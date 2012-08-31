// EDP.bsv - Ethernet Data Plane
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module adds the 14B Ethernet header to the datagram-based data plane on packet egress

import GMAC         ::*;	  // for ABS defs

import BRAMFIFO     ::*;
import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;

interface EDPAdapterIfc;
  interface Server#(ABS, ABS) server;  // Server faces the external fabric
  interface Client#(ABS, ABS) client;  // Client faces the internal datagram dataplane  
endinterface 


module mkEDPAdapterSync#(MACAddress da, MACAddress sa, EtherType ty) (EDPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(ABS)      edpReqF       <- mkFIFO;   // Inbound   EDP  Requests
  FIFO#(ABS)      edpRespF      <- mkFIFO;   // Outbound  EDP  Responses
  FIFO#(ABS)      dgdpReqF      <- mkFIFO;   // Inbound   DGDP Requests
  FIFO#(ABS)      dgdpRespF     <- mkFIFO;   // Outbound  DGDP Responses/Messages
  // The internal state of the EDP module...
  Reg#(Bool)      egressHead    <- mkReg(False);  // Send the L2 Header
  Reg#(Bool)      egressLoadOK  <- mkReg(False);  // Send the L2 Payload
  Reg#(UInt#(3))  ix            <- mkRegU; // used in StmtFSM
  // Not used yet...
  Reg#(Maybe#(Bit#(8)))      lastTag   <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(ABS)                  lastResp  <- mkRegU;                 // The last EDP response sent

  FIFOF#(ABS)      dgdpRespBF <- mkSizedBRAMFIFOF(1024);
  //FIFO#(Bit#(0));  dgdpEOPBF  <- mkFIFO;

  Vector#(6, Bit#(8)) daV = reverse(unpack(da));
  Vector#(6, Bit#(8)) saV = reverse(unpack(sa));
  Vector#(2, Bit#(8)) tyV = reverse(unpack(ty));
  Stmt egressIpHead =
  // Note state variable ix used in sequential iteration...
  seq
    ix<=0; while (ix<6) action ix<=ix+1; edpRespF.enq(tagged ValidNotEOP daV[ix]); endaction
    ix<=0; while (ix<6) action ix<=ix+1; edpRespF.enq(tagged ValidNotEOP saV[ix]); endaction
    ix<=0; while (ix<2) action ix<=ix+1; edpRespF.enq(tagged ValidNotEOP tyV[ix]); endaction
  endseq;
  FSM egressIpHeadFsm <- mkFSM(egressIpHead);

  rule edp_ingress;  // Ingress from Ethernet fabric to Datagram Dataplane 
    let x = edpReqF.first; edpReqF.deq;
    //dgdpReqF.enq(x); 
  endrule

  rule egress_r0;  // Take Egress from Datagram Dataplane to Ethernet fabric and ENQ in RespBF
    let y = dgdpRespF.first; dgdpRespF.deq;
    dgdpRespBF.enq(y);
    if (y matches tagged ValidEOP .*) egressHead <= True;
  endrule

  rule egress_head (egressHead);
    egressHead   <= False;
    egressLoadOK <= True;
    egressIpHeadFsm.start;
  endrule

  rule egress_body (egressIpHeadFsm.done && egressLoadOK);
    let z = dgdpRespBF.first; dgdpRespBF.deq;
    edpRespF.enq(z);
    if (z matches tagged ValidEOP .*) egressLoadOK <= False;  // When we reach EOP, gate this rule condition off
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
