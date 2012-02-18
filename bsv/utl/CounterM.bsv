// CounterM.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package CounterM;

interface CounterM#(type t);
  method Action load(t nval);
  method Action setModulus(t nval);
  method Action inc();
  method Action dec();
  method Bool   tc;
  method t      _read();
endinterface

module mkCounterM (CounterM#(t))
 provisos(Arith#(t), Bits#(t, t_sz), Ord#(t), Eq#(t), Bounded#(t));

  Reg#(t)    value       <- mkReg(0);
  Reg#(t)    modulus     <- mkReg(maxBound);
  Wire#(t)   modulus_bw  <- mkBypassWire;
  PulseWire  incAction   <- mkPulseWire;
  PulseWire  decAction   <- mkPulseWire;

  rule ruleMod; modulus_bw <= modulus; endrule
  rule ruleInc( incAction && !decAction); value <= (value==modulus_bw) ? 0 : value+1; endrule
  rule ruleDec(!incAction &&  decAction); value <= (value==0) ? modulus_bw : value-1; endrule

  method Action inc() = incAction.send;
  method Action dec() = decAction.send;
  method Action load(t nval)       = value._write(nval);
  method Action setModulus(t nval) = modulus._write(nval-1);
  method Bool   tc = (value==modulus_bw);
  method t _read() = value;
endmodule


// Variant with fixed Modulus supplied as argument...

interface CounterMod#(type t);
  method Action load(t nval);
  method Action inc();
  method Action dec();
  method Bool   tc;
  method t      _read();
endinterface

module mkCounterMod#(t modulusArg) (CounterMod#(t))
 provisos(Arith#(t), Bits#(t, t_sz), Ord#(t), Eq#(t), Bounded#(t));

  Reg#(t)    value       <- mkReg(0);
  PulseWire  incAction   <- mkPulseWire;
  PulseWire  decAction   <- mkPulseWire;

  t modulus = modulusArg-1;

  rule ruleInc( incAction && !decAction); value <= (value==modulus) ? 0 : value+1; endrule
  rule ruleDec(!incAction &&  decAction); value <= (value==0) ? modulus : value-1; endrule

  method Action inc() = incAction.send;
  method Action dec() = decAction.send;
  method Action load(t nval) = value._write(nval);
  method Bool   tc = (value==modulus);
  method t _read() = value;
endmodule


// Variant counter that Saturates at maxBound or minBound of the Bounded type...

interface CounterSat#(type t);
  method Action load(t nval);
  method Action inc();
  method Action dec();
  method Bool   satMax;
  method Bool   satMin;
  method t      _read();
endinterface

module mkCounterSat (CounterSat#(t))
 provisos(Arith#(t), Bits#(t, t_sz), Ord#(t), Eq#(t), Bounded#(t));

  Reg#(t)    value       <- mkReg(0);
  PulseWire  incAction   <- mkPulseWire;
  PulseWire  decAction   <- mkPulseWire;

  rule ruleInc( incAction && !decAction); value <= (value==maxBound) ? value : value+1; endrule
  rule ruleDec(!incAction &&  decAction); value <= (value==minBound) ? value : value-1; endrule

  method Action inc() = incAction.send;
  method Action dec() = decAction.send;
  method Action load(t nval) = value._write(nval);
  method Bool satMax = (value==maxBound);
  method Bool satMin = (value==minBound);
  method t _read() = value;
endmodule

endpackage
