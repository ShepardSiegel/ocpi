// WCI2A4LM.bsv - OCP::WIP::WCI Slave bridged to AXI4-Lite Master
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// This bridge enforces a serialization rule allowing only a single access in-flight at a time.
// It does so with the token FIFO of depth 1. Any configuration read or write access takes the token,
// any response gives the token back. The implicit conditions around the token guard the rules.

import ARAXI4L::*;
import OCWip::*;

import FIFO::*;	
import GetPut::*;

interface WCIS2A4LMIfc;
  interface WciES    wciS0;  // WCI Slave
  interface A4LMIfc  axiM0;  // AXI4-Lite Master
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWCIS2A4LM#(parameter Bool hasDebugLogic) (WCIS2A4LMIfc);
  WciSlaveIfc#(32)  wci     <- mkWciSlave;     // The WIP::WCI Slave Interface
  A4LMasterIfc      a4l     <- mkA4LMaster;    // The AXI4-Lite Master Interface
  FIFO#(Bit#(0))    token   <- mkFIFO1;        // Token to allow only one access in flight

(* descending_urgency = "wci_ctl_op_complete,wci_ctl_op_start,wci_cfwr,wci_cfrd,wci_cfwr_resp,wci_cfrd_resp" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Write...
  let wciReq <- wci.reqGet.get;
  a4l.f.wrAddr.enq(A4LAddrCmd{addr:wciReq.addr, prot:aProtDflt});
  a4l.f.wrData.enq(A4LWrData {strb:wciReq.byteEn, data:wciReq.data});
  token.enq(?);
  $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
endrule

rule wci_cfwr_resp;  // AXI Response from Configuration Write...
  let aw = a4l.f.wrResp.first; //TODO: look at AXI write response code (assume OKAY for now)
  a4l.f.wrResp.deq;
  wci.respPut.put(wciOKResponse); // write response
  token.deq;
  $display("[%0d]: %m: WCI CONFIG WRITE RESPOSNE",$time);
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Read...
  let wciReq <- wci.reqGet.get;
  a4l.f.rdAddr.enq(A4LAddrCmd{addr:wciReq.addr, prot:aProtDflt});
  token.enq(?);
  $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x",$time, wciReq.addr, wciReq.byteEn);
endrule

rule wci_cfrd_resp;  // AXI Response from Configuration Read...
  let ar = a4l.f.rdResp.first; //TODO: look at AXI read response code (assume OKAY for now)
  a4l.f.rdResp.deq;
  wci.respPut.put(WciResp{resp:DVA, data:ar.data}); // read response
  token.deq;
  $display("[%0d]: %m: WCI CONFIG READ RESPOSNE Data:%0x",$time, ar.data);
endrule

// Since this bridge is a "worker", need to respect the WIP::WCI control operation disipline..
rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);         wci.ctlAck; endrule

  WciES wci_Es <- mkWciStoES(wci.slv); 
  interface wciS0 = wci_Es;
  interface A4LMIfc axiM0 = a4l.a4lm;
endmodule
