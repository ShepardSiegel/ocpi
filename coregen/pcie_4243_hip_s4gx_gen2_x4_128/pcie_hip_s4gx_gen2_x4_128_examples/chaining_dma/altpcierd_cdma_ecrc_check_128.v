// synthesis translate_off

// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_cdma_ecrc_check_128.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module performs the PCIE ECRC check on the 128-bit Avalon-ST RX data stream.
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
module altpcierd_cdma_ecrc_check_128 (
   input clk_in,
   input srst,

   input[139:0]      rxdata,
   input[15:0]       rxdata_be,
   input             rx_stream_valid0,
   output            rx_stream_ready0_ecrc,

   output reg [139:0]    rxdata_ecrc,
   output reg [15:0]     rxdata_be_ecrc,
   output reg            rx_stream_valid0_ecrc,
   input             rx_stream_ready0,
   output reg        rx_ecrc_check_valid,
   output reg [15:0] ecrc_bad_cnt

   );

   localparam RAM_DATA_WIDTH  = 140;
   localparam RAM_ADDR_WIDTH  = 8;
   localparam PIPELINE_DEPTH  =4;

   // Bits in rxdata
   localparam SOP_BIT   = 139;
   localparam EOP_BIT   = 136;
   localparam EMPTY_BIT = 137;

   wire rx_sop;
   reg  rx_sop_crc_in;

   wire rx_eop;
   reg  rx_eop_reg;
   reg rx_eop_crc_in;

   reg [3:0] rx_empty;
   wire [31:0] crc_32;
   wire crcbad;
   wire crcvalid;

   // Set TLP length
   reg  [9:0]  ctrlrx_cnt_len_dw;
   reg  [9:0]  ctrlrx_cnt_len_dw_reg;

   // Set when TLP is 3 DW header
   wire ctrlrx_payload;
   reg  ctrlrx_payload_reg;

   // Set when TLP is 3 DW header
   wire ctrlrx_3dw;
   reg  ctrlrx_3dw_reg;

   // Set when TLP are qword aligned
   wire ctrlrx_qword_aligned;
   reg ctrlrx_qword_aligned_reg;

   // Set when the TD digest bit is set in the descriptor
   wire ctrlrx_digest;
   reg  ctrlrx_digest_reg;
   reg  [PIPELINE_DEPTH-1:0] ctrlrx_digest_pipe;

   reg[139:0]              rxdata_pipeline [PIPELINE_DEPTH-1:0];
   reg[15:0]               rxdata_be_pipeline [PIPELINE_DEPTH-1:0];
   reg[PIPELINE_DEPTH-1:0] rx_stream_valid_pipeline;

   wire ctrlrx_3dw_aligned;
   reg  ctrlrx_3dw_aligned_reg;

   wire ctrlrx_3dw_nonaligned;
   reg  ctrlrx_3dw_nonaligned_reg;

   wire ctrlrx_4dw_non_aligned;
   reg  ctrlrx_4dw_non_aligned_reg;

   wire ctrlrx_4dw_aligned;
   reg  ctrlrx_4dw_aligned_reg;

   reg ctrlrx_single_cycle_reg;

   integer i;

   reg [127:0] rxdata_crc_reg ;
   wire        rx_valid_crc_in ;

   wire [127:0] rxdata_byte_swap ;
   wire [127:0] rxdata_crc_in ;
   wire ctrlrx_single_cycle;

   reg [10:0]  rx_payld_remain_dw;
   wire [10:0] rx_payld_len;

   reg  rx_valid_crc_pending;
   reg  single_crc_cyc;
   reg  send_rx_eop_crc_early;

   reg  debug_ctrlrx_4dw_offset0;
   reg  debug_ctrlrx_4dw_offset1;
   reg  debug_ctrlrx_4dw_offset2;
   reg  debug_ctrlrx_4dw_offset3;

   reg  debug_ctrlrx_3dw_offset0;
   reg  debug_ctrlrx_3dw_offset1;
   reg  debug_ctrlrx_3dw_offset2;
   reg  debug_ctrlrx_3dw_offset3;

   reg  debug_ctrlrx_4dw_offset0_nopayld;
   reg  debug_ctrlrx_4dw_offset1_nopayld;
   reg  debug_ctrlrx_4dw_offset2_nopayld;
   reg  debug_ctrlrx_4dw_offset3_nopayld;

   reg  debug_ctrlrx_3dw_offset0_nopayld;
   reg  debug_ctrlrx_3dw_offset1_nopayld;
   reg  debug_ctrlrx_3dw_offset2_nopayld;
   reg  debug_ctrlrx_3dw_offset3_nopayld;

   wire[11:0] zeros12;  assign zeros12 = 12'h0;
   wire[7:0]  zeros8;   assign zeros8  = 8'h0;
   wire[3:0]  zeros4;   assign zeros4  = 4'h0;

   wire[15:0] rxdata_be_15_12;  assign rxdata_be_15_12 = {rxdata_be[15:12], zeros12};
   wire[15:0] rxdata_be_15_8;   assign rxdata_be_15_8  = {rxdata_be[15:8],  zeros8};
   wire[15:0] rxdata_be_15_4;   assign rxdata_be_15_4  = {rxdata_be[15:4],  zeros4};

   ////////////////////////////////////////////////////////////////////////////
   //
   //  Drop ECRC field from the data stream/rx_be.
   //  Regenerate rx_st_eop.
   //  Set TD bit to 0.
   //

   assign rx_payld_len = (rxdata[105:96] == 0) ? 11'h400 : {1'b0, rxdata[105:96]};  // account for 1024DW

   always @ (posedge clk_in ) begin
       if (srst==1'b1) begin
           rxdata_ecrc           <= 140'h0;
           rxdata_be_ecrc        <= 16'h0;
           rx_payld_remain_dw    <= 11'h0;
           rx_stream_valid0_ecrc <= 1'b0;
       end
       else begin
           rxdata_ecrc[138] <= 1'b0;
           rx_stream_valid0_ecrc <= 1'b0;  // default
           /////////////////////////
           // TLP has Digest
           //
           if (ctrlrx_digest==1'b1) begin
               if (rx_sop==1'b1) begin
                   rxdata_ecrc[111]        <= 1'b0;
                   rxdata_ecrc[135:112]    <= rxdata[135:112];
                   rxdata_ecrc[110:0]      <= rxdata[110:0];
                   rxdata_ecrc[SOP_BIT]    <= 1'b1;
                   rxdata_ecrc[EOP_BIT]    <= (rxdata[126]==1'b0) | ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0) & (rxdata[105:96]==10'h1));
                   rxdata_ecrc[EMPTY_BIT]  <= 1'b0;
                   rxdata_be_ecrc          <= rxdata_be;
                   rx_stream_valid0_ecrc   <= 1'b1;
                   // Load the # of payld DWs remaining in next cycles
                   if (rxdata[126]==1'b1) begin    // if there is payload
                       if ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0)) begin
                           rx_payld_remain_dw <= rx_payld_len - 1;
                       end
                       // 3DW aligned, or 4DW nonaligned
                       // Add 1 DW to account for empty field
                       else if ( //((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b1)) |
                                ((ctrlrx_3dw==1'b0) & (ctrlrx_qword_aligned==1'b0))   )  begin
                           rx_payld_remain_dw <= rx_payld_len + 1;
                       end
                       else begin
                           rx_payld_remain_dw <= rx_payld_len;
                       end
                   end
                   else begin
                       rx_payld_remain_dw <= 11'h0;
                   end
               end
               else if (rx_stream_valid0==1'b1) begin
                   rxdata_ecrc[SOP_BIT] <= 1'b0;
                   rxdata_ecrc[135:0]   <= rxdata[135:0];
                   case (rx_payld_remain_dw)
                       11'h1: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_ecrc[EMPTY_BIT] <= 1'b1;
                           rxdata_be_ecrc         <= rxdata_be_15_12;
                       end
                       11'h2: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_ecrc[EMPTY_BIT] <= 1'b1;
                           rxdata_be_ecrc         <= rxdata_be_15_8;
                       end
                       11'h3: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_ecrc[EMPTY_BIT] <= 1'b0;
                           rxdata_be_ecrc         <= rxdata_be_15_4;
                       end
                       11'h4: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_ecrc[EMPTY_BIT] <= 1'b0;
                           rxdata_be_ecrc         <= rxdata_be[15:0];
                       end
                       default: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b0;
                           rxdata_ecrc[EMPTY_BIT] <= 1'b0;
                           rxdata_be_ecrc         <= rxdata_be[15:0];
                       end
                   endcase
                   rx_stream_valid0_ecrc  <= (rx_payld_remain_dw > 11'h0) ? 1'b1 : 1'b0;

                   // Decrement payld count as payld is received
                   rx_payld_remain_dw <= (rx_payld_remain_dw < 4) ? 11'h0 : rx_payld_remain_dw - 11'h4;
               end
           end
           ///////////////
           // No Digest
           //
           else begin
               rxdata_ecrc           <= rxdata;
               rxdata_be_ecrc        <= rxdata_be;
               rx_stream_valid0_ecrc <= rx_stream_valid0;
           end
       end
   end



   ////////////////////////////////////////////////////////////////////////////
   //
   // RX Avalon-ST input delayed of PIPELINE_DEPTH to RX Avalon-ST output
   //


   assign rx_stream_ready0_ecrc = rx_stream_ready0;


   ////////////////////////////////////////////////////////////////////////////
   //
   // CRC MegaCore instanciation
   //
   altpcierd_rx_ecrc_128 rx_ecrc_128 (
          .reset_n       (~srst),
          .clk           (clk_in),
          .data          (rxdata_crc_in[127:0]),
          .datavalid     (ctrlrx_digest_reg & rx_valid_crc_in),   // use registered version of ctrlrx_digest since crc_in is delayed 1 cycle from input
          .startofpacket (rx_sop_crc_in),
          .endofpacket   (rx_eop_crc_in),
          .empty         (rx_empty),
          .crcbad        (crcbad),
          .crcvalid      (crcvalid));


   assign  rx_valid_crc_in =  (rx_sop_crc_in & (ctrlrx_single_cycle | rx_stream_valid0)) |
                              (rx_valid_crc_pending & rx_stream_valid0) |
                              (rx_eop_crc_in & ~send_rx_eop_crc_early);

   // Inputs to the MegaCore


   always @(posedge clk_in) begin
       if (srst==1'b1) begin
           rx_valid_crc_pending  <= 1'b0;
           rx_sop_crc_in         <= 1'b0;
           rx_eop_crc_in         <= 1'b0;
           rx_empty              <= 1'b0;
           send_rx_eop_crc_early <= 1'b0;
           ctrlrx_3dw_aligned_reg     <= 1'b0;
           ctrlrx_3dw_nonaligned_reg  <= 1'b0;
           ctrlrx_4dw_non_aligned_reg <= 1'b0;
           ctrlrx_4dw_aligned_reg     <= 1'b0;

           debug_ctrlrx_4dw_offset0   <= 1'b0;
           debug_ctrlrx_4dw_offset1   <= 1'b0;
           debug_ctrlrx_4dw_offset2   <= 1'b0;
           debug_ctrlrx_4dw_offset3   <= 1'b0;

           debug_ctrlrx_3dw_offset0   <= 1'b0;
           debug_ctrlrx_3dw_offset1   <= 1'b0;
           debug_ctrlrx_3dw_offset2   <= 1'b0;
           debug_ctrlrx_3dw_offset3   <= 1'b0;

           debug_ctrlrx_4dw_offset0_nopayld   <= 1'b0;
           debug_ctrlrx_4dw_offset1_nopayld   <= 1'b0;
           debug_ctrlrx_4dw_offset2_nopayld   <= 1'b0;
           debug_ctrlrx_4dw_offset3_nopayld   <= 1'b0;

           debug_ctrlrx_3dw_offset0_nopayld   <= 1'b0;
           debug_ctrlrx_3dw_offset1_nopayld   <= 1'b0;
           debug_ctrlrx_3dw_offset2_nopayld   <= 1'b0;
           debug_ctrlrx_3dw_offset3_nopayld   <= 1'b0;
       end
       else begin
           if ((rx_sop==1'b1) & (rx_stream_valid0==1'b1) & (ctrlrx_digest==1'b1) ) begin
              rx_sop_crc_in <= 1'b1;
           end
           else if ((rx_sop_crc_in==1'b1) & (rx_valid_crc_in==1'b1)) begin
               rx_sop_crc_in <= 1'b0;
           end

           ctrlrx_3dw_aligned_reg     <= ctrlrx_3dw_aligned;
           ctrlrx_3dw_nonaligned_reg  <= ctrlrx_3dw_nonaligned;
           ctrlrx_4dw_non_aligned_reg <= ctrlrx_4dw_non_aligned;
           ctrlrx_4dw_aligned_reg     <= ctrlrx_4dw_aligned;

           if ((rx_stream_valid0==1'b1) & (rx_sop==1'b1)) begin
               debug_ctrlrx_4dw_offset0   <= (ctrlrx_3dw==1'b0) &  (rxdata[126]==1'b1) & (rxdata[3:0]==4'h0);  // no addr offset
               debug_ctrlrx_4dw_offset1   <= (ctrlrx_3dw==1'b0) &  (rxdata[126]==1'b1) & (rxdata[3:0]==4'h4);  // 1DW addr offset
               debug_ctrlrx_4dw_offset2   <= (ctrlrx_3dw==1'b0) &  (rxdata[126]==1'b1) & (rxdata[3:0]==4'h8);  // 2DW addr offset
               debug_ctrlrx_4dw_offset3   <= (ctrlrx_3dw==1'b0) &  (rxdata[126]==1'b1) & (rxdata[3:0]==4'hc);  // 3DW addr offset

               debug_ctrlrx_3dw_offset0   <= (ctrlrx_3dw==1'b1) &  (rxdata[126]==1'b1) & (rxdata[35:32]==4'h0);  // no addr offset
               debug_ctrlrx_3dw_offset1   <= (ctrlrx_3dw==1'b1) &  (rxdata[126]==1'b1) & (rxdata[35:32]==4'h4);  // 1DW addr offset
               debug_ctrlrx_3dw_offset2   <= (ctrlrx_3dw==1'b1) &  (rxdata[126]==1'b1) & (rxdata[35:32]==4'h8);  // 2DW addr offset
               debug_ctrlrx_3dw_offset3   <= (ctrlrx_3dw==1'b1) &  (rxdata[126]==1'b1) & (rxdata[35:32]==4'hc);  // 3DW addr offset

               debug_ctrlrx_4dw_offset0_nopayld   <= (ctrlrx_3dw==1'b0) & (rxdata[126]==1'b0) & (rxdata[3:0]==4'h0);  // no addr offset
               debug_ctrlrx_4dw_offset1_nopayld   <= (ctrlrx_3dw==1'b0) & (rxdata[126]==1'b0) &  (rxdata[3:0]==4'h4);  // 1DW addr offset
               debug_ctrlrx_4dw_offset2_nopayld   <= (ctrlrx_3dw==1'b0) & (rxdata[126]==1'b0) &  (rxdata[3:0]==4'h8);  // 2DW addr offset
               debug_ctrlrx_4dw_offset3_nopayld   <= (ctrlrx_3dw==1'b0) & (rxdata[126]==1'b0) &  (rxdata[3:0]==4'hc);  // 3DW addr offset

               debug_ctrlrx_3dw_offset0_nopayld   <= (ctrlrx_3dw==1'b1) & (rxdata[126]==1'b0) &  (rxdata[35:32]==4'h0);  // no addr offset
               debug_ctrlrx_3dw_offset1_nopayld   <= (ctrlrx_3dw==1'b1) & (rxdata[126]==1'b0) &  (rxdata[35:32]==4'h4);  // 1DW addr offset
               debug_ctrlrx_3dw_offset2_nopayld   <= (ctrlrx_3dw==1'b1) & (rxdata[126]==1'b0) &  (rxdata[35:32]==4'h8);  // 2DW addr offset
               debug_ctrlrx_3dw_offset3_nopayld   <= (ctrlrx_3dw==1'b1) & (rxdata[126]==1'b0) &  (rxdata[35:32]==4'hc);  // 3DW addr offset
           end

           if ((rx_sop==1'b1) & (rx_stream_valid0==1'b1) & (ctrlrx_digest==1'b1)) begin
               if ((ctrlrx_3dw==1'b1) & (ctrlrx_payload==1'b0)) begin
                   rx_eop_crc_in        <= 1'b1;      // Pack ECRC into single cycle
                   rx_empty             <= 1'b0;
                   rx_valid_crc_pending <= 1'b0;
               end
               else begin
                   rx_eop_crc_in        <= 1'b0;      // multicycle
                   rx_empty             <= 1'b0;
                   rx_valid_crc_pending <= 1'b1;
                   // eop is sent 1 cycle early when the payld is a multiple
                   // of 4DWs, and the TLP is 3DW Header aligned
                   send_rx_eop_crc_early <= (ctrlrx_3dw_aligned==1'b1) & (ctrlrx_payload==1'b1) & (rxdata[97:96]==2'h0);
               end
           end
           else if (rx_valid_crc_pending == 1'b1)  begin
               // end crc data early
               if (send_rx_eop_crc_early==1'b1) begin
                   rx_valid_crc_pending <= ((ctrlrx_cnt_len_dw == 10'h0) & (rx_stream_valid0==1'b1)) ? 1'b0 : 1'b1;
                   if ((ctrlrx_cnt_len_dw == 10'h4)& (rx_stream_valid0==1'b1)) begin
                       rx_eop_crc_in <= 1'b1;
                       rx_empty      <= 4'h0;
                   end
               end
               // end on eop
               else begin
                   // rx_valid_crc_pending <= (rx_eop_crc_in==1'b1) ? 1'b0 : rx_valid_crc_pending;
                   if ((rx_eop==1'b1) & (rx_stream_valid0==1'b1))  begin
                       rx_eop_crc_in        <= 1'b1;
                       rx_valid_crc_pending <= 1'b0;
                       case (ctrlrx_cnt_len_dw)
                           10'h1:   rx_empty <= 4'hc;
                           10'h2:   rx_empty <= 4'h8;
                           10'h3:   rx_empty <= 4'h4;
                           default: rx_empty <= 4'h0;
                       endcase
                   end
               end
           end
           else begin
               rx_eop_crc_in <= 1'b0;
               rx_empty      <= 4'h0;
           end


       end


   end


   // rxdata_byte_swap is :
   //     - Set variant bit to 1 The EP field is variant
   //     - Byte swap the data and not the header
   //     - The header is already byte order ready for the CRC (lower byte first) such as :
   //                     | H0 byte 0,1,2,3
   //       rxdata[127:0] | H1 byte 4,5,6,7
   //                     | H2 byte 8,9,10,11
   //                     | H3 byte 12,13,14,15
   //     - The Data requires byte swaping
   //       rxdata
   //
   always @(posedge clk_in) begin
    if (rx_stream_valid0==1'b1) begin
      if (ctrlrx_3dw_aligned==1'b1) begin
         if (rx_sop==1'b1) begin
            rxdata_crc_reg[127:121] <= rxdata[127:121];
            rxdata_crc_reg[120]   <= 1'b1;
            rxdata_crc_reg[119:111] <= rxdata[119:111];
            rxdata_crc_reg[110]   <= 1'b1;
            rxdata_crc_reg[109:0] <= rxdata[109:0];
         end
         else
            rxdata_crc_reg[127:0] <= {
               rxdata[71:64 ], rxdata[79 : 72], rxdata[87 : 80], rxdata[95 : 88],   //D1
               rxdata[39:32 ], rxdata[47 : 40], rxdata[55 : 48], rxdata[63 : 56],   // D2
               rxdata[7:0   ], rxdata[15 :  8], rxdata[23 : 16], rxdata[31 : 24],   // D3
               rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120]};  // D0
      end
      else if (ctrlrx_4dw_non_aligned==1'b1) begin
         if (rx_sop==1'b1) begin
            rxdata_crc_reg[127:121] <= rxdata[127:121];
            rxdata_crc_reg[120]     <= 1'b1;
            rxdata_crc_reg[119:111] <= rxdata[119:111];
            rxdata_crc_reg[110]     <= 1'b1;
            rxdata_crc_reg[109:0]   <= rxdata[109:0];
         end
         else begin
            rxdata_crc_reg[127:0] <= {
               rxdata[71:64 ], rxdata[79 : 72], rxdata[87 : 80], rxdata[95 : 88],   //D1
               rxdata[39:32 ], rxdata[47 : 40], rxdata[55 : 48], rxdata[63 : 56],   // D2
               rxdata[7:0   ], rxdata[15 :  8], rxdata[23 : 16], rxdata[31 : 24],   // D3
               rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120]};  // D0
         end
      end
      else if (ctrlrx_4dw_aligned==1'b1) begin
         if (rx_sop==1'b1) begin
            rxdata_crc_reg[127:121] <= rxdata[127:121];
            rxdata_crc_reg[120]     <= 1'b1;
            rxdata_crc_reg[119:111] <= rxdata[119:111];
            rxdata_crc_reg[110]     <= 1'b1;
            rxdata_crc_reg[109:0]   <= rxdata[109:0];
         end
         else begin
            rxdata_crc_reg[127:0] <= {
               rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120],    // D0
               rxdata[71:64 ], rxdata[79 : 72], rxdata[87 : 80], rxdata[95 : 88],   //D1
               rxdata[39:32 ], rxdata[47 : 40], rxdata[55 : 48], rxdata[63 : 56],   // D2
               rxdata[7:0   ], rxdata[15 :  8], rxdata[23 : 16], rxdata[31 : 24]   // D3
               };
         end
      end
      else                              // 3DW nonaligned
         if (rx_sop==1'b1) begin
            rxdata_crc_reg[127:121] <= rxdata[127:121];
            rxdata_crc_reg[120]     <= 1'b1;
            rxdata_crc_reg[119:111] <= rxdata[119:111];
            rxdata_crc_reg[110]     <= 1'b1;
            rxdata_crc_reg[109:32]  <= rxdata[109:32];
            if (ctrlrx_3dw==1'b1) begin
            // 3 DWORD Header with payload byte swapping the first data D0
               rxdata_crc_reg[31:24] <= rxdata[7:0];
               rxdata_crc_reg[23:16] <= rxdata[15:8];
               rxdata_crc_reg[15:8]  <= rxdata[23:16];
               rxdata_crc_reg[7:0]   <= rxdata[31:24];
            end
            else
            // 4 DWORD Header no need to swap bytes
               rxdata_crc_reg[31:0]   <= rxdata[31:0];
         end
         else
            rxdata_crc_reg[127:0] <= {
               rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120],
               rxdata[71 :64], rxdata[79 :72 ], rxdata[87 :80 ], rxdata[95 : 88],
               rxdata[39 :32], rxdata[47 :40 ], rxdata[55 :48 ], rxdata[63 : 56],
               rxdata[7  :0 ], rxdata[15 : 8 ], rxdata[23 :16 ], rxdata[31 : 24]};
    end
   end


   assign rxdata_crc_in[127:0] = (ctrlrx_3dw_aligned_reg==1'b1) ?   {rxdata_crc_reg[127:32],     // previous 3DW
                                                                            rxdata[103:96 ],     // current DW (byte flipped)
                                                                            rxdata[111:104],
                                                                            rxdata[119:112],
                                                                            rxdata[127:120]} :
                                 ((ctrlrx_4dw_non_aligned_reg==1'b1) & (rx_sop_crc_in==1'b0)) ? {rxdata_crc_reg[127:32],     // previous 3DW
                                                                                                       rxdata[103:96 ],     // current DW (byte flipped)
                                                                                                       rxdata[111:104],
                                                                                                       rxdata[119:112],
                                                                                                       rxdata[127:120]} : rxdata_crc_reg[127:0];



   //////////////////////////////////////////////////////////////////////////
   //
   // BAD ECRC Counter output (ecrc_bad_cnt
   //
   always @(posedge clk_in) begin
      if (srst==1'b1) begin
         rx_ecrc_check_valid <= 1'b1;
         ecrc_bad_cnt        <= 0;
      end
      else if ((crcvalid==1'b1) && (crcbad==1'b1)) begin
         if (ecrc_bad_cnt<16'hFFFF)
            ecrc_bad_cnt <= ecrc_bad_cnt+1;
         if (rx_ecrc_check_valid==1'b1)
            rx_ecrc_check_valid <= 1'b0;
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   //
   // Misc. Avalon-ST control signals
   //
   assign rx_sop = ((rxdata[139]==1'b1) && (rx_stream_valid0==1'b1))?1'b1:1'b0;
   assign rx_eop = ((rxdata[136]==1'b1) && (rx_stream_valid0==1'b1))?1'b1:1'b0;



   always @(posedge clk_in) begin
      if (srst==1'b1) begin
         ctrlrx_3dw_reg           <=1'b0;
         ctrlrx_qword_aligned_reg <=1'b0;
         ctrlrx_digest_reg        <=1'b0;
         ctrlrx_single_cycle_reg  <= 1'b0;
         ctrlrx_payload_reg       <=1'b0;
      end
      else  begin
         ctrlrx_3dw_reg           <=ctrlrx_3dw;
         ctrlrx_qword_aligned_reg <= ctrlrx_qword_aligned;
         ctrlrx_digest_reg        <=ctrlrx_digest;
         ctrlrx_single_cycle_reg  <= ctrlrx_single_cycle;
         ctrlrx_payload_reg       <= ctrlrx_payload;
      end
   end

   assign ctrlrx_single_cycle = (rx_sop==1'b1) ? ((rx_eop==1'b1) ? 1'b1 : 1'b0) : ctrlrx_single_cycle_reg;

   // ctrlrx_payload is set when the TLP has payload
   assign ctrlrx_payload = (rx_sop==1'b1) ? ( (rxdata[126]==1'b1) ? 1'b1 : 1'b0) : ctrlrx_payload_reg;

   // ctrlrx_3dw is set when the TLP has 3 DWORD header
   assign ctrlrx_3dw = (rx_sop==1'b1) ? ((rxdata[125]==1'b0) ? 1'b1 : 1'b0) : ctrlrx_3dw_reg;

   // ctrlrx_qword_aligned is set when the data are address aligned

   assign ctrlrx_qword_aligned = (rx_sop==1'b1)? ((
                                ((ctrlrx_3dw==1'b1) && (rxdata[34:32]==0)) ||
                                ((ctrlrx_3dw==1'b0) && (rxdata[2:0]==0))  ) ? 1'b1: 1'b0 ) :
                                ctrlrx_qword_aligned_reg;


   assign ctrlrx_digest = (rx_sop==1'b1) ? rxdata[111]:ctrlrx_digest_reg;

   assign ctrlrx_3dw_aligned = ((ctrlrx_3dw==1'b1) && (ctrlrx_qword_aligned==1'b1))?1'b1:1'b0;

   assign ctrlrx_3dw_nonaligned = ((ctrlrx_3dw==1'b1) &&
                                    (ctrlrx_qword_aligned==1'b0))?1'b1:1'b0;

   assign ctrlrx_4dw_non_aligned = ((ctrlrx_3dw==1'b0) && (ctrlrx_qword_aligned==1'b0))?1'b1:1'b0;

   assign ctrlrx_4dw_aligned = ((ctrlrx_3dw==1'b0) && (ctrlrx_qword_aligned==1'b1))?1'b1:1'b0;

   always @(posedge clk_in) begin
   // ctrlrx_cnt_len_dw counts the number remaining
   // number of DWORD in rxdata_crc_reg
      ctrlrx_cnt_len_dw_reg <= (rx_stream_valid0) ? ctrlrx_cnt_len_dw : ctrlrx_cnt_len_dw_reg;
      if (srst==1'b1)
         ctrlrx_cnt_len_dw <= 0;
      else if (rx_sop==1'b1) begin
         single_crc_cyc <= 1'b0;  // default
         if (rxdata[126]==1'b0) begin                 // No payload
            if (ctrlrx_3dw==1'b1) begin
                ctrlrx_cnt_len_dw <= 0;               // 1DW ECRC, subtract 1 since ECRC is packed with descriptor.
                single_crc_cyc <= 1'b1;
            end
            else
                ctrlrx_cnt_len_dw <= 1;
         end
         else if (ctrlrx_3dw==1'b0)
            ctrlrx_cnt_len_dw <= rxdata[105:96] + 1;  //  Add ECRC field.
         else
            ctrlrx_cnt_len_dw <= rxdata[105:96];      //  Add ECRC field.
      end
      else if (rx_stream_valid0) begin
          if (ctrlrx_cnt_len_dw>3)
             ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-4;
          else if (ctrlrx_cnt_len_dw>2)
             ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-3;
          else if (ctrlrx_cnt_len_dw>1)
             ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-2;
          else if (ctrlrx_cnt_len_dw>0)
             ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-1;
      end
   end



   // for internal monitoring
   assign crc_32 = (rx_eop_crc_in==1'b0)?0:
                     (ctrlrx_cnt_len_dw_reg[1:0]==0)? rxdata_crc_in[127:96]:
                     (ctrlrx_cnt_len_dw_reg[1:0]==1)? rxdata_crc_in[95:64]:
                     (ctrlrx_cnt_len_dw_reg[1:0]==2)? rxdata_crc_in[63:32]:
                     rxdata_crc_in[31:0];

endmodule
