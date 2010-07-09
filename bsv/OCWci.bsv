// OCWci.bsv - OpenCPI Worker Control Interface (WCI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWci;

import OCWipDefs::*;

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
typedef enum {Initialize,Start,Stop,Release,Test,BeforeQuery,AfterConfig,Rsvd7} WCI_CONTROL_OP deriving (Bits, Eq);
typedef enum {Exists,Initialized,Operating,Suspended,Unusable,Rsvd5,Rsvd6,Rsvd7}  WCI_STATE deriving (Bits, Eq);
typedef enum {None,CfgWt,CfgRd,CtlOp} WCI_REQ deriving (Bits, Eq);
typedef enum {Admin,Control,Config} WCI_SPACE deriving (Bits, Eq);
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
      Rsvd7:       return fshow("Rsvd7 ");
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


typedef struct {
  OCP_CMD  cmd;           // OCP Command (non-Idle qualifies group)
  Bit#(1)  addrSpace;     // 0=Control; 1=Configuration
  Bit#(4)  byteEn;        // 1=byte lane enabled
  Bit#(na) addr;          // Byte Address, na >=5, typ 16 for 64KB
  Bit#(32) data;          // One DWord
} WciReq#(numeric type na) deriving (Bits, Eq);

typedef struct {
  OCP_RESP resp;          // OCP Response (non-Null qualifies group)
  Bit#(32) data;          // One DWord
} WciResp deriving (Bits, Eq);

WciReq#(na) wciIdleRequest     = WciReq{cmd:IDLE,addrSpace:'0,addr:'0,data:?,byteEn:'0}; 
WciResp     wciIdleResponse    = WciResp{resp:NULL,data:?}; 
WciResp     wciOKResponse      = WciResp{resp:DVA,data:32'hC0DE_4201}; // Ok
WciResp     wciErrorResponse   = WciResp{resp:ERR,data:32'hC0DE_4202}; // Error
WciResp     wciTimeoutResponse = WciResp{resp:DVA,data:32'hC0DE_4203}; // Timeout
WciResp     wciResetResponse   = WciResp{resp:DVA,data:32'hC0DE_4204}; // Reset

(* always_ready *)
interface Wci_m#(numeric type na);
                                        method WciReq#(na) req;
  (* prefix = "", always_enabled*)      method Action  put(WciResp resp);
  (* prefix="", enable="SThreadBusy"*)  method Action  sThreadBusy;
  (* prefix="", enable="SFlag"      *)  method Action  sFlag    (Bit#(2) sf);  //b0=attention; b1=present
  (* prefix="", result="MFlag"      *)  method Bit#(2) mFlag;                  //b0=forceterm; b1=bigendian
  interface Reset mReset_n;
endinterface 

(* always_ready *)
interface Wci_s#(numeric type na);
  (* prefix="", always_enabled *)       method Action  putreq (WciReq#(na) req);
                                        method WciResp resp();
  (* prefix="", result="SThreadBusy"*)  method Bool    sThreadBusy;
  (* prefix="", result="SFlag"      *)  method Bit#(2) sFlag;                              //b0=attention; b1=present
  (* prefix="", always_enabled *)       method Action  mFlag ((*port="MFlag"*)Bit#(2) mf); //b0=forceterm; b1=bigendian
endinterface 

// Explicit OCP per-signal naming to purposefully to avoid data-structures and have explict OCP names...
(* always_ready *)
interface Wci_Em#(numeric type na);
  (* prefix="", result="MCmd" *)           method Bit#(3)  mCmd;
  (* prefix="", result="MAddrSpace" *)     method Bit#(1)  mAddrSpace;
  (* prefix="", result="MByteEn" *)        method Bit#(4)  mByteEn;
  (* prefix="", result="MAddr" *)          method Bit#(na) mAddr;
  (* prefix="", result="MData" *)          method Bit#(32) mData;
  (* prefix="", always_enabled *)          method Action   sResp         ((* port="SResp" *) Bit#(2)  arg_resp);
  (* prefix="", always_enabled *)          method Action   sData         ((* port="SData" *) Bit#(32) arg_data);
  (* prefix="", enable="SThreadBusy" *)    method Action   sThreadBusy;
  (* prefix="", always_enabled *)          method Action   sFlag         ((* port="SFlag"*)  Bit#(2)  arg_sFlag);
  (* prefix="", result="MFlag" *)          method Bit#(2)  mFlag;
  interface Reset mReset_n;
endinterface

(* always_ready *)
interface Wci_Es#(numeric type na);
  (* prefix="", always_enabled *)          method Action   mCmd         ((* port="MCmd" *)        Bit#(3)  arg_cmd);
  (* prefix="", always_enabled *)          method Action   mAddrSpace   ((* port="MAddrSpace" *)  Bit#(1)  arg_addrSpace);
  (* prefix="", always_enabled *)          method Action   mByteEn      ((* port="MByteEn" *)     Bit#(4)  arg_byteEn);
  (* prefix="", always_enabled *)          method Action   mAddr        ((* port="MAddr" *)       Bit#(na) arg_addr);
  (* prefix="", always_enabled *)          method Action   mData        ((* port="MData" *)       Bit#(32) arg_data);
  (* prefix="", result="SResp" *)          method Bit#(2)  sResp;
  (* prefix="", result="SData" *)          method Bit#(32) sData;
  (* prefix="", result="SThreadBusy"*)     method Bool     sThreadBusy;
  (* prefix="", result="SFlag"      *)     method Bit#(2)  sFlag;
  (* prefix="", always_enabled *)          method Action   mFlag       ((* port="MFlag" *)       Bit#(2)  arg_mFlag);
endinterface

//
// The Four Connectable M/S instances..
// Connect a Explicitly-named master to a Explicitly-named slave...
instance Connectable#( Wci_Em#(na), Wci_Es#(na) );
  module mkConnection#(Wci_Em#(na) master , Wci_Es#(na) slave ) ();
    rule mCmdConnect;    slave.mCmd(master.mCmd);                        endrule 
    rule mAddrSConnect;  slave.mAddrSpace(master.mAddrSpace);            endrule 
    rule mBEConnect;     slave.mByteEn(master.mByteEn);                  endrule 
    rule mAddrConnect;   slave.mAddr(master.mAddr);                      endrule 
    rule mDataConnect;   slave.mData(master.mData);                      endrule 
    rule sRespConnect;   master.sResp(slave.sResp);                      endrule 
    rule sDataConnect;   master.sData(slave.sData);                      endrule
    rule stbConnect      (slave.sThreadBusy); master.sThreadBusy;        endrule
    rule sFlagConnect;   master.sFlag(slave.sFlag);                      endrule
    rule mFlagConnect;   slave.mFlag(master.mFlag);                      endrule
  endmodule
endinstance
   
// Connect a "conventional" master to a Explicitly-named slave...
instance Connectable#( Wci_m#(na), Wci_Es#(na) );
  module mkConnection#(Wci_m#(na) master , Wci_Es#(na) slave ) ();
    rule mCmdConnect;    slave.mCmd(pack(master.req.cmd));             endrule 
    rule mAddrSConnect;  slave.mAddrSpace(master.req.addrSpace);       endrule 
    rule mBEConnect;     slave.mByteEn(master.req.byteEn);             endrule 
    rule mAddrConnect;   slave.mAddr(master.req.addr);                 endrule 
    rule mDataConnect;   slave.mData(master.req.data);                 endrule 
    rule respConnect;
      WciResp resp = WciResp {
        resp : unpack(slave.sResp),
        data : slave.sData};
      master.put(resp);
    endrule
    rule stbConnect  (slave.sThreadBusy);  master.sThreadBusy;         endrule
    rule sFlagConnect; master.sFlag(slave.sFlag);                      endrule 
    rule mFlagConnect; slave.mFlag(master.mFlag);                      endrule
  endmodule
endinstance
   
// Connect a Explicitly-named master to a "conventional" slave...
instance Connectable#( Wci_Em#(na), Wci_s#(na) );
  module mkConnection#(Wci_Em#(na) master , Wci_s#(na) slave ) ();
    rule reqConnect;
      WciReq#(na) req = WciReq {
         cmd          : unpack(master.mCmd),
         addrSpace    : master.mAddrSpace,
         byteEn       : master.mByteEn,
         addr         : master.mAddr,
         data         : master.mData};
      slave.putreq(req);
    endrule
    rule sRespConnect;  master.sResp(pack(slave.resp.resp));             endrule
    rule sDataConnect;  master.sData(slave.resp.data);                   endrule
    rule stbConnect  (slave.sThreadBusy);     master.sThreadBusy;        endrule
    rule sFlagConnect; master.sFlag(slave.sFlag);                        endrule 
    rule mFlagConnect; slave.mFlag(master.mFlag);                        endrule
  endmodule
endinstance

// Connect a "conventional" master to a "conventional" slave...
instance Connectable#(Wci_m#(na), Wci_s#(na));
  module mkConnection#(Wci_m#(na) master , Wci_s#(na) slave ) ();
    rule masterReqToSlave;                      slave.putreq (master.req); endrule
    rule slaveRspToMaster;                      master.put(slave.resp);    endrule
    rule sThreadBusyRule (slave.sThreadBusy);   master.sThreadBusy;        endrule
    rule sFlagRule;       master.sFlag (slave.sFlag);                      endrule
    rule mFlagRule;       slave.mFlag  (master.mFlag);                     endrule
    //rule mRstConnect (master.mReset_n);  slave.mReset_n;  endrule 
  endmodule
endinstance

   

// The Four function/module permutations are used to expand/collapse Masters and Slaves...
// This permutation trasforms Wci_Em to Wci_m...
function Wci_m#(na) toWciM(Wci_Em#(na) arg);
  WciReq#(na) r = WciReq {
    cmd          : unpack(arg.mCmd),
    addrSpace    : arg.mAddrSpace,
    byteEn       : arg.mByteEn,
    addr         : arg.mAddr,
    data         : arg.mData};
 return (interface Wci_m;
   method              req = r;
   method Action put(WciResp rsp);
     arg.sResp     (pack(rsp.resp));
     arg.sData     (rsp.data);
   endmethod
   method Action  sThreadBusy         = arg.sThreadBusy;
   method Action  sFlag (Bit#(2) sf ) = arg.sFlag(sf);
   method         mFlag               = arg.mFlag;
   interface      mReset_n            = arg.mReset_n;
 endinterface);
endfunction

// This permutation trasforms Wci_m to Wci_Em...
module mkWciMtoEm#(Wci_m#(na) arg) (Wci_Em#(na));
  Wire#(Bit#(2))   resp_w           <- mkDWire(0);
  Wire#(Bit#(32))  respData_w       <- mkDWire(0);

  rule doAlways;
    WciResp rsp = WciResp { resp:unpack(resp_w), data:respData_w };
    arg.put(rsp);
  endrule

  method         mCmd                = pack(arg.req.cmd);
  method         mAddrSpace          = arg.req.addrSpace;
  method         mByteEn             = arg.req.byteEn;
  method         mAddr               = arg.req.addr;
  method         mData               = arg.req.data;
  method Action  sResp(in)           = resp_w._write(in);
  method Action  sData(x)            = respData_w._write(x);
  method Action  sThreadBusy         = arg.sThreadBusy;
  method Action  sFlag (Bit#(2) sf)  = arg.sFlag(sf);
  method         mFlag               = arg.mFlag;
  interface      mReset_n            = arg.mReset_n;
endmodule

// This permutation trasforms Wci_Es to Wci_s...
function Wci_s#(na) toWciS(Wci_Es#(na) arg);
  WciResp rsp = WciResp {
    resp         : unpack(arg.sResp),
    data         : arg.sData };
  return (interface Wci_s;
    method Action putreq(WciReq#(na) req);
      arg.mCmd        (pack(req.cmd));
      arg.mAddrSpace  (req.addrSpace);
      arg.mByteEn     (req.byteEn);
      arg.mAddr       (req.addr);
      arg.mData       (req.data);
    endmethod
    method         resp = rsp;
    method         sThreadBusy         = arg.sThreadBusy;
    method         sFlag               = arg.sFlag;
    method Action  mFlag (Bit#(2) mf) = arg.mFlag(mf);
    //method Action  mReset_n            = arg.mReset_n;
 endinterface);
endfunction

// This permutation trasforms Wci_s to Wci_Es...
module mkWciStoES#(Wci_s#(na) arg) ( Wci_Es#(na));
  Wire#(Bit#(3))   mCmd_w           <- mkDWire(0);
  Wire#(Bit#(1))   mAddrSpace_w     <- mkDWire(0);
  Wire#(Bit#(na))  mAddr_w          <- mkDWire(0);
  Wire#(Bit#(32))  mData_w          <- mkDWire(0);
  Wire#(Bit#(4))   mByteEn_w        <- mkDWire(0);

  rule doAlways_Req;
     WciReq#(na)req = WciReq {
       cmd          : unpack(mCmd_w),
       addrSpace    : mAddrSpace_w,
       byteEn       : mByteEn_w,
       addr         : mAddr_w,
       data         : mData_w};
    arg.putreq(req);
  endrule

  method Action  mCmd(in)        = mCmd_w._write(in);
  method Action  mAddrSpace(x)   = mAddrSpace_w._write(x);
  method Action  mByteEn(x)      = mByteEn_w._write(x);
  method Action  mAddr(x)        = mAddr_w._write(x);
  method Action  mData(x)        = mData_w._write(x);
  method         sResp           = pack(arg.resp.resp);
  method         sData           = arg.resp.data;
  method         sThreadBusy     = arg.sThreadBusy;
  method         sFlag           = arg.sFlag;
  method Action  mFlag (Bit#(2) mf) = arg.mFlag(mf);
endmodule

//
//
//

//
// The Non-Atomic-Action-splitting approach...
//

interface Wci_Xm#(numeric type na);
  (* prefix = "" *)             interface Wci_MasterReq_Ifc#(na)  masterReq;
  (* prefix = "" *)             interface Wci_MasterResp_Ifc      masterResp;
  (* prefix="", always_enabled *)  method Action   sFlag        ((*port="SFlag"*)   Bit#(2)  arg_sFlag);
  (* prefix="", result="MFlag" *)  method Bit#(2)  mFlag;
  interface Reset mReset_n;
endinterface

(* always_ready *)
interface Wci_MasterReq_Ifc#(numeric type na);
  (* result = "MCmd"  *)         method  OCP_CMD       mCmd;
  (* result = "MAddrSpace"  *)   method  Bit#(1)       mAddrSpace;
  (* result = "MByteEn" *)       method  Bit#(4)       mByteEn;
  (* result = "MAddr" *)         method  Bit#(na)      mAddr;
  (* result = "MData" *)         method  Bit#(32)      mData;
  (* enable = "SThreadBusy" *)   method  Action        sThreadBusy();
endinterface

(* always_ready *)
interface Wci_MasterResp_Ifc;
  (* always_enabled, prefix = ""  *)
  method Action putResponse (
    (* port = "SResp" *)   OCP_RESP  sResp,
    (* port = "SData" *)   Bit#(32)  sData
  );
endinterface

interface Wci_Xs#(numeric type na);
  (* prefix = "" *)             interface Wci_SlaveReq_Ifc#(na) slaveReq;
  (* prefix = "" *)             interface Wci_SlaveResp_Ifc     slaveResp;
  (* prefix="", result="SFlag" *)  method Bit#(2)               sFlag;
  (* prefix="", always_enabled *)  method Action                mFlag ((*port="MFlag"*)Bit#(2) mf);
endinterface

(* always_ready *)
interface Wci_SlaveReq_Ifc#(numeric type na);
  (*  always_enabled, prefix = ""  *)
  method Action  putRequest  (
    (* port = "MCmd" *)      OCP_CMD         mCmd,
    (* port = "MAddrSpace"*) Bit#(1)         mAddrSpace,
    (* port = "MByteEn" *)   Bit#(4)         mByteEn,
    (* port = "MAddr" *)     Bit#(na)        mAddr,
    (* port = "MData" *)     Bit#(32)        mData
  );
  (* result = "SThreadBusy" *)  method Bool sThreadBusy  ();
endinterface

(* always_ready *)    
interface Wci_SlaveResp_Ifc;
   (* result = "SResp" *)   method  OCP_RESP sResp;
   (* result = "SData" *)   method  Bit#(32) sData;
endinterface

instance Connectable#( Wci_Xm#(na), Wci_Xs#(na) ) ;
  module mkConnection#(Wci_Xm#(na) master , Wci_Xs#(na) slave ) (Empty) ;
  (* no_implicit_conditions, fire_when_enabled *)
  rule masterToSlave;
    let req = master.masterReq ;
    slave.slaveReq.putRequest ( 
      req.mCmd,
      req.mAddrSpace,
      req.mByteEn,
      req.mAddr,
      req.mData );
  endrule
  (* no_implicit_conditions, fire_when_enabled *)
  rule slaveToMaster;
    let resp = slave.slaveResp ;
    master.masterResp.putResponse(
      resp.sResp,
      resp.sData );
  endrule
  (* no_implicit_conditions, fire_when_enabled *) rule sTrbRule (slave.slaveReq.sThreadBusy); master.masterReq.sThreadBusy; endrule
  (* no_implicit_conditions, fire_when_enabled *) rule sFlagRule; master.sFlag(slave.sFlag);  endrule
  (* no_implicit_conditions, fire_when_enabled *) rule mFlagRule; slave.mFlag (master.mFlag); endrule
  endmodule
endinstance


//
//
//


//
// WciMaster is convienience IP for OpenCPI that
// wraps up some OCP-IP/WIP/WCI boilerplate that may be used to talk to workers
//
interface WciMasterIfc#(numeric type na);
  method Action                req (WCI_SPACE sp, Bool write, Bit#(na) addr, Bit#(32) wdata, Bit#(4) be);
  method ActionValue#(WciResp) resp; 
  method Bool                  attn;
  method Bool                  present;
  interface Wci_m#(na)         mas;
endinterface

module mkWciMaster (WciMasterIfc#(na)) provisos (Add#(a_,5,na), Add#(b_,na,32));
  FIFOF#(WciReq#(na))          reqF             <- mkSizedDFIFOF(1,wciIdleRequest);
  FIFOF#(WciResp)              respF            <- mkSizedFIFOF(1);
  Wire#(WciResp)               wciResponse      <- mkWire;
  PulseWire                    sThreadBusy_pw   <- mkPulseWire;
  Reg#(Bool)                   sThreadBusy_d    <- mkReg(True);
  Reg#(Bit#(2))                mFlagReg         <- mkReg(2'b10);  // big-endian
  Reg#(Bool)                   respTimrAct      <- mkReg(False);
  Reg#(Bit#(32))               respTimr         <- mkReg(0);
  Reg#(Bit#(32))               wStatus          <- mkConfigRegU;
  Reg#(Bool)                   wReset_n         <- mkReg(False);
  Clock                        clk              <- exposeCurrentClock;
  MakeResetIfc                 mReset           <- mkReset(16, True, clk);  // 16 Cycle OCP Reset Specification
  Reg#(Bit#(5))                wTimeout         <- mkReg(5'h04);            // 16 Cycle default timeout 
  Reg#(WCI_REQ)                reqPend          <- mkReg(None);             // type of request pending
  Reg#(ReqTBits)               reqTO            <- mkReg(unpack(0));
  Reg#(ReqTBits)               reqFAIL          <- mkReg(unpack(0));
  Reg#(ReqTBits)               reqERR           <- mkReg(unpack(0));
  Reg#(Bool)                   slvPresent       <- mkReg(False); 
  Reg#(Bool)                   sfCap            <- mkReg(False); 
  Reg#(Bool)                   sfCapSet         <- mkDReg(False); 
  Reg#(Bool)                   sfCapClear       <- mkDReg(False); 
  Reg#(Bool)                   busy             <- mkReg(False); 
  Reg#(Maybe#(WCI_CONTROL_OP)) lastControlOp    <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(32)))       lastConfigAddr   <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(4)))        lastConfigBE     <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bool))           lastOpWrite      <- mkReg(tagged Invalid);

  Bit#(32) toCount = 1<<wTimeout;

  Bool respNULL = (wciResponse.resp==NULL);
  Bool respDVA  = (wciResponse.resp==DVA);
  Bool respFAIL = (wciResponse.resp==FAIL);
  Bool respERR  = (wciResponse.resp==ERR);

  rule workerReset (!wReset_n); mReset.assertReset; endrule

  // Advance requests to the worker as long as sThreadBusy is deasserted...
  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule
  rule reqF_deq (!sThreadBusy_d && respNULL);
    reqF.deq();   // deq method of DFIFO is always ready
  endrule
  // Startup respTimer as soon we have a real request, even if worker can't accept...
  rule startTimer (reqF.notEmpty);
    respTimrAct<=True; respTimr<=0; 
  endrule

  rule wrkBusy (busy);
    if (respNULL) begin
      if (respTimr<toCount) respTimr <= respTimr + 1;
      else begin
        case (reqPend)
          CfgWt: begin reqTO.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE TIMEOUT" , $time); end
          CfgRd: begin reqTO.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  TIMEOUT" , $time); end
          CtlOp: begin reqTO.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   TIMEOUT" , $time); end
        endcase
        respF.enq(wciTimeoutResponse); respTimrAct<=False; respTimr<=0; busy<=False;
      end
    end else begin //non-null response...
      if (respFAIL) begin
        case (reqPend)
          CfgWt: begin reqFAIL.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE RESPONSE-FAIL" , $time); end
          CfgRd: begin reqFAIL.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  RESPONSE-FAIL" , $time); end
          CtlOp: begin reqFAIL.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   RESPONSE-FAIL" , $time); end
        endcase
      end else if (respERR) begin
        case (reqPend)
          CfgWt: begin reqERR.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE RESPONSE-ERR" , $time); end
          CfgRd: begin reqERR.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  RESPONSE-ERR" , $time); end
          CtlOp: begin reqERR.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   RESPONSE-ERR" , $time); end
        endcase
      end
      respF.enq(wciResponse); respTimrAct<=False; respTimr<=0; reqPend<=None; busy<=False;
    end
  endrule

  rule updateStatus;
    wStatus <= {4'b0, 
               pack(fromMaybe(unpack(1'b1),  lastOpWrite)),     //TODO: Check me
               pack(fromMaybe(unpack(3'b111),lastControlOp)),   //TODO: Check me
               pack(fromMaybe(4'hF,  lastConfigBE)),
               pack(isValid(lastOpWrite)),
               pack(isValid(lastControlOp)),
               pack(isValid(lastConfigBE)),
               pack(isValid(lastConfigAddr)),
               6'b0, pack(sfCap),
               pack(reqTO.cfgWt),  pack(reqTO.cfgRd),  pack(reqTO.ctlOp),     // Timeout 
               pack(reqFAIL.cfgWt),pack(reqFAIL.cfgRd),pack(reqFAIL.ctlOp),   // FAIL
               pack(reqERR.cfgWt), pack(reqERR.cfgRd), pack(reqERR.ctlOp)};   // ERR 
  endrule

  rule sflagUpdate;
    if (sfCapSet) begin
      sfCap <= True;  //$display("[%0d]: %m: sfCap True ", $time);
    end else if (sfCapClear) begin
      sfCap <= False; //$display("[%0d]: %m: sfCap False", $time);
    end
  endrule

  method Action req (WCI_SPACE sp, Bool write, Bit#(na) addr, Bit#(32) wdata, Bit#(4) be) if(!busy);
    if (sp==Config) begin  // Configuration Space
      if (!wReset_n) respF.enq(wciResetResponse);
      else begin
        let r = WciReq {cmd:write?WR:RD, addrSpace:'b1, addr:addr, data:wdata, byteEn:be};
        lastConfigAddr <= tagged Valid(extend(addr));
        lastConfigBE   <= tagged Valid(be);
        lastOpWrite    <= tagged Valid(write);
        reqPend <= write?CfgWt:CfgRd;
        reqF.enq(r);
        busy <= True;
      end
    end else if (sp==Control && (addr[15:5]=='0)) begin  // Control Operations first 8 locations...
      $display("[%0d]: %m: WORKER CONTROL ARM..." , $time);
      if (write) respF.enq(wciErrorResponse);    //   Return Error Response for ANY ControlOp Writes
      else begin                                 //   Otherwise process ControlOps normally...
        if (!wReset_n) respF.enq(wciResetResponse);
        else begin
          let r = WciReq {cmd:RD, addrSpace:'b0, addr:extend({addr[4:2],2'b0}), data:wdata, byteEn:'1};
          lastControlOp <= tagged Valid(unpack(addr[4:2]));
          reqPend <= CtlOp; 
          reqF.enq(r);
          busy <= True;
        end
      end
    end else begin // Control-Status (accessable while reset)
      if (write) begin 
        case (addr[5:2])
          4'h9: begin
            wReset_n <= unpack(wdata[31]);
            wTimeout <= wdata[4:0];
            if (wdata[9]=='1) sfCapClear <= True;
            if (wdata[8]=='1) begin reqTO <= unpack(0); reqFAIL <= unpack(0); reqERR <= unpack(0); end
          end
        endcase
        respF.enq(WciResp{resp:DVA,data:'0});    // need to ack Control writes
      end else begin
        case (addr[5:2])
          4'h8:    respF.enq(WciResp{resp:DVA,data:wStatus});                      // FFE0
          4'h9:    respF.enq(WciResp{resp:DVA,data:{pack(wReset_n),'0,wTimeout}}); // FFE4
          4'hA:    respF.enq(WciResp{resp:DVA,data:fromMaybe('1,lastConfigAddr)}); // FFE8
          default: respF.enq(WciResp{resp:DVA,data:'0});
        endcase
      end
    end
  endmethod

  method ActionValue#(WciResp) resp;
    let x = respF.first; respF.deq; return x;
  endmethod

  method Bool attn = (wStatus[15:0]!=0);
  method Bool present = slvPresent;

  interface Wci_m mas;
    method WciReq#(na) req = sThreadBusy_d ? wciIdleRequest : reqF.first;
    method Action  put(WciResp wciResp) = wciResponse._write(wciResp);
    method Action  sThreadBusy = sThreadBusy_pw.send;
    method Action  sFlag (Bit#(2) sf);
      sfCapSet  <=unpack(sf[0]);
      slvPresent<=unpack(sf[1]);
    endmethod
    method Bit#(2)  mFlag    = mFlagReg;
    interface Reset mReset_n = mReset.new_rst;
  endinterface 
endmodule

// Null version..
module mkWciMasterNull (WciMasterIfc#(na)) provisos (Add#(a_,5,na));
  Clock          clk     <- exposeCurrentClock;
  MakeResetIfc   mReset  <- mkReset(1, True, clk);

  method Action req (WCI_SPACE sp, Bool write, Bit#(na) addr, Bit#(32) wdata, Bit#(4) be);
    noAction;
  endmethod
  method ActionValue#(WciResp) resp;
    return wciIdleResponse;
  endmethod
  method Bool attn = False;
  method Bool present = False;
  interface Wci_m mas;
    method WciReq#(na) req = wciIdleRequest;
    method Action  put(WciResp wciResp); noAction; endmethod
    method Action  sThreadBusy; noAction; endmethod
    method Action  sFlag (Bit#(2) sf); noAction; endmethod
    method Bit#(2)  mFlag    = 2'b00;
    interface Reset mReset_n = mReset.new_rst;
  endinterface 
endmodule


interface WciXMasterIfc#(numeric type na);
  method Action                req (WCI_SPACE sp, Bool write, Bit#(na) addr, Bit#(32) wdata, Bit#(4) be);
  method ActionValue#(WciResp) resp; 
  method Bool                  attn;
  method Bool                  present;
  interface Wci_Xm#(na)        mas;
endinterface

module mkWciXMaster (WciXMasterIfc#(na)) provisos (Add#(a_,5,na), Add#(b_,na,32));
  FIFOF#(WciReq#(na))          reqF             <- mkSizedDFIFOF(1,wciIdleRequest);
  FIFOF#(WciResp)              respF            <- mkSizedFIFOF(1);
  Wire#(WciResp)               wciResponse      <- mkWire;
  PulseWire                    sThreadBusy_pw   <- mkPulseWire;
  Reg#(Bool)                   sThreadBusy_d    <- mkReg(True);
  Reg#(Bit#(2))                mFlagReg         <- mkReg(2'b10);  // big-endian
  Reg#(Bool)                   respTimrAct      <- mkReg(False);
  Reg#(Bit#(32))               respTimr         <- mkReg(0);
  Reg#(Bit#(32))               wStatus          <- mkConfigRegU;
  Reg#(Bool)                   wReset_n         <- mkReg(False);
  Clock                        clk              <- exposeCurrentClock;
  MakeResetIfc                 mReset           <- mkReset(16, True, clk);  // 16 Cycle OCP Reset Specification
  Reg#(Bit#(5))                wTimeout         <- mkReg(5'h04);            // 16 Cycle default timeout 
  Reg#(WCI_REQ)                reqPend          <- mkReg(None);             // type of request pending
  Reg#(ReqTBits)               reqTO            <- mkReg(unpack(0));
  Reg#(ReqTBits)               reqFAIL          <- mkReg(unpack(0));
  Reg#(ReqTBits)               reqERR           <- mkReg(unpack(0));
  Reg#(Bool)                   slvPresent       <- mkReg(False); 
  Reg#(Bool)                   sfCap            <- mkReg(False); 
  Reg#(Bool)                   sfCapSet         <- mkDReg(False); 
  Reg#(Bool)                   sfCapClear       <- mkDReg(False); 
  Reg#(Bool)                   busy             <- mkReg(False); 
  Reg#(Maybe#(WCI_CONTROL_OP)) lastControlOp    <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(32)))       lastConfigAddr   <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bit#(4)))        lastConfigBE     <- mkReg(tagged Invalid);
  Reg#(Maybe#(Bool))           lastOpWrite      <- mkReg(tagged Invalid);

  Bit#(32) toCount = 1<<wTimeout;

  Bool respNULL = (wciResponse.resp==NULL);
  Bool respDVA  = (wciResponse.resp==DVA);
  Bool respFAIL = (wciResponse.resp==FAIL);
  Bool respERR  = (wciResponse.resp==ERR);

  rule workerReset (!wReset_n); mReset.assertReset; endrule

  // Advance requests to the worker as long as sThreadBusy is deasserted...
  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule
  rule reqF_deq (!sThreadBusy_d && respNULL);
    reqF.deq();   // deq method of DFIFO is always ready
  endrule
  // Startup respTimer as soon we have a real request, even if worker can't accept...
  rule startTimer (reqF.notEmpty);
    respTimrAct<=True; respTimr<=0; 
  endrule

  rule wrkBusy (busy);
    if (respNULL) begin
      if (respTimr<toCount) respTimr <= respTimr + 1;
      else begin
        case (reqPend)
          CfgWt: begin reqTO.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE TIMEOUT" , $time); end
          CfgRd: begin reqTO.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  TIMEOUT" , $time); end
          CtlOp: begin reqTO.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   TIMEOUT" , $time); end
        endcase
        respF.enq(wciTimeoutResponse); respTimrAct<=False; respTimr<=0; busy<=False;
      end
    end else begin //non-null response...
      if (respFAIL) begin
        case (reqPend)
          CfgWt: begin reqFAIL.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE RESPONSE-FAIL" , $time); end
          CfgRd: begin reqFAIL.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  RESPONSE-FAIL" , $time); end
          CtlOp: begin reqFAIL.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   RESPONSE-FAIL" , $time); end
        endcase
      end else if (respERR) begin
        case (reqPend)
          CfgWt: begin reqERR.cfgWt<=True; $display("[%0d]: %m: WORKER CONFIG-WRITE RESPONSE-ERR" , $time); end
          CfgRd: begin reqERR.cfgRd<=True; $display("[%0d]: %m: WORKER CONFIG-READ  RESPONSE-ERR" , $time); end
          CtlOp: begin reqERR.ctlOp<=True; $display("[%0d]: %m: WORKER CONTROL-OP   RESPONSE-ERR" , $time); end
        endcase
      end
      respF.enq(wciResponse); respTimrAct<=False; respTimr<=0; reqPend<=None; busy<=False;
    end
  endrule

  rule updateStatus;
    wStatus <= {4'b0, 
               pack(fromMaybe(unpack(1'b1),  lastOpWrite)),     //TODO: Check me
               pack(fromMaybe(unpack(3'b111),lastControlOp)),   //TODO: Check me
               pack(fromMaybe(4'hF,  lastConfigBE)),
               pack(isValid(lastOpWrite)),
               pack(isValid(lastControlOp)),
               pack(isValid(lastConfigBE)),
               pack(isValid(lastConfigAddr)),
               6'b0, pack(sfCap),
               pack(reqTO.cfgWt),  pack(reqTO.cfgRd),  pack(reqTO.ctlOp),     // Timeout 
               pack(reqFAIL.cfgWt),pack(reqFAIL.cfgRd),pack(reqFAIL.ctlOp),   // FAIL
               pack(reqERR.cfgWt), pack(reqERR.cfgRd), pack(reqERR.ctlOp)};   // ERR 
  endrule

  rule sflagUpdate;
    if (sfCapSet) begin
      sfCap <= True;  //$display("[%0d]: %m: sfCap True ", $time);
    end else if (sfCapClear) begin
      sfCap <= False; //$display("[%0d]: %m: sfCap False", $time);
    end
  endrule

  method Action req (WCI_SPACE sp, Bool write, Bit#(na) addr, Bit#(32) wdata, Bit#(4) be) if(!busy);
    if (sp==Config) begin  // Configuration Space
      if (!wReset_n) respF.enq(wciResetResponse);
      else begin
        let r = WciReq {cmd:write?WR:RD, addrSpace:'b1, addr:addr, data:wdata, byteEn:be};
        lastConfigAddr <= tagged Valid(extend(addr));
        lastConfigBE   <= tagged Valid(be);
        lastOpWrite    <= tagged Valid(write);
        reqPend <= write?CfgWt:CfgRd;
        reqF.enq(r);
        busy <= True;
      end
    end else if (sp==Control && (addr[15:5]=='0)) begin  // Control Operations first 8 locations...
      $display("[%0d]: %m: WORKER CONTROL ARM..." , $time);
      if (write) respF.enq(wciErrorResponse);    //   Return Error Response for ANY ControlOp Writes
      else begin                                 //   Otherwise process ControlOps normally...
        if (!wReset_n) respF.enq(wciResetResponse);
        else begin
          let r = WciReq {cmd:RD, addrSpace:'b0, addr:extend({addr[4:2],2'b0}), data:wdata, byteEn:'1};
          lastControlOp <= tagged Valid(unpack(addr[4:2]));
          reqPend <= CtlOp; 
          reqF.enq(r);
          busy <= True;
        end
      end
    end else begin // Control-Status (accessable while reset)
      if (write) begin 
        case (addr[5:2])
          4'h9: begin
            wReset_n <= unpack(wdata[31]);
            wTimeout <= wdata[4:0];
            if (wdata[9]=='1) sfCapClear <= True;
            if (wdata[8]=='1) begin reqTO <= unpack(0); reqFAIL <= unpack(0); reqERR <= unpack(0); end
          end
        endcase
        respF.enq(WciResp{resp:DVA,data:'0});    // need to ack Control writes
      end else begin
        case (addr[5:2])
          4'h8:    respF.enq(WciResp{resp:DVA,data:wStatus});                      // FFE0
          4'h9:    respF.enq(WciResp{resp:DVA,data:{pack(wReset_n),'0,wTimeout}}); // FFE4
          4'hA:    respF.enq(WciResp{resp:DVA,data:fromMaybe('1,lastConfigAddr)}); // FFE8
          default: respF.enq(WciResp{resp:DVA,data:'0});
        endcase
      end
    end
  endmethod

  method ActionValue#(WciResp) resp;
    let x = respF.first; respF.deq; return x;
  endmethod

  method Bool attn = (wStatus[15:0]!=0);
  method Bool present = slvPresent;

  interface Wci_Xm mas;
    interface Wci_MasterReq_Ifc masterReq;
      method OCP_CMD mCmd =   (reqF.notEmpty&&!sThreadBusy_d) ? reqF.first.cmd : IDLE ;
      method    mAddrSpace =  reqF.first.addrSpace;
      method    mByteEn    =  reqF.first.byteEn;
      method    mAddr      =  reqF.first.addr;
      method    mData      =  reqF.first.data ;
      method Action  sThreadBusy = sThreadBusy_pw.send;
    endinterface

    interface Wci_MasterResp_Ifc masterResp;
       method Action  putResponse (
         OCP_RESP sResp,
         Bit#(32) sData );
         if (sResp!=NULL && respF.notFull) wciResponse._write(WciResp { data:sData, resp:sResp });                                       
       endmethod
    endinterface

    method Action  sFlag (Bit#(2) sf);
      sfCapSet  <=unpack(sf[0]);
      slvPresent<=unpack(sf[1]);
    endmethod
    method Bit#(2)  mFlag    = mFlagReg;
    interface Reset mReset_n = mReset.new_rst;
  endinterface 
endmodule


//
// WciSlave is convienience IP for OpenCPI that
// wraps up the OCP-IP/WIP/WCI boilerplate that may be reused in each worker
//
interface WciSlaveIfc#(numeric type na);
  interface Wci_s#(na)        slv;
  interface Get#(WciReq#(na)) reqGet;
  interface Put#(WciResp)     respPut;
  method WciReq#(na)          reqPeek;
  method Bool                 configWrite;
  method Bool                 configRead;
  method Bool                 controlOp;
  method Bool                 wrkReset;
  method Action               drvSFlag();
  method WCI_STATE            ctlState;     // expose the control state
  method Bool                 isOperating;  // shorthand for ctlState==Operating
  method WCI_CONTROL_OP       ctlOp;        // expose control Op edges; ready only when ctlOpActive
  method Action               ctlAck;       // Acknowledge Current Control Operation
endinterface

module mkWciSlave (WciSlaveIfc#(na));
  Wire#(WciReq#(na))            wciReq           <- mkWire;
  FIFOLevelIfc#(WciReq#(na),3)  reqF             <- mkGFIFOLevel(True, False, True);
  FIFOF#(WciResp)               respF            <- mkDFIFOF(wciIdleResponse);
  Reg#(WCI_STATE)               cState           <- mkReg(Exists);  // current control state
  Reg#(WCI_STATE)               nState           <- mkReg(Exists);  // next control state
  Wire#(WCI_CONTROL_OP)         wEdge            <- mkWire;
  Reg#(WCI_CONTROL_OP)          cEdge            <- mkReg(Rsvd7);   // this control graph edge
  Reg#(Bool)                    illegalEdge      <- mkReg(False);
  PulseWire                     sThreadBusy_pw   <- mkPulseWire;
  Reg#(Bool)                    sThreadBusy_d    <- mkReg(True);
  Reg#(Bool)                    sFlagReg         <- mkDReg(False);
  PulseWire                     wci_cfwr_pw      <- mkPulseWire;  // Config Write
  PulseWire                     wci_cfrd_pw      <- mkPulseWire;  // Config Read
  PulseWire                     wci_ctrl_pw      <- mkPulseWire;  // Control Op
  Reg#(Bool)                    ctlOpActive      <- mkReg(False);
  Reg#(Bool)                    ctlAckReg        <- mkDReg(False);
  ReadOnly#(Bool)               isReset          <- isResetAsserted;

  // Schedule completions to have priority over new transactions...
  (* descending_urgency = "ctl_op_complete, ctl_op_start, request_decode" *)

  rule request_decode;
   let wciReq = reqF.first;
     if     (wciReq.addrSpace=='b1 && wciReq.cmd==WR) wci_cfwr_pw.send(); // Configuration Write
     else if(wciReq.addrSpace=='b1 && wciReq.cmd==RD) wci_cfrd_pw.send(); // Configuration Read
     else if(wciReq.addrSpace=='b0 && wciReq.cmd==RD) wci_ctrl_pw.send(); // Control Operation
  endrule

  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule
  rule reqF_enq (wciReq.cmd!=IDLE); reqF.enq(wciReq); endrule //TODO: Unguarded FIFO - consider block xxAccept holdoff when Full
  rule respF_deq; respF.deq(); endrule

  rule ctl_op_start (wci_ctrl_pw);
     WCI_CONTROL_OP controlOp = unpack(reqF.first.addr[4:2]); reqF.deq;
     wEdge <= controlOp; // for passing out the ctlOp value method
     cEdge <= controlOp; // for sampling edge until completion
     case (controlOp) matches
       Initialize  : if (cState==Exists)     nState <= Initialized;                                 else illegalEdge<=True;
       Start       : if (cState==Initialized||cState==Suspended)  nState <= Operating;              else illegalEdge<=True;
       Stop        : if (cState==Operating)  nState <= Suspended;                                   else illegalEdge<=True;
       Release     : if (cState==Suspended||cState==Operating||cState==Initialized) nState<=Exists; else illegalEdge<=True;
       Test        : illegalEdge <= False;
       BeforeQuery : illegalEdge <= False;  // for "atomic" ops
       AfterConfig : illegalEdge <= False;  // for "atomic" ops
       Rsvd7       : illegalEdge <= True;
     endcase
     ctlOpActive <= True;
      $display("[%0d]: %m: WCI ControlOp: Starting-transition edge:%x from:%x", $time, pack(controlOp), pack(cState));
  endrule

  rule ctl_op_complete (ctlOpActive && ctlAckReg);
    if (!illegalEdge) begin
      cState <= nState;
      respF.enq(wciOKResponse);
      $display("[%0d]: %m: WCI ControlOp: Completed-transition edge:%x from:%x to:%x", $time, pack(cEdge), pack(cState), pack(nState));
      //$display("[%0d]: %m: WCI ControlOp: Completed transition (edge,from,to)", $time, fshow(cEdge), fshow(cState), fshow(nState));
    end else begin
      illegalEdge <= False;
      respF.enq(wciErrorResponse);
      $display("[%0d]: %m: WCI ControlOp: ILLEGAL-EDGE Completed-transition edge:%x from:%x", $time, pack(cEdge), pack(cState));
    end
    ctlOpActive <= False;
  endrule

  interface Wci_s slv;
    method Action putreq(WciReq#(na) req) = wciReq._write(req);
    method sThreadBusy  = (reqF.isGreaterThan(3-2) || isReset);
    method WciResp resp = respF.first;
    method sFlag = {'1, pack(sFlagReg)};  // drive sFlag[1] to indicate worker present
    method Action mFlag(Bit#(2) mf);    noAction; endmethod
  endinterface

  interface reqGet  = toGet(reqF);
  interface respPut = toPut(respF);
  method WciReq#(na) reqPeek = reqF.first;
  method Bool  configWrite   = wci_cfwr_pw; 
  method Bool  configRead    = wci_cfrd_pw;
  method Bool  controlOp     = wci_ctrl_pw;
  method Bool  wrkReset      = isReset;
  method Action drvSFlag(); sFlagReg<=True; endmethod

  method ctlState    = cState;   // provide the current control state
  method isOperating = (cState==Operating);
  method ctlOp if (wci_ctrl_pw);  // ctlOp is only ready for one cycle, when it is issued
    return(wEdge);
  endmethod
  method Action ctlAck; ctlAckReg <= True; endmethod
endmodule


// WciSlaveNull may be used to tie-off unused Wci_s ports...
interface WciSlaveNullIfc#(numeric type na);
  interface Wci_s#(na)        slv;
endinterface

module mkWciSlaveNull (WciSlaveNullIfc#(na));
  interface Wci_s slv;
    method Action putreq(WciReq#(na) req); noAction; endmethod
    method sThreadBusy  = True;
    method WciResp resp = wciIdleResponse;
    method sFlag = 2'b00;  // deassert sFlag[1] to signal no worker present
    method Action mFlag(Bit#(2) mf);    noAction; endmethod
  endinterface
endmodule

//interface WciSlaveENullIfc#(numeric type na);
//  interface Wci_Es#(na)  slv;
//endinterface

module mkWciSlaveENull (Wci_Es#(na));
  WciSlaveNullIfc#(na) tieOff  <- mkWciSlaveNull;
  Wci_Es#(na)          wci_Es  <- mkWciStoES(tieOff.slv);
  return(wci_Es);
endmodule



interface WciXSlaveIfc#(numeric type na);
  interface Wci_Xs#(na)       slv;
  interface Get#(WciReq#(na)) reqGet;
  interface Put#(WciResp)     respPut;
  method WciReq#(na)          reqPeek;
  method Bool                 configWrite;
  method Bool                 configRead;
  method Bool                 controlOp;
  method Bool                 wrkReset;
  method Action               drvSFlag();
  method WCI_STATE            ctlState;     // expose the control state
  method Bool                 isOperating;  // shorthand for ctlState==Operating
  method WCI_CONTROL_OP       ctlOp;        // expose control Op edges; ready only when ctlOpActive
  method Action               ctlAck;       // Acknowledge Current Control Operation
endinterface

module mkWciXSlave (WciXSlaveIfc#(na));
  Wire#(WciReq#(na))            wciReq           <- mkWire;
  FIFOLevelIfc#(WciReq#(na),SRBsize)  reqF       <- mkFIFOLevel;
  FIFOF#(WciResp)               respF            <- mkDFIFOF(wciIdleResponse);
  Reg#(WCI_STATE)               cState           <- mkReg(Exists);  // current control state
  Reg#(WCI_STATE)               nState           <- mkReg(Exists);  // next control state
  Wire#(WCI_CONTROL_OP)         wEdge            <- mkWire;
  Reg#(WCI_CONTROL_OP)          cEdge            <- mkReg(Rsvd7);   // this control graph edge
  Reg#(Bool)                    illegalEdge      <- mkReg(False);
  PulseWire                     sThreadBusy_pw   <- mkPulseWire;
  Reg#(Bool)                    sThreadBusy_d    <- mkReg(True);
  Reg#(Bool)                    sFlagReg         <- mkDReg(False);
  PulseWire                     wci_cfwr_pw      <- mkPulseWire;  // Config Write
  PulseWire                     wci_cfrd_pw      <- mkPulseWire;  // Config Read
  PulseWire                     wci_ctrl_pw      <- mkPulseWire;  // Control Op
  Reg#(Bool)                    ctlOpActive      <- mkReg(False);
  Reg#(Bool)                    ctlAckReg        <- mkDReg(False);
  ReadOnly#(Bool)               isReset          <- isResetAsserted;
  Reg#(Bool)                    errorSticky      <- mkReg(False);

  // Schedule completions to have priority over new transactions...
  (* descending_urgency = "ctl_op_complete, ctl_op_start, request_decode" *)

  rule request_decode;
   let wciReq = reqF.first;
     if     (wciReq.addrSpace=='b1 && wciReq.cmd==WR) wci_cfwr_pw.send(); // Configuration Write
     else if(wciReq.addrSpace=='b1 && wciReq.cmd==RD) wci_cfrd_pw.send(); // Configuration Read
     else if(wciReq.addrSpace=='b0 && wciReq.cmd==RD) wci_ctrl_pw.send(); // Control Operation
  endrule

  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule
  rule reqF_enq (wciReq.cmd!=IDLE);
    if (reqF.notFull) reqF.enq(wciReq);
    else errorSticky <= True;
  endrule
  rule respF_deq; respF.deq(); endrule

  rule ctl_op_start (wci_ctrl_pw);
     WCI_CONTROL_OP controlOp = unpack(reqF.first.addr[4:2]); reqF.deq;
     wEdge <= controlOp; // for passing out the ctlOp value method
     cEdge <= controlOp; // for sampling edge until completion
     case (controlOp) matches
       Initialize  : if (cState==Exists)     nState <= Initialized;                                 else illegalEdge<=True;
       Start       : if (cState==Initialized||cState==Suspended)  nState <= Operating;              else illegalEdge<=True;
       Stop        : if (cState==Operating)  nState <= Suspended;                                   else illegalEdge<=True;
       Release     : if (cState==Suspended||cState==Operating||cState==Initialized) nState<=Exists; else illegalEdge<=True;
       Test        : illegalEdge <= False;
       BeforeQuery : illegalEdge <= False;  // for "atomic" ops
       AfterConfig : illegalEdge <= False;  // for "atomic" ops
       Rsvd7       : illegalEdge <= True;
     endcase
     ctlOpActive <= True;
      $display("[%0d]: %m: WCI ControlOp: Starting-transition edge:%x from:%x", $time, pack(controlOp), pack(cState));
  endrule

  rule ctl_op_complete (ctlOpActive && ctlAckReg);
    if (!illegalEdge) begin
      cState <= nState;
      respF.enq(wciOKResponse);
      $display("[%0d]: %m: WCI ControlOp: Completed-transition edge:%x from:%x to:%x", $time, pack(cEdge), pack(cState), pack(nState));
      //$display("[%0d]: %m: WCI ControlOp: Completed transition (edge,from,to)", $time, fshow(cEdge), fshow(cState), fshow(nState));
    end else begin
      illegalEdge <= False;
      respF.enq(wciErrorResponse);
      $display("[%0d]: %m: WCI ControlOp: ILLEGAL-EDGE Completed-transition edge:%x from:%x", $time, pack(cEdge), pack(cState));
    end
    ctlOpActive <= False;
  endrule

  interface Wci_Xs slv;
    interface Wci_SlaveReq_Ifc  slaveReq;
      method Action putRequest (
        OCP_CMD   mCmd,
        Bit#(1)   mAddrSpace,
        Bit#(4)   mByteEn,
        Bit#(na)  mAddr,
        Bit#(32)  mData );
        if (mCmd!=IDLE) wciReq._write(WciReq {
          cmd       : mCmd,
          addrSpace : mAddrSpace,
          byteEn    : mByteEn,
          addr      : mAddr,
          data      : mData });
      endmethod
      method sThreadBusy  = (reqF.isGreaterThan(valueOf(SRBsize)-2) || isReset);
    endinterface

    interface Wci_SlaveResp_Ifc slaveResp;
      method OCP_RESP sResp =  respF.notEmpty ? respF.first.resp : NULL ;
      method          sData =  respF.first.data ;
    endinterface

    method sFlag = {'1, pack(sFlagReg)};  // drive sFlag[1] to indicate worker present
    method Action mFlag(Bit#(2) mf);    noAction; endmethod
  endinterface

  interface reqGet  = toGet(reqF);
  interface respPut = toPut(respF);
  method WciReq#(na) reqPeek = reqF.first;
  method Bool  configWrite   = wci_cfwr_pw; 
  method Bool  configRead    = wci_cfrd_pw;
  method Bool  controlOp     = wci_ctrl_pw;
  method Bool  wrkReset      = isReset;
  method Action drvSFlag(); sFlagReg<=True; endmethod

  method ctlState    = cState;   // provide the current control state
  method isOperating = (cState==Operating);
  method ctlOp if (wci_ctrl_pw);  // ctlOp is only ready for one cycle, when it is issued
    return(wEdge);
  endmethod
  method Action ctlAck; ctlAckReg <= True; endmethod
endmodule


/* TODO: Write TieOff to replace Null
instance TieOff#(Wci_s#(na));
  module mkTieOff#(Wci_s#(na) ifc) (Empty);
    rule tieOffSomething;
      ifc.sThreadBusy(True);
      ifc.resp(wciIdleResponse);
      ifc.sFlag(2'b00);
    endrule
  endmodule
endinstance
*/
endpackage: OCWci

