// ICAPWorker.bsv - A dedvice worker for communicating with the ICAP
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum::*;
import ICAP::*;
import OCWip::*;
import SRLFIFO::*;

import Alias::*;
import AlignedFIFOs::*;
import Clocks::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import Vector::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface ICAPWorkerIfc;
  interface WciES wciS0;  // Worker Control and Configuration 
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkICAPWorker#(parameter Bool isV6ICAP, parameter Bool hasDebugLogic) (ICAPWorkerIfc);

  WciESlaveIfc                wci         <- mkWciESlave;
  Reg#(Bit#(32))              icapCtrl    <- mkReg(0);
  Reg#(Bit#(32))              dwWritten   <- mkReg(0);
  Reg#(Bit#(32))              dwRead      <- mkReg(0);

  ClockDividerIfc             cd          <- mkClockDivider(2);  // 125MHz/2 = 62.5 MHz
  Reset                       fastReset   <- exposeCurrentReset;
  Reset                       slowReset   <- mkAsyncResetFromCR(2, cd.slowClock);
  ICAPIfc                     icap        <- mkICAP(clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                  cwe         <- mkSyncRegFromCC(False, cd.slowClock);
  Reg#(Bool)                  cre         <- mkSyncRegFromCC(False, cd.slowClock);
  Store#(UInt#(0),Bit#(32),0) cinS        <- mkRegStore(cd.fastClock, cd.slowClock);
  AlignedFIFO#(Bit#(32))      cinF        <- mkAlignedFIFO(cd.fastClock,fastReset,cd.slowClock,slowReset,cinS,cd.clockReady,True);
  SyncFIFOIfc#(Bit#(32))      coutF       <- mkSyncBRAMFIFOToCC(512, cd.slowClock, slowReset);

  Reg#(Bit#(32))              inCnt       <- mkSyncRegToCC(0, cd.slowClock, slowReset);
  Reg#(Bit#(32))              outCnt      <- mkSyncRegToCC(0, cd.slowClock, slowReset);


  Bool writeICAP  = unpack(icapCtrl[0]);
  Bool readICAP   = unpack(icapCtrl[1]);

  rule update_control (wci.isOperating);
    cwe <= writeICAP;
    cre <= readICAP;
  endrule

  rule connect_cwe; icap.configWriteEnable(cwe); endrule
  rule connect_cre; icap.configReadEnable(cre);  endrule
  rule connect_inc;  inCnt  <= icap.dwInCount; endrule
  rule connect_outc; outCnt <= icap.dwOutCount; endrule

  rule config_write;
     icap.configIn.put(cinF.first);
     cinF.deq;
  endrule

  rule config_read;
    let y <- icap.configOut.get;
    coutF.enq(y);
  endrule

// WCI...

Bit#(32) icapStatus = extend({pack(coutF.notEmpty), pack(readICAP), pack(writeICAP)});

(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h04 : icapCtrl <= unpack(wciReq.data);
     'h08 : cinF.enq(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(icapStatus);
     'h04 : rdat = pack(icapCtrl);
     'h0C : begin rdat = pack(coutF.first); coutF.deq; end
     'h40 : rdat = !hasDebugLogic ? 0 : pack(dwWritten);
     'h44 : rdat = !hasDebugLogic ? 0 : pack(dwRead);
     'h48 : rdat = !hasDebugLogic ? 0 : pack(inCnt);
     'h4C : rdat = !hasDebugLogic ? 0 : pack(outCnt);
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting ICAPyWorker", $time);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  interface Wci_s wciS0  = wci.slv;
endmodule
