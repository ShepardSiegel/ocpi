// ProtocolMonitor.bsv - Protocol Monotor defintions and utlities
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package ProtocolMonitor;

import OCWipDefs::*;
import OCPMDefs::*;
import OCWci::*;
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
// The mkPMEMSend module accepts data from its "seen" Interface, which may be 1 or more DWORDs wide/long.
// It then serializes that information onto a ubiquitious WsiEM4B link.

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
    Bit#(8) inf  = 0;
    PMEvent eTyp = ?;
    Bit#(32) d0  = ?;
    Bit#(32) d1  = ?;
    case (m) matches
      tagged PMEM_1DW  .e0: begin len=1; inf=1; eTyp=e0.eType; end
      tagged PMEM_2DW  .e1: begin len=2; inf=2; eTyp=e1.eType; d0=e1.data0;              end
      tagged PMEM_3DW  .e2: begin len=3; inf=3; eTyp=e2.eType; d0=e2.data0; d1=e2.data1; end
      tagged PMEM_NDWH .e3: begin len=7; inf=4; eTyp=e3.eType; end
      tagged PMEM_NDWB .e4: begin len=7; inf=5;                end
      tagged PMEM_NDWT .e5: begin len=7; inf=6;                end
    endcase
    let h = PMEMHeader {srcID:srcID, eType:eTyp, srcTag:srcTag, info:inf};
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
    if (eom) begin
      evF.deq;
      srcTag <= srcTag + 1;
    end
    idx <= eom ? 1 : idx+1;
  endrule

  interface WsiEM4B pmem = toWsiEM(wsiM.mas); 
  interface Put  seen    = toPut(evF);
endmodule


// PMEM Monitor...
// The mkPMEMMonitor module accepts WSI stream data on a WsiES4B link. This could be from one or more PMEM Senders.
// It "unwinds" the Protocol Monitor Event Message, recovering the PMEM semantics that were encoded for transmission on WSI 4B.

interface PMEMMonitorIfc;
  interface WsiES4B  pmem;
  method Bool head;         
  method Bool body;         
  method Bool grab;         
endinterface

module mkPMEMMonitor (PMEMMonitorIfc);
  WsiSlaveIfc#(12,32,4,8,0)  wsiS  <- mkWsiSlave;
  Reg#(Bool)         msgActive   <- mkReg(False);
  Reg#(PMEMHeader)   pmh         <- mkRegU;
  FIFOF#(PMEMF)      pmemF       <- mkFIFOF;  
  Reg#(Bit#(32))     eventCount  <- mkReg(0);
  Reg#(Bool)         pmHead      <- mkDReg(False);
  Reg#(Bool)         pmBody      <- mkDReg(False);
  Reg#(Bool)         pmGrab      <- mkRegU;

  rule operate; wsiS.operate(); endrule

  rule chomp_wsi;
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;  // ActionValue Get
    if (!msgActive) pmemF.enq(PMEMF {eom:w.reqLast, pm:(Header (unpack(w.data)))});
    else            pmemF.enq(PMEMF {eom:w.reqLast, pm:(Body          (w.data))});
    msgActive <= !w.reqLast; 
  endrule

  rule get_message_head_dw (pmemF.first matches .g &&& g.pm matches tagged Header .h);
    pmh <= h;
    pmGrab <= unpack(parity(pack(pmh)));  // grab looks across all header bits (keeps datapath from dissolving)
    pmemF.deq;
    pmHead <= True;
    if (g.eom) eventCount <= eventCount + 1;
    $display("[%0d]: %m: PMEM HEAD: ", $time, fshow(h));
  endrule

  rule gen_message_body_dw (pmemF.first matches .g &&& g.pm matches tagged Body .b);
    pmemF.deq;
    pmBody <= True;
    if (g.eom) eventCount <= eventCount + 1;
    $display("[%0d]: %m: PMEM BODY: srcId:%x srcTag:%x, Event Count:%d. Body Data:%0x ", $time, pmh.srcID, pmh.srcTag, eventCount, b);
  endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);

  interface Wsi_Es pmem = wsi_Es;     // The protocol-monitor message produced (in WSI format)
  method Bool      head = pmHead;         
  method Bool      body = pmBody;         
  method Bool      grab = pmGrab;         
endmodule


// Now come the Wxx Monitors which encapsulate the Wxx-specific observer, and the PMEM Sender above...


// The WciMonitor encapsulates the WCI Observer and PMEMSender...
interface WciMonitorIfc;
  interface WciEO    observe;
  interface WsiEM4B  pmem;
endinterface

(* synthesize *)
module mkWciMonitor#(parameter Bit#(8) monId)  (WciMonitorIfc);
  WciObserverIfc#(32) observer <- mkWciObserver;
  PMEMSendIfc         pmsender <- mkPMEMSend(monId);

  mkConnection(observer.seen.get, pmsender.seen.put);

  interface Wci_Eo observe  = observer.wci;
  interface Get     pmem    = pmsender.pmem; 
endmodule


// The WsiMonitor encapsulates the WSI Observer and PMEMSender...
interface WsiMonitorIfc#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  interface Wsi_Eo#(nb,nd,ng,nh,ni)  observe;
  interface WsiEM4B                  pmem;
endinterface

//(* synthesize *)
module mkWsiMonitor#(parameter Bit#(8) monId)  (WsiMonitorIfc#(nb,nd,ng,nh,ni)) provisos(Add#(nd,0,32),Add#(ng,0,4));
  WsiObserverIfc#(nb,nd,ng,nh,ni) observer <- mkWsiObserver;
  PMEMSendIfc                     pmsender <- mkPMEMSend(monId);

  mkConnection(observer.seen.get, pmsender.seen.put);

  interface Wsi_Eo  observe  = observer.wsi;
  interface Get     pmem     = pmsender.pmem; 
endmodule



endpackage: ProtocolMonitor
