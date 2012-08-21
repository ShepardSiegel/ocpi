// FTop_kc705.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CTop              ::*;
import DramServer_k7     ::*;
import GMAC              ::*;
import MDIO              ::*;
import FlashWorker       ::*;
import GbeWorker         ::*;
import ICAPWorker        ::*;
import OCWip             ::*;
import TimeService       ::*;
import WSICaptureWorker  ::*;
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
import LCDController     ::*;
import TieOff            ::*;
import PCIE              ::*;
import PCIEInterrupt     ::*;
import Vector            ::*;
import XilinxCells       ::*;

interface FTop_kc705Ifc;
  interface PCIE_EXP#(4)          pcie;
  interface Clock                 p125clk;
  interface Reset                 p125rst;
  method Action                   usr_sw (Bit#(8) i);
  (*always_ready*) method Bit#(8) led;
  interface LCD                   lcd;
  method Bit#(16)                 debug;
//interface GPSIfc                gps;
//interface FLASH_IO#(24,16)      flash;
  interface Clock                  rxclk;      // GMII RX Clock (provided here for BSV interface rules)
  interface Reset                  gmii_rstn;  // GMII Reset driven out to PHY
  interface GMII_RS                gmii;       // The GMII link RX/TX
  interface MDIO_Pads              mdio;       // The MDIO pads
endinterface: FTop_kc705Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_kc705#(Clock sys0_clkp, Clock sys0_clkn, Reset sys0_rstn,
                     Clock sys1_clkp, Clock sys1_clkn,  // 125 MHz Ethernet XO Reference
                     Clock gmii_rx_clk,                 // 125 MHz GMII RX Clock from Marvell Phy
                     Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)
    (FTop_kc705Ifc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(4)  pciw       <- mkPCIEwrap("X7", pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn); // Non-PCIe clocks and resets used...
  Reset            sys0_rst   <- mkAsyncReset(16, sys0_rstn , sys0_clk);
  IDELAYCTRL       idc        <- vMkMYIDELAYCTRL(1, clocked_by sys0_clk, reset_by sys0_rst); // Needed by GMII/GMAC when *not* instanced by DDR3/MIG
  Clock            sys1_clki  <- mkClockIBUFDS_GTE2(True, sys1_clkp, sys1_clkn);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by sys1_clki);
  Reset            sys1_rst   <- mkAsyncReset(1, p125Rst , sys1_clk);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  LCDController      lcd_ctrl   <- mkLCDController(clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)         needs_init <- mkReg(True,     clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(UInt#(32))    freeCnt    <- mkReg(0,        clocked_by p125Clk,  reset_by p125Rst);

  rule inc_freecnt; freeCnt <= freeCnt + 1; endrule

  // Poly approach...
  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
  // Static approach..
`ifdef USE_NDW1
  CTop4BIfc ctop <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW4
  CTop16BIfc ctop <- mkCTop16B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`endif
   
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)
 

  ReadOnly#(Bit#(2)) infLed      <- mkNullCrossingWire(noClock, ctop.led);
  ReadOnly#(Bit#(1)) blinkLed    <- mkNullCrossingWire(noClock, pack(freeCnt)[25]);

  Vector#(Nwci_ftop, WciEM) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level board-specific workers..
  //ICAPWorkerIfc    icap     <- mkICAPWorker("X7",True,                      clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  //FlashWorkerIfc   flash0   <- mkFlashWorker(True,                          clocked_by p125Clk , reset_by(vWci[1].mReset_n));
  GbeWorkerIfc     gbe0   <- mkGbeWorker(True,gmii_rx_clk, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by(vWci[2].mReset_n));
  WSICaptureWorker4BIfc cap0  <- mkWSICaptureWorker(True,                      clocked_by p125Clk , reset_by(vWci[3].mReset_n));
  //DramServer_k7Ifc dram0    <- mkDramServer_k7(True, sys0_clk, sys0_rst,          clocked_by p125Clk , reset_by(vWci[4].mReset_n));

  //WciMonitorIfc            wciMonW8         <- mkWciMonitor(8'h42, clocked_by p125Clk , reset_by p125Rst ); // monId=h42
  //PMEMMonitorIfc           pmemMonW8        <- mkPMEMMonitor(      clocked_by p125Clk , reset_by p125Rst );
  //mkConnection(wciMonW8.pmem, pmemMonW8.pmem, clocked_by p125Clk , reset_by p125Rst );  // Connect the wciMon to an event monitor
  
  // WCI...
  //mkConnection(vWci[0], icap.wciS0);    // worker 8
  //mkConnectionMSO(vWci[0],  icap.wciS0, wciMonW8.observe, clocked_by p125Clk , reset_by p125Rst );
  //mkConnection(vWci[1], flash0.wciS0);   // worker 9
  mkConnection(vWci[2], gbe0.wciS0);     // worker 10 
  mkConnection(vWci[3], cap0.wciS0);     // worker 11
  //mkConnection(vWci[4], dram0.wciS0);    // worker 12

  mkConnection(gbe0.wsiM0, cap0.wsiS0);

  // WTI...
  //TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by p125Rst ); 
  //mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  //mkConnection(tcGbe0.wti_m, gbe0.wtiS0); 

  // Wmemi...
  //mkConnection(ctop.wmemiM0, dram0.wmemiS0);

  rule init_lcd if (needs_init);  // Paint the 16x2 LCD...
     Vector#(16,Bit#(8))  text1 = lcdLine("  Atomic Rules  ");
     Vector#(16,Bit#(8))  text2 = lcdLine("OpenCPI : kc705 ");
     lcd_ctrl.setLine1(text1);
     lcd_ctrl.setLine2(text2);
     needs_init <= False;
   endrule

  // Interfaces and Methods provided...
  interface PCI_EXP  pcie    = pciw.pcie;
  interface Clock    p125clk = p125Clk;
  interface Reset    p125rst = p125Rst;
  method             debug   = pack(freeCnt)[31:16];
  method  led   = {pack(blinkLed), 4'b0000, infLed, pack(pciw.linkUp)}; //8 leds are on active high on KC705
  interface LCD      lcd     = lcd_ctrl.ifc;
  //interface GPSIfc   gps     = ctop.gps;
  //interface FLASH_IO flash   = flash0.flash;
  interface Clock      rxclk     = gbe0.rxclk;
  interface Reset      gmii_rstn = gbe0.gmii_rstn;
  interface GMII       gmii      = gbe0.gmii;
  interface MDIO_Pads  mdio      = gbe0.mdio;
endmodule: mkFTop_kc705

