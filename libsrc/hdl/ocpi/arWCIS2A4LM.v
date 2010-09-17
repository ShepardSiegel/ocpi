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
  output [0:0]   wciS0_SThreadBusy,
  output [0:0]   wciS0_SFlag,
  input  [0:0]   wciS0_MFlag,

  output         axiM0_AWVALID,         // AXI4-Lite Write-Address channel...
  input          axiM0_AWREADY,
  output [19:0]  axiM0_AWADDR,          // 20b 1MB Address Space
  output [2:0]   axiM0_AWPROT,
  output         axiM0_WVALID,          // AXI4-Lite Write-Data channel...
  input          axiM0_WREADY,
  output [31:0]  axiM0_WDATA,
  output [3:0]   axiM0_WSTRB,
  input          axiM0_BVALID,          // AXI4-Lite Write-Response channel...
  output         axiM0_BREADY,
  input  [1:0]   axiM0_BRESP,
  output         axiM0_ARVALID,         // AXI4-Lite Read-Address channel...
  input          axiM0_ARREADY,
  output [19:0]  axiM0_ARADDR,          // 20b 1MB Address Space
  output [2:0]   axiM0_ARPROT,          // ARPROT[2]: 0=Data/Configuration ; 1=Instruction/Control
  input          axiM0_RVALID,          // AXI4-Lite Read-Data channel...
  output         axiM0_RREADY,
  input  [31:0]  axiM0_RDATA, 
  input  [1:0]   axiM0_RRESP
);

wire[22:0] axiM0_wrAddr_data =       {axiM0_AWPROT, axiM0_AWADDR};
wire[35:0] axiM0_wrData_data =       {axiM0_WSTRB,  axiM0_WDATA};
wire[1:0]  axiM0_wrResp_data_value = {axiM0_BRESP};
wire[22:0] axiM0_rdAddr_data =       {axiM0_ARPROT, axiM0_ARADDR};
wire[33:0] axiM0_rdResp_data_value = {axiM0_RRESP,  axiM0_RDATA};

// Instance the BSV module...
mkWCI2A4LM bridge(
  .wciS0_Clk                 (bridge_Clk),
  .wciS0_MReset_n            (bridge_Reset_n),

  .wciS0_MCmd                (wciS0_MCmd),
  .wciS0_MAddrSpace          (wciS0_AddrSpace),
  .wciS0_MByteEn             (wciS0_MByteEn),
  .wciS0_MAddr               (wciS0_MAddr),
  .wciS0_MData               (wciS0_MData),
  .wciS0_SResp               (wciS0_SResp),
  .wciS0_SData               (wciS0_SData),
  .wciS0_SThreadBusy         (wciS0_SThreadBusy),
  .wciS0_SFlag               (wciS0_SFlag),
  .wciS0_MFlag               (wciS0_MFlag),

  .axiM0_wrAddr_data         (axiM0_wrAddr_data),
  .axiM0_wrAddr_valid        (axiM0_AWVALID),
  .axiM0_wrAddr_ready_value  (axiM0_AWREADY),
  .axiM0_wrData_data         (axiM0_wrData_data),
  .axiM0_wrData_valid        (axiM0_WVALID),
  .axiM0_wrData_ready_value  (axiM0_WREADY),
  .axiM0_wrResp_data_value   (axiM0_wrResp_data_value),
  .axiM0_wrResp_valid_value  (axiM0_BVALID),
  .axiM0_wrResp_ready        (axiM0_BREADY),
  .axiM0_rdAddr_data         (axiM0_rdAddr_data),
  .axiM0_rdAddr_valid        (axiM0_ARVALID),
  .axiM0_rdAddr_ready_value  (axiM0_ARREADY),
  .axiM0_rdResp_data_value   (axiM0_rdResp_data_value),
  .axiM0_rdResp_valid_value  (axiM0_RVALID),
  .axiM0_rdResp_ready        (axiM0_RREADY)
);
endmodule

