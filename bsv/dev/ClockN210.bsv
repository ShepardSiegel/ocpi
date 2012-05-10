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
  interface Clock clk0; 
endinterface: ClockN210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkClockN210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Reset fpga_rstn)
                    (ClockN210Ifc);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn); 
  Reset            sys0_rst   <- mkAsyncReset(2, fpga_rstn , sys0_clk);

  DCMParams dcmp = defaultValue;
    dcmp.factory_jf  = 16'h8080;
    dcmp.phase_shift = 0;
  DCM              dcm         <- mkDCM(dcmp, sys0_clk, sys0_clk, clocked_by sys0_clk, reset_by sys0_rst);
  Clock            bufg_clk0   <- mkClockBUFG(clocked_by dcm.clkout0 );
  ReadOnly#(Bool)  clkfb       <- mkClockBitBUFG(clocked_by dcm.clkout0);

  (* fire_when_enabled, no_implicit_conditions *)
  rule connect_wires;
    dcm.fbin(clkfb);
  endrule

  interface Clock clk0 = bufg_clk0;
endmodule: mkClockN210
