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
// File       : pipe_wrapper.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Filename     :  pipe_wrapper.v
//  Description  :  PIPE Wrapper for 7 Series Transceiver
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//  Version      :  8.2
//------------------------------------------------------------------------------

//---------- PIPE Wrapper Hierarchy --------------------------------------------
//  pipe_wrapper.v 
//      pipe_clock.v
//      pipe_reset.v
//      qpll_reset.v
//          * Generate GTXE2_CHANNEL for every lane.
//              pipe_user.v
//              pipe_rate.v
//              pipe_sync.v
//              pipe_drp.v
//              gtx_wrapper.v
//          * Generate GTXE2_COMMON for every quad.
//              qpll_drp.v
//              qpll_wrapper.v
//------------------------------------------------------------------------------

//---------- PIPE Wrapper Attribute Encoding -----------------------------------
//  PCIE_SIM_MODE          : FALSE = Normal mode (default).
//                         : TRUE  = Simulation only.
//  PCIE_SI_REV            : 1.0 = For rev 1.0 silicon (default).
//                         : 1.1 = For rev 1.1 silicon.
//  PCIE_TXBUF_EN          : FALSE = TX buffer bypass (default).
//                         : TRUE  = TX buffer use.
//  PCIE_AUTO_TXSYNC       : 0 = Manual TX sync (default for 1.0 silicon).
//                         : 1 = Auto TX sync.
//  PCIE_AUTO_RXSYNC       : 0 = Manual RX sync (default for 1.0 silicon).
//                         : 1 = Auto RX sync.
//  PCIE_CHAN_BOND         : 0 = One-Hop (default).
//                         : 1 = Daisy-Chain.
//  PCIE_LANE              : 1 (default), 2, 4, or 8.
//  PCIE_LINK_SPEED        : 1 = PCIe Gen 1 Mode.
//                         : 2 = PCIe Gen 2 Mode.
//                         : 3 = PCIe Gen 3 Mode (default).
//  PCIE_REFCLK_FREQ       : 0 = 100 MHz (default).
//                         : 1 = 125 MHz.
//                         : 2 = 250 MHz.
//  PCIE_USERCLK[1/2]_FREQ : 0 =  31.25 MHz.
//                         : 1 =  62.50 MHz (default).
//                         : 2 = 125.00 MHz.
//                         : 3 = 250.00 MHz.
//                         : 4 = 500.00 MHz.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//  Width : The PIPE Wrapper supports only a 32-bit interface.  
//          In Gen 1 and 2 modes, only 16-bits (RXDATA[15:0]) are used.
//          In Gen 3 mode, all 32-bits are used.
//------------------------------------------------------------------------------


`timescale 1ns / 1ps



//---------- PIPE Wrapper ------------------------------------------------------
module pipe_wrapper #
(

    parameter PCIE_SIM_MODE      = "TRUE",                  // PCIe sim mode
    parameter PCIE_SI_REV        = "1.0",                   // PCIe silicon revision
    parameter PCIE_TXBUF_EN      = "FALSE",                 // PCIe TX buffer enable
    parameter PCIE_AUTO_TXSYNC   = 0,                       // PCIe TX auto sync
    parameter PCIE_AUTO_RXSYNC   = 0,                       // PCIe RX auto sync
    parameter PCIE_CHAN_BOND     = 0,                       // PCIe channel bonding mode
    parameter PCIE_LANE          = 1,                       // PCIe number of lanes
    parameter PCIE_LINK_SPEED    = 3,                       // PCIe link speed 
    parameter PCIE_REFCLK_FREQ   = 0,                       // PCIe reference clock frequency
    parameter PCIE_USERCLK1_FREQ = 1,                       // PCIe user clock 1 frequency
    parameter PCIE_USERCLK2_FREQ = 1                        // PCIe user clock 2 frequency
    
)

(

    //---------- PIPE Clock & Reset Ports -----------------
    input                           PIPE_CLK,
    input                           PIPE_RESET_N,
   
    output                          PIPE_PCLK,

    //---------- PIPE TX Data Ports ------------------------
    input       [(PCIE_LANE*32)-1:0]PIPE_TXDATA,
    input       [(PCIE_LANE*4)-1:0] PIPE_TXDATAK,
    
    output      [PCIE_LANE-1:0]     PIPE_TXP,
    output      [PCIE_LANE-1:0]     PIPE_TXN,

    //---------- PIPE RX Data Ports ------------------------
    input       [PCIE_LANE-1:0]     PIPE_RXP,
    input       [PCIE_LANE-1:0]     PIPE_RXN,
    
    output      [(PCIE_LANE*32)-1:0]PIPE_RXDATA,
    output      [(PCIE_LANE*4)-1:0] PIPE_RXDATAK,
    
    //---------- PIPE Command Ports ------------------------
    input                           PIPE_TXDETECTRX,
    input       [PCIE_LANE-1:0]     PIPE_TXELECIDLE,
    input       [PCIE_LANE-1:0]     PIPE_TXCOMPLIANCE,                
    input       [PCIE_LANE-1:0]     PIPE_RXPOLARITY,
    input       [(PCIE_LANE*2)-1:0] PIPE_POWERDOWN,
    input       [ 1:0]              PIPE_RATE,
    
    //---------- PIPE Electrical Command Ports -------------
    input       [17:0]              PIPE_TXDEEMPH,
    input       [ 1:0]              PIPE_TXEQCONTROL,       // *** TBD ***          
    input       [ 2:0]              PIPE_TXMARGIN,
    input                           PIPE_TXSWING,          
    
    output      [17:0]              PIPE_RXDEEMPH,          // *** TBD ***            
    output      [ 1:0]              PIPE_RXEQCONTROL,       // *** TBD ***            
    
    //---------- PIPE Status Ports -------------------------
    output      [PCIE_LANE-1:0]     PIPE_RXVALID,
    output      [PCIE_LANE-1:0]     PIPE_PHYSTATUS,
    output      [PCIE_LANE-1:0]     PIPE_PHYSTATUS_RST,
    output      [PCIE_LANE-1:0]     PIPE_RXELECIDLE,
    output      [(PCIE_LANE*3)-1:0] PIPE_RXSTATUS,
    
    //---------- PIPE User Ports ---------------------------
    input       [PCIE_LANE-1:0]     PIPE_RXSLIDE,
    
    output      [PCIE_LANE-1:0]     PIPE_CPLL_LOCK,
    output      [(PCIE_LANE-1)>>2:0]PIPE_QPLL_LOCK,
    output                          PIPE_PCLK_LOCK,
    output      [PCIE_LANE-1:0]     PIPE_RXCDRLOCK,
    output                          PIPE_USERCLK1,
    output                          PIPE_USERCLK2,
    output      [PCIE_LANE-1:0]		PIPE_RXUSRCLK,
    output      [PCIE_LANE-1:0]     PIPE_TXSYNC_DONE,
    output      [PCIE_LANE-1:0]     PIPE_RXSYNC_DONE,
    output      [PCIE_LANE-1:0]     PIPE_RXCHANISALIGNED,
    output      [PCIE_LANE-1:0]     PIPE_ACTIVE_LANE,
    
    //---------- Debug Ports -------------------------------
    output      [ 3:0]              PIPE_RST_FSM,
    output      [ 3:0]              PIPE_QRST_FSM,
    output      [(PCIE_LANE*5)-1:0] PIPE_RATE_FSM,
    output      [(PCIE_LANE*3)-1:0] PIPE_SYNC_FSM_TX,
    output      [(PCIE_LANE*3)-1:0] PIPE_SYNC_FSM_RX,
    output      [(PCIE_LANE*3)-1:0] PIPE_DRP_FSM,
    output      [((((PCIE_LANE-1)>>2)+1)*3)-1:0]PIPE_QDRP_FSM
    
);

    //---------- PIPE Clock Module Output ------------------ 
    wire                            clk_fab_refclk;
    wire                            clk_pclk;
    wire        [PCIE_LANE-1:0]     clk_rxusrclk;
    wire                            clk_dclk;
    wire                            clk_mmcm_lock;
    
    //---------- PIPE Reset Module Output ------------------
    wire                            rst_cpllreset;   
    wire                            rst_gtxreset;
    wire                            rst_userrdy;
    wire                            rst_txsync_start;
    wire        [ 3:0]              rst_fsm;
    
    //---------- QPLL Reset Module Output ------------------
    wire                            qrst_ovrd;
    wire                            qrst_drp_start;
    wire                            qrst_qpllreset;
    wire                            qrst_qpllpd;
    wire        [ 3:0]              qrst_fsm;
    
    //---------- PIPE User Module Output -------------------
    wire        [PCIE_LANE-1:0]     user_resetovrd;
    wire        [PCIE_LANE-1:0]     user_txpmareset;                 
    wire        [PCIE_LANE-1:0]     user_rxpmareset;                
    wire        [PCIE_LANE-1:0]     user_rxcdrreset;
    wire        [PCIE_LANE-1:0]     user_rxcdrfreqreset;
    wire        [PCIE_LANE-1:0]     user_rxdfelpmreset;
    wire        [PCIE_LANE-1:0]     user_eyescanreset;
    wire        [PCIE_LANE-1:0]     user_txpcsreset;                   
    wire        [PCIE_LANE-1:0]     user_rxpcsreset;                 
    wire        [PCIE_LANE-1:0]     user_rxbufreset;
    wire        [PCIE_LANE-1:0]     user_resetovrd_done;
    wire        [PCIE_LANE-1:0]     user_active_lane;
    wire        [PCIE_LANE-1:0]     user_resetdone;
    wire        [PCIE_LANE-1:0]     user_rxcdrlock;
    
    //---------- PIPE Rate Module Output -------------------
    wire        [PCIE_LANE-1:0]     rate_cpllpd;
    wire        [PCIE_LANE-1:0]     rate_qpllpd;
    wire        [PCIE_LANE-1:0]     rate_cpllreset;
    wire        [PCIE_LANE-1:0]     rate_qpllreset;
    wire        [PCIE_LANE-1:0]     rate_txpmareset;
    wire        [PCIE_LANE-1:0]     rate_rxpmareset;
    wire        [(PCIE_LANE*2)-1:0] rate_sysclksel;
    wire        [PCIE_LANE-1:0]     rate_drp_start;
    wire        [PCIE_LANE-1:0]     rate_pclk_sel;
    wire        [PCIE_LANE-1:0]     rate_gen3;
    wire        [(PCIE_LANE*3)-1:0] rate_rate;
    wire        [PCIE_LANE-1:0]     rate_resetovrd_start;
    wire        [PCIE_LANE-1:0]     rate_txsync_start;
    wire        [PCIE_LANE-1:0]     rate_done;
    wire        [PCIE_LANE-1:0]     rate_rxsync_start;
    wire        [(PCIE_LANE*5)-1:0] rate_fsm;

    //---------- PIPE Sync Module Output -------------------
    wire        [PCIE_LANE-1:0]     sync_txphalign;    
    wire        [PCIE_LANE-1:0]     sync_txphalignen; 
    wire        [PCIE_LANE-1:0]     sync_txphinit;    
    wire        [PCIE_LANE-1:0]     sync_txdlysreset;   
    wire        [PCIE_LANE-1:0]     sync_txdlyen;      
    wire        [PCIE_LANE-1:0]     sync_txsync_done;
    wire        [(PCIE_LANE*3)-1:0] sync_fsm_tx;
    
    wire        [PCIE_LANE-1:0]     sync_rxdlysreset;
    wire        [PCIE_LANE-1:0]     sync_rxsync_done;  
    wire        [(PCIE_LANE*3)-1:0] sync_fsm_rx;
    
    //---------- PIPE DRP Module Output --------------------
    wire        [(PCIE_LANE*9)-1:0] drp_addr;
    wire        [PCIE_LANE-1:0]     drp_en;
    wire        [(PCIE_LANE*16)-1:0]drp_di;   
    wire        [PCIE_LANE-1:0]     drp_we;
    wire        [PCIE_LANE-1:0]     drp_done;
    wire        [(PCIE_LANE*3)-1:0] drp_fsm;

    //---------- PIPE DRP Module Output --------------------
    wire        [((((PCIE_LANE-1)>>2)+1)*8)-1:0]    qdrp_addr;
    wire        [(PCIE_LANE-1)>>2:0]                qdrp_en;
    wire        [((((PCIE_LANE-1)>>2)+1)*16)-1:0]   qdrp_di;   
    wire        [(PCIE_LANE-1)>>2:0]                qdrp_we;
    wire        [(PCIE_LANE-1)>>2:0]                qdrp_done;
    wire        [((((PCIE_LANE-1)>>2)+1)*3)-1:0]    qdrp_fsm;

    //---------- QPLL Wrapper Output -----------------------
    wire        [(PCIE_LANE-1)>>2:0]                qpll_qplloutclk;
    wire        [(PCIE_LANE-1)>>2:0]                qpll_qplloutrefclk;
    wire        [(PCIE_LANE-1)>>2:0]                qpll_qplllock;
    wire        [((((PCIE_LANE-1)>>2)+1)*16)-1:0]   qpll_do;
    wire        [(PCIE_LANE-1)>>2:0]                qpll_rdy;

    //---------- GTX Wrapper Output ------------------------
    wire        [PCIE_LANE-1:0]     gtx_txoutclk;
    wire        [PCIE_LANE-1:0]     gtx_rxoutclk;
    wire        [PCIE_LANE-1:0]     gtx_cplllock;
    wire        [PCIE_LANE-1:0]     gtx_rxcdrlock;
    wire        [PCIE_LANE-1:0]     gtx_txresetdone;
    wire        [PCIE_LANE-1:0]     gtx_rxresetdone;
    wire        [PCIE_LANE-1:0]     gtx_rxvalid;
    wire        [PCIE_LANE-1:0]     gtx_phystatus;
    wire        [(PCIE_LANE*3)-1:0] gtx_rxstatus;
    wire        [PCIE_LANE-1:0]     gtx_rxelecidle;
    wire        [PCIE_LANE-1:0]     gtx_txratedone;
    wire        [PCIE_LANE-1:0]     gtx_rxratedone;
    wire        [(PCIE_LANE*16)-1:0]gtx_do;
    wire        [PCIE_LANE-1:0]     gtx_rdy;
    wire        [PCIE_LANE-1:0]     gtx_txphinitdone;  
    wire        [PCIE_LANE-1:0]     gtx_txdlysresetdone;
    wire        [PCIE_LANE-1:0]     gtx_txphaligndone;
    wire        [PCIE_LANE-1:0]     gtx_rxdlysresetdone;
    wire        [PCIE_LANE-1:0]     gtx_rxphaligndone;     
    wire        [ 4:0]              gtx_rxchbondi [PCIE_LANE:0]; 
    wire        [(PCIE_LANE*3)-1:0] gtx_rxchbondlevel;
    wire        [ 4:0]              gtx_rxchbondo [PCIE_LANE:0];  

    //---------- Generate Per-Lane Signals -----------------
    genvar                          i;                      // Index for per-lane signals
    
    
    
//---------- Channel Bonding ---------------------------------------------------
assign gtx_rxchbondo[0] = 5'd0;                             // Initialize rxchbond for lane 0 



//---------- PIPE Clock Module -------------------------------------------------
pipe_clock #
(

    .PCIE_TXBUF_EN                  (PCIE_TXBUF_EN),        // PCIe TX buffer enable
    .PCIE_LANE                      (PCIE_LANE),            // PCIe number of lanes
    .PCIE_LINK_SPEED    			(PCIE_LINK_SPEED),      // PCIe link speed 
    .PCIE_REFCLK_FREQ               (PCIE_REFCLK_FREQ),     // PCIe reference clock frequency
    .PCIE_USERCLK1_FREQ             (PCIE_USERCLK1_FREQ),   // PCIe user clock 1 frequency
    .PCIE_USERCLK2_FREQ             (PCIE_USERCLK2_FREQ)    // PCIe user clock 2 frequency
        
)
pipe_clock_i
(

    //---------- Input -------------------------------------
    .CLK_CLK                        (PIPE_CLK),
    .CLK_TXOUTCLK                   (gtx_txoutclk[0]),      // Reference clock from lane 0
    .CLK_RXOUTCLK                   (gtx_rxoutclk),         // Recovered clock from lane 0
    .CLK_RST_N                      (1'b1),                
    .CLK_PCLK_SEL                   (rate_pclk_sel),     
    .CLK_GEN3                       (rate_gen3[0]),         // Recovered clock select from lane 0 
    
    //---------- Output ------------------------------------
    .CLK_FAB_REFCLK                 (clk_fab_refclk),
    .CLK_PCLK                       (clk_pclk),
    .CLK_RXUSRCLK                   (clk_rxusrclk),
    .CLK_DCLK                       (clk_dclk),
    .CLK_USERCLK1                   (PIPE_USERCLK1),
    .CLK_USERCLK2                   (PIPE_USERCLK2),
    .CLK_MMCM_LOCK                  (clk_mmcm_lock)
    
);



//---------- PIPE Reset Module -------------------------------------------------
pipe_reset #
(

    .PCIE_TXBUF_EN                  (PCIE_TXBUF_EN),        // PCIe TX buffer enable
    .PCIE_LANE                      (PCIE_LANE)             // PCIe number of lanes

)
pipe_reset_i
(

    //---------- Input -------------------------------------
    .RST_CLK                        (clk_pclk),             // Use clk_fab_refclk if PCLK is not available during reset      
    .RST_RST_N                      (PIPE_RESET_N),
    .RST_CPLLLOCK                   (gtx_cplllock),
    .RST_RATE_FSM                   (rate_fsm),
    .RST_RXCDRLOCK                  (user_rxcdrlock),
    .RST_MMCM_LOCK                  (clk_mmcm_lock),
    .RST_RESETDONE                  (user_resetdone),
    .RST_PHYSTATUS                  (gtx_phystatus),
    .RST_TXSYNC_DONE                (sync_txsync_done),
    
    //---------- Output ------------------------------------
    .RST_CPLLRESET                  (rst_cpllreset),
    .RST_GTXRESET                   (rst_gtxreset),
    .RST_USERRDY                    (rst_userrdy),
    .RST_TXSYNC_START               (rst_txsync_start),
    .RST_FSM                        (rst_fsm)

);



//---------- QPLL Reset Module -------------------------------------------------
qpll_reset #
(

    .PCIE_LANE                      (PCIE_LANE)             // PCIe number of lanes
    
)
qpll_reset_i
(

    //---------- Input -------------------------------------
    .QRST_CLK                       (clk_pclk),             // Use clk_fab_refclk if PCLK is not available during reset
    .QRST_RST_N                     (PIPE_RESET_N),
    .QRST_MMCM_LOCK                 (clk_mmcm_lock),
    .QRST_DRP_DONE                  (qdrp_done),
    .QRST_QPLLLOCK                  (qpll_qplllock),
    .QRST_RATE                      (PIPE_RATE),
    .QRST_QPLLRESET_IN              (rate_qpllreset),
    .QRST_QPLLPD_IN                 (rate_qpllpd),
    
    //---------- Output ------------------------------------
    .QRST_OVRD                      (qrst_ovrd),
    .QRST_DRP_START                 (qrst_drp_start),
    .QRST_QPLLRESET_OUT             (qrst_qpllreset),
    .QRST_QPLLPD_OUT                (qrst_qpllpd),
    .QRST_FSM                       (qrst_fsm)

);



//---------- Generate PIPE Lane ------------------------------------------------
generate for (i=0; i<PCIE_LANE; i=i+1) begin : pipe_lane

//---------- PIPE User Module --------------------------------------------------
pipe_user pipe_user_i
(

    //---------- Input -------------------------------------
    .USER_CLK                       (clk_pclk),
    .USER_RST_N                     (!rst_cpllreset),
    .USER_RESETOVRD_START           (rate_resetovrd_start[i]),
    .USER_TXRESETDONE               (gtx_txresetdone[i]),
    .USER_RXRESETDONE               (gtx_rxresetdone[i]),
    .USER_TXELECIDLE                (PIPE_TXELECIDLE[i]),
    .USER_TXCOMPLIANCE              (PIPE_TXCOMPLIANCE[i]),
    .USER_RXCDRLOCK_IN              (gtx_rxcdrlock[i]),
    .USER_RXVALID_IN                (gtx_rxvalid[i]),
    .USER_RXSTATUS_IN               (gtx_rxstatus[(3*i)+2:(3*i)]),
    .USER_PHYSTATUS_IN              (gtx_phystatus[i]),
    .USER_RATE_DONE                 (rate_done[i]),
    .USER_RST_FSM                   (rst_fsm),
    .USER_RATE_FSM                  (rate_fsm[(5*i)+4:(5*i)]),
    
    //---------- Output ------------------------------------
    .USER_RESETOVRD                 (user_resetovrd[i]),
    .USER_TXPMARESET                (user_txpmareset[i]),                 
    .USER_RXPMARESET                (user_rxpmareset[i]),                
    .USER_RXCDRRESET                (user_rxcdrreset[i]),
    .USER_RXCDRFREQRESET            (user_rxcdrfreqreset[i]),
    .USER_RXDFELPMRESET             (user_rxdfelpmreset[i]),
    .USER_EYESCANRESET              (user_eyescanreset[i]),
    .USER_TXPCSRESET                (user_txpcsreset[i]),                   
    .USER_RXPCSRESET                (user_rxpcsreset[i]),                 
    .USER_RXBUFRESET                (user_rxbufreset[i]),
    .USER_RESETOVRD_DONE            (user_resetovrd_done[i]),
    .USER_RESETDONE                 (user_resetdone[i]),
    .USER_ACTIVE_LANE               (user_active_lane[i]),
    .USER_RXCDRLOCK_OUT             (user_rxcdrlock[i]),
    .USER_RXVALID_OUT               (PIPE_RXVALID[i]),
    .USER_PHYSTATUS_OUT             (PIPE_PHYSTATUS[i]),
    .USER_PHYSTATUS_RST             (PIPE_PHYSTATUS_RST[i])

);



//---------- PIPE Rate Module --------------------------------------------------
pipe_rate #
(

    .PCIE_SI_REV                    (PCIE_SI_REV),          // PCIe silicion revision
    .PCIE_TXBUF_EN                  (PCIE_TXBUF_EN)         // PCIe TX buffer enable
    
)
pipe_rate_i
(

    //---------- Input -------------------------------------
    .RATE_CLK                       (clk_pclk),
    .RATE_RST_N                     (!rst_cpllreset),
    .RATE_RST_FSM                   (rst_fsm),
    .RATE_ACTIVE_LANE               (user_active_lane[i]),
    .RATE_RATE_IN                   (PIPE_RATE),
    .RATE_CPLLLOCK                  (gtx_cplllock[i]),
    .RATE_QPLLLOCK                  (qpll_qplllock[i>>2]),
    .RATE_MMCM_LOCK                 (clk_mmcm_lock),
    .RATE_DRP_DONE                  (drp_done[i]),
    .RATE_TXRESETDONE               (gtx_txresetdone[i]),
    .RATE_RXRESETDONE               (gtx_rxresetdone[i]),
    .RATE_TXRATEDONE                (gtx_txratedone[i]),
    .RATE_RXRATEDONE                (gtx_rxratedone[i]),
    .RATE_PHYSTATUS                 (gtx_phystatus[i]),
    .RATE_RESETOVRD_DONE            (user_resetovrd_done[i]),
    .RATE_TXSYNC_DONE               (sync_txsync_done[i]),        		
    .RATE_RXSYNC_DONE               (sync_rxsync_done[i]),	

    //---------- Output ------------------------------------
    .RATE_CPLLPD                    (rate_cpllpd[i]),
    .RATE_QPLLPD                    (rate_qpllpd[i]),
    .RATE_CPLLRESET                 (rate_cpllreset[i]),
    .RATE_QPLLRESET                 (rate_qpllreset[i]),
    .RATE_TXPMARESET                (rate_txpmareset[i]),
    .RATE_RXPMARESET                (rate_rxpmareset[i]),
    .RATE_SYSCLKSEL                 (rate_sysclksel[(2*i)+1:(2*i)]),
    .RATE_DRP_START                 (rate_drp_start[i]),
    .RATE_PCLK_SEL                  (rate_pclk_sel[i]),
    .RATE_GEN3                      (rate_gen3[i]),
    .RATE_RATE_OUT                  (rate_rate[(3*i)+2:(3*i)]),
    .RATE_RESETOVRD_START           (rate_resetovrd_start[i]),
    .RATE_TXSYNC_START              (rate_txsync_start[i]),
    .RATE_DONE                      (rate_done[i]),
    .RATE_RXSYNC_START              (rate_rxsync_start[i]),
    .RATE_FSM                       (rate_fsm[(5*i)+4:(5*i)])
    
);



//---------- PIPE Sync Module --------------------------------------------------
pipe_sync # 
(

    .PCIE_AUTO_TXSYNC               (PCIE_AUTO_TXSYNC),         // PCIe TX auto sync
    .PCIE_AUTO_RXSYNC               (PCIE_AUTO_RXSYNC)          // PCIe RX auto sync

)
pipe_sync_i 
(

    //---------- Input -------------------------------------
    .SYNC_CLK                       (clk_pclk),
    .SYNC_RST_N                     (!rst_cpllreset),
    .SYNC_SLAVE                     (i > 0),
    .SYNC_MMCM_LOCK                 (clk_mmcm_lock),
    .SYNC_RXELECIDLE                (gtx_rxelecidle[i]),
    .SYNC_RXCDRLOCK                 (user_rxcdrlock[i]),
    
    .SYNC_TXSYNC_START              (rate_txsync_start[i] || rst_txsync_start),
    .SYNC_TXPHINITDONE              (&gtx_txphinitdone),     
    .SYNC_TXDLYSRESETDONE           (PCIE_AUTO_TXSYNC ? gtx_txdlysresetdone[i] : &gtx_txdlysresetdone),                 
    .SYNC_TXPHALIGNDONE             (PCIE_AUTO_TXSYNC ? gtx_txphaligndone[i]   : &gtx_txphaligndone),  
    
    .SYNC_RXSYNC_START              (rate_rxsync_start[i]),
    .SYNC_RXDLYSRESETDONE           (gtx_rxdlysresetdone[i]),
    .SYNC_RXPHALIGNDONE             (gtx_rxphaligndone[i]), 

    //---------- Output ------------------------------------
    .SYNC_TXPHALIGN                 (sync_txphalign[i]),           
    .SYNC_TXPHALIGNEN               (sync_txphalignen[i]),        
    .SYNC_TXPHINIT                  (sync_txphinit[i]),            
    .SYNC_TXDLYEN                   (sync_txdlyen[i]),            
    .SYNC_TXDLYSRESET               (sync_txdlysreset[i]),
    .SYNC_TXSYNC_DONE               (sync_txsync_done[i]),
    .SYNC_FSM_TX                    (sync_fsm_tx[(3*i)+2:(3*i)]),
    
    .SYNC_RXDLYSRESET               (sync_rxdlysreset[i]),
    .SYNC_RXSYNC_DONE               (sync_rxsync_done[i]),
    .SYNC_FSM_RX                    (sync_fsm_rx[(3*i)+2:(3*i)])
    
);


//---------- PIPE DRP Module ---------------------------------------------------
pipe_drp #
(

    .PCIE_SI_REV                    (PCIE_SI_REV),          // PCIe silicion revision
    .PCIE_TXBUF_EN                  (PCIE_TXBUF_EN),        // PCIe TX buffer enable
    .PCIE_AUTO_TXSYNC               (PCIE_AUTO_TXSYNC),     // PCIe TX auto sync
    .PCIE_AUTO_RXSYNC               (PCIE_AUTO_RXSYNC)      // PCIe RX auto sync

)
pipe_drp_i
(
    
    //---------- Input -------------------------------------
    .DRP_CLK                        (clk_dclk),
    .DRP_RST_N                      (!rst_cpllreset),
    .DRP_GTXRESET                   (rst_gtxreset),
    .DRP_RATE                       (PIPE_RATE),
    .DRP_START                      (rate_drp_start[i]),                      
    .DRP_DO                         (gtx_do[(16*i)+15:(16*i)]),
    .DRP_RDY                        (gtx_rdy[i]),
    
    //---------- Output ------------------------------------
    .DRP_ADDR                       (drp_addr[(9*i)+8:(9*i)]),
    .DRP_EN                         (drp_en[i]),  
    .DRP_DI                         (drp_di[(16*i)+15:(16*i)]),   
    .DRP_WE                         (drp_we[i]),
    .DRP_DONE                       (drp_done[i]),
    .DRP_FSM                        (drp_fsm[(3*i)+2:(3*i)])
    
);



//---------- Generate PIPE Common Per Quad -------------------------------------
if ((i%4)==0) begin : pipe_common

//---------- QPLL DRP Module ---------------------------------------------------
qpll_drp qpll_drp_i
(
    
    //---------- Input -------------------------------------
    .DRP_CLK                        (clk_dclk),
    .DRP_RST_N                      (!rst_cpllreset),
    .DRP_OVRD                       (qrst_ovrd),
    .DRP_START                      (qrst_drp_start),                      
    .DRP_DO                         (qpll_do[(16*(i>>2))+15:(16*(i>>2))]),
    .DRP_RDY                        (qpll_rdy[i>>2]),
    
    //---------- Output ------------------------------------
    .DRP_ADDR                       (qdrp_addr[(8*(i>>2))+7:(8*(i>>2))]),
    .DRP_EN                         (qdrp_en[i>>2]),  
    .DRP_DI                         (qdrp_di[(16*(i>>2))+15:(16*(i>>2))]),   
    .DRP_WE                         (qdrp_we[i>>2]),
    .DRP_DONE                       (qdrp_done[i>>2]),
    .DRP_FSM                        (qdrp_fsm[(3*(i>>2))+2:(3*(i>>2))])
    
);



//---------- QPLL Wrapper ------------------------------------------------------
qpll_wrapper #
(

    .PCIE_SIM_MODE                  (PCIE_SIM_MODE),        // PCIe sim mode
    .PCIE_REFCLK_FREQ               (PCIE_REFCLK_FREQ)      // PCIe reference clock frequency
 
)
qpll_wrapper_i
(    
    
    //---------- QPLL Clock Ports --------------------------
    .QPLL_GTGREFCLK                 (PIPE_CLK),
    .QPLL_QPLLLOCKDETCLK            (clk_fab_refclk),
    
    .QPLL_QPLLOUTCLK                (qpll_qplloutclk[i>>2]),
    .QPLL_QPLLOUTREFCLK             (qpll_qplloutrefclk[i>>2]),
    .QPLL_QPLLLOCK                  (qpll_qplllock[i>>2]),
    
    //---------- QPLL Reset Ports --------------------------
    .QPLL_QPLLPD                    (qrst_qpllpd),         
    .QPLL_QPLLRESET                 (qrst_qpllreset),      

    //---------- GTX DRP Ports -----------------------------
    .QPLL_DRPCLK                    (clk_dclk),
    .QPLL_DRPADDR                   (qdrp_addr[(8*(i>>2))+7:(8*(i>>2))]),
    .QPLL_DRPEN                     (qdrp_en[i>>2]),
    .QPLL_DRPDI                     (qdrp_di[(16*(i>>2))+15:(16*(i>>2))]),
    .QPLL_DRPWE                     (qdrp_we[i>>2]),
    
    .QPLL_DRPDO                     (qpll_do[(16*(i>>2))+15:(16*(i>>2))]),
    .QPLL_DRPRDY                    (qpll_rdy[i>>2])
    
);

end



//---------- GTX Wrapper -------------------------------------------------------
gtx_wrapper #
(

    .PCIE_SIM_MODE                  (PCIE_SIM_MODE),        // PCIe sim mode
    .PCIE_SI_REV                    (PCIE_SI_REV),          // PCIe silicion revision
    .PCIE_TXBUF_EN                  (PCIE_TXBUF_EN),        // PCIe TX buffer enable
    .PCIE_AUTO_TXSYNC               (PCIE_AUTO_TXSYNC),     // PCIe TX auto sync
    .PCIE_AUTO_RXSYNC               (PCIE_AUTO_RXSYNC),     // PCIe RX auto sync
    .PCIE_CHAN_BOND                 (PCIE_CHAN_BOND),       // PCIe Channel bonding mode
    .PCIE_LANE                      (PCIE_LANE),            // PCIe number of lane
    .PCIE_REFCLK_FREQ               (PCIE_REFCLK_FREQ)      // PCIe reference clock frequency

)
gtx_wrapper_i
(

    //---------- GTX User Ports ----------------------------
    .GTX_GEN3                       (rate_gen3[i]),  

    //---------- GTX Clock Ports ---------------------------
    .GTX_GTREFCLK0                  (PIPE_CLK),
    .GTX_QPLLCLK                    (qpll_qplloutclk[i>>2]),
    .GTX_QPLLREFCLK                 (qpll_qplloutrefclk[i>>2]),
    .GTX_TXUSRCLK                   (clk_pclk),
    .GTX_RXUSRCLK                   (clk_rxusrclk[0]),      // From Lane 0
    .GTX_TXUSRCLK2                  (clk_pclk),
    .GTX_RXUSRCLK2                  (clk_rxusrclk[0]),      // From Lane 0
    .GTX_TXSYSCLKSEL                (rate_sysclksel[(2*i)+1:(2*i)]),
    .GTX_RXSYSCLKSEL                (rate_sysclksel[(2*i)+1:(2*i)]),
    
    .GTX_TXOUTCLK                   (gtx_txoutclk[i]),
    .GTX_RXOUTCLK                   (gtx_rxoutclk[i]),
    .GTX_CPLLLOCK                   (gtx_cplllock[i]),  
    .GTX_RXCDRLOCK                  (gtx_rxcdrlock[i]),
    
    //---------- GTX Reset Ports ---------------------------
    .GTX_CPLLPD                     (rate_cpllpd[i]),
    .GTX_CPLLRESET                  (rst_cpllreset || rate_cpllreset[i]),
    .GTX_TXUSERRDY                  (rst_userrdy),
    .GTX_RXUSERRDY                  (rst_userrdy),
    .GTX_RESETOVRD                  (user_resetovrd[i]),
    .GTX_GTXTXRESET                 (rst_gtxreset),
    .GTX_GTXRXRESET                 (rst_gtxreset),
    .GTX_TXPMARESET                 (user_txpmareset[i] || rate_txpmareset[i]),                 
    .GTX_RXPMARESET                 (user_rxpmareset[i] || rate_rxpmareset[i]),                
    .GTX_RXCDRRESET                 (user_rxcdrreset[i]),
    .GTX_RXCDRFREQRESET             (user_rxcdrfreqreset[i]),
    .GTX_RXDFELPMRESET              (user_rxdfelpmreset[i]),
    .GTX_EYESCANRESET               (user_eyescanreset[i]),
    .GTX_TXPCSRESET                 (user_txpcsreset[i]),                   
    .GTX_RXPCSRESET                 (user_rxpcsreset[i]),                 
    .GTX_RXBUFRESET                 (user_rxbufreset[i]),

    .GTX_TXRESETDONE                (gtx_txresetdone[i]),
    .GTX_RXRESETDONE                (gtx_rxresetdone[i]),
    
    //---------- GTX TX Data Ports -------------------------
    .GTX_TXDATA                     (PIPE_TXDATA[(32*i)+31:(32*i)]),
    .GTX_TXDATAK                    (PIPE_TXDATAK[(4*i)+3:(4*i)]),
    
    .GTX_TXP                        (PIPE_TXP[i]),
    .GTX_TXN                        (PIPE_TXN[i]),
    
    //---------- GTX RX Data Ports -------------------------
    .GTX_RXP                        (PIPE_RXP[i]),
    .GTX_RXN                        (PIPE_RXN[i]),
    
    .GTX_RXDATA                     (PIPE_RXDATA[(32*i)+31:(32*i)]),
    .GTX_RXDATAK                    (PIPE_RXDATAK[(4*i)+3:(4*i)]),
    
    //---------- GTX Command Ports -------------------------
    .GTX_TXDETECTRX                 (PIPE_TXDETECTRX),
    .GTX_TXELECIDLE                 (PIPE_TXELECIDLE[i]), 
    .GTX_TXCOMPLIANCE               (PIPE_TXCOMPLIANCE[i]),
    .GTX_RXPOLARITY                 (PIPE_RXPOLARITY[i]),
    .GTX_TXPOWERDOWN                (PIPE_POWERDOWN[(2*i)+1:(2*i)]),
    .GTX_RXPOWERDOWN                (PIPE_POWERDOWN[(2*i)+1:(2*i)]),
    .GTX_TXRATE                     (rate_rate[(3*i)+2:(3*i)]),
    .GTX_RXRATE                     (rate_rate[(3*i)+2:(3*i)]),        
        
    //---------- GTX Electrical Command Ports --------------
    .GTX_TXDEEMPH                   (PIPE_TXDEEMPH),    
    .GTX_TXMARGIN                   (PIPE_TXMARGIN),
    .GTX_TXSWING                    (PIPE_TXSWING),

    //---------- GTX Status Ports --------------------------
    .GTX_RXVALID                    (gtx_rxvalid[i]),
    .GTX_PHYSTATUS                  (gtx_phystatus[i]),
    .GTX_RXELECIDLE                 (gtx_rxelecidle[i]),
    .GTX_RXSTATUS                   (gtx_rxstatus[(3*i)+2:(3*i)]),
    .GTX_TXRATEDONE                 (gtx_txratedone[i]),
    .GTX_RXRATEDONE                 (gtx_rxratedone[i]),

    //---------- GTX DRP Ports -----------------------------
    .GTX_DRPCLK                     (clk_dclk),
    .GTX_DRPADDR                    (drp_addr[(9*i)+8:(9*i)]),
    .GTX_DRPEN                      (drp_en[i]),
    .GTX_DRPDI                      (drp_di[(16*i)+15:(16*i)]),
    .GTX_DRPWE                      (drp_we[i]),
   
    .GTX_DRPDO                      (gtx_do[(16*i)+15:(16*i)]),
    .GTX_DRPRDY                     (gtx_rdy[i]),
    
    //---------- GTX TX Sync Ports -------------------------
    .GTX_TXPHALIGN                  (sync_txphalign[i]),    
    .GTX_TXPHALIGNEN                (sync_txphalignen[i]), 
    .GTX_TXPHINIT                   (sync_txphinit[i]),     
    .GTX_TXDLYSRESET                (sync_txdlysreset[i]),
    .GTX_TXDLYEN                    (sync_txdlyen[i]),      
    
    .GTX_TXDLYSRESETDONE            (gtx_txdlysresetdone[i]),
    .GTX_TXPHINITDONE               (gtx_txphinitdone[i]),  
    .GTX_TXPHALIGNDONE              (gtx_txphaligndone[i]), 
    
    //---------- GTX RX Sync Ports -------------------------
    .GTX_RXDLYSRESET                (sync_rxdlysreset[i]),
    
    .GTX_RXDLYSRESETDONE            (gtx_rxdlysresetdone[i]),
    .GTX_RXPHALIGNDONE              (gtx_rxphaligndone[i]),
    
    //---------- GTX Comma Alignment Ports -----------------
    .GTX_RXSLIDE                    (PIPE_RXSLIDE[i]),
    
    //---------- GTX Channel Bonding Ports -----------------
    .GTX_RXCHANISALIGNED            (PIPE_RXCHANISALIGNED[i]),
    .GTX_RXCHBONDEN                 ((PCIE_LANE > 1) && (!rate_gen3[i])),
    .GTX_RXCHBONDI                  (gtx_rxchbondi[i]),
    .GTX_RXCHBONDLEVEL              (gtx_rxchbondlevel[(3*i)+2:(3*i)]),
    .GTX_RXCHBONDMASTER             (i == 0),
    .GTX_RXCHBONDSLAVE              (i  > 0),
    
    .GTX_RXCHBONDO                  (gtx_rxchbondo[i+1])
    
);

    //---------- Channel Bonding Level -----------------------------------------
    assign gtx_rxchbondi[i]                 = (PCIE_CHAN_BOND == 1) ? gtx_rxchbondo[i] : ((i == 0) ? gtx_rxchbondo[0] : gtx_rxchbondo[1]);
    assign gtx_rxchbondlevel[(3*i)+2:(3*i)] = (PCIE_CHAN_BOND == 1) ? (PCIE_LANE-1)-i  : ((PCIE_LANE > 1) && (i == 0));     

end endgenerate



//---------- PIPE Wrapper Output -----------------------------------------------
assign PIPE_RXELECIDLE  = gtx_rxelecidle;
assign PIPE_RXSTATUS    = gtx_rxstatus;
assign PIPE_CPLL_LOCK   = gtx_cplllock;   
assign PIPE_QPLL_LOCK   = qpll_qplllock;
assign PIPE_PCLK        = clk_pclk;
assign PIPE_PCLK_LOCK   = clk_mmcm_lock; 
assign PIPE_RXCDRLOCK   = user_rxcdrlock;
assign PIPE_RXUSRCLK    = clk_rxusrclk;
assign PIPE_TXSYNC_DONE = sync_txsync_done;
assign PIPE_RXSYNC_DONE = sync_rxsync_done;
assign PIPE_ACTIVE_LANE = user_active_lane;
assign PIPE_RST_FSM     = rst_fsm;
assign PIPE_QRST_FSM    = qrst_fsm;
assign PIPE_RATE_FSM    = rate_fsm;
assign PIPE_SYNC_FSM_TX = sync_fsm_tx;
assign PIPE_SYNC_FSM_RX = sync_fsm_rx;
assign PIPE_DRP_FSM     = drp_fsm;   
assign PIPE_QDRP_FSM    = qdrp_fsm;



endmodule
