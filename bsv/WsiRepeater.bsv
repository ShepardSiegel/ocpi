// WsiRepeater.bsv - WSI Repeater (with optional clock crossing)
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import Vector::*;

interface WsiRepeaterIfc#(numeric type ndw, numeric type nd);
  interface Wsi_s#(12,nd,4,8,1)     wsi_s;
  interface Wsi_m#(12,nd,4,8,1)     wsi_m;
endinterface 

module mkWsiRepeater#(parameter Bool isAsync, Clock sClk, Reset sRst, Clock mClk, Reset mRst) (WsiRepeaterIfc#(ndw,nd))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2; // Width in Bytes

  WsiSlaveIfc #(12,nd,4,8,1)   wsiS          <- mkWsiSlave (clocked_by sClk, reset_by sRst);
  WsiMasterIfc#(12,nd,4,8,1)   wsiM          <- mkWsiMaster(clocked_by mClk, reset_by mRst);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions;
  wsiS.operate();  wsiM.operate();
endrule

rule doMessagePush;
  WsiReq#(12,nd,4,8,1) r <-  wsiS.reqGet.get;  // get from the selected slave
  wsiM.reqPut.put(r);                          // put the data to the WSI master
endrule

  interface Wsi_s wsi_s = wsiS.slv;
  interface Wsi_m wsi_m = wsiM.mas;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WsiRepeaterIfc#(1,32) WsiRepeater4BIfc;
(* synthesize *) module mkWsiRepeater4B (WsiRepeater4BIfc);
  WsiRepeater4BIfc _a <- mkWsiRepeater; return _a;
endmodule

typedef WsiRepeaterIfc#(2,64) WsiRepeater8BIfc;
(* synthesize *) module mkWsiRepeater8B (WsiRepeater8BIfc);
  WsiRepeater8BIfc _a <- mkWsiRepeater; return _a;
endmodule

typedef WsiRepeaterIfc#(4,128) WsiRepeater16BIfc;
(* synthesize *) module mkWsiRepeater16B (WsiRepeater16BIfc);
  WsiRepeater16BIfc _a <- mkWsiRepeater; return _a;
endmodule

typedef WsiRepeaterIfc#(8,256) WsiRepeater32BIfc;
(* synthesize *) module mkWsiRepeater32B (WsiRepeater32BIfc);
  WsiRepeater32BIfc _a <- mkWsiRepeater; return _a;
endmodule
