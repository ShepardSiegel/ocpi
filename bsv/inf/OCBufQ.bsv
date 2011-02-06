// OCBufQ.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

// We distinguish between four possible roles:
// Fabric Producer vs. Fabric Consumer (eg Fabric Source or Sink of message data)
// Active vs. Passive (Active actively "pushes" or "pulls"; Passive is "pushed-to" or "pulled-from")
// We have a single module which serves all four roles...
//  Becoming active-passive agnostic means our interface indications are DMA/PIO agnostic
//  Becoming producer-consumer agnostic means that we abstract Egress and INgress to "Ngress" and
//   in the two cases where there is an asymmetry based on role of FProducer or FConsumer
//
// Fabric Producer
//  Active  - Local DMA pushes (writes) data to remote node...
//  Passive - Remote pulls (reads) data from local node...
//
// Fabric Consumer 
//  Active  - Local DMA pulls (reads) data from remote node...
//  Passive - Remote pushes (writes) data to local node...
//
// Remote Ngress = {Egress for fabric producer |  INgress for fabric consumer}

package OCBufQ;

import OCWip::*;
import CounterM::*;
import DReg::*;
import Connectable::*;

// TODO: There should be a single place to specify the buffer size - and supply the control-plane with the info
// Data Buffer BRAM Address and Data Widths...
//typedef 16384                       DPBufSizeBytes;      // *** Set DP Buffer Size here ***
typedef 32768                       DPBufSizeBytes;      // *** Set DP Buffer Size here ***
typedef TDiv#(DPBufSizeBytes,16)    DPBufSizeInHWords;  
typedef TLog#(DPBufSizeBytes)       DPLogBufSizeBytes;
typedef TSub#(DPLogBufSizeBytes,2)  DPLogBufSizeDWords;
typedef TSub#(DPLogBufSizeBytes,4)  DPLogBufSizeHWords;

typedef Bit#(DPLogBufSizeBytes)  DPBufBAddr;   // A DP Buffer Byte Address
typedef Bit#(DPLogBufSizeDWords) DPBufDWAddr;  // A DP Buffer DW   Address
typedef Bit#(DPLogBufSizeHWords) DPBufHWAddr;  // A DP Buffer HW   Address

typedef enum {Disabled,FProducer,FConsumer,Rsvd} DPDirection deriving (Bits,Eq);
typedef enum {Passive,ActMesg,ActFlow,Rsvd}      DPRole      deriving (Bits,Eq);
typedef struct {
  DPDirection dir;
  DPRole      role;
} DPControl deriving (Bits,Eq);
DPControl defaultDPControl = DPControl{dir:Disabled,  role:Passive}; 
DPControl fProdActMesg     = DPControl{dir:FProducer, role:ActMesg}; 
DPControl fConsActMesg     = DPControl{dir:FConsumer, role:ActMesg}; 

/* Embellished version for future use...
typedef struct {
  Bool        moveData;
  Bool        moveMeta;
  Bool        sendTail;
  Bool        sendInterrupt;
  DPDirection dir;
  DPRole      role;
} DPControl deriving (Bits,Eq);
DPControl defaultDPControl = DPControl{moveData:False, moveMeta:False, sendTail:False, sendInterrupt:False, dir:Disabled,  role:Passive}; 
DPControl fProdActMesg     = DPControl{moveData:?    , moveMeta:?    , sendTail:?    , sendInterrupt:?    , dir:FProducer, role:ActMesg}; 
DPControl fConsActMesg     = DPControl{moveData:?    , moveMeta:?    , sendTail:?    , sendInterrupt:?    , dir:FConsumer, role:ActMesg}; 
*/

interface BufQSIfc;          // Provided by mkFabPC to each the local and remote
  method Action    start;    // Start of Message Movement Pulse
  method Action    done;     // Done with Message Movement Pulse
  method Action    fabric;   // Fabric Event Pulse
  method Bool      rdy;      // Buffer Ready Indication (Level)
  method Bool      frdy;     // Far-Side Buffer Ready Indication (Level)
  method Bool      credit;   // Permission to send credits
  method Bit#(16)  bufMeta;  // Current buffer meta data Byte address
  method Bit#(16)  bufMesg;  // Current buffer mesg data Byte address
  method Bit#(32)  fabMeta;  // Current fabric meta data Byte address
  method Bit#(32)  fabMesg;  // Current fabric mesg data Byte address
  method Bit#(32)  fabFlow;  // Current fabric flow ctrl Byte address
endinterface

interface BufQCIfc;          // Provided by the local and remote (client dual of server above)
  method Bool      start;
  method Bool      done; 
  method Bool      fabric;
  method Action    rdy;
  method Action    frdy;
  method Action    credit;
  method Action    bufMeta (Bit#(16) bMeta);
  method Action    bufMesg (Bit#(16) bMesg);
  method Action    fabMeta (Bit#(32) fMeta);
  method Action    fabMesg (Bit#(32) fMesg);
  method Action    fabFlow (Bit#(32) fFlow);
endinterface

instance Connectable#( BufQSIfc, BufQCIfc );
  module mkConnection#( BufQSIfc server, BufQCIfc client ) ();
    rule rStart  (client.start); server.start;     endrule
    rule rDone   (client.done);  server.done;      endrule
    rule rFabric (client.fabric);  server.fabric;  endrule
    rule rRdy    (server.rdy);   client.rdy;       endrule
    rule rFRdy   (server.frdy);  client.frdy;      endrule
    rule rCredit (server.credit);  client.credit;  endrule
    rule rBMeta;  client.bufMeta(server.bufMeta);  endrule
    rule rBMesg;  client.bufMesg(server.bufMesg);  endrule
    rule rFMeta;  client.fabMeta(server.fabMeta);  endrule
    rule rFMesg;  client.fabMesg(server.fabMesg);  endrule
    rule rFFlow;  client.fabFlow(server.fabFlow);  endrule
  endmodule
endinstance

typedef struct {
  Bit#(16) lbar;
  Bit#(16) lbcf;
  Bit#(16) rba;
  Bit#(16) lclIndex;
  Bit#(16) remIndex;
  Bit#(16) lclStarts;
  Bit#(16) lclDones;
  Bit#(16) remStarts;
  Bit#(16) remDones;
} BufState deriving (Bits);

interface FabPCIfc;
  method BufState bs;       // Provide the internal state
  interface BufQSIfc lcl;   // Provide the BufQ Server Interface to the Local WMI Side
  interface BufQSIfc rem;   // Provide the BufQ Server Interface to the Remote TLP Side
  interface Reg#(Bit#(16)) i_lclNumBufs;
  interface Reg#(Bit#(16)) i_fabNumBufs;
  interface Reg#(Bit#(16)) i_mesgSize;
  interface Reg#(Bit#(16)) i_metaSize;
  interface Reg#(Bit#(16)) i_mesgBase;   
  interface Reg#(Bit#(16)) i_metaBase;   
  interface Reg#(Bit#(32)) i_fabMesgSize;
  interface Reg#(Bit#(32)) i_fabMetaSize;
  interface Reg#(Bit#(32)) i_fabFlowSize;
  interface Reg#(Bit#(32)) i_fabMesgBase;   
  interface Reg#(Bit#(32)) i_fabMetaBase;   
  interface Reg#(Bit#(32)) i_fabFlowBase;   
  method Action dpCtrl (DPControl dc);
endinterface 

module mkFabPC#(WciSlaveIfc#(32) wci) (FabPCIfc);
  Reg#(Bool)          lclBufStart     <- mkDReg(False);         // local buffer start
  Reg#(Bool)          lclBufDone      <- mkDReg(False);         // local buffer done
  Reg#(Bool)          remStart        <- mkDReg(False);         // remote buffer start
  Reg#(Bool)          remDone         <- mkDReg(False);         // remote buffer done
  Reg#(Bool)          fabDone         <- mkDReg(False);         // fabric buffer event
  Reg#(Bool)          fabAvail        <- mkDReg(False);         // fabric buffer event
  CounterM#(Bit#(16)) lclBuf          <- mkCounterM;            // Local  Buffer Index
  CounterM#(Bit#(16)) remBuf          <- mkCounterM;            // Remote Buffer Index
  CounterM#(Bit#(16)) fabBuf          <- mkCounterM;            // Fabric Buffer Index
  CounterM#(Bit#(16)) crdBuf          <- mkCounterM;            // Credit Buffer Index
  Reg#(Bit#(16))      fabBufsAvail    <- mkRegU;                // Fabric Buffers Available
  Reg#(Bit#(16))      lclBufsCF       <- mkRegU;                // Producer:lclBufsCommitted; Consumer:lclBufsFreed
  Reg#(Bit#(16))      lclBufsAR       <- mkRegU;                // Producer:lclBufsAvailable; Consumer:lclBufsReady
  Reg#(Bit#(16))      lclCredit       <- mkRegU;                // 
  Reg#(Bit#(16))      lclStarts       <- mkReg(0);              // diagnostic rolling count (reset by reset)
  Reg#(Bit#(16))      lclDones        <- mkReg(0);              // diagnostic rolling count (reset by reset)
  Reg#(Bit#(16))      remStarts       <- mkReg(0);              // diagnostic rolling count (reset by reset)
  Reg#(Bit#(16))      remDones        <- mkReg(0);              // diagnostic rolling count (reset by reset)
  Reg#(Bit#(16))      lclMetaAddr     <- mkRegU;                // The local  metadata   address accumulator
  Reg#(Bit#(16))      lclMesgAddr     <- mkRegU;                // The local  mesgbuffer address accumulator
  Reg#(Bit#(16))      remMetaAddr     <- mkRegU;                // The remote metadata   address accumulator
  Reg#(Bit#(16))      remMesgAddr     <- mkRegU;                // The remote mesgbuffer address accumulator
  Reg#(Bit#(32))      fabMetaAddr     <- mkRegU;                // The fabric metadata   address accumulator
  Reg#(Bit#(32))      fabMesgAddr     <- mkRegU;                // The fabric mesgbuffer address accumulator
  Reg#(Bit#(32))      fabFlowAddr     <- mkRegU;                // The fabric flow ctrl  address accumulator
  Reg#(Bit#(16))      lclNumBufs      <- mkReg(1);              // the number of local  buffers
  Reg#(Bit#(16))      fabNumBufs      <- mkReg(1);              // the number of fabric buffers
  Reg#(Bit#(16))      mesgSize        <- mkReg(16'h0800);       // message size (in Bytes)
  Reg#(Bit#(16))      metaSize        <- mkReg(16'h0010);       // metadata size (in Bytes)
  Reg#(Bit#(16))      mesgBase        <- mkReg(16'h0000);       // message  base address (in Bytes)
  Reg#(Bit#(16))      metaBase        <- mkReg(16'h3800);       // metadata base address (in Bytes)
  Reg#(Bit#(32))      fabMesgSize     <- mkReg(32'h0000_0800);  // Fabric message-buffer size   (in Bytes)
  Reg#(Bit#(32))      fabMetaSize     <- mkReg(32'h0000_0010);  // Fabric metadata buffer size  (in Bytes)
  Reg#(Bit#(32))      fabFlowSize     <- mkReg(32'h0000_0004);  // Fabric flow ctrl       size  (in Bytes)
  Reg#(Bit#(32))      fabMesgBase     <- mkReg(32'hFFFF_0000);  // Fabric message  base address (in Bytes)
  Reg#(Bit#(32))      fabMetaBase     <- mkReg(32'hFFFF_3800);  // Fabric metadata base address (in Bytes)
  Reg#(Bit#(32))      fabFlowBase     <- mkReg(32'hFFFF_0018);  // Fabric flowctrl base address (in Bytes)
  Wire#(DPControl)    dpControl       <- mkWire;

  (* fire_when_enabled *)
  rule initAccumulators (wci.ctlState==Initialized && wci.ctlOp==Start);
    if (dpControl.dir==FProducer)  begin
      lclBufsAR    <= lclNumBufs;  // Producer starts all  Available
      lclBufsCF    <= 0;           // Producer starts none Committed 
      lclCredit    <= 0;
      fabBufsAvail <= (dpControl.role==ActMesg)?fabNumBufs:0; // Producer starts knowing all fabric buffers are Available
    end else begin
      lclBufsAR    <= 0;           // Consumer starts none Ready
      lclBufsCF    <= lclNumBufs;  // Consumer start all Free
      lclCredit    <= 0;
      fabBufsAvail <= 0;           // Consumer starts knowing no fabric buffers are Available
    end
    lclMetaAddr  <= metaBase;    remMetaAddr <= metaBase;
    lclMesgAddr  <= mesgBase;    remMesgAddr <= mesgBase;
    fabMesgAddr  <= fabMesgBase; fabMetaAddr <= fabMetaBase; fabFlowAddr <= fabFlowBase;
    lclBuf.load(0); lclBuf.setModulus(lclNumBufs);
    remBuf.load(0); remBuf.setModulus(lclNumBufs);
    fabBuf.load(0); fabBuf.setModulus(fabNumBufs);
    crdBuf.load(0); crdBuf.setModulus(lclNumBufs);
    wci.ctlAck;
  endrule

  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  function Action bufAdvance32(CounterM#(Bit#(16)) b, Reg#(Bit#(32)) metaAddr, Reg#(Bit#(32)) mesgAddr, Reg#(Bit#(32)) flowAddr);
    action
      b.inc;                                                      // increment modulo count
      metaAddr <= (b.tc) ? fabMetaBase : metaAddr + fabMetaSize;  // load or incr meta address
      mesgAddr <= (b.tc) ? fabMesgBase : mesgAddr + fabMesgSize;  // load or incr mesg address
      flowAddr <= (b.tc) ? fabFlowBase : flowAddr + fabFlowSize;  // load or incr flow address
    endaction
  endfunction
  function Action bufAdvance16(CounterM#(Bit#(16)) b, Reg#(Bit#(16)) metaAddr, Reg#(Bit#(16)) mesgAddr);
    action
      b.inc;                                                // increment modulo count
      metaAddr <= (b.tc) ? metaBase : metaAddr + metaSize;  // load or incr meta address
      mesgAddr <= (b.tc) ? mesgBase : mesgAddr + mesgSize;  // load or incr mesg address
    endaction
  endfunction

  // lclAdvance fires when we have finished with the current local-facing buffer...
  rule lclAdvance  (wci.isOperating && lclBufDone);
    bufAdvance16(lclBuf, lclMetaAddr, lclMesgAddr ); // the local-facing near side
  endrule

  // crdAdvance, used for ActFlow only, loosely shadows lclAdvance in this way:
  // lclBufDone incs lCredit, which fires dmaXmtDoorBell, which makes remStart, which fires this rule
  // This serves the utility of incrementing fabFlowAddr after the dmaXmtDoorbell is sent;
  // but also syncing the modulo reset to fabFlowBase to local buffer counts
  rule crdAdvance  (wci.isOperating && dpControl.role==ActFlow && remStart);
    crdBuf.inc;
    fabFlowAddr <= (crdBuf.tc) ? fabFlowBase : fabFlowAddr+fabFlowSize;
  endrule

  // remAdvance fires when we have finished with the current remote-facing buffer...
  rule remAdvance  (wci.isOperating && remDone);
    bufAdvance16(remBuf, remMetaAddr, remMesgAddr);  // the remote-facing near side
    if (dpControl.role==ActMesg) bufAdvance32(fabBuf, fabMetaAddr, fabMesgAddr, fabFlowAddr);  // the farside fabric buffers 
  endrule

  rule cntLclStart (wci.isOperating && lclBufStart); lclStarts <= lclStarts + 1; endrule
  rule cntLclDone  (wci.isOperating && lclBufDone);  lclDones  <= lclDones  + 1; endrule
  rule cntRemStart (wci.isOperating && remStart);    remStarts <= remStarts + 1; endrule
  rule cntRemDone  (wci.isOperating && remDone);     remDones  <= remDones  + 1; endrule

  rule lbar (wci.isOperating); // Local Buffers Available/Ready... (to throttle local-facing transfers)
  Bool lbarInc = ?;
  case (dpControl.role)
    Passive: lbarInc = fabDone;
    ActMesg: lbarInc = remDone;
    ActFlow: lbarInc = fabDone;
  endcase
    if      ( lbarInc  && !lclBufStart)  lclBufsAR <= lclBufsAR + 1;
    else if (!lbarInc  &&  lclBufStart)  lclBufsAR <= lclBufsAR - 1;
  endrule

  rule lbcf (wci.isOperating); // Local Bufffers Committed/Freed...
  Bool lbcfDec = ?;
  case (dpControl.role)
    Passive: lbcfDec = fabDone;
    ActMesg: lbcfDec = (dpControl.dir==FProducer) ? remDone : remStart;
    ActFlow: lbcfDec = fabDone;
  endcase
    if      ( lclBufDone  && !lbcfDec)  lclBufsCF <= lclBufsCF + 1;
    else if (!lclBufDone  &&  lbcfDec)  lclBufsCF <= lclBufsCF - 1;
  endrule

  // Fabric Buffers Available only meaningful when in ActiveMessage role to count buffers available on far side...
  rule fba (wci.isOperating && dpControl.role==ActMesg);
    if      ( fabAvail && !remStart)  fabBufsAvail <= fabBufsAvail + 1; // fabAvail flowcontol doorbell increments
    else if (!fabAvail &&  remStart)  fabBufsAvail <= fabBufsAvail - 1; // our starting message ngress (push or pull) decrements
  endrule

  rule lcredit (wci.isOperating && dpControl.role==ActFlow);
    if      ( lclBufDone  && !remStart)  lclCredit <= lclCredit + 1;
    else if (!lclBufDone  &&  remStart)  lclCredit <= lclCredit - 1;
  endrule

method BufState bs = BufState { lbar:lclBufsAR, lbcf:lclBufsCF, rba:fabBufsAvail, lclIndex:extend(lclBuf),
  remIndex:extend(remBuf), lclStarts:lclStarts, lclDones:lclDones, remStarts:remStarts, remDones:remDones }; 

interface BufQSIfc lcl;
  method Action    start   = lclBufStart._write(True); // Start of local access to queue head (pulse)
  method Action    done    = lclBufDone._write(True);  // End of local access to queue head (pulse)
  method Action    fabric  = noAction;
  method Bool      rdy     = (wci.isOperating && lclBufsAR!=0); // Local ready
  method Bool      frdy    = ?;                        // Not Used
  method Bool      credit  = ?;                        // Not Used
  method Bit#(16)  bufMeta = lclMetaAddr;              // the local-facing metadata address
  method Bit#(16)  bufMesg = lclMesgAddr;              // the local-facing message  address
  method Bit#(32)  fabMeta = ?;                        // Not Used
  method Bit#(32)  fabMesg = ?;                        // Not Used
  method Bit#(32)  fabFlow = ?;                        // Not Used
endinterface

interface BufQSIfc rem;
  method Action    start   = remStart._write(True);    // Ngress (local DMA or remote access) has started (pulse)
  method Action    done    = remDone._write(True);     // Ngress is Done
  method Action    fabric  = (dpControl.role==ActMesg)?fabAvail._write(True):fabDone._write(True);
  method Bool      rdy     = (wci.isOperating) && lclBufsCF   !=0;  // Near-side is Ready
  method Bool      frdy    = (wci.isOperating) && fabBufsAvail!=0;  // Far-side is Ready
  method Bool      credit  = (wci.isOperating) && lclCredit   !=0;  // Credits are Ready
  method Bit#(16)  bufMeta = remMetaAddr;              // the remote-facing metadata address
  method Bit#(16)  bufMesg = remMesgAddr;              // the remote-facing message  address
  method Bit#(32)  fabMeta = fabMetaAddr;              // the fabric metadata address
  method Bit#(32)  fabMesg = fabMesgAddr;              // the fabric message  address
  method Bit#(32)  fabFlow = fabFlowAddr;              // the fabric flowctrl address
endinterface

// expose register interface so WCI can set/get config properties...
interface Reg i_lclNumBufs   = lclNumBufs;
interface Reg i_fabNumBufs   = fabNumBufs;
interface Reg i_mesgSize     = mesgSize;
interface Reg i_metaSize     = metaSize;
interface Reg i_mesgBase     = mesgBase;   
interface Reg i_metaBase     = metaBase;   
interface Reg i_fabMesgSize  = fabMesgSize;
interface Reg i_fabMetaSize  = fabMetaSize;
interface Reg i_fabFlowSize  = fabFlowSize;
interface Reg i_fabMesgBase  = fabMesgBase;   
interface Reg i_fabMetaBase  = fabMetaBase;   
interface Reg i_fabFlowBase  = fabFlowBase;   
method Action dpCtrl (DPControl dc) = dpControl._write(dc);

endmodule: mkFabPC

endpackage: OCBufQ
