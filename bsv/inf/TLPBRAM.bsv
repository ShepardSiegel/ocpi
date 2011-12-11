// TLPBRAM - Encapsulation of rules that operate on Requests and Responses to BRAM
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package TLPBRAM;

import OCBufQ::*;
import OCWip::*;
import PCIE::*;
import TLPMF::*;

import GetPut::*;
import FIFOF::*;
import Vector::*;
import BRAM::*;
import DReg::*;

// 2011-12-06 The TLP Side of the BRAM now supports a feature to make it work more naturally with both 3DW and 4DW PCIe requests
// We've added the bools skipHeadData, skipRespData, and hasRespData to the WriteReq, ReadReq, and ReadResp structures respectively.
// The idea is that in your Write or Read Request you can "skip" the 1DW of data that normally piggybacks with a 3DW write or completion.
// The utility of this "skip" is that allows the write or read data to directly line up with 4DW PCIe transactions w/o the need for a rotator.

typedef struct {
  Bool        skipHeadData;  // Set True to skip writing the data included with this request
  DPBufDWAddr dwAddr;
  Bit#(10)    dwLength;
  Bit#(4)     firstBE;
  Bit#(4)     lastBE;
  DWord       data;
} WriteReq deriving (Bits);

typedef enum {None,ComplTgt,DMASrc,Metadata} ReadRole deriving (Bits,Eq);

typedef struct {
  Bool        skipRespData;  // Set True to skip including the data included with the first response
  ReadRole    role;
  PciId       reqID;
  DPBufDWAddr dwAddr;
  Bit#(10)    dwLength;
  Bit#(4)     firstBE;
  Bit#(4)     lastBE;
  Bit#(8)     tag;
  Bit#(3)     tc;
} ReadReq deriving (Bits);

typedef union tagged {      // Three kinds of requests the TLPBRAM may receive
  WriteReq    WriteHeader;  // A write header, with or without 1 DWORD of data (no response produced)
  Bit#(128)   WriteData;    // Write data, 4DW that follow a write header (no response produced)
  ReadReq     ReadHeader;   // A read request header, 1 read response + n read body (first response w or w/o data)
} MemReqPacket deriving (Bits);

typedef struct {
  Bool     hasRespData;      // Set True when the data does contain a first 1DW response
  ReadRole role;
  PciId    reqID;
  Bit#(10) dwLength;
  Bit#(7)  lowAddr;
  Bit#(12) byteCount;
  Bit#(8)  tag;
  Bit#(3)  tc;
  DWord    data;
} ReadResp deriving (Bits);

typedef struct {
  ReadRole  role;
  Bit#(8)   tag;
  Bit#(128) data;
} ReadPayld deriving (Bits);

typedef union tagged {  // Responses produced by the TLPBRAM...
  ReadResp   ReadHead;  // The header, with or without 1 DWORD of read data
  ReadPayld  ReadBody;  // The body 4DW of data
} MemRespPacket deriving (Bits);

interface TLPBRAMIfc;
  interface Put#(MemReqPacket)   putReq;
  interface GetS#(MemRespPacket) getsResp;
endinterface: TLPBRAMIfc

module mkTLPBRAM#(Vector#(4,BRAMServer#(DPBufHWAddr,Bit#(32))) mem) (TLPBRAMIfc);

  FIFOF#(MemReqPacket)       mReqF                <- mkFIFOF;  // Requests to local BRAM
  FIFOF#(MemRespPacket)      mRespF               <- mkFIFOF;  // Responses from local BRAM
  FIFOF#(ReadReq)            readReq              <- mkFIFOF;  // Local Read Req/Resp FIFO - for flat map, e.g. tag
  Reg#(DPBufDWAddr)          writeDWAddr          <- mkRegU;
  Reg#(Bit#(10))             writeRemainDWLen     <- mkRegU;
  Reg#(Bit#(4))              writeLastBE          <- mkRegU;
  Reg#(Bool)                 readStarted          <- mkReg(False);
  Reg#(Bool)                 readHeaderSent       <- mkReg(False);
  Reg#(DPBufDWAddr)          readNxtDWAddr        <- mkRegU;
  Reg#(Bit#(10))             readRemainDWLen      <- mkRegU;
  Reg#(Bit#(10))             rdRespDwRemain       <- mkRegU;
  Reg#(Bit#(128))            debugBdata           <- mkReg(0);


  // On the mReqF.deq  side we unwind the PCI/NetworkByteOrder...
  // On the mRespF.enq side we format the data for PCI/NBO...

  // Perform the first memory write...
  rule writeReq (mReqF.first matches tagged WriteHeader .wreq);
    mReqF.deq;
    writeDWAddr       <= wreq.dwAddr   + (wreq.skipHeadData ? 0 : 1);
    writeRemainDWLen  <= wreq.dwLength - (wreq.skipHeadData ? 0 : 1);
    writeLastBE       <= wreq.lastBE;
    //let req = BRAMRequestBE { writeen:wreq.firstBE, address:wreq.dwAddr[11:2], datain:byteSwap(wreq.data), responseOnWrite:False };
    let req = BRAMRequest { write:True, address:truncate(wreq.dwAddr>>2), datain:byteSwap(wreq.data), responseOnWrite:False };
    if (!wreq.skipHeadData) mem[wreq.dwAddr[1:0]].request.put(req);  // We can write the 1st DW right away if we aren't skipping it
    //$display("[%0d] Mem: Writing first word (addr %x) data %x", $time, {wreq.dwAddr,2'b00}, byteSwap(wreq.data));
    //$display("Writing %0h to addr %0h of mem %0d", req.datain, req.address, wreq.dwAddr[1:0]);
  endrule

  // Perform any subsequent memory writes...
  rule writeData (mReqF.first matches tagged WriteData .wrdata);
    mReqF.deq;
    Vector#(4, DWord)       vWords   = reverse(unpack(wrdata)); // place low-addr DW at LS
    Vector#(4, DPBufHWAddr) vAddrs   = ?;
    Vector#(4, Bool)        vInclude = ?;
    Vector#(4, Bit#(4))     vByteEn  = ?;

    for (Integer i=0; i<4; i=i+1) begin
      //vAddrs[i]   = (writeDWAddr + fromInteger(i))[11:2];
      vAddrs[i]   = truncate((writeDWAddr + fromInteger(i))>>2);
      vInclude[i] =  writeRemainDWLen  > fromInteger(i);
      vByteEn[i]  = (writeRemainDWLen  == fromInteger(i+1)) ?  writeLastBE : 4'hF ;
    end

    for (Integer i=0; i<4; i=i+1) begin
      Bit#(2) idx = fromInteger(i) - writeDWAddr[1:0];
      //let req = BRAMRequestBE { writeen:vByteEn[idx], address:vAddrs[idx], datain:byteSwap(vWords[idx]), responseOnWrite:False };
      let req = BRAMRequest { write:True, address:vAddrs[idx], datain:byteSwap(vWords[idx]), responseOnWrite:False };
      if (vInclude[idx]) begin
        mem[i].request.put(req);
        //$display("Writing %0h to addr %0h of mem %0d",req.datain, req.address, i);
      end
    end

    writeDWAddr       <= writeDWAddr      + 4;
    writeRemainDWLen  <= writeRemainDWLen - 4;
    //$display("[%0d] Mem: Writing next words (addr %x, dwLen %0d)", $time, {writeDWAddr,2'b00}, writeRemainDWLen );
  endrule


  // Perform the first memory read request...
  rule read_FirstReq (!readStarted &&& mReqF.first matches tagged ReadHeader .rreq);
    readReq.enq(rreq); 
    if (rreq.dwLength == 1 && !rreq.skipRespData) mReqF.deq;
    else readStarted <= True;
    //let req = BRAMRequestBE { writeen:4'd0, address:rreq.dwAddr[11:2], datain:'0, responseOnWrite:False };
    let req = BRAMRequest { write:False, address:truncate(rreq.dwAddr>>2), datain:'0, responseOnWrite:False };
    if (!rreq.skipRespData) mem[rreq.dwAddr[1:0]].request.put(req); // if we skip the read request, dont look for response
    readRemainDWLen  <= rreq.dwLength - (rreq.skipRespData ? 0 : 1);
    readNxtDWAddr    <= rreq.dwAddr   + (rreq.skipRespData ? 0 : 1) ;
    //$display("[%0d] TLP Mem: First DW read request (addr %x, dwLen %0d)", $time, {rreq.dwAddr,2'b00}, rreq.dwLength);
    //$display("Reading addr %0x of mem %0d", req.address, rreq.dwAddr[1:0]);
  endrule

  // Perform any subsequent read requests...
  rule read_NextReq (readStarted &&& mReqF.first matches tagged ReadHeader .rreq);
    if (readRemainDWLen  <= 4) begin
      readStarted <= False;
      mReqF.deq;
    end
    readRemainDWLen  <= readRemainDWLen - 4;
    readNxtDWAddr    <= readNxtDWAddr   + 4;
    //$display("[%0d] TLP Mem: Next nDW read request (addr %x, dwLen %0d)", $time, {readNxtDWAddr,2'b00}, readRemainDWLen );

    Vector#(4, DPBufHWAddr) vAddrs = ?;
    for (Integer i=0; i<4; i=i+1)
      //vAddrs[i] = (readNxtDWAddr + fromInteger(i))[11:2];
      vAddrs[i] = truncate((readNxtDWAddr + fromInteger(i))>>2);

    for (Integer i=0; i<4; i=i+1) begin
      Bit#(2) idx = fromInteger(i) - readNxtDWAddr[1:0];
      //let req = BRAMRequestBE { writeen:4'd0, address:vAddrs[idx], datain:'0, responseOnWrite:False };
      let req = BRAMRequest { write:False, address:vAddrs[idx], datain:'0, responseOnWrite:False };
      mem[i].request.put(req);
      //$display("Reading addr %0x of mem %0d", req.address, i);
    end
  endrule

  // Process the first read response...
  rule read_FirstResp (!readHeaderSent);
    let rreq = readReq.first;
    let data <- (!rreq.skipRespData ? mem[rreq.dwAddr[1:0]].response.get() : ?);  // get data if we didn't skip
    Bit#(2) lowAddr10 = byteEnToLowAddr(rreq.firstBE);
    Bit#(7) lowAddr = {truncate(rreq.dwAddr), lowAddr10};
    Bit#(12) byteCount = computeByteCount(rreq.dwLength, rreq.firstBE, rreq.lastBE);
    let rresp = ReadResp { hasRespData : !rreq.skipRespData,
                           role        :  rreq.role,
                           reqID       :  rreq.reqID,
                           dwLength    :  rreq.dwLength,
                           lowAddr     :  lowAddr,
                           byteCount   :  byteCount,
                           tag         :  rreq.tag,
                           tc          :  rreq.tc,
                           data        :  byteSwap(data) }; // byteSwap to PCI TLP
    let pkt = ReadHead(rresp);
    mRespF.enq(pkt);
    rdRespDwRemain <= rreq.dwLength - (rreq.skipRespData ? 0 : 1);
    if (rreq.dwLength==1 && !rreq.skipRespData) readReq.deq;
    else readHeaderSent <= True;
    //$display("[%0d] TLP Mem: First DW read response enqueued (data %x)", $time, data);
  endrule

  // Process any subsequent read responses...
  rule read_NextResp (readHeaderSent);
    let rreq = readReq.first;
    Vector#(4, Bit#(32)) vResps = ?;
    Bit#(32) dw = ?;
    for (Integer i=0; i<4; i=i+1) begin
      dw <- mem[i].response.get;
      vResps[i] = byteSwap(dw);  // convert each DW into PCIe big-endian format
    end
    debugBdata <= pack(vResps);  // Capture the data from the four BRAMs for debug

    // The data from the BRAM is stored little-endian. That is the first DWORD is in the LSBs.
    // Two transformations are needed to put this in TLP/PCI completion order:
    // i) First, we reverse the DWORDs so that the first DWORD in the MSBs
    // ii) Next, we rotateBy to move up the first DWORD as needed
    // For example we may get DCBE from our BRAM where B is the "first" data when idx=1
    // The reverse transformation gets us EBCD; the rotateBy gets us BCDE, which is correct

    Bit#(2)   nxtDWAddr = truncate(rreq.dwAddr) + 1;
    UInt#(2)  idx  =  unpack(nxtDWAddr[1:0]);
    Bit#(128) rdata = pack(rotateBy(reverse(vResps),idx));

    let pkt = ReadBody(ReadPayld{role:rreq.role, tag:rreq.tag, data:rdata});
    rdRespDwRemain <= rdRespDwRemain - 4;
    if (rdRespDwRemain<=4) begin
      readReq.deq;
      readHeaderSent <= False;
    end
    mRespF.enq(pkt);
    //$display("[%0d] TLP Mem: Next nDW read response enqueued (data %x) (raw %x) (idx %x)", $time, rdata, pack(vResps), idx);
  endrule

  interface Put  putReq   = toPut(mReqF);
  interface GetS getsResp;
    method         first = mRespF.first;
    method  Action   deq = mRespF.deq;
  endinterface

endmodule: mkTLPBRAM

endpackage: TLPBRAM
