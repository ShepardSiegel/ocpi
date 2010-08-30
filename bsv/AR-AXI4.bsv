// AR-AXI4 Atomic Rules - AXI4 Implementation
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package AR-AXI4;

import OCWipDefs::*;

import BRAM::*;
import ClientServer::*; 
import ConfigReg::*;
import Connectable::*;
import DefaultValue::*;
import Clocks::*;
import GetPut::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import FShow::*;
import SpecialFIFOs::*;
import TieOff::*;
import Vector::*;

typedef struct {
  Bool isInstruction;  // 0=data access;   1=instruction access
  Bool isNonSecure;    // 0=secure access; 1=nonsecure access
  Bool isPrivileged;   // 0=normal access; 1=privileged access
 } ProtEnc deriving (Bits, Eq);

typedef enum {OKAY, EXOCKAY, SLVERR, DECERR} DataRespEnc deriving (Bits, Eq);  // Used for Read and Write Response

// These are the four signal bundles used to communicate AXI4-Lite with FIFO-Like Semantics
// Data is interchnaged between master and slave on the cycles when both xxValid and xxReady are asserted in the same cycle...

// Write Address Channel...
typedef struct {
  Bool         awvalid;    //  Master-sourced signal which indicates that write-address and control are available
  Bool         awready;    //  Slave-sourced signal which indicates that the slave is ready
  Bit#(32)     awaddr;     //  Master-sourced signal with address
  ProtEnc      awprot;     //  Master-sourced signal with the encoded protection type
} WriteAddressChannel deriving (Bits, Eq);  // Used for the Write address channel

// Write Data Channel...
typedef struct {
  Bool         wvalid;     //  Master-sourced signal which indicates that write-data and control are available
  Bool         wready;     //  Slave-sourced signal which indicates that the slave is ready
  Bit#(32)     wdata;      //  Master-sourced signal with write data
  Bit#(4)      wstrb;      //  Master-sourced signal with the byte-lane enables
} WriteDataChannel deriving (Bits, Eq);  // Used for the Write data channel

// Write Response Channel...
typedef struct {
  Bool         bvalid;     //  Slave-sourced signal which indicates that write-response and control are available
  Bool         bready;     //  Master-sourced signal which indicates that the master is ready
  DataRespEnc  bresp;      //  Slave-sourced signal with write-response data
} WriteResponseChannel deriving (Bits, Eq);  // Used for the Write response data channel

// Read Address Channel...
typedef struct {
  Bool         arvalid;    //  Master-sourced signal which indicates that read-address and control are available
  Bool         arready;    //  Slave-sourced signal which indicates that the slave is ready
  Bit#(32)     araddr;     //  Master-sourced signal with address
  ProtEnc      arprot;     //  Master-sourced signal with the encoded protection type
} ReadAddressChannel deriving (Bits, Eq);  // Used for the Read address channel

// Read Data Channel...
typedef struct {
  Bool         rvalid;     //  Slave-sourced signal which indicates that read-data and control are available
  Bool         rready;     //  Master-sourced signal which indicates that the master is ready
  Bit#(32)     rdata;      //  Slave-sourced signal with read data
  DataRespEnc  rresp;      //  Slave-sourced signal with read-response data
} ReadDataChannel deriving (Bits, Eq);  // Used for the Read data channel


typedef struct {

  WmemiReq#(na,nb)   wmemiIdleRequest = WmemiReq  {cmd:IDLE,        reqLast:?,  addr:?, burstLength:?};
  WmemiDh#(nd,ne)    wmemiIdleDh      = WmemiDh   {dataValid:False, dataLast:?, data:?, dataByteEn:?};
  WmemiResp#(nd)     wmemiIdleResp    = WmemiResp {resp:NULL,       respLast:?, data:?};

(* always_ready *)
interface A4L_m);
  (* result = "req" *)                     method WmemiReq#(na,nb)   getReq;
  (* result = "dh" *)                      method WmemiDh#(nd,ne)    getDh;
  (* always_enabled, prefix = ""*)         method Action             putResp(WmemiResp#(nd) resp);
  (* prefix="", enable="SCmdAccept"*)      method Action             sCmdAccept;
  (* prefix="", enable="SDataAccept"*)     method Action             sDataAccept;
  (* prefix="", result="MReset_n"*)        method Bool               mReset_n;
endinterface 

(* always_ready *)
interface Wmemi_s#(numeric type na, numeric type nb, numeric type nd, numeric type ne);
  (* always_enabled, prefix=""*)           method Action             putReq (WmemiReq#(na,nb)  req);
  (* always_enabled, prefix=""*)           method Action             putDh  (WmemiDh#(nd,ne)   dh);
  (* result = "resp" *)                    method WmemiResp#(nd)     getResp();
  (* prefix="", result="SCmdAccept"*)      method Bool               sCmdAccept;
  (* prefix="", result="SDataAccept"*)     method Bool               sDataAccept;
  (* prefix="", enable="MReset_n"*)        method Action             mReset_n;
endinterface 

// Explicit OCP per-signal naming to purposefully to avoid data-structures and have explict OCP names...
(* always_ready *)
interface Wmemi_Em#(numeric type na, numeric type nb, numeric type nd, numeric type ne);
  (* prefix="", result="MCmd" *)           method Bit#(3)  mCmd;
  (* prefix="", result="MReqLast" *)       method Bool     mReqLast;
  (* prefix="", result="MAddr" *)          method Bit#(na) mAddr;
  (* prefix="", result="MBurstLength" *)   method Bit#(nb) mBurstLength;
  (* prefix="", result="MDataValid" *)     method Bool     mDataValid;
  (* prefix="", result="MDataLast" *)      method Bool     mDataLast;
  (* prefix="", result="MData" *)          method Bit#(nd) mData;
  (* prefix="", result="MDataByteEn" *)    method Bit#(ne) mDataByteEn;
  (* prefix="", always_enabled *)          method Action   sResp         ((* port="SResp" *) Bit#(2)  arg_resp);
  (* prefix="", enable="SRespLast" *)      method Action   sRespLast;
  (* prefix="", always_enabled *)          method Action   sData         ((* port="SData" *) Bit#(nd) arg_data);
  (* prefix="", enable="SCmdAccept"*)      method Action   sCmdAccept;
  (* prefix="", enable="SDataAccept"*)     method Action   sDataAccept;
  (* prefix="", result="MReset_n"*)        method Bool     mReset_n;
endinterface

(* always_ready *)
interface Wmemi_Es#(numeric type na, numeric type nb, numeric type nd, numeric type ne);
  (* prefix="", always_enabled *)          method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", enable="MReqLast" *)       method Action   mReqLast;
  (* prefix="", always_enabled *)          method Action   mAddr        ((* port="MAddr" *)        Bit#(na) arg_addr);
  (* prefix="", always_enabled *)          method Action   mBurstLength ((* port="MBurstLength" *) Bit#(nb) arg_burstLength);
  (* prefix="", enable="MDataValid" *)     method Action   mDataValid;
  (* prefix="", enable="MDataLast" *)      method Action   mDataLast;
  (* prefix="", always_enabled *)          method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", always_enabled *)          method Action   mDataByteEn  ((* port="MDataByteEn" *)  Bit#(ne) arg_byteEn);
  (* prefix="", result="SResp" *)          method Bit#(2)  sResp;
  (* prefix="", result="SRespLast"*)       method Bool     sRespLast;
  (* prefix="", result="SData" *)          method Bit#(nd) sData;
  (* prefix="", result="SCmdAccept"*)      method Bool     sCmdAccept;
  (* prefix="", result="SDataAccept"*)     method Bool     sDataAccept;
  (* prefix="", enable="MReset_n"*)        method Action   mReset_n;
endinterface

//
// The Four Connectable M/S instances..
// Connect a Explicitly-named master to a Explicitly-named slave...
instance Connectable#( Wmemi_Em#(na,nb,nd,ne), Wmemi_Es#(na,nb,nd,ne) );
  module mkConnection#(Wmemi_Em#(na,nb,nd,ne) master , Wmemi_Es#(na,nb,nd,ne) slave ) ();
    rule mCmdConnect;    slave.mCmd(master.mCmd);                        endrule 
    rule mReqLConnect   (master.mReqLast);      slave.mReqLast;          endrule 
    rule mAddrConnect;   slave.mAddr(master.mAddr);                      endrule 
    rule mBurstLConnect; slave.mBurstLength(master.mBurstLength);        endrule 
    rule mDataVConnect   (master.mDataValid);   slave.mDataValid;        endrule 
    rule mDataLConnect   (master.mDataLast);    slave.mDataLast;         endrule 
    rule mDataConnect;   slave.mData(master.mData);                      endrule 
    rule mDataBEConnect; slave.mDataByteEn(master.mDataByteEn);          endrule 
    rule sRespConnect;   master.sResp(slave.sResp);                      endrule 
    rule sRespLConnect  (slave.sRespLast);     master.sRespLast;         endrule
    rule sDataConnect;   master.sData(slave.sData);                      endrule
    rule scaConnect  (slave.sCmdAccept);      master.sCmdAccept;         endrule
    rule sdaConnect  (slave.sDataAccept);     master.sDataAccept;        endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                 endrule 
  endmodule
endinstance
   
// Connect a "conventional" master to a Explicitly-named slave...
instance Connectable#( Wmemi_m#(na,nb,nd,ne), Wmemi_Es#(na,nb,nd,ne) );
  module mkConnection#(Wmemi_m#(na,nb,nd,ne) master , Wmemi_Es#(na,nb,nd,ne) slave ) ();
    rule mCmdConnect;    slave.mCmd(pack(master.getReq.cmd));            endrule 
    rule mReqLConnect   (master.getReq.reqLast);      slave.mReqLast;    endrule 
    rule mAddrConnect;   slave.mAddr(master.getReq.addr);                endrule 
    rule mBurstLConnect; slave.mBurstLength(master.getReq.burstLength);  endrule 
    rule mDataVConnect   (master.getDh.dataValid);   slave.mDataValid;   endrule 
    rule mDataLConnect   (master.getDh.dataLast);    slave.mDataLast;    endrule 
    rule mDataConnect;   slave.mData(master.getDh.data);                 endrule 
    rule mDataBEConnect; slave.mDataByteEn(master.getDh.dataByteEn);     endrule 
    rule respConnect;
      WmemiResp#(nd) resp = WmemiResp {
        resp     : unpack(slave.sResp),
        respLast : slave.sRespLast,
        data     : slave.sData};
      master.putResp(resp);
    endrule
    rule scaConnect  (slave.sCmdAccept);      master.sCmdAccept;         endrule
    rule sdaConnect  (slave.sDataAccept);     master.sDataAccept;        endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                 endrule 
  endmodule
endinstance
   
// Connect a Explicitly-named master to a "conventional" slave...
instance Connectable#( Wmemi_Em#(na,nb,nd,ne), Wmemi_s#(na,nb,nd,ne) );
  module mkConnection#(Wmemi_Em#(na,nb,nd,ne) master , Wmemi_s#(na,nb,nd,ne) slave ) ();
    rule reqConnect;
      WmemiReq#(na,nb) req = WmemiReq {
         cmd          : unpack(master.mCmd),
         reqLast      : master.mReqLast,
         addr         : master.mAddr,
         burstLength  : master.mBurstLength};
      slave.putReq(req);
    endrule
    rule dhConnect;
      WmemiDh#(nd,ne) dh = WmemiDh {
         dataValid    : master.mDataValid,
         dataLast     : master.mDataLast,
         data         : master.mData,
         dataByteEn   : master.mDataByteEn};
      slave.putDh(dh);
    endrule
    rule sRespConnect;  master.sResp(pack(slave.getResp.resp));          endrule
    rule sRespLConnect (slave.getResp.respLast); master.sRespLast;       endrule
    rule sDataConnect;  master.sData(slave.getResp.data);                endrule
    rule scaConnect  (slave.sCmdAccept);      master.sCmdAccept;         endrule
    rule sdaConnect  (slave.sDataAccept);     master.sDataAccept;        endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                 endrule 
  endmodule
endinstance
   
// Connect a "conventional" master to a "conventional" slave...
instance Connectable#( Wmemi_m#(na,nb,nd,ne), Wmemi_s#(na,nb,nd,ne) );
  module mkConnection#(Wmemi_m#(na,nb,nd,ne) master , Wmemi_s#(na,nb,nd,ne) slave ) ();
    rule reqConnect; slave.putReq(master.getReq());    endrule                // Request Group
    rule dhConnect;  slave.putDh(master.getDh());      endrule                // Datahandshake Group
    rule respConnect; master.putResp(slave.getResp()); endrule                // Response Group
    rule scaConnect  (slave.sCmdAccept);      master.sCmdAccept;      endrule // sCmdAccept
    rule sdaConnect  (slave.sDataAccept);     master.sDataAccept;     endrule // sDataAccept
    rule mRstConnect (master.mReset_n);  slave.mReset_n;  endrule 
  endmodule
endinstance

// The Four function/module permutations are used to expand/collapse Masters and Slaves...
// This permutation trasforms Wmemi_Em to Wmemi_m...
function Wmemi_m#(na,nb,nd,ne) toWmemiM(Wmemi_Em#(na,nb,nd,ne) arg);
  WmemiReq#(na,nb) req = WmemiReq {
    cmd          : unpack(arg.mCmd),
    reqLast      : arg.mReqLast,
    addr         : arg.mAddr,
    burstLength  : arg.mBurstLength };
  WmemiDh#(nd,ne) dh = WmemiDh {
    dataValid    : arg.mDataValid,
    dataLast     : arg.mDataLast,
    data         : arg.mData,
    dataByteEn   : arg.mDataByteEn };
 return (interface Wmemi_m;
  method              getReq = req;
  method              getDh  = dh;
  method Action       putResp(WmemiResp#(nd) rsp);
    arg.sResp     (pack(rsp.resp));
    arg.sRespLast ();
    arg.sData     (rsp.data);
  endmethod
  method Action  sCmdAccept          = arg.sCmdAccept;
  method Action  sDataAccept         = arg.sDataAccept;
  method         mReset_n            = arg.mReset_n;
 endinterface);
endfunction

// This permutation trasforms Wmemi_m to Wmemi_Em...
module mkWmemiMtoEm#(Wmemi_m#(na,nb,nd,ne) arg) (Wmemi_Em#(na,nb,nd,ne));
  Wire#(Bit#(2))   sResp_w           <- mkDWire(0);
  PulseWire        sRespLast_w       <- mkPulseWire;
  Wire#(Bit#(nd))  sData_w           <- mkDWire(0);

  rule doAlways;
    WmemiResp#(nd) rsp = WmemiResp { resp:unpack(sResp_w), respLast:sRespLast_w, data:sData_w };
    arg.putResp(rsp);
  endrule

  method         mCmd                = pack(arg.getReq.cmd);
  method         mReqLast            = arg.getReq.reqLast;
  method         mAddr               = arg.getReq.addr;
  method         mBurstLength        = arg.getReq.burstLength;
  method         mDataValid          = arg.getDh.dataValid;
  method         mDataLast           = arg.getDh.dataLast;
  method         mData               = arg.getDh.data;
  method         mDataByteEn         = arg.getDh.dataByteEn;
  method Action  sResp(in)           = sResp_w._write(in);
  method Action  sRespLast           = sRespLast_w.send();
  method Action  sData(x)            = sData_w._write(x);
  method Action  sCmdAccept          = arg.sCmdAccept;
  method Action  sDataAccept         = arg.sDataAccept;
  method         mReset_n            = arg.mReset_n;
endmodule

// This permutation trasforms Wmemi_Es to Wmemi_s...
function Wmemi_s#(na,nb,nd,ne) toWmemiS(Wmemi_Es#(na,nb,nd,ne) arg);
  WmemiResp#(nd) resp = WmemiResp {
    resp         : unpack(arg.sResp),
    respLast     : arg.sRespLast,
    data         : arg.sData };
  return (interface Wmemi_s;
    method Action putReq(WmemiReq#(na,nb) req);
      arg.mCmd         (pack(req.cmd));
      arg.mReqLast     ();
      arg.mAddr        (req.addr);
      arg.mBurstLength (req.burstLength );
    endmethod
    method Action putDh(WmemiDh#(nd,ne) dh);
      arg.mDataValid   ();
      arg.mDataLast    ();
      arg.mData        (dh.data);
      arg.mDataByteEn  (dh.dataByteEn);
    endmethod
    method         getResp = resp;
    method         sCmdAccept          = arg.sCmdAccept;
    method         sDataAccept         = arg.sDataAccept;
    method Action  mReset_n            = arg.mReset_n;
 endinterface);
endfunction

// This permutation trasforms Wmemi_s to Wmemi_Es...
module mkWmemiStoES#(Wmemi_s#(na,nb,nd,ne) arg) ( Wmemi_Es#(na,nb,nd,ne));
  Wire#(Bit#(3))   mCmd_w           <- mkDWire(0);
  PulseWire        mReqLast_w       <- mkPulseWire;          
  Wire#(Bit#(na))  mAddr_w          <- mkDWire(0);
  Wire#(Bit#(nb))  mBurstLength_w   <- mkDWire(0);
  PulseWire        mDataValid_w     <- mkPulseWire;
  PulseWire        mDataLast_w      <- mkPulseWire;
  Wire#(Bit#(nd))  mData_w          <- mkDWire(0);
  Wire#(Bit#(ne))  mDataByteEn_w    <- mkDWire(0);

  rule doAlways_Req;
     WmemiReq#(na,nb)req = WmemiReq {
       cmd          : unpack(mCmd_w),
       reqLast      : mReqLast_w,
       addr         : mAddr_w,
       burstLength  : mBurstLength_w };
    arg.putReq(req);
  endrule

  rule doAlways_Dh;
     WmemiDh#(nd,ne)dh = WmemiDh {
       dataValid    : mDataValid_w,
       dataLast     : mDataLast_w,
       data         : mData_w,
       dataByteEn   : mDataByteEn_w };
    arg.putDh(dh);
  endrule

  method Action  mCmd(in)        = mCmd_w._write(in);
  method Action  mReqLast        = mReqLast_w.send();
  method Action  mAddr(x)        = mAddr_w._write(x);
  method Action  mBurstLength(x) = mBurstLength_w._write(x);
  method Action  mDataValid      = mDataValid_w.send();
  method Action  mDataLast       = mDataLast_w.send();
  method Action  mData(x)        = mData_w._write(x);
  method Action  mDataByteEn(x)  = mDataByteEn_w._write(x);
  method         sResp           = pack(arg.getResp.resp);
  method         sRespLast       = arg.getResp.respLast;
  method         sData           = arg.getResp.data;
  method         sCmdAccept      = arg.sCmdAccept;
  method         sDataAccept     = arg.sDataAccept;
  method Action  mReset_n        = arg.mReset_n;
endmodule


//
// WmemiMaster is convienience IP for OpenCPI that wraps up the Wmemi Master Role
//
interface WmemiMasterIfc#(numeric type na, numeric type nb, numeric type nd, numeric type ne);
  method Action                       req (Bool write, Bit#(na) addr, Bit#(nb) bl);
  method Action                       dh  (Bit#(nd) wdata, Bit#(ne) be, Bool dataLast);
  method ActionValue#(WmemiResp#(nd)) resp; 
  method Bool                         anyBusy; // True when either ThreadBusy of sDataThreadBusy asserted
  method Action                       operate;
  method WipDataPortStatus            status;    
  interface Wmemi_m#(na,nb,nd,ne)     mas;  // The Wmemi-OCP Master Interface
endinterface

module mkWmemiMaster (WmemiMasterIfc#(na,nb,nd,ne));
  FIFOF#(WmemiReq#(na,nb))     reqF               <- mkDFIFOF(wmemiIdleRequest);
  FIFOF#(WmemiDh#(nd,ne))      dhF                <- mkDFIFOF(wmemiIdleDh);
  FIFOF#(WmemiResp#(nd))       respF              <- mkFIFOF;
  Reg#(Bool)                   busyWithMessage    <- mkReg(False);
  Wire#(WmemiResp#(nd))        wmemiResponse      <- mkWire;
  Wire#(Bool)                  sCmdAccept_w       <- mkWire;
  Wire#(Bool)                  sDataAccept_w      <- mkWire;
  ReadOnly#(Bool)              isReset            <- isResetAsserted;
  Reg#(Bool)                   operateD           <- mkDReg(False);
  Reg#(Bool)                   peerIsReady        <- mkDReg(True); // WMemI Master assumes infrastructure slave is ready (no SReset_n)
  // Diagnostic state...
  Reg#(WipDataPortStatus)      statusR            <- mkConfigRegU;
  Reg#(Bool)                   errorSticky        <- mkReg(False);
  Reg#(Bool)                   trafficSticky      <- mkReg(False);

  Bool linkReady = (operateD && peerIsReady);
  Bool respNULL  = (wmemiResponse.resp==NULL);
  Bool respDVA   = (wmemiResponse.resp==DVA);
  Bool respFAIL  = (wmemiResponse.resp==FAIL);
  Bool respERR   = (wmemiResponse.resp==ERR);

  // Command and Data are advanced by the Slave asserting {Cmd|Data}Accept...
  rule reqF_deq (sCmdAccept_w); trafficSticky <= True; reqF.deq(); endrule
  rule dhF_deq  (sDataAccept_w); dhF.deq(); endrule

  rule respAdvance (linkReady && !respNULL);     // This profile does not use respAccept, no response backpresure...
    if (respF.notFull) respF.enq(wmemiResponse); // enq the response in the respF  (normal behavior)
    else errorSticky<=True;                      // set errorSticky if we try to enq a full respF (response was dropped)
  endrule

  //TODO: Factor the (nearly) common WipDataPortStatus and ExtendedStatus into reused module or function
  rule update_statusR;
    statusR <= WipDataPortStatus {
      localReset      : isReset,           // 7:  This port is reset
      partnerReset    : !peerIsReady,      // 6:  The connected partner port is reset
      notOperatonal   : !operateD,         // 5:  This port is not Operational
      observedError   : errorSticky,       // 4:  An error has been observed since port became operational (sticky)
      inProgress      : False,             // 3:  A message is in progress at this port
      sThreadBusy     : False,             // 2:  Present value of SThreadBusy
      sDataThreadBusy : False,             // 1:  Present value of SDataThreadBusy (datahandshakeonly)
      observedTraffic : trafficSticky      // 0:  Traffic has moved across this port since it became operational (sticky)
    };
  endrule

  //TODO: convert the awkward OCP bl in cycles to a friendly length in Bytes
  // User-facing Methods...
  method Action req (Bool write, Bit#(na) addr, Bit#(nb) bl) if (linkReady);
    let r = WmemiReq {cmd:write?WR:RD, reqLast:True, addr:addr, burstLength:bl};
    reqF.enq(r);
    //$display("[%0d]: %m: req addr:%0x", $time, addr);
  endmethod

  method Action dh (Bit#(nd) wdata, Bit#(ne) be, Bool dataLast) if (linkReady);
    let r = WmemiDh {dataValid:True, dataLast:dataLast, data:wdata, dataByteEn:be};
    dhF.enq(r);
  endmethod

  method ActionValue#(WmemiResp#(nd)) resp;
    let x = respF.first; respF.deq; return x;
  endmethod
  method Bool     anyBusy        = False; // TODO: Thread vs Accept (does anyBusy make sense here?)
  method Action   operate        = operateD._write(True);
  method WipDataPortStatus status = statusR;    

  interface Wmemi_m mas;  // OCP-IP Master Interface Methods...
    method WmemiReq#(na,nb) getReq  =  reqF.first;
    method WmemiDh#(nd,ne)  getDh   =  dhF.first;
    method Action  putResp(WmemiResp#(nd) resp) = wmemiResponse._write(resp);
    method Action  sCmdAccept      = sCmdAccept_w._write(True);
    method Action  sDataAccept     = sDataAccept_w._write(True);
    method mReset_n = !(isReset || !operateD);
  endinterface 
endmodule

//
// WmemiSlave is convienience IP for OpenCPI that wraps up the Wmemi Slave Role
//
interface WmemiSlaveIfc#(numeric type na, numeric type nb, numeric type nd, numeric type ne);
  method ActionValue#(WmemiReq#(na,nb))   req;
  method ActionValue#(WmemiDh#(nd,ne))    dh;
  method Action                           respd (Bit#(nd) rdata, Bool respLast);
  method Action                           operate;
  method WipDataPortStatus                status;    
  interface Wmemi_s#(na,nb,nd,ne)         slv;  // The Wmemi-OCP Slave Interface
endinterface

module mkWmemiSlave (WmemiSlaveIfc#(na,nb,nd,ne));
  Wire#(WmemiReq#(na,nb))               wmemiReq             <- mkWire;
  Wire#(WmemiDh#(nd,ne))                wmemiDh              <- mkWire;
  Wire#(Bool)                           cmdAccept_w          <- mkDWire(False);
  Wire#(Bool)                           dhAccept_w           <- mkDWire(False);
  FIFOF#(WmemiReq#(na,nb))              reqF                 <- mkFIFOF;
  FIFOF#(WmemiDh#(nd,ne))               dhF                  <- mkFIFOF;
  FIFOF#(WmemiResp#(nd))                respF                <- mkDFIFOF(wmemiIdleResp);
  ReadOnly#(Bool)                       isReset              <- isResetAsserted;
  Reg#(Bool)                            operateD             <- mkDReg(False);
  Reg#(Bool)                            peerIsReady          <- mkDReg(False);
  Reg#(WipDataPortStatus)               statusR              <- mkConfigRegU;
  Reg#(Bool)                            errorSticky          <- mkReg(False);
  Reg#(Bool)                            trafficSticky        <- mkReg(False);

  Bool linkReady = (operateD && peerIsReady);

  rule reqF_enq (linkReady && wmemiReq.cmd!=IDLE && reqF.notFull);  // Rule wont fire if reqF is FULL, so cmdAccept is held off
    reqF.enq(wmemiReq);
    trafficSticky <= True;
    cmdAccept_w   <= True;  // reactive flow-control: we assert cmdAccept on the cycle we accept
  endrule

  rule dhF_enq  (linkReady && wmemiDh.dataValid && dhF.notFull);    // Rule wont fire if dhF is FULL, so dhAccept is held off
    dhF.enq(wmemiDh); 
    dhAccept_w   <= True;   // reactive flow-control: we assert  dhAccept on the cycle we accept
  endrule

  rule respF_deq; respF.deq(); endrule

  rule update_statusR;
    statusR <= WipDataPortStatus {
      localReset      : isReset,           // 7:  This port is reset
      partnerReset    : !peerIsReady,      // 6:  The connected partner port is reset
      notOperatonal   : !operateD,         // 5:  This port is not Operational
      observedError   : errorSticky,       // 4:  An error has been observed since port became operational (sticky)
      inProgress      : False ,            // 3:  A message is in progress at this port
      sThreadBusy     : False,             // 2:  Present value of SThreadBusy
      sDataThreadBusy : False,             // 1:  Present value of SDataThreadBusy (datahandshakeonly)
      observedTraffic : trafficSticky      // 0:  Traffic has moved across this port since it became operational (sticky)
    };
  endrule
   

  // User-facing Methods...
  method ActionValue#(WmemiReq#(na,nb)) req if (linkReady);
    let x = reqF.first; reqF.deq; return x;
  endmethod
  method ActionValue#(WmemiDh#(nd,ne)) dh if (linkReady);
    let x = dhF.first;  dhF.deq; return x;
  endmethod
  method Action   respd (Bit#(nd) rdata, Bool respLast) if(linkReady); respF.enq( WmemiResp { resp:DVA, respLast:respLast, data:rdata} ); endmethod
  method Action   operate    = operateD._write(True);
  method WipDataPortStatus status = statusR;    

  interface Wmemi_s slv; // OCP-IP Slave Interface Methods...
    method Action putReq(WmemiReq#(na,nb)  req) = wmemiReq._write(req);
    method Action putDh (WmemiDh#(nd,ne) dh)     = wmemiDh._write(dh);
    method WmemiResp#(nd) getResp = respF.first;
    method sCmdAccept      = cmdAccept_w;
    method sDataAccept     = dhAccept_w;
    method Action mReset_n = peerIsReady._write(True);
  endinterface
endmodule

endpackage: AR-AXI4

