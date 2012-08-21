// WsiToPrecise - Convert a (possibly) imprecise WSI input stream to a precise stream
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Alias::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;

interface WsiToPreciseGPIfc#(numeric type ndw);
  method Action operate;
  method Action setWordsExact (UInt#(16) i);
  interface Put#(WsiReq#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)) putWsi;
  interface Get#(WsiReq#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)) getWsi;
endinterface 

module mkWsiToPreciseGP (WsiToPreciseGPIfc#(ndw))
  provisos ( DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)) );

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  FIFOF#(WsiReq#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)) inF  <- mkFIFOF;
  FIFOF#(WsiReq#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)) outF <- mkFIFOF;
  FIFOF#(Bit#(nd))               dataF             <- mkSizedBRAMFIFOF(2048);  // MUST be sized large enough for imprecise->precise conversion!
  FIFOF#(Bit#(8))                reqF              <- mkFIFOF;
  Reg#(UInt#(16))                wordsExact        <- mkReg(2048);
  Reg#(UInt#(16))                wordsEnqued       <- mkReg(0);
  Reg#(UInt#(16))                wordsDequed       <- mkReg(0);
  Wire#(Bool)                    operateW          <- mkDWire(False);

  rule imprecise_enq (operateW);
    let w = inF.first; inF.deq;
    dataF.enq(w.data);
    if (wordsEnqued==wordsExact-1) begin
      reqF.enq(w.reqInfo);                     // Enq the reqInfo to signal full message available
      wordsEnqued <= 0;
    end else wordsEnqued <= wordsEnqued + 1;
  endrule
  
  rule precise_deq (operateW && reqF.notEmpty); // Only start DEQ when we have a complete, exact message
    outF.enq (WsiReq    {cmd  : WR ,
                      reqLast : (wordsDequed==wordsExact-1),
                      reqInfo : reqF.first,
                 burstPrecise : True,
                  burstLength : truncate(pack(wordsExact)),
                        data  : dataF.first,
                      byteEn  : '1,
                    dataInfo  : '0 });
    dataF.deq;
    if (wordsDequed==wordsExact-1) begin
      reqF.deq;
      wordsDequed <= 0;
    end else wordsDequed <= wordsDequed + 1;
  endrule
  
  method Action operate = operateW._write(True);
  method Action setWordsExact (UInt#(16) i) = wordsExact._write(i);
  interface Put putWsi = toPut(inF);
  interface Get getWsi = toGet(outF);
endmodule


// Embellished version with WIP Interfaces...

interface WsiToPreciseIfc#(numeric type ndw);
  method Action operate;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiS0;
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiM0;
endinterface 

module mkWsiToPrecise (WsiToPreciseIfc#(ndw))
  provisos ( DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)) );

  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS       <- mkWsiSlave;         // Convienience IP for WSI Slave
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM       <- mkWsiMaster;        // Convienience IP for WSI Master
  WsiToPreciseGPIfc#(ndw)        w2p        <- mkWsiToPreciseGP;   // Instance a GetPut version of WsiToPrecise
  Wire#(Bool)                    operateW   <- mkDWire(False);

  rule operating_actions (operateW); wsiM.operate(); wsiS.operate(); w2p.operate(); endrule

  mkConnection(wsiS.reqGet, w2p.putWsi); 
  mkConnection(w2p.getWsi, wsiM.reqPut); 

  Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsi_Es <- mkWsiStoES(wsiS.slv);

  method Action operate = operateW._write(True);
  interface wsiS0 = wsi_Es;
  interface wsiM0 = toWsiEM(wsiM.mas); 
endmodule


// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiToPreciseIfc#(1) WsiToPrecise4BIfc;
//(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise4B (WsiToPrecise4BIfc);
  WsiToPrecise4BIfc _a <- mkWsiToPrecise(); return _a;
endmodule

typedef WsiToPreciseIfc#(2) WsiToPrecise8BIfc;
//(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise8B (WsiToPrecise8BIfc);
  WsiToPrecise8BIfc _a <- mkWsiToPrecise(); return _a;
endmodule

typedef WsiToPreciseIfc#(4) WsiToPrecise16BIfc;
//(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise16B (WsiToPrecise16BIfc);
  WsiToPrecise16BIfc _a <- mkWsiToPrecise(); return _a;
endmodule

typedef WsiToPreciseIfc#(8) WsiToPrecise32BIfc;
//(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise32B (WsiToPrecise32BIfc);
  WsiToPrecise32BIfc _a <- mkWsiToPrecise(); return _a;
endmodule

