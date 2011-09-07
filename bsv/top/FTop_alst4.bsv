// FTop_alst4.bsv
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CTop              ::*;
import DramServer_s4     ::*;
import FlashWorker       ::*;
import OCWip             ::*;
import TimeService       ::*;
import WsiAdapter        ::*;
import ProtocolMonitor   ::*;
import PCIEwrap          ::*;
import TLPMF             ::*;

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

(* always_ready, always_enabled *)
interface FTop_altst4Ifc;
  interface PCIE_EXP_ALT#(4) pcie;
  interface Clock            p125clk;
  interface Reset            p125rst;
  method Action              usr_sw  (Bit#(8) i);
  method Bit#(16)            led;
  method Action              hsmc_in (Bit#(16) i);
  method Bit#(16)            hsmc_out;
  method Bit#(20)            led_cathode;
  method Bit#(20)            led_anode;
  interface LCD              lcd;
  interface GPSIfc           gps;
  interface FLASH_IO#(24,16) flash;
  interface DDR3_16          dram;
endinterface: FTop_altst4Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_alst4#(Clock sys0_clk, Reset sys0_rstn, Clock pcie_clk, Reset pcie_rstn)(FTop_altst4Ifc);

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapAIfc#(4) pciw       <- mkPCIEwrapA("A4", sys0_clk, sys0_rstn, pcie_clk, pcie_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);
  Reg#(Bit#(16))   hsmcReg    <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  // debug...
  Reg#(Bit#(8))    swReg      <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);
  Reg#(Bit#(32))   freeCnt    <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);
  Bit#(1) swParity = parity(swReg);
  rule freeCount; freeCnt <= freeCnt + 1; endrule

  LCDController    lcd_ctrl   <- mkLCDController(clocked_by p125Clk, reset_by p125Rst);
  Reg#(Bool)       needs_init <- mkReg(True,     clocked_by p125Clk, reset_by p125Rst);

`ifdef USE_NDW1
  CTop4BIfc  ctop <- mkCTop4B(pciDevice,  sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW4
  CTop16BIfc ctop <- mkCTop16B(pciDevice, sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`endif
   
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)

  Vector#(Nwci_ftop, WciEM) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level device-workers..
  FlashWorkerIfc   flash0   <- mkFlashWorker(                       clocked_by p125Clk, reset_by(vWci[1].mReset_n));
  DramServer_s4Ifc dram0    <- mkDramServer_s4(sys0_clk, sys0_rstn, clocked_by p125Clk, reset_by(vWci[4].mReset_n));

  // WCI...
  //mkConnection(vWci[0], icap.wciS0);    // worker 8
  //mkConnectionMSO(vWci[0],  icap.wciS0, wciMonW8.observe, clocked_by p125Clk , reset_by p125Rst );
  mkConnection(vWci[1], flash0.wciS0);   // worker 9
  //mkConnection(vWci[2], gbe0.wciS0);     // worker 10 
  //mkConnection(vWci[3], gbe0.wciS1);     // worker 11
  mkConnection(vWci[4], dram0.wciS0);    // worker 12

  // WTI...
  //TimeClientIfc  tcGbe0  <- mkTimeClient(sys0_clk, sys0_rst, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by p125Rst ); 
  //mkConnection(ctop.cpNow, tcGbe0.gpsTime); 
  //mkConnection(tcGbe0.wti_m, gbe0.wtiS0); 

  // Wmemi...
  mkConnection(ctop.wmemiM0, dram0.wmemiS0);


  rule init_lcd if (needs_init);  // Paint the 16x2 LCD...
     Vector#(16,Bit#(8))  text1 = lcdLine("  Atomic Rules  ");
     Vector#(16,Bit#(8))  text2 = lcdLine("OpenCPI : alst4 ");
     lcd_ctrl.setLine1(text1);
     lcd_ctrl.setLine2(text2);
     needs_init <= False;
  endrule

  Reg#(Bit#(16)) ledReg <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);
  rule assign_led;
    ledReg <= ~{8'h42, swParity, pack(pciw.dbgBool), pack(pciw.alive), pack(pciw.linkUp), freeCnt[29:26]};
  endrule

  // Interfaces and Methods provided...
  interface PCI_EXP_ALT  pcie    = pciw.pcie;
  interface Clock        p125clk = p125Clk;
  interface Reset        p125rst = p125Rst;
  method Action usr_sw (Bit#(8) i);
    swReg <= i;
  endmethod
  method led = ledReg;
  method Action hsmc_in (Bit#(16) i);
    hsmcReg <= i;
  endmethod
  method hsmc_out = hsmcReg;
  method led_cathode = '0;
  method led_anode   =  {4'h8, ledReg};
  interface LCD          lcd   = lcd_ctrl.ifc;
  interface GPSIfc       gps   = ctop.gps;
  interface FLASH_IO     flash = flash0.flash;
  interface DDR3_16      dram  = dram0.dram;
endmodule: mkFTop_alst4
