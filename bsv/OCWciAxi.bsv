// OCWciAxi.bsv - OpenCPI Worker Control Interface (WCI::AXI)
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWciAxi;

import OCWci::*;
import OCWipDefs::*;

import Bus::*;
import Clocks::*;
import ClientServer::*;
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
interface WciAxi_Eo;
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


instance Connectable#(WciAxi_m, WciAxi_s);
  module mkConnection#(WciAxi_m m, WciAxi_s s) (Empty);
    mkConnection(m.wrAddr, s.wrAddr);
    mkConnection(m.wrData, s.wrData);
    mkConnection(s.wrResp, m.wrResp);
    mkConnection(m.rdAddr, s.rdAddr);
    mkConnection(s.rdResp, m.rdResp);
  endmodule
endinstance





// This permutation trasforms WciAxi_m to WciAxi_Em...
module mkWciAxiMtoEm#(WciAxi_m arg) (WciAxi_Em);
  Wire#(Bit#(2))   resp_w           <- mkDWire(0);
  Wire#(Bit#(32))  respData_w       <- mkDWire(0);

  rule doAlways;
    WciAxiResp rsp = WciAxiResp { resp:unpack(resp_w), data:respData_w };
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

  method Bit#(1)  mAWVALID;
  method Action   sAWREADY;
  method Bit#(32) mAWADDR;
  method Bit#(3)  mAWPROT;

  method Bit#(1)  mWVALID;
  method Action   sWREADY;
  method Bit#(32) mWDATA;
  method Bit#(4)  mWSTRB;

  method Action   sBVALID;
  method Bit#(1)  mBREADY;
  method Action   sBRESP        ((* port="BRESP" *) Bit#(2)  arg_wresp);

  method Bit#(1)  mARVALID;
  method Action   sARREADY;
  method Bit#(32) mARADDR;
  method Bit#(3)  mARPROT;

  method Action   sRVALID;
  method Bit#(1)  mRREADY;
  method Action   sRDATA        ((* port="RDATA" *) Bit#(32) arg_rdata);
  method Action   sRRESP        ((* port="RRESP" *) Bit#(2)  arg_rresp);

  interface      mReset_n            = arg.mReset_n;

endmodule







// WciAxiMaster is a protocol adapter between abstract WIP::WCI an WCI::AXI...
interface WciAxiMasterIfc;
  interface WciInitiator  wci;  // The abstract transaction interface
  interface WciAxi_m      axi;  // The protocol specific interface
endinterface

module mkWciAxiMaster (WciAxiMasterIfc);
  FIFOF#(WciRequest)         reqF    <- mkSizedFIFOF(1);
  FIFOF#(WciResponse)        respF   <- mkSizedFIFOF(1);
  BusSender#(A4LAddrCmd)     awBS    <- mkBusSender(aAddrCmdDflt);
  BusSender#(A4LWrData)      wBS     <- mkBusSender(aWrDataDflt);
  BusReceiver#(A4LWrResp)    bBR     <- mkBusReceiver;
  BusSender#(A4LAddrCmd)     arBS    <- mkBusSender(aAddrCmdDflt);
  BusReceiver#(A4LRdResp)    rBR     <- mkBusReceiver;

  rule config_request (reqF.first matches tagged ConfigReq .confreq);
    if (confreq.req == Write) begin
      awBS.in.enq( A4LAddrCmd { prot:unpack(0),  addr:confreq.addr } );  // (AW) Write Address Channel
      wBS.in.enq ( A4LWrData  { strb:confreq.be, data:confreq.data } );  // (W)  Write Data Channel
    end else begin
      arBS.in.enq( A4LAddrCmd { prot:unpack(0), addr:confreq.addr  } );  // (AR) Read Address Channel
    end
    reqF.deq; 
  endrule

  rule wci_write_response;
    let wResp = bBR.out.first; bBR.out.deq;
    WciResponse wresp = RawResponse( WciRaw {resp:OK} );
    respF.enq(wresp);
  endrule

  rule wci_read_response;
    let rResp = rBR.out.first; rBR.out.deq;
    WciResponse rresp = ReadResponse( WciResp {resp:OK, data:rResp.data} );
    respF.enq(rresp);
  endrule

  interface WciInitiator  wci;
    interface Server wciInit   = Server {request:toPut(reqF), response:toGet(respF)};   
    method Bool      attention = False;  // True indicates worker/target attention
    method Bool      present   = True;   // True indicates worker/target present
  endinterface

  interface WciAxi_m  axi;
    interface BusSend wrAddr = awBS.out;
    interface BusSend wrData = wBS.out;
    interface BusRecv wrResp = bBR.in;
    interface BusRecv rdAddr = arBS.out;
    interface BusSend rdResp = rBR.in;
  endinterface

endmodule


// WciAxiSlave is a protocol adapter between WCI::AXI and abstract WCI...
interface WciAxiSlaveIfc;
  interface WciAxi_s      axi;  // The protocol specific interface
  interface WciTarget     wci;  // The abstract transaction interface
endinterface

module mkWciAxiSlave (WciAxiSlaveIfc);
  FIFOF#(WciRequest)         reqF    <- mkSizedFIFOF(1);
  FIFOF#(WciResponse)        respF   <- mkSizedFIFOF(1);
  BusReceiver#(A4LAddrCmd)   awBR    <- mkBusReceiver;
  BusReceiver#(A4LWrData)    wBR     <- mkBusReceiver;
  BusSender#(A4LWrResp)      wBS     <- mkBusSender(aWrRespDflt);
  BusReceiver#(A4LAddrCmd)   bBR     <- mkBusReceiver;
  BusSender#(A4LRdResp)      rBS     <- mkBusSender(aRdRespDflt);


  rule wci_write_request;
    let wAddr = awBR.out.first; awBR.out.deq;
    let wData =  wBR.out.first;  wBR.out.deq;
    reqF.enq(wciConfigWrite(wAddr.addr, wData.data, wData.strb));
  endrule

  rule wci_read_request;
    let rAddr = bBR.out.first; bBR.out.deq;
    reqF.enq(wciConfigRead(rAddr.addr));
  endrule

  rule config_write_response (respF.first matches tagged RawResponse .resp);
    wBS.in.enq( A4LWrResp { resp:OKAY } );  // (B) Write Response Channel
    respF.deq; 
  endrule

  rule config_read_response (respF.first matches tagged ReadResponse .resp);
    rBS.in.enq( A4LRdResp { resp:OKAY, data:resp.data } );  // (R) Read Response Channel
    respF.deq; 
  endrule

  interface WciAxi_s  axi;
    interface BusRecv wrAddr = awBR.in;
    interface BusRecv wrData = wBR.in;
    interface BusSend wrResp = wBS.out;
    interface BusRecv rdAddr = bBR.in;
    interface BusSend rdResp = rBS.out;
  endinterface

  interface WciTarget  wci;
    interface Client wciTarg   = Client {request:toGet(reqF), response:toPut(respF)};   
    method Action    attention = noAction;
    method Action    present   = noAction;
  endinterface
endmodule


endpackage: OCWciAxi
