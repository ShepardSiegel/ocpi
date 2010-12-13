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
//
// The {LEN/SPT/DPT/ERR} signas, although lockstep with DAT, have their own TVALIDs
// See the nf10 doc for details about their behavior and timing

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
  output         M_AXIS_LEN_TVALID,
  output [7:0]   M_AXIS_SPT_TDATA,    // SPT (Source Port)      - lockstep with DAT_TDATA
  output         M_AXIS_SPT_TVALID,
  output [7:0]   M_AXIS_DPT_TDATA,    // DPT (Destination Port) - lockstep with DAT_TDATA
  output         M_AXIS_DPT_TVALID,
  output         M_AXIS_ERR_TDATA,    // ERR (Error)            - lockstep with DAT_TDATA
  output         M_AXIS_ERR_TVALID,

  input  [255:0] S_AXIS_DAT_TDATA,    // AXI4-Stream (Egress to PCIe) Slave-Consumer...
  input          S_AXIS_DAT_TVALID,
  input  [31:0]  S_AXIS_DAT_TSTRB,
  input          S_AXIS_DAT_TLAST,
  output         S_AXIS_DAT_TREADY,
  input  [15:0]  S_AXIS_LEN_TDATA,    // LEN (Length)           - lockstep with DAT_TDATA
  input          S_AXIS_LEN_TVALID,
  input  [7:0]   S_AXIS_SPT_TDATA,    // SPT (Source Port)      - lockstep with DAT_TDATA
  input          S_AXIS_SPT_TVALID,
  input  [7:0]   S_AXIS_DPT_TDATA,    // DPT (Destination Port) - lockstep with DAT_TDATA
  input          S_AXIS_DPT_TVALID,
  input          S_AXIS_ERR_TDATA,    // ERR (Error)            - lockstep with DAT_TDATA
  input          S_AXIS_ERR_TVALID,

  output [31:0]  DEBUG                // 32b of OPED debug information
);


// The code that follows is the "impedance-matching" to the underlying OPED core logic
// This code, and the the submodules it instantiates, are intended to be functionally opaque
// Here we instance mkOPED, which is the name of the BSV OPED implementation.
// Alternate, future OPED implementations may be adapted and placed here, if desired.
// This adaptation layer may be removed at a later date when it is clear it is not needed

 mkOPED oped (
  .pcie_clk_p        (PCIE_CLK_P),
  .pcie_clk_n        (PCIE_CLK_N),
  .pcie_reset_n      (PCIE_RESET_N),
  .pcie_rxp          (PCIE_RXP),
  .pcie_rxn          (PCIE_RXN),
  .pcie_txp          (PCIE_TXP),
  .pcie_txn          (PCIE_TXN),
  .trnClk            (ACLK),
  .CLK_GATE_trnClk   (),
  /*
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
  .M_AXIS_LEN_TVALID (M_AXIS_LEN_TVALID),
  .M_AXIS_SPT_TDATA  (M_AXIS_SPT_TDATA),
  .M_AXIS_SPT_TVALID (M_AXIS_SPT_TVALID),
  .M_AXIS_DPT_TDATA  (M_AXIS_DPT_TDATA),
  .M_AXIS_DPT_TVALID (M_AXIS_DPT_TVALID),
  .M_AXIS_ERR_TDATA  (M_AXIS_ERR_TDATA),
  .M_AXIS_ERR_TVALID (M_AXIS_ERR_TVALID),
  .S_AXIS_DAT_TDATA  (S_AXIS_DAT_TDATA),
  .S_AXIS_DAT_TVALID (S_AXIS_DAT_TVALID),
  .S_AXIS_DAT_TSTRB  (S_AXIS_DAT_TSTRB),
  .S_AXIS_DAT_TLAST  (S_AXIS_DAT_TLAST),
  .S_AXIS_DAT_TREADY (S_AXIS_DAT_TREADY),
  .S_AXIS_LEN_TDATA  (S_AXIS_LEN_TDATA),
  .S_AXIS_LEN_TVALID (S_AXIS_LEN_TVALID),
  .S_AXIS_SPT_TDATA  (S_AXIS_SPT_TDATA),
  .S_AXIS_SPT_TVALID (S_AXIS_SPT_TVALID),
  .S_AXIS_DPT_TDATA  (S_AXIS_DPT_TDATA),
  .S_AXIS_DPT_TVALID (S_AXIS_DPT_TVALID),
  .S_AXIS_ERR_TDATA  (S_AXIS_ERR_TDATA),
  .S_AXIS_ERR_TVALID (S_AXIS_ERR_TVALID),
  */
  .debug             (DEBUG)
);

endmodule : OPED
