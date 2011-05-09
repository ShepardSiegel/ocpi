
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_cdma_ast_msi.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module construct of the Avalon Streaming receive port for the
// chaining DMA application MSI signals.
//-----------------------------------------------------------------------------
// Copyright (c) 2009 Altera Corporation. All rights reserved.  Altera products are
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
module altpcierd_cdma_ast_msi (
                           input clk_in,
                           input rstn,
                           input app_msi_req,
                           output reg app_msi_ack,
                           input[2:0]   app_msi_tc,
                           input[4:0]   app_msi_num,
                                 input        stream_ready,
                           output reg [7:0] stream_data,
                           output reg stream_valid);

   reg   stream_ready_del;
   reg   app_msi_req_r;
   wire [7:0] m_data;

   assign m_data[7:5] = app_msi_tc[2:0];
   assign m_data[4:0] = app_msi_num[4:0];
   //------------------------------------------------------------
   //    Input register boundary
   //------------------------------------------------------------

   always @(negedge rstn or posedge clk_in) begin
      if (rstn == 1'b0)
          stream_ready_del <= 1'b0;
      else
          stream_ready_del <= stream_ready;
   end
   //------------------------------------------------------------
   //    Arbitration between master and target for transmission
   //------------------------------------------------------------

   // tx_state SM states


   always @(negedge rstn or posedge clk_in) begin
      if (rstn == 1'b0) begin
          app_msi_ack        <= 1'b0;
         stream_valid <= 1'b0;
           stream_data  <= 8'h0;
           app_msi_req_r      <= 1'b0;
      end
      else begin
         app_msi_ack       <= stream_ready_del & app_msi_req;
           stream_valid      <= stream_ready_del & app_msi_req & ~app_msi_req_r;
           stream_data       <= m_data;
           app_msi_req_r     <= stream_ready_del ? app_msi_req : app_msi_req_r;
      end
   end
endmodule
