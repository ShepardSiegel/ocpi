// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_rxbridge.v
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
	   
module altpcierd_icm_rxbridge (clk, rstn, 
                             rx_req, rx_ack, rx_desc, rx_data, rx_be, 
				             rx_ws, rx_dv, rx_dfr, rx_abort, rx_retry, rx_mask, 
				             stream_ready, stream_wr, stream_wrdata );
							 
 

   
   
   
   input         clk;  
   input         rstn;    
   input         rx_req;              // core pkt request 
   input[135:0]  rx_desc;             // core pkt descriptor
   input[63:0]   rx_data;             // core payload data
   input[7:0]    rx_be;               // core byte enable bits
   input         rx_dv;               // core rx_data is valid
   input         rx_dfr;              // core has more data cycles
   input         stream_ready;         // means streaming interface can accept more data
   
   output        rx_ack;              // core rx_ack handshake
   output        rx_abort;            // core rx_abort handshake 
   output        rx_retry;            // core rx_retry handshake
   output        rx_ws;               // core data throttling
   output        rx_mask;             // core rx_mask handshake
   output        stream_wr;         // means stream_wrdata is valid
   output[107:0] stream_wrdata;   
   
   //USER DEFINED PARAMETER. 
   parameter DROP_MESSAGE = 1'b1;      // when 1'b1, the bridge acks messages from the core, then drops them.  
                                       // when 1'b0, the bridge acks messages from the core, and passes them to the streaming interface.
   // bridge_sm states
   parameter STREAM_DESC1   = 2'h0;    // write hi descriptor to streaming interface
   parameter STREAM_DESC2   = 2'h1;    // write lo descriptor to streaming interface  
   parameter STREAM_DATA    = 2'h2;    // write dataphase to streaming interface  
   parameter DEFERRED_CYCLE = 2'h3;    // write last data cycle to streaming interface if in deferred mode 
   
   wire          rx_abort;            
   wire          rx_retry;            
   wire          rx_mask;             
   wire[107:0]   stream_wrdata;       
   wire          stream_wr;         
   wire          start_of_pkt_flag;     // menas this cycle is the first of the transfer (always desc phase 1)
   wire          end_of_pkt_flag;       // means this cycle is the last of the transfer
   reg           has_payload;           // means this transfer contains data cycles
   wire[63:0]    muxed_stream_wrdata;     // mulitplexed desc/data bus data to be written to be transferred
   wire[7:0]     muxed_bar_bits;        // multiplexed desc/data bus byte_ena/bar field to be transferred 
   reg[7:0]      rx_be_last;           // byte enable bits from last cycle.  for deferred mode.  
   reg[63:0]     rx_data_last;         // payload data from last cycle.  for deferred mode.
   reg           defer_data_cycle;      // when data phase coincides with descriptor phase, defer writing it to the fifo until after desc phase is written.
   wire[7:0]     muxed_rx_be;          // byte enable bits to be muxed onto muxed_bar_bits
   reg[1:0]      bridge_sm;             // bridge state machine. controls data throttling on both streaming and core interfaces
   reg           enable_desc1;          // selects high descriptor bytes for streaming interface data
   reg           enable_desc2;          // selects low descriptor bytes for streaming interface data 
   reg           write_streaming_data;  // writes data to streaming interface
   reg           stream_deferred_data;  // means data payload is streamed in deferred mode
   wire          rx_ack;              
   wire          rx_ws;
   reg           last_deferred_cycle;   // means current cycle is the last deferred data cycle
   reg           enable_core_dataphase; // allows bridge to accept payload data from core
   reg           filter_out_msg;        // if tlp is a message, ack it, and drop it.  do not pass to streaming interface.  active only if user parameter DROP_MESSAGE is true.
   wire          filter_out_msg_n;
   wire          type_is_message;  
   wire          type_is_message_mem;
   reg           type_is_message_mem_r;
   wire[2:0]     rxdesc_type_field; 
   
   // core signals not supported 
   assign rx_abort = 1'b0;
   assign rx_mask  = 1'b0;
   assign rx_retry = 1'b0; 
   
   
   
   //----------------------------------------------------------------------
   // Generate streaming interface output signals
   //----------------------------------------------------------------------
   assign stream_wrdata[`STREAM_DATA_BITS]    = muxed_stream_wrdata;
   assign stream_wrdata[`STREAM_BAR_BITS]     = muxed_bar_bits;
   assign stream_wrdata[`STREAM_BYTEENA_BITS] = muxed_rx_be;
   assign stream_wrdata[`STREAM_SOP]          = start_of_pkt_flag;
   assign stream_wrdata[`STREAM_EOP]          = end_of_pkt_flag;   
   
   // write descriptor phase and data phase when streaming interface 
   // can accept data (stream_ready), and if not filtering out a message.
   // rx state machine advances on stream_ready
   assign rxdesc_type_field = rx_desc[125:123]; 
   assign type_is_message   = (rxdesc_type_field == 3'b110) ? 1'b1 : 1'b0;  
   assign type_is_message_mem = rx_req ? type_is_message : type_is_message_mem_r;
   assign filter_out_msg_n  = type_is_message_mem & DROP_MESSAGE;
   assign stream_wr         = stream_ready & (rx_req | write_streaming_data) & ~filter_out_msg_n;  
   
   assign start_of_pkt_flag = rx_req & enable_desc1;
   assign end_of_pkt_flag   = (write_streaming_data & ~stream_deferred_data & ~rx_dfr) | last_deferred_cycle;
   
   assign muxed_stream_wrdata = stream_deferred_data ? rx_data_last    :   // data phase with cycle stealing - deferred cycle has priority over any new rx_req
                              enable_desc1           ? rx_desc[127:64] :   // first descriptor phase
                              enable_desc2           ? rx_desc[63:0]   :   // second descriptor phase 
                              rx_data;                                     // data phase without cycle stealing (write_streaming_data)
							         
   assign muxed_rx_be =  stream_deferred_data ? rx_be_last :  // data phase with cycle stealing
                          rx_be;                               // data phase without cycle stealing     
    
  // assign muxed_bar_bits = (enable_desc1 | enable_desc2) ? rx_desc[135:128] : muxed_rx_be;  // bar bits are valid on desc2.  // UNMULTIPLEX THIS 
   assign muxed_bar_bits = rx_desc[135:128];  // bar bits are valid on desc2.   
   
   //------------------------------------------------------------------------
   // Generate Core handshaking/data-throttle signals
   //------------------------------------------------------------------------ 
   assign rx_ws  = ~(enable_core_dataphase & stream_ready & rx_dv);
   assign rx_ack = enable_desc2 & stream_ready;
   
   
   //------------------------------------------------------------------------
   // Generate control signals for
   //    - multiplexing desc/data from the core onto the streaming i/f
   //    - handshaking/throttling the core interface
   //
   // Throttling of the core is driven by the streaming interface 'ready'
   // signal.  Advance the core and the streaming interface on 'stream_ready'.
   //------------------------------------------------------------------------
   always @(negedge rstn or posedge clk) begin
      if (rstn == 1'b0) begin  
	      bridge_sm             <= STREAM_DESC1;
		  enable_desc1          <= 1'b1;
		  enable_desc2          <= 1'b0;
		  write_streaming_data  <= 1'b0;
		  stream_deferred_data  <= 1'b0;
		  has_payload           <= 1'b0; 
		  last_deferred_cycle   <= 1'b0;
		  rx_data_last         <= 64'h0;
		  rx_be_last           <= 8'h0; 	
		  enable_core_dataphase <= 1'b0;
		  filter_out_msg        <= 1'b0; 
		  type_is_message_mem_r <= 1'b0;
		  defer_data_cycle      <= 1'b0; 
      end
      else begin  
	      type_is_message_mem_r <= type_is_message_mem;
		  
	      if (stream_ready) begin                                    // advance data transfer on stream_ready
		      rx_data_last <= rx_data;
		      rx_be_last   <= rx_be; 
	          case (bridge_sm) 
		          STREAM_DESC1: begin
				      // wait for rx_req from core
					  // when received, put desc1 on streaming interface
			          if (rx_req) begin
			    	      enable_desc1          <= 1'b0;
			    	      enable_desc2          <= 1'b1;             // on next cycle, put desc2 on multiplexed streaming bus
			    		  has_payload           <= rx_desc[126];     // pkt has payload
			    		  bridge_sm             <= STREAM_DESC2;            
						  last_deferred_cycle   <= ~rx_desc[126];                            // next cycle is last if there is no payload
						  enable_core_dataphase <= rx_desc[126];                             // allow core dataphase to advance
						  filter_out_msg        <= filter_out_msg_n;
			    	  end
			      end
			      STREAM_DESC2: begin
				     // put desc2 on streaming interface
					 // if first dataphase coincides with desc2, 
					 // hold the core data and write to streaming i/f
					 // on the next ready cycle.
				     enable_desc2     <= 1'b0;             
			         defer_data_cycle <= rx_dv;                     // if receiving data at the same time as desc phase 2, hold data to transmit on streaming on next clk
			         if (~rx_dfr & rx_dv) begin                    // single data phase pkt 
						  last_deferred_cycle   <= 1'b1;             // indicate that this is the last data cycle for the pkt
			    	      bridge_sm             <= DEFERRED_CYCLE;   // receiving last dataphase from core. finish sending last data cycle.
						  write_streaming_data  <= ~filter_out_msg;  // write desc2 to        
						  stream_deferred_data  <= 1;                // hold rx_data and write to streaming i/f on next clk cycle.  currently writing desc2
						  enable_core_dataphase <= 1'b0;             // core dataphase is done.  do not read any more data from core while finishing transfer to streaming interface
			    	 end
			    	 else if (has_payload) begin                     // multi-cycle data payload
			    	      bridge_sm             <= STREAM_DATA;   
						  write_streaming_data  <= ~filter_out_msg;  // on next cycle, write dataphase to streaming interface
						  stream_deferred_data  <= rx_dv;           // hold rx_data and write to streaming i/f on next clk cycle.  currently writing desc2
						  enable_core_dataphase <= 1'b1;             // core dataphase is not done.  continue to accept data from core. 
			    	 end
					 else begin                                      // no payload in pkt
			    	      bridge_sm             <= STREAM_DESC1;     // wait for new pkt
						  enable_desc1          <= 1'b1;           
						  enable_core_dataphase <= 1'b0;             
						  last_deferred_cycle   <= 1'b0;
					 end
			      end
			      STREAM_DATA: begin 
				     // accept data from the core interface,
					 // and transfer to the streaming interface 
					 // until the end of the core dataphase is recieved. 
			         if (~rx_dfr & rx_dv) begin
			    	     // last data cycle
			    	     bridge_sm             <= defer_data_cycle ? DEFERRED_CYCLE : STREAM_DESC1; // finish sending last data cycle on streaming interface if required.
						 last_deferred_cycle   <= defer_data_cycle ? 1'b1 : 1'b0;                   // next cycle is the last deferred data cycle
						 enable_desc1          <= defer_data_cycle ? 1'b0 : 1'b1;            
						 enable_desc2          <= 1'b0;
						 write_streaming_data  <= defer_data_cycle ? ~filter_out_msg : 1'b0;        // if in deferred mode, write data on the next cycle to the streaming interface
						 enable_core_dataphase <= 1'b0;                                             // do not accept any more data from the core
			         end
			      end
			      DEFERRED_CYCLE: begin
				     // stream the last data cycle of deferred mode
			         bridge_sm             <= STREAM_DESC1;
					 enable_desc1          <= 1'b1;
					 enable_desc2          <= 1'b0;
					 write_streaming_data  <= 1'b0;
					 stream_deferred_data  <= 1'b0;
					 last_deferred_cycle   <= 1'b0;
					 enable_core_dataphase <= 1'b0;
			      end
			  endcase
		 end
      end			 
	end	  
 
endmodule
