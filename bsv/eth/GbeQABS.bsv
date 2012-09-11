// GbeQABS.bsv - a Gbe Device (not a worker) with a QABS Typed Client Interface
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// 2012-09-03 ssiegel Evolved out of GbeLite. Removed embedded DCP to EDCP. Put most of removed body in 
// section `define FROM_GbeLite_Obsolete

import E8023        ::*;
import QBGMAC       ::*;
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

interface GbeQABSIfc;
  interface Client#(QABS,QABS)        client;      // Facing Internal FPGA server(s) interface(s)
  method Bool gmRx;
  method Bool gmTx;

  interface GMII_RS                   gmii;        // The GMII link
  interface Reset                     gmii_rstn;   // PHY GMII Reset
  interface Clock                     rxclkBnd;    // PHY GMII RX Clock
  interface MDIO_Pads                 mdio ;       // The MDIO pads
endinterface 

(* synthesize *)
module mkGbeQABS#(parameter Bool hasDebugLogic, 
                            Clock gmii_rx_clk,
                            Clock gmiixo_clk,
                            Reset gmiixo_rst)
                            (GbeQABSIfc);

  //TODO : Scale numbers from 8nS original period to 20nS current period...
  Integer phyResetStart   = 750_000 + 3_125;  // 25 uS Reset Assertion
  Integer phyResetRelease = 750_000;          // 6  mS Reset Recovery (configuration)

  // GMAC Support...
  Reg#(Bit#(32))              gbeControl          <-  mkReg(32'h0000_0101);  // default to PHY MDIO addr 1 ([4:0]) for N210
  MDIO                        mdi                 <-  mkMDIO(6);
  Reg#(Bool)                  phyMdiInit          <-  mkReg(False);
  Reg#(Bool)                  splitReadInFlight   <-  mkReg(False);          // True when split read
  QBGMACIfc                   gmac                <-  mkQBGMAC(gmii_rx_clk, gmiixo_clk, gmiixo_rst);
  Clock  cpClock <- exposeCurrentClock;
  MakeResetIfc                phyRst              <-  mkReset(16, True, cpClock);   
  Reg#(Int#(25))              phyResetWaitCnt     <-  mkReg(fromInteger(phyResetStart));

  // Stats...
  Reg#(Bool)                  ethIngress          <- mkDReg(False);
  Reg#(Bool)                  ethEgress           <- mkDReg(False);
  Reg#(Bit#(32))              rxCount             <-  mkReg(0);
  Reg#(Bit#(32))              txCount             <-  mkReg(0);
  Reg#(Bit#(32))              rxOvfCount          <-  mkReg(0);
  Reg#(Bit#(32))              txUndCount          <-  mkReg(0);

  FIFO#(QABS)                 eReqF               <-  mkFIFO;
  FIFO#(QABS)                 eRespF              <-  mkFIFO;

  Bit#(5) myPhyAddr = gbeControl[4:0];
  Bool txLoopback  = unpack(gbeControl[8]); 
  Bool txDebug     = unpack(gbeControl[9]); 
  Bool phyResetBit = unpack(gbeControl[31]);
  Bool phyResetOK  = (phyResetWaitCnt==0);   // Reset 5 mS config read interval has elapsed

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

  rule rx_pump;
    let rx <- gmac.rx.get;
    eReqF.enq(rx);
    ethIngress <= True;
    rxCount <= rxCount + 1; // TODO: Count RX in Bytes, not in 0-4 Byte QABS word cycles
  endrule

  rule tx_pump;
    let tx = eRespF.first; eRespF.deq;
    gmac.tx.put(tx);
    ethEgress <= True;
    txCount <= txCount + 1; // TODO: Count TX in Bytes, not in 0-4 Byte QABS word cycles
  endrule


  // Interfaces and Methods provided...
  interface Client     client;    
    interface request  = toGet(eReqF);
    interface response = toPut(eRespF);
  endinterface
  method Bool gmRx = ethIngress;
  method Bool gmTx = ethEgress;
  interface GMII_RS    gmii       = gmac.gmii;
  interface Reset      gmii_rstn  = phyRst.new_rst;
  interface Clock      rxclkBnd   = gmac.rxclkBnd;
  interface MDIO_Pads  mdio       = mdi.mdio;
endmodule
