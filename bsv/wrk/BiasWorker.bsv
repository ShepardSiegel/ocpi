// BiasWorker.bsv 
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Connectable::*;
import GetPut::*;
import Vector::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits

interface BiasWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM0;    // WSI-M Stream Output
endinterface 

module mkBiasWorker#(parameter Bool hasDebugLogic) (BiasWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                  wci          <- mkWciESlave;     // WCI-Slave  convienenice logic
  WsiSlaveIfc #(12,nd,nbe,8,0)  wsiS         <- mkWsiSlave;      // WSI-Slave  convienenice logic
  WsiMasterIfc#(12,nd,nbe,8,0)  wsiM         <- mkWsiMaster;     // WSI-Master convienenice logic
  Reg#(Bit#(32))                biasValue    <- mkRegU;          // storage for the biasValue
  Reg#(Bit#(32))                controlReg   <- mkRegU;          // storage for the controlReg

  // This rule inhibits dataflow on the WSI ports until the WCI port isOperating...
  rule operating_actions (wci.isOperating);
    wsiS.operate();
    wsiM.operate();
  endrule
  
  // Each firing of this rule processes exactly one word and applies the biasValue...
  // Note that no change to the byte-enables takes place; and bias is oblivious to their state
  rule doMessagePush (wci.isOperating);
    WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;   // get the request from the slave-cosumer
    r.data = r.data + extend(biasValue);           // apply the biasValue to the data
    wsiM.reqPut.put(r);                            // put the request to the master-producer
  endrule

  // Control and Configuration operations...
  
  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)
  
  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
     case (wciReq.addr[7:0]) matches
       'h00 : biasValue  <= unpack(wciReq.data);
       'h04 : controlReg <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(biasValue);
       'h04 : rdat = pack(controlReg);
       // Diagnostic data from WSI slabe and master ports...
       'h20 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
       'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
       'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
       'h2C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
       'h30 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
       'h34 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
       'h38 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
     wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  endrule
  
  // This rule contains the operations that take place in the Exists->Initialized control edge...
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
    biasValue  <= 0; // initialize bias value to zero
    controlReg <= 0; // initialize control register to zero
    wci.ctlAck;      // acknowledge the initialization operation
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,nd,nbe,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 

  // Interfaces provided...
  interface wciS0 = wci.slv;
  interface wsiS0 = wsi_Es;
  interface wsiM0 = toWsiEM(wsiM.mas);

endmodule: mkBiasWorker

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef BiasWorkerIfc#(1) BiasWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkBiasWorker4B#(parameter Bool hasDebugLogic) (BiasWorker4BIfc);
  BiasWorker4BIfc _a <- mkBiasWorker(hasDebugLogic); return _a;
endmodule

typedef BiasWorkerIfc#(2) BiasWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkBiasWorker8B#(parameter Bool hasDebugLogic) (BiasWorker8BIfc);
  BiasWorker8BIfc _a <- mkBiasWorker(hasDebugLogic); return _a;
endmodule

typedef BiasWorkerIfc#(4) BiasWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkBiasWorker16B#(parameter Bool hasDebugLogic) (BiasWorker16BIfc);
  BiasWorker16BIfc _a <- mkBiasWorker(hasDebugLogic); return _a;
endmodule

typedef BiasWorkerIfc#(8) BiasWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkBiasWorker32B#(parameter Bool hasDebugLogic) (BiasWorker32BIfc);
  BiasWorker32BIfc _a <- mkBiasWorker(hasDebugLogic); return _a;
endmodule

