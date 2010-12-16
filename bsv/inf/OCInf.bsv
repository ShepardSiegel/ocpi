// OCInf.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCInf;

import OCWip::*;
import OCCP::*;
import OCDP::*;
import TimeService::*;
import TLPMF::*;
import Config::*;

import PCIE::*;
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;

// nWci - number of Wci Worker Control Links
// nWmi - number of WMI Interfaces
// ndw    - number of 4B DWORDs in WSI and WMI datapaths
// Using types, not numeric types, so this is not directly Polymorphic as in OCApp

interface OCInfIfc#(numeric type nWci_ctop, numeric type ndw);
  interface Server#(PTW16,PTW16) server;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  interface Vector#(nWci_ctop,WciOcp_Em#(20))               wci_m;
  interface Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiS0;  
  interface Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiS1;  
  method    GPS64_t   cpNow;
  interface GPSIfc    gps;
endinterface

module mkOCInf_poly#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInfIfc#(Nwci_ctop,ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)),
    NumAlias#(ndw,1) ); // by joe

  OCCPIfc#(Nwcit) cp   <- mkOCCP(pciDevice, sys0_clk, sys0_rst);                 // control plane
  TLPSMIfc        sm0  <- mkTLPSM(tagged Bar 0);      // server merge, fork away Bar 0
  TLPSMIfc        sm1  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:0,func:0}); // server merge, fork Bar1 bot32K, function 0 (works by default)
  TLPSMIfc        sm2  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:1,func:1}); // server merge, fork Bar1 top32K, function 1 (see TODO below)
  Reg#(UInt#(8))  chompCnt <- mkReg(0);               // fall-through chomp count

  // Intercept the highest-numbered WCI for infrastructure control and properties...
  Vector#(15,WciOcp_Em#(20)) vWci;
  vWci = cp.wci_Vm;
  // Pull out the resets so we can use them to reset infrastructure IPs...
  Vector#(15, Reset) rst = newVector;
  for (Integer i=0; i<15; i=i+1) rst[i] = vWci[i].mReset_n;

  //TODO: The PCIe Configuration needs to be adjusted so that device functions with non-zero function number will be completed to!

  // The producer/consumer and passive/active roles are set by dataplane configuration properties...
  //OCDPIfc#(ndw)  dp0  <- mkOCDP(insertFNum(pciDevice,0), reset_by rst[13]); // data-plane memory (fabric consumer in example app)
  //OCDPIfc#(ndw)  dp1  <- mkOCDP(insertFNum(pciDevice,1), reset_by rst[14]); // data-plane memory (fabric producer in example app)
`define USE_NDW1
`ifdef USE_NDW1
  OCDP4BIfc  dp0  <- mkOCDP(insertFNum(pciDevice,0),False,True, reset_by rst[13]); // data-plane memory (fabric consumer in example app)  PULL Only
  OCDP4BIfc  dp1  <- mkOCDP(insertFNum(pciDevice,1),True,False, reset_by rst[14]); // data-plane memory (fabric producer in example app)  PUSH Only
`endif

  // Infrastruture WCI slaves...
  mkConnection(vWci[13], dp0.wci_s);
  mkConnection(vWci[14], dp1.wci_s);

  // Make an infrastructure time client for each DP...
  Clock inf_clk <- exposeCurrentClock;
  Reset inf_rst <- exposeCurrentReset;
  TimeClientIfc  itc0  <- mkTimeClient(sys0_clk, sys0_rst, inf_clk,  inf_rst);
  TimeClientIfc  itc1  <- mkTimeClient(sys0_clk, sys0_rst, inf_clk,  inf_rst);
  mkConnection(cp.cpNow, itc0.gpsTime);  // DP0 Infrastructure Server/Client Connection
  mkConnection(cp.cpNow, itc1.gpsTime);  // DP1 Infrastructure Server/Client Connection
  mkConnection(itc0.wti_m, dp0.wti_s);   // DP0 Time Client WTI-M -> WTI-S 
  mkConnection(itc1.wti_m, dp1.wti_s);   // DP1 Time Client WTI-M -> WTI-S 

  // Infrastruture NoC...
  mkConnection(sm0.c0,    cp.server);    // sm0 cp attach
  mkConnection(sm0.c1,    sm1.s);        // sm0 sm1 link
  mkConnection(sm1.c0,    dp0.server);   // sm1 dp0 attach
  mkConnection(sm1.c1,    sm2.s);        // sm1 sm2 link
  mkConnection(sm2.c0,    dp1.server);   // sm1 dp0 attach

  rule chomp_rogue;
    PTW16 x <- sm2.c1.request.get;
    if (chompCnt < maxBound) chompCnt <= chompCnt + 1;
    $display("[%0d]: %m: UNHANDLED TLP chompCnt:%0x", $time, chompCnt);
  endrule

  // Collect the various data-plane WMI masters and provide a vector...
  //Vector#(2,WmiES4B) vWmi;
  //vWmi[0] = dp0.wmiS1;
  //vWmi[1] = dp1.wmiS1;

  interface Server server = sm0.s;
  method led      = cp.led;
  method switch   = cp.switch;
  method GPS64_t cpNow      = cp.cpNow;
  interface GPSIfc   gps    = cp.gps;
  interface Vector   wci_m  = take(vWci);
  interface          wmiS0  = dp0.wmiS1;
  interface          wmiS1  = dp1.wmiS1;

endmodule : mkOCInf_poly

// Synthesizeable, non-polymorphic modules that use the poly module above...

`ifdef USE_NDW1
typedef OCInfIfc#(Nwci_ctop,1) OCInf4BIfc;
(* synthesize *)
module mkOCInf4B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInf4BIfc);
  OCInf4BIfc _a <- mkOCInf_poly(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule
`elsif USE_NDW2
typedef OCInfIfc#(Nwci_ctop,2) OCInf8BIfc;
(* synthesize *)
module mkOCInf8B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInf8BIfc);
  OCInf8BIfc _a <- mkOCInf_poly(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule
`elsif USE_NDW4
typedef OCInfIfc#(Nwci_ctop,4) OCInf16BIfc;
(* synthesize *)
module mkOCInf16B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInf16BIfc);
  OCInf16BIfc _a <- mkOCInf_poly(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule
`elsif USE_NDW8
typedef OCInfIfc#(Nwci_ctop,8) OCInf32BIfc;
(* synthesize *)
module mkOCInf32B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInf32BIfc);
  OCInf32BIfc _a <- mkOCInf_poly(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule
`endif


endpackage: OCInf
