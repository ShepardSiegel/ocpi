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

typedef Bit#(48)  MACAddress;
typedef Bit#(16)  EtherType;
typedef Bit#(32)  IPAddress;

typedef struct {
  MACAddress dst;  // 6B Destination MAC Address
  MACAddress src;  // 6B Source      MAC Address
  EtherType  typ;  // 2B Ether-Type (or non-Jumbo Length)
} E8023Header deriving (Bits, Eq);

typedef union tagged {
  E8023Header          E8023Head;  // Fully formed, valid, Ethernet 802.3 14B Header
  Vector#(14,Bit#(8))  FragV;      // Vector of 14 Bytes not yet fully assembled 
} E8023Hdr deriving (Bits, Eq);

interface E8023HCapIfc;
  method Action clear;
  method Action shiftIn1 (Bit#(8)  x);
  //method Action shiftIn8 (Bit#(64) x);
  method E8023Hdr _read();
  method E8023Header full(); // method not ready until it can return complete E8023Header structure
  method Bool isMatch();
  method Bit#(32) dst_ms;  // Top 2B are zero
  method Bit#(32) dst_ls;  // LS alligned
  method Bit#(32) src_ms;  // Top 2B are zero
  method Bit#(32) src_ls;  // LS alligned
  method Bit#(32) typ;     // Top 2N are zero
  method UInt#(4) posDbg;
  method UInt#(4) mCntDbg;
endinterface

module mkE8023HCap (E8023HCapIfc);
  Reg#(UInt#(4))  pos  <-  mkReg(0);
  Reg#(UInt#(4))  mCnt <-  mkReg(0);
  Reg#(E8023Hdr)  sV   <-  mkReg(tagged FragV unpack(0));
  Reg#(E8023Hdr)  pV   <-  mkReg(tagged FragV unpack(0));
  //Wire#(Bit#(8))  bW   <-  mkWire;
  //Wire#(Bit#(64)) oW   <-  mkWire;

  //(* mutually_exclusive = "byte1_update, byte8_update" *)

  /*
  rule byte1_update (sV matches tagged FragV .v);
    pos <= (pos<14)  ? pos+1 : 14;
    Vector#(14,Bit#(8)) nV = shiftInAt0(v, bW);
    sV  <= (pos==13) ? tagged E8023Head unpack(pack(nV)) : tagged FragV nV;
    if (pos==13) pV <= sV;
    if (pV matches tagged E8023Head .h) begin
      Vector#(14,Bit#(8)) pbV = unpack(pack(h)); // Turn our valid structure back to a vector of 14B
      if (v[pos] == pbV[pos]) mCnt <= mCnt + 1;
    end
  endrule
  */

  /*
  rule byte8_update (sV matches tagged FragV .v);
    pos <= (pos==0)  ? pos+8 : 14;
    case (pos)
      0: begin
         Vector#(6,Bit#(8))  v0 = unpack(0);
         Vector#(14,Bit#(8)) v1 = append(v0, unpack(oW));
         sV <= tagged FragV  v1;  // Place the first 8B at [13-6]
      end
      8: begin
         Vector#(8,Bit#(8))  v2 = unpack(oW);
         Vector#(8,Bit#(8))  v3 = takeAt(6,v);     // The 8B of v we want to keep 
         Vector#(6,Bit#(8))  v4 = takeAt(2,v2);    // The 6B of oW we want to add in
         Vector#(14,Bit#(8)) v5 = append(v4, v3);  // v5[13] has MSB of DST MAC; v5[0] has LSB of EtherType
         sV <= tagged E8023Head unpack(pack(v5));  // Result
      end
    endcase
    if (pos==8) pV <= sV;
    // TODO Add Match Count logic
  endrule
  */

  method Action clear;
    pos  <= 0;
    mCnt <= 0;
    sV <= tagged FragV unpack(0);
  endmethod

  //method Action shiftIn1 (Bit#(8)  x) = bW._write(x);
  method Action shiftIn1 (Bit#(8)  x);
    if (sV matches tagged FragV .v) begin
      pos <= (pos<14)  ? pos+1 : 14;
      Vector#(14,Bit#(8)) nV = shiftInAt0(v, x);
      sV  <= (pos==13) ? tagged E8023Head unpack(pack(nV)) : tagged FragV nV;
      if (pos==13) pV <= tagged E8023Head unpack(pack(nV));
      if (pV matches tagged E8023Head .h) begin
        Vector#(14,Bit#(8)) pbV = unpack(pack(h)); // Turn our valid structure back to a vector of 14B
        if (v[pos] == pbV[pos]) mCnt <= mCnt + 1;
       end
    end
  endmethod

  //method Action shiftIn8 (Bit#(64) x) = oW._write(x);
  method E8023Hdr _read() = sV;
  method E8023Header full() if (sV matches tagged E8023Head .f) = f;
  method Bool isMatch() = (mCnt==14);
  method Bit#(32) dst_ms() if (pV matches tagged E8023Head .z) = truncate(z.dst>>32);
  method Bit#(32) dst_ls() if (pV matches tagged E8023Head .z) = truncate(z.dst);
  method Bit#(32) src_ms() if (pV matches tagged E8023Head .z) = truncate(z.src>>32);
  method Bit#(32) src_ls() if (pV matches tagged E8023Head .z) = truncate(z.src);
  method Bit#(32) typ()    if (pV matches tagged E8023Head .z) = extend(z.typ);
  method UInt#(4) posDbg   = pos;
  method UInt#(4) mCntDbg  = mCnt;
endmodule


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
interface GMII_TX_RS;                            // FPGA provides to PHY
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
  method    Bit#(1)     led;
endinterface: GMII_RS

(* always_enabled, always_ready *)
interface GMII_PCS; // GMII_PCS is the top of the PHY facing the MAC...
  interface GMII_RX_PCS rx;
  interface GMII_TX_PCS tx;
  method    Bit#(1)     col;
  method    Bit#(1)     crs;
  method    Action      led  (Bit#(1) i);
endinterface: GMII_PCS

interface RxRSIfc;
  interface GMII_RX_RS  gmii;
  method    Action      rxOperate;
  method    Bool        rxOverFlow;
  interface Get#(ABS)   rx;
endinterface

interface TxRSIfc;
  interface Put#(ABS)   tx;
  method    Action      txOperate;
  method    Bool        txUnderFlow;
  interface GMII_TX_RS  gmii;
endinterface

interface GMACIfc;
  interface GMII_RS     gmii;
  interface Clock       rxclkBnd; 
  //interface Reset       gmii_rstn;
  interface Get#(ABS)   rx;
  interface Put#(ABS)   tx;
  method Action         rxOperate;
  method Action         txOperate;
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
//      is a on-card XO that provides a stable 125 MHz to transmit symbols by GMII to the PHY. Note that
//      although logically the "tx" clock, the FPGA XO provides this by GMII to the PHY on the pin "GTX_CLK".
//      Inside the PHY TX symbols are capured from the FPGA with the GTX clock, passed through a FIFO, and
//      then sent out on the 1Gb wire by a crystal XO connected to the PHY.
//      The PHY has an output pin "TX_CLK" which is unused in 1Gb operation that this MAC ignores in all cases.
//      path: board 125 MHz source-> FPGA sys1 input -> FPGA TX logic -> PHY GTX_CLK pin -> wire
// iii) There is the Current Clock (CC) default module clock of this mkGMAC module. This can be any frequency
//      equal to or greater than 125 MHz. Buffer sizes and interfame gaps allow a tolerance between the CC 
//      frequency and (i) and (ii) above. At frequencies above 125 MHz TX underrun and RX overrun can only be
//      caused by some external agent (e.g. non-continious WSI on TX, or mid-packet backpressure on RX).
// In some scenarios, the CC can be the same as the (G)TX clk (ii), elliminating the need for a third clock
// Each tx/rx Resolution Sublayer (RS) block handles the clock domain crossing from their tx/rx domain, back to CC

`ifdef SPARTAN
  Clock         rxClk_BUFR       = rxClk;
`else
  ClockIODELAY  gmii_rxc_dly     <-  vClockIODELAY("FIXED", 0, "I", clocked_by rxClk);
  Clock         gmii_rx_clk_dly  =   gmii_rxc_dly.delayed;
  Clock         gmii_rx_clk      <-  mkClockBUFIO(clocked_by gmii_rx_clk_dly);
  //TODO: Use gmii_rx_clk to capture rxd,dv,err in IOB FFs
  //TODO: Use txClk to register tx gmii signals in IOB FFs
  Clock         rxClk_BUFR       <-  mkClockBUFR(BUFRParams{bufr_divide:"BYPASS"}, clocked_by gmii_rx_clk_dly);
`endif
  Clock         clk              <-  exposeCurrentClock;  // User-Facing CC for the rx/tx methods
  Reset         rst              <-  exposeCurrentReset;
  Reset         phyReset         <-  mkAsyncReset(8, rst, clk); // Hold PHY in reset for 8 *additional* cycles
  RxRSIfc       rxRS             <-  mkRxRSAsync(rxClk_BUFR);
  TxRSIfc       txRS             <-  mkTxRSAsync(txClk);

  ReadOnly#(Bool) isReset        <- isResetAsserted;

  interface Get rx = rxRS.rx;
  interface Put tx = txRS.tx;
  method Action rxOperate   = rxRS.rxOperate;
  method Action txOperate   = txRS.txOperate;
  method Bool   rxOverFlow  = rxRS.rxOverFlow;
  method Bool   txUnderFlow = txRS.txUnderFlow;

  interface GMII_RS gmii;                  // PHY-facing GMII Interface to FPGA Pins
    interface GMII_RX_RS  rx = rxRS.gmii;
    interface GMII_TX_RS  tx = txRS.gmii;
    method Action col (Bit#(1) i) = noAction;
    method Action crs (Bit#(1) i) = noAction;
    method Bit#(1) led = pack(!isReset);
  endinterface
  interface Clock rxclkBnd    = rxClk_BUFR;  // Need to provide this clock at the BSV module bounds (not physically used)
  //interface Reset gmii_rstn = phyReset;    // Active-Low reset passed up and out to PHY
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
  Reg#(Bool)               rxOperateD   <- mkDReg(False);
  SyncBitIfc#(Bit#(1))     rxOperateS   <- mkSyncBitFromCC(rxClk);
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

  rule operate_condition; rxOperateS.send(pack(rxOperateD)); endrule // send the operate DReg from CC to rxClk domain
  Bool rxEnable = unpack(rxOperateS.read);
  rule dv_reg (rxEnable); rxDVD <= rxDV; rxDVD2 <= rxDVD; endrule
  rule full_stretch; fullD <= rxEnable && !rxF.notFull; endrule
  Bool rxOverflow = rxEnable && (!rxF.notFull || fullD);  // Stretch full detection so SyncBit sees at least one cycle
  rule overflow_detect (rxEnable); ovfBit.send(pack(rxOverflow)); endrule  // Feed Synchronizer

  rule ingress_advance (rxEnable && rxDV);
     rxPipe  <= shiftInAt0(rxPipe, rxData);                     // Build up our 32b FCS candidate
     rxAPipe <= shiftInAt0(rxAPipe,rxActive);                   // Mark where Active data starts (after SFD)
     if (rxData == pack(PREAMBLE))  preambleCnt.inc;            // Count preamble octets
     if (preambleCnt>6 && rxData==pack(SFD)) rxActive <= True;  // Detect Start of Frame Delimiter
  endrule

  rule ingress_noadvance (rxEnable && !rxDVD && rxAPipe==unpack(6'h3F) && !crcEnd);  // !rxDV is indication we have FCS
    let fcs <- crc.complete;
    $display("[%0d]: %m: RX FCS:%08x from %d elements", $time, fcs, crcDbgCnt);
    crcDbgCnt.load(0);
    if (rxActive) begin
      Bool fcsMatch = (fcs == unpack(pack(reverse(takeAt(0,rxPipe)))));
      rxF.enq( (fcsMatch) ? tagged ValidEOP rxPipe[4] : tagged AbortEOP);  // Either ValidEOP or AbortEOP
    end
    crcEnd   <= True;
  endrule

  rule end_frame (rxEnable && crcEnd);
    preambleCnt.load(0);   // Reset the preamble counter
    rxActive <= False;     // Clear rxActive
    isSOF    <= True;      // For next frame
    rxAPipe  <= unpack(0); // Clear shift register
    crcEnd   <= False;
  endrule

  rule crc_capture (rxEnable && rxDV && rxAPipe[3]);
    crc.add(rxPipe[3]); // Update CRC starting with DA (after SFD)
    crcDbgCnt.inc;
  endrule

  rule egress_data  (rxEnable && rxDVD && rxAPipe[5]);
    rxF.enq(tagged ValidNotEOP rxPipe[5]); 
    isSOF <= False;    
  endrule

  interface GMII_RX_RS gmii;
    method Action rxd   (x) = rxData._write(x);
    method Action rx_dv (x) = rxDV._write(unpack(x));
    method Action rx_er (x) = rxER._write(unpack(x));
  endinterface: gmii

  interface Get rx = toGet(rxF);
  method    Action  rxOperate = rxOperateD._write(True);
  method    Bool    rxOverFlow = unpack(ovfBit.read);
endmodule: mkRxRSAsync

// Transmit (Tx) Reconciliation Sublayer (RS)
// This module accepts the TX data from a higher sublevel of the MAC; frames start at the Destination Address (DA)
// It will insert the preamble and SFD, pass the incident frame, and generate and insert the FCS
// If the txF starves in the middle of a frame; that is a TX UNDERFLOW error (txUnderflow)
module mkTxRSAsync#(Clock txClk) (TxRSIfc);
  Reset                    txRst        <- mkAsyncResetFromCR(2, txClk);
  Reg#(Bool)               txOperateD   <- mkDReg(False);
  SyncBitIfc#(Bit#(1))     txOperateS   <- mkSyncBitFromCC(txClk);
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

  rule operate_condition; txOperateS.send(pack(txOperateD)); endrule // send the operate DReg from CC to txClk domain
  Bool txEnable = unpack(txOperateS.read);
  Bool txUnd = txEnable && (!txF.notEmpty && txActive && !doPad);
  rule unf_stretch ; unfD <= txUnd; endrule
  rule undeflow_detect (txEnable); unfBit.send(pack(txUnd || unfD)); endrule

  //(* descending_urgency = "egress_FCS, egress_PAD, egress_EOF, egress_Body, egress_SOF" *)
  (* descending_urgency = "egress_FCS, egress_EOF, egress_Body, egress_SOF" *)

  rule egress_SOF(txEnable && isSOF &&& ifgCnt==0 &&& txF.first matches tagged ValidNotEOP .d);
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

  rule egress_Body(txEnable && txActive &&& !isSOF &&& txF.first matches tagged ValidNotEOP .d);
    txData <= d;
    crc.add(d);
    crcDbgCnt.inc;
    txF.deq;
    lenCnt.inc;
    txDV <= True;
  endrule

  rule egress_EOF(txEnable && txActive &&& txF.first matches tagged ValidEOP .z);
    //Bool padData = (lenCnt<59);
    let d = doPad ? pack(PAD) : z;  // doPad will be false the first time fired; so we get ValidEOP data
    txData <= d;
    crc.add(d);
    crcDbgCnt.inc;
    lenCnt.inc;
    txDV <= True;
    if (lenCnt>=59) begin // if no padding needed, pop txF and advance to emitFCS
      txActive <= False;
      emitFCS <= 4;
      txF.deq;
      doPad <= False;
    end else doPad <= True;
  endrule

  rule egress_FCS(txEnable && emitFCS!=0);
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

  rule ifg_decrementer (txEnable && ifgCnt!=0);
    ifgCnt.dec;
  endrule

  // Output source-syncronous clocking; Clock output is 180 degress out-of-phase for 4 nS SU + 4 nS Hold...

`ifdef SPARTAN

  (* doc = "iobTxClk output is 180 degress out-of-phase for 4 nS SU + 4 nS Hold" *)
  Clock            iobTxClk  <- mkClockODDR2(ODDR2Prms {ddr_alignment:"NONE", init:0, srtype:"SYNC"}, 0, 1, clocked_by txClk, reset_by txRst);
  ODDR2#(Bit#(8))  iobTxData <- mkODDR2(     ODDR2Prms {ddr_alignment:"NONE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  ODDR2#(Bit#(1))  iobTxEna  <- mkODDR2(     ODDR2Prms {ddr_alignment:"NONE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  ODDR2#(Bit#(1))  iobTxErr  <- mkODDR2(     ODDR2Prms {ddr_alignment:"NONE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  (* fire_when_enabled, no_implicit_conditions *)
  rule tx_output_flops;
    iobTxData.d0(txData);    iobTxData.d1(txData);     iobTxData.ce(True);  iobTxData.s(False); iobTxData.r(False);
    iobTxEna.d0(pack(txDV)); iobTxEna.d1(pack(txDV));  iobTxEna.ce(True);   iobTxEna.s(False);  iobTxEna.r(False);
    iobTxErr.d0(pack(txER)); iobTxErr.d1(pack(txER));  iobTxErr.ce(True);   iobTxErr.s(False);  iobTxErr.r(False);
  endrule


`else

  (* doc = "iobTxClk output is 180 degress out-of-phase for 4 nS SU + 4 nS Hold" *)
  Clock             iobTxClk  <- mkClockODDR(ODDRParams {ddr_clk_edge:"SAME_EDGE", init:0, srtype:"SYNC"}, 0, 1, clocked_by txClk, reset_by txRst);
  ODDRar#(Bit#(8))  iobTxData <- mkODDRar(   ODDRParams {ddr_clk_edge:"SAME_EDGE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  ODDRar#(Bit#(1))  iobTxEna  <- mkODDRar(   ODDRParams {ddr_clk_edge:"SAME_EDGE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  ODDRar#(Bit#(1))  iobTxErr  <- mkODDRar(   ODDRParams {ddr_clk_edge:"SAME_EDGE", init:0, srtype:"SYNC"},       clocked_by txClk, reset_by txRst);
  (* fire_when_enabled, no_implicit_conditions *)
  rule tx_output_flops;
    iobTxData.d1(txData);    iobTxData.d2(txData);     iobTxData.ce(True);  iobTxData.s(False);
    iobTxEna.d1(pack(txDV)); iobTxEna.d2(pack(txDV));  iobTxEna.ce(True);   iobTxEna.s(False);
    iobTxErr.d1(pack(txER)); iobTxErr.d2(pack(txER));  iobTxErr.ce(True);   iobTxErr.s(False);
  endrule


`endif


  interface Put tx = toPut(txF);
  method  Action  txOperate = txOperateD._write(True);
  method  Bool txUnderFlow = unpack(unfBit.read);
  interface GMII_TX_RS gmii;
    interface Clock   tx_clk = iobTxClk;
    method    Bit#(8) txd    = iobTxData.q;
    method    Bit#(1) tx_en  = iobTxEna.q;
    method    Bit#(1) tx_er  = iobTxErr.q;
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
