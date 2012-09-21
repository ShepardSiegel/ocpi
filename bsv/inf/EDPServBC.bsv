// EDPServBC.bsv - EDP Server, BRAM Client
// Copyright (c) 2009,2010,2011,2102 Atomic Rules LLC - ALL RIGHTS RESERVED

// For use with Bluesim, you need to undefine USE_SRLFIFO, as mkSRLFIFO is not yet a BSV 
// primative, it is importBVI of Atomic Rules Verilog...
//`define USE_SRLFIFO

import DGDP         ::*;
import E8023        ::*;
import OCBufQ       ::*;
import OCWip        ::*;
import PCIE         ::*;
import SRLFIFO      ::*;
import TLPBRAM      ::*;
import TLPMF        ::*;

import BRAM         ::*;
import BRAMFIFO     ::*;	
import ClientServer ::*; 
import DReg         ::*;
import FIFO         ::*;
import FIFOF        ::*;
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;


interface EDPServBCIfc;
  interface Server#(QABS,QABS)   server;
  interface BufQCIfc             bufq;
  method Action                  dpCtrl (DPControl dc);
  method Bit#(32)                i_flowDiagCount;
  method Bit#(32)                i_dbgBytesTxEnq;
  method Bit#(32)                i_dbgBytesTxDeq;
  method Bit#(32)                i_debug;
  method Vector#(4,Bit#(32))     i_meta;
  method Action                  now    (Bit#(64) arg);
  method Bool                    dmaStartPulse;
  method Bool                    dmaDonePulse;
  method Bool                    doorBellPulse;
endinterface

typedef enum {Idle,NearReqMeta,NearRespMeta,NearReqMesg,PushMesgHead,PushMesgBody,
  PushMetaHead,PushMetaBody,TailEvent,PostDwell} PushDMAState deriving (Bits,Eq);
typedef enum {Idle,FarReqMeta, FarRespMeta, FarReqMesg, PullMesgHead,PullMesgBody,
  TailEvent,PostDwell} PullDMAState deriving (Bits,Eq);

typedef 5 NtagBits; // Must match PCIe configureation: 5b tag is the default; 8b is optional; 11b with phantom-tags stealing 3b device num

// Rule naming for Pull debug...
typedef enum {
  R_none                  = 15,
  R_dmaRequestFarMeta     = 1,
  R_dmaRespHeadFarMeta    = 2,
  R_dmaRespBodyFarMeta    = 3,
  R_dmaPullRequestFarMesg = 4,
  R_dmaPullResponseHeader = 5,
  R_dmaPullResponseBody   = 6,
  R_dmaPullTailEvent      = 7,
  R_dmaTailEventSender32  = 8,
  R_dmaTailEventSender64a = 9,
  R_dmaTailEventSender64b = 10
  } DmaPullRules deriving (Bits,Eq);

module mkEDPServBC#(Vector#(4,BRAMServer#(DPBufHWAddr,Bit#(32))) mem, PciId pciDevice, WciSlaveIfc#(32) wci, Bool hasPush, Bool hasPull) (EDPServBCIfc);

  FIFOF#(QABS)               inF                  <- mkFIFOF;                // The QABS RX inbound from the fabric
  FIFOF#(QABS)               inProcF              <- mkFIFOF;                // 
  FIFOF#(QABS)               outF                 <- mkFIFOF;                // The QABS TX outbound to the fabric
  FIFOF#(QABS)               outBF                <- mkSizedBRAMFIFOF(1024);
  FIFOF#(Bit#(0))            outTF                <- mkFIFOF;
  TLPBRAMIfc                 tlpBRAM              <- mkTLPBRAM(mem);
  FIFOF#(Bit#(1))            tailEventF           <- mkFIFOF;
  Reg#(Bool)                 inIgnorePkt          <- mkRegU;
  Reg#(Bit#(10))             outDwRemain          <- mkRegU;
  Reg#(Bool)                 tlpRcvBusy           <- mkReg(False);  // the inbound, downstream mutex
  Reg#(Bool)                 tlpXmtBusy           <- mkReg(False);  // the outbound,  upstream mutex
  Reg#(Bool)                 remStart             <- mkDReg(False);
  Reg#(Bool)                 remDone              <- mkDReg(False);
  Reg#(Bool)                 nearBufReady         <- mkDReg(False);
  Reg#(Bool)                 farBufReady          <- mkDReg(False);
  Reg#(Bool)                 creditReady          <- mkDReg(False);
  Reg#(Bit#(16))             remMetaAddr          <- mkRegU;
  Reg#(Bit#(16))             remMesgAddr          <- mkRegU;
  Reg#(Bit#(16))             remMesgAccu          <- mkRegU;
  Reg#(Bit#(32))             fabMetaAddr          <- mkRegU;
  Reg#(Bit#(32))             fabMesgAddr          <- mkRegU;
  Reg#(Bit#(32))             fabFlowAddr          <- mkRegU;
  Reg#(Bit#(32))             fabMetaAddrMS        <- mkRegU;
  Reg#(Bit#(32))             fabMesgAddrMS        <- mkRegU;
  Reg#(Bit#(32))             fabFlowAddrMS        <- mkRegU;
  Reg#(Bit#(32))             srcMesgAccu          <- mkRegU;
  Reg#(Bit#(32))             fabMesgAccu          <- mkRegU;
  Reg#(Bit#(4))              postSeqDwell         <- mkReg(0);
  Reg#(Bit#(4))              doorSeqDwell         <- mkReg(0);
  Reg#(Bool)                 reqMetaInFlight      <- mkReg(False);
  Reg#(Bool)                 reqMetaBodyInFlight  <- mkReg(False);
  Reg#(Bool)                 xmtMetaInFlight      <- mkReg(False);
  Reg#(Bool)                 doXmtMetaBody        <- mkReg(False);
  Reg#(Bool)                 reqMesgInFlight      <- mkReg(False);
  Reg#(Bool)                 xmtMetaOK            <- mkReg(False);
  Reg#(Bool)                 tlpMetaSent          <- mkReg(False);
  Reg#(Bool)                 sentTail4DWHeader    <- mkReg(False);
  Reg#(Maybe#(MesgMeta))     fabMeta              <- mkReg(Invalid);
  Wire#(DPControl)           dpControl            <- mkWire;
  Reg#(Bit#(NtagBits))       dmaTag               <- mkReg(0); 
  Reg#(Bit#(NtagBits))       dmaReqTag            <- mkRegU;
  Reg#(Bit#(10))             dmaPullRemainDWLen   <- mkRegU;
  Reg#(Bit#(10))             dmaPullRemainDWSub   <- mkRegU;
  Reg#(Bool)                 gotResponseHeader    <- mkReg(False);
  Reg#(Bool)                 pullTagMatch         <- mkDReg(False);
  Reg#(Bool)                 dmaDoTailEvent       <- mkReg(False);
  Reg#(Bit#(17))             mesgLengthRemainPush <- mkRegU;      // Size limits maximum DMA message just under 128KB (was 2^24 but slow path) (for Push Logic)
  Reg#(Bit#(17))             mesgLengthRemainPull <- mkRegU;      // Size limits maximum DMA message just under 128KB (was 2^24 but slow path) (for Pull Logic)
  Reg#(Bit#(17))             mesgComplReceived    <- mkRegU;      // Size limits maximum DMA message just under 128KB (was 2^24 but slow path)
  Reg#(Bit#(13))             maxPayloadSize       <- mkReg(128);  // 128B Typical - Must not exceed 4096B
  Reg#(Bit#(13))             maxReadReqSize       <- mkReg(4096); // 512B Typical - Must not exceed 4096B
  Reg#(Bit#(32))             flowDiagCount        <- mkReg(0);
  Reg#(DmaPullRules)         lastRuleFired        <- mkReg(R_none);
  Reg#(Bool)                 complTimerRunning    <- mkReg(False);
  Reg#(UInt#(12))            complTimerCount      <- mkReg(0);
  Vector#(4,Reg#(Bit#(32)))  lastMetaV            <- replicateM(mkReg(0));
  Wire#(Bit#(64))            nowW                 <- mkWire;

  Reg#(Bool)                 dmaStartMark         <- mkDReg(False);
  Reg#(Bool)                 dmaDoneMark          <- mkDReg(False);

  // New State for the EDP is here...
  Reg#(UInt#(16))            frameNumber          <- mkReg(16'h1234);
  Reg#(UInt#(32))            xactionNumber        <- mkReg(32'h1234_5678);
  Reg#(Bool)                 doMetaMH             <- mkReg(False);
  Reg#(Bool)                 doMesgMH             <- mkReg(False);
  Reg#(Bool)                 firstMetaMH          <- mkReg(True);
  Reg#(Bool)                 firstMesgMH          <- mkReg(True);
  Reg#(Bit#(32))             dbgBytesTxEnq        <- mkReg(0);
  Reg#(Bit#(32))             dbgBytesTxDeq        <- mkReg(0);
  Reg#(UInt#(32))            dataAddr             <- mkReg(0);
  Reg#(UInt#(16))            dataLen              <- mkReg(0);
  Reg#(UInt#(16))            ackStart             <- mkReg(0);
  Reg#(UInt#(8))             ackCount             <- mkReg(0);
  Reg#(UInt#(8))             frmFlags             <- mkReg(8'h01);
  Reg#(UInt#(16))            mesgSeq              <- mkReg(0);
  Reg#(Bit#(8))              mhType               <- mkReg(0);
  Reg#(Bit#(8))              mhFlags              <- mkReg(0);
  
  Reg#(Bool)                 frmAckOK             <- mkReg(True);
  Reg#(Bool)                 frmMesgBusy          <- mkReg(False);

  QDW2DWIfc                  outFunl              <- mkQDW2DW;

  Reg#(UInt#(4))             igPtr                <- mkReg(0);
  Reg#(Bool)                 doorBell             <- mkDReg(False);


  Bit#(16) dstID = fabMesgAddrMS[15:0];
  Bit#(16) srcID = fabMesgAddrMS[31:16];

  // Data goes on-the-wire LS Octet First...
  Stmt seqFrameHeader =
  seq
     outBF.enq(qabsFromBits({dstID,          16'h0000},                        4'b0000));   // 2B
     outBF.enq(qabsFromBits({pack(frameNumber), srcID},                        4'b0000));   // 4B 
     outBF.enq(qabsFromBits({pack(frmFlags), pack(ackCount), pack(ackStart) }, 4'b0000));   // 4B 
  endseq;
  FSM fhFsm <- mkFSM(seqFrameHeader);

  Stmt seqMesgHeader =
  seq
     outBF.enq(qabsFromBits(pack(xactionNumber),            4'b0000));   // 4B
     outBF.enq(qabsFromBits(pack(fabFlowAddr),              4'b0000));   // 4B
     outBF.enq(qabsFromBits(32'h0000_0001,                  4'b0000));   // 4B
     outBF.enq(qabsFromBits({pack(mesgSeq), 16'h0002},      4'b0000));   // 4B
     outBF.enq(qabsFromBits(pack(dataAddr),                 4'b0000));   // 4B
     outBF.enq(qabsFromBits({mhFlags,mhType,pack(dataLen)}, 4'b0000));   // 4B
  endseq;
  FSM mhFsm <- mkFSM(seqMesgHeader);



  // Note that there are few, if any, reasons why the maxReadReqSize should not be maxed out at 4096 in the current implementation.
  // This is because with only one read in-flight at once, we wish to amortize the serial latency over as large a request as possible.
  // When moving to two or more read-requests per DMA engine in flight at once, we may wish to lower maReadReqSize from the maximum.
  // The team thanks Dan Zhang for bringing this issues front and center. -Shep Siegel 2011-03-10

  Bool actMesgP = (dpControl==fProdActMesg);
  Bool actMesgC = (dpControl==fConsActMesg);
  Bool actFlow  = (dpControl.role==ActFlow);

  //TODO: Understand why psDwell=1 failed dmaTestBasic4 on 2010-11-02
  // Non-Zero dwell required until BufQ logic is cleared of all dead-reckoning; then suggest removal
  Bit#(4) psDwell = (actFlow ? 8 : 4);  // Was 15 in all modes through Q3-CY2011 ; halved and halved again when not activeFlow


  // hasPush Transmit...

  //
  // FPactMesg - Fabric Producer Push DMA Sequence...
  //

  // Request the metadata for the remote-facing ready buffer...
  rule dmaRequestNearMeta (hasPush && actMesgP && !reqMetaInFlight && !isValid(fabMeta) && nearBufReady && farBufReady && postSeqDwell==0 && !outBF.notEmpty && !outTF.notEmpty && frmAckOK);
    frmAckOK        <= False;  // Just one at a time
    frmMesgBusy     <= True;   // Frame Message in progress - block others
    dmaStartMark    <= True;
    remStart        <= True;   // Indicate to buffer-management remote move start
    reqMetaInFlight <= True;
    ReadReq rreq = ReadReq {
      skipRespData : False,
      role         : Metadata,
      reqID        : PciId {bus:255, dev:31, func:0},
      dwLength     : 4,        // Request all 4DW of metadata (One alligned 16B superword)
      tag          : ?,
      tc           : ?,
      dwAddr       : truncate(remMetaAddr>>2),
      firstBE      : '1,
      lastBE       : '1 };
    MemReqPacket mpkt = ReadHeader(rreq);
    tlpBRAM.putReq.put(mpkt);  // Enqueue BRAM read request for metadata
    $display("[%0d]: %m: dmaRequestNearMeta FPactMesg-Step1/7", $time);
    fhFsm.start;
    frameNumber <= frameNumber + 1;
    doMetaMH <= True; 
  endrule

  rule send_metaMH (doMetaMH && fhFsm.done);  // Send dgdp mesageheader for metadata...
    mesgSeq  <= 0;
    dataAddr <= unpack(fabMetaAddr);
    dataLen  <= 16;
    mhType   <= 1;  // meta
    mhFlags  <= 1;
    mhFsm.start;
    doMetaMH  <= False;
  endrule

  // Accept the first DW metadata back... 
  rule dmaResponseNearMetaHead (hasPush && actMesgP &&& tlpBRAM.getsResp.first matches tagged ReadHead .rres &&& rres.role==Metadata &&& mhFsm.done);
    tlpBRAM.getsResp.deq;
    mesgLengthRemainPush <= truncate(byteSwap(rres.data));  // undo the PCI byteSwap on the 1st DW (mesgLength)
    lastMetaV[0]         <=          byteSwap(rres.data);   // push length
    $display("[%0d]: %m: dmaResponseNearMetaHead FPactMesg-Step2a/7 mesgLength:%0x", $time, byteSwap(rres.data));
  endrule

  // Accept the remaining metadata back and then commit to MesgMeta format..
  rule dmaResponseNearMetaBody (hasPush && actMesgP &&& tlpBRAM.getsResp.first matches tagged ReadBody .rres &&& rres.role==Metadata &&& mhFsm.done);
    tlpBRAM.getsResp.deq;
    Vector#(4, DWord) vWords = reverse(unpack(rres.data));
    Bit#(32) opcode  = byteSwap(vWords[0]); lastMetaV[1] <= opcode;
    Bit#(32) nowMS   = byteSwap(vWords[1]); lastMetaV[2] <= nowMS;
    Bit#(32) nowLS   = byteSwap(vWords[2]); lastMetaV[3] <= nowLS;
    reqMetaInFlight <= False;
    fabMeta <= (Valid (MesgMeta{length:extend(mesgLengthRemainPush), opcode:opcode, nowMS:nowMS, nowLS:nowLS}));
    xmtMetaOK <= (mesgLengthRemainPush==0); // Skip over Message Movement phases and just send metadata if mesgLength is zero
    mesgLengthRemainPush <= (mesgLengthRemainPush+3) & ~3; // DWORD roundup - shep owes Jim a beer
    remMesgAccu <= remMesgAddr;  // Load the message rem address accumulator so we can locally manage message segments
    srcMesgAccu <= fabMesgAddr;  // Load the message src address accumulator so we can locally manage message segments
    fabMesgAccu <= fabMesgAddr;  // Load the message fab address accumulator so we can locally manage message segments
    $display("[%0d]: %m: dmaResponseNearMetaBody FPactMesg-Step2b/7 opcode:%0x nowMS:%0x nowLS:%0x", $time, opcode, nowMS, nowLS);

    outFunl.putVector.put(unpack({nowLS, nowMS, opcode, lastMetaV[0]})); // 16B metadata
    doMesgMH <= True; // Triger to send the mesg-data message header...
  endrule

  rule drain_outFunl;
    let a <- outFunl.getSerial.get;
    outBF.enq(qabsFromBits(a, 4'b0000));
  endrule

  rule send_mesgMH (mhFsm.done && doMesgMH && outFunl.isEmpty);  // Ensure Metadata Message body is clear before we send the MH for the data...
    mesgSeq  <= 1;
    dataAddr <= unpack(fabMesgAddr);
    dataLen  <= unpack(truncate(lastMetaV[0]));
    mhType   <= 0;  // data
    mhFlags  <= 0;
    mhFsm.start;
    doMesgMH <= False;
  endrule



  // Steps 3, 4a, 4b to be repeated 0-N times.
  //   0 times if there is no message data to be moved.
  //   1 or more times based on how many segments the fabric address-length tuple dictates
  //   Policy includes: i) Do not exceed (typ 128B) Maximum Paylod Size MPS); ii) Do not cross 4KB bounds.

  // Request the message from the remote-facing ready buffer...
  // Inhibit this rule while tlpRcvBusy with other rem buffer access...
  // If needed, make multiple requests until the full extent of the message is traversed, as signalled by mesgLengthRemainPush==0...
  rule dmaPushRequestMesg (hasPush && actMesgP &&& fabMeta matches tagged Valid .meta &&& meta.length!=0 &&& !tlpRcvBusy &&& mesgLengthRemainPush!=0 &&& !doMesgMH &&& mhFsm.done);
    Bit#(13) spanToNextPage = 4096 - extend(srcMesgAccu[11:0]);                                                 // how far until we hit a PCIe 4K Page
    //Bit#(13) thisRequestLength = min(min(truncate(min(mesgLengthRemainPush,4096)),maxPayloadSize),spanToNextPage);  // minimum of what we want and what we are allowed
    Bit#(13) thisRequestLength = min(truncate(min(mesgLengthRemainPush,extend(maxPayloadSize))),spanToNextPage);  // minimum of what we want and what we are allowed 
    mesgLengthRemainPush  <= mesgLengthRemainPush - extend(thisRequestLength);
    //lastSegmentOfMessage <= (mesgLengthRemainPush - extend(thisRequestLength)) < min(maxPayloadSize, f(spanToNextPage) TODO: Needs work to pipeline critical path to EoM tag
    ReadReq rreq = ReadReq {
      skipRespData : (fabMesgAddrMS!='0),  // skip when non-zero MesgMS Addr; This is the special behavior taken for 64b Mesg addr in this rule
      role         : DMASrc,
      reqID        : PciId {bus:255, dev:31, func:0},
      dwLength     : truncate(thisRequestLength>>2),
      tag          : (extend(thisRequestLength)==mesgLengthRemainPush)?8'h01:8'h00, // Tag the last segment of a message request with 8'h01
      tc           : ?,
      dwAddr       : truncate(remMesgAccu>>2),
      firstBE      : '1,
      lastBE       : '1 };
    MemReqPacket mpkt = ReadHeader(rreq);
    srcMesgAccu <= srcMesgAccu + extend(thisRequestLength);  // increment src side of the message dest address
    remMesgAccu <= remMesgAccu + extend(thisRequestLength);  // increment the rem address accumulator
    tlpBRAM.putReq.put(mpkt);  // Enqueue BRAM read request for message data
    $display("[%0d]: %m: dmaPushRequestMesg FPactMesg-Step3/7", $time);
  endrule


  // Transform the local read response header to a PCIe posted write request header for push DMA...
  rule dmaPushResponseHeader (hasPush && actMesgP &&& tlpBRAM.getsResp.first matches tagged ReadHead .rres &&& rres.role==DMASrc && !tlpXmtBusy && postSeqDwell==0);
    Bool onlyBeatInSegment = (rres.dwLength==1);
    Bool lastSegmentInMesg = (rres.tag==8'h01); 
    // 4DW only...
    onlyBeatInSegment = False;
    MemReqHdr1 h = makeWrReqHdr(pciDevice, rres.dwLength, '1, (rres.dwLength>1)?'1:'0, True); // 4DW MWr
    let w = PTW16 { data : {pack(h), fabMesgAddrMS, fabMesgAccu}, be:'1, hit:7'h2, sof:True, eof:onlyBeatInSegment };
    //
    // Replace with EDP - outF.enq(w);  // Out goes the 4DW request + no data
    // Nothing to do here
    //
    outDwRemain <= rres.dwLength - ((fabMesgAddrMS=='0) ? 1 : 0);  // update dwords remaining
    fabMesgAccu <= fabMesgAccu + (extend(rres.dwLength)<<2);       // increment the fabric address accumulator
    if (!onlyBeatInSegment) tlpXmtBusy <= True;                    // acquire outbound mutex
    if ( onlyBeatInSegment && lastSegmentInMesg) begin
      xmtMetaOK  <= True;   // message sent, move on to metadata
      tlpXmtBusy <= False;  // release outbound mutex
    end
    tlpBRAM.getsResp.deq; // Consume the BRAM response, even if there was no data and just header
    $display("[%0d]: %m: dmaPushResponseHeader FPactMesg-Step4a/7", $time);
  endrule

  // continue the transformation for the local-read to fabric-write payload body...
  // this rule finishes up the push without regard to message address space
  rule dmaPushResponseBody (hasPush && actMesgP &&& tlpBRAM.getsResp.first matches tagged ReadBody .rbody &&& rbody.role==DMASrc &&& mhFsm.done);
    tlpBRAM.getsResp.deq;
    Bool lastBeatInSegment = (outDwRemain <= 4);
    Bool lastSegmentInMesg = (rbody.tag==8'h01); 
    PTW16 w = TLPData {
                data : rbody.data,
                be   : (lastBeatInSegment ? remFromDW(outDwRemain[1:0]) : '1),
                hit  : 7'h2,
                sof  : False,
                eof  : lastBeatInSegment };
    //
    // Replace with EDP - outF.enq(w);  // out goes follow-on write data
    Vector#(16,Bit#(8)) metaV = unpack({lastMetaV[3], lastMetaV[2], lastMetaV[1], lastMetaV[0]}); // 16B metadata

    
    // 
    // Data Push Body
    //
    Vector#(4,Bit#(32)) rd = unpack(reverseDWORDS(rbody.data));  // Reverse the order of the DWORDs
                        rd = map(reverseBYTES, rd);              // Then reverse the Bytes within each DWORD
    outFunl.putVector.put(rd);
    //outFunl.putVector.put(unpack(rbody.data));

    outDwRemain <= outDwRemain - 4;                                   // update DW remaining in this segment
    if (lastBeatInSegment)                      tlpXmtBusy <= False;  // release outbound mutex
    if (lastBeatInSegment && lastSegmentInMesg) xmtMetaOK  <= True;   // message sent, move on to metadata
    $display("[%0d]: %m: dmaPushResponseBody FPactMesg-Step4b/7", $time);
  endrule

  // Transmit the Metadata header...
  rule dmaXmtMetaHead (hasPush && actMesgP &&& fabMeta matches tagged Valid .meta &&& !tlpXmtBusy && !xmtMetaInFlight && xmtMetaOK && postSeqDwell==0);
    xmtMetaInFlight <= True;
    tlpXmtBusy      <= True;
    doXmtMetaBody   <= True;
    xmtMetaOK       <= False;
    // This rule has two different behaviors depending on if we must make a 32b or 64b MWr request
    if (fabMetaAddrMS=='0) begin
      MemReqHdr1 h = makeWrReqHdr(pciDevice, 4, '1, '1, False); 
      let w = PTW16 { data : {pack(h), fabMetaAddr, byteSwap(extend(meta.length))}, be:'1, hit:7'h2, sof:True, eof:False };
      //
      // Replace with EDP - outF.enq(w);  // Out goes 3DW header + 1 DW of metadata
      //
    end else begin
      MemReqHdr1 h = makeWrReqHdr(pciDevice, 4, '1, '1, True); 
      let w = PTW16 { data : {pack(h), fabMetaAddrMS, fabMetaAddr}, be:'1, hit:7'h2, sof:True, eof:False };
      //
      // Replace with EDP - outF.enq(w);  // Out goes 4DW header + 0 Data
      //
    end
    $display("[%0d]: %m: dmaXmtMetaHead FPactMesg-Step5/7", $time);
  endrule

  // and then the Metadata body...
  rule dmaXmtMetaBody (hasPush && actMesgP &&& fabMeta matches tagged Valid .meta &&& doXmtMetaBody);
    remDone         <= True;  // Indicate to buffer-management remote move done (tail event doesn't care about mesg/meta state)
    doXmtMetaBody   <= False;
    tlpXmtBusy      <= False;
    tlpMetaSent     <= True;
    Bit#(32) opcode  = meta.opcode;
    Bit#(32) nowMS   = meta.nowMS;
    Bit#(32) nowLS   = meta.nowLS;
    if (fabMetaAddrMS=='0) begin
      let w = PTW16 {data:{byteSwap(opcode), byteSwap(nowMS), byteSwap(nowLS), 32'b0}, be:16'hFFF0, hit:7'h2, sof:False, eof:True };
      //
      // Replace with EDP - outF.enq(w);  // Out goes the rest of metadata write
      //
    end else begin
      let w = PTW16 {data:{byteSwap(extend(meta.length)), byteSwap(opcode), byteSwap(nowMS), byteSwap(nowLS)}, be:16'hFFFF, hit:7'h2, sof:False, eof:True };
      //
      // Replace with EDP - outF.enq(w);  // Out goes all of metadata write
      //
    end
    $display("[%0d]: %m: dmaXmtMetaBody FPactMesg-Step6/7", $time);
  endrule

  // Transmit the DMA-PUSH TailEvent...
  rule dmaXmtTailEvent (hasPush && actMesgP &&& fabMeta matches tagged Valid .meta &&& tlpMetaSent);
    xmtMetaInFlight <= False;
    tlpMetaSent     <= False;
    tailEventF.enq(0);  // Send a tail event that does NOT generate a remDone (done in dmaXmtMetaBody)
    $display("[%0d]: %m: dmaXmtTailEvent FPactMesg-Step7/7", $time);

   outBF.enq(qabsFromBits(reverseBYTES(32'hFEEDC0DE), 4'b1000));   // Tail FE on the wire first
   outTF.enq(?); // send the frame in outBF
   frmMesgBusy <= False;  // release the guard so we can send ack-only frames to ack the flow control

  endrule

  // This rule used at the end of all Active transfers to purposefully insert a small amount of dwell time...
  rule dmaPostSeqDwell (postSeqDwell!=0); postSeqDwell <= postSeqDwell - 1; endrule
  rule dmaDoorSeqDwell (doorSeqDwell!=0); doorSeqDwell <= doorSeqDwell - 1; endrule

  // FCactFlow - Fabric Consumer Sending Doorbells
  // FPactFlow - Fabric Consumer Sending Doorbells
  // 
  // FIXME: There are two dead-reakoning races here that need to be fixed structurally
  // i)  Remove the use of doorSeqDwell that serves to keep this rule from re-firing before creditReady has updated from remStart
  // ii) There is a race between
  //      a) remStart, which is used to increment the fabFlowAddr
  //      b) the use of fabFlowAddr at the deq
  // We are counting on (b) to win so we use the correct address (not the incremented address)
  // Send Doorbells to tell the far side of our near buffer availability...
  rule dmaXmtDoorbell (actFlow && creditReady && doorSeqDwell==0);  // FIXME: Race from remStart->OCBufQ->creditReady is gated by doorSeqDwell
    remStart      <= True;    // Indicate to buffer-management to decrement LBCF, and advance crdBuf and fabFlowAddr
    doorSeqDwell  <= 8;
    flowDiagCount <= flowDiagCount + 1;
    tailEventF.enq(0);        // Send a tail event with no remDone
    $display("[%0d]: %m: dmaXmtDoorbell FC/FPactFlow-Step1/1", $time);
  endrule



  // Generic TailEvent Sender (Used at end of push, pull, and for flow signal to fabFlowAddr)...
  // This rule will fire twice in the 4DW (64b addr) case; make sure the two PTW16s come sequentially
  rule dmaTailEventSender( (!tlpXmtBusy && !sentTail4DWHeader && postSeqDwell==0) || (tlpXmtBusy && sentTail4DWHeader));
    Bit#(32) eventData = truncate(nowW>>5) | 32'h0000_0001; // radix point has 5b integer (wrap at 32 seconds)
    dmaDoneMark <= True;
    if (fabFlowAddrMS=='0) begin
      if (tailEventF.first==1) remDone <= True; // For dmaPullTailEvent: Indicate to buffer-management remote move done  FIXME - pipeline allignment address advance
      postSeqDwell   <= psDwell;
      fabMeta        <= (Invalid);
      tailEventF.deq;
      MemReqHdr1 h = makeWrReqHdr(pciDevice, 1, '1, '0, False);
      let w = PTW16 { data : {pack(h), fabFlowAddr, byteSwap(eventData)}, be:'1, hit:7'h2, sof:True, eof:True };
      //
      // Replace with EDP - outF.enq(w); // Out goes the tail event write 3DW + 1 DW 0x0000_0001 non-zero
      //
      lastRuleFired  <= R_dmaTailEventSender32;
    end else begin
      if (!sentTail4DWHeader) begin
        if (tailEventF.first==1) remDone <= True; // For dmaPullTailEvent: Indicate to buffer-management remote move done  FIXME - pipeline allignment address advance
        MemReqHdr1 h = makeWrReqHdr(pciDevice, 1, '1, '0, True);
        let w = PTW16 { data : {pack(h), fabFlowAddrMS, fabFlowAddr}, be:'1, hit:7'h2, sof:True, eof:False };
        //
        // Replace with EDP - outF.enq(w); // Out goes the tail event write 4DW 
        //
        lastRuleFired  <= R_dmaTailEventSender64a;
        sentTail4DWHeader <= True;  // enable second term of rule predacate
        tlpXmtBusy        <= True;
      end else begin
        postSeqDwell   <= psDwell; 
        fabMeta        <= (Invalid);
        tailEventF.deq;
        let w = PTW16 {data:{byteSwap(eventData), byteSwap(0), byteSwap(0), byteSwap(0)}, be:16'hF000, hit:7'h2, sof:False, eof:True };
        //
        // Replace with EDP - outF.enq(w);  
        //
        lastRuleFired  <= R_dmaTailEventSender64b;
        sentTail4DWHeader <= False;
        tlpXmtBusy     <= False;
      end
    end
    $display("[%0d]: %m: dmaTailEventSender - generic", $time);
  endrule

  rule completionTimer;
    complTimerCount <= (complTimerRunning) ? complTimerCount + 1 : 0 ;
  endrule

  rule output_pump (outTF.notEmpty);    // outTF occupancy enables frame output pump
    let z = outBF.first; outBF.deq;
    outF.enq(z);
  endrule

  rule frame_complete (outTF.notEmpty && !outBF.notEmpty); // When outBF empties, deq outTF
    outTF.deq;
  endrule


  // Temporary Blind Assumption:
  // All messages in signal exactly one flow control event and ack one previously sent frame
  rule ingress;
    let x <- toGet(inF).get;
    Bit#(32) dw = pack(map(getData,x));
    Bool hasEOP = unpack(reduceOr(pack(map(isEOP,x))));
    igPtr <= hasEOP ? 0:(igPtr==15) ? 15:igPtr+1; 
    if (igPtr==0) ackStart <= unpack({dw[23:16],dw[31:24]}); // pick off the incident FS and copy it to ackStart for next transmission
    if (hasEOP)  ackCount <= 1;    // To replace the 0 default used on the first frame
    if (hasEOP)  doorBell <= True; // To abstract the 0-nm message containing the flow control doorbell write 
    frmAckOK <= hasEOP;  // Blindly take ACK on EOP, assume 1
    if (hasPull && igPtr>1) inProcF.enq(x);  // If receive message, drop frame header; but pass message and data to inProc
  endrule

  // hasPull Receive...

  // This rule will first fire with the 
  rule rcv_message;
    let x <- toGet(inProcF).get;
  endrule



  //
  // Access of TLPBRAM by EDP Control Plane - may be nice feature to have
  //

  Bit#(32) tlpDebug = {4'h0, pack(complTimerCount), 12'h0, pack(lastRuleFired)};

  interface Server server;
    interface request  = toPut(inF);   // Ethernet packets ingress from fabric to EDP
    interface response = toGet(outF);  // Ethernet packets  egress from EDP to fabric
  endinterface

  // remote-facing buffer queue interface...
  interface BufQCIfc bufq;
    method Bool   start   = remStart;
    method Bool   done    = remDone;
    method Bool   fabric  = False;
    method Action rdy     = nearBufReady._write(True);
    method Action frdy    = farBufReady._write(True);
    method Action credit  = creditReady._write(True);
    method Action bufMeta   (Bit#(16) bMeta);   remMetaAddr<=bMeta;     endmethod
    method Action bufMesg   (Bit#(16) bMesg);   remMesgAddr<=bMesg;     endmethod
    method Action fabMeta   (Bit#(32) fMeta);   fabMetaAddr<=fMeta;     endmethod
    method Action fabMesg   (Bit#(32) fMesg);   fabMesgAddr<=fMesg;     endmethod
    method Action fabFlow   (Bit#(32) fFlow);   fabFlowAddr<=fFlow;     endmethod
    method Action fabMetaMS (Bit#(32) fMetaMS); fabMetaAddrMS<=fMetaMS; endmethod
    method Action fabMesgMS (Bit#(32) fMesgMS); fabMesgAddrMS<=fMesgMS; endmethod
    method Action fabFlowMS (Bit#(32) fFlowMS); fabFlowAddrMS<=fFlowMS; endmethod
  endinterface

  // expose register interface so WCI can set/get these config properties...
  method Action dpCtrl (DPControl dc) = dpControl._write(dc);
  method Bit#(32)            i_flowDiagCount = flowDiagCount;
  method Bit#(32)            i_dbgBytesTxEnq = dbgBytesTxEnq;
  method Bit#(32)            i_dbgBytesTxDeq = dbgBytesTxDeq;
  method Bit#(32)            i_debug = tlpDebug;
  method Vector#(4,Bit#(32)) i_meta  = readVReg(lastMetaV);
  method Action now (Bit#(64) arg) = nowW._write(arg);
  method Bool  dmaStartPulse = dmaStartMark;
  method Bool  dmaDonePulse  = dmaDoneMark;
  method Bool  doorBellPulse = doorBell;
endmodule


// 4:1 DWORD funnel...

interface QDW2DWIfc;
  interface Put#(Vector#(4,Bit#(32))) putVector;
  interface Get#(Bit#(32))            getSerial;
  method Bool isEmpty;
endinterface

module mkQDW2DW (QDW2DWIfc);  // make a serial ABS stream from a QABS vector...
  FIFOF#(Vector#(4,Bit#(32))) inF   <-  mkFIFOF;
  FIFOF#(Bit#(32))            outF  <-  mkFIFOF;
  Reg#(UInt#(2))              ptr   <-  mkReg(0);

  rule funnel; 
    let qb = inF.first;  
    ptr <= ptr+1; 
    outF.enq(qb[ptr]);
    if (ptr==3) inF.deq;
  endrule

  interface Put putVector = toPut(inF);
  interface Get getSerial = toGet(outF);
  method Bool isEmpty = (!inF.notEmpty && !outF.notEmpty);
endmodule



