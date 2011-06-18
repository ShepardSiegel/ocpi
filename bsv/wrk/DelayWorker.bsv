// DelayWorker.bsv - Delay streaming message data
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum::*;
import OCWip::*;
import SRLFIFO::*;

import Alias::*;
import BRAM::*;
import BRAMFIFO::*;
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import Vector::*;

typedef 20 NwciAddr; // Implementer chosen number of WCI address byte bits
typedef 23 Ndag;     // Number of bits in the delay address generator log2 of 16B words entries (e.g. 23=8M*16B = 128MB)

interface DelayWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM0;    // WSI-M Stream Output
  interface WmemiEM16B                                  wmemiM0;  // WMI Memory
endinterface 

module mkDelayWorker#(parameter Bit#(32) dlyCtrlInit, parameter Bool hasDebugLogic) (DelayWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                   wci               <- mkWciESlave;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS              <- mkWsiSlave;
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM              <- mkWsiMaster;
  WmemiMasterIfc#(36,12,128,16)  wmemi             <- mkWmemiMaster;
  Reg#(Bit#(32))                 dlyCtrl           <- mkReg(dlyCtrlInit);
  Reg#(Bit#(32))                 dlyHoldoffBytes   <- mkReg(0);
  Reg#(Bit#(32))                 dlyHoldoffCycles  <- mkReg(0);
  Reg#(Bool)                     tog50             <- mkReg(False);
  Reg#(Bit#(24))                 bytesThisMessage  <- mkReg(0);
  Reg#(Bit#(14))                 mesgLengthSoFar   <- mkReg(0);

  // Delay-Write...
  Reg#(Bit#(32))                 bytesWritten      <- mkReg(0);
  Reg#(Bit#(32))                 cyclesPassed      <- mkReg(0);

  // Write Serialize...
  Reg#(Bit#(32))                 wrtSerAddr        <- mkReg(0);
  Reg#(UInt#(16))                wrtSerUnroll      <- mkReg(0);
  Vector#(4,Reg#(Bit#(32)))      wrtSerStage       <- replicateM(mkRegU);
  Reg#(Bit#(2))                  wrtSerPos         <- mkReg(0);

  // Read Serialize...
  Reg#(Bit#(32))                 rdSerAddr         <- mkReg(0);
  Reg#(UInt#(16))                rdSerUnroll       <- mkReg(0);
  Reg#(MesgMetaFlag)             rdSerMeta         <- mkRegU;
  Vector#(4,Reg#(Bit#(32)))      rdSerStage        <- replicateM(mkRegU);
  Reg#(Bit#(2))                  rdSerPos          <- mkReg(0);
  Reg#(Bool)                     rdSerEmpty        <- mkReg(True);
  Reg#(Bool)                     rdSyncWord        <- mkReg(False);

  // Delay-Read...
  Reg#(MesgMetaFlag)             readMeta          <- mkRegU;
  Reg#(UInt#(16))                unrollCnt         <- mkReg(0);
  Reg#(Bit#(32))                 mesgWtCount       <- mkReg(0);
  Reg#(Bit#(32))                 mesgRdCount       <- mkReg(0);
  Reg#(Bit#(32))                 bytesRead         <- mkReg(0);

  // Delay FIFOs
  //TODO: Switch back in SRLFIFO, now that SRLFIFOD implemenation is in place...
  /*
  FIFOF#(MesgMetaFlag)           metaWF             <- mkSRLFIFOD(4);
  FIFOF#(Bit#(nd))               mesgWF             <- mkSizedBRAMFIFOF(2048);  // MUST be sized large enough for imprecise->precise conversion!
  FIFOF#(MesgMetaFlag)           metaRF             <- mkSRLFIFOD(4);
  FIFOF#(Bit#(nd))               mesgRF             <- mkSRLFIFOD(4);            // Needs only to be large enough to accomodate the dlyReadCredit
  FIFOF#(Bit#(128))              wide16Fa           <- mkSRLFIFOD(4);
  FIFOF#(Bit#(128))              wide16Fb           <- mkSRLFIFOD(4);
  FIFOF#(Bit#(128))              wide16Fc           <- mkSRLFIFOD(4);
  */

  FIFOF#(MesgMetaFlag)           metaWF             <- mkSizedFIFOF(15);
  FIFOF#(Bit#(nd))               mesgWF             <- mkSizedBRAMFIFOF(2048);  // MUST be sized large enough for imprecise->precise conversion!
  FIFOF#(MesgMetaFlag)           metaRF             <- mkSizedFIFOF(15);
  FIFOF#(Bit#(nd))               mesgRF             <- mkSizedFIFOF(15);            // Needs only to be large enough to accomodate the dlyReadCredit
  FIFOF#(Bit#(128))              wide16Fa           <- mkSizedFIFOF(15);
  FIFOF#(Bit#(128))              wide16Fb           <- mkSizedFIFOF(15);
  FIFOF#(Bit#(128))              wide16Fc           <- mkSizedFIFOF(15);

  // Delay Management...
  Accumulator2Ifc#(Int#(TAdd#(Ndag,2))) dlyWordsStored     <- mkAccumulator2;   // Signed Accumulator needs 2 additional bits
  Accumulator2Ifc#(Int#(8))      dlyReadCredit      <- mkAccumulator2;
  Reg#(UInt#(Ndag))              dlyWAG             <- mkReg(0);
  Reg#(UInt#(Ndag))              dlyRAG             <- mkReg(0);
  Accumulator2Ifc#(Int#(16))     dlyReadyToWrite    <- mkAccumulator2;          // Measures the occupancy of the wide16Fa FIFO

  Reg#(Bit#(32))                 dlyRdOpZero        <- mkReg(0);
  Reg#(Bit#(32))                 dlyRdOpOther       <- mkReg(0);

  Reg#(Bit#(32))                 wmemiWrReq         <- mkReg(0);
  Reg#(Bit#(32))                 wmemiRdReq         <- mkReg(0);
  Reg#(Bit#(32))                 wmemiRdResp1       <- mkReg(0);
  Reg#(Bit#(32))                 wmemiRdResp2       <- mkReg(0);

  Bool wsiPass  = (dlyCtrl[3:0]==4'h0);
  Bool wmemiDly = (dlyCtrl[3:0]==4'h7);
  Bool impWsiM = False;

rule operating_actions (wci.isOperating);
  wsiS.operate();
  wsiM.operate();
  wmemi.operate();
  tog50 <= !tog50;
endrule

// WSI Pass...
rule wsipass_doMessagePush (wci.isOperating && wsiPass);
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;
  wsiM.reqPut.put(r);
endrule

rule cycles_passed_count (wsiS.status.observedTraffic); // Start cycle count when first WSI traffic is observed
  if (cyclesPassed < maxBound) cyclesPassed <= cyclesPassed + 1;
endrule

rule wmwt_mesg_ingress (wci.isOperating && wmemiDly);
  WsiReq#(12,nd,nbe,8,0) w <- wsiS.reqGet.get;
  mesgWF.enq(w.data); // Move the message data into the Write FIFO
  mesgLengthSoFar <= (w.reqLast) ? 0 : mesgLengthSoFar + 1;
  if (w.reqLast) begin
    // FIXME: wordsThisMessage seems to return result-1 for precise bursts!
    //Bit#(24) btm = extend(wsiS.wordsThisMessage)<<myWordShift; 
    Bit#(24) btm = wsiS.reqPeek.burstPrecise ?  extend(wsiS.reqPeek.burstLength)<<myWordShift : extend(mesgLengthSoFar+1)<<myWordShift;
    bytesThisMessage <= btm;
    let mesgMetaF = MesgMetaFlag {opcode:w.reqInfo, length:btm}; 
    metaWF.enq(mesgMetaF);  // Enque the metadata
    mesgWtCount <= mesgWtCount + 1;
  end
  if (bytesWritten < (maxBound-extend(myByteWidth))) bytesWritten <= bytesWritten + extend(myByteWidth);
endrule

/*
  Message and Message Metadata Serialization Technique

  Utility: The Worker Streaming Interface (WSI) allows for the ingress of precise or imprecise length messages and their associated
  metadata (e.g. opcode and length). This apparatus serializes this data and packs it into an integer number of (16B) packets. These
  packets are suitable for sequential storage to and retrieval from a FIFO. Then this apparatus de-serializes (or de-multiplexes) the
  (16B) packets into a mesage and metadata stream. 

  Pre-Requsites: Incident WSI streams may be either precise or imprecise. In the precise case, metadata preceeds the message of some length.
  In the imprecise case, the message data must be received as an external circuit counts the number of words in the message. It is not until
  the endOfMessage that the length is known. Because of this, the mesgWF must be deep enough to capture as many words as the longest
  imprecise message. If it is not, the message body will block (no room in message FIFO), and there will never be a commit to the metadata.
  The restriction can be ignored if all input messages are required to be precise.

  ... Serializer Storage ...
  FIFOF#(Bit#(nd))               mesgWF             <- mkSizedBRAMFIFOF(512);  
  FIFOF#(MesgMetaFlag)           metaWF             <- mkSRLFIFOD(4);
  FIFOF#(Bit#(128))              wide16Fa           <- mkSRLFIFOD(4);
  ... De-Serializer Storage..
  FIFOF#(Bit#(128))              wide16Fb           <- mkSRLFIFOD(4);
  FIFOF#(Bit#(nd))               mesgRF             <- mkSizedBRAMFIFOF(512);  
  FIFOF#(MesgMetaFlag)           metaRF             <- mkSRLFIFOD(4);

  Overview:   Serializer -> 16B FIFO Channel -> De-Serializer

  Serializer: DEQs metadata and message data from metaWF and mesgWF as it forms an integer number of ENQs to
  the wide16Fa. The Final enq of a sequence of 16B ENQs may have 0, 1, 2, or 3 DW of padding added so that full
  messages (meta+mesg) are not split between two 16B words. The Action function enqSer4B accumulates 4B call
  data one 4B word at a time. The serialization order is
    1 DW of MesgMetaFlag  // when wrtSer_begin FIRES
    m DW of MessageData   // when wrtSer_body  FIRES
    p DW of zero-padding  // when wrtSer_body  FIRES with lasword/flush True

*/


// Connect the WFs to RFs...
//mkConnection(toGet(metaWF), toPut(metaRF));
//mkConnection(toGet(mesgWF), toPut(mesgRF));

function Action enqSer4B( Bit#(32) data, Bool flush);
  action
    wrtSerStage[wrtSerPos] <= data;
    wrtSerPos <= flush ? 0 : wrtSerPos + 1;
    if (wrtSerPos==3 || flush)
      case (wrtSerPos)
        0: wide16Fa.enq({32'h0, 32'h0,          32'h0,          data});
        1: wide16Fa.enq({32'h0, 32'h0,          data,           wrtSerStage[0]});
        2: wide16Fa.enq({32'h0, data,           wrtSerStage[1], wrtSerStage[0]});
        3: wide16Fa.enq({data,  wrtSerStage[2], wrtSerStage[1], wrtSerStage[0]});
      endcase
      dlyReadyToWrite.acc1(1);
  endaction
endfunction

rule wrtSer_begin(wci.isOperating && wmemiDly && wrtSerUnroll==0);
  let meta = metaWF.first; metaWF.deq;
  wrtSerUnroll  <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words 
  enqSer4B(pack(meta), meta.length==0);
endrule

rule wrtSer_body(wci.isOperating && wmemiDly && wrtSerUnroll>0);
  let mesg = mesgWF.first; mesgWF.deq;
  Bool lastWord = (wrtSerUnroll==1);
  wrtSerUnroll <= wrtSerUnroll - 1;
  enqSer4B(truncate(pack(mesg)), lastWord);
endrule


// Wide16Fa -> Wide16Fb is the Delay Insert point...

// Bypass path for 16B pipe design debug...
//mkConnection(toGet(wide16Fa), toPut(wide16Fb));


// When we satisfy the constraints below, we start the read process...
Bool readThreshold = (dlyWordsStored>0 && bytesWritten>=dlyHoldoffBytes && cyclesPassed>=dlyHoldoffCycles);
Bool writeNotBlockedByRead = !readThreshold || (readThreshold && (!wsiM.reqFifoNotFull || tog50) );  // True, when reads are fully-satisfied; Restrict Write BW to 50% when WSI-M FIFO is not full once we've begun reading
//Bool writeNotTooFarAhead = (dlyWordsStored < extend(fromInteger(2**valueOf(Ndag))) );    // True, as long we we have not stored too much data; Goes low if danger of writes passing reads in buffer
Bool writeNotTooFarAhead = (dlyWordsStored < 8388608 );    // True, as long we we have not stored too much data; Goes low if danger of writes passing reads in buffer

//(* descending_urgency = "delay_write_req, delay_read_req" *)

// As long as we didn't just finish a read request parade (so as to be polite between reads and wtites)...
// If we fired on the previous cycle, keep pushing writes until we run out of things to write.
// Otherwise, wait until we have at least 8 16B Wmemi words that we could push at once.
// Unless the dlyFlushTimer has expired in which case we just go if we have anything at all.
rule delay_write_req (wci.isOperating && wmemiDly && writeNotBlockedByRead && writeNotTooFarAhead );
//rule delay_write_req (wci.isOperating && wmemiDly && ((dlyWriteJustFired||dlyWriteFlush==maxBound) ? dlyReadyToWrite>0 : dlyReadyToWrite>7) && writeNotBlockedByRead && writeNotTooFarAhead );
  dlyWordsStored.acc1(1);                          // One 16B word stored
  dlyWAG <= dlyWAG + 1;                            // Bump WAG
  wmemi.req(True, extend({pack(dlyWAG),4'h0}), 1); // Write Request
  wmemi.dh(wide16Fa.first, '1, True);              // Write 16B Datahandshake
  wide16Fa.deq;
  wmemiWrReq <= wmemiWrReq + 1;
  dlyReadyToWrite.acc2(-1);
endrule


// As long as we didn't just finish a write request parade (so as to be polite between writes and reads)
// if we have reads do ask for, ask for as many as we can, as long as the WSI-M request FIFO is not Full (due to downstream backpressure)...
rule delay_read_req (wci.isOperating && wmemiDly && readThreshold && dlyReadCredit>0 && wsiM.reqFifoNotFull);
  dlyWordsStored.acc2(-1);  // One 16B word read
  dlyRAG <= dlyRAG + 1;
  dlyReadCredit.acc1(-1);   // Decrement our read credit by one
  wmemi.req(False, extend({pack(dlyRAG),4'h0}), 1);  // Read Request
  wmemiRdReq <= wmemiRdReq + 1;
endrule

(* fire_when_enabled *)
rule delay_read_resp (wci.isOperating && wmemiDly);
  let x <- wmemi.resp;
  wide16Fb.enq(x.data);
  wmemiRdResp1 <= wmemiRdResp1 + 1;
endrule

(* fire_when_enabled *)
rule delay_Fb2Fc (wci.isOperating && wmemiDly);
  wide16Fc.enq(wide16Fb.first);
  wide16Fb.deq;
  dlyReadCredit.acc2(1);   // Restore our read credit by one
  wmemiRdResp2 <= wmemiRdResp2 + 1;
endrule

function ActionValue#(Bit#(32)) deqSer4B();
  return (
    actionvalue
      Bit#(128) rdata = ?;
      if (rdSerEmpty || rdSerPos==0) begin 
        rdata = wide16Fc.first;
        rdSerStage[0] <= rdata[31:0];
        rdSerStage[1] <= rdata[63:32];
        rdSerStage[2] <= rdata[95:64];
        rdSerStage[3] <= rdata[127:96];
        wide16Fc.deq;
        rdSerEmpty <= False;
      end
      rdSerPos <= rdSerPos + 1;
      return (
      case (rdSerPos)
        0: rdata[31:0];
        1: rdSerStage[1];
        2: rdSerStage[2];
        3: rdSerStage[3];
      endcase
      );
    endactionvalue
  );
endfunction


rule rdSer_begin(wci.isOperating && wmemiDly && rdSerUnroll==0 && !rdSyncWord);
  let m <- deqSer4B();
  MesgMetaFlag meta = unpack(m);
  rdSerMeta <= meta;
  rdSerUnroll  <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words 
  if (meta.opcode==0) dlyRdOpZero  <= dlyRdOpZero  + 1;
  if (meta.opcode!=0) dlyRdOpOther <= dlyRdOpOther + 1;
  metaRF.enq(meta);
  if (bytesRead < maxBound) bytesRead <= bytesRead + extend(myByteWidth);
  rdSyncWord <= rdSerPos!=3 && meta.length==0;
endrule

rule rdSer_body(wci.isOperating && wmemiDly && rdSerUnroll>0 && !rdSyncWord);
  Bit#(32) mesg <- deqSer4B();
  Bool lastWord = (rdSerUnroll == 1);
  rdSyncWord <= rdSerPos!=3 && lastWord;
  rdSerUnroll <= rdSerUnroll - 1;
  mesgRF.enq(extend(mesg));
  if (bytesRead < maxBound) bytesRead <= bytesRead + extend(myByteWidth);
endrule

//TODO: Replce rdSyncWord with BypassFifo#(Bool) to hide sync cycle...

// Effectively consume (dispose of) any remaining 4B words in the 16B chunk...
rule rdSer_sync(wci.isOperating && wmemiDly && rdSyncWord);
  rdSyncWord <= False;
  rdSerEmpty <= True;
  rdSerPos   <= 0;
endrule








//
//
// Delay Read...
rule wmrd_mesgBegin (wci.isOperating && wmemiDly && unrollCnt==0 );
  let meta = metaRF.first; metaRF.deq; readMeta <= meta;
  if (meta.length==0) begin
    unrollCnt      <= 1;  // One word to produce on WSI with all BEs inaction (zero lenghth mesg indication)
  end else begin
    unrollCnt      <= truncate(unpack(meta.length>>myWordShift)); // ndw-wide Words remaining to be emitted to WSI
  end
endrule

rule wmrd_mesgBodyResponse (wci.isOperating && wmemiDly && unrollCnt>0);
  let mesg = mesgRF.first; mesgRF.deq;
  Bool zlm = (readMeta.length==0);
  Bit#(24) wsiBurstLength = (impWsiM) ? 2 : readMeta.length>>myWordShift; // convert Bytes to ndw-wide WSI Words burstLength
  Bool lastWord = (unrollCnt == 1);
  wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                           reqLast : lastWord,
                           reqInfo : readMeta.opcode,
                      burstPrecise : !impWsiM,
                       burstLength : (zlm || (impWsiM && lastWord)) ? 1 : (impWsiM)? '1 : truncate(wsiBurstLength),
                             data  : mesg,
                           byteEn  : (zlm) ? '0 : '1,   // For Zero-Length WSI Messages
                         dataInfo  : '0 });
  unrollCnt <= unrollCnt - 1;
  if (lastWord) mesgRdCount <= mesgRdCount + 1;
endrule




// WCI...

  Bit#(32) delayStatus = {14'h0,
    pack(readThreshold),            //b17
    pack(writeNotBlockedByRead),    //b16
    pack(writeNotTooFarAhead),      //b15
    pack(wsiM.reqFifoNotFull),      //b14
    pack(metaWF.notFull),   pack(metaWF.notEmpty),
    pack(mesgWF.notFull),   pack(mesgWF.notEmpty),
    pack(metaRF.notFull),   pack(metaRF.notEmpty),
    pack(mesgRF.notFull),   pack(mesgRF.notEmpty),
    pack(wide16Fa.notFull), pack(wide16Fa.notEmpty),
    pack(wide16Fb.notFull), pack(wide16Fb.notEmpty),
    pack(wide16Fc.notFull), pack(wide16Fc.notEmpty)};


(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr) matches
     'h00 : dlyCtrl          <= unpack(wciReq.data);
     'h04 : dlyHoldoffBytes  <= unpack(wciReq.data);
     'h08 : dlyHoldoffCycles <= unpack(wciReq.data);
   endcase
   //$display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr) matches
     'h00 : rdat = pack(dlyCtrl);
     'h04 : rdat = pack(dlyHoldoffBytes);
     'h08 : rdat = pack(dlyHoldoffCycles);
     'h0C : rdat = (!hasDebugLogic) ? 0 : pack(mesgWtCount);
     'h10 : rdat = (!hasDebugLogic) ? 0 : pack(mesgRdCount);
     'h14 : rdat = (!hasDebugLogic) ? 0 : pack(bytesWritten);
     'h18 : rdat = (!hasDebugLogic) ? 0 : extend({pack(wmemi.status),pack(wsiS.status),pack(wsiM.status)});
     'h1C : rdat = (!hasDebugLogic) ? 0 : 0;
     'h20 : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.pMesgCount);
     'h24 : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.iMesgCount);
     'h28 : rdat = (!hasDebugLogic) ? 0 : pack(wsiS.extStatus.tBusyCount);
     'h2C : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.pMesgCount);
     'h30 : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.iMesgCount);
     'h34 : rdat = (!hasDebugLogic) ? 0 : pack(wsiM.extStatus.tBusyCount);
     'h38 : rdat = (!hasDebugLogic) ? 0 : wmemiWrReq;
     'h3C : rdat = (!hasDebugLogic) ? 0 : wmemiRdReq;
     'h40 : rdat = (!hasDebugLogic) ? 0 : wmemiRdResp1;
     'h44 : rdat = (!hasDebugLogic) ? 0 : pack(extend(dlyWordsStored));
     'h48 : rdat = (!hasDebugLogic) ? 0 : pack(extend(dlyReadCredit));
     'h4C : rdat = (!hasDebugLogic) ? 0 : pack(extend(dlyWAG));
     'h50 : rdat = (!hasDebugLogic) ? 0 : pack(extend(dlyRAG));
     'h58 : rdat = pack(dlyRdOpZero);
     'h5C : rdat = pack(dlyRdOpOther);
     'h60 : rdat = (!hasDebugLogic) ? 0 : wmemiRdResp2;
     'h64 : rdat = delayStatus;
     'h68 : rdat = pack(extend(dlyReadyToWrite));
     'h6C : rdat = pack(extend(wrtSerUnroll));
     'h70 : rdat = pack(extend(bytesThisMessage));
     'h74 : rdat = pack(extend(mesgLengthSoFar));
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule


rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  mesgWtCount <= 0;
  mesgRdCount <= 0;
  dlyWordsStored.load(0);   // Initialize the number of (16B) words stored in memory
  dlyReadyToWrite.load(0);  // How many 16B words are ReadyToWrite to DRAM
  dlyReadCredit.load(12);   // Maximum Number of Reads in Flight
  dlyWAG  <= 0;             // Initialize the Write Address Generator accumulator
  dlyRAG  <= 0;             // Initialize the Read  Address Generator accumulator
  wci.ctlAck;
  $display("[%0d]: %m: Starting DelayWorker dlyCtrl:%0x", $time, dlyCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,nd,nbe,8,0)  wsi_Es    <- mkWsiStoES(wsiS.slv);
  WmemiEM16B              wmemi_Em  <- mkWmemiMtoEm(wmemi.mas);

  interface wciS0   = wci.slv;
  interface wsiS0   = wsi_Es;
  interface wsiM0   = toWsiEM(wsiM.mas);
  interface wmemiM0 = wmemi_Em;
endmodule

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef DelayWorkerIfc#(1) DelayWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker4B#(parameter Bit#(32) dlyCtrlInit, parameter Bool hasDebugLogic) (DelayWorker4BIfc);
  DelayWorker4BIfc _a <- mkDelayWorker(dlyCtrlInit, hasDebugLogic); return _a;
endmodule

typedef DelayWorkerIfc#(2) DelayWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker8B#(parameter Bit#(32) dlyCtrlInit, parameter Bool hasDebugLogic) (DelayWorker8BIfc);
  DelayWorker8BIfc _a <- mkDelayWorker(dlyCtrlInit, hasDebugLogic); return _a;
endmodule

typedef DelayWorkerIfc#(4) DelayWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker16B#(parameter Bit#(32) dlyCtrlInit, parameter Bool hasDebugLogic) (DelayWorker16BIfc);
  DelayWorker16BIfc _a <- mkDelayWorker(dlyCtrlInit, hasDebugLogic); return _a;
endmodule

typedef DelayWorkerIfc#(8) DelayWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkDelayWorker32B#(parameter Bit#(32) dlyCtrlInit, parameter Bool hasDebugLogic) (DelayWorker32BIfc);
  DelayWorker32BIfc _a <- mkDelayWorker(dlyCtrlInit, hasDebugLogic); return _a;
endmodule

