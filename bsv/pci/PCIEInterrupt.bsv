////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009  Bluespec, Inc.   ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : PCIEInterrupt.bsv
//  Author        : Todd Snyder
//  Description   : Handles the processing of interrupts over PCIe
////////////////////////////////////////////////////////////////////////////////

// Notes :
// - Currently doesn't support legacy interrupts (only MSI)
// - Currently doesn't turn back-to-back interrupts around in an efficient manner

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Clocks            ::*;
import Connectable       ::*;
import FIFO              ::*;
import GetPut            ::*;

import PCIE              ::*;

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
(* always_enabled, always_ready *)
interface PCIE_INT_DRIVER;
   method    Bit#(1)     interrupt_n;
   method    Action      interrupt_rdy_n(Bit#(1) i);
   method    Action      interrupt_mmenable(Bit#(3) i);
   method    Action      interrupt_msienable(Bit#(1) i);
   method    Bit#(8)     interrupt_di;
   method    Action      interrupt_do(Bit#(8) i);
   method    Bit#(1)     interrupt_assert_n;
endinterface: PCIE_INT_DRIVER

interface InterruptControl;
   interface Put#(Bit#(8))   rx_irq;
   interface PCIE_INT_DRIVER pcie_irq;
endinterface: InterruptControl

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Implementation
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkInterruptController#(Clock user_clk, Reset user_rst_n)(InterruptControl);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   Reg#(Bool)                                rMSIEnabled         <- mkRegU;
   CrossingReg#(Bit#(3))                     rMMEnabled          <- mkNullCrossingRegU(user_clk);
   Wire#(Bool)                               wInterruptRdyN      <- mkDWire(True);
   Wire#(Bit#(8))                            wInterruptDo        <- mkDWire(0);
   
   Reg#(Bool)                                rInterrupting       <- mkReg(False);
   Reg#(Bool)                                rInterruptN         <- mkReg(True);
   Reg#(Bit#(8))                             rInterruptDi        <- mkReg(0);
   
   SyncFIFOIfc#(Bit#(8))                     fifoAssert          <- mkSyncFIFOToCC(8, user_clk, user_rst_n);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule msi_enabled(rMSIEnabled);
      
      rule assert_interrupt(!rInterrupting && wInterruptRdyN);
	 let intnum = fifoAssert.first; fifoAssert.deq;
	 rInterruptN   <= False;
	 rInterruptDi  <= intnum;
	 rInterrupting <= True;
      endrule
      
      rule assert_interrupt_done(rInterrupting && !wInterruptRdyN);
	 rInterruptN   <= True;
	 rInterrupting <= False;
      endrule
			      
   endrule
      
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface PCIE_INT_DRIVER pcie_irq;
      method    interrupt_n            = pack(rInterruptN);
      method    interrupt_rdy_n(x)     = wInterruptRdyN._write(unpack(x));
      method    interrupt_mmenable(x)  = rMMEnabled._write(x);
      method    interrupt_msienable(x) = rMSIEnabled._write(unpack(x));
      method    interrupt_di           = rInterruptDi;
      method    interrupt_do(x)        = wInterruptDo._write(x);
      method    interrupt_assert_n     = 1;
   endinterface: pcie_irq
   
   interface Put rx_irq;
      method Action put(Bit#(8) num);
	 if (rMMEnabled.crossed() == 0)
	    fifoAssert.enq(0);
	 else
	    fifoAssert.enq(num);
      endmethod
   endinterface: rx_irq
      
endmodule: mkInterruptController


////////////////////////////////////////////////////////////////////////////////
/// Connectables
////////////////////////////////////////////////////////////////////////////////
instance Connectable#(PCIE_INT, PCIE_INT_DRIVER);
   module mkConnection#(PCIE_INT p, PCIE_INT_DRIVER d)(Empty);
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_interrupt_1;
	 p.interrupt_n(d.interrupt_n);
	 p.interrupt_di(d.interrupt_di);
	 p.interrupt_assert_n(d.interrupt_assert_n);
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_interrupt_rdy_n;
	 d.interrupt_rdy_n(p.interrupt_rdy_n);
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_interrupt_mmenable;
	 d.interrupt_mmenable(p.interrupt_mmenable);
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_interrupt_msienable;
	 d.interrupt_msienable(p.interrupt_msienable);
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_interrupt_do;
	 d.interrupt_do(p.interrupt_do);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_INT_DRIVER, PCIE_INT);
   module mkConnection#(PCIE_INT_DRIVER d, PCIE_INT p)(Empty);
      mkConnection(p, d);
   endmodule
endinstance

// Identical V6 flavor...

instance Connectable#(PCIE_INT_V6, PCIE_INT_DRIVER);
  module mkConnection#(PCIE_INT_V6 p, PCIE_INT_DRIVER d)(Empty);
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect_interrupt_1;
	    p.req_n(d.interrupt_n);
	    p.di(d.interrupt_di);
	    p.assert_n(d.interrupt_assert_n);
    endrule
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect_interrupt_rdy_n;
	    d.interrupt_rdy_n(p.rdy_n);
    endrule
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect_interrupt_mmenable;
	    d.interrupt_mmenable(p.mmenable);
    endrule
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect_interrupt_msienable;
	    d.interrupt_msienable(p.msienable);
    endrule
    (* fire_when_enabled, no_implicit_conditions *)
    rule connect_interrupt_do;
	    d.interrupt_do(p.dout);
    endrule
   endmodule
endinstance

instance Connectable#(PCIE_INT_DRIVER, PCIE_INT_V6);
   module mkConnection#(PCIE_INT_DRIVER d, PCIE_INT_V6 p)(Empty);
      mkConnection(p, d);
   endmodule
endinstance
