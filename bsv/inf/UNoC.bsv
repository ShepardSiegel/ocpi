// UNoC.bsv - The "micro-NoC" Network-on-Chip
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

//TODO
//1. Generalize so that there are simply a Vector of Clients, as many as needed
//2. Pass in a vector of Merge functions
//3. Fix issue where completions advance to correct data plane (e.g. so DP1 can Pull, affects TLPServBC)

package UNoC;

import TLPMF::*;

import GetPut::*;
import ClientServer::*;
import Connectable::*;

interface UNoCIfc;
  interface Server#(PTW16,PTW16) fab;  // Fabric (e.g. PCIe)
  interface Client#(PTW16,PTW16) cp;   // Control Plane
  interface Client#(PTW16,PTW16) dp0;  // Data Plane 0
  interface Client#(PTW16,PTW16) dp1;  // Data Plane 1
  method UInt#(8) chomp;  // Saturating count of untaken message cycles
endinterface

module mkUNoC (UNoCIfc);

  TLPSMIfc        sm0  <- mkTLPSM(tagged Bar 0);      // server merge, fork away Bar 0 to Control Plane
  TLPSMIfc        sm1  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:0,func:0}); // server merge, fork Bar1 bot32K, function 0 (works by default)
  TLPSMIfc        sm2  <- mkTLPSM(tagged Bar64 BarSub64{bar:1,top32K:1,func:1}); // server merge, fork Bar1 top32K, function 1 (issue 3 above)
  Reg#(UInt#(8))  chompCnt <- mkReg(0);               // fall-through chomp count

  // Infrastruture NoC...
  mkConnection(sm0.c1,    sm1.s);  // sm0 sm1 link
  mkConnection(sm1.c1,    sm2.s);  // sm1 sm2 link

  (* fire_when_enabled *) rule chomp_rogue;  // This rule digests inbound messages that are not split to any uNoC attached resource...
    PTW16 x <- sm2.c1.request.get;
    if (chompCnt < maxBound) chompCnt <= chompCnt + 1;
    $display("[%0d]: %m: UNHANDLED TLP chompCnt:%0x", $time, chompCnt);
  endrule

  interface Server fab = sm0.s;      // sm0 fab attach
  interface Client cp  = sm0.c0;     // sm0 cp  attach
  interface Client dp0 = sm1.c0;     // sm1 dp0 attach
  interface Client dp1 = sm2.c0;     // sm1 dp0 attach
  method UInt#(8) chomp = chompCnt;  // Saturating count of untaken, "chomped", message cycles

endmodule : mkUNoC

endpackage: UNoC
