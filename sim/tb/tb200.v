// tb200.v - A WCI::OCP test bench with BFM, DUT, and Monitor/Observer
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// This testbench instances three components, and provides them with a common clock and reset
// These three components are connected together with the WCI0_ signal group
// 1. A BFM "Initiator" which initiates WCI cycles
// 2. A DUT "Taget" which completes WCI cycles
// 3. A Monitor/Observer which watches ober the WCI cycles

`timescale 1ns/1ps

module tb200 ();

  reg clk;    // System Clock
  reg rst_n;  // System Reset (active-low)

  always begin  // Clock generation...
    #5; clk = 1'b0;
    #5; clk = 1'b1;
  end

  initial begin  // 16 Clock Cycle Reset generataion...
    #0  rst_n = 1'b0; $display("reset asserted");
    #80 rst_n = 1'b1; $display("reset released");
  end

  // WCI0_ WCI::OCP Wires to interconnect the BFM, DUT and Monitor...
  wire        WCI0_Clk;
  wire        WCI0_MReset_n;
  wire [2:0]  WCI0_MCmd;
  wire        WCI0_MAddrSpace;
  wire [3:0]  WCI0_MByteEn;
  wire [19:0] WCI0_MAddr;
  wire [31:0] WCI0_MData;
  wire [2:0]  WCI0_SResp;
  wire [31:0] WCI0_SData;
  wire        WCI0_SThreadBusy;
  wire [1:0]  WCI0_SFlag;
  wire [1:0]  WCI0_MFlag;

  assign WCI0_Clk      = clk;     // Connect system clock
  assign WCI0_MReset_n = rst_n;   // Connect system reset

  mkWciOcpInitiator bfm (                     // Instance the BFM Initiator...
    .wciM0_Clk          (WCI0_Clk),
    .wciM0_MReset_n     (WCI0_MReset_n),
    .wciM0_MCmd         (WCI0_MCmd),
    .wciM0_MAddrSpace   (WCI0_MAddrSpace),
    .wciM0_MByteEn      (WCI0_MByteEn),
    .wciM0_MAddr        (WCI0_MAddr),
    .wciM0_MData        (WCI0_MData),
    .wciM0_SResp        (WCI0_SResp),
    .wciM0_SData        (WCI0_SData),
    .wciM0_SThreadBusy  (WCI0_SThreadBusy),
    .wciM0_SFlag        (WCI0_SFlag),
    .wciM0_MFlag        (WCI0_MFlag)
  );

  mkWciOcpTarget dut (                        // Instance the DUT Target...
    .wciS0_Clk          (WCI0_Clk),
    .wciS0_MReset_n     (WCI0_MReset_n),
    .wciS0_MCmd         (WCI0_MCmd),
    .wciS0_MAddrSpace   (WCI0_MAddrSpace),
    .wciS0_MByteEn      (WCI0_MByteEn),
    .wciS0_MAddr        (WCI0_MAddr),
    .wciS0_MData        (WCI0_MData),
    .wciS0_SResp        (WCI0_SResp),
    .wciS0_SData        (WCI0_SData),
    .wciS0_SThreadBusy  (WCI0_SThreadBusy),
    .wciS0_SFlag        (WCI0_SFlag),
    .wciS0_MFlag        (WCI0_MFlag)
  );

  mkWciOcpMonitor monitor (                   // Instance the Monitor/Observer...
    .wciO0_Clk          (WCI0_Clk),
    .wciO0_MReset_n     (WCI0_MReset_n),
    .wciO0_MCmd         (WCI0_MCmd),
    .wciO0_MAddrSpace   (WCI0_MAddrSpace),
    .wciO0_MByteEn      (WCI0_MByteEn),
    .wciO0_MAddr        (WCI0_MAddr),
    .wciO0_MData        (WCI0_MData),
    .wciO0_SResp        (WCI0_SResp),
    .wciO0_SData        (WCI0_SData),
    .wciO0_SThreadBusy  (WCI0_SThreadBusy),
    .wciO0_SFlag        (WCI0_SFlag),
    .wciO0_MFlag        (WCI0_MFlag)
  );

endmodule
