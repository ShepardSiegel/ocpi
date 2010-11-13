// FTopV5_adc.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop        ::*;
import DramServerV5::*;
import AD9512      ::*;
import TI6149      ::*;
import ADCWorker   ::*;
import DACWorker   ::*;
import Max19692    ::*;
import OCWip       ::*;
import Config      ::*;
import WsiAdapter  ::*;
import TimeService ::*;

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
  interface P_Max19692Ifc dac0;                 // DAC0 Maxim-19692
  (* prefix = "" *) interface AD9512Ifc  adx;   // AD AD9512 Clock Driver
  interface Ads6149Ifc adc0;                    // TI ADS6149 ADC0
  interface Ads6149Ifc adc1;                    // TI ADS6149 ADC1
  interface GPSIfc     gps;                     // GPS Interface
  interface DDR2_32    dram;                    // DDR2 32b DRAM 
  interface Clock      trnClk; 
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn,  // 200 MHz Reference
               Clock sys1_clkp, Clock sys1_clkn,  // 300 MHz Reference
               Clock pci0_clkp, Clock pci0_clkn,  // PCIe clock
               Clock dac_clkp,  Clock dac_clkn, 
               Clock adc_clkp,  Clock adc_clkn,
               Clock adc0_clkp, Clock adc0_clkn,
               Clock adc1_clkp, Clock adc1_clkn)(FTopIfc);
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

  FIFO#(TLPData#(8))     fP2I  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst);
  FIFO#(TLPData#(8))     fI2P  <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst);
  CTop4BIfc              ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn_clk, reset_by trn_rst);
   
  mkConnection(pci0.trn_rx, toPut(fP2I)); 
  mkConnection(toGet(fI2P), pci0.trn_tx); 
  mkConnection(toGet(fP2I), ctop.server.request,    clocked_by trn_clk, reset_by trn_rst); 
  mkConnection(ctop.server.response, toPut(fI2P),   clocked_by trn_clk, reset_by trn_rst); 

  mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  // ADC Clocks...
  Clock           adc_clk   <- mkClockIBUFDS(adc_clkp,  adc_clkn);
  Clock           adc0_clk  <- mkClockIBUFDS(adc0_clkp, adc0_clkn);
  Clock           adc1_clk  <- mkClockIBUFDS(adc1_clkp, adc1_clkn);
  Reset           adc_rst   <- mkAsyncReset(1, pciLinkReset, adc_clk);
  Reset           adc0_rst  <- mkAsyncReset(1, pciLinkReset, adc0_clk);
  Reset           adc1_rst  <- mkAsyncReset(1, pciLinkReset, adc1_clk);
  // DAC Clocks...
  Clock           dac_clk   <- mkClockIBUFDS(dac_clkp, dac_clkn);
  Reset           dac_rst   <- mkAsyncReset(1, pciLinkReset, dac_clk);

  Vector#(Nwci_ftop,Wci_Em#(20)) vWci = ctop.wci_m;

  //TODO: Way of using well-known names instead of array index for reset, etc, on vWci[]

  // FTop Level board-specific workers..
  ADCWorkerIfc     adcW10  <-  mkADCWorker(   sys0_clk, sys0_rst, adc_clk, adc0_clk, adc1_clk, adc0_rst, clocked_by trn_clk, reset_by(vWci[2].mReset_n));
  DACWorkerIfc     dacW11  <-  mkDACWorker(                       dac_clk,                     dac_rst,  clocked_by trn_clk, reset_by(vWci[3].mReset_n));
  DramServerV5Ifc  dram0   <-  mkDramServerV5(sys0_clk, sys0_rst, sys1_clk, sys1_rst,                    clocked_by trn_clk, reset_by(vWci[4].mReset_n));

  // WCI...
  WciSlaveNullIfc#(20) tieOff0  <- mkWciSlaveNull;
  WciSlaveNullIfc#(20) tieOff1  <- mkWciSlaveNull;
  mkConnection(vWci[0], tieOff0.slv);   // worker 8
  mkConnection(vWci[1], tieOff1.slv);   // worker 9
  mkConnection(vWci[2], adcW10.wci_s);  // worker 10  
  mkConnection(vWci[3], dacW11.wci_s);  // worker 11   
  mkConnection(vWci[4], dram0.wci_s);   // worker 12 

  // WTI...
  TimeClientIfc  tcW10  <- mkTimeClient(sys0_clk, sys0_rst, adcW10.adcSdrClk, adcW10.adcSdrRst); // ADC Time Client
  TimeClientIfc  tcW11  <- mkTimeClient(sys0_clk, sys0_rst, dac_clk,  dac_rst);                  // DAC Time Client
  mkConnection(ctop.cpNow, tcW10.gpsTime);  // ADC Infrastructure Server/Client Connection
  mkConnection(ctop.cpNow, tcW11.gpsTime);  // DAC Infrastructure Server/Client Connection
  mkConnection(tcW10.wti_m, adcW10.wti_s);  // Time Client WTI-M -> WTI-S ADC
  mkConnection(tcW11.wti_m, dacW11.wti_s);  // Time Client WTI-M -> WTI-S DAC

  // WSI...
  //WsiAdapter4B16BIfc adapt416 <- mkWsiAdapter4B16B( clocked_by trn_clk, reset_by trn_rst);
  //mkConnection(adcW10.wsiM0,   adapt416.wsi_s);  // The WSI from ADCW10   to CTOP/APP
  //mkConnection(adapt416.wsi_m, ctop.wsi_s_adc);
  mkConnection(adcW10.wsiM0, ctop.wsi_s_adc);

  //WsiAdapter16B4BIfc adapt164 <- mkWsiAdapter16B4B( clocked_by trn_clk, reset_by trn_rst);
  //mkConnection(ctop.wsi_m_dac, adapt164.wsi_s);   // The WSI from CTOP/APP to DACW11
  //mkConnection(adapt164.wsi_m, dacW11.wsiS0);
  mkConnection(ctop.wsi_m_dac, dacW11.wsiS0);

  // Wmemi...
  mkConnection(ctop.wmemiM, dram0.wmemiS);

  // Interfaces and Methods provided...
  interface pcie   = pci0.pcie;
  method    led    = ~{infLed, pack(pciLinkUp)}; //leds are on when active-low
  interface gps    = ctop.gps;
  interface dram   = dram0.dram;
  interface adx    = adcW10.adx;
  interface adc0   = adcW10.adc0;
  interface adc1   = adcW10.adc1;
  interface dac0   = dacW11.dac0;
  interface trnClk = trn_clk;
endmodule: mkFTop
