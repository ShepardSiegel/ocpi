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
// File          : altpcierd_cdma_ast_rx_128.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module construct of the Avalon Streaming receive port for the
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
module altpcierd_cdma_ast_rx_128 #(
   parameter ECRC_FORWARD_CHECK=0
   )(
   input clk_in,
   input rstn,

   input[139:0]      rxdata,
   input[15:0]       rxdata_be,
   input             rx_stream_valid0,
   output            rx_stream_ready0,

   input              rx_ack0  ,
   input              rx_ws0   ,
   output reg         rx_req0  ,
   output reg [135:0] rx_desc0 ,
   output reg [127:0] rx_data0 ,
   output reg [15:0]  rx_be0,
   output reg         rx_dv0   ,
   output reg         rx_dfr0  ,
   output             rx_ecrc_check_valid,
   output [15:0]      ecrc_bad_cnt
   );

   localparam RXFIFO_WIDTH=156;  // WAS: 140
   localparam RXFIFO_DEPTH=1024;
   localparam RXFIFO_WIDTHU=10;

   wire [RXFIFO_WIDTHU-1:0]   rxfifo_usedw;
   wire [155:0] rxfifo_d ;
   wire         rxfifo_full;
   wire         rxfifo_empty;
   wire         rxfifo_rreq;
   reg          rxfifo_rreq_reg;
   wire         rxfifo_wrreq;
   wire [155:0] rxfifo_q ;
   reg  [155:0] rxfifo_q_reg;

   reg          rx_stream_ready0_reg;
   // ECRC Check
   wire[139:0]  rxdata_ecrc;
   wire[15:0]   rxdata_be_ecrc;
   wire         rx_stream_valid0_ecrc;
   wire         rx_stream_ready0_ecrc;
   wire         ctrlrx_single_cycle;
   reg          rx_dfr_reg;
   wire         rx_dfr_digest;
   wire         rx_sop;          // TLP start of packet
   reg          rx_sop_next;
   wire         rx_sop_p0;       // TLP start of packet single pulse
   reg          rx_sop_p1;
   wire         rx_eop;          // TLP end of packet
   reg          rx_eop_next;
   wire         rx_eop_p0;       // TLP end of packet single puclse
   reg          rx_eop_p1;
   wire         ctrlrx_3dw;                    // Set when TLP is 3 DW header
   reg          ctrlrx_3dw_reg;
   reg          ctrlrx_3dw_del;
   wire         ctrlrx_3dw_nonaligned;
   reg          ctrlrx_3dw_nonaligned_reg;
   wire[1:0]    ctrlrx_dw_addroffeset;         // address offset (in DW) from 128-bit address boundary
   reg [1:0]    ctrlrx_dw_addroffeset_reg;
   wire [9:0]   ctrlrx_length;                 // Set TLP length
   reg [9:0]    ctrlrx_length_reg;
   reg [7:0]    ctrlrx_count_length_dqword;
   reg [9:0]    ctrlrx_count_length_dword;
   wire         ctrlrx_payload;
   reg          ctrlrx_payload_reg;
   wire         ctrlrx_qword_aligned;          // Set when TLP are qword aligned
   reg          ctrlrx_qword_aligned_reg;
   wire         ctrlrx_digest;                 // Set when the TD digest bit is set in the descriptor
   reg          ctrlrx_digest_reg;
   reg [2:0]    ctrl_next_rx_req;


   reg [RXFIFO_WIDTHU-1:0] count_eop_in_rxfifo;   // Counter track the number of RX TLP in the RXFIFO
   wire         count_eop_nop;
   wire         last_eop_in_fifo;
   wire         tlp_in_rxfifo;             // set when there is a complete RX TLP in rxfifo
   reg          wait_rdreq_reg;
   wire         wait_rdreq;
   wire         rx_req_cycle;
   reg          rx_ack_pending_del;
   wire         rx_ack_pending;
   reg          rx_req_del;
   reg          rx_req_phase2;
   reg          ctrlrx_single_cycle_reg;
   wire         rx_rd_req;
   reg          rx_rd_req_del;
   reg          rx_sop_last;              // means last data chunk was a SOP
   reg[15:0]    data_tail_be_mask;        // mask out ECRC fields, and delineate end of rx_data0 DW
   reg          ctrlrx_count_length_dqword_zero;
   reg          insert_extra_dfr_cycle;
   reg          need_extra_dfr_cycle;
   reg          got_eop;

   //xhdl
   wire[3:0]    zeros_4;   assign zeros_4  = 4'h0;
   wire[7:0]    zeros_8;   assign zeros_8  = 8'h0;
   wire[11:0]   zeros_12;  assign zeros_12 = 12'h0;

   wire debug_3dw_aligned_dataless;
   wire debug_3dw_nonaligned_dataless;
   wire debug_4dw_aligned_dataless;
   wire debug_4dw_nonaligned_dataless;
   wire debug_3dw_aligned_withdata;
   wire debug_3dw_nonaligned_withdata;
   wire debug_4dw_aligned_withdata;
   wire debug_4dw_nonaligned_withdata;

   wire debug_3dw_dqw_nonaligned_withdata;
   wire debug_4dw_dqw_nonaligned_withdata;
   wire debug_3dw_dqw_aligned_withdata;
   wire debug_4dw_dqw_aligned_withdata;

   //---------------------------------
   // debug monitors

   assign debug_3dw_aligned_dataless     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b00) & (rx_desc0[34]==1'b0);
   assign debug_3dw_nonaligned_dataless  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b00) & (rx_desc0[34]==1'b1);
   assign debug_3dw_aligned_withdata     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b10) & (rx_desc0[34]==1'b0);
   assign debug_3dw_nonaligned_withdata  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b10) & (rx_desc0[34]==1'b1);
   assign debug_4dw_aligned_dataless     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b01) & (rx_desc0[2]==1'b0);
   assign debug_4dw_nonaligned_dataless  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b01) & (rx_desc0[2]==1'b1);
   assign debug_4dw_aligned_withdata     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b11) & (rx_desc0[2]==1'b0);
   assign debug_4dw_nonaligned_withdata  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b11) & (rx_desc0[2]==1'b1);
   assign debug_3dw_dqw_nonaligned_withdata  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b10) & (rx_desc0[35]==1'b1);
   assign debug_4dw_dqw_nonaligned_withdata  = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b11) & (rx_desc0[3] ==1'b1);
   assign debug_3dw_dqw_aligned_withdata     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b10) & (rx_desc0[35]==1'b0);
   assign debug_4dw_dqw_aligned_withdata     = (rx_ack0==1'b1) & (rx_desc0[126:125]==2'b11) & (rx_desc0[3] ==1'b0);
   //------------------------------------------------------------
   //    Avalon ST Control Signlas
   //------------------------------------------------------------
   // rx_stream_ready0
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         rx_stream_ready0_reg <=1'b1;
       else begin
         if ((rxfifo_usedw> (RXFIFO_DEPTH/2))) // ||(rx_ws0==1'b1))
            rx_stream_ready0_reg <=1'b0;
         else
            rx_stream_ready0_reg <=1'b1;
       end
   end

   //------------------------------------------------------------
   //    Avalon ST RX FIFO
   //------------------------------------------------------------
   scfifo # (
             .add_ram_output_register ("ON")          ,
             .intended_device_family  ("Stratix IV"),
             .lpm_numwords            (RXFIFO_DEPTH),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (RXFIFO_WIDTH) ,
             .lpm_widthu              (RXFIFO_WIDTHU),
             .overflow_checking       ("OFF")           ,
             .underflow_checking      ("OFF")           ,
             .use_eab                 ("ON")
             )
             rx_data_fifo_128 (
            .clock (clk_in),
            .sclr  (~rstn ),

            // RX push TAGs into TAG_FIFO
            .data  (rxfifo_d),
            .wrreq (rxfifo_wrreq),

            // TX pop TAGs from TAG_FIFO
            .rdreq (rxfifo_rreq),
            .q     (rxfifo_q),

            .empty (rxfifo_empty),
            .full  (rxfifo_full ),
            .usedw (rxfifo_usedw)
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty (),
            .almost_full ()
            // synopsys translate_on
            );

   assign rx_stream_ready0 = (ECRC_FORWARD_CHECK==0)?rx_stream_ready0_reg:rx_stream_ready0_ecrc;
   assign rxfifo_wrreq     = (ECRC_FORWARD_CHECK==0)?rx_stream_valid0:rx_stream_valid0_ecrc;
   assign rxfifo_d         = (ECRC_FORWARD_CHECK==0)?{rxdata_be, rxdata}: {rxdata_be_ecrc, rxdata_ecrc};

   assign rx_rd_req =  ((rx_ack_pending==1'b0) && ((rx_dv0==1'b0) | (rx_ws0==1'b0))) ?1'b1:1'b0;

   assign rxfifo_rreq = ((rxfifo_empty==1'b0)&&
                         (tlp_in_rxfifo==1'b1)&&
                         (rx_rd_req==1'b1) &&  (wait_rdreq==1'b0)) ?1'b1:1'b0;


   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          rx_rd_req_del   <= 1'b0;
          rxfifo_rreq_reg <= 1'b0;
      end
      else begin
          rx_rd_req_del   <= rx_rd_req;
          rxfifo_rreq_reg <= rxfifo_rreq;
      end
   end
   always @(posedge clk_in) begin
        rxfifo_q_reg    <= rxfifo_q;
   end

   //------------------------------------------------------------
   //    Constructing Desc/ Data, rx_dv, rx_dfr
   //------------------------------------------------------------
   // rxdata[73]        rx_sop0 [139]
   // rxdata[72]        rx_eop0 [138]
   // rxdata[73]        rx_sop1 [137]
   // rxdata[72]        rx_eop1 [136]
   // rxdata[135:128]   bar     [135:128]
   //                  Header |  Aligned |        Un-aligned
   //                         |          | 3 Dwords    | 4 Dwords
   // rxdata[127:96]    H0    |   D0     |  -  -> D1   |     -> D3
   // rxdata[95:64 ]    H1    |   D1     |  -  -> D2   |  D0 -> D4
   // rxdata[63:32 ]    H2    |   D2     |  -  -> D3   |  D1 -> D5
   // rxdata[31:0  ]    H4    |   D3     |  D0 -> D4   |  D2 -> D6


   assign rx_sop = ((rxfifo_q[139]==1'b1) && (rxfifo_rreq_reg==1'b1))?1'b1:1'b0;
   assign rx_eop = ((rxfifo_q[136]==1'b1) && (rxfifo_rreq_reg==1'b1))?1'b1:1'b0;


   always @ (posedge clk_in) begin              // remember if last data chunk was an SOP
       rx_sop_last <= (rxfifo_rreq_reg==1'b1) ? rx_sop : rx_sop_last;
   end

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          got_eop <= 1'b0;
          rx_desc0  <=0;
      end
      else begin
          got_eop <= ((rx_sop==1'b1) && (rx_eop==1'b0)) ? 1'b0 : rx_eop ? 1'b1 : got_eop;
         if ((rx_sop_p0==1'b1) )
            rx_desc0[135:0] <= rxfifo_q[135:0];
      end
   end

  // 128-bit address realignment.
  // stream data is 64-bit address aligned.
  // need to shift QW based on address alignment, and need to
  // un-flip the DWs (IS:  stream comes in wiht DW0 on left, S/B: rx_data presents DW0 on right)


  always @(posedge clk_in) begin
       if (ctrlrx_3dw_del==1'b1) begin    // 3DW header pkts pack desc and data into same stream cycle, depending on address alignment.
           case (ctrlrx_dw_addroffeset_reg)
               2'h0: rx_data0 <= {rxfifo_q[31:0], rxfifo_q[63:32], rxfifo_q[95:64], rxfifo_q[127:96]};                  // start addr is on 128-bit addr boundary
               2'h1: rx_data0 <= {rxfifo_q[95:64], rxfifo_q[127:96], rxfifo_q_reg[31:0], rxfifo_q_reg[63:32]};          // start addr is 1DW offset from 128-bit addr boundary  (first QW is saved from desc phase, and appended to next QW))
               2'h2: rx_data0 <= {rxfifo_q[95:64], rxfifo_q[127:96], rxfifo_q_reg[31:0], rxfifo_q_reg[63:32]};          // first QW is shifted left by a QW
               2'h3: rx_data0 <= {rxfifo_q_reg[31:0], rxfifo_q_reg[63:32], rxfifo_q_reg[95:64], rxfifo_q_reg[127:96]};  // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
           endcase
       end
       else begin
           // for 4DW header pkts, only QW alignment adjustment is required
           case (ctrlrx_dw_addroffeset_reg)
               2'h0: rx_data0 <= {rxfifo_q[31:0], rxfifo_q[63:32], rxfifo_q[95:64], rxfifo_q[127:96]};                  // start addr is on 128-bit addr boundary
               2'h1: rx_data0 <= {rxfifo_q[31:0], rxfifo_q[63:32], rxfifo_q[95:64], rxfifo_q[127:96]};                  // start addr is 1DW offset from 128-bit addr boundary
               2'h2: rx_data0 <= {rxfifo_q[95:64], rxfifo_q[127:96], rxfifo_q_reg[31:0], rxfifo_q_reg[63:32]};          // first QW is shifted left by a QW
               2'h3: rx_data0 <= {rxfifo_q[95:64], rxfifo_q[127:96], rxfifo_q_reg[31:0], rxfifo_q_reg[63:32]};          // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
           endcase
       end

      // BYTE ENABLES

      if ((rx_sop_last==1'b1) & (ctrlrx_3dw_del==1'b1)) begin                                                        // 3DW non-aligned:  Mask out address offset.
          case (ctrlrx_dw_addroffeset_reg)         // First Data Phase for 3DW header
              2'h0: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], rxfifo_q[155:152]}         &  data_tail_be_mask;      // No data offset
              2'h1: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], rxfifo_q_reg[143:140], zeros_4}                  &  data_tail_be_mask;      // 1 DW offset
              2'h2: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], zeros_8}                                         &  data_tail_be_mask;      // QW offset (first QW is shifted left by a QW)
              2'h3: rx_be0  <=  {rxfifo_q_reg[143:140], zeros_4, zeros_8}                                                  &  data_tail_be_mask;      // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
          endcase
      end
      else if (ctrlrx_3dw_del==1'b1) begin         // Subsequent data phases for 3DW header
          case (ctrlrx_dw_addroffeset_reg)
              2'h0: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], rxfifo_q[155:152]}                 &  data_tail_be_mask;   // No data offset
              2'h1: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], rxfifo_q_reg[143:140], rxfifo_q_reg[147:144]}         &  data_tail_be_mask;   // 1 DW offset
              2'h2: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], rxfifo_q_reg[143:140], rxfifo_q_reg[147:144]}         &  data_tail_be_mask;   // QW offset (first QW is shifted left by a QW)
              2'h3: rx_be0  <=  {rxfifo_q_reg[143:140], rxfifo_q_reg[147:144], rxfifo_q_reg[151:148], rxfifo_q_reg[155:152]} &  data_tail_be_mask;   // start addr is 1DW + 1QW offset from 128-bit addr boundary  (first QW is saved from desc phase, and placed in high QW of next phase.  all other dataphases are delayed 1 clk.)
          endcase
      end
      else if ((rx_sop_last==1'b1) & (ctrlrx_3dw_del==1'b0))  begin         //  First Data Phase for 4DW header
          case (ctrlrx_dw_addroffeset_reg)
             2'h0: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], rxfifo_q[155:152]}  &  data_tail_be_mask;
             2'h1: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], zeros_4}               &  data_tail_be_mask;   // Mask out DW offset (actually, already taken care of by core)
             2'h2: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], zeros_8}                                  &  data_tail_be_mask;
             2'h3: rx_be0  <=  {rxfifo_q[151:148], zeros_4, zeros_8}                            &  data_tail_be_mask;
          endcase
      end
      else if (ctrlrx_3dw_del==1'b0)  begin                             //  Subsequent Data Phase for 4DW header
          case (ctrlrx_dw_addroffeset_reg)
             2'h0: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], rxfifo_q[155:152]}          &  data_tail_be_mask;
             2'h1: rx_be0  <=  {rxfifo_q[143:140], rxfifo_q[147:144], rxfifo_q[151:148], rxfifo_q[155:152]}          &  data_tail_be_mask;
             2'h2: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], rxfifo_q_reg[143:140], rxfifo_q_reg[147:144]}  &  data_tail_be_mask;
             2'h3: rx_be0  <=  {rxfifo_q[151:148], rxfifo_q[155:152], rxfifo_q_reg[143:140], rxfifo_q_reg[147:144]}  &  data_tail_be_mask;
          endcase
      end
  end

  always @ (*) begin
      // create bit significant vector to mask the end of payload data.
      // this includes masking out ECRC fields.

      if (ctrlrx_count_length_dword[9:2] > 0) begin     // # of payload DWs left to pass to rx_data0 including this cycle is >4 DWs.  This count is already adjusted for addr offsets.
          data_tail_be_mask = 16'hffff;
      end
      else begin                                        // this is the last payload cycle.  mask out non-Payload bytes.
          case (ctrlrx_count_length_dword[1:0])
              2'b00: data_tail_be_mask = 16'h0000;
              2'b01: data_tail_be_mask = 16'h000f;
              2'b10: data_tail_be_mask = 16'h00ff;
              2'b11: data_tail_be_mask = 16'h0fff;
          endcase
      end
  end


   //   RX_REQ

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          rx_ack_pending_del <= 1'b0;
          rx_req0            <= 1'b0;
          rx_req_del         <= 1'b0;
          rx_req_phase2      <= 1'b0;
      end
      else begin
         if (rx_ack0==1'b1)
              rx_req0 <= 1'b0;
         else if (rx_sop_p0==1'b1)
              rx_req0 <= 1'b1;

          rx_req_del         <= rx_req0;
          rx_req_phase2      <= (rx_ack0==1'b1) ? 1'b0 : ((rx_req_del==1'b0) & (rx_req0==1'b1)) ? 1'b1: rx_req_phase2;  // assert while in phase 2 (waiting for ack) of descriptor
          rx_ack_pending_del <= rx_ack_pending;
      end
   end

   assign rx_ack_pending = (rx_ack0==1'b1) ? 1'b0 :  (rx_req_phase2==1'b1) ? 1'b1 : rx_ack_pending_del;  // means rx_ack is delayed, hold off on fifo reads until ack is received.


   //   RX_DFR
   // Calculate # of rx_data DWs to be passed to rx_data0, including empty DWs (due to address offset)
   // Construct rx_dfr/dv based on this payload count.
   // NOTE:  This desc/data interface has a 2 clk cycle response to rx_ws (and not 1)
   //        rx_ws pops the rx fifo
   //        1 clk cycle later, inputs to rx_dfr/dv/data are all updated on rx_rd_req_del (coinciding with rxfifo_q being valid)
   //        1 clk cycle later, rx_dfr/dv/data register outputs are updated.


   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         ctrlrx_count_length_dqword <= 0;
         ctrlrx_count_length_dword  <= 0;
         ctrlrx_count_length_dqword_zero <= 1'b1;
      end
      else begin
           // DW unit remaining count
           if (rx_sop_p0==1'b1) begin
               if (ctrlrx_payload==1'b1) begin
                   case (ctrlrx_dw_addroffeset)
                       2'h0: ctrlrx_count_length_dword <= ctrlrx_length;      // represents payload length (in DWs) not yet passed on rx_data0/rx_dv0
                       2'h1: ctrlrx_count_length_dword <= ctrlrx_length + 1;
                       2'h2: ctrlrx_count_length_dword <= ctrlrx_length + 2;
                       2'h3: ctrlrx_count_length_dword <= ctrlrx_length + 3;
                   endcase
               end
               else begin
                   ctrlrx_count_length_dword <= 0;
               end
           end
           else if ((ctrlrx_count_length_dword>3) & (rx_rd_req_del==1'b1))      // update when new data is valid
               ctrlrx_count_length_dword <= ctrlrx_count_length_dword - 4;

           // 128-bit unit remaining count (payload                              remaining to be popped from fifo)
           if ((ctrlrx_single_cycle==1'b1) & (rx_sop_p0==1'b1))
               ctrlrx_count_length_dqword <= 1;
           else if ((rx_sop_p0==1'b1) & (ctrlrx_payload==1'b1))begin
               casex ({ctrlrx_dw_addroffeset, ctrlrx_length[1:0]})
                  4'b00_00:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2];       // data is 128-bit aligned and modulo-128
                  4'b00_01:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;   // data is 128-bit aligned
                  4'b00_10:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;   // data is 128-bit aligned
                  4'b00_11:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;   // data is 128-bit aligned
                  4'b01_00:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b01_01:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b01_10:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b01_11:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b10_00:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b10_01:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b10_10:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b10_11:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 2;
                  4'b11_00:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b11_01:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 1;
                  4'b11_10:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 2;
                  4'b11_11:  ctrlrx_count_length_dqword[7:0] <= ctrlrx_length[9:2] + 2;
              endcase
          end
          else if ((ctrlrx_count_length_dqword>0) & (rx_rd_req_del==1'b1)) begin       // update when new data is valid
                ctrlrx_count_length_dqword <= ctrlrx_count_length_dqword-1;
          end

          if ((ctrlrx_count_length_dqword==1) & (rx_rd_req_del==1'b1)) begin       // update when new data is valid
                ctrlrx_count_length_dqword_zero <= 1'b1;
          end
          else if ((rx_sop_p0==1'b1) & (ctrlrx_payload==1'b1) ) begin
               ctrlrx_count_length_dqword_zero <= 1'b0;
          end


       end
   end


   assign rx_dfr_digest = ((rx_dfr_reg==1'b1)&&(ctrlrx_count_length_dqword>0)) ? 1'b1 : 1'b0;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         rx_dfr0 <= 1'b0;
      else begin
          if ((rx_sop_p0==1'b1) & (rxfifo_q[126]==1'b1))   // assert on sop, if there is payload
             rx_dfr0 <= 1'b1;
          else if ((ctrlrx_count_length_dqword==1) & (rx_rd_req_del==1'b1))          // deassert when counter is about to roll over to 0.
             rx_dfr0 <= 1'b0;
      end
   end


   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         rx_dfr_reg <= 1'b0;
      else if (ctrlrx_payload==1'b1) begin
         if (ctrlrx_single_cycle==1'b1)
            rx_dfr_reg <= rx_sop_p0;
         else if (rx_sop_p0==1'b1)
            rx_dfr_reg <= 1'b1;
         else if (rx_eop_p0==1'b1)
            rx_dfr_reg <= 1'b0;
      end
      else
         rx_dfr_reg <= 1'b0;
   end


   //   RX_DV
   always @(posedge clk_in) begin
      rx_dv0 <= (rx_rd_req_del==1'b1) ? rx_dfr0 : rx_dv0;  // update rx_dv0 only on rx_ws
   end

   //------------------------------------------------------------
   //   Misc control signla to convert Avalon-ST to Desc/Data
   //------------------------------------------------------------
   assign wait_rdreq =  ((rx_eop_p0==1'b1) && (rx_req_cycle==1'b1)) || (((rx_eop_p0==1'b1) || (got_eop==1'b1)) & (ctrlrx_count_length_dqword_zero==1'b0)) ? 1'b1 : //(rx_dfr0==1'b1))) ?1'b1:  // throttle fetch of next stream data if there is an eop, and within a few cycles of last rx_sop, or rx_dfr is still asserted (means an extra cycle is needed to transfer offset data)
                        ((wait_rdreq_reg==1'b1) && (rx_req_cycle==1'b1))?1'b1:1'b0;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         wait_rdreq_reg <= 1'b0;
     else if (rx_eop_p0==1'b1) begin
         if (rx_req_cycle==1'b1)
            wait_rdreq_reg <= 1'b1;
         else
            wait_rdreq_reg <= 1'b0;
      end
      else if ((wait_rdreq_reg ==1'b1)&&(rx_req_cycle==1'b0))
         wait_rdreq_reg <= 1'b0;
   end

   // rx_req_cycle with current application 3 cycle required from rx_sop
   assign rx_req_cycle = ((rx_sop_p0==1'b1) ||
                          (ctrl_next_rx_req[0]==1'b1)||
                          (ctrl_next_rx_req[1]==1'b1) )? 1'b1:1'b0;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         ctrl_next_rx_req <= 0;
      else begin
         ctrl_next_rx_req[0] <= rx_sop_p0;
         ctrl_next_rx_req[1] <= ctrl_next_rx_req[0];
         ctrl_next_rx_req[2] <= ctrl_next_rx_req[1];
      end
   end


   // Avalon-ST control signals

   assign rx_sop_p0 = (rx_sop==1'b1) ? 1'b1 : 1'b0;  // generating pulse rx_sop_p0, p1
   assign rx_eop_p0 = (rx_eop==1'b1) ? 1'b1 : 1'b0;  // generating pulse rx_eop_p0, p1

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         rx_sop_next <= 1'b0;
         rx_eop_next <= 1'b0;
      end
      else  begin
         rx_sop_next <= rx_sop;
         rx_eop_next <= rx_eop;
      end
   end
   always @(posedge clk_in) begin
      rx_sop_p1 <= rx_sop_p0;
      rx_eop_p1 <= rx_eop_p0;
   end


   assign ctrlrx_single_cycle   =  (rx_sop==1'b1) ? ((rx_eop==1'b1) ? 1'b1 :1'b0) : ctrlrx_single_cycle_reg;
   // ctrlrx_payload is set when the TLP has payload
   assign ctrlrx_payload        = ((rx_sop==1'b1)&&(rxfifo_q[126]==1'b1)) ? 1'b1  : ctrlrx_payload_reg;
    // ctrlrx_3dw is set when the TLP has 3 DWORD header
   assign ctrlrx_3dw            = ((rx_sop==1'b1)&&(rxfifo_q[125]==1'b0))?1'b1:ctrlrx_3dw_reg;
   assign ctrlrx_3dw_nonaligned = ((rx_sop==1'b1)&&(rxfifo_q[125]==1'b0)&&(rxfifo_q[34]==1'b1))?1'b1:ctrlrx_3dw_nonaligned_reg;
   assign ctrlrx_dw_addroffeset = ((rx_sop==1'b1)&&(rxfifo_q[125]==1'b0))? rxfifo_q[35:34] :
                                                          (rx_sop==1'b1) ? rxfifo_q[3:2]   : ctrlrx_dw_addroffeset_reg;

   // ctrlrx_qword_aligned is set when the data are address aligned
   assign ctrlrx_qword_aligned  = ((rx_sop==1'b1)&& (
                                      ((ctrlrx_3dw==1'b1) && (rxfifo_q[34:32]==0)) ||
                                      ((ctrlrx_3dw==1'b0) && (rxfifo_q[2:0]==0))))?1'b1:  ctrlrx_qword_aligned_reg;
   assign ctrlrx_digest         = (rx_sop==1'b1) ? ((rxfifo_q[111]==1'b1) ? 1'b1: 1'b0) : ctrlrx_digest_reg;
   assign ctrlrx_length[9:0]    = (rx_sop==1'b1) ?  ((rxfifo_q[126]==1'b1) ? rxfifo_q[105:96]: 10'h0) : ctrlrx_length_reg[9:0];

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         ctrlrx_single_cycle_reg   <= 1'b0;
         ctrlrx_payload_reg        <= 1'b0;
         ctrlrx_3dw_reg            <= 1'b0;
         ctrlrx_3dw_del            <= 1'b0;
         ctrlrx_dw_addroffeset_reg <= 1'b0;
         ctrlrx_3dw_nonaligned_reg <= 1'b0;
         ctrlrx_qword_aligned_reg  <= 1'b0;
         ctrlrx_digest_reg         <= 1'b0;
         ctrlrx_length_reg         <= 0;
         ctrlrx_length_reg         <= 0;
      end
      else begin
         ctrlrx_single_cycle_reg   <= ctrlrx_single_cycle;
         ctrlrx_dw_addroffeset_reg <= ctrlrx_dw_addroffeset;
         ctrlrx_3dw_nonaligned_reg <= ctrlrx_3dw_nonaligned;
         ctrlrx_3dw_del            <= ctrlrx_3dw;
         ctrlrx_digest_reg         <= ctrlrx_digest;
         ctrlrx_length_reg         <= ctrlrx_length;

          if (rx_sop_p0==1'b1) begin
              ctrlrx_3dw_reg           <= (rxfifo_q[125]==1'b0) ? 1'b1 : 1'b0;
              ctrlrx_payload_reg       <= (rxfifo_q[126]==1'b1) ? 1'b1 : 1'b0;
              ctrlrx_qword_aligned_reg <= (((ctrlrx_3dw==1'b1) && (rxfifo_q[34:32]==0)) ||
                                                 ((ctrlrx_3dw==1'b0) && (rxfifo_q[2:0]==0))) ? 1'b1 : 1'b0;
           end
          else if (((ctrlrx_single_cycle==1'b1)&&(ctrl_next_rx_req[2]==1'b1))||
                    ((ctrlrx_single_cycle==1'b0)&&(rx_eop_p0==1'b1))) begin
              ctrlrx_3dw_reg           <=1'b0;
              ctrlrx_payload_reg       <=1'b0;
              ctrlrx_qword_aligned_reg <= 1'b0;
          end

      end
   end


   assign count_eop_nop = (((rxfifo_wrreq==1'b1)&&(rxfifo_d[136]==1'b1)) &&
                          ((rxfifo_rreq_reg==1'b1)&&(rxfifo_q[136]==1'b1))) ? 1'b1:1'b0;

   assign last_eop_in_fifo = ((count_eop_in_rxfifo==1)&&
                              (count_eop_nop==1'b0)&&
                              (rxfifo_rreq_reg==1'b1)&&
                              (rxfifo_q[136]==1'b1)) ?1'b1:1'b0;

   assign tlp_in_rxfifo =((count_eop_in_rxfifo==0)||
                          (last_eop_in_fifo==1'b1))?  1'b0:1'b1;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         count_eop_in_rxfifo <= 0;
      else if (count_eop_nop==1'b0) begin
         if ((rxfifo_wrreq==1'b1)&&(rxfifo_d[136]==1'b1))
            count_eop_in_rxfifo <= count_eop_in_rxfifo+1;
         else if ((rxfifo_rreq_reg==1'b1)&&(rxfifo_q[136]==1'b1))
            count_eop_in_rxfifo <= count_eop_in_rxfifo-1;
      end
   end

   generate begin
      if (ECRC_FORWARD_CHECK==1) begin
         altpcierd_cdma_ecrc_check_128
           altpcierd_cdma_ecrc_check_128_i (
            // Input Avalon-ST prior to check ECRC
            .rxdata(rxdata),
            .rxdata_be(rxdata_be),
            .rx_stream_ready0(rx_stream_ready0_reg),
            .rx_stream_valid0(rx_stream_valid0),

            // Output Avalon-ST after checking ECRC
            .rxdata_ecrc(rxdata_ecrc),
            .rxdata_be_ecrc(rxdata_be_ecrc),
            .rx_stream_ready0_ecrc(rx_stream_ready0_ecrc),
            .rx_stream_valid0_ecrc(rx_stream_valid0_ecrc),

            .rx_ecrc_check_valid(rx_ecrc_check_valid),
            .ecrc_bad_cnt(ecrc_bad_cnt),
            .clk_in(clk_in),
            .srst(~rstn)
           );
      end
      else begin
         assign rxdata_ecrc = rxdata;
         assign rxdata_be_ecrc = rxdata_be;
         assign rx_stream_ready0_ecrc = rx_stream_ready0;
         assign rx_ecrc_check_valid = 1'b1;
         assign ecrc_bad_cnt        = 0;
      end
   end
   endgenerate

endmodule
