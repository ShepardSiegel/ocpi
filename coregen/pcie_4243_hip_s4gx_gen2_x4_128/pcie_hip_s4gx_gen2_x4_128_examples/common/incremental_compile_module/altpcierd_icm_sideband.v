// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_sideband.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This is the complete example application for the PCI Express Reference
// Design. This has all of the application logic for the example.
//-----------------------------------------------------------------------------
// Copyright (c) 2006 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation 
// and therefore all warranties, representations or guarantees of any kind 
// (whether express, implied or statutory) including, without limitation, warranties of 
// merchantability, non-infringement, or fitness for a particular purpose, are 
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera. 
//-----------------------------------------------------------------------------
module altpcierd_icm_sideband (
                   clk, rstn, 
                   cfg_busdev,  cfg_devcsr,  cfg_linkcsr, cfg_msicsr, cfg_prmcsr,
                   cfg_tcvcmap,  app_int_sts,  app_int_sts_ack, pex_msi_num, cpl_err,
                   cpl_pending,
                   cfg_busdev_del,  cfg_devcsr_del,  cfg_linkcsr_del, cfg_msicsr_del, cfg_prmcsr_del,
                   cfg_tcvcmap_del,  app_int_sts_del,  app_int_sts_ack_del, pex_msi_num_del, cpl_err_del,
                   cpl_pending_del
                   );


   input             clk;  
   input             rstn;     
   input    [ 12: 0] cfg_busdev;         // From core to app
   input    [ 31: 0] cfg_devcsr;         // From core to app
   input    [ 31: 0] cfg_linkcsr;        // From core to app
   input    [ 31: 0] cfg_prmcsr;        // From core to app
   input    [ 23: 0] cfg_tcvcmap;        // From core to app
   input    [15:0]   cfg_msicsr;         // From core to app
   input    [  4: 0] pex_msi_num;        // From app to core
   input             app_int_sts;        // From app to core
   input             app_int_sts_ack;    // From core to app
   input    [  2: 0] cpl_err;
   input             cpl_pending;
   

   output    [ 12: 0] cfg_busdev_del;
   output    [ 31: 0] cfg_devcsr_del;
   output    [ 31: 0] cfg_linkcsr_del;
   output    [ 31: 0] cfg_prmcsr_del;
   output    [ 23: 0] cfg_tcvcmap_del;  
   output    [15:0]   cfg_msicsr_del;
   output             app_int_sts_del;
   output             app_int_sts_ack_del;  // To app
   output    [  4: 0] pex_msi_num_del; 
   output    [  2: 0] cpl_err_del;
   output             cpl_pending_del;
   
   
   reg       [ 12: 0] cfg_busdev_del;
   reg       [ 31: 0] cfg_devcsr_del;
   reg       [ 31: 0] cfg_linkcsr_del;
   reg       [ 31: 0] cfg_prmcsr_del;
   reg       [ 23: 0] cfg_tcvcmap_del;   
   reg                app_int_sts_del;
   reg                app_int_sts_ack_del;
   reg       [  4: 0] pex_msi_num_del;  
   reg       [  2: 0] cpl_err_del;
   
   reg      [15:0]   cfg_msicsr_del;
   
   reg                cpl_pending_del;
  
  //---------------------------------------------
  // Incremental Compile Boundary registers
  //---------------------------------------------
  always @ (posedge clk or negedge rstn) begin
      if (~rstn) begin
          cfg_busdev_del      <= 13'h0;
          cfg_devcsr_del      <= 32'h0;
          cfg_linkcsr_del     <= 32'h0;
          cfg_prmcsr_del     <= 32'h0;
          cfg_tcvcmap_del     <= 24'h0;
          cfg_msicsr_del      <= 16'h0;
          app_int_sts_del     <= 1'b0;
          app_int_sts_ack_del <= 1'b0;
          pex_msi_num_del     <= 5'h0; 
          cpl_err_del         <= 3'h0; 
          cpl_pending_del     <= 1'b0;
      end
      else begin
          cfg_busdev_del      <= cfg_busdev;
          cfg_devcsr_del      <= cfg_devcsr;
          cfg_linkcsr_del     <= cfg_linkcsr;
          cfg_prmcsr_del     <= cfg_prmcsr;
          cfg_tcvcmap_del     <= cfg_tcvcmap;
          cfg_msicsr_del      <= cfg_msicsr;
          app_int_sts_del     <= app_int_sts;  // From app to core.  NO COMBINATIONAL allowed on input
          app_int_sts_ack_del <= app_int_sts_ack;  
          pex_msi_num_del     <= pex_msi_num;  // From app to core.  NO COMBINATIONAL allowed on input
          cpl_err_del         <= cpl_err;      // From app to core.  NO COMBINATIONAL allowed on input 
          cpl_pending_del     <= cpl_pending;  // From app to core.  NO COMBINATIONAL allowed on input
      end
  end
endmodule
