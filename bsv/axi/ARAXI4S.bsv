// ARAXI4S Atomic Rules - AXI4-Stream Implementation
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// Reference: ARM AMBA 4 AXI-4 Stream Protocol Specification V1.0

package ARAXI4S;

import Bus::*;
import ClientServer::*;
import Connectable::*;
import ConfigReg::*;
import DefaultValue::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import FShow::*;
import GetPut::*;
import SpecialFIFOs::*;
import TieOff::*;
import Vector::*;


// 
// AXI4-Streaming Interface
// 
// td - number of bits in data    (TDATA)
// tg - number of bits in strobe  (TSTRB)
// th - number of bits in keep    (TKEEP)
// tu - number of bits in user    (TUSER)

// AXI4-S (AXIS) type synonyms...
typedef A4Stream#( 0, 0, 0, 0) A4S0B;
typedef A4Stream#( 8, 1, 0, 0) A4S1B;
typedef A4Stream#(16, 2, 0, 0) A4S2B;
typedef A4Stream#(32, 4, 0, 0) A4S4B;
typedef A4Stream#(64, 8, 0, 0) A4S8B;
typedef A4Stream#(128,16,0, 0) A4S16B;
typedef A4Stream#(256,32,0, 0) A4S32B;
typedef A4S_Em#  ( 1, 0, 0, 0) A4SEM0B;
typedef A4S_Es#  ( 1, 0, 0, 0) A4SES0B;
typedef A4S_Em#  ( 8, 1, 0, 0) A4SEM1B;
typedef A4S_Es#  ( 8, 1, 0, 0) A4SES1B;
typedef A4S_Em#  (16, 2, 0, 0) A4SEM2B;
typedef A4S_Es#  (16, 2, 0, 0) A4SES2B;
typedef A4S_Em#  (32, 4, 0, 0) A4SEM4B;
typedef A4S_Es#  (32, 4, 0, 0) A4SES4B;
typedef A4S_Em#  (64, 8, 0, 0) A4SEM8B;
typedef A4S_Es#  (64, 8, 0, 0) A4SES8B;
typedef A4S_Em#  (128,16,0, 0) A4SEM16B;
typedef A4S_Es#  (128,16,0, 0) A4SES16B;
typedef A4S_Em#  (256,32,0, 0) A4SEM32B;
typedef A4S_Es#  (256,32,0, 0) A4SES32B;

typedef struct {
  Bit#(td)  data;
  Bit#(tg)  strb;
  Bit#(th)  keep;
  Bit#(tu)  user;
  Bool      last;
} A4Stream#(numeric type td, numeric type tg, numeric type th, numeric type tu) deriving (Bits, Eq);  
A4Stream#(td,tg,th,tu)  aStrmDflt = A4Stream{data:0,strb:0,keep:0,user:0,last:False};

(* always_ready, always_enabled *)
interface A4StreamMIfc#(numeric type td, numeric type tg, numeric type th, numeric type tu);
  interface BusSend#(A4Stream#(td,tg,th,tu)) strm;
endinterface

(* always_ready, always_enabled *)
interface A4StreamSIfc#(numeric type td, numeric type tg, numeric type th, numeric type tu);
  interface BusRecv#(A4Stream#(td,tg,th,tu)) strm;
endinterface

instance Connectable#(A4StreamMIfc#(td,tg,th,tu), A4StreamSIfc#(td,tg,th,tu));
  module mkConnection#(A4StreamMIfc#(td,tg,th,tu) m, A4StreamSIfc#(td,tg,th,tu) s) (Empty);
    mkConnection(m.strm, s.strm);
  endmodule
endinstance

// Explicit AXI per-signal naming to purposefully to avoid data-structures and have explict AXI names...

(* always_ready *)
interface A4S_Em#(numeric type td, numeric type tg, numeric type th, numeric type tu);  // AXI4-Stream Explicit Master
  (* prefix="", result="TVALID" *)    method Bit#(1)  mTVALID;   
  (* prefix="", enable="TREADY" *)    method Action   sTREADY;
  (* prefix="", result="TDATA"  *)    method Bit#(td) mTDATA;
  (* prefix="", result="TSTRB"  *)    method Bit#(tg) mTSTRB;
  (* prefix="", result="TUSER"  *)    method Bit#(tu) mTUSER;
  (* prefix="", result="TKEEP"  *)    method Bit#(th) mTKEEP;
  (* prefix="", result="TLAST"  *)    method Bit#(1)  mTLAST;   
endinterface

(* always_ready *)
interface A4S_Es#(numeric type td, numeric type tg, numeric type th, numeric type tu);  // AXI4-Stream Explicit Slave
  (* prefix="", enable="TVALID" *)    method Action   mTVALID;
  (* prefix="", result="TREADY" *)    method Bit#(1)  sTREADY;
  (* prefix="", always_enabled  *)    method Action   mTDATA     ((* port="TDATA" *) Bit#(td) arg_data);
  (* prefix="", always_enabled  *)    method Action   mTSTRB     ((* port="TSTRB" *) Bit#(tg) arg_strb);
  (* prefix="", always_enabled  *)    method Action   mTUSER     ((* port="TUSER" *) Bit#(tu) arg_user);
  (* prefix="", always_enabled  *)    method Action   mTKEEP     ((* port="TKEEP" *) Bit#(th) arg_keep);
  (* prefix="", enable="TLAST"  *)    method Action   mTLAST;
endinterface

(* always_ready *)
interface A4S_Eo#(numeric type td, numeric type tg, numeric type th, numeric type tu);  // AXI4-Stream Explicit Observer
  (* prefix="", enable="TVALID" *)    method Action   mTVALID;
  (* prefix="", enable="TREADY" *)    method Action   sTREADY;
  (* prefix="", always_enabled  *)    method Action   mTDATA     ((* port="TDATA" *) Bit#(td) arg_data);
  (* prefix="", always_enabled  *)    method Action   mTSTRB     ((* port="TSTRB" *) Bit#(tg) arg_strb);
  (* prefix="", always_enabled  *)    method Action   mTUSER     ((* port="TUSER" *) Bit#(tu) arg_user);
  (* prefix="", always_enabled  *)    method Action   mTKEEP     ((* port="TKEEP" *) Bit#(th) arg_keep);
  (* prefix="", enable="TLAST"  *)    method Action   mTLAST;
endinterface


// The following modules are used to adapt between an aggregated version of the interface, and a version
// where the individual signal have been separated out. This is useful for modules which must provide the
// "explict" versions of the interface. These modules are practically functions, they are stateless, but use
// DWires to provide the needed conflict freeness...

// Master to Explicit Master
// This module transforms a A4StreamMIfc to a signal-explicit A4L_Em...
module mkA4StreamMtoEm#(A4StreamMIfc#(td,tg,th,tu) arg) (A4S_Em#(td,tg,th,tu));
  Wire#(Bool)      mTRdy_w      <- mkDWire(False);

  // This rule wires the individual Action inputs back onto their respective BusSend and BusRecv channels...
  (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
    arg.strm.ready(mTRdy_w);
  endrule

  method Bit#(1)  mTVALID = pack(arg.strm.valid);
  method Action   sTREADY = mTRdy_w._write(True);
  method Bit#(td) mTDATA  = arg.strm.data.data;
  method Bit#(tg) mTSTRB  = arg.strm.data.strb;
  method Bit#(tu) mTUSER  = arg.strm.data.user;
  method Bit#(th) mTKEEP  = arg.strm.data.keep;
  method Bit#(1)  mTLAST  = pack(arg.strm.data.last);
endmodule

// Slave to Explicit Slave
// This module transforms a A4StreamSIfc to a signal-explicit A4S_Es...
module mkA4StreamStoEs#(A4StreamSIfc#(td,tg,th,tu) arg) (A4S_Es#(td,tg,th,tu));
  Wire#(Bool)      mTVal_w    <- mkDWire(False);
  Wire#(Bool)      mTLast_w   <- mkDWire(False);
  Wire#(Bit#(td))  mTData_w   <- mkDWire(0);
  Wire#(Bit#(tg))  mTStrb_w   <- mkDWire(0);
  Wire#(Bit#(tu))  mTUser_w   <- mkDWire(0);
  Wire#(Bit#(th))  mTKeep_w   <- mkDWire(0);

  // This rule wires the individual Action inputs back onto their respective BusSend and BusRecv channels...
  (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
    arg.strm.valid(mTVal_w);
    arg.strm.data(A4Stream{data:mTData_w, strb:mTStrb_w, user:mTUser_w, keep:mTKeep_w, last:mTLast_w});
  endrule

  method Action   mTVALID  = mTVal_w._write(True);
  method Bit#(1)  sTREADY  = pack(arg.strm.ready);
  method Action   mTDATA   (Bit#(td) arg_data) = mTData_w._write(arg_data);  
  method Action   mTSTRB   (Bit#(tg) arg_strb) = mTStrb_w._write(arg_strb);  
  method Action   mTUSER   (Bit#(tu) arg_user) = mTUser_w._write(arg_user);  
  method Action   mTKEEP   (Bit#(th) arg_keep) = mTKeep_w._write(arg_keep);  
  method Action   mTLAST  = mTLast_w._write(True);

endmodule

instance Connectable#(A4S_Em#(td,tg,th,tu1), A4S_Es#(td,tg,th,tu2)) provisos(Add#(tu1,0,tu2));
  module mkConnection#(A4S_Em#(td,tg,th,tu1) m, A4S_Es#(td,tg,th,tu2) s) (Empty);
    (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
      if (unpack(m.mTVALID)) s.mTVALID;
      if (unpack(s.sTREADY)) m.sTREADY;
      s.mTDATA(m.mTDATA);
      s.mTSTRB(m.mTSTRB);
      s.mTUSER(m.mTUSER);
      s.mTKEEP(m.mTKEEP);
      if (unpack(m.mTLAST)) s.mTLAST;
    endrule
  endmodule
endinstance

endpackage: ARAXI4S
