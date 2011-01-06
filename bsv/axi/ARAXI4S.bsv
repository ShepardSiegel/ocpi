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
// td - number of bits in data 
// tg - number of bits in strobe
// th - number of bits in keep

typedef struct {
  Bit#(td)  data;
  Bit#(tg)  strb;
  Bit#(th)  keep;
  Bool      last;
} A4Stream#(numeric type td, numeric type tg, numeric type th) deriving (Bits, Eq);  
A4Stream  aStrmDflt = A4Stream{data:0,strb:0,keep:0,last:False};

(* always_ready, always_enabled *)
interface A4StreamMIfc;
  interface BusSend#(A4Stream) strm;
endinterface

(* always_ready, always_enabled *)
interface A4StreamSIfc;
  interface BusRecv#(A4Stream) strm;
endinterface

instance Connectable#(A4StreamMIfc, A4StreamSIfc);
  module mkConnection#(A4StreamMIfc m, A4StreamSIfc s) (Empty);
    mkConnection(m.strm, s.strm);
  endmodule
endinstance

// Explicit AXI per-signal naming to purposefully to avoid data-structures and have explict AXI names...

(* always_ready *)
interface A4S_Em;  // AXI4-Stream Explicit Master
  (* prefix="", result="TVALID" *)    method Bit#(1)  mTVALID;   
  (* prefix="", enable="TREADY" *)    method Action   sTREADY;
  (* prefix="", result="TDATA"  *)    method Bit#(td) mTDATA;
  (* prefix="", result="TSTRB"  *)    method Bit#(tg) mTSTRB;
  (* prefix="", result="TKEEP"  *)    method Bit#(th) mKEEP;
  (* prefix="", result="TLAST"  *)    method Bit#(1)  mTLAST;   
endinterface

(* always_ready *)
interface A4S_Es;  // AXI4-Stream Explicit Slave
  (* prefix="", enable="TVALID" *)    method Action   mTVALID;
  (* prefix="", result="TREADY" *)    method Bit#(1)  sTREADY;
  (* prefix="", always_enabled  *)    method Action   mTDATA     ((* port="TDATA" *) Bit#(td) arg_data);
  (* prefix="", always_enabled  *)    method Action   mTSTRB     ((* port="TSTRB" *) Bit#(tg) arg_strb);
  (* prefix="", always_enabled  *)    method Action   mTKEEP     ((* port="TKEEP" *) Bit#(th) arg_keep);
  (* prefix="", enable="TLAST" *)     method Action   mTLAST;
endinterface

(* always_ready *)
interface A4S_Eo;  // AXI4-Stream Explicit Observer
  (* prefix="", enable="TVALID" *)    method Action   mTVALID;
  (* prefix="", enable="TREADY" *)    method Action   sTREADY;
  (* prefix="", always_enabled  *)    method Action   mTDATA     ((* port="TDATA" *) Bit#(td) arg_data);
  (* prefix="", always_enabled  *)    method Action   mTSTRB     ((* port="TSTRB" *) Bit#(tg) arg_strb);
  (* prefix="", always_enabled  *)    method Action   mTKEEP     ((* port="TKEEP" *) Bit#(th) arg_keep);
  (* prefix="", enable="TLAST" *)     method Action   mTLAST;
endinterface


// The following modules are used to adapt between an aggregated version of the interface, and a version
// where the individual signal have been separated out. This is useful for modules which must provide the
// "explict" versions of the interface. These modules are practically functions, their stateless, but use
// DWires to provide the needed conflict freeness...

// Master to Explicit Master
// This module transforms a A4StreamMIfc to a signal-explicit A4L_Em...
module mkA4StreamMtoEm#(A4StreamMIfc arg) (A4S_Em);
  Wire#(Bool)      mTRdy_w      <- mkDWire(False);

  // This rule wires the individual Action inputs back onto their respective BusSend and BusRecv channels...
  (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
    arg.strm.ready(mTRdy_w);
  endrule

  method Bit#(1)  mTVALID = pack(arg.wrAddr.valid);
  method Action   sTREADY = mTRdy_w._write(True);
  method Bit#(td) mTDATA  = arg.strm.data;
  method Bit#(tg) mTSTRB  = arg.strm.strb;
  method Bit#(th) mTKEEP  = arg.strm.keep;
  method Bit#(1)  mTLAST  = pack(arg.strm.last);
endmodule

// Slave to Explicit Slave
// This module transforms a A4StreamSIfc to a signal-explicit A4S_Es...
module mkA4StoEs#(A4StreamSIfc arg) (A4S_Es);
  Wire#(Bool)      wrAddrVal_w      <- mkDWire(False);
  Wire#(Bool)      wrDataVal_w      <- mkDWire(False);
  Wire#(Bool)      wrRespRdy_w      <- mkDWire(False);
  Wire#(Bool)      rdAddrVal_w      <- mkDWire(False);
  Wire#(Bool)      rdRespRdy_w      <- mkDWire(False);
  Wire#(Bit#(32))  wrAddr_w         <- mkDWire(0);
  Wire#(Bit#(3))   wrProt_w         <- mkDWire(0);
  Wire#(Bit#(32))  wrData_w         <- mkDWire(0);
  Wire#(Bit#(4))   wrStrb_w         <- mkDWire(0);
  Wire#(Bit#(32))  rdAddr_w         <- mkDWire(0);
  Wire#(Bit#(3))   rdProt_w         <- mkDWire(0);

  // This rule wires the individual Action inputs back onto their respective BusSend and BusRecv channels...
  (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
    arg.wrAddr.valid(wrAddrVal_w);
    arg.wrData.valid(wrDataVal_w);
    arg.wrResp.ready(wrRespRdy_w);
    arg.rdAddr.valid(rdAddrVal_w);
    arg.rdResp.ready(rdRespRdy_w);
    arg.wrAddr.data(A4LAddrCmd{addr:wrAddr_w, prot:unpack(wrProt_w)});
    arg.wrData.data(A4LWrData {data:wrData_w, strb:wrStrb_w});
    arg.rdAddr.data(A4LAddrCmd{addr:rdAddr_w, prot:unpack(rdProt_w)});
  endrule

  method Action   mAWVALID = wrAddrVal_w._write(True);
  method Bit#(1)  sAWREADY = pack(arg.wrAddr.ready);
  method Action   mAWADDR    (Bit#(32) arg_waddr) = wrAddr_w._write(arg_waddr);
  method Action   mAWPROT    (Bit#(3)  arg_wprot) = wrProt_w._write(arg_wprot);

  method Action   mWVALID  = wrDataVal_w._write(True);
  method Bit#(1)  sWREADY  = pack(arg.wrData.ready);
  method Action   mWDATA     (Bit#(32) arg_wdata) = wrData_w._write(arg_wdata);
  method Action   mWSTRB     (Bit#(4)  arg_wstrb) = wrStrb_w._write(arg_wstrb);

  method Bit#(1)  sBVALID  = pack(arg.wrResp.valid);
  method Action   mBREADY  = wrRespRdy_w._write(True);
  method Bit#(2)  sBRESP   = pack(arg.wrResp.data);

  method Action   mARVALID = rdAddrVal_w._write(True);
  method Bit#(1)  sARREADY = pack(arg.rdAddr.ready);
  method Action   mARADDR   (Bit#(32) arg_raddr) = rdAddr_w._write(arg_raddr);
  method Action   mARPROT   (Bit#(3)  arg_rprot) = rdProt_w._write(arg_rprot);

  method Bit#(1)  sRVALID  = pack(arg.rdResp.valid);
  method Action   mRREADY  = rdRespRdy_w._write(True);
  method Bit#(32) sRDATA   = pack(arg.rdResp.data.data);
  method Bit#(2)  sRRESP   = pack(arg.rdResp.data.resp);
endmodule

instance Connectable#(A4L_Em, A4L_Es);
  module mkConnection#(A4L_Em m, A4L_Es s) (Empty);
    (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
      if (unpack(m.mAWVALID)) s.mAWVALID;
      if (unpack(s.sAWREADY)) m.sAWREADY;
      s.mAWADDR(m.mAWADDR);
      s.mAWPROT(m.mAWPROT);
      if (unpack(m.mWVALID)) s.mWVALID;
      if (unpack(s.sWREADY)) m.sWREADY;
      s.mWDATA(m.mWDATA);
      s.mWSTRB(m.mWSTRB);
      if (unpack(s.sBVALID)) m.sBVALID;
      if (unpack(m.mBREADY)) s.mBREADY;
      m.sBRESP(s.sBRESP);
      if (unpack(m.mARVALID)) s.mARVALID;
      if (unpack(s.sARREADY)) m.sARREADY;
      s.mARADDR(m.mARADDR);
      s.mARPROT(m.mARPROT);
      if (unpack(s.sRVALID)) m.sRVALID;
      if (unpack(m.mRREADY)) s.mRREADY;
      m.sRDATA(s.sRDATA);
      m.sRRESP(s.sRRESP);
    endrule
  endmodule
endinstance

// Convienience IP...
// These two modules encapsulate the five channels used for each AXI4-Lite Master and Slave attachement
// They replace five explict Bus Sender/Receivers with a single module and the same methods
// They allow AXI4-Lite Masters and Slaves FIFO methods on each of the primative channels

interface A4LChannels;
  interface FIFO#(A4LAddrCmd) wrAddr;
  interface FIFO#(A4LWrData)  wrData;
  interface FIFO#(A4LWrResp)  wrResp;
  interface FIFO#(A4LAddrCmd) rdAddr;
  interface FIFO#(A4LRdResp)  rdResp;
endinterface

interface A4LMasterIfc;
  interface A4LMIfc     a4lm;
  interface A4LChannels f;
endinterface

interface A4LSlaveIfc;
  interface A4LSIfc     a4ls;
  interface A4LChannels f;
endinterface

module mkA4LMaster (A4LMasterIfc);
  BusSender#(A4LAddrCmd)    a4wrAddr    <- mkBusSender(aAddrCmdDflt);
  BusSender#(A4LWrData)     a4wrData    <- mkBusSender(aWrDataDflt);
  BusReceiver#(A4LWrResp)   a4wrResp    <- mkBusReceiver;
  BusSender#(A4LAddrCmd)    a4rdAddr    <- mkBusSender(aAddrCmdDflt);
  BusReceiver#(A4LRdResp)   a4rdResp    <- mkBusReceiver;

  interface A4LMIfc a4lm;
    interface BusSend wrAddr = a4wrAddr.out;
    interface BusSend wrData = a4wrData.out;
    interface BusRecv wrResp = a4wrResp.in;
    interface BusSend rdAddr = a4rdAddr.out;
    interface BusRecv rdResp = a4rdResp.in;
  endinterface
  interface A4LChannels f;
    interface FIFO wrAddr = a4wrAddr.in;
    interface FIFO wrData = a4wrData.in;
    interface FIFO wrResp = a4wrResp.out;
    interface FIFO rdAddr = a4rdAddr.in;
    interface FIFO rdResp = a4rdResp.out;
  endinterface
endmodule

module mkA4LSlave (A4LSlaveIfc);
  BusReceiver#(A4LAddrCmd)    a4wrAddr    <- mkBusReceiver;
  BusReceiver#(A4LWrData)     a4wrData    <- mkBusReceiver;
  BusSender#(A4LWrResp)       a4wrResp    <- mkBusSender(aWrRespDflt);
  BusReceiver#(A4LAddrCmd)    a4rdAddr    <- mkBusReceiver;
  BusSender#(A4LRdResp)       a4rdResp    <- mkBusSender(aRdRespDflt);

  interface A4LSIfc a4ls;
    interface BusRecv wrAddr = a4wrAddr.in;
    interface BusRecv wrData = a4wrData.in;
    interface BusSend wrResp = a4wrResp.out;
    interface BusRecv rdAddr = a4rdAddr.in;
    interface BusSend rdResp = a4rdResp.out;
  endinterface
  interface A4LChannels f;
    interface FIFO wrAddr = a4wrAddr.out;
    interface FIFO wrData = a4wrData.out;
    interface FIFO wrResp = a4wrResp.in;
    interface FIFO rdAddr = a4rdAddr.out;
    interface FIFO rdResp = a4rdResp.in;
  endinterface
endmodule

endpackage: ARAXI4S
