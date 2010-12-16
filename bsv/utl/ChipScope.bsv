////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009  Bluespec, Inc.   ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : ChipScope.bsv
//  Author        : Todd Snyder
//  Description   : Xilinx ChipScope Wrappers
////////////////////////////////////////////////////////////////////////////////
package ChipScope;

// Notes :

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Vector            ::*;

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
interface ChipScopeICON#(numeric type ports);
   interface Vector#(ports, Inout#(Bit#(36)))  control;
endinterface

(* always_ready, always_enabled *)
interface ChipScopeILA_1#(numeric type datawidth, numeric type trigwidth);
   interface Inout#(Bit#(36)) control;
   method    Action           trigger(Bit#(trigwidth) i);
   method    Action           data(Bit#(datawidth) i);
endinterface

interface ChipScopeICON_1;
   interface Inout#(Bit#(36)) control_1;
endinterface

interface ChipScopeICON_2;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
endinterface

interface ChipScopeICON_3;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
endinterface

interface ChipScopeICON_4;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
endinterface

interface ChipScopeICON_5;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
endinterface

interface ChipScopeICON_6;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
endinterface

interface ChipScopeICON_7;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
endinterface

interface ChipScopeICON_8;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
endinterface

interface ChipScopeICON_9;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
endinterface

interface ChipScopeICON_10;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
endinterface

interface ChipScopeICON_11;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
   interface Inout#(Bit#(36)) control_11;
endinterface

interface ChipScopeICON_12;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
   interface Inout#(Bit#(36)) control_11;
   interface Inout#(Bit#(36)) control_12;
endinterface

interface ChipScopeICON_13;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
   interface Inout#(Bit#(36)) control_11;
   interface Inout#(Bit#(36)) control_12;
   interface Inout#(Bit#(36)) control_13;
endinterface

interface ChipScopeICON_14;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
   interface Inout#(Bit#(36)) control_11;
   interface Inout#(Bit#(36)) control_12;
   interface Inout#(Bit#(36)) control_13;
   interface Inout#(Bit#(36)) control_14;
endinterface

interface ChipScopeICON_15;
   interface Inout#(Bit#(36)) control_1;
   interface Inout#(Bit#(36)) control_2;
   interface Inout#(Bit#(36)) control_3;
   interface Inout#(Bit#(36)) control_4;
   interface Inout#(Bit#(36)) control_5;
   interface Inout#(Bit#(36)) control_6;
   interface Inout#(Bit#(36)) control_7;
   interface Inout#(Bit#(36)) control_8;
   interface Inout#(Bit#(36)) control_9;
   interface Inout#(Bit#(36)) control_10;
   interface Inout#(Bit#(36)) control_11;
   interface Inout#(Bit#(36)) control_12;
   interface Inout#(Bit#(36)) control_13;
   interface Inout#(Bit#(36)) control_14;
   interface Inout#(Bit#(36)) control_15;
endinterface


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Implementation of ICON Wrappers
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
import "BVI" chipscope_icon_1 =
module vMkChipScopeICON_1(ChipScopeICON_1);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_1

import "BVI" chipscope_icon_2 =
module vMkChipScopeICON_2(ChipScopeICON_2);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_2

import "BVI" chipscope_icon_3 =
module vMkChipScopeICON_3(ChipScopeICON_3);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_3

import "BVI" chipscope_icon_4 =
module vMkChipScopeICON_4(ChipScopeICON_4);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_4

import "BVI" chipscope_icon_5 =
module vMkChipScopeICON_5(ChipScopeICON_5);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_5

import "BVI" chipscope_icon_6 =
module vMkChipScopeICON_6(ChipScopeICON_6);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_6

import "BVI" chipscope_icon_7 =
module vMkChipScopeICON_7(ChipScopeICON_7);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_7

import "BVI" chipscope_icon_8 =
module vMkChipScopeICON_8(ChipScopeICON_8);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_8

import "BVI" chipscope_icon_9 =
module vMkChipScopeICON_9(ChipScopeICON_9);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_9

import "BVI" chipscope_icon_10 =
module vMkChipScopeICON_10(ChipScopeICON_10);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_10

import "BVI" chipscope_icon_11 =
module vMkChipScopeICON_11(ChipScopeICON_11);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   ifc_inout     control_11(CONTROL10) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_11

import "BVI" chipscope_icon_12 =
module vMkChipScopeICON_12(ChipScopeICON_12);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   ifc_inout     control_11(CONTROL10) clocked_by(no_clock);
   ifc_inout     control_12(CONTROL11) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_12

import "BVI" chipscope_icon_13 =
module vMkChipScopeICON_13(ChipScopeICON_13);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   ifc_inout     control_11(CONTROL10) clocked_by(no_clock);
   ifc_inout     control_12(CONTROL11) clocked_by(no_clock);
   ifc_inout     control_13(CONTROL12) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_13

import "BVI" chipscope_icon_14 =
module vMkChipScopeICON_14(ChipScopeICON_14);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   ifc_inout     control_11(CONTROL10) clocked_by(no_clock);
   ifc_inout     control_12(CONTROL11) clocked_by(no_clock);
   ifc_inout     control_13(CONTROL12) clocked_by(no_clock);
   ifc_inout     control_14(CONTROL13) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_14

import "BVI" chipscope_icon_15 =
module vMkChipScopeICON_15(ChipScopeICON_15);

   default_clock clk();
   default_reset no_reset;
   
   ifc_inout     control_1(CONTROL0) clocked_by(no_clock);
   ifc_inout     control_2(CONTROL1) clocked_by(no_clock);
   ifc_inout     control_3(CONTROL2) clocked_by(no_clock);
   ifc_inout     control_4(CONTROL3) clocked_by(no_clock);
   ifc_inout     control_5(CONTROL4) clocked_by(no_clock);
   ifc_inout     control_6(CONTROL5) clocked_by(no_clock);
   ifc_inout     control_7(CONTROL6) clocked_by(no_clock);
   ifc_inout     control_8(CONTROL7) clocked_by(no_clock);
   ifc_inout     control_9(CONTROL8) clocked_by(no_clock);
   ifc_inout     control_10(CONTROL9) clocked_by(no_clock);
   ifc_inout     control_11(CONTROL10) clocked_by(no_clock);
   ifc_inout     control_12(CONTROL11) clocked_by(no_clock);
   ifc_inout     control_13(CONTROL12) clocked_by(no_clock);
   ifc_inout     control_14(CONTROL13) clocked_by(no_clock);
   ifc_inout     control_15(CONTROL14) clocked_by(no_clock);
   
endmodule: vMkChipScopeICON_15

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// mkChipScopeICON BSV wrapper
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkChipScopeICON(ChipScopeICON#(ports))
   provisos(Add#(1, z, ports));
   
   Integer p = valueof(ports);
   
   let _i = ?;
   
   if (p == 1) begin 
      let _icon_1 <- vMkChipScopeICON_1; 
      Inout#(Bit#(36)) v[1] = { _icon_1.control_1 };
      _i = arrayToVector(v);
   end 
   else if (p == 2) begin
      let _icon_2 <- vMkChipScopeICON_2;
      Inout#(Bit#(36)) v[2] = { _icon_2.control_1, _icon_2.control_2 };
      _i = arrayToVector(v);
   end
   else if (p == 3) begin
      let _icon_3 <- vMkChipScopeICON_3;
      Inout#(Bit#(36)) v[3] = { _icon_3.control_1, _icon_3.control_2, _icon_3.control_3 };
      _i = arrayToVector(v);
   end
   else if (p == 4) begin
      let _icon_4 <- vMkChipScopeICON_4;
      Inout#(Bit#(36)) v[4] = { _icon_4.control_1, _icon_4.control_2, _icon_4.control_3, _icon_4.control_4 };
      _i = arrayToVector(v);
   end
   else if (p == 5) begin
      let _icon_5 <- vMkChipScopeICON_5;
      Inout#(Bit#(36)) v[5] = { _icon_5.control_1, _icon_5.control_2, _icon_5.control_3, _icon_5.control_4, _icon_5.control_5 };
      _i = arrayToVector(v);
   end
   else if (p == 6) begin
      let _icon_6 <- vMkChipScopeICON_6;
      Inout#(Bit#(36)) v[6] = { _icon_6.control_1, _icon_6.control_2, _icon_6.control_3, _icon_6.control_4, _icon_6.control_5, 
			        _icon_6.control_6 };
      _i = arrayToVector(v);
   end
   else if (p == 7) begin
      let _icon_7 <- vMkChipScopeICON_7;
      Inout#(Bit#(36)) v[7] = { _icon_7.control_1, _icon_7.control_2, _icon_7.control_3, _icon_7.control_4, _icon_7.control_5, 
			        _icon_7.control_6, _icon_7.control_7 };
      _i = arrayToVector(v);
   end
   else if (p == 8) begin
      let _icon_8 <- vMkChipScopeICON_8;
      Inout#(Bit#(36)) v[8] = { _icon_8.control_1, _icon_8.control_2, _icon_8.control_3, _icon_8.control_4, _icon_8.control_5, 
			        _icon_8.control_6, _icon_8.control_7, _icon_8.control_8 };
      _i = arrayToVector(v);
   end
   else if (p == 9) begin
      let _icon_9 <- vMkChipScopeICON_9;
      Inout#(Bit#(36)) v[9] = { _icon_9.control_1, _icon_9.control_2, _icon_9.control_3, _icon_9.control_4, _icon_9.control_5, 
			        _icon_9.control_6, _icon_9.control_7, _icon_9.control_8, _icon_9.control_9 };
      _i = arrayToVector(v);
   end
   else if (p == 10) begin
      let _icon_10 <- vMkChipScopeICON_10;
      Inout#(Bit#(36)) v[10] = { _icon_10.control_1, _icon_10.control_2, _icon_10.control_3, _icon_10.control_4, _icon_10.control_5, 
				 _icon_10.control_6, _icon_10.control_7, _icon_10.control_8, _icon_10.control_9, _icon_10.control_10 };
      _i = arrayToVector(v);
   end
   else if (p == 11) begin
      let _icon_11 <- vMkChipScopeICON_11;
      Inout#(Bit#(36)) v[11] = { _icon_11.control_1, _icon_11.control_2, _icon_11.control_3, _icon_11.control_4, _icon_11.control_5, 
				 _icon_11.control_6, _icon_11.control_7, _icon_11.control_8, _icon_11.control_9, _icon_11.control_10,
				 _icon_11.control_11 };
      _i = arrayToVector(v);
   end
   else if (p == 12) begin
      let _icon_12 <- vMkChipScopeICON_12;
      Inout#(Bit#(36)) v[12] = { _icon_12.control_1,  _icon_12.control_2, _icon_12.control_3, _icon_12.control_4, _icon_12.control_5, 
				 _icon_12.control_6,  _icon_12.control_7, _icon_12.control_8, _icon_12.control_9, _icon_12.control_10,
				 _icon_12.control_11, _icon_12.control_12 };
      _i = arrayToVector(v);
   end
   else if (p == 13) begin
      let _icon_13 <- vMkChipScopeICON_13;
      Inout#(Bit#(36)) v[13] = { _icon_13.control_1,  _icon_13.control_2,  _icon_13.control_3, _icon_13.control_4, _icon_13.control_5, 
				 _icon_13.control_6,  _icon_13.control_7,  _icon_13.control_8, _icon_13.control_9, _icon_13.control_10,
				 _icon_13.control_11, _icon_13.control_12, _icon_13.control_13 };
      _i = arrayToVector(v);
   end
   else if (p == 14) begin
      let _icon_14 <- vMkChipScopeICON_14;
      Inout#(Bit#(36)) v[14] = { _icon_14.control_1,  _icon_14.control_2,  _icon_14.control_3,  _icon_14.control_4, _icon_14.control_5, 
				 _icon_14.control_6,  _icon_14.control_7,  _icon_14.control_8,  _icon_14.control_9, _icon_14.control_10,
				 _icon_14.control_11, _icon_14.control_12, _icon_14.control_13, _icon_14.control_14 };
      _i = arrayToVector(v);
   end
   else if (p == 15) begin
      let _icon_15 <- vMkChipScopeICON_15;
      Inout#(Bit#(36)) v[15] = { _icon_15.control_1,  _icon_15.control_2,  _icon_15.control_3,  _icon_15.control_4,  _icon_15.control_5, 
				 _icon_15.control_6,  _icon_15.control_7,  _icon_15.control_8,  _icon_15.control_9,  _icon_15.control_10,
				 _icon_15.control_11, _icon_15.control_12, _icon_15.control_13, _icon_15.control_14, _icon_15.control_15 };
      _i = arrayToVector(v);
   end
   else 
      error("The ChipScope ICON module can only have between 1 and 15 control ports.");
      
   interface control = _i;

endmodule: mkChipScopeICON

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation of ILA Wrappers
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
import "BVI" chipscope_ila_1 =
module vMkChipScopeILA_1(ChipScopeILA_1#(d, t))
   provisos(
	    Add#(d, z, 1024),
	    Add#(t, y, 256)
	    );
   
   default_clock clk(CLK);
   default_reset no_reset;
   
   ifc_inout control(CONTROL) clocked_by(no_clock);
   
   method trigger(TRIG0) enable((*inhigh*)EN_1);
   method data(DATA)     enable((*inhigh*)EN_2);
      
   schedule (trigger, data) CF (trigger, data);
   
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// mkChipScopeILA BSV wrapper
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkChipScopeILA1(ChipScopeILA_1#(d, t))
   provisos(
	    Add#(d, z, 1024),
	    Add#(t, y, 256)
	    );
   
   let _ila <- vMkChipScopeILA_1;
   return _ila;
endmodule

endpackage: ChipScope
