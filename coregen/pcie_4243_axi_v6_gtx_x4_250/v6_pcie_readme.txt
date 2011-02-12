
           Core name: Xilinx Virtex-6 Integrated Block for PCI Express
           Version: 1.5
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

For the most recent updates to the IP installation instructions for this core,
please go to:

   http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm


For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm


This file contains release notes for the Xilinx LogiCORE(TM) IP Virtex-6 
Integrated Block for PCI Express v1.5 solution. For the latest core updates, 
see the product page at:

   http://www.xilinx.com/products/ipcenter/V6_PCI_Express_Block.htm


2. NEW FEATURES  
 
   - ISE 12.1 software support
   - Added support for HXT devices - 6VHX380T-FF1154, 6VHX380T-FF1923
     and 6VHX255T-FF1923.
   - Support for 8-lane Gen2 Endpoint product has been enabled for Virtex-6 HXT.
   - Synplify Support
   - Option added to enable Bufferring optimized for Bus Mastering Applications.
   - License check removed
 
3. SUPPORTED DEVICES

   - Virtex-6 LXT, Virtex-6 SXT, Virtex-6 HXT, Virtex-6 CXT
   - Virtex-6 Lower Power LXTL, Virtex-6 Lower Power SXTL

4. RESOLVED ISSUES 

   - License checks removed
     o CR 550704

     The Virtex-6 Integrated Block for PCI Express product no longer checks for
     license and does not require a pre-shipped license as of the 12.1 release.

   - Gen2 operation supported with 100 MHz Reference Clock.
     o CR 522983

     Gen 2 operation is now also supported with 100 MHz Reference Clock.

   - VHDL example design / testbench for Root Port Configuration now supported.
     o CR 510476

     VHDL example design and testbench for both the Endpoint and Root Port
     Configurations is now supported.

   - Synplify flow now supported in the 12.1 release
     o CR 531976

     Synplify flow is now supported in the 12.1 release

   - Option added to enable Buffering optimized for Bus Mastering application
     o CR 535127

     New option has been added to CoreGen GUI to enable Buffering optimized for
     Bus Mastering applications.

   - Added support for 6VHX380T-FF1154, 6VHX380T-FF1923 and 6VHX255T-FF1923.
     o CR 538257

     Support for all HXT devices has now been enabled.

   - 8-lane Gen2 product is now supported in the Virtex-6 HXT devices.
     o CR 531975

     Support for 8-lane Gen2 product, in Virtex-6 HXT devices is now available.

   - 8-lane Gen2 product is now supported in the Virtex-6 LX130T device, in a 
     -2 speedgrade
     o CR 538644

     8-lane Gen2 product is now supported for 6VLX130T, in a -2 speedgrade, in 
     the 12.1 release.

   - Root Port product hardware autonomously initiates Gen1-Gen2 speed change.
     o CR 535128

     The Root Port product now hardware autonomously initiates Gen1 - Gen2 speed
     change if possible.

   - GTX Production Settings Updated
     o CR 548630, 552700, 550490, 545280

     GTX settings have been updated per Production GTX settings.

   - Core Generation from ISE fixed
     o CR 551143

     Issue resolved where Coregen Generation from ISE was failing.

   - LL Replay Timer default settings have been changed in GUI.
     o CR 546697

     LL Replay Timer default settings have been changed in the GUI, as previous
     values were not accounting for internal processing delays, causing 
     Correctable errors (replays) when there is link traffic but no link errors.

   - New GUI option added to Disable TX ASPM L0s.
     o CR 538239

     New GUI options has been added to Disable TX ASPM L0s action. This option 
     is recommended to be enabled for links that interconnect Xilinx Virtex-6 to
     any Xilinx component.

   - Workaround added for De-emphasis Value Error known restriction, for Root
     Port configuration
     o CR 539285

     Workaround has been implemented for the known restriction "De-emphasis
     Value Error", in the Root Port Configuration, by setting 
     PLDOWNSTREAMDEEMPHSOURCE attribute to 1b. For more information on the 
     restriction, refer to the "Known Restrictions" section in the User Guide.

   - Root Port model provided for Endpoint product now passes Memory / IO 
     transactions to User side.
     o CR 539545

     Root Port model delivered with the Endpoint product has been updated to
     pass Memory and IO transactions from the Endpoint to the User side.

   - Enabled PROM file generation for programming ML605
     o CR 552777

     Enabled PROM file generation for programming ML605, in the implementation
     scripts.

   - Upgrade capability added
     o CR 548864

     Upgrade capability added to enable generation of the latest version of the
     product for a previously customized project (from an XCO from the previous
     version of the core).

   - Default value of Acceptable L0s Exit Latency changed
     o CR 553769

     Default value of the Acceptable L0s Exit Latency for an Endpoint product
     has been updated to a "Maximum of 64 ns".

   - GT Debug Ports option removed from CoreGen GUI
     o CR 531980

     GT Debug Ports (DRP) option has been removed from the CoreGen GUI.

   - VHDL update
     o CR 555118

     The VHDL source code has been updated for latest wrapper changes and also 
     for issues with existing code, which was causing address on Read FIFO to be
      incorrect.

   - Constraints added for Configurations with User Clock 250 MHz
     o CR 539219

     Constraints were added to the UCF and XCF for Configurations with User
     Clock set to 250 MHz.

   - PLL reset input changed
     o CR 537545

     PLL reset input had been changed so it does not get reset at link-down.
     This enables the trn_clk to not be interrupted in thsi scenario.


5. KNOWN ISSUES 
   
   The following are known issues for v1.5 of this core at time of release:


   - Use of corename "core" in VHDL design will cause implementation failures
     o CR 538681

     Use of corename "core" for a VHDL design causes implementation failures
     since the instance of the core in the example design has an instance name
     "core".

     Workaround : Use a corename other than "core" for a VHDL design.

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

