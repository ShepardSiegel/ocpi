// FTopV6.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CTop              ::*;
import DramServer        ::*;
import Ethernet          ::*;
import FlashWorker       ::*;
import GbeWorker         ::*;
import ICAPWorker        ::*;
import OCWip             ::*;
import TimeService       ::*;
import WsiAdapter        ::*;
import XilinxExtra       ::*;
import ProtocolMonitor   ::*;
import PCIEwrap          ::*;

// BSV Imports...
import AlignedFIFOs_eco  ::*;
import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import TieOff            ::*;
import PCIE              ::*;
import PCIEInterrupt     ::*;
import Vector            ::*;
import XilinxCells       ::*;

interface FTopIfc;
  interface PCIE_EXP#(4)           pcie;
  (*always_ready*) method Bit#(13) led;
  interface GPSIfc                 gps;
  interface DDR3_64                dram;
  interface FLASH_IO#(24,16)       flash;
  interface Clock                  trn2Clk;
  interface GMII                   gmii;     // The GMII link
  interface Reset                  mrst_n;   // GMII associated Reset
  interface Clock                  rxclk;    // GMII assocaited Clock
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn,
               Clock sys1_clkp, Clock sys1_clkn, Clock gmii_rx_clk,
               Clock pci0_clkp, Clock pci0_clkn)(FTopIfc);

  PCIEwrapIfc      pci        <- mkPCIEwrapV6(pci0_clkp, pci0_clkn);  // Instance the wrapped, technology-specific PCIE core
  Clock            trn2_clk   =  pci.pClk; // Nominal 125 MHz
  Reset            trn2_rst   =  pci.pRst; // Reset for pClk domain

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn); // Non-PCIe clocks and resets used...
  Reset            sys0_rst   <- mkAsyncReset(1, trn2_rst, sys0_clk);
  Clock            sys1_clki  <- mkClockIBUFDS_GTXE1(True, sys1_clkp, sys1_clkn);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by sys1_clki);
  Reset            sys1_rst   <- mkAsyncReset(1, trn2_rst, sys1_clk);

  // Poly approach...
  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by trn2_clk, reset_by trn2_rst);
  // Static approach..
  CTop4BIfc ctop <- mkCTop4B(pci.device, sys0_clk, sys0_rst, clocked_by trn2_clk, reset_by trn2_rst);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  Vector#(Nwci_ftop,WciOcp_Em#(20)) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level board-specific workers..
  ICAPWorkerIfc    icap     <- mkICAPWorker(True,True,                      clocked_by trn2_clk, reset_by(vWci[0].mReset_n));
  FlashWorkerIfc   flash0   <- mkFlashWorker(                               clocked_by trn2_clk, reset_by(vWci[1].mReset_n));
  GbeWorkerIfc     gbe0     <- mkGbeWorker(gmii_rx_clk, sys1_clk, sys1_rst, clocked_by trn2_clk, reset_by(vWci[2].mReset_n));
  DramServerIfc    dram0    <- mkDramServer(sys0_clk, sys0_rst,             clocked_by trn2_clk, reset_by(vWci[4].mReset_n));

  WciOcpMonitorIfc            wciMonW8         <- mkWciOcpMonitor(8'h42, clocked_by trn2_clk, reset_by trn2_rst); // monId=h42
  PMEMMonitorWsiIfc           pmemMonW8        <- mkPMEMMonitorWsi(      clocked_by trn2_clk, reset_by trn2_rst);
  mkConnection(wciMonW8.pmem, pmemMonW8.pmem, clocked_by trn2_clk, reset_by trn2_rst);  // Connect the wciMon to an event monitor
  
  WciOcp_Es#(NwciAddr) icapwci_Es <- mkWciOcpStoES(icap.wci_s, clocked_by trn2_clk, reset_by trn2_rst);

  // WCI...
  //mkConnection(vWci[0], icap.wci_s);    // worker 8
  mkConnectionMSO(vWci[0],  icapwci_Es, wciMonW8.observe, clocked_by trn2_clk, reset_by trn2_rst);
  mkConnection(vWci[1], flash0.wci_s);  // worker 9
  mkConnection(vWci[2], gbe0.wci_rx);   // worker 10 
  mkConnection(vWci[3], gbe0.wci_tx);   // worker 11
  mkConnection(vWci[4], dram0.wci_s);   // worker 12

  // WTI...
  TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst, clocked_by trn2_clk, reset_by trn2_rst); 
  mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  mkConnection(tcGbe0.wti_m, gbe0.wti_s); 

  // Wmemi...
  mkConnection(ctop.wmemiM, dram0.wmemiS);

  // Interfaces and Methods provided...
  interface pcie     = pci.pcie;
  method    led      = {7'b1010000, pack(pmemMonW8.grab), pack(pmemMonW8.head), pack(pmemMonW8.body), infLed, pack(pci.linkUp)}; //13 leds are on active high on ML605
  interface gps      = ctop.gps;
  interface flash    = flash0.flash;
  interface dram     = dram0.dram;
  interface trn2Clk  = trn2_clk;
  interface gmii     = gbe0.gmii;
  interface mrst_n   = gbe0.mrst_n;
  interface rxclk    = gbe0.rxclk;
endmodule: mkFTop

