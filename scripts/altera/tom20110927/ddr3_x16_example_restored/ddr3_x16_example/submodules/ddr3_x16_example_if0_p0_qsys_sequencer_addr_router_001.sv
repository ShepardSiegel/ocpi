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


// $Id: //acds/rel/11.0sp1/ip/merlin/altera_merlin_router/altera_merlin_router.sv.terp#3 $
// $Revision: #3 $
// $Date: 2011/05/16 $
// $Author: jyeap $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// either (a) the address or (b) the dest id. The DECODER_TYPE
// parameter controls this behaviour. 0 means address decoder,
// 1 means dest id decoder.
//
// In the case of (a), it also sets the destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

module ddr3_x16_example_if0_p0_qsys_sequencer_addr_router_001_default_decode
  #(
     parameter DEFAULT_CHANNEL = 3,
               DEFAULT_DESTID = 4 
   )
  (output [74 - 71 : 0] default_destid,
   output [8-1 : 0] default_src_channel
  );

  assign default_destid = DEFAULT_DESTID[74 - 71 : 0];
  generate begin : default_decode
    if (DEFAULT_CHANNEL == -1)
      assign default_src_channel = '0;
    else
      assign default_src_channel = 8'b1 << DEFAULT_CHANNEL;
  end endgenerate

endmodule


module ddr3_x16_example_if0_p0_qsys_sequencer_addr_router_001
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [76-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [76-1    : 0] src_data,
    output reg [8-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 54;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 74;
    localparam PKT_DEST_ID_L = 71;
    localparam ST_DATA_W = 76;
    localparam ST_CHANNEL_W = 8;
    localparam DECODER_TYPE = 0;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;

    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    localparam PAD0 = log2ceil(32'h14000 - 32'h10000);
    localparam PAD1 = log2ceil(32'h800 - 32'h0);
    localparam PAD2 = log2ceil(32'h20800 - 32'h20000);
    localparam PAD3 = log2ceil(32'h58000 - 32'h50000);
    localparam PAD4 = log2ceil(32'h50000 - 32'h48000);
    localparam PAD5 = log2ceil(32'h68000 - 32'h60000);
    localparam PAD6 = log2ceil(32'h48000 - 32'h40000);
    localparam PAD7 = log2ceil(32'h60000 - 32'h58000);

    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 32'h68000;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;
    localparam RG = RANGE_ADDR_WIDTH-1;

    reg [PKT_ADDR_W-1 : 0] address;

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;

    wire [PKT_DEST_ID_W-1:0] default_destid;
    wire [8-1 : 0] default_src_channel;

    ddr3_x16_example_if0_p0_qsys_sequencer_addr_router_001_default_decode the_default_decode(
      .default_destid (default_destid),
      .default_src_channel (default_src_channel)
    );

    always @* begin
        src_data    = sink_data;
        src_channel = default_src_channel;

        src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = default_destid;
        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------
        address     = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];

        // ( 0x10000 .. 0x14000 )
        if ( {address[RG:PAD0],{PAD0{1'b0}}} == 'h10000 ) begin
            src_channel = 8'b00000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
        end

        // ( 0x0 .. 0x800 )
        if ( {address[RG:PAD1],{PAD1{1'b0}}} == 'h0 ) begin
            src_channel = 8'b00000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
        end

        // ( 0x20000 .. 0x20800 )
        if ( {address[RG:PAD2],{PAD2{1'b0}}} == 'h20000 ) begin
            src_channel = 8'b00000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
        end

        // ( 0x50000 .. 0x58000 )
        if ( {address[RG:PAD3],{PAD3{1'b0}}} == 'h50000 ) begin
            src_channel = 8'b00001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
        end

        // ( 0x48000 .. 0x50000 )
        if ( {address[RG:PAD4],{PAD4{1'b0}}} == 'h48000 ) begin
            src_channel = 8'b00010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
        end

        // ( 0x60000 .. 0x68000 )
        if ( {address[RG:PAD5],{PAD5{1'b0}}} == 'h60000 ) begin
            src_channel = 8'b00100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
        end

        // ( 0x40000 .. 0x48000 )
        if ( {address[RG:PAD6],{PAD6{1'b0}}} == 'h40000 ) begin
            src_channel = 8'b01000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
        end

        // ( 0x58000 .. 0x60000 )
        if ( {address[RG:PAD7],{PAD7{1'b0}}} == 'h58000 ) begin
            src_channel = 8'b10000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
        end

    end

    // --------------------------------------------------
    // Ceil(log2()) function
    // --------------------------------------------------
    function integer log2ceil;
        input reg[63:0] val;
        reg [63:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule


