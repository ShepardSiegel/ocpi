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





(* altera_attribute = "-name FITTER_ADJUST_HC_SHORT_PATH_GUARDBAND 100" *)
module ddr3_s4_uniphy_example_if0_p0_controller_phy (
    global_reset_n,
    soft_reset_n,
	reset_request_n,
	ctl_reset_n,
	oct_rdn,
	oct_rup,
    parallelterminationcontrol,
    seriesterminationcontrol,
	pll_ref_clk,
	pll_afi_clk,
	pll_mem_clk,
	pll_write_clk,
	pll_addr_cmd_clk,
	pll_afi_half_clk,
	pll_avl_clk,
	pll_config_clk,
	pll_locked,
	dll_delayctrl,
	afi_clk,
	afi_half_clk,
	afi_addr,
	afi_cke,
	afi_cs_n,
	afi_ba,
	afi_cas_n,
	afi_ras_n,
	afi_we_n,
	afi_odt,
	afi_rst_n,
	afi_mem_clk_disable,
	afi_dqs_burst,
	afi_wlat,
	afi_rlat,
    afi_wdata,
    afi_wdata_valid,
    afi_dm,
    afi_rdata,
    afi_rdata_en,
    afi_rdata_en_full,
    afi_rdata_valid,
	afi_cal_debug_info,
    afi_cal_success,
    afi_cal_fail,
	mem_a,
	mem_ba,
	mem_ck,
	mem_ck_n,
	mem_cke,
	mem_cs_n,
	mem_dm,
	mem_odt,
	mem_ras_n,
	mem_cas_n,
	mem_we_n,
	mem_reset_n,
	mem_dq,
	mem_dqs,
	mem_dqs_n
);


// ******************************************************************************************************************************** 
// BEGIN PARAMETER SECTION
// All parameters default to "" will have their values passed in from higher level wrapper with the controller and driver. 
parameter DEVICE_FAMILY = "Stratix IV";

// On-chip termination
parameter OCT_TERM_CONTROL_WIDTH   = 14;

// PHY-Memory Interface
// Memory device specific parameters, they are set according to the memory spec.
parameter MEM_ADDRESS_WIDTH		= 13;
parameter MEM_DQS_WIDTH			= 2;
parameter MEM_BANK_WIDTH        = 3;
parameter MEM_CHIP_SELECT_WIDTH = 1;
parameter MEM_CLK_EN_WIDTH		= 1;
parameter MEM_CK_WIDTH			= 1;
parameter MEM_ODT_WIDTH			= 1;
parameter MEM_DM_WIDTH         	= 2;
parameter MEM_CONTROL_WIDTH    	= 1; 
parameter MEM_DQ_WIDTH         	= 16;
parameter MEM_READ_DQS_WIDTH   	= 2; 
parameter MEM_WRITE_DQS_WIDTH  	= 2;

// PHY-Controller (AFI) Interface
// The AFI interface widths are derived from the memory interface widths based on full/half rate operations.
// The calculations are done on higher level wrapper.
parameter AFI_ADDRESS_WIDTH         = 26; 
parameter AFI_BANK_WIDTH            = 6;
parameter AFI_CHIP_SELECT_WIDTH     = 2;
parameter AFI_CLK_EN_WIDTH			= 2;
parameter AFI_ODT_WIDTH				= 2;
parameter AFI_WLAT_WIDTH			= 6;
parameter AFI_RLAT_WIDTH			= 6;
parameter AFI_DATA_MASK_WIDTH       = 8; 
parameter AFI_CONTROL_WIDTH         = 2; 
parameter AFI_DATA_WIDTH            = 64; 
parameter AFI_WRITE_DQS_WIDTH       = 4;

// DLL Interface
parameter DLL_DELAY_CTRL_WIDTH	= 6;

parameter NUM_SUBGROUP_PER_READ_DQS        = 1;
parameter QVLD_EXTRA_FLOP_STAGES		   = 0;
parameter QVLD_WR_ADDRESS_OFFSET		   = 5;
	
// Read Datapath parameters, the values should not be changed unless the intention is to change the architecture.
// Read valid prediction FIFO
parameter READ_VALID_FIFO_SIZE             = 16;

// Data resynchronization FIFO
parameter READ_FIFO_SIZE                   = 8;

// Read valid prediction parameters
//This should really be log2(READ_VALID_FIFO_SIZE)
localparam READ_VALID_TIMEOUT_WIDTH		   = 8; // calibration fails when the timeout counter expires 

// Latency calibration parameters
parameter MAX_LATENCY_COUNT_WIDTH		   = 5; // calibration finds the best latency by reducing the maximum latency
localparam MAX_READ_LATENCY				   = 2**MAX_LATENCY_COUNT_WIDTH; 

// Write Datapath
// The sequencer uses this value to control write latency during calibration
parameter MAX_WRITE_LATENCY_COUNT_WIDTH = 4;
parameter NUM_WRITE_PATH_FLOP_STAGES    = 0;

// Address/Command Datapath
parameter NUM_AC_FR_CYCLE_SHIFTS = 0;

// Initialization Sequence
// The init counter is used to maintain the stable condition wait time required by the memory protocol
localparam INIT_COUNT_WIDTH      = 19;


parameter MEM_TINIT_CK							= 175000;
parameter MEM_TMRD_CK							= 4;
parameter RDIMM										= 0;
parameter MR0_BL                              	= 1;
parameter MR0_BT                              	= 0;
parameter MR0_CAS_LATENCY                     	= 3;
parameter MR0_DLL                             	= 1;
parameter MR0_WR                              	= 2;
parameter MR0_PD                              	= 0;
parameter MR1_DLL                             	= 0;
parameter MR1_ODS                             	= 0;
parameter MR1_RTT                             	= 0;
parameter MR1_AL                              	= 0;
parameter MR1_WL                              	= 0;
parameter MR1_TDQS                            	= 0;
parameter MR1_QOFF                            	= 0;
parameter MR2_CWL                             	= 1;
parameter MR2_ASR                             	= 0;
parameter MR2_SRT                             	= 0;
parameter MR2_RTT_WR                          	= 0;
parameter MR3_MPR_RF                          	= 0;
parameter MR3_MPR                             	= 0;
parameter RDIMM_CONFIG                        	= 0;
parameter MEM_BURST_LENGTH						= 8;
parameter MEM_T_WL								= 5;


localparam MEM_T_RL								= 7;

// The sequencer issues back-to-back reads during calibration, NOPs may need to be inserted depending on the burst length
parameter SEQ_BURST_COUNT_WIDTH = 1;

parameter VCALIB_COUNT_WIDTH = 2;

parameter DELAY_PER_OPA_TAP 					= 285;
parameter DELAY_PER_DCHAIN_TAP 				= 50;
parameter DLL_DELAY_CHAIN_LENGTH 			= 10;
parameter MEM_NUMBER_OF_RANKS 				= 1;
parameter MEM_MIRROR_ADDRESSING 				= 0;

// The DLL offset control width
parameter DLL_OFFSET_CTRL_WIDTH = 6;

// The PLL Phase counter width
parameter PLL_PHASE_COUNTER_WIDTH = 4;

parameter ALTDQDQS_INPUT_FREQ = 350.0;
parameter ALTDQDQS_DELAY_CHAIN_BUFFER_MODE = "HIGH";
parameter ALTDQDQS_DQS_PHASE_SETTING = 2;
parameter ALTDQDQS_DQS_PHASE_SHIFT = 7200;
parameter ALTDQDQS_DELAYED_CLOCK_PHASE_SETTING = 2;
parameter CALIB_VFIFO_OFFSET = 14;
parameter CALIB_LFIFO_OFFSET = 5;
parameter AFI_DEBUG_INFO_WIDTH = 32;
parameter REF_CLK_FREQ       = "125.0 MHz";
parameter AFI_CLK_FREQ       = "175.0 MHz";
parameter MEM_CLK_FREQ       = "350.0 MHz";
parameter WRITE_CLK_FREQ     = "350.0 MHz";
parameter ADDR_CMD_CLK_FREQ  = "175.0 MHz";
parameter AFI_HALF_CLK_FREQ  = "87.5 MHz";
parameter AVL_CLK_FREQ       = "87.5 MHz";
parameter CONFIG_CLK_FREQ    = "21.875 MHz";

parameter AFI_CLK_PHASE      = "0 ps";
parameter MEM_CLK_PHASE      = "0 ps";
parameter WRITE_CLK_PHASE    = "714 ps";
parameter ADDR_CMD_CLK_PHASE = "4286 ps";
parameter AFI_HALF_CLK_PHASE = "0 ps";
parameter AVL_CLK_PHASE      = "0 ps";
parameter CONFIG_CLK_PHASE   = "0 ps";
parameter CALIB_REG_WIDTH = 8;


// END PARAMETER SECTION
// ******************************************************************************************************************************** 


// ******************************************************************************************************************************** 
// BEGIN PORT SECTION


input	pll_ref_clk;		// PLL reference clock

// When the PHY is selected to be a PLL/DLL MASTER, the PLL and DLL are instantied on this top level
output	pll_afi_clk;		// See pll_memphy instantiation below for detailed description of each clock
output	pll_mem_clk;	
output	pll_write_clk;
output	pll_addr_cmd_clk;
output	pll_afi_half_clk;
output	pll_avl_clk;
output	pll_config_clk;
output	pll_locked;
output	[DLL_DELAY_CTRL_WIDTH-1:0]  dll_delayctrl;



// Reset Interface, AFI 2.0
input   global_reset_n;		// Resets (active-low) the whole system (all PHY logic + PLL)
input	soft_reset_n;		// Resets (active-low) PHY logic only, PLL is NOT reset
output	reset_request_n;	// When 1, PLL is out of lock
output	ctl_reset_n;		// Asynchronously asserted and synchronously de-asserted on afi_clk domain
							// should be used to reset system level afi_clk domain logic

// On-Chip Termination
// These should be connected to reference resistance pins on the board, via OCT control block if instantiated by user
input   oct_rdn;
input   oct_rup;
// for OCT master, termination control signals will be available to top level
output [OCT_TERM_CONTROL_WIDTH-1:0] parallelterminationcontrol;
output [OCT_TERM_CONTROL_WIDTH-1:0] seriesterminationcontrol;

// PHY-Controller Interface, AFI 2.0
// Control Interface
input   [AFI_ADDRESS_WIDTH-1:0] afi_addr;		// address



input   [AFI_CLK_EN_WIDTH-1:0]	afi_cke;
input   [AFI_CHIP_SELECT_WIDTH-1:0]	afi_cs_n;
input   [AFI_BANK_WIDTH-1:0]	afi_ba;
input   [AFI_CONTROL_WIDTH-1:0]	afi_cas_n;
input   [AFI_CONTROL_WIDTH-1:0]	afi_ras_n;
input   [AFI_CONTROL_WIDTH-1:0]	afi_we_n;
input   [AFI_ODT_WIDTH-1:0]	afi_odt;
input   [AFI_CONTROL_WIDTH-1:0]	afi_rst_n;
input   afi_mem_clk_disable;
input   [AFI_WRITE_DQS_WIDTH-1:0]	afi_dqs_burst;
output	[AFI_WLAT_WIDTH-1:0]	afi_wlat;
output	[AFI_RLAT_WIDTH-1:0]	afi_rlat;


// Write data interface
input   [AFI_DATA_WIDTH-1:0]    afi_wdata;				// write data
input	[AFI_WRITE_DQS_WIDTH-1:0]	afi_wdata_valid;			// write data valid, used to maintain write latency required by protocol spec
input   [AFI_DATA_MASK_WIDTH-1:0]   afi_dm;				// write data mask

// Read data interface
output  [AFI_DATA_WIDTH-1:0]    afi_rdata;				// read data				
input   afi_rdata_en;		// read enable, used to maintain the read latency calibrated by PHY
input   afi_rdata_en_full;		// read enable full burst, used to create DQS enable
output  afi_rdata_valid;// read data valid

// Status interface
output [AFI_DEBUG_INFO_WIDTH - 1:0] afi_cal_debug_info;
output  afi_cal_success;	// calibration success
output  afi_cal_fail;		// calibration failure



// PHY-Memory Interface



output	[MEM_ADDRESS_WIDTH-1:0]	mem_a;
output  [MEM_BANK_WIDTH-1:0]	mem_ba;
output	[MEM_CK_WIDTH-1:0]	mem_ck;
output	[MEM_CK_WIDTH-1:0]	mem_ck_n;
output	[MEM_CLK_EN_WIDTH-1:0]	mem_cke;
output	[MEM_CHIP_SELECT_WIDTH-1:0]	mem_cs_n;
output	[MEM_DM_WIDTH-1:0]	mem_dm;
output	[MEM_ODT_WIDTH-1:0]	mem_odt;
output	[MEM_CONTROL_WIDTH-1:0]	mem_ras_n;
output	[MEM_CONTROL_WIDTH-1:0]	mem_cas_n;
output	[MEM_CONTROL_WIDTH-1:0]	mem_we_n;
output	mem_reset_n;
inout   [MEM_DQ_WIDTH-1:0]  mem_dq;
inout	[MEM_DQS_WIDTH-1:0]	mem_dqs;
inout	[MEM_DQS_WIDTH-1:0]	mem_dqs_n;




// PLL Interface
output	afi_clk;
output	afi_half_clk;

wire	pll_dqs_ena_clk;
wire	seq_clk;






ddr3_s4_uniphy_example_if0_p0_memphy_top #(
	.OCT_TERM_CONTROL_WIDTH(OCT_TERM_CONTROL_WIDTH),
	.MEM_ADDRESS_WIDTH(MEM_ADDRESS_WIDTH),
	.MEM_DQS_WIDTH(MEM_DQS_WIDTH),
	.MEM_BANK_WIDTH(MEM_BANK_WIDTH),
	.MEM_CHIP_SELECT_WIDTH(MEM_CHIP_SELECT_WIDTH),
	.MEM_CLK_EN_WIDTH(MEM_CLK_EN_WIDTH),
	.MEM_CK_WIDTH(MEM_CK_WIDTH),
	.MEM_ODT_WIDTH(MEM_ODT_WIDTH),
	.MEM_DM_WIDTH(MEM_DM_WIDTH),
	.MEM_CONTROL_WIDTH(MEM_CONTROL_WIDTH),
	.MEM_DQ_WIDTH(MEM_DQ_WIDTH),
	.MEM_READ_DQS_WIDTH(MEM_READ_DQS_WIDTH),
	.MEM_WRITE_DQS_WIDTH(MEM_WRITE_DQS_WIDTH),
	.AFI_ADDRESS_WIDTH(AFI_ADDRESS_WIDTH),
	.AFI_BANK_WIDTH(AFI_BANK_WIDTH),
	.AFI_CHIP_SELECT_WIDTH(AFI_CHIP_SELECT_WIDTH),
	.AFI_CLK_EN_WIDTH(AFI_CLK_EN_WIDTH),
	.AFI_ODT_WIDTH(AFI_ODT_WIDTH),
	.AFI_WLAT_WIDTH(AFI_WLAT_WIDTH),
	.AFI_RLAT_WIDTH(AFI_RLAT_WIDTH),
	.AFI_DATA_MASK_WIDTH(AFI_DATA_MASK_WIDTH),
	.AFI_CONTROL_WIDTH(AFI_CONTROL_WIDTH),
	.AFI_DATA_WIDTH(AFI_DATA_WIDTH),
	.AFI_WRITE_DQS_WIDTH(AFI_WRITE_DQS_WIDTH),
	.DLL_DELAY_CTRL_WIDTH(DLL_DELAY_CTRL_WIDTH),
	.NUM_SUBGROUP_PER_READ_DQS(NUM_SUBGROUP_PER_READ_DQS),
	.QVLD_EXTRA_FLOP_STAGES(QVLD_EXTRA_FLOP_STAGES),
	.QVLD_WR_ADDRESS_OFFSET(QVLD_WR_ADDRESS_OFFSET),
	.NUM_AC_FR_CYCLE_SHIFTS(NUM_AC_FR_CYCLE_SHIFTS),
	.READ_FIFO_SIZE(READ_FIFO_SIZE),
	.MAX_WRITE_LATENCY_COUNT_WIDTH(MAX_WRITE_LATENCY_COUNT_WIDTH),
	.NUM_WRITE_PATH_FLOP_STAGES(NUM_WRITE_PATH_FLOP_STAGES),
	.MEM_TINIT_CK(MEM_TINIT_CK),
	.MEM_TMRD_CK(MEM_TMRD_CK),
	.RDIMM(RDIMM),
	.MR0_BL(MR0_BL),
	.MR0_BT(MR0_BT),
	.MR0_CAS_LATENCY(MR0_CAS_LATENCY),
	.MR0_DLL(MR0_DLL),
	.MR0_WR(MR0_WR),
	.MR0_PD(MR0_PD),
	.MR1_DLL(MR1_DLL),
	.MR1_ODS(MR1_ODS),
	.MR1_RTT(MR1_RTT),
	.MR1_AL(MR1_AL),
	.MR1_WL(MR1_WL),
	.MR1_TDQS(MR1_TDQS),
	.MR1_QOFF(MR1_QOFF),
	.MR2_CWL(MR2_CWL),
	.MR2_ASR(MR2_ASR),
	.MR2_SRT(MR2_SRT),
	.MR2_RTT_WR(MR2_RTT_WR),
	.MR3_MPR_RF(MR3_MPR_RF),
	.MR3_MPR(MR3_MPR),
	.RDIMM_CONFIG(RDIMM_CONFIG),
	.MEM_BURST_LENGTH(MEM_BURST_LENGTH),
	.MEM_T_WL(MEM_T_WL),
	.MEM_T_RL(MEM_T_RL),
	.SEQ_BURST_COUNT_WIDTH(SEQ_BURST_COUNT_WIDTH),
	.VCALIB_COUNT_WIDTH(VCALIB_COUNT_WIDTH),
	.DELAY_PER_OPA_TAP(DELAY_PER_OPA_TAP),
	.DELAY_PER_DCHAIN_TAP(DELAY_PER_DCHAIN_TAP),
	.DLL_DELAY_CHAIN_LENGTH(DLL_DELAY_CHAIN_LENGTH),
	.MEM_NUMBER_OF_RANKS(MEM_NUMBER_OF_RANKS),
	.MEM_MIRROR_ADDRESSING(MEM_MIRROR_ADDRESSING),
	.DLL_OFFSET_CTRL_WIDTH(DLL_OFFSET_CTRL_WIDTH),
	.PLL_PHASE_COUNTER_WIDTH(PLL_PHASE_COUNTER_WIDTH),
	.ALTDQDQS_INPUT_FREQ(ALTDQDQS_INPUT_FREQ),
	.ALTDQDQS_DELAY_CHAIN_BUFFER_MODE(ALTDQDQS_DELAY_CHAIN_BUFFER_MODE),
	.ALTDQDQS_DQS_PHASE_SETTING(ALTDQDQS_DQS_PHASE_SETTING),
	.ALTDQDQS_DQS_PHASE_SHIFT(ALTDQDQS_DQS_PHASE_SHIFT),
	.ALTDQDQS_DELAYED_CLOCK_PHASE_SETTING(ALTDQDQS_DELAYED_CLOCK_PHASE_SETTING),
	.CALIB_VFIFO_OFFSET(CALIB_VFIFO_OFFSET),
	.CALIB_LFIFO_OFFSET(CALIB_LFIFO_OFFSET),
	.AFI_DEBUG_INFO_WIDTH(AFI_DEBUG_INFO_WIDTH),
	.REF_CLK_FREQ(REF_CLK_FREQ),
	.AFI_CLK_FREQ(AFI_CLK_FREQ),
	.MEM_CLK_FREQ(MEM_CLK_FREQ),
	.WRITE_CLK_FREQ(WRITE_CLK_FREQ),
	.ADDR_CMD_CLK_FREQ(ADDR_CMD_CLK_FREQ),
	.AFI_HALF_CLK_FREQ(AFI_HALF_CLK_FREQ),
	.AVL_CLK_FREQ(AVL_CLK_FREQ),
	.CONFIG_CLK_FREQ(CONFIG_CLK_FREQ),
	.AFI_CLK_PHASE(AFI_CLK_PHASE),
	.MEM_CLK_PHASE(MEM_CLK_PHASE),
	.WRITE_CLK_PHASE(WRITE_CLK_PHASE),
	.ADDR_CMD_CLK_PHASE(ADDR_CMD_CLK_PHASE),
	.AFI_HALF_CLK_PHASE(AFI_HALF_CLK_PHASE),
	.AVL_CLK_PHASE(AVL_CLK_PHASE),
	.CONFIG_CLK_PHASE(CONFIG_CLK_PHASE),
	.CALIB_REG_WIDTH(CALIB_REG_WIDTH),
	.DEVICE_FAMILY(DEVICE_FAMILY)
) memphy_top_inst (
	.pll_ref_clk(pll_ref_clk),
	.pll_afi_clk(pll_afi_clk),
	.pll_mem_clk(pll_mem_clk),
	.pll_write_clk(pll_write_clk),
	.pll_addr_cmd_clk(pll_addr_cmd_clk),
	.pll_afi_half_clk(pll_afi_half_clk),
	.pll_avl_clk(pll_avl_clk),
	.pll_config_clk(pll_config_clk),
	.pll_locked(pll_locked),
	.dll_delayctrl(dll_delayctrl),
	.global_reset_n(global_reset_n),
	.soft_reset_n(soft_reset_n),
	.reset_request_n(reset_request_n),
	.ctl_reset_n(ctl_reset_n),
	.oct_rdn(oct_rdn),
	.oct_rup(oct_rup),
	.parallelterminationcontrol(parallelterminationcontrol),
	.seriesterminationcontrol(seriesterminationcontrol),
	.afi_addr(afi_addr),
	.afi_cke(afi_cke),
	.afi_cs_n(afi_cs_n),
	.afi_ba(afi_ba),
	.afi_cas_n(afi_cas_n),
	.afi_ras_n(afi_ras_n),
	.afi_we_n(afi_we_n),
	.afi_odt(afi_odt),
	.afi_rst_n(afi_rst_n),
	.afi_mem_clk_disable(afi_mem_clk_disable),
	.afi_dqs_burst(afi_dqs_burst),
	.afi_wlat(afi_wlat),
	.afi_rlat(afi_rlat),
	.afi_wdata(afi_wdata),
	.afi_wdata_valid(afi_wdata_valid),
	.afi_dm(afi_dm),
	.afi_rdata(afi_rdata),
	.afi_rdata_en(afi_rdata_en),
	.afi_rdata_en_full(afi_rdata_en_full),
	.afi_rdata_valid(afi_rdata_valid),
	.afi_cal_debug_info(afi_cal_debug_info),
	.afi_cal_success(afi_cal_success),
	.afi_cal_fail(afi_cal_fail),
	.mem_a(mem_a),
	.mem_ba(mem_ba),
	.mem_ck(mem_ck),
	.mem_ck_n(mem_ck_n),
	.mem_cke(mem_cke),
	.mem_cs_n(mem_cs_n),
	.mem_dm(mem_dm),
	.mem_odt(mem_odt),
	.mem_ras_n(mem_ras_n),
	.mem_cas_n(mem_cas_n),
	.mem_we_n(mem_we_n),
	.mem_reset_n(mem_reset_n),
	.mem_dq(mem_dq),
	.mem_dqs(mem_dqs),
	.mem_dqs_n(mem_dqs_n),
	.afi_clk(afi_clk),
	.afi_half_clk(afi_half_clk)
);




endmodule

