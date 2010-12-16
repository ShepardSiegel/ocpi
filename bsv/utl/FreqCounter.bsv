// FreqCounter.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Clocks      ::*;
import DReg        ::*;
import GrayCounter :: *;

interface FreqCounterIfc#(numeric type n);
  method Action    pulse;
  method Bit#(n)   _read;
  method Bit#(n)   currFreq;
  method Bit#(16)  sampleCnt;  // Rolling 16b sample count
endinterface

module mkFreqCounter#(Clock testClk) (FreqCounterIfc#(n)) provisos(Add#(1,a_,n));

  Clock            wciClk       <- exposeCurrentClock();
  Reset            wciRst       <- exposeCurrentReset();
  Reg#(Bool)       pulseAction  <- mkDReg(False);
  Reg#(Bit#(n))    countNow     <- mkReg('1);
  Reg#(Bit#(n))    countPast    <- mkReg('1);
  Reg#(Bit#(n))    frequency    <- mkReg('1);
  Reg#(Bit#(16))   sampleCount  <- mkReg(0);
  GrayCounter#(n)  grayCounter   <- mkGrayCounter(0, wciClk, wciRst, clocked_by testClk, reset_by noReset);

  rule gray_inc;
    grayCounter.incr();
  endrule

  rule once_per_period (pulseAction);
    countNow    <= grayCounter.dReadBin();
    countPast   <= countNow;
    frequency   <= countNow - countPast;
    sampleCount <= sampleCount + 1;
  endrule

  method Action pulse; pulseAction<=True; endmethod
  method Bit#(n)  _read()   = frequency;
  method Bit#(n)  currFreq  = frequency;
  method Bit#(16) sampleCnt = sampleCount;
endmodule
