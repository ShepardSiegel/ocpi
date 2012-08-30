// GbeWrk.bsv - The WCI facing part of the GbeWorker
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import CPDefs       ::*;
import GMAC         ::*;
import OCWip        ::*;
import SRLFIFO      ::*;

import ClientServer ::*;
import Clocks       ::*;
import Connectable  ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;
import XilinxCells  ::*;
import XilinxExtra  ::*;

interface GbeWrkIfc;
  interface WciES       wciS0;  // Worker Control and Configuration
  (* always_ready *) method    MACAddress  l2Dst;  // Ethernet Layer 2 Dest
  (* always_ready *) method    EtherType   l2Typ;  // Ethernet Layer 2 EtherType
  method Action dgdpEgressCnt (Bit#(32) arg);
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeWrk#(parameter Bool hasDebugLogic) (GbeWrkIfc);

  WciESlaveIfc                wci              <-  mkWciESlave;
  Reg#(Bit#(32))              ctlReg           <-  mkRegU;
  // TODO: Sort out Vector takeAt and append issue...
  //Reg#(Vector#(8,Bit#(8)))    edpDV            <-  mkRegU;
  Reg#(Bit#(32))              r10              <- mkReg(0);
  Reg#(Bit#(32))              r14              <- mkReg(0);
  Wire#(Bit#(32))             dgdpEgressCnt_w  <-  mkDWire(?);

  // WCI Control....
  Bit#(32) gbeStatus = 32'h0000_0000;

  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
    let wciReq <- wci.reqGet.get;
    case (wciReq.addr[7:0]) matches
     'h00 : ctlReg     <= wciReq.data;
     //'h10 : edpDV      <= append(takeAt(4, edpDV), unpack(wciReq.data));
     //'h14 : edpDV      <= append(unpack(wciReq.data), takeAt(0, edpDV));
     'h10 : r10        <= wciReq.data;
     'h14 : r14        <= wciReq.data;
    endcase
    //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
    wci.respPut.put(wciOKResponse); // write response
  endrule

  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
    let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
    case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(ctlReg);
     'h0C : rdat = pack(dgdpEgressCnt_w);
     //'h10 : rdat = pack(takeAt(0, edpDV));
     //'h14 : rdat = pack(takeAt(4, edpDV));
     'h10 : rdat = r10;
     'h14 : rdat = r14;
    endcase
    //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
    wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);         wci.ctlAck; endrule

  // Interfaces and Methods provided...
  interface Wci_s       wciS0   = wci.slv;
  //method    MACAddress  l2Dst   = pack(takeAt(0,edpDV));
  //method    EtherType   l2Typ   = pack(takeAt(6,edpDV));
  //method    MACAddress  l2Dst   =  {r14[15:0], r10};
  method    MACAddress  l2Dst   =  {r10[7:0], r10[15:8], r10[23:16], r10[31:24], r14[7:0], r14[15:8]};
  method    EtherType   l2Typ   =  r14[31:16];
  method Action dgdpEgressCnt (Bit#(32) arg) = dgdpEgressCnt_w._write(arg);
endmodule
