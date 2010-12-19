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

interface PCIEwrapIfc;
  interface PCIE_EXP#(4)          pcie;    // fabric-facing PCIe SERDES signals
                                           // fpga-user-facing interfaces...
  interface Clock                 pClk;    // PCIe-derived clock
  interface Reset                 pRst;    // PCIe-derived reset
  interface Client#(PTW16,PTW16)  client;  // The PCIe client - normally connected to infrastructure uNoC
  (* always_ready *) method Bool  linkUp;  // True when the pcie link is up
  (* always_ready *) method PciId device;  // PCIe device-id (16b 3-tuple)
endinterface: PCIEwrapIfc

//(* synthesize, no_default_clock, clock_prefix="", reset_prefix="" *)
module mkPCIEwrapV6#(Clock pci0_clkp, Clock pci0_clkn)(PCIEwrapIfc);
  Clock             pci0_clk    <- mkClockIBUFDS_GTXE1(True, pci0_clkp, pci0_clkn);
  Reset             pci0_rst    <- mkResetIBUF;
  PCIExpressV6#(4)  pci0        <- mkPCIExpressEndpointV6(?,clocked_by pci0_clk,reset_by pci0_rst);
  Clock             trn_clk     =  pci0.trn.clk;  // 250 MHz
  Reset             trn_rst     <- mkAsyncReset(1, pci0.trn.reset_n, trn_clk);
  Clock             trn2_clk    =  pci0.trn.clk2; // 125 MHz
  Reset             trn2_rst    <- mkAsyncReset(1, pci0.trn.reset_n, trn2_clk);
  Bool              pLinkUp     =  pci0.trn.link_up;
  Reg#(Bool)        pciLinkUp   <- mkSyncReg(False, trn_clk, trn_rst, trn2_clk);
  PciId             pciDev      =  PciId { bus:pci0.cfg.bus_number, dev:pci0.cfg.device_number, func:pci0.cfg.function_number};
  Reg#(PciId)       pciDevice   <- mkSyncReg(unpack(0), trn_clk, trn_rst, trn2_clk);

  rule write_pciLinkup; pciLinkUp <= pLinkUp; endrule  // 250 MHz side of pci core link up
  rule write_pciDevice; pciDevice <= pciDev;  endrule  // 250 MHz side of pciDevice mkSyncReg

  InterruptControl pcie_irq   <- mkInterruptController(trn_clk, trn_rst, clocked_by trn_clk, reset_by trn_rst);
  ClockInvToBoolIfc preEdge   <- vMkClockInvToBool(trn2_clk, clocked_by trn_clk, reset_by trn_rst);  //true when trn2 will rise on next edge

  Store#(UInt#(0),TLPData#(16),0) p2iS    <- mkRegStore(trn_clk, trn2_clk);
  AlignedFIFO#(TLPData#(16))      p2iAF   <- mkAlignedFIFO(trn_clk,trn_rst,trn2_clk,trn2_rst,p2iS,preEdge,True);
  Store#(UInt#(0),TLPData#(16),0) i2pS    <- mkRegStore(trn2_clk, trn_clk);
  AlignedFIFO#(TLPData#(16))      i2pAF   <- mkAlignedFIFO(trn2_clk,trn2_rst,trn_clk,trn_rst,i2pS,True,preEdge);
  FIFO#(TLPData#(8))              fP2I    <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst  );
  FIFO#(TLPData#(8))              fI2P    <- mkSizedFIFO(4,    clocked_by trn_clk, reset_by trn_rst  );

  // Inbound  PCIe (8B@250MHz) -> CTOP (16B@125MHz)...
  mkConnection(pci0.trn_rx,  toPut(fP2I),  clocked_by trn_clk,  reset_by trn_rst);  // 8B      250 MHz
  mkConnection(toGet(fP2I),  toPut(p2iAF), clocked_by trn_clk,  reset_by trn_rst);  // 8B->16B 250 MHz

  // Outbound CTOP (16B@125MHz) -> PCIe (8B@250MHz)...
  mkConnection(toGet(i2pAF), toPut(fI2P),  clocked_by trn_clk,  reset_by trn_rst);  // 16B->8B 250 MHz
  mkConnection(toGet(fI2P),  pci0.trn_tx,  clocked_by trn_clk,  reset_by trn_rst);  // 8B      250 MHz

  mkConnection(pci0.cfg_interrupt, pcie_irq.pcie_irq);
  mkTieOff(pci0.cfg);
  mkTieOff(pci0.cfg_err);

  // Interfaces and Methods provided...
  interface pcie     = pci0.pcie;
  interface pClk     = trn2_clk;
  interface pRst     = trn2_rst;
  interface Client client;
    interface request  = toGet(p2iAF); // 16B-125MHz requests  towards uNoC infrastructre
    interface response = toPut(i2pAF); // 16B-125MHz responses towards PCIe fabric
  endinterface
  method Bool  linkUp = pciLinkUp;
  method PciId device = pciDevice;

endmodule: mkPCIEwrapV6

endpackage
