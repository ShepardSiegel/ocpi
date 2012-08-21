// OCEDP.bsv
// Copyright (c) 2009,2010,2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Module Argument or Provided Interface
// In the current implementation the Vectors of BRAMServers bramsA and bramsB are passed as
// arguments to the edp and wmi respectively. This allows the subordinate modules to use the 
// BRAMServer directly, just as if the BRAMs were local. It may be desirable instead to pass
// these down as subinterfaces of the edp and wmi module interfaces. 

package OCEDP;

import GMAC         ::*;
import TLPMF        ::*;
import OCWip        ::*;
import OCBufQ       ::*;
import TimeService  ::*;
import EDPServBC    ::*;
import WmiServBC    ::*;

import BRAM         ::*;
import DReg         ::*;
import ClientServer ::*; 
import Connectable  ::*;
import DefaultValue ::*;
import GetPut       ::*;
import PCIE         ::*;
import Vector       ::*;

interface OCEDPIfc#(numeric type ndw);
  interface WciES                wciS0;    // Control and Configuration
  interface Wti_s#(64)           wtiS0;    // Worker Time Interface (for timestamping)
  interface Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiS0; // facing the application  (local)
  interface Server#(ABS,ABS)     server;   // facing the infrastructure (remote)
endinterface

module mkOCEDP#(PciId pciDevice, parameter Bool hasPush, parameter Bool hasPull, parameter Bool hasDebugLogic) (OCEDPIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = valueOf(DPBufSizeInHWords); 
    cfg.latency    = 1;
  Vector#(4, BRAM2Port# (DPBufHWAddr, DWord)) bram <- replicateM(mkBRAM2Server(cfg));
  function   BRAMServer#(DPBufHWAddr, DWord)  getPortA (Integer i) = bram[i].portA;
  function   BRAMServer#(DPBufHWAddr, DWord)  getPortB (Integer i) = bram[i].portB;
  Vector#(4, BRAMServer#(DPBufHWAddr, DWord)) bramsA = genWith(getPortA);
  Vector#(4, BRAMServer#(DPBufHWAddr, DWord)) bramsB = genWith(getPortB);

  WciSlaveIfc#(32)    wci  <- mkWciSlave;
  WtiSlaveIfc#(64)    wti  <- mkWtiSlave;
  EDPServBCIfc        edp  <- mkEDPServBC(bramsA,pciDevice,wci,hasPush,hasPull); // The EDP to Memory adaptation
  WmiServBCIfc#(ndw)  wmi  <- mkWmiServBC(bramsB);                               // The ndw-Byte WMI to Memory adaptation
  FabPCIfc            bml  <- mkFabPC(wci);                                      // Buffer Management Logic

  mkConnection(bml.lcl,  wmi.bufq);       // Buffer Managment signals with local  WMI
  mkConnection(bml.remo, edp.bufq);       // Buffer Managment signals with remote EDP

  Reg#(DPControl)  dpControl <- mkReg(defaultDPControl);
  Reg#(Bit#(64))   dmaStartTime     <- mkReg(0);
  Reg#(Bit#(64))   dmaDoneTime      <- mkReg(0);

  rule capture_startTime (edp.dmaStartPulse); dmaStartTime <= wti.now; endrule
  rule capture_doneTime  (edp.dmaDonePulse);  dmaDoneTime  <= wti.now; endrule

// WCI Connection to dataplane control and configuration...
(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd" *)

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
     case (wciReq.addr[7:0]) matches
       'h00 : bml.i_lclNumBufs    <= truncate(unpack(wciReq.data));
       'h04 : bml.i_fabNumBufs    <= truncate(unpack(wciReq.data));
       'h08 : bml.i_mesgBase      <= truncate(unpack(wciReq.data));
       'h0C : bml.i_metaBase      <= truncate(unpack(wciReq.data));
       'h10 : bml.i_mesgSize      <= truncate(unpack(wciReq.data));
       'h14 : bml.i_metaSize      <= truncate(unpack(wciReq.data));
       'h18 : begin bml.remo.fabric;  $display("[%0d] %m: fabDoneAvail Event",$time); end
       'h50 : bml.i_fabMesgBase   <= truncate(unpack(wciReq.data));
       'h54 : bml.i_fabMetaBase   <= truncate(unpack(wciReq.data));
       'h58 : bml.i_fabMesgSize   <= truncate(unpack(wciReq.data));
       'h5C : bml.i_fabMetaSize   <= truncate(unpack(wciReq.data));
       'h60 : bml.i_fabFlowBase   <= truncate(unpack(wciReq.data));
       'h64 : bml.i_fabFlowSize   <= truncate(unpack(wciReq.data));
       'h68 : dpControl           <= unpack(truncate(wciReq.data));
       'h94 : bml.i_fabMesgBaseMS <= truncate(unpack(wciReq.data));
       'h98 : bml.i_fabMetaBaseMS <= truncate(unpack(wciReq.data));
       'h9C : bml.i_fabFlowBaseMS <= truncate(unpack(wciReq.data));
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
  Vector#(4,Bit#(32)) v = wmi.stat;
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = extend(pack(bml.i_lclNumBufs));
       'h04 : rdat = extend(pack(bml.i_fabNumBufs));
       'h08 : rdat = extend(pack(bml.i_mesgBase));
       'h0C : rdat = extend(pack(bml.i_metaBase));
       'h10 : rdat = extend(pack(bml.i_mesgSize));
       'h14 : rdat = extend(pack(bml.i_metaSize));
       'h20 : rdat = pack(extend(bml.bs.lbcf));
       'h24 : rdat = 32'hF00D_FACE;  // required by OpenCPI testRpl software as of 2011-12-13
       'h28 : rdat = !hasDebugLogic ? 0 : pack({bml.bs.lbar,      bml.bs.rba});
       'h2C : rdat = !hasDebugLogic ? 0 : pack({bml.bs.remIndex,  bml.bs.lclIndex});
       'h30 : rdat = !hasDebugLogic ? 0 : pack({bml.bs.lclStarts, bml.bs.lclDones});
       'h34 : rdat = !hasDebugLogic ? 0 : pack({bml.bs.remStarts, bml.bs.remDones});
       'h38 : rdat = !hasDebugLogic ? 0 : pack(v[3]);  // thisMesg
       'h3C : rdat = !hasDebugLogic ? 0 : pack(v[2]);  // lastMesg
       'h40 : rdat = !hasDebugLogic ? 0 : pack(v[1]);  // req/wrt Count
       'h44 : rdat = !hasDebugLogic ? 0 : pack(v[0]);  // wrtData
       'h48 : rdat = !hasDebugLogic ? 0 : 32'hDADE_BABE;
       'h4C : rdat = 32'h0000_8000;  // 2^15 32KB TODO: This location returns the bufferExtent (memory size)
       'h50 : rdat = extend(pack(bml.i_fabMesgBase));
       'h54 : rdat = extend(pack(bml.i_fabMetaBase));
       'h58 : rdat = extend(pack(bml.i_fabMesgSize));
       'h5C : rdat = extend(pack(bml.i_fabMetaSize));
       'h60 : rdat = extend(pack(bml.i_fabFlowBase));
       'h64 : rdat = extend(pack(bml.i_fabFlowSize));
       'h68 : rdat = extend(pack(dpControl));
       'h6C : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_flowDiagCount));
       'h70 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_debug));
       'h80 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_meta[0]));
       'h84 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_meta[1]));
       'h88 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_meta[2]));
       'h8C : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_meta[3]));
       'h90 : rdat = !hasDebugLogic ? 0 : 32'hC0DE_0111; // for OPED pcore 1_11
       'h94 : rdat = extend(pack(bml.i_fabMesgBaseMS)); 
       'h98 : rdat = extend(pack(bml.i_fabMetaBaseMS));
       'h9C : rdat = extend(pack(bml.i_fabFlowBaseMS));
       'hA0 : rdat = !hasDebugLogic ? 0 : dmaStartTime[31:00];
       'hA4 : rdat = !hasDebugLogic ? 0 : dmaStartTime[63:32];
       'hA8 : rdat = !hasDebugLogic ? 0 : dmaDoneTime[31:00];
       'hAC : rdat = !hasDebugLogic ? 0 : dmaDoneTime[63:32];
       'hB0 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_dbgBytesTxEnq));
       'hB4 : rdat = !hasDebugLogic ? 0 : extend(pack(edp.i_dbgBytesTxDeq));
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
       $time, wciReq.addr, wciReq.byteEn, rdat);
     wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  endrule

  rule assignControl;
    bml.dpCtrl(dpControl);
    edp.dpCtrl(dpControl);
    wmi.dpCtrl(dpControl);
  endrule

  rule operating_actions (wci.isOperating); wmi.operate(); endrule

  mkConnection(wti.now, wmi.now); // Pass the WTI Time data down to the WmiServBC
  mkConnection(wti.now, edp.now); // Pass the WTI Time data down to the EDPServBC

  WciES                                          wci_Es <- mkWciStoES(wci.slv);
  Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32) wmi_Es <- mkWmiStoES(wmi.wmi_s);

  // Control Op logic pushed down into OCBufQ
  interface wciS0  = wci_Es;      // Provide the WCI interface
  interface wtiS0  = wti.slv;     // Provide the WTI interface 
  interface wmiS0  = wmi_Es;      // Provide the WMI interface
  interface server = edp.server;  // Provide the EDP interface

endmodule


// Synthesizeable, non-polymorphic modules that use the poly module above...

`ifdef USE_NDW1
typedef OCEDPIfc#(1) OCEDP4BIfc;
(* synthesize *)
module mkOCEDP4B#(PciId pciDevice, parameter Bool hasPush, parameter Bool hasPull, parameter Bool hasDebugLogic) (OCEDP4BIfc);
  OCEDP4BIfc _a <- mkOCEDP(pciDevice,hasPush,hasPull,hasDebugLogic); return _a;
endmodule

`elsif USE_NDW2
typedef OCEDPIfc#(2) OCEDP8BIfc;
(* synthesize *)
module mkOCEDP8B#(PciId pciDevice, parameter Bool hasPush, parameter Bool hasPull, parameter Bool hasDebugLogic) (OCEDP8BIfc);
  OCEDP8BIfc _a <- mkOCEDP(pciDevice,hasPush,hasPull,hasDebugLogic); return _a;
endmodule

`elsif USE_NDW4
typedef OCEDPIfc#(4) OCEDP16BIfc;
(* synthesize *)
module mkOCEDP16B#(PciId pciDevice, parameter Bool hasPush, parameter Bool hasPull, parameter Bool hasDebugLogic) (OCEDP16BIfc);
  OCEDP16BIfc _a <- mkOCEDP(pciDevice,hasPush,hasPull,hasDebugLogic); return _a;
endmodule

`elsif USE_NDW8
typedef OCEDPIfc#(8) OCEDP32BIfc;
(* synthesize *)
module mkOCEDP32B#(PciId pciDevice, parameter Bool hasPush, parameter Bool hasPull, parameter Bool hasDebugLogic) (OCEDP32BIfc);
  OCEDP32BIfc _a <- mkOCEDP(pciDevice,hasPush,hasPull,hasDebugLogic); return _a;
endmodule
`endif

endpackage: OCEDP
