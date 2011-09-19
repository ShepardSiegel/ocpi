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
// File name: sequencer.sv
// The sequencer is responsible for intercepting the AFI interface during the initialization and calibration stages
// During initialization stage, the sequencer executes a sequence according to the memory device spec
// There are 2 steps in the calibration stage:
// 1. Calibrates for read data valid in the returned memory clock domain (read valid prediction)
// 2. Calibrates for read data valid in the afi_clk domain (read latency calibration)
// After successful calibration, the sequencer will pass full control back to the AFI interface
// ******************************************************************************************************************************** 

module ddr3_s4_uniphy_p0_nios_sequencer(
	pll_config_clk,
	pll_avl_clk,
	
	reset_n_avl_clk,
	reset_n_scc_clk,	
	scc_data,
	scc_upd,
	scc_dq_ena,
	scc_dqs_ena,
	scc_dqs_io_ena,
	scc_dm_ena,
	capture_strobe_tracking,
	
	pll_afi_clk,
	reset_n,
	seq_mux_address,
	seq_mux_bank,
	seq_mux_cs_n,
	seq_mux_cke,
	seq_mux_odt,
	seq_mux_ras_n,
	seq_mux_cas_n,
	seq_mux_we_n,
	seq_mux_dqs_en,
	seq_mux_reset_n,
	seq_mux_wdata,
	seq_mux_wdata_valid,
	seq_mux_dm,
	seq_mux_rdata_en,
	mux_seq_rdata,
	mux_seq_read_fifo_q,
	mux_seq_rdata_valid,
	mux_sel,
	seq_read_latency_counter,
	seq_read_increment_vfifo_fr,
	seq_read_increment_vfifo_hr,
	seq_read_increment_vfifo_qr,
	afi_rlat,
	afi_wlat,



	afi_cal_success,
	afi_cal_fail,
	afi_cal_debug_info,
    afi_ctl_refresh_done,
	afi_ctl_long_idle,
	afi_seq_busy,
	seq_reset_mem_stable,
	seq_read_fifo_reset,
	seq_calib_init
);

// ******************************************************************************************************************************** 
// BEGIN PARAMETER SECTION
// All parameters default to "" will have their values passed in from higher level wrapper with the controller and driver 


// PHY-Memory Interface
// Memory device specific parameters, they are set according to the memory spec
parameter MEM_ADDRESS_WIDTH     = ""; 
parameter MEM_BANK_WIDTH        = ""; 
parameter MEM_CLK_EN_WIDTH 		= ""; 
parameter MEM_ODT_WIDTH			= ""; 
parameter MEM_NUMBER_OF_RANKS = "";
parameter MEM_MIRROR_ADDRESSING = "";
parameter MEM_CHIP_SELECT_WIDTH = ""; 
parameter MEM_CONTROL_WIDTH     = ""; 
parameter MEM_DM_WIDTH          = ""; 
parameter MEM_DQ_WIDTH          = ""; 
parameter MEM_READ_DQS_WIDTH    = ""; 
parameter MEM_WRITE_DQS_WIDTH   = "";
parameter DELAY_PER_OPA_TAP   = "";
parameter DELAY_PER_DCHAIN_TAP   = "";
parameter DLL_DELAY_CHAIN_LENGTH 	= "";



// PHY-Controller (AFI) Interface
// The AFI interface widths are derived from the memory interface widths based on full/half rate operations
// The calculations are done on higher level wrapper
parameter AFI_ADDRESS_WIDTH         = ""; 
parameter AFI_DEBUG_INFO_WIDTH = "";
parameter AFI_BANK_WIDTH            = ""; 
parameter AFI_CHIP_SELECT_WIDTH     = ""; 
parameter AFI_CLK_EN_WIDTH 			= ""; 
parameter AFI_ODT_WIDTH				= ""; 
parameter AFI_MAX_WRITE_LATENCY_COUNT_WIDTH	= "";
parameter AFI_MAX_READ_LATENCY_COUNT_WIDTH	= "";
parameter AFI_DATA_MASK_WIDTH       = ""; 
parameter AFI_CONTROL_WIDTH         = ""; 
parameter AFI_DATA_WIDTH            = ""; 
parameter AFI_DQS_WIDTH				= "";



// Read Datapath
parameter MAX_LATENCY_COUNT_WIDTH       = "";	// calibration finds the best latency by reducing the maximum latency  
parameter MAX_READ_LATENCY              = ""; 
parameter READ_VALID_TIMEOUT_WIDTH		= ""; 
parameter READ_VALID_FIFO_SIZE			= "";

// Write Datapath
// The sequencer uses this value to control write latency during calibration
parameter MAX_WRITE_LATENCY_COUNT_WIDTH = "";

// Initialization Sequence
parameter INIT_COUNT_WIDTH		= "";
parameter MEM_TINIT_CK = "";
parameter MEM_TMRD_CK = "";
parameter INIT_NOP_COUNT_WIDTH	= 8;
parameter MRD_COUNT_WIDTH		= 2;
parameter MR0_BL				= "";
parameter MR0_BT				= "";
parameter MR0_CAS_LATENCY		= "";
parameter MR0_WR				= "";
parameter MR0_PD				= "";
parameter MR1_DLL				= "";
parameter MR1_ODS				= "";
parameter MR1_RTT				= "";
parameter MR1_AL				= "";
parameter MR1_QOFF				= "";
parameter RDIMM					= "";
parameter RESET_COUNT_WIDTH 	= 18;
parameter CLK_DIS_COUNT_WIDTH 	= 3;
parameter MOD_COUNT_WIDTH		= 4;
parameter ZQINIT_COUNT_WIDTH 	= 9;
parameter MR0_DLL				= "";
parameter MR1_WL				= "";
parameter MR1_TDQS				= "";
parameter MR2_CWL				= "";
parameter MR2_ASR				= "";
parameter MR2_SRT				= "";
parameter MR2_RTT_WR			= "";
parameter MR3_MPR_RF			= "";
parameter MR3_MPR				= "";
parameter RDIMM_CONFIG = 64'h0;
parameter MEM_BURST_LENGTH      = "";
parameter MEM_T_WL              = "";
parameter MEM_T_RL				= "";

// The sequencer issues back-to-back reads during calibration, NOPs may need to be inserted depending on the burst length
parameter SEQ_BURST_COUNT_WIDTH = "";

// Width of the counter used to determine the number of cycles required
// to calculate if the rddata pattern is all 0 or all 1.
parameter VCALIB_COUNT_WIDTH    = "";

// Width of the calibration status register used to control calibration skipping.
parameter CALIB_REG_WIDTH		= "";

// local parameters
localparam AFI_DQ_GROUP_DATA_WIDTH = AFI_DATA_WIDTH / MEM_READ_DQS_WIDTH;

// The default VFIFO and LFIFO settings used in skip calibration mode
parameter CALIB_VFIFO_OFFSET	= "";
parameter CALIB_LFIFO_OFFSET	= "";


// END PARAMETER SECTION
// ******************************************************************************************************************************** 


// ******************************************************************************************************************************** 
// BEGIN PORT SECTION

input	pll_config_clk;
input	pll_avl_clk;

input	reset_n_avl_clk;
input	reset_n_scc_clk;
output	scc_data;
output	scc_upd;
output	[MEM_DQ_WIDTH-1:0] scc_dq_ena;
output	[MEM_READ_DQS_WIDTH-1:0] scc_dqs_ena;
output	[MEM_READ_DQS_WIDTH-1:0] scc_dqs_io_ena;
output	[MEM_DM_WIDTH-1:0] scc_dm_ena;
input	[MEM_READ_DQS_WIDTH-1:0] capture_strobe_tracking;

input	pll_afi_clk;
input	reset_n;


// sequencer version of the AFI interface
output	[AFI_ADDRESS_WIDTH-1:0] seq_mux_address;
output	[AFI_BANK_WIDTH-1:0]    seq_mux_bank;
output	[AFI_CHIP_SELECT_WIDTH-1:0] seq_mux_cs_n;
output	[AFI_CLK_EN_WIDTH-1:0] seq_mux_cke;
output	[AFI_ODT_WIDTH-1:0] seq_mux_odt;
output	[AFI_CONTROL_WIDTH-1:0] seq_mux_ras_n;
output	[AFI_CONTROL_WIDTH-1:0] seq_mux_cas_n;
output	[AFI_CONTROL_WIDTH-1:0] seq_mux_we_n;
output	[AFI_DQS_WIDTH-1:0] 	seq_mux_dqs_en;
output	[AFI_CONTROL_WIDTH-1:0] seq_mux_reset_n;

output  [AFI_DATA_WIDTH-1:0]    seq_mux_wdata;
output  [AFI_DQS_WIDTH-1:0]		seq_mux_wdata_valid;
output  [AFI_DATA_MASK_WIDTH-1:0]   seq_mux_dm;

output  seq_mux_rdata_en;

// signals between the sequencer and the read datapath
input	[AFI_DATA_WIDTH-1:0]    mux_seq_rdata;	// read data from read datapath, thru sequencer, back to AFI
input	mux_seq_rdata_valid; // read data valid from read datapath, thru sequencer, back to AFI

// read data (no reordering) for indepedently FIFO calibrations (multiple FIFOs for multiple DQS groups)
input	[AFI_DATA_WIDTH-1:0]	mux_seq_read_fifo_q; 

output	mux_sel;

// sequencer outputs to controller AFI interface
output  [AFI_MAX_WRITE_LATENCY_COUNT_WIDTH-1:0] afi_wlat;
output  [AFI_MAX_READ_LATENCY_COUNT_WIDTH-1:0]  afi_rlat;
output	afi_cal_success;
output [AFI_DEBUG_INFO_WIDTH - 1:0] afi_cal_debug_info;
output	afi_cal_fail;




// hold reset in the read capture clock domain until memory is stable
output	seq_reset_mem_stable;

// reset the read and write pointers of the data resynchronization FIFO in the read datapath 
output	[MEM_READ_DQS_WIDTH-1:0] seq_read_fifo_reset;

// read latency counter value from sequencer to inform read datapath when valid data should be read
output	[MAX_LATENCY_COUNT_WIDTH-1:0] seq_read_latency_counter;

// controls from sequencer to read datapath to calibration the valid prediction FIFO pointer offsets
output	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_fr; // increment valid prediction FIFO write pointer by an extra full rate cycle	
output	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_hr; // increment valid prediction FIFO write pointer by an extra half rate cycle
															  // in full rate core, both will mean an extra full rate cycle
output	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_qr;

input	[CALIB_REG_WIDTH-1:0] seq_calib_init;

input   [MEM_CHIP_SELECT_WIDTH-1:0] afi_ctl_refresh_done;
input   [MEM_CHIP_SELECT_WIDTH-1:0] afi_ctl_long_idle;
output  [MEM_CHIP_SELECT_WIDTH-1:0] afi_seq_busy;

assign  afi_seq_busy    =   {MEM_CHIP_SELECT_WIDTH{1'b0}};


assign seq_read_increment_vfifo_qr = {MEM_READ_DQS_WIDTH{1'b0}};

ddr3_s4_uniphy_p0_qsys_sequencer sequencer_inst (
	.scc_upd (scc_upd),
	.scc_dqs_io_ena (scc_dqs_io_ena),
	.scc_data (scc_data),
	.scc_dqs_ena (scc_dqs_ena),
	.reset_n_scc_clk (reset_n_scc_clk),
	.scc_clk (pll_config_clk),
	.scc_dq_ena (scc_dq_ena),
	.scc_dm_ena (scc_dm_ena),
	.capture_strobe_tracking (capture_strobe_tracking),
	.reset_reset_n (reset_n_avl_clk),
	.clock_clk (pll_avl_clk),
	.phy_cal_fail (afi_cal_fail),
	.phy_clk (pll_afi_clk),
	.phy_read_increment_vfifo_fr (seq_read_increment_vfifo_fr),
	.phy_read_fifo_reset (seq_read_fifo_reset),
	.phy_mux_sel (mux_sel),
	.phy_cal_debug_info (afi_cal_debug_info),
	.phy_reset_mem_stable (seq_reset_mem_stable),
	.phy_read_increment_vfifo_hr (seq_read_increment_vfifo_hr),
	.phy_reset_n (reset_n),
	.phy_read_latency_counter (seq_read_latency_counter),
	.phy_afi_wlat (afi_wlat),
	.phy_afi_rlat (afi_rlat),
	.phy_vfifo_rd_en_override (),
	.phy_cal_success (afi_cal_success),
	.calib_skip_steps (seq_calib_init),
	.afi_clk (pll_afi_clk),
	.afi_reset_n (reset_n),
	.afi_address (seq_mux_address),
	.afi_bank (seq_mux_bank),
	.afi_cs_n (seq_mux_cs_n),
	.afi_cke (seq_mux_cke),
	.afi_odt (seq_mux_odt),
	.afi_ras_n (seq_mux_ras_n),
	.afi_cas_n (seq_mux_cas_n),
	.afi_we_n (seq_mux_we_n),
	.afi_dqs_en (seq_mux_dqs_en),
	.afi_mem_reset_n (seq_mux_reset_n),
	.afi_wdata (seq_mux_wdata),
	.afi_wdata_valid (seq_mux_wdata_valid),
	.afi_dm (seq_mux_dm),
	.afi_rdata_en (seq_mux_rdata_en),
	.afi_rdata (mux_seq_rdata),
	.afi_rdata_valid (mux_seq_rdata_valid)
);
endmodule
