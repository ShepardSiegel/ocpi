// OCApp.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip::*;

import GCDWorker::*;
import FCAdapter::*;
import BiasWorker::*;
import FPAdapter::*;
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

interface OCAppIfc#(numeric type nWci, numeric type nWmi);
  interface Vector#(nWci,WciS)        wci_s;
  interface Vector#(nWmi,WmiM4B)      wmi_m;
  interface Wsi_s#(12,32,4,8,1)       wsi_s_adc;  //nd=32 not poly
endinterface

module mkOCApp_poly#(Vector#(nWci, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(nWci,nWmi));

  // Instance the workers in this application container...
  GCDWorkerIfc    gcdW0     <-  mkGCDWorker(0, hasDebugLogic, reset_by(rst[0]));
  GCDWorkerIfc    gcdW1     <-  mkGCDWorker(1, hasDebugLogic, reset_by(rst[1]));

  FCAdapter4BIfc  wmiW2     <-  mkFCAdapter4B (                      reset_by(rst[2]));
  BiasWorker4BIfc wmiW3     <-  mkBiasWorker4B(32'h0, hasDebugLogic, reset_by(rst[3]));
  FPAdapter4BIfc  wmiW4     <-  mkFPAdapter4B (                      reset_by(rst[4]));


  WciSlaveNullIfc#(32) tieOff5  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff6  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff7  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff8  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff9  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff10 <- mkWciSlaveNull;
  //WciSlaveNullIfc#(32) tieOff11 <- mkWciSlaveNull;
  //WciSlaveNullIfc#(32) tieOff12 <- mkWciSlaveNull;
  //WciSlaveNullIfc#(32) tieOff13 <- mkWciSlaveNull;
  //WciSlaveNullIfc#(32) tieOff14 <- mkWciSlaveNull;

  // Connect each worker to its WCI...
  Vector#(nWci,WciS) vWci;
  vWci[0] = gcdW0.wciS0;
  vWci[1] = gcdW1.wciS0;
  vWci[2] = wmiW2.wciS0;
  vWci[3] = wmiW3.wciS0;
  vWci[4] = wmiW4.wciS0;

  vWci[5]  = tieOff5.slv;
  vWci[6]  = tieOff6.slv;
  vWci[7]  = tieOff7.slv;
  vWci[8]  = tieOff8.slv;
  vWci[9]  = tieOff9.slv;
  //vWci[10] = tieOff10.slv;
  //vWci[11] = tieOff11.slv;
  //vWci[12] = tieOff12.slv;
  //vWci[13] = tieOff13.slv;
  //vWci[14] = tieOff14.slv;

  // Connect appropriate workers to their WMI...
  Vector#(nWmi,WmiM4B) vWmi;
  vWmi[0] = wmiW2.wmi_m;  // FCWorker
  vWmi[1] = wmiW4.wmi_m;  // FPWorker

  // Connect co-located WSI ports...
  mkConnection(wmiW2.wsi_m, wmiW3.wsi_s0);
  mkConnection(wmiW3.wsi_m, wmiW4.wsi_s);

  interface Vector wci_s = vWci;
  interface Vector wmi_m = vWmi;
  interface Wsi_s wsi_s_adc = wmiW3.wsi_s1; // The ADC data to the bias Worker

endmodule : mkOCApp_poly

(* synthesize *)
module mkOCApp#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(Nwci_app,Nwmi));
   (*hide*)
   let _ifc <- mkOCApp_poly(rst, hasDebugLogic);
   return _ifc;
endmodule: mkOCApp

endpackage: OCApp
