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

module altpcierd_icm_txbridge_withbypass #( 
                        parameter TXCRED_WIDTH = 22 
			         ) (
                        clk, rstn, 
                        tx_req, tx_ack, tx_desc, tx_data, tx_ws, tx_dv, tx_dfr, tx_be,
						tx_err, tx_cpl_pending, tx_cred,
						tx_npcredh, tx_npcredd, tx_npcredh_infinite, tx_npcredd_infinite,
				        data_ack, data_valid, data_in,  
						tx_bridge_idle, tx_mask,
						msi_busy, tx_fifo_rd);
 

   input         clk;  
   input         rstn;     
   input         tx_ack;                // from core.  TX request ack
   input         tx_ws;                 // from core.  TX dataphase throttle
   input[65:0]   tx_cred;               // from core.  available credits.  this is a concatenation of info for 6 credit types
   input[7:0]    tx_npcredh;
   input[11:0]   tx_npcredd;
   input         tx_npcredh_infinite;
   input         tx_npcredd_infinite;
   input         msi_busy;
   input         tx_fifo_rd;
   
   output        tx_req;                // to core.  TX request
   output[127:0] tx_desc;               // to core.  TX pkt descriptor
   output[63:0]  tx_data;               // to core.  TX pkt payload data
   output        tx_dv;                 // to core.  TX dv contol
   output        tx_dfr;                // to core.  TX dfr contol
   output[7:0]   tx_be;                 // to core.  TX byte enabel -- not used
   output        tx_cpl_pending;        // to core.  TX completion pending status
   output        tx_err;                // to core.  TX error status
   output        tx_bridge_idle;
   output        tx_mask;               // to app.  throttles nonposted requests

   input         data_valid;          // indicates data_in is valid
   input[107:0]  data_in;             // data from TX streaming interface   
   output        data_ack;            // throttles data on TX streaming interface   

   wire       	 req_npbypass_pkt;
   wire          np_data_valid;          // indicates data_in is valid
   wire[107:0]   np_data;                // data from the np bypass fifo   
   wire          np_data_ack;
   
   wire          fifo_rd;               // fifo read control
   wire[107:0]   fifo_rddata;           // fifo read data
   wire          fifo_data_valid;       // menas fifo_rddata is valid 
   wire          tx_bridge_idle; 
   wire          pri_data_valid;          
   wire[107:0]   pri_data;                  
   wire          pri_data_ack;
   wire          ena_np_bypass;
   wire          sending_np;
   wire          sending_npd;
   wire          np_fifo_almostfull;
   
   // Data from the avalon interface gets reordered
   // as required for NP bypassing before it is 
   // translated to the Core Interface
   
   altpcierd_icm_tx_pktordering #( 
            .TXCRED_WIDTH  (TXCRED_WIDTH)
       ) altpcierd_icm_tx_pktordering (
       .clk(clk), .rstn(rstn), 
	   .data_valid(data_valid), .data_in(data_in), .data_ack(data_ack), 
	   .tx_bridge_idle(tx_bridge_idle),  .tx_cred(tx_cred),
	   .tx_npcredh(tx_npcredh), .tx_npcredd(tx_npcredd), .tx_npcredh_infinite(tx_npcredh_infinite), .tx_npcredd_infinite(tx_npcredd_infinite), 
	   .tx_mask(tx_mask),  
	   .req_npbypass_pkt(req_npbypass_pkt) , .tx_ack(tx_ack),  
	   .ena_np_bypass(ena_np_bypass), .sending_np(sending_np), .sending_npd(sending_npd),
	   .pri_data_valid (pri_data_valid), .pri_data(pri_data), .pri_data_ack(pri_data_ack),
	   .np_data_valid(np_data_valid), .np_data(np_data), .np_data_ack(np_data_ack) , .msi_busy(msi_busy) ,
	   .tx_fifo_rd(tx_fifo_rd), .np_fifo_almostfull(np_fifo_almostfull)
   );
 
  
   // Bridge to the Core TX Interface  
   // Reordered packets are passed to the Core interface  
   
   altpcierd_icm_txbridge altpcierd_icm_txbridge (
       .clk(clk), .rstn(rstn), 
       .pri_data_valid(pri_data_valid), .pri_data_in(pri_data), .pri_data_ack(pri_data_ack),  
	   .ena_np_bypass(ena_np_bypass), 
	   .np_data_valid(np_data_valid), .np_data_in(np_data), .np_data_ack(np_data_ack), 
	   .tx_ack(tx_ack), .tx_ws(tx_ws), .sending_np(sending_np), .sending_npd(sending_npd),
	   .tx_req(tx_req), .tx_dfr(tx_dfr), .tx_dv(tx_dv), .tx_data(tx_data), .tx_desc(tx_desc), .tx_be(tx_be),
	   .tx_err(tx_err), .tx_cpl_pending(tx_cpl_pending), .tx_bridge_idle(tx_bridge_idle),
	   .req_npbypass_pkt(req_npbypass_pkt) , .msi_busy(msi_busy),
	   .np_fifo_almostfull(np_fifo_almostfull)
   );
   
   
 
endmodule
