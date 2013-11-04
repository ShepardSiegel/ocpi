// FTop_ml605.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CPDefs            ::*;
import CTop              ::*;
import DramServer_v6     ::*;
import GMAC              ::*;
import MDIO              ::*;
import FlashWorker       ::*;
import FMC150            ::*;
import GbeWorker         ::*;
import ICAPWorker        ::*;
import OCWip             ::*;
import SPICore32         ::*;
import SPICore5          ::*;
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

interface FTop_ml605Ifc;
  interface PCIE_EXP#(4)           pcie;
  interface Clock                  p125clk;
  interface Reset                  p125rst;
  (*always_ready*) method Bit#(13) led;
  interface LCD                    lcd;
  interface GPSIfc                 gps;
  interface DDR3_64                dram;
  interface FLASH_IO#(24,16)       flash;
  interface Clock                  rxclkBnd;   // GMII RX Clock (provided here for BSV interface rules)
  interface Reset                  gmii_rstn;  // GMII Reset driven out to PHY
  interface GMII_RS                gmii;       // The GMII link RX/TX
  interface MDIO_Pads              mdio;       // The MDIO pads
  interface SPI32Pads              flpCDC;
  interface SPI5Pads               flpDAC;
endinterface: FTop_ml605Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_ml605#(Clock sys0_clkp,     Clock sys0_clkn,      // 200 MHz Board XO Reference
                     Clock sys1_clkp,     Clock sys1_clkn,      // 125 MHz Ethernet XO Reference
                     Clock flp_cdc_clk_p, Clock flp_cdc_clk_n,  // From FMC-150 CDCE72010 on FMC-LPC
                     Clock gmii_rx_clk,                         // 125 MHz GMII RX Clock from Marvell Phy
                     Clock pci0_clkp,     Clock pci0_clkn,      // 100 MHz PCIe Reference from Edge Connector
                     Reset pci0_rstn)(FTop_ml605Ifc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(4)  pciw       <- mkPCIEwrap("V6", pci0_clkp, pci0_clkn, pci0_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn); // Non-PCIe clocks and resets used...
  Reset            sys0_rst   <- mkAsyncReset(1, p125Rst , sys0_clk);
  Clock            sys1_clki  <- mkClockIBUFDS_GTXE1(True, sys1_clkp, sys1_clkn);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by sys1_clki);
  Reset            sys1_rst   <- mkAsyncReset(1, p125Rst , sys1_clk);

  Clock            flp_clk    <- mkClockIBUFDS(flp_cdc_clk_p,flp_cdc_clk_n);
  Reset            flp_rst    <- mkAsyncReset(1, p125Rst , flp_clk);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  LCDController    lcd_ctrl   <- mkLCDController(clocked_by p125Clk, reset_by p125Rst);
  Reg#(Bool)       needs_init <- mkReg(True,     clocked_by p125Clk, reset_by p125Rst);
  Reg#(UInt#(32))  freeCnt    <- mkReg(0,        clocked_by p125Clk, reset_by p125Rst);

  rule inc_freecnt; freeCnt <= freeCnt + 1; endrule

  // Poly approach...
  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
  // Static approach..
`ifdef USE_NDW1
  CTop4BIfc ctop  <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW2
  CTop8BIfc ctop  <- mkCTop8B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW4
  CTop16BIfc ctop <- mkCTop16B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW8
  CTop32BIfc ctop <- mkCTop32B(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
`endif
   
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);
  ReadOnly#(Bit#(1)) blinkLed  <- mkNullCrossingWire(noClock, pack(freeCnt)[25]);

  Vector#(Nwci_ftop, WciEM) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level board-specific workers..
//ICAPWorkerIfc    icap   <- mkICAPWorker("V6",True,                           clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  //FMC150Ifc        fmc150 <- mkFMC150(True,sys0_clk,sys0_rst,flp_clk,flp_rst,  clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  FMC150Ifc        fmc150 <- mkFMC150(True,                  flp_clk,flp_rst,  clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  FlashWorkerIfc   flash0 <- mkFlashWorker(True,                               clocked_by p125Clk , reset_by(vWci[1].mReset_n));
  GbeWorkerIfc     gbe0   <- mkGbeWorker(True,gmii_rx_clk, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by(vWci[2].mReset_n));
  WSICaptureWorker4BIfc cap0  <- mkWSICaptureWorker4B(True,                    clocked_by p125Clk , reset_by(vWci[3].mReset_n));
  DramServer_v6Ifc dram0  <- mkDramServer_v6(True,  sys0_clk, sys0_rst,        clocked_by p125Clk , reset_by(vWci[4].mReset_n));

  //WciMonitorIfc            wciMonW8         <- mkWciMonitor(8'h42, clocked_by p125Clk , reset_by p125Rst ); // monId=h42
  //PMEMMonitorIfc           pmemMonW8        <- mkPMEMMonitor(      clocked_by p125Clk , reset_by p125Rst );
  //mkConnection(wciMonW8.pmem, pmemMonW8.pmem, clocked_by p125Clk , reset_by p125Rst );  // Connect the wciMon to an event monitor
  
  // WCI...
//mkConnection(vWci[0], icap.wciS0);     // worker 8
//mkConnectionMSO(vWci[0],  icap.wciS0, wciMonW8.observe, clocked_by p125Clk , reset_by p125Rst );
  mkConnection(vWci[0], fmc150.wciS0);   // worker 8
  mkConnection(vWci[1], flash0.wciS0);   // worker 9
  mkConnection(vWci[2], gbe0.wciS0);     // worker 10 
  mkConnection(vWci[3], cap0.wciS0);     // worker 11
  mkConnection(vWci[4], dram0.wciS0);    // worker 12


  mkConnection(gbe0.wsiM0, cap0.wsiS0);
  mkConnection(gbe0.cpClient, ctop.cpServer);

  // WTI...
  TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by p125Rst ); 
  mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  mkConnection(tcGbe0.wti_m, gbe0.wtiS0); 

  // Wmemi...
  mkConnection(ctop.wmemiM0, dram0.wmemiS0);

  rule init_lcd if (needs_init);  // Paint the 16x2 LCD...
     Vector#(16,Bit#(8))  text1 = lcdLine("  Atomic Rules  ");
     Vector#(16,Bit#(8))  text2 = lcdLine("OpenCPI : ml605 ");
     lcd_ctrl.setLine1(text1);
     lcd_ctrl.setLine2(text2);
     needs_init <= False;
   endrule

  // Interfaces and Methods provided...
  interface PCI_EXP  pcie    = pciw.pcie;
  interface Clock    p125clk = p125Clk;
  interface Reset    p125rst = p125Rst;
  method  led   =
    //{5'b10100, pack(blinkLed), 1'b0, pack(pmemMonW8.grab), pack(pmemMonW8.head), pack(pmemMonW8.body), infLed, pack(pciw.linkUp)}; //13 leds are on active high on ML605
    {5'b10100, pack(blinkLed), 1'b0, pack(dram0.isTrained), pack(dram0.isReset), pack(dram0.isInReset), infLed, pack(pciw.linkUp)}; //13 leds are on active high on ML605
  interface LCD        lcd       = lcd_ctrl.ifc;
  interface GPSIfc     gps       = ctop.gps;
  interface FLASH_IO   flash     = flash0.flash;
  interface DDR3_64    dram      = dram0.dram;
  interface Clock      rxclkBnd  = gbe0.rxclkBnd;
  interface Reset      gmii_rstn = gbe0.gmii_rstn;
  interface GMII       gmii      = gbe0.gmii;
  interface MDIO_Pads  mdio      = gbe0.mdio;
  interface SPI32Pads  flpCDC    = fmc150.padsCDC;
  interface SPI5Pads   flpDAC    = fmc150.padsDAC;
endmodule: mkFTop_ml605

