// FFT.bsv - BSV Wrapper for Vendor FFT Primatives
// Copyright (c) 2010  Atomic Rules LCC ALL RIGHTS RESERVED

package FFT;

import Clocks          ::*;
import Complex         ::*;
import ClientServer    ::*;
import Connectable     ::*;
import FIFO            ::*;
import FIFOF           ::*;
import FixedPoint      ::*;
import GetPut          ::*;
import SpecialFIFOs    ::*;
import Vector          ::*;
import XilinxCells     ::*;

// Interfaces...

(* always_enabled, always_ready *)
interface FFTvIfc;
  method Action   fwd      (Bit#(1)  i);
  method Action   fwd_we   (Bit#(1)  i);
  method Action   scale    (Bit#(12) i);
  method Action   scale_we (Bit#(1)  i);
  method Action   start    (Bit#(1)  i);
  method Bit#(1)  readyForData;
  method Bit#(1)  dataValid;
  method Bit#(1)  edone;
  method Bit#(1)  done;
  method Bit#(1)  busy;
  method Action   xnRe    (Bit#(16) i);
  method Action   xnIm    (Bit#(16) i);
  method Bit#(12) xnIndex;
  method Bit#(16) xkRe;
  method Bit#(16) xkIm;
  method Bit#(12) xkIndex;
endinterface: FFTvIfc


import "BVI" xfft_v7_1 = 
module vMkFFT (FFTvIfc);

  default_clock clk   (clk);
  default_reset rst_n (no_reset); 

  // Action methods methodName (VerilogPort)...
  method fwd      (fwd_inv)       enable((*inhigh*)ena1);
  method fwd_we   (fwd_inv_we)    enable((*inhigh*)ena2);
  method scale    (scale_sch)     enable((*inhigh*)ena3);
  method scale_we (scale_sch_we)  enable((*inhigh*)ena4);
  method start    (start)         enable((*inhigh*)ena5);
  method xnRe     (xn_re)         enable((*inhigh*)ena6);
  method xnIm     (xn_im)         enable((*inhigh*)ena7);
  // Value methods verilogPort methodName...
  method rfd      readyForData;
  method dv       dataValid;
  method edone    edone;
  method done     done;
  method busy     busy;
  method xn_index xnIndex;
  method xk_re    xkRe;
  method xk_im    xkIm;
  method xk_index xkIndex;

  // schedule ()
  //  CF
  //  ()

endmodule: vMkFFT

/*
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

  Wire#(Bit#(3))        memcCmd_w       <- mkDWire(0,     clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bit#(33))       memcAddr_w      <- mkDWire(0,     clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bit#(64))       memcData_w      <- mkDWire(0,     clocked_by memc.uclk, reset_by memc.urst_n);
  Wire#(Bit#(8))        memcMask_w      <- mkDWire(0,     clocked_by memc.uclk, reset_by memc.urst_n);

  // Fires request for read and write...
  (* fire_when_enabled *)
  rule advance_request (unpack(memc.app.init_complete) && !unpack(memc.app.full) && !firstWriteBeat);
    let r = reqF.first;

    //memc.app.addr(extend(r.addr>>2));        // convert byte address to 64B/16B address //TODO: Check shift 
    //memc.app.cmd (r.isRead?3'b001:3'b000);   // Set the command
    memcAddr_w <= (extend(r.addr>>2));         // convert byte address to 64B/16B address //TODO: Check shift 
    memcCmd_w  <= (r.isRead?3'b001:3'b000);    // Set the command

    memc.app.en();                           // Assert the command enable
    requestCount <= requestCount + 1;        // Bump the requestCounter
    if (r.isRead) begin                      // Read...
      reqF.deq();                            // Deq for read (we are done with read request)
    end else begin                           // Write...
      //memc.app.wdf_data (r.data[63:0]);    // First 8B of data
      //memc.app.wdf_mask (~r.be[7:0]);      // Invert myBE to be a "mask"
      memcData_w <= (r.data[63:0]);          // First 8B of data
      memcMask_w <= (~r.be[7:0]);            // Invert myBE to be a "mask"
      wdfWren <= True;                       // Assert the write data enable (W0)
      firstWriteBeat <= True;                // Advance to W0
    end
  endrule

  // Fires with the secondBeat of write, with the W1 data...
  (* fire_when_enabled *)
  rule advance_write1 (unpack(memc.app.init_complete) && !unpack(memc.app.wdf_full) && firstWriteBeat);
    let r = reqF.first;
    //memc.app.wdf_data (r.data[127:64]);    // Second 8B of data
    //memc.app.wdf_mask (~r.be[15:8]);       // Invert myBE to be a "mask"
    memcData_w <= (r.data[127:64]);          // Second 8B of data
    memcMask_w <= (~r.be[15:8]);             // Invert myBE to be a "mask"
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

  // Since these methods are always-enabled by *inhigh*, drive them at all times to satisfy always_enabled assertion...
  (*  fire_when_enabled, no_implicit_conditions *)
  rule drive_memc_always_enabled (True);
    memc.app.cmd      (memcCmd_w);
    memc.app.addr     (memcAddr_w);
    memc.app.wdf_data (memcData_w);
    memc.app.wdf_mask (memcMask_w);
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
*/

endpackage: FFT
