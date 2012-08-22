//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: infrastructure.v
// /___/   /\     Date Last Modified: $Date: 2011/05/27 14:31:02 $
// \   \  /  \    Date Created:Tue Jun 30 2009
//  \___\/\___\
//
//Device: Virtex-6
//Design Name: DDR3 SDRAM
//Purpose:
//   Clock generation/distribution and reset synchronization
//Reference:
//Revision History:
//*****************************************************************************

/******************************************************************************
**$Id: infrastructure.v,v 1.8.6.3 2011/05/27 14:31:02 venkatp Exp $
**$Date: 2011/05/27 14:31:02 $
**$Author: venkatp $
**$Revision: 1.8.6.3 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_2/data/dlib/7series/ddr3_sdram/verilog/rtl/clocking/infrastructure.v,v $
******************************************************************************/

`timescale 1ps/1ps


module infrastructure #
  (
   parameter TCQ             = 100,      // clk->out delay (sim only)
   parameter CLKIN_PERIOD    = 3000,     // Memory clock period
   parameter nCK_PER_CLK     = 2,        // Fabric clk period:Memory clk period
   parameter INPUT_CLK_TYPE  = "DIFFERENTIAL", 
                                         // input clock type 
                                         // "DIFFERENTIAL","SINGLE_ENDED"
   parameter CLKFBOUT_MULT   = 4,        // write PLL VCO multiplier
   parameter DIVCLK_DIVIDE   = 1,        // write PLL VCO divisor
   parameter CLKOUT0_DIVIDE   = 16,      // VCO output divisor for clkout0
   parameter CLKOUT1_DIVIDE   = 4,       // VCO output divisor for clkout1
   parameter CLKOUT2_DIVIDE   = 64,      // VCO output divisor for clkout2
   parameter CLKOUT3_DIVIDE   = 16,      // VCO output divisor for clkout3
   parameter RST_ACT_LOW  = 1
   )
  (
   // Clock inputs
   input  mmcm_clk,          // System clock diff input
   // System reset input
   input  sys_rst,            // core reset from user application
   // PLLE2/IDELAYCTRL Lock status
   input  iodelay_ctrl_rdy,   // IDELAYCTRL lock status
   // Clock outputs
   
   output clk,                // fabric clock freq ; either  half rate or quarter rate and is
                              // determined by  PLL parameters settings.
   output mem_refclk,         // equal to  memory clock
   output freq_refclk,        // freq above 400 MHz:  set freq_refclk = mem_refclk
                              // freq below 400 MHz:  set freq_refclk = 2* mem_refclk or 4* mem_refclk;
                              // to hard PHY for phaser 
   output sync_pulse,          // exactly 1/16 of mem_refclk and the sync pulse is exactly 1 memref_clk wide
   
   output pll_locked,          // locked output from PLLE2_ADV
   // Reset outputs
   output rstdiv0            // Reset CLK and CLKDIV logic (incl I/O),
   );

  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on DCM lock status)
  localparam RST_SYNC_NUM = 15;

  // Round up for clk reset delay to ensure that CLKDIV reset deassertion
  // occurs at same time or after CLK reset deassertion (still need to
  // consider route delay - add one or two extra cycles to be sure!)
  localparam RST_DIV_SYNC_NUM = (RST_SYNC_NUM+1)/2;

  // Input clock is assumed to be equal to the memory clock frequency
  // User should change the parameter as necessary if a different input
  // clock frequency is used
  localparam real CLKIN1_PERIOD_NS = CLKIN_PERIOD / 1000.0;
  
  localparam integer VCO_PERIOD
             = (CLKIN1_PERIOD_NS * DIVCLK_DIVIDE * 1000) / CLKFBOUT_MULT;

  localparam CLKOUT0_PERIOD = VCO_PERIOD * CLKOUT0_DIVIDE;
  localparam CLKOUT1_PERIOD = VCO_PERIOD * CLKOUT1_DIVIDE;
  localparam CLKOUT2_PERIOD = VCO_PERIOD * CLKOUT2_DIVIDE;  
  localparam CLKOUT3_PERIOD = VCO_PERIOD * CLKOUT3_DIVIDE;  

  //synthesis translate_off
  initial begin
    $display("############# Write Clocks PLLE2_ADV Parameters #############\n");
    $display("nCK_PER_CLK      = %7d",   nCK_PER_CLK     );
    $display("CLK_PERIOD       = %7d",   CLKIN_PERIOD    );
    $display("CLKIN1_PERIOD    = %7.3f", CLKIN1_PERIOD_NS);
    $display("DIVCLK_DIVIDE    = %7d",   DIVCLK_DIVIDE   );
    $display("CLKFBOUT_MULT    = %7d",   CLKFBOUT_MULT );
    $display("VCO_PERIOD       = %7d",   VCO_PERIOD      );
    $display("CLKOUT0_DIVIDE_F = %7d",   CLKOUT0_DIVIDE  );
    $display("CLKOUT1_DIVIDE   = %7d",   CLKOUT1_DIVIDE  );
    $display("CLKOUT2_DIVIDE   = %7d",   CLKOUT2_DIVIDE  );
    $display("CLKOUT3_DIVIDE   = %7d",   CLKOUT3_DIVIDE  );
    $display("CLKOUT0_PERIOD   = %7d",   CLKOUT0_PERIOD  );
    $display("CLKOUT1_PERIOD   = %7d",   CLKOUT1_PERIOD  );
    $display("CLKOUT2_PERIOD   = %7d",   CLKOUT2_PERIOD  );
    $display("CLKOUT3_PERIOD   = %7d",   CLKOUT3_PERIOD  );
    $display("############################################################\n");
  end
  //synthesis translate_on

  wire                       clk_bufg;
  wire                       clk_pll;
  wire                       clkfbout_pll;
  wire                       mmcm_clkfbout;                          
  wire                       pll_lock
                             /* synthesis syn_maxfan = 10 */;
  reg [RST_DIV_SYNC_NUM-1:0] rstdiv0_sync_r
                             /* synthesis syn_maxfan = 10 */;
  wire                       rst_tmp;
  wire                       sys_rst_act_hi;

  assign sys_rst_act_hi = RST_ACT_LOW ? ~sys_rst: sys_rst;

  //***************************************************************************
  // Assign global clocks:
  //   2. clk     : Half rate / Quarter rate(used for majority of internal logic)
  //***************************************************************************

  assign clk     = clk_bufg;

  //***************************************************************************
  // Global base clock generation and distribution
  //***************************************************************************

  //*****************************************************************
  // NOTES ON CALCULTING PROPER VCO FREQUENCY
  //  1. VCO frequency = 
  //     1/((DIVCLK_DIVIDE * CLKIN_PERIOD)/(CLKFBOUT_MULT * nCK_PER_CLK))
  //  2. VCO frequency must be in the range [TBD, TBD]
  //*****************************************************************

  PLLE2_ADV #
    (
     .BANDWIDTH          ("OPTIMIZED"),
     .COMPENSATION       ("INTERNAL"),
     .STARTUP_WAIT       ("FALSE"),
     .CLKOUT0_DIVIDE     (CLKOUT0_DIVIDE),  // 4 freq_ref 
     .CLKOUT1_DIVIDE     (CLKOUT1_DIVIDE),  // 4 mem_ref
     .CLKOUT2_DIVIDE     (CLKOUT2_DIVIDE),  // 16 sync
     .CLKOUT3_DIVIDE     (CLKOUT3_DIVIDE),  // 16 sysclk
     .CLKOUT4_DIVIDE     (),
     .CLKOUT5_DIVIDE     (),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKFBOUT_MULT      (CLKFBOUT_MULT),
     .CLKFBOUT_PHASE     (0.000),
     .CLKIN1_PERIOD      (CLKIN1_PERIOD_NS),
     .CLKIN2_PERIOD      (CLKIN1_PERIOD_NS),
     .CLKOUT0_DUTY_CYCLE (0.500),
     .CLKOUT0_PHASE      (45.000),
     .CLKOUT1_DUTY_CYCLE (0.500),
     .CLKOUT1_PHASE      (0.000),
     .CLKOUT2_DUTY_CYCLE (1.0/16.0),
     .CLKOUT2_PHASE      (9.84375),     // PHASE shift is required for sync pulse generation.
     .CLKOUT3_DUTY_CYCLE (0.500),
     .CLKOUT3_PHASE      (0.000),
     .CLKOUT4_DUTY_CYCLE (0.500),
     .CLKOUT4_PHASE      (0.000),
     .CLKOUT5_DUTY_CYCLE (0.500),
     .CLKOUT5_PHASE      (0.000),
     .REF_JITTER1        (0.010),
     .REF_JITTER2        (0.010)
     ) 
    plle2_i 
      (
       .CLKFBOUT (mmcm_clkfbout),
       .CLKOUT0  (freq_refclk),
       .CLKOUT1  (mem_refclk),
       .CLKOUT2  (sync_pulse),  // always 1/16 of mem_ref_clk
       .CLKOUT3  (clk_pll),
       .CLKOUT4  (),      
       .CLKOUT5  (),
       .DO       (),
       .DRDY     (),
       .LOCKED   (pll_locked),
       .CLKFBIN  (mmcm_clkfbout),
       .CLKIN1   (mmcm_clk),
       .CLKIN2   (mmcm_clk),
       .CLKINSEL (1'b0),
       .DADDR    (7'b0),
       .DCLK     (1'b0),
       .DEN      (1'b0),
       .DI       (16'b0),
       .DWE      (1'b0),
       .PWRDWN   (1'b0),
       .RST      ( sys_rst_act_hi)
       );

  
  BUFG u_bufg_clkdiv0
    (
     .O (clk_bufg),
     .I (clk_pll)
     );

  //***************************************************************************
  // RESET SYNCHRONIZATION DESCRIPTION:
  //  Various resets are generated to ensure that:
  //   1. All resets are synchronously deasserted with respect to the clock
  //      domain they are interfacing to. There are several different clock
  //      domains - each one will receive a synchronized reset.
  //   2. The reset deassertion order starts with deassertion of SYS_RST,
  //      followed by deassertion of resets for various parts of the design
  //      (see "RESET ORDER" below) based on the lock status of PLLE2s.
  // RESET ORDER:
  //   1. User deasserts SYS_RST
  //   2. Reset PLLE2 and IDELAYCTRL
  //   3. Wait for PLLE2 and IDELAYCTRL to lock
  //   4. Release reset for all I/O primitives and internal logic
  // OTHER NOTES:
  //   1. Asynchronously assert reset. This way we can assert reset even if
  //      there is no clock (needed for things like 3-stating output buffers
  //      to prevent initial bus contention). Reset deassertion is synchronous.
  //***************************************************************************

  //*****************************************************************
  // CLKDIV logic reset
  //*****************************************************************

  // Wait for PLLE2 and IDELAYCTRL to lock before releasing reset
  
  // current O,25.0 unisim phaser_ref never locks.  Need to find out why .
  assign rst_tmp = sys_rst_act_hi | ~pll_locked | ~iodelay_ctrl_rdy;

  always @(posedge clk_bufg or posedge rst_tmp)
    if (rst_tmp)
      rstdiv0_sync_r <= #TCQ {RST_DIV_SYNC_NUM{1'b1}};
    else
      rstdiv0_sync_r <= #TCQ rstdiv0_sync_r << 1;

  assign rstdiv0 = rstdiv0_sync_r[RST_DIV_SYNC_NUM-1];

endmodule
