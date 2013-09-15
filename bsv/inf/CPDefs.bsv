// CPDefs.bsv -the data structures used by OCCP
// Copyright (c) 2009-2013 Atomic Rules LLC - ALL RIGHTS RESERVED

package CPDefs;

typedef struct {
  Bit#(22) dwAddr;
  Bit#(4)  byteEn;
  Bit#(32) data;
} CpWriteReq deriving (Bits);

typedef struct {
  Bit#(8)  tag;
  Bit#(22) dwAddr;
  Bit#(4)  byteEn;
} CpReadReq deriving (Bits);

typedef union tagged {
  CpWriteReq WriteRequest;
  CpReadReq  ReadRequest;
} CpReq deriving (Bits);

typedef struct {
  Bit#(8)  tag;
  Bit#(32) data;
} CpReadResp deriving (Bits);

endpackage
