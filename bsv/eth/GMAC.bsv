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

// Abortable Byte Stream (ABS)...
// The Atomic Rules 2b encoding that is friendly to FIFO width (8b+2b); plus easy for k-LUT decoding
typedef union tagged {
  Bit#(8) ValidNotEOP;  // Any valid data cell so long as it is not the last
  Bit#(8) ValidEOP;     // A valid final data cell in a sequence (could be a sequence of 1); indicates good EOP 
  void    EmptyEOP;     // The end of a sequence has occured, the last data was sent before; indicates good EOP
  void    AbortEOP;     // The sequence has ended with an abort, all data and metadata from this packet is bad
} ABS deriving (Bits, Eq);

function Bool isEOP(ABS x);
  case(x) matches
    tagged ValidNotEOP .*: return False;
    tagged ValidEOP    .*: return True;
    tagged EmptyEOP    .*: return True;
    tagged AbortEOP    .*: return True;
  endcase
endfunction

interface ABSdetSopIfc;
  method Action observe (ABS x);
  method Bool   sop;
endinterface

module mkABSdetSop (ABSdetSopIfc);
  Reg#(Bool) isSOP <- mkReg(True);
  Wire#(ABS) dW    <- mkWire;

  rule update_sop; // Set isSOP after any EOP event...
    isSOP <= (dW matches tagged ValidNotEOP .d ? False : True); 
  endrule

  method Action observe (ABS x) = dW._write(x);
  method Bool sop = isSOP;
endmodule

// Explicit Byte Stream (EBS)...
// Has 4b of unencoded explicit status for abort, empty, sof, and eof...
typedef struct {
  Bool    abort;
  Bool    empty;
  Bool    sof;
  Bool    eof;
  Bit#(8) data;
} EBS deriving (Bits, Eq);


interface EBS2ABSIfc;
  interface Put#(EBS) put;
  interface Get#(ABS) get;
endinterface

module mkEBS2ABS (EBS2ABSIfc);
  FIFO#(EBS) ebsF <- mkFIFO;
  FIFO#(ABS) absF <- mkFIFO;

  // This rule compresses (encodes) the 4b EBS to 2b ABS and consumes empty bubbles...
  rule advance;
    let x = ebsF.first; ebsF.deq;
    case ({pack(x.abort), pack(x.empty), pack(x.eof), pack(x.sof)})
      4'b0000 : absF.enq(tagged ValidNotEOP x.data);  // Body with data
      4'b0001 : absF.enq(tagged ValidNotEOP x.data);  // Head with data
      4'b0010 : absF.enq(tagged ValidEOP    x.data);  // Tail with data 
      4'b0011 : absF.enq(tagged ValidEOP    x.data);  // Single Cycle with data  (1B)
      4'b0100 : noAction;                             // Consume empty bubble
      4'b0101 : noAction;                             // Consume empyy bubble with SOP
      4'b0110 : absF.enq(tagged EmptyEOP);            // Late Good EOP
      4'b0111 : absF.enq(tagged EmptyEOP);            // Single Cycle with no data (0B)
      4'b1000 : absF.enq(tagged AbortEOP);            // Abort has priority over others
      4'b1001 : absF.enq(tagged AbortEOP);
      4'b1010 : absF.enq(tagged AbortEOP);
      4'b1011 : absF.enq(tagged AbortEOP);
      4'b1100 : absF.enq(tagged AbortEOP);
      4'b1101 : absF.enq(tagged AbortEOP);
      4'b1110 : absF.enq(tagged AbortEOP);
      4'b1111 : absF.enq(tagged AbortEOP);
    endcase
  endrule

  interface Put put = toPut(ebsF);
  interface Get get = toGet(absF);
endmodule


interface ABS2EBSIfc;
  interface Put#(ABS)put;
  interface Get#(EBS)get;
endinterface

module mkABS2EBS (ABS2EBSIfc);
  FIFO#(ABS) absF <- mkFIFO;
  FIFO#(EBS) ebsF <- mkFIFO;
  Reg#(Bool)    isSOP <- mkReg(True);

  // This rule expands (decodes) 2b ABS to 4b EBS...
  rule advance;
    let y = absF.first; absF.deq;
    case (y) matches
      tagged ValidNotEOP .z: ebsF.enq(EBS{abort:False, empty:False, sof:isSOP, eof:False, data:z});
      tagged ValidEOP    .z: ebsF.enq(EBS{abort:False, empty:False, sof:isSOP, eof:True,  data:z});
      tagged EmptyEOP      : ebsF.enq(EBS{abort:False, empty:False, sof:isSOP, eof:True,  data:0});
      tagged AbortEOP      : ebsF.enq(EBS{abort:True,  empty:False, sof:isSOP, eof:True,  data:0});
    endcase
    isSOP <= (y matches tagged ValidNotEOP .d ? False : True); 
  endrule

  interface Put put = toPut(absF);
  interface Get get = toGet(ebsF);
endmodule




   
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
  interface Get#(EBS)           rxf;
endinterface

interface TxRSIfc;
  interface Put#(EBS)           txf;
  method    Bool                txUnderflow;
  interface GMII_TX_RS          gmii;
endinterface



// Transmit (Tx) Reconciliation Sublayer (RS)
// This module accepts the TX data from a higher sublevel of the MAC; frames start at the Destination Address (DA)
// It will insert the preamble and SFD, pass the incident frame, and generate and insert the FCS
// If the txF starves in the middle of a frame; that is a TX UNDERFLOW error (txUnderflow)
(* synthesize *)
module mkTxRS (TxRSIfc);
  FIFO#(EBS)               txF          <- mkFIFO;
  Reg#(Bit#(8))            txData       <- mkDReg(0);
  Reg#(Bool)               txDV         <- mkDReg(False);
  Reg#(Bool)               txER         <- mkDReg(False);
  CounterSat#(UInt#(5))    preambleCnt  <- mkCounterSat;
  CounterSat#(UInt#(5))    ifgCnt       <- mkCounterSat;
  CounterSat#(UInt#(12))   lenCnt       <- mkCounterSat;
  Reg#(Bool)               txActive     <- mkReg(False);
  CRC#(32)                 crc          <- mkCRC32;
  CounterSat#(UInt#(12))   crcDbgCnt    <- mkCounterSat;
  Reg#(Bool)               underflow    <- mkDReg(False);
  Reg#(UInt#(3))           emitFCS      <- mkReg(0);
  Reg#(Bool)               doPad        <- mkReg(False);

  (* descending_urgency = "egress_FCS, egress_PAD, egress_EOF, egress_Body, egress_SOF" *)

  rule egress_SOF(txF.first.sof && ifgCnt==0);
    if (preambleCnt<7) begin
      txData <= pack(PREAMBLE);    // 7 Preamble cycles - 8'h55
    end else if (preambleCnt==7) begin
      txData <= pack(SFD);         // 1 SFD cycle - 8'hD5
    end else begin
      let d = txF.first.data;      // 1st Byte of Destination Address
      txData <= d;
      crc.add(d);
      crcDbgCnt.inc;
      txF.deq;
      lenCnt.inc;
    end
    preambleCnt.inc();
    txDV     <= True;
    txActive <= True;
  endrule

  rule egress_Body(txActive && !txF.first.sof && !txF.first.eof);
    let d = txF.first.data;
    txData <= d;
    crc.add(d);
    crcDbgCnt.inc;
    txF.deq;
    lenCnt.inc;
    txDV <= True;
  endrule

  rule egress_EOF(txActive && txF.first.eof);
    let d = txF.first.data;
    txData <= d;
    crc.add(d);
    crcDbgCnt.inc;
    txF.deq;
    lenCnt.inc;
    txDV <= True;
    if (lenCnt>=60) begin // if not padding, advance to emitFCS
      txActive <= False;
      emitFCS <= 4;
    end else doPad <= True;
  endrule

  rule egress_PAD(txActive && doPad);
    let d = pack(PAD);
    txData <= d;
    lenCnt.inc;
    txDV <= True;
    if (lenCnt>=60) begin // when done padding, advance to emitFCS
      txActive <= False;
      emitFCS  <= 4;
      doPad    <= False;
    end
  endrule

  rule egress_FCS(emitFCS!=0);
    Vector#(4,Bit#(8)) fcsV = unpack(crc.result);
    if (emitFCS==4) begin
      $display("[%0d]: %m: TX FCS:%08x from %d elements", $time, pack(fcsV), crcDbgCnt);
      crcDbgCnt.load(0);
    end
    txData <= fcsV[emitFCS-1];
    lenCnt.inc;
    txDV  <= True;
    emitFCS <= emitFCS - 1;
    if (emitFCS==1) begin
      ifgCnt.load(12);
      preambleCnt.load(0);
      lenCnt.load(0);
      crc.clear;
    end
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
  Reg#(Bool)               rxDVD        <- mkReg(False);
  Reg#(Bool)               rxDVD2       <- mkReg(False);
  Reg#(Bool)               rxER         <- mkReg(False);
  CounterSat#(UInt#(4))    preambleCnt  <- mkCounterSat;
  Reg#(Bool)               rxActive     <- mkReg(False);
  Reg#(Vector#(6,Bit#(8))) rxPipe       <- mkRegU;
  Reg#(Vector#(6,Bool))    rxAPipe      <- mkReg(unpack(0));
  CRC#(32)                 crc          <- mkCRC32;
  CounterSat#(UInt#(12))   crcDbgCnt    <- mkCounterSat;
  Reg#(EofType)            eof          <- mkDReg(EofNone);
  FIFO#(EBS)               rxF          <- mkFIFO;
  Reg#(Bool)               isSOF        <- mkReg(True);
  Reg#(Bool)               crcEnd       <- mkReg(False);

  rule dv_reg; rxDVD <= rxDV; rxDVD2 <= rxDVD; endrule

  //(* fire_when_enabled, no_implicit_conditions *)
  rule ingress_advance (rxDV);
     rxPipe  <= shiftInAt0(rxPipe, rxData);                     // Build up our 32b FCS candidate
     rxAPipe <= shiftInAt0(rxAPipe,rxActive);                   // Mark where Active data starts (after SFD)
     if (rxData == pack(PREAMBLE))     preambleCnt.inc;         // Count preamble octets
     if (preambleCnt>6 && rxData==pack(SFD)) rxActive <= True;  // Detect Start of Frame Delimiter
  endrule

  //(* fire_when_enabled, no_implicit_conditions *)
  rule ingress_noadvance (!rxDVD && rxAPipe==unpack(6'h3F) && !crcEnd);  // !rxDV is indication we have FCS
    let fcs <- crc.complete;
    $display("[%0d]: %m: RX FCS:%08x from %d elements", $time, fcs, crcDbgCnt);
    crcDbgCnt.load(0);
    if (rxActive) begin
      Bool fcsMatch = (fcs == unpack(pack(takeAt(0,rxPipe))));
      eof <= (fcsMatch) ? EofGood : EofBad;
      rxF.enq( EBS {
        abort : !fcsMatch,
        empty : False,
        sof   : False,
        eof   : fcsMatch,
        data  : rxPipe[4] });
    end
    crcEnd   <= True;
  endrule

  rule end_frame (crcEnd);
    preambleCnt.load(0);   // Reset the preamble counter
    rxActive <= False;     // Clear rxActive
    isSOF    <= True;      // For next frame
    rxAPipe  <= unpack(0); // Clear shift register
    crcEnd   <= False;
  endrule

  rule crc_capture (rxDV && rxAPipe[3]);
    crc.add(rxPipe[3]); // Update CRC starting with DA (after SFD)
    crcDbgCnt.inc;
  endrule

  rule egress_data (rxDVD && rxAPipe[5]);
    rxF.enq( EBS {
      abort : False,
      empty : False,
      sof   : isSOF,
      eof   : False,
      data  : rxPipe[5] });
    isSOF <= False;    
  endrule

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
