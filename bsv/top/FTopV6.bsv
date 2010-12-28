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
  interface Clock                  p125clk;
  interface Reset                  p125rst;
  (*always_ready*) method Bit#(13) led;
  interface GPSIfc                 gps;
  interface DDR3_64                dram;
  interface FLASH_IO#(24,16)       flash;
  interface Clock                  rxclk;    // GMII assocaited Clock
  interface Reset                  mrst_n;   // GMII associated Reset
  interface GMII                   gmii;     // The GMII link
endinterface: FTopIfc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn,
               Clock sys1_clkp, Clock sys1_clkn, Clock gmii_rx_clk,
               Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(FTopIfc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(4)  pciw       <- mkPCIEwrap("V6",pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn); // Non-PCIe clocks and resets used...
  Reset            sys0_rst   <- mkAsyncReset(1, p125Rst , sys0_clk);
  Clock            sys1_clki  <- mkClockIBUFDS_GTXE1(True, sys1_clkp, sys1_clkn);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by sys1_clki);
  Reset            sys1_rst   <- mkAsyncReset(1, p125Rst , sys1_clk);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  // Poly approach...
  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
  // Static approach..
  CTop4BIfc ctop <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  Vector#(Nwci_ftop,Wci_Em#(20)) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level board-specific workers..
  ICAPWorkerIfc    icap     <- mkICAPWorker(True,True,                      clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  FlashWorkerIfc   flash0   <- mkFlashWorker(                               clocked_by p125Clk , reset_by(vWci[1].mReset_n));
  GbeWorkerIfc     gbe0     <- mkGbeWorker(gmii_rx_clk, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by(vWci[2].mReset_n));
  DramServerIfc    dram0    <- mkDramServer(sys0_clk, sys0_rst,             clocked_by p125Clk , reset_by(vWci[4].mReset_n));

  WciMonitorIfc            wciMonW8         <- mkWciMonitor(8'h42, clocked_by p125Clk , reset_by p125Rst ); // monId=h42
  PMEMMonitorWsiIfc           pmemMonW8        <- mkPMEMMonitorWsi(      clocked_by p125Clk , reset_by p125Rst );
  mkConnection(wciMonW8.pmem, pmemMonW8.pmem, clocked_by p125Clk , reset_by p125Rst );  // Connect the wciMon to an event monitor
  
  Wci_Es#(NwciAddr) icapwci_Es <- mkWciStoES(icap.wci_s, clocked_by p125Clk , reset_by p125Rst );

  // WCI...
  //mkConnection(vWci[0], icap.wci_s);    // worker 8
  mkConnectionMSO(vWci[0],  icapwci_Es, wciMonW8.observe, clocked_by p125Clk , reset_by p125Rst );
  mkConnection(vWci[1], flash0.wci_s);  // worker 9
  mkConnection(vWci[2], gbe0.wci_rx);   // worker 10 
  mkConnection(vWci[3], gbe0.wci_tx);   // worker 11
  mkConnection(vWci[4], dram0.wci_s);   // worker 12

  // WTI...
  TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by p125Rst ); 
  mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  mkConnection(tcGbe0.wti_m, gbe0.wti_s); 

  // Wmemi...
  mkConnection(ctop.wmemiM, dram0.wmemiS);

  // Interfaces and Methods provided...
  interface PCI_EXP  pcie    = pciw.pcie;
  interface Clock    p125clk = p125Clk;
  interface Reset    p125rst = p125Rst;
  method  led   =
    {7'b1010000, pack(pmemMonW8.grab), pack(pmemMonW8.head), pack(pmemMonW8.body), infLed, pack(pciw.linkUp)}; //13 leds are on active high on ML605
  interface GPSIfc   gps     = ctop.gps;
  interface FLASH_IO flash   = flash0.flash;
  interface DDR3_64  dram    = dram0.dram;
  interface Clock    rxclk   = gbe0.rxclk;
  interface Reset    mrst_n  = gbe0.mrst_n;
  interface GMII     gmii    = gbe0.gmii;
endmodule: mkFTop

