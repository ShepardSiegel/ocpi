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
// File       : pcie_7x_v1_2_qpll_wrapper.v
// Version    : 1.2
//------------------------------------------------------------------------------
//  Filename     :  qpll_wrapper.v
//  Description  :  QPLL Wrapper Module for 7 Series Transceiver
//  Version      :  11.4
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- QPLL Wrapper ----------------------------------------------------
module pcie_7x_v1_2_qpll_wrapper #
(

    parameter PCIE_SIM_MODE    = "FALSE",                   // PCIe sim mode
    parameter PCIE_GT_DEVICE   = "GTX",                     // PCIe GT device
    parameter PCIE_USE_MODE    = "1.1",                     // PCIe use mode
    parameter PCIE_PLL_SEL     = "CPLL",                    // PCIe PLL select for Gen1/Gen2 only
    parameter PCIE_REFCLK_FREQ = 0                          // PCIe reference clock frequency

)

(

    //---------- QPLL Clock Ports --------------------------
    input               QPLL_GTGREFCLK,
    input               QPLL_QPLLLOCKDETCLK,

    output              QPLL_QPLLOUTCLK,
    output              QPLL_QPLLOUTREFCLK,
    output              QPLL_QPLLLOCK,

    //---------- QPLL Reset Ports --------------------------
    input               QPLL_QPLLPD,
    input               QPLL_QPLLRESET,

    //---------- QPLL DRP Ports ----------------------------
    input               QPLL_DRPCLK,
    input       [ 7:0]  QPLL_DRPADDR,
    input               QPLL_DRPEN,
    input       [15:0]  QPLL_DRPDI,
    input               QPLL_DRPWE,

    output      [15:0]  QPLL_DRPDO,
    output              QPLL_DRPRDY

);



    //---------- Select QPLL Feedback Divider --------------
    //  N = 100 for 100 MHz ref clk and 10Gb/s line rate
    //  N =  80 for 125 MHz ref clk and 10Gb/s line rate
    //  N =  40 for 250 MHz ref clk and 10Gb/s line rate
    //------------------------------------------------------
    //  N =  80 for 100 MHz ref clk and  8Gb/s line rate
    //  N =  64 for 125 MHz ref clk and  8Gb/s line rate
    //  N =  32 for 250 MHz ref clk and  8Gb/s line rate
    //------------------------------------------------------
    localparam QPLL_FBDIV = (PCIE_REFCLK_FREQ == 2) && (PCIE_PLL_SEL == "QPLL") ? 10'b0010000000 :
                            (PCIE_REFCLK_FREQ == 1) && (PCIE_PLL_SEL == "QPLL") ? 10'b0100100000 :
                            (PCIE_REFCLK_FREQ == 0) && (PCIE_PLL_SEL == "QPLL") ? 10'b0101110000 :
                            (PCIE_REFCLK_FREQ == 2) && (PCIE_PLL_SEL == "CPLL") ? 10'b0001100000 :
                            (PCIE_REFCLK_FREQ == 1) && (PCIE_PLL_SEL == "CPLL") ? 10'b0011100000 : 10'b0100100000;

    //---------- Select BIAS_CFG ---------------------------
    localparam BIAS_CFG = ((PCIE_USE_MODE == "1.0") && (PCIE_PLL_SEL == "CPLL")) ? 64'h0000042000001000 : 64'h0000040000001000;



//---------- Select GTX or GTH -------------------------------------------------
//  Notes  :  Attributes that are commented out uses the GT default settings
//------------------------------------------------------------------------------
generate if (PCIE_GT_DEVICE == "GTH")

    //---------- GTH Common ----------------------------------------------------
    begin : gth_common

    //---------- GTX Common Module ---------------------------------------------
    GTHE2_COMMON #
    (

        //---------- Simulation Attributes -------------------------------------
        .SIM_QPLLREFCLK_SEL             (3'b001),                               //
        .SIM_RESET_SPEEDUP              (PCIE_SIM_MODE),                        //
        .SIM_VERSION                    (PCIE_USE_MODE),                        //

        //---------- Clock Attributes ------------------------------------------
        .QPLL_CFG                       (27'h06801C1),                          // Optimized for silicon
      //.QPLL_CLKOUT_CFG                ( 4'b0000),                             //
        .QPLL_COARSE_FREQ_OVRD          ( 6'b010000),                           //
        .QPLL_COARSE_FREQ_OVRD_EN       ( 1'b0),                                //
        .QPLL_CP                        (10'h1FF),                              // Optimized for compliance
        .QPLL_CP_MONITOR_EN             ( 1'b0),                                //
        .QPLL_DMONITOR_SEL              ( 1'b0),                                //
        .QPLL_FBDIV                     (QPLL_FBDIV),                           //
        .QPLL_FBDIV_MONITOR_EN          ( 1'b0),                                //
        .QPLL_FBDIV_RATIO               ( 1'b1),                                //
      //.QPLL_INIT_CFG	                 (24'h000006),                           //
        .QPLL_LOCK_CFG                  (16'h01D0),                             // Optimized for silicon
        .QPLL_LPF                       ( 4'hD),                                // Optimized for silicon
        .QPLL_REFCLK_DIV	               ( 1),                                   //

        //----------------------------------------------------------------------
        .BIAS_CFG	                      (BIAS_CFG)                              // Optimized for silicon
      //.COMMON_CFG	                    (32'h00000000),                         //

        //---------- GTH -------------------------------------------------------
      //.RSVD_ATTR0                     (16'h0000),                             //
      //.RSVD_ATTR1                     (16'h0000)                              //
    )
    gthe2_common_i
    (

        //---------- Clock -----------------------------------------------------
        .GTGREFCLK                      ( 1'd0),                                //
        .GTREFCLK0                      (QPLL_GTGREFCLK),                       //
        .GTREFCLK1                      ( 1'd0),                                //
        .GTNORTHREFCLK0                 ( 1'd0),                                //
        .GTNORTHREFCLK1                 ( 1'd0),                                //
        .GTSOUTHREFCLK0                 ( 1'd0),                                //
        .GTSOUTHREFCLK1                 ( 1'd0),                                //
        .QPLLLOCKDETCLK                 (QPLL_QPLLLOCKDETCLK),                  //
        .QPLLLOCKEN                     ( 1'd1),                                //
        .QPLLREFCLKSEL                  ( 3'd1),                                //
        .QPLLRSVD1                      (16'd0),                                //
        .QPLLRSVD2                      ( 5'b11111),                            //

        .QPLLOUTCLK                     (QPLL_QPLLOUTCLK),                      //
        .QPLLOUTREFCLK                  (QPLL_QPLLOUTREFCLK),                   //
        .QPLLLOCK                       (QPLL_QPLLLOCK),                        //
        .QPLLFBCLKLOST                  (),                                     //
        .QPLLREFCLKLOST                 (),                                     //
        .QPLLDMONITOR                   (),                                     //

        //---------- Reset -----------------------------------------------------
        .QPLLPD                         (QPLL_QPLLPD),                          //
        .QPLLRESET                      (QPLL_QPLLRESET),                       //
        .QPLLOUTRESET                   (1'd0),                                 //

        //---------- DRP -------------------------------------------------------
        .DRPCLK                         (QPLL_DRPCLK),                          //
        .DRPADDR                        (QPLL_DRPADDR),                         //
        .DRPEN                          (QPLL_DRPEN),                           //
        .DRPDI                          (QPLL_DRPDI),                           //
        .DRPWE                          (QPLL_DRPWE),                           //

        .DRPDO                          (QPLL_DRPDO),                           //
        .DRPRDY                         (QPLL_DRPRDY),                          //

        //---------- Band Gap --------------------------------------------------
        .BGBYPASSB                      ( 1'd1),                                //
        .BGMONITORENB                   ( 1'd1),                                //
        .BGPDB                          ( 1'd1),                                //
        .BGRCALOVRD                     ( 5'd0),                                //

        //----------------------------------------------------------------------
        .PMARSVD                        ( 8'd0),                                //
        .RCALENB                        ( 1'b0),                                //

        .REFCLKOUTMONITOR               (),                                     //

        //---------- GTH -------------------------------------------------------
        .BGRCALOVRDENB                  ( 1'd0),                                //
        .PMARSVDOUT                     ()                                      //

    );

    end

else

    begin : gtx_common

    //---------- GTX Common Module ---------------------------------------------
    GTXE2_COMMON #
    (

        //---------- Simulation Attributes -------------------------------------
        .SIM_QPLLREFCLK_SEL             (3'b001),                               //
        .SIM_RESET_SPEEDUP              (PCIE_SIM_MODE),                        //
        .SIM_VERSION                    (PCIE_USE_MODE),                        //

        //---------- Clock Attributes ------------------------------------------
        .QPLL_CFG                       (27'h06801C1),                          // Optimized for silicon
      //.QPLL_CLKOUT_CFG                ( 4'b0000),                             //
        .QPLL_COARSE_FREQ_OVRD          ( 6'b010000),                           //
        .QPLL_COARSE_FREQ_OVRD_EN       ( 1'b0),                                //
        .QPLL_CP                        (10'h1FF),                              // Optimized for compliance
        .QPLL_CP_MONITOR_EN             ( 1'b0),                                //
        .QPLL_DMONITOR_SEL              ( 1'b0),                                //
        .QPLL_FBDIV                     (QPLL_FBDIV),                           //
        .QPLL_FBDIV_MONITOR_EN          ( 1'b0),                                //
        .QPLL_FBDIV_RATIO               ( 1'b1),                                //
      //.QPLL_INIT_CFG	                 (24'h000006),                           //
        .QPLL_LOCK_CFG                  (16'h01D0),                             // Optimized for silicon
        .QPLL_LPF                       ( 4'hD),                                // Optimized for silicon
        .QPLL_REFCLK_DIV	               ( 1),                                   //

        //----------------------------------------------------------------------
        .BIAS_CFG	                      (BIAS_CFG)                              // Optimized for silicon
      //.COMMON_CFG	                    (32'h00000000)                          //

    )
    gtxe2_common_i
    (

        //---------- Clock -----------------------------------------------------
        .GTGREFCLK                      ( 1'd0),                                //
        .GTREFCLK0                      (QPLL_GTGREFCLK),                       //
        .GTREFCLK1                      ( 1'd0),                                //
        .GTNORTHREFCLK0                 ( 1'd0),                                //
        .GTNORTHREFCLK1                 ( 1'd0),                                //
        .GTSOUTHREFCLK0                 ( 1'd0),                                //
        .GTSOUTHREFCLK1                 ( 1'd0),                                //
        .QPLLLOCKDETCLK                 (QPLL_QPLLLOCKDETCLK),                  //
        .QPLLLOCKEN                     ( 1'd1),                                //
        .QPLLREFCLKSEL                  ( 3'd1),                                //
        .QPLLRSVD1                      (16'd0),                                //
        .QPLLRSVD2                      ( 5'b11111),                            //

        .QPLLOUTCLK                     (QPLL_QPLLOUTCLK),                      //
        .QPLLOUTREFCLK                  (QPLL_QPLLOUTREFCLK),                   //
        .QPLLLOCK                       (QPLL_QPLLLOCK),                        //
        .QPLLFBCLKLOST                  (),                                     //
        .QPLLREFCLKLOST                 (),                                     //
        .QPLLDMONITOR                   (),                                     //

        //---------- Reset -----------------------------------------------------
        .QPLLPD                         (QPLL_QPLLPD),                          //
        .QPLLRESET                      (QPLL_QPLLRESET),                       //
        .QPLLOUTRESET                   ( 1'd0),                                //

        //---------- DRP -------------------------------------------------------
        .DRPCLK                         (QPLL_DRPCLK),                          //
        .DRPADDR                        (QPLL_DRPADDR),                         //
        .DRPEN                          (QPLL_DRPEN),                           //
        .DRPDI                          (QPLL_DRPDI),                           //
        .DRPWE                          (QPLL_DRPWE),                           //

        .DRPDO                          (QPLL_DRPDO),                           //
        .DRPRDY                         (QPLL_DRPRDY),                          //

        //---------- Band Gap --------------------------------------------------
        .BGBYPASSB                      ( 1'd1),                                //
        .BGMONITORENB                   ( 1'd1),                                //
        .BGPDB                          ( 1'd1),                                //
        .BGRCALOVRD                     ( 5'd0),                                //

        //----------------------------------------------------------------------
        .PMARSVD                        ( 8'd0),                                //
        .RCALENB                        ( 1'b0),                                //

        .REFCLKOUTMONITOR               ()                                      //

    );

    end

endgenerate

endmodule
