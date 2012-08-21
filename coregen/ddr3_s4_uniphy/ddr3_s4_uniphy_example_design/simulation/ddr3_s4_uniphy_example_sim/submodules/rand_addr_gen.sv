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
//USER The random address generator generates random addresses and burstcounts
//USER within parametrizable ranges.
//USER////////////////////////////////////////////////////////////////////////////

module rand_addr_gen(
	clk,
	reset_n,
	enable,
	ready,
	addr,
	burstcount
);

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PARAMETER SECTION

//USER Avalon signal widths
parameter ADDR_WIDTH				= "";
parameter BURSTCOUNT_WIDTH			= "";

//USER Address generator configuration
parameter POWER_OF_TWO_BURSTS_ONLY	= "";
parameter BURST_ON_BURST_BOUNDARY	= "";

//USER Burstcount ranges
parameter MIN_BURSTCOUNT			= "";
parameter MAX_BURSTCOUNT			= "";

//USER END PARAMETER SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN LOCALPARAM SECTION

//USER Two LFSRs are used to generate random addresses to prevent address overlap
//USER in block writes.  The following parameter is the width of the lower bits.
localparam ADDR_WIDTH_LOW	= (ADDR_WIDTH - 1) / 2 + 1;

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

//USER Address generator outputs
output 	[ADDR_WIDTH-1:0]		addr;
output	[BURSTCOUNT_WIDTH-1:0]	burstcount;

//USER END PORT SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER Random address generator output
wire	[ADDR_WIDTH-1:0]		rand_addr_out;

//USER Submodule status
wire							rand_burstcount_ready;


//USER Random address generator status
assign ready = rand_burstcount_ready;


//USER LFSRs for random addresses
lfsr rand_addr_low (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(enable),
	.data		(rand_addr_out[ADDR_WIDTH_LOW-1:0]));
defparam rand_addr_low.WIDTH = ADDR_WIDTH_LOW;

lfsr rand_addr_high (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(enable),
	.data		(rand_addr_out[ADDR_WIDTH-1:ADDR_WIDTH_LOW+1]));
defparam rand_addr_high.WIDTH = ADDR_WIDTH - ADDR_WIDTH_LOW - 1;

assign rand_addr_out[ADDR_WIDTH_LOW] = 1'b0;


//USER Random burstcount generator
rand_burstcount_gen rand_burstcount (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(enable),
	.ready		(rand_burstcount_ready),
	.burstcount	(burstcount));
defparam rand_burstcount.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam rand_burstcount.POWER_OF_TWO_BURSTS_ONLY	= POWER_OF_TWO_BURSTS_ONLY;
defparam rand_burstcount.MIN_BURSTCOUNT				= MIN_BURSTCOUNT;
defparam rand_burstcount.MAX_BURSTCOUNT				= MAX_BURSTCOUNT;


//USER Burst boundary address generator
burst_boundary_addr_gen burst_boundary_addr_gen_inst (
	.burstcount	(burstcount),
	.addr_in		(rand_addr_out),
	.addr_out		(addr));
defparam burst_boundary_addr_gen_inst.ADDR_WIDTH				= ADDR_WIDTH;
defparam burst_boundary_addr_gen_inst.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam burst_boundary_addr_gen_inst.BURST_ON_BURST_BOUNDARY	= BURST_ON_BURST_BOUNDARY;


endmodule

