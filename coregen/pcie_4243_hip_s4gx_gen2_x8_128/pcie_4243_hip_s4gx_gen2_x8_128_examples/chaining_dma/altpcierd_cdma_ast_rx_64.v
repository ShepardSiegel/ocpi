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
// File          : altpcierd_cdma_ast_rx.v
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
module altpcierd_cdma_ast_rx_64 #(
   parameter INTENDED_DEVICE_FAMILY="Cyclone IV GX",
   parameter ECRC_FORWARD_CHECK=0
   )(
   input clk_in,
   input srst,

   input[139:0]      rxdata,
   input[15:0]       rxdata_be,
   input             rx_stream_valid0,
   output            rx_stream_ready0,

   input              rx_ack0  ,
   input              rx_ws0   ,
   output reg         rx_req0  ,
   output reg [135:0] rx_desc0 ,
   output reg [63:0]  rx_data0 ,
   output reg [7:0]   rx_be0,
   output reg         rx_dv0   ,
   output             rx_dfr0  ,
   output             rx_ecrc_check_valid,
   output [15:0]      ecrc_bad_cnt
   );

   localparam RXFIFO_WIDTH=156;
   localparam RXFIFO_DEPTH=64;
   localparam RXFIFO_WIDTHU=6;

   wire [RXFIFO_WIDTHU-1:0]   rxfifo_usedw;
   wire [RXFIFO_WIDTH-1:0] rxfifo_d ;
   wire         rxfifo_full;
   wire         rxfifo_empty;
   wire         rxfifo_rreq;
   reg          rxfifo_rreq_reg;
   wire         rxfifo_wrreq;
   wire [RXFIFO_WIDTH-1:0] rxfifo_q ;
   reg  [RXFIFO_WIDTH-1:0] rxfifo_q_reg;

   reg          rx_stream_ready0_reg;
   // ECRC Check
   wire[139:0]  rxdata_ecrc;
   wire[15:0]   rxdata_be_ecrc;
   wire         rx_stream_valid0_ecrc;
   wire         rx_stream_ready0_ecrc;
   reg          rx_ack_pending_del;
   wire         rx_ack_pending;

   reg          ctrlrx_single_cycle;
   wire         rx_rd_req;
   reg          rx_rd_req_del;


   // TLP start of packet
   wire         rx_sop;
   // TLP start of packet single pulse
   wire         rx_sop_p0;
   wire        rx_sop_p1;

   // TLP end of packet
   wire        rx_eop;
   // TLP end of packet single puclse
   wire        rx_eop_p0;

   // Set when TLP is 3 DW header
   reg         ctrlrx_3dw;
   reg         ctrlrx_3dw_reg;

   // Set TLP length
   reg [9:0]  ctrlrx_length;
   reg [9:0]   ctrlrx_length_reg;
   reg [9:0]   ctrlrx_count_length_dqword;
   reg [9:0]   ctrlrx_count_length_dword;

   // Set when TLP is 3 DW header
   reg         ctrlrx_payload;
   reg         ctrlrx_payload_reg;

   // Set when TLP are qword aligned
  wire        ctrlrx_qword_aligned;
   reg         ctrlrx_qword_aligned_reg;

   // Set when the TD digest bit is set in the descriptor
   reg         ctrlrx_digest;
   reg         ctrlrx_digest_reg;
   reg [2:0]   ctrl_next_rx_req;

   // Counter track the number of RX TLP in the RXFIFO
   reg [RXFIFO_WIDTHU-1:0] count_eop_in_rxfifo;
   wire        count_eop_nop;
   wire        last_eop_in_fifo;
   // set when there is a complete RX TLP in rxfifo
   wire        tlp_in_rxfifo;

   reg         wait_rdreq_reg;
   wire        wait_rdreq;
   wire        rx_req_cycle;

   reg        ctrlrx_single_cycle_reg;
   reg        rx_req_del;
   reg        rx_req_phase2;
   reg        rx_sop_last;     // means last data chunk was sop
   reg        rx_sop2_last;   // means last data chunk was a 2nd cycle of pkt
   reg        rx_sop_hold2;   // remember if rx_sop was received for 2 clks after the sop was popped.

   reg        count_eop_in_rxfifo_is_one;
   reg        count_eop_in_rxfifo_is_zero;

   wire       debug_3dw_aligned_dataless;
   wire       debug_3dw_nonaligned_dataless;
   wire       debug_4dw_aligned_dataless;
   wire       debug_4dw_nonaligned_dataless;
   wire       debug_3dw_aligned_withdata;
   wire       debug_3dw_nonaligned_withdata;
   wire       debug_4dw_aligned_withdata;
   wire       debug_4dw_nonaligned_withdata;

   reg[63:0]  rx_desc_hi_hold;


   wire       rx_data_fifo_almostfull;
   wire       pop_partial_tlp;
   reg        pop_partial_tlp_reg;

   // xhdl
   wire[3:0]  zeros_4;   assign zeros_4 = 4'h0;


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

   //------------------------------------------------------------
   //    Avalon ST Control Signlas
   //------------------------------------------------------------
   // rx_stream_ready0
   always @(posedge clk_in) begin
      if (srst==1'b1)
         rx_stream_ready0_reg <=1'b1;
       else begin
         if ((rxfifo_usedw>(RXFIFO_DEPTH/2))) // ||(rx_ws0==1'b1))
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
             .intended_device_family  (INTENDED_DEVICE_FAMILY),
             .lpm_numwords            (RXFIFO_DEPTH),
             .lpm_showahead           ("OFF")          ,
             .lpm_type                ("scfifo")       ,
             .lpm_width               (RXFIFO_WIDTH) ,
             .lpm_widthu              (RXFIFO_WIDTHU),
             .overflow_checking       ("ON")           ,
             .underflow_checking      ("ON")           ,
             .almost_full_value       (RXFIFO_DEPTH/2) ,
             .use_eab                 ("ON")

             )
             rx_data_fifo_128 (
            .clock (clk_in),
            .sclr  (srst ),

            // RX push TAGs into TAG_FIFO
            .data  (rxfifo_d),
            .wrreq (rxfifo_wrreq),

            // TX pop TAGs from TAG_FIFO
            .rdreq (rxfifo_rreq),
            .q     (rxfifo_q),

            .empty (rxfifo_empty),
            .full  (rxfifo_full ),
            .usedw (rxfifo_usedw),
         .almost_full (rx_data_fifo_almostfull)
            // synopsys translate_off
            ,
            .aclr (),
            .almost_empty ()
            // synopsys translate_on
            );

   assign rx_stream_ready0 = (ECRC_FORWARD_CHECK==0)?rx_stream_ready0_reg:rx_stream_ready0_ecrc;
   assign rxfifo_wrreq     = (ECRC_FORWARD_CHECK==0)?rx_stream_valid0:rx_stream_valid0_ecrc;
   assign rxfifo_d         = (ECRC_FORWARD_CHECK==0)?{rxdata_be, rxdata}: {rxdata_be_ecrc, rxdata_ecrc};

   assign rx_rd_req =  ((rx_ack_pending==1'b0) && ((rx_dv0==1'b0) | (rx_ws0==1'b0)) ) ?1'b1:1'b0;  // app advances the desc/data interface


   assign rxfifo_rreq = ((rxfifo_empty==1'b0)&&
                         (tlp_in_rxfifo==1'b1)&&
                         (rx_rd_req==1'b1) &&  (wait_rdreq==1'b0)
                         ) ?1'b1:1'b0;                             // pops data fifo

   always @(posedge clk_in) begin
      rxfifo_q_reg <= rxfifo_q;
      if (srst==1'b1)  begin
          rx_rd_req_del   <= 1'b0;
          rxfifo_rreq_reg <= 1'b0;
      end
      else begin
          rx_rd_req_del   <= rx_rd_req;             // use this to advance data thru the desc/data interface
          rxfifo_rreq_reg <= rxfifo_rreq;           // use this to decode fifo output data (i.e. data is valid)
      end
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
   assign rx_eop = ((rxfifo_q[138]==1'b1) && (rxfifo_rreq_reg==1'b1))?1'b1:1'b0;

   always @ (posedge clk_in) begin              // remember if last data chunk was an SOP
       rx_sop_last <= (rxfifo_rreq_reg==1'b1) ? rx_sop : rx_sop_last;
       rx_sop2_last <= (rxfifo_rreq_reg==1'b1) ? rx_sop_last : rx_sop2_last;
   end

   // RX_DESC
   always @(posedge clk_in) begin
      if (srst==1'b1)
         rx_desc0 <=0;
      else  begin
         if (rx_sop_p0==1'b1)
            rx_desc_hi_hold  <= rxfifo_q[127:64];

         if (rx_sop_p1==1'b1) begin
            rx_desc0[63:0]    <=  rxfifo_q[127:64];
            rx_desc0[127:64]  <= rx_desc_hi_hold;
            rx_desc0[135:128] <= rxfifo_q[135:128];
         end
      end
   end

   // RX_DATA
   always @(posedge clk_in) begin
      if ((rx_sop2_last==1'b1) & (ctrlrx_3dw==1'b1)& (ctrlrx_qword_aligned==1'b0)) begin                      // 3DW non-aligned: first dataphase
         rx_be0  <=  {rxfifo_q_reg[151:148], zeros_4};
      end
      else if ((rx_sop2_last==1'b1) & (ctrlrx_3dw==1'b0) & (ctrlrx_qword_aligned==1'b0)) begin               // 4DW non-aligned:  first dataphase
         rx_be0  <=  {rxfifo_q[151:148], zeros_4};                                                              // mask out data offset
      end
      else if ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0)) begin                                      // 3DW non-aligned:  full data cycles
          if (ctrlrx_count_length_dqword[9:1]==9'h0) begin                                                    // last data cycle with ECRC:  mask out ECRC
              case (ctrlrx_count_length_dqword[0])
                  1'b0: rx_be0 <= 8'h00;
                  1'b1: rx_be0 <= {zeros_4,  rxfifo_q_reg[155:152]};                                            // data is delayed one cycle
              endcase
          end
          else begin
              rx_be0   <= {rxfifo_q_reg[151:148], rxfifo_q_reg[155:152] };
          end
      end
      else begin                                                                                              // 3DW/4DW aligned: full data cycles
          if (ctrlrx_count_length_dqword[9:1]==9'h0) begin                                                     // last data cycle with ECRC:  mask out ECRC
              case (ctrlrx_count_length_dqword[0])
                  1'b0: rx_be0 <= 8'h00;
                  1'b1: rx_be0 <= {zeros_4,  rxfifo_q[155:152]};                                                 // no delaying of data
              endcase
          end
          else begin
              rx_be0   <= {rxfifo_q[151:148], rxfifo_q[155:152] };
          end
      end

      if ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0))
         rx_data0 <= {rxfifo_q_reg[95:64], rxfifo_q_reg[127:96]};    // delay data
      else
         rx_data0 <= {rxfifo_q[95:64], rxfifo_q[127:96]};
   end

   //
   //   RX_REQ
   always @(posedge clk_in) begin
      if (srst==1'b1)
         rx_req0 <= 1'b0;
      else if (rx_ack0==1'b1)
         rx_req0 <= 1'b0;
      else if (rx_sop_p1==1'b1)
         rx_req0 <= 1'b1;
   end

   always @ (posedge clk_in) begin
      if (srst==1'b1) begin
          rx_ack_pending_del <= 1'b0;
          rx_req_del         <= 1'b0;
          rx_req_phase2      <= 1'b0;
      end
      else begin
          rx_req_del         <= rx_req0;
          rx_req_phase2      <= (rx_ack0==1'b1) ? 1'b0 : ((rx_req_del==1'b0) & (rx_req0==1'b1)) ? 1'b1: rx_req_phase2;  // assert while in phase 2 (waiting for ack) of descriptor
          rx_ack_pending_del <= rx_ack_pending;
      end
   end

   assign rx_ack_pending = (rx_ack0==1'b1) ? 1'b0 :  (rx_req_phase2==1'b1) ? 1'b1 : rx_ack_pending_del;  // means rx_ack is delayed, hold off on fifo reads until ack is received.

   //
   //   RX_DFR
   always @(posedge clk_in) begin
      if (srst==1'b1)  begin
          ctrlrx_count_length_dqword <= 0;
      end
      else begin
           // DW unit remaining count
           if ((rx_sop_last==1'b1) & (rx_rd_req_del==1'b1))                     // load pkt length when last data was an sop, and desc/data interface advanced
               ctrlrx_count_length_dword <= ctrlrx_length;
           else if ((ctrlrx_count_length_dword>1) & (rx_rd_req_del==1'b1))      // update when desc/data inteface advances
               ctrlrx_count_length_dword <= ctrlrx_count_length_dword - 2;

           // 64 bit unit remaining count
           if ((rx_sop_p1==1'b1) & (rx_rd_req_del)) begin
              if (ctrlrx_payload==1'b1) begin
                  if (ctrlrx_qword_aligned==1'b1)                     // address aligned
                     ctrlrx_count_length_dqword <= ctrlrx_length;     // payload length in DWs
                  else
                     ctrlrx_count_length_dqword <= ctrlrx_length+1;   // add 1 DW to account for empty DW in first data cycle
               end
               else begin
                   ctrlrx_count_length_dqword <= 0;
               end
           end
           else if ((ctrlrx_count_length_dqword>1) & (rx_rd_req_del==1'b1))  // decrement only when desc/data interface is advanced
                 ctrlrx_count_length_dqword <= ctrlrx_count_length_dqword-2;
           else if (rx_rd_req_del==1'b1)
                 ctrlrx_count_length_dqword <= 0;
      end
   end


   assign rx_dfr0 = (ctrlrx_count_length_dqword>0);


   //   RX_DV
   always @(posedge clk_in) begin
      rx_dv0 <=  (rx_rd_req_del==1'b1) ? rx_dfr0 : rx_dv0 ;    // update when desc/data interfce is advanced
   end

   //------------------------------------------------------------
   //   Misc control signla to convert Avalon-ST to Desc/Data
   //------------------------------------------------------------
   assign wait_rdreq = ((rx_eop_p0==1'b1) && (rx_req_cycle==1'b1))?1'b1:
                       ((wait_rdreq_reg==1'b1) && (rx_req_cycle==1'b1))?1'b1:1'b0;

   always @(posedge clk_in) begin
      if (srst==1'b1)
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
   // this signal holds off on popping the next descriptor phase while the rx_req/
   // rx_desc is being transferred to the application.

   assign rx_req_cycle = (// (rx_sop_p0==1'b1) ||                       // in 64-bit mode, rx_req_cycle not required in sop cycle
                          (rx_sop_hold2==1'b1)) ? 1'b1 : 1'b0;

   always @(posedge clk_in) begin
      if (srst==1'b1) begin
         ctrl_next_rx_req <= 0;
         rx_sop_hold2     <= 1'b0;
      end
      else begin
         if (rx_rd_req_del==1'b1) begin
            ctrl_next_rx_req[0] <= rx_sop_p0;
            ctrl_next_rx_req[1] <= ctrl_next_rx_req[0];
            ctrl_next_rx_req[2] <= ctrl_next_rx_req[1];
            rx_sop_hold2        <= (rx_sop_p0==1'b1) || (ctrl_next_rx_req[0]==1'b1) ? 1'b1 : 1'b0;
         end
      end
   end


   // Avalon-ST control signals

   assign rx_sop_p0 = (rx_sop==1'b1) ? 1'b1 : 1'b0;  // generating pulse rx_sop_p0, p1
   assign rx_eop_p0 = (rx_eop==1'b1) ? 1'b1 : 1'b0;  // generating pulse rx_eop_p0, p1

   assign rx_sop_p1 =  (rx_sop_last==1'b1) & (rxfifo_rreq_reg==1'b1);  // current data is valid, and last data was sop


   always @ (posedge clk_in) begin
      if (srst==1'b1) begin
         ctrlrx_single_cycle      <= 1'b0;
         ctrlrx_3dw               <= 1'b0;
         ctrlrx_digest            <= 1'b0;
         ctrlrx_length            <= 0;
         ctrlrx_qword_aligned_reg <= 1'b0;
      end
      else begin
          if ((rxfifo_rreq==1'b1) & (rxfifo_q[139]==1'b1)) begin                      // update desc_hi decodes when advancing to desc_lo
               ctrlrx_single_cycle  <= (rxfifo_q[105:96]==10'h1) ? 1'b1 : 1'b0;       // ctrlrx_payload is set when the TLP has payload
               ctrlrx_payload       <= (rxfifo_q[126]==1'b1)     ? 1'b1 : 1'b0;       // ctrlrx_3dw is set when the TLP has 3 DWORD header
               ctrlrx_3dw           <= (rxfifo_q[125]==1'b0)     ? 1'b1 : 1'b0;       // ctrlrx_qword_aligned is set when the data are address aligned
               ctrlrx_digest        <= (rxfifo_q[111]==1'b1)     ? 1'b1 : 1'b0;
               ctrlrx_length[9:0]   <= (rxfifo_q[126]==1'b1)     ? rxfifo_q[105:96] : 10'h0;
          end
          ctrlrx_qword_aligned_reg <= ctrlrx_qword_aligned;
      end
  end

  assign ctrlrx_qword_aligned = (rx_sop_p1==1'b1)? ((((ctrlrx_3dw==1'b1) && (rxfifo_q[98]==0)) ||
                                                     ((ctrlrx_3dw==1'b0) && (rxfifo_q[66]==0))) ? 1'b1 : 0) : ctrlrx_qword_aligned_reg;



   assign count_eop_nop = (((rxfifo_wrreq==1'b1)&&(rxfifo_d[138]==1'b1)) &&
                           ((rxfifo_rreq_reg==1'b1)&&(rxfifo_q[138]==1'b1))) ? 1'b1:1'b0;

   assign last_eop_in_fifo = ((count_eop_in_rxfifo_is_one==1'b1) &&
                              (count_eop_nop==1'b0)&&
                              (rxfifo_rreq_reg==1'b1)&&
                              (rxfifo_q[138]==1'b1)) ?1'b1:1'b0;
 /*
   assign tlp_in_rxfifo =(//(count_eop_in_rxfifo==0)||                // Full-sized Fifo.
                          (count_eop_in_rxfifo_is_zero==1'b1) ||
                          (last_eop_in_fifo==1'b1))?  1'b0:1'b1;

*/

   assign tlp_in_rxfifo =((pop_partial_tlp==1'b1) ||                         // Reduced-sized Fifo. Pop Fifo when TLP EOP is received or when FIFO is almost full.
                          ((count_eop_in_rxfifo_is_zero==1'b0) &&
                           (last_eop_in_fifo==1'b0))) ?  1'b1:1'b0;

   // start popping a partial TLP (start of packet) even if EOP not yet received
   // when the FIFO is almost full.  hold signal until eop is received.

   assign  pop_partial_tlp = (count_eop_in_rxfifo_is_zero==1'b0) ? 1'b0 :
                             (((count_eop_in_rxfifo_is_zero==1'b1) & (rx_data_fifo_almostfull==1'b1)) ? 1'b1 : pop_partial_tlp_reg);

   always @(posedge clk_in) begin
      if (srst==1'b1) begin
          pop_partial_tlp_reg <= 1'b0;
      end
      else begin
          pop_partial_tlp_reg <= pop_partial_tlp;
      end
   end


   always @(posedge clk_in) begin
      if (srst==1'b1) begin
         count_eop_in_rxfifo <= 0;
         count_eop_in_rxfifo_is_one <= 1'b0;
         count_eop_in_rxfifo_is_zero <= 1'b1;
      end
      else if (count_eop_nop==1'b0) begin
         if ((rxfifo_wrreq==1'b1)&&(rxfifo_d[138]==1'b1)) begin
            count_eop_in_rxfifo         <= count_eop_in_rxfifo+1;
            count_eop_in_rxfifo_is_one  <= (count_eop_in_rxfifo==0) ? 1'b1 : 1'b0;
            count_eop_in_rxfifo_is_zero <= 1'b0;
         end
         else if ((rxfifo_rreq_reg==1'b1)&&(rxfifo_q[138]==1'b1)) begin
            count_eop_in_rxfifo         <= count_eop_in_rxfifo-1;
            count_eop_in_rxfifo_is_one  <= (count_eop_in_rxfifo==2) ? 1'b1 : 1'b0;
            count_eop_in_rxfifo_is_zero <= (count_eop_in_rxfifo==1) ? 1'b1 : 1'b0;
         end
      end
   end

   generate begin
      if (ECRC_FORWARD_CHECK==1) begin
         altpcierd_cdma_ecrc_check_64
           altpcierd_cdma_ecrc_check_64_i (
            // Input Avalon-ST prior to check ecrc
            .rxdata(rxdata),
            .rxdata_be(rxdata_be),
            .rx_stream_ready0(rx_stream_ready0_reg),
            .rx_stream_valid0(rx_stream_valid0),

            // Output Avalon-ST afetr checkeing ECRC
            .rxdata_ecrc(rxdata_ecrc),
            .rxdata_be_ecrc(rxdata_be_ecrc),
            .rx_stream_ready0_ecrc(rx_stream_ready0_ecrc),
            .rx_stream_valid0_ecrc(rx_stream_valid0_ecrc),

            .rx_ecrc_check_valid(rx_ecrc_check_valid),
            .ecrc_bad_cnt(ecrc_bad_cnt),
            .clk_in(clk_in),
            .srst(srst)
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
