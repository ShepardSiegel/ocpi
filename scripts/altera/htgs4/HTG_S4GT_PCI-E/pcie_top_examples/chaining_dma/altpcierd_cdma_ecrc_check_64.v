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
// File          : altpcierd_cdma_ecrc_check_64.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module performs PCIE Ecrc checking on the 64 bit Avalon-ST RX data stream
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
module altpcierd_cdma_ecrc_check_64 (
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
   localparam EOP_BIT   = 138;
   localparam EMPTY_BIT = 137;

   wire rx_sop;
   reg  rx_sop_crc_in;
   reg  rx_sop_last;
   reg  rx_eop_last;

   wire rx_eop;
   reg  rx_eop_reg;
   wire rx_eop_crc_in;

   wire [2:0] rx_empty;
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

   wire ctrlrx_4dw_non_aligned;
   wire ctrlrx_4dw_aligned;
   wire ctrlrx_4dw_nopayload;
   wire ctrlrx_3dw_nopayload;
   wire ctrlrx_3dw_nonaligned;
   reg ctrlrx_4dw_non_aligned_reg;
   reg ctrlrx_4dw_aligned_reg;
   reg ctrlrx_4dw_nopayload_reg;
   reg ctrlrx_3dw_nopayload_reg;
   reg ctrlrx_3dw_nonaligned_reg;

   integer i;

   reg [127:0] rxdata_crc_reg ;
   reg         rx_valid_crc_in ;

   wire [127:0] rxdata_byte_swap ;
   wire [127:0] rxdata_crc_in ;
   reg          rx_sop_crc_in_last;
   reg          rx_eop_crc_in_last;
   reg          rx_valid_crc_pending;

   // xhdl
   wire[31:0]  zeros_32;  assign zeros_32 = 32'h0;
   wire ctrlrx_single_cycle;

   reg [10:0]  rx_payld_remain_dw;
   reg [10:0]  rx_payld_len;
   reg         has_payld;

   reg  debug_ctrlrx_4dw_aligned;
   reg  debug_ctrlrx_4dw_non_aligned;
   reg  debug_ctrlrx_3dw_aligned;
   reg  debug_ctrlrx_3dw_nonaligned;
   reg  debug_ctrlrx_4dw_aligned_nopayld;
   reg  debug_ctrlrx_4dw_non_aligned_nopayld;
   reg  debug_ctrlrx_3dw_aligned_nopayld;
   reg  debug_ctrlrx_3dw_nonaligned_nopayld;

   wire[11:0] zeros12;  assign zeros12 = 12'h0;
   wire[7:0]  zeros8;   assign zeros8  = 8'h0;

   wire[15:0] rxdata_be_15_12;  assign rxdata_be_15_12 = {rxdata_be[15:12], zeros12};
   wire[15:0] rxdata_be_15_8;   assign rxdata_be_15_8  = {rxdata_be[15:8],  zeros8};

   ////////////////////////////////////////////////////////////////////////////
   //
   //  Drop ECRC field from the data stream/rx_be.
   //  Regenerate rx_st_eop.
   //  Set TD bit to 0.
   //

   always @ (posedge clk_in ) begin
       if (srst==1'b1) begin
           rxdata_ecrc           <= 140'h0;
           rxdata_be_ecrc        <= 16'h0;
           rx_payld_remain_dw    <= 11'h0;
           rx_stream_valid0_ecrc <= 1'b0;
           rx_payld_len          <= 11'h0;
           has_payld             <= 1'b0;
       end
       else begin
           rxdata_ecrc[138] <= 1'b0;
           rx_stream_valid0_ecrc <= 1'b0;  // default
           /////////////////////////
           // TLP has Digest
           //
           if (ctrlrx_digest==1'b1) begin
               // 1st phase of descriptor
               if ((rx_sop==1'b1) & (rx_stream_valid0==1'b1)) begin
                   rxdata_ecrc[111]        <= 1'b0;
                   rxdata_ecrc[135:112]    <= rxdata[135:112];
                   rxdata_ecrc[110:0]      <= rxdata[110:0];
                   rxdata_ecrc[SOP_BIT]    <= 1'b1;
                   rxdata_ecrc[EOP_BIT]    <= 1'b0;
                   rxdata_ecrc[EMPTY_BIT]  <= 1'b0;
                   rxdata_be_ecrc          <= rxdata_be;
                   has_payld               <= rxdata[126];
                   if (rxdata[126]==1'b1)
                       rx_payld_len <= (rxdata[105:96] == 0) ? 11'h400 : {1'b0, rxdata[105:96]};  // account for 1024DW
                   else
                       rx_payld_len <= 0;
                   rx_stream_valid0_ecrc   <= 1'b1;
               end
               // 2nd phase of descriptor
               else if ((rx_sop_last==1'b1) & (rx_stream_valid0==1'b1)) begin
                   rxdata_ecrc[127:0]      <= rxdata[127:0];
                   rxdata_ecrc[SOP_BIT]    <= 1'b0;
                   rxdata_ecrc[EOP_BIT]    <= (has_payld==1'b0) | ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0) & (rx_payld_len==1));
                   rxdata_ecrc[EMPTY_BIT]  <= 1'b0;
                   rxdata_be_ecrc          <= rxdata_be;
                   rx_stream_valid0_ecrc   <= 1'b1;
                   // Load the # of payld DWs remaining in next cycles
                   if (has_payld==1'b1) begin    // if there is payload
                       if ((ctrlrx_3dw==1'b1) & (ctrlrx_qword_aligned==1'b0)) begin
                           rx_payld_remain_dw <= rx_payld_len - 1;
                       end
                       else if ((ctrlrx_3dw==1'b0) & (ctrlrx_qword_aligned==1'b0)) begin
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
                   rxdata_ecrc[SOP_BIT]   <= 1'b0;
                   rxdata_ecrc[EMPTY_BIT] <= 1'b0;
                   rxdata_ecrc[127:0]     <= rxdata[127:0];
                   case (rx_payld_remain_dw)
                       11'h1: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_be_ecrc         <= rxdata_be_15_12;
                       end
                       11'h2: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b1;
                           rxdata_be_ecrc         <= rxdata_be_15_8;
                       end
                       default: begin
                           rxdata_ecrc[EOP_BIT]   <= 1'b0;
                           rxdata_be_ecrc         <= rxdata_be[15:0];
                       end
                   endcase
                   rx_stream_valid0_ecrc  <= (rx_payld_remain_dw > 11'h0) ? 1'b1 : 1'b0;

                   // Decrement payld count as payld is received
                   rx_payld_remain_dw <= (rx_payld_remain_dw < 2) ? 11'h0 : rx_payld_remain_dw - 11'h2;
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

/*
   assign rxdata_ecrc    = rxdata_pipeline[PIPELINE_DEPTH-1];
   assign rxdata_be_ecrc = rxdata_be_pipeline[PIPELINE_DEPTH-1];

   always @(posedge clk_in) begin
      rxdata_pipeline[0]    <= rxdata;
      rxdata_be_pipeline[0] <= rxdata_be;
      for(i=1;i <PIPELINE_DEPTH;i=i+1) begin
        rxdata_pipeline[i]    <= rxdata_pipeline[i-1];
        rxdata_be_pipeline[i] <= rxdata_be_pipeline[i-1];
      end
   end

   assign rx_stream_valid0_ecrc = rx_stream_valid_pipeline[PIPELINE_DEPTH-1];
   always @(posedge clk_in) begin
      rx_stream_valid_pipeline[0] <= rx_stream_valid0;
      for(i=1;i <PIPELINE_DEPTH;i=i+1)
         rx_stream_valid_pipeline[i] <= rx_stream_valid_pipeline[i-1];
   end
*/
   ////////////////////////////////////////////////////////////////////////////
   //
   // CRC MegaCore instanciation
   //
   altpcierd_rx_ecrc_64 rx_ecrc_64 (
          .reset_n       (~srst),
          .clk           (clk_in),
          .data          (rxdata_crc_in[127:64]),
         // .datavalid     ( ((rx_sop_crc_in | rx_valid_crc_pending) & rx_stream_valid0) | (rx_valid_crc_pending&rx_eop_crc_in)),
          .datavalid     (ctrlrx_digest_reg & (((rx_sop_crc_in | rx_valid_crc_pending) & rx_stream_valid0) | (rx_valid_crc_pending&rx_eop_crc_in))),
          .startofpacket (rx_sop_crc_in),
          .endofpacket   (rx_eop_crc_in),
          .empty         (rx_empty),
          .crcbad        (crcbad),
          .crcvalid      (crcvalid));

   // Inputs to the MegaCore
   always @(posedge clk_in) begin
      if (ctrlrx_digest ==1'b0)
         rx_valid_crc_in <= 1'b0;
       else if ((rx_sop_crc_in==1'b0) && (rx_sop_crc_in_last==1'b0) && (rx_eop==1'b1) &&
           (ctrlrx_cnt_len_dw_reg<2))         // rxdata is only 1 DW of payld -- CRC appended
         rx_valid_crc_in <= 1'b0;
      else
         rx_valid_crc_in <= rx_stream_valid0;

      if (rx_sop_crc_in & rx_stream_valid0)
          rx_valid_crc_pending <=  1'b1;
      else if (rx_eop_crc_in)
          rx_valid_crc_pending <= 1'b0;

   end


   always @(posedge clk_in) begin
       if (srst==1'b1) begin
           debug_ctrlrx_4dw_aligned      <= 1'b0;
           debug_ctrlrx_4dw_non_aligned  <= 1'b0;
           debug_ctrlrx_3dw_aligned      <= 1'b0;
           debug_ctrlrx_3dw_nonaligned   <= 1'b0;

           debug_ctrlrx_4dw_aligned_nopayld      <= 1'b0;
           debug_ctrlrx_4dw_non_aligned_nopayld  <= 1'b0;
           debug_ctrlrx_3dw_aligned_nopayld      <= 1'b0;
           debug_ctrlrx_3dw_nonaligned_nopayld   <= 1'b0;
       end
       else begin
           if (rx_stream_valid0==1'b1) begin
               debug_ctrlrx_4dw_aligned      <= (rx_sop==1'b1) ? ctrlrx_4dw_aligned     : debug_ctrlrx_4dw_aligned;
               debug_ctrlrx_4dw_non_aligned  <= (rx_sop==1'b1) ? ctrlrx_4dw_non_aligned : debug_ctrlrx_4dw_non_aligned;
               debug_ctrlrx_3dw_aligned      <= (rx_sop==1'b1) ? ctrlrx_3dw_aligned     : debug_ctrlrx_3dw_aligned;
               debug_ctrlrx_3dw_nonaligned   <= (rx_sop==1'b1) ? ctrlrx_3dw_nonaligned  : debug_ctrlrx_3dw_nonaligned;

               debug_ctrlrx_4dw_aligned_nopayld       <= ((rx_sop==1'b1) & (rxdata[126]==1'b0)) ? ctrlrx_4dw_aligned     : debug_ctrlrx_4dw_aligned_nopayld ;
               debug_ctrlrx_4dw_non_aligned_nopayld   <= ((rx_sop==1'b1) & (rxdata[126]==1'b0)) ? ctrlrx_4dw_non_aligned : debug_ctrlrx_4dw_non_aligned_nopayld ;
               debug_ctrlrx_3dw_aligned_nopayld       <= ((rx_sop==1'b1) & (rxdata[126]==1'b0)) ? ctrlrx_3dw_aligned     : debug_ctrlrx_3dw_aligned_nopayld ;
               debug_ctrlrx_3dw_nonaligned_nopayld    <= ((rx_sop==1'b1) & (rxdata[126]==1'b0)) ? ctrlrx_3dw_nonaligned  : debug_ctrlrx_3dw_nonaligned_nopayld ;
           end
       end
   end


   always @(posedge clk_in) begin
       if (srst==1'b1) begin
           rx_sop_crc_in           <=  1'b0;
           rx_sop_crc_in_last      <=  1'b0;
           rx_eop_crc_in_last      <=  1'b0;
           ctrlrx_3dw_aligned_reg  <=  1'b0;
           rx_eop_reg              <= 1'b0;
       end
       else if (rx_stream_valid0) begin
           rx_sop_crc_in           <= rx_sop;
           rx_sop_crc_in_last      <= rx_sop_last;
           rx_eop_crc_in_last      <= rx_eop_crc_in;
           ctrlrx_3dw_aligned_reg  <= ctrlrx_3dw_aligned;
           if ((rx_sop_crc_in==1'b0) && (rx_sop_crc_in_last==1'b0) && (rx_eop==1'b1) &&
                (ctrlrx_cnt_len_dw_reg<2))            // rxdata is only 1 DW of payld -- CRC appended
              rx_eop_reg      <= 1'b0;
           else
              rx_eop_reg      <= rx_eop;
       end
   end

   assign rx_eop_crc_in = (   (rx_sop_crc_in==1'b0)&& (rx_sop_crc_in_last==1'b0) &&
                                (rx_eop==1'b1)&& (rx_stream_valid0==1'b1) &&
                                (ctrlrx_cnt_len_dw_reg<2)) ||
                              ((rx_sop_crc_in_last==1'b1) & (rx_eop==1'b1) & (ctrlrx_3dw_nopayload_reg==1'b1) )?1'b1:rx_eop_reg;

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
      if (srst==1'b1) begin
           rx_sop_last <= rx_sop;
           rx_eop_last <= rx_eop;
      end
      else if (rx_stream_valid0==1'b1) begin
           rx_sop_last <= rx_sop;
           rx_eop_last <= rx_eop;
      end

      //////////////////////////////////////////////////////////
      // Reformat the incoming data so that
      //  - the left-most byte corresponds to the first
      //    byte on the PCIE line.
      //  - 'gaps' between the Avalon-ST desc/data boundaries are removed
      //     so that all bytes going into the CRC checker are contiguous
      //    (e.g. for 3DW aligned, 4DW non-aligned packets).
      //  - EP and Type[0] bits are set to '1' for ECRC calc
      //
      // Headers are already formatted.  Data needs to be byte flipped
      // within each DW.


      if (rx_stream_valid0==1'b1) begin
           if (ctrlrx_3dw_aligned==1'b1) begin           // 3DW aligned
              if (rx_sop==1'b1) begin
                 rxdata_crc_reg[127:121] <= rxdata[127:121];
                 rxdata_crc_reg[120]   <= 1'b1;
                 rxdata_crc_reg[119:111] <= rxdata[119:111];
                 rxdata_crc_reg[110]   <= 1'b1;
                 rxdata_crc_reg[109:0] <= rxdata[109:0];
              end
              else if (rx_sop_last==1'b1) begin
                 rxdata_crc_reg[127:0] <= rxdata[127:0];    // 2nd descriptor phase
              end
              else  begin
                 rxdata_crc_reg[127:0] <= { rxdata[71:64 ], rxdata[79 : 72], rxdata[87 : 80], rxdata[95 : 88],
                                            rxdata[39:32 ], rxdata[47 : 40], rxdata[55 : 48], rxdata[63 : 56],
                                            rxdata[7:0   ], rxdata[15 :  8], rxdata[23 : 16], rxdata[31 : 24],
                                            zeros_32};
              end
           end
           else  if (ctrlrx_3dw_nonaligned==1'b1) begin                   // 3DW non-aligned
              if (rx_sop==1'b1) begin
                 rxdata_crc_reg[127:121] <= rxdata[127:121];
                 rxdata_crc_reg[120]     <= 1'b1;
                 rxdata_crc_reg[119:111] <= rxdata[119:111];
                 rxdata_crc_reg[110]     <= 1'b1;
                 rxdata_crc_reg[109:0]   <= rxdata[109:0];
              end
              else if (rx_sop_last==1'b1) begin                // 2nd descriptor phase
                 rxdata_crc_reg[127:96] <= rxdata[127:96];     // descriptor bits
                 rxdata_crc_reg[95:64]  <= {rxdata[71 :64], rxdata[79 :72 ], rxdata[87 :80 ], rxdata[95 : 88]};  // data bits
              end
              else begin
                 rxdata_crc_reg[127:0] <= { rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120],
                                            rxdata[71 :64], rxdata[79 :72 ], rxdata[87 :80 ], rxdata[95 : 88],
                                            rxdata[39 :32], rxdata[47 :40 ], rxdata[55 :48 ], rxdata[63 : 56],
                                            rxdata[7  :0 ], rxdata[15 : 8 ], rxdata[23 :16 ], rxdata[31 : 24]};
              end
          end
          else if (ctrlrx_4dw_non_aligned == 1'b1) begin // 4DW non-aligned
              if (rx_sop==1'b1) begin
                 rxdata_crc_reg[127:121] <= rxdata[127:121];
                 rxdata_crc_reg[120]     <= 1'b1;
                 rxdata_crc_reg[119:111] <= rxdata[119:111];
                 rxdata_crc_reg[110]     <= 1'b1;
                 rxdata_crc_reg[109:0]   <= rxdata[109:0];
              end
              else if (rx_sop_last==1'b1) begin                       // 2nd descriptor phase
                 rxdata_crc_reg[127:64] <= rxdata[127:64];
              end
              else begin                                              // data phase
                 rxdata_crc_reg[127:0] <= { rxdata[71 :64], rxdata[79 :72 ], rxdata[87 :80 ], rxdata[95 : 88],
                                            rxdata[39 :32], rxdata[47 :40 ], rxdata[55 :48 ], rxdata[63 : 56],
                                            rxdata[7  :0 ], rxdata[15 : 8 ], rxdata[23 :16 ], rxdata[31 : 24],
                                            zeros_32};
              end
          end
          else begin                                                   // 4DW Aligned
              if (rx_sop==1'b1) begin
                 rxdata_crc_reg[127:121] <= rxdata[127:121];
                 rxdata_crc_reg[120]     <= 1'b1;
                 rxdata_crc_reg[119:111] <= rxdata[119:111];
                 rxdata_crc_reg[110]     <= 1'b1;
                 rxdata_crc_reg[109:0]   <= rxdata[109:0];
              end
              else if (rx_sop_last==1'b1) begin                       // 2nd descriptor phase
                 rxdata_crc_reg[127:64] <= rxdata[127:64];
              end
              else begin                                              // data phase
                 rxdata_crc_reg[127:0] <= { rxdata[103:96], rxdata[111:104], rxdata[119:112], rxdata[127:120],
                                            rxdata[71 :64], rxdata[79 :72 ], rxdata[87 :80 ], rxdata[95 : 88],
                                            rxdata[39 :32], rxdata[47 :40 ], rxdata[55 :48 ], rxdata[63 : 56],
                                            rxdata[7  :0 ], rxdata[15 : 8 ], rxdata[23 :16 ], rxdata[31 : 24]};
              end
          end
       end
   end

   assign rxdata_crc_in[127:64] = ((ctrlrx_3dw_nonaligned_reg==1'b1)  || (ctrlrx_4dw_aligned_reg==1'b1) || (rx_sop_crc_in==1'b1) ||
                                   ((rx_sop_crc_in_last==1'b1) & (ctrlrx_4dw_non_aligned_reg==1'b1))  )? rxdata_crc_reg[127:64]:  // SOP, or all data for 3DW non-aligned, 4DW aligned,
                                 {rxdata_crc_reg[127:96],                                                                                                                        // 3DW aligned, 4DW non-aligned
                                  rxdata[103:96 ],
                                  rxdata[111:104],
                                  rxdata[119:112],
                                  rxdata[127:120]};

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
   assign rx_sop = (rx_stream_valid0==1'b1) ? ((rxdata[139]==1'b1)?1'b1:1'b0) : rx_sop_last;
   assign rx_eop = (rx_stream_valid0==1'b1) ? ((rxdata[138]==1'b1)?1'b1:1'b0) : rx_eop_last;
   assign ctrlrx_single_cycle = ((rx_sop==1'b1)&&(rx_eop==1'b1))?1'b1:1'b0;

   // ctrlrx_payload is set when the TLP has payload
   assign ctrlrx_payload = (rx_sop==1'b1)? ( (rxdata[126]==1'b1)?1'b1:1'b0) : ctrlrx_payload_reg;
   always @(posedge clk_in) begin
      if (srst==1'b1)
         ctrlrx_payload_reg <=1'b0;
      else
         ctrlrx_payload_reg <=ctrlrx_payload;
   end

   // ctrlrx_3dw is set when the TLP has 3 DWORD header
   assign ctrlrx_3dw = (rx_sop==1'b1) ? ((rxdata[125]==1'b0) ? 1'b1:1'b0) : ctrlrx_3dw_reg;
   always @(posedge clk_in) begin
      if (srst==1'b1)
         ctrlrx_3dw_reg <= 1'b0;
      else
         ctrlrx_3dw_reg <= ctrlrx_3dw;
   end

   // ctrlrx_qword_aligned is set when the data are address aligned
   assign ctrlrx_qword_aligned = (rx_sop_last==1'b1) ? (( ((ctrlrx_3dw==1'b1) && (rxdata[98]==0)) ||
                                                          ((ctrlrx_3dw==1'b0) && (rxdata[66]==0))) ? 1'b1 : 1'b0) : ctrlrx_qword_aligned_reg;

   always @(posedge clk_in) begin
      if (srst==1'b1)
         ctrlrx_qword_aligned_reg <=1'b0;
      else
         ctrlrx_qword_aligned_reg <= ctrlrx_qword_aligned;
   end

   assign ctrlrx_digest = (rx_sop==1'b1) ? ((rxdata[111]==1'b1)?1'b1:1'b0) : ctrlrx_digest_reg;
   always @(posedge clk_in) begin
      if (srst==1'b1)
         ctrlrx_digest_reg <=1'b0;
      else
         ctrlrx_digest_reg <=ctrlrx_digest;
   end

   assign ctrlrx_3dw_aligned = (//(ctrlrx_payload==1'b1) &&
                                  (ctrlrx_3dw==1'b1) &&
                                    (ctrlrx_qword_aligned==1'b1))?1'b1:1'b0;

   assign ctrlrx_3dw_nonaligned = (//(ctrlrx_payload==1'b1) &&
                                  (ctrlrx_3dw==1'b1) &&
                                    (ctrlrx_qword_aligned==1'b0))?1'b1:1'b0;

   assign ctrlrx_4dw_non_aligned = (//(ctrlrx_payload==1'b1) &&
                                  (ctrlrx_3dw==1'b0) &&
                                    (ctrlrx_qword_aligned==1'b0))?1'b1:1'b0;

   assign ctrlrx_4dw_aligned = (//(ctrlrx_payload==1'b1) &&
                                  (ctrlrx_3dw==1'b0) &&
                                    (ctrlrx_qword_aligned==1'b1))?1'b1:1'b0;

   assign ctrlrx_4dw_nopayload = (ctrlrx_payload==1'b0) && (ctrlrx_3dw==1'b0);

   assign ctrlrx_3dw_nopayload = (ctrlrx_payload==1'b0) && (ctrlrx_3dw==1'b1);


   always @(posedge clk_in) begin
       if (srst==1'b1) begin
           ctrlrx_4dw_non_aligned_reg <= 1'b0;
           ctrlrx_4dw_aligned_reg     <= 1'b0;
           ctrlrx_4dw_nopayload_reg   <= 1'b0;
           ctrlrx_3dw_nopayload_reg   <= 1'b0;
           ctrlrx_3dw_nonaligned_reg  <= 1'b0;
       end
       else if (rx_stream_valid0==1'b1) begin
           ctrlrx_4dw_non_aligned_reg <= ctrlrx_4dw_non_aligned;
           ctrlrx_4dw_aligned_reg     <= ctrlrx_4dw_aligned;
           ctrlrx_4dw_nopayload_reg   <= ctrlrx_4dw_nopayload;
           ctrlrx_3dw_nopayload_reg   <= ctrlrx_3dw_nopayload;
           ctrlrx_3dw_nonaligned_reg  <= ctrlrx_3dw_nonaligned;
       end
   end

   always @(posedge clk_in) begin
   // ctrlrx_cnt_len_dw counts the number remaining
   // number of DWORD in rxdata_crc_reg
      if (rx_stream_valid0==1'b1) begin
          if (ctrlrx_payload==1'b1)
              ctrlrx_cnt_len_dw_reg <= ctrlrx_cnt_len_dw;
          else
              ctrlrx_cnt_len_dw_reg <= 0;                 // no payload
      end

      if (srst==1'b1)
         ctrlrx_cnt_len_dw <= 0;
      else if ((rx_sop==1'b1) & (rx_stream_valid0==1'b1))begin
         if (ctrlrx_3dw==1'b0)
            ctrlrx_cnt_len_dw <= rxdata[105:96];
         else
            ctrlrx_cnt_len_dw <= rxdata[105:96]-1;
      end
      else if ((rx_sop_last==1'b0) & (rx_stream_valid0==1'b1)) begin         // decrement in data phase
         if (ctrlrx_cnt_len_dw>1)
            ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-2;
         else if (ctrlrx_cnt_len_dw>0)
            ctrlrx_cnt_len_dw <= ctrlrx_cnt_len_dw-1;
      end
   end

   assign rx_empty = (rx_eop_crc_in==1'b0)? 0:
                     (ctrlrx_3dw_nopayload_reg==1'b1) ? 3'h0 :               // ECRC appended to 3DW header (3DW dataless)
                     (ctrlrx_cnt_len_dw_reg[1:0]==0)?3'h4:                   // sending ECRC field only (4 bytes)
                     (ctrlrx_cnt_len_dw_reg[1:0]==1)?3'h0:                   // sending 1 DW payld + ECRC (8 bytes)
                     (ctrlrx_cnt_len_dw_reg[1:0]==2)?3'h0:3'h0;              // sending 2 DW (8 bytes) paylod + ECRC (4 bytes)

   // for internal monitoring
   assign crc_32 = (rx_eop_crc_in==1'b0)?0:
                     (ctrlrx_cnt_len_dw_reg[1:0]==0)? rxdata_crc_in[127:96]:
                     (ctrlrx_cnt_len_dw_reg[1:0]==1)? rxdata_crc_in[95:64]:
                     (ctrlrx_cnt_len_dw_reg[1:0]==2)? rxdata_crc_in[63:32]:
                     rxdata_crc_in[31:0];

endmodule
