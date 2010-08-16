// TimeGate.bsv - A module that provides a gate/dwell from a uniform control structure
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package TimeGate;

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;	
import FIFO::*;
import GetPut::*;
import Vector::*;
import Synchronizer::*;

typedef struct {
  Bool gatedDwell;  // When True, enables the dwellGate logic; When False, dwellGate is simply asserted
  Bool periodic;    // When True, enables the periodic self retrigger generated from the period
  Bit#(4)  syncEn;  // Selects which syncEn input(s) are used to reset the start, dwell, and period counters
  Bit#(32) start;   // Integer number of iso clock cycles after trigger event until the dwell begins
  Bit#(32) dwell;   // Integer number of iso clock cycles that dwell is active after the start interval
  Bit#(32) period;  // Integer number of iso clock cycles (> start+dwell) where TimeGate will self retrigger
} TimeGateControl deriving (Bits, Eq);

interface TimeGateControlIfc;
  method Action  setControlA  (TimeGateControl arg);  // Control Bank A
  method Action  setControlB  (TimeGateControl arg);  // Control Bank B
endinterface

interface TimeGateIsoIfc;
  method Action  syncIn (Bit#(4) arg);
  method Bool    dwellGate;
  method Bool    syncOut;   // Pulses in phase with the internal sync
endinterface

interface TimeGateIfc;
  interface TimeGateControlIfc ctrl; // The Control sub-interface
  interface TimeGateIsoIfc     iso;  // The Isonchronous sub-interface
endinterface

module mkTimeGate#(Clock iso_clk, Reset iso_rst) (TimeGateIfc);

  // Sofware Control Interface State...
  Reg#(TimeGateControl)    ctlA            <- mkSyncRegFromCC(unpack(0), iso_clk, iso_rst);
  Reg#(TimeGateControl)    ctlB            <- mkSyncRegFromCC(unpack(0), iso_clk, iso_rst);

  // Isochronous Clock Timebase...
  Reg#(Bool)               tgRunning       <- mkReg(False,  clocked_by iso_clk, reset_by iso_rst);
  Reg#(Bool)               intSync         <- mkDReg(False, clocked_by iso_clk, reset_by iso_rst);
  Reg#(Bit#(32))           startCount      <- mkReg(0,      clocked_by iso_clk, reset_by iso_rst);
  Reg#(Bit#(32))           dwellCount      <- mkReg(0,      clocked_by iso_clk, reset_by iso_rst);
  Reg#(Bit#(32))           periodCount     <- mkReg(0,      clocked_by iso_clk, reset_by iso_rst);

  Bool     actDwellGate  = ((activeBankA) ? ctlA : ctlB).gatedDwell;
  Bit#(32) actDwellStart = ((activeBankA) ? ctlA : ctlB).start;
  Bit#(32) actDwellEnd   = ((activeBankA) ? ctlA : ctlB).dwell;
  Bit#(32) actPeriodEnd  = ((activeBankA) ? ctlA : ctlB).period;

  Bool startCountEna  = tgRunning && (startCount  < maxBound);
  Bool dwellCountEna  = tgRunning && (dwellCount  < maxBound) && (startCount >= actDwellStart);
  Bool periodCountEna = tgRunning && (periodCount < maxBound);

  (* fire_when_enabled, no_implicit_conditions *) // Assert that this rule will always fire on every XO cycle
  rule every_iso_cycle;
     startCount   <= (intSync) ? 0 : (startCountEna)  ? startCount  + 1 : startCount;
     dwellCount   <= (intSync) ? 0 : (dwellCountEna)  ? dwellCount  + 1 : dwellCount;
     periodCount  <= (intSync) ? 0 : (periodCountEna) ? periodCount + 1 : periodCount;
  endrule
 

  // Interfaces Provided...
  interface TimeGateControlIfc ctrl; // The Control sub-interface
    method Action setControlA  (TimeGateControl arg) = ctlA._write(arg);
    method Action setControlB  (TimeGateControl arg) = ctlB._write(arg);
  endinterface

  interface TimeGateIsoIfc     iso;  // The Isonchronous sub-interface
    method Action  syncIn (Bit#(4) arg);
    method Bool    dwellGate = !actDwellGate || (tgRunning && dwellCountEna && (dwellCount < actDwellEnd));
    method Bool    syncOut   = intSync;   
  endinterface

endmodule: mkTimeGate
