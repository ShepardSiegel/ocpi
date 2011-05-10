// FTop_alst4.bsv
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CTop              ::*;
import OCWip             ::*;
import WsiAdapter        ::*;
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

(* always_ready, always_enabled *)
interface FTop_altst4Ifc;
  interface PCIE_EXP_ALT#(4) pcie;
  interface Clock            p125clk;
  interface Reset            p125rst;
  method Action              usr_sw (Bit#(8) i);
  method Bit#(16)            led;
endinterface: FTop_altst4Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_alst4#(Clock sys0_clk, Reset sys0_rstn, Clock pcie_clk, Reset pcie_rstn)(FTop_altst4Ifc);

  Clock            sys0Clk    =  sys0_clk;
  Reset            sys0Rst    =  sys0_rstn;
  Reg#(Bit#(8))    swReg      <- mkReg(0, clocked_by sys0Clk, reset_by sys0Rst);
  Reg#(Bit#(32))   freeCnt    <- mkReg(0, clocked_by sys0Clk, reset_by sys0Rst);

  Bit#(1) swParity = parity(swReg);

  rule freeCount;
    freeCnt <= freeCnt + 1;
  endrule

  PCIE_S4GX#(4) pciw <- mkPCIExpressEndpointS4GX(sys0_clk, sys0_rstn, pcie_clk, pcie_rstn);
  Clock            p125Clk    =  pciw.ava.clk;      // Nominal 125 MHz clock domain
  Reset            p125Rst    =  pciw.ava.usr_rst;  // Reset for p125 domain

  SyncBitIfc#(Bit#(1)) aliveLed_sb  <- mkSyncBit(p125Clk, p125Rst, sys0Clk);
  SyncBitIfc#(Bit#(1)) linkLed_sb   <- mkSyncBit(p125Clk, p125Rst, sys0Clk);

  rule assign_alive; aliveLed_sb.send(pack(pciw.ava.alive)); endrule
  rule assign_link;  linkLed_sb.send(pack(pciw.ava.lnk_up)); endrule




  /*
  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapIfc#(4)  pciw       <- mkPCIEwrap("A4", pcie_clk, pcie_clk, pcie_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  // Poly approach...
  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by p125Clk , reset_by p125Rst );
  // Static approach..
`ifdef USE_NDW1
  CTop4BIfc ctop <- mkCTop4B(pciDevice, sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW4
  CTop16BIfc ctop <- mkCTop16B(pciDevice, sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`endif
   
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  Vector#(Nwci_ftop, WciEM) vWci = ctop.wci_m;  // expose WCI from CTop

  // FTop Level board-specific workers..
  //ICAPWorkerIfc    icap     <- mkICAPWorker(True,True,                      clocked_by p125Clk , reset_by(vWci[0].mReset_n));
  //FlashWorkerIfc   flash0   <- mkFlashWorker(                               clocked_by p125Clk , reset_by(vWci[1].mReset_n));
  //GbeWorkerIfc     gbe0     <- mkGbeWorker(gmii_rx_clk, sys1_clk, sys1_rst, clocked_by p125Clk , reset_by(vWci[2].mReset_n));
  //DramServer_v6Ifc dram0    <- mkDramServer_v6(sys0_clk, sys0_rst,          clocked_by p125Clk , reset_by(vWci[4].mReset_n));

  WciMonitorIfc            wciMonW8         <- mkWciMonitor(8'h42, clocked_by p125Clk , reset_by p125Rst ); // monId=h42
  PMEMMonitorIfc           pmemMonW8        <- mkPMEMMonitor(      clocked_by p125Clk , reset_by p125Rst );
  mkConnection(wciMonW8.pmem, pmemMonW8.pmem, clocked_by p125Clk , reset_by p125Rst );  // Connect the wciMon to an event monitor
  
  // WCI...
  //mkConnection(vWci[0], icap.wciS0);    // worker 8
  //mkConnectionMSO(vWci[0],  icap.wciS0, wciMonW8.observe, clocked_by p125Clk , reset_by p125Rst );

  */

  // Interfaces and Methods provided...
  interface PCI_EXP_ALT  pcie    = pciw.pcie;
  interface Clock        p125clk = p125Clk;
  interface Reset        p125rst = p125Rst;
  method Action usr_sw (Bit#(8) i);
    swReg <= i;
  endmethod
  method  led   =
    //{8'h42, 2'b11, pack(pmemMonW8.grab), pack(pmemMonW8.head), pack(pmemMonW8.body), infLed, pack(pciw.linkUp)}; //16 leds are on active low alts4gx
    {8'h42, ~swParity, swParity, aliveLed_sb.read, linkLed_sb.read, freeCnt[29:26]};
endmodule: mkFTop_alst4
