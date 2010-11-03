// fpgaTop_net10.v - A proxy fpga top-level to hold opedTop.v
// Copyright (c) 2010 Atomic Rules LLC, ALL RIGHTS RESERVED
// 2010-11-02 ssiegel Creation
//
// The purpose of this module is to "stand in" for the real NetFPGA-10G as
// OPED is developed under OpenCPI. This file would not normally be needed for
// any NETFPGA-10G build. It is useful for standalone OPED testing and building.

// This level is the top level of the FPGA, this is a stand-in for the real NETFPGA-10G top...
module fpgaTop(
  input  wire        pcie_clk_p,     // PCIe Clock +
  input  wire        pcie_clk_n,     // PCIe Clock -
  input  wire        pcie_reset_n,   // PCIe Reset
  output wire [7:0]  pcie_txp,       // PCIe lanes...
  output wire [7:0]  pcie_txn,
  input  wire [7:0]  pcie_rxp,
  input  wire [7:0]  pcie_rxn
);

 wire [31:0] debug_oped; // The 32b vector of debug signals from the opedTop module

// Instance and connect the OPED component just as it will be intanced in NETFPGA-10G...
 opedTop oped(
  .pcie_clk_p        (pcie_clk_p),
  .pcie_clk_n        (pcie_clk_n),
  .pcie_reset_n      (pcie_reset_n),
  .pcie_txp          (pcie_txp),
  .pcie_txn          (pcie_txn),
  .pcie_rxp          (pcie_rxp),
  .pcie_rxn          (pcie_rxn),
  .debug             (debug_oped)
  // TODO: AXI ports to be added...
);

endmodule
