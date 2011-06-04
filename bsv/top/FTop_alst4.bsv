// FTop_alst4.bsv
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import Config            ::*;
import CTop              ::*;
import OCWip             ::*;
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

  // Instance the wrapped, technology-specific PCIE core...
  PCIEwrapAIfc#(4) pciw       <- mkPCIEwrapA("A4", sys0_clk, sys0_rstn, pcie_clk, pcie_rstn);
  Clock            p125Clk    =  pciw.pClk;  // Nominal 125 MHz
  Reset            p125Rst    =  pciw.pRst;  // Reset for pClk domain
  Reg#(PciId)      pciDevice  <- mkReg(unpack(0), clocked_by p125Clk, reset_by p125Rst);

  (* fire_when_enabled, no_implicit_conditions *) rule pdev; pciDevice <= pciw.device; endrule

  // debug...
  Reg#(Bit#(8))    swReg      <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);
  Reg#(Bit#(32))   freeCnt    <- mkReg(0, clocked_by p125Clk, reset_by p125Rst);
  Bit#(1) swParity = parity(swReg);
  rule freeCount; freeCnt <= freeCnt + 1; endrule


`ifdef USE_NDW1
  CTop4BIfc  ctop <- mkCTop4B(pciDevice,  sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`elsif USE_NDW4
  CTop16BIfc ctop <- mkCTop16B(pciDevice, sys0_clk, sys0_rstn, clocked_by p125Clk , reset_by p125Rst );
`endif
   
  mkConnection(pciw.client, ctop.server); // Connect the PCIe client (fabric) to the CTop server (uNoC)

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
endmodule: mkFTop_alst4
