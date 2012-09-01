// QBGMAC.bsv - User-facing Quad Byte (QABS) 1Gb Ethernet MAC  Wrapper
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package QBGMAC;

import CounterM          ::*;
import GMAC              ::*;
import E8023             ::*;

import Clocks            ::*;
import Connectable       ::*;
import CRC               ::*;
import DReg              ::*;
import FIFO              ::*;
import FIFOF             ::*;
import GetPut            ::*;
import Vector            ::*;


// Interfaces...


interface QBGMACIfc;
  interface GMII_RS     gmii;
  interface Clock       rxclkBnd; 
//interface Reset       gmii_rstn;
  interface Get#(QABS)  rx;
  interface Put#(QABS)  tx;
  method Action         rxOperate;
  method Action         txOperate;
  method Bool           rxOverFlow;
  method Bool           txUnderFlow;
  method Bool           phyInterrupt;
endinterface: QBGMACIfc

(* synthesize *)
module mkQBGMAC#(Clock rxClk, Clock txClk, Reset gmRst)(QBGMACIfc);
  GMACIfc                     gmac                <-  mkGMAC(rxClk, txClk, clocked_by txClk, reset_by gmRst);

endmodule: mkQBGMAC 

// ABS-QABS Conversion Modules...

interface ABS2QABSIfc;
  interface Put#(ABS);
  interface Get#(QABS);
endinterface

module mkABS2QABS (ABS2QABSIfc);
  FIFO#(ABS)          inF   <-  mkFIFO;
  FIFO#(QABS)         outF  <-  mkFIFO;
  Reg#(Vector#(3,ABS) sr    <- mkRegU; 

  rule ingress_abs;
    let b = inF.first; inF.deq;

  endrule

  interface Put#(ABS)  = toPut(inF);
  interface Get#(QABS) = toGet(outF);
endmodule

interface QABS2ABSIfc;
  interface Put#(QABS);
  interface Get#(ABS);
endinterface

module mkQABS2ABS (QABS2ABSIfc);
  FIFO#(QABS)  inF   <-  mkFIFO;
  FIFO#(ABS)   outF  <-  mkFIFO;

  interface Put#(QABS) = toPut(inF);
  interface Get#(ABS)  = toGet(outF);
endmodule


endpackage: QBGMAC
