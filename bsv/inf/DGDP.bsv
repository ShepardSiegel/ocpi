// DGDP.bsv - DataGram DataPlane Types, functions, and modules...
// Copyright (c) 2102 Atomic Rules LLC - ALL RIGHTS RESERVED

package DGDP;

import E8023        ::*;

import ClientServer ::*; 
import DReg         ::*;
import FIFO         ::*;
import FIFOF        ::*;
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;

// DataGramDataPlane (DGDP) types...

typedef struct {
  Bit#(16)  dstID;     // Destination ID of endpoint
  Bit#(16)  srcID;     // Source ID of endpoint
  Bit#(16)  frameSeq;  // Rolling sequence frame number
  Bit#(16)  ackStart;  // Start of ACK sequence
  Bit#(8)   ackCount;  // Tital number of ACKs
  Bit#(8)   flags;     // b0: 1=frame has at least one message, 0=ACK-only frame (no messages)
} DGDPframeHeader deriving (Bits, Eq);

typedef struct {
  UInt#(32) transID;   // Transaction ID - rolling count unique to this source
  Bit#(32)  flagAddr;  // Address where the (e.g. buffer full) flag should be written
  Bit#(32)  flagData;  // Value of flag to write
  UInt#(16) numMesg;   // Number of messages for this transaction
  UInt#(16) mesgSeq;   // Message sequence number scoped to this transaction
  Bit#(32)  dataAddr;  // Address where the data or metadata should be written
  UInt#(16) dataLen;   // Length in Bytes of the data or metadata
  Bit#(8)   mesgTyp;   // Enum for message type - may be depricated
  Bit#(8)   flags;     // b0: 1=A message follows this one, 0=This is the last message in this frame
} DGDPmesgHeader deriving (Bits, Eq);


/*
function Vector#(16,ABS) fhAs16ByteV (DGDPframeHeader h, Bool isEOP);
  Vector#(10,Bit#(8)) v1 = reverse(unpack(pack(h)));  // reverse element order so that v[0] is dstID 
  Vector#(6, Bit#(8)) v2 = ?;
  Vector#(16,Bit#(8)) v3 = append(v1,v2);
  // map with argument?
  Vector#(16, ABS)    v4 = ?;
  for (Integer i=0; i<16; i=i+1) v4[i] = tagged ValidNotEOP v3[i];
  if (isEOP) v4[9] = tagged ValidEOP v3[9];
  return(v4);
endfunction
*/

// Version with two empty ABS cells at head...
function Vector#(16,ABS) fhAs16ByteV (DGDPframeHeader h, Bool isEOP);
  Vector#(10,Bit#(8)) v1 = reverse(unpack(pack(h)));  // reverse element order so that v[0] is dstID 
  Vector#(6, Bit#(8)) v2 = ?;
  Vector#(16,Bit#(8)) v3 = append(v1,v2);
  // map with argument?
  Vector#(16, ABS)    v4 = ?;
  v4[0] = tagged ValidNotEOP 8'h42;  // bogus
  v4[1] = tagged ValidNotEOP 8'h43;  // bogus
  for (Integer i=0; i<14; i=i+1) v4[i+2] = tagged ValidNotEOP v3[i];
  if (isEOP) v4[11] = tagged ValidEOP v3[11];
  return(v4);
endfunction

function Vector#(16,ABS) mhAs16ByteV (DGDPmesgHeader h, Bool first, Bool isEOP);
  Vector#(24,Bit#(8)) v1 = reverse(unpack(pack(h)));  // reverse element order so that v[0] is transID 
  Vector#(8, Bit#(8)) v2 = unpack(0);
  Vector#(32,Bit#(8)) v3 = append(v1,v2);
  // map with argument?
  Vector#(32, ABS)    v4 = ?;
  for (Integer i=0; i<32; i=i+1) v4[i] = tagged ValidNotEOP v3[i];
  if (isEOP) v4[31] = tagged ValidEOP v3[31];
  if (first) return (takeAt(0, v4));
  else       return (takeAt(16,v4));
endfunction








endpackage
