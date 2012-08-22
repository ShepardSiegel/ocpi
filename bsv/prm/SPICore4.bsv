// SPICore4.bsv - Single Thread SPI Engine that can address different formats of SPI
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package SPICore4;

import AlignedFIFOs ::*;
import Clocks       ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import Vector       ::*;

// Four Specific SPI targets
typedef enum {
  CDC      = 2'b00,  // (e.g. CDCE72010) 4b Addr, 28b Data, LSB First
  DAC      = 2'b01,  // (e.g. DAC3283)   8b Addr,  8b Data, MSB First
  ADC      = 2'b10,  // (e.g. ADC62P49)  8b Addr,  8b Data, MSB First
  MON      = 2'b11   // (e.g. AMC7823)  16b Addr, 16b Data, MSB First
} SpiTarget deriving (Bits, Eq);

typedef struct {
  SpiTarget  dev;
  Bool       isRead;
  Bit#(16)   addr;
  Bit#(32)   data;
} Spi4Req deriving(Bits, Eq);

(* always_enabled, always_ready *)
interface SPI4Pads;
  method Clock   sclk;
  method Clock   sclkn;
  method Reset   srst;
  method Bit#(1) sdo;
  method Bit#(4) csb;
  method Action  sdi (Bit#(4) arg);
endinterface

interface Spi4Ifc;
  method Put#(Spi4Req)  req;
  method Get#(Bit#(32)) resp;
  interface SPI4Pads    pads;
endinterface: Spi4Ifc 

module mkSpi4 (Spi4Ifc);
  ClockDividerIfc             cd        <- mkClockDivider(8);  // 125MHz/8 = 15.62 MHz
  ClockDividerIfc             cinv      <- mkClockInverter(clocked_by cd.slowClock);
  Reset                       fastReset <- exposeCurrentReset;
  Reset                       slowReset <- mkAsyncResetFromCR(2, cd.slowClock);
  Store#(UInt#(0),Spi4Req,0)  reqS      <- mkRegStore(cd.fastClock, cd.slowClock);
  AlignedFIFO#(Spi4Req)       reqF      <- mkAlignedFIFO(cd.fastClock,fastReset,cd.slowClock,slowReset,reqS,cd.clockReady,True);
  Store#(UInt#(0),Bit#(32),0) respS     <- mkRegStore(cd.slowClock, cd.fastClock);
  AlignedFIFO#(Bit#(32))      respF     <- mkAlignedFIFO(cd.slowClock,slowReset,cd.fastClock,fastReset,respS,True,cd.clockReady);
  Reg#(Bool)                  xmt_i     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                  xmt_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                  rcv_d     <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(5))              iPos      <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(6))              dPos      <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);
  Reg#(UInt#(6))              rPos      <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                  lsbFirst  <- mkReg(False,      clocked_by cd.slowClock, reset_by slowReset);
  Vector#(32,Reg#(Bit#(1)))   cap       <- replicateM(mkRegU(clocked_by cd.slowClock, reset_by slowReset));
  Reg#(Bit#(1))               sdoR      <- mkReg(1'b0,       clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(4))               csbR      <- mkDReg('1,        clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bool)                  doResp    <- mkDReg(False,     clocked_by cd.slowClock, reset_by slowReset);
  Reg#(Bit#(4))               sdiP      <- mkRegU(clocked_by cinv.slowClock);       // sample falling edge internal
  ReadOnly#(Bit#(4))          sdiWs     <- mkNullCrossingWire(cd.slowClock, sdiP);  // cross to slow
  Reg#(Bit#(2))               devId     <- mkRegU(           clocked_by cd.slowClock, reset_by slowReset);

(* descending_urgency = "send_d, send_i, start_cs" *)

  rule start_cs (!xmt_i && !xmt_d && !rcv_d);
    let req = reqF.first;
    xmt_i <= True;
    case (req.dev)
      CDC: begin devId<=pack(req.dev); lsbFirst<=True;  iPos<= 3;  dPos<=27; rPos<=32; end
      DAC: begin devId<=pack(req.dev); lsbFirst<=False; iPos<= 7;  dPos<= 7; rPos<= 0; end
      ADC: begin devId<=pack(req.dev); lsbFirst<=False; iPos<= 7;  dPos<= 7; rPos<= 0; end
      MON: begin devId<=pack(req.dev); lsbFirst<=False; iPos<=15;  dPos<=15; rPos<= 0; end
    endcase
  endrule

  rule send_i (xmt_i);
    let req = reqF.first;
    case (req.dev)
      CDC: begin
             csbR  <= 4'b1110; // Assert during instruction cycles
             sdoR  <= req.addr[4-iPos];  // 4b Addr
           end
      DAC: begin
             csbR  <= 4'b1101; // Assert during instruction cycles
             sdoR <= req.addr[iPos];  // 8b Instruction
           end
      ADC: begin
             csbR  <= 4'b1011; // Assert during instruction cycles
             sdoR <= req.addr[iPos];  // 8b Instruction
           end
      MON: begin
             csbR  <= 4'b0111; // Assert during instruction cycles
             if      (iPos==15) sdoR <= pack(req.isRead);   // Read vs Write
             else if (iPos==14 || iPos==13) sdoR <= 1'b0;   // 1 Byte Transfer
             else if (iPos>= 7 && iPos<=12) sdoR <= 1'b0;   // Zero address bits [12:7]
             else     sdoR <= req.addr[iPos];               // The request address
           end
    endcase
    iPos  <= (iPos==0) ? 0 : iPos - 1;
    xmt_i <= (iPos!=0);
    xmt_d <= (iPos==0);
  endrule

  rule send_d (xmt_d);
    let req = reqF.first;
    case (req.dev)
      CDC: begin
             csbR  <= 4'b1110; // Assert during instruction cycles
             sdoR  <= req.data[27-dPos];  // Send write data or serial readout command  (LSB FIRST)
             // No Capture here in send phase
           end
      DAC: begin
             csbR  <= 4'b1101; // Assert during instruction cycles
             sdoR  <= req.data[dPos];     // Send write data or serial readout command (MSB First)
             cap[dPos] <= sdiWs[1];       // Capture SDI off of sdiP flop on other edge
           end
      ADC: begin
             csbR  <= 4'b1011; // Assert during instruction cycles
             sdoR  <= req.data[dPos];     // Send write data or serial readout command (MSB First)
             cap[dPos] <= sdiWs[2];       // Capture SDI off of sdiP flop on other edge
           end
      MON: begin
             csbR  <= 4'b0111; // Assert during instruction cycles
             sdoR  <= req.data[dPos];     // Send write data or serial readout command (MSB First)
             cap[dPos] <= sdiWs[3];       // Capture SDI off of sdiP flop on other edge
           end
    endcase
    dPos  <= (dPos==0) ? 0 : dPos - 1; 
    if (dPos==0) begin
      if (req.dev!=CDC) begin  // done if not CDC
        doResp <= req.isRead;
        reqF.deq;
      end else begin
        rcv_d <= True;
      end
    xmt_d  <= False;
    end
  endrule

  rule recv_d (rcv_d);
    let req = reqF.first;
    case (req.dev)
      CDC: begin
             csbR  <= (rPos==32) ? '1 : 4'b1110;  // One cycle de-assert pulse
             cap[31-rPos] <= sdiWs[0];     // Capture SDI off of sdiP flop on other edge (LSB FIRST)
           end
    endcase
    rPos  <= (rPos==0) ? 0 : rPos - 1; 
    if (rPos==0) begin
      doResp <= req.isRead;
      reqF.deq;
      rcv_d  <= False;
    end
  endrule

  rule rd_resp (doResp);
    Bit#(32) respData = { cap[30],cap[29],cap[28],cap[27],cap[26],cap[25],cap[24],cap[23],
                          cap[22],cap[21],cap[20],cap[19],cap[18],cap[17],cap[16],cap[15],
                          cap[14],cap[13],cap[12],cap[11],cap[10],cap[9],cap[8],cap[7],
                          cap[6],cap[5],cap[4],cap[3],cap[2],cap[1],cap[0],sdiWs[devId]};
    respF.enq(respData);
  endrule

  interface req  = toPut(reqF);
  interface resp = toGet(respF);

  interface SPI4Pads pads;
    method Clock   sclk  = cd.slowClock;
    method Clock   sclkn = cinv.slowClock;
    method Reset   srst  = slowReset;
    method Bit#(1) sdo   = sdoR;
    method Bit#(4) csb   = csbR;
    method Action  sdi (Bit#(4) arg) = sdiP._write(arg);
  endinterface

endmodule: mkSpi4 

endpackage: SPICore4
