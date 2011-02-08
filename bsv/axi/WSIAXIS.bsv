// WSIAXIS.bsv - Unidirectional Adapters between WSI and AXI4-Stream
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package WSIAXIS;

import ARAXI4S::*;
import OCWip::*;

import Bus::*;
import FIFO::*;	
import GetPut::*;

// Shorthand used in this module...
typedef A4Stream#(32,4,0,32) NF10DPM4B;
typedef A4S_Em  #(32,4,0,32) NF10DPEM4B;
typedef A4Stream#(32,4,0,8)  NF10DPS4B;
typedef A4S_Es  #(32,4,0,8)  NF10DPES4B;

// The modules below adapt between WSI and AXI-Stream (AXIS)
// They use the established WSI convienience IP mkWsi{Master|Slave}, 
// bit implement "in-place" the AXIfication, as the AXI spec can be volatile.
// At some point, the AXI side could be moved to a mkAXIStream{Master|Slave} convienience IP.
// For now, it is right here.

//4B WSI->AXI...
interface WSItoAXIS4BIfc;
  interface WsiES4B    wsi;  // WSI-Slave 
  interface NF10DPEM4B axi;  // NF10-Specialized AXI4-Stream Master
endinterface 

(* synthesize *)
module mkWSItoAXIS4B (WSItoAXIS4BIfc);
  WsiSlaveIfc#(12,32,4,8,0)        wsiS       <- mkWsiSlave;
  BusSender#(NF10DPM4B)            axiM       <- mkBusSender(aStrmDflt);

  A4StreamMIfc#(32,4,0,32) axisDatM = A4StreamMIfc { strm : axiM.out};  // Place strm sub-interface in axisM interface

  rule operate_action; wsiS.operate(); endrule

  rule advance_data;
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;
    Bit#(16) length = extend(w.burstLength*4);
    axiM.in.enq( A4Stream { data : w.data,
                            strb : w.byteEn,
                            user : {length, 8'h00, w.reqInfo},
                            keep : 0,
                            last : w.reqLast });
  endrule

  Wsi_Es#(12,32,4,8,0)       wsi_Es    <- mkWsiStoES(wsiS.slv);
  A4S_Em#(32,4,0,32)         axi_Em    <- mkA4StreamMtoEm(axisDatM);
  interface WsiES32B   wsi = wsi_Es;
  interface NF10DPEM4B axi = axi_Em;
endmodule


//4B AXI->WSI
interface AXIStoWSI4BIfc;
  interface NF10DPES4B axi;  // NF10-Specialized AXI4-Stream Slave
  interface WsiEM4B    wsi;  // WSI-Master
endinterface 

(* synthesize *)
module mkAXIStoWSI4B (AXIStoWSI4BIfc);
  BusReceiver#(NF10DPS4B)       axiS       <- mkBusReceiver;
  WsiMasterIfc#(12,32,4,8,0)    wsiM       <- mkWsiMaster;

  A4StreamSIfc#(32,4,0,8) axisDatS = A4StreamSIfc { strm : axiS.in};  // Place strm sub-interface in axisS interface

  rule operate_action; wsiM.operate(); endrule

  rule advance_data;
    let a = axiS.out.first; axiS.out.deq;
    wsiM.reqPut.put( WsiReq {   cmd  : WR,
                             reqLast : a.last,
                             reqInfo : a.user,
                        burstPrecise : False,
                         burstLength : (a.last) ? 1 : '1,
                               data  : a.data,
                             byteEn  : a.strb,
                           dataInfo  : '0 });
  endrule

  A4S_Es#(32,4,0,8) axi_Es <- mkA4StreamStoEs(axisDatS);
  interface NF10DPES4B axi = axi_Es;
  interface WsiEM4B    wsi = toWsiEM(wsiM.mas);
endmodule

endpackage
