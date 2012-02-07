//-----------------------------------------------------------------------------
// Title      : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : v6_emac_v1_5.v
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
//------------------------------------------------------------------------------
// Description:  This wrapper file instantiates the full Virtex-6 Embedded
//               Tri-Mode Ethernet MAC (EMAC) primitive, where:
//
//               * all unused input ports on the primitive are tied to the
//                 appropriate logic level;
//
//               * all unused output ports on the primitive are left
//                 unconnected;
//
//               * the attributes are set based on the options selected
//                 from CORE Generator;
//
//               * only used ports are connected to the ports of this
//                 wrapper file.
//
//               This simplified wrapper should therefore be used as the
//               instantiation template for the EMAC primitive in customer
//               designs.
//------------------------------------------------------------------------------

`timescale 1 ps / 1 ps


//------------------------------------------------------------------------------
// Module declaration for the primitive-level wrapper
//------------------------------------------------------------------------------

(* X_CORE_INFO = "v6_emac_v1_5, Coregen 13.1" *)
(* CORE_GENERATION_INFO = "v6_emac_v1_5,v6_emac_v1_5,{c_has_mii=false,c_has_gmii=true,c_has_rgmii_v1_3=false,c_has_rgmii_v2_0=false,c_has_sgmii=false,c_has_gpcs=false,c_tri_speed=false,c_speed_10=false,c_speed_100=false,c_speed_1000=true,c_has_host=false,c_has_dcr=false,c_has_mdio=false,c_client_16=false,c_add_filter=false,c_has_clock_enable=false,c_serial_mode_switch_en=false,c_overclocking_rate_2000mbps=false,c_overclocking_rate_2500mbps=false,}" *)
module v6_emac_v1_5
(

    // Client Receiver Interface
    EMACCLIENTRXCLIENTCLKOUT,
    CLIENTEMACRXCLIENTCLKIN,
    EMACCLIENTRXD,
    EMACCLIENTRXDVLD,
    EMACCLIENTRXDVLDMSW,
    EMACCLIENTRXGOODFRAME,
    EMACCLIENTRXBADFRAME,
    EMACCLIENTRXFRAMEDROP,
    EMACCLIENTRXSTATS,
    EMACCLIENTRXSTATSVLD,
    EMACCLIENTRXSTATSBYTEVLD,

    // Client Transmitter Interface
    EMACCLIENTTXCLIENTCLKOUT,
    CLIENTEMACTXCLIENTCLKIN,
    CLIENTEMACTXD,
    CLIENTEMACTXDVLD,
    CLIENTEMACTXDVLDMSW,
    EMACCLIENTTXACK,
    CLIENTEMACTXFIRSTBYTE,
    CLIENTEMACTXUNDERRUN,
    EMACCLIENTTXCOLLISION,
    EMACCLIENTTXRETRANSMIT,
    CLIENTEMACTXIFGDELAY,
    EMACCLIENTTXSTATS,
    EMACCLIENTTXSTATSVLD,
    EMACCLIENTTXSTATSBYTEVLD,

    // MAC Control Interface
    CLIENTEMACPAUSEREQ,
    CLIENTEMACPAUSEVAL,

    // Clock Signals
    GTX_CLK,
    PHYEMACTXGMIIMIICLKIN,
    EMACPHYTXGMIIMIICLKOUT,

    // GMII Interface
    GMII_TXD,
    GMII_TX_EN,
    GMII_TX_ER,
    GMII_RXD,
    GMII_RX_DV,
    GMII_RX_ER,
    GMII_RX_CLK,

    // MMCM Lock Indicator
    MMCM_LOCKED,

    // Asynchronous Reset
    RESET
);


    //--------------------------------------------------------------------------
    // Port declarations
    //--------------------------------------------------------------------------

    // Client Receiver Interface
    output          EMACCLIENTRXCLIENTCLKOUT;
    input           CLIENTEMACRXCLIENTCLKIN;
    output   [7:0]  EMACCLIENTRXD;
    output          EMACCLIENTRXDVLD;
    output          EMACCLIENTRXDVLDMSW;
    output          EMACCLIENTRXGOODFRAME;
    output          EMACCLIENTRXBADFRAME;
    output          EMACCLIENTRXFRAMEDROP;
    output   [6:0]  EMACCLIENTRXSTATS;
    output          EMACCLIENTRXSTATSVLD;
    output          EMACCLIENTRXSTATSBYTEVLD;

    // Client Transmitter Interface
    output          EMACCLIENTTXCLIENTCLKOUT;
    input           CLIENTEMACTXCLIENTCLKIN;
    input    [7:0]  CLIENTEMACTXD;
    input           CLIENTEMACTXDVLD;
    input           CLIENTEMACTXDVLDMSW;
    output          EMACCLIENTTXACK;
    input           CLIENTEMACTXFIRSTBYTE;
    input           CLIENTEMACTXUNDERRUN;
    output          EMACCLIENTTXCOLLISION;
    output          EMACCLIENTTXRETRANSMIT;
    input    [7:0]  CLIENTEMACTXIFGDELAY;
    output          EMACCLIENTTXSTATS;
    output          EMACCLIENTTXSTATSVLD;
    output          EMACCLIENTTXSTATSBYTEVLD;

    // MAC Control Interface
    input           CLIENTEMACPAUSEREQ;
    input   [15:0]  CLIENTEMACPAUSEVAL;

    // Clock Signals
    input           GTX_CLK;
    output          EMACPHYTXGMIIMIICLKOUT;
    input           PHYEMACTXGMIIMIICLKIN;

    // GMII Interface
    output   [7:0]  GMII_TXD;
    output          GMII_TX_EN;
    output          GMII_TX_ER;
    input    [7:0]  GMII_RXD;
    input           GMII_RX_DV;
    input           GMII_RX_ER;
    input           GMII_RX_CLK;

    // MMCM Lock Indicator
    input           MMCM_LOCKED;

    // Asynchronous Reset
    input           RESET;


    //--------------------------------------------------------------------------
    // Wire declarations
    //--------------------------------------------------------------------------

    wire    [15:0]  client_rx_data_i;
    wire    [15:0]  client_tx_data_i;

    //--------------------------------------------------------------------------
    // Main body of code
    //--------------------------------------------------------------------------

    // Use the 8-bit client data interface
    assign EMACCLIENTRXD = client_rx_data_i[7:0];
    assign #4000 client_tx_data_i = {8'b00000000, CLIENTEMACTXD};

    // Instantiate the Virtex-6 Embedded Tri-Mode Ethernet MAC
    TEMAC_SINGLE #(
    // PCS/PMA logic is not in use
       .EMAC_PHYINITAUTONEG_ENABLE         ("FALSE"),
       .EMAC_PHYISOLATE                    ("FALSE"),
       .EMAC_PHYLOOPBACKMSB                ("FALSE"),
       .EMAC_PHYPOWERDOWN                  ("FALSE"),
       .EMAC_PHYRESET                      ("TRUE"),
       .EMAC_GTLOOPBACK                    ("FALSE"),
       .EMAC_UNIDIRECTION_ENABLE           ("FALSE"),
       .EMAC_LINKTIMERVAL                  (9'h000),
       .EMAC_MDIO_IGNORE_PHYADZERO         ("FALSE"),
    // Configure the EMAC operating mode
    // MDIO is not enabled
       .EMAC_MDIO_ENABLE                   ("FALSE"),
    // Speed is defaulted to 1000 Mb/s
       .EMAC_SPEED_LSB                     ("FALSE"),
       .EMAC_SPEED_MSB                     ("TRUE"),
    // Clock Enable advanced clocking is not in use
       .EMAC_USECLKEN                      ("FALSE"),
    // Byte PHY advanced clocking is not supported. Do not modify.
       .EMAC_BYTEPHY                       ("FALSE"),
    // RGMII physical interface is not in use
       .EMAC_RGMII_ENABLE                  ("FALSE"),
    // SGMII physical interface is not in use
       .EMAC_SGMII_ENABLE                  ("FALSE"),
       .EMAC_1000BASEX_ENABLE              ("FALSE"),
    // The host interface is not enabled
       .EMAC_HOST_ENABLE                   ("FALSE"),
    // The Tx-side 8-bit client data interface is used
       .EMAC_TX16BITCLIENT_ENABLE          ("FALSE"),
    // The Rx-side 8-bit client data interface is used
       .EMAC_RX16BITCLIENT_ENABLE          ("FALSE"),
    // The address filter is not enabled
       .EMAC_ADDRFILTER_ENABLE             ("FALSE"),

    // EMAC configuration defaults
    // Rx Length/Type checking is enabled
       .EMAC_LTCHECK_DISABLE               ("FALSE"),
    // Rx control frame length checking is enabled
       .EMAC_CTRLLENCHECK_DISABLE          ("FALSE"),
    // Rx flow control is not enabled
       .EMAC_RXFLOWCTRL_ENABLE             ("FALSE"),
    // Tx flow control is not enabled
       .EMAC_TXFLOWCTRL_ENABLE             ("FALSE"),
    // Transmitter is not held in reset
       .EMAC_TXRESET                       ("FALSE"),
    // Transmitter Jumbo frames are not enabled
       .EMAC_TXJUMBOFRAME_ENABLE           ("FALSE"),
    // Transmitter in-band FCS is not enabled
       .EMAC_TXINBANDFCS_ENABLE            ("FALSE"),
    // Transmitter is enabled
       .EMAC_TX_ENABLE                     ("TRUE"),
    // Transmitter VLAN frames are not enabled
       .EMAC_TXVLAN_ENABLE                 ("FALSE"),
    // Transmitter full-duplex mode is enabled
       .EMAC_TXHALFDUPLEX                  ("FALSE"),
    // Transmitter IFG Adjust is not enabled
       .EMAC_TXIFGADJUST_ENABLE            ("FALSE"),
    // Receiver is not held in reset
       .EMAC_RXRESET                       ("FALSE"),
    // Receiver Jumbo frames are not enabled
       .EMAC_RXJUMBOFRAME_ENABLE           ("FALSE"),
    // Receiver in-band FCS is not enabled
       .EMAC_RXINBANDFCS_ENABLE            ("FALSE"),
    // Receiver is enabled
       .EMAC_RX_ENABLE                     ("TRUE"),
    // Receiver VLAN frames are not enabled
       .EMAC_RXVLAN_ENABLE                 ("FALSE"),
    // Receiver full-duplex mode is enabled
       .EMAC_RXHALFDUPLEX                  ("FALSE"),

    // Configure the EMAC addressing
    // Set the PAUSE address default
       .EMAC_PAUSEADDR                     (48'hFFEEDDCCBBAA),
    // Do not set the unicast address (address filter is unused)
       .EMAC_UNICASTADDR                   (48'h000000000000),
    // Do not set the DCR base address (DCR is unused)
       .EMAC_DCRBASEADDR                   (8'h00)
    )
    v6_emac
    (
        .RESET                    (RESET),

        .EMACCLIENTRXCLIENTCLKOUT (EMACCLIENTRXCLIENTCLKOUT),
        .CLIENTEMACRXCLIENTCLKIN  (CLIENTEMACRXCLIENTCLKIN),
        .EMACCLIENTRXD            (client_rx_data_i),
        .EMACCLIENTRXDVLD         (EMACCLIENTRXDVLD),
        .EMACCLIENTRXDVLDMSW      (EMACCLIENTRXDVLDMSW),
        .EMACCLIENTRXGOODFRAME    (EMACCLIENTRXGOODFRAME),
        .EMACCLIENTRXBADFRAME     (EMACCLIENTRXBADFRAME),
        .EMACCLIENTRXFRAMEDROP    (EMACCLIENTRXFRAMEDROP),
        .EMACCLIENTRXSTATS        (EMACCLIENTRXSTATS),
        .EMACCLIENTRXSTATSVLD     (EMACCLIENTRXSTATSVLD),
        .EMACCLIENTRXSTATSBYTEVLD (EMACCLIENTRXSTATSBYTEVLD),

        .EMACCLIENTTXCLIENTCLKOUT (EMACCLIENTTXCLIENTCLKOUT),
        .CLIENTEMACTXCLIENTCLKIN  (CLIENTEMACTXCLIENTCLKIN),
        .CLIENTEMACTXD            (client_tx_data_i),
        .CLIENTEMACTXDVLD         (CLIENTEMACTXDVLD),
        .CLIENTEMACTXDVLDMSW      (CLIENTEMACTXDVLDMSW),
        .EMACCLIENTTXACK          (EMACCLIENTTXACK),
        .CLIENTEMACTXFIRSTBYTE    (CLIENTEMACTXFIRSTBYTE),
        .CLIENTEMACTXUNDERRUN     (CLIENTEMACTXUNDERRUN),
        .EMACCLIENTTXCOLLISION    (EMACCLIENTTXCOLLISION),
        .EMACCLIENTTXRETRANSMIT   (EMACCLIENTTXRETRANSMIT),
        .CLIENTEMACTXIFGDELAY     (CLIENTEMACTXIFGDELAY),
        .EMACCLIENTTXSTATS        (EMACCLIENTTXSTATS),
        .EMACCLIENTTXSTATSVLD     (EMACCLIENTTXSTATSVLD),
        .EMACCLIENTTXSTATSBYTEVLD (EMACCLIENTTXSTATSBYTEVLD),

        .CLIENTEMACPAUSEREQ       (CLIENTEMACPAUSEREQ),
        .CLIENTEMACPAUSEVAL       (CLIENTEMACPAUSEVAL),

        .PHYEMACGTXCLK            (GTX_CLK),
        .EMACPHYTXGMIIMIICLKOUT   (EMACPHYTXGMIIMIICLKOUT),
        .PHYEMACTXGMIIMIICLKIN    (PHYEMACTXGMIIMIICLKIN),

        .PHYEMACRXCLK             (GMII_RX_CLK),
        .PHYEMACRXD               (GMII_RXD),
        .PHYEMACRXDV              (GMII_RX_DV),
        .PHYEMACRXER              (GMII_RX_ER),
        .EMACPHYTXCLK             (),
        .EMACPHYTXD               (GMII_TXD),
        .EMACPHYTXEN              (GMII_TX_EN),
        .EMACPHYTXER              (GMII_TX_ER),
        .PHYEMACMIITXCLK          (1'b0),
        .PHYEMACCOL               (1'b0),
        .PHYEMACCRS               (1'b0),

        .CLIENTEMACDCMLOCKED      (MMCM_LOCKED),
        .EMACCLIENTANINTERRUPT    (),
        .PHYEMACSIGNALDET         (1'b0),
        .PHYEMACPHYAD             (5'b00000),
        .EMACPHYENCOMMAALIGN      (),
        .EMACPHYLOOPBACKMSB       (),
        .EMACPHYMGTRXRESET        (),
        .EMACPHYMGTTXRESET        (),
        .EMACPHYPOWERDOWN         (),
        .EMACPHYSYNCACQSTATUS     (),
        .PHYEMACRXCLKCORCNT       (3'b000),
        .PHYEMACRXBUFSTATUS       (2'b00),
        .PHYEMACRXCHARISCOMMA     (1'b0),
        .PHYEMACRXCHARISK         (1'b0),
        .PHYEMACRXDISPERR         (1'b0),
        .PHYEMACRXNOTINTABLE      (1'b0),
        .PHYEMACRXRUNDISP         (1'b0),
        .PHYEMACTXBUFERR          (1'b0),
        .EMACPHYTXCHARDISPMODE    (),
        .EMACPHYTXCHARDISPVAL     (),
        .EMACPHYTXCHARISK         (),

        .EMACPHYMCLKOUT           (),
        .PHYEMACMCLKIN            (1'b0),
        .PHYEMACMDIN              (1'b1),
        .EMACPHYMDOUT             (),
        .EMACPHYMDTRI             (),

        .EMACSPEEDIS10100         (),

        .HOSTCLK                  (1'b0),
        .HOSTOPCODE               (2'b00),
        .HOSTREQ                  (1'b0),
        .HOSTMIIMSEL              (1'b0),
        .HOSTADDR                 (10'b0000000000),
        .HOSTWRDATA               (32'h00000000),
        .HOSTMIIMRDY              (),
        .HOSTRDDATA               (),

        .DCREMACCLK               (1'b0),
        .DCREMACABUS              (10'h000),
        .DCREMACREAD              (1'b0),
        .DCREMACWRITE             (1'b0),
        .DCREMACDBUS              (32'h00000000),
        .EMACDCRACK               (),
        .EMACDCRDBUS              (),
        .DCREMACENABLE            (1'b0),
        .DCRHOSTDONEIR            ()
    );

endmodule
