// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
//import Config            ::*;
//import CPDefs            ::*;
//import CTop              ::*;
//import GMAC              ::*;
//import MDIO              ::*;
//import FlashWorker       ::*;
//import GbeWorker         ::*;
//import ICAPWorker        ::*;
//import OCWip             ::*;
//import SPICore32         ::*;
//import SPICore5          ::*;
//import TimeService       ::*;
//import WSICaptureWorker  ::*;
//import WsiAdapter        ::*;
//import XilinxExtra       ::*;
//import ProtocolMonitor   ::*;

// BSV Imports...
import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;


(* always_ready, always_enabled *)
interface FTop_n210Ifc;
  method Bit#(5)   led;
  method Bit#(16)  debug;
  interface Reset  sysRst;
endinterface: FTop_n210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_n210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Reset fpga_rstn)
                    (FTop_n210Ifc);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst   <- mkAsyncReset(2, fpga_rstn , sys0_clk);
  Reg#(UInt#(32))  freeCnt    <- mkReg(0, clocked_by sys0_clk, reset_by sys0_rst);

  rule inc_freecnt; freeCnt <= freeCnt + 1; endrule

  method Bit#(5)  led    = pack(freeCnt)[31:27];
  method Bit#(16) debug  = pack(freeCnt)[15:0];
  interface Reset sysRst = sys0_rst;
endmodule: mkFTop_n210

