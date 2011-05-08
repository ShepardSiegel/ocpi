// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It arbitrates PCI Express packets for
//  * the modules altpcierd_dma_dt (read or write) and altpcierd_rc_slave. It
//  * instantiates the Endpoint memory used for the DMA read and write transfer.
//  */
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030

//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_pcie_reconfig_initiator.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This is the complete example application for the PCI Express Reference
// Design. This has all of the application logic for the example.
//-----------------------------------------------------------------------------
// Copyright © 2009 Altera Corporation. All rights reserved.  Altera products are
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
module altpcierd_pcie_reconfig_initiator
    (
  output reg [  7: 0]   avs_pcie_reconfig_address,
  output reg            avs_pcie_reconfig_chipselect,
  output reg            avs_pcie_reconfig_write,
  output reg [ 15: 0]   avs_pcie_reconfig_writedata,
  input                 avs_pcie_reconfig_waitrequest,
  output reg            avs_pcie_reconfig_read,
  input [15: 0]         avs_pcie_reconfig_readdata,
  input                 avs_pcie_reconfig_readdatavalid,
  output                avs_pcie_reconfig_clk,
  output                avs_pcie_reconfig_rstn,

  input                 pcie_rstn,
  input                 set_pcie_reconfig,
  input                 pcie_reconfig_clk,
  output                pcie_reconfig_busy
);

localparam IDLE_ST                  =0,
           ENABLE_PCIE_RECONFIG_ST  =1,
           READ_VENDOR_ID_ST        =2,
           VENDOR_ID_UPD_ST         =3,
           WRITE_VENDOR_ID_ST       =4,
           PCIE_RECONFIG_DONE_ST    =5;

reg [2:0] cstate;
reg [2:0] nstate;
reg [2:0] pcie_rstn_sync /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102 ; SUPPRESS_DA_RULE_INTERNAL=R101"  */;

   assign pcie_reconfig_busy = (cstate==PCIE_RECONFIG_DONE_ST)?1'b0:1'b1;
   assign avs_pcie_reconfig_rstn = pcie_rstn_sync[2];
   assign avs_pcie_reconfig_clk = pcie_reconfig_clk;

   always @*
   case (cstate)
      IDLE_ST:
         if (set_pcie_reconfig==1'b1) begin
            if (pcie_rstn_sync[2]==1'b1)
               nstate = ENABLE_PCIE_RECONFIG_ST;
            else
               nstate = IDLE_ST;
            end
         else
            nstate = PCIE_RECONFIG_DONE_ST;

      ENABLE_PCIE_RECONFIG_ST:
         if (avs_pcie_reconfig_waitrequest==1'b0)
            nstate = READ_VENDOR_ID_ST;
          else
            nstate = ENABLE_PCIE_RECONFIG_ST;

      READ_VENDOR_ID_ST:
         if (avs_pcie_reconfig_waitrequest==1'b0)
            nstate = VENDOR_ID_UPD_ST;
          else
            nstate = READ_VENDOR_ID_ST;

      VENDOR_ID_UPD_ST:
         nstate = WRITE_VENDOR_ID_ST;

      WRITE_VENDOR_ID_ST:
         if (avs_pcie_reconfig_waitrequest==1'b0)
            nstate = PCIE_RECONFIG_DONE_ST;
          else
            nstate = WRITE_VENDOR_ID_ST;

      PCIE_RECONFIG_DONE_ST:
            nstate = PCIE_RECONFIG_DONE_ST;

      default:
         nstate = IDLE_ST;

   endcase

   always @ (negedge pcie_rstn_sync[2] or posedge pcie_reconfig_clk) begin
      if (pcie_rstn_sync[2]==1'b0) begin
         avs_pcie_reconfig_address     <=8'h0;
         avs_pcie_reconfig_chipselect  <=1'b0;
         avs_pcie_reconfig_write       <=1'b0;
         avs_pcie_reconfig_writedata   <=16'h0;
         avs_pcie_reconfig_read        <=1'b0;
      end
      else begin
         if (cstate==ENABLE_PCIE_RECONFIG_ST)
            avs_pcie_reconfig_address     <=8'h0;
         else
            avs_pcie_reconfig_address     <={1'b1, 7'h09}; //Vendor ID

         if (cstate==ENABLE_PCIE_RECONFIG_ST)
            avs_pcie_reconfig_writedata <= (set_pcie_reconfig==1'b1)?16'h0:16'h1;
         else if (avs_pcie_reconfig_readdatavalid==1'b1)
            avs_pcie_reconfig_writedata <= avs_pcie_reconfig_readdata+1;

         if (cstate==READ_VENDOR_ID_ST) begin
            if (avs_pcie_reconfig_waitrequest==1'b1) begin
               avs_pcie_reconfig_chipselect  <=1'b1;
               avs_pcie_reconfig_read        <=1'b1;
            end
            else begin
               avs_pcie_reconfig_chipselect  <=1'b0;
               avs_pcie_reconfig_read        <=1'b0;
            end
            avs_pcie_reconfig_write       <=1'b0;
         end
         else if ((cstate==WRITE_VENDOR_ID_ST) ||
                        (cstate==ENABLE_PCIE_RECONFIG_ST)) begin
            if (avs_pcie_reconfig_waitrequest==1'b1) begin
               avs_pcie_reconfig_chipselect  <=1'b1;
               avs_pcie_reconfig_write       <=1'b1;
            end
            else begin
               avs_pcie_reconfig_chipselect  <=1'b0;
               avs_pcie_reconfig_write       <=1'b0;
            end
            avs_pcie_reconfig_read        <=1'b0;
         end
         else begin
            avs_pcie_reconfig_chipselect  <=1'b0;
            avs_pcie_reconfig_write       <=1'b0;
            avs_pcie_reconfig_read        <=1'b0;
         end
      end
   end

   always @ (negedge pcie_rstn_sync[2] or posedge pcie_reconfig_clk) begin
      if (pcie_rstn_sync[2]==1'b0)
         cstate <= IDLE_ST;
      else
         cstate <= nstate;
   end

   always @ (negedge pcie_rstn or posedge pcie_reconfig_clk) begin
      if (pcie_rstn==1'b0)
         pcie_rstn_sync <= 3'b000;
      else  begin
         pcie_rstn_sync[0]<=1'b1;
         pcie_rstn_sync[1]<=pcie_rstn_sync[0];
         pcie_rstn_sync[2]<=pcie_rstn_sync[1];
      end
   end

endmodule


