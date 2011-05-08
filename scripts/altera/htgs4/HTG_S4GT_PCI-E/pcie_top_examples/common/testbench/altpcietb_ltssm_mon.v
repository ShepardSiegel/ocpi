`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express LTSSM monitor
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




module altpcietb_ltssm_mon (
             rp_clk,
             rstn,
             rp_ltssm,
             ep_ltssm,
             dummy_out
);

   `include "altpcietb_bfm_constants.v"
   `include "altpcietb_bfm_log.v"
   `include "altpcietb_bfm_shmem.v"
   `include "altpcietb_bfm_rdwr.v"

input rp_clk;
input rstn;
input [4:0] rp_ltssm;
input [4:0] ep_ltssm;
output       dummy_out;

reg [4:0] rp_ltssm_r;
reg [4:0] ep_ltssm_r;

task conv_ltssm;
   input device;
   input detect_timout;
   input [4:0] ltssm;
   reg[(23)*8:1] ltssm_str;
   reg dummy, dummy2 ;
   begin
   case (ltssm)
   5'b00000: ltssm_str = "DETECT.QUIET           ";
   5'b00001: ltssm_str = "DETECT.ACTIVE          ";
   5'b00010: ltssm_str = "POLLING.ACTIVE         ";
   5'b00011: ltssm_str = "POLLING.COMPLIANCE     ";
   5'b00100: ltssm_str = "POLLING.CONFIG         ";
   5'b00110: ltssm_str = "CONFIG.LINKWIDTH.START ";
   5'b00111: ltssm_str = "CONFIG.LINKWIDTH.ACCEPT";
   5'b01000: ltssm_str = "CONFIG.LANENUM.ACCEPT  ";
   5'b01001: ltssm_str = "CONFIG.LANENUM.WAIT    ";
   5'b01010: ltssm_str = "CONFIG.COMPLETE        ";
   5'b01011: ltssm_str = "CONFIG.IDLE            ";
   5'b01100: ltssm_str = "RECOVERY.RCVRLOCK      ";
   5'b01101: ltssm_str = "RECOVERY.RCVRCFG       ";
   5'b01110: ltssm_str = "RECOVERY.IDLE          ";
   5'b01111: ltssm_str = "L0                     ";
   5'b10000: ltssm_str = "DISABLE                ";
   5'b10001: ltssm_str = "LOOPBACK.ENTRY         ";
   5'b10010: ltssm_str = "LOOPBACK.ACTIVE        ";
   5'b10011: ltssm_str = "LOOPBACK.EXIT          ";
   5'b10100: ltssm_str = "HOT RESET              ";
   5'b10101: ltssm_str = "L0s                    ";
   5'b10110: ltssm_str = "L1.ENTRY               ";
   5'b10111: ltssm_str = "L1.IDLE                ";
   5'b11000: ltssm_str = "L2.IDLE                ";
   5'b11001: ltssm_str = "L2.TRANSMITWAKE        ";
   5'b11010: ltssm_str = "RECOVERY.SPEED         ";
   default: ltssm_str =  "UNKNOWN                ";
   endcase

   if (detect_timout==1)
     dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, { " LTSSM does not change from DETECT.QUIET"});
   else if (device == 0)
     dummy = ebfm_display(EBFM_MSG_INFO, { " RP LTSSM State: ", ltssm_str});
   else
     dummy = ebfm_display(EBFM_MSG_INFO, { " EP LTSSM State: ", ltssm_str});
   end

endtask
reg [3:0] detect_cnt;

always @(posedge rp_clk)
  begin
  rp_ltssm_r <= rp_ltssm;
  ep_ltssm_r <= ep_ltssm;
  if (rp_ltssm_r != rp_ltssm)
    conv_ltssm(0,0,rp_ltssm);
  if (ep_ltssm_r != ep_ltssm)
    conv_ltssm(1,0,ep_ltssm);
  end

always @ (posedge rp_clk or negedge rstn) begin
   if (rstn==1'b0) begin
      detect_cnt <= 4'h0;
   end
   else begin
      if (rp_ltssm_r != rp_ltssm) begin
         if (detect_cnt == 4'b1000) begin
            conv_ltssm(1,1,rp_ltssm);
         end
         else if (rp_ltssm==5'b01111) begin
            detect_cnt <= 4'h0;
         end
         else if (rp_ltssm==5'b00000) begin
            detect_cnt <= detect_cnt + 4'h1;
         end
      end
   end
end

endmodule

