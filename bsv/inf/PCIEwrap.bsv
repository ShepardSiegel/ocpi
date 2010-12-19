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

// The PCIEwrapIfc is expected to remain constant across a range of technology-specific implemenatations...
interface PCIEwrapIfc;
  interface PCIE_EXP#(4)          pcie;    // fabric-facing PCIe SERDES signals
                                           // FPGA-user-facing interfaces...
  interface Clock                 pClk;    // PCIe-derived clock (nominally 125 MHz, regardless of PCIe core)
  interface Reset                 pRst;    // PCIe-derived reset (Reset in the domain of the above Clock)
  interface Client#(PTW16,PTW16)  client;  // The PCIe client - normally connected to infrastructure uNoC
  (* always_ready *) method Bool  linkUp;  // True when the pcie link is up
  (* always_ready *) method PciId device;  // PCIe device-id (16b 3-tuple)
endinterface: PCIEwrapIfc

// This Xilinx V6 specifc implementation takes 8B/250MHz interface and converts it to 16B/125MHz...
//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapV6#(Clock pci0_clkp, Clock pci0_clkn)(PCIEwrapIfc);
  Clock                pci0_clk    <- mkClockIBUFDS_GTXE1(True, pci0_clkp, pci0_clkn);
  Reset                pci0_rst    <- mkResetIBUF;   // Instance the PCIe Reset IBUF here
  PCIExpressV6#(4)     pci0        <- mkPCIExpressEndpointV6(?,clocked_by pci0_clk,reset_by pci0_rst);
  Clock                p250clk     =  pci0.trn.clk;  // 250 MHz (the div/1 clock from the pcie core)
  Reset                p250rst     <- mkAsyncReset(1, pci0.trn.reset_n, p250clk);
  Clock                p125clk     =  pci0.trn.clk2; // 125 MHz (the div/2 clock from the pcie core)
  Reset                p125rst     <- mkAsyncReset(1, pci0.trn.reset_n, p125clk );
                                   // Place LinkUp and pciDevice in p125clk domain
  Bool                 pLinkUp     =  pci0.trn.link_up;
  SyncBitIfc#(Bit#(1)) pciLinkUp   <- mkSyncBit(p250clk, p250rst, p125clk);  // single-bit synchronizer 250 to 125 MHz
  PciId                pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
  Reg#(PciId)          pciDevice   <- mkSyncReg(unpack(0), p250clk, p250rst, p125clk); // multi-bit sync 250 to 125 MHz

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
  interface pcie     = pci0.pcie;
  interface pClk     = p125clk ;
  interface pRst     = p125rst ;
  interface Client client;
    interface request  = toGet(p2iAF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(i2pAF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  linkUp = unpack(pciLinkUp.read);
  method PciId device = pciDevice;
endmodule: mkPCIEwrapV6


interface PCIEwrapV5Ifc;
  interface PCIE_EXP#(8)          pcie;    // fabric-facing PCIe SERDES signals
                                           // FPGA-user-facing interfaces...
  interface Clock                 pClk;    // PCIe-derived clock (nominally 125 MHz, regardless of PCIe core)
  interface Reset                 pRst;    // PCIe-derived reset (Reset in the domain of the above Clock)
  interface Client#(PTW16,PTW16)  client;  // The PCIe client - normally connected to infrastructure uNoC
  (* always_ready *) method Bool  linkUp;  // True when the pcie link is up
  (* always_ready *) method PciId device;  // PCIe device-id (16b 3-tuple)
endinterface: PCIEwrapV5Ifc

// This Xilinx V5 specifc implementation takes 8B/125MHz interface and converts it to 16B/125MHz...
// This implemenation is IMBALANCED as the PCIe side is 1 GB/S to the uNoC side of 2 GB/S
//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapV5#(Clock pci0_clkp, Clock pci0_clkn)(PCIEwrapV5Ifc);
  Clock             pci0_clk    <- mkClockIBUFDS(pci0_clkp, pci0_clkn);
  Reset             pci0_rst    <- mkResetIBUF;
  PCIExpress#(8)    pci0        <- mkPCIExpressEndpoint(?,clocked_by pci0_clk,reset_by pci0_rst);
  Clock             p125clk     =  pci0.trn.clk2; // 125 MHz
  Reset             p125rst     <- mkAsyncReset(1, pci0.trn.reset_n, p125clk );
  Bool              pLinkUp     =  pci0.trn.link_up;
  Reg#(Bool)        pciLinkUp   <- mkReg(False);
  PciId             pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
  Reg#(PciId)       pciDevice   <- mkReg(unpack(0));

  rule write_pciLinkup; pciLinkUp <= pLinkUp; endrule
  rule write_pciDevice; pciDevice <= pciDev;  endrule 

  InterruptControl pcie_irq   <- mkInterruptController(p125clk, p125rst, clocked_by p125clk, reset_by p125rst);
  ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(p125clk , clocked_by p125clk, reset_by p125rst);  //true when trn2 will rise on next edge

  FIFO#(TLPData#(16)) uP2IF   <- mkFIFO(clocked_by p125clk, reset_by p125rst);
  FIFO#(TLPData#(16)) uI2PF   <- mkFIFO(clocked_by p125clk, reset_by p125rst);

  // Inbound  PCIe (8B@125MHz) -> CTOP (16B@125MHz)...
  mkConnection(pci0.trn_rx,  toPut(uP2IF), clocked_by p125clk,  reset_by p125rst);  // 8B->16B  (this mkConnection instance does 1:2 width conversion)
  // Outbound CTOP (16B@125MHz) -> PCIe (8B@125MHz)...
  mkConnection(toGet(uI2PF), pci0.trn_tx,  clocked_by p125clk,  reset_by p125rst);  // 16B->8B  (this mkConnection instance does 2:1 width conversion)

  mkConnection(pci0.cfg_irq, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  // Interfaces and Methods provided...
  interface pcie     = pci0.pcie;
  interface pClk     = p125clk ;
  interface pRst     = p125rst ;
  interface Client client;
    interface request  = toGet(uP2IF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(uI2PF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  linkUp = pciLinkUp;
  method PciId device = pciDevice;
endmodule: mkPCIEwrapV5

endpackage
