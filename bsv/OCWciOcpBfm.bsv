// OCWciOcpBfm.bsv - OpenCPI Worker Control Interface (WCI::OCP) Bus Functional Models
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWciOcpBfm;

import OCWci::*;
import OCWciOcp::*;
import OCWipDefs::*;
import ProtocolMonitor::*;

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

interface WciOcpInitiatorIfc;
  interface WciOcp_Em#(20) wciM0;
endinterface

//(* synthesize, reset_prefix="bar" *)
(* synthesize *)
module mkWciOcpInitiator (WciOcpInitiatorIfc);
  WciOcpMasterIfc#(20) initiator <- mkWciOcpMaster;
  Reg#(Bool)           started   <- mkReg(False);
  // Add initiator behavior here...
  //WciOcpResp resp = ?;
  Stmt init = 
  seq
    $display("[%0d]: %m: WCI Initiator Taking Worker out of Reset...", $time);
    initiator.req(Admin,   True,  20'h00_0024, 32'h8000_0004, 4'hF);  // unreset
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Control, False, 20'h00_0000, 32'h8000_0000, 4'hF);  // initialize
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Control, False, 20'h00_0004, 32'h8000_0000, 4'hF);  // start
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Config,  True,  20'h00_0000, 32'h8000_0042, 4'hF);  // write 42
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
    initiator.req(Config,  False, 20'h00_0000, 32'h8000_0000, 4'hF);  // read
    action let resp <- initiator.resp; $display("[%0d]: %m: WCI Initiator received response %0x", $time, resp.data); endaction
  endseq;
  FSM initFsm <- mkFSM(init);

  rule startup (!started);
    initFsm.start;
    started <= True;
  endrule

  WciOcp_Em#(20) wci_Em <- mkWciOcpMtoEm(initiator.mas);
  interface WciOcp_Em wciM0 = wci_Em;
endmodule


interface WciOcpTargetIfc;
  interface WciOcp_Es#(20) wciS0;
endinterface

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWciOcpTarget (WciOcpTargetIfc);
  WciOcpSlaveIfc#(20) target       <-mkWciOcpSlave;
  Reg#(Bool)          operating    <- mkReg(False);
  Reg#(Bit#(32))      biasValue    <- mkRegU;          // storage for the biasValue
  Reg#(Bit#(32))      controlReg   <- mkRegU;          // storage for the controlReg

  // Add target behavior here...
  rule report_operating (target.isOperating && !operating);
    $display("[%0d]: %m: WCI Target is Operating", $time);
    operating <= True;
  endrule

  rule target_cfwr (target.configWrite); // WCI Configuration Property Writes...
   let targetReq <- target.reqGet.get;
     case (targetReq.addr[7:0]) matches
       'h00 : biasValue  <= unpack(targetReq.data);
       'h04 : controlReg <= unpack(targetReq.data);
     endcase
     $display("[%0d]: %m: WCI TARGET CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, targetReq.addr, targetReq.byteEn, targetReq.data);
     target.respPut.put(wciOKResponse); // write response
  endrule
  
  rule target_cfrd (target.configRead);  // WCI Configuration Property Reads...
   let targetReq <- target.reqGet.get; Bit#(32) rdat = '0;
     case (targetReq.addr[7:0]) matches
       'h00 : rdat = pack(biasValue);
       'h04 : rdat = pack(controlReg);
     endcase
     $display("[%0d]: %m: WCI TARGET CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, targetReq.addr, targetReq.byteEn, rdat);
     target.respPut.put(WciResp{resp:OK, data:rdat}); // read response
  endrule
  
  rule target_ctrl_EiI (target.ctlState==Exists && target.ctlOp==Initialize);
    biasValue  <= 0;    // initialize bias value to zero
    controlReg <= 0;    // initialize control register to zero
    target.ctlAck;      // acknowledge the initialization operation
  endrule

  rule target_ctrl_IsO (target.ctlState==Initialized && target.ctlOp==Start); target.ctlAck; endrule
  rule target_ctrl_OrE (target.isOperating && target.ctlOp==Release); target.ctlAck; endrule


  WciOcp_Es#(20) wci_Es <- mkWciOcpStoES(target.slv);
  interface WciOcp_Em wciS0 = wci_Es;
endmodule

interface WciOcpMonitorIfc;
  interface WciOcp_Eo#(20) observe;
  interface Get#(PMEMF)     pmem; 
endinterface

(* synthesize *)
module mkWciOcpMonitor#(parameter Bit#(8) monId)  (WciOcpMonitorIfc);
  WciOcpObserverIfc#(20) observer <- mkWciOcpObserver;
  PMEMGenIfc             pmemgen  <- mkPMEMGen(monId);

  // Add monitor/observer behavior here...
  rule event_cmd;
    let e <- observer.seen.get;
    pmemgen.sendEvent(e);
    //$display("[%0d]: %m: event seen", $time);
  endrule

  interface WciOcp_Eo observe  = observer.wci;
  interface Get       pmem     = pmemgen.pmem; 
endmodule


endpackage: OCWciOcpBfm
