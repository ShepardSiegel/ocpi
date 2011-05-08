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
// Title         : altpcierd_rxtx_intf
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_control_status.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
//
//  Description:  This module contains Chaining DMA control and status
//                registers accessible by the root port on BAR 2/3.
//
//
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


module altpcierd_rxtx_downstream_intf #(
   parameter AVALON_ST_128   = 0,
   parameter AVALON_WDATA    = 64,
   parameter AVALON_BE_WIDTH = 8,
   parameter MEM_ADDR_WIDTH  = 10
   ) (
   input                         clk_in,
   input                         rstn,
   input[12:0]                   cfg_busdev,

   input                         rx_req  ,
   input[135:0]                  rx_desc ,
   input[AVALON_WDATA-1:0]       rx_data ,
   input[AVALON_BE_WIDTH-1:0]    rx_be,
   input                         rx_dv   ,
   input                         rx_dfr  ,
   output  reg                   rx_ack  ,
   output                        rx_ws  ,

   input                         tx_ws,
   input                         tx_ack,
   input                         tx_sel,
   output [127:0]                tx_desc,
   output [AVALON_WDATA-1:0]     tx_data,
   output reg                    tx_dfr,
   output reg                    tx_dv,
   output reg                    tx_req,
   output reg                    tx_ready ,
   output reg                    tx_busy  ,


   output reg                       sel_epmem,
   output reg                       sel_ctl_sts,
   input                            mem_rd_data_valid,
   output reg [MEM_ADDR_WIDTH-1:0]  mem_rd_addr,
   input  [AVALON_WDATA-1:0]        mem_rd_data,        // register read data   output reg                    mem_wr_ena,         // pulse.  register write enable
   output reg                       mem_rd_ena,         // pulse.  register read enable
   output reg                       mem_wr_ena,
   output reg [MEM_ADDR_WIDTH-1:0]  mem_wr_addr,        // register address (BAR 2/3 is 128 bytes max)
   output reg [AVALON_WDATA-1:0]    mem_wr_data,        // register data to be written
   output reg [AVALON_BE_WIDTH-1:0] mem_wr_be,

   input [31:0]                     reg_rd_data,
   input                            reg_rd_data_valid,
   output reg [7:0]                 reg_wr_addr,        // register address (BAR 2/3 is 128 bytes max)
   output reg [7:0]                 reg_rd_addr,
   output reg [31:0]                reg_wr_data

   );

   localparam AVALON_WDATA_WIDTHU = (AVALON_WDATA==128) ? 7 : 6;

   // cstate_rx states
   localparam RX_IDLE         = 3'h0;   // Wait for PciE Request
   localparam RX_DESC2_ACK    = 3'h1;   // Acking PciE Request in this cycle (2nd Descriptor cycle)
   localparam RX_START_CPL    = 3'h2;   // If Request is a READ, then wait for Completion to start
   localparam RX_WAIT_END_CPL = 3'h3;   // Wait for Completion to end
   localparam RX_DV_PAYLD     = 3'h4;   // Write payload to memory

   // cstate_tx states
   localparam TX_IDLE             = 3'h0;  // Wait for cstate_rx to request a Completion
   localparam TX_SEND_REQ         = 3'h1;  // Send Completion TLP to PciE
   localparam TX_SEND_DV_WAIT_ACK = 3'h2;  // Drive tx_dv on PciE Desc/Data interface
   localparam TX_DV_PAYLD         = 3'h3;  // Wait for PciE Desc/Data interface to accept data phase
   localparam TX_WAIT_ARB         = 3'h4;  // Wait for external arbiter to give this module access to the TX interface

   reg[2:0]   cstate_rx;
   reg[2:0]   cstate_tx;
   wire       rx_bar_hit_n;
   reg        rx_is_rdreq;
   reg        rx_is_wrreq;
   reg [12:0] cfg_busdev_reg;
   reg [7:0]  rx_hold_tag;
   reg [15:0] rx_hold_reqid;
   reg [63:0] rx_hold_addr;
   reg [10:0] rx_hold_length;
   reg [7:0]  tx_desc_tag;
   reg [15:0] tx_desc_req_id;
   reg [6:0]  tx_desc_addr;
   reg [3:0]  tx_desc_lbe;
   reg [9:0]  tx_desc_length;
   reg        rx_start_write;
   reg [9:0]  num_dw_to_read;
   reg [9:0]  mem_num_to_read;
   reg [9:0]  mem_num_to_read_minus_one;
   reg [9:0]  fifo_rd_count;
   reg [9:0]  mem_read_count;
   reg        rx_start_read;
   reg        tx_ready_del;
   wire       tx_arb_granted;
   reg        rx_sel_epmem;
   wire       start_tx;
   wire       fifo_rd;
  // wire       fifo_wr;
   wire       fifo_almost_full;
   wire       fifo_empty;
   wire       rx_is_downstream_req_n;
   wire       rx_is_rdreq_n;
   wire       rx_is_wrreq_n;
   wire       rx_is_msg_n;
   reg        fifo_prefetch;
   reg        rx_do_cpl;
   reg        rx_mem_bar_hit;
   reg        rx_reg_bar_hit;
 //  wire[AVALON_WDATA-1:0] fifo_data_in;
   wire[AVALON_WDATA-1:0] fifo_data_out;

   ///////////////////////////////////////////
   // RX state machine - Receives requests
   // This is the main request controller
   //////////////////////////////////////////

   assign rx_ws = 1'b0;

   // this module responds to BAR0/1/4/5 downstream requests
  // assign rx_bar_hit_n  = (rx_desc[133] | rx_desc[132] | rx_desc[129] | rx_desc[128]) ? 1'b1 : 1'b0;
   assign rx_bar_hit_n  = 1'b1;    // service all downstream requests
   assign rx_is_rdreq_n = ((rx_desc[126]==1'b0) & (rx_desc[124:120] == `TLP_TYPE_READ))  ? 1'b1 : 1'b0;
   assign rx_is_wrreq_n = ((rx_desc[126]==1'b1) & (rx_desc[124:120] == `TLP_TYPE_WRITE)) ? 1'b1 : 1'b0;
   assign rx_is_msg_n   = (rx_desc[125:123] == 3'b110) ? 1'b1 : 1'b0;

   assign rx_is_downstream_req_n = ((rx_is_rdreq_n==1'b1) | (rx_is_wrreq_n==1'b1) | (rx_is_msg_n==1'b1)) ? 1'b1 : 1'b0;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          rx_ack           <= 1'b0;
          cstate_rx        <= RX_IDLE;
          rx_is_rdreq      <= 1'b0;
          rx_is_wrreq      <= 1'b0;
          rx_start_read    <= 1'b0;
          rx_hold_tag      <= 8'h0;
          rx_hold_reqid    <= 16'h0;
          rx_hold_addr     <= 64'h0;
          rx_hold_length   <= 11'h0;
          rx_start_write   <= 1'b0;
          rx_sel_epmem     <= 1'b0;
          sel_ctl_sts       <= 1'b0;
          rx_do_cpl        <= 1'b0;
        num_dw_to_read   <= 0 ;
      end
      else begin
          case (cstate_rx)
              RX_IDLE: begin
                  rx_start_write <= 1'b0;
                  // wait for a downstream request addressed to BAR 2/3
                  if ((rx_req == 1'b1) & (rx_bar_hit_n == 1'b1) & (rx_is_downstream_req_n==1'b1)) begin

                      cstate_rx       <= RX_DESC2_ACK;
                      rx_ack          <= 1'b1;
                      rx_is_rdreq     <= rx_is_rdreq_n;
                      rx_is_wrreq     <= rx_is_wrreq_n;
                      rx_do_cpl       <= rx_is_rdreq_n;
                      rx_start_write  <= rx_is_wrreq_n;
                      rx_hold_length  <= rx_desc[105:96];
                      sel_ctl_sts     <= (rx_desc[131] | rx_desc[130]) ? 1'b1 : 1'b0;   // bar 2/3
                      rx_sel_epmem    <= (rx_desc[134] | rx_desc[133] | rx_desc[132] | rx_desc[129] | rx_desc[128]) ? 1'b1 : 1'b0;   // bar 0/1, 4/5/6
                  end
                  else begin
                      rx_sel_epmem <= 1'b0;
                      sel_ctl_sts   <= 1'b0;
                      rx_is_rdreq  <= 1'b0;
                      rx_is_wrreq  <= 1'b0;
                      rx_do_cpl    <= 1'b0;
                      cstate_rx    <= cstate_rx;
                  end
              end
              RX_DESC2_ACK: begin
                  rx_ack         <= 1'b0;
                  rx_start_write <= 1'b0;

                  if (rx_desc[125]==1'b1) begin  // 4DW header
                      case (rx_desc[3:2])
                          2'h1:    num_dw_to_read <= rx_desc[105:96] + 2'h1;                             // Address is 1 DW offset
                          2'h2:    num_dw_to_read <= (AVALON_ST_128==1'b1) ? (rx_desc[105:96] + 2'h2) :  // Address is 2 DW offset
                                                                             (rx_desc[105:96] + 2'h0);
                          2'h3:    num_dw_to_read <= (AVALON_ST_128==1'b1) ? (rx_desc[105:96] + 2'h3) :  // Address is 3 DW offset
                                                                             (rx_desc[105:96] + 2'h1);
                          default: num_dw_to_read <= rx_desc[105:96] + 2'h0;                             // Address is 0 DW offset
                      endcase
                      rx_hold_addr <= rx_desc[63:0];
                  end
                  else begin                     // 3DW header
                      case (rx_desc[35:34])
                          2'h1:    num_dw_to_read <= rx_desc[105:96] + 2'h1;                             // Address is 1 DW offset
                          2'h2:    num_dw_to_read <= (AVALON_ST_128==1'b1) ? (rx_desc[105:96] + 2'h2) :  // Address is 2 DW offset
                                                                             (rx_desc[105:96] + 2'h0);
                          2'h3:    num_dw_to_read <= (AVALON_ST_128==1'b1) ? (rx_desc[105:96] + 2'h3) :  // Address is 3 DW offset
                                                                             (rx_desc[105:96] + 2'h1);
                          default: num_dw_to_read <= rx_desc[105:96] + 2'h0;                             // Address is 0 DW offset
                      endcase
                      rx_hold_addr[63:32] <= 32'h0;
                      rx_hold_addr[31:0]  <= rx_desc[63:32];
                  end

                  // hold rx_desc fields for use in cpl
                  rx_hold_tag   <= rx_desc[79:72];
                  rx_hold_reqid <= rx_desc[95:80];

                  // If request is READ, then send a
                  // request to TX SM to send cpl.
                  // Else, wait for another request
                  if (rx_is_rdreq == 1'b1) begin
                      rx_start_read <= 1'b1;
                      cstate_rx <= RX_START_CPL;
                  end
                  else if (rx_is_wrreq == 1'b1) begin
                      if (rx_dfr==1'b1)
                          cstate_rx <= RX_DV_PAYLD;
                      else
                          cstate_rx <= RX_IDLE;
                  end
                  else begin
                      cstate_rx <= RX_IDLE;
                  end
              end
              RX_DV_PAYLD: begin
                  rx_start_write <= 1'b0;
                  if (rx_dfr==1'b0)   // last data cycle
                      cstate_rx <= RX_IDLE;
                  else
                      cstate_rx <= cstate_rx;
              end
              RX_START_CPL: begin
                  rx_start_read <= 1'b0;
                  // Wait for TX side to service the cpl request
                  if (cstate_tx!=TX_IDLE) begin
                      cstate_rx <= RX_WAIT_END_CPL;
                  end
                  else begin
                      cstate_rx <= cstate_rx;
                  end
              end
              RX_WAIT_END_CPL: begin
                  // Wait for TX side to finish sending the CPL
                  if (cstate_tx == TX_IDLE)
                      cstate_rx <= RX_IDLE;
                  else
                      cstate_rx <= cstate_rx;
              end
          endcase
      end
   end

   ////////////////////////////////////////////////////////////////
   // TX state machine - sends Completions
   // This module is a slave to the RX state machine cstate_rx
   ////////////////////////////////////////////////////////////////
   assign tx_arb_granted = (tx_ready_del == 1'b1) & (tx_sel == 1'b1);
   assign start_tx       = (tx_arb_granted==1'b1) & (fifo_empty==1'b0);
   assign tx_data        = fifo_data_out;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          cstate_tx      <= TX_IDLE;
          tx_req         <= 1'b0;
          tx_dfr         <= 1'b0;
          tx_dv          <= 1'b0;
          cfg_busdev_reg <= 16'h0;
          tx_ready       <= 1'b0;
          tx_ready_del   <= 1'b0;
          tx_busy        <= 1'b0;
          fifo_rd_count  <= 10'h0;
          tx_desc_length <= 10'h0;
          tx_desc_lbe    <= 4'h0;
          fifo_prefetch  <= 1'b0;
        tx_desc_addr   <= 0;
        tx_desc_req_id <= 0;
        tx_desc_tag    <= 0;
      end
      else begin
          tx_ready_del <= tx_ready;
          if (cstate_tx==TX_IDLE)
              fifo_rd_count <= 10'h0;
          else
              fifo_rd_count <= (fifo_rd==1'b1) ? fifo_rd_count + 1 : fifo_rd_count;

          ////////////////////
          // tx_desc fields

          cfg_busdev_reg <= cfg_busdev;
          tx_desc_addr   <= rx_hold_addr[6:0];
          tx_desc_tag    <= rx_hold_tag;
          tx_desc_req_id <= rx_hold_reqid;
          tx_desc_lbe    <= (rx_hold_length[9:0]==10'h1) ? 4'h0 : 4'hF;
          tx_desc_length <= rx_hold_length;
          //////////////////////////
          // tx_req, tx_dfr, tx_dv

          case (cstate_tx)
              TX_IDLE: begin
                  // wait for a request for CPL
                  tx_dv    <= 1'b0;
                  tx_ready <= (rx_do_cpl== 1'b1) ? 1'b1 : tx_ready;      // request access to PciE TX desc/data interface
                  if ((tx_arb_granted==1'b1) & (fifo_empty==1'b0)) begin  // start transmission on PciE TX desc/data interface
                      cstate_tx <= TX_SEND_DV_WAIT_ACK;
                      tx_req    <= 1'b1;
                      tx_dfr    <= 1'b1;
                      tx_busy   <= 1'b1;
                      fifo_prefetch <= 1'b1;
                  end
                  else begin
                      cstate_tx <= cstate_tx;
                      tx_busy   <= 1'b0;
                  end
              end
              TX_SEND_DV_WAIT_ACK: begin
                  fifo_prefetch <= 1'b0;
                  tx_ready <= 1'b0;
                  tx_dv    <= 1'b1;

                  if  ((mem_num_to_read==10'h1) || ((fifo_rd_count==mem_num_to_read_minus_one) & (tx_dv==1'b1) & (tx_ws==1'b0)))
                      tx_dfr <= 1'b0;
                  else
                      tx_dfr <= tx_dfr;

                  if (tx_ack == 1'b1) begin
                      tx_req <= 1'b0;
                      if ((tx_ws == 1'b0) & (mem_num_to_read==1)) begin
                         cstate_tx <= TX_IDLE;
                      end
                      else begin
                         cstate_tx <= TX_DV_PAYLD;
                      end
                  end
                  else begin
                      cstate_tx <= cstate_tx;
                      tx_req    <= tx_req;
                  end
              end
              TX_DV_PAYLD: begin
                  if (tx_ws == 1'b0) begin
                      if (fifo_rd_count == mem_num_to_read_minus_one)
                          tx_dfr <= 1'b0;
                      else
                          tx_dfr <= tx_dfr;

                      if (tx_dfr==1'b0) begin
                         cstate_tx <= TX_IDLE;
                         tx_dv     <= 1'b0;
                      end
                  end
                  else begin
                      cstate_tx <= cstate_tx;
                      tx_dv     <= tx_dv;
                  end
              end
          endcase
      end
   end
   assign tx_desc[127]     = `RESERVED_1BIT ;
   assign tx_desc[126:120] =  8'h4A;                // Format/Type = CplD
   assign tx_desc[119]     = `RESERVED_1BIT ;
   assign tx_desc[118:116] = `TLP_TC_DEFAULT;
   assign tx_desc[115:112] = `RESERVED_4BIT ;
   assign tx_desc[111]     = `TLP_TD_DEFAULT;
   assign tx_desc[110]     = `TLP_EP_DEFAULT;
   assign tx_desc[109:108] = `TLP_ATTR_DEFAULT;
   assign tx_desc[107:106] = `RESERVED_2BIT ;
   assign tx_desc[105:96]  =  tx_desc_length;
   assign tx_desc[95:83]   = cfg_busdev_reg;                // Completor ID bus, dev #
   assign tx_desc[82:80]   = 3'h0;                          // Completor ID function #
   assign tx_desc[79:76]   = 4'h0;                          // Successful completion
   assign tx_desc[75:64]   = {tx_desc_length[9:0], 2'h00};  // Read request is limited to Max payload size
   assign tx_desc[63:48]   = tx_desc_req_id;
   assign tx_desc[47:40]   = tx_desc_tag;
   assign tx_desc[39]      = 1'b0;
   assign tx_desc[38:32]   = tx_desc_addr;
   assign tx_desc[31:0]    = 32'h0;

   ////////////////////////////////////////////////////////////////////////////////////
   // Translate PCIE WRITE Requests to Memory WRITE Ctl and Datapath
   ////////////////////////////////////////////////////////////////////////////////////

   always @ (negedge rstn or posedge clk_in) begin         // pipeline this datapath
      if (rstn==1'b0) begin
          mem_wr_data <= {AVALON_WDATA{1'b0}};
          mem_wr_be   <= {AVALON_BE_WIDTH{1'b0}};
          mem_wr_ena  <= 1'b0;
          sel_epmem   <= 1'b0;
          mem_wr_addr <= {MEM_ADDR_WIDTH{1'b0}};
          reg_wr_addr <= 8'h0;
          reg_wr_data <= 32'h0;
      end
      else begin
          sel_epmem <= rx_sel_epmem;  // delay along with control signals.
          //////////////////////////////
          // MEMORY WRITE ENA, ADDRESS
          reg_wr_addr <= (rx_desc[125]==1'b1) ? rx_desc[7:0] : rx_desc[39:32];

          if (rx_desc[125]==1'b1) begin
              if (AVALON_ST_128==1'b1) begin                // 128-bit interface
                  case (rx_desc[3:2])
                     2'h0: reg_wr_data <= rx_data[31:0];
                     2'h1: reg_wr_data <= rx_data[63:32];
                     2'h2: reg_wr_data <= rx_data[AVALON_WDATA-33:AVALON_WDATA-64];
                     2'h3: reg_wr_data <= rx_data[AVALON_WDATA-1:AVALON_WDATA-32];
                  endcase
              end
              else begin                                     // 64-bit interface
                  case (rx_desc[2])
                     1'b0   : reg_wr_data <= rx_data[31:0];
                     default: reg_wr_data <= rx_data[63:32];
                  endcase
              end
          end
          else begin                                        // 3DW header
              if (AVALON_ST_128==1'b1) begin                // 128-bit interface
                  case (rx_desc[35:34])
                     2'h0: reg_wr_data <= rx_data[31:0];
                     2'h1: reg_wr_data <= rx_data[63:32];
                     2'h2: reg_wr_data <= rx_data[AVALON_WDATA-33:AVALON_WDATA-64];
                     2'h3: reg_wr_data <= rx_data[AVALON_WDATA-1:AVALON_WDATA-32];
                  endcase
              end
              else begin                                     // 64-bit interface
                  case (rx_desc[34])
                     1'b0   : reg_wr_data <= rx_data[31:0];
                     default: reg_wr_data <= rx_data[63:32];
                  endcase
              end
          end


          if (rx_start_write==1'b1) begin
              mem_wr_ena  <= 1'b1;
              if (AVALON_ST_128==1'b1)
                  mem_wr_addr <= (rx_desc[125]==1'b1) ? rx_desc[MEM_ADDR_WIDTH-1+4:4] : rx_desc[MEM_ADDR_WIDTH-1+36:36];
              else
                  mem_wr_addr <= (rx_desc[125]==1'b1) ? rx_desc[MEM_ADDR_WIDTH-1+3:3] : rx_desc[MEM_ADDR_WIDTH-1+35:35];
          end
          else if (rx_dv==1'b1) begin
              mem_wr_ena  <= 1'b1;
              mem_wr_addr <= mem_wr_addr + 1;
          end
          else begin
              mem_wr_ena  <= 1'b0;
              mem_wr_addr <= mem_wr_addr;
          end
          //////////////////////////////////
          // MEMORY WRITE DATAPATH
          // data is written on mem_wr_ena

          mem_wr_data <= rx_data;
          mem_wr_be   <= rx_be;
      end
  end

   ////////////////////////////////////////////////////////////////////////////////////
   // Translate PCIE READ Requests to Memory READ Ctl and Datapath
   ////////////////////////////////////////////////////////////////////////////////////

   always @ (negedge rstn or posedge clk_in) begin         // pipeline this datapath
      if (rstn==1'b0) begin
          mem_rd_ena        <= 1'b0;
          mem_rd_addr       <= {MEM_ADDR_WIDTH-1{1'b0}};
          mem_num_to_read   <= 10'h0;
          mem_read_count    <= 10'h0;
          mem_num_to_read_minus_one <= 10'h0;
          reg_rd_addr       <= {MEM_ADDR_WIDTH{1'b0}};
      end
      else begin
          /////////////////////////////
          // MEMORY READ ADDR/CONTROL

          mem_num_to_read_minus_one <= (|mem_num_to_read[9:1]) ? mem_num_to_read - 1 : 10'h0;
          reg_rd_addr <= rx_hold_addr[7:0];

          if (rx_start_read==1'b1) begin
              if (AVALON_ST_128==1'b1) begin
                  mem_rd_addr     <= rx_hold_addr[MEM_ADDR_WIDTH-1+4:4];
                  mem_num_to_read <= (|num_dw_to_read[1:0]==1'b1) ? (num_dw_to_read[9:2] + 1) : num_dw_to_read[9:2];
                  mem_read_count <= (|num_dw_to_read[1:0]==1'b1) ? num_dw_to_read[9:2]  : num_dw_to_read[9:2] - 1;
              end
              else begin
                  mem_rd_addr     <= rx_hold_addr[MEM_ADDR_WIDTH-1+3:3];
                  mem_num_to_read <= (num_dw_to_read[0]==1'b1) ? (num_dw_to_read[9:1] + 1) : num_dw_to_read[9:1];
                  mem_read_count <= (num_dw_to_read[0]==1'b1) ? (num_dw_to_read[9:1]) : num_dw_to_read[9:1] -1 ;
              end
              mem_rd_ena <= 1'b1;
          end
          else if ((mem_read_count != 0) & (fifo_almost_full == 1'b0)) begin
              mem_rd_ena     <= 1'b1;
              mem_rd_addr    <= mem_rd_addr + 1;
              mem_read_count <= mem_read_count - 1;
          end
          else begin
              mem_rd_ena     <= 1'b0;
              mem_rd_addr    <= mem_rd_addr;
              mem_read_count <= mem_read_count;
          end
      end
  end
   /////////////////////////////
   // MEMORY READ DATAPATH

   assign fifo_rd      = ((fifo_prefetch==1'b1) | ((tx_dv==1'b1) & (tx_ws==1'b0))) & (fifo_empty == 1'b0);

   reg                    fifo_wr;
   reg [AVALON_WDATA-1:0] fifo_data_in;

   always @ (posedge clk_in or negedge rstn) begin
       if (rstn==1'b0) begin
           fifo_wr      <= 1'b0;
           fifo_data_in <= {AVALON_WDATA{1'b0}};
       end
       else begin
           fifo_wr  <= mem_rd_data_valid | reg_rd_data_valid;
           if (AVALON_ST_128==1'b1)
               fifo_data_in <= reg_rd_data_valid ? {reg_rd_data, reg_rd_data, reg_rd_data, reg_rd_data} : mem_rd_data;
           else
               fifo_data_in <= reg_rd_data_valid ? {reg_rd_data, reg_rd_data} : mem_rd_data;
       end
   end


   // rate matching FIFO -
   // interfaces high latency RAM reads to
   // single-cycle turnaround desc/data interface

   scfifo # (  .add_ram_output_register ("ON")          ,
               .intended_device_family  ("Stratix II GX"),
               .lpm_numwords            (16),
               .lpm_showahead           ("OFF")          ,
               .lpm_type                ("scfifo")       ,
               .lpm_width               (AVALON_WDATA) ,
               .lpm_widthu              (4),
               .almost_full_value       (10) ,
               .overflow_checking       ("OFF")           ,
               .underflow_checking      ("OFF")           ,
               .use_eab                 ("ON")
               )
               tx_data_fifo (  .clock       (clk_in),
                               .aclr        (~rstn ),
                               .data        (fifo_data_in),
                               .wrreq       (fifo_wr),
                               .rdreq       (fifo_rd),
                               .q           (fifo_data_out),
                               .empty       (fifo_empty),
                               .almost_full (fifo_almost_full)

                               // synopsys translate_off
                               ,
                               .usedw        (),
                               .sclr         (),
                               .full         (),
                               .almost_empty ()
                               // synopsys translate_on
                         );
endmodule
