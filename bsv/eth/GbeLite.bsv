// GbeLite.bsv - A Lightweight, non-Worker Gbe Core
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

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

interface GbeLiteIfc;
  interface Client#(CpReq,CpReadResp) cpClient;

  interface GMII_RS   gmii;        // The GMII link
  interface Reset     gmii_rstn;   // PHY GMII Reset
  interface Clock     rxclkBnd;    // PHY GMII RX Clock
  interface MDIO_Pads mdio ;       // The MDIO pads
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeLite#(parameter Bool hasDebugLogic, Clock gmii_rx_clk, Clock sys1_clk, Reset sys1_rst) (GbeLiteIfc);

  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0101);  // default to PHY MDIO addr 1 ([4:0]) for N210
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);          // True when split read

  GMACIfc                     gmac                <-  mkGMAC(gmii_rx_clk, sys1_clk);
  Reg#(MACAddress)            macAddress          <-  mkReg(48'h00_0A_35_42_01_00);

  MakeResetIfc                phyRst              <-  mkReset(0, True, sys1_clk);   // Use 100 MHz sys0 as sys1 may not be running before reset!
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

  DCPAdapterIfc               dcp                 <-  mkDCPAdapter;
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
  (* fire_when_enabled *)
  rule gbe_operate (phyResetOK);
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
  rule rx_data;
    let rx <- gmac.rx.get;
    rxCount <= rxCount + 1;
    case (rx) matches
      tagged ValidNotEOP .z :  begin
        rxAdvance(True,z,False,False);
        rxValidNoEOPC <= rxValidNoEOPC + 1; // diagnostic
      end
      tagged ValidEOP    .z :  begin
        rxAdvance(True,z,True,False);
        rxValidEOPC <= rxValidEOPC + 1;     // diagnostic
      end
      tagged EmptyEOP       : begin
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
  rule rx_dcp;
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
  endrule
 
  rule tx_dcp_fifo;
    let r <- dcp.server.response.get;
    dcpRespF.enq(r);
  endrule

  rule tx_dcp;   // Fires when we have a DCP Response Packet is wholly available to TX...
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


  // Interfaces and Methods provided...
  interface Client     cpClient   = dcp.client;
  interface GMII_RS    gmii       = gmac.gmii;
  interface Reset      gmii_rstn  = phyRst.new_rst;
  interface Clock      rxclkBnd   = gmac.rxclkBnd;
  interface MDIO_Pads  mdio       = mdi.mdio;
endmodule
