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
module altpcierd_cdma_ast_rx # (
   parameter TL_SELECTION= 0
   )(
   input clk_in,
   input rstn,

   input[81:0]       rx_stream_data0,
   input             rx_stream_valid0,
   output            reg rx_stream_ready0,

   input              rx_ack0  ,
   input              rx_ws0   ,
   output reg         rx_req0  ,
   output reg [135:0] rx_desc0 ,
   output reg [63:0]  rx_data0 ,
   output reg         rx_dv0   ,
   output reg         rx_dfr0  ,
   output reg [7:0]   rx_be0 ,
   output     [15:0] ecrc_bad_cnt
   );

   wire      rx_sop;
   reg [2:0] rx_sop_reg;
   wire      rx_eop;
   reg [2:0] rx_eop_reg;
   wire      rx_eop_done;
   reg       rx_eop_2dw;
   reg       rx_eop_2dw_reg;
   reg       has_payload;
   reg       dw3_desc_w_payload;
   wire      qword_aligned;
   reg       qword_aligned_reg;
   reg [63:0]rx_data0_3dwna ;
   reg      srst ;

//   always @(posedge clk_in) begin
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==0)
         srst <= 1'b1;
      else
         srst <=1'b0;
   end
   assign ecrc_bad_cnt =0;

   //------------------------------------------------------------
   //    Avalon ST Control signals
   //------------------------------------------------------------
   // SOP
   assign rx_sop = ((rx_stream_data0[73]==1'b1) &&
                     (rx_stream_valid0==1'b1))?1'b1:1'b0;
   always @(posedge clk_in) begin
      if (TL_SELECTION==0) begin
         if (rx_stream_valid0==1'b1) begin
            rx_sop_reg[0] <= rx_sop;
            rx_sop_reg[1] <= rx_sop_reg[0];
         end
         if ((rx_stream_valid0==1'b1)||(rx_eop_reg[0]==1'b1))
            rx_sop_reg[2] <= rx_sop_reg[1];
      end
      else begin
         if (rx_stream_valid0==1'b1) begin
            rx_sop_reg[0] <= rx_sop;
         end
         if ((rx_stream_valid0==1'b1)||(rx_eop_reg[0]==1'b1))
            rx_sop_reg[2] <= rx_sop_reg[1];
         if (rx_stream_valid0==1'b1)
            rx_sop_reg[1] <= rx_sop_reg[0];
         else if (rx_eop_2dw==1'b1)
            rx_sop_reg[1] <= 1'b0;
      end
   end

   // EOP
   assign rx_eop = ((rx_stream_data0[72]==1'b1) &&
                     (rx_stream_valid0==1'b1))?1'b1:1'b0;
   assign rx_eop_done = ((rx_stream_data0[72]==1'b0) &&
                        (rx_eop_reg[0]==1'b1)) ? 1'b1:1'b0;

   always @(posedge clk_in) begin
      rx_eop_reg[0] <= rx_eop;
      rx_eop_reg[1] <= rx_eop_reg[0];
      rx_eop_reg[2] <= rx_eop_reg[1];
   end

   always @(posedge clk_in) begin
      if (TL_SELECTION==0)
         rx_eop_2dw <=1'b0;
      else if ((rx_sop_reg[0]==1'b1) && (rx_eop==1'b1))
         rx_eop_2dw <=1'b1;
      else
         rx_eop_2dw <=1'b0;
   end

   always @(posedge clk_in) begin
       rx_eop_2dw_reg <=rx_eop_2dw;
   end

   // Payload
   always @(negedge rstn or posedge clk_in) begin
      if (rstn == 1'b0)
         has_payload <=1'b0;
      else if (rx_stream_data0[73]==1'b1) begin
         if (TL_SELECTION==0)
            has_payload <= rx_stream_data0[62];
         else
            has_payload <= rx_stream_data0[30];
      end
      else if (rx_eop_done==1'b1)
         has_payload <= 1'b0;
   end

   always @(posedge clk_in) begin
      if (TL_SELECTION==0) //TODO Update dw3_desc_w_payload for desc/data interface
         dw3_desc_w_payload <=1'b0;
      else if (rx_sop_reg[0]==1'b1)  begin
         if ((rx_stream_data0[30]==1'b1) &&
                (rx_stream_data0[29]==1'b0) )
            dw3_desc_w_payload <= 1'b1;
         else
            dw3_desc_w_payload <= 1'b0;
      end
   end

   assign qword_aligned = ((rx_sop_reg[0]==1'b1)  &&
                             (rx_stream_data0[2:0]==0))?1'b1:qword_aligned_reg;

   always @(posedge clk_in) begin
      if (TL_SELECTION==0)//TODO Update qword_aligned_reg for desc/data interface
         qword_aligned_reg <= 1'b0;
      else if (srst==1'b1)
         qword_aligned_reg <= 1'b0;
      else if (rx_sop_reg[0]==1'b1) begin
         if (rx_stream_data0[2:0]==0)
            qword_aligned_reg <=1'b1;
         else
            qword_aligned_reg <=1'b0;
      end
      else if (rx_eop==1'b1)
         qword_aligned_reg <= 1'b0;
   end

   // TODO if no rx_ack de-assert rx_stream_ready0 on cycle rx_sop_reg
   always @(posedge clk_in) begin
      if (TL_SELECTION==0)
         rx_stream_ready0 <= ~rx_ws0;
      else begin
         if (rx_ws0==1'b1)
            rx_stream_ready0 <= 1'b0;
         else if ((rx_sop==1'b1)&&(rx_stream_data0[9:0]<3))
            rx_stream_ready0 <= 1'b0;
         else
            rx_stream_ready0 <= 1'b1;
      end
   end

   //------------------------------------------------------------
   //    Constructing Descriptor  && rx_req
   //------------------------------------------------------------

   always @(posedge clk_in) begin
      if (srst == 1'b1)
         rx_req0 <= 1'b0;
      else begin
         if ((rx_sop_reg[0]==1'b1)&&(rx_stream_valid0==1'b1))
            rx_req0 <= 1'b1;
         else if (TL_SELECTION==0) begin
            if (rx_sop_reg[2]==1'b1)
               rx_req0 <= 1'b0;
         end
         else begin
            if (rx_ack0==1'b1)
               rx_req0 <=1'b0;
         end
      end
   end

   always @(posedge clk_in) begin
      if (rx_sop==1'b1) begin
         if (TL_SELECTION==0)
            rx_desc0[127:64]  <= rx_stream_data0[63:0];
         else
            rx_desc0[127:64]  <= {rx_stream_data0[31:0],rx_stream_data0[63:32]};
       end
   end

   always @(posedge clk_in) begin
      if (rx_sop_reg[0]==1'b1) begin
         rx_desc0[135:128] <= rx_stream_data0[71:64];
         if (TL_SELECTION==0)
            rx_desc0[63:0] <= rx_stream_data0[63:0];
         else begin
            rx_desc0[63:0] <= {rx_stream_data0[31:0], rx_stream_data0[63:32]};
         end
      end
   end



   //------------------------------------------------------------
   //    Constructing Data, rx_dv, rx_dfr
   //------------------------------------------------------------

   always @(posedge clk_in) begin
      rx_data0_3dwna[63:0]  <= rx_stream_data0[63:0];
   end

   always @(posedge clk_in) begin
      if (TL_SELECTION==0) begin
         rx_data0[63:0]  <= rx_stream_data0[63:0];
         rx_be0          <= rx_stream_data0[81:74];
      end
      else begin
         if ((dw3_desc_w_payload==1'b1)&&(qword_aligned==1'b0))
            rx_data0[63:0]  <= rx_data0_3dwna[63:0];
          else
            rx_data0[63:0]  <= rx_stream_data0[63:0];
      end
   end

   always @(posedge clk_in) begin
      if (srst==1'b1)
         rx_dv0 <=1'b0;
      else if ((rx_sop_reg[1]==1'b1)&&(has_payload==1'b1) &&
                 ((rx_stream_valid0==1'b1)||(rx_eop_2dw==1'b1)))
         rx_dv0  <= 1'b1;
      else if ((rx_eop_reg[0] ==1'b1)&&(rx_eop_2dw==1'b0))
         rx_dv0  <= 1'b0;
      else if (rx_eop_2dw_reg==1'b1)
         rx_dv0  <= 1'b0;
    end

   always @(posedge clk_in) begin
      if (srst==1'b1)
         rx_dfr0 <=1'b0;
      else if ((rx_sop_reg[0]==1'b1)&&(has_payload==1'b1)&&
                       (rx_stream_valid0==1'b1))
         rx_dfr0 <= 1'b1;
      else if ((rx_eop==1'b1) || (rx_eop_2dw==1'b1))
         rx_dfr0 <= 1'b0;
   end

endmodule
