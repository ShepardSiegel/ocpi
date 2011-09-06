// DRAM_s4.bsv - BSV code to provide DRAM functionality for Altera Stratix 4 using UNIPHY
// Copyright (c) 2011  Atomic Rules LCC ALL RIGHTS RESERVED

package DRAM_s4;

import Clocks            ::*;
import Vector            ::*;
import GetPut            ::*;
import Gray              ::*;
import GrayCounter       ::*;
import ClientServer      ::*;
import Connectable       ::*;
import BRAM              ::*;
import FIFO              ::*;
import FIFOF             ::*;
import SpecialFIFOs      ::*;

//import XilinxCells     ::*;
//import SRLFIFO         ::*;
//import XilinxExtra     ::*;


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
endinterface: DRAM_DDR
typedef DRAM_DDR#(13,3,1,1,1,2,16,2) DDR3_16;  // As in the Altera alst4 platform single-chip 16b "DDR3TOP" device

(* always_enabled, always_ready *)
interface DRAM_AVL#(numeric type datWidth, numeric type adrWidth, numeric type beWidth, numeric type brstWidth);
  method Bool                rdy;
  method Action              burstbegin   (Bool i);
  method Action              addr         (Bit#(adrWidth) i);
  method Bool                rdata_valid;
  method Bit#(datWidth)      rdata;
  method Action              wdata        (Bit#(datWidth) i);
  method Action              be           (Bit#(beWidth)  i);
  method Bool                read_req;
  method Bool                write_req;
  method Action              size         (Bit#(brstWidth)  i);
endinterface: DRAM_AVL
typedef DRAM_AVL#(64,24,8,3) DRAM_AVL_8B;

(* always_enabled, always_ready *)
interface DRAM_STATUS;
  method Bool init_done;
  method Bool cal_success;
  method Bool cal_fail;
endinterface: DRAM_STATUS

interface DramControllerIfc;
  interface DDR3_16       dram;      // the dram-facing ios
  interface DRAM_AVL_8B   avl;       // the explicit Avalon MM interface
  interface DRAM_STATUS   status;    // the status interface
  interface Clock         afi_full;  // AFI clock
  interface Clock         afi_half;  // AFI half-clock (this is the clock for the avl interface)
  interface Reset         afi_rstn;  // AFI reset
endinterface: DramControllerIfc

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
  interface DDR3_16              dram;      // dram pins
  interface DRAM_USR16B          usr;       // user interface
  //interface DRAM_DBG_32B         dbg;       // debug port
  interface Clock                uclk;      // user-facing clock
  interface Reset                urst_n;    // user-facing reset
  method Bit#(16) reqCount;
endinterface: DramControllerUiIfc

import "BVI" ddr3_s4_uniphy = 
module vMkS4DDR3#(Clock pllref_clk)(DramControllerIfc);

  default_clock clk(pll_ref_clk);     // 125 MHz Clock In
  default_reset rst(global_reset_n); 

  output_clock    afi_full  (afi_clk);       // 300 MHz
  output_clock    afi_half  (afi_half_clk);  // 150 MHz
  output_reset    afi_rstn  (afi_reset_n) clocked_by (afi_half); 

  interface DDR3_16 dram;
    ifc_inout  io_dq(ddr3_dq)       clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_addr     addr      clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_ba       ba        clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_ras_n    ras_n     clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_cas_n    cas_n     clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_we_n     we_n      clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_reset_n  reset_n   clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_cs_n     cs_n      clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_odt      odt       clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_cke      cke       clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_dm       dm        clocked_by(no_clock) reset_by(no_reset);
    ifc_inout  io_dqs_p(ddr3_dqs_p) clocked_by(no_clock) reset_by(no_reset);
    ifc_inout  io_dqs_n(ddr3_dqs_n) clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_ck_p     ck_p      clocked_by(no_clock) reset_by(no_reset);
    method  ddr3_ck_n     ck_n      clocked_by(no_clock) reset_by(no_reset);
  endinterface: dram

  interface DRAM_AVL_8B avl;
    method avl_ready          rdy                                                     clocked_by(afi_half) reset_by(afi_rstn);
    method                    burstbegin (avl_burstbegin)      enable((*inhigh*)ena1) clocked_by(afi_half) reset_by(afi_rstn);
    method                    addr       (avl_addr)            enable((*inhigh*)ena2) clocked_by(afi_half) reset_by(afi_rstn); 
    method avl_rdata_valid    rdata_valid                                             clocked_by(afi_half) reset_by(afi_rstn);
    method avl_rdata          rdata                                                   clocked_by(afi_half) reset_by(afi_rstn);
    method                    wdata      (avl_wdata)           enable((*inhigh*)ena3) clocked_by(afi_half) reset_by(afi_rstn); 
    method                    be         (avl_be   )           enable((*inhigh*)ena4) clocked_by(afi_half) reset_by(afi_rstn); 
    method avl_read_req       read_req                                                clocked_by(afi_half) reset_by(afi_rstn);
    method avl_write_req      write_req                                               clocked_by(afi_half) reset_by(afi_rstn);
    method                    size       (avl_size)            enable((*inhigh*)ena5) clocked_by(afi_half) reset_by(afi_rstn); 
  endinterface: avl

  interface DRAM_STATUS status;
    method local_init_done   init_done                                                clocked_by(afi_half) reset_by(afi_rstn);
    method local_cal_success cal_success                                              clocked_by(afi_half) reset_by(afi_rstn);
    method local_cal_fail    cal_fail                                                 clocked_by(afi_half) reset_by(afi_rstn);
  endinterface: status

  schedule 
    (dram_addr, dram_ba, dram_ras_n, dram_cas_n, dram_we_n, dram_cs_n, dram_odt, dram_cke, dram_dm, dram_ck_p, dram_ck_n, dram_reset_n)
    CF
    (dram_addr, dram_ba, dram_ras_n, dram_cas_n, dram_we_n, dram_cs_n, dram_odt, dram_cke, dram_dm, dram_ck_p, dram_ck_n, dram_reset_n);
  schedule
    (avl_rdy, avl_rdata_valid, avl_rdata, avl_read_req, avl_write_req, avl_burstbegin, avl_addr, avl_wdata, avl_be, avl_size,
      status_init_done, status_cal_success, status_cal_fail)
    CF
    (avl_rdy, avl_rdata_valid, avl_rdata, avl_read_req, avl_write_req, avl_burstbegin, avl_addr, avl_wdata, avl_be, avl_size,
      status_init_done, status_cal_success, status_cal_fail);



endmodule: vMkS4DDR3

`ifdef HLC_DRAM

module mkDramController#(Clock sys0_clk, Clock mem_clk) (DramControllerIfc);
  Clock                 clk           <-  exposeCurrentClock;
  Reset                 rst_n         <-  exposeCurrentReset;
  Reset                 rst_p         <-  mkResetInverter(rst_n);                  
  Reset                 mem_rst_p     <-  mkAsyncReset(2, rst_p, sys0_clk); // active-high for importBVI use
  let _m <- vMkV6DDR3(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by mem_rst_p);
  return(_m);
endmodule: mkDramController

module mkDramControllerUi#(Clock sys0_clk, Clock mem_clk) (DramControllerUiIfc);
  Reset                 rst_n         <- exposeCurrentReset;
  Reset                 rst_p         <- mkResetInverter(rst_n);                  
  Reset                 mem_rst_p     <- mkAsyncReset(16, rst_p, sys0_clk); // active-high for importBVI use
  DramControllerIfc     memc          <- vMkV6DDR3(sys0_clk, mem_clk, clocked_by sys0_clk, reset_by mem_rst_p);
  FIFO#(DramReq16B)     reqF          <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
  FIFO#(Bit#(128))      respF         <- mkFIFO(        clocked_by memc.uclk, reset_by memc.urst_n);
  Reg#(Bit#(16))        requestCount  <- mkReg(0,       clocked_by memc.uclk, reset_by memc.urst_n);
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
  // TODO: Guard the maximum number of Read Responses in flight so as not to overflow the respF;
  // The DRAM controntroller read channel does not respect backpressure!
  rule advance_readData (unpack(memc.app.init_complete) && unpack(memc.app.rd_data_valid));
    let p = rdpF.first;
    case({unpack(memc.app.rd_data_end),p})
      3'b000: respF.enq(memc.app.rd_data[127:0]  );  //16B-0 from W0 LS
      3'b101: respF.enq(memc.app.rd_data[255:128]);  //16B-1 from W1 MS **
      3'b110: respF.enq(memc.app.rd_data[127:0]  );  //16B-2 from W1 LS
      3'b011: respF.enq(memc.app.rd_data[255:128]);  //16B-3 from W0 MS **
    endcase
    if (unpack(memc.app.rd_data_end)) rdpF.deq; // we are done with this read response, deq the rdpF
  endrule

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
  method Bit#(16) reqCount = requestCount;
endmodule: mkDramControllerUi

`endif

endpackage: DRAM_s4
