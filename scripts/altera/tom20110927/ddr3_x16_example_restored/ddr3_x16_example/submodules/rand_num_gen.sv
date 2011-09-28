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
//USER The random number generator uses the LFSR module to generate random numbers
//USER within a parametrizable range.
//USER////////////////////////////////////////////////////////////////////////////

module rand_num_gen(
	clk,
	reset_n,
	enable,
	ready,
	rand_num,
	is_less_than
);

import driver_definitions::*;

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PARAMETER SECTION

parameter RAND_NUM_WIDTH	= "";
parameter RAND_NUM_MIN		= "";
parameter RAND_NUM_MAX		= "";
parameter RAND_NUM_IS_LESS_THAN_THRESHOLD = 0;

//USER END PARAMETER SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN LOCALPARAM SECTION

//USER Derive LFSR parameters
localparam LFSR_DATA_RANGE	= RAND_NUM_MAX - RAND_NUM_MIN + 1;
localparam LFSR_DATA_WIDTH	= ceil_log2(LFSR_DATA_RANGE);
localparam LFSR_WIDTH		= max(4, ceil_log2(LFSR_DATA_RANGE + 1));

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

//USER Random number generator output
output	[RAND_NUM_WIDTH-1:0]	rand_num;
output							is_less_than;

//USER END PORT SECTION
//USER////////////////////////////////////////////////////////////////////////////

generate
if (RAND_NUM_MIN == RAND_NUM_MAX)
begin : constant_gen
	//USER The max and min of the range equal
	//USER Simply output a constant number

	assign ready = 1'b1;
	assign rand_num = RAND_NUM_MIN;
	assign is_less_than = (RAND_NUM_MIN < RAND_NUM_IS_LESS_THAN_THRESHOLD) ? 1'b1 : 1'b0;
end
else if (RAND_NUM_MIN < RAND_NUM_MAX)
begin : random_gen
	//USER Instantiate the LFSR which is automatically run
	//USER until the output is within the specified range

	//USER Registered random number output
	reg 							rand_num_valid_reg;
	reg		[RAND_NUM_WIDTH-1:0]	rand_num_reg;
	reg								is_less_than_reg;

	//USER LFSR output
	wire							lfsr_valid;
	wire	[LFSR_WIDTH-1:0]		lfsr_data;

	assign ready = rand_num_valid_reg;
	assign rand_num = rand_num_reg;
	assign is_less_than = is_less_than_reg;

	//USER The LFSR output is valid if it is in the range of 0 and LFSR_DATA_RANGE
	assign lfsr_valid = lfsr_data[LFSR_DATA_WIDTH-1:0] < LFSR_DATA_RANGE;

	//USER Output the number within range by adding RAND_NUM_MIN
	always_ff @(posedge clk or negedge reset_n)
	begin
		if (!reset_n)
		begin
			rand_num_valid_reg <= 1'b0;
			rand_num_reg <= '0;
		end
		else if ((!rand_num_valid_reg && lfsr_valid) || enable)
		begin
			rand_num_valid_reg <= lfsr_valid;
			rand_num_reg <= lfsr_data[LFSR_DATA_WIDTH-1:0] + RAND_NUM_MIN[RAND_NUM_WIDTH-1:0];
			is_less_than_reg <= ((lfsr_data[LFSR_DATA_WIDTH-1:0] + RAND_NUM_MIN[RAND_NUM_WIDTH-1:0]) < RAND_NUM_IS_LESS_THAN_THRESHOLD) ? 1'b1 : 1'b0;
		end
	end

	//USER The LFSR module
	lfsr lfsr_inst (
		.clk		(clk),
		.reset_n	(reset_n),
		.enable		(~lfsr_valid | ~rand_num_valid_reg | enable),
		.data		(lfsr_data));
	defparam lfsr_inst.WIDTH = LFSR_WIDTH;
end
endgenerate


//USER Simulation assertions
// synthesis translate_off
initial
begin
	assert (RAND_NUM_MAX >= RAND_NUM_MIN) else $error ("Invalid random number range");
	assert (RAND_NUM_MAX < 2**RAND_NUM_WIDTH) else $error ("Invalid random number width");
end
// synthesis translate_on


endmodule

