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
// Project    : Series-7 Integrated Block for PCI Express
// File       : pcie_gtx_7x.v
// Version    : 1.1
//-- Description: GTX module for 7-series Integrated PCIe Block
//--
//--
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module pcie_gtx_v7 #
(
   parameter                         NO_OF_LANES = 8,          // 1 - x1 , 2 - x2 , 4 - x4 , 8 - x8
   parameter                         REF_CLK_FREQ = 0,         // 0 - 100 MHz , 1 - 125 MHz , 2 - 250 MHz
   parameter                         USER_CLK2_DIV2 = "FALSE", // "TRUE" => user_clk2 = user_clk/2, where user_clk = 500 or 250 MHz. "FALSE" => user_clk2 = user_clk
   parameter  integer                USER_CLK_FREQ = 3,        // 0 - 31.25 MHz , 1 - 62.5 MHz , 2 - 125 MHz , 3 - 250 MHz , 4 - 500Mhz 
   parameter                         PL_FAST_TRAIN = "FALSE"
)
(
   // Pipe Per-Link Signals	
   input   wire                      pipe_tx_rcvr_det       ,
   input   wire                      pipe_tx_reset          ,  
   input   wire                      pipe_tx_rate           ,  
   input   wire                      pipe_tx_deemph         ,  
   input   wire [2:0]                pipe_tx_margin         ,  
   input   wire                      pipe_tx_swing          ,  
   
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
   output  wire [ (NO_OF_LANES-1):0] pci_exp_txn            ,
   output  wire [ (NO_OF_LANES-1):0] pci_exp_txp            ,
   input   wire [ (NO_OF_LANES-1):0] pci_exp_rxn            ,
   input   wire [ (NO_OF_LANES-1):0] pci_exp_rxp            ,

   // Non PIPE signals
   input   wire                      sys_clk                , 
   input   wire                      sys_rst_n              ,	

   output  wire                      pipe_clk               , 
   output  wire                      user_clk               , 
   output  wire                      user_clk2              , 

   output  wire                      phy_rdy_n 
);

  parameter                          TCQ  = 1;      // clock to out delay model

  localparam                         USERCLK2_FREQ = (USER_CLK2_DIV2 == "TRUE") ? (USER_CLK_FREQ == 4) ? 3 : (USER_CLK_FREQ == 3) ? 2 : USER_CLK_FREQ 
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
  wire [NO_OF_LANES-1:0]             plllkdet;
  wire [NO_OF_LANES-1:0]             phystatus_rst;
  wire                               clock_locked;
   

//---------- GTX ---------------------------------------------------------------
pipe_wrapper #
(

    .PCIE_SIM_MODE                  (PL_FAST_TRAIN),                   
    .PCIE_TXBUF_EN                  ("TRUE"),
    .PCIE_CHAN_BOND                 (0),
    .PCIE_LANE                      (NO_OF_LANES),                    
    .PCIE_LINK_SPEED                (2), 
    .PCIE_REFCLK_FREQ               (REF_CLK_FREQ),  
    .PCIE_USERCLK1_FREQ             (USER_CLK_FREQ), 
    .PCIE_USERCLK2_FREQ             (USERCLK2_FREQ)

)
pipe_wrapper_i
(

    //---------- PIPE Clock & Reset Ports ------------------
    .PIPE_CLK                        (sys_clk),//v4.0
   // .REF_CLK                             (sys_clk),
    .PIPE_RESET_N                        (sys_rst_n),

    //---------- Serial Ports ------------------
    .PIPE_TXP                       (pci_exp_txp[((NO_OF_LANES)-1):0]),
    .PIPE_TXN                       (pci_exp_txn[((NO_OF_LANES)-1):0]),
    .PIPE_RXP                       (pci_exp_rxp[((NO_OF_LANES)-1):0]),
    .PIPE_RXN                       (pci_exp_rxn[((NO_OF_LANES)-1):0]),

    //---------- PIPE Transmit Data Ports ------------------
    .PIPE_TXDATA                    (gt_tx_data[((32*NO_OF_LANES)-1):0]),
    .PIPE_TXDATAK                   (gt_tx_data_k[((4*NO_OF_LANES)-1):0]),
    .PIPE_TXELECIDLE                (gt_tx_elec_idle[((NO_OF_LANES)-1):0]),
    .PIPE_TXCOMPLIANCE              (gt_tx_char_disp_mode[((NO_OF_LANES)-1):0]),                  
    .PIPE_TXDEEMPH                  (pipe_tx_deemph),
    .PIPE_TXEQCONTROL               (2'd0),                  
    .PIPE_TXMARGIN                  (pipe_tx_margin[2]),
    .PIPE_TXSWING                   (pipe_tx_swing),   

    //---------- PIPE Receive Data Ports -------------------
    
    .PIPE_RXDATA                    (gt_rx_data_wire[((32*NO_OF_LANES)-1):0]),
    .PIPE_RXDATAK                   (gt_rx_data_k_wire[((4*NO_OF_LANES)-1):0]),
    .PIPE_RXPOLARITY                (gt_rx_polarity[((NO_OF_LANES)-1):0]),
    .PIPE_RXVALID                   (gt_rx_valid_wire[((NO_OF_LANES)-1):0]),
    .PIPE_PHYSTATUS                 (gt_rx_phy_status_wire[((NO_OF_LANES)-1):0]),
    .PIPE_PHYSTATUS_RST             (phystatus_rst),

    //.PIPE_RXDEEMPH                  (17'b0),                     
    //.PIPE_RXEQCONTROL               (2'b0),                   
    .PIPE_RXELECIDLE                (gt_rx_elec_idle_wire[((NO_OF_LANES)-1):0]),
    .PIPE_RXSTATUS                  (gt_rx_status_wire[((3*NO_OF_LANES)-1):0]),

    .PIPE_POWERDOWN                 (gt_power_down[((2*NO_OF_LANES)-1):0]),
    .PIPE_RATE                      ({1'b0,pipe_tx_rate}),
    .PIPE_TXDETECTRX                (gt_tx_detect_rx_loopback),
    
    //---------- PIPE User Ports ---------------------------
    .PIPE_CPLL_LOCK                 (plllkdet),
    .PIPE_QPLL_LOCK                 (),
    .PIPE_PCLK_LOCK                 (clock_locked),
    .PIPE_RXCHANISALIGNED           (gt_rxchanisaligned_wire),
    
    .PIPE_PCLK                      (pipe_clk),
    .PIPE_USERCLK1                  (user_clk),
    .PIPE_USERCLK2                  (user_clk2),
    //.PIPE_RXOUTCLK                  (),
    .PIPE_ACTIVE_LANE               (),
    .PIPE_RST_FSM                   (),
    .PIPE_RATE_FSM                  ()
    
    
);

// KSP - Missing from the wrapper
//.ChanIsAligned(gt_rxchanisaligned_wire[((NO_OF_LANES)-1):0]),
//assign gt_rxchanisaligned_wire = 8'hff;

assign pipe_rx0_phy_status = gt_rx_phy_status_wire[0] ;
assign pipe_rx1_phy_status = (NO_OF_LANES >= 2 ) ? gt_rx_phy_status_wire[1] : 1'b0;
assign pipe_rx2_phy_status = (NO_OF_LANES >= 4 ) ? gt_rx_phy_status_wire[2] : 1'b0;
assign pipe_rx3_phy_status = (NO_OF_LANES >= 4 ) ? gt_rx_phy_status_wire[3] : 1'b0;
assign pipe_rx4_phy_status = (NO_OF_LANES >= 8 ) ? gt_rx_phy_status_wire[4] : 1'b0;
assign pipe_rx5_phy_status = (NO_OF_LANES >= 8 ) ? gt_rx_phy_status_wire[5] : 1'b0;
assign pipe_rx6_phy_status = (NO_OF_LANES >= 8 ) ? gt_rx_phy_status_wire[6] : 1'b0;
assign pipe_rx7_phy_status = (NO_OF_LANES >= 8 ) ? gt_rx_phy_status_wire[7] : 1'b0;

assign pipe_rx0_chanisaligned = gt_rxchanisaligned_wire[0];
assign pipe_rx1_chanisaligned = (NO_OF_LANES >= 2 ) ? gt_rxchanisaligned_wire[1] : 1'b0 ;
assign pipe_rx2_chanisaligned = (NO_OF_LANES >= 4 ) ? gt_rxchanisaligned_wire[2] : 1'b0 ;
assign pipe_rx3_chanisaligned = (NO_OF_LANES >= 4 ) ? gt_rxchanisaligned_wire[3] : 1'b0 ;
assign pipe_rx4_chanisaligned = (NO_OF_LANES >= 8 ) ? gt_rxchanisaligned_wire[4] : 1'b0 ;
assign pipe_rx5_chanisaligned = (NO_OF_LANES >= 8 ) ? gt_rxchanisaligned_wire[5] : 1'b0 ;
assign pipe_rx6_chanisaligned = (NO_OF_LANES >= 8 ) ? gt_rxchanisaligned_wire[6] : 1'b0 ;
assign pipe_rx7_chanisaligned = (NO_OF_LANES >= 8 ) ? gt_rxchanisaligned_wire[7] : 1'b0 ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

assign pipe_rx0_char_is_k =  {gt_rx_data_k_wire[1], gt_rx_data_k_wire[0]};
assign pipe_rx1_char_is_k =  (NO_OF_LANES >= 2 ) ? {gt_rx_data_k_wire[5], gt_rx_data_k_wire[4]} : 2'b0 ;
assign pipe_rx2_char_is_k =  (NO_OF_LANES >= 4 ) ? {gt_rx_data_k_wire[9], gt_rx_data_k_wire[8]} : 2'b0 ;
assign pipe_rx3_char_is_k =  (NO_OF_LANES >= 4 ) ? {gt_rx_data_k_wire[13], gt_rx_data_k_wire[12]} : 2'b0 ;
assign pipe_rx4_char_is_k =  (NO_OF_LANES >= 8 ) ? {gt_rx_data_k_wire[17], gt_rx_data_k_wire[16]} : 2'b0 ;
assign pipe_rx5_char_is_k =  (NO_OF_LANES >= 8 ) ? {gt_rx_data_k_wire[21], gt_rx_data_k_wire[20]} : 2'b0 ;
assign pipe_rx6_char_is_k =  (NO_OF_LANES >= 8 ) ? {gt_rx_data_k_wire[25], gt_rx_data_k_wire[24]} : 2'b0 ;
assign pipe_rx7_char_is_k =  (NO_OF_LANES >= 8 ) ? {gt_rx_data_k_wire[29], gt_rx_data_k_wire[28]} : 2'b0 ;

assign pipe_rx0_data = {gt_rx_data_wire[ 15: 8], gt_rx_data_wire[ 7: 0]};
assign pipe_rx1_data = (NO_OF_LANES >= 2 ) ? {gt_rx_data_wire[47:40], gt_rx_data_wire[39:32]} : 16'h0 ;
assign pipe_rx2_data = (NO_OF_LANES >= 4 ) ? {gt_rx_data_wire[79:72], gt_rx_data_wire[71:64]} : 16'h0 ;
assign pipe_rx3_data = (NO_OF_LANES >= 4 ) ? {gt_rx_data_wire[111:104], gt_rx_data_wire[103:96]} : 16'h0 ;
assign pipe_rx4_data = (NO_OF_LANES >= 8 ) ? {gt_rx_data_wire[143:136], gt_rx_data_wire[135:128]} : 16'h0 ;
assign pipe_rx5_data = (NO_OF_LANES >= 8 ) ? {gt_rx_data_wire[175:168], gt_rx_data_wire[167:160]} : 16'h0 ;
assign pipe_rx6_data = (NO_OF_LANES >= 8 ) ? {gt_rx_data_wire[207:200], gt_rx_data_wire[199:192]} : 16'h0 ;
assign pipe_rx7_data = (NO_OF_LANES >= 8 ) ? {gt_rx_data_wire[239:232], gt_rx_data_wire[231:224]} : 16'h0 ;


assign pipe_rx0_status = gt_rx_status_wire[ 2: 0];
assign pipe_rx1_status = (NO_OF_LANES >= 2 ) ? gt_rx_status_wire[ 5: 3] : 3'b0 ;
assign pipe_rx2_status = (NO_OF_LANES >= 4 ) ? gt_rx_status_wire[ 8: 6] : 3'b0 ;
assign pipe_rx3_status = (NO_OF_LANES >= 4 ) ? gt_rx_status_wire[11: 9] : 3'b0 ;
assign pipe_rx4_status = (NO_OF_LANES >= 8 ) ? gt_rx_status_wire[14:12] : 3'b0 ;
assign pipe_rx5_status = (NO_OF_LANES >= 8 ) ? gt_rx_status_wire[17:15] : 3'b0 ;
assign pipe_rx6_status = (NO_OF_LANES >= 8 ) ? gt_rx_status_wire[20:18] : 3'b0 ;
assign pipe_rx7_status = (NO_OF_LANES >= 8 ) ? gt_rx_status_wire[23:21] : 3'b0 ;

//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
//<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

assign pipe_rx0_elec_idle = gt_rx_elec_idle_wire[0];
assign pipe_rx1_elec_idle = (NO_OF_LANES >= 2 ) ? gt_rx_elec_idle_wire[1] : 1'b1 ;
assign pipe_rx2_elec_idle = (NO_OF_LANES >= 4 ) ? gt_rx_elec_idle_wire[2] : 1'b1 ;
assign pipe_rx3_elec_idle = (NO_OF_LANES >= 4 ) ? gt_rx_elec_idle_wire[3] : 1'b1 ;
assign pipe_rx4_elec_idle = (NO_OF_LANES >= 8 ) ? gt_rx_elec_idle_wire[4] : 1'b1 ;
assign pipe_rx5_elec_idle = (NO_OF_LANES >= 8 ) ? gt_rx_elec_idle_wire[5] : 1'b1 ;
assign pipe_rx6_elec_idle = (NO_OF_LANES >= 8 ) ? gt_rx_elec_idle_wire[6] : 1'b1 ;
assign pipe_rx7_elec_idle = (NO_OF_LANES >= 8 ) ? gt_rx_elec_idle_wire[7] : 1'b1 ;



assign pipe_rx0_valid = gt_rx_valid_wire[0];
assign pipe_rx1_valid = (NO_OF_LANES >= 2 ) ? gt_rx_valid_wire[1] : 1'b0 ;
assign pipe_rx2_valid = (NO_OF_LANES >= 4 ) ? gt_rx_valid_wire[2] : 1'b0 ;
assign pipe_rx3_valid = (NO_OF_LANES >= 4 ) ? gt_rx_valid_wire[3] : 1'b0 ;
assign pipe_rx4_valid = (NO_OF_LANES >= 8 ) ? gt_rx_valid_wire[4] : 1'b0 ;
assign pipe_rx5_valid = (NO_OF_LANES >= 8 ) ? gt_rx_valid_wire[5] : 1'b0 ;
assign pipe_rx6_valid = (NO_OF_LANES >= 8 ) ? gt_rx_valid_wire[6] : 1'b0 ;
assign pipe_rx7_valid = (NO_OF_LANES >= 8 ) ? gt_rx_valid_wire[7] : 1'b0 ;

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

assign phy_rdy_n = !(&plllkdet[NO_OF_LANES-1:0] & clock_locked);




endmodule
