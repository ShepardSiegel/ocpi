// GbeWorker.bsv - GbE "device worker" 
// Copyright (c) 2009,2010,2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import Ethernet    ::*;
import MDIO        ::*;
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
  interface WciES                wciS1;    // WCI
  interface Wti_s#(64)           wtiS0;    // WTI
  interface Wsi_Em#(12,32,4,8,0) wsiM0;    // WSI Rx Packet Stream
  interface Wsi_Es#(12,32,4,8,0) wsiS0;    // WSI Tx Packet Stream

  interface GMII      gmii;     // The GMII link
  interface Reset     mrst_n;   // GMII associated Reset
  interface Clock     rxclk;    // GMII assocaited Clock
  interface MDIO_Pads mdio ;    // The MDIO pads
endinterface 

(* synthesize, default_clock_osc="wciS0_Clk", default_reset="wciS0_MReset_n" *)
module mkGbeWorker#(parameter Bool hasDebugLogic, Clock gmii_rx_clk, Clock sys1_clk, Reset sys1_rst) (GbeWorkerIfc);

  WciESlaveIfc                wciRx        <-  mkWciESlave; 
  WciESlaveIfc                wciTx        <-  mkWciESlave; 
  WtiSlaveIfc#(64)            wti          <-  mkWtiSlave(clocked_by sys1_clk, reset_by sys1_rst); 
  WsiMasterIfc#(12,32,4,8,0)  wsiM         <-  mkWsiMaster; 
  WsiSlaveIfc #(12,32,4,8,0)  wsiS         <-  mkWsiSlave;
  Reg#(Bit#(32))              gbeControl   <-  mkReg(32'h0000_0007);  // default to PHY MDIO Add 7
  EthernetMAC                 emac         <-  mkEthernetMAC(gmii_rx_clk, sys1_clk);
  MDIO                        mdi          <-  mkMDIO(6);

  Integer myWordShift = 2; // log2(4) 4B Wide WSI
  Bit#(5) myPhyAddr = gbeControl[4:0];

  (* fire_when_enabled *) rule wsi_operate (wciRx.isOperating); wsiM.operate(); wsiS.operate(); endrule

  // RX from EMAC...
  rule rx_data (wciRx.isOperating);
    let s <- emac.rx.get;
    wsiM.reqPut.put (WsiReq     {cmd  : WR ,
                              reqLast : matchesLast(s),
                              reqInfo : 0,  // TODO: Opcode
                         burstPrecise : False,
                          burstLength : (matchesLast(s)) ? 1 : '1,
                                data  : extend(getData(s)), // TODO: 1B unto 4
                              byteEn  : '1,
                            dataInfo  : '0 });
  endrule

  // TX to EMAC...
  rule tx_data (wciRx.isOperating);
    WsiReq#(12,32,4,8,0) w <- wsiS.reqGet.get; //nd==32 nopoly
    //FIXME: Logic for first/data/last  sof/bof/eof
    emac.tx.put(tagged FirstData truncate(w.data)); //TODO: 4B to 1
  endrule



(* descending_urgency = "wci_ctrl_EiI, wciRx_wslv_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wciRx.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wciRx.reqGet.get;
   if (wciReq.addr[7]==0) begin
     case (wciReq.addr[7:0])
       'h04 : gbeControl <= wciReq.data;
     endcase
   end else begin
     mdi.user.request(MDIORequest{isWrite:True, phyAddr:myPhyAddr, regAddr:wciReq.addr[6:2], data:wciReq.data[15:0]});
   end
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wciRx.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wciRx.configRead); // WCI Configuration Property Reads...
 Bit#(32) status = extend({pack(wsiM.status),pack(wsiS.status)});
 let wciReq <- wciRx.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(status);
     'h04 : rdat = pack(gbeControl);
     'h10 : rdat = wsiM.extStatus.pMesgCount;
     'h14 : rdat = wsiM.extStatus.iMesgCount;
     'h18 : rdat = wsiS.extStatus.pMesgCount;
     'h1C : rdat = wsiS.extStatus.iMesgCount;
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x", $time, wciReq.addr, wciReq.byteEn, rdat);
   wciRx.respPut.put(WciResp{resp:DVA, data:rdat}); // read response
endrule

rule wci_ctrl_EiI (wciRx.ctlState==Exists && wciRx.ctlOp==Initialize);
  wciRx.ctlAck;
endrule

rule wci_ctrl_IsO (wciRx.ctlState==Initialized && wciRx.ctlOp==Start);
  wciRx.ctlAck;
endrule

rule wci_ctrl_OrE (wciRx.isOperating && wciRx.ctlOp==Release);
  wciRx.ctlAck;
endrule

  Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);

  // Interfaces and Methods provided...
  interface Wci_s     wciS0  = wciRx.slv;
  interface Wci_s     wciS1  = wciTx.slv;
  interface Wti_s     wtiS0  = wti.slv;
  interface Wsi_Em    wsiM0  = toWsiEM(wsiM.mas);
  interface Wsi_Es    wsiS0  = wsi_Es;
  interface           gmii   = emac.gmii;
  interface           mrst_n = emac.mrst_n;
  interface           rxclk  = emac.rxclk;
  interface MDIO_Pads mdio   = mdi.mdio;
endmodule
