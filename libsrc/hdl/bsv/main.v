
// Copyright (c) 2000-2009 Bluespec, Inc.

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// $Revision: 17872 $
// $Date: 2009-09-18 14:32:56 +0000 (Fri, 18 Sep 2009) $

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_TIMESCALE
 `timescale `BSV_TIMESCALE
`endif

module main();

   reg CLK;
   // reg CLK_GATE;
   reg RST_N;
   reg [31:0] cycle;
   reg        do_dump;
   reg        do_cycles;
      
   `TOP top(.CLK(CLK), /* .CLK_GATE(CLK_GATE), */ .RST_N(RST_N));

// For Sce-Mi linkage, insert code here
`ifdef BSV_SCEMI_LINK
`include `BSV_SCEMI_LINK
`endif

`ifdef BSV_DUMP_LEVEL
`else
 `define BSV_DUMP_LEVEL 0
`endif

`ifdef BSV_DUMP_TOP
`else
 `define BSV_DUMP_TOP main
`endif
   
   initial begin
      // CLK_GATE = 1'b1;
      // CLK = 1'b0;    // This line will cause a neg edge of clk at t=0!
      // RST_N = 1'b0;  // This needs #0, to allow always blocks to wait
      cycle = 0;

      do_dump = $test$plusargs("bscvcd") ;
      do_cycles = $test$plusargs("bsccycle") ;

     
      if (do_dump)
        begin
`ifdef BSC_FSDB
           $fsdbDumpfile("dump.fsdb");
           $fsdbDumpvars(`BSV_DUMP_LEVEL, `BSV_DUMP_TOP);
`else
           $dumpfile("dump.vcd");
           // $dumpon; unneeded
           $dumpvars(`BSV_DUMP_LEVEL, `BSV_DUMP_TOP);
`endif
        end
      #0
      RST_N = 1'b0;
      #1;
      CLK = 1'b1;
      // $display("reset");
      #1;
      RST_N = 1'b1;
      // $display("reset done");
      //  #200010;
      //  $finish;
   end

   always
     begin
        #1
        if (do_cycles)
          $display("cycle %0d", cycle) ;
        cycle = cycle + 1 ;
        #4;
        CLK = 1'b0 ;
        #5;
        CLK = 1'b1 ;
   end

endmodule
