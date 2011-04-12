//*****************************************************************************
// (c) Copyright 2008 - 2010 Xilinx, Inc. All rights reserved.
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
// /___/  \  /    Vendor                : Xilinx
// \   \   \/     Version               : %version
//  \   \         Application           : MIG
//  /   /         Filename              : mc.v
// /___/   /\     Date Last Modified    : $date$
// \   \  /  \    Date Created          : Tue Jun 30 2009
//  \___\/\___\
//
//Device            : 7-Series
//Design Name       : DDR3 SDRAM
//Purpose           :
//Reference         :
//Revision History  :
//*****************************************************************************

//*****************************************************************************
// Top level memory sequencer structural block. This block
// instantiates the rank, bank, and column machines.
//*****************************************************************************

`timescale 1ps/1ps

module mc #
  (
    parameter TCQ                   = 100,          // clk->out delay(sim only)
    parameter ADDR_CMD_MODE         = "1T",      // registered or
                                                    // 1Tfered mem?
    parameter BANK_WIDTH            = 3,            // bank address width
    parameter BM_CNT_WIDTH          = 2,            // # BM counter width
                                                    // i.e., log2(nBANK_MACHS)
    parameter BURST_MODE            = "8",          // Burst length
    parameter CL                    = 5,            // Read CAS latency
                                                    // (in clk cyc)
    parameter CMD_PIPE_PLUS1        = "ON",         // add register stage
                                                    // between MC and PHY
    parameter COL_WIDTH             = 12,           // column address width
    parameter CS_WIDTH              = 4,            // # of unique CS outputs
    parameter CWL                   = 5,            // Write CAS latency
                                                    // (in clk cyc)
    parameter DATA_BUF_ADDR_WIDTH   = 8,            // User request tag (e.g.
                                                    // user src/dest buf addr)
    parameter DATA_BUF_OFFSET_WIDTH = 1,            // User buffer offset width
    parameter DATA_WIDTH            = 64,           // Data bus width
    parameter DQ_WIDTH              = 64,           // # of DQ (data)
    parameter DQS_WIDTH             = 8,            // # of DQS (strobe)
    parameter DRAM_TYPE             = "DDR3",       // Memory I/F type:
                                                    // "DDR3", "DDR2" 
    parameter ECC                   = "OFF",        // ECC ON/OFF?
    parameter ECC_WIDTH             = 8,            // # of ECC bits
    parameter MAINT_PRESCALER_PERIOD= 200000,       // maintenance period (ps)
    parameter MC_ERR_ADDR_WIDTH     = 31,           // # of error address bits
    parameter nBANK_MACHS           = 4,            // # of bank machines (BM)
    parameter nCK_PER_CLK           = 4,            // DRAM clock : MC clock
                                                    // frequency ratio
    parameter nCS_PER_RANK          = 1,            // # of unique CS outputs
                                                    // per rank
    parameter nREFRESH_BANK         = 1,            // # of REF cmds to pull-in
    parameter nSLOTS                = 1,            // # DIMM slots in system
    parameter ORDERING              = "NORM",       // request ordering mode
    parameter PAYLOAD_WIDTH         = 64,           // Width of data payload
                                                    // from PHY
    parameter RANK_WIDTH            = 2,            // # of bits to count ranks
    parameter RANKS                 = 4,            // # of ranks of DRAM
    parameter ROW_WIDTH             = 16,           // row address width
    parameter RTT_NOM               = "40",         // Nominal ODT value
    parameter RTT_WR                = "120",        // Write ODT value
    parameter SLOT_0_CONFIG         = 8'b0000_0101, // ranks allowed in slot 0
    parameter SLOT_1_CONFIG         = 8'b0000_1010, // ranks allowed in slot 1
    parameter STARVE_LIMIT          = 2,            // max # of times a user
                                                    // request is allowed to
                                                    // lose arbitration when
                                                    // reordering is enabled
    parameter tCK                   = 2500,         // memory clk period(ns)
    parameter tFAW                  = 40000,        // four activate window(ns)
    parameter tRAS                  = 37500,        // ACT->PRE cmd period (ns)
    parameter tRCD                  = 12500,        // ACT->R/W delay (ns)
    parameter tREFI                 = 7800000,      // average periodic
                                                    // refresh interval(ns)
    parameter tRFC                  = 110000,       // REF->ACT/REF delay (ns)
    parameter tRP                   = 12500,        // PRE cmd period (ns)
    parameter tRRD                  = 10000,        // ACT->ACT period (ns)
    parameter tRTP                  = 7500,         // Read->PRE cmd delay (ns)
    parameter tWTR                  = 7500,         // Internal write->read
                                                    // delay (ns)
    parameter tZQCS                 = 64,           // ZQCS cmd period (CKs)
    parameter tZQI                  = 128_000_000   // ZQCS interval (ns)
  )
  (

    // System inputs

    input                                     clk,
    input                                     rst,

    // Physical memory slot presence

    input         [7:0]                       slot_0_present,
    input         [7:0]                       slot_1_present,

    // Native Interface

    input         [2:0]                       cmd,
    input         [DATA_BUF_ADDR_WIDTH-1:0]   data_buf_addr,
    input                                     hi_priority,
    input                                     size,
  
    input         [BANK_WIDTH-1:0]            bank,
    input         [COL_WIDTH-1:0]             col,
    input         [RANK_WIDTH-1:0]            rank,
    input         [ROW_WIDTH-1:0]             row,
    input                                     use_addr,

    input         [2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0] wr_data,
    input         [2*nCK_PER_CLK*DATA_WIDTH/8-1:0]  wr_data_mask,
    
    output                                    accept,
    output                                    accept_ns,

    output        [BM_CNT_WIDTH-1:0]          bank_mach_next,
    
    output wire   [2*nCK_PER_CLK*PAYLOAD_WIDTH-1:0] rd_data,
    output        [DATA_BUF_ADDR_WIDTH-1:0]   rd_data_addr,
    output                                    rd_data_en,
    output                                    rd_data_end,
    output        [DATA_BUF_OFFSET_WIDTH-1:0] rd_data_offset,
    
    output  reg   [DATA_BUF_ADDR_WIDTH-1:0]   wr_data_addr,
    output  reg                               wr_data_en,
    output  reg   [DATA_BUF_OFFSET_WIDTH-1:0] wr_data_offset,

    // ECC interface

    input                                     correct_en,   
    input         [2*nCK_PER_CLK-1:0]         raw_not_ecc,
    
    output        [MC_ERR_ADDR_WIDTH-1:0]     ecc_err_addr,
    output        [2*nCK_PER_CLK-1:0]         ecc_single,
    output        [2*nCK_PER_CLK-1:0]         ecc_multiple,
    
    // User maintenance requests

    input                                     app_periodic_rd_req,
    input                                     app_ref_req,
    input                                     app_zq_req,

    // MC <==> PHY Interface
    
    output reg  [nCK_PER_CLK-1:0]             mc_ras_n,
    output reg  [nCK_PER_CLK-1:0]             mc_cas_n,
    output reg  [nCK_PER_CLK-1:0]             mc_we_n,
    output reg  [nCK_PER_CLK*ROW_WIDTH-1:0]   mc_address,
    output reg  [nCK_PER_CLK*BANK_WIDTH-1:0]  mc_bank,
    output reg  [CS_WIDTH*nCS_PER_RANK*nCK_PER_CLK-1:0] mc_cs_n,
    output wire                               mc_reset_n,
    output wire [2*nCK_PER_CLK*DQ_WIDTH-1:0]  mc_wrdata,
    output wire [2*nCK_PER_CLK*DQ_WIDTH/8-1:0]mc_wrdata_mask,
    output reg                                mc_wrdata_en,
    
    output wire                               mc_cmd_wren,
    output wire                               mc_ctl_wren,
    output reg  [2:0]                         mc_cmd,
    output reg  [5:0]                         mc_data_offset,
    output reg  [3:0]                         mc_aux_out0,
    output reg  [3:0]                         mc_aux_out1,
    output reg  [1:0]                         mc_rank_cnt,
    
    input       [2*nCK_PER_CLK*DQ_WIDTH-1:0]  phy_rd_data,
    input                                     phy_rddata_valid,
  
    input                                     init_calib_complete,
    input       [6*RANKS-1:0]                 calib_rd_data_offset

  );

  assign mc_reset_n = 1'b1;   // never reset memory
  assign mc_cmd_wren = 1'b1;  // always write CMD FIFO(issue DSEL when idle)
  assign mc_ctl_wren = 1'b1;  // always write CTL FIFO(issue nondata when idle)

  // Ensure there is always at least one rank present during operation
  `ifdef MC_SVA
    ranks_present: assert property
      (@(posedge clk) (rst || (|(slot_0_present | slot_1_present))));
  `endif
   
  //***************************************************************************
  // PHY, datapath, control, bus turnaround delay configuration
  //***************************************************************************

  localparam nWR_EN2CNFG_RD = 4;  // write-enable -> read io_config delay
  localparam nWR_EN2CNFG_WR = 4;  // write-enable -> write io_config delay
  localparam nCNFG2RD_EN = 2;     // io_config -> read-enable delay
  localparam nCNFG2WR = 2;        // io_config -> write delay
  localparam nRD_EN2CNFG_WR =     // read-enable -> write io_config delay
                              (DRAM_TYPE == "DDR2")? 5 : (CL <= 6) ? 7 :
                              ((CL == 7) || (CL == 8)) ? 8 : 9;

  // Reserved. Do not change.
  localparam nPHY_WRLAT = 2;

  // never delay write data control
  localparam DELAY_WR_DATA_CNTRL = ((ECC == "ON") || (CWL < 0) )? 0 : 1;

  // Ensure that write control is delayed for appropriate CWL
  /*`ifdef MC_SVA
    delay_wr_data_zero_CWL_le_6: assert property
      (@(posedge clk) ((CWL > 6) || (DELAY_WR_DATA_CNTRL == 0)));
  `endif*/

  // Pre-fetch WR_DATA_ADDR early when ECC is on, for all CWL
  localparam EARLY_WR_DATA_ADDR = (ECC == "ON") && (CWL < 11)
                                    ? "ON"
                                    : "OFF";

  //***************************************************************************
  // Convert timing parameters from time to clock cycles
  //***************************************************************************
  
  localparam nRP = cdiv(tRP, tCK);
  localparam nRCD = cdiv(tRCD, tCK);
  localparam nRAS = cdiv(tRAS, tCK);
  localparam nFAW = cdiv(tFAW, tCK);
  localparam nRFC = cdiv(tRFC, tCK);

  // Convert tWR. As per specification, write recover for autoprecharge
  // cycles doesn't support values of 9 and 11. Round up 9 to 10 and 11 to 12
  localparam nWR_CK = cdiv(15000, tCK) ;
  localparam nWR = (nWR_CK == 9) ? 10 : (nWR_CK == 11) ? 12 : nWR_CK;

  // tRRD, tWTR at tRTP have a 4 cycle floor in DDR3 and 2 cycle floor in DDR2
  localparam nRRD_CK = cdiv(tRRD, tCK);
  localparam nRRD = (DRAM_TYPE == "DDR3") ? (nRRD_CK < 4) ? 4 : nRRD_CK
                                          : (nRRD_CK < 2) ? 2 : nRRD_CK;
  localparam nWTR_CK = cdiv(tWTR, tCK);
  localparam nWTR = (DRAM_TYPE == "DDR3") ? (nWTR_CK < 4) ? 4 : nWTR_CK
                                          : (nWTR_CK < 2) ? 2 : nWTR_CK;
  localparam nRTP_CK = cdiv(tRTP, tCK);
  localparam nRTP = (DRAM_TYPE == "DDR3") ? (nRTP_CK < 4) ? 4 : nRTP_CK
                                          : (nRTP_CK < 2) ? 2 : nRTP_CK;

  //***************************************************************************
  // Set up maintenance counter dividers
  //***************************************************************************

  // CK clock divisor to generate maintenance prescaler period (round down)
  localparam MAINT_PRESCALER_DIV = MAINT_PRESCALER_PERIOD / (tCK*nCK_PER_CLK);
  
  // Maintenance prescaler divisor for refresh timer. Essentially, this is
  // just (tREFI / MAINT_PRESCALER_PERIOD), but we must account for the worst
  // case delay from the time we get a tick from the refresh counter to the
  // time that we can actually issue the REF command. Thus, subtract tRCD, CL,
  // data burst time and tRP for each implemented bank machine to ensure that
  // all transactions can complete before tREFI expires
  localparam REFRESH_TIMER_DIV =  (tREFI-((tRCD+((CL+4)*tCK)+tRP)*nBANK_MACHS))
                                  / MAINT_PRESCALER_PERIOD;
  
  // Periodic read (RESERVED - not currently required or supported in 7 series)
  // tPRDI should only be set to 0
  localparam tPRDI                 = 0; // Do NOT change.
  localparam PERIODIC_RD_TIMER_DIV = tPRDI / MAINT_PRESCALER_PERIOD;

  // Convert maintenance prescaler from ps to ns
  localparam MAINT_PRESCALER_PERIOD_NS = MAINT_PRESCALER_PERIOD / 1000;
  
  // Maintenance prescaler divisor for ZQ calibration (ZQCS) timer
  localparam ZQ_TIMER_DIV = tZQI / MAINT_PRESCALER_PERIOD_NS;

  // Bus width required to broadcast a single bit rank signal among all the
  // bank machines - 1 bit per rank, per bank
  localparam RANK_BM_BV_WIDTH = nBANK_MACHS * RANKS;
  
  //***************************************************************************
  // Reserved feature control.
  //***************************************************************************

  // Open page wait mode is reserved.
  // nOP_WAIT is the number of states a bank machine will park itself
  // on an otherwise inactive open page before closing the page.  If
  // nOP_WAIT == 0, open page wait mode is disabled.  If nOP_WAIT == -1,
  // the bank machine will remain parked until the pool of idle bank machines
  // are less than LOW_IDLE_CNT.  At which point parked bank machines
  // are selected to exit until the number of idle bank machines exceeds the
  // LOW_IDLE_CNT.
  localparam nOP_WAIT                 = 0;  // Open page mode
  localparam LOW_IDLE_CNT             = 0;  // Low idle bank machine threshold
  
  //***************************************************************************
  // Internal wires
  //***************************************************************************

  wire [RANK_BM_BV_WIDTH-1:0]       act_this_rank_r;
  wire [ROW_WIDTH-1:0]              col_a;
  wire [BANK_WIDTH-1:0]             col_ba;
  wire [DATA_BUF_ADDR_WIDTH-1:0]    col_data_buf_addr;
  wire                              col_periodic_rd;
  wire [RANK_WIDTH-1:0]             col_ra;
  wire                              col_rmw;
  wire                              col_rd_wr;
  wire [ROW_WIDTH-1:0]              col_row;
  wire                              col_size;
  wire [DATA_BUF_ADDR_WIDTH-1:0]    col_wr_data_buf_addr;
  wire                              dq_busy_data;
  wire                              ecc_status_valid;
  wire [RANKS-1:0]                  inhbt_act_faw_r;
  wire                              inhbt_rd_config;
  wire [RANKS-1:0]                  inhbt_rd_r;
  wire                              inhbt_wr_config;
  wire                              insert_maint_r1;
  wire [RANK_WIDTH-1:0]             maint_rank_r;
  wire                              maint_req_r;
  wire                              maint_wip_r;
  wire                              maint_zq_r;
  wire                              periodic_rd_ack_r;
  wire                              periodic_rd_r;
  wire [RANK_WIDTH-1:0]             periodic_rd_rank_r;
  wire [(RANKS*nBANK_MACHS)-1:0]    rank_busy_r;
  wire                              rd_rmw;
  wire [RANK_BM_BV_WIDTH-1:0]       rd_this_rank_r;
  wire [nBANK_MACHS-1:0]            sending_col;
  wire [nBANK_MACHS-1:0]            sending_row;
  wire                              sent_col;
  wire                              wr_ecc_buf;
  wire [RANK_BM_BV_WIDTH-1:0]       wr_this_rank_r;
  wire [RANKS-1:0]                  wtr_inhbt_config_r;
  
  // MC/PHY optional pipeline stage support
  wire [nCK_PER_CLK-1:0]              mc_ras_n_ns;
  wire [nCK_PER_CLK-1:0]              mc_cas_n_ns;
  wire [nCK_PER_CLK-1:0]              mc_we_n_ns;
  wire [nCK_PER_CLK*ROW_WIDTH-1:0]    mc_address_ns;
  wire [nCK_PER_CLK*BANK_WIDTH-1:0]   mc_bank_ns;
  wire [CS_WIDTH*nCS_PER_RANK*nCK_PER_CLK-1:0] mc_cs_n_ns;
  wire [3:0]                          mc_aux_out0_ns;
  wire [3:0]                          mc_aux_out1_ns;
  wire [1:0]                          mc_rank_cnt_ns = col_ra;
  wire [2:0]                          mc_cmd_ns;
  wire [5:0]                          mc_data_offset_ns;
  wire                                mc_wrdata_en_ns;
  
  wire [DATA_BUF_ADDR_WIDTH-1:0]    wr_data_addr_ns;
  wire                              wr_data_en_ns;
  wire [DATA_BUF_OFFSET_WIDTH-1:0]  wr_data_offset_ns;

  wire [RANK_WIDTH:0]               io_config_ns;
  wire                              io_config_strobe_ns;

  integer                           i;

  //***************************************************************************
  // Function cdiv
  //  Description:
  //    This function performs ceiling division (divide and round-up)
  //  Inputs:
  //    num: integer to be divided
  //    div: divisor
  // Outputs:
  //    cdiv: result of ceiling division (num/div, rounded up)
  //***************************************************************************

  function integer cdiv (input integer num, input integer div);
    begin
      // perform division, then add 1 if and only if remainder is non-zero
      cdiv = (num/div) + (((num%div)>0) ? 1 : 0);
    end
  endfunction // cdiv

  //***************************************************************************
  // Optional pipeline register stage on MC/PHY interface
  //***************************************************************************

  generate
    
    if (CMD_PIPE_PLUS1 == "ON") begin : cmd_pipe_plus // register interface

      always @(posedge clk) begin
       
        mc_address <= #TCQ mc_address_ns;
        mc_bank <= #TCQ mc_bank_ns;
        mc_cas_n <= #TCQ mc_cas_n_ns;
        mc_cs_n <= #TCQ mc_cs_n_ns;
        mc_aux_out0 <= #TCQ mc_aux_out0_ns;
        mc_aux_out1 <= #TCQ mc_aux_out1_ns;
        mc_cmd <= #TCQ mc_cmd_ns;
        mc_ras_n <= #TCQ mc_ras_n_ns;
        mc_we_n <= #TCQ mc_we_n_ns;
        mc_data_offset <= #TCQ mc_data_offset_ns;
    
        mc_wrdata_en <= #TCQ mc_wrdata_en_ns;
        mc_rank_cnt <= #TCQ mc_rank_cnt_ns;

        wr_data_addr <= #TCQ wr_data_addr_ns;
        wr_data_en <= #TCQ wr_data_en_ns;
        wr_data_offset <= #TCQ wr_data_offset_ns;

      end // always @ (posedge clk)
    
    end // block: cmd_pipe_plus
    
    else begin : cmd_pipe_plus0 // don't register interface
    
      always @( mc_address or mc_aux_out0 or mc_aux_out1 or mc_bank or
                mc_cas_n or mc_cmd or mc_cs_n or mc_data_offset or
                mc_rank_cnt or mc_ras_n or mc_we_n or mc_wrdata_en or
                wr_data_addr or wr_data_en or wr_data_offset)
      begin

        mc_address = #TCQ mc_address_ns;
        mc_bank = #TCQ mc_bank_ns;
        mc_cas_n = #TCQ mc_cas_n_ns;
        mc_cs_n = #TCQ mc_cs_n_ns;
        mc_aux_out0 = #TCQ mc_aux_out0_ns;
        mc_aux_out1 = #TCQ mc_aux_out1_ns;
        mc_cmd = #TCQ mc_cmd_ns;
        mc_ras_n = #TCQ mc_ras_n_ns;
        mc_we_n = #TCQ mc_we_n_ns;
        mc_data_offset = #TCQ mc_data_offset_ns;
    
        mc_wrdata_en = #TCQ mc_wrdata_en_ns;
        mc_rank_cnt = #TCQ mc_rank_cnt_ns;

        wr_data_addr = #TCQ wr_data_addr_ns;
        wr_data_en = #TCQ wr_data_en_ns;
        wr_data_offset = #TCQ wr_data_offset_ns;
        
        mc_wrdata_en = #TCQ mc_wrdata_en_ns;
        mc_rank_cnt = #TCQ mc_rank_cnt_ns;
        
        wr_data_addr = #TCQ wr_data_addr_ns;
        wr_data_en = #TCQ wr_data_en_ns;
        wr_data_offset = #TCQ wr_data_offset_ns;

      end // always @ (...

    end // block: cmd_pipe_plus0

  endgenerate

  //***************************************************************************
  // Manage rank-level timing and maintanence
  //***************************************************************************
     
  rank_mach #
    (
      // Parameters
      .BURST_MODE             (BURST_MODE),
      .CL                     (CL),
      .CS_WIDTH               (CS_WIDTH),
      .DRAM_TYPE              (DRAM_TYPE),
      .MAINT_PRESCALER_DIV    (MAINT_PRESCALER_DIV),
      .nBANK_MACHS            (nBANK_MACHS),
      .nCK_PER_CLK            (nCK_PER_CLK),
      .nFAW                   (nFAW),
      .nREFRESH_BANK          (nREFRESH_BANK),
      .nRRD                   (nRRD),
      .nWTR                   (nWTR),
      .PERIODIC_RD_TIMER_DIV  (PERIODIC_RD_TIMER_DIV),
      .RANK_BM_BV_WIDTH       (RANK_BM_BV_WIDTH),
      .RANK_WIDTH             (RANK_WIDTH),
      .RANKS                  (RANKS),
      .REFRESH_TIMER_DIV      (REFRESH_TIMER_DIV),
      .ZQ_TIMER_DIV           (ZQ_TIMER_DIV)
    )
    rank_mach0
      (
        // Outputs
        .inhbt_act_faw_r      (inhbt_act_faw_r[RANKS-1:0]),
        .inhbt_rd_r           (inhbt_rd_r[RANKS-1:0]),
        .maint_rank_r         (maint_rank_r[RANK_WIDTH-1:0]),
        .maint_req_r          (maint_req_r),
        .maint_zq_r           (maint_zq_r),
        .periodic_rd_r        (periodic_rd_r),
        .periodic_rd_rank_r   (periodic_rd_rank_r[RANK_WIDTH-1:0]),
        .wtr_inhbt_config_r   (wtr_inhbt_config_r[RANKS-1:0]),
        // Inputs
        .act_this_rank_r      (act_this_rank_r[RANK_BM_BV_WIDTH-1:0]),
        .app_periodic_rd_req  (app_periodic_rd_req),
        .app_ref_req          (app_ref_req),
        .app_zq_req           (app_zq_req),
        .clk                  (clk),
        .init_calib_complete  (init_calib_complete),
        .insert_maint_r1      (insert_maint_r1),
        .maint_wip_r          (maint_wip_r),
        .periodic_rd_ack_r    (periodic_rd_ack_r),
        .rank_busy_r          (rank_busy_r[(RANKS*nBANK_MACHS)-1:0]),
        .rd_this_rank_r       (rd_this_rank_r[RANK_BM_BV_WIDTH-1:0]),
        .rst                  (rst),
        .sending_col          (sending_col[nBANK_MACHS-1:0]),
        .sending_row          (sending_row[nBANK_MACHS-1:0]),
        .slot_0_present       (slot_0_present[7:0]),
        .slot_1_present       (slot_1_present[7:0]),
        .wr_this_rank_r       (wr_this_rank_r[RANK_BM_BV_WIDTH-1:0])
      );

  //***************************************************************************
  // Manage requests, reordering and bank timing
  //***************************************************************************

  bank_mach#
    (
      // Parameters
      .TCQ                     (TCQ),
      .ADDR_CMD_MODE           (ADDR_CMD_MODE),
      .BANK_WIDTH              (BANK_WIDTH),
      .BM_CNT_WIDTH            (BM_CNT_WIDTH),
      .BURST_MODE              (BURST_MODE),
      .COL_WIDTH               (COL_WIDTH),
      .CS_WIDTH                (CS_WIDTH),
      .CWL                     (CWL),
      .DATA_BUF_ADDR_WIDTH     (DATA_BUF_ADDR_WIDTH),
      .DRAM_TYPE               (DRAM_TYPE),
      .EARLY_WR_DATA_ADDR      (EARLY_WR_DATA_ADDR),
      .ECC                     (ECC),
      .LOW_IDLE_CNT            (LOW_IDLE_CNT),
      .nBANK_MACHS             (nBANK_MACHS),
      .nCK_PER_CLK             (nCK_PER_CLK),
      .nCNFG2RD_EN             (nCNFG2RD_EN),
      .nCNFG2WR                (nCNFG2WR),
      .nCS_PER_RANK            (nCS_PER_RANK),
      .nOP_WAIT                (nOP_WAIT),
      .nRAS                    (nRAS),
      .nRCD                    (nRCD),
      .nRFC                    (nRFC),
      .nRP                     (nRP),
      .nRTP                    (nRTP),
      .nSLOTS                  (nSLOTS),
      .nWR                     (nWR),
      .ORDERING                (ORDERING),
      .RANK_BM_BV_WIDTH        (RANK_BM_BV_WIDTH),
      .RANK_WIDTH              (RANK_WIDTH),
      .RANKS                   (RANKS),
      .ROW_WIDTH               (ROW_WIDTH),
      .RTT_NOM                 (RTT_NOM),
      .RTT_WR                  (RTT_WR),
      .SLOT_0_CONFIG           (SLOT_0_CONFIG),
      .SLOT_1_CONFIG           (SLOT_1_CONFIG),
      .STARVE_LIMIT            (STARVE_LIMIT),
      .tZQCS                   (tZQCS)
    )
    bank_mach0
      (
        // Outputs
        .accept                (accept),
        .accept_ns             (accept_ns),
        .act_this_rank_r       (act_this_rank_r[RANK_BM_BV_WIDTH-1:0]),
        .bank_mach_next        (bank_mach_next[BM_CNT_WIDTH-1:0]),
        .col_a                 (col_a[ROW_WIDTH-1:0]),
        .col_ba                (col_ba[BANK_WIDTH-1:0]),
        .col_data_buf_addr     (col_data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .col_periodic_rd       (col_periodic_rd),
        .col_ra                (col_ra[RANK_WIDTH-1:0]),
        .col_rmw               (col_rmw),
        .col_rd_wr             (col_rd_wr),
        .col_row               (col_row[ROW_WIDTH-1:0]),
        .col_size              (col_size),
        .col_wr_data_buf_addr  (col_wr_data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .mc_bank               (mc_bank_ns),
        .mc_address            (mc_address_ns),
        .mc_ras_n              (mc_ras_n_ns),
        .mc_cas_n              (mc_cas_n_ns),
        .mc_we_n               (mc_we_n_ns),
        .mc_cs_n               (mc_cs_n_ns),
        .mc_aux_out0           (mc_aux_out0_ns),
        .mc_aux_out1           (mc_aux_out1_ns),
        .mc_cmd                (mc_cmd_ns),
        .mc_data_offset        (mc_data_offset_ns),
        .insert_maint_r1       (insert_maint_r1),
        .io_config             (io_config_ns[RANK_WIDTH:0]), 
        .io_config_strobe      (io_config_strobe_ns),
        .maint_wip_r           (maint_wip_r),
        .periodic_rd_ack_r     (periodic_rd_ack_r),
        .rank_busy_r           (rank_busy_r[(RANKS*nBANK_MACHS)-1:0]),
        .rd_this_rank_r        (rd_this_rank_r[RANK_BM_BV_WIDTH-1:0]),
        .sending_row           (sending_row[nBANK_MACHS-1:0]),
        .sending_col           (sending_col[nBANK_MACHS-1:0]),
        .sent_col              (sent_col),
        .wr_this_rank_r        (wr_this_rank_r[RANK_BM_BV_WIDTH-1:0]),
        // Inputs
        .bank                  (bank[BANK_WIDTH-1:0]),
        .calib_rddata_offset   (calib_rd_data_offset[5:0]),
        .clk                   (clk),
        .cmd                   (cmd[2:0]),
        .col                   (col[COL_WIDTH-1:0]),
        .data_buf_addr         (data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .init_calib_complete   (init_calib_complete),
        .phy_rddata_valid      (phy_rddata_valid),
        .dq_busy_data          (dq_busy_data),
        .hi_priority           (hi_priority),
        .inhbt_act_faw_r       (inhbt_act_faw_r[RANKS-1:0]),
        .inhbt_rd_config       (inhbt_rd_config),
        .inhbt_rd_r            (inhbt_rd_r[RANKS-1:0]),
        .inhbt_wr_config       (inhbt_wr_config),
        .maint_rank_r          (maint_rank_r[RANK_WIDTH-1:0]),
        .maint_req_r           (maint_req_r),
        .maint_zq_r            (maint_zq_r),
        .periodic_rd_r         (periodic_rd_r),
        .periodic_rd_rank_r    (periodic_rd_rank_r[RANK_WIDTH-1:0]),
        .rank                  (rank[RANK_WIDTH-1:0]),
        .rd_data_addr          (rd_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .rd_rmw                (rd_rmw),
        .row                   (row[ROW_WIDTH-1:0]),
        .rst                   (rst),
        .size                  (size),
        .slot_0_present        (slot_0_present[7:0]),
        .slot_1_present        (slot_1_present[7:0]),
        .use_addr              (use_addr),
        .wtr_inhbt_config_r    (wtr_inhbt_config_r[RANKS-1:0])
      );

  //***************************************************************************
  // Manage DQ bus
  //***************************************************************************
     
  col_mach #
    (
      // Parameters
      .TCQ                     (TCQ),
      .BANK_WIDTH              (BANK_WIDTH),
      .BURST_MODE              (BURST_MODE),
      .COL_WIDTH               (COL_WIDTH),
      .CS_WIDTH                (CS_WIDTH),
      .DATA_BUF_ADDR_WIDTH     (DATA_BUF_ADDR_WIDTH),
      .DATA_BUF_OFFSET_WIDTH   (DATA_BUF_OFFSET_WIDTH),
      .DELAY_WR_DATA_CNTRL     (DELAY_WR_DATA_CNTRL),
      .DQS_WIDTH               (DQS_WIDTH),
      .DRAM_TYPE               (DRAM_TYPE),
      .EARLY_WR_DATA_ADDR      (EARLY_WR_DATA_ADDR),
      .ECC                     (ECC),
      .MC_ERR_ADDR_WIDTH       (MC_ERR_ADDR_WIDTH),
      .nCK_PER_CLK             (nCK_PER_CLK),
      .nPHY_WRLAT              (nPHY_WRLAT),
      .nRD_EN2CNFG_WR          (nRD_EN2CNFG_WR),
      .nWR_EN2CNFG_RD          (nWR_EN2CNFG_RD),
      .nWR_EN2CNFG_WR          (nWR_EN2CNFG_WR),
      .RANK_WIDTH              (RANK_WIDTH),
      .ROW_WIDTH               (ROW_WIDTH)
    )
    col_mach0
      (
        // Outputs
        .mc_wrdata_en         (mc_wrdata_en_ns),
        .dq_busy_data         (dq_busy_data),
        .ecc_err_addr         (ecc_err_addr[MC_ERR_ADDR_WIDTH-1:0]),
        .ecc_status_valid     (ecc_status_valid),
        .inhbt_rd_config      (inhbt_rd_config),
        .inhbt_wr_config      (inhbt_wr_config),
        .rd_data_addr         (rd_data_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .rd_data_en           (rd_data_en),
        .rd_data_end          (rd_data_end),
        .rd_data_offset       (rd_data_offset),
        .rd_rmw               (rd_rmw),
        .wr_data_addr         (wr_data_addr_ns),
        .wr_data_en           (wr_data_en_ns),
        .wr_data_offset       (wr_data_offset_ns),
        .wr_ecc_buf           (wr_ecc_buf),
        // Inputs
        .clk                  (clk),
        .rst                  (rst),
        .col_a                (col_a[ROW_WIDTH-1:0]),
        .col_ba               (col_ba[BANK_WIDTH-1:0]),
        .col_data_buf_addr    (col_data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .col_periodic_rd      (col_periodic_rd),
        .col_ra               (col_ra[RANK_WIDTH-1:0]),
        .col_rmw              (col_rmw),
        .col_rd_wr            (col_rd_wr),
        .col_row              (col_row[ROW_WIDTH-1:0]),
        .col_size             (col_size),
        .col_wr_data_buf_addr (col_wr_data_buf_addr[DATA_BUF_ADDR_WIDTH-1:0]),
        .phy_rddata_valid     (phy_rddata_valid),
        .io_config            (io_config_ns),
        .sent_col             (sent_col)
      );

  //***************************************************************************
  // Implement ECC
  //***************************************************************************
      
  // Total ECC word length = ECC code width + Data width
  localparam CODE_WIDTH = DATA_WIDTH + ECC_WIDTH;

  generate

    if (ECC == "OFF") begin : ecc_off
    
      assign rd_data = phy_rd_data;
      assign mc_wrdata = wr_data;
      assign mc_wrdata_mask = wr_data_mask;
      assign ecc_single = 4'b0;
      assign ecc_multiple = 4'b0;
    
    end

    else begin : ecc_on
      
      wire [CODE_WIDTH*ECC_WIDTH-1:0] h_rows;
      wire [2*nCK_PER_CLK*DATA_WIDTH-1:0] rd_merge_data;
      
      // Merge and encode
      ecc_merge_enc #
        (
          // Parameters
          .TCQ                      (TCQ),
          .CODE_WIDTH               (CODE_WIDTH),
          .DATA_BUF_ADDR_WIDTH      (DATA_BUF_ADDR_WIDTH),
          .DATA_WIDTH               (DATA_WIDTH),
          .DQ_WIDTH                 (DQ_WIDTH),
          .ECC_WIDTH                (ECC_WIDTH),
          .PAYLOAD_WIDTH            (PAYLOAD_WIDTH),
          .nCK_PER_CLK              (nCK_PER_CLK)
        )
        ecc_merge_enc0
          (
            // Outputs
            .mc_wrdata              (mc_wrdata),
            .mc_wrdata_mask         (mc_wrdata_mask),
            // Inputs
            .clk                    (clk),
            .rst                    (rst),
            .h_rows                 (h_rows),
            .rd_merge_data          (rd_merge_data),
            .raw_not_ecc            (raw_not_ecc),
            .wr_data                (wr_data),
            .wr_data_mask           (wr_data_mask)
          );

      // Decode and fix
      ecc_dec_fix #
        (
          // Parameters
          .TCQ                      (TCQ),
          .CODE_WIDTH               (CODE_WIDTH), 
          .DATA_WIDTH               (DATA_WIDTH),
          .DQ_WIDTH                 (DQ_WIDTH),
          .ECC_WIDTH                (ECC_WIDTH),
          .PAYLOAD_WIDTH            (PAYLOAD_WIDTH),
          .nCK_PER_CLK              (nCK_PER_CLK)
        )
        ecc_dec_fix0
          (
            // Outputs
            .ecc_multiple           (ecc_multiple), 
            .ecc_single             (ecc_single),
            .rd_data                (rd_data),
            // Inputs
            .clk                    (clk),
            .rst                    (rst),
            .correct_en             (correct_en),
            .phy_rddata             (phy_rd_data),          
            .ecc_status_valid       (ecc_status_valid),
            .h_rows                 (h_rows)
          );

      // ECC Buffer
      ecc_buf #
        (
          // Parameters
          .TCQ                      (TCQ),
          .DATA_BUF_ADDR_WIDTH      (DATA_BUF_ADDR_WIDTH),
          .DATA_BUF_OFFSET_WIDTH    (DATA_BUF_OFFSET_WIDTH),
          .DATA_WIDTH               (DATA_WIDTH),
          .PAYLOAD_WIDTH            (PAYLOAD_WIDTH),
          .nCK_PER_CLK              (nCK_PER_CLK)
        )
        ecc_buf0
          (           
            // Outputs
            .rd_merge_data          (rd_merge_data),
            // Inputs
            .clk                    (clk),
            .rst                    (rst),
            .rd_data                (rd_data),
            .rd_data_addr           (rd_data_addr),
            .rd_data_offset         (rd_data_offset),
            .wr_data_addr           (wr_data_addr),
            .wr_data_offset         (wr_data_offset),
            .wr_ecc_buf             (wr_ecc_buf)
          );
      
      // Generate ECC table
      ecc_gen #
        (
          // Parameters
          .CODE_WIDTH               (CODE_WIDTH),
          .DATA_WIDTH               (DATA_WIDTH),
          .ECC_WIDTH                (ECC_WIDTH)
        )
        ecc_gen0
          (
            // Outputs
            .h_rows                 (h_rows)
          );

  `ifdef DISPLAY_H_MATRIX

    integer i;

      always @(negedge rst) begin
      
        $display ("**********************************************");
        $display ("H Matrix:");

        for (i=0; i<ECC_WIDTH; i=i+1)
          $display ("%b", h_rows[i*CODE_WIDTH+:CODE_WIDTH]);
       
       $display ("**********************************************");
      
      end
  
  `endif

    end

  endgenerate

endmodule // mc
