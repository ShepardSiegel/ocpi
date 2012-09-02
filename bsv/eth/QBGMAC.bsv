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
  GMACIfc              gmac    <- mkGMAC(rxClk, txClk, clocked_by txClk, reset_by gmRst);
  ABS2QABSIfc          rxfun   <- mkABS2QABS(clocked_by txClk, reset_by gmRst);
  QABS2ABSIfc          txfun   <- mkQABS2ABS(clocked_by txClk, reset_by gmRst);
  SyncFIFOIfc#(QABS)   rxF     <- mkSyncFIFOToCC(8, txClk, gmRst);
  SyncBitIfc#(Bit#(1)) ovfBit  <- mkSyncBitToCC(txClk, gmRst);
  SyncFIFOIfc#(QABS)   txF     <- mkSyncFIFOFromCC(8, txClk);
  SyncBitIfc#(Bit#(1)) unfBit  <- mkSyncBitToCC(txClk, gmRst);

  mkConnection(gmac.rx, rxfun.putSerial);
  mkConnection(txfun.getSerial, gmac.tx);

  interface GMII_RS     gmii         = gmac.gmii;
  interface Clock       rxclkBnd     = gmac.rxclkBnd; 
//interface Reset       gmii_rstn;
  interface Get         rx           = rxfun.getVector;
  interface Put         tx           = txfun.putVector;
    /*
  method Action         rxOperate;
  method Action         txOperate;
  method Bool           rxOverFlow;
  method Bool           txUnderFlow;
  method Bool           phyInterrupt;
    */
endmodule: mkQBGMAC 

endpackage: QBGMAC
