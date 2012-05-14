// clock_n210.v - Clocking for the n210 platform
// Copyright (c) 2012 Atomic Rules LLC, ALL RIGHTS RESERVED
//
// 2012-05-14 ssiegel Creation

module clock_n210
  (
   input  clkIn,
   input  rstDCM,
   output locked,
   output clk0_buf,
   output clkdv_buf,
   output clk2x_buf,
   output clk270_buf,
   output clk0_rstn,
   output clkdv_rstn,
   output clk2x_rstn,
   output clk270_rstn
   );

  DCM_SP # (
    .CLK_FEEDBACK          ("1X"),
    .CLKDV_DIVIDE          (2.0),
    .CLKFX_DIVIDE          (1),
    .CLKFX_MULTIPLY        (4),
    .CLKIN_DIVIDE_BY_2     ("FALSE"),
    .CLKIN_PERIOD          (10.000),
    .CLKOUT_PHASE_SHIFT    ("NONE"),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .DFS_FREQUENCY_MODE    ("LOW"),
    .DLL_FREQUENCY_MODE    ("LOW"),
    .DUTY_CYCLE_CORRECTION ("TRUE"),
    .FACTORY_JF            (16'hC080),
    .PHASE_SHIFT           (0),
    .STARTUP_WAIT          ("FALSE")
  ) 
  dcm (
    .CLKFB     (clk0_buf),  // Include BUFG delay in feedback loop
    .CLKIN     (clkIn), 
    .DSSEN     (0), 
    .PSCLK     (0), 
    .PSEN      (0), 
    .PSINCDEC  (0), 
    .RST       (rstDCM), 
    .CLKDV     (clkdv_unbuf), 
    .CLKFX     (), 
    .CLKFX180  (), 
    .CLK0      (clk0_unbuf), 
    .CLK2X     (clk2x_unbuf), 
    .CLK2X180  (), 
    .CLK90     (), 
    .CLK180    (), 
    .CLK270    (clk270_unbuf), 
    .LOCKED    (locked), 
    .PSDONE    (), 
    .STATUS    ()
  );

  // BUFGs to distribute clock outputs...
  BUFG clk0_bufg   (.I(clk0_unbuf),   .O(clk0_buf));
  BUFG clkdv_bufg  (.I(clkdv_unbuf),  .O(clkdv_buf));
  BUFG clk2x_bufg  (.I(clk2x_unbuf),  .O(clk2x_buf));
  BUFG clk270_bufg (.I(clk270_unbuf), .O(clk270_buf));

  // Active-Low reset signals in each clock domain; if DCM unlocks, reset is asserted...
  FDSE # (.INIT(1'b0)) clk0_rst   (.D(locked), .Q(clk0_rstn),  .C(clk0_buf),   .CE(1), .S(0));
  FDSE # (.INIT(1'b0)) clkdv_rst  (.D(locked), .Q(clkdv_rstn), .C(clkdv_buf),  .CE(1), .S(0));
  FDSE # (.INIT(1'b0)) clk2x_rst  (.D(locked), .Q(clk2x_rstn), .C(clk2x_buf),  .CE(1), .S(0));
  FDSE # (.INIT(1'b0)) clk270_rst (.D(locked), .Q(clk270_rstn),.C(clk270_buf), .CE(1), .S(0));

  endmodule 
