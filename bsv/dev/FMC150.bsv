// FMC150.bsv - A Device Worker for the 4DSP FMC150 FMC Module
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package FMC150;

import OCWip       ::*;
import SPICore4    ::*;
import FreqCounter ::*;
import TimeService ::*;
import CounterM    ::*;

import Connectable ::*;
import Clocks      ::*;
import DReg        ::*;
import FIFO        ::*;	
import FIFOF       ::*;	
import GetPut      ::*;
import StmtFSM     ::*;
import Vector      ::*;
import XilinxCells ::*;
import XilinxExtra ::*;

(* always_enabled, always_ready *)
interface FMC150_PINS;
  method Bit#(1) cdc_rstn;
  method Bit#(1) cdc_pdn;
  method Bit#(1) mon_rstn;
  method Bit#(1) mon_intn;
  method Bit#(1) adc_rstn;
  method Action  cdc_clkm2c_p (Bit#(1) i);
  method Action  cdc_clkm2c_n (Bit#(1) i);
  method Action  cdc_pllstat  (Bit#(1) i);
  method Bit#(1) cdc_refen;
endinterface

interface FMC150Ifc;
  interface WciES       wciS0;
  interface SPI4Pads    pads;
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFMC150#(parameter Bool hasDebugLogic) (FMC150Ifc);
  WciESlaveIfc      wci                <- mkWciESlave;
  Spi4Ifc           spi                <- mkSpi4;
  Reg#(Bool)        splitReadInFlight  <- mkReg(False);


(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, spi_response" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, spi_response" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[11:10]) matches
     'b00 : spi.req.put(Spi4Req{dev:CDC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
     'b01 : spi.req.put(Spi4Req{dev:DAC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
     'b10 : spi.req.put(Spi4Req{dev:ADC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
     'b11 : spi.req.put(Spi4Req{dev:ADC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule spi_response;
  let d32 <- spi.resp.get;
  wci.respPut.put(WciResp{resp:DVA, data:d32});
  splitReadInFlight <= False;
endrule

rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
 Bool splitRead = False;
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[11:10]) matches
     'b00 : begin spi.req.put(Spi4Req{dev:CDC, isRead:True, addr:extend(wciReq.addr[9:2]), data:'0}); splitRead=True; end
     'b01 : begin spi.req.put(Spi4Req{dev:DAC, isRead:True, addr:extend(wciReq.addr[9:2]), data:'0}); splitRead=True; end
     'b10 : begin spi.req.put(Spi4Req{dev:ADC, isRead:True, addr:extend(wciReq.addr[9:2]), data:'0}); splitRead=True; end
     'b11 : begin spi.req.put(Spi4Req{dev:MON, isRead:True, addr:extend(wciReq.addr[9:2]), data:'0}); splitRead=True; end
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
   else splitReadInFlight <= True;
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  interface Wci_s wciS0   = wci.slv;
  interface SPI4Pads pads = spi.pads;

endmodule

endpackage
