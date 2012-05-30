// ICAP.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package ICAP;

import Vector::*;
import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import FIFOF::*;	
import GetPut::*;

(* always_ready, always_enabled *)
interface ICAP;
   method Bit#(32)   configOut;
   method Bool       busy;
   method Action     configIn(Bit#(32) i);
   method Action     rdwrb(Bool i);     // True Read, False For Write
   method Action     csb(Bool i);       // False for Chip Select
endinterface: ICAP

import "BVI" ICAP_SPARTAN3A =
module vICAP_S3A (ICAP);

   default_clock clk(CLK);
   default_reset no_reset;

   method O         configOut;
   method BUSY      busy;
   method configIn (I)      enable((*inhigh*)en0);
   method rdwrb    (WRITE)  enable((*inhigh*)en1);
   method csb      (CE)     enable((*inhigh*)en2);
      
   schedule (configOut, busy, configIn, rdwrb, csb) CF (configOut, busy, configIn, rdwrb, csb); 
endmodule: vICAP_S3A

import "BVI" ICAP_VIRTEX5 =
module vICAP_V5 (ICAP);

   default_clock clk(CLK);
   default_reset no_reset;

   parameter ICAP_WIDTH  = "X32";
   
   method O         configOut;
   method BUSY      busy;
   method configIn (I)      enable((*inhigh*)en0);
   method rdwrb    (WRITE)  enable((*inhigh*)en1);
   method csb      (CE)     enable((*inhigh*)en2);
      
   schedule (configOut, busy, configIn, rdwrb, csb) CF (configOut, busy, configIn, rdwrb, csb); 
endmodule: vICAP_V5

import "BVI" ICAP_VIRTEX6 =
module vICAP_V6 (ICAP);

   default_clock clk(CLK);
   default_reset no_reset;

   parameter ICAP_WIDTH  = "X32";
   
   method O         configOut;
   method BUSY      busy;
   method configIn (I)      enable((*inhigh*)en0);
   method rdwrb    (RDWRB)  enable((*inhigh*)en1);
   method csb      (CSB)    enable((*inhigh*)en2);
      
   schedule (configOut, busy, configIn, rdwrb, csb) CF (configOut, busy, configIn, rdwrb, csb); 
endmodule: vICAP_V6

interface ICAPIfc;
  method Action configWriteEnable (Bool e);
  method Action configReadEnable  (Bool e);
  method Put#(Bit#(32)) configIn;
  method Get#(Bit#(32)) configOut;
  method Bit#(32) dwInCount;
  method Bit#(32) dwOutCount;
endinterface

// The Xilinx SelectMAP BitSwap reverses the position of bits in Bytes, while leaving Bytes positionally intact...
function Bit#(n) reverseBitsInBytes(Bit#(n) a) provisos (Mul#(8,b,n));
  Vector#(b, Bit#(8)) vBytes = unpack(a);
  vBytes = map(reverseBits, vBytes);
  return pack(vBytes);
endfunction

module mkICAP#(String icapPrim) (ICAPIfc);

/*
  ICAP  icap = ?;
  case (icapPrim)
    "S3A"    :  icap <- vICAP_S3A;
    "V5"     :  icap <- vICAP_V5;
    "V6"     :  icap <- vICAP_V6;
    default  :  icap <- vICAP_V6;
  endcase
*/
`ifdef SPARTAN
  ICAP icap <- vICAP_S3A;
`else
  ICAP icap <- vICAP_V6;
`endif

  FIFOF#(Bit#(32))     cinF      <- mkFIFOF;
  FIFOF#(Bit#(32))     coutF     <- mkFIFOF;
  Reg#(Bool)           icapCs    <- mkDReg(False);  // default deselected
  Reg#(Bool)           icapRd    <- mkDReg(False);  // default write
  Reg#(Bit#(32))       icapIn    <- mkDReg('1);     // default '1
  Reg#(Bit#(32))       icapOut   <- mkDReg('1);     // default '1
  Reg#(Bool)           icapBusy  <- mkDReg(True);   // default busy
  Wire#(Bool)          cwe       <- mkDWire(False);
  Wire#(Bool)          cre       <- mkDWire(False);
  Reg#(Bit#(32))       inCount   <- mkReg(0);
  Reg#(Bit#(32))       outCount  <- mkReg(0);


  // Rank of pipeline regsiters surrounds ICAP for FUD about sync timing paramaters...
  rule drive_icap_control;
    icap.csb         (!icapCs);
    icap.rdwrb        (icapRd);
    icap.configIn     (icapIn);
    icapBusy <=       (icap.busy);
    icapOut  <=        icap.configOut;
  endrule

  (* mutually_exclusive = "write_configration_data, read_configuration_data" *)
  
  rule write_configration_data (cwe && !cre);
    icapCs <= True;
    icapRd <= False;
    icapIn <= reverseBitsInBytes(cinF.first);
    cinF.deq;
    inCount <= inCount + 1;
  endrule

  rule read_configuration_data (cre && !cwe);
    icapCs <= True;
    icapRd <= True;
    if (!icapBusy) begin
      coutF.enq(reverseBitsInBytes(icapOut));
      outCount <= outCount + 1;
    end
  endrule

  method Action configWriteEnable (Bool e); cwe <= e; endmethod
  method Action configReadEnable  (Bool e); cre <= e; endmethod
  method Put#(Bit#(32)) configIn  = toPut(cinF);
  method Get#(Bit#(32)) configOut = toGet(coutF);
  method Bit#(32) dwInCount = inCount;
  method Bit#(32) dwOutCount = outCount;

endmodule

endpackage: ICAP
