// OCWmi.bsv OpenCPI Worker Message Interface (WMI)
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWmi;

import OCWipDefs::*;

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

// WIP::WMI Attributes...
typedef struct {
  Bool continuous;       // True means no IDLE cycles within a burst
  UInt#(32) dataWidth;   // Width in bits of the data path
  UInt#(32) byteWidth;   // Derived from other attributes
  Bool impreciseBurst;   // True means Imprecise OCP bursts will be used
  Bool preciseBurst;     // True means Precise OCP bursts will be used
  Bool talkBack;         // True means wants/needs to writeback inbut or readback output buffer
} WmiAttributes deriving (Bits, Eq);

instance DefaultValue#(WmiAttributes);
 defaultValue = WmiAttributes {
  continuous     : False,
  dataWidth      : 8,
  byteWidth      : ?,
  impreciseBurst : False,
  preciseBurst   : False,
  talkBack       : False
  };
endinstance

// 
// Worker Messaging Interface (WMI)...
// 
// na - number of bits in Byte Address
// nb - number of bits in Burst Length (BL is # of transfer cycles in a burst)
// nd - number of bits in {M|S}Data 
// ni - number of bits in DataInfo
// ne - number of bits in DataByteEn
// nf - number of bits in {M|S}Flag (8 OpCode + Message Length)
// 
typeclass DWordWidth#(numeric type ndw); endtypeclass
instance  DWordWidth#(1); endinstance // 1DW,  4B.  32b
instance  DWordWidth#(2); endinstance // 2DW,  8B,  64b
instance  DWordWidth#(4); endinstance // 4DW, 16B, 128b
instance  DWordWidth#(8); endinstance // 8DW, 32B, 256b

// WMI convienience type synonyms, "SuperProfiles"...
typedef Wmi_m#(14,12, 32,0, 4,32) WmiM4B;
typedef Wmi_s#(14,12, 32,0, 4,32) WmiS4B;
typedef Wmi_m#(14,12, 64,0, 8,32) WmiM8B;
typedef Wmi_s#(14,12, 64,0, 8,32) WmiS8B;
typedef Wmi_m#(14,12,128,0,16,32) WmiM16B;
typedef Wmi_s#(14,12,128,0,16,32) WmiS16B;
typedef Wmi_m#(14,12,256,0,32,32) WmiM32B;
typedef Wmi_s#(14,12,256,0,32,32) WmiS32B;
// Explicit flavors...
typedef Wmi_Em#(14,12, 32,0, 4,32) WmiEM4B;
typedef Wmi_Es#(14,12, 32,0, 4,32) WmiES4B;
typedef Wmi_Em#(14,12, 64,0, 8,32) WmiEM8B;
typedef Wmi_Es#(14,12, 64,0, 8,32) WmiES8B;
typedef Wmi_Em#(14,12,128,0,16,32) WmiEM16B;
typedef Wmi_Es#(14,12,128,0,16,32) WmiES16B;
typedef Wmi_Em#(14,12,256,0,32,32) WmiEM32B;
typedef Wmi_Es#(14,12,256,0,32,32) WmiES32B;


typedef struct {
  OCP_CMD  cmd;           // IDLE WR RD (non-Idle qualifies group)
  Bool     reqLast;       // Last cycle of request
  Bit#(1)  reqInfo;       // Done With Message (DWM)
  Bit#(1)  addrSpace;     // No-Data Indication (1==NoData)
  Bit#(na) addr;          // Byte Address (na)
  Bit#(nb) burstLength;   // polymorhic burst length (nb) 
} WmiReq#(numeric type na, numeric type nb) deriving (Bits, Eq);

typedef struct {
  Bool     dataValid;     // Data Valid (True qualifies this group)
  Bool     dataLast;      // Last cycle of data
  Bit#(nd) data;          // polymorphic data width (nd)
  Bit#(ni) dataInfo;      // polymorphic data info  (ni)
  Bit#(ne) dataByteEn;    // 1=byte lane enabled    (ne)
} WmiDh#(numeric type nd, numeric type ni, numeric type ne) deriving (Bits, Eq);

typedef struct {
  OCP_RESP resp;          // OCP Response (non-Null qualifies group)
  Bit#(nd) data;          // polymorphic data width (nd)
} WmiResp#(numeric type nd) deriving (Bits, Eq);

  WmiReq#(na,nb)   wmiIdleRequest = WmiReq  {cmd:IDLE,reqLast:False,reqInfo:0,addrSpace:0,addr:0,burstLength:0};
  WmiDh#(nd,ni,ne) wmiIdleDh      = WmiDh   {dataValid:False,dataLast:False,data:0,dataInfo:0,dataByteEn:0};
  WmiResp#(nd)     wmiIdleResp    = WmiResp {resp:NULL,data:0};

(* always_ready *)
interface Wmi_m#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  (* result = "req" *)                     method WmiReq#(na,nb)   getReq;
  (* result = "dh" *)                      method WmiDh#(nd,ni,ne) getDh;
  (* prefix = "", always_enabled*)         method Action           putResp(WmiResp#(nd) resp);
  (* prefix="", enable="SThreadBusy"*)     method Action           sThreadBusy;
  (* prefix="", enable="SDataThreadBusy"*) method Action           sDataThreadBusy;
  (* prefix="", enable="SRespLast"*)       method Action           sRespLast;
  (* prefix="", always_enabled *)          method Action           sFlag ((*port="SFlag"*) Bit#(nf) sf);
  (* prefix="", result="MFlag"      *)     method Bit#(nf)         mFlag;
  (* prefix="", result="MReset_n"*)        method Bool             mReset_n;
  (* prefix="", enable="SReset_n"*)        method Action           sReset_n;
endinterface 

(* always_ready *)
interface Wmi_s#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  (* prefix="", always_enabled *)          method Action           putReq (WmiReq#(na,nb)  req);
  (* prefix="", always_enabled *)          method Action           putDh  (WmiDh#(nd,ni,ne) dh);
  (* result = "resp" *)                    method WmiResp#(nd)     getResp();
  (* prefix="", result="SThreadBusy"*)     method Bool             sThreadBusy;
  (* prefix="", result="SDataThreadBusy"*) method Bool             sDataThreadBusy;
  (* prefix="", result="SRespLast"*)       method Bool             sRespLast;
  (* prefix="", result="SFlag"      *)     method Bit#(nf)         sFlag;
  (* prefix="", always_enabled *)          method Action           mFlag ((*port="MFlag"*) Bit#(nf) mf);
  (* prefix="", result="SReset_n"*)        method Bool             sReset_n;
  (* prefix="", enable="MReset_n"*)        method Action           mReset_n;
endinterface 

// Explicit OCP per-signal naming to purposefully to avoid data-structures and have explict OCP names...
(* always_ready *)
interface Wmi_Em#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  (* prefix="", result="MCmd" *)           method Bit#(3)  mCmd;
  (* prefix="", result="MReqLast" *)       method Bool     mReqLast;
  (* prefix="", result="MReqInfo" *)       method Bit#(1)  mReqInfo;
  (* prefix="", result="MAddrSpace" *)     method Bit#(1)  mAddrSpace;
  (* prefix="", result="MAddr" *)          method Bit#(na) mAddr;
  (* prefix="", result="MBurstLength" *)   method Bit#(nb) mBurstLength;
  (* prefix="", result="MDataValid" *)     method Bool     mDataValid;
  (* prefix="", result="MDataLast" *)      method Bool     mDataLast;
  (* prefix="", result="MData" *)          method Bit#(nd) mData;
  (* prefix="", result="MDataInfo" *)      method Bit#(ni) mDataInfo;
  (* prefix="", result="MDataByteEn" *)    method Bit#(ne) mDataByteEn;
  (* prefix="", always_enabled *)          method Action   sResp        ((* port="SResp" *) Bit#(2)  arg_resp);
  (* prefix="", always_enabled *)          method Action   sData        ((* port="SData" *) Bit#(nd) arg_data);
  (* prefix="", enable="SThreadBusy" *)    method Action   sThreadBusy;
  (* prefix="", enable="SDataThreadBusy"*) method Action   sDataThreadBusy;
  (* prefix="", enable="SRespLast"*)       method Action   sRespLast;
  (* prefix="", always_enabled *)          method Action   sFlag        ((*port="SFlag"*)   Bit#(nf) arg_sFlag);
  (* prefix="", result="MFlag" *)          method Bit#(nf) mFlag;
  (* prefix="", result="MReset_n"*)        method Bool     mReset_n;
  (* prefix="", enable="SReset_n"*)        method Action   sReset_n;
endinterface

(* always_ready *)
interface Wmi_Es#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  (* prefix="", always_enabled *)          method Action   mCmd         ((* port="MCmd" *)         Bit#(3)  arg_cmd);
  (* prefix="", enable="MReqLast" *)       method Action   mReqLast;
  (* prefix="", always_enabled *)          method Action   mReqInfo     ((* port="MReqInfo" *)     Bit#(1)  arg_reqInfo);
  (* prefix="", always_enabled *)          method Action   mAddrSpace   ((* port="MAddrSpace" *)   Bit#(1)  arg_addrSpace);
  (* prefix="", always_enabled *)          method Action   mAddr        ((* port="MAddr" *)        Bit#(na) arg_addr);
  (* prefix="", always_enabled *)          method Action   mBurstLength ((* port="MBurstLength" *) Bit#(nb) arg_burstLength);
  (* prefix="", enable="MDataValid" *)     method Action   mDataValid;
  (* prefix="", enable="MDataLast" *)      method Action   mDataLast;
  (* prefix="", always_enabled *)          method Action   mData        ((* port="MData" *)        Bit#(nd) arg_data);
  (* prefix="", always_enabled *)          method Action   mDataInfo    ((* port="MDataInfo" *)    Bit#(ni) arg_dataInfo);
  (* prefix="", always_enabled *)          method Action   mDataByteEn  ((* port="MDataByteEn" *)  Bit#(ne) arg_byteEn);
  (* prefix="", result="SResp" *)          method Bit#(2)  sResp;
  (* prefix="", result="SData" *)          method Bit#(nd) sData;
  (* prefix="", result="SThreadBusy"*)     method Bool     sThreadBusy;
  (* prefix="", result="SDataThreadBusy"*) method Bool     sDataThreadBusy;
  (* prefix="", result="SRespLast"*)       method Bool     sRespLast;
  (* prefix="", result="SFlag"      *)     method Bit#(nf) sFlag;
  (* prefix="", always_enabled *)          method Action   mFlag (Bit#(nf) arg_mFlag);
  (* prefix="", result="SReset_n"*)        method Bool     sReset_n;
  (* prefix="", enable="MReset_n"*)        method Action   mReset_n;
endinterface


//
// The Four Connectable M/S instances..
// Connect a Explicitly-named master to a Explicitly-named slave...
instance Connectable#( Wmi_Em#(na,nb,nd,ni,ne,nf), Wmi_Es#(na,nb,nd,ni,ne,nf) );
  module mkConnection#(Wmi_Em#(na,nb,nd,ni,ne,nf) master , Wmi_Es#(na,nb,nd,ni,ne,nf) slave ) ();
    rule mCmdConnect;    slave.mCmd(master.mCmd);                        endrule 
    rule mReqLConnect   (master.mReqLast);      slave.mReqLast;          endrule 
    rule mReqIConnect;   slave.mReqInfo(master.mReqInfo);                endrule 
    rule mAddrSConnect;  slave.mAddrSpace(master.mAddrSpace);            endrule 
    rule mAddrConnect;   slave.mAddr(master.mAddr);                      endrule 
    rule mBurstLConnect; slave.mBurstLength(master.mBurstLength);        endrule 
    rule mDataVConnect   (master.mDataValid);   slave.mDataValid;        endrule 
    rule mDataLConnect   (master.mDataLast);    slave.mDataLast;         endrule 
    rule mDataConnect;   slave.mData(master.mData);                      endrule 
    rule mDataIConnect;  slave.mDataInfo(master.mDataInfo);              endrule 
    rule mDataBEConnect; slave.mDataByteEn(master.mDataByteEn);          endrule 
    rule sRespConnect;   master.sResp(slave.sResp);                      endrule 
    rule sDataConnect;   master.sData(slave.sData);                      endrule
    rule stbConnect  (slave.sThreadBusy);     master.sThreadBusy;        endrule
    rule sdtbConnect (slave.sDataThreadBusy); master.sDataThreadBusy;    endrule
    rule srlConnect  (slave.sRespLast); master.sRespLast;                endrule
    rule sFlagConnect; master.sFlag(slave.sFlag);                        endrule
    rule mFlagConnect; slave.mFlag(master.mFlag);                        endrule
    (*fire_when_enabled, no_implicit_conditions*)
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                 endrule 
    (*fire_when_enabled, no_implicit_conditions*)
    rule sRstConnect (slave.sReset_n);  master.sReset_n;                 endrule
  endmodule
endinstance
   
// Connect a "conventional" master to a Explicitly-named slave...
instance Connectable#( Wmi_m#(na,nb,nd,ni,ne,nf), Wmi_Es#(na,nb,nd,ni,ne,nf) );
  module mkConnection#(Wmi_m#(na,nb,nd,ni,ne,nf) master , Wmi_Es#(na,nb,nd,ni,ne,nf) slave ) ();
    rule mCmdConnect;    slave.mCmd(pack(master.getReq.cmd));             endrule 
    rule mReqLConnect   (master.getReq.reqLast);      slave.mReqLast;     endrule 
    rule mReqIConnect;   slave.mReqInfo(master.getReq.reqInfo);           endrule 
    rule mAddrSConnect;  slave.mAddrSpace(master.getReq.addrSpace);       endrule 
    rule mAddrConnect;   slave.mAddr(master.getReq.addr);                 endrule 
    rule mBurstLConnect; slave.mBurstLength(master.getReq.burstLength);   endrule 
    rule mDataVConnect   (master.getDh.dataValid);   slave.mDataValid;    endrule 
    rule mDataLConnect   (master.getDh.dataLast);    slave.mDataLast;     endrule 
    rule mDataConnect;   slave.mData(master.getDh.data);                  endrule 
    rule mDataIConnect;  slave.mDataInfo(master.getDh.dataInfo);          endrule 
    rule mDataBEConnect; slave.mDataByteEn(master.getDh.dataByteEn);      endrule 
    rule respConnect;
      WmiResp#(nd) resp = WmiResp {
        resp : unpack(slave.sResp),
        data : slave.sData};
      master.putResp(resp);
    endrule
    rule stbConnect  (slave.sThreadBusy);     master.sThreadBusy;         endrule
    rule sdtbConnect (slave.sDataThreadBusy); master.sDataThreadBusy;     endrule
    rule srlConnect  (slave.sRespLast); master.sRespLast;                 endrule
    rule sFlagConnect; master.sFlag(slave.sFlag);                         endrule 
    rule mFlagConnect; slave.mFlag(master.mFlag);                         endrule
    (*fire_when_enabled, no_implicit_conditions*)
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                  endrule 
    (*fire_when_enabled, no_implicit_conditions*)
    rule sRstConnect (slave.sReset_n);  master.sReset_n;                  endrule
  endmodule
endinstance
   
// Connect a Explicitly-named master to a "conventional" slave...
instance Connectable#( Wmi_Em#(na,nb,nd,ni,ne,nf), Wmi_s#(na,nb,nd,ni,ne,nf) );
  module mkConnection#(Wmi_Em#(na,nb,nd,ni,ne,nf) master , Wmi_s#(na,nb,nd,ni,ne,nf) slave ) ();
    rule reqConnect;
      WmiReq#(na,nb) req = WmiReq {
         cmd          : unpack(master.mCmd),
         reqLast      : master.mReqLast,
         reqInfo      : master.mReqInfo,
         addrSpace    : master.mAddrSpace,
         addr         : master.mAddr,
         burstLength  : master.mBurstLength};
      slave.putReq(req);
    endrule
    rule dhConnect;
      WmiDh#(nd,ni,ne) dh = WmiDh {
         dataValid    : master.mDataValid,
         dataLast     : master.mDataLast,
         data         : master.mData,
         dataInfo     : master.mDataInfo,
         dataByteEn   : master.mDataByteEn};
      slave.putDh(dh);
    endrule
    rule sRespConnect;  master.sResp(pack(slave.getResp.resp));          endrule
    rule sDataConnect;  master.sData(slave.getResp.data);                endrule
    rule stbConnect  (slave.sThreadBusy);     master.sThreadBusy;        endrule
    rule sdtbConnect (slave.sDataThreadBusy); master.sDataThreadBusy;    endrule
    rule srlConnect  (slave.sRespLast); master.sRespLast;                endrule
    rule sFlagConnect; master.sFlag(slave.sFlag);                        endrule 
    rule mFlagConnect; slave.mFlag(master.mFlag);                        endrule
    (*fire_when_enabled, no_implicit_conditions*)
    rule mRstConnect (master.mReset_n);  slave.mReset_n;                 endrule 
    (*fire_when_enabled, no_implicit_conditions*)
    rule sRstConnect (slave.sReset_n);  master.sReset_n;                 endrule
  endmodule
endinstance
   
// Connect a "conventional" master to a "conventional" slave...
instance Connectable#( Wmi_m#(na,nb,nd,ni,ne,nf), Wmi_s#(na,nb,nd,ni,ne,nf) );
  module mkConnection#(Wmi_m#(na,nb,nd,ni,ne,nf) master , Wmi_s#(na,nb,nd,ni,ne,nf) slave ) ();
    rule reqConnect; slave.putReq(master.getReq());    endrule                // Request Group
    rule dhConnect;  slave.putDh(master.getDh());      endrule                // Datahandshake Group
    rule respConnect; master.putResp(slave.getResp()); endrule                // Response Group
    rule stbConnect  (slave.sThreadBusy);     master.sThreadBusy;     endrule // sThreadBusy
    rule sdtbConnect (slave.sDataThreadBusy); master.sDataThreadBusy; endrule // sDataThreadBusy
    rule srlConnect  (slave.sRespLast);       master.sRespLast;       endrule // sRespLast
    rule sFlagConnect; master.sFlag(slave.sFlag); endrule                     // sFlag
    rule mFlagConnect; slave.mFlag(master.mFlag); endrule                     // mFlag
    (*fire_when_enabled, no_implicit_conditions*)
    rule mRstConnect (master.mReset_n);  slave.mReset_n;  endrule 
    (*fire_when_enabled, no_implicit_conditions*)
    rule sRstConnect (slave.sReset_n);  master.sReset_n;  endrule
  endmodule
endinstance

// The Four function/module permutations are used to expand/collapse Masters and Slaves...
// This permutation trasforms Wmi_Em to Wmi_m...
function Wmi_m#(na,nb,nd,ni,ne,nf) toWmiM(Wmi_Em#(na,nb,nd,ni,ne,nf) arg);
  WmiReq#(na,nb) req = WmiReq {
    cmd          : unpack(arg.mCmd),
    reqLast      : arg.mReqLast,
    reqInfo      : arg.mReqInfo,
    addrSpace    : arg.mAddrSpace,
    addr         : arg.mAddr,
    burstLength  : arg.mBurstLength };
  WmiDh#(nd,ni,ne) dh = WmiDh {
    dataValid    : arg.mDataValid,
    dataLast     : arg.mDataLast,
    data         : arg.mData,
    dataInfo     : arg.mDataInfo,
    dataByteEn   : arg.mDataByteEn };
 return (interface Wmi_m;
  method              getReq = req;
  method              getDh  = dh;
  method Action       putResp(WmiResp#(nd) rsp);
    arg.sResp  (pack(rsp.resp));
    arg.sData  (rsp.data);
  endmethod
  method Action  sThreadBusy         = arg.sThreadBusy;
  method Action  sDataThreadBusy     = arg.sDataThreadBusy;
  method Action  sRespLast           = arg.sRespLast;
  method Action  sFlag (Bit#(nf) sf) = arg.sFlag(sf);
  method         mFlag               = arg.mFlag;
  method         mReset_n            = arg.mReset_n;
  method Action  sReset_n            = arg.sReset_n;
 endinterface);
endfunction

// This permutation trasforms Wmi_m to Wmi_Em...
module mkWmiMtoEm#(Wmi_m#(na,nb,nd,ni,ne,nf) arg) (Wmi_Em#(na,nb,nd,ni,ne,nf));
  Wire#(Bit#(2))   sResp_w       <- mkDWire(0);
  Wire#(Bit#(nd))  sData_w       <- mkDWire(0);

  rule doAlways;
    WmiResp#(nd) rsp = WmiResp { resp:unpack(sResp_w), data:sData_w };
    arg.putResp(rsp);
  endrule

  method         mCmd                = pack(arg.getReq.cmd);
  method         mReqLast            = arg.getReq.reqLast;
  method         mReqInfo            = arg.getReq.reqInfo;
  method         mAddrSpace          = arg.getReq.addrSpace;
  method         mAddr               = arg.getReq.addr;
  method         mBurstLength        = arg.getReq.burstLength;
  method         mDataValid          = arg.getDh.dataValid;
  method         mDataLast           = arg.getDh.dataLast;
  method         mData               = arg.getDh.data;
  method         mDataInfo           = arg.getDh.dataInfo;
  method         mDataByteEn         = arg.getDh.dataByteEn;
  method Action  sResp(in)           = sResp_w._write(in);
  method Action  sData(x)            = sData_w._write(x);
  method Action  sThreadBusy         = arg.sThreadBusy;
  method Action  sDataThreadBusy     = arg.sDataThreadBusy;
  method Action  sRespLast           = arg.sRespLast;
  method Action  sFlag (Bit#(nf) sf) = arg.sFlag(sf);
  method         mFlag               = arg.mFlag;
  method         mReset_n            = arg.mReset_n;
  method Action  sReset_n            = arg.sReset_n;
endmodule

// This permutation trasforms Wmi_Es to Wmi_s...
function Wmi_s#(na,nb,nd,ni,ne,nf) toWmiS(Wmi_Es#(na,nb,nd,ni,ne,nf) arg);
  WmiResp#(nd) resp = WmiResp {
    resp         : unpack(arg.sResp),
    data         : arg.sData };
  return (interface Wmi_s;
    method Action putReq(WmiReq#(na,nb) req);
      arg.mCmd         (pack(req.cmd));
      arg.mReqLast     ();
      arg.mReqInfo     (req.reqInfo  );
      arg.mAddrSpace   (req.addrSpace);
      arg.mAddr        (req.addr);
      arg.mBurstLength (req.burstLength );
    endmethod
    method Action putDh(WmiDh#(nd,ni,ne) dh);
      arg.mDataValid   ();
      arg.mDataLast    ();
      arg.mData        (dh.data);
      arg.mDataInfo    (dh.dataInfo);
      arg.mDataByteEn  (dh.dataByteEn);
    endmethod
    method         getResp = resp;
    method         sThreadBusy         = arg.sThreadBusy;
    method         sDataThreadBusy     = arg.sDataThreadBusy;
    method         sRespLast           = arg.sRespLast;
    method         sFlag               = arg.sFlag;
    method Action  mFlag (Bit#(nf) mf) = arg.mFlag(mf);
    method Action  mReset_n            = arg.mReset_n;
    method         sReset_n            = arg.sReset_n;
 endinterface);
endfunction

// This permutation trasforms Wmi_s to Wmi_Es...
module mkWmiStoES#(Wmi_s#(na,nb,nd,ni,ne,nf) arg) ( Wmi_Es#(na,nb,nd,ni,ne,nf));
  Wire#(Bit#(3))   mCmd_w           <- mkDWire(0);
  PulseWire        mReqLast_w       <- mkPulseWire;          
  Wire#(Bit#(1))   mReqInfo_w       <- mkDWire(0);
  Wire#(Bit#(1))   mAddrSpace_w     <- mkDWire(0);
  Wire#(Bit#(na))  mAddr_w          <- mkDWire(0);
  Wire#(Bit#(nb))  mBurstLength_w   <- mkDWire(0);
  PulseWire        mDataValid_w     <- mkPulseWire;
  PulseWire        mDataLast_w      <- mkPulseWire;
  Wire#(Bit#(nd))  mData_w          <- mkDWire(0);
  Wire#(Bit#(ni))  mDataInfo_w      <- mkDWire(0);
  Wire#(Bit#(ne))  mDataByteEn_w    <- mkDWire(0);

  rule doAlways_Req;
     WmiReq#(na,nb)req = WmiReq {
       cmd          : unpack(mCmd_w),
       reqLast      : mReqLast_w,
       reqInfo      : mReqInfo_w,
       addrSpace    : mAddrSpace_w,
       addr         : mAddr_w,
       burstLength  : mBurstLength_w };
    arg.putReq(req);
  endrule

  rule doAlways_Dh;
     WmiDh#(nd,ni,ne)dh = WmiDh {
       dataValid    : mDataValid_w,
       dataLast     : mDataLast_w,
       data         : mData_w,
       dataInfo     : mDataInfo_w,
       dataByteEn   : mDataByteEn_w };
    arg.putDh(dh);
  endrule

  method Action  mCmd(in)         = mCmd_w._write(in);
  method Action  mReqLast         = mReqLast_w.send();
  method Action  mReqInfo(x)      = mReqInfo_w._write(x);
  method Action  mAddrSpace(x)    = mAddrSpace_w._write(x);
  method Action  mAddr(x)         = mAddr_w._write(x);
  method Action  mBurstLength(x)  = mBurstLength_w._write(x);
  method Action  mDataValid       = mDataValid_w.send();
  method Action  mDataLast        = mDataLast_w.send();
  method Action  mData(x)         = mData_w._write(x);
  method Action  mDataInfo(x)     = mDataInfo_w._write(x);
  method Action  mDataByteEn(x)   = mDataByteEn_w._write(x);
  method         sResp            = pack(arg.getResp.resp);
  method         sData            = arg.getResp.data;
  method         sThreadBusy      = arg.sThreadBusy;
  method         sDataThreadBusy  = arg.sDataThreadBusy;
  method         sRespLast        = arg.sRespLast;
  method         sFlag            = arg.sFlag;
  method Action  mFlag (Bit#(nf) mf) = arg.mFlag(mf);
  method         sReset_n         = arg.sReset_n;
  method Action  mReset_n         = arg.mReset_n;
endmodule



//
// WmiMaster is convienience IP for OpenCPI that wraps up the WMI Master Role
//
interface WmiMasterIfc#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  method Action                req (Bool write, Bit#(na) addr, Bit#(nb) bl, Bool doneWithMessage, Bit#(nf) mf);
  method Action                dh  (Bit#(nd) wdata, Bit#(ne) be, Bool dataLast);
  method ActionValue#(WmiResp#(nd))  resp; 
  method Bool                  attn;
  method Bool                  anyBusy;        // True when either sThreadBusy of sDataThreadBusy asserted
  method Bit#(nf)              peekSFlag;
  method Bit#(8)               reqInfo;  
  method Bit#(24)              mesgLength;
  method Bool                  zeroLengthMesg;
  method Action                operate;
  method WipDataPortStatus     status;
  interface Wmi_m#(na,nb,nd,ni,ne,nf) mas;  // The WMI-OCP Master Interface
endinterface

module mkWmiMaster (WmiMasterIfc#(na,nb,nd,ni,ne,nf)) provisos (Add#(a_,8,nf), Add#(b_,24,nf));
  FIFOF#(WmiReq#(na,nb))       reqF               <- mkDFIFOF(wmiIdleRequest);
  FIFOF#(Bit#(nf))             mFlagF             <- mkDFIFOF('0);
  FIFOF#(WmiDh#(nd,ni,ne))     dhF                <- mkDFIFOF(wmiIdleDh);
  FIFOF#(WmiResp#(nd))         respF              <- mkFIFOF;
  Reg#(Bool)                   busyWithMessage    <- mkReg(False);
  Wire#(WmiResp#(nd))          wmiResponse        <- mkWire;
  Reg#(Bool)                   sThreadBusy_d      <- mkDReg(False);
  Reg#(Bool)                   sDataThreadBusy_d  <- mkDReg(False);
  Reg#(Bit#(nf))               sFlagReg           <- mkReg(0);
  ReadOnly#(Bool)              isReset            <- isResetAsserted;
  Reg#(Bool)                   operateD           <- mkDReg(False);
  Reg#(Bool)                   peerIsReady        <- mkDReg(False);

  Reg#(WipDataPortStatus)      statusR            <- mkConfigRegU;
  Reg#(Bool)                   errorSticky        <- mkReg(False);
  Reg#(Bool)                   trafficSticky      <- mkReg(False);

  Bool linkReady = (operateD && peerIsReady);
  Bool respNULL  = (wmiResponse.resp==NULL);
  Bool respDVA   = (wmiResponse.resp==DVA);
  Bool respFAIL  = (wmiResponse.resp==FAIL);
  Bool respERR   = (wmiResponse.resp==ERR);

  rule reqF_deq (linkReady && !sThreadBusy_d);
    // if producer DWM, deq the message metadata associated with this request...
    if (reqF.first.reqInfo==pack(True)) mFlagF.deq();
    reqF.deq();
  endrule

  rule dhF_deq  (linkReady && !sDataThreadBusy_d);
    dhF.deq();
  endrule

  rule respAdvance (linkReady && !respNULL);
    respF.enq(wmiResponse); // enq the response in the respF  (normal behavior)
  endrule

  //TODO: convert the awkward OCP bl in cycles to a friendly length in Bytes
  method Action req (Bool write, Bit#(na) addr, Bit#(nb) bl, Bool doneWithMessage, Bit#(nf) mf) if (linkReady);
    let r = WmiReq {cmd:write?WR:RD, reqLast:True, reqInfo:pack(doneWithMessage), addrSpace:'b0, addr:addr, burstLength:bl};
    reqF.enq(r);
    if (doneWithMessage) mFlagF.enq(mf); // if producer DWM, enq the message metadata into the mFlagF FIFO
    //$display("[%0d]: %m: req addr:%0x", $time, addr);
  endmethod

  method Action dh (Bit#(nd) wdata, Bit#(ne) be, Bool dataLast) if (linkReady);
    let r = WmiDh {dataValid:True, dataLast:dataLast, data:wdata, dataInfo:0, dataByteEn:be}; //TODO: Implement or Remove dataInfo
    dhF.enq(r);
  endmethod

  method ActionValue#(WmiResp#(nd)) resp;
    let x = respF.first; respF.deq; return x;
  endmethod

  method Bool      attn           = False;
  method Bool      anyBusy        = sThreadBusy_d || sDataThreadBusy_d;
  method Bit#(nf)  peekSFlag      = sFlagReg;
  method Bit#(8)   reqInfo        = truncate(sFlagReg>>24);  
  method Bit#(24)  mesgLength     = truncate(sFlagReg);
  method Bool      zeroLengthMesg = (sFlagReg[23:0]==0);
  method Action    operate        = operateD._write(True);
  method WipDataPortStatus status = statusR;    

  interface Wmi_m mas;
    method WmiReq#(na,nb) getReq   = sThreadBusy_d ? wmiIdleRequest : reqF.first;
    method Bit#(nf)        mFlag   = sThreadBusy_d ? '0             : mFlagF.first;
    method WmiDh#(nd,ni,ne) getDh  = sDataThreadBusy_d ?  wmiIdleDh : dhF.first;
    method Action  putResp(WmiResp#(nd) resp) = wmiResponse._write(resp);
    method Action  sThreadBusy     = sThreadBusy_d._write(True);
    method Action  sDataThreadBusy = sDataThreadBusy_d._write(True);
    method Action  sRespLast       = noAction; //TODO Implement Me!
    method Action  sFlag(Bit#(nf) sf); sFlagReg<=sf; endmethod
    method mReset_n = !(isReset || !operateD);
    method Action  sReset_n = peerIsReady._write(True);
  endinterface 
endmodule

//
// WmiSlave is convienience IP for OpenCPI that wraps up the WMI Slave Role
//
interface WmiSlaveIfc#(numeric type na, numeric type nb, numeric type nd, numeric type ni, numeric type ne, numeric type nf);
  method ActionValue#(WmiReq#(na,nb))   req;
  method ActionValue#(WmiDh#(nd,ni,ne)) dh;
  method ActionValue#(Bit#(nf))         popMFlag;
  method Action                         respd (Bit#(nd) rdata);
  method Action                         drvSFlag(Bit#(nf) sf);
  method Action                         forceSThreadBusy;
  method Action                         allowReq;
  //method Bit#(nf)                       peekMFlag;
  //method Bit#(8)                        reqInfo;  
  //method Bit#(24)                       mesgLength;
  method Action                         operate;
  method WipDataPortStatus              status;
  interface Wmi_s#(na,nb,nd,ni,ne,nf) slv;  // The WMI-OCP Slave Interface
endinterface

module mkWmiSlave (WmiSlaveIfc#(na,nb,nd,ni,ne,nf)) provisos (Add#(a_,8,nf), Add#(b_,24,nf));
  Wire#(WmiReq#(na,nb))               wmiReq               <- mkWire;
  Wire#(Bit#(nf))                     wmiMFlag             <- mkWire;
  Wire#(WmiDh#(nd,ni,ne))             wmiDh                <- mkWire;
  PulseWire                           forceSThreadBusy_pw  <- mkPulseWire;
  FIFOLevelIfc#(WmiReq#(na,nb),SRBsize)   reqF             <- mkFIFOLevel;
  FIFOLevelIfc#(Bit#(nf),SRBsize)         mFlagF           <- mkFIFOLevel;
  FIFOLevelIfc#(WmiDh#(nd,ni,ne),SRBsize) dhF              <- mkFIFOLevel;
  FIFOF#(WmiResp#(nd))                respF                <- mkDFIFOF(wmiIdleResp);
  //Reg#(Bit#(nf))                      mFlagReg             <- mkReg(0);
  Reg#(Bit#(nf))                      sFlagReg             <- mkReg(0);
  Reg#(Bool)                          blockReq             <- mkReg(False);
  ReadOnly#(Bool)                     isReset              <- isResetAsserted;
  Reg#(Bool)                          operateD             <- mkDReg(False);
  Reg#(Bool)                          peerIsReady          <- mkDReg(False);
  Wire#(Bool)                         sThreadBusy_dw       <- mkDWire(True);  // Default True applies SThreadBusy Backpressure
  Wire#(Bool)                         sDataThreadBusy_dw   <- mkDWire(True);  // Default True applies SDataThreadBusy Backpressure

  Reg#(WipDataPortStatus)             statusR              <- mkConfigRegU;
  Reg#(Bool)                          errorSticky          <- mkReg(False);
  Reg#(Bool)                          trafficSticky        <- mkReg(False);

  Bool linkReady = (operateD && peerIsReady);

  // Only when this rule fires (which requires the implicit condition on reqFifo.isGreaterThan) will we drive sThreadBusy_dw low...
  rule backpressure_req (linkReady && !forceSThreadBusy_pw);
    sThreadBusy_dw <= (reqF.isGreaterThan(valueOf(SRBsize)-2)); // for correct SThreadBusy behavior
  endrule
  rule backpressure_dh (linkReady);
    sDataThreadBusy_dw <= (dhF.isGreaterThan(valueOf(SRBsize)-2)); // for correct SDataThreadBusy behavior
  endrule

  rule reqF_enq   (linkReady && wmiReq.cmd!=IDLE); 
    reqF.enq(wmiReq);
  endrule

  // Opcode and Message Size sent M->S on MFlag when DWM is indicated on reqInfo...
  rule mFlagF_enq (linkReady && wmiReq.cmd!=IDLE && wmiReq.reqInfo==pack(True));
    mFlagF.enq(wmiMFlag);
  endrule

  rule dhF_enq    (linkReady && wmiDh.dataValid); 
    dhF.enq(wmiDh);
  endrule

  rule respF_deq; respF.deq(); endrule
  
  // blockReq is used as a predicate to the req method so that req reads are blocked when blockReq is set.
  //   The Master partner is able to ingress requests as best as it can, governed only by the reqF FIFO
  //   depth, and throttled by SThreadBusy. The blockReq register sets when the Slave side dequeues
  //   a request which is the the reqLast and DWM. The user of this module should call the allowReq
  //   method when its local processing is itself "done". This guards the slave IP from taking a request
  //   prematurely, such as may occur in zero or short length messages where the next request may be
  //   ready before the user logic has updated all of its per-message, multi-cycle state.

  method ActionValue#(WmiReq#(na,nb)) req if (linkReady && !blockReq);
    let x = reqF.first;
    if (x.reqLast && x.reqInfo==1'b1) blockReq <= True; 
    //if (x.reqInfo==pack(True) && mFlagF.notEmpty) begin 
    //  mFlagReg<=mFlagF.first; 
    //  mFlagF.deq; 
    //end
    reqF.deq;
    return x;
  endmethod

  method ActionValue#(WmiDh#(nd,ni,ne)) dh if (linkReady);
    let x = dhF.first; dhF.deq; return x;
  endmethod

  method ActionValue#(Bit#(nf)) popMFlag if (linkReady);
    let x = mFlagF.first; mFlagF.deq; return x;
  endmethod


  method Action   respd (Bit#(nd) rdata) if(linkReady); respF.enq( WmiResp { resp:DVA, data:rdata} ); endmethod
  method Action   drvSFlag(Bit#(nf) sf)  if(linkReady); sFlagReg<=sf; endmethod
  method Action   forceSThreadBusy  = forceSThreadBusy_pw.send;
  method Action   allowReq; blockReq<=False; endmethod
  //method Bit#(nf) peekMFlag  = mFlagReg;
  //method Bit#(8)  reqInfo    = truncate(mFlagReg>>24);  
  //method Bit#(24) mesgLength = truncate(mFlagReg);
  method Action   operate    = operateD._write(True);
  method WipDataPortStatus status = statusR;    

  interface Wmi_s slv;
    method Action putReq(WmiReq#(na,nb)   req) = wmiReq._write(req);
    method Action mFlag(Bit#(nf) mf)           = wmiMFlag._write(mf);
    method Action putDh (WmiDh#(nd,ni,ne) dh)  = wmiDh._write(dh);
    method WmiResp#(nd) getResp = respF.first;
    method sThreadBusy      = sThreadBusy_dw;
    method sDataThreadBusy  = sDataThreadBusy_dw;
    method sRespLast        = False; //TODO Implement Me
    method sFlag = sFlagReg;
    method sReset_n = !(isReset || !operateD);
    method Action mReset_n = peerIsReady._write(True);
  endinterface
endmodule

endpackage: OCWmi
