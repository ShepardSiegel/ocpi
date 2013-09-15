// CRT.bsv - Command-Response Transaction (CRT)
// Copyright (c) 2012,2013 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4L      ::*; 

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
} CRTMesgType deriving (Bits, Eq);

typedef enum {
  OK       = 4'h0,
  Timeout  = 4'h1,
  Error    = 4'h2,
  RSVD     = 4'hF
} CRTRespCode deriving (Bits, Eq);

typedef struct {
  Bool        isLast;
  Bit#(2)     rsvd28;
  UInt#(12)   adl;
  Bit#(8)     rsvd8;
  Bit#(1)     rsvd7;
  Bool        isDO;
  CRTMesgType mesgt;
  Bit#(4)     tag;
} CRHNOP deriving (Bits, Eq);

typedef struct {
  Bool        isLast;
  Bit#(2)     rsvd28;
  UInt#(12)   adl;
  Bit#(4)     lastBE;
  Bit#(4)     firtBE;
  Bit#(1)     rsvd7;
  Bool        isDO;
  CRTMesgType mesgt;
  Bit#(4)     tag;
} CRHWrite deriving (Bits, Eq);

typedef struct {
  Bool        isLast;
  Bit#(2)     rsvd28;
  UInt#(12)   adl;
  Bit#(4)     lastBE;
  Bit#(4)     firtBE;
  Bit#(1)     rsvd7;
  Bool        isDO;
  CRTMesgType mesgt;
  Bit#(4)     tag;
} CRHRead deriving (Bits, Eq);

typedef struct {
  Bool        isLast;
  Bit#(2)     rsvd28;
  UInt#(12)   adl;
  Bit#(4)     rsvd12;
  CRTRespCode mesgt;
  Bit#(1)     rsvd7;
  Bool        isDO;
  CRTMesgType mesgt;
  Bit#(4)     tag;
} CRHResp deriving (Bits, Eq);

typedef union tagged {
  CRHNOP    NOP;
  CRHWrite  Write;
  CRHRead   Read;
  CRHResp   Response;
  void      Invalid;
} TagCRH deriving (Bits, Eq); 

interface CRTServToA4LMIfc;
  interface Server#(CRTDW,CRTDW)  crtS0; 
  interface A4LMIfx               axiM0
endinterface 

module mkCRTServToA4LM (CRTServToA4LM);

  Integer respBufSize = 64;

  // CRT Command/Response FIFOs...
  FIFO#(Bit#(32))       crtCmdF     <- mkFIFO;   // Inbound  CRT Commands
  FIFO#(Bit#(32))       crtRespF    <- mkFIFO;   // Outbound CRT Responses
  // The internal state of the CRT module...
  Reg#(TagCRH)          thisCRH     <- mkReg(tagged Invalid);
  Reg#(Bool)            isCmdCRH    <- mkReg(True);
  Reg#(Bool)            fault       <- mkReg(False);
  Reg#(Bool)            doInFlight  <- mkReg(False);           // True when a Discovery Operation (DO) is in flight
  Reg#(Maybe#(Bit#(8))) lastTag     <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  UInt#(12)             adlRemain   <- mkReg(0);
  UInt#(12)             adlLastResp <- mkReg(0);
  FIFO#(Bit#(32))       respBuffer  <- mkSizedFIFO(respBufSize/4);

  Bit#(32) targAdvert = respBufSize;

  rule crt_cmd_ingress;
    let x = crtCmdF.first; crtCmdF.deq;
    if (isCmdCRH)
      CRTMesgType cmt = unpack(x[5:4]);
      case (cmt)
        NOP:   thisCRH <= tagged NOP   unpack(x);
        Write: thisCRH <= tagged Write unpack(x);
        Read:  thisCRH <= tagged Read  unpack(x);
        Response: fault <= True;
      endcase
    end
  endrule

/*
    case (x) matches
      tagged NOP   .n: begin
          crtRespF.enq(tagged NOP( CRTResponseNOP{hasDO:n.isDO, targAdvert:targAdvert, tag:n.tag, code:RESP_OK})); // Respond to the NOP
          if (!n.isDO) lastTag <= (tagged Invalid);  // NOPs Invalidate the lastTag so next command is always accepted
          if ( n.isDO) doInFlight <= True;
        end
      tagged Write .w: begin
        if ((isValid(lastTag) && w.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || w.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged WriteRequest( CpWriteReq{dwAddr:truncate(w.addr>>2), byteEn:w.be, data:w.data}));  // Issue the Write
          if (!w.isDO) lastTag <= (tagged Valid w.tag); // Capture the tag into lastTag
          if ( w.isDO) doInFlight <= True;
        end 
        crtRespF.enq(tagged Write( CRTResponseWrite{hasDO:w.isDO, tag:w.tag, code:RESP_OK})); // Blind ACK the Write regardless if tag match or not
        //TODO: When CP write responses are non-blind (from non-posted requests), make write machine use lastResp like Read
        end
        tagged Read  .r: begin
        if ((isValid(lastTag) && r.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || r.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged ReadRequest(  CpReadReq {dwAddr:truncate(r.addr>>2), byteEn:r.be, tag:r.tag}));    // Issue the Read
          if (!r.isDO) lastTag <= (tagged Valid r.tag); // Capture the tag into lastTag
          if ( r.isDO) doInFlight <= True;
        end else crtRespF.enq(lastResp);   // Retransmit the lastResp since tags match
        end
    endcase
  endrule

  */

  /*
  rule cp_response;
    let y = cpRespF.first; cpRespF.deq;
    CRTResponse crtr = (tagged Read( CRTResponseRead{hasDO:doInFlight, data:y.data, tag:y.tag, code:RESP_OK}));
    crtRespF.enq(crtr);  // Advance the CP Read response
    if (!doInFlight) lastResp <= crtr;    // Save crtr in lastResponse for possible re-transmission
    doInFlight <= False;
  endrule
  */

  interface Server server;  // Facing the CRT Packet Side
    interface request  = toPut(crtCmdF);
    interface response = toGet(crtRespF);
  endinterface
  interface A4LMIfc axiM0 = a4l.a4lm;
endmodule

/*
// This is an easy (lazy) way of doing an asyc CP-side client interface...
// We simply take the lean sync implementation as-is; and attach two async FIFOs to
// the CP-facing side so they can be in their own clock domain. 

module mkCRTAdapterAsync#(Clock cpClock, Reset cpReset) (CRTAdapterIfc);
  CRTAdapterIfc              crt       <- mkCRTAdapterSync;
  SyncFIFOIfc#(CpReq)        cpReqAF   <- mkSyncFIFOFromCC(4, cpClock); 
  SyncFIFOIfc#(CpReadResp)   cpRespAF  <- mkSyncFIFOToCC(  4, cpClock, cpReset); 

  mkConnection(crt.client.request, toPut(cpReqAF));
  mkConnection(toGet(cpRespAF), crt.client.response);

  interface Server server = crt.server;  // Facing the Ethernet L2 directly

  interface Client client;  // Facing the Control Plane through Async FIFOs
    interface request  = toGet(cpReqAF);
    interface response = toPut(cpRespAF);
  endinterface
endmodule
*/
