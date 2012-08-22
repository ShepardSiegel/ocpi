// XilinxExtra.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

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

`define SHEP_ODDRar
`ifdef SHEP_ODDRar

interface VODDRar#(type a);
   method    a            q();
   method    Action       s(Bool i);
   method    Action       ce(Bool i);
   method    Action       d1(a i);
   method    Action       d2(a i);
endinterface: VODDRar

(* always_ready, always_enabled *)
interface ODDRar#(type a);
   method    a                q();
   method    Action           s(Bool i);
   method    Action           ce(Bool i);
   method    Action           d1(a i);
   method    Action           d2(a i);
endinterface: ODDRar

import "BVI" ODDR =
module vMkODDRar#(ODDRParams#(a) params)(VODDRar#(a))
   provisos(Bits#(a, 1), DefaultValue#(a));

   default_clock clk(C);
   default_reset rst(R);

   parameter DDR_CLK_EDGE = params.ddr_clk_edge;
   parameter INIT         = pack(params.init);
   parameter SRTYPE       = params.srtype;

   method Q   q                              reset_by(no_reset);
   method     s(S)     enable((*inhigh*)en0) reset_by(no_reset);
   method     ce(CE)   enable((*inhigh*)en1) reset_by(no_reset);
   method     d1(D1)   enable((*inhigh*)en2) reset_by(no_reset);
   method     d2(D2)   enable((*inhigh*)en3) reset_by(no_reset);

   schedule (q,d1,d2,ce,s)  CF (q,d1,d2,ce,s);
endmodule: vMkODDRar

module mkODDRar#(ODDRParams#(a) params)(ODDRar#(a))
   provisos(Bits#(a, sa), DefaultValue#(a));

   Reset reset <- invertCurrentReset;

   Vector#(sa, ODDRParams#(Bit#(1))) _params = ?;
   for(Integer i = 0; i < valueof(sa); i = i + 1) begin
      _params[i].ddr_clk_edge = params.ddr_clk_edge;
      _params[i].init         = pack(params.init)[i];
      _params[i].srtype       = params.srtype;
   end

   Vector#(sa, VODDRar#(Bit#(1))) _oddr  = ?;
   for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr[i] <- vMkODDRar(_params[i], reset_by reset);

   function Bit#(1) getQ(VODDRar#(Bit#(1)) ddr);
      return ddr.q;
   endfunction

   method a q();
      return unpack(pack(map(getQ, _oddr)));
   endmethod

   method Action s(Bool x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr[i].s(x);
   endmethod

   method Action ce(Bool x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr[i].ce(x);
   endmethod

   method Action d1(a x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr[i].d1(pack(x)[i]);
   endmethod

   method Action d2(a x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr[i].d2(pack(x)[i]);
   endmethod

endmodule: mkODDRar

`endif

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


////////////////////////////////////////////////////////////////////////////////
/// IBUFDS_GTE2 - for series 7
////////////////////////////////////////////////////////////////////////////////
interface GTE2ClockGenIfc;
   interface Clock gen_clk;
   interface Clock gen_clk_div2;
endinterface

import "BVI" IBUFDS_GTE2 =
module vMkClockIBUFDS_GTE2#(Bool enable, Clock clk_p, Clock clk_n)(GTE2ClockGenIfc);
   default_clock no_clock;
   default_reset no_reset;

   input_clock clk_p(I)  = clk_p;
   input_clock clk_n(IB) = clk_n;

   port CEB = pack(!enable);

   output_clock gen_clk(O);
   output_clock gen_clk_div2(ODIV2);

   path(I,  O);
   path(IB, O);
   path(I,  ODIV2);
   path(IB, ODIV2);

   same_family(clk_p, gen_clk);
endmodule: vMkClockIBUFDS_GTE2

module mkClockIBUFDS_GTE2#(Bool enable, Clock clk_p, Clock clk_n)(Clock);
   let _m <- vMkClockIBUFDS_GTE2(enable, clk_p, clk_n);
   return _m.gen_clk;
endmodule: mkClockIBUFDS_GTE2

module mkClockIBUFDS_GTE2_div2#(Bool enable, Clock clk_p, Clock clk_n)(Clock);
   let _m <- vMkClockIBUFDS_GTE2(enable, clk_p, clk_n);
   return _m.gen_clk_div2;
endmodule: mkClockIBUFDS_GTE2_div2


////////////////////////////////////////////////////////////////////////////////
///  OSERDES (V6)
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   String      data_rate_oq;
   String      data_rate_tq;
   Integer     data_width;
   String      serdes_mode;
   Integer     tristate_width;
   Integer     odelay_used;
   String      interface_type;
} OSERDESParams deriving (Bits, Eq);

instance DefaultValue#(OSERDESParams);
   defaultValue = OSERDESParams {
      data_rate_oq:          "DDR",
      data_rate_tq:          "DDR",
      data_width:            4,
      serdes_mode:           "MASTER",
      tristate_width:        4,
      odelay_used:           0,
      interface_type:        "DEFAULT"
      };
endinstance

(* always_ready, always_enabled *)
interface OSERDES;
   method Bool   oq;
   method Bool   ofb;
   method Bool   tq;
   method Bool   tfb;
   method Bool   shiftout1;
   method Bool   shiftout2;
   method Bool   ocbextend;
   method Action d1       (Bool i);
   method Action d2       (Bool i);
   method Action d3       (Bool i);
   method Action d4       (Bool i);
   method Action d5       (Bool i);
   method Action d6       (Bool i);
   method Action tci      (Bool i);
   method Action oce      (Bool i);
   method Action wc       (Bool i);
   method Action odv      (Bool i);
   method Action shiftin1 (Bool i);
   method Action shiftin2 (Bool i);
   method Action t1       (Bool i);
   method Action t2       (Bool i);
   method Action t3       (Bool i);
   method Action t4       (Bool i);
endinterface

import "BVI" OSERDES =
module vMkOSERDES#(OSERDESParams params, 
                   Clock clk, 
                   Clock clkdiv, 
                   Clock clkperf, Clock clkperfdelayed) (OSERDES);

   Reset reset <- invertCurrentReset;
   default_reset rst(RST) = reset;
   default_clock clkdiv (CLKDIV);  // Most of this modules methods in the CLKDIV domain

   
   parameter DATA_RATE_OQ    = params.data_rate_oq;
   parameter DATA_RATE_TQ    = params.data_rate_tq;
   parameter DATA_WIDTH      = params.data_width;
   parameter SERDES_MODE     = params.serdes_mode;
   parameter TRISTATE_WIDTH  = params.tristate_width;
   parameter ODELAY_USED     = params.odelay_used;
   parameter INTERFACE_TYPE  = params.interface_type;
   
   input_clock clkhs(CLK,            (*unused*)CLKHS_GATE) = clk;
   input_clock clkp (CLKPERF,        (*unused*)CLKP_GATE)  = clkperf;
   input_clock clkpd(CLKPERFSELAYED, (*unused*)CLKPD_GATE) = clkperfdelayed;

   method OQ         oq        reset_by(no_reset);
   method OFB        ofb       reset_by(no_reset);
   method TQ         tq        reset_by(no_reset);
   method TFB        tfb       reset_by(no_reset);
   method SHIFTOUT1  shiftout1 reset_by(no_reset);
   method SHIFTOUT2  shiftout2 reset_by(no_reset);
   method OCBEXTEND  ocbextend reset_by(no_reset);
   method            d1         (D1)       enable((*inhigh*)en0)  reset_by(no_reset);
   method            d2         (D2)       enable((*inhigh*)en1)  reset_by(no_reset);
   method            d3         (D3)       enable((*inhigh*)en2)  reset_by(no_reset);
   method            d4         (D4)       enable((*inhigh*)en3)  reset_by(no_reset);
   method            d5         (D5)       enable((*inhigh*)en4)  reset_by(no_reset);
   method            d6         (D6)       enable((*inhigh*)en5)  reset_by(no_reset);
   method            tci        (TCI)      enable((*inhigh*)en6)  reset_by(no_reset);
   method            oce        (OCE)      enable((*inhigh*)en7)  reset_by(no_reset);
   method            wc         (WC)       enable((*inhigh*)en8)  reset_by(no_reset);
   method            odv        (ODV)      enable((*inhigh*)en9)  reset_by(no_reset);
   method            shiftin1   (SHIFTIN1) enable((*inhigh*)en10) reset_by(no_reset);
   method            shiftin2   (SHIFTIN2) enable((*inhigh*)en11) reset_by(no_reset);
   method            t1         (T1)       enable((*inhigh*)en12) reset_by(no_reset);
   method            t2         (T2)       enable((*inhigh*)en13) reset_by(no_reset);
   method            t3         (T3)       enable((*inhigh*)en14) reset_by(no_reset);
   method            t4         (T4)       enable((*inhigh*)en15) reset_by(no_reset);

   //TODO: Make this schedule non-bogus...
   schedule
   (oq, ofb, tq, tfb, shiftout1, shiftout2, ocbextend, d1, d2, d3, d4, d5, d6, tci, oce, wc, odv, shiftin1, shiftin2, t1, t2, t3, t4)
   CF
   (oq, ofb, tq, tfb, shiftout1, shiftout2, ocbextend, d1, d2, d3, d4, d5, d6, tci, oce, wc, odv, shiftin1, shiftin2, t1, t2, t3, t4);

endmodule

module mkOSERDES#(OSERDESParams params, Clock clk, Clock clkdiv, Clock clkperf, Clock clkperfdelayed)(OSERDES);
   OSERDES _oserdes <- vMkOSERDES(params, clk, clkdiv, clkperf, clkperfdelayed);
   return _oserdes;
endmodule


////////////////////////////////////////////////////////////////////////////////
// Spartan-3 ODDR2

typedef struct {
		String    ddr_alignment;
		Bit#(1)   init;
		String    srtype;
		} ODDR2Prms#(type a) deriving (Bits, Eq);

instance DefaultValue#(ODDR2Prms#(a))
  provisos(DefaultValue#(a));
  defaultValue = ODDR2Prms {
		ddr_alignment:   "NONE",
		init:            1'b0,
		srtype:         "SYNC"
  };
endinstance

interface VODDR2#(type a);
   method    a         q;
   method    Action    s (Bool i);
   method    Action    ce(Bool i);
   method    Action    d0(a i);
   method    Action    d1(a i);
endinterface: VODDR2


(* always_ready, always_enabled *)
interface ODDR2#(type a);
   method    a         q;
   method    Action    s (Bool i);
   method    Action    ce(Bool i);
   method    Action    d0(a i);
   method    Action    d1(a i);
endinterface: ODDR2

import "BVI" ODDR2 =
module vMkODDR2#(ODDR2Prms#(a) params, Clock c0, Clock c1)(ODDR2#(a))
   provisos(Bits#(a,sa), DefaultValue#(a));

   parameter DDR_ALIGNMENT = params.ddr_alignment;
   parameter INIT          = params.init;
   parameter SRTYPE        = params.srtype;

   default_clock clk();  // Stops BSV from generating the OSC and CLK_GATE ports

   default_reset rst(R);  // Tie current reset to active-high R

   //no_reset;  // Stops BSV from generating the RST_N port

   input_clock clk_0(C0, (*unused*)C0_GATE) = c0;
   input_clock clk_1(C1, (*unused*)C1_GATE) = c1;
   
   method Q q;
   method   ce(CE) enable((*inhigh*)en0);
   method   d0(D0) enable((*inhigh*)en1);
   method   d1(D1) enable((*inhigh*)en2);
   method   s(S)   enable((*inhigh*)en3);

   //TODO: Make this schedule non-bogus...
   schedule
   (q, ce, d0, d1, s) CF (q, ce, d0, d1, s);

endmodule: vMkODDR2

module mkODDR2#(ODDR2Prms#(a) params)(ODDR2#(a))
   provisos(Bits#(a,sa), DefaultValue#(a));

   Reset reset <- invertCurrentReset;  // Generate the active-high reset for the underlying module

   Clock           c0  <- exposeCurrentClock;
   ClockDividerIfc cdi <- mkClockInverter;
   Clock           c1  =  cdi.slowClock;

   Vector#(sa, ODDR2Prms#(Bit#(1))) _params = ?;
   for(Integer i = 0; i < valueof(sa); i = i + 1) begin
      _params[i].ddr_alignment = params.ddr_alignment;
      //_params[i].init          = pack(params.init)[i];
      _params[i].init          = 1'b0; // FIXME: allow vector init
      _params[i].srtype        = params.srtype;
   end

   Vector#(sa, ODDR2#(Bit#(1))) _oddr2  = ?;
   for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr2[i] <- vMkODDR2(_params[i], c0, c1, reset_by reset);

   function Bit#(1) getQ(ODDR2#(Bit#(1)) ddr);
      return ddr.q;
   endfunction

   method a q();
      return unpack(pack(map(getQ, _oddr2)));
   endmethod

   method Action s(Bool x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr2[i].s(x);
   endmethod

   method Action ce(Bool x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr2[i].ce(x);
   endmethod

   method Action d0(a x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr2[i].d0(pack(x)[i]);
   endmethod

   method Action d1(a x);
      for(Integer i = 0; i < valueof(sa); i = i + 1) _oddr2[i].d1(pack(x)[i]);
   endmethod

endmodule: mkODDR2

// Clock Gen Flavor of ODDR2 for Source-Sync...

import "BVI" ODDR2 =
module vMkClockODDR2#(ODDR2Prms#(a) params, Clock c0, Clock c1, Bit#(1) d0, Bit#(1) d1)(ClockGenIfc);

   Reset reset <- invertCurrentReset;
   default_reset rst(R) = reset;

   default_clock clk();  // Stops BSV from generating the OSC and CLK_GATE ports

   input_clock clk_0(C0, (*unused*)C0_GATE) = c0;
   input_clock clk_1(C1, (*unused*)C1_GATE) = c1;

   output_clock gen_clk(Q);

   parameter DDR_ALIGNMENT = params.ddr_alignment;
   parameter INIT          = params.init;
   parameter SRTYPE        = params.srtype;

   port D0 = d0;
   port D1 = d1;
   port CE = True;
   port S  = False;
endmodule: vMkClockODDR2

module mkClockODDR2#(ODDR2Prms#(a) params, Bit#(1) d0, Bit#(1) d1)(Clock);
   Clock           c0  <- exposeCurrentClock;
   ClockDividerIfc cdi <- mkClockInverter;
   Clock           c1  =  cdi.slowClock;
   let _m <- vMkClockODDR2(params, c0, c1, d0, d1);
   return _m.gen_clk;
endmodule: mkClockODDR2


endpackage: XilinxExtra
