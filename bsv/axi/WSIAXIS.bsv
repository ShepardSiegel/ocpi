// WSIAXIS.bsv - Unidirectional Adapters between WSI and AXI4-Stream
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package WSIAXIS;

import ARAXI4S::*;
import OCWip::*;

import Bus::*;
import FIFO::*;	
import GetPut::*;


//TODO: Consider migrating NF10 stream defintions to a aggregated line the five peer channels of AXI4-Lite
// For now, we have them as five independent streams...

// These next two interfaces are as per the spec in the following wiki link... 
// http://netfpga10g.pbworks.com/w/page/31840959/Standard-IP-Interfaces
interface NF10DPM;
  interface A4SEM32B  dat;    // The AXI-4-Stream Master
  interface A4SEM2B   len;
  interface A4SEM1B   spt;
  interface A4SEM1B   dpt;
  interface A4SEM1B   err;
endinterface

interface NF10DPS;
  interface A4SES32B  dat;    // The AXI-4-Stream Slave
  interface A4SES2B   len;
  interface A4SES1B   spt;
  interface A4SES1B   dpt;
  interface A4SES1B   err;
endinterface


// The modules below adapt between WSI and AXI-Stream (AXIS)
// They use the established WSI convienience IP mkWsi{Master|Slave}, 
// bit implement "in-place" the AXIfication, as the AXI spec can be volatile.
// At some point, the AXI side could be moved to a mkAXIStream{Master|Slave} convienience IP.
// For now, it is right here.

//32B WSI->AXI...
interface WSItoAXIS32BIfc;
  interface WsiES32B  wsi;  // WSI-Slave 
  interface NF10DPM   axi;  // NF10-Specialized AXI4-Stream Master
endinterface 

(* synthesize *)
module mkWSItoAXIS32B (WSItoAXIS32BIfc);
  WsiSlaveIfc#(12,256,32,8,0)      wsiS       <- mkWsiSlave;
  BusSender#(A4S32B)               dat        <- mkBusSender(aStrmDflt);
  BusSender#(A4S2B)                len        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                spt        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                dpt        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                err        <- mkBusSender(aStrmDflt);
  Reg#(Bool)                       firstWord  <- mkReg(True);

  A4StreamMIfc#(256,32,0) axisDatM = A4StreamMIfc { strm : dat.out};  // Place strm sub-interface in axisM interface
  A4StreamMIfc#(16,2,0)   axisLenM = A4StreamMIfc { strm : len.out}; 
  A4StreamMIfc#(8,1,0)    axisSptM = A4StreamMIfc { strm : spt.out}; 
  A4StreamMIfc#(8,1,0)    axisDptM = A4StreamMIfc { strm : dpt.out}; 
  A4StreamMIfc#(8,1,0)    axisErrM = A4StreamMIfc { strm : err.out}; 

  rule operate_action; wsiS.operate(); endrule

  rule advance_data;
    WsiReq#(12,256,32,8,0) w <- wsiS.reqGet.get;
    dat.in.enq( A4Stream {  data : w.data,
                            strb : w.byteEn,
                            keep : 0,
                            last : w.reqLast });
    if (firstWord) begin
      len.in.enq( A4Stream {data:extend(w.burstLength*32), strb:'1, keep:0, last:True});  // LEN is expressed in Bytes
      spt.in.enq( A4Stream {data:8'h10,                    strb:'1, keep:0, last:True});  // PCIe Logical Port 0 as SPT
      dpt.in.enq( A4Stream {data:w.reqInfo,                strb:'1, keep:0, last:True});  // Use reqInfo/opcode for DPT
      err.in.enq( A4Stream {data:0,                        strb:'1, keep:0, last:True});  // TODO: Improve Error Logics
    end
    firstWord <= w.reqLast;
  endrule


  Wsi_Es#(12,256,32,8,0)     wsi_Es    <- mkWsiStoES(wsiS.slv);
  A4S_Em#(256,32,0)          axiDat_Em <- mkA4StreamMtoEm(axisDatM);
  A4S_Em#(16,2,0)            axiLen_Em <- mkA4StreamMtoEm(axisLenM);
  A4S_Em#(8,1,0)             axiSpt_Em <- mkA4StreamMtoEm(axisSptM);
  A4S_Em#(8,1,0)             axiDpt_Em <- mkA4StreamMtoEm(axisDptM);
  A4S_Em#(8,1,0)             axiErr_Em <- mkA4StreamMtoEm(axisErrM);
  interface WsiES32B  wsi = wsi_Es;
  interface NF10DPM axi;
    interface A4SEM32B dat   = axiDat_Em;
    interface A4SEM2B  len   = axiLen_Em;
    interface A4SEM1B  spt   = axiSpt_Em;
    interface A4SEM1B  dpt   = axiDpt_Em;
    interface A4SEM1B  err   = axiErr_Em;
  endinterface
endmodule


//4B WSI->AXI...
interface WSItoAXIS4BIfc;
  interface WsiES4B   wsi;  // WSI-Slave 
  interface NF10DPM   axi;  // NF10-Specialized AXI4-Stream Master
endinterface 

(* synthesize *)
module mkWSItoAXIS4B (WSItoAXIS4BIfc);
  WsiSlaveIfc#(12,32,4,8,0)        wsiS       <- mkWsiSlave;
  BusSender#(A4S32B)               dat        <- mkBusSender(aStrmDflt);
  BusSender#(A4S2B)                len        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                spt        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                dpt        <- mkBusSender(aStrmDflt);
  BusSender#(A4S1B)                err        <- mkBusSender(aStrmDflt);
  Reg#(Bool)                       firstWord  <- mkReg(True);

  A4StreamMIfc#(256,32,0) axisDatM = A4StreamMIfc { strm : dat.out};  // Place strm sub-interface in axisM interface
  A4StreamMIfc#(16,2,0)   axisLenM = A4StreamMIfc { strm : len.out}; 
  A4StreamMIfc#(8,1,0)    axisSptM = A4StreamMIfc { strm : spt.out}; 
  A4StreamMIfc#(8,1,0)    axisDptM = A4StreamMIfc { strm : dpt.out}; 
  A4StreamMIfc#(8,1,0)    axisErrM = A4StreamMIfc { strm : err.out}; 

  rule operate_action; wsiS.operate(); endrule

  rule advance_data;
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;
    dat.in.enq( A4Stream {  data : extend(w.data),
                            strb : extend(w.byteEn),
                            keep : 0,
                            last : w.reqLast });
    if (firstWord) begin
      len.in.enq( A4Stream {data:extend(w.burstLength*32), strb:'1, keep:0, last:True});  // LEN is expressed in Bytes
      spt.in.enq( A4Stream {data:8'h10,                    strb:'1, keep:0, last:True});  // PCIe Logical Port 0 as SPT
      dpt.in.enq( A4Stream {data:w.reqInfo,                strb:'1, keep:0, last:True});  // Use reqInfo/opcode for DPT
      err.in.enq( A4Stream {data:0,                        strb:'1, keep:0, last:True});  // TODO: Improve Error Logics
    end
    firstWord <= w.reqLast;
  endrule


  Wsi_Es#(12,32,4,8,0)       wsi_Es    <- mkWsiStoES(wsiS.slv);
  A4S_Em#(256,32,0)          axiDat_Em <- mkA4StreamMtoEm(axisDatM);
  A4S_Em#(16,2,0)            axiLen_Em <- mkA4StreamMtoEm(axisLenM);
  A4S_Em#(8,1,0)             axiSpt_Em <- mkA4StreamMtoEm(axisSptM);
  A4S_Em#(8,1,0)             axiDpt_Em <- mkA4StreamMtoEm(axisDptM);
  A4S_Em#(8,1,0)             axiErr_Em <- mkA4StreamMtoEm(axisErrM);
  interface WsiES32B  wsi = wsi_Es;
  interface NF10DPM axi;
    interface A4SEM32B dat   = axiDat_Em;
    interface A4SEM2B  len   = axiLen_Em;
    interface A4SEM1B  spt   = axiSpt_Em;
    interface A4SEM1B  dpt   = axiDpt_Em;
    interface A4SEM1B  err   = axiErr_Em;
  endinterface
endmodule


//32B AXI->WSI
interface AXIStoWSI32BIfc;
  interface NF10DPS   axi;  // NF10-Specialized AXI4-Stream Slave
  interface WsiEM32B  wsi;  // WSI-Master
endinterface 

(* synthesize *)
module mkAXIStoWSI32B (AXIStoWSI32BIfc);
  BusReceiver#(A4S32B)          dat        <- mkBusReceiver;
  BusReceiver#(A4S2B)           len        <- mkBusReceiver;
  BusReceiver#(A4S1B)           spt        <- mkBusReceiver;
  BusReceiver#(A4S1B)           dpt        <- mkBusReceiver;
  BusReceiver#(A4S1B)           err        <- mkBusReceiver;
  WsiMasterIfc#(12,256,32,8,0)  wsiM       <- mkWsiMaster;
  Reg#(Bool)                    firstWord  <- mkReg(True);

  A4StreamSIfc#(256,32,0) axisDatS = A4StreamSIfc { strm : dat.in};  // Place strm sub-interface in axisS interface
  A4StreamSIfc#(16,2,0)   axisLenS = A4StreamSIfc { strm : len.in}; 
  A4StreamSIfc#(8,1,0)    axisSptS = A4StreamSIfc { strm : spt.in}; 
  A4StreamSIfc#(8,1,0)    axisDptS = A4StreamSIfc { strm : dpt.in}; 
  A4StreamSIfc#(8,1,0)    axisErrS = A4StreamSIfc { strm : err.in}; 

  rule operate_action; wsiM.operate(); endrule

  rule advance_data;
    Bit#(8) opcodeSPT = 0;
    if (firstWord) begin
      let l = len.out.first; len.out.deq; 
      let s = spt.out.first; spt.out.deq; opcodeSPT = s.data;
      let d = dpt.out.first; dpt.out.deq; // We will ignore the DPT provided
      let e = err.out.first; err.out.deq; // We will ignore the error provided
    end
    let a = dat.out.first; dat.out.deq;
    wsiM.reqPut.put( WsiReq {   cmd  : WR,
                             reqLast : a.last,
                             reqInfo : opcodeSPT,  // put the SPT value into the opcode 
                        burstPrecise : False,
                         burstLength : (a.last) ? 1 : '1,
                               data  : a.data,
                             byteEn  : a.strb,
                           dataInfo  : '0 });
    firstWord <= a.last;
  endrule

  A4S_Es#(256,32,0) axiDat_Es <- mkA4StreamStoEs(axisDatS);
  A4S_Es#(16,2,0)   axiLen_Es <- mkA4StreamStoEs(axisLenS);
  A4S_Es#(8,1,0)    axiSpt_Es <- mkA4StreamStoEs(axisSptS);
  A4S_Es#(8,1,0)    axiDpt_Es <- mkA4StreamStoEs(axisDptS);
  A4S_Es#(8,1,0)    axiErr_Es <- mkA4StreamStoEs(axisErrS);
  interface NF10DPS axi;
    interface A4SES32B dat   = axiDat_Es;
    interface A4SES2B  len   = axiLen_Es;
    interface A4SES1B  spt   = axiSpt_Es;
    interface A4SES1B  dpt   = axiDpt_Es;
    interface A4SES1B  err   = axiErr_Es;
  endinterface
  interface WsiEM32B  wsi = toWsiEM(wsiM.mas);
endmodule

//4B AXI->WSI
interface AXIStoWSI4BIfc;
  interface NF10DPS   axi;  // NF10-Specialized AXI4-Stream Slave
  interface WsiEM4B   wsi;  // WSI-Master
endinterface 

(* synthesize *)
module mkAXIStoWSI4B (AXIStoWSI4BIfc);
  BusReceiver#(A4S32B)          dat        <- mkBusReceiver;
  BusReceiver#(A4S2B)           len        <- mkBusReceiver;
  BusReceiver#(A4S1B)           spt        <- mkBusReceiver;
  BusReceiver#(A4S1B)           dpt        <- mkBusReceiver;
  BusReceiver#(A4S1B)           err        <- mkBusReceiver;
  WsiMasterIfc#(12,32,4,8,0)    wsiM       <- mkWsiMaster;
  Reg#(Bool)                    firstWord  <- mkReg(True);

  A4StreamSIfc#(256,32,0) axisDatS = A4StreamSIfc { strm : dat.in};  // Place strm sub-interface in axisS interface
  A4StreamSIfc#(16,2,0)   axisLenS = A4StreamSIfc { strm : len.in}; 
  A4StreamSIfc#(8,1,0)    axisSptS = A4StreamSIfc { strm : spt.in}; 
  A4StreamSIfc#(8,1,0)    axisDptS = A4StreamSIfc { strm : dpt.in}; 
  A4StreamSIfc#(8,1,0)    axisErrS = A4StreamSIfc { strm : err.in}; 

  rule operate_action; wsiM.operate(); endrule

  rule advance_data;
    Bit#(8) opcodeSPT = 0;
    if (firstWord) begin
      let l = len.out.first; len.out.deq; 
      let s = spt.out.first; spt.out.deq; opcodeSPT = s.data;
      let d = dpt.out.first; dpt.out.deq; // We will ignore the DPT provided
      let e = err.out.first; err.out.deq; // We will ignore the error provided
    end
    let a = dat.out.first; dat.out.deq;
    wsiM.reqPut.put( WsiReq {   cmd  : WR,
                             reqLast : a.last,
                             reqInfo : opcodeSPT,  // put the SPT value into the opcode 
                        burstPrecise : False,
                         burstLength : (a.last) ? 1 : '1,
                               data  : truncate(a.data),
                             byteEn  : truncate(a.strb),
                           dataInfo  : '0 });
    firstWord <= a.last;
  endrule

  A4S_Es#(256,32,0) axiDat_Es <- mkA4StreamStoEs(axisDatS);
  A4S_Es#(16,2,0)   axiLen_Es <- mkA4StreamStoEs(axisLenS);
  A4S_Es#(8,1,0)    axiSpt_Es <- mkA4StreamStoEs(axisSptS);
  A4S_Es#(8,1,0)    axiDpt_Es <- mkA4StreamStoEs(axisDptS);
  A4S_Es#(8,1,0)    axiErr_Es <- mkA4StreamStoEs(axisErrS);
  interface NF10DPS axi;
    interface A4SES32B dat   = axiDat_Es;
    interface A4SES2B  len   = axiLen_Es;
    interface A4SES1B  spt   = axiSpt_Es;
    interface A4SES1B  dpt   = axiDpt_Es;
    interface A4SES1B  err   = axiErr_Es;
  endinterface
  interface WsiEM4B  wsi = toWsiEM(wsiM.mas);
endmodule

endpackage
