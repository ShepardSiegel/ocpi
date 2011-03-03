//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
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
//-----------------------------------------------------------------------------
// Project    : Virtex-6 Integrated Block for PCI Express
// File       : xilinx_pcie_2_0_ep_v6.v
// Version    : 1.7
//--
//-- Description:  PCI Express Endpoint example FPGA design
//--
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

module xilinx_pcie_2_0_ep_v6 # (
  parameter        PL_FAST_TRAIN	        = "FALSE"
)
(
  output  [3:0]    pci_exp_txp,
  output  [3:0]    pci_exp_txn,
  input   [3:0]    pci_exp_rxp,
  input   [3:0]    pci_exp_rxn,

`ifdef ENABLE_LEDS
  output                                       led_0,
  output                                       led_1,
  output                                       led_2,
`endif
  input                                        sys_clk_p,
  input                                        sys_clk_n,
  input                                        sys_reset_n
);


  wire                                        trn_clk;
  wire                                        trn_reset_n;
  wire                                        trn_lnk_up_n;

  // Tx
  wire  [5:0]                                 trn_tbuf_av;
  wire                                        trn_tcfg_req_n;
  wire                                        trn_terr_drop_n;
  wire                                        trn_tdst_rdy_n;
  wire [63:0]                                 trn_td;
  wire                                        trn_trem_n;
  wire                                        trn_tsof_n;
  wire                                        trn_teof_n;
  wire                                        trn_tsrc_rdy_n;
  wire                                        trn_tsrc_dsc_n;
  wire                                        trn_terrfwd_n;
  wire                                        trn_tcfg_gnt_n;
  wire                                        trn_tstr_n;

  // Rx
  wire [63:0]                                 trn_rd;
  wire                                        trn_rrem_n;
  wire                                        trn_rsof_n;
  wire                                        trn_reof_n;
  wire                                        trn_rsrc_rdy_n;
  wire                                        trn_rsrc_dsc_n;
  wire                                        trn_rerrfwd_n;
  wire  [6:0]                                 trn_rbar_hit_n;
  wire                                        trn_rdst_rdy_n;
  wire                                        trn_rnp_ok_n;

  // Flow Control
  wire [11:0]                                 trn_fc_cpld;
  wire [7:0]                                  trn_fc_cplh;
  wire [11:0]                                 trn_fc_npd;
  wire [7:0]                                  trn_fc_nph;
  wire [11:0]                                 trn_fc_pd;
  wire [7:0]                                  trn_fc_ph;
  wire  [2:0]                                 trn_fc_sel;


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  wire [31:0]                                 cfg_do;
  wire                                        cfg_rd_wr_done_n;
  wire  [31:0]                                cfg_di;
  wire   [3:0]                                cfg_byte_en_n;
  wire   [9:0]                                cfg_dwaddr;
  wire                                        cfg_wr_en_n;
  wire                                        cfg_rd_en_n;

  wire                                        cfg_err_cor_n;
  wire                                        cfg_err_ur_n;
  wire                                        cfg_err_ecrc_n;
  wire                                        cfg_err_cpl_timeout_n;
  wire                                        cfg_err_cpl_abort_n;
  wire                                        cfg_err_cpl_unexpect_n;
  wire                                        cfg_err_posted_n;
  wire                                        cfg_err_locked_n;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire                                        cfg_err_cpl_rdy_n;
  wire                                        cfg_interrupt_n;
  wire                                        cfg_interrupt_rdy_n;
  wire                                        cfg_interrupt_assert_n;
  wire  [7:0]                                 cfg_interrupt_di;
  wire [7:0]                                  cfg_interrupt_do;
  wire [2:0]                                  cfg_interrupt_mmenable;
  wire                                        cfg_interrupt_msienable;
  wire                                        cfg_interrupt_msixenable;
  wire                                        cfg_interrupt_msixfm;
  wire                                        cfg_turnoff_ok_n;
  wire                                        cfg_to_turnoff_n;
  wire                                        cfg_trn_pending_n;
  wire                                        cfg_pm_wake_n;
  wire  [7:0]                                 cfg_bus_number;
  wire  [4:0]                                 cfg_device_number;
  wire  [2:0]                                 cfg_function_number;
  wire [15:0]                                 cfg_status;
  wire [15:0]                                 cfg_command;
  wire [15:0]                                 cfg_dstatus;
  wire [15:0]                                 cfg_dcommand;
  wire [15:0]                                 cfg_lstatus;
  wire [15:0]                                 cfg_lcommand;
  wire [15:0]                                 cfg_dcommand2;
  wire  [2:0]                                 cfg_pcie_link_state_n;
  wire  [63:0]                                cfg_dsn;

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  wire [2:0]                                  pl_initial_link_width;
  wire [1:0]                                  pl_lane_reversal_mode;
  wire                                        pl_link_gen2_capable;
  wire                                        pl_link_partner_gen2_supported;
  wire                                        pl_link_upcfg_capable;
  wire [5:0]                                  pl_ltssm_state;
  wire                                        pl_received_hot_rst;
  wire                                        pl_sel_link_rate;
  wire [1:0]                                  pl_sel_link_width;
  wire                                        pl_directed_link_auton;
  wire  [1:0]                                 pl_directed_link_change;
  wire                                        pl_directed_link_speed;
  wire  [1:0]                                 pl_directed_link_width;
  wire                                        pl_upstream_prefer_deemph;

  wire                                        sys_clk_c;
  wire                                        sys_reset_n_c;

  //-------------------------------------------------------

IBUFDS_GTXE1 refclk_ibuf (.O(sys_clk_c), .ODIV2(), .I(sys_clk_p), .IB(sys_clk_n), .CEB(1'b0));

IBUF   sys_reset_n_ibuf (.O(sys_reset_n_c), .I(sys_reset_n));
`ifdef ENABLE_LEDS
   OBUF   led_0_obuf (.O(led_0), .I(sys_reset_n_c));
   OBUF   led_1_obuf (.O(led_1), .I(trn_reset_n));
   OBUF   led_2_obuf (.O(led_2), .I(trn_lnk_up_n));
`endif

FDCP #(

  .INIT(1'b1)

) trn_lnk_up_n_int_i (

  .Q (trn_lnk_up_n),
  .D (trn_lnk_up_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)

);

FDCP #(

  .INIT(1'b1)

) trn_reset_n_i (

  .Q (trn_reset_n),
  .D (trn_reset_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)

);

`ifdef SIMULATION
v6_pcie_v1_7 #( 
  .PL_FAST_TRAIN			( PL_FAST_TRAIN )
)
core (
`else
v6_pcie_v1_7 
core (
`endif

  //-------------------------------------------------------
  // 1. PCI Express (pci_exp) Interface
  //-------------------------------------------------------

  // Tx
  .pci_exp_txp( pci_exp_txp ),
  .pci_exp_txn( pci_exp_txn ),

  // Rx
  .pci_exp_rxp( pci_exp_rxp ),
  .pci_exp_rxn( pci_exp_rxn ),

  //-------------------------------------------------------
  // 2. Transaction (TRN) Interface
  //-------------------------------------------------------

  // Common
  .trn_clk( trn_clk ),
  .trn_reset_n( trn_reset_n_int1 ),
  .trn_lnk_up_n( trn_lnk_up_n_int1 ),

  // Tx
  .trn_tbuf_av( trn_tbuf_av ),
  .trn_tcfg_req_n( trn_tcfg_req_n ),
  .trn_terr_drop_n( trn_terr_drop_n ),
  .trn_tdst_rdy_n( trn_tdst_rdy_n ),
  .trn_td( trn_td ),
  .trn_trem_n( trn_trem_n ),
  .trn_tsof_n( trn_tsof_n ),
  .trn_teof_n( trn_teof_n ),
  .trn_tsrc_rdy_n( trn_tsrc_rdy_n ),
  .trn_tsrc_dsc_n( trn_tsrc_dsc_n ),
  .trn_terrfwd_n( trn_terrfwd_n ),
  .trn_tcfg_gnt_n( trn_tcfg_gnt_n ),
  .trn_tstr_n( trn_tstr_n ),

  // Rx
  .trn_rd( trn_rd ),
  .trn_rrem_n( trn_rrem_n ),
  .trn_rsof_n( trn_rsof_n ),
  .trn_reof_n( trn_reof_n ),
  .trn_rsrc_rdy_n( trn_rsrc_rdy_n ),
  .trn_rsrc_dsc_n( trn_rsrc_dsc_n ),
  .trn_rerrfwd_n( trn_rerrfwd_n ),
  .trn_rbar_hit_n( trn_rbar_hit_n ),
  .trn_rdst_rdy_n( trn_rdst_rdy_n ),
  .trn_rnp_ok_n( trn_rnp_ok_n ),

  // Flow Control
  .trn_fc_cpld( trn_fc_cpld ),
  .trn_fc_cplh( trn_fc_cplh ),
  .trn_fc_npd( trn_fc_npd ),
  .trn_fc_nph( trn_fc_nph ),
  .trn_fc_pd( trn_fc_pd ),
  .trn_fc_ph( trn_fc_ph ),
  .trn_fc_sel( trn_fc_sel ),


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  .cfg_do( cfg_do ),
  .cfg_rd_wr_done_n( cfg_rd_wr_done_n),
  .cfg_di( cfg_di ),
  .cfg_byte_en_n( cfg_byte_en_n ),
  .cfg_dwaddr( cfg_dwaddr ),
  .cfg_wr_en_n( cfg_wr_en_n ),
  .cfg_rd_en_n( cfg_rd_en_n ),

  .cfg_err_cor_n( cfg_err_cor_n ),
  .cfg_err_ur_n( cfg_err_ur_n ),
  .cfg_err_ecrc_n( cfg_err_ecrc_n ),
  .cfg_err_cpl_timeout_n( cfg_err_cpl_timeout_n ),
  .cfg_err_cpl_abort_n( cfg_err_cpl_abort_n ),
  .cfg_err_cpl_unexpect_n( cfg_err_cpl_unexpect_n ),
  .cfg_err_posted_n( cfg_err_posted_n ),
  .cfg_err_locked_n( cfg_err_locked_n ),
  .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy_n( cfg_err_cpl_rdy_n ),
  .cfg_interrupt_n( cfg_interrupt_n ),
  .cfg_interrupt_rdy_n( cfg_interrupt_rdy_n ),
  .cfg_interrupt_assert_n( cfg_interrupt_assert_n ),
  .cfg_interrupt_di( cfg_interrupt_di ),
  .cfg_interrupt_do( cfg_interrupt_do ),
  .cfg_interrupt_mmenable( cfg_interrupt_mmenable ),
  .cfg_interrupt_msienable( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable( cfg_interrupt_msixenable ),
  .cfg_interrupt_msixfm( cfg_interrupt_msixfm ),
  .cfg_turnoff_ok_n( cfg_turnoff_ok_n ),
  .cfg_to_turnoff_n( cfg_to_turnoff_n ),
  .cfg_trn_pending_n( cfg_trn_pending_n ),
  .cfg_pm_wake_n( cfg_pm_wake_n ),
  .cfg_bus_number( cfg_bus_number ),
  .cfg_device_number( cfg_device_number ),
  .cfg_function_number( cfg_function_number ),
  .cfg_status( cfg_status ),
  .cfg_command( cfg_command ),
  .cfg_dstatus( cfg_dstatus ),
  .cfg_dcommand( cfg_dcommand ),
  .cfg_lstatus( cfg_lstatus ),
  .cfg_lcommand( cfg_lcommand ),
  .cfg_dcommand2( cfg_dcommand2 ),
  .cfg_pcie_link_state_n( cfg_pcie_link_state_n ),
  .cfg_dsn( cfg_dsn ),
  .cfg_pmcsr_pme_en( ),
  .cfg_pmcsr_pme_status( ),
  .cfg_pmcsr_powerstate( ),

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  .pl_initial_link_width( pl_initial_link_width ),
  .pl_lane_reversal_mode( pl_lane_reversal_mode ),
  .pl_link_gen2_capable( pl_link_gen2_capable ),
  .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported ),
  .pl_link_upcfg_capable( pl_link_upcfg_capable ),
  .pl_ltssm_state( pl_ltssm_state ),
  .pl_received_hot_rst( pl_received_hot_rst ),
  .pl_sel_link_rate( pl_sel_link_rate ),
  .pl_sel_link_width( pl_sel_link_width ),
  .pl_directed_link_auton( pl_directed_link_auton ),
  .pl_directed_link_change( pl_directed_link_change ),
  .pl_directed_link_speed( pl_directed_link_speed ),
  .pl_directed_link_width( pl_directed_link_width ),
  .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph ),

  //-------------------------------------------------------
  // 5. System  (SYS) Interface
  //-------------------------------------------------------

  .sys_clk( sys_clk_c ),
  .sys_reset_n( sys_reset_n_c )

);


pcie_app_v6 app (

  //-------------------------------------------------------
  // 1. Transaction (TRN) Interface
  //-------------------------------------------------------

  // Common
  .trn_clk( trn_clk ),
  .trn_reset_n( trn_reset_n_int1 ),
  .trn_lnk_up_n( trn_lnk_up_n_int1 ),

  // Tx
  .trn_tbuf_av( trn_tbuf_av ),
  .trn_tcfg_req_n( trn_tcfg_req_n ),
  .trn_terr_drop_n( trn_terr_drop_n ),
  .trn_tdst_rdy_n( trn_tdst_rdy_n ),
  .trn_td( trn_td ),
  .trn_trem_n( trn_trem_n ),
  .trn_tsof_n( trn_tsof_n ),
  .trn_teof_n( trn_teof_n ),
  .trn_tsrc_rdy_n( trn_tsrc_rdy_n ),
  .trn_tsrc_dsc_n( trn_tsrc_dsc_n ),
  .trn_terrfwd_n( trn_terrfwd_n ),
  .trn_tcfg_gnt_n( trn_tcfg_gnt_n ),
  .trn_tstr_n( trn_tstr_n ),

  // Rx
  .trn_rd( trn_rd ),
  .trn_rrem_n( trn_rrem_n ),
  .trn_rsof_n( trn_rsof_n ),
  .trn_reof_n( trn_reof_n ),
  .trn_rsrc_rdy_n( trn_rsrc_rdy_n ),
  .trn_rsrc_dsc_n( trn_rsrc_dsc_n ),
  .trn_rerrfwd_n( trn_rerrfwd_n ),
  .trn_rbar_hit_n( trn_rbar_hit_n ),
  .trn_rdst_rdy_n( trn_rdst_rdy_n ),
  .trn_rnp_ok_n( trn_rnp_ok_n ),

  // Flow Control
  .trn_fc_cpld( trn_fc_cpld ),
  .trn_fc_cplh( trn_fc_cplh ),
  .trn_fc_npd( trn_fc_npd ),
  .trn_fc_nph( trn_fc_nph ),
  .trn_fc_pd( trn_fc_pd ),
  .trn_fc_ph( trn_fc_ph ),
  .trn_fc_sel( trn_fc_sel ),


  //-------------------------------------------------------
  // 2. Configuration (CFG) Interface
  //-------------------------------------------------------

  .cfg_do( cfg_do ),
  .cfg_rd_wr_done_n( cfg_rd_wr_done_n),
  .cfg_di( cfg_di ),
  .cfg_byte_en_n( cfg_byte_en_n ),
  .cfg_dwaddr( cfg_dwaddr ),
  .cfg_wr_en_n( cfg_wr_en_n ),
  .cfg_rd_en_n( cfg_rd_en_n ),

  .cfg_err_cor_n( cfg_err_cor_n ),
  .cfg_err_ur_n( cfg_err_ur_n ),
  .cfg_err_ecrc_n( cfg_err_ecrc_n ),
  .cfg_err_cpl_timeout_n( cfg_err_cpl_timeout_n ),
  .cfg_err_cpl_abort_n( cfg_err_cpl_abort_n ),
  .cfg_err_cpl_unexpect_n( cfg_err_cpl_unexpect_n ),
  .cfg_err_posted_n( cfg_err_posted_n ),
  .cfg_err_locked_n( cfg_err_locked_n ),
  .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy_n( cfg_err_cpl_rdy_n ),
  .cfg_interrupt_n( cfg_interrupt_n ),
  .cfg_interrupt_rdy_n( cfg_interrupt_rdy_n ),
  .cfg_interrupt_assert_n( cfg_interrupt_assert_n ),
  .cfg_interrupt_di( cfg_interrupt_di ),
  .cfg_interrupt_do( cfg_interrupt_do ),
  .cfg_interrupt_mmenable( cfg_interrupt_mmenable ),
  .cfg_interrupt_msienable( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable( cfg_interrupt_msixenable ),
  .cfg_interrupt_msixfm( cfg_interrupt_msixfm ),
  .cfg_turnoff_ok_n( cfg_turnoff_ok_n ),
  .cfg_to_turnoff_n( cfg_to_turnoff_n ),
  .cfg_trn_pending_n( cfg_trn_pending_n ),
  .cfg_pm_wake_n( cfg_pm_wake_n ),
  .cfg_bus_number( cfg_bus_number ),
  .cfg_device_number( cfg_device_number ),
  .cfg_function_number( cfg_function_number ),
  .cfg_status( cfg_status ),
  .cfg_command( cfg_command ),
  .cfg_dstatus( cfg_dstatus ),
  .cfg_dcommand( cfg_dcommand ),
  .cfg_lstatus( cfg_lstatus ),
  .cfg_lcommand( cfg_lcommand ),
  .cfg_dcommand2( cfg_dcommand2 ),
  .cfg_pcie_link_state_n( cfg_pcie_link_state_n ),
  .cfg_dsn( cfg_dsn ),

  //-------------------------------------------------------
  // 3. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  .pl_initial_link_width( pl_initial_link_width ),
  .pl_lane_reversal_mode( pl_lane_reversal_mode ),
  .pl_link_gen2_capable( pl_link_gen2_capable ),
  .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported ),
  .pl_link_upcfg_capable( pl_link_upcfg_capable ),
  .pl_ltssm_state( pl_ltssm_state ),
  .pl_received_hot_rst( pl_received_hot_rst ),
  .pl_sel_link_rate( pl_sel_link_rate ),
  .pl_sel_link_width( pl_sel_link_width ),
  .pl_directed_link_auton( pl_directed_link_auton ),
  .pl_directed_link_change( pl_directed_link_change ),
  .pl_directed_link_speed( pl_directed_link_speed ),
  .pl_directed_link_width( pl_directed_link_width ),
  .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph )

);

endmodule
