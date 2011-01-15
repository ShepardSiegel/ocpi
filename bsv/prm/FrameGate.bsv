// FrameGate.bsv - Delay streaming message data
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Alias::*;
import Connectable::*;
import GetPut::*;

interface FrameGateIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM0;    // WSI-M Stream Output
endinterface 

module mkFrameGate#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGateIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc#(32)               wci                <- mkWciSlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS               <- mkWsiSlave;
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM               <- mkWsiMaster;
  Reg#(Bit#(32))                 frameGateCtrl      <- mkReg(fgCtrlInit);
  Reg#(Bit#(32))                 frameSize          <- mkReg(0);
  Reg#(Bit#(32))                 gateSize           <- mkReg(0);
  Reg#(Bit#(32))                 byteCount          <- mkReg(extend(myByteWidth));
  Reg#(Bool)                     gated              <- mkReg(False);
  Reg#(Bit#(32))                 op0MesgCnt         <- mkReg(0);
  Reg#(Bit#(32))                 otherMesgCnt       <- mkReg(0);

  Bool wsiPass   = (frameGateCtrl[3:0]==4'h0);
  Bool frameGate = (frameGateCtrl[3:0]==4'h1);

rule operating_actions (wci.isOperating);
  wsiS.operate();
  wsiM.operate();
endrule

// The assumption is that messages arriving are imprecise and that both
// frameSize and gateSize are integer multiples of the message length so that
// the end of message indication with r.burstLenth==1 is taken on the correct
// cycle...
rule wsipass_doMessagePush (wci.isOperating);
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;

  if          (!gated && (byteCount==frameSize)) begin
    gated     <= True;
    byteCount <= extend(myByteWidth);
  end else if ( gated && (byteCount==gateSize))  begin
    gated     <= False;
    byteCount <= extend(myByteWidth);
  end else begin
    byteCount <= byteCount + extend(myByteWidth);
  end

  if (wsiPass || (frameGate && !gated)) wsiM.reqPut.put(r);
endrule


Bit#(32) frameGateStatus = extend({pack(hasDebugLogic)});

//
// WCI...
//
(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h04 : frameGateCtrl <= unpack(wciReq.data);
     'h08 : frameSize     <= unpack(wciReq.data);
     'h0C : gateSize      <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(frameGateStatus);
     'h04 : rdat = pack(frameGateCtrl);
     'h08 : rdat = pack(frameSize);
     'h0C : rdat = pack(gateSize);
     'h10 : rdat = (!hasDebugLogic) ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
     'h14 : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.pMesgCount);
     'h18 : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.iMesgCount);
     'h1C : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.tBusyCount);
     'h20 : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.pMesgCount);
     'h24 : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.iMesgCount);
     'h28 : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.tBusyCount);
     'h2C : rdat = (!hasDebugLogic) ? 0 : extend(pack(op0MesgCnt));
     'h30 : rdat = (!hasDebugLogic) ? 0 : extend(pack(otherMesgCnt));
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting FrameGate frameGateCtrl:%0x", $time, frameGateCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  WciES                   wci_Es    <- mkWciStoES(wci.slv); 
  Wsi_Es#(12,nd,nbe,8,0)  wsi_Es    <- mkWsiStoES(wsiS.slv);

  interface wciS0  = wci_Es;
  interface wsiS0  = wsi_Es;
  interface wsiM0  = toWsiEM(wsiM.mas);
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef FrameGateIfc#(1) FrameGate4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate4B#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGate4BIfc);
  FrameGate4BIfc _a <- mkFrameGate(fgCtrlInit, hasDebugLogic); return _a;
endmodule

typedef FrameGateIfc#(2) FrameGate8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate8B#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGate8BIfc);
  FrameGate8BIfc _a <- mkFrameGate(fgCtrlInit, hasDebugLogic); return _a;
endmodule

typedef FrameGateIfc#(4) FrameGate16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate16B#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGate16BIfc);
  FrameGate16BIfc _a <- mkFrameGate(fgCtrlInit, hasDebugLogic); return _a;
endmodule

typedef FrameGateIfc#(8) FrameGate32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate32B#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGate32BIfc);
  FrameGate32BIfc _a <- mkFrameGate(fgCtrlInit, hasDebugLogic); return _a;
endmodule

