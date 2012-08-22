// PWrk_n210.bsv - Platform Worker for the n210 Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PWrk_n210;

import OCWip          ::*;
import I2C            ::*;
import SPIFlash       ::*;
import Config         ::*;

import Clocks         ::*;
import Connectable    ::*;
import FIFO           ::*;
import FIFOF          ::*;
import Vector         ::*;
import GetPut         ::*;

export PWrk_n210      ::*;
export I2C            ::*;
export SPIFlash       ::*;

interface PWrk_n210Ifc;
  method    Bit#(48)        macAddr;  // 48-bit MAC address from I2C devaddr0; EEPROM[07:02] 6B
  interface WciES           wciS0;    // Worker Control and Configuration
  interface I2C_Pins        i2cpad;   // The interface to the I2C EEPROM pins
  interface SPIFLASH_Pads   spipad;   // The interface to the SPI Flash pins
endinterface

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkPWrk_n210#(Reset sys0_rst) (PWrk_n210Ifc);

  I2C                  i2cC                <- mkI2C(416, reset_by sys0_rst); // prescale = 416; // 125/417 = 299 KHz/3=~ 100 KHz i2c clock
  Reg#(Bit#(8))             doGetMAC       <- mkReg(6, reset_by sys0_rst);
  Reg#(Vector#(6,Bit#(8)))  macV           <- mkRegU(  reset_by sys0_rst);             

  WciESlaveIfc         wci                 <- mkWciESlave;
  SPIFlashIfc          flashC              <- mkSPIFlash;
  Reg#(Bit#(32))       flashCtrl           <- mkReg(0);
  Reg#(Bit#(32))       aReg                <- mkReg(0);
  Reg#(Bit#(32))       wdReg               <- mkReg(0);
  Reg#(Bit#(32))       rdReg               <- mkReg(0);
  Reg#(Bool)           splitReadInFlight   <- mkReg(False); 

  rule read_eeprom (doGetMAC != 0);
    i2cC.user.request(False, 7'b1010_000, 8-doGetMAC, 0); // 1010 control code ahead of 3b slave_addr
    doGetMAC <= doGetMAC - 1;
  endrule

  rule response_eeprom;
    let b <- i2cC.user.response;
    macV <= shiftInAt0(macV, b);
  endrule




  Bit#(32) flashStatus = extend({1'b1, pack(flashC.user.waitBit)});

  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, advance_response" *)
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
     'h14 : flashC.user.request.put(SPIFlashReq {isRead:False, addr:truncate(aReg), data:truncate(wdReg)} ); // Write Req
     'h18 : flashC.user.request.put(SPIFlashReq {isRead:True,  addr:truncate(aReg), data:?}               ); // Read  Req
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
      flashC.user.request.put(SPIFlashReq {isRead:True,  addr:{wciReq.addr[21:2]}, data:?});
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

  method    Bit#(48)      macAddr = pack(macV);
  interface Wci_s         wciS0   = wci.slv;
  interface I2C_Pins      i2cpad  = i2cC.i2c;
  interface SPIFLASH_Pads spipad  = flashC.pads; 

endmodule : mkPWrk_n210

endpackage : PWrk_n210

