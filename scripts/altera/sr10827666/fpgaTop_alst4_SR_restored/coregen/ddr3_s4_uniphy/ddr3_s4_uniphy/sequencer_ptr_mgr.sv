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
//USER ptr_mgr
//USER ******
//USER
//USER PTR Manager
//USER
//USER General Description
//USER -------------------
//USER
//USER This component allows a way for JTAG debug master to figure out where
//USER data transfer arrays are placed in memory. NIOS code will place the
//USER pointer to the array in a register, and the JTAG debug master picks it
//USER up from there.
//USER

module sequencer_ptr_mgr (
	//USER Avalon Interface
	
	avl_clk,
	avl_reset_n,
	avl_address,
	avl_write,
	avl_writedata,
	avl_read,
	avl_readdata,
	avl_waitrequest
);

	parameter AVL_DATA_WIDTH = 32;
	parameter AVL_ADDR_WIDTH = 13;

	input avl_clk;
	input avl_reset_n;
	input [AVL_ADDR_WIDTH - 1:0] avl_address;
	input avl_write;
	input [AVL_DATA_WIDTH - 1:0] avl_writedata;
	input avl_read;
	output [AVL_DATA_WIDTH - 1:0] avl_readdata;
	output avl_waitrequest;
	
	reg [AVL_DATA_WIDTH - 1:0] avl_readdata;
	reg avl_waitrequest;
	
	reg [AVL_DATA_WIDTH - 1:0] rfile_tcl_rx_io;
	reg [AVL_DATA_WIDTH - 1:0] rfile_tcl_tx_io;
	reg [AVL_DATA_WIDTH - 1:0] rfile_info_step;
	reg [AVL_DATA_WIDTH - 1:0] rfile_info_group;
	reg [AVL_DATA_WIDTH - 1:0] rfile_info_extra;
	reg [AVL_DATA_WIDTH - 1:0] rfile_info_dtaps_per_ptap;

	//USER register selected
	
	wire sel_rfile, sel_rfile_wr, sel_rfile_rd;
	
	assign sel_rfile = 1'b1;
		//~avl_address[AVL_ADDR_WIDTH - 1] &
		//~avl_address[AVL_ADDR_WIDTH - 2] &
		//~avl_address[AVL_ADDR_WIDTH - 3];
	assign sel_rfile_wr = sel_rfile & avl_write;
	assign sel_rfile_rd = sel_rfile & avl_read;

	always_ff @ (posedge avl_clk) begin
		if (sel_rfile_wr) begin
			case (avl_address[2:0])
			3'b000: rfile_tcl_rx_io <= avl_writedata;
			3'b001: rfile_info_step <= avl_writedata;
			3'b010: rfile_info_group <= avl_writedata;
			3'b011: rfile_info_extra <= avl_writedata;
			3'b100: rfile_tcl_tx_io <= avl_writedata;
			3'b101: rfile_info_dtaps_per_ptap <= avl_writedata;
			endcase
		end
	end

	//USER wait request management and read data gating
	
	always_comb
	begin
		avl_waitrequest <= 0;
		
		if (sel_rfile_rd) 
			case (avl_address[2:0])
			3'b000: avl_readdata <= rfile_tcl_rx_io;
			3'b001: avl_readdata <= rfile_info_step;
			3'b010: avl_readdata <= rfile_info_group;
			3'b100: avl_readdata <= rfile_tcl_tx_io;
			3'b101: avl_readdata <= rfile_info_dtaps_per_ptap;
			default: avl_readdata <= rfile_info_extra;
			endcase
		else 
			avl_readdata <= '0;
	end
	
endmodule
