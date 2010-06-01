// OCTG_nosm.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCTG_nosm;

import TLPMF::*;

import PCIE::*;
import FIFO::*;
import LFSR::*;
import Vector::*;
import GetPut::*;
import StmtFSM::*;
import ClientServer::*;
import Connectable::*;


(* synthesize *)
module mkOCTG_nosm (OCTGIfc);
  FIFO#(PTW16)    outF     <- mkFIFO;       // Outbound TLPs, typically requests
  FIFO#(PTW16)    inF      <- mkFIFO;       // Inbound  TLPs, typically completions
  Reg#(Bool)      started  <- mkReg(False); // True once running
  Reg#(Bit#(8))   tag      <- mkReg(0);     // Requester Tag Source
  Reg#(DWord)     dwValue  <- mkRegU;       // Register to hold read response

  PTW16 nullPTW = unpack('0);

  // The multi-cycle read reqeust/response sub-seqeuence...
  function RStmt#(DWord) rdSeq0 (Bit#(0) b, Bit#(32) bAddr);
  Bit#(30) dwAddr = truncate(bAddr>>2); 
  Bit#(7) bar = 7'h01; //data plane
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

  // The multi-cycle read reqeust/response sub-seqeuence...
  function RStmt#(DWord) rdSeq1 (Bit#(0) b, Bit#(32) bAddr);
  Bit#(30) dwAddr = truncate(bAddr>>2); 
  Bit#(7) bar = 7'h02; //control plane
  seq
    action
      outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
      tag <= tag + 1;                              // Bump the transaction tag
    endaction
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
    action
      outF.enq(makeWtDwReqTLP(bar, truncate(bAddr>>2), wd));
      $display("[%0d]: %m: WRITE-INITIATED  Addr:%0x Data:%0x", $time, bAddr, wd);
    endaction
  endfunction 

  function Action fsmReadReq(Bit#(7) bar, Bit#(32) bAddr);
    action
      Bit#(30) dwAddr = truncate(bAddr>>2); 
      outF.enq(makeRdDwReqTLP(bar, dwAddr, tag));  // Launch the read-request
      tag <= tag + 1;                              // Bump the transaction tag
      $display("[%0d]: %m: READ-INITIATED  Addr:%0x Tag:%0x", $time, bAddr, tag);
    endaction
  endfunction 

  Stmt req = 
  seq

  endseq;
  FSM reqFsm <- mkFSM(req);

  rule startup (False && !started);
  //rule startup (True && !started);
    reqFsm.start;
    started <= True;
  endrule

  interface Client client;
    interface request  = toGet(outF);
    interface response = toPut(inF); 
  endinterface
endmodule: mkOCTG_nosm

endpackage: OCTG_nosm

