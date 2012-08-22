// FPAdapter.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import Vector::*;	
import Alias::*;

interface FPAdapterIfc#(numeric type ndw);
  interface Wci_s#(20)                      wci_s;
  interface Wsi_s#(12,TMul#(ndw,32),4,8,0)     wsi_s;
  interface Wmi_m#(14,12,TMul#(ndw,32),0,0,32) wmi_m;
endinterface 

module mkFPAdapter (FPAdapterIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc#(20)            wci               <- mkWciSlave;
  WsiSlaveIfc#(12,nd,4,8,0)      wsi               <- mkWsiSlave;
  WmiMasterIfc#(14,12,nd,0,0,32) wmi               <- mkWmiMaster;
  Reg#(Bit#(32))                 r0                <- mkReg(0);
  Reg#(Bit#(32))                 mesgCount         <- mkReg(0);
  Reg#(UInt#(32))                zeroCount         <- mkReg(0);
  Reg#(Bit#(32))                 mesgSum           <- mkReg(0);
  Reg#(MesgMetaDW)               thisMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(MesgMetaDW)               lastMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(Maybe#(Bit#(8)))          opcode            <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(14)))         mesgLength        <- mkReg(tagged Invalid); // in Bytes
  Reg#(Bit#(12))                 wsiWordsRemain    <- mkReg(0);              // in ndw-wide words
  Reg#(Bool)                     mesgReqValid      <- mkReg(False);
  Reg#(Bool)                     impreciseBurst    <- mkReg(False);
  Reg#(Bool)                     preciseBurst      <- mkReg(False);
  Reg#(Bool)                     endOfMessage      <- mkReg(False);
  Reg#(Bool)                     readyToRequest    <- mkReg(False);
  Reg#(Bool)                     readyToPush       <- mkReg(False);
  Reg#(UInt#(32))                mesgLengthSoFar   <- mkReg(0);
  Reg#(Bool)                     zeroLengthMesg    <- mkReg(False);
  
  Reg#(Bit#(nd))                 valExpect         <- mkReg(0);
  Reg#(Bit#(nd))                 errCount          <- mkReg(0);
  Reg#(Vector#(4,Bit#(8)))       dvState           <- mkReg(unpack(0));

  Reg#(Bit#(32))                 mesgBeginCount    <- mkReg(0);
  Reg#(Bit#(32))                 mesgPushCount     <- mkReg(0);

rule operating_actions (wci.isOperating);
  wmi.operate();
  wsi.operate();
endrule

(* descending_urgency = "messageFinalize, messagePushPrecise, requestPrecise, mesgBegin" *)

// This rule will fire once at the beginning of every inbound WSI message
// It relies upon the implicit condition of the wsi.reqPeek to only fire when we a request...
rule mesgBegin (wci.isOperating && !wmi.anyBusy && !isValid(opcode));
  opcode <= tagged Valid wsi.reqPeek.reqInfo;
  Bit#(14) mesgLengthB =  extend(wsi.reqPeek.burstLength)<<myWordShift; // ndw-wide burstLength words to mesgLength Bytes
  if (wsi.reqPeek.burstPrecise) begin
    preciseBurst    <= True;
    if (wsi.reqPeek.byteEn=='0) begin
      zeroLengthMesg  <= True;
      mesgLength      <= tagged Valid 0;
      zeroCount       <= zeroCount + 1;
    end else begin
      zeroLengthMesg  <= False;
      mesgLength      <= tagged Valid (mesgLengthB);
    end
    wsiWordsRemain  <= wsi.reqPeek.burstLength; 
    readyToRequest  <= True;
    $display("[%0d]: %m: mesgBegin PRECISE mesgCount:%0x WSI burstLength:%0x reqInfo:%0x",
      $time, mesgCount, wsi.reqPeek.burstLength, wsi.reqPeek.reqInfo);
  end else begin
    zeroLengthMesg  <= False;
    impreciseBurst  <= True;
    mesgLengthSoFar <= 0; 
    readyToPush     <= True;
    //$display("[%0d]: %m: mesgBegin IMPRECISE:%0x", $time, mesgCount);
  end
  mesgBeginCount <= mesgBeginCount + 1;
endrule

// This rule firing posts an WMI request and the MFlag opcode/length info...
rule requestPrecise (wci.isOperating && readyToRequest && preciseBurst);
  thisMesg <= MesgMetaDW { tag:truncate(mesgCount), opcode:fromMaybe(0,opcode), length:extend(fromMaybe(0,mesgLength)) };
  lastMesg <= thisMesg;
  let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(fromMaybe(0,mesgLength))}; 
  //wmi.req(True, 0, zeroLengthMesg?1:truncate(fromMaybe(0,mesgLength)>>myWordShift),True,pack(mesgMetaF)); // Sole request is DWM 
  Bit#(14) wmiLen =  (fromMaybe(0,mesgLength)>>myWordShift);
  wmi.req(True, 0, zeroLengthMesg?1:truncate(wmiLen),True,pack(mesgMetaF)); // Sole request is DWM 
  readyToRequest <= False;
  mesgReqValid   <= True;
  //$display("[%0d]: %m: requestPrecise", $time );
endrule

// Push message WSI to WMI. This rule fires once for each word moved...
rule messagePushPrecise (wci.isOperating && wsiWordsRemain>0 && mesgReqValid && preciseBurst);
  WsiReq#(12,nd,4,8,0) w <- wsi.reqGet.get;
  if (!zeroLengthMesg) mesgSum <= mesgSum + truncate(w.data);
  wmi.dh(w.data, '1, (wsiWordsRemain==1));
  wsiWordsRemain <= wsiWordsRemain - 1;
  //$display("[%0d]: %m: messagePushPrecise", $time );
  // Error check...
  if (!zeroLengthMesg) valExpect <= valExpect + 1;
  if (w.data!=valExpect && !zeroLengthMesg) errCount <= errCount + 1;
  //
  dvState <= shiftInAt0(dvState, w.data[7:0]); 
endrule

// When we have pushed all the data through, this rule fires to prepare us for the next...
rule messageFinalize
  (wci.isOperating && isValid(mesgLength) && ((preciseBurst && wsiWordsRemain==0) || (impreciseBurst && endOfMessage)) );
  opcode         <= tagged Invalid;
  mesgLength     <= tagged Invalid;
  mesgCount      <= mesgCount + 1;
  mesgReqValid   <= False;
  preciseBurst   <= False;
  impreciseBurst <= False;
  endOfMessage   <= False;
  //$display("[%0d]: %m: messageFinalize", $time );
endrule


(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h00 : r0  <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
    // $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(r0);
     'h04 : rdat = pack(mesgCount);
     'h08 : rdat = pack(zeroCount);
     'h0C : rdat = pack(mesgSum);
     'h10 : rdat = pack(thisMesg);
     'h14 : rdat = pack(lastMesg);
     'h18 : rdat = pack(dvState);
     'h1C : rdat = pack(mesgBeginCount);
     'h20 : rdat = pack(mesgPushCount);
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
    // $time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:OK, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  mesgCount <= 0;
  zeroCount <= 0;
  mesgSum   <= 0;
  thisMesg  <= unpack(32'hFEFE_FFFE);
  lastMesg  <= unpack(32'hFEFE_FFFE);
  wci.ctlAck;
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  interface Wci_s wci_s = wci.slv;
  interface Wsi_s wsi_s = wsi.slv;
  interface Wmi_m wmi_m = wmi.mas;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef FPAdapterIfc#(1) FPAdapter4BIfc;
(* synthesize *) module mkFPAdapter4B (FPAdapter4BIfc);
  FPAdapter4BIfc _a <- mkFPAdapter; return _a;
endmodule

typedef FPAdapterIfc#(2) FPAdapter8BIfc;
(* synthesize *) module mkFPAdapter8B (FPAdapter8BIfc);
  FPAdapter8BIfc _a <- mkFPAdapter; return _a;
endmodule

typedef FPAdapterIfc#(4) FPAdapter16BIfc;
(* synthesize *) module mkFPAdapter16B (FPAdapter16BIfc);
  FPAdapter16BIfc _a <- mkFPAdapter; return _a;
endmodule

typedef FPAdapterIfc#(8) FPAdapter32BIfc;
(* synthesize *) module mkFPAdapter32B (FPAdapter32BIfc);
  FPAdapter32BIfc _a <- mkFPAdapter; return _a;
endmodule

