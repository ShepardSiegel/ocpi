// OPED.v - OpenCPI PCIe Endpoint with DMA 
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// This is the top-level port signature of the OPED sub-system
// The signals are grouped functionally as indicated by their prefix
// + The PCIE_ signals must connect directly to their IOBs with no intermediate logic.
// + The ACLK and ARESETN outputs are the clock and reset for all other port groups
// + The M_AXI_ signal group is a AXI4-Lite Master with a 4GB address space
// + The M_AXIS group is the AXI4-Stream channel providing ingress data from PCIe->FPGA
// + The S_AXIS group is the AXI4-Stream channel supplying egress  data from FPGA->PCIe
// + The ERR channel has zero bits of data. An error is indicated by TVALID assertion
// + The DEBUG signals contain up to 32 "interesting" bits of status
//
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


module OPED # 

  ( // OPED accepts the MPD-named paramater specifications...
  parameter                              C_M_AXIS_DATA_WIDTH  = 32,
  parameter                              C_S_AXIS_DATA_WIDTH  = 32,
  parameter                              C_M_AXIS_TUSER_WIDTH = 128,
  parameter                              C_S_AXIS_TUSER_WIDTH = 128,
  parameter                              HAS_DEBUG_LOGIC      = 0)  // 0 = no debug logic, 1= debug logic

  ( // OPED uses the MPD-specified signal names for the AXI user-facing ports...
  input                                  PCIE_CLKP,           // PCIe connections...
  input                                  PCIE_CLKN,
  input                                  PCIE_RSTN,
  input  [7:0]                           PCIE_RXP,
  input  [7:0]                           PCIE_RXN,
  output [7:0]                           PCIE_TXP,
  output [7:0]                           PCIE_TXN,

  output                                 ACLK,                // Clock (125 MHz) (BUFG driven)
  output                                 ARESETN,             // Synchronous Reset, Active-Low

  output [31:0]                          M_AXI_AWADDR,        // AXI4-Lite Write-Address channel..
  output [2:0]                           M_AXI_AWPROT,
  output                                 M_AXI_AWVALID,         
  input                                  M_AXI_AWREADY,
  output [31:0]                          M_AXI_WDATA,         // AXI4-Lite Write-Data channel...
  output [3:0]                           M_AXI_WSTRB,
  output                                 M_AXI_WVALID,
  input                                  M_AXI_WREADY,
  input  [1:0]                           M_AXI_BRESP,         // AXI4-Lite Write-Response channel...
  input                                  M_AXI_BVALID,
  output                                 M_AXI_BREADY,
  output [31:0]                          M_AXI_ARADDR,        // AXI4-Lite Read-Address channel...
  output [2:0]                           M_AXI_ARPROT,
  output                                 M_AXI_ARVALID,
  input                                  M_AXI_ARREADY,
  input  [31:0]                          M_AXI_RDATA,         // AXI4-Lite Read-Data channel...
  input  [1:0]                           M_AXI_RRESP,
  input                                  M_AXI_RVALID,
  output                                 M_AXI_RREADY,

  output [C_M_AXIS_DATA_WIDTH-1:0]       M_AXIS_DAT_TDATA,    // AXI4-Stream (Ingress from PCIe) Master-Producer...
  output [C_M_AXIS_DATA_WIDTH/8-1:0]     M_AXIS_DAT_TSTRB,
  output [C_M_AXIS_TUSER_WIDTH-1:0]      M_AXIS_DAT_TUSER, 
  output                                 M_AXIS_DAT_TLAST,
  output                                 M_AXIS_DAT_TVALID,
  input                                  M_AXIS_DAT_TREADY,

  input  [C_S_AXIS_DATA_WIDTH-1:0]       S_AXIS_DAT_TDATA,    // AXI4-Stream (Egress to PCIe) Slave-Consumer...
  input  [C_S_AXIS_DATA_WIDTH/8-1:0]     S_AXIS_DAT_TSTRB,
  input  [C_S_AXIS_TUSER_WIDTH-1:0]      S_AXIS_DAT_TUSER, 
  input                                  S_AXIS_DAT_TLAST,
  input                                  S_AXIS_DAT_TVALID,
  output                                 S_AXIS_DAT_TREADY,

  output [31:0]                          DEBUG                // 32b of OPED debug information
);


// The code that follows is the "impedance-matching" to the underlying OPED core logic
// This code, and the the submodules it instantiates, are intended to be functionally opaque
// Here we instance mkOPED, which is the name of the BSV OPED implementation.
// Alternately, future OPED implementations may be adapted and placed here, if desired.
// This adaptation layer may be removed at a later date when it is clear it is not needed
//

// Compile time check for expected paramaters...
initial begin
  if (C_M_AXIS_DATA_WIDTH != 32)   begin $display("Unsupported M_AXIS_DATA width");  $finish; end
  if (C_S_AXIS_DATA_WIDTH != 32)   begin $display("Unsupported S_AXIS_DATA width");  $finish; end
  if (C_M_AXIS_TUSER_WIDTH != 128) begin $display("Unsupported M_AXIS_TUSER width"); $finish; end
  if (C_S_AXIS_TUSER_WIDTH != 128) begin $display("Unsupported S_AXIS_TUSER width"); $finish; end
end

 mkOPED_v5 oped #
   (
     parameter hasDebugLogic = HAS_DEBUG_LOGIC      // Set to 0 for no debug logic; Set to 1 for debug logic
   )
   (
  .pci0_clkp         (PCIE_CLKP),
  .pci0_clkn         (PCIE_CLKN),
  .RST_N_pci0_rstn   (PCIE_RSTN),
  .pcie_rxp_i        (PCIE_RXP),
  .pcie_rxn_i        (PCIE_RXN),
  .pcie_txp          (PCIE_TXP),
  .pcie_txn          (PCIE_TXN),
  .p125clk           (ACLK),
  .CLK_GATE_p125clk  (),
  .RST_N_p125rst     (ARESETN),
  .axi4m_AWADDR      (M_AXI_AWADDR),
  .axi4m_AWPROT      (M_AXI_AWPROT),
  .axi4m_AWVALID     (M_AXI_AWVALID),
  .axi4m_AWREADY     (M_AXI_AWREADY),
  .axi4m_WDATA       (M_AXI_WDATA),
  .axi4m_WSTRB       (M_AXI_WSTRB),
  .axi4m_WVALID      (M_AXI_WVALID),
  .axi4m_WREADY      (M_AXI_WREADY),
  .axi4m_BRESP       (M_AXI_BRESP),
  .axi4m_BVALID      (M_AXI_BVALID),
  .axi4m_BREADY      (M_AXI_BREADY),
  .axi4m_ARADDR      (M_AXI_ARADDR),
  .axi4m_ARPROT      (M_AXI_ARPROT),
  .axi4m_ARVALID     (M_AXI_ARVALID),
  .axi4m_ARREADY     (M_AXI_ARREADY),
  .axi4m_RDATA       (M_AXI_RDATA),
  .axi4m_RRESP       (M_AXI_RRESP),
  .axi4m_RVALID      (M_AXI_RVALID),
  .axi4m_RREADY      (M_AXI_RREADY),

  .axisM_TDATA       (M_AXIS_DAT_TDATA),
  .axisM_TVALID      (M_AXIS_DAT_TVALID),
  .axisM_TSTRB       (M_AXIS_DAT_TSTRB),
  .axisM_TUSER       (M_AXIS_DAT_TUSER),
  .axisM_TLAST       (M_AXIS_DAT_TLAST),
  .axisM_TREADY      (M_AXIS_DAT_TREADY),

  .axisS_TDATA       (S_AXIS_DAT_TDATA),
  .axisS_TVALID      (S_AXIS_DAT_TVALID),
  .axisS_TSTRB       (S_AXIS_DAT_TSTRB),
  .axisS_TUSER       (S_AXIS_DAT_TUSER),
  .axisS_TLAST       (S_AXIS_DAT_TLAST),
  .axisS_TREADY      (S_AXIS_DAT_TREADY),

  .debug             (DEBUG)
);

endmodule
