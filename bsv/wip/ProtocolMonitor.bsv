// ProtocolMonitor.bsv - Protocol Monotor defintions and utlities
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package ProtocolMonitor;

import OCWipDefs::*;
import OCPMDefs::*;
import OCWsi::*;

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import GetPut::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import FShow::*;
import SpecialFIFOs::*;
import TieOff::*;


// PMEM Sender...

interface PMEMSendIfc;
  interface WsiEM4B     pmem;  // The protocol-monitor message sent on WSI
  interface Put#(PMEM)  seen;  // What we've seen that we would like to send  
endinterface

module mkPMEMSend#(parameter Bit#(8) srcID)  (PMEMSendIfc);
  WsiMasterIfc#(12,32,4,8,0)  wsiM      <- mkWsiMaster;  // WSI master out
  FIFOF#(PMEM)                evF       <- mkFIFOF;      // event input
  Reg#(Bit#(8))               srcTag    <- mkReg(0);     // 8b rolling count
  Reg#(Bit#(3))               idx       <- mkReg(1);     // serialize-unroll index
  Reg#(Bool)                  isHead    <- mkReg(True);  // True for Header

  rule operate; wsiM.operate(); endrule

  rule serialize_message;
    let m = evF.first; 
    Bit#(3) len  = 0;
    PMEvent eTyp = ?;
    Bit#(32) d0  = ?;
    Bit#(32) d1  = ?;
    case (m) matches
      tagged PMEM_1DW  .e0: begin len=1; eTyp=e0.eType; end
      tagged PMEM_2DW  .e1: begin len=2; eTyp=e1.eType; d0=e1.data0;              end
      tagged PMEM_3DW  .e2: begin len=3; eTyp=e2.eType; d0=e2.data0; d1=e2.data1; end
      tagged PMEM_NDWH .e3: begin len=7; eTyp=e3.eType; end
      tagged PMEM_NDWB .e4: begin len=7;                end
      tagged PMEM_NDWT .e5: begin len=7;                end
    endcase
    srcTag <= srcTag + 1;
    let h = PMEMHeader {srcID:srcID, eType:eTyp, srcTag:srcTag, info:0};
    Bool eom = (idx==len);
    wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                             reqLast : (eom),
                             reqInfo : 0,
                        burstPrecise : False,
                         burstLength : extend(len),
                               data  : case (idx)
                                         1 : pack(h);
                                         2 : d0;
                                         3 : d1;
                                       endcase,
                             byteEn  : '1,
                           dataInfo  : '0 });
    if (eom) evF.deq;
    idx <= eom ? 1 : idx+1;
  endrule

  interface WsiEM4B pmem = toWsiEM(wsiM.mas); 
  interface Put  seen    = toPut(evF);
endmodule


// PMEM Monitor...
/*

interface PMEMMonitorIfc;
  interface WsiES4B  pmem;
  method Bool head;         
  method Bool body;         
  method Bool grab;         
endinterface

module mkPMEMMonitor (PMEMMonitorIfc);
  FIFOF#(PMEMF)      pmemF       <- mkFIFOF;   // PMEMF message input
  Reg#(PMEMHeader)   pmh         <- mkRegU;
  Reg#(Bit#(8))      dwRemain    <- mkRegU;
  Reg#(Bit#(32))     eventCount  <- mkReg(0);
  Reg#(Bool)         pmHead      <- mkDReg(False);
  Reg#(Bool)         pmBody      <- mkDReg(False);
  Reg#(Bool)         pmGrab      <- mkDReg(False);

  WsiSlaveIfc#(12,32,4,8,0)  wsiS  <- mkWsiSlave;
  Reg#(Bool)         msgActive   <- mkReg(False);

  rule operate; wsiS.operate(); endrule

  rule chomp;
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;  // ActionValue Get
    if (!msgActive) begin // Header
      pmemF.enq(PMEMF{eof:w.reqLast, pmem:Header (unpack(w.data))});
      PMEMHeader h =  unpack(w.data);
    end else begin        // Body
      pmemF.enq(PMEMF{eof:w.reqLast,pmem:Body (w.data)});
    end
    msgActive <= !w.reqLast;
  endrule


  rule get_message_head (pmemF.first.pmem matches tagged Header .h);
    pmh <= h;
    pmGrab <= unpack(parity(pack(pmh)));  // Just look across all header bits

    pmemF.deq;
    pmHead <= True;
    dwRemain <= h.length - 1;
    if (h.length==1) begin 
      eventCount <= eventCount + 1;
      if (!pmemF.first.eof) $display("[%0d]: %m PMEM HEAD EOF ERROR", $time);
    end
    $display("[%0d]: %m PMEM event: ", $time, fshow(h));
  endrule

  rule gen_message_body (pmemF.first.pmem matches tagged Body .b);
    pmemF.deq;
    pmBody <= True;
    dwRemain <= dwRemain - 1;
    if(dwRemain==1) begin
      eventCount <= eventCount + 1;
      if (!pmemF.first.eof) $display("[%0d]: %m PMEM BODY EOF ERROR", $time);
    end
    $display("[%0d]: %m: PMEM MONITOR Event %0d Body dwRemain:%0x data:%0x ", $time, eventCount, dwRemain, b);
  endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);

  interface Wsi_Es pmem = wsi_Es;     // The protocol-monitor message produced (in WSI format)
  method Bool      head = pmHead;         
  method Bool      body = pmBody;         
  method Bool      grab = pmGrab;         
endmodule
*/


endpackage: ProtocolMonitor
