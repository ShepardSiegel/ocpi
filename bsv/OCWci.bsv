// OCWci.bsv - OpenCPI Worker Control Interface (WCI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

// This package contains the code that is common to WCI::{OCP,AXI,etc} implementations
// It should contain the WCI higher-level attributes; not the protocol-specific bits
// It will typically be imported by the protocol-specific packages for its common WCI abstraction

package OCWci;

import Clocks::*;
import ClientServer::*;
import GetPut::*;
import DefaultValue::*;
import Connectable::*;
import FShow::*;
import TieOff::*;

// WIP::WCI Attributes...
typedef struct {
  UInt#(32) sizeOfConfigSpace;     // Size in Bytes of config property space
  Bool writableConfigProperties;   // True if writable properties
  Bool readableConfigProperties;   // True if readable properties
  Bool sub32bitConfigProperties;   // True if properties smaller than 4B
  Bool resetWhileSuspended;        // True if worker will remain functional when adjacent reset when SUSPENDED
} WciAttributes deriving (Bits, Eq);

instance DefaultValue#(WciAttributes);
 defaultValue = WciAttributes {
  sizeOfConfigSpace         : 0,
  writableConfigProperties  : False,
  readableConfigProperties  : False,
  sub32bitConfigProperties  : False,
  resetWhileSuspended       : False
  };
endinstance

//
// Worker Control Interface (WCI)...
//
// control ops are the edges, states are the nodes...
typedef enum {Initialize,Start,Stop,Release,Test,BeforeQuery,AfterConfig,ReqAttn} WCI_CONTROL_OP deriving (Bits, Eq);
typedef enum {Exists,Initialized,Operating,Suspended,Unusable,Rsvd5,Rsvd6,Rsvd7}  WCI_STATE deriving (Bits, Eq);
typedef enum {Write, Read, WriteNP, Rsvd3} WCI_CONFIG_REQ deriving (Bits, Eq);
typedef enum {None, CfgWt, CfgRd, CtlOp}   WCI_REQ        deriving (Bits, Eq);
typedef enum {OK, Error, Timeout, Rsvd3}   WCI_RESP       deriving (Bits, Eq);
typedef enum {Admin, Control, Config}      WCI_SPACE      deriving (Bits, Eq);
typedef struct { Bool cfgWt; Bool cfgRd; Bool ctlOp;} ReqTBits deriving (Bits, Eq);

// BSV Feature Request: Would be nice if there was a way to suck enum or struct member names out
// so that instances like the two that follow are not needed...

instance FShow#(WCI_CONTROL_OP);
  function Fmt fshow (WCI_CONTROL_OP cop);
    case (cop)
      Initialize:  return fshow("Initialize ");
      Start:       return fshow("Start ");
      Stop:        return fshow("Stop ");
      Release:     return fshow("Release ");
      Test:        return fshow("Test ");
      BeforeQuery: return fshow("BeforeQuery ");
      AfterConfig: return fshow("AfterConfig ");
      ReqAttn:     return fshow("ReqAttn ");
    endcase
  endfunction
endinstance

instance FShow#(WCI_STATE);
  function Fmt fshow (WCI_STATE state);
    case (state)
      Exists:      return fshow("Exists ");
      Initialized: return fshow("Initialized ");
      Operating:   return fshow("Operating ");
      Suspended:   return fshow("Suspended ");
      Unusable:    return fshow("Unusable ");
      Rsvd5:       return fshow("Rsvd5 ");
      Rsvd6:       return fshow("Rsvd6 ");
      Rsvd7:       return fshow("Rsvd7 ");
    endcase
  endfunction
endinstance

//WCI::{OCP|AXI} Agnostic... 

typedef struct {
  WCI_CONFIG_REQ req;     // WCI Configuration Request Operation Type
  Bit#(4)        be;      // 1=byte lane enabled
  Bit#(32)       addr;    // Byte Address
  Bit#(32)       data;    // One DWord
} WciConfigReq deriving (Bits, Eq);

typedef union tagged {
  WCI_CONTROL_OP ControlOp;
  WciConfigReq   ConfigReq;
} WciRequest deriving (Bits);

typedef struct {
  WCI_RESP resp;          // WCI Response
} WciRaw deriving (Bits, Eq);

typedef struct {
  WCI_RESP resp;          // WCI Response
  Bit#(32) data;          // One DWord
} WciResp deriving (Bits, Eq);

typedef union tagged {
  WciRaw     RawResponse;
  WciResp    ReadResponse;
} WciResponse deriving (Bits);

WciResp wciOKResponse      = WciResp{resp:OK,      data:32'hC0DE_4201}; // OK
WciResp wciErrorResponse   = WciResp{resp:Error,   data:32'hC0DE_4202}; // Error
WciResp wciTimeoutResponse = WciResp{resp:Timeout, data:32'hC0DE_4203}; // Timeout
WciResp wciResetResponse   = WciResp{resp:OK,      data:32'hC0DE_4204}; // Reset

function WciRequest wciConfigWrite(Bit#(32) addr, Bit#(32) data, Bit#(4) be);
  let configReq = WciConfigReq {req:Write, be:be, addr:addr, data:data};
  return(tagged ConfigReq configReq);
endfunction

function WciRequest wciConfigRead(Bit#(32) addr);
  let configReq = WciConfigReq {req:Read, be:'0, addr:addr, data:'0 };
  return(tagged ConfigReq configReq);
endfunction

interface WciInitiator;                          // WCI Initiator, Protocol Independent
  interface Server#(WciRequest,WciResponse)  wciInit;    // WCI Request/Response 
  method Bool                        attention;  // True indicates worker/target attention
  method Bool                        present;    // True indicates worker/target present
endinterface

interface WciTarget;                             // WCI Target, Protocol Independent
  interface Client#(WciRequest,WciResponse)  wciTarg;    // WCI Request/Response
  method Action                      attention;  // True to signal attention
  method Action                      present;    // True to signal present
endinterface

endpackage: OCWci
