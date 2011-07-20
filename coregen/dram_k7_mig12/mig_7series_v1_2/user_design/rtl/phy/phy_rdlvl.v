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
//  /   /         Filename: phy_rdlvl.v
// /___/   /\     Date Last Modified: $Date: 2011/05/27 14:31:03 $
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: 7 Series
//Design Name: DDR3 SDRAM
//Purpose:
//  Read leveling Stage1 calibration logic
//  NOTES:
//    1. Window detection with PRBS pattern.
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: phy_rdlvl.v,v 1.16.16.2 2011/05/27 14:31:03 venkatp Exp $
**$Date: 2011/05/27 14:31:03 $
**$Author: venkatp $
**$Revision: 1.16.16.2 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_2/data/dlib/7series/ddr3_sdram/verilog/rtl/phy/phy_rdlvl.v,v $
******************************************************************************/

`timescale 1ps/1ps

module phy_rdlvl #
  (
   parameter TCQ             = 100,    // clk->out delay (sim only)
   parameter nCK_PER_CLK     = 2,      // # of memory clocks per CLK
   parameter CLK_PERIOD      = 3333,   // Internal clock period (in ps)
   parameter DQ_WIDTH        = 64,     // # of DQ (data)
   parameter DQS_CNT_WIDTH   = 3,      // = ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH       = 8,      // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,      // # of DQ per DQS
   parameter RANKS           = 1,      // # of DRAM ranks
   parameter PER_BIT_DESKEW  = "ON",   // Enable per-bit DQ deskew
   parameter SIM_CAL_OPTION  = "NONE", // Skip various calibration steps
   parameter DEBUG_PORT      = "OFF"   // Enable debug port
   )
  (
   input                        clk,
   input                        rst,
   // Calibration status, control signals
   input                        rdlvl_stg1_start,
   output reg                   rdlvl_stg1_done,
   output                       rdlvl_stg1_rnk_done,
   output reg                   rdlvl_stg1_err,
   output reg                   rdlvl_prech_req,
   output reg                   rdlvl_last_byte_done,
   input                        prech_done,
   input                        phy_if_empty,
   // Captured data in fabric clock domain
   input [2*nCK_PER_CLK*DQ_WIDTH-1:0] rd_data,
   // Stage 1 calibration outputs
   output reg                   pi_en_stg2_f,
   output reg                   pi_stg2_f_incdec,
   output reg                   pi_stg2_load,
   output reg [5:0]             pi_stg2_reg_l,
   output reg [DQS_CNT_WIDTH:0] pi_stg2_rdlvl_cnt,
   // To DQ IDELAY required if DQS less than half bit
   // time away from right edge
   output                       idelay_ce,
   output                       idelay_inc,
   // Only output if Per-bit de-skew enabled
   output reg [5*RANKS*DQ_WIDTH-1:0] dlyval_dq,
   // Debug Port
   output [5*DQS_WIDTH-1:0]     dbg_cpt_first_edge_cnt,
   output [5*DQS_WIDTH-1:0]     dbg_cpt_second_edge_cnt,
   input                        dbg_idel_up_all,
   input                        dbg_idel_down_all,
   input                        dbg_idel_up_cpt,
   input                        dbg_idel_down_cpt,
   input [DQS_CNT_WIDTH-1:0]    dbg_sel_idel_cpt,
   input                        dbg_sel_all_idel_cpt,
   output [255:0]               dbg_phy_rdlvl
   );

  // minimum time (in IDELAY taps) for which capture data must be stable for
  // algorithm to consider a valid data eye to be found. The read leveling 
  // logic will ignore any window found smaller than this value. Limitations
  // on how small this number can be is determined by: (1) the algorithmic
  // limitation of how many taps wide the data eye can be (3 taps), and (2)
  // how wide regions of "instability" that occur around the edges of the
  // read valid window can be (i.e. need to be able to filter out "false"
  // windows that occur for a short # of taps around the edges of the true
  // data window, although with multi-sampling during read leveling, this is
  // not as much a concern) - the larger the value, the more protection 
  // against "false" windows  
  localparam MIN_EYE_SIZE = 8;

  // Length of calibration sequence (in # of words)
  localparam CAL_PAT_LEN = 8;
  // Read data shift register length
  localparam RD_SHIFT_LEN = CAL_PAT_LEN / (2*nCK_PER_CLK);

  // # of cycles required to perform read data shift register compare
  // This is defined as from the cycle the new data is loaded until
  // signal found_edge_r is valid
  localparam RD_SHIFT_COMP_DELAY = 5;

  // worst-case # of cycles to wait to ensure that both the SR and 
  // PREV_SR shift registers have valid data, and that the comparison 
  // of the two shift register values is valid. The "+1" at the end of
  // this equation is a fudge factor, I freely admit that
  localparam SR_VALID_DELAY = (2 * RD_SHIFT_LEN) + RD_SHIFT_COMP_DELAY + 1;

  // # of clock cycles to wait after changing tap value or read data MUX 
  // to allow: (1) tap chain to settle, (2) for delayed input to propagate 
  // thru ISERDES, (3) for the read data comparison logic to have time to
  // output the comparison of two consecutive samples of the settled read data
  // The minimum delay is 16 cycles, which should be good enough to handle all
  // three of the above conditions for the simulation-only case with a short
  // training pattern. For H/W (or for simulation with longer training 
  // pattern), it will take longer to store and compare two consecutive 
  // samples, and the value of this parameter will reflect that
  localparam PIPE_WAIT_CNT = (SR_VALID_DELAY < 8) ? 16 : (SR_VALID_DELAY + 8);

  // # of read data samples to examine when detecting whether an edge has 
  // occured during stage 1 calibration. Width of local param must be
  // changed as appropriate. Note that there are two counters used, each
  // counter can be changed independently of the other - they are used in
  // cascade to create a larger counter
  localparam [11:0] DETECT_EDGE_SAMPLE_CNT0 = 12'h001; //12'hFFF;
  localparam [11:0] DETECT_EDGE_SAMPLE_CNT1 = 12'h001;   // Must be > 0
  
  localparam [4:0] CAL1_IDLE                 = 5'h00;
  localparam [4:0] CAL1_NEW_DQS_WAIT         = 5'h01;
  localparam [4:0] CAL1_STORE_FIRST_WAIT     = 5'h02;
  localparam [4:0] CAL1_DETECT_EDGE          = 5'h03;
  localparam [4:0] CAL1_IDEL_INC_CPT         = 5'h04;
  localparam [4:0] CAL1_IDEL_INC_CPT_WAIT    = 5'h05;
  localparam [4:0] CAL1_CALC_IDEL            = 5'h06;
  localparam [4:0] CAL1_IDEL_DEC_CPT         = 5'h07;
  localparam [4:0] CAL1_IDEL_DEC_CPT_WAIT    = 5'h08;
  localparam [4:0] CAL1_DQ_IDEL_TAP_INC      = 5'h09;
  localparam [4:0] CAL1_DQ_IDEL_TAP_INC_WAIT = 5'h0A;
  localparam [4:0] CAL1_NEXT_DQS             = 5'h0B;
  localparam [4:0] CAL1_DONE                 = 5'h0C;
  localparam [4:0] CAL1_PB_STORE_FIRST_WAIT  = 5'h0D;
  localparam [4:0] CAL1_PB_DETECT_EDGE       = 5'h0E;
  localparam [4:0] CAL1_PB_INC_CPT           = 5'h0F;
  localparam [4:0] CAL1_PB_INC_CPT_WAIT      = 5'h10;
  localparam [4:0] CAL1_PB_DEC_CPT_LEFT      = 5'h11;
  localparam [4:0] CAL1_PB_DEC_CPT_LEFT_WAIT = 5'h12;
  localparam [4:0] CAL1_PB_DETECT_EDGE_DQ    = 5'h13;
  localparam [4:0] CAL1_PB_INC_DQ            = 5'h14;
  localparam [4:0] CAL1_PB_INC_DQ_WAIT       = 5'h15;
  localparam [4:0] CAL1_PB_DEC_CPT           = 5'h16;
  localparam [4:0] CAL1_PB_DEC_CPT_WAIT      = 5'h17;
  localparam [4:0] CAL1_REGL_LOAD            = 5'h18;

  integer    i;
  integer    j;
  integer    k;
  integer    l;
  integer    m;
  integer    n;
  integer    r;
  integer    p;
  integer    q;
  genvar     x;
  genvar     z;
  
  reg [DQS_CNT_WIDTH:0]   cal1_cnt_cpt_r;
  wire [DQS_CNT_WIDTH+2:0]cal1_cnt_cpt_timing;
  reg                     cal1_dq_idel_ce;
  reg                     cal1_dq_idel_inc;
  reg                     cal1_dlyce_cpt_r;
  reg                     cal1_dlyinc_cpt_r;
  reg                     cal1_dlyce_dq_r;
  reg                     cal1_dlyinc_dq_r;
  reg                     cal1_wait_cnt_en_r;  
  reg [4:0]               cal1_wait_cnt_r;                
  reg                     cal1_wait_r;
  reg [DQ_WIDTH-1:0]      dlyce_dq_r;
  reg                     dlyinc_dq_r;  
  reg [5*DQ_WIDTH*RANKS-1:0] dlyval_dq_reg_r;
  reg                     cal1_prech_req_r;
  reg [4:0]               cal1_state_r;
  reg [4:0]               cal1_state_r1;
  reg [5:0]               cnt_idel_dec_cpt_r;
  reg [3:0]               cnt_shift_r;
  reg                     detect_edge_done_r;  
  reg [5:0]               first_edge_taps_r;
  reg                     found_edge_r;
  reg                     found_first_edge_r;
  reg                     found_second_edge_r;
  reg                     found_stable_eye_r;
  reg                     found_stable_eye_last_r;
  reg                     found_edge_all_r;
  reg [5:0]               tap_cnt_cpt_r;
  reg                     tap_limit_cpt_r;
  reg [4:0]               idel_tap_cnt_dq_pb_r;
  reg                     idel_tap_limit_dq_pb_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall3_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise3_r;
  reg                     mux_rd_valid_r;
  reg                     new_cnt_cpt_r;
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  old_sr_rise3_r [DRAM_WIDTH-1:0];
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall0_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall1_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise0_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise1_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall2_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_fall3_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise2_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_rise3_r;
  reg [2:0]               pb_cnt_eye_size_r [DRAM_WIDTH-1:0];
  reg [DRAM_WIDTH-1:0]    pb_detect_edge_done_r;
  reg [DRAM_WIDTH-1:0]    pb_found_edge_last_r;  
  reg [DRAM_WIDTH-1:0]    pb_found_edge_r;
  reg [DRAM_WIDTH-1:0]    pb_found_first_edge_r;  
  reg [DRAM_WIDTH-1:0]    pb_found_stable_eye_r;
  reg [DRAM_WIDTH-1:0]    pb_last_tap_jitter_r;
  reg 			  pi_en_stg2_f_timing;
  reg 			  pi_stg2_f_incdec_timing;
  reg 			  pi_stg2_load_timing;
  reg [5:0] 		  pi_stg2_reg_l_timing;
  reg [DRAM_WIDTH-1:0]    prev_sr_diff_r;
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  prev_sr_rise3_r [DRAM_WIDTH-1:0];
  reg [DRAM_WIDTH-1:0]    prev_sr_match_cyc2_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall0_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall1_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise0_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise1_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall2_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_fall3_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise2_r;
  reg [DRAM_WIDTH-1:0]    prev_sr_match_rise3_r;
  wire [DQ_WIDTH-1:0]     rd_data_rise0;
  wire [DQ_WIDTH-1:0]     rd_data_fall0;
  wire [DQ_WIDTH-1:0]     rd_data_rise1;
  wire [DQ_WIDTH-1:0]     rd_data_fall1;
  wire [DQ_WIDTH-1:0]     rd_data_rise2;
  wire [DQ_WIDTH-1:0]     rd_data_fall2;
  wire [DQ_WIDTH-1:0]     rd_data_rise3;
  wire [DQ_WIDTH-1:0]     rd_data_fall3;
  reg                     samp_cnt_done_r;
  reg                     samp_edge_cnt0_en_r;
  reg [11:0]              samp_edge_cnt0_r;
  reg                     samp_edge_cnt1_en_r;
  reg [11:0]              samp_edge_cnt1_r;
//  reg [4:0]               second_edge_dq_taps_r;
  reg [DQS_CNT_WIDTH:0]   rd_mux_sel_r;
  reg [5:0]               second_edge_taps_r;
  reg [RD_SHIFT_LEN-1:0]  sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise3_r [DRAM_WIDTH-1:0];
  reg                     store_sr_r;
  reg                     store_sr_req_pulsed_r;
  reg                     store_sr_req_r;
  reg                     sr_valid_r;
  reg                     sr_valid_r1;
  reg                     sr_valid_r2;
  reg [DRAM_WIDTH-1:0]    old_sr_diff_r;
  reg [DRAM_WIDTH-1:0]    old_sr_match_cyc2_r;
  
  reg [6*DQS_WIDTH*RANKS-1:0] rdlvl_dqs_tap_cnt_r;
  reg [1:0]               rnk_cnt_r;
  reg                     rdlvl_rank_done_r;
  
  reg [3:0]               done_cnt;
  reg [1:0]               regl_rank_cnt;
  reg [DQS_CNT_WIDTH:0]   regl_dqs_cnt;
  wire [DQS_CNT_WIDTH+2:0]regl_dqs_cnt_timing;
  reg                     regl_rank_done_r;
  reg                     rdlvl_stg1_start_r;

  // Debug
  reg [4:0]               dbg_cpt_first_edge_taps [0:DQS_WIDTH-1];
  reg [4:0]               dbg_cpt_second_edge_taps [0:DQS_WIDTH-1];

  //***************************************************************************
  // Debug
  //***************************************************************************

  assign dbg_phy_rdlvl[0]      = rdlvl_stg1_start;
  assign dbg_phy_rdlvl[1]      = 'b0;
  assign dbg_phy_rdlvl[2]      = found_edge_r;
  assign dbg_phy_rdlvl[3]      = 'b0;
  assign dbg_phy_rdlvl[6:4]    = 'b0;
  assign dbg_phy_rdlvl[8:7]    = 'b0;
  assign dbg_phy_rdlvl[13:9]   = cal1_state_r[4:0];
  assign dbg_phy_rdlvl[20:14]  = cnt_idel_dec_cpt_r;
  assign dbg_phy_rdlvl[21]     = found_first_edge_r;
  assign dbg_phy_rdlvl[22]     = found_second_edge_r;
  assign dbg_phy_rdlvl[23]     = 'b0;
  assign dbg_phy_rdlvl[24]     = store_sr_r;
  // [40:25] previously used for sr, old_sr shift registers. If connecting
  // these signals again, don't forget to parameterize based on RD_SHIFT_LEN
  assign dbg_phy_rdlvl[40:25]  = 'b0;   
  assign dbg_phy_rdlvl[41]     = sr_valid_r;
  assign dbg_phy_rdlvl[42]     = found_stable_eye_r;
  assign dbg_phy_rdlvl[48:43]  = tap_cnt_cpt_r;
  assign dbg_phy_rdlvl[54:49]  = first_edge_taps_r;
  assign dbg_phy_rdlvl[60:55]  = second_edge_taps_r;
  assign dbg_phy_rdlvl[64:61]  = cal1_cnt_cpt_r;
  assign dbg_phy_rdlvl[65]     = cal1_dlyce_cpt_r;
  assign dbg_phy_rdlvl[66]     = cal1_dlyinc_cpt_r;
  assign dbg_phy_rdlvl[67]     = found_edge_r;
  assign dbg_phy_rdlvl[68]     = found_first_edge_r;
  assign dbg_phy_rdlvl[255:69] = 'b0;
  
  //***************************************************************************
  // Debug output
  //***************************************************************************

  // Record first and second edges found during CPT calibration
  generate
    genvar ce_i;
    for (ce_i = 0; ce_i < DQS_WIDTH; ce_i = ce_i + 1) begin: gen_dbg_cpt_edge
      assign dbg_cpt_first_edge_cnt[(5*ce_i)+4:(5*ce_i)]
               = dbg_cpt_first_edge_taps[ce_i];
      assign dbg_cpt_second_edge_cnt[(5*ce_i)+4:(5*ce_i)]
               = dbg_cpt_second_edge_taps[ce_i];
      always @(posedge clk)
        if (rst) begin
          dbg_cpt_first_edge_taps[ce_i]  <= #TCQ 'b0;
          dbg_cpt_second_edge_taps[ce_i] <= #TCQ 'b0;
        end else begin
          // Record tap counts of first and second edge edges during
          // CPT calibration for each DQS group. If neither edge has
          // been found, then those taps will remain 0
          if (cal1_state_r == CAL1_CALC_IDEL) begin
            if (found_first_edge_r && (cal1_cnt_cpt_r == ce_i))
              dbg_cpt_first_edge_taps[ce_i]  
                <= #TCQ first_edge_taps_r;
            if (found_second_edge_r && (cal1_cnt_cpt_r == ce_i))
              dbg_cpt_second_edge_taps[ce_i] 
                <= #TCQ second_edge_taps_r;
          end
        end
    end
  endgenerate

  assign rdlvl_stg1_rnk_done = rdlvl_rank_done_r;// || regl_rank_done_r;
  
   //**************************************************************************
   // DQS count to hard PHY during write calibration using Phaser_OUT Stage2
   // coarse delay 
   //**************************************************************************
   always @(posedge clk)
     if (cal1_state_r == CAL1_REGL_LOAD)
       pi_stg2_rdlvl_cnt <= #TCQ regl_dqs_cnt;
     else
       pi_stg2_rdlvl_cnt <= #TCQ cal1_cnt_cpt_r;

   assign idelay_ce  = cal1_dq_idel_ce;
   assign idelay_inc = cal1_dq_idel_inc;

  //***************************************************************************
  // Data mux to route appropriate bit to calibration logic - i.e. calibration
  // is done sequentially, one bit (or DQS group) at a time
  //***************************************************************************

  generate
    if (nCK_PER_CLK == 4) begin: rd_data_div4_logic_clk
      assign rd_data_rise0 = rd_data[DQ_WIDTH-1:0];
      assign rd_data_fall0 = rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
      assign rd_data_rise1 = rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
      assign rd_data_fall1 = rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
      assign rd_data_rise2 = rd_data[5*DQ_WIDTH-1:4*DQ_WIDTH];
      assign rd_data_fall2 = rd_data[6*DQ_WIDTH-1:5*DQ_WIDTH];
      assign rd_data_rise3 = rd_data[7*DQ_WIDTH-1:6*DQ_WIDTH];
      assign rd_data_fall3 = rd_data[8*DQ_WIDTH-1:7*DQ_WIDTH];
    end else begin: rd_data_div2_logic_clk
      assign rd_data_rise0 = rd_data[DQ_WIDTH-1:0];
      assign rd_data_fall0 = rd_data[2*DQ_WIDTH-1:DQ_WIDTH];
      assign rd_data_rise1 = rd_data[3*DQ_WIDTH-1:2*DQ_WIDTH];
      assign rd_data_fall1 = rd_data[4*DQ_WIDTH-1:3*DQ_WIDTH];
    end
  endgenerate

  always @(posedge clk) begin
    rd_mux_sel_r <= #TCQ cal1_cnt_cpt_r;
  end

  // Register outputs for improved timing.
  // NOTE: Will need to change when per-bit DQ deskew is supported.
  //       Currenly all bits in DQS group are checked in aggregate
  generate
    genvar mux_i;
    for (mux_i = 0; mux_i < DRAM_WIDTH; mux_i = mux_i + 1) begin: gen_mux_rd
      always @(posedge clk) begin
        mux_rd_rise0_r[mux_i] <= #TCQ rd_data_rise0[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_fall0_r[mux_i] <= #TCQ rd_data_fall0[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_rise1_r[mux_i] <= #TCQ rd_data_rise1[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_fall1_r[mux_i] <= #TCQ rd_data_fall1[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_rise2_r[mux_i] <= #TCQ rd_data_rise2[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_fall2_r[mux_i] <= #TCQ rd_data_fall2[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_rise3_r[mux_i] <= #TCQ rd_data_rise3[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];
        mux_rd_fall3_r[mux_i] <= #TCQ rd_data_fall3[DRAM_WIDTH*rd_mux_sel_r + 
                                                    mux_i];     
      end
    end
  endgenerate

  // Registered signal indicates when mux_rd_rise/fall_r is valid
  always @(posedge clk)
    mux_rd_valid_r <= #TCQ ~phy_if_empty;
  
  //***************************************************************************
  // Demultiplexor to control Phaser_IN delay values
  //***************************************************************************

  // Read DQS
  always @(posedge clk) begin
    if (rst) begin
      pi_en_stg2_f_timing     <= #TCQ 'b0;
      pi_stg2_f_incdec_timing <= #TCQ 'b0;
    end else if (cal1_dlyce_cpt_r) begin
      if ((SIM_CAL_OPTION == "NONE") ||
          (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
        // Change only specified DQS
        pi_en_stg2_f_timing     <= #TCQ 1'b1;  
        pi_stg2_f_incdec_timing <= #TCQ cal1_dlyinc_cpt_r;
      end else if (SIM_CAL_OPTION == "FAST_CAL") begin 
        // if simulating, and "shortcuts" for calibration enabled, apply 
        // results to all DQSs (i.e. assume same delay on all 
        // DQSs).
        pi_en_stg2_f_timing     <= #TCQ 1'b1;
        pi_stg2_f_incdec_timing <= #TCQ cal1_dlyinc_cpt_r;
      end
    end else begin
      pi_en_stg2_f_timing     <= #TCQ 'b0;
      pi_stg2_f_incdec_timing <= #TCQ 'b0;
    end
  end

  // registered for timing 
  always @(posedge clk) begin
    pi_en_stg2_f     <= #TCQ pi_en_stg2_f_timing;
    pi_stg2_f_incdec <= #TCQ pi_stg2_f_incdec_timing;
  end
  
   // This counter used to implement settling time between
   // Phaser_IN rank register loads to different DQSs
   always @(posedge clk) begin
     if (rst)
       done_cnt <= #TCQ 'b0;
     else if (((cal1_state_r == CAL1_REGL_LOAD) && 
               (cal1_state_r1 == CAL1_NEXT_DQS)) ||
              ((done_cnt == 4'd1) && (cal1_state_r != CAL1_DONE)))
       done_cnt <= #TCQ 4'b1010;
     else if (done_cnt > 'b0)
       done_cnt <= #TCQ done_cnt - 1;
   end

   // During rank register loading the rank count must be sent to
   // Phaser_IN via the phy_ctl_wd?? If so phy_init will have to 
   // issue NOPs during rank register loading with the appropriate
   // rank count
   always @(posedge clk) begin
     if (rst || (regl_rank_done_r == 1'b1))
       regl_rank_done_r <= #TCQ 1'b0;
     else if ((regl_dqs_cnt == DQS_WIDTH-1) &&
              (regl_rank_cnt != RANKS-1) &&
              (done_cnt == 4'd1))
       regl_rank_done_r <= #TCQ 1'b1;
   end

   // Temp wire for timing.
   // The following in the always block below causes timing issues
   // due to DSP block inference
   // 6*regl_dqs_cnt.
   // replacing this with two left shifts + 1 left shift to avoid
   // DSP multiplier. 
   assign regl_dqs_cnt_timing = {2'd0, regl_dqs_cnt};
   
   // Load Phaser_OUT rank register with rdlvl delay value
   // for each DQS per rank.
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0)) begin
       pi_stg2_load_timing    <= #TCQ 'b0;
       pi_stg2_reg_l_timing   <= #TCQ 'b0;
     end else if ((cal1_state_r == CAL1_REGL_LOAD) && 
                  (regl_dqs_cnt <= DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       pi_stg2_load_timing  <= #TCQ 'b1;
       pi_stg2_reg_l_timing <= #TCQ 
         rdlvl_dqs_tap_cnt_r[(((regl_dqs_cnt_timing<<2) + (regl_dqs_cnt_timing<<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6];
     end else begin
       pi_stg2_load_timing  <= #TCQ 'b0;
       pi_stg2_reg_l_timing <= #TCQ 'b0;
     end
   end 

   // registered for timing 
   always @(posedge clk) begin
     pi_stg2_load  <= #TCQ pi_stg2_load_timing;
     pi_stg2_reg_l <= #TCQ pi_stg2_reg_l_timing;
   end 

   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0))
       regl_rank_cnt   <= #TCQ 2'b00;
     else if ((cal1_state_r == CAL1_REGL_LOAD) && 
              (regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       if (regl_rank_cnt == RANKS-1)
         regl_rank_cnt  <= #TCQ regl_rank_cnt;
       else
         regl_rank_cnt <= #TCQ regl_rank_cnt + 1;
     end
   end
   
   always @(posedge clk) begin
     if (rst || (done_cnt == 4'd0))
       regl_dqs_cnt    <= #TCQ {DQS_CNT_WIDTH+1{1'b0}};
     else if ((cal1_state_r == CAL1_REGL_LOAD) && 
              (regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1)) begin
       if (regl_rank_cnt == RANKS-1)
         regl_dqs_cnt  <= #TCQ regl_dqs_cnt;
       else
         regl_dqs_cnt  <= #TCQ 'b0;
     end else if ((cal1_state_r == CAL1_REGL_LOAD) && (regl_dqs_cnt != DQS_WIDTH-1)
                  && (done_cnt == 4'd1))
       regl_dqs_cnt  <= #TCQ regl_dqs_cnt + 1;
     else
       regl_dqs_cnt  <= #TCQ regl_dqs_cnt;
   end

  //*****************************************************************
  // DQ Stage 1 CALIBRATION INCREMENT/DECREMENT LOGIC:
  // The actual IDELAY elements for each of the DQ bits is set via the
  // DLYVAL parallel load port. However, the stage 1 calibration
  // algorithm (well most of it) only needs to increment or decrement the DQ
  // IDELAY value by 1 at any one time.
  //*****************************************************************

  // Chip-select generation for each of the individual counters tracking
  // IDELAY tap values for each DQ
  generate
    for (z = 0; z < DQS_WIDTH; z = z + 1) begin: gen_dlyce_dq
      always @(posedge clk)
        if (rst)
          dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
        else
          if (SIM_CAL_OPTION == "SKIP_CAL")
            // If skipping calibration altogether (only for simulation), no
            // need to set DQ IODELAY values - they are hardcoded
            dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
          else if (SIM_CAL_OPTION == "FAST_CAL")
            // If fast calibration option (simulation only) selected, DQ
            // IODELAYs across all bytes are updated simultaneously
            // (although per-bit deskew within DQS[0] is still supported)
            dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ cal1_dlyce_dq_r;
          else if ((SIM_CAL_OPTION == "NONE") ||
                   (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin 
            if (cal1_cnt_cpt_r == z)
              dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] 
                <= #TCQ cal1_dlyce_dq_r;
            else
              dlyce_dq_r[DRAM_WIDTH*z+:DRAM_WIDTH] <= #TCQ 'b0;
          end
    end
  endgenerate

  // Also delay increment/decrement control to match delay on DLYCE
  always @(posedge clk)
    if (rst)
      dlyinc_dq_r <= #TCQ 1'b0;
    else
      dlyinc_dq_r <= #TCQ cal1_dlyinc_dq_r;  


  // Each DQ has a counter associated with it to record current read-leveling
  // delay value
  always @(posedge clk)
    // Reset or skipping calibration all together
    if (rst | (SIM_CAL_OPTION == "SKIP_CAL")) begin
      dlyval_dq_reg_r <= #TCQ 'b0;
    end else if (SIM_CAL_OPTION == "FAST_CAL") begin
      for (n = 0; n < RANKS; n = n + 1) begin: gen_dlyval_dq_reg_rnk
        for (r = 0; r < DQ_WIDTH; r = r + 1) begin: gen_dlyval_dq_reg
          if (dlyce_dq_r[r]) begin     
            if (dlyinc_dq_r)
              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] + 1;
            else
              dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] 
              <= #TCQ dlyval_dq_reg_r[((5*r)+(n*DQ_WIDTH*5))+:5] - 1;
          end
        end
      end
    end else begin
      if (dlyce_dq_r[cal1_cnt_cpt_r]) begin     
        if (dlyinc_dq_r)
          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] 
          <= #TCQ 
          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] + 1;
        else
          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] 
          <= #TCQ 
          dlyval_dq_reg_r[((5*cal1_cnt_cpt_r)+(rnk_cnt_r*5*DQ_WIDTH))+:5] - 1;
      end
    end

  // Register for timing (help with logic placement)
  always @(posedge clk) begin 
    dlyval_dq <= #TCQ dlyval_dq_reg_r;
  end
  
  //***************************************************************************
  // Generate signal used to delay calibration state machine - used when:
  //  (1) IDELAY value changed
  //  (2) RD_MUX_SEL value changed
  // Use when a delay is necessary to give the change time to propagate
  // through the data pipeline (through IDELAY and ISERDES, and fabric
  // pipeline stages)
  //***************************************************************************

      
  // List all the stage 1 calibration wait states here.
  always @(posedge clk)
    if ((cal1_state_r == CAL1_NEW_DQS_WAIT) ||
        (cal1_state_r == CAL1_PB_STORE_FIRST_WAIT) ||
        (cal1_state_r == CAL1_PB_INC_CPT_WAIT) ||
        (cal1_state_r == CAL1_PB_DEC_CPT_LEFT_WAIT) ||
        (cal1_state_r == CAL1_PB_INC_DQ_WAIT) ||
        (cal1_state_r == CAL1_PB_DEC_CPT_WAIT) ||
        (cal1_state_r == CAL1_IDEL_INC_CPT_WAIT) ||
        (cal1_state_r == CAL1_STORE_FIRST_WAIT) ||
        (cal1_state_r == CAL1_DQ_IDEL_TAP_INC_WAIT))
      cal1_wait_cnt_en_r <= #TCQ 1'b1;
    else
      cal1_wait_cnt_en_r <= #TCQ 1'b0;

  always @(posedge clk)
    if (!cal1_wait_cnt_en_r) begin
      cal1_wait_cnt_r <= #TCQ 4'b0000;
      cal1_wait_r     <= #TCQ 1'b1;
    end else begin
      if (cal1_wait_cnt_r != PIPE_WAIT_CNT - 1) begin
        cal1_wait_cnt_r <= #TCQ cal1_wait_cnt_r + 1;
        cal1_wait_r     <= #TCQ 1'b1;
      end else begin
        // Need to reset to 0 to handle the case when there are two
        // different WAIT states back-to-back
        cal1_wait_cnt_r <= #TCQ 4'b0000;        
        cal1_wait_r     <= #TCQ 1'b0;
      end
    end  

  //***************************************************************************
  // generate request to PHY_INIT logic to issue precharged. Required when
  // calibration can take a long time (during which there are only constant
  // reads present on this bus). In this case need to issue perioidic
  // precharges to avoid tRAS violation. This signal must meet the following
  // requirements: (1) only transition from 0->1 when prech is first needed,
  // (2) stay at 1 and only transition 1->0 when RDLVL_PRECH_DONE asserted
  //***************************************************************************

  always @(posedge clk)
    if (rst)
      rdlvl_prech_req <= #TCQ 1'b0;
    else
      rdlvl_prech_req <= #TCQ cal1_prech_req_r;

  //***************************************************************************
  // Serial-to-parallel register to store last RDDATA_SHIFT_LEN cycles of 
  // data from ISERDES. The value of this register is also stored, so that
  // previous and current values of the ISERDES data can be compared while
  // varying the IODELAY taps to see if an "edge" of the data valid window
  // has been encountered since the last IODELAY tap adjustment 
  //***************************************************************************

  //***************************************************************************
  // Shift register to store last RDDATA_SHIFT_LEN cycles of data from ISERDES
  // NOTE: Written using discrete flops, but SRL can be used if the matching
  //   logic does the comparison sequentially, rather than parallel
  //***************************************************************************

  generate
    genvar rd_i;
    if (nCK_PER_CLK == 4) begin: gen_sr_div4
      if (RD_SHIFT_LEN == 1) begin: gen_sr_len_eq1
        for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
          always @(posedge clk) begin
            if (mux_rd_valid_r) begin
              sr_rise0_r[rd_i] <= #TCQ mux_rd_rise0_r[rd_i];
              sr_fall0_r[rd_i] <= #TCQ mux_rd_fall0_r[rd_i];
              sr_rise1_r[rd_i] <= #TCQ mux_rd_rise1_r[rd_i];
              sr_fall1_r[rd_i] <= #TCQ mux_rd_fall1_r[rd_i];
              sr_rise2_r[rd_i] <= #TCQ mux_rd_rise2_r[rd_i];
              sr_fall2_r[rd_i] <= #TCQ mux_rd_fall2_r[rd_i];
              sr_rise3_r[rd_i] <= #TCQ mux_rd_rise3_r[rd_i];
              sr_fall3_r[rd_i] <= #TCQ mux_rd_fall3_r[rd_i];
            end
          end
        end
      end else if (RD_SHIFT_LEN > 1) begin: gen_sr_len_gt1
        for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
          always @(posedge clk) begin
            if (mux_rd_valid_r) begin
              sr_rise0_r[rd_i] <= #TCQ {sr_rise0_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise0_r[rd_i]};
              sr_fall0_r[rd_i] <= #TCQ {sr_fall0_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall0_r[rd_i]};
              sr_rise1_r[rd_i] <= #TCQ {sr_rise1_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise1_r[rd_i]};
              sr_fall1_r[rd_i] <= #TCQ {sr_fall1_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall1_r[rd_i]};
              sr_rise2_r[rd_i] <= #TCQ {sr_rise2_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise2_r[rd_i]};
              sr_fall2_r[rd_i] <= #TCQ {sr_fall2_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall2_r[rd_i]};
              sr_rise3_r[rd_i] <= #TCQ {sr_rise3_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise3_r[rd_i]};
              sr_fall3_r[rd_i] <= #TCQ {sr_fall3_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall3_r[rd_i]};
            end
          end
        end
      end
    end else if (nCK_PER_CLK == 2) begin: gen_sr_div2
      if (RD_SHIFT_LEN == 1) begin: gen_sr_len_eq1
        for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
          always @(posedge clk) begin
            if (mux_rd_valid_r) begin
              sr_rise0_r[rd_i] <= #TCQ {mux_rd_rise0_r[rd_i]};
              sr_fall0_r[rd_i] <= #TCQ {mux_rd_fall0_r[rd_i]};
              sr_rise1_r[rd_i] <= #TCQ {mux_rd_rise1_r[rd_i]};
              sr_fall1_r[rd_i] <= #TCQ {mux_rd_fall1_r[rd_i]};      
            end
          end
        end
      end else if (RD_SHIFT_LEN > 1) begin: gen_sr_len_gt1
        for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
          always @(posedge clk) begin
            if (mux_rd_valid_r) begin
              sr_rise0_r[rd_i] <= #TCQ {sr_rise0_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise0_r[rd_i]};
              sr_fall0_r[rd_i] <= #TCQ {sr_fall0_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall0_r[rd_i]};
              sr_rise1_r[rd_i] <= #TCQ {sr_rise1_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_rise1_r[rd_i]};
              sr_fall1_r[rd_i] <= #TCQ {sr_fall1_r[rd_i][RD_SHIFT_LEN-2:0],
                                        mux_rd_fall1_r[rd_i]};      
            end
          end
        end
      end
    end
  endgenerate

  //***************************************************************************
  // First stage calibration: Capture clock
  //***************************************************************************

  //*****************************************************************
  // Keep track of how many samples have been written to shift registers
  // Every time RD_SHIFT_LEN samples have been written, then we have a
  // full read training pattern loaded into the sr_* registers. Then assert
  // sr_valid_r to indicate that: (1) comparison between the sr_* and
  // old_sr_* and prev_sr_* registers can take place, (2) transfer of
  // the contents of sr_* to old_sr_* and prev_sr_* registers can also
  // take place
  //*****************************************************************

  always @(posedge clk)
    if (rst) begin
      cnt_shift_r <= #TCQ 'b0;
      sr_valid_r  <= #TCQ 1'b0;
    end else begin
      if (mux_rd_valid_r) begin
        if (cnt_shift_r == RD_SHIFT_LEN-1) begin
          sr_valid_r <= #TCQ 1'b1;
          cnt_shift_r <= #TCQ 'b0;
        end else begin
          sr_valid_r <= #TCQ 1'b0;
          cnt_shift_r <= #TCQ cnt_shift_r + 1;
        end
      end else
        // When the current mux_rd_* contents are not valid, then
        // retain the current value of cnt_shift_r, and make sure
        // that sr_valid_r = 0 to prevent any downstream loads or
        // comparisons
        sr_valid_r <= #TCQ 1'b0;
    end

  //*****************************************************************
  // Logic to determine when either edge of the data eye encountered
  // Pre- and post-IDELAY update data pattern is compared, if they
  // differ, than an edge has been encountered. Currently no attempt
  // made to determine if the data pattern itself is "correct", only
  // whether it changes after incrementing the IDELAY (possible
  // future enhancement)
  //*****************************************************************

  // One-way control for ensuring that state machine request to store
  // current read data into OLD SR shift register only occurs on a
  // valid clock cycle. The FSM provides a one-cycle request pulse.
  // It is the responsibility of the FSM to wait the worst-case time
  // before relying on any downstream results of this load. 
  always @(posedge clk)
    if (rst)
      store_sr_r      <= #TCQ 1'b0;
    else begin
      if (store_sr_req_r)
        store_sr_r <= #TCQ 1'b1;
      else if (sr_valid_r && store_sr_r)
        store_sr_r <= #TCQ 1'b0;
    end

  // Transfer current data to old data, prior to incrementing delay
  // Also store data from current sampling window - so that we can detect
  // if the current delay tap yields data that is "jittery"
  generate
    if (nCK_PER_CLK == 4) begin: gen_old_sr_div4
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_old_sr
      always @(posedge clk) begin
        if (sr_valid_r) begin
          // Load last sample (i.e. from current sampling interval)
          prev_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
          prev_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
          prev_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
          prev_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          prev_sr_rise2_r[z] <= #TCQ sr_rise2_r[z];
          prev_sr_fall2_r[z] <= #TCQ sr_fall2_r[z];
          prev_sr_rise3_r[z] <= #TCQ sr_rise3_r[z];
          prev_sr_fall3_r[z] <= #TCQ sr_fall3_r[z];         
        end
        if (sr_valid_r && store_sr_r) begin
          old_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
          old_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
          old_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
          old_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          old_sr_rise2_r[z] <= #TCQ sr_rise2_r[z];
          old_sr_fall2_r[z] <= #TCQ sr_fall2_r[z];
          old_sr_rise3_r[z] <= #TCQ sr_rise3_r[z];
          old_sr_fall3_r[z] <= #TCQ sr_fall3_r[z];
        end
      end
    end
    end else if (nCK_PER_CLK == 2) begin: gen_old_sr_div2
      for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_old_sr
        always @(posedge clk) begin
          if (sr_valid_r) begin
            prev_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
            prev_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
            prev_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
            prev_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          end
          if (sr_valid_r && store_sr_r) begin
            old_sr_rise0_r[z] <= #TCQ sr_rise0_r[z];
            old_sr_fall0_r[z] <= #TCQ sr_fall0_r[z];
            old_sr_rise1_r[z] <= #TCQ sr_rise1_r[z];
            old_sr_fall1_r[z] <= #TCQ sr_fall1_r[z];
          end
        end
      end
    end
  endgenerate

  //*******************************************************
  // Match determination occurs over 3 cycles - pipelined for better timing
  //*******************************************************

  // Match valid with # of cycles of pipelining in match determination
  always @(posedge clk) begin
    sr_valid_r1 <= #TCQ sr_valid_r;
    sr_valid_r2 <= #TCQ sr_valid_r1;
  end
  
  generate
    if (nCK_PER_CLK == 4) begin: gen_sr_match_div4
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_sr_match
      always @(posedge clk) begin
        // CYCLE1: Compare all bits in DQS grp, generate separate term for 
        //  each bit over four bit times. For example, if there are 8-bits
        //  per DQS group, 32 terms are generated on cycle 1
        // NOTE: Structure HDL such that X on data bus will result in a 
        //  mismatch. This is required for memory models that can drive the 
        //  bus with X's to model uncertainty regions (e.g. Denali)
        if (sr_rise0_r[z] == old_sr_rise0_r[z])
          old_sr_match_rise0_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise0_r[z] <= #TCQ 1'b0;
        
        if (sr_fall0_r[z] == old_sr_fall0_r[z])
          old_sr_match_fall0_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall0_r[z] <= #TCQ 1'b0;
        
        if (sr_rise1_r[z] == old_sr_rise1_r[z])
          old_sr_match_rise1_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise1_r[z] <= #TCQ 1'b0;
        
        if (sr_fall1_r[z] == old_sr_fall1_r[z])
          old_sr_match_fall1_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall1_r[z] <= #TCQ 1'b0;

        if (sr_rise2_r[z] == old_sr_rise2_r[z])
          old_sr_match_rise2_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise2_r[z] <= #TCQ 1'b0;
        
        if (sr_fall2_r[z] == old_sr_fall2_r[z])
          old_sr_match_fall2_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall2_r[z] <= #TCQ 1'b0;
        
        if (sr_rise3_r[z] == old_sr_rise3_r[z])
          old_sr_match_rise3_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_rise3_r[z] <= #TCQ 1'b0;
        
        if (sr_fall3_r[z] == old_sr_fall3_r[z])
          old_sr_match_fall3_r[z] <= #TCQ 1'b1;
        else
          old_sr_match_fall3_r[z] <= #TCQ 1'b0;
        
        if (sr_rise0_r[z] == prev_sr_rise0_r[z])
          prev_sr_match_rise0_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise0_r[z] <= #TCQ 1'b0;
        
        if (sr_fall0_r[z] == prev_sr_fall0_r[z])
          prev_sr_match_fall0_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall0_r[z] <= #TCQ 1'b0;
        
        if (sr_rise1_r[z] == prev_sr_rise1_r[z])
          prev_sr_match_rise1_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise1_r[z] <= #TCQ 1'b0;
        
        if (sr_fall1_r[z] == prev_sr_fall1_r[z])
          prev_sr_match_fall1_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall1_r[z] <= #TCQ 1'b0;
          
        if (sr_rise2_r[z] == prev_sr_rise2_r[z])
          prev_sr_match_rise2_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise2_r[z] <= #TCQ 1'b0;
        
        if (sr_fall2_r[z] == prev_sr_fall2_r[z])
          prev_sr_match_fall2_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall2_r[z] <= #TCQ 1'b0;
        
        if (sr_rise3_r[z] == prev_sr_rise3_r[z])
          prev_sr_match_rise3_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_rise3_r[z] <= #TCQ 1'b0;
        
        if (sr_fall3_r[z] == prev_sr_fall3_r[z])
          prev_sr_match_fall3_r[z] <= #TCQ 1'b1;
        else
          prev_sr_match_fall3_r[z] <= #TCQ 1'b0;

        // CYCLE2: Combine all the comparisons for every 8 words (rise0, 
        //  fall0,rise1, fall1) in the calibration sequence. Now we're down 
        //  to DRAM_WIDTH terms
          old_sr_match_cyc2_r[z] <= #TCQ 
                                    old_sr_match_rise0_r[z] &
                                  old_sr_match_fall0_r[z] &
                                  old_sr_match_rise1_r[z] &
                                  old_sr_match_fall1_r[z] &
                                  old_sr_match_rise2_r[z] &
                                  old_sr_match_fall2_r[z] &
                                  old_sr_match_rise3_r[z] &
                                  old_sr_match_fall3_r[z];
          prev_sr_match_cyc2_r[z] <= #TCQ 
                                     prev_sr_match_rise0_r[z] &
                                   prev_sr_match_fall0_r[z] &
                                   prev_sr_match_rise1_r[z] &
                                   prev_sr_match_fall1_r[z] &
                                   prev_sr_match_rise2_r[z] &
                                   prev_sr_match_fall2_r[z] &
                                   prev_sr_match_rise3_r[z] &
                                   prev_sr_match_fall3_r[z];
         
        // CYCLE3: Invert value (i.e. assert when DIFFERENCE in value seen),
        //  and qualify with pipelined valid signal) - probably don't need
        //  a cycle just do do this....
        if (sr_valid_r2) begin 
          old_sr_diff_r[z]  <= #TCQ ~old_sr_match_cyc2_r[z];
          prev_sr_diff_r[z] <= #TCQ ~prev_sr_match_cyc2_r[z];     
        end else begin 
          old_sr_diff_r[z]  <= #TCQ 'b0;
          prev_sr_diff_r[z] <= #TCQ 'b0;
        end
        end
      end
    end if (nCK_PER_CLK == 2) begin: gen_sr_match_div2
      for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_sr_match
        always @(posedge clk) begin
          if (sr_rise0_r[z] == old_sr_rise0_r[z])
            old_sr_match_rise0_r[z] <= #TCQ 1'b1;
          else
            old_sr_match_rise0_r[z] <= #TCQ 1'b0;
          
          if (sr_fall0_r[z] == old_sr_fall0_r[z])
            old_sr_match_fall0_r[z] <= #TCQ 1'b1;
          else
            old_sr_match_fall0_r[z] <= #TCQ 1'b0;

          if (sr_rise1_r[z] == old_sr_rise1_r[z])
            old_sr_match_rise1_r[z] <= #TCQ 1'b1;
          else
            old_sr_match_rise1_r[z] <= #TCQ 1'b0;
          
          if (sr_fall1_r[z] == old_sr_fall1_r[z])
            old_sr_match_fall1_r[z] <= #TCQ 1'b1;
          else
            old_sr_match_fall1_r[z] <= #TCQ 1'b0;
          
          if (sr_rise0_r[z] == prev_sr_rise0_r[z])
            prev_sr_match_rise0_r[z] <= #TCQ 1'b1;
          else
            prev_sr_match_rise0_r[z] <= #TCQ 1'b0;
          
          if (sr_fall0_r[z] == prev_sr_fall0_r[z])
            prev_sr_match_fall0_r[z] <= #TCQ 1'b1;
          else
            prev_sr_match_fall0_r[z] <= #TCQ 1'b0;
          
          if (sr_rise1_r[z] == prev_sr_rise1_r[z])
            prev_sr_match_rise1_r[z] <= #TCQ 1'b1;
          else
            prev_sr_match_rise1_r[z] <= #TCQ 1'b0;
          
          if (sr_fall1_r[z] == prev_sr_fall1_r[z])
            prev_sr_match_fall1_r[z] <= #TCQ 1'b1;
          else
            prev_sr_match_fall1_r[z] <= #TCQ 1'b0;
          
          old_sr_match_cyc2_r[z] <= #TCQ 
                                    old_sr_match_rise0_r[z] &
                                    old_sr_match_fall0_r[z] &
                                    old_sr_match_rise1_r[z] &
                                    old_sr_match_fall1_r[z];
          prev_sr_match_cyc2_r[z] <= #TCQ
                                     prev_sr_match_rise0_r[z] &
                                     prev_sr_match_fall0_r[z] &
                                     prev_sr_match_rise1_r[z] &
                                     prev_sr_match_fall1_r[z];
          
          // CYCLE3: Invert value (i.e. assert when DIFFERENCE in value seen),
          //  and qualify with pipelined valid signal) - probably don't need
          //  a cycle just do do this....
          if (sr_valid_r2) begin 
            old_sr_diff_r[z]  <= #TCQ ~old_sr_match_cyc2_r[z];
            prev_sr_diff_r[z] <= #TCQ ~prev_sr_match_cyc2_r[z];     
          end else begin 
            old_sr_diff_r[z]  <= #TCQ 'b0;
            prev_sr_diff_r[z] <= #TCQ 'b0;
          end
        end
     end
    end
  endgenerate
  
  //***************************************************************************
  // First stage calibration: DQS Capture
  //***************************************************************************
  

  //*******************************************************
  // Counters for tracking # of samples compared
  // For each comparision point (i.e. to determine if an edge has
  // occurred after each IODELAY increment when read leveling),
  // multiple samples are compared in order to average out the effects
  // of jitter. If any one of these samples is different than the "old"
  // sample corresponding to the previous IODELAY value, then an edge
  // is declared to be detected. 
  //*******************************************************
  
  // Two cascaded counters are used to keep track of # of samples compared, 
  // in order to make it easier to meeting timing on these paths. Once 
  // optimal sampling interval is determined, it may be possible to remove 
  // the second counter 
  always @(posedge clk)
    samp_edge_cnt0_en_r <= #TCQ 
                          (cal1_state_r == CAL1_DETECT_EDGE) ||
                          (cal1_state_r == CAL1_PB_DETECT_EDGE) ||
                          (cal1_state_r == CAL1_PB_DETECT_EDGE_DQ);
  
  // First counter counts # of samples compared
  always @(posedge clk)
    if (rst)
      samp_edge_cnt0_r <= #TCQ 'b0;
    else begin
      if (!samp_edge_cnt0_en_r)
        // Reset sample counter when not in any of the "sampling" states
        samp_edge_cnt0_r <= #TCQ 'b0;
      else if (sr_valid_r2)
        // Otherwise, count # of samples compared
        samp_edge_cnt0_r <= #TCQ samp_edge_cnt0_r + 1;
    end

  // Counter #2 enable generation
  always @(posedge clk)
    if (rst)
      samp_edge_cnt1_en_r <= #TCQ 1'b0;
    else begin 
      // Assert pulse when correct number of samples compared
      if ((samp_edge_cnt0_r == DETECT_EDGE_SAMPLE_CNT0) && sr_valid_r2)
        samp_edge_cnt1_en_r <= #TCQ 1'b1;
      else
        samp_edge_cnt1_en_r <= #TCQ 1'b0;
    end
  
  // Counter #2
  always @(posedge clk)
    if (rst)
      samp_edge_cnt1_r <= #TCQ 'b0;
    else 
      if (!samp_edge_cnt0_en_r)
        samp_edge_cnt1_r <= #TCQ 'b0;
      else if (samp_edge_cnt1_en_r)
        samp_edge_cnt1_r <= #TCQ samp_edge_cnt1_r + 1;
      
  always @(posedge clk)
    if (rst)
      samp_cnt_done_r <= #TCQ 1'b0;
    else begin 
      if (!samp_edge_cnt0_en_r)
        samp_cnt_done_r <= #TCQ 'b0;
      else if ((SIM_CAL_OPTION == "FAST_CAL") ||
               (SIM_CAL_OPTION == "FAST_WIN_DETECT")) begin
        if (samp_edge_cnt0_r == SR_VALID_DELAY-1)
          // For simulation only, stay in edge detection mode a minimum
          // amount of time - just enough for two data compares to finish
          samp_cnt_done_r <= #TCQ 1'b1;      
      end else begin
        if (samp_edge_cnt1_r == DETECT_EDGE_SAMPLE_CNT1)
          samp_cnt_done_r <= #TCQ 1'b1;
      end
    end

  //*****************************************************************
  // Logic to keep track of (on per-bit basis):
  //  1. When a region of stability preceded by a known edge occurs
  //  2. If for the current tap, the read data jitters
  //  3. If an edge occured between the current and previous tap
  //  4. When the current edge detection/sampling interval can end
  // Essentially, these are a series of status bits - the stage 1
  // calibration FSM monitors these to determine when an edge is
  // found. Additional information is provided to help the FSM
  // determine if a left or right edge has been found. 
  //****************************************************************

  assign pb_detect_edge_setup 
    = (cal1_state_r == CAL1_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_STORE_FIRST_WAIT) ||
      (cal1_state_r == CAL1_PB_DEC_CPT_LEFT_WAIT);

  assign pb_detect_edge
    = (cal1_state_r == CAL1_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE) ||
      (cal1_state_r == CAL1_PB_DETECT_EDGE_DQ);
        
  generate
    for (z = 0; z < DRAM_WIDTH; z = z + 1) begin: gen_track_left_edge  
      always @(posedge clk) begin 
        if (pb_detect_edge_setup) begin
          // Reset eye size, stable eye marker, and jitter marker before
          // starting new edge detection iteration
          pb_cnt_eye_size_r[z]     <= #TCQ 3'b111;
          pb_detect_edge_done_r[z] <= #TCQ 1'b0;
          pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
          pb_last_tap_jitter_r[z]  <= #TCQ 1'b0;
          pb_found_edge_last_r[z]  <= #TCQ 1'b0;
          pb_found_edge_r[z]       <= #TCQ 1'b0;
          pb_found_first_edge_r[z] <= #TCQ 1'b0;
        end else if (pb_detect_edge) begin 
          // Save information on which DQ bits are already out of the
          // data valid window - those DQ bits will later not have their
          // IDELAY tap value incremented
          pb_found_edge_last_r[z] <= #TCQ pb_found_edge_r[z];

          if (!pb_detect_edge_done_r[z]) begin 
            if (samp_cnt_done_r) begin
              // If we've reached end of sampling interval, no jitter on 
              // current tap has been found (although an edge could have 
              // been found between the current and previous taps), and 
              // the sampling interval is complete. Increment the stable 
              // eye counter if no edge found, and always clear the jitter 
              // flag in preparation for the next tap. 
              pb_last_tap_jitter_r[z]  <= #TCQ 1'b0;
              pb_detect_edge_done_r[z] <= #TCQ 1'b1;
              if (!pb_found_edge_r[z] && !pb_last_tap_jitter_r[z]) begin
                // If the data was completely stable during this tap and
                // no edge was found between this and the previous tap
                // then increment the stable eye counter "as appropriate" 
                if (pb_cnt_eye_size_r[z] != MIN_EYE_SIZE-1)
                  pb_cnt_eye_size_r[z] <= #TCQ pb_cnt_eye_size_r[z] + 1;
                else if (pb_found_first_edge_r[z])
                  // We've reached minimum stable eye width
                  pb_found_stable_eye_r[z] <= #TCQ 1'b1;
              end else begin 
                // Otherwise, an edge was found, either because of a
                // difference between this and the previous tap's read 
                // data, and/or because the previous tap's data jittered 
                // (but not the current tap's data), then just set the 
                // edge found flag, and enable the stable eye counter
                pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
                pb_found_stable_eye_r[z] <= #TCQ 1'b0;          
                pb_found_edge_r[z]       <= #TCQ 1'b1;
                pb_detect_edge_done_r[z] <= #TCQ 1'b1;          
              end
            end else if (prev_sr_diff_r[z]) begin
              // If we find that the current tap read data jitters, then
              // set edge and jitter found flags, "enable" the eye size
              // counter, and stop sampling interval for this bit
              pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
              pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
              pb_last_tap_jitter_r[z]  <= #TCQ 1'b1;          
              pb_found_edge_r[z]       <= #TCQ 1'b1;
              pb_found_first_edge_r[z] <= #TCQ 1'b1;          
              pb_detect_edge_done_r[z] <= #TCQ 1'b1;        
            end else if (old_sr_diff_r[z] || pb_last_tap_jitter_r[z]) begin
              // If either an edge was found (i.e. difference between
              // current tap and previous tap read data), or the previous
              // tap exhibited jitter (which means by definition that the
              // current tap cannot match the previous tap because the
              // previous tap gave unstable data), then set the edge found
              // flag, and "enable" eye size counter. But do not stop 
              // sampling interval - we still need to check if the current 
              // tap exhibits jitter
              pb_cnt_eye_size_r[z]     <= #TCQ 3'b000;
              pb_found_stable_eye_r[z] <= #TCQ 1'b0;      
              pb_found_edge_r[z]       <= #TCQ 1'b1;
              pb_found_first_edge_r[z] <= #TCQ 1'b1;          
            end
          end
        end else begin
          // Before every edge detection interval, reset "intra-tap" flags
          pb_found_edge_r[z]       <= #TCQ 1'b0;
          pb_detect_edge_done_r[z] <= #TCQ 1'b0;
        end
      end          
    end
  endgenerate

  // Combine the above per-bit status flags into combined terms when
  // performing deskew on the aggregate data window
  always @(posedge clk) begin
    detect_edge_done_r <= #TCQ &pb_detect_edge_done_r;
    found_edge_r       <= #TCQ |pb_found_edge_r;
    found_edge_all_r   <= #TCQ &pb_found_edge_r;
    found_stable_eye_r <= #TCQ &pb_found_stable_eye_r;
  end

  // last IODELAY "stable eye" indicator is updated only after 
  // detect_edge_done_r is asserted - so that when we do find the "right edge" 
  // of the data valid window, found_edge_r = 1, AND found_stable_eye_r = 1 
  // when detect_edge_done_r = 1 (otherwise, if found_stable_eye_r updates
  // immediately, then it never possible to have found_stable_eye_r = 1
  // when we detect an edge - and we'll never know whether we've found
  // a "right edge")
  always @(posedge clk)
    if (pb_detect_edge_setup)
      found_stable_eye_last_r <= #TCQ 1'b0;
    else if (detect_edge_done_r)
      found_stable_eye_last_r <= #TCQ found_stable_eye_r;
  
  //*****************************************************************
  // keep track of edge tap counts found, and current capture clock
  // tap count
  //*****************************************************************

  always @(posedge clk)
    if (rst || new_cnt_cpt_r)
      tap_cnt_cpt_r   <= #TCQ 'b0;
    else if (cal1_dlyce_cpt_r) begin
      if (cal1_dlyinc_cpt_r)
        tap_cnt_cpt_r <= #TCQ tap_cnt_cpt_r + 1;
      else
        tap_cnt_cpt_r <= #TCQ tap_cnt_cpt_r - 1;
    end
    
  always @(posedge clk)
    if (rst || new_cnt_cpt_r || 
       (cal1_state_r1 == CAL1_DQ_IDEL_TAP_INC))
      tap_limit_cpt_r <= #TCQ 1'b0;
    else if (tap_cnt_cpt_r == 6'd63)
      tap_limit_cpt_r <= #TCQ 1'b1;

  // Temp wire for timing.
   // The following in the always block below causes timing issues
   // due to DSP block inference
   // 6*cal1_cnt_cpt_r.
   // replacing this with two left shifts + one left shift  to avoid
   // DSP multiplier.

  assign cal1_cnt_cpt_timing = {2'd0, cal1_cnt_cpt_r};
 
   // Storing DQS tap values at the end of each DQS read leveling
   always @(posedge clk) begin
     if (rst) begin
       rdlvl_dqs_tap_cnt_r <= #TCQ 'b0;
     end else if ((SIM_CAL_OPTION == "FAST_CAL") & (cal1_state_r1 == CAL1_NEXT_DQS)) begin
       for (p = 0; p < RANKS; p = p +1) begin: rdlvl_dqs_tap_rank_cnt   
         for(q = 0; q < DQS_WIDTH; q = q +1) begin: rdlvl_dqs_tap_cnt
           rdlvl_dqs_tap_cnt_r[((6*q)+(p*DQS_WIDTH*6))+:6] <= #TCQ tap_cnt_cpt_r;
         end
       end
     end else if (SIM_CAL_OPTION == "SKIP_CAL") begin
       for (j = 0; j < RANKS; j = j +1) begin: rdlvl_dqs_tap_rnk_cnt   
         for(i = 0; i < DQS_WIDTH; i = i +1) begin: rdlvl_dqs_cnt
           rdlvl_dqs_tap_cnt_r[((6*i)+(j*DQS_WIDTH*6))+:6] <= #TCQ 6'd31;
         end
       end
     end else if (cal1_state_r1 == CAL1_NEXT_DQS) begin
         rdlvl_dqs_tap_cnt_r[(((cal1_cnt_cpt_timing <<2) + (cal1_cnt_cpt_timing <<1))
         +(rnk_cnt_r*DQS_WIDTH*6))+:6]
           <= #TCQ tap_cnt_cpt_r;
     end
   end


  // Counter to track maximum DQ IODELAY tap usage during the per-bit 
  // deskew portion of stage 1 calibration
  always @(posedge clk)
    if (rst) begin
      idel_tap_cnt_dq_pb_r   <= #TCQ 'b0;
      idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
    end else 
      if (new_cnt_cpt_r) begin
        idel_tap_cnt_dq_pb_r   <= #TCQ 'b0;
        idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
      end else if (|cal1_dlyce_dq_r) begin
        if (cal1_dlyinc_dq_r)
          idel_tap_cnt_dq_pb_r <= #TCQ idel_tap_cnt_dq_pb_r + 1;
        else
          idel_tap_cnt_dq_pb_r <= #TCQ idel_tap_cnt_dq_pb_r - 1;         

        if (idel_tap_cnt_dq_pb_r == 31)
          idel_tap_limit_dq_pb_r <= #TCQ 1'b1;
        else
          idel_tap_limit_dq_pb_r <= #TCQ 1'b0;
      end


  always @(posedge clk)
    rdlvl_stg1_start_r <= #TCQ rdlvl_stg1_start;

  
  //*****************************************************************
  
  always @(posedge clk)
    cal1_state_r1 <= #TCQ cal1_state_r;
  
  always @(posedge clk)
    if (rst) begin
      cal1_cnt_cpt_r        <= #TCQ 'b0;
      cal1_dlyce_cpt_r      <= #TCQ 1'b0;
      cal1_dlyinc_cpt_r     <= #TCQ 1'b0;
      cal1_dq_idel_ce       <= #TCQ 1'b0;
      cal1_dq_idel_inc      <= #TCQ 1'b0;
      cal1_prech_req_r      <= #TCQ 1'b0;
      cal1_state_r          <= #TCQ CAL1_IDLE;
      cnt_idel_dec_cpt_r    <= #TCQ 6'bxxxxxx;
      found_first_edge_r    <= #TCQ 1'b0;
      found_second_edge_r   <= #TCQ 1'b0;
      first_edge_taps_r     <= #TCQ 6'bxxxxx;
      new_cnt_cpt_r         <= #TCQ 1'b0;
      rdlvl_stg1_done       <= #TCQ 1'b0;
      rdlvl_stg1_err        <= #TCQ 1'b0;
      second_edge_taps_r    <= #TCQ 6'bxxxxx;
      store_sr_req_pulsed_r <= #TCQ 1'b0;
      store_sr_req_r        <= #TCQ 1'b0;
      rnk_cnt_r             <= #TCQ 2'b00;
      rdlvl_rank_done_r     <= #TCQ 1'b0;
      rdlvl_last_byte_done  <= #TCQ 1'b0; 
    end else begin
      // default (inactive) states for all "pulse" outputs
      cal1_prech_req_r    <= #TCQ 1'b0;
      cal1_dlyce_cpt_r    <= #TCQ 1'b0;
      cal1_dlyinc_cpt_r   <= #TCQ 1'b0;
      cal1_dq_idel_ce     <= #TCQ 1'b0;
      cal1_dq_idel_inc    <= #TCQ 1'b0;
      new_cnt_cpt_r       <= #TCQ 1'b0;
      store_sr_req_pulsed_r <= #TCQ 1'b0;
      store_sr_req_r      <= #TCQ 1'b0;
      
      case (cal1_state_r)
        
        CAL1_IDLE: begin
          rdlvl_rank_done_r    <= #TCQ 1'b0;
          rdlvl_last_byte_done <= #TCQ 1'b0;
          if (rdlvl_stg1_start && ~rdlvl_stg1_start_r) begin
            if (SIM_CAL_OPTION == "SKIP_CAL") begin
               cal1_state_r  <= #TCQ CAL1_REGL_LOAD;
            end else begin
              new_cnt_cpt_r <= #TCQ 1'b1;             
              cal1_state_r  <= #TCQ CAL1_NEW_DQS_WAIT;
            end
          end
        end
        // Wait for the new DQS group to change
        // also gives time for the read data IN_FIFO to
        // output the updated data for the new DQS group
        CAL1_NEW_DQS_WAIT: begin
          rdlvl_rank_done_r    <= #TCQ 1'b0;
          rdlvl_last_byte_done <= #TCQ 1'b0;
          cal1_prech_req_r     <= #TCQ 1'b0;
          if (!cal1_wait_r) begin
            // Store "previous tap" read data. Technically there is no 
            // "previous" read data, since we are starting a new DQS 
            // group, so we'll never find an edge at tap 0 unless the 
            // data is fluctuating/jittering
            store_sr_req_r <= #TCQ 1'b1;
            // If per-bit deskew is disabled, then skip the first
            // portion of stage 1 calibration
            if (PER_BIT_DESKEW == "OFF")
              cal1_state_r <= #TCQ CAL1_STORE_FIRST_WAIT;
            else if (PER_BIT_DESKEW == "ON")
              cal1_state_r <= #TCQ CAL1_PB_STORE_FIRST_WAIT;
          end
        end
        //*****************************************************************
        // Per-bit deskew states
        //*****************************************************************
        
        // Wait state following storage of initial read data 
        CAL1_PB_STORE_FIRST_WAIT:
          if (!cal1_wait_r) 
            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE;
          
        // Look for an edge on all DQ bits in current DQS group
        CAL1_PB_DETECT_EDGE:
          if (detect_edge_done_r) begin
            if (found_stable_eye_r) begin 
              // If we've found the left edge for all bits (or more precisely, 
              // we've found the left edge, and then part of the stable 
              // window thereafter), then proceed to positioning the CPT clock 
              // right before the left margin
              cnt_idel_dec_cpt_r <= #TCQ MIN_EYE_SIZE + 1;
              cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT_LEFT; 
            end else begin
              // If we've reached the end of the sampling time, and haven't 
              // yet found the left margin of all the DQ bits, then:
              if (!tap_limit_cpt_r) begin 
                // If we still have taps left to use, then store current value 
                // of read data, increment the capture clock, and continue to
                // look for (left) edges
                store_sr_req_r <= #TCQ 1'b1;
                cal1_state_r    <= #TCQ CAL1_PB_INC_CPT;
              end else begin
                // If we ran out of taps moving the capture clock, and we
                // haven't finished edge detection, then reset the capture 
                // clock taps to 0 (gradually, gradually, one tap at a time... 
                // we don't want to piss anybody off), then exit the per-bit 
                // portion of the algorithm - i.e. proceed to adjust the 
                // capture clock and DQ IODELAYs as
                cnt_idel_dec_cpt_r <= #TCQ 6'd63; 
                cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT;
              end
            end
          end
            
        // Increment delay for DQS
        CAL1_PB_INC_CPT: begin
          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
          cal1_dlyinc_cpt_r <= #TCQ 1'b1;
          cal1_state_r      <= #TCQ CAL1_PB_INC_CPT_WAIT;
        end
        
        // Wait for IODELAY for both capture and internal nodes within 
        // ISERDES to settle, before checking again for an edge 
        CAL1_PB_INC_CPT_WAIT: begin
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE;       
        end 
        // We've found the left edges of the windows for all DQ bits 
        // (actually, we found it MIN_EYE_SIZE taps ago) Decrement capture 
        // clock IDELAY to position just outside left edge of data window
        CAL1_PB_DEC_CPT_LEFT:
          if (cnt_idel_dec_cpt_r == 6'b000000)
            cal1_state_r <= #TCQ CAL1_PB_DEC_CPT_LEFT_WAIT;
          else begin 
            cal1_dlyce_cpt_r   <= #TCQ 1'b1;
            cal1_dlyinc_cpt_r  <= #TCQ 1'b0;
            cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
          end       

        CAL1_PB_DEC_CPT_LEFT_WAIT:
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE_DQ;

        // If there is skew between individual DQ bits, then after we've
        // positioned the CPT clock, we will be "in the window" for some
        // DQ bits ("early" DQ bits), and "out of the window" for others
        // ("late" DQ bits). Increase DQ taps until we are out of the 
        // window for all DQ bits
        CAL1_PB_DETECT_EDGE_DQ:
          if (detect_edge_done_r)
            if (found_edge_all_r) begin 
              // We're out of the window for all DQ bits in this DQS group
              // We're done with per-bit deskew for this group - now decr
              // capture clock IODELAY tap count back to 0, and proceed
              // with the rest of stage 1 calibration for this DQS group
              cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r;
              cal1_state_r       <= #TCQ CAL1_PB_DEC_CPT;
            end else
              if (!idel_tap_limit_dq_pb_r)               
                // If we still have DQ taps available for deskew, keep 
                // incrementing IODELAY tap count for the appropriate DQ bits
                cal1_state_r <= #TCQ CAL1_PB_INC_DQ;
              else begin 
                // Otherwise, stop immediately (we've done the best we can)
                // and proceed with rest of stage 1 calibration
                cnt_idel_dec_cpt_r <= #TCQ tap_cnt_cpt_r;
                cal1_state_r <= #TCQ CAL1_PB_DEC_CPT;
              end
              
        CAL1_PB_INC_DQ: begin
          // Increment only those DQ for which an edge hasn't been found yet
          cal1_dlyce_dq_r  <= #TCQ ~pb_found_edge_last_r;
          cal1_dlyinc_dq_r <= #TCQ 1'b1;
          cal1_state_r     <= #TCQ CAL1_PB_INC_DQ_WAIT;
        end

        CAL1_PB_INC_DQ_WAIT:
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_PB_DETECT_EDGE_DQ;

        // Decrement capture clock taps back to initial value
        CAL1_PB_DEC_CPT:
          if (cnt_idel_dec_cpt_r == 6'b000000)
            cal1_state_r <= #TCQ CAL1_PB_DEC_CPT_WAIT;
          else begin
            cal1_dlyce_cpt_r   <= #TCQ 1'b1;
            cal1_dlyinc_cpt_r  <= #TCQ 1'b0;
            cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
          end

        // Wait for capture clock to settle, then proceed to rest of
        // state 1 calibration for this DQS group
        CAL1_PB_DEC_CPT_WAIT:
          if (!cal1_wait_r) begin 
            store_sr_req_r <= #TCQ 1'b1;
            cal1_state_r    <= #TCQ CAL1_STORE_FIRST_WAIT;      
          end

        // When first starting calibration for a DQS group, save the
        // current value of the read data shift register, and use this
        // as a reference. Note that for the first iteration of the
        // edge detection loop, we will in effect be checking for an edge
        // at IODELAY taps = 0 - normally, we are comparing the read data
        // for IODELAY taps = N, with the read data for IODELAY taps = N-1
        // An edge can only be found at IODELAY taps = 0 if the read data
        // is changing during this time (possible due to jitter)
        CAL1_STORE_FIRST_WAIT: 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_DETECT_EDGE;

        // Check for presence of data eye edge. During this state, we
        // sample the read data multiple times, and look for changes
        // in the read data, specifically:
        //   1. A change in the read data compared with the value of
        //      read data from the previous delay tap. This indicates 
        //      that the most recent tap delay increment has moved us
        //      into either a new window, or moved/kept us in the
        //      transition/jitter region between windows. Note that this
        //      condition only needs to be checked for once, and for
        //      logistical purposes, we check this soon after entering
        //      this state (see comment in CAL1_DETECT_EDGE below for 
        //      why this is done)
        //   2. A change in the read data while we are in this state
        //      (i.e. in the absence of a tap delay increment). This
        //      indicates that we're close enough to a window edge that
        //      jitter will cause the read data to change even in the
        //      absence of a tap delay change 
        CAL1_DETECT_EDGE: begin
          // Essentially wait for the first comparision to finish, then 
          // store current data into "old" data register. This store 
          // happens now, rather than later (e.g. when we've have already 
          // left this state) in order to avoid the situation the data that
          // is stored as "old" data has not been used in an "active 
          // comparison" - i.e. data is stored after the last comparison 
          // of this state. In this case, we can miss an edge if the 
          // following sequence occurs:
          //   1. Comparison completes in this state - no edge found
          //   2. "Momentary jitter" occurs which "pushes" the data out the 
          //      equivalent of one delay tap
          //   3. We store this jittered data as the "old" data
          //   4. "Jitter" no longer present
          //   5. We increment the delay tap by one
          //   6. Now we compare the current with the "old" data - they're
          //      the same, and no edge is detected
          // NOTE: Given the large # of comparisons done in this state, it's
          //  highly unlikely the above sequence will occur in actual H/W

          // Wait for the first load of read data into the comparison 
          // shift register to finish, then load the current read data 
          // into the "old" data register. This allows us to do one 
          // initial comparision between the current read data, and 
          // stored data corresponding to the previous delay tap      
          if (!store_sr_req_pulsed_r) begin
            // Pulse store_sr_req_r only once in this state
            store_sr_req_r        <= #TCQ 1'b1;
            store_sr_req_pulsed_r <= #TCQ 1'b1;
          end else begin
            store_sr_req_r        <= #TCQ 1'b0;
            store_sr_req_pulsed_r <= #TCQ 1'b1;
          end
        
          // Continue to sample read data and look for edges until the
          // appropriate time interval (shorter for simulation-only, 
          // much, much longer for actual h/w) has elapsed
          if (detect_edge_done_r) begin
            if (tap_limit_cpt_r)
              // Only one edge detected and ran out of taps since only one
              // bit time worth of taps available for window detection. This
              // can happen if at tap 0 DQS is in previous window which results
              // in only left edge being detected. Or at tap 0 DQS is in the
              // current window resulting in only right edge being detected.
              // Depending on the frequency this case can also happen if at
              // tap 0 DQS is in the left noise region resulting in only left
              // edge being detected.
              cal1_state_r <= #TCQ CAL1_CALC_IDEL;
            else if (found_edge_r) begin 
              // Sticky bit - asserted after we encounter an edge, although
              // the current edge may not be considered the "first edge" this
              // just means we found at least one edge
              found_first_edge_r <= #TCQ 1'b1;

              // Both edges of data valid window found:
              // If we've found a second edge after a region of stability
              // then we must have just passed the second ("right" edge of
              // the window. Record this second_edge_taps = current tap-1, 
              // because we're one past the actual second edge tap, where 
              // the edge taps represent the extremes of the data valid 
              // window (i.e. smallest & largest taps where data still valid
              if (found_first_edge_r && found_stable_eye_last_r) begin
                found_second_edge_r <= #TCQ 1'b1;
                second_edge_taps_r <= #TCQ tap_cnt_cpt_r - 1;
                cal1_state_r <= #TCQ CAL1_CALC_IDEL;          
              end else begin
                // Otherwise, an edge was found (just not the "second" edge)
                // Assuming DQS is in the correct window at tap 0 of Phaser IN
                // fine tap. The first edge found is the right edge of the valid
                // window and is the beginning of the jitter region hence done!
                first_edge_taps_r <= #TCQ tap_cnt_cpt_r;           
                cal1_state_r <= #TCQ CAL1_CALC_IDEL;
              end
            end else
              // Otherwise, if we haven't found an edge.... 
              // If we still have taps left to use, then keep incrementing
            cal1_state_r  <= #TCQ CAL1_IDEL_INC_CPT;
          end
        end
        
        // Increment Phaser_IN delay for DQS
        CAL1_IDEL_INC_CPT: begin
          cal1_state_r        <= #TCQ CAL1_IDEL_INC_CPT_WAIT;
          if (~tap_limit_cpt_r) begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b1;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b1;
          end else begin
            cal1_dlyce_cpt_r    <= #TCQ 1'b0;
            cal1_dlyinc_cpt_r   <= #TCQ 1'b0;
          end
        end

        // Wait for Phaser_In to settle, before checking again for an edge 
        CAL1_IDEL_INC_CPT_WAIT: begin
          cal1_dlyce_cpt_r    <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r   <= #TCQ 1'b0; 
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_DETECT_EDGE;
        end
            
        // Calculate final value of Phaser_IN taps. At this point, one or both
        // edges of data eye have been found, and/or all taps have been
        // exhausted looking for the edges
        // NOTE: We're calculating the amount to decrement by, not the
        //  absolute setting for DQS.
        CAL1_CALC_IDEL: begin
          // CASE1: If 2 edges found.
          if (found_second_edge_r)
            cnt_idel_dec_cpt_r 
              <=  #TCQ ((second_edge_taps_r -
                         first_edge_taps_r)>>1) + 1;
          //else if (first_edge_taps_r < MIN_EYE_SIZE)
          //  // Started off in incorrect data window
          //  // Only left edge of data window detected
          //  // Set to 31+first_edge_taps
          //  cnt_idel_dec_cpt_r 
          //    <=  #TCQ (32 - first_edge_taps_r);
          else if ((first_edge_taps_r > 6'd0) && 
                   (first_edge_taps_r <= 6'd31))
            // Only right edge of data window detected
            // Less than 31 taps away from right edge so
            // increment DQ IDELAY tap by 1
            cnt_idel_dec_cpt_r <=  #TCQ tap_cnt_cpt_r;
        //      <=  #TCQ 6'd16;// TEMP FIX FOR CR 588495
          else if (first_edge_taps_r > 6'd31)
            // Only right edge detected more than 31 taps away
            // Decrement to 31 taps
            cnt_idel_dec_cpt_r 
              <=  #TCQ (tap_cnt_cpt_r - (first_edge_taps_r - 32));
          else
            // No edges detected 
            cnt_idel_dec_cpt_r 
              <=  #TCQ ((tap_cnt_cpt_r)>>1) + 1;
          // Now use the value we just calculated to decrement CPT taps
          // to the desired calibration point
          cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT;  
        end

        // decrement capture clock for final adjustment - center
        // capture clock in middle of data eye. This adjustment will occur
        // only when both the edges are found usign CPT taps. Must do this
        // incrementally to avoid clock glitching (since CPT drives clock
        // divider within each ISERDES)
        CAL1_IDEL_DEC_CPT: begin
          cal1_dlyce_cpt_r  <= #TCQ 1'b1;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          // once adjustment is complete, we're done with calibration for
          // this DQS, repeat for next DQS
          cnt_idel_dec_cpt_r <= #TCQ cnt_idel_dec_cpt_r - 1;
          if (cnt_idel_dec_cpt_r == 6'b000001) begin
            if ((first_edge_taps_r > 6'd0) && (first_edge_taps_r <= 6'd31))
              cal1_state_r <= #TCQ CAL1_DQ_IDEL_TAP_INC;
            else
              cal1_state_r <= #TCQ CAL1_NEXT_DQS;
          end else
            cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT_WAIT;
        end

        CAL1_IDEL_DEC_CPT_WAIT: begin
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          cal1_state_r <= #TCQ CAL1_IDEL_DEC_CPT;
        end

        // Increment IDELAY tap by 1 for DQ bits in the byte being calibrated
        // if first edge was detected at less than half a bit time or less than
        // 32 Phaser IN fine taps
        CAL1_DQ_IDEL_TAP_INC: begin
          found_first_edge_r  <= #TCQ 1'b0;
          found_second_edge_r <= #TCQ 1'b0;
          first_edge_taps_r   <= #TCQ 'd0;
          second_edge_taps_r  <= #TCQ 'd0;
          cal1_dq_idel_ce     <= #TCQ 1'b1;
          cal1_dq_idel_inc    <= #TCQ 1'b1;
          cal1_state_r        <= #TCQ CAL1_DQ_IDEL_TAP_INC_WAIT;
        end
        
        CAL1_DQ_IDEL_TAP_INC_WAIT: begin
          cal1_dq_idel_ce     <= #TCQ 1'b0;
          cal1_dq_idel_inc    <= #TCQ 1'b0;
          if (!cal1_wait_r)
            cal1_state_r <= #TCQ CAL1_NEW_DQS_WAIT;
        end
        
        // Determine whether we're done, or have more DQS's to calibrate
        // Also request precharge after every byte, as appropriate
        CAL1_NEXT_DQS: begin
          cal1_prech_req_r  <= #TCQ 1'b1;
          cal1_dlyce_cpt_r  <= #TCQ 1'b0;
          cal1_dlyinc_cpt_r <= #TCQ 1'b0;
          // Prepare for another iteration with next DQS group
          found_first_edge_r  <= #TCQ 1'b0;
          found_second_edge_r <= #TCQ 1'b0;
          first_edge_taps_r <= #TCQ 'd0;
          second_edge_taps_r <= #TCQ 'd0;
          if ((SIM_CAL_OPTION == "FAST_CAL") ||
              (cal1_cnt_cpt_r >= DQS_WIDTH-1))// && (rnk_cnt_r == RANKS-1)))
            rdlvl_last_byte_done <= #TCQ 1'b1;
           
          // Wait until precharge that occurs in between calibration of
          // DQS groups is finished
          if (prech_done) begin
            if (SIM_CAL_OPTION == "FAST_CAL") begin
              //rdlvl_rank_done_r <= #TCQ 1'b1;
              cal1_state_r <= #TCQ CAL1_REGL_LOAD;
            end else if (cal1_cnt_cpt_r >= DQS_WIDTH-1) begin
              // All DQS groups in a rank done
              rdlvl_rank_done_r <= #TCQ 1'b1;
              if (rnk_cnt_r == RANKS-1) begin
                // All DQS groups in all ranks done
                cal1_state_r <= #TCQ CAL1_REGL_LOAD;
              end else begin
                // Process DQS groups in next rank
                rnk_cnt_r      <= #TCQ rnk_cnt_r + 1;
                new_cnt_cpt_r  <= #TCQ 1'b1;
                cal1_cnt_cpt_r <= #TCQ 'b0;
                cal1_state_r   <= #TCQ CAL1_IDLE;
              end         
            end else begin
              // Process next DQS group
              new_cnt_cpt_r  <= #TCQ 1'b1;
              cal1_cnt_cpt_r <= #TCQ cal1_cnt_cpt_r + 1;
              cal1_state_r   <= #TCQ CAL1_NEW_DQS_WAIT;
            end
          end
        end

        // Load rank registers in Phaser_IN
        CAL1_REGL_LOAD: begin
          rdlvl_rank_done_r <= #TCQ 1'b0;
          cal1_prech_req_r  <= #TCQ 1'b0;
          rnk_cnt_r         <= #TCQ 2'b00;
          if ((regl_rank_cnt == RANKS-1) && 
              ((regl_dqs_cnt == DQS_WIDTH-1) && (done_cnt == 4'd1))) begin
            cal1_state_r <= #TCQ CAL1_DONE;
            rdlvl_last_byte_done <= #TCQ 1'b0;
          end else
            cal1_state_r <= #TCQ CAL1_REGL_LOAD;
        end
        
        // Done with this stage of calibration
        // if used, allow DEBUG_PORT to control taps
        CAL1_DONE: begin
          rdlvl_stg1_done   <= #TCQ 1'b1;
        end

      endcase
    end

 
 


endmodule
