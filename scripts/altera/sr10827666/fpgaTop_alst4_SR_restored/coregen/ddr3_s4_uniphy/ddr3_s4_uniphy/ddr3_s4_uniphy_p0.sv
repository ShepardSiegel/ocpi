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


(* altera_attribute = "-name IP_TOOL_NAME altera_mem_if_ddr3_phy; -name IP_TOOL_VERSION 11.0; -name FITTER_ADJUST_HC_SHORT_PATH_GUARDBAND 100" *)
module ddr3_s4_uniphy_p0 (
    global_reset_n,
    soft_reset_n,
	oct_rdn,
	oct_rup,
    parallelterminationcontrol,
    seriesterminationcontrol,
	pll_ref_clk,
	pll_afi_half_clk,
	pll_afi_clk,
	pll_mem_clk,
	pll_write_clk,
	pll_addr_cmd_clk,
	pll_avl_clk,
	pll_config_clk,
	pll_locked,
	dll_delayctrl,
	afi_reset_n,
	afi_half_clk,
	afi_clk,
	afi_addr,
	afi_ba,
	afi_cke,
	afi_cs_n,
	afi_ras_n,
	afi_we_n,
	afi_cas_n,
	afi_rst_n,
	afi_odt,
	afi_dqs_burst,
	afi_wdata_valid,
	afi_wdata,
	afi_dm,
	afi_rdata_en,
	afi_rdata_en_full,
	afi_rdata,
	afi_rdata_valid,
	afi_cal_success,
	afi_cal_fail,
	afi_cal_req,
	afi_wlat,
	afi_rlat,
	mem_a,
	mem_ba,
	mem_ck,
	mem_ck_n,
	mem_cke,
	mem_cs_n,
	mem_dm,
	mem_ras_n,
	mem_cas_n,
	mem_we_n,
	mem_dq,
	mem_dqs,
	mem_dqs_n,
	mem_reset_n,
	mem_odt
);


parameter DEVICE_FAMILY = "Stratix IV";

parameter OCT_TERM_CONTROL_WIDTH   = 14;

parameter MEM_IF_ADDR_WIDTH			= 13;
parameter MEM_IF_BANKADDR_WIDTH     = 3;
parameter MEM_IF_CK_WIDTH			= 1;
parameter MEM_IF_CLK_EN_WIDTH		= 1;
parameter MEM_IF_CS_WIDTH			= 1;
parameter MEM_IF_DM_WIDTH         	= 2;
parameter MEM_IF_CONTROL_WIDTH    	= 1; 
parameter MEM_IF_DQ_WIDTH         	= 16;
parameter MEM_IF_DQS_WIDTH         	= 2;
parameter MEM_IF_ODT_WIDTH         	= 1;

parameter AFI_ADDR_WIDTH 	        = 26; 
parameter AFI_DM_WIDTH 	        	= 8; 
parameter AFI_BANKADDR_WIDTH        = 6; 
parameter AFI_CS_WIDTH				= 2;
parameter AFI_CONTROL_WIDTH         = 2; 
parameter AFI_DQ_WIDTH				= 64; 
parameter AFI_WRITE_DQS_WIDTH		= 4;
parameter AFI_RATE_RATIO			= 2;
parameter AFI_RLAT_WIDTH			= 6;
parameter AFI_WLAT_WIDTH			= 6;

parameter DLL_DELAY_CTRL_WIDTH	= 6;

parameter NUM_SUBGROUP_PER_READ_DQS        = 1;
parameter QVLD_EXTRA_FLOP_STAGES		   = 0;
parameter QVLD_WR_ADDRESS_OFFSET		   = 5;
	
parameter READ_FIFO_SIZE                   = 8;

localparam MAX_WRITE_LATENCY_COUNT_WIDTH = 4;
parameter NUM_WRITE_PATH_FLOP_STAGES    = 0;

parameter NUM_AC_FR_CYCLE_SHIFTS = 0;

parameter MEM_TINIT_CK							= 175000;
parameter MEM_TMRD_CK							= 4;
parameter RDIMM_INT								= 0;
parameter MR0_BL								= 1;
parameter MR0_BT								= 0;
parameter MR0_CAS_LATENCY						= 3;
parameter MR0_DLL								= 1;

parameter MR0_WR								= 2;
parameter MR0_PD								= 0;
parameter MR1_DLL								= 0;
parameter MR1_ODS								= 0;
parameter MR1_RTT								= 0;
parameter MR1_AL								= 0;
parameter MR1_WL								= 0;
parameter MR1_TDQS								= 0;
parameter MR1_QOFF								= 0;
parameter MR2_CWL								= 1;
parameter MR2_ASR								= 0;
parameter MR2_SRT								= 0;
parameter MR2_RTT_WR							= 0;
parameter MR3_MPR_RF							= 0;
parameter MR3_MPR								= 0;
parameter RDIMM_CONFIG							= 0;
parameter MEM_BURST_LENGTH						= 8;
parameter MEM_T_WL								= 5;

parameter SEQ_BURST_COUNT_WIDTH = 1;

parameter VCALIB_COUNT_WIDTH = 2;

parameter DELAY_PER_OPA_TAP 				= 285;
parameter DELAY_PER_DCHAIN_TAP 				= 50;
parameter DELAY_CHAIN_LENGTH 				= 10;
parameter MEM_IF_NUMBER_OF_RANKS 			= 1;
parameter MEM_MIRROR_ADDRESSING_DEC			= 0;
parameter DLL_OFFSET_CTRL_WIDTH = 6;

parameter PLL_PHASE_COUNTER_WIDTH = 4;

parameter MEM_CLK_FREQ = 350.0;
parameter DELAY_BUFFER_MODE = "HIGH";
parameter DQS_DELAY_CHAIN_PHASE_SETTING = 2;
parameter DQS_PHASE_SHIFT = 7200;
parameter DELAYED_CLOCK_PHASE_SETTING = 2;
parameter CALIB_VFIFO_OFFSET = 14;
parameter CALIB_LFIFO_OFFSET = 5;
parameter AFI_DEBUG_INFO_WIDTH = 32;

parameter REF_CLK_FREQ_STR = "125.0 MHz";
parameter PLL_AFI_CLK_FREQ_STR = "175.0 MHz";
parameter PLL_MEM_CLK_FREQ_STR = "350.0 MHz";
parameter PLL_WRITE_CLK_FREQ_STR = "350.0 MHz";
parameter PLL_ADDR_CMD_CLK_FREQ_STR = "175.0 MHz";
parameter PLL_AFI_HALF_CLK_FREQ_STR = "87.5 MHz";
parameter PLL_NIOS_CLK_FREQ_STR = "87.5 MHz";
parameter PLL_CONFIG_CLK_FREQ_STR = "21.875 MHz";
parameter PLL_P2C_READ_CLK_FREQ_STR = "";
parameter PLL_C2P_WRITE_CLK_FREQ_STR = "";
parameter PLL_HR_CLK_FREQ_STR = "";
parameter PLL_DR_CLK_FREQ_STR = "";

parameter PLL_AFI_CLK_FREQ_SIM_STR = "5716 ps";
parameter PLL_MEM_CLK_FREQ_SIM_STR = "2858 ps";
parameter PLL_WRITE_CLK_FREQ_SIM_STR = "2858 ps";
parameter PLL_ADDR_CMD_CLK_FREQ_SIM_STR = "5716 ps";
parameter PLL_AFI_HALF_CLK_FREQ_SIM_STR = "11432 ps";
parameter PLL_NIOS_CLK_FREQ_SIM_STR = "11432 ps";
parameter PLL_CONFIG_CLK_FREQ_SIM_STR = "45728 ps";
parameter PLL_P2C_READ_CLK_FREQ_SIM_STR = "0 ps";
parameter PLL_C2P_WRITE_CLK_FREQ_SIM_STR = "0 ps";
parameter PLL_HR_CLK_FREQ_SIM_STR = "0 ps";
parameter PLL_DR_CLK_FREQ_SIM_STR = "0 ps";

parameter PLL_AFI_CLK_PHASE_PS_STR = "0 ps";
parameter PLL_MEM_CLK_PHASE_PS_STR = "0 ps";
parameter PLL_WRITE_CLK_PHASE_PS_STR = "714 ps";
parameter PLL_ADDR_CMD_CLK_PHASE_PS_STR = "4286 ps";
parameter PLL_AFI_HALF_CLK_PHASE_PS_STR = "0 ps";
parameter PLL_NIOS_CLK_PHASE_PS_STR = "0 ps";
parameter PLL_CONFIG_CLK_PHASE_PS_STR = "0 ps";
parameter PLL_P2C_READ_CLK_PHASE_PS_STR = "";
parameter PLL_C2P_WRITE_CLK_PHASE_PS_STR = "";
parameter PLL_HR_CLK_PHASE_PS_STR = "";
parameter PLL_DR_CLK_PHASE_PS_STR = "";

parameter CALIB_REG_WIDTH = 8;


localparam SIM_FILESET = ("false" == "true");






input	pll_ref_clk;		

output	pll_afi_clk;		
output	pll_afi_half_clk;
output	pll_mem_clk;	
output	pll_write_clk;
output	pll_addr_cmd_clk;
output	pll_avl_clk;
output	pll_config_clk;
output	pll_locked;
output	[DLL_DELAY_CTRL_WIDTH-1:0]  dll_delayctrl;

input   global_reset_n;		
input	soft_reset_n;		
output	afi_reset_n;		

input   oct_rdn;
input   oct_rup;
output [OCT_TERM_CONTROL_WIDTH-1:0] parallelterminationcontrol;
output [OCT_TERM_CONTROL_WIDTH-1:0] seriesterminationcontrol;

input   [AFI_ADDR_WIDTH-1:0]        afi_addr;		
input   [AFI_BANKADDR_WIDTH-1:0]    afi_ba;			
input   [AFI_CS_WIDTH-1:0]          afi_cke;		
input   [AFI_CS_WIDTH-1:0]          afi_cs_n;		
input   [AFI_CONTROL_WIDTH-1:0]     afi_ras_n;
input   [AFI_CONTROL_WIDTH-1:0]     afi_we_n;
input   [AFI_CONTROL_WIDTH-1:0]     afi_cas_n;
input   [AFI_CS_WIDTH-1:0]          afi_odt;
input   [AFI_CONTROL_WIDTH-1:0]     afi_rst_n;


input   [AFI_WRITE_DQS_WIDTH-1:0]   afi_dqs_burst;
input	[AFI_WRITE_DQS_WIDTH-1:0]	afi_wdata_valid;	
input   [AFI_DQ_WIDTH-1:0]          afi_wdata;			
input   [AFI_DM_WIDTH-1:0]          afi_dm;				

input   [AFI_RATE_RATIO-1:0]		afi_rdata_en;		
input   [AFI_RATE_RATIO-1:0]		afi_rdata_en_full;	
output  [AFI_DQ_WIDTH-1:0]          afi_rdata;			
output  [AFI_RATE_RATIO-1:0]		afi_rdata_valid;

output  afi_cal_success;	
output  afi_cal_fail;		
input   afi_cal_req;		

output [AFI_WLAT_WIDTH-1:0]			afi_wlat;
output [AFI_RLAT_WIDTH-1:0]			afi_rlat;



output  [MEM_IF_ADDR_WIDTH-1:0]       mem_a;        
output  [MEM_IF_BANKADDR_WIDTH-1:0]   mem_ba;       
output  [MEM_IF_CK_WIDTH-1:0]         mem_ck;       
output  [MEM_IF_CK_WIDTH-1:0]         mem_ck_n;
output  [MEM_IF_CLK_EN_WIDTH-1:0]     mem_cke;      
output  [MEM_IF_CS_WIDTH-1:0]         mem_cs_n;     
output  [MEM_IF_DM_WIDTH-1:0]         mem_dm;       
output  [MEM_IF_CONTROL_WIDTH-1:0]    mem_ras_n;		
output  [MEM_IF_CONTROL_WIDTH-1:0]    mem_cas_n;		
output  [MEM_IF_CONTROL_WIDTH-1:0]    mem_we_n;		
inout	[MEM_IF_DQ_WIDTH-1:0]         mem_dq;       
inout	[MEM_IF_DQS_WIDTH-1:0]        mem_dqs;      
inout	[MEM_IF_DQS_WIDTH-1:0]        mem_dqs_n;    
output  [MEM_IF_ODT_WIDTH-1:0]        mem_odt;
output	                              mem_reset_n;




output	afi_clk;
output	afi_half_clk;






wire reset_request_n;



ddr3_s4_uniphy_p0_controller_phy #(
	.DEVICE_FAMILY(DEVICE_FAMILY),
	.OCT_TERM_CONTROL_WIDTH(OCT_TERM_CONTROL_WIDTH),
	.MEM_ADDRESS_WIDTH(MEM_IF_ADDR_WIDTH),
	.MEM_BANK_WIDTH(MEM_IF_BANKADDR_WIDTH),
	.MEM_CHIP_SELECT_WIDTH(MEM_IF_CS_WIDTH),
	.MEM_DM_WIDTH(MEM_IF_DM_WIDTH),
	.MEM_CONTROL_WIDTH(MEM_IF_CONTROL_WIDTH),
	.MEM_DQ_WIDTH(MEM_IF_DQ_WIDTH),
	.MEM_ODT_WIDTH(MEM_IF_ODT_WIDTH),
	.AFI_ADDRESS_WIDTH(AFI_ADDR_WIDTH),
	.AFI_BANK_WIDTH(AFI_BANKADDR_WIDTH),
	.AFI_CHIP_SELECT_WIDTH(AFI_CS_WIDTH),
	.AFI_DATA_MASK_WIDTH(AFI_DM_WIDTH),
	.AFI_WRITE_DQS_WIDTH(AFI_WRITE_DQS_WIDTH),
	.AFI_CONTROL_WIDTH(AFI_CONTROL_WIDTH),
	.AFI_DATA_WIDTH(AFI_DQ_WIDTH),
	.DLL_DELAY_CTRL_WIDTH(DLL_DELAY_CTRL_WIDTH),
	.NUM_SUBGROUP_PER_READ_DQS(NUM_SUBGROUP_PER_READ_DQS),
	.QVLD_EXTRA_FLOP_STAGES(QVLD_EXTRA_FLOP_STAGES),
	.QVLD_WR_ADDRESS_OFFSET(QVLD_WR_ADDRESS_OFFSET),
	.READ_FIFO_SIZE(READ_FIFO_SIZE),
	.AFI_WLAT_WIDTH(AFI_WLAT_WIDTH),
	.AFI_RLAT_WIDTH(AFI_RLAT_WIDTH),
	.NUM_WRITE_PATH_FLOP_STAGES(NUM_WRITE_PATH_FLOP_STAGES),
	.MEM_TINIT_CK(MEM_TINIT_CK),
	.MEM_TMRD_CK(MEM_TMRD_CK),
	.RDIMM(RDIMM_INT),
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
	.SEQ_BURST_COUNT_WIDTH(SEQ_BURST_COUNT_WIDTH),
	.VCALIB_COUNT_WIDTH(VCALIB_COUNT_WIDTH),
	.DELAY_PER_OPA_TAP(DELAY_PER_OPA_TAP),
	.DELAY_PER_DCHAIN_TAP(DELAY_PER_DCHAIN_TAP),
	.DLL_DELAY_CHAIN_LENGTH(DELAY_CHAIN_LENGTH),
	.MEM_NUMBER_OF_RANKS(MEM_IF_NUMBER_OF_RANKS),
	.MEM_MIRROR_ADDRESSING(MEM_MIRROR_ADDRESSING_DEC),
	.ALTDQDQS_INPUT_FREQ(MEM_CLK_FREQ),
	.ALTDQDQS_DELAY_CHAIN_BUFFER_MODE(DELAY_BUFFER_MODE),
	.ALTDQDQS_DQS_PHASE_SETTING(DQS_DELAY_CHAIN_PHASE_SETTING),
	.ALTDQDQS_DQS_PHASE_SHIFT(DQS_PHASE_SHIFT),
	.ALTDQDQS_DELAYED_CLOCK_PHASE_SETTING(DELAYED_CLOCK_PHASE_SETTING),
	.CALIB_VFIFO_OFFSET(CALIB_VFIFO_OFFSET),
	.CALIB_LFIFO_OFFSET(CALIB_LFIFO_OFFSET),
	.AFI_DEBUG_INFO_WIDTH(AFI_DEBUG_INFO_WIDTH),
	.REF_CLK_FREQ(REF_CLK_FREQ_STR),
	.AFI_CLK_FREQ(SIM_FILESET ? PLL_AFI_CLK_FREQ_SIM_STR : PLL_AFI_CLK_FREQ_STR),
	.MEM_CLK_FREQ(SIM_FILESET ? PLL_MEM_CLK_FREQ_SIM_STR : PLL_MEM_CLK_FREQ_STR),
	.WRITE_CLK_FREQ(SIM_FILESET ? PLL_WRITE_CLK_FREQ_SIM_STR : PLL_WRITE_CLK_FREQ_STR),
	.ADDR_CMD_CLK_FREQ(SIM_FILESET ? PLL_ADDR_CMD_CLK_FREQ_SIM_STR : PLL_ADDR_CMD_CLK_FREQ_STR),
	.AFI_HALF_CLK_FREQ(SIM_FILESET ? PLL_AFI_HALF_CLK_FREQ_SIM_STR : PLL_AFI_HALF_CLK_FREQ_STR),
	.AVL_CLK_FREQ(SIM_FILESET ? PLL_NIOS_CLK_FREQ_SIM_STR : PLL_NIOS_CLK_FREQ_STR),
	.CONFIG_CLK_FREQ(SIM_FILESET ? PLL_CONFIG_CLK_FREQ_SIM_STR : PLL_CONFIG_CLK_FREQ_STR),
	.AFI_CLK_PHASE(PLL_AFI_CLK_PHASE_PS_STR),
	.MEM_CLK_PHASE(PLL_MEM_CLK_PHASE_PS_STR),
	.WRITE_CLK_PHASE(PLL_WRITE_CLK_PHASE_PS_STR),
	.ADDR_CMD_CLK_PHASE(PLL_ADDR_CMD_CLK_PHASE_PS_STR),
	.AFI_HALF_CLK_PHASE(PLL_AFI_HALF_CLK_PHASE_PS_STR),
	.AVL_CLK_PHASE(PLL_NIOS_CLK_PHASE_PS_STR),
	.CONFIG_CLK_PHASE(PLL_CONFIG_CLK_PHASE_PS_STR),
	.CALIB_REG_WIDTH(CALIB_REG_WIDTH)
) controller_phy_inst (
	.global_reset_n(global_reset_n),
	.soft_reset_n(soft_reset_n),
	.reset_request_n(reset_request_n),
	.ctl_reset_n(afi_reset_n),
	.oct_rdn(oct_rdn),
	.oct_rup(oct_rup),
	.parallelterminationcontrol(parallelterminationcontrol),
	.seriesterminationcontrol(seriesterminationcontrol),
	.pll_ref_clk(pll_ref_clk),
	.pll_afi_clk(pll_afi_clk),
	.pll_afi_half_clk(pll_afi_half_clk),
	.pll_mem_clk(pll_mem_clk),
	.pll_write_clk(pll_write_clk),
	.pll_addr_cmd_clk(pll_addr_cmd_clk),
	.pll_avl_clk(pll_avl_clk),
	.pll_config_clk(pll_config_clk),
	.pll_locked(pll_locked),
	.dll_delayctrl(dll_delayctrl),
	.afi_clk(afi_clk),
	.afi_half_clk(afi_half_clk),
	.afi_addr(afi_addr),
	.afi_ba(afi_ba),
	.afi_cke(afi_cke),
	.afi_cs_n(afi_cs_n),
	.afi_ras_n(afi_ras_n),
	.afi_we_n(afi_we_n),
	.afi_cas_n(afi_cas_n),
	.afi_rst_n(afi_rst_n),
	.afi_odt(afi_odt),
	.afi_dqs_burst(afi_dqs_burst),
	.afi_wdata_valid(afi_wdata_valid),
	.afi_wdata(afi_wdata),
	.afi_dm(afi_dm),
	.afi_rdata_en(afi_rdata_en),
	.afi_rdata_en_full(afi_rdata_en_full),
	.afi_rdata(afi_rdata),
	.afi_rdata_valid(afi_rdata_valid),
	.afi_cal_success(afi_cal_success),
	.afi_cal_fail(afi_cal_fail),
	.afi_wlat(afi_wlat),
	.afi_rlat(afi_rlat),
	.mem_a(mem_a),
	.mem_ba(mem_ba),
	.mem_ck(mem_ck),
	.mem_ck_n(mem_ck_n),
	.mem_cke(mem_cke),
	.mem_cs_n(mem_cs_n),
	.mem_dm(mem_dm),
	.mem_ras_n(mem_ras_n),
	.mem_cas_n(mem_cas_n),
	.mem_we_n(mem_we_n),
	.mem_reset_n(mem_reset_n),
	.mem_dq(mem_dq),
	.mem_dqs(mem_dqs),
	.mem_dqs_n(mem_dqs_n),
	.mem_odt(mem_odt)
);


endmodule

