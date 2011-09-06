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


// ********************************************************************************************************************************
// Filename: sequencer_bridge.sv
// This module performs rate conversion for the HR sequencer signals and FR AFI signals
// The conversion can be bypassed to support same-rate sequencer
// ********************************************************************************************************************************

module altera_mem_if_ddr3_phy_0001_sequencer_mux_bridge(
	seq_clk,
	reset_n_seq_clk,
	afi_clk,
	reset_n_afi_clk,

	seq_address,
	seq_bank,
	seq_cs_n,
	seq_cke,
	seq_odt,
	seq_ras_n,
	seq_cas_n,
	seq_we_n,
	seq_reset_n,
	seq_dqs_en,
	seq_wdata,
	seq_wdata_valid,
	seq_dm,
	seq_rdata_en,
	seq_rdata,
	seq_read_fifo_q,
	seq_rdata_valid,
	seq_read_increment_vfifo_fr,
	seq_read_increment_vfifo_hr,

	mux_address,
	mux_bank,
	mux_cs_n,
	mux_cke,
	mux_odt,
	mux_ras_n,
	mux_cas_n,
	mux_we_n,
	mux_reset_n,
	mux_dqs_en,
	mux_wdata,
	mux_wdata_valid,
	mux_dm,
	mux_rdata_en,
	mux_rdata,
	mux_read_fifo_q,
	mux_rdata_valid,
	phy_read_increment_vfifo_fr,
	phy_read_increment_vfifo_hr
);


parameter	MEM_READ_DQS_WIDTH		= "";
parameter	AFI_ADDRESS_WIDTH		= "";
parameter	AFI_BANK_WIDTH			= "";
parameter	AFI_CHIP_SELECT_WIDTH	= "";
parameter	AFI_CLK_EN_WIDTH		= "";
parameter	AFI_ODT_WIDTH			= "";
parameter	AFI_DATA_MASK_WIDTH		= "";
parameter	AFI_CONTROL_WIDTH		= "";
parameter	AFI_DATA_WIDTH			= "";
parameter	AFI_DQS_WIDTH			= "";


localparam	SEQ_ADDRESS_WIDTH		= 2 * AFI_ADDRESS_WIDTH;
localparam	SEQ_BANK_WIDTH			= 2 * AFI_BANK_WIDTH;
localparam	SEQ_CHIP_SELECT_WIDTH	= 2 * AFI_CHIP_SELECT_WIDTH;
localparam	SEQ_CLK_EN_WIDTH		= 2 * AFI_CLK_EN_WIDTH;
localparam	SEQ_ODT_WIDTH			= 2 * AFI_ODT_WIDTH;
localparam	SEQ_DATA_MASK_WIDTH		= 2 * AFI_DATA_MASK_WIDTH;
localparam	SEQ_CONTROL_WIDTH		= 2 * AFI_CONTROL_WIDTH;
localparam	SEQ_DATA_WIDTH			= 2 * AFI_DATA_WIDTH;
localparam	SEQ_DQS_WIDTH			= 2 * AFI_DQS_WIDTH;


input								seq_clk;
input								reset_n_seq_clk;
input								afi_clk;
input								reset_n_afi_clk;

input	[SEQ_ADDRESS_WIDTH-1:0]		seq_address;
input	[SEQ_BANK_WIDTH-1:0]		seq_bank;
input	[SEQ_CHIP_SELECT_WIDTH-1:0]	seq_cs_n;
input	[SEQ_CLK_EN_WIDTH-1:0]		seq_cke;
input	[SEQ_ODT_WIDTH-1:0]			seq_odt;
input	[SEQ_CONTROL_WIDTH-1:0]		seq_ras_n;
input	[SEQ_CONTROL_WIDTH-1:0]		seq_cas_n;
input	[SEQ_CONTROL_WIDTH-1:0]		seq_we_n;
input	[SEQ_CONTROL_WIDTH-1:0]		seq_reset_n;
input	[SEQ_DQS_WIDTH-1:0]			seq_dqs_en;
input	[SEQ_DATA_WIDTH-1:0]		seq_wdata;
input	[SEQ_DQS_WIDTH-1:0]			seq_wdata_valid;
input	[SEQ_DATA_MASK_WIDTH-1:0]	seq_dm;
input								seq_rdata_en;
output	[SEQ_DATA_WIDTH-1:0]		seq_rdata;
output	[SEQ_DATA_WIDTH-1:0]		seq_read_fifo_q;
output								seq_rdata_valid;
input	[MEM_READ_DQS_WIDTH-1:0]	seq_read_increment_vfifo_fr;
input	[MEM_READ_DQS_WIDTH-1:0]	seq_read_increment_vfifo_hr;

output	[AFI_ADDRESS_WIDTH-1:0]		mux_address;
output	[AFI_BANK_WIDTH-1:0]		mux_bank;
output	[AFI_CHIP_SELECT_WIDTH-1:0]	mux_cs_n;
output	[AFI_CLK_EN_WIDTH-1:0]		mux_cke;
output	[AFI_ODT_WIDTH-1:0]			mux_odt;
output	[AFI_CONTROL_WIDTH-1:0]		mux_ras_n;
output	[AFI_CONTROL_WIDTH-1:0]		mux_cas_n;
output	[AFI_CONTROL_WIDTH-1:0]		mux_we_n;
output	[AFI_CONTROL_WIDTH-1:0]		mux_reset_n;
output	[AFI_DQS_WIDTH-1:0]			mux_dqs_en;
output	[AFI_DATA_WIDTH-1:0]		mux_wdata;
output	[AFI_DQS_WIDTH-1:0]			mux_wdata_valid;
output	[AFI_DATA_MASK_WIDTH-1:0]	mux_dm;
output								mux_rdata_en;
input	[AFI_DATA_WIDTH-1:0]		mux_rdata;
input	[AFI_DATA_WIDTH-1:0]		mux_read_fifo_q;
input								mux_rdata_valid;
output	[MEM_READ_DQS_WIDTH-1:0]	phy_read_increment_vfifo_fr;
output	[MEM_READ_DQS_WIDTH-1:0]	phy_read_increment_vfifo_hr;


wire	enable_conversion;
wire	shift_addr_cmd;


assign	enable_conversion	= 1'b0;
assign	shift_addr_cmd		= 1'b0;


wire	[AFI_ADDRESS_WIDTH-1:0]		seq_address_h;
wire	[AFI_ADDRESS_WIDTH-1:0]		seq_address_l;
wire	[AFI_BANK_WIDTH-1:0]		seq_bank_h;
wire	[AFI_BANK_WIDTH-1:0]		seq_bank_l;
wire	[AFI_CHIP_SELECT_WIDTH-1:0]	seq_cs_n_h;
wire	[AFI_CHIP_SELECT_WIDTH-1:0]	seq_cs_n_l;
wire	[AFI_CLK_EN_WIDTH-1:0]		seq_cke_h;
wire	[AFI_CLK_EN_WIDTH-1:0]		seq_cke_l;
wire	[AFI_ODT_WIDTH-1:0]			seq_odt_h;
wire	[AFI_ODT_WIDTH-1:0]			seq_odt_l;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_ras_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_ras_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_cas_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_cas_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_we_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_we_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_reset_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		seq_reset_n_l;
wire	[AFI_DQS_WIDTH-1:0]			seq_dqs_en_h;
wire	[AFI_DQS_WIDTH-1:0]			seq_dqs_en_l;
wire	[AFI_DATA_WIDTH-1:0]		seq_wdata_h;
wire	[AFI_DATA_WIDTH-1:0]		seq_wdata_l;
wire	[AFI_DQS_WIDTH-1:0]			seq_wdata_valid_h;
wire	[AFI_DQS_WIDTH-1:0]			seq_wdata_valid_l;
wire	[AFI_DATA_MASK_WIDTH-1:0]	seq_dm_h;
wire	[AFI_DATA_MASK_WIDTH-1:0]	seq_dm_l;
wire								seq_rdata_en_h;
wire								seq_rdata_en_l;


assign	seq_address_h		= seq_address[SEQ_ADDRESS_WIDTH-1:AFI_ADDRESS_WIDTH];
assign	seq_address_l		= seq_address[AFI_ADDRESS_WIDTH-1:0];
assign	seq_bank_h			= seq_bank[SEQ_BANK_WIDTH-1:AFI_BANK_WIDTH];
assign	seq_bank_l			= seq_bank[AFI_BANK_WIDTH-1:0];
assign	seq_cs_n_h			= seq_cs_n[SEQ_CHIP_SELECT_WIDTH-1:AFI_CHIP_SELECT_WIDTH];
assign	seq_cs_n_l			= seq_cs_n[AFI_CHIP_SELECT_WIDTH-1:0];
assign	seq_cke_h			= seq_cke[SEQ_CLK_EN_WIDTH-1:AFI_CLK_EN_WIDTH];
assign	seq_cke_l			= seq_cke[AFI_CLK_EN_WIDTH-1:0];
assign	seq_odt_h			= seq_odt[SEQ_ODT_WIDTH-1:AFI_ODT_WIDTH];
assign	seq_odt_l			= seq_odt[AFI_ODT_WIDTH-1:0];
assign	seq_ras_n_h			= seq_ras_n[SEQ_CONTROL_WIDTH-1:AFI_CONTROL_WIDTH];
assign	seq_ras_n_l			= seq_ras_n[AFI_CONTROL_WIDTH-1:0];
assign	seq_cas_n_h			= seq_cas_n[SEQ_CONTROL_WIDTH-1:AFI_CONTROL_WIDTH];
assign	seq_cas_n_l			= seq_cas_n[AFI_CONTROL_WIDTH-1:0];
assign	seq_we_n_h			= seq_we_n[SEQ_CONTROL_WIDTH-1:AFI_CONTROL_WIDTH];
assign	seq_we_n_l			= seq_we_n[AFI_CONTROL_WIDTH-1:0];
assign	seq_reset_n_h		= seq_reset_n[SEQ_CONTROL_WIDTH-1:AFI_CONTROL_WIDTH];
assign	seq_reset_n_l		= seq_reset_n[AFI_CONTROL_WIDTH-1:0];
assign	seq_dqs_en_h		= seq_dqs_en[SEQ_DQS_WIDTH-1:AFI_DQS_WIDTH];
assign	seq_dqs_en_l		= seq_dqs_en[AFI_DQS_WIDTH-1:0];
assign	seq_wdata_h			= seq_wdata[SEQ_DATA_WIDTH-1:AFI_DATA_WIDTH];
assign	seq_wdata_l			= seq_wdata[AFI_DATA_WIDTH-1:0];
assign	seq_wdata_valid_h	= seq_wdata_valid[SEQ_DQS_WIDTH-1:AFI_DQS_WIDTH];
assign	seq_wdata_valid_l	= seq_wdata_valid[AFI_DQS_WIDTH-1:0];
assign	seq_dm_h			= seq_dm[SEQ_DATA_MASK_WIDTH-1:AFI_DATA_MASK_WIDTH];
assign	seq_dm_l			= seq_dm[AFI_DATA_MASK_WIDTH-1:0];
assign	seq_rdata_en_h		= seq_rdata_en;
assign	seq_rdata_en_l		= seq_rdata_en;


reg		[AFI_ADDRESS_WIDTH-1:0]		seq_address_h_r;
reg		[AFI_BANK_WIDTH-1:0]		seq_bank_h_r;
reg		[AFI_CHIP_SELECT_WIDTH-1:0]	seq_cs_n_h_r;
reg		[AFI_CLK_EN_WIDTH-1:0]		seq_cke_h_r;
reg		[AFI_ODT_WIDTH-1:0]			seq_odt_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		seq_ras_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		seq_cas_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		seq_we_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		seq_reset_n_h_r;
reg									seq_rdata_en_h_r;


always_ff @(posedge seq_clk or negedge reset_n_seq_clk)
begin
	if (~reset_n_seq_clk)
	begin
		seq_address_h_r		<= '0;
		seq_bank_h_r		<= '0;
		seq_cke_h_r			<= '0;
		seq_cs_n_h_r		<= '1;
		seq_odt_h_r			<= '0;
		seq_ras_n_h_r		<= '1;
		seq_cas_n_h_r		<= '1;
		seq_we_n_h_r		<= '1;
		seq_reset_n_h_r		<= '1;
		seq_rdata_en_h_r	<= '0;
	end
	else
	begin
		seq_address_h_r		<= seq_address_h;
		seq_bank_h_r		<= seq_bank_h;
		seq_cke_h_r			<= seq_cke_h;
		seq_cs_n_h_r		<= seq_cs_n_h;
		seq_odt_h_r			<= seq_odt_h;
		seq_ras_n_h_r		<= seq_ras_n_h;
		seq_cas_n_h_r		<= seq_cas_n_h;
		seq_we_n_h_r		<= seq_we_n_h;
		seq_reset_n_h_r		<= seq_reset_n_h;
		seq_rdata_en_h_r	<= seq_rdata_en_h;
	end
end


wire	[AFI_ADDRESS_WIDTH-1:0]		ddr_address_h;
wire	[AFI_ADDRESS_WIDTH-1:0]		ddr_address_l;
wire	[AFI_BANK_WIDTH-1:0]		ddr_bank_h;
wire	[AFI_BANK_WIDTH-1:0]		ddr_bank_l;
wire	[AFI_CHIP_SELECT_WIDTH-1:0]	ddr_cs_n_h;
wire	[AFI_CHIP_SELECT_WIDTH-1:0]	ddr_cs_n_l;
wire	[AFI_CLK_EN_WIDTH-1:0]		ddr_cke_h;
wire	[AFI_CLK_EN_WIDTH-1:0]		ddr_cke_l;
wire	[AFI_ODT_WIDTH-1:0]			ddr_odt_h;
wire	[AFI_ODT_WIDTH-1:0]			ddr_odt_l;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_ras_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_ras_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_cas_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_cas_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_we_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_we_n_l;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_reset_n_h;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_reset_n_l;
wire								ddr_rdata_en_h;
wire								ddr_rdata_en_l;


assign	ddr_address_h	= shift_addr_cmd ? seq_address_l	: seq_address_h;
assign	ddr_address_l	= shift_addr_cmd ? seq_address_h_r	: seq_address_l;
assign	ddr_bank_h		= shift_addr_cmd ? seq_bank_l		: seq_bank_h;
assign	ddr_bank_l		= shift_addr_cmd ? seq_bank_h_r		: seq_bank_l;
assign	ddr_cs_n_h		= shift_addr_cmd ? seq_cs_n_l		: seq_cs_n_h;
assign	ddr_cs_n_l		= shift_addr_cmd ? seq_cs_n_h_r		: seq_cs_n_l;
assign	ddr_cke_h		= shift_addr_cmd ? seq_cke_l		: seq_cke_h;
assign	ddr_cke_l		= shift_addr_cmd ? seq_cke_h_r		: seq_cke_l;
assign	ddr_odt_h		= shift_addr_cmd ? seq_odt_l		: seq_odt_h;
assign	ddr_odt_l		= shift_addr_cmd ? seq_odt_h_r		: seq_odt_l;
assign	ddr_ras_n_h		= shift_addr_cmd ? seq_ras_n_l		: seq_ras_n_h;
assign	ddr_ras_n_l		= shift_addr_cmd ? seq_ras_n_h_r	: seq_ras_n_l;
assign	ddr_cas_n_h		= shift_addr_cmd ? seq_cas_n_l		: seq_cas_n_h;
assign	ddr_cas_n_l		= shift_addr_cmd ? seq_cas_n_h_r	: seq_cas_n_l;
assign	ddr_we_n_h		= shift_addr_cmd ? seq_we_n_l		: seq_we_n_h;
assign	ddr_we_n_l		= shift_addr_cmd ? seq_we_n_h_r		: seq_we_n_l;
assign	ddr_reset_n_h	= shift_addr_cmd ? seq_reset_n_l	: seq_reset_n_h;
assign	ddr_reset_n_l	= shift_addr_cmd ? seq_reset_n_h_r	: seq_reset_n_l;
assign	ddr_rdata_en_h	= shift_addr_cmd ? seq_rdata_en_l	: seq_rdata_en_h;
assign	ddr_rdata_en_l	= shift_addr_cmd ? seq_rdata_en_h_r	: seq_rdata_en_l;


reg		[AFI_ADDRESS_WIDTH-1:0]		ddr_address_h_r;
reg		[AFI_ADDRESS_WIDTH-1:0]		ddr_address_l_r;
reg		[AFI_BANK_WIDTH-1:0]		ddr_bank_h_r;
reg		[AFI_BANK_WIDTH-1:0]		ddr_bank_l_r;
reg		[AFI_CHIP_SELECT_WIDTH-1:0]	ddr_cs_n_h_r;
reg		[AFI_CHIP_SELECT_WIDTH-1:0]	ddr_cs_n_l_r;
reg		[AFI_CLK_EN_WIDTH-1:0]		ddr_cke_h_r;
reg		[AFI_CLK_EN_WIDTH-1:0]		ddr_cke_l_r;
reg		[AFI_ODT_WIDTH-1:0]			ddr_odt_h_r;
reg		[AFI_ODT_WIDTH-1:0]			ddr_odt_l_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_ras_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_ras_n_l_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_cas_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_cas_n_l_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_we_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_we_n_l_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_reset_n_h_r;
reg		[AFI_CONTROL_WIDTH-1:0]		ddr_reset_n_l_r;
reg		[AFI_DQS_WIDTH-1:0]			ddr_dqs_en_h_r;
reg		[AFI_DQS_WIDTH-1:0]			ddr_dqs_en_l_r;
reg		[AFI_DATA_WIDTH-1:0]		ddr_wdata_h_r;
reg		[AFI_DATA_WIDTH-1:0]		ddr_wdata_l_r;
reg		[AFI_DQS_WIDTH-1:0]			ddr_wdata_valid_h_r;
reg		[AFI_DQS_WIDTH-1:0]			ddr_wdata_valid_l_r;
reg		[AFI_DATA_MASK_WIDTH-1:0]	ddr_dm_h_r;
reg		[AFI_DATA_MASK_WIDTH-1:0]	ddr_dm_l_r;
reg									ddr_rdata_en_h_r;
reg									ddr_rdata_en_l_r;


`ifdef DDR_FLOP
always_ff @(posedge seq_clk or negedge reset_n_seq_clk)
`else
always_comb
`endif
begin
	ddr_address_h_r		<= ddr_address_h;
	ddr_address_l_r		<= ddr_address_l;
	ddr_bank_h_r		<= ddr_bank_h;
	ddr_bank_l_r		<= ddr_bank_l;
	ddr_cs_n_h_r		<= ddr_cs_n_h;
	ddr_cs_n_l_r		<= ddr_cs_n_l;
	ddr_cke_h_r			<= ddr_cke_h;
	ddr_cke_l_r			<= ddr_cke_l;
	ddr_odt_h_r			<= ddr_odt_h;
	ddr_odt_l_r			<= ddr_odt_l;
	ddr_ras_n_h_r		<= ddr_ras_n_h;
	ddr_ras_n_l_r		<= ddr_ras_n_l;
	ddr_cas_n_h_r		<= ddr_cas_n_h;
	ddr_cas_n_l_r		<= ddr_cas_n_l;
	ddr_we_n_h_r		<= ddr_we_n_h;
	ddr_we_n_l_r		<= ddr_we_n_l;
	ddr_reset_n_h_r		<= ddr_reset_n_h;
	ddr_reset_n_l_r		<= ddr_reset_n_l;
	ddr_dqs_en_h_r		<= seq_dqs_en_h;
	ddr_dqs_en_l_r		<= seq_dqs_en_l;
	ddr_wdata_h_r		<= seq_wdata_h;
	ddr_wdata_l_r		<= seq_wdata_l;
	ddr_wdata_valid_h_r	<= seq_wdata_valid_h;
	ddr_wdata_valid_l_r	<= seq_wdata_valid_l;
	ddr_dm_h_r			<= seq_dm_h;
	ddr_dm_l_r			<= seq_dm_l;
	ddr_rdata_en_h_r	<= ddr_rdata_en_h;
	ddr_rdata_en_l_r	<= ddr_rdata_en_l;
end


wire	[AFI_ADDRESS_WIDTH-1:0]		ddr_address;
wire	[AFI_BANK_WIDTH-1:0]		ddr_bank;
wire	[AFI_CHIP_SELECT_WIDTH-1:0]	ddr_cs_n;
wire	[AFI_CLK_EN_WIDTH-1:0]		ddr_cke;
wire	[AFI_ODT_WIDTH-1:0]			ddr_odt;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_ras_n;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_cas_n;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_we_n;
wire	[AFI_CONTROL_WIDTH-1:0]		ddr_reset_n;
wire	[AFI_DQS_WIDTH-1:0]			ddr_dqs_en;
wire	[AFI_DATA_WIDTH-1:0]		ddr_wdata;
wire	[AFI_DQS_WIDTH-1:0]			ddr_wdata_valid;
wire	[AFI_DATA_MASK_WIDTH-1:0]	ddr_dm;
wire								ddr_rdata_en;
wire	[MEM_READ_DQS_WIDTH-1:0]	ddr_read_increment_vfifo_fr;
wire	[MEM_READ_DQS_WIDTH-1:0]	ddr_read_increment_vfifo_hr;


assign	ddr_address					= seq_clk ? ddr_address_l_r				: ddr_address_h_r;
assign	ddr_bank					= seq_clk ? ddr_bank_l_r				: ddr_bank_h_r;
assign	ddr_cke						= seq_clk ? ddr_cke_l_r					: ddr_cke_h_r;
assign	ddr_cs_n					= seq_clk ? ddr_cs_n_l_r				: ddr_cs_n_h_r;
assign	ddr_odt						= seq_clk ? ddr_odt_l_r					: ddr_odt_h_r;
assign	ddr_ras_n					= seq_clk ? ddr_ras_n_l_r				: ddr_ras_n_h_r;
assign	ddr_cas_n					= seq_clk ? ddr_cas_n_l_r				: ddr_cas_n_h_r;
assign	ddr_we_n					= seq_clk ? ddr_we_n_l_r				: ddr_we_n_h_r;
assign	ddr_reset_n					= seq_clk ? ddr_reset_n_l_r				: ddr_reset_n_h_r;
assign	ddr_dqs_en					= seq_clk ? ddr_dqs_en_l_r				: ddr_dqs_en_h_r;
assign	ddr_wdata					= seq_clk ? ddr_wdata_l_r				: ddr_wdata_h_r;
assign	ddr_wdata_valid				= seq_clk ? ddr_wdata_valid_l_r			: ddr_wdata_valid_h_r;
assign	ddr_dm						= seq_clk ? ddr_dm_l_r					: ddr_dm_h_r;
assign	ddr_rdata_en				= seq_clk ? ddr_rdata_en_l_r			: ddr_rdata_en_h_r;
assign	ddr_read_increment_vfifo_fr	= seq_clk ? seq_read_increment_vfifo_fr	: 1'b0;
assign	ddr_read_increment_vfifo_hr	= seq_clk ? seq_read_increment_vfifo_hr	: 1'b0;


reg		[AFI_DATA_WIDTH-1:0]	mux_rdata_r;
reg		[AFI_DATA_WIDTH-1:0]	mux_rdata_rr;
reg		[AFI_DATA_WIDTH-1:0]	mux_read_fifo_q_r;
reg		[AFI_DATA_WIDTH-1:0]	mux_read_fifo_q_rr;
reg								mux_rdata_valid_r;
reg								mux_rdata_valid_rr;


always_ff @(posedge afi_clk)
begin
	mux_rdata_r			<= mux_rdata;
	mux_rdata_rr		<= mux_rdata_r;
	mux_read_fifo_q_r	<= mux_read_fifo_q;
	mux_read_fifo_q_rr	<= mux_read_fifo_q_r;
end


always_ff @(posedge afi_clk or negedge reset_n_afi_clk)
begin
	if (~reset_n_afi_clk)
	begin
		mux_rdata_valid_r	<= 1'b0;
		mux_rdata_valid_rr	<= 1'b0;
	end
	else
	begin
		mux_rdata_valid_r	<= mux_rdata_valid;
		mux_rdata_valid_rr	<= mux_rdata_valid_r;
	end
end


wire							shift_zero;
wire							shift_one;
reg								shift_reg;
wire							shift;
wire	[SEQ_DATA_WIDTH-1:0]	ddr_rdata;
wire	[SEQ_DATA_WIDTH-1:0]	ddr_read_fifo_q;
wire							ddr_rdata_valid;


assign	shift_zero		= (mux_rdata_valid & mux_rdata_valid_r & ~mux_rdata_valid_rr);
assign	shift_one		= (mux_rdata_valid & ~mux_rdata_valid_r & ~mux_rdata_valid_rr);
always_ff @(posedge seq_clk or negedge reset_n_seq_clk)
begin
	if (~reset_n_seq_clk)
		shift_reg <= 1'b0;
	else
		shift_reg <= shift_zero ? 1'b0 : (shift_one ? 1'b1 : shift_reg);
end
assign	shift			= (shift_one | (~shift_zero & shift_reg));
assign	ddr_rdata		= shift ? {mux_rdata_r, mux_rdata_rr} : {mux_rdata, mux_rdata_r};
assign	ddr_read_fifo_q	= shift ? {mux_read_fifo_q_r, mux_read_fifo_q_rr} : {mux_read_fifo_q, mux_read_fifo_q_r};
assign	ddr_rdata_valid	= shift ? (mux_rdata_valid_r & mux_rdata_valid_rr) : (mux_rdata_valid & mux_rdata_valid_r);


assign	mux_address					= enable_conversion ? ddr_address					: seq_address;
assign	mux_bank					= enable_conversion ? ddr_bank						: seq_bank;
assign	mux_cs_n					= enable_conversion ? ddr_cs_n						: seq_cs_n;
assign	mux_cke						= enable_conversion ? ddr_cke						: seq_cke;
assign	mux_odt						= enable_conversion ? ddr_odt						: seq_odt;
assign	mux_ras_n					= enable_conversion ? ddr_ras_n						: seq_ras_n;
assign	mux_cas_n					= enable_conversion ? ddr_cas_n						: seq_cas_n;
assign	mux_we_n					= enable_conversion ? ddr_we_n						: seq_we_n;
assign	mux_reset_n					= enable_conversion ? ddr_reset_n					: seq_reset_n;
assign	mux_dqs_en					= enable_conversion ? ddr_dqs_en					: seq_dqs_en;
assign	mux_wdata					= enable_conversion ? ddr_wdata						: seq_wdata;
assign	mux_wdata_valid				= enable_conversion ? ddr_wdata_valid				: seq_wdata_valid;
assign	mux_dm						= enable_conversion ? ddr_dm						: seq_dm;
assign	mux_rdata_en				= enable_conversion ? ddr_rdata_en					: seq_rdata_en;
assign	seq_rdata					= enable_conversion ? ddr_rdata						: mux_rdata;
assign	seq_read_fifo_q				= enable_conversion ? ddr_read_fifo_q				: mux_read_fifo_q;
assign	seq_rdata_valid				= enable_conversion ? ddr_rdata_valid				: mux_rdata_valid;
assign	phy_read_increment_vfifo_fr	= enable_conversion ? ddr_read_increment_vfifo_fr	: seq_read_increment_vfifo_fr;
assign	phy_read_increment_vfifo_hr	= enable_conversion ? ddr_read_increment_vfifo_hr	: seq_read_increment_vfifo_hr;


endmodule

