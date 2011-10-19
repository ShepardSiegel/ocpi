// DramServer_s4.bsv - DRAM Server (device worker) for Altera Stratix 4 DRAM_s4
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package DramServer_s4;

import Accum::*;
import Config::*;
import DRAM_s4::*;
import OCWip::*;

import Clocks::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;

export DRAM_s4::*;
export DramServer_s4::*;

interface DramServer_s4Ifc;
  interface WciES         wciS0;    // Worker Control and Configuration
  interface WmemiES16B    wmemiS0;  // The Wmemi slave interface provided to the application
  interface DDR3_16       dram;     // The interface to the DRAM pins
endinterface

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDramServer_s4#(parameter Bool hasDebugLogic, Clock sys0_clk, Reset sys0_rstn) (DramServer_s4Ifc);

  // On the Altera alst4 board, the default on sysclk0 is 100 MHz - it can be programmed by USB
  // The jitter is uncertain. So here we take the questionable approach of using the PCIe-derrived 125 MHz
  // as the reference clock to the DRAM controller -
//Clock                            clk125                     <-  exposeCurrentClock;
//Reset                            rst125                     <-  exposeCurrentReset;
  DramControllerUiIfc              memc                       <- mkDramControllerUi(sys0_clk, sys0_rstn);
//DramControllerUiIfc              memc                       <- mkDramControllerUi(clk125, rst125);

  WciESlaveIfc                     wci                        <- mkWciESlave;
  WmemiSlaveIfc#(36,12,128,16)     wmemi                      <- mkWmemiSlave; 
  Reg#(Bit#(32))                   dramCtrl                   <- mkReg(0);
  Clock                            uclk                       =  memc.uclk;
  Reset                            urst_n                     =  memc.urst_n;
  ReadOnly#(Bool)                  memIsReset                 <- isResetAsserted(clocked_by uclk, reset_by urst_n);
  SyncBitIfc#(Bit#(1))             memIsResetCC               <- mkSyncBitToCC(uclk, urst_n);
  SyncBitIfc#(Bit#(1))             initDone                   <- mkSyncBitToCC(uclk, urst_n);
  SyncBitIfc#(Bit#(1))             calSuccess                 <- mkSyncBitToCC(uclk, urst_n);
  SyncBitIfc#(Bit#(1))             calFail                    <- mkSyncBitToCC(uclk, urst_n);
  Reg#(Bit#(32))                   dbgCtrl                    <- mkReg(0, clocked_by uclk, reset_by urst_n);
  Reg#(Bit#(8))                    respCount                  <- mkReg(0);
  Reg#(Bool)                       splitReadInFlight          <- mkReg(False); 
  FIFOF#(Bit#(2))                  splaF                      <- mkFIFOF;

  Reg#(Bit#(16))                   requestCount               <- mkSyncRegToCC(0, uclk, urst_n);

  Reg#(Bit#(16))                   pReg                       <- mkReg(0);
  Reg#(Bit#(16))                   mReg                       <- mkReg(0);
  Vector#(4,Reg#(Bit#(32)))        wdReg                      <- replicateM(mkReg(0));
  Vector#(4,Reg#(Bit#(32)))        rdReg                      <- replicateM(mkReg(0));

  SyncFIFOIfc#(DramReq16B)         lreqF                      <- mkSyncFIFOFromCC(2, uclk);
  SyncFIFOIfc#(Bit#(128))          lrespF                     <- mkSyncFIFOToCC  (2, uclk, urst_n);

  Accumulator2Ifc#(Int#(8))        wmemiReadInFlight          <- mkAccumulator2;
  Reg#(Bit#(32))                   wmemiWrReq                 <- mkReg(0);
  Reg#(Bit#(32))                   wmemiRdReq                 <- mkReg(0);
  Reg#(Bit#(32))                   wmemiRdResp                <- mkReg(0);

  rule operating_actions (wci.isOperating); wmemi.operate(); endrule

  rule update_memIsReset;   memIsResetCC.send(pack(memIsReset));        endrule
  rule update_initDone;     initDone.send(pack(memc.usr.initDone));     endrule
  rule update_calSuccess;   calSuccess.send(pack(memc.usr.calSuccess)); endrule
  rule update_calFail;      calFail.send(pack(memc.usr.calFail));       endrule

  //(* no_implicit_conditions, fire_when_enabled *)
  rule update_debug (True);
     requestCount              <= memc.reqCount;
  endrule

  mkConnection(toGet(lreqF), memc.usr.request);
  mkConnection(memc.usr.response, toPut(lrespF));

  Bit#(32) dramStatus = extend({respCount, 
    1'h0, memc.usr.clkOk, memIsResetCC.read, calFail.read, calSuccess.read, initDone.read});
  //      654             3                  2             1                0


// Connection to the Wmemi...
rule getRequest (!wci.configWrite && !wci.configRead); // Rule predicate gives PIO config access priority
  let req <- wmemi.req;
  if (req.cmd==WR) begin
      let dh <- wmemi.dh;
      lreqF.enq( DramReq16B {isRead:False, addr:truncate(req.addr), be:dh.dataByteEn, data:dh.data} );
      wmemiWrReq <= wmemiWrReq + 1;
  end else begin
      lreqF.enq( DramReq16B {isRead:True,  addr:truncate(req.addr), be:?,             data:?} );
      wmemiReadInFlight.acc1(1);
      wmemiRdReq <= wmemiRdReq + 1;
  end
endrule

rule getResponse (wmemiReadInFlight>0);
  let rsp = lrespF.first; lrespF.deq();
  wmemiReadInFlight.acc2(-1);
  wmemi.respd(rsp, True);
  wmemiRdResp <= wmemiRdResp + 1;
endrule
   
   
  function Action writeDram4B(Bit#(32) addr, Bit#(4) be, Bit#(32) wdata);
    action
      Vector#(4, Bit#(4))  vbe  = replicate(4'h0);
      vbe[addr[3:2]] = be; // place be in the correct 4B within 16B words
      Vector#(4, Bit#(32)) wdat = replicate(wdata);
      lreqF.enq( DramReq16B {isRead:False, addr:(addr&32'hFFFF_FFF0), be:pack(vbe), data:pack(wdat)} );
    endaction
  endfunction

  function Action readDram4B(Bit#(32) addr);
    action
      lreqF.enq( DramReq16B {isRead:True, addr:(addr&32'hFFFF_FFF0), be:?, data:?} );
      splaF.enq(addr[3:2]); // enq which 4B of 16B we need to select when response arrives
    endaction
  endfunction

  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, advance_response" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, advance_response" *)

  rule advance_response (!wci.configWrite && wmemiReadInFlight==0);
    let rsp = lrespF.first; lrespF.deq();
    Vector#(4, Bit#(32)) rdVect = unpack(rsp);
    for(Integer i=0;i<4;i=i+1) rdReg[i] <= rdVect[i];
    if (splitReadInFlight) begin
      let p = splaF.first; splaF.deq();
      wci.respPut.put(WciResp{resp:DVA, data:rdVect[p]}); // put the correct 4B DW from 16B return
      splitReadInFlight <= False;
    end
    respCount <= respCount + 1;
  endrule

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
   if (wciReq.addr[19]==0) begin
     case (wciReq.addr[7:0]) matches
       'h04 : dramCtrl  <= unpack(wciReq.data);
       'h50 : pReg      <= truncate(wciReq.data);
       'h54 : lreqF.enq(DramReq16B {isRead:False, addr:wciReq.data, be:mReg, data:pack(readVReg(wdReg))}); // Write Req
       'h58 : lreqF.enq(DramReq16B {isRead:True,  addr:wciReq.data, be:mReg, data:pack(readVReg(wdReg))}); // Read  Req
       'h5C : mReg      <= truncate(wciReq.data);
       'h60 : wdReg[0]  <= wciReq.data;
       'h64 : wdReg[1]  <= wciReq.data;
       'h68 : wdReg[2]  <= wciReq.data;
       'h6C : wdReg[3]  <= wciReq.data;
       'h80 : rdReg[0]  <= wciReq.data;
       'h84 : rdReg[1]  <= wciReq.data;
       'h88 : rdReg[2]  <= wciReq.data;
       'h8C : rdReg[3]  <= wciReq.data;
     endcase
   end else begin
       writeDram4B(truncate({pReg,wciReq.addr[18:2],2'b0}), 4'hF, wciReq.data);
   end
     //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule

  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   Bool splitRead = False;
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   if (wciReq.addr[19]==0) begin
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = dramStatus;
       'h04 : rdat = pack(dramCtrl);
       'h48 : rdat = extend(requestCount);
       'h4C : rdat = 32'hc0de_4002; // code-4002 magic cookie
       'h50 : rdat = extend(pReg);
       'h5C : rdat = extend(mReg);
       'h60 : rdat = wdReg[0];
       'h64 : rdat = wdReg[1];
       'h68 : rdat = wdReg[2];
       'h6C : rdat = wdReg[3];
       'h80 : rdat = rdReg[0];
       'h84 : rdat = rdReg[1];
       'h88 : rdat = rdReg[2];
       'h8C : rdat = rdReg[3];
      endcase
    end else begin
       readDram4B(truncate({pReg,wciReq.addr[18:2],2'b0}));
       splitRead = True;
    end
     //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
     if (!splitRead)wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
     else splitReadInFlight <= True;
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
    //TODO: DRAM Auto Initialize here
    wmemiReadInFlight.load(0);
    wci.ctlAck;
    $display("[%0d]: %m: Starting DramWorker dramCtrl:%0x", $time, dramCtrl);
  endrule
  
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  WmemiES16B wmemi_Es <- mkWmemiStoES(wmemi.slv);

  interface WciES       wciS0    = wci.slv;
  interface WmemiES16B  wmemiS0  = wmemi_Es;
  interface DDR3_16     dram     = memc.dram;  // 16b DDR3 interface to pins

endmodule : mkDramServer_s4

endpackage : DramServer_s4

