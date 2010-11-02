// FTopV5.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop              ::*;
import TimeService       ::*;

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

interface FTopIfc;
  interface PCIE_EXP#(8) pcie;
  (* always_ready *) method Bit#(3) led;
  interface GPSIfc gps;
  interface Clock  trnClk; 
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn, Clock pci0_clkp, Clock pci0_clkn)(FTopIfc);
  Clock            pci0_clk  <- mkClockIBUFDS(pci0_clkp, pci0_clkn);
  Reset            pci0_rst  <- mkResetIBUF;
  PCIExpress#(8)   pci0      <- mkPCIExpressEndpoint(?,clocked_by pci0_clk, reset_by pci0_rst);
  Clock            trn_clk   =  pci0.trn.clk;
  Reset            trn_rst_n <- mkAsyncReset(1, pci0.trn.reset_n, trn_clk);
  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst  <- mkAsyncReset(1, pci0.trn.reset_n, sys0_clk);
  Bool             pciLinkUp =  pci0.trn.link_up;
  MakeResetIfc     pciLinkUpResetGen <-mkReset(1,True,trn_clk, clocked_by trn_clk, reset_by trn_rst_n);
  rule plr (!pciLinkUp); pciLinkUpResetGen.assertReset; endrule
  Reset            pciLinkReset = pciLinkUpResetGen.new_rst;

  PciId            pciDevice =  PciId { bus  : pci0.cfg.bus_number,
                                        dev  : pci0.cfg.device_number,
                                        func : pci0.cfg.function_number};

  InterruptControl pcie_irq       <- mkInterruptController(trn_clk, trn_rst_n,
                                     clocked_by trn_clk, reset_by trn_rst_n);

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);
  CTop4BIfc              ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn_clk, reset_by trn_rst_n);
   
  mkConnection(pci0.trn_rx, toPut(fP2I)); 
  mkConnection(toGet(fI2P), pci0.trn_tx); 
  mkConnection(toGet(fP2I), ctop.server.request,    clocked_by trn_clk, reset_by trn_rst_n); 
  mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst_n); 

  mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  interface pcie     = pci0.pcie;
  method    led      = ~{infLed, pack(pciLinkUp)}; //leds are on when active-low
  interface gps    = ctop.gps;
  interface trnClk = trn_clk;
endmodule: mkFTop

