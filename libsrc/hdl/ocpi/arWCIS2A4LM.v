// arWCIS2A4LM.v - Bridge module from WCI-Slave to AXI4-Lite Master
// Copyright (c) 2010 Atomic Rules LLC, ALL RIGHTS RESERVED
//
// 2010-09-12 Module declaration in Verilog
// 2010-09-14 20b, 1MB Address Window on both sides of bridge

module arWCI2A4LM (
  input          bridge_Clk,
	input          bridge_Reset_n,

  input  [2:0]   wciS0_MCmd,            // WCI Slave...
  input  [0:0]   wciS0_MAddrSpace,      // MAddrSpace[0]: 0=Control ; 1=Configuration
  input  [3:0]   wciS0_MByteEn,
  input  [19:0]  wciS0_MAddr,           // 20b 1MB Address Space
  input  [31:0]  wciS0_MData,
  output [1:0]   wciS0_SResp,
  output [31:0]  wciS0_SData,
  input  [0:0]   wciS0_SThreadBusy,
  input  [0:0]   wciS0_SFlag,
  output [0:0]   wciS0_MFlag,

  output         axiM0_AWVALID,         // AXI4-Lite Write-Address channel...
  input          axiM0_AWREADY,
  output [31:0]  axiM0_AWADDR,
  output [2:0]   axiM0_AWPROT,
  output         axiM0_WVALID,          // AXI4-Lite Write-Data channel...
  input          axiM0_WREADY,
  output [31:0]  axiM0_WDATA,
  output [3:0]   axiM0_WSTRB,
  input          axiM0_BVALID,          // AXI4-Lite Write-Response channel...
  output         axiM0_BREADY,
  input  [1:0]   axiM0_BRESP
  output         axiM0_ARVALID,         // AXI4-Lite Read-Address channel...
  input          axiM0_ARREADY,
  output [19:0]  axiM0_ARADDR,          // 20b 1MB Address Space
  output [2:0]   axiM0_ARPROT,          // ARPROT[2]: 0=Data/Configuration ; 1=Instruction/Control
  input          axiM0_RVALID,          // AXI4-Lite Read-Data channel...
  output         axiM0_RREADY,
  input  [19:0]  axiM0_RDATA,           // 20b 1MB Address Space
  input  [3:0]   axiM0_RRESP
);
endmodule

