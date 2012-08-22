// TB11.bsv - A testbench for ProtocolMonitor
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import BiasWorker::*;
import ProtocolMonitor::*;

import Connectable::*;
import GetPut::*;
import Real::*;
import StmtFSM::*;


(* synthesize *)
module mkTB11();

  Reg#(Bit#(16))              simCycle       <- mkReg(0);       // simulation cycle counter
  WciMasterIfc#(20,32)        wci            <- mkWciMaster;    // WCI-OCP-Master convienenice logic
  WsiMasterIfc#(12,32,4,8,0)  wsiM           <- mkWsiMaster;    // WSI-OCP-Master convienenice logic
  WsiSlaveIfc #(12,32,4,8,0)  wsiS           <- mkWsiSlave;     // WSI-OCP-Slave  convienenice logic

  // It is each WCI master's job to generate for each WCI M-S pairing a mReset_n signal that can reset each worker
  // We send that reset in on the "reset_by" line to reset all state associated with worker module...
  BiasWorkerIfc#(1)           biasWorker      <- mkBiasWorker(True, reset_by wci.mas.mReset_n); 

  Reg#(Bool)                  enWsiSource    <- mkReg(False);   // Trigger for WSI generator
  Reg#(Bool)                  enWsiChecker   <- mkReg(False);   // Trigger for WSI checker
  Reg#(Bool)                  testOperating  <- mkReg(False);   // Enable for test Operating
  Reg#(Bit#(16))              srcMesgCount   <- mkReg(0);       // Number of Messages sent
  Reg#(Bit#(16))              srcUnrollCnt   <- mkReg(0);       // Message Positions to go
  Reg#(Bit#(32))              srcDataOut     <- mkReg(0);       // DWORD ordinal count
  Reg#(Bit#(6))               srcIndex       <- mkReg(0);       // Src Tone Index
  Reg#(Bit#(16))              dstMesgCount   <- mkReg(0);       // Number of Messages sent
  Reg#(Bit#(16))              dstUnrollCnt   <- mkReg(0);       // Message Positions to go
  Reg#(Bit#(32))              dstDataOut     <- mkReg(0);       // DWORD ordinal count

  WciMonitorIfc               wciMon         <- mkWciMonitor(8'h42); // monId=h42
  PMEMMonitorIfc              pmemMon0       <- mkPMEMMonitor;
  mkConnection(wciMon.pmem, pmemMon0.pmem);   // Connect the wciMon to an event monitor

  WsiMonitorIfc#(12,32,4,8,0) wsiMon1        <- mkWsiMonitor(8'h52); // monId=h52
  PMEMMonitorIfc              pmemMon1       <- mkPMEMMonitor;
  mkConnection(wsiMon1.pmem, pmemMon1.pmem);   // Connect the wciMon to an event monitor

  WsiMonitorIfc#(12,32,4,8,0) wsiMon2        <- mkWsiMonitor(8'h62); // monId=h62
  PMEMMonitorIfc              pmemMon2       <- mkPMEMMonitor;
  mkConnection(wsiMon2.pmem, pmemMon2.pmem);   // Connect the wciMon to an event monitor

  // Connect the PSD DUT's three interfaces...
  WciEM wci_Em <- mkWciMtoEm(wci.mas);                         // Convert the conventional to explicit 
  mkConnectionMSO(wci_Em,  biasWorker.wciS0, wciMon.observe);  // Connect the WCI Master to the DUT (using mkConnectionMSO to add PM Observer)
  mkConnectionMSO(toWsiEM(wsiM.mas), biasWorker.wsiS0, wsiMon1.observe); // Connect the Source wsiM to the biasWorker wsi-S input
  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);         // Convert the conventional to explicit 
  mkConnectionMSO(biasWorker.wsiM0,  wsi_Es, wsiMon2.observe);           // Connect the biasWorker wsi-M output to the Sinc wsiS

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
    wci.req(Config, True, 20'h00_0004, 32'h0000_AAA2, 'hF);
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
    wciSeqOnce.start;
  endrule

  // This rule inhibits dataflow on the WSI ports until the WCI port isOperating...
  rule operating_actions (testOperating);
    wsiS.operate();
    wsiM.operate();
  endrule

  // WSI Interaction
  // Producer Stream...
  rule wsi_source (enWsiSource);
    Bool lastWord  = (srcUnrollCnt == 1);
    Bit#(8) opcode = 0;
    Bit#(16) wsiBurstLength = 16; // in Words (4B)

    if (srcMesgCount < 3)
      wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                               reqLast : lastWord,
                               reqInfo : opcode,
                          burstPrecise : False,
                           burstLength : '1,
                                 data  : {srcDataOut[15:0],srcDataOut[15:0]},
                               //data  : {tone[srcIndex+1],tone[srcIndex]},
                               byteEn  : '1,
                             dataInfo  : '0 });

    srcIndex <= srcIndex + 2;
    srcDataOut  <= srcDataOut  + 1;
    if (lastWord) begin
      srcMesgCount <= srcMesgCount + 1;
      $display("[%0d]: %m: wsi_source: End of WSI Producer: srcMesgCount:%0x opcode:%0x", $time, srcMesgCount, opcode);
    end
    srcUnrollCnt <= (lastWord) ? wsiBurstLength : srcUnrollCnt - 1;
  endrule


  // Consume Stream...
  rule wsi_checker (enWsiChecker);
    Bit#(8) opcode = wsiS.reqPeek.reqInfo;
    //Bit#(16) wsiBurstLength =  extend(wsiS.reqPeek.burstLength);
    Bit#(16) wsiBurstLength = 16; // in Words (4B)
    Bit#(16) mesgLengthB    =  wsiBurstLength<<2;
    Bool lastWord  = (dstUnrollCnt == 1);
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get;

    Bit#(32) dataGot = w.data;

    //Bit#(32) dataExp = dstDataOut;
    //if (dataGot != dataExp) $display("[%0d]: %m: wsi_checker MISMATCH: exp:%0x got:%0x srcMesgCount:%0x", $time, dataExp, dataGot, dstMesgCount);

    $display("[%0d]: %m: Consumer wordbin:%0d %04x, wordbin:%0d %04x", $time, dstDataOut, dataGot[15:0], dstDataOut+1, dataGot[31:16]);

    dstDataOut  <= dstDataOut  + 2;
    if (lastWord) begin
      dstMesgCount <= dstMesgCount + 1;
      $display("[%0d]: %m: wsi_checker: End of WSI Consumer: dstMesgCount:%0x opcode:%0x", $time, dstMesgCount, opcode);
    end
    dstUnrollCnt <= (lastWord) ? wsiBurstLength : dstUnrollCnt - 1;
  endrule

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkTB11 termination", $time);
    $finish;
  endrule

endmodule: mkTB11

