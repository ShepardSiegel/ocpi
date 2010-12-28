// FCAdapter.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import Accum::*;

import GetPut::*;
import FIFO::*;	
import FIFOF::*;	
import DReg::*;
import Alias::*;

interface FCAdapterIfc#(numeric type ndw);
  interface Wci_s#(20)                      wci_s;
  interface Wmi_m#(14,12,TMul#(ndw,32),0,0,32) wmi_m;
  interface Wsi_m#(12,TMul#(ndw,32),4,8,1)     wsi_m;
endinterface 

module mkFCAdapter (FCAdapterIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc#(20)            wci               <- mkWciSlave;
  WmiMasterIfc#(14,12,nd,0,0,32) wmi               <- mkWmiMaster;
  WsiMasterIfc#(12,nd,4,8,1)     wsi               <- mkWsiMaster;
  Reg#(Bit#(32))                 r0                <- mkReg(0);
  Reg#(Bit#(32))                 mesgCount         <- mkReg(0);
  Reg#(UInt#(32))                zeroCount         <- mkReg(0);
  Reg#(Bit#(32))                 mesgSum           <- mkReg(0);
  Reg#(MesgMetaDW)               thisMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(MesgMetaDW)               lastMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(UInt#(16))                unrollCnt         <- mkReg(0);
  Accumulator2Ifc#(Int#(4))      fabRespCredit     <- mkAccumulator2;
  Reg#(UInt#(14))                fabWordsRemain    <- mkReg(0);            // ndw-wide Words that remain to be consumed
  Reg#(UInt#(14))                fabWordsCurReq    <- mkRegU;              // ndw-wide Words in the current request
  Reg#(UInt#(14))                mesgReqAddr       <- mkRegU;              // Message Request Byte Address 
  Reg#(Bool)                     mesgPreRequest    <- mkDReg(False);
  Reg#(Bool)                     mesgReqOK         <- mkReg(False);
  Reg#(Bool)                     firstMsgReq       <- mkReg(False);
  
  Reg#(Bit#(nd))                 valExpect         <- mkReg(0);
  Reg#(Bit#(nd))                 valGot            <- mkReg(0);
  Reg#(Bit#(32))                 errCount          <- mkReg(0);

rule operating_actions (wci.isOperating);
  wmi.operate();
  wsi.operate();
endrule

(* descending_urgency = "mesgBodyResponse, mesgBodyRequest, mesgBodyPreRequest, mesgBegin" *)

// This rule to fire once at the beginning of each and every fabric consumption of a message...
rule mesgBegin (wci.isOperating && !wmi.anyBusy && unrollCnt==0);
  Bool isZlm = ?;
  if (wmi.zeroLengthMesg) begin
    isZlm = True;
    unrollCnt      <= 1;  // One word to produce on WSI with all BEs inaction (zero lenghth mesg indication)
    fabWordsRemain <= 1;  // One word to consume from WMI so we can send a DWM
    zeroCount <= zeroCount + 1;
  end else begin
    isZlm = False;
    unrollCnt      <= truncate(unpack(wmi.mesgLength>>myWordShift)); // ndw-wide Words remaining to be emitted to WSI
    fabWordsRemain <= truncate(unpack(wmi.mesgLength>>myWordShift)); // ndw-wide Words remaining to be requested from fabric
  end
  mesgReqOK        <= True;
  mesgReqAddr      <= 0;  // Initialize address to 0
  thisMesg <= MesgMetaDW { tag:truncate(mesgCount), opcode:wmi.reqInfo, length:truncate(wmi.mesgLength) };
  lastMesg <= thisMesg;
  $display("[%0d]: %m: mesgBegin mesgCount:%0h mesgLength:%0h reqInfo:%0h", $time, mesgCount, wmi.mesgLength, wmi.reqInfo);
endrule

// Figure out how much we can ask for: the min of what we need and what we can acccept...
rule mesgBodyPreRequest (wci.isOperating && fabWordsRemain>0 && fabRespCredit>0 && mesgReqOK);
  fabWordsCurReq   <= min(fabWordsRemain, unpack(pack(extend(fabRespCredit))));
  mesgReqOK        <= False;  // Inhibit issuing another request until this one is completed
  mesgPreRequest   <= True;
  //$display("[%0d]: %m: mesgBodyPreReq", $time );
endrule

// Act on the pre-request calculaton and make the request...
rule mesgBodyRequest (wci.isOperating && mesgPreRequest);
  fabRespCredit.acc1(- unpack(pack(truncate(fabWordsCurReq))) );   // Debit on what we ask for
  Bool last = (fabWordsRemain==fabWordsCurReq);
  wmi.req(False, pack(mesgReqAddr), truncate(pack(fabWordsCurReq)), last, ?);
  mesgReqAddr      <= mesgReqAddr    + (fabWordsCurReq<<myWordShift);  // convert from ndw-wide words to Bytes
  fabWordsRemain   <= fabWordsRemain -  fabWordsCurReq;
  //$display("[%0d]: %m: mesgBodyRequest mesgReqAddr:%0h fabWordsCurReq:%0h fabWordsRemain:%0h",
  // $time, mesgReqAddr, fabWordsCurReq, fabWordsRemain );
endrule

(* execution_order = "mesgBodyResponse, wci_cfwr" *) 
rule mesgBodyResponse (wci.isOperating && unrollCnt>0);
  let x <- wmi.resp;     // Take the response from the WMI interface
  fabRespCredit.acc2(1); // Credit one word removed from the Resp FIFO this cycle
  Bool zlm = (thisMesg.length==0);
  if (!zlm) mesgSum <= mesgSum + truncate(x.data);
  Bit#(16) wsiBurstLength = thisMesg.length>>myWordShift; // convert Bytes to ndw-wide WSI Words burstLength
  wsi.reqPut.put (WsiReq     {cmd  : WR ,
                           reqLast : (unrollCnt==1) ? True : False,
                            reqInfo : thisMesg.opcode,
                      burstPrecise : True,
                       //burstLength : (zlm) ? 1 : truncate(thisMesg.length>>myWordShift), // convert Bytes to ndw-wide WSI Words burstLength
                       burstLength : (zlm) ? 1 : truncate(wsiBurstLength),
                             data  : x.data,
                           byteEn  : (zlm) ? '0 : '1,   // For Zero-Length WSI Messages
                         dataInfo  : '0 });
  if (unrollCnt==1) begin
    mesgCount <= mesgCount + 1;
    //$display("[%0d]: %m: mesgBodyResponse: End of WSI Producer Egress: mesgCount:%0x mesgLen:%0x reqInfo:%0x",
    //  $time, mesgCount, wmi.mesgLength, wmi.reqInfo);
  end
  mesgReqOK <= True;           // OK to issue another request now
  unrollCnt <= unrollCnt - 1;
  // Error check...
  valGot <= x.data;
  if (!zlm) valExpect <= valExpect + 1;
  if (x.data!=valExpect && !zlm) errCount <= errCount + 1;
endrule


(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h00 : r0  <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
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
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
     //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:OK, data:rdat}); // read response
endrule


rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  fabRespCredit.load(2);  // sized to the WMI Response to WSI Master Buffering
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
  interface Wmi_m wmi_m = wmi.mas;
  interface Wsi_m wsi_m = wsi.mas;
endmodule


// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef FCAdapterIfc#(1) FCAdapter4BIfc;
(* synthesize *) module mkFCAdapter4B (FCAdapter4BIfc);
  FCAdapter4BIfc _a <- mkFCAdapter; return _a;
endmodule

typedef FCAdapterIfc#(2) FCAdapter8BIfc;
(* synthesize *) module mkFCAdapter8B (FCAdapter8BIfc);
  FCAdapter8BIfc _a <- mkFCAdapter; return _a;
endmodule

typedef FCAdapterIfc#(4) FCAdapter16BIfc;
(* synthesize *) module mkFCAdapter16B (FCAdapter16BIfc);
  FCAdapter16BIfc _a <- mkFCAdapter; return _a;
endmodule

typedef FCAdapterIfc#(8) FCAdapter32BIfc;
(* synthesize *) module mkFCAdapter32B (FCAdapter32BIfc);
  FCAdapter32BIfc _a <- mkFCAdapter; return _a;
endmodule
