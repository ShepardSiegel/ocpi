// Memory.bsv - Design Examples for Memory Inference
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import Vector::*;

interface DelayIfc;
  method Action  write (Bit#(32) arg);
  method ActionValue#(Bit#(32)) read;
endinterface 

(* synthesize *)
module mkDelay (DelayIfc);

  Reg#(Bit#(4))             wag     <- mkReg(0);
  Reg#(Bit#(4))             rag     <- mkReg(0);
  Vector#(4,Reg#(Bit#(32))) regs    <- replicateM(mkRegU);

  method Action write (Bit#(32) arg); 
     wag <= wag + 0;
     regs[wag] <= arg;
  endmethod

  method ActionValue#(Bit#(32)) read;
     rag <= rag + 1; 
     return(regs[rag]);
  endmethod

endmodule

