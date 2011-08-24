// OCApp.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip::*;
//import ProtocolMonitor::*;
import UUID::*;


import BiasWorker::*;
//import DelayWorker::*;
import SMAdapter::*;
import Config::*;

import Clocks::*;
import FIFO::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;

`ifdef USE_NDW1
  `define DEFINE_NDW 1
`elsif USE_NDW2
  `define DEFINE_NDW 2
`elsif USE_NDW4
  `define DEFINE_NDW 4
`elsif USE_NDW8
  `define DEFINE_NDW 8
`endif

// nWci   - number of Wci Worker Control Links
// nWmi   - number of WMI Interfaces
// nWmemi - number of WMI Interfaces
// ndw    - number of 4B DWORDs in WSI and WMI datapaths
// Using numeric types, not types, so this is Polymorphic, unlike OCInf 

interface OCAppIfc#(numeric type nWci, numeric type nWmi, numeric type nWmemi, numeric type ndw);
  interface Vector#(nWci,WciES)                             wci_s;
  interface Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiM0;  
  interface Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiM1;  
  interface WmemiEM16B                                      wmemiM0;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)      wsi_s_adc;   
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)      wsi_m_dac;  
  (*always_ready*) method Bit#(512) uuid;
endinterface

module mkOCApp_poly#(Vector#(nWci, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(nWci,nWmi,nWmemi,ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)),    // by shep
    Add#(1, a__, TAdd#(3, TAdd#(1, TAdd#(1, TAdd#(12, TAdd#(TMul#(ndw, 32), TAdd#(TMul#(ndw, 4), 8))))))),                          // by bsc output
    NumAlias#(ndw, `DEFINE_NDW) ); // by joe (modified by Dan)

  UUIDIfc         id   <- mkUUID;

  /*
  WciMonitorIfc            wciMonW3         <- mkWciMonitor(8'h42); // monId=h42
  PMEMMonitorIfc              pmemMonW3        <- mkPMEMMonitor;
  mkConnection(wciMonW3.pmem, pmemMonW3.pmem);  // Connect the wciMon to an event monitor
  */

  // Instance the workers in this application container...

`ifdef USE_NDW1
  SMAdapter4BIfc   appW2   <-  mkSMAdapter4B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  //DelayWorker4BIfc appW3   <-  mkDelayWorker4B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  BiasWorker4BIfc appW3   <-  mkBiasWorker4B (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter4BIfc   appW4   <-  mkSMAdapter4B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW4
  SMAdapter16BIfc   appW2   <-  mkSMAdapter16B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  //DelayWorker16BIfc appW3   <-  mkDelayWorker16B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  BiasWorker16BIfc appW3   <-  mkBiasWorker16B (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter16BIfc   appW4   <-  mkSMAdapter16B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`endif

  // 'PLAN A': This compiles and functions; but does not allows us to have synthesis bounds at each worker as required...
  // Here we show instancing the underlying polymorhic modules directly (nice!)...
  /*
  SMAdapterIfc  #(ndw) appW2   <-  mkSMAdapter   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  DelayWorkerIfc#(ndw) appW3   <-  mkDelayWorker (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapterIfc  #(ndw) appW4   <-  mkSMAdapter   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
  */

  // 'PLAN B': This doesn't work, because bsc doesn't get to choose across the case arms until too late...
  // Here we do this manually (yuck!), because we had the desire to implement discrete worker RTL modules with synth bounds...
  /*
  case (iNDW_global)
  1:
    begin
      SMAdapter4BIfc    appW2    <-  mkSMAdapter4B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker4BIfc  appW3    <-  mkDelayWorker4B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter4BIfc    appW4    <-  mkSMAdapter4B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
    end
  2:
    begin
      SMAdapter8BIfc    appW2    <-  mkSMAdapter8B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker8BIfc  appW3    <-  mkDelayWorker8B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter8BIfc    appW4    <-  mkSMAdapter8B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
    end
  4:
    begin
      SMAdapter16BIfc   appW2    <-  mkSMAdapter16B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker16BIfc appW3    <-  mkDelayWorker16B(32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter16BIfc   appW4    <-  mkSMAdapter16B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
    end
  8:
    begin
      SMAdapter32BIfc   appW2    <-  mkSMAdapter32B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker32BIfc appW3    <-  mkDelayWorker32B(32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter32BIfc   appW4    <-  mkSMAdapter32B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
    end
  endcase
  */

  // 'PLAN C': This satisfies the compiler at first. but can't tell bsc what ndw is...
  // Here we use (super-yuck) `defines...
  /*
`ifdef USE_NDW1
      SMAdapter4BIfc    appW2    <-  mkSMAdapter4B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker4BIfc  appW3    <-  mkDelayWorker4B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter4BIfc    appW4    <-  mkSMAdapter4B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW2
      SMAdapter8BIfc    appW2    <-  mkSMAdapter8B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker8BIfc  appW3    <-  mkDelayWorker8B (32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter8BIfc    appW4    <-  mkSMAdapter8B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW4
      SMAdapter16BIfc   appW2    <-  mkSMAdapter16B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker16BIfc appW3    <-  mkDelayWorker16B(32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter16BIfc   appW4    <-  mkSMAdapter16B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW8
      SMAdapter32BIfc   appW2    <-  mkSMAdapter32B  (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
      DelayWorker32BIfc appW3    <-  mkDelayWorker32B(32'h00000000, hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
      SMAdapter32BIfc   appW4    <-  mkSMAdapter32B  (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`endif
  */

  // TODO: Use Default for tieOff...
  Wci_Es#(32) tieOff0  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff1  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff5  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff6  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff7  <- mkWciSlaveENull;

  // Connect each worker to its WCI...
  Vector#(nWci,Wci_Es#(32)) vWci;
  vWci[0] = tieOff0;
  vWci[1] = tieOff1;
  vWci[2] = appW2.wciS0;
  vWci[3] = appW3.wciS0;
  //mkConnectionMSO(wciM3,  appW3.wciS0, wciMonW3.wciO0);  // Connect the WCI Master to the DUT (using mkConnectionMSO to add PM Observer)
  vWci[4] = appW4.wciS0;
  vWci[5] = tieOff5;
  vWci[6] = tieOff6;
  vWci[7] = tieOff7;

  // Connect co-located WSI ports...
  mkConnection(appW2.wsiM0, appW3.wsiS0);  // W2 SMAdapter WSI-M0   feeding W3 DelayWorker WSI-S0
  mkConnection(appW3.wsiM0, appW4.wsiS0);  // W3 DelayWorker WSI-M0 feeding W4 SMAdapter WSI-S0

  interface wci_s     = vWci;

  // Connect appropriate workers to their WMI...
  interface wmiM0     = appW2.wmiM0;
  interface wmiM1     = appW4.wmiM0;

  // Connect appropriate workers to their Wmemi...
  //interface wmemiM0   = appW3.wmemiM0;  // W3 DelayWroker Wmemi connect

  interface wsi_s_adc = appW2.wsiS0;    // The ADC data to the   W2 SMAdapter WSI-S0 Slave Port
  interface wsi_m_dac = appW4.wsiM0;    // The DAC data from the W4 SMAdapter WSI-M0 Master Port

  method Bit#(512) uuid = id.uuid;      // The always-ready UUID value

endmodule : mkOCApp_poly

// Synthesizeable, non-polymorphic modules that use the poly module above...

`ifdef USE_NDW1
typedef OCAppIfc#(Nwci_app,Nwmi,Nwmemi,1) OCApp4BIfc;
(* synthesize *)
module mkOCApp4B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp4BIfc);
  OCApp4BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW2
typedef OCAppIfc#(Nwci_app,Nwmi,Nwmemi,2) OCApp8BIfc;
(* synthesize *)
module mkOCApp8B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp8BIfc);
  OCApp8BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW4
typedef OCAppIfc#(Nwci_app,Nwmi,Nwmemi,4) OCApp16BIfc;
(* synthesize *)
module mkOCApp16B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp16BIfc);
  OCApp16BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW8
typedef OCAppIfc#(Nwci_app,Nwmi,Nwmemi,8) OCApp32BIfc;
(* synthesize *)
module mkOCApp32B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp32BIfc);
  OCApp32BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`endif


// Original poly wrapper...
/*
(* synthesize *)
module mkOCApp#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(Nwci_app,Nwmi,Nwmemi));
   (*hide*) let _ifc <- mkOCApp_poly(rst, hasDebugLogic); return _ifc;
endmodule: mkOCApp
*/


endpackage: OCApp
