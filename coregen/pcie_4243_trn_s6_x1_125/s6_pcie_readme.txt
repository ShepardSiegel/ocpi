                Core name: Xilinx Spartan-6 Integrated
                           Block for PCI Express
                Version: 1.2
                Release Date: September 16, 2009


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



This file contains release notes for the Xilinx LogiCORE(TM) IP Spartan-6
Integrated Block for PCI Express(R) v1.2 solution. For the latest core
updates, see the product page at:

  http://www.xilinx.com/products/ipcenter/S6_PCI_Express_Block.htm

2. NEW FEATURES

   - ISE 11.3 software support
   - VHDL source for wrapper and example design
   - Support for VCS, IUS, and Synplify
   - Additional Part/Package support


3. RESOLVED ISSUES

   - Clock-to-out delay required on cfg_interrupt_n for simulation
      - version fixed: 1.2
      - CR #520833
      - AR #32865

   - Designs which use Multi-Vector MSI should check the number of allocated
     vectors before generating an MSI interrupt
      - CR #522729
      - AR #32866

   - Designs which use the cfg_pm_wake_n input to generate a PME event should
     implement a timeout counter
      - CR #522731
      - AR #32867

4. KNOWN ISSUES

   The following are known issues for v1.1 of this core at time of release:

   - At time of release, Synplify does not support VHDL designs
     targeting Spartan-6
      - This is expected to be corrected in the next release of Synplify

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

   The User Guide states that VHDL simulation is only supported in
   ModelSim. This is incorrect - VHDL simulation in IUS is also supported.


7. CORE RELEASE HISTORY

Date        By            Version      Description
================================================================================
09/16/2009  Xilinx, Inc.  1.2          11.3 support
06/24/2009  Xilinx, Inc.  1.1          Initial release
================================================================================

8. Legal Disclaimer

(c) Copyright 2009 Xilinx, Inc. All rights reserved. 

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

