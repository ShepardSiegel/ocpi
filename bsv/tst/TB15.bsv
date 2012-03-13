// TB15.bsv - A testbench for WSIPatternWorker feeding WSICaptureWorker
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip            ::*;
import WSIPatternWorker ::*;
import WSICaptureWorker ::*;

import Connectable::*;
import GetPut::*;
import StmtFSM::*;

(* synthesize *)
module mkTB15();

  Reg#(Bit#(16))              simCycle       <- mkReg(0);       // simulation cycle counter
  Reg#(Bool)                  testOperating  <- mkReg(False);
  WtiMasterIfc#(64)           wtiM           <- mkWtiMaster;    // WTI time source
  WciEMasterIfc#(20,32)       patWci         <- mkWciEMaster;   // WCI-OCP-Master convienenice logic
  WciEMasterIfc#(20,32)       capWci         <- mkWciEMaster;   // WCI-OCP-Master convienenice logic
  WSIPatternWorker4BIfc       patWorker      <- mkWSIPatternWorker(True, reset_by patWci.mas.mReset_n);
  WSICaptureWorker4BIfc       capWorker      <- mkWSICaptureWorker(True, reset_by capWci.mas.mReset_n);

  mkConnection(patWci.mas, patWorker.wciS0); 
  mkConnection(capWci.mas, capWorker.wciS0); 
  mkConnection(patWorker.wsiM0, capWorker.wsiS0);

  rule driveNow;
    wtiM.reqPut.put( WtiReq{cmd:WR, data:extend(simCycle)});
  endrule

  mkConnection(wtiM.mas, capWorker.wtiS0);

  // WCI Interaction
  // A sequence of control-configuration operartions to be performed...
  Stmt wciSeq = 
  seq
    $display("[%0d]: %m: Checking for DUT presence...", $time);
    await(patWci.present);
    await(capWci.present);

    $display("[%0d]: %m: Taking DUT out of Reset...", $time);
    patWci.req(Admin, True,  20'h00_0024, 'h8000_0004, 'hF);
    action let r <- patWci.resp; endaction
    capWci.req(Admin, True,  20'h00_0024, 'h8000_0004, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: CONTROL-OP: -INITIALIZE- DUT...", $time);
    patWci.req(Control, False, 20'h00_0000, ?, ?);
    action let r <- patWci.resp; endaction
    capWci.req(Control, False, 20'h00_0000, ?, ?);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    patWci.req(Config, True, 20'h00_0004, 32'h0000_0001, 'hF);   // pattern modulus 1
    action let r <- patWci.resp; endaction

    //$display("[%0d]: %m: Read Dataplane Config Properties...", $time);
    //patWci.req(Config, False, 20'h00_0000, ?, 'hF);
    //action let r <- patWci.resp; endaction
    //capWci.req(Config, False, 20'h00_0000, ?, 'hF);
    //action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Pattern Status Register...", $time);
    patWci.req(Config, False, 20'h00_001C, ?, 'hF);
    action let r <- patWci.resp; endaction
    $display("[%0d]: %m: Read Capture Status Register...", $time);
    capWci.req(Config, False, 20'h00_000C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: CONTROL-OP: -START- DUT...", $time);
    patWci.req(Control, False, 20'h00_0004, ?, ?);
    action let r <- patWci.resp; endaction
    capWci.req(Control, False, 20'h00_0004, ?, ?);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Write Capture Enable Bit", $time);
    capWci.req(Config, True, 20'h00_0000, 32'h0000_0001, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Set Page Register to Metadata on Pattern Generator...", $time);
    patWci.req(Control, True, 20'h00_0030, 32'h0000_0400, 'hF);
    action let r <- patWci.resp; endaction
    $display("[%0d]: %m: Write Metadata 0", $time);
    patWci.req(Config, True, 20'h00_0000, 32'h0000_0010, 'hF); // 16B
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_0004, 32'h0000_0002, 'hF); // opcode 2
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_0008, 32'h0000_0042, 'hF); // 
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_000C, 32'h0000_0043, 'hF); // 
    action let r <- patWci.resp; endaction

    $display("[%0d]: %m: Set Page Register to Data Region on Pattern Generator...", $time);
    patWci.req(Control, True, 20'h00_0030, 32'h0000_0800, 'hF);
    action let r <- patWci.resp; endaction
    $display("[%0d]: %m: Write Metadata 0", $time);
    patWci.req(Config, True, 20'h00_0000, 32'h0302_0100, 'hF);
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_0004, 32'h0706_0504, 'hF);
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_0008, 32'h0B0A_0908, 'hF);
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_000C, 32'h0F0E_0D0C, 'hF);
    action let r <- patWci.resp; endaction
    patWci.req(Config, True, 20'h00_0010, 32'h1312_1110, 'hF);
    action let r <- patWci.resp; endaction

    $display("[%0d]: %m: Return Page Register to 0 Pattern Generator...", $time);
    patWci.req(Control, True, 20'h00_0030, 32'h0000_0000, 'hF); // Set Page 0
    patWci.req(Config,  True, 20'h00_0010, 32'h0000_0004, 'hF); // 4 messages to send
    action let r <- patWci.resp; endaction

    $display("[%0d]: %m: Write Pattern Generate Enable Bit", $time);
    patWci.req(Config, True, 20'h00_0000, 32'h0000_0001, 'hF);
    action let r <- patWci.resp; endaction

    testOperating <= True;

  endseq;
  FSM  wciSeqFsm  <- mkFSM(wciSeq);
  Once wciSeqOnce <- mkOnce(wciSeqFsm.start);

  // Start of the WCI sequence...
  rule runWciSeq;
    wciSeqOnce.start;
  endrule

  Stmt wciDumpSeq = 
  seq
    $display("[%0d]: %m: Read Dataplane Config Properties: controlReg", $time);
    capWci.req(Config, False, 20'h00_0000, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties: metaCount", $time);
    capWci.req(Config, False, 20'h00_0004, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties: dataCount", $time);
    capWci.req(Config, False, 20'h00_0008, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties: statusReg", $time);
    capWci.req(Config, False, 20'h00_000C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Setting Worker Control Page Register to 'h800...", $time);
    capWci.req(Admin, True,  20'h00_0030, 'h0000_0800, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0000, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0004, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0008, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_000C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0010, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0014, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0018, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_001C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0020, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0024, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0028, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_002C, ?, 'hF);
    action let r <- capWci.resp; endaction


    $display("[%0d]: %m: Setting Worker Control Page Register to 'h400...", $time);
    capWci.req(Admin, True,  20'h00_0030, 'h0000_0400, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0000, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0004, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0008, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_000C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0010, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0014, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0018, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_001C, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0020, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0024, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_0028, ?, 'hF);
    action let r <- capWci.resp; endaction

    $display("[%0d]: %m: Read Data Buffer", $time);
    capWci.req(Config, False, 20'h00_002C, ?, 'hF);
    action let r <- capWci.resp; endaction


  endseq;
  FSM  wciDumpSeqFsm  <- mkFSM(wciDumpSeq);
  Once wciDumpSeqOnce <- mkOnce(wciDumpSeqFsm.start);

  // Start of the WCI sequence...
  rule runWciDumpSeq (simCycle==900);
    wciDumpSeqOnce.start;
  endrule


  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkTB15 termination", $time);
    if (True)            $display("mkTB15 PASSED OK");
    else                 $display("mkTB15 had %d ERRORS and FAILED", 42);
    $finish;
  endrule

endmodule: mkTB15

