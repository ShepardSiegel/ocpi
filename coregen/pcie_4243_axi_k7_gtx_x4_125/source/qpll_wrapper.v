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
// File       : qpll_wrapper.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  QPLL Wrapper for Virtex-7 GTX PCIe
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- QPLL Wrapper ----------------------------------------------------
module qpll_wrapper #
(
    
    parameter PCIE_SIM_MODE    = "FALSE", 
    parameter PCIE_REFCLK_FREQ = 0
 
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
    //  PCIE_REFCLK_FREQ = 0 (100 MHz) : 8 + 3(QPLL_FBDIV[9:4]) + QPLL_FBDIV[3:0] = 80
    //  PCIE_REFCLK_FREQ = 1 (125 MHz) : 8 + 3(QPLL_FBDIV[9:4]) + QPLL_FBDIV[3:0] = 64
    //  PCIE_REFCLK_FREQ = 2 (250 MHz) : 8 + 3(QPLL_FBDIV[9:4]) + QPLL_FBDIV[3:0] = 32
    //------------------------------------------------------
   //ocalparam        	QPLL_FBDIV  = (PCIE_REFCLK_FREQ == 2) ?  10'b000011_1111 : 
   //                                 (PCIE_REFCLK_FREQ == 1) ?  10'b001110_1110 : 10'b010011_1111;

    localparam        	QPLL_FBDIV  = (PCIE_REFCLK_FREQ == 2) ?  10'b0001100000 : 
                                      (PCIE_REFCLK_FREQ == 1) ?  10'b0011100000 : 10'b0100100000;

//---------- GTX Common Module -------------------------------------------------
GTXE2_COMMON #
(
   
    //---------- Simulation Attributes --------------------- 
    .SIM_QPLLREFCLK_SEL	            (3'b001),               //
    .SIM_RESET_SPEEDUP	            (PCIE_SIM_MODE),        //
    .SIM_VERSION	                ("1.0"),                // 
    
    //---------- Clock Attributes --------------------------
    .QPLL_CFG                       (27'h0480181),          // default = 27'h0080000, 27'h0480181
    .QPLL_CLKOUT_CFG	            (4'b0000),              //
    .QPLL_COARSE_FREQ_OVRD	        (6'b010000),            // coarse freq
    .QPLL_COARSE_FREQ_OVRD_EN	    (1'b0),                 // coarse freq en
    .QPLL_CP	                    (10'b0000000000),       //
    .QPLL_CP_MONITOR_EN	            (1'b0),                 //
    .QPLL_DMONITOR_SEL	            (1'b0),                 //
    .QPLL_FBDIV	                    (QPLL_FBDIV),           // 
    .QPLL_FBDIV_MONITOR_EN	        (1'b0),                 //
    .QPLL_FBDIV_RATIO	            (1'b1),                 //
    .QPLL_INIT_CFG	                (24'h0000FF),           // [9:0] need to be none-zero
    .QPLL_LOCK_CFG                  (PCIE_SIM_MODE ? 16'h01F0 : 16'h21D0), // [15:13] sweep, [5:4] coarse
    .QPLL_LPF	                    (4'b1111),              //
    .QPLL_REFCLK_DIV	            (1),                    // default = 2

    //------------------------------------------------------
    .BIAS_CFG	                    (64'h0000000000000000), //
    .COMMON_CFG	                    (32'h00000000)          //

)
gtxe2_common_i 
(
       
    //---------- Clock -------------------------------------
    .GTGREFCLK                      (1'd0),                 //    
    .GTREFCLK0                      (QPLL_GTGREFCLK),       //
    .GTREFCLK1                      (1'd0),                 //
    .GTNORTHREFCLK0                 (1'd0),                 //
    .GTNORTHREFCLK1                 (1'd0),                 //
    .GTSOUTHREFCLK0                 (1'd0),                 //
    .GTSOUTHREFCLK1                 (1'd0),                 //
    .QPLLLOCKDETCLK                 (QPLL_QPLLLOCKDETCLK),  //
    .QPLLLOCKEN                     (1'd1),                 //
    .QPLLREFCLKSEL                  (3'd1),                 // Select GTREFCLK0
    .QPLLRSVD1                      (16'd0),                //
    .QPLLRSVD2                      (5'b11111),                 //
    
    .QPLLOUTCLK                     (QPLL_QPLLOUTCLK),      //
    .QPLLOUTREFCLK                  (QPLL_QPLLOUTREFCLK),   //
    .QPLLLOCK                       (QPLL_QPLLLOCK),        //
    .QPLLFBCLKLOST                  (),                     //
    .QPLLREFCLKLOST                 (),                     //
    .QPLLDMONITOR                   (),                     //
    
    //---------- Reset -------------------------------------
    .QPLLPD                         (QPLL_QPLLPD),          // 
    .QPLLRESET                      (QPLL_QPLLRESET),       //
    .QPLLOUTRESET                   (1'd0),                 //
    
    //---------- DRP ---------------------------------------
    .DRPCLK                         (QPLL_DRPCLK),          //
    .DRPADDR                        (QPLL_DRPADDR),         //
    .DRPEN                          (QPLL_DRPEN),           //
    .DRPDI                          (QPLL_DRPDI),           //
    .DRPWE                          (QPLL_DRPWE),           //
    
    .DRPDO                          (QPLL_DRPDO),           //
    .DRPRDY                         (QPLL_DRPRDY),          //
            
    //---------- Band Gap ----------------------------------    
    .BGBYPASS                       (1'd1),                 //
    .BGMONITOREN                    (1'd1),                 //
    .BGPDB                          (1'd1),                 //
    .BGRCALOVRD                     (5'd0),                 //
    
    //------------------------------------------------------
    .PMARSVD                        (8'd0),                 //
    .RCALENB                        (1'b0),                 //
    
    .REFCLKOUTMONITOR               ()                      //

);
 


endmodule
