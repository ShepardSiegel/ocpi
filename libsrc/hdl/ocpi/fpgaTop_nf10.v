// fpgaTop_nf10.v - A proxy fpga top-level to hold OPED.v
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// The purpose of this module is to "stand in" for the real NetFPGA-10G as
// OPED is developed. This file would not normally be needed for any normal 
// NETFPGA-10G build. It is useful for standalone OPED testing and building.

// This level is the top level of the nf10 FPGA, this is a stand-in for the real NETFPGA-10G top...

module fpgaTop (
  input  wire        pcie_clkp,      // PCIe Clock +
  input  wire        pcie_clkn,      // PCIe Clock -
  input  wire        pcie_rstn,      // PCIe Reset
  input  wire [7:0]  pcie_rxp,       // PCIe lanes...
  input  wire [7:0]  pcie_rxn,
  output wire [7:0]  pcie_txp,
  output wire [7:0]  pcie_txn,
  output reg         debug_parity    // To prevent debug from being optimized away
);

// Wire declarations...
wire         ACLK;  
wire         ARESETN; 
wire [31:0]  M_AXI_AWADDR;
wire [2:0]   M_AXI_AWPROT;
wire         M_AXI_AWVALID;
wire         M_AXI_AWREADY;
wire [31:0]  M_AXI_WDATA;
wire [3:0]   M_AXI_WSTRB;
wire         M_AXI_WVALID;
wire         M_AXI_WREADY;
wire [1:0]   M_AXI_BRESP;
wire         M_AXI_BVALID;
wire         M_AXI_BREADY;
wire [31:0]  M_AXI_ARADDR;
wire [2:0]   M_AXI_ARPROT;
wire         M_AXI_ARVALID;
wire         M_AXI_ARREADY;
wire [31:0]  M_AXI_RDATA;
wire [1:0]   M_AXI_RRESP;
wire         M_AXI_RVALID;
wire         M_AXI_RREADY;
wire [255:0] M_AXIS_DAT_TDATA;
wire         M_AXIS_DAT_TVALID;
wire [31:0]  M_AXIS_DAT_TSTRB;
wire         M_AXIS_DAT_TLAST;
wire         M_AXIS_DAT_TREADY;
wire [15:0]  M_AXIS_LEN_TDATA;
wire [7:0]   M_AXIS_SPT_TDATA;
wire [7:0]   M_AXIS_DPT_TDATA;
wire         M_AXIS_ERR_TDATA;
wire [255:0] S_AXIS_DAT_TDATA;
wire         S_AXIS_DAT_TVALID;
wire [31:0]  S_AXIS_DAT_TSTRB;
wire         S_AXIS_DAT_TLAST;
wire         S_AXIS_DAT_TREADY;
wire [15:0]  S_AXIS_LEN_TDATA;
wire [7:0]   S_AXIS_SPT_TDATA;
wire [7:0]   S_AXIS_DPT_TDATA;
wire         S_AXIS_ERR_TDATA;

wire [31:0]  debug_oped;       // The 32b vector of debug signals from OPED
always@(posedge ACLK) begin
  debug_parity <= ^debug_oped; // XOR reduce the debug bits onto debug_parity
end

// Instance and connect the OPED component just as it will be instanced in nf10...
 OPED oped (
  .PCIE_CLKP         (pcie_clkp),
  .PCIE_CLKN         (pcie_clkn),
  .PCIE_RSTN         (pcie_rstn),
  .PCIE_RXP          (pcie_rxp),
  .PCIE_RXN          (pcie_rxn),
  .PCIE_TXP          (pcie_txp),
  .PCIE_TXN          (pcie_txn),
  .ACLK              (ACLK),
  .ARESETN           (ARESETN),
  .M_AXI_AWADDR      (M_AXI_AWADDR),
  .M_AXI_AWPROT      (M_AXI_AWPROT),
  .M_AXI_AWVALID     (M_AXI_AWVALID),
  .M_AXI_AWREADY     (M_AXI_AWREADY),
  .M_AXI_WDATA       (M_AXI_WDATA),
  .M_AXI_WSTRB       (M_AXI_WSTRB),
  .M_AXI_WVALID      (M_AXI_WVALID),
  .M_AXI_WREADY      (M_AXI_WREADY),
  .M_AXI_BRESP       (M_AXI_BRESP),
  .M_AXI_BVALID      (M_AXI_BVALID),
  .M_AXI_BREADY      (M_AXI_BREADY),
  .M_AXI_ARADDR      (M_AXI_ARADDR),
  .M_AXI_ARPROT      (M_AXI_ARPROT),
  .M_AXI_ARVALID     (M_AXI_ARVALID),
  .M_AXI_ARREADY     (M_AXI_ARREADY),
  .M_AXI_RDATA       (M_AXI_RDATA),
  .M_AXI_RRESP       (M_AXI_RRESP),
  .M_AXI_RVALID      (M_AXI_RVALID),
  .M_AXI_RREADY      (M_AXI_RREADY),
  .M_AXIS_DAT_TDATA  (M_AXIS_DAT_TDATA),
  .M_AXIS_DAT_TVALID (M_AXIS_DAT_TVALID),
  .M_AXIS_DAT_TSTRB  (M_AXIS_DAT_TSTRB),
  .M_AXIS_DAT_TLAST  (M_AXIS_DAT_TLAST),
  .M_AXIS_DAT_TREADY (M_AXIS_DAT_TREADY),
  .M_AXIS_LEN_TDATA  (M_AXIS_LEN_TDATA),
  .M_AXIS_SPT_TDATA  (M_AXIS_SPT_TDATA),
  .M_AXIS_DPT_TDATA  (M_AXIS_DPT_TDATA),
  .M_AXIS_ERR_TDATA  (M_AXIS_ERR_TDATA),
  .S_AXIS_DAT_TDATA  (S_AXIS_DAT_TDATA),
  .S_AXIS_DAT_TVALID (S_AXIS_DAT_TVALID),
  .S_AXIS_DAT_TSTRB  (S_AXIS_DAT_TSTRB),
  .S_AXIS_DAT_TLAST  (S_AXIS_DAT_TLAST),
  .S_AXIS_DAT_TREADY (S_AXIS_DAT_TREADY),
  .S_AXIS_LEN_TDATA  (S_AXIS_LEN_TDATA),
  .S_AXIS_SPT_TDATA  (S_AXIS_SPT_TDATA),
  .S_AXIS_DPT_TDATA  (S_AXIS_DPT_TDATA),
  .S_AXIS_ERR_TDATA  (S_AXIS_ERR_TDATA),
  .DEBUG             (debug_oped)
);


// Instance and connect a simple AXI4-Lite Slave Device...
// TODO: This module will be replaced with the nf10 "control plane"
 mkA4LS axiSlave (
  .ACLK        (ACLK),
  .ARESETN     (ARESETN),
  .AWADDR      (M_AXI_AWADDR),
  .AWPROT      (M_AXI_AWPROT),
  .AWVALID     (M_AXI_AWVALID),
  .AWREADY     (M_AXI_AWREADY),
  .WDATA       (M_AXI_WDATA),
  .WSTRB       (M_AXI_WSTRB),
  .WVALID      (M_AXI_WVALID),
  .WREADY      (M_AXI_WREADY),
  .BRESP       (M_AXI_BRESP),
  .BVALID      (M_AXI_BVALID),
  .BREADY      (M_AXI_BREADY),
  .ARADDR      (M_AXI_ARADDR),
  .ARPROT      (M_AXI_ARPROT),
  .ARVALID     (M_AXI_ARVALID),
  .ARREADY     (M_AXI_ARREADY),
  .RDATA       (M_AXI_RDATA),
  .RRESP       (M_AXI_RRESP),
  .RVALID      (M_AXI_RVALID),
  .RREADY      (M_AXI_RREADY)
);

/*

// Instance and connect a loopback core from the ingress to the egress...
// TODO: This module will be replaced with the nf10 "data plane"
 AXILOOPBACK axiLoopback (
  .ACLK              (ACLK),
  .ARESETN           (ARESETN),
  .S_AXIS_DAT_TDATA  (M_AXIS_DAT_TDATA),
  .S_AXIS_DAT_TVALID (M_AXIS_DAT_TVALID),
  .S_AXIS_DAT_TSTRB  (M_AXIS_DAT_TSTRB),
  .S_AXIS_DAT_TLAST  (M_AXIS_DAT_TLAST),
  .S_AXIS_DAT_TREADY (M_AXIS_DAT_TREADY),
  .S_AXIS_LEN_TDATA  (M_AXIS_LEN_TDATA),
  .S_AXIS_SPT_TDATA  (M_AXIS_SPT_TDATA),
  .S_AXIS_DPT_TDATA  (M_AXIS_DPT_TDATA),
  .S_AXIS_ERR_TDATA  (M_AXIS_ERR_TDATA),
  .M_AXIS_DAT_TDATA  (S_AXIS_DAT_TDATA),
  .M_AXIS_DAT_TVALID (S_AXIS_DAT_TVALID),
  .M_AXIS_DAT_TSTRB  (S_AXIS_DAT_TSTRB),
  .M_AXIS_DAT_TLAST  (S_AXIS_DAT_TLAST),
  .M_AXIS_DAT_TREADY (S_AXIS_DAT_TREADY),
  .M_AXIS_LEN_TDATA  (S_AXIS_LEN_TDATA),
  .M_AXIS_SPT_TDATA  (S_AXIS_SPT_TDATA),
  .M_AXIS_DPT_TDATA  (S_AXIS_DPT_TDATA),
  .M_AXIS_ERR_TDATA  (S_AXIS_ERR_TDATA)
);

*/

endmodule
