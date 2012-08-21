// FTop_sp605.bsv
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop              ::*;
import TimeService       ::*;
import PCIEwrap          ::*;

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

interface FTop_sp605Ifc;
  interface PCIE_EXP#(8) pcie;
  (* always_ready *) method Bit#(3) led;
  interface GPSIfc gps;
  interface Clock  trnClk; 
endinterface: FTop_sp605Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_sp605#(Clock sys0_clkp, Clock sys0_clkn, Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(FTop_sp605Ifc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(4)  pciw       <- mkPCIEwrap("S6",pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);

  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst  <- mkAsyncReset(1, pci0.trn.reset_n, sys0_clk);
  CTop4BIfc              ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn_clk, reset_by trn_rst_n);
  mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst_n); 

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  interface pcie     = pci0.pcie;
  method    led      = ~{infLed, pack(pciLinkUp)}; //leds are on when active-low
  interface gps    = ctop.gps;
  interface trnClk = trn_clk;
endmodule: mkFTop_sp605

