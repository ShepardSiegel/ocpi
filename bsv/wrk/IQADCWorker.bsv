// IQADCWorker.bsv - a quadrature (IQ) ADC Device Worker
// Copyright (c) 2009,2010,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package IQADCWorker;

import OCWip        ::*;
import SPICore      ::*;
import TI62P4X      ::*;
import CollectGate  ::*;
import FreqCounter  ::*;
import TimeService  ::*;
import CounterM     ::*;

import Connectable  ::*;
import Clocks       ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;
import XilinxCells  ::*;
import XilinxExtra  ::*;

export IQADCWorker  ::*;
export TI62P4X      ::*;

interface IQADCWorkerIfc;
  interface WciES      wciS0;                 // WCI
  interface Wti_s#(64) wtiS0;                 // WTI
  interface Wsi_Em#(12,32,4,8,0) wsiM0;       // WSI ADC Master
//(* prefix = "" *) interface AD9512Ifc adx;  // AD AD9512 Clock Driver
  interface TI62P4X_Pads adc;                 // TI ADS62P49 ADC Pads
  interface Clock adcSdrClk;
  interface Reset adcSdrRst;
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkIQADCWorker#(parameter Bool hasDebugLogic,
  Clock sys0_clk, Reset sys0_rst, Clock adc_clock, Reset adc_reset, Clock adcCaptureClk) (IQADCWorkerIfc);
  WciESlaveIfc         wci                <-  mkWciESlave;              // WCI
  Reg#(Bool)           sFlagState         <-  mkReg(False);             // Worker Attention
  Reg#(Bool)           splitReadInFlight  <-  mkReg(False);             // Asserted for Split Reads
  Reg#(Bool)           initOpInFlight     <-  mkReg(False);             // Asserted While Init-ing
  FreqCounterIfc#(18)  fcAdc              <-  mkFreqCounter(adc_clock); // Measure ADC clock
  CounterMod#(Bit#(18))oneKHz             <-  mkCounterMod(125000);
  TI62P4XIfc           adcCore            <-  mkTI62P4X(adc_clock, adcCaptureClk);
  WtiSlaveIfc#(64)     wti                <-  mkWtiSlave(clocked_by adcCore.adcSdrClk, reset_by adcCore.adcSdrRst); 
  Reg#(Bit#(8))        spiResp            <-  mkReg('1);
  Reg#(Bit#(32))       maxMesgLength      <-  mkReg(1024);
  Reg#(Bit#(32))       adcControl         <-  mkReg(0);
  Reg#(Bit#(32))       mesgCount          <-  mkReg(0);
  Reg#(Bit#(32))       lastOverflowMesg   <-  mkReg('1);
  WsiMasterIfc#(12,32,4,8,0)   wsiM       <-  mkWsiMaster; //nd=32 not poly
  Reg#(Bit#(32))       overflowCountD     <-  mkReg(0);

  Integer myWordShift = 2; // log2(4) 4B Wide WSI

(* fire_when_enabled *) rule wsiM_operate (wci.isOperating); wsiM.operate(); endrule

(* fire_when_enabled *)
rule operating_actions (wci.isOperating);
  adcCore.user.operate();
endrule

mkConnection(wti.now, adcCore.user.now);  // Pass the WTI Time data down to the ADC Core0

rule max_burst;
  adcCore.user.maxBurstLength(truncate(maxMesgLength>>myWordShift)); // convert Bytes to ndw-wide WSI Words burstLength
endrule

// This DEQ side of the collection FIFO is a message pump that reads sample messages and feeds WSI
// The heavier-lifing is done at the ENQ where opcodes are selected and message length is shaped
// TODO: Consider how we flush imprecise messages from capF in an orderly way when a worker is made non-operational
rule doMessage (wci.isOperating);
  let s = adcCore.capF.first;
  wsiM.reqPut.put (WsiReq     {cmd  : WR ,
                            reqLast : s.last,
                            reqInfo : extend(pack(s.opcode)),
                       burstPrecise : False,
                        burstLength : (s.last) ? 1 : '1,
                              data  : s.data,
                            byteEn  : '1,
                          dataInfo  : '0 });
  adcCore.capF.deq();
  if (s.last) mesgCount <= mesgCount + 1;
endrule

rule doMessageCleanPump (wci.ctlState!=Operating); adcCore.capF.deq(); endrule

rule doAcquire (wci.isOperating && !unpack(adcControl[0]));
  if (!unpack(adcControl[3]) || overflowCountD==0) adcCore.user.acquire();  // Pass dataMesgEnable down
endrule

rule doAverage (wci.isOperating && unpack(adcControl[4]));
  adcCore.user.average();  // Pass dataMesgEnable down
endrule

rule inc_modcnt; oneKHz.inc(); endrule
rule send_pulse (oneKHz.tc);
  fcAdc.pulse();  // measure KHz
endrule

rule updateSflag (sFlagState); action wci.drvSFlag; endaction endrule
rule do_operating (wci.isOperating); overflowCountD <= adcCore.user.stats.dwellFails; endrule
rule update_ovf_message (wci.isOperating && overflowCountD!=adcCore.user.stats.dwellFails);
  lastOverflowMesg <= mesgCount;
endrule


function Action completeSpiResponse(Bit#(8) arg);
 action
  spiResp  <= arg;
  if (splitReadInFlight) begin
    wci.respPut.put(WciResp{resp:DVA, data:extend(arg)});
    splitReadInFlight <= False;
  end
 endaction
endfunction

(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, get_adc_resp" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, get_adc_resp " *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[11:10]) matches
     'b00 :  case (wciReq.addr[7:0]) matches
       'h08 : maxMesgLength <= wciReq.data;
       'h0C : adcControl    <= wciReq.data;
       'h28 : adcCore.user.req.put  (SpiReq{rdCmd:unpack(wciReq.data[31]), addr:wciReq.data[15:8], wdata:wciReq.data[7:0]});
       endcase
     'b01 : adcCore.user.req.put (SpiReq{rdCmd:False, addr:wciReq.addr[9:2], wdata:wciReq.data[7:0]});
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule get_adc_resp; let a <- adcCore.user.resp.get; completeSpiResponse(a); endrule

rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
 Bool splitRead = False;
 Bit#(32) adcStatusLs = extend({3'b000, pack(splitReadInFlight),
   pack(initOpInFlight), 1'b0, pack(adcCore.user.isInited), 1'b1});
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[11:10]) matches
     'b00 : case (wciReq.addr[7:0]) matches
       'h00 : rdat = extend(pack(wsiM.status));
       'h04 : rdat = adcStatusLs;
       'h08 : rdat = maxMesgLength;
       'h0C : rdat = adcControl;
       'h14 : rdat = extend(fcAdc);
       'h18 : rdat = adcCore.user.stats.sampCount;
       'h1C : rdat = adcCore.user.sampleSpy;
       'h30 : rdat = extend(spiResp);
       'h34 : rdat = mesgCount;
       'h3C : rdat = adcCore.user.stats.dwellStarts;
       'h40 : rdat = adcCore.user.stats.dwellFails; 
       'h44 : rdat = lastOverflowMesg;
       'h50 : rdat = wsiM.extStatus.pMesgCount;
       'h54 : rdat = wsiM.extStatus.iMesgCount;
       'h58 : rdat = wsiM.extStatus.tBusyCount;
       'h5C : rdat = adcCore.user.stats.dropCount;
       'h60 : rdat = overflowCountD;
       endcase
     'b01 : begin adcCore.user.req.put(SpiReq{rdCmd:True, addr:wciReq.addr[9:2], wdata:'0}); splitRead=True; end
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
   else splitReadInFlight <= True;
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  adcCore.user.doInitSeq;  // ... ADC 
  initOpInFlight <= True;
endrule

rule init_complete_ok(initOpInFlight && adcCore.user.isInited);
  initOpInFlight <= False;
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  interface Wci_s wciS0      = wci.slv;
  interface Wti_s wtiS0      = wti.slv;
  interface Wsi_m wsiM0      = toWsiEM(wsiM.mas);
  interface TI62P4X_Pads adc = adcCore.pads;
  interface Clock adcSdrClk  = adcCore.adcSdrClk;
  interface Reset adcSdrRst  = adcCore.adcSdrRst;
endmodule: mkIQADCWorker

endpackage: IQADCWorker
