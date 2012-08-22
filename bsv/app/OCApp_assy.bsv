// OCApp.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCApp;

import OCWip::*;

import DelayWorker::*;
import SMAdapter::*;
import Config::*;

import I_delayAssy::*;

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

  Clock wciClk <- exposeCurrentClock;
  Vector#(3,Reset) wciRst;
  wciRst[1] = rst[2];  // worker 2 SMA FC
  wciRst[0] = rst[3];  // worker 3 delayW
  wciRst[2] = rst[4];  // worker 4 SMA FP

  VdelayAssyIfc assy <- mkdelayAssy(wciClk, wciRst);

  // Connect each worker to its WCI...
  Vector#(nWci,WciES) vWci = ?;
  vWci[2] = assy.i_wci1;
  vWci[3] = assy.i_wci0;
  vWci[4] = assy.i_wci2;

  interface wci_s     = vWci;
  interface wmiM0     = assy.i_FC;
  interface wmiM1     = assy.i_FP;
  interface wmemiM0   = assy.i_wmemi0;
  interface wsi_s_adc = assy.i_adc;
  interface wsi_m_dac = assy.i_dac;

endmodule : mkOCApp_poly

(* synthesize *)
module mkOCApp#(Vector#(Nwci_app, Reset) rst, parameter Bool hasDebugLogic) (OCAppIfc#(Nwci_app,Nwmi,Nwmemi));
   (*hide*)
   let _ifc <- mkOCApp_poly(rst, hasDebugLogic);
   return _ifc;
endmodule: mkOCApp

endpackage: OCApp
