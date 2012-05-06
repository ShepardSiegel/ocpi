// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
//import Config            ::*;
//import CPDefs            ::*;
//import CTop              ::*;
//import FlashWorker       ::*;

import MDIO              ::*;
import GMAC              ::*;
import GbeLite           ::*;

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
import Gray              ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;

/* USRP2 N210 Front-Panel LED Encoding
| A(4)tx   | B(1)mimo |
| C(3)rx   | D(0)firm |
| E(2)ref  | F(-)cpld |
*/


(* always_ready, always_enabled *)
interface FTop_n210Ifc;
  method     Bit#(5)    led;
  method     Bit#(32)   debug;
  interface  Clock      rxclkBnd;   // GMII RX Clock (provided here for BSV interface rules)
  interface  Reset      gmii_rstn;  // GMII Reset driven out to PHY
  interface  GMII_RS    gmii;       // The GMII link RX/TX
  interface  MDIO_Pads  mdio;       // The MDIO pads
  interface  Reset      sysRst;
endinterface: FTop_n210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_n210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Clock gmii_sysclk,                 // 125 MHz from GbE PHY
                    Clock gmii_rx_clk,                 // 125 MHz GMII RX Clock recovered
                    Reset fpga_rstn)
                    (FTop_n210Ifc);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn);     // sys0: 100 MHz Clock and Reset (from clock gen)
  Reset            sys0_rst   <- mkAsyncReset(2, fpga_rstn , sys0_clk);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by gmii_sysclk);     // sys1: 125 MHz Clock and Reset (from Enet PHY)
  Reset            sys1_rst   <- mkAsyncReset(2, fpga_rstn , sys1_clk);

  Reg#(Bit#(32))   freeCnt    <- mkReg(0,    clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)       doInit     <- mkReg(True, clocked_by sys0_clk, reset_by sys0_rst);

  GbeLiteIfc       gbe0       <- mkGbeLite(False, gmii_rx_clk, sys1_clk, sys1_rst, clocked_by sys1_clk, reset_by sys1_rst);

  rule inc_freeCnt;
    freeCnt <= freeCnt + 1;
    if (freeCnt>32'h0800_0000) doInit <= False;
  endrule

  function Bit#(5) initBlink (Bit#(32) cnt);
    Bool gateBit = unpack(cnt[22]);
    case (cnt[26:24])
      0, 1, 2, 6, 7 : return~(gateBit ? 5'h1C : 5'h00);
      3 : return~(5'h04);
      4 : return~(5'h0C);
      5 : return~(5'h1C);
    endcase
  endfunction

  function Bit#(5) ledStatus (Bit#(32) cnt);
    Bool gateBit = unpack(cnt[24]);
    return~(gateBit ? 5'h01 : 5'h00);
  endfunction

  method    Bit#(5)    led    = doInit ? initBlink(freeCnt) : ledStatus(freeCnt);
  method    Bit#(32)   debug  = {pack(grayEncode(pack(freeCnt)[15:0])), 16'h0000};
  interface Clock      rxclkBnd  = gbe0.rxclkBnd;
  interface Reset      gmii_rstn = gbe0.gmii_rstn;
  interface GMII       gmii      = gbe0.gmii;
  interface MDIO_Pads  mdio      = gbe0.mdio;
  interface Reset sysRst = sys0_rst;
endmodule: mkFTop_n210

