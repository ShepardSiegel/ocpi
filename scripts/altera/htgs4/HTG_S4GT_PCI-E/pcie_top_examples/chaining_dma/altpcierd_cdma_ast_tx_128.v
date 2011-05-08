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
// File          : altpcierd_cdma_ast_tx.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module construct of the Avalon Streaming transmit port for the
// chaining DMA application DATA/Descriptor signals.
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
module altpcierd_cdma_ast_tx_128  #(
   parameter TX_PIPE_REQ=0,
   parameter ECRC_FORWARD_GENER=0
      )(
   input             clk_in,
   input             rstn,
   input             tx_stream_ready0,
   output [132:0]    txdata,
   output            tx_stream_valid0,

   //transmit section channel 0
   input             tx_req0 ,
   output            tx_ack0 ,
   input [127:0]     tx_desc0,
   output            tx_ws0  ,
   input             tx_err0 ,
   input             tx_dv0  ,
   input             tx_dfr0 ,
   input[127:0]      tx_data0,
   output            tx_fifo_empty);

   localparam TXFIFO_WIDTH=133;
   localparam TXFIFO_DEPTH=64;
   localparam TXFIFO_ALMOST_FULL=32;
   localparam TXFIFO_WIDTHU=6;

   wire[132:0]   txdata_int;
   wire[132:0]   txdata_ecrc;
   wire          txfifo_rdreq_int;
   wire          txfifo_rdreq_ecrc;
   reg           tx_stream_valid0_int;
   wire          tx_stream_valid0_ecrc;
   wire          tx_req_p0;
   reg           tx_req_next;
   reg           tx_req_p1;
   reg [127:0]   tx_data_reg;
   reg [127:0]   txdata_with_payload;
   reg [31:0]    ctrltx_address;
   wire [31:0]   ctrltx_address_n;
   reg           tx_err;
   wire          tx_sop_0;
   reg           tx_empty;
   reg           tx_sop_1;
   wire          tx_eop_1;
   wire          tx_eop_3dwh_1dwp_nonaligned;
   reg           tx_eop_ndword;
   reg [132:0]   txfifo_d;
   reg           txfifo_wrreq;
   wire [132:0]  txfifo_q;
   wire          txfifo_empty;
   wire          txfifo_full;
   wire          txfifo_almost_full;
   wire          txfifo_rdreq;
   wire [TXFIFO_WIDTHU-1:0] txfifo_usedw;
   reg           tx_ws0_r;
   reg           tx_ws0_rr;
   reg           tx_ack0_r;
   wire          tx_ws0_pipe;

   wire          txfifo_wrreq_with_payload;
   wire          ctrltx_nopayload;
   reg           ctrltx_nopayload_reg;
   wire          ctrltx_3dw;
   reg           ctrltx_3dw_reg;
   wire          ctrltx_qword_aligned;
   reg           ctrltx_qword_aligned_reg;
   wire [9:0]    ctrltx_tx_length;
   reg  [9:0]    ctrltx_tx_length_reg;

   reg           ctrltx_nopayload_r2;
   reg           ctrltx_3dw_r2;
   reg           ctrltx_qword_aligned_r2;
   reg  [1:0]    ctrltx_tx_length_r2;

   // ECRC
   wire[1:0]     user_sop;
   wire[1:0]     user_eop;
   wire[127:0]   user_data;
   wire          user_rd_req;
   reg           user_valid;
   wire [75:0]   ecrc_stream_data0_0;
   wire [75:0]   ecrc_stream_data0_1;

   reg           tx_req_int;
   reg [10:0]    tx_stream_data_dw_count;
   reg [10:0]    tx_stream_data_dw_count_reg;

   wire          txfifo_wrreq_n;
   reg           txfifoq_r_eop1;
   reg           tx_stream_data_dw_count_gt_4;
   reg           tx_stream_data_dw_count_gt_4_reg;
   wire          tx_stream_data_dw_count_gt_4_n;

   reg[132:0]    txfifo_q_pipe;
   reg           output_stage_full;

   // xhdl
   wire[31:0]    zeros_32;              assign zeros_32 = 32'h0;
   wire          zero;                  assign zero = 1'b0;
   wire[10:0]    ctrltx_tx_length_ext;  assign ctrltx_tx_length_ext = {zero, ctrltx_tx_length};

   assign tx_fifo_empty = txfifo_empty;
   assign tx_ack0 = (tx_ws0==0) ? tx_req_int :1'b0;
   assign tx_ws0  = tx_ws0_r;

   assign tx_ws0_pipe = (TX_PIPE_REQ==0)?tx_ws0:tx_ws0_rr;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          tx_req_int   <= 1'b0;
          tx_ws0_r     <= 1'b0;
          tx_ws0_rr    <= 1'b0;
          tx_ack0_r    <= 1'b0;
       end
       else begin
          tx_ws0_rr   <= tx_ws0_r;
          tx_ws0_r  <= (txfifo_almost_full==1'b1) ? 1'b1 : 1'b0;
          tx_ack0_r <= (TX_PIPE_REQ==0)?1'b0:tx_ack0;
          if ((tx_ack0==1'b1)||(tx_ack0_r==1'b1))
              tx_req_int <= 1'b0;
          else
              tx_req_int <= tx_req0;
       end
   end


   //////////////////////////////////////////////////////////////////////
   // tx_fifo

   scfifo # (
             .add_ram_output_register ("ON")          ,
             .intended_device_family  ("Stratix IV"),
             .lpm_numwords            (TXFIFO_DEPTH),
             .almost_full_value       (TXFIFO_ALMOST_FULL),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (TXFIFO_WIDTH) ,
             .lpm_widthu              (TXFIFO_WIDTHU),
             .overflow_checking       ("OFF")           ,
             .underflow_checking      ("OFF")           ,
             .use_eab                 ("ON")
             )
             tx_data_fifo_128 (
            .clock (clk_in),
            .sclr  (~rstn ),

            // RX push TAGs into TAG_FIFO
            .data  ({txfifo_d[132:131], tx_empty & ~txfifo_d[131], txfifo_d[129:0]}),
            .wrreq (txfifo_wrreq),

            // TX pop TAGs from TAG_FIFO
            .rdreq (txfifo_rdreq),
            .q     (txfifo_q),

            .empty (txfifo_empty),
            .full  (txfifo_full ),
            .almost_full  (txfifo_almost_full)
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .usedw ()
            // synopsys translate_on
            );


   /////////////////////////////////////////////////////////////
   // TX Streaming ECRC mux
   // Selects between sending output tx Stream with ECRC or
   // an output tx Stream without ECRC

   // Streaming output - ECRC mux
   assign txdata           = (ECRC_FORWARD_GENER==1) ? txdata_ecrc           : txdata_int;
   assign tx_stream_valid0 = (ECRC_FORWARD_GENER==1) ? tx_stream_valid0_ecrc : ((txfifoq_r_eop1==1'b1) && (txdata_int[131]==1'b0))?1'b0:tx_stream_valid0_int;

   // Data Fifo read control - ECRC mux
   assign txfifo_rdreq     = (ECRC_FORWARD_GENER==1) ? txfifo_rdreq_ecrc     : txfifo_rdreq_int;


   ///////////////////////////////////////////////////////
   // Streaming output data & Fifo rd control without ECRC

   assign txdata_int[132:0] = txfifo_q_pipe[132:0];
   assign txfifo_rdreq_int     = ((tx_stream_ready0==1'b1)&&(txfifo_empty==1'b0))?1'b1:1'b0;


   //  tx_stream_valid output signal
   //  used when ECRC forwarding is NOT enabled

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         tx_stream_valid0_int <=1'b0;
       output_stage_full    <= 1'b0;
      end
     else begin
          if (tx_stream_ready0==1'b0) begin
              tx_stream_valid0_int <= 1'b0;
           output_stage_full    <= output_stage_full;
        end
          else begin
           output_stage_full <= ~txfifo_empty;
            if (output_stage_full)
                tx_stream_valid0_int <= 1'b1;
            else
              tx_stream_valid0_int <= 1'b0;
        end
        txfifoq_r_eop1 <= txdata_int[128];
      end
   end
   always @ (posedge clk_in) begin
       if (tx_stream_ready0==1'b1) begin
          txfifo_q_pipe <= txfifo_q;
      end
      else begin
          txfifo_q_pipe <= txfifo_q_pipe;
      end
   end

   ////////////////////////////////////////////////////////////////////////
   //  ECRC Generator
   //  Appends ECRC field to end of txdata pulled from tx_data_fifo_128

   assign user_sop[0]  = txfifo_q[131];
   assign user_sop[1]  = 1'b0;
   assign user_eop[0]  = txfifo_q[130];
   assign user_eop[1]  = txfifo_q[128];
   assign user_data    = txfifo_q[127:0];

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
           user_valid <= 1'b0;
       end
       else begin
           if ((user_rd_req==1'b1) & (txfifo_empty==1'b0))
               user_valid <= 1'b1;
           else if (user_rd_req==1'b1)
               user_valid <= 1'b0;
           else
               user_valid <= user_valid;   // hold valid until 'acked' by rdreq
       end
   end

   assign txdata_ecrc[127:64] = ecrc_stream_data0_0[63:0];
   assign txdata_ecrc[130]    = ecrc_stream_data0_0[73];
   assign txdata_ecrc[131]    = ecrc_stream_data0_0[72];
   assign txdata_ecrc[132]    = 1'b0;
   assign txdata_ecrc[128]    = ecrc_stream_data0_1[73];
   assign txdata_ecrc[129]    = ecrc_stream_data0_1[72];
   assign txdata_ecrc[63:0]   = ecrc_stream_data0_1[63:0];

   assign txfifo_rdreq_ecrc   = ((user_rd_req==1'b1)&&(txfifo_empty==1'b0))?1'b1:1'b0;

   generate begin
      if (ECRC_FORWARD_GENER==1) begin
         altpcierd_cdma_ecrc_gen #(.AVALON_ST_128(1)
               ) cdma_ecrc_gen(
                  .clk(clk_in),
                  .rstn(rstn),
                  .user_rd_req(user_rd_req),
                  .user_sop(user_sop[0]),
                  .user_eop(user_eop),
                  .user_data(user_data),
                  .user_valid(user_valid),
                  .tx_stream_ready0(tx_stream_ready0),
                  .tx_stream_data0_0(ecrc_stream_data0_0),
                  .tx_stream_data0_1(ecrc_stream_data0_1),
                  .tx_stream_valid0(tx_stream_valid0_ecrc));
      end
   end
   endgenerate
   ///////////////////////////////////////////
   //------------------------------------------------------------
   //    Constructing TSDATA from Desc/ Data, tx_dv, tx_dfr
   //------------------------------------------------------------
   // txdata[132]     tx_err0
   // txdata[131]     tx_sop0
   // txdata[130]     tx_eop0
   // txdata[129]     tx_sop1
   // txdata[128]     tx_eop1
   //
   //                  Header |  Aligned |        Un-aligned
   //                         |          | 3 Dwords    | 4 Dwords
   // txdata[127:96]    H0    |   D0     |  -  -> D1   |     -> D3
   // txdata[95:64 ]    H1    |   D1     |  -  -> D2   |  D0 -> D4
   // txdata[63:32 ]    H2    |   D2     |  -  -> D3   |  D1 -> D5
   // txdata[31:0  ]    H4    |   D3     |  D0 -> D4   |  D2 -> D6

   assign tx_req_p0            = ((tx_req0==1'b1)&&(tx_req_next==1'b0)) ? 1'b1 : 1'b0;
   assign ctrltx_nopayload     = (tx_req_p0==1'b1) ? ((tx_desc0[126]==1'b0) ? 1'b1 : 1'b0)          : ctrltx_nopayload_reg;
   assign ctrltx_3dw           = (tx_req_p0==1'b1) ? ((tx_desc0[125]==1'b0) ? 1'b1 : 1'b0)          : ctrltx_3dw_reg;
   assign ctrltx_tx_length     = (tx_req_p0==1'b1) ? ((tx_desc0[126]==1'b1) ? tx_desc0[105:96] : 10'h0) : ctrltx_tx_length_reg;     //   Length only applies if there is a payld
   assign ctrltx_address_n     = (tx_req_p0==1'b1) ? ((tx_desc0[125]==1'b0) ?
                                                                  tx_desc0[63:32] : tx_desc0[31:0]) : ctrltx_address;

   assign ctrltx_qword_aligned = (tx_req_p1==1'b1) ? (((ctrltx_3dw==1'b1) && (tx_desc0[34:32]==0))||
                                                      ((ctrltx_3dw==1'b0) && (tx_desc0[2:0  ]==0))) :ctrltx_qword_aligned_reg;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         tx_req_next                 <= 1'b0;
         tx_req_p1                   <= 1'b0;
         ctrltx_nopayload_reg        <= 1'b0;
         ctrltx_3dw_reg              <= 1'b0;
         ctrltx_qword_aligned_reg    <= 1'b0;
         tx_stream_data_dw_count_reg <= 11'h0;
         tx_stream_data_dw_count_gt_4_reg <= 1'b0;
         ctrltx_tx_length_reg        <= 0;
         ctrltx_address              <= 32'h0;
      end
      else begin
          tx_req_next                 <= tx_req0;
          tx_req_p1                   <= tx_req_p0;
          ctrltx_nopayload_reg        <= ctrltx_nopayload;
          ctrltx_3dw_reg              <= ctrltx_3dw;
          ctrltx_qword_aligned_reg    <= ctrltx_qword_aligned;
          tx_stream_data_dw_count_reg <= tx_stream_data_dw_count;
          tx_stream_data_dw_count_gt_4_reg <= tx_stream_data_dw_count_gt_4_n;
          ctrltx_tx_length_reg        <= ctrltx_tx_length;
          ctrltx_address              <= ctrltx_address_n;
      end
   end

   assign tx_stream_data_dw_count_gt_4_n = (tx_stream_data_dw_count>11'h4);

   always @(posedge clk_in) begin
       tx_data_reg  <= ((tx_ws0_pipe==1'b0) || (tx_ack0==1'b1))  ? tx_data0 : tx_data_reg;
       tx_err       <= tx_err0;
   end

   assign tx_eop_3dwh_1dwp_nonaligned = ((tx_ack0==1'b1)&&
                                         (ctrltx_3dw==1'b1)&&(ctrltx_qword_aligned==1'b0)&&
                                         (ctrltx_tx_length==10'h1)) ? 1'b1 : 1'b0;

   assign txfifo_wrreq_with_payload = ((tx_sop_0==1'b1)||(tx_eop_1==1'b1)||
                                       ((tx_dv0==1'b1)&&(tx_ws0_pipe==1'b0))) ? 1'b1 : 1'b0;

   assign tx_sop_0 = tx_ack0;
   // ensures that back-to-back pkts are okay even if prev pkt requires extra cycle for eop
   assign tx_eop_1 = ((tx_eop_3dwh_1dwp_nonaligned==1'b1)||
                      ((ctrltx_tx_length==10'h0) & (tx_req_p1==1'b1)) ||   //  account for 4DW dataless
                      (tx_eop_ndword==1'b1)) ? 1'b1 : 1'b0;

   assign txfifo_wrreq_n = ((tx_req_p1==1'b1)&&(ctrltx_nopayload==1'b1)) ? 1'b1: txfifo_wrreq_with_payload;

   always @ (posedge clk_in) begin

      ctrltx_nopayload_r2     <= ctrltx_nopayload;
      ctrltx_qword_aligned_r2 <= ctrltx_qword_aligned;
      ctrltx_tx_length_r2     <= ctrltx_tx_length[1:0];
      ctrltx_3dw_r2           <= ctrltx_3dw;

      if ((tx_eop_1==1'b1) && (ctrltx_nopayload_r2==1'b0)) begin
         if (ctrltx_qword_aligned_r2==1'b1) begin
            if ((ctrltx_tx_length_r2==1) || (ctrltx_tx_length_r2==2))
               tx_empty<=1'b1;
            else
               tx_empty<=1'b0;
         end
         else if (ctrltx_qword_aligned_r2==1'b0) begin
            if ((ctrltx_3dw_r2==1'b1) &&  ((ctrltx_tx_length_r2==2)||(ctrltx_tx_length_r2==3)))
               tx_empty<=1'b1;
            else if ((ctrltx_3dw_r2==1'b0) && ((ctrltx_tx_length_r2==1)||(ctrltx_tx_length_r2==0)))
               tx_empty<=1'b1;
            else
               tx_empty<=1'b0;
         end
         else
            tx_empty<=1'b1;
      end
      else
         tx_empty<=1'b0;
   end

   // TX FIFO WRITE - pipelined
   always @ (posedge clk_in) begin
       txfifo_wrreq <= txfifo_wrreq_n;
       tx_sop_1     <= 1'b0;
       txfifo_d     <= ((tx_ack0==1'b1)&&(ctrltx_nopayload==1'b1)) ?
                        {tx_err0,1'b1,1'b0,1'b0,1'b1,tx_desc0[127:0]}:
                        {tx_err, tx_sop_0, tx_empty, tx_sop_1, tx_eop_1, txdata_with_payload};
   end

   always @ (*) begin
       //  Streaming EOP
       if ((ctrltx_nopayload==1'b0)&&(tx_stream_data_dw_count_gt_4_n==1'b0)&&(tx_stream_data_dw_count_gt_4_reg==1'b1))
           tx_eop_ndword  = ((ctrltx_3dw==1'b1)&&(ctrltx_qword_aligned==1'b0)&& (ctrltx_tx_length==10'h1)) ? 1'b0 :  1'b1;
       else
           tx_eop_ndword = 1'b0;
   end

   // Generate Streaming interface Data field
   always @ (*) begin
       // descriptor phase
       if (tx_ack0==1'b1) begin
           if (ctrltx_3dw==1'b1) begin
               case (ctrltx_address[3:2])
                   2'h0: txdata_with_payload = {tx_desc0[127:32], zeros_32};
                   2'h1: txdata_with_payload = {tx_desc0[127:32], tx_data0[63:32]};
                   2'h2: txdata_with_payload = {tx_desc0[127:32], zeros_32};
                   2'h3: txdata_with_payload = {tx_desc0[127:32], tx_data0[127:96]};
               endcase
           end
           else begin
               txdata_with_payload = tx_desc0;
           end
       end
       // data phase
       else  begin
           // convert 128-bit address alignement to 64-bit address alignment
           if (ctrltx_3dw==1'b1) begin
               case (ctrltx_address[3:2])
                   2'h0: txdata_with_payload = {tx_data_reg[31:0], tx_data_reg[63:32], tx_data_reg[95:64], tx_data_reg[127:96]};
                   2'h1: txdata_with_payload = {tx_data_reg[95:64], tx_data_reg[127:96], tx_data0[31:0], tx_data0[63:32]};
                   2'h2: txdata_with_payload = {tx_data_reg[95:64], tx_data_reg[127:96], tx_data0[31:0], tx_data0[63:32]};
                   2'h3: txdata_with_payload = {tx_data0[31:0], tx_data0[63:32], tx_data0[95:64], tx_data0[127:96]};
               endcase
           end
           else begin
               case (ctrltx_address[3:2])
                   2'h0: txdata_with_payload = {tx_data_reg[31:0],  tx_data_reg[63:32], tx_data_reg[95:64], tx_data_reg[127:96]};
                   2'h1: txdata_with_payload = {tx_data_reg[31:0],  tx_data_reg[63:32], tx_data_reg[95:64], tx_data_reg[127:96]};
                   2'h2: txdata_with_payload = {tx_data_reg[95:64], tx_data_reg[127:96], tx_data0[31:0], tx_data0[63:32]};
                   2'h3: txdata_with_payload = {tx_data_reg[95:64], tx_data_reg[127:96], tx_data0[31:0], tx_data0[63:32]};

               endcase
           end
       end
   end

   // Calculate number of DWs to be transferred on streaming interface
   // Including Descriptor DWs and empty (non-aligned) DWs
   always @ (*) begin
       // initialize
       if ((tx_req_p1==1'b1) & (tx_desc0[126]==1'b1)) begin
           if (tx_desc0[125]==1'b0) begin  // 3DW header pkt
               case (ctrltx_address_n[3:2])
                   2'h0:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h4; // - 4;     // add desc DW's (3DW header + 1 empty DW in header)
                   2'h1:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h3; //  - 4;     // add desc DW's (3DW header)
                   2'h2:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h4; //  - 4;     // add desc DW's (3DW header + 1 empty DW in header)
                   2'h3:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h3; //   - 4;    // add desc DW's (3DW header)
               endcase
           end
           else begin                 // 4DW header pkt
               case (ctrltx_address_n[3:2])
                   2'h1:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h5; //  + 1  - 4;    // add desc DW's (4DW header) + 1 empty data DW
                   2'h0:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h4; //  - 4;         // add desc DW's (4DW header)
                   2'h3:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h5; //  + 3 - 4;     // add desc DW's (4DW header) + 1 empty data DW
                   2'h2:  tx_stream_data_dw_count = ctrltx_tx_length_ext + 11'h4; //  + 2 - 4;     // add desc DW's (4DW header) + 2 empty data DWs
               endcase
           end
       end
       // decrement
       else if (txfifo_wrreq==1'b1)    begin                                  // decrement whenever stream data is written to FIFO

           if (tx_stream_data_dw_count_reg > 3) begin
               tx_stream_data_dw_count = tx_stream_data_dw_count_reg - 11'h4;    // 4 DWs transferred to stream
           end
           else begin
               tx_stream_data_dw_count = 11'h0;
           end
       end
       else begin
           tx_stream_data_dw_count = tx_stream_data_dw_count_reg;  // default
       end
   end



endmodule
