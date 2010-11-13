// WsiAdapter - Simple, Synchronous Adapation between common WSI Profile Choices
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import Vector::*;

interface WsiAdapter4B16BIfc;
  interface WsiES4B     wsiS0;
  interface WsiEM16B    wsiM0;
endinterface 

interface WsiAdapter16B4BIfc;
  interface WsiES16B    wsiS0;
  interface WsiEM4B     wsiM0;
endinterface 


//TODO: Correctly write me for all cases, both ways


(* synthesize *)
module mkWsiAdapter4B16B (WsiAdapter4B16BIfc);
  WsiSlaveIfc #(12, 32, 4,8,0)          wsiS    <- mkWsiSlave;
  WsiMasterIfc#(12,128,16,8,0)          wsiM    <- mkWsiMaster;
  Vector#(4,Reg#(WsiReq#(12,32,4,8,0))) stage   <- replicateM(mkRegU);
  Reg#(Bit#(2))                         pos     <- mkReg(0);
  Reg#(Bool)                            isLast  <- mkReg(False);
  Reg#(Bool)                            isFull  <- mkReg(False);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions;
  wsiS.operate();  wsiM.operate();
endrule

rule doRequestIngress(!isFull);
  let r  <-  wsiS.reqGet.get;
  stage[pos] <= r;
  isLast <= r.reqLast;
  pos <= pos + 1;
  isFull <= (pos==3 || r.reqLast);
endrule

rule doRequestEgress (isFull);
  Bit#(16) be = ?;
  case (pos)
    0 : be = extend({                                                stage[0].byteEn});
    1 : be = extend({                                stage[1].byteEn,stage[0].byteEn});
    2 : be = extend({                stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    3 : be =        {stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn};
  endcase
  wsiM.reqPut.put(
    WsiReq { cmd:           WR,
             reqLast:       isLast,
             reqInfo:       stage[0].reqInfo,
             burstPrecise:  stage[0].burstPrecise,
             burstLength:   stage[0].burstLength,
             data:          {stage[3].data,  stage[2].data,  stage[1].data,  stage[0].data},
             byteEn:        be,
             dataInfo:      stage[0].dataInfo }
    );
   pos    <= 0;
   isLast <= False;
   isFull <= False;
endrule

  WsiES4B wsi_Es <- mkWsiStoES(wsiS.slv); 
  interface Wsi_Es wsiS0 = wsi_Es;
  interface Wsi_Em wsiM0 = toWsiEM(wsiM.mas);
endmodule


(* synthesize *)
module mkWsiAdapter16B4B (WsiAdapter16B4BIfc);
  WsiSlaveIfc #(12,128,16,8,0)          wsiS    <- mkWsiSlave;
  WsiMasterIfc#(12, 32, 4,8,0)          wsiM    <- mkWsiMaster;
  Reg#(Bool)                            isEmpty <- mkReg(True);
  Reg#(WsiReq#(12,128,16,8,0))          req16   <- mkRegU;
  Reg#(Bit#(2))                         pos     <- mkReg(0);
  Reg#(Bool)                            isLast  <- mkReg(False);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions;
  wsiS.operate();  wsiM.operate();
endrule

rule doRequestIngress (isEmpty);
  let r  <-  wsiS.reqGet.get;
  req16   <= r;
  isLast  <= r.reqLast;
  isEmpty <= False;
endrule

rule doRequestEgress (!isEmpty);
  Bit#(32) data = 0;
  Bit#(4)  be   = 0;
  case (pos)
    0: begin data = req16.data[31:0];   be = req16.byteEn[3:0];   end
    1: begin data = req16.data[63:32];  be = req16.byteEn[7:4];   end
    2: begin data = req16.data[95:64];  be = req16.byteEn[11:8];  end
    3: begin data = req16.data[127:96]; be = req16.byteEn[15:12]; end
  endcase
  wsiM.reqPut.put(
    WsiReq { cmd:           WR,
             reqLast:       isLast && (pos==3),
             reqInfo:       req16.reqInfo,
             burstPrecise:  req16.burstPrecise,
             burstLength:   req16.burstLength,
             data:          data,
             byteEn:        be,
             dataInfo:      req16.dataInfo }
    );
   pos <= pos + 1;
   isEmpty <= (pos==3);
endrule

  WsiES16B wsi_Es <- mkWsiStoES(wsiS.slv); 
  interface Wsi_Es wsiS0 = wsi_Es;
  interface Wsi_Em wsiM0 = toWsiEM(wsiM.mas);
endmodule
