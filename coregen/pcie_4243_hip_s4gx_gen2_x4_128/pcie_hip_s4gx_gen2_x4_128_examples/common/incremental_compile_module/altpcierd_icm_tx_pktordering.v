// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_tx_pktordering.v
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
 
module altpcierd_icm_tx_pktordering #( 
                        parameter TXCRED_WIDTH = 22 
			         )(
                        clk, rstn,  
				        data_ack, data_valid, data_in, 
						tx_bridge_idle,  tx_cred, tx_npcredh, tx_npcredd, tx_npcredh_infinite, tx_npcredd_infinite,
						pri_data_ack, pri_data_valid, pri_data, 
						tx_mask, tx_ack, ena_np_bypass, sending_np, sending_npd,
						req_npbypass_pkt,  np_data_valid, np_data, np_data_ack, msi_busy,
						tx_fifo_rd, np_fifo_almostfull); 
						
   parameter     NPBYPASSFIFO_NUMWORDS   = 32;   // Depth of NPBypass Fifo
   parameter     NPBYPASSFIFO_WIDTHU     = 5;    // Number of bits in NUMWORDS
   parameter     NPBYPASSFIFO_ALMOSTFULL = 28;   // Almost_Full flag should be atleast 1 NP packet (3 entries) from FULL
   
   input         clk;  
   input         rstn;       
   
   input         data_valid;     // indicates data_in is valid
   input[107:0]  data_in;        // data from TX streaming fifo  
   output        data_ack;       // accepts data_in 
   input         tx_bridge_idle;        // means no packet is being transferred to the core
   input[65:0]   tx_cred;               // available credits from core.  this is a concatenation of info for 6 credit types
   input[7:0]    tx_npcredh;
   input[11:0]   tx_npcredd;
   input         tx_npcredh_infinite;
   input         tx_npcredd_infinite;
   input         tx_ack;
   input         sending_np;
   input         sending_npd;
   input         msi_busy;
   input         tx_fifo_rd;

   output        pri_data_valid;          // indicates data_in is valid
   output[107:0] pri_data;                // data from TX streaming interface    
   input         pri_data_ack; 
   output        tx_mask;               // masks nonposted requests from app 
   
   output        req_npbypass_pkt;  
   output        np_fifo_almostfull;

   output        np_data_valid;          // indicates data_in is valid
   output[107:0] np_data;                // data from TX streaming interface  
   input         np_data_ack;
   
   output        ena_np_bypass;

   wire          np_data_valid;          // indicates data_in is valid 

   wire          data_ack;  
   wire          ena_np_bypass;          // means core does not have enough NP credits.  Bypass NP requests  
   reg           np_fifo_almostfull_del;

   wire          pri_data_valid;          
   wire[107:0]   pri_data;                 
   
   // fifo
   wire          np_fifo_rd;
   wire          np_fifo_wr;
   wire          np_fifo_almostfull;
   wire          np_fifo_full;
   wire          np_fifo_empty;
   wire[107:0]   np_data;
   wire[107:0]   np_fifo_wrdata;
   wire[107:0]   npflags_fifo_wrdata;
   wire[107:0]   np_fifo_rddata;
   wire[107:0]   npflags_fifo_rddata;
   reg           np_fifo_wrempty_r;
   wire          np_fifo_wrempty;
   wire[3:0]     used_words; 
   wire          ordered_pkt_start;   
   reg           np_fifo_wr_r;
    
   
   reg[107:0]    data_in_del;
   reg           np_fifo_wr_del;
   wire[84:0]    dataindel_84_to_0;
   wire[2:0]     dataindel_87_to_85;

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin 
		   data_in_del     <= 108'h0;
		   np_fifo_wr_del  <= 1'b0;  
	   end
	   else begin 
		   data_in_del     <= data_in;
		   np_fifo_wr_del  <= np_fifo_wr;  
	   end 
   end

   
   //------------------------------------------------------------
   // 
   //-------------------------------------------------------------
   
   assign pri_data_valid  =  data_valid; // & ~(ena_np_bypass & data_in[`STREAM_NP_REQ_FLAG]);  // do not pass data to bridge if it is an NP request in bypass mode
   assign pri_data        =  data_in;
   
   // -----------------------------------------------------------
   // Fifos for Bypassed NonPosted requests.
   // Streaming NP data is deferred to this Fifo until the core 
   // has enough credits to accept them
   //------------------------------------------------------------

   /////////////////////////////////////////////////////////
   // NP BYPASS DATA FIFO
   ////////////////////////////////////////////////////////
	    
   assign   dataindel_84_to_0 =  data_in_del[84:0];
   assign   np_fifo_wrdata    = {23'h0, dataindel_84_to_0}; 
   assign   np_data[84:0]     = np_fifo_rddata[84:0];
  
  defparam  npbypass_fifo_131x4.NUMWORDS    = NPBYPASSFIFO_NUMWORDS; 
  defparam  npbypass_fifo_131x4.WIDTHU      = NPBYPASSFIFO_WIDTHU;
  defparam  npbypass_fifo_131x4.ALMOST_FULL = NPBYPASSFIFO_ALMOSTFULL; 
  
   altpcierd_icm_fifo_lkahd   #( 
       .RAMTYPE     ("RAM_BLOCK_TYPE=AUTO"),
	   .ALMOST_FULL (NPBYPASSFIFO_ALMOSTFULL),
	   .NUMWORDS    (NPBYPASSFIFO_NUMWORDS),
	   .WIDTHU      (NPBYPASSFIFO_WIDTHU)
      )  npbypass_fifo_131x4( 
                           .clock        (clk),
                           .aclr         (~rstn),
                           .data         (np_fifo_wrdata),
						   .wrreq        (np_fifo_wr_del),
						   .rdreq        (np_fifo_rd),
						   .q            (np_fifo_rddata),
						   .full         (),
						   .almost_full  ( ),
						   .almost_empty ( ), 
						   .empty        ( ),
						   .usedw        ( ));

 					   
   /////////////////////////////////////////////////////////
   // NP BYPASS FLAGS FIFO
   ////////////////////////////////////////////////////////
	
   assign   dataindel_87_to_85  = data_in_del[87:85];
   assign   npflags_fifo_wrdata = {105'h0, dataindel_87_to_85}; 
   assign   np_data[87:85]      = npflags_fifo_rddata[2:0]; 
   
    // NOTE:  Synthesizing this Fifo in LC's may give better Fmax
    // altera_mf does not simulate USE_EAB=OFF   
    //    defparam npbypassflags_fifo_131x4.USEEAB = "OFF";
   	// synopsys synthesis_off 
   	//    defparam npbypassflags_fifo_131x4.USEEAB = "ON";
	// synopsys synthesis_on
  
  defparam  npbypassflags_fifo_131x4.NUMWORDS    = NPBYPASSFIFO_NUMWORDS;
  defparam  npbypassflags_fifo_131x4.WIDTHU      = NPBYPASSFIFO_WIDTHU;
  defparam  npbypassflags_fifo_131x4.ALMOST_FULL = NPBYPASSFIFO_ALMOSTFULL; 
   
   altpcierd_icm_fifo_lkahd     #(  
	   .ALMOST_FULL (NPBYPASSFIFO_ALMOSTFULL),
	   .NUMWORDS    (NPBYPASSFIFO_NUMWORDS),
	   .WIDTHU      (NPBYPASSFIFO_WIDTHU)
      )  npbypassflags_fifo_131x4( 
                           .clock        (clk),
                           .aclr         (~rstn),
                           .data         (npflags_fifo_wrdata),
						   .wrreq        (np_fifo_wr_del),
						   .rdreq        (np_fifo_rd),
						   .q            (npflags_fifo_rddata),
						   .full         (np_fifo_full),
						   .almost_full  (np_fifo_almostfull),
						   .almost_empty ( ), 
						   .empty        (np_fifo_empty),
						   .usedw        (used_words)); 


   
   assign   np_data_valid = 1'b1;
	
   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin 
		   np_fifo_almostfull_del <= 1'b0; 
		   np_fifo_wrempty_r      <= 1'b1; 
		   np_fifo_wr_r           <= 1'b0;
	   end
	   else begin 
		   np_fifo_almostfull_del <= np_fifo_almostfull;  
		   np_fifo_wr_r           <= np_fifo_wr;
		   
		   if (np_fifo_wr & ~np_fifo_rd)            // write, but no read
		       np_fifo_wrempty_r <= 1'b0;
		   else if ((np_fifo_wr_del==1'b0) & (np_fifo_wr==1'b0) & (np_fifo_wr_r==1'b0) & (np_fifo_rd==1'b1) & (used_words==1))    // no writes in progress, but reading last entry 
		       np_fifo_wrempty_r <= 1'b1;
		   else 
		       np_fifo_wrempty_r <= np_fifo_wrempty;  // else no change
	   end 
   end
    
   assign np_fifo_wrempty = np_fifo_wrempty_r; 
   
   // np fifo controls
//   assign np_fifo_wr = ena_np_bypass & data_valid & data_in[`STREAM_NP_REQ_FLAG] & data_ack & ~msi_busy;

   assign np_fifo_wr = ena_np_bypass & data_in[`STREAM_NP_REQ_FLAG] & tx_fifo_rd;
   assign np_fifo_rd = np_data_ack & ~np_fifo_empty;
   
   //----------------------------------------------------- 
   // Streaming Interface Control
   //-----------------------------------------------------
   
   assign data_ack = pri_data_ack;  
	
   //-----------------------------------------------------
   // NP Bypass Control
   // Monitors core credits and determines if NP requests 
   // need to be deferred.
   //-----------------------------------------------------
   altpcierd_icm_npbypassctl   #( 
       .TXCRED_WIDTH  (TXCRED_WIDTH)
      ) altpcierd_icm_npbypassctl(
       .clk(clk), .rstn(rstn),
	   .tx_cred(tx_cred), .data_in(data_in), .data_valid(data_valid),  .data_ack(data_ack),
	   .tx_npcredh(tx_npcredh), .tx_npcredd(tx_npcredd), .tx_npcredh_infinite(tx_npcredh_infinite), .tx_npcredd_infinite(tx_npcredd_infinite),
	   .tx_bridge_idle(tx_bridge_idle), .np_fifo_wrempty(np_fifo_wrempty), .np_fifo_rdempty(np_fifo_empty), .np_data_in(np_data),
	   .tx_ack(tx_ack), .np_data_ack(np_data_ack), .sending_np(sending_np), .sending_npd(sending_npd),
	   .ena_np_bypass(ena_np_bypass), .tx_mask(tx_mask), .got_cred( ),
	   .req_npbypass_pkt(req_npbypass_pkt) 
   );
   
 
   
endmodule
