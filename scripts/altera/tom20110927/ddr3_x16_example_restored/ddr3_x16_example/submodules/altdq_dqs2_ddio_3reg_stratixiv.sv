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


`timescale 1 ps / 1 ps

module altdq_dqs2_ddio_3reg_stratixiv (
	dll_delayctrl_in,
	dll_offsetdelay_in,
	capture_strobe_in,
	capture_strobe_n_in,
	capture_strobe_ena,
	capture_strobe_out,
	
	output_strobe_ena,
	output_strobe_out,
	output_strobe_n_out,
	oct_ena_in,
	strobe_io,
	strobe_n_io,
	
	reset_n_core_clock_in,
	core_clock_in,
	fr_clock_in,
	hr_clock_in,
	dr_clock_in,
	strobe_ena_hr_clock_in,
	strobe_ena_clock_in,
	write_strobe_clock_in,
	parallelterminationcontrol_in,
	seriesterminationcontrol_in,

	
	read_data_in,
	write_data_out,
	read_write_data_io,
		
	
	write_oe_in,
	read_data_out,
	write_data_in,
	extra_write_data_in,
	extra_write_data_out,
	capture_strobe_tracking,

	
	config_data_in,
	config_dqs_ena,
	config_io_ena,
	config_extra_io_ena,
	config_dqs_io_ena,
	config_update,
	config_clock_in

);
	
parameter PIN_WIDTH = 8;
parameter PIN_TYPE = "bidir";

parameter USE_INPUT_PHASE_ALIGNMENT = "false";
parameter USE_OUTPUT_PHASE_ALIGNMENT = "false";
parameter USE_LDC_AS_LOW_SKEW_CLOCK = "false";

parameter USE_HALF_RATE_INPUT = "false";
parameter USE_HALF_RATE_OUTPUT = "false";

parameter DIFFERENTIAL_CAPTURE_STROBE = "false";
parameter SEPARATE_CAPTURE_STROBE = "false";

parameter INPUT_FREQ = 0.0;
parameter INPUT_FREQ_PS = "0 ps";
parameter DELAY_CHAIN_BUFFER_MODE = "high";
parameter DQS_PHASE_SETTING = 3;
parameter DQS_PHASE_SHIFT = 9000;
parameter DQS_ENABLE_PHASE_SETTING = 2;
parameter USE_DYNAMIC_CONFIG = "true";
parameter INVERT_CAPTURE_STROBE = "false";
parameter USE_TERMINATION_CONTROL = "false";
parameter USE_OCT_ENA_IN_FOR_OCT = "false";
parameter USE_DQS_ENABLE = "false";
parameter USE_IO_CONFIG = "false";
parameter USE_DQS_CONFIG = "false";

parameter USE_OFFSET_CTRL = "false";
parameter HR_DDIO_OUT_HAS_THREE_REGS = "true";

parameter USE_OUTPUT_STROBE = "true";
parameter DIFFERENTIAL_OUTPUT_STROBE = "false";
parameter USE_OUTPUT_STROBE_RESET = "true";
parameter USE_BIDIR_STROBE = "false";
parameter REVERSE_READ_WORDS = "false";

parameter EXTRA_OUTPUT_WIDTH = 0;
parameter PREAMBLE_TYPE = "none";
parameter USE_DATA_OE_FOR_OCT = "false";
parameter DQS_ENABLE_WIDTH = 1;

parameter USE_2X_FF = "false";
parameter USE_DQS_TRACKING = "false";

localparam rate_mult_in = (USE_HALF_RATE_INPUT == "true") ? 4 : 2;
localparam rate_mult_out = (USE_HALF_RATE_OUTPUT == "true") ? 4 : 2;
localparam fpga_width_in = PIN_WIDTH * rate_mult_in;
localparam fpga_width_out = PIN_WIDTH * rate_mult_out;
localparam extra_fpga_width_out = EXTRA_OUTPUT_WIDTH * rate_mult_out;
localparam OS_ENA_WIDTH =  rate_mult_out / 2;
localparam WRITE_OE_WIDTH = PIN_WIDTH * rate_mult_out / 2;
parameter  DQS_ENABLE_PHASECTRL = "true"; 

parameter DYNAMIC_MODE = "dynamic";

parameter OCT_SERIES_TERM_CONTROL_WIDTH   = 16; 
parameter OCT_PARALLEL_TERM_CONTROL_WIDTH = 16; 
parameter DLL_WIDTH = 6;
parameter DLL_USE_2X_CLK = "false";
parameter REGULAR_WRITE_BUS_ORDERING = "true";

parameter CALIBRATION_SUPPORT = "false";

parameter ALTERA_ALTDQ_DQS2_FAST_SIM_MODEL = 0;

localparam DELAY_CHAIN_WIDTH = 4;

localparam OUTPUT_ALIGNMENT_DELAY = "two_cycle";

input [DLL_WIDTH-1:0] dll_delayctrl_in;
input [DLL_WIDTH-1:0] dll_offsetdelay_in;

input reset_n_core_clock_in;
input core_clock_in;
input fr_clock_in;
input hr_clock_in;
input strobe_ena_hr_clock_in;
input strobe_ena_clock_in;
input write_strobe_clock_in;

input [PIN_WIDTH-1:0] read_data_in;
output [PIN_WIDTH-1:0] write_data_out;
inout [PIN_WIDTH-1:0] read_write_data_io;

input capture_strobe_in;
input capture_strobe_n_in;
input [DQS_ENABLE_WIDTH-1:0] capture_strobe_ena;

input [OS_ENA_WIDTH-1:0] output_strobe_ena;
output output_strobe_out;
output output_strobe_n_out;
input [1:0] oct_ena_in;
inout strobe_io;
inout strobe_n_io;

output [fpga_width_in-1:0] read_data_out;
input [fpga_width_out-1:0] write_data_in;

input [WRITE_OE_WIDTH-1:0] write_oe_in;
output capture_strobe_out;

input [extra_fpga_width_out-1:0] extra_write_data_in;
output [EXTRA_OUTPUT_WIDTH-1:0] extra_write_data_out;

output capture_strobe_tracking;

input dr_clock_in;

input	[OCT_PARALLEL_TERM_CONTROL_WIDTH-1:0] parallelterminationcontrol_in;
input	[OCT_SERIES_TERM_CONTROL_WIDTH-1:0] seriesterminationcontrol_in;

input config_data_in;
input config_update;
input config_dqs_ena;
input [PIN_WIDTH-1:0] config_io_ena;
input [EXTRA_OUTPUT_WIDTH-1:0] config_extra_io_ena;
input config_dqs_io_ena;
input config_clock_in;

wire [DLL_WIDTH-1:0] dll_delay_value;
assign dll_delay_value = dll_delayctrl_in;

wire dqsbusout;
wire dqsnbusout;

wire [3:0] dqs_inputdelaysetting;
wire [3:0] dqsn_inputdelaysetting;

wire [3:0] dqs_outputdelaysetting1;
wire [3:0] dqs_outputdelaysetting2;
wire [3:0] dqsn_outputdelaysetting1;
wire [3:0] dqsn_outputdelaysetting2;

wire [DELAY_CHAIN_WIDTH-1:0] dqs_outputdelaysetting1_dlc;
wire [DELAY_CHAIN_WIDTH-1:0] dqs_outputdelaysetting2_dlc;
wire [DELAY_CHAIN_WIDTH-1:0] dqsn_outputdelaysetting1_dlc;
wire [DELAY_CHAIN_WIDTH-1:0] dqsn_outputdelaysetting2_dlc;

generate
if (USE_DYNAMIC_CONFIG =="true" && (USE_OUTPUT_STROBE == "true" || PIN_TYPE =="input" || PIN_TYPE == "bidir"))
begin
	
	

	stratixiv_io_config dqs_io_config_1 (
			.datain(config_data_in),  
			.clk(config_clock_in),
			.ena(config_dqs_io_ena),
			.update(config_update),  

			.outputdelaysetting1(dqs_outputdelaysetting1),
			.outputdelaysetting2(dqs_outputdelaysetting2),
			.padtoinputregisterdelaysetting(dqs_inputdelaysetting),
		

			.dataout()
		);

	
	assign dqs_outputdelaysetting1_dlc = dqs_outputdelaysetting1;
	assign dqs_outputdelaysetting2_dlc = dqs_outputdelaysetting2;

	stratixiv_io_config dqsn_io_config_1 (
		    .datain(config_data_in),          
			.clk(config_clock_in),
			.ena(config_dqs_io_ena),
			.update(config_update),       

			.outputdelaysetting1(dqsn_outputdelaysetting1),
			.outputdelaysetting2(dqsn_outputdelaysetting2),
			.padtoinputregisterdelaysetting(dqsn_inputdelaysetting),

			.dataout()
		);

	
	assign dqsn_outputdelaysetting1_dlc = dqsn_outputdelaysetting1;
	assign dqsn_outputdelaysetting2_dlc = dqsn_outputdelaysetting2;

end
endgenerate

wire [1:0] oct_ena;
wire fr_term;
wire aligned_term;

wire [1:0] oct_source;

generate
	if (USE_DATA_OE_FOR_OCT == "true")
	begin
		assign oct_source[0] = write_oe_in [0];
		if (USE_HALF_RATE_OUTPUT == "true")
			assign oct_source [1] = write_oe_in [PIN_WIDTH];
	end
	else
	begin
		assign oct_source = output_strobe_ena;
	end
endgenerate

generate
	if (USE_HALF_RATE_OUTPUT == "true")
	begin : oct_ena_hr_gen
		if (USE_OCT_ENA_IN_FOR_OCT == "true")
		begin
			assign oct_ena = oct_ena_in;
		end
		else
		begin
			reg oct_ena_hr_reg;
			always @(posedge hr_clock_in)
				oct_ena_hr_reg <= oct_source[1];
			assign oct_ena[1] = ~oct_source[1];
			assign oct_ena[0] = ~(oct_ena_hr_reg | oct_source[1]);
		end
	end
	else
	begin : oct_ena_fr_gen
		if (USE_OCT_ENA_IN_FOR_OCT == "true")
		begin
			assign fr_term = oct_ena_in[0];
		end
		else
		begin
			reg oct_ena_fr_reg;
			initial
				oct_ena_fr_reg = 0;
			always @(posedge hr_clock_in)
				oct_ena_fr_reg <= oct_source[0];
			assign fr_term = ~(oct_source[0] | oct_ena_fr_reg);
		end
	end
endgenerate



localparam PINS_PER_DQS_CONFIG = 6;
localparam NUM_STROBES = (DIFFERENTIAL_CAPTURE_STROBE == "true" || SEPARATE_CAPTURE_STROBE == "true") ? 2 : 1;
localparam DQS_CONFIGS = (PIN_WIDTH + EXTRA_OUTPUT_WIDTH + NUM_STROBES) / PINS_PER_DQS_CONFIG;

wire dividerphasesetting [DQS_CONFIGS:0];
wire dqoutputphaseinvert [DQS_CONFIGS:0];
wire [3:0] dqoutputphasesetting [DQS_CONFIGS:0];
wire [3:0] dqsbusoutdelaysetting [DQS_CONFIGS:0];
wire [3:0] dqsoutputphasesetting [DQS_CONFIGS:0];
wire [3:0] resyncinputphasesetting [DQS_CONFIGS:0];
wire [2:0] dqsenabledelaysetting [DQS_CONFIGS:0];
wire [2:0] dqsinputphasesetting [DQS_CONFIGS:0];
wire [3:0] dqsenablectrlphasesetting [DQS_CONFIGS:0];
wire dqsbusoutfinedelaysetting [DQS_CONFIGS:0];
wire dqsenablectrlphaseinvert [DQS_CONFIGS:0];
wire dqsenablefinedelaysetting [DQS_CONFIGS:0];
wire dqsoutputphaseinvert [DQS_CONFIGS:0];
wire enadataoutbypass [DQS_CONFIGS:0];
wire enadqsenablephasetransferreg [DQS_CONFIGS:0];

wire enainputcycledelaysetting [DQS_CONFIGS:0];
wire enainputphasetransferreg [DQS_CONFIGS:0];

wire enaoctphasetransferreg [DQS_CONFIGS:0];
wire enaoutputphasetransferreg [DQS_CONFIGS:0];
wire enaoctcycledelaysetting [DQS_CONFIGS:0];
wire enaoutputcycledelaysetting [DQS_CONFIGS:0];
wire [3:0] octdelaysetting1 [DQS_CONFIGS:0];
wire [2:0] octdelaysetting2 [DQS_CONFIGS:0];

wire resyncinputphaseinvert [DQS_CONFIGS:0];

wire [DELAY_CHAIN_WIDTH-1:0] dqsbusoutdelaysetting_dlc[DQS_CONFIGS:0];
wire [DELAY_CHAIN_WIDTH-1:0] dqsenabledelaysetting_dlc[DQS_CONFIGS:0];
wire [DELAY_CHAIN_WIDTH-1:0] dqsdisabledelaysetting_dlc[DQS_CONFIGS:0];
wire [DELAY_CHAIN_WIDTH-1:0] octdelaysetting1_dlc[DQS_CONFIGS:0];
wire [DELAY_CHAIN_WIDTH-1:0] octdelaysetting2_dlc[DQS_CONFIGS:0];

generate
if (USE_DYNAMIC_CONFIG == "true")
begin
	genvar c_num; 
	for (c_num = 0; c_num <= DQS_CONFIGS; c_num = c_num + 1)
	begin :dqs_config_gen
			
		stratixiv_dqs_config   dqs_config_inst
		( 
		.clk(config_clock_in),
		.datain(config_data_in),
		.dataout(),
		.ena(config_dqs_ena),
		.update(config_update),


		
		.dqoutputphaseinvert(dqoutputphaseinvert[c_num]), 
		.dqoutputphasesetting(dqoutputphasesetting[c_num]), 
 		.dqsbusoutdelaysetting(dqsbusoutdelaysetting[c_num]), 
		
		.dqsenablectrlphaseinvert(dqsenablectrlphaseinvert[c_num]), 
		.dqsenablectrlphasesetting(dqsenablectrlphasesetting[c_num]), 

		.dqsenabledelaysetting(dqsenabledelaysetting[c_num]), 
		
		.dqsinputphasesetting(dqsinputphasesetting[c_num]), 
		.dqsoutputphaseinvert(dqsoutputphaseinvert[c_num]), 
		.dqsoutputphasesetting(dqsoutputphasesetting[c_num]), 
		
		.enadqsenablephasetransferreg(enadqsenablephasetransferreg[c_num]), 
		.enainputcycledelaysetting(enainputcycledelaysetting[c_num]), 
		.enainputphasetransferreg(enainputphasetransferreg[c_num]), 
		.enaoctcycledelaysetting(enaoctcycledelaysetting[c_num]), 
		.enaoctphasetransferreg(enaoctphasetransferreg[c_num]),
		.enaoutputcycledelaysetting(enaoutputcycledelaysetting[c_num]),
		.enaoutputphasetransferreg(enaoutputphasetransferreg[c_num]), 
		.octdelaysetting1(octdelaysetting1[c_num]),
		.octdelaysetting2(octdelaysetting2[c_num]),
		.resyncinputphaseinvert(resyncinputphaseinvert[c_num]), 
		.resyncinputphasesetting(resyncinputphasesetting[c_num]) 
		);
		
		assign dqsbusoutdelaysetting_dlc[c_num] = dqsbusoutdelaysetting[c_num];
		assign dqsenabledelaysetting_dlc[c_num] = dqsenabledelaysetting[c_num];
		assign octdelaysetting1_dlc[c_num] = octdelaysetting1[c_num];
		assign octdelaysetting2_dlc[c_num] = octdelaysetting2[c_num];
	end
end
endgenerate



generate
if (USE_BIDIR_STROBE == "true")
begin
	assign output_strobe_out = 1'b0;
	assign output_strobe_n_out = 1'b1;	
end
else
begin
	assign strobe_io = 1'b0;
	assign strobe_n_io = 1'b1;	
end
endgenerate

wire zero_phase_clock;
wire dq_zero_phase_clock;
wire dqs_zero_phase_clock;
wire dq_dr_clock;
wire dqs_dr_clock;
wire dq_shifted_clock;
wire dqs_shifted_clock;
wire write_strobe_clock;

assign zero_phase_clock = fr_clock_in;
assign dq_zero_phase_clock = fr_clock_in;
assign dqs_zero_phase_clock = fr_clock_in;
assign dq_shifted_clock = fr_clock_in;
assign dqs_shifted_clock = fr_clock_in;
assign write_strobe_clock = write_strobe_clock_in;




generate 
if (PIN_TYPE == "input" || PIN_TYPE == "bidir")
begin

	assign capture_strobe_out = dqsbusout;
	wire dqsin;
	
	if (DIFFERENTIAL_CAPTURE_STROBE == "true")
	begin
		if (USE_BIDIR_STROBE == "true")
		begin
			stratixiv_io_ibuf 
			#(
				.differential_mode(DIFFERENTIAL_CAPTURE_STROBE),
				.bus_hold("false")
			) strobe_in (
				.i(strobe_io),
				.ibar (strobe_n_io),
				.o(dqsin)
			);
		end
		else
		begin
			stratixiv_io_ibuf 
			#(
				.differential_mode(DIFFERENTIAL_CAPTURE_STROBE),
				.bus_hold("false")
			) strobe_in (					      
				.i(capture_strobe_in),
				.ibar (capture_strobe_n_in),
				.o(dqsin)
			);
		end
	end
	else
	begin
		if (USE_BIDIR_STROBE == "true")
		begin
			stratixiv_io_ibuf
			#(
				.bus_hold("false")
			) strobe_in (					      
				.i(strobe_io),
				.o(dqsin)
		);
		end
		else
		begin
			stratixiv_io_ibuf 
			#(
				.bus_hold("false")
			) strobe_in (					      
				.i(capture_strobe_in),
				.o(dqsin)
		);
		end
	end

	wire capture_strobe_ena_fr;
	if (DQS_ENABLE_WIDTH > 1)
	begin
			stratixiv_ddio_out
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")
			) hr_to_fr_ena (					      
					.datainhi(capture_strobe_ena[1]),
					.datainlo(capture_strobe_ena[0]),
					.dataout(capture_strobe_ena_fr),
					.clkhi (strobe_ena_hr_clock_in),
					.clklo (strobe_ena_hr_clock_in),
					.muxsel (strobe_ena_hr_clock_in)
			);
	end	
	else
	begin
		assign capture_strobe_ena_fr = capture_strobe_ena;
	end



	wire dqsbusout_preena;
	wire dqsbusout_predelay;
	wire dqs_enable_predelay;
	wire dqs_enable;

	if (USE_DYNAMIC_CONFIG == "true")
	begin
		
 		
		

		stratixiv_dqs_delay_chain
		#(
			.dqs_input_frequency(INPUT_FREQ_PS),
		  	.delay_buffer_mode(DELAY_CHAIN_BUFFER_MODE),
		  	.use_phasectrlin("true"),
		  	.phase_setting(DQS_PHASE_SETTING),
			.dqs_phase_shift(DQS_PHASE_SHIFT),
		  	.dqs_ctrl_latches_enable("false"),
		  	.dqs_offsetctrl_enable(USE_OFFSET_CTRL)
		) dqs_delay_chain(					      
			.dqsin(dqsin),
			.delayctrlin(dll_delay_value),
			.dqsbusout(dqsbusout_predelay),
			
			.phasectrlin(dqsinputphasesetting[0])
		);

		stratixiv_delay_chain dqs_in_delay_1(
			.datain             (dqsbusout_predelay),
			.delayctrlin        (dqsbusoutdelaysetting_dlc[0]),
			.dataout            (dqsbusout_preena)
		);

		stratixiv_delay_chain dqs_ena_delay_1(
			.datain             (dqs_enable_predelay),
			.delayctrlin        (dqsenabledelaysetting_dlc[0]),
			.dataout            (dqs_enable)
		);
	end
	else
	begin
		stratixiv_dqs_delay_chain 
		#(
			.dqs_input_frequency(INPUT_FREQ_PS),
			.delay_buffer_mode(DELAY_CHAIN_BUFFER_MODE),
			.use_phasectrlin("false"),
			.phase_setting(DQS_PHASE_SETTING),
			.dqs_phase_shift(DQS_PHASE_SHIFT),
			.dqs_ctrl_latches_enable("false"),
			.dqs_offsetctrl_enable(USE_OFFSET_CTRL)
		) dqs_delay_chain(						      
			.dqsin(dqsin),
			.delayctrlin(dll_delay_value),
			.dqsbusout(dqsbusout_predelay),
			.dqsupdateen(1'b0)
		);
		assign dqsbusout_preena = dqsbusout_predelay;
		assign dqs_enable = dqs_enable_predelay;
	end

	if (USE_DQS_ENABLE == "true")
	begin
		stratixiv_dqs_enable_ctrl 
		#(
			.delay_dqs_enable_by_half_cycle("true"),
			.delay_buffer_mode("high"), //"high" is the only valid input
			.phase_setting(DQS_ENABLE_PHASE_SETTING),
			.invert_phase(DYNAMIC_MODE),
			.level_dqs_enable("true"),
			.add_phase_transfer_reg(DYNAMIC_MODE),
			.use_phasectrlin(DQS_ENABLE_PHASECTRL)
		) enable_ctrl (
			.dqsenablein(capture_strobe_ena_fr),
			.clk(strobe_ena_clock_in),
			.delayctrlin(dll_delay_value),
			.dqsenableout(dqs_enable_predelay),
			.phasectrlin(dqsenablectrlphasesetting[0]),
			.phaseinvertctrl(dqsenablectrlphaseinvert[0]),
			.enaphasetransferreg(enadqsenablephasetransferreg[0])
			);

		stratixiv_dqs_enable dqs_enable_block (
			.dqsin(dqsbusout_preena), 
			.dqsenable(dqs_enable),
			.dqsbusout(dqsbusout)
		);
	end
	else
	begin
		assign dqsbusout = dqsbusout_preena;
	end
	
	if (SEPARATE_CAPTURE_STROBE == "true")
	begin
		wire dqsnin;
		wire dqsnbusout_preena;
		wire dqsnbusout_predelay;
		wire dqsn_enable_predelay;
		wire dqsn_enable;

		
		if (USE_BIDIR_STROBE == "true")
		begin
			stratixiv_io_ibuf strobe_n_in (
				.i(strobe_n_io),
				.o(dqsnin)
			);
		end
		else
		begin
			stratixiv_io_ibuf strobe_n_in (
				.i(capture_strobe_n_in),
				.o(dqsnin)
			);
		end
		
		if (USE_DYNAMIC_CONFIG == "true")
		begin
			
	 		
			

			stratixiv_dqs_delay_chain
			#(
				.dqs_input_frequency(INPUT_FREQ_PS),
				.delay_buffer_mode(DELAY_CHAIN_BUFFER_MODE),
				.use_phasectrlin("true"),
				.phase_setting(DQS_PHASE_SETTING),
				.dqs_phase_shift(DQS_PHASE_SHIFT),
				.dqs_ctrl_latches_enable("false"),	
				.dqs_offsetctrl_enable(USE_OFFSET_CTRL)
			)  dqs_delay_chain(
				.dqsin(dqsnin),
				.delayctrlin(dll_delay_value),
				.dqsbusout(dqsnbusout_predelay),
				.phasectrlin(dqsinputphasesetting[0])
			);

			stratixiv_delay_chain dqs_delay_1(
				.datain             (dqsnbusout_predelay),
				.delayctrlin        (dqsbusoutdelaysetting_dlc[0]),
				.dataout            (dqsnbusout_preena)
			);

			stratixiv_delay_chain dqs_ena_delay_1(
				.datain             (dqsn_enable_predelay),
				.delayctrlin        (dqsenabledelaysetting_dlc[0]),
				.dataout            (dqsn_enable)
			);
		end
		else
		begin
			stratixiv_dqs_delay_chain 
			#(
				.dqs_input_frequency(INPUT_FREQ_PS),
				.delay_buffer_mode(DELAY_CHAIN_BUFFER_MODE),
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.phase_setting(DQS_PHASE_SETTING),
				.dqs_phase_shift(DQS_PHASE_SHIFT),
				.dqs_ctrl_latches_enable("false"),
				.dqs_offsetctrl_enable(USE_OFFSET_CTRL)
			)  dqsn_delay_chain(
				.dqsin(dqsnin),
				.delayctrlin(dll_delay_value),
				.dqsbusout(dqsnbusout_predelay)
			);

			assign dqsnbusout_preena = dqsnbusout_predelay;
			assign dqsn_enable = dqsn_enable_predelay;
		end

		if (USE_DQS_ENABLE == "true")
		begin
			stratixiv_dqs_enable_ctrl
			#( 
				.delay_buffer_mode(DELAY_CHAIN_BUFFER_MODE),
				.phase_setting(DQS_ENABLE_PHASE_SETTING),
				.delay_dqs_enable_by_half_cycle("true"),
				.invert_phase(DYNAMIC_MODE),
				.level_dqs_enable("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.use_phasectrlin(DQS_ENABLE_PHASECTRL)
			) enablen_ctrl (
				.dqsenablein(capture_strobe_ena_fr),
				.clk(strobe_ena_clock_in),
				.delayctrlin(dll_delay_value),
				.dqsenableout(dqsn_enable_predelay),
				.phasectrlin(dqsenablectrlphasesetting[0]),
				.phaseinvertctrl(dqsenablectrlphaseinvert[0]),
				.enaphasetransferreg(enadqsenablephasetransferreg[0])
			);

			stratixiv_dqs_enable dqs_enablen_block (
				.dqsin(dqsnbusout_preena),
				.dqsenable(dqsn_enable),
				.dqsbusout(dqsnbusout)
			);
		end
		else
		begin
			assign dqsnbusout = dqsnbusout_preena;
		end
	end
								
	
end
endgenerate

generate
if (USE_OUTPUT_STROBE == "true")
begin
	wire os;
	wire os_bar;
	wire os_dtc;
	wire os_dtc_bar;
	wire os_delayed1;
	wire os_delayed2;

	wire fr_os_oe;
	wire fr_os_oct;
	wire aligned_os_oct;
	wire aligned_os_oe;
	wire aligned_strobe;
	
	wire fr_os_hi;
	wire fr_os_lo;
	
	if (USE_HALF_RATE_OUTPUT == "true")
	begin
		if (USE_BIDIR_STROBE == "true")
		begin		
			wire clk_gate;
			
			if (PREAMBLE_TYPE == "low")
			begin
				assign clk_gate = output_strobe_ena[0];
			end
			else
			begin
				if (PREAMBLE_TYPE == "high")
				begin
					assign clk_gate = output_strobe_ena [1];
				end
				else
				begin
					assign clk_gate = 1'b1;
				end
			end
			
			stratixiv_ddio_out
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")	
			) hr_to_fr_os_hi (
					.datainhi(clk_gate),
					.datainlo(clk_gate),
					.dataout(fr_os_hi),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
			);

			stratixiv_ddio_out
			#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true"),
					.async_mode("none")
			) hr_to_fr_os_lo (	
					.datainhi(1'b0),
					.datainlo(1'b0),
					.dataout(fr_os_lo),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
			);

			stratixiv_ddio_out
			#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true"),
					.async_mode("none")
			) hr_to_fr_os_oe (								  
					.datainhi(~output_strobe_ena [1]),
					.datainlo(~output_strobe_ena [0]),
					.dataout(fr_os_oe),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
			);
		end
		else 
		begin
			wire clk_gate;
			
			
			
			
			
			
			
			
			if (USE_OUTPUT_STROBE_RESET == "true") begin
				reg clk_h /* synthesis dont_merge */;
				always @(posedge core_clock_in or negedge reset_n_core_clock_in)
				begin
					if (~reset_n_core_clock_in)
						clk_h <= 1'b0;
					else
						clk_h <= 1'b1;
				end			
				assign clk_gate = clk_h;
			end else begin
				assign clk_gate = 1'b1;
			end
			
			if (USE_LDC_AS_LOW_SKEW_CLOCK == "true") begin
				
				
				stratixiv_ddio_out
				#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true"),
					.async_mode("none")	
				) hr_to_fr_os_hi (
						.datainhi(clk_gate),
						.datainlo(clk_gate),
						.dataout(fr_os_hi),
						.clkhi (hr_clock_in),
						.clklo (hr_clock_in),
						.muxsel (hr_clock_in)
				);

				stratixiv_ddio_out
				#(
						.half_rate_mode("true"),
						.use_new_clocking_model("true"),
						.async_mode("none")
				) hr_to_fr_os_lo (	
						.datainhi(1'b0),
						.datainlo(1'b0),
						.dataout(fr_os_lo),
						.clkhi (hr_clock_in),
						.clklo (hr_clock_in),
						.muxsel (hr_clock_in)
				);
			end else begin
				
				wire gnd_lut /* synthesis keep = 1*/;
				assign gnd_lut = 1'b0;
				assign fr_os_lo = gnd_lut;
				assign fr_os_hi = clk_gate;
			end
		end

		stratixiv_ddio_out 
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")	
			) hr_to_fr_os_oct (
			.datainhi(oct_ena[1]),
			.datainlo(oct_ena[0]),
			.dataout(fr_os_oct),
			.clkhi (hr_clock_in),
			.clklo (hr_clock_in),
			.muxsel (hr_clock_in)
		);
	end
	else
	begin
		if (USE_BIDIR_STROBE == "true")
		begin
			assign fr_os_oe = ~output_strobe_ena[0];
			assign fr_os_oct = fr_term;

			
			wire gnd_lut /* synthesis keep = 1*/;
			assign gnd_lut = 1'b0;
			assign fr_os_lo = gnd_lut;

			if (PREAMBLE_TYPE == "low")
			begin
				reg os_ena_reg1;
				
				initial
					os_ena_reg1 = 0;
				
				always @(posedge core_clock_in)
					os_ena_reg1 <= output_strobe_ena[0];
	
				assign fr_os_hi = os_ena_reg1 & output_strobe_ena[0];
			end
			else
			begin
				if (PREAMBLE_TYPE == "high")
				begin
					assign fr_os_hi = output_strobe_ena[0];
				end
				else
				begin
					
					wire vcc_lut /* synthesis keep = 1*/;
					assign vcc_lut = 1'b1;
					assign fr_os_hi = vcc_lut;
				end
			end
		end
		else
		begin
			
			wire gnd_lut /* synthesis keep = 1*/;
			assign gnd_lut = 1'b0;
			assign fr_os_lo = gnd_lut;	

			
			
			
			
			
			
			
			if (USE_OUTPUT_STROBE_RESET == "true") begin
				reg clk_h /* synthesis dont_merge */;
				always @(posedge core_clock_in or negedge reset_n_core_clock_in)
				begin
					if (~reset_n_core_clock_in)
						clk_h <= 1'b0;
					else
						clk_h <= 1'b1;
				end			
				assign fr_os_hi = clk_h;
			end else begin
				assign fr_os_hi = 1'b1;
			end
		end		
	end

	if (USE_OUTPUT_PHASE_ALIGNMENT == "true")
	begin
		stratixiv_output_phase_alignment
		#(
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.use_phasectrl_clock("true"),
				.use_delayed_clock("true"),
				.phase_setting_for_delayed_clock(2),
				.operation_mode("ddio_out"),
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_primary_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
		) dqs_alignment(
			.datain ({fr_os_hi,fr_os_lo}),
			.clk(fr_clock_in),
			.clkena (1'b1),
			.delayctrlin(dll_delay_value),
			.phaseinvertctrl (dqsoutputphaseinvert[0]),
			
			.enaoutputcycledelay (enaoctcycledelaysetting[0]),
			.enaphasetransferreg (enaoctphasetransferreg[0]),
	
			.dataout(aligned_strobe),
			.phasectrlin(dqsoutputphasesetting[0])
		);

		stratixiv_output_phase_alignment
		#(
			.use_phasectrlin(USE_DYNAMIC_CONFIG),
			.use_phasectrl_clock("true"),
			.use_delayed_clock("true"),
			.phase_setting_for_delayed_clock(2),
			.operation_mode("oe"),
			.delay_buffer_mode("high"),
			.power_up("low"),
			.async_mode("none"),
			.sync_mode("none"),
			.use_primary_clock("true"),
			.add_phase_transfer_reg(DYNAMIC_MODE),
			.add_output_cycle_delay(DYNAMIC_MODE),
			.invert_phase(DYNAMIC_MODE),
			.bypass_input_register("false")
		) dqs_oe_alignment(								
			.datain({1'b0,fr_os_oe}),
			.clk(fr_clock_in),
			.clkena (1'b1),
			.delayctrlin(dll_delay_value),
			.phaseinvertctrl (dqsoutputphaseinvert[0]),
			
			.enaoutputcycledelay (enaoctcycledelaysetting[0]),
			.enaphasetransferreg (enaoctphasetransferreg[0]),
	
			.dataout(aligned_os_oe),
			.phasectrlin(dqsoutputphasesetting[0])
		);

		stratixiv_output_phase_alignment
		#(
				.operation_mode("rtena"),
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_phasectrl_clock("true"),
				.use_primary_clock("true"),
				.use_delayed_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
		) dqs_oct_alignment (
			.datain			({1'b0,fr_os_oct}),
			.clk(fr_clock_in),
			.clkena			(1'b1),
			.delayctrlin(dll_delay_value),
			.phasectrlin (dqsoutputphasesetting[0]),
			.phaseinvertctrl (dqsoutputphaseinvert[0]),
			.enaoutputcycledelay (enaoctcycledelaysetting[0]),
			.enaphasetransferreg (enaoctphasetransferreg[0]),
			.dataout		(aligned_os_oct )
		);
	end
	else
	begin
		
		reg oe_reg /* synthesis dont_merge altera_attribute="FAST_OUTPUT_ENABLE_REGISTER=on" */;
		reg oct_reg /* synthesis altera_attribute="FAST_OCT_REGISTER=on" */;
		
		initial 
		begin
			oe_reg = 0;
			oct_reg = 0;
		end
		
		always @ ( posedge write_strobe_clock)
			oe_reg <= fr_os_oe;

		assign aligned_os_oe = oe_reg;
		always @ (posedge fr_clock_in)
			oct_reg <= fr_os_oct;

		assign aligned_os_oct = oct_reg;
	
		stratixiv_ddio_out
		#(
				.half_rate_mode("false"),
				.use_new_clocking_model("true"),
				.async_mode("none")
		) phase_align_os (
			.datainhi(fr_os_hi),
			.datainlo(fr_os_lo),
			.dataout(aligned_strobe),
			.clkhi (write_strobe_clock),
			.clklo (write_strobe_clock),
			.muxsel (write_strobe_clock)
		);
	end
	
	wire delayed_os_oct;
	wire delayed_os_oe;
	wire predelayed_os;
	wire predelayed_os_oe;
	
	if (USE_2X_FF == "true")
	begin
		reg dd_os;
		reg dd_os_oe;
		always @(posedge dqs_dr_clock)
		begin
			dd_os <= aligned_strobe;
			dd_os_oe <= aligned_os_oe;
		end
		assign predelayed_os = dd_os;
		assign predelayed_os_oe = dd_os_oe;
	end
	else
	begin
		assign predelayed_os = aligned_strobe;
		assign predelayed_os_oe = aligned_os_oe;
	end
	
	if (USE_DYNAMIC_CONFIG == "true")
	begin
		wire delayed_os_oct_1;
		wire delayed_os_oe_1;

		stratixiv_delay_chain
		dqs_out_delay_1(
			.datain             (predelayed_os),
			.delayctrlin        (dqs_outputdelaysetting1_dlc),
			.dataout            (os_delayed1)
		);


		stratixiv_delay_chain
		dqs_out_delay_2(
			.datain             (os_delayed1),
			.delayctrlin        (dqs_outputdelaysetting2_dlc),
			.dataout            (os_delayed2)
		);

		stratixiv_delay_chain oct_delay_1(
			.datain             (aligned_os_oct),
			.delayctrlin        (octdelaysetting1_dlc [0]),
			.dataout            (delayed_os_oct_1)
		);
		
		stratixiv_delay_chain oct_delay_2(
			.datain             (delayed_os_oct_1),
			.delayctrlin        (octdelaysetting2_dlc [0]),
			.dataout            (delayed_os_oct)
		);

		stratixiv_delay_chain
		oe_delay_1(
			.datain             (predelayed_os_oe),
			.delayctrlin        (dqs_outputdelaysetting1_dlc),
			.dataout            (delayed_os_oe_1)
		);

		stratixiv_delay_chain 
		oe_delay_2(
						  
			.datain             (delayed_os_oe_1),
			.delayctrlin        (dqs_outputdelaysetting2_dlc),
			.dataout            (delayed_os_oe)
		);
	end
	else
	begin
		assign os_delayed2 = aligned_strobe;
		assign delayed_os_oct = aligned_term;
		assign delayed_os_oe = aligned_os_oe;
	end

	wire diff_oe;
	wire diff_oe_bar;
	wire diff_dtc;
	wire diff_dtc_bar;

	if (DIFFERENTIAL_OUTPUT_STROBE=="true")
	begin
		wire aligned_os_oe_bar;
		wire aligned_os_oct_bar;
		
		wire delayed_os_bar_oct;
		wire delayed_os_bar_oct_1;

		wire delayed_os_bar_oe;
		wire delayed_os_bar_oe_1;

		wire fr_os_oen;
		wire fr_os_octn;

		if (USE_HALF_RATE_OUTPUT == "true")
		begin
			stratixiv_ddio_out
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")	
			)  hr_to_fr_os_oe_bar (
					.datainhi(~output_strobe_ena [1]),
					.datainlo(~output_strobe_ena [0]),
					.dataout(fr_os_oen),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
			);
	
			stratixiv_ddio_out
			#(
			  	.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")
			) hr_to_fr_os_oct_bar (
				.datainhi(oct_ena [1]),
				.datainlo(oct_ena [0]),
				.dataout(fr_os_octn),
				.clkhi (hr_clock_in),
				.clklo (hr_clock_in),
				.muxsel (hr_clock_in)
			);
		end
		else
		begin
			assign fr_os_oen = ~output_strobe_ena;
			assign fr_os_octn = fr_term;
		end
	
		if (USE_OUTPUT_PHASE_ALIGNMENT == "true")
		begin
			stratixiv_output_phase_alignment 
			#( 
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.use_phasectrl_clock("true"),
				.use_delayed_clock("true"),
				.phase_setting_for_delayed_clock(2),
				.operation_mode("oe"),
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_primary_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
			) dqs_oe_bar_alignment(
				.datain({1'b0,fr_os_oen}),
				.clk(fr_clock_in),
				.clkena (1'b1),
				.delayctrlin(dll_delay_value),
				.phaseinvertctrl (dqsoutputphaseinvert[0]),
				.enaoutputcycledelay (enaoctcycledelaysetting[0]),
				.enaphasetransferreg (enaoctphasetransferreg[0]),
		
				.dataout(aligned_os_oe_bar),
				.phasectrlin(dqsoutputphasesetting[0])
			);

			stratixiv_output_phase_alignment
			#(
				.operation_mode("rtena"),
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_phasectrl_clock("true"),
				.use_primary_clock("true"),
				.use_delayed_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
			) dqs_oct_bar_alignment (
				.datain			({1'b0,fr_os_octn}),
				.clk(fr_clock_in),
				.clkena			(1'b1),
				.delayctrlin(dll_delay_value),
				.phasectrlin (dqsoutputphasesetting[0]),
				.phaseinvertctrl (dqsoutputphaseinvert[0]),
				.enaoutputcycledelay (enaoctcycledelaysetting[0]),
				.enaphasetransferreg (enaoctphasetransferreg[0]),
				.dataout		(aligned_os_oct_bar )
			);
		end
		else
		begin

			
			reg oe_bar_reg /* synthesis dont_merge altera_attribute="FAST_OUTPUT_ENABLE_REGISTER=on" */;
			reg oct_bar_reg /* synthesis altera_attribute="FAST_OCT_REGISTER=on" */;
			
			initial
			begin
				oe_bar_reg = 0;
				oct_bar_reg = 0;
			end
			
			always @ ( posedge write_strobe_clock)
				oe_bar_reg <= fr_os_oen;

			assign aligned_os_oe_bar = oe_bar_reg;
			
			always @ (posedge fr_clock_in)
				oct_bar_reg <= fr_os_octn;
		
			assign aligned_os_oct_bar = oct_bar_reg;
		end		
		
		if (USE_DYNAMIC_CONFIG == "true")
		begin
			stratixiv_delay_chain oct_delay_1_bar(
				.datain             (aligned_os_oct_bar),
				.delayctrlin        (octdelaysetting1_dlc [0]),
				.dataout            (delayed_os_bar_oct_1)
			);

			stratixiv_delay_chain oct_delay_2_bar(
				.datain             (delayed_os_bar_oct_1),
				.delayctrlin        (octdelaysetting2_dlc [0]),
				.dataout            (delayed_os_bar_oct)
			);

			stratixiv_delay_chain
			oe_delay_1_bar(
				.datain             (aligned_os_oe_bar),
				.delayctrlin        (dqsn_outputdelaysetting1_dlc),
				.dataout            (delayed_os_bar_oe_1)
			);

			stratixiv_delay_chain
			oe_delay_2_bar(
				.datain             (delayed_os_bar_oe_1),
				.delayctrlin        (dqsn_outputdelaysetting2_dlc),
				.dataout            (delayed_os_bar_oe)
			);
		end
		else
		begin
			assign delayed_os_bar_oct = aligned_os_oct_bar;
			assign delayed_os_bar_oe = aligned_os_oe_bar;
		end

		if (USE_BIDIR_STROBE == "true")
		begin
			stratixiv_pseudo_diff_out   pseudo_diffa_0
			( 
				.i(os_delayed2),
				.o(os),
				.obar(os_bar)
			);		
		
			stratixiv_io_obuf
			#(
				.bus_hold("false"),
				.open_drain_output("false")
			) obuf_os_bar_0
			( 
				.i(os_bar),
				.o(strobe_n_io),
				.obar(),
				.parallelterminationcontrol	(parallelterminationcontrol_in),
				.oe(~delayed_os_bar_oe),
				.dynamicterminationcontrol	(delayed_os_bar_oct),
				.seriesterminationcontrol	(seriesterminationcontrol_in)
			);
		end
		else
		begin
			stratixiv_pseudo_diff_out   pseudo_diffa_0
			( 
				.i(os_delayed2),
				.o(os),
				.obar(os_bar)
			);
		
			stratixiv_io_obuf
			#(
				.bus_hold("false"),
				.open_drain_output("false")
			) obuf_os_bar_0
			( 
				.i(os_bar),
				.o(output_strobe_n_out),
				.obar(),
				.oe(1'b1)
			);
		end
	end
	else
	begin
		
		assign os = os_delayed2;
		assign diff_oe = delayed_os_oe;
	end


	if (USE_BIDIR_STROBE == "true")
	begin
		stratixiv_io_obuf
		#(
			.bus_hold("false"),
			.open_drain_output("false")
		) obuf_os_0
			( 
			.i(os),
			.o(strobe_io),
			.obar(),
			.parallelterminationcontrol	(parallelterminationcontrol_in),
			.oe(~delayed_os_oe),
			.dynamicterminationcontrol	(delayed_os_oct),
			.seriesterminationcontrol	(seriesterminationcontrol_in)
		);
	end
	else
	begin
		stratixiv_io_obuf
		#(
			.bus_hold("false"),
			.open_drain_output("false")
		) obuf_os_0			  
			( 
			.i(os),
			.o(output_strobe_out),
			.obar(),
			.oe(1'b1)
			);
	
	end	
end
endgenerate


wire [PIN_WIDTH-1:0] aligned_oe ;
wire [PIN_WIDTH-1:0] aligned_data;
wire [PIN_WIDTH-1:0] ddr_data;
wire [PIN_WIDTH-1:0] aligned_oct;

generate
	if (PIN_TYPE == "output" || PIN_TYPE == "bidir")
	begin
		genvar opin_num;
		for (opin_num = 0; opin_num < PIN_WIDTH; opin_num = opin_num + 1)
		begin :output_path_gen
			wire fr_data_hi;
			wire fr_data_lo;
			wire fr_oe;
			wire fr_oct;
			
			if (USE_HALF_RATE_OUTPUT == "true")
			begin
				wire hr_data_t0;
				wire hr_data_t1;
				wire hr_data_t2;
				wire hr_data_t3;

				if (REGULAR_WRITE_BUS_ORDERING == "true")
			  	begin
					assign hr_data_t0 = write_data_in [opin_num + 0*PIN_WIDTH];
			  		assign hr_data_t1 = write_data_in [opin_num + 1*PIN_WIDTH];
			  		assign hr_data_t2 = write_data_in [opin_num + 2*PIN_WIDTH];
					assign hr_data_t3 = write_data_in [opin_num + 3*PIN_WIDTH];
				end
				else
			  	begin
					
					
					assign hr_data_t0 = write_data_in [opin_num + 1*PIN_WIDTH];
					assign hr_data_t1 = write_data_in [opin_num + 0*PIN_WIDTH];
					assign hr_data_t2 = write_data_in [opin_num + 3*PIN_WIDTH];
					assign hr_data_t3 = write_data_in [opin_num + 2*PIN_WIDTH];
				end
			
				stratixiv_ddio_out
				#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true"),
					.async_mode("none")
				) hr_to_fr_hi (			  
					.datainhi(hr_data_t2),
					.datainlo(hr_data_t0),
					.dataout(fr_data_hi),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
				);

				stratixiv_ddio_out
				#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true"),
					.async_mode("none")
				) hr_to_fr_lo (			  
					.datainhi(hr_data_t3),
					.datainlo(hr_data_t1),
					.dataout(fr_data_lo),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
				);

				stratixiv_ddio_out
				#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true")
				
				) hr_to_fr_oe (
					.datainhi(~write_oe_in [opin_num + PIN_WIDTH]),
					.datainlo(~write_oe_in [opin_num + 0]),
					.dataout(fr_oe),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
				);

				stratixiv_ddio_out
				#(
					.half_rate_mode("true"),
					.use_new_clocking_model("true")
				)  hr_to_fr_oct (
					.datainhi(oct_ena [1]),
					.datainlo(oct_ena [0]),
					.dataout(fr_oct),
					.clkhi (hr_clock_in),
					.clklo (hr_clock_in),
					.muxsel (hr_clock_in)
				);
			end
			else
			begin
				assign fr_data_lo = write_data_in [opin_num+PIN_WIDTH];
				assign fr_data_hi = write_data_in [opin_num];
				assign fr_oe = ~write_oe_in [opin_num];
				assign fr_oct = fr_term;
			end
			
			if (USE_OUTPUT_PHASE_ALIGNMENT == "true")
			begin
				int dqs_index = (opin_num+NUM_STROBES)/PINS_PER_DQS_CONFIG;
				
				stratixiv_output_phase_alignment 
				#(
					.use_phasectrlin(USE_DYNAMIC_CONFIG),
					.use_phasectrl_clock("true"),
					.use_delayed_clock("true"),
					
					.operation_mode("ddio_out"),
					.delay_buffer_mode("high"),
					.power_up("low"),
					.async_mode("none"),
					.sync_mode("none"),
					.use_primary_clock("true"),
					.add_phase_transfer_reg(DYNAMIC_MODE),
					.add_output_cycle_delay(DYNAMIC_MODE),
					.invert_phase(DYNAMIC_MODE),
					.bypass_input_register("false")
				) data_alignment(
					.datain({fr_data_hi,fr_data_lo}),
					.clk(zero_phase_clock),
					.clkena (1'b1),
					.delayctrlin(dll_delay_value),
					.phasectrlin (dqoutputphasesetting[dqs_index]),
					.phaseinvertctrl (dqoutputphaseinvert[dqs_index]),
					.enaoutputcycledelay (enaoutputcycledelaysetting[dqs_index]),
					.enaphasetransferreg (enaoutputphasetransferreg[dqs_index]),
					.dataout(aligned_data[opin_num])
				);
	
				stratixiv_output_phase_alignment
				#(
				.operation_mode("oe"),
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.use_phasectrl_clock("true"),
				.use_delayed_clock("true"),
				
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_primary_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
				) oe_alignment(
					.datain({1'b0,fr_oe}), 
					.clk(zero_phase_clock),
					.clkena(1'b1),
					.delayctrlin(dll_delay_value),
					.phasectrlin (dqoutputphasesetting[dqs_index]),
					.phaseinvertctrl (dqoutputphaseinvert[dqs_index]),
					.enaoutputcycledelay (enaoutputcycledelaysetting[dqs_index]),
					.enaphasetransferreg (enaoutputphasetransferreg[dqs_index]),
					.dataout(aligned_oe[opin_num])
				);

				stratixiv_output_phase_alignment
				#(
					.operation_mode("rtena"),
					.use_phasectrlin(USE_DYNAMIC_CONFIG),
					.delay_buffer_mode("high"),
					.power_up("low"),
					.async_mode("none"),
					.sync_mode("none"),
					.use_phasectrl_clock("true"),
					.use_primary_clock("true"),
					.use_delayed_clock("true"),
					.add_phase_transfer_reg(DYNAMIC_MODE),
					.add_output_cycle_delay(DYNAMIC_MODE),
					.invert_phase(DYNAMIC_MODE),
					.bypass_input_register("false")
				) oct_alignment (			  
					.datain			({1'b0,fr_oct}),
					.clk(fr_clock_in),
					.clkena			(1'b1),
					.delayctrlin(dll_delay_value),
					.phasectrlin (dqsoutputphasesetting[dqs_index]),
					.phaseinvertctrl (dqsoutputphaseinvert[dqs_index]),
					.enaoutputcycledelay (enaoctcycledelaysetting[dqs_index]),
					.enaphasetransferreg (enaoctphasetransferreg[dqs_index]),
					.dataout		(aligned_oct [opin_num])
				);
			end
			else
			begin
				reg oe_reg /* synthesis dont_merge altera_attribute="FAST_OUTPUT_ENABLE_REGISTER=on" */;
				reg oct_reg /* synthesis altera_attribute="FAST_OCT_REGISTER=on" */;
			
				stratixiv_ddio_out
				#(
					.async_mode("none"),
					.half_rate_mode("false"),
					.sync_mode("none"),
					.use_new_clocking_model("true")
				) ddio_out (
					.datainhi(fr_data_hi),
					.datainlo(fr_data_lo),
					.dataout(aligned_data[opin_num]),
					.clkhi (dq_shifted_clock),
					.clklo (dq_shifted_clock),
					.muxsel (dq_shifted_clock)
				);

				
				initial
				begin
					oe_reg = 0;
					oct_reg = 0;
				end
				always @ (posedge dq_shifted_clock)
				begin
					oe_reg <= fr_oe;
					oct_reg <= fr_oct; 
				end

				assign aligned_oct [opin_num] = oct_reg;
				assign aligned_oe [opin_num] = oe_reg;
				

			end
		end
	end
endgenerate


generate
if (PIN_TYPE == "input" || PIN_TYPE == "bidir")
begin
	genvar ipin_num;
	for (ipin_num = 0; ipin_num < PIN_WIDTH; ipin_num = ipin_num + 1)
	begin :input_path_gen

		wire [1:0] sdr_data;
		wire [1:0] aligned_input;
		wire dqsbusout_to_ddio_in;
		wire dqsnbusout_to_ddio_in;
		
		if (INVERT_CAPTURE_STROBE == "true") begin
			assign dqsbusout_to_ddio_in = ~dqsbusout;
			if (SEPARATE_CAPTURE_STROBE == "true") begin
				assign dqsnbusout_to_ddio_in = ~dqsnbusout;
			end
		end else begin
			assign dqsbusout_to_ddio_in = dqsbusout;
			if (SEPARATE_CAPTURE_STROBE == "true") begin
				assign dqsnbusout_to_ddio_in = dqsnbusout;
			end
		end
		
		if (SEPARATE_CAPTURE_STROBE == "true") begin
			stratixiv_ddio_in
			#(
				.use_clkn("true"),
				.async_mode("none"),
				.sync_mode("none")
			) capture_reg(
				.datain(ddr_data[ipin_num]),
				.clk (dqsbusout_to_ddio_in),
				.clkn (dqsnbusout_to_ddio_in),
				.regouthi(sdr_data[1]),
				.regoutlo(sdr_data[0])
			);
		end else begin
			stratixiv_ddio_in
			#(
				.use_clkn("false"),
				.async_mode("none"),
				.sync_mode("none")
			)  capture_reg(
				.datain(ddr_data[ipin_num]),
				.clk (dqsbusout_to_ddio_in),
				.regouthi(sdr_data[1]),
				.regoutlo(sdr_data[0])
			);
		end
		
		if (USE_INPUT_PHASE_ALIGNMENT == "true") 
		begin
			stratixiv_input_phase_alignment
			#(
				.use_phasectrlin("false"),
				
				
				.phase_setting(0)
			) data_alignment_hi(			  
				.datain(sdr_data[1]),
				.clk(zero_phase_clock),
				.delayctrlin(dll_delay_value),
				.dataout(aligned_input[1])
			);

			stratixiv_input_phase_alignment
			#(
				.use_phasectrlin("false"),
				
				
				.phase_setting(0)
			) data_alignment_lo(
				.datain(sdr_data[0]),
				.clk(zero_phase_clock),
				.delayctrlin(dll_delay_value),
				.dataout(aligned_input[0])
			);
		end
		else
		begin
			assign aligned_input = sdr_data;
		end
		
		if (USE_HALF_RATE_INPUT == "true")
		begin
		/*
			stratixiv_half_rate_input half_rate (
				.datain (aligned_input),
				.clk (hr_clock_in),
				.dataout ({fpga_data_in_hi[ipin_num], fpga_data_in_lo[ipin_num],fpga_data_in_hi_hr[ipin_num],fpga_data_in_lo_hr[ipin_num]})
			);
			*/
		end
		else
		begin
			if (REVERSE_READ_WORDS == "true")
			begin
				assign read_data_out [ipin_num] = aligned_input [1];
				assign read_data_out [PIN_WIDTH +ipin_num] = aligned_input [0];
			end
			else
			begin
				assign read_data_out [ipin_num] = aligned_input [0];
				assign read_data_out [PIN_WIDTH +ipin_num] = aligned_input [1];
			end
		end
	end
end
endgenerate

generate
	genvar pin_num;
	for (pin_num = 0; pin_num < PIN_WIDTH; pin_num = pin_num + 1)
	begin :pad_gen
		if (PIN_TYPE == "bidir")
		begin
			assign write_data_out [pin_num] = 1'b0;
		end
		else
		begin
			assign read_write_data_io [pin_num] = 1'b0;
		end
	
	
		wire delayed_data_in;
		wire delayed_data_out;
		wire delayed_oe;
		wire [3:0] dq_outputdelaysetting1;
		wire [3:0] dq_outputdelaysetting2;
		wire [3:0] dq_inputdelaysetting;
		assign dq_outputdelaysetting2 [3] = 1'b0;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_outputdelaysetting1_dlc;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_outputdelaysetting2_dlc;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_inputdelaysetting_dlc;
		
		
		if (USE_DYNAMIC_CONFIG == "true")
		begin
		stratixiv_io_config config_1 (
		    .datain(config_data_in),          
		    .clk(config_clock_in),
		    .ena(config_io_ena[pin_num]),
		    .update(config_update),       

		    .outputdelaysetting1(dq_outputdelaysetting1),
		    .outputdelaysetting2(dq_outputdelaysetting2),
		    .padtoinputregisterdelaysetting(dq_inputdelaysetting),
		    .dataout()
		);
		
		assign dq_outputdelaysetting1_dlc = dq_outputdelaysetting1;
		assign dq_outputdelaysetting2_dlc = dq_outputdelaysetting2;
		assign dq_inputdelaysetting_dlc = dq_inputdelaysetting;
		end
	
		if (PIN_TYPE == "input" || PIN_TYPE == "bidir")
		begin
			
			wire raw_input;
			if (USE_DYNAMIC_CONFIG == "true")
			begin
				stratixiv_delay_chain in_delay_1(
					.datain             (raw_input),
					.delayctrlin        (dq_inputdelaysetting_dlc),
					.dataout            (ddr_data[pin_num])
				);
			end
			else
			begin
				assign ddr_data[pin_num] = raw_input;
			end	
			
			if (PIN_TYPE == "bidir")
			begin
				stratixiv_io_ibuf data_in (
					.i(read_write_data_io[pin_num]),
					.o(raw_input)
				);
			end
			else
			begin
				stratixiv_io_ibuf data_in (
					.i(read_data_in[pin_num]),
					.o(raw_input)
				);
			end
		end
		wire delayed_oct;
		
		if (PIN_TYPE == "output" || PIN_TYPE == "bidir")
		begin
		
			wire predelayed_data;
			wire predelayed_oe;
	
			if (USE_2X_FF == "true")
			begin
				reg dd_data;
				reg dd_oe;
				always @(posedge dq_dr_clock)
				begin
					dd_data <= aligned_data[pin_num];
					dd_oe <= aligned_oe[pin_num];
				end
				assign predelayed_data = dd_data;
				assign predelayed_oe = dd_oe;
			end
			else
			begin
				assign predelayed_data = aligned_data[pin_num];
				assign predelayed_oe = aligned_oe[pin_num];
			end

			if (USE_DYNAMIC_CONFIG == "true")
			begin
				
				wire delayed_data_1;
				wire delayed_oe_1;
				wire delayed_oct_1;
						
				stratixiv_delay_chain
				out_delay_1(
					.datain             (predelayed_data),
					.delayctrlin        (dq_outputdelaysetting1_dlc),
					.dataout            (delayed_data_1)
				);

				stratixiv_delay_chain
				out_delay_2(
					.datain             (delayed_data_1),
					.delayctrlin        (dq_outputdelaysetting2_dlc),
					.dataout            (delayed_data_out)
				);

				stratixiv_delay_chain
				oe_delay_1(
					.datain             (predelayed_oe),
					.delayctrlin        (dq_outputdelaysetting1_dlc),
					.dataout            (delayed_oe_1)
				);

				stratixiv_delay_chain
				oe_delay_2(
					.datain             (delayed_oe_1),
					.delayctrlin        (dq_outputdelaysetting2_dlc),
					.dataout            (delayed_oe)
				);

				stratixiv_delay_chain oct_delay_1(
					.delayctrlin        (octdelaysetting1_dlc [(pin_num+NUM_STROBES)/PINS_PER_DQS_CONFIG]),		
					.datain             (aligned_oct[pin_num]),
					.dataout            (delayed_oct_1)
				);
				
				stratixiv_delay_chain oct_delay_2(
					.delayctrlin        (octdelaysetting2_dlc [(pin_num+NUM_STROBES)/PINS_PER_DQS_CONFIG]),
					.datain             (delayed_oct_1),
					.dataout            (delayed_oct)
				);
			end
			else
			begin
				assign delayed_data_out = predelayed_data;
				assign delayed_oe = predelayed_oe;
				assign delayed_oct = aligned_oct [pin_num];
			end
		
			if (PIN_TYPE == "output")
			begin
				
				stratixiv_io_obuf data_out (
					.i (delayed_data_out),
					.o (write_data_out [pin_num]),
					.oe (~delayed_oe),
					.parallelterminationcontrol	(parallelterminationcontrol_in),
					.seriesterminationcontrol	(seriesterminationcontrol_in)					
				);
			end
			else if (PIN_TYPE == "bidir")
			begin
				
				stratixiv_io_obuf data_out (
					.oe (~delayed_oe),
					.i (delayed_data_out),
					.o (read_write_data_io [pin_num]),
					.parallelterminationcontrol	(parallelterminationcontrol_in),
					.dynamicterminationcontrol	(delayed_oct),
					.seriesterminationcontrol	(seriesterminationcontrol_in)
				);
			end
		end
	end
endgenerate

generate
	genvar epin_num;
	for (epin_num = 0; epin_num < EXTRA_OUTPUT_WIDTH; epin_num = epin_num + 1)
	begin :extra_output_pad_gen
		wire fr_data_hi;
		wire fr_data_lo;
		wire aligned_data;

		if (USE_HALF_RATE_OUTPUT == "true")
		begin
			wire hr_data_t0;
			wire hr_data_t1;
			wire hr_data_t2;
			wire hr_data_t3;
			
			if (REGULAR_WRITE_BUS_ORDERING == "true")
		  	begin
				assign hr_data_t0 = extra_write_data_in [epin_num + 0*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t1 = extra_write_data_in [epin_num + 1*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t2 = extra_write_data_in [epin_num + 2*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t3 = extra_write_data_in [epin_num + 3*EXTRA_OUTPUT_WIDTH];
			end
			else
		  	begin
				
				
				assign hr_data_t0 = extra_write_data_in [epin_num + 2*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t1 = extra_write_data_in [epin_num + 0*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t2 = extra_write_data_in [epin_num + 3*EXTRA_OUTPUT_WIDTH];
				assign hr_data_t3 = extra_write_data_in [epin_num + 1*EXTRA_OUTPUT_WIDTH];
			end
		
			stratixiv_ddio_out
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")
			) hr_to_fr_hi (							    
				.datainhi(hr_data_t2),
				.datainlo(hr_data_t0),
				.dataout(fr_data_hi),
				.clkhi (hr_clock_in),
				.clklo (hr_clock_in),
				.muxsel (hr_clock_in)
			);

			stratixiv_ddio_out
			#(
				.half_rate_mode("true"),
				.use_new_clocking_model("true"),
				.async_mode("none")
			) hr_to_fr_lo (							    
				.datainhi(hr_data_t3),
				.datainlo(hr_data_t1),
				.dataout(fr_data_lo),
				.clkhi (hr_clock_in),
				.clklo (hr_clock_in),
				.muxsel (hr_clock_in)
			);
		end
		else
		begin
			assign fr_data_lo = extra_write_data_in [epin_num+EXTRA_OUTPUT_WIDTH];
			assign fr_data_hi = extra_write_data_in [epin_num];	
		end
		
		if (USE_OUTPUT_PHASE_ALIGNMENT == "true")
		begin
			int dqs_index = (epin_num+NUM_STROBES+PIN_WIDTH)/PINS_PER_DQS_CONFIG;
			stratixiv_output_phase_alignment 
			#(
				.use_phasectrlin(USE_DYNAMIC_CONFIG),
				.use_phasectrl_clock("true"),
				.use_delayed_clock("true"),
				
				.operation_mode("ddio_out"),
				.delay_buffer_mode("high"),
				.power_up("low"),
				.async_mode("none"),
				.sync_mode("none"),
				.use_primary_clock("true"),
				.add_phase_transfer_reg(DYNAMIC_MODE),
				.add_output_cycle_delay(DYNAMIC_MODE),
				.invert_phase(DYNAMIC_MODE),
				.bypass_input_register("false")
			) data_alignment(
				.datain({fr_data_hi,fr_data_lo}),
				.clk(fr_clock_in),
				.clkena (1'b1),
				.delayctrlin(dll_delay_value),
				.phasectrlin (dqoutputphasesetting[dqs_index]),
				.phaseinvertctrl (dqoutputphaseinvert[dqs_index]),
				.enaoutputcycledelay (enaoutputcycledelaysetting[dqs_index]),
				.enaphasetransferreg (enaoutputphasetransferreg[dqs_index]),
				.dataout(aligned_data)
			);
		end
		else
		begin

			stratixiv_ddio_out
			#(
				.async_mode("none"),
				.half_rate_mode("false"),
				.sync_mode("none"),
				.use_new_clocking_model("true")
			) ddio_out (
				.datainhi(fr_data_hi),
				.datainlo(fr_data_lo),
				.dataout(aligned_data),
				.clkhi (dq_shifted_clock),
				.clklo (dq_shifted_clock),
				.muxsel (dq_shifted_clock)
			);
		end
		
		wire delayed_data_out;
		wire [3:0] dq_outputdelaysetting1;
		wire [3:0] dq_outputdelaysetting2;
		wire [3:0] dq_inputdelaysetting;
		
		assign dq_outputdelaysetting2 [3] = 1'b0;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_outputdelaysetting1_dlc;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_outputdelaysetting2_dlc;
		wire [DELAY_CHAIN_WIDTH-1:0] dq_inputdelaysetting_dlc;


		wire predelayed_data;
	
		if (USE_2X_FF == "true")
		begin
			reg dd_data;
			always @(posedge dq_dr_clock)
			begin
				dd_data <= aligned_data;
			end
			assign predelayed_data = dd_data;
		end
		else
		begin
			assign predelayed_data = aligned_data;
		end
	
		if (USE_DYNAMIC_CONFIG == "true")
		begin	
			stratixiv_io_config config_1 (
				.datain(config_data_in),          
				.clk(config_clock_in),
				.ena(config_extra_io_ena[epin_num]),
				.update(config_update),       

				.outputdelaysetting1(dq_outputdelaysetting1),
				.outputdelaysetting2(dq_outputdelaysetting2),
				.padtoinputregisterdelaysetting(dq_inputdelaysetting),
				.dataout()
			);
		
			
			assign dq_outputdelaysetting1_dlc = dq_outputdelaysetting1;
			assign dq_outputdelaysetting2_dlc = dq_outputdelaysetting2;
			assign dq_inputdelaysetting_dlc = dq_inputdelaysetting;

			wire delayed_data_1;
			
			stratixiv_delay_chain
			out_delay_1(						      
				.datain             (predelayed_data),
				.delayctrlin        (dq_outputdelaysetting1_dlc),
				.dataout            (delayed_data_1)
			);

			stratixiv_delay_chain
			out_delay_2(
				.datain             (delayed_data_1),
				.delayctrlin        (dq_outputdelaysetting2_dlc),
				.dataout            (delayed_data_out)
			);
		end
		else
		begin
			assign delayed_data_out = predelayed_data;
		end
		stratixiv_io_obuf obuf_1 (
			.i (delayed_data_out),
			.o (extra_write_data_out[epin_num]),
			.parallelterminationcontrol(parallelterminationcontrol_in),
			.seriesterminationcontrol(seriesterminationcontrol_in),
			.oe (1'b1)
		);
	end
endgenerate
endmodule
