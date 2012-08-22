//alt_oct_power CBX_AUTO_BLACKBOX="ALL" CBX_SINGLE_OUTPUT_FILE="ON" device_family="Stratix IV" parallelterminationcontrol rdn rup seriesterminationcontrol
//VERSION_BEGIN 11.0SP1 cbx_alt_oct_power 2011:07:03:21:10:32:SJ cbx_cycloneii 2011:07:03:21:10:33:SJ cbx_lpm_add_sub 2011:07:03:21:10:33:SJ cbx_lpm_compare 2011:07:03:21:10:33:SJ cbx_lpm_counter 2011:07:03:21:10:33:SJ cbx_lpm_decode 2011:07:03:21:10:33:SJ cbx_mgl 2011:07:03:21:11:41:SJ cbx_stratix 2011:07:03:21:10:33:SJ cbx_stratixii 2011:07:03:21:10:33:SJ cbx_stratixiii 2011:07:03:21:10:33:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 1991-2011 Altera Corporation
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, Altera MegaCore Function License 
//  Agreement, or other applicable license agreement, including, 
//  without limitation, that your use is for the sole purpose of 
//  programming logic devices manufactured by Altera and sold by 
//  Altera or its authorized distributors.  Please refer to the 
//  applicable agreement for further details.



//synthesis_resources = stratixiv_termination 1 stratixiv_termination_logic 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim_e0_if0_p0_oct_control
	( 
	parallelterminationcontrol,
	rdn,
	rup,
	seriesterminationcontrol) /* synthesis synthesis_clearbox=1 */;
	output   [13:0]  parallelterminationcontrol;
	input   [0:0]  rdn;
	input   [0:0]  rup;
	output   [13:0]  seriesterminationcontrol;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   [0:0]  rdn;
	tri0   [0:0]  rup;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire  [0:0]   wire_sd1a_serializerenableout;
	wire  [0:0]   wire_sd1a_terminationcontrol;
	wire  [13:0]   wire_sd2a_parallelterminationcontrol;
	wire  [13:0]   wire_sd2a_seriesterminationcontrol;

	stratixiv_termination   sd1a_0
	( 
	.incrdn(),
	.incrup(),
	.rdn(rdn),
	.rup(rup),
	.scanout(),
	.serializerenableout(wire_sd1a_serializerenableout[0:0]),
	.shiftregisterprobe(),
	.terminationcontrol(wire_sd1a_terminationcontrol[0:0]),
	.terminationcontrolprobe()
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.otherserializerenable({9{1'b0}}),
	.scanen(1'b0),
	.serializerenable(1'b0),
	.terminationclear(1'b0),
	.terminationclock(1'b0),
	.terminationcontrolin(1'b0),
	.terminationenable(1'b1)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	// synopsys translate_off
	,
	.devclrn(1'b1),
	.devpor(1'b1)
	// synopsys translate_on
	);
	stratixiv_termination_logic   sd2a_0
	( 
	.parallelterminationcontrol(wire_sd2a_parallelterminationcontrol[13:0]),
	.serialloadenable(wire_sd1a_serializerenableout),
	.seriesterminationcontrol(wire_sd2a_seriesterminationcontrol[13:0]),
	.terminationdata(wire_sd1a_terminationcontrol)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.parallelloadenable(1'b0),
	.terminationclock(1'b0)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	// synopsys translate_off
	,
	.devclrn(1'b1),
	.devpor(1'b1)
	// synopsys translate_on
	);
	assign
		parallelterminationcontrol = wire_sd2a_parallelterminationcontrol,
		seriesterminationcontrol = wire_sd2a_seriesterminationcontrol;
endmodule //ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim_e0_if0_p0_oct_control
//VALID FILE
