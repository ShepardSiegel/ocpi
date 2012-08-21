// opedTop.v - Top Level Verilog wrapper for NETFPGA10G "OPED" component
// Copyright (c) 2010 Atomic Rules LLC, ALL RIGHTS RESERVED
// 2010-10-31 ssiegel Creation with WCI::AXI only
// 2010-11-02 ssiegel Made debug a 32b vector
// 2010-11-22 ssiegel Minor noodling

module opedTop(
 
  // Outward-Facing Direct Connection to PCIe pads...
  input  wire         pcie_clk_p,      // PCIe Clock +
  input  wire         pcie_clk_n,      // PCIe Clock -
  input  wire         pcie_reset_n,    // PCIe Reset (active low)
  output wire   [7:0] pcie_txp,        // PCIe lanes...
  output wire   [7:0] pcie_txn,
  input  wire   [7:0] pcie_rxp,
  input  wire   [7:0] pcie_rxn,

  output wire  [31:0] debug      // Debug Port Bitfields...
  // debug[31:3] reserved        // For future use, will read as '0'
  // debug[2]    oped_egress     // True when TL data is making egress to PCIe from OPED
  // debug[1]    oped_ingress    // True when TL data is making ingress from PCIe to OPED
  // debug[0]    oped_linkp      // True when the PCIe link-layer is established with OPED

  //TODO: AXI ports to be added...

  /*

  // Inward-Facing OPED signals, clock, resets for AXI ports...
  output wire         oped_clk125,     // OPED Clock Output (nominaly 125 MHz)
  output wire         oped_reset,      // OPED Reset (active high)

  // WCI::AXI AXI4-Lite Master WCIM0...
  output wire         wcim0_awvalid,   // (AW) Write Address Channel...
  input  wire         wcim0_awready,
  output wire  [31:0] wcim0_awaddr, 
  output wire  [ 2:0] wcim0_awprot, 
  output wire         wcim0_wvalid,    // (W) Write Data Channel...
  input  wire         wcim0_wready,
  output wire  [31:0] wcim0_wdata,
  output wire  [ 3:0] wcim0_wstrb, 
  input  wire         wcim0_bvalid,    // (B) Write Response Channel...
  output wire         wcim0_bready,
  output wire  [ 1:0] wcim0_bresp, 
  output wire         wcim0_arvalid,   // (AR) Read Address Channel...
  input  wire         wcim0_arready,
  output wire  [31:0] wcim0_araddr, 
  output wire  [ 2:0] wcim0_arprot, 
  input  wire         wcim0_rvalid,    // (R) Read Response Channel..
  output wire         wcim0_rready,
  output wire  [31:0] wcim0_rdata, 
  output wire  [ 1:0] wcim0_rresp, 
 
  // WSI::AXI AXI4-Stream Master 0 WSI-M0...  
  output wire         wsim0_tvalid,    // (T) Stream Channel...
  input  wire         wsim0_tready,  
  output wire [255:0] wsim0_tdata,     // 32B (256b) Message Data
  output wire [ 31:0] wsim0_tstrb,
  output wire         wsim0_tlast,

  // WSI::AXI AXI4-Stream Master Info Channel 0 WSI-M0ic...
  output wire         wsim0ic_tvalid,  // (T) Stream Channel...
  input  wire         wsim0ic_tready,  
  output wire [ 15:0] wsim0ic_tdata,   // 4B (16b) Stream Info Channel
  output wire [  3:0] wsim0ic_tstrb,
  output wire         wsim0ic_tlast,

  // WSI::AXI AXI4-Stream Slave 1 WSI-S0...
  input  wire         wsis0_tvalid,    // (T) Stream Channel...
  output wire         wsis0_tready,  
  input  wire [255:0] wsis0_tdata,     // 32B (256b) Message Data
  input  wire [ 31:0] wsis0_tstrb,
  input  wire         wsis0_tlast,

  // WSI::AXI AXI4-Stream Slave Info Channel 1 WSI-S0ic...
  input  wire         wsis0ic_tvalid,  // (T) Stream Channel...
  output wire         wsis0ic_tready,  
  input  wire [ 15:0] wsis0ic_tdata,   // 4B (16b) Stream Info Channel
  input  wire [  3:0] wsis0ic_tstrb,
  input  wire         wsis0ic_tlast
  */
);

 // The implementation of module opedTop follows. This may be made opaque,
 // black-boxed, etc, and should be of no concern to the average NETFPGA-10G user.
 // The purpose is to provide some ligweight "impedence-matching" between the
 // BSV compiler-generated mkOPED implementation. 
 //
 // Core Team: Shep owns this interface contract from this point down...

  wire unused_1;

  // Instance and connect mkOPED...
  mkOPED moped(
	  .pcie_clk_p      (pcie_clk_p),
	  .pcie_clk_n      (pcie_clk_n),
	  .pcie_reset_n    (pcie_reset_n),
	  .pcie_rxp_i      (pcie_rxp),
	  .pcie_rxn_i      (pcie_rxn),
	  .pcie_txp        (pcie_txp),
	  .pcie_txn        (pcie_txn),
	  .debug           (debug),
	  .trnClk          (oped_clk125),
	  .CLK_GATE_trnClk (unused_1)
);

endmodule
