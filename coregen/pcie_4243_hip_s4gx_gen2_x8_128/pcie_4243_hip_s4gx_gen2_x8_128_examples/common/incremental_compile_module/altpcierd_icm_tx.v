// synthesis verilog_version verilog_2001
`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_icm_tx.v
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
 
module altpcierd_icm_tx  #( 
                parameter TXCRED_WIDTH = 22 
			   )       (clk, rstn, 
                        tx_req, tx_ack, tx_desc, tx_data, tx_ws, tx_dv, tx_dfr, tx_be,
						tx_err, tx_cpl_pending, tx_cred_int, 
						tx_npcredh, tx_npcredd, tx_npcredh_infinite, tx_npcredd_infinite,
						app_msi_ack, app_msi_req, app_msi_num, app_msi_tc,
				        stream_ready, stream_valid, stream_data_in,
						stream_msi_ready, stream_msi_valid, stream_msi_data_in,
						tx_mask, tx_cred);
 

   input         clk;  
   input         rstn;     
   input[TXCRED_WIDTH-1:0]   tx_cred_int;           // from core.
   input[7:0]    tx_npcredh;            // from core.
   input[11:0]   tx_npcredd;            // from core.
   input         tx_npcredh_infinite;   // from core.
   input         tx_npcredd_infinite;   // from core.
   input         tx_ack;                // from core.  TX request ack
   input         tx_ws;                 // from core.  TX dataphase throttle
   input         app_msi_ack;           // from core.  MSI request ack

   output        tx_req;                // to core.  TX request
   output[127:0] tx_desc;               // to core.  TX pkt descriptor
   output[63:0]  tx_data;               // to core.  TX pkt payload data
   output        tx_dv;                 // to core.  TX dv contol
   output        tx_dfr;                // to core.  TX dfr contol
   output[7:0]   tx_be;                 // to core.  TX byte enabel -- not used
   output        tx_cpl_pending;        // to core.  TX completion pending status
   output        tx_err;                // to core.  TX error status
   output[TXCRED_WIDTH-1:0]  tx_cred;               // to app.
   
   output        app_msi_req;           // to core.  MSI request.
   output[4:0]   app_msi_num;           // to core.  MSI msi num bits.
   output[2:0]   app_msi_tc;            // to core.  MSI TC bits.

   input         stream_valid;          // indicates stream_data_in is valid
   input[107:0]  stream_data_in;        // data from TX streaming interface   
   output        stream_ready;          // throttles data on TX streaming interface  
   output        tx_mask;               // to app.  masks nonposted requests
   
   input         stream_msi_valid;      // indicates msi_data_in is valid
   input[7:0]    stream_msi_data_in;    // data from MSI streaming interface      
   output        stream_msi_ready;      // throttles data on MSI streaming interface   
   
   reg           stream_ready;    
   reg[107:0]    stream_data_in_del;    // input boundary reg
   reg           stream_valid_del;      // input boundary reg
   reg           stream_msi_valid_del;  // input boundary reg
   reg           stream_msi_ready;   

   // Fifo 
   wire          fifo_empty;            // indicates fifo is full
   wire          tx_fifo_almostfull;       // indicates fifo is almost full.  
   wire          msi_fifo_almostfull;       // indicates fifo is almost full. 
   wire          fifo_wr;               // fifo write control
   wire          fifo_rd;               // fifo read control
   wire[107:0]   fifo_wrdata;           // fifo write data
   wire[107:0]   fifo_rddata;           // fifo read data
    
   wire          msi_data_ack;           // Fifo throttle control from MSI bridge
   wire          tx_data_ack;            // Fifo throttle control from TX bridge  
   wire          tx_bridge_idle;        // indicates that there is no TX port packet in progress. for TX/MSI throttle arbitration. 
   
   wire          stream_npreq_flag;     // flag indicating that the current pkt is a non-posted req
   wire          stream_npwrreq_flag;   // flag indicating that the current pkt is a non-posted write req
   reg           stream_npreq_flag_r;
   reg           stream_npwrreq_flag_r; 
   wire          stream_npreq_sop_flag;
   wire          stream_type_is_np;
   wire          stream_type_is_npwr;
   
   wire[107:0]    tx_fifo_rddata;
   wire[107:0]    msi_fifo_rddata;
   wire           fifo_data_valid;
   wire           throttle;
   wire[84:0]     stream_dataindel_84_to_0;
   
   wire[TXCRED_WIDTH-1:0]     tx_cred;
   wire[65:0]     unused_vec;  
   wire           msi_busy; 
   wire           msi_data_valid;
   reg            fifo_empty_or_rd_del;
   reg            fifo_rd_del;
   reg[107:0]     fifo_wrdata_masked; 
   
   assign unused_vec = 66'h0; 
   
   assign tx_cred = tx_cred_int;        // pass straight thru from core to app
   
   //-----------------------------------------------------------
   // Streaming Interface input pipe stage
   // NOTE:  This is an incremental compile register boundary.  
   //        No combinational logic is allowed on the input
   //        to these registers.
   //------------------------------------------------------------ 
   
   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
           stream_data_in_del    <= 108'h0;
		   stream_valid_del      <= 1'b0; 
		   stream_msi_valid_del  <= 1'b0;
		   stream_npreq_flag_r   <= 1'b0;
		   stream_npwrreq_flag_r <= 1'b0; 
	   end
	   else begin
	       stream_data_in_del[107:85]              <= 23'h0;
	       stream_data_in_del[`STREAM_TX_IF]       <= stream_data_in[`STREAM_TX_IF];
		   stream_data_in_del[`STREAM_APP_MSI_NUM] <= stream_msi_data_in[4:0];
		   stream_data_in_del[`STREAM_MSI_TC]      <= stream_msi_data_in[7:5];
		   stream_data_in_del[`STREAM_MSI_VALID]   <= stream_msi_valid;                  // indicate when there is a valid msi data
		   stream_valid_del                        <= stream_valid;
		   stream_msi_valid_del                    <= stream_msi_valid;                  // write whenever there is data on the tx chan or on the msi chan
		   stream_npreq_flag_r                     <= stream_npreq_flag;
		   stream_npwrreq_flag_r                   <= stream_npwrreq_flag;
	   end
   end
   
   // Generate NP decoding flags
   assign stream_type_is_np   = ((stream_data_in_del[60:59]==2'h0) &  
                                (((stream_data_in_del[58:56]==3'h2) | (stream_data_in_del[58:56]==3'h4) | (stream_data_in_del[58:56]==3'h5)) |   // IO, ConfigType0, ConfigType1
								 ((stream_data_in_del[58:57]== 2'h0) & (stream_data_in_del[62]== 1'b0)))) ? 1'b1 : 1'b0;                         // MemRead, MemReadLocked
		
   assign stream_npreq_flag   = (stream_data_in_del[`STREAM_SOP] & stream_valid_del) ? stream_type_is_np: stream_npreq_flag_r;   
 
   assign stream_type_is_npwr = ((stream_data_in_del[60:59]==2'h0) & (stream_data_in_del[62]==1'b1) & ((stream_data_in_del[58:56]==3'h2) | (stream_data_in_del[58:56]==3'h4) | (stream_data_in_del[58:56]==3'h5))) ? 1'b1 : 1'b0;

   assign stream_npwrreq_flag = (stream_data_in_del[`STREAM_SOP] & stream_valid_del) ?  stream_type_is_npwr : stream_npwrreq_flag_r;   

   assign stream_npreq_sop_flag = (((stream_data_in_del[`STREAM_SOP]==1'b1) & (stream_valid_del==1'b1)) & ((stream_data_in_del[60:59]==2'h0) &  
                                (((stream_data_in_del[58:56]==3'h2) | (stream_data_in_del[58:56]==3'h4) | (stream_data_in_del[58:56]==3'h5)) |   // IO, ConfigType0, ConfigType1
								 ((stream_data_in_del[58:57]== 2'h0) & (stream_data_in_del[62]== 1'b0))))) ? 1'b1 : 1'b0;
   
   //-------------------------------------------------
   // Streaming Interface output pipe stage
   //-------------------------------------------------

   always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin 
		   stream_ready     <= 1'b0;
		   stream_msi_ready <= 1'b0;
	   end
	   else begin 
		   stream_ready     <= ~tx_fifo_almostfull;
		   stream_msi_ready <= ~msi_fifo_almostfull;
	   end
   end
    
   
   //--------------------------------------------------
   // Avalon Sink Fifo
   // Buffers the data from the Streaming Interface
   // Data from TX and MSI Streaming interfaces are
   // held in the same FIFO in order to maintain 
   // pkt ordering between these ports.
   //--------------------------------------------------
   
   assign stream_dataindel_84_to_0 = stream_data_in_del[84:0];
   assign fifo_wrdata              = {20'h0, stream_npreq_flag, stream_npwrreq_flag, stream_npreq_sop_flag, stream_dataindel_84_to_0};
   
   // MSI & TX data share a fifo.  
   // mask out data if no valid present.
   always @ (*) begin
       fifo_wrdata_masked                      = 108'h0;  // default.  override with following
       fifo_wrdata_masked[`STREAM_TX_IF]       = fifo_wrdata[`STREAM_TX_IF]       & {76{stream_valid_del}};
       fifo_wrdata_masked[`STREAM_MSI_IF]      = fifo_wrdata[`STREAM_MSI_IF]      & {9{stream_msi_valid_del}};
       fifo_wrdata_masked[`STREAM_NP_FLAG_VEC] = fifo_wrdata[`STREAM_NP_FLAG_VEC] & {3{stream_valid_del}};
   end
   
   altpcierd_icm_fifo_lkahd    #( 
       .RAMTYPE  ("RAM_BLOCK_TYPE=AUTO")
      )tx_fifo_131x4( 
                           .clock        (clk),
                           .aclr         (~rstn),
                           .data         (fifo_wrdata_masked),
						   .wrreq        (stream_valid_del | stream_msi_valid_del),
						   .rdreq        (fifo_rd),
						   .q            (tx_fifo_rddata),
						   .full         ( ),
						   .almost_full  (tx_fifo_almostfull),
						   .almost_empty ( ), 
						   .empty        (fifo_empty));
						    
/* 
 defparam tx_fifo_131x4.RAMTYPE = "RAM_BLOCK_TYPE=AUTO";
   altpcierd_icm_fifo_lkahd msi_fifo_131x4( 
                           .clock        (clk),
                           .aclr         (~rstn),
                           .data         (stream_data_in_del),
						   .wrreq        (stream_valid_del | stream_msi_valid_del),
						   .rdreq        (fifo_rd),
						   .q            (msi_fifo_rddata),
						   .full         ( ),
						   .almost_full  (msi_fifo_almostfull),
						   .almost_empty ( ), 
						   .empty        ( ));
*/ 
 
   assign msi_fifo_almostfull = tx_fifo_almostfull;
   assign msi_fifo_rddata     = tx_fifo_rddata;
 
   //-------------------------------------------------
   // Core Interface
   // Data from streaming interface goes to 
   // Core's TX Data Port and Core's MSI interface
   // Both interfaces throttle the FIFO data.
   //-------------------------------------------------
 
   assign fifo_data_valid = ~fifo_empty;
   
   // FIFO read controls.
   // tx channel throttling is allowed to override msi channel throttle. 
   // since an entire msi transaction fits in one clock cycle,
   // tx channel will not inadvertantly interrupt an msi in progress.
   // however, since tx channel pkts require multiple fifo entries, 
   // msi is only allowed to throttle the fifo if no tx pkt is in progress.  
   
  // assign fifo_rd = tx_data_ack & (msi_data_ack | ~tx_bridge_idle);   
     assign throttle = ~tx_data_ack | (~msi_data_ack & tx_bridge_idle);
     assign fifo_rd  = ~throttle & ~fifo_empty;
	 
	 assign msi_busy    = ~msi_data_ack; 

     always @ (posedge clk or negedge rstn) begin
       if (~rstn) begin
	       fifo_empty_or_rd_del <= 1'b1;
	       fifo_rd_del    <= 1'b0; 
	   end
	   else begin
	       fifo_empty_or_rd_del <= fifo_empty | fifo_rd;
	       fifo_rd_del    <=  fifo_rd;
	   end
     end
	 
	 assign msi_data_valid = ~fifo_empty & fifo_empty_or_rd_del;
 
     altpcierd_icm_txbridge_withbypass   #( 
         .TXCRED_WIDTH  (TXCRED_WIDTH)
       ) altpcierd_icm_txbridge_withbypass(
         .clk(clk), .rstn(rstn), 
         .tx_req(tx_req), .tx_ack(tx_ack), .tx_desc(tx_desc), .tx_data(tx_data), .tx_ws(tx_ws), .tx_dv(tx_dv), .tx_dfr(tx_dfr), .tx_be(tx_be),
	     .tx_err(tx_err), .tx_cpl_pending(tx_cpl_pending), .tx_cred(unused_vec),
	     .tx_npcredh(tx_npcredh), .tx_npcredd(tx_npcredd), .tx_npcredh_infinite(tx_npcredh_infinite), .tx_npcredd_infinite(tx_npcredd_infinite),
	     .data_ack(tx_data_ack), .data_valid(fifo_data_valid), .data_in(tx_fifo_rddata), .tx_bridge_idle(tx_bridge_idle), .tx_mask(tx_mask),
		 .msi_busy(msi_busy), .tx_fifo_rd(fifo_rd));
		 
   
     // Bridge to the Core MSI Interface  
	 // NOTE:  The msibridge may not support multiple MSI requests if they 
	 //        all coincide with a single TLP request
     altpcierd_icm_msibridge  altpcierd_icm_msibridge (
       .clk(clk), .rstn(rstn), 
       .data_valid(msi_data_valid), .data_in(msi_fifo_rddata), .data_ack(msi_data_ack), 
	   .msi_ack(app_msi_ack), .msi_req(app_msi_req), . msi_num(app_msi_num), .msi_tc(app_msi_tc));


endmodule
