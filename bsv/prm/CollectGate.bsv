// CollectGate.bsv - Gated Sample Capture and Collection 
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package CollectGate;

import OCWip::*;
import SRLFIFO::*;

import DReg::*;
import FIFOF::*;	
import GetPut::*;
import Vector::*;

// Sample Statistics of Collection Process...
typedef struct {
  Bit#(32) dropCount;   // number of samples dropped   (during dwell) since operational
  Bit#(32) sampCount;   // number of samples collected (during dwell) since operational
  Bit#(32) dwellStarts; // number of dwell collection starts (leading-edge of collect) since operational
  Bit#(32) dwellFails;  // number of dwell collection failures (1 or more samples dropped in a dwell) since operational
} SampleStats deriving (Bits, Eq);

// The interface declaration of the ADC methods + the chip-level interface...
interface CollectGateIfc;
  method Action      operate;                       // Operational State
  method Action      collect;                       // Gated Collection Indication
  method Action      average;                       // Average 4 samples
  method Action      enableSync;                    // Enable Sync at capture start
  method Action      enableTimestamp;               // Enable Timestamp at capture start
  method Action      now          (Bit#(64) arg);   // Current Time
  method Action      maxBurstLen  (Bit#(16) arg);   // Maximum number of message words
  method Action      sampData     (Bit#(32) arg);   // Isochronous Ungated Sample Data Input
  method     SampleStats    stats;                  // Collection Statistics
  interface  Get#(SampMesg) sampMesg;               // Asynchronous Message Output
endinterface: CollectGateIfc

module mkCollectGate (CollectGateIfc);
  FIFOF#(SampMesg)      sampF           <-  mkSRLFIFOD(4);
  PulseWire             operatePW       <-  mkPulseWire;
  PulseWire             collectPW       <-  mkPulseWire;
  Wire#(Bool)           average_dw      <-  mkDWire(False);
  PulseWire             enaSyncPW       <-  mkPulseWire;
  PulseWire             enaTimestampPW  <-  mkPulseWire;
  Reg#(Bool)            collectD        <-  mkReg(False);
  Reg#(Bool)            sampActive      <-  mkDReg(False);
  Reg#(Bool)            sampActiveD     <-  mkReg(False);
  Wire#(Bit#(64))       nowW            <-  mkWire;
  Wire#(Bit#(16))       maxBurstLenW    <-  mkWire;
  Wire#(Bit#(32))       sampDataW       <-  mkWire;
  Reg#(Bit#(32))        sampDataWD      <-  mkRegU;
  Reg#(Bit#(32))        dwellStarts     <-  mkReg(0);
  Reg#(Bit#(32))        sampCount       <-  mkReg(0);
  Reg#(Bit#(32))        dwellFails      <-  mkReg(0);
  Reg#(Bit#(32))        dropCount       <-  mkReg(0);
  Reg#(Bit#(16))        uprollCnt       <-  mkReg(0);
  Reg#(Bit#(4))         ovrRecover      <-  mkReg(0);
  Reg#(Bit#(3))         timeMesg        <-  mkReg(0);
  Reg#(Bit#(2))         syncMesg        <-  mkReg(0);
  Reg#(Bit#(2))         avgPhase        <-  mkReg(0);
  Reg#(Bit#(18))        avgEven         <-  mkReg(0);
  Reg#(Bit#(18))        avgOdd          <-  mkReg(0);
  //Wire#(Bit#(32))       avgDataBW       <-  mkBypassWire;

  Bool collectRising = (collectPW && !collectD);         // Rising edge of the collection (dwell) activity
  Bool activeRising  = (sampActive && !sampActiveD);     // Rising edge of active sample availability (e.g. dynamic ingress)
  Bool eitherRising  = (collectRising || activeRising);  // Either the start of collection (dwell) or active (available)

  (* fire_when_enabled *) rule pipeline_registers (operatePW); collectD<=collectPW; sampActiveD<=sampActive; endrule

  // Hold known, intialized, idle state when non-operational...
  rule non_operational_init (!operatePW);
    uprollCnt<=0; ovrRecover<=0; timeMesg<=0; collectD<=False; sampF.clear(); // Reset Internal State
    dwellStarts<=0; sampCount<=0; dwellFails<=0; dropCount<=0;                // Zero statistics
    sampActiveD <= False; syncMesg<=0;
  endrule

  rule send_timestamp_mesg (operatePW && timeMesg!=0); // Send 8B Time and 16B Statistics (24B Message)...
    SampMesg d = ?; d.opcode=Timestamp; d.be='1;
    case (timeMesg)
      3'h6 : d.data = nowW[63:32];
      3'h5 : d.data = nowW[31:00];
      3'h4 : d.data = dropCount; 
      3'h3 : d.data = sampCount;
      3'h1 : d.data = dwellStarts; 
      3'h2 : d.data = dwellFails;
    endcase
    d.last = (timeMesg==1);
    sampF.enq(d);
    timeMesg <= timeMesg - 1;
  endrule

  rule send_sync_mesg (operatePW && syncMesg!=0 && timeMesg==0); // Send 0B Sync Message...
    SampMesg sMesg = SampMesg{opcode:Sync, last:True, be:0, data:0};
    sampF.enq(sMesg);
    syncMesg <= syncMesg - 1;
  endrule

  // Product-Terms common to the next three rule predicates...
  Bool attemptSampleEnq = (operatePW && timeMesg==0 && collectPW && collectD); 

  (* descending_urgency = "overrun_recovery, count_dropped_samples, capture_collect" *)

  (* fire_when_enabled *)   // Send the sample data...
  rule capture_collect (attemptSampleEnq && syncMesg==0 && ovrRecover==0 && (!average_dw || (average_dw && avgPhase==0)) );
    Bool lastSample = (uprollCnt==maxBurstLenW-1); 
    Bit#(32) avgDataBW = {(avgOdd>>2)[15:0], (avgEven>>2)[15:0]};
    SampMesg d = SampMesg { data:(average_dw)?avgDataBW:sampDataW, opcode:Sample, last:lastSample, be:'1 };
    sampCount <= sampCount + 1;
    uprollCnt <= (lastSample) ? 0 : uprollCnt + 1;
    sampF.enq(d);
  endrule

  (* fire_when_enabled *)   // create the 4:1 averaged avgDataW for use in avg4 mode...
  rule form_avg4_sample (operatePW);
    case (avgPhase)
      0: avgEven <=           extend(sampDataW[31:16]) + extend(sampDataW[15:0]);
      1: avgEven <= avgEven + extend(sampDataW[31:16]) + extend(sampDataW[15:0]);
      2: avgOdd  <=           extend(sampDataW[31:16]) + extend(sampDataW[15:0]);
      3: avgOdd  <= avgOdd  + extend(sampDataW[31:16]) + extend(sampDataW[15:0]);
    endcase
    avgPhase <= avgPhase + 1;
  endrule

  // ... unless we can't sucessfully enque the sample FIFO...
  rule count_dropped_samples(attemptSampleEnq  && sampActive && !sampF.notFull);
    if (ovrRecover==0) begin
      sampDataWD <= sampDataW; // save the last continious sample for subsequent enq
      ovrRecover <= 15;
      dwellFails <= dwellFails + 1;
    end
    dropCount <= dropCount + 1; // Maintain a count of dropped samples
  endrule

  // Place the last continious sample before overrun in the stream, and reset the uproll count...
  //   note that this rule wont *first* fire after overrun until we can again enq the sampFIFO
  //   This rule terminates the imprecise burst with the last continious sample of the mesage before overrrun
  rule overrun_recovery (attemptSampleEnq && ovrRecover!=0);
    if (ovrRecover==15) begin
      SampMesg d = SampMesg { data:sampDataWD, opcode:Sample, last:True, be:'1 };
      uprollCnt <= 0;
      sampF.enq(d);
    end
    ovrRecover <= ovrRecover - 1;
  endrule

  rule timestamp_trigger (operatePW && enaTimestampPW && eitherRising && timeMesg==0 && ovrRecover==0); timeMesg <= 6; endrule
  rule sync_trigger      (operatePW && enaSyncPW      && eitherRising && syncMesg==0 && ovrRecover==0); syncMesg <= 1; endrule
  rule count_dwells      (operatePW && collectRising); dwellStarts<=dwellStarts+1; endrule

  // Interfaces Provided...
  method Action  operate = operatePW.send;
  method Action  collect = collectPW.send;
  method Action  average = average_dw._write(True);
  method Action  enableSync      = enaSyncPW.send;
  method Action  enableTimestamp = enaTimestampPW.send;
  method Action  now         (Bit#(64) arg) = nowW._write(arg);
  method Action  maxBurstLen (Bit#(16) arg) = maxBurstLenW._write(arg);
  method Action  sampData    (Bit#(32) arg);
    sampDataW  <= arg;
    sampActive <= True;
  endmethod
  method SampleStats  stats = SampleStats{dwellStarts:dwellStarts,sampCount:sampCount,dwellFails:dwellFails,dropCount:dropCount};
  interface Get sampMesg = toGet(sampF);

endmodule: mkCollectGate

endpackage: CollectGate
