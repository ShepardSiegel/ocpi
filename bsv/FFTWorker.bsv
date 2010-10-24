// FFTWorker.bsv - A worker containter for the FFT core
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED


// TODO: Initially hardcoded for 2K Complex FFT (2K X 4B I/Q) = 8KB Payload

import OCWip::*;
import FFT::*;
import WsiToPrecise::*;

import Alias::*;
import Complex::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits
typedef enum {PsdPass, PsdPrecise, PsdFFT, PsdSpare} FFTMode deriving (Bits, Eq);  // FFT mode bits in fftCtrl[1:0]

interface FFTWorkerIfc;
  interface WciOcp_Es#(NwciAddr)     wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,32,4,8,0)     wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,32,4,8,0)     wsiM0;    // WSI-M Stream Output
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFFTWorker#(parameter Bit#(32) fftCtrlInit, parameter Bool hasDebugLogic) (FFTWorkerIfc);

  WciOcpSlaveIfc #(NwciAddr)         wci         <- mkWciOcpSlave;
  WsiSlaveIfc #(12,32,4,8,0)         wsiS        <- mkWsiSlave;
  WsiToPreciseGPIfc#(1)              w2p         <- mkWsiToPreciseGP;
  WsiMasterIfc#(12,32,4,8,0)         wsiM        <- mkWsiMaster;
  Reg#(Bit#(32))                     fftCtrl     <- mkReg(fftCtrlInit);
  FFTIfc                             fft         <- mkFFT;
  Reg#(UInt#(16))                    unloadCnt   <- mkReg(0);
  FIFOF#(Bit#(32))                   xnF         <- mkFIFOF;

  FFTMode pmod = unpack(fftCtrl[1:0]);
  Bool fromOffsetBin = unpack(fftCtrl[4]);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions (wci.isOperating);
  wsiS.operate(); wsiM.operate(); w2p.operate();
endrule

//////////////////////////////////////////////////////// Pass
rule fftPass_bypass (wci.isOperating && pmod==PsdPass);
  WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
endrule

//////////////////////////////////////////////////////// Precise || FFT
rule fftPrecise_input (wci.isOperating && (pmod==PsdPrecise||pmod==PsdFFT));
  WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;
  w2p.putWsi.put(r);
endrule

rule fftPrecise_output_bypassFFT (wci.isOperating && pmod==PsdPrecise);
  WsiReq#(12,32,4,8,0) r <- w2p.getWsi.get;
  wsiM.reqPut.put(r); // bypass the FFT
endrule

rule fftPrecise_output_feedFFT (wci.isOperating && pmod==PsdFFT);
  WsiReq#(12,32,4,8,0) r <- w2p.getWsi.get;
  xnF.enq(r.data);    // feed the FFT xnF
endrule

//////////////////////////////////////////////////////// FFT
rule fftFFT_doIngress (wci.isOperating && pmod==PsdFFT);             // rule will fire 2K times per frame
  fft.putXn.put(Complex{rel:xnF.first[15:0], img:xnF.first[31:16]}); // put 2K complex, little-endian time-domain samples
  xnF.deq;                                                           // 2K DEQs per frame
endrule

rule fftFFT_doEgress (wci.isOperating && pmod==PsdFFT);
  Cmp16 xk  = fft.fifoXk.first;
  Int#(16) xkRel = unpack(xk.rel);                                 // Signed 16b I FFT Outout
  Int#(16) xkImg = unpack(xk.img);                                 // Signed 16b Q FFT Outout
  Bool lastWord = (unloadCnt == 2047);                            // Hardcoded to 2K Transform
  else begin
    wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                             reqLast : lastWord,
                             reqInfo : 0,
                        burstPrecise : True,
                         burstLength : 2048, // 4B words =  8KB      Hardcoded to 2K Transform 
                               data  : {pack(xkImg), pack(xkRel)},
                             byteEn  : '1,
                           dataInfo  : '0 });
  end
  fft.fifoXk.deq;                                                  // 2K FFT unloads
  unloadCnt <= (lastWord) ? 0 : unloadCnt + 1;
endrule



//
// WCI...
//

Bit#(32) fftStatus = extend({pack(hasDebugLogic)});

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h04 : fftCtrl <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(fftStatus);
     'h04 : rdat = pack(fftCtrl);
     'h10 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
     'h14 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
     'h18 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
     'h1C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
     'h20 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
     'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
     'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
     'h2C : rdat = !hasDebugLogic ? 0 : fft.fftFrameCounts;
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:OK, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting FFTWorker fftCtrl:%0x", $time, fftCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  WciOcp_Es#(NwciAddr)     wci_Es    <- mkWciOcpStoES(wci.slv); 
  Wsi_Es#(12,32,4,8,0)     wsi_Es    <- mkWsiStoES(wsiS.slv);

  interface wciS0  = wci_Es;
  interface wsiS0  = wsi_Es;
  interface wsiM0 = toWsiEM(wsiM.mas); 
endmodule

