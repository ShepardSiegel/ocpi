// EDP.bsv - Ethernet Data Plane
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module adds the 14B Ethernet header to the datagram-based data plane on packet egress

import GMAC         ::*;	  // for ABS defs

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;

interface EDPAdapterIfc;
  interface Server#(ABS, ABS) server;  // Server faces the external fabric
  interface Client#(ABS, ABS) client;  // Client faces the internal datagram dataplane  
endinterface 


module mkEDPAdapterSync#(MACAddress da, MACAddress sa, EtherType ty) (EDPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(ABS)      edpReqF     <- mkFIFO;   // Inbound   EDP  Requests
  FIFO#(ABS)      edpRespF    <- mkFIFO;   // Outbound  EDP  Responses
  FIFO#(ABS)      dgdpReqF    <- mkFIFO;   // Inbound   DGDP Requests
  FIFO#(ABS)      dgdpRespF   <- mkFIFO;   // Outbound  DGDP Responses/Messages
  // The internal state of the EDP module...
  Reg#(Bool)      egressHead  <- mkReg(True);
  Reg#(UInt#(3))  ix          <- mkRegU; // used in StmtFSM
  // Not used yet...
  Reg#(Maybe#(Bit#(8)))      lastTag   <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(ABS)                  lastResp  <- mkRegU;                 // The last EDP response sent

  rule edp_ingress;  // Ingress from Ethernet fabric to Datagram Dataplane 
    let x = edpReqF.first; edpReqF.deq;
    dgdpReqF.enq(x);
  endrule

  rule edp_egress;  // Egress from Datagram Dataplane to Ethernet fabric
    let y = dgdpRespF.first; dgdpRespF.deq;
    edpRespF.enq(y);
  endrule

  Vector#(6, Bit#(8)) daV = reverse(unpack(da));
  Vector#(6, Bit#(8)) saV = reverse(unpack(sa));
  Vector#(2, Bit#(8)) tyV = reverse(unpack(ty));
  Stmt egressIpHead =
  // Note state variable ix used in sequential iteration...
  seq
    for (ix<=0; ix<6; ix<=ix+1) edpRespF.enq(tagged ValidNotEOP daV[ix]);
    for (ix<=0; ix<6; ix<=ix+1) edpRespF.enq(tagged ValidNotEOP saV[ix]);
    for (ix<=0; ix<2; ix<=ix+1) edpRespF.enq(tagged ValidNotEOP tyV[ix]);
  endseq;
  FSM egressIpHeadFsm <- mkFSM(egressIpHead);


  interface Server server;  // Facing the EDP Packet Side
    interface request  = toPut(edpReqF);
    interface response = toGet(edpRespF);
  endinterface
  interface Client client;  // Facing the Datagram DataPlane
    interface request  = toGet(dgdpReqF);
    interface response = toPut(dgdpRespF);
  endinterface
endmodule


// This is an easy (lazy) way of doing an async user datagram-side client interface...
// We simply take the lean sync implementation as-is; and attach two async FIFOs to
// the DGDP-facing side so they can be in their own clock domain. 

module mkEDPAdapterAsync#(Clock      cpClock
                        , Reset      cpReset
                        , MACAddress da
                        , MACAddress sa
                        , EtherType  ty) (EDPAdapterIfc);
  EDPAdapterIfc            edp         <- mkEDPAdapterSync(da,sa,ty);
  SyncFIFOIfc#(ABS)        dgdpReqAF   <- mkSyncFIFOFromCC(4, cpClock);           // L2 to dgdp
  SyncFIFOIfc#(ABS)        dgdpRespAF  <- mkSyncFIFOToCC(  4, cpClock, cpReset);  // dgdp to L2

  mkConnection(edp.client.request, toPut(dgdpReqAF));
  mkConnection(toGet(dgdpRespAF), edp.client.response);

  interface Server server = edp.server;  // Facing the Ethernet L2 directly

  interface Client client;  // Facing the Datagram Data Plane through Async FIFOs
    interface request  = toGet(dgdpReqAF);
    interface response = toPut(dgdpRespAF);
  endinterface
endmodule
