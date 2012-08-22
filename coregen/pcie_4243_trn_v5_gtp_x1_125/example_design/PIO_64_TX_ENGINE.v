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
// Project    : V5-Block Plus for PCI Express
// File       : PIO_64_TX_ENGINE.v
//--
//-- Description: 64 bit Local-Link Transmit Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`define PIO_64_CPLD_FMT_TYPE 7'b10_01010
`define PIO_64_CPL_FMT_TYPE  7'b00_01010

`define PIO_64_TX_RST_STATE  2'b00
`define PIO_64_TX_CPLD_QW1   2'b01
`define PIO_64_TX_CPL_QW1    2'b10

module PIO_64_TX_ENGINE    (

                        clk,
                        rst_n,

                        trn_td,
                        trn_trem_n,
                        trn_tsof_n,
                        trn_teof_n,
                        trn_tsrc_rdy_n,
                        trn_tsrc_dsc_n,
                        trn_tdst_rdy_n,
                        trn_tdst_dsc_n,

                        req_compl_i,
                        req_compl_with_data_i,
                        compl_done_o,

                        req_tc_i,     
                        req_td_i,
                        req_ep_i,
                        req_attr_i,
                        req_len_i,
                        req_rid_i,        
                        req_tag_i,
                        req_be_i,
                        req_addr_i,

                        // Read Access

                        rd_addr_o,
                        rd_be_o,
                        rd_data_i,

                        completer_id_i,
                        cfg_bus_mstr_enable_i

                        );

    input               clk;
    input               rst_n;

    output [63:0]       trn_td;
    output [7:0]        trn_trem_n;
    output              trn_tsof_n;
    output              trn_teof_n;
    output              trn_tsrc_rdy_n;
    output              trn_tsrc_dsc_n;
    input               trn_tdst_rdy_n;
    input               trn_tdst_dsc_n;

    input               req_compl_i;
    input               req_compl_with_data_i; // asserted indicates to generate a completion WITH data
                         // otherwise a completion WITHOUT data will be generated
    output              compl_done_o;

    input [2:0]         req_tc_i;
    input               req_td_i;
    input               req_ep_i;
    input [1:0]         req_attr_i;
    input [9:0]         req_len_i;
    input [15:0]        req_rid_i;
    input [7:0]         req_tag_i;
    input [7:0]         req_be_i;
    input [12:0]        req_addr_i;

    output [10:0]       rd_addr_o;
    output [3:0]        rd_be_o;
    input  [31:0]       rd_data_i;

    input [15:0]        completer_id_i;
    input               cfg_bus_mstr_enable_i;

    // Local registers

    reg [63:0]          trn_td;
    reg [7:0]           trn_trem_n;
    reg                 trn_tsof_n;
    reg                 trn_teof_n;
    reg                 trn_tsrc_rdy_n;
    reg                 trn_tsrc_dsc_n;

    reg [11:0]          byte_count;
    reg [06:0]          lower_addr;

    reg                 compl_done_o;
    reg                 req_compl_q;
    reg                 req_compl_with_data_q;

    reg [1:0]           state;

    // Local wires

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

      casex (rd_be_o[3:0])
      
        4'b0000 : lower_addr = {req_addr_i[6:2], 2'b00};
        4'bxxx1 : lower_addr = {req_addr_i[6:2], 2'b00};
        4'bxx10 : lower_addr = {req_addr_i[6:2], 2'b01};
        4'bx100 : lower_addr = {req_addr_i[6:2], 2'b10};
        4'b1000 : lower_addr = {req_addr_i[6:2], 2'b11};

      endcase

    end

    always @ ( posedge clk or negedge rst_n ) begin

        if (!rst_n ) begin

          req_compl_q <= 1'b0;
          req_compl_with_data_q <= 1'b1;

        end else begin

          req_compl_q <= req_compl_i;
          req_compl_with_data_q <= req_compl_with_data_i;

        end

    end

    /*
     *  Generate Completion with 1 DW Payload or Completion with no data
     */

    always @ ( posedge clk or negedge rst_n ) begin

        if (!rst_n ) begin

          trn_tsof_n        <= 1'b1;
          trn_teof_n        <= 1'b1;
          trn_tsrc_rdy_n    <= 1'b1;
          trn_tsrc_dsc_n    <= 1'b1;
          trn_td            <= 64'b0;
          trn_trem_n        <= 8'b0;

          compl_done_o      <= 1'b0;

          state             <= `PIO_64_TX_RST_STATE;

        end else begin


          case ( state )

            `PIO_64_TX_RST_STATE : begin

              if (req_compl_q && req_compl_with_data_q &&
                  trn_tdst_dsc_n) begin

                trn_tsof_n       <= 1'b0;
                trn_teof_n       <= 1'b1;
                trn_tsrc_rdy_n   <= 1'b0;
                trn_td           <= { {1'b0},
                                      `PIO_64_CPLD_FMT_TYPE,
                                      {1'b0}, 
                                      req_tc_i,
                                      {4'b0},
                                      req_td_i,
                                      req_ep_i, 
                                      req_attr_i,
                                      {2'b0}, 
                                      req_len_i,
                                      completer_id_i,
                                      {3'b0},
                                      {1'b0}, 
                                      byte_count };
                trn_trem_n        <= 8'b0;

                state             <= `PIO_64_TX_CPLD_QW1;
               
              end else if (req_compl_q && (!req_compl_with_data_q) &&
                  trn_tdst_dsc_n) begin

                trn_tsof_n       <= 1'b0;
                trn_teof_n       <= 1'b1;
                trn_tsrc_rdy_n   <= 1'b0;
                trn_td           <= { {1'b0},
                                      `PIO_64_CPL_FMT_TYPE,
                                      {1'b0},
                                      req_tc_i,
                                      {4'b0},
                                      req_td_i,
                                      req_ep_i,
                                      req_attr_i,
                                      {2'b0},
                                      req_len_i,
                                      completer_id_i,
                                      {3'b0},
                                      {1'b0},
                                      byte_count };
                trn_trem_n        <= 8'b0;

                state             <= `PIO_64_TX_CPL_QW1;

              end else begin

                trn_tsof_n        <= 1'b1;
                trn_teof_n        <= 1'b1;
                trn_tsrc_rdy_n    <= 1'b1;
                trn_tsrc_dsc_n    <= 1'b1;
                trn_td            <= 64'b0;
                trn_trem_n        <= 8'b0;
                compl_done_o      <= 1'b0;

                state             <= `PIO_64_TX_RST_STATE;

              end

            end

            `PIO_64_TX_CPLD_QW1 : begin

              if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin

                trn_tsof_n       <= 1'b1;
                trn_teof_n       <= 1'b0;
                trn_tsrc_rdy_n   <= 1'b0;
                trn_td           <= { req_rid_i,
                                      req_tag_i,
                                      {1'b0},
                                      lower_addr,
                                      rd_data_i };
                trn_trem_n        <= 8'h00;
                compl_done_o      <= 1'b1;

                state             <= `PIO_64_TX_RST_STATE;

              end else if (!trn_tdst_dsc_n) begin

                state             <= `PIO_64_TX_RST_STATE;
                trn_tsrc_dsc_n    <= 1'b0;

              end else
                state             <= `PIO_64_TX_CPLD_QW1;

            end

            `PIO_64_TX_CPL_QW1 : begin

              if ((!trn_tdst_rdy_n) && (trn_tdst_dsc_n)) begin

                trn_tsof_n       <= 1'b1;
                trn_teof_n       <= 1'b0;
                trn_tsrc_rdy_n   <= 1'b0;
                trn_td           <= { req_rid_i,
                                      req_tag_i, 
                                      {1'b0},
                                      lower_addr,
                                      32'h00000000 };
                trn_trem_n        <= 8'h0F;
                compl_done_o      <= 1'b1;

                state             <= `PIO_64_TX_RST_STATE;

              end else if (!trn_tdst_dsc_n) begin

                state             <= `PIO_64_TX_RST_STATE;
                trn_tsrc_dsc_n    <= 1'b0;

              end else
                state             <= `PIO_64_TX_CPL_QW1;

            end

          endcase

        end

    end

endmodule // PIO_64_TX_ENGINE


