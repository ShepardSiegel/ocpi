
           Core name: Xilinx Virtex-6 Integrated Block for PCI Express
           Version: 1.7
           Release Date: March 01, 2011


================================================================================

This document contains the following sections:

1. Introduction
2. New Features
3. Supported Devices
4. Resolved Issues
5. Known Issues
6. Technical Support
7. Other Information
8. Core Release History
9. Legal Disclaimer

================================================================================

1. INTRODUCTION

For the most recent updates to the IP installation instructions for this core,
please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm


For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm


This file contains release notes for the Xilinx LogiCORE(TM) IP Virtex-6
Integrated Block for PCI Express v1.6 solution. For the latest core updates,
see the product page at:

   http://www.xilinx.com/products/ipcenter/V6_PCI_Express_Block.htm


2. NEW FEATURES

   - ISE 12.1 software support


3. SUPPORTED DEVICES

- Virtex-6 LXT
- Virtex-6 SXT
- Virtex-6 HXT
- Virtex-6 CXT
- Virtex-6 Lower Power
- QPro Virtex-6 Hi-Rel

4. RESOLVED ISSUES

   - BUFG added on TXOUTCLK to MMCM path
     o CR 579207

     BUFG added to TXOUTCLK path to the MMCM to workaround requirement of MMCM
     in same region as the PCI Express Integrated Block when the TXOUTCLK drives
     the MMCM input directly.

   - Core TxOutClk constraint added to UCF
     o CR 589216

     Constraint added to TxOutClk BUFG output as sys_clk constraint was not
     propagated correctly by tools.

   - Virtex-6 GTX Transceiver Delay Aligner Errata Work-around
     o CR 585954

     GTX transceiver settings have been updated to work around the Virtex-6 GTX
     Transceiver Delay Aligner Errata.

   - GTX Wrapper updated
     o CR 585171

     The GTX Wrapper updated per latest recommendations for GTX Transceiver for
     PCI Express.

   - Default Reference Clock Frequency updated
     o CR 585171

     The default reference clock frequency for Designs with Link Speed 5.0 Gb/s
     been changed from 250 MHz to 100 MHz.

   - PMA_RX_CFG attribute in GTX wrapper updated
     o CR 566981

     The PMA_RX_CFG attribute in the GTX wrapper has been udpated to be set 
     based on Synchronous or Asynchronous clocking selected (Slot Clock 
     selection).

   - Transaction Buffer Pipeline default setting for 8-lane Gen2 configuration
     o CR 572926

     The default setting for Transaction Buffer Pipeline for 8-lane Gen2 
     configurations has been updated to "Buffer Write and Read"

   - INTERRUPT_PIN attribute update based on Legacy Interrupt option in GUI
     o CR 581046

     Issue resolved where Unchecking the Legacy Interrupt option was not updating
     the INTERRUPT_PIN attribute.

   - trn_trem_n not connected in PIO_EP.vhd
     o CR 577673

     Issue resolved where trn_trem_n was not connected to trn_trem_n_int, in 
     PIO_EP.vhd, causing this output to not be driven.


5. KNOWN ISSUES

   The following are known issues for v1.7 of this core at time of release:

    5.1  Functional Issues


    5.2  Simulation Issues


    5.3  Implementation Issues


           - Timing Closure

            In order to obtain timing closure, designers may be required to use
            multiple PAR seeds and/or floorplanning. Using Multi-Pass Place and
            Route (MPPR), designers can try multiple cost tables in order to meet
            timing. Please see the Development System Reference Guide in the
            Software Manuals found at: http://www.xilinx.com/support/library.htm
            for more information on using MPPR. Designers may also have to
            floorplan and add advanced placement constraints for both their
            design and the core to meet timing.


  The most recent information, including known issues, workarounds, and
  resolutions for this version is provided in the IP Release Notes Guide located at

   http://www.xilinx.com/support/documentation/user_guides/xtp025.pdf

6. TECHNICAL SUPPORT

   To obtain technical support, create a WebCase at www.xilinx.com/support.
   Questions are routed to a team with expertise using this product.

   Xilinx provides technical support for use of this product when used
   according to the guidelines described in the core documentation, and
   cannot guarantee timing, functionality, or support of this product for
   designs that do not follow specified guidelines.


7. OTHER INFORMATION


8. CORE RELEASE HISTORY

Date        By            Version      Description
================================================================================
03/01/2011  Xilinx, Inc.  1.7           13.1 support
09/21/2010  Xilinx, Inc.  1.6           12.3 support
07/23/2010  Xilinx, Inc.  1.5 Rev 1     Patch Release
04/19/2010  Xilinx, Inc.  1.5           12.1 support
03/09/2010  Xilinx, Inc.  1.4 Rev 3     Patch Release
03/09/2010  Xilinx, Inc.  1.4 Rev 2     11.5 support
12/02/2009  Xilinx, Inc.  1.4 Rev 1     Patch Release
12/02/2009  Xilinx, Inc.  1.4           11.4 support
09/16/2009  Xilinx, Inc.  1.3           11.3 support
06/24/2009  Xilinx, Inc.  1.2           11.2 support
04/24/2009  Xilinx, Inc.  1.1           Initial release (BETA)
================================================================================

9. Legal Disclaimer

(c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.

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

