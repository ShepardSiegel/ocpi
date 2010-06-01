

	Core Name: Xilinx LogiCORE Endpoint Block Plus for PCI Express(R)
	Version: 1.13
	Release Date: December 02, 2009


===============================================================================

This document contains the following sections:

1. Introduction
2. New Features
3. Resolved Issues
4. Known Issues
5. Technical Support
6. Other Information
7. Core Release History
8. Legal Disclaimer

===============================================================================

1. INTRODUCTION

For the most recent updates to the IP installation instructions for this core,
please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm

For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm

This file contains release notes for the Xilinx LogiCORE IP Endpoint Block Plus
for PCI Express v1.13 solution. For the latest core updates, see the product 
page at:

http://www.xilinx.com/products/ipcenter/V5_PCI_Express_Block_Plus.htm

For information on how to set up and use the core, please refer to the LogiCORE
IP Endpoint Block Plus for PCI Express Getting Started Guide.  More 
comprehensive user information is available in the LogiCORE IP Endpoint Block 
Plus for PCI Express User Guide.


2. New Features

   - ISE 11.4 software support
   - Synplify support added
   - SX240T support added

3. Resolved Issues

   - Un-checking TX_DIFF_BOOST checkbox causes core generation failure
      o CR 530800

      Issue resolved where Un-checking the TX_DIFF_BOOST checkbox, during the 
      Core customization process was causing the Core generation to fail.

   - ISE Proj Nav flow
      o CR 529525

      Issue resolved where `defines for module names have been removed from the
       Example design delivered with the core, as this was not compatible with 
      the ISE Proj Nav flow.

   - XCF Files delivered
      o CR 537266

      Issue resolved where XCF files were not delivered with the core. This 
      caused difficulty in timing closure.

   - implement_dual.bat now delivered
      o CR 483369

      The implement_dual.bat script is now delivered.

   - trn_rnp_ok_n deassertion causing Posted & Completion transactions to stall
      o CR 536473

      Issue resolved where trn_rnp_ok_n deassertion for an extended period of 
      time caused Posted & Completion transactions to stall.

   - Polarity reversal on Lane 7 not detected.
      o CR 532483

      Issue resolved where the core was not detecting Polarity reversal on 
      Lane 7, in a 8-lane product.

   - Core Transmit interface lock up after warm reset
      o CR 529523

      Issue resolved where the core transaction transmit interface would lock up
      after a warm reset due to the Calendar logic's failure to capture initial 
      data correctly.

   - Synplify support now available
      o CR 529524

      Support for Synplify is now available.

4. Known Issues

    The following are known issues for v1.13 of this core at the time of release.

    4.1  Functional Issues


    4.2  Simulation Issues

          - Large Simulation Times
          o CR 448685

            Simulation takes a long time to achieve trn_lnk_up_n assertion.
	    This is because GTP model drives the serial lines to Unknown logic
	    state, when signaling Electrical Idle during the link training 
	    phase. Refer to Xilinx Answer 29294 for a work around to this issue.

    4.3  Implementation Issues


          - Speed file and design changes

            The design files present in this release are based on timing 
	    parameters from, and intended for use with, the speed files shipped 
	    with ISE 11.3. As more device characterization data is collected,
	    Xilinx may update the speed files to more closely model device 
	    operation.

            Xilinx reserves the right to modify the design files, including the 
	    core pin-out, in order to maintain full compliance after speed files
	    updates occur. To the full extent possible, Xilinx will incorporate 
	    such modifications without using pin-out changes in an effort to 
	    provide "transparent" design file updates.

           - Timing Closure

            In order to obtain timing closure, designers may be required to use
            multiple PAR seeds and/or floorplanning. Using Multi-Pass Place and
            Route (MPPR), designers can try multiple cost tables in order to meet
            timing. Please see the Development System Reference Guide in the
            Software Manuals found at: http://www.xilinx.com/support/library.htm
	    for more information on using MPPR. Designers may also have to 
	    floorplan and add advanced placement constraints for both their 
	    design and the core to meet timing.

            - Xilinx warnings

            The Xilinx tools may issue various warnings, however no errors should
            occur.

   The most recent information, including known issues, workarounds and 
   resolutions for this version is provided in the IP Release Notes Guide located
   at 

   www.xilinx.com/support/documentation/user_guides/xtp025.pdf

5. TECHNICAL SUPPORT

   To obtain technical support, create a WebCase at
   http://www.xilinx.com/support.
   Questions are routed to a team expertise in using this product.

   Xilinx provides technical support for use of this product when used according
   to the guidelines described in the core documentation, and cannot guarantee
   timing, functionality, or support of this product for designs that do not
   follow specified guidelines.


6. OTHER INFORMATION


7. CORE RELEASE HISTORY

Date     By            Version      Description
===============================================================================
12/2009  Xilinx, Inc.  1.13         11.4i - Source code delivery
09/2009  Xilinx, Inc.  1.12         11.3i - Source code delivery
06/2009  Xilinx, Inc.  1.11         11.2i support
04/2009  Xilinx, Inc.  1.10         11.1i support
09/2008  Xilinx, Inc.  1.9          10.1i - IP Update 3
06/2008  Xilinx, Inc.  1.8          10.1i - IP Update 2
04/2008  Xilinx, Inc.  1.7 rev 1    Update for rev 1 patch
04/2008  Xilinx, Inc.  1.7          10.1i - IP Update 1
03/2008  Xilinx, Inc.  1.6 rev 1    Update for rev 1 patch
03/2008  Xilinx, Inc.  1.6          10.1i
02/2008  Xilinx, Inc.  1.5 rev 2    Update for rev 2 patch
01/2008  Xilinx, Inc.  1.5 rev 1    Update for rev 1 patch
10/2007  Xilinx, Inc.  1.5          9.2i SP3 - IP Update 2
08/2007  Xilinx, Inc.  1.4          9.2i SP2 - IP Update 1
05/2007  Xilinx, Inc.  1.3          9.1i SP3 - IP Update 3
03/2007  Xilinx, Inc.  1.2 rev 1    Update for rev 1 patch
02/2007  Xilinx, Inc.  1.2          9.1i SP2 - IP Update 1
===============================================================================

8. Legal Disclaimer

(c) Copyright 2002 - 2009 Xilinx, Inc. All rights reserved. 
2006, 2007, 2008, 2009

This file contains confidential and proprietary information
of Xilinx, Inc. and is protected under U.S. and
international copyright and other intellectual property
laws.
--
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
--
CRITICAL APPLICATIONS
Xilinx products are not designed or intended to be fail-
safe, or for use in any application requiring fail-safe
performance, such as life-support or safety devices or
systems, Class III medical devices, nuclear facilities,
applications related to the deployment of airbags, or any
other applications that could lead to death, personal
injury, or severe property or environmental damage
individually and collectively, "Critical
Applications"). Customer assumes the sole risk and
liability of any use of Xilinx products in Critical
Applications, subject only to applicable laws and
regulations governing limitations on product liability.
--
THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
PART OF THIS FILE AT ALL TIMES.
