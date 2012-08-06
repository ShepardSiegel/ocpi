// EDP.bsv - Ethernet Data Plane
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module adds the 14B Ethernet header to the datagram-based data plane

import GMAC         ::*;	  // for ABS defs

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;	
import GetPut       ::*;
import Vector       ::*;

interface EDPAdapterIfc;
  interface Server#(ABS, ABS) server;  // Server faces the external fabric
  interface Client#(ABS, ABS) client;  // Client faces the internal datagram dataplane  
endinterface 


module mkEDPAdapterSync (EDPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(ABS)      edpReqF    <- mkFIFO;   // Inbound   EDP  Requests
  FIFO#(ABS)      edpRespF   <- mkFIFO;   // Outbound  EDP  Responses
  FIFO#(ABS)      dgdpReqF   <- mkFIFO;   // Inbound   DGDP Requests
  FIFO#(ABS)      dgdpRespF  <- mkFIFO;   // Outbound  DGDP Responses/Messages
  // The internal state of the EDP module...
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

module mkEDPAdapterAsync#(Clock dgdpClock, Reset dgdpReset) (EDPAdapterIfc);
  EDPAdapterIfc            edp         <- mkEDPAdapterSync;
  SyncFIFOIfc#(ABS)        dgdpReqAF   <- mkSyncFIFOFromCC(4, dgdpClock); 
  SyncFIFOIfc#(ABS)        dgdpRespAF  <- mkSyncFIFOToCC(  4, dgdpClock, dgdpReset); 

  mkConnection(edp.client.request, toPut(dgdpReqAF));
  mkConnection(toGet(dgdpRespAF), edp.client.response);

  interface Server server = edp.server;  // Facing the Ethernet L2 directly

  interface Client client;  // Facing the Datagram Data Plane through Async FIFOs
    interface request  = toGet(dgdpReqAF);
    interface response = toPut(dgdpRespAF);
  endinterface
endmodule
