// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_txbridge.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module is a bridge between the streaming interface protocol and 
// the PCIExpress core TX interface signalling.  
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
 
module altpcierd_icm_txbridge (clk, rstn, 
                               pri_data_valid, pri_data_in, pri_data_ack, 
							   ena_np_bypass, req_npbypass_pkt,
							   np_data_valid, np_data_in, np_data_ack, 
							   sending_np, sending_npd,
							   tx_ack, tx_ws, 
							   tx_req, tx_dfr, tx_dv, tx_data, tx_desc, tx_be,
							   tx_err, tx_cpl_pending, tx_bridge_idle, 
							   msi_busy, np_fifo_almostfull);
 

   
   // bridge_sm states
   parameter DESC1        = 3'h0;        // hold desc1
   parameter DESC2        = 3'h1;        // full tx_desc is valid, assert tx_req, tx_dfr
   parameter DATA_PHASE   = 3'h2;        // first dataphase is valid, assert tx_dv.  advance data phase until end of pkt
   parameter WAIT_FOR_ACK = 3'h3;        // no dataphase.  waiting for ack.
   parameter DROP_PKT     = 3'h4;        // follow pkt, but do not pass to core 
   parameter WAIT_NP_SEL_UPDATE = 3'h5;  // when pkt is from npbypass fifo, wait for tx credits to update the np select signal

   
   input         clk;  
   input         rstn;     
 
   input         pri_data_valid;        // means pri_data_in is current
   input[107:0]  pri_data_in;           // data from streaming interface
   input         tx_ack;                // from core.  grants tx_req
   input         tx_ws;                 // from core.  throttles dataphase
   input         ena_np_bypass;
   input         req_npbypass_pkt;   
   
   input         np_data_valid;
   input[107:0]  np_data_in;
   input         msi_busy;
   input         np_fifo_almostfull;
   
   output        np_data_ack; 
   
   output        pri_data_ack;      // accepts current data 
   output        tx_req;            // to core. tx request
   output        tx_dfr;            // to core. means there are more data cycles
   output        tx_dv;             // to core. means tx_dv is valid
   output[63:0]  tx_data;           // to core. tx data
   output[127:0] tx_desc;           // to core. tx descriptor
   output[7:0]   tx_be;             // not used
   output        tx_err;            // to core. indicates an error in tx_data
   output        tx_cpl_pending;    // to core. indicates that there is a completion still in progress
   output        tx_bridge_idle;    // indicates that this bridge is not processing a pkt 
   output        sending_np;
   output        sending_npd;   
 
   wire          tx_req;
   wire          tx_dfr;
   wire          tx_dv;
   wire [63:0]   tx_data;
   wire[127:0]   tx_desc;
   reg[63:0]     tx_desc_hi_r;     // registered version of high descriptor bytes
   reg[63:0]     tx_desc_lo_r;     // registered version of low descriptor bytes
   wire          pri_data_ack;     // fetches data from streaming interface
   wire          np_data_ack;
   wire          tx_err;
   wire          tx_cpl_pending; 
   reg           assert_req;       // asserts tx_req
   reg           assert_dfr;       // asserts tx_dfr
   reg           assert_dv;        // asserts tx_dv
   reg           tx_dfr_last;      // memorize last cycle of tx_dfr 
   reg           got_ack;          // indicates an ack was received for the last request
   reg[2:0]      bridge_sm;        // bridge state machine
   reg           tx_bridge_idle;   
   reg           np_bypass_mode; 
   reg           sending_np;
   reg           sending_npd;
   
   wire          sel_npbypass_fifo_c;
   reg           sel_npbypass_fifo_r;  
   wire[107:0]   muxed_data_in;
   wire          muxed_data_valid;
   wire[107:0]   muxed_sop_data_in;
   wire          muxed_sop_data_valid;
  reg[107:0]    muxed_sop_data_in_del;
    
   //--------------------------------------------
   // Generate Streaming interface ready signal
   // for throttling streaming data
   //--------------------------------------------
 
 
   assign pri_data_ack  =  ((sel_npbypass_fifo_c == 1'b0) &  ~(     
                            ((bridge_sm == DESC1) & pri_data_in[`STREAM_NP_SOP_FLAG] &  
													ena_np_bypass & np_fifo_almostfull) |
                           // ((bridge_sm == DESC1) & msi_busy) |                 // already accounted for in parent module
                            ((bridge_sm == DATA_PHASE)  & (tx_ws == 1'b1))  |     // in data phase.  fetch as long as core does not throttle 
					        (bridge_sm == WAIT_FOR_ACK)   )) ? 1'b1 : 1'b0;                  
						  
   assign np_data_ack  =  ((sel_npbypass_fifo_c == 1'b1) & ~(
                            ((bridge_sm == DESC1) & msi_busy) |                   // do not allow npbypass reads if SM does not advance
                            ((bridge_sm == DATA_PHASE)  & (tx_ws == 1'b1))  |     // in data phase.  fetch as long as core does not throttle 
					        (bridge_sm == WAIT_FOR_ACK)  |
							(bridge_sm == WAIT_NP_SEL_UPDATE))) ? 1'b1 : 1'b0; 
							
   //---------------------------------------------------------
   // Input Data Mux:  Primary Data Stream vs NPBypass Fifo 
   //---------------------------------------------------------     
   
   // select data from either primary data stream or from npbypass
   // fifo.  npbypass gets priority.  
   
   assign sel_npbypass_fifo_c = (bridge_sm == DESC1) ? req_npbypass_pkt : sel_npbypass_fifo_r;
   
   // for first descriptor phase, use sel_npbypass_fifo_c
   
   assign muxed_sop_data_in    = sel_npbypass_fifo_c ? np_data_in : pri_data_in;
   assign muxed_sop_data_valid = sel_npbypass_fifo_c ? np_data_valid : pri_data_valid;
   
   // for subsequent descriptor/data phases, use delayed version 
   // of sel_npbypass_fifo_c for performance
   
   assign muxed_data_in    = sel_npbypass_fifo_r ? np_data_in : pri_data_in;
   assign muxed_data_valid = sel_npbypass_fifo_r ? np_data_valid : pri_data_valid;

   //------------------------------------------------------- 
   // Generate Core Interface TX signals
   //    - extract multiplexed streaming interface  
   //      data onto non-multiplexed Core interface.
   //    - generate TX interface control signals
   //-------------------------------------------------------  
   
   assign tx_req           = assert_req;
   assign tx_dfr           = muxed_data_in[`STREAM_EOP] ? 1'b0 : assert_dfr ? 1'b1 : tx_dfr_last;   // assert dfr until last cycle of data
   assign tx_dv            = assert_dv;    
   assign tx_data          = muxed_data_in[`STREAM_DATA_BITS];      
   assign tx_be            = 8'h0;
   assign tx_err           = muxed_data_in[`STREAM_TX_ERR] & muxed_data_valid;
   assign tx_cpl_pending   = 1'b0;     
   assign tx_desc[127:64]  = tx_desc_hi_r;                                                            // hold descriptor high bytes at start of new pkt
   assign tx_desc[63:0]    = (bridge_sm == DESC2) ? muxed_data_in[`STREAM_DATA_BITS]: tx_desc_lo_r;   // hold descriptor low bytes on desc bus
   
   
   //----------------------------------------------
   // State machine manages the Core TX protocol
   // and generates signals for throttling data 
   // on the streaming interface.
   //----------------------------------------------
   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin 
	       bridge_sm           <= DESC1;
		   tx_dfr_last         <= 1'b0; 
		   assert_req          <= 1'b0;
		   assert_dfr          <= 1'b0;  
		   assert_dv           <= 1'b0;  
		   assert_dv           <= 1'b0;
		   tx_desc_hi_r        <= 64'h0;
		   tx_desc_lo_r        <= 64'h0;  
		   got_ack             <= 1'b0;
		   tx_bridge_idle      <= 1'b1; 
		   np_bypass_mode      <= 1'b0; 
		   sel_npbypass_fifo_r <= 1'b0;
		   np_bypass_mode      <= 1'b0;
		   sending_np            <= 1'b0;
		   sending_npd           <= 1'b0;
		   muxed_sop_data_in_del <= 108'h0;
	   end
	   else begin  
	       sel_npbypass_fifo_r <= sel_npbypass_fifo_c;	
	       tx_dfr_last         <= pri_data_valid ? tx_dfr : tx_dfr_last;       
		   got_ack             <= tx_ack ? 1'b1 : tx_req ? 1'b0 : got_ack;     // indicate if last request was acked 
		   muxed_sop_data_in_del <= muxed_sop_data_in;
		   
	       case (bridge_sm) 
		       DESC1: begin 
			       // wait for a start-of-pkt flag from the
				   // streaming interface
			       tx_bridge_idle <= 1'b1;
                   tx_desc_hi_r   <= muxed_sop_data_in[`STREAM_DATA_BITS];             // save the 1st phase of the descriptor (high bytes)
				   np_bypass_mode <= 1'b0;                                             // default
				   if (muxed_sop_data_valid & ~msi_busy) begin                      // MSI has priority.                                
                       if (pri_data_in[`STREAM_NP_SOP_FLAG] & ~req_npbypass_pkt & ena_np_bypass) begin  
					       // gaurantee that full NP req packet gets written to 
						   // npbypass fifo to prevent mid-pkt npbypass fifo 
						   // underrun conditions.
					       if (np_fifo_almostfull) begin 
				               bridge_sm       <= DESC1;
					           tx_bridge_idle  <= 1'b1; 
						   end
						   else begin
				               bridge_sm       <= DROP_PKT;
					           tx_bridge_idle  <= 1'b0; 
						   end
				       end  
				       else if (muxed_sop_data_in[`STREAM_SOP]) begin                   
				           assert_req      <= 1'b1;                                     // assert tx_req when 2nd phase of descritor is fetched.
				           assert_dfr      <= muxed_sop_data_in[62];                    // assert tx_dfr if the descriptor payload bit is set
					       bridge_sm       <= DESC2;       
					       tx_bridge_idle  <= 1'b0;  
						   np_bypass_mode  <= sel_npbypass_fifo_c;
				       end  
					end 
			   end
			   DESC2: begin  
			       // receiving descriptor phase2.   
				   // tx_req, tx_dfr are asserted.
				   // fetch first data phase and assert tx_dv if there is a dataphase. 
				   assert_req   <= 1'b1;                                                // assert request for 2 cycles (desc phase 2 and first data cycle)                                       
				   assert_dfr   <= muxed_data_in[`STREAM_EOP] ? 1'b0 : assert_dfr;      // hold tx_dfr until last packet cycle
				   bridge_sm    <= ~assert_dfr ? WAIT_FOR_ACK : DATA_PHASE;             // use payload bit instead of EOP.  possible edge condition if fifo throttles in this state.  if no data phase, then wait for ack.  else start dataphase while waiting for ack. 
				   sending_np     <= muxed_sop_data_in_del[`STREAM_NP_REQ_FLAG];        // assert on 2nd cycle tx_req at latest
				   sending_npd    <= muxed_sop_data_in_del[`STREAM_NP_WRREQ_FLAG];
				   tx_bridge_idle <= 1'b0; 
				   assert_dv      <= assert_dfr;                                        // fetch first data, and assert tx_dv on next cycle if there is a dataphase
				   tx_desc_lo_r   <= muxed_data_in[`STREAM_DATA_BITS];                  // hold desc phase 2 on non-multiplexed descriptor bus 
			   end
			   DATA_PHASE: begin    
			       // throttled data phase.
				   // first data phase is presented on non-multiplexed core bus. 
				   // subsequent data phases are throttled by tx_ws.
				   // advance data phase on tx_ws
			       assert_req <= tx_ack ? 1'b0 : assert_req;                                  // keep asserting request if not yet acked 
			       if (~tx_ws) begin                                                          // advance data phase on tx_ws
				       if (muxed_data_in[`STREAM_EOP]) begin                                      
				  	       bridge_sm <= (tx_ack | got_ack) ? DESC1 : WAIT_FOR_ACK;            // if end of data phase, and no ack yet, then wait for ack.  else, ok to start new pkt.
					   end
					   else begin
					       bridge_sm <= DATA_PHASE;                                           // stay here until end of dataphase
					   end
					   tx_bridge_idle <= muxed_data_in[`STREAM_EOP] & (tx_ack | got_ack);
					   assert_dfr     <= muxed_data_in[`STREAM_EOP] ? 1'b0 : assert_dfr; 
					   assert_dv      <= muxed_data_in[`STREAM_EOP] ? 1'b0 : assert_dv;  
				   end
			   end
			   WAIT_FOR_ACK: begin 
			       // in this state, there is no dataphase, or dataphase is done
				   // and request has not yet been acked.
				   // throttle streaming interface until request is acked.
				   assert_req <= tx_ack ? 1'b0 : assert_req;                              // keep asserting request if not yet acked 
				   if (tx_ack) begin 
					   bridge_sm <= np_bypass_mode ? WAIT_NP_SEL_UPDATE : DESC1;
				   end 
				     tx_bridge_idle <= tx_ack & ~np_bypass_mode;
			   end
			   DROP_PKT: begin 
			       bridge_sm      <= muxed_data_in[`STREAM_EOP] ? DESC1 : bridge_sm;
				   tx_bridge_idle <= muxed_data_in[`STREAM_EOP]; 
			   end
			   WAIT_NP_SEL_UPDATE: begin
			       // tx_credits are valid in this cycle 
				   // let sel_npbypass_fifo signal update before
				   // evaluating next pkt
			       bridge_sm      <= DESC1;
				   tx_bridge_idle <= 1'b1; 
			   end

		   endcase
	   end
   end   
    
endmodule
