// OPED.bsv
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

// Infrastucture Imports...
import Config            ::*;
import OCWip             ::*;
import OCCP              ::*;
import OCDP              ::*;
import PCIEwrap          ::*;
import TimeService       ::*;
import TLPMF             ::*;
import UNoC              ::*;
import XilinxExtra       ::*;

// BSV Imports...
import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import PCIE              ::*;
import PCIEInterrupt     ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;

interface OPEDIfc#(numeric type lanes);
  interface PCIE_EXP#(lanes)       pcie;
  interface Clock                  p125clk;
  interface Reset                  p125rst;
  (*always_ready*) method Bit#(32) debug;
endinterface: OPEDIfc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="" *)
module mkOPEDv6#(Clock pci0_clkp, Clock pci0_clkn) (OPEDIfc#(4));
  OPEDIfc#(4) _a <- mkOPEDw(pci0_clkp,pci0_clkn); return _a;
endmodule

// This top-level wrapper module has no default clock or reset...
module mkOPEDw#(Clock pci0_clkp, Clock pci0_clkn)(OPEDIfc#(lanes)) provisos(Add#(1,z,lanes));
  PCIEwrapIfc#(lanes) pciw  <- mkPCIEwrapV6(pci0_clkp, pci0_clkn);  // Instance the technology-specific PCIE core
  Clock p125Clk = pciw.pClk;
  Reset p125Rst = pciw.pRst;

  // This is the body of mkOPED, which enjoys having the default 125 MHz Clock and Reset provided...
  module mkOPED (OPEDIfc#(lanes)) provisos(Add#(1,z,lanes));
    Reg#(PciId)          pciDevice  <- mkReg(unpack(0));
    (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule
    UNoCIfc              noc        <- mkUNoC;                              // uNoC Network-on-Chip
    OCCPIfc#(Nwcit)      cp         <- mkOCCP(pciDevice, p125Clk, p125Rst); // control plane

    Vector#(15,WciOcp_Em#(20)) vWci; vWci = cp.wci_Vm; // splay apart the individual Reset signals from the Control Plane
    Vector#(15, Reset) rst = newVector; for (Integer i=0; i<15; i=i+1) rst[i] = vWci[i].mReset_n;

    OCDP4BIfc dp0 <- mkOCDP(insertFNum(pciDevice,0),False,True, reset_by rst[13]); // data-plane fabric consumer PULL Only
    OCDP4BIfc dp1 <- mkOCDP(insertFNum(pciDevice,1),True,False, reset_by rst[14]); // data-plane fabric producer PUSH Only

    mkConnection(pciw.client, noc.fab);   // PCIe to uNoC
    mkConnection(noc.cp,    cp.server);   // uNoC to Control Plane
    mkConnection(noc.dp0,   dp0.server);  // uNoC to Data Plane 0
    mkConnection(noc.dp1,   dp1.server);  // uNoC to Data Plane 1

    interface PCI_EXP  pcie    = pciw.pcie;
    interface Clock    p125clk = pciw.pClk;
    interface Reset    p125rst = pciw.pRst;
    method Bit#(32)    debug   = extend(pack(pciw.linkUp));
 endmodule: mkOPED

  OPEDIfc#(lanes) _b  <- mkOPED(clocked_by p125Clk, reset_by p125Rst); // Instantiate mkOPED
  return _b;
endmodule: mkOPEDw

