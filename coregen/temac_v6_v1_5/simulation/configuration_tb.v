//----------------------------------------------------------------------
// Title      : Vector Configuration Testbench
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : configuration_tb.v
// Version    : 1.5
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//----------------------------------------------------------------------
// Description: Management
//
//              This testbench will control the speed settings of the
//              EMAC block (if required) by driving the Tie-off vector.
//----------------------------------------------------------------------

`timescale 1ps / 1ps


module configuration_tb
 (
   reset,

   //----------------------------------------------------------------
   // Host interface: host_clk is always required
   //----------------------------------------------------------------
   host_clk,

   //----------------------------------------------------------------
   // Testbench semaphores
   //----------------------------------------------------------------
   configuration_busy,
   monitor_finished_1g,
   monitor_finished_100m,
   monitor_finished_10m,
   monitor_error
 );

  // Port declarations
  output reg       reset;
  output reg       host_clk;
  output reg       configuration_busy;
  input            monitor_finished_1g;
  input            monitor_finished_100m;
  input            monitor_finished_10m;
  input            monitor_error;


  //--------------------------------------------------------------------
  // HOSTCLK driver
  //--------------------------------------------------------------------

  // Drive HOSTCLK at one third the frequency of GTX_CLK
  initial
  begin
    host_clk <= 1'b0;
 #2000;
    forever
    begin
      host_clk <= 1'b1;
      #12000;
      host_clk <= 1'b0;
      #12000;
    end
  end


  //------------------------------------------------------------------
  // Testbench configuration
  //------------------------------------------------------------------
  initial
  begin : tb_configuration

    reset <= 1'b1;

    // test bench semaphores
    configuration_busy <= 0;

    #200000
    configuration_busy <= 1;

    // Reset the core
    $display("Resetting the design...");
    $display("Timing checks are not valid");

    reset <= 1'b1;
    #4000000;
    reset <= 1'b0;
    #200000;

    $display("Timing checks are valid");
    #15000000

    #100000
    configuration_busy <= 0;

    // Wait for 1Gb/s frames to complete
    wait (monitor_finished_1g == 1);

    #100000

    if (monitor_error == 1'b1)
    begin
         $display("*************************");
         $display("ERROR: Simulation Failed.");
         $display("*************************");
    end
    else begin
         $display("****************************");
         $display("PASS: Simulation Successful.");
         $display("****************************");
    end

    // Our work here is done
    $display("Simulation Complete.");
 $stop;

  end // tb_configuration


  //------------------------------------------------------------------
  // If the simulation is still going after 2 ms
  // then something has gone wrong
  //------------------------------------------------------------------
  initial
  begin : p_end_simulation
    #2000000000
    $display("ERROR - Testbench timed out");
    $stop;
  end // p_end_simulation


endmodule
