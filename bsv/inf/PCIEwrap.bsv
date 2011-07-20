// PCIEwrap.bsv - An abstraction level for PCIe to wrap technology-specific implementations
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIEwrap;

// Application Imports...
import TLPMF             ::*;
import XilinxExtra       ::*;

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

// The PCIEwrapIfc is expected to remain constant across a range of technology-specific implementations...
interface PCIEwrapIfc#(numeric type lanes);
  interface PCIE_EXP#(lanes)      pcie;    // fabric-facing PCIe SERDES signals
                                           // FPGA-user-facing interfaces...
  interface Clock                 pClk;    // PCIe-derived clock (nominally 125 MHz, regardless of PCIe core)
  interface Reset                 pRst;    // PCIe-derived reset (Reset in the domain of the above Clock)
  interface Client#(PTW16,PTW16)  client;  // The PCIe client - normally connected to infrastructure uNoC
  (* always_ready *) method Bool  linkUp;  // True when the pcie link is up
  (* always_ready *) method PciId device;  // PCIe device-id (16b bus/dev/fun 3-tuple)
endinterface: PCIEwrapIfc

// Altera variant is the same, except with a PCIE_EXP_ALT sub-interface...
interface PCIEwrapAIfc#(numeric type lanes);
  interface PCIE_EXP_ALT#(lanes)  pcie;    // fabric-facing PCIe SERDES signals
                                           // FPGA-user-facing interfaces...
  interface Clock                 pClk;    // PCIe-derived clock (nominally 125 MHz, regardless of PCIe core)
  interface Reset                 pRst;    // PCIe-derived reset (Reset in the domain of the above Clock)
  interface Client#(PTW16,PTW16)  client;  // The PCIe client - normally connected to infrastructure uNoC
  (* always_ready *) method Bool  alive;   // Pulsing when the core is alive
  (* always_ready *) method Bool  linkUp;  // True when the pcie link is up
  (* always_ready *) method Bool  dbgBool; // Collected OR of debug
  (* always_ready *) method PciId device;  // PCIe device-id (16b bus/dev/fun 3-tuple)
endinterface: PCIEwrapAIfc

// The PCIE wrapping instances are diverse implementations providing the same interface.
// Here we select which implementation from the family String...
module mkPCIEwrap#(String family, Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(PCIEwrapIfc#(lanes)) provisos(Add#(1,z,lanes));
  PCIEwrapIfc#(lanes) _a;
  case (family)
    "V5"    : _a  <- mkPCIEwrapV5(pci0_clkp, pci0_clkn, pci0_rstn);  // Virtex 5
    "V6"    : _a  <- mkPCIEwrapV6(pci0_clkp, pci0_clkn, pci0_rstn);  // Virtex 6
    "X6"    : _a  <- mkPCIEwrapX6(pci0_clkp, pci0_clkn, pci0_rstn);  // Virtex 6 with AXI Interface
 // "X7"    : _a  <- mkPCIEwrapX7(pci0_clkp, pci0_clkn, pci0_rstn);  // Xilinx Series 7 AXI (Artex, Kintex, Virtex)
    default : _a  <- mkPCIEwrapV5(pci0_clkp, pci0_clkn, pci0_rstn);
  endcase
  return _a;
endmodule

// The PCIE wrapping instances are diverse implementations providing the same interface.
// Here we select which implementation from the family String...
// The Altera variant is different as it requires a sys0 clk/rst to operate and can not live by PCIe clk/rst alone
module mkPCIEwrapA#(String family, Clock sys0_clk, Reset sys0_rstn, Clock pci0_clk, Reset pci0_rstn)(PCIEwrapAIfc#(lanes)) provisos(Add#(1,z,lanes), Add#(lanes,0,4));
  PCIEwrapAIfc#(lanes) _a;
  case (family)
    "A4"    : _a  <- mkPCIEwrapA4(sys0_clk, sys0_rstn, pci0_clk, pci0_rstn);
    default : _a  <- mkPCIEwrapA4(sys0_clk, sys0_rstn, pci0_clk, pci0_rstn);
  endcase
  return _a;
endmodule

//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapA4#(Clock sys0_clk, Reset sys0_rstn, Clock pci0_clk,  Reset pci0_rstn)(PCIEwrapAIfc#(lanes)) provisos(Add#(1,z,lanes), Add#(lanes,0,4));
  Clock            sys0Clk    =  sys0_clk;
  Reset            sys0Rst    =  sys0_rstn;
  PCIE_S4GX#(4) pci0 <- mkPCIExpressEndpointS4GX(sys0_clk, sys0_rstn, pci0_clk, pci0_rstn);
  Clock            p125Clk    =  pci0.ava.clk;      // Nominal 125 MHz clock domain
  Reset            p125Rst    =  pci0.ava.usr_rst;  // Reset for p125 domain

  SyncBitIfc#(Bit#(1)) aliveLed_sb  <- mkSyncBit(sys0Clk, sys0Rst, p125Clk);
  SyncBitIfc#(Bit#(1)) linkLed_sb   <- mkSyncBit(sys0Clk, sys0Rst, p125Clk);
  rule assign_alive; aliveLed_sb.send(pack(pci0.ava.alive)); endrule
  rule assign_link;  linkLed_sb.send(pack(pci0.ava.lnk_up)); endrule
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);
  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pci0.device; endrule


  //(* fire_when_enabled, no_implicit_conditions *) rule send_pciLinkup; pciLinkUp.send(pack(pLinkUp)); endrule 
  //(* fire_when_enabled *) rule capture_pciDevice; pciDevice <= pciDev;  endrule 

  //InterruptControl pcie_irq   <- mkInterruptController(p250clk, p250rst, clocked_by p250clk, reset_by p250rst);
  //ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(p125clk , clocked_by p250clk, reset_by p250rst);  //true when trn2 will rise on next edge

  FIFO#(TLPData#(16))      p2iF   <- mkFIFO(clocked_by p125Clk, reset_by p125Rst);
  FIFO#(TLPData#(16))      i2pF   <- mkFIFO(clocked_by p125Clk, reset_by p125Rst);

  // Inbound  PCIe (16B@125MHz) -> CTOP (16B@125MHz)...
  mkConnection(pci0.trn_rx,  toPut(p2iF));
  // Outbound CTOP (16B@125MHz) -> PCIe (16B@125MHz)...
  mkConnection(toGet(i2pF),  pci0.trn_tx);

  // TODO: Implement me when these interfaces are exposed
  //mkConnection(pci0.cfg_interrupt, pcie_irq.pcie_irq);
  //mkTieOff(pci0.cfg);
  //mkTieOff(pci0.cfg_err);

  // Interfaces and Methods provided...
  interface PCI_EXP_ALT pcie     = pci0.pcie;
  interface Clock       pClk     = p125Clk ;
  interface Reset       pRst     = p125Rst ;
  interface Client client;
    interface request  = toGet(p2iF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(i2pF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  alive   = unpack(aliveLed_sb.read);
  method Bool  dbgBool = unpack(parity(pci0.ava.debug));
  method Bool  linkUp  = unpack(linkLed_sb.read);
  method PciId device  = pciDevice;
endmodule: mkPCIEwrapA4

// This Xilinx X6 specifc implementation takes 8B/250MHz interface and converts it to 16B/125MHz...
//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapX6#(Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(PCIEwrapIfc#(lanes)) provisos(Add#(1,z,lanes));
  Clock                 pci0_clk    <- mkClockIBUFDS_GTXE1(True, pci0_clkp, pci0_clkn);
  //Reset                 pci0_rst    <- mkResetIBUF(clocked_by noClock, reset_by noReset);
  PCIExpressV6#(lanes)  pci0        <- mkPCIExpressEndpointX6(?,clocked_by pci0_clk,reset_by pci0_rstn);
  Clock                 p250clk     =  pci0.trn.clk;  // 250 MHz (the div/1 clock from the pcie core)
  Reset                 p250rst     <- mkAsyncReset(1, pci0.trn.reset_n, p250clk);
  Clock                 p125clk     =  pci0.trn.clk2; // 125 MHz (the div/2 clock from the pcie core)
  Reset                 p125rst     <- mkAsyncReset(1, pci0.trn.reset_n, p125clk );
                                      // Place LinkUp and pciDevice in p125clk domain
  Bool                  pLinkUp     =  pci0.trn.link_up;
  SyncBitIfc#(Bit#(1))  pciLinkUp   <- mkSyncBit(p250clk, p250rst, p125clk);  // single-bit synchronizer 250 to 125 MHz
  PciId                 pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
  Reg#(PciId)           pciDevice   <- mkSyncReg(unpack(0), p250clk, p250rst, p125clk); // multi-bit sync 250 to 125 MHz

  Reg#(UInt#(4))        dbpciCD          <- mkReg(4, clocked_by pci0_clk, reset_by pci0_rstn);
  Reg#(UInt#(4))        dbpciCE          <- mkReg(5, clocked_by p250clk,  reset_by p250rst);
  Reg#(UInt#(4))        dbpciCF          <- mkReg(6, clocked_by p125clk,  reset_by p125rst);  

  rule cnt_cd; dbpciCD <= dbpciCD + 1; endrule
  rule cnt_ce; dbpciCE <= dbpciCE + 1; endrule
  rule cnt_cf; dbpciCF <= dbpciCF + 1; endrule

  (* fire_when_enabled, no_implicit_conditions *) rule send_pciLinkup; pciLinkUp.send(pack(pLinkUp)); endrule 
  (* fire_when_enabled *) rule capture_pciDevice; pciDevice <= pciDev;  endrule 

  //InterruptControl pcie_irq   <- mkInterruptController(p250clk, p250rst, clocked_by p250clk, reset_by p250rst);
  ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(p125clk , clocked_by p250clk, reset_by p250rst);  //true when trn2 will rise on next edge

  Store#(UInt#(0),TLPData#(16),0) p2iS    <- mkRegStore(p250clk, p125clk );
  AlignedFIFO#(TLPData#(16))      p2iAF   <- mkAlignedFIFO(p250clk,p250rst,p125clk ,p125rst ,p2iS,preEdge,True);
  Store#(UInt#(0),TLPData#(16),0) i2pS    <- mkRegStore(p125clk , p250clk);
  AlignedFIFO#(TLPData#(16))      i2pAF   <- mkAlignedFIFO(p125clk ,p125rst ,p250clk,p250rst,i2pS,True,preEdge);
  FIFO#(TLPData#(8))              fP2I    <- mkSizedFIFO(4,    clocked_by p250clk, reset_by p250rst  );
  FIFO#(TLPData#(8))              fI2P    <- mkSizedFIFO(4,    clocked_by p250clk, reset_by p250rst  );

  // Inbound  PCIe (8B@250MHz) -> CTOP (16B@125MHz)...
  mkConnection(pci0.trn_rx,  toPut(fP2I),  clocked_by p250clk,  reset_by p250rst);  // 8B      250 MHz
  mkConnection(toGet(fP2I),  toPut(p2iAF), clocked_by p250clk,  reset_by p250rst);  // 8B->16B 250 MHz

  // Outbound CTOP (16B@125MHz) -> PCIe (8B@250MHz)...
  mkConnection(toGet(i2pAF), toPut(fI2P),  clocked_by p250clk,  reset_by p250rst);  // 16B->8B 250 MHz
  mkConnection(toGet(fI2P),  pci0.trn_tx,  clocked_by p250clk,  reset_by p250rst);  // 8B      250 MHz

  // TODO: Implement me when these interfaces are exposed
  //mkConnection(pci0.cfg_interrupt, pcie_irq.pcie_irq);
  //mkTieOff(pci0.cfg);
  //mkTieOff(pci0.cfg_err);

  // Interfaces and Methods provided...
  interface PCI_EXP pcie     = pci0.pcie;
  interface Clock   pClk     = p125clk ;
  interface Reset   pRst     = p125rst ;
  interface Client client;
    interface request  = toGet(p2iAF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(i2pAF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  linkUp = unpack(pciLinkUp.read);
  method PciId device = pciDevice;
endmodule: mkPCIEwrapX6



// This Xilinx V6 specifc implementation takes 8B/250MHz interface and converts it to 16B/125MHz...
//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapV6#(Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(PCIEwrapIfc#(lanes)) provisos(Add#(1,z,lanes));
  Clock                 pci0_clk    <- mkClockIBUFDS_GTXE1(True, pci0_clkp, pci0_clkn);
  //Reset                 pci0_rst    <- mkResetIBUF(clocked_by noClock, reset_by noReset);
  PCIExpressV6#(lanes)  pci0        <- mkPCIExpressEndpointV6(?,clocked_by pci0_clk,reset_by pci0_rstn);
  Clock                 p250clk     =  pci0.trn.clk;  // 250 MHz (the div/1 clock from the pcie core)
  Reset                 p250rst     <- mkAsyncReset(1, pci0.trn.reset_n, p250clk);
  Clock                 p125clk     =  pci0.trn.clk2; // 125 MHz (the div/2 clock from the pcie core)
  Reset                 p125rst     <- mkAsyncReset(1, pci0.trn.reset_n, p125clk );
                                      // Place LinkUp and pciDevice in p125clk domain
  Bool                  pLinkUp     =  pci0.trn.link_up;
  SyncBitIfc#(Bit#(1))  pciLinkUp   <- mkSyncBit(p250clk, p250rst, p125clk);  // single-bit synchronizer 250 to 125 MHz
  PciId                 pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
  Reg#(PciId)           pciDevice   <- mkSyncReg(unpack(0), p250clk, p250rst, p125clk); // multi-bit sync 250 to 125 MHz

  (* fire_when_enabled, no_implicit_conditions *) rule send_pciLinkup; pciLinkUp.send(pack(pLinkUp)); endrule 
  (* fire_when_enabled *) rule capture_pciDevice; pciDevice <= pciDev;  endrule 

  InterruptControl pcie_irq   <- mkInterruptController(p250clk, p250rst, clocked_by p250clk, reset_by p250rst);
  ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(p125clk , clocked_by p250clk, reset_by p250rst);  //true when trn2 will rise on next edge

  Store#(UInt#(0),TLPData#(16),0) p2iS    <- mkRegStore(p250clk, p125clk );
  AlignedFIFO#(TLPData#(16))      p2iAF   <- mkAlignedFIFO(p250clk,p250rst,p125clk ,p125rst ,p2iS,preEdge,True);
  Store#(UInt#(0),TLPData#(16),0) i2pS    <- mkRegStore(p125clk , p250clk);
  AlignedFIFO#(TLPData#(16))      i2pAF   <- mkAlignedFIFO(p125clk ,p125rst ,p250clk,p250rst,i2pS,True,preEdge);
  FIFO#(TLPData#(8))              fP2I    <- mkSizedFIFO(4,    clocked_by p250clk, reset_by p250rst  );
  FIFO#(TLPData#(8))              fI2P    <- mkSizedFIFO(4,    clocked_by p250clk, reset_by p250rst  );

  // Inbound  PCIe (8B@250MHz) -> CTOP (16B@125MHz)...
  mkConnection(pci0.trn_rx,  toPut(fP2I),  clocked_by p250clk,  reset_by p250rst);  // 8B      250 MHz
  mkConnection(toGet(fP2I),  toPut(p2iAF), clocked_by p250clk,  reset_by p250rst);  // 8B->16B 250 MHz

  // Outbound CTOP (16B@125MHz) -> PCIe (8B@250MHz)...
  mkConnection(toGet(i2pAF), toPut(fI2P),  clocked_by p250clk,  reset_by p250rst);  // 16B->8B 250 MHz
  mkConnection(toGet(fI2P),  pci0.trn_tx,  clocked_by p250clk,  reset_by p250rst);  // 8B      250 MHz

  mkConnection(pci0.cfg_interrupt, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  // Interfaces and Methods provided...
  interface PCI_EXP pcie     = pci0.pcie;
  interface Clock   pClk     = p125clk ;
  interface Reset   pRst     = p125rst ;
  interface Client client;
    interface request  = toGet(p2iAF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(i2pAF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  linkUp = unpack(pciLinkUp.read);
  method PciId device = pciDevice;
endmodule: mkPCIEwrapV6


// This Xilinx V5 specifc implementation takes 8B/125MHz interface and converts it to 16B/125MHz...
// This implemenation is IMBALANCED as the PCIe side is 1 GB/S to the uNoC side of 2 GB/S
//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapV5#(Clock pci0_clkp, Clock pci0_clkn, Reset pci0_rstn)(PCIEwrapIfc#(lanes)) provisos(Add#(1,z,lanes));
  Clock                 pci0_clk    <- mkClockIBUFDS(pci0_clkp, pci0_clkn);
  //Reset                 pci0_rst    <- mkResetIBUF(clocked_by noClock, reset_by noReset);
  PCIExpress#(lanes)    pci0        <- mkPCIExpressEndpoint(?,clocked_by pci0_clk,reset_by pci0_rstn);
  Clock                 p125clk     =  pci0.trn.clk; // 125 MHz as configured by coregen xco
  Reset                 p125rst     <- mkAsyncReset(1, pci0.trn.reset_n, p125clk );

  // This is the inner body of mkPCIEwrapV5 which enjoys having the default 125 MHz Clock and Reset applied...
  module mkPCIEwrapV5_inner (PCIEwrapIfc#(lanes)) provisos(Add#(1,z,lanes));
    InterruptControl      pcie_irq    <- mkInterruptController(p125clk, p125rst);
    FIFO#(TLPData#(16))   uP2IF       <- mkFIFO;
    FIFO#(TLPData#(16))   uI2PF       <- mkFIFO;
    Bool                  pLinkUp     =  pci0.trn.link_up;
    SyncBitIfc#(Bit#(1))  pciLinkUp   <- mkSyncBit(p125clk, p125rst, p125clk);  // single-bit synchronizer 125 to 125 MHz
    PciId                 pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
    Reg#(PciId)           pciDevice   <- mkSyncReg(unpack(0), p125clk, p125rst, p125clk); // multi-bit sync 125 to 125 MHz

    (* fire_when_enabled, no_implicit_conditions *) rule send_pciLinkup; pciLinkUp.send(pack(pLinkUp)); endrule 
    (* fire_when_enabled *) rule capture_pciDevice; pciDevice <= pciDev;  endrule 

    // Inbound  PCIe (8B@125MHz) -> CTOP (16B@125MHz)...
    mkConnection(pci0.trn_rx,  toPut(uP2IF));  // 8B->16B  (1:2 width conversion)
    // Outbound CTOP (16B@125MHz) -> PCIe (8B@125MHz)...
    mkConnection(toGet(uI2PF), pci0.trn_tx);   // 16B->8B  (2:1 width conversion)
  
    mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
    mkTieOff(pci0.cfg);
    mkTieOff(pci0.cfg_err);
  
    // Interfaces and Methods provided...
    interface PCI_EXP pcie   = pci0.pcie;
    interface Clock   pClk   = p125clk ;
    interface Reset   pRst   = p125rst ;
    interface Client  client;
      interface request  = toGet(uP2IF); // 16B-125MHz requests  towards uNoC infrastructre
      interface response = toPut(uI2PF); // 16B-125MHz responses towards PCIe fabric
    endinterface
    method Bool  linkUp = unpack(pciLinkUp.read);
    method PciId device = pciDevice;
  endmodule

  PCIEwrapIfc#(lanes) _b  <- mkPCIEwrapV5_inner(clocked_by p125clk, reset_by p125rst); return _b; // Instance wrapped inner module

endmodule: mkPCIEwrapV5

endpackage
