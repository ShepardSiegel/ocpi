// OCWciAxi.bsv - OpenCPI Worker Control Interface (WCI::AXI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWciAxi;

import OCWci::*;
import OCWipDefs::*;

import Bus::*;
import Clocks::*;
import GetPut::*;
import ConfigReg::*;
import DefaultValue::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import SpecialFIFOs::*;
import Connectable::*;
import FShow::*;
import TieOff::*;


// WCI::AXI Specific...

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

// WCI::AXI Master and Slave Interfaces...

(* always_ready, always_enabled *)
interface WciAxi_m;
  interface BusSend#(A4LAddrCmd) wrAddr;  // (AW) Write Address  Channel
  interface BusSend#(A4LWrData)  wrData;  // (W)  Write Data     Channel
  interface BusRecv#(A4LWrResp)  wrResp;  // (B)  Write Response Channel
  interface BusSend#(A4LAddrCmd) rdAddr;  // (AR) Read  Address  Channel
  interface BusRecv#(A4LRdResp)  rdResp;  // (R)  Read  Response Channel
endinterface

(* always_ready, always_enabled *)
interface WciAxi_s;
  interface BusRecv#(A4LAddrCmd) wrAddr;  // (AW) Write Address  Channel
  interface BusRecv#(A4LWrData)  wrData;  // (W)  Write Data     Channel
  interface BusSend#(A4LWrResp)  wrResp;  // (B)  Write Response Channel
  interface BusRecv#(A4LAddrCmd) rdAddr;  // (AR) Read  Address  Channel
  interface BusSend#(A4LRdResp)  rdResp;  // (R)  Read  Response Channel
endinterface

// Explicit WCI::AXI per-signal naming to purposefully to avoid data-structures and have explict WCI::AXI names...

(* always_ready *)
interface WciAxi_Em;
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

  interface Reset mReset_n;
endinterface

(* always_ready *)
interface WciAxi_Es;
  (* prefix="", enable="AWVALID" *)        method Bit#(1)  mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", result="AWREADY" *)        method Action   sAWREADY;
  (* prefix="", always_enabled   *)        method Action   mAWADDR       ((* port="AWADDR" *) Bit#(32) arg_waddr);
  (* prefix="", always_enabled   *)        method Action   mAWPROT       ((* port="AWPROT" *) Bit#(3)  arg_wprot);

  (* prefix="", enable="WVALID"  *)        method Bit#(1)  mWVALID;      // (W) Write Data Channel...
  (* prefix="", result="WREADY"  *)        method Action   sWREADY;
  (* prefix="", always_enabled   *)        method Action   mWDATA        ((* port="WDATA" *) Bit#(32) arg_wdata);
  (* prefix="", always_enabled   *)        method Action   mWSTRB        ((* port="WSTRB" *) Bit#(4)  arg_wstrb);

  (* prefix="", result="BVALID"  *)        method Bit#(1)  sBVALID;      // (B) Write Response Channel...
  (* prefix="", enable="BREADY"  *)        method Action   mBREADY;
  (* prefix="", result="BRESP"   *)        method Bit#(2)  sBRESP;

  (* prefix="", enable="ARVALID" *)        method Bit#(1)  mARVALID;     // (AR) Read Address Channel...
  (* prefix="", result="ARREADY" *)        method Action   sARREADY;
  (* prefix="", always_enabled   *)        method Action   mARADDR       ((* port="ARADDR" *) Bit#(32) arg_raddr);
  (* prefix="", always_enabled   *)        method Action   mARPROT       ((* port="ARPROT" *) Bit#(3)  arg_rprot);

  (* prefix="", result="RVALID"  *)        method Bit#(1)  sRVALID;      // (R) Read Response Channel...
  (* prefix="", enable="RREADY"  *)        method Action   mRREADY;
  (* prefix="", result="RDATA"   *)        method Bit#(32) sRDATA;
  (* prefix="", result="RRESP"   *)        method Bit#(2)  sRRESP;
endinterface


instance Connectable#(WciAxi_m, WciAxi_s);
  module mkConnection#(WciAxi_m m, WciAxi_s s) (Empty);
    mkConnection(m.wrAddr, s.wrAddr);
    mkConnection(m.wrData, s.wrData);
    mkConnection(s.wrResp, m.wrResp);
    mkConnection(m.rdAddr, s.rdAddr);
    mkConnection(s.rdResp, m.rdResp);
  endmodule
endinstance


endpackage: OCWciAxi
