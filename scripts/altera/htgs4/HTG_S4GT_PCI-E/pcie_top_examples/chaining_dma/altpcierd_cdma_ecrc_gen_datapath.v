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


module altpcierd_cdma_ecrc_gen_datapath (clk, rstn, data_in, data_valid, rdreq, data_out, data_out_valid, full);

   input         clk;
   input         rstn;
   input[135:0]  data_in;
   input         data_valid;
   input         rdreq;

   output[135:0] data_out;
   output        data_out_valid;
   output        full;

   wire          empty;
   reg[6:0]      ctl_shift_reg;
   wire          rdreq_int;
   wire          open_data_fifo_empty;
   wire          open_data_fifo_almost_full;
   wire          open_data_fifo_full;
   wire          open_ctl_fifo_full;
   wire          open_ctl_fifo_data;
   wire          data_bit;  assign data_bit = 1'b1;

// lookahead
altpcierd_tx_ecrc_data_fifo tx_ecrc_data_fifo(
    .aclr           (~rstn),
    .clock          (clk),
    .data           (data_in),
    .rdreq          (rdreq_int),
    .wrreq          (data_valid),
    .almost_full    (open_data_fifo_almost_full),
    .empty          (open_data_fifo_empty),
    .full           (open_data_fifo_full),
    .q              (data_out));


 // push data_valid thru a shift register to
 // wait a minimum time before allowing data fifo
 // to be popped.  when shifted data_valid is put
 // into the control fifo, it is okay to pop data
 // fifo whenever avalon ST is ready

 always @ (posedge clk or negedge rstn) begin
     if (rstn==1'b0) begin
         ctl_shift_reg <= 7'h0;
     end
     else begin
         ctl_shift_reg <= {data_valid, ctl_shift_reg[6:1]};   // always shifting.  no throttling because crc module is not throttled.
     end
 end

 assign rdreq_int      = (rdreq==1'b1) & (empty==1'b0);
 assign data_out_valid = (rdreq==1'b1) & (empty==1'b0);

 // this fifo only serves as an up/down counter for number of
 // tx_data_fifo entries which have met the minimum
 // required delay time before being popped
 // lookahead
 altpcierd_tx_ecrc_ctl_fifo tx_ecrc_ctl_fifo (
     .aclr          (~rstn),
     .clock         (clk),
     .data          (data_bit),             // data does not matter
     .rdreq         (rdreq_int),
     .wrreq         (ctl_shift_reg[0]),
     .almost_full   (full),
     .empty         (empty),
     .full          (open_ctl_fifo_full),
     .q             (open_ctl_fifo_data));

endmodule

////////////////////////////////////////////////////////////////////
// Megawizard Generated FIFOs
////////////////////////////////////////////////////////////////////
