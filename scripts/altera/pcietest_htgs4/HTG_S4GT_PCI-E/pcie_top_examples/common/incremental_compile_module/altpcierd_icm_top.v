// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_top.v
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
module altpcierd_icm_top #( 
                parameter TXCRED_WIDTH = 22 
               )(  clk, rstn, 
                   rx_req0, rx_ack0, rx_desc0, rx_data0, rx_be0, 
                   rx_ws0, rx_dv0, rx_dfr0, rx_abort0, rx_retry0, rx_mask0, 
                   rx_stream_ready0, rx_stream_valid0, rx_stream_data0, rx_stream_mask0, 
                   tx_req0, tx_ack0, tx_desc0, tx_data0, tx_ws0, tx_dv0, tx_dfr0, 
                   tx_err0, 
                   tx_cred0, tx_stream_cred0,
                   tx_npcredh0, tx_npcredd0, tx_npcredh_inf0, tx_npcredd_inf0,
                   app_msi_ack, app_msi_req, app_msi_num, app_msi_tc,
                   tx_stream_ready0, tx_stream_valid0, tx_stream_data0,
                   msi_stream_ready0, msi_stream_valid0, msi_stream_data0,
                   tx_stream_mask0,
                   cpl_pending_icm, cpl_pending, 
                   cfg_busdev_icm,  cfg_devcsr_icm,  cfg_linkcsr_icm, cfg_prmcsr_icm,
                   cfg_tcvcmap_icm,  app_int_sts_icm,  app_int_sts_ack_icm, pex_msi_num_icm, cpl_err_icm, cfg_msicsr_icm,
                   cfg_busdev,  cfg_devcsr,  cfg_linkcsr, cfg_prmcsr, cfg_msicsr, 
                   cfg_tcvcmap,  app_int_sts,  app_int_sts_ack, pex_msi_num, cpl_err,
                   test_out, test_out_icm
                   );

     
   
   input         clk;  
   input         rstn;    
   
   // RX IO
   input         rx_req0;   
   input[135:0]  rx_desc0; 
   input[63:0]   rx_data0; 
   input[7:0]    rx_be0;  
   input         rx_dv0; 
   input         rx_dfr0;    
   
   output        rx_ack0;   
   output        rx_abort0;  
   output        rx_retry0;  
   output        rx_ws0;
   output        rx_mask0;
   
   input         rx_stream_ready0; 
   output        rx_stream_valid0; 
   output[81:0]  rx_stream_data0;  
   input         rx_stream_mask0;
   
   
   // TX  IO
   input         tx_ack0;    
   input         tx_ws0; 
   input [TXCRED_WIDTH-1:0]  tx_cred0;
   input [7:0]   tx_npcredh0;
   input [11:0]  tx_npcredd0;
   input         tx_npcredh_inf0;
   input         tx_npcredd_inf0;
   
   output        tx_req0;   
   output[127:0] tx_desc0; 
   output[63:0]  tx_data0;  
   output        tx_dv0; 
   output        tx_dfr0;
   
   output        tx_err0; 
   output [TXCRED_WIDTH-1:0] tx_stream_cred0;
   reg [TXCRED_WIDTH-1:0]    tx_stream_cred0;

   input         tx_stream_valid0; 
   input[74:0]   tx_stream_data0;     
   output        tx_stream_ready0;
   output        tx_stream_mask0;

   
   
   // MSI IO
   input         app_msi_ack;
   output        app_msi_req;
   output[4:0]   app_msi_num;
   output[2:0]   app_msi_tc;
   
   input         msi_stream_valid0; 
   input[7:0]    msi_stream_data0;     
   output        msi_stream_ready0;      


   // CONFIG SIDEBAND
   
   input    [ 12: 0] cfg_busdev;
   input    [ 31: 0] cfg_devcsr;
   input    [ 31: 0] cfg_linkcsr;
   input    [ 31: 0] cfg_prmcsr;
   input    [ 23: 0] cfg_tcvcmap; 
   input    [15:0]   cfg_msicsr;
   input             app_int_sts_icm;
   input    [  4: 0] pex_msi_num_icm; 
   input    [  2: 0] cpl_err_icm;
   input             cpl_pending_icm;
   input             app_int_sts_ack;

   output    [ 12: 0] cfg_busdev_icm;
   output    [ 31: 0] cfg_devcsr_icm;
   output    [ 31: 0] cfg_linkcsr_icm;
   output    [ 31: 0] cfg_prmcsr_icm;
   output    [ 23: 0] cfg_tcvcmap_icm;  
   output    [15:0]   cfg_msicsr_icm;
   output             app_int_sts;
   output    [  4: 0] pex_msi_num; 
   output    [  2: 0] cpl_err;
   output             cpl_pending;
   output             app_int_sts_ack_icm;
   
   // TEST SIGNALS  
   input  [8:0]     test_out;
   output [8:0]     test_out_icm;
   
   reg [8:0]        test_out_icm;
   
   wire  [107:0]      rx_stream_data0_int;
   wire  [81:0]       rx_stream_data0;
   wire  [107:0]      tx_stream_data0_int; 

   
   assign rx_stream_data0 = rx_stream_data0_int[81:0];
   assign tx_stream_data0_int = {33'h0, tx_stream_data0};

   
   // Bridge from Core RX port to RX Streaming port
   altpcierd_icm_rx altpcierd_icm_rx(
                 .clk(clk), .rstn(rstn), 
                 .rx_req(rx_req0), .rx_ack(rx_ack0), .rx_desc(rx_desc0), 
                 .rx_data(rx_data0), .rx_be(rx_be0), 
                 .rx_ws(rx_ws0), .rx_dv(rx_dv0), .rx_dfr(rx_dfr0), .rx_abort(rx_abort0), 
                 .rx_retry(rx_retry0), .rx_mask(rx_mask0), 
                 .rx_stream_ready(rx_stream_ready0), 
                 .rx_stream_valid(rx_stream_valid0), .rx_stream_data(rx_stream_data0_int), .rx_stream_mask(rx_stream_mask0)
                 );   
     
   // Contains 2 Bridges:  Core TX port to TX Streaming Port 
   //                      Core MSI port to MSI Streaming Port
   // Data from the TX and MSI ports are kept synchronized thru this bridge.
   altpcierd_icm_tx  #( 
            .TXCRED_WIDTH  (TXCRED_WIDTH)
           ) altpcierd_icm_tx(
                 .clk(clk), .rstn(rstn), 
                 .tx_req(tx_req0), .tx_ack(tx_ack0), .tx_desc(tx_desc0), 
                 .tx_data(tx_data0), .tx_ws(tx_ws0), .tx_dv(tx_dv0), .tx_dfr(tx_dfr0), .tx_be(),
                 .tx_err(tx_err0), .tx_cpl_pending(), .tx_cred_int(tx_cred0), 
                 .tx_npcredh(tx_npcredh0), .tx_npcredd(tx_npcredd0), .tx_npcredh_infinite(tx_npcredh_inf0), .tx_npcredd_infinite(tx_npcredd_inf0),   
                 .stream_ready(tx_stream_ready0), 
                 .stream_valid(tx_stream_valid0), .stream_data_in(tx_stream_data0_int),  
                 .app_msi_ack(app_msi_ack), .app_msi_req(app_msi_req), .app_msi_num(app_msi_num), .app_msi_tc(app_msi_tc),
                 .stream_msi_ready(msi_stream_ready0), .stream_msi_valid(msi_stream_valid0), .stream_msi_data_in(msi_stream_data0),
                 .tx_mask(tx_stream_mask0), .tx_cred()
    );
   
   // Configuration sideband signals
   altpcierd_icm_sideband altpcierd_icm_sideband(
     .clk(clk), .rstn(rstn),             
     .cfg_busdev(cfg_busdev), .cfg_devcsr(cfg_devcsr), .cfg_linkcsr(cfg_linkcsr), .cfg_msicsr(cfg_msicsr),
.cfg_prmcsr(cfg_prmcsr), .cfg_prmcsr_del(cfg_prmcsr_icm),
     .cfg_tcvcmap(cfg_tcvcmap), .app_int_sts(app_int_sts_icm), .pex_msi_num(pex_msi_num_icm), .cpl_err(cpl_err_icm),
     .app_int_sts_ack(app_int_sts_ack), .app_int_sts_ack_del(app_int_sts_ack_icm), 
     .cpl_pending(cpl_pending_icm),
     .cfg_busdev_del(cfg_busdev_icm), .cfg_devcsr_del(cfg_devcsr_icm), .cfg_linkcsr_del(cfg_linkcsr_icm), .cfg_msicsr_del(cfg_msicsr_icm),
     .cfg_tcvcmap_del(cfg_tcvcmap_icm), .app_int_sts_del(app_int_sts), .pex_msi_num_del(pex_msi_num), 
     .cpl_err_del(cpl_err), .cpl_pending_del(cpl_pending)
  );
  
  
   ///////////////////////////////////////////////////////
   // Incremental Compile Output boundary registers 
   ///////////////////////////////////////////////////////
   
   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
           test_out_icm    <= 9'h0;
           tx_stream_cred0 <= {TXCRED_WIDTH{1'b0}};
       end
       else begin
           test_out_icm    <= test_out;
           tx_stream_cred0 <= tx_cred0;
       end
   end 
   
endmodule
