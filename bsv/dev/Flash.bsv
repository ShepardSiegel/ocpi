// Flash.bsv - BSV code to provide Flash memory access functionality
// Copyright (c) 2010,2011  Atomic Rules LCC ALL RIGHTS RESERVED

package Flash;

import Connectable       ::*;
import GetPut            ::*;
import FIFO              ::*;
import StmtFSM           ::*;
import TriState          ::*;

typedef struct {
  Bool      isRead; // request is read
  Bit#(na)  addr;   // memory address
  Bit#(nd)  data;   // write data
 } FlashReq#(numeric type na, numeric type nd) deriving (Bits, Eq);

(* always_enabled, always_ready *)  // As these are io pins connected to the flash device...
interface FLASH_IO#(numeric type na, numeric type nd);
  interface Inout#(Bit#(nd))  io_dq;
  method  Bit#(na)            addr;
  method  Bool                ce_n;
  method  Bool                oe_n;
  method  Bool                we_n;
  method  Bool                wp_n;
  method  Bool                rst_n;
  method  Bool                adv_n;
  method  Action              fwait (Bool i);
endinterface: FLASH_IO

interface FLASH_USR#(numeric type na, numeric type nd);
  interface Put#(FlashReq#(na,nd)) request;
  interface Get#(Bit#(nd))         response;
  method Bool                      waitBit;
endinterface: FLASH_USR

interface FlashControllerIfc#(numeric type na, numeric type nd);
  interface FLASH_IO#(na,nd)       flash;
  interface FLASH_USR#(na,nd)      user;
endinterface: FlashControllerIfc

module mkFlashController (FlashControllerIfc#(na,nd))
  provisos(Add#(a_, 8, nd));  // Make sure nd is at least 8b

  FIFO#(FlashReq#(na,nd))   reqF      <- mkFIFO;
  FIFO#(Bit#(nd))           respF     <- mkFIFO;
  Reg#(Bit#(na))            aReg      <- mkReg(0);
  Reg#(Bit#(nd))            wdReg     <- mkReg(0);
  Reg#(Bool)                isRead    <- mkReg(True);
  Reg#(Bool)                ceReg     <- mkReg(False);
  Reg#(Bool)                oeReg     <- mkReg(False);
  Reg#(Bool)                weReg     <- mkReg(False);
  Reg#(Bool)                tsOE      <- mkReg(False);
  Reg#(Bit#(nd))            tsWD      <- mkReg(0);
  Reg#(Bit#(nd))            tmpWD     <- mkReg(0);
  Reg#(Bool)                waitReg   <- mkRegU;
  TriState#(Bit#(nd))       tsd       <- mkTriState(tsOE, tsWD);

  Stmt rseq = seq     // Flash Read Access Sequence...
    ceReg  <= True;     // Assert CE
    oeReg  <= True;     // Assert OE
    delay(15);          // Wait Access Time
    respF.enq(tsd);     // Capture Read Data
    oeReg  <= False;    // DeAssert OE
    ceReg  <= False;    // DeAssert CE 
  endseq;
  FSM rseqFsm <- mkFSMWithPred(rseq, isRead);

  Stmt wseq = seq     // Flash Write Access Sequence...
    tsWD   <= extend(8'h40);  // Word Program Setup 
    ceReg  <= True;           // Assert CE
    tsOE   <= True;           // Assert Write Data
    weReg  <= True;           // Assert Write Enable
    delay(7);                 // Satisfy 50 nS we# pulse width
    weReg  <= False;          // DeAssert Write Enable
    ceReg  <= False;          // DeAssert CE 
    delay(1);                 // Satisfy 17 nS min ce# high
    tsWD   <= tmpWD;          // Apply Write Data
    ceReg  <= True;           // Assert CE
    weReg  <= True;           // Assert Write Enable
    delay(7);                 // Satisfy 50 nS we# pulse width
    weReg  <= False;          // DeAssert Write Enable
    ceReg  <= False;          // DeAssert CE 
    tsOE   <= False;          // DeAssert Write Data
    delay(1);                 // Satisfy 17 nS min ce# high
                              // Read Array Command to finish write cycle
    ceReg  <= True;           // Assert CE
    oeReg  <= True;           // Assert OE
    delay(7);                 // Wait Access Time
    oeReg  <= False;          // DeAssert OE
    ceReg  <= False;          // DeAssert CE 
  endseq;
  FSM wseqFsm <- mkFSMWithPred(wseq, !isRead);

  // Allow a new request to begin only when a prior one is not active...
  rule nextRequest (rseqFsm.done && wseqFsm.done);
    let r = reqF.first; reqF.deq();  // pop the request
    aReg    <= r.addr;               // flash address
    tmpWD   <= r.data;               // flash write data
    isRead  <= r.isRead;             // set the read/write bit
    let start_access <- (r.isRead) ? rseqFsm.start : wseqFsm.start;
  endrule

  interface FLASH_IO flash;
    interface Inout io_dq    =  tsd.io;
    method  Bit#(na)  addr   =  aReg;
    method  Bool      ce_n   =  !ceReg;
    method  Bool      oe_n   =  !oeReg;
    method  Bool      we_n   =  !weReg;
    method  Bool      wp_n   =  True;
    method  Bool      rst_n  =  True;
    method  Bool      adv_n  =  False;  // Low allows address to pass-through
    method  Action    fwait (Bool i); 
      waitReg <= i;
    endmethod
  endinterface
  interface FLASH_USR user;
    interface Put  request      = toPut(reqF);
    interface Get  response     = toGet(respF);
    method    Bool waitBit      = waitReg;
  endinterface
endmodule: mkFlashController

typedef FlashControllerIfc#(24,16) FlashController2416Ifc;
(* synthesize *) module mkFlashController2416 (FlashController2416Ifc);
  FlashController2416Ifc _a <- mkFlashController; return _a;
endmodule

endpackage: Flash
