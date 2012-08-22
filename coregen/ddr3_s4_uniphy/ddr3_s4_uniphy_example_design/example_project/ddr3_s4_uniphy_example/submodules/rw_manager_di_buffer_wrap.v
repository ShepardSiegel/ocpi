// (C) 2001-2011 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ps / 1 ps

module rw_manager_di_buffer_wrap(
	clock,
	data,
	rdaddress,
	wraddress,
	wren,
	q);

	parameter DATA_WIDTH = 18;
	parameter READ_DATA_SIZE = 9;
	parameter WRITE_TO_READ_RATIO_2_EXPONENT = 2;

	localparam WRITE_TO_READ_RATIO = 2 ** WRITE_TO_READ_RATIO_2_EXPONENT;

	input clock;
	input [DATA_WIDTH-1:0] data;
	input [WRITE_TO_READ_RATIO_2_EXPONENT + 1 : 0] rdaddress;
	input [1:0] wraddress;
	input wren;
	output [READ_DATA_SIZE - 1 : 0] q;

	wire [DATA_WIDTH-1:0] q_wire;

	rw_manager_di_buffer rw_manager_di_buffer_i(
		.clock(clock),
		.data(data),
		.rdaddress(rdaddress[WRITE_TO_READ_RATIO_2_EXPONENT + 1 : WRITE_TO_READ_RATIO_2_EXPONENT]),
		.wraddress(wraddress),
		.wren(wren),
		.q(q_wire));

	generate
		if(WRITE_TO_READ_RATIO_2_EXPONENT > 0) begin
			rw_manager_datamux rw_manager_datamux_i(
				.datain(q_wire),
				.sel(rdaddress[WRITE_TO_READ_RATIO_2_EXPONENT - 1 : 0]),
				.dataout(q)
			);
			defparam rw_manager_datamux_i.DATA_WIDTH = READ_DATA_SIZE;
			defparam rw_manager_datamux_i.SELECT_WIDTH = WRITE_TO_READ_RATIO_2_EXPONENT;
			defparam rw_manager_datamux_i.NUMBER_OF_CHANNELS = WRITE_TO_READ_RATIO;
		end
		else begin
			assign q = q_wire;
		end
	endgenerate

endmodule
