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
// File       : gtx_wrapper.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  GTX Wrapper for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- GTX Wrapper -------------------------------------------------------
module gtx_wrapper #
(
    
    parameter PCIE_SIM_MODE    = "FALSE",                   // PCIe sim mode
    parameter PCIE_SI_REV       = "1.0",                    // PCIe silicon revision
    parameter PCIE_TXBUF_EN    = "FALSE",                   // PCIe TX buffer enable
    parameter PCIE_AUTO_TXSYNC = 0,                         // PCIe Auto TX sync
    parameter PCIE_AUTO_RXSYNC = 0,                         // PCIe Auto RX sync
    parameter PCIE_CHAN_BOND   = 0,                         // PCIe channel bonding mode
    parameter PCIE_LANE        = 1,                         // PCIe number of lane
    parameter PCIE_REFCLK_FREQ = 0                          // PCIe reference clock frequency
 
)

(    
    
    //---------- GTX User Ports ----------------------------
    input               GTX_GEN3,                           
    
    //---------- GTX Clock Ports ---------------------------
    input               GTX_GTREFCLK0,
    input               GTX_QPLLCLK,
    input               GTX_QPLLREFCLK,
    input               GTX_TXUSRCLK,
    input               GTX_RXUSRCLK,
    input               GTX_TXUSRCLK2,
    input               GTX_RXUSRCLK2, 
    input       [ 1:0]  GTX_TXSYSCLKSEL,
    input       [ 1:0]  GTX_RXSYSCLKSEL,                
                         
    output              GTX_TXOUTCLK,
    output              GTX_RXOUTCLK,
    output              GTX_CPLLLOCK,
    output              GTX_RXCDRLOCK,
    
    //---------- GTX Reset Ports ---------------------------
    input               GTX_CPLLPD,
    input               GTX_CPLLRESET,
    input               GTX_TXUSERRDY,
    input               GTX_RXUSERRDY,
    input               GTX_RESETOVRD,
    input               GTX_GTXTXRESET,
    input               GTX_GTXRXRESET,
    input               GTX_TXPMARESET,
    input               GTX_RXPMARESET,
    input               GTX_RXCDRRESET,
    input               GTX_RXCDRFREQRESET,
    input               GTX_RXDFELPMRESET,
    input               GTX_EYESCANRESET,
    input               GTX_TXPCSRESET,
    input               GTX_RXPCSRESET,
    input               GTX_RXBUFRESET,
    
    output              GTX_TXRESETDONE,
    output              GTX_RXRESETDONE,
    
    //---------- GTX TX Data Ports -------------------------
    input       [31:0]  GTX_TXDATA,
    input       [ 3:0]  GTX_TXDATAK,
    
    output              GTX_TXP,
    output              GTX_TXN,
    
    //---------- GTX RX Data Ports -------------------------
    input               GTX_RXN,
    input               GTX_RXP,
    
    output      [31:0]  GTX_RXDATA,
    output      [ 3:0]  GTX_RXDATAK,
    
    //---------- GTX Command Ports -------------------------
    input               GTX_TXDETECTRX,
    input               GTX_TXELECIDLE,
    input               GTX_TXCOMPLIANCE,
    input               GTX_RXPOLARITY,
    input       [ 1:0]  GTX_TXPOWERDOWN,
    input       [ 1:0]  GTX_RXPOWERDOWN,
    input       [ 2:0]  GTX_TXRATE,
    input       [ 2:0]  GTX_RXRATE,
      
    //---------- GTX Electrical Command Ports --------------
    input       [17:0]  GTX_TXDEEMPH,
    input       [ 2:0]  GTX_TXMARGIN,
    input               GTX_TXSWING,
       
    //---------- GTX Status Ports --------------------------
    output              GTX_RXVALID,
    output              GTX_PHYSTATUS,
    output              GTX_RXELECIDLE,
    output      [ 2:0]  GTX_RXSTATUS,
    output              GTX_TXRATEDONE,
    output              GTX_RXRATEDONE,

    //---------- GTX DRP Ports -----------------------------
    input               GTX_DRPCLK,
    input       [ 8:0]  GTX_DRPADDR,
    input               GTX_DRPEN,
    input       [15:0]  GTX_DRPDI,
    input               GTX_DRPWE,
    
    output      [15:0]  GTX_DRPDO,
    output              GTX_DRPRDY,
    
    //---------- GTX TX Sync Ports -------------------------
    input               GTX_TXPHALIGN,     
    input               GTX_TXPHALIGNEN,  
    input               GTX_TXPHINIT,      
    input               GTX_TXDLYSRESET,
    input               GTX_TXDLYEN,       
    
    output              GTX_TXDLYSRESETDONE,
    output              GTX_TXPHINITDONE,  
    output              GTX_TXPHALIGNDONE,

    //---------- GTX RX Sync Ports -------------------------
    input               GTX_RXDLYSRESET,
    
    output              GTX_RXDLYSRESETDONE,
    output              GTX_RXPHALIGNDONE,
    
    //---------- GTX Comma Alignment Ports -----------------
    input               GTX_RXSLIDE,
    
    //---------- GTX Channel Bonding Ports -----------------
    input               GTX_RXCHBONDEN,
    input       [ 4:0]  GTX_RXCHBONDI,
    input       [ 2:0]  GTX_RXCHBONDLEVEL,
    input               GTX_RXCHBONDMASTER,
    input               GTX_RXCHBONDSLAVE,
    
    output              GTX_RXCHANISALIGNED,
    output      [ 4:0]  GTX_RXCHBONDO
    
);

    //---------- Internal Signals --------------------------
    wire        [63:0]  rxdata;
    wire        [ 7:0]  rxdatak;

    //---------- Select Clock Divider ----------------------
    localparam          CPLL_REFCLK_DIV = 1;
    localparam          CPLL_FBDIV_45   = 5;
    localparam          CPLL_FBDIV      = (PCIE_REFCLK_FREQ == 2) ?  2 : 
                                          (PCIE_REFCLK_FREQ == 1) ?  4 : 5;
    localparam          CPLL_OUT_DIV    = 2;                                                     
    localparam          CLK25_DIV       = (PCIE_REFCLK_FREQ == 2) ? 10 : 
                                          (PCIE_REFCLK_FREQ == 1) ?  5 : 4;

    //---------- Select Clock Correct Latency --------------
    //  CLK_COR_MIN_LAT = Larger of (2 * RXCHBONDLEVEL + 13) or (CHAN_BOND_MAX_SKEW + 11)
    //                  = 13 when PCIE_LANE = 1
    //  CLK_COR_MAX_LAT = CLK_COR_MIN_LAT + CLK_COR_SEQ_LEN + 1
    //------------------------------------------------------
    localparam          CLK_COR_MIN_LAT = ((PCIE_LANE == 8) && (PCIE_CHAN_BOND == 1)) ? 27 : 
                                          ((PCIE_LANE == 7) && (PCIE_CHAN_BOND == 1)) ? 25 : 
                                          ((PCIE_LANE == 6) && (PCIE_CHAN_BOND == 1)) ? 23 : 
                                          ((PCIE_LANE == 5) && (PCIE_CHAN_BOND == 1)) ? 21 : 
                                          ((PCIE_LANE == 4) && (PCIE_CHAN_BOND == 1)) ? 19 : 
                                          ((PCIE_LANE == 3) && (PCIE_CHAN_BOND == 1)) ? 18 : 
                                          ((PCIE_LANE == 2) && (PCIE_CHAN_BOND == 1)) ? 18 : 
                                           (PCIE_LANE == 1)                           ? 13 : 18; 
    localparam          CLK_COR_MAX_LAT = CLK_COR_MIN_LAT + 2;                                                     



    //---------- Select PCS_RSVD_ATTR ---------------------------------------------- 
    localparam          PCS_RSVD_ATTR = ((PCIE_SI_REV == "1.0")                             && (PCIE_TXBUF_EN == "FALSE")) ? 48'h000000000081 :
                                        ((PCIE_SI_REV == "1.0")                             && (PCIE_TXBUF_EN == "TRUE"))  ? 48'h000000000080 : 
                                        ((PCIE_AUTO_RXSYNC == 0) && (PCIE_AUTO_TXSYNC == 0) && (PCIE_TXBUF_EN == "FALSE")) ? 48'h000000000087 : 
                                        ((PCIE_AUTO_RXSYNC == 0) && (PCIE_AUTO_TXSYNC == 0) && (PCIE_TXBUF_EN == "TRUE"))  ? 48'h000000000086 : 
                                        ((PCIE_AUTO_RXSYNC == 0) && (PCIE_AUTO_TXSYNC == 1) && (PCIE_TXBUF_EN == "FALSE")) ? 48'h000000000085 : 
                                        ((PCIE_AUTO_RXSYNC == 0) && (PCIE_AUTO_TXSYNC == 1) && (PCIE_TXBUF_EN == "TRUE"))  ? 48'h000000000084 : 
                                        ((PCIE_AUTO_RXSYNC == 1) && (PCIE_AUTO_TXSYNC == 0) && (PCIE_TXBUF_EN == "FALSE")) ? 48'h000000000083 : 
                                        ((PCIE_AUTO_RXSYNC == 1) && (PCIE_AUTO_TXSYNC == 0) && (PCIE_TXBUF_EN == "TRUE"))  ? 48'h000000000082 : 
                                        ((PCIE_AUTO_RXSYNC == 1) && (PCIE_AUTO_TXSYNC == 1) && (PCIE_TXBUF_EN == "FALSE")) ? 48'h000000000081 : 
                                        ((PCIE_AUTO_RXSYNC == 1) && (PCIE_AUTO_TXSYNC == 1) && (PCIE_TXBUF_EN == "TRUE"))  ? 48'h000000000080 :  48'h000000000081; 
      
      
 
//---------- GTX Channel Module ------------------------------------------------
GTXE2_CHANNEL #
(
           
    //---------- Simulation Attributes ---------------------
    .SIM_CPLLREFCLK_SEL             (3'b000),               //
    .SIM_RESET_SPEEDUP            	(PCIE_SIM_MODE),        //
    .SIM_RECEIVER_DETECT_PASS       ("TRUE"),               //    
    .SIM_TX_EIDLE_DRIVE_LEVEL       ("Z"),                  // 
    .SIM_VERSION                    ("1.0"),                //

    //---------- Clock Attributes --------------------------                      
    .CPLL_REFCLK_DIV                (CPLL_REFCLK_DIV),      //
    .CPLL_FBDIV_45                  (CPLL_FBDIV_45),        //
    .CPLL_FBDIV                     (CPLL_FBDIV),           //
    .CPLL_TXOUT_DIV                 (CPLL_OUT_DIV),         //
    .CPLL_RXOUT_DIV                 (CPLL_OUT_DIV),         // 
    .TX_CLK25_DIV                   (CLK25_DIV),            //
    .RX_CLK25_DIV                   (CLK25_DIV),            //
    .TX_CLKMUX_PD                   (1'b0),                 // 
    .RX_CLKMUX_PD                   (1'b0),                 // 
    .TX_XCLK_SEL                    ((PCIE_TXBUF_EN == "TRUE") ? "TXOUT" : "TXUSR"), // TXUSR to bypass TX buffer
    .RX_XCLK_SEL                    ("RXREC"),              // RXREC to use RX buffer
    .OUTREFCLK_SEL_INV              (2'd3),                 //
    .CPLL_CFG                       (24'h2383E0),           //
    .CPLL_INIT_CFG                  (24'h00001A),           // Must be non-zero
    .CPLL_LOCK_CFG                  (16'h01FC),             //
    
    //---------- Reset Attributes --------------------------
    .TXPCSRESET_TIME	            (5'b00001),             //
    .RXPCSRESET_TIME	            (5'b00001),             //
    .TXPMARESET_TIME                (5'b00001),             //
    .RXPMARESET_TIME                (5'b00001),             //
    .RXISCANRESET_TIME              (5'b00001),             //
    
    //---------- TX Data Attributes ------------------------
    .TX_DATA_WIDTH                  (20),                   // 2-byte external datawidth
    .TX_INT_DATAWIDTH	            (0),                    // 2-byte internal datawidth

    //---------- RX Data Attributes ------------------------
    .RX_DATA_WIDTH                  (20),                   // 2-byte external datawidth
    .RX_INT_DATAWIDTH	            (0),                    // 2-byte internal datawidth
 
    //---------- Command Attributes ------------------------
    .TX_RXDETECT_CFG	            (14'h0050),             // [10:0] must be at least 14'h0020
    .TX_RXDETECT_REF	            (3'b100),               //
    .TX_EIDLE_ASSERT_DELAY	        (3'b100),               // Verified in Denali sim
    .TX_EIDLE_DEASSERT_DELAY	    (3'b010),               // Verified in Denali sim
    .PD_TRANS_TIME_FROM_P2	        (12'h03C),              //
    .PD_TRANS_TIME_NONE_P2	        (8'h19),                //
    .PD_TRANS_TIME_TO_P2	        (8'h64),                //
    .TRANS_TIME_RATE	            (8'h0E),                //
 
    //---------- Electrical Command Attributes -------------
    .TX_DRIVE_MODE                  ("PIPE"),               //
    .TX_DEEMPH0                     (5'b00000),             //
    .TX_DEEMPH1                     (5'b00000),             //
    .TX_MARGIN_FULL_0               (7'b1001110),           //
    .TX_MARGIN_FULL_1               (7'b1001001),           //
    .TX_MARGIN_FULL_2               (7'b1000101),           //
    .TX_MARGIN_FULL_3               (7'b1000010),           //
    .TX_MARGIN_FULL_4               (7'b1000000),           //
    .TX_MARGIN_LOW_0                (7'b1000110),           //
    .TX_MARGIN_LOW_1                (7'b1000100),           //
    .TX_MARGIN_LOW_2                (7'b1000010),           //
    .TX_MARGIN_LOW_3                (7'b1000000),           //
    .TX_MARGIN_LOW_4                (7'b1000000),           //
    .TX_MAINCURSOR_SEL              (1'b1),                 //
    .TX_PREDRIVER_MODE              (1'b0),                 //

    //---------- Status Attributes -------------------------
    .RX_SIG_VALID_DLY               (4),                    // Verified in Denali sim

    //---------- DRP Attributes ----------------------------

    //---------- PMA Attributes ----------------------------
    .PMA_RSV	                    (32'h00000000),         // 
    .PMA_RSV2	                    (16'h0040),             //
    .PMA_RSV3                       (2'b00),                // 
    .RX_BIAS_CFG	                (12'b000000000000),     //
    .RXLPM_HF_CFG                   (14'h0096),             // 
    .RXLPM_LF_CFG                   (14'h00E0),             // 
    .TERM_RCAL_CFG	                (5'b10000),             // 
    .TERM_RCAL_OVRD	                (1'b1),                 // 

    //---------- PCS Attributes ----------------------------
    .PCS_PCIE_EN                    ("TRUE"),               //  
    .PCS_RSVD_ATTR	                (PCS_RSVD_ATTR),        // [0] : 1 when TX buffer bypass, [1] : 0 = TX auto sync mode, [2] : 0 = RX auto sync mode

    //---------- CDR Attributes ----------------------------
  //.RXCDR_CFG	                    (72'b0000_0000_0100_0111_1111_1110_0100_0000_0110_0000_0000_0001_0000_0010_0000000000010000), 
  //.RXCDR_CFG                      (72'h0207FE4061C1084000),  // Wizard
    .RXCDR_CFG                      (72'b0000_0010_0000_0111_1111_1110_0010_0000_0110_0000_0010_0001_0001_0000_0000000000010000), // XAP
    .RXCDR_LOCK_CFG	                (6'b000111),            // [5:3] wait cycle, [2:1] window size, [0] enable CDR lock
    .RXCDR_HOLD_DURING_EIDLE	    (1'b0),                 //
    .RXCDR_FR_RESET_ON_EIDLE	    (1'b1),                 //
    .RXCDR_PH_RESET_ON_EIDLE	    (1'b1),                 //
    .RXCDRFREQRESET_TIME	        (5'b00001),             // 
    .RXCDRPHRESET_TIME	            (5'b00001),             // 

    //---------- DFE Attributes ----------------------------
    .RXDFELPMRESET_TIME	            (7'b0001111),           // 
    .RX_DFE_GAIN_CFG	            (23'h000000),           //
    .RX_DFE_H2_CFG	                (12'b000000000000),     //
    .RX_DFE_H3_CFG	                (12'b000000000000),     //
    .RX_DFE_H4_CFG	                (11'b00000000000),      //
    .RX_DFE_H5_CFG	                (11'b00000000000),      //
    .RX_DFE_KL_CFG	                (13'b0000000000000),    //
    .RX_DFE_LPM_CFG	                (16'h0000),             //
    .RX_DFE_LPM_HOLD_DURING_EIDLE	(1'b1),                 //
    .RX_DFE_UT_CFG	                (17'd0),                //
    .RX_DFE_VP_CFG	                (17'd0),                //
    .RX_DFE_XYD_CFG	                (13'b0000000010000),    //
    .RX_OS_CFG	                    (13'b0001111110000),    //  
  
    //---------- Eye Scan Attributes -----------------------
    .ES_CONTROL	                    (6'b000000),            //
    .ES_ERRDET_EN	                ("FALSE"),              //
    .ES_EYE_SCAN_EN	                ("FALSE"),              //
    .ES_HORZ_OFFSET	                (12'h010),              //
    .ES_PMA_CFG	                    (10'b0000000000),       //
    .ES_PRESCALE	                (5'b00000),             //
    .ES_QUAL_MASK	                (80'd0),                //
    .ES_QUALIFIER	                (80'd0),                //
    .ES_SDATA_MASK	                (80'd0),                //
    .ES_VERT_OFFSET	                (9'b000000000),         //

    //---------- TX Buffer Attributes ----------------------
    .TXBUF_EN	                    (PCIE_TXBUF_EN),        // 
    .TXBUF_RESET_ON_RATE_CHANGE	    ("TRUE"),               //
    
    //---------- RX Buffer Attributes ----------------------
    .RXBUF_EN	                    ("TRUE"),               //
    .RX_BUFFER_CFG	                (6'b000000),            //
    .RX_DEFER_RESET_BUF_EN          ("TRUE"),               // 
    .RXBUF_ADDR_MODE	            ("FULL"),               //
    .RXBUF_EIDLE_HI_CNT	            (4'd4),                 // Changed from 8 to 4 based on Denali sim
    .RXBUF_EIDLE_LO_CNT	            (4'd0),                 //
    .RXBUF_RESET_ON_CB_CHANGE	    ("TRUE"),               //
    .RXBUF_RESET_ON_COMMAALIGN	    ("FALSE"),              //
    .RXBUF_RESET_ON_EIDLE	        ("TRUE"),               //
    .RXBUF_RESET_ON_RATE_CHANGE	    ("TRUE"),               //
    .RXBUF_THRESH_OVRD	            ("FALSE"),              //
    .RXBUF_THRESH_OVFLW	            (61),                   //
    .RXBUF_THRESH_UNDFLW	        (4),                    //
    .RXBUFRESET_TIME	            (5'b00001),             //

    //---------- TX Sync Attributes ------------------------
    .TXPH_CFG	                    (16'h0780),             // TXPH_CFG[10:7] - step size for phase loop *** (16'h0400)
    .TXPH_MONITOR_SEL	            (5'b00000),             // TXPHDLY_CFG[19] - 1 = full range or 0 for half range
    .TXPHDLY_CFG	                (24'h084020),           // TXPHDLY_CFG[14] - initial position search on rising edge
    .TXDLY_CFG	                    (16'h001F),             // TXDLY_CFG[5:0] - 010000b = 32ps shift or 111111b = 64ps shift
    .TXDLY_LCFG	                    (9'h030),               // TXDLY_LCFG[4:3] : 00b = 2, 01b = 4, 10b = 8, 11b = 16   
    .TXDLY_TAP_CFG	                (16'h0000),             // TXDLY_LCFG[6:5] : 00b = 1, 01b = 2, 10b = 4, 11b =  8
    
    //---------- RX Sync Attributes ------------------------
    .RXPH_CFG	                    (24'h000000),           //
    .RXPH_MONITOR_SEL	            (5'b00000),             //
    .RXPHDLY_CFG	                (24'h004020),           // Use half range
    .RXDLY_CFG	                    (16'h001F),             //
    .RXDLY_LCFG	                    (9'h030),               //
    .RXDLY_TAP_CFG	                (16'h0000),             //
    .RX_DDI_SEL	                    (6'b000000),            //

    //---------- Comma Alignment Attributes ----------------
    .ALIGN_COMMA_DOUBLE             ("FALSE"),              //   
    .ALIGN_COMMA_ENABLE             (10'b1111111111),       // 
    .ALIGN_COMMA_WORD               (1),                    //
    .ALIGN_MCOMMA_DET               ("TRUE"),               //
    .ALIGN_MCOMMA_VALUE             (10'b1010000011),       //
    .ALIGN_PCOMMA_DET               ("TRUE"),               //
    .ALIGN_PCOMMA_VALUE             (10'b0101111100),       //
    .DEC_MCOMMA_DETECT              ("TRUE"),               //
    .DEC_PCOMMA_DETECT              ("TRUE"),               //
    .DEC_VALID_COMMA_ONLY           ("FALSE"),              // 
    .SHOW_REALIGN_COMMA             ("FALSE"),              // Set FALSE to rx reduce latency or when RXSLIDE_MODE = PMA
    .RXSLIDE_AUTO_WAIT              (7),                    // Changed from 5 to 7 based on Design recommendation
    .RXSLIDE_MODE                   ("PMA"),                // 

    //---------- Channel Bonding Attributes ----------------
    .CHAN_BOND_KEEP_ALIGN           ("TRUE"),               // 
    .CHAN_BOND_MAX_SKEW             (7),                    // 
    .CHAN_BOND_SEQ_LEN              (4),                    // 
    .CHAN_BOND_SEQ_1_ENABLE         (4'b1111),              //
    .CHAN_BOND_SEQ_1_1              (10'b0001001010),       // D10.2 (4A) - TS1 
    .CHAN_BOND_SEQ_1_2              (10'b0001001010),       // D10.2 (4A) - TS1
    .CHAN_BOND_SEQ_1_3              (10'b0001001010),       // D10.2 (4A) - TS1
    .CHAN_BOND_SEQ_1_4              (10'b0110111100),       // K28.5 (BC) - COM
    .CHAN_BOND_SEQ_2_USE            ("TRUE"),               // 
    .CHAN_BOND_SEQ_2_ENABLE         (4'b1111),              //
    .CHAN_BOND_SEQ_2_1              (10'b0001000101),       // D5.2  (45) - TS2
    .CHAN_BOND_SEQ_2_2              (10'b0001000101),       // D5.2  (45) - TS2
    .CHAN_BOND_SEQ_2_3              (10'b0001000101),       // D5.2  (45) - TS2
    .CHAN_BOND_SEQ_2_4              (10'b0110111100),       // K28.5 (BC) - COM
    .FTS_DESKEW_SEQ_ENABLE	        (4'b1111),              // 
    .FTS_LANE_DESKEW_EN	            ("TRUE"),               // 
    .FTS_LANE_DESKEW_CFG	        (4'b1111),              // 

    //---------- Clock Correction Attributes ---------------
    .CBCC_DATA_SOURCE_SEL	        ("DECODED"),            //
    .CLK_CORRECT_USE                ("TRUE"),               //
    .CLK_COR_KEEP_IDLE              ("TRUE"),               //
    .CLK_COR_MAX_LAT                (CLK_COR_MAX_LAT),      // 
    .CLK_COR_MIN_LAT                (CLK_COR_MIN_LAT),      // 
    .CLK_COR_PRECEDENCE             ("TRUE"),               // Clock correction higher priority over channel bonding
    .CLK_COR_REPEAT_WAIT            (0),                    // Continuous clock correction
    .CLK_COR_SEQ_LEN                (1),                    //
    .CLK_COR_SEQ_1_ENABLE           (4'b1111),              //
    .CLK_COR_SEQ_1_1                (10'b0100011100),       // K28.0 (1C) - SKP
    .CLK_COR_SEQ_1_2                (10'b0000000000),       //
    .CLK_COR_SEQ_1_3                (10'b0000000000),       //
    .CLK_COR_SEQ_1_4                (10'b0000000000),       //
    .CLK_COR_SEQ_2_ENABLE           (4'b0000),              //
    .CLK_COR_SEQ_2_USE              ("FALSE"),              //
    .CLK_COR_SEQ_2_1                (10'b0000000000),       //
    .CLK_COR_SEQ_2_2                (10'b0000000000),       //
    .CLK_COR_SEQ_2_3                (10'b0000000000),       //
    .CLK_COR_SEQ_2_4                (10'b0000000000),       //

    //---------- 8b10b Attributes --------------------------
    .RX_DISPERR_SEQ_MATCH	        ("TRUE"),               //

    //---------- 64b/66b & 64b/67b Attributes --------------
    .GEARBOX_MODE                   (3'b000),               //
    .TXGEARBOX_EN                   ("FALSE"),              //
    .RXGEARBOX_EN                   ("FALSE"),              //

    //---------- PRBS & Loopback Attributes ----------------
    .RXPRBS_ERR_LOOPBACK            (1'b0),                 //
    .TX_LOOPBACK_DRIVE_HIZ          ("FALSE"),              //
    
    //---------- OOB Attributes ----------------------------
    .RXOOB_CFG                      (7'b0010000),           //
    .SAS_MAX_COM                    (64),                   //
    .SAS_MIN_COM                    (36),                   //
    .SATA_BURST_SEQ_LEN             (4'b1111),              //
    .SATA_BURST_VAL                 (3'b100),               //
    .SATA_CPLL_CFG                  ("VCO_3000MHZ"),        //
    .SATA_EIDLE_VAL                 (3'b100),               //
    .SATA_MAX_BURST                 (8),                    //
    .SATA_MAX_INIT                  (21),                   //
    .SATA_MAX_WAKE                  (7),                    //
    .SATA_MIN_BURST                 (4),                    //
    .SATA_MIN_INIT                  (12),                   //
    .SATA_MIN_WAKE                  (4),                    //  
           
    //------------------------------------------------------
    .DMONITOR_CFG	                (24'h000000),           //
    .RX_CM_SEL	                    (2'b11),                //
    .RX_CM_TRIM	                    (3'b000),               //
    .RX_DEBUG_CFG	                (12'b000010000000),     //
    .TST_RSV                        (32'h00000000),         //
    .TX_QPI_STATUS_EN               (1'b0),                 //
    .UCODEER_CLR                    (1'b0)                  //
            
) 
gtxe2_i 
(
       
    //---------- Clock -------------------------------------
    .GTGREFCLK                      (1'd0),                 //
    .GTREFCLK0                      (GTX_GTREFCLK0),        //
    .GTREFCLK1                      (1'd0),                 //
    .GTNORTHREFCLK0                 (1'd0),                 //
    .GTNORTHREFCLK1                 (1'd0),                 //
    .GTSOUTHREFCLK0                 (1'd0),                 //
    .GTSOUTHREFCLK1                 (1'd0),                 //
    .QPLLCLK                        (GTX_QPLLCLK),          //
    .QPLLREFCLK                     (GTX_QPLLREFCLK),       //
    .TXUSRCLK                       (GTX_TXUSRCLK),         //
    .RXUSRCLK                       (GTX_RXUSRCLK),         //
    .TXUSRCLK2                      (GTX_TXUSRCLK2),        //
    .RXUSRCLK2                      (GTX_RXUSRCLK2),        //
    .TXSYSCLKSEL                    (GTX_TXSYSCLKSEL),      // 
    .RXSYSCLKSEL                    (GTX_RXSYSCLKSEL),      // 
    .TXOUTCLKSEL                    (3'd3),                 //
    .RXOUTCLKSEL                    (3'd2),                 //
    .CPLLREFCLKSEL                  (3'd1),                 //
    .CPLLLOCKDETCLK                 (1'd0),                 //
    .CPLLLOCKEN                     (1'd1),                 // 
    .CLKRSVD                        (4'd0),                 //
    
    .TXOUTCLK                       (GTX_TXOUTCLK),         //
    .RXOUTCLK                       (GTX_RXOUTCLK),         //
    .TXOUTCLKFABRIC                 (),                     //
    .RXOUTCLKFABRIC                 (),                     //
    .TXOUTCLKPCS                    (),                     //
    .RXOUTCLKPCS                    (),                     //
    .CPLLLOCK                       (GTX_CPLLLOCK),         //
    .CPLLREFCLKLOST                 (),                     //
    .CPLLFBCLKLOST                  (),                     //
    .RXCDRLOCK                      (GTX_RXCDRLOCK),        //
    .GTREFCLKMONITOR                (),                     //

    //---------- Reset -------------------------------------
    .CPLLPD                         (GTX_CPLLPD),           // 
    .CPLLRESET                      (GTX_CPLLRESET),        //
    .TXUSERRDY                      (GTX_TXUSERRDY),        //
    .RXUSERRDY                      (GTX_RXUSERRDY),        //
    .CFGRESET                       (1'd0),                 //
    .GTRESETSEL                     (1'd0),                 //
    .RESETOVRD                      (GTX_RESETOVRD),        //
    .GTTXRESET                      (GTX_GTXTXRESET),       //
    .GTRXRESET                      (GTX_GTXRXRESET),       //

    .TXRESETDONE                    (GTX_TXRESETDONE),      //
    .RXRESETDONE                    (GTX_RXRESETDONE),      //

    //---------- TX Data -----------------------------------
    .TXDATA                         ({32'd0, GTX_TXDATA}),  //
    .TXCHARISK                      ({4'd0, GTX_TXDATAK}),  //
    
    .GTXTXP                         (GTX_TXP),              //
    .GTXTXN                         (GTX_TXN),              //

    //---------- RX Data -----------------------------------
    .GTXRXP                         (GTX_RXP),              //
    .GTXRXN                         (GTX_RXN),              //
    
    .RXDATA                         (rxdata),               //
    .RXCHARISK                      (rxdatak),              //
    
    //---------- Command -----------------------------------
    .TXDETECTRX                     (GTX_TXDETECTRX),       //
    .TXPDELECIDLEMODE               (1'd0),                 //
    .RXELECIDLEMODE                 (2'd0),                 //
    .TXELECIDLE                     (GTX_TXELECIDLE),       //
    .TXCHARDISPMODE                 ({7'd0, GTX_TXCOMPLIANCE}),  //
    .TXCHARDISPVAL                  (8'd0),                 //
    .TXPOLARITY                     (1'b0),                 //
    .RXPOLARITY                     (GTX_RXPOLARITY),       //
    .TXPD                           (GTX_TXPOWERDOWN),      //
    .RXPD                           (GTX_RXPOWERDOWN),      //
    .TXRATE                         (GTX_TXRATE),           //
    .RXRATE                         (GTX_RXRATE),           //
     
    //---------- Electrical Command ------------------------
    .TXDEEMPH                       (GTX_TXDEEMPH[0]),      //
    .TXMARGIN                       (GTX_TXMARGIN),         //
    .TXSWING                        (GTX_TXSWING),          //
    .TXINHIBIT                      (1'b0),                 // 
    .TXBUFDIFFCTRL                  (3'b100),               // 
    .TXDIFFCTRL                     (4'b1000),              // 
    .TXPRECURSOR                    (5'h03),                // 
    .TXPRECURSORINV                 (1'b0),                 // 
    .TXMAINCURSOR                   (7'h3F),                // 
    .TXPOSTCURSOR                   (5'h03),                // 
    .TXPOSTCURSORINV                (1'b0),                 // 
    
    //---------- Status ------------------------------------
    .RXVALID                        (GTX_RXVALID),          //
    .PHYSTATUS                      (GTX_PHYSTATUS),        //
    .RXELECIDLE                     (GTX_RXELECIDLE),       // 
    .RXSTATUS                       (GTX_RXSTATUS),         //
    .TXRATEDONE                     (GTX_TXRATEDONE),       //
    .RXRATEDONE                     (GTX_RXRATEDONE),       //
    
    //---------- DRP ---------------------------------------
    .DRPCLK                         (GTX_DRPCLK),           //
    .DRPADDR                        (GTX_DRPADDR),          //
    .DRPEN                          (GTX_DRPEN),            //
    .DRPDI                          (GTX_DRPDI),            //
    .DRPWE                          (GTX_DRPWE),            //
    
    .DRPDO                          (GTX_DRPDO),            //
    .DRPRDY                         (GTX_DRPRDY),           //
 
    //---------- PMA ---------------------------------------
    .TXPMARESET                     (GTX_TXPMARESET),       //
    .RXPMARESET                     (GTX_RXPMARESET),       //
    .RXLPMEN                        (1'd0),                 // 
    .RXLPMHFHOLD                    (1'd0),                 // 
    .RXLPMHFOVRDEN                  (1'd0),                 // 
    .RXLPMLFHOLD                    (1'd0),                 // 
    .RXLPMLFKLOVRDEN                (1'd0),                 // 
    .TXQPIBIASEN                    (1'd0),                 // 
    .TXQPISTRONGPDOWN               (1'd0),                 // 
    .TXQPIWEAKPUP                   (1'd0),                 // 
    .RXQPIEN                        (1'd0),                 // 
    .PMARSVDIN                      (5'd0),                 // 
    .PMARSVDIN2                     (5'd0),                 // 
    .GTRSVD                         (16'd0),                // 
    
    .TXQPISENP                      (),                     // 
    .TXQPISENN                      (),                     // 
    .RXQPISENP                      (),                     // 
    .RXQPISENN                      (),                     // 
    .DMONITOROUT                    (),                     // 
 
    //---------- PCS ---------------------------------------
    .TXPCSRESET                     (GTX_TXPCSRESET),       //
    .RXPCSRESET                     (GTX_RXPCSRESET),       //
    .PCSRSVDIN                      (16'd0),                // [0] : 1 = TXRATE async, [1] : 1 = RXRATE async  
    .PCSRSVDIN2                     (5'd0),                 // 
    
    .PCSRSVDOUT                     (),                     // 
    //---------- CDR ---------------------------------------
    .RXCDRRESET                     (GTX_RXCDRRESET),       //
    .RXCDRRESETRSV                  (1'd0),                 // 
    .RXCDRFREQRESET                 (GTX_RXCDRFREQRESET),   // 
    .RXCDRHOLD                      (1'd0),                 // 
    .RXCDROVRDEN                    (1'd0),                 // 
 
    //---------- DFE ---------------------------------------
    .RXDFELPMRESET                  (GTX_RXDFELPMRESET),    //  
    .RXDFECM1EN                     (1'd0),                 // 
    .RXDFEVSEN                      (1'd0),                 // 
    .RXDFETAP2HOLD                  (1'd0),                 // 
    .RXDFETAP2OVRDEN                (1'd0),                 // 
    .RXDFETAP3HOLD                  (1'd0),                 // 
    .RXDFETAP3OVRDEN                (1'd0),                 // 
    .RXDFETAP4HOLD                  (1'd0),                 // 
    .RXDFETAP4OVRDEN                (1'd0),                 // 
    .RXDFETAP5HOLD                  (1'd0),                 // 
    .RXDFETAP5OVRDEN                (1'd0),                 // 
    .RXDFEAGCHOLD                   (1'd0),                 // 
    .RXDFEAGCOVRDEN                 (1'd0),                 // 
    .RXDFELFHOLD                    (1'd0),                 // 
    .RXDFELFOVRDEN                  (1'd0),                 // 
    .RXDFEUTHOLD                    (1'd0),                 // 
    .RXDFEUTOVRDEN                  (1'd0),                 // 
    .RXDFEVPHOLD                    (1'd0),                 // 
    .RXDFEVPOVRDEN                  (1'd0),                 // 
    .RXDFEXYDEN                     (1'd0),                 // 
    .RXDFEXYDHOLD                   (1'd0),                 // 
    .RXDFEXYDOVRDEN                 (1'd0),                 // 
    .RXOSHOLD                       (1'd0),                 // 
    .RXOSOVRDEN                     (1'd0),                 // 
    .RXMONITORSEL	                (2'd0),                 //

    .RXMONITOROUT                   (),                     // 
    
    //---------- Eye Scan ----------------------------------
    .EYESCANRESET                   (GTX_EYESCANRESET),     // 
    .EYESCANMODE                    (1'd0),                 // 
    .EYESCANTRIGGER                 (1'd0),                 // 
    
    .EYESCANDATAERROR               (),                     // 
 
    //---------- TX Buffer ---------------------------------
    .TXBUFSTATUS                    (),                     //
    
    //---------- RX Buffer ---------------------------------
    .RXBUFRESET                     (GTX_RXBUFRESET),       //
    
    .RXBUFSTATUS                    (),                     //
   
    //---------- TX Sync -----------------------------------
    .TXPHDLYRESET                   (1'd0),                 //
    .TXPHDLYTSTCLK					(1'd0), 				//
    .TXPHALIGN                      (GTX_TXPHALIGN),        // Used for manual mode 
    .TXPHALIGNEN                    (GTX_TXPHALIGNEN),      // Used for manual mode 
    .TXPHDLYPD                      (1'd0),                 // 
    .TXPHINIT                       (GTX_TXPHINIT),         // Used for manual mode 
    .TXPHOVRDEN                     (1'd0),                 //
    .TXDLYSRESET                    (GTX_TXDLYSRESET),      // Used for auto mode
    .TXDLYBYPASS                    (1'd0),                 //  
    .TXDLYEN                        (GTX_TXDLYEN),          // Used for manual mode 
    .TXDLYOVRDEN                    (1'd0),                 //
    .TXDLYHOLD                      (1'd0),                 // 
    .TXDLYUPDOWN                    (1'd0),                 //
    
    .TXPHALIGNDONE                  (GTX_TXPHALIGNDONE),    // Used for auto mode
    .TXPHINITDONE                   (GTX_TXPHINITDONE),     // Used for manual mode
    .TXDLYSRESETDONE                (GTX_TXDLYSRESETDONE),  // Used for auto mode
    
    //---------- RX Sync -----------------------------------  
    .RXPHDLYRESET                   (1'd0),                 //
    .RXPHALIGN                      (1'd0),                 //
    .RXPHALIGNEN                    (1'd0),                 //
    .RXPHDLYPD                      (1'd0),                 // 
    .RXPHOVRDEN                     (1'd0),                 // 
    .RXDLYSRESET                    (GTX_RXDLYSRESET),      // 
    .RXDLYBYPASS                    (1'd0),                 //  
    .RXDLYEN                        (1'd0),                 // 
    .RXDLYOVRDEN                    (1'd0),                 //
    .RXDDIEN                        (1'd1),                 // Set 1 to use RX Sync 
    
    .RXPHALIGNDONE                  (GTX_RXPHALIGNDONE),    //  
    .RXPHMONITOR                    (),                     //
    .RXPHSLIPMONITOR                (),                     // 
    .RXDLYSRESETDONE                (GTX_RXDLYSRESETDONE),  // 
     
    //---------- Comma Alignment --------------------------- 
    .RXCOMMADETEN                   (1'd1),                 //
    .RXMCOMMAALIGNEN                (!GTX_GEN3),            // 0 = bypass comma alignment in Gen3
    .RXPCOMMAALIGNEN                (!GTX_GEN3),            // 0 = bypass comma alignment in Gen3
    .RXSLIDE                        (GTX_RXSLIDE),          //
     
    .RXCOMMADET                     (),                     //
    .RXCHARISCOMMA                  (),                     // 
    .RXBYTEISALIGNED                (),                     //
    .RXBYTEREALIGN                  (),                     //
     
    //---------- Channel Bonding ---------------------------
    .RXCHBONDEN                     (GTX_RXCHBONDEN),       //
    .RXCHBONDI                      (GTX_RXCHBONDI),        //
    .RXCHBONDLEVEL                  (GTX_RXCHBONDLEVEL),    //
    .RXCHBONDMASTER                 (GTX_RXCHBONDMASTER),   //
    .RXCHBONDSLAVE                  (GTX_RXCHBONDSLAVE),    //

    .RXCHANBONDSEQ                  (),                     //
    .RXCHANISALIGNED                (GTX_RXCHANISALIGNED),  //
    .RXCHANREALIGN                  (),                     //
    .RXCHBONDO                      (GTX_RXCHBONDO),        //
     
    //---------- Clock Correction  -------------------------
    .RXCLKCORCNT                    (),                     //
     
    //---------- 8b10b -------------------------------------
    .TX8B10BBYPASS                  (8'd0),                 //
    .TX8B10BEN                      (!GTX_GEN3),            // 0 = bypass TX 8b10b in Gen3
    .RX8B10BEN                      (!GTX_GEN3),            // 0 = bypass RX 8b10b in Gen3
    
    .RXDISPERR                      (),                     //
    .RXNOTINTABLE                   (),                     //

    //---------- 64b/66b & 64b/67b -----------------------
    .TXHEADER                       (3'd0),                 //
    .TXSEQUENCE                     (7'd0),                 //
    .TXSTARTSEQ                     (1'b0),                 //
    
    .RXGEARBOXSLIP                  (1'b0),                 //
    
    .TXGEARBOXREADY                 (),                     // 
    .RXDATAVALID                    (),                     //
    .RXHEADER                       (),                     //
    .RXHEADERVALID                  (),                     //
    .RXSTARTOFSEQ                   (),                     //
    
    //---------- PRBS & Loopback ---------------------------
    .TXPRBSSEL                      (3'd0),                 //
    .RXPRBSSEL                      (3'd0),                 //
    .TXPRBSFORCEERR                 (1'b0),                 //
    .RXPRBSCNTRESET                 (1'b0),                 // 
    .LOOPBACK                       (3'd0),                 // 
    
    .RXPRBSERR                      ( ),                    //
     
    //---------- OOB ---------------------------------------
    .TXCOMINIT                      (1'b0),                 //
    .TXCOMSAS                       (1'b0),                 //
    .TXCOMWAKE                      (1'b0),                 //
    .RXOOBRESET                     (1'd0),                 // 

    .TXCOMFINISH                    (),                     //
    .RXCOMINITDET                   (),                     //
    .RXCOMSASDET                    (),                     //
    .RXCOMWAKEDET                   (),                     //

    //---------- New ---------------------------------------
    .SETERRSTATUS                   (1'd0),                 // 
    .TXDIFFPD                       (1'd0),                 // 
    .TXPISOPD                       (1'd0),                 // 
    .TSTIN                          (20'hFFFFF),            //  
    
    .TSTOUT                         ()                      //

);
    
    
    
//---------- GTX Wrapper Output ------------------------------------------------
assign GTX_RXDATA  = rxdata[31:0];
assign GTX_RXDATAK = rxdatak[3:0];
 


endmodule
