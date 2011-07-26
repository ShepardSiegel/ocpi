// OCWsi.bsv - OpenCPI Worker Streaming Interface 
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWsi;

import OCWipDefs::*;
import OCPMDefs::*;


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

// WIP::WSI Attributes...
typedef struct {
  Bool continuous;       // True means no IDLE cycles within a burst
  UInt#(32) dataWidth;   // Width in bits of the data path
  UInt#(32) byteWidth;   // Derived from other attributes
  Bool impreciseBurst;   // True means Imprecise OCP bursts will be used
  Bool preciseBurst;     // True means Precise OCP bursts will be used
  Bool abortable;        // True means unfinished messages can be aborted
  Bool earlyRequest;     // True means Start-of-message may occur before data
} WsiAttributes deriving (Bits, Eq);

instance DefaultValue#(WsiAttributes);
 defaultValue = WsiAttributes {
  continuous     : False,
  dataWidth      : 8,
  byteWidth      : ?,
  impreciseBurst : False,
  preciseBurst   : False,
  abortable      : False,
  earlyRequest   : False
  };
endinstance

// 
// Worker Streaming Interface (WSI)...
// 
// nb - number of bits in Burst Length (BL is # of transfers in a burst)
// nd - number of bits in {M|S}Data 
// ng - number of bits in MByteEn
// nh - number of bits in MReqInfo
// ni - number of bits in MDataInfo
// 

// WSI convienience type synonyms, "SuperProfiles"...
typedef Wsi_m#(12, 32, 4,8,0) WsiM4B;
typedef Wsi_s#(12, 32, 4,8,0) WsiS4B;
typedef Wsi_m#(12, 64, 8,8,0) WsiM8B;
typedef Wsi_s#(12, 64, 8,8,0) WsiS8B;
typedef Wsi_m#(12,128,16,8,0) WsiM16B;
typedef Wsi_s#(12,128,16,8,0) WsiS16B;
typedef Wsi_m#(12,256,32,8,0) WsiM32B;
typedef Wsi_s#(12,256,32,8,0) WsiS32B;
// Explicit flavors...
typedef Wsi_Em#(12, 32, 4,8,0) WsiEM4B;
typedef Wsi_Es#(12, 32, 4,8,0) WsiES4B;
typedef Wsi_Em#(12, 64, 8,8,0) WsiEM8B;
typedef Wsi_Es#(12, 64, 8,8,0) WsiES8B;
typedef Wsi_Em#(12,128,16,8,0) WsiEM16B;
typedef Wsi_Es#(12,128,16,8,0) WsiES16B;
typedef Wsi_Em#(12,256,32,8,0) WsiEM32B;
typedef Wsi_Es#(12,256,32,8,0) WsiES32B;

typedef struct {
  OCP_CMD  cmd;           // IDLE WR RD (non-Idle qualifies group)
  Bool     reqLast;       // Last cycle of request (always included)
  Bool     burstPrecise;  // 0=Imprecise, 1=Precise
  Bit#(nb) burstLength;   // polymorhic burst length (nb)  //TODO: This should be a UInt
  Bit#(nd) data;          // polymorphic data width  (nd)
  Bit#(ng) byteEn;        // polymorphic BE   width  (ng)
  Bit#(nh) reqInfo;       // polymorhic reqInfo size (nh)
  Bit#(ni) dataInfo;      // polymorphic data info   (ni)
} WsiReq#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni) deriving (Bits, Eq);

WsiReq#(nb,nd,ng,nh,ni) wsiIdleRequest =
   WsiReq {cmd:IDLE,reqLast:False,reqInfo:'0,burstPrecise:False,burstLength:'0,data:?,byteEn:?,dataInfo:?};

//TODO
// MFlag for Abort, when needed

(* always_ready *)
interface Wsi_m#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  (* result="req" *)                      method WsiReq#(nb,nd,ng,nh,ni) get();
  (* prefix="", enable="SThreadBusy" *)   method Action sThreadBusy;
  (* prefix="", result="MReset_n"*)       method Bool   mReset_n;
  (* prefix="", enable="SReset_n"*)       method Action sReset_n;
endinterface

(* always_ready *)
interface Wsi_s#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  (* prefix="", always_enabled *)         method Action put (WsiReq#(nb,nd,ng,nh,ni) req);
  (* prefix="", result="SThreadBusy" *)   method Bool   sThreadBusy;
  (* prefix="", result="SReset_n"*)       method Bool   sReset_n;
  (* prefix="", enable="MReset_n"*)       method Action mReset_n;
endinterface

// Explicit OCP per-signal naming to purposefully to avoid data-structures and have explict OCP names...
(* always_ready *)
interface Wsi_Em#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  (* prefix="", result="MCmd" *)          method Bit#(3)  mCmd;
  (* prefix="", result="MReqLast" *)      method Bool     mReqLast;
  (* prefix="", result="MBurstPrecise" *) method Bool     mBurstPrecise;
  (* prefix="", result="MBurstLength" *)  method Bit#(nb) mBurstLength;
  (* prefix="", result="MData" *)         method Bit#(nd) mData;
  (* prefix="", result="MByteEn" *)       method Bit#(ng) mByteEn;
  (* prefix="", result="MReqInfo" *)      method Bit#(nh) mReqInfo;
  (* prefix="", result="MDataInfo" *)     method Bit#(ni) mDataInfo;
  (* prefix="", enable="SThreadBusy" *)   method Action   sThreadBusy;
  (* prefix="", result="MReset_n"*)       method Bool     mReset_n;
  (* prefix="", enable="SReset_n"*)       method Action   sReset_n;
endinterface

(* always_ready *)
interface Wsi_Es#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  (* prefix="", always_enabled *)         method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", enable="MReqLast" *)      method Action   mReqLast;
  (* prefix="", enable="MBurstPrecise" *) method Action   mBurstPrecise;
  (* prefix="", always_enabled *)         method Action   mBurstLength ((* port="MBurstLength" *) Bit#(nb) arg_burstLength);
  (* prefix="", always_enabled *)         method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", always_enabled *)         method Action   mByteEn      ((* port="MByteEn" *)      Bit#(ng) arg_byteEn);
  (* prefix="", always_enabled *)         method Action   mReqInfo     ((* port="MReqInfo" *)     Bit#(nh) arg_reqInfo);
  (* prefix="", always_enabled *)         method Action   mDataInfo    ((* port="MDataInfo" *)    Bit#(ni) arg_dataInfo);
  (* prefix="", result="SThreadBusy" *)   method Bool     sThreadBusy;
  (* prefix="", result="SReset_n"*)       method Bool     sReset_n;
  (* prefix="", enable="MReset_n"*)       method Action   mReset_n;
endinterface

(* always_ready *)
interface Wsi_Eo#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  (* prefix="", always_enabled *)         method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", enable="MReqLast" *)      method Action   mReqLast;
  (* prefix="", enable="MBurstPrecise" *) method Action   mBurstPrecise;
  (* prefix="", always_enabled *)         method Action   mBurstLength ((* port="MBurstLength" *) Bit#(nb) arg_burstLength);
  (* prefix="", always_enabled *)         method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", always_enabled *)         method Action   mByteEn      ((* port="MByteEn" *)      Bit#(ng) arg_byteEn);
  (* prefix="", always_enabled *)         method Action   mReqInfo     ((* port="MReqInfo" *)     Bit#(nh) arg_reqInfo);
  (* prefix="", always_enabled *)         method Action   mDataInfo    ((* port="MDataInfo" *)    Bit#(ni) arg_dataInfo);
  (* prefix="", enable="SThreadBusy" *)   method Action   sThreadBusy;
  (* prefix="", enable="SReset_n"*)       method Action   sReset_n;
  (* prefix="", enable="MReset_n"*)       method Action   mReset_n;
endinterface

// The WSI instance of ConnectableMSO...
instance ConnectableMSO#( Wsi_Em#(nb,nd,ng,nh,ni), Wsi_Es#(nb,nd,ng,nh,ni), Wsi_Eo#(nb,nd,ng,nh,ni) );
  module mkConnectionMSO#(Wsi_Em#(nb,nd,ng,nh,ni) master, Wsi_Es#(nb,nd,ng,nh,ni) slave, Wsi_Eo#(nb,nd,ng,nh,ni) observer) (Empty);
    rule mCmdConnect;    slave.mCmd(master.mCmd);                      observer.mCmd(master.mCmd);                  endrule 
    rule mReqLConnect    (master.mReqLast);      slave.mReqLast;       observer.mReqLast;                           endrule
    rule mBrstPConnect   (master.mBurstPrecise); slave.mBurstPrecise;  observer.mBurstPrecise;                      endrule
    rule mBLenConnect;   slave.mBurstLength(master.mBurstLength);      observer.mBurstLength(master.mBurstLength);  endrule 
    rule mDataConnect;   slave.mData(master.mData);                    observer.mData(master.mData);                endrule 
    rule mBEConnect;     slave.mByteEn(master.mByteEn);                observer.mByteEn(master.mByteEn);            endrule 
    rule mReqIConnect;   slave.mReqInfo(master.mReqInfo);              observer.mReqInfo(master.mReqInfo);          endrule 
    rule mDatIConnect;   slave.mDataInfo(master.mDataInfo);            observer.mDataInfo(master.mDataInfo);        endrule 
    rule stbConnect      (slave.sThreadBusy);    master.sThreadBusy;   observer.sThreadBusy;                        endrule
    rule mResetConnect   (master.mReset_n);      slave.mReset_n;       observer.mReset_n;                           endrule
    rule sResetConnect   (slave.sReset_n);       master.sReset_n;      observer.sReset_n;                           endrule
  endmodule
endinstance

//
// The Four Connectable M/S instances..
// Connect an Explicitly-named master to an Explicitly-named slave...
instance Connectable#( Wsi_Em#(nb,nd,ng,nh,ni), Wsi_Es#(nb,nd,ng,nh,ni) );
  module mkConnection#(Wsi_Em#(nb,nd,ng,nh,ni) master , Wsi_Es#(nb,nd,ng,nh,ni) slave ) (Empty);
    rule mCmdConnect;    slave.mCmd(master.mCmd);                    endrule 
    rule mReqLConnect   (master.mReqLast);      slave.mReqLast;      endrule 
    rule mBurstPConnect (master.mBurstPrecise); slave.mBurstPrecise; endrule 
    rule mBurstLConnect; slave.mBurstLength(master.mBurstLength);    endrule 
    rule mDataConnect;   slave.mData(master.mData);                  endrule 
    rule mByteEnConnect; slave.mByteEn(master.mByteEn);              endrule 
    rule mReqIConnect;   slave.mReqInfo(master.mReqInfo);            endrule 
    rule mDataIConnect;  slave.mDataInfo(master.mDataInfo);          endrule 
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;         endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;             endrule 
    rule sRstConnect (slave.sReset_n);  master.sReset_n;             endrule
  endmodule
endinstance

// Connect a "conventional" master to an Explicitly-named slave...
instance Connectable#( Wsi_m#(nb,nd,ng,nh,ni), Wsi_Es#(nb,nd,ng,nh,ni) );
  module mkConnection#(Wsi_m#(nb,nd,ng,nh,ni) master , Wsi_Es#(nb,nd,ng,nh,ni) slave ) (Empty);
    rule mCmdConnect;    slave.mCmd(pack(master.get.cmd));              endrule 
    rule mReqLConnect   (master.get.reqLast);      slave.mReqLast;      endrule 
    rule mBurstPConnect (master.get.burstPrecise); slave.mBurstPrecise; endrule 
    rule mBurstLConnect; slave.mBurstLength(master.get.burstLength);    endrule 
    rule mDataConnect;   slave.mData(master.get.data);                  endrule 
    rule mByteEnConnect; slave.mByteEn(master.get.byteEn);              endrule 
    rule mReqIConnect;   slave.mReqInfo(master.get.reqInfo);            endrule 
    rule mDataIConnect;  slave.mDataInfo(master.get.dataInfo);          endrule 
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;            endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                endrule 
    rule sRstConnect (slave.sReset_n);  master.sReset_n;                endrule
  endmodule
endinstance

// Connect an Explicitly-named master to a "conventional" slave...
instance Connectable#( Wsi_Em#(nb,nd,ng,nh,ni), Wsi_s#(nb,nd,ng,nh,ni) );
  module mkConnection#(Wsi_Em#(nb,nd,ng,nh,ni) master , Wsi_s#(nb,nd,ng,nh,ni) slave ) (Empty);
    rule reqConnect;
      WsiReq#(nb,nd,ng,nh,ni) req = WsiReq {
         cmd          : unpack(master.mCmd),
         reqLast      : master.mReqLast,
         burstPrecise : master.mBurstPrecise,
         burstLength  : master.mBurstLength,
         data         : master.mData,
         byteEn       : master.mByteEn,
         reqInfo      : master.mReqInfo,
         dataInfo     : master.mDataInfo};
      slave.put(req);
    endrule
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy;       endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;           endrule 
    rule sRstConnect (slave.sReset_n);  master.sReset_n;           endrule
  endmodule
endinstance

// Connect a "conventional" master to a "conventional" slave
instance Connectable#( Wsi_m#(nb,nd,ng,nh,ni), Wsi_s#(nb,nd,ng,nh,ni) );
  module mkConnection#(Wsi_m#(nb,nd,ng,nh,ni) master , Wsi_s#(nb,nd,ng,nh,ni) slave ) (Empty);
    rule reqConnect; slave.put(master.get());                endrule
    rule stbConnect (slave.sThreadBusy); master.sThreadBusy; endrule
    rule mRstConnect (master.mReset_n);  slave.mReset_n;     endrule 
    rule sRstConnect (slave.sReset_n);  master.sReset_n;     endrule
  endmodule
endinstance

//
// The Four function/module permutations are used to expand/collapse Masters and Slaves...
// This permutation trasforms Wsi_Em to Wsi_m...
function Wsi_m#(nb,nd,ng,nh,ni) toWsiM(Wsi_Em#(nb,nd,ng,nh,ni) arg);
  WsiReq#(nb,nd,ng,nh,ni) req = WsiReq {
     cmd          : unpack(arg.mCmd),
     reqLast      : arg.mReqLast,
     burstPrecise : arg.mBurstPrecise,
     burstLength  : arg.mBurstLength,
     data         : arg.mData,
     byteEn       : arg.mByteEn,
     reqInfo      : arg.mReqInfo,
     dataInfo     : arg.mDataInfo};
  return ( Wsi_m {get:req, sThreadBusy:arg.sThreadBusy, sReset_n:arg.sReset_n, mReset_n:arg.mReset_n} );
endfunction

// This permutation trasforms Wsi_m to Wsi_Em...
function Wsi_Em#(nb,nd,ng,nh,ni) toWsiEM(Wsi_m#(nb,nd,ng,nh,ni) arg);
  return ( Wsi_Em {
     mCmd          : pack(arg.get.cmd),
     mReqLast      : arg.get.reqLast, 
     mBurstPrecise : arg.get.burstPrecise,
     mBurstLength  : arg.get.burstLength,
     mData         : arg.get.data,
     mByteEn       : arg.get.byteEn,
     mReqInfo      : arg.get.reqInfo,
     mDataInfo     : arg.get.dataInfo,
     sThreadBusy  : arg.sThreadBusy,
     sReset_n     : arg.sReset_n,
     mReset_n     : arg.mReset_n} );
endfunction

// This permutation trasforms Wsi_Es to Wsi_s...
function Wsi_s#(nb,nd,ng,nh,ni) toWsiS(Wsi_Es#(nb,nd,ng,nh,ni) arg);
  return (interface Wsi_s;
    method Action put(WsiReq#(nb,nd,ng,nh,ni) req);
      arg.mCmd         (pack(req.cmd));
      arg.mReqLast     ();
      arg.mBurstPrecise();
      arg.mBurstLength (req.burstLength);
      arg.mData        (req.data);
      arg.mByteEn      (req.byteEn   );
      arg.mReqInfo     (req.reqInfo  );
      arg.mDataInfo    (req.dataInfo );
    endmethod
    method     sThreadBusy = arg.sThreadBusy;
    method        sReset_n = arg.sReset_n;
    method Action mReset_n = arg.mReset_n;
  endinterface);
endfunction

// Credit: Hadar - This module's signature nearly looks like the function we cant write...
module mkWsiStoES#(Wsi_s#(nb,nd,ng,nh,ni) arg) ( Wsi_Es#(nb,nd,ng,nh,ni));
  Wire#(Bit#(3))   mCmd_w           <- mkDWire(0);
  PulseWire        mReqLast_w       <- mkPulseWire;          
  PulseWire        mBurstPrecise_w  <- mkPulseWire;
  Wire#(Bit#(nb))  mBurstLength_w   <- mkDWire(0);
  Wire#(Bit#(nd))  mData_w          <- mkDWire(0);
  Wire#(Bit#(ng))  mByteEn_w        <- mkDWire(0);
  Wire#(Bit#(nh))  mReqInfo_w       <- mkDWire(0);
  Wire#(Bit#(ni))  mDataInfo_w      <- mkDWire(0);

  rule doAlways;
     WsiReq#(nb,nd,ng,nh,ni)req = WsiReq {
       cmd          : unpack(mCmd_w),
       reqLast      : mReqLast_w,
       burstPrecise : mBurstPrecise_w,
       burstLength  : mBurstLength_w,
       data         : mData_w,
       byteEn       : mByteEn_w,
       reqInfo      : mReqInfo_w,
       dataInfo     : mDataInfo_w
    };
    arg.put(req);
  endrule

  method Action  mCmd(in)         = mCmd_w._write(in);
  method Action  mReqLast         = mReqLast_w.send();
  method Action  mBurstPrecise    = mBurstPrecise_w.send();
  method Action  mBurstLength(x)  = mBurstLength_w ._write(x);
  method Action  mData(x)         = mData_w        ._write(x);
  method Action  mByteEn(x)       = mByteEn_w      ._write(x);
  method Action  mReqInfo(x)      = mReqInfo_w     ._write(x);
  method Action  mDataInfo(x)     = mDataInfo_w    ._write(x);
  method     sThreadBusy = arg.sThreadBusy;
  method        sReset_n = arg.sReset_n;
  method Action mReset_n = arg.mReset_n;
endmodule

//
// WSI Support Functions
//

function Bool isAborted(WsiReq#(nb,nd,ng,nh,ni) w);
  return(False); // Abort is MFlag[0] when configured
  //return unpack(w.dataInfo[0]);  //TODO: Extract the correct bit position based on WIP attributes
endfunction

//
// WsiMaster is convienience IP for OpenCPI that wraps up the WSI Master Role
//
interface WsiMasterIfc#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  interface Put#(WsiReq#(nb,nd,ng,nh,ni))  reqPut;   // The WSI Request Put
  method Action                            operate;  // Assert to operate
  method Bool                              reqFifoNotFull; 
  method WipDataPortStatus                 status;    
  method WipDataPortExtendedStatus         extStatus;
  interface Wsi_m#(nb,nd,ng,nh,ni) mas; // OCP-IP WSI Master 
endinterface

module mkWsiMaster (WsiMasterIfc#(nb,nd,ng,nh,ni));
  //Clock                               clk              <- exposeCurrentClock;
  //Reset                               rstLocal         <- exposeCurrentReset;
  //MakeResetIfc                        rstRemote        <- mkReset(0,True,clk);
  //Reset                               rstEither        <- mkResetEither
  ReadOnly#(Bool)                     isReset          <- isResetAsserted;
  FIFOF#(WsiReq#(nb,nd,ng,nh,ni))     reqFifo          <- mkDFIFOF(wsiIdleRequest);
  PulseWire                           sThreadBusy_pw   <- mkPulseWire;
  Reg#(Bool)                          sThreadBusy_d    <- mkReg(True);
  Reg#(Bool)                          operateD         <- mkDReg(False);
  Reg#(Bool)                          peerIsReady      <- mkDReg(False);

  Reg#(WipDataPortStatus)             statusR          <- mkConfigRegU;
  Reg#(Bool)                          errorSticky      <- mkReg(False);
  Reg#(Bool)                          trafficSticky    <- mkReg(False);
  Reg#(OCP_BURST)                     burstKind        <- mkReg(None);
  Reg#(Bit#(32))                      pMesgCount       <- mkReg(0);
  Reg#(Bit#(32))                      iMesgCount       <- mkReg(0);
  Reg#(Bit#(32))                      tBusyCount       <- mkReg(0);
  Wire#(WipDataPortExtendedStatus)    extStatusW       <- mkBypassWire;

  Bool isBusy    = (burstKind!=None);
  Bool linkReady = (operateD && peerIsReady);
  rule sThreadBusy_reg; sThreadBusy_d <= sThreadBusy_pw; endrule
  //TODO: Move this rule action to be atomic with reqFifo.first()...
  //TODO: Make daignostic behavior correct when r.reqlast is on the first and only cycle of a message
  rule reqFifo_deq (reqFifo.notEmpty && !sThreadBusy_d);
    let r = reqFifo.first;
    if (r.cmd==WR) begin
      case (burstKind)
        None      :  burstKind <= (r.burstPrecise) ? Precise : Imprecise;
        Precise   :  begin if (r.reqLast) begin burstKind <= None; pMesgCount<=pMesgCount+1; end end
        Imprecise :  begin if (r.reqLast) begin burstKind <= None; iMesgCount<=iMesgCount+1; end end
      endcase
      trafficSticky <= True;
    end
    reqFifo.deq();
  endrule
  rule inc_tBusyCount (linkReady && sThreadBusy_d); tBusyCount <= tBusyCount + 1; endrule
  rule ext_status_assign; extStatusW <= WipDataPortExtendedStatus {pMesgCount:pMesgCount, iMesgCount:iMesgCount, tBusyCount:tBusyCount}; endrule

  //TODO: Factor the (nearly) common WipDataPortStatus and ExtendedStatus into reused module or function
  rule update_statusR;
    statusR <= WipDataPortStatus {
      localReset      : isReset,       // 7:  This port is reset
      partnerReset    : !peerIsReady,  // 6:  The connected partner port is reset
      notOperatonal   : !operateD,     // 5:  This port is not Operational
      observedError   : errorSticky,   // 4:  An error has been observed since port became operational (sticky)
      inProgress      : isBusy,        // 3:  A message is in progress at this port
      sThreadBusy     : sThreadBusy_d, // 2:  Present value of SThreadBusy
      sDataThreadBusy : False,         // 1:  Present value of SDataThreadBusy (datahandshakeonly)
      observedTraffic : trafficSticky  // 0:  Traffic has moved across this port since it became operational (sticky)
    };
  endrule

  // User-facing Methods...
  interface reqPut = toPut(reqFifo);
  method Action operate = operateD._write(True);
  method Bool reqFifoNotFull = reqFifo.notFull; 
  method WipDataPortStatus status = statusR;    
  method WipDataPortExtendedStatus extStatus = extStatusW;

  interface Wsi_m mas; // OCP-IP Master Interface Methods...
    method WsiReq#(nb,nd,ng,nh,ni) get = sThreadBusy_d ? wsiIdleRequest : reqFifo.first;
    method Action sThreadBusy = sThreadBusy_pw.send;
    method mReset_n = !(isReset || !operateD);
    method Action sReset_n = peerIsReady._write(True);
  endinterface
endmodule


//
// WsiSlave is convienience IP for OpenCPI that wraps up the WSI Slave Role
//
interface WsiSlaveIfc#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  interface Get#(WsiReq#(nb,nd,ng,nh,ni)) reqGet;   // The WSI Request Get
  method    WsiReq#(nb,nd,ng,nh,ni)       reqPeek;  // The WSI Request Peek
  method Action                           operate;  // Assert to operate
  method WipDataPortStatus                status;    
  method WipDataPortExtendedStatus        extStatus;
  method Bit#(nb)                         wordsThisMessage; //TODO: Make this not matter precise vs imprecise - still use (nb)?
  interface Wsi_s#(nb,nd,ng,nh,ni) slv; // OCP-IP WSI Slave
endinterface

module mkWsiSlave (WsiSlaveIfc#(nb,nd,ng,nh,ni));
  Wire#(WsiReq#(nb,nd,ng,nh,ni))                 wsiReq          <- mkWire;
  FIFOLevelIfc#(WsiReq#(nb,nd,ng,nh,ni),SRBsize) reqFifo         <- mkFIFOLevel;
  ReadOnly#(Bool)                                isReset         <- isResetAsserted;
  Reg#(Bool)                                     operateD        <- mkDReg(False);
  Reg#(Bool)                                     peerIsReady     <- mkDReg(False);
  Wire#(Bool)                                    sThreadBusy_dw  <- mkDWire(True);  // Default True applies SThreadBusy Backpressure

  Reg#(WipDataPortStatus)                        statusR         <- mkConfigRegU;
  Reg#(Bool)                                     errorSticky     <- mkReg(False);
  Reg#(Bool)                                     trafficSticky   <- mkReg(False);
  Reg#(OCP_BURST)                                burstKind       <- mkReg(None);
  Reg#(Bit#(32))                                 pMesgCount      <- mkReg(0);
  Reg#(Bit#(32))                                 iMesgCount      <- mkReg(0);
  Reg#(Bit#(32))                                 tBusyCount      <- mkReg(0);
  Wire#(WipDataPortExtendedStatus)               extStatusW      <- mkBypassWire;
  Reg#(Bit#(nb))                                 wordCount       <- mkReg(1);
  Reg#(Bit#(nb))                                 mesgWordLength  <- mkRegU;

  Bool isBusy    = (burstKind!=None);
  Bool linkReady = (operateD && peerIsReady);

  // Only when this rule fires (which requires the implicit condition on reqFifo.isGreaterThan) will we drive sThreadBusy_dw low...
  rule backpressure (linkReady);
    sThreadBusy_dw <= (reqFifo.isGreaterThan(valueOf(SRBsize)-2)); // for correct SThreadBusy behavior
  endrule

  // This rule fires on the OCP-Wire Side of the Slave convienience IP...
  rule reqFifo_enq (linkReady && wsiReq.cmd==WR);
    let r = wsiReq;
    reqFifo.enq(r); 
    if (r.cmd==WR) begin
      wordCount <= (r.reqLast) ? 1 : wordCount + 1; // reset message wordCount to one on reqLast
      if (r.reqLast) mesgWordLength <= wordCount;   // transfer the wordCount to mesgWordLengh for user to observe Value method
      case (burstKind)
        None      :  burstKind <= (r.burstPrecise) ? Precise : Imprecise;
        Precise   :  begin if (r.reqLast) begin burstKind <= None; pMesgCount<=pMesgCount+1; end end
        Imprecise :  begin if (r.reqLast) begin burstKind <= None; iMesgCount<=iMesgCount+1; end end
      endcase
      trafficSticky <= True;
    end
  endrule

  rule inc_tBusyCount (linkReady && sThreadBusy_dw); tBusyCount <= tBusyCount + 1; endrule
  rule ext_status_assign; extStatusW <= WipDataPortExtendedStatus {pMesgCount:pMesgCount, iMesgCount:iMesgCount, tBusyCount:tBusyCount}; endrule

  rule update_statusR;
    statusR <= WipDataPortStatus {
      localReset      : isReset,        // 7:  This port is reset
      partnerReset    : !peerIsReady,   // 6:  The connected partner port is reset
      notOperatonal   : !operateD,      // 5:  This port is not Operational
      observedError   : errorSticky,    // 4:  An error has been observed since port became operational (sticky)
      inProgress      : isBusy,         // 3:  A message is in progress at this port
      sThreadBusy     : sThreadBusy_dw, // 2:  Present value of SThreadBusy
      sDataThreadBusy : False,          // 1:  Present value of SDataThreadBusy (datahandshakeonly)
      observedTraffic : trafficSticky   // 0:  Traffic has moved across this port since it became operational (sticky)
    };
  endrule
  
  // User-facing Methods...
  interface reqGet = toGet(reqFifo);
  method WsiReq#(nb,nd,ng,nh,ni) reqPeek = reqFifo.first;
  method Action operate = operateD._write(True);
  method WipDataPortStatus status = statusR;    
  method WipDataPortExtendedStatus extStatus = extStatusW;
  method Bit#(nb) wordsThisMessage = mesgWordLength;        // provides length of last complete message in words

  interface Wsi_s slv; // OCP-IP Slave Interface Methods...
    method Action put(WsiReq#(nb,nd,ng,nh,ni) req) = wsiReq._write(req);
    method sThreadBusy = sThreadBusy_dw;
    method sReset_n = !(isReset || !operateD);
    method Action mReset_n = peerIsReady._write(True);
  endinterface
endmodule

//
// WSI OBSERVER...
//

//
// WsiObserver is convienience IP for OpenCPI that observes the WSI transactions
//
interface WsiObserverIfc#(numeric type nb, numeric type nd, numeric type ng, numeric type nh, numeric type ni);
  interface Wsi_Eo#(nb,nd,ng,nh,ni)  wsi;
  interface Get#(PMEM)               seen;
endinterface

module mkWsiObserver (WsiObserverIfc#(nb,nd,ng,nh,ni)) provisos(Add#(nd,0,32),Add#(ng,0,4));
  // Register the observer inputs to minimze and equalize the obseerved link's loading...
  Reg#(Bit#(3))      r_mCmd          <-   mkReg(0);
  Reg#(Bit#(1))      r_mReqLast      <-   mkDReg(0);
  Reg#(Bit#(1))      r_mBurstPrecise <-   mkDReg(0);
  Reg#(Bit#(nb))     r_mBurstLength  <-   mkReg(0);
  Reg#(Bit#(nd))     r_mData         <-   mkReg(0);
  Reg#(Bit#(ng))     r_mByteEn       <-   mkReg(0);
  Reg#(Bit#(nh))     r_mReqInfo      <-   mkReg(0);
  Reg#(Bit#(ni))     r_mDataInfo     <-   mkReg(0);
  Reg#(Bit#(1))      r_sThreadBusy   <-   mkDReg(0);
  Reg#(Bit#(1))      r_sReset_n      <-   mkDReg(0);
  Reg#(Bit#(1))      r_mReset_n      <-   mkDReg(0);

  FIFO#(PMEM)        evF             <-   mkFIFO;
  Reg#(Bit#(3))      r_mCmdD         <-   mkReg(0);
  Reg#(Bit#(1))      r_sResetnD      <-   mkReg(0);
  Reg#(Bit#(1))      r_mResetnD      <-   mkReg(0);

  BoolEdgeIfc        e_sThreadBusy   <-   mkBoolEdge(unpack(r_sThreadBusy));

  // For observing temporal changes
  (* fire_when_enabled, no_implicit_conditions *) rule doAlways (True);
    r_mCmdD        <= r_mCmd;
    r_sResetnD     <= r_sReset_n;
    r_mResetnD     <= r_mReset_n;
  endrule

  rule request_detected (r_mCmdD==pack(IDLE) && r_mCmd!=pack(IDLE)); 
    case (unpack(r_mCmd))
      WR : evF.enq(PMEM_2DW (PM_2DW{eType:pmNibble(PMEV_WRITE_REQUEST,r_mByteEn), data0:r_mData}));
    endcase
  endrule

  rule reqlast_detected (unpack(r_mReqLast)); 
    evF.enq(PMEM_2DW (PM_2DW{eType:PMEV_REQLAST_ASSERT, data0:r_mData}));
  endrule

  rule backpressure_leading_detected (e_sThreadBusy.rising); 
    evF.enq(PMEM_1DW (PM_1DW{eType:PMEV_BPRESSURE_ASSERT}));
  endrule

  rule backpressure_trailing_detected (e_sThreadBusy.falling); 
    evF.enq(PMEM_1DW (PM_1DW{eType:PMEV_BPRESSURE_DEASSERT}));
  endrule

  interface Wsi_Eo wsi;
    method Action   mCmd         (Bit#(3)  arg_cmd);          r_mCmd           <= arg_cmd;         endmethod
    method Action   mReqLast;                                 r_mReqLast       <= 1'b1;            endmethod
    method Action   mBurstPrecise;                            r_mBurstPrecise  <= 1'b1;            endmethod
    method Action   mBurstLength (Bit#(nb) arg_burstLength);  r_mBurstLength   <= arg_burstLength; endmethod
    method Action   mData        (Bit#(nd) arg_data);         r_mData          <= arg_data;        endmethod
    method Action   mByteEn      (Bit#(ng) arg_byteEn);       r_mByteEn        <= arg_byteEn;      endmethod
    method Action   mReqInfo     (Bit#(nh) arg_reqInfo);      r_mReqInfo       <= arg_reqInfo;     endmethod
    method Action   mDataInfo    (Bit#(ni) arg_datInfo);      r_mDataInfo      <= arg_datInfo;     endmethod
    method Action   sThreadBusy;                              r_sThreadBusy    <= 1'b1;            endmethod
    method Action   sReset_n;                                 r_sReset_n       <= 1'b1;            endmethod
    method Action   mReset_n;                                 r_mReset_n       <= 1'b1;            endmethod
  endinterface
  interface Get seen = toGet(evF); // Get what we've "seen" from the event FIFO
endmodule

endpackage: OCWsi
