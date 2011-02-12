//-----------------------------------------------------------------------------
// Title      : LocalLink-level Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : v6_emac_v1_3_locallink.v
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
// Description:  This is the LocalLink-level wrapper for the Virtex-6
//               Embedded Tri-Mode Ethernet MAC. It is intended that this
//               example design can be quickly adapted and downloaded onto an
//               FPGA to provide a hardware test environment.
//
//               The LocalLink-level wrapper:
//
//               * instantiates the EMAC block-level wrapper (the EMAC
//                 instance-level wrapper with the physical interface logic);
//
//               * instantiates TX and RX reference design FIFOs with
//                 a LocalLink interface.
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
//               further information.
//-----------------------------------------------------------------------------

`timescale 1 ps / 1 ps


//-----------------------------------------------------------------------------
// Module declaration for the LocalLink-level wrapper
//-----------------------------------------------------------------------------

module v6_emac_v1_3_locallink
(

    // TX clock output
    TX_CLK_OUT,
    // TX clock input from BUFG
    TX_CLK,

    // LocalLink receiver interface
    RX_LL_CLOCK,
    RX_LL_RESET,
    RX_LL_DATA,
    RX_LL_SOF_N,
    RX_LL_EOF_N,
    RX_LL_SRC_RDY_N,
    RX_LL_DST_RDY_N,
    RX_LL_FIFO_STATUS,

    // LocalLink transmitter interface
    TX_LL_CLOCK,
    TX_LL_RESET,
    TX_LL_DATA,
    TX_LL_SOF_N,
    TX_LL_EOF_N,
    TX_LL_SRC_RDY_N,
    TX_LL_DST_RDY_N,

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

    // LocalLink receiver interface
    input           RX_LL_CLOCK;
    input           RX_LL_RESET;
    output   [7:0]  RX_LL_DATA;
    output          RX_LL_SOF_N;
    output          RX_LL_EOF_N;
    output          RX_LL_SRC_RDY_N;
    input           RX_LL_DST_RDY_N;
    output   [3:0]  RX_LL_FIFO_STATUS;

    // LocalLink transmitter interface
    input           TX_LL_CLOCK;
    input           TX_LL_RESET;
    input    [7:0]  TX_LL_DATA;
    input           TX_LL_SOF_N;
    input           TX_LL_EOF_N;
    input           TX_LL_SRC_RDY_N;
    output          TX_LL_DST_RDY_N;

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

    // Asynchronous reset
    input           RESET;


//-----------------------------------------------------------------------------
// Wire and register declarations
//-----------------------------------------------------------------------------

    // Global asynchronous reset
    wire            reset_i;

    // Client interface clocking signals
    wire            tx_clk_i;
    wire            rx_clk_i;

    // Internal client interface connections
    // Transmitter interface
    (* KEEP = "TRUE" *)
    wire     [7:0]  tx_data_i;
    (* KEEP = "TRUE" *)
    wire            tx_data_valid_i;
    wire            tx_underrun_i;
    (* KEEP = "TRUE" *)
    wire            tx_ack_i;
    wire            tx_collision_i;
    wire            tx_retransmit_i;
    // Receiver interface
    (* KEEP = "TRUE" *)
    wire     [7:0]  rx_data_i;
    (* KEEP = "TRUE" *)
    wire            rx_data_valid_i;
    wire            rx_good_frame_i;
    wire            rx_bad_frame_i;
    // Registers for the EMAC receiver output
    reg      [7:0]  rx_data_r;
    reg             rx_data_valid_r;
    reg             rx_good_frame_r;
    reg             rx_bad_frame_r;

    // Synchronous reset registers in the transmitter clock domain
    (* ASYNC_REG = "TRUE" *)
    reg       [5:0] tx_pre_reset_i;
    reg             tx_reset_i;

    // Synchronous reset registers in the receiver clock domain
    (* ASYNC_REG = "TRUE" *)
    reg       [5:0] rx_pre_reset_i;
    reg             rx_reset_i;


//-----------------------------------------------------------------------------
// Main body of code
//-----------------------------------------------------------------------------

    // Asynchronous reset input
    assign reset_i = RESET;

    //------------------------------------------------------------------------
    // Instantiate the block-level wrapper (v6_emac_v1_3_block.v)
    //------------------------------------------------------------------------
    v6_emac_v1_3_block v6_emac_v1_3_block_inst
    (
    // TX clock output
    .TX_CLK_OUT               (TX_CLK_OUT),
    // TX clock input from BUFG
    .TX_CLK                   (TX_CLK),

    // Client receiver interface
    .EMACCLIENTRXD            (rx_data_i),
    .EMACCLIENTRXDVLD         (rx_data_valid_i),
    .EMACCLIENTRXGOODFRAME    (rx_good_frame_i),
    .EMACCLIENTRXBADFRAME     (rx_bad_frame_i),
    .EMACCLIENTRXFRAMEDROP    (EMACCLIENTRXFRAMEDROP),
    .EMACCLIENTRXSTATS        (EMACCLIENTRXSTATS),
    .EMACCLIENTRXSTATSVLD     (EMACCLIENTRXSTATSVLD),
    .EMACCLIENTRXSTATSBYTEVLD (EMACCLIENTRXSTATSBYTEVLD),

    // Client transmitter interface
    .CLIENTEMACTXD            (tx_data_i),
    .CLIENTEMACTXDVLD         (tx_data_valid_i),
    .EMACCLIENTTXACK          (tx_ack_i),
    .CLIENTEMACTXFIRSTBYTE    (1'b0),
    .CLIENTEMACTXUNDERRUN     (tx_underrun_i),
    .EMACCLIENTTXCOLLISION    (tx_collision_i),
    .EMACCLIENTTXRETRANSMIT   (tx_retransmit_i),
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

    // MDIO interface
    .MDC                      (MDC),
    .MDIO_I                   (MDIO_I),
    .MDIO_O                   (MDIO_O),
    .MDIO_T                   (MDIO_T),

    // Host interface
    .HOSTCLK                  (HOSTCLK),
    .HOSTOPCODE               (HOSTOPCODE),
    .HOSTREQ                  (HOSTREQ),
    .HOSTMIIMSEL              (HOSTMIIMSEL),
    .HOSTADDR                 (HOSTADDR),
    .HOSTWRDATA               (HOSTWRDATA),
    .HOSTMIIMRDY              (HOSTMIIMRDY),
    .HOSTRDDATA               (HOSTRDDATA),

    // Asynchronous reset input
    .RESET                    (reset_i)
    );

  //-------------------------------------------------------------------
  // Instantiate the client-side FIFO
  //-------------------------------------------------------------------
  eth_fifo_8 client_side_FIFO (

     // EMAC transmitter client interface
     .tx_clk              (tx_clk_i),
     .tx_reset            (tx_reset_i),
     .tx_enable           (1'b1),
     .tx_data             (tx_data_i),
     .tx_data_valid       (tx_data_valid_i),
     .tx_ack              (tx_ack_i),
     .tx_underrun         (tx_underrun_i),
     .tx_collision        (tx_collision_i),
     .tx_retransmit       (tx_retransmit_i),

     // Transmitter LocalLink interface
     .tx_ll_clock         (TX_LL_CLOCK),
     .tx_ll_reset         (TX_LL_RESET),
     .tx_ll_data_in       (TX_LL_DATA),
     .tx_ll_sof_in_n      (TX_LL_SOF_N),
     .tx_ll_eof_in_n      (TX_LL_EOF_N),
     .tx_ll_src_rdy_in_n  (TX_LL_SRC_RDY_N),
     .tx_ll_dst_rdy_out_n (TX_LL_DST_RDY_N),
     .tx_fifo_status      (),
     .tx_overflow         (),

     // EMAC receiver client interface
     .rx_clk              (rx_clk_i),
     .rx_reset            (rx_reset_i),
     .rx_enable           (1'b1),
     .rx_data             (rx_data_r),
     .rx_data_valid       (rx_data_valid_r),
     .rx_good_frame       (rx_good_frame_r),
     .rx_bad_frame        (rx_bad_frame_r),
     .rx_overflow         (),

     // Receiver LocalLink interface
     .rx_ll_clock         (RX_LL_CLOCK),
     .rx_ll_reset         (RX_LL_RESET),
     .rx_ll_data_out      (RX_LL_DATA),
     .rx_ll_sof_out_n     (RX_LL_SOF_N),
     .rx_ll_eof_out_n     (RX_LL_EOF_N),
     .rx_ll_src_rdy_out_n (RX_LL_SRC_RDY_N),
     .rx_ll_dst_rdy_in_n  (RX_LL_DST_RDY_N),
     .rx_fifo_status      (RX_LL_FIFO_STATUS)
  );

  //-------------------------------------------------------------------
  // Additional synchronization, pipelining, and clock assignments
  //-------------------------------------------------------------------

  // Create synchronous reset in the transmitter clock domain
  always @(posedge tx_clk_i, posedge reset_i)
  begin
    if (reset_i === 1'b1)
    begin
      tx_pre_reset_i <= 6'h3F;
      tx_reset_i     <= 1'b1;
    end
    else
    begin
        tx_pre_reset_i[0]   <= 1'b0;
        tx_pre_reset_i[5:1] <= tx_pre_reset_i[4:0];
        tx_reset_i          <= tx_pre_reset_i[5];
      end
  end

  // Create synchronous reset in the receiver clock domain
  always @(posedge rx_clk_i, posedge reset_i)
  begin
    if (reset_i === 1'b1)
    begin
      rx_pre_reset_i <= 6'h3F;
      rx_reset_i     <= 1'b1;
    end
    else
    begin
        rx_pre_reset_i[0]   <= 1'b0;
        rx_pre_reset_i[5:1] <= rx_pre_reset_i[4:0];
        rx_reset_i          <= rx_pre_reset_i[5];
      end
  end

  // Register the receiver outputs before routing to the FIFO
  always @(posedge rx_clk_i, posedge reset_i)
  begin
    if (reset_i == 1'b1)
    begin
      rx_data_valid_r <= 1'b0;
      rx_data_r       <= 8'h00;
      rx_good_frame_r <= 1'b0;
      rx_bad_frame_r  <= 1'b0;
    end
    else
    begin
        rx_data_r       <= rx_data_i;
        rx_data_valid_r <= rx_data_valid_i;
        rx_good_frame_r <= rx_good_frame_i;
        rx_bad_frame_r  <= rx_bad_frame_i;
      end
  end

  assign EMACCLIENTRXDVLD = rx_data_valid_i;

  // Clocking assignments
  assign tx_clk_i = TX_CLK;
  assign rx_clk_i = PHY_RX_CLK;


endmodule
