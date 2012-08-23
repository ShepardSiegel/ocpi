// GbeLite.bsv - A Lightweight, non-Worker Gbe Core
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import CPDefs       ::*;
import DCP          ::*;
import EDP          ::*;
import GMAC         ::*;
import MDIO         ::*;
import OCWip        ::*;
import SRLFIFO      ::*;
import TimeService  ::*;

import ClientServer ::*;
import Clocks       ::*;
import Connectable  ::*;
import DReg         ::*;
import FIFO         ::*;	
import FIFOF        ::*;	
import GetPut       ::*;
import StmtFSM      ::*;
import Vector       ::*;
import XilinxCells  ::*;
import XilinxExtra  ::*;

interface GbeLiteIfc;
  method Action macAddr (Bit#(48) u);
  method Bit#(32) dgdpEgressCnt;
  interface Client#(CpReq,CpReadResp) cpClient;    // Control Plane Client
  interface Client#(ABS, ABS)         dpClient;    // Data Plane Client
  interface GMII_RS                   gmii;        // The GMII link
  interface Reset                     gmii_rstn;   // PHY GMII Reset
  interface Clock                     rxclkBnd;    // PHY GMII RX Clock
  interface MDIO_Pads                 mdio ;       // The MDIO pads
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeLite#(parameter Bool hasDebugLogic, Clock gmii_rx_clk, Clock gmiixo_clk, Reset gmiixo_rst, Clock cpClock, Reset cpReset) (GbeLiteIfc);

  Integer phyResetStart   = 750_000 + 3_125;  // 25 uS Reset Assertion
  Integer phyResetRelease = 750_000;          // 6  mS Reset Recovery (configration)

  MACAddress bAddr = 48'hFF_FF_FF_FF_FF_FF;
  MACAddress uAddr = 48'h00_0A_35_42_01_00;   // A fake Xilinx MAC Addr
//MACAddress uAddr = 48'hA0_36_FA_25_3E_A5;   // A real Ettus N210 MAC Addr

  Clock  gmii_clk <- exposeCurrentClock;

  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0101);  // default to PHY MDIO addr 1 ([4:0]) for N210
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  phyMdiInit          <-  mkReg(False);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);          // True when split read

  GMACIfc                     gmac                <-  mkGMAC(gmii_rx_clk, gmiixo_clk);
  CrossingReg#(MACAddress)    macAddressCP        <-  mkNullCrossingReg(gmii_clk, uAddr, clocked_by cpClock, reset_by cpReset);
  Reg#(MACAddress)            macAddress          <-  mkReg(uAddr);

  MakeResetIfc                phyRst              <-  mkReset(16, True, cpClock);   
  Reg#(Int#(25))              phyResetWaitCnt     <-  mkReg(fromInteger(phyResetStart));

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
  Reg#(Bool)                  rxDropFrame         <-  mkReg(False);
  Reg#(Bit#(32))              rxDropCnt           <-  mkReg(0);

  FIFOF#(E8023Header)         rxDCPHdrF           <-  mkFIFOF;
  Reg#(Vector#(14,Bit#(8)))   rxDCPMesg           <-  mkRegU;
  Reg#(UInt#(5))              rxDCPMesgPos        <-  mkReg(0);
  Reg#(Bit#(32))              rxDCPCnt            <-  mkReg(0);
  Reg#(UInt#(8))              rxDCPPLI            <-  mkReg(maxBound);  // max 255B for now
  Reg#(Bit#(8))               rxDCPmt             <-  mkRegU;
  Reg#(Bit#(8))               rxDCPtag            <-  mkRegU;

  Reg#(Bit#(32))              txDCPCnt            <-  mkReg(0);
  FIFO#(E8023Header)          txDCPHdrF           <-  mkFIFO;
  Reg#(UInt#(5))              txDCPPos            <-  mkReg(0);


  FIFOF#(Bit#(32))            txDBGF              <-  mkFIFOF;
  Reg#(UInt#(5))              txDBGPos            <-  mkReg(0);
  Reg#(Bit#(32))              txDBGCnt            <-  mkReg(0);

  DCPAdapterIfc               dcp                 <-  mkDCPAdapterAsync(cpClock, cpReset);
  FIFOF#(DCPResponse)         dcpRespF            <-  mkFIFOF;

  EDPAdapterIfc               edp                 <-  mkEDPAdapterAsync(cpClock, cpReset, 48'h012345, macAddress, 16'hf041);
  FIFO#(ABS)                  edpRxF              <-  mkFIFO;
  //FIFO#(ABS)                  edpTxF              <-  mkFIFO;
  Reg#(Vector#(16,Bit#(8)))   edpDV               <-  mkRegU(clocked_by cpClock, reset_by cpReset);
  Reg#(Bit#(32))              txEgressCnt         <-  mkReg(0);
  Reg#(Bit#(32))              txEgressCntCP       <-  mkSyncRegFromCC(0, cpClock);

  ABSMergeIfc                 merge               <-  mkABSMerge;  // To merge egress packets from DCP and DGDP 



  Integer myWordShift = 2; // log2(4) 4B Wide WSI
  Bit#(5) myPhyAddr = gbeControl[4:0];
  Bool txLoopback  = unpack(gbeControl[8]); 
  Bool txDebug     = unpack(gbeControl[9]); 
  Bool phyResetBit = unpack(gbeControl[31]);
  Bool phyResetOK  = (phyResetWaitCnt==0);   // Reset 5 mS config read interval has elapsed

  rule update_mac_addr;
    macAddress <= macAddressCP.crossed;
  endrule

  rule phy_reset_drive (phyResetWaitCnt > fromInteger(phyResetRelease));
    phyRst.assertReset();  // Assert Phy Reset while count is great than release point
  endrule

  rule phy_reset_wait;
    if (phyResetBit) phyResetWaitCnt <= fromInteger(phyResetStart);
    else phyResetWaitCnt <= (phyResetWaitCnt > 0) ? phyResetWaitCnt-1 : 0;
  endrule

  rule phy_mdio_init (phyResetOK && !phyMdiInit);
    mdi.user.request(MDIORequest{isWrite:True, phyAddr:myPhyAddr, regAddr:28, data:16'hD7F0});
    phyMdiInit <= True;
  endrule

  rule inc_rx_overflow  (gmac.rxOverFlow);  rxOvfCount <= rxOvfCount + 1; endrule
  rule inc_tx_underflow (gmac.txUnderFlow); txUndCount <= txUndCount + 1; endrule

  (* fire_when_enabled *)
  rule gbe_operate (phyMdiInit);
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
      if (rxDCPMesgPos==4) rxDCPmt  <= d; 
      if (rxDCPMesgPos==5) rxDCPtag <= d; 
    endaction);
  endfunction

  function Action rxAdvance (Bool hasData, Bit#(8) d, Bool isEOP, Bool isAbort);
    return ( action
    if (hasData) begin
      rxHdr.shiftIn1(d);
      if (rxLenCount < 16) rxHeadCap <= shiftInAt0(rxHeadCap,d);
      rxPipe  <= shiftInAt0(rxPipe, d);
      if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040 &&& (h.dst==bAddr || h.dst==macAddress) &&& extend(rxDCPMesgPos)<rxDCPPLI)
        rxDCPMesgCapt(d);  // accept only DCP EtherTypes and discard padding
    end
    rxPos      <= (isEOP) ? 0 : rxPos + 1;
    rxLenCount <= (isEOP) ? 0 : rxLenCount + 1;
    if (isEOP) begin
      rxLenLast <= rxLenCount + 1; 
      rxHdrMatchCnt <= (rxHdr.isMatch) ? rxHdrMatchCnt + 1 : rxHdrMatchCnt;
      if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040 && (h.dst==bAddr || h.dst==macAddress)) rxDCPHdrF.enq(h); // capture Ethernet header at good EOP of this DCP message
      else rxDropFrame <= True;  // The EOP has arrived but we care not for this frame, drop it
    end
    endaction);
  endfunction

  rule rx_drop_frame (rxDropFrame);  // Actions to take when we've decided not to use this frame...
    rxHdr.clear;                     // Clear rxHdr state (resetting _pos), this packet means nothing to us
    rxDCPMesgPos <= 0;               // Clear DCP Mesg Capture pointer to zero
    rxDropFrame <= False;            // Do this once per frame
    rxDropCnt <= rxDropCnt + 1;      // Increment diagnostic counter
  endrule


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
    Bool    isDO = unpack(rxDCPmt[6]); // is Discovery Operation 
    Bit#(2) mTyp = rxDCPmt[5:4];
    Bit#(4) mBe  = rxDCPmt[3:0];
    Vector#(4,Bit#(8)) dwa = takeAt(4, rxDCPMesg);
    Vector#(4,Bit#(8)) dwb = takeAt(0, rxDCPMesg);
    DCPMesgType mType = unpack(mTyp);
    case (mType)
      NOP   : dcp.server.request.put(tagged NOP  ( DCPRequestNOP  {isDO:isDO,         tag:rxDCPtag, initAdvert:pack(dwb)}));
      Write : dcp.server.request.put(tagged Write( DCPRequestWrite{isDO:isDO, be:mBe, tag:rxDCPtag, data:pack(dwb), addr:pack(dwa)}));
      Read  : dcp.server.request.put(tagged Read ( DCPRequestRead {isDO:isDO, be:mBe, tag:rxDCPtag, addr:pack(dwb)}));
    endcase
    // Done with request, reset rx for next DCP...
    rxDCPMesgPos <= 0;
    rxDCPPLI <= maxBound;
  endrule
 
  rule tx_dcp_fifo;
    let r <- dcp.server.response.get;
    dcpRespF.enq(r);
  endrule

  rule tx_dcp (dcpRespF.notEmpty);   // Fires when we have a DCP Response Packet is wholly available to TX...
    let rsp = dcpRespF.first;        // Implicit condition on DCP Response 

    // Send the Ethernet header back with the SA/DA fields swapped...
    if (rxHdr matches tagged E8023Head .h &&& h.typ==16'hF040) begin
      let modHead = E8023Header {dst:h.src, src:macAddress, typ:h.typ};
      Vector#(14,Bit#(8)) respHeadV = unpack(pack(modHead)); 
      merge.iport0.put(tagged ValidNotEOP respHeadV[13-txDCPPos]);
      txDCPPos <= (txDCPPos==13) ? 0 : txDCPPos + 1;
      if (txDCPPos==13) rxHdr.clear;  // Release the rxHdr state, we are through with it
    end else begin
      case (rsp) matches
      tagged NOP   .n: begin
                         case (txDCPPos)
                           0: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           1: merge.iport0.put(tagged ValidNotEOP 8'h0A); // NOP reseponse is 10B
                           2: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           3: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           4: merge.iport0.put(tagged ValidNotEOP (n.hasDO ? 8'h70:8'h30)); // DCP Response = OK
                           5: merge.iport0.put(tagged ValidNotEOP n.tag);
                           6: merge.iport0.put(tagged ValidNotEOP n.targAdvert[31:24]);
                           7: merge.iport0.put(tagged ValidNotEOP n.targAdvert[23:16]);
                           8: merge.iport0.put(tagged ValidNotEOP n.targAdvert[15:8]);
                           9: merge.iport0.put(tagged ValidEOP    n.targAdvert[7:0]);
                         endcase 
                         txDCPPos <= (txDCPPos==9) ? 0 : txDCPPos + 1;
                         if (txDCPPos==9) dcpRespF.deq; // Finish
                       end
      tagged Write .w: begin
                         case (txDCPPos)
                           0: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           1: merge.iport0.put(tagged ValidNotEOP 8'h06); // Write reseponse is 6B
                           2: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           3: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           4: merge.iport0.put(tagged ValidNotEOP (w.hasDO ? 8'h70:8'h30)); // DCP Response = OK
                           5: merge.iport0.put(tagged ValidEOP    w.tag);
                         endcase
                         txDCPPos <= (txDCPPos==5) ? 0 : txDCPPos + 1;
                         if (txDCPPos==5) dcpRespF.deq; // Finish
                       end
      tagged Read  .r: begin
                         case (txDCPPos)
                           0: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           1: merge.iport0.put(tagged ValidNotEOP 8'h0A); // Read response is 10B
                           2: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           3: merge.iport0.put(tagged ValidNotEOP 8'h00);
                           4: merge.iport0.put(tagged ValidNotEOP (r.hasDO ? 8'h70:8'h30)); // DCP Response = OK
                           5: merge.iport0.put(tagged ValidNotEOP r.tag);
                           6: merge.iport0.put(tagged ValidNotEOP r.data[31:24]);
                           7: merge.iport0.put(tagged ValidNotEOP r.data[23:16]);
                           8: merge.iport0.put(tagged ValidNotEOP r.data[15:8]);
                           9: merge.iport0.put(tagged ValidEOP    r.data[7:0]);
                         endcase 
                         txDCPPos <= (txDCPPos==9) ? 0 : txDCPPos + 1;
                         if (txDCPPos==9) dcpRespF.deq; // Finish
                       end
      endcase
    end
  endrule


  //rule consume_tx_devnull;
  //  let t <- edp.server.response.get;
  //  txEgressCnt <= txEgressCnt + 1;
  //endrule

  //rule update_tx_stat;
  //  txEgressCntCP <= txEgressCnt;
  //endrule


  //FIXME: No way for DGDP TX to get out!
  //mkConnection(edp.server.response, merge.iport1);  // Connect the dgdp to merge iport1 

  mkConnection(merge.oport, gmac.tx);               // Connect the merge output to the gmac


  // Interfaces and Methods provided...
  method Action macAddr (Bit#(48) u) = macAddressCP._write(unpack(u));
  method Bit#(32)   dgdpEgressCnt = txEgressCntCP;
  interface Client     cpClient   = dcp.client;
  interface Client     dpClient   = edp.client;
  interface GMII_RS    gmii       = gmac.gmii;
  interface Reset      gmii_rstn  = phyRst.new_rst;
  interface Clock      rxclkBnd   = gmac.rxclkBnd;
  interface MDIO_Pads  mdio       = mdi.mdio;
endmodule
