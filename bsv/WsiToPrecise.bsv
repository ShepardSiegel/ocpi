// WsiToPrecise - Convert a (possibly) imprecise WSI input stream to a precise stream
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import Alias::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;

interface WsiToPreciseIfc#(numeric type ndw);
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiM1;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiS1;
endinterface 

module mkWsiToPrecise#(parameter Bit#(32) smaCtrlInit) (WsiToPreciseIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM              <- mkWsiMaster;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS              <- mkWsiSlave;

rule operating_actions (True);
  wsiM.operate();
  wsiS.operate();
endrule

rule wsipass_doMessagePush (wci.isOperating && wsiPass);
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
endrule

// TODO: Imprecise to Precise n-buffering...
// Convert Stream to Message, Store Message, Retrieve Message, Convert Message to Stream
// ? Is there a more-efficient way, in general, to perform this transformation ?

  Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsi_Es <- mkWsiStoES(wsiS.slv);
  Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32) wmi_Em <- mkWmiMtoEm(wmi.mas);

  interface wsiM1 = toWsiEM(wsiM.mas); 
  interface wsiS1 = wsi_Es;

endmodule


// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiToPreciseIfc#(1) WsiToPrecise4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise4B (WsiToPrecise4BIfc);
  WsiToPrecise4BIfc _a <- mkWsiToPrecise(smaCtrlInit); return _a;
endmodule

typedef WsiToPreciseIfc#(2) WsiToPrecise8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise8B (WsiToPrecise8BIfc);
  WsiToPrecise8BIfc _a <- mkWsiToPrecise(smaCtrlInit); return _a;
endmodule

typedef WsiToPreciseIfc#(4) WsiToPrecise16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise16B (WsiToPrecise16BIfc);
  WsiToPrecise16BIfc _a <- mkWsiToPrecise(smaCtrlInit); return _a;
endmodule

typedef WsiToPreciseIfc#(8) WsiToPrecise32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWsiToPrecise32B (WsiToPrecise32BIfc);
  WsiToPrecise32BIfc _a <- mkWsiToPrecise(smaCtrlInit); return _a;
endmodule

