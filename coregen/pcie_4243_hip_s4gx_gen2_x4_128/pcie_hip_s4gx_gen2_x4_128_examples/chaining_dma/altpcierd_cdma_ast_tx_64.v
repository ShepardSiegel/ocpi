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
// File          : altpcierd_cdma_ast_tx_64.v
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
module altpcierd_cdma_ast_tx_64 #(
   parameter TX_PIPE_REQ=0,
   parameter INTENDED_DEVICE_FAMILY="Cyclone IV GX",
   parameter ECRC_FORWARD_GENER=0

      )(
   input clk_in,
   input srst,
   input             tx_stream_ready0,
   output [132:0]    txdata,
   output            tx_stream_valid0,

   //transmit section channel 0
   input             tx_req0 ,
   output            tx_ack0 ,
   input [127:0]     tx_desc0,
   output  reg       tx_ws0  ,
   input             tx_err0 ,
   input             tx_dv0  ,
   input             tx_dfr0 ,
   input[127:0]      tx_data0,
   output            tx_fifo_empty);

   localparam TXFIFO_WIDTH=133;
   localparam TXFIFO_DEPTH=32;
   localparam TXFIFO_WIDTHU=5;

   wire[132:0]   txdata_int;
   wire[132:0]   txdata_ecrc;
   wire          txfifo_rdreq_int;
   wire          txfifo_rdreq_ecrc;
   reg           tx_stream_valid0_int;
   wire          tx_stream_valid0_ecrc;
   wire          tx_req_p0;
   reg           tx_req_next;
   wire [127:0]  txdata_with_payload;
   reg           tx_err;
   wire          tx_sop_0;
   wire          tx_empty ;
   reg           tx_sop_1;
   wire          tx_eop_1;
   wire          tx_eop_3dwh_1dwp_nonaligned;
   reg           tx_eop_ndword;
   reg [132:0]   txfifo_d;
   reg           txfifo_wrreq;
   wire [132:0]  txfifo_q;
   wire          txfifo_empty;
   wire          txfifo_full;
   wire          txfifo_rdreq;
   wire [TXFIFO_WIDTHU-1:0] txfifo_usedw;

   wire          txfifo_wrreq_with_payload;
   wire          ctrltx_nopayload;
   reg           ctrltx_nopayload_reg;
   wire          ctrltx_3dw;
   reg           ctrltx_3dw_reg;
   wire          ctrltx_qword_aligned;
   reg           ctrltx_qword_aligned_reg;
   wire [9:0]    ctrltx_tx_length;
   reg  [9:0]    ctrltx_tx_length_reg;
   reg           txfifo_almostfull;
   reg           tx_req_int;
   reg           ctrltx_4dw_or_aligned_reg;
   reg           ctrltx_3dw_and_nonaligned_reg;

   // ECRC
   wire[1:0]     user_sop;
   wire[1:0]     user_eop;
   wire[127:0]   user_data;
   wire          user_rd_req;
   reg           user_valid;
   wire [75:0]   ecrc_stream_data0_0;
   wire [75:0]   ecrc_stream_data0_1;

   reg[132:0]    txfifo_q_pipe;
   reg           output_stage_full;

   wire          debug_3dw_aligned_dataless;
   wire          debug_3dw_nonaligned_dataless;
   wire          debug_4dw_aligned_dataless;
   wire          debug_4dw_nonaligned_dataless;
   wire          debug_3dw_aligned_withdata;
   wire          debug_3dw_nonaligned_withdata;
   wire          debug_4dw_aligned_withdata;
   wire          debug_4dw_nonaligned_withdata;

   //---------------------------------
   // debug monitors

   assign debug_3dw_aligned_dataless     = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b00) & (tx_desc0[34]==1'b0);
   assign debug_3dw_nonaligned_dataless  = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b00) & (tx_desc0[34]==1'b1);
   assign debug_3dw_aligned_withdata     = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b10) & (tx_desc0[34]==1'b0);
   assign debug_3dw_nonaligned_withdata  = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b10) & (tx_desc0[34]==1'b1);
   assign debug_4dw_aligned_dataless     = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b01) & (tx_desc0[2]==1'b0);
   assign debug_4dw_nonaligned_dataless  = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b01) & (tx_desc0[2]==1'b1);
   assign debug_4dw_aligned_withdata     = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b11) & (tx_desc0[2]==1'b0);
   assign debug_4dw_nonaligned_withdata  = (tx_ack0==1'b1) & (tx_desc0[126:125]==2'b11) & (tx_desc0[2]==1'b1);
  //-----------------------------------

   assign tx_fifo_empty = txfifo_empty;

   assign tx_ack0 = (txfifo_almostfull==0) ? tx_req_int:1'b0;

   always @ (posedge clk_in) begin
       if (srst==1'b1) begin
           tx_req_int        <= 1'b0;
           txfifo_almostfull <= 1'b0;
       end
       else begin
           if (tx_ack0==1'b1)
               tx_req_int <= 1'b0;
           else if (tx_req0==1'b1)
               tx_req_int <= 1'b1;
           else
               tx_req_int <= tx_req_int;

           if ((txfifo_usedw>(TXFIFO_DEPTH/2)) & (txfifo_empty==1'b0))
                txfifo_almostfull <=1'b1;
           else
                txfifo_almostfull <=1'b0;
       end
   end

   always @ (posedge clk_in) begin
       if (srst==1'b1) begin
           ctrltx_4dw_or_aligned_reg    <= 1'b0;
           ctrltx_3dw_and_nonaligned_reg <= 1'b0;
       end
       else begin
           ctrltx_4dw_or_aligned_reg     <= ((ctrltx_3dw==1'b0) || (ctrltx_qword_aligned==1'b1));  // becomes valid on 2nd phase of tx_req
           ctrltx_3dw_and_nonaligned_reg <= ((ctrltx_3dw==1'b1) && (ctrltx_qword_aligned==1'b0));  // becomes valid on 2nd phase of tx_req
       end
   end


   always @(*) begin
       if ((txfifo_almostfull==1'b1) ||
           ((tx_req_int==1'b1) &
                (ctrltx_4dw_or_aligned_reg==1'b1)))    // hold off on accepting data until desc is written, if header is 4DW or address is QWaligned

            tx_ws0 =1'b1;
       else
            tx_ws0 = 1'b0;

    end


   //////////////////////////////////////////////////////////////////////
   // tx_fifo

   scfifo # (
             .add_ram_output_register ("ON")          ,
             .intended_device_family  (INTENDED_DEVICE_FAMILY),
             .lpm_numwords            (TXFIFO_DEPTH),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (TXFIFO_WIDTH) ,
             .lpm_widthu              (TXFIFO_WIDTHU),
             .overflow_checking       ("ON")           ,
             .underflow_checking      ("ON")           ,
             .use_eab                 ("ON")
             )
             tx_data_fifo_128 (
            .clock (clk_in),
            .sclr  (srst ),

            // RX push TAGs into TAG_FIFO
            .data  (txfifo_d),
            .wrreq (txfifo_wrreq),

            // TX pop TAGs from TAG_FIFO
            .rdreq (txfifo_rdreq),
            .q     (txfifo_q),

            .empty (txfifo_empty),
            .full  (txfifo_full ),
            .usedw (txfifo_usedw)
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full ()
            // synopsys translate_on
            );


   /////////////////////////////////////////////////////////////
   // TX Streaming ECRC mux
   // Selects between sending output tx Stream with ECRC or
   // an output tx Stream without ECRC

   // Streaming output - ECRC mux
   assign txdata           = (ECRC_FORWARD_GENER==1) ? txdata_ecrc           : txdata_int;
   assign tx_stream_valid0 = (ECRC_FORWARD_GENER==1) ? tx_stream_valid0_ecrc : tx_stream_valid0_int;

   // Data Fifo read control - ECRC mux
   assign txfifo_rdreq     = (ECRC_FORWARD_GENER==1) ? txfifo_rdreq_ecrc     : txfifo_rdreq_int;


   ///////////////////////////////////////////////////////
   // Streaming output data & Fifo rd control without ECRC

   assign txdata_int[132:0] = txfifo_q_pipe[132:0];
   assign txfifo_rdreq_int  = ((tx_stream_ready0==1'b1)&&(txfifo_empty==1'b0))?1'b1:1'b0;

   //  tx_stream_valid output signal used when ECRC forwarding is NOT enabled

   always @(posedge clk_in) begin
      if (srst==1'b1) begin
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

   always @ (posedge clk_in) begin
       if (srst==1'b1) begin
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

   assign txfifo_rdreq_ecrc = ((user_rd_req==1'b1)&&(txfifo_empty==1'b0))?1'b1:1'b0;

   generate begin
      if (ECRC_FORWARD_GENER==1) begin
         altpcierd_cdma_ecrc_gen  #(.AVALON_ST_128(0))
            cdma_ecrc_gen (
               .clk(clk_in),
               .rstn(~srst),
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

   assign tx_req_p0        = ((tx_req0==1'b1) && (tx_req_next==1'b0)) ? 1'b1 : 1'b0;
   assign ctrltx_nopayload = (tx_req_p0==1'b1) ? ((tx_dfr0==1'b0)?1'b1: 1'b0)        : ctrltx_nopayload_reg;
   assign ctrltx_3dw       = (tx_req_p0==1'b1) ? ((tx_desc0[125]==1'b0)? 1'b1: 1'b0) : ctrltx_3dw_reg;
   assign ctrltx_tx_length = (tx_req_p0==1'b1) ? ((tx_desc0[126]==1'b1) ?
                                                               tx_desc0[105:96] : 0) : ctrltx_tx_length_reg;  //   Length only applies if there is a payld

   assign ctrltx_qword_aligned = (tx_req_p0 ==1'b1) ?                              //   entire tx_desc should be avail on first tx_req phase
                                 (((ctrltx_3dw==1'b1) && (tx_desc0[34:32]==0))||
                                 ((ctrltx_3dw==1'b0) && (tx_desc0[2:0  ]==0)))       : ctrltx_qword_aligned_reg;

   always @(posedge clk_in) begin
      if (srst==1'b1) begin
          tx_req_next              <= 1'b0;
          ctrltx_nopayload_reg     <= 1'b0;
          ctrltx_3dw_reg           <= 1'b0;
          ctrltx_qword_aligned_reg <= 1'b0;
          ctrltx_tx_length_reg     <= 0;
      end
      else  begin
          tx_req_next              <= tx_req0;
          ctrltx_nopayload_reg     <= ctrltx_nopayload;
          ctrltx_3dw_reg           <= ctrltx_3dw;
          ctrltx_qword_aligned_reg <= ctrltx_qword_aligned;
          ctrltx_tx_length_reg     <= ctrltx_tx_length;
      end
   end

   always @(posedge clk_in) begin
      tx_err       <= tx_err0;

   end

   // TX FIFO inputs - pipelined
   always @(posedge clk_in) begin
      txfifo_d     <= {tx_err, tx_sop_0, tx_empty, tx_sop_1, tx_eop_1, txdata_with_payload};
      txfifo_wrreq <= txfifo_wrreq_with_payload;
      tx_sop_1     <= 1'b0;
   end

   assign txfifo_wrreq_with_payload = ( (tx_req_p0==1'b1 )|| (tx_ack0==1'b1) ||     // 2 descriptor phases
                                        (tx_eop_1==1'b1)||
                                        ((tx_dv0==1'b1) & (tx_ws0==1'b0))) ?1'b1:1'b0;


   assign tx_sop_0 =  (tx_req_p0==1'b1);  // first cycle of descriptor

   assign  tx_eop_3dwh_1dwp_nonaligned = (
             (tx_ack0==1'b1)&&
            // (ctrltx_3dw==1'b1)&&(ctrltx_qword_aligned==1'b0)&&
             (ctrltx_3dw_and_nonaligned_reg==1'b1) &&                     // use registered version for performance.  only evaluated on tx_ack0 cycle (i.e. 2nd phase of tx_req)
             (ctrltx_tx_length==1)) ? 1'b1:1'b0;

   assign tx_eop_1 = ((tx_eop_3dwh_1dwp_nonaligned==1'b1)|| ((ctrltx_nopayload_reg==1'b1) & (tx_ack0==1'b1)) ||   //  account for 4DW dataless
                      (tx_eop_ndword==1'b1))?1'b1:1'b0;

  /*  Generate Streaming EOP and Data fields
            3DW
            Stream
                  H0H1  H2--  D1D0   --D2    Aligned, odd DWs      (Data & Eop is delayed)
                  H0H1  H2--  D1D0   D3D2    Aligned, even DWs     (Data & Eop is delayed)
                  H0H1  H2D0  D2D1           NonAligned, odd DWs
                  H0H1  H2D0  --D1           NonAligned, even DWs

            Desc/Data
            H0H1  H2
                  D1D0  --D2        Aligned, odd DWs
                  D1D0  D3D2        Aligned, even DWs
                  D0    D2D1        NonAligned, odd DWs
                  D0    --D1        NonAligned, even DWs
  */

   // Streaming EOP
    always @(*) begin
      if ((tx_dfr0==1'b0)&&(tx_dv0==1'b1) & (tx_ws0==1'b0)) begin  // assert eop when last data phase is accepted
          if ((ctrltx_qword_aligned==1'b1) || (ctrltx_3dw==1'b0))   // if aligned, or 4DW header, data is always deferred to cycle after descriptor phase 2
              tx_eop_ndword <=1'b1;
          else if (ctrltx_tx_length>1)                              // if not aligned adn 3DW header, and there were atleast 2 DWs
              tx_eop_ndword <=1'b1;
          else
              tx_eop_ndword <=1'b0;                                  // if not aligned, and there was only 1 word, or 0 words, eop was already asserted

      end
      else
          tx_eop_ndword <=1'b0;
   end


   assign tx_empty = 1'b1;

   // Streaming Data Field
   assign txdata_with_payload[127:64] =  (tx_req_p0==1'b1) ? tx_desc0[127:64] :
                                         // ((tx_req_int==1'b1) && (ctrltx_3dw==1'b1) && (ctrltx_qword_aligned==1'b0)) ? {tx_desc0[63:32], tx_data0[63:32]} :
                                         ((tx_req_int==1'b1) && (ctrltx_3dw_and_nonaligned_reg==1'b1)) ? {tx_desc0[63:32], tx_data0[63:32]} :
                                         (tx_req_int==1'b1)   ? tx_desc0[63:0]   :  {tx_data0[31:0],  tx_data0 [63:32] };

   assign txdata_with_payload[63:0] =  64'h0;



endmodule
