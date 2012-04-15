// FMC150.bsv - A Device Worker for the 4DSP FMC150 FMC Module
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package FMC150;

import OCWip       ::*;
import SPICore32   ::*;
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
  interface SPI32Pads   pads;
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkFMC150#(parameter Bool hasDebugLogic,
            //  Clock sys0_clk, Reset sys0_rst,  // 200 MHz Chip Reference
                Clock flp_clk,  Reset flp_rst    // CDC Clock Output U4
                ) (FMC150Ifc);
  WciESlaveIfc          wci                <- mkWciESlave;
  Spi32Ifc              spiCDC             <- mkSpi32;
  Reg#(Bool)            splitReadInFlight  <- mkReg(False);
  FreqCounterIfc#(18)   fcCdc              <- mkFreqCounter(flp_clk); 
  CounterMod#(Bit#(18)) oneKHz             <- mkCounterMod(125000);

rule inc_modcnt; oneKHz.inc(); endrule
rule send_pulse (oneKHz.tc);
  fcCdc.pulse();  // measure KHz
endrule


(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, spi_response" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, spi_response" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[11:10]) matches
     'b00 : spiCDC.req.put(Spi32Req{isRead:False, addr:wciReq.addr[5:2], data:wciReq.data[27:0]});
     //'b01 : spi.req.put(Spi4Req{dev:DAC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
     //'b10 : spi.req.put(Spi4Req{dev:ADC, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
     //'b11 : spi.req.put(Spi4Req{dev:MON, isRead:False, addr:extend(wciReq.addr[9:2]), data:wciReq.data});
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule spi_response;
  let d32 <- spiCDC.resp.get;
  wci.respPut.put(WciResp{resp:DVA, data:extend(d32)});
  splitReadInFlight <= False;
endrule

rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
 Bool splitRead = False;
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[11:10]) matches
     'b00 : begin spiCDC.req.put(Spi32Req{isRead:True, addr:wciReq.addr[5:2], data:'0}); splitRead=True; end
     'b01 : rdat = 32'hbeef_f00d;
     'b10 : rdat = 32'hfeed_face;
     'b11 : rdat = extend(fcCdc);
     //'b11 : begin spi.req.put(Spi4Req{dev:MON, isRead:True, addr:extend(wciReq.addr[9:2]), data:'0}); splitRead=True; end
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
  interface SPI32Pads pads = spiCDC.pads;

endmodule

endpackage
