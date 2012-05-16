// ClockN210.bsv N210 Platform Specific Clock Service
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// BSV Imports...
import Clocks            ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import TieOff            ::*;
import Vector            ::*;

(* always_ready, always_enabled *)
interface ClockN210Ifc;
  method    Bool   isLocked;
  interface Clock  clk0;
  interface Reset  rst0;   // active-low
  interface Clock  clkdv;
  interface Reset  rstdv;  // active-low
  interface Clock  clk2x;
  interface Reset  rst2x;  // active-low
  interface Clock  clk125;
  interface Reset  rst125; // active-low

endinterface

import "BVI" clock_n210 =
module vMkClockN210#(Clock clk, Reset rstn)(ClockN210Ifc);

   default_clock clk_src(clkIn, (*unused*)clk_gate) = clk;
   default_reset no_reset;
   input_reset rst_src(rstIn) clocked_by(clk_src) = rstn;

   output_clock clk0   (clk0_buf);
   output_clock clkdv  (clkdv_buf);
   output_clock clk2x  (clk2x_buf);
   output_clock clk125 (clk125_buf);
   
   output_reset rst0   (clk0_rstn)   clocked_by(clk0);
   output_reset rstdv  (clkdv_rstn)  clocked_by(clkdv);
   output_reset rst2x  (clk2x_rstn)  clocked_by(clk2x);
   output_reset rst125 (clk125_rstn) clocked_by(clk125);

   method locked isLocked() clocked_by(no_clock) reset_by(no_reset);

   schedule isLocked CF isLocked;

endmodule

module mkClockN210#(Clock clk, Reset rstn)(ClockN210Ifc);
   ClockN210Ifc _clk <- vMkClockN210(clk, rstn);
   return(_clk);
endmodule
