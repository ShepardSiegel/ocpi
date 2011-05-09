// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It could be used by the software
//  * application (Root Port) to retrieve the DMA Performance counter values
//  * and performs single DWORD read and write to the Endpoint memory by
//  * bypassing the DMA engines.
//  */
// synthesis translate_off

`timescale 1ns / 1ps
// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030
//
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


module altpcierd_cdma_ecrc_gen_calc #( parameter AVALON_ST_128 = 0) (clk, rstn,  crc_data, crc_valid, crc_empty, crc_eop, crc_sop,
                ecrc,   crc_ack);

   input        clk;
   input        rstn;
   input[127:0]  crc_data;
   input        crc_valid;
   input[3:0]   crc_empty;
   input        crc_eop;
   input        crc_sop;
   output[31:0] ecrc;
   input        crc_ack;

   wire[31:0]   crc_int;
   wire         crc_valid_int;
   wire         open_empty;
   wire         open_full;


   generate  begin
      if (AVALON_ST_128==1)  begin
         altpcierd_tx_ecrc_128 tx_ecrc_128 (
               .clk(clk), .reset_n(rstn), .data(crc_data), .datavalid(crc_valid),
               .empty(crc_empty), .endofpacket(crc_eop), .startofpacket(crc_sop),
               .checksum(crc_int), .crcvalid(crc_valid_int)
         );
       end
    end
   endgenerate

   generate  begin
      if (AVALON_ST_128==0)  begin
         altpcierd_tx_ecrc_64 tx_ecrc_64 (
               .clk(clk), .reset_n(rstn), .data(crc_data[127:64]), .datavalid(crc_valid),
               .empty(crc_empty[2:0]), .endofpacket(crc_eop), .startofpacket(crc_sop),
               .checksum(crc_int), .crcvalid(crc_valid_int)
         );
       end
    end
   endgenerate

   altpcierd_tx_ecrc_fifo tx_ecrc_fifo (
    .aclr   (~rstn),
    .clock  (clk),
    .data   (crc_int),
    .rdreq  (crc_ack),
    .wrreq  (crc_valid_int),
    .empty  (open_empty),
    .full   (open_full),
    .q      (ecrc)
   );

endmodule

