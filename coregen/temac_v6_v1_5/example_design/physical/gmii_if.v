//----------------------------------------------------------------------
// Title      : Gigabit Media Independent Interface (GMII) Physical I/F
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : gmii_if.v
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
//----------------------------------------------------------------------
// Description:  This module creates a Gigabit Media Independent
//               Interface (GMII) by instantiating Input/Output buffers
//               and Input/Output flip-flops as required.
//
//               This interface is used to connect the Ethernet MAC to
//               an external 1000Mb/s (or Tri-speed) Ethernet PHY.
//----------------------------------------------------------------------

`timescale 1 ps / 1 ps

module gmii_if (
  RESET,
  // GMII Interface
  GMII_TXD,
  GMII_TX_EN,
  GMII_TX_ER,
  GMII_TX_CLK,
  GMII_RXD,
  GMII_RX_DV,
  GMII_RX_ER,
  // MAC Interface
  TXD_FROM_MAC,
  TX_EN_FROM_MAC,
  TX_ER_FROM_MAC,
  TX_CLK,
  RXD_TO_MAC,
  RX_DV_TO_MAC,
  RX_ER_TO_MAC,
  RX_CLK
);

  input        RESET;
  output [7:0] GMII_TXD;
  output       GMII_TX_EN;
  output       GMII_TX_ER;
  output       GMII_TX_CLK;
  input  [7:0] GMII_RXD;
  input        GMII_RX_DV;
  input        GMII_RX_ER;
  input  [7:0] TXD_FROM_MAC;
  input        TX_EN_FROM_MAC;
  input        TX_ER_FROM_MAC;
  input        TX_CLK;
  output [7:0] RXD_TO_MAC;
  output       RX_DV_TO_MAC;
  output       RX_ER_TO_MAC;
  input        RX_CLK;

  reg    [7:0] RXD_TO_MAC;
  reg          RX_DV_TO_MAC;
  reg          RX_ER_TO_MAC;
  reg    [7:0] GMII_TXD;
  reg          GMII_TX_EN;
  reg          GMII_TX_ER;
  wire   [7:0] GMII_RXD_DLY;
  wire         GMII_RX_DV_DLY;
  wire         GMII_RX_ER_DLY;

  //------------------------------------------------------------------------
  // GMII Transmitter Clock Management
  //------------------------------------------------------------------------
  // Instantiate a DDR output register. This is a good way to drive
  // GMII_TX_CLK since the clock-to-pad delay will be the same as that for
  // data driven from IOB Ouput flip-flops, eg. GMII_TXD[7:0].
  ODDR gmii_tx_clk_oddr (
     .Q  (GMII_TX_CLK),
     .C  (TX_CLK),
     .CE (1'b1),
     .D1 (1'b0),
     .D2 (1'b1),
     .R  (RESET),
     .S  (1'b0)
  );

  //------------------------------------------------------------------------
  // GMII Transmitter Logic : Drive TX signals through IOBs onto the
  // GMII interface
  //------------------------------------------------------------------------
  // Infer IOB Output flip-flops
  always @(posedge TX_CLK, posedge RESET)
  begin
     if (RESET == 1'b1)
     begin
        GMII_TX_EN <= 1'b0;
        GMII_TX_ER <= 1'b0;
        GMII_TXD   <= 8'h00;
     end
     else
     begin
        GMII_TX_EN <= TX_EN_FROM_MAC;
        GMII_TX_ER <= TX_ER_FROM_MAC;
        GMII_TXD   <= TXD_FROM_MAC;
     end
  end

  //------------------------------------------------------------------------
  // Route GMII inputs through IODELAY blocks, using IDELAY function
  //------------------------------------------------------------------------
  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld0 (
    .IDATAIN(GMII_RXD[0]),
    .DATAOUT(GMII_RXD_DLY[0]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

 IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld1 (
    .IDATAIN(GMII_RXD[1]),
    .DATAOUT(GMII_RXD_DLY[1]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld2 (
    .IDATAIN(GMII_RXD[2]),
    .DATAOUT(GMII_RXD_DLY[2]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld3 (
    .IDATAIN(GMII_RXD[3]),
    .DATAOUT(GMII_RXD_DLY[3]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld4 (
    .IDATAIN(GMII_RXD[4]),
    .DATAOUT(GMII_RXD_DLY[4]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld5 (
    .IDATAIN(GMII_RXD[5]),
    .DATAOUT(GMII_RXD_DLY[5]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld6 (
    .IDATAIN(GMII_RXD[6]),
    .DATAOUT(GMII_RXD_DLY[6]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideld7 (
    .IDATAIN(GMII_RXD[7]),
    .DATAOUT(GMII_RXD_DLY[7]),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
  );

  IODELAY #(
    .IDELAY_TYPE           ("FIXED"),
    .IDELAY_VALUE          (0),
    .HIGH_PERFORMANCE_MODE ("TRUE")
  )
  ideldv(
    .IDATAIN(GMII_RX_DV),
    .DATAOUT(GMII_RX_DV_DLY),
    .DATAIN(1'b0),
    .ODATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .T(1'b0),
    .RST(1'b0)
 );

 IODELAY #(
   .IDELAY_TYPE           ("FIXED"),
   .IDELAY_VALUE          (0),
   .HIGH_PERFORMANCE_MODE ("TRUE")
 )
 ideler(
   .IDATAIN(GMII_RX_ER),
   .DATAOUT(GMII_RX_ER_DLY),
   .DATAIN(1'b0),
   .ODATAIN(1'b0),
   .C(1'b0),
   .CE(1'b0),
   .INC(1'b0),
   .T(1'b0),
   .RST(1'b0)
 );

  //------------------------------------------------------------------------
  // GMII Receiver Logic : Receive RX signals through IOBs from the
  // GMII interface
  //------------------------------------------------------------------------
  // Infer IOB Input flip-flops
  always @(posedge RX_CLK, posedge RESET)
  begin
     if (RESET == 1'b1)
     begin
        RX_DV_TO_MAC <= 1'b0;
        RX_ER_TO_MAC <= 1'b0;
        RXD_TO_MAC   <= 8'h00;
     end
     else
     begin
        RX_DV_TO_MAC <= GMII_RX_DV_DLY;
        RX_ER_TO_MAC <= GMII_RX_ER_DLY;
        RXD_TO_MAC   <= GMII_RXD_DLY;
     end
  end

endmodule
