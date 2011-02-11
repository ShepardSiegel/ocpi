`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express PIPE PHY connector
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_pipe_phy.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This function interconnects two PIPE MAC interfaces for a single lane.
// For now this uses a common PCLK for both interfaces, an enhancement woudl be
// to support separate PCLK's for each interface with the requisite elastic
// buffer.
//-----------------------------------------------------------------------------
// Copyright (c) 2005 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation
// and therefore all warranties, representations or guarantees of any kind
// (whether express, implied or statutory) including, without limitation, warranties of
// merchantability, non-infringement, or fitness for a particular purpose, are
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------
module altpcietb_rst_clk (
           ref_clk_sel_code,
           ref_clk_out,
           pcie_rstn,
           ep_core_clk_out,
           rp_rstn
);

input [3:0] ref_clk_sel_code;

output       ref_clk_out;
output     pcie_rstn;
output     rp_rstn;
input      ep_core_clk_out;

integer   half_period;
reg     ref_clk_out;
reg     pcie_rstn;
reg     rp_rstn;

integer   core_clk_out_period;
integer   core_clk_cnt = 0;
integer   refclk_cnt = 0;
always @(ref_clk_sel_code)
  case (ref_clk_sel_code)
  4'h0: half_period = 5000;
  4'h1: half_period = 4000;
  4'h2: half_period = 3200;
  4'h3: half_period = 2000;
  default: half_period = 5000;
  endcase

  always
    #half_period  ref_clk_out <= ~ref_clk_out;

always @(posedge ref_clk_out)
  begin
  if (rp_rstn == 0)
    refclk_cnt <= 0;
  else
    refclk_cnt <= refclk_cnt + 1;

  if ((refclk_cnt == 200) & (core_clk_cnt > 10))
    $display("INFO: Core Clk Frequency: %5.2f Mhz",1000000/(half_period*2*200/core_clk_cnt));
  end


always @(posedge ep_core_clk_out)
  if (rp_rstn == 0)
    core_clk_cnt <= 0;
  else
    core_clk_cnt <= core_clk_cnt + 1;



  initial
    begin
      pcie_rstn         = 1'b1;
      rp_rstn           = 1'b0;
      ref_clk_out       = 1'b0;
      #1000
      pcie_rstn         = 1'b0;
      rp_rstn           = 1'b1;
      #1000
      rp_rstn           = 1'b0;
      #1000
      rp_rstn           = 1'b1;
      #1000
      rp_rstn           = 1'b0;
      #200000 pcie_rstn = 1'b1;
      #100000 rp_rstn   = 1'b1;
    end

endmodule

