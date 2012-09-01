// E8023.bsv - Types, Functions, and convienience modulues used by IEEE 802.3 Ethernet
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// See IEEE 802.3-2008 section 35 Reconciliation Sublayer (RS) and Gigabit Media Independent Interface (GMII)
// Includes Abortable Byte Stream (ABS) and derrivative Types 

package E8023;

import CounterM          ::*;

import Clocks            ::*;
import Connectable       ::*;
import CRC               ::*;
import DReg              ::*;
import FIFO              ::*;
import FIFOF             ::*;
import GetPut            ::*;
import Vector            ::*;

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

typedef Vector#(4,ABS) QABS;

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

function ABS tagValidData(Bool eop, Bit#(8) d);
  return (eop ? tagged ValidEOP d : tagged ValidNotEOP d);
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


// ABSMerge styled after the much-used (TLP) mkPktMerge...

interface ABSMergeIfc;
  interface Put#(ABS) iport0;
  interface Put#(ABS) iport1;
  interface Get#(ABS) oport;
endinterface

module mkABSMerge (ABSMergeIfc);

  FIFOF#(ABS) fi0        <- mkFIFOF;
  FIFOF#(ABS) fi1        <- mkFIFOF;
  FIFOF#(ABS) fo         <- mkFIFOF;
  Reg#(Bool)  fi0HasPrio <- mkReg(True);   // True when fi0 has priority
  Reg#(Bool)  fi0Active  <- mkReg(False);  // True on the 2nd through the EOP cycle of fi0 packet
  Reg#(Bool)  fi1Active  <- mkReg(False);  // True on the 2nd through the EOP cycle of fi1 packet

  function Bool isABSActive (ABS x);
    if (x matches tagged ValidNotEOP .*) return True;
    else                                 return False;
  endfunction

  (* descending_urgency = "arbitrate, fi0_advance, fi1_advance" *)
  // The first two rules handle the non-contending 1st cycle and all 2-n cycle cases...
  rule fi0_advance (!fi1Active);
    let x = fi0.first; fi0.deq; fo.enq(x);
    fi0Active  <= isABSActive(x);
    fi0HasPrio <= False;
  endrule

  rule fi1_advance (!fi0Active);
    let x = fi1.first; fi1.deq; fo.enq(x);
    fi1Active  <= isABSActive(x);
    fi0HasPrio <= True;
  endrule

  // The arbitrate rule handles the contending 1st cycle case by LRU.
  // Both inputs are available, but neither is yet active...
  rule arbitrate (fi0.notEmpty && fi1.notEmpty && !fi0Active && !fi1Active);
    FIFOF#(ABS) fi = ((fi0HasPrio) ? fi0 : fi1);
    let x = fi.first; fi.deq; fo.enq(x);
    if (fi0HasPrio) fi0Active <= isABSActive(x);
    else            fi1Active <= isABSActive(x);
    fi0HasPrio <= !fi0HasPrio;
  endrule

 interface iport0 = toPut(fi0);
 interface iport1 = toPut(fi1);
 interface oport  = toGet(fo);

endmodule: mkABSMerge

endpackage: E8023
