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
  interface PCIE_EXP#(4) pcie;
  (* always_ready *) method Bit#(13)  led;
  interface GPSIfc           gps;
  interface DDR3_64          dram;
  interface FLASH_IO#(24,16) flash;
  interface Clock  trn2Clk;
  interface GMII   gmii;    // The GMII link
  interface Reset  mrst_n;  // GMII associated Reset
  interface Clock  rxclk;   // GMII assocaited Clock
endinterface: FTopIfc

(* synthesize, no_default_clock, clock_prefix="", reset_prefix="pci0_reset_n" *)
module mkFTop#(Clock sys0_clkp, Clock sys0_clkn,
               Clock sys1_clkp, Clock sys1_clkn, Clock gmii_rx_clk,
               Clock pci0_clkp, Clock pci0_clkn)(FTopIfc);
  Clock            pci0_clk   <- mkClockIBUFDS_GTXE1(True, pci0_clkp, pci0_clkn);
  Reset            pci0_rst   <- mkResetIBUF;
  PCIExpressV6#(4) pci0       <- mkPCIExpressEndpointV6(?,clocked_by pci0_clk,reset_by pci0_rst);
  Clock            trn_clk    =  pci0.trn.clk;  // 250 MHz
  Reset            trn_rst    <- mkAsyncReset(1, pci0.trn.reset_n, trn_clk);
  Clock            trn2_clk   =  pci0.trn.clk2; // 125 MHz
  Reset            trn2_rst   <- mkAsyncReset(1, pci0.trn.reset_n, trn2_clk);
  Clock            sys0_clk   <- mkClockIBUFDS(sys0_clkp, sys0_clkn);
  Reset            sys0_rst   <- mkAsyncReset(1, pci0.trn.reset_n, sys0_clk);
  Clock            sys1_clki  <- mkClockIBUFDS_GTXE1(True, sys1_clkp, sys1_clkn);
  Clock            sys1_clk   <- mkClockBUFG(clocked_by sys1_clki);
  Reset            sys1_rst   <- mkAsyncReset(1, pci0.trn.reset_n, sys1_clk);
  Bool             pciLinkUp  =  pci0.trn.link_up;
  PciId            pciDev     =  PciId { bus  : pci0.cfg.bus_number,
                                         dev  : pci0.cfg.device_number,
                                         func : pci0.cfg.function_number};
  Reg#(PciId)      pciDevice  <- mkSyncReg(unpack(0), trn_clk, trn_rst, trn2_clk);
  rule write_pciDevice; pciDevice <= pciDev; endrule  // 250 MHz side of pciDevice mkSyncReg

  InterruptControl pcie_irq   <- mkInterruptController(trn_clk, trn_rst, clocked_by trn_clk, reset_by trn_rst);

  ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(trn2_clk, clocked_by trn_clk, reset_by trn_rst);  //true when trn2 will rise on next edge

  Store#(UInt#(0),TLPData#(16),0) p2iS    <- mkRegStore(trn_clk, trn2_clk);
  AlignedFIFO#(TLPData#(16))      p2iAF   <- mkAlignedFIFO(trn_clk,trn_rst,trn2_clk,trn2_rst,p2iS,preEdge,True);
  Store#(UInt#(0),TLPData#(16),0) i2pS    <- mkRegStore(trn2_clk, trn_clk);
  AlignedFIFO#(TLPData#(16))      i2pAF   <- mkAlignedFIFO(trn2_clk,trn2_rst,trn_clk,trn_rst,i2pS,True,preEdge);
  FIFO#(TLPData#(8))              fP2I    <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst  );
  FIFO#(TLPData#(8))              fI2P    <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst  );

  //CTopIfc#(`DEFINE_NDW) ctop <- mkCTop(pciDevice, sys0_clk, sys0_rst, clocked_by trn2_clk, reset_by trn2_rst);
`define USE_NDW1
`ifdef USE_NDW1
  CTop4BIfc ctop <- mkCTop4B(pciDevice, sys0_clk, sys0_rst, clocked_by trn2_clk, reset_by trn2_rst);
`endif


  // Inbound  PCIe (8B@250MHz) -> CTOP (16B@125MHz)
  mkConnection(pci0.trn_rx,  toPut(fP2I),          clocked_by trn_clk,  reset_by trn_rst);  // 8B      250 MHz
  mkConnection(toGet(fP2I),  toPut(p2iAF),         clocked_by trn_clk,  reset_by trn_rst);  // 8B->16B 250 MHz
  mkConnection(toGet(p2iAF), ctop.server.request,  clocked_by trn2_clk, reset_by trn2_rst); // 16B     125 MHz

  // Outbound CTOP (16B@125MHz) -> PCIe (8B@250MHz)
  mkConnection(ctop.server.response, toPut(i2pAF), clocked_by trn2_clk, reset_by trn2_rst); // 16B     125 MHz
  mkConnection(toGet(i2pAF),          toPut(fI2P), clocked_by trn_clk,  reset_by trn_rst);  // 16B->8B 250 MHz
  mkConnection(toGet(fI2P), pci0.trn_tx,           clocked_by trn_clk,  reset_by trn_rst);  // 8B      250 MHz

  mkConnection(pci0.cfg_interrupt, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  ReadOnly#(Bit#(2)) infLed    <- mkNullCrossingWire(noClock, ctop.led);

  Vector#(Nwci_ftop,WciOcp_Em#(20)) vWci = ctop.wci_m;  // expose WCI from CTop


  // FTop Level board-specific workers..
  ICAPWorkerIfc    icap     <- mkICAPWorker(True,True,                      clocked_by trn2_clk, reset_by(vWci[0].mReset_n));
  FlashWorkerIfc   flash0   <- mkFlashWorker(                               clocked_by trn2_clk, reset_by(vWci[1].mReset_n));
  GbeWorkerIfc     gbe0     <- mkGbeWorker(gmii_rx_clk, sys1_clk, sys1_rst, clocked_by trn2_clk, reset_by(vWci[2].mReset_n));
  DramServerIfc    dram0    <- mkDramServer(sys0_clk, sys0_rst,             clocked_by trn2_clk, reset_by(vWci[4].mReset_n));

  WciOcpMonitorIfc            wciMonW8         <- mkWciOcpMonitor(8'h42, clocked_by trn2_clk, reset_by trn2_rst); // monId=h42
  PMEMMonitorIfc              pmemMonW8        <- mkPMEMMonitor(         clocked_by trn2_clk, reset_by trn2_rst);
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

  // WSI...
  //WsiAdapter4B16BIfc adapt416 <- mkWsiAdapter4B16B( clocked_by trn2_clk, reset_by trn2_rst);
  //mkConnection(gbe0.wsiM0,     adapt416.wsi_s);  // The WSI from gbe0-RX  to CTOP/APP
  //mkConnection(adapt416.wsi_m, ctop.wsi_s_adc);  // The WSI from gbe0-RX  to CTOP/APP
  //mkConnection(gbe0.wsiM0,     ctop.wsi_s_adc);

  //WsiAdapter16B4BIfc adapt164 <- mkWsiAdapter16B4B( clocked_by trn2_clk, reset_by trn2_rst);
  //mkConnection(ctop.wsi_m_dac, adapt164.wsi_s);  // The WSI from CTOP/APP to gbe0-TX
  //mkConnection(adapt164.wsi_m,     gbe0.wsi_s);  // The WSI from CTOP/APP to gbe0-TX
  //mkConnection(ctop.wsi_m_dac,     gbe0.wsiS0);  // The WSI from CTOP/APP to gbe0-TX

  // Wmemi...
  mkConnection(ctop.wmemiM, dram0.wmemiS);

  // Interfaces and Methods provided...
  interface pcie     = pci0.pcie;
  method    led      = {7'b1010000, pack(pmemMonW8.grab), pack(pmemMonW8.head), pack(pmemMonW8.body), infLed, pack(pciLinkUp)}; //13 leds are on active high on ML605
  interface gps      = ctop.gps;
  interface flash    = flash0.flash;
  interface dram     = dram0.dram;
  interface trn2Clk  = trn2_clk;
  interface gmii     = gbe0.gmii;
  interface mrst_n   = gbe0.mrst_n;
  interface rxclk    = gbe0.rxclk;
endmodule: mkFTop

