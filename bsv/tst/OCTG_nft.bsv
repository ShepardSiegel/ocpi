// OCTG_dmaFC.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCTG_nft;

import TLPMF::*;
import TLPServBC::*;

import PCIE::*;
import FIFO::*;
import LFSR::*;
import Vector::*;
import GetPut::*;
import StmtFSM::*;
import ClientServer::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import RegFile::*;

typedef enum {
   INIT0,
   INIT1
   } InitState deriving (Bits, Eq);

typedef enum {
   GEN_FLAG,
   GEN_DATA,
   GEN_META,
   UPDATE_FLAG,
   UPDATE_PTR,
   DOORBELL,
   DISABLED
   } WriteState deriving (Bits, Eq);

typedef enum {
   CHK_FLAG,
   CHK_DATA,
   CHK_META,
   UPDATE_FLAG,
   UPDATE_PTR,
   DOORBELL,
   DISABLED
   } ReadState deriving (Bits, Eq);

typedef enum {
   READY,
   READ_HEADER,
   READ_BODY,
   WRITE_HEADER,
   WRITE_BODY,
   DISABLED
   } MemState deriving (Bits, Eq);


typedef struct {
  ReadRole    role;
  PciId       reqID;
  Bit#(32)    dwAddr;
  Bit#(10)    dwLength;
  Bit#(4)     firstBE;
  Bit#(4)     lastBE;
  Bit#(8)     tag;
  Bit#(3)     tc;
} ReadReq deriving (Bits);


typedef struct {
  Bit#(32)    dwAddr;
  Bit#(10)    dwLength;
  Bit#(4)     firstBE;
  Bit#(4)     lastBE;
  DWord       data;
} WriteReq deriving (Bits);


typedef union tagged {
  WriteReq    WriteHeader;
  Bit#(128)   WriteData;
  ReadReq     ReadHeader;
} MemReqPacket deriving (Bits);

(* synthesize *)
module mkOCTG_nft (OCTGIfc);

  FIFO#(PTW16)    outF     <- mkFIFO;       // Outbound TLPs, typically requests
  FIFO#(PTW16)    inF      <- mkFIFO;       // Inbound  TLPs, typically completions
  FIFO#(PTW16)    outF2    <- mkFIFO;       // Outbound TLPs, typically requests
  FIFO#(PTW16)    inF2     <- mkFIFO;       // Inbound  TLPs, typically completions
  Reg#(Bool)      started  <- mkReg(False); // True once running
  Reg#(Bit#(8))   tag      <- mkReg(0);     // Requester Tag Source
  Reg#(DWord)     dwValue  <- mkRegU;       // Register to hold read response
  Reg#(Bool)      dpGo     <- mkReg(False); // dataplane test rules
  Reg#(Bool)      genGo    <- mkReg(False); 
  Reg#(Bool)      chkGo    <- mkReg(False); 
  Reg#(Bool)      initGo   <- mkReg(False); 
  Reg#(Bool)   tlpOutMutex <- mkReg(False); // Guard multi-cycle outbound TLPs from being split 
  Reg#(Bool)   tlpInMutex  <- mkReg(False); // Guard multi-cycle inbound  TLPs from being split

  Reg#(Maybe#(PTW16)) mReg <- mkReg(Invalid); // for multi-cycle outbounds, eg N-DW write requests
   
   // 64KB of memory space
   Vector#(4, RegFile#(Bit#(16), Bit#(32))) mem <- replicateM(mkRegFileFull);
   


  PTW16 nullPTW = unpack('0);

  // The multi-cycle read request/response sub-seqeuence...
  function RStmt#(DWord) rdSeq0 (Bit#(0) b, Bit#(32) bAddr);
  Bit#(30) dwAddr = truncate(bAddr>>2); 
  Bit#(7) bar = 7'h01; //control plane
  seq
    action
      $display("[%0d]: %m: BAR0 READ SEND tag:%0x Addr:%0x", $time, tag, bAddr);
      outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
      tag <= tag + 1;                              // Bump the transaction tag
    endaction
    actionvalue
      let p = inF.first;                 // wait for the read data to return
      inF.deq;
      let d  = byteSwap(p.data[31:0]);   // perform read DWORD byteSwap
      $display("[%0d]: %m: BAR0 READ-RETURNED tag:%0x Addr:%0x Data:%0x", $time, tag, bAddr, d);
      return d;
    endactionvalue
  endseq;
  endfunction
  FSMServer#(Bit#(32), DWord) rdServer0 <- mkFSMServer(rdSeq0(0));

  // The multi-cycle read request/response sub-seqeuence...
  function RStmt#(DWord) rdSeq1 (Bit#(0) b, Bit#(32) bAddr);
  Bit#(30) dwAddr = truncate(bAddr>>2); 
  Bit#(7) bar = 7'h02; //data plane
  seq
    when (!isValid(mReg),
      (action
        outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
        tag <= tag + 1;                              // Bump the transaction tag
      endaction));
    actionvalue
      let p = inF.first;                 // wait for the read data to return
      inF.deq;
      let d  = byteSwap(p.data[31:0]);   // perform read DWORD byteSwap
      $display("[%0d]: %m: BAR1 READ-RETURNED tag:%0x Addr:%0x Data:%0x", $time, tag, bAddr, d);
      return d;
    endactionvalue
  endseq;
  endfunction
  FSMServer#(Bit#(32), DWord) rdServer1 <- mkFSMServer(rdSeq1(0));

  function Action fsmWrite(Bit#(7) bar, Bit#(32) bAddr, DWord wd);
    return when (!isValid(mReg),
      (action 
        outF.enq(makeWtNDwReqTLP(bar, truncate(bAddr>>2), wd, 1));
        $display("[%0d]: %m: 1DW WRITE-INITIATED  Addr:%0x Data:%0x", $time, bAddr, wd);
      endaction));
  endfunction 

  // TODO: Implement general N-Dword Writer
  function Action fsmWrite2(Bit#(7) bar, Bit#(32) bAddr, DWord wd0, DWord wd1);
    return when (!isValid(mReg),
      (action
        outF.enq(makeWtNDwReqTLP(bar, truncate(bAddr>>2), wd0, 2));
        PTW16 p = PTW16 {
          data : {byteSwap(wd1), ?},
          be   : 16'hF000,
          hit  : bar,
          sof  : False,
          eof  : True };
        mReg <= Valid(p);
        $display("[%0d]: %m: 2DW WRITE-INITIATED  Addr:%0x Data:%0x,%0x", $time, bAddr, wd0,wd1);
      endaction));
  endfunction 

  function Action fsmReadReq(Bit#(7) bar, Bit#(32) bAddr);
    return when (!isValid(mReg),
      (action
        Bit#(30) dwAddr = truncate(bAddr>>2); 
        outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
        tag <= tag + 1;                              // Bump the transaction tag
        $display("[%0d]: %m: READ-INITIATED  Addr:%0x Tag:%0x", $time, bAddr, tag);
      endaction));
  endfunction 

rule pushMulti (mReg matches tagged Valid .p);
  mReg <= Invalid;
  outF.enq(p);
endrule

   
   Bit#(32) bufSize = 64;
   Bit#(32) metaSize = 16;
   Bit#(32) flagSize = 4;
   Bit#(32) genNumLclBufs = 2;
   Bit#(32) genNumRemBufs = 8;
   Bit#(32) genLclMesgBase = 0;
   Bit#(32) genLclMetaBase = genLclMesgBase + genNumLclBufs*bufSize;
   
   Bit#(32) genRemMesgBase  = 32'h01_0000; // 32'h5f700000; 
   Bit#(32) genRemMetaBase  = genRemMesgBase + genNumRemBufs*bufSize;
   Bit#(32) genRemFlagBase  = genRemMetaBase + genNumRemBufs*metaSize; 
   Bit#(32) genRemPageBase  = genRemFlagBase + genNumRemBufs*flagSize;
   Bit#(32) genDbellAddr = 32'hE0_0018;   // config prop
   
   
   Bit#(32) chkNumLclBufs = 2;
   Bit#(32) chkNumRemBufs = 8;
   Bit#(32) chkLclMesgBase = 0;
   Bit#(32) chkLclMetaBase = chkLclMesgBase + chkNumLclBufs*bufSize;
   
   Bit#(32) chkRemMesgBase  = genRemPageBase + 4*4096;
   Bit#(32) chkRemMetaBase  = chkRemMesgBase + chkNumRemBufs*bufSize;
   Bit#(32) chkRemFlagBase  = chkRemMetaBase + chkNumRemBufs*metaSize; 
   Bit#(32) chkRemPageBase  = chkRemFlagBase + chkNumRemBufs*flagSize;
   Bit#(32) chkDbellAddr = 32'hF0_0018;   // config prop
   
   Bit#(7)  ctrlPlaneBar = 7'h01;
   Bit#(7)  dataPlaneBar = 7'h02;
   
  Stmt req = 
  seq
  
    $display("[%0d]: %m: Reading Worker Bit Mask...", $time);
      dwValue <- callServer(rdServer0, extend(24'h00_0010));

    $display("[%0d]: %m: Taking Workers out of Reset...", $time);
      fsmWrite('h01, 'h03_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h04_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h05_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h0D_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h0E_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h0F_FFE4, 'h8000_0004);

    $display("[%0d]: %m: Initialize Workers...", $time);
      dwValue <- callServer(rdServer0, extend(20'h03_0000));
      dwValue <- callServer(rdServer0, extend(20'h04_0000));
      dwValue <- callServer(rdServer0, extend(20'h05_0000));
      dwValue <- callServer(rdServer0, extend(20'h0D_0000)); //dram
      dwValue <- callServer(rdServer0, extend(20'h0E_0000));
      dwValue <- callServer(rdServer0, extend(20'h0F_0000));


    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
      // Try out 64b writes where we can...
      fsmWrite2('h01, 'h10_0000, 32'hFAAA_AAAA, 32'hFBBB_BBBB); 



     fsmWrite('h01, 'hE0_0068, 32'h0000_0009);  //control FCactMesg
     fsmWrite('h01, 'hF0_0068, 32'h0000_0005);  //control FPactMesg
     
     
     // DP0 controls
     fsmWrite('h01, 'hE0_0000, genNumLclBufs); // local buffers = 2
     fsmWrite('h01, 'hE0_0004, genNumRemBufs); // fab buffers = 8
     fsmWrite('h01, 'hE0_0008, genLclMesgBase); // local message base = 0x0
     fsmWrite('h01, 'hE0_000C, genLclMetaBase); // local meta base = 0x1000 (4096)
     fsmWrite('h01, 'hE0_0010, bufSize); // local message size = 0x800 (2048)
     fsmWrite('h01, 'hE0_0014, metaSize); // local meta size = 0x10 (16)
        
     fsmWrite('h01, 'hE0_0040, genRemPageBase);  // fab pinned page base
     fsmWrite('h01, 'hE0_0050, genRemMesgBase);  // fab mesg base
     fsmWrite('h01, 'hE0_0054, genRemMetaBase);  // fab meta base = 8*2048 = 0x4000
     fsmWrite('h01, 'hE0_0058, bufSize);  // fab mesg size (2048B)
     fsmWrite('h01, 'hE0_005C, metaSize);  // fab meta size (16B)
     fsmWrite('h01, 'hE0_0060, genRemFlagBase);  // fab flag base 
     fsmWrite('h01, 'hE0_0064, flagSize);  // flag size (32-bits)
     
     // DP1 controls
     fsmWrite('h01, 'hF0_0000, chkNumLclBufs); // local buffers = 2
     fsmWrite('h01, 'hF0_0004, chkNumRemBufs); // fab buffers = 8
     fsmWrite('h01, 'hF0_0008, chkLclMesgBase); // local message base = 0x0
     fsmWrite('h01, 'hF0_000C, chkLclMetaBase); // local meta base = 0x1000 (4096)
     fsmWrite('h01, 'hF0_0010, bufSize); // local message size = 0x800 (2048)
     fsmWrite('h01, 'hF0_0014, metaSize); // local meta size = 0x10 (16)
        
     fsmWrite('h01, 'hF0_0040, chkRemPageBase);  // fab pinned page base
     fsmWrite('h01, 'hF0_0050, chkRemMesgBase);  // fab mesg base
     fsmWrite('h01, 'hF0_0054, chkRemMetaBase);  // fab meta base = 8*2048 = 0x4000
     fsmWrite('h01, 'hF0_0058, bufSize);  // fab mesg size (2048B)
     fsmWrite('h01, 'hF0_005C, metaSize);  // fab meta size (16B)
     fsmWrite('h01, 'hF0_0060, chkRemFlagBase);  // fab flag base 
     fsmWrite('h01, 'hF0_0064, flagSize);  // flag size (32-bits)
     
      $display("[%0d]: %m: Start Workers...", $time);
      dwValue <- callServer(rdServer0, extend(24'h03_0004));
      dwValue <- callServer(rdServer0, extend(24'h04_0004));
      dwValue <- callServer(rdServer0, extend(24'h05_0004));
      dwValue <- callServer(rdServer0, extend(24'h0D_0004)); // dram
      dwValue <- callServer(rdServer0, extend(24'h0E_0004));
      dwValue <- callServer(rdServer0, extend(24'h0F_0004));
     
     //fsmWrite('h01, 'h40_0004, (32 << 12 | 4)); // Update flag
     //fsmWrite('h01, 'h40_0008, -1); // Update flag
     initGo <= True;

     dwValue <= 200;
     while(dwValue!=0) dwValue <= dwValue-1;


  endseq;
  FSM reqFsm <- mkFSM(req);

  //rule startup (False && !started);
  rule startup (True && !started);
    reqFsm.start;
    started <= True;
  endrule


//gen...
   
  FIFOF#(MemReqPacket)     mReqF                <- mkFIFOF;
  FIFOF#(MemRespPacket)    mRespF               <- mkFIFOF;
   
  Reg#(Bit#(32))          genMesgAddr    <- mkReg(extend(genRemMesgBase));
  Reg#(Bit#(32))          genMetaAddr    <- mkReg(extend(genRemMetaBase));
  Reg#(Bit#(32))          genFlagAddr    <- mkReg(extend(genRemFlagBase)); 
   
  Reg#(Bit#(32))          chkMesgAddr    <- mkReg(extend(chkRemMesgBase));
  Reg#(Bit#(32))          chkMetaAddr    <- mkReg(extend(chkRemMetaBase));
  Reg#(Bit#(32))          chkFlagAddr    <- mkReg(extend(chkRemFlagBase)); 
   
  Reg#(Bit#(8))           readPtr        <- mkReg(0);
  Reg#(Bit#(8))           writePtr       <- mkReg(0);
   
  Reg#(Bit#(16))          genDebugPbe    <- mkReg(0);
  Reg#(Bit#(128))         genDebugPdata  <- mkReg(0);
  
  Reg#(WriteState)        writeState     <- mkReg(GEN_FLAG);
  Reg#(ReadState)         readState      <- mkReg(CHK_FLAG);
  Reg#(MemState)          memState       <- mkReg(READY);
  Reg#(InitState)         initState      <- mkReg(INIT0); 
   Reg#(Bit#(32))          counter        <- mkReg(0);
   Reg#(Bit#(32))          genCounter     <- mkReg(0);
  Reg#(Bit#(32))          chkCounter     <- mkReg(0);
  Reg#(Bit#(32))          writeVal       <- mkReg(0);
  Reg#(Bit#(10))          outDwRemain    <- mkRegU;
  Reg#(Bit#(128))         lastBuf        <- mkRegU;
  Reg#(Bit#(32))          curAddr <- mkRegU; 
  Reg#(Bit#(32))          writeDWAddr    <- mkRegU;
   Reg#(Bit#(32))          writeRemainDWLen <- mkRegU;
   Reg#(Bit#(32))          chkDataLength <- mkRegU;
   Reg#(Bit#(32))          genVal        <- mkReg(0);
   Reg#(Bit#(32))          chkVal        <- mkReg(0);
   
   //------------------------------------------ INIT FSM -------------------------------------------------
   
   // Clear main memory
   rule init0(initGo && initState == INIT0);
      Bit#(32) dwAddr = genMesgAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), 32'b0);
      //$display("Init: Phase 1 initializing, on val %0x", genMesgAddr);
      // Clear 2^16 = 64KB
      if(genMesgAddr == 32'h0004_0000 - 4) begin
	 genMesgAddr <= genRemMesgBase;
	 counter <= 0;
	 initState <= INIT1;
      end
      else begin
	 genMesgAddr <= genMesgAddr + 4;
      end
   endrule
   
   // Set write flags to 1
   rule init1(initGo && initState == INIT1);
      Bit#(32) dwAddr = genFlagAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), 32'b1);
      
      $display("Init: Phase 2 initializing, on val %0x", counter);
      
      if(counter == genNumRemBufs - 1) begin
	 counter <= 0;
	 genFlagAddr <= genRemFlagBase;
	 dpGo <= True;
	 genGo <= True;
	 chkGo <= True;
	 initGo <= False;
      end
      else begin
	 counter <= counter + 1;
	 genFlagAddr <= genFlagAddr + 4;
      end
      
   endrule
 
   //------------------------------------------ GEN (WRITE) FSM -------------------------------------------------
      
   // Check flag != 0
   rule genFlag(dpGo && genGo && writeState == GEN_FLAG);
      Bit#(32) dwAddr = genFlagAddr >> 2;
      Bit#(32) flag = mem[dwAddr[1:0]].sub(truncate(dwAddr >> 2));
      if(flag != 0) begin
	 $display("[%0d] Gen: Flag check at addr %0x, val  = %0d", $time, genFlagAddr, flag);
	 writeState <= GEN_DATA;
      end
   endrule
   
   rule genData(dpGo && genGo && writeState == GEN_DATA);
      Bit#(32) dwAddr = genMesgAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), genVal);
      $display("[%0d] Gen: Writing data to addr %0x, data = %0d", $time, genMesgAddr, genVal);
      genMesgAddr <= genMesgAddr + 4;
      genVal <= genVal + 1;
      
      if(genCounter == (64 >> 2) - 1) begin //extend(bufSize >> 2) - 1) begin
	 writeState <= GEN_META;
	 genCounter <= 0;
	 
	 fsmWrite('h01, 'h40_0004, (32 << 12 | 16)); // Update flag
      end
      else begin
	 genCounter <= genCounter + 1;
      end
   endrule
   
   // Populate metadata
   rule genMeta(dpGo && genGo && writeState == GEN_META);
      Bit#(32) dwAddr = genMetaAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), 64);
      $display("[%0d] Gen: Writing meta to addr %0x, dwAddr %0x, idx=%0x, bank=%0x, data = %0d", $time, genMetaAddr, dwAddr, dwAddr >> 2, dwAddr[1:0], 64);
           
      genMetaAddr <= genMetaAddr + 4;
      
      if(genCounter == extend(metaSize >> 2) - 1) begin
	 writeState <= UPDATE_FLAG;
	 genCounter <= 0;
      end
      else begin
	 genCounter <= genCounter + 1;
      end
   endrule
   
   // Update flag
   rule genUpdateFlag(dpGo && genGo && writeState == UPDATE_FLAG);
      Bit#(32) dwAddr = genFlagAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), 0);
      $display("[%0d] Gen: Flag clear at addr %0x, val  = %0d", $time, genFlagAddr, 0);
      writeState <= UPDATE_PTR;
   endrule
   
   rule genPtrUpdate(writeState == UPDATE_PTR);
      if(writePtr == truncate(genNumRemBufs - 1)) begin
	 writePtr <= 0;
	 genFlagAddr <= extend(genRemFlagBase);
	 genMetaAddr <= extend(genRemMetaBase);
	 genMesgAddr <= extend(genRemMesgBase);
	 $display("Gen: Wraparound!\n");
      end
      else begin
	 writePtr <= writePtr + 1;
	 genFlagAddr <= genRemFlagBase + flagSize*(extend(writePtr + 1));
	 genMetaAddr <= genRemMetaBase + metaSize*(extend(writePtr + 1));
	 genMesgAddr <= genRemMesgBase + bufSize*(extend(writePtr + 1));
      end
      writeState <= DOORBELL;
   endrule
   
   
   // Currently no data being written (no flag, no data, no meta)
   rule genDoorbell(dpGo && genGo && writeState == DOORBELL);
      Bit#(7)  bar   = ctrlPlaneBar;
      Bit#(32) bAddr = extend(genDbellAddr);
      Bit#(32) wd    = 32'h0000_0001;
      outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
      
      $display("[%0d] Gen: Writing doorbell to addr %0x", $time, bAddr);
      writeState <= GEN_FLAG;
   endrule
   
   //------------------------------------------ MAIN MEMORY FSM -------------------------------------------------
   
   // Wait for DP0 to read my data
   rule genWaitForReadReq(dpGo);
      PTW16 pw = inF2.first;
      inF2.deq;
      Ptw16Hdr p = unpack(pw.data);
      DWAddress  dwAddr    = pw.data[63:34];          // Pick off dwAddr from 1st TLP
      $display("DWAddr: %h, addr: %h, pw.sof: %h", dwAddr, {dwAddr, 2'b0}, pw.sof);
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
	 //DWAddress  dwAddr    = pw.data[63:34];          // Pick off dwAddr from 1st TLP
	 DWord      firstDW   = truncate(pw.data);       // Bottom DW of 1st TLP is data
	 //Bool ignorePkt = p.hdr.isPoisoned || p.hdr.is4DW || p.hdr.pktType != 5'b00000;
	 Bool ignorePkt = p.hdr.isPoisoned || p.hdr.pktType != 5'b00000;
	 if (!ignorePkt) begin
	    if (isWrite) begin
               WriteReq wreq = WriteReq {
		  dwAddr   : extend(dwAddr),
		  dwLength : len,
		  data     : firstDW,  // DW still in PCI/NBO, Byte0 on 31:24
		  firstBE  : firstBE,
		  lastBE   : lastBE };
               MemReqPacket mpkt = WriteHeader(wreq);
	       mReqF.enq(mpkt);
               if (pw.eof) begin
		  $display("[%0d] TMem: WTF single-cycle write (addr %0x), writing %0d", $time, {dwAddr,2'b00}, byteSwap(firstDW));
	       end
	       else begin
		  $display("[%0d] TMem: Multi-cycle write, addr %0x, data %0x, nontrunc %0x", $time, {dwAddr,2'b00}, byteSwap(firstDW), pw.data);
	       end
	    end
            else begin
               ReadReq rreq = ReadReq {
		  role     : ComplTgt,
		  reqID    : srcReqID,
		  dwLength : len,
		  tag      : tag,
		  tc       : tc,
		  dwAddr   : extend(dwAddr),
		  firstBE  : firstBE,
		  lastBE   : lastBE };
               MemReqPacket mpkt = ReadHeader(rreq);
               mReqF.enq(mpkt);
               $display("[%0d] TMem: ReadHeader (addr %0x, dwAddr %0x, len %0d, BE %x %x)", $time, {dwAddr,2'b00}, dwAddr, len, firstBE, lastBE);
	    end
	 end
      end
      else begin
         MemReqPacket pkt = WriteData(pw.data); //16B Data still in PCI/NBO format
         mReqF.enq(pkt);
         if (pw.eof) $display("[%0d] TMem: Finished multi-cycle write (addr %x)", $time, {dwAddr,2'b00});
	 $display("[0%d] TMem: Multi-cycle write", $time);
      end
   endrule

   
   // Generate response header
   rule genXmtHeader (memState == READY &&& mReqF.first matches tagged ReadHeader .rreq);
      mReqF.deq;
      Bit#(2) lowAddr10 = byteEnToLowAddr(rreq.firstBE);
      Bit#(7) lowAddr = {truncate(rreq.dwAddr), lowAddr10};
      Bit#(12) byteCount = computeByteCount(rreq.dwLength, rreq.firstBE, rreq.lastBE);
      CompletionHdr hdr =
      makeReadCompletionHdr(PciId {bus:255, dev:0, func:0}, rreq.reqID, rreq.dwLength, rreq.tag, rreq.tc, lowAddr, byteCount);
     
      // Generate packet
      Bit#(32) data = mem[rreq.dwAddr[1:0]].sub(truncate(rreq.dwAddr >> 2));
      $display("Reading from addr %0x, idx %0x, bank %0x", rreq.dwAddr, rreq.dwAddr >> 2, rreq.dwAddr[1:0]);
      Bit#(128) pkt = { pack(hdr), byteSwap(data) };
      PTW16 w = TLPData {
	 data : pkt,
	 be   : '1,
	 hit  : 7'h2,
	 sof  : True,
	 eof  : (rreq.dwLength == 1)};
      outF2.enq(w);
      outDwRemain <= rreq.dwLength - 1;
      curAddr <= extend(rreq.dwAddr) + 1;
      
	 $display("[%0d] TMem: Transmitting data header addr %0h, size %0d bytes, data = %0d", $time, {rreq.dwAddr, lowAddr10}, byteCount, data);
      
      if(rreq.dwLength > 1)
	 memState <= READ_BODY;
   endrule
   
   // Generate response body
   rule genXmtBody (memState == READ_BODY);
      Bool isLastTLP = (outDwRemain <= 4);
      
      Bit#(32) curAddr0, curAddr1, curAddr2, curAddr3;
      curAddr0 = curAddr + 0;
      curAddr1 = curAddr + 1;
      curAddr2 = curAddr + 2;
      curAddr3 = curAddr + 3;
      
      Bit#(32) data1, data2, data3, data4;
      
      // Hardcoded because Bluespec is stupid
      data1 = mem[1].sub(truncate(curAddr0 >> 2));
      data2 = mem[2].sub(truncate(curAddr1 >> 2));
      data3 = mem[3].sub(truncate(curAddr2 >> 2));
      data4 = mem[0].sub(truncate(curAddr3 >> 2));
      
      PTW16 w = TLPData {
	 data : {byteSwap(data1), byteSwap(data2), byteSwap(data3), byteSwap(data4)},
	 be   : (isLastTLP ? remFromDW(outDwRemain[1:0]) : '1),
	 hit  : 7'h2,
	 sof  : False,
         eof  : isLastTLP };
      outF2.enq(w);
      outDwRemain <= outDwRemain - 4;
      
      counter <= counter + 1;
      curAddr <= curAddr + 4;
      $display("[%0d] TMem: Transmitting data body, writing %0d, %0d, %0d, %0d", $time, data1, data2, data3, data4);
      if (isLastTLP)
	 memState <= READY;
   endrule
   
   
   rule writeReq (memState == READY &&& mReqF.first matches tagged WriteHeader .wreq);
      mReqF.deq;
      writeDWAddr       <= wreq.dwAddr   + 1;
      writeRemainDWLen  <= extend(wreq.dwLength - 1);
      
      mem[wreq.dwAddr[1:0]].upd(truncate(wreq.dwAddr >> 2), byteSwap(wreq.data));
      $display("[%0d] TMem: Writing first word (addr %x, idx %0x, bank %0x) data %x", $time, {wreq.dwAddr,2'b00}, wreq.dwAddr >> 2, wreq.dwAddr[1:0], byteSwap(wreq.data));
   endrule
   
   // Perform any subsequent memory writes...
   rule writeData (memState == READY &&& mReqF.first matches tagged WriteData .wrdata);
      //Tuple4#(Bit#(32), Bit#(32), Bit#(32), Bit#(32)) test = unpack(wrdata);
      Vector#(4, DWord)       vWords   = reverse(unpack(wrdata)); // sadly this is equivalent to the tuple (reverse is needed)
      mReqF.deq;
      
      //$display("TMem: TESTING tpl_1=%0x, tpl_2=%0x, tpl_3=%0x, tpl_4=%0x", tpl_1(test), tpl_2(test), tpl_3(test), tpl_4(test));
      for (Integer i=0; i<4; i=i+1) begin
	 Bit#(32) dwAddr = writeDWAddr + fromInteger(i);
	 if(writeRemainDWLen > fromInteger(i)) begin
	    mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), byteSwap(vWords[i]));
	    $display("[%0d] TMem: Writing next words, dwAddr=%0x, idx=%0x, bank=%0x, data=%0x", $time, dwAddr, dwAddr>>2, dwAddr[1:0], vWords[i]);
	 end
      end
      
      writeDWAddr       <= writeDWAddr      + 4;
      writeRemainDWLen  <= writeRemainDWLen - 4;
   endrule
   
   
   //------------------------------------------ CHK (READ) FSM -------------------------------------------------
   

   // Check flag != 0
   rule chkWaitFlag(dpGo && chkGo && readState == CHK_FLAG);
      Bit#(32) dwAddr = chkFlagAddr >> 2;
      Bit#(32) flag = mem[dwAddr[1:0]].sub(truncate(dwAddr >> 2));
      if(flag != 0) begin
	 $display("[%0d] Chk: Flag check at addr %0x, val  = %0d", $time, chkFlagAddr, flag);
	 readState <= CHK_META;
      end
   endrule
   
   // Read metadata (length)
   rule chkMeta(dpGo && chkGo && readState == CHK_META);
      Bit#(32) dwAddr = chkMetaAddr >> 2;
      Bit#(32) length = mem[dwAddr[1:0]].sub(truncate(dwAddr >> 2));
      $display("[%0d] Chk: Meta read @ addr %0x, length = %0d", $time, chkMetaAddr, length);
      
      chkMetaAddr <= chkMetaAddr + 16;
      
      if(length == 0) begin
	 $display("WTF LENGTH IS 0");
	 $finish;
      end
      
      // Length is in bytes, convert to DW
      chkDataLength <= length >> 2;
      chkCounter <= 0;
      
      readState <= CHK_DATA;
   endrule
   
   
   rule chkData(dpGo && chkGo && readState == CHK_DATA);
      Bit#(32) dwAddr = chkMesgAddr >> 2;
      Bit#(32) data = mem[dwAddr[1:0]].sub(truncate(dwAddr >> 2));
      
      $display("[%0d] Chk: Reading data @ addr %0x, data = %0d", $time, chkMesgAddr, data);
      
      if(data != chkVal) begin
	 $display("\n\n\n\n ERROR: %0d != %0d", data, chkVal);
	 $finish;
      end
      
      chkVal <= chkVal + 1;
      chkMesgAddr <= chkMesgAddr + 4;
      
      if(chkCounter == chkDataLength - 1) begin
	 readState <= UPDATE_FLAG;
	 chkCounter <= 0;
      end
      else begin
	 chkCounter <= chkCounter + 1;
      end
   endrule
   
   // Mark flag as cleared
   rule chkUpdateFlag(dpGo && chkGo && readState == UPDATE_FLAG);
      Bit#(32) dwAddr = chkFlagAddr >> 2;
      mem[dwAddr[1:0]].upd(truncate(dwAddr >> 2), 0);
      $display("[%0d] Chk: Flag clear at addr %0x, val  = %0d", $time, chkFlagAddr, 0);
      readState <= UPDATE_PTR;
   endrule
      
   
   rule chkPtrUpdate(readState == UPDATE_PTR);
      if(readPtr == truncate(chkNumRemBufs - 1)) begin
	 readPtr <= 0;
	 chkFlagAddr <= extend(chkRemFlagBase);
	 chkMetaAddr <= extend(chkRemMetaBase);
	 chkMesgAddr <= extend(chkRemMesgBase);
	 $display("Chk: Wraparound!\n");
      end
      else begin
	 readPtr <= readPtr + 1;
	 chkFlagAddr <= chkRemFlagBase + flagSize*(extend(readPtr + 1));
	 chkMetaAddr <= chkRemMetaBase + metaSize*(extend(readPtr + 1));
	 chkMesgAddr <= chkRemMesgBase + bufSize*(extend(readPtr + 1));
      end
      readState <= DOORBELL;
   endrule
   
   
   // Currently no data being written (no flag, no data, no meta)
   rule chkDoorbell(dpGo && chkGo && readState == DOORBELL);
      Bit#(7)  bar   = ctrlPlaneBar;
      Bit#(32) bAddr = extend(chkDbellAddr);
      Bit#(32) wd    = 32'h0000_0001;
      outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
      
      $display("[%0d] Chk: Writing doorbell to addr %0x", $time, bAddr);
      readState <= CHK_FLAG;
   endrule



  interface Client client;
    interface request  = toGet(outF);
    interface response = toPut(inF); 
  endinterface
  interface Client client2;
    interface request  = toGet(outF2);
    interface response = toPut(inF2); 
  endinterface

endmodule: mkOCTG_nft

endpackage: OCTG_nft

