// ClockN210.bsv N210 Platform Specific Clock Circuit 
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

//import XilinxExtra       ::*;

// BSV Imports...
import Clocks            ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import Gray              ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;

(* always_ready, always_enabled *)
interface ClockN210Ifc;
  // Inward-Facing...
  method    Bool   isLocked;
  interface Clock  clk0;
  interface Reset  rst0;   // active-low
  interface Clock  clkdv;
  interface Reset  rstdv;  // active-low
  interface Clock  clk2x;
  interface Reset  rst2x;  // active-low
  interface Clock  clk270;
  interface Reset  rst270; // active-low

endinterface

import "BVI" clock_n210 =
module vMkClockN210#(Clock clk)(ClockN210Ifc);

   default_clock clk_src(clkIn, (*unused*)clk_gate) = clk;
   default_reset no_reset;

   output_clock clk0   (clk0_buf);
   output_clock clkdv  (clkdv_buf);
   output_clock clk2x  (clk2x_buf);
   output_clock clk270 (clk270_buf);
   
   output_reset rst0   (clk0_rstn)   clocked_by(clk0);
   output_reset rstdv  (clkdv_rstn)  clocked_by(clkdv);
   output_reset rst2x  (clk2x_rstn)  clocked_by(clk2x);
   output_reset rst270 (clk270_rstn) clocked_by(clk270);

   method locked isLocked() clocked_by(no_clock) reset_by(no_reset);

   schedule isLocked CF isLocked;

endmodule

module mkClockN210#(Clock clk)(ClockN210Ifc);
   ClockN210Ifc _clk <- vMkClockN210(clk);
   return(_clk);
endmodule
