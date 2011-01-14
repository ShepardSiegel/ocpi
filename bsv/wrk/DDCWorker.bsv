// DDCWorker - Four DDC channels
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import DDC::*;

import Alias::*;
import Complex::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits
typedef enum {DDCPass, DDCEnable, DDCSpare2, DDCSpare3} DDCMode deriving (Bits, Eq);  // DDC mode bits in ddcCtrl[1:0]

interface DDCWorkerIfc;
  interface WciES                    wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,32,4,8,0)     wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,32,4,8,0)     wsiM0;    // WSI-M Stream Output
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDDCWorker#(parameter Bit#(32) ddcCtrlInit, parameter Bool hasDebugLogic) (DDCWorkerIfc);

  WciESlaveIfc                wci                 <- mkWciESlave;
  WsiSlaveIfc #(12,32,4,8,0)  wsiS                <- mkWsiSlave;
  WsiMasterIfc#(12,32,4,8,0)  wsiM                <- mkWsiMaster;
  Reg#(Bit#(32))              ddcCtrl             <- mkReg(ddcCtrlInit);
  DDCIfc                      ddc                 <- mkDDC;
  FIFOF#(Bit#(32))            xnF                 <- mkFIFOF;
  Reg#(Bool)                  takeEven            <- mkReg(True); // start with 0
  Reg#(UInt#(16))             unloadCnt           <- mkReg(0);
  Reg#(Bool)                  splitWriteInFlight  <- mkReg(False); 
  Reg#(Bool)                  splitReadInFlight   <- mkReg(False); 
  Reg#(Bit#(32))              ambaWrReqCnt        <- mkReg(0);
  Reg#(Bit#(32))              ambaRdReqCnt        <- mkReg(0);
  Reg#(Bit#(32))              ambaRespCnt         <- mkReg(0);
  Reg#(Bit#(32))              ambaErrCnt          <- mkReg(0);
  Reg#(Bit#(32))              outMesgCnt          <- mkReg(0);

  DDCMode pmod = unpack(ddcCtrl[1:0]);
  Bool fromOffsetBin = unpack(ddcCtrl[4]);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsiS.operate(); wsiM.operate();
endrule

rule ddcPass_bypass (wci.isOperating && pmod==DDCPass);
  WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
endrule

rule ddcEnable_output_feedDDC (wci.isOperating && pmod==DDCEnable);
  WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;
  xnF.enq(r.data);    // feed the DDC xnF
endrule

// The following rule predicate uses the !wsiM.status.partnerReset to ensure data can move downstream
// Since the DDC core's output does not allow any backpressure; we do not want to start any ingress unless we are
// sure the downconverted data has a uninhibited path out. This is necessary to allow workers to start in any order.
rule ddcEnable_doIngress (wci.isOperating && pmod==DDCEnable && !wsiM.status.partnerReset);
  Bit#(32) d32   = xnF.first;
  Bit#(16) dReal = (takeEven) ? d32[15:0] : d32[31:16]; // little-endian: first, even sample at LS word
  ddc.putXn.put(dReal);
  if (!takeEven) xnF.deq;
  takeEven <= !takeEven;
endrule

rule ddcEnable_doEgress (wci.isOperating && pmod==DDCEnable);
  Cmp16 xk  = ddc.fifoXk.first;
  Int#(16) xkRel = unpack(xk.rel);                                 // Signed 16b I FFT Outout
  Int#(16) xkImg = unpack(xk.img);                                 // Signed 16b Q FFT Outout
  Bool lastWord = (unloadCnt == 2047);                             // Hardcoded to 8KB output 
  wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                           reqLast : lastWord,
                           reqInfo : 0,
                      burstPrecise : True,
                       burstLength : 2048,                         // 2K 4B words =  8KB
                             data  : {pack(xkImg), pack(xkRel)},   // Little-Endian I/Q (Real in 15:0)
                           byteEn  : '1,
                         dataInfo  : '0 });
  ddc.fifoXk.deq;                                                  
  unloadCnt <= (lastWord) ? 0 : unloadCnt + 1;
  if (lastWord)  outMesgCnt <= outMesgCnt + 1;
endrule


  //
  // WCI...
  //

  Bit#(32) ddcStatus = extend({pack(ddc.ddcint), 3'b0, pack(hasDebugLogic)});

  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, advance_wci_response" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

  rule advance_wci_response (!wci.configWrite);
    let resp <- ddc.getApb.get;  // AMBA3 provides responses for both write and read, we only support read here
    if (splitWriteInFlight) splitWriteInFlight <= False;
    if (splitReadInFlight)  splitReadInFlight  <= False;
    wci.respPut.put(resp.isError ? wciErrorResponse : (splitWriteInFlight) ? wciOKResponse : WciResp{resp:DVA, data:resp.data});
    if (resp.isError) ambaErrCnt  <= ambaErrCnt  + 1;
    else              ambaRespCnt <= ambaRespCnt + 1;
  endrule

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   Bool splitWrite = False;
   let wciReq <- wci.reqGet.get;
   if(wciReq.addr[12]==0) begin
     case (wciReq.addr) matches
       'h04 : ddcCtrl <= unpack(wciReq.data);
     endcase
   end else begin
     ddc.putApb.put(AMBA3APBReq {isWrite:True, isError:False, addr:truncate(wciReq.addr), data:wciReq.data});
     ambaWrReqCnt <= ambaWrReqCnt + 1;
     splitWrite = True;
   end
     //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
     //if (!splitWrite) wci.respPut.put(wciOKResponse); // write response
     //else splitWriteInFlight <= True;
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   Bool splitRead = False;
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   if(wciReq.addr[12]==0) begin
     case (wciReq.addr) matches
       'h00 : rdat = pack(ddcStatus);
       'h04 : rdat = pack(ddcCtrl);
       'h10 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
       'h14 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
       'h18 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
       'h1C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
       'h20 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
       'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
       'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
       'h2C : rdat = !hasDebugLogic ? 0 : pack(ambaWrReqCnt);
       'h30 : rdat = !hasDebugLogic ? 0 : pack(ambaRdReqCnt);
       'h34 : rdat = !hasDebugLogic ? 0 : pack(ambaRespCnt);
       'h38 : rdat = !hasDebugLogic ? 0 : pack(ambaErrCnt);
       'h3C : rdat = !hasDebugLogic ? 0 : pack(outMesgCnt);
     endcase
   end else begin
     ddc.putApb.put(AMBA3APBReq {isWrite:False, isError:False, addr:truncate(wciReq.addr), data:?});
     ambaRdReqCnt <= ambaRdReqCnt + 1;
     splitRead = True;
   end
     //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, rdat);
     if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
     else splitReadInFlight <= True;
  endrule
  
  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
    wci.ctlAck;
    $display("[%0d]: %m: Starting DDC ddcCtrl:%0x", $time, ddcCtrl);
    endrule
  
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule
  
  Wsi_Es#(12,32,4,8,0)     wsi_Es    <- mkWsiStoES(wsiS.slv);

  interface wciS0  = wci.slv;
  interface wsiS0  = wsi_Es;
  interface wsiM0 = toWsiEM(wsiM.mas); 
endmodule

