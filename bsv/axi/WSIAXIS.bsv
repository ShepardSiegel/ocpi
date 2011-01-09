// WSIAXIS.bsv - Unidirectional Adapters between WSI and AXI4-Stream
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package WSIAXIS;

import ARAXI4S::*;
import OCWip::*;

import Bus::*;
import FIFO::*;	
import GetPut::*;

// The modules below adapt between WSI and AXI-Stream (AXIS)
// They use the established WSI convienience IP mkWsi{Master|Slave}, 
// bit implement "in-place" the AXIfication, as the AXI spec can be volatile.
// At some point, the AXI side could be moved to a mkAXIStream{Master|Slave} convienience IP.
// For now, it is right here.

interface WSItoAXIS32BIfc;
  interface WsiES32B  wsi;  // WSI-Slave 
  interface A4SEM32B  axi;  // AXI4-Stream Master
endinterface 

(* synthesize *)
module mkWSItoAXIS32B (WSItoAXIS32BIfc);
  WsiSlaveIfc#(12,256,32,8,0)      wsiS  <- mkWsiSlave;
  BusSender#(A4Stream#(256,32,0))  a4ms  <- mkBusSender(aStrmDflt);

  A4StreamMIfc#(256,32,0) axisM = A4StreamMIfc { strm : a4ms.out};  // Place strm sub-interface in axisM interface

  rule operate_action; wsiS.operate(); endrule

  rule advance_data;
    WsiReq#(12,256,32,8,0) w <- wsiS.reqGet.get;
    a4ms.in.enq( A4Stream { data : w.data,
                            strb : w.byteEn,
                            keep : 0,
                            last : w.reqLast });
  endrule

  Wsi_Es#(12,256,32,8,0)     wsi_Es <- mkWsiStoES(wsiS.slv);
  A4S_Em#(256,32,0)          axi_Em <- mkA4StreamMtoEm(axisM);
  interface WsiES32B  wsi = wsi_Es;
  interface A4SEM32B  axi = axi_Em;
endmodule


interface AXIStoWSI32BIfc;
  interface A4SES32B  axi;  // AXI4-Stream Slave 
  interface WsiEM32B  wsi;  // WSI-Master
endinterface 

(* synthesize *)
module mkAXIStoWSI32B (AXIStoWSI32BIfc);
  BusReceiver#(A4Stream#(256,32,0))  a4ss  <- mkBusReceiver;
  WsiMasterIfc#(12,256,32,8,0)       wsiM  <- mkWsiMaster;

  A4StreamSIfc#(256,32,0) axisS = A4StreamSIfc { strm : a4ss.in};  // Place strm sub-interface in axisS interface

  rule operate_action; wsiM.operate(); endrule

  rule advance_data;
    let a = a4ss.out.first; 
    a4ss.out.deq;
    wsiM.reqPut.put( WsiReq {   cmd  : WR,
                             reqLast : a.last,
                             reqInfo : 0,
                        burstPrecise : False,
                         burstLength : (a.last) ? 1 : '1,
                               data  : a.data,
                             byteEn  : a.strb,
                           dataInfo  : '0 });
  endrule

  A4S_Es#(256,32,0) axi_Es <- mkA4StreamStoEs(axisS);
  interface A4SES32B  axi = axi_Es;
  interface WsiEM32B  wsi = toWsiEM(wsiM.mas);
endmodule

endpackage
