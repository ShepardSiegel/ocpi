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
//USER This is an example address generator, which simply alternate between 0x0
//USER and 0x1.
//USER////////////////////////////////////////////////////////////////////////////

module template_addr_gen(
	clk,
	reset_n,
	enable,
	ready,
	addr,
	burstcount
);

import driver_definitions::*;

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PARAMETER SECTION

//USER Avalon signal widths
parameter ADDR_WIDTH		= "";
parameter BURSTCOUNT_WIDTH	= "";

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

//USER Address bit 0 register
reg								addr0;


//USER Always ready
assign ready = 1'b1;

//USER Always issue single burst commands
assign burstcount = {'0,1'b1};


//USER Alternate address 0x0 and 0x1
always_ff @(posedge clk or negedge reset_n)
begin
	if (!reset_n)
		addr0 <= 1'b0;
	else if (enable)
		addr0 <= ~addr0;
end

assign addr = {'0, addr0};


endmodule

