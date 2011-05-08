   //-----------------------------------------------------------------------------
   // Title         : PCI Express BFM Root Constants Package
   // Project       : PCI Express MegaCore function
   //-----------------------------------------------------------------------------
   // File          : altpcie_bfm_constants.v
   // Author        : Altera Corporation
   //-----------------------------------------------------------------------------
   // Description :
   // This entity provides the BFM with global constants 
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

   // Root Port Primary Side Bus Number and Device Number
   parameter [7:0] RP_PRI_BUS_NUM = 8'h00 ; 
   parameter [4:0] RP_PRI_DEV_NUM = 5'b00000 ; 
   // Root Port Requester ID
   parameter[15:0] RP_REQ_ID = {RP_PRI_BUS_NUM, RP_PRI_DEV_NUM , 3'b000}; // used in the Requests sent out
   // 2MB of memory
   parameter SHMEM_ADDR_WIDTH = 21; 
   // The first section of the PCI Express I/O Space will be reserved for
   // addressing the Root Port's Shared Memory. PCI Express I/O Initiators
   // would use an I/O address in this range to access the shared memory.
   // Likewise the first section of the PCI Express Memory Space will be
   // reserved for accessing the Root Port's Shared Memory. PCI Express
   // Memory Initiators will use this range to access this memory.
   // These values here set the range that can be used to assign the
   // EP BARs to. 
   parameter[31:0] EBFM_BAR_IO_MIN = 32'b1 << SHMEM_ADDR_WIDTH ; 
   parameter[31:0] EBFM_BAR_IO_MAX = {32{1'b1}}; 
   parameter[31:0] EBFM_BAR_M32_MIN = 32'b1 << SHMEM_ADDR_WIDTH ; 
   parameter[31:0] EBFM_BAR_M32_MAX = {32{1'b1}}; 
   parameter[63:0] EBFM_BAR_M64_MIN = 64'h0000000100000000 ; 
   parameter[63:0] EBFM_BAR_M64_MAX = {64{1'b1}}; 
   parameter EBFM_NUM_VC = 4; // Number of VC's implemented in the Root Port BFM
   parameter EBFM_NUM_TAG = 32; // Number of TAG's used by Root Port BFM
 
