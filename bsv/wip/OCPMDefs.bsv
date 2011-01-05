// OCPMDefs.bsv -   Protocol Monotor defintions and utlities
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCPMDefs;

import FShow::*;

typedef enum {
  PMEV_NONE               = 0,
  PMEV_UNRESET            = 1,
  PMEV_RESET              = 2,
  PMEV_UNATTENTION        = 3,
  PMEV_ATTENTION          = 4, 
  PMEV_UNTERMINATE        = 5,
  PMEV_TERMINATE          = 6,
  PMEV_TIMEOUT            = 7,
  PMEV_INITIALIZE         = 8,
  PMEV_START              = 9,
  PMEV_STOP               = 10,
  PMEV_RELEASE            = 11,
  PMEV_TEST               = 12,
  PMEV_BEFORE_QUERY       = 13,
  PMEV_AFTER_CONFIG       = 14,
  PMEV_WRITE_REQUEST      = 8'h10,
  PMEV_READ_REQUEST       = 8'h20,
  PMEV_WRITE_RESPONSE     = 8'h30,
  PMEV_READ_RESPONSE      = 8'h40,
  PMEV_REQLAST_ASSERT     = 8'h50,
  PMEV_BPRESSURE_ASSERT   = 8'h60,
  PMEV_BPRESSURE_DEASSERT = 8'h61,
  PMEV_REQUEST_ERROR      = 8'h80,
  PMEV_RESPONSE_ERROR     = 8'h90,
  PMEV_XACTION_ERROR      = 8'hA0,
  PMEV_PAD                = 255
 } PMEvent deriving (Bits, Eq);

 function PMEvent pmNibble(PMEvent pme, Bit#(4) nibble);
   return(unpack(pack(pme)+extend(nibble)));
 endfunction

typedef struct {    // Protocol Monitor Event Message (PMEM) Header
  Bit#(8) srcID;    // Source Indentifier of Protocol Monitor
  PMEvent eType;    // Event Type
  Bit#(8) srcTag;   // Source Event Tag
  Bit#(8) info;     // Event-Specific Info
} PMEMHeader deriving (Bits, Eq);

typedef union tagged {
  PMEMHeader Header;
  Bit#(32)   Body;
} PMEMHB deriving (Bits);

typedef struct {
  Bool   eom;
  PMEMHB pm;
} PMEMF deriving (Bits);

typedef struct {
  PMEvent  eType;
} PM_1DW deriving (Bits);

typedef struct {
  PMEvent  eType;
  Bit#(32) data0;
} PM_2DW deriving (Bits);

typedef struct {
  PMEvent  eType;
  Bit#(32) data0;
  Bit#(32) data1;
} PM_3DW deriving (Bits);

typedef struct {
  PMEvent  eType;
  Bit#(32) data0;
  Bit#(32) data1;
} PM_NDWH deriving (Bits);

typedef struct {
  Bit#(32) data2;
  Bit#(32) data3;
  Bit#(32) data4;
} PM_NDWB deriving (Bits);

typedef struct {
  Bit#(32) data2;
  Bit#(32) data3;
  Bit#(32) data4;
} PM_NDWT deriving (Bits);

typedef union tagged {
  PM_1DW  PMEM_1DW;
  PM_2DW  PMEM_2DW;
  PM_3DW  PMEM_3DW;
  PM_NDWH PMEM_NDWH;
  PM_NDWB PMEM_NDWB;
  PM_NDWT PMEM_NDWT;
} PMEM deriving (Bits); // A PMEM of either 1, 2, 3, or N DW

instance FShow#(PMEvent);
  function Fmt fshow (PMEvent pme);
    case (pme)
      PMEV_NONE                : return fshow("---None              ");
      PMEV_UNRESET             : return fshow("---UnReset           ");
      PMEV_RESET               : return fshow("---Reset             ");
      PMEV_UNATTENTION         : return fshow("---UnAttention       ");
      PMEV_ATTENTION           : return fshow("---Attention         ");
      PMEV_UNTERMINATE         : return fshow("---UnTerminate       ");
      PMEV_TERMINATE           : return fshow("---Terminate         ");
      PMEV_TIMEOUT             : return fshow("---Timeout           ");
      PMEV_INITIALIZE          : return fshow("---Initialize        ");
      PMEV_START               : return fshow("---Start             ");
      PMEV_STOP                : return fshow("---Stop              ");
      PMEV_RELEASE             : return fshow("---Release           ");
      PMEV_TEST                : return fshow("---Test              ");
      PMEV_BEFORE_QUERY        : return fshow("---BeforeQuery       ");
      PMEV_AFTER_CONFIG        : return fshow("---AfterConfig       ");
      PMEV_WRITE_REQUEST       : return fshow("---WriteRequest      ");
      PMEV_READ_REQUEST        : return fshow("---ReadRequest       ");
      PMEV_WRITE_RESPONSE      : return fshow("---WriteResponse     ");
      PMEV_READ_RESPONSE       : return fshow("---ReadResponse      ");
      PMEV_REQLAST_ASSERT      : return fshow("---ReqLastAsserted   ");
      PMEV_BPRESSURE_ASSERT    : return fshow("---BPressureAssert   ");
      PMEV_BPRESSURE_DEASSERT  : return fshow("---BPressureDeassert ");
      PMEV_REQUEST_ERROR       : return fshow("---RequestError      ");
      PMEV_RESPONSE_ERROR      : return fshow("---ResponseError     ");
      PMEV_XACTION_ERROR       : return fshow("---TransactionError  ");
      PMEV_PAD                 : return fshow("---Pad               ");
    endcase
  endfunction
endinstance

instance FShow#(PMEMHeader);
  function Fmt fshow(PMEMHeader val);
    return ($format("PMEM_HEADER ")
      +
      fshow(val.eType)
      +
      $format("srcID:(%0x) ",  val.srcID)
      +
      $format("srcTag:(%0x) ", val.srcTag)
      +
      $format("info:(%0x) ",   val.info));
  endfunction
endinstance

endpackage: OCPMDefs
