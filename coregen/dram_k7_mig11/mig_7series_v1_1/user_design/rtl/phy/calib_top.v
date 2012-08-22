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
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: calib_top.v
// /___/   /\     Date Last Modified: $Date: 2011/01/07 20:30:53 $
// \   \  /  \    Date Created: Aug 03 2009
//  \___\/\___\
//
//Device: 7 Series
//Design Name: DDR3 SDRAM
//Purpose:
//Purpose:
//   Top-level for memory physical layer (PHY) interface
//   NOTES:
//     1. Need to support multiple copies of CS outputs
//     2. DFI_DRAM_CKE_DISABLE not supported
//
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: calib_top.v,v 1.7.4.1 2011/01/07 20:30:53 mgeorge Exp $
**$Date: 2011/01/07 20:30:53 $
**$Author: mgeorge $
**$Revision: 1.7.4.1 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_1/data/dlib/7series/ddr3_sdram/verilog/rtl/phy/calib_top.v,v $
******************************************************************************/

`timescale 1ps/1ps

module calib_top #
  (
   parameter TCQ             = 100,
   parameter nCK_PER_CLK     = 2,       // # of memory clocks per CLK
   parameter CLK_PERIOD      = 3333,    // Internal clock period (in ps)
   parameter N_CTL_LANES     = 3,       // # of control byte lanes in the PHY
   parameter DRAM_TYPE       = "DDR3",  // Memory I/F type: "DDR3", "DDR2"
   parameter PRBS_WIDTH      = 64,      // The PRBS sequence is 2^PRBS_WIDTH
   parameter HIGHEST_LANE    = 4,
   parameter HIGHEST_BANK    = 3,
   parameter DQS_BYTE_MAP         
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00,
   // Slot Conifg parameters
   parameter [7:0] SLOT_1_CONFIG = 8'b0000_0000,
   // DRAM bus widths
   parameter BANK_WIDTH      = 2,       // # of bank bits
   parameter COL_WIDTH       = 10,      // column address width
   parameter nCS_PER_RANK    = 1,       // # of unique CS outputs per rank
   parameter DQ_WIDTH        = 64,      // # of DQ (data)
   parameter DQS_CNT_WIDTH   = 3,       // = ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH       = 8,       // # of DQS (strobe)
   parameter DRAM_WIDTH      = 8,       // # of DQ per DQS
   parameter ROW_WIDTH       = 14,      // DRAM address bus width
   parameter RANKS           = 1,       // # of memory ranks in the interface
   parameter CS_WIDTH        = 1,       // # of CS# signals in the interface
   parameter CKE_WIDTH       = 1,       // # of cke outputs
   parameter DDR2_DQSN_ENABLE = "YES",  // Enable differential DQS for DDR2
   parameter PER_BIT_DESKEW  = "ON", 
   // calibration Address. The address given below will be used for calibration
   // read and write operations. 
   parameter CALIB_ROW_ADD   = 16'h0000,// Calibration row address
   parameter CALIB_COL_ADD   = 12'h000, // Calibration column address
   parameter CALIB_BA_ADD    = 3'h0,    // Calibration bank address 
   // DRAM mode settings
   parameter AL              = "0",     // Additive Latency option
   parameter BURST_MODE      = "8",     // Burst length
   parameter BURST_TYPE      = "SEQ",   // Burst type
   parameter nCL             = 5,       // Read CAS latency (in clk cyc)
   parameter nCWL            = 5,       // Write CAS latency (in clk cyc)
   parameter tRFC            = 110000,  // Refresh-to-command delay
   parameter OUTPUT_DRV      = "HIGH",  // DRAM reduced output drive option
   parameter REG_CTRL        = "ON",    // "ON" for registered DIMM
   parameter RTT_NOM         = "60",    // ODT Nominal termination value
   parameter RTT_WR          = "60",    // ODT Write termination value
   parameter WRLVL           = "OFF",   // Enable write leveling
    // Simulation /debug options
   parameter SIM_INIT_OPTION = "NONE",  // Skip various initialization steps
   parameter SIM_CAL_OPTION  = "NONE",  // Skip various calibration steps
   parameter DEBUG_PORT      = "OFF"    // Enable debug port
   )
  (
   input                              clk,         // Internal (logic) clock
   input                              rst,         // Reset sync'ed to CLK
   // Slot present inputs
   input [7:0]                        slot_0_present,
   input [7:0]                        slot_1_present,
   // Hard PHY signals
   // From PHY Ctrl Block
   input                              phy_ctl_ready,
   input                              phy_ctl_full,
   input                              phy_cmd_full,
   input                              phy_data_full,
   // To PHY Ctrl Block
   output                             write_calib,
   output                             read_calib,
   output                             calib_ctl_wren,
   output                             calib_cmd_wren,
   output [1:0]                       calib_seq, 
   output [3:0]                       calib_aux_out0,
   output [3:0]                       calib_aux_out1,
   output [2:0]                       calib_cmd,
   output                             calib_wrdata_en,
   output [1:0]                       calib_rank_cnt,
   output [5:0]                       calib_data_offset,
   output [nCK_PER_CLK*ROW_WIDTH-1:0] phy_address,
   output [nCK_PER_CLK*BANK_WIDTH-1:0]phy_bank,
   output [CS_WIDTH*nCS_PER_RANK*nCK_PER_CLK-1:0] phy_cs_n,
   output [nCK_PER_CLK-1:0]           phy_ras_n,
   output [nCK_PER_CLK-1:0]           phy_cas_n,
   output [nCK_PER_CLK-1:0]           phy_we_n,
   output                             phy_reset_n,
   // To hard PHY wrapper
   output reg [5:0]                   calib_sel,
   output reg                         calib_in_common,
   output reg [HIGHEST_BANK-1:0]      calib_zero_inputs,
//   output reg                         ck_addr_ctl_delay_done,
   // From DQS Phaser_In
   input                              pi_phaselocked,
   input                              pi_phase_locked_all,
   input                              pi_found_dqs,
   input                              pi_dqs_found_all,
   // To DQS Phaser_In
   output                             pi_rst_stg1_cal,
   output                             pi_en_stg2_f,
   output                             pi_stg2_f_incdec,
   output                             pi_stg2_load,
   output [5:0]                       pi_stg2_reg_l,
   // To DQS Phaser_Out
   output                             po_sel_stg2stg3,
   output                             po_stg2_c_incdec,
   output                             po_en_stg2_c,
   output                             po_stg2_f_incdec,
   output                             po_en_stg2_f,
   output                             po_stg2_load,
   output [8:0]                       po_stg2_reg_l,
   // To command Phaser_Out
   input                              phy_if_empty,
   // Write data to OUT_FIFO
   output [2*nCK_PER_CLK*DQ_WIDTH-1:0]phy_wrdata,
   // To CNTVALUEIN input of DQ IDELAYs for perbit de-skew
   output [5*RANKS*DQ_WIDTH-1:0]      dlyval_dq,
   // IN_FIFO read enable during write leveling, write calibration,
   // and read leveling
   // Read data from hard PHY fans out to mc and calib logic
   input[2*nCK_PER_CLK*DQ_WIDTH-1:0]  phy_rddata,
   // To MC
   output [6*RANKS-1:0]               calib_rd_data_offset,
   output                             phy_rddata_valid,
   output                             init_calib_complete,
//   output [CKE_WIDTH-1:0]             phy_cke,
   // Debug Port
   // Write leveling logic
//   input  [5*DQS_WIDTH-1:0]   dbg_wr_dqs_tap_set,
//   input  [5*DQS_WIDTH-1:0]   dbg_wr_dq_tap_set,
//   input                      dbg_wr_tap_set_en,
//   output [5*DQS_WIDTH-1:0]   dbg_wl_odelay_dqs_tap_cnt,
//   output [5*DQS_WIDTH-1:0]   dbg_wl_odelay_dq_tap_cnt, 
   output                     dbg_wrlvl_start,
   output                     dbg_wrlvl_done,
   output                     dbg_wrlvl_err,
   output [4:0]               dbg_tap_cnt_during_wrlvl,
   output                     dbg_wl_edge_detect_valid,
   output [DQS_WIDTH-1:0]     dbg_rd_data_edge_detect,
   // Write Calibration Logic
   output [15:0]              dbg_phy_wrcal,
   // Read leveling logic
   output [1:0]               dbg_rdlvl_start,
   output [1:0]               dbg_rdlvl_done,
   output [1:0]               dbg_rdlvl_err,
   output [5*DQS_WIDTH-1:0]   dbg_cpt_first_edge_cnt,
   output [5*DQS_WIDTH-1:0]   dbg_cpt_second_edge_cnt,
   // Delay control
   input                      dbg_idel_up_all,
   input                      dbg_idel_down_all,
   input                      dbg_idel_up_cpt,
   input                      dbg_idel_down_cpt,
   input [DQS_CNT_WIDTH-1:0]  dbg_sel_idel_cpt,
   input                      dbg_sel_all_idel_cpt,
   output [255:0]             dbg_phy_rdlvl, // Read leveling calibration
   output [255:0]             dbg_calib_top    // General PHY debug
   );

  // Advance ODELAY of DQ by extra 0.25*tCK (quarter clock cycle) to center
  // align DQ and DQS on writes. Round (up or down) value to nearest integer
//  localparam integer SHIFT_TBY4_TAP
//             = (CLK_PERIOD + (nCK_PER_CLK*(1000000/(REFCLK_FREQ*64))*2)-1) /
//             (nCK_PER_CLK*(1000000/(REFCLK_FREQ*64))*4);
  
  // Calculate number of slots in the system
  localparam nSLOTS  = 1 + (|SLOT_1_CONFIG ? 1 : 0);


  wire [PRBS_WIDTH-1:0]            prbs_o;
  wire                             clk_en;
//  wire                             phy_init_data_sel;
  wire                             phy_rddata_en;
  wire                             prech_done;
  wire                             rdlvl_stg1_done;
  wire                             pi_dqs_found_done;
  wire                             rdlvl_stg1_err;
  wire                             rddata_offset_cal_err;
  wire                             wrcal_pat_resume;
  wire                             wrcal_resume_w;
  wire                             rdlvl_prech_req;
  wire                             rdlvl_stg1_start;
  wire                             rdlvl_stg1_rank_done;
  wire                             pi_dqs_found_start;
  wire                             pi_dqs_found_rank_done;
//  wire                             stg2_done_r;
  wire                             wl_sm_start;
  wire                             wrcal_start;
  wire                             wrcal_prech_req;
  wire                             wrcal_pat_err;
  wire                             wrcal_done;
  wire                             wrlvl_done;
  wire                             wrlvl_err;
  wire                             wrlvl_start;
//  wire                             dqs_dly_done;
//  wire                             ck_addr_cmd_delay_done;
//  wire                             po_ck_addr_cmd_delay_done;
  wire                             pi_calib_done;
  wire                             detect_pi_found_dqs;
  wire [5:0]                       rd_data_offset;
  wire [6*RANKS-1:0]               rd_data_offset_ranks;
//  wire                             cmd_po_stg2_f_incdec;
//  wire                             cmd_po_en_stg2_f;
  wire                             po_stg3_f_incdec;
  wire                             po_en_stg3_f;
  wire                             dqs_po_stg2_f_incdec;
  wire                             dqs_po_en_stg2_f;
  wire                             dqs_wl_po_stg2_c_incdec;
  wire                             wrcal_po_stg2_c_incdec;
  wire                             dqs_wl_po_en_stg2_c;
  wire                             wrcal_po_en_stg2_c;
//  wire [1:0]                       ctl_lane_cnt;
//  wire [DQS_CNT_WIDTH:0]           po_stg3_dqs_cnt;
  wire [DQS_CNT_WIDTH:0]           po_stg2_wrcal_cnt;
//  wire [DQS_CNT_WIDTH:0]           pi_phaselock_calib_cnt;
  wire [DQS_CNT_WIDTH:0]           po_stg2_wl_cnt;
  wire [8:0]                       dqs_wl_po_stg2_reg_l;
  wire                             dqs_wl_po_stg2_load;
  wire [8:0]                       dqs_po_stg2_reg_l;
  wire                             dqs_po_stg2_load;
//  wire [DQS_CNT_WIDTH:0]           pi_stg1_dqs_found_cnt;
  wire [DQS_CNT_WIDTH:0]           pi_stg2_rdlvl_cnt;
  reg [DQS_CNT_WIDTH:0]            byte_sel_cnt;
  wire [3*DQS_WIDTH-1:0]           wl_po_coarse_cnt;
  wire [6*DQS_WIDTH-1:0]           wl_po_fine_cnt;
  
  

//*****************************************************************************
// Assertions to check correctness of parameter values
//*****************************************************************************

initial
begin
  if (RANKS == 0) begin 
    $display ("Error: Invalid RANKS parameter. Must be 1 or greater"); 
    $finish;
  end
  if (phy_ctl_full == 1'b1) begin 
    $display ("Error: Incorrect phy_ctl_full input value in 2:1 or 4:1 mode"); 
    $finish;
  end
end



  //***************************************************************************
  // Debug
  //***************************************************************************

  // Unused for now - use these as needed to bring up lower level signals
  assign dbg_calib_top = 256'd0;

  // Write Level and write calibration debug observation ports
  assign dbg_wrlvl_start           = wrlvl_start;  
  assign dbg_wrlvl_done            = wrlvl_done;
  assign dbg_wrlvl_err             = wrlvl_err;
//  assign dbg_wl_odelay_dqs_tap_cnt = dlyval_wrlvl_dqs;
//  assign dbg_wl_odelay_dq_tap_cnt  = dlyval_wrlvl_dq;

  // Read Level debug observation ports
  assign dbg_rdlvl_start           = {pi_dqs_found_start, rdlvl_stg1_start};
  assign dbg_rdlvl_done            = {pi_dqs_found_done, rdlvl_stg1_done};
  assign dbg_rdlvl_err             = {rddata_offset_cal_err, rdlvl_stg1_err};
  
  //***************************************************************************
  // Write leveling dependent signals
  //***************************************************************************

  assign wrcal_resume_w = (WRLVL == "ON") ? wrcal_pat_resume : 1'b0;
  assign wrlvl_done_w = (WRLVL == "ON") ? wrlvl_done : 1'b1;
//  assign ck_addr_cmd_delay_done = (WRLVL == "ON") ? po_ck_addr_cmd_delay_done :
//                                                    1'b1;
  assign po_sel_stg2stg3  = 1'b0;//(~dqs_dly_done) ? 1'b1 : 1'b0;

  assign po_stg2_c_incdec = (wrlvl_done) ? wrcal_po_stg2_c_incdec : 
                                           dqs_wl_po_stg2_c_incdec;
  assign po_en_stg2_c     = (wrlvl_done) ? wrcal_po_en_stg2_c : 
                                           dqs_wl_po_en_stg2_c;
                                           
  assign po_stg2_load     = (wrlvl_done)?  dqs_po_stg2_load :
                                           dqs_wl_po_stg2_load;
  assign po_stg2_reg_l    = (wrlvl_done)?  dqs_po_stg2_reg_l :
                                           dqs_wl_po_stg2_reg_l;
                                           
  assign po_stg2_f_incdec = dqs_po_stg2_f_incdec; //(~dqs_dly_done) ? 
                             //po_stg3_f_incdec : dqs_po_stg2_f_incdec;
  assign po_en_stg2_f     = dqs_po_en_stg2_f; //(~dqs_dly_done) ? 
                             //po_en_stg3_f : dqs_po_en_stg2_f;
  
  assign clk_en = 1'b1;

  //***************************************************************************
  // Hard PHY signals
  //***************************************************************************
  
  assign calib_rd_data_offset = rd_data_offset_ranks;

  
  //***************************************************************************
  // MUX select logic to select current byte undergoing calibration
  // Use DQS_CAL_MAP to determine the correlation between the physical
  // byte numbering, and the byte numbering within the hard PHY
  //***************************************************************************  

  always @(posedge clk) begin
//    if (~ck_addr_cmd_delay_done)
//      byte_sel_cnt <= #TCQ ctl_lane_cnt;
    if (rst) begin
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b0;
//    end else if (~dqs_dly_done) begin
//      byte_sel_cnt    <= #TCQ 'd0;
//      calib_in_common <= #TCQ 1'b1;
    end else if (~wrlvl_done_w) begin
      byte_sel_cnt    <= #TCQ po_stg2_wl_cnt;
      calib_in_common <= #TCQ 1'b0;
    end else if (~pi_calib_done) begin
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b1;
    end else if (~pi_dqs_found_done) begin
      byte_sel_cnt    <= #TCQ 'd0;
      calib_in_common <= #TCQ 1'b0;
    end else if (~rdlvl_stg1_done && pi_calib_done) begin
      byte_sel_cnt    <= #TCQ pi_stg2_rdlvl_cnt;
      calib_in_common <= #TCQ 1'b0;
    end else if (~wrcal_done) begin
      byte_sel_cnt    <= #TCQ po_stg2_wrcal_cnt;
      calib_in_common <= #TCQ 1'b0;
    end
  end

generate 
begin
  always @(posedge clk) begin
    if (rst || init_calib_complete) begin
      calib_sel         <= #TCQ 6'b000100;
      calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
//    end else if (~dqs_dly_done) begin
//      calib_sel         <= #TCQ 6'b000000;
//      calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b0}};
    end else begin
      calib_sel[2]   <= #TCQ 1'b0;
      calib_sel[1:0] <= #TCQ DQS_BYTE_MAP[(byte_sel_cnt*8)+:2];
      calib_sel[5:3] <= #TCQ DQS_BYTE_MAP[((byte_sel_cnt*8)+4)+:3];
      case (DQS_BYTE_MAP[((byte_sel_cnt*8)+4)+:3])
        3'b000: begin
        if (HIGHEST_BANK>=1)
           begin
                  calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
                  calib_zero_inputs[0] <= #TCQ 1'b0;
                end
           end
        3'b001: begin
        if (HIGHEST_BANK>=2)
           begin
                  calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
                  calib_zero_inputs[1] <= #TCQ 1'b0;
                end
           end
        3'b010: begin
        if (HIGHEST_BANK>=3)
           begin
                  calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
                  calib_zero_inputs[2] <= #TCQ 1'b0;
                end
           end
        3'b011: begin
        if (HIGHEST_BANK>=4)
           begin
                  calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
                  calib_zero_inputs[3] <= #TCQ 1'b0;
                end
           end
        3'b100: begin
        if (HIGHEST_BANK==5)
           begin
                  calib_zero_inputs <= #TCQ {HIGHEST_BANK{1'b1}};
                  calib_zero_inputs[4] <= #TCQ 1'b0;
                end
           end
      endcase
    end
  end
end
endgenerate

//  always @(posedge clk) begin
//    ck_addr_ctl_delay_done <= #TCQ ck_addr_cmd_delay_done;
//  end


  //***************************************************************************
  // PRBS Generator for Read Leveling Stage 1 - read window detection and 
  // DQS Centering
  //***************************************************************************
  
  prbs_gen #
    (
     .PRBS_WIDTH  (PRBS_WIDTH)
    )
    u_prbs_gen
      (
       .clk              (clk),
       .clk_en           (clk_en),
       .rst              (rst),
       .prbs_o           (prbs_o)
      );

  //***************************************************************************
  // Delay DQS with respect to DQ for 90 degree offset
  //***************************************************************************
  
//  phy_dqs_delay #
//     (
//      .TCQ           (TCQ),
//      .nCK_PER_CLK   (nCK_PER_CLK),
//      .CLK_PERIOD    (CLK_PERIOD)
//      )
//     u_phy_dqs_delay
//       (
//        .clk              (clk),            
//        .rst              (rst),            
//        .phy_ctl_ready    (phy_ctl_ready),  
//        .po_stg2_f_incdec (po_stg3_f_incdec),
//        .po_en_stg2_f     (po_en_stg3_f),   
//        .dqs_dly_done     (dqs_dly_done)
//       );
  

  //***************************************************************************
  // Initialization / Master PHY state logic (overall control during memory
  // init, timing leveling)
  //***************************************************************************

  phy_init #
    (
     .TCQ             (TCQ),
     .nCK_PER_CLK     (nCK_PER_CLK),
     .CLK_PERIOD      (CLK_PERIOD),
     .DRAM_TYPE       (DRAM_TYPE),
     .PRBS_WIDTH      (PRBS_WIDTH),
     .BANK_WIDTH      (BANK_WIDTH),
     .COL_WIDTH       (COL_WIDTH),
     .nCS_PER_RANK    (nCS_PER_RANK),
     .DQ_WIDTH        (DQ_WIDTH),
     .DQS_WIDTH       (DQS_WIDTH),
     .DQS_CNT_WIDTH   (DQS_CNT_WIDTH),
     .ROW_WIDTH       (ROW_WIDTH),
     .CS_WIDTH        (CS_WIDTH),
     .RANKS           (RANKS),
     .CKE_WIDTH       (CKE_WIDTH),
     .CALIB_ROW_ADD   (CALIB_ROW_ADD),
     .CALIB_COL_ADD   (CALIB_COL_ADD),
     .CALIB_BA_ADD    (CALIB_BA_ADD),
     .AL              (AL),
     .BURST_MODE      (BURST_MODE),
     .BURST_TYPE      (BURST_TYPE),
//     .nAL             (nAL),
     .nCL             (nCL),
     .nCWL            (nCWL),
     .tRFC            (tRFC),
     .OUTPUT_DRV      (OUTPUT_DRV),
     .REG_CTRL        (REG_CTRL),
     .RTT_NOM         (RTT_NOM),
     .RTT_WR          (RTT_WR),
     .WRLVL           (WRLVL),
     .DDR2_DQSN_ENABLE(DDR2_DQSN_ENABLE),
     .nSLOTS          (nSLOTS),
     .SIM_INIT_OPTION (SIM_INIT_OPTION),
     .SIM_CAL_OPTION  (SIM_CAL_OPTION)
     )
    u_phy_init
      (
       .clk                   (clk),
       .rst                   (rst),
       .prbs_o                (prbs_o),
       .dqs_dly_done          (1'b1),//(dqs_dly_done),
//       .ck_addr_cmd_delay_done(ck_addr_cmd_delay_done),
       .pi_phaselocked        (pi_phaselocked),
       .pi_phase_locked_all   (pi_phase_locked_all),
//       .phy_cke                (phy_cke),
//       .pi_phaselock_calib_cnt(pi_phaselock_calib_cnt),
       .pi_calib_done         (pi_calib_done),
       .phy_if_empty          (phy_if_empty),
       .phy_ctl_ready         (phy_ctl_ready),
       .phy_ctl_full          (phy_ctl_full),
       .phy_cmd_full          (phy_cmd_full),
       .phy_data_full         (phy_data_full),
       .calib_ctl_wren        (calib_ctl_wren),
       .calib_cmd_wren        (calib_cmd_wren),
       .calib_wrdata_en       (calib_wrdata_en),
       .calib_seq             (calib_seq),
       .calib_aux_out0        (calib_aux_out0),
       .calib_aux_out1        (calib_aux_out1),
       .calib_rank_cnt        (calib_rank_cnt),
//       .calib_bank_cnt        (calib_bank_cnt),
       .calib_data_offset     (calib_data_offset),
       .calib_cmd             (calib_cmd),
       .write_calib           (write_calib),
       .read_calib            (read_calib),
       .wrlvl_done            (wrlvl_done),
       .wrlvl_rank_done       (wrlvl_rank_done),
       .done_dqs_tap_inc      (done_dqs_tap_inc),
       .wl_sm_start           (wl_sm_start),
       .wr_lvl_start          (wrlvl_start),
       .slot_0_present        (slot_0_present),
       .slot_1_present        (slot_1_present),
       .rdlvl_stg1_done       (rdlvl_stg1_done),
       .rdlvl_stg1_rank_done  (rdlvl_stg1_rank_done),
       .rdlvl_stg1_start      (rdlvl_stg1_start),
       .rdlvl_prech_req       (rdlvl_prech_req),
       .pi_dqs_found_start    (pi_dqs_found_start),
       .pi_dqs_found_rank_done(pi_dqs_found_rank_done),
       .pi_dqs_found_done     (pi_dqs_found_done),
       .detect_pi_found_dqs   (detect_pi_found_dqs),
       .rd_data_offset        (rd_data_offset),
       .rd_data_offset_ranks  (rd_data_offset_ranks),
       .wrcal_start           (wrcal_start),
       .wrcal_prech_req       (wrcal_prech_req),
       .wrcal_resume          (wrcal_resume_w),
       .wrcal_done            (wrcal_done),
       .prech_done            (prech_done),
       .init_calib_complete   (init_calib_complete),
       .phy_address           (phy_address),
       .phy_bank              (phy_bank),
       .phy_cas_n             (phy_cas_n),
       .phy_cs_n              (phy_cs_n),
       .phy_ras_n             (phy_ras_n),
       .phy_reset_n           (phy_reset_n),
       .phy_we_n              (phy_we_n),
       .phy_wrdata            (phy_wrdata),
       .phy_rddata_en         (phy_rddata_en),
       .phy_rddata_valid      (phy_rddata_valid)
       );


  //*****************************************************************
  // Write Calibration
  //*****************************************************************
  
  phy_wrcal #
    (
     .TCQ            (TCQ),
     .nCK_PER_CLK    (nCK_PER_CLK),
     .DQ_WIDTH       (DQ_WIDTH),
     .DQS_CNT_WIDTH  (DQS_CNT_WIDTH),
     .DQS_WIDTH      (DQS_WIDTH),
     .DRAM_WIDTH     (DRAM_WIDTH),
     .SIM_CAL_OPTION (SIM_CAL_OPTION)
     )
    u_phy_wrcal
      (
       .clk                  (clk),
       .rst                  (rst),
       .wrcal_start          (wrcal_start),
       .phy_rddata_en        (phy_rddata_en),
       .wrcal_done           (wrcal_done),
       .wrcal_pat_err        (wrcal_pat_err),
       .wrcal_prech_req      (wrcal_prech_req),
       .prech_done           (prech_done),
       .rd_data_rise0        (phy_rddata[DQ_WIDTH-1:0]),
       .rd_data_fall0        (phy_rddata[2*DQ_WIDTH-1:DQ_WIDTH]),
       .rd_data_rise1        (phy_rddata[3*DQ_WIDTH-1:2*DQ_WIDTH]),
       .rd_data_fall1        (phy_rddata[4*DQ_WIDTH-1:3*DQ_WIDTH]),
       .rd_data_rise2        (phy_rddata[5*DQ_WIDTH-1:4*DQ_WIDTH]),
       .rd_data_fall2        (phy_rddata[6*DQ_WIDTH-1:5*DQ_WIDTH]),
       .rd_data_rise3        (phy_rddata[7*DQ_WIDTH-1:6*DQ_WIDTH]),
       .rd_data_fall3        (phy_rddata[8*DQ_WIDTH-1:7*DQ_WIDTH]),
       .dqs_po_stg2_c_incdec (wrcal_po_stg2_c_incdec),
       .dqs_po_en_stg2_c     (wrcal_po_en_stg2_c),
       .dqs_po_stg2_load     (dqs_po_stg2_load),
       .dqs_po_stg2_reg_l    (dqs_po_stg2_reg_l),
       .wrcal_pat_resume     (wrcal_pat_resume),
       .po_stg2_wrcal_cnt    (po_stg2_wrcal_cnt),
       .wl_po_coarse_cnt     (wl_po_coarse_cnt),
       .wl_po_fine_cnt       (wl_po_fine_cnt),
       .dbg_phy_wrcal        (dbg_phy_wrcal)
   );
  
  

  //***************************************************************************
  // Write-leveling calibration logic
  //***************************************************************************

  generate
    if (WRLVL == "ON") begin: mb_wrlvl_inst
      phy_wrlvl #
        (
         .TCQ               (TCQ),
         .DQS_CNT_WIDTH     (DQS_CNT_WIDTH),
         .DQ_WIDTH          (DQ_WIDTH),
         .DQS_WIDTH         (DQS_WIDTH),
         .DRAM_WIDTH        (DRAM_WIDTH),
         .RANKS             (RANKS),
         .SIM_CAL_OPTION    ("NONE")
         )
        u_phy_wrlvl
          (
           .clk                         (clk),
           .rst                         (rst),
           .wr_level_start              (wrlvl_start),
           .wl_sm_start                 (wl_sm_start),
           .rd_data_rise0               (phy_rddata[DQ_WIDTH-1:0]),
           .wr_level_done               (wrlvl_done),
           .wrlvl_rank_done             (wrlvl_rank_done),
           .done_dqs_tap_inc            (done_dqs_tap_inc),
           .dqs_po_stg2_f_incdec        (dqs_po_stg2_f_incdec),
           .dqs_po_en_stg2_f            (dqs_po_en_stg2_f),
           .dqs_wl_po_stg2_c_incdec     (dqs_wl_po_stg2_c_incdec),
           .dqs_wl_po_en_stg2_c         (dqs_wl_po_en_stg2_c),
           .dqs_wl_po_stg2_load         (dqs_wl_po_stg2_load),
           .dqs_wl_po_stg2_reg_l        (dqs_wl_po_stg2_reg_l),
           .po_stg2_wl_cnt              (po_stg2_wl_cnt),
           .wrlvl_err                   (wrlvl_err),
           .wl_po_coarse_cnt            (wl_po_coarse_cnt),
           .wl_po_fine_cnt              (wl_po_fine_cnt),
           .dbg_wl_tap_cnt              (dbg_tap_cnt_during_wrlvl),
           .dbg_wl_edge_detect_valid    (dbg_wl_edge_detect_valid),
           .dbg_rd_data_edge_detect     (dbg_rd_data_edge_detect),
           .dbg_dqs_count               (),
           .dbg_wl_state                ()
           );
           
//      phy_ck_addr_cmd_delay #
//        (
//         .TCQ               (TCQ),
//         .nCK_PER_CLK       (nCK_PER_CLK),
//         .CLK_PERIOD        (CLK_PERIOD),
//         .N_CTL_LANES       (N_CTL_LANES)
//        )
//        u_phy_ck_addr_cmd_delay
//          (
//           .clk                        (clk),
//           .rst                        (rst),
//           .phy_ctl_ready              (phy_ctl_ready),
//           .ctl_lane_cnt               (ctl_lane_cnt),
//           .po_stg2_f_incdec           (cmd_po_stg2_f_incdec),
//           .po_en_stg2_f               (cmd_po_en_stg2_f),
//           .po_ck_addr_cmd_delay_done  (po_ck_addr_cmd_delay_done)
//          );
      
    end
  endgenerate

       
  //***************************************************************************
  // Read data-offset calibration required for Phaser_In
  //***************************************************************************
  

  phy_dqs_found_cal #
  (
   .TCQ            (TCQ),
   .nCK_PER_CLK    (nCK_PER_CLK),
   .nCL            (nCL),
   .AL             (AL),
   .RANKS          (RANKS),
   .DQS_CNT_WIDTH  (DQS_CNT_WIDTH),
   .DQS_WIDTH      (DQS_WIDTH),
   .DRAM_WIDTH     (DRAM_WIDTH)
   )
    u_phy_dqs_found_cal
      (
       .clk                   (clk),
       .rst                   (rst),
       .pi_dqs_found_start    (pi_dqs_found_start),
       .detect_pi_found_dqs   (detect_pi_found_dqs),
       .pi_found_dqs          (pi_found_dqs),
       .pi_dqs_found_all      (pi_dqs_found_all),
       .pi_rst_stg1_cal       (pi_rst_stg1_cal),
//       .pi_stg1_dqs_found_cnt (pi_stg1_dqs_found_cnt),
       .rd_data_offset        (rd_data_offset),
       .pi_dqs_found_rank_done(pi_dqs_found_rank_done),
       .pi_dqs_found_done     (pi_dqs_found_done),
       .rddata_offset_cal_err (rddata_offset_cal_err),
       .rd_data_offset_ranks  (rd_data_offset_ranks)
       );

  //***************************************************************************
  // Read-leveling calibration logic
  //***************************************************************************

  phy_rdlvl #
    (
     .TCQ             (TCQ),
     .nCK_PER_CLK     (nCK_PER_CLK),
     .CLK_PERIOD      (CLK_PERIOD),
     .DQ_WIDTH        (DQ_WIDTH),
     .DQS_CNT_WIDTH   (DQS_CNT_WIDTH),
     .DQS_WIDTH       (DQS_WIDTH),
     .DRAM_WIDTH      (DRAM_WIDTH),
     .RANKS           (RANKS),
     .PER_BIT_DESKEW  (PER_BIT_DESKEW),
     .SIM_CAL_OPTION  (SIM_CAL_OPTION),
     .DEBUG_PORT      (DEBUG_PORT)
     )
    u_phy_rdlvl
      (
       .clk                     (clk),
       .rst                     (rst),
       .rdlvl_stg1_start        (rdlvl_stg1_start),
       .rdlvl_stg1_done         (rdlvl_stg1_done),
       .rdlvl_stg1_rnk_done     (rdlvl_stg1_rank_done),
       .rdlvl_stg1_err          (rdlvl_stg1_err),
       .rdlvl_prech_req         (rdlvl_prech_req),
       .prech_done              (prech_done),
       .rd_data_rise0           (phy_rddata[DQ_WIDTH-1:0]),
       .rd_data_fall0           (phy_rddata[2*DQ_WIDTH-1:DQ_WIDTH]),
       .rd_data_rise1           (phy_rddata[3*DQ_WIDTH-1:2*DQ_WIDTH]),
       .rd_data_fall1           (phy_rddata[4*DQ_WIDTH-1:3*DQ_WIDTH]),
       .rd_data_rise2           (phy_rddata[5*DQ_WIDTH-1:4*DQ_WIDTH]),
       .rd_data_fall2           (phy_rddata[6*DQ_WIDTH-1:5*DQ_WIDTH]),
       .rd_data_rise3           (phy_rddata[7*DQ_WIDTH-1:6*DQ_WIDTH]),
       .rd_data_fall3           (phy_rddata[8*DQ_WIDTH-1:7*DQ_WIDTH]),
       .pi_en_stg2_f            (pi_en_stg2_f),
       .pi_stg2_f_incdec        (pi_stg2_f_incdec),
       .pi_stg2_load            (pi_stg2_load),
       .pi_stg2_reg_l           (pi_stg2_reg_l),
       .pi_stg2_rdlvl_cnt       (pi_stg2_rdlvl_cnt),
       .dlyval_dq               (dlyval_dq),
       .dbg_cpt_first_edge_cnt  (dbg_cpt_first_edge_cnt),
       .dbg_cpt_second_edge_cnt (dbg_cpt_second_edge_cnt),
       .dbg_idel_up_all         (dbg_idel_up_all),
       .dbg_idel_down_all       (dbg_idel_down_all),
       .dbg_idel_up_cpt         (dbg_idel_up_cpt),
       .dbg_idel_down_cpt       (dbg_idel_down_cpt),
       .dbg_sel_idel_cpt        (dbg_sel_idel_cpt),
       .dbg_sel_all_idel_cpt    (dbg_sel_all_idel_cpt),
       .dbg_phy_rdlvl           (dbg_phy_rdlvl)
       );



endmodule
