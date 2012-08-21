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
//USER The sequential address generator generates sequential addresses starting
//USER with a parametrizable address.
//USER////////////////////////////////////////////////////////////////////////////

module seq_addr_gen(
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

//USER Burstcount range
parameter MIN_BURSTCOUNT			= "";
parameter MAX_BURSTCOUNT			= "";

//USER END PARAMETER SECTION
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

//USER Sequential address registers
reg	 	[ADDR_WIDTH-1:0]		seq_addr;


//USER Sequential address generation
always_ff @(posedge clk or negedge reset_n)
begin
	if (!reset_n)
		seq_addr <= '0;
	else if (enable)
		seq_addr <= addr + burstcount;
end


//USER Random burstcount generator
rand_burstcount_gen rand_burstcount (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(enable),
	.ready		(ready),
	.burstcount	(burstcount));
defparam rand_burstcount.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam rand_burstcount.POWER_OF_TWO_BURSTS_ONLY	= POWER_OF_TWO_BURSTS_ONLY;
defparam rand_burstcount.MIN_BURSTCOUNT				= MIN_BURSTCOUNT;
defparam rand_burstcount.MAX_BURSTCOUNT				= MAX_BURSTCOUNT;


//USER Burst boundary address generator
burst_boundary_addr_gen burst_boundary_addr_gen_inst (
	.burstcount	(burstcount),
	.addr_in	(seq_addr),
	.addr_out	(addr));
defparam burst_boundary_addr_gen_inst.ADDR_WIDTH				= ADDR_WIDTH;
defparam burst_boundary_addr_gen_inst.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam burst_boundary_addr_gen_inst.BURST_ON_BURST_BOUNDARY	= BURST_ON_BURST_BOUNDARY;


endmodule

