// AD9777.bsv - TI AD9777 Interpolating TX DAC Specific Logic
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package AD9777;

import SPICore      ::*;
import OCWip        ::*;

import BRAMFIFO     ::*;
import Clocks       ::*;
import Connectable  ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;
import DefaultValue ::*;

export AD9777       ::*;

// Src-Side methods...
interface SyncFIFOSrcIfc #(type a_type) ;
  method Action enq ( a_type sendData ) ;
  method Bool notFull () ;
endinterface

// Dst-Side methods...
//interface SyncFIFODstIfc #(type a_type) ;
//  method Action   deq  () ;
//  method a_type  first () ;
//  method Bool notEmpty () ;
//endinterface

// The interface declaration of the device-package-pins for the TI AD9777 device...
(* always_enabled, always_ready *)  // DAC pads ...
interface AD9777_Pads;
  // CMOS SDR link...
  method Action   lock (Bit#(1) i);
  method Bit#(16) da;
  method Bit#(16) db;
  // Serial Control...
  method Clock   sclk;
  method Clock   sclkn;
  //method Reset   rst;
  //method Bit#(1) resetp;
  method Bit#(1) sen;
  method Bit#(1) smosi;
  method Action  smiso (Bit#(1) i);
endinterface: AD9777_Pads 

// The interface declaration of the DAC methods... 
interface AD9777_User;
  method Action        operate;
  method Action        acquire;
  method Action        average;
  method Action        now             (Bit#(64) arg);
  method Action        maxBurstLength  (Bit#(16) arg);
  method SampleStats   stats;
  method Bit#(32)      sampleSpy;   // last two samples MS first
  method Put#(SpiReq)  req;         // spi requests
  method Get#(Bit#(8)) resp;        // spi responses
  method Action        doInitSeq;   // do chip init
  method Bool          isInited;    // chip is init-ed
endinterface: AD9777_User

interface AD9777Ifc;
  interface AD9777_Pads              pads;
  interface AD9777_User              user;
  interface SyncFIFODstIfc#(SampMesg) capF;
  interface Clock                     adcSdrClk;
  interface Reset                     adcSdrRst;
endinterface: AD9777Ifc


module mkAD9777#(Clock adcClk, Clock adcCapture) (AD9777Ifc);

  //DDRCaptureIfc           ddrC         <-   mkDDRCapture(ddrClk);
  Reg#(Bit#(14))          iobA         <-   mkRegU(clocked_by adcCapture);
  Reg#(Bit#(14))          iobB         <-   mkRegU(clocked_by adcCapture);

  //Clock                   sdrClk       =    ddrC.sdrClk;
  //Clock                   sdrClk       <-   exposeCurrentClock;
  Clock                   sdrClk       =    adcClk;
  Reset                   sdrRst       <-   mkAsyncResetFromCR(2, sdrClk);
  CollectGateIfc          colGate      <-   mkCollectGate(clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              operateDReg  <-   mkDReg(False);
  Reg#(Bool)              acquireDReg  <-   mkDReg(False);
  Reg#(Bool)              averageDReg  <-   mkDReg(False);
  Reg#(Bool)              operateD     <-   mkSyncRegFromCC(False, sdrClk);
  Reg#(Bool)              acquireD     <-   mkSyncRegFromCC(False, sdrClk);
  Reg#(Bool)              averageD     <-   mkSyncRegFromCC(False, sdrClk);
  Reg#(SampleStats)       statsCC      <-   mkSyncRegToCC(unpack(0), sdrClk, sdrRst);
  Reg#(Bit#(32))          samp         <-   mkRegU(clocked_by sdrClk, reset_by sdrRst); //TODO: consider prune of this rank
  Reg#(Bit#(32))          sampCC       <-   mkSyncRegToCC('0, sdrClk, sdrRst);
  SyncFIFOIfc#(SampMesg)  sampF        <-   mkSyncBRAMFIFOToCC(512, sdrClk, sdrRst);
  Wire#(Bit#(64))         nowW         <-   mkWire(clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(16))      maxBurstLengthR  <-   mkSyncRegFromCC(0, sdrClk);

  //let capture_samp <- mkConnection(ddrC.sdrData, samp._write); // register in sdrClk domain

  rule update_sampCC; sampCC._write(samp); endrule             // writing the sampCC synchronizer
  

  rule pipe;
    operateD  <= operateDReg;
    acquireD  <= acquireDReg;
    averageD  <= averageDReg;
  endrule

  rule r_operate (operateD);  colGate.operate;          endrule
  rule r_collect (acquireD);  colGate.collect;          endrule
  rule r_average (averageD);  colGate.average;          endrule
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
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h50, wdata:8'h06});  // Data Format: 2's complement
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h51, wdata:8'h34});  // Data Pattern low
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h52, wdata:8'h12});  // Data Pattern High
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h54, wdata:8'h40});  // Enable Offset Correction Servo
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h55, wdata:8'h10});  // Fine Gain is +0.5dB : Offset TC is 256K samples
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
  interface AD9777_Pads              pads;
    method Bit#(1) oe = pack(True); // Output buffer enable, active-high
    method Action da (Bit#(14) i) = iobA._write(i);
    method Action db (Bit#(14) i) = iobB._write(i);
    method Clock   sclk   = spiI.sclk;
    method Clock   sclkn  = spiI.sclkn;
    method Reset   rst    = spiI.srst;
    method Bit#(1) sen    = spiI.csb;
    method Bit#(1) resetp = pack(adcRst);
    method Bit#(1) smosi  = spiI.sdo;
    method Action  smiso (Bit#(1) i); action spiI.sdi(i); endaction endmethod
  endinterface

  interface AD9777_User              user;
  method Action  operate = operateDReg._write(True);
  method Action  acquire = acquireDReg._write(True);
  method Action  average = averageDReg._write(True);
  method Action  now             (Bit#(64) arg) = nowW._write(arg);
  method Action  maxBurstLength  (Bit#(16) arg) = maxBurstLengthR._write(arg);
  method SampleStats   stats    = statsCC;
  method Bit#(32)    sampleSpy  = sampCC;
  interface          req        = toPut(reqF);
  interface          resp       = spiI.resp;
  method Action doInitSeq       = iseqFsm.start;
  method Bool   isInited        = iseqFsm.done;
  endinterface

  interface SyncFIFODstIfc capF; 
    method Action   deq  () = sampF.deq;
    method         first () = sampF.first;
    method Bool notEmpty () = sampF.notEmpty;
  endinterface


  interface Clock adcSdrClk = sdrClk;
  interface Reset adcSdrRst = sdrRst;

endmodule: mkAD9777

endpackage: AD9777
