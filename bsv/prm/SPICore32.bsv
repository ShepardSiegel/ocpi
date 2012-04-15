// SPICore32.bsv - SPI Master specialized for the TI-style 28b data, 4b addr (e.g. CDCE72010)
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package SPICore32;

import AlignedFIFOs ::*;
import Clocks       ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import Vector       ::*;

typedef struct {
  Bool       isRead;
  Bit#(4)    addr;
  Bit#(28)   data;
} Spi32Req deriving(Bits, Eq);

(* always_enabled, always_ready *)
interface SPI32Pads;
  method Clock   sclk;
  method Clock   sclkn;
  method Reset   srst;
  method Bit#(1) sdo;
  method Bit#(1) csb;
  method Bit#(1) sclkgate;
  method Action  sdi (Bit#(1) arg);
endinterface

interface Spi32Ifc;
  method Put#(Spi32Req)  req;
  method Get#(Bit#(28))  resp;
  interface SPI32Pads    pads;
endinterface: Spi32Ifc 

module mkSpi32 (Spi32Ifc);
  ClockDividerIfc              cd        <- mkClockDivider(8);  // 125MHz/8 = 15.62 MHz
  ClockDividerIfc              cinv      <- mkClockInverter(clocked_by cd.slowClock);
  Reset                        fastReset <- exposeCurrentReset;
  Reset                        slowReset <- mkAsyncResetFromCR(2, cd.slowClock);
  Store#(UInt#(0),Spi32Req,0)  reqS      <- mkRegStore(cd.fastClock, cd.slowClock);
  AlignedFIFO#(Spi32Req)       reqF      <- mkAlignedFIFO(cd.fastClock,fastReset,cd.slowClock,slowReset,reqS,cd.clockReady,True);
  Store#(UInt#(0),Bit#(28),0)  respS     <- mkRegStore(cd.slowClock, cd.fastClock);
  AlignedFIFO#(Bit#(28))       respF     <- mkAlignedFIFO(cd.slowClock,slowReset,cd.fastClock,fastReset,respS,True,cd.clockReady);
  Reg#(Bool)                   cGate     <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   xmt_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   rcv_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(5))               dPos      <- mkReg(0,          clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(6))               rPos      <- mkReg(0,          clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Vector#(28,(Bit#(1))))  capV      <- mkReg(unpack(0),  clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                sdoR      <- mkReg(1'b0,       clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                csbR      <- mkDReg('1,        clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                   doResp    <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(1))                sdiP      <- mkRegU(clocked_by cinv.slowClock);       // sample falling edge internal
  ReadOnly#(Bit#(1))           sdiWs     <- mkNullCrossingWire(cd.slowClock, sdiP);  // cross to slow

(* descending_urgency = "rd_resp, recv_d, send_d, start_cs" *)

  rule start_cs (!xmt_d && !rcv_d && !doResp);
    let req = reqF.first;
    xmt_d <= True;
    dPos  <= 31;
    rPos  <= (req.isRead) ? 32 : 0;  // rPos cycles have 1 csb de-assert + 32 read-capture
  endrule


  rule send_d (xmt_d && !rcv_d && !doResp);
    let req = reqF.first;
    csbR  <= 1'b0;
    cGate <= True;
    if (req.isRead)
      case (31-dPos)
        0:sdoR<=0; 1:sdoR<=1; 2:sdoR<=1; 3: sdoR<=1;  // 0xE (14) Read Command
        4:sdoR<=req.addr[0]; 5:sdoR<=req.addr[1]; 6:sdoR<=req.addr[2]; 7: sdoR<=req.addr[3];  // Addr for read
        default: sdoR <= 0;
      endcase
    else
      case (31-dPos)
        0:sdoR<=req.addr[0]; 1:sdoR<=req.addr[1]; 2:sdoR<=req.addr[2]; 3: sdoR<=req.addr[3];  // Addr for write
        default: sdoR  <= req.data[27-dPos];  // lsb first
      endcase
    dPos  <= (dPos==0) ? 0 : dPos - 1; 
    if (dPos==0) begin 
      xmt_d  <= False;
      rcv_d  <= (req.isRead);
      reqF.deq;
    end
  endrule

  rule recv_d (!xmt_d && rcv_d && !doResp);
    cGate <= (rPos!=32);      // Diable clock when csb/LE de-asserted
    csbR  <= pack(rPos==32);  // One cycle de-assert pulse
    capV  <= shiftInAtN(capV, sdiWs);
    rPos  <= (rPos==0) ? 0 : rPos - 1; 
    if (rPos==0) begin
      doResp <= True;
      rcv_d  <= False;
    end
  endrule

  rule rd_resp (!xmt_d && !rcv_d && doResp);
    doResp <= False;
    respF.enq(pack(shiftInAtN(capV, sdiWs)));
  endrule


  interface req  = toPut(reqF);
  interface resp = toGet(respF);

  interface SPI32Pads pads;
    method Clock   sclk     = cd.slowClock;
    method Clock   sclkn    = cinv.slowClock;
    method Reset   srst     = slowReset;
    method Bit#(1) sdo      = sdoR;
    method Bit#(1) csb      = csbR;
    method Bit#(1) sclkgate = pack(cGate);
    method Action  sdi (Bit#(1) arg) = sdiP._write(arg);
  endinterface

endmodule: mkSpi32

endpackage: SPICore32
