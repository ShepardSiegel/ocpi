// BiasWorker.bsv - Stripped Down 4B Example Version
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Connectable::*;
import GetPut::*;
import Vector::*;

interface BiasWorker4BIfc;
  interface Wci_Es#(20)           wciS0;  // WCI Slave  for Control and Configuration
  interface Wsi_Es#(12,32,4,8,1)  wsiS1;  // WSI Slave  for message ingress (consumer port)
  interface Wsi_Em#(12,32,4,8,1)  wsiM1;  // WSI Master for message egress (producer port)
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkBiasWorker (BiasWorker4BIfc);
  WciSlaveIfc#(20)              wci          <- mkWciSlave;   // WCI-Slave  convienenice logic
  WsiSlaveIfc #(12,32,4,8,1)    wsiS         <- mkWsiSlave;    // WSI-Slave  convienenice logic
  WsiMasterIfc#(12,32,4,8,1)    wsiM         <- mkWsiMaster;   // WSI-Master convienenice logic
  Reg#(Bit#(32))                biasValue    <- mkRegU;        // storage for the biasValue
  Reg#(Bit#(32))                controlReg   <- mkRegU;        // storage for the controlReg

  // This rule inhibits dataflow on the WSI ports until the WCI port isOperating...
  rule operating_actions (wci.isOperating);
    wsiS.operate();
    wsiM.operate();
  endrule
  
  // Each firing of this rule processes exactly one word and applies the biasValue...
  rule doMessagePush (wci.isOperating);
    WsiReq#(12,32,4,8,1) r <- wsiS.reqGet.get;     // get the request from the slave-cosumer
    r.data = r.data + biasValue;                   // apply the biasValue to the data
    wsiM.reqPut.put(r);                            // put the request to the master-producer
  endrule

  // Control and Configuration operations...
  
  (* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)
  
  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
     case (wciReq.addr[7:0]) matches
       'h00 : biasValue  <= unpack(wciReq.data);
       'h04 : controlReg <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
       $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(biasValue);
       'h04 : rdat = pack(controlReg);
       // Diagnostic data from WSI slabe and master ports...
       //'h20 : rdat = extend({pack(wsiS.status),pack(wsiM.status)});
       //'h24 : rdat = pack(wsiS.extStatus.pMesgCount);
       //'h28 : rdat = pack(wsiS.extStatus.iMesgCount);
       //'h2C : rdat = pack(wsiS.extStatus.tBusyCount);
       //'h30 : rdat = pack(wsiM.extStatus.pMesgCount);
       //'h34 : rdat = pack(wsiM.extStatus.iMesgCount);
       //'h38 : rdat = pack(wsiM.extStatus.tBusyCount);
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
       $time, wciReq.addr, wciReq.byteEn, rdat);
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


  Wci_Es#(20)          wci_Es <- mkWciStoES(wci.slv);  // Convert the conventional to explicit 
  Wsi_Es#(12,32,4,8,1) wsi_Es <- mkWsiStoES(wsiS.slv); // Convert the conventional to explicit 

  // Interfaces provided...
  interface wciS0 = wci_Es;
  interface wsiS1 = wsi_Es;                     // And use it here
  interface wsiM1 = toWsiEM(wsiM.mas);

endmodule: mkBiasWorker
