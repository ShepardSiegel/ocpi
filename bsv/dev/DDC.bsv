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

typedef Complex#(Bit#(16)) Cmp16;

typedef struct {
  Bool      isWrite; // request is a write 
  Bool      isError; // request is a error
  Bit#(na)  addr;    // memory byte address
  Bit#(nd)  data;    // write data
 } AMBA3APBReq#(numeric type na, numeric type nd) deriving (Bits, Eq);

typedef struct {
  Bool      isError; // response is an error
  Bit#(nd)  data;    // read data response
 } AMBA3APBResp#(numeric type nd) deriving (Bits, Eq);

typedef struct {
  Bool missInput;
  Bool errPacket;
  Bool lostOutput;
  Bool ducDdc;
} DdcInt deriving (Bits, Eq);

// Interfaces...

(* always_enabled, always_ready *)
interface DDCvIfc;
  method Action   sDataValid   (Bit#(1)  i);
  method Bit#(1)  sDataReady;
  method Action   sDataR       (Bit#(16) i);
  method Action   mDataReady   (Bit#(1)  i);
  method Bit#(1)  mDataValid;
  method Bit#(1)  mDataLast;
  method Bit#(1)  mDataClean;
  method Bit#(16) mDataI;
  method Bit#(16) mDataQ;
  method Action   dataResetn   (Bit#(1)  i);
	method Action   sRegPaddr    (Bit#(12) i);
	method Action   sRegPsel     (Bit#(1)  i);
	method Action   sRegPenable  (Bit#(1)  i);
	method Action   sRegPwrite   (Bit#(1)  i);
	method Action   sRegPwdata   (Bit#(32) i);
	method Bit#(1)  sRegPready;
	method Bit#(32) sRegPrdata;
	method Bit#(1)  sRegPslverr;
	method Bit#(1)  intMissinput;
	method Bit#(1)  intErrpacket;
	method Bit#(1)  intLostoutput;
	method Bit#(1)  intDucddc;
endinterface: DDCvIfc

interface DDCIfc;
  interface Put#(Bit#(16)) putXn;
  //interface Get#(Cmp16) getXk;
  interface FIFO#(Cmp16)  fifoXk;  // Wating for Get Split (GetS?) to be defined and implemented
  interface Put#(AMBA3APBReq#(12,32))  putApb;
  interface Get#(AMBA3APBResp#(32))    getApb;
  method DdcInt ddcint;
endinterface: DDCIfc

import "BVI" duc_ddc_compiler_v1_0 = 
module vMkDDC (DDCvIfc);

  default_clock clk        (clk);
  default_reset rst_n      (sreg_presetn); 

  // Action methods methodName (VerilogPort) enable()...
  method sDataValid   (sdata_valid)  enable((*inhigh*)en1);
  method sDataR       (sdata_r)      enable((*inhigh*)en2);
  method mDataReady   (mdata_ready)  enable((*inhigh*)en3);
  method dataResetn   (data_resetn)  enable((*inhigh*)en4);
	method sRegPaddr    (sreg_paddr)   enable((*inhigh*)en5);
	method sRegPsel     (sreg_psel)    enable((*inhigh*)en6);
	method sRegPenable  (sreg_penable) enable((*inhigh*)en7);
	method sRegPwrite   (sreg_pwrite)  enable((*inhigh*)en8);
	method sRegPwdata   (sreg_pwdata)  enable((*inhigh*)en9);

  // Value methods verilogPort methodName...
  method  sdata_ready    sDataReady;
  method  mdata_valid    mDataValid;
  method  mdata_last     mDataLast;
  method  mdata_clean    mDataClean;
  method  mdata_i        mDataI;
  method  mdata_q        mDataQ;
	method  sreg_pready    sRegPready;
	method  sreg_prdata    sRegPrdata;
	method  sreg_pslverr   sRegPslverr;
	method  int_missinput  intMissinput;
	method  int_errpacket  intErrpacket;
	method  int_lostoutput intLostoutput;
	method  int_ducddc     intDucddc;

  //TODO: Learn the proper methodology for schedule composition - for now, make everthing conflict-free...
  schedule
  ( sDataValid, sDataReady, sDataR, mDataReady, mDataValid, mDataLast, mDataClean, mDataI, mDataQ, dataResetn, sRegPaddr, sRegPsel, sRegPenable, sRegPwrite, sRegPwdata, sRegPready, sRegPrdata, sRegPslverr, intMissinput, intErrpacket, intLostoutput, intDucddc )
    CF
  ( sDataValid, sDataReady, sDataR, mDataReady, mDataValid, mDataLast, mDataClean, mDataI, mDataQ, dataResetn, sRegPaddr, sRegPsel, sRegPenable, sRegPwrite, sRegPwdata, sRegPready, sRegPrdata, sRegPslverr, intMissinput, intErrpacket, intLostoutput, intDucddc );

endmodule: vMkDDC


module mkDDC (DDCIfc);
  Reset                 rst_n           <- exposeCurrentReset;
  DDCvIfc               ddc             <- vMkDDC;
  FIFOF#(Bit#(16))      xnF             <- mkFIFOF;
  FIFO#(Cmp16)          xkF             <- mkFIFO;
  FIFO#(AMBA3APBReq#(12,32))  apbReqF   <- mkFIFO; 
  FIFO#(AMBA3APBResp#(32))    apbRespF  <- mkFIFO;

  Wire#(Bit#(1))        sDataValid_w    <- mkDWire(0);
  Wire#(Bit#(16))       sDataR_w        <- mkDWire(0);
  Wire#(Bit#(1))        mDataReady_w    <- mkDWire(0);
  Wire#(Bit#(1))        dataResetn_w    <- mkDWire(0);
  Wire#(Bit#(12))       sRegPaddr_w     <- mkDWire(0);
  Wire#(Bit#(1))        sRegPsel_w      <- mkDWire(0);
  Wire#(Bit#(1))        sRegPenable_w   <- mkDWire(0);
  Wire#(Bit#(1))        sRegPwrite_w    <- mkDWire(0);
  Wire#(Bit#(32))       sRegPwdata_w    <- mkDWire(0);

  Reg#(Bool)            started         <- mkReg(False);
  Reg#(Bool)            reqSetup        <- mkReg(False);

  // Since these methods are always-enabled by *inhigh*, drive them at all times to satisfy the always_enabled assertion...
  (*  fire_when_enabled, no_implicit_conditions *)
  rule drive_ddc_always_enabled (True);
    ddc.sDataValid  (sDataValid_w);
    ddc.sDataR      (sDataR_w);
    ddc.mDataReady  (mDataReady_w);
    ddc.dataResetn  (dataResetn_w);
    ddc.sRegPaddr   (sRegPaddr_w);
    ddc.sRegPsel    (sRegPsel_w);
    ddc.sRegPenable (sRegPenable_w);
    ddc.sRegPwrite  (sRegPwrite_w);
    ddc.sRegPwdata  (sRegPwdata_w);
  endrule

  rule ddc_stream_ingress (unpack(ddc.sDataReady));
    sDataValid_w  <= pack(True);
    sDataR_w      <= xnF.first;
    xnF.deq;
  endrule

  rule ddc_stream_egress (unpack(ddc.mDataValid));
    let xk = (Complex{rel:ddc.mDataI, img:ddc.mDataQ});
    xkF.enq(xk);
    mDataReady_w <= pack(True);
  endrule

  rule start (!started); started <= True; endrule
  rule run   ( started); dataResetn_w <= pack(True); endrule

  //This rule must fire continiuously during the lifetime of a request...
  rule sreg_request;
    let req = apbReqF.first;
    sRegPwrite_w  <= pack(req.isWrite);
    sRegPaddr_w   <= req.addr;
    sRegPwdata_w  <= req.data;
    sRegPsel_w    <= pack(True);
    sRegPenable_w <= pack(reqSetup);     // Assert PENABLE one cycle after PSEL
    if (!reqSetup) begin
      reqSetup    <= True;
    end else begin
      if (unpack(ddc.sRegPready)) begin  // PREADY asserted while PENABLE driven means cycle complete
        reqSetup  <= False;              // Clear for next request
        apbReqF.deq;                     // DEQ the current request
        // AMBA3/APB supports reponses for both reads and wrirtes, but only respond to reads here...
        if(!req.isWrite) apbRespF.enq(AMBA3APBResp {isError:unpack(ddc.sRegPslverr), data:ddc.sRegPrdata}); // ENQ the response
      end
    end
  endrule

  interface Put  putXn  = toPut(xnF);
  interface FIFO fifoXk = xkF;
  interface Put  putApb = toPut(apbReqF);
  interface Get  getApb = toGet(apbRespF);
  method    DdcInt ddcint = (DdcInt 
    {missInput :unpack(ddc.intMissinput),
     errPacket :unpack(ddc.intErrpacket),
     lostOutput:unpack(ddc.intLostoutput),
     ducDdc    :unpack(ddc.intDucddc)});
endmodule: mkDDC


endpackage: DDC
