`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express BFM Request Interface Common Variables
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_req_intf_common.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module provides the common variables for passing the requests between the
// Read/Write Request package and ultimately the user's driver and the VC
// Interface Entitites
//-----------------------------------------------------------------------------
// Copyright (c) 2005 Altera Corporation. All rights reserved.  Altera products are
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

module altpcietb_bfm_req_intf_common(dummy_out) ;

`include "altpcietb_bfm_constants.v"
`include "altpcietb_bfm_log.v"
`include "altpcietb_bfm_req_intf.v"

   output      dummy_out;

// Contains the performance measurement information
   reg         [0:EBFM_NUM_VC-1] perf_req;
   reg         [0:EBFM_NUM_VC-1] perf_ack;
   integer     perf_tx_pkts[0:EBFM_NUM_VC-1];
   integer     perf_tx_qwords[0:EBFM_NUM_VC-1];
   integer     perf_rx_pkts[0:EBFM_NUM_VC-1];
   integer     perf_rx_qwords[0:EBFM_NUM_VC-1];
   integer     last_perf_timestamp;

   reg [192:0] req_info[0:EBFM_NUM_VC-1] ;
   reg         req_info_valid[0:EBFM_NUM_VC-1] ;
   reg         req_info_ack[0:EBFM_NUM_VC-1] ;

   reg         tag_busy[0:EBFM_NUM_TAG-1] ;
   reg [2:0]   tag_status[0:EBFM_NUM_TAG-1] ;
   reg         hnd_busy[0:EBFM_NUM_TAG-1] ;
   integer     tag_lcl_addr[0:EBFM_NUM_TAG-1] ;
   
   reg reset_in_progress ;
   integer bfm_max_payload_size ;
   integer bfm_ep_max_rd_req ;
   integer bfm_rp_max_rd_req ;
   // This variable holds the TC to VC mapping
   reg [23:0] tc2vc_map;

   integer    i ;
   
   initial
     begin
        for (i = 0; i < EBFM_NUM_VC; i = i + 1 )
          begin
             req_info[i]       = {193{1'b0}} ;
             req_info_valid[i] = 1'b0 ;
             req_info_ack[i]   = 1'b0 ;
             perf_req[i]       = 1'b0 ;
             perf_ack[i]       = 1'b0 ;
             perf_tx_pkts[i]   = 0 ;
             perf_tx_qwords[i] = 0 ;
             perf_rx_pkts[i]   = 0 ;
             perf_rx_qwords[i] = 0 ;
             last_perf_timestamp[i] = 0 ;
          end
        for (i = 0; i < EBFM_NUM_TAG; i = i + 1)
          begin
             tag_busy[i]     = 1'b0 ;
             tag_status[i]   = 3'b000 ;
             hnd_busy[i]     = 1'b0 ;
             tag_lcl_addr[i] = 0 ;
          end 
        reset_in_progress    = 1'b0 ;
        bfm_max_payload_size = 128 ;
        bfm_ep_max_rd_req    = 128 ;
        bfm_rp_max_rd_req    = 128 ;
        tc2vc_map            = 24'h000000 ;        
     end
endmodule // altpcietb_bfm_req_intf_common
