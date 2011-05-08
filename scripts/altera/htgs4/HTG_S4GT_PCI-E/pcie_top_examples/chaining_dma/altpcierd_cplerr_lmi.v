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
// File          : altpcierd_cplerr_lmi.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module drives the cpl_err/err_desc signalling from the application
// to the PCIe Hard IP via the LMI interface.
//-----------------------------------------------------------------------------
// Copyright (c) 2009 Altera Corporation. All rights reserved.  Altera products are
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
module altpcierd_cplerr_lmi  (
   input             clk_in,
   input             rstn,
   input [127:0]     err_desc,            // TLP descriptor corresponding to cpl_err bits.  Written to AER header log when cpl_err[6] is asserted.
   input [6:0]       cpl_err_in,          // cpl_err bits from application.  edge sensitive inputs.
   input             lmi_ack,             // lmi read/write request acknowledge from core

   output reg[31:0]  lmi_din,             // lmi write data to core
   output reg[11:0]  lmi_addr,            // lmi address to core
   output reg        lmi_wren,            // lmi write request to core
   output reg [6:0]  cpl_err_out,         // cpl_err signal to core
   output            lmi_rden,            // lmi read request to core
   output reg        cplerr_lmi_busy      // 1'b1 means this module is busy writing cpl_err/err_desc  to the core.
                                          // transitions on cpl_err while this signal is high are ignored.
        );

   // cplerr_lmi_sm State Machine
   localparam        IDLE             = 3'h0;
   localparam        WAIT_LMI_WR_AER81C = 3'h1;
   localparam        WAIT_LMI_WR_AER820 = 3'h2;
   localparam        WAIT_LMI_WR_AER824 = 3'h3;
   localparam        WAIT_LMI_WR_AER828 = 3'h4;
   localparam        DRIVE_CPL_ERR    = 3'h5;

   reg [2:0]   cplerr_lmi_sm;
   reg [6:0]   cpl_err_reg;
   reg [127:0] err_desc_reg;

   reg         lmi_ack_reg;    // boundary register

   assign lmi_rden = 1'b0;   // not used

   wire[6:0] cpl_err_in_assert;

   assign cpl_err_in_assert = ~cpl_err_reg &  cpl_err_in;

   always @ (posedge clk_in or negedge rstn) begin
       if (rstn==1'b0) begin
           cplerr_lmi_sm   <= IDLE;
           cpl_err_reg     <= 7'h0;
           lmi_din         <= 32'h0;
           lmi_addr        <= 12'h0;
           lmi_wren        <= 1'b0;
           cpl_err_out     <= 7'h0;
           err_desc_reg    <= 128'h0;
           cplerr_lmi_busy <= 1'b0;
           lmi_ack_reg     <= 1'b0;
       end
       else begin
           lmi_ack_reg <= lmi_ack;

           // This State Machine controls LMI/cpl_err signalling to core.
           // When cpl_err[6] asserts, the err_desc is written to the
           // core's configuration space AER register via the LMI.
           // And then cpl_err is driven to the core.
           case (cplerr_lmi_sm)
               IDLE: begin
                   lmi_addr     <= 12'h81C;
                   lmi_din      <= err_desc[127:96];
                   cpl_err_reg  <= cpl_err_in;
                   err_desc_reg <= err_desc;
                   cpl_err_out  <= 7'h0;
                   // level sensitive
                   if (cpl_err_in_assert[6]==1'b1) begin
                        // log header via LMI
                        // in 1DW accesses
                        cplerr_lmi_sm   <= WAIT_LMI_WR_AER81C;
                        lmi_wren        <= 1'b1;
                        cplerr_lmi_busy <= 1'b1;
                   end
                   else if (cpl_err_in_assert != 7'h0) begin
                        // cpl_err to core
                        // without logging header
                        cplerr_lmi_sm   <= DRIVE_CPL_ERR;
                        lmi_wren        <= 1'b0;
                        cplerr_lmi_busy <= 1'b1;
                   end
                   else begin
                       cplerr_lmi_sm   <= cplerr_lmi_sm;
                       lmi_wren        <= 1'b0;
                       cplerr_lmi_busy <= 1'b0;
                   end
               end
               WAIT_LMI_WR_AER81C: begin
                   // wait for core to accept last LMI write
                   // before writing 2nd DWord of err_desc
                   if (lmi_ack_reg==1'b1) begin
                       cplerr_lmi_sm <= WAIT_LMI_WR_AER820;
                       lmi_addr      <= 12'h820;
                       lmi_din       <= err_desc_reg[95:64];
                       lmi_wren      <= 1'b1;
                   end
                   else begin
                       cplerr_lmi_sm <= cplerr_lmi_sm;
                       lmi_addr      <= lmi_addr;
                       lmi_din       <= lmi_din;
                       lmi_wren      <= 1'b0;
                   end
               end
               WAIT_LMI_WR_AER820: begin
                   // wait for core to accept last LMI write
                   // before writing 3rd DWord of err_desc
                   if (lmi_ack_reg==1'b1) begin
                       cplerr_lmi_sm <= WAIT_LMI_WR_AER824;
                       lmi_addr      <= 12'h824;
                       lmi_din       <= err_desc_reg[63:32];
                       lmi_wren      <= 1'b1;
                   end
                   else begin
                       cplerr_lmi_sm <= cplerr_lmi_sm;
                       lmi_addr      <= lmi_addr;
                       lmi_din       <= lmi_din;
                       lmi_wren      <= 1'b0;
                   end
               end
               WAIT_LMI_WR_AER824: begin
                   // wait for core to accept last LMI write
                   // before writing 4th DWord of err_desc
                   if (lmi_ack_reg==1'b1) begin
                       cplerr_lmi_sm <= WAIT_LMI_WR_AER828;
                       lmi_addr      <= 12'h828;
                       lmi_din       <= err_desc_reg[31:0];
                       lmi_wren      <= 1'b1;
                   end
                   else begin
                       cplerr_lmi_sm <= cplerr_lmi_sm;
                       lmi_addr      <= lmi_addr;
                       lmi_din       <= lmi_din;
                       lmi_wren      <= 1'b0;
                   end
               end
               WAIT_LMI_WR_AER828: begin
                   // wait for core to accept last LMI write
                   // before driving cpl_err bits
                   lmi_addr      <= lmi_addr;
                   lmi_din       <= lmi_din;
                   lmi_wren      <= 1'b0;
                   if (lmi_ack_reg==1'b1) begin
                       cplerr_lmi_sm <= DRIVE_CPL_ERR;
                   end
                   else begin
                       cplerr_lmi_sm <= cplerr_lmi_sm;
                   end
               end
               DRIVE_CPL_ERR: begin
                   // drive cpl_err bits to core
                   cpl_err_out     <= cpl_err_reg;
                   cplerr_lmi_sm   <= IDLE;
                   cplerr_lmi_busy <= 1'b0;
               end
           endcase
       end
   end




endmodule
