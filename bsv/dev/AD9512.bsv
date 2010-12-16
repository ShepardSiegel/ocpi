// AD9512.bsv
// Copyright (c) 2009,2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package AD9512;

import SPICore::*;

import Clocks::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import StmtFSM::*;
import Vector::*;

// The interface declaration of the device-package-pins for the AD9512 device...
interface AD9512Ifc;
  (*always_ready*) method Clock   adx_sclk;
  (*always_ready*) method Clock   adx_sclkn;
  (*always_ready*) method Reset   adx_srst;
  (*always_ready*) method Bit#(1) adx_csb;
  (*always_ready*) method Bit#(1) adx_sdo;
  (*always_ready, always_enabled*) method Action adx_sdi (Bit#(1) arg);
  (*always_ready*) method Bit#(1) adx_funct;
  (*always_ready, always_enabled*) method Action adx_status (Bit#(1) arg);
endinterface: AD9512Ifc

interface SpiAdxIfc;
  method Put#(SpiReq)  req;
  method Get#(Bit#(8)) resp;
  method Action doInitSeq;
  method Bool   isInited;
  interface AD9512Ifc adx;
endinterface: SpiAdxIfc

// Specialized SPI core, for AD9512 Clock controller...
module mkSpiAdx (SpiAdxIfc);
  SpiIfc         spiI     <-  mkSpi(True);
  Reg#(Bit#(4))  iState   <-  mkReg(0);

  // AD AD9512 reset and initialization sequence...
  Stmt iseq = 
  seq
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h45, wdata:8'h02}); // powerdown CLK1, enable CLK2
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h4B, wdata:8'h80}); // Bypass Divider 0
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h4D, wdata:8'h80}); // Bypass Divider 1
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h4F, wdata:8'h80}); // Bypass Divider 2
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h51, wdata:8'h80}); // Bypass Divider 3
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h53, wdata:8'h80}); // Bypass Divider 4
    spiI.req.put(SpiReq {rdCmd:False, addr:8'h5A, wdata:8'h01}); // Update Registers
  endseq;
  FSM iseqFsm <- mkFSM(iseq);

  interface req  = spiI.req;
  interface resp = spiI.resp;
  method Action doInitSeq = iseqFsm.start;
  method Bool   isInited  = iseqFsm.done;
  interface AD9512Ifc adx;
    method Clock   adx_sclk  = spiI.sclk;
    method Clock   adx_sclkn = spiI.sclkn;
    method Reset   adx_srst  = spiI.srst;
    method Bit#(1) adx_csb   = spiI.csb;
    method Bit#(1) adx_sdo   = spiI.sdo;
    method Action  adx_sdi (Bit#(1) arg); action spiI.sdi(arg); endaction endmethod
    method Bit#(1) adx_funct = 1'b1;       // Drive High, default function is low for RESETB
    method Action  adx_status (Bit#(1) arg) = noAction; 
  endinterface
endmodule: mkSpiAdx

endpackage: AD9512
