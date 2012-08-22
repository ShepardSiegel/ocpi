/***********************************************************
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
-- Applications"). A Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

//
//
//  Owner:        Gary Martin
//  Revision:     $Id: mc_phy.v,v 1.10.10.3 2011/05/30 10:45:54 pboya Exp $
//                $Author: pboya $
//                $DateTime: 2010/05/11 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is a parameterizable wrapper instantiating
//    up to 5 memory banks of 4-lane phy primitives. There
//    There are always 2 control banks leaving 18 lanes for data.
//
//  History:
//  Date        Engineer    Description
//  04/01/2010  G. Martin   Initial Checkin.
//
////////////////////////////////////////////////////////////
***********************************************************/

`timescale 1ps/1ps

//`include "phy.vh"

`define PC_OFFSET_RANGE 22:17

module mc_phy
 #(
// five fields, one per possible I/O bank, 4 bits in each field, 1 per lane data=1/ctl=0
      parameter        BYTE_LANES_B0           = 4'b1111,
      parameter        BYTE_LANES_B1           = 4'b0000,
      parameter        BYTE_LANES_B2           = 4'b0000,
      parameter        BYTE_LANES_B3           = 4'b0000,
      parameter        BYTE_LANES_B4           = 4'b0000,
      parameter        DATA_CTL_B0             = 4'hc,
      parameter        DATA_CTL_B1             = 4'hf,
      parameter        DATA_CTL_B2             = 4'hf,
      parameter        DATA_CTL_B3             = 4'hf,
      parameter        DATA_CTL_B4             = 4'hf,
      parameter        PHY_0_BITLANES          = 48'hdffd_fffe_dfff,
      parameter        PHY_1_BITLANES          = PHY_0_BITLANES,
      parameter        PHY_2_BITLANES          = PHY_0_BITLANES,
      parameter        PHY_0_BITLANES_OUTONLY  = 48'h0000_0000_0000,
      parameter        PHY_1_BITLANES_OUTONLY  = PHY_0_BITLANES_OUTONLY,
      parameter        PHY_2_BITLANES_OUTONLY  = PHY_0_BITLANES_OUTONLY,
      parameter        RCLK_SELECT_BANK        = 0,
      parameter        RCLK_SELECT_LANE        = "B",
//      parameter        RCLK_SELECT_EDGE        = 3'b111,
      parameter        DDR_CLK_SELECT_BANK     = 0,
      parameter        PO_CTL_COARSE_BYPASS    = "FALSE",

      parameter        PHYCTL_CMD_FIFO         = "FALSE",
      parameter        PHY_CLK_RATIO           = 4,          // phy to controller divide ratio

// common to all i/o banks
      parameter        PHY_FOUR_WINDOW_CLOCKS  = 63,
      parameter        PHY_EVENTS_DELAY        = 18,
      parameter        PHY_COUNT_EN            = "TRUE",
      parameter        PHY_SYNC_MODE           = "TRUE",
      parameter        PHY_DISABLE_SEQ_MATCH   = "FALSE",
// common to instance 0
      parameter        PHY_0_LANE_REMAP        = 16'h3210,
      parameter        PHY_0_GENERATE_IDELAYCTRL =  "FALSE",
      parameter        PHY_0_GENERATE_DDR_CK   =  "B",
      parameter        PHY_0_NUM_DDR_CK        =  1,
      parameter        PHY_0_DIFFERENTIAL_DQS  =  "TRUE",
      parameter        PHY_0_DATA_CTL          = DATA_CTL_B0,
      parameter        PHY_0_CMD_OFFSET        = 0,
      parameter        PHY_0_RD_CMD_OFFSET_0   = 0,
      parameter        PHY_0_RD_CMD_OFFSET_1   = 0,
      parameter        PHY_0_RD_CMD_OFFSET_2   = 0,
      parameter        PHY_0_RD_CMD_OFFSET_3   = 0,
      parameter        PHY_0_RD_DURATION_0     = 0,
      parameter        PHY_0_RD_DURATION_1     = 0,
      parameter        PHY_0_RD_DURATION_2     = 0,
      parameter        PHY_0_RD_DURATION_3     = 0,
      parameter        PHY_0_WR_CMD_OFFSET_0   = 0,
      parameter        PHY_0_WR_CMD_OFFSET_1   = 0,
      parameter        PHY_0_WR_CMD_OFFSET_2   = 0,
      parameter        PHY_0_WR_CMD_OFFSET_3   = 0,
      parameter        PHY_0_WR_DURATION_0     = 0,
      parameter        PHY_0_WR_DURATION_1     = 0,
      parameter        PHY_0_WR_DURATION_2     = 0,
      parameter        PHY_0_WR_DURATION_3     = 0,
      parameter        PHY_0_AO_WRLVL_EN       = 0,
      parameter        PHY_0_AO_TOGGLE         = 4'b0101, // odd bits are toggle (CKE)
// per lane parameters
      parameter        PHY_0_A_PI_FREQ_REF_DIV = "NONE",
      parameter        PHY_0_A_PI_CLKOUT_DIV   = 2,
      parameter        PHY_0_A_PO_CLKOUT_DIV   = 2,
      parameter        PHY_0_A_BURST_MODE   =  "TRUE",
      parameter        PHY_0_A_PI_OUTPUT_CLK_SRC  = "DELAYED_REF",
      parameter        PHY_0_A_PO_OUTPUT_CLK_SRC  = "DELAYED_REF",
      parameter        PHY_0_PO_FINE_DELAY           = "UNDECLARED",
      parameter        PHY_0_A_PO_OCLK_DELAY         = 0,
      parameter        PHY_0_B_PO_OCLK_DELAY         = PHY_0_A_PO_OCLK_DELAY,
      parameter        PHY_0_C_PO_OCLK_DELAY         = PHY_0_A_PO_OCLK_DELAY,
      parameter        PHY_0_D_PO_OCLK_DELAY         = PHY_0_A_PO_OCLK_DELAY,
      parameter        PHY_0_A_PO_OCLKDELAY_INV  = "FALSE",
      parameter        PHY_0_A_OF_ARRAY_MODE         = "ARRAY_MODE_8_X_4",
      parameter        PHY_0_B_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_C_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_D_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_A_IF_ARRAY_MODE         = "ARRAY_MODE_8_X_4",
      parameter        PHY_0_B_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_C_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_D_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_A_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_B_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_C_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_D_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_A_IF_ARRAY_MODE         = PHY_0_A_IF_ARRAY_MODE,
      parameter        PHY_1_B_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_C_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_1_D_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_A_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_B_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_C_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_D_OF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_A_IF_ARRAY_MODE         = PHY_0_A_IF_ARRAY_MODE,
      parameter        PHY_2_B_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_C_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_2_D_IF_ARRAY_MODE         = PHY_0_A_OF_ARRAY_MODE,
      parameter        PHY_0_A_OSERDES_DATA_RATE     = "UNDECLARED",
      parameter        PHY_0_A_OSERDES_DATA_WIDTH    = "UNDECLARED",
      parameter        PHY_0_B_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_0_B_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_0_C_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_0_C_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_0_D_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_0_D_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_1_A_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_1_A_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_1_B_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_1_B_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_1_C_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_1_C_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_1_D_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_1_D_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_2_A_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_2_A_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_2_B_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_2_B_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_2_C_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_2_C_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_2_D_OSERDES_DATA_RATE     = PHY_0_A_OSERDES_DATA_RATE,
      parameter        PHY_2_D_OSERDES_DATA_WIDTH    = PHY_0_A_OSERDES_DATA_WIDTH,
      parameter        PHY_0_OF_ALMOST_FULL_VALUE = 1,
      parameter        PHY_0_A_IDELAYE2_IDELAY_TYPE  = "VARIABLE",
      parameter        PHY_0_A_IDELAYE2_IDELAY_VALUE = 00,
      parameter        PHY_0_B_IDELAYE2_IDELAY_TYPE  = PHY_0_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_0_B_IDELAYE2_IDELAY_VALUE = PHY_0_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_0_C_IDELAYE2_IDELAY_TYPE  = PHY_0_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_0_C_IDELAYE2_IDELAY_VALUE = PHY_0_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_0_D_IDELAYE2_IDELAY_TYPE  = PHY_0_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_0_D_IDELAYE2_IDELAY_VALUE = PHY_0_A_IDELAYE2_IDELAY_VALUE,
      
// common to instance 1
      parameter        PHY_1_LANE_REMAP        = 16'h3210,
      parameter        PHY_1_GENERATE_IDELAYCTRL =  "FALSE",
      parameter        PHY_1_GENERATE_DDR_CK   = PHY_0_GENERATE_DDR_CK,
      parameter        PHY_1_NUM_DDR_CK        =  PHY_0_NUM_DDR_CK,
      parameter        PHY_1_DIFFERENTIAL_DQS  = PHY_0_DIFFERENTIAL_DQS,
      parameter        PHY_1_DATA_CTL          = DATA_CTL_B1,
      parameter        PHY_1_CMD_OFFSET        = PHY_0_CMD_OFFSET,
      parameter        PHY_1_RD_CMD_OFFSET_0   = PHY_0_RD_CMD_OFFSET_0,
      parameter        PHY_1_RD_CMD_OFFSET_1   = PHY_0_RD_CMD_OFFSET_1,
      parameter        PHY_1_RD_CMD_OFFSET_2   = PHY_0_RD_CMD_OFFSET_2,
      parameter        PHY_1_RD_CMD_OFFSET_3   = PHY_0_RD_CMD_OFFSET_3,
      parameter        PHY_1_RD_DURATION_0     = PHY_0_RD_DURATION_0,
      parameter        PHY_1_RD_DURATION_1     = PHY_0_RD_DURATION_1,
      parameter        PHY_1_RD_DURATION_2     = PHY_0_RD_DURATION_2,
      parameter        PHY_1_RD_DURATION_3     = PHY_0_RD_DURATION_3,
      parameter        PHY_1_WR_CMD_OFFSET_0   = PHY_0_WR_CMD_OFFSET_0,
      parameter        PHY_1_WR_CMD_OFFSET_1   = PHY_0_WR_CMD_OFFSET_1,
      parameter        PHY_1_WR_CMD_OFFSET_2   = PHY_0_WR_CMD_OFFSET_2,
      parameter        PHY_1_WR_CMD_OFFSET_3   = PHY_0_WR_CMD_OFFSET_3,
      parameter        PHY_1_WR_DURATION_0     = PHY_0_WR_DURATION_0,
      parameter        PHY_1_WR_DURATION_1     = PHY_0_WR_DURATION_1,
      parameter        PHY_1_WR_DURATION_2     = PHY_0_WR_DURATION_2,
      parameter        PHY_1_WR_DURATION_3     = PHY_0_WR_DURATION_3,
      parameter        PHY_1_AO_WRLVL_EN       = PHY_0_AO_WRLVL_EN,
      parameter        PHY_1_AO_TOGGLE         = PHY_0_AO_TOGGLE, // odd bits are toggle (CKE)
      // per lane parameters
      parameter        PHY_1_A_PI_FREQ_REF_DIV = PHY_0_A_PI_FREQ_REF_DIV,
      parameter        PHY_1_A_PI_CLKOUT_DIV   = PHY_0_A_PI_CLKOUT_DIV,
      parameter        PHY_1_A_PO_CLKOUT_DIV   = PHY_0_A_PO_CLKOUT_DIV,
      parameter        PHY_1_A_BURST_MODE      = PHY_0_A_BURST_MODE,
      parameter        PHY_1_A_PI_OUTPUT_CLK_SRC  = PHY_0_A_PI_OUTPUT_CLK_SRC,
      parameter        PHY_1_A_PO_OUTPUT_CLK_SRC  = PHY_0_A_PO_OUTPUT_CLK_SRC ,
      parameter        PHY_1_PO_FINE_DELAY     = PHY_0_PO_FINE_DELAY,
      parameter        PHY_1_A_PO_OCLK_DELAY   = PHY_0_A_PO_OCLK_DELAY,
      parameter        PHY_1_B_PO_OCLK_DELAY   = PHY_1_A_PO_OCLK_DELAY,
      parameter        PHY_1_C_PO_OCLK_DELAY   = PHY_1_A_PO_OCLK_DELAY,
      parameter        PHY_1_D_PO_OCLK_DELAY   = PHY_1_A_PO_OCLK_DELAY,
      parameter        PHY_1_A_PO_OCLKDELAY_INV   = PHY_0_A_PO_OCLKDELAY_INV,
      parameter        PHY_1_OF_ALMOST_FULL_VALUE = 1,
      parameter        PHY_1_A_IDELAYE2_IDELAY_TYPE  = PHY_0_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_1_A_IDELAYE2_IDELAY_VALUE = PHY_0_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_1_B_IDELAYE2_IDELAY_TYPE  = PHY_1_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_1_B_IDELAYE2_IDELAY_VALUE = PHY_1_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_1_C_IDELAYE2_IDELAY_TYPE  = PHY_1_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_1_C_IDELAYE2_IDELAY_VALUE = PHY_1_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_1_D_IDELAYE2_IDELAY_TYPE  = PHY_1_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_1_D_IDELAYE2_IDELAY_VALUE = PHY_1_A_IDELAYE2_IDELAY_VALUE,
      parameter        IODELAY_GRP = "IODELAY_MIG",

// common to instance 2
      parameter        PHY_2_LANE_REMAP        = 16'h3210,
      parameter        PHY_2_GENERATE_IDELAYCTRL =  "FALSE",
      parameter        PHY_2_GENERATE_DDR_CK   =  PHY_0_GENERATE_DDR_CK,
      parameter        PHY_2_NUM_DDR_CK        =  PHY_0_NUM_DDR_CK,
      parameter        PHY_2_DIFFERENTIAL_DQS  =  PHY_0_DIFFERENTIAL_DQS,
      parameter        PHY_2_DATA_CTL          = DATA_CTL_B2,
      parameter        PHY_2_CMD_OFFSET        = PHY_0_CMD_OFFSET,
      parameter        PHY_2_RD_CMD_OFFSET_0   = PHY_0_RD_CMD_OFFSET_0,
      parameter        PHY_2_RD_CMD_OFFSET_1   = PHY_0_RD_CMD_OFFSET_1,
      parameter        PHY_2_RD_CMD_OFFSET_2   = PHY_0_RD_CMD_OFFSET_2,
      parameter        PHY_2_RD_CMD_OFFSET_3   = PHY_0_RD_CMD_OFFSET_3,
      parameter        PHY_2_RD_DURATION_0     = PHY_0_RD_DURATION_0,
      parameter        PHY_2_RD_DURATION_1     = PHY_0_RD_DURATION_1,
      parameter        PHY_2_RD_DURATION_2     = PHY_0_RD_DURATION_2,
      parameter        PHY_2_RD_DURATION_3     = PHY_0_RD_DURATION_3,
      parameter        PHY_2_WR_CMD_OFFSET_0   = PHY_0_WR_CMD_OFFSET_0,
      parameter        PHY_2_WR_CMD_OFFSET_1   = PHY_0_WR_CMD_OFFSET_1,
      parameter        PHY_2_WR_CMD_OFFSET_2   = PHY_0_WR_CMD_OFFSET_2,
      parameter        PHY_2_WR_CMD_OFFSET_3   = PHY_0_WR_CMD_OFFSET_3,
      parameter        PHY_2_WR_DURATION_0     = PHY_0_WR_DURATION_0,
      parameter        PHY_2_WR_DURATION_1     = PHY_0_WR_DURATION_1,
      parameter        PHY_2_WR_DURATION_2     = PHY_0_WR_DURATION_2,
      parameter        PHY_2_WR_DURATION_3     = PHY_0_WR_DURATION_3,
      parameter        PHY_2_AO_WRLVL_EN       = PHY_0_AO_WRLVL_EN,
      parameter        PHY_2_AO_TOGGLE         = PHY_0_AO_TOGGLE, // odd bits are toggle (CKE)
// per lane parameters
      parameter        PHY_2_A_PI_FREQ_REF_DIV = PHY_0_A_PI_FREQ_REF_DIV,
      parameter        PHY_2_A_PI_CLKOUT_DIV   = PHY_0_A_PI_CLKOUT_DIV ,
      parameter        PHY_2_A_PO_CLKOUT_DIV   = PHY_0_A_PO_CLKOUT_DIV,
      parameter        PHY_2_A_BURST_MODE      = PHY_0_A_BURST_MODE ,
      parameter        PHY_2_A_PI_OUTPUT_CLK_SRC  = PHY_0_A_PI_OUTPUT_CLK_SRC,
      parameter        PHY_2_A_PO_OUTPUT_CLK_SRC  = PHY_0_A_PO_OUTPUT_CLK_SRC,
      parameter        PHY_2_PO_FINE_DELAY     = PHY_0_PO_FINE_DELAY,
      parameter        PHY_2_A_PO_OCLK_DELAY   = PHY_0_A_PO_OCLK_DELAY,
      parameter        PHY_2_B_PO_OCLK_DELAY   = PHY_2_A_PO_OCLK_DELAY,
      parameter        PHY_2_C_PO_OCLK_DELAY   = PHY_2_A_PO_OCLK_DELAY,
      parameter        PHY_2_D_PO_OCLK_DELAY   = PHY_2_A_PO_OCLK_DELAY,
      parameter        PHY_2_A_PO_OCLKDELAY_INV   = PHY_0_A_PO_OCLKDELAY_INV,
      parameter        PHY_2_OF_ALMOST_FULL_VALUE = 1,
      parameter        PHY_2_A_IDELAYE2_IDELAY_TYPE  = PHY_0_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_2_A_IDELAYE2_IDELAY_VALUE = PHY_0_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_2_B_IDELAYE2_IDELAY_TYPE  = PHY_2_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_2_B_IDELAYE2_IDELAY_VALUE = PHY_2_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_2_C_IDELAYE2_IDELAY_TYPE  = PHY_2_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_2_C_IDELAYE2_IDELAY_VALUE = PHY_2_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_2_D_IDELAYE2_IDELAY_TYPE  = PHY_2_A_IDELAYE2_IDELAY_TYPE,
      parameter        PHY_2_D_IDELAYE2_IDELAY_VALUE = PHY_2_A_IDELAYE2_IDELAY_VALUE,
      parameter        PHY_0_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) || (BYTE_LANES_B2 != 0) || (BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0)) ?  "FALSE" : "TRUE",
      parameter        PHY_1_IS_LAST_BANK   = ((BYTE_LANES_B1 != 0) && ((BYTE_LANES_B2 != 0) || (BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0))) ?  "FALSE" : ((PHY_0_IS_LAST_BANK) ? "FALSE" : "TRUE"),
      parameter        PHY_2_IS_LAST_BANK   = (BYTE_LANES_B2 != 0) && ((BYTE_LANES_B3 != 0) || (BYTE_LANES_B4 != 0)) ?  "FALSE" : ((PHY_0_IS_LAST_BANK || PHY_1_IS_LAST_BANK) ? "FALSE" : "TRUE"),
      parameter        TCK = 2500,

// local computational use, do not pass down
      parameter        N_LANES = (0+BYTE_LANES_B0[0]) + (0+BYTE_LANES_B0[1]) + (0+BYTE_LANES_B0[2]) + (0+BYTE_LANES_B0[3])
      +  (0+BYTE_LANES_B1[0]) + (0+BYTE_LANES_B1[1]) + (0+BYTE_LANES_B1[2]) + (0+BYTE_LANES_B1[3])  + (0+BYTE_LANES_B2[0]) + (0+BYTE_LANES_B2[1]) + (0+BYTE_LANES_B2[2]) + (0+BYTE_LANES_B2[3])
      ,  // must not delete comma for syntax
      parameter HIGHEST_BANK = (BYTE_LANES_B4 != 0 ? 5 : (BYTE_LANES_B3 != 0 ? 4 : (BYTE_LANES_B2 != 0 ? 3 :  (BYTE_LANES_B1 != 0  ? 2 : 1)))),
      parameter HIGHEST_LANE_B0  =   ((PHY_0_IS_LAST_BANK == "FALSE") ? 4 : BYTE_LANES_B0[3] ? 4 : BYTE_LANES_B0[2] ? 3 : BYTE_LANES_B0[1] ? 2 : BYTE_LANES_B0[0] ? 1 : 0)  ,
      parameter HIGHEST_LANE_B1  = (HIGHEST_BANK > 2) ? 4 : ( BYTE_LANES_B1[3] ? 4 : BYTE_LANES_B1[2] ? 3 : BYTE_LANES_B1[1] ? 2 : BYTE_LANES_B1[0] ? 1 : 0) ,
      parameter HIGHEST_LANE_B2  = (HIGHEST_BANK > 3) ? 4 : ( BYTE_LANES_B2[3] ? 4 : BYTE_LANES_B2[2] ? 3 : BYTE_LANES_B2[1] ? 2 : BYTE_LANES_B2[0] ? 1 : 0) ,
      parameter HIGHEST_LANE_B3  = 0,
      parameter HIGHEST_LANE_B4  = 0,

      parameter HIGHEST_LANE = (HIGHEST_LANE_B4 != 0) ? (HIGHEST_LANE_B4+16) : ((HIGHEST_LANE_B3 != 0) ? (HIGHEST_LANE_B3 + 12) : ((HIGHEST_LANE_B2 != 0) ? (HIGHEST_LANE_B2 + 8)  : ((HIGHEST_LANE_B1 != 0) ? (HIGHEST_LANE_B1 + 4) : HIGHEST_LANE_B0))),
      parameter LP_DDR_CK_WIDTH = 2
 )
 (
      input            rst,
      input            ddr_rst_in_n ,
      input            phy_clk,
      input            freq_refclk,
      input            mem_refclk,
      input            mem_refclk_div4,
      input            pll_lock,
      input            sync_pulse,
      input            idelayctrl_refclk,
      input [HIGHEST_LANE*80-1:0]    phy_dout,
      input            phy_cmd_wr_en,
      input            phy_data_wr_en,
      input            phy_rd_en,
      input [31:0]     phy_ctl_wd,
      input [3:0]      aux_in_1,
      input [3:0]      aux_in_2,
      input [5:0]      data_offset_1,
      input [5:0]      data_offset_2,
      input            phy_ctl_wr,
      input            if_empty_def,
      input            cke_in,
      input            idelay_ce,
      input            idelay_ld,
      input            idelay_inc,
      input            input_sink,
      output           if_a_empty,
      output           if_empty,
      output           of_ctl_a_full,
      output           of_data_a_full,
      output           of_ctl_full,
      output           of_data_full,
      output [HIGHEST_LANE*80-1:0]   phy_din,
      output           phy_ctl_a_full,
      output           phy_ctl_full,
/**
      inout  [(HIGHEST_LANE*12)-1:0]  IO,      // data/ctl to memory
      inout  [(HIGHEST_LANE*2-1):0]   DQS,     // to memory
**/
      output [HIGHEST_LANE*12-1:0] mem_dq_out,
      output [HIGHEST_LANE*12-1:0] mem_dq_ts,
      input  [HIGHEST_LANE*10-1:0] mem_dq_in,
      output [HIGHEST_LANE-1:0]    mem_dqs_out,
      output [HIGHEST_LANE-1:0]    mem_dqs_ts,
      input  [HIGHEST_LANE-1:0]    mem_dqs_in,
     
      output reg [(((HIGHEST_LANE+3)/4)*4)-1:0] aux_out, // to memory, odt ,  4 per phy controller
      output           phy_ctl_ready,          // to fabric
      output wire      rst_out,                // to memory
      output [(PHY_0_NUM_DDR_CK * LP_DDR_CK_WIDTH)-1:0]  ddr_clk,
      output           rclk,
      output           mcGo,
      //inout [`SCAN_TEST_BUS_WIDTH-1:0] scan_test_bus_A,
      //inout [`SCAN_TEST_BUS_WIDTH-1:0] scan_test_bus_B,
      //inout [`SCAN_TEST_BUS_WIDTH-1:0] scan_test_bus_C,
      //inout [`SCAN_TEST_BUS_WIDTH-1:0] scan_test_bus_D
// calibration signals
      input            phy_write_calib,
      input            phy_read_calib,
      input  [5:0]     calib_sel,
      input  [HIGHEST_BANK-1:0]calib_zero_inputs, // bit calib_sel[2], one per bank
      input  [HIGHEST_BANK-1:0]calib_zero_ctrl,  // one  bit per lane, zero's only control lane calibration inputs
      input            calib_in_common,
      input            po_fine_enable,
      input            po_coarse_enable,
      input            po_fine_inc,
      input            po_coarse_inc,
      input            po_counter_load_en,
      input            po_sel_fine_oclk_delay,
      input  [8:0]     po_counter_load_val,
      input            po_counter_read_en,
      output reg       po_coarse_overflow,
      output reg       po_fine_overflow,
      output reg [8:0] po_counter_read_val,


      input            pi_rst_dqs_find,
      input            pi_fine_enable,
      input            pi_fine_inc,
      input            pi_counter_load_en,
      input            pi_counter_read_en,
      input  [5:0]     pi_counter_load_val,
      output reg       pi_fine_overflow,
      output reg [5:0] pi_counter_read_val,

      output reg       pi_phase_locked,
      output           pi_phase_locked_all,
      output reg       pi_dqs_found,
      output           pi_dqs_found_all,
      output           pi_dqs_found_any,
      output reg       pi_dqs_out_of_range
 );


wire [1:0]    phy_encalib;

wire [7:0]    calib_zero_inputs_int ;

wire  [4:0]     po_coarse_overflow_w;
wire  [4:0]     po_fine_overflow_w;
wire  [8:0]     po_counter_read_val_w[4:0];
wire  [4:0]     pi_fine_overflow_w;
wire  [5:0]     pi_counter_read_val_w[4:0];
wire  [4:0]     pi_dqs_found_w;
wire  [4:0]     pi_dqs_found_all_w;
wire  [4:0]     pi_dqs_found_any_w;
wire  [4:0]     pi_dqs_out_of_range_w;
wire  [4:0]     pi_phase_locked_w;
wire  [4:0]     pi_phase_locked_all_w;
wire  [4:0]     rclk_w;
wire  [HIGHEST_BANK-1:0]     phy_ctl_ready_w;
wire  [(PHY_0_NUM_DDR_CK * LP_DDR_CK_WIDTH)-1:0]     ddr_clk_w [4:0];
wire [(((HIGHEST_LANE+3)/4)*4)-1:0] aux_out_;


wire [3:0]    if_q0;
wire [3:0]    if_q1;
wire [3:0]    if_q2;
wire [3:0]    if_q3;
wire [3:0]    if_q4;
wire [7:0]    if_q5;
wire [7:0]    if_q6;
wire [3:0]    if_q7;
wire [3:0]    if_q8;
wire [3:0]    if_q9;

wire [31:0]   _phy_ctl_wd;
wire [3:0]    aux_in_[4:1];
wire [3:0]    rst_out_w;
reg           rst_out_i = 1'b0;

wire           freq_refclk_split;
wire           mem_refclk_div4_split;
wire           sync_pulse_split;
wire           phy_clk_split0;
wire           phy_ctl_clk_split0;
wire  [31:0]   phy_ctl_wd_split0;
wire           phy_ctl_wr_split0;
wire           phy_ctl_clk_split1;
wire           phy_clk_split1;
wire  [31:0]   phy_ctl_wd_split1;
wire           phy_ctl_wr_split1;
wire  [5:0]    data_offset_1_split1;
wire           phy_ctl_clk_split2;
wire           phy_clk_split2;
wire  [31:0]   phy_ctl_wd_split2;
wire           phy_ctl_wr_split2;
wire  [5:0]    data_offset_2_split2;
wire  [HIGHEST_LANE*80-1:0] phy_dout_split0;
wire           phy_cmd_wr_en_split0;
wire           phy_data_wr_en_split0;
wire           phy_rd_en_split0;
wire  [HIGHEST_LANE*80-1:0] phy_dout_split1;
wire           phy_cmd_wr_en_split1;
wire           phy_data_wr_en_split1;
wire           phy_rd_en_split1;
wire  [HIGHEST_LANE*80-1:0] phy_dout_split2;
wire           phy_cmd_wr_en_split2;
wire           phy_data_wr_en_split2;
wire           phy_rd_en_split2;

wire          phy_ctl_mstr_empty;
wire  [HIGHEST_BANK-1:0] phy_ctl_empty;

wire          _phy_ctl_a_full_f;
wire          _phy_ctl_a_empty_f;
wire          _phy_ctl_full_f;
wire          _phy_ctl_empty_f;
wire  [HIGHEST_BANK-1:0] _phy_ctl_a_full_p;
wire  [HIGHEST_BANK-1:0] _phy_ctl_full_p;
wire  [HIGHEST_BANK-1:0]  of_ctl_a_full_v;
wire  [HIGHEST_BANK-1:0]  of_ctl_full_v;
wire  [HIGHEST_BANK-1:0]  of_data_a_full_v;
wire  [HIGHEST_BANK-1:0]  of_data_full_v;
wire  [HIGHEST_BANK-1:0]  if_empty_v;
wire  [HIGHEST_BANK-1:0]  mux_i0_v;
wire  [HIGHEST_BANK-1:0]  mux_i1_v;
wire  [HIGHEST_BANK-1:0]  if_a_empty_v;

wire [7:0]                 dummy;
wire [3:0]                 dummy_q[11:0];
wire [HIGHEST_LANE -1:0]   dummy_data;
wire [HIGHEST_LANE*2-1:0]  dummy_dqs;

localparam IF_ALMOST_EMPTY_VALUE = 1;
localparam IF_ALMOST_FULL_VALUE  = 2;
localparam IF_ARRAY_MODE         = "ARRAY_MODE_4_X_4";
localparam IF_SYNCHRONOUS_MODE   = "FALSE";
localparam IF_SLOW_WR_CLK        = "FALSE";
localparam IF_SLOW_RD_CLK        = "FALSE";

localparam PHY_MULTI_REGION      = (HIGHEST_BANK > 1) ? "TRUE" : "FALSE";
localparam MASTER_PHY_CTL        = 0;
localparam RCLK_NEG_EDGE         = 3'b000;
localparam RCLK_POS_EDGE         = 3'b111;

/* Phaser_In Output source coding table
    "PHASE_REF"         :  4'b0000;
    "DELAYED_MEM_REF"   :  4'b0101;
    "DELAYED_PHASE_REF" :  4'b0011;
    "DELAYED_REF"       :  4'b0001;
    "FREQ_REF"          :  4'b1000;
    "MEM_REF"           :  4'b0010;
*/
localparam  RCLK_PI_OUTPUT_CLK_SRC = "DELAYED_MEM_REF";


localparam  real FREQ_REF_PER_NS = TCK > 2500.0 ? TCK/2/1000.0 : TCK/1000.0; 
localparam  DDR_TCK = TCK;

localparam  FREQ_REF_PERIOD = DDR_TCK / (PHY_0_A_PI_FREQ_REF_DIV == "DIV2" ? 2 : 1);
localparam  PO_S3_TAPS        = 64 ;  // Number of taps per clock cycle in OCLK_DELAYED delay line
localparam  PI_S2_TAPS        = 128 ; // Number of taps per clock cycle in stage 2 delay line
localparam  PO_S2_TAPS        = 128 ; // Number of taps per clock cycle in sta

/*
Intrinsic delay of Phaser In Stage 1
@3300ps - 1.939ns - 58.8%
@2500ps - 1.657ns - 66.3%
@1875ps - 1.263ns - 67.4%
@1500ps - 1.021ns - 68.1%
@1250ps - 0.868ns - 69.4%
@1072ps - 0.752ns - 70.1%
@938ps  - 0.667ns - 71.1% 
*/

// If we use the Delayed Mem_Ref_Clk in the RCLK Phaser_In, then the Stage 1 intrinsic delay is 0.0
// Fraction of a full DDR_TCK period
localparam  real PI_STG1_INTRINSIC_DELAY  =  (RCLK_PI_OUTPUT_CLK_SRC == "DELAYED_MEM_REF") ? 0.0 :
                     ((DDR_TCK < 1005) ? 0.667 :
                      (DDR_TCK < 1160) ? 0.752 :
                      (DDR_TCK < 1375) ? 0.868 :
                      (DDR_TCK < 1685) ? 1.021 :
                      (DDR_TCK < 2185) ? 1.263 :
                      (DDR_TCK < 2900) ? 1.657 :
                      (DDR_TCK < 3100) ? 1.771 : 1.939)*1000;
/*
Intrinsic delay of Phaser In Stage 2
@3300ps - 0.912ns - 27.6% - single tap - 13ps
@3000ps - 0.848ns - 28.3% - single tap - 11ps
@2500ps - 1.264ns - 50.6% - single tap - 19ps
@1875ps - 1.000ns - 53.3% - single tap - 15ps
@1500ps - 0.848ns - 56.5% - single tap - 11ps
@1250ps - 0.736ns - 58.9% - single tap - 9ps
@1072ps - 0.664ns - 61.9% - single tap - 8ps
@938ps  - 0.608ns - 64.8% - single tap - 7ps 
*/
// Intrinsic delay = (.4218 + .0002freq(MHz))period(ps)
localparam  real PI_STG2_INTRINSIC_DELAY  = (0.4218*FREQ_REF_PERIOD + 200) + 16.75;  // 12ps fudge factor
/*
Intrinsic delay of Phaser Out Stage 2 - coarse bypass = 1
@3300ps - 1.294ns - 39.2%
@2500ps - 1.294ns - 51.8%
@1875ps - 1.030ns - 54.9%
@1500ps - 0.878ns - 58.5%
@1250ps - 0.766ns - 61.3%
@1072ps - 0.694ns - 64.7%
@938ps  - 0.638ns - 68.0%

Intrinsic delay of Phaser Out Stage 2 - coarse bypass = 0
@3300ps - 2.084ns - 63.2% - single tap - 20ps
@2500ps - 2.084ns - 81.9% - single tap - 19ps
@1875ps - 1.676ns - 89.4% - single tap - 15ps
@1500ps - 1.444ns - 96.3% - single tap - 11ps
@1250ps - 1.276ns - 102.1% - single tap - 9ps
@1072ps - 1.164ns - 108.6% - single tap - 8ps
@938ps  - 1.076ns - 114.7% - single tap - 7ps
*/          
// Fraction of a full DDR_TCK period
localparam  real  PO_STG1_INTRINSIC_DELAY  = 0;
localparam  real  PO_STG2_FINE_INTRINSIC_DELAY    = 0.4218*FREQ_REF_PERIOD + 200 + 42; // 42ps fudge factor
localparam  real  PO_STG2_COARSE_INTRINSIC_DELAY  = 0.2256*FREQ_REF_PERIOD + 200 + 29; // 29ps fudge factor
localparam  real  PO_STG2_INTRINSIC_DELAY  = PO_STG2_FINE_INTRINSIC_DELAY +
                                            (PO_CTL_COARSE_BYPASS  == "TRUE" ? 30 : PO_STG2_COARSE_INTRINSIC_DELAY);

// When the PO_STG2_INTRINSIC_DELAY is approximately equal to tCK, then the Phaser Out's circular buffer can
// go metastable. The circular buffer must be prevented from getting into a metastable state. To accomplish this,
// a default programmed value must be programmed into the stage 2 delay. This delay is only needed at reset, adjustments
// to the stage 2 delay can be made after reset is removed.

localparam  real    PO_S2_TAPS_SIZE        = 1.0*FREQ_REF_PERIOD / PO_S2_TAPS ; // average delay of taps in stage 2 fine delay line
localparam  real    PO_CIRC_BUF_META_ZONE  = 200.0;
localparam       PO_CIRC_BUF_EARLY      = (PO_STG2_INTRINSIC_DELAY < DDR_TCK) ? 1'b1 : 1'b0;
localparam  real PO_CIRC_BUF_OFFSET     = (PO_STG2_INTRINSIC_DELAY < DDR_TCK) ? DDR_TCK - PO_STG2_INTRINSIC_DELAY : PO_STG2_INTRINSIC_DELAY - DDR_TCK;
// If the stage 2 intrinsic delay is less than the clock period, then see if it is less than the threshold
// If it is not more than the threshold than we must push the delay after the clock period plus a guardband.
localparam  integer PO_CIRC_BUF_DELAY   = PO_CIRC_BUF_EARLY ? (PO_CIRC_BUF_OFFSET > PO_CIRC_BUF_META_ZONE) ? 0 :
                                         (PO_CIRC_BUF_META_ZONE + PO_CIRC_BUF_OFFSET) / PO_S2_TAPS_SIZE : 
                                         (PO_CIRC_BUF_META_ZONE - PO_CIRC_BUF_OFFSET) / PO_S2_TAPS_SIZE;


localparam  real    PI_S2_TAPS_SIZE     = 1.0*FREQ_REF_PERIOD / PI_S2_TAPS ; // average delay of taps in stage 2 fine delay line
localparam  real    PI_MAX_STG2_DELAY   = PI_S2_TAPS/2 * PI_S2_TAPS_SIZE;
localparam  real  PI_INTRINSIC_DELAY  = PI_STG1_INTRINSIC_DELAY + PI_STG2_INTRINSIC_DELAY;
localparam  real  PO_INTRINSIC_DELAY  = PO_STG1_INTRINSIC_DELAY + PO_STG2_INTRINSIC_DELAY;
localparam  real    PO_DELAY            = PO_INTRINSIC_DELAY + (PO_CIRC_BUF_DELAY*PO_S2_TAPS_SIZE);
// The PI_OFFSET is the difference between the Phaser Out delay path and the intrinsic delay path
// of the Phaser_In that drives the rclk. The objective is to align either the rising edges of the
// oserdes_oclk and the rclk or to align the rising to falling edges depending on which adjustment 
// is within the range of the stage 2 delay line in the Phaser_In.
localparam  real    PI_OFFSET		= PO_DELAY - PI_INTRINSIC_DELAY; 
localparam  real    PI_STG2_DELAY       = PI_OFFSET > PI_MAX_STG2_DELAY ? 
                                          PI_OFFSET - PI_MAX_STG2_DELAY : PI_OFFSET;
localparam          RCLK_SELECT_EDGE    = PI_OFFSET > PI_MAX_STG2_DELAY ? RCLK_NEG_EDGE : RCLK_POS_EDGE;
localparam  integer DEFAULT_RCLK_DELAY  = PI_STG2_DELAY / PI_S2_TAPS_SIZE;

localparam  integer L_PHY_0_PO_FINE_DELAY = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_0_PO_FINE_DELAY;
localparam  integer L_PHY_1_PO_FINE_DELAY = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_1_PO_FINE_DELAY;
localparam  integer L_PHY_2_PO_FINE_DELAY = PHY_0_PO_FINE_DELAY == "UNDECLARED" ? PO_CIRC_BUF_DELAY : PHY_2_PO_FINE_DELAY;

localparam  PHY_0_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_0_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_0_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_0_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_1_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_1_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_1_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_1_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_2_A_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "A") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_2_B_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "B") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_2_C_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "C") ? DEFAULT_RCLK_DELAY : 0 : 0;
localparam  PHY_2_D_PI_FINE_DELAY = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "D") ? DEFAULT_RCLK_DELAY : 0 : 0;
  

localparam  _PHY_0_A_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "A") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_0_B_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "B") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_0_C_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "C") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_0_D_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 0) ? (RCLK_SELECT_LANE == "D") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC : PHY_0_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_1_A_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "A") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_1_B_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "B") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_1_C_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "C") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_1_D_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 1) ? (RCLK_SELECT_LANE == "D") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC : PHY_1_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_2_A_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "A") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_2_B_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "B") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_2_C_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "C") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC;
localparam  _PHY_2_D_PI_OUTPUT_CLK_SRC = (RCLK_SELECT_BANK == 2) ? (RCLK_SELECT_LANE == "D") ? RCLK_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC : PHY_2_A_PI_OUTPUT_CLK_SRC;


wire _phy_ctl_wr;
wire _phy_clk;

wire [2:0] mcGo_w;
reg  [3:0] mcGo_r;



initial begin
  $display("%m : BYTE_LANES_B0 = %x BYTE_LANES_B1 = %x DATA_CTL_B0 = %x DATA_CTL_B1 = %x", BYTE_LANES_B0, BYTE_LANES_B1, DATA_CTL_B0, DATA_CTL_B1);
  $display("%m : HIGHEST_LANE = %d HIGHEST_LANE_B0 = %d HIGHEST_LANE_B1 = %d",  HIGHEST_LANE, HIGHEST_LANE_B0, HIGHEST_LANE_B1);
  $display("%m : HIGHEST_BANK = %d", HIGHEST_BANK);

  $display("%m : FREQ_REF_PERIOD         = %0d ", FREQ_REF_PERIOD);
  $display("%m : DDR_TCK                 = %0d ", DDR_TCK);
  $display("%m : PO_S2_TAPS_SIZE         = %0.2f ", PO_S2_TAPS_SIZE);
  $display("%m : PO_CIRC_BUF_EARLY       = %0d ", PO_CIRC_BUF_EARLY);
  $display("%m : PO_CIRC_BUF_OFFSET      = %0.2f ", PO_CIRC_BUF_OFFSET);
  $display("%m : PO_CIRC_BUF_META_ZONE   = %0.2f ", PO_CIRC_BUF_META_ZONE);
  $display("%m : PO_STG2_FINE_INTR_DLY   = %0.2f ", PO_STG2_FINE_INTRINSIC_DELAY);
  $display("%m : PO_STG2_COARSE_INTR_DLY = %0.2f ", PO_STG2_COARSE_INTRINSIC_DELAY);
  $display("%m : PO_STG2_INTRINSIC_DELAY = %0.2f ", PO_STG2_INTRINSIC_DELAY);
  $display("%m : PO_CIRC_BUF_DELAY       = %0d ", PO_CIRC_BUF_DELAY);
  $display("%m : PO_INTRINSIC_DELAY      = %0.2f ", PO_INTRINSIC_DELAY);
  $display("%m : PO_DELAY                = %0.2f ", PO_DELAY);
  $display("%m : PO_OCLK_DELAY           = %0d ", PHY_0_A_PO_OCLK_DELAY);
  $display("%m : L_PHY_0_PO_FINE_DELAY   = %0d ", L_PHY_0_PO_FINE_DELAY);

  $display("%m : PI_STG1_INTRINSIC_DELAY = %0.2f ", PI_STG1_INTRINSIC_DELAY);
  $display("%m : PI_STG2_INTRINSIC_DELAY = %0.2f ", PI_STG2_INTRINSIC_DELAY);
  $display("%m : PI_INTRINSIC_DELAY      = %0.2f ", PI_INTRINSIC_DELAY);
  $display("%m : PI_STG2_DELAY           = %0.2f ", PI_STG2_DELAY);
  
  $display("%m : DEFAULT_RCLK_DELAY      = %0d ", DEFAULT_RCLK_DELAY);
  $display("%m : RCLK_SELECT_EDGE        = %0b ", RCLK_SELECT_EDGE);
end

// Use module signal_split for only for simulation purposes if it's desired to insert skew
// in signals going to different PHASER blocks. Otherwise, use the code below to bypass any
// skew insertion. 
assign mem_refclk_split       = mem_refclk;
assign sync_pulse_split       = sync_pulse;
assign freq_refclk_split      = freq_refclk;
assign mem_refclk_div4_split  = mem_refclk_div4;
assign data_offset_1_split1   = data_offset_1;
assign data_offset_2_split2   = data_offset_2;
assign phy_ctl_clk_split0     = phy_clk;
assign phy_ctl_wd_split0      = phy_ctl_wd;
assign phy_ctl_wr_split0      = phy_ctl_wr;
assign phy_clk_split0         = phy_clk;
assign phy_cmd_wr_en_split0   = phy_cmd_wr_en;
assign phy_data_wr_en_split0  = phy_data_wr_en;
assign phy_rd_en_split0       = phy_rd_en;
assign phy_dout_split0        = phy_dout;
assign phy_ctl_clk_split1     = phy_clk;
assign phy_ctl_wd_split1      = phy_ctl_wd;
assign phy_ctl_wr_split1      = phy_ctl_wr;
assign phy_clk_split1         = phy_clk;
assign phy_cmd_wr_en_split1   = phy_cmd_wr_en;
assign phy_data_wr_en_split1  = phy_data_wr_en;
assign phy_rd_en_split1       = phy_rd_en;
assign phy_dout_split1        = phy_dout;
assign phy_ctl_clk_split2     = phy_clk;
assign phy_ctl_wd_split2      = phy_ctl_wd;
assign phy_ctl_wr_split2      = phy_ctl_wr;
assign phy_clk_split2         = phy_clk;
assign phy_cmd_wr_en_split2   = phy_cmd_wr_en;
assign phy_data_wr_en_split2  = phy_data_wr_en;
assign phy_rd_en_split2       = phy_rd_en;
assign phy_dout_split2        = phy_dout;

/*
signal_split
 #(
     .BYTE_LANES_B0 (BYTE_LANES_B0),
     .BYTE_LANES_B1 (BYTE_LANES_B1),
     .BYTE_LANES_B2 (BYTE_LANES_B2),
     .BYTE_LANES_B3 (BYTE_LANES_B3),
     .BYTE_LANES_B4 (BYTE_LANES_B4)
 ) signal_split_i
 (
      .phy_clk                  (_phy_clk),
      .freq_refclk              (freq_refclk),
      .mem_refclk               (mem_refclk),
      .mem_refclk_div4          (mem_refclk_div4),
      .sync_pulse               (sync_pulse),
      .phy_dout                 (phy_dout),
      .phy_cmd_wr_en            (phy_cmd_wr_en),
      .phy_data_wr_en           (phy_data_wr_en),
      .phy_rd_en                (phy_rd_en),
      .phy_ctl_wd               (_phy_ctl_wd),
      .phy_ctl_wr               (_phy_ctl_wr),
      .data_offset_1            (data_offset_1),
      .data_offset_2            (data_offset_2),
      .mem_refclk_split         (mem_refclk_split),
      .freq_refclk_split        (freq_refclk_split),
      .mem_refclk_div4_split    (mem_refclk_div4_split),
      .sync_pulse_split         (sync_pulse_split),
      .phy_ctl_clk_split0       (phy_ctl_clk_split0),
      .phy_clk_split0           (phy_clk_split0),
      .phy_ctl_wd_split0        (phy_ctl_wd_split0),
      .phy_ctl_wr_split0        (phy_ctl_wr_split0),
      .phy_ctl_clk_split1       (phy_ctl_clk_split1),
      .phy_clk_split1           (phy_clk_split1),
      .phy_ctl_wd_split1        (phy_ctl_wd_split1),
      .data_offset_1_split1     (data_offset_1_split1),
      .phy_ctl_wr_split1        (phy_ctl_wr_split1),
      .phy_ctl_clk_split2       (phy_ctl_clk_split2),
      .phy_clk_split2           (phy_clk_split2),
      .phy_ctl_wd_split2        (phy_ctl_wd_split2),
      .data_offset_2_split2     (data_offset_2_split2),
      .phy_ctl_wr_split2        (phy_ctl_wr_split2),
      .phy_dout_split0          (phy_dout_split0),
      .phy_cmd_wr_en_split0     (phy_cmd_wr_en_split0),
      .phy_data_wr_en_split0    (phy_data_wr_en_split0),
      .phy_rd_en_split0         (phy_rd_en_split0),
      .phy_dout_split1          (phy_dout_split1),
      .phy_cmd_wr_en_split1     (phy_cmd_wr_en_split1),
      .phy_data_wr_en_split1    (phy_data_wr_en_split1),
      .phy_rd_en_split1         (phy_rd_en_split1),
      .phy_dout_split2          (phy_dout_split2),
      .phy_cmd_wr_en_split2     (phy_cmd_wr_en_split2),
      .phy_data_wr_en_split2    (phy_data_wr_en_split2),
      .phy_rd_en_split2         (phy_rd_en_split2)
 );
*/

assign pi_dqs_found_all      = & pi_dqs_found_all_w[HIGHEST_BANK-1:0];
assign pi_dqs_found_any      = | pi_dqs_found_any_w[HIGHEST_BANK-1:0];
assign pi_phase_locked_all   = & pi_phase_locked_all_w[HIGHEST_BANK-1:0];
assign calib_zero_inputs_int = {3'bxxx, calib_zero_inputs};

assign phy_ctl_ready = &phy_ctl_ready_w[HIGHEST_BANK-1:0];

assign phy_ctl_mstr_empty  = phy_ctl_empty[MASTER_PHY_CTL];

assign of_ctl_a_full  = |of_ctl_a_full_v;
assign of_ctl_full    = |of_ctl_full_v;
assign of_data_a_full = |of_data_a_full_v;
assign of_data_full   = |of_data_full_v;
// if if_empty_def == 1, empty is asserted only if all are empty;
// this allows the user to detect a skewed fifo depth and self-clear
// if desired. It avoids a reset to clear the flags.
//assign if_empty       = ! if_empty_def ? |if_empty_v : & if_empty_v;
generate
  begin
    if (HIGHEST_BANK==3)
      assign if_empty = !if_empty_def ? (mux_i0_v[0] | mux_i0_v[1] | mux_i0_v[2]) : (mux_i1_v[0] & mux_i1_v[1] & mux_i1_v[2]);
    else if (HIGHEST_BANK==2)
      assign if_empty = !if_empty_def ? (mux_i0_v[0] | mux_i0_v[1]) : (mux_i1_v[0] & mux_i1_v[1]);
    else 
      assign if_empty = !if_empty_def ? (mux_i0_v[0]) : (mux_i1_v[0]);
  end
endgenerate

assign if_a_empty     = |if_a_empty_v;

assign ddr_clk = ddr_clk_w[DDR_CLK_SELECT_BANK];

assign rclk = rclk_w[RCLK_SELECT_BANK];

always @(*) begin
      rst_out_i <=  rst_out_w[RCLK_SELECT_BANK] & ddr_rst_in_n;
end


always @(posedge phy_clk or posedge rst) begin
    if ( rst) 
       mcGo_r <= #(1) 0;
    else
    mcGo_r <=#(1) (mcGo_r << 1) |  (mcGo_w[RCLK_SELECT_BANK] && phy_ctl_ready);
end

assign mcGo = mcGo_r[3];

// Substitute OBUF with direct connection to prevent possible instantiation
// of extra output if rst_out from MC_PHY isn't used
//OBUF rst_buf(.O(rst_out), .I(rst_out_i));
assign rst_out = rst_out_i;  
  
generate
if (PHYCTL_CMD_FIFO == "TRUE" ) begin
    assign _phy_ctl_wd = {if_q7, if_q6[3:0], if_q5[3:0], if_q4, if_q3, if_q2, if_q1, if_q0};
    assign aux_in_[1]      = if_q8;
    assign aux_in_[2]      = if_q9;
    assign phy_ctl_a_full  = _phy_ctl_a_full_f;
    assign phy_ctl_full    = _phy_ctl_full_f;
    assign _phy_ctl_wr     = ! _phy_ctl_empty_f;
    assign _phy_clk        = mem_refclk_div4;
end
else begin 
    assign _phy_ctl_wd     = phy_ctl_wd;
    assign aux_in_[1]  = aux_in_1;
    assign aux_in_[2]  = aux_in_2;
    assign phy_ctl_a_full  = &_phy_ctl_a_full_p;
    assign phy_ctl_full    = &_phy_ctl_full_p;
    assign _phy_ctl_wr     = phy_ctl_wr;
    assign _phy_clk        = phy_clk;
end
endgenerate


// this code ties off dummy wires for unused dqs signals
// on control lanes and unused data signals on data lanes.
// this keeps the allocation of the busses simple
// all lanes allocate 10-bits of data plus 2-more at the high
// end of the bus.

assign dummy [0] =  (&dummy_data) & (& dummy_dqs);

// this fifo crosses domain for the phy control word from
// phy_clk to freq_refclk (ddr clk). It uses one in_fifo (4x4
// mode)  that  is  unused in the control-path.
// Set parameter PHYCTL_CMD_FIFO = "TRUE" to use.
// otherwise this fifo is trimmed in the mapper.
// It is required to be used if there are more than 1
// phy controllers to prevent asychronous domain crossing
// in phy controller causing a skew in when phy control
// words are registered and executed. Using this fifo keeps them
// synchronous and timing is simplified.

`ifdef FUJI_PHY_BLH
B_IN_FIFO #(
`else
IN_FIFO #(
`endif      
  .ALMOST_EMPTY_VALUE          ( IF_ALMOST_EMPTY_VALUE ),
  .ALMOST_FULL_VALUE           ( IF_ALMOST_FULL_VALUE ),
  .ARRAY_MODE                  ( IF_ARRAY_MODE),
  .SYNCHRONOUS_MODE            ( IF_SYNCHRONOUS_MODE)
) in_fifo_i  (
  .ALMOSTEMPTY                 (_phy_ctl_a_empty_f),
  .ALMOSTFULL                  (_phy_ctl_a_full_f),
  .EMPTY                       (_phy_ctl_empty_f),
  .FULL                        (_phy_ctl_full_f),
  .Q0                          ({dummy_q[0],if_q0}),
  .Q1                          ({dummy_q[1],if_q1}),
  .Q2                          ({dummy_q[2],if_q2}),
  .Q3                          ({dummy_q[3],if_q3}),
  .Q4                          ({dummy_q[4],if_q4}),
  .Q5                          ({if_q5}),
  .Q6                          ({if_q6}),
  .Q7                          ({dummy_q[7],if_q7}),
  .Q8                          ({dummy_q[8],if_q8}),
  .Q9                          ({dummy_q[9],if_q9}),
//===
  .D0                          (phy_ctl_wd[3:0]),
  .D1                          (phy_ctl_wd[7:4]),
  .D2                          (phy_ctl_wd[11:8]),
  .D3                          (phy_ctl_wd[15:12]),
  .D4                          (phy_ctl_wd[19:16]),
  .D5                          ({phy_ctl_wd[23:20], phy_ctl_wd[23:20]}),
  .D6                          ({phy_ctl_wd[27:24], phy_ctl_wd[27:24]}),
  .D7                          (phy_ctl_wd[31:28]),
  .D8                          (aux_in_1),
  .D9                          (aux_in_2),
  .RDCLK                       (mem_refclk_div4_split0),
  .RDEN                        ( ! _phy_ctl_empty_f ),
  .RESET                       (rst),
  .WRCLK                       (phy_clk_split0),
  .WREN                        (phy_ctl_wr_split0)
);

// instance of four-lane phy

generate 

if ( BYTE_LANES_B0 != 0)  begin : phy_4lanes_0
phy_4lanes #(
     .BYTE_LANES                (BYTE_LANES_B0),        /* four bits, one per lanes */
     .DATA_CTL_N                (PHY_0_DATA_CTL), /* four bits, one per lane */
     .PO_CTL_COARSE_BYPASS      (PO_CTL_COARSE_BYPASS),
     .PO_FINE_DELAY             (L_PHY_0_PO_FINE_DELAY),
     .BITLANES                  (PHY_0_BITLANES),
     .BITLANES_OUTONLY          (PHY_0_BITLANES_OUTONLY),
     .LAST_BANK                 (PHY_0_IS_LAST_BANK ),
     .LANE_REMAP                (PHY_0_LANE_REMAP),
     //.OF_ALMOST_FULL_VALUE      (PHY_O_OF_ALMOST_FULL_VALUE),
     //.IF_ALMOST_EMPTY_VALUE     (PHY_O_IF_ALMOST_EMPTY_VALUE),
     .GENERATE_IDELAYCTRL       (PHY_0_GENERATE_IDELAYCTRL),
     .GENERATE_DDR_CK           (PHY_0_GENERATE_DDR_CK),
     .NUM_DDR_CK                (PHY_0_NUM_DDR_CK),
     .DIFFERENTIAL_DQS          (PHY_0_DIFFERENTIAL_DQS),
     .TCK                       (TCK),
     .RCLK_SELECT_LANE          (RCLK_SELECT_LANE),
     .MC_DIVIDE                 (PHY_CLK_RATIO),
     .PC_CLK_RATIO              (PHY_CLK_RATIO),
     .PC_EVENTS_DELAY           (PHY_EVENTS_DELAY),
     .PC_FOUR_WINDOW_CLOCKS     (PHY_FOUR_WINDOW_CLOCKS),
     .PC_BURST_MODE             (PHY_0_A_BURST_MODE),
     .PC_SYNC_MODE              (PHY_SYNC_MODE),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),
     .PC_PHY_COUNT_EN           (PHY_COUNT_EN),
     .PC_DISABLE_SEQ_MATCH      (PHY_DISABLE_SEQ_MATCH),
     .PC_CMD_OFFSET             (PHY_0_CMD_OFFSET),
     .PC_RD_CMD_OFFSET_0        (PHY_0_RD_CMD_OFFSET_0),
     .PC_RD_CMD_OFFSET_1        (PHY_0_RD_CMD_OFFSET_1),
     .PC_RD_CMD_OFFSET_2        (PHY_0_RD_CMD_OFFSET_2),
     .PC_RD_CMD_OFFSET_3        (PHY_0_RD_CMD_OFFSET_3),
     .PC_RD_DURATION_0          (PHY_0_RD_DURATION_0),
     .PC_RD_DURATION_1          (PHY_0_RD_DURATION_1),
     .PC_RD_DURATION_2          (PHY_0_RD_DURATION_2),
     .PC_RD_DURATION_3          (PHY_0_RD_DURATION_3),
     .PC_WR_CMD_OFFSET_0        (PHY_0_WR_CMD_OFFSET_0),
     .PC_WR_CMD_OFFSET_1        (PHY_0_WR_CMD_OFFSET_1),
     .PC_WR_CMD_OFFSET_2        (PHY_0_WR_CMD_OFFSET_2),
     .PC_WR_CMD_OFFSET_3        (PHY_0_WR_CMD_OFFSET_3),
     .PC_WR_DURATION_0          (PHY_0_WR_DURATION_0),
     .PC_WR_DURATION_1          (PHY_0_WR_DURATION_1),
     .PC_WR_DURATION_2          (PHY_0_WR_DURATION_2),
     .PC_WR_DURATION_3          (PHY_0_WR_DURATION_3),
     .PC_AO_WRLVL_EN            (PHY_0_AO_WRLVL_EN),
     .PC_AO_TOGGLE              (PHY_0_AO_TOGGLE),

     .A_PI_FINE_DELAY           (PHY_0_A_PI_FINE_DELAY),
     .B_PI_FINE_DELAY           (PHY_0_B_PI_FINE_DELAY),
     .C_PI_FINE_DELAY           (PHY_0_C_PI_FINE_DELAY),
     .D_PI_FINE_DELAY           (PHY_0_D_PI_FINE_DELAY),

     .A_PI_FREQ_REF_DIV         (PHY_0_A_PI_FREQ_REF_DIV),
     //.A_PI_CLKOUT_DIV           ( PHY_0_A_PI_CLKOUT_DIV),
     //.A_PO_CLKOUT_DIV           ( PHY_0_A_PO_CLKOUT_DIV),
     .A_PI_BURST_MODE           (PHY_0_A_BURST_MODE),
     .A_PI_OUTPUT_CLK_SRC       (_PHY_0_A_PI_OUTPUT_CLK_SRC),
     .B_PI_OUTPUT_CLK_SRC       (_PHY_0_B_PI_OUTPUT_CLK_SRC),
     .C_PI_OUTPUT_CLK_SRC       (_PHY_0_C_PI_OUTPUT_CLK_SRC),
     .D_PI_OUTPUT_CLK_SRC       (_PHY_0_D_PI_OUTPUT_CLK_SRC),
     .A_PO_OUTPUT_CLK_SRC       (PHY_0_A_PO_OUTPUT_CLK_SRC),
     .A_PO_OCLK_DELAY           (PHY_0_A_PO_OCLK_DELAY),
     .A_PO_OCLKDELAY_INV        (PHY_0_A_PO_OCLKDELAY_INV),
     .A_OF_ARRAY_MODE           (PHY_0_A_OF_ARRAY_MODE),
     .B_OF_ARRAY_MODE           (PHY_0_B_OF_ARRAY_MODE),
     .C_OF_ARRAY_MODE           (PHY_0_C_OF_ARRAY_MODE),
     .D_OF_ARRAY_MODE           (PHY_0_D_OF_ARRAY_MODE),
     .A_IF_ARRAY_MODE           (PHY_0_A_IF_ARRAY_MODE),
     .B_IF_ARRAY_MODE           (PHY_0_B_IF_ARRAY_MODE),
     .C_IF_ARRAY_MODE           (PHY_0_C_IF_ARRAY_MODE),
     .D_IF_ARRAY_MODE           (PHY_0_D_IF_ARRAY_MODE),
     .A_OS_DATA_RATE            (PHY_0_A_OSERDES_DATA_RATE),
     .A_OS_DATA_WIDTH           (PHY_0_A_OSERDES_DATA_WIDTH),
     .B_OS_DATA_RATE            (PHY_0_B_OSERDES_DATA_RATE),
     .B_OS_DATA_WIDTH           (PHY_0_B_OSERDES_DATA_WIDTH),
     .C_OS_DATA_RATE            (PHY_0_C_OSERDES_DATA_RATE),
     .C_OS_DATA_WIDTH           (PHY_0_C_OSERDES_DATA_WIDTH),
     .D_OS_DATA_RATE            (PHY_0_D_OSERDES_DATA_RATE),
     .D_OS_DATA_WIDTH           (PHY_0_D_OSERDES_DATA_WIDTH),
     .A_IDELAYE2_IDELAY_TYPE   (PHY_0_A_IDELAYE2_IDELAY_TYPE),
     .A_IDELAYE2_IDELAY_VALUE  (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP              (IODELAY_GRP)
)
 phy_4lanes
(
      .rst                      (rst),
      .phy_clk                  (phy_clk_split0),
      .phy_ctl_clk              (phy_ctl_clk_split0),
      .phy_ctl_wd               (phy_ctl_wd_split0),
      .data_offset              (phy_ctl_wd_split0[`PC_OFFSET_RANGE]),
      .phy_ctl_wr               (phy_ctl_wr_split0),
      .mem_refclk               (mem_refclk_split),
      .freq_refclk              (freq_refclk_split),
      .mem_refclk_div4          (mem_refclk_div4_split),
      .sync_pulse               (sync_pulse_split),
      .phy_dout                 (phy_dout_split0[HIGHEST_LANE_B0*80-1:0]),
      .phy_cmd_wr_en            (phy_cmd_wr_en_split0),
      .phy_data_wr_en           (phy_data_wr_en_split0),
      .phy_rd_en                (phy_rd_en_split0),
      .pll_lock                 (pll_lock),
      .ddr_clk                  (ddr_clk_w[0]),
      .rclk                     (rclk_w[0]),
      .rst_out                  (rst_out_w[0]),
      .mcGo                     (mcGo_w[0]),
      .idelayctrl_refclk        (idelayctrl_refclk),
      .idelay_inc               (idelay_inc),
      .idelay_ce                (idelay_ce),
      .idelay_ld                (idelay_ld),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),
      .if_empty_def             (if_empty_def),

      .if_a_empty               (if_a_empty_v[0]),
      .if_empty                 (if_empty_v[0]),
      .mux_i0                   (mux_i0_v[0]),
      .mux_i1                   (mux_i1_v[0]),
      .of_ctl_a_full            (of_ctl_a_full_v[0]),
      .of_data_a_full           (of_data_a_full_v[0]),
      .of_ctl_full              (of_ctl_full_v[0]),
      .of_data_full             (of_data_full_v[0]),
      .phy_din                  (phy_din[HIGHEST_LANE_B0*80-1:0]),
      .phy_ctl_a_full           (_phy_ctl_a_full_p[0]),
      .phy_ctl_full             (_phy_ctl_full_p[0]),
      .phy_ctl_empty            (phy_ctl_empty[0]),
      .mem_dq_out               (mem_dq_out[HIGHEST_LANE_B0*12-1:0]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B0*12-1:0]),
      .mem_dq_in                (mem_dq_in[HIGHEST_LANE_B0*10-1:0]),
      .mem_dqs_out              (mem_dqs_out[HIGHEST_LANE_B0-1:0]),
      .mem_dqs_ts               (mem_dqs_ts[HIGHEST_LANE_B0-1:0]),
      .mem_dqs_in               (mem_dqs_in[HIGHEST_LANE_B0-1:0]),
      .aux_out                  (aux_out_[3:0]),
      .phy_ctl_ready            (phy_ctl_ready_w[0]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
//      .scan_test_bus_A          (scan_test_bus_A),
//      .scan_test_bus_B          (),
//      .scan_test_bus_C          (),
//      .scan_test_bus_D          (),
      .input_sink               (),

      .calib_sel                ({calib_zero_inputs_int[0], calib_sel[1:0]}),
      .calib_zero_ctrl          (calib_zero_ctrl[0]),
      .calib_in_common          (calib_in_common),
      .phy_encalib              (phy_encalib),
      .po_coarse_enable         (po_coarse_enable),
      .po_fine_enable           (po_fine_enable),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[0]),
      .po_fine_overflow         (po_fine_overflow_w[0]),
      .po_counter_read_val      (po_counter_read_val_w[0]),

      .pi_rst_dqs_find          (pi_rst_dqs_find),
      .pi_fine_enable           (pi_fine_enable),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[0]),
      .pi_counter_read_val      (pi_counter_read_val_w[0]),
      .pi_dqs_found             (pi_dqs_found_w[0]),
      .pi_dqs_found_all         (pi_dqs_found_all_w[0]),
      .pi_dqs_found_any         (pi_dqs_found_any_w[0]),
      .pi_dqs_out_of_range      (pi_dqs_out_of_range_w[0]),
      .pi_phase_locked          (pi_phase_locked_w[0]),
      .pi_phase_locked_all      (pi_phase_locked_all_w[0])
);

if ( RCLK_SELECT_EDGE[0])
      always @(posedge rclk_w[0] or posedge rst)  begin
     if (rst)
         aux_out[3:0] <= #1 0;
     else
         aux_out[3:0] <= #1 aux_out_[3:0];
   end
   else
      always @(negedge rclk_w[0] or posedge rst)  begin
     if (rst)
         aux_out[3:0] <= #1 0;
     else
         aux_out[3:0] <= #1 aux_out_[3:0];
   end
end
else begin
   if ( HIGHEST_BANK > 0) begin
       assign phy_din[319:0] = 0;
       assign _phy_ctl_a_full_p[0] = 0;
       assign of_ctl_a_full_v[0]   = 0;
       assign of_ctl_full_v[0]     = 0;
       assign of_data_a_full_v[0]  = 0;
       assign of_data_full_v[0]    = 0;
       assign if_empty_v[0]        = 0;
       assign mux_i0_v[0]          = 0;
       assign mux_i1_v[0]          = 0;
       always @(*)
           aux_out[3:0] = 0;
   end
       assign pi_dqs_found_w[0]    = 1;
       assign pi_dqs_found_all_w[0]    = 1;
       assign pi_dqs_found_any_w[0]    = 0;
       assign pi_dqs_out_of_range_w[0]    = 0;
       assign pi_phase_locked_w[0]    = 1;
       assign po_fine_overflow_w[0] = 0;
       assign po_coarse_overflow_w[0] = 0;
       assign po_fine_overflow_w[0] = 0;
       assign pi_fine_overflow_w[0] = 0;
       assign po_counter_read_val_w[0] = 0;
       assign pi_counter_read_val_w[0] = 0;
       if ( RCLK_SELECT_BANK == 0)
       always @(*)
           aux_out[3:0] = 0;
end

if ( BYTE_LANES_B1 != 0) begin : phy_4lanes_1

phy_4lanes #(
     .BYTE_LANES                (BYTE_LANES_B1),        /* four bits, one per lanes */
     .DATA_CTL_N                (PHY_1_DATA_CTL), /* four bits, one per lane */
     .PO_CTL_COARSE_BYPASS      (PO_CTL_COARSE_BYPASS),
     .PO_FINE_DELAY             (L_PHY_1_PO_FINE_DELAY),
     .BITLANES                  (PHY_1_BITLANES),
     .BITLANES_OUTONLY          (PHY_1_BITLANES_OUTONLY),
     .LAST_BANK                 (PHY_1_IS_LAST_BANK ),
     .LANE_REMAP                (PHY_1_LANE_REMAP),
     //.OF_ALMOST_FULL_VALUE      (PHY_1_OF_ALMOST_FULL_VALUE),
     //.IF_ALMOST_EMPTY_VALUE     (PHY_1_IF_ALMOST_EMPTY_VALUE),
     .GENERATE_IDELAYCTRL       (PHY_1_GENERATE_IDELAYCTRL),
     .GENERATE_DDR_CK           (PHY_1_GENERATE_DDR_CK),
     .NUM_DDR_CK                (PHY_1_NUM_DDR_CK),
     .DIFFERENTIAL_DQS          (PHY_1_DIFFERENTIAL_DQS),
     .TCK                       (TCK),
     .RCLK_SELECT_LANE          (RCLK_SELECT_LANE),
     .MC_DIVIDE                 (PHY_CLK_RATIO),
     .PC_CLK_RATIO              (PHY_CLK_RATIO),
     .PC_EVENTS_DELAY           (PHY_EVENTS_DELAY),
     .PC_FOUR_WINDOW_CLOCKS     (PHY_FOUR_WINDOW_CLOCKS),
     .PC_BURST_MODE             (PHY_1_A_BURST_MODE),
     .PC_SYNC_MODE              (PHY_SYNC_MODE),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),
     .PC_PHY_COUNT_EN           (PHY_COUNT_EN),
     .PC_DISABLE_SEQ_MATCH      (PHY_DISABLE_SEQ_MATCH),
     .PC_CMD_OFFSET             (PHY_1_CMD_OFFSET),
     .PC_RD_CMD_OFFSET_0        (PHY_1_RD_CMD_OFFSET_0),
     .PC_RD_CMD_OFFSET_1        (PHY_1_RD_CMD_OFFSET_1),
     .PC_RD_CMD_OFFSET_2        (PHY_1_RD_CMD_OFFSET_2),
     .PC_RD_CMD_OFFSET_3        (PHY_1_RD_CMD_OFFSET_3),
     .PC_RD_DURATION_0          (PHY_1_RD_DURATION_0),
     .PC_RD_DURATION_1          (PHY_1_RD_DURATION_1),
     .PC_RD_DURATION_2          (PHY_1_RD_DURATION_2),
     .PC_RD_DURATION_3          (PHY_1_RD_DURATION_3),
     .PC_WR_CMD_OFFSET_0        (PHY_1_WR_CMD_OFFSET_0),
     .PC_WR_CMD_OFFSET_1        (PHY_1_WR_CMD_OFFSET_1),
     .PC_WR_CMD_OFFSET_2        (PHY_1_WR_CMD_OFFSET_2),
     .PC_WR_CMD_OFFSET_3        (PHY_1_WR_CMD_OFFSET_3),
     .PC_WR_DURATION_0          (PHY_1_WR_DURATION_0),
     .PC_WR_DURATION_1          (PHY_1_WR_DURATION_1),
     .PC_WR_DURATION_2          (PHY_1_WR_DURATION_2),
     .PC_WR_DURATION_3          (PHY_1_WR_DURATION_3),
     .PC_AO_WRLVL_EN            (PHY_1_AO_WRLVL_EN),
     .PC_AO_TOGGLE              (PHY_1_AO_TOGGLE),

     .A_PI_FINE_DELAY           (PHY_1_A_PI_FINE_DELAY),
     .B_PI_FINE_DELAY           (PHY_1_B_PI_FINE_DELAY),
     .C_PI_FINE_DELAY           (PHY_1_C_PI_FINE_DELAY),
     .D_PI_FINE_DELAY           (PHY_1_D_PI_FINE_DELAY),

     .A_PI_FREQ_REF_DIV         (PHY_1_A_PI_FREQ_REF_DIV),
     //.A_PI_CLKOUT_DIV           (PHY_1_A_PI_CLKOUT_DIV),
     //.A_PO_CLKOUT_DIV           (PHY_1_A_PO_CLKOUT_DIV),
     .A_PI_BURST_MODE           (PHY_1_A_BURST_MODE),
     .A_PI_OUTPUT_CLK_SRC       (_PHY_1_A_PI_OUTPUT_CLK_SRC),
     .B_PI_OUTPUT_CLK_SRC       (_PHY_1_B_PI_OUTPUT_CLK_SRC),
     .C_PI_OUTPUT_CLK_SRC       (_PHY_1_C_PI_OUTPUT_CLK_SRC),
     .D_PI_OUTPUT_CLK_SRC       (_PHY_1_D_PI_OUTPUT_CLK_SRC),
     .A_PO_OUTPUT_CLK_SRC       (PHY_1_A_PO_OUTPUT_CLK_SRC),
     .A_PO_OCLK_DELAY           (PHY_1_A_PO_OCLK_DELAY),
     .A_PO_OCLKDELAY_INV        (PHY_1_A_PO_OCLKDELAY_INV),
     .A_OF_ARRAY_MODE           (PHY_1_A_OF_ARRAY_MODE),
     .B_OF_ARRAY_MODE           (PHY_1_B_OF_ARRAY_MODE),
     .C_OF_ARRAY_MODE           (PHY_1_C_OF_ARRAY_MODE),
     .D_OF_ARRAY_MODE           (PHY_1_D_OF_ARRAY_MODE),
     .A_IF_ARRAY_MODE           (PHY_1_A_IF_ARRAY_MODE),
     .B_IF_ARRAY_MODE           (PHY_1_B_IF_ARRAY_MODE),
     .C_IF_ARRAY_MODE           (PHY_1_C_IF_ARRAY_MODE),
     .D_IF_ARRAY_MODE           (PHY_1_D_IF_ARRAY_MODE),
     .A_OS_DATA_RATE            (PHY_1_A_OSERDES_DATA_RATE),
     .A_OS_DATA_WIDTH           (PHY_1_A_OSERDES_DATA_WIDTH),
     .B_OS_DATA_RATE            (PHY_1_B_OSERDES_DATA_RATE),
     .B_OS_DATA_WIDTH           (PHY_1_B_OSERDES_DATA_WIDTH),
     .C_OS_DATA_RATE            (PHY_1_C_OSERDES_DATA_RATE),
     .C_OS_DATA_WIDTH           (PHY_1_C_OSERDES_DATA_WIDTH),
     .D_OS_DATA_RATE            (PHY_1_D_OSERDES_DATA_RATE),
     .D_OS_DATA_WIDTH           (PHY_1_D_OSERDES_DATA_WIDTH),
     .A_IDELAYE2_IDELAY_TYPE    (PHY_1_A_IDELAYE2_IDELAY_TYPE),
     .A_IDELAYE2_IDELAY_VALUE   (PHY_1_A_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP               (IODELAY_GRP)
)
 phy_4lanes
(
      .rst                      (rst),
      .phy_clk                  (phy_clk_split1),
      .phy_ctl_clk              (phy_ctl_clk_split1),
      .phy_ctl_wd               (phy_ctl_wd_split1),
      .data_offset              (data_offset_1_split1),
      .phy_ctl_wr               (phy_ctl_wr_split1),
      .mem_refclk               (mem_refclk_split),
      .freq_refclk              (freq_refclk_split),
      .mem_refclk_div4          (mem_refclk_div4_split),
      .sync_pulse               (sync_pulse_split),
      .phy_dout                 (phy_dout_split1[HIGHEST_LANE_B1*80+320-1:320]),
      .phy_cmd_wr_en            (phy_cmd_wr_en_split1),
      .phy_data_wr_en           (phy_data_wr_en_split1),
      .phy_rd_en                (phy_rd_en_split1),
      .pll_lock                 (pll_lock),
      .ddr_clk                  (ddr_clk_w[1]),
      .rclk                     (rclk_w[1]),
      .rst_out                  (rst_out_w[1]),
      .mcGo                     (mcGo_w[1]),
      .idelayctrl_refclk        (idelayctrl_refclk),
      .idelay_inc               (idelay_inc),
      .idelay_ce                (idelay_ce),
      .idelay_ld                (idelay_ld),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),
      .if_empty_def             (if_empty_def),

      .if_a_empty               (if_a_empty_v[1]),
      .if_empty                 (if_empty_v[1]),
      .mux_i0                   (mux_i0_v[1]),
      .mux_i1                   (mux_i1_v[1]),
      .of_ctl_a_full            (of_ctl_a_full_v[1]),
      .of_data_a_full           (of_data_a_full_v[1]),
      .of_ctl_full              (of_ctl_full_v[1]),
      .of_data_full             (of_data_full_v[1]),
      .phy_din                  (phy_din[HIGHEST_LANE_B1*80+320-1:320]),
      .phy_ctl_a_full           (_phy_ctl_a_full_p[1]),
      .phy_ctl_full             (_phy_ctl_full_p[1]),
      .phy_ctl_empty            (phy_ctl_empty[1]),
      .mem_dq_out               (mem_dq_out[HIGHEST_LANE_B1*12+48-1:48]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B1*12+48-1:48]),
      .mem_dq_in                (mem_dq_in[HIGHEST_LANE_B1*10+40-1:40]),
      .mem_dqs_out              (mem_dqs_out[HIGHEST_LANE_B1+4-1:4]),
      .mem_dqs_ts               (mem_dqs_ts[HIGHEST_LANE_B1+4-1:4]),
      .mem_dqs_in               (mem_dqs_in[HIGHEST_LANE_B1+4-1:4]),
      .aux_out                  (aux_out_[7:4]),
      .phy_ctl_ready            (phy_ctl_ready_w[1]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
//      .scan_test_bus_A          (scan_test_bus_A),
//      .scan_test_bus_B          (),
//      .scan_test_bus_C          (),
//      .scan_test_bus_D          (),
      .input_sink               (),

      .calib_sel                ({calib_zero_inputs_int[1], calib_sel[1:0]}),
      .calib_zero_ctrl          (calib_zero_ctrl[1]),
      .calib_in_common          (calib_in_common),
      .phy_encalib              (phy_encalib),
      .po_coarse_enable         (po_coarse_enable),
      .po_fine_enable           (po_fine_enable),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[1]),
      .po_fine_overflow         (po_fine_overflow_w[1]),
      .po_counter_read_val      (po_counter_read_val_w[1]),

      .pi_rst_dqs_find          (pi_rst_dqs_find),
      .pi_fine_enable           (pi_fine_enable),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[1]),
      .pi_counter_read_val      (pi_counter_read_val_w[1]),
      .pi_dqs_found             (pi_dqs_found_w[1]),
      .pi_dqs_found_all         (pi_dqs_found_all_w[1]),
      .pi_dqs_found_any         (pi_dqs_found_any_w[1]),
      .pi_dqs_out_of_range      (pi_dqs_out_of_range_w[1]),
      .pi_phase_locked          (pi_phase_locked_w[1]),
      .pi_phase_locked_all      (pi_phase_locked_all_w[1])
);

if ( RCLK_SELECT_EDGE[1])
   always @(posedge rclk_w[1] or posedge rst)  begin
     if (rst)
         aux_out[7:4] <= #1 0;
     else
         aux_out[7:4] <= #1 aux_out_[7:4];
   end
   else
   always @(negedge rclk_w[1] or posedge rst)  begin
     if (rst)
         aux_out[7:4] <= #1 0;
     else
         aux_out[7:4] <= #1 aux_out_[7:4];
   end
end
else begin
   if ( HIGHEST_BANK > 1)  begin
       assign phy_din[2*320-1:320] = 0;
       assign _phy_ctl_a_full_p[1] = 0;
       assign of_ctl_a_full_v[1]   = 0;
       assign of_ctl_full_v[1]     = 0;
       assign of_data_a_full_v[1]  = 0;
       assign of_data_full_v[1]    = 0;
       assign if_empty_v[1]        = 0;
       assign mux_i0_v[1]          = 0;
       assign mux_i1_v[1]          = 0;
       always @(*)
          aux_out[7:4] = 0;
   end
       assign pi_dqs_found_w[1]    = 1;
       assign pi_dqs_found_all_w[1]    = 1;
       assign pi_dqs_found_any_w[1]    = 0;
       assign pi_dqs_out_of_range_w[1]    = 0;
       assign pi_phase_locked_w[1]    = 1;
       assign po_coarse_overflow_w[1] = 0;
       assign po_fine_overflow_w[1] = 0;
       assign pi_fine_overflow_w[1] = 0;
       assign po_counter_read_val_w[1] = 0;
       assign pi_counter_read_val_w[1] = 0;
end
  
if ( BYTE_LANES_B2 != 0) begin : phy_4lanes_2

phy_4lanes #(
     .BYTE_LANES                (BYTE_LANES_B2),        /* four bits, one per lanes */
     .DATA_CTL_N                (PHY_2_DATA_CTL), /* four bits, one per lane */
     .PO_CTL_COARSE_BYPASS      (PO_CTL_COARSE_BYPASS),
     .PO_FINE_DELAY             (L_PHY_2_PO_FINE_DELAY),
     .BITLANES                  (PHY_2_BITLANES),
     .BITLANES_OUTONLY          (PHY_2_BITLANES_OUTONLY),
     .LAST_BANK                 (PHY_2_IS_LAST_BANK ),
     .LANE_REMAP                (PHY_2_LANE_REMAP),
     //.OF_ALMOST_FULL_VALUE      (PHY_2_OF_ALMOST_FULL_VALUE),
     //.IF_ALMOST_EMPTY_VALUE     (PHY_2_IF_ALMOST_EMPTY_VALUE),
     .GENERATE_IDELAYCTRL       (PHY_2_GENERATE_IDELAYCTRL),
     .GENERATE_DDR_CK           (PHY_2_GENERATE_DDR_CK),
     .NUM_DDR_CK                (PHY_2_NUM_DDR_CK),
     .DIFFERENTIAL_DQS          (PHY_2_DIFFERENTIAL_DQS),
     .TCK                       (TCK),
     .RCLK_SELECT_LANE          (RCLK_SELECT_LANE),
     .PC_CLK_RATIO              (PHY_CLK_RATIO),
     .MC_DIVIDE                 (PHY_CLK_RATIO),     
     .PC_EVENTS_DELAY           (PHY_EVENTS_DELAY),
     .PC_FOUR_WINDOW_CLOCKS     (PHY_FOUR_WINDOW_CLOCKS),
     .PC_BURST_MODE             (PHY_2_A_BURST_MODE),
     .PC_SYNC_MODE              (PHY_SYNC_MODE),
     .PC_MULTI_REGION           (PHY_MULTI_REGION),
     .PC_PHY_COUNT_EN           (PHY_COUNT_EN),
     .PC_DISABLE_SEQ_MATCH      (PHY_DISABLE_SEQ_MATCH),
     .PC_CMD_OFFSET             (PHY_2_CMD_OFFSET),
     .PC_RD_CMD_OFFSET_0        (PHY_2_RD_CMD_OFFSET_0),
     .PC_RD_CMD_OFFSET_1        (PHY_2_RD_CMD_OFFSET_1),
     .PC_RD_CMD_OFFSET_2        (PHY_2_RD_CMD_OFFSET_2),
     .PC_RD_CMD_OFFSET_3        (PHY_2_RD_CMD_OFFSET_3),
     .PC_RD_DURATION_0          (PHY_2_RD_DURATION_0),
     .PC_RD_DURATION_1          (PHY_2_RD_DURATION_1),
     .PC_RD_DURATION_2          (PHY_2_RD_DURATION_2),
     .PC_RD_DURATION_3          (PHY_2_RD_DURATION_3),
     .PC_WR_CMD_OFFSET_0        (PHY_2_WR_CMD_OFFSET_0),
     .PC_WR_CMD_OFFSET_1        (PHY_2_WR_CMD_OFFSET_1),
     .PC_WR_CMD_OFFSET_2        (PHY_2_WR_CMD_OFFSET_2),
     .PC_WR_CMD_OFFSET_3        (PHY_2_WR_CMD_OFFSET_3),
     .PC_WR_DURATION_0          (PHY_2_WR_DURATION_0),
     .PC_WR_DURATION_1          (PHY_2_WR_DURATION_1),
     .PC_WR_DURATION_2          (PHY_2_WR_DURATION_2),
     .PC_WR_DURATION_3          (PHY_2_WR_DURATION_3),
     .PC_AO_WRLVL_EN            (PHY_2_AO_WRLVL_EN),
     .PC_AO_TOGGLE              (PHY_2_AO_TOGGLE),

     .A_PI_FINE_DELAY           (PHY_2_A_PI_FINE_DELAY),
     .B_PI_FINE_DELAY           (PHY_2_B_PI_FINE_DELAY),
     .C_PI_FINE_DELAY           (PHY_2_C_PI_FINE_DELAY),
     .D_PI_FINE_DELAY           (PHY_2_D_PI_FINE_DELAY),
     .A_PI_FREQ_REF_DIV         (PHY_2_A_PI_FREQ_REF_DIV),
     //.A_PI_CLKOUT_DIV           (PHY_2_A_PI_CLKOUT_DIV),
     //.A_PO_CLKOUT_DIV           (PHY_2_A_PO_CLKOUT_DIV),
     .A_PI_BURST_MODE           (PHY_2_A_BURST_MODE),
     .A_PI_OUTPUT_CLK_SRC       (_PHY_2_A_PI_OUTPUT_CLK_SRC),
     .B_PI_OUTPUT_CLK_SRC       (_PHY_2_B_PI_OUTPUT_CLK_SRC),
     .C_PI_OUTPUT_CLK_SRC       (_PHY_2_C_PI_OUTPUT_CLK_SRC),
     .D_PI_OUTPUT_CLK_SRC       (_PHY_2_D_PI_OUTPUT_CLK_SRC),
     .A_PO_OUTPUT_CLK_SRC       (PHY_2_A_PO_OUTPUT_CLK_SRC),
     .A_PO_OCLK_DELAY           (PHY_2_A_PO_OCLK_DELAY),
     .A_PO_OCLKDELAY_INV        (PHY_2_A_PO_OCLKDELAY_INV),
     .A_OF_ARRAY_MODE           (PHY_2_A_OF_ARRAY_MODE),
     .B_OF_ARRAY_MODE           (PHY_2_B_OF_ARRAY_MODE),
     .C_OF_ARRAY_MODE           (PHY_2_C_OF_ARRAY_MODE),
     .D_OF_ARRAY_MODE           (PHY_2_D_OF_ARRAY_MODE),
     .A_IF_ARRAY_MODE           (PHY_2_A_IF_ARRAY_MODE),
     .B_IF_ARRAY_MODE           (PHY_2_B_IF_ARRAY_MODE),
     .C_IF_ARRAY_MODE           (PHY_2_C_IF_ARRAY_MODE),
     .D_IF_ARRAY_MODE           (PHY_2_D_IF_ARRAY_MODE),
     .A_OS_DATA_RATE            (PHY_2_A_OSERDES_DATA_RATE),
     .A_OS_DATA_WIDTH           (PHY_2_A_OSERDES_DATA_WIDTH),
     .B_OS_DATA_RATE            (PHY_2_B_OSERDES_DATA_RATE),
     .B_OS_DATA_WIDTH           (PHY_2_B_OSERDES_DATA_WIDTH),
     .C_OS_DATA_RATE            (PHY_2_C_OSERDES_DATA_RATE),
     .C_OS_DATA_WIDTH           (PHY_2_C_OSERDES_DATA_WIDTH),
     .D_OS_DATA_RATE            (PHY_2_D_OSERDES_DATA_RATE),
     .D_OS_DATA_WIDTH           (PHY_2_D_OSERDES_DATA_WIDTH),
     .A_IDELAYE2_IDELAY_TYPE    (PHY_2_A_IDELAYE2_IDELAY_TYPE),
     .A_IDELAYE2_IDELAY_VALUE   (PHY_2_A_IDELAYE2_IDELAY_VALUE),
     .IODELAY_GRP               (IODELAY_GRP)
)
 phy_4lanes
(
      .rst                      (rst),
      .phy_clk                  (phy_clk_split2),
      .phy_ctl_clk              (phy_ctl_clk_split2),
      .phy_ctl_wd               (phy_ctl_wd_split2),
      .data_offset              (data_offset_2_split2),
      .phy_ctl_wr               (phy_ctl_wr_split2),
      .mem_refclk               (mem_refclk_split),
      .freq_refclk              (freq_refclk_split),
      .mem_refclk_div4          (mem_refclk_div4_split),
      .sync_pulse               (sync_pulse_split),
      .phy_dout                 (phy_dout_split2[HIGHEST_LANE_B2*80+640-1:640]),
      .phy_cmd_wr_en            (phy_cmd_wr_en_split2),
      .phy_data_wr_en           (phy_data_wr_en_split2),
      .phy_rd_en                (phy_rd_en_split2),
      .pll_lock                 (pll_lock),
      .ddr_clk                  (ddr_clk_w[2]),
      .rclk                     (rclk_w[2]),
      .rst_out                  (rst_out_w[2]),
      .mcGo                     (mcGo_w[2]),
      .idelayctrl_refclk        (idelayctrl_refclk),
      .idelay_inc               (idelay_inc),
      .idelay_ce                (idelay_ce),
      .idelay_ld                (idelay_ld),
      .phy_ctl_mstr_empty       (phy_ctl_mstr_empty),
      .if_empty_def             (if_empty_def),

      .if_a_empty               (if_a_empty_v[2]),
      .if_empty                 (if_empty_v[2]),
      .mux_i0                   (mux_i0_v[2]),
      .mux_i1                   (mux_i1_v[2]),
      .of_ctl_a_full            (of_ctl_a_full_v[2]),
      .of_data_a_full           (of_data_a_full_v[2]),
      .of_ctl_full              (of_ctl_full_v[2]),
      .of_data_full             (of_data_full_v[2]),
      .phy_din                  (phy_din[HIGHEST_LANE_B2*80+640-1:640]),
      .phy_ctl_a_full           (_phy_ctl_a_full_p[2]),
      .phy_ctl_full             (_phy_ctl_full_p[2]),
      .phy_ctl_empty            (phy_ctl_empty[2]),
      .mem_dq_out               (mem_dq_out[HIGHEST_LANE_B2*12+96-1:96]),
      .mem_dq_ts                (mem_dq_ts[HIGHEST_LANE_B2*12+96-1:96]),
      .mem_dq_in                (mem_dq_in[HIGHEST_LANE_B2*10+80-1:80]),
      .mem_dqs_out              (mem_dqs_out[HIGHEST_LANE_B2-1+8:8]),
      .mem_dqs_ts               (mem_dqs_ts[HIGHEST_LANE_B2-1+8:8]),
      .mem_dqs_in               (mem_dqs_in[HIGHEST_LANE_B2-1+8:8]),
      .aux_out                  (aux_out_[11:8]),
      .phy_ctl_ready            (phy_ctl_ready_w[2]),
      .phy_write_calib          (phy_write_calib),
      .phy_read_calib           (phy_read_calib),
//      .scan_test_bus_A          (scan_test_bus_A),
//      .scan_test_bus_B          (),
//      .scan_test_bus_C          (),
//      .scan_test_bus_D          (),
      .input_sink               (),

      .calib_sel                ({calib_zero_inputs_int[2], calib_sel[1:0]}),
      .calib_zero_ctrl          (calib_zero_ctrl[2]),
      .calib_in_common          (calib_in_common),
      .phy_encalib              (phy_encalib),
      .po_coarse_enable         (po_coarse_enable),
      .po_fine_enable           (po_fine_enable),
      .po_fine_inc              (po_fine_inc),
      .po_coarse_inc            (po_coarse_inc),
      .po_counter_load_en       (po_counter_load_en),
      .po_sel_fine_oclk_delay   (po_sel_fine_oclk_delay),
      .po_counter_load_val      (po_counter_load_val),
      .po_counter_read_en       (po_counter_read_en),
      .po_coarse_overflow       (po_coarse_overflow_w[2]),
      .po_fine_overflow         (po_fine_overflow_w[2]),
      .po_counter_read_val      (po_counter_read_val_w[2]),

      .pi_rst_dqs_find          (pi_rst_dqs_find),
      .pi_fine_enable           (pi_fine_enable),
      .pi_fine_inc              (pi_fine_inc),
      .pi_counter_load_en       (pi_counter_load_en),
      .pi_counter_read_en       (pi_counter_read_en),
      .pi_counter_load_val      (pi_counter_load_val),
      .pi_fine_overflow         (pi_fine_overflow_w[2]),
      .pi_counter_read_val      (pi_counter_read_val_w[2]),
      .pi_dqs_found             (pi_dqs_found_w[2]),
      .pi_dqs_found_all         (pi_dqs_found_all_w[2]),
      .pi_dqs_found_any         (pi_dqs_found_any_w[2]),
      .pi_dqs_out_of_range      (pi_dqs_out_of_range_w[2]),
      .pi_phase_locked          (pi_phase_locked_w[2]),
      .pi_phase_locked_all      (pi_phase_locked_all_w[2])
);
if (RCLK_SELECT_EDGE[2])
   always @(posedge rclk_w[2]  or posedge rst)  begin
     if (rst)
         aux_out[11:8] <= #1 0;
     else
         aux_out[11:8] <= #1 aux_out_[11:8];
     end
else
   always @(negedge rclk_w[2] or posedge rst)  begin
     if (rst)
         aux_out[11:8] <= #1 0;
     else
         aux_out[11:8] <= #1 aux_out_[11:8];
     end
end
else begin
   if ( HIGHEST_BANK > 2)  begin
       assign phy_din[3*320-1:640] = 0;
       assign _phy_ctl_a_full_p[2] = 0;
       assign of_ctl_a_full_v[2]   = 0;
       assign of_ctl_full_v[2]     = 0;
       assign of_data_a_full_v[2]  = 0;
       assign of_data_full_v[2]    = 0;
       assign if_empty_v[2]        = 0;
       assign mux_i0_v[2]          = 0;
       assign mux_i1_v[2]          = 0;
       always @(*)
         aux_out[11:8] = 0;
   end
       assign pi_dqs_found_w[2]    = 1;
       assign pi_dqs_found_all_w[2]    = 1;
       assign pi_dqs_found_any_w[2]    = 0;
       assign pi_dqs_out_of_range_w[2]    = 0;
       assign pi_phase_locked_w[2]    = 1;
       assign po_coarse_overflow_w[2] = 0;
       assign po_fine_overflow_w[2] = 0;
       assign po_counter_read_val_w[2] = 0;
       assign pi_counter_read_val_w[2] = 0;
end
endgenerate

generate

// emit an extra phaser_in to generate rclk
// so that rst and auxout can be placed in another region
// if desired
if ( BYTE_LANES_B1 == 0 && BYTE_LANES_B2 == 0 && RCLK_SELECT_BANK>0)
begin : phaser_in_rclk


`ifdef FUJI_PHY_BLH
B_PHASER_IN_PHY #(
`else
PHASER_IN_PHY #(
`endif
  .BURST_MODE                       ( PHY_0_A_BURST_MODE),
  .CLKOUT_DIV                       ( PHY_0_A_PI_CLKOUT_DIV),
  .FREQ_REF_DIV                     ( PHY_0_A_PI_FREQ_REF_DIV),
  .REFCLK_PERIOD                    ( FREQ_REF_PER_NS),
  .OUTPUT_CLK_SRC                   ( RCLK_PI_OUTPUT_CLK_SRC)
) phaser_in_rclk (
  .DQSFOUND                         (),
  .DQSOUTOFRANGE                    (),
  .FINEOVERFLOW                     (),
  .PHASELOCKED                      (),
  .ISERDESRST                       (),
  .ICLKDIV                          (),
  .ICLK                             (),
  .COUNTERREADVAL                   (),
  .RCLK                             (rclk_w[RCLK_SELECT_BANK]),
  .WRENABLE                         (),
  .BURSTPENDINGPHY                  (),
  .ENCALIBPHY                       (),
  .FINEENABLE                       (0),
  .FREQREFCLK                       (freq_refclk),
  .MEMREFCLK                        (mem_refclk),
  .RANKSELPHY                       (0),
  .PHASEREFCLK                      (),
  .RSTDQSFIND                       (0),
  .RST                              (rst),
  .FINEINC                          (),
  .COUNTERLOADEN                    (),
  .COUNTERREADEN                    (),
  .COUNTERLOADVAL                   (),
  .SYNCIN                           (sync_pulse),
  .SYSCLK                           (phy_clk)
);

end

endgenerate



always @(*) begin
      case (calib_sel[5:3]) 
      3'b000: begin
          po_coarse_overflow  = po_coarse_overflow_w[0];
          po_fine_overflow    = po_fine_overflow_w[0];
          po_counter_read_val = po_counter_read_val_w[0];
          pi_fine_overflow    = pi_fine_overflow_w[0];
          pi_counter_read_val = pi_counter_read_val_w[0];
          pi_phase_locked     = pi_phase_locked_w[0];
          if ( calib_in_common)
             pi_dqs_found        = pi_dqs_found_any;
          else
          pi_dqs_found        = pi_dqs_found_w[0];
          pi_dqs_out_of_range = pi_dqs_out_of_range_w[0];
        end
      3'b001: begin
          po_coarse_overflow  = po_coarse_overflow_w[1];
          po_fine_overflow    = po_fine_overflow_w[1];
          po_counter_read_val = po_counter_read_val_w[1];
          pi_fine_overflow    = pi_fine_overflow_w[1];
          pi_counter_read_val = pi_counter_read_val_w[1];
          pi_phase_locked     = pi_phase_locked_w[1];
          if ( calib_in_common)
              pi_dqs_found        = pi_dqs_found_any;
          else
          pi_dqs_found        = pi_dqs_found_w[1];
          pi_dqs_out_of_range = pi_dqs_out_of_range_w[1];
        end
      3'b010: begin
          po_coarse_overflow  = po_coarse_overflow_w[2];
          po_fine_overflow    = po_fine_overflow_w[2];
          po_counter_read_val = po_counter_read_val_w[2];
          pi_fine_overflow    = pi_fine_overflow_w[2];
          pi_counter_read_val = pi_counter_read_val_w[2];
          pi_phase_locked     = pi_phase_locked_w[2];
          if ( calib_in_common)
             pi_dqs_found        = pi_dqs_found_any;
          else
          pi_dqs_found        = pi_dqs_found_w[2];
          pi_dqs_out_of_range = pi_dqs_out_of_range_w[2];
        end
       default: begin 
          po_coarse_overflow  = 0;
          po_fine_overflow    = 0;
          po_counter_read_val = 0;
          pi_fine_overflow    = 0;
          pi_counter_read_val = 0;
          pi_phase_locked     = 0;
          pi_dqs_found        = 0;
          pi_dqs_out_of_range = 0;
        end
       endcase
end

endmodule // mc_phy
