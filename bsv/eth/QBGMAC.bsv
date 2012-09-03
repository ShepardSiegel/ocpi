// QBGMAC.bsv - User-facing Quad Byte (QABS) 1Gb Ethernet MAC  Wrapper
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module wraps the GMAC with ABS logic at 125 MHz to QABS logic in the upper layer.
// The utility of this module is to handle as much of the insulation of the 125 MHz GbE clock as possible.
// Upper layer devices (e.g. GbeQABS) can then more-convieniently communicate with the GMAC's 125 MHz features.

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
  Reg#(Bool)           rxOperD <- mkDReg(False);
  Reg#(Bool)           txOperD <- mkDReg(False);
  SyncBitIfc#(Bit#(1)) rxOper  <- mkSyncBitFromCC(txClk);
  SyncBitIfc#(Bit#(1)) txOper  <- mkSyncBitFromCC(txClk);
  ABS2QABSIfc          rxfun   <- mkABS2QABS(clocked_by txClk, reset_by gmRst);
  QABS2ABSIfc          txfun   <- mkQABS2ABS(clocked_by txClk, reset_by gmRst);
  SyncFIFOIfc#(QABS)   rxF     <- mkSyncFIFOToCC(8, txClk, gmRst);
  SyncBitIfc#(Bit#(1)) ovfBit  <- mkSyncBitToCC(txClk, gmRst);
  SyncFIFOIfc#(QABS)   txF     <- mkSyncFIFOFromCC(8, txClk);
  SyncBitIfc#(Bit#(1)) unfBit  <- mkSyncBitToCC(txClk, gmRst);

  mkConnection(gmac.rx, rxfun.putSerial);     // RX: gmac ABS -> rxFunnel QABS (125MHz)x4 -> rxF (50MHz)x4 QABS
  mkConnection(rxfun.getVector, toPut(rxF));

  mkConnection(toGet(txF), txfun.putVector);  // TX: QABS (50MHz)x4 txF (125MHz)x4 -> txFunnel ABS -> gmac
  mkConnection(txfun.getSerial, gmac.tx);

  // Plase the DReg values onto the one bit syncronizers...
  rule cross_rx_Operate; rxOper.send(pack(rxOperD)); endrule
  rule cross_tx_Operate; txOper.send(pack(txOperD)); endrule

  // Pass the operate bits from the CC domain to the rx and tx domains...
  rule connect_rxOperate (unpack(rxOper.read)); gmac.rxOperate; endrule
  rule connect_txOperate (unpack(txOper.read)); gmac.txOperate; endrule

  interface GMII_RS     gmii         = gmac.gmii;
  interface Clock       rxclkBnd     = gmac.rxclkBnd; 
//interface Reset       gmii_rstn;
  interface Get         rx           = toGet(rxF);
  interface Put         tx           = toPut(txF);
  method Action         rxOperate    = rxOperD._write(True);
  method Action         txOperate    = txOperD._write(True);
  method Bool           rxOverFlow   = False; // TODO: pass these up...
  method Bool           txUnderFlow  = False;
  method Bool           phyInterrupt = False;
endmodule: mkQBGMAC 

endpackage: QBGMAC
