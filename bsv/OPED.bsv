// OPED.bsv - OpenCPI PCIe Endpoint w/ DMA
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

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

interface OPEDIfc;
  interface PCIE_EXP#(8)             pcie;
  (* always_ready *) method Bit#(32) debug;
  interface Clock                    trnClk; 
endinterface: OPEDIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pcie_reset_n" *)
module mkOPED#(Clock pcie_clk_p, Clock pcie_clk_n)(OPEDIfc);
  Clock            pci_clk   <- mkClockIBUFDS(pcie_clk_p, pcie_clk_n);
  Reset            pci_rst   <- mkResetIBUF;
  PCIExpress#(8)   pci       <- mkPCIExpressEndpoint(?,clocked_by pci_clk, reset_by pci_rst);
  Clock            trn_clk   =  pci.trn.clk;
  Reset            trn_rst_n <- mkAsyncReset(1, pci.trn.reset_n, trn_clk);
  Bool             pciLinkUp =  pci.trn.link_up;
  MakeResetIfc     pciLinkUpResetGen <-mkReset(1,True,trn_clk, clocked_by trn_clk, reset_by trn_rst_n);
  rule plr (!pciLinkUp); pciLinkUpResetGen.assertReset; endrule
  Reset            pciLinkReset = pciLinkUpResetGen.new_rst;

  PciId            pciDevice =  PciId { bus  : pci.cfg.bus_number,
                                        dev  : pci.cfg.device_number,
                                        func : pci.cfg.function_number};

  InterruptControl pci_irq       <- mkInterruptController(trn_clk, trn_rst_n,
                                    clocked_by trn_clk, reset_by trn_rst_n);

  mkConnection(pci.cfg_irq, pci_irq.pcie_irq);
  mkTieOff(pci.cfg); mkTieOff(pci.cfg_err);

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst_n);
  mkConnection(pci.trn_rx, toPut(fP2I));  // Adapt 8B PCIe to 16B uNoC
  mkConnection(toGet(fI2P), pci.trn_tx);  // Adapt 16B uNoC to 8B PCIe

  //CTop4BIfc              ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn_clk, reset_by trn_rst_n);
  //mkConnection(toGet(fP2I), ctop.server.request,    clocked_by trn_clk, reset_by trn_rst_n); 
  //mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst_n); 

  //TODO: Place infrastucure IP here!


  interface pcie    = pci.pcie;
  method    debug   = extend(pack(pciLinkUp));
  interface trnClk  = trn_clk;
endmodule: mkOPED
