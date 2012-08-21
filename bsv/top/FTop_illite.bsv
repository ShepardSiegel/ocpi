// FTop_illite.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop              ::*;
import PCIE              ::*;
import PCIEwrap          ::*;
import TimeService       ::*;

import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import TieOff            ::*;
import XilinxCells       ::*;

interface FTop_illiteIfc;
  interface PCIE_EXP#(8)          pcie;
  interface Clock                 p125clk;
  interface Reset                 p125rst;
  (*always_ready*) method Bit#(3) led;
  interface GPSIfc                gps;
endinterface: FTop_illiteIfc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_illite#(Clock sys0_clkp, Clock sys0_clkn, Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(FTop_illiteIfc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(8)  pciw       <- mkPCIEwrap("V5",pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain

  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst  <- mkAsyncReset(1, p125Rst, sys0_clk);

  CTop4BIfc        ctop  <- mkCTop4B(pciw.device, sys0_clk, sys0_rst, clocked_by p125Clk, reset_by p125Rst);
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)
   
  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  interface PCIE_EXP pcie    = pciw.pcie;
  interface Clock    p125clk = p125Clk;
  interface Reset    p125rst = p125Rst;
  method    Bit#(3)  led     = ~{infLed, pack(pciw.linkUp)}; //leds are on when active-low
  interface GPSIfc   gps     = ctop.gps;

endmodule: mkFTop_illite
