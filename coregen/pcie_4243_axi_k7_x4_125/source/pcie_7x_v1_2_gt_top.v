//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
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
// Project    : Series-7 Integrated Block for PCI Express
// File       : pcie_7x_v1_2_gt_top.v
// Version    : 1.2
//-- Description: GTX module for 7-series Integrated PCIe Block
//--
//--
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module pcie_7x_v1_2_gt_top #
(
   parameter               LINK_CAP_MAX_LINK_WIDTH = 8, // 1 - x1 , 2 - x2 , 4 - x4 , 8 - x8
   parameter               REF_CLK_FREQ = 0,            // 0 - 100 MHz , 1 - 125 MHz , 2 - 250 MHz
   parameter               USER_CLK2_DIV2 = "FALSE",    // "FALSE" => user_clk2 = user_clk
                                                        // "TRUE" => user_clk2 = user_clk/2, where user_clk = 500 or 250 MHz. 
   parameter  integer      USER_CLK_FREQ = 3,           // 0 - 31.25 MHz , 1 - 62.5 MHz , 2 - 125 MHz , 3 - 250 MHz , 4 - 500Mhz
   parameter               PL_FAST_TRAIN = "FALSE",     // Simulation Speedup
   parameter               PCIE_EXT_CLK = "FALSE"       // Use External Clocking
)
(
   //-----------------------------------------------------------------------------------------------------------------//
   // Pipe Per-Link Signals
   input   wire                      pipe_tx_rcvr_det       ,
   input   wire                      pipe_tx_reset          ,
   input   wire                      pipe_tx_rate           ,
   input   wire                      pipe_tx_deemph         ,
   input   wire [2:0]                pipe_tx_margin         ,
   input   wire                      pipe_tx_swing          ,

   //-----------------------------------------------------------------------------------------------------------------//
   // Clock Inputs - For Partial Reconfig Support                                                                     //
   //-----------------------------------------------------------------------------------------------------------------//
   input                                      PIPE_PCLK_IN,
   input  [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PIPE_RXUSRCLK_IN,
   input                                      PIPE_RXOUTCLK_IN,
   input                                      PIPE_DCLK_IN,
   input                                      PIPE_USERCLK1_IN,
   input                                      PIPE_USERCLK2_IN,
   input                                      PIPE_MMCM_LOCK_IN,

   output                                     PIPE_TXOUTCLK_OUT,
   output [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PIPE_RXOUTCLK_OUT,
   output [(LINK_CAP_MAX_LINK_WIDTH - 1) : 0] PIPE_PCLK_SEL_OUT,
   output                                     PIPE_GEN3_OUT,

   // Pipe Per-Lane Signals - Lane 0
   output  wire [ 1:0]               pipe_rx0_char_is_k     ,
   output  wire [15:0]               pipe_rx0_data          ,
   output  wire                      pipe_rx0_valid         ,
   output  wire                      pipe_rx0_chanisaligned ,
   output  wire [ 2:0]               pipe_rx0_status        ,
   output  wire                      pipe_rx0_phy_status    ,
   output  wire                      pipe_rx0_elec_idle     ,
   input   wire                      pipe_rx0_polarity      ,
   input   wire                      pipe_tx0_compliance    ,
   input   wire [ 1:0]               pipe_tx0_char_is_k     ,
   input   wire [15:0]               pipe_tx0_data          ,
   input   wire                      pipe_tx0_elec_idle     ,
   input   wire [ 1:0]               pipe_tx0_powerdown     ,

   // Pipe Per-Lane Signals - Lane 1
   output  wire [ 1:0]               pipe_rx1_char_is_k     ,
   output  wire [15:0]               pipe_rx1_data          ,
   output  wire                      pipe_rx1_valid         ,
   output  wire                      pipe_rx1_chanisaligned ,
   output  wire [ 2:0]               pipe_rx1_status        ,
   output  wire                      pipe_rx1_phy_status    ,
   output  wire                      pipe_rx1_elec_idle     ,
   input   wire                      pipe_rx1_polarity      ,
   input   wire                      pipe_tx1_compliance    ,
   input   wire [ 1:0]               pipe_tx1_char_is_k     ,
   input   wire [15:0]               pipe_tx1_data          ,
   input   wire                      pipe_tx1_elec_idle     ,
   input   wire [ 1:0]               pipe_tx1_powerdown     ,

   // Pipe Per-Lane Signals - Lane 2
   output  wire [ 1:0]               pipe_rx2_char_is_k     ,
   output  wire [15:0]               pipe_rx2_data          ,
   output  wire                      pipe_rx2_valid         ,
   output  wire                      pipe_rx2_chanisaligned ,
   output  wire [ 2:0]               pipe_rx2_status        ,
   output  wire                      pipe_rx2_phy_status    ,
   output  wire                      pipe_rx2_elec_idle     ,
   input   wire                      pipe_rx2_polarity      ,
   input   wire                      pipe_tx2_compliance    ,
   input   wire [ 1:0]               pipe_tx2_char_is_k     ,
   input   wire [15:0]               pipe_tx2_data          ,
   input   wire                      pipe_tx2_elec_idle     ,
   input   wire [ 1:0]               pipe_tx2_powerdown     ,

   // Pipe Per-Lane Signals - Lane 3
   output  wire [ 1:0]               pipe_rx3_char_is_k     ,
   output  wire [15:0]               pipe_rx3_data          ,
   output  wire                      pipe_rx3_valid         ,
   output  wire                      pipe_rx3_chanisaligned ,
   output  wire [ 2:0]               pipe_rx3_status        ,
   output  wire                      pipe_rx3_phy_status    ,
   output  wire                      pipe_rx3_elec_idle     ,
   input   wire                      pipe_rx3_polarity      ,
   input   wire                      pipe_tx3_compliance    ,
   input   wire [ 1:0]               pipe_tx3_char_is_k     ,
   input   wire [15:0]               pipe_tx3_data          ,
   input   wire                      pipe_tx3_elec_idle     ,
   input   wire [ 1:0]               pipe_tx3_powerdown     ,

   // Pipe Per-Lane Signals - Lane 4
   output  wire [ 1:0]               pipe_rx4_char_is_k     ,
   output  wire [15:0]               pipe_rx4_data          ,
   output  wire                      pipe_rx4_valid         ,
   output  wire                      pipe_rx4_chanisaligned ,
   output  wire [ 2:0]               pipe_rx4_status        ,
   output  wire                      pipe_rx4_phy_status    ,
   output  wire                      pipe_rx4_elec_idle     ,
   input   wire                      pipe_rx4_polarity      ,
   input   wire                      pipe_tx4_compliance    ,
   input   wire [ 1:0]               pipe_tx4_char_is_k     ,
   input   wire [15:0]               pipe_tx4_data          ,
   input   wire                      pipe_tx4_elec_idle     ,
   input   wire [ 1:0]               pipe_tx4_powerdown     ,

   // Pipe Per-Lane Signals - Lane 5
   output  wire [ 1:0]               pipe_rx5_char_is_k     ,
   output  wire [15:0]               pipe_rx5_data          ,
   output  wire                      pipe_rx5_valid         ,
   output  wire                      pipe_rx5_chanisaligned ,
   output  wire [ 2:0]               pipe_rx5_status        ,
   output  wire                      pipe_rx5_phy_status    ,
   output  wire                      pipe_rx5_elec_idle     ,
   input   wire                      pipe_rx5_polarity      ,
   input   wire                      pipe_tx5_compliance    ,
   input   wire [ 1:0]               pipe_tx5_char_is_k     ,
   input   wire [15:0]               pipe_tx5_data          ,
   input   wire                      pipe_tx5_elec_idle     ,
   input   wire [ 1:0]               pipe_tx5_powerdown     ,

   // Pipe Per-Lane Signals - Lane 6
   output  wire [ 1:0]               pipe_rx6_char_is_k     ,
   output  wire [15:0]               pipe_rx6_data          ,
   output  wire                      pipe_rx6_valid         ,
   output  wire                      pipe_rx6_chanisaligned ,
   output  wire [ 2:0]               pipe_rx6_status        ,
   output  wire                      pipe_rx6_phy_status    ,
   output  wire                      pipe_rx6_elec_idle     ,
   input   wire                      pipe_rx6_polarity      ,
   input   wire                      pipe_tx6_compliance    ,
   input   wire [ 1:0]               pipe_tx6_char_is_k     ,
   input   wire [15:0]               pipe_tx6_data          ,
   input   wire                      pipe_tx6_elec_idle     ,
   input   wire [ 1:0]               pipe_tx6_powerdown     ,

   // Pipe Per-Lane Signals - Lane 7
   output  wire [ 1:0]               pipe_rx7_char_is_k     ,
   output  wire [15:0]               pipe_rx7_data          ,
   output  wire                      pipe_rx7_valid         ,
   output  wire                      pipe_rx7_chanisaligned ,
   output  wire [ 2:0]               pipe_rx7_status        ,
   output  wire                      pipe_rx7_phy_status    ,
   output  wire                      pipe_rx7_elec_idle     ,
   input   wire                      pipe_rx7_polarity      ,
   input   wire                      pipe_tx7_compliance    ,
   input   wire [ 1:0]               pipe_tx7_char_is_k     ,
   input   wire [15:0]               pipe_tx7_data          ,
   input   wire                      pipe_tx7_elec_idle     ,
   input   wire [ 1:0]               pipe_tx7_powerdown     ,

   // PCI Express signals
   output  wire [ (LINK_CAP_MAX_LINK_WIDTH-1):0] pci_exp_txn            ,
   output  wire [ (LINK_CAP_MAX_LINK_WIDTH-1):0] pci_exp_txp            ,
   input   wire [ (LINK_CAP_MAX_LINK_WIDTH-1):0] pci_exp_rxn            ,
   input   wire [ (LINK_CAP_MAX_LINK_WIDTH-1):0] pci_exp_rxp            ,

   // Non PIPE signals
   input   wire                      sys_clk                ,
   input   wire                      sys_rst_n              ,

   output  wire                      pipe_clk               ,
   output  wire                      user_clk               ,
   output  wire                      user_clk2              ,

   output  wire                      phy_rdy_n
);

  parameter                          TCQ  = 1;      // clock to out delay model

  localparam                         USERCLK2_FREQ = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : 
                                                                                     (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ
                                                                                : USER_CLK_FREQ;


  wire [  7:0]                       gt_rx_phy_status_wire    ;
  wire [  7:0]                       gt_rxchanisaligned_wire  ;
  wire [ 31:0]                       gt_rx_data_k_wire        ;
  wire [255:0]                       gt_rx_data_wire          ;
  wire [  7:0]                       gt_rx_elec_idle_wire     ;
  wire [ 23:0]                       gt_rx_status_wire        ;
  wire [  7:0]                       gt_rx_valid_wire         ;
  wire [  7:0]                       gt_rx_polarity           ;
  wire [ 15:0]                       gt_power_down            ;
  wire [  7:0]                       gt_tx_char_disp_mode     ;
  wire [ 31:0]                       gt_tx_data_k             ;
  wire [255:0]                       gt_tx_data               ;
  wire                               gt_tx_detect_rx_loopback ;
  wire [  7:0]                       gt_tx_elec_idle          ;
  wire [  7:0]                       gt_rx_elec_idle_reset    ;
  wire [LINK_CAP_MAX_LINK_WIDTH-1:0]             plllkdet;
  wire [LINK_CAP_MAX_LINK_WIDTH-1:0]             phystatus_rst;
  wire                               clock_locked;


//---------- GTX ---------------------------------------------------------------
pcie_7x_v1_2_pipe_wrapper #
(

    .PCIE_SIM_MODE                  ( PL_FAST_TRAIN ),
    .PCIE_EXT_CLK                   ( PCIE_EXT_CLK ),
    .PCIE_TXBUF_EN                  ( "FALSE" ),
    .PCIE_CHAN_BOND                 ( 1 ),
    .PCIE_USE_MODE                  ( "1.0" ),
  `ifdef SIMULATION
    .PCIE_LPM_DFE                   ( "DFE" ),
  `else
    .PCIE_LPM_DFE                   ( "LPM" ),
  `endif
    .PCIE_LANE                      ( LINK_CAP_MAX_LINK_WIDTH ),
  `ifdef SIMULATION
    .PCIE_LINK_SPEED                ( 2 ),
  `else
    .PCIE_LINK_SPEED                ( 3 ),
  `endif
    .PCIE_REFCLK_FREQ               ( REF_CLK_FREQ ),
    .PCIE_USERCLK1_FREQ             ( USER_CLK_FREQ +1 ),
    .PCIE_USERCLK2_FREQ             ( USERCLK2_FREQ +1 )

)
pipe_wrapper_i
(

    //---------- PIPE Clock & Reset Ports ------------------
    .PIPE_CLK                        (sys_clk),
    .PIPE_RESET_N                    (sys_rst_n),
    .PIPE_PCLK                       (pipe_clk),

    //---------- PIPE TX Data Ports ------------------
    .PIPE_TXP                       (pci_exp_txp[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_TXN                       (pci_exp_txn[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),

    .PIPE_TXDATA                    (gt_tx_data[((32*LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_TXDATAK                   (gt_tx_data_k[((4*LINK_CAP_MAX_LINK_WIDTH)-1):0]),

    //---------- PIPE RX Data Ports ------------------
    .PIPE_RXP                       (pci_exp_rxp[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_RXN                       (pci_exp_rxn[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),

    .PIPE_RXDATA                    (gt_rx_data_wire[((32*LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_RXDATAK                   (gt_rx_data_k_wire[((4*LINK_CAP_MAX_LINK_WIDTH)-1):0]),

    //---------- PIPE Command Ports ------------------
    .PIPE_TXDETECTRX                (gt_tx_detect_rx_loopback),
    .PIPE_TXELECIDLE                (gt_tx_elec_idle[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_TXCOMPLIANCE              (gt_tx_char_disp_mode[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_RXPOLARITY                (gt_rx_polarity[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_POWERDOWN                 (gt_power_down[((2*LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_RATE                      ({1'b0,pipe_tx_rate}),

    //---------- PIPE Electrical Command Ports ------------------
    .PIPE_TXMARGIN                  (pipe_tx_margin[2]),
    .PIPE_TXSWING                   (pipe_tx_swing),
    .PIPE_TXDEEMPH                  (pipe_tx_deemph),
    .PIPE_TXEQ_CONTROL              ({2*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),
    .PIPE_TXEQ_PRESET               ({4*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),

    .PIPE_RXEQ_CONTROL              ({2*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),
    .PIPE_RXEQ_PRESET               ({4*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),
    .PIPE_RXEQ_LFFS                 ({6*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),
    .PIPE_RXEQ_TXPRESET             ({4*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),

    .PIPE_TXEQ_FS                   (),
    .PIPE_TXEQ_LF                   (),
    .PIPE_TXEQ_DEEMPH               (),
    .PIPE_TXEQ_DONE                 (),

    .PIPE_RXEQ_LFFS_SEL             (),
    .PIPE_RXEQ_NEW_TXCOEFF          (),
    .PIPE_RXEQ_DONE                 (),
    .PIPE_RXEQ_ADAPT_DONE           (),

    //---------- PIPE Status Ports -------------------
    .PIPE_RXVALID                   (gt_rx_valid_wire[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_PHYSTATUS                 (gt_rx_phy_status_wire[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_PHYSTATUS_RST             (phystatus_rst),
    .PIPE_RXELECIDLE                (gt_rx_elec_idle_wire[((LINK_CAP_MAX_LINK_WIDTH)-1):0]),
    .PIPE_RXSTATUS                  (gt_rx_status_wire[((3*LINK_CAP_MAX_LINK_WIDTH)-1):0]),

    //---------- PIPE User Ports ---------------------------
    .PIPE_RXSLIDE                   ({1*LINK_CAP_MAX_LINK_WIDTH{1'b0}}),
    .PIPE_CPLL_LOCK                 (plllkdet),
    .PIPE_QPLL_LOCK                 (),
    .PIPE_PCLK_LOCK                 (clock_locked),
    .PIPE_RXCDRLOCK                 (),
    .PIPE_USERCLK1                  (user_clk),
    .PIPE_USERCLK2                  (user_clk2),
    .PIPE_TXSYNC_DONE               (),
    .PIPE_RXSYNC_DONE               (),
    .PIPE_RXCHANISALIGNED           (gt_rxchanisaligned_wire),
    .PIPE_ACTIVE_LANE               (),

    //---------- PIPE Debug Ports ---------------------------
    .PIPE_TXPRBSSEL                 (3'b0),
    .PIPE_LOOPBACK                  (3'b0),

    .PIPE_RST_FSM                   (),
    .PIPE_QRST_FSM                  (),
    .PIPE_RATE_FSM                  (),
    .PIPE_SYNC_FSM_TX               (),
    .PIPE_SYNC_FSM_RX               (),
    .PIPE_DRP_FSM                   (),
    .PIPE_TXEQ_FSM                  (),
    .PIPE_RXEQ_FSM                  (),
    .PIPE_QDRP_FSM                  (),

    .PIPE_PCLK_IN                   ( PIPE_PCLK_IN ),
    .PIPE_RXUSRCLK_IN               ( PIPE_RXUSRCLK_IN ),
    .PIPE_RXOUTCLK_IN               ( PIPE_RXOUTCLK_IN ),
    .PIPE_DCLK_IN                   ( PIPE_DCLK_IN ),
    .PIPE_USERCLK1_IN               ( PIPE_USERCLK1_IN ),
    .PIPE_USERCLK2_IN               ( PIPE_USERCLK2_IN ),
    .PIPE_MMCM_LOCK_IN              ( PIPE_MMCM_LOCK_IN ),

    .PIPE_TXOUTCLK_OUT              ( PIPE_TXOUTCLK_OUT ),
    .PIPE_RXOUTCLK_OUT              ( PIPE_RXOUTCLK_OUT ),
    .PIPE_PCLK_SEL_OUT              ( PIPE_PCLK_SEL_OUT ),
    .PIPE_GEN3_OUT                  ( PIPE_GEN3_OUT )


);

assign pipe_rx0_phy_status = gt_rx_phy_status_wire[0] ;
assign pipe_rx1_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? gt_rx_phy_status_wire[1] : 1'b0;
assign pipe_rx2_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_phy_status_wire[2] : 1'b0;
assign pipe_rx3_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_phy_status_wire[3] : 1'b0;
assign pipe_rx4_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_phy_status_wire[4] : 1'b0;
assign pipe_rx5_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_phy_status_wire[5] : 1'b0;
assign pipe_rx6_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_phy_status_wire[6] : 1'b0;
assign pipe_rx7_phy_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_phy_status_wire[7] : 1'b0;

assign pipe_rx0_chanisaligned = gt_rxchanisaligned_wire[0];
assign pipe_rx1_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? gt_rxchanisaligned_wire[1] : 1'b0 ;
assign pipe_rx2_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rxchanisaligned_wire[2] : 1'b0 ;
assign pipe_rx3_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rxchanisaligned_wire[3] : 1'b0 ;
assign pipe_rx4_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rxchanisaligned_wire[4] : 1'b0 ;
assign pipe_rx5_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rxchanisaligned_wire[5] : 1'b0 ;
assign pipe_rx6_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rxchanisaligned_wire[6] : 1'b0 ;
assign pipe_rx7_chanisaligned = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rxchanisaligned_wire[7] : 1'b0 ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

assign pipe_rx0_char_is_k =  {gt_rx_data_k_wire[1], gt_rx_data_k_wire[0]};
assign pipe_rx1_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? {gt_rx_data_k_wire[5], gt_rx_data_k_wire[4]} : 2'b0 ;
assign pipe_rx2_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? {gt_rx_data_k_wire[9], gt_rx_data_k_wire[8]} : 2'b0 ;
assign pipe_rx3_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? {gt_rx_data_k_wire[13], gt_rx_data_k_wire[12]} : 2'b0 ;
assign pipe_rx4_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_k_wire[17], gt_rx_data_k_wire[16]} : 2'b0 ;
assign pipe_rx5_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_k_wire[21], gt_rx_data_k_wire[20]} : 2'b0 ;
assign pipe_rx6_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_k_wire[25], gt_rx_data_k_wire[24]} : 2'b0 ;
assign pipe_rx7_char_is_k =  (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_k_wire[29], gt_rx_data_k_wire[28]} : 2'b0 ;

assign pipe_rx0_data = {gt_rx_data_wire[ 15: 8], gt_rx_data_wire[ 7: 0]};
assign pipe_rx1_data = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? {gt_rx_data_wire[47:40], gt_rx_data_wire[39:32]} : 16'h0 ;
assign pipe_rx2_data = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? {gt_rx_data_wire[79:72], gt_rx_data_wire[71:64]} : 16'h0 ;
assign pipe_rx3_data = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? {gt_rx_data_wire[111:104], gt_rx_data_wire[103:96]} : 16'h0 ;
assign pipe_rx4_data = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_wire[143:136], gt_rx_data_wire[135:128]} : 16'h0 ;
assign pipe_rx5_data = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_wire[175:168], gt_rx_data_wire[167:160]} : 16'h0 ;
assign pipe_rx6_data = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_wire[207:200], gt_rx_data_wire[199:192]} : 16'h0 ;
assign pipe_rx7_data = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? {gt_rx_data_wire[239:232], gt_rx_data_wire[231:224]} : 16'h0 ;


assign pipe_rx0_status = gt_rx_status_wire[ 2: 0];
assign pipe_rx1_status = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? gt_rx_status_wire[ 5: 3] : 3'b0 ;
assign pipe_rx2_status = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_status_wire[ 8: 6] : 3'b0 ;
assign pipe_rx3_status = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_status_wire[11: 9] : 3'b0 ;
assign pipe_rx4_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_status_wire[14:12] : 3'b0 ;
assign pipe_rx5_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_status_wire[17:15] : 3'b0 ;
assign pipe_rx6_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_status_wire[20:18] : 3'b0 ;
assign pipe_rx7_status = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_status_wire[23:21] : 3'b0 ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

assign pipe_rx0_elec_idle = gt_rx_elec_idle_wire[0];
assign pipe_rx1_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? gt_rx_elec_idle_wire[1] : 1'b1 ;
assign pipe_rx2_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_elec_idle_wire[2] : 1'b1 ;
assign pipe_rx3_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_elec_idle_wire[3] : 1'b1 ;
assign pipe_rx4_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_elec_idle_wire[4] : 1'b1 ;
assign pipe_rx5_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_elec_idle_wire[5] : 1'b1 ;
assign pipe_rx6_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_elec_idle_wire[6] : 1'b1 ;
assign pipe_rx7_elec_idle = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_elec_idle_wire[7] : 1'b1 ;



assign pipe_rx0_valid = gt_rx_valid_wire[0];
assign pipe_rx1_valid = (LINK_CAP_MAX_LINK_WIDTH >= 2 ) ? gt_rx_valid_wire[1] : 1'b0 ;
assign pipe_rx2_valid = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_valid_wire[2] : 1'b0 ;
assign pipe_rx3_valid = (LINK_CAP_MAX_LINK_WIDTH >= 4 ) ? gt_rx_valid_wire[3] : 1'b0 ;
assign pipe_rx4_valid = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_valid_wire[4] : 1'b0 ;
assign pipe_rx5_valid = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_valid_wire[5] : 1'b0 ;
assign pipe_rx6_valid = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_valid_wire[6] : 1'b0 ;
assign pipe_rx7_valid = (LINK_CAP_MAX_LINK_WIDTH >= 8 ) ? gt_rx_valid_wire[7] : 1'b0 ;

assign gt_rx_polarity[0] = pipe_rx0_polarity;
assign gt_rx_polarity[1] = pipe_rx1_polarity;
assign gt_rx_polarity[2] = pipe_rx2_polarity;
assign gt_rx_polarity[3] = pipe_rx3_polarity;
assign gt_rx_polarity[4] = pipe_rx4_polarity;
assign gt_rx_polarity[5] = pipe_rx5_polarity;
assign gt_rx_polarity[6] = pipe_rx6_polarity;
assign gt_rx_polarity[7] = pipe_rx7_polarity;

assign gt_power_down[ 1: 0] = pipe_tx0_powerdown;
assign gt_power_down[ 3: 2] = pipe_tx1_powerdown;
assign gt_power_down[ 5: 4] = pipe_tx2_powerdown;
assign gt_power_down[ 7: 6] = pipe_tx3_powerdown;
assign gt_power_down[ 9: 8] = pipe_tx4_powerdown;
assign gt_power_down[11:10] = pipe_tx5_powerdown;
assign gt_power_down[13:12] = pipe_tx6_powerdown;
assign gt_power_down[15:14] = pipe_tx7_powerdown;

assign gt_tx_char_disp_mode = {pipe_tx7_compliance,
                               pipe_tx6_compliance,
                               pipe_tx5_compliance,
                               pipe_tx4_compliance,
                               pipe_tx3_compliance,
                               pipe_tx2_compliance,
                               pipe_tx1_compliance,
                               pipe_tx0_compliance};


assign gt_tx_data_k = {2'd0,
                       pipe_tx7_char_is_k,
                       2'd0,
                       pipe_tx6_char_is_k,
                       2'd0,
                       pipe_tx5_char_is_k,
                       2'd0,
                       pipe_tx4_char_is_k,
                       2'd0,
                       pipe_tx3_char_is_k,
                       2'd0,
                       pipe_tx2_char_is_k,
                       2'd0,
                       pipe_tx1_char_is_k,
                       2'd0,
                       pipe_tx0_char_is_k};

assign gt_tx_data = {16'd0,
                     pipe_tx7_data,
                     16'd0,
                     pipe_tx6_data,
                     16'd0,
                     pipe_tx5_data,
                     16'd0,
                     pipe_tx4_data,
                     16'd0,
                     pipe_tx3_data,
                     16'd0,
                     pipe_tx2_data,
                     16'd0,
                     pipe_tx1_data,
                     16'd0,
                     pipe_tx0_data};

assign gt_tx_detect_rx_loopback = pipe_tx_rcvr_det;

assign gt_tx_elec_idle = {pipe_tx7_elec_idle,
                          pipe_tx6_elec_idle,
                          pipe_tx5_elec_idle,
                          pipe_tx4_elec_idle,
                          pipe_tx3_elec_idle,
                          pipe_tx2_elec_idle,
                          pipe_tx1_elec_idle,
                          pipe_tx0_elec_idle};

assign phy_rdy_n = (&phystatus_rst[LINK_CAP_MAX_LINK_WIDTH-1:0] & clock_locked);




endmodule
