// EDCP.bsv - Ethernet DWORD Control Packet (uses QABS on L2 side)
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This module digests DCP (ad hoc EtherType 0xF040) payloads
// DCP Requests arriving are assumed correct as tagged; upstream logic strips 6+6+2 Byte Ethernet header

package EDCP;

import CPDefs       ::*; 
import E8023        ::*;

import ClientServer ::*; 
import Clocks       ::*;
import Connectable  ::*;
import FIFO         ::*;	
import GetPut       ::*;
import Vector       ::*;

typedef enum {
  NOP      = 4'h0,
  Write    = 4'h1,
  Read     = 4'h2,
  Response = 4'h3
} DCPMesgType deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(8)  tag;
  Bit#(32) initAdvert;
} DCPRequestNOP deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(4)  be;
  Bit#(8)  tag;
  Bit#(32) data;
  Bit#(32) addr;
} DCPRequestWrite deriving (Bits, Eq);

typedef struct {
  Bool     isDO;
  Bit#(4)  be;
  Bit#(8)  tag;
  Bit#(32) addr;
} DCPRequestRead deriving (Bits, Eq);

typedef union tagged {
  DCPRequestNOP    NOP;
  DCPRequestWrite  Write;
  DCPRequestRead   Read;
} DCPRequest deriving (Bits);

typedef enum {
  RESP_OK      = 4'h0,
  RESP_TIMEOUT = 4'h1,
  RESP_ERROR   = 4'h2
} DCPRespCode deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(32)    targAdvert;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseNOP deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseWrite deriving (Bits, Eq);

typedef struct {
  Bool        hasDO;
  Bit#(32)    data;
  Bit#(8)     tag;
  DCPRespCode code;
} DCPResponseRead deriving (Bits, Eq);

typedef union tagged {
  DCPResponseNOP    NOP;
  DCPResponseWrite  Write;
  DCPResponseRead   Read;
} DCPResponse deriving (Bits);

interface EDCPAdapterIfc;
  interface Server#(QABS,QABS)         server; 
  interface Client#(CpReq,CpReadResp)  client; 
endinterface 

(* synthesize *)
module mkEDCPAdapter (EDCPAdapterIfc);
  // FIFOs for Client/Server Interfaces...
  FIFO#(QABS)                ecpReqF     <- mkFIFO;
  FIFO#(QABS)                ecpRespF    <- mkFIFO;

  FIFO#(DCPRequest)          dcpReqF     <- mkFIFO;   // Inbound   DCP Requests
  FIFO#(DCPResponse)         dcpRespF    <- mkFIFO;   // Outbound  DCP Responses
  FIFO#(CpReq)               cpReqF      <- mkFIFO;
  FIFO#(CpReadResp)          cpRespF     <- mkFIFO;
  // The internal state of the DCP module...
  Reg#(Bool)                 doInFlight <- mkReg(False);          // True when a Discovery Operation (DO) is in flight
  Reg#(Maybe#(Bit#(8)))      lastTag    <- mkReg(tagged Invalid);  // The last tag captured (valid or not)
  Reg#(DCPResponse )         lastResp   <- mkRegU;                 // The last CP response sent

  Bit#(32) targAdvert = 32'h4000_0001;  // Set the target advertisement constant

  rule dcp_request;
    let x = dcpReqF.first; dcpReqF.deq;
    case (x) matches
      tagged NOP   .n: begin
          dcpRespF.enq(tagged NOP( DCPResponseNOP{hasDO:n.isDO, targAdvert:targAdvert, tag:n.tag, code:RESP_OK})); // Respond to the NOP
          if (!n.isDO) lastTag <= (tagged Invalid);  // NOPs Invalidate the lastTag so next command is always accepted
          if ( n.isDO) doInFlight <= True;
        end
      tagged Write .w: begin
        if ((isValid(lastTag) && w.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || w.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged WriteRequest( CpWriteReq{dwAddr:truncate(w.addr>>2), byteEn:w.be, data:w.data}));  // Issue the Write
          if (!w.isDO) lastTag <= (tagged Valid w.tag); // Capture the tag into lastTag
          if ( w.isDO) doInFlight <= True;
        end 
        dcpRespF.enq(tagged Write( DCPResponseWrite{hasDO:w.isDO, tag:w.tag, code:RESP_OK})); // Blind ACK the Write regardless if tag match or not
        //TODO: When CP write responses are non-blind (from non-posted requests), make write machine use lastResp like Read
        end
        tagged Read  .r: begin
        if ((isValid(lastTag) && r.tag!=fromMaybe(?,lastTag)) || !isValid(lastTag) || r.isDO) begin // if the lastTag is Valid and the tags dont match OR if the lastTag is Invalid OR a Discovery Op
          cpReqF.enq(tagged ReadRequest(  CpReadReq {dwAddr:truncate(r.addr>>2), byteEn:r.be, tag:r.tag}));    // Issue the Read
          if (!r.isDO) lastTag <= (tagged Valid r.tag); // Capture the tag into lastTag
          if ( r.isDO) doInFlight <= True;
        end else dcpRespF.enq(lastResp);   // Retransmit the lastResp since tags match
        end
    endcase
  endrule

  rule cp_response;
    let y = cpRespF.first; cpRespF.deq;
    DCPResponse dcpr = (tagged Read( DCPResponseRead{hasDO:doInFlight, data:y.data, tag:y.tag, code:RESP_OK}));
    dcpRespF.enq(dcpr);  // Advance the CP Read response
    if (!doInFlight) lastResp <= dcpr;    // Save dcpr in lastResponse for possible re-transmission
    doInFlight <= False;
  endrule


  //mkConnection(toGet(ecpReqF), toPut(ecpRespF));   // Loopback for logic measurement

  interface Server server;  // Outward Facing the L2 Packet Side
    interface request  = toPut(ecpReqF);
    interface response = toGet(ecpRespF);
  endinterface
  interface Client client;  // Inward Facing the FPGA Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule

endpackage







// For reference within this file, remove code when debugged, this code not intended for use here...
`ifdef FROM_GbeLite_Obsolete

  method Action macAddr (MACAddress u);
  method Action l2Dst   (MACAddress d);
  method Action l2Typ   (EtherType  t);
  ...
  method Action macAddr (Bit#(48) u) = macAddress._write(unpack(u));
  method Action l2Dst   (MACAddress d) = l2DstR._write(d);
  method Action l2Typ   (EtherType  t) = l2TypR._write(t);

  MACAddress bAddr = 48'hFF_FF_FF_FF_FF_FF;
  MACAddress uAddr = 48'h00_0A_35_42_01_00;   // A fake Xilinx MAC Addr
//MACAddress uAddr = 48'hA0_36_FA_25_3E_A5;   // A real Ettus N210 MAC Addr

  Reg#(MACAddress)            macAddress          <-  mkReg(uAddr);
  Reg#(MACAddress)            l2DstR              <-  mkRegU;
  Reg#(EtherType)             l2TypR              <-  mkRegU;


  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0101);  // default to PHY MDIO addr 1 ([4:0]) for N210
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  phyMdiInit          <-  mkReg(False);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);          // True when split read

  QBGMACIfc                   gmac                <-  mkQBGMAC(gmii_rx_clk, gmiixo_clk, gmiixo_rst);
  Reg#(MACAddress)            macAddress          <-  mkReg(uAddr);
  Reg#(MACAddress)            l2DstR              <-  mkRegU;
  Reg#(EtherType)             l2TypR              <-  mkRegU;

  Clock  cpClock <- exposeCurrentClock;
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

// sls 2012-08-27 Insist that DCP responses are more urgent than requests...
(* descending_urgency = "dcp_dcp_cp_response, dcp_dcp_dcp_request" *)
(* descending_urgency = "tx_dcp, rx_dcp, rx_data, rx_drop_frame" *)

  rule consume_tx_devnull;
    let t <- edp.server.response.get;
    txEgressCnt <= txEgressCnt + 1;
    merge.iport1.put(t);
  endrule

  rule update_tx_stat;
    txEgressCntCP <= txEgressCnt;  // This wont fire on every cycle as the implicit condition of the CP._write is at a lower clock rate
  endrule

`endif
