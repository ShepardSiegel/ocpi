// OCInf.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCInf;

import Config::*;
import OCWip::*;
import OCCP::*;
import OCDP::*;
import TimeService::*;
import TLPMF::*;
import UNoC::*;

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

`ifdef USE_NDW1
  `define DEFINE_NDW 1
`elsif USE_NDW2
  `define DEFINE_NDW 2
`elsif USE_NDW4
  `define DEFINE_NDW 4
`elsif USE_NDW8
  `define DEFINE_NDW 8
`endif

interface OCInfIfc#(numeric type nWci_ctop, numeric type ndw);
  interface Server#(PTW16,PTW16) server;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  interface Vector#(nWci_ctop,WciEM)                        wci_m;
  interface Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiDP0;  
  interface Wmi_Es#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiDP1;  
  method    GPS64_t   cpNow;
  interface GPSIfc    gps;
  method Action uuid (Bit#(512) arg);
endinterface

module mkOCInf_poly#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInfIfc#(Nwci_ctop,ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)),
    NumAlias#(ndw,`DEFINE_NDW) ); // by joe

  OCCPIfc#(Nwcit) cp   <- mkOCCP(pciDevice, sys0_clk, sys0_rst); // control plane
  UNoCIfc         noc  <- mkUNoC;                                // uNoC Netword-on-Chip

  // Intercept the highest-numbered WCI for infrastructure control and properties...
  Vector#(15,WciEM) vWci;
  vWci = cp.wci_Vm;
  // Pull out the resets so we can use them to reset infrastructure IPs...
  Vector#(15, Reset) rst = newVector;
  for (Integer i=0; i<15; i=i+1) rst[i] = vWci[i].mReset_n;

  //TODO: The PCIe Configuration needs to be adjusted so that device functions with non-zero function number will be completed to!

  // The producer/consumer and passive/active roles are set by dataplane configuration properties...
  //OCDPIfc#(ndw)  dp0  <- mkOCDP(insertFNum(pciDevice,0), reset_by rst[13]); // data-plane memory (fabric consumer in example app)
  //OCDPIfc#(ndw)  dp1  <- mkOCDP(insertFNum(pciDevice,1), reset_by rst[14]); // data-plane memory (fabric producer in example app)
`ifdef USE_NDW1
  OCDP4BIfc  dp0  <- mkOCDP4B(insertFNum(pciDevice,0),False,True, reset_by rst[13]); // data-plane memory (fabric consumer in example app)  PULL Only
  OCDP4BIfc  dp1  <- mkOCDP4B(insertFNum(pciDevice,1),True,False, reset_by rst[14]); // data-plane memory (fabric producer in example app)  PUSH Only
`elsif USE_NDW4
  OCDP16BIfc  dp0  <- mkOCDP16B(insertFNum(pciDevice,0),False,True, reset_by rst[13]); // data-plane memory (fabric consumer in example app)  PULL Only
  OCDP16BIfc  dp1  <- mkOCDP16B(insertFNum(pciDevice,1),True,False, reset_by rst[14]); // data-plane memory (fabric producer in example app)  PUSH Only
`endif

  // uNoC connections...
  mkConnection(noc.cp,  cp.server);   // uNoC to Control Plane
  mkConnection(noc.dp0, dp0.server);  // uNoC to Data Plane 0
  mkConnection(noc.dp1, dp1.server);  // uNoC to Data Plane 1

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

  // Collect the various data-plane WMI masters and provide a vector...
  //Vector#(2,WmiES4B) vWmi;
  //vWmi[0] = dp0.wmiS0;
  //vWmi[1] = dp1.wmiS0;

  interface Server server = noc.fab;
  method led      = cp.led;
  method switch   = cp.switch;
  method GPS64_t cpNow      = cp.cpNow;
  interface GPSIfc   gps    = cp.gps;
  interface Vector   wci_m  = take(vWci);
  interface          wmiDP0 = dp0.wmiS0;
  interface          wmiDP1 = dp1.wmiS0;
  method Action uuid (Bit#(512) arg) = cp.uuid(arg); // Pass the UUID from the infrastrucrture down to the control plane

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
