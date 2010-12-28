// WsiSplitter.bsv - Split one WSI stream to simulatensously feed two sinks
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import Vector::*;

interface WsiSplitterIfc#(numeric type ndw, numeric type nd);
  interface Wci_s#(20)              wci_s;
  interface Wsi_s#(12,nd,4,8,1)     wsi_s;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m0;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m1;
endinterface 

module mkWsiSplitter (WsiSplitterIfc#(ndw,nd))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2; // Width in Bytes

  WciSlaveIfc#(20)             wci           <- mkWciSlave;
  WsiSlaveIfc #(12,nd,4,8,1)   wsiS          <- mkWsiSlave;
  WsiMasterIfc#(12,nd,4,8,1)   wsiM0         <- mkWsiMaster;
  WsiMasterIfc#(12,nd,4,8,1)   wsiM1         <- mkWsiMaster;
  Reg#(Bit#(32))               controlReg    <- mkReg(0);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsiS.operate(); wsiM0.operate(); wsiM1.operate();
endrule

// This rule performs the WSI Split to two sinks. This could be made 'n' sinks...
rule doMessagePush (wci.isOperating);
  WsiReq#(12,nd,4,8,1) r <- wsiS.reqGet.get;   // get from the WSI source
  wsiM0.reqPut.put(r);                         // split-put to M0
  wsiM1.reqPut.put(r);                         // split-put to M1
endrule

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h04 : controlReg <= unpack(wciReq.data);
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h04 : rdat = pack(controlReg);
     'h18 : rdat = extend({pack(wsiS.status),pack(wsiM0.status),pack(wsiM1.status)});
     'h20 : rdat = pack( wsiS.extStatus.pMesgCount);
     'h24 : rdat = pack( wsiS.extStatus.iMesgCount);
     'h28 : rdat = pack(wsiM0.extStatus.pMesgCount);
     'h2C : rdat = pack(wsiM0.extStatus.iMesgCount);
     'h30 : rdat = pack(wsiM1.extStatus.pMesgCount);
     'h34 : rdat = pack(wsiM1.extStatus.iMesgCount);
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:OK, data:rdat}); // read response
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  interface Wci_s wci_s  = wci.slv;
  interface Wsi_s wsi_s  = wsiS.slv;
  interface Wsi_m wsi_m0 = wsiM0.mas;
  interface Wsi_m wsi_m1 = wsiM1.mas;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiSplitterIfc#(1,32) WsiSplitter4BIfc;
(* synthesize *) module mkWsiSplitter4B (WsiSplitter4BIfc);
  WsiSplitter4BIfc _a <- mkWsiSplitter; return _a;
endmodule

typedef WsiSplitterIfc#(2,64) WsiSplitter8BIfc;
(* synthesize *) module mkWsiSplitter8B (WsiSplitter8BIfc);
  WsiSplitter8BIfc _a <- mkWsiSplitter; return _a;
endmodule

typedef WsiSplitterIfc#(4,128) WsiSplitter16BIfc;
(* synthesize *) module mkWsiSplitter16B (WsiSplitter16BIfc);
  WsiSplitter16BIfc _a <- mkWsiSplitter; return _a;
endmodule

typedef WsiSplitterIfc#(8,256) WsiSplitter32BIfc;
(* synthesize *) module mkWsiSplitter32B (WsiSplitter32BIfc);
  WsiSplitter32BIfc _a <- mkWsiSplitter; return _a;
endmodule
