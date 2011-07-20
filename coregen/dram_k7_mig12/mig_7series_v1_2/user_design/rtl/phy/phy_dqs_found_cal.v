//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version:
//  \   \         Application: MIG
//  /   /         Filename: phy_dqs_found_cal.v
// /___/   /\     Date Last Modified: $Date: 2011/05/27 14:31:03 $
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: 7 Series
//Design Name: DDR3 SDRAM
//Purpose:
//  Read leveling calibration logic
//  NOTES:
//    1. Phaser_In DQSFOUND calibration
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: phy_dqs_found_cal.v,v 1.7.18.2 2011/05/27 14:31:03 venkatp Exp $
**$Date: 2011/05/27 14:31:03 $
**$Author: 
**$Revision:
**$Source: 
******************************************************************************/

`timescale 1ps/1ps

module phy_dqs_found_cal #
  (
   parameter TCQ             = 100,    // clk->out delay (sim only)
   parameter nCK_PER_CLK     = 2,      // # of memory clocks per CLK
   parameter nCL             = 5,      // Read CAS latency
   parameter AL              = "0",
   parameter nCWL            = 5,      // Write CAS latency
   parameter RANKS           = 1,      // # of memory ranks in the system
   parameter DQS_CNT_WIDTH   = 3,      // = ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH       = 8,      // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,      // # of DQ per DQS
   parameter REG_CTRL         = "ON",   // "ON" for registered DIMM
   parameter NUM_DQSFOUND_CAL = 3       // Number of times to iterate
   )
  (
   input                        clk,
   input                        rst,
   input                        dqsfound_retry,
   // From phy_init
   input                        pi_dqs_found_start,
   input                        detect_pi_found_dqs,
   // From the selected byte lane Phaser_IN
   input                        pi_found_dqs,
   input                        pi_dqs_found_all,
   // Byte lane selection counter
//   output [DQS_CNT_WIDTH:0]     pi_stg1_dqs_found_cnt,
   // To All byte lane Phaser_INs simulataneously
   output reg                   pi_rst_stg1_cal,
   // To hard PHY
//   output                       stg2_done_r,
   // To phy_init
   output [5:0]                 rd_data_offset,
   output                       pi_dqs_found_rank_done,
   output                       pi_dqs_found_done,
   output reg                   pi_dqs_found_err,
   output [6*RANKS-1:0]         rd_data_offset_ranks,
   output reg                   dqsfound_retry_done,
   //To MC
   output [6*RANKS-1:0]         rd_data_offset_ranks_mc
  );
  

// For non-zero AL values
   localparam nAL = (AL == "CL-1") ? nCL - 1 : 0;   

// Adding the register dimm latency to write latency
   localparam CWL_M = (REG_CTRL == "ON") ? nCWL + nAL + 1 : nCWL + nAL;

  integer l;
  
  reg                     dqs_found_start_r;
  reg [5:0]               rd_byte_data_offset[0:RANKS-1];
//  reg [DQS_CNT_WIDTH:0]   dqs_cnt_r;
  reg                     rank_done_r;
  reg                     rank_done_r1;
  reg                     dqs_found_done_r;
  reg                     init_dqsfound_done_r;
  reg                     init_dqsfound_done_r1;
  reg                     init_dqsfound_done_r2;
  reg                     init_dqsfound_done_r3;
  reg [1:0]               rnk_cnt_r;
//  reg [5:0]               smallest_data_offset[0:RANKS-1];
  reg [5:0]               final_data_offset[0:RANKS-1];
  reg [5:0]               final_data_offset_mc[0:RANKS-1];
  reg                     reg_pi_found_dqs;
  reg                     reg_pi_found_dqs_all;
  reg                     reg_pi_found_dqs_all_r1;
  reg                     pi_rst_stg1_cal_r;
  reg [2:0]               calib_cnt;
  reg                     dqsfound_retry_r1;
  

  
  
//  assign stg2_done_r        = init_dqsfound_done_r;
  assign pi_dqs_found_rank_done    = rank_done_r;
  assign pi_dqs_found_done         = dqs_found_done_r;

  generate
  genvar rnk_cnt;
    for (rnk_cnt = 0; rnk_cnt < RANKS; rnk_cnt = rnk_cnt + 1) begin: rnk_loop
      assign rd_data_offset_ranks[6*rnk_cnt+:6] = final_data_offset[rnk_cnt];
      assign rd_data_offset_ranks_mc[6*rnk_cnt+:6] = final_data_offset_mc[rnk_cnt];
    end
  endgenerate
  
  // final_data_offset is used during write calibration and during
  // normal operation. One rd_data_offset value per rank for entire
  // interface
  assign rd_data_offset = (~init_dqsfound_done_r2) ? rd_byte_data_offset[rnk_cnt_r] :
                          final_data_offset[rnk_cnt_r];

  
   //**************************************************************************
   // DQS count to hard PHY during read data offset calibration using 
   // Phaser_IN Stage1 
   //**************************************************************************
//   assign pi_stg1_dqs_found_cnt = dqs_cnt_r;
  

  always @(posedge clk) begin
    if (rst || pi_rst_stg1_cal_r) begin
      reg_pi_found_dqs     <= #TCQ 'b0;
      reg_pi_found_dqs_all <= #TCQ 1'b0;
    end else if (pi_dqs_found_start) begin
      reg_pi_found_dqs     <= #TCQ pi_found_dqs;
      reg_pi_found_dqs_all <= #TCQ pi_dqs_found_all;
    end
  end
  
  
  always@(posedge clk)
    dqs_found_start_r <= #TCQ pi_dqs_found_start;

  always @(posedge clk) begin
    if (rst || rank_done_r)
      calib_cnt <= #TCQ 'b0;
    else if ((rd_byte_data_offset[rnk_cnt_r] < (nCL + nAL -1)) &&
             (calib_cnt < NUM_DQSFOUND_CAL))
      calib_cnt <= #TCQ calib_cnt + 1;
    else
      calib_cnt <= #TCQ calib_cnt;
  end      

  // Read data offset value calib all DQSs simulataneously
  always @(posedge clk) begin
    if (rst || dqsfound_retry) begin
      for (l = 0; l < RANKS; l = l + 1) begin: rst_rd_data_offset_loop
        rd_byte_data_offset[l] <= #TCQ nCL + nAL + 13;
      end
    end else if ((rank_done_r1 && ~init_dqsfound_done_r) ||
       (rd_byte_data_offset[rnk_cnt_r] < (nCL + nAL -1))) begin
          rd_byte_data_offset[rnk_cnt_r] <= #TCQ nCL + nAL + 13;
    end else if (dqs_found_start_r && ~reg_pi_found_dqs_all &&
             detect_pi_found_dqs && ~init_dqsfound_done_r)
      rd_byte_data_offset[rnk_cnt_r] 
      <= #TCQ rd_byte_data_offset[rnk_cnt_r] - 1;
  end
  

  always @(posedge clk) begin
    if (rst)
      rnk_cnt_r <= #TCQ 2'b00;
    else if (init_dqsfound_done_r)
      rnk_cnt_r <= #TCQ rnk_cnt_r;
    else if (rank_done_r)
      rnk_cnt_r <= #TCQ rnk_cnt_r + 1;
  end
  
  //*****************************************************************
  // Read data_offset calibration done signal
  //*****************************************************************
  
  always @(posedge clk) begin
    if (rst || pi_rst_stg1_cal_r)
      init_dqsfound_done_r  <= #TCQ 1'b0;
    else if (reg_pi_found_dqs_all && ~reg_pi_found_dqs_all_r1) begin
      if (rnk_cnt_r == RANKS-1)
        init_dqsfound_done_r  <= #TCQ 1'b1;
      else
        init_dqsfound_done_r  <= #TCQ 1'b0;
    end
  end
  
  always @(posedge clk) begin
    if (rst  || pi_rst_stg1_cal_r ||
       (init_dqsfound_done_r && (rnk_cnt_r == RANKS-1)))
      rank_done_r       <= #TCQ 1'b0;
    else if (reg_pi_found_dqs_all && ~reg_pi_found_dqs_all_r1)
      rank_done_r <= #TCQ 1'b1;
    else
      rank_done_r       <= #TCQ 1'b0;
  end
  
  always @(posedge clk) begin
    init_dqsfound_done_r1   <= #TCQ init_dqsfound_done_r;
    init_dqsfound_done_r2   <= #TCQ init_dqsfound_done_r1;
    init_dqsfound_done_r3   <= #TCQ init_dqsfound_done_r2;
    reg_pi_found_dqs_all_r1 <= #TCQ reg_pi_found_dqs_all;
    rank_done_r1            <= #TCQ rank_done_r;
    dqsfound_retry_r1       <= #TCQ dqsfound_retry;
  end

  always @(posedge clk) begin
    if (rst || dqsfound_retry || dqsfound_retry_r1 || pi_rst_stg1_cal_r)
      dqsfound_retry_done <= #TCQ 1'b0;
    else if (init_dqsfound_done_r)
      dqsfound_retry_done <= #TCQ 1'b1;
  end
  
  always @(posedge clk) begin
    if (rst)
      dqs_found_done_r <= #TCQ 1'b0;
    else if (reg_pi_found_dqs_all && (rnk_cnt_r == RANKS-1) && init_dqsfound_done_r1)
      dqs_found_done_r <= #TCQ 1'b1;
    else
      dqs_found_done_r <= #TCQ 1'b0;
  end
  

  
  // Reset read data offset calibration in all DQS Phaser_INs
  // after the read data offset value for a rank is determined
  // or if within a rank DQSFOUND is not asserted for all DQSs
  always @(posedge clk) begin
    if (rst || pi_rst_stg1_cal_r)
      pi_rst_stg1_cal <= #TCQ 1'b0;
    else if ((pi_dqs_found_start && ~dqs_found_start_r) ||
             (dqsfound_retry) ||
             (reg_pi_found_dqs && ~pi_dqs_found_all) ||
             (rd_byte_data_offset[rnk_cnt_r] < (nCL + nAL -1)))
      pi_rst_stg1_cal <= #TCQ 1'b1;
//    else
//      pi_rst_stg1_cal <= #TCQ 1'b0;
  end
  
  always @(posedge clk)
    pi_rst_stg1_cal_r     <= #TCQ pi_rst_stg1_cal;

  
  // Determine smallest rd_data_offset value per rank and assign it as the
  // Final read data offset value to be used during write calibration and
  // normal operation
  generate
  genvar i;
    for (i = 0; i < RANKS; i = i + 1) begin: smallest_final_loop
      always @(posedge clk) begin
        if (rst)
          final_data_offset[i]    <= #TCQ 'b0;
        else if (dqsfound_retry)
          final_data_offset[i] <= #TCQ rd_byte_data_offset[i];
        else if (init_dqsfound_done_r && ~init_dqsfound_done_r1) begin
          final_data_offset[i] <= #TCQ rd_byte_data_offset[i];
          if (CWL_M % 2) // odd latency CAS slot 1
            final_data_offset_mc[i] <= #TCQ rd_byte_data_offset[i] - 1;
          else // even latency CAS slot 0
            final_data_offset_mc[i] <= #TCQ rd_byte_data_offset[i];
        end
      end
    end
  endgenerate

  
  // Error generation in case pi_found_dqs signal from Phaser_IN
  // is not asserted when a common rddata_offset value is used
  always @(posedge clk) begin
    if (rst)
      pi_dqs_found_err <= #TCQ 1'b0;
    else if (!reg_pi_found_dqs_all && (calib_cnt == NUM_DQSFOUND_CAL) &&
            (rd_byte_data_offset[rnk_cnt_r] < (nCL + nAL -1)))
      pi_dqs_found_err <= #TCQ 1'b1;
  end
  
  
endmodule
           
        
      
       

      
