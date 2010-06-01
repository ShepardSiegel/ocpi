// DRAMV5.bsv - BSV code to provide DRAM functionality
// Copyright (c) 2010  Atomic Rules LCC ALL RIGHTS RESERVED

package DRAMV5;

import Clocks            ::*;
import Vector            ::*;
import GetPut            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import BRAM              ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;
import XilinxCells       :: *;

import MyGray ::*;
import MyGrayCounter ::*;
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
  //interface Clock clk; 
  //interface Reset rst;
  interface Inout#(Bit#(dqWidth))  io_dq;
  method  Bit#(rowWidth)           addr;
  method  Bit#(bankWidth)          ba;
  method  Bit#(1)                  ras_n;
  method  Bit#(1)                  cas_n;
  method  Bit#(1)                  we_n;
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
  method Bit#(1)             full;
  method Action              addr     (Bit#(adrWidth) i);
//method Action              wdf_wren (Bit#(1) i);
  method Action              wdf_wren ();
  method Action              wdf_data (Bit#(appWidth) i);
  method Action              wdf_mask (Bit#(mskWidth) i);
  method Bit#(1)             wdf_full;
  method Bit#(appWidth)      rd_data;
  method Bit#(1)             rd_data_valid;
  method Bit#(1)             init_complete;
//method Action              hi_pri   (Bit#(1) i);
//method Action              sz       (Bit#(1) i);
endinterface: DRAM_APP
typedef DRAM_APP#(256,33,32) DRAM_APP_32B;
typedef DRAM_APP#(64,33,8) DRAM_APP_8B;

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


// 22 DDR2 V5 Specific MIG Debug Methods...
(* always_enabled, always_ready *)
interface DRAM_DEBUG_DDR2_V5#(numeric type dqsWidth, numeric type dqsPerDqs);
  method Bit#(4)                   calib_done;
  method Bit#(4)                   calib_err;
  method Bit#(TMul#(6,dqsWidth))   calib_dq_tap_cnt;
  method Bit#(TMul#(6,dqsWidth))   calib_dqs_tap_cnt;
  method Bit#(TMul#(6,dqsWidth))   calib_gate_tap_cnt;
  method Bit#(dqsWidth)            calib_rd_data_sel;
  method Bit#(TMul#(5,dqsWidth))   calib_rden_delay;
  method Bit#(TMul#(5,dqsWidth))   calib_gate_delay;
  method Action                    idel_up_all             (Bit#(1) i);
  method Action                    idel_down_all           (Bit#(1) i);
  method Action                    sel_all_idel_dq         (Bit#(1) i);
  method Action                    sel_idel_dq             (Bit#(TLog#(TMul#(dqsWidth,dqsPerDqs))) i);
  method Action                    idel_up_dq              (Bit#(1) i);
  method Action                    idel_down_dq            (Bit#(1) i);
  method Action                    sel_all_idel_dqs        (Bit#(1) i);
  method Action                    sel_idel_dqs            (Bit#(TLog#(dqsWidth)) i);
  method Action                    idel_up_dqs             (Bit#(1) i);
  method Action                    idel_down_dqs           (Bit#(1) i);
  method Action                    sel_all_idel_gate       (Bit#(1) i);
  method Action                    sel_idel_gate           (Bit#(TLog#(dqsWidth)) i);
  method Action                    idel_up_gate            (Bit#(1) i);
  method Action                    idel_down_gate          (Bit#(1) i);
endinterface: DRAM_DEBUG_DDR2_V5
typedef DRAM_DEBUG_DDR2_V5#(4,8) DRAM_DBG_V5S;


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

interface DramControllerV5Ifc;
  interface DDR2_32       dram;
  interface DRAM_APP_8B   app;
  interface DRAM_DBG_V5S  dbg;       // V5-SX
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

interface DramControllerUiV5Ifc;
  interface DRAM_USR16B          usr;       // user interface
  interface DDR2_32              dram;      // dram pins
  interface DRAM_DBG_V5S         dbg;       // debug port
  interface Clock                uclk;      // user-facing clock
  interface Reset                urst_n;    // user-facing reset
  method Bit#(16) reqCount;
endinterface: DramControllerUiV5Ifc

import "BVI" v5_mig34 = 
module vMkV5DDR2#(Clock sys0_clk, Clock mem_clk)(DramControllerV5Ifc);

  default_clock clk();
  default_reset rst(sys_rst_n); 

  input_clock (clk_ref) = sys0_clk;  // 200 MHz Stable Source feeding IODELAY CONTROL LOGIC
  input_clock (clk_sys) = mem_clk;   // 300~200 MHz Clock feeding X0Y9 MMCM

  output_clock    uclk     (tb_clk);
  output_reset    urst_n   (tb_rst_n) clocked_by (uclk); 

  interface DDR2_32 dram;
    //output_clock clk(clk_sys);
    //output_reset rst(sys_rst);
    ifc_inout  io_dq(ddr2_dq)       clocked_by(mem_clk) reset_by(rst);
    method  ddr2_addr     addr      clocked_by(mem_clk) reset_by(rst);
    method  ddr2_ba       ba        clocked_by(mem_clk) reset_by(rst);
    method  ddr2_ras_n    ras_n     clocked_by(mem_clk) reset_by(rst);
    method  ddr2_cas_n    cas_n     clocked_by(mem_clk) reset_by(rst);
    method  ddr2_we_n     we_n      clocked_by(mem_clk) reset_by(rst);
    method  ddr2_cs_n     cs_n      clocked_by(mem_clk) reset_by(rst);
    method  ddr2_odt      odt       clocked_by(mem_clk) reset_by(rst);
    method  ddr2_cke      cke       clocked_by(mem_clk) reset_by(rst);
    method  ddr2_dm       dm        clocked_by(mem_clk) reset_by(rst);
    ifc_inout  io_dqs_p(ddr2_dqs_p) clocked_by(mem_clk) reset_by(rst);
    ifc_inout  io_dqs_n(ddr2_dqs_n) clocked_by(mem_clk) reset_by(rst);
    method  ddr2_ck_p     ck_p      clocked_by(mem_clk) reset_by(rst);
    method  ddr2_ck_n     ck_n      clocked_by(mem_clk) reset_by(rst);
  endinterface: dram

  interface DRAM_APP_32B app;
    method                    cmd      (app_cmd)       enable((*inhigh*)ena1)  clocked_by(uclk) reset_by(urst_n);
    method                    en       ()              enable(app_af_wren)     clocked_by(uclk) reset_by(urst_n);
    method app_af_afull       full                                             clocked_by(uclk) reset_by(urst_n);
    method                    addr     (app_addr)      enable((*inhigh*)ena3)  clocked_by(uclk) reset_by(urst_n);
    method                    wdf_wren ()              enable(app_wf_wren)     clocked_by(uclk) reset_by(urst_n);
    method                    wdf_data (app_data)      enable((*inhigh*)ena5)  clocked_by(uclk) reset_by(urst_n);
    method                    wdf_mask (app_mask)      enable((*inhigh*)ena6)  clocked_by(uclk) reset_by(urst_n);
    method app_wf_afull       wdf_full                                         clocked_by(uclk) reset_by(urst_n);
    method app_rd_data        rd_data                                          clocked_by(uclk) reset_by(urst_n);
    method app_rd_data_valid  rd_data_valid                                    clocked_by(uclk) reset_by(urst_n);
    method phy_init_done      init_complete                                    clocked_by(uclk) reset_by(urst_n);
  endinterface: app

  interface DRAM_DBG_V5S dbg;
    // value methods verilogPort methodName...
    method dbg_calib_done             calib_done                  clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_err              calib_err                   clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_dq_tap_cnt       calib_dq_tap_cnt            clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_dqs_tap_cnt      calib_dqs_tap_cnt           clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_gate_tap_cnt     calib_gate_tap_cnt          clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_rd_data_sel      calib_rd_data_sel           clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_rden_delay       calib_rden_delay            clocked_by(uclk) reset_by(urst_n);
    method dbg_calib_gate_delay       calib_gate_delay            clocked_by(uclk) reset_by(urst_n);
    // Action methods methodName (VerilogPort)...
    method idel_up_all        (dbg_idel_up_all)          enable((*inhigh*)enb1) clocked_by(uclk) reset_by(urst_n);
    method idel_down_all      (dbg_idel_down_all)        enable((*inhigh*)enb2) clocked_by(uclk) reset_by(urst_n);
    method sel_all_idel_dq    (dbg_sel_all_idel_dq)      enable((*inhigh*)enb3) clocked_by(uclk) reset_by(urst_n);
    method sel_idel_dq        (dbg_sel_idel_dq)          enable((*inhigh*)enb4) clocked_by(uclk) reset_by(urst_n);
    method idel_up_dq         (dbg_idel_up_dq)           enable((*inhigh*)enb5) clocked_by(uclk) reset_by(urst_n);
    method idel_down_dq       (dbg_idel_down_dq)         enable((*inhigh*)enb6) clocked_by(uclk) reset_by(urst_n);
    method sel_all_idel_dqs   (dbg_sel_all_idel_dqs)     enable((*inhigh*)enb7) clocked_by(uclk) reset_by(urst_n);
    method sel_idel_dqs       (dbg_sel_idel_dqs)         enable((*inhigh*)enb8) clocked_by(uclk) reset_by(urst_n);
    method idel_up_dqs        (dbg_idel_up_dqs)          enable((*inhigh*)enb9) clocked_by(uclk) reset_by(urst_n);
    method idel_down_dqs      (dbg_idel_down_dqs)        enable((*inhigh*)enba) clocked_by(uclk) reset_by(urst_n);
    method sel_all_idel_gate  (dbg_sel_all_idel_gate)    enable((*inhigh*)enbb) clocked_by(uclk) reset_by(urst_n);
    method sel_idel_gate      (dbg_sel_idel_gate)        enable((*inhigh*)enbc) clocked_by(uclk) reset_by(urst_n);
    method idel_up_gate       (dbg_idel_up_gate )        enable((*inhigh*)enbd) clocked_by(uclk) reset_by(urst_n);
    method idel_down_gate     (dbg_idel_down_gate)       enable((*inhigh*)enbe) clocked_by(uclk) reset_by(urst_n);
  endinterface: dbg

  //TODO: Make conflict free all..
   schedule (
   dram_addr, dram_ba, dram_ras_n, dram_cas_n, dram_we_n, dram_cs_n, dram_odt, dram_cke, dram_dm, dram_ck_p, dram_ck_n,
   app_cmd, app_en, app_addr, app_wdf_wren, app_wdf_data, app_wdf_mask, app_full, app_wdf_full, app_rd_data, app_rd_data_valid, app_init_complete, 
   dbg_calib_done, dbg_calib_err, dbg_calib_dq_tap_cnt, dbg_calib_dqs_tap_cnt, dbg_calib_gate_tap_cnt, dbg_calib_rd_data_sel, dbg_calib_rden_delay, dbg_calib_gate_delay, dbg_idel_up_all, dbg_idel_down_all, dbg_sel_all_idel_dq, dbg_sel_idel_dq, dbg_idel_up_dq, dbg_idel_down_dq, dbg_sel_all_idel_dqs, dbg_sel_idel_dqs, dbg_idel_up_dqs, dbg_idel_down_dqs, dbg_sel_all_idel_gate, dbg_sel_idel_gate, dbg_idel_up_gate, dbg_idel_down_gate)
    CF
    ( dram_addr, dram_ba, dram_ras_n, dram_cas_n, dram_we_n, dram_cs_n, dram_odt, dram_cke, dram_dm, dram_ck_p, dram_ck_n,
    app_cmd, app_en, app_addr, app_wdf_wren, app_wdf_data, app_wdf_mask, app_full, app_wdf_full, app_rd_data, app_rd_data_valid, app_init_complete, 
      dbg_calib_done, dbg_calib_err, dbg_calib_dq_tap_cnt, dbg_calib_dqs_tap_cnt, dbg_calib_gate_tap_cnt, dbg_calib_rd_data_sel, dbg_calib_rden_delay, dbg_calib_gate_delay, dbg_idel_up_all, dbg_idel_down_all, dbg_sel_all_idel_dq, dbg_sel_idel_dq, dbg_idel_up_dq, dbg_idel_down_dq, dbg_sel_all_idel_dqs, dbg_sel_idel_dqs, dbg_idel_up_dqs, dbg_idel_down_dqs, dbg_sel_all_idel_gate, dbg_sel_idel_gate, dbg_idel_up_gate, dbg_idel_down_gate );

endmodule: vMkV5DDR2

module mkDramControllerV5#(Clock sys0_clk, Clock mem_clk) (DramControllerV5Ifc);
  Clock                 clk           <-  exposeCurrentClock;
  Reset                 rst_n         <-  exposeCurrentReset;
  let _m <- vMkV5DDR2(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by rst_n);
  return(_m);
endmodule: mkDramControllerV5

module mkDramControllerV5Ui#(Clock sys0_clk, Reset sys0_rst, Clock mem_clk) (DramControllerUiV5Ifc);
  //Reset                 rst_n         <- exposeCurrentReset;
  //Reset                 rst_p         <- mkResetInverter(rst_n);                  
  //Reset                 mem_rst_n     <- mkAsyncReset(16, rst_n, sys0_clk); // active-low for importBVI use
  DramControllerV5Ifc   memc            <- vMkV5DDR2(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by sys0_rst);
  FIFO#(DramReq16B)     reqF            <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
  FIFO#(Bit#(128))      respF           <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bit#(16))        requestCount    <- mkReg(0,       clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bool)            firstWriteBeat  <- mkReg(False,   clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bool)           wdfWren         <- mkDWire(False, clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bool)            firstReadBeat   <- mkReg(False,   clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bit#(64))        firstReadData   <- mkReg(0,       clocked_by memc.uclk, reset_by memc.urst_n);

  // Fires request for read and write...
  (* fire_when_enabled *)
  rule advance_request (unpack(memc.app.init_complete) && !unpack(memc.app.full) && !firstWriteBeat);
    let r = reqF.first;
    memc.app.addr(extend(r.addr>>2));        // convert byte address to 64B/16B address //TODO: Check shift 
    memc.app.cmd (r.isRead?3'b001:3'b000);   // Set the command
    memc.app.en();                           // Assert the command enable
    requestCount <= requestCount + 1;        // Bump the requestCounter
    if (r.isRead) begin                      // Read...
      reqF.deq();                            // Deq for read (we are done with read request)
    end else begin                           // Write...
      memc.app.wdf_data (r.data[63:0]);      // First 8B of data
      memc.app.wdf_mask (~r.be[7:0]);        // Invert myBE to be a "mask"
      wdfWren <= True;                       // Assert the write data enable (W0)
      firstWriteBeat <= True;                // Advance to W0
    end
  endrule

  // Fires with the secondBeat of write, with the W1 data...
  (* fire_when_enabled *)
  rule advance_write1 (unpack(memc.app.init_complete) && !unpack(memc.app.wdf_full) && firstWriteBeat);
    let r = reqF.first;
    memc.app.wdf_data (r.data[127:64]);      // Second 8B of data
    memc.app.wdf_mask (~r.be[15:8]);         // Invert myBE to be a "mask"
    wdfWren <= True;                         // Assert the write data enable (W1)
    firstWriteBeat <= False;                 // Clear the firstWriteBeat state
    reqF.deq();                              // Deq, we are done with write request
  endrule
  
  rule drive_wdf_wren (wdfWren); memc.app.wdf_wren();    endrule

  // V5 - Take 8B (64b) from Memory and form 16B (128b) response
  (* fire_when_enabled *)
  rule advance_readData (unpack(memc.app.init_complete) && unpack(memc.app.rd_data_valid));
    if (!firstReadBeat) begin
      firstReadBeat <= True;
      firstReadData <= memc.app.rd_data;
    end else begin
      firstReadBeat <= False;
      respF.enq({memc.app.rd_data, firstReadData});
    end
  endrule

  interface DRAM_USR16B usr;
    method    Bool initComplete = unpack(memc.app.init_complete);
    method    Bool appFull      = unpack(memc.app.full);
    method    Bool wdfFull      = unpack(memc.app.wdf_full);
    method    Bool firBeat      = firstWriteBeat;
    method    Bool secBeat      = firstReadBeat;
    interface Put  request      = toPut(reqF);
    interface Get  response     = toGet(respF);
  endinterface
  interface DDR2_32        dram    = memc.dram;    // pass-through other interfaces...
  interface DRAM_DBG_V5S   dbg     = memc.dbg;
  interface Clock          uclk    = memc.uclk;
  interface Reset          urst_n  = memc.urst_n;
  method Bit#(16) reqCount = requestCount;
endmodule: mkDramControllerV5Ui

endpackage: DRAMV5
