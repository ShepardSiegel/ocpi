// OCTG_dmaFP.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCTG_dmaFP;

import TLPMF::*;

import PCIE::*;
import FIFO::*;
import LFSR::*;
import Vector::*;
import GetPut::*;
import StmtFSM::*;
import ClientServer::*;
import Connectable::*;

typedef Get#(Bit#(n)) RandI#(numeric type n);
module mkRand(RandI#(n)) provisos(Add#(foo, n, 32));
  Bit#(32) poly = 32'h5555_5555;
  LFSR#(Bit#(n))  lfsr     <- mkFeedLFSR(truncate(poly));
  FIFO#(Bit#(n))  fi       <- mkFIFO ;
  Reg#(Bool)      starting <- mkReg(True) ;
  rule start (starting); starting <= False; lfsr.seed('1); endrule
  rule run (!starting); fi.enq(lfsr.value); lfsr.next; endrule
  return fifoToGet(fi);
endmodule

(* synthesize *)
module mkOCTG_dmaFP (OCTGIfc);

  FIFO#(PTW16)    outF     <- mkFIFO;       // Outbound TLPs, typically requests
  FIFO#(PTW16)    inF      <- mkFIFO;       // Inbound  TLPs, typically completions
  Reg#(Bool)      started  <- mkReg(False); // True once running
  Reg#(Bit#(8))   tag      <- mkReg(0);     // Requester Tag Source
  Reg#(DWord)     dwValue  <- mkRegU;       // Register to hold read response
  Reg#(Bool)      dpGo     <- mkReg(False); // dataplane test rules
  Reg#(Bool)      genGo    <- mkReg(False); 
  Reg#(Bool)      chkGo    <- mkReg(False); 
  Reg#(Bool)   tlpOutMutex <- mkReg(False); // Guard multi-cycle outbound TLPs from being split 
  Reg#(Bool)   tlpInMutex  <- mkReg(False); // Guard multi-cycle inbound  TLPs from being split

  Reg#(Maybe#(PTW16)) mReg <- mkReg(Invalid); // for multi-cycle outbounds, eg N-DW write requests

  //Reg#(Bool)   blockChecker  <- mkReg(True);


  PTW16 nullPTW = unpack('0);

  // The multi-cycle read request/response sub-seqeuence...
  function RStmt#(DWord) rdSeq0 (Bit#(0) b, Bit#(32) bAddr);
  Bit#(30) dwAddr = truncate(bAddr>>2); 
  Bit#(7) bar = 7'h01; //control plane
  seq
    action
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

Bit#(8)  genchkNumBuf = 2;
Bit#(32) genchkInit   = 4;
Bit#(32) genchkDelta  = 4;
Bit#(8)  genchkRepeat = 0;
Bit#(8)  genLimit = 4;

  Stmt req = 
  seq
  
    $display("[%0d]: %m: Reading Worker Bit Mask...", $time);
      dwValue <- callServer(rdServer0, extend(24'h00_0010));

    $display("[%0d]: %m: Taking Workers out of Reset...", $time);
      fsmWrite('h01, 'h01_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h02_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h03_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h04_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h05_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h0E_FFE4, 'h8000_0004);
      fsmWrite('h01, 'h0F_FFE4, 'h8000_0004);

    $display("[%0d]: %m: Initialize Workers...", $time);
      dwValue <- callServer(rdServer0, extend(20'h01_0000));
      dwValue <- callServer(rdServer0, extend(20'h02_0000));
      dwValue <- callServer(rdServer0, extend(20'h03_0000));
      dwValue <- callServer(rdServer0, extend(20'h04_0000));
      dwValue <- callServer(rdServer0, extend(20'h05_0000));
      dwValue <- callServer(rdServer0, extend(20'h0E_0000));
      dwValue <- callServer(rdServer0, extend(20'h0F_0000));


    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    /*
      fsmWrite('h01, 'hE0_0000, extend(genchkNumBuf)); 
      fsmWrite('h01, 'hE0_0004, extend(genchkNumBuf)); 
      fsmWrite('h01, 'hF0_0000, extend(genchkNumBuf)); 
      fsmWrite('h01, 'hF0_0004, extend(genchkNumBuf)); 
    */
      // Try out 64b writes where we can...
      fsmWrite2('h01, 'h10_0000, 32'hFAAA_AAAA, 32'hFBBB_BBBB); 
      fsmWrite2('h01, 'hE0_0000, extend(genchkNumBuf), extend(genchkNumBuf)); 
      fsmWrite2('h01, 'hF0_0000, extend(genchkNumBuf), extend(genchkNumBuf)); 


      // dma stuff...
      fsmWrite('h01, 'hF0_0050, 32'h0000_0000);  //mesgbase
      fsmWrite('h01, 'hF0_0054, 32'h0000_3800);  //metabase
      fsmWrite('h01, 'hF0_0058, 32'h0000_0800);  //mesgsize
      fsmWrite('h01, 'hF0_005C, 32'h0000_0010);  //metasize
      fsmWrite('h01, 'hF0_0060, 32'h00E0_0018);  //ngressdone address
      fsmWrite('h01, 'hF0_0068, 32'h0000_0005);  //control FPactMesg
      fsmWrite('h01, 'hE0_0068, 32'h0000_0008);  //control FCpassive


      //fsmWrite('h01, 'h40_0000, 'h0001_0000);  // biasValue, add at b16

    $display("[%0d]: %m: Start Workers...", $time);
      dwValue <- callServer(rdServer0, extend(24'h01_0004));
      dwValue <- callServer(rdServer0, extend(24'h02_0004));
      dwValue <- callServer(rdServer0, extend(24'h03_0004));
      dwValue <- callServer(rdServer0, extend(24'h04_0004));
      dwValue <- callServer(rdServer0, extend(24'h05_0004));
      dwValue <- callServer(rdServer0, extend(24'h0E_0004));
      dwValue <- callServer(rdServer0, extend(24'h0F_0004));

     dpGo  <= True;
     genGo <= True;

     dwValue <= 200;
     while(dwValue!=0) dwValue <= dwValue-1;

     // Must re-purpose FC side from passive to doorbell...
     fsmWrite('h01, 'hE0_0064, 32'h00F0_001C);  //doorbell address
     fsmWrite('h01, 'hE0_0068, 32'h0000_000A);  //control FCactBell

    // chkGo <= True;

  endseq;
  FSM reqFsm <- mkFSM(req);

  //rule startup (False && !started);
  rule startup (True && !started);
    reqFsm.start;
    started <= True;
  endrule


//gen...

  Reg#(Maybe#(Bit#(32)))  genReady       <- mkReg(tagged Invalid);
  Reg#(Bool)              genReqInFlight <- mkReg(False);
  Reg#(Bit#(8))           genReqTag      <- mkRegU;
  Reg#(Bit#(32))          genVal         <- mkReg(0);
  Reg#(Bit#(32))          genUnroll      <- mkReg(0);
  Reg#(Bit#(8))           genNumBuf      <- mkReg(genchkNumBuf);
  Reg#(Bit#(8))           genRepeat      <- mkReg(genchkRepeat);
  Reg#(Bit#(8))           genCurBuf      <- mkReg(0);
  Reg#(Bool)              genMesgCont    <- mkReg(False);
  Reg#(Bool)              genDoMeta0     <- mkReg(False);
  Reg#(Bool)              genDoMeta1     <- mkReg(False);
  Reg#(Bit#(32))          genLen         <- mkReg(genchkInit);
  Reg#(Bool)              genDoDoor      <- mkReg(False);
  Reg#(Bit#(8))           genOpcode      <- mkReg(0);
  RandI#(8)               genRand        <- mkRand;
  Reg#(Bit#(8))           genCount       <- mkReg(0);
  Reg#(Bit#(8))           genBlkCount    <- mkReg(0);


  Bit#(24) genMesgBase  = 24'h00_0000;
  Bit#(24) genMesgPitch = 24'h00_0800; 
  Bit#(24) genMetaBase  = 24'h00_3800;
  Bit#(24) genDbellAddr = 24'hE0_0018;   // config prop
  Bit#(24) genReadyAddr = 24'hE0_0020;   // config prop
  Bit#(7)  ctrlPlaneBar = 7'h01;
  Bit#(7)  dataPlaneBar = 7'h02;

  Reg#(Bit#(32))          genMesgAddr    <- mkReg(extend(genMesgBase));
  Reg#(Bit#(32))          genMetaAddr    <- mkReg(extend(genMetaBase));

  Reg#(Bit#(16))          genDebugPbe    <- mkReg(0);
  Reg#(Bit#(128))         genDebugPdata  <- mkReg(0);

  rule genReqReady (dpGo && !isValid(genReady) && !genReqInFlight && genGo);
    genReqInFlight <= True;
    Bit#(32) bAddr = extend(genReadyAddr);
    Bit#(30) dwAddr = truncate(bAddr>>2); 
    Bit#(7) bar = ctrlPlaneBar;
    outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
    tag <= tag + 1;                              // Bump the transaction tag
    genReqTag <= tag;
  endrule

  function Bool tagMatch(Bit#(8) tagm, PTW16 t);
    CompletionHdr ch = unpack(t.data[127:32]);
    return(tagm==ch.tag);
  endfunction 

  rule genRespReady (dpGo && !isValid(genReady) && genReqInFlight && tagMatch(genReqTag,inF.first) && !tlpInMutex);
    let p = inF.first; 
    genReqInFlight <= False;
    inF.deq;
    let d  = byteSwap(p.data[31:0]);   // perform read DWORD byteSwap

    /*
    if (d==0) begin
      genBlkCount <= genBlkCount+1;
      if (genBlkCount==255) begin chkGo<=True; genGo<=False; end
    end
    */

    if (d != 0) genReady <= tagged Valid d;
    //blockChecker <= (d != 0); // block checker while we can still generate messages
    // startup...
    if (genLen==0)  genDoMeta0 <= True;   // skip making any data in genMesg
    else            genUnroll  <= genLen;
  endrule

  rule genMesg (dpGo && fromMaybe(0,genReady)>0 && genUnroll!=0 && !genMesgCont &&!genDoMeta0 && !genDoMeta1);
    Bit#(7)  bar = dataPlaneBar;
    Bit#(32) bAddr = genMesgAddr;
    Bit#(32) wd = genVal;
    //outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));

    PciId    rid    = PciId {bus:255, dev:0, func:0};
    Bit#(10) len    = truncate(genUnroll>>2);
    Bit#(30) dwAddr = truncate(bAddr>>2);
    MemReqHdr1 h = makeWrReqHdr(rid, len, '1, '0, False);
    let d = PTW16 {
      data : {pack(h), dwAddr,2'b0, byteSwap(wd)},
      be   : '1,
      hit  : bar,
      sof  : True,
      eof  : genUnroll==4 ? True : False };
    outF.enq(d);

    genUnroll   <= genUnroll - 4;
    genVal      <= genVal + 1;
    if (genUnroll==4) begin
      genDoMeta0  <= True;
    end else begin 
      genMesgCont <= True;
      tlpOutMutex <= True;
    end
    genCount <= genCount + 1;
  endrule
  
  rule genMesgContinue (dpGo && fromMaybe(0,genReady)>0 && genUnroll!=0 && genMesgCont && !genDoMeta0 && !genDoMeta1);
    Bit#(7)  bar  = dataPlaneBar;
    Bit#(32) wd0  = genVal;
    Bit#(32) wd1  = genVal+1;
    Bit#(32) wd2  = genVal+2;
    Bit#(32) wd3  = genVal+3;
    Bool lastBeat = (genUnroll<=16);
    Bit#(16) lRem = 0;
    if (lastBeat) begin
      case (truncate(genUnroll)&5'h1F) matches
        5'h04 : begin lRem = 16'hF000; genVal<=genVal+1; end
        5'h08 : begin lRem = 16'hFF00; genVal<=genVal+2; end
        5'h0C : begin lRem = 16'hFFF0; genVal<=genVal+3; end
        5'h10 : begin lRem = 16'hFFFF; genVal<=genVal+4; end
      endcase
    end else genVal <= genVal+4;

    let t = PTW16 {
      data : {byteSwap(wd0), byteSwap(wd1), byteSwap(wd2), byteSwap(wd3)},
      be   : lastBeat ? lRem :'1,
      hit  : bar,
      sof  : False,
      eof  : lastBeat ? True : False };
    outF.enq(t);

    genDebugPdata <= t.data;
    genDebugPbe   <= t.be  ;

    genUnroll <= lastBeat ? 0 : genUnroll-16;
    if (lastBeat) begin
      genDoMeta0  <= True;
      genMesgCont <= False;
      tlpOutMutex <= False;  // Release Outbound Mutex
    end 
  endrule

  rule genMeta0 (dpGo && fromMaybe(0,genReady)>0 && genDoMeta0);
    genDoMeta0 <= False;
    Bit#(7)  bar   = dataPlaneBar;
    Bit#(32) bAddr = genMetaAddr;
    Bit#(32) wd    = genLen;
    outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
    genMetaAddr <= genMetaAddr + 4;
    genDoMeta1  <= True;
  endrule

  rule genMeta1 (dpGo && fromMaybe(0,genReady)>0 && genDoMeta1);
    genDoMeta1 <= False;
    Bit#(7)  bar   = dataPlaneBar;
    Bit#(32) bAddr = genMetaAddr;
    Bit#(32) wd    = extend(genOpcode);
    outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
    genDoDoor  <= True;
  endrule

  rule genDoorbell (dpGo && fromMaybe(0,genReady)>0 && genDoDoor);
    genDoDoor <= False;
    Bit#(7)  bar   = ctrlPlaneBar;
    Bit#(32) bAddr = extend(genDbellAddr);
    Bit#(32) wd    = 32'h0000_0001;
    outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
    genOpcode <= genOpcode + 1;
    // buffer wrap...
    Bool tc = !(genCurBuf < genNumBuf-1);
    genCurBuf   <= tc ? 0                   : genCurBuf+1;
    genMesgAddr <= tc ? extend(genMesgBase) : genMesgAddr+extend(genMesgPitch);
    genMetaAddr <= tc ? extend(genMetaBase) : genMetaAddr+extend(8'h0C);
    genReady <= tagged Invalid;
    // next message
    if (genRepeat==0) begin
      genLen <= genLen + genchkDelta;
      genRepeat <= genchkRepeat;
    end else genRepeat <= genRepeat-1;
    if (genCount==genLimit) genGo <= False;
  endrule


//chk..

  Reg#(Maybe#(Bit#(32)))  chkReady       <- mkReg(tagged Invalid);
  Reg#(Bool)              chkReqInFlight <- mkReg(False);
  Reg#(Bit#(8))           chkReqTag      <- mkRegU;
  Reg#(Bit#(32))          chkVal         <- mkReg(0);
  Reg#(Bit#(32))          chkErrors      <- mkReg(0);
  Reg#(Bit#(32))          chkUnroll      <- mkReg(0);
  Reg#(Bit#(8))           chkNumBuf      <- mkReg(genchkNumBuf);
  Reg#(Bit#(8))           chkRepeat      <- mkReg(genchkRepeat);
  Reg#(Bit#(8))           chkCurBuf      <- mkReg(0);
  Reg#(Bool)              chkDoMeta0     <- mkReg(False);
  Reg#(Bool)              chkDoMeta1     <- mkReg(False);
  Reg#(Bit#(32))          chkLen         <- mkReg(genchkInit);
  Reg#(Bool)              chkDoDoor      <- mkReg(False);
  Reg#(Bit#(8))           chkOpcode      <- mkReg(0);
  RandI#(8)               chkRand        <- mkRand;
  Reg#(Maybe#(Bit#(8)))   chkHoldOff     <- mkReg(tagged Invalid);
  Reg#(Bit#(8))           chkBlkCount    <- mkReg(0);

  Bit#(24) chkMesgBase  = 24'h00_8000;
  Bit#(24) chkMesgPitch = 24'h00_0800; 
  Bit#(24) chkMetaBase  = 24'h00_B800;
  Bit#(24) chkDbellAddr = 24'hF0_0018;   // config prop
  Bit#(24) chkReadyAddr = 24'hF0_0020;   // config prop

  Reg#(Bit#(32))          chkMesgAddr    <- mkReg(extend(chkMesgBase));
  Reg#(Bit#(32))          chkMetaAddr    <- mkReg(extend(chkMetaBase));
  Reg#(Bit#(32))          chkTmpIndex    <- mkReg(0);

  Reg#(Bool) chkRespMesgCont <- mkReg(False);

  Reg#(Bit#(128))         chkDebugExp    <- mkReg(0);
  Reg#(Bit#(128))         chkDebugGot    <- mkReg(0);
  Reg#(Bit#(16))          chkDebugPbe    <- mkReg(0);
  Reg#(Bit#(128))         chkDebugPdata  <- mkReg(0);

  /*
  rule chkHoldOffStart (dpGo && !isValid(chkReady) && !chkReqInFlight && !tlpOutMutex && !isValid(chkHoldOff) && chkGo);
    let r <- chkRand.get;
    chkHoldOff <= tagged Valid (r%32);
  endrule

  rule chkHoldOffDec (isValid(chkHoldOff));
    chkHoldOff <= tagged Valid (fromMaybe(?,chkHoldOff) - 1);
  endrule
  */

  //rule chkReqReady (dpGo && !isValid(chkReady) && !chkReqInFlight && !tlpOutMutex && fromMaybe('1,chkHoldOff)==0);
  rule chkReqReady (dpGo && !isValid(chkReady) && !chkReqInFlight && !tlpOutMutex && chkGo);
    chkHoldOff <= tagged Invalid;
    //blockChecker <= True; // wait for Generator to let us try again
    chkReqInFlight <= True;
    Bit#(32) bAddr = extend(chkReadyAddr);
    Bit#(30) dwAddr = truncate(bAddr>>2); 
    Bit#(7) bar = ctrlPlaneBar;
    outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
    tag <= tag + 1;                              // Bump the transaction tag
    chkReqTag <= tag;
  endrule

  rule chkRespReady (dpGo && !isValid(chkReady) && chkReqInFlight && tagMatch(chkReqTag,inF.first) );
    let p = inF.first; 
    chkReqInFlight <= False;
    inF.deq;
    let d  = byteSwap(p.data[31:0]);   // perform read DWORD byteSwap

    /*
    if (d==0) begin
      chkBlkCount <= chkBlkCount+1;
      if (chkBlkCount==255) begin genGo<=True; chkGo<=False; end
    end
    */

    if (d != 0) chkReady <= tagged Valid d;
    // startup...
    if (chkLen==0)  chkDoMeta0 <= True;   // skip getting any data in chkMesg
    else            chkUnroll <= chkLen;
    chkTmpIndex <= 0;
  endrule

  rule chkReqMesg (dpGo && fromMaybe(0,chkReady)>0 && chkUnroll!=0 && !chkDoMeta0 && !chkDoMeta1 && !chkReqInFlight && !tlpOutMutex);
    chkReqInFlight <= True;
    Bit#(7)  bar = dataPlaneBar;
    Bit#(32) bAddr = chkMesgAddr + chkTmpIndex;
    //outF.enq(makeRdDwReqTLP(bar, truncate(bAddr>>2), tag));  // Launch the read-request
    PciId    rid    = PciId {bus:255, dev:0, func:0};
    Bit#(10) len    = truncate(chkUnroll>>2);
    Bit#(30) dwAddr = truncate(bAddr>>2);
    MemReqHdr1 h = makeRdReqHdr(rid, tag, len, '1, '0, False);
    let d = PTW16 {
      data : {pack(h), dwAddr,2'b0, 32'h0},
      be   : '1,
      hit  : bar,
      sof  : True,
      eof  : True};
    outF.enq(d);

    tag       <= tag + 1; 
    chkReqTag <= tag;
  endrule

  rule chkRespMesg (dpGo && fromMaybe(0,chkReady)>0 && chkUnroll!=0 && !chkDoMeta0 && !chkDoMeta1 && chkReqInFlight && tagMatch(chkReqTag,inF.first) && !chkRespMesgCont);
    let p = inF.first; 
    inF.deq;
    let got  = byteSwap(p.data[31:0]);   // perform read DWORD byteSwap
    if (got != chkVal) begin
      chkErrors <= chkErrors + 1;
      $display("[%0d]: %m: chkRespMesg FirstDW ***MISMATCH*** chkVal:%0x got:%0x", $time, chkVal, got);
    end
    chkTmpIndex <= chkTmpIndex + 4;
    chkUnroll   <= chkUnroll - 4;
    chkVal      <= chkVal + 1;
    if (chkUnroll==4) begin
      chkDoMeta0     <= True;
      chkReqInFlight <= False;
    end else begin
      chkRespMesgCont <= True;
      tlpInMutex      <= True;  // Take tlpInMutex for multi-cycle
    end
  endrule

  rule chkRespMesgContinue (dpGo && fromMaybe(0,chkReady)>0 && chkUnroll!=0 && chkRespMesgCont && !chkDoMeta0 && !chkDoMeta1 && chkRespMesgCont);
    Bit#(32) exp0  = chkVal;
    Bit#(32) exp1  = chkVal+1;
    Bit#(32) exp2  = chkVal+2;
    Bit#(32) exp3  = chkVal+3;
    Bool lastBeat = (chkUnroll<=16);
    Bit#(16) lRem = 0;
    if (lastBeat) begin
      case (truncate(chkUnroll)&5'h1F) matches
        5'h04 : begin lRem = 16'hF000; chkVal<=chkVal+1; end
        5'h08 : begin lRem = 16'hFF00; chkVal<=chkVal+2; end
        5'h0C : begin lRem = 16'hFFF0; chkVal<=chkVal+3; end
        5'h10 : begin lRem = 16'hFFFF; chkVal<=chkVal+4; end
      endcase
    end else chkVal <= chkVal+4;

    let p = inF.first; 
    inF.deq;
    let got0  = byteSwap(p.data[127:96]);
    let got1  = byteSwap(p.data[95:64]);
    let got2  = byteSwap(p.data[63:32]);
    let got3  = byteSwap(p.data[31:0]);

    chkDebugExp   <= {exp0,exp1,exp2,exp3};
    chkDebugGot   <= {got0,got1,got2,got3};
    chkDebugPbe   <= p.be  ;
    chkDebugPdata <= p.data;

    if (!lastBeat) begin
      if (exp0!=got0 || exp1!=got1 || exp2!=got2 || exp3!=got3) begin
        chkErrors <= chkErrors + 1;
        $display("[%0d]: %m: chkRespMesg 4DW-C ***MISMATCH*** chkVal:%0x got:%0x", $time, {exp0,exp1,exp2,exp3}, {got0,got1,got2,got3});
      end
    end else begin
      case (truncate(chkUnroll)&5'h1F) matches
        5'h04 : begin 
          if (exp0!=got0) begin
            chkErrors <= chkErrors + 1;
            $display("[%0d]: %m: chkRespMesg 1DW-L ***MISMATCH*** chkVal:%0x got:%0x", $time, exp0, got0);
          end
        end
        5'h08 : begin 
          if (exp0!=got0 || exp1!=got1) begin
            chkErrors <= chkErrors + 1;
            $display("[%0d]: %m: chkRespMesg 2DW-L ***MISMATCH*** chkVal:%0x got:%0x", $time, {exp0,exp1}, {got0,got1});
          end
        end
        5'h0C : begin 
          if (exp0!=got0 || exp1!=got1 || exp2!=got2 ) begin
            chkErrors <= chkErrors + 1;
            $display("[%0d]: %m: chkRespMesg 3DW-L ***MISMATCH*** chkVal:%0x got:%0x", $time, {exp0,exp1,exp2}, {got0,got1,got2});
          end
        end
        5'h10 : begin
          if (exp0!=got0 || exp1!=got1 || exp2!=got2 || exp3!=got3) begin
            chkErrors <= chkErrors + 1;
            $display("[%0d]: %m: chkRespMesg 4DW-L ***MISMATCH*** chkVal:%0x got:%0x", $time, {exp0,exp1,exp2,exp3}, {got0,got1,got2,got3});
          end
        end
      endcase
    end

    chkUnroll <= lastBeat ? 0 : chkUnroll-16;
    if (lastBeat) begin
      chkDoMeta0      <= True;
      chkReqInFlight  <= False;
      chkRespMesgCont <= False;
      tlpInMutex      <= False;
    end 
  endrule


  rule chkMeta0Req (dpGo && fromMaybe(0,chkReady)>0 && chkDoMeta0 && !chkReqInFlight && !tlpOutMutex);
    chkReqInFlight <= True;
    Bit#(7)  bar   = dataPlaneBar;
    Bit#(32) bAddr = chkMetaAddr;
    outF.enq(makeRdDwReqTLP(bar, truncate(bAddr>>2), tag));  // Launch the read-request
    tag       <= tag + 1; 
    chkReqTag <= tag;
  endrule

  rule chkMeta0Resp (dpGo && fromMaybe(0,chkReady)>0 && chkDoMeta0 && chkReqInFlight && tagMatch(chkReqTag,inF.first) );
    let p = inF.first; 
    chkReqInFlight <= False;
    inF.deq;
    let got  = byteSwap(p.data[31:0]);   // get length from Meta0
    if (got != chkLen) begin
      chkErrors <= chkErrors + 1;
      $display("[%0d]: %m: chkMeta0Resp ***MISMATCH*** chkLen:%0x got:%0x", $time, chkLen, got);
    end
    chkDoMeta0 <= False;
    chkMetaAddr <= chkMetaAddr + 4;
    chkDoMeta1  <= True;
  endrule


  rule chkMeta1Req (dpGo && fromMaybe(0,chkReady)>0 && chkDoMeta1 && !chkReqInFlight && !tlpOutMutex);
    chkReqInFlight <= True;
    Bit#(7)  bar   = dataPlaneBar;
    Bit#(32) bAddr = chkMetaAddr;
    outF.enq(makeRdDwReqTLP(bar, truncate(bAddr>>2), tag));  // Launch the read-request
    tag       <= tag + 1; 
    chkReqTag <= tag;
  endrule

  rule chkMeta1Resp (dpGo && fromMaybe(0,chkReady)>0 && chkDoMeta1 && chkReqInFlight && tagMatch(chkReqTag,inF.first) );
    let p = inF.first; 
    chkReqInFlight <= False;
    inF.deq;
    let got  = byteSwap(p.data[31:0]);   // get length from Meta0
    if (got != (extend(chkOpcode) | 32'h8000_0000)) begin
      chkErrors <= chkErrors + 1;
      $display("[%0d]: %m: chkMeta1Resp ***MISMATCH*** chkOpcode:%0x got:%0x", $time, chkOpcode, got);
    end
    chkDoMeta1 <= False;
    chkDoDoor  <= True;
  endrule

  rule chkDoorbell (dpGo && fromMaybe(0,chkReady)>0 && chkDoDoor && !tlpOutMutex);
    chkDoDoor <= False;
    Bit#(7)  bar   = ctrlPlaneBar;
    Bit#(32) bAddr = extend(chkDbellAddr);
    Bit#(32) wd    = 32'h0000_0001;
    outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
    chkOpcode <= chkOpcode + 1;
    // buffer wrap...
    Bool tc = !(chkCurBuf < chkNumBuf-1);
    chkCurBuf   <= tc ? 0                   : chkCurBuf+1;
    chkMesgAddr <= tc ? extend(chkMesgBase) : chkMesgAddr+extend(chkMesgPitch);
    chkMetaAddr <= tc ? extend(chkMetaBase) : chkMetaAddr+extend(8'h0C);
    chkReady <= tagged Invalid;
    // next Chk
    if (chkRepeat==0) begin
      chkLen <= chkLen + genchkDelta;
      chkRepeat <= genchkRepeat;
    end else chkRepeat <= chkRepeat-1;
  endrule

  interface Client client;
    interface request  = toGet(outF);
    interface response = toPut(inF); 
  endinterface

endmodule: mkOCTG_dmaFP

endpackage: OCTG_dmaFP

