// WSICaptureWorker.bsv - Capture and record an incident WSI stream with timestamp
// Copyright (c) 2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import TimeService ::*;

import BRAM        ::*;
import Connectable ::*;
import FIFO        ::*;
import FixedPoint  ::*;
import GetPut      ::*;
import Vector      ::*;


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
    l2NumberDataWords  : 10, // 1K data words
    l2NumberMetaWords  : 10  // 1K meta words
  };
endinstance


interface WSICaptureWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  interface Wti_Es#(64)                                 wtiS0;    // WTI-S Time Input
endinterface 

// Capture Buffer Sizing...
  typedef 1024                   CapBufSizeWords;
  typedef TLog#(CapBufSizeWords) CapLogBufSize;
  typedef Bit#(CapLogBufSize)    CapBufAddr; 


module mkWSICaptureWorker#(parameter Bool hasDebugLogic) (WSICaptureWorkerIfc#(ndw))
  provisos (DWordWidth#(ndw)
          , NumAlias#(TMul#(ndw,32),nd)
          , Add#(a_,32,nd)
          , NumAlias#(TMul#(ndw,4),nbe)
          , Add#(1,b_,TMul#(ndw,32)) 
          , Add#(c_, TLog#(TAdd#(1, TMul#(ndw, 4))), 14)
          , Add#(1, d_, TLog#(TAdd#(1, TMul#(ndw, 4))))  );

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                  wci                 <- mkWciESlave;     // WCI-Slave  convienenice logic
  WsiSlaveIfc#(12,nd,nbe,8,0)   wsiS                <- mkWsiSlave;      // WSI-Slave  convienenice logic
  WtiSlaveIfc#(64)              wtiS                <- mkWtiSlave;      // WTI-Slave  convienenice logic
  Reg#(Bit#(32))                controlReg          <- mkRegU;          // storage for the controlReg
  Reg#(Bit#(32))                metaCount           <- mkRegU;          // Rolling count of messages (metadata)
  Reg#(Bit#(32))                dataCount           <- mkRegU;          // Rolling count of data words
  Wire#(GPS64_t)                nowW                <- mkDWire(0);      // Time Now
  Reg#(Bool)                    isFirst             <- mkReg(True);     // First word of messgge
  Reg#(Bit#(14))                mesgLengthSoFar     <- mkReg(0);        // in Bytes up to 2^14 -1
  Reg#(Bool)                    splitReadInFlight   <- mkReg(False);    // Truen when split read
  FIFO#(Tuple2#(Bool,Bit#(2)))  splaF               <- mkFIFO;          // isData, LSBs of read in flight
  Wire#(StatusReg)              statusReg_w         <- mkWire;


  // Capture Buffer Instantiation...
  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = valueOf(CapBufSizeWords); 
    cfg.latency    = 1;
  Vector#(ndw,BRAM2Port# (CapBufAddr, Bit#(32))) dataBram <- replicateM(mkBRAM2Server(cfg));
  function    BRAMServer#(CapBufAddr, Bit#(32))  getDataPortA (Integer i) = dataBram[i].portA;
  function    BRAMServer#(CapBufAddr, Bit#(32))  getDataPortB (Integer i) = dataBram[i].portB;
  Vector#(ndw,BRAMServer#(CapBufAddr, Bit#(32))) dataBramsA = genWith(getDataPortA);
  Vector#(ndw,BRAMServer#(CapBufAddr, Bit#(32))) dataBramsB = genWith(getDataPortB);

  Vector#(4,  BRAM2Port# (CapBufAddr, Bit#(32))) metaBram <- replicateM(mkBRAM2Server(cfg));
  function    BRAMServer#(CapBufAddr, Bit#(32))  getMetaPortA (Integer i) = metaBram[i].portA;
  function    BRAMServer#(CapBufAddr, Bit#(32))  getMetaPortB (Integer i) = metaBram[i].portB;
  Vector#(4,  BRAMServer#(CapBufAddr, Bit#(32))) metaBramsA = genWith(getMetaPortA);
  Vector#(4,  BRAMServer#(CapBufAddr, Bit#(32))) metaBramsB = genWith(getMetaPortB);


  rule operating_actions (wci.isOperating);
    wsiS.operate();
  endrule

  rule getTime;
    nowW <= unpack(wtiS.now);
  endrule

  Bool captureEnabled = unpack(controlReg[0]);
  Bool wrapInhibit    = unpack(controlReg[1]);

  Bool metaFull = (metaCount>=1024);
  Bool dataFull = (dataCount>=1024);

  rule doMessageAccept (wci.isOperating);
    WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;     // get the request from the slave-cosumer
    Vector#(ndw,Bit#(32)) dvWord = unpack(r.data);   // Stuff 1, 2, or 4 DWORDs into the vWord Vector

    Bool dwm = (r.reqLast);                                  // WSI ends with reqLast, used to make WMI DWM
    Bool zlm = dwm && (r.byteEn=='0) && mesgLengthSoFar==0;  // Zero Length Message is 0 BEs on DWM on the first WSI data cycle
    Bit#(14) mlInc =(dwm) ? pack(extend(countOnes(r.byteEn))) : extend(myByteWidth); // Increment by byteWidth except on last cycle use byteEn
    Bit#(14) mlB   = mesgLengthSoFar + mlInc;                // Current messageLength in Bytes
    mesgLengthSoFar <= (dwm) ? 0 : mlB;                      // Update or clear the length accumulator

    let meta = MesgMeta {length:extend(mlB), opcode:extend(r.reqInfo), nowMS:pack(fxptGetInt(nowW)), nowLS:pack(fxptGetFrac(nowW))};
    Vector#(4,Bit#(32))  mvWord = reverse(unpack(pack(meta))); // reverse makes mkWord[0] len; [1] opcode; [2] nowMS; [3] nowLS

    // When captureEnabled, we take data on every available cycle; and metadata at end...
    if (captureEnabled && (!wrapInhibit || (wrapInhibit && !metaFull && !dataFull))) begin

      dataCount <= dataCount + 1;  // Increment Data Capture Address
      for (Integer i=0; i<valueOf(ndw); i=i+1) begin   // Connect each WSI incident DWORD to its respective BRAM write port...
        let dReq  = BRAMRequest { write:True, address:truncate(dataCount), datain:dvWord[i], responseOnWrite:False };
        dataBramsA[i].request.put(dReq); 
      end

      if (dwm) begin
        metaCount <= metaCount + 1;  // Increment Metadata Capture Address
        for (Integer i=0; i<4; i=i+1) begin
          let mReq  = BRAMRequest { write:True, address:truncate(metaCount), datain:mvWord[i], responseOnWrite:False };
          metaBramsA[i].request.put(mReq); 
        end
        $display("[%0d]: %m: doMessageAccept DWM metaCount:%0x WSI opcode:%0x length:%0x", $time, metaCount, r.reqInfo, mlB);
      end

    end
  endrule


  rule updateStatus;
    StatusReg statusReg = defaultValue;
    statusReg.metaFull = metaFull;
    statusReg.dataFull = dataFull;
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
     case (wciReq.addr[7:0]) matches
       'h00 : controlReg <= unpack(wciReq.data);
       'h04 : metaCount  <= unpack(wciReq.data);
       'h08 : dataCount  <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   Bool splitRead = False;
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   Bit#(2) mSel = wciReq.addr[3:2];
   if (wciReq.addr[31:20] == 'h000) begin
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(controlReg);
       'h04 : rdat = pack(metaCount);
       'h08 : rdat = pack(dataCount);
       'h0C : rdat = pack(statusReg_w);
       // Diagnostic data from WSI slave port...
       'h10 : rdat = !hasDebugLogic ? 0 : extend(pack(wsiS.status));
       'h14 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
       'h18 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
       'h1C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
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
    metaCount  <= 0;  // initialize message count to zero
    dataCount  <= 0;  // initialize data count to zero
    wci.ctlAck;       // acknowledge the initialization operation
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,nd,nbe,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 
  Wti_Es#(64)            wti_Es <- mkWtiStoES(wtiS.slv);  // Convert the conventional to explicit 
  interface wciS0 = wci.slv;
  interface wsiS0 = wsi_Es;
  interface wtiS0 = wti_Es;

endmodule: mkWSICaptureWorker

// Synthesizeable, non-polymorphic modules that use the poly module above...

typedef WSICaptureWorkerIfc#(1) WSICaptureWorker4BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSICaptureWorker4B#(parameter Bool hasDebugLogic) (WSICaptureWorker4BIfc);
  WSICaptureWorker4BIfc _a <- mkWSICaptureWorker(hasDebugLogic); return _a;
endmodule

typedef WSICaptureWorkerIfc#(2) WSICaptureWorker8BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSICaptureWorker8B#(parameter Bool hasDebugLogic) (WSICaptureWorker8BIfc);
  WSICaptureWorker8BIfc _a <- mkWSICaptureWorker(hasDebugLogic); return _a;
endmodule

typedef WSICaptureWorkerIfc#(4) WSICaptureWorker16BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSICaptureWorker16B#(parameter Bool hasDebugLogic) (WSICaptureWorker16BIfc);
  WSICaptureWorker16BIfc _a <- mkWSICaptureWorker(hasDebugLogic); return _a;
endmodule

typedef WSICaptureWorkerIfc#(8) WSICaptureWorker32BIfc;
(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkWSICaptureWorker32B#(parameter Bool hasDebugLogic) (WSICaptureWorker32BIfc);
  WSICaptureWorker32BIfc _a <- mkWSICaptureWorker(hasDebugLogic); return _a;
endmodule
