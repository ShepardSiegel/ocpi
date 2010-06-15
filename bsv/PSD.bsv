// PSD.bsv - Power Spectral Density 
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

/*

This Module-Worker implements a Power Spectal Density (PSD) function.
Assumptions:
 A1. Input Samples presented two 16b samples per cycle at nominally 125 MHz (250 MSPS)
 A2. Fixed 4K (2^12) Transform Buffer Size
 A3. FPGA Vendor supplied Forward FFT Core Wrapped, pipelined, streaming, nominally 125MHz*2 = 250 MHz Core Clock
 A4: Fixed Power Vector Frame Averaging of N=4

Cascade of Operations:

1. Precise Frame Formatting, WsiToPrecise (4K sample 2-buffer)
  Format an imprecise-burst of time-domain samples from a prior stage into a precisely-sized message buffer.
  This is done as a processing convienience using a 2-buffered BRAM. One buffer may be written while the other
  is read. The utility is that the read side logic can be sure all 4K samples may be read at once, without interruption.

2. Windowing of Time-Domain Data 
  Prior to the forward FFT, the real input data is windowed with a raised-cosine (Hamming) function to balance spectral
  leakage against sensitivity in the finite length transform to follow. The windowing implementation typically is
  multiplying two adjacent time samples per clock cycle. 2 x 125 = 250 MSPS

3. Gear Shift 125MHz to 250 MHz
  Two samples per cycle at 125 MHz are converted to One sample per cycle at 250 MHz

4. 4K Streaming, Pipelined, Forward FFT, Natural Ordered Output
  Implemented by wrapping a FPGA Vendor Core (eg fft-v5-4k-stream-natural) Core operates at 250 MHz nominal.
  The output of the FFT core is a naturally ordered (F-bin 0, 1, 2, ..., 4095) vector of fixed-point complex numbers.

5. Magnitude Approximation
  The magnitude of each complex number is approximated by folding all data into the first-quadrant |i|+|q| and then using 
  a technique described by Lyons to estimate magnitude to within 1 dB. The input to this stage are 250 MSPS complex numbers; 
  the output are 250 MSPS unsigned magnitudes. Each vector of 4096 magnitudes is termed a "Power Vector Frame".

6. Power Vector Frame Averaging
  Each Power Vector Frame is added into a power vector frame accumulator until the four frames have been accumulated. Then
  the result is shifted down by two to yield a N=4 Power Vector Frame Average. This is implemented at 250 MHz.

7. Output Formating
  The PSD Output is then a 8KB message containing the 4096 16b unsigned entries of the N=4 averaged power vector frame.
  This step includes the Gear Shift from 16b 250 MHz (250 MSPS) to 32b 125 MHz (250 MSPS).

*/

import OCWip::*;

import Alias::*;
import Connectable::*;
import GetPut::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface PSDIfc;
  interface Wci_Es#(NwciAddr)        wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,32,4,8,0)     wsiS1;    // WSI-S Stream Input
  interface Wsi_Em#(12,32,4,8,0)     wsiM1;    // WSI-M Stream Output
  //interface Wmi_Em#(14,12,32,0,4,32) wmiM;     // WSI-M Message Output
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkPSD#(parameter Bit#(32) psdCtrlInit, parameter Bool hasDebugLogic) (PSDIfc);

  WciSlaveIfc #(NwciAddr)            wci        <- mkWciSlave;
  WsiSlaveIfc #(12,32,4,8,0)         wsiS       <- mkWsiSlave;
  WsiMasterIfc#(12,32,4,8,0)         wsiM        <- mkWsiMaster;
  //WmiMasterIfc#(14,12,32,0,4,32)     wmi        <- mkWmiMaster;
  Reg#(Bit#(32))                     psdCtrl    <- mkReg(psdCtrlInit);

rule operating_actions (wci.isOperating);
  wsiS.operate();
  wsiM.operate();
  //wmiM.operate();
endrule

rule wsipass_doMessagePush (wci.isOperating);
  WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
endrule





//
// WCI...
//

Bit#(32) psdStatus = extend({pack(hasDebugLogic)});

(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h04 : psdCtrl <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(psdStatus);
     'h04 : rdat = pack(psdCtrl);
     'h10 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
     'h14 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
     'h18 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
     'h1C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
     'h20 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
     'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
     'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
  $display("[%0d]: %m: Starting PSD psdCtrl:%0x", $time, psdCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wci_Es#(NwciAddr)        wci_Es    <- mkWciStoES(wci.slv); 
  Wsi_Es#(12,32,4,8,0)     wsi_Es    <- mkWsiStoES(wsiS.slv);
  //Wmi_Em#(14,12,32,0,4,32) wmi_Em <- mkWmiMtoEm(wmi.mas);

  interface wciS0  = wci_Es;
  interface wsiS1  = wsi_Es;
  interface wsiM1 = toWsiEM(wsiM.mas); 
  //interface wmiM   = wmi_Em;
endmodule

