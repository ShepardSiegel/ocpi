// FrameGate.bsv - Delay streaming message data
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Alias::*;
import Connectable::*;
import GetPut::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface FrameGateIfc#(numeric type ndw);
  interface Wci_Es#(NwciAddr)                           wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS1;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM1;    // WSI-M Stream Output
endinterface 

module mkFrameGate#(parameter Bit#(32) fgCtrlInit, parameter Bool hasDebugLogic) (FrameGateIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciSlaveIfc #(NwciAddr)        wci                <- mkWciSlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS               <- mkWsiSlave;
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM               <- mkWsiMaster;
  Reg#(Bit#(32))                 frameGateCtrl      <- mkReg(fgCtrlInit);
  Reg#(Bit#(32))                 frameSize          <- mkReg(0);
  Reg#(Bit#(32))                 wordsThisFrame     <- mkReg(0);
  Reg#(Bit#(32))                 gateSize           <- mkReg(0);
  Reg#(Bit#(32))                 wordsGated         <- mkReg(0);
  Reg#(Bool)                     gated              <- mkReg(False);
  Reg#(Maybe#(Bit#(8)))          opcode             <- mkReg(tagged Invalid)

  Reg#(Bit#(32))                 op0MesgCnt         <- mkReg(0);
  Reg#(Bit#(32))                 otherMesgCnt       <- mkReg(0);

  Bool wsiPass   = (frameGateCtrl[3:0]==4'h0);
  Bool frameGate = (frameGateCtrl[3:0]==4'h1);

rule operating_actions (wci.isOperating);
  wsiS.operate();
  wsiM.operate();
endrule

rule wsipass_doMessagePush (wci.isOperating && wsiPass);   // This rule allows the wsiPass function, bypassing the frameGate
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
  //$display("[%0d]: %m: wsipass_doMessagePush ", $time);
endrule

rule wmwt_mesgBegin (wci.isOperating && frameGate && !isValid(opcode));
  opcode <= tagged Valid wsiS.reqPeek.reqInfo;
endrule

rule wmwt_messagePushImprecise (wci.isOperating && frameGate &&& opcode matches tagged Valid .op);
  WsiReq#(12,nd,nbe,8,0) w <- wsiS.reqGet.get;
  Bool dwm = (w.burstLength==1);                   // Imprecise WSI ends with burstLength==1, used to make WMI DWM
  Bool zlm = dwm && (w.byteEn=='0);                // Zero Length Message is 0 BEs on DWM 
  Bool eof = !gated && wordsThisFrame==frameSize;  // EOF detection
  Bool eog =  gated && wordsGated==gateSize;       // EOG detection
  gated <= eof || (gated && !eog);                 // Set gated at EOF, Clear gated at EOG
  case op
    0: begin
      if (!gated) begin
        wsiM.reqPut.put(w);
        wordsThisFrame <= (eof) ? 0 : wordsThisFrame + 1;
        if (eof) op0MesgCnt <= op0MesgCnt + 1;
      end else begin
        wordsGated     <= (eog) ? 0 : wordsGated + 1;
      end
    end
    default : begin
      wsiM.reqPut.put(w);
      if (dwm) otherMesgCnt <= otherMesgCnt + 1;
    end
  endcase
endrule

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

Bit#(32) frameGateStatus = extend({pack(hasDebugLogic)});

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(frameGateStatus);
     'h04 : rdat = pack(frameGateCtrl);
     'h08 : rdat = pack(frameSize);
     'h0C : rdat = pack(gateSize);
      if (hasDebugLogic) begin
        'h10 : rdat = extend({pack(wsiS.status),pack(wsiM.status)});
        'h14 : rdat = pack(wsiS.extStatus.pMesgCount);
        'h18 : rdat = pack(wsiS.extStatus.iMesgCount);
        'h1C : rdat = pack(wsiS.extStatus.tBusyCount);
        'h20 : rdat = pack(wsiM.extStatus.pMesgCount);
        'h24 : rdat = pack(wsiM.extStatus.iMesgCount);
        'h28 : rdat = pack(wsiM.extStatus.tBusyCount);
        'h2C : rdat = extend(pack(op0MesgCnt));
        'h30 : rdat = extend(pack(otherMesgCnt));
      end
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting DelayWorker dlyCtrl:%0x", $time, dlyCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wci_Es#(NwciAddr)       wci_Es    <- mkWciStoES(wci.slv); 
  Wsi_Es#(12,nd,nbe,8,0)  wsi_Es    <- mkWsiStoES(wsiS.slv);

  interface wciS0  = wci_Es;
  interface wsiS1  = wsi_Es;
  interface wsiM1  = toWsiEM(wsiM.mas);
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef FrameGateIfc#(1) FrameGate4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate4B#(parameter Bit#(32) fgCtrlInit) (FrameGate4BIfc);
  FrameGate4BIfc _a <- mkFrameGate(fgCtrlInit); return _a;
endmodule

typedef FrameGateIfc#(2) FrameGate8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate8B#(parameter Bit#(32) fgCtrlInit) (FrameGate8BIfc);
  FrameGate8BIfc _a <- mkFrameGate(fgCtrlInit); return _a;
endmodule

typedef FrameGateIfc#(4) FrameGate16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate16B#(parameter Bit#(32) fgCtrlInit) (FrameGate16BIfc);
  FrameGate16BIfc _a <- mkFrameGate(fgCtrlInit); return _a;
endmodule

typedef FrameGateIfc#(8) FrameGate32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFrameGate32B#(parameter Bit#(32) fgCtrlInit) (FrameGate32BIfc);
  FrameGate32BIfc _a <- mkFrameGate(fgCtrlInit); return _a;
endmodule

