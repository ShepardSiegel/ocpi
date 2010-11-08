// tb201.v - A WCI::AXI test bench with BFM, DUT, and Monitor/Observer
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// This testbench instances three components, and provides them with a common clock and reset
// These three components are connected together with the WCI0_ signal group
// 1. A BFM "Initiator" which initiates WCI cycles
// 2. A DUT "Taget" which completes WCI cycles
// 3. A Monitor/Observer which watches ober the WCI cycles

`timescale 1ns/1ps

module tb201 ();

  reg CLK;    // System Clock
  reg RST_N;  // System Reset (active-low)

  always begin  // Clock generation...
    #5; CLK = 1'b0;
    #5; CLK = 1'b1;
  end

  initial begin: initblock
    integer i;
    localparam resetCycles = 16; 
    #0 RST_N = 1'b0; $display("reset asserted, RST_N=0");
    for (i=0;i<resetCycles;i=i+1) @(posedge CLK);
    #0 RST_N = 1'b1; $display("reset released, RST_N=1");
  end

  // WCI0_ WCI::AXI Wires to interconnect the BFM, DUT and Monitor...
  wire        WCI0_ACLK;
  wire        WCI0_ARESETn;
  wire        WCI0_AWVALID;
  wire        WCI0_AWREADY;
  wire [31:0] WCI0_AWADDR;
  wire [2:0]  WCI0_AWPROT;
  wire        WCI0_WVALID;
  wire        WCI0_WREADY;
  wire [31:0] WCI0_WDATA;
  wire [3:0]  WCI0_WSTRB;
  wire        WCI0_BVALID;
  wire        WCI0_BREADY;
  wire [1:0]  WCI0_BRESP;
  wire        WCI0_ARVALID;
  wire        WCI0_ARREADY;
  wire [31:0] WCI0_ARADDR;
  wire [2:0]  WCI0_ARPROT;
  wire        WCI0_RVALID;
  wire        WCI0_RREADY;
  wire [31:0] WCI0_RDATA;
  wire [1:0]  WCI0_RRESP;

  assign WCI0_ACLK    = CLK;     // Connect system clock to WCI0 Link

  mkWciAxiInitiator bfm (           // Instance the BFM Initiator...
    .CLK                  (CLK),
    .RST_N                (RST_N),
    .wciM0_ACLK           (WCI0_ACLK),
    .RST_N_wciM0_ARESETn  (WCI0_ARESETn),
    .wciM0_AWVALID        (WCI0_AWVALID),
    .wciM0_AWREADY        (WCI0_AWREADY),
    .wciM0_AWADDR         (WCI0_AWADDR),
    .wciM0_AWPROT         (WCI0_AWPROT),
    .wciM0_WVALID         (WCI0_WVALID),
    .wciM0_WREADY         (WCI0_WREADY),
    .wciM0_WDATA          (WCI0_WDATA),
    .wciM0_WSTRB          (WCI0_WSTRB),
    .wciM0_BVALID         (WCI0_BVALID),
    .wciM0_BREADY         (WCI0_BREADY),
    .wciM0_BRESP          (WCI0_BRESP),
    .wciM0_ARVALID        (WCI0_ARVALID),
    .wciM0_ARREADY        (WCI0_ARVALID),
    .wciM0_ARADDR         (WCI0_ARADDR),
    .wciM0_ARPROT         (WCI0_ARPROT),
    .wciM0_RVALID         (WCI0_RVALID),
    .wciM0_RREADY         (WCI0_RREADY),
    .wciM0_RDATA          (WCI0_RDATA),
    .wciM0_RRESP          (WCI0_RRESP)
  );

  mkWciAxiTarget dut (              // Instance the DUT Target...
    .wciS0_ACLK           (WCI0_ACLK),
    .wciS0_ARESETn        (WCI0_ARESETn),
    .wciS0_AWVALID        (WCI0_AWVALID),
    .wciS0_AWREADY        (WCI0_AWREADY),
    .wciS0_AWADDR         (WCI0_AWADDR),
    .wciS0_AWPROT         (WCI0_AWPROT),
    .wciS0_WVALID         (WCI0_WVALID),
    .wciS0_WREADY         (WCI0_WREADY),
    .wciS0_WDATA          (WCI0_WDATA),
    .wciS0_WSTRB          (WCI0_WSTRB),
    .wciS0_BVALID         (WCI0_BVALID),
    .wciS0_BREADY         (WCI0_BREADY),
    .wciS0_BRESP          (WCI0_BRESP),
    .wciS0_ARVALID        (WCI0_ARVALID),
    .wciS0_ARREADY        (WCI0_ARVALID),
    .wciS0_ARADDR         (WCI0_ARADDR),
    .wciS0_ARPROT         (WCI0_ARPROT),
    .wciS0_RVALID         (WCI0_RVALID),
    .wciS0_RREADY         (WCI0_RREADY),
    .wciS0_RDATA          (WCI0_RDATA),
    .wciS0_RRESP          (WCI0_RRESP)
  );

  mkWciAxiMonitor monitor (         // Instance the Monitor/Observer...
    .wciO0_ACLK           (WCI0_ACLK),
    .wciO0_ARESETn        (WCI0_ARESETn),
    .wciO0_AWVALID        (WCI0_AWVALID),
    .wciO0_AWREADY        (WCI0_AWREADY),
    .wciO0_AWADDR         (WCI0_AWADDR),
    .wciO0_AWPROT         (WCI0_AWPROT),
    .wciO0_WVALID         (WCI0_WVALID),
    .wciO0_WREADY         (WCI0_WREADY),
    .wciO0_WDATA          (WCI0_WDATA),
    .wciO0_WSTRB          (WCI0_WSTRB),
    .wciO0_BVALID         (WCI0_BVALID),
    .wciO0_BREADY         (WCI0_BREADY),
    .wciO0_BRESP          (WCI0_BRESP),
    .wciO0_ARVALID        (WCI0_ARVALID),
    .wciO0_ARREADY        (WCI0_ARVALID),
    .wciO0_ARADDR         (WCI0_ARADDR),
    .wciO0_ARPROT         (WCI0_ARPROT),
    .wciO0_RVALID         (WCI0_RVALID),
    .wciO0_RREADY         (WCI0_RREADY),
    .wciO0_RDATA          (WCI0_RDATA),
    .wciO0_RRESP          (WCI0_RRESP)
  );

endmodule
