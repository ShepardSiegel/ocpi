// rom_proto.v - Prototype of a Verilog DWORD ROM
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

module rom_proto(
  input  wire        clk, 
  input  wire        rstn,

	input  wire [8:0]  addr,
	output wire [31:0] data,

	input  wire        addr_valid,
  output wire        data_ready

);

endmodule
