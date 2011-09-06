// (C) 2001-2011 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/11.0sp1/ip/merlin/altera_merlin_slave_agent/altera_merlin_burst_uncompressor.sv#1 $
// $Revision: #1 $
// $Date: 2011/04/07 $
// $Author: max $

`timescale 1ns / 1ns

// ------------------------------------------
// Merlin Burst Uncompressor
//
// Compressed read bursts -> uncompressed
// ------------------------------------------

`timescale 1ns / 1ns

module altera_merlin_burst_uncompressor
#(
    parameter ADDR_W      = 16,
    parameter BURSTWRAP_W = 3,
    parameter BYTE_CNT_W  = 4,
    parameter PKT_SYMBOLS = 4
)
(
    input clk,
    input reset,
   
    // sink ST signals
    input sink_startofpacket,
    input sink_endofpacket,
    input sink_valid,
    output sink_ready,
   
    // sink ST "data"
    input [ADDR_W - 1: 0] sink_addr,
    input [BURSTWRAP_W - 1 : 0] sink_burstwrap,
    input [BYTE_CNT_W - 1 : 0] sink_byte_cnt,
    input sink_is_compressed,
   
    // source ST signals
    output source_startofpacket,
    output source_endofpacket,
    output source_valid,
    input source_ready,
   
    // source ST "data"
    output [ADDR_W - 1: 0] source_addr,
    output [BURSTWRAP_W - 1 : 0] source_burstwrap,
    output [BYTE_CNT_W - 1 : 0] source_byte_cnt,
   
    // Note: in the slave agent, the output should always be uncompressed.  In
    // other applications, it may be required to leave-compressed or not. How to
    // control?  Seems like a simple mux - pass-through if no uncompression is
    // required.
    output source_is_compressed
);
   // num_symbols is PKT_SYMBOLS, appropriately sized.
   wire [31:0] int_num_symbols = PKT_SYMBOLS;
   wire [BYTE_CNT_W-1:0] num_symbols = int_num_symbols[BYTE_CNT_W-1:0];
  
   // def: Burst Compression.  In a merlin network, a compressed burst is one 
   // which is transmitted in a single beat.  Example: read burst.  In 
   // constrast, an uncompressed burst (example: write burst) is transmitted in
   // one beat per writedata item.
   //
   // For compressed bursts which require response packets, burst
   // uncompression is required.  Concrete example: a read burst of size 8
   // occupies one response-fifo position.  When that fifo position reaches the
   // front of the FIFO, the slave starts providing the required 8 readdatavalid
   // pulses.  The 8 return response beats must be provided in a single packet,
   // with incrementing address and decrementing byte_cnt fields.  Upon receipt
   // of the final readdata item of the burst, the response FIFO item is
   // retired.
   // Burst uncompression logic provides:
   //   a) 2-state FSM (idle, busy)
   //     reset to idle state
   //     transition to busy state for 2nd and subsequent rdv pulses
   //     - a single-cycle burst (aka non-burst read) causes no transition to
   //     busy state.
   //   b) response startofpacket/endofpacket logic.  The response FIFO item 
   //   will have sop asserted, and may have eop asserted. (In the case of
   //   multiple read bursts transmit in the command fabric in a single packet,
   //   the eop assertion will come in a later FIFO item.)  To support packet
   //   conservation, and emit a well-formed packet on the response fabric,
   //     i) response fabric startofpacket is asserted only for the first resp.
   //     beat;
   //     ii) response fabric endofpacket is asserted only for the last resp.
   //     beat.
   //   c) response address field.  The response address field contains an
   //   incrementing sequence, such that each readdata item is associated with
   //   its slave-map location.  N.b. a) computing the address correctly requires
   //   knowledge of burstwrap behavior b) there may be no clients of the address
   //   field, which makes this field a good target for optimization.  See
   //   burst_uncompress_address_counter below.
   //   d) response byte_cnt field.  The response byte_cnt field contains a
   //   decrementing sequence, such that each beat of the response contains the
   //   count of bytes to follow.  In the case of sub-bursts in a single packet,
   //   the byte_cnt field may decrement down to num_symbols, then back up to
   //   some value, multiple times in the packet.
  
   reg burst_uncompress_busy;
   reg [BYTE_CNT_W-1:0] burst_uncompress_byte_counter;
   wire first_packet_beat;
   wire last_packet_beat;

   assign first_packet_beat = sink_valid & ~burst_uncompress_busy;

   // First cycle: burst_uncompress_byte_counter isn't ready yet, mux the input to
   // the output.
   assign source_byte_cnt =
     first_packet_beat ? sink_byte_cnt : burst_uncompress_byte_counter;
   assign source_valid = sink_valid;
  
   // Last packet beat is set throughout receipt of an uncompressed read burst
   // from the response FIFO - this forces all the burst uncompression machinery
   // idle.
   assign last_packet_beat = ~sink_is_compressed |
     (
     burst_uncompress_busy ?
       (sink_valid & (burst_uncompress_byte_counter == num_symbols)) :
         sink_valid & (sink_byte_cnt == num_symbols)
     );
  
   always @(posedge clk or posedge reset) begin
     if (reset) begin
       burst_uncompress_busy <= '0;
       burst_uncompress_byte_counter <= '0;
     end
     else begin
       if (source_valid & source_ready & sink_valid) begin
         // No matter what the current state, last_packet_beat leads to
         // idle.
         if (last_packet_beat) begin
           burst_uncompress_busy <= '0;
           burst_uncompress_byte_counter <= '0;
         end
         else begin
           if (burst_uncompress_busy) begin
             burst_uncompress_byte_counter <= burst_uncompress_byte_counter ? 
               (burst_uncompress_byte_counter - num_symbols) :
               (sink_byte_cnt - num_symbols);
           end
           else begin // not busy, at least one more beat to go
             burst_uncompress_byte_counter <= sink_byte_cnt - num_symbols;
             // To do: should busy go true for numsymbols-size compressed
             // bursts?
             burst_uncompress_busy <= '1;
           end
         end
       end
     end
   end
  
   wire [ADDR_W - 1 : 0 ] addr_width_burstwrap;
   reg [ADDR_W - 1 : 0 ] burst_uncompress_address_base;
   reg [ADDR_W - 1 : 0] burst_uncompress_address_offset;

   // The input burstwrap value can be used as a mask against address values,
   // but with one caveat: the address width may be (probably is) wider than 
   // the burstwrap width.  The spec says: extend the msb of the burstwrap 
   // value out over the entire address width (but only if the address width
   // actually is wider than the burstwrap width; otherwise it's a 0-width or
   // negative range and concatenation multiplier). 
   assign addr_width_burstwrap[BURSTWRAP_W - 1 : 0] = sink_burstwrap;
   generate
      if (ADDR_W > BURSTWRAP_W) begin : addr_sign_extend
         // Sign-extend, just wires:
         assign addr_width_burstwrap[ADDR_W - 1 : BURSTWRAP_W] =
            {(ADDR_W - BURSTWRAP_W) {sink_burstwrap[BURSTWRAP_W - 1]}};
      end
   endgenerate

   always @(posedge clk or posedge reset) begin
     if (reset) begin
       burst_uncompress_address_base <= '0;
     end
     else if (first_packet_beat & source_ready) begin
       burst_uncompress_address_base <= sink_addr & ~addr_width_burstwrap;
     end
   end

   wire [ADDR_W - 1 : 0] p1_burst_uncompress_address_offset =
   (
     (first_packet_beat ?
       sink_addr :
       burst_uncompress_address_offset) + num_symbols
    ) &
    addr_width_burstwrap;

   always @(posedge clk or posedge reset) begin
     if (reset) begin
       burst_uncompress_address_offset <= '0;
     end
     else begin
       if (source_ready & source_valid) begin
         burst_uncompress_address_offset <= p1_burst_uncompress_address_offset;
         // if (first_packet_beat) begin
         //   burst_uncompress_address_offset <=
         //     (sink_addr + num_symbols) & addr_width_burstwrap;
         // end
         // else begin
         //   burst_uncompress_address_offset <=
         //     (burst_uncompress_address_offset + num_symbols) & addr_width_burstwrap;
         // end
       end
     end
   end
  
   // On the first packet beat, send the input address out unchanged, 
   // while values are computed/registered for 2nd and subsequent beats.
   assign source_addr = first_packet_beat ? sink_addr :
       burst_uncompress_address_base | burst_uncompress_address_offset;
   assign source_burstwrap = sink_burstwrap;
  
   //-------------------------------------------------------------------
   // A single (compressed) read burst will have sop/eop in the same beat.
   // A sequence of read sub-bursts emitted by a burst adapter in response to a
   // single read burst will have sop on the first sub-burst, eop on the last.
   // Assert eop only upon (sink_endofpacket & last_packet_beat) to preserve 
   // packet conservation.
   assign source_startofpacket = sink_startofpacket & ~burst_uncompress_busy;
   assign source_endofpacket   = sink_endofpacket & last_packet_beat;
   assign sink_ready = source_valid & source_ready & last_packet_beat;
  
   // This is correct for the slave agent usage, but won't always be true in the
   // width adapter.  To do: add an "please uncompress" input, and use it to
   // pass-through or modify, and set source_is_compressed accordingly.
   assign source_is_compressed = 1'b0;
endmodule

