// DCP.bsv - DWORD Control Packet
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module digests DCP (ad hoc EtherType 0xF040) payloads
// DCP Requests arriving are assumed correct as tagged; upstream logic strips 6+6+2 Byte Ethernet header

import CPDefs       ::*; 

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
  Response = 4'h3,
  Pad      = 4'hF
} DCPMesgType deriving (Bits, Eq);

typedef struct {
  Bit#(8)  tag;
  Bit#(32) initAdvert;
} DCPRequestNOP deriving (Bits, Eq);

typedef struct {
  Bit#(4)  be;
  Bit#(8)  tag;
  Bit#(32) data;
  Bit#(32) addr;
} DCPRequestWrite deriving (Bits, Eq);

typedef struct {
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
  Bit#(32)    targAdvert;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseNOP deriving (Bits, Eq);

typedef struct {
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseWrite deriving (Bits, Eq);

typedef struct {
  Bit#(32)    data;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseRead deriving (Bits, Eq);

typedef union tagged {
  DCPResponseNOP    NOP;
  DCPResponseWrite  Write;
  DCPResponseRead   Read;
} DCPResponse deriving (Bits);

interface DCPAdapterIfc;
  interface Server#(DCPRequest,DCPResponse) server; 
  interface Client#(CpReq,CpReadResp)       client; 
endinterface 

module mkDCPAdapterSync (DCPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(DCPRequest)          dcpReqF   <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF  <- mkFIFO;   // Outbound  DCP Responses
  FIFO#(CpReq)               cpReqF    <- mkFIFO;
  FIFO#(CpReadResp)          cpRespF   <- mkFIFO;
  // The internal state of the DCP module...
  Reg#(Maybe#(Bit#(8)))      lastTag   <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(DCPResponse )         lastResp  <- mkRegU;                 // The last CP response sent

  Bit#(32) targAdvert = 32'h4000_0001;  // Set the target advertisement constant

  rule dcp_request;
    let x = dcpReqF.first; dcpReqF.deq;
    case (x) matches
      tagged NOP   .n: begin
          dcpRespF.enq(tagged NOP( DCPResponseNOP{targAdvert:targAdvert, tag:n.tag, code:RESP_OK})); // Respond to the NOP
          lastTag <= (tagged Invalid);  // NOPs Invalidate the lastTag so next command is always accepted
        end
      tagged Write .w: begin
        if ((isValid(lastTag) && w.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag)) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid
          cpReqF.enq(tagged WriteRequest( CpWriteReq{dwAddr:truncate(w.addr>>2), byteEn:w.be, data:w.data}));  // Issue the Write
          lastTag <= (tagged Valid w.tag); // Capture the tag into lastTag
        end 
        dcpRespF.enq(tagged Write( DCPResponseWrite{tag:w.tag, code:RESP_OK})); // Blind ACK the Write regardless if tag match or not
        //TODO: When CP write responses are non-blind (from non-posted requests), make write machine use lastResp like Read
        end
        tagged Read  .r: begin
        if ((isValid(lastTag) && r.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag)) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid
          cpReqF.enq(tagged ReadRequest(  CpReadReq {dwAddr:truncate(r.addr>>2), byteEn:r.be, tag:r.tag}));    // Issue the Read
          lastTag <= (tagged Valid r.tag); // Capture the tag into lastTag
        end else dcpRespF.enq(lastResp);   // Retransmit the lastResp since tags match
        end
    endcase
  endrule

  rule cp_response;
    let y = cpRespF.first; cpRespF.deq;
    DCPResponse dcpr = (tagged Read( DCPResponseRead{data:y.data, tag:y.tag, code:RESP_OK}));
    dcpRespF.enq(dcpr);  // Advance the CP Read response
    lastResp <= dcpr;    // Save dcpr in lastResponse for possible re-transmission
  endrule

  interface Server server;  // Facing the DCP Packet Side
    interface request  = toPut(dcpReqF);
    interface response = toGet(dcpRespF);
  endinterface
  interface Client client;  // Facing the Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule


// This is an easy (lazy) way of doing an asyc CP-side client interface...
// We simply take the lean sync implementation as-is; and attach two async FIFOs to
// the CP-facing side so they can be in their own clock domain. 

module mkDCPAdapterAsync#(Clock cpClock, Reset cpReset) (DCPAdapterIfc);
  DCPAdapterIfc              dcp       <- mkDCPAdapterSync;
  SyncFIFOIfc#(CpReq)        cpReqAF   <- mkSyncFIFOFromCC(4, cpClock); 
  SyncFIFOIfc#(CpReadResp)   cpRespAF  <- mkSyncFIFOToCC(  4, cpClock, cpReset); 

  mkConnection(dcp.client.request, toPut(cpReqAF));
  mkConnection(toGet(cpRespAF), dcp.client.response);

  interface Server server = dcp.server;  // Facing the Ethernet L2 directly

  interface Client client;  // Facing the Control Plane through Async FIFOs
    interface request  = toGet(cpReqAF);
    interface response = toPut(cpRespAF);
  endinterface
endmodule


// TODO: Consider a poly version of the DCP adapter that can use either plain 
// or Async FIFOs on the CP-fascing client side. Based on the isAsync, we 
// instance eitehr the plain or async FIFOs. Then we use the syncFifoToFifo
// function to expose a FIFO ifc. When I tried this, I had some unexplained
// clock domain crossing errors; so abandonned this approach for lack of time.
// I think the Poly idea is a usefull pattern and should be experimented with
// first in a simple test case. sssiegel 2012-06-13

`ifdef POLY_DCP_IDEA

module mkDCPAdapterPoly#(Bool isAsync, Clock cpClock, Reset cpReset) (DCPAdapterIfc);

  FIFO#(DCPRequest)          dcpReqF   <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF  <- mkFIFO;   // Outbound  DCP Responses

  // Needs to be out here to scope the Interface suficiently
  FIFO#(CpReq)      cpReqF  = ?;
  FIFO#(CpReadResp) cpRespF = ?;

  if (!isAsync) begin
    cpReqF    <- mkFIFO;   // Control-plane Requests
    cpRespF   <- mkFIFO;   // Control-plane Responses
  end else begin
    SyncFIFOIfc#(CpReq)        cpSReqF     <- mkSyncFIFOFromCC(4, cpClock); 
    SyncFIFOIfc#(CpReadResp)   cpSRespF    <- mkSyncFIFOToCC(4,cpClock, cpReset); 
    let cpReqF  = syncFifoToFifo (cpSReqF);
    let cpRespF = syncFifoToFifo (cpSRespF);
  end

  rule dcp_request;
    ...
  endrule

  interface Server server;  // Facing the DCP Packet Side
    interface request  = toPut(dcpReqF);
    interface response = toGet(dcpRespF);
  endinterface
  interface Client client;  // Facing the Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule

module mkDCPAdapterSync (DCPAdapterIfc);
  DCPAdapterIfc _a <- mkDCPAdapterPoly(False, ?, ?); return _a;
endmodule

module mkDCPAdapterAsync#(Clock cpClock, Reset cpReset) (DCPAdapterIfc);
  DCPAdapterIfc _a <- mkDCPAdapterPoly(True, cpClock, cpReset); return _a;
endmodule

function FIFO#(t) syncFifoToFifo (SyncFIFOIfc#(t) in);
   return (
      interface FIFO;
         method Action enq(x) = in.enq(x);
         method Action clear  = $display("%m: Clear method is not supported in this module!");
         method Action deq = in.deq;
         method t first       = in.first;
      endinterface );
endfunction

`endif
