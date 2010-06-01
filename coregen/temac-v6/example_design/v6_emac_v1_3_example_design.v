//-----------------------------------------------------------------------------
// Title      : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper Example Design
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : v6_emac_v1_3_example_design.v
// Version    : 1.3
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
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
// Description:  This is the Example Design wrapper for the Virtex-6
//               Embedded Tri-Mode Ethernet MAC. It is intended that this
//               example design can be quickly adapted and downloaded onto an
//               FPGA to provide a hardware test environment.
//
//               The Example Design wrapper:
//
//               * instantiates the EMAC LocalLink-level wrapper (the EMAC
//                 block-level wrapper with the RX and TX FIFOs and a
//                 LocalLink interface);
//
//               * instantiates a simple example design which provides an
//                 address swap and loopback function at the user interface;
//
//               * instantiates the fundamental clocking resources required
//                 by the core;
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
//               further information.
//
//    ---------------------------------------------------------------------
//    |EXAMPLE DESIGN WRAPPER                                             |
//    |           --------------------------------------------------------|
//    |           |LOCALLINK-LEVEL WRAPPER                                |
//    |           |              -----------------------------------------|
//    |           |              |BLOCK-LEVEL WRAPPER                     |
//    |           |              |    ---------------------               |
//    | --------  |  ----------  |    | INSTANCE-LEVEL    |               |
//    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
//    | |      |->|->|        |->|--->| Tx            Tx  |->|       |--->|
//    | |      |  |  |        |  |    | client        PHY |  |       |    |
//    | | ADDR |  |  | LOCAL- |  |    | I/F           I/F |  |       |    |
//    | | SWAP |  |  | LINK   |  |    |                   |  | PHY   |    |
//    | |      |  |  | FIFO   |  |    |                   |  | I/F   |    |
//    | |      |  |  |        |  |    |                   |  |       |    |
//    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
//    | |      |  |  |        |  |    | client        PHY |  |       |    |
//    | |      |<-|<-|        |<-|<---| I/F           I/F |<-|       |<---|
//    | |      |  |  |        |  |    |                   |  ---------    |
//    | --------  |  ----------  |    ---------------------               |
//    |           |              -----------------------------------------|
//    |           --------------------------------------------------------|
//    ---------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

`timescale 1 ps / 1 ps


//-----------------------------------------------------------------------------
// Module declaration for the example design
//-----------------------------------------------------------------------------

module v6_emac_v1_3_example_design
(

    // Client receiver interface
    EMACCLIENTRXDVLD,
    EMACCLIENTRXFRAMEDROP,
    EMACCLIENTRXSTATS,
    EMACCLIENTRXSTATSVLD,
    EMACCLIENTRXSTATSBYTEVLD,

    // Client transmitter interface
    CLIENTEMACTXIFGDELAY,
    EMACCLIENTTXSTATS,
    EMACCLIENTTXSTATSVLD,
    EMACCLIENTTXSTATSBYTEVLD,

    // MAC control interface
    CLIENTEMACPAUSEREQ,
    CLIENTEMACPAUSEVAL,

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

    // MDIO interface
    MDC,
    MDIO_I,
    MDIO_O,
    MDIO_T,

    // Host interface
    HOSTCLK,
    HOSTOPCODE,
    HOSTREQ,
    HOSTMIIMSEL,
    HOSTADDR,
    HOSTWRDATA,
    HOSTMIIMRDY,
    HOSTRDDATA,

    // Reference clock for IODELAYs
    REFCLK,

    // Asynchronous reset
    RESET
);


//-----------------------------------------------------------------------------
// Port declarations
//-----------------------------------------------------------------------------

    // Client receiver interface
    output          EMACCLIENTRXDVLD;
    output          EMACCLIENTRXFRAMEDROP;
    output   [6:0]  EMACCLIENTRXSTATS;
    output          EMACCLIENTRXSTATSVLD;
    output          EMACCLIENTRXSTATSBYTEVLD;

    // Client transmitter interface
    input    [7:0]  CLIENTEMACTXIFGDELAY;
    output          EMACCLIENTTXSTATS;
    output          EMACCLIENTTXSTATSVLD;
    output          EMACCLIENTTXSTATSBYTEVLD;

    // MAC control interface
    input           CLIENTEMACPAUSEREQ;
    input   [15:0]  CLIENTEMACPAUSEVAL;

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

    // MDIO interface
    output          MDC;
    input           MDIO_I;
    output          MDIO_O;
    output          MDIO_T;

    // Host interface
    input           HOSTCLK;
    input    [1:0]  HOSTOPCODE;
    input           HOSTREQ;
    input           HOSTMIIMSEL;
    input    [9:0]  HOSTADDR;
    input   [31:0]  HOSTWRDATA;
    output          HOSTMIIMRDY;
    output  [31:0]  HOSTRDDATA;

    // Reference clock for IODELAYs
    input           REFCLK;

    // Asynchronous reset
    input           RESET;


//-----------------------------------------------------------------------------
// Wire and register declarations
//-----------------------------------------------------------------------------

    // Global asynchronous reset
    wire            reset_i;

    // LocalLink interface clocking signal
    wire            ll_clk_i;

    // Address swap transmitter connections
    wire      [7:0] tx_ll_data_i;
    wire            tx_ll_sof_n_i;
    wire            tx_ll_eof_n_i;
    wire            tx_ll_src_rdy_n_i;
    wire            tx_ll_dst_rdy_n_i;

    // Address swap receiver connections
    wire      [7:0] rx_ll_data_i;
    wire            rx_ll_sof_n_i;
    wire            rx_ll_eof_n_i;
    wire            rx_ll_src_rdy_n_i;
    wire            rx_ll_dst_rdy_n_i;

    // Synchronous reset registers in the LocalLink clock domain
    (* ASYNC_REG = "TRUE" *)
    reg       [5:0] ll_pre_reset_i;

    reg             ll_reset_i;

    // Reference clock for IODELAYs
    wire            refclk_ibufg_i;
    wire            refclk_bufg_i;

    // Host interface clock
    (* BUFFER_TYPE = "NONE" *)
    wire            host_clk_i;

    // GMII input clocks to wrappers
    (* KEEP = "TRUE" *)
    wire            tx_clk;
    wire            rx_clk_i;
    wire            gmii_rx_clk_bufio;
    wire            gmii_rx_clk_delay;

    // IDELAY controller
    reg      [12:0] idelayctrl_reset_r;
    wire            idelayctrl_reset_i;
    // GTX reference clock
    wire            gtx_clk_i;


//-----------------------------------------------------------------------------
// Main body of code
//-----------------------------------------------------------------------------

    // Reset input buffer
    IBUF reset_ibuf (
       .I (RESET),
       .O (reset_i)
    );

    //------------------------------------------------------------------------
    // Clock skew management: use IDELAY on GMII_RX_CLK to move
    // the clock into proper alignment with the data
    //------------------------------------------------------------------------

    // Instantiate IDELAYCTRL for the IDELAY in Fixed Tap Delay Mode
    (* SYN_NOPRUNE = "TRUE" *)
    IDELAYCTRL dlyctrl (
       .RDY    (),
       .REFCLK (refclk_bufg_i),
       .RST    (idelayctrl_reset_i)
    );

    // Assert the proper reset pulse for the IDELAYCTRL
    always @(posedge refclk_bufg_i, posedge reset_i)
    begin
       if (reset_i == 1'b1)
       begin
          idelayctrl_reset_r[0]    <= 1'b0;
          idelayctrl_reset_r[12:1] <= 12'b111111111111;
       end
       else
       begin
          idelayctrl_reset_r[0]    <= 1'b0;
          idelayctrl_reset_r[12:1] <= idelayctrl_reset_r[11:0];
       end
    end
    assign idelayctrl_reset_i = idelayctrl_reset_r[12];

    // Please modify the IDELAY_VALUE to suit your design.
    // The IDELAY_VALUE set here is tuned to this example design.
    // For more information on IDELAYCTRL and IODELAY, please
    // refer to the Virtex-6 User Guide.
    IODELAY #(
       .IDELAY_TYPE           ("FIXED"),
       .IDELAY_VALUE          (0),
       .DELAY_SRC             ("I"),
       .SIGNAL_PATTERN        ("CLOCK"),
       .HIGH_PERFORMANCE_MODE ("TRUE")
    )
    gmii_rxc_delay (
       .IDATAIN (GMII_RX_CLK),
       .ODATAIN (1'b0),
       .DATAOUT (gmii_rx_clk_delay),
       .DATAIN  (1'b0),
       .C       (1'b0),
       .T       (1'b0),
       .CE      (1'b0),
       .INC     (1'b0),
       .RST     (1'b0)
    );


    // Globally-buffer the GTX reference clock, used to clock
    // the transmit-side functions of the EMAC wrappers
    // (tx_clk can be shared between multiple EMAC instances, including
    //  multiple instantiations of the EMAC wrappers)
    BUFG bufg_tx (
       .I (gtx_clk_i),
       .O (tx_clk)
    );

    // Use a low-skew BUFIO on the delayed RX_CLK, which will be used in the
    // GMII phyical interface block to capture incoming data and control.
    BUFIO bufio_rx (
       .I (gmii_rx_clk_delay),
       .O (gmii_rx_clk_bufio)
    );

    // Regionally-buffer the receive-side GMII physical interface clock
    // for use with receive-side functions of the EMAC
    BUFR bufr_rx (
       .I   (gmii_rx_clk_delay),
       .O   (rx_clk_i),
       .CE  (1'b1),
       .CLR (1'b0)
    );

    // Clock the LocalLink interface with the globally-buffered
    // GTX reference clock
    assign ll_clk_i = tx_clk;

    //------------------------------------------------------------------------
    // Instantiate the LocalLink-level EMAC wrapper (v6_emac_v1_3_locallink.v)
    //------------------------------------------------------------------------
    v6_emac_v1_3_locallink v6_emac_v1_3_locallink_inst
    (
    // TX clock output
    .TX_CLK_OUT               (),
    // TX Clock input from BUFG
    .TX_CLK                   (tx_clk),

    // LocalLink receiver interface
    .RX_LL_CLOCK              (ll_clk_i),
    .RX_LL_RESET              (ll_reset_i),
    .RX_LL_DATA               (rx_ll_data_i),
    .RX_LL_SOF_N              (rx_ll_sof_n_i),
    .RX_LL_EOF_N              (rx_ll_eof_n_i),
    .RX_LL_SRC_RDY_N          (rx_ll_src_rdy_n_i),
    .RX_LL_DST_RDY_N          (rx_ll_dst_rdy_n_i),
    .RX_LL_FIFO_STATUS        (),

    // Client receiver signals
    .EMACCLIENTRXDVLD         (EMACCLIENTRXDVLD),
    .EMACCLIENTRXFRAMEDROP    (EMACCLIENTRXFRAMEDROP),
    .EMACCLIENTRXSTATS        (EMACCLIENTRXSTATS),
    .EMACCLIENTRXSTATSVLD     (EMACCLIENTRXSTATSVLD),
    .EMACCLIENTRXSTATSBYTEVLD (EMACCLIENTRXSTATSBYTEVLD),

    // LocalLink transmitter interface
    .TX_LL_CLOCK              (ll_clk_i),
    .TX_LL_RESET              (ll_reset_i),
    .TX_LL_DATA               (tx_ll_data_i),
    .TX_LL_SOF_N              (tx_ll_sof_n_i),
    .TX_LL_EOF_N              (tx_ll_eof_n_i),
    .TX_LL_SRC_RDY_N          (tx_ll_src_rdy_n_i),
    .TX_LL_DST_RDY_N          (tx_ll_dst_rdy_n_i),

    // Client transmitter signals
    .CLIENTEMACTXIFGDELAY     (CLIENTEMACTXIFGDELAY),
    .EMACCLIENTTXSTATS        (EMACCLIENTTXSTATS),
    .EMACCLIENTTXSTATSVLD     (EMACCLIENTTXSTATSVLD),
    .EMACCLIENTTXSTATSBYTEVLD (EMACCLIENTTXSTATSBYTEVLD),

    // MAC control interface
    .CLIENTEMACPAUSEREQ       (CLIENTEMACPAUSEREQ),
    .CLIENTEMACPAUSEVAL       (CLIENTEMACPAUSEVAL),

    // Receive-side PHY clock on regional buffer, to EMAC
    .PHY_RX_CLK               (rx_clk_i),

    // Reference clock (unused)
    .GTX_CLK                  (1'b0),

    // GMII interface
    .GMII_TXD                 (GMII_TXD),
    .GMII_TX_EN               (GMII_TX_EN),
    .GMII_TX_ER               (GMII_TX_ER),
    .GMII_TX_CLK              (GMII_TX_CLK),
    .GMII_RXD                 (GMII_RXD),
    .GMII_RX_DV               (GMII_RX_DV),
    .GMII_RX_ER               (GMII_RX_ER),
    .GMII_RX_CLK              (gmii_rx_clk_bufio),

    // MDIO interface
    .MDC                      (MDC),
    .MDIO_I                   (MDIO_I),
    .MDIO_O                   (MDIO_O),
    .MDIO_T                   (MDIO_T),

    // Host interface
    .HOSTCLK                  (host_clk_i),
    .HOSTOPCODE               (HOSTOPCODE),
    .HOSTREQ                  (HOSTREQ),
    .HOSTMIIMSEL              (HOSTMIIMSEL),
    .HOSTADDR                 (HOSTADDR),
    .HOSTWRDATA               (HOSTWRDATA),
    .HOSTMIIMRDY              (HOSTMIIMRDY),
    .HOSTRDDATA               (HOSTRDDATA),

    // Asynchronous reset
    .RESET                    (reset_i)
    );

    //-------------------------------------------------------------------
    //  Instatiate the address swapping module
    //-------------------------------------------------------------------
    address_swap_module_8 client_side_asm (
       .rx_ll_clock         (ll_clk_i),
       .rx_ll_reset         (ll_reset_i),
       .rx_ll_data_in       (rx_ll_data_i),
       .rx_ll_sof_in_n      (rx_ll_sof_n_i),
       .rx_ll_eof_in_n      (rx_ll_eof_n_i),
       .rx_ll_src_rdy_in_n  (rx_ll_src_rdy_n_i),
       .rx_ll_data_out      (tx_ll_data_i),
       .rx_ll_sof_out_n     (tx_ll_sof_n_i),
       .rx_ll_eof_out_n     (tx_ll_eof_n_i),
       .rx_ll_src_rdy_out_n (tx_ll_src_rdy_n_i),
       .rx_ll_dst_rdy_in_n  (tx_ll_dst_rdy_n_i)
    );

    assign rx_ll_dst_rdy_n_i = tx_ll_dst_rdy_n_i;

    // Create synchronous reset in the transmitter clock domain
    always @(posedge ll_clk_i, posedge reset_i)
    begin
      if (reset_i === 1'b1)
      begin
        ll_pre_reset_i <= 6'h3F;
        ll_reset_i     <= 1'b1;
      end
      else
      begin
        ll_pre_reset_i[0]   <= 1'b0;
        ll_pre_reset_i[5:1] <= ll_pre_reset_i[4:0];
        ll_reset_i          <= ll_pre_reset_i[5];
      end
    end

    // Globally-buffer the reference clock used for
    // the IODELAYCTRL primitive
    IBUFG refclk_ibufg (
       .I (REFCLK),
       .O (refclk_ibufg_i)
    );
    BUFG refclk_bufg (
       .I (refclk_ibufg_i),
       .O (refclk_bufg_i)
    );

    // Buffer the input clock used for the generic host management
    // interface. This input should be driven from the 125MHz reference
    // clock to save clocking resources.
    IBUF host_clk (
       .I (HOSTCLK),
       .O (host_clk_i)
    );
    // Prepare the GTX_CLK for a BUFG
    IBUFG gtx_clk_ibufg (
       .I (GTX_CLK),
       .O (gtx_clk_i)
    );


endmodule
