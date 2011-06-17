// SRLFIFO.bsv
// Copyright (c) 2009, 2011 Atomic Rules LLC, ALL RIGHTS RESERVED
//
// 2009-05-10 ssiegel Creation in VHDL
// 2009-11-01 ssiegel ImportBVI Wrapper Created
// 2011-06-16 ssiegel Added SRLFIFOD, made depth a localparam in the Verilog

package SRLFIFO;

import FIFOF :: * ;

import "BVI" arSRLFIFO =
module mkSRLFIFO#(Integer ldepth) (FIFOF#(a))
        provisos(Bits#(a,size_a));

        parameter width = valueOf(size_a);
        parameter l2depth = ldepth;
        
        default_clock clk;
        default_reset rst_RST_N;

        input_clock clk (CLK)  <- exposeCurrentClock;
        input_reset rst_RST_N (RST_N) clocked_by(clk)  <- exposeCurrentReset;

        method enq (D_IN) enable(ENQ) ready(FULL_N);
        method deq () enable(DEQ) ready(EMPTY_N);
        method D_OUT first () ready(EMPTY_N);
        method FULL_N  notFull ();
        method EMPTY_N notEmpty ();
        method clear () enable (CLR);
        
        schedule deq CF enq;
        schedule enq CF (deq, first);
        schedule (first, notEmpty, notFull) CF (first,notEmpty,notFull);
        schedule (clear, deq, enq) SBR clear;
        schedule first SB (clear,deq);
        schedule (notEmpty, notFull) SB (clear, deq, enq);
        schedule deq C deq;   
        schedule enq C enq;   
endmodule
           
/*
(*synthesize*)
module arSRLFIFO_test1();
   FIFOF#(Bit#(8)) i <- mkSRLFIFO(5);
endmodule
*/

           
import "BVI" arSRLFIFOD =
module mkSRLFIFOD#(Integer ldepth) (FIFOF#(a))
        provisos(Bits#(a,size_a));

        parameter width = valueOf(size_a);
        parameter l2depth = ldepth;
        
        default_clock clk;
        default_reset rst_RST_N;

        input_clock clk (CLK)  <- exposeCurrentClock;
        input_reset rst_RST_N (RST_N) clocked_by(clk)  <- exposeCurrentReset;

        method enq (D_IN) enable(ENQ) ready(FULL_N);
        method deq () enable(DEQ) ready(EMPTY_N);
        method D_OUT first () ready(EMPTY_N);
        method FULL_N  notFull ();
        method EMPTY_N notEmpty ();
        method clear () enable (CLR);
        
        schedule deq CF enq;
        schedule enq CF (deq, first);
        schedule (first, notEmpty, notFull) CF (first,notEmpty,notFull);
        schedule (clear, deq, enq) SBR clear;
        schedule first SB (clear,deq);
        schedule (notEmpty, notFull) SB (clear, deq, enq);
        schedule deq C deq;   
        schedule enq C enq;   
endmodule
           
/*
(*synthesize*)
module arSRLFIFOD_test1();
   FIFOF#(Bit#(8)) i <- mkSRLFIFOD(5);
endmodule
*/

endpackage
