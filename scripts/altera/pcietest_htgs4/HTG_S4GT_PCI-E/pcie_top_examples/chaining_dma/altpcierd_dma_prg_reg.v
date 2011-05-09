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
// Title         : DMA register setting (altpcierd_dma_prg_reg)
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_dma_prg_reg.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
//
// DMA Write register DIRECTION = "write"
// EP Addr           |                |
// rx_desc_addr[4:0] |                |
//-------------------|----------------|----------------
// 0h  0b00000       | DW0 (size)     | rx_data[31:0]
// 04h 0b00100       | DW1 (BDT Msb)  | rx_data[63:32]
// 08h 0b01000       | DW2 (BDT Lsb)  | rx_data[31:0]
// 0ch 0b01100       | DW3 RCLast     | rx_data[63:32]
//
// DMA Read register DIRECTION = "read"
// EP Addr           |                |
// rx_desc_addr[4:0] |                |
//-------------------|----------------|----------------
// 1h  0b10000       | DW0 (size)     | rx_data[31:0]
// 14h 0b10100       | DW1 (BDT Msb)  | rx_data[63:32]
// 18h 0b11000       | DW2 (BDT Lsb)  | rx_data[31:0]
// 1ch 0b11100       | DW3 RCLast     | rx_data[63:32]
//
// Key signals:
//       - init : reset all other DMA module
//               writing 0xFFFF in DW0 set init
//               writing valid DW3 clear init (e.g RCLast <size)
//       |31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16|15 .................0
//   ----|---------------------------------------------------------------------
//       | R|        |         |              |  | E|M| D |
//   DW0 | E| MSI    |         |              |  | P|S| I |
//       | R|TRAFFIC |         |              |  | L|I| R |
//       | U|CLASS   | RESERVED|  MSI         |1 | A| | E |      SIZE:Number
//       | N|        |         |  NUMBER      |  | S| | C |   of DMA descriptor
//       | D|        |         |              |  | T| | T |
//       | M|        |         |              |  |  | | I |
//       | A|        |         |              |  |  | | O |
//       |  |        |         |              |  |  | | N |
//   ----|---------------------------------------------------------------------
//   DW1 |                     BDT_MSB
//   ----|---------------------------------------------------------------------
//   DW2 |                   DT_LSB
//   ----|---------------------------------------------------------------------
//   DW3 |                                                | RC Last
//   ----|---------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////
//
// NOTE:
//      1- This module always issues RX_ACK when RX TLP = Message Request
//         (TYPE[4:3] == 2'b10)
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
module altpcierd_dma_prg_reg #(
   parameter RC_64BITS_ADDR = 0,
   parameter AVALON_ST_128  = 0   )
   (
   input          clk_in,
   input          rstn,
   input          dma_prg_wrena,
   input[31:0]    dma_prg_wrdata,
   input[3:0]     dma_prg_addr,
   output reg [31:0] dma_prg_rddata,

   output reg [15:0] dt_rc_last,        // last value of the descriptor written by the rc
   output reg        dt_rc_last_sync,   // Toggling sync bit to indicate to re-run DMA
                                        // When 1 the DMA restart from the first descriptor
                                        // When 0 the DMA stops
   output reg  [15:0] dt_size,          // Descriptor table size (the number of descriptor)
   output reg  [63:0] dt_base_rc,       // Descriptor table base address in the RC site
   output reg         dt_eplast_ena,    // Status bit to update the eplast ister in the rc memeory
   output reg         dt_msi,           // Status bit to reflect use of MSI
   output reg         dt_3dw_rcadd,     // Return 1 if dt_base_rc[63:32] == 0
   output reg  [4:0]  app_msi_num,      // MSI TC and MSI Number
   output reg  [2:0]  app_msi_tc ,
   output reg         init              // high when reset state or before any transaction
   );

   // Register Address Decode
   localparam EP_ADDR_DW0 = 2'b00;
   localparam EP_ADDR_DW1 = 2'b01;
   localparam EP_ADDR_DW2 = 2'b10;
   localparam EP_ADDR_DW3 = 2'b11;

   // soft_dma_reset : DMA reset controlled by software
   reg        soft_dma_reset;
   reg        init_shift;
   reg [31:0] prg_reg_DW0;
   reg [31:0] prg_reg_DW1;
   reg [31:0] prg_reg_DW2;
   reg [31:0] prg_reg_DW3;
   reg        prg_reg_DW1_is_zero;

   reg        dma_prg_wrena_reg;
   reg[31:0]  dma_prg_wrdata_reg;
   reg[3:0]   dma_prg_addr_reg;

   // Generate DMA resets
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         soft_dma_reset <= 1'b1;
         init_shift     <= 1'b1;
         init           <= 1'b1;
         dma_prg_wrena_reg  <= 1'b0;
         dma_prg_wrdata_reg <= 32'h0;
         dma_prg_addr_reg   <= 4'h0;
      end
      else begin
          init              <= init_shift;
         dma_prg_wrena_reg  <= dma_prg_wrena;
         dma_prg_wrdata_reg <= dma_prg_wrdata;
         dma_prg_addr_reg   <= dma_prg_addr;

          // write 1's to Address 0 to clear all regs
          soft_dma_reset <= (dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2]==EP_ADDR_DW0) & (dma_prg_wrdata_reg[15:0]==16'hFFFF);

          // assert init on a reset
          // deassert init when the last (3rd) Prg Reg is written
          if (soft_dma_reset==1'b1)
              init_shift <= 1'b1;
          else if ((dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2]==EP_ADDR_DW3))
              init_shift <= 1'b0;
      end
   end

   // DMA Programming Register Write
   always @ (posedge clk_in) begin
      if (soft_dma_reset == 1'b1) begin
         prg_reg_DW0         <= 32'h0;
         prg_reg_DW1         <= 32'h0;
         prg_reg_DW2         <= 32'h0;
         prg_reg_DW3         <= 32'h0;
         prg_reg_DW1_is_zero <= 1'b1;
         dt_size             <= 16'h0;
         dt_msi              <= 1'b0;
         dt_eplast_ena       <= 1'b0;
         app_msi_num         <= 5'h0;
         app_msi_tc          <= 3'h0;
         dt_rc_last_sync     <= 1'b0;
         dt_base_rc          <= 64'h0;
         dt_3dw_rcadd        <= 1'b0;
         dt_rc_last[15:0]    <= 16'h0;
         dma_prg_rddata      <= 32'h0;
      end
      else begin
          // Registers
          prg_reg_DW0 <= ((dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2] == EP_ADDR_DW0)) ? dma_prg_wrdata_reg : prg_reg_DW0; // Header register DW0
          prg_reg_DW1 <= ((dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2] == EP_ADDR_DW1)) ? dma_prg_wrdata_reg : prg_reg_DW1; // Header register DW1
          prg_reg_DW2 <= ((dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2] == EP_ADDR_DW2)) ? dma_prg_wrdata_reg : prg_reg_DW2; // Header register DW2
          prg_reg_DW3 <= ((dma_prg_wrena_reg==1'b1) & (dma_prg_addr_reg[3:2] == EP_ADDR_DW3)) ? dma_prg_wrdata_reg : prg_reg_DW3; // Header register DW3

          case (dma_prg_addr_reg[3:2])
              EP_ADDR_DW0: dma_prg_rddata <= prg_reg_DW0;
              EP_ADDR_DW1: dma_prg_rddata <= prg_reg_DW1;
              EP_ADDR_DW2: dma_prg_rddata <= prg_reg_DW2;
              EP_ADDR_DW3: dma_prg_rddata <= prg_reg_DW3;
          endcase


          // outputs
          dt_size           <= prg_reg_DW0[15:0]-1;
          dt_msi            <= prg_reg_DW0[17];
          dt_eplast_ena     <= prg_reg_DW0[18];
          app_msi_num       <= prg_reg_DW0[24:20];
          app_msi_tc        <= prg_reg_DW0[30:28];
          dt_rc_last_sync   <= prg_reg_DW0[31];
          dt_base_rc[63:32] <= prg_reg_DW1;
          dt_3dw_rcadd      <= (prg_reg_DW1==32'h0) ? 1'b1 : 1'b0;
          dt_base_rc[31:0]  <= prg_reg_DW2;
          dt_rc_last[15:0]  <= prg_reg_DW3[15:0];
      end
   end


endmodule
