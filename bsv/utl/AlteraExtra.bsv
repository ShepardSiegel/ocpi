package AlteraExtra;

import Clocks::*;
import Vector::*;

export LVDSClockPair, pairClocks, posClock, negClock;
export clockFromLVDS, clockToLVDS;
export PLL(..), mkPLL;

// structure for working with LVDS clock signal pairs

typedef Vector#(2,Clock) LVDSClockPair;

function LVDSClockPair pairClocks(Clock pos, Clock neg);
   return Vector::cons(pos,Vector::cons(neg,Vector::nil));
endfunction

function Clock posClock(LVDSClockPair lvds);
   return lvds[0];
endfunction

function Clock negClock(LVDSClockPair lvds);
   return lvds[1];
endfunction

// helper interface for dealing with imported clock generating modules
interface WrappedClock;
   interface Clock clk_out;
endinterface: WrappedClock

import "BVI" alt_inbuf_diff =
   module v_alt_inbuf_diff(Clock clk_in_p, Clock clk_in_n, WrappedClock ifc);
      default_clock no_clock;
      no_reset;

      parameter io_standard="LVDS";

      input_clock clk_p(i)    = clk_in_p;
      input_clock clk_n(ibar) = clk_in_n;

      output_clock clk_out(o);

      ancestor(clk_out,clk_p);

      path(i, o);
      path(ibar, o);
   endmodule

// This is the exported module for producing a clock from an LVDS clock signal pair
(* no_default_clock, no_default_reset *)
module clockFromLVDS(LVDSClockPair lvds, Clock ifc);
   let _m <- v_alt_inbuf_diff(posClock(lvds), negClock(lvds));
   return _m.clk_out;
endmodule

interface TwoClockIfc;
   interface Clock pos;
   interface Clock neg;
endinterface

Bit#(1) one  = 1'b1;
Bit#(1) zero = 1'b0;

import "BVI" altddio_out =
   module v_alt_ddio_out(Clock sClk, WrappedClock ifc);
      default_clock no_clock;
      no_reset;

      parameter extend_oe_disable = "UNUSED";
      parameter intended_device_family = "Stratix III";
      parameter lpm_type = "altddio_out";
      parameter oe_reg = "UNUSED";
      parameter width = 1;

      input_clock clk(outclock) = sClk;
      output_clock clk_out(dataout);

      port datain_h   clocked_by(clk) = one;
      port datain_l   clocked_by(clk) = zero;
      port oe         clocked_by(clk) = one;
      port outclocken clocked_by(clk) = one;
      port aclr       clocked_by(clk) = zero;
      port aset       clocked_by(clk) = zero;
      port sclr       clocked_by(clk) = zero;
      port sset       clocked_by(clk) = zero;

      ancestor(clk_out,clk);

      path(outclock, dataout);
   endmodule

import "BVI" alt_outbuf_diff =
   module v_alt_outbuf_diff(Clock ddrff_clk, TwoClockIfc ifc);
      default_clock no_clock;
      no_reset;

      parameter io_standard="LVDS";

      input_clock clk_in(i) = ddrff_clk;

      output_clock pos(o);
      output_clock neg(obar);

      ancestor(pos,clk_in);

      path(i, o);
      path(i, obar);
   endmodule

// This is the exported module for producing an LVDS clock signal pair from a clock
(* no_default_clock, no_default_reset *)
module clockToLVDS(Clock clkIn, LVDSClockPair ifc);
   let _clk_ddrff <- v_alt_ddio_out(clkIn);
   TwoClockIfc _lvds <- v_alt_outbuf_diff(_clk_ddrff.clk_out);
   return pairClocks(_lvds.pos, _lvds.neg);
endmodule

// PLL routines

interface CRPair;
   interface Clock clk;
   interface Reset rstn;
endinterface

interface PLL;
   interface Clock clk;
   interface Reset rstn;
   method Bool locked();
endinterface

import "BVI" aclk_pll =
   module v_aclk_pll(Clock clk_in, Reset rst_in, CRPair ifc);
      default_clock no_clock;
      no_reset;

      input_clock clkin(inclk0) = clk_in;
      input_reset rstin(areset) clocked_by(clkin) = rst_in;

      ancestor(clk,clkin);

      output_clock clk(c0);
      output_reset rstn(locked) clocked_by(clk);
   endmodule

(* no_default_clock, no_default_reset *)
module mkPLL(Clock clk_in, Reset inv_rst_in, PLL ifc);
   Reset _rst <- mkResetInverter(inv_rst_in, clocked_by noClock, reset_by noReset);
   CRPair _m <- v_aclk_pll(clk_in, _rst, clocked_by noClock, reset_by noReset);
   ReadOnly#(Bool) _rst_test <- isResetAsserted(clocked_by noClock, reset_by _m.rstn);
   interface Clock clk  = _m.clk;
   interface Reset rstn = _m.rstn;
   method Bool locked();
      return !_rst_test;
   endmethod
endmodule

endpackage: AlteraExtra
