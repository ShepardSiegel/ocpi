// GbeWorker.bsv - GbE "device worker" 
// Copyright (c) 2009,2010,2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
//import Ethernet    ::*;
import GMAC        ::*;
import MDIO        ::*;
import SRLFIFO     ::*;
import TimeService ::*;

import Clocks::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import XilinxCells::*;
import XilinxExtra::*;

interface GbeWorkerIfc;
  interface WciES                wciS0;    // WCI
  interface Wti_s#(64)           wtiS0;    // WTI
  interface Wsi_Em#(12,32,4,8,0) wsiM0;    // WSI Rx Packet Stream
  interface Wsi_Es#(12,32,4,8,0) wsiS0;    // WSI Tx Packet Stream

  interface GMII_RS   gmii;        // The GMII link
  interface Reset     gmii_rstn;   // PHY GMII Reset
  interface Clock     rxclk;       // PHY GMII RX Clock
  interface MDIO_Pads mdio ;       // The MDIO pads
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeWorker#(parameter Bool hasDebugLogic, Clock gmii_rx_clk, Clock sys1_clk, Reset sys1_rst) (GbeWorkerIfc);

  WciESlaveIfc                wci                 <-  mkWciESlave; 
  WtiSlaveIfc#(64)            wti                 <-  mkWtiSlave(clocked_by sys1_clk, reset_by sys1_rst); 
  WsiMasterIfc#(12,32,4,8,0)  wsiM                <-  mkWsiMaster; 
  WsiSlaveIfc #(12,32,4,8,0)  wsiS                <-  mkWsiSlave;
  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0007);  // default to PHY MDIO Add 7
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);  // Truen when split read

  GMACIfc                     gmac                <-  mkGMAC(gmii_rx_clk, sys1_clk);

  Reg#(Vector#(4,Bit#(8)))    rxPipe              <-  mkRegU;
  Reg#(UInt#(2))              rxPos               <-  mkReg(0);

  Reg#(Bit#(32))              rxCount             <-  mkReg(0);
  Reg#(Bit#(32))              txCount             <-  mkReg(0);
  Reg#(Bit#(32))              rxOvfCount          <-  mkReg(0);
  Reg#(Bit#(32))              txUndCount          <-  mkReg(0);

  Reg#(Bit#(32))              rxValidNoEOPC       <-  mkReg(0);
  Reg#(Bit#(32))              rxValidEOPC         <-  mkReg(0);
  Reg#(Bit#(32))              rxEmptyEOPC         <-  mkReg(0);
  Reg#(Bit#(32))              rxAbortEOPC         <-  mkReg(0);

  Reg#(UInt#(5))              rxIdx               <-  mkReg(0);
  Reg#(Vector#(16,Bit#(8)))   rxHdrLast           <-  mkRegU;
  Reg#(Bit#(32))              rxLenCount          <-  mkReg(0);
  Reg#(Bit#(32))              rxLenLast           <-  mkRegU;

  FIFOF#(Bit#(8))             daF                 <-  mkSRLFIFOD(3);
  FIFOF#(Bit#(8))             saF                 <-  mkSRLFIFOD(3);
  FIFOF#(ABS)                 loopF               <-  mkSRLFIFOD(4);


  Integer myWordShift = 2; // log2(4) 4B Wide WSI
  Bit#(5) myPhyAddr = gbeControl[4:0];
  Bool txLoopback = unpack(gbeControl[8]); 

  rule inc_rx_overflow  (gmac.rxOverFlow);  rxOvfCount <= rxOvfCount + 1; endrule
  rule inc_tx_underflow (gmac.txUnderFlow); txUndCount <= txUndCount + 1; endrule

  (* fire_when_enabled *) rule wsi_operate (wci.isOperating); wsiM.operate(); wsiS.operate(); endrule

  function Bit#(4) genBE (UInt#(2) p);
    case (p)
      0 : return(4'b0001);
      1 : return(4'b0011);
      2 : return(4'b0111);
      3 : return(4'b1111);
    endcase
  endfunction

  // RX from GMAC...
  rule rx_data (wci.isOperating);
    let rx <- gmac.rx.get;
    rxCount <= rxCount + 1;
    if (rxIdx>=12 && txLoopback) loopF.enq(rx);
    case (rx) matches
      tagged ValidNotEOP .z :  begin
        rxPipe  <= shiftInAt0(rxPipe, z);
        if (rxPos==3) wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:False,reqInfo:0,burstPrecise:False,burstLength:'1,data:pack(rxPipe),byteEn:'1,dataInfo:'0 });
        rxValidNoEOPC <= rxValidNoEOPC + 1;
        rxPos <= rxPos + 1;
        rxLenCount <= rxLenCount + 1;
        rxIdx <= (rxIdx==maxBound) ? rxIdx : rxIdx + 1;
        if (rxIdx<16) rxHdrLast  <= shiftInAt0(rxHdrLast, z);
        if (rxIdx<6 && txLoopback)              daF.enq(z);  // Capture the DA
        if (rxIdx>=6 && rxIdx<12 && txLoopback) saF.enq(z);  // Capture the SA
      end
      tagged ValidEOP    .z :  begin
        let d  = shiftInAt0(rxPipe, z);
        wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:True,reqInfo:0,burstPrecise:False,burstLength:1,data:pack(d),byteEn:genBE(rxPos),dataInfo:'0 });
        rxValidEOPC <= rxValidEOPC + 1;
        rxPos <= 0;
        rxIdx <= 0;
        rxLenCount <= 0;
        rxLenLast <= rxLenCount + 1;
      end
      tagged EmptyEOP       : begin
        wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:True,reqInfo:0,burstPrecise:False,burstLength:1,data:pack(rxPipe),byteEn:genBE(rxPos),dataInfo:'0 });
        rxEmptyEOPC <= rxEmptyEOPC + 1;
        rxPos <= 0;
        rxIdx <= 0;
      end
      tagged AbortEOP       : begin
        rxAbortEOPC <= rxAbortEOPC + 1;
        rxPos <= 0;
        rxIdx <= 0;
      end
    endcase
  endrule

  /*
  let arpReq = {
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 
    8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 
    8'h08, 8'h06, 8'h00, 8'h01, 8'h46, 8'h47, 
    */

  rule tx_loopback (wci.isOperating && loopF.notEmpty);
    if (saF.notEmpty) begin          // Send the SA as the DA
      gmac.tx.put(tagged ValidNotEOP saF.first);
      saF.deq();
    end else if (daF.notEmpty) begin // Send the DA as the SA
      gmac.tx.put(tagged ValidNotEOP daF.first);
      daF.deq();
    end else begin                   // Send the reset of the header and payload unchanged 
      gmac.tx.put(loopF.first);
      loopF.deq();                      
    end
    txCount <= txCount + 1;
  endrule

    

  // TX to GMAC...
  rule tx_data (wci.isOperating);
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get; //nd==32 nopoly
    //FIXME: Logic for first/data/last  sof/bof/eof
    //FIXME get from gmac emac.tx.put(tagged FirstData truncate(w.data)); //TODO: 4B to 1
  endrule



(* descending_urgency = "wci_ctrl_EiI, wci_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
  let wciReq <- wci.reqGet.get;
  if (wciReq.addr[7]==0) begin
    case (wciReq.addr[7:0])
      'h04 : gbeControl <= wciReq.data;
    endcase
  end else begin
    mdi.user.request(MDIORequest{isWrite:True, phyAddr:myPhyAddr, regAddr:wciReq.addr[6:2], data:wciReq.data[15:0]});
  end
  $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
    $time, wciReq.addr, wciReq.byteEn, wciReq.data);
  wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
  Bool splitRead = False;
  Bit#(32) status = extend({pack(wsiM.status),pack(wsiS.status)});
  let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
  if (wciReq.addr[7]==0) begin
    case (wciReq.addr[7:0]) 
      'h00 : rdat = pack(status);
      'h04 : rdat = pack(gbeControl);
      'h08 : rdat = !hasDebugLogic ? 0 : extend({pack(wsiS.status),pack(wsiM.status)});
      'h0C : rdat = !hasDebugLogic ? 0 : wsiS.extStatus.pMesgCount;
      'h10 : rdat = !hasDebugLogic ? 0 : wsiS.extStatus.iMesgCount;
      'h14 : rdat = !hasDebugLogic ? 0 : wsiS.extStatus.tBusyCount;
      'h18 : rdat = !hasDebugLogic ? 0 : wsiM.extStatus.pMesgCount;
      'h1C : rdat = !hasDebugLogic ? 0 : wsiM.extStatus.iMesgCount;
      'h20 : rdat = !hasDebugLogic ? 0 : wsiM.extStatus.tBusyCount;
      'h24 : rdat = !hasDebugLogic ? 0 : rxCount;
      'h28 : rdat = !hasDebugLogic ? 0 : txCount;
      'h2C : rdat = !hasDebugLogic ? 0 : rxOvfCount;
      'h30 : rdat = !hasDebugLogic ? 0 : txUndCount;
      'h34 : rdat = !hasDebugLogic ? 0 : rxValidNoEOPC;
      'h38 : rdat = !hasDebugLogic ? 0 : rxValidEOPC;
      'h3C : rdat = !hasDebugLogic ? 0 : rxEmptyEOPC;
      'h40 : rdat = !hasDebugLogic ? 0 : rxAbortEOPC;
      'h44 : rdat = !hasDebugLogic ? 0 : pack(takeAt(12, rxHdrLast)); 
      'h48 : rdat = !hasDebugLogic ? 0 : pack(takeAt(8,  rxHdrLast)); 
      'h4C : rdat = !hasDebugLogic ? 0 : pack(takeAt(4,  rxHdrLast));
      'h50 : rdat = !hasDebugLogic ? 0 : pack(takeAt(0,  rxHdrLast));
      'h54 : rdat = !hasDebugLogic ? 0 : rxLenLast;
    endcase
  end else begin
    mdi.user.request(MDIORequest{isWrite:False, phyAddr:myPhyAddr, regAddr:wciReq.addr[6:2], data:?});
    splitRead = True;
  end
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   if (!splitRead) wci.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
   else splitReadInFlight <= True;
endrule

rule advance_split_response (!wci.configWrite && splitReadInFlight);
  let r <- mdi.user.response;
  wci.respPut.put(WciResp{resp:DVA, data:extend(r.data)});
  splitReadInFlight <= False;
  $display("[%0d]: %m: WCI SPLIT READ Data:%0x", $time, r.data);
endrule


rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);

  // Interfaces and Methods provided...
  interface Wci_s     wciS0     = wci.slv;
  interface Wti_s     wtiS0     = wti.slv;
  interface Wsi_Em    wsiM0     = toWsiEM(wsiM.mas);
  interface Wsi_Es    wsiS0     = wsi_Es;
  interface GMII_RS   gmii      = gmac.gmii;
  interface Reset     gmii_rstn = gmac.gmii_rstn;
  interface Clock     rxclk     = gmac.rxclk;
  interface MDIO_Pads mdio      = mdi.mdio;
endmodule
