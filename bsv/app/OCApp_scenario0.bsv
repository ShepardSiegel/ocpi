// OCApp.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip::*;

import BiasWorker::*;
import SMAdapter::*;
import Config::*;
//import ProtocolMonitor::*;

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
  interface Vector#(nWci,WciES) wci_s;
  interface WmiEM4B             wmiM0;
  interface WmiEM4B             wmiM1;
  interface WmemiEM16B          wmemiM0;
  interface WsiES4B             wsi_s_adc;
  interface WsiEM4B             wsi_m_dac;
endinterface

module mkOCApp_poly#(Vector#(nWci, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(nWci,nWmi,nWmemi));

  // Instance the workers in this application container...
  SMAdapter4BIfc    appW2    <-  mkSMAdapter4B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  BiasWorker4BIfc   appW3    <-  mkBiasWorker4B (              hasDebugLogic, reset_by(rst[3])); // Bias ahead of first SMAdapter
  SMAdapter4BIfc    appW4    <-  mkSMAdapter4B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write

  // TODO: Use Default for tieOff...
  WciES tieOff0 <- mkWciSlaveENull;
  WciES tieOff1 <- mkWciSlaveENull;
  WciES tieOff5 <- mkWciSlaveENull;
  WciES tieOff6 <- mkWciSlaveENull;
  WciES tieOff7 <- mkWciSlaveENull;

  // Connect each worker to its WCI...
  Vector#(nWci,WciES) vWci;
  vWci[0] = tieOff0;
  vWci[1] = tieOff1;
  vWci[2] = appW2.wciS0;
  vWci[3] = appW3.wciS0;
  vWci[4] = appW4.wciS0;
  vWci[5] = tieOff5;
  vWci[6] = tieOff6;
  vWci[7] = tieOff7;

// Protocol Monitor IPs...
// WsiMonitorIfc             wsiMonW23         <- mkWsiMonitor(8'h52);
// PMEMMonitorWsiIfc            pmemMonW23        <- mkPMEMMonitorWsi;
// mkConnection(wciMonW23.pmem, pmemMonW23.pmem);
//mkConnectionMSO(appW2.wsiM0, appW3.wsiS0, wsiMon23.observe);  // W2 SMAdapter WSI-M0   feeding W3 BiasWorker WSI-S0

  // Connect co-located WSI ports...
  mkConnection(appW2.wsiM0, appW3.wsiS0);  // W2 SMAdapter  WSI-M0 feeding W3 BiasWorker WSI-S0
  mkConnection(appW3.wsiM0, appW4.wsiS0);  // W3 BiasWorker WSI-M0 feeding W4 SMAdapter  WSI-S0

  interface wci_s     = vWci;

  // Connect appropriate workers to their WMI...
  interface wmiM0     = appW2.wmiM0;
  interface wmiM1     = appW4.wmiM0;

  interface wsi_s_adc = appW2.wsiS0;  // The ADC data to the   W2 SMAdapter WSI-S0 Slave Port
  interface wsi_m_dac = appW4.wsiM0;  // The DAC data from the W4 SMAdapter WSI-M0 Master Port

endmodule : mkOCApp_poly

(* synthesize *)
module mkOCApp4B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(Nwci_app,Nwmi,Nwmemi));
   (*hide*)
   let _ifc <- mkOCApp_poly(rst, hasDebugLogic);
   return _ifc;
endmodule: mkOCApp4B

endpackage: OCApp
