// WsiSplitter2x2.bsv - 2x2 WSI Crossbar Switch
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import Vector::*;

interface WsiSplitter2x2Ifc#(numeric type ndw, numeric type nd);
  interface Wci_s#(20)              wci_s;
  interface Wsi_s#(12,nd,4,8,1)     wsi_s0;
  interface Wsi_s#(12,nd,4,8,1)     wsi_s1;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m0;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m1;
endinterface 

module mkWsiSplitter2x2 (WsiSplitter2x2Ifc#(ndw,nd))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2; // Width in Bytes

  WciSlaveIfc#(20)             wci           <- mkWciSlave;
  WsiSlaveIfc #(12,nd,4,8,1)   wsiS0         <- mkWsiSlave;
  WsiSlaveIfc #(12,nd,4,8,1)   wsiS1         <- mkWsiSlave;
  WsiMasterIfc#(12,nd,4,8,1)   wsiM0         <- mkWsiMaster;
  WsiMasterIfc#(12,nd,4,8,1)   wsiM1         <- mkWsiMaster;
  Reg#(Bit#(32))               controlReg    <- mkReg(0);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsiS0.operate(); wsiS1.operate(); wsiM0.operate(); wsiM1.operate();
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
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
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

typedef WsiSplitter2x2Ifc#(1,32) WsiSplitter2x24BIfc;
(* synthesize *) module mkWsiSplitter2x24B (WsiSplitter2x24BIfc);
  WsiSplitter2x24BIfc _a <- mkWsiSplitter2x2; return _a;
endmodule

typedef WsiSplitter2x2Ifc#(2,64) WsiSplitter2x28BIfc;
(* synthesize *) module mkWsiSplitter2x28B (WsiSplitter2x28BIfc);
  WsiSplitter2x28BIfc _a <- mkWsiSplitter2x2; return _a;
endmodule

typedef WsiSplitter2x2Ifc#(4,128) WsiSplitter2x216BIfc;
(* synthesize *) module mkWsiSplitter2x216B (WsiSplitter2x216BIfc);
  WsiSplitter2x216BIfc _a <- mkWsiSplitter; return _a;
endmodule

typedef WsiSplitter2x2Ifc#(8,256) WsiSplitter2x232BIfc;
(* synthesize *) module mkWsiSplitter2x232B (WsiSplitter2x232BIfc);
  WsiSplitter2x232BIfc _a <- mkWsiSplitter2x2; return _a;
endmodule
