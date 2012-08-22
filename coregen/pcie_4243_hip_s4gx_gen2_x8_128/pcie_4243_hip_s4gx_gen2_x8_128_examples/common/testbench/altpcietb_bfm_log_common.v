`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express BFM Message Logging Common Variable File 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_log_common.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This module is not intended to be instantiated by rather referenced by an
// absolute path from the altpcietb_bfm_log.v include file. This allows all
// users of altpcietb_bfm_log.v to see a common set of values. 
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

module altpcietb_bfm_log_common(dummy_out) ;
output dummy_out;

   `include "altpcietb_bfm_log.v" 

   integer log_file ;

   reg [EBFM_MSG_ERROR_CONTINUE:EBFM_MSG_DEBUG] suppressed_msg_mask ;
   
   reg [EBFM_MSG_ERROR_CONTINUE:EBFM_MSG_DEBUG] stop_on_msg_mask ;

   initial
     begin
        suppressed_msg_mask = {EBFM_MSG_ERROR_CONTINUE-EBFM_MSG_DEBUG+1{1'b0}} ;
        suppressed_msg_mask[EBFM_MSG_DEBUG] = 1'b1 ;
        stop_on_msg_mask    = {EBFM_MSG_ERROR_CONTINUE-EBFM_MSG_DEBUG+1{1'b0}} ;
     end
endmodule // altpcietb_bfm_log_common
