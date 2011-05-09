// DNA.bsv
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package DNA;

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import FIFOF::*;	
import StmtFSM::*;
import Vector::*;

(* always_ready, always_enabled *)
interface DNA_PORTIfc;
   method Bit#(1)    dOut;              // output of sr[56]
   method Action     dIn(Bit#(1) i);    // input to sr[0]
   method Action     read(Bool i);      // read loads the 57b shift register
   method Action     shift(Bool i);     // shift 
   method Action     clk(Bit#(1) i);    // device clock (UG360 suggests positive SetUp and Hold)
endinterface: DNA_PORTIfc

import "BVI" DNA_PORT =
module vDNA (DNA_PORTIfc);

   default_clock (NO_CONNECT);
   default_reset no_reset;

   method DOUT  dOut;
   method dIn   (DIN)   enable((*inhigh*)en0);
   method read  (READ)  enable((*inhigh*)en1);
   method shift (SHIFT) enable((*inhigh*)en2);
   method clk   (CLK)   enable((*inhigh*)en3);
      
   schedule (dOut, dIn, read, shift, clk) CF (dOut, dIn, read, shift, clk);

endmodule: vDNA


interface DNAIfc;
  method Bit#(57) deviceID;
  method Action   rescanID;
endinterface

module mkDNA (DNAIfc);

  DNA_PORTIfc          dna       <- vDNA;
  Reg#(Bit#(7))        cnt       <- mkReg(0);
  Reg#(Bool)           rdReg     <- mkDReg(False);
  Reg#(Bool)           shftReg   <- mkDReg(False);
  Reg#(Bit#(57))       sr        <- mkReg(0);

  (* fire_when_enabled *)
  rule drive_dna_control;
    dna.dIn(0);
    dna.read(rdReg);
    dna.shift(shftReg);
    dna.clk(cnt[0]);  // lsb of cnt is the DNA_PORT clk (1/2 cycle SU+H)
  endrule

  rule cnt_inc (cnt < maxBound);
    cnt <= cnt + 1;
  endrule

  rule assert_read (cnt==1 || cnt==2);  // Read on cnt 2-3 (1 rising clk edge)
    rdReg <= True;
  endrule

  rule assert_shift (cnt>=3 && cnt<=116);  // Shift DNA out on cnt 4-117  (56 rising clk edges)
    shftReg <= True;
    if (cnt[0]==1'b0) sr <= {sr[55:0], dna.dOut};
  endrule

  method Bit#(57) deviceID if (cnt==maxBound);
    return(sr);
  endmethod

  method Action rescanID;
    cnt <= 0;
  endmethod

endmodule

endpackage: DNA
