// OCApp.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip::*;

import DelayWorker::*;
import SMAdapter::*;
import Config::*;

import Clocks::*;
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;

// nWci - number of Wci Worker Control Links
// nWmi - number of WMI Interfaces
// Using numeric types, not types, so this is Polymorphic, unlike OCInf 

interface OCAppIfc#(numeric type nWci, numeric type nWmi, numeric type nWmemi);
  interface Vector#(nWci,Wci_s#(20))  wci_s;
  interface Vector#(nWmi,WmiM16B)     wmi_m;
  interface  WmemiM16B                wmemi_m;
  interface  WsiS16B                  wsi_s_adc;
  interface  WsiM16B                  wsi_m_dac;
endinterface

module mkOCApp_poly#(Vector#(nWci, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(nWci,nWmi,nWmemi));

  // Instance the workers in this application container...
  SMAdapter16BIfc    appW2    <-  mkSMAdapter16B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  DelayWorker16BIfc  appW3    <-  mkDelayWorker16B(32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter16BIfc    appW4    <-  mkSMAdapter16B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write

  // TODO: Use Defaults for tieOff...
  WciSlaveNullIfc#(20) tieOff0  <- mkWciSlaveNull;
  WciSlaveNullIfc#(20) tieOff1  <- mkWciSlaveNull;
  WciSlaveNullIfc#(20) tieOff5  <- mkWciSlaveNull;
  WciSlaveNullIfc#(20) tieOff6  <- mkWciSlaveNull;
  WciSlaveNullIfc#(20) tieOff7  <- mkWciSlaveNull;

  // Connect each worker to its WCI...
  Vector#(nWci,Wci_s#(20)) vWci;
  vWci[2] = appW2.wci_s;
  vWci[3] = appW3.wci_s;
  vWci[4] = appW4.wci_s;

  // TODO: Use Defaults for tieOff...
  vWci[0]  = tieOff0.slv;
  vWci[1]  = tieOff1.slv;
  vWci[5]  = tieOff5.slv;
  vWci[6]  = tieOff6.slv;
  vWci[7]  = tieOff7.slv;

  // Connect appropriate workers to their WMI...
  Vector#(nWmi,WmiM16B) vWmi;
  vWmi[0] = appW2.wmi_m;  // W2 SMAdapter
  vWmi[1] = appW4.wmi_m;  // W4 SMAdapter

  // Connect appropriate workers to their Wmemi
  Vector#(nWmemi,WmemiM16B) vWmemi;
  vWmemi[0] = appW3.wmemi_m;  // W3 DelayWroker Wmemi connect

  // Connect co-located WSI ports...
  mkConnection(appW2.wsi_m, appW3.wsi_s);  // W2 SMAdapter WSI-M feeding W3 DelayWorker
  mkConnection(appW3.wsi_m, appW4.wsi_s);  // W3 DelayWorker feeding W4 SMAdapter WSI-S

  interface Vector wci_s   = vWci;
  interface Vector wmi_m   = vWmi;
  interface Vector wmemi_m = vWmemi[0];
  interface Wsi_s wsi_s_adc = appW2.wsi_s; // The ADC data to the   W2 SMAdapter WSI Slave Port
  interface Wsi_m wsi_m_dac = appW4.wsi_m; // The DAC data from the W4 SMAdapter WSI Master Port

endmodule : mkOCApp_poly

(* synthesize *)
module mkOCApp#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(Nwci_app,Nwmi,Nwmemi));
   (*hide*)
   let _ifc <- mkOCApp_poly(rst, hasDebugLogic);
   return _ifc;
endmodule: mkOCApp

endpackage: OCApp
