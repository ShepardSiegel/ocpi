// TLPSerializer.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import TLPMF::*;
import OCBufQ::*;

import PCIE::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAM::*;
import ClientServer::*; 
import DReg::*;
import Gearbox::*;

interface TLPSerializerIfc;
  interface Server#(PTW16,PTW16) server;
  interface Client#(CpReq,CpReadResp) client;
endinterface

typedef struct {
  Bit#(22) dwAddr;
  Bit#(4)  byteEn;
  DWord    data;
} CpWriteReq deriving (Bits);

typedef struct {
  Bit#(8)  tag;
  Bit#(22) dwAddr;
  Bit#(4)  byteEn;
} CpReadReq deriving (Bits);

typedef union tagged {
  CpWriteReq WriteRequest;
  CpReadReq  ReadRequest;
} CpReq deriving (Bits);

typedef struct {
  Bit#(8)  tag;
  DWord    data;
} CpReadResp deriving (Bits);

typedef enum {Idle,RdPush,RdFinal} RdStage deriving (Bits, Eq);

// as inbound TLPs become available, serialize them into single DW reqeusts
// For Writes: Pick the first DW as the bottom DW of the write DLP, if more to follow
//             then chomp 1 DW at a time out of the 4 DW on each subsequent 16B TLP
// For Reads:  Use the firstBE condition for the first DW, then make dwLength DW requests
//             up until the last, where lastBE is used

module mkTLPSerializer#(PciId pciDevice) (TLPSerializerIfc);

  FIFO#(PTW16)          inF                <- mkFIFO;   // inbound TLPs
  FIFO#(PTW16)          outF               <- mkFIFO;   // outbound completion TLPs
  FIFO#(ComplInfo)      cmpF               <- mkFIFO;   // Read completion info
  FIFO#(CpReq)          cpReqF             <- mkFIFO;   // Control-plane Requests
  FIFO#(CpReadResp)     cpRespF            <- mkFIFO;   // Control-plane Responses

  Reg#(Bool)            tlpActive          <- mkReg(False);
  Reg#(Bool)            tlpFirst           <- mkRegU;
  Reg#(MemReqHdr1)      tlpReq             <- mkRegU;
  Reg#(Bit#(10))        tlpUnroll          <- mkRegU;
  Reg#(DWAddress)       tlpDWAddr          <- mkRegU;
  Reg#(DWord)           tlpDW              <- mkRegU;
  Reg#(Bit#(2))         tlpDWp             <- mkRegU;

  Reg#(Bool)                 cmpActive     <- mkReg(False);
  Reg#(Bit#(10))             cmpDWRemain   <- mkRegU;
  Reg#(RdStage)              rss           <- mkReg(Idle);  // read stage state
  Reg#(Bit#(2))              rdp           <- mkReg(0);     // read data pointer
  Reg#(Vector#(4,Bit#(32)))  rdv           <- mkRegU;       // read data vector

  rule tlpFirstRcv (!tlpActive);
    tlpActive <= True;
    PTW16   pw = inF.first;
    Ptw16Hdr p = unpack(pw.data);
    if (pw.sof) begin 
      MemReqHdr1 hdr      = unpack(pw.data[127:64]);  // Top 2DW of 4DW TLP has the hdr
      DWAddress  dwAddr   = pw.data[63:34];           // Pick off dwAddr from 1st TLP
      DWord      firstDW  = truncate(pw.data);        // Bottom DW of 1st TLP is data
      Bool ignorePkt = p.hdr.isPoisoned || p.hdr.is4DW || p.hdr.pktType != 5'b00000;
      if (!ignorePkt) begin
        tlpReq     <= hdr;
        tlpUnroll  <= hdr.length;
        tlpDWAddr  <= dwAddr;
        tlpDW      <= firstDW;
        tlpFirst   <= True;
        tlpDWp     <= 3;
        if (!p.hdr.isWrite) begin  // Compute and enq completion information for reads...
          Bit#(2) lowAddr10 = byteEnToLowAddr(p.hdr.firstDWByteEn);
          Bit#(7) lowAddr = {truncate(dwAddr), lowAddr10};
          Bit#(12) byteCount = computeByteCount(p.hdr.length, p.hdr.firstDWByteEn, p.hdr.lastDWByteEn);
          let ci = ComplInfo { reqID     : p.hdr.requesterID,
                               dwLength  : p.hdr.length,
                               lowAddr   : lowAddr,
                               byteCount : byteCount,
                               tag       : p.hdr.tag,
                               tc        : p.hdr.trafficClass };
          cmpF.enq(ci);
        end
      end
    end
    inF.deq;
  endrule

  rule tlpReqGen (tlpActive);
    Bit#(32) dn = tlpDW;  // use this data on the 1st cycle
    Bit#(4)  be = 4'hF;
    if (tlpUnroll==1) be = tlpReq.lastDWByteEn;
    if (tlpFirst)     be = tlpReq.firstDWByteEn;

    if (tlpReq.isWrite && !tlpFirst) begin
      let pn <- toGet(inF).get;
      Vector#(4, DWord) vdw = unpack(pn.data);
      dn = vdw[tlpDWp];
      tlpDWp <= tlpDWp - 1;
    end

    CpWriteReq wreq = CpWriteReq {
       dwAddr   : truncate(tlpDWAddr),
       byteEn   : be, 
       data     : byteSwap(dn) };
    CpReadReq rreq = CpReadReq {
       tag      : tlpReq.tag,
       dwAddr   : truncate(tlpDWAddr),
       byteEn   : be };
    CpReq cpr = (tlpReq.isWrite) ? WriteRequest(wreq) : ReadRequest(rreq);
    cpReqF.enq(cpr);    // enq the CP request in cpReqF
    tlpFirst  <= False;
    tlpDWAddr <= tlpDWAddr + 1;
    tlpUnroll <= tlpUnroll - 1;
    if (tlpUnroll==1) tlpActive <= False;
  endrule


  // Process the first read response and make the completion header...
  rule tlpFirstComplWord (!cmpActive);
    ComplInfo ci  = cmpF.first; cmpF.deq;
    Bit#(32) data = cpRespF.first.data; cpRespF.deq;
    CompletionHdr hdr =
      makeReadCompletionHdr(pciDevice, ci.reqID, ci.dwLength, ci.tag, ci.tc, ci.lowAddr, ci.byteCount);
    Bit#(128) pkt = { pack(hdr), byteSwap(data) };
    PTW16 w = TLPData {
                data : pkt,
                be   : '1,
                hit  : ?,
                sof  : True,
                eof  : (ci.dwLength == 1)};
    outF.enq(w);
    cmpDWRemain <= ci.dwLength - 1;
    if (ci.dwLength != 1) cmpActive <= True;
    //$display("[%0d] TLP Serializer: First DW read response enqueued (data %0x)", $time, data);
  endrule

  // Finish the current completion first...
  (* descending_urgency = "tlpNextComplWord, tlpStageNextWord" *)

  // Stage the data that will form the body of the completion...
  rule tlpStageNextWord (cmpActive && cmpDWRemain>0);
    Bit#(32) rdata = cpRespF.first.data; cpRespF.deq;
    rdv <= shiftInAt0(rdv, byteSwap(rdata));  // shift it in, endian byteSwap
    rdp <= rdp + 1;                           // update head pointer
    cmpDWRemain <= cmpDWRemain-1;             // decrement read remaining
    if (cmpDWRemain==1) rss <= RdFinal;       // last DW has been staged
    else if (rdp==3)    rss <= RdPush;        // 4 DWs have been staged
  endrule

  // Send out 16B read completion data; or flush the final one...
  rule tlpNextComplWord (cmpActive && rss!=Idle);
    UInt#(2) rot = unpack(truncate(3'h4-extend(rdp)));
    Vector#(4, DWord) vdw = rotateBy(rdv,rot);
    Bit#(16) lastRema =
      case (rdp[1:0])
        2'b00 : 'hFFFF;
        2'b01 : 'hF000;
        2'b10 : 'hFF00;
        2'b11 : 'hFFF0;
      endcase;
    PTW16 pw = PTW16 {
      data : pack(vdw),
      be   : (rss==RdFinal)?lastRema:'1,
      hit  : ?,
      sof  : False,
      eof  : (rss==RdFinal) };
    outF.enq(pw);
    // Reset for next use...
    rdp <= 0;
    if (rss==RdFinal) begin
      cmpActive <= False;
      rss <= Idle;
    end
  endrule

  interface Server server;                  // Facing the TLP/PCIe side
    interface request  = toPut(inF);
    interface response = toGet(outF);
  endinterface
  interface Client client;                  // Facing the Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule


