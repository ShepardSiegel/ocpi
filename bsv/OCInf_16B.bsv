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
// Using types, not numeric types, so this is not directly Polymorphic as in OCApp

interface OCInfIfc#(type iNwci_ctop, type iNwmi);
  interface Server#(PTW16,PTW16) server;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  interface Vector#(iNwci_ctop,Wci_m#(20))  wci_m;
  interface Vector#(iNwmi,WmiS16B)          wmi_s;
  method    GPS64_t   cpNow;
  interface GPSIfc    gps;
endinterface

(*synthesize*)
module mkOCInf#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCInfIfc#(Nwci_ctop,Nwmi));

  OCCPIfc#(Nwcit) cp   <- mkOCCP(pciDevice, sys0_clk, sys0_rst);                 // control plane
  TLPSMIfc        sm0  <- mkTLPSM(tagged Bar 0);      // server merge, fork away Bar 0
  TLPSMIfc        sm1  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:0,func:0}); // server merge, fork Bar1 bot32K
  TLPSMIfc        sm2  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:1,func:1}); // server merge, fork Bar1 top32K
  Reg#(UInt#(8))  chompCnt <- mkReg(0);               // fall-through chomp count

  // Intercept the highest-numbered WCI for infrastructure control and properties...
  Vector#(15,Wci_m#(20)) vWci;
  vWci = cp.wci_m;
  // Pull out the resets so we can use them to reset infrastructure IPs...
  Vector#(15, Reset) rst = newVector;
  for (Integer i=0; i<15; i=i+1) rst[i] = vWci[i].mReset_n;

  // The producer/consumer and passive/active roles are set by dataplane configuration properties...
  OCDPIfc         dp0  <- mkOCDP(pciDevice,reset_by rst[13]); // data-plane memory (fabric consumer in example app)
  OCDPIfc         dp1  <- mkOCDP(pciDevice,reset_by rst[14]); // data-plane memory (fabric producer in example app)

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
  Vector#(2,WmiS16B) vWmi;
  vWmi[0] = dp0.wmi_s;
  vWmi[1] = dp1.wmi_s;

  interface Server server = sm0.s;
  method led      = cp.led;
  method switch   = cp.switch;
  method GPS64_t cpNow      = cp.cpNow;
  interface GPSIfc  gps     = cp.gps;
  interface Vector  wci_m   = take(vWci);
  interface Vector  wmi_s   = vWmi;

endmodule : mkOCInf

endpackage: OCInf
