// (c) Copyright 2006-2009 Xilinx, Inc. All rights reserved.
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
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: 3.4
//  \   \         Application: MIG
//  /   /         Filename: ddr2_infrastructure.v
// /___/   /\     Date Last Modified: $Date: 2009/11/03 04:43:17 $
// \   \  /  \    Date Created: Wed Aug 16 2006
//  \___\/\___\
//
//Device: Virtex-5
//Design Name: DDR2
//Purpose:
//   Clock generation/distribution and reset synchronization
//Reference:
//Revision History:
//   Rev 1.1 - Parameter CLK_TYPE added and logic for  DIFFERENTIAL and
//             SINGLE_ENDED added. PK. 6/20/08
//   Rev 1.2 - Loacalparam CLK_GENERATOR added and logic for clocks generation
//             using PLL or DCM added as generic code. PK. 10/14/08
//   Rev 1.3 - Added parameter NOCLK200 with default value '0'. Used for
//             controlling the instantiation of IBUFG for clk200. jul/03/09
//*****************************************************************************

`timescale 1ns/1ps

module ddr2_infrastructure #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference
   // board design). Actual values may be different. Actual parameters values
   // are passed from design top module mig_v3_4 module. Please refer to
   // the mig_v3_4 module for actual values.
   parameter CLK_PERIOD    = 3000,
   parameter CLK_TYPE      = "DIFFERENTIAL",
   parameter DLL_FREQ_MODE = "HIGH",
   parameter NOCLK200      = 0,
   parameter RST_ACT_LOW  = 1
   )
  (
   input  sys_clk_p,
   input  sys_clk_n,
   input  sys_clk,
   input  clk200_p,
   input  clk200_n,
   input  idly_clk_200,
   output clk0,
   output clk90,
   output clk200,
   output clkdiv0,
   input  sys_rst_n,
   input  idelay_ctrl_rdy,
   output rst0,
   output rst90,
   output rst200,
   output rstdiv0
   );

  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on PLL/DCM lock status)
  localparam RST_SYNC_NUM = 25;
  localparam CLK_PERIOD_NS = CLK_PERIOD / 1000.0;
  localparam CLK_PERIOD_INT = CLK_PERIOD/1000;

  // By default this Parameter (CLK_GENERATOR) value is "PLL". If this
  // Parameter is set to "PLL", PLL is used to generate the design clocks.
  // If this Parameter is set to "DCM",
  // DCM is used to generate the design clocks.
  localparam CLK_GENERATOR = "PLL";

  wire                       clk0_bufg;
  wire                       clk0_bufg_in;
  wire                       clk90_bufg;
  wire                       clk90_bufg_in;
  wire                       clk200_bufg;
  wire                       clk200_ibufg;
  wire                       clkdiv0_bufg;
  wire                       clkdiv0_bufg_in;
  wire                       clkfbout_clkfbin;
  wire                       locked;
  reg [RST_SYNC_NUM-1:0]     rst0_sync_r    /* synthesis syn_maxfan = 10 */;
  reg [RST_SYNC_NUM-1:0]     rst200_sync_r  /* synthesis syn_maxfan = 10 */;
  reg [RST_SYNC_NUM-1:0]     rst90_sync_r   /* synthesis syn_maxfan = 10 */;
  reg [(RST_SYNC_NUM/2)-1:0] rstdiv0_sync_r /* synthesis syn_maxfan = 10 */;
  wire                       rst_tmp;
  wire                       sys_clk_ibufg;
  wire                       sys_rst;

  assign sys_rst = RST_ACT_LOW ? ~sys_rst_n: sys_rst_n;

  assign clk0    = clk0_bufg;
  assign clk90   = clk90_bufg;
  assign clk200  = clk200_bufg;
  assign clkdiv0 = clkdiv0_bufg;

  generate
  if(CLK_TYPE == "DIFFERENTIAL") begin : DIFF_ENDED_CLKS_INST
    //***************************************************************************
    // Differential input clock input buffers
    //***************************************************************************

    IBUFGDS_LVPECL_25 SYS_CLK_INST
      (
       .I  (sys_clk_p),
       .IB (sys_clk_n),
       .O  (sys_clk_ibufg)
       );

    IBUFGDS_LVPECL_25 IDLY_CLK_INST
      (
       .I  (clk200_p),
       .IB (clk200_n),
       .O  (clk200_ibufg)
       );

  end else if(CLK_TYPE == "SINGLE_ENDED") begin : SINGLE_ENDED_CLKS_INST
    //**************************************************************************
    // Single ended input clock input buffers
    //**************************************************************************

    IBUFG SYS_CLK_INST
      (
       .I  (sys_clk),
       .O  (sys_clk_ibufg)
       );
    if ( NOCLK200 == 0 ) begin : IBUFG_INST
        IBUFG IDLY_CLK_INST
          (
           .I  (idly_clk_200),
           .O  (clk200_ibufg)
           );
    end

  end
  endgenerate

  generate
    if ( ((NOCLK200 == 0) && (CLK_TYPE == "SINGLE_ENDED")) || (CLK_TYPE == "DIFFERENTIAL") ) begin : BUFG_INST
      BUFG CLK_200_BUFG
        (
         .O (clk200_bufg),
         .I (clk200_ibufg)
         );
    end else begin : NO_BUFG
      assign clk200_bufg = 1'b0;
    end
  endgenerate

  //***************************************************************************
  // Global clock generation and distribution
  //***************************************************************************

  generate
    if (CLK_GENERATOR == "PLL") begin : gen_pll_adv
      PLL_ADV #
        (
         .BANDWIDTH          ("OPTIMIZED"),
         .CLKIN1_PERIOD      (CLK_PERIOD_NS),
         .CLKIN2_PERIOD      (10.000),
         .CLKOUT0_DIVIDE     (CLK_PERIOD_INT),
         .CLKOUT1_DIVIDE     (CLK_PERIOD_INT),
         .CLKOUT2_DIVIDE     (CLK_PERIOD_INT*2),
         .CLKOUT3_DIVIDE     (1),
         .CLKOUT4_DIVIDE     (1),
         .CLKOUT5_DIVIDE     (1),
         .CLKOUT0_PHASE      (0.000),
         .CLKOUT1_PHASE      (90.000),
         .CLKOUT2_PHASE      (0.000),
         .CLKOUT3_PHASE      (0.000),
         .CLKOUT4_PHASE      (0.000),
         .CLKOUT5_PHASE      (0.000),
         .CLKOUT0_DUTY_CYCLE (0.500),
         .CLKOUT1_DUTY_CYCLE (0.500),
         .CLKOUT2_DUTY_CYCLE (0.500),
         .CLKOUT3_DUTY_CYCLE (0.500),
         .CLKOUT4_DUTY_CYCLE (0.500),
         .CLKOUT5_DUTY_CYCLE (0.500),
         .COMPENSATION       ("SYSTEM_SYNCHRONOUS"),
         .DIVCLK_DIVIDE      (1),
         .CLKFBOUT_MULT      (CLK_PERIOD_INT),
         .CLKFBOUT_PHASE     (0.0),
         .REF_JITTER         (0.005000)
         )
        u_pll_adv
          (
           .CLKFBIN     (clkfbout_clkfbin),
           .CLKINSEL    (1'b1),
           .CLKIN1      (sys_clk_ibufg),
           .CLKIN2      (1'b0),
           .DADDR       (5'b0),
           .DCLK        (1'b0),
           .DEN         (1'b0),
           .DI          (16'b0),
           .DWE         (1'b0),
           .REL         (1'b0),
           .RST         (sys_rst),
           .CLKFBDCM    (),
           .CLKFBOUT    (clkfbout_clkfbin),
           .CLKOUTDCM0  (),
           .CLKOUTDCM1  (),
           .CLKOUTDCM2  (),
           .CLKOUTDCM3  (),
           .CLKOUTDCM4  (),
           .CLKOUTDCM5  (),
           .CLKOUT0     (clk0_bufg_in),
           .CLKOUT1     (clk90_bufg_in),
           .CLKOUT2     (clkdiv0_bufg_in),
           .CLKOUT3     (),
           .CLKOUT4     (),
           .CLKOUT5     (),
           .DO          (),
           .DRDY        (),
           .LOCKED      (locked)
           );
    end else if (CLK_GENERATOR == "DCM") begin: gen_dcm_base
      DCM_BASE #
        (
         .CLKIN_PERIOD          (CLK_PERIOD_NS),
         .CLKDV_DIVIDE          (2.0),
         .DLL_FREQUENCY_MODE    (DLL_FREQ_MODE),
         .DUTY_CYCLE_CORRECTION ("TRUE"),
         .FACTORY_JF            (16'hF0F0)
         )
        u_dcm_base
          (
           .CLK0      (clk0_bufg_in),
           .CLK180    (),
           .CLK270    (),
           .CLK2X     (),
           .CLK2X180  (),
           .CLK90     (clk90_bufg_in),
           .CLKDV     (clkdiv0_bufg_in),
           .CLKFX     (),
           .CLKFX180  (),
           .LOCKED    (locked),
           .CLKFB     (clk0_bufg),
           .CLKIN     (sys_clk_ibufg),
           .RST       (sys_rst)
           );
    end
  endgenerate

  BUFG U_BUFG_CLK0
    (
     .O (clk0_bufg),
     .I (clk0_bufg_in)
     );

  BUFG U_BUFG_CLK90
    (
     .O (clk90_bufg),
     .I (clk90_bufg_in)
     );

   BUFG U_BUFG_CLKDIV0
    (
     .O (clkdiv0_bufg),
     .I (clkdiv0_bufg_in)
     );


  //***************************************************************************
  // Reset synchronization
  // NOTES:
  //   1. shut down the whole operation if the PLL/ DCM hasn't yet locked (and
  //      by inference, this means that external SYS_RST_IN has been asserted -
  //      PLL/DCM deasserts LOCKED as soon as SYS_RST_IN asserted)
  //   2. In the case of all resets except rst200, also assert reset if the
  //      IDELAY master controller is not yet ready
  //   3. asynchronously assert reset. This was we can assert reset even if
  //      there is no clock (needed for things like 3-stating output buffers).
  //      reset deassertion is synchronous.
  //***************************************************************************

  assign rst_tmp = sys_rst | ~locked | ~idelay_ctrl_rdy;

  // synthesis attribute max_fanout of rst0_sync_r is 10
  always @(posedge clk0_bufg or posedge rst_tmp)
    if (rst_tmp)
      rst0_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      // logical left shift by one (pads with 0)
      rst0_sync_r <= rst0_sync_r << 1;

  // synthesis attribute max_fanout of rstdiv0_sync_r is 10
  always @(posedge clkdiv0_bufg or posedge rst_tmp)
    if (rst_tmp)
      rstdiv0_sync_r <= {(RST_SYNC_NUM/2){1'b1}};
    else
      // logical left shift by one (pads with 0)
      rstdiv0_sync_r <= rstdiv0_sync_r << 1;

  // synthesis attribute max_fanout of rst90_sync_r is 10
  always @(posedge clk90_bufg or posedge rst_tmp)
    if (rst_tmp)
      rst90_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      rst90_sync_r <= rst90_sync_r << 1;

  // make sure CLK200 doesn't depend on IDELAY_CTRL_RDY, else chicken n' egg
  // synthesis attribute max_fanout of rst200_sync_r is 10
  always @(posedge clk200_bufg or negedge locked)
    if (!locked)
      rst200_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      rst200_sync_r <= rst200_sync_r << 1;


  assign rst0    = rst0_sync_r[RST_SYNC_NUM-1];
  assign rst90   = rst90_sync_r[RST_SYNC_NUM-1];
  assign rst200  = rst200_sync_r[RST_SYNC_NUM-1];
  assign rstdiv0 = rstdiv0_sync_r[(RST_SYNC_NUM/2)-1];

endmodule
