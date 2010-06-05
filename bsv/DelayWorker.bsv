// DelayWorker.bsv - Delay streaming message data
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum::*;
import OCWip::*;
import SRLFIFO::*;

import Alias::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import Vector::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface DelayWorkerIfc#(numeric type ndw);
  interface Wci_Es#(NwciAddr)                           wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS1;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM1;    // WSI-M Stream Output
  interface WmemiEM16B                                  wmemiM;   // WMI Memory
endinterface 

module mkDelayWorker#(parameter Bit#(32) dlyCtrlInit) (DelayWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc #(NwciAddr)        wci               <- mkWciSlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS              <- mkWsiSlave;
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM              <- mkWsiMaster;
  WmemiMasterIfc#(36,12,128,16)  wmemi             <- mkWmemiMaster;
  Reg#(Bit#(32))                 dlyCtrl           <- mkReg(dlyCtrlInit);
  Reg#(Bit#(32))                 dlyHoldoff        <- mkReg(0);

  // Delay-Write...
  Reg#(Maybe#(Bit#(8)))          opcode            <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(14)))         mesgLength        <- mkReg(tagged Invalid); // in Bytes
  Reg#(Bit#(12))                 wsiWordsRemain    <- mkReg(0);              // in ndw-wide words
  Reg#(Bool)                     mesgReqValid      <- mkReg(False);
  Reg#(Bool)                     impreciseBurst    <- mkReg(False);
  Reg#(Bool)                     preciseBurst      <- mkReg(False);
  Reg#(Bool)                     endOfMessage      <- mkReg(False);
  Reg#(Bool)                     readyToRequest    <- mkReg(False);
  Reg#(Bool)                     readyToPush       <- mkReg(False);
  Reg#(Bit#(14))                 mesgLengthSoFar   <- mkReg(0);
  Reg#(Bool)                     zeroLengthMesg    <- mkReg(False);
  Reg#(Bool)                     doAbort           <- mkReg(False);
  Reg#(Bit#(32))                 mesgWtCount       <- mkReg(0);
  Reg#(Bit#(32))                 bytesWritten      <- mkReg(0);

  // Write Serialize...
  Reg#(Bit#(32))                 wrtSerAddr        <- mkReg(0);
  Reg#(UInt#(16))                wrtSerUnroll      <- mkReg(0);
  Reg#(MesgMetaFlag)             wrtSerMeta        <- mkRegU;
  Vector#(4,Reg#(Bit#(32)))      wrtSerStage       <- replicateM(mkRegU);
  Reg#(Bit#(2))                  wrtSerPos         <- mkReg(0);

  // Read Serialize...
  Reg#(Bit#(32))                 rdSerAddr         <- mkReg(0);
  Reg#(UInt#(16))                rdSerUnroll       <- mkReg(0);
  Reg#(MesgMetaFlag)             rdSerMeta         <- mkRegU;
  Vector#(4,Reg#(Bit#(32)))      rdSerStage        <- replicateM(mkRegU);
  Reg#(Bit#(2))                  rdSerPos          <- mkReg(0);
  Reg#(Bool)                     rdSerEmpty        <- mkReg(True);
  Reg#(Bool)                     rdSyncWord        <- mkReg(False);

  // Delay-Read...
  Reg#(MesgMetaFlag)             readMeta          <- mkRegU;
  Reg#(UInt#(16))                unrollCnt         <- mkReg(0);
  Reg#(Bit#(32))                 mesgRdCount       <- mkReg(0);
  Reg#(Bit#(32))                 bytesRead         <- mkReg(0);

  // debug...
  Reg#(Bit#(32))                 abortCount        <- mkReg(0);
  Reg#(Bit#(nd))                 valExpect         <- mkReg(0);
  Reg#(Bit#(nd))                 errCount          <- mkReg(0);

  // Delay FIFOs
  FIFOF#(MesgMetaFlag)           metaWF             <- mkSRLFIFO(4);
  FIFOF#(Bit#(nd))               mesgWF             <- mkSizedBRAMFIFOF(512);  
  FIFOF#(MesgMetaFlag)           metaRF             <- mkSRLFIFO(4);
  FIFOF#(Bit#(nd))               mesgRF             <- mkSizedBRAMFIFOF(512);  
  FIFOF#(Bit#(128))              wide16Fa           <- mkSRLFIFO(4);
  FIFOF#(Bit#(128))              wide16Fb           <- mkSRLFIFO(4);

  // Delay Management...
  Accumulator2Ifc#(Int#(20))     dlyWordsStored     <- mkAccumulator2;
  Accumulator2Ifc#(Int#(8))      dlyReadCredit      <- mkAccumulator2;
  Reg#(UInt#(20))                dlyWAG             <- mkReg(0);
  Reg#(UInt#(20))                dlyRAG             <- mkReg(0);

  Reg#(Bit#(32))                 wmemiWrReq         <- mkReg(0);
  Reg#(Bit#(32))                 wmemiRdReq         <- mkReg(0);
  Reg#(Bit#(32))                 wmemiRdResp        <- mkReg(0);

  Bool wsiPass  = (dlyCtrl[3:0]==4'h0);
  Bool wmiRd    = (dlyCtrl[3:0]==4'h1) || (dlyCtrl[3:0]==4'h4);
  Bool wmiWt    = (dlyCtrl[3:0]==4'h2) || (dlyCtrl[3:0]==4'h3);
  Bool wmemiDly = (dlyCtrl[3:0]==4'h7);

  Bool impWsiM = False;

rule operating_actions (wci.isOperating);
  wsiS.operate();
  wsiM.operate();
  wmemi.operate();
endrule

// WSI Pass...
rule wsipass_doMessagePush (wci.isOperating && wsiPass);
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
  //$display("[%0d]: %m: wsipass_doMessagePush ", $time);
endrule


//
//
// Delay Write...
(* descending_urgency = "wmwt_doAbort, wmwt_messageFinalize, wmwt_messagePushImprecise, wmwt_messagePushPrecise, wmwt_requestPrecise, wmwt_mesgBegin" *)

// This rule will fire once at the beginning of every inbound WSI message
// It relies upon the implicit condition of the wsiS.reqPeek to only fire when we a request...
rule wmwt_mesgBegin (wci.isOperating && wmemiDly && !isValid(opcode));
  opcode <= tagged Valid wsiS.reqPeek.reqInfo;
  Bit#(14) mesgLengthB =  extend(wsiS.reqPeek.burstLength)<<myWordShift; // ndw-wide burstLength words to mesgLength Bytes
  if (wsiS.reqPeek.burstPrecise) begin
    preciseBurst    <= True;
    if (wsiS.reqPeek.byteEn=='0) begin
      zeroLengthMesg  <= True;
      mesgLength      <= tagged Valid 0;
    end else begin
      zeroLengthMesg  <= False;
      mesgLength      <= tagged Valid (mesgLengthB);
    end
    wsiWordsRemain  <= wsiS.reqPeek.burstLength; 
    readyToRequest  <= True;
    $display("[%0d]: %m: mesgBegin PRECISE mesgWtCount:%0x WSI burstLength:%0x reqInfo:%0x",
      $time, mesgWtCount, wsiS.reqPeek.burstLength, wsiS.reqPeek.reqInfo);
  end else begin
    impreciseBurst  <= True;
    mesgLengthSoFar <= 0; 
    readyToPush     <= True;
    $display("[%0d]: %m: wmwt_mesgBegin IMPRECISE mesgWtCount:%0x", $time, mesgWtCount);
  end
endrule

// This rule firing posts an WMemiI SRMD request based upon
rule wmwt_requestPrecise (wci.isOperating && wmemiDly && readyToRequest && preciseBurst);
  let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(fromMaybe(0,mesgLength))}; 
  metaWF.enq(mesgMetaF);
  readyToRequest <= False;
  mesgReqValid   <= True;
endrule

// Push precise message WSI to WMI. This rule fires once for each word moved...
rule wmwt_messagePushPrecise (wci.isOperating && wmemiDly && wsiWordsRemain>0 && mesgReqValid && preciseBurst);
  WsiReq#(12,nd,nbe,8,0) w <- wsiS.reqGet.get;
  mesgWF.enq(w.data);
  if (bytesWritten < maxBound) bytesWritten <= bytesWritten + extend(myByteWidth);
  wsiWordsRemain <= wsiWordsRemain - 1;
endrule

// Push imprecise message WSI to WMI...
rule wmwt_messagePushImprecise (wci.isOperating && wmemiDly && readyToPush && impreciseBurst);
  WsiReq#(12,nd,nbe,8,0) w <- wsiS.reqGet.get;
  Bool dwm = (w.burstLength==1);       // Imprecise WSI ends with burstLength==1, used to make WMI DWM
  Bool zlm = dwm && (w.byteEn=='0);    // Zero Length Message is 0 BEs on DWM 
  Bit#(14) mlp1  =  mesgLengthSoFar+1; // message length so far plus one (in Words)
  Bit#(14) mlp1B =  mlp1<<myWordShift; // message length so far plus one (in Bytes)
  if (isAborted(w)) begin
    doAbort <= True;
  end else begin
    let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(mlp1B)}; 
    mesgWF.enq(w.data);
    if (bytesWritten < maxBound) bytesWritten <= bytesWritten + extend(myByteWidth);
    if (dwm) begin
      mesgLength   <= tagged Valid pack(mlp1B);
      readyToPush  <= False;
      endOfMessage <= True;
    end
    mesgLengthSoFar <= mlp1;
    // Count Pattern Error check...
    if (!zlm) valExpect <= valExpect + 1;
    if (w.data!=valExpect && !zlm) errCount <= errCount + 1;
  end
endrule

// In case we abort the imprecise WSI...
rule wmwt_doAbort (wci.isOperating && wmemiDly && doAbort);
  doAbort         <= False;
  readyToPush     <= False;
  preciseBurst    <= False;
  impreciseBurst  <= False;
  opcode          <= tagged Invalid;
  mesgLength      <= tagged Invalid;
  abortCount      <= abortCount + 1;
  $display("[%0d]: %m: wmwt_doAbort", $time );
endrule

// When we have pushed all the data through, this rule fires to prepare us for the next...
rule wmwt_messageFinalize
  (wci.isOperating && wmemiDly && isValid(mesgLength) && !doAbort && ((preciseBurst && wsiWordsRemain==0) || (impreciseBurst && endOfMessage)) );
  if (impreciseBurst) metaWF.enq(MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(fromMaybe(0,mesgLength))}); 
  opcode         <= tagged Invalid;
  mesgLength     <= tagged Invalid;
  mesgWtCount    <= mesgWtCount + 1;
  mesgReqValid   <= False;
  preciseBurst   <= False;
  impreciseBurst <= False;
  endOfMessage   <= False;
  $display("[%0d]: %m: wmwt_messageFinalize mesgWtCount:%0x WSI mesgLength:%0x", $time, mesgWtCount, fromMaybe(0,mesgLength));
endrule


// Connect the WFs to RFs...
//mkConnection(toGet(metaWF), toPut(metaRF));
//mkConnection(toGet(mesgWF), toPut(mesgRF));

function Action enqSer4B( Bit#(32) data, Bool flush);
  action
    wrtSerStage[wrtSerPos] <= data;
    wrtSerPos <= flush ? 0 : wrtSerPos + 1;
    if (wrtSerPos==3 || flush)
      case (wrtSerPos)
        0: wide16Fa.enq({32'h0, 32'h0,          32'h0,          data});
        1: wide16Fa.enq({32'h0, 32'h0,          data,           wrtSerStage[0]});
        2: wide16Fa.enq({32'h0, data,           wrtSerStage[1], wrtSerStage[0]});
        3: wide16Fa.enq({data,  wrtSerStage[2], wrtSerStage[1], wrtSerStage[0]});
      endcase
  endaction
endfunction

rule wrtSer_begin(wci.isOperating && wmemiDly && wrtSerUnroll==0);
  let meta = metaWF.first; metaWF.deq; wrtSerMeta <= meta;
  wrtSerUnroll  <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words 
  enqSer4B(pack(meta), meta.length==0);
endrule

rule wrtSer_body(wci.isOperating && wmemiDly && wrtSerUnroll>0);
  let mesg = mesgWF.first; mesgWF.deq;
  Bool lastWord = (wrtSerUnroll==1);
  wrtSerUnroll <= wrtSerUnroll - 1;
  enqSer4B(truncate(pack(mesg)), lastWord);
endrule

// Wide16Fa -> Wide16Fb is the Delay Insert point...


//mkConnection(toGet(wide16Fa), toPut(wide16Fb));


Bool readThreshold = (dlyWordsStored > 0);
(* descending_urgency = "delay_write_req, delay_read_req" *)

rule delay_write_req (wci.isOperating && wmemiDly);
  dlyWordsStored.acc1(1);  // One 16B word stored
  dlyWAG <= dlyWAG + 1;
  wmemi.req(True, extend({pack(dlyWAG),4'h0}), 1);
  wmemi.dh(wide16Fa.first, '1, True);
  wide16Fa.deq;
  wmemiWrReq <= wmemiWrReq + 1;
endrule

rule delay_read_req (wci.isOperating && wmemiDly && readThreshold && dlyReadCredit>0);
  dlyWordsStored.acc2(-1);  // One 16B word read
  dlyRAG <= dlyRAG + 1;
  dlyReadCredit.acc1(-1);   // Decrement our credit by 1
  wmemi.req(False, extend({pack(dlyRAG),4'h0}), 1);
  wmemiRdReq <= wmemiRdReq + 1;
endrule

rule delay_read_resp (wci.isOperating && wmemiDly);
  dlyReadCredit.acc2(1);   // Restore our credit by one
  let x <- wmemi.resp;
  wide16Fb.enq(x.data);
  wmemiRdResp <= wmemiRdResp + 1;
endrule



function ActionValue#(Bit#(32)) deqSer4B(Bool forceSync);
  return (
    actionvalue
      Bit#(128) rdata = ?;
      if (rdSerEmpty || rdSerPos==0 || forceSync) begin 
        rdata = wide16Fb.first;
        rdSerStage[0] <= rdata[31:0];
        rdSerStage[1] <= rdata[63:32];
        rdSerStage[2] <= rdata[95:64];
        rdSerStage[3] <= rdata[127:96];
        wide16Fb.deq;
        rdSerEmpty <= False;
      end
      rdSerPos <= forceSync ? 0 : rdSerPos + 1;
      return (
      case (rdSerPos)
        0: rdata[31:0];
        1: rdSerStage[1];
        2: rdSerStage[2];
        3: rdSerStage[3];
      endcase
      );
    endactionvalue
  );
endfunction

rule rdSer_begin(wci.isOperating && wmemiDly && rdSerUnroll==0 && !rdSyncWord);
  let m <- deqSer4B(False);
  MesgMetaFlag meta = unpack(m);
  rdSerMeta <= meta;
  rdSerUnroll  <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words 
  metaRF.enq(meta);
  if (bytesRead < maxBound) bytesRead <= bytesRead + extend(myByteWidth);
  rdSyncWord <= meta.length==0;
endrule

rule rdSer_body(wci.isOperating && wmemiDly && rdSerUnroll>0 && !rdSyncWord);
  Bit#(32) mesg <- deqSer4B(False);
  Bool lastWord = (rdSerUnroll == 1);
  rdSyncWord <= lastWord;
  rdSerUnroll <= rdSerUnroll - 1;
  mesgRF.enq(extend(mesg));
  if (bytesRead < maxBound) bytesRead <= bytesRead + extend(myByteWidth);
endrule

rule rdSer_sync(wci.isOperating && wmemiDly && rdSyncWord);
  Bit#(32) ignore <- deqSer4B(True);
  rdSyncWord <= False;
endrule








//
//
// Delay Read...
rule wmrd_mesgBegin (wci.isOperating && wmemiDly && unrollCnt==0 && bytesWritten>dlyHoldoff );
  let meta = metaRF.first; metaRF.deq; readMeta <= meta;
  if (meta.length==0) begin
    unrollCnt      <= 1;  // One word to produce on WSI with all BEs inaction (zero lenghth mesg indication)
  end else begin
    unrollCnt      <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words remaining to be emitted to WSI
  end
endrule

rule wmrd_mesgBodyResponse (wci.isOperating && wmemiDly && unrollCnt>0);
  let mesg = mesgRF.first; mesgRF.deq;
  Bool zlm = (readMeta.length==0);
  Bit#(24) wsiBurstLength = (impWsiM) ? 2 : readMeta.length>>myWordShift; // convert Bytes to ndw-wide WSI Words burstLength
  Bool lastWord = (unrollCnt == 1);
  wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                           reqLast : lastWord,
                           reqInfo : readMeta.opcode,
                      burstPrecise : !impWsiM,
                       burstLength : (zlm || (impWsiM && lastWord)) ? 1 : (impWsiM)? '1 : truncate(wsiBurstLength),
                             data  : mesg,
                           byteEn  : (zlm) ? '0 : '1,   // For Zero-Length WSI Messages
                         dataInfo  : '0 });
  unrollCnt <= unrollCnt - 1;
  if (lastWord) mesgRdCount <= mesgRdCount + 1;
endrule





// WCI...

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h00 : dlyCtrl    <= unpack(wciReq.data);
     'h04 : dlyHoldoff <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(dlyCtrl);
     'h04 : rdat = pack(dlyHoldoff);
     'h08 : rdat = pack(mesgWtCount);
     'h0C : rdat = pack(mesgRdCount);
     'h10 : rdat = pack(bytesWritten);
     'h14 : rdat = 0;
     'h18 : rdat = extend({pack(wmemi.status),pack(wsiS.status),pack(wsiM.status)});
     'h20 : rdat = pack(wsiS.extStatus.pMesgCount);
     'h24 : rdat = pack(wsiS.extStatus.iMesgCount);
     'h28 : rdat = pack(wsiS.extStatus.tBusyCount);
     'h2C : rdat = pack(wsiM.extStatus.pMesgCount);
     'h30 : rdat = pack(wsiM.extStatus.iMesgCount);
     'h34 : rdat = pack(wsiM.extStatus.tBusyCount);
     'h38 : rdat = wmemiWrReq;
     'h3C : rdat = wmemiRdReq;
     'h40 : rdat = wmemiRdResp;
     'h44 : rdat = extend(pack(dlyWordsStored));
     'h48 : rdat = extend(pack(dlyReadCredit));
     'h4C : rdat = extend(pack(dlyWAG));
     'h50 : rdat = extend(pack(dlyRAG));
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
     //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule


rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  mesgWtCount <= 0;
  mesgRdCount <= 0;
  dlyWordsStored.load(0);   // Initialize the number of (16B) words stored in memory
  dlyReadCredit.load(8);    // Sets the maximum number of reads that can be inflight at once
  dlyWAG  <= 0;             // Initialize the Write Address Generator accumulator
  dlyRAG  <= 0;             // Initialize the Read  Address Generator accumulator
  wci.ctlAck;
  $display("[%0d]: %m: Starting DelayWorker dlyCtrl:%0x", $time, dlyCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wci_Es#(NwciAddr)       wci_Es    <- mkWciStoES(wci.slv); 
  Wsi_Es#(12,nd,nbe,8,0)  wsi_Es    <- mkWsiStoES(wsiS.slv);
  WmemiEM16B              wmemi_Em  <- mkWmemiMtoEm(wmemi.mas);

  interface wciS0  = wci_Es;
  interface wsiS1  = wsi_Es;
  interface wsiM1  = toWsiEM(wsiM.mas);
  interface wmemiM = wmemi_Em;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef DelayWorkerIfc#(1) DelayWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker4B#(parameter Bit#(32) dlyCtrlInit) (DelayWorker4BIfc);
  DelayWorker4BIfc _a <- mkDelayWorker(dlyCtrlInit); return _a;
endmodule

typedef DelayWorkerIfc#(2) DelayWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker8B#(parameter Bit#(32) dlyCtrlInit) (DelayWorker8BIfc);
  DelayWorker8BIfc _a <- mkDelayWorker(dlyCtrlInit); return _a;
endmodule

typedef DelayWorkerIfc#(4) DelayWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker16B#(parameter Bit#(32) dlyCtrlInit) (DelayWorker16BIfc);
  DelayWorker16BIfc _a <- mkDelayWorker(dlyCtrlInit); return _a;
endmodule

typedef DelayWorkerIfc#(8) DelayWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker32B#(parameter Bit#(32) dlyCtrlInit) (DelayWorker32BIfc);
  DelayWorker32BIfc _a <- mkDelayWorker(dlyCtrlInit); return _a;
endmodule

