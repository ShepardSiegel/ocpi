
           Core name: Xilinx Virtex-6 Integrated Block for PCI Express
           Version: 1.3 Rev 2
           Release Date: September 21, 2010


================================================================================

This document contains the following sections: 

1. Introduction
2. New Features
3. Resolved Issues
4. Known Issues 
5. Technical Support
6. Other Information
7. Core Release History
8. Legal Disclaimer
 
================================================================================
 
1. INTRODUCTION

For the most recent updates to the IP installation instructions for this core,
please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm


For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm


This file contains release notes for the Xilinx LogiCORE(TM) IP Virtex-6 
Integrated Block for PCI Express v1.3 solution. For the latest core updates, 
see the product page at:

   http://www.xilinx.com/products/ipcenter/V6_PCI_Express_Block.htm


2. NEW FEATURES  
 
   - ISE 12.3 software support. Rev 2
   - Virtex-6 Integrated Block for PCI Express Root Port support
   - Implementation support for 512 Bytes MPS configuration for the 8-lane Gen2
     product.
   - Implementation support for all part/packages for the 8-lane Gen2 product
   - Added support for 6VHX380T-FF1155-1.

 
3. RESOLVED ISSUES 

   - Link Training failure. Rev 2
     o CR 558043

     Issue resolved where link would not train or go to Gen2 speed on Cold boot
     on some systems.  Rev2

   - Virtex-6 GTXE1 Attribute Change for POWER_SAVE
     o CR 550490

     V6 GTX POWER_SAVE setting updated per IDS 12.2 requirements.

   - MMCM VCO changed from 500 MHz to 1000 MHz. Rev 1.
     o CR 543565

     The MMCM VC0 setting has been changed from 500 MHz to 1000 MHz due to
     new MMCM requirements

   - Fix for HDL compiler warnings. Rev 1.
     o CR 551390

     Issue resolved where HDL compiler warnings were issued during Core
     Generation

   - Disable Lane Reversal Setting for Endpoint Configuration. Rev 1.
     o CR 558536

     Disable Lane Reversal Attribute setting on the Integrated Block has been
     set to FALSE for Endpoint Configurations, per CES Errata.

   - Error in generating core from ISE New source Wizard
     o CR 517195

     Issue resolved where ProjNav would error out with a Tcl scripting error when
     attempting to generate the core from ISE New Source Wizard. 

   - Incorrect UCF path in implement.bat file
     o CR 523072

     Issue resolved where the relative path to UCF in implement.bat is incorrect,
     when design is generated and implemented on Windows operating systems.

   - BUFG driving MMCM clkin removed
     o CR 511334

     The BUFG driving the MMCM clkin was removed, to reduce the number of BUFGs
     used in the design.

   - Root Port operation now supported in this release.
     o CR 509679

     Support added for Root Port operation of the PCIe Integrated Block.

   - FIFO_LIMIT setting could cause throttling on Transaction Transmit interface
     for the 8-lane Gen2 operation only
     o CR 524324

     Issue resolved where the FIFO_LIMIT setting in the 8-lane Gen2 product
     was not high enough and could cause throttling on the Transaction transmit
     interface.

   - Incorrect cfg_trn_pending_n functionality
     o CR 524835

     Issue resolved where the cfg_trn_pending_n output of the core was inverted.

   - Implementation support for the 8-lane Gen2 product with 512 Bytes Max 
     Payload Size Configuration
     o CR 522979

     Implementation support is now available for the 8-lane Gen 2 product with
     512 Bytes Max Payload Size Configuration

   - Support for Non-default User Interface frequency when the Xilinx Development
     Board selected is "ML 605"
     o CR 522735

     Implementation support is now available for non-default User Interface
     frequency when the Xilinx Development Board selected is "ML 605".

   - Support for Programmed Power Management (PPM) state L1 for the 8-lane Gen2
     product
     o CR 522902

     Programmed Power Management (PPM) state L1 is now supported for the 8-lane
     Gen2 product

   - trn_reof_n assertion without a trn_rsof_n assertion on Receive Transaction
     Interface in the 8-lane Gen2 product, when receiving back-to-back
     Transactions.
     o CR 522593

     Issue resolved where trn_reof_n might assert without trn_rsof_n assertion
     if trn_rsrc_rdy_n were deasserted while a packet was being written into
     the internal FIFO.

   - Requirement added for trn_tsrc_dsc_n assertion to be accompanied by 
     trn_teof_n assertion in the 8-lane Gen2 product
     o CR 525136

     The 8-lane Gen2 product now requires trn_tsrc_dsc_n assertion to be 
     accompanied by trn_teof_n assertion.

   - Transmit Transaction interface lock-up in the 8-lane Gen2 product.
     o CR 525691

     Issue resolved where the Transmit Transaction interface locks up on an
     assertion of trn_teof_n, which is not qualified by trn_tsrc_rdy_n, in the
     8-lane Gen2 product.


4. KNOWN ISSUES 
   
   The following are known issues for v1.3 of this core at time of release:

   - Virtex-6 solutions are pending hardware validation.

   - trn_rnp_ok_n not supported in the 8-lane Gen2 Integrated Block 
     o CR 518631

     Use of trn_rnp_ok_n is not supported in the 8-lane Gen 2 Integrated Block 
     for PCI Express product.

     Workaround : None

   - Gen2 operation only supported with 250 MHz Reference Clock.
     o CR 522983

     Gen 2 operation is only supported with 250 MHz Reference Clock.

     Workaround : Use an external PLL to convert 100 MHz clock to 250 MHz. 
     Contact Xilinx Support.

   - VHDL example design / testbench not supported.
     o CR 510476

     VHDL example design and testbench are not supported in the 11.2 release

     Workaround : None. Planned release in 11.4.

  The most recent information, including known issues, workarounds, and 
  resolutions for this version is provided in the IP Release Notes Guide located at 

   http://www.xilinx.com/support/documentation/user_guides/xtp025.pdf

5. TECHNICAL SUPPORT 

   To obtain technical support, create a WebCase at www.xilinx.com/support.
   Questions are routed to a team with expertise using this product.  
     
   Xilinx provides technical support for use of this product when used
   according to the guidelines described in the core documentation, and
   cannot guarantee timing, functionality, or support of this product for
   designs that do not follow specified guidelines.


6. OTHER INFORMATION
   
   In this release, the only supported synthesis tool is XST. 
   Additionally, only Verilog simulation and example design files are provided.

7. CORE RELEASE HISTORY 

Date        By            Version      Description
================================================================================
09/21/2010  Xilinx, Inc.  1.3 Rev2      Update for Rev2 Patch
05/05/2010  Xilinx, Inc.  1.3 Rev1      Update for Rev1 Patch
09/16/2009  Xilinx, Inc.  1.3           11.3 support
06/24/2009  Xilinx, Inc.  1.2           11.2 support
04/24/2009  Xilinx, Inc.  1.1           Initial release (BETA)
================================================================================

8. Legal Disclaimer

(c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved. 

This file contains confidential and proprietary information
of Xilinx, Inc. and is protected under U.S. and
international copyright and other intellectual property
laws.

DISCLAIMER
This disclaimer is not a license and does not grant any
rights to the materials distributed herewith. Except as
otherwise provided in a valid license issued to you by
Xilinx, and to the maximum extent permitted by applicable
law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
(2) Xilinx shall not be liable (whether in contract or tort,
including negligence, or under any other theory of
liability) for any loss or damage of any kind or nature
related to, arising under or in connection with these
materials, including for any direct, or any indirect,
special, incidental, or consequential loss or damage
(including loss of data, profits, goodwill, or any type of
loss or damage suffered as a result of any action brought
by a third party) even if such damage or loss was
reasonably foreseeable or Xilinx had been advised of the
possibility of the same.

CRITICAL APPLICATIONS
Xilinx products are not designed or intended to be fail-
safe, or for use in any application requiring fail-safe
performance, such as life-support or safety devices or
systems, Class III medical devices, nuclear facilities,
applications related to the deployment of airbags, or any
other applications that could lead to death, personal
injury, or severe property or environmental damage
(individually and collectively, "Critical
Applications"). Customer assumes the sole risk and
liability of any use of Xilinx products in Critical
Applications, subject only to applicable laws and
regulations governing limitations on product liability.

THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
PART OF THIS FILE AT ALL TIMES.
