// TI6149.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package TI6149;

import DDRCapture::*;
import SPICore::*;
import OCWip::*;
import CollectGate::*; 

import BRAMFIFO::*;
import Clocks::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import DefaultValue::*;

// Src-Side methods...
//interface SyncFIFOSrcIfc #(type a_type) ;
//  method Action enq ( a_type sendData ) ;
//  method Bool notFull () ;
//endinterface

// Dst-Side methods...
interface SyncFIFODstIfc #(type a_type) ;
  method Action   deq  () ;
  method a_type  first () ;
  method Bool notEmpty () ;
endinterface

// The interface declaration of the device-package-pins for the TI ADS6149 device...
interface Ads6149Ifc;
  // LVDS DDR link...
  (*always_ready*) method Bit#(1) oe;
  (*always_ready, always_enabled*) method Action ddp (Bit#(7) arg);
  (*always_ready, always_enabled*) method Action ddn (Bit#(7) arg);
  // Serial Control...
  (*always_ready*) method Clock   sclk;
  (*always_ready*) method Clock   sclkn;
  (*always_ready*) method Reset   rst;
  (*always_ready*) method Bit#(1) resetp;
  (*always_ready*) method Bit#(1) sen;
  (*always_ready*) method Bit#(1) sdata;
  (*always_ready, always_enabled*) method Action sdout (Bit#(1) arg);
endinterface: Ads6149Ifc 

// The interface declaration of the ADC methods + the chip-level interface...
interface Ti6149Ifc;
  method Action        operate;
  method Action        acquire;
  interface Clock adcSdrClk;
  interface Reset adcSdrRst;
  method Action        now             (Bit#(64) arg);
  method Action        maxBurstLength  (Bit#(16) arg);
  method SampleStats   stats;
  interface SyncFIFODstIfc#(SampMesg) capF;
  method Bit#(32)      sampleSpy;   // last two samples MS first
  method Put#(SpiReq)  req;         // spi requests
  method Get#(Bit#(8)) resp;        // spi responses
  method Action        doInitSeq;   // do chip init
  method Bool          isInited;    // chip is init-ed
  method Action   psCmd (PsOp op);  // phase-shift control
  interface Ads6149Ifc adc;         // the ADC chip pins
endinterface: Ti6149Ifc

module mkTi6149#(Clock ddrClk) (Ti6149Ifc);
  DDRCaptureIfc           ddrC         <-   mkDDRCapture(ddrClk);
  Clock                   sdrClk       =    ddrC.sdrClk;
  Reset                   sdrRst       <-   mkAsyncResetFromCR(2, sdrClk);
  CollectGateIfc          colGate      <-   mkCollectGate(clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              operateDReg  <-   mkDReg(False);
  Reg#(Bool)              acquireDReg  <-   mkDReg(False);
  Reg#(Bool)              operateD     <-   mkSyncRegFromCC(False, sdrClk);
  Reg#(Bool)              acquireD     <-   mkSyncRegFromCC(False, sdrClk);
  Reg#(SampleStats)       statsCC      <-   mkSyncRegToCC(unpack(0), sdrClk, sdrRst);
  Reg#(Bit#(32))          samp         <-   mkRegU(clocked_by sdrClk, reset_by sdrRst); //TODO: consider prune of this rank
  Reg#(Bit#(32))          sampCC       <-   mkSyncRegToCC('0, sdrClk, sdrRst);
  SyncFIFOIfc#(SampMesg)  sampF        <-   mkSyncBRAMFIFOToCC(512, sdrClk, sdrRst);
  Wire#(Bit#(64))         nowW         <-   mkWire(clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(16))      maxBurstLengthR  <-   mkSyncRegFromCC(0, sdrClk);

  let capture_samp <- mkConnection(ddrC.sdrData, samp._write); // register in sdrClk domain
  rule update_sampCC; sampCC._write(samp); endrule             // writing the sampCC synchronizer

  rule pipe;
    operateD <= operateDReg;
    acquireD <= acquireDReg;
  endrule

  rule r_operate (operateD);  colGate.operate;          endrule
  rule r_collect (acquireD);  colGate.collect;          endrule
  rule r_now     (True);      colGate.now(nowW);        endrule
  rule r_bl      (True);      colGate.maxBurstLen(maxBurstLengthR); endrule
  rule r_sampdat (True);      colGate.sampData(samp);   endrule
  rule get_stats (True);      statsCC <= colGate.stats; endrule
  let collection_path <- mkConnection(colGate.sampMesg, toPut(sampF));  // move SampMesg into sampF

  // The serial control path...
  SpiIfc               spiI      <-  mkSpi(False);
  Reg#(Bool)           adcRst    <-  mkDReg(False);
  Reg#(Bool)           readMode  <-  mkReg(False);
  FIFO#(SpiReq)        reqF      <-  mkFIFO;

  // TI ADS6149 reset and initialization sequence...
  Stmt iseq = 
  seq
    adcRst <= True;
    adcRst <= True;   // 16 nS Reset asserted
    delay(13);        // Wait 104 nS before any action
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h50, wdata:8'h04});  // Data Format
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h51, wdata:8'h34});  // Data Pattern low
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h52, wdata:8'h12});  // Data Pattern High
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h55, wdata:8'h10});  // Fine Gain : Offset Tc
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h62, wdata:8'h04});  // 14b Ramp
  endseq;
  FSM iseqFsm <- mkFSM(iseq);

  rule advance_spi_request (iseqFsm.done);  // Only allow access after iseqFsm initialization is done...
    let a = reqF.first;
    if          (a.rdCmd && !readMode) begin
      spiI.req.put(SpiReq {rdCmd:False, addr:8'h00, wdata:8'h01});  // Turn on readmode by writing 0x00 with (0x01)
      readMode <= True;
    end else if (!a.rdCmd && readMode) begin
      spiI.req.put(SpiReq {rdCmd:False, addr:8'h00, wdata:8'h00});  // Turn off readmode by writing 0x00 with (0x00)
      readMode <= False;
    end else begin
      spiI.req.put(a); // Move the request along
      reqF.deq;
    end
  endrule

  // Interfaces Provided...
  method Action  operate = operateDReg._write(True);
  method Action  acquire = acquireDReg._write(True);
  interface Clock adcSdrClk = sdrClk;
  interface Reset adcSdrRst = sdrRst;
  method Action  now             (Bit#(64) arg) = nowW._write(arg);
  method Action  maxBurstLength  (Bit#(16) arg) = maxBurstLengthR._write(arg);
  method SampleStats   stats = statsCC;
  interface SyncFIFODstIfc capF; 
    method Action   deq  () = sampF.deq;
    method         first () = sampF.first;
    method Bool notEmpty () = sampF.notEmpty;
  endinterface
  method Bit#(32)    sampleSpy  = sampCC;
  interface          req        = toPut(reqF);
  interface          resp       = spiI.resp;
  method Action doInitSeq       = iseqFsm.start;
  method Bool   isInited        = iseqFsm.done;
  method Action psCmd (PsOp op) = ddrC.psCmd(op);
  interface Ads6149Ifc adc;
    // LVDS DDR...
    method Bit#(1) oe = pack(True); // Output buffer enable, active-high
    method Action ddp (Bit#(7) arg) = ddrC.ddp(arg);
    method Action ddn (Bit#(7) arg) = ddrC.ddn(arg);
    // Serial control...
    method Clock   sclk   = spiI.sclk;
    method Clock   sclkn  = spiI.sclkn;
    method Reset   rst    = spiI.srst;
    method Bit#(1) sen    = spiI.csb;
    method Bit#(1) resetp = pack(adcRst);
    method Bit#(1) sdata  = spiI.sdo;
    method Action  sdout (Bit#(1) arg); action spiI.sdi(arg); endaction endmethod
  endinterface
endmodule: mkTi6149

endpackage: TI6149
