// WSIAXIS.bsv - Unidirectional Adapters between WSI and AXI4-Stream
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package WSIAXIS;

import ARAXI4S::*;
import OCWip::*;

import Bus::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import FIFOLevel::*;	
import GetPut::*;
import SpecialFIFOs::*;

// Shorthand used in this module...
typedef A4Stream#(32,4,0,128) NF10DPM4B;
typedef A4S_Em  #(32,4,0,128) NF10DPEM4B;
typedef A4Stream#(32,4,0,128) NF10DPS4B;
typedef A4S_Es  #(32,4,0,128) NF10DPES4B;

typedef struct {
  Bit#(96)  umeta;  // user metadata
  Bit#(8)   dpt;    // opcode to DP1
  Bit#(8)   spt;    // opcode from DP0
  UInt#(16) length; // transfer length in Bytes
} AxiInfo deriving (Bits);

// For the bit vector bin, count the number of 1s until the first 0,
// starting from the least signigcant bit (LSB).
function UInt#(lgn1) countOnesLSB (Bit#(n) bin) provisos (Add#(1, n, n1), Log#(n1, lgn1) );
  return(countZerosLSB(~bin));
endfunction

// The modules below adapt between WSI and AXI-Stream (AXIS)
// They use the established WSI convienience IP mkWsi{Master|Slave}, 
// but implement "in-place" the AXIfication, as the AXI spec can be volatile.
// At some point, the AXI side could be moved to a mkAXIStream{Master|Slave} convienience IP.
// For now, it is right here.

//4B WSI->AXI...
interface WSItoAXIS4BIfc;
  interface Put#(WsiReq#(12,32,4,8,0))  reqPut;   // The WSI Request Put
  interface NF10DPEM4B axi;      // NF10-Specialized AXI4-Stream Master
  method Action        operate;  // Assert to operate
endinterface 

module mkWSItoAXIS4B (WSItoAXIS4BIfc);
  FIFOF#(WsiReq#(12,32,4,8,0))     reqFifo    <- mkFIFOF;
  BusSender#(NF10DPM4B)            axiM       <- mkBusSender(aStrmDflt);
  Reg#(Bool)                       operateD   <- mkDReg(False);

  A4StreamMIfc#(32,4,0,128) axisDatM = A4StreamMIfc { strm : axiM.out};  // Place strm sub-interface in axisM interface

  rule advance_data (operateD);
    WsiReq#(12,32,4,8,0) w = reqFifo.first; reqFifo.deq;
    // Note we use a endian-neutral method of countOnes to determine th exact message length...
    UInt#(16) xfrLengthInBytes = extend((unpack(w.burstLength)-1)*4)  + extend(countOnes(w.byteEn)); // Calculate exact Byte length
    let aui = AxiInfo {length:xfrLengthInBytes, spt:w.reqInfo, dpt:8'h01, umeta:0};
    axiM.in.enq( A4Stream { data : w.data,
                            strb : w.byteEn,     // AXI strobes come directly from WSI byte-enables
                            user : pack(aui),
                            keep : 0,
                            last : w.reqLast });
  endrule

  A4S_Em#(32,4,0,128)   axi_Em    <- mkA4StreamMtoEm(axisDatM);
  interface reqPut = toPut(reqFifo);
  interface NF10DPEM4B axi = axi_Em;
  method Action operate = operateD._write(True);
endmodule


//4B AXI->WSI
interface AXIStoWSI4BIfc;
  interface NF10DPES4B axi;      // NF10-Specialized AXI4-Stream Slave
  interface Get#(WsiReq#(12,32,4,8,0)) reqGet;   // The WSI Request Get
  method Action        operate;  // Assert to operate
endinterface 

module mkAXIStoWSI4B (AXIStoWSI4BIfc);
  BusReceiver#(NF10DPS4B)                axiS        <- mkBusReceiver;
  FIFOLevelIfc#(WsiReq#(12,32,4,8,0),3)  reqFifo     <- mkFIFOLevel;
  Reg#(Bool)                             operateD    <- mkDReg(False);
  Reg#(Bool)                             xfrActive   <- mkReg(False);
  Reg#(Bit#(2))                          xfrLenLSBs  <- mkReg(0);

  A4StreamSIfc#(32,4,0,128) axisDatS = A4StreamSIfc { strm : axiS.in};  // Place strm sub-interface in axisS interface

  rule advance_data (operateD);
    let a = axiS.out.first; axiS.out.deq;
    AxiInfo aui = unpack(a.user);
    // Although aui.length contains the exact length in Bytes; we must disribute the information on both burstLenth and byteEn...
    reqFifo.enq( WsiReq {   cmd  : WR,
                         reqLast : a.last,
                         reqInfo : aui.dpt,                       // opcode comes in on dpt
                    burstPrecise : True,
                     burstLength : truncate(pack(aui.length)>>2), // WSI burstLength is only accurate to 4B bounds
                           data  : a.data,
                         byteEn  : a.strb,  
                       dataInfo  : '0 });
    xfrActive <= !a.last;                                // Keep track if this is an active transfer - NO BUBBLES ALLOWED - No way to indicate
    if (!xfrActive) xfrLenLSBs <= pack(aui.length)[1:0]; // sample the TUSER Length LSBs for use in the last cycle
  endrule

  A4S_Es#(32,4,0,128) axi_Es <- mkA4StreamStoEs(axisDatS);
  interface NF10DPES4B axi = axi_Es;
  interface reqGet = toGet(reqFifo);
  method Action operate = operateD._write(True);
endmodule

endpackage
