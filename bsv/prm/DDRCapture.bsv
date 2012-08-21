// DDRCapture.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import Vector::*;

(* always_ready, always_enabled *)
interface VDDRCaptureIfc;
  // Pad-Facing...
  method Action    ddrp      (Bit#(7) arg);
  method Action    ddrn      (Bit#(7) arg);
  // Inward-Facing...
  method Action    psEna     (Bool arg);
  method Action    psInc     (Bool arg);
  interface Clock  sdrClk;
  method Bit#(14)  sdrData0;
  method Bit#(14)  sdrData1;
endinterface

// See the comments at the head of ddrInput2.v for details...
import "BVI" ddrInput2=
module vMkDDRCapture#(Clock ddrCk) (VDDRCaptureIfc);

  default_clock  clk     (psClk)      <- exposeCurrentClock;
  default_reset  rst     (psRstN)     <- exposeCurrentReset;
  input_clock    ddrCk   (ddrClk)     = ddrCk;
  output_clock   sdrClk  (sdrClk);

  method ddrp (ddrDataP)    enable((*inhigh*)en0) clocked_by(ddrCk)  reset_by(no_reset);
  method ddrn (ddrDataN)    enable((*inhigh*)en1) clocked_by(ddrCk)  reset_by(no_reset);
  method psEna (psEna)      enable((*inhigh*)en2);
  method psInc (psInc)      enable((*inhigh*)en3);
  method sdrData0 sdrData0()                      clocked_by(sdrClk) reset_by(no_reset);
  method sdrData1 sdrData1()                      clocked_by(sdrClk) reset_by(no_reset);

  schedule (ddrp, ddrn, psEna, psInc, sdrData0, sdrData1)
  CF       (ddrp, ddrn, psEna, psInc, sdrData0, sdrData1);
endmodule


typedef enum {Nop,Rsvd,Dec,Inc} PsOp deriving (Bits, Eq);

interface DDRCaptureIfc;
  // Pad-Facing...
  (*always_ready, always_enabled*) method Action ddp (Bit#(7) arg);
  (*always_ready, always_enabled*) method Action ddn (Bit#(7) arg);
  // Inward-Facing...
  method Clock     sdrClk;
  method Bit#(32)  sdrData;
  method Action    psCmd (PsOp op);
endinterface

module mkDDRCapture#(Clock ddrCk) (DDRCaptureIfc);
  VDDRCaptureIfc      ddrV       <- vMkDDRCapture(ddrCk);
  Reg#(PsOp)          psCmdReg   <- mkDReg(Nop);

  rule psControl;
    ddrV.psEna(unpack(pack(psCmdReg)[0]));
    ddrV.psInc(unpack(pack(psCmdReg)[1]));
  endrule

  //TODO: More BSV logic here, delay controller, etc

  method Action ddp (Bit#(7) arg) = ddrV.ddrp(arg);
  method Action ddn (Bit#(7) arg) = ddrV.ddrn(arg);
  method Clock     sdrClk  = ddrV.sdrClk;
  //method Bit#(32)  sdrData = {2'h0,ddrV.sdrData1,2'h0,ddrV.sdrData0};  // Place 14b samples little-endian, LSB justfied
  method Bit#(32)  sdrData = {ddrV.sdrData1,2'h0,ddrV.sdrData0,2'h0};    // Place 14b samples little-endian, MSB justfied
  method Action psCmd (PsOp op) = psCmdReg._write(op);
endmodule
