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
  (* prefix="", enable="AWREADY" *)        method Bit#(1)  sAWREADY;
  (* prefix="", result="AWADDR"  *)        method Bit#(32) mAWADDR;
  (* prefix="", result="AWPROT"  *)        method Bit#(3)  mAWPROT;

  (* prefix="", result="WVALID"  *)        method Bit#(1)  mWVALID;      // (W) Write Data Channel...
  (* prefix="", enable="WREADY"  *)        method Bit#(1)  sWREADY;
  (* prefix="", result="WDATA"   *)        method Bit#(32) mWDATA;
  (* prefix="", result="WSTRB"   *)        method Bit#(4)  mWSTRB;

  (* prefix="", enable="BVALID"  *)        method Bit#(1)  sBVALID;      // (B) Write Response Channel...
  (* prefix="", result="BREADY"  *)        method Bit#(1)  mBREADY;
  (* prefix="", always_enabled   *)        method Action   sBRESP        ((* port="BRESP" *) Bit#(2)  arg_wresp);

  (* prefix="", result="ARVALID" *)        method Bit#(1)  mARVALID;     // (AR) Read Address Channel...
  (* prefix="", enable="ARREADY" *)        method Bit#(1)  sARREADY;
  (* prefix="", result="ARADDR"  *)        method Bit#(32) mARADDR;
  (* prefix="", result="ARPROT"  *)        method Bit#(3)  mARPROT;

  (* prefix="", enable="RVALID"  *)        method Bit#(1)  sRVALID;      // (R) Read Response Channel...
  (* prefix="", result="RREADY"  *)        method Bit#(1)  mRREADY;
  (* prefix="", always_enabled   *)        method Action   sRDATA        ((* port="RDATA" *) Bit#(32) arg_rdata);
  (* prefix="", always_enabled   *)        method Action   sRRESP        ((* port="RRESP" *) Bit#(2)  arg_rresp);

  interface Reset mReset_n;
endinterface

(* always_ready *)
interface WciAxi_Es;
  (* prefix="", enable="AWVALID" *)        method Bit#(1)  mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", result="AWREADY" *)        method Bit#(1)  sAWREADY;
  (* prefix="", always_enabled   *)        method Action   mAWADDR       ((* port="AWADDR" *) Bit#(32) arg_waddr);
  (* prefix="", always_enabled   *)        method Action   mAWPROT       ((* port="AWPROT" *) Bit#(3)  arg_wprot);

  (* prefix="", enable="WVALID"  *)        method Bit#(1)  mWVALID;      // (W) Write Data Channel...
  (* prefix="", result="WREADY"  *)        method Bit#(1)  sWREADY;
  (* prefix="", always_enabled   *)        method Action   mWDATA        ((* port="WDATA" *) Bit#(32) arg_wdata);
  (* prefix="", always_enabled   *)        method Action   mWSTRB        ((* port="WSTRB" *) Bit#(4)  arg_wstrb);

  (* prefix="", result="BVALID"  *)        method Bit#(1)  sBVALID;      // (B) Write Response Channel...
  (* prefix="", enable="BREADY"  *)        method Bit#(1)  mBREADY;
  (* prefix="", result="BRESP"   *)        method Bit#(2)  sBRESP;

  (* prefix="", enable="ARVALID" *)        method Bit#(1)  mARVALID;     // (AR) Read Address Channel...
  (* prefix="", result="ARREADY" *)        method Bit#(1)  sARREADY;
  (* prefix="", always_enabled   *)        method Action   mARADDR       ((* port="ARADDR" *) Bit#(32) arg_raddr);
  (* prefix="", always_enabled   *)        method Action   mARPROT       ((* port="ARPROT" *) Bit#(3)  arg_rprot);

  (* prefix="", result="RVALID"  *)        method Bit#(1)  sRVALID;      // (R) Read Response Channel...
  (* prefix="", enable="RREADY"  *)        method Bit#(1)  mRREADY;
  (* prefix="", result="RDATA"   *)        method Bit#(32) sRDATA;
  (* prefix="", result="RRESP"   *)        method Bit#(2)  sRRESP;
endinterface


(* always_ready *)
interface WciAxi_Eo;
  (* prefix="", enable="AWVALID" *)        method Bit#(1)  mAWVALID;     // (AW) Write Address Channel...
  (* prefix="", enable="AWREADY" *)        method Bit#(1)  sAWREADY;
  (* prefix="", always_enabled   *)        method Action   mAWADDR       ((* port="AWADDR" *) Bit#(32) arg_waddr);
  (* prefix="", always_enabled   *)        method Action   mAWPROT       ((* port="AWPROT" *) Bit#(3)  arg_wprot);

  (* prefix="", enable="WVALID"  *)        method Bit#(1)  mWVALID;      // (W) Write Data Channel...
  (* prefix="", enable="WREADY"  *)        method Bit#(1)  sWREADY;
  (* prefix="", always_enabled   *)        method Action   mWDATA        ((* port="WDATA" *) Bit#(32) arg_wdata);
  (* prefix="", always_enabled   *)        method Action   mWSTRB        ((* port="WSTRB" *) Bit#(4)  arg_wstrb);

  (* prefix="", enable="BVALID"  *)        method Bit#(1)  sBVALID;      // (B) Write Response Channel...
  (* prefix="", enable="BREADY"  *)        method Bit#(1)  mBREADY;
  (* prefix="", always_enabled   *)        method Action   sBRESP        ((* port="BRESP" *) Bit#(2)  arg_wresp);

  (* prefix="", enable="ARVALID" *)        method Bit#(1)  mARVALID;     // (AR) Read Address Channel...
  (* prefix="", enable="ARREADY" *)        method Bit#(1)  sARREADY;
  (* prefix="", always_enabled   *)        method Action   mARADDR       ((* port="ARADDR" *) Bit#(32) arg_raddr);
  (* prefix="", always_enabled   *)        method Action   mARPROT       ((* port="ARPROT" *) Bit#(3)  arg_rprot);

  (* prefix="", result="RVALID"  *)        method Bit#(1)  sRVALID;      // (R) Read Response Channel...
  (* prefix="", enable="RREADY"  *)        method Bit#(1)  mRREADY;
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


// Initiatior, Target, and Monitor/Observer...

interface WciAxiInitiatorIfc;
  interface WciAxi_Em wciM0;
endinterface

/*
(* synthesize, default_clock_osc="wciM0_Clk", default_reset="wciM0_MReset_n" *)
module mkWciAxiInitiator (WciAxiInitiatorIfc);
  WciAxiMasterIfc initiator <-mkWciAxiMaster;
  // Add initiator behavior here...
  //WciAxi_Em wci_Em <- mkWciAxiMtoEm(initiator.mas);
  interface WciAxi_Em wciM0;
  endinterface
endmodule
*/


interface WciAxiTargetIfc;
  interface WciAxi_Es wciS0;
endinterface

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWciAxiTarget (WciAxiTargetIfc);
  WciAxiSlaveIfc target <-mkWciAxiSlave;
  // Add target behavior here...
  //WciAxi_Es wci_Es <- mkWciAxiStoES(target.slv);
  interface WciAxi_Es wciS0;
  endinterface
endmodule

interface WciAxiMonitorIfc;
  interface WciAxi_Eo wciO0;
endinterface

(* synthesize, default_clock_osc="wciO0_Clk", default_reset="wciO0_MReset_n" *)
module mkWciAxiMonitor (WciAxiMonitorIfc);
  // Add monitor/observer behavior here...
  interface WciAxi_Eo wciO0;
  endinterface
endmodule


endpackage: OCWciAxi
