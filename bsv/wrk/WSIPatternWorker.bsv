// WSIPatternWorker.bsv - Pattern generator
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import CounterM    ::*;

import BRAM        ::*;
import Connectable ::*;
import FIFO        ::*;
import FixedPoint  ::*;
import GetPut      ::*;
import Vector      ::*;


// Given a UInt#(np) specifiying how many ones, decode into a little-endian bit vector Bit#(nm) mask of ones...
function Bit#(nm) genLittleOnes (UInt#(np) numOnes);
  Bit#(nm) mask = 0;
  for (UInt#(np) p=0; p<numOnes; p=p+1) mask = mask | (1<<p);
  return (mask);
endfunction


typedef struct {
  Bit#(4) pad;
  Bool    b27;
  Bool    b26;
  Bool    metaFull;
  Bool    dataFull;
  Bit#(4) l2BytesPerDataWord;
  Bit#(4) l2BytesPerMetaWord;
  Bit#(8) l2NumberDataWords;
  Bit#(8) l2NumberMetaWords;
} StatusReg deriving (Bits);

instance DefaultValue#(StatusReg);
  defaultValue = StatusReg {
    pad                : 4'hA,
    b27                : False,
    b26                : False,
    metaFull           : False,
    dataFull           : False,
    l2BytesPerDataWord : 2,  //  4B per word
    l2BytesPerMetaWord : 4,  // 16B per meta
    l2NumberDataWords  : 10, // 1K data words (4  KB)
    l2NumberMetaWords  : 10  // 1K meta words (16 KB)
  };
endinstance

interface WSIPatternWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Em#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiM0;    // WSI-M Stream Output
endinterface 

// Pattern Buffer Sizing...
  typedef 1024                   PatBufSizeWords;
  typedef TLog#(PatBufSizeWords) PatLogBufSize;
  typedef Bit#(PatLogBufSize)    PatBufAddr; 


module mkWSIPatternWorker#(parameter Bool hasDebugLogic) (WSIPatternWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw)
          , NumAlias#(TMul#(ndw,32),nd)
          , Add#(a_,32,nd)
          , NumAlias#(TMul#(ndw,4),nbe)
          , Add#(1,b_,TMul#(ndw,32)) 
          , Add#(c_, TLog#(TAdd#(1, TMul#(ndw, 4))), 14)
          , Add#(1, d_, TLog#(TAdd#(1, TMul#(ndw, 4))))
          , Add#(a__, TMul#(ndw, 4), 32) );

// This function accepts the length of a transfer, knows "ndw" as a side-effect, and either:
// i)  Returns all '1s if the length is alligned and thus all BEs are active
// ii) Returns a littte-endian mask of ones to enable just the bytes in the word that matter
function Bit#(32) byteEnFromLength (Bit#(32) length);
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


  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                  wci                 <- mkWciESlave;     // WCI-Slave  convienenice logic
  WsiMasterIfc#(12,nd,nbe,8,0)  wsiM                <- mkWsiMaster;     // WSI-Master convienenice logic
  Reg#(Bit#(32))                controlReg          <- mkRegU;          // storage for the controlReg
  Reg#(Bit#(32))                mesgCount           <- mkRegU;          // Rolling count of messages (metadata)
  Reg#(Bit#(32))                dataCount           <- mkRegU;          // Rolling count of data words
  Reg#(Bool)                    isFirst             <- mkReg(True);     // First word of message
  Reg#(Bit#(14))                mesgLengthSoFar     <- mkReg(0);        // in Bytes up to 2^14 -1
  Reg#(Bool)                    splitReadInFlight   <- mkReg(False);    // Truen when split read
  FIFO#(Tuple2#(Bool,Bit#(2)))  splaF               <- mkFIFO;          // isData, LSBs of read in flight
  Wire#(StatusReg)              statusReg_w         <- mkWire;

  Reg#(UInt#(32))               mesgRemain          <- mkReg(1);        // Messages Remaining to Send
  CounterM#(Bit#(16))           metaPtr             <- mkCounterM;      // Pointer in BRAM to next Metadata
  Reg#(Bit#(32))                dataPtr             <- mkReg(0);        // Pointer to word Data in BRAM
  FIFO#(Bit#(0))                metaReqInFlightF    <- mkFIFO1;
  FIFO#(Bit#(0))                loopReqInFlightF    <- mkFIFO1;
  Reg#(Bit#(32))                thisLength          <- mkReg(0);
  Reg#(Bit#(32))                bytesRemain         <- mkReg(0);
  Reg#(Bit#(32))                thisOpcode          <- mkReg(0);
  Reg#(Bit#(32))                thisTMS             <- mkReg(0);
  Reg#(Bit#(32))                thisTLS             <- mkReg(0);
  Reg#(UInt#(16))               unrollCnt           <- mkReg(0);
  Reg#(Bool)                    doZLM               <- mkReg(False); 


  // Pattern Buffer Instantiation...
  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = valueOf(PatBufSizeWords); 
    cfg.latency    = 1;
  Vector#(ndw,BRAM2Port# (PatBufAddr, Bit#(32))) dataBram <- replicateM(mkBRAM2Server(cfg));
  function    BRAMServer#(PatBufAddr, Bit#(32))  getDataPortA (Integer i) = dataBram[i].portA;
  function    BRAMServer#(PatBufAddr, Bit#(32))  getDataPortB (Integer i) = dataBram[i].portB;
  Vector#(ndw,BRAMServer#(PatBufAddr, Bit#(32))) dataBramsA = genWith(getDataPortA);
  Vector#(ndw,BRAMServer#(PatBufAddr, Bit#(32))) dataBramsB = genWith(getDataPortB);

  Vector#(4,  BRAM2Port# (PatBufAddr, Bit#(32))) metaBram <- replicateM(mkBRAM2Server(cfg));
  function    BRAMServer#(PatBufAddr, Bit#(32))  getMetaPortA (Integer i) = metaBram[i].portA;
  function    BRAMServer#(PatBufAddr, Bit#(32))  getMetaPortB (Integer i) = metaBram[i].portB;
  Vector#(4,  BRAMServer#(PatBufAddr, Bit#(32))) metaBramsA = genWith(getMetaPortA);
  Vector#(4,  BRAMServer#(PatBufAddr, Bit#(32))) metaBramsB = genWith(getMetaPortB);

  rule operating_actions (wci.isOperating);
    wsiM.operate();
  endrule

  Bool patGenEnabled = unpack(controlReg[0]);

  rule request_meta (wci.isOperating && patGenEnabled && mesgRemain>0) ;
    metaPtr.inc;
    let req  = BRAMRequest { write:False, address:truncate(metaPtr), datain:'0, responseOnWrite:False };
    metaBramsA[0].request.put(req); 
    metaBramsA[1].request.put(req); 
    metaBramsA[2].request.put(req); 
    metaBramsA[3].request.put(req); 
    metaReqInFlightF.enq(?);
    loopReqInFlightF.enq(?);
  endrule

  rule resp_meta (wci.isOperating && mesgRemain>0);
    metaReqInFlightF.deq;
    mesgRemain <= mesgRemain - 1;
    let byteLength <- metaBramsA[0].response.get;
    thisLength  <= byteLength;  // unmodified until next resp_meta
    bytesRemain <= byteLength;
    let to  <- metaBramsA[1].response.get; thisOpcode <= to;
    let tms <- metaBramsA[2].response.get; thisTMS    <= tms;
    let tls <- metaBramsA[3].response.get; thisTLS    <= tls;

    Bool zlm = (byteLength==0);
    doZLM <= zlm;
    Bit#(32) residue = (isAlignedLength(truncate(byteLength))) ? 0 : 1;
    unrollCnt <= (zlm) ? 1 : truncate(unpack((byteLength>>myWordShift) + residue)); 
  endrule

  rule request_data (bytesRemain > 0);
    for (Integer i=0; i<valueOf(ndw); i=i+1) begin 
      let dReq  = BRAMRequest { write:False, address:truncate(dataPtr), datain:0, responseOnWrite:False };
      dataBramsA[i].request.put(dReq); 
    end
    dataPtr <= dataPtr + 1;
    bytesRemain <= (bytesRemain<4) ? 0 : bytesRemain - 4;
  endrule

  rule doMessageEmit (wci.isOperating);
    Vector#(ndw, Bit#(32)) vWord = ?;
    if (doZLM) begin
      doZLM <= False;
    end else begin
      for (Integer i=0; i<valueOf(ndw); i=i+1) vWord[i] <- dataBramsA[i].response.get;
    end
    Bool zlm = (thisLength==0);
    Bool lastWord = (unrollCnt == 1);
    if (zlm || lastWord) loopReqInFlightF.deq; // OK to start next
    wsiM.reqPut.put (WsiReq    {cmd  : WR ,
                             reqLast : lastWord,
                             reqInfo : truncate(thisOpcode),
                        burstPrecise : False,
                         burstLength : (zlm || lastWord) ? 1 : '1,
                               data  : pack(vWord),
                             byteEn  : (zlm) ? '0 : (lastWord) ? truncate(byteEnFromLength(thisLength)) : '1,
                           dataInfo  : '0 });
    if (lastWord) begin
      mesgCount <= mesgCount + 1;
      $display("[%0d]: %m: wsi_source: End of WSI Producer Egress: mesgCount:%0x thisOpcode:%0x thisLength:%0x", $time, mesgCount, thisOpcode, thisLength);
    end
    unrollCnt <= unrollCnt - 1;
    dataCount <= dataCount + 1;
  endrule

  rule updateStatus;
    StatusReg statusReg = defaultValue;
   // statusReg.metaFull = metaFull;
   // statusReg.dataFull = dataFull;
    statusReg_w <= statusReg;
  endrule



  // Control and Configuration operations...
  
  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd, advance_split_response" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE, advance_split_response" *)

  rule advance_split_response (!wci.configWrite && splitReadInFlight);
    let p = splaF.first; splaF.deq();
    Bit#(32) rdata <- (tpl_1(p) ? dataBramsB[tpl_2(p)] : metaBramsB[tpl_2(p)]).response.get;
    wci.respPut.put(WciResp{resp:DVA, data:rdata});
    splitReadInFlight <= False;
    $display("[%0d]: %m: WCI SPLIT READ Data:%0x", $time, rdata);
  endrule

  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
   if (wciReq.addr[31:20] == 'h000) begin
     case (wciReq.addr[7:0]) matches
       'h00 : controlReg <= unpack(wciReq.data);
       'h04 : begin metaPtr.load(0); metaPtr.setModulus(truncate(wciReq.data)); end
       'h08 : mesgCount  <= unpack(wciReq.data);
       'h0C : dataCount  <= unpack(wciReq.data);
       'h10 : mesgRemain <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   end else if (wciReq.addr[31:20] == 'h800) begin // Data Region...
     let dReq  = BRAMRequest {write:True, address:truncate(wciReq.addr[31:2]), datain:wciReq.data, responseOnWrite:False };
      dataBramsB[0].request.put(dReq); 
   end else if (wciReq.addr[31:20] == 'h400) begin // Meta Region...
     let mReq  = BRAMRequest {write:True, address:truncate(wciReq.addr[31:4]), datain:wciReq.data, responseOnWrite:False };
     metaBramsB[wciReq.addr[3:2]].request.put(mReq); 
   end
   wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   Bool splitRead = False;
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   Bit#(2) mSel = wciReq.addr[3:2];
   if (wciReq.addr[31:20] == 'h000) begin
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(controlReg);
       'h08 : rdat = pack(mesgCount);
       'h0C : rdat = pack(dataCount);
       'h10 : rdat = pack(mesgRemain);

       'h1C : rdat = pack(statusReg_w);
       // Diagnostic data from WSI master port...
       'h20 : rdat = !hasDebugLogic ? 0 : extend(pack(wsiM.status));
       'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.pMesgCount);
       'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.iMesgCount);
       'h2C : rdat = !hasDebugLogic ? 0 : pack(wsiM.extStatus.tBusyCount);
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   end else if (wciReq.addr[31:20] == 'h800) begin // Data Region...
     //TODO: Make mSel, etc poly on ndw 1,2,4,8
     //let req  = BRAMRequest { write:False, address:wciReq.addr[13:4], datain:'0, responseOnWrite:False };
     //dataBramsB[mSel].request.put(req); 
     //splaF.enq(tuple2(True, mSel));
     let req  = BRAMRequest { write:False, address:wciReq.addr[11:2], datain:'0, responseOnWrite:False };
     dataBramsB[0].request.put(req); 
     splaF.enq(tuple2(True, 0));
     splitRead = True;
   end else if (wciReq.addr[31:20] == 'h400) begin // Meta Region...
     let req  = BRAMRequest { write:False, address:wciReq.addr[13:4], datain:'0, responseOnWrite:False };
     metaBramsB[mSel].request.put(req); 
     splaF.enq(tuple2(False, mSel));
     splitRead = True;
  end
  if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  else splitReadInFlight <= True;
  endrule
  
  // This rule contains the operations that take place in the Exists->Initialized control edge...
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
    controlReg <= 0;  // initialize control register to zero
    mesgCount  <= 0;  // initialize message count to zero
    dataCount  <= 0;  // initialize data count to zero
    metaPtr.setModulus(1);  // initialize metadata pointer modulus
    wci.ctlAck;       // acknowledge the initialization operation
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  interface wciS0 = wci.slv;
  interface wsiM0 = toWsiEM(wsiM.mas);

endmodule: mkWSIPatternWorker

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WSIPatternWorkerIfc#(1) WSIPatternWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSIPatternWorker4B#(parameter Bool hasDebugLogic) (WSIPatternWorker4BIfc);
  WSIPatternWorker4BIfc _a <- mkWSIPatternWorker(hasDebugLogic); return _a;
endmodule

`ifdef OTHER_WIDTHS

typedef WSIPatternWorkerIfc#(2) WSIPatternWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSIPatternWorker8B#(parameter Bool hasDebugLogic) (WSIPatternWorker8BIfc);
  WSIPatternWorker8BIfc _a <- mkWSIPatternWorker(hasDebugLogic); return _a;
endmodule

typedef WSIPatternWorkerIfc#(4) WSIPatternWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSIPatternWorker16B#(parameter Bool hasDebugLogic) (WSIPatternWorker16BIfc);
  WSIPatternWorker16BIfc _a <- mkWSIPatternWorker(hasDebugLogic); return _a;
endmodule

typedef WSIPatternWorkerIfc#(8) WSIPatternWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSIPatternWorker32B#(parameter Bool hasDebugLogic) (WSIPatternWorker32BIfc);
  WSIPatternWorker32BIfc _a <- mkWSIPatternWorker(hasDebugLogic); return _a;

`end if

endmodule
