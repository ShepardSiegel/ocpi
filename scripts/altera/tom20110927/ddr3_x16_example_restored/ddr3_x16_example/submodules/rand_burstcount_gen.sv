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


//USER////////////////////////////////////////////////////////////////////////////
//USER The random burstcount generator generates random burstcounts within
//USER parametrizable ranges.  In addition, an option can be enabled to only
//USER generate burstcounts that are powers of two.
//USER////////////////////////////////////////////////////////////////////////////

module rand_burstcount_gen(
	clk,
	reset_n,
	enable,
	ready,
	burstcount
);

import driver_definitions::*;

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PARAMETER SECTION

//USER Avalon signal widths
parameter BURSTCOUNT_WIDTH			= "";

//USER Burstcount generator configuration
parameter POWER_OF_TWO_BURSTS_ONLY	= "";

//USER Burstcount range
parameter MIN_BURSTCOUNT			= "";
parameter MAX_BURSTCOUNT			= "";

//USER END PARAMETER SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN LOCALPARAM SECTION

localparam MIN_EXPONENT		= ceil_log2(MIN_BURSTCOUNT);
localparam MAX_EXPONENT		= log2(MAX_BURSTCOUNT);
localparam EXPONENT_WIDTH	= ceil_log2(MAX_EXPONENT);

//USER END LOCALPARAM SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PORT SECTION

//USER Clock and reset
input							clk;
input							reset_n;

//USER Control and status
input							enable;
output							ready;

//USER Burstcount generator output
output	[BURSTCOUNT_WIDTH-1:0]	burstcount;

//USER END PORT SECTION
//USER////////////////////////////////////////////////////////////////////////////

generate
if (POWER_OF_TWO_BURSTS_ONLY == 1)
begin : power_of_two_true
	//USER POWER_OF_TWO_BURSTS_ONLY is enabled
	//USER Use the random number generator to generate the exponent

	wire	[EXPONENT_WIDTH-1:0]	rand_exponent_out;

	rand_num_gen rand_exponent (
		.clk		(clk),
		.reset_n	(reset_n),
		.enable		(enable),
		.ready		(ready),
		.rand_num	(rand_exponent_out));
	defparam rand_exponent.RAND_NUM_WIDTH	= EXPONENT_WIDTH;
	defparam rand_exponent.RAND_NUM_MIN		= MIN_EXPONENT;
	defparam rand_exponent.RAND_NUM_MAX		= MAX_EXPONENT;

	assign burstcount = 1 << rand_exponent_out;
end
else
begin : power_of_two_false
	//USER POWER_OF_TWO_BURSTS_ONLY is disabled
	//USER Simply generate the burstcount using a random number generator

	rand_num_gen rand_burstcount (
		.clk		(clk),
		.reset_n	(reset_n),
		.enable		(enable),
		.ready		(ready),
		.rand_num	(burstcount));
	defparam rand_burstcount.RAND_NUM_WIDTH	= BURSTCOUNT_WIDTH;
	defparam rand_burstcount.RAND_NUM_MIN	= MIN_BURSTCOUNT;
	defparam rand_burstcount.RAND_NUM_MAX	= MAX_BURSTCOUNT;
end
endgenerate


endmodule

