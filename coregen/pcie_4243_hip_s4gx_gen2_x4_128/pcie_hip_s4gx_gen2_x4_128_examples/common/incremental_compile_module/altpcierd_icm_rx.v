// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_rx.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This is the complete example application for the PCI Express Reference
// Design. This has all of the application logic for the example.
//-----------------------------------------------------------------------------
// Copyright (c) 2006 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation
// and therefore all warranties, representations or guarantees of any kind
// (whether express, implied or statutory) including, without limitation, warranties of
// merchantability, non-infringement, or fitness for a particular purpose, are
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------


module altpcierd_icm_rx (clk, rstn,
                        rx_req, rx_ack, rx_desc, rx_data, rx_be,
                    rx_ws, rx_dv, rx_dfr, rx_abort, rx_retry, rx_mask,
                    rx_stream_ready, rx_stream_valid, rx_stream_data, rx_stream_mask
                          );

   input         clk;
   input         rstn;
   input         rx_req;             // from core.  pkt request
   input[135:0]  rx_desc;            // from core.  pkt descriptor
   input[63:0]   rx_data;            // from core.  pkt payload
   input[7:0]    rx_be;              // from core.  byte enable bits
   input         rx_dv;              // from core.  rx_data is valid
   input         rx_dfr;             // from core.  pkt has more data cycles

   output        rx_ack;             // to core.  rx request handshake
   output        rx_abort;           // to core.  Abort handshake
   output        rx_retry;           // to core.  Retry NP pkt handshake
   output        rx_ws;              // to core.  NP pkt mask control
   output        rx_mask;            // to core.  NP pkt mask control

   input         rx_stream_ready;       // indicates streaming interface can accept more data

   output        rx_stream_valid;       // writes rx_stream_data to streaming interface
   output[107:0] rx_stream_data;    // streaming interface data
   input         rx_stream_mask;

   wire          rx_ack;
   wire          rx_abort;
   wire          rx_retry;
   wire          rx_ws;
   reg           rx_mask;


   // Fifo
   wire          fifo_empty;
   wire          fifo_almostfull;
   wire          fifo_wr;
   wire          fifo_rd;
   wire[107:0]   fifo_wrdata;
   wire[107:0]   fifo_rddata;

   reg           stream_ready_del;
   reg           rx_stream_valid;
   reg[107:0]    rx_stream_data;

   reg           not_fifo_almost_full_del;  // for performance
   reg           fifo_rd_del;               // fifo output is valid one cycle after fifo_rd


   //------------------------------------------------
   // Core Interface
   //------------------------------------------------

   // Bridge from Core RX port to Streaming I/F
   altpcierd_icm_rxbridge rx_altpcierd_icm_rxbridge (
            .clk(clk), .rstn(rstn),
            .rx_req(rx_req), .rx_desc(rx_desc), .rx_dv(rx_dv), .rx_dfr(rx_dfr),
         .rx_data(rx_data), .rx_be(rx_be), .rx_ws(rx_ws), .rx_ack(rx_ack),
         .rx_abort(rx_abort), .rx_retry(rx_retry), .rx_mask(),
         .stream_ready(not_fifo_almost_full_del),
         .stream_wr(fifo_wr), .stream_wrdata(fifo_wrdata)
   );


   // Throttle data from bridge
   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
         not_fifo_almost_full_del <= 1'b1;
      end
      else begin
          not_fifo_almost_full_del <= ~fifo_almostfull;
      end
   end

   //-----------------------------------
   // isolation fifo
   //-----------------------------------
   altpcierd_icm_fifo    #(
       .RAMTYPE  ("RAM_BLOCK_TYPE=AUTO")
      )fifo_131x4 (
                           .clock        (clk),
                           .aclr         (~rstn),
                           .data         (fifo_wrdata),
                     .wrreq        (fifo_wr),
                     .rdreq        (fifo_rd & ~fifo_empty),
                     .q            (fifo_rddata),
                     .full         ( ),
                     .almost_full  (fifo_almostfull),
                     .almost_empty ( ),
                     .empty        (fifo_empty));


   //------------------------------------------
   // Streaming interface.  Input pipe stage.
   //------------------------------------------

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
         stream_ready_del <= 1'b0;
         rx_mask          <= 1'b0;
      end
      else begin
          stream_ready_del <= rx_stream_ready;
         rx_mask          <= rx_stream_mask;
      end
   end


   //------------------------------------------
   // Streaming interface.  Output pipe stage.
   //------------------------------------------

   assign fifo_rd = stream_ready_del & ~fifo_empty;     // pop fifo when streaming interface can accept more data

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
          rx_stream_data  <= 107'h0;
         fifo_rd_del     <= 1'b0;
         rx_stream_valid <= 1'b0;
      end
      else begin
          rx_stream_data  <= fifo_rddata;
         fifo_rd_del     <= fifo_rd & ~fifo_empty;
         rx_stream_valid <= fifo_rd_del;              // push fifo data onto streaming interface

      end
   end




endmodule
