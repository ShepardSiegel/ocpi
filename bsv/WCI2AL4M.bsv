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
  Bit#(19) addr;
  Bit#(3)  prot;
} A4LAddrCmd deriving (Bits, Eq);  

typedef struct {   // Used for the Write-Data channel...
  Bit#(4)  strb;
  Bit#(32) data;
} A4LWrData deriving (Bits, Eq);

typedef struct {   // Used for the Write-Response channel...
  Bit#(2)  resp;
} A4LWrResp deriving (Bits, Eq);

typedef struct {   // Used for the Read-Response chanell...
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

  WciSlaveIfc #(20)              wci               <- mkWciSlave;

// WCI...

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h00 : smaCtrl  <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(smaCtrl);
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule


rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting AXI4LM smaCtrl:%0x", $time, smaCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);         wci.ctlAck; endrule

  Wci_Es#(20)                                    wci_Es <- mkWciStoES(wci.slv); 

  interface wciS0 = wci_Es;

endmodule
