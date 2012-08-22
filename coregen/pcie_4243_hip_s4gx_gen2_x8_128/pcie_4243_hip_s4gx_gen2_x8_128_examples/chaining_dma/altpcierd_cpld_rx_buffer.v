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
// File          : altpcierd_cpld_rx_buffer.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module monitors the rxbuffer space for read completion and calculate the number
// of allocated/freed credit for header and data.
//  Parameters
//       MAX_NUMTAG        : Specify the maximum number of TAGs
//       CPLD_64K_BOUNDARY : When 1 , assume that the RP system issues completion limited
//                           to 64 byte length
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
module altpcierd_cpld_rx_buffer # (
                           parameter MAX_NUMTAG= 32,
                           parameter CHECK_RX_BUFFER_CPL= 1,
                           parameter CPLD_64K_BOUNDARY= 1
                           )(
                           input          clk_in,
                           input          srst,

                           input          rx_ack0 ,
                           input          rx_req0  ,
                           input  [135:0] rx_desc0,

                           input          tx_req0 ,
                           input          tx_ack0 ,
                           input [127:0]  tx_desc0,

                           input [19:0] ko_cpl_spc_vc0,
                           output reg  [15:0] rx_buffer_cpl_max_dw,  // specifies the maximum amount of data available in RX Buffer for a given MRd
                           output reg cpld_rx_buffer_ready);

   localparam TAGRAM_WIDTH_ADDR  = (MAX_NUMTAG<3  )?1:
                                 (MAX_NUMTAG<5  )?2:
                                 (MAX_NUMTAG<9  )?3:
                                 (MAX_NUMTAG<17 )?4:
                                 (MAX_NUMTAG<33 )?5:
                                 (MAX_NUMTAG<65 )?6:
                                 (MAX_NUMTAG<129)?7:8;
   localparam MAX_RAM_NUMWORDS = (1<<TAGRAM_WIDTH_ADDR);
   localparam TAGRAM_WIDTH = 10;
   localparam MAX_HEADER_CREDIT_PER_MRD = 4;

   wire cst_one;
   wire cst_zero;
   wire [63:0] cst_std_logic_vector_type_one;

   reg  tagram_wren_a                      ;
   reg [TAGRAM_WIDTH-1:0] tagram_data_a  ;
   reg [TAGRAM_WIDTH_ADDR-1:0] tagram_address_a;

   wire  tagram_wren_b                      ;
   wire [TAGRAM_WIDTH-1:0] tagram_data_b  ;
   reg [TAGRAM_WIDTH_ADDR-1:0] tagram_address_b;
   wire [TAGRAM_WIDTH-1:0] tagram_q_b     ;

   reg [7:0] estimated_header_credits;
   reg [7:0] lim_cplh_cred;
   reg [7:0] tx_mrd_header_credit;
   reg [7:0] rx_cpl_header_credit;

   reg [13:0] estimated_data_credits;
   reg [13:0] lim_cpld_cred;
   reg [13:0] tx_mrd_data_credit;
   reg [13:0] rx_cpl_data_credit;

   reg [7:0] estimated_header_credits_64;
   wire [15:0] estimated_rx_buffer_cpl_header_max_dw;
   wire [15:0] estimated_rx_buffer_cpl_data_max_dw;

   reg [7:0]  tx_tag;
   reg [9:0]  tx_length_dw;
   reg [6:0]  tx_fmt_type;

   reg  [7:0]  rx_tag;
   reg  [9:0]  rx_length_dw;
   wire [11:0] rx_length_dw_byte;
   reg  [11:0] rx_byte_count;
   reg  [6:0]  rx_fmt_type;
   reg  [4:0]  read_tagram;
   reg rx_ack_reg;

   assign cst_one  = 1'b1;
   assign cst_zero = 1'b0;
   assign cst_std_logic_vector_type_one[0]=1'b1;

   // TX
   always @ (posedge clk_in) begin
      if (tx_req0==1'b1)
         tx_fmt_type <= tx_desc0[126:120];
   end

   always @ (posedge clk_in) begin
      if (tx_req0==1'b1)
         tx_tag <= tx_desc0[79:72];
   end

   always @ (posedge clk_in) begin
      if (tx_req0==1'b1)
         tx_length_dw <= tx_desc0[105:96];
   end


   //RX
   always @ (posedge clk_in) begin
      if (rx_ack0==1'b1)
         rx_fmt_type <= rx_desc0[126:120];
   end

   always @ (posedge clk_in) begin
      if (rx_ack0==1'b1)
         rx_tag <= rx_desc0[47:40];
   end

   always @ (posedge clk_in) begin
      if (rx_ack0==1'b1)
         rx_length_dw <= rx_desc0[105:96];
   end

   assign rx_length_dw_byte[1:0] = 2'b00;
   assign rx_length_dw_byte[11:2] = rx_length_dw[9:0];

   always @ (posedge clk_in) begin
      rx_ack_reg <= rx_ack0;
   end

   always @ (posedge clk_in) begin
      if (rx_ack0==1'b1)
         rx_byte_count <= rx_desc0[75:64];
   end

   always @ (posedge clk_in) begin
      if ((srst==1'b1)||(ko_cpl_spc_vc0 == 20'hF_FFFF)||(CHECK_RX_BUFFER_CPL==0))
         cpld_rx_buffer_ready <=1'b1;
      else if (estimated_header_credits ==0)
         cpld_rx_buffer_ready <=1'b0;
      else if (estimated_data_credits ==0)
         cpld_rx_buffer_ready <=1'b0;
      else if ((tagram_wren_a==1'b1) && (read_tagram[4] ==1'b0)&&(
                (estimated_header_credits<=tx_mrd_header_credit) ||
                (estimated_data_credits <= tx_mrd_data_credit)))
         cpld_rx_buffer_ready <=1'b0;
      else
         cpld_rx_buffer_ready <=1'b1;
   end

  /////////////////////////////////////////////////////////////////////////////////////////
  // Update available rx buffer header credit counter (estimated_header_credits)
  // When transmitting MRd, assume worst case that it consumes 4 credit in RX Buffer

   always @ (posedge clk_in) begin
      if (CPLD_64K_BOUNDARY==0)
         lim_cplh_cred <= ko_cpl_spc_vc0-2;
      else if (read_tagram[3]==1'b1) begin
         if (ko_cpl_spc_vc0>rx_cpl_header_credit)
            lim_cplh_cred[7:0]  <= ko_cpl_spc_vc0[7:0]-rx_cpl_header_credit;
         else
            lim_cplh_cred[7:0]  <=1;
      end
   end

   always @ (posedge clk_in) begin
   // Compute the number of freed header credit (rx_cpl_header_credit)
   // required when tx issues MRD
   // divide by 16 DWORDs (or 64 bytes) and add 1 for potential 4k completion boundary
      if (CPLD_64K_BOUNDARY==1) begin
         if (read_tagram[2]==1'b1)
            rx_cpl_header_credit[7:0] <= {2'b00,tagram_q_b[9:4]} +1;
      end
      else
         rx_cpl_header_credit[7:0] <= 2;
   end

   always @ (posedge clk_in) begin
   // Compute the number of allocated header credit (tx_mrd_header_credit)
   // required when tx issues MRD
   // divide by 16 DWORDs (or 64 bytes) and add 1 for potential 4k completion boundary
      if (CPLD_64K_BOUNDARY==1)
         tx_mrd_header_credit[7:0] <= {2'b00,tx_length_dw[9:4]} +1;
      else
         tx_mrd_header_credit[7:0] <= 2;
   end

   always @ (posedge clk_in) begin
      if (srst==1'b1)
          estimated_header_credits[7:0]  <= ko_cpl_spc_vc0[7:0] ;
      else if ((tagram_wren_a==1'b1) && (read_tagram[4] ==1'b0)) begin
         if (estimated_header_credits<=tx_mrd_header_credit)
            estimated_header_credits <= 0;
         else
            estimated_header_credits <= estimated_header_credits-tx_mrd_header_credit;
      end
      else if ((read_tagram[4] == 1'b1) && (tagram_wren_a==1'b0)) begin
         if (estimated_header_credits>lim_cplh_cred)
            estimated_header_credits <= ko_cpl_spc_vc0[7:0];
         else
            estimated_header_credits <= estimated_header_credits+rx_cpl_header_credit;
      end
      else if ((read_tagram[4] == 1'b1) && (tagram_wren_a==1'b1)) begin
      //TODO corner case when simultaneous RX TX
      end
   end

   always @ (posedge clk_in) begin
      if (estimated_header_credits>0)
         estimated_header_credits_64 <= estimated_header_credits-1;
      else
         estimated_header_credits_64 <= 0;
   end
   assign estimated_rx_buffer_cpl_header_max_dw[3:0]  = 0;
   assign estimated_rx_buffer_cpl_header_max_dw[11:4] = estimated_header_credits_64[7:0];
   assign estimated_rx_buffer_cpl_header_max_dw[15:12]  = 0;

   always @ (posedge clk_in) begin
      if (CHECK_RX_BUFFER_CPL==0)
         rx_buffer_cpl_max_dw <= 16'hFFFF;
      else if (estimated_rx_buffer_cpl_data_max_dw>estimated_rx_buffer_cpl_header_max_dw)
         rx_buffer_cpl_max_dw <= estimated_rx_buffer_cpl_header_max_dw;
      else
         rx_buffer_cpl_max_dw <= estimated_rx_buffer_cpl_data_max_dw;
   end

  /////////////////////////////////////////////////////////////////////////////////////////
  // Update available RX Buffer credit for data counter (estimated_data_credits)
  // When transmitting MRd, assume worst case that it consumes 4 credit in RX Buffer

   always @ (posedge clk_in) begin
   // Compute the number of allocated data credit (tx_mrd_header_credit)
   // required when tx issues MRD
   // take the tx_length in DWORD and divide by 4 and ceiled
      if (tx_length_dw[1:0]==0)
         tx_mrd_data_credit[13:0] <= {6'h00, tx_length_dw[9:2]};
      else
         tx_mrd_data_credit[13:0] <= {6'h00, tx_length_dw[9:2]}+1;
   end

   always @ (posedge clk_in) begin
   // Compute the number of freed header credit (rx_cpl_header_credit)
   // required when tx issues MRD
   // divide by 16 DWORDs (or 64 bytes) and add 1 for potential 4k completion boundary
      if (read_tagram[2]==1'b1) begin
         if (tagram_q_b[1:0]==0)
            rx_cpl_data_credit[13:0]<={6'h00,tagram_q_b[9:2]};
         else
            rx_cpl_data_credit[13:0]<={6'h00,tagram_q_b[9:2]} +1;
      end
   end

   always @ (posedge clk_in) begin
      if (read_tagram[3]==1'b1) begin
         lim_cpld_cred[13:0]  <= ko_cpl_spc_vc0[19:8]-rx_cpl_data_credit;
      end
   end

   always @ (posedge clk_in) begin
      if (srst==1'b1)
          estimated_data_credits[13:0]  <= ko_cpl_spc_vc0[19:8] ;
      else if ((tagram_wren_a==1'b1) && (read_tagram[4] ==1'b0)) begin
         if (estimated_data_credits<=tx_mrd_data_credit)
            estimated_data_credits <= 0;
         else
            estimated_data_credits <= estimated_data_credits-tx_mrd_data_credit;
      end
      else if ((read_tagram[4] == 1'b1) && (tagram_wren_a==1'b0)) begin
         if (estimated_data_credits>lim_cpld_cred)
            estimated_data_credits <= ko_cpl_spc_vc0[19:8];
         else
            estimated_data_credits <= estimated_data_credits+rx_cpl_data_credit;
      end
      else if ((read_tagram[4] == 1'b1) && (tagram_wren_a==1'b1)) begin
      //TODO corner case when simultaneous RX TX
      end
   end

   assign estimated_rx_buffer_cpl_data_max_dw[1:0] = 2'b00;
   assign estimated_rx_buffer_cpl_data_max_dw[15:2] = estimated_data_credits[13:0];

   generate begin
      if (CHECK_RX_BUFFER_CPL==1) begin

   // The TAG RAM store the number of credit required for a given Mrd
  // It uses converted tx_length in DWORD to credits
      altsyncram # (
         .address_reg_b                      ("CLOCK0"          ),
         .indata_reg_b                       ("CLOCK0"          ),
         .wrcontrol_wraddress_reg_b          ("CLOCK0"          ),
         .intended_device_family             ("Stratix II"      ),
         .lpm_type                           ("altsyncram"      ),
         .numwords_a                         (MAX_RAM_NUMWORDS  ),
         .numwords_b                         (MAX_RAM_NUMWORDS  ),
         .operation_mode                     ("BIDIR_DUAL_PORT" ),
         .outdata_aclr_a                     ("NONE"            ),
         .outdata_aclr_b                     ("NONE"            ),
         .outdata_reg_a                      ("CLOCK0"    ),
         .outdata_reg_b                      ("CLOCK0"    ),
         .power_up_uninitialized             ("FALSE"           ),
         .read_during_write_mode_mixed_ports ("DONT_CARE"        ),
         .widthad_a                          (TAGRAM_WIDTH_ADDR ),
         .widthad_b                          (TAGRAM_WIDTH_ADDR ),
         .width_a                            (TAGRAM_WIDTH      ),
         .width_b                            (TAGRAM_WIDTH      ),
         .width_byteena_a                    (1                 ),
         .width_byteena_b                    (1                 )
      ) rx_buffer_cpl_tagram (
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
      end
      end
   endgenerate

   // TAGRAM port A
   always @ (posedge clk_in) begin
      tagram_address_a[TAGRAM_WIDTH_ADDR-1:0] <= tx_tag[TAGRAM_WIDTH_ADDR-1:0];
      tagram_data_a[TAGRAM_WIDTH-1:0] <= tx_length_dw;
      tagram_wren_a <= ((tx_ack0==1'b1)&&
                           (tx_fmt_type[4:0]==5'b00000)&&
                           (tx_fmt_type[6]==1'b0))?1'b1:1'b0;
   end
   // TAGRAM port B
   always @ (posedge clk_in) begin
      if (srst ==1'b1)
         tagram_address_b[TAGRAM_WIDTH_ADDR-1:0] <= 0;
      else if (rx_ack_reg ==1'b1)
         tagram_address_b[TAGRAM_WIDTH_ADDR-1:0] <= rx_tag[TAGRAM_WIDTH_ADDR-1:0];
   end

   assign tagram_data_b = 0;
   assign tagram_wren_b = 0;


   always @ (posedge clk_in) begin
      if (srst == 1'b1)
         read_tagram[0] <= 1'b0;
      else if ((rx_length_dw_byte >= rx_byte_count) &&
                 (rx_fmt_type[6:1]==6'b100101) && (rx_ack_reg==1'b1))
         read_tagram[0] <=1'b1;
      else
         read_tagram[0]<=1'b0;
   end

   always @ (posedge clk_in) begin
      read_tagram[1] <= read_tagram[0];
      read_tagram[2] <= read_tagram[1];
      read_tagram[3] <= read_tagram[2];
      read_tagram[4] <= read_tagram[3];
   end

endmodule
