                Core name: Xilinx LogiCORE Endpoint Block Plus for PCI Express(R)
                Version: 1.14
                Release Date: April 19, 2010


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

For the most recent updates to the IP installation instructions for this
core, please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm

For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm

This file contains release notes for the Xilinx LogiCORE IP Endpoint Block Plus
for PCI Express v1.14 solution. For the latest core updates, see the product 
page at:

http://www.xilinx.com/products/ipcenter/V5_PCI_Express_Block_Plus.htm

For information on how to set up and use the core, please refer to the LogiCORE
IP Endpoint Block Plus for PCI Express Getting Started Guide.  More 
comprehensive user information is available in the LogiCORE IP Endpoint Block 
Plus for PCI Express User Guide.


2. NEW FEATURES

- ISE 12.1 software support
- Synplify support added for VHDL
- Support for QVirtex5
- License check removed
- New script added to generate netlist of core.

3. SUPPORTED DEVICES

- Virtex-5, QVirtex5


4. RESOLVED ISSUES

   - Synplify support now available
      o CR 529524

      Support for Synplify is now available for both Verilog and VHDL.

   - License checks removed
     o CR 550704

     The Virtex-5 Integrated Block Plus for PCI Express product no longer checks
     for license and does not require a pre-shipped license as of the 12.1 release.

   - Hexadecimal value for Device ID causing simulation failure
      o CR 555015

      Issue resolved where a Hexadecimal value for Device ID caused simulation
      failure.

   - VHDL simulation time-out
      o CR 551805

      Issue resolved where VHDL simulation was timing out due to issue in root
      port test bench.

   - XST error in 2-lane 250 MHz interface frequency design
      o CR 539288

      Issue resolved where implementing 2-lane designs with 250 MHz interface 
      frequency would result in unrecognized constraint error, due to error in
      the delivered XCF.

   - TXBUFDIFFCTRL selection in GUI not displaying correctly
      o CR 550697

      Issue resolved where TXBUFDIFFCTRL display in GUI did not change to match
      the selected option for TXDIFFCTRL.

   - PIO Design updated for generating completions for IO Writes
     o CR 536197

     PIO design updated to enable generation of completion for IO Writes.

   - Root Port model provided for Endpoint product now passes Memory / IO 
     transactions to User side.
     o CR 539544

     Root Port model delivered with the Endpoint product has been updated to
     pass Memory and IO transactions from the Endpoint to the User side.

   - TXBUFDIFFCTRL not driving TXBUFDIFFCTRL on the GT
     o CR 539439

     Issue resolved where the GUI selection of TXBUFDIFFCTRL was not driving
     the TXBUFDIFFCTRL on the GT.

   - Incorrect path in delivered XCF for synplify flow
     o CR 541047

     Issue resolved where the delivered XCF for synplify flow had incorrect path
     for the NETs.

   - TXPREEMPHASIS selection in GUI fixed
     o CR 551912

     Issue resolved where the GUI was preventing selection of non-default values
     for TXPREEMPHASIS.

   - New script to enable generation of ngc for core.
     o CR 540346

     New script delivered, to enable generation of ngc for core

   - Root Port model settings corrected.
     o CR 551223

     Issue resolved where Root Port model settings were incorrect causing 
     error in simulation, due to incorrect attribute setting on the model.

   - Warnings during Core Generation from ISE resolved
     o CR 539017

     Issue resolved where Core generation from ISE / Project Navigator caused
     a number of Warnings to be generated.


5. KNOWN ISSUES

The following are known issues for v1.14 of this core at time of release:

    5.1  Functional Issues

        - 64-packet threshold for Completion Streaming on RX interface.
        o CR 553163

          The known restriction for 64-packet threshold for Completion 
	  Streaming on receive interface of the Integrated PCIe Block, listed
	  in the UG197, is applicable to both Posted and Completion packets
	  bypassing older Posted and Non-Posted packets. This issue is 
	  encountered in the Endpoint Block Plus for PCI Express core, when
	  trn_rnp_ok_n is de-asserted for an extended period of time while
	  such traffic is being received.

         Workaround: Do not de-assert trn_rnp_ok_n for extended periods of time.


    5.2  Simulation Issues

          - Large Simulation Times
          o CR 448685

            Simulation takes a long time to achieve trn_lnk_up_n assertion.
	    This is because GTP model drives the serial lines to Unknown logic
	    state, when signaling Electrical Idle during the link training 
	    phase. Refer to Xilinx Answer 29294 for a work around to this issue.

    5.3  Implementation Issues


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

The most recent information, including known issues, workarounds, and
resolutions for this version is provided in the IP Release Notes Guide
located at

   www.xilinx.com/support/documentation/user_guides/xtp025.pdf


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
04/19/2010  Xilinx, Inc.  1.14         12.1 support
13/09/2010  Xilinx, Inc.  1.13 Rev 1   11.5 support
12/02/2009  Xilinx, Inc.  1.13         11.4 support
09/16/2009  Xilinx, Inc.  1.12         11.3 support
06/24/2009  Xilinx, Inc.  1.11         11.2 support
04/24/2009  Xilinx, Inc.  1.10         11.1 support
09/2008     Xilinx, Inc.  1.9          10.1i - IP Update 3
06/2008     Xilinx, Inc.  1.8          10.1i - IP Update 2
04/2008     Xilinx, Inc.  1.7 rev 1    Update for rev 1 patch
04/2008     Xilinx, Inc.  1.7          10.1i - IP Update 1
03/2008     Xilinx, Inc.  1.6 rev 1    Update for rev 1 patch
03/2008     Xilinx, Inc.  1.6          10.1i
02/2008     Xilinx, Inc.  1.5 rev 2    Update for rev 2 patch
01/2008     Xilinx, Inc.  1.5 rev 1    Update for rev 1 patch
10/2007     Xilinx, Inc.  1.5          9.2i SP3 - IP Update 2
08/2007     Xilinx, Inc.  1.4          9.2i SP2 - IP Update 1
05/2007     Xilinx, Inc.  1.3          9.1i SP3 - IP Update 3
03/2007     Xilinx, Inc.  1.2 rev 1    Update for rev 1 patch
02/2007     Xilinx, Inc.  1.2          9.1i SP2 - IP Update 1
================================================================================

9. Legal Disclaimer

(c) Copyright 2002 - 2010 Xilinx, Inc. All rights reserved.

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

