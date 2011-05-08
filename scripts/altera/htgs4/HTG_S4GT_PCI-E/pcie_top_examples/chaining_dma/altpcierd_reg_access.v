// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It contains the descriptor header
//  * table registers which get programmed by the software application.
//  */
// synthesis translate_off
`include "altpcierd_dma_dt_cst_sim.v"
`timescale 1ns / 1ps
// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030

//-----------------------------------------------------------------------------
// Title         : altpcierd_ctl_sts_regs
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_ctl_sts_regs.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
//
//  Description:  This module contains the Address decoding for BAR2/3
//                address space.
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


module altpcierd_reg_access   (
   input             clk_in,
   input             rstn,
   input             sel_ep_reg,
   input             reg_wr_ena,         // pulse.  register write enable
   input             reg_rd_ena,
   input [7:0]       reg_rd_addr,        // register byte address (BAR 2/3 is 128 bytes max)
   input [7:0]       reg_wr_addr,
   input [31:0]      reg_wr_data,        // register data to be written
   input [31:0]      dma_rd_prg_rddata,
   input [31:0]      dma_wr_prg_rddata,
   input [15:0]      rx_ecrc_bad_cnt,
   input [63:0]      read_dma_status,
   input [63:0]      write_dma_status,

   output reg [31:0] reg_rd_data,        // register read data
   output reg        reg_rd_data_valid,  // pulse.  means reg_rd_data is valid
   output reg [31:0] dma_prg_wrdata,
   output reg [3:0]  dma_prg_addr,       // byte address
   output reg        dma_rd_prg_wrena,
   output reg        dma_wr_prg_wrena
   );


   // Module Address Decode - 2 MSB's

   localparam DMA_WRITE_PRG = 4'h0;
   localparam DMA_READ_PRG  = 4'h1;
   localparam MISC          = 4'h2;
   localparam ERR_STATUS    = 4'h3;

   // MISC address space
   localparam WRITE_DMA_STATUS_REG_HI = 4'h0;
   localparam WRITE_DMA_STATUS_REG_LO = 4'h4;
   localparam READ_DMA_STATUS_REG_HI  = 4'h8;
   localparam READ_DMA_STATUS_REG_LO  = 4'hc;


   reg [31:0] err_status_reg;
   reg [63:0] read_dma_status_reg;
   reg [63:0] write_dma_status_reg;
   reg [31:0] dma_rd_prg_rddata_reg;
   reg [31:0] dma_wr_prg_rddata_reg;

   reg             reg_wr_ena_reg;
   reg             reg_rd_ena_reg;
   reg [7:0]       reg_rd_addr_reg;
   reg [7:0]       reg_wr_addr_reg;
   reg [31:0]      reg_wr_data_reg;
   reg             sel_ep_reg_reg;
   reg             reg_rd_ena_reg2;
   reg             reg_rd_ena_reg3;

   // Pipeline input data for performance
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          err_status_reg       <= 32'h0;
          read_dma_status_reg  <= 64'h0;
          write_dma_status_reg <= 64'h0;
          reg_wr_ena_reg       <= 1'b0;
          reg_rd_ena_reg       <= 1'b0;
          reg_rd_ena_reg2      <= 1'b0;
          reg_rd_ena_reg3      <= 1'b0;
          reg_rd_addr_reg      <= 8'h0;
          reg_wr_addr_reg      <= 8'h0;
          reg_wr_data_reg      <= 32'h0;
          sel_ep_reg_reg       <= 1'b0;
          dma_rd_prg_rddata_reg <= 32'h0;
          dma_wr_prg_rddata_reg <= 32'h0;
      end
      else begin
          err_status_reg       <= {16'h0, rx_ecrc_bad_cnt};
          read_dma_status_reg  <= read_dma_status;
          write_dma_status_reg <= write_dma_status;
          reg_wr_ena_reg       <= reg_wr_ena & sel_ep_reg;
          reg_rd_ena_reg       <= reg_rd_ena & sel_ep_reg;
          reg_rd_ena_reg2      <= reg_rd_ena_reg;
          reg_rd_ena_reg3      <= reg_rd_ena_reg2;
          reg_rd_addr_reg      <= reg_rd_addr;
          reg_wr_addr_reg      <= reg_wr_addr;
          reg_wr_data_reg      <= reg_wr_data;
          dma_rd_prg_rddata_reg <= dma_rd_prg_rddata;
          dma_wr_prg_rddata_reg <= dma_wr_prg_rddata;
      end
   end

   // Register Access
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          reg_rd_data       <= 32'h0;
          reg_rd_data_valid <= 1'b0;
          dma_prg_wrdata    <= 32'h0;
          dma_prg_addr      <= 4'h0;
          dma_rd_prg_wrena  <= 1'b0;
          dma_wr_prg_wrena  <= 1'b0;
      end
      else begin
          //////////
          // WRITE

          dma_prg_wrdata    <= reg_wr_data_reg;
          dma_prg_addr      <= reg_wr_addr_reg[3:0];
          dma_rd_prg_wrena  <= ((reg_wr_ena_reg==1'b1) & (reg_wr_addr_reg[7:4] == DMA_READ_PRG))  ? 1'b1 : 1'b0;
          dma_wr_prg_wrena  <= ((reg_wr_ena_reg==1'b1) & (reg_wr_addr_reg[7:4] == DMA_WRITE_PRG)) ? 1'b1 : 1'b0;

          //////////
          // READ


          case (reg_rd_addr_reg[7:0])
              {MISC, WRITE_DMA_STATUS_REG_HI}: reg_rd_data <= write_dma_status_reg[63:32];
              {MISC, WRITE_DMA_STATUS_REG_LO}: reg_rd_data <= write_dma_status_reg[31:0];
              {MISC, READ_DMA_STATUS_REG_HI} : reg_rd_data <= read_dma_status_reg[63:32];
              {MISC, READ_DMA_STATUS_REG_LO} : reg_rd_data <= read_dma_status_reg[31:0];
              {ERR_STATUS, 4'h0}             : reg_rd_data <= err_status_reg;
              {DMA_WRITE_PRG, 4'h0},
              {DMA_WRITE_PRG, 4'h4},
              {DMA_WRITE_PRG, 4'h8},
              {DMA_WRITE_PRG, 4'hC}          : reg_rd_data <= dma_wr_prg_rddata_reg;
              {DMA_READ_PRG, 4'h0},
              {DMA_READ_PRG, 4'h4},
              {DMA_READ_PRG, 4'h8},
              {DMA_READ_PRG, 4'hC}           : reg_rd_data <= dma_rd_prg_rddata_reg;
              default                        : reg_rd_data <= 32'h0;
          endcase

          case (reg_rd_addr_reg[7:4])
              DMA_WRITE_PRG: reg_rd_data_valid <= reg_rd_ena_reg3;
              DMA_READ_PRG : reg_rd_data_valid <= reg_rd_ena_reg3;
              default      : reg_rd_data_valid <= reg_rd_ena_reg;
          endcase
      end
   end


endmodule
