//  Ethernet.bsv - Xilinx V5, V6, S6 Ethernet Wrappers
// Copyright (c) 2008  Bluespec, Inc.   ALL RIGHTS RESERVED.
// Copyright (c) 2010  Atomic Rules LCC ALL RIGHTS RESERVED

package Ethernet;

import Clocks            ::*;
import Vector            ::*;
import GetPut            ::*;
import Gray ::*;
import GrayCounter ::*;
import ClientServer      ::*;
import Connectable       ::*;
import BRAM              ::*;
import FIFO              ::*;
import SpecialFIFOs      ::*;
import XilinxCells       :: *;

import XilinxExtra :: *;

// Types...
typedef Bit#(32)         IPAddress;
typedef Bit#(48)         MACAddress;

typedef union tagged {
  Bit#(8) FirstData;
  Bit#(8) Data;
  Bit#(8) LastData;
} EthernetData deriving (Bits, Eq);

// Functions...
function Bit#(8) getData(EthernetData x);
  case(x) matches
    tagged FirstData .z: return(z);
    tagged      Data .z: return(z);
    tagged  LastData .z: return(z);
  endcase
endfunction

function Bool matchesFirst(EthernetData x);
  case(x) matches
    tagged FirstData .*: return True;
    tagged      Data .*: return False;
    tagged  LastData .*: return False;
  endcase
endfunction
   
function Bool matchesData(EthernetData x);
  case(x) matches
    tagged FirstData .*: return False;
    tagged      Data .*: return True;
    tagged  LastData .*: return False;
  endcase
endfunction
   
function Bool matchesLast(EthernetData x);
  case(x) matches
    tagged FirstData .*: return False;
    tagged      Data .*: return False;
    tagged  LastData .*: return True;
  endcase
endfunction
   
// Interfaces...
(* always_enabled, always_ready *)
interface GMII;
  interface Clock       tx_clk;
  method    Bit#(8)     txd;
  method    Bit#(1)     tx_en;
  method    Bit#(1)     tx_er;
  method    Action      rxd(Bit#(8) i);
  method    Action      rx_dv(Bit#(1) i);
  method    Action      rx_er(Bit#(1) i);
endinterface: GMII

(* always_enabled, always_ready *)
interface MAC_GMII;
  method    Action      txd(Bit#(8) i);
  method    Action      tx_en(Bit#(1) i);
  method    Action      tx_er(Bit#(1) i);
  method    Bit#(8)     rxd;
  method    Bit#(1)     rx_dv;
  method    Bit#(1)     rx_er;
endinterface: MAC_GMII

(* always_enabled, always_ready *)
interface MAC_RX;
  method    Bit#(8)     data;
  method    Bool        data_valid;
  method    Bool        good_frame;
  method    Bool        bad_frame;
  method    Bool        frame_drop;
endinterface: MAC_RX

(* always_enabled, always_ready *)
interface RX_MAC;
  method    Action      data(Bit#(8) i);
  method    Action      data_valid(Bool i);
  method    Action      good_frame(Bool i);
  method    Action      bad_frame(Bool i);
  method    Action      frame_drop(Bool i);
endinterface: RX_MAC

(* always_enabled, always_ready *)
interface MAC_RX_STATS;
  method    Bit#(7)     stats;
  method    Bool        stats_valid;
  method    Bool        stats_byte_valid;
endinterface: MAC_RX_STATS

(* always_enabled, always_ready *)
interface RX_STATS;
  method    Action      stats(Bit#(7) i);
  method    Action      stats_valid(Bool i);
  method    Action      stats_byte_valid(Bool i);
endinterface: RX_STATS

(* always_enabled, always_ready *)
interface MAC_TX;
  interface Clock       clk;
  method    Action      data(Bit#(8) i);
  method    Action      data_valid(Bool i);
  method    Bool        ack;
  method    Action      first_byte(Bool i);
  method    Action      underrun(Bool i);
  method    Bool        collision;
  method    Bool        retransmit;
  method    Action      ifg_delay(Bit#(8) i);
endinterface: MAC_TX   

(* always_enabled, always_ready *)
interface TX_MAC;
  method    Bit#(8)     data;
  method    Bool        data_valid;
  method    Action      ack(Bool i);
  method    Bool        first_byte;
  method    Bool        underrun;
  method    Action      collision(Bool i);
  method    Action      retransmit(Bool i);
  method    Bit#(8)     ifg_delay;
endinterface: TX_MAC

(* always_enabled, always_ready *)
interface MAC_TX_STATS;
  method    Bit#(1)     stats;
  method    Bool        stats_valid;
  method    Bool        stats_byte_valid;
endinterface: MAC_TX_STATS

(* always_enabled, always_ready *)
interface TX_STATS;
  method    Action      stats(Bit#(1) i);
  method    Action      stats_valid(Bool i);
  method    Action      stats_byte_valid(Bool i);
endinterface: TX_STATS
  
interface TEMAC;
  interface GMII         gmii;
  interface MAC_RX       rx;
  interface MAC_RX_STATS rx_stats;
  interface MAC_TX       tx;
  interface MAC_TX_STATS tx_stats;
endinterface: TEMAC

interface GMII_MAC;
  interface GMII        gmii;
  interface MAC_GMII    mac;
endinterface: GMII_MAC

interface RX_MAC_BUFFER;
  interface RX_MAC             rx;
  interface Get#(EthernetData) ingress;
endinterface: RX_MAC_BUFFER
      
interface TX_MAC_BUFFER;
  interface TX_MAC             tx;
  interface Put#(EthernetData) egress;
endinterface: TX_MAC_BUFFER

interface MAC_TO_BUFFER;
  interface RX_MAC_BUFFER      rx;
  interface TX_MAC_BUFFER      tx;
endinterface: MAC_TO_BUFFER

interface EthernetMAC;
  interface GMII               gmii;
  interface Reset              mrst_n;
  interface Clock              rxclk;
  interface Get#(EthernetData) rx;     // Get receive packets
  interface Put#(EthernetData) tx;     // Put transmit packets 
endinterface: EthernetMAC

// V5 Flavor...
import "BVI" v5_emac_v1_6_block = 
module vMkVirtex5EthernetMAC#(Clock gmii_rx_clk)(TEMAC);
  default_clock clk(GTX_CLK_0);                   // Transmit Clock
  default_reset rst(RESET);                       // Active-High Async Reset
  input_clock   (GMII_RX_CLK_0) = gmii_rx_clk;    // Receive Clock from GMII
   
  port CLIENTEMAC0PAUSEREQ   = 0;
  port CLIENTEMAC0PAUSEVAL   = 0;  
   
  interface GMII gmii;
    output_clock                  tx_clk(GMII_TX_CLK_0);
    method GMII_TXD_0             txd                                          clocked_by(gmii_tx_clk) reset_by(rst);
    method GMII_TX_EN_0           tx_en                                        clocked_by(gmii_tx_clk) reset_by(rst);
    method GMII_TX_ER_0           tx_er                                        clocked_by(gmii_tx_clk) reset_by(rst);
    method                        rxd(GMII_RXD_0)     enable((*inhigh*)rxd_en) clocked_by(gmii_rx_clk) reset_by(rst);
    method                        rx_dv(GMII_RX_DV_0) enable((*inhigh*)rdv_en) clocked_by(gmii_rx_clk) reset_by(rst);
    method                        rx_er(GMII_RX_ER_0) enable((*inhigh*)rer_en) clocked_by(gmii_rx_clk) reset_by(rst);
  endinterface: gmii
   
  schedule (gmii_rx_dv, gmii_rx_er) SB (gmii_rxd);
  schedule (gmii_rx_dv, gmii_rx_er) CF (gmii_rx_dv, gmii_rx_er);
  schedule (gmii_rxd) CF (gmii_rxd);
  schedule (gmii_tx_en, gmii_tx_er) SB (gmii_txd);
  schedule (gmii_tx_en, gmii_tx_er) CF (gmii_tx_en, gmii_tx_er);
  schedule (gmii_txd) C (gmii_txd);
   
  interface MAC_RX rx;
    //output_clock                      clk(RX_CLIENT_CLK);
    //output_reset                      rst(RX_CLIENT_RST_N) clocked_by(rx_clk);
    method EMAC0CLIENTRXD             data                 clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXDVLD          data_valid           clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXGOODFRAME     good_frame           clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXBADFRAME      bad_frame            clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXFRAMEDROP     frame_drop           clocked_by(gmii_rx_clk) reset_by(no_reset);
  endinterface: rx
   
  schedule (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop) SB (rx_data);
  schedule (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop) CF (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop);
  schedule (rx_data) CF (rx_data);
   
  interface MAC_RX_STATS rx_stats;
    method EMAC0CLIENTRXSTATS         stats               clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXSTATSVLD      stats_valid         clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMAC0CLIENTRXSTATSBYTEVLD  stats_byte_valid    clocked_by(gmii_rx_clk) reset_by(no_reset);
  endinterface: rx_stats
   
  schedule (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid);
   
  interface MAC_TX tx;
    output_clock                    clk(TX_CLK_OUT); // was TX_CLIENT_CLK before ISE 11.4
    //output_reset                    rst(TX_CLIENT_RST_N)                                         clocked_by (tx_clk);
    method                          data(CLIENTEMAC0TXD)                enable((*inhigh*)entx_0) clocked_by(tx_clk) reset_by(no_reset);
    method                          data_valid(CLIENTEMAC0TXDVLD)       enable((*inhigh*)entx_1) clocked_by(tx_clk) reset_by(no_reset);
    method EMAC0CLIENTTXACK         ack                                                          clocked_by(tx_clk) reset_by(no_reset);
    method                          first_byte(CLIENTEMAC0TXFIRSTBYTE)  enable((*inhigh*)entx_2) clocked_by(tx_clk) reset_by(no_reset);
    method                          underrun(CLIENTEMAC0TXUNDERRUN)  enable((*inhigh*)entx_3)    clocked_by(tx_clk) reset_by(no_reset);
    method EMAC0CLIENTTXCOLLISION   collision                                                    clocked_by(tx_clk) reset_by(no_reset);
    method EMAC0CLIENTTXRETRANSMIT  retransmit                                                   clocked_by(tx_clk) reset_by(no_reset);
    method                          ifg_delay(CLIENTEMAC0TXIFGDELAY)    enable((*inhigh*)entx_4) clocked_by(tx_clk) reset_by(no_reset);
  endinterface: tx
   
   schedule (tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit) SB (tx_data);
   schedule (tx_ack, tx_collision, tx_retransmit, tx_ifg_delay) CF (tx_ack, tx_collision, tx_retransmit, tx_ifg_delay);
   schedule (tx_data) C (tx_data);
   schedule (tx_ack, tx_collision) CF (tx_data_valid, tx_first_byte, tx_underrun);
   schedule (tx_data, tx_data_valid, tx_first_byte, tx_underrun) CF (tx_ifg_delay);
   schedule (tx_data_valid) C (tx_data_valid);
   schedule (tx_data_valid) CF (tx_first_byte, tx_underrun, tx_retransmit);
   schedule (tx_first_byte) C (tx_first_byte);
   schedule (tx_first_byte) CF (tx_data_valid, tx_underrun, tx_retransmit);
   schedule (tx_underrun) C (tx_underrun);
   schedule (tx_underrun) CF (tx_data_valid, tx_first_byte, tx_retransmit);
      
   interface MAC_TX_STATS tx_stats;
      method EMAC0CLIENTTXSTATS         stats               clocked_by(tx_clk) reset_by(no_reset);
      method EMAC0CLIENTTXSTATSVLD      stats_valid         clocked_by(tx_clk) reset_by(no_reset);
      method EMAC0CLIENTTXSTATSBYTEVLD  stats_byte_valid    clocked_by(tx_clk) reset_by(no_reset);
   endinterface: tx_stats
   
   schedule (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid) CF (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid);
   schedule (rx_data, rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop, rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF
      (tx_data, tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit, tx_ifg_delay, tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid);
   schedule (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid) CF (tx_data, tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit, tx_ifg_delay);
   schedule (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF (rx_data, rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop);
endmodule: vMkVirtex5EthernetMAC

// V6 Flavor...
import "BVI" v6_emac_v1_3_block = 
module vMkVirtex6EthernetMAC#(Clock gmii_rx_clk, Clock phy_rx_clk)(TEMAC);
  default_clock clk(TX_CLK);                      // Transmit Clock
  default_reset rst(RESET);                       // Active-High Async Reset
  input_clock   (GMII_RX_CLK) = gmii_rx_clk;      // GMII Receive Clock from BUFIO  (for IOB flops)
  input_clock   (PHY_RX_CLK) = phy_rx_clk;        // EMAC Receive Clock from BUFR   (for EMAC)

  port CLIENTEMACPAUSEREQ   = 0;
  port CLIENTEMACPAUSEVAL   = 0;  
   
  interface GMII gmii;
    output_clock                tx_clk(GMII_TX_CLK);
    method GMII_TXD             txd                                        clocked_by(gmii_tx_clk) reset_by(rst);
    method GMII_TX_EN           tx_en                                      clocked_by(gmii_tx_clk) reset_by(rst);
    method GMII_TX_ER           tx_er                                      clocked_by(gmii_tx_clk) reset_by(rst);
    method                      rxd(GMII_RXD)     enable((*inhigh*)rxd_en) clocked_by(gmii_rx_clk) reset_by(rst);
    method                      rx_dv(GMII_RX_DV) enable((*inhigh*)rdv_en) clocked_by(gmii_rx_clk) reset_by(rst);
    method                      rx_er(GMII_RX_ER) enable((*inhigh*)rer_en) clocked_by(gmii_rx_clk) reset_by(rst);
  endinterface: gmii
   
  schedule (gmii_rx_dv, gmii_rx_er) SB (gmii_rxd);
  schedule (gmii_rx_dv, gmii_rx_er) CF (gmii_rx_dv, gmii_rx_er);
  schedule (gmii_rxd) CF (gmii_rxd);
  schedule (gmii_tx_en, gmii_tx_er) SB (gmii_txd);
  schedule (gmii_tx_en, gmii_tx_er) CF (gmii_tx_en, gmii_tx_er);
  schedule (gmii_txd) C (gmii_txd);
   
  interface MAC_RX rx;
    //output_clock                      clk(RX_CLIENT_CLK);
    //output_reset                      rst(RX_CLIENT_RST_N) clocked_by(rx_clk);
    method EMACCLIENTRXD             data                 clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXDVLD          data_valid           clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXGOODFRAME     good_frame           clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXBADFRAME      bad_frame            clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXFRAMEDROP     frame_drop           clocked_by(gmii_rx_clk) reset_by(no_reset);
  endinterface: rx
   
  schedule (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop) SB (rx_data);
  schedule (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop) CF (rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop);
  schedule (rx_data) CF (rx_data);
   
  interface MAC_RX_STATS rx_stats;
    method EMACCLIENTRXSTATS         stats               clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXSTATSVLD      stats_valid         clocked_by(gmii_rx_clk) reset_by(no_reset);
    method EMACCLIENTRXSTATSBYTEVLD  stats_byte_valid    clocked_by(gmii_rx_clk) reset_by(no_reset);
  endinterface: rx_stats
   
  schedule (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid);
   
  interface MAC_TX tx;
    output_clock                    clk(TX_CLK_OUT);
    method                          data(CLIENTEMACTXD)                enable((*inhigh*)entx_0) clocked_by(tx_clk) reset_by(no_reset);
    method                          data_valid(CLIENTEMACTXDVLD)       enable((*inhigh*)entx_1) clocked_by(tx_clk) reset_by(no_reset);
    method EMACCLIENTTXACK          ack                                                         clocked_by(tx_clk) reset_by(no_reset);
    method                          first_byte(CLIENTEMACTXFIRSTBYTE)  enable((*inhigh*)entx_2) clocked_by(tx_clk) reset_by(no_reset);
    method                          underrun(CLIENTEMACTXUNDERRUN)  enable((*inhigh*)entx_3)    clocked_by(tx_clk) reset_by(no_reset);
    method EMACCLIENTTXCOLLISION    collision                                                   clocked_by(tx_clk) reset_by(no_reset);
    method EMACCLIENTTXRETRANSMIT   retransmit                                                  clocked_by(tx_clk) reset_by(no_reset);
    method                          ifg_delay(CLIENTEMACTXIFGDELAY)    enable((*inhigh*)entx_4) clocked_by(tx_clk) reset_by(no_reset);
  endinterface: tx
   
   schedule (tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit) SB (tx_data);
   schedule (tx_ack, tx_collision, tx_retransmit, tx_ifg_delay) CF (tx_ack, tx_collision, tx_retransmit, tx_ifg_delay);
   schedule (tx_data) C (tx_data);
   schedule (tx_ack, tx_collision) CF (tx_data_valid, tx_first_byte, tx_underrun);
   schedule (tx_data, tx_data_valid, tx_first_byte, tx_underrun) CF (tx_ifg_delay);
   schedule (tx_data_valid) C (tx_data_valid);
   schedule (tx_data_valid) CF (tx_first_byte, tx_underrun, tx_retransmit);
   schedule (tx_first_byte) C (tx_first_byte);
   schedule (tx_first_byte) CF (tx_data_valid, tx_underrun, tx_retransmit);
   schedule (tx_underrun) C (tx_underrun);
   schedule (tx_underrun) CF (tx_data_valid, tx_first_byte, tx_retransmit);
      
   interface MAC_TX_STATS tx_stats;
      method EMACCLIENTTXSTATS         stats               clocked_by(tx_clk) reset_by(no_reset);
      method EMACCLIENTTXSTATSVLD      stats_valid         clocked_by(tx_clk) reset_by(no_reset);
      method EMACCLIENTTXSTATSBYTEVLD  stats_byte_valid    clocked_by(tx_clk) reset_by(no_reset);
   endinterface: tx_stats
   
   schedule (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid) CF (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid);
   
   schedule (rx_data, rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop, rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF
      (tx_data, tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit, tx_ifg_delay, tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid);

   schedule (tx_stats_stats, tx_stats_stats_valid, tx_stats_stats_byte_valid) CF (tx_data, tx_data_valid, tx_ack, tx_first_byte, tx_underrun, tx_collision, tx_retransmit, tx_ifg_delay);
   schedule (rx_stats_stats, rx_stats_stats_valid, rx_stats_stats_byte_valid) CF (rx_data, rx_data_valid, rx_good_frame, rx_bad_frame, rx_frame_drop);
   
endmodule: vMkVirtex6EthernetMAC


// Rx Packet Buffer...
module mkRxPacketBuffer#(Clock wrClk, Reset wrRstN)(RX_MAC_BUFFER);    // The Clock/Reset arguments are emac-client-port-facing write port
  Clock                 coreclk             <- exposeCurrentClock;     // The CC is the user-facing read port
  Reset                 corerst_n           <- exposeCurrentReset;
  // Emac-facing...
  Wire#(Bit#(8))        wData               <- mkWire(clocked_by wrClk, reset_by wrRstN);
  Wire#(Bool)           wDataValid          <- mkWire(clocked_by wrClk, reset_by wrRstN);
  Wire#(Bool)           wGoodFrame          <- mkWire(clocked_by wrClk, reset_by wrRstN);
  Wire#(Bool)           wBadFrame           <- mkWire(clocked_by wrClk, reset_by wrRstN);
  Wire#(Bool)           wFrameDrop          <- mkWire(clocked_by wrClk, reset_by wrRstN);
  PulseWire             pwEnqueue           <- mkPulseWire(clocked_by wrClk, reset_by wrRstN);
  Reg#(Bit#(12))        rWrCurrPtr          <- mkReg(0, clocked_by wrClk, reset_by wrRstN);
  Reg#(Bit#(12))        rWrStartPtr         <- mkReg(0, clocked_by wrClk, reset_by wrRstN); 
  Reg#(Bool)            rInPacket           <- mkReg(False, clocked_by wrClk, reset_by wrRstN);
  GrayCounter#(8)       rWrPackets          <- mkGrayCounter(0, coreclk, corerst_n, clocked_by wrClk, reset_by wrRstN);
  Reg#(Bit#(8))         rData_D1            <- mkRegU(clocked_by wrClk, reset_by wrRstN);

  // MEMORY - Port A Write, Port B Read
  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 4096; // 12b
    cfg.latency    = 1;
  BRAM2Port#(Bit#(12), EthernetData)        memBuffer           <- mkSyncBRAM2Server(cfg, wrClk, wrRstN, coreclk, corerst_n);

  // CLIENT-facing...
  FIFO#(EthernetData)   fifoDeq             <- mkBypassFIFO;
  Reg#(Bit#(12))        rRdCurrPtr          <- mkReg(0);
  Reg#(Bit#(12))        rRdStartPtr         <- mkReg(0);
  GrayCounter#(8)       rRdPackets          <- mkGrayCounter(0, wrClk, wrRstN);
  Reg#(Bool)            rOutPacket          <- mkReg(False);
   
  rule enqueue_first_beat(wDataValid && !rInPacket);
    EthernetData data = tagged FirstData wData;
    rData_D1   <= wData;
    rInPacket  <= True;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrStartPtr, datain: data });
    rWrCurrPtr <= rWrStartPtr + 1;
  endrule
   
  rule enqueue_next_data_beat(wDataValid && !wGoodFrame && !wBadFrame && !wFrameDrop && rInPacket);
    EthernetData data = tagged Data wData;
    rData_D1   <= wData;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrCurrPtr, datain: data });
    rWrCurrPtr <= rWrCurrPtr + 1;
  endrule

  rule commit_packet(wGoodFrame && !wFrameDrop && rInPacket);
    EthernetData data = tagged LastData rData_D1;
    rInPacket  <= False;
    rWrPackets.incr;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrCurrPtr - 1, datain: data });
    rWrStartPtr <= rWrCurrPtr;
  endrule

  rule punt_packet((wBadFrame || wFrameDrop) && !wGoodFrame && rInPacket);
    rInPacket  <= False;
  endrule
   
  rule dequeue_first_beat((rWrPackets.dReadGray != rRdPackets.sReadGray) && !rOutPacket);
    memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdStartPtr, datain: ? });
    rRdCurrPtr <= rRdStartPtr + 1;
    rOutPacket <= True;
  endrule
   
  rule dequeue_next_beat(rOutPacket);
    let data <- memBuffer.portB.response.get;
    fifoDeq.enq(data);
    if (data matches tagged LastData .*) begin
      rOutPacket  <= False;
      rRdStartPtr <= rRdCurrPtr;
      rRdPackets.incr;
    end else begin
      memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdCurrPtr, datain: ? });
      rRdCurrPtr <= rRdCurrPtr + 1;
    end
  endrule
      
  interface RX_MAC rx;
    method Action data(x)       = wData._write(x);
    method Action data_valid(x) = wDataValid._write(x);
    method Action good_frame(x) = wGoodFrame._write(x);
    method Action bad_frame(x)  = wBadFrame._write(x);
    method Action frame_drop(x) = wFrameDrop._write(x);
  endinterface: rx
  interface Get ingress = toGet(fifoDeq);
endmodule: mkRxPacketBuffer

// Tx Packet Buffer...
module mkTxPacketBuffer#(Clock rdClk, Reset rdRstN)(TX_MAC_BUFFER);  // The Clock/Reset arguments are emac-client facing read port
  Clock                coreclk             <- exposeCurrentClock;    // The CC is the user-facing write port
  Reset                corerst_n           <- exposeCurrentReset;
  // CLIENT-facing
  FIFO#(EthernetData)  fifoEnq             <- mkBypassFIFO;
  Reg#(Bit#(12))       rWrCurrPtr          <- mkReg(0);
  Reg#(Bit#(12))       rWrStartPtr         <- mkReg(0);
  GrayCounter#(8)      rWrPackets          <- mkGrayCounter(0, rdClk, rdRstN);
   
  // MEMORY - Port A Write, Port B Read
  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 4096; // 12b
    cfg.latency    = 1;
  BRAM2Port#(Bit#(12), EthernetData)        memBuffer           <- mkSyncBRAM2Server(cfg, coreclk, corerst_n, rdClk, rdRstN);
   
  // EMAC-facing...
  Wire#(Bit#(8))       wDataOut            <- mkDWire(0,     clocked_by rdClk, reset_by rdRstN);
  Wire#(Bool)          wDataValid          <- mkDWire(False, clocked_by rdClk, reset_by rdRstN);
  Wire#(Bool)          wAck                <- mkWire(        clocked_by rdClk, reset_by rdRstN);
  Reg#(Bool)           rUnderrun           <- mkReg(False,   clocked_by rdClk, reset_by rdRstN);
  Wire#(Bool)          wCollision          <- mkWire(        clocked_by rdClk, reset_by rdRstN);
  Wire#(Bool)          wRetransmit         <- mkWire(        clocked_by rdClk, reset_by rdRstN);
  Reg#(Bit#(8))        rIfgDelay           <- mkReg(5,       clocked_by rdClk, reset_by rdRstN);
  Reg#(Bit#(12))       rRdCurrPtr          <- mkReg(0,       clocked_by rdClk, reset_by rdRstN);
  Reg#(Bit#(12))       rRdStartPtr         <- mkReg(0,       clocked_by rdClk, reset_by rdRstN);
  GrayCounter#(8)      rRdPackets          <- mkGrayCounter(0, coreclk, corerst_n, clocked_by rdClk, reset_by rdRstN);
  Reg#(Bool)           rAcked              <- mkReg(False,   clocked_by rdClk, reset_by rdRstN);
  Reg#(Bool)           rOutPacket          <- mkReg(False,   clocked_by rdClk, reset_by rdRstN);

  rule enqueue_first_data_beat(fifoEnq.first matches tagged FirstData .*);
    fifoEnq.deq;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrStartPtr, datain: fifoEnq.first });
    rWrCurrPtr <= rWrStartPtr + 1;
  endrule
   
  rule enqueue_next_data_beat(fifoEnq.first matches tagged Data .*);
    fifoEnq.deq;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrCurrPtr, datain: fifoEnq.first });
    rWrCurrPtr <= rWrCurrPtr + 1;
  endrule
   
  rule enqueue_last_data_beat(fifoEnq.first matches tagged LastData .*);
    fifoEnq.deq;
    memBuffer.portA.request.put(BRAMRequest{ write: True, responseOnWrite: False, address: rWrCurrPtr, datain: fifoEnq.first });
    rWrCurrPtr  <= rWrCurrPtr + 1;
    rWrStartPtr <= rWrCurrPtr + 1;
    rWrPackets.incr;
  endrule
   
  rule dequeue_first_data_beat((rWrPackets.dReadGray != rRdPackets.sReadGray) && !rOutPacket);
    rOutPacket     <= True;
    memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdStartPtr, datain: ? });
    rRdCurrPtr <= rRdStartPtr + 1;
  endrule
   
  (* preempts = "(dequeue_wait_for_ack, dequeue_got_ack, dequeue_next_data_beat), transmit_underrun" *)
  rule dequeue_wait_for_ack(rOutPacket && !rAcked && !wAck);
    let data <- memBuffer.portB.response.get;
    memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdStartPtr, datain: ? });
    wDataOut      <= getData(data);
    wDataValid    <= True;
  endrule
   
  rule dequeue_got_ack(rOutPacket && !rAcked && wAck);
    let data <- memBuffer.portB.response.get;
    memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdCurrPtr, datain: ? });
    rRdCurrPtr    <= rRdCurrPtr + 1; 
    wDataOut      <= getData(data);
    wDataValid    <= True;
    rAcked        <= True;
  endrule
   
  rule dequeue_next_data_beat(rOutPacket && rAcked);
    let data <- memBuffer.portB.response.get;
    wDataOut      <= getData(data);
    wDataValid    <= True;
    case(data) matches
      tagged LastData .*: begin
        rAcked      <= False;
        rOutPacket  <= False;
        rRdStartPtr <= rRdCurrPtr;
        rRdPackets.incr;
      end
      tagged Data .*: begin
      memBuffer.portB.request.put(BRAMRequest{ write: False, responseOnWrite: False, address: rRdCurrPtr, datain: ? });
      rRdCurrPtr  <= rRdCurrPtr + 1;
      end
    endcase
  endrule
   
  rule transmit_underrun(rOutPacket);
    rUnderrun  <= True;
    rOutPacket <= False;
    rAcked     <= False;
  endrule
   
  rule clear_underrun(rUnderrun);
    rUnderrun  <= False;
  endrule
   
  interface TX_MAC tx;
    method Bit#(8) data          = wDataOut;
    method Bool    data_valid    = wDataValid;
    method Action  ack(i)        = wAck._write(i);
    method Bool    first_byte    = False;
    method Bool    underrun      = rUnderrun;
    method Action  collision(i)  = wCollision._write(i);
    method Action  retransmit(i) = wRetransmit._write(i);
    method Bit#(8) ifg_delay     = rIfgDelay;
  endinterface: tx
  interface Put egress = toPut(fifoEnq);
endmodule: mkTxPacketBuffer


/*
// GMII Interface
(* no_default_clock, no_default_reset *)
module mkGMII#(Clock tx_clk, Reset tx_rst_n, Clock rx_clk, Reset rx_rst_n)(GMII_MAC);
  ODDRPrms opms = defaultValue;
  ClockODDR                 rTxClk              <- vClockODDR(opms, 0, 1, clocked_by tx_clk, reset_by tx_rst_n);
  Reg#(Bit#(8))             rTxD                <- mkReg(0, clocked_by tx_clk, reset_by tx_rst_n);
  Reg#(Bit#(1))             rTxEn               <- mkReg(0, clocked_by tx_clk, reset_by tx_rst_n);
  Reg#(Bit#(1))             rTxEr               <- mkReg(0, clocked_by tx_clk, reset_by tx_rst_n);
  Reg#(Bit#(8))             rRxD                <- mkReg(0, clocked_by rx_clk, reset_by rx_rst_n);
  Reg#(Bit#(1))             rRxDv               <- mkReg(0, clocked_by rx_clk, reset_by rx_rst_n);
  Reg#(Bit#(1))             rRxEr               <- mkReg(0, clocked_by rx_clk, reset_by rx_rst_n);
  Wire#(Bit#(8))            wRxD                <- mkWire(  clocked_by rx_clk, reset_by rx_rst_n);
  Wire#(Bit#(1))            wRxDv               <- mkWire(  clocked_by rx_clk, reset_by rx_rst_n);
  Wire#(Bit#(1))            wRxEr               <- mkWire(  clocked_by rx_clk, reset_by rx_rst_n);
  Vector#(8,IDELAY)         ideld               <- replicateM(vIDELAY("FIXED", 0, clocked_by rx_clk, reset_by rx_rst_n));
  IDELAY                    ideldv              <- vIDELAY("FIXED", 0, clocked_by rx_clk, reset_by rx_rst_n);
  IDELAY                    ideler              <- vIDELAY("FIXED", 0, clocked_by rx_clk, reset_by rx_rst_n);
   
  rule connect_idelay_in;
    for(Integer i = 0; i < 8; i = i + 1) ideld[i].i(wRxD[i]);
    ideldv.i(wRxDv);
    ideler.i(wRxEr);
  endrule
   
  rule connect_idelay_out;
    Vector#(8, Bit#(1)) delayD = ?;
    for(Integer i = 0; i < 8; i = i + 1) delayD[i] = ideld[i].o;
    rRxD  <= pack(delayD);
    rRxDv <= ideldv.o;
    rRxEr <= ideler.o;
  endrule
   
  interface GMII gmii;               // Interface that faces the GMII mdeia
    interface tx_clk   = rTxClk.q;
    method  txd      = rTxD;
    method  tx_en    = rTxEn;
    method  tx_er    = rTxEr;
    method  rxd(i)   = wRxD._write(i);
    method  rx_dv(i) = wRxDv._write(i);
    method  rx_er(i) = wRxEr._write(i);
   endinterface: gmii
   interface MAC_GMII mac;          // Interface the faces the MAC
     method txd(i)   = rTxD._write(i);
     method tx_en(i) = rTxEn._write(i);
     method tx_er(i) = rTxEr._write(i);
     method rxd      = rRxD;
     method rx_dv    = rRxDv;
     method rx_er    = rRxEr;      
   endinterface: mac
endmodule: mkGMII
*/

// Ethernet Module...
module mkEthernetMAC#(Clock rx_clk, Clock tx_clk)(EthernetMAC);

  Clock                 clk               <- exposeCurrentClock;  // User-Facing CC for the rx/tx methods
  Reset                 rst_n             <- exposeCurrentReset;

  Reset                 macreset_n        <- mkAsyncReset(12, rst_n, clk);
  Reset                 macreset_inv      <- mkResetInverter(rst_n);                  
  Reset                 macreset_h        <- mkAsyncReset(1, macreset_inv, tx_clk); // active-high for importBVI use

  //IDELAYCTRL            dlyctrl0            <- mkIDELAYCTRL(clocked_by tx_clk);
  // IODELAYs are in GMII as part of "block-level" wrapper
  ClockIODELAY          gmii_rxc_delay    <- vClockIODELAY("FIXED", 0, "I", clocked_by rx_clk);
  Clock                 gmii_rx_clk_delay = gmii_rxc_delay.delayed;
  //Reset                 rx_rst_n          <- mkAsyncReset(1, rst_n, rx_clk);
  Clock                   gmii_rx_clk       <- mkClockBUFIO(clocked_by gmii_rx_clk_delay);
  Clock                   phy_rx_clk        <- mkClockBUFR(BUFRParams{bufr_divide:"BYPASS"}, clocked_by gmii_rx_clk_delay);

  TEMAC                 mac                 <- vMkVirtex6EthernetMAC(gmii_rx_clk, phy_rx_clk, clocked_by tx_clk, reset_by macreset_h);
 // Reset                 ref_rst_n           <- mkAsyncReset(1, rst_n, tx_clk);
 // GMII_MAC              gmi                 <- mkGMII(tx_clk, ref_rst_n, rx_clk, rx_rst_n);

  Clock                 rx_client_clk        = phy_rx_clk;
  Reset                 rx_client_rst_n     <- mkAsyncReset(12, rst_n, rx_client_clk);
  Clock                 tx_client_clk        = mac.tx.clk;
  Reset                 tx_client_rst_n     <- mkAsyncReset(12, rst_n, tx_client_clk);
  RX_MAC_BUFFER         rx_buffer           <- mkRxPacketBuffer(rx_client_clk, rx_client_rst_n);
  TX_MAC_BUFFER         tx_buffer           <- mkTxPacketBuffer(tx_client_clk, tx_client_rst_n);

 // mkConnection(mac.gmii, gmi.mac);
  mkConnection(rx_buffer.rx, mac.rx);
  mkConnection(tx_buffer.tx, mac.tx);
   
  interface gmii      = mac.gmii;
  interface mrst_n    = macreset_n;
  interface rxclk     = phy_rx_clk;
  interface rx        = rx_buffer.ingress;
  interface tx        = tx_buffer.egress;

endmodule: mkEthernetMAC


// Connection Templates...

instance Connectable#(MAC_GMII, GMII);
  module mkConnection#(MAC_GMII m, GMII g)(Empty);
    rule connect_1;
       m.txd(g.txd);
       m.tx_en(g.tx_en);
       m.tx_er(g.tx_er);
    endrule
    rule connect_2;
      g.rxd(m.rxd);
      g.rx_dv(m.rx_dv);
      g.rx_er(m.rx_er);
    endrule
  endmodule
endinstance
instance Connectable#(GMII, MAC_GMII);
  module mkConnection#(GMII g, MAC_GMII m)(Empty);
    mkConnection(m, g);
  endmodule
endinstance

instance Connectable#(MAC_RX, RX_MAC);
  module mkConnection#(MAC_RX m, RX_MAC r)(Empty);
    rule connect;
      r.data(m.data);
      r.data_valid(m.data_valid);
      r.good_frame(m.good_frame);
      r.bad_frame(m.bad_frame);
      r.frame_drop(m.frame_drop);
    endrule
  endmodule
endinstance
instance Connectable#(RX_MAC, MAC_RX);
   module mkConnection#(RX_MAC r, MAC_RX m)(Empty);
      mkConnection(m, r);
   endmodule
endinstance

instance Connectable#(MAC_TX, TX_MAC);
  module mkConnection#(MAC_TX m, TX_MAC t)(Empty);
    rule connect_a; m.data(t.data); endrule
    rule connect_b; t.ack(m.ack); endrule
    rule connect_c; t.collision(m.collision); endrule
    rule connect_d; t.retransmit(m.retransmit); endrule
    rule connect_e; m.data_valid(t.data_valid); endrule
    rule connect_f; m.first_byte(t.first_byte); endrule
    rule connect_g; m.underrun(t.underrun); endrule
    rule connect_h; m.ifg_delay(t.ifg_delay); endrule
  endmodule
endinstance
instance Connectable#(TX_MAC, MAC_TX);
  module mkConnection#(TX_MAC t, MAC_TX m)(Empty);
    mkConnection(m, t);
  endmodule
endinstance

instance Connectable#(MAC_RX_STATS, RX_STATS);
  module mkConnection#(MAC_RX_STATS m, RX_STATS r)(Empty);
    rule connect;
       r.stats(m.stats);
       r.stats_valid(m.stats_valid);
       r.stats_byte_valid(m.stats_byte_valid);
    endrule
  endmodule
endinstance
instance Connectable#(RX_STATS, MAC_RX_STATS);
   module mkConnection#(RX_STATS r, MAC_RX_STATS m)(Empty);
      mkConnection(m, r);
   endmodule
endinstance

instance Connectable#(MAC_TX_STATS, TX_STATS);
  module mkConnection#(MAC_TX_STATS m, TX_STATS t)(Empty);
    rule connect;
      t.stats(m.stats);
      t.stats_valid(m.stats_valid);
      t.stats_byte_valid(m.stats_byte_valid);
    endrule
  endmodule
endinstance
instance Connectable#(TX_STATS, MAC_TX_STATS);
   module mkConnection#(TX_STATS t, MAC_TX_STATS m)(Empty);
      mkConnection(m, t);
   endmodule
endinstance

endpackage: Ethernet
