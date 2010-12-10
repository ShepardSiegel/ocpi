// fpgaTop_nf10.v - A proxy fpga top-level to hold OPED.v
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// The purpose of this module is to "stand in" for the real NetFPGA-10G as
// OPED is developed. This file would not normally be needed for any normal 
// NETFPGA-10G build. It is useful for standalone OPED testing and building.

// This level is the top level of the nf10 FPGA, this is a stand-in for the real NETFPGA-10G top...

module fpgaTop (
  input  wire        pcie_clk_p,     // PCIe Clock +
  input  wire        pcie_clk_n,     // PCIe Clock -
  input  wire        pcie_reset_n,   // PCIe Reset
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
  .PCIE_CLK_P        (pcie_clk_p),
  .PCIE_CLK_N        (pcie_clk_n),
  .PCIE_RESET_N      (pcie_reset_n),
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
 AXISLAVE axiSlave (
  .ACLK              (ACLK),
  .ARESETN           (ARESETN),
  .S_AXI_AWADDR      (M_AXI_AWADDR),
  .S_AXI_AWPROT      (M_AXI_AWPROT),
  .S_AXI_AWVALID     (M_AXI_AWVALID),
  .S_AXI_AWREADY     (M_AXI_AWREADY),
  .S_AXI_WDATA       (M_AXI_WDATA),
  .S_AXI_WSTRB       (M_AXI_WSTRB),
  .S_AXI_WVALID      (M_AXI_WVALID),
  .S_AXI_WREADY      (M_AXI_WREADY),
  .S_AXI_BRESP       (M_AXI_BRESP),
  .S_AXI_BVALID      (M_AXI_BVALID),
  .S_AXI_BREADY      (M_AXI_BREADY),
  .S_AXI_ARADDR      (M_AXI_ARADDR),
  .S_AXI_ARPROT      (M_AXI_ARPROT),
  .S_AXI_ARVALID     (M_AXI_ARVALID),
  .S_AXI_ARREADY     (M_AXI_ARREADY),
  .S_AXI_RDATA       (M_AXI_RDATA),
  .S_AXI_RRESP       (M_AXI_RRESP),
  .S_AXI_RVALID      (M_AXI_RVALID),
  .S_AXI_RREADY      (M_AXI_RREADY)
);

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

endmodule: fpgaTop
