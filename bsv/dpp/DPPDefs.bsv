// DPPDefs.bsv
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package DPPDefs;

import Connectable     ::*;
import DefaultValue    ::*;
import GetPut          ::*;
import Reserved        ::*;
import TieOff          ::*;
import Vector          ::*;


// DPP Frame Header - 10B total...
typedef struct {
  Bit#(16)  did;  // Destination ID
  Bit#(16)  sid;  // Source ID
  UInt#(16) fs;   // Frame Sequence number (rolling count)
  UInt#(16) as;   // ACKstart (start of ACK sequence)
  UInt#(8)  ac;   // ACKCount (number of ACKs)
  Bit#(8)   f;    // Flags (0==ACK Only Frame; 1==Frame has at least 1 message)
} DPPFrameHeader deriving (Eq);  // Note Bits not derived, as pack/unpack specified below...

// Overload pack and unpack functions so that the DPPFrameHeader is in little-endian order...
instance Bits#(DPPFrameHeader, 80);
  function Bit#(80) pack(DPPFrameHeader fh);
    return { pack(fh.f), pack(fh.ac), pack(fh.as), pack(fh.fs), pack(fh.sid), pack(fh.did) };
  endfunction
  function DPPFrameHeader unpack(Bit#(80) f);
  Vector#(10,Bit#(8)) fV = unpack(f);
    return (DPPFrameHeader {
      did: unpack(pack(reverse(takeAt(0,fV)))),
      sid: unpack(pack(reverse(takeAt(2,fV)))),
      fs:  unpack(pack(reverse(takeAt(4,fV)))),
      as:  unpack(pack(reverse(takeAt(6,fV)))),
      ac:  unpack(pack(reverse(takeAt(8,fV)))),
      f:   unpack(pack(reverse(takeAt(9,fV)))) });
  endfunction
endinstance

instance DefaultValue#(DPPFrameHeader);
defaultValue =
  DPPFrameHeader {
    did: 0,
    sid: 0,
    fs:  0,
    as:  0,
    ac:  0,
    f:   0
  };
endinstance

// DPP Message Header - 24B total...
typedef struct {
  UInt#(32) tid;  // Transaction ID (rolling count)
  UInt#(32) fa;   // Flag Address
  Bit#(32)  fv;   // Flag Value
  UInt#(16) nm;   // Number of Messages in this transaction
  UInt#(16) ms;   // Message Sequence number scoped to this transaction
  UInt#(32) da;   // Data Address where this message should get written
  UInt#(16) dl;   // Data Length in Bytes of data that follows the header
  Bit#(8)   mt;   // Message Type (enum)
  Bit#(8)   tm;   // Trailimg Message (0=last message in frame;1=another message follows)
} DPPMessageHeader deriving (Eq); // Note Bits not derived, as pack/unpack specified below...

// Overload pack and unpack functions so that the DPPMessageHeader is in little-endian order...
instance Bits#(DPPMessageHeader, 192);
  function Bit#(192) pack(DPPMessageHeader mh);
    return { pack(mh.tm), pack(mh.mt), pack(mh.dl), pack(mh.da), pack(mh.ms), pack(mh.nm), pack(mh.fv), pack(mh.fa), pack(mh.tid) };
  endfunction
  function DPPMessageHeader unpack(Bit#(192) m);
  Vector#(24,Bit#(8)) mV = unpack(m);
    return (DPPMessageHeader {
      tid: unpack(pack(reverse(takeAt(0, mV)))),
      fa:  unpack(pack(reverse(takeAt(4, mV)))),
      fv:  unpack(pack(reverse(takeAt(8, mV)))),
      nm:  unpack(pack(reverse(takeAt(12,mV)))),
      ms:  unpack(pack(reverse(takeAt(14,mV)))),
      da:  unpack(pack(reverse(takeAt(16,mV)))),
      dl:  unpack(pack(reverse(takeAt(20,mV)))),
      mt:  unpack(pack(reverse(takeAt(22,mV)))),
      tm:  unpack(pack(reverse(takeAt(23,mV)))) });
  endfunction
endinstance

instance DefaultValue#(DPPMessageHeader);
defaultValue =
  DPPMessageHeader {
    tid: 0,
    fa:  0,
    fv:  0,
    nm:  0,
    ms:  0,
    da:  0,
    dl:  0,
    mt:  0,
    tm:  0 
  };
endinstance

endpackage: DPPDefs
