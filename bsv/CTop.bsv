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


// ndb - number of data Bytes in dataplane...

interface CTopIfc;
//interface CTopIfc#(numeric type ndb);
  interface Server#(PTW16,PTW16) server;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  interface Vector#(Nwci_ftop, Wci_Em#(20)) wci_m;  // provide WCI interfaces to Ftop
  interface  GPS64_t     cpNow;
  interface  WsiES4B     wsi_s_adc;
  interface  WsiEM4B     wsi_m_dac;
  interface  WmemiEM16B  wmemiM;
  interface  GPSIfc      gps;
endinterface 

(* synthesize *)
module mkCTop#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTopIfc);

  OCInfIfc#(Nwci_ctop) inf  <- mkOCInf(pciDevice, sys0_clk, sys0_rst);             // Instance the Infrastructre
  Vector#(iNwci_ctop, Reset) resetVec = newVector;                                 // Vector of WCI Resets
  for (Integer i=0; i<iNwci_app; i=i+1) resetVec[i] = inf.wci_m[i].mReset_n;       // Reset Vector for the Application
  OCAppIfc#(Nwci_app,Nwmi,Nwmemi)  app  <- mkOCApp(resetVec);                      // Instance the Application
  for (Integer i=0; i<iNwci_app; i=i+1) mkConnection(inf.wci_m[i], app.wci_s[i]);  // Connect WCI between INF/APP
  Vector#(Nwci_ftop, Wci_Em#(20)) wci_c2f = takeAt(iNwci_app, inf.wci_m);          // Take the unused WCI for FTop

  // WMI interfaces between App(masters) to Inf(Slaves)...
  mkConnection(app.wmiM0, inf.wmiS0);
  mkConnection(app.wmiM1, inf.wmiS1);

  interface Server server     = inf.server;
  method led                  = inf.led;
  method switch               = inf.switch;
  interface GPS64_t cpNow     = inf.cpNow;
  interface GPSIfc  gps       = inf.gps;
  interface Vector  wci_m     = wci_c2f;
  interface Wsi_s wsi_s_adc   = app.wsi_s_adc; // The ADC device-worker to the application
  interface Wsi_m wsi_m_dac   = app.wsi_m_dac; // The DAC device-worker to the application
  interface WmemiEM16B wmemiM = app.wmemiM;
endmodule : mkCTop

endpackage: CTop
