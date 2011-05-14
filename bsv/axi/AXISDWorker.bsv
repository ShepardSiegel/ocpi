// AXISDWorker.bsv - A Device worker to allow AXI4-Stream (AXIS)Interoperability
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import ARAXI4S::*;
import WSIAXIS::*;

import Connectable::*;
import FIFO::*;
import GetPut::*;
import Vector::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface AXISDWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM0;    // WSI-M Stream Output
  interface A4S_Em#(TMul#(ndw,32),TMul#(ndw,4),0,128)   axiM0;    // AXIS-M Stream Output
  interface A4S_Es#(TMul#(ndw,32),TMul#(ndw,4),0,128)   axiS0;    // AXIS-S Stream Input
endinterface 

module mkAXISDWorker#(parameter Bool hasDebugLogic) (AXISDWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)), Add#(ndw,0,1));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                  wci            <- mkWciESlave;     // WCI-Slave  convienenice logic
  WsiSlaveIfc #(12,nd,nbe,8,0)  wsiS           <- mkWsiSlave;      // WSI-Slave  convienenice logic
  WsiMasterIfc#(12,nd,nbe,8,0)  wsiM           <- mkWsiMaster;     // WSI-Master convienenice logic
  WSItoAXIS4BIfc                axiM           <- mkWSItoAXIS4B;   // AXI-S Master logic
  AXIStoWSI4BIfc                axiS           <- mkAXIStoWSI4B;   // AXI-S Slave  logic
  Reg#(Bit#(32))                spareValue     <- mkRegU;          // storage for the spareValue
  Reg#(Bit#(32))                controlReg     <- mkRegU;          // storage for the controlReg
  Reg#(Bit#(32))                bypassCount    <- mkReg(0); 
  Reg#(Bit#(32))                axiSendCount   <- mkReg(0); 
  Reg#(Bit#(32))                axiRecvCount   <- mkReg(0);

  Bool useAXI = unpack(controlReg[0]);

  // This rule inhibits dataflow on the WSI and AXIS ports until the WCI port isOperating...
  rule operating_actions (wci.isOperating);
    wsiS.operate(); wsiM.operate(); axiM.operate(); axiS.operate();
  endrule

  // The Data Path...
  (* mutually_exclusive = "doMessageBypass, doMessageAXIsend" *)
  (* mutually_exclusive = "doMessageBypass, doMessageAXIrecv" *)

  rule doMessageBypass (wci.isOperating && !useAXI);
    WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;          // take from WSI-S
    wsiM.reqPut.put(r);                                 // send to   WSI-M
    bypassCount <= bypassCount + 1;
  endrule
  
  rule doMessageAXIsend (wci.isOperating && useAXI);
    WsiReq#(12,32,4,8,0) r <- wsiS.reqGet.get;          // take from WSI-S
    axiM.reqPut.put(r);                                 // send to   AXI-M
    axiSendCount <= axiSendCount + 1;
  endrule
  
  rule doMessageAXIrecv (wci.isOperating && useAXI);
    WsiReq#(12,32,4,8,0) r <- axiS.reqGet.get;          // take from AXI-S
    wsiM.reqPut.put(r);                                 // send to   WSI-M
    axiRecvCount <= axiRecvCount + 1;
  endrule
  
  // Control and Configuration operations...
  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)
  
  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
     case (wciReq.addr[7:0]) matches
       'h00 : spareValue <= unpack(wciReq.data);
       'h04 : controlReg <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(spareValue);
       'h04 : rdat = pack(controlReg);
       // Diagnostic data from WSI slabe and master ports...
       'h20 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
       'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
       'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
       'h2C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
       'h30 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
       'h34 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
       'h38 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
       'h3C : rdat = !hasDebugLogic ? 0 : pack(bypassCount);
       'h40 : rdat = !hasDebugLogic ? 0 : pack(axiSendCount);
       'h44 : rdat = !hasDebugLogic ? 0 : pack(axiRecvCount);
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
     wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  endrule
  
  // This rule contains the operations that take place in the Exists->Initialized control edge...
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
    spareValue  <= 0; // initialize spare value to zero
    controlReg <= 1;  // initialize control register to 32'h0000_0001 to enable useAXI by default
    wci.ctlAck;       // acknowledge the initialization operation
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,nd,nbe,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 

  // Interfaces provided...
  interface wciS0 = wci.slv;
  interface wsiS0 = wsi_Es;
  interface wsiM0 = toWsiEM(wsiM.mas);
  interface A4S_Em axiM0 = axiM.axi;
  interface A4S_Es axiS0 = axiS.axi;

endmodule: mkAXISDWorker

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef AXISDWorkerIfc#(1) AXISDWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkAXISDWorker4B#(parameter Bool hasDebugLogic) (AXISDWorker4BIfc);
  AXISDWorker4BIfc _a <- mkAXISDWorker(hasDebugLogic); return _a;
endmodule

`ifdef NOT_NOW
typedef AXISDWorkerIfc#(2) AXISDWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkAXISDWorker8B#(parameter Bool hasDebugLogic) (AXISDWorker8BIfc);
  AXISDWorker8BIfc _a <- mkAXISDWorker(hasDebugLogic); return _a;
endmodule

typedef AXISDWorkerIfc#(4) AXISDWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkAXISDWorker16B#(parameter Bool hasDebugLogic) (AXISDWorker16BIfc);
  AXISDWorker16BIfc _a <- mkAXISDWorker(hasDebugLogic); return _a;
endmodule

typedef AXISDWorkerIfc#(8) AXISDWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkAXISDWorker32B#(parameter Bool hasDebugLogic) (AXISDWorker32BIfc);
  AXISDWorker32BIfc _a <- mkAXISDWorker(hasDebugLogic); return _a;
endmodule
`endif
