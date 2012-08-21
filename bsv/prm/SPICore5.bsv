// SPICore5.bsv - SPI Master specialized for the TI-Style 5b Addr 8b Data (e.g. TI DAC3283)
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package SPICore5;

import AlignedFIFOs ::*;
import Clocks       ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import Vector       ::*;

typedef struct {
  Bool       isRead;
  Bit#(5)    addr;
  Bit#(8)    data;
} Spi5Req deriving(Bits, Eq);

(* always_enabled, always_ready *)
interface SPI5Pads;
  method Clock   sclk;
  method Clock   sclkn;
  method Reset   srst;
  method Bit#(1) sdo;
  method Bit#(1) csb;
  method Bit#(1) sclkgate;
  method Action  sdi (Bit#(1) arg);
endinterface

interface Spi5Ifc;
  method Put#(Spi5Req)  req;
  method Get#(Bit#(8))  resp;
  interface SPI5Pads    pads;
endinterface: Spi5Ifc 

module mkSpi5 (Spi5Ifc);
  ClockDividerIfc              cd        <- mkClockDivider(16);  // 125MHz/16 = 7.8 MHz ~ 128 nS Period
  ClockDividerIfc              cinv      <- mkClockInverter(clocked_by cd.slowClock);
  Reset                        fastReset <- exposeCurrentReset;
  Reset                        slowReset <- mkAsyncResetFromCR(2, cd.slowClock);
  Store#(UInt#(0),Spi5Req,0)   reqS      <- mkRegStore(cd.fastClock, cd.slowClock);
  AlignedFIFO#(Spi5Req)        reqF      <- mkAlignedFIFO(cd.fastClock,fastReset,cd.slowClock,slowReset,reqS,cd.clockReady,True);
  Store#(UInt#(0),Bit#(8),0)   respS     <- mkRegStore(cd.slowClock, cd.fastClock);
  AlignedFIFO#(Bit#(8))        respF     <- mkAlignedFIFO(cd.slowClock,slowReset,cd.fastClock,fastReset,respS,True,cd.clockReady);
  Reg#(Bool)                   cGate     <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   xmt_i     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   xcv_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(3))               iPos      <- mkReg(0,          clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(3))               dPos      <- mkReg(0,          clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Vector#(8,(Bit#(1))))   capV      <- mkReg(unpack(0),  clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                sdoR      <- mkReg(1'b0,       clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                csbR      <- mkDReg('1,        clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   doResp    <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                sdiP      <- mkRegU(clocked_by cinv.slowClock);       // sample falling edge internal
  ReadOnly#(Bit#(1))           sdiWs     <- mkNullCrossingWire(cd.slowClock, sdiP);  // cross to slow

(* descending_urgency = "rd_resp, doxcv_d, send_i, start_cs" *)

  rule start_cs (!xmt_i && !xcv_d && !doResp && unpack(csbR));
    let req = reqF.first;
    xmt_i <= True;
    iPos  <= 7;
    dPos  <= 7;
  endrule

  rule send_i (xmt_i && !xcv_d && !doResp);
    let req = reqF.first;
    csbR  <= 1'b0;
    cGate <= True;
    case (iPos)
      7: sdoR <= pack(req.isRead);  // 1=Read; 0=Write
      6: sdoR <= 0; 5: sdoR <= 0;   // Transfer 1 Byte
      4: sdoR<=req.addr[4]; 3: sdoR<=req.addr[3]; 2: sdoR<=req.addr[2]; 1: sdoR<=req.addr[1]; 0: sdoR<=req.addr[0]; // Address
    endcase
    iPos  <= (iPos==0) ? 0 : iPos - 1; 
    xmt_i <= (iPos!=0);
    xcv_d <= (iPos==0);
  endrule

  rule doxcv_d (!xmt_i && xcv_d && !doResp);
    let req = reqF.first;
    csbR  <= 1'b0;
    cGate <= True;
    sdoR  <= req.data[dPos];           // Send the data out, even if this is a read cycle
    capV  <= shiftInAt0(capV, sdiWs);  // Recv the data in,  even if this is a write cycle
    dPos  <= (dPos==0) ? 0 : dPos - 1; 
    if (dPos==0) begin 
      xcv_d  <= False;
      doResp <= req.isRead;
      reqF.deq;
    end
  endrule

  rule rd_resp (doResp);
    doResp <= False;
    respF.enq(pack(shiftInAt0(capV, sdiWs)));
  endrule


  interface req  = toPut(reqF);
  interface resp = toGet(respF);

  interface SPI5Pads pads;
    method Clock   sclk     = cd.slowClock;
    method Clock   sclkn    = cinv.slowClock;
    method Reset   srst     = slowReset;
    method Bit#(1) sdo      = sdoR;
    method Bit#(1) csb      = csbR;
    method Bit#(1) sclkgate = pack(cGate);
    method Action  sdi (Bit#(1) arg) = sdiP._write(arg);
  endinterface

endmodule: mkSpi5

endpackage: SPICore5
