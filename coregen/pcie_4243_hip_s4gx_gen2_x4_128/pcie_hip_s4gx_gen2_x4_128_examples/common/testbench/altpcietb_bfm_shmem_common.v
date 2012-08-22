`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express BFM Shmem Module
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_shmem_common.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// Implements the common shared memory array
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
module altpcietb_bfm_shmem_common(dummy_out) ;

`include "altpcietb_bfm_constants.v"
`include "altpcietb_bfm_log.v"
`include "altpcietb_bfm_shmem.v"
output dummy_out;
   reg [7:0] shmem[0:SHMEM_SIZE-1] ;
   
   // Protection Bit for the Shared Memory
   // This bit protects critical data in Shared Memory from being overwritten.
   // Critical data includes things like the BAR table that maps BAR numbers to addresses.
   // Deassert this bit to REMOVE protection of the CRITICAL data.
   reg protect_bfm_shmem;

   initial
     begin
        shmem_fill(0,SHMEM_FILL_ZERO,SHMEM_SIZE,{64{1'b0}}) ;
        protect_bfm_shmem = 1'b1;
     end

endmodule // altpcietb_bfm_shmem_common
