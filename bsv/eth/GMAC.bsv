// GMAC.bsv - 1Gb Ethernet MAC 
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// See IEEE 803.3-2008 section 35 Reconciliation Sublayer (RS) and Gigabit Media Independent Interface (GMII)

package GMAC;

import CounterM          ::*;

import Clocks            ::*;
import Connectable       ::*;
import CRC               ::*;
import FIFO              ::*;
import GetPut            ::*;
import Vector            ::*;

// Types...

typeded Bit#(8)   Octet;
typedef Bit#(32)  IPAddress;
typedef Bit#(48)  MACAddress;

typedef enum {
  EofNone, EofGood, EofBad
} EofType deriving (Bits, Eq);

typedef enum {
  PREAMBLE = 8'h55,
  SFD      = 8'hD5
} EthernetOctets deriving (Bits, Eq);


typedef union tagged {
  Bit#(8) FirstData;
  Bit#(8) Data;
  Bit#(8) LastData;
} EthernetData deriving (Bits, Eq);

// Functions...

function Bit#(8) getData(EthernetData x);
  case(x) matches
    tagged FirstData .z: return(z);
    tagged      Data .z: return(z);
    tagged  LastData .z: return(z);
  endcase
endfunction

function Bool matchesFirst(EthernetData x);
  case(x) matches
    tagged FirstData .*: return True;
    tagged      Data .*: return False;
    tagged  LastData .*: return False;
  endcase
endfunction
   
function Bool matchesData(EthernetData x);
  case(x) matches
    tagged FirstData .*: return False;
    tagged      Data .*: return True;
    tagged  LastData .*: return False;
  endcase
endfunction
   
function Bool matchesLast(EthernetData x);
  case(x) matches
    tagged FirstData .*: return False;
    tagged      Data .*: return False;
    tagged  LastData .*: return True;
  endcase
endfunction
   
// Interfaces...

(* always_enabled, always_ready *)
interface GMII_RX_RS;
  method    Action      rxd  (Bit#(8) i);
  method    Action      rx_dv(Bit#(1) i);
  method    Action      rx_er(Bit#(1) i);
endinterface GMII_RX_RS;

(* always_enabled, always_ready *)
interface GMII_RX_PCS;
  method    Bit#(8)     rxd;
  method    Bit#(1)     rx_dv;
  method    Bit#(1)     rx_er;
endinterface GMII_RX_PCS;

(* always_enabled, always_ready *)
interface GMII_TX_RS;
  interface Clock       tx_clk;
  method    Bit#(8)     txd;
  method    Bit#(1)     tx_en;
  method    Bit#(1)     tx_er;
endinterface GMII_TX_RS;

(* always_enabled, always_ready *)
interface GMII_TX_PCS;
  method    Action      txd  (Bit#(8) i);
  method    Action      tx_en(Bit#(1) i);
  method    Action      tx_er(Bit#(1) i);
endinterface GMII_TX_PCS;

(* always_enabled, always_ready *)
interface GMII_RS;  // GMII_RS is the bottom of the MAC facing the top of the PHY...
  interface GMII_RX_RS  rx;
  interface GMII_TX_RS  tx;
  method    Action      col  (Bit#(1) i);
  method    Action      crs  (Bit#(1) i);
endinterface: GMII_RS

(* always_enabled, always_ready *)
interface GMII_PCS; // GMII_PCS is the top of the PHY facing the MAC...
  interface GMII_RX_PCS rx;
  interface GMII_TX_PCS tx;
  method    Bit#(1)     col
  method    Bit#(1)     crs
endinterface: GMII_PCS

(* always_enabled, always_ready *)
interface MAC_RX;
  method    Bit#(8)     data;
  method    Bool        data_valid;
  method    Bool        good_frame;
  method    Bool        bad_frame;
  method    Bool        frame_drop;
endinterface: MAC_RX

(* always_enabled, always_ready *)
interface RX_MAC;
  method    Action      data(Bit#(8) i);
  method    Action      data_valid(Bool i);
  method    Action      good_frame(Bool i);
  method    Action      bad_frame (Bool i);
  method    Action      frame_drop(Bool i);
endinterface: RX_MAC

(* always_enabled, always_ready *)
interface MAC_TX;
  interface Clock       clk;
  method    Action      data(Bit#(8) i);
  method    Action      data_valid(Bool i);
  method    Bool        ack;
  method    Action      first_byte(Bool i);
  method    Action      underrun  (Bool i);
  method    Bool        collision;
  method    Bool        retransmit;
  method    Action      ifg_delay(Bit#(8) i);
endinterface: MAC_TX   

(* always_enabled, always_ready *)
interface TX_MAC;
  method    Bit#(8)     data;
  method    Bool        data_valid;
  method    Action      ack(Bool i);
  method    Bool        first_byte;
  method    Bool        underrun;
  method    Action      collision (Bool i);
  method    Action      retransmit(Bool i);
  method    Bit#(8)     ifg_delay;
endinterface: TX_MAC
  
interface GMAC;
  interface GMII_RS     gmii;
  interface MAC_RX      rx;
  interface MAC_TX      tx;
endinterface: GMAC

interface RS_RX_MAC;
  Bit#(8)
  

interface RxRSIfc;
  interface GMII_RX_RS gmii;
endinterface


// Rx Reconciliation Sublayer (RS)
// This module accepts the RX data from the PHY and segments it into frames
// It will remove the preamble and SFD
// It will pass frames starting with the Destination Address (DA)
// It will end a frame with either an eofGood (if the FCS matches) or an eofBad (if it doesnt)
module mkRxRS (RxRSIfc);
  Reg#(Bit#(8))            rxData       <- mkRegU;
  Reg#(Bool)               rxDV         <- mkReg(False);
  Reg#(Bool)               rxER         <- mkReg(False);
  Reg#(UInt#(4))           preambleCnt  <- mkCounterSat(15);
  Reg#(Bool)               rxAvtive     <- mkReg(False);
  Reg#(Vector#(4,Bit#(8))) rxPipe       <- mkRegU;
  CRC#(32)                 crc          <- mkCRC32;
  Reg#(EofType)            eof          <- mkDReg(EofNone);
  FIFO#(EthernetFrame)     rxF          <- mkFIFO;

  (* fire_when_enabled, no_implicit_conditions *)
  rule gmii_rx_ingress_advance (rxDV);
     rxPipe <= shiftInAt0(rxPipe, rxData);                // Build up our 32b FCS candidate
     if (rxData == PREAMBLE)           preambleCnt.inc;   // Count preamble octets
     if (preambleCnt>6 && rxData==SFD) rxActive <= True;  // Detect Start of Frame Delimiter
     if (rxActive) crc.add(rxData);                       // Update CRC starting with DA (after SFD)
  endrule

  (* fire_when_enabled, no_implicit_conditions *)
  rule gmii_rx_ingress_noadvance (!rxDV);
    let fcs <- crc.complete;
    if (rxActive) eof <= (fcs == unpack(pack(rxPipe))) : eofGood : eofBad;
    preambleCnt.load(0);  // Reset the preamble counter
    rxActive <= False;    // Clear rxActive
  endrule

  rule gmii_rx_ingress_enqueue;
    EthernetData d = ?;
    if   (rxActive && !rxActiveD) d = tagged FirsData rxData;
    else (rxActive && rxDV)       d = tagged Data     rxData
    else                          d = tagged LastData rxData;
    rfF.enq(d);
  endrule



  interface GMII_RX_RS gmii;
    method Action rxd   (x) = rxData._write(x);
    method Action rx_dv (x) = rxDV._write(unpack(x));
    method Action rx_er (x) = rxER._write(unpack(x));
  endinterface GMII_RX_RS;

  interface Get ingress = toGet(rxF);

endmodule: mkRxRS

endpackage: GMAC
