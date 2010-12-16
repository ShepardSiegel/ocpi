// FTopV5_gbe.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop       ::*;
import GbeWorker  ::*;
import Ethernet   ::*;
import OCWip      ::*;
import Config     ::*;
import TimeService::*;

import Vector            ::*;
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
  interface GMII   gmii;    // The GMII link
  interface Reset  mrst_n;  // GMII associated Reset
  interface Clock  rxclk;   // GMII assocaited Clock
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn,
               Clock sys1_clkp, Clock sys1_clkn, Clock gmii_rx_clk,
               Clock pci0_clkp, Clock pci0_clkn) (FTopIfc);
  Clock            pci0_clk  <- mkClockIBUFDS(pci0_clkp, pci0_clkn);
  Reset            pci0_rst  <- mkResetIBUF;
  PCIExpress#(8)   pci0      <- mkPCIExpressEndpoint(?,clocked_by pci0_clk, reset_by pci0_rst);
  Clock            trn_clk   =  pci0.trn.clk;
  Reset            trn_rst   <- mkAsyncReset(1, pci0.trn.reset_n, trn_clk);
  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst  <- mkAsyncReset(1, pci0.trn.reset_n, sys0_clk);
  Clock            sys1_clk  <- mkClockIBUFDS(sys1_clkp, sys1_clkn);
  Reset            sys1_rst  <- mkAsyncReset(1, pci0.trn.reset_n, sys1_clk);
  Bool             pciLinkUp =  pci0.trn.link_up;
  MakeResetIfc     pciLinkUpResetGen <-mkReset(1,True,trn_clk, clocked_by trn_clk, reset_by trn_rst);
  rule plr (!pciLinkUp); pciLinkUpResetGen.assertReset; endrule
  Reset            pciLinkReset = pciLinkUpResetGen.new_rst;
  PciId            pciDevice =  PciId { bus  : pci0.cfg.bus_number,
                                        dev  : pci0.cfg.device_number,
                                        func : pci0.cfg.function_number};

  InterruptControl pcie_irq       <- mkInterruptController(trn_clk, trn_rst, clocked_by trn_clk, reset_by trn_rst);

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,                          clocked_by trn_clk, reset_by trn_rst);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,                          clocked_by trn_clk, reset_by trn_rst);
  CTop4BIfc              ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn_clk, reset_by trn_rst);
   
  mkConnection(pci0.trn_rx, toPut(fP2I)); 
  mkConnection(toGet(fI2P), pci0.trn_tx); 
  mkConnection(toGet(fP2I), ctop.server.request,    clocked_by trn_clk, reset_by trn_rst); 
  mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst); 

  mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  // WCI...
  Vector#(Nwci_ftop,Wci_m#(20)) vWci = ctop.wci_m;
  GbeWorkerIfc    gbe0       <-  mkGbeWorker(gmii_rx_clk, sys1_clk, sys1_rst, clocked_by trn_clk, reset_by(vWci[0].mReset_n));
  WciSlaveNullIfc#(20) to12  <-  mkWciSlaveNull;
  mkConnection(vWci[0], gbe0.wci_rx);
  mkConnection(vWci[1], gbe0.wci_tx);
  mkConnection(vWci[2], to12.slv);

  // WTI...
  TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst); 
  mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  mkConnection(tcGbe0.wti_m, gbe0.wti_s); 

  // WSI...
  mkConnection(gbe0.wsiM0, ctop.wsi_s_adc);  // The WSI from gbe0-RX  to CTOP/APP
  mkConnection(ctop.wsi_m_dac, gbe0.wsiS0);  // The WSI from CTOP/APP to gbe0-TX

  // Interfaces and Methods provided...
  interface pcie     = pci0.pcie;
  method    led      = ~{infLed, pack(pciLinkUp)}; //leds are on when active-low
  interface gps      = ctop.gps;
  interface trnClk   = trn_clk;
  interface gmii     = gbe0.gmii;
  interface mrst_n   = gbe0.mrst_n;
  interface rxclk    = gbe0.rxclk;
  //interface adx    = adcW10.adx;
endmodule: mkFTop
