// DACWorker.bsv 
// Copyright (c) 2009,2010 Atomic Rules LLC - ALL RIGHTS RESERVED
// DACWorker is a device-worker that attempts to be agnostic to specific DAC implemenatations

import OCWip::*;
import Max19692::*;
import DDRSlaveDrive::*;
import FreqCounter::*;
import TimeService::*;
import CounterM::*;

import Clocks::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import XilinxCells::*;
import XilinxExtra::*;

interface DACWorkerIfc;
  interface Wci_s#(20) wci_s;                 // WCI
  interface Wti_s#(64) wti_s;                 // WTI
  interface Wsi_Es#(12,32,4,8,0) wsiS1;       // WSI DAC Slave
  interface P_Max19692Ifc dac0;               // Maxim 19662
endinterface 

(* synthesize *)
module mkDACWorker#(Clock dac_clk, Reset dac_rst) (DACWorkerIfc);
  WciSlaveIfc#(20)      wci                <-  mkWciSlave;               // WCI
  WtiSlaveIfc#(64)      wti                <-  mkWtiSlave(clocked_by dac_clk, reset_by dac_rst); 
  Reg#(Bool)            sFlagState         <-  mkReg(False);             // Worker Attention
  Reg#(Bool)            splitReadInFlight  <-  mkReg(False);             // Split WCI Read
  Reg#(Bool)            initOpInFlight     <-  mkReg(False);             // Asserted While Init-ing
  Max19692Ifc           dacCore0           <-  mkMax19692(dac_clk);      // DAC
  Clock                 dacSdrClk          =   dacCore0.dac.dacSdrClk;
  FreqCounterIfc#(16)   fcDac              <-  mkFreqCounter(dacSdrClk); // Measure DAC SDR clock 1/16 DAC Clk
  CounterMod#(Bit#(18)) oneKHz             <-  mkCounterMod(125000);
  Reg#(Bit#(32))        dacControl         <-  mkReg(32'h0000_0008);
  Reg#(Bit#(32))        mesgCount          <-  mkReg(0);
  Reg#(Bit#(32))        lastOverflowMesg   <-  mkReg('1);
  WsiSlaveIfc#(12,32,4,8,0)   wsiS         <-  mkWsiSlave; //nd=32 not poly
  Reg#(Bit#(16))        unrollCnt          <-  mkReg(0);
  Reg#(Bit#(32))        popCount           <-  mkReg(0);
  Reg#(Bit#(32))        syncCount          <-  mkReg(0);
  Reg#(Bit#(32))        mesgStart          <-  mkReg(0);

  // WMI-Write...
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

  Reg#(Bit#(2))                  srcCnt            <- mkReg(0);
  Vector#(16,Reg#(Bit#(12)))     rf                <- replicateM(mkReg(0));
  Reg#(Bool)                     stageReady        <- mkReg(False);
  Reg#(Bit#(32))                 stageCount        <- mkReg(0);

  Integer myWordShift = 2; // log2(4) 4B Wide WSI

  Bool invertMSB = unpack(dacControl[6]);
  Bool upConv8x  = unpack(dacControl[5]);

rule operating_actions (wci.isOperating); wsiS.operate(); endrule // Indicate to the WSI-S that we are available

// Cloned ruleset from WSI-S to WMI-Write transformation...
// TODO: Consider making this a rule set with WMI-WRITE from SMAdapter
//(* descending_urgency = "emit_doAbort, emit_messageFinalize, emit_messagePushImprecise, emit_messagePushPrecise, emit_requestPrecise, emit_mesgBegin" *)

// This rule will fire once at the beginning of every inbound WSI message
// It relies upon the implicit condition of the wsiS.reqPeek to only fire when we a request...
rule emit_mesgBegin (wci.isOperating && !isValid(opcode));
  mesgStart <= mesgStart + 1;
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
    $display("[%0d]: %m: mesgBegin PRECISE mesgCount:%0x WSI burstLength:%0x reqInfo:%0x", $time, mesgCount, wsiS.reqPeek.burstLength, wsiS.reqPeek.reqInfo);
  end else begin
    impreciseBurst  <= True;
    mesgLengthSoFar <= 0; 
    readyToPush     <= True;
    $display("[%0d]: %m: emit_mesgBegin IMPRECISE mesgCount:%0x", $time, mesgCount);
  end
endrule

// This rule firing posts an WMI request and the MFlag opcode/length info...
rule emit_requestPrecise (wci.isOperating && readyToRequest && preciseBurst);
  let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(fromMaybe(0,mesgLength))}; 
  //Bit#(14) wmiLen =  (fromMaybe(0,mesgLength)>>myWordShift);
  //wmi.req(True, 0, zeroLengthMesg?1:truncate(wmiLen),True,pack(mesgMetaF)); // The sole request precise is DWM 
  readyToRequest <= False;
  mesgReqValid   <= True;
  //$display("[%0d]: %m: emit_requestPrecise", $time );
endrule

rule pushStage (stageReady);
  dacCore0.smpF.enq(readVReg(rf));
  stageReady <= False;
  stageCount <= stageCount + 1;
endrule

// Push precise message WSI to WMI. This rule fires once for each word moved...
rule emit_messagePushPrecise (wci.isOperating && wsiWordsRemain>0 && mesgReqValid && preciseBurst);
  WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get; //nd==32 nopoly

  if (invertMSB) begin
    w.data[31] = ~w.data[31];
    w.data[15] = ~w.data[15];
  end

  //ENQ EMIT HERE
  if (!upConv8x) begin
    case (srcCnt)
      2'h0:  begin rf[0]  <= w.data[15:4];  rf[1]  <= w.data[15:4]; rf[2]   <= w.data[31:20];  rf[3]  <= w.data[31:20]; end
      2'h1:  begin rf[4]  <= w.data[15:4];  rf[5]  <= w.data[15:4]; rf[6]   <= w.data[31:20];  rf[7]  <= w.data[31:20]; end
      2'h2:  begin rf[8]  <= w.data[15:4];  rf[9]  <= w.data[15:4]; rf[10]  <= w.data[31:20];  rf[11] <= w.data[31:20]; end
      2'h3:  begin rf[12] <= w.data[15:4];  rf[13] <= w.data[15:4]; rf[14]  <= w.data[31:20];  rf[15] <= w.data[31:20]; stageReady<=True; end
    endcase
    srcCnt <= srcCnt + 1;
  end else begin
    rf[0]  <= w.data[15:4];   rf[1]  <= w.data[15:4];  rf[2]   <= w.data[15:4];   rf[3]  <= w.data[15:4];
    rf[4]  <= w.data[15:4];   rf[5]  <= w.data[15:4];  rf[6]   <= w.data[15:4];   rf[7]  <= w.data[15:4];
    rf[8]  <= w.data[31:20];  rf[9]  <= w.data[31:20]; rf[10]  <= w.data[31:20];  rf[11] <= w.data[31:20];
    rf[12] <= w.data[31:20];  rf[13] <= w.data[31:20]; rf[14]  <= w.data[31:20];  rf[15] <= w.data[31:20];
    stageReady<=True;
  end

  //wmi.dh(w.data, '1, (wsiWordsRemain==1));
  wsiWordsRemain <= wsiWordsRemain - 1;
  //$display("[%0d]: %m: emit_messagePushPrecise", $time );
endrule

// Push imprecise message WSI to WMI...
rule emit_messagePushImprecise (wci.isOperating && readyToPush && impreciseBurst);
  WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get; //nd==32 nopoly
  Bool dwm = (w.reqLast);              // WSI ends with reqLast==True, used to make WMI DWM
  Bool zlm = dwm && (w.byteEn=='0);    // Zero Length Message is 0 BEs on DWM 
  Bit#(14) mlp1  =  mesgLengthSoFar+1; // message length so far plus one (in Words)
  Bit#(14) mlp1B =  mlp1<<myWordShift; // message length so far plus one (in Bytes)
  if (isAborted(w)) begin
    doAbort <= True;
  end else begin
    let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:extend(mlp1B)}; 

  if (invertMSB) begin
    w.data[31] = ~w.data[31];
    w.data[15] = ~w.data[15];
  end

  //ENQ EMIT HERE
  if (!upConv8x) begin
    case (srcCnt)
      2'h0:  begin rf[0]  <= w.data[15:4];  rf[1]  <= w.data[15:4]; rf[2]   <= w.data[31:20];  rf[3]  <= w.data[31:20]; end
      2'h1:  begin rf[4]  <= w.data[15:4];  rf[5]  <= w.data[15:4]; rf[6]   <= w.data[31:20];  rf[7]  <= w.data[31:20]; end
      2'h2:  begin rf[8]  <= w.data[15:4];  rf[9]  <= w.data[15:4]; rf[10]  <= w.data[31:20];  rf[11] <= w.data[31:20]; end
      2'h3:  begin rf[12] <= w.data[15:4];  rf[13] <= w.data[15:4]; rf[14]  <= w.data[31:20];  rf[15] <= w.data[31:20]; stageReady<=True; end
    endcase
    srcCnt <= srcCnt + 1;
  end else begin
    rf[0]  <= w.data[15:4];   rf[1]  <= w.data[15:4];  rf[2]   <= w.data[15:4];   rf[3]  <= w.data[15:4];
    rf[4]  <= w.data[15:4];   rf[5]  <= w.data[15:4];  rf[6]   <= w.data[15:4];   rf[7]  <= w.data[15:4];
    rf[8]  <= w.data[31:20];  rf[9]  <= w.data[31:20]; rf[10]  <= w.data[31:20];  rf[11] <= w.data[31:20];
    rf[12] <= w.data[31:20];  rf[13] <= w.data[31:20]; rf[14]  <= w.data[31:20];  rf[15] <= w.data[31:20];
    stageReady<=True;
  end

    //wmi.req(True, mesgLengthSoFar<<myWordShift, 1, dwm, pack(mesgMetaF)); // Write, addr, 1Word, dwm, mFlag;
    //wmi.dh(w.data,  '1, dwm);                                             // Data, BE,           dwm
    if (dwm) begin
      mesgLength   <= tagged Valid pack(mlp1B);
      readyToPush  <= False;
      endOfMessage <= True;
    end
    mesgLengthSoFar <= mlp1;
  end
  //$display("[%0d]: %m: emit_messagePushImprecise", $time );
endrule

// In case we abort the imprecise WSI...
rule emit_doAbort (wci.isOperating && doAbort);
  doAbort         <= False;
  readyToPush     <= False;
  preciseBurst    <= False;
  impreciseBurst  <= False;
  opcode          <= tagged Invalid;
  mesgLength      <= tagged Invalid;
  $display("[%0d]: %m: emit_doAbort", $time );
endrule

// When we have pushed all the data through, this rule fires to prepare us for the next...
rule emit_messageFinalize
  (wci.isOperating && isValid(mesgLength) && !doAbort && ((preciseBurst && wsiWordsRemain==0) || (impreciseBurst && endOfMessage)) );
  opcode         <= tagged Invalid;
  mesgLength     <= tagged Invalid;
  mesgCount      <= mesgCount + 1;
  mesgReqValid   <= False;
  preciseBurst   <= False;
  impreciseBurst <= False;
  endOfMessage   <= False;
  $display("[%0d]: %m: emit_messageFinalize mesgCount:%0x WSI mesgLength:%0x", $time, mesgCount, fromMaybe(0,mesgLength));
endrule


rule doEmit (wci.isOperating && unpack(dacControl[4]));
  dacCore0.emitEn();
endrule

rule inc_modcnt; oneKHz.inc(); endrule
rule send_pulse (oneKHz.tc);
 fcDac.pulse();  // measure KHz
endrule


rule updateSflag (sFlagState); action wci.drvSFlag; endaction endrule
rule do_operating (wci.isOperating); endrule

(* descending_urgency = "wci_ctl_op_complete, wci_ctrl_EiI, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[11:10]) matches
     'b00 :  case (wciReq.addr[7:0]) matches
       'h0C : dacControl    <= wciReq.data;
       endcase
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule


rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
 Bool splitRead = False;
 Bit#(32) dacStatusLs = extend({pack(splitReadInFlight),pack(initOpInFlight)
   ,pack(dacCore0.isTrue),pack(dacCore0.isFalse),pack(dacCore0.dcmLocked),pack(dacCore0.isInited)});
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[11:10]) matches
     'b00 : case (wciReq.addr[7:0]) matches
       'h00 : rdat = extend(pack(wsiS.status));
       'h04 : rdat = dacStatusLs;
       'h0C : rdat = dacControl;
       'h10 : rdat = extend(fcDac); // multiply by 8*2 for DAC sample rate
       'h14 : rdat = dacCore0.dacSampleDeq;
       'h18 : rdat = mesgCount;
       'h28 : rdat = popCount;
       'h2C : rdat = extend(unrollCnt);
       'h30 : rdat = syncCount;
       'h34 : rdat = mesgStart;
       'h38 : rdat = dacCore0.underflowCnt;
       'h3C : rdat = stageCount;
       'h48 : rdat = wsiS.extStatus.pMesgCount;
       'h4C : rdat = wsiS.extStatus.iMesgCount;
       'h50 : rdat = wsiS.extStatus.tBusyCount;
       endcase
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
   else splitReadInFlight <= True;
endrule

rule pass_control;
  dacCore0.dacCtrl(dacControl[3:0]);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  dacCore0.doInitSeq;
  initOpInFlight <= True;
endrule

rule init_complete_ok(initOpInFlight && dacCore0.isInited);
  initOpInFlight <= False;
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv); // Convert the conventional to explicit 

  interface Wci_s wci_s = wci.slv;
  interface Wti_s wti_s = wti.slv;
  interface Wsi_s wsiS1 = wsi_Es;
  interface Max19692Ifc dac0 = dacCore0.dac;
endmodule

