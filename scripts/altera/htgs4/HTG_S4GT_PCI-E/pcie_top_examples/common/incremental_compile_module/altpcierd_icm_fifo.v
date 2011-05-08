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
module altpcierd_icm_fifo  #(
    parameter RAMTYPE = "RAM_BLOCK_TYPE=M512",
   parameter USEEAB  = "ON"
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
   q);


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

   wire  sub_wire0;
   wire  sub_wire1;
   wire  sub_wire2;
   wire [107:0] sub_wire3;
   wire  sub_wire4;
   wire  almost_full = sub_wire0;
   wire  empty = sub_wire1;
   wire  almost_empty = sub_wire2;
   wire [107:0] q = sub_wire3[107:0];
   wire  full = sub_wire4;

   scfifo   # (

      .add_ram_output_register ( "ON"           ),
      .almost_empty_value      ( 5              ),
      .almost_full_value       ( 10             ),
      .intended_device_family  ( "Stratix II GX"),
      .lpm_hint                ( RAMTYPE        ),
      .lpm_numwords            ( 16             ),
      .lpm_showahead           ( "OFF"           ),
      .lpm_type                ( "scfifo"       ),
      .lpm_width               ( 108            ),
      .lpm_widthu              ( 4              ),
      .overflow_checking       ( "OFF"          ),
      .underflow_checking      ( "OFF"          ),
      .use_eab                 ( USEEAB         )

      )  scfifo_component (
            .rdreq (rdreq),
            .aclr (aclr),
            .clock (clock),
            .wrreq (wrreq),
            .data (data),
            .almost_full (sub_wire0),
            .empty (sub_wire1),
            .almost_empty (sub_wire2),
            .q (sub_wire3),
            .full (sub_wire4)
            // synopsys translate_off
            ,
            .sclr (),
            .usedw ()
            // synopsys translate_on
            );



endmodule

