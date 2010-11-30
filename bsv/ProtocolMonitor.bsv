// ProtocolMonitor.bsv - Protocol Monotor defintions and utlities
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package ProtocolMonitor;

import OCWipDefs::*;

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import GetPut::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import FShow::*;
import SpecialFIFOs::*;
import TieOff::*;

// Common to all Protocol Monitors...

typedef enum {
  PMEV_NONE           = 0,
  PMEV_UNRESET        = 1,
  PMEV_RESET          = 2,
  PMEV_UNATTENTION    = 3,
  PMEV_ATTENTION      = 4, 
  PMEV_UNTERMINATE    = 5,
  PMEV_TERMINATE      = 6,
  PMEV_TIMEOUT        = 7,
  PMEV_INITIALIZE     = 8,
  PMEV_START          = 9,
  PMEV_STOP           = 10,
  PMEV_RELEASE        = 11,
  PMEV_TEST           = 12,
  PMEV_BEFORE_QUERY   = 13,
  PMEV_AFTER_CONFIG   = 14,
  PMEV_WRITE_REQUEST  = 8'h10,
  PMEV_READ_REQUEST   = 8'h20,
  PMEV_WRITE_RESPONSE = 8'h30,
  PMEV_READ_RESPONSE  = 8'h40,
  PMEV_REQUEST_ERROR  = 8'h80,
  PMEV_RESPONSE_ERROR = 8'h90,
  PMEV_XACTION_ERROR  = 8'hA0,
  PMEV_PAD            = 255
 } PMEvent deriving (Bits, Eq);

 function PMEvent pmNibble(PMEvent pme, Bit#(4) nibble);
   return(unpack(pack(pme)+extend(nibble)));
 endfunction

typedef struct {    // Protocol Monitor Event Message (PMEM) Header
  Bit#(8) srcID;    // Source Indentifier of Protocol Monitor
  PMEvent eType;    // Event Type
  Bit#(8) srcTag;   // Source Event Tag
  Bit#(8) length;   // Length in DWORDs of PMEM, including this DWORD header
} PMEMHeader deriving (Bits, Eq);

typedef union tagged { 
  PMEMHeader Header; 
  Bit#(32)   Body; 
} PMEM deriving (Bits);

typedef struct {
  Bool eof;        // Explicit EOF indication
  PMEM pmem;       // Header or Body of PMEM
} PMEMF deriving (Bits);

// Specific to the WCI Protocol Monitor...
typedef struct {
  PMEvent  eType;
} PMWCI0DW deriving (Bits);

typedef struct {
  PMEvent  eType;
  Bit#(32) data0;
} PMWCI1DW deriving (Bits);

typedef struct {
  PMEvent  eType;
  Bit#(32) data0;
  Bit#(32) data1;
} PMWCI2DW deriving (Bits);

typedef union tagged {
  PMWCI0DW Event0DW;
  PMWCI1DW Event1DW;
  PMWCI2DW Event2DW;
} PMWCIEvent deriving (Bits);


instance FShow#(PMEvent);
  function Fmt fshow (PMEvent pme);
    case (pme)
      PMEV_NONE            : return fshow("---None             ");
      PMEV_UNRESET         : return fshow("---UnReset          ");
      PMEV_RESET           : return fshow("---Reset            ");
      PMEV_UNATTENTION     : return fshow("---UnAttention      ");
      PMEV_ATTENTION       : return fshow("---Attention        ");
      PMEV_UNTERMINATE     : return fshow("---UnTerminate      ");
      PMEV_TERMINATE       : return fshow("---Terminate        ");
      PMEV_TIMEOUT         : return fshow("---Timeout          ");
      PMEV_INITIALIZE      : return fshow("---Initialize       ");
      PMEV_START           : return fshow("---Start            ");
      PMEV_STOP            : return fshow("---Stop             ");
      PMEV_RELEASE         : return fshow("---Release          ");
      PMEV_TEST            : return fshow("---Test             ");
      PMEV_BEFORE_QUERY    : return fshow("---BeforeQuery      ");
      PMEV_AFTER_CONFIG    : return fshow("---AfterConfig      ");
      PMEV_WRITE_REQUEST   : return fshow("---WriteRequest     ");
      PMEV_READ_REQUEST    : return fshow("---ReadRequest      ");
      PMEV_WRITE_RESPONSE  : return fshow("---WriteResponse    ");
      PMEV_READ_RESPONSE   : return fshow("---ReadResponse     ");
      PMEV_REQUEST_ERROR   : return fshow("---RequestError     ");
      PMEV_RESPONSE_ERROR  : return fshow("---ResponseError    ");
      PMEV_XACTION_ERROR   : return fshow("---TransactionError ");
      PMEV_PAD             : return fshow("---Pad              ");
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
      $format("length:(%0x) ", val.length));
  endfunction
endinstance


// PMEM Generator...

interface PMEMGenIfc;
  interface Get#(PMEMF) pmem;               // The protocol-monitor message produced
  method Action sendEvent (PMWCIEvent e);   // The event we wish to send
endinterface

module mkPMEMGen#(parameter Bit#(8) srcID)  (PMEMGenIfc);
  FIFOF#(PMEMF)      pmemF     <- mkFIFOF;   // PMEMF message output 
  FIFOF#(PMWCIEvent) evF       <- mkFIFOF;   // event input
  Reg#(Bit#(8))      srcTag    <- mkReg(0);  // 8b rolling count
  Reg#(Bit#(2))      dwRemain  <- mkReg(0);  // Remaining number of DWORDs to send this event

  Bool messageInEgress = (dwRemain!=0);

  rule gen_message_head (!messageInEgress);  // This rule will fire exactly once for each event...
    Bit#(8) len  = 0;
    PMEvent eTyp = ?;
    case (evF.first) matches
      tagged Event0DW .e0: begin len=1; dwRemain<=0; evF.deq; eTyp=e0.eType; end
      tagged Event1DW .e1: begin len=2; dwRemain<=1;          eTyp=e1.eType; end
      tagged Event2DW .e2: begin len=3; dwRemain<=2;          eTyp=e2.eType; end
    endcase
    let h = PMEMHeader {srcID:srcID, eType:eTyp, srcTag:srcTag, length:len};
    pmemF.enq(PMEMF{eof:(len==1), pmem:Header (h)});
    srcTag <= srcTag + 1;
    //$display("[%0d]: %m: gen_messsage_head", $time);
  endrule

  rule gen_message_body (messageInEgress);  // This rule will fire 0 or more times for each event...
    Bit#(32) d = 0;
    case (evF.first) matches
      tagged Event0DW .e0: $display("Error");
      tagged Event1DW .e1: d=e1.data0;
      tagged Event2DW .e2: d=(dwRemain==1)?e2.data1:e2.data0;
    endcase
    pmemF.enq(PMEMF{eof:(dwRemain==1),pmem:Body (d)});
    dwRemain <= dwRemain - 1;
    if(dwRemain==1) evF.deq;
    //$display("[%0d]: %m: gen_messsage_body", $time);
  endrule

  interface Get pmem = toGet(pmemF);             // provide Put from pmemF
  method Action sendEvent (PMWCIEvent e) = evF.enq(e);  // capture envent in evF
endmodule


// PMEM Monitor...

interface PMEMMonitorIfc;
  interface Put#(PMEMF) pmem;   // The protocol-monitor message monitored
  method Bool head;         
  method Bool body;         
endinterface

module mkPMEMMonitor (PMEMMonitorIfc);
  FIFOF#(PMEMF)      pmemF       <- mkFIFOF;   // PMEMF message input
  Reg#(PMEMHeader)   pmh         <- mkRegU;
  Reg#(Bit#(8))      dwRemain    <- mkRegU;
  Reg#(Bit#(32))     eventCount  <- mkReg(0);
  Reg#(Bool)         pmHead      <- mkDReg(False);
  Reg#(Bool)         pmBody      <- mkDReg(False);

  rule get_message_head (pmemF.first.pmem matches tagged Header .h);
    pmh <= h;
    pmemF.deq;
    pmHead <= True;
    dwRemain <= h.length - 1;
    if (h.length==1) begin 
      eventCount <= eventCount + 1;
      if (!pmemF.first.eof) $display("[%0d]: %m PMEM HEAD EOF ERROR", $time);
    end
    $display("[%0d]: %m PMEM event: ", $time, fshow(h));
  endrule

  rule gen_message_body (pmemF.first.pmem matches tagged Body .b);
    pmemF.deq;
    pmBody <= True;
    dwRemain <= dwRemain - 1;
    if(dwRemain==1) begin
      eventCount <= eventCount + 1;
      if (!pmemF.first.eof) $display("[%0d]: %m PMEM BODY EOF ERROR", $time);
    end
    $display("[%0d]: %m: PMEM MONITOR Event %0d Body dwRemain:%0x data:%0x ", $time, eventCount, dwRemain, b);
  endrule

  interface Put pmem = toPut(pmemF);
  method Bool head = pmHead;         
  method Bool body = pmBody;         
endmodule

endpackage: ProtocolMonitor
