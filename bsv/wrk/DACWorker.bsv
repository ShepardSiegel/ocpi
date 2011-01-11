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
  interface WciES                wciS0;   // WCI
  interface Wti_s#(64)           wtiS0;   // WTI
  interface Wsi_Es#(12,32,4,8,0) wsiS0;   // WSI DAC Slave
  interface P_Max19692Ifc dac0;           // Maxim 19662
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDACWorker#(Clock dac_clk, Reset dac_rst) (DACWorkerIfc);
  WciESlaveIfc                wci                 <-  mkWciESlave;              // WCI
  WtiSlaveIfc#(64)            wti                 <-  mkWtiSlave(clocked_by dac_clk, reset_by dac_rst); 
  Reg#(Bool)                  sFlagState          <-  mkReg(False);             // Worker Attention
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);             // Split WCI Read
  Reg#(Bool)                  initOpInFlight      <-  mkReg(False);             // Asserted While Init-ing
  Max19692Ifc                 dacCore0            <-  mkMax19692(dac_clk);      // DAC
  Clock                       dacSdrClk           =   dacCore0.dac.dacSdrClk;
  FreqCounterIfc#(16)         fcDac               <-  mkFreqCounter(dacSdrClk); // Measure DAC SDR clock 1/16 DAC Clk
  CounterMod#(Bit#(18))       oneKHz              <-  mkCounterMod(125000);
  Reg#(Bit#(32))              dacControl          <-  mkReg(32'h0000_0008);
  Reg#(Bit#(32))              firstUnderflowMesg  <-  mkReg('1);
  Reg#(Bool)                  hasUnderflowed      <-  mkReg(False);
  WsiSlaveIfc#(12,32,4,8,0)   wsiS                <-  mkWsiSlave;               //nd=32 not poly
  Reg#(Bit#(32))              syncCount           <-  mkReg(0);
  Reg#(Bit#(32))              mesgStart           <-  mkReg(0);
  Reg#(Maybe#(Bit#(8)))       opcode              <-  mkReg(tagged Invalid);
  Reg#(Bit#(2))               srcCnt              <-  mkReg(0);
  Vector#(16,Reg#(Bit#(12)))  rf                  <-  replicateM(mkReg(0));
  Reg#(Bit#(32))              stageCount          <-  mkReg(0);
  Reg#(Bool)                  takeEven            <-  mkReg(True);               // start with 0, little-endian
  FIFOF#(Bit#(32))            stageF              <-  mkFIFOF;
  Reg#(UInt#(8))              wordsConsumed       <-  mkReg(0);

  Integer myWordShift = 2; // log2(4) 4B Wide WSI

  Bool invertMSB = unpack(dacControl[6]);
  Bool upConv16x = unpack(dacControl[5]);

rule operating_actions (wci.isOperating); wsiS.operate(); endrule

rule emit_mesgBegin (wci.isOperating && !isValid(opcode));
  mesgStart <= mesgStart + 1;
  opcode <= tagged Valid wsiS.reqPeek.reqInfo;
endrule

rule emit_mesgConsume (wci.isOperating && isValid(opcode));
  WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get; // ActionValue consume from WSI
  if (invertMSB) begin
    w.data[31] = ~w.data[31];
    w.data[15] = ~w.data[15];
  end
  stageF.enq(w.data);                        // First level data staging on stageF
  if (wordsConsumed < maxBound) wordsConsumed <= wordsConsumed + 1;
  if (w.reqLast) opcode <= tagged Invalid;
endrule

rule process_staged_data (wci.isOperating);
  let sd = stageF.first;
  if (!upConv16x) begin
    case (srcCnt)
      2'h0:  begin rf[0]  <= sd[15:4];  rf[1]  <= sd[15:4]; rf[2]   <= sd[31:20];  rf[3]  <= sd[31:20]; end
      2'h1:  begin rf[4]  <= sd[15:4];  rf[5]  <= sd[15:4]; rf[6]   <= sd[31:20];  rf[7]  <= sd[31:20]; end
      2'h2:  begin rf[8]  <= sd[15:4];  rf[9]  <= sd[15:4]; rf[10]  <= sd[31:20];  rf[11] <= sd[31:20]; end
      2'h3:  begin rf[12] <= sd[15:4];  rf[13] <= sd[15:4]; rf[14]  <= sd[31:20];  rf[15] <= sd[31:20]; 
             //dacCore0.smpF.enq(readVReg(rf));
             dacCore0.smpF.enq(readVReg(rf));  // FIXME
             stageCount <= stageCount + 1;
             end
    endcase
    srcCnt <= srcCnt + 1;
    stageF.deq;               // consume 2 source samples every 4 target DAC samples   2x replicate
  end else begin
    Bit#(12) repeatData = (takeEven) ? sd[15:4] : sd[31:20];
    //writeVReg(rf, replicate(repeatData));
    //dacCore0.smpF.enq(readVReg(rf));
    dacCore0.smpF.enq(replicate(repeatData)); // 16 samples at once!
    stageCount <= stageCount + 1;
    takeEven <= !takeEven;
    if (!takeEven) stageF.deq; // consume 2 source sample every 32 target DAC samples  16x replicate
  end
endrule

rule doEmit (wci.isOperating && unpack(dacControl[4]) && wordsConsumed>127); // wait for 128 Words, 256 WSI samples
  dacCore0.emitEn();
endrule

rule doTone (wci.isOperating && unpack(dacControl[7]));
  dacCore0.toneEn();
endrule

rule capture_underflow(wci.isOperating && !hasUnderflowed && dacCore0.underflowCnt!=0);
  firstUnderflowMesg <= mesgStart;
  hasUnderflowed     <= True;
endrule

rule inc_modcnt; oneKHz.inc(); endrule
rule send_pulse (oneKHz.tc);
 fcDac.pulse();  // measure KHz
endrule

rule updateSflag (sFlagState); action wci.drvSFlag; endaction endrule
rule do_operating (wci.isOperating); endrule

(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
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
       'h24 : rdat = firstUnderflowMesg;
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

rule wci_ctrl_IsO ((wci.isInitialized || wci.isSuspended) && wci.ctlOp==Start);
  // Any actions from (INITIALIZED or SUSPENDED) to OPERATING state
  wci.ctlAck;
endrule

rule wci_ctrl_OperatingToSuspended(wci.isOperating && wci.ctlOp==Stop);
  // Any actions from OPERATING to SUSPENED state
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv); // Convert the conventional to explicit 

  interface Wci_s    wciS0 = wci.slv;
  interface Wti_s    wtiS0 = wti.slv;
  interface Wsi_s    wsiS0 = wsi_Es;
  interface Max19692Ifc dac0 = dacCore0.dac;
endmodule

