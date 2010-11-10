// OCWciAxi.bsv - OpenCPI Worker Control Interface (WCI::AXI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWciAxiBfm;

import OCWci::*;
import OCWciAxi::*;
import OCWipDefs::*;

import Clocks::*;
import Connectable::*;
import GetPut::*;
import ConfigReg::*;
import DefaultValue::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import FShow::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import TieOff::*;

interface WciAxiInitiatorIfc;
  interface WciAxi_Em wciM0;
endinterface

(* synthesize *)
module mkWciAxiInitiator (WciAxiInitiatorIfc);
  WciAxiMasterIfc      initiator <- mkWciAxiMaster;
  Reg#(Bool)           started   <- mkReg(False);
  // Add initiator behavior here...
  Stmt init = 
  seq
    $display("[%0d]: %m: WCI Initiator Taking Worker out of Reset...", $time);
    initiator.req(Admin,   True,  32'h0000_0024, 32'h8000_0004, 4'hF);  // unreset
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Control, False, 32'h0000_0000, 32'h8000_0000, 4'hF);  // initialize
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Control, False, 32'h0000_0004, 32'h8000_0000, 4'hF);  // start
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Config,  True,  32'h0000_0000, 32'h8000_0042, 4'hF);  // write 42
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Config,  False, 32'h0000_0000, 32'h8000_0000, 4'hF);  // read
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
  endseq;
  FSM initFsm <- mkFSM(init);

  rule startup (!started);
    initFsm.start;
    started <= True;
  endrule

  WciAxi_Em wci_Em <- mkWciAxiMtoEm(initiator.mas);
  interface WciAxi_Em wciM0 = wci_Em;
endmodule



interface WciAxiTargetIfc;
  interface WciAxi_Es wciS0;
endinterface

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWciAxiTarget (WciAxiTargetIfc);
  WciAxiSlaveIfc target <-mkWciAxiSlave;
  // Add target behavior here...
  //WciAxi_Es wci_Es <- mkWciAxiStoES(target.slv);
  interface WciAxi_Es wciS0;
  endinterface
endmodule

interface WciAxiMonitorIfc;
  interface WciAxi_Eo wciO0;
endinterface

(* synthesize, default_clock_osc="wciO0_Clk", default_reset="wciO0_MReset_n" *)
module mkWciAxiMonitor (WciAxiMonitorIfc);
  // Add monitor/observer behavior here...
  interface WciAxi_Eo wciO0;
  endinterface
endmodule


endpackage: OCWciAxiBfm
