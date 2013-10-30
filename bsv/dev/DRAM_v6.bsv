// DRAM_v6.bsv - BSV code to provide DRAM functionality
// Copyright (c) 2010-2013  Atomic Rules LCC ALL RIGHTS RESERVED

// 2013-10-29 sls Place MIG into reset when DramServer device worker is in Reset

package DRAM_v6;

import Clocks            ::*;
import Vector            ::*;
import GetPut            ::*;
import Gray ::*;
import GrayCounter ::*;
import ClientServer      ::*;
import Connectable       ::*;
import BRAM              ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;
import XilinxCells       :: *;

import SRLFIFO ::*;
import XilinxExtra :: *;


typedef struct {
  Bool      isRead; // request is read
  Bit#(na)  addr;   // memory address
 } DramReq#(numeric type na) deriving (Bits, Eq);

typedef struct {
  Bool      isLast; // request is last of burst
  Bit#(nbe) be;     // byte-lane write enables (active-high)
  Bit#(nd)  data;   // write data
 } DramWrite#(numeric type nd, numeric type nbe) deriving (Bits, Eq);

typedef struct {
  Bool      isLast; // request is last of burst
  Bit#(nd)  data;   // read data
 } DramRead#(numeric type nd) deriving (Bits, Eq);

typedef struct {
  Bool       isRead; // request is read
  Bit#(32)   addr;   // memory address
  Bit#(16)   be;     // byte-lane write enables (active-high)
  Bit#(128)  data;   // write data (16B)
 } DramReq16B deriving (Bits, Eq);




// Interfaces...

(* always_enabled, always_ready *)
interface DRAM_DDR#(numeric type rowWidth, numeric type bankWidth, numeric type ckWidth, numeric type csWidth,
                    numeric type odtWidth, numeric type dmWidth, numeric type dqWidth, numeric type dqsWidth);
  interface Inout#(Bit#(dqWidth))  io_dq;
  method  Bit#(rowWidth)           addr;
  method  Bit#(bankWidth)          ba;
  method  Bit#(1)                  ras_n;
  method  Bit#(1)                  cas_n;
  method  Bit#(1)                  we_n;
  method  Bit#(1)                  reset_n;
  method  Bit#(odtWidth)           cs_n;
  method  Bit#(odtWidth)           odt;
  method  Bit#(csWidth)            cke;
  method  Bit#(dmWidth)            dm;
  interface Inout#(Bit#(dqsWidth)) io_dqs_p;
  interface Inout#(Bit#(dqsWidth)) io_dqs_n;
  method  Bit#(ckWidth)            ck_p;
  method  Bit#(ckWidth)            ck_n;
//interface Inout#(Bit#(1))        sda;
//method  Bit#(1)                  scl;
//method  Bit#(1)                  parity;
endinterface: DRAM_DDR
typedef DRAM_DDR#(13,3,1,1,1,8,64,8) DDR3_64;
typedef DRAM_DDR#(13,2,2,2,2,4,32,4) DDR2_32;

(* always_enabled, always_ready *)
interface DRAM_APP#(numeric type appWidth, numeric type adrWidth, numeric type mskWidth);
  method Action              cmd      (Bit#(3) i);
//method Action              en       (Bit#(1) i);
  method Action              en       ();
  method Bit#(1)             cmd_rdy;
  method Action              addr     (Bit#(adrWidth) i);
//method Action              wdf_wren (Bit#(1) i);
  method Action              wdf_wren ();
  method Action              wdf_data (Bit#(appWidth) i);
  method Action              wdf_mask (Bit#(mskWidth) i);
  method Action              wdf_end  (Bit#(1) i);
  method Bit#(1)             wdf_rdy;
  method Bit#(appWidth)      rd_data;
  method Bit#(1)             rd_data_end;
  method Bit#(1)             rd_data_valid;
  method Bit#(1)             init_complete;
//method Action              hi_pri   (Bit#(1) i);
//method Action              sz       (Bit#(1) i);
endinterface: DRAM_APP
typedef DRAM_APP#(256,33,32) DRAM_APP_32B;

(* always_enabled, always_ready *)
interface DRAM_DEBUG#(numeric type dqsWidth, numeric type dqsCntWidth);
  method Bit#(dqsWidth)            wl_dqs_inverted;
  method Bit#(TMul#(2,dqsWidth))   wr_calib_clk_delay;
  method Bit#(TMul#(5,dqsWidth))   wl_odelay_dqs_tap_cnt;
  method Bit#(TMul#(5,dqsWidth))   wl_odelay_dq_tap_cnt;
  method Bit#(2)                   rdlvl_done;
  method Bit#(2)                   rdlvl_err;
  method Bit#(TMul#(5,dqsWidth))   cpt_tap_cnt;
  method Bit#(TMul#(5,dqsWidth))   cpt_first_edge_cnt;
  method Bit#(TMul#(5,dqsWidth))   cpt_second_edge_cnt;
  method Bit#(TMul#(3,dqsWidth))   rd_bitslip_cnt;
  method Bit#(TMul#(2,dqsWidth))   rd_clkdly_cnt;
  method Bit#(5)                   rd_active_dly;
  method Action                    pd_off             (Bit#(1) i);
  method Action                    pd_maintain_off    (Bit#(1) i);
  method Action                    pd_maintain_0_only (Bit#(1) i);
  method Action                    ocb_mon_off        (Bit#(1) i);
  method Action                    inc_cpt            (Bit#(1) i);
  method Action                    dec_cpt            (Bit#(1) i);
  method Action                    inc_rd_dqs         (Bit#(1) i);
  method Action                    dec_rd_dqs         (Bit#(1) i);
  method Action                    inc_dec_sel        (Bit#(dqsCntWidth) i);
  method Bit#(TMul#(5,dqsWidth))   dqs_p_tap_cnt;
  method Bit#(TMul#(5,dqsWidth))   dqs_n_tap_cnt;
  method Bit#(TMul#(5,dqsWidth))   dq_tap_cnt;
  method Bit#(TMul#(4,dqsWidth))   rddata;
endinterface: DRAM_DEBUG
typedef DRAM_DEBUG#(8,3) DRAM_DBG_32B;


(* always_enabled, always_ready *)
interface DRAM_INF#(numeric type bmWidth);
  method Bit#(1)             pll_lock_ck_fb;
  method Action              rst_pll_ck_fb;
  method Bit#(bmWidth)       bank_mach_next;
  method Bit#(1)             ocb_mon_PSEN;
  method Bit#(1)             ocb_mon_PSINCDEC;
  method Bit#(1)             dfi_init_complete;
  method Bit#(4)             app_ecc_multiple_err;
  interface Clock            clk;
  interface Clock            clk_mem;
  interface Clock            clk_wr_i;
  interface Clock            clk_wr_o;
  method Action              ocb_mon_PSDONE (Bit#(1) i);
  interface Reset            rst;
endinterface: DRAM_INF

interface DramControllerIfc;
  interface DDR3_64       dram;
  interface DRAM_APP_32B  app;
  interface DRAM_DBG_32B  dbg;
  interface Clock         uclk;      // user-facing clock
  interface Reset         urst_n;    // user-facing reset
endinterface: DramControllerIfc

interface DramControllerV5Ifc;
  interface DDR2_32       dram;
  interface DRAM_APP_32B  app;
  interface DRAM_DBG_32B  dbg;
  interface Clock         uclk;      // user-facing clock
  interface Reset         urst_n;    // user-facing reset
endinterface: DramControllerV5Ifc

interface DRAM_USR16B;                             // 16B Usr interface
  method    Bool                   initComplete;   // memory server ready
  method    Bool                   appFull;
  method    Bool                   wdfFull;
  method    Bool                   firBeat;
  method    Bool                   secBeat;
  interface Put#(DramReq16B)       request;        // 16B dram request
  interface Get#(Bit#(128))        response;       // 16B read data response
endinterface

interface DramControllerUiIfc;
  Action                         migReset;  // Input to MIG to force re-calibration
  interface DRAM_USR16B          usr;       // user interface
  interface DDR3_64              dram;      // dram pins
  interface DRAM_DBG_32B         dbg;       // debug port
  interface Clock                uclk;      // user-facing clock (output from MIG)
  interface Reset                urst_n;    // user-facing reset (output from MIG)
  method Bit#(16) reqCount;                 // diagnostc
  method Bit#(16) respCount;                // diagnostc
endinterface: DramControllerUiIfc

import "BVI" v6_mig37 = 
module vMkV6DDR3#(Clock sys0_clk, Clock mem_clk)(DramControllerIfc);

  default_clock clk();
  default_reset rst(sys_rst);  // active-high input to MIG used to force re-calibration, made by

  input_clock (clk_ref) = sys0_clk;  // 200 MHz Stable Source feeding IODELAY CONTROL LOGIC
  input_clock (clk_sys) = mem_clk;   // 200 MHz Clock feeding X0Y9 MMCM

  output_clock    uclk     (tb_clk);
  output_reset    urst_n   (tb_rst_n) clocked_by (uclk); 

  interface DDR3_64 dram;
    ifc_inout  io_dq(ddr3_dq)       clocked_by(mem_clk) reset_by(rst);
    method  ddr3_addr     addr      clocked_by(mem_clk) reset_by(rst);
    method  ddr3_ba       ba        clocked_by(mem_clk) reset_by(rst);
    method  ddr3_ras_n    ras_n     clocked_by(mem_clk) reset_by(rst);
    method  ddr3_cas_n    cas_n     clocked_by(mem_clk) reset_by(rst);
    method  ddr3_we_n     we_n      clocked_by(mem_clk) reset_by(rst);
    method  ddr3_reset_n  reset_n   clocked_by(mem_clk) reset_by(rst);
    method  ddr3_cs_n     cs_n      clocked_by(mem_clk) reset_by(rst);
    method  ddr3_odt      odt       clocked_by(mem_clk) reset_by(rst);
    method  ddr3_cke      cke       clocked_by(mem_clk) reset_by(rst);
    method  ddr3_dm       dm        clocked_by(mem_clk) reset_by(rst);
    ifc_inout  io_dqs_p(ddr3_dqs_p) clocked_by(mem_clk) reset_by(rst);
    ifc_inout  io_dqs_n(ddr3_dqs_n) clocked_by(mem_clk) reset_by(rst);
    method  ddr3_ck_p     ck_p      clocked_by(mem_clk) reset_by(rst);
    method  ddr3_ck_n     ck_n      clocked_by(mem_clk) reset_by(rst);
  endinterface: dram

  interface DRAM_APP_32B app;
    method                    cmd      (app_cmd)        enable((*inhigh*)ena1) clocked_by(uclk) reset_by(urst_n);
    method                    en       ()               enable(app_en)         clocked_by(uclk) reset_by(urst_n);
    method app_rdy            cmd_rdy                                          clocked_by(uclk) reset_by(urst_n);
    method                    addr     (app_addr)       enable((*inhigh*)ena3) clocked_by(uclk) reset_by(urst_n); // tg_addr became app_addr in v37
    method                    wdf_wren ()               enable(app_wdf_wren)   clocked_by(uclk) reset_by(urst_n);
    method                    wdf_data (app_wdf_data)   enable((*inhigh*)ena5) clocked_by(uclk) reset_by(urst_n);
    method                    wdf_mask (app_wdf_mask)   enable((*inhigh*)ena6) clocked_by(uclk) reset_by(urst_n);
    method                    wdf_end  (app_wdf_end)    enable((*inhigh*)ena7) clocked_by(uclk) reset_by(urst_n);
    method app_wdf_rdy        wdf_rdy                                          clocked_by(uclk) reset_by(urst_n);
    method app_rd_data        rd_data                                          clocked_by(uclk) reset_by(urst_n);
    method app_rd_data_end    rd_data_end                                      clocked_by(uclk) reset_by(urst_n);
    method app_rd_data_valid  rd_data_valid                                    clocked_by(uclk) reset_by(urst_n);
    method phy_init_done      init_complete                                    clocked_by(uclk) reset_by(urst_n);
  endinterface: app

  interface DRAM_DBG_32B dbg;
    method dbg_wl_dqs_inverted       wl_dqs_inverted                           clocked_by(uclk) reset_by(urst_n);
    method dbg_wr_calib_clk_delay    wr_calib_clk_delay                        clocked_by(uclk) reset_by(urst_n);
    method dbg_wl_odelay_dqs_tap_cnt wl_odelay_dqs_tap_cnt                     clocked_by(uclk) reset_by(urst_n);
    method dbg_wl_odelay_dq_tap_cnt  wl_odelay_dq_tap_cnt                      clocked_by(uclk) reset_by(urst_n);
    method dbg_rdlvl_done            rdlvl_done                                clocked_by(uclk) reset_by(urst_n);
    method dbg_rdlvl_err             rdlvl_err                                 clocked_by(uclk) reset_by(urst_n);
    method dbg_cpt_tap_cnt           cpt_tap_cnt                               clocked_by(uclk) reset_by(urst_n);
    method dbg_cpt_first_edge_cnt    cpt_first_edge_cnt                        clocked_by(uclk) reset_by(urst_n);
    method dbg_cpt_second_edge_cnt   cpt_second_edge_cnt                       clocked_by(uclk) reset_by(urst_n);
    method dbg_rd_bitslip_cnt        rd_bitslip_cnt                            clocked_by(uclk) reset_by(urst_n);
    method dbg_rd_clkdly_cnt         rd_clkdly_cnt                             clocked_by(uclk) reset_by(urst_n);
    method dbg_rd_active_dly         rd_active_dly                             clocked_by(uclk) reset_by(urst_n);
    method dbg_dqs_p_tap_cnt         dqs_p_tap_cnt                             clocked_by(uclk) reset_by(urst_n);
    method dbg_dqs_n_tap_cnt         dqs_n_tap_cnt                             clocked_by(uclk) reset_by(urst_n);
    method dbg_dq_tap_cnt            dq_tap_cnt                                clocked_by(uclk) reset_by(urst_n);
    method dbg_rddata                rddata                                    clocked_by(uclk) reset_by(urst_n);
    method pd_off             (dbg_pd_off)              enable((*inhigh*)enb1) clocked_by(uclk) reset_by(urst_n);
    method pd_maintain_off    (dbg_pd_maintain_off)     enable((*inhigh*)enb2) clocked_by(uclk) reset_by(urst_n);
    method pd_maintain_0_only (dbg_pd_maintain_0_only)  enable((*inhigh*)enb3) clocked_by(uclk) reset_by(urst_n);
    method ocb_mon_off        (dbg_ocb_mon_off)         enable((*inhigh*)enb4) clocked_by(uclk) reset_by(urst_n);
    method inc_cpt            (dbg_inc_cpt)             enable((*inhigh*)enb5) clocked_by(uclk) reset_by(urst_n);
    method dec_cpt            (dbg_dec_cpt)             enable((*inhigh*)enb6) clocked_by(uclk) reset_by(urst_n);
    method inc_rd_dqs         (dbg_inc_rd_dqs)          enable((*inhigh*)enb7) clocked_by(uclk) reset_by(urst_n);
    method dec_rd_dqs         (dbg_dec_rd_dqs)          enable((*inhigh*)enb8) clocked_by(uclk) reset_by(urst_n);
    method inc_dec_sel        (dbg_inc_dec_sel)         enable((*inhigh*)enb9) clocked_by(uclk) reset_by(urst_n);
  endinterface: dbg

    schedule (dbg_wl_dqs_inverted, dbg_wr_calib_clk_delay, dbg_wl_odelay_dqs_tap_cnt, dbg_wl_odelay_dq_tap_cnt, dbg_rdlvl_done, dbg_rdlvl_err, dbg_cpt_tap_cnt, dbg_cpt_first_edge_cnt, dbg_cpt_second_edge_cnt, dbg_rd_bitslip_cnt, dbg_rd_clkdly_cnt, dbg_rd_active_dly, dbg_dqs_p_tap_cnt, dbg_dqs_n_tap_cnt, dbg_dq_tap_cnt, dbg_rddata) CF
             (dbg_wl_dqs_inverted, dbg_wr_calib_clk_delay, dbg_wl_odelay_dqs_tap_cnt, dbg_wl_odelay_dq_tap_cnt, dbg_rdlvl_done, dbg_rdlvl_err, dbg_cpt_tap_cnt, dbg_cpt_first_edge_cnt, dbg_cpt_second_edge_cnt, dbg_rd_bitslip_cnt, dbg_rd_clkdly_cnt, dbg_rd_active_dly, dbg_dqs_p_tap_cnt, dbg_dqs_n_tap_cnt, dbg_dq_tap_cnt, dbg_rddata);

  schedule (dbg_pd_off, dbg_pd_maintain_off, dbg_pd_maintain_0_only, dbg_ocb_mon_off, dbg_inc_cpt, dbg_dec_cpt , dbg_inc_rd_dqs, dbg_dec_rd_dqs, dbg_inc_dec_sel,
             app_cmd, app_en, app_addr, app_wdf_wren, app_wdf_data, app_wdf_mask, app_wdf_end ) CF
           (dbg_pd_off, dbg_pd_maintain_off, dbg_pd_maintain_0_only, dbg_ocb_mon_off, dbg_inc_cpt, dbg_dec_cpt , dbg_inc_rd_dqs, dbg_dec_rd_dqs, dbg_inc_dec_sel,
             app_cmd, app_en, app_addr, app_wdf_wren, app_wdf_data, app_wdf_mask, app_wdf_end );

endmodule: vMkV6DDR3

module mkDramController#(Clock sys0_clk, Clock mem_clk) (DramControllerIfc);
  Clock                 clk           <-  exposeCurrentClock;
  Reset                 rst_n         <-  exposeCurrentReset;
  Reset                 rst_p         <-  mkResetInverter(rst_n);                  
  Reset                 mem_rst_p     <-  mkAsyncReset(2, rst_p, sys0_clk); // active-high for importBVI use
  let _m <- vMkV6DDR3(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by mem_rst_p);
  return(_m);
endmodule: mkDramController

module mkDramControllerUi#(Clock sys0_clk, Clock mem_clk) (DramControllerUiIfc);
  Reset                 rst_n         <- exposeCurrentReset;  // module reset from sys0_rst
  MakeResetIfc          migRst        <- mkReset(16, True, sys0_clk);
  Reset                 rst_x         <- mkResetEither(rst_n, migRst.new_rst); // Either of these two active-low will reset MIG
  Reset                 rst_p         <- mkResetInverter(rst_x); // Turn rst_x from active-low to active-high rst_p
  Reset                 mem_rst_p     <- mkAsyncReset(16, rst_p, sys0_clk); // active-high for importBVI use
  DramControllerIfc     memc          <- vMkV6DDR3(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by mem_rst_p);
  FIFO#(DramReq16B)     reqF          <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
//FIFO#(Bit#(128))      respF         <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
  FIFOF#(Bit#(128))     respF         <- mkSRLFIFOD(4,  clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bit#(16))        requestCount  <- mkReg(0,       clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bit#(16))        responseCount <- mkReg(0,       clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bool)            firstBeat     <- mkReg(False,   clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bool)            secondBeat    <- mkReg(False,   clocked_by memc.uclk, reset_by memc.urst_n);
  FIFOF#(Bit#(2))       rdpF          <- mkSRLFIFOD(4,  clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bool)           wdfWren       <- mkDWire(False, clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bool)           wdfEnd        <- mkDWire(False, clocked_by memc.uclk, reset_by memc.urst_n);

  // Fires request for read and write...
  (* fire_when_enabled *)
  rule advance_request (unpack(memc.app.init_complete) && !firstBeat && !secondBeat);
    let r = reqF.first;
    memc.app.addr(extend(r.addr>>2));        // convert byte address to 64B/16B address //TODO: Check shift 
    memc.app.cmd (r.isRead?3'b001:3'b000);   // Set the command
    memc.app.en();                           // Assert the command enable
    if (unpack(memc.app.cmd_rdy)) begin      // When the command is (finally) accepted...
      if (r.isRead) begin                    // Read...
        rdpF.enq(r.addr[5:4]);               // push 2b of 16B/64B read-phase to rdpF
        reqF.deq();                          // Deq for read (we are done with read request)
      end else begin                         // Write...
        firstBeat <= True;                   // Advance to W0
      end
      requestCount <= requestCount + 1;      // Bump the requestCounter
    end
  endrule

  // Fires with the firstBeat of write, with the W0 data...
  rule advance_write0 (unpack(memc.app.init_complete) && firstBeat && !secondBeat);
    let r = reqF.first;
    memc.app.wdf_data ({r.data,r.data});     // Replicate the 16B write data to 32B 
    Bit#(32) myBE = '0;                      // Calculate the BE (default no enable)
    case (r.addr[5:4])
      2'b00: myBE = {16'h0000,r.be};         // 16B-0 into W0 LS
      2'b01: myBE = {r.be,16'h0000};         // 16B-1 into W0 MS
    endcase
    memc.app.wdf_mask (~myBE);               // Invert myBE to be a "mask"
    wdfWren <= True;                         // Assert the write data enable (W0)
    if (unpack(memc.app.wdf_rdy)) begin      // When the write-data W0 is (finally) accepted...
      firstBeat  <= False;                   // Clear firstBeat
      secondBeat <= True;                    // Writes need a second beat
    end
  endrule

  // Fires with the secondBeat of write, with the W1 data...
  rule advance_write1 (unpack(memc.app.init_complete) && !firstBeat && secondBeat);
    let r = reqF.first;
    memc.app.wdf_data ({r.data,r.data});     // Replicate the 16B write data to 32B
    Bit#(32) myBE = '0;                      // Calculate the BE (default no enable)
    case (r.addr[5:4])
      2'b10: myBE = {16'h0000,r.be};         // 16B-2 into W1 LS
      2'b11: myBE = {r.be,16'h0000};         // 16B-3 into W1 MS
    endcase
    memc.app.wdf_mask (~myBE);               // Invert myBE to be a "mask"
    wdfWren <= True;                         // Assert the write data enable (W1)
    wdfEnd  <= True;                         // Assert wdf end
    if (unpack(memc.app.wdf_rdy)) begin     // When the write-data W1 is (finally) accepted...
      secondBeat <= False;                   // Clear the secondBeat state
      reqF.deq();                            // Deq, we are done with write request
    end
  endrule
  
  rule drive_wdf_wren (wdfWren); memc.app.wdf_wren();    endrule
  rule drive_wdf_end;  memc.app.wdf_end (pack(wdfEnd));  endrule

  // Fires on the two beats of each word read response; rdpF selects where to select 16B from 64B
  // TODO: Understand 16B-1/3 reversal
  // We guard the maximum number of Read Responses in flight so as not to overflow the respF by using a 16-deep SRL 
  // and then using the state of wmemReadInFlight to provide request backpressure in the DramServer
  // The DRAM controller read channel does not respect backpressure!
  rule advance_readData (unpack(memc.app.init_complete) && unpack(memc.app.rd_data_valid));
    let p = rdpF.first;
    case({unpack(memc.app.rd_data_end),p})
      3'b000: respF.enq(memc.app.rd_data[127:0]  );  //16B-0 from W0 LS
      3'b101: respF.enq(memc.app.rd_data[255:128]);  //16B-1 from W1 MS **
      3'b110: respF.enq(memc.app.rd_data[127:0]  );  //16B-2 from W1 LS
      3'b011: respF.enq(memc.app.rd_data[255:128]);  //16B-3 from W0 MS **
    endcase
    responseCount <= responseCount + 1;
    if (unpack(memc.app.rd_data_end)) rdpF.deq; // we are done with this read response, deq the rdpF
  endrule

  Action migReset = migRst.assertReset;  // Input to MIG to force re-calibration
  interface DRAM_USR16B usr;
    method    Bool initComplete = unpack(memc.app.init_complete);
    method    Bool appFull      = !unpack(memc.app.cmd_rdy);
    method    Bool wdfFull      = !unpack(memc.app.wdf_rdy);
    method    Bool firBeat      = firstBeat;
    method    Bool secBeat      = secondBeat;
    interface Put  request      = toPut(reqF);
    interface Get  response     = toGet(respF);
  endinterface
  interface DDR3_64        dram    = memc.dram;    // pass-through other interfaces...
  interface DRAM_DBG_32B   dbg     = memc.dbg;
  interface Clock          uclk    = memc.uclk;
  interface Reset          urst_n  = memc.urst_n;
  method Bit#(16) reqCount  = requestCount;
  method Bit#(16) respCount = responseCount;
endmodule: mkDramControllerUi

endpackage: DRAM_v6
