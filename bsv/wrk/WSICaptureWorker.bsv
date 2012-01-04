// WSICaptureWorker.bsv - Capture and record an incident WSI stream with timestamp
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;

import BRAM        ::*;
import Connectable ::*;
import GetPut      ::*;
import Vector      ::*;

interface WSICaptureWorkerIfc#(numeric type ndw);
  interface WciES                                       wciS0;    // Worker Control and Configuration 
  interface Wsi_Es#(12,TMul#(ndw,32),TMul#(ndw,4),8,0)  wsiS0;    // WSI-S Stream Input
  method Action now (Bit#(64) arg);                               // Time
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
          , Add#(1,b_,TMul#(ndw,32)));

  Bit#(8)  myByteWidth  = fromInteger(valueOf(ndw))<<2;          // Width in Bytes
  Bit#(8)  myWordShift  = fromInteger(2+valueOf(TLog#(ndw)));    // Shift amount between Bytes and ndw-wide Words

  WciESlaveIfc                  wci          <- mkWciESlave;     // WCI-Slave  convienenice logic
  WsiSlaveIfc #(12,nd,nbe,8,0)  wsiS         <- mkWsiSlave;      // WSI-Slave  convienenice logic
  Reg#(Bit#(32))                controlReg   <- mkRegU;          // storage for the controlReg
  Reg#(Bit#(32))                mesgCount    <- mkRegU;          // Rolling count of messages
  Reg#(Bit#(32))                dataCount    <- mkRegU;          // Rolling count of data words
  Reg#(Bit#(32))                nextWrite    <- mkRegU;          // Next address to write
  Wire#(Bit#(32))               statusReg    <- mkDWire(0);
  Reg#(Bool)                    isFirst      <- mkReg(True);     // First word of messgge


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

  Bool captureEnabeld = unpack(controlReg[0]);

  rule doMessageAccept (wci.isOperating);
    WsiReq#(12,nd,nbe,8,0) r <- wsiS.reqGet.get;   // get the request from the slave-cosumer
    if (captureEnabled)
      let wreq  = BRAMRequest { write:True, address:truncate(nextWrite), datain:r.data, responseOnWrite:False };
      em[addr[3:2]].request.put(req4); 

      if (r.burstPrecise) begin
        $display("[%0d]: %m: CaptureWorker PRECISE mesgCount:%0x WSI burstLength:%0x reqInfo:%0x", $time, mesgCount, r.burstLength, r.reqInfo);
      end else begin
        $display("[%0d]: %m: CaptureWorker IMPRECISE mesgCount:%0x", $time, mesgCount);
      end
    end
  endrule

  // Control and Configuration operations...
  
  (* descending_urgency = "wci_wslv_ctl_op_complete, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
  (* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)
  
  rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
   let wciReq <- wci.reqGet.get;
     case (wciReq.addr[7:0]) matches
       'h00 : controlReg <= unpack(wciReq.data);
       'h04 : mesgCount  <= unpack(wciReq.data);
       'h08 : dataCount  <= unpack(wciReq.data);
       'h0C : nextWrite  <= unpack(wciReq.data);
     endcase
     $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, wciReq.data);
     wci.respPut.put(wciOKResponse); // write response
  endrule
  
  rule wci_cfrd (wci.configRead);  // WCI Configuration Property Reads...
   let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
     case (wciReq.addr[7:0]) matches
       'h00 : rdat = pack(controlReg);
       'h04 : rdat = pack(mesgCount);
       'h08 : rdat = pack(dataCount);
       'h0C : rdat = pack(nextWrite);
       'h10 : rdat = pack(statusReg);
       'h1C : rdat = 32'hfeed_c0de;
       // Diagnostic data from WSI slave port...
       'h20 : rdat = !hasDebugLogic ? 0 : extend(pack(wsiS.status));
       'h24 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.pMesgCount);
       'h28 : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.iMesgCount);
       'h2C : rdat = !hasDebugLogic ? 0 : pack(wsiS.extStatus.tBusyCount);
     endcase
     $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
     wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
  endrule
  
  // This rule contains the operations that take place in the Exists->Initialized control edge...
  rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
    controlReg <= 0;  // initialize control register to zero
    mesgCount  <= 0;  // initialize message count to zero
    dataCount  <= 0;  // initialize data count to zero
    nextWrite  <= 0;  // initialize last write to all '1 (first write will be at zero, 1, 2, ...)
    wci.ctlAck;       // acknowledge the initialization operation
  endrule

  rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start); wci.ctlAck; endrule
  rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release); wci.ctlAck; endrule

  Wsi_Es#(12,nd,nbe,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 
  interface wciS0 = wci.slv;
  interface wsiS0 = wsi_Es;

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

