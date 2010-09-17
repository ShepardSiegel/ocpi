// ARAXI4L Atomic Rules - AXI4-Lite Implementation
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package ARAXI4L;

import Bus::*;
import Connectable::*;
import DefaultValue::*;
import FShow::*;
import GetPut::*;
import TieOff::*;
import Vector::*;

typedef struct {
  Bool isInstruction;  // 0=data access;   1=instruction access
  Bool isNonSecure;    // 0=secure access; 1=nonsecure access
  Bool isPrivileged;   // 0=normal access; 1=privileged access
 } A4Prot deriving (Bits, Eq);
A4Prot aProtDflt = A4Prot{isInstruction:False, isNonSecure:False, isPrivileged:False};

typedef enum {OKAY, EXOCKAY, SLVERR, DECERR} A4Resp deriving (Bits, Eq);  // Used for Read and Write Response

typedef struct {   // Used for both the Write- and Read- Address channels...
  A4Prot    prot;
  Bit#(20)  addr;
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

interface A4LMIfc;
  interface BusSend#(A4LAddrCmd) wrAddr;
  interface BusSend#(A4LWrData)  wrData;
  interface BusRecv#(A4LWrResp)  wrResp;
  interface BusSend#(A4LAddrCmd) rdAddr;
  interface BusRecv#(A4LRdResp)  rdResp;
endinterface

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


endpackage: ARAXI4L
