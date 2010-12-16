// OCWti.bsv - OpenCPI Worker Time Interface (WTI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

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
endinterface

(* always_ready *)
interface Wti_s#(numeric type nd);
  (* prefix="", always_enabled *)         method Action put(WtiReq#(nd) req);
  (* prefix="", result="SThreadBusy" *)   method Bool sThreadBusy;
endinterface

instance Connectable#( Wti_m#(nd), Wti_s#(nd) );
  module mkConnection#(Wti_m#(nd) master , Wti_s#(nd) slave ) ();
    rule reqConnect; slave.put(master.get()); endrule
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy; endrule
  endmodule
endinstance

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

  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule

  interface Wti_m mas;
    method WtiReq#(nd) get = sThreadBusy_d ? wtiIdleRequest : nowReq;
    method Action sThreadBusy = sThreadBusy_pw.send;
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

  interface Wti_s slv;
    method Action put(WtiReq#(nd) req) = nowReq._write(req);
    method sThreadBusy = (isReset);
  endinterface
  interface reqGet  = toGet(nowReq);
  method    now = nowReq.data;
endmodule

endpackage: OCWti
