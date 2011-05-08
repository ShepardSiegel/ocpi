//Copyright (C) 1991-2007 Altera Corporation
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files from any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, Altera MegaCore Function License
//Agreement, or other applicable license agreement, including,
//without limitation, that your use is for the sole purpose of
//programming logic devices manufactured by Altera and sold by
//Altera or its authorized distributors.  Please refer to the
//applicable agreement for further details.

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module altpcierd_icm_fifo_lkahd #(
    parameter RAMTYPE = "RAM_BLOCK_TYPE=M512",
   parameter USEEAB  = "ON",
   parameter ALMOST_FULL = 10,
   parameter NUMWORDS = 16,
   parameter WIDTHU   = 4
   )(
   aclr,
   clock,
   data,
   rdreq,
   wrreq,
   almost_empty,
   almost_full,
   empty,
   full,
   q,
   usedw);

   input   aclr;
   input   clock;
   input [107:0]  data;
   input   rdreq;
   input   wrreq;
   output     almost_empty;
   output     almost_full;
   output     empty;
   output     full;
   output   [107:0]  q;
   output   [WIDTHU-1:0]  usedw;

   wire  sub_wire0;
   wire [WIDTHU-1:0] sub_wire1;
   wire  sub_wire2;
   wire  sub_wire3;
   wire [107:0] sub_wire4;
   wire  sub_wire5;
   wire  almost_full = sub_wire0;
   wire [WIDTHU-1:0] usedw = sub_wire1[WIDTHU-1:0];
   wire  empty = sub_wire2;
   wire  almost_empty = sub_wire3;
   wire [107:0] q = sub_wire4[107:0];
   wire  full = sub_wire5;



   scfifo   # (

      .add_ram_output_register ( "ON"           ),
      .almost_empty_value      ( 3              ),
      .almost_full_value       ( ALMOST_FULL    ),
      .intended_device_family  ( "Stratix II GX"),
      .lpm_hint                ( RAMTYPE        ),
      .lpm_numwords            ( NUMWORDS       ),
      .lpm_showahead           ( "ON"           ),
      .lpm_type                ( "scfifo"       ),
      .lpm_width               ( 108            ),
      .lpm_widthu              ( WIDTHU         ),
      .overflow_checking       ( "OFF"          ),
      .underflow_checking      ( "OFF"          ),
      .use_eab                 ( USEEAB         )

      ) scfifo_component (
            .rdreq (rdreq),
            .aclr (aclr),
            .clock (clock),
            .wrreq (wrreq),
            .data (data),
            .almost_full (sub_wire0),
            .usedw (sub_wire1),
            .empty (sub_wire2),
            .almost_empty (sub_wire3),
            .q (sub_wire4),
            .full (sub_wire5)
            // synopsys translate_off
            ,
            .sclr ()
            // synopsys translate_on
            );


endmodule

