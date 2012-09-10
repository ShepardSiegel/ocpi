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
endinterface 

(* synthesize *)
module mkEDDPAdapter (EDDPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(QABS)                edpReqF     <- mkFIFO;
  FIFO#(QABS)                edpRespF    <- mkFIFO;
  FIFO#(QABS)                dpReqF      <- mkFIFO;
  FIFO#(QABS)                dpRespF     <- mkFIFO;

  Reg#(MACAddress)           uMAddr      <- mkRegU;   // unicast MAC address of this device
  Reg#(UInt#(4))             ptr         <- mkReg(0);
  Reg#(MACAddress)           eDAddr      <- mkRegU;   // captured destination address of incident packet
  Reg#(MACAddress)           eMAddr      <- mkRegU;   // captured source address of incident packet
  FIFO#(MACAddress)          eMAddrF     <- mkFIFO;
  Reg#(EtherType)            eTyp        <- mkRegU;
  Reg#(Bit#(16))             ePli        <- mkRegU;
  Reg#(Bit#(32))             eDMH        <- mkRegU;
  Reg#(Bit#(32))             eAddr       <- mkRegU;
  Reg#(Bit#(32))             eData       <- mkRegU;
  Reg#(Bool)                 eDoReq      <- mkDReg(False);

  Reg#(Bool)                 isWrtResp  <- mkRegU;
  Reg#(MACAddress)           eeMDst     <- mkRegU;
  Reg#(Bit#(16))             eePli      <- mkRegU;
  Reg#(Bit#(32))             eeDmh      <- mkRegU;
  Reg#(Bit#(32))             eeDat      <- mkRegU;


  interface Server server;  // Outward Facing the L2 Packet Side
    interface request  = toPut(edpReqF);
    interface response = toGet(edpRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Data Plane
    interface request  = toGet(dpReqF);
    interface response = toPut(dpRespF);
  endinterface
  method Action macAddr (MACAddress u) = uMAddr._write(u);  // Our local unicast MAC address
endmodule

endpackage

