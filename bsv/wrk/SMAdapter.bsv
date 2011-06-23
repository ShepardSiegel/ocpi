// SMAdapter.bsv - Stream/Message Adapter WSI/WMI
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum::*;
import OCWip::*;

import Alias::*;
import BRAMFIFO::*;	
import Connectable::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import SRLFIFO::*;
import GetPut::*;

// Some useful functions...

// Given a UInt#(np) specifiying how many ones, decode into a little-endian bit vector Bit#(nm) mask of ones...
function Bit#(nm) genLittleOnes (UInt#(np) numOnes);
  Bit#(nm) mask = 0;
  for (UInt#(np) p=0; p<numOnes; p=p+1) mask = mask | (1<<p);
  return (mask);
endfunction

interface SMAdapterIfc#(numeric type ndw);
  interface WciES                                          wciS0;
  interface Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32) wmiM0;
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiM0;
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsiS0;
endinterface 

module mkSMAdapter#(parameter Bit#(32) smaCtrlInit, parameter Bool hasDebugLogic) (SMAdapterIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd), NumAlias#(TMul#(ndw,4),nbe), Add#(b_,TMul#(ndw,4),32), 
   Add#(1, c_, TLog#(TAdd#(1, TMul#(ndw,4)))), Add#(d_, TLog#(TAdd#(1, TMul#(ndw, 4))), 8),
   Add#(1, a__, TAdd#(3, TAdd#(1, TAdd#(1, TAdd#(12, TAdd#(TMul#(ndw, 32), TAdd#(TMul#(ndw, 4), 8))))))),
   Add#(bx_, TLog#(TAdd#(1, TMul#(ndw,4))), 14)
  );

// This function accepts the length of a transfer, knows "ndw" as a side-effect, and either:
// i)  Returns all '1s if the length is alligned and thus all BEs are active
// ii) Returns a littte-endian mask of ones to enable just the bytes in the word that matter
function Bit#(32) byteEnFromLength (Bit#(16) length);
  UInt#(8)  larg = unpack(length[7:0]);
  UInt#(8)  lmask = 0;
  Bit#(32)  rval  = 0;
  case (valueOf(ndw)) // ndw determines which address bits are significant for BE mask generation
    1: lmask = 8'h03; // 1DW /  4B
    2: lmask = 8'h07; // 2DW /  8B
    4: lmask = 8'h0F; // 4DW / 16B
    8: lmask = 8'h1F; // 8DW / 32B
  endcase
  UInt#(6) addrResidue = truncate(larg&lmask);
  rval = (addrResidue==0) ? '1 : genLittleOnes(addrResidue);
  return(rval);
endfunction

function Bool isAlignedLength (Bit#(16) length);
  UInt#(8)  larg = unpack(length[7:0]);
  UInt#(8)  lmask = 0;
  case (valueOf(ndw)) 
    1: lmask = 8'h03; // 1DW /  4B
    2: lmask = 8'h07; // 2DW /  8B
    4: lmask = 8'h0F; // 4DW / 16B
    8: lmask = 8'h1F; // 8DW / 32B
  endcase
  UInt#(6) addrResidue = truncate(larg&lmask);
  return (addrResidue==0);
endfunction


  // Set this True for possibly higher WMI to WSI throughput; False for possibly lower area...
  Bool hasDeepResponseBuffer = True;

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;        // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));  // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                   wci               <- mkWciESlave;
  WmiMasterIfc#(14,12,nd,0,TMul#(ndw,4),32) wmi    <- mkWmiMaster;
  WsiMasterIfc#(12,nd,nbe,8,0)   wsiM              <- mkWsiMaster;
  WsiSlaveIfc #(12,nd,nbe,8,0)   wsiS              <- mkWsiSlave;
  Reg#(Bit#(32))                 smaCtrl           <- mkReg(smaCtrlInit);

  // WMI-Read...
  Reg#(Bit#(32))                 mesgCount         <- mkReg(0);
  Reg#(MesgMetaDW)               thisMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(MesgMetaDW)               lastMesg          <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(UInt#(16))                unrollCnt         <- mkReg(0);
  Accumulator2Ifc#(Int#(12))     fabRespCredit     <- mkAccumulator2;
  Reg#(UInt#(14))                fabWordsRemain    <- mkReg(0);            // ndw-wide Words that remain to be consumed
  Reg#(UInt#(14))                fabWordsCurReq    <- mkRegU;              // ndw-wide Words in the current request
  Reg#(UInt#(14))                mesgReqAddr       <- mkRegU;              // Message Request Byte Address 
  Reg#(Bool)                     mesgPreRequest    <- mkDReg(False);
  Reg#(Bool)                     mesgReqOK         <- mkReg(False);
  Reg#(Bool)                     firstMsgReq       <- mkReg(False);

  FIFOF#(WsiReq#(12,nd,nbe,8,0)) respF             <- hasDeepResponseBuffer ?
                                                      mkSizedBRAMFIFOF(1024) : // 1024 Words of Message Response Storage
                                                      mkSRLFIFOD(4);           // 16   Words of Message Response Storage

  // WMI-Write...
  Reg#(Maybe#(Bit#(8)))          opcode            <- mkReg(tagged Invalid);
  Reg#(Bool)                     endOfMessage      <- mkReg(False);
  Reg#(Bool)                     readyToRequest    <- mkReg(False);
  Reg#(Bool)                     readyToPush       <- mkReg(False);
  Reg#(Bit#(14))                 mesgLengthSoFar   <- mkReg(0);              // in Bytes up to 2^14 -1
  Reg#(Bool)                     doAbort           <- mkReg(False);
  FIFO#(Bit#(0))                 mesgTokenF        <- mkFIFO1;

  // debug...
  Reg#(Bit#(32))                 abortCount        <- mkReg(0);
  Reg#(Bit#(nd))                 valExpect         <- mkReg(0);
  Reg#(Bit#(nd))                 errCount          <- mkReg(0);
  Reg#(Bit#(32))                 wmwtBeginCount    <- mkReg(0);
  Reg#(Bit#(32))                 wmwtPushCount     <- mkReg(0);
  Reg#(Bit#(32))                 wmwtFinalCount    <- mkReg(0);

  Bool wsiPass  = (smaCtrl[3:0]==4'h0);
  Bool wmiRd    = (smaCtrl[3:0]==4'h1) || (smaCtrl[3:0]==4'h4) || (smaCtrl[3:0]==4'h9); // FIXME: 4'h9 is temp workaround for testRpl sw
  Bool wmiWt    = (smaCtrl[3:0]==4'h2) || (smaCtrl[3:0]==4'h3);  // Split function adds additional WSI-M egress to WMI Write
  Bool wxiSplit = (smaCtrl[3:0]==4'h3);
  Bool nixWsiM = unpack(smaCtrl[4]);  // Setting bit 4 disables target WSI-M Put
  Bool impWsiM = unpack(smaCtrl[5]);  // Setting bit 5 forces imprecise burst (for testing)

rule operating_actions (wci.isOperating);
  wmi.operate();
  wsiM.operate();
  wsiS.operate();
endrule

// WSI Pass...
rule wsipass_doMessagePush (wci.isOperating && wsiPass);
  WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;
  if (!nixWsiM) wsiM.reqPut.put(r);  // Setting nixWsiM disables target WSI-M Put
endrule


// WMI Read...
(* descending_urgency = "wmrd_mesgBodyResponse, wmrd_mesgBodyRequest, wmrd_mesgBodyPreRequest, wmrd_mesgBegin" *)

// This rule to fire once at the beginning of each and every fabric consumption of a message...
rule wmrd_mesgBegin (wci.isOperating && wmiRd && !wmi.anyBusy && unrollCnt==0);
  Bool isZlm = ?;
  Bit#(24) residue = (isAlignedLength(truncate(wmi.mesgLength))) ? 0 : 1; // if there is a remainder, we will need an extra word cycle
  if (wmi.zeroLengthMesg) begin
    isZlm = True;
    unrollCnt      <= 1;  // One word to produce on WSI with all BEs inaction (zero lenghth mesg indication)
    fabWordsRemain <= 1;  // One word to consume from WMI so we can send a DWM
  end else begin
    isZlm = False;
    unrollCnt      <= truncate(unpack((wmi.mesgLength>>myWordShift) + residue)); // ndw-wide Words remaining to be emitted to WSI
    fabWordsRemain <= truncate(unpack((wmi.mesgLength>>myWordShift) + residue)); // ndw-wide Words remaining to be requested from fabric
  end
  mesgReqOK        <= True;
  mesgReqAddr      <= 0;  // Initialize address to 0
  thisMesg <= MesgMetaDW { tag:truncate(mesgCount), opcode:wmi.reqInfo, length:truncate(wmi.mesgLength) };  // WMI->WSI: take the length from WMI metadata
  lastMesg <= thisMesg;
  $display("[%0d]: %m: wmrd_mesgBegin mesgCount:%0h mesgLength:%0h reqInfo:%0h", $time, mesgCount, wmi.mesgLength, wmi.reqInfo);
endrule

// Figure out how much we can ask for: the min of what we need and what we can acccept...
rule wmrd_mesgBodyPreRequest (wci.isOperating && wmiRd && fabWordsRemain>0 && fabRespCredit>0 && mesgReqOK);
  fabWordsCurReq   <= min(fabWordsRemain, unpack(pack(extend(fabRespCredit))));
  mesgReqOK        <= False;  // Inhibit issuing another request until this one is completed
  mesgPreRequest   <= True;
  //$display("[%0d]: %m: wmrd_mesgBodyPreReq", $time );
endrule

// Act on the pre-request calculaton and make the request...
rule wmrd_mesgBodyRequest (wci.isOperating && wmiRd && mesgPreRequest);
  fabRespCredit.acc1(- unpack(pack(truncate(fabWordsCurReq))) );   // Debit on what we ask for
  Bool last = (fabWordsRemain==fabWordsCurReq);
  wmi.req(False, pack(mesgReqAddr), truncate(pack(fabWordsCurReq)), last, ?);
  mesgReqAddr      <= mesgReqAddr    + (fabWordsCurReq<<myWordShift);  // convert from ndw-wide words to Bytes
  fabWordsRemain   <= fabWordsRemain -  fabWordsCurReq;
  //$display("[%0d]: %m: wmrd_mesgBodyRequest mesgReqAddr:%0h fabWordsCurReq:%0h fabWordsRemain:%0h",
  // $time, mesgReqAddr, fabWordsCurReq, fabWordsRemain );
endrule

//(* execution_order = "wmrd_mesgBodyResponse, wci_cfwr" *) 
rule wmrd_mesgBodyResponse (wci.isOperating && wmiRd && unrollCnt>0);
  let x <- wmi.resp;     // Take the response from the WMI interface
  Bool zlm = (thisMesg.length==0);
  Bit#(16) wsiBurstLength = (impWsiM) ? 2 : thisMesg.length>>myWordShift; // convert Bytes to ndw-wide WSI Words burstLength
  Bool lastWord = (unrollCnt == 1);
  if (!nixWsiM)          // Setting nixWsiM disables target WSI-M Put
    respF.enq       (WsiReq    {cmd  : WR ,
                             reqLast : lastWord,
                             reqInfo : thisMesg.opcode,
                        burstPrecise : !impWsiM,
                         burstLength : (zlm || (impWsiM && lastWord)) ? 1 : (impWsiM) ? '1 : truncate(wsiBurstLength),
                               data  : x.data,
                             // WSI rule to assert all BEs except on last word of a transfer...
                             byteEn  : (zlm) ? '0 : (lastWord) ? truncate(byteEnFromLength(thisMesg.length)) : '1,
                           dataInfo  : '0 });
  if (lastWord) begin
    mesgCount <= mesgCount + 1;
    //$display("[%0d]: %m: wmrd_mesgBodyResponse: End of WSI Producer Egress: mesgCount:%0x mesgLen:%0x reqInfo:%0x",
    //  $time, mesgCount, wmi.mesgLength, wmi.reqInfo);
  end
  mesgReqOK <= True;           // OK to issue another request now
  unrollCnt <= unrollCnt - 1;
endrule

// Could do this with mkConnection except that we need to get credit on deq
//mkConnection(toGet(respF), wsiM.reqPut); 
rule wmrd_mesgResptoWsi (wci.isOperating && wmiRd);
  wsiM.reqPut.put(respF.first); // Put the message read response FIFO to the wsiM
  respF.deq;
  fabRespCredit.acc2(1);        // Credit one word removed from the Resp FIFO this cycle
endrule



// WMI Write...
(* descending_urgency = "wmwt_doAbort, wmwt_messageFinalize, wmwt_messagePush, wmwt_mesgBegin, wsipass_doMessagePush" *)

// This rule will fire once at the beginning of every inbound WSI message
// It relies upon the implicit condition of the wsiS.reqPeek to only fire when we a request...
rule wmwt_mesgBegin (wci.isOperating && wmiWt && !wmi.anyBusy && !isValid(opcode));
  mesgTokenF.enq(?);
  opcode <= tagged Valid wsiS.reqPeek.reqInfo;
  if (wsiS.reqPeek.burstPrecise) begin
    $display("[%0d]: %m: mesgBegin PRECISE mesgCount:%0x WSI burstLength:%0x reqInfo:%0x", $time, mesgCount, wsiS.reqPeek.burstLength, wsiS.reqPeek.reqInfo);
  end else begin
    $display("[%0d]: %m: wmwt_mesgBegin IMPRECISE mesgCount:%0x", $time, mesgCount);
  end
  mesgLengthSoFar <= 0; 
  readyToPush     <= True;
  wmwtBeginCount <= wmwtBeginCount + 1;
endrule

// 2011-06-22 ssiegel: Surgery to fuse the precise and imprecise WSI->WMI cases
// Previously, there were separate rule to request and push in the Precise WSI case
// Henceforth, we treat all WSI messages as imprecise, even if they arrive as precise.
// The motivation for this change is that a single front-end precise request can NOT know the exact length in bytes of the message
// that will be revealed on the very last cycle by adding in the Hamming-weight of the byteEn field

// The downside of the is approach is that in all cases, both precise and imprecise, we issue a reqest and datahandhake per WSI word
// This is fine if the WMI slacve an accept a request and word on every cycle, as the WmiServBC implementation can.
// However, there may be WMI implemenations that perform better with one signle N-word request; followed by N words of data phase
// That was how the old precise logic (removed now) operated. But we had no easy way to communicate the exact Byte length at the
// the front of the transfer (in the request).

// Designer's Note: When WSI has an imprecise burst; it is a "Zero Length Message" (ZLM) iff there are all-zero Byte Enables on
// the FIRST and ONLY cycle of the message. Any other condition is non-ZLM, just a cycle that has non-valid data, and is
// in the middle or end of a WSI message (as seen by reqLast)...

// Push messages WSI to WMI...
rule wmwt_messagePush (wci.isOperating && wmiWt && readyToPush);
  WsiReq#(12,nd,nbe,8,0) w <- wsiS.reqGet.get;  // ActionValue Get
  if (wxiSplit) wsiM.reqPut.put(w);             // Feed wsiM in Split Mode
  Bool dwm = (w.reqLast);                                  // WSI ends with reqLast, used to make WMI DWM
  Bool zlm = dwm && (w.byteEn=='0) && mesgLengthSoFar==0;  // Zero Length Message is 0 BEs on DWM on the first WSI data cycle
  Bit#(14) mlInc =(dwm) ? pack(extend(countOnes(w.byteEn))) : extend(myByteWidth); // Increment by byteWidth except on last cycle use byteEn
  Bit#(14) mlB   = mesgLengthSoFar + mlInc;                                        // Current messageLength in Bytes
  if (isAborted(w)) begin
    doAbort <= True;
  end else begin
    let mesgMetaF = MesgMetaFlag {opcode:fromMaybe(0,opcode), length:zlm?0:extend(mlB)}; 
    wmi.req(True, mesgLengthSoFar, 1, dwm, pack(mesgMetaF)); // Write, ByteAddr, 1Word, dwm, mFlag;
    wmi.dh(w.data, w.byteEn, dwm);                           // Data,  BE,              dwm
    if (dwm) begin
      readyToPush  <= False;
      endOfMessage <= True;
      thisMesg <= MesgMetaDW { tag:truncate(mesgCount), opcode:fromMaybe(0,opcode), length:extend(mlB) }; lastMesg <= thisMesg;  // diag
    end
    mesgLengthSoFar <= mlB; // transfer mlB to accumulator
    // Count Pattern Error check...
    if (!zlm) valExpect <= valExpect + 1;
    if (w.data!=valExpect && !zlm) errCount <= errCount + 1;
  end
  wmwtPushCount <= wmwtPushCount + 1;
  //$display("[%0d]: %m: wmwt_messagePush", $time );
endrule

// In case we abort the imprecise WSI...
rule wmwt_doAbort (wci.isOperating && wmiWt && doAbort);
  doAbort         <= False;
  readyToPush     <= False;
  opcode          <= tagged Invalid;
  abortCount      <= abortCount + 1;
  $display("[%0d]: %m: wmwt_doAbort", $time );
endrule

// When we have pushed all the data through, this rule fires to prepare us for the next...
rule wmwt_messageFinalize
  (wci.isOperating && wmiWt && !doAbort && endOfMessage );
  mesgTokenF.deq();
  opcode         <= tagged Invalid;
  mesgCount      <= mesgCount + 1;
  endOfMessage   <= False;
  wmwtFinalCount <= wmwtFinalCount + 1;
  $display("[%0d]: %m: wmwt_messageFinalize mesgCount:%0x WSI mesgLength:%0x", $time, mesgCount, thisMesg.length);
endrule


// WCI...

(* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h00 : smaCtrl  <= unpack(wciReq.data);
   endcase
   $display("[%0d]: %m: SMAdapter WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(smaCtrl);
     'h04 : rdat = !hasDebugLogic ? 0 : pack(mesgCount);
     'h08 : rdat = !hasDebugLogic ? 0 : pack(abortCount);
     'h10 : rdat = !hasDebugLogic ? 0 : pack(thisMesg);
     'h14 : rdat = !hasDebugLogic ? 0 : pack(lastMesg);
     'h18 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
     'h20 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
     'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
     'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
     'h2C : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
     'h30 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
     'h34 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
     'h38 : rdat = !hasDebugLogic ? 0 : pack(wmwtBeginCount);
     'h3C : rdat = !hasDebugLogic ? 0 : pack(wmwtPushCount);
     'h40 : rdat = !hasDebugLogic ? 0 : pack(wmwtFinalCount);
     'h44 : rdat = !hasDebugLogic ? 0 : 32'hFEED_C0DE;
   endcase
   //$display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
     //$time, wciReq.addr, wciReq.byteEn, rdat);
   wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule


rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  fabRespCredit.load(hasDeepResponseBuffer?1024:16);  // sized to the WMI Response to WSI Master Buffering
  mesgCount <= 0;
  thisMesg  <= unpack(32'hFEFE_FFFE);
  lastMesg  <= unpack(32'hFEFE_FFFE);
  wci.ctlAck;
  $display("[%0d]: %m: Starting SMAdapter smaCtrl:%0x", $time, smaCtrl);
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize); wci.ctlAck; endrule
rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)     wsi_Es <- mkWsiStoES(wsiS.slv);
  Wmi_Em#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32) wmi_Em <- mkWmiMtoEm(wmi.mas);

  interface wciS0 = wci.slv;
  interface wmiM0 = wmi_Em;
  interface wsiM0 = toWsiEM(wsiM.mas); 
  interface wsiS0 = wsi_Es;

endmodule


// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef SMAdapterIfc#(1) SMAdapter4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkSMAdapter4B#(parameter Bit#(32) smaCtrlInit, parameter Bool hasDebugLogic) (SMAdapter4BIfc);
  SMAdapter4BIfc _a <- mkSMAdapter(smaCtrlInit, hasDebugLogic); return _a;
endmodule

typedef SMAdapterIfc#(2) SMAdapter8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkSMAdapter8B#(parameter Bit#(32) smaCtrlInit, parameter Bool hasDebugLogic) (SMAdapter8BIfc);
  SMAdapter8BIfc _a <- mkSMAdapter(smaCtrlInit, hasDebugLogic); return _a;
endmodule

typedef SMAdapterIfc#(4) SMAdapter16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkSMAdapter16B#(parameter Bit#(32) smaCtrlInit, parameter Bool hasDebugLogic) (SMAdapter16BIfc);
  SMAdapter16BIfc _a <- mkSMAdapter(smaCtrlInit, hasDebugLogic); return _a;
endmodule

typedef SMAdapterIfc#(8) SMAdapter32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkSMAdapter32B#(parameter Bit#(32) smaCtrlInit, parameter Bool hasDebugLogic) (SMAdapter32BIfc);
  SMAdapter32BIfc _a <- mkSMAdapter(smaCtrlInit, hasDebugLogic); return _a;
endmodule

