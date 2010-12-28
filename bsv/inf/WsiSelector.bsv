// WsiSelector.bsv - Select one of two WSI sources
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import Vector::*;

interface WsiSelectorIfc#(numeric type ndw, numeric type nd);
  interface Wci_s#(20)           wci_s;
  interface Wsi_s#(12,nd,4,8,1)     wsi_s0;
  interface Wsi_s#(12,nd,4,8,1)     wsi_s1;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m;
endinterface 

module mkWsiSelector (WsiSelectorIfc#(ndw,nd))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2; // Width in Bytes

  WciSlaveIfc#(20)          wci           <- mkWciSlave;
  WsiSlaveIfc #(12,nd,4,8,1)   wsiS0         <- mkWsiSlave;
  WsiSlaveIfc #(12,nd,4,8,1)   wsiS1         <- mkWsiSlave;
  WsiMasterIfc#(12,nd,4,8,1)   wsiM          <- mkWsiMaster;
  Reg#(Bit#(32))               controlReg    <- mkReg(0);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsiS0.operate(); wsiS1.operate(); wsiM.operate();
endrule

// This rule performs the WSI selection from S0 or S1 ports...
rule doMessagePush (wci.isOperating);
  WsiReq#(12,nd,4,8,1) r <- ( (controlReg[0]==0) ? wsiS0 : wsiS1) .reqGet.get;  // get from the selected slave
  wsiM.reqPut.put(r);                                                           // put the data to the WSI master
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
     'h18 : rdat = extend({pack(wsiS0.status),pack(wsiS1.status),pack(wsiM.status)});
     'h20 : rdat = pack(wsiS0.extStatus.pMesgCount);
     'h24 : rdat = pack(wsiS0.extStatus.iMesgCount);
     'h28 : rdat = pack(wsiS1.extStatus.pMesgCount);
     'h2C : rdat = pack(wsiS1.extStatus.iMesgCount);
     'h30 : rdat = pack( wsiM.extStatus.pMesgCount);
     'h34 : rdat = pack( wsiM.extStatus.iMesgCount);
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
  interface Wsi_s wsi_s0 = wsiS0.slv;
  interface Wsi_s wsi_s1 = wsiS1.slv;
  interface Wsi_m wsi_m  = wsiM.mas;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiSelectorIfc#(1,32) WsiSelector4BIfc;
(* synthesize *) module mkWsiSelector4B (WsiSelector4BIfc);
  WsiSelector4BIfc _a <- mkWsiSelector; return _a;
endmodule

typedef WsiSelectorIfc#(2,64) WsiSelector8BIfc;
(* synthesize *) module mkWsiSelector8B (WsiSelector8BIfc);
  WsiSelector8BIfc _a <- mkWsiSelector; return _a;
endmodule

typedef WsiSelectorIfc#(4,128) WsiSelector16BIfc;
(* synthesize *) module mkWsiSelector16B (WsiSelector16BIfc);
  WsiSelector16BIfc _a <- mkWsiSelector; return _a;
endmodule

typedef WsiSelectorIfc#(8,256) WsiSelector32BIfc;
(* synthesize *) module mkWsiSelector32B (WsiSelector32BIfc);
  WsiSelector32BIfc _a <- mkWsiSelector; return _a;
endmodule
