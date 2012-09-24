
// Copyright (c) 2000-2012 Bluespec, Inc.

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
// $Revision: 29441 $
// $Date: 2012-08-27 21:58:03 +0000 (Mon, 27 Aug 2012) $

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif



// Depth 2 FIFO
module FIFO2(CLK,
             RST,
             D_IN,
             ENQ,
             FULL_N,
             D_OUT,
             DEQ,
             EMPTY_N,
             CLR);

   parameter width = 1;
   parameter guarded = 1;

   input     CLK ;
   input     RST ;
   input [width - 1 : 0] D_IN;
   input                 ENQ;
   input                 DEQ;
   input                 CLR ;

   output                FULL_N;
   output                EMPTY_N;
   output [width - 1 : 0] D_OUT;

   reg                    full_reg;
   reg                    empty_reg;
   reg [width - 1 : 0]    data0_reg;
   reg [width - 1 : 0]    data1_reg;

   assign                 FULL_N = full_reg ;
   assign                 EMPTY_N = empty_reg ;
   assign                 D_OUT = data0_reg ;


   // Optimize the loading logic since state encoding is not power of 2!
   wire                   d0di = (ENQ && ! empty_reg ) || ( ENQ && DEQ && full_reg ) ;
   wire                   d0d1 = DEQ && ! full_reg ;
   wire                   d0h = ((! DEQ) && (! ENQ )) || (!DEQ && empty_reg ) || ( ! ENQ &&full_reg) ;
   wire                   d1di = ENQ & empty_reg ;

`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin
        data0_reg   = {((width + 1)/2) {2'b10}} ;
        data1_reg  = {((width + 1)/2) {2'b10}} ;
        empty_reg = 1'b0;
        full_reg  = 1'b1;
     end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS

   always@(posedge CLK /* or `BSV_RESET_EDGE RST */)
     begin
        if (RST == `BSV_RESET_VALUE)
          begin
             empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b0;
             full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
          end // if (RST == `BSV_RESET_VALUE)
        else
          begin
             if (CLR)
               begin
                  empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b0;
                  full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
               end // if (CLR)
             else if ( ENQ && ! DEQ ) // just enq
               begin
                  empty_reg <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  full_reg <= `BSV_ASSIGNMENT_DELAY ! empty_reg ;
               end
             else if ( DEQ && ! ENQ )
               begin
                  full_reg  <= `BSV_ASSIGNMENT_DELAY 1'b1;
                  empty_reg <= `BSV_ASSIGNMENT_DELAY ! full_reg;
               end // if ( DEQ && ! ENQ )
          end // else: !if(RST == `BSV_RESET_VALUE)

     end // always@ (posedge CLK or `BSV_RESET_EDGE RST)


   always@(posedge CLK /* or `BSV_RESET_EDGE RST */ )
     begin
        // Following section initializes the data registers which
        // may be desired only in some situations.
        // Uncomment to initialize array
        /*
        if (RST == `BSV_RESET_VALUE)
          begin
             data0_reg <= `BSV_ASSIGNMENT_DELAY {width {1'b0}} ;
             data1_reg <= `BSV_ASSIGNMENT_DELAY {width {1'b0}} ;
          end
        else
         */
          begin
             data0_reg  <= `BSV_ASSIGNMENT_DELAY
                           {width{d0di}} & D_IN | {width{d0d1}} & data1_reg | {width{d0h}} & data0_reg ;
             data1_reg <= `BSV_ASSIGNMENT_DELAY
                          d1di ? D_IN : data1_reg ;
          end // else: !if(RST == `BSV_RESET_VALUE)
     end // always@ (posedge CLK or `BSV_RESET_EDGE RST)



   // synopsys translate_off
   always@(posedge CLK)
     begin: error_checks
        reg deqerror, enqerror ;

        deqerror =  0;
        enqerror = 0;
        if (RST == ! `BSV_RESET_VALUE)
          begin
             if ( ! empty_reg && DEQ )
               begin
                  deqerror =  1;
                  $display( "Warning: FIFO2: %m -- Dequeuing from empty fifo" ) ;
               end
             if ( ! full_reg && ENQ && (!DEQ || guarded) )
               begin
                  enqerror = 1;
                  $display( "Warning: FIFO2: %m -- Enqueuing to a full fifo" ) ;
               end
          end
     end // always@ (posedge CLK)
   // synopsys translate_on

endmodule
