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
  interface Put#(CmpMaybe) putXn;
  //interface Get#(CmpMaybe) getXk;
  interface FIFO#(CmpMaybe) fifoXk;  // Wating for Get Split (GetS?) to be defined and implemented
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
  FIFO#(CmpMaybe)       xnF             <- mkFIFO;
  FIFO#(CmpMaybe)       xkF             <- mkFIFO;

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

  rule fft_stream_ingress (unpack(fft.readyForData) &&& xnF.first matches tagged Valid .xn);
    xnRe_w  <= xn.rel;
    xnIm_w  <= xn.img;
    start_w <= 1;
    xnF.deq;
  endrule

  rule fft_stream_egress (unpack(fft.dataValid));
    let xk = (Valid (Complex{rel:fft.xkRe, img:fft.xkIm}));
    xkF.enq(xk);
  endrule

  interface Put putXn = toPut(xnF);
  //interface Get getXk = toGet(xkF);
  interface FIFO fifoXk = xkF;
endmodule: mkFFT


endpackage: FFT
