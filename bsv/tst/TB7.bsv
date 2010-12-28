// TB7.bsv - A simple AXI testbench
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4L::*;
import WCIS2AL4M::*;
import A4LS::*;
import OCWip::*;

import Connectable::*;
import GetPut::*;
import StmtFSM::*;

(* synthesize *)
module mkTB7();

  Reg#(Bit#(16))         simCycle       <- mkReg(0);         // simulation cycle counter
  WciMasterIfc#(20)      wci            <- mkWciMaster;   // WCI-OCP-Master convienenice logic

  WCIS2A4LMIfc           wci2a4l        <- mkWCIS2A4LM(True, reset_by wci.mas.mReset_n);   // instance the WCI/AXI4L Bridge
  A4LSIfc                a4ls           <- mkA4LS     (True, reset_by wci.mas.mReset_n);   // instance the simple AXI4-L Slave

  Wci_Em#(20 )           wci_Em <- mkWciMtoEm(wci.mas);  // Convert the conventional to explicit 
  mkConnection(wci_Em,  wci2a4l.wciS0);                    // connect the WCI Master to the Bridge WCI Side
  mkConnection(wci2a4l.axiM0, a4ls);                       // connect the Bridge AXI4L-M to S

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
    $display("[%0d]: %m: mkTB7 termination", $time);
    $finish;
  endrule

endmodule: mkTB7

