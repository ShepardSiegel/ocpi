// LedTop.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import Clocks            ::*;
import Connectable       ::*;
import GetPut            ::*;
import FIFO              ::*;
import DefaultValue      ::*;
import TieOff            ::*;
import XilinxCells       ::*;
import PCIE              ::*;
import PCIEInterrupt     ::*;
import ClientServer      ::*;

interface LedTopIfc;
  (* always_ready *)
  method Bit#(8) led;
endinterface: LedTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="sys_reset_n" *)
module mkLedTop#(Clock sys_clk_p, Clock sys_clk_n)(LedTopIfc);
  Reset          sys_rst_n_buf  <- mkResetIBUF;
  Clock          sys_clk_buf    <- mkClockIBUFDS(sys_clk_p, sys_clk_n);
  Reg#(Bit#(32)) freeCount      <- mkReg(0, clocked_by sys_clk_buf, reset_by sys_rst_n_buf);

  rule count;
    freeCount <= freeCount + 1;
  endrule

  ReadOnly#(Bit#(8)) infLed <- mkNullCrossingWire(noClock, freeCount[31:24]);

  method    led     = ~{infLed}; //leds are on when active-low

endmodule: mkLedTop

