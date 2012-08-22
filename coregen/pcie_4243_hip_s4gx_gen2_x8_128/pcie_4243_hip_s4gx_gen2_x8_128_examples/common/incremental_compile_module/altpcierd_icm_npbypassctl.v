// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : core_wrapper_tx.v
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
`include "altpcierd_icm_defines.v"

module altpcierd_icm_npbypassctl   # (
                          parameter TXCRED_WIDTH = 22
                    )( clk, rstn,
                      tx_cred, data_in, data_valid, data_ack, tx_bridge_idle,
                    tx_npcredh, tx_npcredd, tx_npcredh_infinite, tx_npcredd_infinite,
                    np_data_in, np_fifo_wrempty, np_fifo_rdempty, np_data_ack,
                    ena_np_bypass,  tx_mask, got_cred, sending_np, sending_npd,
                    tx_ack, req_npbypass_pkt );


   input         clk;
   input         rstn;
   input [65:0]  tx_cred;             // from core.  available credits.  this is a concatenation of info for 6 credit types
                                      // bit 10 = means no NP header credits avail
                             // bit 11 = means no NP data credits avail
   input [107:0] data_in;             // indicates data_in is valid
   input         data_valid;          // indicates data_in is valid
   input         data_ack;
   input         tx_bridge_idle;      // means tx avalon-to-legacy bridge is not transferring a pkt. okay to switch data source.
   input         np_fifo_wrempty;     // npbypass fifo is empty
   input         np_fifo_rdempty;
   input[107:0]  np_data_in;          // data output from npbypass fifo
   input         np_data_ack;
   input[7:0]    tx_npcredh;
   input[11:0]   tx_npcredd;
   input         tx_npcredh_infinite;
   input         tx_npcredd_infinite;
   input         tx_ack;
   input         sending_np;
   input         sending_npd;

   output        req_npbypass_pkt;

   output        tx_mask;             // tells app to mask out nonposted requests
   output        ena_np_bypass;       // Control to route NP requests to npbypass fifo
   output        got_cred;

   wire          ena_np_bypass;
   reg           ena_np_bypass_r;
   reg           tx_mask;

   wire          sim_npreq;  // for simulation only
   reg           got_nph_cred;
   reg           got_npd_cred;

   wire          req_npbypass_pkt;

   reg[10:0]     sim_count;
   reg           sim_sop_del;

   wire          got_cred;
   wire          got_nph_cred_c;
   wire          got_npd_cred_c;
   reg           flush_np_bypass;

   reg           np_tx_ack_del;

   assign sim_npreq   = data_in[`STREAM_NP_REQ_FLAG]; // for simulation only

   //------------------------------------------------------
   // Credit Check
   // Bypass NP requests if core has no header credits,
   // FOR NOW .. MAINTAIN STRICT ORDERING ON NP's
   // NP Read requests require 1 header credit.
   // NP Write requests require 1 data credit.
   //-------------------------------------------------------

   // assert bypass whenever there are no header credits, or whenever
   // a write request is received and there are no data credits.
   // release after there are enough credits to accept the next NP
   // packet, and all deferred NP packets have been flushed.
   // should be able to release ena_np_bypass  before fifo is flushed - but leave like this for now.

     assign ena_np_bypass    = (data_in[`STREAM_NP_SOP_FLAG] &
                               (~got_nph_cred_c | (~got_npd_cred_c & data_in[`STREAM_NP_WRREQ_FLAG])))  ? 1'b1 :  np_fifo_wrempty  ? 1'b0 : ena_np_bypass_r;  // need to account for latency in np_fifo_empty


   assign req_npbypass_pkt = flush_np_bypass;

   /////////////////////////////////////////////////////////////////////
   // For x4/x1 core (TXCRED_WIDTH == 22), use only the LSB
   // For x8 core    (TXCRED_WIDTH == 66), use registered equation
   ////////////////////////////////////////////////////////////////////
/*
   assign got_nph_cred_c = (TXCRED_WIDTH == 22) ? tx_npcredh[0] : got_nph_cred;
   assign got_npd_cred_c = (TXCRED_WIDTH == 22) ? tx_npcredd[0] : got_npd_cred;
*/
   // x4 work around - do not evaluate credits until 2nd cycle after tx_ack asserts
   assign got_nph_cred_c = (TXCRED_WIDTH == 22) ? (tx_npcredh[0] & ~np_tx_ack_del) : got_nph_cred;
   assign got_npd_cred_c = (TXCRED_WIDTH == 22) ? (tx_npcredd[0] & ~np_tx_ack_del) : got_npd_cred;

   assign got_cred       = 1'b0;

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
          ena_np_bypass_r    <= 1'b0;
         tx_mask            <= 1'b0;
         sim_sop_del        <= 1'b0;
         sim_count          <= 11'h0;
         got_nph_cred       <= 1'b0;
         got_npd_cred       <= 1'b0;
         flush_np_bypass    <= 1'b0;
         np_tx_ack_del      <= 1'b0;
      end
      else begin
          ena_np_bypass_r    <= ena_np_bypass;
         np_tx_ack_del      <= tx_ack & sending_np;


         if (tx_npcredh_infinite)       got_nph_cred <= 1'b1;
         else if (tx_ack & sending_np)  got_nph_cred <= |tx_npcredh[7:1];    // if credits=1 on this cycle, assume it is zero on next.
         else                           got_nph_cred <= |tx_npcredh;         // okay to evaluate on any non-tx_ack cycle

         if (tx_npcredd_infinite)       got_npd_cred <= 1'b1;
           else if (tx_ack & sending_npd) got_npd_cred <= |tx_npcredd[11:1];   // if credits=1 on this cycle, assume it is zero on next.
         else                           got_npd_cred <= |tx_npcredd;         // okay to evaluate on any non-tx_ack cycle



         if (np_fifo_rdempty) begin
             flush_np_bypass <= 1'b0;
         end
         else if (np_data_in[`STREAM_NP_SOP_FLAG]) begin
             flush_np_bypass <=  got_nph_cred_c & (got_npd_cred_c | ~np_data_in[`STREAM_NP_WRREQ_FLAG]);
         end
         else begin
             flush_np_bypass <= 1'b0;
         end

         ////////////////////// FOR SIMULATION ONLY ////////////////////////////////
         // COUNT # NP REQUESTS
         sim_sop_del <= data_valid ? data_in[`STREAM_SOP] : sim_sop_del;

           if (data_in[`STREAM_NP_REQ_FLAG] & data_in[`STREAM_SOP] & ~sim_sop_del)
               sim_count <= sim_count + 1;

         ///////////////////////////////////////////////////////////////////////////

         // assert tx_mask as soon as the first nonposted
         // request requires bypassing.
         // deassert when bypass fifo is empty (for now)
         tx_mask <= (~got_nph_cred_c | (~got_npd_cred_c & data_in[`STREAM_NP_WRREQ_FLAG])) ? 1'b1 : np_fifo_wrempty ? 1'b0 : tx_mask;

      end
   end


endmodule
