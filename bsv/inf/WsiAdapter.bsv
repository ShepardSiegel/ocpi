// WsiAdapter - Simple, Synchronous Adapation between common WSI Profile Choices
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package WsiAdapter;

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

interface WsiAdapter4B32BIfc;
  interface WsiES4B     wsiS0;
  interface WsiEM32B    wsiM0;
endinterface 

interface WsiAdapter32B4BIfc;
  interface WsiES32B    wsiS0;
  interface WsiEM4B     wsiM0;
endinterface 


//TODO: Correctly write me for all cases, both ways
// Remember that OCP MBurstLength is in transfer cycles, not Bytes; so must be adjusted


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
  function Bit#(32) getData(WsiReq#(12,32,4,8,0) s) =  s.data;
  wsiM.reqPut.put(
    WsiReq { cmd:           WR,
             reqLast:       isLast,
             reqInfo:       stage[0].reqInfo,
             burstPrecise:  stage[0].burstPrecise,
             burstLength:   stage[0].burstLength / 4,            // 1/4 the output transfers
             data:          pack(map(getData,readVReg(stage))),  // Take Little-Endian DWORDS
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
             burstLength:   req16.burstLength * 4,   // 4x the outputput transfers
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


(* synthesize *)
module mkWsiAdapter4B32B (WsiAdapter4B32BIfc);
  WsiSlaveIfc #(12, 32, 4,8,0)          wsiS    <- mkWsiSlave;
  WsiMasterIfc#(12,256,32,8,0)          wsiM    <- mkWsiMaster;
  Vector#(8,Reg#(WsiReq#(12,32,4,8,0))) stage   <- replicateM(mkRegU);
  Reg#(Bit#(3))                         pos     <- mkReg(0);
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
  isFull <= (pos==7 || r.reqLast);
endrule

rule doRequestEgress (isFull);
  Bit#(32) be = ?;
  case (pos)
    0 : be =          extend({                                                                                                stage[0].byteEn});
    1 : be =          extend({                                                                                stage[1].byteEn,stage[0].byteEn});
    2 : be =          extend({                                                                stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    3 : be =          extend({                                                stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    4 : be =          extend({                                stage[4].byteEn,stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    5 : be =          extend({                stage[5].byteEn,stage[4].byteEn,stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    6 : be =          extend({stage[6].byteEn,stage[5].byteEn,stage[4].byteEn,stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn});
    7 : be = {stage[7].byteEn,stage[6].byteEn,stage[5].byteEn,stage[4].byteEn,stage[3].byteEn,stage[2].byteEn,stage[1].byteEn,stage[0].byteEn};
  endcase
  function Bit#(32) getData(WsiReq#(12,32,4,8,0) s) =  s.data;
  wsiM.reqPut.put(
    WsiReq { cmd:           WR,
             reqLast:       isLast,
             reqInfo:       stage[0].reqInfo,
             burstPrecise:  stage[0].burstPrecise,
             burstLength:   stage[0].burstLength / 8,            // 1/8 the output transfers
             data:          pack(map(getData,readVReg(stage))),  // Take Little-Endian DWORDS
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
module mkWsiAdapter32B4B (WsiAdapter32B4BIfc);
  WsiSlaveIfc #(12,256,32,8,0)          wsiS    <- mkWsiSlave;
  WsiMasterIfc#(12, 32, 4,8,0)          wsiM    <- mkWsiMaster;
  Reg#(Bool)                            isEmpty <- mkReg(True);
  Reg#(WsiReq#(12,256,32,8,0))          req32   <- mkRegU;
  Reg#(Bit#(3))                         pos     <- mkReg(0);
  Reg#(Bool)                            isLast  <- mkReg(False);

(* fire_when_enabled, no_implicit_conditions *)
rule operating_actions;
  wsiS.operate();  wsiM.operate();
endrule

rule doRequestIngress (isEmpty);
  let r  <-  wsiS.reqGet.get;
  req32   <= r;
  isLast  <= r.reqLast;
  isEmpty <= False;
endrule

rule doRequestEgress (!isEmpty);
  Bit#(32) data = 0;
  Bit#(4)  be   = 0;
  case (pos)
    0: begin data = req32.data[31:0];    be = req32.byteEn[3:0];   end
    1: begin data = req32.data[63:32];   be = req32.byteEn[7:4];   end
    2: begin data = req32.data[95:64];   be = req32.byteEn[11:8];  end
    3: begin data = req32.data[127:96];  be = req32.byteEn[15:12]; end
    4: begin data = req32.data[159:128]; be = req32.byteEn[19:16]; end
    5: begin data = req32.data[191:160]; be = req32.byteEn[23:20]; end
    6: begin data = req32.data[223:192]; be = req32.byteEn[27:24]; end
    7: begin data = req32.data[255:224]; be = req32.byteEn[31:28]; end
  endcase
  wsiM.reqPut.put(
    WsiReq { cmd:           WR,
             reqLast:       isLast && (pos==7),
             reqInfo:       req32.reqInfo,
             burstPrecise:  req32.burstPrecise,
             burstLength:   req32.burstLength * 8,    // 8x the output transfers
             data:          data,
             byteEn:        be,
             dataInfo:      req32.dataInfo }
    );
   pos <= pos + 1;
   isEmpty <= (pos==7);
endrule

  WsiES32B wsi_Es <- mkWsiStoES(wsiS.slv); 
  interface Wsi_Es wsiS0 = wsi_Es;
  interface Wsi_Em wsiM0 = toWsiEM(wsiM.mas);
endmodule

endpackage
