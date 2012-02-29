// OCApp.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip            ::*;
import ProtocolMonitor  ::*;
import UUID             ::*;

import BiasWorker       ::*;
import MemiTestWorker   ::*;
import Config           ::*;
//import DelayWorker::*;
import SMAdapter        ::*;
import TimeService      ::*;
import WSICaptureWorker ::*;

import ClientServer ::*;
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;
import GetPut       ::*;
import Vector       ::*;

`ifdef USE_NDW1
  `define DEFINE_NDW 1
`elsif USE_NDW2
  `define DEFINE_NDW 2
`elsif USE_NDW4
  `define DEFINE_NDW 4
`elsif USE_NDW8
  `define DEFINE_NDW 8
`endif

// nWci   - number of WCI Worker Control Links
// nWti   - number of WTI Slaves in Application
// nWmi   - number of WMI Interfaces
// nWmemi - number of WMI Interfaces
// ndw    - number of 4B DWORDs in WSI and WMI datapaths
// Using numeric types, not types, so this is Polymorphic, unlike OCInf 

interface OCAppIfc#(numeric type nWci, numeric type nWti, numeric type nWmi, numeric type nWmemi, numeric type ndw);
  interface Vector#(nWci,WciES)                             wci_s;
  interface Vector#(nWti,Wti_Es#(64))                       wti_s;
  interface Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiM0;  
  interface Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmiM1;  
  interface WmemiEM16B                                      wmemiM0;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)      wsi_s_adc;   
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)      wsi_m_dac;  
  (*always_ready*) method Bit#(512) uuid;
endinterface

module mkOCApp_poly#(Vector#(nWci, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(nWci,nWti,nWmi,nWmemi,ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)),    // by shep
    Add#(1, a__, TAdd#(3, TAdd#(1, TAdd#(1, TAdd#(12, TAdd#(TMul#(ndw, 32), TAdd#(TMul#(ndw, 4), 8))))))),                          // by bsc output
    NumAlias#(ndw, `DEFINE_NDW) ); // by joe (modified by Dan)

  UUIDIfc         id   <- mkUUID;

`ifdef OBSERVER

  // Observe the WCI port of the BiasWorker W3...
  WciMonitorIfc               wciMonW3              <- mkWciMonitor(8'h80); // monId=h80
  WSICaptureWorker4BIfc       captWorker0           <- mkWSICaptureWorker(True, reset_by(rst[5]));
  mkConnection(wciMonW3.pmem, captWorker0.wsiS0);   // Connect the monitor to the capture worker

  // Observe the WSI-S port of the BiasWorker W3...
  WsiMonitorIfc#(12,TMul#(ndw,32),TMul#(ndw,4),8,0) wsisMonW3 <- mkWsiMonitor(8'h81); // monId=h81
  WSICaptureWorker4BIfc       captWorker1           <- mkWSICaptureWorker(True, reset_by(rst[6]));
  mkConnection(wsisMonW3.pmem, captWorker1.wsiS0);  // Connect the monitor to the capture worker

  // Observe the WSI-M port of the BiasWorker W3...
  WsiMonitorIfc#(12,TMul#(ndw,32),TMul#(ndw,4),8,0) wsimMonW3 <- mkWsiMonitor(8'h82); // monId=h82
  WSICaptureWorker4BIfc       captWorker2           <- mkWSICaptureWorker(True, reset_by(rst[7]));
  mkConnection(wsimMonW3.pmem, captWorker2.wsiS0);  // Connect the monitor to the capture worker

`endif

 // Instance the workers in this application container...

`ifdef USE_NDW1
  MemiTestWorkerIfc appW1   <-  mkMemiTestWorker (              hasDebugLogic, reset_by(rst[1]));
  SMAdapter4BIfc    appW2   <-  mkSMAdapter4B    (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  BiasWorker4BIfc   appW3   <-  mkBiasWorker4B   (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter4BIfc    appW4   <-  mkSMAdapter4B    (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW2
  MemiTestWorkerIfc appW1   <-  mkMemiTestWorker (              hasDebugLogic, reset_by(rst[1]));
  SMAdapter8BIfc    appW2   <-  mkSMAdapter8B    (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  BiasWorker8BIfc   appW3   <-  mkBiasWorker8B   (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter8BIfc    appW4   <-  mkSMAdapter8B    (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW4
  MemiTestWorkerIfc appW1   <-  mkMemiTestWorker (              hasDebugLogic, reset_by(rst[1]));
  SMAdapter16BIfc   appW2   <-  mkSMAdapter16B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  BiasWorker16BIfc  appW3   <-  mkBiasWorker16B  (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter16BIfc   appW4   <-  mkSMAdapter16B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`elsif USE_NDW8
  MemiTestWorkerIfc appW1   <-  mkMemiTestWorker (              hasDebugLogic, reset_by(rst[1]));
  SMAdapter32BIfc   appW2   <-  mkSMAdapter32B   (32'h00000001, hasDebugLogic, reset_by(rst[2])); // Read WMI to WSI-M 
  BiasWorker32BIfc  appW3   <-  mkBiasWorker32B  (              hasDebugLogic, reset_by(rst[3])); // Delay ahead of first SMAdapter
  SMAdapter32BIfc   appW4   <-  mkSMAdapter32B   (32'h00000002, hasDebugLogic, reset_by(rst[4])); // WSI-S to WMI Write
`endif


  // TODO: Use Default for tieOff...
  Wci_Es#(32) tieOff0  <- mkWciSlaveENull;

  // Connect each worker to its WCI...
  Vector#(nWci,Wci_Es#(32)) vWci;
  vWci[0] = tieOff0;
  vWci[1] = appW1.wciS0;
  vWci[2] = appW2.wciS0;
  vWci[3] = appW3.wciS0;
  //mkConnectionMSO(vWci[3], appW3.wciS0, wciMonW3.observe);  // Connect the WCI Master to the DUT 
  vWci[4] = appW4.wciS0;

`ifdef OBSERVER
  vWci[5] = captWorker0.wciS0;
  vWci[6] = captWorker1.wciS0;
  vWci[7] = captWorker2.wciS0;
  // Connect each workers WTI Slave interfaces...
  Vector#(nWti,Wti_Es#(64)) vWti;
  vWti[0] = captWorker0.wtiS0;
  vWti[1] = captWorker1.wtiS0;
  vWti[2] = captWorker2.wtiS0;
  // Connect co-located WSI ports...
  mkConnectionMSO(appW2.wsiM0, appW3.wsiS0 ,wsisMonW3.observe);  // W2 SMAdapter WSI-M0   feeding W3 DelayWorker WSI-S0
  mkConnectionMSO(appW3.wsiM0, appW4.wsiS0 ,wsimMonW3.observe);  // W3 DelayWorker WSI-M0 feeding W4 SMAdapter WSI-S0
`else
  Wci_Es#(32) tieOff5  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff6  <- mkWciSlaveENull;
  Wci_Es#(32) tieOff7  <- mkWciSlaveENull;
  vWci[5] = tieOff5;
  vWci[6] = tieOff6;
  vWci[7] = tieOff7;
  // Connect co-located WSI ports...
  mkConnection(appW2.wsiM0, appW3.wsiS0);
  mkConnection(appW3.wsiM0, appW4.wsiS0);
`endif

  interface wci_s     = vWci;
`ifdef OBSERVER
  interface wti_s     = vWti;
`endif

  // Connect appropriate workers to their WMI...
  interface wmiM0     = appW2.wmiM0;
  interface wmiM1     = appW4.wmiM0;

  // Connect appropriate workers to their Wmemi...
  interface wmemiM0   = appW1.wmemiM0;  // W1 MemiTestWorker Wmemi connect

  interface wsi_s_adc = appW2.wsiS0;    // The ADC data to the   W2 SMAdapter WSI-S0 Slave Port
  interface wsi_m_dac = appW4.wsiM0;    // The DAC data from the W4 SMAdapter WSI-M0 Master Port

  method Bit#(512) uuid = id.uuid;      // The always-ready UUID value

endmodule : mkOCApp_poly

// Synthesizeable, non-polymorphic modules that use the poly module above...

`ifdef USE_NDW1
typedef OCAppIfc#(Nwci_app,Nwti_app,Nwmi,Nwmemi,1) OCApp4BIfc;
(* synthesize *)
module mkOCApp4B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp4BIfc);
  OCApp4BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW2
typedef OCAppIfc#(Nwci_app,Nwti_app,Nwmi,Nwmemi,2) OCApp8BIfc;
(* synthesize *)
module mkOCApp8B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp8BIfc);
  OCApp8BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW4
typedef OCAppIfc#(Nwci_app,Nwti_app,Nwmi,Nwmemi,4) OCApp16BIfc;
(* synthesize *)
module mkOCApp16B#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCApp16BIfc);
  OCApp16BIfc _a <- mkOCApp_poly(rst, hasDebugLogic); return _a;
endmodule
`elsif USE_NDW8
typedef OCAppIfc#(Nwci_app,Nwti_app,Nwmi,Nwmemi,8) OCApp32BIfc;
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
