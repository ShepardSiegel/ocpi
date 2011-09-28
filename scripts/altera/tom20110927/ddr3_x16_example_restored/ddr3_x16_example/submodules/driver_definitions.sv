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


//USER////////////////////////////////////////////////////////////////////////////
//USER This package contains common typedefs and function definitions for the
//USER example driver.
//USER////////////////////////////////////////////////////////////////////////////

package driver_definitions;


//USER Address generators definition
typedef enum int unsigned {
	SEQ,
	RAND,
	RAND_SEQ,
	TEMPLATE_ADDR_GEN
} addr_gen_select_t;


//USER Returns the maximum of two numbers
function automatic integer max;
	input integer a;
	input integer b;
	begin
		max = (a > b) ? a : b;
	end
endfunction


//USER Calculate the log_2 of the input value
function automatic integer log2;
	input integer value;
	begin
		value = value >> 1;
		for (log2 = 0; value > 0; log2 = log2 + 1)
			value = value >> 1;
	end
endfunction


//USER Calculate the ceiling of log_2 of the input value
function automatic integer ceil_log2;
	input integer value;
	begin
		value = value - 1;
		for (ceil_log2 = 0; value > 0; ceil_log2 = ceil_log2 + 1)
			value = value >> 1;
	end
endfunction


endpackage

