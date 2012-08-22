// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It manages DMA write data transfer
//  * from the End Point memory to the Root Complex memory.
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
// Title         : DMA Write requestor module (altpcierd_write_dma_requester)
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_write_dma_requester_128.v
// Author        : Altera Corporation
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


module altpcierd_write_dma_requester_128  # (
   parameter MAX_PAYLOAD      = 256,
   parameter MAX_NUMTAG       = 32,
   parameter FIFO_WIDTH       = 128,
   parameter AVALON_WADDR     = 12,
   parameter AVALON_WDATA     = 128,
   parameter BOARD_DEMO       = 0,
   parameter USE_MSI          = 1,
   parameter TXCRED_WIDTH     = 22,
   parameter DMA_QWORD_ALIGN  = 0,
   parameter RC_64BITS_ADDR   = 0,
   parameter INTENDED_DEVICE_FAMILY = "Cyclone IV GX",
   parameter TL_SELECTION     = 0,
   parameter USE_CREDIT_CTRL  = 1,
   parameter DT_EP_ADDR_SPEC   = 2           // Descriptor Table's EP Address is specified as:  3=QW Address,  2=DW Address, 1= W Address, 0= Byte Addr.

   )
   (
   // Descriptor control signals
   output                  dt_fifo_rdreq,
   input                   dt_fifo_empty,
   input  [FIFO_WIDTH-1:0] dt_fifo_q    ,

   input  [15:0] cfg_maxpload_dw ,
   input  [2:0]  cfg_maxpload ,
   input  [4:0]  cfg_link_negociated ,
   input  [63:0] dt_base_rc          ,
   input         dt_3dw_rcadd        ,
   input         dt_eplast_ena       ,
   input         dt_msi              ,
   input  [15:0] dt_size             ,
   input [12:0]  dt_fifo_q_4K_bound,

   //PCIe transmit
   input                     tx_ready_dmard,
   output                    tx_ready,
   output reg                tx_busy ,
   input                     tx_sel  ,
   input [TXCRED_WIDTH-1:0]  tx_cred,
   output                    tx_req  ,
   output   reg              tx_dv   ,
   output                    tx_dfr  ,
   input                     tx_ack  ,
   output     [127:0]        tx_desc ,
   output     [127:0]        tx_data ,
   input                     tx_ws   ,


   // MSI signal
   input   app_msi_ack,
   output  app_msi_req,
   input   msi_sel    ,
   output  msi_ready  ,
   output  msi_busy   ,

   //Avalon slave port
   output [AVALON_WADDR-1:0] address    ,
   output                    waitrequest,
   output                    read       ,
   input  [AVALON_WDATA-1:0] readdata   ,

   // Control signals for RC Slave module
   input        descriptor_mrd_cycle,
   output reg   requester_mrdmwr_cycle,
   output [3:0] dma_sm  ,

   output [63:0]  dma_status,

   input        init    ,
   input        clk_in  ,
   input        rstn
   );

   /////////////////////////////////////////////////////////
   // Local parameters
   //
   localparam CDMA_VERSION      = 4'b0011;
   localparam TL_MODE           = 2'b10;

   // Write requester states
   localparam DT_FIFO           = 0 , // Ready to retrieve new descriptor
                                      // from FIFO
              DT_FIFO_RD_QW0    = 1 , // Read the first QWORD descriptor
              DT_FIFO_RD_QW1    = 2 , // Re ad the second QWORD descriptor
              TX_LENGTH         = 3 , // Format tx_desc
              START_TX          = 4 , // Wait for top level arbitartion
              MWR_REQ           = 5 , // set tx_req, set tx_fr, tx_dv
              MWR_DV            = 6 , // clear tx_req upon tx_ack
              DONE              = 7 , // clear tx_dv
              TX_DONE_WS        = 8 ,
              START_TX_UPD_DT   = 9, //  update, send the number of
              MWR_REQ_UPD_DT    = 10, //  descriptor which has been
              MWR_DV_UPD_DT     = 11; //  completed

    // MSI State
    localparam IDLE_MSI    = 0,// MSI Stand by
               START_MSI   = 1,// Wait for msi_sel
               MWR_REQ_MSI = 2;// Set app_msi_req, wait for app_msi_ack

  localparam WR_FIFO_NUMWORDS    = 32;
  localparam WR_FIFO_ALMST_FULL  = WR_FIFO_NUMWORDS-8;


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
//   localparam WR_FIFO_WIDTHU = ceil_log2(WR_FIFO_NUMWORDS);
// VHDL translation_off

   localparam WR_FIFO_WIDTHU      = (WR_FIFO_NUMWORDS<17  )? 4 :
                                    (WR_FIFO_NUMWORDS<33  )? 5 :
                                    (WR_FIFO_NUMWORDS<65  )? 6 :
                                    (WR_FIFO_NUMWORDS<129 )? 7 :
                                    (WR_FIFO_NUMWORDS<257 )? 8 :
                                    (WR_FIFO_NUMWORDS<513 )? 9 :
                                    (WR_FIFO_NUMWORDS<1025)? 10:11;

   localparam ZERO_INTEGER    = 0;
   localparam ONE_INTEGER     = 1;
   localparam TWO_INTEGER     = 2;

   /////////////////////////////////////////////////////////
   // Local signals
   //

   // Control counter for payload and dma length
   reg  [9:0]   tx_length_dw    ;
   reg  [7:0]   tx_length_ow;
   wire  [7:0]   tx_length_ow_minus_one;
   reg  [7:0]   tx_length_ow_minus_one_reg;
   reg          tx_length_load_cycle_next;
   // pre-decode tx_length values

   wire [11:0]  tx_length_byte  ;
   wire [31:0]  tx_length_byte_32ext  ;
   wire [63:0]  tx_length_byte_64ext  ;

   wire [10:0] cfg_maxpayload_dw_ext_10;
   reg  [15:0] cfg_maxpload_dw_plus_two ;
   reg  [15:0] cdt_length_dw   ;   // cdt : current descriptor //
   wire [31:0] cdt_length_byte ;   // cdt : current descriptor //

   wire [12:0] cfg_maxpload_byte; // Max read request in bytes
   wire [12:0] tx_desc_addr_4k;
   reg [11:0] tx_desc_addr_4k_3dw;
   reg [11:0] tx_desc_addr_4k_4dw;
   wire [12:0] dt_fifo_q_addr_4k;
   reg  [12:0] calc_4kbnd_done_byte;
   wire [12:0] calc_4kbnd_dt_fifo_byte;
   wire [15:0] calc_4kbnd_done_dw;
   wire [15:0] calc_4kbnd_dt_fifo_dw;
   reg  [15:0] maxpload_dw;
   // pre-decode cdt_length_dw values

   // TX State machine registers
   reg [3:0]   cstate;
   reg [3:0]   nstate;
   reg [3:0]   cstate_last;

   // MSI State machine registers
   // MSI could be send in parallel to EPLast
   reg [2:0]   cstate_msi;
   reg [2:0]   nstate_msi;

   // DMA registers
   reg         cdt_msi       ;// When set, send MSI to RC host
   reg         cdt_eplast_ena;// When set, update RC Host memory with dt_ep_last
   reg [15:0]  dt_ep_last    ;// Number of descriptors completed

   wire                    read_int;
   reg  [AVALON_WADDR-1:0]   address_reg;
   reg                       epmem_read_cycle;

   wire wr_fifo_sclr ;
   wire [AVALON_WDATA-1:0] wr_fifo_data ;
   wire wr_fifo_wrreq;
   wire wr_fifo_ready_to_read;
   reg [5:0] wrreq_d;

   wire wr_fifo_rdreq;
   wire [AVALON_WDATA-1:0] wr_fifo_q    ;
   wire [WR_FIFO_WIDTHU-1:0] wr_fifo_usedw;
   reg  wr_fifo_almost_full;
   wire wr_fifo_empty;
   wire wr_fifo_full ;

   reg  tx_dfr_complete;
   reg  tx_dfr_complete_pipe;
   wire tx_dfr_p0;
   reg  tx_dfr_p1;
   wire tx_dfr_add;
   wire tx_dv_ws_wait;
   reg  tx_dv_gone;
   wire tx_ws_val;
   wire tx_dfr_non_qword_aligned_addr;

   reg  [7:0]   tx_dfr_ow_counter; // o --> octo-word = double dqword

   // PCIe Signals RC address
   reg [63:0]  tx_desc_addr ;
   reg         addrval_32b;
   wire [63:0]  tx_desc_addr_pipe ;
   reg [63:0]  tx_max_addr ;
   reg         tx_rc_addr_gt_tx_max_addr ;
   reg [63:0]  tx_addr_eplast;
   reg         addrval_32b_eplast;
   wire [63:0]  tx_addr_eplast_pipe;
   reg  [63:0] tx_data_eplast;
   wire [AVALON_WDATA-1:0] tx_data_avalon;
   wire [AVALON_WDATA-1:0] readdata_m;
   reg  [31:0] readdata_m_next;
   reg         tx_data_dw0_msb;
   wire [7:0]  tx_tag  ;
   wire [3:0]  tx_lbe_d;
   wire [3:0]  tx_fbe_d;

   // tx_credit control
   reg  tx_cred_posted_header_valid_x8;
   wire tx_cred_posted_header_valid;
   reg  tx_cred_posted_data_valid;
   wire [10:0] tx_cred_posted_data;
   wire tx_cred_posted_data_inf;

   assign dma_sm = cstate;
   // For VHDl translation

   // control bits : check 32 bit vs 64 bit address
   reg         txadd_3dw;

   // control bits : generate tx_dfr & tx_dv
   reg   tx_req_reg;
   wire  tx_req_pulse;
   reg   tx_req_delay ;
   wire  tx_req_p0;
   reg   tx_req_p1 ;

   // control bits : set when ep_lastup transmit
   reg ep_lastupd_cycle;
   reg [23:0]  performance_counter ;

   wire [63:0] dt_fifo_ep_addr_byte;
   reg         inhibit_fifo_rd;
   wire        inhibit_fifo_rd_n;
   reg         addr_ends_on128bit_bound;
   reg         last_addr_ended_on128bit_bound;
   wire[1:0]   addr_end;
   wire[31:0]  tx_start_addr;
   wire[31:0]  tx_start_addr_n;
   wire[63:0]  tx_desc_addr_n;
   reg[63:0]   tx_desc_addr_n_reg;
   wire        txadd_3dw_n;
   reg         txadd_3dw_n_reg;
   reg[31:0]   tx_desc_addr_plus_tx_length_byte_32ext;
   reg         dt_ep_last_eq_dt_size;

   assign  dma_status = tx_data_eplast;

   assign tx_start_addr = (txadd_3dw==1'b1) ? tx_desc_addr[63:32] : tx_desc_addr[31:0];
   assign tx_start_addr_n = (txadd_3dw_n==1'b1) ? tx_desc_addr_n[63:32] : tx_desc_addr_n[31:0];

   assign dt_fifo_ep_addr_byte = (DT_EP_ADDR_SPEC==0) ? dt_fifo_q[63:32]  : {dt_fifo_q[63-DT_EP_ADDR_SPEC:32], {DT_EP_ADDR_SPEC{1'b0}}};   // Convert the EP Address (from the Descriptor Table) to a Byte address


   // if (USE_CREDIT_CTRL==0)
   // 9:1   .. 0: No credits available
   //       .. 1-256: number of credits available
   //       .. 257-511: reserved
   // Posted data: 9 bits permit advertisement of 256 credits,
   // which corresponds to 4KBytes, the maximum payload size
   // which translates into 1 credit == 4 DWORDS
   // Credit and flow control signaling

   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_cred_posted_header_valid_x8<=1'b0;
      else begin
         if  ((tx_cred[7:0]>0)||(tx_cred[TXCRED_WIDTH-6]==1))
            tx_cred_posted_header_valid_x8 <= 1'b1;
         else
            tx_cred_posted_header_valid_x8 <= 1'b0;
      end
   end

   assign tx_cred_posted_header_valid = (USE_CREDIT_CTRL==0)?1'b1:(TXCRED_WIDTH==66)?
                                          tx_cred_posted_header_valid_x8:tx_cred[0];
   assign tx_cred_posted_data[10:2] = (TXCRED_WIDTH==66)?tx_cred[16:8]:tx_cred[9:1];
   assign tx_cred_posted_data[1:0]  = 2'b00;
   assign tx_cred_posted_data_inf   = (TXCRED_WIDTH==66)?tx_cred[TXCRED_WIDTH-5]:1'b0;
   assign cfg_maxpayload_dw_ext_10 = cfg_maxpload_dw[10:0];
   always @ (posedge clk_in) begin
      if (USE_CREDIT_CTRL==0)
         tx_cred_posted_data_valid <= 1'b1;
      else begin
         if ((init==1'b1)||(tx_cred_posted_header_valid==1'b0))
            tx_cred_posted_data_valid <=1'b0;
         else begin
            if (tx_cred_posted_data_inf==1'b1)
                  tx_cred_posted_data_valid <=1'b1;
            else begin
               if (cdt_length_dw>cfg_maxpload_dw) begin
                  if (tx_cred_posted_data>=cfg_maxpayload_dw_ext_10)
                    tx_cred_posted_data_valid <=1'b1;
                  else
                    tx_cred_posted_data_valid <=1'b0;
               end
               else begin
                     tx_cred_posted_data_valid <=1'b0;
               end
            end
         end
      end
   end

   assign wr_fifo_ready_to_read = (wr_fifo_empty==1'b0)?1'b1:
                                  (wr_fifo_wrreq==1'b1)?1'b1:1'b0;

   assign tx_ready      = ((cstate==START_TX)&&(wr_fifo_ready_to_read==1'b1) &&
                           (tx_ready_dmard==1'b0))?1'b1:1'b0;

   always @ (posedge clk_in) begin
      if ((nstate==MWR_REQ)||(nstate==MWR_DV)||(nstate==DONE)||
                      (nstate==TX_DONE_WS)||(nstate==MWR_REQ_UPD_DT)||
                      (nstate==START_TX_UPD_DT)||(nstate==MWR_DV_UPD_DT))
         tx_busy <= 1'b1;
      else if ((nstate==START_TX) && (cstate==DONE))
         tx_busy <= 1'b1;
      else
         tx_busy <= 1'b0;
   end

   assign dt_fifo_rdreq = ((dt_fifo_empty==1'b0)&&(cstate==DT_FIFO))?
                           1'b1:1'b0;

   // Updating RC memory register dt_ep_last
   always @ (posedge clk_in) begin
      if (init==1'b1)
         ep_lastupd_cycle <=1'b0;
      else begin
         if ((cstate==START_TX_UPD_DT)||(cstate==MWR_REQ_UPD_DT) || (cstate==MWR_DV_UPD_DT))
            ep_lastupd_cycle <=1'b1;
         else
            ep_lastupd_cycle <=1'b0;
       end
   end

   // Register containing EPLast descriptor processed
   always @ (posedge clk_in) begin
      cstate_last <= cstate;
      if (init==1'b1) begin
         dt_ep_last            <=0;
         dt_ep_last_eq_dt_size <= 1'b0;
      end
      else begin
         dt_ep_last_eq_dt_size <= (dt_ep_last==dt_size) ? 1'b1 : 1'b0;
        if ((cstate == DT_FIFO) & ((cstate_last == MWR_DV_UPD_DT) || (cstate_last==DONE)))  begin // increment when left MWR_DV_UPD_DT state
            if (dt_ep_last_eq_dt_size == 1'b1)
                dt_ep_last <=0;
            else
                dt_ep_last <=dt_ep_last+1;
         end
         else
            dt_ep_last <= dt_ep_last;
      end

   end

   // tx signals
   assign tx_tag   = `ZERO_BYTE;
   assign tx_lbe_d = ((ep_lastupd_cycle==1'b0)&&(tx_length_dw==1))?4'h0:4'hF;
   assign tx_fbe_d = 4'hF;


   assign tx_req   = (((cstate==MWR_REQ)||(cstate==MWR_REQ_UPD_DT))&&
                      (tx_ack==1'b0))?1'b1:1'b0;

   // tx_desc construction
   assign tx_desc[127]     = `RESERVED_1BIT     ;
   assign tx_desc[126:125] = (RC_64BITS_ADDR==0)                                   ?`TLP_FMT_3DW_W:
                             ((ep_lastupd_cycle==1'b0)&&(txadd_3dw==1'b1))||
                              ((ep_lastupd_cycle==1'b1)&&(dt_3dw_rcadd==1'b1))     ?`TLP_FMT_3DW_W:
                             ((ep_lastupd_cycle==1'b1)&&(addrval_32b_eplast==1'b0))?`TLP_FMT_4DW_W:
                             ((ep_lastupd_cycle==1'b1)&&(addrval_32b_eplast==1'b1))?`TLP_FMT_3DW_W:
                             ((ep_lastupd_cycle==1'b0)&&(addrval_32b       ==1'b1))?`TLP_FMT_3DW_W:
                                                                                    `TLP_FMT_4DW_W;
   assign tx_desc[124:120] = `TLP_TYPE_WRITE    ;
   assign tx_desc[119]     = `RESERVED_1BIT     ;
   assign tx_desc[118:116] = `TLP_TC_DEFAULT    ;
   assign tx_desc[115:112] = `RESERVED_4BIT     ;
   assign tx_desc[111]     = `TLP_TD_DEFAULT    ;
   assign tx_desc[110]     = `TLP_EP_DEFAULT    ;
   assign tx_desc[109:108] = `TLP_ATTR_DEFAULT  ;
   assign tx_desc[107:106] = `RESERVED_2BIT     ;
   assign tx_desc[105:96]  = (ep_lastupd_cycle==1'b1)?2:tx_length_dw;
   assign tx_desc[95:80]   = `ZERO_WORD         ;
   assign tx_desc[79:72]   = tx_tag             ;
   assign tx_desc[71:64]   = {tx_lbe_d, tx_fbe_d};
   assign tx_desc[63:0]    = ((ep_lastupd_cycle==1'b1)&&(addrval_32b_eplast==1'b0))?tx_addr_eplast:
                             ((ep_lastupd_cycle==1'b1)&&(addrval_32b_eplast==1'b1))?{tx_addr_eplast[31:0],32'h0}:
                             ((ep_lastupd_cycle==1'b0)&&(addrval_32b       ==1'b1))?{tx_desc_addr[31:0]  ,32'h0}:
                                                                                    tx_desc_addr;

   always @ (posedge clk_in) begin
      cfg_maxpload_dw_plus_two <= cfg_maxpload_dw+2;
   end

   // tx_ws_val_pipe ignores tx_ws on the first pulse
   // of tx_dfr and on the first pulse of tx_dv
   assign tx_ws_val = ((tx_req_p0==1'b1)||(tx_ws==1'b0))?  1'b0:1'b1;


   // cdt_length_dw counter
   always @ (posedge clk_in) begin
      if (cstate==DT_FIFO)
         cdt_length_dw <= 0;
      else begin
         if (cstate==DT_FIFO_RD_QW0)
             // DW count is decremented by 4 DWs after every mem access.
             // When starting address is offset in memory, add offset to
             // the total # of DWs to be accessed from memory to account for
             // unused DWs in the first memory access.
            cdt_length_dw <= dt_fifo_q[15:0];
         else if (tx_req_p0==1'b1) begin
              cdt_length_dw <= cdt_length_dw - tx_length_dw;
         end
      end
   end

   // PCIe 4K byte boundary off-set
   assign cfg_maxpload_byte[1:0] = 2'b00;
   assign cfg_maxpload_byte[12:2] = cfg_maxpload_dw[10:0];

   assign tx_desc_addr_4k[12] = 1'b0;
   assign tx_desc_addr_4k[11:0] = (txadd_3dw==1'b1)?
                                     tx_desc_addr_4k_3dw:tx_desc_addr_4k_4dw;
   always @ (posedge clk_in) begin
      if (init==1'b1) begin
         tx_desc_addr_4k_3dw   <= 0;
         tx_desc_addr_4k_4dw   <= 0;
      end
      else if (tx_req_p0==1'b1) begin
         tx_desc_addr_4k_3dw   <= tx_desc_addr[43:32]+tx_length_byte;
         tx_desc_addr_4k_4dw   <= tx_desc_addr[11:0]+tx_length_byte;
      end
   end

   always @ (posedge clk_in) begin
      if (init==1'b1)
         calc_4kbnd_done_byte <= cfg_maxpload_byte;
      else if ((cstate== MWR_REQ)&&(tx_ack==1'b1))
         calc_4kbnd_done_byte <= 13'h1000-tx_desc_addr_4k;
   end

   assign calc_4kbnd_done_dw[15:11] = 0;
   assign calc_4kbnd_done_dw[10:0] = calc_4kbnd_done_byte[12:2];

   assign dt_fifo_q_addr_4k[12] = 1'b0;
   assign dt_fifo_q_addr_4k[11:0] = (RC_64BITS_ADDR==0)?dt_fifo_q[43+64:32+64]:
                                                        dt_fifo_q[43+64:32+64];

   assign calc_4kbnd_dt_fifo_byte = dt_fifo_q_4K_bound;
   assign calc_4kbnd_dt_fifo_dw [15:11]= 0;
   assign calc_4kbnd_dt_fifo_dw[10:0] =  (calc_4kbnd_dt_fifo_byte[12:2]==11'h0) & (calc_4kbnd_dt_fifo_byte[1:0]>0) ?
                                         11'h1 : calc_4kbnd_dt_fifo_byte[12:2];      //  if starting addr is within 1QW OF 4K addr boundary, round to 1.
   always @ (posedge clk_in) begin
      if (init==1'b1)
         maxpload_dw <= cfg_maxpload_dw;
      else if (cstate==MWR_DV) begin
         if (cfg_maxpload_byte>calc_4kbnd_done_byte)
            maxpload_dw <= calc_4kbnd_done_dw;
         else
            maxpload_dw <= cfg_maxpload_dw;
      end
      else if (cstate==DT_FIFO_RD_QW1) begin
         if (cfg_maxpload_byte>calc_4kbnd_dt_fifo_byte)
            maxpload_dw <= calc_4kbnd_dt_fifo_dw;
         else
            maxpload_dw <= cfg_maxpload_dw;
      end
   end


   always @ (posedge clk_in) begin
      //  tx_dma_length_dw : length of data to tx
      if (cstate==DT_FIFO)
         tx_length_dw <= 0;
      else begin
         if ((cstate==TX_LENGTH)||(cstate==DONE)) begin
            if (cdt_length_dw>maxpload_dw)
               tx_length_dw  <= maxpload_dw[9:0];
            else
               tx_length_dw  <= cdt_length_dw[9:0];
         end
      end
   end



   always @ (posedge clk_in) begin
         if (cdt_length_dw>maxpload_dw) begin
              // tx_length_ow is the # of tx_data cycles required to transfer tx_length_dw payload.
              // if payld length is fraction of oct-word, then round up.
              case ({tx_start_addr_n[3:2], maxpload_dw[1:0]})
                  4'b00_00: tx_length_ow[7:0]  <= maxpload_dw[9:2];       // addr starts on 128-bit bound, and is multiple of 128
                  4'b00_01: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 1 dw
                  4'b00_10: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 2 dw
                  4'b00_11: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 3 dw

                  4'b01_00: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is multiple of 128
                  4'b01_01: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 1 dw
                  4'b01_10: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 2 dw
                  4'b01_11: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 3 dw

                  4'b10_00: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is multiple of 128
                  4'b10_01: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is xx-octwords + 1 dw
                  4'b10_10: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is xx-octwords + 2 dw
                  4'b10_11: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 2;   // addr starts on 2DW offset addr, and is xx-octwords + 3 dw

                  4'b11_00: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 3DW offset addr, and is multiple of 128
                  4'b11_01: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 1;   // addr starts on 3DW offset addr, and is xx-octwords + 1 dw
                  4'b11_10: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 2;   // addr starts on 3DW offset addr, and is xx-octwords + 2 dw
                  4'b11_11: tx_length_ow[7:0]  <= maxpload_dw[9:2] + 2;   // addr starts on 3DW offset addr, and is xx-octwords + 3 dw
              endcase
         end
         else begin
              // tx_length_ow is the # of tx_data cycles required to transfer tx_length_dw payload.
              // if payld length is fraction of oct-word, then round up.
              case ({tx_start_addr_n[3:2], cdt_length_dw[1:0]})
                  4'b00_00: tx_length_ow[7:0]  <= cdt_length_dw[9:2];       // addr starts on 128-bit bound, and is multiple of 128
                  4'b00_01: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 1 dw
                  4'b00_10: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 2 dw
                  4'b00_11: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 128-bit bound, and is xx-octwords + 3 dw

                  4'b01_00: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is multiple of 128
                  4'b01_01: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 1 dw
                  4'b01_10: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 2 dw
                  4'b01_11: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 1DW offset addr, and is xx-octwords + 3 dw

                  4'b10_00: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is multiple of 128
                  4'b10_01: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is xx-octwords + 1 dw
                  4'b10_10: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 2DW offset addr, and is xx-octwords + 2 dw
                  4'b10_11: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 2;   // addr starts on 2DW offset addr, and is xx-octwords + 3 dw

                  4'b11_00: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 3DW offset addr, and is multiple of 128
                  4'b11_01: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 1;   // addr starts on 3DW offset addr, and is xx-octwords + 1 dw
                  4'b11_10: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 2;   // addr starts on 3DW offset addr, and is xx-octwords + 2 dw
                  4'b11_11: tx_length_ow[7:0]  <= cdt_length_dw[9:2] + 2;   // addr starts on 3DW offset addr, and is xx-octwords + 3 dw
              endcase
         end
   end

   always @ (posedge clk_in) begin
      if ((cstate==TX_LENGTH)||(cstate==DONE))
         tx_length_load_cycle_next<=1'b1;
      else
         tx_length_load_cycle_next<=1'b0;
   end

   assign tx_length_ow_minus_one = (tx_length_load_cycle_next==1'b1) ? tx_length_ow-1 : tx_length_ow_minus_one_reg;   // Needed for tx_dv_gone

   always @ (posedge clk_in) begin
      if (init==1'b1)
        tx_length_ow_minus_one_reg <= 0;
      if (tx_length_load_cycle_next==1'b1)
        tx_length_ow_minus_one_reg  <= tx_length_ow-1;
   end

   assign tx_length_byte[11:2] = tx_length_dw[9:0];
   assign tx_length_byte[1:0]  = 2'b00;
   assign tx_length_byte_32ext[11:0] = tx_length_byte[11:0];
   assign tx_length_byte_32ext[31:12] = 0;
   assign tx_length_byte_64ext[11:0] = tx_length_byte[11:0];
   assign tx_length_byte_64ext[63:12] = 0;

   assign  cdt_length_byte[17:2] = cdt_length_dw[15:0];
   assign  cdt_length_byte[1:0]  = 2'b00;
   assign  cdt_length_byte[31:18] = 0;

   // Generation of tx_dfr signal
   always @ (posedge clk_in) begin
      if ((cstate==TX_LENGTH)||(cstate == START_TX_UPD_DT)||(cstate==MWR_DV))
         tx_req_reg <= 0;
      else if (tx_req==1'b1)
         tx_req_reg <= 1'b1;
   end

   // tx_req_pulse ensures that tx_dfr is set when tx_req is set
   assign tx_req_pulse = tx_req & ~tx_req_reg;

   always @ (posedge clk_in)
   begin
      tx_req_delay  <= tx_req;
      tx_req_p1   <= tx_req_p0;
   end
   assign tx_req_p0 = tx_req & ~tx_req_delay;

   assign tx_dfr_add = ((tx_dfr_non_qword_aligned_addr==1'b1) && (tx_dfr_complete==1'b0))?1'b1:1'b0;
   // Generation of tx_dfr signal might be extended of one cycle for the
   // pipelined implementation

   // extend tx_dfr of 1 cycle if the tx_adr is not qword aligned (tx_data_dw0_msb)
   assign tx_dfr_non_qword_aligned_addr = ((tx_data_dw0_msb==1'b1) && (tx_dfr_complete_pipe==1'b1))?
                                               1'b1:1'b0;


   assign tx_dfr = ((tx_dfr_p0==1'b1)||(tx_dfr_complete==1'b1)) ? 1'b1:1'b0;


   assign tx_dfr_p0 = tx_req_pulse;
   always @ (posedge clk_in) begin
      if ((tx_dfr==1'b1) && (tx_dv==1'b0))
         tx_dfr_p1 <=1'b1;
      else
         tx_dfr_p1 <=1'b0;
   end

   always @ (posedge clk_in) begin
      tx_dfr_complete_pipe <= (tx_dfr_complete==1'b1) ? 1'b1 : ((tx_ws==1'b0) ? 1'b0  : tx_dfr_complete_pipe);
   end

   always @ (posedge clk_in) begin
     if ((cstate==MWR_REQ)||(cstate==MWR_DV)) begin
        if (tx_dfr_ow_counter<tx_length_ow_minus_one)
           tx_dfr_complete<=1'b1;
        else if (tx_ws==1'b0)
         tx_dfr_complete<=1'b0;
     end
     else
        tx_dfr_complete<=1'b0;
   end

   always @ (posedge clk_in) begin
     if ((cstate==MWR_REQ)||(cstate==MWR_DV)) begin
        if ((tx_ws_val==1'b0)&&(tx_dfr_ow_counter<tx_length_ow_minus_one))
        tx_dfr_ow_counter <= tx_dfr_ow_counter+1;
     end
     else
        tx_dfr_ow_counter <= 0;
   end

   // Generation of tx_dv signal
   always @ (posedge clk_in) begin
      if (init==1'b1)
         tx_dv <= 1'b0;
      else if ((tx_dv==1'b0)||(tx_ws==1'b0))
         tx_dv <= tx_dfr;
   end

   assign tx_dv_ws_wait = tx_dv;

   assign tx_data = (ep_lastupd_cycle==1'b0)?tx_data_avalon:
                     {tx_data_eplast[63:0], tx_data_eplast[63:0]};
                   //  QW1  , QW0

   // TX_Address Generation section : tx_desc_addr, tx_addr_eplast
   // check static parameter for 64 bit vs 32 bits RC : RC_64BITS_ADDR
   // contain the 64 bits RC destination address
   // Header in RC memory
   // BRC+10h   | DW0: length
   // BRC+14h   | DW1: EP ADDR
   // BRC+18h   | DW2: RC ADDR MSB
   // BRC+1ch   | DW3: RC ADDR LSB
   // on PCIe backend when request 4 DWORDS
   // rx_data {DW1, DW0} QWORD1, {DW3, DW2} QWORD2
   //
   // 32 static parameter


   always @ (posedge clk_in) begin
      tx_desc_addr_plus_tx_length_byte_32ext <= tx_desc_addr[63:32]+tx_length_byte_32ext;
      if ((cstate==DT_FIFO)||(init==1'b1)) begin
         tx_addr_eplast       <=0;
         tx_desc_addr         <=0;
         addrval_32b_eplast   <=1'b0;
         addrval_32b          <=1'b0;
      end
      else if (RC_64BITS_ADDR==0) begin
         tx_addr_eplast[31:0] <= `ZERO_DWORD;
         addrval_32b_eplast   <=1'b0;
         addrval_32b          <=1'b0;
         // generate tx_addr_eplast
         if  (cstate == DT_FIFO_RD_QW0) begin
           tx_addr_eplast[63:32]<=dt_base_rc[31:0]+32'h0000_0008;
         end

         // generate tx_desc_addr
         txadd_3dw            <= 1'b1;
         tx_desc_addr[31:0]   <= `ZERO_DWORD;
         if (cstate==DT_FIFO_RD_QW1)
            tx_desc_addr[63:32]  <= dt_fifo_q[63+64:32+64];
         else if (cstate==DONE)
             tx_desc_addr[63:32]<=tx_desc_addr_plus_tx_length_byte_32ext;
      end
      else begin
         if  (cstate == DT_FIFO_RD_QW0) begin
            if (dt_3dw_rcadd==1'b1) begin
               tx_addr_eplast[63:32] <= dt_base_rc[31:0]+
                                                      32'h0000_0008;
               tx_addr_eplast[31:0] <= `ZERO_DWORD;
               addrval_32b_eplast   <=1'b0;
            end
            else begin
               //tx_addr_eplast <= dt_base_rc+64'h8;
               tx_addr_eplast <= tx_addr_eplast_pipe;
               if (tx_addr_eplast_pipe[63:32]==32'h0)
                  addrval_32b_eplast   <=1'b1;
               else
                  addrval_32b_eplast   <=1'b0;
            end
         end

         // Assigning tx_desc_addr
         if (cstate==DT_FIFO_RD_QW1) begin
            addrval_32b             <= 1'b0;
            // RC ADDR MSB if qword aligned
            if (dt_fifo_q[31+64:0+64]==`ZERO_DWORD) begin
               txadd_3dw            <= 1'b1;
               tx_desc_addr[63:32]  <= dt_fifo_q[63+64:32+64];
               tx_desc_addr[31:0]   <= `ZERO_DWORD;
            end
            else begin
               txadd_3dw            <= 1'b0;
               tx_desc_addr[63:32]  <= dt_fifo_q[31+64:0+64];
               tx_desc_addr[31:0]   <= dt_fifo_q[63+64:32+64];
            end
         end
         else if (cstate==DONE) begin
            // TO DO assume double word
            if (txadd_3dw==1'b1) begin
               addrval_32b         <= 1'b0;
               tx_desc_addr[63:32] <= tx_desc_addr[63:32]+tx_length_byte_32ext;
            end
            else begin
               // 32 bit addition assuming no overflow on bit 31->32
               //tx_desc_addr <= tx_desc_addr+tx_length_byte_64ext;
               tx_desc_addr <= tx_desc_addr_pipe;
               if (tx_desc_addr_pipe[63:32]==32'h0)
                  addrval_32b   <=1'b1;
               else
                  addrval_32b   <=1'b0;
            end
         end
      end
   end


   assign tx_desc_addr_n = (init==1'b1)? 0 :
                           ((RC_64BITS_ADDR==0)&&(cstate==DT_FIFO_RD_QW1)) ? {dt_fifo_q[63+64:32+64],32'h0} :
                           ((RC_64BITS_ADDR==0)&&(cstate==DONE))           ? {tx_desc_addr[63:32]+tx_length_byte_32ext[31:0], 32'h0} :
                           ((RC_64BITS_ADDR==1)&&(cstate==DT_FIFO_RD_QW1) & (dt_fifo_q[31+64:0+64]==`ZERO_DWORD)  ) ? {dt_fifo_q[63+64:32+64],32'h0} :
                           ((RC_64BITS_ADDR==1)&&(cstate==DT_FIFO_RD_QW1) & (dt_fifo_q[31+64:0+64]!=`ZERO_DWORD)  ) ? {dt_fifo_q[31+64:0+64], dt_fifo_q[63+64:32+64]} :
                           ((RC_64BITS_ADDR==1)&&(cstate==DONE)           & (txadd_3dw==1'b1) ) ?   {tx_desc_addr[63:32]+tx_length_byte_32ext, 32'h0} :
                           ((RC_64BITS_ADDR==1)&&(cstate==DONE)           & (txadd_3dw==1'b0) ) ?   tx_desc_addr_pipe :
                           tx_desc_addr_n_reg;



   assign txadd_3dw_n = (RC_64BITS_ADDR==0) ? 1'b1 :
                        ((cstate==DT_FIFO_RD_QW1) & (dt_fifo_q[31+64:0+64]==`ZERO_DWORD)) ? 1'b1 :
                        ((cstate==DT_FIFO_RD_QW1) & (dt_fifo_q[31+64:0+64]!=`ZERO_DWORD)) ? 1'b0 :
                         txadd_3dw_n_reg;



   always @ (posedge clk_in) begin
       if ((cstate==DT_FIFO)||(init==1'b1)) begin
           tx_desc_addr_n_reg <= 0;
           txadd_3dw_n_reg    <= 1;
       end
       else begin
           tx_desc_addr_n_reg <= tx_desc_addr_n;
           txadd_3dw_n_reg    <= txadd_3dw_n;
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
      if (cstate==DT_FIFO)
            tx_max_addr    <=0;
      else begin
         tx_max_addr[31:0]   <= `ZERO_DWORD;
         if (cstate==DT_FIFO_RD_QW1)
            tx_max_addr[63:32]  <= dt_fifo_q[63+64:32+64]+cdt_length_byte;
      end
   end

   always @ (posedge clk_in) begin
      if (RC_64BITS_ADDR==0) begin
         if (cstate==DT_FIFO)
            tx_rc_addr_gt_tx_max_addr <= 1'b0;
         else if (cstate==TX_LENGTH) begin
            if (tx_desc_addr[63:32]>tx_max_addr)
               tx_rc_addr_gt_tx_max_addr <= 1'b1;
            else
               tx_rc_addr_gt_tx_max_addr <= 1'b0;
         end
      end
   end

   // DMA Write control signal msi, ep_lastena
   always @ (posedge clk_in) begin
      if (cstate==DT_FIFO_RD_QW0) begin
            cdt_msi            <= dt_msi        | dt_fifo_q[16];
            cdt_eplast_ena     <= dt_eplast_ena | dt_fifo_q[17];
      end
   end

   //DMA Write performance counter
   always @ (posedge clk_in) begin
      if (init==1'b1)
         performance_counter <= 0;
         else if ((dt_ep_last_eq_dt_size==1'b1) &&
               (cstate == MWR_DV_UPD_DT) )
         performance_counter <= 0;
      else begin
         if ((requester_mrdmwr_cycle==1'b1) || (descriptor_mrd_cycle==1'b1))
            performance_counter <= performance_counter+1;
         else if (tx_ws==0)
            performance_counter <= 0;
      end
   end

   // tx_data_eplast
   // Assume RC addr is Qword aligned
   // 63:60 Design example version
   // 59:58 Transaction layer mode
   // When bit 57 set, indicates that the RC Slave module is being used
   // 56     UNUSED
   // 55:53  maxpayload for MWr
   // 52:48  UNUSED
   // 47:32 indicates the number of the last processed descriptor
   // 31:24 Avalon width
   // When 52:48  number of lanes negocatied
   always @ (posedge clk_in) begin
       tx_data_eplast[63:60] <= CDMA_VERSION;
       tx_data_eplast[59:58] <= TL_MODE;
       tx_data_eplast[57]    <= 1'b0;
       tx_data_eplast[56]    <= 1'b0;
       tx_data_eplast[55:53] <= cfg_maxpload;
       tx_data_eplast[52:49] <= 0;
       tx_data_eplast[48]    <= dt_fifo_empty;
       tx_data_eplast[47:32] <= dt_ep_last;
       tx_data_eplast[31:24] <= AVALON_WADDR;
       tx_data_eplast[23:0]  <= performance_counter;
   end

   // tx_data_avalon
   always @ (posedge clk_in) begin
      if (DMA_QWORD_ALIGN==1)
         tx_data_dw0_msb <=1'b0;
      else begin
         if (cstate==DT_FIFO)
            tx_data_dw0_msb <=1'b0;
         else begin
            if (cstate==MWR_REQ) begin       // Reevaluate address alignment at the start of every pkt for the programmed burst.  4Kboundary can re-align it.
               if (txadd_3dw==1'b1 ) begin   // Address is non-128bit aligned
                  case (tx_desc_addr[35:34])
                      2'b00:  tx_data_dw0_msb <= 1'b0;                                                  // start address is 128-bit address aligned
                      2'b01:  tx_data_dw0_msb <=  (tx_length_byte[3:2]==2'h0)      ? 1'b1 : 1'b0;       // start address is 1DW offset from 128-bit address, and payload is multiple of 128-bits
                      2'b10:  tx_data_dw0_msb <= ((tx_length_byte[3:2]== 2'h0) ||
                                                  (tx_length_byte[3:2]== 2'h3))    ? 1'b1 : 1'b0;       // start address is 2DW offset from 128-bit address, and payload is multiple of 128-bits, or odd by 3DW
                      2'b11:  tx_data_dw0_msb <= ((tx_length_byte[3:2]== 2'h0) ||
                                                  (tx_length_byte[3:2]== 2'h2) ||
                                                  (tx_length_byte[3:2]== 2'h3)  )  ? 1'b1 : 1'b0;       // start address is 3DW offset from 128-bit address, and payload is multiple of 128-bits or odd by 3DW or odd by 2DW
                  endcase
               end
               else if (txadd_3dw==1'b0) begin
                  case (tx_desc_addr[3:2])
                      2'b00:  tx_data_dw0_msb <= 1'b0;                                                   // start address is 128-bit address aligned
                      2'b01:  tx_data_dw0_msb <=  (tx_length_byte[3:2]==2'h0)      ? 1'b1 : 1'b0;        // start address is 1DW offset from 128-bit address, and payload is multiple of 128-bits
                      2'b10:  tx_data_dw0_msb <= ((tx_length_byte[3:2]== 2'h0) ||
                                                  (tx_length_byte[3:2]== 2'h3))    ? 1'b1 : 1'b0;        // start address is 2DW offset from 128-bit address, and payload is multiple of 128-bits, or odd by 3DW
                      2'b11:  tx_data_dw0_msb <= ((tx_length_byte[3:2]== 2'h0) ||
                                                  (tx_length_byte[3:2]== 2'h2) ||
                                                  (tx_length_byte[3:2]== 2'h3)   ) ? 1'b1 : 1'b0;        // start address is 3DW offset from 128-bit address, and payload is multiple of 128-bits or odd by 3DW or odd by 2DW
                  endcase
               end
               else
               // QWORD aligned
                  tx_data_dw0_msb <= 1'b0;
            end
         end
      end
   end


assign tx_data_avalon = readdata_m;


   assign readdata_m = wr_fifo_q;

   always @ (posedge clk_in) begin
      if ((tx_dv==1'b0)||(tx_data_dw0_msb==1'b0))
         readdata_m_next <=0;
      else
         readdata_m_next[31:0] <=readdata_m[63:32];
   end

   // Avalon backend signaling to Avalon memory read
   //assign read    = ~max_wr_fifo_cnt;
   always @ (posedge clk_in) begin
      if ((cstate==DT_FIFO)||(init==1'b1))
         epmem_read_cycle <=1'b0;
      else begin
         if (cstate==DT_FIFO_RD_QW1)
            epmem_read_cycle <=1'b1;
         else if (cstate==START_TX_UPD_DT)
            epmem_read_cycle <=1'b0;
      end
   end

   always @ (posedge clk_in) begin
      if ((init==1'b1)||(wr_fifo_sclr==1'b1)||(wr_fifo_empty==1'b1))
         wr_fifo_almost_full <=1'b0;
      else begin
         if (wr_fifo_usedw>WR_FIFO_ALMST_FULL)
             wr_fifo_almost_full<=1'b1;
         else
             wr_fifo_almost_full<=1'b0;
      end
   end

   assign read = 1'b1;
   assign read_int = (((cstate==DT_FIFO_RD_QW1)||(epmem_read_cycle==1'b1))&&
                  (wr_fifo_almost_full==1'b0))?1'b1:1'b0;

   always @ (posedge clk_in) begin
      if (init==1'b1)
         address_reg <= 0;
      else if (cstate==DT_FIFO_RD_QW0)
         address_reg[AVALON_WADDR-1:0]  <= dt_fifo_ep_addr_byte[AVALON_WADDR+3 : 4];    // Convert byte address to 128-bit address
      else if ((wr_fifo_full==1'b0) && (read_int==1'b1))
         address_reg[AVALON_WADDR-1:0] <= address_reg[AVALON_WADDR-1:0]+1;
   end
   assign address = address_reg;


   assign waitrequest = 0;
   assign wr_fifo_data = readdata;
   assign wr_fifo_sclr = ((init==1'b1) ||(cstate==DT_FIFO))?1'b1:1'b0;
   assign wr_fifo_rdreq = ((tx_dfr==1'b1) && (tx_ws_val==1'b0) && (inhibit_fifo_rd==1'b0) &
                           (wr_fifo_empty==1'b0)&&(ep_lastupd_cycle ==1'b0))?1'b1:1'b0;

   assign wr_fifo_wrreq = wrreq_d[2];
   // wrreq_d is a delay on th write fifo buffer which reflects the
   // memeory latency
   always @ (posedge clk_in) begin
      if ((init==1'b1)||(cstate==DT_FIFO))
         wrreq_d <= 0;
      else begin
         wrreq_d[5] <= wrreq_d[4];
         wrreq_d[4] <= wrreq_d[3];
         wrreq_d[3] <= wrreq_d[2];
         wrreq_d[2] <= wrreq_d[1];
         wrreq_d[1] <= wrreq_d[0];
         wrreq_d[0] <= read_int;
      end
   end

  assign addr_end[1:0] =  (txadd_3dw==1'b1) ? (tx_desc_addr[35:34]+ tx_length_dw[1:0]) : (tx_desc_addr[3:2]+ tx_length_dw[1:0]);

  always @ (posedge clk_in or negedge rstn) begin
      if (rstn==1'b0) begin
           addr_ends_on128bit_bound       <=  1'b1;
           last_addr_ended_on128bit_bound <=  1'b1;

      end
      else begin
           addr_ends_on128bit_bound       <=  (addr_end[1:0] == 2'h0) ? 1'b1 : 1'b0;  //
           last_addr_ended_on128bit_bound <=  (cstate == DONE) ? addr_ends_on128bit_bound : last_addr_ended_on128bit_bound;
      end
  end

   // requester_mrdmwr_cycle signal is used to enable the
   // performance counter
   always @ (posedge clk_in) begin
      if (init==1'b1)
           requester_mrdmwr_cycle<=1'b0;
      else begin
         if ((dt_fifo_empty==1'b0) && (cstate==DT_FIFO))
           requester_mrdmwr_cycle<=1'b1;
         else  begin
            if ((dt_fifo_empty==1'b1) &&
                    (cstate==MWR_REQ_UPD_DT) && (tx_ws==1'b0))
                  requester_mrdmwr_cycle<=1'b0;
         end
      end
   end


   always @ (posedge clk_in) begin
      if (cstate==MWR_REQ) begin
         if ((tx_dfr_ow_counter==tx_length_ow_minus_one) &&
                  (tx_ws==1'b0))
           tx_dv_gone <=1'b1;
      end
      else
         tx_dv_gone <=1'b0;
   end

  assign inhibit_fifo_rd_n = ((cstate==DONE) & (tx_dfr==1'b0) &(cdt_length_dw!=0) & (addr_ends_on128bit_bound==1'b1)) ? 1'b0 :
                             ((cstate==DONE) & (tx_dfr==1'b0) &(cdt_length_dw!=0) & (addr_ends_on128bit_bound==1'b0)) ? 1'b1 :
                             ((cstate==TX_DONE_WS) & (tx_dv_ws_wait==1'b0) & (cdt_length_dw!=0) & (last_addr_ended_on128bit_bound==1'b1)) ? 1'b0 :
                             ((cstate==TX_DONE_WS) & (tx_dv_ws_wait==1'b0) & (cdt_length_dw!=0) & (last_addr_ended_on128bit_bound==1'b0)) ? 1'b1 :
                             ((tx_dfr==1'b1) & (tx_ws_val==1'b0)) ? 1'b0 : inhibit_fifo_rd;

   // Requester state machine
   //    Combinatorial state transition (case state)
   always @ (*) begin
   case (cstate)
      DT_FIFO:
         begin
            if ((dt_fifo_empty==1'b0) && (init==1'b0))
               nstate = DT_FIFO_RD_QW0;
            else
               nstate = DT_FIFO;
         end

      DT_FIFO_RD_QW0:
         begin
            if (dt_fifo_empty==1'b0)
               nstate = DT_FIFO_RD_QW1;
            else
               nstate = DT_FIFO_RD_QW0;
         end

      DT_FIFO_RD_QW1:
          // wait for any pending MSI to be issued befor requesting more TX pkts
          if (cstate_msi==IDLE_MSI)
              nstate = TX_LENGTH;
          else
              nstate = cstate;

      TX_LENGTH:
         begin
            if (cdt_length_dw==0)
               nstate = DT_FIFO;
            else
               nstate =START_TX;
        end

      START_TX:
      // Waiting for Top level arbitration (tx_sel) prior to tx MEM64_WR
         begin
            if (init==1'b1)
               nstate = DT_FIFO;
            else if ((tx_sel==1'b1) &&
                     (wr_fifo_ready_to_read==1'b1)&&
                     (tx_ready_dmard==1'b0) )
               nstate = MWR_REQ;
            else
               nstate = START_TX;
         end

      MWR_REQ: // Read Request Assert tx_req
      // Set tx_req, Waiting for tx_ack
         begin
            if (init==1'b1)
               nstate = DT_FIFO;
            else if (tx_ack==1'b1)
               nstate = MWR_DV;
            else
               nstate = MWR_REQ;
         end

      MWR_DV: // Read Request Ack. tx_ack
      // Received tx_ack, clear tx_req, completing data phase
         begin
            if (tx_dv_gone==1'b1)
               nstate = DONE;
            else if ((tx_dfr_ow_counter==tx_length_ow_minus_one) &&
                  (tx_ws==1'b0))
               nstate = DONE;
            else
               nstate = MWR_DV;
         end

      DONE:
         begin
            if ((tx_dv==1'b1) && (tx_ws==1'b1))
               nstate = TX_DONE_WS;
            else begin
               if (cdt_length_dw==0) begin
                  if (cdt_eplast_ena==1'b1)
                     nstate = START_TX_UPD_DT;
                  else
                     nstate = DT_FIFO;
               end
               else begin
                  if (tx_ready_dmard ==1'b0)
                     nstate = MWR_REQ;
                  else
                     nstate = START_TX;
               end
           end
         end

      TX_DONE_WS:
            if (init==1'b1)
               nstate = DT_FIFO;
            else if (tx_dv_ws_wait==1'b1)
               nstate = TX_DONE_WS;
            else begin
               if (cdt_length_dw==0) begin
                  if (cdt_eplast_ena==1'b1)
                     nstate = START_TX_UPD_DT;
                  else
                     nstate = MWR_DV_UPD_DT;
                  end
                  else begin

                     if (tx_ready_dmard ==1'b0)
                        nstate = MWR_REQ;
                     else
                        nstate = START_TX;
                  end
            end

      // Update RC Memeory for polling info

      START_TX_UPD_DT:
      // Waiting for Top level arbitration (tx_sel) prior to tx MEM64_WR
         begin
            if (init==1'b1)
               nstate = DT_FIFO;
            else
               nstate = MWR_REQ_UPD_DT;
         end

      MWR_REQ_UPD_DT:
      // Set tx_req, Waiting for tx_ack
         begin
            if (init==1'b1)
               nstate = DT_FIFO;
            else if (tx_ack==1'b1)
               nstate = MWR_DV_UPD_DT;
            else
               nstate = MWR_REQ_UPD_DT;
         end

      MWR_DV_UPD_DT:
      // Received tx_ack, clear tx_req
          if ((tx_ws==1'b0) || (tx_dv==1'b0))
              nstate = DT_FIFO;
          else
              nstate = MWR_DV_UPD_DT;

      default:
         nstate = DT_FIFO;

   endcase
   end

   // Requester state machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in)  begin
      if (rstn==1'b0) begin
         cstate          <= DT_FIFO;
         inhibit_fifo_rd <= 1'b0;
      end
      else begin
         cstate          <= nstate;
         inhibit_fifo_rd <= inhibit_fifo_rd_n;
      end
   end


//
// write_scfifo is used as a buffer between the EP memory and tx_data
//
scfifo # (
        .add_ram_output_register ("ON")                ,
        .intended_device_family  (INTENDED_DEVICE_FAMILY)     ,
        .lpm_numwords            (WR_FIFO_NUMWORDS)      ,
        .lpm_showahead           ("OFF")               ,
        .lpm_type                ("scfifo")            ,
        .lpm_width               (AVALON_WDATA)        ,
        .lpm_widthu              (WR_FIFO_WIDTHU),
        .overflow_checking       ("OFF")               ,
        .underflow_checking      ("OFF")               ,
        .use_eab                 ("ON")
          )
          write_scfifo (
            .clock (clk_in       ),
            .sclr  (wr_fifo_sclr ),
            .data  (wr_fifo_data ),
            .wrreq (wr_fifo_wrreq),
            .rdreq (wr_fifo_rdreq),
            .q     (wr_fifo_q    ),
            .usedw (wr_fifo_usedw),
            .empty (wr_fifo_empty),
            .full  (wr_fifo_full )
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full ()
            // synopsys translate_on
            );


   ///////////////////////////////////////////////////////////////////////////
   //
   // MSI section
   //
   assign app_msi_req = (USE_MSI==0)?1'b0:(cstate_msi==MWR_REQ_MSI)  ?1'b1:1'b0;
   assign msi_ready   = (USE_MSI==0)?1'b0:(cstate_msi==START_MSI)    ?1'b1:1'b0;
   assign msi_busy    = (USE_MSI==0)?1'b0:(cstate_msi==MWR_REQ_MSI)?1'b1:1'b0;

   always @ *
   case (cstate_msi)
      IDLE_MSI:
         begin
            if ((cstate==DONE)&&(cdt_length_dw==0)&&(cdt_msi==1'b1))
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
         begin
            nstate_msi  = IDLE_MSI;
         end
   endcase

   // MSI state machine
   //    Registered state state transition
   always @ (negedge rstn or posedge clk_in)
   begin
      if (rstn==1'b0)
         cstate_msi  = IDLE_MSI;
      else
         cstate_msi = nstate_msi;
   end

   //
   // END MSI section
   //
   /////////////////////////////////////////////////////////////////////////////


endmodule
