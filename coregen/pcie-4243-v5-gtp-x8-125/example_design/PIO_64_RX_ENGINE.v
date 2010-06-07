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
// File       : PIO_64_RX_ENGINE.v
//--
//-- Description: 64 bit Local-Link Receive Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

`define TCQ 1

`define PIO_64_RX_MEM_RD32_FMT_TYPE 7'b00_00000
`define PIO_64_RX_MEM_WR32_FMT_TYPE 7'b10_00000
`define PIO_64_RX_MEM_RD64_FMT_TYPE 7'b01_00000
`define PIO_64_RX_MEM_WR64_FMT_TYPE 7'b11_00000
`define PIO_64_RX_IO_RD32_FMT_TYPE  7'b00_00010
`define PIO_64_RX_IO_WR32_FMT_TYPE  7'b10_00010

`define PIO_64_RX_RST_STATE         8'b00000000
`define PIO_64_RX_MEM_RD32_DW1DW2   8'b00000001
`define PIO_64_RX_MEM_WR32_DW1DW2   8'b00000010
`define PIO_64_RX_MEM_RD64_DW1DW2   8'b00000100
`define PIO_64_RX_MEM_WR64_DW1DW2   8'b00001000
`define PIO_64_RX_MEM_WR64_DW3      8'b00010000
`define PIO_64_RX_WAIT_STATE        8'b00100000
`define PIO_64_RX_IO_WR_DW1DW2      8'b01000000
`define PIO_64_RX_IO_MEM_WR_WAIT_STATE  8'b10000000



module PIO_64_RX_ENGINE (
                        clk,
                        rst_n,

                        /*
                         * Receive local link interface from PCIe core
                         */

                        trn_rd,
                        trn_rrem_n,
                        trn_rsof_n,
                        trn_reof_n,
                        trn_rsrc_rdy_n,
                        trn_rsrc_dsc_n,
                        trn_rbar_hit_n,
                        trn_rdst_rdy_n,



                        /*
                         * Memory Read data handshake with Completion
                         * transmit unit. Transmit unit reponds to
                         * req_compl assertion and responds with compl_done
                         * assertion when a Completion w/ data is transmitted.
                         */

                        req_compl_o,
                        req_compl_with_data_o, // asserted indicates to generate a completion WITH data
                                               // otherwise a completion WITHOUT data will be generated
                        compl_done_i,

                        req_tc_o,                  // Memory Read TC
                        req_td_o,                  // Memory Read TD
                        req_ep_o,                  // Memory Read EP
                        req_attr_o,                // Memory Read Attribute
                        req_len_o,                 // Memory Read Length (1DW)
                        req_rid_o,                 // Memory Read Requestor ID
                        req_tag_o,                 // Memory Read Tag
                        req_be_o,                  // Memory Read Byte Enables
                        req_addr_o,                // Memory Read Address

                         /* 
                         * Memory interface used to save 1 DW data received
                         * on Memory Write 32 TLP. Data extracted from
                         * inbound TLP is presented to the Endpoint memory
                         * unit. Endpoint memory unit reacts to wr_en_o
                         * assertion and asserts wr_busy_i when it is
                         * processing written information.
                         */

                        wr_addr_o,                 // Memory Write Address
                        wr_be_o,                   // Memory Write Byte Enable
                        wr_data_o,                 // Memory Write Data
                        wr_en_o,                   // Memory Write Enable
                        wr_busy_i                  // Memory Write Busy
                        


                       );

    input              clk;
    input              rst_n;

    input [63:0]       trn_rd;
    input [7:0]        trn_rrem_n;
    input              trn_rsof_n;
    input              trn_reof_n;
    input              trn_rsrc_rdy_n;
    input              trn_rsrc_dsc_n;
    input [6:0]        trn_rbar_hit_n;
    output             trn_rdst_rdy_n;
 
    output             req_compl_o;
    output             req_compl_with_data_o; //asserted indicates to generate a completion WITH data
                              // otherwise a completion WITHOUT data will be generated
    input              compl_done_i;

    output [2:0]       req_tc_o;
    output             req_td_o;
    output             req_ep_o;
    output [1:0]       req_attr_o;
    output [9:0]       req_len_o;
    output [15:0]      req_rid_o;
    output [7:0]       req_tag_o;
    output [7:0]       req_be_o;
    output [12:0]      req_addr_o;


    output [10:0]      wr_addr_o;
    output [7:0]       wr_be_o;
    output [31:0]      wr_data_o;
    output             wr_en_o;
    input              wr_busy_i;
    

    // Local Registers

    reg                trn_rdst_rdy_n;

    reg                req_compl_o;
    reg                req_compl_with_data_o;

    reg [2:0]          req_tc_o;
    reg                req_td_o;
    reg                req_ep_o;
    reg [1:0]          req_attr_o;
    reg [9:0]          req_len_o;
    reg [15:0]         req_rid_o;
    reg [7:0]          req_tag_o;
    reg [7:0]          req_be_o;
    reg [12:0]         req_addr_o;

    reg [10:0]         wr_addr_o;
    reg [7:0]          wr_be_o;
    reg [31:0]         wr_data_o;
    reg                wr_en_o;
    
    reg [7:0]          state;
    reg [7:0]          tlp_type;

    wire               io_bar_hit_n;
    wire               mem32_bar_hit_n;
    wire               mem64_bar_hit_n;
    wire               erom_bar_hit_n;

    reg [1:0]          region_select;




    always @ ( posedge clk or negedge rst_n ) begin

        if (!rst_n ) begin

          trn_rdst_rdy_n <= #`TCQ 1'b0;

          req_compl_o    <= #`TCQ 1'b0;
          req_compl_with_data_o  <= #`TCQ 1'b1;
          req_tc_o       <= #`TCQ 2'b0;
          req_td_o       <= #`TCQ 1'b0;
          req_ep_o       <= #`TCQ 1'b0;
          req_attr_o     <= #`TCQ 2'b0;
          req_len_o      <= #`TCQ 10'b0;
          req_rid_o      <= #`TCQ 16'b0;
          req_tag_o      <= #`TCQ 8'b0;
          req_be_o       <= #`TCQ 8'b0;
          req_addr_o     <= #`TCQ 13'b0;

          wr_be_o        <= #`TCQ 8'b0;
          wr_addr_o      <= #`TCQ 11'b0;
          wr_data_o      <= #`TCQ 31'b0;
          wr_en_o        <= #`TCQ 1'b0;
          
          state          <= #`TCQ `PIO_64_RX_RST_STATE;
          tlp_type       <= #`TCQ 7'b0;

        end else begin

          wr_en_o        <= #`TCQ 1'b0;
          req_compl_o    <= #`TCQ 1'b0;
          req_compl_with_data_o  <= #`TCQ 1'b1;

          case (state)

            `PIO_64_RX_RST_STATE : begin

              trn_rdst_rdy_n <= #`TCQ 1'b0;

              if ((!trn_rsof_n) &&
                  (!trn_rsrc_rdy_n) && 
                  (!trn_rdst_rdy_n)) begin

                case (trn_rd[62:56])

                  `PIO_64_RX_MEM_RD32_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32];
                    trn_rdst_rdy_n <= #`TCQ 1'b1;
 

                    if (trn_rd[41:32] == 10'b1) begin

                      req_tc_o     <= #`TCQ trn_rd[54:52];  
                      req_td_o     <= #`TCQ trn_rd[47];
                      req_ep_o     <= #`TCQ trn_rd[46]; 
                      req_attr_o   <= #`TCQ trn_rd[45:44];
                      req_len_o    <= #`TCQ trn_rd[41:32];
                      req_rid_o    <= #`TCQ trn_rd[31:16];
                      req_tag_o    <= #`TCQ trn_rd[15:08]; 
                      req_be_o     <= #`TCQ trn_rd[07:00];
                      state        <= #`TCQ `PIO_64_RX_MEM_RD32_DW1DW2;

                    end else begin

                      state        <= #`TCQ `PIO_64_RX_RST_STATE;

                    end

                  end
         
                  `PIO_64_RX_MEM_WR32_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32]; 
                    trn_rdst_rdy_n <= #`TCQ 1'b1;

                    if (trn_rd[41:32] == 10'b1) begin

                      wr_be_o      <= #`TCQ trn_rd[07:00];
                      state        <= #`TCQ `PIO_64_RX_MEM_WR32_DW1DW2;

                    end else begin
                    
                      state        <= #`TCQ `PIO_64_RX_RST_STATE;

                    end

                  end

                  `PIO_64_RX_MEM_RD64_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32];
                    trn_rdst_rdy_n <= #`TCQ 1'b1;
 

                    if (trn_rd[41:32] == 10'b1) begin

                      req_tc_o     <= #`TCQ trn_rd[54:52];  
                      req_td_o     <= #`TCQ trn_rd[47];
                      req_ep_o     <= #`TCQ trn_rd[46]; 
                      req_attr_o   <= #`TCQ trn_rd[45:44];
                      req_len_o    <= #`TCQ trn_rd[41:32];
                      req_rid_o    <= #`TCQ trn_rd[31:16];
                      req_tag_o    <= #`TCQ trn_rd[15:08]; 
                      req_be_o     <= #`TCQ trn_rd[07:00];
                      state        <= #`TCQ `PIO_64_RX_MEM_RD64_DW1DW2;

                    end else begin

                      state        <= #`TCQ `PIO_64_RX_RST_STATE;

                    end

                  end
         
                  `PIO_64_RX_MEM_WR64_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32]; 

                    if (trn_rd[41:32] == 10'b1) begin

                      wr_be_o      <= #`TCQ trn_rd[07:00];
                      state        <= #`TCQ `PIO_64_RX_MEM_WR64_DW1DW2;

                    end else begin

                      state        <= #`TCQ `PIO_64_RX_RST_STATE; 

                    end

                  end 


                  `PIO_64_RX_IO_RD32_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32];
                    trn_rdst_rdy_n <= #`TCQ 1'b1;
 

                    if (trn_rd[41:32] == 10'b1) begin

                      req_tc_o     <= #`TCQ trn_rd[54:52];  
                      req_td_o     <= #`TCQ trn_rd[47];
                      req_ep_o     <= #`TCQ trn_rd[46]; 
                      req_attr_o   <= #`TCQ trn_rd[45:44]; 
                      req_len_o    <= #`TCQ trn_rd[41:32];
                      req_rid_o    <= #`TCQ trn_rd[31:16]; 
                      req_tag_o    <= #`TCQ trn_rd[15:08];
                      req_be_o     <= #`TCQ trn_rd[07:00]; 
                      state        <= #`TCQ `PIO_64_RX_MEM_RD32_DW1DW2;

                    end else begin

                      state        <= #`TCQ `PIO_64_RX_RST_STATE; 

                    end

                  end

                  `PIO_64_RX_IO_WR32_FMT_TYPE : begin

                    tlp_type     <= #`TCQ trn_rd[63:56];
                    req_len_o    <= #`TCQ trn_rd[41:32];
                    trn_rdst_rdy_n <= #`TCQ 1'b1;

                    if (trn_rd[41:32] == 10'b1) begin

                      req_tc_o     <= #`TCQ trn_rd[54:52];
                      req_td_o     <= #`TCQ trn_rd[47];
                      req_ep_o     <= #`TCQ trn_rd[46];
                      req_attr_o   <= #`TCQ trn_rd[45:44];
                      req_len_o    <= #`TCQ trn_rd[41:32];
                      req_rid_o    <= #`TCQ trn_rd[31:16];
                      req_tag_o    <= #`TCQ trn_rd[15:08];
                      req_be_o     <= #`TCQ trn_rd[07:00];
                      wr_be_o      <= #`TCQ trn_rd[07:00];
                      state        <= #`TCQ `PIO_64_RX_IO_WR_DW1DW2;

                    end else begin

                      state        <= #`TCQ `PIO_64_RX_RST_STATE;

                    end

                  end


                  default : begin // other TLPs

                    state        <= #`TCQ `PIO_64_RX_RST_STATE; 

                  end

                endcase

              end else
                state <= #`TCQ `PIO_64_RX_RST_STATE;

            end

            `PIO_64_RX_MEM_RD32_DW1DW2 : begin

              if (!trn_rsrc_rdy_n) begin
                
                trn_rdst_rdy_n <= #`TCQ 1'b1;
                req_addr_o   <= #`TCQ {region_select[1:0],trn_rd[42:34], 2'b00};
                req_compl_o  <= #`TCQ 1'b1;
                state        <= #`TCQ `PIO_64_RX_WAIT_STATE;

              end else
                state        <= #`TCQ `PIO_64_RX_MEM_RD32_DW1DW2; 

            end


            `PIO_64_RX_MEM_WR32_DW1DW2 : begin

              if (!trn_rsrc_rdy_n) begin

                wr_data_o      <= #`TCQ trn_rd[31:0];
                trn_rdst_rdy_n <= #`TCQ 1'b1;
                wr_addr_o      <= #`TCQ {region_select[1:0],trn_rd[42:34]};
                state          <= #`TCQ  `PIO_64_RX_IO_MEM_WR_WAIT_STATE;

              end else
                state          <= #`TCQ `PIO_64_RX_MEM_WR32_DW1DW2;

            end


            `PIO_64_RX_IO_MEM_WR_WAIT_STATE : begin

                wr_en_o        <= #`TCQ 1'b1;
                state          <= #`TCQ  `PIO_64_RX_WAIT_STATE;


            end

            `PIO_64_RX_MEM_RD64_DW1DW2 : begin

              if (!trn_rsrc_rdy_n) begin

                req_addr_o   <= #`TCQ {region_select[1:0],trn_rd[10:2], 2'b00};
                req_compl_o  <= #`TCQ 1'b1;
                trn_rdst_rdy_n <= #`TCQ 1'b1;
                state        <= #`TCQ `PIO_64_RX_WAIT_STATE; 

              end else
                state        <= #`TCQ `PIO_64_RX_MEM_RD64_DW1DW2;
         
            end



            `PIO_64_RX_MEM_WR64_DW1DW2 : begin

              if (!trn_rsrc_rdy_n) begin

                trn_rdst_rdy_n <= #`TCQ 1'b1;
                wr_addr_o      <= #`TCQ {region_select[1:0],trn_rd[10:2]};
                state          <= #`TCQ  `PIO_64_RX_MEM_WR64_DW3;

              end else
                state          <= #`TCQ `PIO_64_RX_MEM_WR64_DW1DW2; 

            end


            `PIO_64_RX_MEM_WR64_DW3 : begin

              if (!trn_rsrc_rdy_n) begin

                wr_data_o      <= #`TCQ trn_rd[63:32];
                wr_en_o        <= #`TCQ 1'b1;
                trn_rdst_rdy_n <= #`TCQ 1'b1;
                state        <= #`TCQ `PIO_64_RX_WAIT_STATE; 

              end else 
                 state        <= #`TCQ `PIO_64_RX_MEM_WR64_DW3;
         
            end


           `PIO_64_RX_IO_WR_DW1DW2 : begin

              if (!trn_rsrc_rdy_n) begin

                wr_data_o      <= #`TCQ trn_rd[31:0];
                trn_rdst_rdy_n <= #`TCQ 1'b1;
                wr_addr_o      <= #`TCQ {region_select[1:0],trn_rd[42:34]};
                req_compl_o    <= #`TCQ 1'b1;
                req_compl_with_data_o <= #`TCQ 1'b0;
                state          <= #`TCQ  `PIO_64_RX_IO_MEM_WR_WAIT_STATE;

              end else
                state          <= #`TCQ `PIO_64_RX_IO_WR_DW1DW2;

            end


            `PIO_64_RX_WAIT_STATE : begin

              wr_en_o      <= #`TCQ 1'b0;
              req_compl_o  <= #`TCQ 1'b0;

              if ((tlp_type == `PIO_64_RX_MEM_WR32_FMT_TYPE) &&
                  (!wr_busy_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE; 

             end else if ((tlp_type == `PIO_64_RX_IO_WR32_FMT_TYPE) &&
                  (!compl_done_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE;

              end else if ((tlp_type == `PIO_64_RX_MEM_WR64_FMT_TYPE) &&
                  (!wr_busy_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE; 

              end else if ((tlp_type == `PIO_64_RX_MEM_RD32_FMT_TYPE) &&
                           (compl_done_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE;

              end else if ((tlp_type == `PIO_64_RX_IO_RD32_FMT_TYPE) &&
                           (compl_done_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE; 

              end else if ((tlp_type == `PIO_64_RX_MEM_RD64_FMT_TYPE) &&
                           (compl_done_i)) begin

                trn_rdst_rdy_n <= #`TCQ 1'b0;
                state        <= #`TCQ `PIO_64_RX_RST_STATE; 

              end else
                state        <= #`TCQ `PIO_64_RX_WAIT_STATE;

            end

          endcase

        end

    end


     assign mem64_bar_hit_n = 1'b1;
    assign io_bar_hit_n = 1'b1;
    assign mem32_bar_hit_n = trn_rbar_hit_n[0];
    assign erom_bar_hit_n  = trn_rbar_hit_n[6];


  always @*
  begin
     case ({io_bar_hit_n, mem32_bar_hit_n, mem64_bar_hit_n, erom_bar_hit_n})

        4'b0111 : begin
             region_select <= #`TCQ 2'b00;    // Select IO region
        end

        4'b1011 : begin
             region_select <= #`TCQ 2'b01;    // Select Mem32 region
        end

        4'b1101 : begin
             region_select <= #`TCQ 2'b10;    // Select Mem64 region
        end

        4'b1110 : begin
             region_select <= #`TCQ 2'b11;    // Select EROM region
        end

        default : begin
             region_select <= #`TCQ 2'b00;    // Error selection will select IO region
        end

     endcase

  end


  // synthesis translate_off
  reg  [8*20:1] state_ascii;
  always @(state)
  begin
    if      (state==`PIO_64_RX_RST_STATE)         state_ascii <= #`TCQ "RX_RST_STATE";
    else if (state==`PIO_64_RX_MEM_RD32_DW1DW2)   state_ascii <= #`TCQ "RX_MEM_RD32_DW1DW2";
    else if (state==`PIO_64_RX_MEM_WR32_DW1DW2)   state_ascii <= #`TCQ "RX_MEM_WR32_DW1DW2";
    else if (state==`PIO_64_RX_MEM_RD64_DW1DW2)   state_ascii <= #`TCQ "RX_MEM_RD64_DW1DW2";
    else if (state==`PIO_64_RX_MEM_WR64_DW1DW2)   state_ascii <= #`TCQ "RX_MEM_WR64_DW1DW2";
    else if (state==`PIO_64_RX_MEM_WR64_DW3)      state_ascii <= #`TCQ "RX_MEM_WR64_DW3";
    else if (state==`PIO_64_RX_WAIT_STATE)        state_ascii <= #`TCQ "RX_WAIT_STATE";
else if (state==`PIO_64_RX_IO_WR_DW1DW2)        state_ascii <= #`TCQ "RX_IO_WR_DW1_DW2";
    else                                          state_ascii <= #`TCQ "PIO 64 STATE ERR";

  end
  // synthesis translate_on






endmodule // PIO_64_RX_ENGINE

