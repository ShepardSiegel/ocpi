// Accum.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package Accum;

import DReg::*;

interface AccumulatorIfc#(type accT);
  method accT   _read();
  method Action load(accT ldval);
  method Action acc(accT inc);
endinterface

module mkAccumulator (AccumulatorIfc#(accT))
 provisos(Arith#(accT), Bits#(accT, accT_sz), Ord#(accT), Eq#(accT), Bounded#(accT));
  Reg#(accT)     value       <- mkReg(0);
  Wire#(accT)    acc1        <- mkDWire(0);

  rule accumulate; value <= value + acc1; endrule

  method accT _read() = value;
  method Action load(accT ldval) = value._write(ldval);
  method Action acc(accT inc)    = acc1._write(inc);
endmodule

interface Accumulator2Ifc#(type accT);
  method accT   _read();
  method Action load(accT ldval);
  method Action acc1(accT inc);
  method Action acc2(accT inc);
endinterface

module mkAccumulator2 (Accumulator2Ifc#(accT))
 provisos(Arith#(accT), Bits#(accT, accT_sz), Ord#(accT), Eq#(accT), Bounded#(accT));
  Reg#(accT)     value       <- mkReg(0);
  Wire#(accT)    acc_v1      <- mkDWire(0);
  Wire#(accT)    acc_v2      <- mkDWire(0);

  rule accumulate; value <= value + acc_v1 + acc_v2; endrule

  method accT _read() = value;
  method Action load(accT ldval) = value._write(ldval);
  method Action acc1(accT inc)   = acc_v1._write(inc);
  method Action acc2(accT inc)   = acc_v2._write(inc);
endmodule

module mkAccumulatorReg2 (Accumulator2Ifc#(accT))
 provisos(Arith#(accT), Bits#(accT, accT_sz), Ord#(accT), Eq#(accT), Bounded#(accT));

  Reg#(accT)     value       <- mkReg(0);
  Reg#(accT)     acc_v1      <- mkDReg(0);
  Reg#(accT)     acc_v2      <- mkDReg(0);

  rule accumulate; value <= value + acc_v1 + acc_v2; endrule

  method accT _read() = value;
  method Action load(accT ldval) = value._write(ldval);
  method Action acc1(accT inc)   = acc_v1._write(inc);
  method Action acc2(accT inc)   = acc_v2._write(inc);
endmodule

endpackage
