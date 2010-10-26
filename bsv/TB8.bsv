// TB8.bsv - A simple native WCI:AXI testbench
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import ClientServer::*;
import Connectable::*;
import GetPut::*;
import StmtFSM::*;

(* synthesize *)
module mkTB8();

  Reg#(Bit#(16))         simCycle       <- mkReg(0);         // simulation cycle counter
  WciAxiMasterIfc        wci_m          <- mkWciAxiMaster;   // WCI::AXI Master convienenice logic
  WciAxiSlaveIfc         wci_s          <- mkWciAxiSlave;   // WCI::AXI Master convienenice logic

  mkConnection(wci_m.axi, wci_s.axi);

  Reg#(Bit#(32))         reg4           <- mkReg(0);

  rule target_action;
    let req <- wci_s.wci.wciTarg.request.get;
    wci_s.wci.wciTarg.response.put(unpack(0));
  endrule


  // A sequence of WCI control-configuration operartions to be performed...
  Stmt wciSeq = 
  seq
    //$display("[%0d]: %m: Checking for DUT presence...", $time);
    //await(wci.present);

    //$display("[%0d]: %m: Taking DUT out of Reset...", $time);
    //wci.req(Admin, True,  20'h00_0024, 'h8000_0004, 'hF);
    //action let r <- wci.resp; endaction

    //$display("[%0d]: %m: CONTROL-OP: -INITIALIZE- DUT...", $time);
    //wci.req(Control, False, 20'h00_0000, ?, ?);
    //action let r <- wci.resp; endaction

    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    wci_m.wci.wciInit.request.put(wciConfigWrite(32'h0000_0004, 32'h0000_4242, 'hF));
    action let r <- wci_m.wci.wciInit.response.get; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties...", $time);
    wci_m.wci.wciInit.request.put(wciConfigRead(32'h0000_0004));
    action let r <- wci_m.wci.wciInit.response.get; endaction

    //$display("[%0d]: %m: CONTROL-OP: -START- DUT...", $time);
    //wci.req(Control, False, 20'h00_0004, ?, ?);
    //action let r <- wci.resp; endaction

  endseq;
  FSM  wciSeqFsm  <- mkFSM(wciSeq);
  Once wciSeqOnce <- mkOnce(wciSeqFsm.start);

  // Start of the WCI sequence...
  rule runWciSeq;
    wciSeqOnce.start;
  endrule

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkTB8 termination", $time);
    $finish;
  endrule

endmodule: mkTB8

