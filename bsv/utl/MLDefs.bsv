// MLDefs.bsv - Message Level Definitions
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package MLDefs;

import GetPut  ::*;
import Vector  ::*;

typedef struct {
  Bit#(8)   opcode;   // Message Opcode
  UInt#(32) length;   // Message Length in Bytes
} MLMeta deriving (Bits, Eq);

typedef Vector#(16,Bit#(8)) HexByte;

interface MLProducer;
  interface GetS#(MLMeta) meta;    // GetS splits the "first" and "deq" methods so we can observe
  interface Get#(HexByte) data;    // Our message data
endinterface

interface PutAck#(type t);
  method Action offer(t val);      // A way to observe the first element
  method Bool   ack();             // And signal for the next
endinterface

interface MLConsumer;
  interface PutAck#(MLMeta) meta;  // Our metadata
  interface Put#(HexByte)   data.  // Our message data
endinterface

endpackage
