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
  interface Vector#(Nwci_ftop, Wci_m#(20)) wci_m;  // provide WCI interfaces to Ftop
  interface  GPS64_t    cpNow;
  interface  WsiS16B    wsi_s_adc;
  interface  WsiM16B    wsi_m_dac;
  interface  WmemiM16B  wmemi_m;
  interface  GPSIfc     gps;
endinterface 

module mkCTop#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (CTopIfc);
  OCInfIfc#(Nwci_ctop,Nwmi) inf  <- mkOCInf(pciDevice, sys0_clk, sys0_rst);        // Instance the Infrastructre
  Vector#(iNwci_ctop, Reset) resetVec = newVector;
  for (Integer i=0; i<iNwci_app; i=i+1) resetVec[i] = inf.wci_m[i].mReset_n;       // Reset Vector for the Application
  OCAppIfc#(Nwci_app,Nwmi,Nwmemi)  app  <- mkOCApp(resetVec);                      // Instance the Application
  for (Integer i=0; i<iNwci_app; i=i+1) mkConnection(inf.wci_m[i], app.wci_s[i]);  // Connect WCI between INF/APP
  Vector#(Nwci_ftop, Wci_m#(20)) wci_c2f = ?;
  for (Integer j=0; j<iNwci_ftop; j=j+1) wci_c2f[j] = inf.wci_m[j+iNwci_app];      // Connect WCI INF/CTOP/FTOP
  // WMI...
  mkConnection(app.wmi_m, inf.wmi_s);     // Vector of WMI interfaces between App(masters) to Inf(Slaves)

  interface Server server     = inf.server;
  method led                  = inf.led;
  method switch               = inf.switch;
  interface GPS64_t cpNow     = inf.cpNow;
  interface GPSIfc  gps       = inf.gps;
  interface Vector  wci_m     = wci_c2f;
  interface Wsi_s wsi_s_adc   = app.wsi_s_adc; // The ADC device-worker to the application
  interface Wsi_m wsi_m_dac   = app.wsi_m_dac; // The DAC device-worker to the application
  interface WmemiM16B wmemi_m = app.wmemi_m;
endmodule : mkCTop

endpackage: CTop
