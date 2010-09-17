// WCI2A4LM.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum::*;
import OCWip::*;

import Alias::*;
import Bus::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;

//A4L Structures...

typedef struct {   // Used for both the Write- and Read- Address channels...
  Bit#(3)  prot;
  Bit#(20) addr;
} A4LAddrCmd deriving (Bits, Eq);  
A4LAddrCmd  aAddrCmdDflt = A4LAddrCmd{addr:'0,prot:'0}; 

typedef struct {   // Used for the Write-Data channel...
  Bit#(4)  strb;
  Bit#(32) data;
} A4LWrData deriving (Bits, Eq);
A4LWrData  aWrDataDflt = A4LWrData{strb:'0,data:'0}; 

typedef struct {   // Used for the Write-Response channel...
  Bit#(2)  resp;
} A4LWrResp deriving (Bits, Eq);

typedef struct {   // Used for the Read-Response channel...
  Bit#(2)  resp;
  Bit#(32) data;
} A4LRdResp deriving (Bits, Eq);

interface A4LMIfc;
  interface BusSend#(A4LAddrCmd) wrAddr;
  interface BusSend#(A4LWrData)  wrData;
  interface BusRecv#(A4LWrResp)  wrResp;
  interface BusSend#(A4LAddrCmd) rdAddr;
  interface BusRecv#(A4LRdResp)  rdResp;
endinterface

interface WCI2A4LMIfc;
  interface Wci_Es#(20) wciS0;
  interface A4LMIfc     axiM0;
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWCI2A4LM#(parameter Bool hasDebugLogic) (WCI2A4LMIfc);

  WciSlaveIfc #(20)         wci         <- mkWciSlave;
  BusSender#(A4LAddrCmd)    a4wrAddr    <- mkBusSender(aAddrCmdDflt);
  BusSender#(A4LWrData)     a4wrData    <- mkBusSender(aWrDataDflt);
  BusReceiver#(A4LWrResp)   a4wrResp    <- mkBusReceiver;
  BusSender#(A4LAddrCmd)    a4rdAddr    <- mkBusSender(aAddrCmdDflt);
  BusReceiver#(A4LRdResp)   a4rdResp    <- mkBusReceiver;
  Reg#(Bool)                wrInFlight  <- mkReg(False);
  Reg#(Bool)                rdInFlight  <- mkReg(False);

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite && !wrInFlight); // WCI Configuration Property Writes...
  let wciReq <- wci.reqGet.get;
  a4wrAddr.in.enq(A4LAddrCmd{addr:wciReq.addr, prot:3'b000});
  a4wrData.in.enq(A4LWrData {strb:wciReq.byteEn, data:wciReq.data});
  $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
  wrInFlight <= True;
endrule

rule wci_cfwr_resp (wrInFlight);
  let aw = a4wrResp.out.first;
  //TODO: look at AXI write response code
  a4wrResp.out.deq;
  wci.respPut.put(wciOKResponse); // write response
  wrInFlight <= False;
  $display("[%0d]: %m: WCI CONFIG WRITE RESPOSNE",$time);
endrule

rule wci_cfrd (wci.configRead && !rdInFlight);  // WCI Configuration Property Reads...
  let wciReq <- wci.reqGet.get;
  a4rdAddr.in.enq(A4LAddrCmd{addr:wciReq.addr, prot:3'b000});
  rdInFlight <= True;
  $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x",$time, wciReq.addr, wciReq.byteEn);
endrule

rule wci_cfird_resp (rdInFlight);
  let ar = a4rdResp.out.first;
  //TODO: look at AXI read response code
  a4rdResp.out.deq;
  wci.respPut.put(WciResp{resp:DVA, data:ar.data}); // read response
  rdInFlight <= False;
  $display("[%0d]: %m: WCI CONFIG READ RESPOSNE Data:%0x",$time, ar.data);
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);         wci.ctlAck; endrule

  Wci_Es#(20)                                    wci_Es <- mkWciStoES(wci.slv); 

  interface wciS0 = wci_Es;
  interface A4LMIfc axiM0;
    interface BusSend wrAddr = a4wrAddr.out;
    interface BusSend wrData = a4wrData.out;
    interface BusRecv wrResp = a4wrResp.in;
    interface BusSend rdAddr = a4rdAddr.out;
    interface BusRecv rdResp = a4rdResp.in;
  endinterface

endmodule
