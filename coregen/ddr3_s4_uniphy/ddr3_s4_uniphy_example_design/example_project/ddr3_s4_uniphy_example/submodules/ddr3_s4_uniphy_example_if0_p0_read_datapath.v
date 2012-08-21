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
// File name: read_datapath.v
// The read datapath is responsible for read data resynchronization from the memory clock domain to the AFI clock domain.
// It contains 1 FIFO per DQS group for read valid prediction and 1 FIFO per DQS group for read data synchronization.
// ******************************************************************************************************************************** 

`timescale 1 ps / 1 ps

// altera message_off 10036
module ddr3_s4_uniphy_example_if0_p0_read_datapath(
	reset_n_afi_clk,
	seq_read_fifo_reset,
	reset_n_resync_clk,
	pll_dqs_ena_clk,
	read_capture_clk,
	ddio_phy_dq,
	pll_afi_clk,
	seq_read_latency_counter,
	seq_read_increment_vfifo_fr,
	seq_read_increment_vfifo_hr,
	seq_read_increment_vfifo_qr,
	afi_rdata_en,
	afi_rdata_en_full,
	afi_rdata,
	phy_mux_read_fifo_q,
	force_oct_off,
	dqs_enable_ctrl,
	afi_rdata_valid,
	seq_calib_init,
	dqs_edge_detect
);

// ******************************************************************************************************************************** 
// BEGIN PARAMETER SECTION
// All parameters default to "" will have their values passed in from higher level wrapper with the controller and driver 

parameter DEVICE_FAMILY = "";

// PHY-Memory Interface
parameter MEM_ADDRESS_WIDTH     = ""; 
parameter MEM_DM_WIDTH          = ""; 
parameter MEM_CONTROL_WIDTH     = ""; 
parameter MEM_DQ_WIDTH          = ""; 
parameter MEM_READ_DQS_WIDTH    = ""; 
parameter MEM_WRITE_DQS_WIDTH   = ""; 

// PHY-Controller (AFI) Interface
parameter AFI_ADDRESS_WIDTH         = ""; 
parameter AFI_DATA_MASK_WIDTH       = ""; 
parameter AFI_CONTROL_WIDTH         = ""; 
parameter AFI_DATA_WIDTH            = ""; 
parameter AFI_DQS_WIDTH				= "";

// Read Datapath
parameter MAX_LATENCY_COUNT_WIDTH          = "";
parameter MAX_READ_LATENCY                 = "";
parameter READ_FIFO_READ_MEM_DEPTH         = "";
parameter READ_FIFO_READ_ADDR_WIDTH        = "";
parameter READ_FIFO_WRITE_MEM_DEPTH        = "";
parameter READ_FIFO_WRITE_ADDR_WIDTH       = "";
parameter READ_VALID_FIFO_SIZE             = "";
parameter READ_VALID_FIFO_READ_MEM_DEPTH   = "";
parameter READ_VALID_FIFO_READ_ADDR_WIDTH  = "";
parameter READ_VALID_FIFO_WRITE_MEM_DEPTH  = "";
parameter READ_VALID_FIFO_WRITE_ADDR_WIDTH = "";
parameter READ_VALID_FIFO_PER_DQS_WIDTH    = "";
parameter NUM_SUBGROUP_PER_READ_DQS        = "";
parameter MEM_T_RL                         = "";
parameter QVLD_EXTRA_FLOP_STAGES           = "";
parameter QVLD_WR_ADDRESS_OFFSET           = "";

// Width of the calibration status register used to control calibration skipping.
parameter CALIB_REG_WIDTH		= "";
parameter FAST_SIM_MODEL                   = "";

// Local parameters
localparam RATE_MULT = 2;

localparam DOUBLE_MEM_DQ_WIDTH = MEM_DQ_WIDTH * 2;
localparam DQ_GROUP_WIDTH = MEM_DQ_WIDTH / MEM_READ_DQS_WIDTH;
localparam USE_NUM_SUBGROUP_PER_READ_DQS = FAST_SIM_MODEL ? 1 : NUM_SUBGROUP_PER_READ_DQS;
localparam AFI_DQ_GROUP_DATA_WIDTH = AFI_DATA_WIDTH / MEM_READ_DQS_WIDTH;
localparam DDIO_DQ_GROUP_DATA_WIDTH = DOUBLE_MEM_DQ_WIDTH / MEM_READ_DQS_WIDTH;
localparam DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP = DOUBLE_MEM_DQ_WIDTH / (MEM_READ_DQS_WIDTH * USE_NUM_SUBGROUP_PER_READ_DQS);
localparam QVLD_SHIFTER_LENGTH = (2 ** READ_VALID_FIFO_WRITE_ADDR_WIDTH) + QVLD_EXTRA_FLOP_STAGES;



localparam VFIFO_RATE_MULT = 2;

localparam READ_FIFO_DQ_GROUP_OUTPUT_WIDTH = 4 * DQ_GROUP_WIDTH;

localparam OCT_ON_DELAY = (MEM_T_RL > 4) ? ((MEM_T_RL - 4) / 2) : 0;
localparam OCT_OFF_DELAY = (MEM_T_RL + 6) / 2;

// END PARAMETER SECTION
// ******************************************************************************************************************************** 

input	reset_n_afi_clk;
input	[MEM_READ_DQS_WIDTH-1:0] seq_read_fifo_reset; // reset from sequencer to read and write pointers of the data resynchronization FIFO
input	[MEM_READ_DQS_WIDTH-1:0] read_capture_clk;
input	reset_n_resync_clk;
input	pll_dqs_ena_clk;
input	[DOUBLE_MEM_DQ_WIDTH-1:0] ddio_phy_dq;
input	pll_afi_clk;
input	[MAX_LATENCY_COUNT_WIDTH-1:0] seq_read_latency_counter;
input	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_fr;	// increment valid prediction FIFO write pointer by an extra full rate cycle
input	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_hr;	// increment valid prediction FIFO write pointer by an extra half rate cycle
																// in full rate core, both will mean an extra full rate cycle
input	[MEM_READ_DQS_WIDTH-1:0] seq_read_increment_vfifo_qr;	// increment valid prediction FIFO write pointer by an extra quarter rate cycle.
																// not used in full/half rate core

input	afi_rdata_en;
input	afi_rdata_en_full;

output	[AFI_DATA_WIDTH-1:0] afi_rdata;
output	afi_rdata_valid;

// read data (no reordering) for indepedently FIFO calibrations (multiple FIFOs for multiple DQS groups)
output	[AFI_DATA_WIDTH-1:0] phy_mux_read_fifo_q;	

output	[AFI_DQS_WIDTH-1:0] force_oct_off;
output  [MEM_READ_DQS_WIDTH*READ_VALID_FIFO_PER_DQS_WIDTH-1:0] dqs_enable_ctrl;

output [MEM_READ_DQS_WIDTH-1:0] dqs_edge_detect;

input	[CALIB_REG_WIDTH-1:0] seq_calib_init;

reg		afi_rdata_valid;

reg [1:0] qvld_num_fr_cycle_shift [MEM_READ_DQS_WIDTH-1:0];

wire    [MEM_READ_DQS_WIDTH*READ_VALID_FIFO_PER_DQS_WIDTH-1:0] qvld;
wire	[MEM_READ_DQS_WIDTH-1:0] read_valid;
wire	[MEM_READ_DQS_WIDTH-1:0] valid_predict_clk;
wire	[MEM_READ_DQS_WIDTH-1:0] reset_n_valid_predict_clk;
reg		[MEM_READ_DQS_WIDTH-1:0] reset_n_fifo_write_side;
reg		[MEM_READ_DQS_WIDTH-1:0] reset_n_fifo_wraddress;

wire	[MEM_READ_DQS_WIDTH-1:0] read_capture_clk_pos;
wire	[MEM_READ_DQS_WIDTH-1:0] read_capture_clk_neg;
reg		[MEM_READ_DQS_WIDTH-1:0] read_capture_clk_div2;


wire	[AFI_DATA_WIDTH-1:0] read_fifo_output;
wire	read_fifo_read_clk = pll_afi_clk;
wire	reset_n_read_fifo_read_clk = reset_n_afi_clk;

wire	seq_calib_skip_vfifo;
assign seq_calib_skip_vfifo = seq_calib_init[3];

// *******************************************************************************************************************
// VALID PREDICTION
// Read request (afi_rdata_en) is generated on the AFI clock domain (pll_afi_clk).
// Read data is captured on the read_capture_clk domain (output clock from I/O). 
// The purpose of valid prediction is to determine which read_capture_clk cycle valid data will be returned to the core
// after the request is issued on pll_afi_clk; this is essentially the latency between read request seen on 
// AFI interface and valid data available at the output of ALTDQ_DQS.
// The clock domain crossing between pll_afi_clk and read_capture_clk is handled by a FIFO (uread_valid_fifo).
// The pll_afi_clk controls the write side of the FIFO and the read_capture_clk controls the read side.
// The pll_afi_clk writes into the FIFO on every clock cycle.  When there is no read request, it writes a 0;
// when there is a read request, it writes a 1 (refer to as a token) into the FIFO.
// The read_capture_clk reads from the FIFO every clock cycle, whenever it reads a token, it means that valid data
// is available during that cycle.  Each token represents 1 cycle of valid data.
// In full rate, BL=2, 1 read results in 1 AFI cycle of valid data, controller asserts afi_rdata_en for 1 cycle
// In full rate, BL=4, 1 read results in 2 AFI cycles of valid data, controller asserts afi_rdata_en for 2 cycles
// In full rate, BL=8, 1 read results in 4 AFI cycles of valid data, controller asserts afi_rdata_en for 4 cycles
// In half rate, BL=2, not supported
// In half rate, BL=4, 1 read results in 1 AFI cycle of valid data, controller asserts afi_rdata_en for 1 cycle
// In half rate, BL=8, 1 read results in 2 AFI cycle of valid data, controller asserts afi_rdata_en for 2 cycles
// In full rate, 1 afi_rdata_en cycle = 1 token
// In half rate, 1 afi_rdata_en cycle = 2 tokens
//
// After reset is released, the relationship between the read and write pointers can be arbitrary.
// During calibration, the sequencer keeps incrementing the write pointer (both the sequencer and write pointer operates
// on pll_afi_clk) until the correct latency has been tuned.
// *******************************************************************************************************************

assign valid_predict_clk = {MEM_READ_DQS_WIDTH{pll_dqs_ena_clk}};
assign reset_n_valid_predict_clk = {MEM_READ_DQS_WIDTH{reset_n_resync_clk}};

generate
genvar dqsgroup, vfifo_i;
	for (dqsgroup=0; dqsgroup<MEM_READ_DQS_WIDTH; dqsgroup=dqsgroup+1)
	begin: read_valid_predict
	
		wire [VFIFO_RATE_MULT-1:0] vfifo_out_per_dqs;
	
		reg [READ_VALID_FIFO_WRITE_ADDR_WIDTH-1:0] qvld_wr_address;

`ifndef SYNTH_FOR_SIM
 		// synthesis translate_off
`endif
		wire [ceil_log2(READ_VALID_FIFO_SIZE)-1:0] qvld_wr_address_offset;
		assign qvld_wr_address_offset = QVLD_WR_ADDRESS_OFFSET;
`ifndef SYNTH_FOR_SIM
 		// synthesis translate_on
`endif
		
		wire qvld_increment_wr_address = seq_read_increment_vfifo_hr[dqsgroup];
		
		// In half rate, 1 afi_rdata_en_full cycle = 2 tokens, qvld_in[0] and qvld_in[1]
		// In 1/4 rate, 1 afi_rdata_en_full cycle = 4 tokens, qvld_in[0..3]
		// etc.
		// Tokens are written at AFI clock rate but read at full rate.
		// During calibration the latency needs to be tuned at full rate granularity.
		// For example, in half rate, in the base case, 1 afi_rdata_en_full will result
		// in two tokens in write address 0, that means read address 0 and read address 1
		// will both have tokens. If the sequencer request to increase the latency by
		// full rate cycle, the write side first writes 10 into write address 0, then
		// it writes 01 into write address 1; this means there are tokens in read
		// address 1 and read address 2.
		always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
		begin
			if (~reset_n_afi_clk) begin
	`ifndef SYNTH_FOR_SIM
				// synthesis translate_off
	`endif
				qvld_num_fr_cycle_shift[dqsgroup] <= {1'b0, ((seq_calib_skip_vfifo) ? qvld_wr_address_offset[0] : 1'b0)};
	`ifndef SYNTH_FOR_SIM
				// synthesis translate_on
				// synthesis read_comments_as_HDL on
				// qvld_num_fr_cycle_shift[dqsgroup] <= 2'b00;
				// synthesis read_comments_as_HDL off
	`endif
			end else begin
				if (seq_read_increment_vfifo_fr[dqsgroup]) begin
					qvld_num_fr_cycle_shift[dqsgroup] <= 2'b01;
				end else if (seq_read_increment_vfifo_hr[dqsgroup]) begin
					qvld_num_fr_cycle_shift[dqsgroup] <= 2'b00;
				end
			end
		end	

		wire [RATE_MULT-1:0] qvld_in;
		ddr3_s4_uniphy_example_if0_p0_fr_cycle_shifter uread_fr_cycle_shifter(
			.clk (pll_afi_clk),
			.reset_n (reset_n_afi_clk),
			.shift_by (qvld_num_fr_cycle_shift[dqsgroup]),
			.datain ({RATE_MULT{afi_rdata_en_full}}),
			.dataout (qvld_in));
		defparam uread_fr_cycle_shifter.DATA_WIDTH = 1;
		

		always @(posedge pll_afi_clk)
		begin
`ifndef SYNTH_FOR_SIM
			// synthesis translate_off
`endif
			if (~reset_n_afi_clk) begin
				qvld_wr_address <= (seq_calib_skip_vfifo) ? (qvld_wr_address_offset >> ceil_log2(RATE_MULT)) : {READ_VALID_FIFO_WRITE_ADDR_WIDTH{1'b0}};
`ifndef SYNTH_FOR_SIM
			// synthesis translate_on
			// synthesis read_comments_as_HDL on
			// if (~reset_n_afi_clk) begin
			// 	qvld_wr_address <= {READ_VALID_FIFO_WRITE_ADDR_WIDTH{1'b0}};
			// synthesis read_comments_as_HDL off
`endif
			end else begin
				qvld_wr_address <= qvld_increment_wr_address ? (qvld_wr_address + 2'd1) : qvld_wr_address;
			end
		end

		// The valid-prediction FIFO is implemented as a shift-register
		for (vfifo_i=0; vfifo_i<VFIFO_RATE_MULT; vfifo_i=vfifo_i+1)
		begin: qvld_shifter_gen
			reg [QVLD_SHIFTER_LENGTH-1:0] qvld_shifter;
			
			always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
			begin
				if (~reset_n_afi_clk) begin
					qvld_shifter <= {QVLD_SHIFTER_LENGTH{1'b0}};
				end	else begin
					qvld_shifter <= {1'b0, qvld_shifter[QVLD_SHIFTER_LENGTH-1:1]};
					qvld_shifter[qvld_wr_address+QVLD_EXTRA_FLOP_STAGES] <= qvld_in[vfifo_i];
				end
		 	end
			
			assign vfifo_out_per_dqs[vfifo_i] = qvld_shifter[0];
		end

		wire [READ_VALID_FIFO_PER_DQS_WIDTH-1:0] qvld_per_dqs = vfifo_out_per_dqs;
		
		// Map per-dqs vfifo output bus to the per-interface vfifo output bus.
		for (vfifo_i=0; vfifo_i<READ_VALID_FIFO_PER_DQS_WIDTH; vfifo_i=vfifo_i+1)
		begin: map_qvld_per_dqs_to_qvld
			assign qvld[dqsgroup+(vfifo_i*MEM_READ_DQS_WIDTH)] = qvld_per_dqs[vfifo_i];
		end
	end
endgenerate

assign dqs_enable_ctrl = qvld;

reg	[MAX_READ_LATENCY-1:0] latency_shifter;
reg	[MAX_READ_LATENCY-1:0] full_latency_shifter;

always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
begin
	if (~reset_n_afi_clk) begin
		full_latency_shifter <= {MAX_READ_LATENCY{1'b0}};
		latency_shifter <= {MAX_READ_LATENCY{1'b0}};
	end
	else begin
		full_latency_shifter <= {full_latency_shifter[MAX_READ_LATENCY-2:0], afi_rdata_en_full};
		latency_shifter <= {latency_shifter[MAX_READ_LATENCY-2:0], afi_rdata_en};
	end
end
	

generate
genvar dqs_count, subgroup, dq_count, timeslot;
	for (dqs_count=0; dqs_count<MEM_READ_DQS_WIDTH; dqs_count=dqs_count+1)
	begin: read_buffering

		wire	[USE_NUM_SUBGROUP_PER_READ_DQS-1:0] wren;
		wire	[USE_NUM_SUBGROUP_PER_READ_DQS-1:0] wren_neg;
		wire	read_enable;
		wire	[READ_FIFO_DQ_GROUP_OUTPUT_WIDTH-1:0] read_fifo_output_per_dqs;
		
		// Perform read data mapping from ddio_phy_dq to ddio_phy_dq_per_dqs.
		//
		// The ddio_phy_dq bus is the read data coming out of the DDIO, and so
		// is 2x the interface data width. The bus is ordered by DQS group
		// and sub-ordered by time slot:
		// 
		// D1_T1, D1_T0, D0_T1, D0_T0
		//
		// The ddio_phy_dq_per_dqs bus is a subset of the ddio_phy_dq bus that
		// is specific to the current DQS group. Like ddio_phy_dq, it's ordered
		// by time slot:
		//
		// D0_T1, D0_T0
		wire	[DDIO_DQ_GROUP_DATA_WIDTH-1:0] ddio_phy_dq_per_dqs;
		assign ddio_phy_dq_per_dqs = ddio_phy_dq[(DDIO_DQ_GROUP_DATA_WIDTH*(dqs_count+1)-1) : (DDIO_DQ_GROUP_DATA_WIDTH*dqs_count)];
		
		ddr3_s4_uniphy_example_if0_p0_read_valid_selector uread_valid_selector(
			.reset_n		(reset_n_afi_clk),
			.pll_afi_clk		(pll_afi_clk),
			.latency_shifter	(latency_shifter),
			.latency_counter	(seq_read_latency_counter),
			.read_enable		(),
			.read_valid		(read_valid[dqs_count])
		);
		defparam uread_valid_selector.MAX_LATENCY_COUNT_WIDTH = MAX_LATENCY_COUNT_WIDTH;
		ddr3_s4_uniphy_example_if0_p0_read_valid_selector uread_valid_full_selector(
			.reset_n		(reset_n_afi_clk),
			.pll_afi_clk		(pll_afi_clk),
			.latency_shifter	(full_latency_shifter),
			.latency_counter	(seq_read_latency_counter),
			.read_enable		(read_enable),
			.read_valid		()
		);
		defparam uread_valid_full_selector.MAX_LATENCY_COUNT_WIDTH = MAX_LATENCY_COUNT_WIDTH;

		always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
		begin
			if (~reset_n_afi_clk) begin
				reset_n_fifo_write_side[dqs_count] <= 1'b0;
				reset_n_fifo_wraddress[dqs_count] <= 1'b0;
			end
			else begin
				reset_n_fifo_write_side[dqs_count] <= ~seq_read_fifo_reset[dqs_count];
				reset_n_fifo_wraddress[dqs_count] <= ~seq_read_fifo_reset[dqs_count];
			end
		end
		
		wire	[READ_FIFO_DQ_GROUP_OUTPUT_WIDTH-1:0] read_fifo_output_per_dqs_tmp;

		always @(posedge read_capture_clk[dqs_count] or negedge reset_n_fifo_write_side[dqs_count])
		begin
			if (~reset_n_fifo_write_side[dqs_count])
				read_capture_clk_div2[dqs_count] <= 1'b0;
			else
				read_capture_clk_div2[dqs_count] <= ~read_capture_clk_div2[dqs_count];
		end

		`ifndef SIMGEN
		assign #10 read_capture_clk_pos[dqs_count] = read_capture_clk_div2[dqs_count];
		`else
		ddr3_s4_uniphy_example_if0_p0_sim_delay #(
				.delay(10)
			)
			sim_delay_inst(
				.o(read_capture_clk_pos[dqs_count]),
				.i(read_capture_clk_div2[dqs_count]),
			);
		`endif
		assign read_capture_clk_neg[dqs_count] = ~read_capture_clk_pos[dqs_count];

		for (subgroup=0; subgroup<USE_NUM_SUBGROUP_PER_READ_DQS; subgroup=subgroup+1)
		begin: read_subgroup

 			assign wren[subgroup] = 1'b1;
 			assign wren_neg[subgroup] = 1'b1;

			reg	[READ_FIFO_WRITE_ADDR_WIDTH-1:0] wraddress /* synthesis dont_merge */;
			reg	[READ_FIFO_WRITE_ADDR_WIDTH-1:0] wraddress_neg /* synthesis dont_merge */;

			// The clock is read_capture_clk while reset_n_fifo_wraddress is a signal synchronous to
			// the AFI clk domain but asynchronous to read_capture_clk. reset_n_fifo_wraddress goes
			// '0' when either the system is reset, or when the sequencer asserts seq_read_fifo_reset.
			// By design we ensure that wren has been '0' for at least one cycle when reset_n_fifo_wraddress
			// is deasserted (i.e. '0' -> '1'). When wren is '0', the input and output of the
			// wraddress registers are both '0', so there's no risk of metastability due to reset
			// recovery.
			always @(posedge read_capture_clk_pos[dqs_count] or negedge reset_n_fifo_wraddress[dqs_count])
			begin
				if (~reset_n_fifo_wraddress[dqs_count])
					wraddress <= {READ_FIFO_WRITE_ADDR_WIDTH{1'b0}};
				else if (wren[subgroup])
				begin
					if (READ_FIFO_WRITE_MEM_DEPTH == 2 ** READ_FIFO_WRITE_ADDR_WIDTH)
						wraddress <= wraddress + 1'b1;
					else
						wraddress <= (wraddress == READ_FIFO_WRITE_MEM_DEPTH - 1) ? {READ_FIFO_WRITE_ADDR_WIDTH{1'b0}} : wraddress + 1'b1;
				end
			end

			always @(posedge read_capture_clk_neg[dqs_count] or negedge reset_n_fifo_wraddress[dqs_count])
			begin
				if (~reset_n_fifo_wraddress[dqs_count])
					wraddress_neg <= {READ_FIFO_WRITE_ADDR_WIDTH{1'b0}};
				else if (wren_neg[subgroup])
				begin
					if (READ_FIFO_WRITE_MEM_DEPTH == 2 ** READ_FIFO_WRITE_ADDR_WIDTH)
						wraddress_neg <= wraddress_neg + 1'b1;
					else
						wraddress_neg <= (wraddress_neg == READ_FIFO_WRITE_MEM_DEPTH - 1) ? {READ_FIFO_WRITE_ADDR_WIDTH{1'b0}} : wraddress_neg + 1'b1;
				end
			end

			reg	[READ_FIFO_READ_ADDR_WIDTH-1:0] rdaddress /* synthesis dont_merge */;

			always @(posedge read_fifo_read_clk)
			begin
				if (seq_read_fifo_reset[dqs_count])
					rdaddress <= {READ_FIFO_READ_ADDR_WIDTH{1'b0}};
				else if (read_enable)
				begin
					if (READ_FIFO_READ_MEM_DEPTH == 2 ** READ_FIFO_READ_ADDR_WIDTH)
						rdaddress <= rdaddress + 1'b1;
					else
						rdaddress <= (rdaddress == READ_FIFO_READ_MEM_DEPTH - 1) ? {READ_FIFO_READ_ADDR_WIDTH{1'b0}} : rdaddress + 1'b1;
				end
			end

			ddr3_s4_uniphy_example_if0_p0_flop_mem	uread_fifo(
				.wr_clk     (read_capture_clk_pos[dqs_count]),
				.wr_en		(wren[subgroup]),
				.wr_addr	(wraddress),
				.wr_data	(ddio_phy_dq_per_dqs[(DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*(subgroup+1)-1) : 
							 (DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*subgroup)]),
				.rd_reset_n (reset_n_read_fifo_read_clk),
				.rd_clk		(read_fifo_read_clk),
				.rd_en		(read_enable),
				.rd_addr	(rdaddress),
				.rd_data	(read_fifo_output_per_dqs_tmp[(DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*(subgroup+1)-1) :
							 (DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*subgroup)])		
			);
			defparam uread_fifo.WRITE_MEM_DEPTH = READ_FIFO_WRITE_MEM_DEPTH;
			defparam uread_fifo.WRITE_ADDR_WIDTH = READ_FIFO_WRITE_ADDR_WIDTH;
			defparam uread_fifo.WRITE_DATA_WIDTH = DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP;
			defparam uread_fifo.READ_MEM_DEPTH = READ_FIFO_READ_MEM_DEPTH;
			defparam uread_fifo.READ_ADDR_WIDTH = READ_FIFO_READ_ADDR_WIDTH;
			defparam uread_fifo.READ_DATA_WIDTH = READ_FIFO_DQ_GROUP_OUTPUT_WIDTH / (USE_NUM_SUBGROUP_PER_READ_DQS * 2);

			ddr3_s4_uniphy_example_if0_p0_flop_mem	uread_fifo_neg(
				.wr_clk		(read_capture_clk_neg[dqs_count]),
				.wr_en		(wren_neg[subgroup]),
				.wr_addr	(wraddress_neg),
				.wr_data	(ddio_phy_dq_per_dqs[(DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*(subgroup+1)-1) : 
							 (DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*subgroup)]),
				.rd_reset_n (reset_n_read_fifo_read_clk),
				.rd_clk		(read_fifo_read_clk),
				.rd_en		(read_enable),
				.rd_addr	(rdaddress),
				.rd_data	(read_fifo_output_per_dqs_tmp[(DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*(subgroup+1)-1+DDIO_DQ_GROUP_DATA_WIDTH) :
							 (DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP*subgroup+DDIO_DQ_GROUP_DATA_WIDTH)])
			);
			defparam uread_fifo_neg.WRITE_MEM_DEPTH = READ_FIFO_WRITE_MEM_DEPTH;
			defparam uread_fifo_neg.WRITE_ADDR_WIDTH = READ_FIFO_WRITE_ADDR_WIDTH;
			defparam uread_fifo_neg.WRITE_DATA_WIDTH = DDIO_DQ_GROUP_DATA_WIDTH_SUBGROUP;
			defparam uread_fifo_neg.READ_MEM_DEPTH = READ_FIFO_READ_MEM_DEPTH;
			defparam uread_fifo_neg.READ_ADDR_WIDTH = READ_FIFO_READ_ADDR_WIDTH;
			defparam uread_fifo_neg.READ_DATA_WIDTH = READ_FIFO_DQ_GROUP_OUTPUT_WIDTH / (USE_NUM_SUBGROUP_PER_READ_DQS * 2);
		end

		assign read_fifo_output_per_dqs = read_fifo_output_per_dqs_tmp;

		// Perform mapping from read_fifo_output_per_dqs to read_fifo_output
		//
		// The read_fifo_output_per_dqs bus is the read data coming out of the read FIFO.
		// It has the read data for the current dqs group. In FR, it has 2x the
		// width of a dqs group on the interface. In HR, it has 4x the width of
		// a dqs group on the interface. The bus is ordered by time slot:
		//
		// FR: D0_T1, D0_T0
		// HR: D0_T3, D0_T2, D0_T1, D0_T0
		//
		// The read_fifo_output bus is the read data from read fifo. In FR, it has
		// the same width as ddio_phy_dq (i.e. 2x interface width). In HR, it has
		// 4x the interface width. The bus is ordered by time slot and
		// sub-ordered by DQS group:
		//
		// FR: D1_T1, D0_T1, D1_T0, D0_T0
		// HR: D1_T3, D0_T3, D1_T2, D0_T2, D1_T1, D0_T1, D1_T0, D0_T0
		//
		for (timeslot=0; timeslot<4; timeslot=timeslot+1)
		begin: read_mapping_timeslot
			wire [DQ_GROUP_WIDTH-1:0] rdata = read_fifo_output_per_dqs[DQ_GROUP_WIDTH * (timeslot + 1) - 1 : DQ_GROUP_WIDTH * timeslot];
			assign read_fifo_output[DQ_GROUP_WIDTH * (dqs_count + 1) + MEM_DQ_WIDTH * timeslot - 1 : DQ_GROUP_WIDTH * dqs_count + MEM_DQ_WIDTH * timeslot] = rdata;
		end
	end
endgenerate

// Data from read-fifo is synchronous to the AFI clock and so can be sent
// directly to the afi_rdata bus. 
assign afi_rdata = read_fifo_output;

// Perform data re-mapping from afi_rdata to phy_mux_read_fifo_q
//
// The afi_rdata bus is the read data going out to the AFI. In FR, it has
// the same width as ddio_phy_dq (i.e. 2x interface width). In HR, it has
// 4x the interface width. The bus is ordered by time slot and
// sub-ordered by DQS group:
//
// FR: D1_T1, D0_T1, D1_T0, D0_T0
// HR: D1_T3, D0_T3, D1_T2, D0_T2, D1_T1, D0_T1, D1_T0, D0_T0
//
// The phy_mux_read_fifo_q bus is the read data going into the sequencer
// for calibration. It has the same width as afi_rdata. The bus is ordered
// by DQS group, and sub-ordered by time slot:
//
// FR: D1_T1, D1_T0, D0_T1, D0_T0
// HR: D1_T3, D1_T2, D1_T1, D1_T0, D0_T3, D0_T2, D0_T1, D0_T0
//
//As of Nov 1 2010, the NIOS sequencer doesn't use the phy_mux_read_fifo_q signal.
generate 
genvar k, t;
	for (k=0; k<MEM_READ_DQS_WIDTH; k=k+1)
	begin: read_mapping_for_seq
		wire [AFI_DQ_GROUP_DATA_WIDTH-1:0] rdata_per_dqs_group;

		for (t=0; t<RATE_MULT*2; t=t+1)
		begin: build_rdata_per_dqs_group
			wire [DQ_GROUP_WIDTH-1:0] rdata_t = afi_rdata[DQ_GROUP_WIDTH * (k+1) + MEM_DQ_WIDTH * t - 1 : DQ_GROUP_WIDTH * k + MEM_DQ_WIDTH * t];
			assign rdata_per_dqs_group[(t+1)*DQ_GROUP_WIDTH-1:t*DQ_GROUP_WIDTH] = rdata_t;
		end
		assign phy_mux_read_fifo_q[(k+1)*AFI_DQ_GROUP_DATA_WIDTH-1 : k*AFI_DQ_GROUP_DATA_WIDTH] = rdata_per_dqs_group;
	end
endgenerate

// Generate an AFI read valid signal from all the read valid signals from all FIFOs
always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
begin
	if (~reset_n_afi_clk) begin
		afi_rdata_valid <= 1'b0;
	end else begin
		afi_rdata_valid <= &read_valid;
	end
end

reg		[AFI_DQS_WIDTH-1:0] force_oct_off;

generate
genvar oct_num;
for (oct_num = 0; oct_num < AFI_DQS_WIDTH; oct_num = oct_num + 1)
begin : oct_gen
	reg		[OCT_OFF_DELAY-1:0] rdata_en_r /* synthesis dont_merge */;
	wire [OCT_OFF_DELAY:0] rdata_en_shifter;

	assign rdata_en_shifter = {rdata_en_r,afi_rdata_en_full};
	always @(posedge pll_afi_clk or negedge reset_n_afi_clk)
	begin
		if (~reset_n_afi_clk)
		begin
			rdata_en_r <= {OCT_OFF_DELAY{1'b0}};
			force_oct_off[oct_num] = 1'b0;
		end
		else
		begin
			rdata_en_r <= {rdata_en_r[OCT_OFF_DELAY-2:0],afi_rdata_en_full};
			force_oct_off[oct_num] = ~(|rdata_en_shifter[OCT_OFF_DELAY:OCT_ON_DELAY]);
		end
	end
end
endgenerate

wire [MEM_READ_DQS_WIDTH-1:0] dqs_detect_reset_n;
reg [MEM_READ_DQS_WIDTH-1:0] dqs_edge_detect_reg;

generate
genvar dqs_detect_count;
	
	for (dqs_detect_count=0; dqs_detect_count<MEM_READ_DQS_WIDTH; dqs_detect_count=dqs_detect_count+1)
	begin: dqs_detection

	always @(posedge read_capture_clk_pos[dqs_detect_count] or negedge reset_n_fifo_write_side[dqs_detect_count])
		if (~reset_n_fifo_write_side[dqs_detect_count])
			dqs_edge_detect_reg[dqs_detect_count] <= 0;
		else
			dqs_edge_detect_reg[dqs_detect_count] <= 1;
	end
	
endgenerate 
assign dqs_edge_detect = dqs_edge_detect_reg;

// Calculate the ceiling of log_2 of the input value
function integer ceil_log2;
	input integer value;
	begin
		value = value - 1;
		for (ceil_log2 = 0; value > 0; ceil_log2 = ceil_log2 + 1)
			value = value >> 1;
	end
endfunction

endmodule
