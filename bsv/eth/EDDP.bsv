// EDDP.bsv - Ethernet Dattagram Data Plane (EDDP) Adapter
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module digests DGDP (ad hoc EtherType 0xF041) payloads

package EDDP;

import E8023        ::*;

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import DReg         ::*;
import FIFO         ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;

interface EDDPAdapterIfc;
  interface Server#(QABS,QABS)  server; 
  interface Client#(QABS,QABS)  client; 
  method Action macAddr (MACAddress u);  // Our local unicast MAC address
  method Action dstAddr (MACAddress d);  // The destination MAC address for TX'd Producer packets
  method Action dstType (EtherType  t);  // The EtherType for TX'd Producer packets
  method Bool edpRx;
  method Bool edpTx;
  method Bool edpTxEOP;
endinterface 

(* synthesize *)
module mkEDDPAdapter (EDDPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(QABS)                edpReqF      <- mkFIFO;
  FIFO#(QABS)                edpRespF     <- mkFIFO;
  FIFO#(QABS)                dpReqF       <- mkFIFO;
  FIFO#(QABS)                dpRespF      <- mkFIFO;

  Reg#(Bool)                 edpIngress   <- mkDReg(False);
  Reg#(Bool)                 edpEgress    <- mkDReg(False);
  Reg#(Bool)                 edpEgressEOP <- mkDReg(False);

  Reg#(MACAddress)           dMAddr       <- mkRegU;        // supplied dest address for tx frames
  Reg#(MACAddress)           uMAddr       <- mkRegU;        // unicast MAC address of this device
  Reg#(EtherType)            dEType       <- mkRegU;        // supplied EtherType    for tx frames
  Reg#(Bit#(16))             eeDID        <- mkRegU;        // captured DGDP destination ID (DID)
  Reg#(Bool)                 txPayload    <- mkReg(False);  // Send DGDP payload following header

  Reg#(ABS)                  dbge0        <- mkRegU;
  Reg#(ABS)                  dbge1        <- mkRegU;
  Reg#(ABS)                  dbge2        <- mkRegU;
  Reg#(ABS)                  dbge3        <- mkRegU;


  // Non-functional bypass logic for scafolding...
  //mkConnection(toGet(edpReqF), toPut(dpReqF));
  //mkConnection(toGet(dpRespF), toPut(edpRespF));

  //
  // RX / Ingress from Ethernet...
  //

  rule ingress_chomp;             // FIXME: consume ingress packets blindly until we are making solid outputs
    let x <- toGet(edpReqF).get;  // chomp
    edpIngress <= True;
  endrule


  //
  // TX / Egress to Ethernet...
  //

  Vector#(6, Bit#(8)) daV  = reverse(unpack(dMAddr));
  Vector#(6, Bit#(8)) saV  = reverse(unpack(uMAddr));
  Vector#(2, Bit#(8)) tyV  = reverse(unpack(dEType));
  Vector#(4, Bit#(1)) allV = unpack(4'b0000);
  Vector#(4, Bit#(1)) lasV = unpack(4'b1000);
  Vector#(2, Bit#(8)) didV = reverse(unpack(eeDID));  

  // Note: On egress, the DGDP will prepend two empty ABS cells to the frame payload so that we may
  // create a (14+2) = 16B L2 header (with DID added); then n QABS cycles of DGDP payload.
  // This means that no byte shifting is needed after the header is sent (logic savings).

  Stmt egressDGDP =
  seq
     edpRespF.enq(qabsFromBits( pack(daV)[31:0],                     4'b0000));
     edpRespF.enq(qabsFromBits({pack(saV)[15:0],  pack(daV)[47:32]}, 4'b0000));
     edpRespF.enq(qabsFromBits( pack(saV)[47:16],                    4'b0000));
     edpRespF.enq(qabsFromBits({pack(didV)[15:0], pack(tyV)},        4'b0000));
     txPayload <= True;  // L2 Header complete, Let the DGDP payload egress
  endseq;
  FSM edpFsm <- mkFSM(egressDGDP);
   
  rule egress_setup (edpFsm.done && !txPayload);
    let t = dpRespF.first; dpRespF.deq;  // The first QABS from DGDP will have two empty ABS cells + DID
    Bit#(32) dw = pack(map(getData,t));  // Extract raw data from the QABS TX stream
    eeDID <= dw[31:16];                  // Pick off the DID ignoring the bubbles in Bytes 0/1 
    edpFsm.start;                        // egress the DGDP L2 header with DID included (14+2=16B)
  endrule

  rule egress_body (txPayload);
    let t = dpRespF.first; dpRespF.deq;  // Accept more from the DGDP TX
    edpRespF.enq(t);
    txPayload    <= !hasQABSEOP(t);      // End the frame on EOP
    edpEgressEOP <=  hasQABSEOP(t);      // End the frame on EOP
    edpEgress <= True;
    dbge0 <= t[0];
    dbge1 <= t[1];
    dbge2 <= t[2];
    dbge3 <= t[3];
  endrule

  interface Server server;  // Outward Facing the L2 Packet Side
    interface request  = toPut(edpReqF);
    interface response = toGet(edpRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Data Plane
    interface request  = toGet(dpReqF);
    interface response = toPut(dpRespF);
  endinterface
  method Action macAddr (MACAddress u) = uMAddr._write(u);  // Our local unicast MAC address
  method Action dstAddr (MACAddress d) = dMAddr._write(d);  // The destination MAC address for Producer packets
  method Action dstType (EtherType  t) = dEType._write(t);  // The EtherType for TX'd Producer packets
  method Bool   edpRx    = edpIngress;
  method Bool   edpTx    = edpEgress;
  method Bool   edpTxEOP = edpEgressEOP;
endmodule

endpackage

