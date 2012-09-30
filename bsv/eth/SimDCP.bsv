// SimDCP.bsv - Simulator DWORD Control Packet, accepts raw DCP w/o L2
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module digests raw DCP payloads
// DCP Requests arriving are assumed correct as tagged; upstream logic strips 6+6+2 Byte Ethernet header

package SimDCP;

import CPDefs       ::*; 

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import DReg         ::*;
import FIFO         ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;

typedef enum {
  NOP      = 4'h0,
  Write    = 4'h1,
  Read     = 4'h2,
  Response = 4'h3
} DCPMesgType deriving (Bits, Eq);

typedef struct {
  Bool       isDO;
  Bit#(8)    tag;
  Bit#(32)   initAdvert;
} DCPRequestNOP deriving (Bits, Eq);

typedef struct {
  Bool       isDO;
  Bit#(4)    be;
  Bit#(8)    tag;
  Bit#(32)   data;
  Bit#(32)   addr;
} DCPRequestWrite deriving (Bits, Eq);

typedef struct {
  Bool       isDO;
  Bit#(4)    be;
  Bit#(8)    tag;
  Bit#(32)   addr;
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

interface SimDCPIfc;
  interface Server#(Bit#(8),Bit#(8))   host; 
  interface Client#(CpReq,CpReadResp)  client; 
endinterface 

(* synthesize *)
module mkSimDCP (SimDCPIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(Bit#(8))             simReqF     <- mkFIFO;
  FIFO#(Bit#(8))             simRespF    <- mkFIFO;

  Reg#(UInt#(4))             ptr         <- mkReg(0);
  Reg#(Bit#(16))             ePli        <- mkRegU;
  Reg#(Bit#(32))             eDMH        <- mkRegU;
  Reg#(Bit#(32))             eAddr       <- mkRegU;
  Reg#(Bit#(32))             eData       <- mkRegU;
  Reg#(Bool)                 eDoReq      <- mkDReg(False);

  FIFO#(DCPRequest)          dcpReqF     <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF    <- mkFIFO;   // Outbound  DCP Responses
  FIFO#(CpReq)               cpReqF      <- mkFIFO;
  FIFO#(CpReadResp)          cpRespF     <- mkFIFO;
  // The internal state of the DCP module...
  Reg#(Bool)                 doInFlight <- mkReg(False);           // True when a Discovery Operation (DO) is in flight
  Reg#(Maybe#(Bit#(8)))      lastTag    <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(DCPResponse)          lastResp   <- mkRegU;                 // The last CP response sent

  Reg#(Bool)                 isWrtResp  <- mkRegU;
  Reg#(Bit#(16))             eePli      <- mkRegU;
  Reg#(Bit#(32))             eeDmh      <- mkRegU;
  Reg#(Bit#(32))             eeDat      <- mkRegU;

  Bit#(32) targAdvert = 32'h4000_0001;  // Set the target advertisement constant

  // This rule digests all inbound packets and decides if the rx_scp_dcp rule should file with a DCP Request...
  rule sim_ingress (!eDoReq);
    let b = simReqF.first;  simReqF.deq;     // Get the simulator byte
    Bool isWrite = (eDMH[13:12]==2'b01);     // Decode write=14B request
    Bool isEOP = (ptr==((isWrite)?13:9));    // The 10th or 14th byte 
    ptr <= isEOP ? 0:(ptr==15) ? 15:ptr+1;   // ptr counts up to 15 until EOP reset 
    case (ptr)
      0  : ePli   <= 0    | extend(b<<8);
      1  : ePli   <= ePli | extend(b<<0);
      2  : eDMH   <= {              b, 24'h000000};
      3  : eDMH   <= {eDMH[31:24],  b, 16'h0000  };
      4  : eDMH   <= {eDMH[31:16],  b, 8'h00     };
      5  : eDMH   <= {eDMH[31:8],   b            };
      6  : eAddr  <= {              b, 24'h000000};
      7  : eAddr  <= {eAddr[31:24], b, 16'h0000  };
      8  : eAddr  <= {eAddr[31:16], b, 8'h00     };
      9  : eAddr  <= {eAddr[31:8],  b            };
      10 : eData  <= {              b, 24'h000000};
      11 : eData  <= {eData[31:24], b, 16'h0000  };
      12 : eData  <= {eData[31:16], b, 8'h00     };
      13 : eData  <= {eData[31:8],  b            };
    endcase
    eDoReq <= isEOP;
    //$display("sim_ingress ptr:%d b:%0x, eDMH:%0x",ptr,b, eDMH);
  endrule

  function Bit#(32) reverseBytes (Bit#(32) a);
    Vector#(4,Bit#(8)) b = unpack(a);
    return (pack(reverse(b)));
  endfunction

  // Here we enque something in the dcpReqF for dcp_to_cp_request to act on...
  rule rx_sim_dcp (eDoReq);
    Bit#(32) leDMH = reverseBytes(eDMH);
    //$display("edmH:%0x  leDMH%0x", eDMH, leDMH);
    Bool    isDO = unpack(leDMH[22]);
    Bit#(2) mTyp = leDMH[21:20];
    Bit#(4) mBe  = leDMH[19:16];
    Bit#(8) mTag = leDMH[31:24];
    DCPMesgType mType = unpack(mTyp);
    case (mType)
      NOP   : dcpReqF.enq(tagged NOP  ( DCPRequestNOP  {isDO:isDO,         tag:mTag,       initAdvert:eAddr}));
      Write : dcpReqF.enq(tagged Write( DCPRequestWrite{isDO:isDO, be:mBe, tag:mTag, data:eData, addr:eAddr}));
      Read  : dcpReqF.enq(tagged Read ( DCPRequestRead {isDO:isDO, be:mBe, tag:mTag,             addr:eAddr}));
    endcase
    case (mType)
      NOP   : $display("[%0d]: rx_sim_dcp REQUEST: NOP ", $time);
      Write : $display("[%0d]: rx_sim_dcp REQUEST: WRITE Addr:0x%0x Data:0x%0x", $time, eAddr, eData);
      Read  : $display("[%0d]: rx_sim_dcp REQUEST: READ  Addr:0x%0x ", $time, eAddr);
    endcase
  endrule


  // Here we decide if the request can be responded to here (such as a NOP) or if we need to pass this to the CP
  // If not a discovery operation (DO), we check the tag for a match so that we don't re-issue a CP command twice 
  rule dcp_to_cp_request;
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
        end else begin
          dcpRespF.enq(lastResp);   // Retransmit the lastResp since tags match
          $display("[%0d]: dcp_to_cp_request ***TAG MATCH*** (Returning Previous Response)", $time);
        end
        end
    endcase
  endrule

  // Here we consume responses from the CP and turn them into DCP responses...
  rule cp_to_dcp_response;
    let y = cpRespF.first; cpRespF.deq;
    DCPResponse dcpr = (tagged Read( DCPResponseRead{hasDO:doInFlight, data:y.data, tag:y.tag, code:RESP_OK}));
    dcpRespF.enq(dcpr);                   // Advance the CP Read response
    if (!doInFlight) lastResp <= dcpr;    // Save dcpr in lastResponse for possible re-transmission
    doInFlight <= False;
  endrule


  // The following code waits for a DCP response in dcpRespF... 
  Stmt egressDCPPacket =
  seq
     simRespF.enq(truncate(eePli>> 8));
     simRespF.enq(truncate(eePli>> 0));
     simRespF.enq(truncate(eeDmh>> 0));
     simRespF.enq(truncate(eeDmh>> 8));
     simRespF.enq(truncate(eeDmh>>16));
     simRespF.enq(truncate(eeDmh>>24));
     if (!isWrtResp) seq
       simRespF.enq(truncate(eeDat>>24));
       simRespF.enq(truncate(eeDat>>16));
       simRespF.enq(truncate(eeDat>> 8));
       simRespF.enq(truncate(eeDat>> 0));
     endseq
  endseq;
  FSM edpFsm <- mkFSM(egressDCPPacket);

  // This rule sets up the state needed for egressDCPPacket to run...
  rule sim_egress (edpFsm.done);
    let rsp = dcpRespF.first;  dcpRespF.deq;              // take the DCP response
    case (rsp) matches
      tagged NOP   .n: begin
        eePli <= 10;  // NOP reseponse is 10B
        eeDmh <= { n.tag, n.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        eeDat <= n.targAdvert;
        isWrtResp <= False;
        $display("[%0d]: sim_egress NOP_RESPONSE", $time);
        end
      tagged Write .w: begin
        eePli <= 6;  // Write reseponse is 6B
        eeDmh <= { w.tag, w.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        isWrtResp <= True;
        $display("[%0d]: sim_egress WRITE_RESPONSE", $time);
        end
      tagged Read  .r: begin
        eePli <= 10;  // Read reseponse is 10B
        eeDmh <= { r.tag, r.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        eeDat <= r.data;
        isWrtResp <= False;
        $display("[%0d]: sim_egress READ_RESPONSE Data:0x%0x ", $time, r.data);
        end
    endcase
   edpFsm.start;  // egress the DCP packet...
  endrule

  interface Server host;  // Outward Facing the Host Side
    interface request  = toPut(simReqF);
    interface response = toGet(simRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule

endpackage

