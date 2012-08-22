// GbeWorker.bsv - GbE "device worker" 
// Copyright (c) 2009,2010,2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip        ::*;
import CPDefs       ::*;
import GMAC         ::*;
import MDIO         ::*;
import SRLFIFO      ::*;
import TimeService  ::*;
import DCP          ::*;

import ClientServer ::*;
import Clocks       ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;
import XilinxCells  ::*;
import XilinxExtra  ::*;

interface GbeWorkerIfc;
  interface WciES                wciS0;    // WCI
  interface Wti_s#(64)           wtiS0;    // WTI
  interface Wsi_Em#(12,32,4,8,0) wsiM0;    // WSI Rx Packet Stream
  interface Wsi_Es#(12,32,4,8,0) wsiS0;    // WSI Tx Packet Stream
  interface Client#(CpReq,CpReadResp) cpClient;

  interface GMII_RS   gmii;        // The GMII link
  interface Reset     gmii_rstn;   // PHY GMII Reset
  interface Clock     rxclkBnd;    // PHY GMII RX Clock
  interface MDIO_Pads mdio ;       // The MDIO pads
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeWorker#(parameter Bool hasDebugLogic, Clock gmii_rx_clk, Clock sys1_clk, Reset sys1_rst) (GbeWorkerIfc);

  WciESlaveIfc                wci                 <-  mkWciESlave; 
  WtiSlaveIfc#(64)            wti                 <-  mkWtiSlave(clocked_by sys1_clk, reset_by sys1_rst); 
  WsiMasterIfc#(12,32,4,8,0)  wsiM                <-  mkWsiMaster; 
  WsiSlaveIfc #(12,32,4,8,0)  wsiS                <-  mkWsiSlave;
  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0107);  // default to PHY MDIO Add 7
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);          // True when split read

  GMACIfc                     gmac                <-  mkGMAC(gmii_rx_clk, sys1_clk);
  Reg#(MACAddress)            macAddress          <-  mkReg(48'h00_0A_35_42_01_00);
  MakeResetIfc                phyRst              <-  mkReset(1, True, sys1_clk);
  Reg#(Int#(22))              phyResetWaitCnt     <-  mkReg(1250000);

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

  E8023HCapIfc                rxHdr               <-  mkE8023HCap;
  Reg#(Bit#(32))              rxLenCount          <-  mkReg(0);
  Reg#(Bit#(32))              rxLenLast           <-  mkReg(0);
  Reg#(Bit#(32))              rxHdrMatchCnt       <-  mkReg(0);
  Reg#(Vector#(16,Bit#(8)))   rxHeadCap           <-  mkReg(unpack(0));   // Debug Only

  FIFOF#(E8023Header)         rxDCPHdrF           <-  mkFIFOF;
  Reg#(Vector#(14,Bit#(8)))   rxDCPMesg           <-  mkRegU;
  Reg#(UInt#(5))              rxDCPMesgPos        <-  mkReg(0);
  Reg#(Bit#(32))              rxDCPCnt            <-  mkReg(0);
  Reg#(UInt#(8))              rxDCPPLI            <-  mkReg(maxBound);  // max 255B for now

  Reg#(Bit#(32))              txDCPCnt            <-  mkReg(0);
  FIFO#(E8023Header)          txDCPHdrF           <-  mkFIFO;
  Reg#(UInt#(5))              txDCPPos            <-  mkReg(0);


  FIFOF#(Bit#(32))            txDBGF              <-  mkFIFOF;
  Reg#(UInt#(5))              txDBGPos            <-  mkReg(0);
  Reg#(Bit#(32))              txDBGCnt            <-  mkReg(0);

  DCPAdapterIfc               dcp                 <-  mkDCPAdapterSync;
  FIFO#(DCPResponse)          dcpRespF            <-  mkFIFO;


  Integer myWordShift = 2; // log2(4) 4B Wide WSI
  Bit#(5) myPhyAddr = gbeControl[4:0];
  Bool txLoopback  = unpack(gbeControl[8]); 
  Bool txDebug     = unpack(gbeControl[9]); 
  Bool phyReset    = unpack(gbeControl[31]);
  Bool phyResetOK  = (phyResetWaitCnt==0);

  rule phy_reset_drive (phyReset);
    phyRst.assertReset();
  endrule

  rule phy_reset_wait;
    if (phyReset) phyResetWaitCnt <= 1250000;
    else if (phyResetWaitCnt > 0) phyResetWaitCnt <= phyResetWaitCnt - 1;
  endrule

  rule inc_rx_overflow  (gmac.rxOverFlow);  rxOvfCount <= rxOvfCount + 1; endrule
  rule inc_tx_underflow (gmac.txUnderFlow); txUndCount <= txUndCount + 1; endrule

  // Don't start up WSI or GMAC interaction until 10mS after phy Reset...
  (* fire_when_enabled *) rule gbe_operate (wci.isOperating && phyResetOK);
    wsiM.operate();
    wsiS.operate(); 
    gmac.rxOperate();
    gmac.txOperate();
  endrule

  function Bit#(4) genBE (UInt#(2) p);
    case (p)
      0 : return(4'b1111);
      1 : return(4'b0001);
      2 : return(4'b0011);
      3 : return(4'b0111);
    endcase
  endfunction


/*
  The Tagged Union of Type ABS has the following members...

  Tagged     hasData   isEOP  isAbort
  ValidNotEOP   Y      N      N
  ValidEOP      Y      Y      N
  EmptyEOP      N      Y      N
  AbortEOP      N      N      Y

  We may write Action functions to collect the state to update when we haveData, haveEOP, etc.
*/

  function Action rxDCPMesgCapt (Bit#(8) d);
    return ( action
      rxDCPMesg    <= shiftInAt0(rxDCPMesg, d);
      rxDCPMesgPos <= rxDCPMesgPos + 1;
      if (rxDCPMesgPos==1) rxDCPPLI <= unpack(d); // Only look at PLI byte 1 for now (255B max)
    endaction);
  endfunction

  function Action rxAdvance (Bool hasData, Bit#(8) d, Bool isEOP, Bool isAbort);
    return ( action
    if (hasData) begin
      rxHdr.shiftIn1(d);
      if (rxLenCount < 16) rxHeadCap <= shiftInAt0(rxHeadCap,d);
      rxPipe  <= shiftInAt0(rxPipe, d);
      if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040 &&& extend(rxDCPMesgPos)<rxDCPPLI)
        rxDCPMesgCapt(d);  // accept only DCP EtherTypes and discard padding
    end
    rxPos      <= (isEOP) ? 0 : rxPos + 1;
    rxLenCount <= (isEOP) ? 0 : rxLenCount + 1;
    if (isEOP) begin
      rxLenLast <= rxLenCount + 1; 
      rxHdrMatchCnt <= (rxHdr.isMatch) ? rxHdrMatchCnt + 1 : rxHdrMatchCnt;
      if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040) rxDCPHdrF.enq(h); // capture Ethernet header at good EOP of this DCP message
    end
    endaction);
  endfunction


  // RX from GMAC...
  rule rx_data (wci.isOperating);
    let rx <- gmac.rx.get;
    rxCount <= rxCount + 1;
    case (rx) matches
      tagged ValidNotEOP .z :  begin
        //if (rxPos==3) wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:False,reqInfo:0,burstPrecise:False,burstLength:'1,data:pack(rxPipe),byteEn:'1,dataInfo:'0 });
        rxAdvance(True,z,False,False);
        rxValidNoEOPC <= rxValidNoEOPC + 1; // diagnostic
      end
      tagged ValidEOP    .z :  begin
        //wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:True,reqInfo:0,burstPrecise:False,burstLength:1,data:pack(d),byteEn:genBE(rxPos+1),dataInfo:'0 });
        rxAdvance(True,z,True,False);
        rxValidEOPC <= rxValidEOPC + 1;     // diagnostic
      end
      tagged EmptyEOP       : begin
        //wsiM.reqPut.put(WsiReq{cmd:WR,reqLast:True,reqInfo:0,burstPrecise:False,burstLength:1,data:pack(rxPipe),byteEn:genBE(rxPos),dataInfo:'0 });
        rxAdvance(False,?,True,False);
        rxEmptyEOPC <= rxEmptyEOPC + 1;     // diagnostic
      end
      tagged AbortEOP       : begin
        rxAdvance(False,?,True,True);
        rxAbortEOPC <= rxAbortEOPC + 1;     // diagnostic
      end
    endcase
  endrule


  // RX DCP Processing when we have a known good DCP packet
  rule rx_dcp (wci.isOperating);
    let rxh <- toGet(rxDCPHdrF).get;
    Bit#(4) mTyp = (rxDCPMesg[rxDCPMesgPos-5])[7:4];
    Bit#(4) mBe  = (rxDCPMesg[rxDCPMesgPos-5])[3:0];
    Bit#(8) tag  =  rxDCPMesg[rxDCPMesgPos-6];
    Vector#(4,Bit#(8)) dwa = takeAt(4, rxDCPMesg);
    Vector#(4,Bit#(8)) dwb = takeAt(0, rxDCPMesg);
    DCPMesgType mType = unpack(mTyp);
    case (mType)
      NOP   : dcp.server.request.put(tagged NOP  ( DCPRequestNOP  {tag:tag,   initAdvert:pack(dwb)}));
      Write : dcp.server.request.put(tagged Write( DCPRequestWrite{be:mBe, tag:tag, data:pack(dwb), addr:pack(dwa)}));
      Read  : dcp.server.request.put(tagged Read ( DCPRequestRead {be:mBe, tag:tag, addr:pack(dwb)}));
    endcase
    // Done with request, reset rx for next DCP...
    rxDCPMesgPos <= 0;
    rxDCPPLI <= maxBound;

    //let txh = E8023Header {dst:rxh.src, src:macAddress, typ:16'hF040};
    //rxDCPCnt <= rxDCPCnt + 1;
    //txDCPHdrF.enq(txh);
  endrule
 
  rule tx_dcp_fifo (wci.isOperating);    // TODO Replace with GetS
    let r <- dcp.server.response.get;
    dcpRespF.enq(r);
  endrule

  rule tx_dcp (wci.isOperating);   // Fires when we have a DCP Response Packet is wholly available to TX...
    let rsp = dcpRespF.first;

    // Send the Ethernet header back with the SA/DA fields swapped...
    if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040) begin
      let modHead = E8023Header {dst:h.src, src:macAddress, typ:h.typ};
      Vector#(14,Bit#(8)) respHeadV = unpack(pack(modHead)); 
      gmac.tx.put(tagged ValidNotEOP respHeadV[13-txDCPPos]);
      txDCPPos <= (txDCPPos==13) ? 0 : txDCPPos + 1;
      if (txDCPPos==13) rxHdr.clear;
    end else begin
      case (rsp) matches
      tagged NOP   .n: begin
                         case (txDCPPos)
                           0: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           1: gmac.tx.put(tagged ValidNotEOP 8'h0A); // NOP reseponse is 10B
                           2: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           3: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           4: gmac.tx.put(tagged ValidNotEOP 8'h31); // sb 30
                           5: gmac.tx.put(tagged ValidNotEOP n.tag);
                           6: gmac.tx.put(tagged ValidNotEOP n.targAdvert[31:24]);
                           7: gmac.tx.put(tagged ValidNotEOP n.targAdvert[23:16]);
                           8: gmac.tx.put(tagged ValidNotEOP n.targAdvert[15:8]);
                           9: gmac.tx.put(tagged ValidEOP    n.targAdvert[7:0]);
                         endcase 
                         txDCPPos <= (txDCPPos==9) ? 0 : txDCPPos + 1;
                         if (txDCPPos==9) dcpRespF.deq; // Finish
                       end
      tagged Write .w: begin
                         case (txDCPPos)
                           0: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           1: gmac.tx.put(tagged ValidNotEOP 8'h06); // Write reseponse is 6B
                           2: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           3: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           4: gmac.tx.put(tagged ValidNotEOP 8'h32); // sb 30
                           5: gmac.tx.put(tagged ValidEOP    w.tag);
                         endcase
                         txDCPPos <= (txDCPPos==5) ? 0 : txDCPPos + 1;
                         if (txDCPPos==5) dcpRespF.deq; // Finish
                       end
      tagged Read  .r: begin
                         case (txDCPPos)
                           0: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           1: gmac.tx.put(tagged ValidNotEOP 8'h0A); // Read response is 10B
                           2: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           3: gmac.tx.put(tagged ValidNotEOP 8'h00);
                           4: gmac.tx.put(tagged ValidNotEOP 8'h33); // sb 30
                           5: gmac.tx.put(tagged ValidNotEOP r.tag);
                           6: gmac.tx.put(tagged ValidNotEOP r.data[31:24]);
                           7: gmac.tx.put(tagged ValidNotEOP r.data[23:16]);
                           8: gmac.tx.put(tagged ValidNotEOP r.data[15:8]);
                           9: gmac.tx.put(tagged ValidEOP    r.data[7:0]);
                         endcase 
                         txDCPPos <= (txDCPPos==9) ? 0 : txDCPPos + 1;
                         if (txDCPPos==9) dcpRespF.deq; // Finish
                       end
      endcase
    end
  endrule


  /*
  rule tx_loopback (wci.isOperating && txLoopback);
    let txh = txDCPHdrF.first;
    Vector#(14,Bit#(8)) l2h = unpack(pack(txh));
    case (txDCPPos)
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13:
        gmac.tx.put(tagged ValidNotEOP l2h[13-txDCPPos]);
      14, 15:
        gmac.tx.put(tagged ValidNotEOP 8'h0);
      16,17,18:
        gmac.tx.put(tagged ValidNotEOP 8'h0);
      19: begin
        gmac.tx.put(tagged ValidEOP 8'h0);
        txDCPHdrF.deq();
        txDCPCnt <= txDCPCnt + 1;
        rxHdr.clear; //TODO check me
        end
    endcase
    txCount <= txCount + 1;
    txDCPPos <= (txDCPPos==19) ? 0 : txDCPPos + 1;
  endrule

  rule tx_debug (wci.isOperating && txDebug && txDBGF.notEmpty && !rxDCPHdrF.notEmpty);
    let dbd = txDBGF.first;
    Vector#(4,Bit#(8)) dwd = unpack(dbd);
    Vector#(14,Bit#(8)) l2h = unpack({48'hffffffffffff, 48'h212224252627, 16'hF041});
    case (txDBGPos)
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13:
        gmac.tx.put(tagged ValidNotEOP l2h[13-txDBGPos]);
      14,15,16,17:
        gmac.tx.put(tagged ValidNotEOP dwd[17-txDBGPos]);
      18: begin
        gmac.tx.put(tagged ValidEOP 8'h80);
        txDBGF.deq();
        txDBGCnt <= txDBGCnt + 1;
        end
    endcase
    txCount <= txCount + 1;
    txDBGPos <= (txDBGPos==18) ? 0 : txDBGPos + 1;
  endrule
*/
    

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
      'h20 : txDBGF.enq(wciReq.data);
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
    //  'h20 : rdat = !hasDebugLogic ? 0 : wsiM.extStatus.tBusyCount;
      'h20 : rdat = !hasDebugLogic ? 0 : txDBGCnt;
      'h24 : rdat = !hasDebugLogic ? 0 : rxCount;
      'h28 : rdat = !hasDebugLogic ? 0 : txCount;
      'h2C : rdat = !hasDebugLogic ? 0 : rxOvfCount;
      'h30 : rdat = !hasDebugLogic ? 0 : txUndCount;
      'h34 : rdat = !hasDebugLogic ? 0 : rxValidNoEOPC;
      'h38 : rdat = !hasDebugLogic ? 0 : rxValidEOPC;
      'h3C : rdat = !hasDebugLogic ? 0 : rxEmptyEOPC;
      'h40 : rdat = !hasDebugLogic ? 0 : rxAbortEOPC;
      'h44 : rdat = !hasDebugLogic ? 0 : rxDCPCnt;       //18th
      'h48 : rdat = !hasDebugLogic ? 0 : rxHdrMatchCnt;
      'h4C : rdat = !hasDebugLogic ? 0 : rxLenLast;      // 20th
      'h50 : rdat = !hasDebugLogic ? 0 : txDCPCnt;       //21th
      'h54 : rdat = !hasDebugLogic ? 0 : extend(pack(rxHdr.posDbg));
      'h58 : rdat = !hasDebugLogic ? 0 : extend(pack(rxHdr.mCntDbg));
      'h5C : rdat = !hasDebugLogic ? 0 : extend(pack(rxHdr)[111:96]);
      'h60 : rdat = !hasDebugLogic ? 0 : pack(rxHdr)[95:64];
      'h64 : rdat = !hasDebugLogic ? 0 : extend(pack(rxHdr)[63:48]);
      'h68 : rdat = !hasDebugLogic ? 0 : pack(rxHdr)[47:16];
      'h6C : rdat = !hasDebugLogic ? 0 : extend(pack(rxHdr)[15:0]);  // 28
      'h70 : rdat = !hasDebugLogic ? 0 : pack(rxHeadCap)[127:96];
      'h74 : rdat = !hasDebugLogic ? 0 : pack(rxHeadCap)[95 :64];
      'h78 : rdat = !hasDebugLogic ? 0 : pack(rxHeadCap)[63 :32];
      'h7C : rdat = !hasDebugLogic ? 0 : pack(rxHeadCap)[31 :0];  //32
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
  interface Client    cpClient  = dcp.client;
  interface GMII_RS   gmii      = gmac.gmii;
  //interface Reset     gmii_rstn = gmac.gmii_rstn;
  interface Reset     gmii_rstn = phyRst.new_rst;
  interface Clock     rxclkBnd  = gmac.rxclkBnd;
  interface MDIO_Pads mdio      = mdi.mdio;
endmodule
