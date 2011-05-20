// fpgaTop_nf10.v - A proxy fpga top-level to hold OPED.v
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// The purpose of this module is to "stand in" for the real NetFPGA-10G as
// OPED is developed. This file would not normally be needed for any normal 
// NETFPGA-10G build. It is useful for standalone OPED testing and building.

// This level is the top level of the nf10 FPGA, this is a stand-in for the real NETFPGA-10G top...
//

module fpgaTop (
  input  wire        pcie_clkp,      // PCIe Clock +
  input  wire        pcie_clkn,      // PCIe Clock -
  input  wire        pcie_rstn,      // PCIe Reset
  input  wire [7:0]  pcie_rxp,       // PCIe lanes...
  input  wire [7:0]  pcie_rxn,
  output wire [7:0]  pcie_txp,
  output wire [7:0]  pcie_txn,
  output wire [2:0]  led,
  output reg  [10:1] mictor
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
wire [31:0]  M_AXIS_DAT_TDATA;
wire         M_AXIS_DAT_TVALID;
wire [3:0]   M_AXIS_DAT_TSTRB;
wire [127:0] M_AXIS_DAT_TUSER;
wire         M_AXIS_DAT_TLAST;
wire         M_AXIS_DAT_TREADY;
wire [31:0]  S_AXIS_DAT_TDATA;
wire         S_AXIS_DAT_TVALID;
wire [3:0]   S_AXIS_DAT_TSTRB;
wire [127:0] S_AXIS_DAT_TUSER;
wire         S_AXIS_DAT_TLAST;
wire         S_AXIS_DAT_TREADY;
wire [31:0]  I_AXIS_DAT_TDATA;
wire         I_AXIS_DAT_TVALID;
wire [3:0]   I_AXIS_DAT_TSTRB;
wire [127:0] I_AXIS_DAT_TUSER;
wire         I_AXIS_DAT_TLAST;
wire         I_AXIS_DAT_TREADY;

wire [31:0]  debug_oped;       // The 32b vector of debug signals from OPED
assign led = debug_oped[2:0];  // Drive the three LEDs from the debug_oped port
always@(posedge ACLK) begin
  mictor[10]  <= ^debug_oped; // XOR reduce the debug bits onto mictor[10]
  mictor[9:1] <=  debug_oped[8:0];
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
  .M_AXIS_DAT_TUSER  (M_AXIS_DAT_TUSER),
  .M_AXIS_DAT_TLAST  (M_AXIS_DAT_TLAST),
  .M_AXIS_DAT_TREADY (M_AXIS_DAT_TREADY),
  .S_AXIS_DAT_TDATA  (S_AXIS_DAT_TDATA),
  .S_AXIS_DAT_TVALID (S_AXIS_DAT_TVALID),
  .S_AXIS_DAT_TSTRB  (S_AXIS_DAT_TSTRB),
  .S_AXIS_DAT_TUSER  (S_AXIS_DAT_TUSER),
  .S_AXIS_DAT_TLAST  (S_AXIS_DAT_TLAST),
  .S_AXIS_DAT_TREADY (S_AXIS_DAT_TREADY),
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

// Instance and connect a loopback core from the ingress to the egress...
// TODO: This module will be replaced with the nf10 "data plane"

// + The 128b of TUSER are assigned as follows:
// TUSER[15:0]   Transfer Length in Bytes  (provided by OPED AXIS Master; ignored by OPED AXIS Slave since TLAST implicit length) 
// TUSER[23:16]  Source Port (SPT) (provided by OPED AXIS Master from DP0 opcode; ignored by OPED AXIS Slave)
// TUSER[31:24]  Destination Port (DPT) (driven to 8'h01 by OPED AXIS Master;  used by OPED AXIS Slave to make DP1 opcode)
// TUSER[127:32] User metadata bits, un-used by OPED. driven to 0 by OPED AXIS master; un-used by OPED AXIS slave
//
// Note that OPED is "port-encoding-agnostic" with respect to the values on SPT and DPT:
//  a. In the case of packets moving downstream from host to NF10, OPED places DP0 opcode metadata on SPT
//  b. In the case of packets moving upstream from NF10 to host, OPED captures DPT and places it in DP1 opcode
//  The value 8'h01 is placed as a constant in the DPT output of the OPED AXIS Master

// Note that OPED does nothing with the TUSER[127:32] user metadata bits.
// a. It drives them to 0 on the AXIS Master
// b. it ignores them on the the AXIS Slave

/*
 AXIS_LOOPBACK axisLoopback (
  .ACLK              (ACLK),
  .ARESETN           (ARESETN),
  .S_AXIS_DAT_TDATA  (M_AXIS_DAT_TDATA),
  .S_AXIS_DAT_TVALID (M_AXIS_DAT_TVALID),
  .S_AXIS_DAT_TSTRB  (M_AXIS_DAT_TSTRB),
  .S_AXIS_DAT_TUSER  (M_AXIS_DAT_TUSER), 
  .S_AXIS_DAT_TLAST  (M_AXIS_DAT_TLAST),
  .S_AXIS_DAT_TREADY (M_AXIS_DAT_TREADY),
  .M_AXIS_DAT_TDATA  (S_AXIS_DAT_TDATA),
  .M_AXIS_DAT_TVALID (S_AXIS_DAT_TVALID),
  .M_AXIS_DAT_TSTRB  (S_AXIS_DAT_TSTRB),
  .M_AXIS_DAT_TUSER  (S_AXIS_DAT_TUSER), 
  .M_AXIS_DAT_TLAST  (S_AXIS_DAT_TLAST),
  .M_AXIS_DAT_TREADY (S_AXIS_DAT_TREADY)
);
*/

nf10_axis_converter 
#(  .C_M_AXIS_DATA_WIDTH (64),
    .C_S_AXIS_DATA_WIDTH (256),
    .C_USER_WIDTH (128),
    .C_LEN_WIDTH (16),
    .C_SPT_WIDTH (8),
    .C_DPT_WIDTH (8),
    .C_DEFAULT_VALUE_ENABLE (0),
    .C_DEFAULT_SRC_PORT (0),
    .C_DEFAULT_DST_PORT (0))   conv_i0
(
    .axi_aclk      (ACLK),
    .axi_resetn    (ARESETN),
    .s_axis_tdata  (M_AXIS_DAT_TDATA),
    .s_axis_tstrb  (M_AXIS_DAT_TSTRB),
    .s_axis_tuser  (M_AXIS_DAT_TUSER),
    .s_axis_tvalid (M_AXIS_DAT_TVALID),
    .s_axis_tready (M_AXIS_DAT_TREADY),
    .s_axis_tlast  (M_AXIS_DAT_TLAST),
    .m_axis_tdata  (I_AXIS_DAT_TDATA),
    .m_axis_tstrb  (I_AXIS_DAT_TSTRB),
    .m_axis_tuser  (I_AXIS_DAT_TUSER),
    .m_axis_tvalid (I_AXIS_DAT_TVALID),
    .m_axis_tready (I_AXIS_DAT_TREADY),
    .m_axis_tlast  (I_AXIS_DAT_TLAST)
);

nf10_axis_converter 
#(  .C_M_AXIS_DATA_WIDTH (256),
    .C_S_AXIS_DATA_WIDTH (64),
    .C_USER_WIDTH (128),
    .C_LEN_WIDTH (16),
    .C_SPT_WIDTH (8),
    .C_DPT_WIDTH (8),
    .C_DEFAULT_VALUE_ENABLE (0),
    .C_DEFAULT_SRC_PORT (0),
    .C_DEFAULT_DST_PORT (0)) conv_i1
(
    .axi_aclk      (ACLK),
    .axi_resetn    (ARESETN),
    .s_axis_tdata  (I_AXIS_DAT_TDATA),
    .s_axis_tstrb  (I_AXIS_DAT_TSTRB),
    .s_axis_tuser  (I_AXIS_DAT_TUSER),
    .s_axis_tvalid (I_AXIS_DAT_TVALID),
    .s_axis_tready (I_AXIS_DAT_TREADY),
    .s_axis_tlast  (I_AXIS_DAT_TLAST),
    .m_axis_tdata  (S_AXIS_DAT_TDATA),
    .m_axis_tstrb  (S_AXIS_DAT_TSTRB),
    .m_axis_tuser  (S_AXIS_DAT_TUSER),
    .m_axis_tvalid (S_AXIS_DAT_TVALID),
    .m_axis_tready (S_AXIS_DAT_TREADY),
    .m_axis_tlast  (S_AXIS_DAT_TLAST)
);


endmodule
