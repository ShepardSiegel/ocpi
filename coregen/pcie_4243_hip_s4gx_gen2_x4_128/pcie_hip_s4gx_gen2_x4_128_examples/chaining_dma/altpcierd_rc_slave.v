// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It could be used by the software
//  * application (Root Port) to retrieve the DMA Performance counter values
//  * and performs read and write to the Endpoint memory by
//  * bypassing the DMA engines.
//  */
// synthesis translate_off
`include "altpcierd_dma_dt_cst_sim.v"
`timescale 1ns / 1ps
// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030


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
module altpcierd_rc_slave #(
   parameter AVALON_WDATA          = 128,
   parameter AVALON_WADDR          = 12,
   parameter AVALON_ST_128         = 0,
   parameter AVALON_BYTE_WIDTH     = AVALON_WDATA/8
   ) (

   input           clk_in,
   input           rstn,
   input [31:0]    dma_rd_prg_rddata,
   input [31:0]    dma_wr_prg_rddata,
   output [3:0]    dma_prg_addr,
   output [31:0]   dma_prg_wrdata,
   output          dma_wr_prg_wrena,
   output          dma_rd_prg_wrena,

   output          mem_wr_ena,  // rename this to write_downstream
   output          mem_rd_ena,

   input [15:0]    rx_ecrc_bad_cnt,
   input [63:0]    read_dma_status,
   input [63:0]    write_dma_status,
   input [12:0]    cfg_busdev,
   input           rx_req  ,
   input[135:0]    rx_desc ,
   input[127:0]    rx_data ,
   input[15:0]     rx_be,
   input           rx_dv   ,
   input           rx_dfr  ,
   output          rx_ack  ,
   output          rx_ws   ,
   input           tx_ws ,
   input           tx_ack ,
   output[127:0]   tx_data,
   output [127:0]  tx_desc,
   output          tx_dfr ,
   output          tx_dv  ,
   output          tx_req ,
   output          tx_busy,
   output          tx_ready,
   input           tx_sel,
   input                          mem_rd_data_valid,
   output [AVALON_WADDR-1:0]      mem_rd_addr ,
   input [AVALON_WDATA-1:0]       mem_rd_data  ,
   output [AVALON_WADDR-1:0]      mem_wr_addr ,
   output [AVALON_WDATA-1:0]      mem_wr_data ,
   output                         sel_epmem       ,
   output [AVALON_BYTE_WIDTH-1:0] mem_wr_be
);

   wire          sel_ep_reg;
   wire [31:0]   reg_rd_data;
   wire          reg_rd_data_valid;
   wire [7:0]    reg_rd_addr;
   wire [7:0]    reg_wr_addr;
   wire [31:0]   reg_wr_data;

   altpcierd_rxtx_downstream_intf #(
      .AVALON_ST_128    (AVALON_ST_128),
      .AVALON_WDATA     (AVALON_WDATA),
      .AVALON_BE_WIDTH  (AVALON_BYTE_WIDTH),
      .MEM_ADDR_WIDTH   (AVALON_WADDR)
      ) altpcierd_rxtx_mem_intf (
      .clk_in       (clk_in),
      .rstn         (rstn),
      .cfg_busdev   (cfg_busdev),

      .rx_req       (rx_req),
      .rx_desc      (rx_desc),
      .rx_data      (rx_data[AVALON_WDATA-1:0]),
      .rx_be        (rx_be[AVALON_BYTE_WIDTH-1:0]),
      .rx_dv        (rx_dv),
      .rx_dfr       (rx_dfr),
      .rx_ack       (rx_ack),
      .rx_ws        (rx_ws),

      .tx_ws        (tx_ws),
      .tx_ack       (tx_ack),
      .tx_desc      (tx_desc),
      .tx_data      (tx_data[AVALON_WDATA-1:0]),
      .tx_dfr       (tx_dfr),
      .tx_dv        (tx_dv),
      .tx_req       (tx_req),
      .tx_busy      (tx_busy ),
      .tx_ready     (tx_ready),
      .tx_sel       (tx_sel ),

      .mem_rd_data_valid (mem_rd_data_valid),
      .mem_rd_addr       (mem_rd_addr),
      .mem_rd_data       (mem_rd_data),
      .mem_rd_ena        (mem_rd_ena),
      .mem_wr_ena        (mem_wr_ena),
      .mem_wr_addr       (mem_wr_addr),
      .mem_wr_data       (mem_wr_data),
      .mem_wr_be         (mem_wr_be),
      .sel_epmem         (sel_epmem),

      .sel_ctl_sts       (sel_ep_reg),
      .reg_rd_data       (reg_rd_data),
      .reg_rd_data_valid (reg_rd_data_valid),
      .reg_wr_addr       (reg_wr_addr),
      .reg_rd_addr       (reg_rd_addr),
      .reg_wr_data       (reg_wr_data)
   );

   altpcierd_reg_access altpcierd_reg_access   (
        .clk_in            (clk_in),
        .rstn              (rstn),
        .dma_rd_prg_rddata (dma_rd_prg_rddata),
        .dma_wr_prg_rddata (dma_wr_prg_rddata),
        .dma_prg_wrdata    (dma_prg_wrdata),
        .dma_prg_addr      (dma_prg_addr),
        .dma_rd_prg_wrena  (dma_rd_prg_wrena),
        .dma_wr_prg_wrena  (dma_wr_prg_wrena),

        .sel_ep_reg        (sel_ep_reg),
        .reg_rd_data       (reg_rd_data),
        .reg_rd_data_valid (reg_rd_data_valid),
        .reg_wr_ena        (mem_wr_ena),
        .reg_rd_ena        (mem_rd_ena),
        .reg_rd_addr       (reg_rd_addr),
        .reg_wr_addr       (reg_wr_addr),
        .reg_wr_data       (reg_wr_data),

        .rx_ecrc_bad_cnt   (rx_ecrc_bad_cnt),
        .read_dma_status   (read_dma_status),
        .write_dma_status  (write_dma_status)
   );



endmodule
