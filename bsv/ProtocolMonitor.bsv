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

typedef struct {    // Protocol Monitor Event Message (PMEM) Header
  Bit#(8) srcID;    // Source Indentifier of Protocol Monitor
  Bit#(8) eType;    // Event Type
  Bit#(8) srcTag;   // Source Event Tag
  Bit#(8) length;   // Length in DWORDs of PMEM, including this DWORD header
} PMEMHeader deriving (Bits, Eq);

typedef union tagged {
  PMEMHeader Header;
  Bit#(32)   Body;
} PMEM deriving (Bits);

// Specific to the WCI Protocol Monitor...
typedef struct {
  Bit#(8)  eType;
} PMWCI0DW deriving (Bits);

typedef struct {
  Bit#(8)  eType;
  Bit#(32) data0;
} PMWCI1DW deriving (Bits);

typedef struct {
  Bit#(8)  eType;
  Bit#(32) data0;
  Bit#(32) data1;
} PMWCI2DW deriving (Bits);

typedef union tagged {
  PMWCI0DW Event0DW;
  PMWCI1DW Event1DW;
  PMWCI2DW Event2DW;
} PMWCIEvent deriving (Bits);


interface PMEMGenIfc;
  interface Put#(PMEM) pmem;               // The protocol-monitor message produced
  method Action sendEvent (PMWCIEvent e);  // The event we wish to send
endinterface

module mkPMEMGen#(parameter Bit#(8) srcID)  (PMEMGenIfc);
  FIFOF#(PMEM)       pmemF     <- mkFIFOF;   // PMEM message output 
  FIFOF#(PMWCIEvent) evF       <- mkFIFOF;   // event input
  Reg#(Bit#(8))      srcTag    <- mkReg(0);  // 8b rolling count
  Reg#(Bit#(2))      dwRemain  <- mkReg(0);  // Remaining number of DWORDs to send this event

  Bool messageInEgress = (dwRemain!=0);

  rule gen_message_head (!messageInEgress);  // This rule will fire exactly once for each event...
    Bit#(8) len = 0;
    case (evF.first) matches
      tagged Event0DW .e0: begin len=1; dwRemain<=0; evF.deq; end
      tagged Event1DW .e1: begin len=2; dwRemain<=1;          end
      tagged Event2DW .e2: begin len=3; dwRemain<=2;          end
    endcase
    let h = PMEMHeader {srcID:srcID, eType:0, srcTag:srcTag, length:len};
    pmemF.enq(Header (h));
    srcTag <= srcTag + 1;
  endrule

  rule gen_message_body (messageInEgress);  // This rule will fire 0 or more times for each event...
    Bit#(32) d = 0;
    case (evF.first) matches
      tagged Event0DW .e0: $display("Error");
      tagged Event1DW .e1: d=e1.data0;
      tagged Event2DW .e2: d=(dwRemain==1)?e2.data0:e2.data1;
    endcase
    pmemF.enq(Body (d));
    dwRemain <= dwRemain - 1;
    if(dwRemain==1) evF.deq;
  endrule

  rule foop4;
    $display("[%0d]: %m: foop4", $time);
  endrule


  interface Put pmem = toPut(pmemF);             // provide Put from pmemF
  method Action sendEvent (PMWCIEvent e) = evF.enq(e);  // capture envent in evF
endmodule


endpackage: ProtocolMonitor
