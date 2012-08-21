// clock_n210.v - Clock Service for the n210 platform
// Copyright (c) 2012 Atomic Rules LLC, ALL RIGHTS RESERVED
//
// Requires BitGen LCK_cycle to be set True so that STARTUP_WAIT functions
//
// 2012-05-14 ssiegel Creation
// 2012-05-16 ssiegel Reset Logic Enhancement, Unlock Detect
// 2012-06-06 ssiegel De-Feature and Simplify by commenting out all non-essential clocks 

module clock_n210
  (
   input  clkIn,     // ref clock in
   input  rstIn,     // active-low reset
   output locked,
   output clk0_buf,
// output clkdv_buf,
// output clk2x_buf,
// output clk125_buf,
   output clk0_rstn
// output clkdv_rstn,
// output clk2x_rstn,
// output clk125_rstn
   );

  wire [7:0] dcmStatus;
  wire unlock1, unlock2, unlock3, unlockRst, locked_d, rstInD, forceReset;
  assign forceReset = ~rstInD;

  DCM_SP # (
    .CLK_FEEDBACK          ("1X"),
    .CLKDV_DIVIDE          (2.0),
    .CLKFX_DIVIDE          (4),
    .CLKFX_MULTIPLY        (5),
    .CLKIN_DIVIDE_BY_2     ("FALSE"),
    .CLKIN_PERIOD          (10.000),
    .CLKOUT_PHASE_SHIFT    ("NONE"),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .DFS_FREQUENCY_MODE    ("LOW"),
    .DLL_FREQUENCY_MODE    ("LOW"),
    .DUTY_CYCLE_CORRECTION ("TRUE"),
    .FACTORY_JF            (16'hC080),
    .PHASE_SHIFT           (0),
    .STARTUP_WAIT          ("FALSE")  // No Wait
  ) 
  dcm (
    .CLKFB     (clk0_buf),            // Include BUFG delay in feedback loop
    .CLKIN     (clkIn), 
    .DSSEN     (0), 
    .PSCLK     (0), 
    .PSEN      (0), 
    .PSINCDEC  (0), 
    .RST       (rstDCM), 
    .CLKDV     (clkdv_unbuf), 
    .CLKFX     (),
//  .CLKFX     (clk125_unbuf),        // 100 * 5 / 4 = 125 MHz
    .CLKFX180  (), 
    .CLK0      (clk0_unbuf), 
    .CLK2X     (), 
//  .CLK2X     (clk2x_unbuf), 
    .CLK2X180  (), 
    .CLK90     (), 
    .CLK180    (), 
    .CLK270    (), 
    .LOCKED    (locked), 
    .PSDONE    (), 
    .STATUS    (dcmStatus)
  );

  // BUFGs to distribute clock outputs...
  BUFG clk0_bufg   (.I(clk0_unbuf),   .O(clk0_buf));
//BUFG clkdv_bufg  (.I(clkdv_unbuf),  .O(clkdv_buf));
//BUFG clk2x_bufg  (.I(clk2x_unbuf),  .O(clk2x_buf));
//BUFG clk125_bufg (.I(clk125_unbuf), .O(clk125_buf));

  // Active-Low reset signals in each clock domain; if DCM unlocks, reset is asserted
  // Use rstInD active-low to force reset pulse when DCM locked...
  FDR clk0_rst   (.D(locked), .R(forceReset), .Q(clk0_rstn),   .C(clk0_buf)  );
//FDR clkdv_rst  (.D(locked), .R(forceReset), .Q(clkdv_rstn),  .C(clkdv_buf) );
//FDR clk2x_rst  (.D(locked), .R(forceReset), .Q(clk2x_rstn),  .C(clk2x_buf) );
//FDR clk125_rst (.D(locked), .R(forceReset), .Q(clk125_rstn), .C(clk125_buf));
  
  // Watch for falling-edge of DCM locked signal... 
  FD   lock_flop  (.C(clkIn), .D(locked), .Q(locked_d)); 
  AND2 edge_cap   (.I0(~locked), .I1(locked_d), .O(unlock1));
  FD   lock_flop2 (.C(clkIn), .D(unlock1), .Q(unlock2)); 
  FD   lock_flop3 (.C(clkIn), .D(unlock2), .Q(unlock3)); 
  OR3  lock_or    (.I0(unlock1), .I1(unlock2), .I2(unlock3), .O(unlockRst));  // 3 cycle unlockRst

  // Reset DCM on unlockEdge or rstIn...
  FD   rst_fd (.C(clkIn), .D(rstIn), .Q(rstInD));              // sync external reset to input clkIn
  OR2  rst_or (.I0(forceReset), .I1(unlockRst), .O(rstDCM));   // create rstDCM signal

  endmodule 
