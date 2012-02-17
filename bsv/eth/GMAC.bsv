// GMAC.bsv - 1Gb Ethernet MAC 
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// See IEEE 803.3-2008 section 35 Reconciliation Sublayer (RS) and Gigabit Media Independent Interface (GMII)

package GMAC;

import CounterM          ::*;

import Clocks            ::*;
import Connectable       ::*;
import CRC               ::*;
import DReg              ::*;
import FIFO              ::*;
import GetPut            ::*;
import Vector            ::*;

// Types...

typedef Bit#(32)  IPAddress;
typedef Bit#(48)  MACAddress;

typedef enum {
  EofNone, EofGood, EofBad
} EofType deriving (Bits, Eq);

typedef enum {
  PAD      = 8'h00,
  PREAMBLE = 8'h55,
  SFD      = 8'hD5
} EthernetOctets deriving (Bits, Eq);

typedef union tagged {
  Bit#(8) DataSOF;      // The first Octect of the Destination Address
  Bit#(8) Data;
  Bit#(8) DataEOFOK;    // On tx;EOF; On rx: EOF with FCS OK
  Bit#(8) DataEOFBAD;   //            0n rx: EOF with FCS Bad
} EthernetFrame deriving (Bits, Eq);

// Functions...

function Bit#(8) getData(EthernetFrame x);
  case(x) matches
    tagged DataSOF    .z: return(z);
    tagged Data       .z: return(z);
    tagged DataEOFOK  .z: return(z);
    tagged DataEOFBAD .z: return(z);
  endcase
endfunction
function Bool matchesSOF(EthernetFrame x);
  case(x) matches
    tagged DataSOF    .*: return True;
    tagged Data       .*: return False;
    tagged DataEOFOK  .*: return False;
    tagged DataEOFBAD .*: return False;
  endcase
endfunction
function Bool matchesData(EthernetFrame x);
  case(x) matches
    tagged DataSOF    .*: return False;
    tagged Data       .*: return True;
    tagged DataEOFOK  .*: return False;
    tagged DataEOFBAD .*: return False;
  endcase
endfunction
function Bool matchesEOFOK(EthernetFrame x);
  case(x) matches
    tagged DataSOF    .*: return False;
    tagged Data       .*: return False;
    tagged DataEOFOK  .*: return True;
    tagged DataEOFBAD .*: return True;
  endcase
endfunction
function Bool matchesEOFBAD(EthernetFrame x);
  case(x) matches
    tagged DataSOF    .*: return False;
    tagged Data       .*: return False;
    tagged DataEOFOK  .*: return False;
    tagged DataEOFBAD .*: return True;
  endcase
endfunction
   
// Interfaces...

(* always_enabled, always_ready *)
interface GMII_RX_RS;
  method    Action      rxd  (Bit#(8) i);
  method    Action      rx_dv(Bit#(1) i);
  method    Action      rx_er(Bit#(1) i);
endinterface: GMII_RX_RS

(* always_enabled, always_ready *)
interface GMII_RX_PCS;
  method    Bit#(8)     rxd;
  method    Bit#(1)     rx_dv;
  method    Bit#(1)     rx_er;
endinterface: GMII_RX_PCS

(* always_enabled, always_ready *)
interface GMII_TX_RS;
//interface Clock       tx_clk;
  method    Bit#(8)     txd;
  method    Bit#(1)     tx_en;
  method    Bit#(1)     tx_er;
endinterface: GMII_TX_RS

(* always_enabled, always_ready *)
interface GMII_TX_PCS;
  method    Action      txd  (Bit#(8) i);
  method    Action      tx_en(Bit#(1) i);
  method    Action      tx_er(Bit#(1) i);
endinterface :GMII_TX_PCS

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
  method    Bit#(1)     col;
  method    Bit#(1)     crs;
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

interface RxRSIfc;
  interface GMII_RX_RS          gmii;
  interface Get#(EthernetFrame) rxf;
endinterface

interface TxRSIfc;
  interface Put#(EthernetFrame) txf;
  method    Bool                txUnderflow;
  interface GMII_TX_RS          gmii;
endinterface



// Transmit (Tx) Reconciliation Sublayer (RS)
// This module accepts the TX data from a higher sublevel of the MAC; frames start at the Destination Address (DA)
// It will insert the preamble and SFD, pass the incident frame, and generate and insert the FCS
// If the txF starves in the middle of a frame; that is a TX UNDERFLOW error (txUnderflow)
(* synthesize *)
module mkTxRS (TxRSIfc);
  FIFO#(EthernetFrame)     txF          <- mkFIFO;
  Reg#(Bit#(8))            txData       <- mkDReg(0);
  Reg#(Bool)               txDV         <- mkDReg(False);
  Reg#(Bool)               txER         <- mkDReg(False);
  CounterSat#(UInt#(4))    preambleCnt  <- mkCounterSat(8);
  CounterSat#(UInt#(5))    ifgCnt       <- mkCounterSat(16);
  CounterSat#(UInt#(12))   lenCnt       <- mkCounterSat(2048);
  Reg#(Bool)               txActive     <- mkReg(False);
  CRC#(32)                 crc          <- mkCRC32;
  Reg#(Bool)               underflow    <- mkDReg(False);
  Reg#(UInt#(3))           emitFCS      <- mkReg(0);

  rule egress_SOF(txF.first matches tagged DataSOF .* &&& ifgCnt==0);
    if (preambleCnt<7) begin
      preambleCnt.inc;
      txData <= pack(PREAMBLE);    // 7 Preamble cycles - 8'h55
    end else if (preambleCnt==7) begin
      preambleCnt.inc;
      txData <= pack(SFD);          // 1 SFD cycle - 8'hD5
    end else begin
      let d = getData(txF.first);   // 1st Byte of Destination Address
      txData <= d;
      crc.add(d);
      txF.deq;
      lenCnt.inc;
      preambleCnt.load(0);
    end
    txDV     <= True;
    txActive <= True;
  endrule

  rule egress_Body(txF.first matches tagged Data .*);
    let d = getData(txF.first);
    txData <= d;
    crc.add(d);
    txF.deq;
    lenCnt.inc;
    txDV <= True;
  endrule

  rule egress_EOF(txF.first matches tagged DataEOFOK .*);
    let d = (lenCnt<60) ? pack(PAD) : getData(txF.first);
    txData <= d;
    crc.add(d);
    lenCnt.inc;
    txDV <= True;
    if (lenCnt>=60) begin // if not padding, advance to emitFCS
      txActive <= False;
      txF.deq;
      emitFCS <= 4;
    end
  endrule

  rule egress_FCS(emitFCS!=0);
    Vector#(4,Bit#(8)) fcsV = unpack(crc.result);
    txData <= fcsV[emitFCS-1];
    lenCnt.inc;
    txDV  <= True;
    emitFCS <= emitFCS - 1;
    if (emitFCS==1) ifgCnt.load(12);
  endrule

  rule ifg_decrementer (ifgCnt!=0);
    ifgCnt.dec;
  endrule

  interface Put txf = toPut(txF);
  method  Bool txUnderflow = underflow;
  interface GMII_TX_RS gmii;
    //interface Clock   tx_clk = Empty;
    method    Bit#(8) txd    = txData;
    method    Bit#(1) tx_en  = pack(txDV);
    method    Bit#(1) tx_er  = pack(txER);
  endinterface: gmii
endmodule: mkTxRS

// Receive (Rx) Reconciliation Sublayer (RS)
// This module accepts the RX data from the PHY and segments it into EthernetFrame frames
// It will remove the preamble and SFD
// It will pass frames starting with the Destination Address (DA)
// It will end a frame with either an eofGood (if the FCS matches) or an eofBad (if it doesnt)
(* synthesize *)
module mkRxRS (RxRSIfc);
  Reg#(Bit#(8))            rxData       <- mkRegU;
  Reg#(Bool)               rxDV         <- mkReg(False);
  Reg#(Bool)               rxER         <- mkReg(False);
  CounterSat#(UInt#(4))    preambleCnt  <- mkCounterSat(15);
  Reg#(Bool)               rxActive     <- mkReg(False);
  Reg#(Vector#(4,Bit#(8))) rxPipe       <- mkRegU;
  CRC#(32)                 crc          <- mkCRC32;
  Reg#(EofType)            eof          <- mkDReg(EofNone);
  FIFO#(EthernetFrame)     rxF          <- mkFIFO;

  (* fire_when_enabled, no_implicit_conditions *)
  rule gmii_rx_ingress_advance (rxDV);
     rxPipe <= shiftInAt0(rxPipe, rxData);                      // Build up our 32b FCS candidate
     if (rxData == pack(PREAMBLE))     preambleCnt.inc;         // Count preamble octets
     if (preambleCnt>6 && rxData==pack(SFD)) rxActive <= True;  // Detect Start of Frame Delimiter
     if (rxActive) crc.add(rxData);                             // Update CRC starting with DA (after SFD)
  endrule

  (* fire_when_enabled, no_implicit_conditions *)
  rule gmii_rx_ingress_noadvance (!rxDV);
    let fcs <- crc.complete;
    if (rxActive) eof <= (fcs == unpack(pack(rxPipe))) ? EofGood : EofBad;
    preambleCnt.load(0);  // Reset the preamble counter
    rxActive <= False;    // Clear rxActive
  endrule

  /*
  rule gmii_rx_ingress_enqueue;
    EthernetFrame d = ?;
    if      (rxActive && !rxActiveD) d = tagged DataSOF  rxData;
    else if (rxActive && rxDV)       d = tagged Data     rxData;
    else                             d = tagged DataEOF  rxData;
    rxF.enq(d);
  endrule
  */

  interface GMII_RX_RS gmii;
    method Action rxd   (x) = rxData._write(x);
    method Action rx_dv (x) = rxDV._write(unpack(x));
    method Action rx_er (x) = rxER._write(unpack(x));
  endinterface: gmii

  interface Get rxf = toGet(rxF);
endmodule: mkRxRS

// Connectable Instances...

instance Connectable#(GMII_TX_RS, GMII_RX_RS); // Loopback TX to RX at RS
  module mkConnection#(GMII_TX_RS t, GMII_RX_RS r)(Empty);
    rule connect_1;
       r.rxd(t.txd);
       r.rx_dv(t.tx_en);
       r.rx_er(t.tx_er);
    endrule
  endmodule
endinstance

endpackage: GMAC
