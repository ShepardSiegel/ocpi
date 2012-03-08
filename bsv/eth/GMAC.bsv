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

import XilinxCells       ::*;
import XilinxExtra       ::*;

// Types...

typedef Bit#(32)  IPAddress;
typedef Bit#(48)  MACAddress;
typedef Bit#(16)  EtherType

typedef struct {
  IPAddress dst;
  IPAddress src;
  EtherType typ;
} IPHeader deriving (Bits, Eq);


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

function Bit#(8) getData(ABS x);
  case(x) matches
    tagged ValidNotEOP .z: return (z);
    tagged ValidEOP    .z: return (z);
    tagged EmptyEOP      : return (?);
    tagged AbortEOP      : return (?);
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
  Bool    abort;  // Highest priority, Abort and EOP
  Bool    empty;  // This cycle contains no data - a bubble
  Bool    sof;    // Explicit SOF (SOP)
  Bool    eof;    // Explicit EOF (EOP)
  Bit#(8) data;   // Data on non-empty and non-abort cycles
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
  Reg#(Bool) isSOP <- mkReg(True);

  // This rule expands (decodes) 2b ABS to 4b EBS...
  rule advance;
    let y = absF.first; absF.deq;
    case (y) matches
      tagged ValidNotEOP .z: ebsF.enq(EBS{abort:False, empty:False, sof:isSOP, eof:False, data:z});
      tagged ValidEOP    .z: ebsF.enq(EBS{abort:False, empty:False, sof:isSOP, eof:True,  data:z});
      tagged EmptyEOP      : ebsF.enq(EBS{abort:False, empty:True,  sof:isSOP, eof:True,  data:0});
      tagged AbortEOP      : ebsF.enq(EBS{abort:True,  empty:False, sof:isSOP, eof:True,  data:0});
    endcase
    isSOP <= (y matches tagged ValidNotEOP .d ? False : True); 
  endrule

  interface Put put = toPut(absF);
  interface Get get = toGet(ebsF);
endmodule

// Interfaces...

(* always_enabled, always_ready *)
interface GMII_RX_RS;                            // FPGA provides to PHY
  method    Action      rxd  (Bit#(8) i);
  method    Action      rx_dv(Bit#(1) i);
  method    Action      rx_er(Bit#(1) i);
endinterface: GMII_RX_RS

(* always_enabled, always_ready *)
interface GMII_RX_PCS;                           // PHY provides to FPGA
  method    Bit#(8)     rxd;
  method    Bit#(1)     rx_dv;
  method    Bit#(1)     rx_er;
endinterface: GMII_RX_PCS

(* always_enabled, always_ready *)
interface GMII_TX_RS;                           // FPGA provides to PHY
  interface Clock       tx_clk;
  method    Bit#(8)     txd;
  method    Bit#(1)     tx_en;
  method    Bit#(1)     tx_er;
endinterface: GMII_TX_RS

(* always_enabled, always_ready *)
interface GMII_TX_PCS;                           // PHY provides to FPGA
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

interface RxRSIfc;
  interface GMII_RX_RS  gmii;
  method    Bool        rxOverFlow;
  interface Get#(ABS)   rx;
endinterface

interface TxRSIfc;
  interface Put#(ABS)   tx;
  method    Bool        txUnderFlow;
  interface GMII_TX_RS  gmii;
endinterface

interface GMACIfc;
  interface GMII_RS     gmii;
  interface Clock       rxclk; 
  interface Reset       gmii_rstn;
  interface Get#(ABS)   rx;
  interface Put#(ABS)   tx;
  method Bool           rxOverFlow;
  method Bool           txUnderFlow;
endinterface: GMACIfc

(* synthesize *)
module mkGMAC#(Clock rxClk, Clock txClk)(GMACIfc);

// GMAC Clocking: In general there are three Clocks used by the GMAC. It can be simplified to two
// in a special case. Those three clocks are:
// i)   The GMII PHY RX Clock. The rxClk is generated by the PHY and is the source-synchronous clock for
//      the GMII_RX signals. This is 125 MHz is recovered from the wire by the PHY. path: wire->PHY->FPGA RX
// ii)  The GMII PHY GTX Clock. The txClk is generated by the FPGA and sent to the PHY. The source for this
//      is a on-card XO that provides a stable 125 MHz to transmit symbols on the wire by the PHY. Note that
//      although logically the "tx" clock, the FPGA XO provides this by GMII to the PHY on the pin "GTX_CLK".
//      The PHY has an output pin "TX_CLK" which is unused in 1Gb operation that this MAC ignores in all cases.
//      path: board 125 MHz source-> FPGA sys1 input -> FPGA TX logic -> PHY GTX_CLK pin -> wire
// iii) There is the Current Clock (CC) default module clock of this mkGMAC module. This can be any frequency
//      equal to or greater than 125 MHz. Buffer sizes and interfame gaps allow a tolerance between the CC 
//      frequency and (i) and (ii) above. At frequencies above 125 MHz TX underrun and RX overrun can only be
//      caused by some external agent (e.g. non-continious WSI on TX, or mid-packet backpressure on RX).
// In some scenarios, the CC can be the same as the (G)TX clk (ii), elliminating the need for a third clock
// Each tx/rx Resolution Sublayer (RS) block handles the clock domain crossing from their tx/rx domain, back to CC

  ClockIODELAY  gmii_rxc_dly     <-  vClockIODELAY("FIXED", 0, "I", clocked_by rxClk);
  Clock         gmii_rx_clk_dly  =   gmii_rxc_dly.delayed;
  Clock         gmii_rx_clk      <-  mkClockBUFIO(clocked_by gmii_rx_clk_dly);
  //TODO: Use gmii_rx_clk to capture rxd,dv,err in IOB FFs
  //TODO: Use txClk to register tx gmii signals in IOB FFs
  Clock         rxClk_BUFR       <-  mkClockBUFR(BUFRParams{bufr_divide:"BYPASS"}, clocked_by gmii_rx_clk_dly);
  Clock         clk              <-  exposeCurrentClock;  // User-Facing CC for the rx/tx methods
  Reset         rst              <-  exposeCurrentReset;
  Reset         phyReset         <-  mkAsyncReset(8, rst, clk); // Hold PHY in reset for 8 *additional* cycles
  RxRSIfc       rxRS             <-  mkRxRSAsync(rxClk_BUFR);
  TxRSIfc       txRS             <-  mkTxRSAsync(txClk);

  interface Get rx = rxRS.rx;
  interface Put tx = txRS.tx;
  method Bool rxOverFlow  = rxRS.rxOverFlow;
  method Bool txUnderFlow = txRS.txUnderFlow;

  interface GMII_RS gmii;                  // PHY-facing GMII Interface to FPGA Pins
    interface GMII_RX_RS  rx = rxRS.gmii;
    interface GMII_TX_RS  tx = txRS.gmii;
    method Action col (Bit#(1) i) = noAction;
    method Action crs (Bit#(1) i) = noAction;
  endinterface
  interface Clock rxclk     = rxClk_BUFR;  // Need to provide this clock at the BSV module bounds (not physically used)
  interface Reset gmii_rstn = phyReset;    // Active-Low reset passed up and out to PHY
endmodule: mkGMAC

// Receive (Rx) Reconciliation Sublayer (RS)
// This module accepts the RX data from the PHY and segments it into ABS frames
// It removes the preamble and SFD; it passes frames starting with the Destination Address (DA)
// It ends frames with either a ValidEOP (if the FCS matches) or an AbortEOP (if it doesnt)
// By adding 5 cycles of latency, this module alligns the fcsMatch with the last payload rxF.enq
// Thus downstream RX logic doesn't have to cope with the waiting to know of good vs. bad.
// This is 40 nS of rcv data latency we could take back someday; but we would still not know fcsMatch any earlier.
module mkRxRSAsync#(Clock rxClk) (RxRSIfc);
  Reset                    rxRst        <- mkAsyncResetFromCR(2, rxClk);
  Reg#(Bit#(8))            rxData       <- mkRegU(          clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               rxDV         <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               rxDVD        <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               rxDVD2       <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               rxER         <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  CounterSat#(UInt#(4))    preambleCnt  <- mkCounterSat(    clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               rxActive     <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  Reg#(Vector#(6,Bit#(8))) rxPipe       <- mkRegU(          clocked_by rxClk, reset_by rxRst);
  Reg#(Vector#(6,Bool))    rxAPipe      <- mkReg(unpack(0), clocked_by rxClk, reset_by rxRst);
  CRC#(32)                 crc          <- mkCRC32(         clocked_by rxClk, reset_by rxRst);
  CounterSat#(UInt#(12))   crcDbgCnt    <- mkCounterSat(    clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               isSOF        <- mkReg(True,      clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               crcEnd       <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  Reg#(Bool)               fullD        <- mkReg(False,     clocked_by rxClk, reset_by rxRst);
  SyncFIFOIfc#(ABS)        rxF          <- mkSyncFIFOToCC(8, rxClk, rxRst); // ~6 cycle fallthrough
  SyncBitIfc#(Bit#(1))     ovfBit       <- mkSyncBitToCC(rxClk, rxRst);

  rule dv_reg; rxDVD <= rxDV; rxDVD2 <= rxDVD; endrule
  rule full_stretch; fullD <= !rxF.notFull; endrule
  Bool rxOverflow = !rxF.notFull || fullD;  // Stretch full detection by 1 cycle so SyncBit must see at least one cycle
  rule overflow_detect; ovfBit.send(pack(rxOverflow)); endrule  // Feed Synchronizer

  rule ingress_advance (rxDV);
     rxPipe  <= shiftInAt0(rxPipe, rxData);                     // Build up our 32b FCS candidate
     rxAPipe <= shiftInAt0(rxAPipe,rxActive);                   // Mark where Active data starts (after SFD)
     if (rxData == pack(PREAMBLE))  preambleCnt.inc;            // Count preamble octets
     if (preambleCnt>6 && rxData==pack(SFD)) rxActive <= True;  // Detect Start of Frame Delimiter
  endrule

  rule ingress_noadvance (!rxDVD && rxAPipe==unpack(6'h3F) && !crcEnd);  // !rxDV is indication we have FCS
    let fcs <- crc.complete;
    $display("[%0d]: %m: RX FCS:%08x from %d elements", $time, fcs, crcDbgCnt);
    crcDbgCnt.load(0);
    if (rxActive) begin
      Bool fcsMatch = (fcs == unpack(pack(reverse(takeAt(0,rxPipe)))));
      rxF.enq( (fcsMatch) ? tagged ValidEOP rxPipe[4] : tagged AbortEOP);  // Either ValidEOP or AbortEOP
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

  rule egress_data  (rxDVD && rxAPipe[5]);
    rxF.enq(tagged ValidNotEOP rxPipe[5]); 
    isSOF <= False;    
  endrule

  interface GMII_RX_RS gmii;
    method Action rxd   (x) = rxData._write(x);
    method Action rx_dv (x) = rxDV._write(unpack(x));
    method Action rx_er (x) = rxER._write(unpack(x));
  endinterface: gmii

  interface Get rx = toGet(rxF);
  method    Bool  rxOverFlow = unpack(ovfBit.read);
endmodule: mkRxRSAsync

// Transmit (Tx) Reconciliation Sublayer (RS)
// This module accepts the TX data from a higher sublevel of the MAC; frames start at the Destination Address (DA)
// It will insert the preamble and SFD, pass the incident frame, and generate and insert the FCS
// If the txF starves in the middle of a frame; that is a TX UNDERFLOW error (txUnderflow)
module mkTxRSAsync#(Clock txClk) (TxRSIfc);
  Reset                    txRst        <- mkAsyncResetFromCR(2, txClk);
  Reg#(Bit#(8))            txData       <- mkDReg(0,        clocked_by txClk, reset_by txRst);
  Reg#(Bool)               txDV         <- mkDReg(False,    clocked_by txClk, reset_by txRst);
  Reg#(Bool)               txER         <- mkDReg(False,    clocked_by txClk, reset_by txRst);
  CounterSat#(UInt#(5))    preambleCnt  <- mkCounterSat(    clocked_by txClk, reset_by txRst);
  CounterSat#(UInt#(5))    ifgCnt       <- mkCounterSat(    clocked_by txClk, reset_by txRst);
  CounterSat#(UInt#(12))   lenCnt       <- mkCounterSat(    clocked_by txClk, reset_by txRst);
  Reg#(Bool)               txActive     <- mkReg(False,     clocked_by txClk, reset_by txRst);
  CRC#(32)                 crc          <- mkCRC32(         clocked_by txClk, reset_by txRst);
  CounterSat#(UInt#(12))   crcDbgCnt    <- mkCounterSat(    clocked_by txClk, reset_by txRst);
  Reg#(Bool)               underflow    <- mkDReg(False,    clocked_by txClk, reset_by txRst);
  Reg#(UInt#(3))           emitFCS      <- mkReg(0,         clocked_by txClk, reset_by txRst);
  Reg#(Bool)               doPad        <- mkReg(False,     clocked_by txClk, reset_by txRst);
  Reg#(Bool)               isSOF        <- mkReg(True,      clocked_by txClk, reset_by txRst);
  Reg#(Bool)               unfD         <- mkReg(False,     clocked_by txClk, reset_by txRst);
  SyncFIFOIfc#(ABS)        txF          <- mkSyncFIFOFromCC(8, txClk);  // ~6 cycle fallthrough
  SyncBitIfc#(Bit#(1))     unfBit       <- mkSyncBitToCC(txClk, txRst);

  Bool txUnd = !txF.notEmpty && txActive;
  rule unf_stretch; unfD <= txUnd; endrule
  rule undeflow_detect; unfBit.send(pack(txUnd || unfD)); endrule

  (* descending_urgency = "egress_FCS, egress_PAD, egress_EOF, egress_Body, egress_SOF" *)

  rule egress_SOF(isSOF &&& ifgCnt==0 &&& txF.first matches tagged ValidNotEOP .d);
    if (preambleCnt<7) begin
      txData <= pack(PREAMBLE);    // 7 Preamble cycles - 8'h55
    end else if (preambleCnt==7) begin
      txData <= pack(SFD);         // 1 SFD cycle - 8'hD5
    end else begin
      txData <= d;                 // 1st Byte of Destination Address
      crc.add(d);
      crcDbgCnt.inc;
      txF.deq;
      lenCnt.inc;
      isSOF <= False;
    end
    preambleCnt.inc();
    txDV     <= True;
    txActive <= True;
  endrule

  rule egress_Body(txActive &&& !isSOF &&& txF.first matches tagged ValidNotEOP .d);
    txData <= d;
    crc.add(d);
    crcDbgCnt.inc;
    txF.deq;
    lenCnt.inc;
    txDV <= True;
  endrule

  rule egress_EOF(txActive &&& txF.first matches tagged ValidEOP .d);
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
    Vector#(4,Bit#(8)) fcsV = reverse(unpack(crc.result));
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
      isSOF <= True;
    end
  endrule

  rule ifg_decrementer (ifgCnt!=0);
    ifgCnt.dec;
  endrule

  interface Put tx = toPut(txF);
  method  Bool txUnderFlow = unpack(unfBit.read);
  interface GMII_TX_RS gmii;
    interface Clock   tx_clk = txClk;
    method    Bit#(8) txd    = txData;
    method    Bit#(1) tx_en  = pack(txDV);
    method    Bit#(1) tx_er  = pack(txER);
  endinterface: gmii
endmodule: mkTxRSAsync



//
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
