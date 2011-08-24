// CTop.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package CTop;

import OCInf::*;
import OCApp::*;
import TLPMF::*;
import TimeService::*;
import OCWip::*;
import Config::*;

import Clocks::*;
import PCIE::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;


// ndw - number of 4B DWORDS...

interface CTopIfc#(numeric type ndw);
  interface Server#(PTW16,PTW16) server;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  interface Vector#(Nwci_ftop, WciEM)                   wci_m;  // provide WCI interfaces to Ftop
  interface  GPS64_t     cpNow;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsi_s_adc;   
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsi_m_dac;  
  interface  WmemiEM16B  wmemiM0;
  interface  GPSIfc      gps;
endinterface 

module mkCTop#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTopIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)), // by shep
    Add#(1, a__, TAdd#(3, TAdd#(1, TAdd#(1, TAdd#(12, TAdd#(TMul#(ndw, 32), TAdd#(TMul#(ndw, 4), 8))))))));                       ///by bsc output

  Bool hasDebugLogic = True;

  //OCInfIfc#(Nwci_ctop,ndw) inf <- mkOCInf_poly(pciDevice, sys0_clk, sys0_rst);       // Instance the Infrastructre
`ifdef USE_NDW1
  OCInf4BIfc inf <- mkOCInf4B(pciDevice, sys0_clk, sys0_rst);       // Instance the Infrastructre
`elsif USE_NDW4
  OCInf16BIfc inf <- mkOCInf16B(pciDevice, sys0_clk, sys0_rst);       // Instance the Infrastructre
`endif

  Vector#(iNwci_ctop, Reset) resetVec = newVector;                                   // Vector of WCI Resets
  for (Integer i=0; i<iNwci_app; i=i+1) resetVec[i] = inf.wci_m[i].mReset_n;         // Reset Vector for the Application

  //OCAppIfc#(Nwci_app,Nwmi,Nwmemi,ndw) app  <- mkOCApp_poly(resetVec,hasDebugLogic);  // Instance the Application
`ifdef USE_NDW1
  OCApp4BIfc  app  <- mkOCApp4B(resetVec,hasDebugLogic);  // Instance the Application
`elsif USE_NDW4
  OCApp16BIfc app  <- mkOCApp16B(resetVec,hasDebugLogic);  // Instance the Application
`endif

  for (Integer i=0; i<iNwci_app; i=i+1) mkConnection(inf.wci_m[i], app.wci_s[i]);   // Connect WCI between INF/APP
  Vector#(Nwci_ftop, WciEM) wci_c2f = takeAt(iNwci_app, inf.wci_m);                 // Take the unused WCI for FTop

  // WMI interfaces between App(masters) to Inf(Slaves)...
  mkConnection(app.wmiM0, inf.wmiDP0);
  mkConnection(app.wmiM1, inf.wmiDP1);

  rule connect_uuid;
    inf.uuid(app.uuid);
  endrule // Pass the uuid from the application to the infrastructure

  interface Server server     = inf.server;  // Pass the sever interface provided by OCInf straight through
  method led                  = inf.led;
  method switch               = inf.switch;
  interface GPS64_t cpNow     = inf.cpNow;
  interface GPSIfc  gps       = inf.gps;
  interface Vector  wci_m     = wci_c2f;
  //interface Wsi_s wsi_s_adc   = app.wsi_s_adc; // The ADC device-worker to the application  // FIXME Poly Width
  //interface Wsi_m wsi_m_dac   = app.wsi_m_dac; // The DAC device-worker to the application  // FIXME Poly Width
  interface WmemiEM16B wmemiM0 = app.wmemiM0;
endmodule : mkCTop

// Synthesizeable, non-polymorphic modules that use the poly module above...

`ifdef USE_NDW1
typedef CTopIfc#(1) CTop4BIfc;
(* synthesize *)
module mkCTop4B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTop4BIfc);
  CTop4BIfc _a <- mkCTop(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule

`elsif USE_NDW2
typedef CTopIfc#(2) CTop8BIfc;
(* synthesize *)
module mkCTop8B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTop8BIfc);
  CTop8BIfc _a <- mkCTop(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule

`elsif USE_NDW4
typedef CTopIfc#(4) CTop16BIfc;
(* synthesize *)
module mkCTop16B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTop16BIfc);
  CTop16BIfc _a <- mkCTop(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule

`elsif USE_NDW8
typedef CTopIfc#(8) CTop32BIfc;
(* synthesize *)
module mkCTop32B#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTop32BIfc);
  CTop32BIfc _a <- mkCTop(pciDevice, sys0_clk, sys0_rst); return _a;
endmodule
`endif


endpackage: CTop
