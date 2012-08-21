// GMACTB1 - A Testbench for the Async GMAC
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import BiasWorker  ::*;
import CounterM    ::*;
import GMAC        ::*;

import Connectable ::*;
import FIFO        ::*;
import GetPut      ::*;
import StmtFSM     ::*;

interface ABSGenIfc;
  interface Get#(ABS) stream;
endinterface

module mkABSGen#(UInt#(12) length) (ABSGenIfc);
  FIFO#(ABS)      gsF       <- mkFIFO;
  Reg#(Bool)      isSOF     <- mkReg(True);
  Reg#(UInt#(12)) lenRemain <- mkReg(length);
  Reg#(Bit#(8))   pattern   <- mkReg(0);

  rule genseq;
    Bool isEOF = (lenRemain==1);
    Bool isEmpty = False;
    Bool isAbort = False;
    case ({pack(isAbort), pack(isEmpty), pack(isEOF), pack(isSOF)})
      4'b0000 : gsF.enq(tagged ValidNotEOP pattern);  // Body with data
      4'b0001 : gsF.enq(tagged ValidNotEOP pattern);  // Head with data
      4'b0010 : gsF.enq(tagged ValidEOP    pattern);  // Tail with data 
      4'b0011 : gsF.enq(tagged ValidEOP    pattern);  // Single Cycle with data  (1B)
      4'b0100 : noAction;                             // Consume empty bubble
      4'b0101 : noAction;                             // Consume empyy bubble with SOP
      4'b0110 : gsF.enq(tagged EmptyEOP);             // Late Good EOP
      4'b0111 : gsF.enq(tagged EmptyEOP);             // Single Cycle with no data (0B)
      4'b1000 : gsF.enq(tagged AbortEOP);             // Abort has priority over others
      4'b1001 : gsF.enq(tagged AbortEOP);
      4'b1010 : gsF.enq(tagged AbortEOP);
      4'b1011 : gsF.enq(tagged AbortEOP);
      4'b1100 : gsF.enq(tagged AbortEOP);
      4'b1101 : gsF.enq(tagged AbortEOP);
      4'b1110 : gsF.enq(tagged AbortEOP);
      4'b1111 : gsF.enq(tagged AbortEOP);
    endcase
    lenRemain <= (lenRemain==1) ? length : lenRemain-1;
    isSOF <= (lenRemain==1);
    //pattern <= (lenRemain==1) ? 0 : pattern + 1;
    pattern <=  pattern + 1;
  endrule

  interface Get stream = toGet(gsF);
endmodule

interface EBSGenIfc;
  interface Get#(EBS) stream;
endinterface

module mkEBSGen#(UInt#(12) length) (EBSGenIfc);
  FIFO#(EBS)      gsF       <- mkFIFO;
  Reg#(Bool)      isSOF     <- mkReg(True);
  Reg#(UInt#(12)) lenRemain <- mkReg(length);
  Reg#(Bit#(8))   pattern   <- mkReg(0);

  rule genseq;
    gsF.enq( EBS {
      abort : False,
      empty : False,
      sof   : isSOF,
      eof   : (lenRemain==1),
      data  : pattern
     });
  lenRemain <= (lenRemain==1) ? length : lenRemain-1;
  isSOF <= (lenRemain==1);
  //pattern <= (lenRemain==1) ? 0 : pattern + 1;
  pattern <=  pattern + 1;
  endrule

  interface Get stream = toGet(gsF);
endmodule

(* synthesize *)
module mkGMACTB1();

  Reg#(Bit#(16))              simCycle       <- mkReg(0);       // simulation cycle counter
  WciEMasterIfc#(20,32)       wci            <- mkWciEMaster;   // WCI-OCP-Master convienenice logic
  WsiMasterIfc#(12,32,4,8,0)  wsiM           <- mkWsiMaster;    // WSI-OCP-Master convienenice logic
  WsiSlaveIfc #(12,32,4,8,0)  wsiS           <- mkWsiSlave;     // WSI-OCP-Slave  convienenice logic


  // It is each WCI master's job to generate for each WCI M-S pairing a mReset_n signal that can reset each worker
  // We send that reset in on the "reset_by" line to reset all state associated with worker module...
  BiasWorker4BIfc             biasWorker     <- mkBiasWorker(True, reset_by wci.mas.mReset_n);   // instance the biasWorker DUT

  Reg#(Bool)                  enWsiSource    <- mkReg(False);   // Trigger for WSI generator
  Reg#(Bool)                  enWsiChecker   <- mkReg(False);   // Trigger for WSI checker
  Reg#(Bool)                  testOperating  <- mkReg(False);   // Enable for test Operating
  Reg#(Bit#(16))              srcMesgCount   <- mkReg(0);       // Number of Messages sent
  Reg#(Bit#(16))              srcUnrollCnt   <- mkReg(0);       // Message Positions to go
  Reg#(Bit#(32))              srcDataOut     <- mkReg(0);       // DWORD ordinal count
  Reg#(Bit#(16))              dstMesgCount   <- mkReg(0);       // Number of Messages rcvd
  Reg#(Bit#(16))              dstUnrollCnt   <- mkReg(0);       // Message Positions to go
  Reg#(Bit#(32))              dstDataOut     <- mkReg(0);       // DWORD ordinal count

  Reg#(Bool)                  mesgHadError   <- mkReg(False);   // Message had an Error
  CounterSat#(UInt#(32))      goodDataCnt    <- mkCounterSat;   // Good Data Words
  CounterSat#(UInt#(32))      goodMesgCnt    <- mkCounterSat;   // Good Messages
  CounterSat#(UInt#(32))      badDataCnt     <- mkCounterSat;   // Bad  Data Words
  CounterSat#(UInt#(32))      badMesgCnt     <- mkCounterSat;   // Bad  Messages

  ABSGenIfc                   rsXmtGen       <- mkABSGen(19);
  ABSGenIfc                   rsRcvGen       <- mkABSGen(19);


  Clock                       thisClk        <- exposeCurrentClock;
  RxRSIfc                     rxRS           <- mkRxRSAsync(thisClk);
  TxRSIfc                     txRS           <- mkTxRSAsync(thisClk);

  mkConnection(txRS.gmii, rxRS.gmii); // Loopback txRS to rxRS

  rule sendPat (simCycle>5);
    let z <- rsXmtGen.stream.get;
    txRS.tx.put(z);
  endrule

  rule recvPat;
    let dGot <- rxRS.rx.get;
    let dExp <- rsRcvGen.stream.get;

    if (getData(dGot) != getData(dExp)) begin
      $display("[%0d]: %m: recvPat MISMATCH: exp:%0x got:%0x", $time, getData(dExp), getData(dGot));
      badDataCnt.inc;
    end else begin
      goodDataCnt.inc;
    end

    if (isEOP(dGot)) begin
      //if (!isEOP(dExp) || dExp.abort) begin
      if (!isEOP(dExp) ) begin
        $display("[%0d]: %m: recv EOF MISMATCH: exp:%0x got:%0x", $time, isEOP(dExp), isEOP(dGot));
        badMesgCnt.inc;
      end else begin
        goodMesgCnt.inc;
      end
    end
  endrule





  

  // Connect the biasWorker DUT's three interfaces...
  mkConnection(wci.mas,  biasWorker.wciS0);             // connect the WCI Master to the DUT
  mkConnection(toWsiEM(wsiM.mas), biasWorker.wsiS0);   // connect the Source wsiM to the biasWorker wsi-S input
  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv); // Convert the conventional to explicit 
  mkConnection(biasWorker.wsiM0,  wsi_Es);             // connect the biasWorker wsi-M output to the Sinc wsiS

  // WCI Interaction
  // A sequence of control-configuration operartions to be performed...
  Stmt wciSeq = 
  seq
    $display("[%0d]: %m: Checking for DUT presence...", $time);
    await(wci.present);

    $display("[%0d]: %m: Taking DUT out of Reset...", $time);
    wci.req(Admin, True,  20'h00_0024, 'h8000_0004, 'hF);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: CONTROL-OP: -INITIALIZE- DUT...", $time);
    wci.req(Control, False, 20'h00_0000, ?, ?);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    wci.req(Config, True, 20'h00_0004, 32'h0000_4242, 'hF);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties...", $time);
    wci.req(Config, False, 20'h00_0004, ?, ?);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: CONTROL-OP: -START- DUT...", $time);
    wci.req(Control, False, 20'h00_0004, ?, ?);
    action let r <- wci.resp; endaction

    testOperating <= True;
    dstUnrollCnt  <= 16;
    enWsiChecker  <= True;
    srcUnrollCnt  <= 16;
    enWsiSource   <= True;
  endseq;
  FSM  wciSeqFsm  <- mkFSM(wciSeq);
  Once wciSeqOnce <- mkOnce(wciSeqFsm.start);

  // Start of the WCI sequence...
  rule runWciSeq;
    //wciSeqOnce.start; // FIXME Uncomment me for the FSM
  endrule

  // This rule inhibits dataflow on the WSI ports until the WCI port isOperating...
  rule operating_actions (testOperating);
    wsiS.operate();
    wsiM.operate();
  endrule

  rule gmac_actions (True);
    txRS.txOperate();
    rxRS.rxOperate();
  endrule

  // WSI Interaction
  // Producer Stream...
  rule wsi_source (enWsiSource);
    Bool lastWord  = (srcUnrollCnt == 1);
    Bit#(8) opcode = 0;
    Bit#(16) wsiBurstLength = 64>>2; // convert Bytes to ndw-wide WSI Words burstLength
    wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                             reqLast : lastWord,
                             reqInfo : opcode,
                        burstPrecise : False,
                         burstLength : truncate(wsiBurstLength),
                               data  : srcDataOut,
                             byteEn  : '1,
                           dataInfo  : '0 });
    srcDataOut  <= srcDataOut  + 1;
    if (lastWord) begin
      srcMesgCount <= srcMesgCount + 1;
      $display("[%0d]: %m: wsi_source: End of WSI Producer Egress: srcMesgCount:%0x opcode:%0x", $time, srcMesgCount, opcode);
      srcUnrollCnt <= wsiBurstLength;
    end else begin
      srcUnrollCnt <= srcUnrollCnt - 1;
    end
  endrule

  // Consume Stream...
  rule wsi_checker (enWsiChecker);
    Bit#(8) opcode = wsiS.reqPeek.reqInfo;
    Bit#(16) wsiBurstLength =  extend(wsiS.reqPeek.burstLength);
    Bit#(16) mesgLengthB    =  wsiBurstLength<<2;
    Bool lastWord  = (dstUnrollCnt == 1);
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;
    Bit#(32) dataGot = w.data;
    Bit#(32) dataExp = dstDataOut;
    Bool errorInMessage = False;

    if (dataGot != dataExp) begin
      $display("[%0d]: %m: wsi_checker MISMATCH: exp:%0x got:%0x srcMesgCount:%0x", $time, dataExp, dataGot, dstMesgCount);
      badDataCnt.inc;
      errorInMessage = True;
    end else goodDataCnt.inc;

    dstDataOut  <= dstDataOut  + 1;
    if (lastWord) begin
      dstMesgCount <= dstMesgCount + 1;
      $display("[%0d]: %m: wsi_source: End of WSI Consumer Ingress: dstMesgCount:%0x opcode:%0x", $time, dstMesgCount, opcode);
      dstUnrollCnt <= wsiBurstLength;
      if (errorInMessage || mesgHadError) badMesgCnt.inc;
      else                                goodMesgCnt.inc;
      mesgHadError <= False; // reset for next message
    end else begin
      dstUnrollCnt <= dstUnrollCnt - 1;
      mesgHadError <= errorInMessage;
    end
  endrule

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkGMACTB termination", $time);
    $display("goodDataCnt : %08x (%d)", goodDataCnt, goodDataCnt);
    $display("goodMesgCnt : %08x (%d)", goodMesgCnt, goodMesgCnt);
    $display("badDataCnt  : %08x (%d)", badDataCnt,  badDataCnt);
    $display("badMesgCnt  : %08x (%d)", badMesgCnt,  badMesgCnt);
    if (badDataCnt == 0) $display("mkGMACTB PASSED OK");
    else                 $display("mkGMACTB had %d ERRORS and FAILED", badDataCnt);
    $finish;
  endrule

endmodule: mkGMACTB1

