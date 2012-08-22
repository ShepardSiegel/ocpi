//-----------------------------------------------------------------------------
// Title      : Verilog instantiation template
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : v6_emac_v1_5.veo
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
// Description: Verilog instantiation template for the Virtex-6 Embedded
//              Tri-Mode Ethernet MAC Wrapper (block-level wrapper).
//-----------------------------------------------------------------------------


// The following must be inserted into your Verilog file for this core to
// be instantiated. Change the port connections to your own signal names.

    //------------------------------------------------------------------------
    // Instantiate the block-level wrapper (v6_emac_v1_5_block.v)
    //------------------------------------------------------------------------
    v6_emac_v1_5_block v6_emac_v1_5_block_inst
    (
    // TX clock output
    .TX_CLK_OUT               (TX_CLK_OUT),
    // TX clock input from BUFG
    .TX_CLK                   (TX_CLK),

    // Client receiver interface
    .EMACCLIENTRXD            (EMACCLIENTRXD),
    .EMACCLIENTRXDVLD         (EMACCLIENTRXDVLD),
    .EMACCLIENTRXGOODFRAME    (EMACCLIENTRXGOODFRAME),
    .EMACCLIENTRXBADFRAME     (EMACCLIENTRXBADFRAME),
    .EMACCLIENTRXFRAMEDROP    (EMACCLIENTRXFRAMEDROP),
    .EMACCLIENTRXSTATS        (EMACCLIENTRXSTATS),
    .EMACCLIENTRXSTATSVLD     (EMACCLIENTRXSTATSVLD),
    .EMACCLIENTRXSTATSBYTEVLD (EMACCLIENTRXSTATSBYTEVLD),

    // Client transmitter interface
    .CLIENTEMACTXD            (CLIENTEMACTXD),
    .CLIENTEMACTXDVLD         (CLIENTEMACTXDVLD),
    .EMACCLIENTTXACK          (EMACCLIENTTXACK),
    .CLIENTEMACTXFIRSTBYTE    (CLIENTEMACTXFIRSTBYTE),
    .CLIENTEMACTXUNDERRUN     (CLIENTEMACTXUNDERRUN),
    .EMACCLIENTTXCOLLISION    (EMACCLIENTTXCOLLISION),
    .EMACCLIENTTXRETRANSMIT   (EMACCLIENTTXRETRANSMIT),
    .CLIENTEMACTXIFGDELAY     (CLIENTEMACTXIFGDELAY),
    .EMACCLIENTTXSTATS        (EMACCLIENTTXSTATS),
    .EMACCLIENTTXSTATSVLD     (EMACCLIENTTXSTATSVLD),
    .EMACCLIENTTXSTATSBYTEVLD (EMACCLIENTTXSTATSBYTEVLD),

    // MAC control interface
    .CLIENTEMACPAUSEREQ       (CLIENTEMACPAUSEREQ),
    .CLIENTEMACPAUSEVAL       (CLIENTEMACPAUSEVAL),

    // Receive-side PHY clock on regional buffer, to EMAC
    .PHY_RX_CLK               (PHY_RX_CLK),

    // Clock signal
    .GTX_CLK                  (GTX_CLK),

    // GMII interface
    .GMII_TXD                 (GMII_TXD),
    .GMII_TX_EN               (GMII_TX_EN),
    .GMII_TX_ER               (GMII_TX_ER),
    .GMII_TX_CLK              (GMII_TX_CLK),
    .GMII_RXD                 (GMII_RXD),
    .GMII_RX_DV               (GMII_RX_DV),
    .GMII_RX_ER               (GMII_RX_ER),
    .GMII_RX_CLK              (GMII_RX_CLK),

    // Asynchronous reset input
    .RESET                    (RESET)
    );
