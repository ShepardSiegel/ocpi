// ARAXI4L Atomic Rules - AXI4-Lite Implementation
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package ARAXI4L;

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

typedef struct {
  Bool isInstruction;  // 0=data access;   1=instruction access
  Bool isNonSecure;    // 0=secure access; 1=nonsecure access
  Bool isPrivileged;   // 0=normal access; 1=privileged access
 } A4Prot deriving (Bits, Eq);
A4Prot aProtDflt = A4Prot{isInstruction:False, isNonSecure:False, isPrivileged:False};

typedef enum {OKAY, EXOKAY, SLVERR, DECERR} A4Resp deriving (Bits, Eq);  // Used for Read and Write Response

typedef struct {   // Used for both the Write- and Read- Address channels...
  A4Prot    prot;
  Bit#(32)  addr;
} A4LAddrCmd deriving (Bits, Eq);  
A4LAddrCmd  aAddrCmdDflt = A4LAddrCmd{addr:'0,prot:aProtDflt}; 

typedef struct {   // Used for the Write-Data channel...
  Bit#(4)  strb;
  Bit#(32) data;
} A4LWrData deriving (Bits, Eq);
A4LWrData  aWrDataDflt = A4LWrData{strb:'0,data:'0}; 

typedef struct {   // Used for the Write-Response channel...
  A4Resp  resp;
} A4LWrResp deriving (Bits, Eq);
A4LWrResp  aWrRespDflt = A4LWrResp{resp:OKAY}; 

typedef struct {   // Used for the Read-Response channel...
  A4Resp   resp;
  Bit#(32) data;
} A4LRdResp deriving (Bits, Eq);
A4LRdResp  aRdRespDflt = A4LRdResp{resp:OKAY, data:'0}; 

(* always_ready, always_enabled *)
interface A4LMIfc;
  interface BusSend#(A4LAddrCmd) wrAddr; // (AW) Write Address
  interface BusSend#(A4LWrData)  wrData; // (W)  Write Data
  interface BusRecv#(A4LWrResp)  wrResp; // (B)  Write Response
  interface BusSend#(A4LAddrCmd) rdAddr; // (AR) Read Address
  interface BusRecv#(A4LRdResp)  rdResp; // (R)  Read Response
endinterface

(* always_ready, always_enabled *)
interface A4LSIfc;
  interface BusRecv#(A4LAddrCmd) wrAddr;
  interface BusRecv#(A4LWrData)  wrData;
  interface BusSend#(A4LWrResp)  wrResp;
  interface BusRecv#(A4LAddrCmd) rdAddr;
  interface BusSend#(A4LRdResp)  rdResp;
endinterface

instance Connectable#(A4LMIfc, A4LSIfc);
  module mkConnection#(A4LMIfc m, A4LSIfc s) (Empty);
    mkConnection(m.wrAddr, s.wrAddr);
    mkConnection(m.wrData, s.wrData);
    mkConnection(s.wrResp, m.wrResp);
    mkConnection(m.rdAddr, s.rdAddr);
    mkConnection(s.rdResp, m.rdResp);
  endmodule
endinstance

// Explicit AXI per-signal naming to purposefully to avoid data-structures and have explict AXI names...

(* always_ready *)
interface A4L_Em;  // AXI4-Lite Explicit Master
  (* prefix="", result="AWVALID" *)        method Bit#(1)  mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", enable="AWREADY" *)        method Action   sAWREADY;
  (* prefix="", result="AWADDR"  *)        method Bit#(32) mAWADDR;
  (* prefix="", result="AWPROT"  *)        method Bit#(3)  mAWPROT;

  (* prefix="", result="WVALID"  *)        method Bit#(1)  mWVALID;      // (W) Write Data Channel...
  (* prefix="", enable="WREADY"  *)        method Action   sWREADY;
  (* prefix="", result="WDATA"   *)        method Bit#(32) mWDATA;
  (* prefix="", result="WSTRB"   *)        method Bit#(4)  mWSTRB;

  (* prefix="", enable="BVALID"  *)        method Action   sBVALID;      // (B) Write Response Channel...
  (* prefix="", result="BREADY"  *)        method Bit#(1)  mBREADY;
  (* prefix="", always_enabled   *)        method Action   sBRESP        ((* port="BRESP" *) Bit#(2)  arg_wresp);

  (* prefix="", result="ARVALID" *)        method Bit#(1)  mARVALID;     // (AR) Read Address Channel...
  (* prefix="", enable="ARREADY" *)        method Action   sARREADY;
  (* prefix="", result="ARADDR"  *)        method Bit#(32) mARADDR;
  (* prefix="", result="ARPROT"  *)        method Bit#(3)  mARPROT;

  (* prefix="", enable="RVALID"  *)        method Action   sRVALID;      // (R) Read Response Channel...
  (* prefix="", result="RREADY"  *)        method Bit#(1)  mRREADY;
  (* prefix="", always_enabled   *)        method Action   sRDATA        ((* port="RDATA" *) Bit#(32) arg_rdata);
  (* prefix="", always_enabled   *)        method Action   sRRESP        ((* port="RRESP" *) Bit#(2)  arg_rresp);
endinterface

(* always_ready *)
interface A4L_Es;  // AXI4-Lite Explicit Slave
  (* prefix="", enable="AWVALID" *)        method Action   mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", result="AWREADY" *)        method Bit#(1)  sAWREADY;
  (* prefix="", always_enabled   *)        method Action   mAWADDR       ((* port="AWADDR" *) Bit#(32) arg_waddr);
  (* prefix="", always_enabled   *)        method Action   mAWPROT       ((* port="AWPROT" *) Bit#(3)  arg_wprot);

  (* prefix="", enable="WVALID"  *)        method Action   mWVALID;      // (W) Write Data Channel...
  (* prefix="", result="WREADY"  *)        method Bit#(1)  sWREADY;
  (* prefix="", always_enabled   *)        method Action   mWDATA        ((* port="WDATA" *) Bit#(32) arg_wdata);
  (* prefix="", always_enabled   *)        method Action   mWSTRB        ((* port="WSTRB" *) Bit#(4)  arg_wstrb);

  (* prefix="", result="BVALID"  *)        method Bit#(1)  sBVALID;      // (B) Write Response Channel...
  (* prefix="", enable="BREADY"  *)        method Action   mBREADY;
  (* prefix="", result="BRESP"   *)        method Bit#(2)  sBRESP;

  (* prefix="", enable="ARVALID" *)        method Action   mARVALID;     // (AR) Read Address Channel...
  (* prefix="", result="ARREADY" *)        method Bit#(1)  sARREADY;
  (* prefix="", always_enabled   *)        method Action   mARADDR       ((* port="ARADDR" *) Bit#(32) arg_raddr);
  (* prefix="", always_enabled   *)        method Action   mARPROT       ((* port="ARPROT" *) Bit#(3)  arg_rprot);

  (* prefix="", result="RVALID"  *)        method Bit#(1)  sRVALID;      // (R) Read Response Channel...
  (* prefix="", enable="RREADY"  *)        method Action   mRREADY;
  (* prefix="", result="RDATA"   *)        method Bit#(32) sRDATA;
  (* prefix="", result="RRESP"   *)        method Bit#(2)  sRRESP;
endinterface


(* always_ready *)
interface A4L_Eo;  // AXI4-Lite Explicit Observer
  (* prefix="", enable="AWVALID" *)        method Action   mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", enable="AWREADY" *)        method Action   sAWREADY;
  (* prefix="", always_enabled   *)        method Action   mAWADDR       ((* port="AWADDR" *) Bit#(32) arg_waddr);
  (* prefix="", always_enabled   *)        method Action   mAWPROT       ((* port="AWPROT" *) Bit#(3)  arg_wprot);

  (* prefix="", enable="WVALID"  *)        method Action   mWVALID;      // (W) Write Data Channel...
  (* prefix="", enable="WREADY"  *)        method Action   sWREADY;
  (* prefix="", always_enabled   *)        method Action   mWDATA        ((* port="WDATA" *) Bit#(32) arg_wdata);
  (* prefix="", always_enabled   *)        method Action   mWSTRB        ((* port="WSTRB" *) Bit#(4)  arg_wstrb);

  (* prefix="", enable="BVALID"  *)        method Action   sBVALID;      // (B) Write Response Channel...
  (* prefix="", enable="BREADY"  *)        method Action   mBREADY;
  (* prefix="", always_enabled   *)        method Action   sBRESP        ((* port="BRESP" *) Bit#(2)  arg_wresp);

  (* prefix="", enable="ARVALID" *)        method Action   mARVALID;     // (AR) Read Address Channel...
  (* prefix="", enable="ARREADY" *)        method Action   sARREADY;
  (* prefix="", always_enabled   *)        method Action   mARADDR       ((* port="ARADDR" *) Bit#(32) arg_raddr);
  (* prefix="", always_enabled   *)        method Action   mARPROT       ((* port="ARPROT" *) Bit#(3)  arg_rprot);

  (* prefix="", result="RVALID"  *)        method Action   sRVALID;      // (R) Read Response Channel...
  (* prefix="", enable="RREADY"  *)        method Action   mRREADY;
  (* prefix="", always_enabled   *)        method Action   sRDATA        ((* port="RDATA" *) Bit#(32) arg_rdata);
  (* prefix="", always_enabled   *)        method Action   sRRESP        ((* port="RRESP" *) Bit#(2)  arg_rresp);
endinterface


// The following modules are used to adapt between an aggregated version of the interface, and a version
// where the individual signal have been separated out. This is useful for modules which must provide the
// "explict" versions of the interface. These modules are practically functions, their stateless, but use
// DWires to provide the needed conflict freeness...

// Master to Explicit Master
// This module transforms a A4LMIfc to a signal-explicit A4L_Em...
module mkA4MtoEm#(A4LMIfc arg) (A4L_Em);
  Wire#(Bool)      wrAddrRdy_w      <- mkDWire(False);
  Wire#(Bool)      wrDataRdy_w      <- mkDWire(False);
  Wire#(Bool)      wrRespVal_w      <- mkDWire(False);
  Wire#(Bool)      rdAddrRdy_w      <- mkDWire(False);
  Wire#(Bool)      rdRespVal_w      <- mkDWire(False);
  Wire#(Bit#(2))   wrResp_w         <- mkDWire(0);
  Wire#(Bit#(32))  rdData_w         <- mkDWire(0);
  Wire#(Bit#(2))   rdResp_w         <- mkDWire(0);

  // This rule wires the individual Action inputs back onto their respective BusSend and BusRecv channels...
  (* no_implicit_conditions, fire_when_enabled *) rule doAlways (True);
    arg.wrAddr.ready(wrAddrRdy_w);
    arg.wrData.ready(wrDataRdy_w);
    arg.wrResp.valid(wrRespVal_w);
    arg.rdAddr.ready(rdAddrRdy_w);
    arg.rdResp.valid(rdRespVal_w);
    arg.wrResp.data(A4LWrResp{               resp:unpack(wrResp_w)});
    arg.rdResp.data(A4LRdResp{data:rdData_w, resp:unpack(rdResp_w)});
  endrule

  method Bit#(1)  mAWVALID = pack(arg.wrAddr.valid);
  method Action   sAWREADY = wrAddrRdy_w._write(True);
  method Bit#(32) mAWADDR  = arg.wrAddr.data.addr;
  method Bit#(3)  mAWPROT  = pack(arg.wrAddr.data.prot);   

  method Bit#(1)  mWVALID  = pack(arg.wrData.valid);
  method Action   sWREADY  = wrDataRdy_w._write(True);
  method Bit#(32) mWDATA   = arg.wrData.data.data;
  method Bit#(4)  mWSTRB   = arg.wrData.data.strb;

  method Action   sBVALID  = wrRespVal_w._write(True);
  method Bit#(1)  mBREADY  = pack(arg.wrResp.ready);
  method Action   sBRESP   (Bit#(2)  arg_wresp) = wrResp_w._write(arg_wresp);

  method Bit#(1)  mARVALID = pack(arg.rdAddr.valid);
  method Action   sARREADY = rdAddrRdy_w._write(True);
  method Bit#(32) mARADDR  = arg.rdAddr.data.addr;
  method Bit#(3)  mARPROT  = pack(arg.rdAddr.data.prot);   

  method Action   sRVALID  = rdRespVal_w._write(True);
  method Bit#(1)  mRREADY  = pack(arg.rdResp.ready);
  method Action   sRDATA   (Bit#(32) arg_rdata) = rdData_w._write(arg_rdata);
  method Action   sRRESP   (Bit#(2)  arg_rresp) = rdResp_w._write(arg_rresp);
endmodule

// Slave to Explicit Slave
// This module transforms a A4LSIfc to a signal-explicit A4L_Es...
module mkA4StoEs#(A4LSIfc arg) (A4L_Es);
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

endpackage: ARAXI4L
