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


//USER ******
//USER phy_mgr
//USER ******
//USER
//USER PHY Manager
//USER
//USER General Description
//USER -------------------
//USER
//USER This component allows a way for a master on the Avalon bus to
//USER control various aspects of the PHY connection.
//USER
//USER Architecture
//USER ------------
//USER
//USER The PHY Manager is organized as follows
//USER    - Avalon Interface: it's a Memory-Mapped interface to the Avalon
//USER      Bus.
//USER    - Register File: it's a set of registers used to control the functioning
//USER		of the PHY. This register file can be read and written from the Avalon
//USER      interface and can only be read by the PHY.
//USER	  - Command Issue: a write to this port runs a particular sequence at PHY
//USER		speeds. 
//USER
//USER Address Space
//USER -------------
//USER
//USER The address space is divided into 2 identical portions.
//USER The most significant bit select one of the internal components.
//USER The rest of the address word (whose size depend on parameterization)
//USER is used to access a specific location of the selected component.
//USER
//USER 0 - Instruction/Configuration Address.
//USER     Data written to this component is intepreted as a command.
//USER	   Data read from this component returns various parameters specific
//USER	   to the PHY manager.
//USER     During read, case (lower address bits)
//USER			000: returns MAX_LATENCY_COUNT_WIDTH
//USER			001: returns AFI_MAX_WRITE_LATENCY_COUNT_WIDTH
//USER			010: returns AFI_MAX_READ_LATENCY_COUNT_WIDTH
//USER     During write, case (lower address bits)
//USER			000: increments vfifo_fr specified by word being written
//USER			001: increments vfifo_hr specified by word being written
//USER			010: resets the fifo.
//USER			(the following only used by quarter-rate PHY)
//USER			011: asserts vfifo_fr and vfifo_hr
//USER			100: asserts vfifo_qr
//USER
//USER 1 - Register File.
//USER	   8 registers controlling various aspects of the PHY are provided.
//USER	   The lowest three bits are used to address the specific register
//USER	   begin read/written from/to.
//USER	   During reads/writes, case (lower address bits)
//USER			000: returns/sets read latency counter
//USER			001: returns/sets mem stable bit.
//USER

module sequencer_phy_mgr (
	//USER Avalon Interface
	
	avl_clk,
	avl_reset_n,
	avl_address,
	avl_write,
	avl_writedata,
	avl_read,
	avl_readdata,
	avl_waitrequest,

	//USER PHY control

	phy_clk,
	phy_reset_n,
	phy_read_latency_counter,
	phy_read_increment_vfifo_fr,
	phy_read_increment_vfifo_hr,
	phy_read_increment_vfifo_qr,
	phy_reset_mem_stable,
	phy_afi_wlat,
	phy_afi_rlat,
	phy_mux_sel,
	phy_cal_success,
	phy_cal_fail,
	phy_cal_debug_info,
	phy_read_fifo_reset,
	phy_vfifo_rd_en_override,

	calib_skip_steps
);

	parameter AVL_DATA_WIDTH = 32;
	parameter AVL_ADDR_WIDTH = 13;

	parameter MAX_LATENCY_COUNT_WIDTH = 5;
	parameter MEM_READ_DQS_WIDTH = 1;
	parameter AFI_DEBUG_INFO_WIDTH = 32;
	parameter AFI_MAX_WRITE_LATENCY_COUNT_WIDTH = 5;
	parameter AFI_MAX_READ_LATENCY_COUNT_WIDTH	= 5;
	parameter CALIB_VFIFO_OFFSET = 10;
	parameter CALIB_LFIFO_OFFSET = 3;
	parameter CALIB_SKIP_STEPS_WIDTH = 8;
	parameter READ_VALID_FIFO_SIZE = 16;
	parameter MEM_T_WL = 1;
	parameter MEM_T_RL = 2;
	parameter CTL_REGDIMM_ENABLED = 0;

	input avl_clk;
	input avl_reset_n;
	input [AVL_ADDR_WIDTH - 1:0] avl_address;
	input avl_write;
	input [AVL_DATA_WIDTH - 1:0] avl_writedata;
	input avl_read;
	output [AVL_DATA_WIDTH - 1:0] avl_readdata;
	output avl_waitrequest;

	input phy_clk;
	input phy_reset_n;
	output [MAX_LATENCY_COUNT_WIDTH - 1:0] phy_read_latency_counter;
	output [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_fr;
	output [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_hr;
	output [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_qr;
	output phy_reset_mem_stable;
	output [AFI_MAX_WRITE_LATENCY_COUNT_WIDTH - 1:0] phy_afi_wlat;
	output [AFI_MAX_READ_LATENCY_COUNT_WIDTH - 1:0] phy_afi_rlat;
	output phy_mux_sel;
	output phy_cal_success;
	output phy_cal_fail;
	output [AFI_DEBUG_INFO_WIDTH - 1:0] phy_cal_debug_info;
	output [MEM_READ_DQS_WIDTH - 1:0] phy_read_fifo_reset;
	output [MEM_READ_DQS_WIDTH - 1:0] phy_vfifo_rd_en_override;

	input [CALIB_SKIP_STEPS_WIDTH - 1:0] calib_skip_steps;
	
	reg avl_waitrequest;
	reg [AVL_DATA_WIDTH - 1:0] avl_readdata_r;
	reg [AVL_DATA_WIDTH - 1:0] avl_readdata;

	reg avl_rfile_wr;
	reg avl_issue_wr;
	reg [MEM_READ_DQS_WIDTH - 1:0] avl_read_increment_vfifo_fr;
	reg [MEM_READ_DQS_WIDTH - 1:0] avl_read_increment_vfifo_hr;
	reg [MEM_READ_DQS_WIDTH - 1:0] avl_read_increment_vfifo_qr;
	reg avl_read_fifo_reset;
	
	reg [MAX_LATENCY_COUNT_WIDTH - 1:0] phy_read_latency_counter;
	reg [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_fr;
	reg [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_hr;
	reg [MEM_READ_DQS_WIDTH - 1:0] phy_read_increment_vfifo_qr;
	reg phy_reset_mem_stable;
	reg [AFI_MAX_WRITE_LATENCY_COUNT_WIDTH - 1:0] phy_afi_wlat;
	reg [AFI_MAX_READ_LATENCY_COUNT_WIDTH - 1:0] phy_afi_rlat;
	reg phy_mux_sel;
	reg phy_cal_success;
	reg phy_cal_fail;
	reg [AFI_DEBUG_INFO_WIDTH - 1:0] phy_cal_debug_info;
	reg [MEM_READ_DQS_WIDTH - 1:0] phy_read_fifo_reset;
	reg [MEM_READ_DQS_WIDTH - 1:0] phy_vfifo_rd_en_override;
	reg phy_done;
	
	localparam RFILE_ADDR_WIDTH = 3;

	typedef enum int unsigned {
		STATE_AVL_IDLE,
		STATE_AVL_EXEC,
		STATE_AVL_DONE
	} STATE_AVL_T;

	STATE_AVL_T state_avl_curr;

	typedef enum int unsigned {
		STATE_PHY_IDLE,
		STATE_PHY_DONE
	} STATE_PHY_T;

	STATE_PHY_T state_phy_curr;

	//USER the register file
	
	reg [AVL_DATA_WIDTH - 1:0] rfile [0:7];
	
	//USER register file selected
	
	wire sel_rfile, sel_rfile_wr, sel_rfile_rd;
	
	//USER command issue selected
	
	wire sel_any;
	wire sel_issue, sel_issue_wr, sel_issue_rd;
	
	assign sel_rfile = avl_address[AVL_ADDR_WIDTH - 1];
		//~avl_address[AVL_ADDR_WIDTH - 1] &
		//~avl_address[AVL_ADDR_WIDTH - 2] &
		//avl_address[AVL_ADDR_WIDTH - 3] &
		//avl_address[AVL_ADDR_WIDTH - 4];
	assign sel_rfile_wr = sel_rfile & avl_write;
	assign sel_rfile_rd = sel_rfile & avl_read;
	
	assign sel_issue = ~avl_address[AVL_ADDR_WIDTH - 1];
		//~avl_address[AVL_ADDR_WIDTH - 1] &
		//~avl_address[AVL_ADDR_WIDTH - 2] &
		//avl_address[AVL_ADDR_WIDTH - 3] &
		//~avl_address[AVL_ADDR_WIDTH - 4];
	assign sel_issue_wr = sel_issue & avl_write;
	assign sel_issue_rd = sel_issue & avl_read;
	
	assign sel_any = sel_rfile_wr | sel_rfile_rd | sel_issue_wr | sel_issue_rd;
	
	//USER State machine, AVALON side
		
	always_ff @ (posedge avl_clk or negedge avl_reset_n) begin
		if (avl_reset_n == 0) begin
			state_avl_curr <= STATE_AVL_IDLE;

			avl_readdata_r <= '0;
			avl_rfile_wr <= 0;
			avl_issue_wr <= 0;
			avl_read_increment_vfifo_fr <= '0;
			avl_read_increment_vfifo_hr <= '0;
			avl_read_increment_vfifo_qr <= '0;
			avl_read_fifo_reset <= 0;

			rfile[0][MAX_LATENCY_COUNT_WIDTH - 1:0] <= '0;
			rfile[1][0] <= 0;
			rfile[2][0] <= 1;
			rfile[3][1:0] <= '0;
			rfile[4][0] <= '0;
			rfile[5][0] <= 0;
			rfile[6][0] <= 0;
			rfile[7][0] <= 0;
		end else begin
			case (state_avl_curr)
			STATE_AVL_IDLE: begin
				if (sel_rfile_rd) begin
					//USER NIOS is reading from the register file
					
					state_avl_curr <= STATE_AVL_DONE;
					
					avl_readdata_r <= '0 /*rfile[avl_address[RFILE_ADDR_WIDTH - 1:0]] */; //USER removing address file access for further optimization.
				end else if (sel_issue_rd) begin
					//USER NIOS is reading parameters

					state_avl_curr <= STATE_AVL_DONE;
					
					case (avl_address[3:0])
					4'b0000: avl_readdata_r <= MAX_LATENCY_COUNT_WIDTH;
					4'b0001: avl_readdata_r <= AFI_MAX_WRITE_LATENCY_COUNT_WIDTH;
					4'b0010: avl_readdata_r <= AFI_MAX_READ_LATENCY_COUNT_WIDTH;
					// with simgen and post-fit sim, we synthesizing but for purposes of simulation, so no translate_off
					`ifndef SYNTH_FOR_SIM
					//synthesis translate_off
					`endif
					//USER extra bit indicates we are in the simulator
					4'b0011: avl_readdata_r <= {{(AVL_DATA_WIDTH-CALIB_SKIP_STEPS_WIDTH-1){1'b0}},1'b1,calib_skip_steps};
					`ifndef SYNTH_FOR_SIM
					//synthesis translate_on
					`endif
					`ifndef SYNTH_FOR_SIM
					//synthesis read_comments_as_HDL on
					`endif
					// 4'b0011: avl_readdata_r <= {{(AVL_DATA_WIDTH-CALIB_SKIP_STEPS_WIDTH){1'b0}},calib_skip_steps};
					`ifndef SYNTH_FOR_SIM
					// synthesis read_comments_as_HDL off
					`endif
					//FIXME: comments stripping for the sequencer is turned off.  use the following line when it's re-enabled.
					//USER 4'b0011: avl_readdata_r <= {{(AVL_DATA_WIDTH-CALIB_SKIP_STEPS_WIDTH){1'b0}},calib_skip_steps};
					4'b0100: avl_readdata_r <= CALIB_VFIFO_OFFSET;
					4'b0101: avl_readdata_r <= CALIB_LFIFO_OFFSET;
					4'b0110:
						if (CTL_REGDIMM_ENABLED == 1)
							avl_readdata_r <= 1;
						else
							avl_readdata_r <= 0;
					4'b0111: avl_readdata_r <= MEM_T_WL;
					4'b1000: avl_readdata_r <= MEM_T_RL;
					4'b1001: avl_readdata_r <= READ_VALID_FIFO_SIZE;
					endcase
				end else if (sel_rfile_wr) begin
					//USER NIOS is writing into the register file.
					//USER Need to issue a command the PHY side to pick up changes.

					state_avl_curr <= STATE_AVL_EXEC;

					avl_rfile_wr <= 1;
					
					rfile[avl_address[RFILE_ADDR_WIDTH - 1:0]] <= avl_writedata;
				end else if (sel_issue_wr) begin
					//USER NIOS is asking for a particular command to be issued
					
					state_avl_curr <= STATE_AVL_EXEC;
					
					avl_issue_wr <= 1;
					
					case (avl_address[2:0])
					3'b000:
						if (avl_writedata == 8'b11111111) begin
							avl_read_increment_vfifo_fr <= {MEM_READ_DQS_WIDTH{1'b1}};
						end else begin
							avl_read_increment_vfifo_fr[avl_writedata] <= 1;
						end
					3'b001:
						if (avl_writedata == 8'b11111111) begin
							avl_read_increment_vfifo_hr <= {MEM_READ_DQS_WIDTH{1'b1}};
						end else begin
							avl_read_increment_vfifo_hr[avl_writedata] <= 1;
						end
					3'b010:
						avl_read_fifo_reset <= 1;
					3'b011:
						if (avl_writedata == 8'b11111111) begin
							avl_read_increment_vfifo_fr <= {MEM_READ_DQS_WIDTH{1'b1}};
							avl_read_increment_vfifo_hr <= {MEM_READ_DQS_WIDTH{1'b1}};
						end else begin
							avl_read_increment_vfifo_fr[avl_writedata] <= 1;
							avl_read_increment_vfifo_hr[avl_writedata] <= 1;
						end
					3'b100:
						if (avl_writedata == 8'b11111111) begin
							avl_read_increment_vfifo_qr <= {MEM_READ_DQS_WIDTH{1'b1}};
						end else begin
							avl_read_increment_vfifo_qr[avl_writedata] <= 1;
						end
					endcase
				end
			end
			STATE_AVL_EXEC: begin
				//USER We are currently executing a command on the PHY side.
				//USER Wait until it is done.
				
				if (phy_done) begin
					state_avl_curr <= STATE_AVL_DONE;
					
					//USER Need to bring all the command lines down to prevent
					//USER the PHY from reexecuting the same command.
					
					avl_rfile_wr <= 0;
					avl_issue_wr <= 0;
					avl_read_increment_vfifo_fr <= '0;
					avl_read_increment_vfifo_hr <= '0;
					avl_read_increment_vfifo_qr <= '0;
					avl_read_fifo_reset <= 0;
				end
			end
			STATE_AVL_DONE: begin
				//USER Done operation. During this clock waitrequest is de-asserted.
				//USER Return to idle state next clock.
				
				state_avl_curr <= STATE_AVL_IDLE;
			end
			endcase
		end
	end

	//USER State machine, PHY side
		
	always_ff @ (posedge phy_clk or negedge phy_reset_n) begin
		if (phy_reset_n == 0) begin
			state_phy_curr <= STATE_PHY_IDLE;

			phy_done <= 0;
			phy_read_increment_vfifo_fr <= '0;
			phy_read_increment_vfifo_hr <= '0;
			phy_read_increment_vfifo_qr <= '0;
			phy_read_fifo_reset <= '0;
			phy_reset_mem_stable <= 0;
			phy_mux_sel <= 1;
			phy_cal_success <= 0;
			phy_cal_fail <= 0;
			phy_cal_debug_info <= '0;
			phy_vfifo_rd_en_override <= '0;
		end else begin
			case (state_phy_curr)
			STATE_PHY_IDLE: begin
				//USER Waiting for a command to arrive.
				
				if (avl_rfile_wr) begin
					//USER Register file was just changed on the AVL side. Pick
					//USER up changes.
					
					state_phy_curr <= STATE_PHY_DONE;
					
					phy_done <= 1;
					
					phy_read_latency_counter <= rfile[0][MAX_LATENCY_COUNT_WIDTH - 1:0];
					phy_reset_mem_stable <= rfile[1][0];
					phy_mux_sel <= rfile[2][0];
					phy_cal_success <= rfile[3][0];
					phy_cal_fail <= rfile[3][1];
					phy_cal_debug_info <= rfile[4][AFI_DEBUG_INFO_WIDTH - 1:0];
					phy_vfifo_rd_en_override <= {(MEM_READ_DQS_WIDTH){rfile[5][0]}};
					phy_afi_wlat <= rfile[6][AFI_MAX_WRITE_LATENCY_COUNT_WIDTH - 1:0];
					phy_afi_rlat <= rfile[7][AFI_MAX_READ_LATENCY_COUNT_WIDTH - 1:0];
				end else if (avl_issue_wr) begin
					//USER NIOS just issued a command to be run.
					
					state_phy_curr <= STATE_PHY_DONE;
					
					phy_done <= 1;
					
					phy_read_increment_vfifo_fr <= avl_read_increment_vfifo_fr;
					phy_read_increment_vfifo_hr <= avl_read_increment_vfifo_hr;
					phy_read_increment_vfifo_qr <= avl_read_increment_vfifo_qr;
					phy_read_fifo_reset <= {(MEM_READ_DQS_WIDTH){avl_read_fifo_reset}};
				end
			end
			STATE_PHY_DONE: begin
				phy_read_increment_vfifo_fr <= '0;
				phy_read_increment_vfifo_hr <= '0;
				phy_read_increment_vfifo_qr <= '0;
				phy_read_fifo_reset <= '0;

				if (~avl_rfile_wr && ~avl_issue_wr) begin
					state_phy_curr <= STATE_PHY_IDLE;
					phy_done <= 0;
				end
			end
			endcase
		end
	end

	//USER wait request management and read data gating
	
	always_comb
	begin
		if (sel_any && state_avl_curr != STATE_AVL_DONE || ~avl_reset_n)
			avl_waitrequest <= 1;
		else 
			avl_waitrequest <= 0;

		if (sel_rfile_rd || sel_issue_rd)
			avl_readdata <= avl_readdata_r;
		else 
			avl_readdata <= '0;
	end
	
endmodule
