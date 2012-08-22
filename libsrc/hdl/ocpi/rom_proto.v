// rom_proto.v - Prototype of a Verilog DWORD ROM
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

module rom_proto(
  input  wire        clk, 
  input  wire        rstn,
	input  wir  [8:0]  addr,
	output reg  [31:0] data

  reg [31:0] rom [511:0];

  inital begin
    $readmemh("ramprom.data", rom, 0, 511);
  end

  always @(posedge clk) begin
    data <= rom[addr];
  end

);

endmodule
