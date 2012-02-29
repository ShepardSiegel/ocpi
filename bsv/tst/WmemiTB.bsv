// WmemiTB - A testbench for Wmemi
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import MemiTestWorker  ::*;
import CounterM    ::*;

import BRAM        ::*;
import Connectable ::*;
import FIFO        ::*;
import GetPut      ::*;
import StmtFSM     ::*;

interface WmemiBRAMIfc;
  interface WmemiES16B    wmemiS0;  // The Wmemi slave interface provided to the application
endinterface

//(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWmemiBRAM (WmemiBRAMIfc);

  WmemiSlaveIfc#(36,12,128,16)   wmemi   <- mkWmemiSlave; 

  rule opeate_assert;
    wmemi.operate();
  endrule

  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = valueOf(1024);   // 1K x 16 = 16KB
    cfg.latency    = 1;
  BRAM1Port#(Bit#(10), Bit#(128)) bram <- mkBRAM1Server(cfg);

  // This style allows only one dh cycle per request - no bursts...
  rule getRequest;
    let req <- wmemi.req;
    if (req.cmd==WR) begin // Write...
       let dh <- wmemi.dh;
       //let breq = BRAMRequestBE {writeen:dh.dataByteEn,  address:truncate(req.addr>>6), datain:dh.data, responseOnWrite:False };
       // TODO: Add in Byte En
       let breq = BRAMRequest {write:True,  address:truncate(req.addr>>6), datain:dh.data, responseOnWrite:False };
       bram.portA.request.put(breq); 
    end else begin         // Read...
       let breq = BRAMRequest   {write:False, address:truncate(req.addr>>6), datain:0, responseOnWrite:False };
       bram.portA.request.put(breq); 
    end
  endrule
  
  rule getResponse;
    let brsp <- bram.portA.response.get;
    wmemi.respd(brsp, True);
  endrule
   
  WmemiES16B wmemi_Es <- mkWmemiStoES(wmemi.slv);
  interface WmemiES16B  wmemiS0  = wmemi_Es;
endmodule 


(* synthesize *)
module mkWmemiTB();

  Reg#(Bit#(16))              simCycle       <- mkReg(0);       // simulation cycle counter
  WciEMasterIfc#(20,32)       wci            <- mkWciEMaster;   // WCI-OCP-Master convienenice logic

  // It is each WCI master's job to generate for each WCI M-S pairing a mReset_n signal that can reset each worker
  // We send that reset in on the "reset_by" line to reset all state associated with worker module...
  MemiTestWorkerIfc           memtst         <- mkMemiTestWorker(True, reset_by wci.mas.mReset_n); 
  WmemiBRAMIfc                mem            <- mkWmemiBRAM;

  mkConnection(memtst.wmemiM0, mem.wmemiS0);
  
  mkConnection(wci.mas,  memtst.wciS0);  // connect the WCI Master to the DUT

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
    wci.req(Config, True, 20'h00_0000, 32'h0000_0001, 'hF);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: Read Dataplane Config Properties...", $time);
    wci.req(Config, False, 20'h00_0000, ?, ?);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: CONTROL-OP: -START- DUT...", $time);
    wci.req(Control, False, 20'h00_0004, ?, ?);
    action let r <- wci.resp; endaction

    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    wci.req(Config, True, 20'h00_0004, 32'h0000_0020, 'hF);  // Switch from default 16 to 32 16B words
    action let r <- wci.resp; endaction


    $display("[%0d]: %m: Write Dataplane Config Properties...", $time);
    wci.req(Config, True, 20'h00_0030, 32'h0000_0000, 'hF);  // Start test
    action let r <- wci.resp; endaction



  endseq;
  FSM  wciSeqFsm  <- mkFSM(wciSeq);
  Once wciSeqOnce <- mkOnce(wciSeqFsm.start);

  // Start of the WCI sequence...
  rule runWciSeq;
    wciSeqOnce.start; // FIXME Uncomment me for the FSM
  endrule

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkWmemiTB termination", $time);
    $finish;
  endrule

endmodule: mkWmemiTB


