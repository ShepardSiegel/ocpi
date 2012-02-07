//-----------------------------------------------------------------------------
// Title      : Block-level Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : v6_emac_v1_5_block.v
// Version    : 1.5
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
// Description:  This is the block-level wrapper for the Virtex-6 Embedded
//               Tri-Mode Ethernet MAC. It is intended that this example design
//               can be quickly adapted and downloaded onto an FPGA to provide
//               a hardware test environment.
//
//               The block-level wrapper:
//
//               * instantiates appropriate PHY interface modules (GMII, MII,
//                 RGMII, SGMII or 1000BASE-X) as required per the user
//                 configuration;
//
//               * instantiates some clocking and reset resources to operate
//                 the EMAC and its example design.
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
//               further information.
//-----------------------------------------------------------------------------

`timescale 1 ps / 1 ps


//-----------------------------------------------------------------------------
// Module declaration for the block-level wrapper
//-----------------------------------------------------------------------------

module v6_emac_v1_5_block
(

    // TX clock output
    TX_CLK_OUT,
    // TX clock input from BUFG
    TX_CLK,

    // Client receiver interface
    EMACCLIENTRXD,
    EMACCLIENTRXDVLD,
    EMACCLIENTRXGOODFRAME,
    EMACCLIENTRXBADFRAME,
    EMACCLIENTRXFRAMEDROP,
    EMACCLIENTRXSTATS,
    EMACCLIENTRXSTATSVLD,
    EMACCLIENTRXSTATSBYTEVLD,

    // Client transmitter interface
    CLIENTEMACTXD,
    CLIENTEMACTXDVLD,
    EMACCLIENTTXACK,
    CLIENTEMACTXFIRSTBYTE,
    CLIENTEMACTXUNDERRUN,
    EMACCLIENTTXCOLLISION,
    EMACCLIENTTXRETRANSMIT,
    CLIENTEMACTXIFGDELAY,
    EMACCLIENTTXSTATS,
    EMACCLIENTTXSTATSVLD,
    EMACCLIENTTXSTATSBYTEVLD,

    // MAC control interface
    CLIENTEMACPAUSEREQ,
    CLIENTEMACPAUSEVAL,

    // Receive-side PHY clock on regional buffer, to EMAC
    PHY_RX_CLK,

    // Clock signal
    GTX_CLK,

    // GMII interface
    GMII_TXD,
    GMII_TX_EN,
    GMII_TX_ER,
    GMII_TX_CLK,
    GMII_RXD,
    GMII_RX_DV,
    GMII_RX_ER,
    GMII_RX_CLK,

    // Asynchronous reset
    RESET
);


//-----------------------------------------------------------------------------
// Port declarations
//-----------------------------------------------------------------------------

    // TX clock output
    output          TX_CLK_OUT;
    // TX clock input from BUFG
    input           TX_CLK;

    // Client receiver interface
    output   [7:0]  EMACCLIENTRXD;
    output          EMACCLIENTRXDVLD;
    output          EMACCLIENTRXGOODFRAME;
    output          EMACCLIENTRXBADFRAME;
    output          EMACCLIENTRXFRAMEDROP;
    output   [6:0]  EMACCLIENTRXSTATS;
    output          EMACCLIENTRXSTATSVLD;
    output          EMACCLIENTRXSTATSBYTEVLD;

    // Client transmitter interface
    input    [7:0]  CLIENTEMACTXD;
    input           CLIENTEMACTXDVLD;
    output          EMACCLIENTTXACK;
    input           CLIENTEMACTXFIRSTBYTE;
    input           CLIENTEMACTXUNDERRUN;
    output          EMACCLIENTTXCOLLISION;
    output          EMACCLIENTTXRETRANSMIT;
    input    [7:0]  CLIENTEMACTXIFGDELAY;
    output          EMACCLIENTTXSTATS;
    output          EMACCLIENTTXSTATSVLD;
    output          EMACCLIENTTXSTATSBYTEVLD;

    // MAC control interface
    input           CLIENTEMACPAUSEREQ;
    input   [15:0]  CLIENTEMACPAUSEVAL;

    // Receive-side PHY clock on regional buffer, to EMAC
    input           PHY_RX_CLK;

    // Clock signal
    input           GTX_CLK;

    // GMII interface
    output   [7:0]  GMII_TXD;
    output          GMII_TX_EN;
    output          GMII_TX_ER;
    output          GMII_TX_CLK;
    input    [7:0]  GMII_RXD;
    input           GMII_RX_DV;
    input           GMII_RX_ER;
    input           GMII_RX_CLK;

    // Asynchronous reset
    input           RESET;


//-----------------------------------------------------------------------------
// Wire and register declarations
//-----------------------------------------------------------------------------

    // Asynchronous reset signals
    wire            reset_ibuf_i;
    wire            reset_i;

    // Client clocking signals
    wire            rx_client_clk_out_i;
    wire            rx_client_clk_in_i;
    wire            tx_client_clk_out_i;
    wire            tx_client_clk_in_i;
    wire            tx_gmii_mii_clk_out_i;
    wire            tx_gmii_mii_clk_in_i;

    // Physical interface signals
    wire            gmii_tx_en_i;
    wire            gmii_tx_er_i;
    wire     [7:0]  gmii_txd_i;
    wire            gmii_rx_dv_r;
    wire            gmii_rx_er_r;
    wire     [7:0]  gmii_rxd_r;
    wire            gmii_rx_clk_i;

    // 125MHz reference clock
    wire            gtx_clk_ibufg_i;

//-----------------------------------------------------------------------------
// Main body of code
//-----------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Main reset circuitry
    //-------------------------------------------------------------------------

    assign reset_ibuf_i = RESET;
    assign reset_i = reset_ibuf_i;

    //-------------------------------------------------------------------------
    // GMII circuitry for the physical interface
    //-------------------------------------------------------------------------

    gmii_if gmii (
        .RESET          (reset_i),
        .GMII_TXD       (GMII_TXD),
        .GMII_TX_EN     (GMII_TX_EN),
        .GMII_TX_ER     (GMII_TX_ER),
        .GMII_TX_CLK    (GMII_TX_CLK),
        .GMII_RXD       (GMII_RXD),
        .GMII_RX_DV     (GMII_RX_DV),
        .GMII_RX_ER     (GMII_RX_ER),
        .TXD_FROM_MAC   (gmii_txd_i),
        .TX_EN_FROM_MAC (gmii_tx_en_i),
        .TX_ER_FROM_MAC (gmii_tx_er_i),
        .TX_CLK         (tx_gmii_mii_clk_in_i),
        .RXD_TO_MAC     (gmii_rxd_r),
        .RX_DV_TO_MAC   (gmii_rx_dv_r),
        .RX_ER_TO_MAC   (gmii_rx_er_r),
        .RX_CLK         (GMII_RX_CLK)
    );

    // GTX reference clock
    assign gtx_clk_ibufg_i = GTX_CLK;

    // GMII PHY-side transmit clock
    assign tx_gmii_mii_clk_in_i = TX_CLK;

    // GMII PHY-side receive clock, regionally-buffered
    assign gmii_rx_clk_i = PHY_RX_CLK;

    // GMII client-side transmit clock
    assign tx_client_clk_in_i = TX_CLK;

    // GMII client-side receive clock
    assign rx_client_clk_in_i = gmii_rx_clk_i;

    // TX clock output
    assign TX_CLK_OUT = tx_gmii_mii_clk_out_i;

    //------------------------------------------------------------------------
    // Instantiate the primitive-level EMAC wrapper (v6_emac_v1_5.v)
    //------------------------------------------------------------------------

    v6_emac_v1_5 v6_emac_v1_5_inst
    (
        // Client receiver interface
        .EMACCLIENTRXCLIENTCLKOUT    (rx_client_clk_out_i),
        .CLIENTEMACRXCLIENTCLKIN     (rx_client_clk_in_i),
        .EMACCLIENTRXD               (EMACCLIENTRXD),
        .EMACCLIENTRXDVLD            (EMACCLIENTRXDVLD),
        .EMACCLIENTRXDVLDMSW         (),
        .EMACCLIENTRXGOODFRAME       (EMACCLIENTRXGOODFRAME),
        .EMACCLIENTRXBADFRAME        (EMACCLIENTRXBADFRAME),
        .EMACCLIENTRXFRAMEDROP       (EMACCLIENTRXFRAMEDROP),
        .EMACCLIENTRXSTATS           (EMACCLIENTRXSTATS),
        .EMACCLIENTRXSTATSVLD        (EMACCLIENTRXSTATSVLD),
        .EMACCLIENTRXSTATSBYTEVLD    (EMACCLIENTRXSTATSBYTEVLD),

        // Client transmitter interface
        .EMACCLIENTTXCLIENTCLKOUT    (tx_client_clk_out_i),
        .CLIENTEMACTXCLIENTCLKIN     (tx_client_clk_in_i),
        .CLIENTEMACTXD               (CLIENTEMACTXD),
        .CLIENTEMACTXDVLD            (CLIENTEMACTXDVLD),
        .CLIENTEMACTXDVLDMSW         (1'b0),
        .EMACCLIENTTXACK             (EMACCLIENTTXACK),
        .CLIENTEMACTXFIRSTBYTE       (CLIENTEMACTXFIRSTBYTE),
        .CLIENTEMACTXUNDERRUN        (CLIENTEMACTXUNDERRUN),
        .EMACCLIENTTXCOLLISION       (EMACCLIENTTXCOLLISION),
        .EMACCLIENTTXRETRANSMIT      (EMACCLIENTTXRETRANSMIT),
        .CLIENTEMACTXIFGDELAY        (CLIENTEMACTXIFGDELAY),
        .EMACCLIENTTXSTATS           (EMACCLIENTTXSTATS),
        .EMACCLIENTTXSTATSVLD        (EMACCLIENTTXSTATSVLD),
        .EMACCLIENTTXSTATSBYTEVLD    (EMACCLIENTTXSTATSBYTEVLD),

        // MAC control interface
        .CLIENTEMACPAUSEREQ          (CLIENTEMACPAUSEREQ),
        .CLIENTEMACPAUSEVAL          (CLIENTEMACPAUSEVAL),

        // Clock signals
        .GTX_CLK                     (gtx_clk_ibufg_i),
        .EMACPHYTXGMIIMIICLKOUT      (tx_gmii_mii_clk_out_i),
        .PHYEMACTXGMIIMIICLKIN       (tx_gmii_mii_clk_in_i),

        // GMII interface
        .GMII_TXD                    (gmii_txd_i),
        .GMII_TX_EN                  (gmii_tx_en_i),
        .GMII_TX_ER                  (gmii_tx_er_i),
        .GMII_RXD                    (gmii_rxd_r),
        .GMII_RX_DV                  (gmii_rx_dv_r),
        .GMII_RX_ER                  (gmii_rx_er_r),
        .GMII_RX_CLK                 (gmii_rx_clk_i),

         // MMCM lock indicator
        .MMCM_LOCKED                 (1'b1),

        // Asynchronous reset
        .RESET                       (reset_i)
    );


endmodule
