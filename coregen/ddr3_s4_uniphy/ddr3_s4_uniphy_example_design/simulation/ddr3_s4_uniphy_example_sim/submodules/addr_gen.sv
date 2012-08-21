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
//USER This module is a wrapper for the address generators.  The generators'
//USER outputs are multiplexed in this module using the select signals.
//USER////////////////////////////////////////////////////////////////////////////


module addr_gen(
	clk,
	reset_n,
	addr_gen_select,
	enable,
	ready,
	addr,
	burstcount
);

import driver_definitions::*;

//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PARAMETER SECTION

//USER Avalon signal widths
parameter ADDR_WIDTH							= "";
parameter AVL_WORD_ADDR_WIDTH                   = "";
parameter DATA_WIDTH							= "";
parameter BURSTCOUNT_WIDTH						= "";

//USER Address generator configuration
//USER If set to 1, the driver generates 'avl_size' which are powers of two
parameter POWER_OF_TWO_BURSTS_ONLY				= "";
//USER If set to 1, burst transfers begin at addresses which are multiples of 'avl_size'
parameter BURST_ON_BURST_BOUNDARY				= "";
//USER If set to true, the address will be shifted to make it per byte address instead per word address
parameter GEN_BYTE_ADDR					= "";

//USER Sequential address generator
parameter SEQ_ADDR_GEN_MIN_BURSTCOUNT			= "";
parameter SEQ_ADDR_GEN_MAX_BURSTCOUNT			= "";

//USER Random address generator
parameter RAND_ADDR_GEN_MIN_BURSTCOUNT			= "";
parameter RAND_ADDR_GEN_MAX_BURSTCOUNT			= "";

//USER Mixed sequential/random address generator
parameter RAND_SEQ_ADDR_GEN_MIN_BURSTCOUNT		= "";
parameter RAND_SEQ_ADDR_GEN_MAX_BURSTCOUNT		= "";
parameter RAND_SEQ_ADDR_GEN_RAND_ADDR_PERCENT	= "";

//USER END PARAMETER SECTION
//USER////////////////////////////////////////////////////////////////////////////

// From the address generators point of view, they always generate in terms of words
// If byte address is to be generated, then the word->byte address conversion takes place
// outside of the address generators (ie. the address generators should still be restricted
// to the same address space regardless of GEN_BYTE_ADDR set to true or false)
// However, if GEN_TYPE_ADDR set to true, the ADDR_WIDTH passed in will be greater than
// the false case to take into account the extra zero padding.
localparam ADDR_GEN_ADDR_WIDTH				= (GEN_BYTE_ADDR == 1) ? AVL_WORD_ADDR_WIDTH : ADDR_WIDTH;


//USER////////////////////////////////////////////////////////////////////////////
//USER BEGIN PORT SECTION

//USER Clock and reset
input							clk;
input							reset_n;

//USER One-hot address generator selector
input	addr_gen_select_t		addr_gen_select;

//USER Control and status
input							enable;
output							ready;

//USER Address generator outputs
output 	[ADDR_WIDTH-1:0]		addr;
output	[BURSTCOUNT_WIDTH-1:0]	burstcount;

//USER END PORT SECTION
//USER////////////////////////////////////////////////////////////////////////////

//USER Sequential address generator signals
wire							seq_addr_gen_enable;
wire							seq_addr_gen_ready;
wire 	[ADDR_GEN_ADDR_WIDTH-1:0]		seq_addr_gen_addr;
wire	[BURSTCOUNT_WIDTH-1:0]	seq_addr_gen_burstcount;

//USER Random address generator signals
wire							rand_addr_gen_enable;
wire							rand_addr_gen_ready;
wire 	[ADDR_GEN_ADDR_WIDTH-1:0]		rand_addr_gen_addr;
wire	[BURSTCOUNT_WIDTH-1:0]	rand_addr_gen_burstcount;

//USER Mixed sequential/random address generator signals
wire							rand_seq_addr_gen_enable;
wire							rand_seq_addr_gen_ready;
wire 	[ADDR_GEN_ADDR_WIDTH-1:0]		rand_seq_addr_gen_addr;
wire	[BURSTCOUNT_WIDTH-1:0]	rand_seq_addr_gen_burstcount;

//USER Sequential address generator signals
wire							template_addr_gen_enable;
wire							template_addr_gen_ready;
wire 	[ADDR_GEN_ADDR_WIDTH-1:0]		template_addr_gen_addr;
wire	[BURSTCOUNT_WIDTH-1:0]	template_addr_gen_burstcount;


//USER Address generator output mux
logic ready;
logic [ADDR_WIDTH-1:0] addr;
logic [ADDR_GEN_ADDR_WIDTH-1:0] word_addr;
logic [BURSTCOUNT_WIDTH-1:0] burstcount;

assign addr = (GEN_BYTE_ADDR == 1) ? {word_addr, {(ADDR_WIDTH-AVL_WORD_ADDR_WIDTH){1'b0}}} : word_addr;

always_comb
begin
	case (addr_gen_select)
		SEQ:
		begin
			ready <= seq_addr_gen_ready;
			word_addr <= seq_addr_gen_addr;
			burstcount <= seq_addr_gen_burstcount;
		end
		RAND:
		begin
			ready <= rand_addr_gen_ready;
			word_addr <= rand_addr_gen_addr;
			burstcount <= rand_addr_gen_burstcount;
		end
		RAND_SEQ:
		begin
			ready <= rand_seq_addr_gen_ready;
			word_addr <= rand_seq_addr_gen_addr;
			burstcount <= rand_seq_addr_gen_burstcount;
		end
		TEMPLATE_ADDR_GEN:
		begin
			ready <= template_addr_gen_ready;
			word_addr <= template_addr_gen_addr;
			burstcount <= template_addr_gen_burstcount;
		end
	endcase
end

//USER Address generator inputs
assign seq_addr_gen_enable = (addr_gen_select == SEQ) & enable;
assign rand_addr_gen_enable = (addr_gen_select == RAND) & enable;
assign rand_seq_addr_gen_enable = (addr_gen_select == RAND_SEQ) & enable;
assign template_addr_gen_enable = (addr_gen_select == TEMPLATE_ADDR_GEN) & enable;


//USER Sequential address generator
seq_addr_gen seq_addr_gen_inst (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(seq_addr_gen_enable),
	.ready		(seq_addr_gen_ready),
	.addr		(seq_addr_gen_addr),
	.burstcount	(seq_addr_gen_burstcount));
defparam seq_addr_gen_inst.ADDR_WIDTH				= ADDR_GEN_ADDR_WIDTH;
defparam seq_addr_gen_inst.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam seq_addr_gen_inst.POWER_OF_TWO_BURSTS_ONLY	= POWER_OF_TWO_BURSTS_ONLY;
defparam seq_addr_gen_inst.BURST_ON_BURST_BOUNDARY	= BURST_ON_BURST_BOUNDARY;
defparam seq_addr_gen_inst.MIN_BURSTCOUNT			= SEQ_ADDR_GEN_MIN_BURSTCOUNT;
defparam seq_addr_gen_inst.MAX_BURSTCOUNT			= SEQ_ADDR_GEN_MAX_BURSTCOUNT;


//USER Random address generator
rand_addr_gen rand_addr_gen_inst (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(rand_addr_gen_enable),
	.ready		(rand_addr_gen_ready),
	.addr		(rand_addr_gen_addr),
	.burstcount	(rand_addr_gen_burstcount));
defparam rand_addr_gen_inst.ADDR_WIDTH					= ADDR_GEN_ADDR_WIDTH;
defparam rand_addr_gen_inst.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam rand_addr_gen_inst.POWER_OF_TWO_BURSTS_ONLY	= POWER_OF_TWO_BURSTS_ONLY;
defparam rand_addr_gen_inst.BURST_ON_BURST_BOUNDARY		= BURST_ON_BURST_BOUNDARY;
defparam rand_addr_gen_inst.MIN_BURSTCOUNT				= RAND_ADDR_GEN_MIN_BURSTCOUNT;
defparam rand_addr_gen_inst.MAX_BURSTCOUNT				= RAND_ADDR_GEN_MAX_BURSTCOUNT;


//USER Mixed sequential/random address generator
rand_seq_addr_gen rand_seq_addr_gen_inst (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(rand_seq_addr_gen_enable),
	.ready		(rand_seq_addr_gen_ready),
	.addr		(rand_seq_addr_gen_addr),
	.burstcount	(rand_seq_addr_gen_burstcount));
defparam rand_seq_addr_gen_inst.ADDR_WIDTH					= ADDR_GEN_ADDR_WIDTH;
defparam rand_seq_addr_gen_inst.BURSTCOUNT_WIDTH			= BURSTCOUNT_WIDTH;
defparam rand_seq_addr_gen_inst.POWER_OF_TWO_BURSTS_ONLY	= POWER_OF_TWO_BURSTS_ONLY;
defparam rand_seq_addr_gen_inst.BURST_ON_BURST_BOUNDARY		= BURST_ON_BURST_BOUNDARY;
defparam rand_seq_addr_gen_inst.RAND_ADDR_PERCENT			= RAND_SEQ_ADDR_GEN_RAND_ADDR_PERCENT;
defparam rand_seq_addr_gen_inst.MIN_BURSTCOUNT				= RAND_SEQ_ADDR_GEN_MIN_BURSTCOUNT;
defparam rand_seq_addr_gen_inst.MAX_BURSTCOUNT				= RAND_SEQ_ADDR_GEN_MAX_BURSTCOUNT;


//USER Address generator template
template_addr_gen template_addr_gen_inst (
	.clk		(clk),
	.reset_n	(reset_n),
	.enable		(template_addr_gen_enable),
	.ready		(template_addr_gen_ready),
	.addr		(template_addr_gen_addr),
	.burstcount	(template_addr_gen_burstcount));
defparam template_addr_gen_inst.ADDR_WIDTH			= ADDR_GEN_ADDR_WIDTH;
defparam template_addr_gen_inst.BURSTCOUNT_WIDTH	= BURSTCOUNT_WIDTH;

endmodule

