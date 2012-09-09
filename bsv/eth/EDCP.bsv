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

interface EDCPAdapterIfc;
  interface Server#(QABS,QABS)         server; 
  interface Client#(CpReq,CpReadResp)  client; 
  method Action macAddr (MACAddress u);  // Our local unicast MAC address
endinterface 

(* synthesize *)
module mkEDCPAdapter (EDCPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(QABS)                ecpReqF     <- mkFIFO;
  FIFO#(QABS)                ecpRespF    <- mkFIFO;

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

  FIFO#(DCPRequest)          dcpReqF     <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF    <- mkFIFO;   // Outbound  DCP Responses
  FIFO#(CpReq)               cpReqF      <- mkFIFO;
  FIFO#(CpReadResp)          cpRespF     <- mkFIFO;
  // The internal state of the DCP module...
  Reg#(Bool)                 doInFlight <- mkReg(False);           // True when a Discovery Operation (DO) is in flight
  Reg#(Maybe#(Bit#(8)))      lastTag    <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(DCPResponse)          lastResp   <- mkRegU;                 // The last CP response sent

  Reg#(Bool)                 isWrtResp  <- mkRegU;
  Reg#(MACAddress)           eeMDst     <- mkRegU;
  Reg#(Bit#(16))             eePli      <- mkRegU;
  Reg#(Bit#(32))             eeDmh      <- mkRegU;
  Reg#(Bit#(32))             eeDat      <- mkRegU;

  MACAddress bAddr = 48'hFF_FF_FF_FF_FF_FF;
//MACAddress uAddr = 48'h00_0A_35_42_01_00;   // A fake Xilinx MAC Addr
//MACAddress uAddr = 48'hA0_36_FA_25_3E_A5;   // A real Ettus N210 MAC Addr
  Bit#(32) targAdvert = 32'h4000_0001;  // Set the target advertisement constant

  // Data in QABS has first byte on the wire in LSB

  function Bit#(32) reverseBytes (Bit#(32) a);
    Vector#(4,Bit#(8)) b = unpack(a);
    return (pack(reverse(b)));
  endfunction

  rule ecp_ingress (!eDoReq);
    let qb = ecpReqF.first;  ecpReqF.deq;      // Get the upstream QABS Vector contents
    Bit#(32) dw = pack(map(getData,qb));       // Extract data from the QABS stream
    Bit#(32) bedw = reverseBytes(dw);
    Bool hasEOP = unpack(reduceOr(pack(map(isEOP,qb))));     // Test for any EOP cells
    ptr <= hasEOP ? 0:(ptr==15) ? 15:ptr+1;      // ptr counts up to 15 until EOP reset // TODO Abort 
    case (ptr)
      0 : eDAddr  <= {bedw, 16'h0000};
      1 : action eMAddr  <= {bedw[15:0], 32'h00000000}; eDAddr <= eDAddr | {32'h00000000, bedw[31:16]}; endaction
      2 : eMAddr  <= eMAddr | extend(bedw);
      3 : action eTyp <= {dw[7:0],dw[15:8]}; ePli <= {dw[23:16],dw[31:24]}; endaction
      4 : eDMH   <= bedw;
      5 : eAddr  <= bedw;
      6 : eData  <= bedw;
    endcase
    eDoReq <= ((eDAddr==bAddr) || (eDAddr==uMAddr))  // Dest address matches broadcast or unicast MAC address
           &&  (eTyp==16'hF040)                      // EtherType matches 
           && ((ePli==10 && ptr==5)||(ePli==14 && ptr==6));  // TODO Qualify non-aborted hasEOP (wait for EOP, padding?)
  endrule

  rule rx_ecp_dcp (eDoReq);
    Bit#(32) leDMH = reverseBytes(eDMH);
    Bool    isDO = unpack(leDMH[22]);
    Bit#(2) mTyp = leDMH[21:20];
    Bit#(4) mBe  = leDMH[19:16];
    Bit#(8) mTag = leDMH[31:24];
    DCPMesgType mType = unpack(mTyp);
    case (mType)
      NOP   : dcpReqF.enq(tagged NOP  ( DCPRequestNOP  {isDO:isDO,         tag:mTag, initAdvert:eAddr}));
      Write : dcpReqF.enq(tagged Write( DCPRequestWrite{isDO:isDO, be:mBe, tag:mTag, data:eData, addr:eAddr}));
      Read  : dcpReqF.enq(tagged Read ( DCPRequestRead {isDO:isDO, be:mBe, tag:mTag, addr:eAddr}));
    endcase
    eMAddrF.enq(eMAddr); // push the partner MAC address so we know where to send the response
  endrule


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
        end else dcpRespF.enq(lastResp);   // Retransmit the lastResp since tags match
        end
    endcase
  endrule

  rule cp_to_dcp_response;
    let y = cpRespF.first; cpRespF.deq;
    DCPResponse dcpr = (tagged Read( DCPResponseRead{hasDO:doInFlight, data:y.data, tag:y.tag, code:RESP_OK}));
    dcpRespF.enq(dcpr);                   // Advance the CP Read response
    if (!doInFlight) lastResp <= dcpr;    // Save dcpr in lastResponse for possible re-transmission
    doInFlight <= False;
  endrule


  Vector#(6, Bit#(8)) daV  = reverse(unpack(eeMDst));
  Vector#(6, Bit#(8)) saV  = reverse(unpack(uMAddr));
  Vector#(2, Bit#(8)) tyV  = reverse(unpack(16'hF040));
  Vector#(4, Bit#(1)) allV = unpack(4'b0000);
  Vector#(4, Bit#(1)) lasV = unpack(4'b1000);

  Vector#(2, Bit#(8)) pliV  = reverse(unpack(eePli));
  Vector#(4, Bit#(8)) dmhV  = reverse(unpack(eeDmh));
  Vector#(4, Bit#(8)) rspV  = reverse(unpack(eeDat));

  Stmt egressDCPPacket =
  seq
     ecpRespF.enq(qabsFromBits(pack(daV)[31:0],  4'b0000));
     ecpRespF.enq(qabsFromBits({pack(saV)[15:0], pack(daV)[47:32]}, 4'b0000));
     ecpRespF.enq(qabsFromBits(pack(saV)[47:16],  4'b0000));
     ecpRespF.enq(qabsFromBits({pack(pliV)[15:0], pack(tyV)}, 4'b0000));
     if (isWrtResp)
       ecpRespF.enq(qabsFromBits(reverseBytes(pack(dmhV)),  4'b1000));
     else seq
       ecpRespF.enq(qabsFromBits(reverseBytes(pack(dmhV)),  4'b0000));
       ecpRespF.enq(qabsFromBits(pack(rspV),  4'b1000));
     endseq
  endseq;
  FSM edpFsm <- mkFSM(egressDCPPacket);
   
  // This rule sets up the state needed for egressDCPPacket to run...
  rule ecp_egress (edpFsm.done);

    let da = eMAddrF.first; eMAddrF.deq; eeMDst <= da;  // take the return MAC address for the da

    let rsp = dcpRespF.first;  dcpRespF.deq;            // tahe the DCP response
    case (rsp) matches
      tagged NOP   .n: begin
        eePli <= 10;  // NOP reseponse is 10B
        eeDmh <= { n.tag, n.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        eeDat <= n.targAdvert;
        isWrtResp <= False;
        end
      tagged Write .w: begin
        eePli <= 6;  // Write reseponse is 6B
        eeDmh <= { w.tag, w.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        isWrtResp <= True;
        end
      tagged Read  .r: begin
        eePli <= 10;  // Read reseponse is 10B
        eeDmh <= { r.tag, r.hasDO?8'h70:8'h30, 16'h0000}; // DCP Response = OK
        eeDat <= r.data;
        isWrtResp <= False;
        end
    endcase

   edpFsm.start;  // egress the DCP packet...
  endrule

  interface Server server;  // Outward Facing the L2 Packet Side
    interface request  = toPut(ecpReqF);
    interface response = toGet(ecpRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
  method Action macAddr (MACAddress u) = uMAddr._write(u);  // Our local unicast MAC address
endmodule

endpackage

