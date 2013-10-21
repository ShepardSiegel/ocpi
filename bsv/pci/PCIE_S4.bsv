// PCIE_S4.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE_S4;

import DwordShifter      ::*;
import PCIEDefs         ::*;

import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import FIFOLevel         ::*;

// Altera Avalon-SX...
import "BVI" pcie_hip_s4gx_gen2_x4_128_wrapper =
module vMkStratix4PCIExpress#(Clock sclk, Reset srstn, Clock pclk, Reset prstn) (PCIE_vS4GX#(lanes))
   provisos(Add#(lanes, 0, 4));

   input_clock sclk    (sys0_clk)                   = sclk;
   input_reset srstn   (sys0_rstn) clocked_by(sclk) = srstn;
   default_clock       (pcie_clk)  = pclk;
   default_reset prstn (pcie_rstn) = prstn;

   interface PCIE_EXP_ALT pcie;
      method                            rx(pcie_rx_in)     enable((*inhigh*)en00)  reset_by(no_reset);
      method pcie_tx_out                tx                                         reset_by(no_reset);
      //method                            prsnt(pcie_prsnt)  enable((*inhigh*)en01)  reset_by(no_reset);
      //method pcie_waken                 waken                                      reset_by(no_reset);
   endinterface

   interface PCIE_AVALONST ava;
      output_clock                      clk(ava_core_clk_out);
      output_reset                      usr_rst(ava_srstn)                  clocked_by(ava_clk);
      method ava_alive                  alive                               clocked_by(no_clock) reset_by(no_reset); 
      method ava_lnk_up                 lnk_up                              clocked_by(no_clock) reset_by(no_reset); 
      method ava_debug                  debug                               clocked_by(no_clock) reset_by(no_reset); 
   endinterface

   interface PCIE_AVALONST_RX ava_rx;
      method                            mask(rx_st_mask0)    enable((*inhigh*)en04) clocked_by(ava_clk) reset_by(no_reset);
      method                            rdy (rx_st_ready0)   enable((*inhigh*)en05) clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_valid0  valid                                                 clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_bardec0 bar                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_be0     be                                                    clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_data0   data                                                  clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_sop0    sop                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_eop0    eop                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_empty0  empty                                                 clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_err0    err                                                   clocked_by(ava_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AVALONST_TX ava_tx;
      method                            data (tx_st_data0)  enable((*inhigh*)en06) clocked_by(ava_clk) reset_by(no_reset);
      method                            sop  (tx_st_sop0)   enable((*inhigh*)en07) clocked_by(ava_clk) reset_by(no_reset);
      method                            eop  (tx_st_eop0)   enable((*inhigh*)en08) clocked_by(ava_clk) reset_by(no_reset);
      method                            empty(tx_st_empty0) enable((*inhigh*)en09) clocked_by(ava_clk) reset_by(no_reset);
      method                            valid(tx_st_valid0) enable((*inhigh*)en10) clocked_by(ava_clk) reset_by(no_reset);
      method                            err  (tx_st_err0)   enable((*inhigh*)en11) clocked_by(ava_clk) reset_by(no_reset);
      method    tx_st_ready0   tready                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tx_cred0       credit                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tx_fifo_empty0 fEmpty                                              clocked_by(ava_clk) reset_by(no_reset);
   endinterface

   interface PCIE_ALT_CFG cfg;
      method    tl_cfg_add     addr                                                clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_ctl     data                                                clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_ctl_wr  dataWrite                                           clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_sts     status                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_sts_wr  statusWrite                                         clocked_by(ava_clk) reset_by(no_reset);
   endinterface

     schedule (pcie_rx, pcie_tx, ava_alive, ava_lnk_up, ava_debug, ava_rx_mask, ava_rx_rdy, ava_rx_valid, ava_rx_bar, ava_rx_be, ava_rx_data, ava_rx_sop, ava_rx_eop, ava_rx_empty, ava_rx_err, ava_tx_data, ava_tx_sop, ava_tx_eop, ava_tx_empty, ava_tx_valid, ava_tx_err, ava_tx_tready, ava_tx_credit, ava_tx_fEmpty, cfg_addr, cfg_data, cfg_dataWrite, cfg_status, cfg_statusWrite) CF
     (pcie_rx, pcie_tx, ava_alive, ava_lnk_up, ava_debug, ava_rx_mask, ava_rx_rdy, ava_rx_valid, ava_rx_bar, ava_rx_be, ava_rx_data, ava_rx_sop, ava_rx_eop, ava_rx_empty, ava_rx_err, ava_tx_data, ava_tx_sop, ava_tx_eop, ava_tx_empty, ava_tx_valid, ava_tx_err, ava_tx_tready, ava_tx_credit, ava_tx_fEmpty, cfg_addr, cfg_data, cfg_dataWrite, cfg_status, cfg_statusWrite);

endmodule: vMkStratix4PCIExpress 

////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Altera S4 GX - Avalon-ST Interface
///
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointS4GX#(Clock sclk, Reset srstn, Clock pclk, Reset prstn)(PCIE_S4GX#(lanes))
  provisos(Add#(lanes, 0, 4));

  PCIE_vS4GX#(4)    pcie_ep     <- vMkStratix4PCIExpress(sclk, srstn, pclk, prstn);
  Clock             ava125Clk   = pcie_ep.ava.clk; 
  Reset             ava125Rst   = pcie_ep.ava.usr_rst;

  // Was DWire, made DReg to add one cycle of readLatency
  //Reg#(TLPDataA#(16)) avaTxD     <- mkDReg(unpack(0), clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxValid  <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxErr    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxSop    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxEop    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxEmpty  <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);

  // Avalon-ST RX qword-allignment bubble removal
  FIFOLevelIfc#(TLPDataA#(16), 32) rxInF         <- mkFIFOLevel( clocked_by ava125Clk, reset_by ava125Rst);  // Purposefully depth-3 for Avalon variable latency flow control
  FIFOF#(TLPHeadInfo)              rxHeadF       <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  DwordShifter#(4,4,8)             rxDws         <- mkDwordShifter( clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(UInt#(3))                 rxEofF        <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(TLPData#(16))             rxOutF        <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                       rxInFlight    <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(11))                  rxDwrEnq      <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(11))                  rxDwrDeq      <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);

  Reg#(UInt#(16))                  rxDbgInstage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgEnstage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgDestage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgEnSof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgEnEof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgDeSof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgDeEof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgEnEnq    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  rxDbgDeDeq    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);

  // Avalon-ST TX qword-allignment bubble insertion
  FIFOF#(TLPData#(16))             txInF         <- mkFIFOF(     clocked_by ava125Clk, reset_by ava125Rst); 
  FIFOF#(TLPHeadInfo)              txHeadF       <- mkFIFOF(     clocked_by ava125Clk, reset_by ava125Rst);
  DwordShifter#(4,4,8)             txDws         <- mkDwordShifter ( clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(UInt#(3))                 txEofF        <- mkFIFOF(     clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(UInt#(1))                 txExF         <- mkFIFOF(     clocked_by ava125Clk, reset_by ava125Rst);  // Signals OK to tx_exstage
  FIFOLevelIfc#(TLPDataA#(16),515) txOutF        <- mkFIFOLevel( clocked_by ava125Clk, reset_by ava125Rst);  // 512 x 16B = 4KB + 3 words
  Reg#(Bool)                       txInFlight    <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(11))                  txDwrEnq      <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(11))                  txDwrDeq      <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                       txReadyD      <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);

  Reg#(UInt#(16))                  txDbgEnstage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgDestage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgExstage  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgEnSof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgEnEof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgDeSof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgDeEof    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgEnEnq    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(16))                  txDbgDeDeq    <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
 
  Reg#(Bool)                       cfgDataWr     <- mkReg(?,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                       cfgSample     <- mkReg(?,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(PciId)                      deviceReg     <- mkReg(?,     clocked_by ava125Clk, reset_by ava125Rst);

  rule update_txReadyD; // one cycle delay of tx_st_ready per Altera spec  (table 5-4 page 5-15 IP Compiler PCIe guide May 2011)
    txReadyD <= pcie_ep.ava_tx.tready;
  endrule

  // Make a cfgSample pulse on the edge after dataWrite changes...
  rule cfg_sample;
    cfgDataWr <= pcie_ep.cfg.dataWrite;
    cfgSample <= (cfgDataWr != pcie_ep.cfg.dataWrite);
  endrule

  // Configuration capture logic...
  rule capture_deviceid (cfgSample && pcie_ep.cfg.addr == 4'hF); // capture cfg_busdev
    deviceReg <= PciId { bus:pcie_ep.cfg.data[12:5], dev:pcie_ep.cfg.data[4:0], func:0 } ;
  endrule

  //
  // Downstream Avalon-ST to TRN

  rule connect_ava_rx_mask;
    pcie_ep.ava_rx.mask(False); // No non-posted back pressure. 26 more NP requests may come after this is asserted (128b Avalon-ST)
  endrule

  rule connect_ava_rx_rdy;
    pcie_ep.ava_rx.rdy(rxInF.isLessThan(30)); // 1 element in rxInF means at least 2 more may follow after Avalon-Ready is de-asserted
  endrule

  rule rx_instage (pcie_ep.ava_rx.valid);  // instage brings guarded FIFO semantics to Avalon-ST (removes variable read latency)
    Bit#(8) bar = 0;
    if(pcie_ep.ava_rx.sop) begin  // Avalon bardec is only valid on SOP
      TLPPacketType pktType = unpack(pcie_ep.ava_rx.data[28:24]);
      bar = (pktType==MEMORY_READ_WRITE) ? pcie_ep.ava_rx.bar : 0; // zero out Bar for non-memory requests
    end
    rxInF.enq(TLPDataA {  
      empty: pcie_ep.ava_rx.empty,     // When empty asserted, there is no data in upper 64b of data - qualifies byte-enables
      sof:   pcie_ep.ava_rx.sop,
      eof:   pcie_ep.ava_rx.eop,
      hit:   bar,                      // bar/hit is only valid on sop/sof
      be:    pcie_ep.ava_rx.be,        // 16b BEs qualify the data (true=valid) in little-endian format' when empty asserted, only lower 8b are valid
      data:  pcie_ep.ava_rx.data });   // 16B data is little-endian; except PCIe header bytes are byte-wise big-endian within each DWORD

    rxDbgInstage <= rxDbgInstage + 1;
  endrule

  // When RX packets are available in rxInF, we consume then and then enstage enq into HeadF, Dws, and Eof

  // These rx_enstage operations are about removing the Avalon Spexcificiity and making PCIe generic
  // All DWORDs from insatge are LE; but the header-only is Byte-Wise BE
  // We will Byte-Reverse ONLY the Header, so EVERYTHING enqueued into rxDws is both DWORD and BYTE wise Little-Endian

  // AV-ST to PCIe... 
  rule rx_enstage (rxDws.space_available >= 4);  // enstage is only ready when 4 or more locations are open in rxDws (the max we may need)
    let prx = rxInF.first; rxInF.deq();  // take a packet-fragment from rxInF

    // bit 2 of the request address at Header Byte 11 - bubble when alligned (and a MEM_WRITE); If we are a read request, we are not a bubble...
    Bool rxBubble   = prx.sof && !unpack(prx.data[66]) && unpack(prx.data[30]);  // fmt[1] indicates "with data" (e.g. MemWrt)
    Bool is4DWHead  = prx.sof                          && unpack(prx.data[29]);  // fmt[0] indicates 4DW head vs. 3DW head
    Bool hasPayload = prx.sof                          && unpack(prx.data[30]);  // fmt[1] indicates "with data" (e.g. MemWrt)

    // Regardless of "bubbles" and "straddling" the information in length conveys exactly how many DWORDs are in this packet
    // This is useful for the rule on the downstream side to know exactly how many DWORDs to take out...
    TLPPacketFormat tpf = unpack(prx.data[30:29]);
    TLPLength       len = unpack(prx.data[9:0]);
    UInt#(11) realDWlength = (is4DWHead?4:3) + (hasPayload?decodeDWlength(len):0); // Header Length + Payload Length (if any)
    /*
    case (tuple2(is4DWHead,hasPayload)) matches
      {False, True}  : realDWlength = 3 + decodeDWlength(len); 
      {True,  True}  : realDWlength = 4 + decodeDWlength(len);
      {False, False} : realDWlength = 3;
      {True,  False} : realDWlength = 4;
    endcase
    */
    if (prx.sof) rxHeadF.enq(TLPHeadInfo {hit:prx.hit, tlpLen:len, pfmt:tpf, length:realDWlength}); //TODO: trim tlplen and pfmt 

    // Now supply the rxDws with the goods...
    Vector#(4, Bit#(32)) vdw = unpack(prx.data);

    if (prx.sof)  // Only muck with the header (non-data) in the first word - Make header Bytes little-endian with each DWORD
      for (Integer i=0; i<(is4DWHead?4:3); i=i+1)
        vdw[i] = reverseBYTES(vdw[i]);

    UInt#(3) enqCount = 0;  // enqCount is how many DWORDs we push into rxDws on this cycle
    if      ( prx.sof && !hasPayload && !is4DWHead)              enqCount = 3; // 3DW of header
    else if ( prx.sof &&                 is4DWHead)              enqCount = 4; // 4DW of header + N DW of payload
    else if ( prx.sof &&  hasPayload && !is4DWHead && !rxBubble) enqCount = 4; // 3DW of header + 1 DW of payload
    else if ( prx.sof &&  hasPayload && !is4DWHead &&  rxBubble) enqCount = 3; // 3DW of header + 0 DW of payload
    else if (!prx.sof && !prx.empty  && prx.be==16'hFFFF)        enqCount = 4; //                 4 DW of payload
    else if (!prx.sof && !prx.empty  && prx.be==16'h0FFF)        enqCount = 3; //                 3 DW of payload
    else if (!prx.sof &&  prx.empty  && prx.be[15:8]==8'hFF)     enqCount = 2; //                 2 DW of payload (*1)
    else if (!prx.sof &&  prx.empty  && prx.be[15:8]==8'h0F)     enqCount = 1; //                 1 DW of payload (*1)
    else                                                         enqCount = 0; // default 0
    rxDws.enq(enqCount, vdw); 
    rxDbgEnEnq <= rxDbgEnEnq + extend(enqCount);

    // (*1) While the Altera documentation suggests that prx.be[7:0] should be observed when empty is asserted;
    // SignalTap investigation shows the pattern 0x0FFF for 1 DW of maessage payload and 0x0F0F for 1 DW of data payload

    if (prx.eof) rxEofF.enq(?); // signal that the message is over

    rxDbgEnstage <= rxDbgEnstage + 1;
    if (prx.sof) rxDbgEnSof <= rxDbgEnSof + 1;
    if (prx.eof) rxDbgEnEof <= rxDbgEnEof + 1;
  endrule


  // These rx_destage operations are about making PCIe generic specific to the TRN big-endian uNoC format.
  // It is not until there are 4 DWORDs available (or an packet eof) that we fire this rule on a predicate
  // And the implicit conditions include the rxHeadF being ready; meaning that we have a pending SOF
  // PCIe to TRN...
  rule rx_destage (rxDws.dwords_available >= 4 || rxEofF.notEmpty);
    let rxh = rxHeadF.first; // peek at the rxHeadF; will deq when the packet is done

    Bool sof = !rxInFlight;   
    Bool eof = rxEofF.notEmpty && (rxDws.dwords_available <= 4);

    Vector#(4, Bit#(32)) vdw = rxDws.dwords_out;                   // Pick up the 16B from the rxDws
    vdw = unpack(reverseDWORDS(pack(vdw)));                        // Make DWORDs Big-Endian
    for (Integer i=0; i<4; i=i+1) vdw[i] = reverseBYTES(vdw[i]);   // Make Bytes with each DWORD Big-Endian

    // The deqAmount is how many DWORDs we will deq from rxDws this cycle. It can never be more than 4.
    // and in the case of SOF, we get it directly from rxh.length instead of the state variable...
    UInt#(3) deqAmount =  truncate(min(4, sof ? rxh.length : rxDwrDeq));
    // The state variable keeps track of how many more DWORDs to go by subtracting away the deqAmount...
    rxDwrDeq <= sof ? (eof ? 0 : rxh.length-extend(deqAmount)) : rxDwrDeq-extend(deqAmount);
    rxDws.deq(deqAmount);
    rxDbgDeDeq <= rxDbgDeDeq + extend(deqAmount);

    Bit#(16) mask = '1;
    case (deqAmount)
      0 : mask = 16'h0000;
      1 : mask = 16'h000F;
      2 : mask = 16'h00FF;
      3 : mask = 16'h0FFF;
      4 : mask = 16'hFFFF;
    endcase

    rxOutF.enq(TLPData { 
      sof:  sof,
      eof:  eof,
      hit:  truncate(rxh.hit),
      be:   reverseBits(mask),  // Turn the little-endian mask to big-endian
      data: pack(vdw) });

    if (eof) begin
      rxHeadF.deq;  // done with this packet's header
      rxEofF.deq;   // done with this packet's eof indication
    end
    rxInFlight <= !eof; // packet is in flight until we encounter eof

    rxDbgDestage <= rxDbgDestage + 1;
    if (sof) rxDbgDeSof <= rxDbgDeSof + 1;
    if (eof) rxDbgDeEof <= rxDbgDeEof + 1;
  endrule


  //
  // Upstream TRN to Avalon-ST...
  //
  // These tx_enstage operations remove the TRN Specificity and make the packet PCIe generic
  // As TRN is uniformly big-endian; the work done here includes converting both DWORDs and Bytes to Little-Endian
  // TRN to PCIe...
  rule tx_enstage (txDws.space_available >= 4);
    let ptx = txInF.first; txInF.deq();  // take a packet-fragment from txInF

    Bool hasPayload = ptx.sof && unpack(ptx.data[126]);  // fmt[1] indicates "with data" (e.g. MemWrt)
    Bool is4DWHead  = ptx.sof && unpack(ptx.data[125]);  // fmt[0] indicates 4DW head vs. 3DW head

    TLPPacketFormat tpf = unpack(ptx.data[126:125]);
    TLPLength       len = unpack(ptx.data[105:96]);
    UInt#(11) realDWlength = (is4DWHead?4:3) + (hasPayload?decodeDWlength(len):0); // Header Length + Payload Length (if any)

    if (ptx.sof) txHeadF.enq(TLPHeadInfo {hit:0, tlpLen:len, pfmt:tpf, length:realDWlength}); //TODO: trim tlplen and pfmt 

    // Uniformly convert TRN DWORD and Byte Big-Endianness to Little-endian...
    Vector#(4, Bit#(32)) vdw = unpack(pack(ptx.data));             // Pick up the 16B from the txInF
    vdw = unpack(reverseDWORDS(pack(vdw)));                        // Make DWORDs Little-Endian
    for (Integer i=0; i<4; i=i+1) vdw[i] = reverseBYTES(vdw[i]);   // Make Bytes with each DWORD Little-Endian

    UInt#(3) enqCount = 0;  // enqCount is how many DWORDs we push into txDws on this cycle
    if      ( ptx.sof && !hasPayload && !is4DWHead)                            enqCount = 3; // 3DW of header
    else if ( ptx.sof &&                 is4DWHead)                            enqCount = 4; // 4DW of header + N DW of payload
    else if ( ptx.sof &&  hasPayload && !is4DWHead && ptx.be==16'hFFFF)        enqCount = 4; // 3DW of header + 1 DW of payload
    else if ( ptx.sof &&  hasPayload && !is4DWHead && ptx.be==16'hFFF0)        enqCount = 3; // 3DW of header + 0 DW of payload
    else if (!ptx.sof &&                              ptx.be==16'hFFFF)        enqCount = 4; //                 4 DW of payload
    else if (!ptx.sof &&                              ptx.be==16'hFFF0)        enqCount = 3; //                 3 DW of payload
    else if (!ptx.sof &&                              ptx.be==16'hFF00)        enqCount = 2; //                 2 DW of payload
    else if (!ptx.sof &&                              ptx.be==16'hF000)        enqCount = 1; //                 1 DW of payload
    else                                                                       enqCount = 0; // default 0
    txDws.enq(enqCount, vdw); 
    txDbgEnEnq <= txDbgEnEnq + extend(enqCount);

    if (ptx.eof) txEofF.enq(?); // signal that the message is over

    txDbgEnstage <= txDbgEnstage + 1;
    if (ptx.sof) txDbgEnSof <= txDbgEnSof + 1;
    if (ptx.eof) txDbgEnEof <= txDbgEnEof + 1;
  endrule


  // These tx_destage operations take the PCIe generic data and specialize them for the Avalon-ST format.
  // This includes + Byte-Reversal ONLY of the Header DWORDs
  //               + Adding a tx "bubble" cycle to force the 64b-allignment of data
  // PCIe to AV-ST...
  rule tx_destage (txDws.dwords_available >= 4 || txEofF.notEmpty);
    let txh = txHeadF.first; // peek at the txHeadF; will deq when the packet is done

    Bool sof = !txInFlight;   
    Bool is4DWHead  = sof && unpack(pack(txh.pfmt)[0]);  // fmt[0] indicates 4DW head vs. 3DW head

    Vector#(4, Bit#(32)) vdw = txDws.dwords_out;  
    if (sof)  // Only muck with the header (non-data) in the first word - Make header Bytes big-endian with each DWORD
      for (Integer i=0; i<(is4DWHead?4:3); i=i+1)
        vdw[i] = reverseBYTES(vdw[i]);

    Bit#(128) raw = pack(vdw); // We need the data to peek at bit 66 to see if we are 64b memory-alligned or not
    Bool txBubble = sof && !unpack(raw[66]) && unpack(raw[30]);
    // FIXME: The dwords available test in the next line does not work correctly when TX stream is fully occupied or more than one message
    // May be that the DWORD shifter needs to carry eof inband with data. Talk with jek on 20131021
    Bool eof = txEofF.notEmpty && (txDws.dwords_available <= 4) && !txBubble; // Cant end on a txBubble

    // The deqAmount is how many DWORDs we will deq from txDws this cycle. It can never be more than 4, 3 if a txBubble
    // and in the case of SOF, we get it directly from txh.length instead of the state variable...
    UInt#(3) deqAmount =  truncate(min(txBubble?3:4, sof?txh.length:txDwrDeq));
    // The state variable keeps track of how many more DWORDs to go by subtracting away the deqAmount...
    txDwrDeq <= sof ? (eof ? 0 : txh.length-extend(deqAmount)) : txDwrDeq-extend(deqAmount);
    txDws.deq(deqAmount);
    txDbgDeDeq <= txDbgDeDeq + extend(deqAmount);

    txOutF.enq(TLPDataA { 
      empty: (deqAmount<3),
      sof:   sof,
      eof:   eof,
      hit:   0,   // hit is not used for AV-ST TX
      be:    0,   // be-mask is not used for AV-ST TX
      data:  pack(vdw) });

    if (eof) begin
      txHeadF.deq;  // done with this packet's header
      txEofF.deq;   // done with this packet's eof indication
      txExF.enq(0); // signal to tx_exstage the message is ready
    end
    txInFlight <= !eof; // packet is in flight until we encounter eof

    txDbgDestage <= txDbgDestage + 1;
    if (sof) txDbgDeSof <= txDbgDeSof + 1;
    if (eof) txDbgDeEof <= txDbgDeEof + 1;
  endrule

  // Move the AV-ST format data from txOutF to the PCIe core...
  // AvalonST readLatency=2 ; one cycle from txReadyD, one cycle from tx_enstage rule firing
  rule tx_exstage (txReadyD && txExF.notEmpty);  // can not advance upstream until we have the whole message (AV-ST)
    let tex = txOutF.first; txOutF.deq;
    avaTxValid   <=  True;
    //avaTxD       <=  tex;
    pcie_ep.ava_tx.data (tex.data);
    avaTxSop     <=  tex.sof;
    avaTxEop     <=  tex.eof;
    avaTxEmpty   <=  tex.empty;
    txDbgExstage <= txDbgExstage + 1;
    if (tex.eof) txExF.deq; // message is done
  endrule

  (* no_implicit_conditions, fire_when_enabled *)
  rule connect_ava_tx;
    pcie_ep.ava_tx.valid(avaTxValid);
    //pcie_ep.ava_tx.data (avaTxD.data);
    pcie_ep.ava_tx.sop  (avaTxSop);
    pcie_ep.ava_tx.eop  (avaTxEop);
    pcie_ep.ava_tx.empty(avaTxEmpty);
    pcie_ep.ava_tx.err  (avaTxErr);
  endrule


  interface pcie = pcie_ep.pcie;

  interface PCIE_AVALONST ava;
    interface Clock    clk     = pcie_ep.ava.clk;
    interface Reset    usr_rst = pcie_ep.ava.usr_rst;
    method    Bool     alive   = pcie_ep.ava.alive;
    method    Bool     lnk_up  = pcie_ep.ava.lnk_up;
    method    Bit#(32) debug   = pcie_ep.ava.debug | extend(pack(rxInFlight)) | extend(pack(rxDbgInstage)) | extend(pack(rxDbgEnstage)) | extend(pack(rxDbgDestage)) 
     | extend(pack(rxDbgEnSof))| extend(pack(rxDbgEnEof)) | extend(pack(rxDbgDeSof)) | extend(pack(rxDbgDeEof)) | extend(pack(rxDbgEnEnq)) | extend(pack(rxDbgDeDeq)) 
                                                   | extend(pack(txInFlight)) | extend(pack(txDbgExstage)) | extend(pack(txDbgEnstage)) | extend(pack(txDbgDestage)) 
     | extend(pack(txDbgEnSof))| extend(pack(txDbgEnEof)) | extend(pack(txDbgDeSof)) | extend(pack(txDbgDeEof)) | extend(pack(txDbgEnEnq)) | extend(pack(txDbgDeDeq)) ;
  endinterface

  interface PCIE_TRN_RECV16 trn_rx;  // downstream...
     method ActionValue#(TLPData#(16)) recv() if (rxOutF.notEmpty);
        let rxo = rxOutF.first;
        rxOutF.deq;
        TLPData#(16) retval = defaultValue;
        retval.sof  = rxo.sof;
        retval.eof  = rxo.eof;
        retval.hit  = rxo.hit;
        retval.be   = rxo.be;
        retval.data = rxo.data;
        return retval;
     endmethod
  endinterface

  interface PCIE_TRN_XMIT16 trn_tx; // upstream
    method Action xmit(discontinue, data) if (txInF.notFull);
      txInF.enq(data);
    endmethod
  endinterface

  method PciId device = deviceReg;

endmodule: mkPCIExpressEndpointS4GX

endpackage: PCIE_S4
