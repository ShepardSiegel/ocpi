// FFT.bsv - BSV Wrapper for Vendor FFT Primatives
// Copyright (c) 2010  Atomic Rules LCC ALL RIGHTS RESERVED

package FFT;

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
interface FFTvIfc;
  method Action   fwd      (Bit#(1)  i);
  method Action   fwd_we   (Bit#(1)  i);
  method Action   scale    (Bit#(12) i);
  method Action   scale_we (Bit#(1)  i);
  method Action   start    (Bit#(1)  i);
  method Bit#(1)  readyForData;
  method Bit#(1)  dataValid;
  method Bit#(1)  edone;
  method Bit#(1)  done;
  method Bit#(1)  busy;
  method Action   xnRe    (Bit#(16) i);
  method Action   xnIm    (Bit#(16) i);
  method Bit#(12) xnIndex;
  method Bit#(16) xkRe;
  method Bit#(16) xkIm;
  method Bit#(12) xkIndex;
endinterface: FFTvIfc

interface FFTIfc;
  interface Put#(Cmp16)  putXn;
  //interface Get#(Cmp16) getXk;
  interface FIFO#(Cmp16) fifoXk;  // Wating for Get Split (GetS?) to be defined and implemented
  method Bit#(32) fftFrameCounts;
endinterface: FFTIfc


import "BVI" xfft_v7_1 = 
module vMkFFT (FFTvIfc);

  default_clock clk   (clk);
  default_reset rst_n (); 

  // Action methods methodName (VerilogPort)...
  method fwd      (fwd_inv)       enable((*inhigh*)ena1);
  method fwd_we   (fwd_inv_we)    enable((*inhigh*)ena2);
  method scale    (scale_sch)     enable((*inhigh*)ena3);
  method scale_we (scale_sch_we)  enable((*inhigh*)ena4);
  method start    (start)         enable((*inhigh*)ena5);
  method xnRe     (xn_re)         enable((*inhigh*)ena6);
  method xnIm     (xn_im)         enable((*inhigh*)ena7);
  // Value methods verilogPort methodName...
  method rfd      readyForData;
  method dv       dataValid;
  method edone    edone;
  method done     done;
  method busy     busy;
  method xn_index xnIndex;
  method xk_re    xkRe;
  method xk_im    xkIm;
  method xk_index xkIndex;

  schedule
    (fwd, fwd_we, scale, scale_we, start, xnRe, xnIm, readyForData, dataValid, edone, done, busy, xnIndex, xkRe, xkIm,  xkIndex)
    CF
    (fwd, fwd_we, scale, scale_we, start, xnRe, xnIm, readyForData, dataValid, edone, done, busy, xnIndex, xkRe, xkIm,  xkIndex);

endmodule: vMkFFT


module mkFFT (FFTIfc);
  FFTvIfc               fft             <- vMkFFT;
  FIFOF#(Cmp16)         xnF             <- mkFIFOF;
  FIFO#(Cmp16)          xkF             <- mkFIFO;
  Reg#(Bool)            fftStarted      <- mkReg(False);
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
  rule drive_fft_always_enabled (True);
    fft.fwd      (fwd_w);
    fft.fwd_we   (fwd_we_w);
    fft.scale    (scale_w);
    fft.scale_we (scale_we_w);
    fft.start    (start_w);
    fft.xnRe     (xnRe_w);
    fft.xnIm     (xnIm_w);
  endrule

  rule frame_start (xnF.notEmpty && !fftStarted);
    start_w    <= 1;
    fftStarted <= True;
  endrule

  rule fft_stream_ingress (unpack(fft.readyForData) && fftStarted);
    xnRe_w  <= xnF.first.rel;
    xnIm_w  <= xnF.first.img;
    xnF.deq;
    Bool endOfLoad = (loadIndex==4095); // hardcoded 4K
    loadIndex <= (endOfLoad) ? 0 : loadIndex + 1;
    if (endOfLoad) begin
      loadFrames <= loadFrames + 1;
      fftStarted <= False;
    end
  endrule

  rule fft_stream_egress (unpack(fft.dataValid));
    let xk = (Complex{rel:fft.xkRe, img:fft.xkIm});
    xkF.enq(xk);
    Bool endOfUnload = (unloadIndex==4095); // hardcoded 4K
    unloadIndex <= (endOfUnload) ? 0 : unloadIndex + 1;
    if (endOfUnload) unloadFrames <= unloadFrames + 1;
  endrule

  interface Put putXn = toPut(xnF);
  //interface Get getXk = toGet(xkF);
  interface FIFO fifoXk = xkF;
  method Bit#(32) fftFrameCounts = {pack(loadFrames),pack(unloadFrames)};
endmodule: mkFFT


endpackage: FFT
