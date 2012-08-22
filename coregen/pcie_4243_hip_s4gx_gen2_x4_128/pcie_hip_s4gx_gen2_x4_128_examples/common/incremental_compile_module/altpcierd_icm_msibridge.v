// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : avalon_legacy_bridge.v
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

`include "altpcierd_icm_defines.v"

module altpcierd_icm_msibridge (clk, rstn,
                                 data_valid, data_in, data_ack,
                          msi_ack, msi_req, msi_num, msi_tc);


   input         clk;
   input         rstn;

   input         data_valid;
   input[107:0]  data_in;
   input         msi_ack;


   output        data_ack;
   output        msi_req;
   output[4:0]   msi_num;
   output[2:0]   msi_tc;

   reg           msi_req;
   reg  [4:0]    msi_num;
   reg  [2:0]    msi_tc;
   reg           msi_req_r;

   wire          throttle_data;

   //--------------------------------
   // legacy output signals
   //--------------------------------



   //--------------------------------
   // avalon ready
   //--------------------------------

   assign data_ack  = ~(~msi_ack & (msi_req | (data_valid & data_in[`STREAM_MSI_VALID])));

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
          msi_num <= 5'h0;
         msi_tc  <= 3'h0;
         msi_req <= 1'b0;
      end
      else begin
          msi_num <= (data_in[`STREAM_MSI_VALID]) ? data_in[`STREAM_APP_MSI_NUM] : msi_num;
         msi_tc  <= (data_in[`STREAM_MSI_VALID]) ? data_in[`STREAM_MSI_TC] : msi_tc;
         msi_req <= msi_ack ? 1'b0 : (data_valid & data_in[`STREAM_MSI_VALID]) ? 1'b1 : msi_req;
      end
   end

/*
   wire          msi_req;
   wire [4:0]    msi_num;
   wire [2:0]    msi_tc;
   reg           msi_req_r;

   wire          throttle_data;
   reg [4:0]     msi_num_r;
   reg [2:0]     msi_tc_r;
   reg           msi_ack_r;

   //--------------------------------
   // legacy output signals
   //--------------------------------

   assign msi_req  = msi_ack_r ? 1'b0 : (data_valid & data_in[`STREAM_MSI_VALID]) ? 1'b1 : msi_req_r;

   assign msi_tc  = (data_in[`STREAM_MSI_VALID]) ? data_in[`STREAM_MSI_TC] : msi_tc_r;
   assign msi_num = (data_in[`STREAM_MSI_VALID]) ? data_in[`STREAM_APP_MSI_NUM] : msi_num_r;

   //--------------------------------
   // avalon ready
   //--------------------------------

   assign data_ack  = ~msi_req;

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
          msi_num_r <= 5'h0;
         msi_tc_r  <= 3'h0;
         msi_req_r <= 1'b0;
         msi_ack_r <= 1'b0;
      end
      else begin
          msi_num_r <= msi_num;
         msi_tc_r  <= msi_tc;
         msi_req_r <= msi_req;
         msi_ack_r <= msi_ack;
      end
   end
*/
endmodule
