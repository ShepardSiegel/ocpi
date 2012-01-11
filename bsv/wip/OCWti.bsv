// OCWti.bsv - OpenCPI Worker Time Interface (WTI)
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWti;

import OCWipDefs::*;

import Clocks::*;
import DefaultValue::*;
import GetPut::*;
import ConfigReg::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import SpecialFIFOs::*;
import Connectable::*;
import FShow::*;
import TieOff::*;

// WIP::WTI Attributes...
typedef struct {
  UInt#(32) secondsWidth;   // Width in bits/wires of whole seconds of GPS time
  UInt#(32) fractionWidth;  // Width in bits/wires of fractuonal seconds of GPS time
  Bool allowUnavailable;    // True means worker prepared for time being unavailable
} WtiAttributes deriving (Bits, Eq);

instance DefaultValue#(WtiAttributes);
 defaultValue = WtiAttributes {
  secondsWidth     : 32,
  fractionWidth    : 0,
  allowUnavailable : False
  };
endinstance

// 
// Worker Time Interface (WTI)...
// 
// nd - number of bits in MData (sum of timeInteger and timeFraction)
// 
typedef struct {
  OCP_CMD  cmd;           // IDLE WR RD (non-Idle qualifies group)
  Bit#(nd) data;          // polymorphic data width  (nd)
} WtiReq#(numeric type nd) deriving (Bits, Eq);

WtiReq#(nd) wtiIdleRequest = WtiReq {cmd:IDLE,data:?};

(* always_ready *)
interface Wti_m#(numeric type nd);
  (* result="req" *)                      method WtiReq#(nd) get();
  (* prefix="", enable="SThreadBusy" *)   method Action sThreadBusy;
  (* prefix="", enable="SReset_n"*)       method Action sReset_n;
endinterface

(* always_ready *)
interface Wti_s#(numeric type nd);
  (* prefix="", always_enabled *)         method Action put(WtiReq#(nd) req);
  (* prefix="", result="SThreadBusy" *)   method Bool sThreadBusy;
  (* prefix="", result="SReset_n"*)       method Bool   sReset_n;
endinterface

// Explicit OCP per-signal naming to purposefully to avoid data-structures and have explict OCP names...
interface Wti_Em#(numeric type nd);
  (* prefix="", result="MCmd" *)          method Bit#(3)  mCmd;
  (* prefix="", result="MData" *)         method Bit#(nd) mData;
  (* prefix="", enable="SThreadBusy" *)   method Action   sThreadBusy;
  (* prefix="", enable="SReset_n"*)       method Action   sReset_n;
endinterface

(* always_ready *)
interface Wti_Es#(numeric type nd);
  (* prefix="", always_enabled *)         method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", always_enabled *)         method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", result="SThreadBusy" *)   method Bool     sThreadBusy;
  (* prefix="", result="SReset_n"*)       method Bool     sReset_n;
endinterface

(* always_ready *)
interface Wti_Eo#(numeric type nd);
  (* prefix="", always_enabled *)         method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", always_enabled *)         method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", enable="SThreadBusy" *)   method Action   sThreadBusy;
  (* prefix="", enable="SReset_n"*)       method Action   sReset_n;
endinterface
//
// The Four Connectable M/S instances..
// Connect an Explicitly-named master to an Explicitly-named slave...
instance Connectable#( Wti_Em#(nd), Wti_Es#(nd) );
  module mkConnection#(Wti_Em#(nd) master , Wti_Es#(nd) slave ) (Empty);
    rule mCmdConnect;    slave.mCmd(master.mCmd);                    endrule 
    rule mDataConnect;   slave.mData(master.mData);                  endrule 
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;         endrule
    rule sRstConnect (slave.sReset_n);  master.sReset_n;             endrule
  endmodule
endinstance

// Connect a "conventional" master to an Explicitly-named slave...
instance Connectable#( Wti_m#(nd), Wti_Es#(nd) );
  module mkConnection#(Wti_m#(nd) master , Wti_Es#(nd) slave ) (Empty);
    rule mCmdConnect;    slave.mCmd(pack(master.get.cmd));              endrule 
    rule mDataConnect;   slave.mData(master.get.data);                  endrule 
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;            endrule
    rule sRstConnect (slave.sReset_n);  master.sReset_n;                endrule
  endmodule
endinstance

// Connect an Explicitly-named master to a "conventional" slave...
instance Connectable#( Wti_Em#(nd), Wti_s#(nd) );
  module mkConnection#(Wti_Em#(nd) master , Wti_s#(nd) slave ) (Empty);
    rule reqConnect;
      WtiReq#(nd) req = WtiReq {
         cmd          : unpack(master.mCmd),
         data         : master.mData};
      slave.put(req);
    endrule
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;  endrule
    rule sRstConnect (slave.sReset_n);   master.sReset_n;     endrule
  endmodule
endinstance

// Connect a "conventional" master to a "conventional" slave
instance Connectable#( Wti_m#(nd), Wti_s#(nd) );
  module mkConnection#(Wti_m#(nd) master , Wti_s#(nd) slave ) (Empty);
    rule reqConnect; slave.put(master.get());                endrule
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy; endrule
    rule sRstConnect (slave.sReset_n);  master.sReset_n;     endrule
  endmodule
endinstance


//
// The Four function/module permutations are used to expand/collapse Masters and Slaves...
// This permutation trasforms Wti_Em to Wti_m...
function Wti_m#(nd) toWtiM(Wti_Em#(nd) arg);
  WtiReq#(nd) req = WtiReq {
     cmd          : unpack(arg.mCmd),
     data         : arg.mData};
  return ( Wti_m {get:req, sThreadBusy:arg.sThreadBusy, sReset_n:arg.sReset_n} );
endfunction

// This permutation trasforms Wti_m to Wti_Em...
function Wti_Em#(nd) toWtiEM(Wti_m#(nd) arg);
  return ( Wti_Em {
     mCmd          : pack(arg.get.cmd),
     mData         : arg.get.data,
     sThreadBusy  : arg.sThreadBusy,
     sReset_n     : arg.sReset_n} );
endfunction

// This permutation trasforms Wti_Es to Wti_s...
function Wti_s#(nd) toWtiS(Wti_Es#(nd) arg);
  return (interface Wti_s;
    method Action put(WtiReq#(nd) req);
      arg.mCmd         (pack(req.cmd));
      arg.mData        (req.data);
    endmethod
    method     sThreadBusy = arg.sThreadBusy;
    method        sReset_n = arg.sReset_n;
  endinterface);
endfunction

// Credit: Hadar - This module's signature nearly looks like the function we cant write...
module mkWtiStoES#(Wti_s#(nd) arg) ( Wti_Es#(nd));
  Wire#(Bit#(3))   mCmd_w           <- mkDWire(0);
  Wire#(Bit#(nd))  mData_w          <- mkDWire(0);

  rule doAlways;
     WtiReq#(nd)req = WtiReq {
       cmd          : unpack(mCmd_w),
       data         : mData_w
    };
    arg.put(req);
  endrule

  method Action  mCmd(in)         = mCmd_w._write(in);
  method Action  mData(x)         = mData_w        ._write(x);
  method     sThreadBusy = arg.sThreadBusy;
  method        sReset_n = arg.sReset_n;
endmodule


//
// WtiMaster is convienience IP for OpenCPI that implements WTI Master Role
//
interface WtiMasterIfc#(numeric type nd);
  interface Put#(WtiReq#(nd)) reqPut;
  interface Wti_m#(nd)        mas;
endinterface

module mkWtiMaster (WtiMasterIfc#(nd));
  Reg#(WtiReq#(nd))           nowReq          <- mkReg(unpack(0));
  PulseWire                   sThreadBusy_pw  <- mkPulseWire;
  Reg#(Bool)                  sThreadBusy_d   <- mkReg(True);
  Reg#(Bool)                  peerIsReady     <- mkDReg(False);

  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule

  interface Wti_m mas;
    method WtiReq#(nd) get = sThreadBusy_d ? wtiIdleRequest : nowReq;
    method Action sThreadBusy = sThreadBusy_pw.send;
    method Action sReset_n = peerIsReady._write(True);
  endinterface
  interface reqPut = toPut(asReg(nowReq));
endmodule

//
// WtiSlave is convienience IP for OpenCPI that implements the WTI Slave Role
//
interface WtiSlaveIfc#(numeric type nd);
  interface Wti_s#(nd)        slv;
  interface Get#(WtiReq#(nd)) reqGet;
  method         Bit#(nd)  now;
endinterface

module mkWtiSlave (WtiSlaveIfc#(nd));
  Wire#(WtiReq#(nd))          wtiReq    <- mkWire;
  Reg#(WtiReq#(nd))           nowReq    <- mkReg(unpack(0));
  ReadOnly#(Bool)             isReset   <- isResetAsserted;
  Reg#(Bool)                  operateD  <- mkDReg(True);

  interface Wti_s slv;
    method Action put(WtiReq#(nd) req) = nowReq._write(req);
    method sThreadBusy = (isReset);
    method sReset_n = !(isReset || !operateD);
  endinterface
  interface reqGet  = toGet(nowReq);
  method    now = nowReq.data;
endmodule

endpackage: OCWti
