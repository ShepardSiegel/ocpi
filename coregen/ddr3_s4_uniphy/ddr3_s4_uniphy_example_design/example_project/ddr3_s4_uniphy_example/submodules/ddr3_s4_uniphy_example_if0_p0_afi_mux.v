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
// Filename: afi_mux.v
// This module contains a set of muxes between the sequencer AFI signals and the controller AFI signals
// During calibration, mux_sel = 1, sequencer AFI signals are selected
// After calibration is succesfu, mux_sel = 0, controller AFI signals are selected
// ******************************************************************************************************************************** 

module ddr3_s4_uniphy_example_if0_p0_afi_mux(
	mux_sel,
	afi_address,
	afi_bank,
	afi_cs_n,
	afi_cke,
	afi_odt,
	afi_ras_n,
	afi_cas_n,
	afi_we_n,
	afi_rst_n,
	afi_dqs_burst,
	afi_wdata,
	afi_wdata_valid,
	afi_dm,
	afi_rdata_en,
	afi_rdata_en_full,
	afi_rdata,
	afi_rdata_valid,
	seq_mux_address,
	seq_mux_bank,
	seq_mux_cs_n,
	seq_mux_cke,
	seq_mux_odt,
	seq_mux_ras_n,
	seq_mux_cas_n,
	seq_mux_we_n,
	seq_mux_reset_n,
	seq_mux_dqs_en,
	seq_mux_wdata,
	seq_mux_wdata_valid,
	seq_mux_dm,
	seq_mux_rdata_en,
	mux_seq_rdata,
	mux_seq_read_fifo_q,
	mux_seq_rdata_valid,
	mux_phy_address,
	mux_phy_bank,
	mux_phy_cs_n,
	mux_phy_cke,
	mux_phy_odt,
	mux_phy_ras_n,
	mux_phy_cas_n,
	mux_phy_we_n,
	mux_phy_reset_n,
	mux_phy_dqs_en,
	mux_phy_wdata,
	mux_phy_wdata_valid,
	mux_phy_dm,
	mux_phy_rdata_en,
	mux_phy_rdata_en_full,
	phy_mux_rdata,
	phy_mux_read_fifo_q,
	phy_mux_rdata_valid
);


parameter AFI_ADDRESS_WIDTH         = "";
parameter AFI_BANK_WIDTH            = "";
parameter AFI_CHIP_SELECT_WIDTH     = "";
parameter AFI_CLK_EN_WIDTH     		= "";
parameter AFI_ODT_WIDTH     		= "";
parameter MEM_READ_DQS_WIDTH		= "";
parameter AFI_DATA_MASK_WIDTH       = "";
parameter AFI_CONTROL_WIDTH         = "";
parameter AFI_DATA_WIDTH            = "";
parameter AFI_DQS_WIDTH				= "";

input	mux_sel;

// AFI inputs from the controller
input   [AFI_ADDRESS_WIDTH-1:0] afi_address;
input   [AFI_BANK_WIDTH-1:0]    afi_bank;
input   [AFI_CONTROL_WIDTH-1:0] afi_cas_n;
input   [AFI_CLK_EN_WIDTH-1:0] afi_cke;
input   [AFI_CHIP_SELECT_WIDTH-1:0] afi_cs_n;
input   [AFI_ODT_WIDTH-1:0] afi_odt;
input   [AFI_CONTROL_WIDTH-1:0] afi_ras_n;
input   [AFI_CONTROL_WIDTH-1:0] afi_we_n;
input   [AFI_CONTROL_WIDTH-1:0] afi_rst_n;
input	[AFI_DQS_WIDTH-1:0]	afi_dqs_burst;
input   [AFI_DATA_WIDTH-1:0]    afi_wdata;
input   [AFI_DQS_WIDTH-1:0] afi_wdata_valid;
input   [AFI_DATA_MASK_WIDTH-1:0]   afi_dm;
input   afi_rdata_en;
input   afi_rdata_en_full;
output	[AFI_DATA_WIDTH-1:0] afi_rdata;
output	afi_rdata_valid;

// AFI inputs from the sequencer
input  [AFI_ADDRESS_WIDTH-1:0] seq_mux_address;
input	[AFI_BANK_WIDTH-1:0]    seq_mux_bank;
input	[AFI_CHIP_SELECT_WIDTH-1:0] seq_mux_cs_n;
input	[AFI_CLK_EN_WIDTH-1:0] seq_mux_cke;
input	[AFI_ODT_WIDTH-1:0] seq_mux_odt;
input	[AFI_CONTROL_WIDTH-1:0] seq_mux_ras_n;
input	[AFI_CONTROL_WIDTH-1:0] seq_mux_cas_n;
input	[AFI_CONTROL_WIDTH-1:0] seq_mux_we_n;
input	[AFI_CONTROL_WIDTH-1:0] seq_mux_reset_n;
input	[AFI_DQS_WIDTH-1:0]	seq_mux_dqs_en;
input  [AFI_DATA_WIDTH-1:0]    seq_mux_wdata;
input  [AFI_DQS_WIDTH-1:0]	seq_mux_wdata_valid;
input  [AFI_DATA_MASK_WIDTH-1:0]   seq_mux_dm;
input  seq_mux_rdata_en;
output  [AFI_DATA_WIDTH-1:0]    mux_seq_rdata;
output  [AFI_DATA_WIDTH-1:0]    mux_seq_read_fifo_q;
output  mux_seq_rdata_valid;

// Mux output to the rest of the PHY logic
output  [AFI_ADDRESS_WIDTH-1:0] mux_phy_address;
output	[AFI_BANK_WIDTH-1:0]    mux_phy_bank;
output	[AFI_CHIP_SELECT_WIDTH-1:0] mux_phy_cs_n;
output	[AFI_CLK_EN_WIDTH-1:0] mux_phy_cke;
output	[AFI_ODT_WIDTH-1:0] mux_phy_odt;
output	[AFI_CONTROL_WIDTH-1:0] mux_phy_ras_n;
output	[AFI_CONTROL_WIDTH-1:0] mux_phy_cas_n;
output	[AFI_CONTROL_WIDTH-1:0] mux_phy_we_n;
output	[AFI_CONTROL_WIDTH-1:0] mux_phy_reset_n;
output	[AFI_DQS_WIDTH-1:0]	mux_phy_dqs_en;
output  [AFI_DATA_WIDTH-1:0]    mux_phy_wdata;
output  [AFI_DQS_WIDTH-1:0]	mux_phy_wdata_valid;
output  [AFI_DATA_MASK_WIDTH-1:0]   mux_phy_dm;
output  mux_phy_rdata_en;
output  mux_phy_rdata_en_full;
input	[AFI_DATA_WIDTH-1:0] phy_mux_rdata;
input	[AFI_DATA_WIDTH-1:0] phy_mux_read_fifo_q;
input	phy_mux_rdata_valid;


assign afi_rdata = phy_mux_rdata;
assign afi_rdata_valid = mux_sel ? 1'b0 : phy_mux_rdata_valid;

assign mux_seq_rdata = phy_mux_rdata;
assign mux_seq_read_fifo_q = phy_mux_read_fifo_q;
assign mux_seq_rdata_valid = phy_mux_rdata_valid;

assign mux_phy_address = mux_sel ? seq_mux_address : afi_address;
assign mux_phy_bank = mux_sel ? seq_mux_bank : afi_bank; 
assign mux_phy_cs_n = mux_sel ? seq_mux_cs_n : afi_cs_n;
assign mux_phy_cke = mux_sel ? seq_mux_cke : afi_cke;
assign mux_phy_odt = mux_sel ? seq_mux_odt : afi_odt;
assign mux_phy_ras_n = mux_sel ? seq_mux_ras_n : afi_ras_n;
assign mux_phy_cas_n = mux_sel ? seq_mux_cas_n : afi_cas_n;
assign mux_phy_we_n = mux_sel ? seq_mux_we_n : afi_we_n;
assign mux_phy_reset_n = mux_sel ? seq_mux_reset_n : afi_rst_n;
assign mux_phy_dqs_en = mux_sel ? seq_mux_dqs_en : afi_dqs_burst;
assign mux_phy_wdata = mux_sel ? seq_mux_wdata : afi_wdata;
assign mux_phy_wdata_valid = mux_sel ? seq_mux_wdata_valid  : afi_wdata_valid;
assign mux_phy_dm = mux_sel ? seq_mux_dm : afi_dm;
assign mux_phy_rdata_en = mux_sel ? seq_mux_rdata_en : afi_rdata_en;
assign mux_phy_rdata_en_full = mux_sel ? seq_mux_rdata_en : afi_rdata_en_full;


endmodule
