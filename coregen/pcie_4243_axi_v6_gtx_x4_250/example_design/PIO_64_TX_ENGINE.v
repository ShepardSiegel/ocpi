//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
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
// Project    : Virtex-6 Integrated Block for PCI Express
// File       : PIO_64_TX_ENGINE.v
// Version    : 2.1
//-- Description: 64 bit Local-Link Transmit Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module PIO_64_TX_ENGINE    #(
  // RX/TX interface data width
  parameter C_DATA_WIDTH = 64,
  parameter TCQ = 1,

  // TSTRB width
  parameter STRB_WIDTH = C_DATA_WIDTH / 8
)(

  input             clk,
  input             rst_n,

  // AXIS
  input                           s_axis_tx_tready,
  output  reg [C_DATA_WIDTH-1:0]  s_axis_tx_tdata,
  output  reg [STRB_WIDTH-1:0]    s_axis_tx_tstrb,
  output  reg                     s_axis_tx_tlast,
  output  reg                     s_axis_tx_tvalid,
  output                          tx_src_dsc,

  input               req_compl_i,
  input               req_compl_wd_i,
  output reg          compl_done_o,

  input [2:0]         req_tc_i,
  input               req_td_i,
  input               req_ep_i,
  input [1:0]         req_attr_i,
  input [9:0]         req_len_i,
  input [15:0]        req_rid_i,
  input [7:0]         req_tag_i,
  input [7:0]         req_be_i,
  input [12:0]        req_addr_i,

  output [10:0]       rd_addr_o,
  output [3:0]        rd_be_o,
  input  [31:0]       rd_data_i,

  input [15:0]        completer_id_i,
  input               cfg_bus_mstr_enable_i

);

localparam PIO_64_CPLD_FMT_TYPE = 7'b10_01010;
localparam PIO_64_CPL_FMT_TYPE  = 7'b00_01010;
localparam PIO_64_TX_RST_STATE  = 1'b0;
localparam PIO_64_TX_CPLD_QW1   = 1'b1;

    // Local registers


    reg [11:0]              byte_count;
    reg [06:0]              lower_addr;

    reg                     req_compl_q;
    reg                     req_compl_wd_q;

    reg [0:0]               state;

    // Local wires

    // Unused discontinue
    assign tx_src_dsc = 1'b0;

    /*
     * Present address and byte enable to memory module
     */

    assign rd_addr_o = req_addr_i[12:2];
    assign rd_be_o =   req_be_i[3:0];

    /*
     * Calculate byte count based on byte enable
     */

    always @ (rd_be_o) begin

      casex (rd_be_o[3:0])

        4'b1xx1 : byte_count = 12'h004;
        4'b01x1 : byte_count = 12'h003;
        4'b1x10 : byte_count = 12'h003;
        4'b0011 : byte_count = 12'h002;
        4'b0110 : byte_count = 12'h002;
        4'b1100 : byte_count = 12'h002;
        4'b0001 : byte_count = 12'h001;
        4'b0010 : byte_count = 12'h001;
        4'b0100 : byte_count = 12'h001;
        4'b1000 : byte_count = 12'h001;
        4'b0000 : byte_count = 12'h001;

      endcase

    end

    /*
     * Calculate lower address based on  byte enable
     */

    always @ (rd_be_o or req_addr_i) begin

      casex ({req_compl_wd_q, rd_be_o[3:0]})

        5'b0_xxxx : lower_addr = 8'h0;
        5'bx_0000 : lower_addr = {req_addr_i[6:2], 2'b00};
        5'bx_xxx1 : lower_addr = {req_addr_i[6:2], 2'b00};
        5'bx_xx10 : lower_addr = {req_addr_i[6:2], 2'b01};
        5'bx_x100 : lower_addr = {req_addr_i[6:2], 2'b10};
        5'bx_1000 : lower_addr = {req_addr_i[6:2], 2'b11};

      endcase

    end

    always @ ( posedge clk ) begin

        if (!rst_n ) begin

          req_compl_q <= #TCQ 1'b0;
          req_compl_wd_q <= #TCQ 1'b1;

        end else begin

          req_compl_q <= #TCQ req_compl_i;
          req_compl_wd_q <= #TCQ req_compl_wd_i;

        end

    end

    /*
     *  Generate Completion with 1 DW Payload
     */

    always @ ( posedge clk ) begin

        if (!rst_n ) begin

          s_axis_tx_tlast   <= #TCQ 1'b0;
          s_axis_tx_tvalid  <= #TCQ 1'b0;
          s_axis_tx_tdata   <= #TCQ {C_DATA_WIDTH{1'b0}};
          s_axis_tx_tstrb   <= #TCQ {STRB_WIDTH{1'b1}};

          compl_done_o      <= #TCQ 1'b0;

          state             <= #TCQ PIO_64_TX_RST_STATE;

        end else begin


          case ( state )

            PIO_64_TX_RST_STATE : begin

              if (req_compl_q) begin

                s_axis_tx_tlast  <= #TCQ 1'b0;
                s_axis_tx_tvalid <= #TCQ 1'b1;
                // Swap DWORDS for AXI
                s_axis_tx_tdata  <= #TCQ {                      // Bits
                                      completer_id_i,           // 16
                                      {3'b0},                   // 3
                                      {1'b0},                   // 1
                                      byte_count,               // 12
                                      {1'b0},                   // 1
                                      (req_compl_wd_q ?
                                      PIO_64_CPLD_FMT_TYPE :
                                      PIO_64_CPL_FMT_TYPE),     // 7
                                      {1'b0},                   // 1
                                      req_tc_i,                 // 3
                                      {4'b0},                   // 4
                                      req_td_i,                 // 1
                                      req_ep_i,                 // 1
                                      req_attr_i,               // 2
                                      {2'b0},                   // 2
                                      req_len_i                 // 10
                                      };
                s_axis_tx_tstrb   <= #TCQ 8'hFF;

                // Wait in this state if the PCIe core does not accept
                // the first beat of the packet
                if (s_axis_tx_tready)
                  state             <= #TCQ PIO_64_TX_CPLD_QW1;
                else
                  state             <= #TCQ PIO_64_TX_RST_STATE;


              end else begin

                s_axis_tx_tlast   <= #TCQ 1'b0;
                s_axis_tx_tvalid  <= #TCQ 1'b0;
                s_axis_tx_tdata   <= #TCQ 64'b0;
                s_axis_tx_tstrb   <= #TCQ 8'hFF;
                compl_done_o      <= #TCQ 1'b0;

                state             <= #TCQ PIO_64_TX_RST_STATE;

              end

            end

            PIO_64_TX_CPLD_QW1 : begin

              if (s_axis_tx_tready) begin

                s_axis_tx_tlast  <= #TCQ 1'b1;
                s_axis_tx_tvalid <= #TCQ 1'b1;
                // Swap DWORDS for AXI
                s_axis_tx_tdata  <= #TCQ {        // Bits
                                      rd_data_i,  // 32
                                      req_rid_i,  // 16
                                      req_tag_i,  //  8
                                      {1'b0},     //  1
                                      lower_addr  //  7
                                      };

                // Here we select if the packet has data or
                // not.  The strobe signal will mask data
                // when it is not needed.  No reason to change
                // the data bus.
                if (req_compl_wd_q)
                  s_axis_tx_tstrb <= #TCQ 8'hFF;
                else
                  s_axis_tx_tstrb <= #TCQ 8'h0F;


                compl_done_o      <= #TCQ 1'b1;
                state             <= #TCQ PIO_64_TX_RST_STATE;

              end else
                state             <= #TCQ PIO_64_TX_CPLD_QW1;

            end

          endcase

        end

    end

endmodule // PIO_64_TX_ENGINE

