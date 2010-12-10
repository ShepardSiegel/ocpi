// OPED.v - OpenCPI PCIe Endpoint with DMA 
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// This is the top-level port signature of the OPED sub-system
// The signals are grouped functionally as indicated by their prefix
// + The PCIE_ signals must connect directly to their IOBs with no intermediate logic.
// + The ACLK and ARESETN outputs are the clock and reset for all other port groups
// + The M_AXI_ signal group is a AXI4-Lite Master with a 4GB address space
// + The M_AXIS group is the AXI4-Stream channel providing ingress data from PCIe->FPGA
// + The S_AXIS group is the AXI4-Stream channel supplying egress  data from FPGA->PCIe
// + The DEBUG signals contain up to 32 "interesting" bits of status

module OPED (
                                      // PCIE Endpoint Connections...
  input          PCIE_CLK_P, 
  input          PCIE_CLK_N,
  input          PCIE_RESET_N,
  input  [7:0]   PCIE_RXP,
  input  [7:0]   PCIE_RXN,
  output [7:0]   PCIE_TXP,
  output [7:0]   PCIE_TXN,

  output         ACLK,                // Clock (125 MHz) (BUFG driven)
  output         ARESETN,             // Synchronous Reset, Active-Low

  output [31:0]  M_AXI_AWADDR,        // AXI4-Lite Write-Address channel..
  output [2:0]   M_AXI_AWPROT,
  output         M_AXI_AWVALID,         
  input          M_AXI_AWREADY,
  output [31:0]  M_AXI_WDATA,         // AXI4-Lite Write-Data channel...
  output [3:0]   M_AXI_WSTRB,
  output         M_AXI_WVALID,
  input          M_AXI_WREADY,
  input  [1:0]   M_AXI_BRESP,         // AXI4-Lite Write-Response channel...
  input          M_AXI_BVALID,
  output         M_AXI_BREADY,
  output [31:0]  M_AXI_ARADDR,        // AXI4-Lite Read-Address channel...
  output [2:0]   M_AXI_ARPROT,
  output         M_AXI_ARVALID,
  input          M_AXI_ARREADY,
  input  [31:0]  M_AXI_RDATA,         // AXI4-Lite Read-Data channel...
  input  [1:0]   M_AXI_RRESP,
  input          M_AXI_RVALID,
  output         M_AXI_RREADY,

  output [255:0] M_AXIS_DAT_TDATA,    // AXI4-Stream (Ingress from PCIe) Master-Producer...
  output         M_AXIS_DAT_TVALID,
  output [31:0]  M_AXIS_DAT_TSTRB,
  output         M_AXIS_DAT_TLAST,
  input          M_AXIS_DAT_TREADY,
  output [15:0]  M_AXIS_LEN_TDATA,    // LEN (Length)           - lockstep with DAT_TDATA
  output [7:0]   M_AXIS_SPT_TDATA,    // SPT (Source Port)      - lockstep with DAT_TDATA
  output [7:0]   M_AXIS_DPT_TDATA,    // DPT (Destination Port) - lockstep with DAT_TDATA
  output         M_AXIS_ERR_TDATA,    // ERR (Error)            - lockstep with DAT_TDATA

  input  [255:0] S_AXIS_DAT_TDATA,    // AXI4-Stream (Egress to PCIe) Slave-Consumer...
  input          S_AXIS_DAT_TVALID,
  input  [31:0]  S_AXIS_DAT_TSTRB,
  input          S_AXIS_DAT_TLAST,
  output         S_AXIS_DAT_TREADY,
  input  [15:0]  S_AXIS_LEN_TDATA,    // LEN (Length)           - lockstep with DAT_TDATA
  input  [7:0]   S_AXIS_SPT_TDATA,    // SPT (Source Port)      - lockstep with DAT_TDATA
  input  [7:0]   S_AXIS_DPT_TDATA,    // DPT (Destination Port) - lockstep with DAT_TDATA
  input          S_AXIS_ERR_TDATA,    // ERR (Error)            - lockstep with DAT_TDATA

  output [31:0]  DEBUG                // 32b of OPED debug information
);

endmodule : OPED
