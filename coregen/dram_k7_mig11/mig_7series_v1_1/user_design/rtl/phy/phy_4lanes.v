/**********************************************************
-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

//
// THIS NOTICE MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES.
//
//
//  Owner:        Gary Martin
//  Revision:     $Id: phy_4lanes.v,v 1.13.4.3 2011/01/08 11:34:37 karthip Exp $
//                $Author: karthip $
//                $DateTime: 2010/05/11 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is the parameterizable 4-byte lane phy primitive top
//    This module may be ganged to create an N-lane phy.
//
//  History:
//  Date        Engineer    Description
//  04/01/2010  G. Martin   Initial Checkin.
//
///////////////////////////////////////////////////////////
**********************************************************/

`timescale 1ps/1ps

module phy_4lanes #(
parameter  GENERATE_IDELAYCTRL  = "TRUE",
parameter  GENERATE_DDR_CK      = "B",   // choose lane "A", "B", "C" or "D"
// next three parameter fields correspond to byte lanes for lane order DCBA
parameter  BYTE_LANES           = 4'b1111, // lane existence, one per lane
parameter  DATA_CTL_N           = 4'b1111, // data or control, per lane
parameter  BITLANES             = 48'hffff_ffff_ffff,
parameter  BITLANES_OUTONLY     = 48'h0000_0000_0000,
parameter  LANE_REMAP           = 16'h3210,// 4-bit index
                                        // used to rewire to one of four
                                        // input/output buss lanes
                                        // example: 0321 remaps lanes as:
                                        //  D->A
                                        //  C->D
                                        //  B->C
                                        //  A->B
parameter   LAST_BANK              = "FALSE",
parameter   DIFFERENTIAL_DQS       = "TRUE",
parameter   RCLK_SELECT_LANE       = "B",

//phaser_in parameters
parameter  A_PI_FREQ_REF_DIV       = "NONE",
parameter  A_PI_CLKOUT_DIV         = 2,
parameter  A_PI_BURST_MODE         = "TRUE",
parameter  A_PI_OUTPUT_CLK_SRC     = "DELAYED_REF" , //"DELAYED_REF",
parameter  A_PI_FINE_DELAY         = 60,
parameter  A_PI_SYNC_IN_DIV_RST    = "TRUE",

parameter  B_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  B_PI_CLKOUT_DIV         = A_PI_CLKOUT_DIV,
parameter  B_PI_BURST_MODE         = A_PI_BURST_MODE,
parameter  B_PI_OUTPUT_CLK_SRC     = A_PI_OUTPUT_CLK_SRC,
parameter  B_PI_FINE_DELAY         = A_PI_FINE_DELAY,
parameter  B_PI_SYNC_IN_DIV_RST    = A_PI_SYNC_IN_DIV_RST,

parameter  C_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  C_PI_CLKOUT_DIV         = A_PI_CLKOUT_DIV,
parameter  C_PI_BURST_MODE         = A_PI_BURST_MODE,
parameter  C_PI_OUTPUT_CLK_SRC     = A_PI_OUTPUT_CLK_SRC,
parameter  C_PI_FINE_DELAY         = 0,
parameter  C_PI_SYNC_IN_DIV_RST    = A_PI_SYNC_IN_DIV_RST,

parameter  D_PI_FREQ_REF_DIV       = A_PI_FREQ_REF_DIV,
parameter  D_PI_CLKOUT_DIV         = A_PI_CLKOUT_DIV,
parameter  D_PI_BURST_MODE         = A_PI_BURST_MODE,
parameter  D_PI_OUTPUT_CLK_SRC     = A_PI_OUTPUT_CLK_SRC,
parameter  D_PI_FINE_DELAY         = 0,
parameter  D_PI_SYNC_IN_DIV_RST    = A_PI_SYNC_IN_DIV_RST,

//phaser_out parameters
parameter  A_PO_CLKOUT_DIV         = (DATA_CTL_N[0] == 0) ? 4 :  2,
parameter  A_PO_FINE_DELAY         = 0,
parameter  A_PO_COARSE_DELAY       = 0,
parameter  A_PO_OCLK_DELAY         = 0,
parameter  A_PO_OCLKDELAY_INV      = "FALSE",
parameter  A_PO_OUTPUT_CLK_SRC     = "DELAYED_REF",
parameter  A_PO_SYNC_IN_DIV_RST    = "TRUE",
//parameter  A_PO_SYNC_IN_DIV_RST    = "FALSE",

parameter  B_PO_CLKOUT_DIV         = (DATA_CTL_N[1] == 0) ? 4 :  2,
parameter  B_PO_FINE_DELAY         = A_PO_FINE_DELAY,
parameter  B_PO_COARSE_DELAY       = A_PO_COARSE_DELAY,
parameter  B_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  B_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  B_PO_OUTPUT_CLK_SRC     = A_PO_OUTPUT_CLK_SRC,
parameter  B_PO_SYNC_IN_DIV_RST    = A_PO_SYNC_IN_DIV_RST,

parameter  C_PO_CLKOUT_DIV         = (DATA_CTL_N[2] == 0) ? 4 :  2,
parameter  C_PO_FINE_DELAY         = A_PO_FINE_DELAY,
parameter  C_PO_COARSE_DELAY       = A_PO_COARSE_DELAY,
parameter  C_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  C_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  C_PO_OUTPUT_CLK_SRC     = A_PO_OUTPUT_CLK_SRC,
parameter  C_PO_SYNC_IN_DIV_RST    = A_PO_SYNC_IN_DIV_RST,

parameter  D_PO_CLKOUT_DIV         = (DATA_CTL_N[3] == 0) ? 4 :  2,
parameter  D_PO_FINE_DELAY         = A_PO_FINE_DELAY,
parameter  D_PO_COARSE_DELAY       = A_PO_COARSE_DELAY,
parameter  D_PO_OCLK_DELAY         = A_PO_OCLK_DELAY,
parameter  D_PO_OCLKDELAY_INV      = A_PO_OCLKDELAY_INV,
parameter  D_PO_OUTPUT_CLK_SRC     = A_PO_OUTPUT_CLK_SRC,
parameter  D_PO_SYNC_IN_DIV_RST    = A_PO_SYNC_IN_DIV_RST,

parameter  A_IDELAYE2_IDELAY_TYPE  = "VARIABLE",
parameter  A_IDELAYE2_IDELAY_VALUE = 00,
parameter  B_IDELAYE2_IDELAY_TYPE  = A_IDELAYE2_IDELAY_TYPE,
parameter  B_IDELAYE2_IDELAY_VALUE = A_IDELAYE2_IDELAY_VALUE,
parameter  C_IDELAYE2_IDELAY_TYPE  = A_IDELAYE2_IDELAY_TYPE,
parameter  C_IDELAYE2_IDELAY_VALUE = A_IDELAYE2_IDELAY_VALUE,
parameter  D_IDELAYE2_IDELAY_TYPE  = A_IDELAYE2_IDELAY_TYPE,
parameter  D_IDELAYE2_IDELAY_VALUE = A_IDELAYE2_IDELAY_VALUE,
parameter  IODELAY_GRP             = "IODELAY_MIG",


// phy_control parameters

parameter PC_BURST_MODE           = "TRUE",
parameter PC_CLK_RATIO            = 4,
parameter PC_DATA_CTL_N           =  DATA_CTL_N,
parameter PC_CMD_OFFSET           = 0,
parameter PC_RD_CMD_OFFSET_0      = 0,
parameter PC_RD_CMD_OFFSET_1      = 0,
parameter PC_RD_CMD_OFFSET_2      = 0,
parameter PC_RD_CMD_OFFSET_3      = 0,
parameter PC_CO_DURATION          = 1,
parameter PC_DI_DURATION          = 1,
parameter PC_DO_DURATION          = 1,
parameter PC_RD_DURATION_0        = 0,
parameter PC_RD_DURATION_1        = 0,
parameter PC_RD_DURATION_2        = 0,
parameter PC_RD_DURATION_3        = 0,
parameter PC_WR_CMD_OFFSET_0      = 5,
parameter PC_WR_CMD_OFFSET_1      = 5,
parameter PC_WR_CMD_OFFSET_2      = 5,
parameter PC_WR_CMD_OFFSET_3      = 5,
parameter PC_WR_DURATION_0        = 6,
parameter PC_WR_DURATION_1        = 6,
parameter PC_WR_DURATION_2        = 6,
parameter PC_WR_DURATION_3        = 6,
parameter PC_AO_WRLVL_EN          = 0,
parameter PC_AO_TOGGLE            = 4'b0101, // odd bits are toggle (CKE)
parameter PC_FOUR_WINDOW_CLOCKS   = 63,
parameter PC_EVENTS_DELAY         = 18,
parameter PC_PHY_COUNT_EN         = "TRUE",
parameter PC_SYNC_MODE            = "TRUE",
parameter PC_DISABLE_SEQ_MATCH    = "TRUE",

// io fifo parameters

parameter  A_OF_ARRAY_MODE        = (DATA_CTL_N[0] == 1) ? "ARRAY_MODE_8_X_4" :  "ARRAY_MODE_4_X_4",
parameter  B_OF_ARRAY_MODE        = (DATA_CTL_N[1] == 1) ? "ARRAY_MODE_8_X_4" :  "ARRAY_MODE_4_X_4",
parameter  C_OF_ARRAY_MODE        = (DATA_CTL_N[2] == 1) ? "ARRAY_MODE_8_X_4" :  "ARRAY_MODE_4_X_4",
parameter  D_OF_ARRAY_MODE        = (DATA_CTL_N[3] == 1) ? "ARRAY_MODE_8_X_4" :  "ARRAY_MODE_4_X_4",
parameter  OF_ALMOST_EMPTY_VALUE  = 1,
parameter  OF_ALMOST_FULL_VALUE   = 1,
parameter  OF_OUTPUT_DISABLE      = "TRUE",
parameter  OF_SYNCHRONOUS_MODE    = PC_SYNC_MODE,


parameter  IF_ARRAY_MODE          = "ARRAY_MODE_4_X_8",
parameter  IF_ALMOST_EMPTY_VALUE  =  1,
parameter  IF_ALMOST_FULL_VALUE   =  1,
parameter  IF_SYNCHRONOUS_MODE    = PC_SYNC_MODE,


// this is used locally, not for external pushdown
// NOTE: the 0+ is needed in each to coerce to integer for addition.
// otherwise 4x 1'b values are added producing a 1'b value.
parameter HIGHEST_LANE  =  LAST_BANK == "FALSE" ? 4 : (BYTE_LANES[3] ? 4 : BYTE_LANES[2] ? 3 : BYTE_LANES[1] ? 2 : 1),
parameter  N_CTL_LANES = ((0+(!DATA_CTL_N[0]) & BYTE_LANES[0]) + (0+(!DATA_CTL_N[1]) & BYTE_LANES[1]) + (0+(!DATA_CTL_N[2]) & BYTE_LANES[2]) + (0+(!DATA_CTL_N[3]) & BYTE_LANES[3])),

parameter  N_BYTE_LANES = (0+BYTE_LANES[0]) + (0+BYTE_LANES[1]) + (0+BYTE_LANES[2]) + (0+BYTE_LANES[3]),

parameter N_DATA_LANES = N_BYTE_LANES - N_CTL_LANES,
// assume odt per rank + any declared cke's
parameter  AUXOUT_WIDTH = 4
)
(

//`include "phy.vh"

      input                       rst,
      input                       phy_clk,
      input                       phy_ctl_clk,
      input                       freq_refclk,
      input                       mem_refclk,
      input                       mem_refclk_div4,
      input                       pll_lock,
      input                       sync_pulse,
      input [HIGHEST_LANE*80-1:0] phy_dout,
      input                       phy_cmd_wr_en,
      input                       phy_data_wr_en,
      input                       if_empty_or,
      input [31:0]                phy_ctl_wd,
      input                       phy_ctl_wr,
      input                       input_sink,

      output  [1:0]               ddr_clk,  // to memory
      output                      rclk,
      output                      if_a_empty,
      output                      if_empty,
      output                      of_ctl_a_full,
      output                      of_data_a_full,
      output                      of_ctl_full,
      output                      of_data_full,
      output [HIGHEST_LANE*80-1:0]phy_din, // assume input bus same size as output bus
      output                      phy_ctl_a_full,
      output                      phy_ctl_full,
      inout  [HIGHEST_LANE*12-1:0]IO,
      inout  [HIGHEST_LANE*2-1:0] DQS,
      output [HIGHEST_LANE*12-1:0]mem_dq_out,
      output [HIGHEST_LANE*12-1:0]mem_dq_ts,
      input  [HIGHEST_LANE*10-1:0]mem_dq_in,
      output [HIGHEST_LANE-1:0]   mem_dqs_out,
      output [HIGHEST_LANE-1:0]   mem_dqs_ts,
      input  [HIGHEST_LANE-1:0]   mem_dqs_in,

      output     [AUXOUT_WIDTH-1:0]aux_out,
      output reg                  rst_out = 0,
      output reg                  mcGo,
      output                      phy_ctl_ready,
      input                       phy_read_calib,
      input                       phy_write_calib,
      input                        idelay_inc,
      input                        idelay_ce,
      input                        idelay_ld,
      input  [2:0]                 calib_sel,
      input                        calib_in_common,
      output [1:0]                 phy_encalib,
      input                        po_fine_enable,
      input                        po_coarse_enable,
      input                        po_fine_inc,
      input                        po_coarse_inc,
      input                        po_counter_load_en,
      input                        po_counter_read_en,
      input  [8:0]                 po_counter_load_val,
      input                        po_sel_fine_oclk_delay,
      output reg                   po_coarse_overflow,
      output reg                   po_fine_overflow,
      output reg [8:0]             po_counter_read_val,



      input                        pi_rst_dqs_find,
      input                        pi_fine_enable,
      input                        pi_fine_inc,
      input                        pi_counter_load_en,
      input                        pi_counter_read_en,
      input  [5:0]                 pi_counter_load_val,
      output reg                   pi_fine_overflow,
      output reg [5:0]             pi_counter_read_val,

      output reg                   pi_dqs_found,
      output                       pi_dqs_found_all,
      output                       pi_dqs_found_any,
      output reg                   pi_dqs_out_of_range,
      output reg                   pi_phase_locked,
      output                       pi_phase_locked_all
);

localparam  DATA_CTL_A       = (~DATA_CTL_N[0]);
localparam  DATA_CTL_B       = (~DATA_CTL_N[1]);
localparam  DATA_CTL_C       = (~DATA_CTL_N[2]);
localparam  DATA_CTL_D       = (~DATA_CTL_N[3]);
localparam  PRESENT_CTL_A    = BYTE_LANES[0] && ! DATA_CTL_N[0];
localparam  PRESENT_CTL_B    = BYTE_LANES[1] && ! DATA_CTL_N[1];
localparam  PRESENT_CTL_C    = BYTE_LANES[2] && ! DATA_CTL_N[2];
localparam  PRESENT_CTL_D    = BYTE_LANES[3] && ! DATA_CTL_N[3];
localparam  PRESENT_DATA_A   = BYTE_LANES[0] &&  DATA_CTL_N[0];
localparam  PRESENT_DATA_B   = BYTE_LANES[1] &&  DATA_CTL_N[1];
localparam  PRESENT_DATA_C   = BYTE_LANES[2] &&  DATA_CTL_N[2];
localparam  PRESENT_DATA_D   = BYTE_LANES[3] &&  DATA_CTL_N[3];
localparam  PC_DATA_CTL_A    = (DATA_CTL_A) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_B    = (DATA_CTL_B) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_C    = (DATA_CTL_C) ? "FALSE" : "TRUE";
localparam  PC_DATA_CTL_D    = (DATA_CTL_D) ? "FALSE" : "TRUE";

localparam  IO_A_START = 41;
localparam  IO_A_END   = 40;
localparam  IO_B_START = 43;
localparam  IO_B_END   = 42;
localparam  IO_C_START = 45;
localparam  IO_C_END   = 44;
localparam  IO_D_START = 47;
localparam  IO_D_END   = 46;
localparam  IO_A_X_START = (HIGHEST_LANE * 10) + 1;
localparam  IO_A_X_END   = (IO_A_X_START-1);
localparam  IO_B_X_START = (IO_A_X_START + 2);
localparam  IO_B_X_END   = (IO_B_X_START -1);
localparam  IO_C_X_START = (IO_B_X_START + 2);
localparam  IO_C_X_END   = (IO_C_X_START -1);
localparam  IO_D_X_START = (IO_C_X_START + 2);
localparam  IO_D_X_END   = (IO_D_X_START -1);

localparam MSB_BURST_PEND_PO             =  3;
localparam MSB_BURST_PEND_PI             =  7;
localparam MSB_RANK_SEL_I                =  MSB_BURST_PEND_PI+ 8;
localparam PHASER_CTL_BUS_WIDTH          =  MSB_RANK_SEL_I + 1;

wire [1:0]  oserdes_dqs;
wire [1:0]  oserdes_dqs_ts;
wire [1:0]  oserdes_dq_ts;


wire [PHASER_CTL_BUS_WIDTH-1:0] phaser_ctl_bus;
wire [7:0]  in_rank;
wire [11:0] IO_A;
wire [11:0] IO_B;
wire [11:0] IO_C;
wire [11:0] IO_D;

wire [319:0] phy_din_remap;

reg        A_po_counter_read_en;
wire [8:0] A_po_counter_read_val;
reg        A_pi_counter_read_en;
wire [5:0] A_pi_counter_read_val;
wire       A_pi_fine_overflow;
wire       A_po_coarse_overflow;
wire       A_po_fine_overflow;
wire       A_pi_dqs_found;
wire       A_pi_dqs_out_of_range;
wire       A_pi_phase_locked;
wire       A_pi_iserdes_rst;  
reg        A_pi_fine_enable;
reg        A_pi_fine_inc;
reg        A_pi_counter_load_en;
reg [5:0]  A_pi_counter_load_val;


reg        A_po_fine_enable;
reg        A_po_coarse_enable;
reg        A_po_fine_inc;
reg        A_po_sel_fine_oclk_delay;
reg        A_po_coarse_inc;
reg        A_po_counter_load_en;
reg [8:0]  A_po_counter_load_val;
wire       A_rclk;


reg        B_po_counter_read_en;
wire [8:0] B_po_counter_read_val;
reg        B_pi_counter_read_en;
wire [5:0] B_pi_counter_read_val;
wire       B_pi_fine_overflow;
wire       B_po_coarse_overflow;
wire       B_po_fine_overflow;
wire       B_pi_phase_locked;
wire       B_pi_iserdes_rst;  
wire       B_pi_dqs_found;
wire       B_pi_dqs_out_of_range;
reg        B_pi_fine_enable;
reg        B_pi_fine_inc;
reg        B_pi_counter_load_en;
reg [5:0]  B_pi_counter_load_val;


reg        B_po_fine_enable;
reg        B_po_coarse_enable;
reg        B_po_fine_inc;
reg        B_po_coarse_inc;
reg        B_po_sel_fine_oclk_delay;
reg        B_po_counter_load_en;
reg [8:0]  B_po_counter_load_val;
wire       B_rclk;


reg        C_pi_fine_inc;
reg        D_pi_fine_inc;
reg        C_pi_fine_enable;
reg        D_pi_fine_enable;
reg        C_po_counter_load_en;
reg        D_po_counter_load_en;
reg        C_po_coarse_inc;
reg        D_po_coarse_inc;
reg        C_po_fine_inc;
reg        D_po_fine_inc;
reg        C_po_sel_fine_oclk_delay;
reg        D_po_sel_fine_oclk_delay;
reg [5:0]  C_pi_counter_load_val;
reg [5:0]  D_pi_counter_load_val;
reg [8:0]  C_po_counter_load_val;
reg [8:0]  D_po_counter_load_val;
reg        C_po_coarse_enable;
reg        D_po_coarse_enable;
reg        C_po_fine_enable;
reg        D_po_fine_enable;
wire       C_po_coarse_overflow;
wire       D_po_coarse_overflow;
wire       C_po_fine_overflow;
wire       D_po_fine_overflow;
wire [8:0] C_po_counter_read_val;
wire [8:0] D_po_counter_read_val;
reg        C_po_counter_read_en;
reg        D_po_counter_read_en;
wire       C_pi_dqs_found;
wire       D_pi_dqs_found;
wire       C_pi_fine_overflow;
wire       D_pi_fine_overflow;
reg        C_pi_counter_read_en;
reg        D_pi_counter_read_en;
reg        C_pi_counter_load_en;
reg        D_pi_counter_load_en;
wire       C_pi_phase_locked;
wire       C_pi_iserdes_rst;
wire       D_pi_phase_locked;
wire       D_pi_iserdes_rst;  
wire       C_pi_dqs_out_of_range;
wire       D_pi_dqs_out_of_range;
wire [5:0] C_pi_counter_read_val;
wire [5:0] D_pi_counter_read_val;
wire       C_rclk;
wire       D_rclk;

wire       pi_iserdes_rst;
  
wire       A_if_empty;
wire       B_if_empty;
wire       C_if_empty;
wire       D_if_empty;
wire       A_if_a_empty;
wire       B_if_a_empty;
wire       C_if_a_empty;
wire       D_if_a_empty;  
wire       A_if_full;
wire       B_if_full;
wire       C_if_full;
wire       D_if_full;
wire       A_of_empty;
wire       B_of_empty;
wire       C_of_empty;
wire       D_of_empty;
wire       A_of_full;
wire       B_of_full;
wire       C_of_full;
wire       D_of_full;
wire       A_of_ctl_full;
wire       B_of_ctl_full;
wire       C_of_ctl_full;
wire       D_of_ctl_full;
wire       A_of_data_full;
wire       B_of_data_full;
wire       C_of_data_full;
wire       D_of_data_full;
wire       A_of_a_full;
wire       B_of_a_full;
wire       C_of_a_full;
wire       D_of_a_full;
wire       A_of_ctl_a_full;
wire       B_of_ctl_a_full;
wire       C_of_ctl_a_full;
wire       D_of_ctl_a_full;
wire       A_of_data_a_full;
wire       B_of_data_a_full;
wire       C_of_data_a_full;
wire       D_of_data_a_full;
wire  [1:0]  A_ddr_clk;  // for generation
wire  [1:0]  B_ddr_clk;  // 
wire  [1:0]  C_ddr_clk;  // 
wire  [1:0]  D_ddr_clk;  // 

assign  pi_dqs_found_any =
           ( PRESENT_DATA_A & A_pi_dqs_found) |
           ( PRESENT_DATA_B & B_pi_dqs_found) |
           ( PRESENT_DATA_C & C_pi_dqs_found) |
           ( PRESENT_DATA_D & D_pi_dqs_found) ;

assign  pi_dqs_found_all = 
           (! PRESENT_DATA_A | A_pi_dqs_found) & 
           (! PRESENT_DATA_B | B_pi_dqs_found) & 
           (! PRESENT_DATA_C | C_pi_dqs_found) & 
           (! PRESENT_DATA_D | D_pi_dqs_found) ;

assign  pi_phase_locked_all = 
           (! PRESENT_DATA_A | A_pi_phase_locked) & 
           (! PRESENT_DATA_B | B_pi_phase_locked) & 
           (! PRESENT_DATA_C | C_pi_phase_locked) & 
           (! PRESENT_DATA_D | D_pi_phase_locked);

wire       dangling_outputs;  // this reduces all constant 0 values to 1 signal
                              // which can be tied to an unused input. The purpose
                              // is to fake the tools into ignoring dangling outputs.
                              // Because it is anded with 1'b0, the contributing signals
                              // are folded as constants or trimmed.

assign     dangling_outputs = ( &phy_dout) ;

assign      if_empty = A_if_empty | B_if_empty | C_if_empty | D_if_empty;
assign      if_a_empty = A_if_a_empty | B_if_a_empty | C_if_a_empty | D_if_a_empty;
assign      if_full  = A_if_full  | B_if_full  | C_if_full  | D_if_full ;
assign      of_empty = A_of_empty | B_of_empty | C_of_empty | D_of_empty;
assign      of_ctl_full     = A_of_ctl_full  | B_of_ctl_full  | C_of_ctl_full  | D_of_ctl_full ;
assign      of_data_full    = A_of_data_full  | B_of_data_full  | C_of_data_full  | D_of_data_full ;
assign      of_ctl_a_full   = A_of_ctl_a_full  | B_of_ctl_a_full  | C_of_ctl_a_full  | D_of_ctl_a_full ;
assign      of_data_a_full  = A_of_data_a_full  | B_of_data_a_full  | C_of_data_a_full  | D_of_data_a_full ;


function [79:0] part_select_80;
input [319:0] vector;
input [1:0]  select;
begin
     case (select)
     2'b00 : part_select_80[79:0] = vector[1*80-1:0*80];
     2'b01 : part_select_80[79:0] = vector[2*80-1:1*80];
     2'b10 : part_select_80[79:0] = vector[3*80-1:2*80];
     2'b11 : part_select_80[79:0] = vector[4*80-1:3*80];
     endcase
end
endfunction

wire [319:0]     phy_dout_remap;

reg         rst_out_trig = 1'b0;
reg [31:0]  rclk_delay;
reg         rst_edge1 = 1'b0;
reg         rst_edge2 = 1'b0;
reg         rst_edge3 = 1'b0;
reg         rst_edge_detect = 1'b0;
wire        rclk_;
reg         rst_out_start = 1'b0 ;

generate

if (RCLK_SELECT_LANE == "A")  begin
     assign rclk_ = A_rclk;
     assign pi_iserdes_rst = A_pi_iserdes_rst;
     end
else if (RCLK_SELECT_LANE == "B")  begin
     assign rclk_ = B_rclk;
     assign pi_iserdes_rst = B_pi_iserdes_rst;
     end
else if (RCLK_SELECT_LANE == "C") begin
     assign rclk_ = C_rclk;
     assign pi_iserdes_rst = C_pi_iserdes_rst;
     end
else if (RCLK_SELECT_LANE == "D") begin
     assign rclk_ = D_rclk;
     assign pi_iserdes_rst = D_pi_iserdes_rst;
     end
else  begin
     assign rclk_ = B_rclk; // default
     end

if ( GENERATE_DDR_CK == "A")
    assign ddr_clk = A_ddr_clk;
if ( GENERATE_DDR_CK == "B")
    assign ddr_clk = B_ddr_clk;
if ( GENERATE_DDR_CK == "C")
    assign ddr_clk = C_ddr_clk;
if ( GENERATE_DDR_CK == "D")
    assign ddr_clk = D_ddr_clk;
endgenerate


always @(posedge mem_refclk_div4 or posedge rst) begin

        if ( rst == 1)  begin
            rst_out       <= #1 0;
            rst_out_start <= #1  0;
            mcGo          <= #1 0;
            rst_out_trig  <= #1 0;
            rst_edge1     <= #1 1;
            rst_edge2     <= #1 0;
            rst_edge3     <= #1 0;
            rst_edge_detect <= #1 0;
        end
        else  begin
          rst_edge1 <= #1 rst;
          rst_edge2 <= #1 rst_edge1;
          rst_edge3 <= #1 rst_edge2;
          rst_edge_detect <= #1 rst_edge3  == 1 && rst_edge2 == 0 || rst_edge_detect ;
          if ( rst_out == 1)
                rst_out_start <= #1  0;
            else 
             rst_out_start <= #1 rst_out_start ||  (rclk_delay[11] === 0 && ! rst_out_trig &&  rst_edge_detect);
        
           rclk_delay <= #1 (rclk_delay << 1) | (rst_out_start);
           mcGo <= #1 rst_out == 1 && ! rst_out_start;
           rst_out_trig  <= #1 rst_out_trig ||  rst_out_start ;
           if (  rclk_delay[11] === 1)
             rst_out <= #1 1;
        end
  end

generate

  if (PRESENT_DATA_A) begin
      assign A_of_data_full     = A_of_full;
      assign A_of_ctl_full      = 0;
      assign A_of_data_a_full   = A_of_a_full;
      assign A_of_ctl_a_full    = 0;
  end
  else  begin
      assign A_of_ctl_full      = A_of_full;
      assign A_of_data_full     = 0;
      assign A_of_ctl_a_full    = A_of_a_full;
      assign A_of_data_a_full   = 0;
  end
  if (PRESENT_DATA_B) begin
      assign B_of_data_full     = B_of_full;
      assign B_of_ctl_full      = 0;
      assign B_of_data_a_full   = B_of_a_full;
      assign B_of_ctl_a_full    = 0;
  end
  else  begin
      assign B_of_ctl_full      = B_of_full;
      assign B_of_data_full     = 0;
      assign B_of_ctl_a_full    = B_of_a_full;
      assign B_of_data_a_full   = 0;
  end
  if (PRESENT_DATA_C) begin
      assign C_of_data_full     = C_of_full;
      assign C_of_ctl_full      = 0;
      assign C_of_data_a_full   = C_of_a_full;
      assign C_of_ctl_a_full    = 0;
  end
  else  begin
      assign C_of_ctl_full       = C_of_full;
      assign C_of_data_full      = 0;
      assign C_of_ctl_a_full     = C_of_a_full;
      assign C_of_data_a_full    = 0;
  end
  if (PRESENT_DATA_D) begin
      assign D_of_data_full      = D_of_full;
      assign D_of_ctl_full       = 0;
      assign D_of_data_a_full    = D_of_a_full;
      assign D_of_ctl_a_full     = 0;
  end
  else  begin
      assign D_of_ctl_full       = D_of_full;
      assign D_of_data_full      = 0;
      assign D_of_ctl_a_full     = D_of_a_full;
      assign D_of_data_a_full    = 0;
  end
// byte lane must exist and be data lane.
  if (PRESENT_DATA_A )
      case ( LANE_REMAP[1:0]   )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[79:0];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[79:0];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[79:0];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[79:0];
      endcase
  else
      case ( LANE_REMAP[1:0]   )
      2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
      2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
      2'b10 : assign phy_din[3*80-1:160] = 80'h0;
      2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase

  if (PRESENT_DATA_B )
      case ( LANE_REMAP[5:4]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[159:80];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[159:80];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[159:80];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[159:80];
      endcase
   else
      case ( LANE_REMAP[5:4]   )
      2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
      2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
      2'b10 : assign phy_din[3*80-1:160] = 80'h0;
      2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase

  if (PRESENT_DATA_C)
      case ( LANE_REMAP[9:8]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[239:160];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[239:160];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[239:160];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[239:160];
      endcase
  else
      case ( LANE_REMAP[9:8]   )
      2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
      2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
      2'b10 : assign phy_din[3*80-1:160] = 80'h0;
      2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase

  if (PRESENT_DATA_D )
      case ( LANE_REMAP[13:12]  )
      2'b00 : assign phy_din[1*80-1:0]   = phy_din_remap[319:240];
      2'b01 : assign phy_din[2*80-1:80]  = phy_din_remap[319:240];
      2'b10 : assign phy_din[3*80-1:160] = phy_din_remap[319:240];
      2'b11 : assign phy_din[4*80-1:240] = phy_din_remap[319:240];
      endcase
  else
      case ( LANE_REMAP[13:12]   )
      2'b00 : assign phy_din[1*80-1:0]   = 80'h0;
      2'b01 : assign phy_din[2*80-1:80]  = 80'h0;
      2'b10 : assign phy_din[3*80-1:160] = 80'h0;
      2'b11 : assign phy_din[4*80-1:240] = 80'h0;
      endcase
endgenerate


generate

endgenerate

//module BUFR (O, CE, CLR, I);
BUFR #(.BUFR_DIVIDE ("2")) rclk_buf(.I(rclk_), .O(rclk), .CE (1'b1), .CLR (pi_iserdes_rst));

generate

if ( BYTE_LANES[0] ) begin : byte_lane_A

  assign phy_dout_remap[79:0] = part_select_80(phy_dout, (LANE_REMAP[1:0]));

  byte_lane#(
     .ABCD                   ("A"),
     .PO_DATA_CTL            (PC_DATA_CTL_N[0] ? "TRUE" : "FALSE"),
     .BITLANES               (BITLANES[11:0]),
     .BITLANES_OUTONLY       (BITLANES_OUTONLY[11:0]),
     .OF_ALMOST_EMPTY_VALUE  (OF_ALMOST_EMPTY_VALUE),
     .OF_ALMOST_FULL_VALUE   (OF_ALMOST_FULL_VALUE),
     .OF_SYNCHRONOUS_MODE    (OF_SYNCHRONOUS_MODE),
     //.OF_OUTPUT_DISABLE      (OF_OUTPUT_DISABLE),
     //.OF_ARRAY_MODE          (A_OF_ARRAY_MODE),
     //.IF_ARRAY_MODE          (IF_ARRAY_MODE),
     .IF_ALMOST_EMPTY_VALUE  (IF_ALMOST_EMPTY_VALUE),
     .IF_ALMOST_FULL_VALUE   (IF_ALMOST_FULL_VALUE),
     .IF_SYNCHRONOUS_MODE    (IF_SYNCHRONOUS_MODE),
     .DIFFERENTIAL_DQS       (DIFFERENTIAL_DQS),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK),
     .PI_BURST_MODE          (A_PI_BURST_MODE),
     .PI_CLKOUT_DIV          (A_PI_CLKOUT_DIV),
     .PI_FREQ_REF_DIV        (A_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (A_PI_FINE_DELAY),
     .PI_OUTPUT_CLK_SRC      (A_PI_OUTPUT_CLK_SRC),
     .PI_SYNC_IN_DIV_RST     (A_PI_SYNC_IN_DIV_RST),
     .PO_CLKOUT_DIV          (A_PO_CLKOUT_DIV),
     .PO_FINE_DELAY          (A_PO_FINE_DELAY),
     .PO_COARSE_DELAY        (A_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (A_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (A_PO_OCLKDELAY_INV),
     .PO_OUTPUT_CLK_SRC      (A_PO_OUTPUT_CLK_SRC),
     .PO_SYNC_IN_DIV_RST     (A_PO_SYNC_IN_DIV_RST),
     .IDELAYE2_IDELAY_TYPE   (A_IDELAYE2_IDELAY_TYPE),
     .IDELAYE2_IDELAY_VALUE  (A_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP            (IODELAY_GRP)
     )
   byte_lane_A(
      .IO                    ({IO[IO_A_X_START:IO_A_X_END], IO[9:0]}),
      .mem_dq_out            (mem_dq_out[11:0]),
      .mem_dq_ts             (mem_dq_ts[11:0]),
      .mem_dq_in             (mem_dq_in[9:0]),
      .mem_dqs_out           (mem_dqs_out[0]),
      .mem_dqs_ts            (mem_dqs_ts[0]),
      .mem_dqs_in            (mem_dqs_in[0]),
      .DQS_P                 (DQS[0]),
      .DQS_N                 (DQS[4]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .ddr_ck_out            (A_ddr_clk),
      .rclk                  (A_rclk),
      .pi_dqs_found          (A_pi_dqs_found),
      .dqs_out_of_range      (A_pi_dqs_out_of_range),
      .if_a_empty            (A_if_a_empty),
      .if_empty              (A_if_empty),
      .if_a_full             (if_a_full),
      .if_full               (A_if_full),
      .of_a_empty            (of_a_empty),
      .of_empty              (A_of_empty),
      .of_a_full             (A_of_a_full),
      .of_full               (A_of_full),
      .phy_din               (phy_din_remap[79:0]),
      .phy_dout              (phy_dout_remap[79:0]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .if_empty_or           (if_empty_or),
      .phaser_ctl_bus        (phaser_ctl_bus),
// calibration signals
      .idelay_inc            (idelay_inc),
      .idelay_ce             (idelay_ce),
      .idelay_ld             (idelay_ld),
      .pi_rst_dqs_find       (pi_rst_dqs_find),
      .po_en_calib           (phy_encalib),
      .po_fine_enable        (A_po_fine_enable),
      .po_coarse_enable      (A_po_coarse_enable),
      .po_fine_inc           (A_po_fine_inc),
      .po_coarse_inc         (A_po_coarse_inc),
      .po_counter_load_en    (A_po_counter_load_en),
      .po_counter_read_en    (A_po_counter_read_en),
      .po_counter_load_val   (A_po_counter_load_val),
      .po_coarse_overflow    (A_po_coarse_overflow),
      .po_fine_overflow      (A_po_fine_overflow),
      .po_counter_read_val   (A_po_counter_read_val),
      .po_sel_fine_oclk_delay(A_po_sel_fine_oclk_delay),
      .pi_en_calib           (phy_encalib),
      .pi_fine_enable        (A_pi_fine_enable),
      .pi_fine_inc           (A_pi_fine_inc),
      .pi_counter_load_en    (A_pi_counter_load_en),
      .pi_counter_read_en    (A_pi_counter_read_en),
      .pi_counter_load_val   (A_pi_counter_load_val),
      .pi_fine_overflow      (A_pi_fine_overflow),
      .pi_counter_read_val   (A_pi_counter_read_val),
      .pi_iserdes_rst        (A_pi_iserdes_rst),
      .pi_phase_locked       (A_pi_phase_locked)
);

end
else begin : no_byte_lane_A
       assign A_of_a_full = 1'b0;
       assign A_of_full = 1'b0;
       assign A_if_empty = 1'b0;
       assign A_if_a_empty = 1'b0;
       assign A_pi_phase_locked = 1;
       assign A_pi_dqs_found     = 1;
       assign A_rclk = 0;
       assign IO[9:0]    = 0;
       assign IO[IO_A_X_START:IO_A_X_END]    = 0;
       assign DQS[0] = 1'b0;
       assign DQS[4] = 1'b0;
       assign A_pi_counter_read_val = 0;
       assign A_po_counter_read_val = 0;
       assign A_pi_fine_overflow    = 0;
       assign A_po_coarse_overflow  = 0;
       assign A_po_fine_overflow    = 0;
end

if ( BYTE_LANES[1] ) begin : byte_lane_B

  assign phy_dout_remap[159:80] = part_select_80(phy_dout, (LANE_REMAP[5:4]));
  byte_lane#(
     .ABCD                   ("B"),
     .PO_DATA_CTL            (PC_DATA_CTL_N[1] ? "TRUE" : "FALSE"),
     .BITLANES               (BITLANES[23:12]),
     .BITLANES_OUTONLY       (BITLANES_OUTONLY[23:12]),
     .OF_ALMOST_EMPTY_VALUE  (OF_ALMOST_EMPTY_VALUE),
     .OF_ALMOST_FULL_VALUE   (OF_ALMOST_FULL_VALUE),
     .OF_SYNCHRONOUS_MODE    (OF_SYNCHRONOUS_MODE),
     //.OF_OUTPUT_DISABLE      (OF_OUTPUT_DISABLE),
     //.OF_ARRAY_MODE          (B_OF_ARRAY_MODE),
     //.IF_ARRAY_MODE          (IF_ARRAY_MODE),
     .IF_ALMOST_EMPTY_VALUE  (IF_ALMOST_EMPTY_VALUE),
     .IF_ALMOST_FULL_VALUE   (IF_ALMOST_FULL_VALUE),
     .IF_SYNCHRONOUS_MODE    (IF_SYNCHRONOUS_MODE),
     .DIFFERENTIAL_DQS       (DIFFERENTIAL_DQS),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK),
     .PI_BURST_MODE          (B_PI_BURST_MODE),
     .PI_CLKOUT_DIV          (B_PI_CLKOUT_DIV),
     .PI_FREQ_REF_DIV        (B_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (B_PI_FINE_DELAY),
     .PI_OUTPUT_CLK_SRC      (B_PI_OUTPUT_CLK_SRC),
     .PI_SYNC_IN_DIV_RST     (B_PI_SYNC_IN_DIV_RST),
     .PO_CLKOUT_DIV          (B_PO_CLKOUT_DIV),
     .PO_FINE_DELAY          (B_PO_FINE_DELAY),
     .PO_COARSE_DELAY        (B_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (B_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (B_PO_OCLKDELAY_INV),
     .PO_OUTPUT_CLK_SRC      (B_PO_OUTPUT_CLK_SRC),
     .PO_SYNC_IN_DIV_RST     (B_PO_SYNC_IN_DIV_RST),
     .IDELAYE2_IDELAY_TYPE   (B_IDELAYE2_IDELAY_TYPE),
     .IDELAYE2_IDELAY_VALUE  (B_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP            (IODELAY_GRP)
     )
   byte_lane_B(
      .IO                    ({IO[IO_B_X_START:IO_B_X_END], IO[19:10]}),
      .DQS_P                 (DQS[1]),
      .DQS_N                 (DQS[5]),
      .mem_dq_out            (mem_dq_out[23:12]),
      .mem_dq_ts             (mem_dq_ts[23:12]),
      .mem_dq_in             (mem_dq_in[19:10]),
      .mem_dqs_out           (mem_dqs_out[1]),
      .mem_dqs_ts            (mem_dqs_ts[1]),
      .mem_dqs_in            (mem_dqs_in[1]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .ddr_ck_out            (B_ddr_clk),
      .rclk                  (B_rclk),
      .pi_dqs_found          (B_pi_dqs_found),
      .dqs_out_of_range      (B_pi_dqs_out_of_range),
      .if_a_empty            (B_if_a_empty),
      .if_empty              (B_if_empty),
      .if_a_full             (/*if_a_full*/),
      .if_full               (B_if_full),
      .of_a_empty            (/*of_a_empty*/),
      .of_empty              (B_of_empty),
      .of_a_full             (B_of_a_full),
      .of_full               (B_of_full),
      .phy_din               (phy_din_remap[159:80]),
      .phy_dout              (phy_dout_remap[159:80]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .if_empty_or           (if_empty_or),
      .phaser_ctl_bus        (phaser_ctl_bus),
// calibration signals
      .idelay_inc            (idelay_inc),
      .idelay_ce             (idelay_ce),
      .idelay_ld             (idelay_ld),
      .pi_rst_dqs_find       (pi_rst_dqs_find),
      .po_en_calib           (phy_encalib),
      .po_fine_enable        (B_po_fine_enable),
      .po_coarse_enable      (B_po_coarse_enable),
      .po_fine_inc           (B_po_fine_inc),
      .po_coarse_inc         (B_po_coarse_inc),
      .po_counter_load_en    (B_po_counter_load_en),
      .po_counter_read_en    (B_po_counter_read_en),
      .po_counter_load_val   (B_po_counter_load_val),
      .po_coarse_overflow    (B_po_coarse_overflow),
      .po_fine_overflow      (B_po_fine_overflow),
      .po_counter_read_val   (B_po_counter_read_val),
      .po_sel_fine_oclk_delay(B_po_sel_fine_oclk_delay),
      .pi_en_calib           (phy_encalib),
      .pi_fine_enable        (B_pi_fine_enable),
      .pi_fine_inc           (B_pi_fine_inc),
      .pi_counter_load_en    (B_pi_counter_load_en),
      .pi_counter_read_en    (B_pi_counter_read_en),
      .pi_counter_load_val   (B_pi_counter_load_val),
      .pi_fine_overflow      (B_pi_fine_overflow),
      .pi_counter_read_val   (B_pi_counter_read_val),
      .pi_iserdes_rst        (B_pi_iserdes_rst),
      .pi_phase_locked       (B_pi_phase_locked)
);
end
else begin : no_byte_lane_B
       assign B_of_a_full = 1'b0;
       assign B_of_full = 1'b0;
       assign B_if_empty = 1'b0;
       assign B_if_a_empty = 1'b0;
       assign B_pi_phase_locked = 1;
       assign B_pi_dqs_found     = 1;
       assign B_rclk = 0;
       assign B_pi_counter_read_val = 0;
       assign B_po_counter_read_val = 0;
       assign B_pi_fine_overflow    = 0;
       assign B_po_coarse_overflow = 0;
       assign B_po_fine_overflow   = 0;
       if ( HIGHEST_LANE > 1) begin
          assign IO[19:10]    = 0;
          assign IO[IO_B_X_START:IO_B_X_END]    = 0;
          assign DQS[1] = 1'b0;
          assign DQS[5] = 1'b0;
       end
end

if ( BYTE_LANES[2] ) begin : byte_lane_C

  assign phy_dout_remap[239:160] = part_select_80(phy_dout, (LANE_REMAP[9:8]));
  byte_lane#(
     .ABCD                   ("C"),
     .PO_DATA_CTL            (PC_DATA_CTL_N[2] ? "TRUE" : "FALSE"),
     .BITLANES               (BITLANES[35:24]),
     .BITLANES_OUTONLY       (BITLANES_OUTONLY[35:24]),
     .OF_ALMOST_EMPTY_VALUE  (OF_ALMOST_EMPTY_VALUE),
     .OF_ALMOST_FULL_VALUE   (OF_ALMOST_FULL_VALUE),
     .OF_SYNCHRONOUS_MODE    (OF_SYNCHRONOUS_MODE),
     //.OF_OUTPUT_DISABLE      (OF_OUTPUT_DISABLE),
     //.OF_ARRAY_MODE          (C_OF_ARRAY_MODE),
     //.IF_ARRAY_MODE          (IF_ARRAY_MODE),
     .IF_ALMOST_EMPTY_VALUE  (IF_ALMOST_EMPTY_VALUE),
     .IF_ALMOST_FULL_VALUE   (IF_ALMOST_FULL_VALUE),
     .IF_SYNCHRONOUS_MODE    (IF_SYNCHRONOUS_MODE),
     .DIFFERENTIAL_DQS       (DIFFERENTIAL_DQS),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK),
     .PI_BURST_MODE          (C_PI_BURST_MODE),
     .PI_CLKOUT_DIV          (C_PI_CLKOUT_DIV),
     .PI_FREQ_REF_DIV        (C_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (C_PI_FINE_DELAY),
     .PI_OUTPUT_CLK_SRC      (C_PI_OUTPUT_CLK_SRC),
     .PI_SYNC_IN_DIV_RST     (C_PI_SYNC_IN_DIV_RST),
     .PO_CLKOUT_DIV          (C_PO_CLKOUT_DIV),
     .PO_FINE_DELAY          (C_PO_FINE_DELAY),
     .PO_COARSE_DELAY        (C_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (C_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (C_PO_OCLKDELAY_INV),
     .PO_OUTPUT_CLK_SRC      (C_PO_OUTPUT_CLK_SRC),
     .PO_SYNC_IN_DIV_RST     (C_PO_SYNC_IN_DIV_RST),
     .IDELAYE2_IDELAY_TYPE   (C_IDELAYE2_IDELAY_TYPE),
     .IDELAYE2_IDELAY_VALUE  (C_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP            (IODELAY_GRP)
     )
   byte_lane_C(
      .IO                    ({IO[IO_C_X_START:IO_C_X_END], IO[29:20]}),
      .DQS_P                 (DQS[2]),
      .DQS_N                 (DQS[6]),
      .mem_dq_out            (mem_dq_out[35:24]),
      .mem_dq_ts             (mem_dq_ts[35:24]),
      .mem_dq_in             (mem_dq_in[29:20]),
      .mem_dqs_out           (mem_dqs_out[2]),
      .mem_dqs_ts            (mem_dqs_ts[2]),
      .mem_dqs_in            (mem_dqs_in[2]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .ddr_ck_out            (C_ddr_clk),
      .rclk                  (C_rclk),
      .pi_dqs_found          (C_pi_dqs_found),
      .dqs_out_of_range      (C_pi_dqs_out_of_range),
      .if_a_empty            (C_if_a_empty),
      .if_empty              (C_if_empty),
      .if_a_full             (/*if_a_full*/),
      .if_full               (C_if_full),
      .of_a_empty            (/*of_a_empty*/),
      .of_empty              (C_of_empty),
      .of_a_full             (C_of_a_full),
      .of_full               (C_of_full),
      .phy_din               (phy_din_remap[239:160]),
      .phy_dout              (phy_dout_remap[239:160]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .if_empty_or           (if_empty_or),
      .phaser_ctl_bus        (phaser_ctl_bus),
// calibration signals
      .idelay_inc            (idelay_inc),
      .idelay_ce             (idelay_ce),
      .idelay_ld             (idelay_ld),
      .pi_rst_dqs_find       (pi_rst_dqs_find),
      .po_en_calib           (phy_encalib),
      .po_fine_enable        (C_po_fine_enable),
      .po_coarse_enable      (C_po_coarse_enable),
      .po_fine_inc           (C_po_fine_inc),
      .po_coarse_inc         (C_po_coarse_inc),
      .po_counter_load_en    (C_po_counter_load_en),
      .po_counter_read_en    (C_po_counter_read_en),
      .po_counter_load_val   (C_po_counter_load_val),
      .po_coarse_overflow    (C_po_coarse_overflow),
      .po_fine_overflow      (C_po_fine_overflow),
      .po_counter_read_val   (C_po_counter_read_val),
      .po_sel_fine_oclk_delay(C_po_sel_fine_oclk_delay),
      .pi_en_calib           (phy_encalib),
      .pi_fine_enable        (C_pi_fine_enable),
      .pi_fine_inc           (C_pi_fine_inc),
      .pi_counter_load_en    (C_pi_counter_load_en),
      .pi_counter_read_en    (C_pi_counter_read_en),
      .pi_counter_load_val   (C_pi_counter_load_val),
      .pi_fine_overflow      (C_pi_fine_overflow),
      .pi_counter_read_val   (C_pi_counter_read_val),
      .pi_iserdes_rst        (C_pi_iserdes_rst),
      .pi_phase_locked       (C_pi_phase_locked)
);

end
else begin : no_byte_lane_C
       assign C_of_a_full = 1'b0;
       assign C_of_full = 1'b0;
       assign C_if_empty = 1'b0;
       assign C_if_a_empty = 1'b0;
       assign C_pi_phase_locked = 1;
       assign C_pi_dqs_found      = 1;
       assign C_rclk = 0;
       assign C_pi_counter_read_val = 0;
       assign C_po_counter_read_val = 0;
       assign C_pi_fine_overflow    = 0;
       assign C_po_coarse_overflow = 0;
       assign C_po_fine_overflow   = 0;
       if ( HIGHEST_LANE > 2) begin
          assign IO[29:20]    = 0;
          assign IO[IO_C_X_START:IO_C_X_END]    = 0;
          assign DQS[2] = 1'b0;
          assign DQS[6] = 1'b0;
       end
end

if ( BYTE_LANES[3] ) begin : byte_lane_D
  assign phy_dout_remap[319:240] = part_select_80(phy_dout, (LANE_REMAP[13:12]));

  byte_lane#(
     .ABCD                   ("D"),
     .PO_DATA_CTL            (PC_DATA_CTL_N[3] ? "TRUE" : "FALSE"),
     .BITLANES               (BITLANES[47:36]),
     .BITLANES_OUTONLY       (BITLANES_OUTONLY[47:36]),
     .OF_ALMOST_EMPTY_VALUE  (OF_ALMOST_EMPTY_VALUE),
     .OF_ALMOST_FULL_VALUE   (OF_ALMOST_FULL_VALUE),
     .OF_SYNCHRONOUS_MODE    (OF_SYNCHRONOUS_MODE),
     //.OF_OUTPUT_DISABLE      (OF_OUTPUT_DISABLE),
     //.OF_ARRAY_MODE          (D_OF_ARRAY_MODE),
     //.IF_ARRAY_MODE          (IF_ARRAY_MODE),
     .IF_ALMOST_EMPTY_VALUE  (IF_ALMOST_EMPTY_VALUE),
     .IF_ALMOST_FULL_VALUE   (IF_ALMOST_FULL_VALUE),
     .IF_SYNCHRONOUS_MODE    (IF_SYNCHRONOUS_MODE),
     .DIFFERENTIAL_DQS       (DIFFERENTIAL_DQS),
     .GENERATE_DDR_CK        (GENERATE_DDR_CK),
     .PI_BURST_MODE          (D_PI_BURST_MODE),
     .PI_CLKOUT_DIV          (D_PI_CLKOUT_DIV),
     .PI_FREQ_REF_DIV        (D_PI_FREQ_REF_DIV),
     .PI_FINE_DELAY          (D_PI_FINE_DELAY),
     .PI_OUTPUT_CLK_SRC      (D_PI_OUTPUT_CLK_SRC),
     .PI_SYNC_IN_DIV_RST     (D_PI_SYNC_IN_DIV_RST),
     .PO_CLKOUT_DIV          (D_PO_CLKOUT_DIV),
     .PO_FINE_DELAY          (D_PO_FINE_DELAY),
     .PO_COARSE_DELAY        (D_PO_COARSE_DELAY),
     .PO_OCLK_DELAY          (D_PO_OCLK_DELAY),
     .PO_OCLKDELAY_INV       (D_PO_OCLKDELAY_INV),
     .PO_OUTPUT_CLK_SRC      (D_PO_OUTPUT_CLK_SRC),
     .PO_SYNC_IN_DIV_RST     (D_PO_SYNC_IN_DIV_RST),
     .IDELAYE2_IDELAY_TYPE   (D_IDELAYE2_IDELAY_TYPE),
     .IDELAYE2_IDELAY_VALUE  (D_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP            (IODELAY_GRP)
     )
   byte_lane_D(
      .IO                    ({IO[IO_D_X_START:IO_D_X_END], IO[39:30]}),
      .DQS_P                 (DQS[3]),
      .DQS_N                 (DQS[7]),
      .mem_dq_out            (mem_dq_out[47:36]),
      .mem_dq_ts             (mem_dq_ts[47:36]),
      .mem_dq_in             (mem_dq_in[39:30]),
      .mem_dqs_out           (mem_dqs_out[3]),
      .mem_dqs_ts            (mem_dqs_ts[3]),
      .mem_dqs_in            (mem_dqs_in[3]),
      .rst                   (rst),
      .phy_clk               (phy_clk),
      .freq_refclk           (freq_refclk),
      .mem_refclk            (mem_refclk),
      .sync_pulse            (sync_pulse),
      .ddr_ck_out            (D_ddr_clk),
      .rclk                  (D_rclk),
      .pi_dqs_found          (D_pi_dqs_found),
      .dqs_out_of_range      (D_pi_dqs_out_of_range),
      .if_a_empty            (D_if_a_empty),
      .if_empty              (D_if_empty),
      .if_a_full             (/*if_a_full*/),
      .if_full               (D_if_full),
      .of_a_empty            (/*of_a_empty*/),
      .of_empty              (D_of_empty),
      .of_a_full             (D_of_a_full),
      .of_full               (D_of_full),
      .phy_din               (phy_din_remap[319:240]),
      .phy_dout              (phy_dout_remap[319:240]),
      .phy_cmd_wr_en         (phy_cmd_wr_en),
      .phy_data_wr_en        (phy_data_wr_en),
      .if_empty_or           (if_empty_or),
      .phaser_ctl_bus        (phaser_ctl_bus),
      .idelay_inc            (idelay_inc),
      .idelay_ce             (idelay_ce),
      .idelay_ld             (idelay_ld),
// calibration signals
      .pi_rst_dqs_find       (pi_rst_dqs_find),
      .po_en_calib           (phy_encalib),
      .po_fine_enable        (D_po_fine_enable),
      .po_coarse_enable      (D_po_coarse_enable),
      .po_fine_inc           (D_po_fine_inc),
      .po_coarse_inc         (D_po_coarse_inc),
      .po_counter_load_en    (D_po_counter_load_en),
      .po_counter_read_en    (D_po_counter_read_en),
      .po_counter_load_val   (D_po_counter_load_val),
      .po_coarse_overflow    (D_po_coarse_overflow),
      .po_fine_overflow      (D_po_fine_overflow),
      .po_counter_read_val   (D_po_counter_read_val),
      .po_sel_fine_oclk_delay(D_po_sel_fine_oclk_delay),
      .pi_en_calib           (phy_encalib),
      .pi_fine_enable        (D_pi_fine_enable),
      .pi_fine_inc           (D_pi_fine_inc),
      .pi_counter_load_en    (D_pi_counter_load_en),
      .pi_counter_read_en    (D_pi_counter_read_en),
      .pi_counter_load_val   (D_pi_counter_load_val),
      .pi_fine_overflow      (D_pi_fine_overflow),
      .pi_counter_read_val   (D_pi_counter_read_val),
      .pi_iserdes_rst        (D_pi_iserdes_rst),
      .pi_phase_locked       (D_pi_phase_locked)
);
end
else begin : no_byte_lane_D
       assign D_of_a_full = 1'b0;
       assign D_of_full = 1'b0;
       assign D_if_empty = 1'b0;
       assign D_if_a_empty = 1'b0;
       assign D_rclk = 0;
       assign D_pi_dqs_found      = 1;
       assign D_pi_phase_locked   = 1;
       assign D_pi_counter_read_val = 0;
       assign D_po_counter_read_val = 0;
       assign D_pi_fine_overflow    = 0;
       assign D_po_coarse_overflow  = 0;
       assign D_po_fine_overflow   = 0;
       if ( HIGHEST_LANE > 3) begin
          assign IO[39:30]    = 0;
          assign IO[IO_D_X_START:IO_D_X_END]    = 0;
          assign DQS[3] = 1'b0;
          assign DQS[7] = 1'b0;
       end
end
endgenerate


assign phaser_ctl_bus[MSB_RANK_SEL_I : MSB_RANK_SEL_I - 7] = in_rank;

PHY_CONTROL #(
  .AO_WRLVL_EN          ( PC_AO_WRLVL_EN),
  .AO_TOGGLE            ( PC_AO_TOGGLE),
  .BURST_MODE           ( PC_BURST_MODE),
  .CO_DURATION          ( PC_CO_DURATION ),
  .CLK_RATIO            ( PC_CLK_RATIO),
  .DATA_CTL_A_N         ( PC_DATA_CTL_A),
  .DATA_CTL_B_N         ( PC_DATA_CTL_B),
  .DATA_CTL_C_N         ( PC_DATA_CTL_C),
  .DATA_CTL_D_N         ( PC_DATA_CTL_D),
  .DI_DURATION          ( PC_DI_DURATION ),
  .DO_DURATION          ( PC_DO_DURATION ),
  .EVENTS_DELAY         ( PC_EVENTS_DELAY),
  .FOUR_WINDOW_CLOCKS   ( PC_FOUR_WINDOW_CLOCKS),
  .PHY_COUNT_ENABLE     ( PC_PHY_COUNT_EN),
  .DISABLE_SEQ_MATCH    ( PC_DISABLE_SEQ_MATCH),
  .SYNC_MODE            ( PC_SYNC_MODE),
  .CMD_OFFSET           ( PC_CMD_OFFSET),

  .RD_CMD_OFFSET_0      ( PC_RD_CMD_OFFSET_0),
  .RD_CMD_OFFSET_1      ( PC_RD_CMD_OFFSET_1),
  .RD_CMD_OFFSET_2      ( PC_RD_CMD_OFFSET_2),
  .RD_CMD_OFFSET_3      ( PC_RD_CMD_OFFSET_3),
  .RD_DURATION_0        ( PC_RD_DURATION_0),
  .RD_DURATION_1        ( PC_RD_DURATION_1),
  .RD_DURATION_2        ( PC_RD_DURATION_2),
  .RD_DURATION_3        ( PC_RD_DURATION_3),
  .WR_CMD_OFFSET_0      ( PC_WR_CMD_OFFSET_0),
  .WR_CMD_OFFSET_1      ( PC_WR_CMD_OFFSET_1),
  .WR_CMD_OFFSET_2      ( PC_WR_CMD_OFFSET_2),
  .WR_CMD_OFFSET_3      ( PC_WR_CMD_OFFSET_3),
  .WR_DURATION_0        ( PC_WR_DURATION_0),
  .WR_DURATION_1        ( PC_WR_DURATION_1),
  .WR_DURATION_2        ( PC_WR_DURATION_2),
  .WR_DURATION_3        ( PC_WR_DURATION_3)
) phy_control_i (
  .AUXOUTPUT            (aux_out),
  .INBURSTPENDING       (phaser_ctl_bus[MSB_BURST_PEND_PI:MSB_BURST_PEND_PI-3]),
  .INRANKA              (in_rank[1:0]),
  .INRANKB              (in_rank[3:2]),
  .INRANKC              (in_rank[5:4]),
  .INRANKD              (in_rank[7:6]),
  .OUTBURSTPENDING      (phaser_ctl_bus[MSB_BURST_PEND_PO:MSB_BURST_PEND_PO-3]),
  .PCENABLECALIB        (phy_encalib),
  .PHYCTLALMOSTFULL     (phy_ctl_a_full),
  .PHYCTLFULL           (phy_ctl_full),
  .PHYCTLREADY          (phy_ctl_ready),
  .MEMREFCLK            (mem_refclk),
  .PHYCLK               (phy_ctl_clk),
  .PHYCTLWD             (phy_ctl_wd),
  .PHYCTLWRENABLE       (phy_ctl_wr),
  .PLLLOCK              (pll_lock),
  .REFDLLLOCK           (ref_dll_lock),
  .RESET                (rst),
  .SYNCIN               (sync_pulse),
  .READCALIBENABLE      (phy_read_calib),
  .WRITECALIBENABLE     (phy_write_calib)
);


// register oututs to give extra slack in timing
always @(posedge phy_clk) begin
    case (calib_sel[1:0]) 
    2'h0: begin
       // TEMP: condition on whether this byte lane is
       // control/addr or data. If control/address, then
       // hardcode these outputs, and allow SYN/PAR to 
       // trim out the PHASER_IN in this byte lane
       if (! PRESENT_DATA_A) begin
          po_coarse_overflow <= #1 1'b0;
          po_fine_overflow <= #1 1'b0;
          po_counter_read_val <= #1 9'b0;

          pi_fine_overflow <= #1 1'b0;
          pi_counter_read_val<= #1 6'b0;

          pi_phase_locked  <= #1 1'b0;
          pi_dqs_found     <= #1 1'b0;
          pi_dqs_out_of_range <= #1 1'b0;
       end
       else begin
          po_coarse_overflow <= #1 A_po_coarse_overflow;
          po_fine_overflow <= #1 A_po_fine_overflow;
          po_counter_read_val <= #1 A_po_counter_read_val;

          pi_fine_overflow <= #1 A_pi_fine_overflow;
          pi_counter_read_val<= #1 A_pi_counter_read_val;

          pi_phase_locked  <= #1 A_pi_phase_locked;
       if ( calib_in_common)
           pi_dqs_found     <= #1 pi_dqs_found_any;
       else
          pi_dqs_found     <= #1 A_pi_dqs_found;
          pi_dqs_out_of_range <= #1 A_pi_dqs_out_of_range;
       end
      end
      
    2'h1: begin
       if (! PRESENT_DATA_B) begin
          po_coarse_overflow <= #1 1'b0;
          po_fine_overflow <= #1 1'b0;
          po_counter_read_val <= #1 9'b0;

          pi_fine_overflow <= #1 1'b0;
          pi_counter_read_val<= #1 6'b0;

          pi_phase_locked  <= #1 1'b0;
          pi_dqs_found     <= #1 1'b0;
          pi_dqs_out_of_range <= #1 1'b0;
       end
       else begin
         po_coarse_overflow     <= #1 B_po_coarse_overflow;
         po_fine_overflow       <= #1 B_po_fine_overflow;
         po_counter_read_val    <= #1 B_po_counter_read_val;

         pi_fine_overflow       <= #1 B_pi_fine_overflow;
         pi_counter_read_val    <= #1 B_pi_counter_read_val;

         pi_phase_locked        <= #1 B_pi_phase_locked;
       if ( calib_in_common)
          pi_dqs_found           <= #1 pi_dqs_found_any;
       else
         pi_dqs_found           <= #1 B_pi_dqs_found;
         pi_dqs_out_of_range    <= #1 B_pi_dqs_out_of_range;
       end
      end
      
    2'h2: begin
       if (! PRESENT_DATA_C) begin
          po_coarse_overflow <= #1 1'b0;
          po_fine_overflow <= #1 1'b0;
          po_counter_read_val <= #1 9'b0;

          pi_fine_overflow <= #1 1'b0;
          pi_counter_read_val<= #1 6'b0;

          pi_phase_locked  <= #1 1'b0;
          pi_dqs_found     <= #1 1'b0;
          pi_dqs_out_of_range <= #1 1'b0;
       end
       else begin
          po_coarse_overflow     <= #1 C_po_coarse_overflow;
          po_fine_overflow       <= #1 C_po_fine_overflow;
          po_counter_read_val    <= #1 C_po_counter_read_val;

          pi_fine_overflow       <= #1 C_pi_fine_overflow;
          pi_counter_read_val    <= #1 C_pi_counter_read_val;

          pi_phase_locked        <= #1 C_pi_phase_locked;
       if ( calib_in_common)
           pi_dqs_found           <= #1 pi_dqs_found_any;
       else
          pi_dqs_found           <= #1 C_pi_dqs_found;
          pi_dqs_out_of_range    <= #1 C_pi_dqs_out_of_range;
       end
      end
      
    2'h3: begin
       if (! PRESENT_DATA_D) begin
          po_coarse_overflow <= #1 1'b0;
          po_fine_overflow <= #1 1'b0;
          po_counter_read_val <= #1 9'b0;

          pi_fine_overflow <= #1 1'b0;
          pi_counter_read_val<= #1 6'b0;

          pi_phase_locked  <= #1 1'b0;
          pi_dqs_found     <= #1 1'b0;
          pi_dqs_out_of_range <= #1 1'b0;
       end
       else begin
          po_coarse_overflow     <= #1 D_po_coarse_overflow;
          po_fine_overflow       <= #1 D_po_fine_overflow;
          po_counter_read_val    <= #1 D_po_counter_read_val;

          pi_fine_overflow       <= #1 D_pi_fine_overflow;
          pi_counter_read_val    <= #1 D_pi_counter_read_val;

          pi_phase_locked        <= #1 D_pi_phase_locked;
       if ( calib_in_common)
          pi_dqs_found           <= #1 pi_dqs_found_any;
       else
          pi_dqs_found           <= #1 D_pi_dqs_found;
          pi_dqs_out_of_range    <= #1 D_pi_dqs_out_of_range;
       end
      end
     default: begin 
        po_coarse_overflow <= po_coarse_overflow;
     end
    endcase
end

always @(*) begin
        A_pi_fine_enable          = 0;
        A_pi_fine_inc             = 0;
        A_pi_counter_load_en      = 0;
        A_pi_counter_read_en      = 0;
        A_pi_counter_load_val     = 0;


        A_po_fine_enable          = 0;
        A_po_coarse_enable        = 0;
        A_po_fine_inc             = 0;
        A_po_coarse_inc           = 0;
        A_po_counter_load_en      = 0;
        A_po_counter_read_en      = 0;
        A_po_counter_load_val     = 0;
        A_po_sel_fine_oclk_delay  = 0;


        B_pi_fine_enable          = 0;
        B_pi_fine_inc   = 0;
        B_pi_counter_load_en      = 0;
        B_pi_counter_read_en      = 0;
        B_pi_counter_load_val     = 0;


        B_po_fine_enable          = 0;
        B_po_coarse_enable        = 0;
        B_po_fine_inc             = 0;
        B_po_coarse_inc           = 0;
        B_po_counter_load_en      = 0;
        B_po_counter_read_en      = 0;
        B_po_counter_load_val     = 0;
        B_po_sel_fine_oclk_delay  = 0;

        C_pi_fine_enable    = 0;
        C_pi_fine_inc   = 0;
        C_pi_counter_load_en      = 0;
        C_pi_counter_read_en      = 0;
        C_pi_counter_load_val     = 0;


        C_po_fine_enable          = 0;
        C_po_coarse_enable        = 0;
        C_po_fine_inc             = 0;
        C_po_coarse_inc           = 0;
        C_po_counter_load_en      = 0;
        C_po_counter_read_en      = 0;
        C_po_counter_load_val     = 0;
        C_po_sel_fine_oclk_delay  = 0;


        D_pi_fine_enable          = 0;
        D_pi_fine_inc             = 0;
        D_pi_counter_load_en      = 0;
        D_pi_counter_read_en      = 0;
        D_pi_counter_load_val     = 0;


        D_po_fine_enable          = 0;
        D_po_coarse_enable        = 0;
        D_po_fine_inc             = 0;
        D_po_coarse_inc           = 0;
        D_po_counter_load_en      = 0;
        D_po_counter_read_en      = 0;
        D_po_counter_load_val     = 0;
        D_po_sel_fine_oclk_delay  = 0;
    if ( calib_sel[2]) begin
    // if this is asserted, all calib signals are deasserted
        A_pi_fine_enable     = 0;
        A_pi_fine_inc        = 0;
        A_pi_counter_load_en = 0;
        A_pi_counter_read_en = 0;
        A_pi_counter_load_val = 0;


        A_po_fine_enable     = 0;
        A_po_coarse_enable   = 0;
        A_po_fine_inc        = 0;
        A_po_coarse_inc      = 0;
        A_po_counter_load_en = 0;
        A_po_counter_read_en = 0;
        A_po_counter_load_val = 0;


        B_pi_fine_enable     = 0;
        B_pi_fine_inc        = 0;
        B_pi_counter_load_en = 0;
        B_pi_counter_read_en = 0;
        B_pi_counter_load_val = 0;


        B_po_fine_enable     = 0;
        B_po_coarse_enable   = 0;
        B_po_fine_inc        = 0;
        B_po_coarse_inc      = 0;
        B_po_counter_load_en = 0;
        B_po_counter_read_en = 0;
        B_po_counter_load_val=  0;


        C_pi_fine_enable     = 0;
        C_pi_fine_inc        = 0;
        C_pi_counter_load_en = 0;
        C_pi_counter_read_en = 0;
        C_pi_counter_load_val = 0;


        C_po_fine_enable     = 0;
        C_po_coarse_enable   = 0;
        C_po_fine_inc        = 0;
        C_po_coarse_inc      = 0;
        C_po_counter_load_en = 0;
        C_po_counter_read_en = 0;
        C_po_counter_load_val= 0;


        D_pi_fine_enable     = 0;
        D_pi_fine_inc        = 0;
        D_pi_counter_load_en = 0;
        D_pi_counter_read_en = 0;
        D_pi_counter_load_val= 0;


        D_po_fine_enable     = 0;
        D_po_coarse_enable   = 0;
        D_po_fine_inc        = 0;
        D_po_coarse_inc      = 0;
        D_po_counter_load_en = 0;
        D_po_counter_read_en = 0;
        D_po_counter_load_val = 0;

    end else
    if (calib_in_common) begin
       // if this is asserted, each signal is broadcast  to all phasers
       // in common
        A_pi_fine_enable          = pi_fine_enable;
        A_pi_fine_inc             = pi_fine_inc;
        A_pi_counter_load_en      = pi_counter_load_en;
        A_pi_counter_read_en      = pi_counter_read_en;
        A_pi_counter_load_val     = pi_counter_load_val;


        A_po_fine_enable          = po_fine_enable;
        A_po_coarse_enable        = po_coarse_enable;
        A_po_fine_inc             = po_fine_inc;
        A_po_coarse_inc           = po_coarse_inc;
        A_po_counter_load_en      = po_counter_load_en;
        A_po_counter_read_en      = po_counter_read_en;
        A_po_counter_load_val     = po_counter_load_val;
        A_po_sel_fine_oclk_delay  = po_sel_fine_oclk_delay;

        B_pi_fine_enable          = pi_fine_enable;
        B_pi_fine_inc             = pi_fine_inc;
        B_pi_counter_load_en      = pi_counter_load_en;
        B_pi_counter_read_en      = pi_counter_read_en;
        B_pi_counter_load_val     = pi_counter_load_val;


        B_po_fine_enable          = po_fine_enable;
        B_po_coarse_enable        = po_coarse_enable;
        B_po_fine_inc             = po_fine_inc;
        B_po_coarse_inc           = po_coarse_inc;
        B_po_counter_load_en      = po_counter_load_en;
        B_po_counter_read_en      = po_counter_read_en;
        B_po_counter_load_val     = po_counter_load_val;
        B_po_sel_fine_oclk_delay  = po_sel_fine_oclk_delay;

        C_pi_fine_enable          = pi_fine_enable;
        C_pi_fine_inc             = pi_fine_inc;
        C_pi_counter_load_en      = pi_counter_load_en;
        C_pi_counter_read_en      = pi_counter_read_en;
        C_pi_counter_load_val     = pi_counter_load_val;


        C_po_fine_enable          = po_fine_enable;
        C_po_coarse_enable        = po_coarse_enable;
        C_po_fine_inc             = po_fine_inc;
        C_po_coarse_inc           = po_coarse_inc;
        C_po_counter_load_en      = po_counter_load_en;
        C_po_counter_read_en      = po_counter_read_en;
        C_po_counter_load_val     = po_counter_load_val;
        C_po_sel_fine_oclk_delay  = po_sel_fine_oclk_delay;

        D_pi_fine_enable          = pi_fine_enable;
        D_pi_fine_inc             = pi_fine_inc;
        D_pi_counter_load_en      = pi_counter_load_en;
        D_pi_counter_read_en      = pi_counter_read_en;
        D_pi_counter_load_val     = pi_counter_load_val;


        D_po_fine_enable          = po_fine_enable;
        D_po_coarse_enable        = po_coarse_enable;
        D_po_fine_inc             = po_fine_inc;
        D_po_coarse_inc           = po_coarse_inc;
        D_po_counter_load_en      = po_counter_load_en;
        D_po_counter_load_val     = po_counter_load_val;
        D_po_sel_fine_oclk_delay  = po_sel_fine_oclk_delay;
    end
    else begin
    // otherwise, only a single phaser is selected


    case (calib_sel[1:0])
    0:  begin
        A_pi_fine_enable          = pi_fine_enable;
        A_pi_fine_inc             = pi_fine_inc;
        A_pi_counter_load_en      = pi_counter_load_en;
        A_pi_counter_read_en      = pi_counter_read_en;
        A_pi_counter_load_val     = pi_counter_load_val;


        A_po_fine_enable          = po_fine_enable;
        A_po_coarse_enable        = po_coarse_enable;
        A_po_fine_inc             = po_fine_inc;
        A_po_coarse_inc           = po_coarse_inc;
        A_po_counter_load_en      = po_counter_load_en;
        A_po_counter_read_en      = po_counter_read_en;
        A_po_counter_load_val     = po_counter_load_val;

     end
    1: begin
        B_pi_fine_enable          = pi_fine_enable;
        B_pi_fine_inc             = pi_fine_inc;
        B_pi_counter_load_en      = pi_counter_load_en;
        B_pi_counter_read_en      = pi_counter_read_en;
        B_pi_counter_load_val     = pi_counter_load_val;


        B_po_fine_enable          = po_fine_enable;
        B_po_coarse_enable        = po_coarse_enable;
        B_po_fine_inc             = po_fine_inc;
        B_po_coarse_inc           = po_coarse_inc;
        B_po_counter_load_en      = po_counter_load_en;
        B_po_counter_read_en      = po_counter_read_en;
        B_po_counter_load_val     = po_counter_load_val;

     end

    2: begin
        C_pi_fine_enable          = pi_fine_enable;
        C_pi_fine_inc             = pi_fine_inc;
        C_pi_counter_load_en      = pi_counter_load_en;
        C_pi_counter_read_en      = pi_counter_read_en;
        C_pi_counter_load_val     = pi_counter_load_val;


        C_po_fine_enable          = po_fine_enable;
        C_po_coarse_enable        = po_coarse_enable;
        C_po_fine_inc             = po_fine_inc;
        C_po_coarse_inc           = po_coarse_inc;
        C_po_counter_load_en      = po_counter_load_en;
        C_po_counter_read_en      = po_counter_read_en;
        C_po_counter_load_val     = po_counter_load_val;

     end

    3: begin
        D_pi_fine_enable          = pi_fine_enable;
        D_pi_fine_inc             = pi_fine_inc;
        D_pi_counter_load_en      = pi_counter_load_en;
        D_pi_counter_read_en      = pi_counter_read_en;
        D_pi_counter_load_val     = pi_counter_load_val;


        D_po_fine_enable          = po_fine_enable;
        D_po_coarse_enable        = po_coarse_enable;
        D_po_fine_inc             = po_fine_inc;
        D_po_coarse_inc           = po_coarse_inc;
        D_po_counter_load_en      = po_counter_load_en;
        D_po_counter_load_val     = po_counter_load_val;
        D_po_counter_read_en      = po_counter_read_en;

     end
    endcase
    end
end

//obligatory phaser-ref
PHASER_REF phaser_ref_i(

 .LOCKED (ref_dll_lock),
 .CLKIN  (freq_refclk),
 .PWRDWN (1'b0),
 .RST    (rst)

);


endmodule
