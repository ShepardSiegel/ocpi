// FTop_schist.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import CTop         ::*;
import DramServer_v5::*;
import AD9512       ::*;
import TI6149       ::*;
import ADCWorker    ::*;
import DACWorker    ::*;
import Max19692     ::*;
import OCWip        ::*;
import Config       ::*;
import WsiAdapter   ::*;
import TimeService  ::*;
import PCIEwrap     ::*;

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

interface FTop_schistIfc;
  interface PCIE_EXP#(8) pcie;
  (* always_ready *) method Bit#(3) led;
  interface P_Max19692Ifc dac0;                 // DAC0 Maxim-19692
  (* prefix = "" *) interface AD9512Ifc  adx;   // AD AD9512 Clock Driver
  interface Ads6149Ifc adc0;                    // TI ADS6149 ADC0
  interface Ads6149Ifc adc1;                    // TI ADS6149 ADC1
  interface GPSIfc     gps;                     // GPS Interface
  interface DDR2_32    dram;                    // DDR2 32b DRAM 
  interface Clock      trnClk; 
endinterface: FTop_schistIfc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_schist#(Clock sys0_clkp, Clock sys0_clkn,  // 200 MHz Reference
                     Clock sys1_clkp, Clock sys1_clkn,  // 300 MHz Reference
                     Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn,  // PCIe clock
                     Clock dac_clkp,  Clock dac_clkn, 
                     Clock adc_clkp,  Clock adc_clkn,
                     Clock adc0_clkp, Clock adc0_clkn,
                     Clock adc1_clkp, Clock adc1_clkn)(FTop_schistIfc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(8)  pciw       <- mkPCIEwrap("V5",pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  Clock            sys0_clk  <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst  <- mkAsyncReset(1, p125Rst, sys0_clk);
  Clock            sys1_clk  <- mkClockIBUFDS(sys1_clkp, sys1_clkn);
  Reset            sys1_rst  <- mkAsyncReset(1, p125Rst, sys1_clk);

  CTop4BIfc        ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk, reset_by p125Rst);
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)
   
  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  // ADC Clocks...
  Clock           adc_clk   <- mkClockIBUFDS(adc_clkp,  adc_clkn);
  Clock           adc0_clk  <- mkClockIBUFDS(adc0_clkp, adc0_clkn);
  Clock           adc1_clk  <- mkClockIBUFDS(adc1_clkp, adc1_clkn);
  Reset           adcRst    <- mkAsyncReset(1, p125Rst, adc_clk);
  Reset           adc0Rst   <- mkAsyncReset(1, p125Rst, adc0_clk);
  Reset           adc1Rst   <- mkAsyncReset(1, p125Rst, adc1_clk);
  // DAC Clocks...
  Clock           dac_clk   <- mkClockIBUFDS(dac_clkp, dac_clkn);
  Reset           dac_rst   <- mkAsyncReset(1, p125Rst, dac_clk);

  Vector#(Nwci_ftop,WciEM) vWci = ctop.wci_m;

  //TODO: Way of using well-known names instead of array index for reset, etc, on vWci[]

  // FTop Level board-specific workers..
  ADCWorkerIfc     adcW10  <-  mkADCWorker(   sys0_clk, sys0_rst, adc_clk, adc0_clk, adc1_clk, adc0Rst,  clocked_by p125Clk, reset_by(vWci[2].mReset_n));
  DACWorkerIfc     dacW11  <-  mkDACWorker(                       dac_clk,                     dac_rst,  clocked_by p125Clk, reset_by(vWci[3].mReset_n));
  DramServer_v5Ifc dram0   <-  mkDramServer_v5(sys0_clk, sys0_rst, sys1_clk, sys1_rst,                   clocked_by p125Clk, reset_by(vWci[4].mReset_n));

  // WCI...
  WciSlaveNullIfc#(32) tieOff0  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff1  <- mkWciSlaveNull;
  mkConnection(vWci[0], tieOff0.slv);   // worker 8
  mkConnection(vWci[1], tieOff1.slv);   // worker 9
  mkConnection(vWci[2], adcW10.wciS0);  // worker 10  
  mkConnection(vWci[3], dacW11.wciS0);  // worker 11   
  mkConnection(vWci[4], dram0.wciS0);   // worker 12 

  // WTI...
  TimeClientIfc  tcW10  <- mkTimeClient(sys0_clk, sys0_rst, adcW10.adcSdrClk, adcW10.adcSdrRst); // ADC Time Client
  TimeClientIfc  tcW11  <- mkTimeClient(sys0_clk, sys0_rst, dac_clk,  dac_rst);                  // DAC Time Client
  mkConnection(ctop.cpNow, tcW10.gpsTime);  // ADC Infrastructure Server/Client Connection
  mkConnection(ctop.cpNow, tcW11.gpsTime);  // DAC Infrastructure Server/Client Connection
  mkConnection(tcW10.wti_m, adcW10.wtiS0);  // Time Client WTI-M -> WTI-S ADC
  mkConnection(tcW11.wti_m, dacW11.wtiS0);  // Time Client WTI-M -> WTI-S DAC

  // WSI...
  //WsiAdapter4B16BIfc adapt416 <- mkWsiAdapter4B16B( clocked_by p125Clk, reset_by p125Rst);
  //mkConnection(adcW10.wsiM0,   adapt416.wsi_s);  // The WSI from ADCW10   to CTOP/APP
  //mkConnection(adapt416.wsi_m, ctop.wsi_s_adc);
  mkConnection(adcW10.wsiM0, ctop.wsi_s_adc);

  //WsiAdapter16B4BIfc adapt164 <- mkWsiAdapter16B4B( clocked_by p125Clk, reset_by p125Rst);
  //mkConnection(ctop.wsi_m_dac, adapt164.wsi_s);   // The WSI from CTOP/APP to DACW11
  //mkConnection(adapt164.wsi_m, dacW11.wsiS0);
  mkConnection(ctop.wsi_m_dac, dacW11.wsiS0);

  // Wmemi...
  mkConnection(ctop.wmemiM0, dram0.wmemiS0);

  // Interfaces and Methods provided...
  interface pcie   = pciw.pcie;
  method    led    = ~{infLed, pack(pciw.linkUp)}; //leds are on when active-low
  interface gps    = ctop.gps;
  interface dram   = dram0.dram;
  interface adx    = adcW10.adx;
  interface adc0   = adcW10.adc0;
  interface adc1   = adcW10.adc1;
  interface dac0   = dacW11.dac0;
  interface trnClk = p125Clk;
endmodule: mkFTop_schist
