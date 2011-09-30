// TLPMF.bsv
// Copyright (c) 2009,2010.2011 Atomic Rules LLC, ALL RIGHTS RESERVED
//
//  Filename      : TLPMF.bsv
//  Author        : Shepard Siegel
//  Description   : Transaction Layer Packet Merge / Fork Modules
//
//  This module contains the upstream merge and downstream fork that forms the
//  basis of a TLP network. In both directions, individual packets are never split.
//  When a tie, the least recenty used source is chosen. Going downstream, a select
//  function is used to decode the packet header and determine if the packet is for
//  dn0 or dn1.
//
// 2009-02-25 sls Creation
// 2009-02-26 sls Combine Merge and Fork files at bottom of this file
// 2009-03-10 sls Rename to ServerMerge and ClientMerge

// For use with Bluesim, you need to undefine USE_SRLFIFO, as mkSRLFIFO is not yet a BSV 
// primative, it is importBVI of Atomic Rules Verilog...
//`define USE_SRLFIFO

package TLPMF;
import SRLFIFO::*;

import PCIE::*;
import FIFO::*;
import FIFOF::*;
import List::*;
import Vector::*;
import RegFile::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;

typedef Bit#(32)     DWord;
typedef TLPData#(16) PTW16;

interface OCTGIfc;
  interface Client#(PTW16,PTW16) client;
  interface Client#(PTW16,PTW16) client2;
endinterface

// Convienient PCIe functions...

function PciId insertFNum(PciId pcid, FuncNumber fn); // Take the pcid and replace the Function Number
  return (PciId{bus:pcid.bus, dev:pcid.dev, func:fn}); 
endfunction

// From original PCIe MemReqHdr1 and CompletionHdr...

typedef struct {
   Bool     isWrite;
   Bool     is4DW;
   Bit#(5)  pktType;
   Bit#(3)  trafficClass;
   Bool     hasDigest;
   Bool     isPoisoned;
   Bool     attrOrdering;
   Bool     attrNoSnoop;
   Bit#(10) length;
   PciId    requesterID;
   Bit#(8)  tag;
   Bit#(4)  lastDWByteEn;
   Bit#(4)  firstDWByteEn;
 } MemReqHdr1;

instance Bits#(MemReqHdr1,64);
  function Bit#(64) pack(MemReqHdr1 hdr);
    return { 1'b0, pack(hdr.isWrite), pack(hdr.is4DW), hdr.pktType,
             1'b0, hdr.trafficClass, 4'b0000,
             pack(hdr.hasDigest), pack(hdr.isPoisoned),
             pack(hdr.attrOrdering), pack(hdr.attrNoSnoop), 2'b00,
             hdr.length, pack(hdr.requesterID), hdr.tag,
             hdr.lastDWByteEn, hdr.firstDWByteEn };
   endfunction
  function MemReqHdr1 unpack(Bit#(64) w);
    return (MemReqHdr1 {
             isWrite: unpack(w[62]),
             is4DW: unpack(w[61]),
             pktType: w[60:56],
             trafficClass: w[54:52],
             hasDigest: unpack(w[47]),
             isPoisoned: unpack(w[46]),
             attrOrdering: unpack(w[45]),
             attrNoSnoop: unpack(w[44]),
             length: w[41:32],
             requesterID: unpack(w[31:16]),
             tag: w[15:8],
             lastDWByteEn: w[7:4],
             firstDWByteEn: w[3:0] });
   endfunction
endinstance

function MemReqHdr1 makeWrReqHdr (PciId rid, Bit#(10) len, Bit#(4) firstBE, Bit#(4) lastBE, Bool is64b);
  return (MemReqHdr1 {
    isWrite:       True,
    is4DW:         is64b,
    pktType:       '0,
    trafficClass:  '0,
    hasDigest:     False,
    isPoisoned:    False,
    attrOrdering:  False,
    attrNoSnoop:   False,
    length:        len,
    requesterID:   rid,
    tag:           '0,
    lastDWByteEn:  lastBE,
    firstDWByteEn: firstBE });
endfunction

typedef enum {
   SuccessfulCompletion = 0,
   UnsupportedRequest   = 1,
   ConfigReqRetryStatus = 2,
   CompleterAbort       = 4
 } CompletionStatus deriving (Eq, Bits);

typedef struct {
   Bool hasData;
   Bit#(3) trafficClass;
   Bool hasDigest;
   Bool isPoisoned;
   Bool attrOrdering;
   Bool attrNoSnoop;
   Bit#(10) length;

   PciId completerID;
   CompletionStatus status;
   Bool byteCountModified;
   Bit#(12) byteCount;

   PciId requesterID;
   Bit#(8) tag;
   Bit#(7) lowerAddress;
 } CompletionHdr;

instance Bits#(CompletionHdr,96);
   function Bit#(96) pack(CompletionHdr hdr);
      return { 1'b0, pack(hdr.hasData), 1'b0, 5'b01010,
               1'b0, hdr.trafficClass, 4'b0000,
               pack(hdr.hasDigest), pack(hdr.isPoisoned),
               pack(hdr.attrOrdering), pack(hdr.attrNoSnoop), 2'b00, hdr.length,
               pack(hdr.completerID), pack(hdr.status),
               pack(hdr.byteCountModified), hdr.byteCount,
	       pack(hdr.requesterID), hdr.tag, 1'b0, hdr.lowerAddress };
   endfunction
   function CompletionHdr unpack(Bit#(96) w);
      return (CompletionHdr {
                 hasData: unpack(w[94]),
                 trafficClass: w[86:84],
                 hasDigest: unpack(w[79]),
                 isPoisoned: unpack(w[78]),
                 attrOrdering: unpack(w[77]),
                 attrNoSnoop: unpack(w[76]),
                 length: w[73:64],
		 completerID: unpack(w[63:48]),
		 status: unpack(w[47:45]),
		 byteCountModified: unpack(w[44]),
		 byteCount: w[43:32],
                 requesterID: unpack(w[31:16]),
                 tag: w[15:8],
                 lowerAddress: w[6:0]
              });
   endfunction
endinstance

function CompletionHdr make2DWReadCompletion (PciId cid, PciId rid, Bit#(8) tag, Bit#(3) tc, Bool poison, Bit#(7) lowAddr);
   return (CompletionHdr {
              hasData: True,
              trafficClass: tc,
              hasDigest: False,
              isPoisoned: poison,
              attrOrdering: False,
              attrNoSnoop: False,
              length: 1,
	            completerID: cid,
              status: SuccessfulCompletion,
              byteCountModified: False,
              byteCount: 0,
              requesterID: rid,
              tag: tag,
              lowerAddress: lowAddr
           });
endfunction

function CompletionHdr makeReadCompletionHdr (PciId cid, PciId rid, Bit#(10) length, Bit#(8) tag, Bit#(3) tc, Bit#(7) lowAddr, Bit#(12) byteCount);
   return (CompletionHdr {
              hasData: True,
              trafficClass: tc,
              hasDigest: False,
              isPoisoned: False,
              attrOrdering: False,
              attrNoSnoop: False,
              length: length,
	            completerID: cid,
              status: SuccessfulCompletion,
              byteCountModified: False,
              byteCount: byteCount,
              requesterID: rid,
              tag: tag,
              lowerAddress: lowAddr
           });
endfunction



////////////////////////////////////////////////////////////////////////////////
/// Functions
////////////////////////////////////////////////////////////////////////////////

// data words received on PCIE are { byte0, byte1, byte2, byte3 }
// so we need to reverse the bytes in order to retrieve a 32-bit value
function Bit#(32) byteSwap(Bit#(32) w);
   Vector#(4, Bit#(8)) bytes = unpack(w);
   return pack(reverse(bytes));
endfunction

// For read-request completions,
// construct the lower 2 bits of the address from the first byte enable
function Bit#(2) byteEnToLowAddr(Bit#(4) firstBE);
   Bit#(2) lwaddr10 = ?;
   case(firstBE)
      4'b1110: lwaddr10 = 2'b01;
      4'b1100: lwaddr10 = 2'b10;
      4'b1000: lwaddr10 = 2'b11;
      default: lwaddr10 = 2'b00;
  endcase
  return lwaddr10;
endfunction

// For read-request completions
function Bit#(12) computeByteCount(Bit#(10) length,
                                   Bit#(4) firstBE, Bit#(4) lastBE);
   function Bit#(2) missingBytes(Bit#(4) be);
      case (be)
         4'b1111: return 2'b00;
         4'b1110: return 2'b01;
         4'b1100: return 2'b10;
         default: return 2'b11;
      endcase
   endfunction

   return ( {length, 2'b00}
            - zeroExtend(missingBytes(firstBE))
            - ( length == 1 ? 0 : zeroExtend(missingBytes(lastBE)) ) );
endfunction

function TLPData#(16) combineTLP8s(TLPData#(8) hi, TLPData#(8) lo);
   return TLPData {
		      data: { hi.data, lo.data },
		      be  : { hi.be  , lo.be   },
		      hit:  hi.hit,
		      sof:  hi.sof,
		      eof:  lo.eof
		      };
endfunction

function TLPData#(8) createInvalidTLP8(Bool hieof);
   return TLPData {
		      data: ?,
		      be  : 0,
		      hit:  ?,
		      sof:  ?,
		      eof:  !hieof
		      };
endfunction

function Tuple2#(TLPData#(8), TLPData#(8)) splitTLP16(TLPData#(16) hilo);
   TLPData#(8) hi = TLPData {
				   data: hilo.data[127:64],
				   be  : hilo.be  [15:8],
				   hit:  hilo.hit,
				   sof:  hilo.sof,
				   eof:  (hilo.be[7:0] == 0) ? hilo.eof : False
				   };
   TLPData#(8) lo = TLPData {
				   data: hilo.data[63:0],
				   be  : hilo.be[7:0],
				   hit:  hilo.hit,
				   sof:  False,
				   eof:  hilo.eof
				   };
   
   return tuple2(hi, lo);
endfunction



typedef struct {
  Bit#(18) dwAddr;   // DWord write address
  Bit#(4)  firstBE;  // Byte Lane Enables
  DWord    data;     // DWord Write Data
} WtDwReq deriving (Bits);

typedef struct {
  PciId    reqID;    // Requester Id bus/dev/func
  Bit#(18) dwAddr;   // DWord read address
  Bit#(4)  firstBE;  // First Byte Enable
  Bit#(2)  lwaddr10; // Byte address LSBs
  Bit#(8)  tag;      // Tag from requester
  Bit#(3)  tc;       // TC from requester
  Bool     poisoned; // True if poisoned
} RdDwReq deriving (Bits);

typedef struct {
  PciId    reqID;    // Requester Id bus/dev/func
  Bit#(7)  lowAddr;  // Low Address for Completion
  Bit#(8)  tag;      // Tag from requester
  Bit#(3)  tc;       // TC from requester
  Bool     poisoned; // True if poisoned
  DWord    data;     // 4B read response
} RdDwResp deriving (Bits);


// Ptw16Hdr: 2DW Header + 1DW Address + 1DW Data...
typedef struct {
  MemReqHdr1 hdr;    // 2DW PCIE header
  Bit#(30)   dwAddr; // DWord Address 31:2
  Bit#(32)   data;   // Data 0
} Ptw16Hdr;
//} Ptw16Hdr deriving (Bits);

instance Bits#(Ptw16Hdr,128);
  function Bit#(128) pack(Ptw16Hdr ph);
    return {pack(ph.hdr), pack(ph.dwAddr), 2'b00, pack(ph.data)};
  endfunction
  function Ptw16Hdr unpack(Bit#(128) w);
    return (Ptw16Hdr {hdr:unpack(w[127:64]), dwAddr:unpack(w[63:34]), data:unpack(w[31:0])});
  endfunction
endinstance


// Ptw16CompletionHdr: 3DW Header + 1DW Data...
typedef struct {
  CompletionHdr hdr;    // 3DW PCIE Completion Header / Transaction Descriptor
  Bit#(32)      data;   // Data 0
} Ptw16CompletionHdr;

instance Bits#(Ptw16CompletionHdr,128);
  function Bit#(128) pack(Ptw16CompletionHdr ph);
    return {pack(ph.hdr), pack(ph.data)};
  endfunction
  function Ptw16CompletionHdr unpack(Bit#(128) w);
    return (Ptw16CompletionHdr {hdr:unpack(w[127:32]), data:unpack(w[31:0])});
  endfunction
endinstance


function PTW16 makeWtDwReqTLP(Bit#(7) bar, Bit#(30) a, Bit#(32) wd);
  PciId  rid  = PciId {bus:255, dev:0, func:0};
  MemReqHdr1 h = makeWrReqHdr(rid, 1, '1, '0, False);
  return PTW16 {
    data : pack(Ptw16Hdr{hdr:h, dwAddr:a, data:byteSwap(wd)}),  // Perform DWORD byteSwap to get on TLP
    be   : '1,
    hit  : bar,
    sof  : True,
    eof  : True };
endfunction

function PTW16 makeWtNDwReqTLP(Bit#(7) bar, Bit#(30) a, Bit#(32) wd0, Bit#(10) dwLen);
  PciId  rid  = PciId {bus:255, dev:0, func:0};
  MemReqHdr1 h = makeWrReqHdr(rid, dwLen, '1, (dwLen==1)?'0:'1, False);
  return PTW16 {
    data : pack(Ptw16Hdr{hdr:h, dwAddr:a, data:byteSwap(wd0)}),  // Perform DWORD byteSwap to get on TLP
    be   : '1,
    hit  : bar,
    sof  : True,
    eof  : (dwLen==1) };
endfunction

function PTW16 makeRdDwReqTLP(Bit#(7) bar, Bit#(30) a, Bit#(8) tag);
  PciId  rid  = PciId {bus:255, dev:0, func:0};
  MemReqHdr1 h = makeRdReqHdr(rid, tag, 1, '1, '0, False);
  return PTW16 {
    data : pack(Ptw16Hdr{hdr:h, dwAddr:a, data:'0}),
    be   : '1,
    hit  : bar,
    sof  : True,
    eof  : True };
endfunction

function PTW16 makeRdNDwReqTLP(PciId rid, Bit#(7) bar, Bit#(30) a, Bit#(8) tag, Bit#(10) dwLen);
  MemReqHdr1 h = makeRdReqHdr(rid, tag, dwLen, '1, (dwLen==1)?'0:'1, False);
  return PTW16 {
    data : pack(Ptw16Hdr{hdr:h, dwAddr:a, data:'0}), be:remFromDW(3), hit:bar, sof:True, eof:True }; // 3DW Request
endfunction

function MemReqHdr1 makeRdReqHdr (PciId rid, Bit#(8) tag, Bit#(10) len, Bit#(4) firstBE, Bit#(4) lastBE, Bool is64b);
  return (MemReqHdr1 {
    isWrite       : False,
    is4DW         : is64b,
    pktType       : '0,
    trafficClass  : '0,
    hasDigest     : False,
    isPoisoned    : False,
    attrOrdering  : False,  // When set (relaxed): Read Completions are allowed to pass Memory Writes or Messages
    attrNoSnoop   : False,  // When set, NoSnoop means transactions targeting host memory don't need to snoop cache
    length        : len,
    requesterID   : rid,
    tag           : tag,
    lastDWByteEn  : lastBE,
    firstDWByteEn : firstBE });
endfunction

function Bit#(16) remFromDW(Bit#(2) dec);
  case (dec)
    2'b00 : return('hFFFF);
    2'b01 : return('hF000);
    2'b10 : return('hFF00);
    2'b11 : return('hFFF0);
  endcase
endfunction

typedef struct{
  Bit#(3)  bar;     // which bar
  Bit#(30) dwMask;  // which dwAddr bits are not significant in comparison (1=masked)
  Bit#(30) dwAddr;  // Requires State of address bits that un-masked to satisfy decode
} BarSub deriving (Bits, Eq);

typedef struct{
  Bit#(3)  bar;     // which bar
  Bit#(1)  top32K;  // True for top 32KB; Byte bit 11 set; DW bit 9 set
  Bit#(3)  func;    // for ID routed completions, which function number
} BarSub64 deriving (Bits, Eq);

typedef struct{
  Bit#(4)   addr;   // addr[28:25] match for MWr and MRd TLP routing
  BusNumber bus;    // for ID routed completions, which bus number
} RouteSub deriving (Bits, Eq);

typedef union tagged {
  Bit#(3)   Bar;
  Bit#(8)   Bus;
  BarSub64  Bar64;
  RouteSub  Route;
} PktForkKey deriving (Bits);

// TLP "ClientMerge" - used to merge multiple client interfaces (e.g. typicaly aggregate requestors)...
interface TLPCMIfc;
  interface Client#(PTW16,PTW16) c;   // facing upstream requests
  interface Server#(PTW16,PTW16) s0;  // facing this device
  interface Server#(PTW16,PTW16) s1;  // facing downstream devices
endinterface

(* synthesize *)
module mkTLPCM#(PktForkKey pfk) (TLPCMIfc);
  PktMergeIfc  pktMerge  <- mkPktMerge;
  PktForkIfc   pktFork   <- mkPktFork(pfk);

  interface Client c;
    interface request  = pktMerge.oport;   // Traffic headed upstream
    interface response = pktFork.iport;    // Traffic headed downstream
  endinterface
  interface Server s0;
    interface request  = pktMerge.iport0;  // Traffic from this device
    interface response = pktFork.oport0;   // Traffic to this device
  endinterface
  interface Server s1;
    interface request  = pktMerge.iport1;  // Traffic headed upstream
    interface response = pktFork.oport1;   // Traffic headed downstream
  endinterface
endmodule: mkTLPCM

// TLP "ServerMerge" - used to merge multiple server interfaces (e.g. typicaly aggregate completors)
interface TLPSMIfc;
  interface Server#(PTW16,PTW16) s;
  interface Client#(PTW16,PTW16) c0;
  interface Client#(PTW16,PTW16) c1;
endinterface

(* synthesize *)
module mkTLPSM#(PktForkKey pfk) (TLPSMIfc);
  PktMergeIfc  pktMerge  <- mkPktMerge;
  PktForkIfc   pktFork   <- mkPktFork(pfk);

  interface Server s;
    interface request  = pktFork.iport;
    interface response = pktMerge.oport;
  endinterface
  interface Client c0;
    interface request  = pktFork.oport0;
    interface response = pktMerge.iport0;
  endinterface
  interface Client c1;
    interface request  = pktFork.oport1;
    interface response = pktMerge.iport1;
  endinterface
endmodule: mkTLPSM


// TLP "ClientNode" - used to construct networks with a client attaches...
interface TLPClientNodeIfc;
  interface Server#(PTW16,PTW16) s;
  interface Put#(PTW16)          p;
  interface Get#(PTW16)          g;
endinterface

(* synthesize *)
module mkTLPClientNode#(PktForkKey pfk) (TLPClientNodeIfc);
  PktMergeIfc  pktMerge  <- mkPktMerge;
  PktForkIfc   pktFork   <- mkPktFork(pfk);

  mkConnection(pktFork.oport1, pktMerge.iport1);
  interface Put p = pktFork.iport;
  interface Get g = pktMerge.oport;
  interface Server s;
    interface request  = pktMerge.iport0;
    interface response = pktFork.oport0;
  endinterface
endmodule: mkTLPClientNode

// TLP "ServerNode" - used to construct networks where a server attaches...
interface TLPServerNodeIfc;
  interface Client#(PTW16,PTW16) c;
  interface Put#(PTW16)          p;
  interface Get#(PTW16)          g;
endinterface

(* synthesize *)
module mkTLPServerNode#(PktForkKey pfk) (TLPServerNodeIfc);
  PktMergeIfc  pktMerge  <- mkPktMerge;
  PktForkIfc   pktFork   <- mkPktFork(pfk);

  mkConnection(pktFork.oport1, pktMerge.iport1);
  interface Put p = pktFork.iport;
  interface Get g = pktMerge.oport;
  interface Client c;
    interface request  = pktFork.oport0;
    interface response = pktMerge.iport0;
  endinterface
endmodule: mkTLPServerNode



// PktMerge.bsv - Merge two packet streams without segmentation 
// Copyright (c) 2009 Atomic Rules LLC, ALL RIGHTS RESERVED
// Author: Shepard.Siegel@atomicrules.com
//
// Embellishes the basic merge operation with xActive temporal state bits so that
// the merge never splits a packet. The packet type must have a member eof which is true
// on the last cycle of the packet.

interface PktMergeIfc;
  interface Put#(PTW16) iport0;
  interface Put#(PTW16) iport1;
  interface Get#(PTW16) oport;
endinterface

(* synthesize *)
module mkPktMerge (PktMergeIfc);

`ifdef USE_SRLFIFO
  FIFOF#(PTW16) fi0        <- mkSRLFIFOD(4);
  FIFOF#(PTW16) fi1        <- mkSRLFIFOD(4);
  FIFOF#(PTW16) fo         <- mkSRLFIFOD(4);
`else
  FIFOF#(PTW16) fi0        <- mkFIFOF;  // FIFO size may be reduced to 1 with reduced throughput 
  FIFOF#(PTW16) fi1        <- mkFIFOF;
  FIFOF#(PTW16) fo         <- mkFIFOF;
`endif

  Reg#(Bool)    fi0HasPrio <- mkReg(True);   // True when fi0 has priority
  Reg#(Bool)    fi0Active  <- mkReg(False);  // True on the 2nd to end cycle of fi0 packet
  Reg#(Bool)    fi1Active  <- mkReg(False);  // True on the 2nd to end cycle of fi1 packet


  (* descending_urgency = "arbitrate, fi0_advance, fi1_advance" *)
  // The first two rules handle the non-contending 1st cycle and all 2-n cycle cases...
  rule fi0_advance (!fi1Active);
    let x = fi0.first; fi0.deq; fo.enq(x);
    fi0Active  <= !x.eof;
    fi0HasPrio <= False;
  endrule

  rule fi1_advance (!fi0Active);
    let x = fi1.first; fi1.deq; fo.enq(x);
    fi1Active  <= !x.eof;
    fi0HasPrio <= True;
  endrule

  // The arbitrate rule handles the contending 1st cycle case by LRU.
  // Both inputs are available, but neither is yet active...
  rule arbitrate (fi0.notEmpty && fi1.notEmpty && !fi0Active && !fi1Active);
    FIFOF#(PTW16) fi = ((fi0HasPrio) ? fi0 : fi1);
    let x = fi.first; fi.deq; fo.enq(x);
    if (fi0HasPrio) fi0Active <= !x.eof;
    else            fi1Active <= !x.eof;
    fi0HasPrio <= !fi0HasPrio;
    $display("[%0d]: %m: Merge from:%d Data:%x", $time, fi0HasPrio, x.data);
  endrule

 interface iport0 = toPut(fi0);
 interface iport1 = toPut(fi1);
 interface oport  = toGet(fo);

endmodule: mkPktMerge



// PktFork.bsv - Fork packet stream
// Copyright (c) 2009 Atomic Rules LLC, ALL RIGHTS RESERVED
// Author: Shepard.Siegel@atomicrules.com
//
// Embellishes the basic fork operation.

interface PktForkIfc;
  interface Put#(PTW16) iport;
  interface Get#(PTW16) oport0;
  interface Get#(PTW16) oport1;
endinterface

(* synthesize *)
module mkPktFork#(PktForkKey pfk) (PktForkIfc);

`ifdef USE_SRLFIFO
  FIFOF#(PTW16) fi        <- mkSRLFIFOD(4);
  FIFOF#(PTW16) fo0       <- mkSRLFIFOD(4);
  FIFOF#(PTW16) fo1       <- mkSRLFIFOD(4);
`else
  FIFO#(PTW16) fi         <- mkFIFO;  // FIFO size may be reduced to 1 with reduced throughput 
  FIFO#(PTW16) fo0        <- mkFIFO;
  FIFO#(PTW16) fo1        <- mkFIFO;
`endif

  Reg#(Bool)   f0Active   <- mkReg(False);  // True on the 2nd to end cycle of input packet
  Reg#(Bool)   f1Active   <- mkReg(False);  // True on the 2nd to end cycle of input packet

  function Bool fork0(PTW16 x);
  Ptw16CompletionHdr p = unpack(x.data);  // defined here 4DW (3DW comp hdr + 1 DW data)
  Ptw16Hdr    z = unpack(x.data);         // defined here 4DW (2DW req hdr + 1 DW addr + 1 DW data)
  DWAddress dwAddr = z.dwAddr;
    case (pfk) matches
      tagged Bar   .bar: return(x.hit==1<< bar);
      tagged Bar64 .b64: 
        if (z.hdr.pktType==5'b01010) return(p.hdr.requesterID.func==b64.func);  // if a completion, Fork on function match
        else return((x.hit==1<<b64.bar) && (b64.top32K[0]==dwAddr[13]));
      tagged Bus   .bus:   return((p.hdr.requesterID.bus==bus)&&(z.hdr.pktType==5'b01010));
      tagged Route .route: 
        if (z.hdr.pktType==5'b01010) return((p.hdr.requesterID.bus==route.bus));
        else return(route.addr==dwAddr[26:23]);
    endcase
  endfunction

  (* descending_urgency = "fo0_advance, fo1_advance" *)

  rule fo0_advance (f0Active);
    let x = fi.first; fi.deq; fo0.enq(x);
    f0Active <= !x.eof;
  endrule

  rule fo1_advance (f1Active);
    let x = fi.first; fi.deq; fo1.enq(x);
    f1Active <= !x.eof;
  endrule

  // The 0 port gets the fork-select...
  rule select (!f0Active && !f1Active);
    let x = fi.first; fi.deq;
    if (fork0(x)) begin
      fo0.enq(x); f0Active <= !x.eof;
    end else begin
      fo1.enq(x); f1Active <= !x.eof;
    end
  endrule

 interface iport  = toPut(fi);
 interface oport0 = toGet(fo0);
 interface oport1 = toGet(fo1);

endmodule: mkPktFork


// Utilitiy Modules for the production and consumption of TLP requests and completions...

typedef struct {
  MemReqHdr1 hdr;
  Bit#(7)    bar;
  Bit#(30)   dwAddr;
} MemReq32 deriving (Bits);

typedef struct {
  PciId    reqID;
  Bit#(3)  tc;
  Bit#(8)  tag;
  Bit#(7)  lowAddr;
  Bit#(10) dwLength;
  Bit#(12) byteCount;
} ComplInfo deriving (Bits);

interface TLPInitiatorIfc;
  interface Put#(MemReq32) request;  // TLP requests in
  interface Put#(Bit#(32)) wdata;    // write data in
  interface Get#(Bit#(32)) rdata;    // read data out
  interface Client#(PTW16,PTW16) client;
endinterface

interface TLPTargetIfc;
  interface Server#(PTW16,PTW16) server;
  interface Get#(MemReq32) request;  // TLP requests out
  interface Get#(Bit#(32)) wdata;    // write data out
  interface Put#(Bit#(32)) rdata;    // read data in
endinterface

typedef union tagged {
  void     Idle;
  Bit#(10) WtDWRemain;
  Bit#(10) RdDWRemain;
} RemainCount deriving (Bits, Eq);

typedef enum {Idle,WtPush,WtFinal} WtStage deriving (Bits, Eq);

module mkTLPInitiator#(PciId pciDevice) (TLPInitiatorIfc);
  FIFO#(MemReq32)            reqF      <- mkFIFO;          // Initiator requests in
  FIFO#(Bit#(32))            wdF       <- mkFIFO;          // Write Data to TLP
  FIFO#(Bit#(32))            rdF       <- mkFIFO;          // Read Data 
  FIFO#(ComplInfo)           cmpF      <- mkFIFO;          // Read completion info
  FIFO#(PTW16)               outF      <- mkFIFO;          // outbound request TLPs
  FIFO#(PTW16)               inF       <- mkFIFO;          // inbound completion TLPs
  Reg#(Bit#(7))              wBar      <- mkRegU;          // storage of BAR
  Reg#(RemainCount)          dwr       <- mkReg(Idle);     // state for packet body
  Reg#(Bit#(3))              wdp       <- mkReg(0);        // write data pointer
  Reg#(Vector#(4,Bit#(32)))  wdv       <- mkRegU;          // write data vector
  Reg#(WtStage)              wss       <- mkReg(Idle);     // write stage state
  Reg#(Maybe#(Bit#(2)))      rdp       <- mkReg(Invalid);  // read data pointer
  Reg#(Vector#(4,Bit#(32)))  rdv       <- mkRegU;          // read data vector
  Reg#(Bool)                 rdPayld   <- mkReg(False);    // read payload enabled

  // The outbound request...
  rule tlpTxHead (dwr matches tagged Idle);
    MemReq32 mr <- toGet(reqF).get;
    Bit#(32) wDW = ?;
    Bit#(10) dwLen = mr.hdr.length;
    Bool isWrite = mr.hdr.isWrite;
    wBar <= mr.bar;
    if (isWrite) begin  // write specific...
      if (dwLen!=1) dwr <= WtDWRemain(dwLen-1);
      wDW <- toGet(wdF).get;
    end else begin      // read specific...
      dwr <= RdDWRemain(mr.hdr.length);
      Bit#(2)  lowAddr10 = byteEnToLowAddr(mr.hdr.firstDWByteEn);
      Bit#(7)  lowAddr = {truncate(mr.hdr.length), lowAddr10};
      ComplInfo ci = ComplInfo {
        reqID     : pciDevice,
        tc        : mr.hdr.trafficClass,
        tag       : mr.hdr.tag,
        lowAddr   : lowAddr,
        dwLength  : mr.hdr.length,
        byteCount : computeByteCount(mr.hdr.length,mr.hdr.firstDWByteEn,mr.hdr.lastDWByteEn) };
      cmpF.enq(ci);
    end
    PTW16 pw = PTW16 {
      data : pack(Ptw16Hdr{hdr:mr.hdr, dwAddr:mr.dwAddr, data:isWrite?byteSwap(wDW):?}),
      be   : '1,
      hit  : mr.bar,
      sof  : True,
      eof  : isWrite?(dwLen==1):True };
    outF.enq(pw);
  endrule

  // While there are more DWords to stage, and storage available, stage the 4B write data for transmission...
  rule stageWtData (wdp<4 &&& dwr matches tagged WtDWRemain .wdr);
    let wdata <- toGet(wdF).get;              // get new write data
    wdv <= shiftInAt0(wdv, byteSwap(wdata));  // shift it in, endian byteSwap
    wdp <= wdp + 1;                           // update head pointer
    dwr <= WtDWRemain(wdr-1);                 // decrement write remaining
    if      (wdr==1) wss <= WtFinal;          // last DW has been staged
    else if (wdp==3) wss <= WtPush;           // 4 DWs have been staged
  endrule

  // When we have staged enough write data for one 16B push; or to flush the final one..
  rule tlpTxWtData (wss!=Idle);
    UInt#(2) rot = unpack(truncate(3'h4-wdp));
    Vector#(4, DWord) vdw = rotateBy(wdv,rot);
    Bit#(16) lastRema =
      case (wdp[1:0])
        2'b00 : 'hFFFF;
        2'b01 : 'hF000;
        2'b10 : 'hFF00;
        2'b11 : 'hFFF0;
      endcase;
    PTW16 pw = PTW16 {
      data : pack(vdw),
      be   : (wss==WtFinal)?lastRema:'1,
      hit  : wBar,
      sof  : False,
      eof  : (wss==WtFinal) };
    outF.enq(pw);
    // Reset for next use...
    wdp <= 0;
    if (wss==WtFinal) begin
      dwr <= Idle;
      wss <= Idle;
    end
  endrule

  function Bool tagMatch(Bit#(8) tagm, PTW16 t);
    CompletionHdr ch = unpack(t.data[127:32]);
    return(tagm==ch.tag);
  endfunction 

  // The inbound read completion header...
  rule tlpRxHead (!rdPayld &&& tagMatch(cmpF.first.tag, inF.first) &&& dwr matches tagged RdDWRemain .rdr);
    let rh <- toGet(inF).get;
    let rd = byteSwap(rh.data[31:0]);
    rdF.enq(rd);
    if (rdr>1) rdPayld <= True;
    else       dwr     <= Idle;
  endrule

  // Subsequent inbound 16B chunks for serialization...
  rule tlpRxRdData(rdPayld &&& dwr matches tagged RdDWRemain .rdr);
    let rd <- toGet(inF).get;
    rdv <= unpack(pack(rd.data));
    rdp <= Valid(3);
  endrule

  // Subtract from RdDWRemain at the far end as we enq DWs to the read data FIFO...
  rule serializeRdData(dwr matches tagged RdDWRemain .rdr &&& rdp matches tagged Valid .rp);
    rdF.enq(rdv[rp]);
    dwr <= RdDWRemain(rdr-1);
    rdp <= (rp==0 || rdr==1) ? Invalid : Valid(rp-1);
    if (rdr==1) begin
      dwr     <= Idle;
      rdPayld <= False;
    end
  endrule

  interface request = toPut(reqF);
  interface wdata   = toPut(wdF);
  interface rdata   = toGet(rdF);
  interface Client client;
    interface request  = toGet(outF);
    interface response = toPut(inF); 
  endinterface
endmodule


//TODO: Consdider that this is similar to the target TLPSerializer used by the control plane...
module mkTLPTarget#(PciId pciDevice) (TLPTargetIfc);
  FIFO#(PTW16)          inF       <- mkFIFO;   // inbound request TLPs
  FIFO#(PTW16)          outF      <- mkFIFO;   // outbound completion TLPs
  FIFO#(MemReq32)       reqF      <- mkFIFO;   // Initiator requests out
  FIFO#(ComplInfo)      cmpF      <- mkFIFO;   // Read completion info
  FIFO#(Bit#(32))       wdF       <- mkFIFO;   // Write Data from TLP
  FIFO#(Bit#(32))       rdF       <- mkFIFO;   // Read Data to TLP

  interface Server server;
    interface request  = toPut(inF);
    interface response = toGet(outF); 
  endinterface
  interface request = toGet(reqF);
  interface wdata   = toGet(wdF);
  interface rdata   = toPut(rdF);
endmodule

endpackage: TLPMF
