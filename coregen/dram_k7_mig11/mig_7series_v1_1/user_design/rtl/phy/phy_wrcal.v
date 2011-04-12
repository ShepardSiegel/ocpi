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
//  /   /         Filename: phy_wrcal.v
// /___/   /\     Date Last Modified: $Date: 2010/12/23 01:30:08 $
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: 7 Series
//Design Name: DDR3 SDRAM
//Purpose:
//  Write calibration logic to align DQS to correct CK edge
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: phy_wrcal.v,v 1.7 2010/12/23 01:30:08 mgeorge Exp $
**$Date: 2010/12/23 01:30:08 $
**$Author: 
**$Revision:
**$Source: 
******************************************************************************/

`timescale 1ps/1ps

module phy_wrcal #
  (
   parameter TCQ             = 100,    // clk->out delay (sim only)
   parameter nCK_PER_CLK     = 2,      // # of memory clocks per CLK
   parameter DQ_WIDTH        = 64,     // # of DQ (data)
   parameter DQS_CNT_WIDTH   = 3,      // = ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH       = 8,      // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,      // # of DQ per DQS
   parameter SIM_CAL_OPTION  = "NONE"  // Skip various calibration steps
   )
  (
   input                        clk,
   input                        rst,
   // Calibration status, control signals
   input                        wrcal_start,
   input                        phy_rddata_en,
   output reg                   wrcal_done,
   output reg                   wrcal_pat_err,
   output reg                   wrcal_prech_req,
   input                        prech_done,
   // Captured data in resync clock domain
   input [DQ_WIDTH-1:0]         rd_data_rise0,
   input [DQ_WIDTH-1:0]         rd_data_fall0,
   input [DQ_WIDTH-1:0]         rd_data_rise1,
   input [DQ_WIDTH-1:0]         rd_data_fall1,
   input [DQ_WIDTH-1:0]         rd_data_rise2,
   input [DQ_WIDTH-1:0]         rd_data_fall2,
   input [DQ_WIDTH-1:0]         rd_data_rise3,
   input [DQ_WIDTH-1:0]         rd_data_fall3,
   // Write level values of Phaser_Out coarse and fine
   // delay taps required to load Phaser_Out register
   input [3*DQS_WIDTH-1:0]      wl_po_coarse_cnt,
   input [6*DQS_WIDTH-1:0]      wl_po_fine_cnt,
   // Stage 2 calibration inputs/outputs
   // Only coarse delay line used during write calibration
   // Inc Phaser_Out coarse delay line
   output reg                   dqs_po_stg2_c_incdec,
   // Enable Phaser_Out coarse delay inc/dec
   output reg                   dqs_po_en_stg2_c,
   output reg                   dqs_po_stg2_load,
   output reg [8:0]             dqs_po_stg2_reg_l,
   output                       wrcal_pat_resume,   // to phy_init for write
   output [DQS_CNT_WIDTH:0]     po_stg2_wrcal_cnt,

   // Debug Port
   output [15:0]                dbg_phy_wrcal
   );

  // Length of calibration sequence (in # of words)
  localparam CAL_PAT_LEN = 8;
  // Read data shift register length
  localparam RD_SHIFT_LEN = (nCK_PER_CLK == 4) ? 1 : 2;

  // # of cycles to wait after changing RDEN count value
  localparam RDEN_WAIT_CNT = 12;

 
  
  localparam CAL2_IDLE           = 3'h0;
  localparam CAL2_READ_WAIT      = 3'h1;
  localparam CAL2_DETECT_MATCH   = 3'h2;
  localparam CAL2_CORSE_INC      = 3'h3;
  localparam CAL2_CORSE_INC_WAIT = 3'h4;
  localparam CAL2_NEXT_DQS       = 3'h5;
  localparam CAL2_DONE           = 3'h6;
  localparam CAL2_ERROR_TO       = 3'h7;

  integer  i;
  
  reg [DQS_CNT_WIDTH:0]   wrcal_dqs_cnt_r;
  reg [DQS_CNT_WIDTH:0]   wrcal_regl_dqs_cnt;
  reg [3:0]               wrcal_done_cnt;
  reg                     cal2_done_r;
  reg                     cal2_done_r1;
  reg                     cal2_done_r2;
  reg                     cal2_done_r3;  
  reg                     cal2_prech_req_r;
  reg [2:0]               cal2_state_r;
  reg [3*DQS_WIDTH-1:0]   cal2_corse_cnt;
  reg                     wrcal_pat_resume_r;
  reg                     wrcal_pat_resume_r1;
  reg                     wrcal_pat_resume_r2;
  reg                     wrcal_pat_resume_r3;
  reg [3:0]               cnt_rden_wait_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise0_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise1_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_fall3_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise2_r;
  reg [DRAM_WIDTH-1:0]    mux_rd_rise3_r;
  reg                     pat_data_match_r;
  wire [RD_SHIFT_LEN-1:0] pat_fall0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_fall1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_fall2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_fall3 [3:0];
  reg [DRAM_WIDTH-1:0]    pat_match_fall0_r;
  reg                     pat_match_fall0_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall1_r;
  reg                     pat_match_fall1_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall2_r;
  reg                     pat_match_fall2_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_fall3_r;
  reg                     pat_match_fall3_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise0_r;
  reg                     pat_match_rise0_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise1_r;
  reg                     pat_match_rise1_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise2_r;
  reg                     pat_match_rise2_and_r;
  reg [DRAM_WIDTH-1:0]    pat_match_rise3_r;
  reg                     pat_match_rise3_and_r;
  wire [RD_SHIFT_LEN-1:0] pat_rise0 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_rise1 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_rise2 [3:0];
  wire [RD_SHIFT_LEN-1:0] pat_rise3 [3:0];
  reg [DQS_CNT_WIDTH:0]   rd_mux_sel_r;
  reg                     rd_active_posedge_r;
  reg                     rd_active_r;
  reg                     rden_wait_r;
  reg [RD_SHIFT_LEN-1:0]  sr_fall0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise0_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise1_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_fall3_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise2_r [DRAM_WIDTH-1:0];
  reg [RD_SHIFT_LEN-1:0]  sr_rise3_r [DRAM_WIDTH-1:0];



  //***************************************************************************
  // Debug
  //***************************************************************************

  assign dbg_phy_wrcal[0]    = pat_data_match_r;
  assign dbg_phy_wrcal[4:2]  = cal2_state_r[2:0];
generate
  if (nCK_PER_CLK == 4) begin: div4_clk
    assign dbg_phy_wrcal[12:5] = {sr_fall3_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise3_r[0][RD_SHIFT_LEN-1:0],
                                  sr_fall2_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise2_r[0][RD_SHIFT_LEN-1:0],
                                  sr_fall1_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise1_r[0][RD_SHIFT_LEN-1:0],
                                  sr_fall0_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise0_r[0][RD_SHIFT_LEN-1:0]};
  end else begin: div2_clk
    assign dbg_phy_wrcal[12:5] = {sr_fall1_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise1_r[0][RD_SHIFT_LEN-1:0],
                                  sr_fall0_r[0][RD_SHIFT_LEN-1:0],
                                  sr_rise0_r[0][RD_SHIFT_LEN-1:0]};
  end
endgenerate  
  assign dbg_phy_wrcal[15:13]= wrcal_dqs_cnt_r;


  
   //**************************************************************************
   // DQS count to hard PHY during write calibration using Phaser_OUT Stage2
   // coarse delay 
   //**************************************************************************
   assign po_stg2_wrcal_cnt = (cal2_done_r1) ? wrcal_regl_dqs_cnt : wrcal_dqs_cnt_r;



  //***************************************************************************
  // Data mux to route appropriate byte to calibration logic - i.e. calibration
  // is done sequentially, one byte (or DQS group) at a time
  //***************************************************************************

  always @(posedge clk) begin
    rd_mux_sel_r <= #TCQ wrcal_dqs_cnt_r;
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
      wrcal_prech_req <= #TCQ 1'b0;
    else
      // Combine requests from all stages here
      wrcal_prech_req <= #TCQ cal2_prech_req_r;

  //***************************************************************************
  // Shift register to store last RDDATA_SHIFT_LEN cycles of data from ISERDES
  // NOTE: Written using discrete flops, but SRL can be used if the matching
  //   logic does the comparison sequentially, rather than parallel
  //***************************************************************************

  generate
    genvar rd_i;
    if (nCK_PER_CLK == 4) begin: div4_logic_clk
      for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
        always @(posedge clk) begin
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
    end else begin: div2_logic_clk  
      for (rd_i = 0; rd_i < DRAM_WIDTH; rd_i = rd_i + 1) begin: gen_sr
        always @(posedge clk) begin
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
  endgenerate


  
  //*****************************************************************
  


 //***************************************************************************
  // Write calibration:
  // During write leveling DQS is aligned to the nearest CK edge that may not 
  // be the correct CK edge. Write calibration is required to align the DQS to 
  // the correct CK edge that clocks the write command.  
  // The Phaser_Out coarse delay line is adjusted if required to add a memory
  // clock cycle of delay in order to read back the expected pattern.
  //***************************************************************************

  
  always @(posedge clk)
    if (wrcal_start) begin
      rd_active_r         <= #TCQ phy_rddata_en;
      rd_active_posedge_r <= #TCQ phy_rddata_en & ~rd_active_r;
    end

  //*****************************************************************
  // Expected data pattern when properly aligned through bitslip
  // Based on pattern of ({rise,fall}) =
  //   0xF, 0x0, 0xA, 0x5, 0x5, 0xA, 0x9, 0x6
  // Examining only the LSb of each DQS group, pattern is =
  //   bit3: 1, 0, 1, 0, 0, 1, 1, 0
  //   bit2: 1, 0, 0, 1, 1, 0, 0, 1
  //   bit1: 1, 0, 1, 0, 0, 1, 0, 1
  //   bit0: 1, 0, 0, 1, 1, 0, 1, 0
  // Change the hard-coded pattern below accordingly as RD_SHIFT_LEN
  // and the actual training pattern contents change
  //*****************************************************************
generate
  if (nCK_PER_CLK == 2) begin: DIV2
    assign pat_rise0[3] = 2'b10;
    assign pat_fall0[3] = 2'b01;
    assign pat_rise1[3] = 2'b11;
    assign pat_fall1[3] = 2'b00;
    
    assign pat_rise0[2] = 2'b11;
    assign pat_fall0[2] = 2'b00;
    assign pat_rise1[2] = 2'b00;
    assign pat_fall1[2] = 2'b11;
    
    assign pat_rise0[1] = 2'b10;
    assign pat_fall0[1] = 2'b01;
    assign pat_rise1[1] = 2'b10;
    assign pat_fall1[1] = 2'b01;
    
    assign pat_rise0[0] = 2'b11;
    assign pat_fall0[0] = 2'b00;
    assign pat_rise1[0] = 2'b01;
    assign pat_fall1[0] = 2'b10;
  end else begin: DIV4
    assign pat_rise0[3] = 1'b1;
    assign pat_fall0[3] = 1'b0;
    assign pat_rise1[3] = 1'b1;
    assign pat_fall1[3] = 1'b0;
    assign pat_rise2[3] = 1'b0;
    assign pat_fall2[3] = 1'b1;
    assign pat_rise3[3] = 1'b1;
    assign pat_fall3[3] = 1'b0;
    
    assign pat_rise0[2] = 1'b1;
    assign pat_fall0[2] = 1'b0;
    assign pat_rise1[2] = 1'b0;
    assign pat_fall1[2] = 1'b1;
    assign pat_rise2[2] = 1'b1;
    assign pat_fall2[2] = 1'b0;
    assign pat_rise3[2] = 1'b0;
    assign pat_fall3[2] = 1'b1;
    
    assign pat_rise0[1] = 1'b1;
    assign pat_fall0[1] = 1'b0;
    assign pat_rise1[1] = 1'b1;
    assign pat_fall1[1] = 1'b0;
    assign pat_rise2[1] = 1'b0;
    assign pat_fall2[1] = 1'b1;
    assign pat_rise3[1] = 1'b0;
    assign pat_fall3[1] = 1'b1;
    
    assign pat_rise0[0] = 1'b1;
    assign pat_fall0[0] = 1'b0;
    assign pat_rise1[0] = 1'b0;
    assign pat_fall1[0] = 1'b1;
    assign pat_rise2[0] = 1'b1;
    assign pat_fall2[0] = 1'b0;
    assign pat_rise3[0] = 1'b1;
    assign pat_fall3[0] = 1'b0;
  end
endgenerate

  // Each bit of each byte is compared to expected pattern.
  // This was done to prevent (and "drastically decrease") the chance that
  // invalid data clocked in when the DQ bus is tri-state (along with a
  // combination of the correct data) will resemble the expected data
  // pattern. A better fix for this is to change the training pattern and/or
  // make the pattern longer.
  generate
    genvar pt_i;
    for (pt_i = 0; pt_i < DRAM_WIDTH; pt_i = pt_i + 1) begin: gen_pat_match
      always @(posedge clk) begin
        if (sr_rise0_r[pt_i] == pat_rise0[pt_i%4])
          pat_match_rise0_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_rise0_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall0_r[pt_i] == pat_fall0[pt_i%4])
          pat_match_fall0_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_fall0_r[pt_i] <= #TCQ 1'b0;

        if (sr_rise1_r[pt_i] == pat_rise1[pt_i%4])
          pat_match_rise1_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_rise1_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall1_r[pt_i] == pat_fall1[pt_i%4])
          pat_match_fall1_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_fall1_r[pt_i] <= #TCQ 1'b0;
        
        if (sr_rise2_r[pt_i] == pat_rise2[pt_i%4])
          pat_match_rise2_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_rise2_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall2_r[pt_i] == pat_fall2[pt_i%4])
          pat_match_fall2_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_fall2_r[pt_i] <= #TCQ 1'b0;

        if (sr_rise3_r[pt_i] == pat_rise3[pt_i%4])
          pat_match_rise3_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_rise3_r[pt_i] <= #TCQ 1'b0;

        if (sr_fall3_r[pt_i] == pat_fall3[pt_i%4])
          pat_match_fall3_r[pt_i] <= #TCQ 1'b1;
        else
          pat_match_fall3_r[pt_i] <= #TCQ 1'b0;
      end
    end
  endgenerate

  always @(posedge clk) begin
    pat_match_rise0_and_r <= #TCQ &pat_match_rise0_r;
    pat_match_fall0_and_r <= #TCQ &pat_match_fall0_r;
    pat_match_rise1_and_r <= #TCQ &pat_match_rise1_r;
    pat_match_fall1_and_r <= #TCQ &pat_match_fall1_r;
    pat_match_rise2_and_r <= #TCQ &pat_match_rise2_r;
    pat_match_fall2_and_r <= #TCQ &pat_match_fall2_r;
    pat_match_rise3_and_r <= #TCQ &pat_match_rise3_r;
    pat_match_fall3_and_r <= #TCQ &pat_match_fall3_r;
    pat_data_match_r <= #TCQ (pat_match_rise0_and_r &&
                              pat_match_fall0_and_r &&
                              pat_match_rise1_and_r &&
                              pat_match_fall1_and_r &&
                              pat_match_rise2_and_r &&
                              pat_match_fall2_and_r &&
                              pat_match_rise3_and_r &&
                              pat_match_fall3_and_r);
  end

  // Generic counter to force wait after read_en is issued
  // Have to re-visit this logic based on IN_FIFO timing
  always @(posedge clk)
    if (rst || ((cal2_state_r == CAL2_READ_WAIT) 
                && (cnt_rden_wait_r == 'b1)))
      cnt_rden_wait_r <= #TCQ 'b0;
    else if (rd_active_posedge_r)
        cnt_rden_wait_r <= #TCQ RDEN_WAIT_CNT;
    else if (cnt_rden_wait_r > 'b1)
        cnt_rden_wait_r <= #TCQ cnt_rden_wait_r - 1;

  
  always @(posedge clk)
    if (rst || (cnt_rden_wait_r == 'b1))
      rden_wait_r <= #TCQ 1'b0;
    else if (cal2_state_r != CAL2_READ_WAIT)
      rden_wait_r <= #TCQ 1'b1;


  always @(posedge clk) begin
    wrcal_pat_resume_r1 <= #TCQ wrcal_pat_resume_r;
    wrcal_pat_resume_r2 <= #TCQ wrcal_pat_resume_r1;
    wrcal_pat_resume_r3 <= #TCQ wrcal_pat_resume_r2;
  end
  
  // Need to delay it by 3 cycles in order to wait for Phaser_Out
  // coarse delay to take effect before issuing a write command
  assign wrcal_pat_resume = wrcal_pat_resume_r3;
  
   // Inc Phaser_Out stage 2 Coarse delay line
   always @(posedge clk) begin
     if (rst) begin
     // Coarse delay line used during write calibration
       dqs_po_stg2_c_incdec   <= #TCQ 1'b0;
       dqs_po_en_stg2_c       <= #TCQ 1'b0;
     // Inc Phaser_Out coarse delay during write calibration
     end else if (cal2_state_r == CAL2_CORSE_INC) begin
       dqs_po_stg2_c_incdec <= #TCQ 1'b1;
       dqs_po_en_stg2_c     <= #TCQ 1'b1;
     end else if (cal2_state_r == CAL2_CORSE_INC_WAIT) begin
       dqs_po_stg2_c_incdec <= #TCQ 1'b0;
       dqs_po_en_stg2_c     <= #TCQ 1'b0; 
     end
   end

   // This counter used to implement settling time for
   // Phaser_Out fine delay line after final_val
   // loaded for different DQSs
   always @(posedge clk) begin
     if (rst || ((wrcal_regl_dqs_cnt == DQS_WIDTH-1)
              && (wrcal_done_cnt == 4'd1)))
       wrcal_done_cnt <= #TCQ 'b0;
     else if ((cal2_done_r && ~cal2_done_r1)
              || (wrcal_done_cnt == 4'd1))
       wrcal_done_cnt <= #TCQ 4'b1010;
     else if (wrcal_done_cnt > 'b0)
       wrcal_done_cnt <= #TCQ wrcal_done_cnt - 1;
   end

   always @(posedge clk) begin
     if (rst || (wrcal_done_cnt == 4'd0))
       wrcal_regl_dqs_cnt    <= #TCQ {DQS_CNT_WIDTH+1{1'b0}};
     else if (cal2_done_r && (wrcal_regl_dqs_cnt != DQS_WIDTH-1)
                  && (wrcal_done_cnt == 4'd1))
       wrcal_regl_dqs_cnt  <= #TCQ wrcal_regl_dqs_cnt + 1;
     else
       wrcal_regl_dqs_cnt  <= #TCQ wrcal_regl_dqs_cnt;
   end

   // Load Phaser_OUT register with final delay value.
   // For multi-rank systems same value used for all
   // ranks from single Phaser_OUT register.
   always @(posedge clk) begin
     if (rst || (wrcal_done_cnt == 4'd0)) begin
       dqs_po_stg2_load  <= #TCQ 'b0;
       dqs_po_stg2_reg_l <= #TCQ 'b0;
     end else if (cal2_done_r && (wrcal_regl_dqs_cnt <= DQS_WIDTH-1)
                  && (wrcal_done_cnt == 4'd2)) begin
       dqs_po_stg2_load  <= #TCQ 'b1;
       dqs_po_stg2_reg_l <= #TCQ {(cal2_corse_cnt[3*wrcal_regl_dqs_cnt+:3] + wl_po_coarse_cnt[3*wrcal_regl_dqs_cnt+:3]),
                                  wl_po_fine_cnt[6*wrcal_regl_dqs_cnt+:6]};
     end else begin
       dqs_po_stg2_load  <= #TCQ 'b0;
       dqs_po_stg2_reg_l <= #TCQ 'b0;
     end
   end     

   
  //*****************************************************************
  // Write Calibration state machine
  //*****************************************************************

  // when calibrating, check to see if the expected pattern is received.
  // Otherwise delay DQS to align to correct CK edge.
  // NOTES:
  //  1. An error condition can occur due to two reasons:
  //    a. If the matching logic does not receive the expected data
  //       pattern. However, the error may be "recoverable" because 
  //       the write calibration is still in progress. If an error is
  //       found the write calibration logic delays DQS by an additional
  //       clock cycle and restarts the pattern detection process.
  //       By design, if the write path timing is incorrect, the correct
  //       data pattern will never be detected.
  //    b. Valid data not found even after incrementing Phaser_Out
  //       coarse delay line.


  always @(posedge clk) begin
    if (rst) begin
      wrcal_dqs_cnt_r       <= #TCQ 'b0;
      cal2_done_r           <= #TCQ 1'b0;
      cal2_prech_req_r      <= #TCQ 1'b0;
      cal2_state_r          <= #TCQ CAL2_IDLE;
      cal2_corse_cnt        <= #TCQ {3*DQS_WIDTH{1'b0}};
      wrcal_pat_err         <= #TCQ 1'b0;
      wrcal_pat_resume_r      <= #TCQ 1'b0;
    end else begin
      cal2_prech_req_r <= #TCQ 1'b0;

      case (cal2_state_r)
        CAL2_IDLE:
          if (wrcal_start) begin
            if (SIM_CAL_OPTION == "SKIP_CAL")
              // If skip write calibration, then proceed to end.
              cal2_state_r <= #TCQ CAL2_DONE;
            else
              cal2_state_r <= #TCQ CAL2_READ_WAIT;
          end

        // General wait state to wait for read data to be output by the
        // IN_FIFO
        CAL2_READ_WAIT: begin
          wrcal_pat_resume_r <= #TCQ 1'b0;
          // Wait for rising edge of read enable signal to the IN_FIFO
          if (!rden_wait_r)
            cal2_state_r <= #TCQ CAL2_DETECT_MATCH;
        end

        // Wait until either a match is found, or until enough cycles
        // have passed that there could not possibly be a match
        CAL2_DETECT_MATCH: begin
          if (pat_data_match_r)
            // If found data match, then move on to next DQS group
            cal2_state_r <= #TCQ CAL2_NEXT_DQS;
          else begin
              // Otherwise, if no match found delay DQS by 1 clock cycle,
              // issue another write command and try once more. If no
              // match a second time then other issues with either write
              // or read.
              if (cal2_corse_cnt[3*wrcal_dqs_cnt_r+:3] == 'd0)
                cal2_state_r <= #TCQ CAL2_CORSE_INC;
              else
                cal2_state_r <= #TCQ CAL2_ERROR_TO;
           end
        end
        
        CAL2_CORSE_INC: begin
          cal2_state_r <= #TCQ CAL2_CORSE_INC_WAIT;
          cal2_corse_cnt[3*wrcal_dqs_cnt_r+:3]  <= 
            #TCQ cal2_corse_cnt[3*wrcal_dqs_cnt_r+:3] + 1;
        end

        CAL2_CORSE_INC_WAIT: begin
          if (cal2_corse_cnt[3*wrcal_dqs_cnt_r+:3] == 'd3) begin
            cal2_state_r <= #TCQ CAL2_READ_WAIT;
            wrcal_pat_resume_r <= #TCQ 1'b1;
          end else begin
            cal2_state_r <= #TCQ CAL2_CORSE_INC;
            // wrcal_pat_resume_r only asserted once per DQS since we do
            // not forsee using more than a clock cycle of delay in this
            // stage of calibration.
            wrcal_pat_resume_r <= #TCQ 1'b0;
          end
        end
          
        // Final processing for current DQS group. Move on to next group
        CAL2_NEXT_DQS: begin
          // At this point, we've just found the correct pattern for the
          // current DQS group.
           
          // Request bank/row precharge, and wait for its completion. Always
          // precharge after each DQS group to avoid tRAS(max) violation
          cal2_prech_req_r  <= #TCQ 1'b1;
          if (prech_done)
            if (((DQS_WIDTH == 1) || (SIM_CAL_OPTION == "FAST_CAL")) ||
                (wrcal_dqs_cnt_r == DQS_WIDTH-1)) begin
              // If either FAST_CAL is enabled and first DQS group is 
              // finished, or if the last DQS group was just finished,
              // then end of write calibration
              cal2_state_r       <= #TCQ CAL2_DONE;
            end else begin
              // Continue to next DQS group
              wrcal_dqs_cnt_r    <= #TCQ wrcal_dqs_cnt_r + 1;
              cal2_state_r       <= #TCQ CAL2_READ_WAIT;
            end
        end

        // Finished with read enable calibration
        CAL2_DONE:
          cal2_done_r <= #TCQ 1'b1;

        // Assert error signal indicating that writes timing is incorrect
        CAL2_ERROR_TO: begin
          wrcal_pat_resume_r <= #TCQ 1'b0;
          wrcal_pat_err    <= #TCQ 1'b1;
          cal2_state_r     <= #TCQ CAL2_ERROR_TO;
        end
      endcase
    end
  end



  // Delay assertion of wrcal_done for write calibration by a few cycles after
  // we've reached CAL2_DONE
  always @(posedge clk)
    if (rst) begin 
      cal2_done_r1  <= #TCQ 1'b0;
      cal2_done_r2  <= #TCQ 1'b0;
      cal2_done_r3  <= #TCQ 1'b0;
    end else begin
      cal2_done_r1  <= #TCQ cal2_done_r;
      cal2_done_r2  <= #TCQ cal2_done_r1;
      cal2_done_r3  <= #TCQ cal2_done_r2;
    end // else: !if(rst)
  
  always @(posedge clk)
    if (rst)
      wrcal_done <= #TCQ 1'b0;
    else if ((wrcal_regl_dqs_cnt == DQS_WIDTH-1) && (wrcal_done_cnt == 'd1))
      wrcal_done <= #TCQ 1'b1;
  


endmodule
