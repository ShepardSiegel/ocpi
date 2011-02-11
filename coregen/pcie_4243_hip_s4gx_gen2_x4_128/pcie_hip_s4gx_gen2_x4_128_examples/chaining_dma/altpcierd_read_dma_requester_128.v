// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It manages DMA read data transfer from
//  * the Root Complex memory to the End Point memory.
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
// Title         : DMA Read requestor module (altpcierd_read_dma_requester_128)
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_read_dma_requester_128.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
//
// - Retrieve descriptor info from the dt_fifo (module read descriptor)
//       states : cstate_tx = DT_FIFO_RD_QW0, DT_FIFO_RD_QW1
//       cdt_length_dw_tx : number of DWORDs to transfer
// - For each descriptor:
//       - Send multiple Mrd request for a max payload
//            tx_length=< cdt_length_dw_tx
//       - Each Tx MRd has TAG starting from 2--> MAX_NUMTAG.
//            A counter issue the TAG up to MAX_NUMTAG; When MAX_NUMTAG
//            the TAG are pop-ed from the TAG FIFO.
//            when Rx received packet (CPLD), the TAG is recycled (pushed)
//            into the TAG_FIFO if the completion of tx_length in TAG RAM
//
// - RAM : tag_dpram  :
//      hash table which tracks TAG information
//      Port A : is used by the TX code section
//        data_a    = {tx_length_dw[9:1], tx_tag_addr_offset_qw[AVALON_WADDR-1:0]};
//      Port B : is used by the RX code section
//        data_b    = {rx_length_dw[9:1], tx_tag_addr_offset_qw[AVALON_WADDR-1:0]};
//        q         =
// - FIFO : tag_scfifo  :
//      contains the list of TAG which can be re-used by the TX code section
//      The RX code section updates this FIFO by writting recycled TAG upon
//      completion
//
// - FIFO : rx_data_fifo  :
//      is used by the RX code section to eliminates RX_WS and increase
//      DMA read throughput.
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

module altpcierd_read_dma_requester_128  # (
   parameter MAX_NUMTAG      = 32,
   parameter RC_SLAVE_USETAG = 0,
   parameter FIFO_WIDTH      = 128,
   parameter TXCRED_WIDTH    = 36,
   parameter AVALON_WADDR    = 12,
   parameter AVALON_WDATA    = 128,
   parameter BOARD_DEMO      = 0,
   parameter USE_MSI         = 1,
   parameter USE_CREDIT_CTRL = 1,
   parameter INTENDED_DEVICE_FAMILY = "Cyclone IV GX",
   parameter RC_64BITS_ADDR  = 0,
   parameter AVALON_BYTE_WIDTH = AVALON_WDATA/8,
   parameter DT_EP_ADDR_SPEC   = 2,                  // Descriptor Table's EP Address is specified as:  3=QW Address,  2=DW Address, 1= W Address, 0= Byte Addr.
   parameter  CDMA_AST_RXWS_LATENCY = 2                 // response time fo rx_data to rx_ws

   )
   (
   // Descriptor control signals
   output                        dt_fifo_rdreq,
   input                         dt_fifo_empty,
   input      [FIFO_WIDTH-1:0]   dt_fifo_q    ,

   input [15:0] cfg_maxrdreq_dw,
   input [2:0]  cfg_maxrdreq ,
   input [4:0]  cfg_link_negociated ,
   input [63:0] dt_base_rc   ,
   input dt_3dw_rcadd ,
   input dt_eplast_ena,
   input dt_msi       ,
   input [15:0]  dt_size      ,

   //PCIe transmit
   output             tx_ready,
   output             tx_busy ,
   input              tx_sel  ,
   input [TXCRED_WIDTH-1:0]       tx_cred,
   input              tx_have_creds,
   input              tx_ack  ,
   input              tx_ws   ,
   output             tx_req  ,
   output   reg       tx_dv   ,
   output             tx_dfr  ,
   output     [127:0] tx_desc ,
   output     [127:0] tx_data ,
   input [15:0] rx_buffer_cpl_max_dw,  // specifify the maximum amount of data available in RX Buffer for a given MRd

   //PCIe receive
   input          rx_req   ,
   output         rx_ack  ,
   input [135:0]  rx_desc ,
   input [AVALON_WDATA-1:0]  rx_data ,
   input [15:0]   rx_be,
   input          rx_dv   ,
   input          rx_dfr  ,
   output         rx_ws   ,

   // MSI
   input   app_msi_ack,
   output  app_msi_req,
   input   msi_sel   ,
   output  msi_ready ,
   output  msi_busy  ,

   //avalon slave port
   output reg [AVALON_WDATA-1:0] writedata  ,
   output reg [AVALON_WADDR-1:0] address    ,
   output reg                    write      ,
   output                        waitrequest,
   output reg [AVALON_BYTE_WIDTH-1:0] write_byteena,

   // RC Slave control signals
   input         descriptor_mrd_cycle,
   output reg    requester_mrdmwr_cycle,
   output [3:0]  dma_sm_tx,
   output [2:0]  dma_sm_rx,
   output [2:0]  dma_sm_rx_data,

   output [63:0]  dma_status,
   output reg     cpl_pending,

   input  init   ,
   input  clk_in ,
   input  rstn
   );

// VHDL translation_on
//    function integer ceil_log2;
//       input integer numwords;
//       begin
//          ceil_log2=0;
//          numwords = numwords-1;
//          while (numwords>0)
//          begin
//             ceil_log2=ceil_log2+1;
//             numwords = numwords >> 1;
//          end
//       end
//    endfunction
//
//     function integer get_numwords;
//        input integer width;
//        begin
//           get_numwords = (1<<width);
//        end
//    endfunction
// VHDL translation_off


   // Parameter for TX State machine
   localparam DT_FIFO           =0 , // Ready for next Descriptor FIFO (DT)
              DT_FIFO_RD_QW0    =1 , // read First  QWORD
              DT_FIFO_RD_QW1    =2 , // read second QWORD
              MAX_RREQ_UPD      =3 , // Update lenght counters
              TX_LENGTH         =4 , // Update lenght counters
              START_TX          =5 , // Wait for top level arbitration tx_sel
              MRD_REQ           =6 , // Set tx_req, MRD
              MRD_ACK           =7 , // Get tx_ack
              GET_TAG           =8 , // Optional Tag FIFO Retrieve
              CPLD              =9 , // Wait for CPLD state machine (rx)
              DONE              =10,  // Completed MRD-CPLD
              START_TX_UPD_DT   =11, // Wait for top level arbitration tx_sel
              MWR_REQ_UPD_DT    =12, // Set tx_req, MWR
              MWR_ACK_UPD_DT    =13; // Get tx_ack

   // Parameter for RX State machine
   localparam CPLD_IDLE   = 0,
              CPLD_REQ    = 1,
              CPLD_ACK    = 2,
              CPLD_DV     = 3,
              CPLD_LAST   = 4;

   // Parameter for RX DATA FIFO State machine
   localparam SM_RX_DATA_FIFO_IDLE           = 0,
              SM_RX_DATA_FIFO_READ_TAGRAM_1  = 1,
              SM_RX_DATA_FIFO_READ_TAGRAM_2  = 2,
              SM_RX_DATA_FIFO_RREQ           = 3,
              SM_RX_DATA_FIFO_SINGLE_QWORD   = 4,
              SM_RX_DATA_FIFO_TAGRAM_UPD     = 5;

    // MSI State
   localparam  IDLE_MSI    = 0,// MSI Stand by
               START_MSI   = 1,// Wait for msi_sel
               MWR_REQ_MSI = 2;// Set app_msi_req, wait for app_msi_ack

   localparam DATA_WIDTH_DWORD                = AVALON_WDATA>>5;
   localparam ZERO_INTEGER                    = 0;
   localparam MAX_NUMTAG_VAL                  = MAX_NUMTAG-1;
   localparam FIRST_DMARD_TAG                 = 2+RC_SLAVE_USETAG;
   localparam FIRST_DMARD_TAG_SEC_DESCRIPTOR  = (MAX_NUMTAG-FIRST_DMARD_TAG)/2+FIRST_DMARD_TAG;
   localparam MAX_NUMTAG_VAL_FIRST_DESCRIPTOR = FIRST_DMARD_TAG_SEC_DESCRIPTOR-1;
   localparam TAG_TRACK_WIDTH                 = MAX_NUMTAG-2-RC_SLAVE_USETAG;
   localparam TAG_TRACK_HALF_WIDTH            = TAG_TRACK_WIDTH/2;
   localparam TAG_FIFO_DEPTH   = MAX_NUMTAG-2;

// localparam MAX_TAG_WIDTH    =  ceil_log2(MAX_NUMTAG);
   localparam MAX_TAG_WIDTH    = (MAX_NUMTAG<3  )?1:
                                 (MAX_NUMTAG<5  )?2:
                                 (MAX_NUMTAG<9  )?3:
                                 (MAX_NUMTAG<17 )?4:
                                 (MAX_NUMTAG<33 )?5:
                                 (MAX_NUMTAG<65 )?6:
                                 (MAX_NUMTAG<129)?7:8;


// localparam MAX_TAG_WIDTHU  =  ceil_log2(TAG_FIFO_DEPTH);
   localparam MAX_TAG_WIDTHU  =  (TAG_FIFO_DEPTH<3  )?1:
                                 (TAG_FIFO_DEPTH<5  )?2:
                                 (TAG_FIFO_DEPTH<9  )?3:
                                 (TAG_FIFO_DEPTH<17 )?4:
                                 (TAG_FIFO_DEPTH<33 )?5:
                                 (TAG_FIFO_DEPTH<65 )?6:
                                 (TAG_FIFO_DEPTH<129)?7:8;
   localparam LENGTH_DW_WIDTH  = 10;
   localparam LENGTH_QW_WIDTH  = 9;
   localparam TAG_EP_ADDR_WIDTH = (AVALON_WADDR+4);  // AVALON_WADDR is a 128-bit Address, Tag Ram stores Byte Address
   localparam TAG_RAM_WIDTH    = LENGTH_DW_WIDTH + TAG_EP_ADDR_WIDTH;
   localparam TAG_RAM_WIDTHAD  = MAX_TAG_WIDTH;

   localparam TAG_RAM_NUMWORDS = (1<<TAG_RAM_WIDTHAD);
// localparam TAG_RAM_NUMWORDS = get_numwords(TAG_RAM_WIDTHAD);

   localparam RX_DATA_FIFO_NUMWORDS      = 64;
   localparam RX_DATA_FIFO_WIDTHU        = 6;
   localparam RX_DATA_FIFO_ALMST_FULL_LIM= RX_DATA_FIFO_NUMWORDS-6;

   //  SOP| EOP| NUMBER OF TAG| AVALON_WDATA
   localparam RX_DATA_FIFO_WIDTH         = AVALON_WDATA+2+MAX_TAG_WIDTH + 16;

   integer i;
   assign waitrequest   = 0;


   // State machine registers for transmit MRd MWr (tx)
   reg [3:0]   cstate_tx;
   reg [3:0]   nstate_tx;
   reg         tx_mrd_cycle;

   // State machine registers for Receive CPLD (rx)
   reg [2:0]   cstate_rx;
   reg [2:0]   nstate_rx;

   //
   reg [2:0]   cstate_rx_data_fifo;
   reg [2:0]   nstate_rx_data_fifo;

   // MSI State machine registers
   // MSI could be send in parallel to EPLast
   reg [2:0]   cstate_msi;
   reg [2:0]   nstate_msi;

   // control bits : set when ep_lastup transmit
   reg ep_lastupd_cycle;

   reg [2:0]   rx_ws_ast; //rx_ws from Avalon ST
   reg         rx_ast_data_valid; //rx_ws from Avalon ST
   // Control counter for payload and dma length

   reg  [15:0] cdt_length_dw_tx; // cdt : length of the transfer (in DWORD)
                                 // for the current descriptor. This counter
                                 // is used for tx (Mrd)

   wire [12:0] cfg_maxrdreq_byte; // Max read request in bytes
   reg  [12:0] calc_4kbnd_mrd_ack_byte;
   reg [12:0] calc_4kbnd_dt_fifo_byte;
   wire [15:0] calc_4kbnd_mrd_ack_dw;
   wire [15:0] calc_4kbnd_dt_fifo_dw;
   reg [12:0]  tx_desc_addr_4k;
   wire [12:0] dt_fifo_q_addr_4k;
   reg  [15:0] maxrdreq_dw;
   reg  [9:0]   tx_length_dw ;   // length of tx_PCIE transfer in DWORD
                                 // tx_desc[105:96] = tx_length_dw when tx_req

   wire [11:0]  tx_length_byte  ; // length of tx_PCIE transfer in BYTE
                                 // tx_desc[105:96] = tx_length_dw when tx_req
   wire [31:0]  tx_length_byte_32ext  ;
   wire [63:0]  tx_length_byte_64ext  ;

   // control bits : check 32 bit vs 64 bit address
   reg         txadd_3dw;

   // control bits : generate tx_dfr & tx_dv
   reg         tx_req_reg;
   reg         tx_req_delay;

   // DMA registers
   reg         cdt_msi       ;// When set, send MSI to RC host
   reg         cdt_eplast_ena;// When set, update RC Host memory with dt_ep_last
   reg [15:0]  dt_ep_last    ;// Number of descriptors completed

   // PCIe Signals RC address
   wire  [MAX_TAG_WIDTH-1:0]  tx_tag_wire_mux_first_descriptor;
   wire  [MAX_TAG_WIDTH-1:0]  tx_tag_wire_mux_second_descriptor;
   wire tx_get_tag_from_fifo;
   reg  [7:0]   tx_tag_tx_desc;
   reg  [63:0]  tx_desc_addr ;
   wire  [63:0] tx_desc_addr_pipe ;
   reg  [31:0]  tx_desc_addr_3dw_pipe;
   reg  [63:0]  tx_addr_eplast;
   reg          addrval_32b; // indicates that a 64-bit address has upper dword equal to zero

   wire  [63:0] tx_addr_eplast_pipe;
   reg          tx_32addr_eplast;
   reg  [63:0]  tx_data_eplast;
   wire [3:0]   tx_lbe_d      ;
   wire [3:0]   tx_fbe_d      ;

   // tx_credit controls
   wire tx_cred_non_posted_header_valid;
   reg  tx_cred_non_posted_header_valid_x8;
   reg  tx_cred_posted_data_valid_8x;
   wire tx_cred_posted_data_valid_4x;
   wire tx_cred_posted_data_valid ;
   reg rx_buffer_cpl_ready;
   reg rx_tag_is_sec_desc;

   reg dt_ep_last_eq_dt_size;

   //
   // TAG management overview:
   //
   //     TAG 8'h00            : Descriptor read
   //     TAG 8'h01            : Descriptor write
   //     TAG 8'h02 -> MAX TAG : Requester read
   //
   //     TX issues MRd, with TAG "xyz" and length "tx_length" dword data
   //     RX ack CPLD with TAG "xyz", and length "rx_length" dword daata
   //
   //     The TX state machine write a new TAG for every MRd on port A of
   //     tag_dpram
   //     The RX state machine uses the port B of tag_dpram
   //        When cstate_rx==CPLD_REQ --> Read tag_dpram word with "tx_length"
   //        info.
   //        When (cstate_rx==CPLD_DV)||(cstate_rx==CPLD_LAST) write tag_dpram
   //        to reflect the number of dword read for a given TAG
   //     If  "tx_length" == "rx_length" the TAG is recycled in the tag_scfifo

   reg  [MAX_TAG_WIDTH-1:0] tx_tag_cnt_first_descriptor ;
   reg  [MAX_TAG_WIDTH-1:0] tx_tag_cnt_second_descriptor;
   reg  [MAX_TAG_WIDTH-1:0] rx_tag         ;

   reg                      tx_tag_mux_first_descriptor     ;
   reg                      tx_tag_mux_second_descriptor     ;

   // tag_scfifo:
   //    The tx_state machine read data
   //    The rx_statemachine pushes data
   wire tag_fifo_sclr                     ;
   wire rx_second_descriptor_tag;
   wire rx_fifo_wrreq_first_descriptor    ;
   wire rx_fifo_wrreq_second_descriptor   ;
   reg  tagram_wren_b_mrd_ack             ;
   wire tx_fifo_rdreq_first_descriptor    ;
   wire tx_fifo_rdreq_second_descriptor   ;
   wire [MAX_TAG_WIDTH-1:0] tx_tag_fifo_first_descriptor  ;
   wire [MAX_TAG_WIDTH-1:0] tx_tag_fifo_second_descriptor  ;
   wire tag_fifo_empty_first_descriptor   ;
   wire tag_fifo_empty_second_descriptor  ;
   wire tag_fifo_full_first_descriptor    ;
   wire tag_fifo_full_second_descriptor   ;

   wire rx_dmard_tag ; //set when rx_desc tag >FIRST_DMARD_TAG
   reg rx_dmard_cpld;
   reg valid_rx_dmard_cpld_next;
   reg valid_rx_dv_for_dmard;
   wire valid_rx_dmard_cpld; //set when
                             //  -- the second phase of rx_req,
                             //  + Valid tag
                             //  + Valid first phase of rx_req (CPLD and rx_dfr)

   // Constant used for VHDL translation
   wire cst_one;
   wire cst_zero;
   wire [63:0] cst_std_logic_vector_type_one;
   wire [511:0] cst_std_logic_vector_type_zero;
   wire [MAX_TAG_WIDTH-1:0] FIRST_DMARD_TAG_cst_width_eq_MAX_TAG_WIDTH;
   wire [MAX_TAG_WIDTH-1:0] FIRST_DMARD_TAG_SEC_DESCRIPTOR_cst_width_eq_MAX_TAG_WIDTH;

   // tag_dpram:
   //    data : tx_length_dw[9:1]      :QWORD LENGTH to know when recycle TAG
   //          tx_tag_addr_offset_qw[AVALON_WADDR-1:0]:EP Address offset (where PCIE write to)
   //          {tx_length_dw[9:1], tx_tag_addr_offset_qw[AVALON_WADDR-1:0]}
   //    Address : TAG
   wire tagram_wren_a                      ;
   wire [TAG_RAM_WIDTH-1:0] tagram_data_a  ;
   wire [MAX_TAG_WIDTH-1:0] tagram_address_a;

   reg  tagram_wren_b                      ;
   reg  tagram_wren_b_reg_init;
   reg [TAG_RAM_WIDTH-1:0] tagram_data_b  ;
   wire [MAX_TAG_WIDTH-1:0] tagram_address_b;
   reg  [MAX_TAG_WIDTH-1:0] tagram_address_b_mrd_ack;
   wire [TAG_RAM_WIDTH-1:0] tagram_q_b     ;

   reg  [9:0]                 rx_tag_length_dw ;
   reg [TAG_EP_ADDR_WIDTH-1:0]  rx_tag_addr_offset;
   wire [9:0]                    rx_tag_length_dw_next ;
   wire [TAG_EP_ADDR_WIDTH-1:0]  rx_tag_addr_offset_next;

   reg tx_first_descriptor_cycle;
   reg eplast_upd_first_descriptor;
   reg next_is_second;
   reg eplast_upd_second_descriptor;
   wire tx_cpld_first_descriptor;
   wire tx_cpld_second_descriptor;
   reg [TAG_TRACK_WIDTH-1:0] tag_track_one_hot;

   // Avalon address
   reg [AVALON_WADDR-1:0]  ep_addr;   // Base address of the EP memeory
   reg [TAG_EP_ADDR_WIDTH-1:0]  tx_tag_addr_offset; // max 15:0 dword
                                  // If multiple are needed, this track the
                                  // EP adress offset for each tag in the TAGRAM
   // Receive signals section
   wire [1:0] rx_fmt ;
   wire [4:0] rx_type;

   // RX Data fifo signals
   wire [RX_DATA_FIFO_WIDTH + 10:0] rx_data_fifo_data;
   wire [RX_DATA_FIFO_WIDTH + 10:0] rx_data_fifo_q;
   wire      rx_data_fifo_sclr;
   wire      rx_data_fifo_wrreq;
   wire      rx_data_fifo_rdreq;
   wire      rx_data_fifo_full;
   wire [RX_DATA_FIFO_WIDTHU-1:0]  rx_data_fifo_usedw;
   reg       rx_data_fifo_almost_full;
   wire      rx_data_fifo_empty;

   reg       rx_dv_pulse_reg;
   wire      rx_dv_start_pulse;
   wire      rx_dv_end_pulse;
   reg       rx_dv_end_pulse_reg;
   reg [MAX_TAG_WIDTH-1:0] rx_data_fifo_rx_tag;

   reg       tagram_data_rd_cycle;

   reg [23:0] performance_counter;

   reg rx_req_reg;
   reg rx_req_p1 ;
   wire rx_req_p0;

   wire [63:0] dt_fifo_ep_addr_byte;

   reg   cdt_msi_first_descriptor;
   reg   cdt_msi_second_descriptor;
   reg   cdt_eplast_first_descriptor;
   reg   cdt_eplast_second_descriptor;

   reg [9:0] rx_length_hold;
   reg [9:0] rx_data_fifo_length_hold;

   wire  got_all_cpl_for_tag;
   wire  rcving_last_cpl_for_tag_n;
   reg   rcving_last_cpl_for_tag;
   reg   transferring_data, transferring_data_n;
   reg [9:0] tag_remaining_length;

   reg [MAX_TAG_WIDTH-1:0] tagram_address_b_reg;
   reg rx_fifo_wrreq_first_descriptor_reg;
   reg rx_fifo_wrreq_second_descriptor_reg;


   assign  dma_status = tx_data_eplast;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         rx_req_reg <= 1'b1;
         rx_req_p1  <= 1'b0;
      end
      else begin
         rx_req_reg <= rx_req;
         rx_req_p1  <= rx_req_p0;
      end
   end
   assign rx_req_p0 = rx_req & ~rx_req_reg;

   always @ (posedge clk_in) begin
      if (init==1'b1)
         rx_dv_pulse_reg <= 1'b0;
      else
         rx_dv_pulse_reg <= rx_dv;
   end

   assign rx_dv_start_pulse = ((rx_dv==1'b1) && (rx_dv_pulse_reg==1'b0))?1'b1:1'b0;
   assign rx_dv_end_pulse   = ((rx_dfr==1'b0) && (rx_dv==1'b1) & (rx_ast_data_valid==1'b1))?1'b1:1'b0;

   assign dma_sm_tx = cstate_tx;
   assign dma_sm_rx = cstate_rx;
   assign dma_sm_rx_data = cstate_rx_data_fifo;

   // Constant carrying width type for VHDL translation
   assign cst_one         = 1'b1;
   assign cst_zero        = 1'b0;
   assign cst_std_logic_vector_type_one  = 64'hFFFF_FFFF_FFFF_FFFF;
   assign cst_std_logic_vector_type_zero = 512'h0;

   assign FIRST_DMARD_TAG_cst_width_eq_MAX_TAG_WIDTH=
                                                FIRST_DMARD_TAG;

   assign FIRST_DMARD_TAG_SEC_DESCRIPTOR_cst_width_eq_MAX_TAG_WIDTH=
                                                FIRST_DMARD_TAG_SEC_DESCRIPTOR;

   assign dt_fifo_ep_addr_byte = (DT_EP_ADDR_SPEC==0) ? dt_fifo_q[63:32]  : {dt_fifo_q[63-DT_EP_ADDR_SPEC:32], {DT_EP_ADDR_SPEC{1'b0}}};   // Convert the EP Address (from the Descriptor Table) to a Byte address


   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_addr_offset <= 0;
      else if (cstate_tx==DT_FIFO_RD_QW0)
         tx_tag_addr_offset <= dt_fifo_ep_addr_byte;
      else if (cstate_tx==MRD_ACK)
         tx_tag_addr_offset <= tx_tag_addr_offset + {tx_length_dw[9:0], 2'b00};
   end



   // PCIe 4K byte boundary off-set

   assign cfg_maxrdreq_byte[1:0] = 2'b00;
   assign cfg_maxrdreq_byte[12:2] = cfg_maxrdreq_dw[10:0];

   // calc maxrdreq_dw after DT_FIFO_RD_QW1
   assign dt_fifo_q_addr_4k[12] = 1'b0;
   assign dt_fifo_q_addr_4k[11:0] = dt_fifo_q[43+64:32+64];

   always @ (posedge clk_in) begin
      if (init==1'b1)
         calc_4kbnd_dt_fifo_byte <= cfg_maxrdreq_byte;
      else if (cstate_tx==DT_FIFO_RD_QW1)
         calc_4kbnd_dt_fifo_byte <= 13'h1000-dt_fifo_q_addr_4k;
   end
   assign calc_4kbnd_dt_fifo_dw[15:11] = 0;
   assign calc_4kbnd_dt_fifo_dw[10:0] = calc_4kbnd_dt_fifo_byte[12:2];


   // calc maxrdreq_dw after MRD_REQ
   always @ (posedge clk_in) begin
      if (init==1'b1)
         calc_4kbnd_mrd_ack_byte <= cfg_maxrdreq_byte;
      else if ((cstate_tx==MRD_REQ) && (tx_ack==1'b1))
         calc_4kbnd_mrd_ack_byte <= 13'h1000-tx_desc_addr_4k;
   end
   assign calc_4kbnd_mrd_ack_dw[15:11] = 0;
   assign calc_4kbnd_mrd_ack_dw[10:0] = calc_4kbnd_mrd_ack_byte[12:2];
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_desc_addr_4k <= 0;
      else if ((cstate_tx==MRD_REQ) && (tx_ack==1'b0)) begin
         if ((txadd_3dw==1'b1)||(RC_64BITS_ADDR==0))
            tx_desc_addr_4k[11:0] <= tx_desc_addr[43:32]+tx_length_byte;
         else
            tx_desc_addr_4k[11:0] <= tx_desc_addr[11:0]+tx_length_byte;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         maxrdreq_dw <= cfg_maxrdreq_dw;
      else if (cstate_tx==MRD_ACK) begin
         if (cfg_maxrdreq_byte > calc_4kbnd_mrd_ack_byte)
            maxrdreq_dw <= calc_4kbnd_mrd_ack_dw;
         else
            maxrdreq_dw <= cfg_maxrdreq_dw;
      end
      else if (cstate_tx==MAX_RREQ_UPD) begin
         if (cfg_maxrdreq_byte > calc_4kbnd_dt_fifo_byte)
            maxrdreq_dw <= calc_4kbnd_dt_fifo_dw;
         else
            maxrdreq_dw <= cfg_maxrdreq_dw;
      end
   end

   always @ (posedge clk_in) begin
      // DWORD handling
      if (init==1'b1)
         cdt_length_dw_tx <= 0;
      else begin
         if (cstate_tx==DT_FIFO_RD_QW0)
            cdt_length_dw_tx <= dt_fifo_q[15:0];
         else if (cstate_tx==TX_LENGTH) begin
            if (cdt_length_dw_tx<maxrdreq_dw)
               cdt_length_dw_tx <= 0;
            else
               cdt_length_dw_tx <= cdt_length_dw_tx-maxrdreq_dw;
         end
      end
   end

   // DWORD count management
   always @ (posedge clk_in) begin
      if ((cstate_tx==DT_FIFO)||(cstate_tx==MRD_ACK))
         tx_length_dw <= 0;
      else begin
         if (cstate_tx==TX_LENGTH) begin
            if (cdt_length_dw_tx<maxrdreq_dw)
               tx_length_dw <= cdt_length_dw_tx;
            else
               tx_length_dw <= maxrdreq_dw;
         end
      end
   end

   always @ * begin
      if (cdt_length_dw_tx<maxrdreq_dw) begin
         if (rx_buffer_cpl_max_dw<cdt_length_dw_tx)
            rx_buffer_cpl_ready<=1'b0;
         else
            rx_buffer_cpl_ready<=1'b1;
      end
      else begin
         if (rx_buffer_cpl_max_dw<maxrdreq_dw)
            rx_buffer_cpl_ready<=1'b0;
         else
            rx_buffer_cpl_ready<=1'b1;
      end
   end

   assign tx_length_byte[11:2]       = tx_length_dw[9:0];
   assign tx_length_byte[1:0]        = 2'b00;
   assign tx_length_byte_32ext[11:0] = tx_length_byte[11:0];
   assign tx_length_byte_32ext[31:12]= 0;
   assign tx_length_byte_64ext[11:0] = tx_length_byte[11:0];
   assign tx_length_byte_64ext[63:12]= 0;

   // Credit and flow control signaling
   generate
   begin
   if (TXCRED_WIDTH>36)
      begin
         always @ (posedge clk_in) begin
            if (init==1'b1)
               tx_cred_non_posted_header_valid_x8<=1'b0;
            else begin
               if  ((tx_cred[27:20]>0)||(tx_cred[62]==1))
                  tx_cred_non_posted_header_valid_x8 <= 1'b1;
               else
                  tx_cred_non_posted_header_valid_x8 <= 1'b0;
            end
         end
      end
   end
   endgenerate

   assign tx_cred_non_posted_header_valid = (USE_CREDIT_CTRL==0)?1'b1: tx_have_creds;

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_cred_posted_data_valid_8x<=1'b0;
      else begin
         if (((tx_cred[7:0]>0)||(tx_cred[TXCRED_WIDTH-6]==1'b1))&&
                  ((tx_cred[19:8]>0)||(tx_cred[TXCRED_WIDTH-5]==1'b1)))
           tx_cred_posted_data_valid_8x <= 1'b1;
         else
            tx_cred_posted_data_valid_8x <= 1'b0;
      end
   end

   assign tx_cred_posted_data_valid_4x = ((tx_cred[0]==1'b1)&&(tx_cred[9:1]>0))?1'b1:1'b0;
   assign tx_cred_posted_data_valid = (USE_CREDIT_CTRL==0)?1'b1: (TXCRED_WIDTH==66)?
                                         tx_cred_posted_data_valid_8x: tx_cred_posted_data_valid_4x;
   //
   // Transmit signal section tx_desc, tx_dv, tx_req...
   //
   assign tx_ready = (((cstate_tx==START_TX)                  &&
                       (tx_cred_non_posted_header_valid==1'b1)&&
                       (rx_buffer_cpl_ready==1'b1)) ||
                      ((cstate_tx==START_TX_UPD_DT)&&
                       (tx_cred_posted_data_valid==1'b1)           ))?1'b1:1'b0;

   assign tx_busy  = ((cstate_tx==MRD_REQ)||(tx_dv==1'b1)||
                       (tx_dfr==1'b1)||(cstate_tx==MWR_REQ_UPD_DT)) ?1'b1:1'b0;

   assign tx_req   = (((cstate_tx==MRD_REQ)||(cstate_tx==MWR_REQ_UPD_DT)) &&
                        (tx_ack==1'b0))? 1'b1:1'b0;
   assign tx_lbe_d = (tx_length_dw[9:0]==10'h1) ? 4'h0 : 4'hf;
   assign tx_fbe_d = 4'hF;

   assign tx_desc[127]     = `RESERVED_1BIT;
   wire   [1:0] tx_desc_fmt_32;
   wire   [1:0] tx_desc_fmt_64;

   assign tx_desc_fmt_32 = (ep_lastupd_cycle==1'b1)?`TLP_FMT_3DW_W:
                                                    `TLP_FMT_3DW_R;

   assign tx_desc_fmt_64 = ((ep_lastupd_cycle==1'b1)&&(dt_3dw_rcadd==1'b1))?`TLP_FMT_3DW_W :
                           ((ep_lastupd_cycle==1'b1)&&(dt_3dw_rcadd==1'b0))?`TLP_FMT_4DW_W :
                           ((ep_lastupd_cycle==1'b0)&&(addrval_32b==1'b1)) ?`TLP_FMT_3DW_R:`TLP_FMT_4DW_R;

   assign tx_desc[126:125] = (RC_64BITS_ADDR==0)?tx_desc_fmt_32:
                                                 tx_desc_fmt_64;
   assign tx_desc[124:120] = (ep_lastupd_cycle==1'b1)?`TLP_TYPE_WRITE:
                                                      `TLP_TYPE_READ;
   assign tx_desc[119]     = `RESERVED_1BIT     ;
   assign tx_desc[118:116] = `TLP_TC_DEFAULT    ;
   assign tx_desc[115:112] = `RESERVED_4BIT     ;
   assign tx_desc[111]     = `TLP_TD_DEFAULT    ;
   assign tx_desc[110]     = `TLP_EP_DEFAULT    ;
   assign tx_desc[109:108] = `TLP_ATTR_DEFAULT  ;
   assign tx_desc[107:106] = `RESERVED_2BIT     ;
   assign tx_desc[105:96]  = (ep_lastupd_cycle==1'b1)?2:tx_length_dw[9:0];
   assign tx_desc[95:80]   = `ZERO_WORD         ;
   assign tx_desc[79:72]   = (ep_lastupd_cycle==1'b1)?0:tx_tag_tx_desc ;
   assign tx_desc[71:64]   = {tx_lbe_d,tx_fbe_d};
   assign tx_desc[63:0]    = (ep_lastupd_cycle==1'b1)?tx_addr_eplast:
                             (addrval_32b==1'b1)     ?{tx_desc_addr[31:0],32'h0}:tx_desc_addr;

   // Hardware performance counter
   always @ (posedge clk_in) begin
      if (init==1'b1)
         performance_counter <= 0;
     // else if ((dt_ep_last==dt_size) && (cstate_tx==MWR_ACK_UPD_DT))
      else if ((dt_ep_last_eq_dt_size==1'b1) && (cstate_tx==MWR_ACK_UPD_DT))
         performance_counter <= 0;
      else begin
         if ((requester_mrdmwr_cycle==1'b1) || (descriptor_mrd_cycle==1'b1))
            performance_counter <= performance_counter+1;
         else if (tx_ws==0)
            performance_counter <= 0;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         requester_mrdmwr_cycle<=1'b0;
      else if ((dt_fifo_empty==1'b0) && (cstate_tx==DT_FIFO))
         requester_mrdmwr_cycle<=1'b1;
      else if ((dt_fifo_empty==1'b1)&&(cstate_tx==DT_FIFO) &&
               (tx_ws==1'b0) &&
               (eplast_upd_first_descriptor==1'b0)&&
               (eplast_upd_second_descriptor==1'b0))
         requester_mrdmwr_cycle<=1'b0;
   end

   // 63:57 Indicates which board is being used
   //    0 - Altera Stratix II GX  x1
   //    1 - Altera Stratix II GX  x4
   //    2 - Altera Stratix II GX  x8
   //    3 - Cyclone II            x1
   //    4 - Arria GX              x1
   //    5 - Arria GX              x4
   //    6 - Custom PHY            x1
   //    7 - Custom PHY            x4
   // When bit 56 set, indicates x8 configuration 256 Mhz back-end
   // 55:53  maxpayload for MWr
   // 52:48  number of lanes negocatied
   // 47:32 indicates the number of the last processed descriptor
   // 31:24 Number of tags
   // When 52:48  number of lanes negocatied
   always @ (posedge clk_in) begin
      tx_data_eplast[63:57] <= BOARD_DEMO;
      if (TXCRED_WIDTH>36)
         tx_data_eplast[56]    <= 1'b1;
      else
         tx_data_eplast[56]    <= 1'b0;
      tx_data_eplast[55:53] <= cfg_maxrdreq;
      tx_data_eplast[52:49] <= cfg_link_negociated[3:0];
      tx_data_eplast[48]    <= dt_fifo_empty;
      tx_data_eplast[47:32] <= dt_ep_last;
      tx_data_eplast[31:24] <= MAX_NUMTAG;
      tx_data_eplast[23:0]  <= performance_counter;
   end

   assign tx_data =  {tx_data_eplast[63:0], tx_data_eplast[63:0]};    // assumes dt_rc_base is a QWord address

   // Generation of tx_dfr signal
   always @ (posedge clk_in) begin
      if ((cstate_tx==START_TX_UPD_DT)||(cstate_tx==DT_FIFO))
         tx_req_reg <= 1'b0;
      else if (cstate_tx==MWR_REQ_UPD_DT)
         tx_req_reg <= 1'b1;
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_req_delay<=1'b0;
      else
         tx_req_delay<=tx_req;
   end

   assign tx_dfr = tx_req & ~tx_req_reg & ep_lastupd_cycle;

   // Generation of tx_dv signal
   always @ (posedge clk_in) begin
      if (cstate_tx==DT_FIFO)
         tx_dv <= 1'b0;
      else if (ep_lastupd_cycle==1'b1)
         tx_dv <= (tx_dfr==1'b1) ? 1'b1 : (tx_ws==1'b0) ? 1'b0 : tx_dv;    // Hold tx_dv until accepted
   end

   // DT_FIFO signaling
   assign dt_fifo_rdreq = ((dt_fifo_empty==1'b0)&&
                           (cstate_tx==DT_FIFO))? 1'b1:1'b0;

   // DMA Write control signal msi, ep_lastena
   always @ (posedge clk_in) begin
      if (cstate_tx==DT_FIFO_RD_QW0) begin
         cdt_msi        <= dt_msi       |dt_fifo_q[16];
         cdt_eplast_ena <= dt_eplast_ena|dt_fifo_q[17];
         if (tx_first_descriptor_cycle==1'b1) begin
             cdt_msi_first_descriptor     <= (dt_msi |dt_fifo_q[16]) ? 1'b1 : 1'b0;
             cdt_eplast_first_descriptor  <= (dt_eplast_ena |dt_fifo_q[17])? 1'b1 : 1'b0;
             cdt_msi_second_descriptor    <= cdt_msi_second_descriptor;
             cdt_eplast_second_descriptor <= cdt_eplast_second_descriptor;
         end
         else begin
             cdt_msi_first_descriptor     <= cdt_msi_first_descriptor;
             cdt_eplast_first_descriptor  <= cdt_eplast_first_descriptor;
             cdt_msi_second_descriptor    <= (dt_msi |dt_fifo_q[16]) ? 1'b1 : 1'b0;
             cdt_eplast_second_descriptor <= (dt_eplast_ena |dt_fifo_q[17])? 1'b1 : 1'b0;
         end
      end
   end

   //Section related to EPLAST rewrite
   // Upadting RC memory register dt_ep_last

   always @ (posedge clk_in) begin
      if ((cstate_tx == START_TX_UPD_DT)||(cstate_tx == MWR_REQ_UPD_DT))
         ep_lastupd_cycle <=1'b1;
      else
         ep_lastupd_cycle <=1'b0;
   end

   //
   // EP Last counter dt_ep_last : track the number of descriptor processed
   //
   always @ (posedge clk_in) begin
      if (init==1'b1) begin
         dt_ep_last            <=0;
         dt_ep_last_eq_dt_size <= 1'b0;
      end
      else begin
         dt_ep_last_eq_dt_size <= (dt_ep_last==dt_size) ? 1'b1 : 1'b0;
         if (cstate_tx == MWR_ACK_UPD_DT) begin
           //  if (dt_ep_last==dt_size)
             if (dt_ep_last_eq_dt_size==1'b1)
                dt_ep_last <=0;
             else
                dt_ep_last <=dt_ep_last+1;
         end
      end
   end

   // TX_Address Generation section : tx_desc_addr, tx_addr_eplast
   // check static parameter for 64 bit vs 32 bits RC : RC_64BITS_ADDR

   always @ (posedge clk_in) begin
      tx_desc_addr_3dw_pipe[31:0] <= tx_desc_addr[63:32]+tx_length_byte_32ext;
   end

   always @ (posedge clk_in) begin
      if (cstate_tx==DT_FIFO) begin
         tx_desc_addr <= 0;
         txadd_3dw    <= 1'b1;
         addrval_32b  <= 1'b0;
      end
      else if (RC_64BITS_ADDR==0) begin
         txadd_3dw    <= 1'b1;
         addrval_32b  <= 1'b0;
         tx_desc_addr[31:0]   <= `ZERO_DWORD;

         // generate tx_desc_addr
         if (cstate_tx==DT_FIFO_RD_QW1)
            tx_desc_addr[63:32]  <= dt_fifo_q[63+64:32+64];
         else if (cstate_tx==MRD_ACK)
            // TO DO assume double word
           tx_desc_addr[63:32]<=tx_desc_addr_3dw_pipe[31:0];
      end
      else begin
         if (cstate_tx==DT_FIFO_RD_QW1) begin
            // RC ADDR MSB if qword aligned
            addrval_32b             <= 1'b0;
            if (dt_fifo_q[31+64:0+64]==`ZERO_DWORD) begin
               txadd_3dw            <= 1'b1;
               tx_desc_addr[63:32]  <= dt_fifo_q[63+64:32+64];
               tx_desc_addr[31:0]   <= `ZERO_DWORD;
            end
            else begin
               txadd_3dw     <= 1'b0;
               tx_desc_addr[31:0] <= dt_fifo_q[63+64:32+64];
               tx_desc_addr[63:32] <= dt_fifo_q[31+64:0+64];
            end
         end
         else if (cstate_tx==MRD_ACK) begin
            // TO DO assume double word
            if (txadd_3dw==1'b1) begin
               tx_desc_addr[63:32] <= tx_desc_addr[63:32]+tx_length_byte_32ext;
               addrval_32b         <= 1'b0;
            end
            else begin
               //tx_desc_addr <= tx_desc_addr+tx_length_byte_64ext;
               tx_desc_addr <= tx_desc_addr_pipe;
               if (tx_desc_addr_pipe[63:32]==32'h0)
                  addrval_32b         <= 1'b1;
               else
                  addrval_32b         <= 1'b0;
            end
         end
      end
   end

       lpm_add_sub  # (
              .lpm_direction ("ADD"),
              .lpm_hint ( "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO"),
              .lpm_pipeline ( 2),
              .lpm_type ( "LPM_ADD_SUB"),
              .lpm_width ( 64))
      addr64_add (
                .dataa (tx_desc_addr),
                .datab (tx_length_byte_64ext),
                .clock (clk_in),
                .result (tx_desc_addr_pipe)
                // synopsys translate_off
                ,
                .aclr (),
                .add_sub (),
                .cin (),
                .clken (),
                .cout (),
                .overflow ()
                // synopsys translate_on
                );
   // Generation of address of tx_addr_eplast and
   // tx_32addr_eplast bit which indicates that this is a 32 bit address
   always @ (posedge clk_in) begin
      if (RC_64BITS_ADDR==0) begin
         tx_32addr_eplast     <=1'b1;
         tx_addr_eplast[31:0] <= `ZERO_DWORD;

         // generate tx_addr_eplast
         if (init==1'b1)
           tx_addr_eplast[63:32]<=`ZERO_DWORD;
         else if  (cstate_tx == DT_FIFO_RD_QW0)
           tx_addr_eplast[63:32]<=dt_base_rc[31:0]+32'h0000_0008;
      end
      else begin
         if (init==1'b1) begin
            tx_32addr_eplast <=1'b1;
            tx_addr_eplast<=0;
         end
         else if  (cstate_tx == DT_FIFO_RD_QW0) begin
            if (dt_3dw_rcadd==1'b1) begin
               tx_32addr_eplast     <=1'b1;
               tx_addr_eplast[63:32] <= dt_base_rc[31:0]+
                                        32'h0000_0008;
               tx_addr_eplast[31:0] <= `ZERO_DWORD;
            end
            else begin
               tx_32addr_eplast     <=1'b0;
               //tx_addr_eplast <= dt_base_rc+64'h8;
               tx_addr_eplast <= tx_addr_eplast_pipe;
            end
        end
      end
   end

       lpm_add_sub  # (
              .lpm_direction ("ADD"),
              .lpm_hint ( "ONE_INPUT_IS_CONSTANT=YES,CIN_USED=NO"),
              .lpm_pipeline ( 2),
              .lpm_type ( "LPM_ADD_SUB"),
              .lpm_width ( 64))
        addr64_add_eplast (
                .datab (dt_base_rc),
                .dataa (64'h8),
                .clock (clk_in),
                .result (tx_addr_eplast_pipe)
                // synopsys translate_off
                ,
                .aclr (),
                .add_sub (),
                .cin (),
                .clken (),
                .cout (),
                .overflow ()
                // synopsys translate_on
                );

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_mrd_cycle<=1'b0;
      else begin
         if (cstate_tx==DT_FIFO_RD_QW0)
             tx_mrd_cycle<=1'b1;
         else if (cstate_tx==CPLD)
             tx_mrd_cycle<=1'b0;
     end
   end

   assign tx_get_tag_from_fifo =  (((tx_tag_mux_first_descriptor==1'b1) &&
                                    (tx_first_descriptor_cycle==1'b1))||
                                   ((tx_tag_mux_second_descriptor==1'b1) &&
                                    (tx_first_descriptor_cycle==1'b0)))?
                                    1'b1:1'b0;

   // Requester Read state machine (Transmit)
   //    Combinatorial state transition (case state)
   always @*
   case (cstate_tx)
      DT_FIFO:
      // Descriptor FIFO - ready to read the next descriptor 4 DWORDS
         begin
            if (init==1'b1)
                nstate_tx = DT_FIFO;
            else if (dt_fifo_empty==1'b0)
               nstate_tx = DT_FIFO_RD_QW0;
            else if ((eplast_upd_first_descriptor==1'b1) &&
                          (tx_cpld_first_descriptor==1'b1) )
                nstate_tx = DONE;
            else if ((eplast_upd_second_descriptor==1'b1) &&
                          (tx_cpld_second_descriptor==1'b1) )
                nstate_tx = DONE;
            else
                nstate_tx = DT_FIFO;
         end

      DT_FIFO_RD_QW0:
      // set dt_fifo_rd_req for DW0
         nstate_tx = DT_FIFO_RD_QW1;

      DT_FIFO_RD_QW1:
         // Wait for any pending MSI to issue before transmitting
         if (cstate_msi==IDLE_MSI)
            // set dt_fifo_rd_req for DW1
               nstate_tx = MAX_RREQ_UPD;
         else
               nstate_tx = cstate_tx;
      MAX_RREQ_UPD:
         begin
            if (tx_get_tag_from_fifo==1'b1)
               nstate_tx = GET_TAG;
            else
               nstate_tx = TX_LENGTH;
         end

      TX_LENGTH:
         nstate_tx = START_TX;

      START_TX:
      // Waiting for Top level arbitration (tx_sel) prior to tx MEM64_WR
         begin
            if ((init==1'b1)||(tx_length_dw==0))
               nstate_tx = DT_FIFO;
            else begin
               if ((tx_sel==1'b1)&&(rx_buffer_cpl_ready==1'b1))
                  nstate_tx = MRD_REQ;
               else
                  nstate_tx = START_TX;
            end
         end

      MRD_REQ:  // Read Request Assert tx_req
      // Set tx_req, Waiting for tx_ack
         begin
            if (init==1'b1)
               nstate_tx = DT_FIFO;
            else if (tx_ack==1'b1)
               nstate_tx = MRD_ACK;
            else
               nstate_tx = MRD_REQ;
         end

      MRD_ACK: // Read Request Ack. tx_ack
      // Received tx_ack, clear tx_req, MRd next data chunk
         begin
            if (cdt_length_dw_tx==0)
               nstate_tx = CPLD;
            else if (tx_get_tag_from_fifo==1'b1)
               nstate_tx = GET_TAG;
            else
               nstate_tx = TX_LENGTH;
         end

      GET_TAG:
      // Retrieve a TAG from the TAG FIFO
         begin
            if (init==1'b1)
               nstate_tx = DT_FIFO;
            else if ((tag_fifo_empty_first_descriptor==1'b0) &&
                            (tx_first_descriptor_cycle==1'b1))
               nstate_tx = TX_LENGTH;
            else if ((tag_fifo_empty_second_descriptor==1'b0) &&
                            (tx_first_descriptor_cycle==1'b0))
               nstate_tx = TX_LENGTH;
            else
               nstate_tx = GET_TAG;// Waiting for a new TAG from the TAG FIFO
         end

      CPLD:
      // Waiting for completion for RX state machine (CPLD)
         begin
            if (init == 1'b1)
               nstate_tx = DT_FIFO;
            else begin
               if (tx_cpld_first_descriptor==1'b0) begin
                  if (tx_cpld_second_descriptor==1'b1) begin
                     if (eplast_upd_second_descriptor==1'b1)
                        nstate_tx = DONE;
                     else
                        nstate_tx = DT_FIFO;
                  end
                  else
                        // 2 descriptor are being processed, waiting
                        // for the completion of at least one descriptor
                        nstate_tx = CPLD;
               end
               else begin
                  if (eplast_upd_first_descriptor==1'b1)
                        nstate_tx = DONE;
                  else
                        nstate_tx = DT_FIFO;
               end
            end
        end

      DONE:
         begin
            if (((msi_ready==1'b0) & (msi_busy==1'b0)) | (cdt_msi==1'b0)) begin  // if MSI is enabled, wait in DONE state until msi_req can be issued by MSI sm
              if ( ((cdt_eplast_first_descriptor == 1'b1) & (eplast_upd_first_descriptor==1'b1) & (tx_cpld_first_descriptor==1'b1)) |
                   ((cdt_eplast_second_descriptor == 1'b1) & (eplast_upd_second_descriptor==1'b1) & (tx_cpld_second_descriptor==1'b1)) )
                  nstate_tx = START_TX_UPD_DT;
               else
                  nstate_tx = MWR_ACK_UPD_DT;
            end
            else begin
                nstate_tx = DONE;
            end
         end

      // Update RC Memory for polling info with the last
      // processed/completed descriptor

      START_TX_UPD_DT:
      // Waiting for Top level arbitration (tx_sel) prior to tx MEM64_WR
         begin
            if (init==1'b1)
               nstate_tx = DT_FIFO;
            else begin
               if ((tx_sel==1'b1)&& (rx_buffer_cpl_ready==1'b1))
                  nstate_tx = MWR_REQ_UPD_DT;
               else
                  nstate_tx = START_TX_UPD_DT;
            end
         end

      MWR_REQ_UPD_DT:
      // Set tx_req, Waiting for tx_ack
         begin
            if (init==1'b1)
               nstate_tx = DT_FIFO;
            else if (tx_ack==1'b1)
               nstate_tx = MWR_ACK_UPD_DT;
            else
               nstate_tx = MWR_REQ_UPD_DT;
         end

      MWR_ACK_UPD_DT:
      // Received tx_ack, clear tx_req
         nstate_tx = DT_FIFO;

      default:
         nstate_tx = DT_FIFO;

   endcase

   // Requester Read TX machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         cstate_tx <= DT_FIFO;
      else
         cstate_tx <= nstate_tx;
   end

   ////////////////////////////////////////////////////////////////
   //
   // RX TLP Receive section
   //

   assign rx_fmt        = rx_desc[126:125];
   assign rx_type       = rx_desc[124:120];
   assign rx_dmard_tag  = (rx_desc[47:40]>=FIRST_DMARD_TAG) ?1'b1:1'b0;

   always @ (posedge clk_in) begin
      if (rx_req_p0==1'b0)
         rx_dmard_cpld<=1'b0;
      else if ((rx_dfr==1'b1)&&(rx_fmt ==`TLP_FMT_CPLD)&&
                (rx_type ==`TLP_TYPE_CPLD))
         rx_dmard_cpld <=1'b1;
   end

   // Set/Clear rx_ack
   assign rx_ack = (nstate_rx==CPLD_ACK)?1'b1:1'b0;

   // Avalon streaming back pressure control
   // 4 cycles response : 1 cc registered rx_ws +
   //                     3 cc tx_stream_ready -> tx_stream_valid
   assign rx_ws  =  ((rx_data_fifo_almost_full==1'b1) && (rx_dv==1'b1))?1'b1:1'b0;

   always @ (posedge clk_in or negedge rstn ) begin
       if (rstn==1'b0) begin
          rx_ast_data_valid <= 1'b0;
          rx_ws_ast         <= 3'h0;
       end
       else begin
          rx_ws_ast[0]      <= rx_ws;
          rx_ws_ast[1]      <= rx_ws_ast[0];
          rx_ws_ast[2]      <= rx_ws_ast[1];
          rx_ast_data_valid <= ~rx_ws_ast[0];
       end
   end



   always @ (posedge clk_in) begin
      if (init==1'b1)
         rx_tag[MAX_TAG_WIDTH-1:0] <=
                             cst_std_logic_vector_type_zero[MAX_TAG_WIDTH-1:0];
      else if (valid_rx_dmard_cpld==1'b1)
         rx_tag <= rx_desc[MAX_TAG_WIDTH+39:40];
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         rx_tag_is_sec_desc<= 0;
      else if (valid_rx_dmard_cpld==1'b1)
         rx_tag_is_sec_desc <= rx_desc[MAX_TAG_WIDTH+39:40] > MAX_NUMTAG_VAL_FIRST_DESCRIPTOR;
   end

  always @ (posedge clk_in) begin
       if (rx_dv_start_pulse==1'b1)
          rx_length_hold <= rx_desc[105:96];
      else
          rx_length_hold <= rx_length_hold;
  end
   //////////////////////////////////////////////////////////
   //
   // DATA FIFO RX_DATA side management  (DATA_FIFO Write)
   //
   assign rx_data_fifo_data[AVALON_WDATA-1:0]       = rx_data[AVALON_WDATA-1:0];
   assign rx_data_fifo_data[AVALON_WDATA+15: AVALON_WDATA] = rx_be;
   assign rx_data_fifo_data[RX_DATA_FIFO_WIDTH-3:AVALON_WDATA + 16]=
                           (rx_dv_start_pulse==1'b0)?rx_tag:
                                                  rx_desc[MAX_TAG_WIDTH+39:40];
   assign rx_data_fifo_data[RX_DATA_FIFO_WIDTH-2]   = rx_dv_start_pulse;
   assign rx_data_fifo_data[RX_DATA_FIFO_WIDTH-1]   = rx_dv_end_pulse;
   assign rx_data_fifo_data[RX_DATA_FIFO_WIDTH]=  (rx_dv_start_pulse==1'b0)? rx_tag_is_sec_desc: rx_desc[MAX_TAG_WIDTH+39:40] > MAX_NUMTAG_VAL_FIRST_DESCRIPTOR;
   assign rx_data_fifo_data[RX_DATA_FIFO_WIDTH + 10 : RX_DATA_FIFO_WIDTH + 1] =  (rx_dv_start_pulse==1'b0)? rx_length_hold: rx_desc[105:96];

   always @ (posedge clk_in) begin
      if ((rx_dfr==1'b0) || (init==1'b1))
         valid_rx_dmard_cpld_next <=1'b0;
      else begin
        if ((rx_req_p1==1'b1) &&
            (rx_dmard_tag==1'b1) &&
            (rx_dmard_cpld==1'b1))
            valid_rx_dmard_cpld_next <=1'b1;
         else if (rx_req==1'b0)
            valid_rx_dmard_cpld_next <=1'b0;
      end
   end

   assign valid_rx_dmard_cpld =((rx_req==1'b1) &&
        (((rx_req_p1==1'b1)&&(rx_dmard_tag==1'b1)&&(rx_dmard_cpld==1'b1)) ||
                            (valid_rx_dmard_cpld_next==1'b1)))?1'b1:1'b0;

   always @ (posedge clk_in) begin
      rx_dv_end_pulse_reg <= rx_dv_end_pulse;
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         valid_rx_dv_for_dmard <=1'b0;
      else if (rx_dv_end_pulse_reg==1'b1)
         valid_rx_dv_for_dmard <=1'b0;
      else if (valid_rx_dmard_cpld_next==1'b1)
         valid_rx_dv_for_dmard <=1'b1;
   end

   assign rx_data_fifo_sclr  = (init==1'b1)?1'b1:1'b0;
   assign rx_data_fifo_wrreq = (((valid_rx_dmard_cpld==1'b1)||
                                (valid_rx_dmard_cpld_next==1'b1) ||  //TODO optimize valid_rx_dv_for_dmard
                                (valid_rx_dv_for_dmard==1'b1)      )&&
                                (rx_ast_data_valid==1'b1)&& (rx_dv==1'b1))?1'b1:1'b0;

   //////////////////////////////////////////////////////////
   //
   // DATA FIFO Avalon side management   (DATA_FIFO Read)
   //

   always @ (posedge clk_in) begin
      if (cstate_rx_data_fifo==SM_RX_DATA_FIFO_READ_TAGRAM_2)
         tagram_data_rd_cycle <=1'b1;
      else
         tagram_data_rd_cycle <=1'b0;
   end

   always @ (posedge clk_in) begin
      if ((rx_data_fifo_empty==1'b1)||(init==1'b1))
         rx_data_fifo_almost_full<=1'b0;
      else begin
         if (rx_data_fifo_usedw>RX_DATA_FIFO_ALMST_FULL_LIM)
            rx_data_fifo_almost_full<=1'b1;
         else
            rx_data_fifo_almost_full<=1'b0;
     end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         rx_data_fifo_rx_tag[MAX_TAG_WIDTH-1:0]   <=
                              cst_std_logic_vector_type_zero[MAX_TAG_WIDTH-1:0];
      else if (cstate_rx_data_fifo==SM_RX_DATA_FIFO_READ_TAGRAM_1)
         rx_data_fifo_rx_tag   <= rx_data_fifo_q[RX_DATA_FIFO_WIDTH-3:144];
   end

   //////////////////////////////////////////////////////////
   //
   //  TAGRAM Update (port b) from the CPLD section
   //

   assign tagram_address_b =(cstate_rx_data_fifo==SM_RX_DATA_FIFO_READ_TAGRAM_1)?
                                rx_data_fifo_q[RX_DATA_FIFO_WIDTH-3:144]:
                                 rx_data_fifo_rx_tag;

   always @ (posedge clk_in) begin
     if (init==1'b1)
       tagram_wren_b <= 1'b0;
     else
       tagram_wren_b <= tagram_data_rd_cycle;  // Update tag info as early as possible

   end

   always @ (posedge clk_in) begin
      if (((cstate_rx_data_fifo==SM_RX_DATA_FIFO_RREQ) &&
            (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-1]==1'b1))||
             (cstate_rx_data_fifo==SM_RX_DATA_FIFO_SINGLE_QWORD) )
         tagram_wren_b_reg_init<=1'b1;
      else
         tagram_wren_b_reg_init<=1'b0;
   end

   // base the new tagram entries on descriptor info

   always @ (posedge clk_in) begin
       if (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-2]==1'b1)
          rx_data_fifo_length_hold <= rx_data_fifo_q[RX_DATA_FIFO_WIDTH + 10 : RX_DATA_FIFO_WIDTH + 1];
   end

   assign rx_tag_length_dw_next   = (tagram_q_b[TAG_EP_ADDR_WIDTH+9:TAG_EP_ADDR_WIDTH] < 5) ? 0 : tagram_q_b[TAG_EP_ADDR_WIDTH+9:TAG_EP_ADDR_WIDTH] - rx_data_fifo_length_hold;
   assign rx_tag_addr_offset_next = tagram_q_b[TAG_EP_ADDR_WIDTH-1:0] + {rx_data_fifo_length_hold, 2'h0};  // length is in DWords, tagram address uses byte addressing



   always @ (posedge clk_in) begin
       rcving_last_cpl_for_tag <= rcving_last_cpl_for_tag_n;
      if (init==1'b1) begin
        rx_tag_length_dw      <=0;
        rx_tag_addr_offset    <=0;
      tag_remaining_length  <= 10'h0;
      tagram_data_b         <= {TAG_EP_ADDR_WIDTH+10{1'b0}};
      end
      else if (tagram_data_rd_cycle==1'b1) begin
        rx_tag_length_dw[9:0]<=tagram_q_b[TAG_RAM_WIDTH-1:TAG_RAM_WIDTH-10];
        rx_tag_addr_offset   <=tagram_q_b[TAG_EP_ADDR_WIDTH-1:0];
        tagram_data_b        <= {rx_tag_length_dw_next[9:0], rx_tag_addr_offset_next[TAG_EP_ADDR_WIDTH-1:0]};
      tag_remaining_length <= tagram_q_b[TAG_EP_ADDR_WIDTH+9:TAG_EP_ADDR_WIDTH];
      end
      else begin
       tag_remaining_length <= tag_remaining_length;
      tagram_data_b <= tagram_data_b;
        rx_tag_addr_offset <= rx_tag_addr_offset+ 16;  // rx_tag_addr_offset is in bytes, but mem access is in 128-bits so increment every access by 16 bytes.
        if (rx_tag_length_dw>0) begin
           if ((rx_tag_length_dw<DATA_WIDTH_DWORD) && (rx_tag_length_dw>0))
              rx_tag_length_dw <= 0;
           else
              rx_tag_length_dw <= rx_tag_length_dw-DATA_WIDTH_DWORD;
        end
      end
   end
   //////////////////////////////////////////////////////////
   //
   //  Avalon memory write
   //

   assign rx_data_fifo_rdreq= (cstate_rx_data_fifo==SM_RX_DATA_FIFO_IDLE)||
                               ((rx_data_fifo_empty==1'b0) &&
                                (cstate_rx_data_fifo==SM_RX_DATA_FIFO_RREQ) || (cstate_rx_data_fifo==SM_RX_DATA_FIFO_SINGLE_QWORD))?
                                        1'b1:1'b0;


   always @ (posedge clk_in) begin
      writedata     <= rx_data_fifo_q[127:0];
      write_byteena <= rx_data_fifo_q[143:128];
   end

   always @ (posedge clk_in) begin
     if ((cstate_rx_data_fifo==SM_RX_DATA_FIFO_RREQ) ||
           (cstate_rx_data_fifo==SM_RX_DATA_FIFO_SINGLE_QWORD))
         write <= 1'b1;
      else
         write <= 1'b0;
   end
   always @ (posedge clk_in) begin
      if (init==1'b1)
         address <=0;
      else begin
         if (tagram_data_rd_cycle==1'b1)
            address <= tagram_q_b[TAG_EP_ADDR_WIDTH-1:4];  // tagram stores byte address.  Convert to QW address.
         else if (write==1'b1)
            address <= address+1;
      end
   end

   // Requester Read state machine (Receive)
   //    Combinatorial state transition (case state)
   always @*
   case (cstate_rx)
      CPLD_IDLE    :
      // Reflects the beginning of a new descriptor
         begin
            if (init == 1'b0)
               nstate_rx = CPLD_REQ;
            else
               nstate_rx = CPLD_IDLE;
         end

      CPLD_REQ   : // rx_ack upon rx_req and CPLD, and DMA Read tag
         begin
            if (init==1'b1)
               nstate_rx = CPLD_IDLE;
            else if (valid_rx_dmard_cpld==1'b1)
               nstate_rx = CPLD_ACK;
            else
               nstate_rx = CPLD_REQ;
         end

      CPLD_ACK: // set rx_ack
         nstate_rx = CPLD_DV;

      CPLD_DV: // collect data for a given tag
         begin
            if (rx_dfr==1'b0)
               nstate_rx = CPLD_LAST;
            else
               nstate_rx = CPLD_DV;
         end

      CPLD_LAST:
      // Last data (rx_dfr ==0) :
         begin
            if (rx_dv==1'b0)
               nstate_rx = CPLD_REQ;
            else
               nstate_rx = CPLD_LAST;
         end

      default:
         nstate_rx = CPLD_IDLE;

   endcase

   // Requester Read RX machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         cstate_rx    <= DT_FIFO;
      else
         cstate_rx <= nstate_rx;
   end


   always @*  begin
   transferring_data_n = transferring_data;
   case (cstate_rx_data_fifo)
      SM_RX_DATA_FIFO_IDLE:
         begin
            if (rx_data_fifo_empty==1'b0)
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_READ_TAGRAM_1;
            else
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_IDLE;
         end

      SM_RX_DATA_FIFO_READ_TAGRAM_1:
         begin
            if (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-2]==1'b0)
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_IDLE;
            else
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_READ_TAGRAM_2;
         end

      SM_RX_DATA_FIFO_READ_TAGRAM_2:
         begin
          transferring_data_n = 1'b1;
            if (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-1]==1'b0)
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_RREQ;
            else
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_SINGLE_QWORD;
         end

      SM_RX_DATA_FIFO_RREQ:
         begin
            if (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-1]==1'b1) begin
            nstate_rx_data_fifo = (rx_data_fifo_empty==1'b0) ? SM_RX_DATA_FIFO_READ_TAGRAM_1 : SM_RX_DATA_FIFO_IDLE;
            transferring_data_n = 1'b0;
         end
            else
               nstate_rx_data_fifo = SM_RX_DATA_FIFO_RREQ;
         end

      SM_RX_DATA_FIFO_SINGLE_QWORD:
        begin
            nstate_rx_data_fifo = (rx_data_fifo_empty==1'b0) ? SM_RX_DATA_FIFO_READ_TAGRAM_1 : SM_RX_DATA_FIFO_IDLE;
              transferring_data_n = 1'b0;
       end
      SM_RX_DATA_FIFO_TAGRAM_UPD:
          nstate_rx_data_fifo = SM_RX_DATA_FIFO_IDLE;

       default:
            nstate_rx_data_fifo  = SM_RX_DATA_FIFO_IDLE;

   endcase
   end

   // RX data fifo state machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in)
   begin
      if (rstn==1'b0) begin
         cstate_rx_data_fifo  <= SM_RX_DATA_FIFO_IDLE;
       transferring_data   <= 1'b0;
      end
      else begin
         cstate_rx_data_fifo <= nstate_rx_data_fifo;
       transferring_data   <= transferring_data_n;
     end
   end
   ///////////////////////////////////////////////////////////////////////////
   //
   // MSI section :  if (USE_MSI>0)
   //
   assign app_msi_req = (USE_MSI==0)?1'b0:(cstate_msi==MWR_REQ_MSI)?1'b1:1'b0;
   assign msi_ready   = (USE_MSI==0)?1'b0:(cstate_msi==START_MSI)?1'b1:1'b0;
   assign msi_busy    = (USE_MSI==0)?1'b0:(cstate_msi==MWR_REQ_MSI)?1'b1:1'b0;
   always @*
   case (cstate_msi)
      IDLE_MSI:
         begin
            if ((cstate_tx==DONE)&&  //(cdt_msi==1'b1))
                (((cdt_msi_first_descriptor == 1'b1) & (tx_cpld_first_descriptor==1'b1)) ||
                 ((cdt_msi_second_descriptor == 1'b1) & (tx_cpld_second_descriptor==1'b1)) ) )
               nstate_msi = START_MSI;
            else
               nstate_msi = IDLE_MSI;
         end

      START_MSI:
      // Waiting for Top level arbitration (tx_sel) prior to tx MEM64_WR
         begin
            if ((msi_sel==1'b1) && (tx_ws==1'b0))
               nstate_msi = MWR_REQ_MSI;
            else
               nstate_msi = START_MSI;
         end

      MWR_REQ_MSI:
      // Set tx_req, Waiting for tx_ack
         begin
            if (app_msi_ack==1'b1)
               nstate_msi = IDLE_MSI;
            else
               nstate_msi = MWR_REQ_MSI;
         end

       default:
            nstate_msi  = IDLE_MSI;
   endcase

   // MSI state machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in)
   begin
      if (rstn==1'b0)
         cstate_msi  <= IDLE_MSI;
      else
         cstate_msi <= nstate_msi;
   end


   /////////////////////////////////////////////////////////////////////
   //
   // TAG Section

   // Write in TAG RAM the offset of EP memory
   // The TAG RAM content {tx_length_dw[9:1], tx_tag_addr_offset[AVALON_WADDR-1:0]}
   // tx_length_dw[9:1]       : QWORD LENGTH to know when recycle TAG
   // tx_tag_addr_offset[AVALON_WADDR-1:0] : EP Address offset (where PCIE write to)
   assign tagram_wren_a    = ((cstate_tx==MRD_REQ)&&(tx_req==1'b1)&&
                                                   (tx_req_delay==1'b0))?  1'b1:1'b0;
   assign tagram_data_a    = {tx_length_dw[9:0],tx_tag_addr_offset[TAG_EP_ADDR_WIDTH-1:0]};  // tx_tag_addr_offset is in Bytes
   assign tagram_address_a[MAX_TAG_WIDTH-1:0] = tx_tag_tx_desc[MAX_TAG_WIDTH-1:0];

   // TX TAG Signaling FIFO TAG
   // There are 2 FIFO TAGs :
   //    tag_scfifo_first_descriptor
   //    tag_scfifo_second_descriptor
   // The FIFO TAG are used to recycle TAGS
   // The read requester module issues MRD for
   // two consecutive descriptors (first_descriptor, second descriptor)
   // The TAG assignment is such
   //        MAX_NUMTAG : Maximum number of TAG available from the core
   //        TAG_TRACK_WIDTH : Number of tag for both descriptor
   //        TAG_TRACK_HALF_WIDTH : Number of tag for each descriptor
   // The one hot register tag_track_one_hot tracks the TAG which has been
   // recycled accross both descriptors
   assign tag_fifo_sclr  = init;
   assign rcving_last_cpl_for_tag_n =  (tagram_data_rd_cycle==1'b1)  ? ~(tagram_q_b[TAG_EP_ADDR_WIDTH+9:TAG_EP_ADDR_WIDTH] > rx_data_fifo_length_hold) : rcving_last_cpl_for_tag;

   assign got_all_cpl_for_tag = (transferring_data == 1'b1 ) &
                                   (rcving_last_cpl_for_tag_n == 1'b1) && (rx_data_fifo_q[RX_DATA_FIFO_WIDTH-1]==1'b1);   // release tag when dv_end is received, and this is the end of the last cpl expected for the tag


   always @ (posedge clk_in) begin
      if (init==1'b1)
         tag_track_one_hot[TAG_TRACK_WIDTH-1:0]
                   <= cst_std_logic_vector_type_zero[TAG_TRACK_WIDTH-1:0];
      else if (cstate_tx==MRD_ACK) begin
          for(i=2+RC_SLAVE_USETAG;i <MAX_NUMTAG;i=i+1)
             if (tx_tag_tx_desc == i)
                tag_track_one_hot[i-2] <= 1'b1;
      end
     else if (got_all_cpl_for_tag == 1'b1) begin
         for(i=2+RC_SLAVE_USETAG;i <MAX_NUMTAG;i=i+1)
            if (tagram_address_b == i)
               tag_track_one_hot[i-2] <= 1'b0;
      end
      else if (tagram_wren_b_mrd_ack==1'b1) begin
         for(i=2+RC_SLAVE_USETAG;i <MAX_NUMTAG;i=i+1)
            if (tagram_address_b_mrd_ack == i)
               tag_track_one_hot[i-2] <= 1'b0;
      end
   end

   //cpl_pending logic
   always @ (posedge clk_in) begin
      if (init==1'b1)
         cpl_pending<=1'b0;
      else begin
         if (tag_track_one_hot[TAG_TRACK_WIDTH-1:0]>cst_std_logic_vector_type_zero[TAG_TRACK_WIDTH-1:0])
             cpl_pending<=1'b1;
         else
             cpl_pending<=1'b0;
     end
   end

   always @ (posedge clk_in) begin
     if ((cstate_tx==MRD_ACK)&& (got_all_cpl_for_tag == 1'b1))
       tagram_wren_b_mrd_ack <= 1'b1;
      else
         tagram_wren_b_mrd_ack <= 1'b0;
   end

   always @ (posedge clk_in) begin
     // Hold tagram address in case conflict between setting tag and releasing tag
    if ((cstate_tx==MRD_ACK)&&(got_all_cpl_for_tag == 1'b1))
         tagram_address_b_mrd_ack <= tagram_address_b;
      else
         tagram_address_b_mrd_ack[MAX_TAG_WIDTH-1:0] <=
                             cst_std_logic_vector_type_zero[MAX_TAG_WIDTH-1:0];
   end

   assign tx_cpld_first_descriptor = (MAX_NUMTAG==4)?~tag_track_one_hot[0]:
                        (tag_track_one_hot[TAG_TRACK_HALF_WIDTH-1:0]==0)?1'b1:1'b0;

   assign tx_cpld_second_descriptor = (MAX_NUMTAG==4)?~tag_track_one_hot[1]:
          (tag_track_one_hot[TAG_TRACK_WIDTH-1:TAG_TRACK_HALF_WIDTH]==0)?1'b1:1'b0;

   assign tx_fifo_rdreq_first_descriptor  = ((tx_first_descriptor_cycle==1'b1) &&
                                             (cstate_tx==GET_TAG))?1'b1:1'b0;
   assign tx_fifo_rdreq_second_descriptor = ((tx_first_descriptor_cycle==1'b0)&&
                                              (cstate_tx==GET_TAG))?1'b1:1'b0;

   // TX TAG counter first descriptor
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_cnt_first_descriptor <=
                                    FIRST_DMARD_TAG_cst_width_eq_MAX_TAG_WIDTH;
      else if ((cstate_tx==MRD_REQ)&&(tx_ack==1'b1)&&
               (tx_first_descriptor_cycle==1'b1) ) begin
         if (tx_tag_cnt_first_descriptor!=MAX_NUMTAG_VAL_FIRST_DESCRIPTOR)
            tx_tag_cnt_first_descriptor  <= tx_tag_cnt_first_descriptor+1;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_mux_first_descriptor  <= 1'b0;
      else if ((tx_tag_cnt_first_descriptor==MAX_NUMTAG_VAL_FIRST_DESCRIPTOR)&&
            (cstate_tx==MRD_REQ) && (tx_ack==1'b1))
         tx_tag_mux_first_descriptor <= 1'b1;
   end

   assign tx_tag_wire_mux_first_descriptor[MAX_TAG_WIDTH-1:0] =
                          (tx_tag_mux_first_descriptor == 1'b0)?
                          tx_tag_cnt_first_descriptor[MAX_TAG_WIDTH-1:0]:
                          tx_tag_fifo_first_descriptor[MAX_TAG_WIDTH-1:0];

   // TX TAG counter second descriptor
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_cnt_second_descriptor <=
              FIRST_DMARD_TAG_SEC_DESCRIPTOR_cst_width_eq_MAX_TAG_WIDTH ;
      else if ((tx_ack==1'b1) && (cstate_tx==MRD_REQ) &&
             (tx_first_descriptor_cycle==1'b0)) begin
         if (tx_tag_cnt_second_descriptor!=MAX_NUMTAG_VAL)
            tx_tag_cnt_second_descriptor  <= tx_tag_cnt_second_descriptor+1;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_mux_second_descriptor  <= 1'b0;
      else if ((tx_tag_cnt_second_descriptor==MAX_NUMTAG_VAL) &&
                (tx_ack==1'b1) && (cstate_tx==MRD_REQ) &&
                (tx_first_descriptor_cycle==1'b0) )
         tx_tag_mux_second_descriptor <= 1'b1;
   end

   assign tx_tag_wire_mux_second_descriptor[MAX_TAG_WIDTH-1:0] =
                         (tx_tag_mux_second_descriptor == 1'b0)?
                          tx_tag_cnt_second_descriptor[MAX_TAG_WIDTH-1:0]:
                          tx_tag_fifo_second_descriptor[MAX_TAG_WIDTH-1:0];
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_tag_tx_desc <=0;
      else if ((cstate_tx==TX_LENGTH) && (tx_first_descriptor_cycle==1'b1))
         tx_tag_tx_desc[MAX_TAG_WIDTH-1:0] <=
                   tx_tag_wire_mux_first_descriptor[MAX_TAG_WIDTH-1:0];
      else if ((cstate_tx==TX_LENGTH) && (tx_first_descriptor_cycle==1'b0))
         tx_tag_tx_desc[MAX_TAG_WIDTH-1:0] <=
                   tx_tag_wire_mux_second_descriptor[MAX_TAG_WIDTH-1:0];
   end

   assign rx_second_descriptor_tag  = rx_data_fifo_q[RX_DATA_FIFO_WIDTH];

   assign rx_fifo_wrreq_first_descriptor =
             ( (got_all_cpl_for_tag == 1'b1) &&
                                   (rx_second_descriptor_tag==1'b0))?1'b1:1'b0;
   assign rx_fifo_wrreq_second_descriptor =
             ( (got_all_cpl_for_tag == 1'b1)  &&
                                   (rx_second_descriptor_tag==1'b1))?1'b1:1'b0;
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_first_descriptor_cycle <=1'b1;
      else if ((cstate_tx==MRD_ACK) && (cdt_length_dw_tx==0))
         tx_first_descriptor_cycle <= ~tx_first_descriptor_cycle;
   end


   always @ (posedge clk_in) begin
      if (init==1'b1)
         next_is_second <=1'b0;
      else if (cstate_tx==MWR_ACK_UPD_DT) begin
         if ((eplast_upd_first_descriptor==1'b1) &&
              (eplast_upd_second_descriptor==1'b1) &&
               (next_is_second==1'b0))
            next_is_second <=1'b1;
         else
            next_is_second <=1'b0;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         eplast_upd_first_descriptor <=1'b0;
      else if ((cstate_tx==MRD_ACK) && (cdt_length_dw_tx==0)
               && (tx_first_descriptor_cycle==1'b1))
         eplast_upd_first_descriptor <= 1'b1;
      else if ((cstate_tx==MWR_ACK_UPD_DT) &&
            (tx_cpld_first_descriptor==1'b1)) begin
         if (eplast_upd_second_descriptor==1'b0)
            eplast_upd_first_descriptor <= 1'b0;
         else if (next_is_second==1'b0)
            eplast_upd_first_descriptor <= 1'b0;
      end
   end


   // Pipe the TAG Fifo Write inputs for performance
   always @ (posedge clk_in) begin
       tagram_address_b_reg <= tagram_address_b;

       if (tag_fifo_sclr==1'b1) begin
          rx_fifo_wrreq_first_descriptor_reg  <= 1'b0;
         rx_fifo_wrreq_second_descriptor_reg <= 1'b0;
      end
      else begin
          rx_fifo_wrreq_first_descriptor_reg  <= rx_fifo_wrreq_first_descriptor;
         rx_fifo_wrreq_second_descriptor_reg <= rx_fifo_wrreq_second_descriptor;
      end

   end


   always @ (posedge clk_in) begin
      if (init==1'b1)
         eplast_upd_second_descriptor <=1'b0;
      else if ((cstate_tx==MRD_ACK)&&(cdt_length_dw_tx==0)
               && (tx_first_descriptor_cycle==1'b0))
         eplast_upd_second_descriptor <= 1'b1;
      else if ((cstate_tx==MWR_ACK_UPD_DT) &&
                (tx_cpld_second_descriptor==1'b1)) begin
         if (eplast_upd_first_descriptor==1'b0)
            eplast_upd_second_descriptor <= 1'b0;
         else if (next_is_second==1'b1)
            eplast_upd_second_descriptor <= 1'b0;
      end
   end

   // TAG FIFO
   //
   scfifo # (
             .add_ram_output_register ("ON")           ,
             .intended_device_family  (INTENDED_DEVICE_FAMILY),
             .lpm_numwords            (TAG_FIFO_DEPTH) ,
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (MAX_TAG_WIDTH) ,
             .lpm_widthu              (MAX_TAG_WIDTHU),
             .overflow_checking       ("ON")           ,
             .underflow_checking      ("ON")           ,
             .use_eab                 ("ON")
             )
             tag_scfifo_first_descriptor (
            .clock (clk_in),
            .sclr  (tag_fifo_sclr ),

            // RX push TAGs into TAG_FIFO
            .data  (tagram_address_b_reg),
            .wrreq (rx_fifo_wrreq_first_descriptor_reg),

            // TX pop TAGs from TAG_FIFO
            .rdreq (tx_fifo_rdreq_first_descriptor),
            .q     (tx_tag_fifo_first_descriptor  ),

            .empty (tag_fifo_empty_first_descriptor),
            .full  (tag_fifo_full_first_descriptor )
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full (),
            .usedw ()
            // synopsys translate_on
            );

   scfifo # (
             .add_ram_output_register ("ON")          ,
             .intended_device_family  (INTENDED_DEVICE_FAMILY),
             .lpm_numwords            (TAG_FIFO_DEPTH),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (MAX_TAG_WIDTH) ,
             .lpm_widthu              (MAX_TAG_WIDTHU),
             .overflow_checking       ("ON")           ,
             .underflow_checking      ("ON")           ,
             .use_eab                 ("ON")
             )
             tag_scfifo_second_descriptor (
            .clock (clk_in),
            .sclr  (tag_fifo_sclr ),

            // RX push TAGs into TAG_FIFO
            .data  (tagram_address_b_reg),
            .wrreq (rx_fifo_wrreq_second_descriptor_reg),

            // TX pop TAGs from TAG_FIFO
            .rdreq (tx_fifo_rdreq_second_descriptor),
            .q     (tx_tag_fifo_second_descriptor),

            .empty (tag_fifo_empty_second_descriptor),
            .full  (tag_fifo_full_second_descriptor )
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full (),
            .usedw ()
            // synopsys translate_on
            );




      altsyncram # (
         .address_reg_b                      ("CLOCK0"          ),
         .indata_reg_b                       ("CLOCK0"          ),
         .wrcontrol_wraddress_reg_b          ("CLOCK0"          ),
         .intended_device_family             (INTENDED_DEVICE_FAMILY),
         .lpm_type                           ("altsyncram"      ),
         .numwords_a                         (TAG_RAM_NUMWORDS  ),
         .numwords_b                         (TAG_RAM_NUMWORDS  ),
         .operation_mode                     ("BIDIR_DUAL_PORT" ),
         .outdata_aclr_a                     ("NONE"            ),
         .outdata_aclr_b                     ("NONE"            ),
         .outdata_reg_a                      ("CLOCK0"    ),
         .outdata_reg_b                      ("CLOCK0"    ),
         .power_up_uninitialized             ("FALSE"           ),
         .read_during_write_mode_mixed_ports ("DONT_CARE"        ),
         .widthad_a                          (TAG_RAM_WIDTHAD   ),
         .widthad_b                          (TAG_RAM_WIDTHAD   ),
         .width_a                            (TAG_RAM_WIDTH     ),
         .width_b                            (TAG_RAM_WIDTH     ),
         .width_byteena_a                    (1                 ),
         .width_byteena_b                    (1                 )
      ) tag_dpram (
         .clock0          (clk_in),

         // Port B is used by TX module to update the TAG
         .data_a          (tagram_data_a),
         .wren_a          (tagram_wren_a),
         .address_a       (tagram_address_a),

         // Port B is used by RX module to update the TAG
         .data_b          (tagram_data_b),
         .wren_b          (tagram_wren_b),
         .address_b       (tagram_address_b),
         .q_b             (tagram_q_b),

         .rden_b          (cst_one),
         .aclr0           (cst_zero),
         .aclr1           (cst_zero),
         .addressstall_a  (cst_zero),
         .addressstall_b  (cst_zero),
         .byteena_a       (cst_std_logic_vector_type_one[0]),
         .byteena_b       (cst_std_logic_vector_type_one[0]),
         .clock1          (cst_one),
         .clocken0        (cst_one),
         .clocken1        (cst_one),
         .q_a             ()
         );

   scfifo # (
             .add_ram_output_register ("ON")          ,
             .intended_device_family  (INTENDED_DEVICE_FAMILY),
             .lpm_numwords            (RX_DATA_FIFO_NUMWORDS),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (RX_DATA_FIFO_WIDTH+11) ,
             .lpm_widthu              (RX_DATA_FIFO_WIDTHU),
             .overflow_checking       ("ON")           ,
             .underflow_checking      ("ON")           ,
             .use_eab                 ("ON")
             )
             rx_data_fifo (
            .clock (clk_in),
            .sclr  (rx_data_fifo_sclr ),

            // RX push TAGs into TAG_FIFO
            .data  (rx_data_fifo_data),
            .wrreq (rx_data_fifo_wrreq),

            // TX pop TAGs from TAG_FIFO
            .rdreq (rx_data_fifo_rdreq),
            .q     (rx_data_fifo_q    ),

            .empty (rx_data_fifo_empty),
            .full  (rx_data_fifo_full ),
            .usedw (rx_data_fifo_usedw)
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full ()
            // synopsys translate_on
            );

endmodule
