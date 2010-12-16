// FTopV5.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop              ::*;
import Max19692::*;

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
  (* always_ready *) method Bool ppsOut; 
  (* always_ready, always_enabled *) method Action ppsExtIn (Bit#(1) x);
  interface Clock trnClk;  // to allow ppsExtIn to enter the synchronzier in the interface method
  interface Max19692Ifc dac0;
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn, Clock pci0_clkp, Clock pci0_clkn, Clock dac_clkp, Clock dac_clkn)(FTopIfc);
  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Clock            pci0_clk  <- mkClockIBUFDS(pci0_clkp, pci0_clkn);
  Reset            pci0_rst  <- mkResetIBUF;
  PCIExpress#(8)   pci0      <- mkPCIExpressEndpoint(?,clocked_by pci0_clk, reset_by pci0_rst);
  Clock            trn_clk   =  pci0.trn.clk;
  Reset            trn_rst_n <- mkAsyncReset(1, pci0.trn.reset_n, trn_clk);
  Bool             pciLinkUp =  pci0.trn.link_up;
  MakeResetIfc     pciLinkUpResetGen <-mkReset(1,True,trn_clk, clocked_by trn_clk, reset_by trn_rst_n);
  rule plr (!pciLinkUp); pciLinkUpResetGen.assertReset; endrule
  Reset            pciLinkReset = pciLinkUpResetGen.new_rst;

  PciId            pciDevice =  PciId { bus  : pci0.cfg.bus_number,
                                        dev  : pci0.cfg.device_number,
                                        func : pci0.cfg.function_number};

  InterruptControl pcie_irq       <- mkInterruptController(trn_clk, trn_rst_n,
                                     clocked_by trn_clk, reset_by trn_rst_n);

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,      clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,      clocked_by trn_clk, reset_by trn_rst_n);
  CTop4BIfc              ctop  <- mkCTop4B(pciDevice, clocked_by trn_clk, reset_by trn_rst_n);
   
  mkConnection(pci0.trn_rx, toPut(fP2I)); 
  mkConnection(toGet(fI2P), pci0.trn_tx); 
  mkConnection(toGet(fP2I), ctop.server.request,    clocked_by trn_clk, reset_by trn_rst_n); 
  mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst_n); 

  mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);
  ReadOnly#(Bool)    ppsOutdrv <- mkNullCrossingWire(noClock, ctop.ppsOut);

  SyncBitIfc#(Bit#(1)) ppsExtInSync <- mkSyncBit(trn_clk,trn_rst_n,trn_clk);
  Reg#(Bool)           ppsDFF       <- mkReg(False, clocked_by trn_clk, reset_by trn_rst_n);
  rule ppsDFFCapture; ppsDFF <= unpack(ppsExtInSync.read); endrule
  Bool ppsEdge    = (unpack(ppsExtInSync.read) != ppsDFF);
  Bool ppsRising  = (ppsEdge && !ppsDFF);
  Bool ppsFalling = (ppsEdge &&  ppsDFF);
  rule ppsRises (ppsRising); ctop.ppsExtIn; endrule

  Clock           dac_clk   <- mkClockIBUFDS(dac_clkp, dac_clkn);
  Reset           dac_rst   <- mkAsyncReset(3, pciLinkReset, dac_clk);
  Max19692Ifc     dac       <- mkMax19692(clocked_by dac_clk, reset_by dac_rst);

  interface pcie     = pci0.pcie;
  method    led      = ~{infLed, pack(pciLinkUp)}; //leds are on when active-low
  method    ppsOut   = ppsOutdrv;
  method Action ppsExtIn (Bit#(1) x) = ppsExtInSync.send(x);
  interface trnClk = trn_clk;
  interface dac0 = dac;
endmodule: mkFTop

