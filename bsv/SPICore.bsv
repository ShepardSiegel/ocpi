// SPICore.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package SPICore;

import AlignedFIFOs::*;
import Clocks::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import Vector::*;

typedef struct {
  Bool    rdCmd;
  Bit#(8) addr;
  Bit#(8) wdata;
} SpiReq deriving(Bits, Eq);

interface SpiIfc;
  method Put#(SpiReq)  req;
  method Get#(Bit#(8)) resp;
  method Clock         sclk;
  method Clock         sclkn;
  method Reset         srst;
  (*always_ready*) method Bit#(1) csb;
  (*always_ready*) method Bit#(1) sdo;
  (*always_ready, always_enabled*) method Action sdi (Bit#(1) arg);
endinterface: SpiIfc 

// Basic SPI core, for long (16b) or short(8b) instruction...
module mkSpi#(Bool longInst) (SpiIfc);
  ClockDividerIfc            cd        <- mkClockDivider(8);  // 125MHz/8 = 15.62 MHz
  ClockDividerIfc            cinv      <- mkClockInverter(clocked_by cd.slowClock);
  Reset                      fastReset <- exposeCurrentReset;
  Reset                      slowReset <- mkAsyncResetFromCR(2, cd.slowClock);
  Store#(UInt#(0),SpiReq,0)  reqS      <- mkRegStore(cd.fastClock, cd.slowClock);
  AlignedFIFO#(SpiReq)       reqF      <- mkAlignedFIFO(cd.fastClock,fastReset,cd.slowClock,slowReset,reqS,cd.clockReady,True);
  Store#(UInt#(0),Bit#(8),0) respS     <- mkRegStore(cd.slowClock, cd.fastClock);
  AlignedFIFO#(Bit#(8))      respF     <- mkAlignedFIFO(cd.slowClock,slowReset,cd.fastClock,fastReset,respS,True,cd.clockReady);
  Reg#(Bool)                 xmt_i     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                 xmt_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(4))              iPos      <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(3))              dPos      <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);
  Vector#(8,Reg#(Bit#(1)))   cap       <- replicateM(mkRegU(clocked_by cd.slowClock, reset_by slowReset));
  Reg#(Bit#(1))              sdoR      <- mkReg(1'b0,       clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))              csbR      <- mkDReg(1'b1,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                 doResp    <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))              sdiP      <- mkRegU(clocked_by cinv.slowClock);       // sample falling edge internal
  ReadOnly#(Bit#(1))         sdiWs     <- mkNullCrossingWire(cd.slowClock, sdiP);  // cross to slow

(* descending_urgency = "send_d, send_i, start_cs" *)

  rule start_cs (reqF.dNotEmpty && !xmt_i && !xmt_d);
    xmt_i <= True;
    iPos  <= (longInst) ? 4'hF : 4'h7;
    dPos  <= 3'h7;
  endrule

  rule send_i (xmt_i);
    let req = reqF.first;
    csbR  <= 1'b0; // Assert during instruction cycles
    if (longInst) begin
      if      (iPos==15) sdoR <= pack(req.rdCmd);   // Read vs Write
      else if (iPos==14 || iPos==13) sdoR <= 1'b0;  // 1 Byte Transfer
      else if (iPos>= 7 && iPos<=12) sdoR <= 1'b0;  // Zero address bits [12:7]
      else     sdoR <= req.addr[iPos];              // The request address
    end else sdoR <= req.addr[iPos];  // 8b Instruction
    iPos  <= (iPos==0) ? '0 : iPos - 1;
    xmt_i <= iPos!=0;
    xmt_d <= iPos==0;
  endrule

  rule send_d (xmt_d);
    let req = reqF.first;
    csbR      <= 1'b0;            // Assert during data cycles
    sdoR      <= req.wdata[dPos]; // Send write data or serial readout command
    cap[dPos] <= sdiWs;           // Capture SDI off of sdiP flop on other edge
    dPos  <= (dPos==0) ? '0 : dPos - 1; 
    if (dPos==0) begin
      doResp <= req.rdCmd;
      xmt_d  <= False;
      reqF.deq;
    end
  endrule

  rule rd_resp (doResp);
    Bit#(8) respData = {cap[6],cap[5],cap[4],cap[3],cap[2],cap[1],cap[0],sdiWs};
    respF.enq(respData);
  endrule

  interface req  = toPut(reqF);
  interface resp = toGet(respF);
  method Bit#(1) csb = csbR;
  method Bit#(1) sdo = sdoR;
  method Action  sdi (Bit#(1) arg) = sdiP._write(arg);
  method Clock   sclk  = cd.slowClock;
  method Reset   srst  = slowReset;
  method Clock   sclkn = cinv.slowClock;
endmodule: mkSpi 

endpackage: SPICore
