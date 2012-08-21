// WsiSplitter2x2.bsv - 2x2 WSI Crossbar Switch
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import GetPut::*;

interface WsiSplitter2x2Ifc#(numeric type ndw);
  interface WciES                                        wciS0;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)   wsiS0;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)   wsiS1;
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)   wsiM0;
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)   wsiM1;
endinterface 

module mkWsiSplitter2x2#(parameter Bit#(32) ctrlInit, parameter Bool hasDebugLogic) (WsiSplitter2x2Ifc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc#(32)                wci           <- mkWciSlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)    wsi_S0        <- mkWsiSlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)    wsi_S1        <- mkWsiSlave;
  WsiMasterIfc#(12,nd,nbe,8,0)    wsi_M0        <- mkWsiMaster;
  WsiMasterIfc#(12,nd,nbe,8,0)    wsi_M1        <- mkWsiMaster;
  Reg#(Bit#(32))                  splitCtrl     <- mkReg(ctrlInit);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsi_S0.operate(); wsi_S1.operate(); wsi_M0.operate(); wsi_M1.operate();
endrule

rule doMessageConsume_S0 (wci.isOperating);
  WsiReq#(12,nd,nbe,8,0) r <- wsi_S0.reqGet.get;
  if (!unpack(splitCtrl[0]) && !unpack(splitCtrl[7]))  wsi_M0.reqPut.put(r);
  if (!unpack(splitCtrl[8]) && !unpack(splitCtrl[15])) wsi_M1.reqPut.put(r);
endrule

rule doMessageConsume_S1 (wci.isOperating);
  WsiReq#(12,nd,nbe,8,0) r <- wsi_S1.reqGet.get;
  if ( unpack(splitCtrl[0]) && !unpack(splitCtrl[7]))  wsi_M0.reqPut.put(r);
  if ( unpack(splitCtrl[8]) && !unpack(splitCtrl[15])) wsi_M1.reqPut.put(r);
endrule


(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h04 : splitCtrl <= unpack(wciReq.data);
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h04 : rdat = pack(splitCtrl);
     'h1C : rdat = !hasDebugLogic ? 0 : {pack(wsi_S0.status),pack(wsi_S1.status),pack(wsi_M0.status),pack(wsi_M1.status)};
     'h20 : rdat = !hasDebugLogic ? 0 : pack(wsi_S0.extStatus.pMesgCount);
     'h24 : rdat = !hasDebugLogic ? 0 : pack(wsi_S0.extStatus.iMesgCount);
     'h28 : rdat = !hasDebugLogic ? 0 : pack(wsi_S1.extStatus.pMesgCount);
     'h2C : rdat = !hasDebugLogic ? 0 : pack(wsi_S1.extStatus.iMesgCount);
     'h30 : rdat = !hasDebugLogic ? 0 : pack(wsi_M0.extStatus.pMesgCount);
     'h34 : rdat = !hasDebugLogic ? 0 : pack(wsi_M0.extStatus.iMesgCount);
     'h38 : rdat = !hasDebugLogic ? 0 : pack(wsi_M1.extStatus.pMesgCount);
     'h3C : rdat = !hasDebugLogic ? 0 : pack(wsi_M1.extStatus.iMesgCount);
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

  WciES                                       wci_Es  <- mkWciStoES(wci.slv); 
  Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsi_Es0 <- mkWsiStoES(wsi_S0.slv);
  Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsi_Es1 <- mkWsiStoES(wsi_S1.slv);

  interface Wci_s wciS0  = wci_Es;
  interface Wsi_s wsiS0  = wsi_Es0;
  interface Wsi_s wsiS1  = wsi_Es1;
  interface Wsi_m wsiM0  = toWsiEM(wsi_M0.mas);
  interface Wsi_m wsiM1  = toWsiEM(wsi_M1.mas);

endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiSplitter2x2Ifc#(1) WsiSplitter2x24BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiSplitter2x24B#(parameter Bit#(32) ctrlInit, parameter Bool hasDebugLogic) (WsiSplitter2x24BIfc);
  WsiSplitter2x24BIfc _a <- mkWsiSplitter2x2(ctrlInit, hasDebugLogic); return _a;
endmodule

typedef WsiSplitter2x2Ifc#(2) WsiSplitter2x28BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiSplitter2x28B#(parameter Bit#(32) ctrlInit, parameter Bool hasDebugLogic) (WsiSplitter2x28BIfc);
  WsiSplitter2x28BIfc _a <- mkWsiSplitter2x2(ctrlInit, hasDebugLogic); return _a;
endmodule

typedef WsiSplitter2x2Ifc#(4) WsiSplitter2x216BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiSplitter2x216B#(parameter Bit#(32) ctrlInit, parameter Bool hasDebugLogic) (WsiSplitter2x216BIfc);
  WsiSplitter2x216BIfc _a <- mkWsiSplitter2x2(ctrlInit, hasDebugLogic); return _a;
endmodule

typedef WsiSplitter2x2Ifc#(8) WsiSplitter2x232BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiSplitter2x232B#(parameter Bit#(32) ctrlInit, parameter Bool hasDebugLogic) (WsiSplitter2x232BIfc);
  WsiSplitter2x232BIfc _a <- mkWsiSplitter2x2(ctrlInit, hasDebugLogic); return _a;
endmodule
