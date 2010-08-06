// DDC.bsv - BSV Wrapper for Vendor DDC Primatives
// Copyright (c) 2010  Atomic Rules LCC ALL RIGHTS RESERVED

package DDC;

import Clocks          ::*;
import Complex         ::*;
import ClientServer    ::*;
import Connectable     ::*;
import FIFO            ::*;
import FIFOF           ::*;
import FixedPoint      ::*;
import GetPut          ::*;
import SpecialFIFOs    ::*;
import Vector          ::*;
import XilinxCells     ::*;

typedef Complex#(Bit#(16))         Cmp16;
typedef Maybe#(Complex#(Bit#(16))) CmpMaybe;

// Interfaces...

(* always_enabled, always_ready *)
interface DDCvIfc;
  method Action   sDataValid (Bit#(1)  i);
  method Bit#(1)  sDataReady;
  method Action   sDataR     (Bit#(1)  i);
  method Action   mDataReady (Bit#(1)  i);
  method Bit#(1)  mDataValid;
  method Bit#(1)  mDataLast;
  method Bit#(1)  mDataClean;
  method Bit#(16) mDataI;
  method Bit#(16) mDataQ;
  method Action  
  method Action   sRegPresetn  (Bit#(1)  i);
	method Action   sRegPaddr    (Bit#(1)  i);
	method Action   sRegPsel     (Bit#(1)  i);
	method Action   sRegPenable  (Bit#(1)  i);
	method Action   sRegPwrite   (Bit#(1)  i);
	method Action   sRegPwdata   (Bit#(32) i);
	method Bit#(1)  sRegPready;
	method Bit#(32) sRegPrdata   (Bit#(1)  i);
	method Bit#(1)  sRegPslverr  (Bit#(1)  i);
	method Bit#(1)  intMissinput;
	method Bit#(1)  intErrpacket;
	method Bit#(1)  intLostoutput;
	method Bit#(1)  intDucddc;
endinterface: DDCvIfc

interface DDCIfc;
  interface Put#(Cmp16)  putXn;
  //interface Get#(Cmp16) getXk;
  interface FIFO#(Cmp16) fifoXk;  // Wating for Get Split (GetS?) to be defined and implemented
  method Bit#(32) ddcFrameCounts;
endinterface: DDCIfc


import "BVI" duc_ddc_compiler_v1_0 = 
module vMkDDC (DDCvIfc);

  default_clock clk   (clk);
  default_reset rst_n (data_resetn); 

  // Action methods methodName (VerilogPort) enable()...
  // Value methods verilogPort methodName...

  method sdata        (sdata_r)       enable((*inhigh*)ena1);
  method sdata_val    (sdata_valid)   enable((*inhigh*)ena2);
  method sdata_ready  sdata_rdy;


  schedule
    (fwd, fwd_we, scale, scale_we, start, xnRe, xnIm, readyForData, dataValid, edone, done, busy, xnIndex, xkRe, xkIm,  xkIndex)
    CF
    (fwd, fwd_we, scale, scale_we, start, xnRe, xnIm, readyForData, dataValid, edone, done, busy, xnIndex, xkRe, xkIm,  xkIndex);

endmodule: vMkDDC


module mkDDC (DDCIfc);
  DDCvIfc               ddc             <- vMkDDC;
  FIFOF#(Cmp16)         xnF             <- mkFIFOF;
  FIFO#(Cmp16)          xkF             <- mkFIFO;
  Reg#(Bool)            ddcStarted      <- mkReg(False);
  Reg#(UInt#(16))       loadIndex       <- mkReg(0);
  Reg#(UInt#(16))       loadFrames      <- mkReg(0);
  Reg#(UInt#(16))       unloadIndex     <- mkReg(0);
  Reg#(UInt#(16))       unloadFrames    <- mkReg(0);

  Wire#(Bit#(1))        fwd_w           <- mkDWire(0);
  Wire#(Bit#(1))        fwd_we_w        <- mkDWire(0);
  Wire#(Bit#(12))       scale_w         <- mkDWire(0);
  Wire#(Bit#(1))        scale_we_w      <- mkDWire(0);
  Wire#(Bit#(1))        start_w         <- mkDWire(0);
  Wire#(Bit#(16))       xnRe_w          <- mkDWire(0);
  Wire#(Bit#(16))       xnIm_w          <- mkDWire(0);

  // Since these methods are always-enabled by *inhigh*, drive them at all times to satisfy always_enabled assertion...
  (*  fire_when_enabled, no_implicit_conditions *)
  rule drive_ddc_always_enabled (True);
    ddc.fwd      (fwd_w);
    ddc.fwd_we   (fwd_we_w);
    ddc.scale    (scale_w);
    ddc.scale_we (scale_we_w);
    ddc.start    (start_w);
    ddc.xnRe     (xnRe_w);
    ddc.xnIm     (xnIm_w);
  endrule

  rule frame_start (xnF.notEmpty && !ddcStarted);
    start_w    <= 1; 
    ddcStarted <= True;
  endrule

 // rule drive_start (ddcStarted);
 //   start_w   <= 1; 
 // endrule

  rule ddc_stream_ingress (unpack(ddc.readyForData) && ddcStarted);
    xnRe_w    <= xnF.first.rel;
    xnIm_w    <= xnF.first.img;
    xnF.deq;
    Bool endOfLoad = (loadIndex==4095); // hardcoded 4K
    loadIndex <= (endOfLoad) ? 0 : loadIndex + 1;
    if (endOfLoad) begin
      loadFrames <= loadFrames + 1;
      ddcStarted <= False;
    end
  endrule

  rule ddc_stream_egress (unpack(ddc.dataValid));
    let xk = (Complex{rel:ddc.xkRe, img:ddc.xkIm});
    xkF.enq(xk);
    Bool endOfUnload = (unloadIndex==4095); // hardcoded 4K
    unloadIndex <= (endOfUnload) ? 0 : unloadIndex + 1;
    if (endOfUnload) unloadFrames <= unloadFrames + 1;
  endrule

  interface Put putXn = toPut(xnF);
  //interface Get getXk = toGet(xkF);
  interface FIFO fifoXk = xkF;
  method Bit#(32) ddcFrameCounts = {pack(loadFrames),pack(unloadFrames)};
endmodule: mkDDC


endpackage: DDC
