// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import ClockN210         ::*;
import Config            ::*;
import OCCP              ::*;

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
  interface  Clock      sys0Clk;
  interface  Reset      sys0Rst;
  interface  Clock      sys125Clk;
  interface  Reset      sys125Rst;
endinterface: FTop_n210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_n210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Clock gmii_sysclk,                 // 125 MHz from GbE PHY - stable clock, once enabled after reset
                    Clock gmii_rx_clk,                 // 125 MHz GMII RX Clock - agile recovered rx clock, when 1Gb link up
                    Reset fpga_rstn)                   // FPGA User Reset Pushbutton S2
                    (FTop_n210Ifc);

  Clock            clkIn      <- mkClockIBUFDS(sys0_clkp, sys0_clkn);     // sys0: 100 MHz Clock and Reset (from clock gen)
  ClockN210Ifc     clkN210    <- mkClockN210(clkIn, fpga_rstn);
  Clock            sys0_clk   = clkN210.clk0;
  Reset            sys0_rst   = clkN210.rst0;
  Clock            sys2_clk   = clkN210.clk2x;
  Reset            sys2_rst   = clkN210.rst2x;
  Clock            sysdv_clk  = clkN210.clkdv;
  Reset            sysdv_rst  = clkN210.rstdv;
  Clock            sys125_clk = clkN210.clk125;
  Reset            sys125_rst = clkN210.rst125;

  Clock            gmiixo_clk <- mkClockBUFG(clocked_by gmii_sysclk);
  Reset            gmiixo_rst <- mkAsyncReset(2, sys0_rst, gmiixo_clk);

  Reg#(Bit#(32))   freeCnt    <- mkReg(0,    clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)       doInit     <- mkReg(True, clocked_by sys0_clk, reset_by sys0_rst);

  GbeLiteIfc       gbe0       <- mkGbeLite(False, gmii_rx_clk, gmiixo_clk, gmiixo_rst, sys0_clk, sys0_rst, clocked_by sys125_clk, reset_by sys125_rst);
  OCCPIfc#(Nwcit)  cp         <- mkOCCP(?, sys2_clk, sys2_rst, clocked_by sys0_clk, reset_by sys0_rst);
  mkConnection(gbe0.cpClient, cp.server);

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
  interface Clock      rxclkBnd   = gbe0.rxclkBnd;
  interface Reset      gmii_rstn  = gbe0.gmii_rstn;
  interface GMII       gmii       = gbe0.gmii;
  interface MDIO_Pads  mdio       = gbe0.mdio;
  interface Clock      sys0Clk    = sys0_clk;
  interface Reset      sys0Rst    = sys0_rst;
  interface Clock      sys125Clk  = sys125_clk;
  interface Reset      sys125Rst  = sys125_rst;
endmodule: mkFTop_n210

