// Memory.bsv - Design Examples for Memory Inference
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import BRAM         ::*;
import DefaultValue ::*;
import Vector       ::*;

typedef Bit#(10) Taddr;  // 2^10 words deep
typedef Bit#(32) Tdata;  // 32b wide

(* synthesize *)
module mkBRAM100 (BRAM1Port#(Taddr, Tdata));

  BRAM_Configure cfg = defaultValue;
  BRAM1Port#(Taddr, Tdata) bram <- mkBRAM1Server(cfg);

  return(bram); // just expose the provided BRAM1Port interface

endmodule
