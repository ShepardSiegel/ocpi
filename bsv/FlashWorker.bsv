// FlashWorker.bsv
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package FlashWorker;

import OCWip::*;
import Flash::*;
import Config::*;
import SRLFIFO ::*;

import Clocks::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import GetPut::*;

export Flash::*;
export FlashWorker::*;

interface FlashWorkerIfc;
  interface Wci_s#(20)       wci_s;    // Worker Control and Configuration
  interface FLASH_IO#(24,16) flash;    // The interface to the Flash pins
endinterface

(*synthesize*)
module mkFlashWorker (FlashWorkerIfc);

  WciSlaveIfc #(20)            wci         <- mkWciSlave;
  FlashControllerIfc#(24,16)   flashC      <- mkFlashController;
  Reg#(Bit#(32))               flashCtrl   <- mkReg(0);
  Reg#(Bit#(32))               aReg        <- mkReg(0);
  Reg#(Bit#(32))               wdReg       <- mkReg(0);
  Reg#(Bit#(32))               rdReg       <- mkReg(0);
  Reg#(Bool)                   splitReadInFlight   <- mkReg(False); 

  Bit#(32) flashStatus = extend({1'b1, pack(flashC.user.waitBit)});

  (* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd, advance_response" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, advance_response" *)

  rule advance_response (!wci.configWrite);
    let rsp <- flashC.user.response.get;
    rdReg <= extend(rsp);
    if (splitReadInFlight) begin
      wci.respPut.put(WciResp{resp:DVA, data:extend(rsp)});
      splitReadInFlight <= False;
    end
  endrule

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
    let wciReq <- wci.reqGet.get;
    case (wciReq.addr[7:0]) matches
     'h04 : flashCtrl  <= unpack(wciReq.data);
     'h08 : aReg       <= unpack(wciReq.data);
     'h0C : wdReg      <= unpack(wciReq.data);
     'h10 : rdReg      <= unpack(wciReq.data);
     'h14 : flashC.user.request.put(FlashReq {isRead:False, addr:truncate(aReg), data:truncate(wdReg)} ); // Write Req
     'h18 : flashC.user.request.put(FlashReq {isRead:True,  addr:truncate(aReg), data:?}               ); // Read  Req
    endcase
    //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
    wci.respPut.put(wciOKResponse); // write response
  endrule

  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
    Bool splitRead = False;
    let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
    if (wciReq.addr[19]==0) begin
      case (wciReq.addr[7:0]) matches
       'h00 : rdat = flashStatus;
       'h04 : rdat = flashCtrl;
       'h08 : rdat = aReg;
       'h0C : rdat = wdReg;
       'h10 : rdat = rdReg;
      endcase
    end else begin
      flashC.user.request.put(FlashReq {isRead:True,  addr:{5'h0,wciReq.addr[18:2],2'b0}, data:?});
      splitRead = True;
    end
    //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
    if (!splitRead)wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
    else splitReadInFlight <= True;
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
    wci.ctlAck;
    $display("[%0d]: %m: Starting flashWorker flashCtrl:%0x", $time, flashCtrl);
  endrule
  
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  interface Wci_s      wci_s   = wci.slv;
  interface FLASH      flash   = flashC.flash; 

endmodule : mkFlashWorker

endpackage : FlashWorker

