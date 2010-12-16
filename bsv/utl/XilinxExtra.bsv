// XilinxExtra.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package XilinxExtra;

import XilinxCells::*;
import Vector::*;
import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import FIFOF::*;	
import GetPut::*;

interface DiffOutIfc#(type t);
   method Action _write(t val);
   method t      read_pos();
   method t      read_neg();
endinterface   

import "BVI" OBUFDS =
module vMkOBUFDS(DiffOutIfc#(one_bit))
   provisos(Bits#(one_bit, 1));
   
   default_clock clk();
   default_reset rstn();
   
   method      _write(I) enable((*inhigh*)en);
   method O    read_pos();
   method OB   read_neg();

   path(I, O);
   path(I, OB);
      
   schedule _write SB (read_pos, read_neg);
   schedule _write C  _write;
   schedule (read_pos, read_neg) CF (read_pos, read_neg);
endmodule: vMkOBUFDS

module mkOBUFDS(DiffOutIfc#(a))
   provisos(Bits#(a, sa));

   Vector#(sa, DiffOutIfc#(Bit#(1))) _bufg <- replicateM(vMkOBUFDS);

   function t readPos(DiffOutIfc#(t) w) = w.read_pos;
   function t readNeg(DiffOutIfc#(t) w) = w.read_neg;
   function Action writeIn(DiffOutIfc#(t) w, t v) = w._write(v);
   
   method Action _write(a x);
      Vector#(sa, Bit#(1)) vec = unpack(pack(x));
      // This is one line, but it's advanced:
      //joinActions(zipWith(writeIn, _bufg, vec));
      // This is the same thing using a for-loop:
      for (Integer i=0; i<valueOf(sa); i=i+1)
         _bufg[i] <= vec[i];
   endmethod

   method a read_pos;
      return unpack(pack(map(readPos,_bufg)));
   endmethod

   method a read_neg;
      return unpack(pack(map(readNeg,_bufg)));
   endmethod
endmodule: mkOBUFDS

// -------------------------

interface DiffInIfc#(type t);
   method Action write_pos (t val);
   method Action write_neg (t val);
   method t      _read();
endinterface   

import "BVI" IBUFDS =
module vMkIBUFDS(DiffInIfc#(one_bit))
   provisos(Bits#(one_bit, 1));
   
   default_clock clk();
   default_reset rstn();
   
   method      write_pos(I)  enable((*inhigh*)en_pos);
   method      write_neg(IB) enable((*inhigh*)en_neg);
   method O    _read();

   path(I,  O);
   path(IB, O);

   schedule (write_pos, write_neg) SB _read;
   schedule write_pos C write_pos;
   schedule write_neg C write_neg;
   schedule write_pos CF write_neg;
   schedule _read CF _read;
endmodule: vMkIBUFDS

module mkIBUFDS(DiffInIfc#(a))
   provisos(Bits#(a, sa));

   Vector#(sa, DiffInIfc#(Bit#(1))) _bufg <- replicateM(vMkIBUFDS);

   function Action writePos(DiffInIfc#(t) w, t v) = w.write_pos(v);
   function Action writeNeg(DiffInIfc#(t) w, t v) = w.write_neg(v);
   function t readOut(DiffInIfc#(t) w) = w;

   method Action write_pos(a x);
      Vector#(sa, Bit#(1)) vec = unpack(pack(x));
      // This is one line, but it's advanced:
      //joinActions(zipWith(writePos, _bufg, vec));
      // This is the same thing using a for-loop:
      for (Integer i=0; i<valueOf(sa); i=i+1)
         _bufg[i].write_pos(vec[i]);
   endmethod

   method Action write_neg(a x);
      Vector#(sa, Bit#(1)) vec = unpack(pack(x));
      // This is one line, but it's advanced:
      //joinActions(zipWith(writeNeg, _bufg, vec));
      // This is the same thing using a for-loop:
      for (Integer i=0; i<valueOf(sa); i=i+1)
         _bufg[i].write_neg(vec[i]);
   endmethod

   method a _read;
      return unpack(pack(map(readOut, _bufg)));
   endmethod

endmodule: mkIBUFDS

// -------------------------

// There are two options for this module:
// (1) "clkin" is of type Clock (if using mkClockIBUFDS as input)
// (2) "clkin" is of type Bit#(1) (if using mkIBUFDS as input)
// I'd prefer it be #1, but that requires that dac_clkp and dac_clkn
// be of type Clock.  Are they?

// Version with Clock input
import "BVI" DCM_BUFG =
module mkDCM_BUFG (ClockGenIfc);
   default_clock clk(I, (*unused*)GATE);
   default_reset rst(RST_N);

   path (I, O);

   output_clock gen_clk(O);

   same_family(clk, gen_clk);
endmodule

// Version with Bit#(1) input as a port
import "BVI" DCM_BUFG =
module mkDCM_BUFG_2 #(Bit#(1) inp) (ClockGenIfc);
   default_clock clk();
   default_reset no_reset;

   path (I, O);

   port I = inp;

   output_clock gen_clk(O);

   same_family(clk, gen_clk);
endmodule

// -------------
// BUFIO

import "BVI" BUFIO =
module vMkClockBUFIO(ClockGenIfc);
   default_clock clk(I, (*unused*)GATE);
   default_reset no_reset;
   path(I, O);
   output_clock gen_clk(O);
   same_family(clk, gen_clk);
endmodule: vMkClockBUFIO

module mkClockBUFIO(Clock);
   let _m <- vMkClockBUFIO;
   return _m.gen_clk;
endmodule: mkClockBUFIO


//----
// BUFR

typedef struct {
   String  bufr_divide;
   } BUFRParams;

instance DefaultValue#(BUFRParams);
   defaultValue = BUFRParams {
      bufr_divide:  "BYPASS"
      };
endinstance

import "BVI" BUFR =
module vMkClockBUFR#(BUFRParams params) (ClockGenIfc);
   default_clock clk(I, (*unused*)GATE);
   default_reset no_reset;
   parameter BUFR_DIVIDE = params.bufr_divide;
   port CE  = True;
   port CLR = False;
   path(I, O);
   output_clock gen_clk(O);
   same_family(clk, gen_clk);
endmodule: vMkClockBUFR

module mkClockBUFR#(BUFRParams params)(Clock);
   let _m <- vMkClockBUFR(params);
   return _m.gen_clk;
endmodule: mkClockBUFR


//----


//(* always_ready, always_enabled *)
//interface IDELAYCTRL;
//   method    Bool     rdy;
//endinterface: IDELAYCTRL

import "BVI" IDELAYCTRL =
module vMkMYIDELAYCTRL#(Integer rst_delay)(IDELAYCTRL);
   Clock c        <- exposeCurrentClock;
   Reset resetP    <- invertCurrentReset;
   //Reset delayed  <- mkAsyncReset(rst_delay, reset, c);

   default_clock clk(REFCLK);
   default_reset rst(RST) = resetP;

   method RDY rdy  reset_by(no_reset);

   schedule rdy CF rdy;
endmodule: vMkMYIDELAYCTRL

module mkMYIDELAYCTRL#(Integer rst_delay)(IDELAYCTRL);
   Reg#(Bit#(4))  preResetCount  <- mkReg(0);
   Reg#(Bit#(4))  doResetCount   <- mkReg(0);
   Clock          cClk           <- exposeCurrentClock;
   MakeResetIfc   idcRst         <- mkReset(1,True, cClk);

   rule my_reset_condition (preResetCount==4'hF && doResetCount!=4'hF);
     idcRst.assertReset;
   endrule

   rule pre_reset;
     preResetCount <= (preResetCount==4'hF) ? 4'hF : preResetCount + 1;
   endrule

   rule do_reset (preResetCount==4'hF);
      doResetCount <= (doResetCount==4'hF) ? 4'hF : doResetCount + 1;
   endrule

   let _m <- vMkMYIDELAYCTRL(rst_delay, reset_by idcRst.new_rst);
   return _m;
endmodule: mkMYIDELAYCTRL

//---

import "BVI" IDELAYCTRL_GRP =
module vMkMYIDELAYCTRL_GRP#(Integer rst_delay, String delayGrp)(IDELAYCTRL);
   Clock c        <- exposeCurrentClock;
   Reset resetP    <- invertCurrentReset;
   //Reset delayed  <- mkAsyncReset(rst_delay, reset, c);

   parameter IODELAY_GRP = delayGrp;

   default_clock clk(REFCLK);
   default_reset rst(RST) = resetP;

   method RDY rdy  reset_by(no_reset);

   schedule rdy CF rdy;
endmodule: vMkMYIDELAYCTRL_GRP

module mkMYIDELAYCTRL_GRP#(Integer rst_delay, String delayGrp)(IDELAYCTRL);
   Reg#(Bit#(4))  preResetCount  <- mkReg(0);
   Reg#(Bit#(4))  doResetCount   <- mkReg(0);
   Clock          cClk           <- exposeCurrentClock;
   MakeResetIfc   idcRst         <- mkReset(1,True, cClk);

   rule my_reset_condition (preResetCount==4'hF && doResetCount!=4'hF);
     idcRst.assertReset;
   endrule

   rule pre_reset;
     preResetCount <= (preResetCount==4'hF) ? 4'hF : preResetCount + 1;
   endrule

   rule do_reset (preResetCount==4'hF);
      doResetCount <= (doResetCount==4'hF) ? 4'hF : doResetCount + 1;
   endrule

   let _m <- vMkMYIDELAYCTRL_GRP(rst_delay, delayGrp, reset_by idcRst.new_rst);
   return _m;
endmodule: mkMYIDELAYCTRL_GRP

//---

interface ClockInvToBoolIfc;
   method Bool  _read();
endinterface

import "BVI" ClockInvToBool =
module vMkClockInvToBool#(Clock clk)(ClockInvToBoolIfc);
  default_clock clkin(CLK_FAST);
  input_clock (CLK_SLOW, (* unused *)GATE) = clk;
  default_reset ();
  method CLK_VAL _read reset_by(no_reset);
  schedule (_read) CF (_read);
endmodule

//(* synthesize *)
//module mkTest#(Clock fast, Reset fastRst)(Empty);
//  Clock slow <- exposeCurrentClock;
//  ClockInvToBoolIfc c <- vMkClockInvToBool(slow, clocked_by fast, reset_by fastRst);
//endmodule






////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008  Bluespec, Inc.   ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Author        : Todd Snyder
//  Description   : Virtex-5 Cell Wrappers
////////////////////////////////////////////////////////////////////////////////
//import Clocks            ::*;
//import Common            ::*;

typedef struct {
		String    ddr_clk_edge;
		Bit#(1)   init;
		String    srtype;
		} ODDRPrms deriving (Bits, Eq);

    /*
instance Parameters#(ODDRPrms);
   function ODDRPrms mkParams();
      return ODDRPrms {
		       ddr_clk_edge:   "OPPOSITE_EDGE",
		       init:           1'b0,
		       srtype:         "SYNC"
		       };
   endfunction
endinstance
*/
instance DefaultValue#(ODDRPrms);
      defaultValue = ODDRPrms {
		       ddr_clk_edge:   "OPPOSITE_EDGE",
		       init:           1'b0,
		       srtype:         "SYNC"
		       };
endinstance

////////////////////////////////////////////////////////////////////////////////
/// ODDR with reset method
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface ODDRr;
   method    Bit#(1)          q;
   method    Action           s(Bit#(1) i);
   method    Action           r(Bit#(1) i);
   method    Action           ce(Bit#(1) i);
   method    Action           d1(Bit#(1) i);
   method    Action           d2(Bit#(1) i);
endinterface: ODDRr

import "BVI" ODDR =
module vODDRr#(ODDRPrms params)(ODDRr);
   default_clock clk(C);
   default_reset rst();

   parameter DDR_CLK_EDGE = params.ddr_clk_edge;
   parameter INIT         = params.init;
   parameter SRTYPE       = params.srtype;
   
   method Q q;
   method   ce(CE) enable((*inhigh*)en0);
   method   d1(D1) enable((*inhigh*)en1);
   method   d2(D2) enable((*inhigh*)en2);
   method   s(S)   enable((*inhigh*)en3);
   method   r(R)   enable((*inhigh*)en4);
      
   schedule (r)         SB (d1, d2, q, ce, s);
   schedule (q)         CF (d1, d2);
   schedule (d1, d2)    CF (d1, d2);
   schedule (q)         CF (q);
   schedule (ce, s)     CF (d1, d2, q, ce, s);
   schedule (r)         C  (r);
endmodule: vODDRr

////////////////////////////////////////////////////////////////////////////////
/// ODDR with usual reset
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface ODDR;
   method    Bit#(1)          q;
   method    Action           s(Bit#(1) i);
   method    Action           ce(Bit#(1) i);
   method    Action           d1(Bit#(1) i);
   method    Action           d2(Bit#(1) i);
endinterface: ODDR

import "BVI" ODDR =
module vODDR#(ODDRPrms params)(ODDR);
   Reset         reset <- invertCurrentReset;

   default_clock clk(C);
   default_reset rst(R) = reset;

   parameter DDR_CLK_EDGE = params.ddr_clk_edge;
   parameter INIT         = params.init;
   parameter SRTYPE       = params.srtype;
   
   method Q q;
   method   ce(CE) enable((*inhigh*)en0);
   method   d1(D1) enable((*inhigh*)en1);
   method   d2(D2) enable((*inhigh*)en2);
   method   s(S)   enable((*inhigh*)en3);
      
   schedule (q)      SB (d1, d2);
   schedule (d1, d2) CF (d1, d2);
   schedule (q)      CF (q);
   schedule (ce, s)  CF (d1, d2, q, ce, s);
endmodule: vODDR

////////////////////////////////////////////////////////////////////////////////
/// ODDR for Clocks
////////////////////////////////////////////////////////////////////////////////
interface ClockODDR;
   interface Clock            q;
endinterface: ClockODDR

import "BVI" ODDR =
module vClockODDR#(ODDRPrms params, Bit#(1) d1, Bit#(1) d2)(ClockODDR);
   Reset         reset <- invertCurrentReset;

   default_clock clk(C);
   default_reset rst(R) = reset;
   
   output_clock  q(Q);

   parameter DDR_CLK_EDGE = params.ddr_clk_edge;
   parameter INIT         = params.init;
   parameter SRTYPE       = params.srtype;
   
   port D1 = d1;
   port D2 = d2;
   port CE = 1;
   port S  = 0;

endmodule: vClockODDR


////////////////////////////////////////////////////////////////////////////////
/// IDELAYCTRL
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface IDELAYCTRL;
   method Bool    rdy;
endinterface: IDELAYCTRL

import "BVI" IDELAYCTRL =
module vIDELAYCTRL(IDELAYCTRL);
   Reset reset <- invertCurrentReset;
   
   default_clock clk(REFCLK);
   default_reset rst(RST) = reset;
   
   method RDY rdy;
      
   schedule rdy CF rdy;
endmodule: vIDELAYCTRL
      
module mkIDELAYCTRL(IDELAYCTRL);
   Clock clk   <- exposeCurrentClock;
   Reset rst_n <- exposeCurrentReset;
   
   Reset rst_n_delayed <- mkAsyncReset(12, rst_n, clk);
   let   _m    <- vIDELAYCTRL(clocked_by clk, reset_by rst_n_delayed);
   return _m;
endmodule: mkIDELAYCTRL
				    
////////////////////////////////////////////////////////////////////////////////
/// IDELAY
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface IDELAY;
   method Bit#(1)    o;
   method Action     i(Bit#(1) i);
//   method Action     ce(Bit#(1) i);
//   method Action     inc(Bit#(1) i);
endinterface: IDELAY

import "BVI" IDELAY =
module vIDELAY#(String iobdelay_type, Integer iobdelay_value)(IDELAY);
   
   default_clock clk();
   default_reset rst();
   
   parameter IOBDELAY_TYPE  = iobdelay_type;
   parameter IOBDELAY_VALUE = iobdelay_value;
   
   port C   = 0;
   port RST = 0;
   port CE  = 0;
   port INC = 0;
   
   method O o;
//   method   ce(CE) enable((*inhigh*)en0);
   method   i(I)   enable((*inhigh*)en1);
//   method   inc(INC) enable((*inhigh*)en2);
   
   schedule i SB o;
   schedule i C i;
   schedule o CF o;
endmodule: vIDELAY

////////////////////////////////////////////////////////////////////////////////
/// IODELAY
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface IODELAY;
   method Action     idatain(Bit#(1) i);
   method Action     odatain(Bit#(1) i);
   method Bit#(1)    dataout;
   method Action     datain(Bit#(1) i);
   method Action     t(Bit#(1) i);
   method Action     ce(Bit#(1) i);
   method Action     inc(Bit#(1) i);
endinterface: IODELAY

interface ClockIODELAY;
   interface Clock   delayed;
endinterface: ClockIODELAY

import "BVI" IODELAY =
module vIODELAY#(String delaytype, Integer delayval, String delaysrc)(IODELAY);
   Reset rst <- invertCurrentReset;

   default_clock clk(C);
   default_reset rst(RST);

   parameter IDELAY_TYPE    = delaytype;
   parameter IDELAY_VALUE   = delayval;
   parameter DELAY_SRC      = delaysrc;
   parameter SIGNAL_PATTERN = "DATA";
   parameter HIGH_PERFORMANCE_MODE = "TRUE";
   
   method idatain(IDATAIN) enable((*inhigh*)en0);
   method odatain(ODATAIN) enable((*inhigh*)en1);
   method DATAOUT dataout;
   method datain(DATAIN)   enable((*inhigh*)en2);
   method t(T)             enable((*inhigh*)en3);
   method ce(CE)           enable((*inhigh*)en4);
   method inc(INC)         enable((*inhigh*)en5);
      
   schedule (idatain, odatain, dataout, datain, t, ce, inc) CF (idatain, odatain, dataout, datain, t, ce, inc); 
endmodule: vIODELAY

import "BVI" IODELAY =
module vClockIODELAY#(String delaytype, Integer delayval, String delaysrc)(ClockIODELAY);
   default_clock clk(IDATAIN);
   default_reset no_reset;
   output_clock delayed(DATAOUT); 
   
   parameter IDELAY_TYPE     = delaytype;
   parameter IDELAY_VALUE    = delayval;
   parameter DELAY_SRC       = delaysrc;
   parameter SIGNAL_PATTERN  = "CLOCK";
   parameter HIGH_PERFORMANCE_MODE = "TRUE";
   
   port ODATAIN = 0;
   port DATAIN  = 0;
   port C       = 0;
   port T       = 0;
   port CE      = 0;
   port INC     = 0;
   port RST     = 0;
endmodule: vClockIODELAY

////////////////////////////////////////////////////////////////////////////////
/// BUFG
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface Buffer;
   method    Action      _write(Bit#(1) x);
   method    Bit#(1)     _read;
endinterface: Buffer

interface ClockBuffer;
   interface Clock       clkout;
endinterface: ClockBuffer

interface ResetBuffer;
   interface Reset       rstout;
endinterface: ResetBuffer

import "BVI" BUFG =
module vBUFG(Buffer);
   default_clock clk();
   default_reset rst();
   
   method      _write(I) enable((*inhigh*)en);
   method O    _read;
      
   path (I, O);

   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule: vBUFG

import "BVI" BUFG =
module vClkBUFG(ClockBuffer);
   default_clock clk(I);
   default_reset no_reset;

   output_clock clkout(O);
endmodule: vClkBUFG

import "BVI" IBUFG =
module vIBUFG(Buffer);
   
   default_clock clk();
   default_reset rst();
   
   method      _write(I) enable((*inhigh*)en);
   method O    _read;
      
   path (I, O);
      
   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule: vIBUFG

import "BVI" IBUFG =
module vClkIBUFG(ClockBuffer);
   default_clock clk(I);
   default_reset rst();

   output_clock clkout(O);
endmodule: vClkIBUFG

import "BVI" IBUF =
module vIBUF(Buffer);
   
   default_clock clk();
   default_reset rst();
   
   method      _write(I) enable((*inhigh*)en);
   method O    _read;
      
   path (I, O);
      
   schedule _write SB _read;
   schedule _write C  _write;
   schedule _read  CF _read;
endmodule: vIBUF

import "BVI" IBUF =
module vRstIBUF(ResetBuffer);
   default_clock clk();
   default_reset rst(I);

   output_reset  rstout(O) clocked_by(no_clock);
endmodule: vRstIBUF

import "BVI" IBUFDS =
module vClkIBUFDS#(Clock clk_p, Clock clk_n)(ClockBuffer);
   default_clock clk();
   default_reset rst();
   
   input_clock  clk_p(I) = clk_p;
   input_clock  clk_n(IB) = clk_n;
   
   output_clock clkout(O);   
   same_family(clk_p, clkout);
endmodule: vClkIBUFDS

endpackage: XilinxExtra
