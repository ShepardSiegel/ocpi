`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express PIPE PHY connector
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_pipe_phy.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This function interconnects two PIPE MAC interfaces for a single lane.
// For now this uses a common PCLK for both interfaces, an enhancement woudl be
// to support separate PCLK's for each interface with the requisite elastic
// buffer. 
//-----------------------------------------------------------------------------
// Copyright (c) 2005 Altera Corporation. All rights reserved.  Altera products are
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
module altpcietb_pipe_phy (pclk_a, pclk_b, resetn, pipe_mode, A_lane_conn, B_lane_conn, A_txdata, A_txdatak, A_txdetectrx, A_txelecidle, A_txcompl, A_rxpolarity, A_powerdown, A_rxdata, A_rxdatak, A_rxvalid, A_phystatus, A_rxelecidle, A_rxstatus, B_txdata, B_txdatak, B_txdetectrx, B_txelecidle, B_txcompl, B_rxpolarity, B_powerdown, B_rxdata, B_rxdatak, B_rxvalid, B_phystatus, B_rxelecidle, B_rxstatus,B_rate,A_rate);

   parameter APIPE_WIDTH  = 16;
   parameter BPIPE_WIDTH  = 16;
   parameter LANE_NUM  = 0;
   parameter A_MAC_NAME  = "EP";
   parameter B_MAC_NAME  = "RP";
   // Latency should be 2 or greater
   parameter LATENCY = 23;
   input pclk_a; 
   input pclk_b; 
   input resetn; 
   input pipe_mode; 
   input A_lane_conn; 
   input B_lane_conn;
input 	 A_rate;
input 	 B_rate;
   input[APIPE_WIDTH - 1:0] A_txdata; 
   input[(APIPE_WIDTH / 8) - 1:0] A_txdatak; 
   input A_txdetectrx; 
   input A_txelecidle; 
   input A_txcompl; 
   input A_rxpolarity; 
   input[1:0] A_powerdown; 
   output[APIPE_WIDTH - 1:0] A_rxdata; 
   wire[APIPE_WIDTH - 1:0] A_rxdata;
   output[(APIPE_WIDTH / 8) - 1:0] A_rxdatak; 
   wire[(APIPE_WIDTH / 8) - 1:0] A_rxdatak;
   output A_rxvalid; 
   wire A_rxvalid;
   output A_phystatus; 
   wire A_phystatus;
   output A_rxelecidle; 
   wire A_rxelecidle;
   output[2:0] A_rxstatus; 
   wire[2:0] A_rxstatus;
   input[BPIPE_WIDTH - 1:0] B_txdata; 
   input[(BPIPE_WIDTH / 8) - 1:0] B_txdatak; 
   input B_txdetectrx; 
   input B_txelecidle; 
   input B_txcompl; 
   input B_rxpolarity; 
   input[1:0] B_powerdown; 
   output[BPIPE_WIDTH - 1:0] B_rxdata;
   output[(BPIPE_WIDTH / 8) - 1:0] B_rxdatak; 
   output B_rxvalid;
   wire[BPIPE_WIDTH - 1:0] B_rxdata_i;
   wire [(BPIPE_WIDTH / 8) - 1:0] B_rxdatak_i; 
   wire B_rxvalid_i; 
   output B_phystatus; 
   wire B_phystatus;
   output B_rxelecidle; 
   wire B_rxelecidle;
   output[2:0] B_rxstatus; 
   wire[2:0] B_rxstatus;

   wire[APIPE_WIDTH - 1:0] A2B_data; 
   wire[(APIPE_WIDTH / 8) - 1:0] A2B_datak; 
   wire A2B_elecidle; 

   wire[APIPE_WIDTH - 1:0] B2A_data; 
   wire[(APIPE_WIDTH / 8) - 1:0] B2A_datak; 
   wire B2A_elecidle; 

   // For a 250MHz 8-Bit PIPE the fifo needs to be 2x the length for the same latency
   // Add latency on B side only because it is interface to RP which has a known
   // interface of 250Mhz SDR 8 bit
   localparam FIFO_LENGTH = LATENCY * (16/BPIPE_WIDTH);
   reg [FIFO_LENGTH * BPIPE_WIDTH - 1:0] B_txdata_shift;
   reg [FIFO_LENGTH * BPIPE_WIDTH - 1:0] B_rxdata_shift;
   reg[FIFO_LENGTH - 1:0] B_rxvalid_shift;
   reg[FIFO_LENGTH * (BPIPE_WIDTH / 8) - 1:0] B_txdatak_shift;
   reg[FIFO_LENGTH * (BPIPE_WIDTH / 8) - 1:0] B_rxdatak_shift; 
   reg[FIFO_LENGTH - 1:0] B_txelecidle_shift;

   assign B_rxdata = B_rxdata_shift[FIFO_LENGTH * BPIPE_WIDTH - 1: (FIFO_LENGTH - 1) * BPIPE_WIDTH];
   assign B_rxdatak = B_rxdatak_shift[FIFO_LENGTH * (BPIPE_WIDTH/8) - 1: (FIFO_LENGTH - 1) * (BPIPE_WIDTH/8)];
   assign B_rxvalid = B_rxvalid_shift[FIFO_LENGTH-1];

// Shift register to add latency between the pipe to pipe connection.
// Length of the shift registers scales with the length of the desired latency.
   always @(posedge pclk_b)
   begin
      if (resetn == 1'b0)
      begin
         B_rxdata_shift     <= {(FIFO_LENGTH *  BPIPE_WIDTH)   {1'b0}};
         B_rxdatak_shift    <= {(FIFO_LENGTH * (BPIPE_WIDTH/8)){1'b0}};
         B_rxvalid_shift <= { FIFO_LENGTH                   {1'b0}};
         B_txdata_shift     <= {(FIFO_LENGTH *  BPIPE_WIDTH)   {1'b0}};
         B_txdatak_shift    <= {(FIFO_LENGTH * (BPIPE_WIDTH/8)){1'b0}};
         B_txelecidle_shift <= { FIFO_LENGTH                   {1'b1}};
      end
      else
      begin
         B_rxdata_shift     <= {    B_rxdata_shift[FIFO_LENGTH *  BPIPE_WIDTH    - 1:0], B_rxdata_i };
         B_rxdatak_shift    <= {   B_rxdatak_shift[FIFO_LENGTH * (BPIPE_WIDTH/8) - 1:0], B_rxdatak_i};
         B_rxvalid_shift <= {B_rxvalid_shift[FIFO_LENGTH - 1: 0], B_rxvalid_i};
         B_txdata_shift     <= {    B_txdata_shift[FIFO_LENGTH *  BPIPE_WIDTH    - 1:0], B_txdata };
         B_txdatak_shift    <= {   B_txdatak_shift[FIFO_LENGTH * (BPIPE_WIDTH/8) - 1:0], B_txdatak};
         B_txelecidle_shift <= {B_txelecidle_shift[FIFO_LENGTH - 1: 0], B_txelecidle};
      end
   end

   altpcietb_pipe_xtx2yrx #(APIPE_WIDTH, APIPE_WIDTH, LANE_NUM, A_MAC_NAME) A2B(
      .X_lane_conn(A_lane_conn), 
      .Y_lane_conn(B_lane_conn), 
      .pclk(pclk_a), 
      .resetn(resetn), 
      .pipe_mode(pipe_mode), 
      .X_txdata(A_txdata), 
      .X_txdatak(A_txdatak), 
      .X_txdetectrx(A_txdetectrx),
      .X_rate(A_rate), 
      .X_txelecidle(A_txelecidle), 
      .X_txcompl(A_txcompl), 
      .X_rxpolarity(A_rxpolarity), 
      .X_powerdown(A_powerdown), 
      .X_rxdata(A_rxdata), 
      .X_rxdatak(A_rxdatak), 
      .X_rxvalid(A_rxvalid), 
      .X_phystatus(A_phystatus), 
      .X_rxelecidle(A_rxelecidle), 
      .X_rxstatus(A_rxstatus), 
      .X2Y_data(A2B_data), 
      .X2Y_datak(A2B_datak), 
      .X2Y_elecidle(A2B_elecidle), 
      .Y2X_data(B2A_data), 
      .Y2X_datak(B2A_datak), 
      .Y2X_elecidle(B2A_elecidle)
   ); 

   altpcietb_pipe_xtx2yrx #(BPIPE_WIDTH, APIPE_WIDTH, LANE_NUM, B_MAC_NAME) B2A(
      .X_lane_conn(B_lane_conn), 
      .Y_lane_conn(A_lane_conn), 
      .pclk(pclk_b), 
      .resetn(resetn), 
      .pipe_mode(pipe_mode), 
      .X_txdata(B_txdata_shift[FIFO_LENGTH * BPIPE_WIDTH - 1: (FIFO_LENGTH - 1) * BPIPE_WIDTH]), 
      .X_txdatak(B_txdatak_shift[FIFO_LENGTH * (BPIPE_WIDTH/8) - 1: (FIFO_LENGTH - 1) * (BPIPE_WIDTH/8)]), 
      .X_txdetectrx(B_txdetectrx),
      .X_rate(B_rate),
      .X_txelecidle(B_txelecidle_shift[FIFO_LENGTH - 1]), 
      .X_txcompl(B_txcompl), 
      .X_rxpolarity(B_rxpolarity), 
      .X_powerdown(B_powerdown), 
      .X_rxdata(B_rxdata_i), 
      .X_rxdatak(B_rxdatak_i), 
      .X_rxvalid(B_rxvalid_i), 
      .X_phystatus(B_phystatus), 
      .X_rxelecidle(B_rxelecidle), 
      .X_rxstatus(B_rxstatus), 
      .X2Y_data(B2A_data), 
      .X2Y_datak(B2A_datak), 
      .X2Y_elecidle(B2A_elecidle), 
      .Y2X_data(A2B_data), 
      .Y2X_datak(A2B_datak), 
      .Y2X_elecidle(A2B_elecidle)
   ); 
endmodule
