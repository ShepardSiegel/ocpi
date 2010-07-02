// TLPMemory.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package TLPMemory;

import TLPMF::*;

import PCIE::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import BRAM::*;
import ClientServer::*; 
import DReg::*;
import Gearbox::*;

interface TLPMemoryIfc;
  interface Server#(PTW16,PTW16) server;
endinterface


typedef struct {
  Bit#(12) dwAddr;
  Bit#(10) dwLength;
  Bit#(4)  firstBE;
  Bit#(4)  lastBE;
  DWord    data;
} WriteReq deriving (Bits);

typedef struct {
  PciId    reqID;
  Bit#(12) dwAddr;
  Bit#(10) dwLength;
  Bit#(4)  firstBE;
  Bit#(4)  lastBE;
  Bit#(8)  tag;
  Bit#(3)  tc;
} ReadReq deriving (Bits);

typedef union tagged {
  WriteReq   WriteHeader;
  Bit#(128)  WriteData;
  ReadReq    ReadHeader;
} MemReqPacket deriving (Bits);

typedef struct {
  PciId    reqID;
  Bit#(10) dwLength;
  Bit#(7)  lowAddr;
  Bit#(12) byteCount;
  Bit#(8)  tag;
  Bit#(3)  tc;
  DWord    data;
} ReadResp deriving (Bits);

typedef union tagged {
  ReadResp   ReadHead;
  Bit#(128)  ReadData;
} MemRespPacket deriving (Bits);


(* synthesize *)
module mkTLPMemory#(PciId pciDevice) (TLPMemoryIfc);

  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 1024; // Use 10b of address on each 4B BRAM 2^10
    cfg.latency    = 1;
   
  //Vector#(4, BRAM1PortBE#(HexABits, DWord, 4)) mems <- replicateM(mkBRAM1ServerBE(cfg));
  Vector#(4, BRAM1Port#(HexABits, DWord)) mems <- replicateM(mkBRAM1Server(cfg));
  Reg#(Bool)            inIgnorePkt        <- mkRegU;
  FIFOF#(PTW16)         inF                <- mkFIFOF;
  FIFOF#(PTW16)         outF               <- mkFIFOF;
  FIFO#(MemReqPacket)   mReqF              <- mkFIFO;
  FIFO#(MemRespPacket)  mRespF             <- mkFIFO;
  Reg#(Bit#(10))        outDwRemain        <- mkRegU;
  Reg#(Bit#(12))        writeDWAddr        <- mkRegU;
  Reg#(Bit#(10))        writeRemainDWLen   <- mkRegU;
  Reg#(Bit#(4))         writeLastBE        <- mkRegU;
  Reg#(Bool)            readStarted        <- mkReg(False);
  Reg#(Bool)            readHeaderSent     <- mkRegU;
  Reg#(ReadReq)         readReq            <- mkRegU;
  Reg#(Bit#(10))        readReaminDWLen    <- mkRegU;
  Reg#(Bit#(12))        readNxtDWAddr      <- mkRegU;

  rule tlpRcv;
    PTW16 pw = inF.first;
    Ptw16Hdr p = unpack(pw.data);
    if (pw.sof) begin 
      MemReqHdr1 hdr       = unpack(pw.data[127:64]);  // Top 2DW of 4DW TLP has the hdr
      Bit#(10)   len       = hdr.length;
      Bit#(8)    tag       = hdr.tag;
      Bit#(3)    tc        = hdr.trafficClass;
      Bit#(4)    firstBE   = hdr.firstDWByteEn;
      Bit#(4)    lastBE    = hdr.lastDWByteEn;
      Bit#(2)    lowAddr10 = byteEnToLowAddr(hdr.firstDWByteEn);
      Bool       isWrite   = hdr.isWrite;
      PciId      srcReqID  = hdr.requesterID;
      DWAddress  dwAddr    = pw.data[63:34];          // Pick off dwAddr from 1st TLP
      DWord      firstDW   = truncate(pw.data);       // Bottom DW of 1st TLP is data
      Bool ignorePkt = p.hdr.isPoisoned || p.hdr.is4DW || p.hdr.pktType != 5'b00000;

      if (!ignorePkt) begin
        if (isWrite) begin
          WriteReq wreq = WriteReq {
            dwAddr   : truncate(dwAddr),
            dwLength : len,
            data     : byteSwap(firstDW),  // place Byte 0 in bits [7:0]
            firstBE  : firstBE,
            lastBE   : lastBE };
          MemReqPacket mpkt = WriteHeader(wreq);
          mReqF.enq(mpkt);
          //if (pw.eof) $display("[%0d] Mem: Finished single-cycle write (addr %x)", $time, {dwAddr,2'b00});
        end else begin
          ReadReq rreq = ReadReq {
            reqID    : srcReqID,
            dwLength : len,
            tag      : tag,
            tc       : tc,
            dwAddr   : truncate(dwAddr),
            firstBE  : firstBE,
            lastBE   : lastBE };
          MemReqPacket mpkt = ReadHeader(rreq);
          mReqF.enq(mpkt);
        end
      end

    // Update state in case there are multiple write data beats...
    inIgnorePkt <= ignorePkt;
    end else begin 

      if (!inIgnorePkt) begin
        MemReqPacket pkt = WriteData(pw.data); //FIXME: for byteSwap
        mReqF.enq(pkt);
        //if (pw.eof) $display("[%0d] Mem: Finished multi-cycle write (addr %x)", $time, {dwAddr,2'b00});
      end
    end

    inF.deq;
  endrule
   
  rule dataXmt_Header (mRespF.first matches tagged ReadHead .rres);
    mRespF.deq;
    CompletionHdr hdr =
      makeReadCompletionHdr(pciDevice, rres.reqID, rres.dwLength, rres.tag, rres.tc, rres.lowAddr, rres.byteCount);
    Bit#(128) pkt = { pack(hdr), rres.data };
    PTW16 w = PciTlpWord {
                data : pkt,
                rema : '1,
                hit  : ?,
                sof  : True,
                eof  : (rres.dwLength == 1)};
    outF.enq(w);
    outDwRemain <= rres.dwLength - 1;
  endrule

 rule dataXmt_Data (mRespF.first matches tagged ReadData .rdata);
    mRespF.deq;
    Bit#(16) last_rema =
      case (outDwRemain[1:0])
        2'b00 : 'hFFFF;
        2'b01 : 'hF000;
        2'b10 : 'hFF00;
        2'b11 : 'hFFF0;
      endcase;
    Bool isLastTLP = (outDwRemain <= 4);
    PTW16 w = PciTlpWord {
                data : rdata,
                rema : (isLastTLP ? last_rema : '1),
                hit  : ?,
                sof  : False,
                eof  : isLastTLP };
    outF.enq(w);
    outDwRemain <= outDwRemain - 4;
  endrule

  // Perform the first memory write...
  rule writeReq (mReqF.first matches tagged WriteHeader .wreq);
    mReqF.deq;
    writeDWAddr       <= wreq.dwAddr   + 1;
    writeRemainDWLen  <= wreq.dwLength - 1;
    writeLastBE       <= wreq.lastBE;
    //let req = BRAMRequestBE { writeen:wreq.firstBE, address:wreq.dwAddr[11:2], datain:wreq.data, responseOnWrite:False };
    let req = BRAMRequest { write:True, address:wreq.dwAddr[11:2], datain:wreq.data, responseOnWrite:False };
    mems[wreq.dwAddr[1:0]].portA.request.put(req);  // We can write the 1st DW right away
    $display("[%0d] Mem: Writing first word (addr %x)", $time, {wreq.dwAddr,2'b00});
    $display("Writing %0h to addr %0h of mem %0d", req.datain, req.address, wreq.dwAddr[1:0]);
  endrule

  // Perform any subsequent memory writes...
  rule writeData (mReqF.first matches tagged WriteData .wrdata);
    mReqF.deq;
    Vector#(4, DWord)    vWords   = reverse(unpack(wrdata));
    Vector#(4, HexABits) vAddrs   = ?;
    Vector#(4, Bool)     vInclude = ?;
    Vector#(4, Bit#(4))  vByteEn  = ?;

    for (Integer i=0; i<4; i=i+1) begin
      vAddrs[i]   = (writeDWAddr + fromInteger(i))[11:2];
      vInclude[i] =  writeRemainDWLen  > fromInteger(i);
      vByteEn[i]  = (writeRemainDWLen  == fromInteger(i+1)) ?  writeLastBE : 4'hF ;
    end

    for (Integer i=0; i<4; i=i+1) begin
      Bit#(2) idx = fromInteger(i) - writeDWAddr[1:0];
      //let req = BRAMRequestBE { writeen:vByteEn[idx], address:vAddrs[idx], datain:vWords[idx], responseOnWrite:False };
      let req = BRAMRequest { write:True, address:vAddrs[idx], datain:vWords[idx], responseOnWrite:False };
      if (vInclude[idx]) begin
        mems[i].portA.request.put(req);
        $display("Writing %0h to addr %0h of mem %0d",req.datain, req.address, i);
      end
    end

    writeDWAddr       <= writeDWAddr      + 4;
    writeRemainDWLen  <= writeRemainDWLen - 4;
    $display("[%0d] Mem: Writing next words (addr %x, len %0d)", $time, {writeDWAddr,2'b00}, writeRemainDWLen );
  endrule


  // Perform the first memory read request...
  rule read_FirstReq (!readStarted &&& mReqF.first matches tagged ReadHeader .rreq);
    readHeaderSent <= False;
    readReq        <= rreq;
    if (rreq.dwLength == 1) mReqF.deq;
    else readStarted <= True;
    //let req = BRAMRequestBE { writeen:4'd0, address:rreq.dwAddr[11:2], datain:'0, responseOnWrite:False };
    let req = BRAMRequest { write:False, address:rreq.dwAddr[11:2], datain:'0, responseOnWrite:False };
    mems[rreq.dwAddr[1:0]].portA.request.put(req);
    readReaminDWLen  <= rreq.dwLength - 1;
    readNxtDWAddr    <= rreq.dwAddr + 1;
    $display("[%0d] Mem: First read request (addr %x, len %0d)", $time, {rreq.dwAddr,2'b00}, rreq.dwLength);
    $display("Reading addr %0h of mem %0d", req.address, rreq.dwAddr[1:0]);
  endrule

  // Process the first read response...
  rule read_FirstResp (!readHeaderSent);
    let rreq = readReq;
    Bit#(32) data <- mems[rreq.dwAddr[1:0]].portA.response.get;
    Bit#(2) lowAddr10 = byteEnToLowAddr(rreq.firstBE);
    Bit#(7) lowAddr = {truncate(rreq.dwAddr), lowAddr10};
    Bit#(12) byteCount = computeByteCount(rreq.dwLength, rreq.firstBE, rreq.lastBE);
    let rresp = ReadResp { reqID     : rreq.reqID,
                           dwLength  : rreq.dwLength,
                           lowAddr   : lowAddr,
                           byteCount : byteCount,
                           tag       : rreq.tag,
                           tc        : rreq.tc,
                           data      : byteSwap(data) };  //TODO: byteSwap
    let pkt = ReadHead(rresp);
    mRespF.enq(pkt);
    readHeaderSent <= True;
    $display("[%0d] Mem: First read response enqueued (data %x)", $time, data);  //TODO: byteSwap
  endrule

  // Perform any subsequent read requests...
  rule read_NextReq (readStarted &&& mReqF.first matches tagged ReadHeader .rreq);
    if (readReaminDWLen  <= 4) begin
      readStarted <= False;
      mReqF.deq;
    end
    readReaminDWLen  <= readReaminDWLen - 4;
    readNxtDWAddr    <= readNxtDWAddr   + 4;
    $display("[%0d] Mem: Next read request (addr %x, len %0d)", $time, {readNxtDWAddr,2'b00}, readReaminDWLen );

    Vector#(4, HexABits) vAddrs = ?;
    for (Integer i=0; i<4; i=i+1)
      vAddrs[i] = (readNxtDWAddr + fromInteger(i))[11:2];

    for (Integer i=0; i<4; i=i+1) begin
      Bit#(2) idx = fromInteger(i) - readNxtDWAddr[1:0];
      //let req = BRAMRequestBE { writeen:4'd0, address:vAddrs[idx], datain:'0, responseOnWrite:False };
      let req = BRAMRequest { write:False, address:vAddrs[idx], datain:'0, responseOnWrite:False };
      mems[i].portA.request.put(req);
      $display("Reading addr %0h of mem %0d", req.address, i);
    end
  endrule

  // Process any subsequent read responses...
  rule read_NextResp (readHeaderSent);
    Vector#(4, Bit#(32)) vResps = ?;
    for (Integer i=0; i<4; i=i+1) vResps[i] <- mems[i].portA.response.get;
    UInt#(2)  idx = unpack(readNxtDWAddr[1:0]);
    Bit#(128) rdata = pack(reverse(rotateBy(vResps,idx)));  //TODO: byteSwap
    let pkt = ReadData(rdata);
    mRespF.enq(pkt);
    $display("[%0d] Mem: Next read enqueued (data %x)", $time, rdata);
  endrule

  interface Server server;
    interface request  = toPut(inF);
    interface response = toGet(outF);
  endinterface

endmodule

endpackage: TLPMemory

