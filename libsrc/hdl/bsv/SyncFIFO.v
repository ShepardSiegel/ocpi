
// Copyright (c) 2000-2010 Bluespec, Inc.

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
// $Revision: 24080 $
// $Date: 2011-05-18 19:32:52 +0000 (Wed, 18 May 2011) $

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

// A clock synchronization FIFO where the enqueue and dequeue sides are in
// different clock domains.
// There are no restrictions w.r.t. clock frequencies
// The depth of the FIFO must be a power of 2 (2,4,8,...) since the
// indexing uses a Gray code counter.
// FULL and EMPTY signal are pessimistic, that is, they are asserted
// immediately when the FIFO becomes FULL or EMPTY, but their deassertion
// is delayed due to synchronization latency.
module SyncFIFO(
                sCLK,
                sRST_N,
                dCLK,
                sENQ,
                sD_IN,
                sFULL_N,
                dDEQ,
                dD_OUT,
                dEMPTY_N
                ) ;


   parameter                 dataWidth = 1 ;
   parameter                 depth = 2 ; // minimum 2
   parameter                 indxWidth = 1 ; // minimum 1

   // input clock domain ports
   input                     sCLK ;
   input                     sRST_N ;
   input                     sENQ ;
   input [dataWidth -1 : 0]  sD_IN ;
   output                    sFULL_N ;

   // destination clock domain ports
   input                     dCLK ;
   input                     dDEQ ;
   output                    dEMPTY_N ;
   output [dataWidth -1 : 0] dD_OUT ;

   // constants for bit masking of the gray code
   wire [indxWidth : 0]      msbset  = ~({(indxWidth + 1){1'b1}} >> 1) ;
   wire [indxWidth - 1 : 0]  msb2set = ~({(indxWidth + 0){1'b1}} >> 1) ;
   wire [indxWidth : 0]      msb12set = msbset | {1'b0, msb2set} ; // 'b11000...

   // FIFO Memory
   reg [dataWidth -1 : 0]    fifoMem [0: depth -1 ] ;
   reg [dataWidth -1 : 0]    dDoutReg ;

   // Enqueue Pointer support
   reg [indxWidth +1 : 0]    sGEnqPtr, sGEnqPtr1 ; // Flops
   reg                       sNotFullReg ;
   wire                      sNextNotFull, sFutureNotFull ;

   // Dequeue Pointer support
   reg [indxWidth+1 : 0]       dGDeqPtr, dGDeqPtr1 ; // Flops
   reg                       dNotEmptyReg ;
   wire                      dNextNotEmpty;

   // Reset generation
   wire                      dRST_N ;

   // flops to sychronize enqueue and dequeue point across domains
   reg [indxWidth : 0]       dSyncReg1, dEnqPtr ;
   reg [indxWidth : 0]       sSyncReg1, sDeqPtr ;

   wire [indxWidth - 1 :0]   sEnqPtrIndx, dDeqPtrIndx ;

   // Resets
   assign                    dRST_N = sRST_N ;

   // Outputs
   assign                    dD_OUT   = dDoutReg     ;
   assign                    dEMPTY_N = dNotEmptyReg ;
   assign                    sFULL_N  = sNotFullReg  ;

   // Indexes are truncated from the Gray counter with parity
   assign                    sEnqPtrIndx  = sGEnqPtr[indxWidth-1:0];
   assign                    dDeqPtrIndx  = dGDeqPtr[indxWidth-1:0];

   // Fifo memory write
   always @(posedge sCLK)
     begin
        if ( sENQ )
          fifoMem[sEnqPtrIndx] <= `BSV_ASSIGNMENT_DELAY sD_IN ;
     end // always @ (posedge sCLK)

   ////////////////////////////////////////////////////////////////////////
   // Enqueue Pointer and increment logic
   assign sNextNotFull   = (sGEnqPtr [indxWidth+1:1] ^ msb12set) != sDeqPtr ;
   assign sFutureNotFull = (sGEnqPtr1[indxWidth+1:1] ^ msb12set) != sDeqPtr ;

   always @(posedge sCLK or negedge sRST_N)
     begin
        if (sRST_N == 0)
          begin
             sGEnqPtr    <= `BSV_ASSIGNMENT_DELAY {(indxWidth +2 ) {1'b0}} ;
             sGEnqPtr1   <= `BSV_ASSIGNMENT_DELAY { {indxWidth {1'b0}}, 2'b11} ;
             sNotFullReg <= `BSV_ASSIGNMENT_DELAY 1'b0 ; // Mark as full during reset to avoid spurious loads
          end // if (sRST_N == 0)
        else
           begin
              if ( sENQ )
                begin
                   sGEnqPtr1   <= `BSV_ASSIGNMENT_DELAY incrGrayP( sGEnqPtr1 ) ;
                   sGEnqPtr    <= `BSV_ASSIGNMENT_DELAY sGEnqPtr1 ;
                   sNotFullReg <= `BSV_ASSIGNMENT_DELAY sFutureNotFull ;
                end // if ( sENQ )
              else
                begin
                   sNotFullReg <= `BSV_ASSIGNMENT_DELAY  sNextNotFull ;
                end // else: !if( sENQ )
           end // else: !if(sRST_N == 0)
     end // always @ (posedge sCLK or negedge sRST_N)


   // Enqueue pointer synchronizer to dCLK
   always @(posedge dCLK  or negedge dRST_N)
     begin
        if (dRST_N == 0)
          begin
             dSyncReg1 <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
             dEnqPtr   <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
          end // if (dRST_N == 0)
        else
          begin
             dSyncReg1 <= `BSV_ASSIGNMENT_DELAY sGEnqPtr[indxWidth+1:1] ; // Clock domain crossing
             dEnqPtr   <= `BSV_ASSIGNMENT_DELAY dSyncReg1 ;
          end // else: !if(dRST_N == 0)
     end // always @ (posedge dCLK  or negedge dRST_N)
   ////////////////////////////////////////////////////////////////////////


   ////////////////////////////////////////////////////////////////////////
   // Enqueue Pointer and increment logic
   assign dNextNotEmpty   = dGDeqPtr[indxWidth+1:1]  != dEnqPtr ;

   always @(posedge dCLK or negedge dRST_N)
     begin
        if (dRST_N == 0)
          begin
             dGDeqPtr     <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 2) {1'b0}} ;
             dGDeqPtr1    <= `BSV_ASSIGNMENT_DELAY {{indxWidth {1'b0}}, 2'b11 } ;
             dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b0 ;
          end // if (dRST_N == 0)
        else
           begin
              if ((!dNotEmptyReg || dDEQ) && dNextNotEmpty) begin
                 dGDeqPtr     <= `BSV_ASSIGNMENT_DELAY dGDeqPtr1 ;
                 dGDeqPtr1    <= `BSV_ASSIGNMENT_DELAY incrGrayP( dGDeqPtr1 );
                 dDoutReg     <= `BSV_ASSIGNMENT_DELAY fifoMem[dDeqPtrIndx] ;
                 dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b1;
              end
              else if (dDEQ && !dNextNotEmpty) begin
                 dNotEmptyReg <= `BSV_ASSIGNMENT_DELAY 1'b0;
              end
           end // else: !if(dRST_N == 0)
     end // always @ (posedge dCLK or negedge dRST_N)

    // Dequeue pointer synchronized to sCLK
    always @(posedge sCLK  or negedge sRST_N)
      begin
         if (sRST_N == 0)
           begin
              sSyncReg1 <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ;
              sDeqPtr   <= `BSV_ASSIGNMENT_DELAY {(indxWidth + 1) {1'b0}} ; // When reset mark as not empty
           end // if (sRST_N == 0)
         else
           begin
              sSyncReg1 <= `BSV_ASSIGNMENT_DELAY dGDeqPtr[indxWidth+1:1] ; // clock domain crossing
              sDeqPtr   <= `BSV_ASSIGNMENT_DELAY sSyncReg1 ;
           end // else: !if(sRST_N == 0)
      end // always @ (posedge sCLK  or negedge sRST_N)
   ////////////////////////////////////////////////////////////////////////

`ifdef BSV_NO_INITIAL_BLOCKS
`else // not BSV_NO_INITIAL_BLOCKS
   // synopsys translate_off
   initial
     begin : initBlock
        integer i ;

        // initialize the FIFO memory with aa's
        for (i = 0; i < depth; i = i + 1)
          begin
             fifoMem[i] = {((dataWidth + 1)/2){2'b10}} ;
          end
        dDoutReg     = {((dataWidth + 1)/2){2'b10}} ;

        // initialize the pointer
        sGEnqPtr = {((indxWidth + 2)/2){2'b10}} ;
        sGEnqPtr1 = sGEnqPtr ;
        sNotFullReg = 1'b0 ;

        dGDeqPtr = sGEnqPtr ;
        dGDeqPtr1 = sGEnqPtr ;
        dNotEmptyReg = 1'b0;


        // initialize other registers
        sSyncReg1 = sGEnqPtr ;
        sDeqPtr   = sGEnqPtr ;
        dSyncReg1 = sGEnqPtr ;
        dEnqPtr   = sGEnqPtr ;
     end // block: initBlock
   // synopsys translate_on



   // synopsys translate_off
   initial
     begin : parameter_assertions
        integer ok ;
        integer i, expDepth ;

        ok = 1;
        expDepth = 1 ;

        // calculate x = 2 ** (indxWidth - 1)
        for( i = 0 ; i < indxWidth ; i = i + 1 )
          begin
             expDepth = expDepth * 2 ;
          end // for ( i = 0 ; i < indxWidth ; i = i + 1 )

        if ( expDepth != depth )
          begin
             ok = 0;
             $display ( "ERROR SyncFiFO.v: index size and depth do not match;" ) ;
             $display ( "\tdepth must equal 2 ** index size. expected %0d", expDepth );
          end

        #0
        if ( ok == 0 ) $finish ;

      end // initial begin
   // synopsys translate_on
`endif // BSV_NO_INITIAL_BLOCKS

   function [indxWidth+1:0] incrGrayP ;
      input [indxWidth+1:0] grayPin;

      begin: incrGrayPBlock
         reg [indxWidth :0] g;
         reg                p ;
         reg [indxWidth :0] i;

         g = grayPin[indxWidth+1:1];
         p = grayPin[0];
         i = incrGray (g,p);
         incrGrayP = {i,~p};
      end
   endfunction
   function [indxWidth:0] incrGray ;
      input [indxWidth:0] grayin;
      input parity ;

      begin: incrGrayBlock
         integer               i;
         reg [indxWidth: 0]    tempshift;
         reg [indxWidth: 0]    flips;

         flips[0] = ! parity ;
         for ( i = 1 ; i < indxWidth ; i = i+1 )
           begin
              tempshift = grayin << (2 + indxWidth - i ) ;
              flips[i]  = parity & grayin[i-1] & ~(| tempshift ) ;
           end
         tempshift = grayin << 2 ;
         flips[indxWidth] = parity & ~(| tempshift ) ;

         incrGray = flips ^ grayin ;
      end
   endfunction

endmodule // FIFOSync


`ifdef testBluespec
module testSyncFIFO() ;
   parameter dsize = 8;
   parameter fifodepth = 32;
   parameter fifoidx = 5;

   wire      sCLK,  dCLK, dRST_N ;
   wire      sENQ, dDEQ;
   wire      sFULL_N, dEMPTY_N ;
   wire [dsize -1:0] sDIN, dDOUT ;

   reg [dsize -1:0]  sCNT, dCNT ;
   reg sRST_N, sCLR ;

   ClockGen#(15,14,10)  sc( sCLK );
   ClockGen#(11,12,2600)  dc( dCLK );

   initial
     begin
        sCNT = 0;
        dCNT = 0;
        sCLR = 1'b0 ;

        sRST_N = 0 ;
        $display( "running test" ) ;

        $dumpfile("SyncFIFO.vcd");
        $dumpvars(5,testSyncFIFO) ;
        $dumpon ;
        #200 ;
        sRST_N = 1 ;


        #100000 $finish ;
     end // initial begin
   initial
     begin
        #50000 ;
        @(posedge sCLK ) ;
        sCLR <= `BSV_ASSIGNMENT_DELAY 1'b1 ;
        @(posedge sCLK ) ;
        sCLR <= `BSV_ASSIGNMENT_DELAY 1'b0 ;

      end

   SyncFIFO #(dsize,fifodepth,fifoidx)
     dut( sCLK, sRST_N, dCLK, sENQ, sDIN,
          sFULL_N, // sCLR,
          dDEQ, dDOUT, dEMPTY_N );

   assign sDIN = sCNT ;
   assign sENQ = sFULL_N ;


   always @(posedge sCLK)
     begin
        if (sENQ )
          begin
             sCNT <= `BSV_ASSIGNMENT_DELAY sCNT + 1;
          end
      end // always @ (posedge sCLK)

   assign dDEQ = dEMPTY_N ;

   always @(posedge dCLK)
     begin
        if (dDEQ )
           begin
              $display( "dequeing %d", dDOUT ) ;
           end
     end // always @ (posedge dCLK)

endmodule // testSyncFIFO
`endif
