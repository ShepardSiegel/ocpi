// EDCP.bsv - Ethernet DWORD Control Packet (uses QABS on L2 side)
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module digests DCP (ad hoc EtherType 0xF040) payloads
// DCP Requests arriving are assumed correct as tagged; upstream logic strips 6+6+2 Byte Ethernet header

package EDCP;

import CPDefs       ::*; 
import E8023        ::*;

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;	
import GetPut       ::*;
import Vector       ::*;

typedef enum {
  NOP      = 4'h0,
  Write    = 4'h1,
  Read     = 4'h2,
  Response = 4'h3
} DCPMesgType deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(8)  tag;
  Bit#(32) initAdvert;
} DCPRequestNOP deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(4)  be;
  Bit#(8)  tag;
  Bit#(32) data;
  Bit#(32) addr;
} DCPRequestWrite deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(4)  be;
  Bit#(8)  tag;
  Bit#(32) addr;
} DCPRequestRead deriving (Bits, Eq);

typedef union tagged {
  DCPRequestNOP    NOP;
  DCPRequestWrite  Write;
  DCPRequestRead   Read;
} DCPRequest deriving (Bits);

typedef enum {
  RESP_OK      = 4'h0,
  RESP_TIMEOUT = 4'h1,
  RESP_ERROR   = 4'h2
} DCPRespCode deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(32)    targAdvert;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseNOP deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseWrite deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(32)    data;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseRead deriving (Bits, Eq);

typedef union tagged {
  DCPResponseNOP    NOP;
  DCPResponseWrite  Write;
  DCPResponseRead   Read;
} DCPResponse deriving (Bits);

interface EDCPAdapterIfc;
  interface Server#(QABS,QABS)         server; 
  interface Client#(CpReq,CpReadResp)  client; 
endinterface 

(* synthesize *)
module mkEDCPAdapter (EDCPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(QABS)                ecpReqF     <- mkFIFO;
  FIFO#(QABS)                ecpRespF    <- mkFIFO;

  FIFO#(DCPRequest)          dcpReqF     <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF    <- mkFIFO;   // Outbound  DCP Responses
  FIFO#(CpReq)               cpReqF      <- mkFIFO;
  FIFO#(CpReadResp)          cpRespF     <- mkFIFO;
  // The internal state of the DCP module...
  Reg#(Bool)                 doInFlight <- mkReg(False);          // True when a Discovery Operation (DO) is in flight
  Reg#(Maybe#(Bit#(8)))      lastTag    <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(DCPResponse )         lastResp   <- mkRegU;                 // The last CP response sent

  Bit#(32) targAdvert = 32'h4000_0001;  // Set the target advertisement constant

  rule dcp_request;
    let x = dcpReqF.first; dcpReqF.deq;
    case (x) matches
      tagged NOP   .n: begin
          dcpRespF.enq(tagged NOP( DCPResponseNOP{hasDO:n.isDO, targAdvert:targAdvert, tag:n.tag, code:RESP_OK})); // Respond to the NOP
          if (!n.isDO) lastTag <= (tagged Invalid);  // NOPs Invalidate the lastTag so next command is always accepted
          if ( n.isDO) doInFlight <= True;
        end
      tagged Write .w: begin
        if ((isValid(lastTag) && w.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || w.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged WriteRequest( CpWriteReq{dwAddr:truncate(w.addr>>2), byteEn:w.be, data:w.data}));  // Issue the Write
          if (!w.isDO) lastTag <= (tagged Valid w.tag); // Capture the tag into lastTag
          if ( w.isDO) doInFlight <= True;
        end 
        dcpRespF.enq(tagged Write( DCPResponseWrite{hasDO:w.isDO, tag:w.tag, code:RESP_OK})); // Blind ACK the Write regardless if tag match or not
        //TODO: When CP write responses are non-blind (from non-posted requests), make write machine use lastResp like Read
        end
        tagged Read  .r: begin
        if ((isValid(lastTag) && r.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || r.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged ReadRequest(  CpReadReq {dwAddr:truncate(r.addr>>2), byteEn:r.be, tag:r.tag}));    // Issue the Read
          if (!r.isDO) lastTag <= (tagged Valid r.tag); // Capture the tag into lastTag
          if ( r.isDO) doInFlight <= True;
        end else dcpRespF.enq(lastResp);   // Retransmit the lastResp since tags match
        end
    endcase
  endrule

  rule cp_response;
    let y = cpRespF.first; cpRespF.deq;
    DCPResponse dcpr = (tagged Read( DCPResponseRead{hasDO:doInFlight, data:y.data, tag:y.tag, code:RESP_OK}));
    dcpRespF.enq(dcpr);  // Advance the CP Read response
    if (!doInFlight) lastResp <= dcpr;    // Save dcpr in lastResponse for possible re-transmission
    doInFlight <= False;
  endrule

  interface Server server;  // Outward Facing the L2 Packet Side
    interface request  = toPut(ecpReqF);
    interface response = toGet(ecpRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule

endpackage
