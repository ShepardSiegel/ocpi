//-----------------------------------------------------------------------------
//
// (c) Copyright 2008, 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
// FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
// IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
// MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
// and (2) Xilinx shall not be liable (whether in contract or tort, including
// negligence, or under any other theory of liability) for any loss or damage
// of any kind or nature related to, arising under or in connection with these
// materials, including for any direct, or any indirect, special, incidental,
// or consequential loss or damage (including loss of data, profits, goodwill,
// or any type of loss or damage suffered as a result of any action brought by
// a third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// CRITICAL APPLICATIONS
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other
// applications that could lead to death, personal injury, or severe property
// or environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Spartan-6 Integrated Block for PCI Express
// File       : s6_pcie_v1_2.v
// Description: Spartan-6 solution wrapper : Endpoint for PCI Express
//
//-----------------------------------------------------------------------------

`timescale 1ns/1ns

(* CORE_GENERATION_INFO = "s6_pcie_v1_2,s6_pcie_v1_2,{TL_TX_RAM_RADDR_LATENCY=0,TL_TX_RAM_RDATA_LATENCY=2,TL_RX_RAM_RADDR_LATENCY=0,TL_RX_RAM_RDATA_LATENCY=2,TL_RX_RAM_WRITE_LATENCY=0,VC0_TX_LASTPACKET=14,VC0_RX_RAM_LIMIT=7FF,VC0_TOTAL_CREDITS_PH=32,VC0_TOTAL_CREDITS_PD=211,VC0_TOTAL_CREDITS_NPH=8,VC0_TOTAL_CREDITS_CH=40,VC0_TOTAL_CREDITS_CD=211,VC0_CPL_INFINITE=TRUE,BAR0=FF000000,BAR1=FFFF0000,BAR2=00000000,BAR3=00000000,BAR4=00000000,BAR5=00000000,EXPANSION_ROM=000000,USR_CFG=FALSE,USR_EXT_CFG=FALSE,DEV_CAP_MAX_PAYLOAD_SUPPORTED=2,CLASS_CODE=050000,CARDBUS_CIS_POINTER=00000000,PCIE_CAP_CAPABILITY_VERSION=1,PCIE_CAP_DEVICE_PORT_TYPE=0,DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT=0,DEV_CAP_EXT_TAG_SUPPORTED=FALSE,DEV_CAP_ENDPOINT_L0S_LATENCY=7,DEV_CAP_ENDPOINT_L1_LATENCY=7,LINK_CAP_ASPM_SUPPORT=1,MSI_CAP_MULTIMSGCAP=0,MSI_CAP_MULTIMSG_EXTENSION=0,LINK_STATUS_SLOT_CLOCK_CONFIG=FALSE,ENABLE_RX_TD_ECRC_TRIM=FALSE,DISABLE_SCRAMBLING=FALSE,PM_CAP_DSI=FALSE,PM_CAP_D1SUPPORT=TRUE,PM_CAP_D2SUPPORT=TRUE,PM_CAP_PMESUPPORT=0F,PM_DATA0=00,PM_DATA_SCALE0=0,PM_DATA1=00,PM_DATA_SCALE1=0,PM_DATA2=00,PM_DATA_SCALE2=0,PM_DATA3=00,PM_DATA_SCALE3=0,PM_DATA4=00,PM_DATA_SCALE4=0,PM_DATA5=00,PM_DATA_SCALE5=0,PM_DATA6=00,PM_DATA_SCALE6=0,PM_DATA7=00,PM_DATA_SCALE7=0,PCIE_GENERIC=000010101111,GTP_SEL=0,CFG_VEN_ID=10EE,CFG_DEV_ID=4243,CFG_REV_ID=02,CFG_SUBSYS_VEN_ID=10EE,CFG_SUBSYS_ID=0007,REF_CLK_FREQ=1}" *)
module s6_pcie_v1_2
 #(
  parameter   [0:0] TL_TX_RAM_RADDR_LATENCY           = 0,
  parameter   [1:0] TL_TX_RAM_RDATA_LATENCY           = 2,
  parameter   [0:0] TL_RX_RAM_RADDR_LATENCY           = 0,
  parameter   [1:0] TL_RX_RAM_RDATA_LATENCY           = 2,
  parameter   [0:0] TL_RX_RAM_WRITE_LATENCY           = 0,
  parameter   [4:0] VC0_TX_LASTPACKET                 = 14,
  parameter  [11:0] VC0_RX_RAM_LIMIT                  = 12'h7FF,
  parameter   [6:0] VC0_TOTAL_CREDITS_PH              = 32,
  parameter  [10:0] VC0_TOTAL_CREDITS_PD              = 211,
  parameter   [6:0] VC0_TOTAL_CREDITS_NPH             = 8,
  parameter   [6:0] VC0_TOTAL_CREDITS_CH              = 40,
  parameter  [10:0] VC0_TOTAL_CREDITS_CD              = 211,
  parameter         VC0_CPL_INFINITE                  = "TRUE",
  parameter  [31:0] BAR0                              = 32'hFF000000,
  parameter  [31:0] BAR1                              = 32'hFFFF0000,
  parameter  [31:0] BAR2                              = 32'h00000000,
  parameter  [31:0] BAR3                              = 32'h00000000,
  parameter  [31:0] BAR4                              = 32'h00000000,
  parameter  [31:0] BAR5                              = 32'h00000000,
  parameter  [21:0] EXPANSION_ROM                     = 22'h000000,
  parameter         DISABLE_BAR_FILTERING             = "FALSE",
  parameter         DISABLE_ID_CHECK                  = "FALSE",
  parameter         TL_TFC_DISABLE                    = "FALSE",
  parameter         TL_TX_CHECKS_DISABLE              = "FALSE",
  parameter         USR_CFG                           = "FALSE",
  parameter         USR_EXT_CFG                       = "FALSE",
  parameter   [2:0] DEV_CAP_MAX_PAYLOAD_SUPPORTED     = 3'd2,
  parameter  [23:0] CLASS_CODE                        = 24'h050000,
  parameter  [31:0] CARDBUS_CIS_POINTER               = 32'h00000000,
  parameter   [3:0] PCIE_CAP_CAPABILITY_VERSION       = 4'h1,
  parameter   [3:0] PCIE_CAP_DEVICE_PORT_TYPE         = 4'h0,
  parameter         PCIE_CAP_SLOT_IMPLEMENTED         = "FALSE",
  parameter   [4:0] PCIE_CAP_INT_MSG_NUM              = 5'b00000,
  parameter   [1:0] DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT = 2'd0,
  parameter         DEV_CAP_EXT_TAG_SUPPORTED         = "FALSE",
  parameter   [2:0] DEV_CAP_ENDPOINT_L0S_LATENCY      = 3'd7,
  parameter   [2:0] DEV_CAP_ENDPOINT_L1_LATENCY       = 3'd7,
  parameter         SLOT_CAP_ATT_BUTTON_PRESENT       = "FALSE",
  parameter         SLOT_CAP_ATT_INDICATOR_PRESENT    = "FALSE",
  parameter         SLOT_CAP_POWER_INDICATOR_PRESENT  = "FALSE",
  parameter         DEV_CAP_ROLE_BASED_ERROR          = "TRUE",
  parameter   [1:0] LINK_CAP_ASPM_SUPPORT             = 2'd1,
  parameter   [2:0] LINK_CAP_L0S_EXIT_LATENCY         = 3'd7,
  parameter   [2:0] LINK_CAP_L1_EXIT_LATENCY          = 3'd7,
  parameter  [14:0] LL_ACK_TIMEOUT                    = 15'h0000,
  parameter         LL_ACK_TIMEOUT_EN                 = "FALSE",
  parameter  [14:0] LL_REPLAY_TIMEOUT                 = 15'h0000,
  parameter         LL_REPLAY_TIMEOUT_EN              = "FALSE",
  parameter   [2:0] MSI_CAP_MULTIMSGCAP               = 3'd0,
  parameter   [0:0] MSI_CAP_MULTIMSG_EXTENSION        = 1'd0,
  parameter         LINK_STATUS_SLOT_CLOCK_CONFIG     = "FALSE",
  parameter         PLM_AUTO_CONFIG                   = "FALSE",
  parameter         FAST_TRAIN                        = "FALSE",
  parameter         ENABLE_RX_TD_ECRC_TRIM            = "FALSE",
  parameter         DISABLE_SCRAMBLING                = "FALSE",
  parameter   [2:0] PM_CAP_VERSION                    = 3'd3,
  parameter         PM_CAP_PME_CLOCK                  = "FALSE",
  parameter         PM_CAP_DSI                        = "FALSE",
  parameter   [2:0] PM_CAP_AUXCURRENT                 = 3'd0,
  parameter         PM_CAP_D1SUPPORT                  = "TRUE",
  parameter         PM_CAP_D2SUPPORT                  = "TRUE",
  parameter   [4:0] PM_CAP_PMESUPPORT                 = 5'h0F,
  parameter   [7:0] PM_DATA0                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE0                    = 2'h0,
  parameter   [7:0] PM_DATA1                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE1                    = 2'h0,
  parameter   [7:0] PM_DATA2                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE2                    = 2'h0,
  parameter   [7:0] PM_DATA3                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE3                    = 2'h0,
  parameter   [7:0] PM_DATA4                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE4                    = 2'h0,
  parameter   [7:0] PM_DATA5                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE5                    = 2'h0,
  parameter   [7:0] PM_DATA6                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE6                    = 2'h0,
  parameter   [7:0] PM_DATA7                          = 8'h00,
  parameter   [1:0] PM_DATA_SCALE7                    = 2'h0,
  parameter  [11:0] PCIE_GENERIC                      = 12'b000011101111,
  parameter   [0:0] GTP_SEL                           = 1'b0,
  parameter  [15:0] CFG_VEN_ID                        = 16'h10EE,
  parameter  [15:0] CFG_DEV_ID                        = 16'h4243,
  parameter   [7:0] CFG_REV_ID                        = 8'h02,
  parameter  [15:0] CFG_SUBSYS_VEN_ID                 = 16'h10EE,
  parameter  [15:0] CFG_SUBSYS_ID                     = 16'h0007,
  parameter         REF_CLK_FREQ                      = 1) (
  // PCI Express Fabric Interface
  output            pci_exp_txp,
  output            pci_exp_txn,
  input             pci_exp_rxp,
  input             pci_exp_rxn,

  // Transaction (TRN) Interface
  output            trn_lnk_up_n,

  // Tx
  input      [31:0] trn_td,
  input             trn_tsof_n,
  input             trn_teof_n,
  input             trn_tsrc_rdy_n,
  output            trn_tdst_rdy_n,
  output            trn_terr_drop_n,
  input             trn_tsrc_dsc_n,
  input             trn_terrfwd_n,
  output      [5:0] trn_tbuf_av,
  input             trn_tstr_n,
  output            trn_tcfg_req_n,
  input             trn_tcfg_gnt_n,

  // Rx
  output     [31:0] trn_rd,
  output            trn_rsof_n,
  output            trn_reof_n,
  output            trn_rsrc_rdy_n,
  output            trn_rsrc_dsc_n,
  input             trn_rdst_rdy_n,
  output            trn_rerrfwd_n,
  input             trn_rnp_ok_n,
  output      [6:0] trn_rbar_hit_n,
  input       [2:0] trn_fc_sel,
  output      [7:0] trn_fc_nph,
  output     [11:0] trn_fc_npd,
  output      [7:0] trn_fc_ph,
  output     [11:0] trn_fc_pd,
  output      [7:0] trn_fc_cplh,
  output     [11:0] trn_fc_cpld,

  // Host (CFG) Interface
  output     [31:0] cfg_do,
  output            cfg_rd_wr_done_n,
  input       [9:0] cfg_dwaddr,
  input             cfg_rd_en_n,
  input             cfg_err_ur_n,
  input             cfg_err_cor_n,
  input             cfg_err_ecrc_n,
  input             cfg_err_cpl_timeout_n,
  input             cfg_err_cpl_abort_n,
  input             cfg_err_posted_n,
  input             cfg_err_locked_n,
  input      [47:0] cfg_err_tlp_cpl_header,
  output            cfg_err_cpl_rdy_n,
  input             cfg_interrupt_n,
  output            cfg_interrupt_rdy_n,
  input             cfg_interrupt_assert_n,
  output      [7:0] cfg_interrupt_do,
  input       [7:0] cfg_interrupt_di,
  output      [2:0] cfg_interrupt_mmenable,
  output            cfg_interrupt_msienable,
  input             cfg_turnoff_ok_n,
  output            cfg_to_turnoff_n,
  input             cfg_pm_wake_n,
  output      [2:0] cfg_pcie_link_state_n,
  input             cfg_trn_pending_n,
  input      [63:0] cfg_dsn,
  output      [7:0] cfg_bus_number,
  output      [4:0] cfg_device_number,
  output      [2:0] cfg_function_number,
  output     [15:0] cfg_status,
  output     [15:0] cfg_command,
  output     [15:0] cfg_dstatus,
  output     [15:0] cfg_dcommand,
  output     [15:0] cfg_lstatus,
  output     [15:0] cfg_lcommand,

  // System Interface
  input             sys_clk,
  input             sys_reset_n,
  output            trn_clk,
  output            trn_reset_n,
  output            received_hot_reset
  );

  //***************************************************************************
  // Wire Declarations
  //***************************************************************************


  // Wires for the PLL
  wire          mgt_clk;
  wire          mgt_clk_2x;
  wire          clock_locked;
  wire          gt_refclk_out;
  wire          pll_rst;
  wire          clk_125;
  wire          clk_250;
  wire          clk_62_5;
  wire          gt_refclk_buf;
  wire          gt_refclk_fb;

  // These values may be brought out and driven dynamically
  // from pins rather than attributes if desired. Note -
  // if they are not statically driven, the values must be
  // stable before sys_reset_n is released
  wire  [15:0]  w_cfg_ven_id;
  wire  [15:0]  w_cfg_dev_id;
  wire   [7:0]  w_cfg_rev_id;
  wire  [15:0]  w_cfg_subsys_ven_id;
  wire  [15:0]  w_cfg_subsys_id;

  assign w_cfg_ven_id         = CFG_VEN_ID;
  assign w_cfg_dev_id         = CFG_DEV_ID;
  assign w_cfg_rev_id         = CFG_REV_ID;
  assign w_cfg_subsys_ven_id  = CFG_SUBSYS_VEN_ID;
  assign w_cfg_subsys_id      = CFG_SUBSYS_ID;

  wire  [4:0]   cfg_ltssm_state;
  wire  [1:0]   cfg_link_control_aspm_control;
  wire          cfg_link_control_rcb;
  wire          cfg_link_control_common_clock;
  wire          cfg_link_control_extended_sync;
  wire          cfg_command_interrupt_disable;
  wire          cfg_command_serr_en;
  wire          cfg_command_bus_master_enable;
  wire          cfg_command_mem_enable;
  wire          cfg_command_io_enable;
  wire          cfg_dev_status_ur_detected;
  wire          cfg_dev_status_fatal_err_detected;
  wire          cfg_dev_status_nonfatal_err_detected;
  wire          cfg_dev_status_corr_err_detected;
  wire [2:0]    cfg_dev_control_max_read_req;
  wire          cfg_dev_control_no_snoop_en;
  wire          cfg_dev_control_aux_power_en;
  wire          cfg_dev_control_phantom_en;
  wire          cfg_dev_cntrol_ext_tag_en;
  wire [2:0]    cfg_dev_control_max_payload;
  wire          cfg_dev_control_enable_ro;
  wire          cfg_dev_control_ur_err_reporting_en;
  wire          cfg_dev_control_fatal_err_reporting_en;
  wire          cfg_dev_control_non_fatal_reporting_en;
  wire          cfg_dev_control_corr_err_reporting_en;

  wire          mim_rx_rdata_unused;
  wire [11:0]   mim_tx_waddr, mim_tx_raddr, mim_rx_waddr, mim_rx_raddr;
  wire [35:0]   mim_tx_wdata, mim_tx_rdata;
  wire [34:0]   mim_rx_wdata, mim_rx_rdata;
  wire          mim_tx_wen, mim_tx_ren, mim_rx_wen, mim_rx_ren;

  wire          dbg_bad_dllp_status;
  wire          dbg_bad_tlp_lcrc;
  wire          dbg_bad_tlp_seq_num;
  wire          dbg_bad_tlp_status;
  wire          dbg_dl_protocol_status;
  wire          dbg_fc_protocol_err_status;
  wire          dbg_mlfrmd_length;
  wire          dbg_mlfrmd_mps;
  wire          dbg_mlfrmd_tcvc;
  wire          dbg_mlfrmd_tlp_status;
  wire          dbg_mlfrmd_unrec_type;
  wire          dbg_poistlpstatus;
  wire          dbg_rcvr_overflow_status;
  wire          dbg_reg_detected_correctable;
  wire          dbg_reg_detected_fatal;
  wire          dbg_reg_detected_non_fatal;
  wire          dbg_reg_detected_unsupported;
  wire          dbg_rply_rollover_status;
  wire          dbg_rply_timeout_status;
  wire          dbg_ur_no_bar_hit;
  wire          dbg_ur_pois_cfg_wr;
  wire          dbg_ur_status;
  wire          dbg_ur_unsup_msg;

  wire [1:0]    pipe_gt_power_down_a;
  wire [1:0]    pipe_gt_power_down_b;
  wire          pipe_gt_reset_done_a;
  wire          pipe_gt_reset_done_b;
  wire          pipe_gt_tx_elec_idle_a;
  wire          pipe_gt_tx_elec_idle_b;
  wire          pipe_phy_status_a;
  wire          pipe_phy_status_b;
  wire [1:0]    pipe_rx_charisk_a;
  wire [1:0]    pipe_rx_charisk_b;
  wire [15:0]   pipe_rx_data_a;
  wire [15:0]   pipe_rx_data_b;
  wire          pipe_rx_enter_elec_idle_a;
  wire          pipe_rx_enter_elec_idle_b;
  wire          pipe_rx_polarity_a;
  wire          pipe_rx_polarity_b;
  wire          pipe_rxreset_a;
  wire          pipe_rxreset_b;
  wire [2:0]    pipe_rx_status_a;
  wire [2:0]    pipe_rx_status_b;
  wire [1:0]    pipe_tx_char_disp_mode_a;
  wire [1:0]    pipe_tx_char_disp_mode_b;
  wire [1:0]    pipe_tx_char_disp_val_a;
  wire [1:0]    pipe_tx_char_disp_val_b;
  wire [1:0]    pipe_tx_char_is_k_a;
  wire [1:0]    pipe_tx_char_is_k_b;
  wire [15:0]   pipe_tx_data_a;
  wire [15:0]   pipe_tx_data_b;
  wire          pipe_tx_rcvr_det_a;
  wire          pipe_tx_rcvr_det_b;

  // GT->PLM PIPE Interface rx
  wire [1:0]    rx_char_is_k;
  wire [15:0]   rx_data;
  wire          rx_enter_elecidle;
  wire [2:0]    rx_status;
  wire          rx_polarity;

  // GT<-PLM PIPE Interface tx
  wire [1:0]    tx_char_disp_mode;
  wire [1:0]    tx_char_is_k;
  wire          tx_rcvr_det;
  wire [15:0]   tx_data;

  // GT<->PLM PIPE Interface Misc
  wire          phystatus;

  // GT<->PLM PIPE Interface MGT Logic I/O
  wire          gt_reset_done;
  wire          gt_rx_valid;
  wire          gt_tx_elec_idle;
  wire [1:0]    gt_power_down;
  wire          rxreset;
  wire          gt_plllkdet_out;

  // Buffer reference clock from GTP
  BUFIO2  gt_refclk_bufio2 (
      .DIVCLK        ( gt_refclk_buf ),
      .IOCLK         (               ),
      .SERDESSTROBE  (               ),
      .I             ( gt_refclk_out )
  );

  localparam CLKFBOUT_MULT  = (REF_CLK_FREQ == 0) ? 5 :
                              (REF_CLK_FREQ == 1) ? 4 : 2 ;

  localparam CLKIN_PERIOD   = (REF_CLK_FREQ == 0) ? 10 :
                              (REF_CLK_FREQ == 1) ? 8 : 4 ;

  PLL_BASE #(
    //  5 for 100 MHz, 4 for 125Mhz, 2 for 250 MHz
    .CLKFBOUT_MULT    ( CLKFBOUT_MULT ),
    .CLKFBOUT_PHASE   ( 0             ),
    // 10 for 100 MHz, 8 for 125Mhz, 4 for 250 MHz
    .CLKIN_PERIOD     ( CLKIN_PERIOD  ),
    .CLKOUT0_DIVIDE   ( 2             ),
    .CLKOUT0_PHASE    ( 0             ),
    .CLKOUT1_DIVIDE   ( 4             ),
    .CLKOUT1_PHASE    ( 0             ),
    .CLKOUT2_DIVIDE   ( 8             ),
    .CLKOUT2_PHASE    ( 0             ),
    .COMPENSATION     ( "INTERNAL"    )
  ) pll_base_i (
    .CLKIN            ( gt_refclk_buf ),
    .CLKFBIN          ( gt_refclk_fb  ),
    .RST              ( pll_rst       ),
    .CLKOUT0          ( clk_250       ),
    .CLKOUT1          ( clk_125       ),
    .CLKOUT2          ( clk_62_5      ),
    .CLKOUT3          (               ),
    .CLKOUT4          (               ),
    .CLKOUT5          (               ),
    .CLKFBOUT         ( gt_refclk_fb  ),
    .LOCKED           ( clock_locked  )
  );

  //******************************************************************//
  // Instantiate buffers where required                               //
  //******************************************************************//
  BUFG  mgt_bufg    (.O(mgt_clk),    .I(clk_125));
  BUFG  mgt2x_bufg  (.O(mgt_clk_2x), .I(clk_250));
  BUFG  phy_bufg    (.O(trn_clk),    .I(clk_62_5));

  //***************************************************************************
  // PCI Express BRAM Instance
  //***************************************************************************
  pcie_bram_top_s6 #(
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED  ( DEV_CAP_MAX_PAYLOAD_SUPPORTED ),

    .VC0_TX_LASTPACKET              ( VC0_TX_LASTPACKET             ),
    .TLM_TX_OVERHEAD                ( 20                            ),
    .TL_TX_RAM_RADDR_LATENCY        ( TL_TX_RAM_RADDR_LATENCY       ),
    .TL_TX_RAM_RDATA_LATENCY        ( TL_TX_RAM_RDATA_LATENCY       ),
    // NOTE: use the RX value here since there is no separate TX value
    .TL_TX_RAM_WRITE_LATENCY        ( TL_RX_RAM_WRITE_LATENCY       ),

    .VC0_RX_LIMIT                   ( VC0_RX_RAM_LIMIT              ),
    .TL_RX_RAM_RADDR_LATENCY        ( TL_RX_RAM_RADDR_LATENCY       ),
    .TL_RX_RAM_RDATA_LATENCY        ( TL_RX_RAM_RDATA_LATENCY       ),
    .TL_RX_RAM_WRITE_LATENCY        ( TL_RX_RAM_WRITE_LATENCY       )
  ) pcie_bram_top (
    .user_clk_i                     ( trn_clk                       ),
    .reset_i                        ( !trn_reset_n                  ),

    .mim_tx_waddr                   ( mim_tx_waddr                  ),
    .mim_tx_wen                     ( mim_tx_wen                    ),
    .mim_tx_ren                     ( mim_tx_ren                    ),
    .mim_tx_rce                     ( 1'b1                          ),
    .mim_tx_wdata                   ( mim_tx_wdata                  ),
    .mim_tx_raddr                   ( mim_tx_raddr                  ),
    .mim_tx_rdata                   ( mim_tx_rdata                  ),

    .mim_rx_waddr                   ( mim_rx_waddr                  ),
    .mim_rx_wen                     ( mim_rx_wen                    ),
    .mim_rx_ren                     ( mim_rx_ren                    ),
    .mim_rx_rce                     ( 1'b1                          ),
    .mim_rx_wdata                   ( {1'b0, mim_rx_wdata}          ),
    .mim_rx_raddr                   ( mim_rx_raddr                  ),
    .mim_rx_rdata                   ( {mim_rx_rdata_unused, mim_rx_rdata}     )
  );

  //***************************************************************************
  // PCI Express GTA1_DUAL Wrapper Instance
  //***************************************************************************

  gtpa1_dual_wrapper_top #(
    .SIMULATION          (FAST_TRAIN == "TRUE" ? 1 : 0)
  ) mgt (
    .rx_char_is_k        ( rx_char_is_k      ),
    .rx_data             ( rx_data           ),
    .rx_enter_elecidle   ( rx_enter_elecidle ),
    .rx_status           ( rx_status         ),
    .rx_polarity         ( rx_polarity       ),
    .tx_char_disp_mode   ( tx_char_disp_mode ),
    .tx_char_is_k        ( tx_char_is_k      ),
    .tx_rcvr_det         ( tx_rcvr_det       ),
    .tx_data             ( tx_data           ),
    .phystatus           ( phystatus         ),
    .gt_usrclk           ( mgt_clk           ),
    .gt_usrclk2x         ( mgt_clk_2x        ),
    .sys_clk             ( sys_clk           ),
    .sys_rst_n           ( sys_reset_n       ),
    .arp_txp             ( pci_exp_txp       ),
    .arp_txn             ( pci_exp_txn       ),
    .arp_rxp             ( pci_exp_rxp       ),
    .arp_rxn             ( pci_exp_rxn       ),
    .gt_reset_done       ( gt_reset_done     ),
    .gt_rx_valid         ( gt_rx_valid       ),
    .gt_plllkdet_out     ( gt_plllkdet_out   ),
    .gt_refclk_out       ( gt_refclk_out     ),
    .gt_tx_elec_idle     ( gt_tx_elec_idle   ),
    .gt_power_down       ( gt_power_down     ),
    .rxreset             ( rxreset           )
  );

  // Generate the reset for the PLL

  assign pll_rst = !gt_plllkdet_out || !sys_reset_n;


  //***************************************************************************
  // Generate the connection between PCIE_A1 block and the GTPA1_DUAL.  When
  // the parameter GTP_SEL is 0, connect to PIPEA, when it is a 1, connect to
  // PIPEB.
  //***************************************************************************
  generate if (!GTP_SEL) begin : PIPE_A_SEL

    // Signals from GTPA1_DUAL to PCIE_A1
    assign   pipe_rx_charisk_a         = rx_char_is_k;
    assign   pipe_rx_data_a            = rx_data;
    assign   pipe_rx_enter_elec_idle_a = rx_enter_elecidle;
    assign   pipe_rx_status_a          = rx_status;
    assign   pipe_phy_status_a         = phystatus;
    assign   pipe_gt_reset_done_a      = gt_reset_done;

    // Unused PCIE_A1 inputs
    assign   pipe_rx_charisk_b         = 2'b0;
    assign   pipe_rx_data_b            = 16'h0;
    assign   pipe_rx_enter_elec_idle_b = 1'b0;
    assign   pipe_rx_status_b          = 3'b0;
    assign   pipe_phy_status_b         = 1'b0;
    assign   pipe_gt_reset_done_b      = 1'b0;

    //Signals from PCIE_A1 to GTPA1_DUAL
    assign   rx_polarity               = pipe_rx_polarity_a;
    assign   tx_char_disp_mode         = pipe_tx_char_disp_mode_a;
    assign   tx_char_is_k              = pipe_tx_char_is_k_a;
    assign   tx_rcvr_det               = pipe_tx_rcvr_det_a;
    assign   tx_data                   = pipe_tx_data_a;
    assign   gt_tx_elec_idle           = pipe_gt_tx_elec_idle_a;
    assign   gt_power_down             = pipe_gt_power_down_a;
    assign   rxreset                   = pipe_rxreset_a;

  end else begin : PIPE_B_SEL

    // Signals from GTPA1_DUAL to PCIE_A1
    assign   pipe_rx_charisk_b         = rx_char_is_k;
    assign   pipe_rx_data_b            = rx_data;
    assign   pipe_rx_enter_elec_idle_b = rx_enter_elecidle;
    assign   pipe_rx_status_b          = rx_status;
    assign   pipe_phy_status_b         = phystatus;
    assign   pipe_gt_reset_done_b      = gt_reset_done;

    // Unused PCIE_A1 inputs
    assign   pipe_rx_charisk_a         = 2'b0;
    assign   pipe_rx_data_a            = 16'h0;
    assign   pipe_rx_enter_elec_idle_a = 1'b0;
    assign   pipe_rx_status_a          = 3'b0;
    assign   pipe_phy_status_a         = 1'b0;
    assign   pipe_gt_reset_done_a      = 1'b0;

    //Signals from PCIE_A1 to GTPA1_DUAL
    assign   rx_polarity               = pipe_rx_polarity_b;
    assign   tx_char_disp_mode         = pipe_tx_char_disp_mode_b;
    assign   tx_char_is_k              = pipe_tx_char_is_k_b;
    assign   tx_rcvr_det               = pipe_tx_rcvr_det_b;
    assign   tx_data                   = pipe_tx_data_b;
    assign   gt_tx_elec_idle           = pipe_gt_tx_elec_idle_b;
    assign   gt_power_down             = pipe_gt_power_down_b;
    assign   rxreset                   = pipe_rxreset_b;

  end
  endgenerate

  //***************************************************************************
  // PCI Express Hard Block Instance (PCIE_A1)
  //***************************************************************************

  PCIE_A1 #(
    .BAR0                               ( BAR0                                    ),
    .BAR1                               ( BAR1                                    ),
    .BAR2                               ( BAR2                                    ),
    .BAR3                               ( BAR3                                    ),
    .BAR4                               ( BAR4                                    ),
    .BAR5                               ( BAR5                                    ),
    .CARDBUS_CIS_POINTER                ( CARDBUS_CIS_POINTER                     ),
    .CLASS_CODE                         ( CLASS_CODE                              ),
    .DEV_CAP_ENDPOINT_L0S_LATENCY       ( DEV_CAP_ENDPOINT_L0S_LATENCY            ),
    .DEV_CAP_ENDPOINT_L1_LATENCY        ( DEV_CAP_ENDPOINT_L1_LATENCY             ),
    .DEV_CAP_EXT_TAG_SUPPORTED          ( DEV_CAP_EXT_TAG_SUPPORTED               ),
    .DEV_CAP_MAX_PAYLOAD_SUPPORTED      ( DEV_CAP_MAX_PAYLOAD_SUPPORTED           ),
    .DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT  ( DEV_CAP_PHANTOM_FUNCTIONS_SUPPORT       ),
    .DEV_CAP_ROLE_BASED_ERROR           ( DEV_CAP_ROLE_BASED_ERROR                ),
    .DISABLE_BAR_FILTERING              ( DISABLE_BAR_FILTERING                   ),
    .DISABLE_ID_CHECK                   ( DISABLE_ID_CHECK                        ),
    .DISABLE_SCRAMBLING                 ( DISABLE_SCRAMBLING                      ),
    .ENABLE_RX_TD_ECRC_TRIM             ( ENABLE_RX_TD_ECRC_TRIM                  ),
    .EXPANSION_ROM                      ( EXPANSION_ROM                           ),
    .FAST_TRAIN                         ( FAST_TRAIN                              ),
    .GTP_SEL                            ( GTP_SEL                                 ),
    .LINK_CAP_ASPM_SUPPORT              ( LINK_CAP_ASPM_SUPPORT                   ),
    .LINK_CAP_L0S_EXIT_LATENCY          ( LINK_CAP_L0S_EXIT_LATENCY               ),
    .LINK_CAP_L1_EXIT_LATENCY           ( LINK_CAP_L1_EXIT_LATENCY                ),
    .LINK_STATUS_SLOT_CLOCK_CONFIG      ( LINK_STATUS_SLOT_CLOCK_CONFIG           ),
    .LL_ACK_TIMEOUT                     ( LL_ACK_TIMEOUT                          ),
    .LL_ACK_TIMEOUT_EN                  ( LL_ACK_TIMEOUT_EN                       ),
    .LL_REPLAY_TIMEOUT                  ( LL_REPLAY_TIMEOUT                       ),
    .LL_REPLAY_TIMEOUT_EN               ( LL_REPLAY_TIMEOUT_EN                    ),
    .MSI_CAP_MULTIMSG_EXTENSION         ( MSI_CAP_MULTIMSG_EXTENSION              ),
    .MSI_CAP_MULTIMSGCAP                ( MSI_CAP_MULTIMSGCAP                     ),
    .PCIE_CAP_CAPABILITY_VERSION        ( PCIE_CAP_CAPABILITY_VERSION             ),
    .PCIE_CAP_DEVICE_PORT_TYPE          ( PCIE_CAP_DEVICE_PORT_TYPE               ),
    .PCIE_CAP_INT_MSG_NUM               ( PCIE_CAP_INT_MSG_NUM                    ),
    .PCIE_CAP_SLOT_IMPLEMENTED          ( PCIE_CAP_SLOT_IMPLEMENTED               ),
    .PCIE_GENERIC                       ( PCIE_GENERIC                            ),
    .PLM_AUTO_CONFIG                    ( PLM_AUTO_CONFIG                         ),
    .PM_CAP_AUXCURRENT                  ( PM_CAP_AUXCURRENT                       ),
    .PM_CAP_DSI                         ( PM_CAP_DSI                              ),
    .PM_CAP_D1SUPPORT                   ( PM_CAP_D1SUPPORT                        ),
    .PM_CAP_D2SUPPORT                   ( PM_CAP_D2SUPPORT                        ),
    .PM_CAP_PME_CLOCK                   ( PM_CAP_PME_CLOCK                        ),
    .PM_CAP_PMESUPPORT                  ( PM_CAP_PMESUPPORT                       ),
    .PM_CAP_VERSION                     ( PM_CAP_VERSION                          ),
    .PM_DATA_SCALE0                     ( PM_DATA_SCALE0                          ),
    .PM_DATA_SCALE1                     ( PM_DATA_SCALE1                          ),
    .PM_DATA_SCALE2                     ( PM_DATA_SCALE2                          ),
    .PM_DATA_SCALE3                     ( PM_DATA_SCALE3                          ),
    .PM_DATA_SCALE4                     ( PM_DATA_SCALE4                          ),
    .PM_DATA_SCALE5                     ( PM_DATA_SCALE5                          ),
    .PM_DATA_SCALE6                     ( PM_DATA_SCALE6                          ),
    .PM_DATA_SCALE7                     ( PM_DATA_SCALE7                          ),
    .PM_DATA0                           ( PM_DATA0                                ),
    .PM_DATA1                           ( PM_DATA1                                ),
    .PM_DATA2                           ( PM_DATA2                                ),
    .PM_DATA3                           ( PM_DATA3                                ),
    .PM_DATA4                           ( PM_DATA4                                ),
    .PM_DATA5                           ( PM_DATA5                                ),
    .PM_DATA6                           ( PM_DATA6                                ),
    .PM_DATA7                           ( PM_DATA7                                ),
    .SLOT_CAP_ATT_BUTTON_PRESENT        ( SLOT_CAP_ATT_BUTTON_PRESENT             ),
    .SLOT_CAP_ATT_INDICATOR_PRESENT     ( SLOT_CAP_ATT_INDICATOR_PRESENT          ),
    .SLOT_CAP_POWER_INDICATOR_PRESENT   ( SLOT_CAP_POWER_INDICATOR_PRESENT        ),
    .TL_RX_RAM_RADDR_LATENCY            ( TL_RX_RAM_RADDR_LATENCY                 ),
    .TL_RX_RAM_RDATA_LATENCY            ( TL_RX_RAM_RDATA_LATENCY                 ),
    .TL_RX_RAM_WRITE_LATENCY            ( TL_RX_RAM_WRITE_LATENCY                 ),
    .TL_TFC_DISABLE                     ( TL_TFC_DISABLE                          ),
    .TL_TX_CHECKS_DISABLE               ( TL_TX_CHECKS_DISABLE                    ),
    .TL_TX_RAM_RADDR_LATENCY            ( TL_TX_RAM_RADDR_LATENCY                 ),
    .TL_TX_RAM_RDATA_LATENCY            ( TL_TX_RAM_RDATA_LATENCY                 ),
    .USR_CFG                            ( USR_CFG                                 ),
    .USR_EXT_CFG                        ( USR_EXT_CFG                             ),
    .VC0_CPL_INFINITE                   ( VC0_CPL_INFINITE                        ),
    .VC0_RX_RAM_LIMIT                   ( VC0_RX_RAM_LIMIT                        ),
    .VC0_TOTAL_CREDITS_CD               ( VC0_TOTAL_CREDITS_CD                    ),
    .VC0_TOTAL_CREDITS_CH               ( VC0_TOTAL_CREDITS_CH                    ),
    .VC0_TOTAL_CREDITS_NPH              ( VC0_TOTAL_CREDITS_NPH                   ),
    .VC0_TOTAL_CREDITS_PD               ( VC0_TOTAL_CREDITS_PD                    ),
    .VC0_TOTAL_CREDITS_PH               ( VC0_TOTAL_CREDITS_PH                    ),
    .VC0_TX_LASTPACKET                  ( VC0_TX_LASTPACKET                       )
  ) PCIE_A1 (
    .CFGBUSNUMBER                       ( cfg_bus_number                          ),
    .CFGCOMMANDBUSMASTERENABLE          ( cfg_command_bus_master_enable           ),
    .CFGCOMMANDINTERRUPTDISABLE         ( cfg_command_interrupt_disable           ),
    .CFGCOMMANDIOENABLE                 ( cfg_command_io_enable                   ),
    .CFGCOMMANDMEMENABLE                ( cfg_command_mem_enable                  ),
    .CFGCOMMANDSERREN                   ( cfg_command_serr_en                     ),
    .CFGDEVCONTROLAUXPOWEREN            ( cfg_dev_control_aux_power_en            ),
    .CFGDEVCONTROLCORRERRREPORTINGEN    ( cfg_dev_control_corr_err_reporting_en   ),
    .CFGDEVCONTROLENABLERO              ( cfg_dev_control_enable_ro               ),
    .CFGDEVCONTROLEXTTAGEN              ( cfg_dev_control_ext_tag_en              ),
    .CFGDEVCONTROLFATALERRREPORTINGEN   ( cfg_dev_control_fatal_err_reporting_en  ),
    .CFGDEVCONTROLMAXPAYLOAD            ( cfg_dev_control_max_payload             ),
    .CFGDEVCONTROLMAXREADREQ            ( cfg_dev_control_max_read_req            ),
    .CFGDEVCONTROLNONFATALREPORTINGEN   ( cfg_dev_control_non_fatal_reporting_en  ),
    .CFGDEVCONTROLNOSNOOPEN             ( cfg_dev_control_no_snoop_en             ),
    .CFGDEVCONTROLPHANTOMEN             ( cfg_dev_control_phantom_en              ),
    .CFGDEVCONTROLURERRREPORTINGEN      ( cfg_dev_control_ur_err_reporting_en     ),
    .CFGDEVICENUMBER                    ( cfg_device_number                       ),
    .CFGDEVID                           ( w_cfg_dev_id                            ),
    .CFGDEVSTATUSCORRERRDETECTED        ( cfg_dev_status_corr_err_detected        ),
    .CFGDEVSTATUSFATALERRDETECTED       ( cfg_dev_status_fatal_err_detected       ),
    .CFGDEVSTATUSNONFATALERRDETECTED    ( cfg_dev_status_nonfatal_err_detected    ),
    .CFGDEVSTATUSURDETECTED             ( cfg_dev_status_ur_detected              ),
    .CFGDO                              ( cfg_do                                  ),
    .CFGDSN                             ( cfg_dsn                                 ),
    .CFGDWADDR                          ( cfg_dwaddr                              ),
    .CFGERRCORN                         ( cfg_err_cor_n                           ),
    .CFGERRCPLABORTN                    ( cfg_err_cpl_abort_n                     ),
    .CFGERRCPLRDYN                      ( cfg_err_cpl_rdy_n                       ),
    .CFGERRCPLTIMEOUTN                  ( cfg_err_cpl_timeout_n                   ),
    .CFGERRECRCN                        ( cfg_err_ecrc_n                          ),
    .CFGERRLOCKEDN                      ( cfg_err_locked_n                        ),
    .CFGERRPOSTEDN                      ( cfg_err_posted_n                        ),
    .CFGERRTLPCPLHEADER                 ( cfg_err_tlp_cpl_header                  ),
    .CFGERRURN                          ( cfg_err_ur_n                            ),
    .CFGFUNCTIONNUMBER                  ( cfg_function_number                     ),
    .CFGINTERRUPTASSERTN                ( cfg_interrupt_assert_n                  ),
    .CFGINTERRUPTDI                     ( cfg_interrupt_di                        ),
    .CFGINTERRUPTDO                     ( cfg_interrupt_do                        ),
    .CFGINTERRUPTMMENABLE               ( cfg_interrupt_mmenable                  ),
    .CFGINTERRUPTMSIENABLE              ( cfg_interrupt_msienable                 ),
    .CFGINTERRUPTN                      ( cfg_interrupt_n                         ),
    .CFGINTERRUPTRDYN                   ( cfg_interrupt_rdy_n                     ),
    .CFGLINKCONTOLRCB                   ( cfg_link_control_rcb                    ),
    .CFGLINKCONTROLASPMCONTROL          ( cfg_link_control_aspm_control           ),
    .CFGLINKCONTROLCOMMONCLOCK          ( cfg_link_control_common_clock           ),
    .CFGLINKCONTROLEXTENDEDSYNC         ( cfg_link_control_extended_sync          ),
    .CFGLTSSMSTATE                      ( cfg_ltssm_state                         ),
    .CFGPCIELINKSTATEN                  ( cfg_pcie_link_state_n                   ),
    .CFGPMWAKEN                         ( cfg_pm_wake_n                           ),
    .CFGRDENN                           ( cfg_rd_en_n                             ),
    .CFGRDWRDONEN                       ( cfg_rd_wr_done_n                        ),
    .CFGREVID                           ( w_cfg_rev_id                            ),
    .CFGSUBSYSID                        ( w_cfg_subsys_id                         ),
    .CFGSUBSYSVENID                     ( w_cfg_subsys_ven_id                     ),
    .CFGTOTURNOFFN                      ( cfg_to_turnoff_n                        ),
    .CFGTRNPENDINGN                     ( cfg_trn_pending_n                       ),
    .CFGTURNOFFOKN                      ( cfg_turnoff_ok_n                        ),
    .CFGVENID                           ( w_cfg_ven_id                            ),
    .CLOCKLOCKED                        ( clock_locked                            ),
    .DBGBADDLLPSTATUS                   ( dbg_bad_dllp_status                     ),
    .DBGBADTLPLCRC                      ( dbg_bad_tlp_lcrc                        ),
    .DBGBADTLPSEQNUM                    ( dbg_bad_tlp_seq_num                     ),
    .DBGBADTLPSTATUS                    ( dbg_bad_tlp_status                      ),
    .DBGDLPROTOCOLSTATUS                ( dbg_dl_protocol_status                  ),
    .DBGFCPROTOCOLERRSTATUS             ( dbg_fc_protocol_err_status              ),
    .DBGMLFRMDLENGTH                    ( dbg_mlfrmd_length                       ),
    .DBGMLFRMDMPS                       ( dbg_mlfrmd_mps                          ),
    .DBGMLFRMDTCVC                      ( dbg_mlfrmd_tcvc                         ),
    .DBGMLFRMDTLPSTATUS                 ( dbg_mlfrmd_tlp_status                   ),
    .DBGMLFRMDUNRECTYPE                 ( dbg_mlfrmd_unrec_type                   ),
    .DBGPOISTLPSTATUS                   ( dbg_poistlpstatus                       ),
    .DBGRCVROVERFLOWSTATUS              ( dbg_rcvr_overflow_status                ),
    .DBGREGDETECTEDCORRECTABLE          ( dbg_reg_detected_correctable            ),
    .DBGREGDETECTEDFATAL                ( dbg_reg_detected_fatal                  ),
    .DBGREGDETECTEDNONFATAL             ( dbg_reg_detected_non_fatal              ),
    .DBGREGDETECTEDUNSUPPORTED          ( dbg_reg_detected_unsupported            ),
    .DBGRPLYROLLOVERSTATUS              ( dbg_rply_rollover_status                ),
    .DBGRPLYTIMEOUTSTATUS               ( dbg_rply_timeout_status                 ),
    .DBGURNOBARHIT                      ( dbg_ur_no_bar_hit                       ),
    .DBGURPOISCFGWR                     ( dbg_ur_pois_cfg_wr                      ),
    .DBGURSTATUS                        ( dbg_ur_status                           ),
    .DBGURUNSUPMSG                      ( dbg_ur_unsup_msg                        ),
    .MGTCLK                             ( mgt_clk                                 ),
    .MIMRXRADDR                         ( mim_rx_raddr                            ),
    .MIMRXRDATA                         ( mim_rx_rdata                            ),
    .MIMRXREN                           ( mim_rx_ren                              ),
    .MIMRXWADDR                         ( mim_rx_waddr                            ),
    .MIMRXWDATA                         ( mim_rx_wdata                            ),
    .MIMRXWEN                           ( mim_rx_wen                              ),
    .MIMTXRADDR                         ( mim_tx_raddr                            ),
    .MIMTXRDATA                         ( mim_tx_rdata                            ),
    .MIMTXREN                           ( mim_tx_ren                              ),
    .MIMTXWADDR                         ( mim_tx_waddr                            ),
    .MIMTXWDATA                         ( mim_tx_wdata                            ),
    .MIMTXWEN                           ( mim_tx_wen                              ),
    .PIPEGTPOWERDOWNA                   ( pipe_gt_power_down_a                    ),
    .PIPEGTPOWERDOWNB                   ( pipe_gt_power_down_b                    ),
    .PIPEGTRESETDONEA                   ( pipe_gt_reset_done_a                    ),
    .PIPEGTRESETDONEB                   ( pipe_gt_reset_done_b                    ),
    .PIPEGTTXELECIDLEA                  ( pipe_gt_tx_elec_idle_a                  ),
    .PIPEGTTXELECIDLEB                  ( pipe_gt_tx_elec_idle_b                  ),
    .PIPEPHYSTATUSA                     ( pipe_phy_status_a                       ),
    .PIPEPHYSTATUSB                     ( pipe_phy_status_b                       ),
    .PIPERXCHARISKA                     ( pipe_rx_charisk_a                       ),
    .PIPERXCHARISKB                     ( pipe_rx_charisk_b                       ),
    .PIPERXDATAA                        ( pipe_rx_data_a                          ),
    .PIPERXDATAB                        ( pipe_rx_data_b                          ),
    .PIPERXENTERELECIDLEA               ( pipe_rx_enter_elec_idle_a               ),
    .PIPERXENTERELECIDLEB               ( pipe_rx_enter_elec_idle_b               ),
    .PIPERXPOLARITYA                    ( pipe_rx_polarity_a                      ),
    .PIPERXPOLARITYB                    ( pipe_rx_polarity_b                      ),
    .PIPERXRESETA                       ( pipe_rxreset_a                          ),
    .PIPERXRESETB                       ( pipe_rxreset_b                          ),
    .PIPERXSTATUSA                      ( pipe_rx_status_a                        ),
    .PIPERXSTATUSB                      ( pipe_rx_status_b                        ),
    .PIPETXCHARDISPMODEA                ( pipe_tx_char_disp_mode_a                ),
    .PIPETXCHARDISPMODEB                ( pipe_tx_char_disp_mode_b                ),
    .PIPETXCHARDISPVALA                 ( pipe_tx_char_disp_val_a                 ),
    .PIPETXCHARDISPVALB                 ( pipe_tx_char_disp_val_b                 ),
    .PIPETXCHARISKA                     ( pipe_tx_char_is_k_a                     ),
    .PIPETXCHARISKB                     ( pipe_tx_char_is_k_b                     ),
    .PIPETXDATAA                        ( pipe_tx_data_a                          ),
    .PIPETXDATAB                        ( pipe_tx_data_b                          ),
    .PIPETXRCVRDETA                     ( pipe_tx_rcvr_det_a                      ),
    .PIPETXRCVRDETB                     ( pipe_tx_rcvr_det_b                      ),
    .RECEIVEDHOTRESET                   ( received_hot_reset                      ),
    .SYSRESETN                          ( sys_reset_n                             ),
    .TRNFCCPLD                          ( trn_fc_cpld                             ),
    .TRNFCCPLH                          ( trn_fc_cplh                             ),
    .TRNFCNPD                           ( trn_fc_npd                              ),
    .TRNFCNPH                           ( trn_fc_nph                              ),
    .TRNFCPD                            ( trn_fc_pd                               ),
    .TRNFCPH                            ( trn_fc_ph                               ),
    .TRNFCSEL                           ( trn_fc_sel                              ),
    .TRNLNKUPN                          ( trn_lnk_up_n                            ),
    .TRNRBARHITN                        ( trn_rbar_hit_n                          ),
    .TRNRD                              ( trn_rd                                  ),
    .TRNRDSTRDYN                        ( trn_rdst_rdy_n                          ),
    .TRNREOFN                           ( trn_reof_n                              ),
    .TRNRERRFWDN                        ( trn_rerrfwd_n                           ),
    .TRNRNPOKN                          ( trn_rnp_ok_n                            ),
    .TRNRSOFN                           ( trn_rsof_n                              ),
    .TRNRSRCDSCN                        ( trn_rsrc_dsc_n                          ),
    .TRNRSRCRDYN                        ( trn_rsrc_rdy_n                          ),
    .TRNTBUFAV                          ( trn_tbuf_av                             ),
    .TRNTCFGGNTN                        ( trn_tcfg_gnt_n                          ),
    .TRNTCFGREQN                        ( trn_tcfg_req_n                          ),
    .TRNTD                              ( trn_td                                  ),
    .TRNTDSTRDYN                        ( trn_tdst_rdy_n                          ),
    .TRNTEOFN                           ( trn_teof_n                              ),
    .TRNTERRDROPN                       ( trn_terr_drop_n                         ),
    .TRNTERRFWDN                        ( trn_terrfwd_n                           ),
    .TRNTSOFN                           ( trn_tsof_n                              ),
    .TRNTSRCDSCN                        ( trn_tsrc_dsc_n                          ),
    .TRNTSRCRDYN                        ( trn_tsrc_rdy_n                          ),
    .TRNTSTRN                           ( trn_tstr_n                              ),
    .USERCLK                            ( trn_clk                                 ),
    .USERRSTN                           ( trn_reset_n                             )
  );

  //***************************************************************************
  // Recreate wrapper outputs from the PCIE_A1 signals.
  //***************************************************************************
  assign      cfg_status  = {16'b0};

  assign      cfg_command = {5'b0,
                             cfg_command_interrupt_disable,
                             1'b0,
                             cfg_command_serr_en,
                             5'b0,
                             cfg_command_bus_master_enable,
                             cfg_command_mem_enable,
                             cfg_command_io_enable};

  assign      cfg_dstatus  = {10'h0,
                             !cfg_trn_pending_n,
                             1'b0,
                             cfg_dev_status_ur_detected,
                             cfg_dev_status_fatal_err_detected,
                             cfg_dev_status_nonfatal_err_detected,
                             cfg_dev_status_corr_err_detected};

  assign      cfg_dcommand = {1'b0,
                             cfg_dev_control_max_read_req,
                             cfg_dev_control_no_snoop_en,
                             cfg_dev_control_aux_power_en,
                             cfg_dev_control_phantom_en,
                             cfg_dev_control_ext_tag_en,
                             cfg_dev_control_max_payload,
                             cfg_dev_control_enable_ro,
                             cfg_dev_control_ur_err_reporting_en,
                             cfg_dev_control_fatal_err_reporting_en,
                             cfg_dev_control_non_fatal_reporting_en,
                             cfg_dev_control_corr_err_reporting_en};

  assign      cfg_lstatus   = 16'h0011;

  assign      cfg_lcommand  = {8'h0,
                              cfg_link_control_extended_sync,
                              cfg_link_control_common_clock,
                              2'b00,
                              cfg_link_control_rcb,
                              1'b0,
                              cfg_link_control_aspm_control};



endmodule
