###############################################################################
## (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
###############################################################################
##   ____  ____
##  /   /\/   /
## /___/  \  /    Vendor             : Xilinx
## \   \   \/     Version            : 1.1
##  \   \         Application        : MIG
##  /   /         Filename           : readme.txt
## /___/   /\     Date Last Modified : $Date: 2010/11/30 15:09:47 $
## \   \  /  \    Date Created       : Wed Dec 16 2009
##  \___\/\___\
##
## Device          : 7 Series
## Design Name     : DDR3 SDRAM
## Purpose         : Steps to run simulations using Modelsim/ISIM simualtor
## Assumptions     : Simulations are run in \sim folder of MIG output directory
## Reference       :
## Revision History:
###############################################################################

MIG ouputs files (sim.do and other files) required to run the simulations for
Modelsim simulator.

1. How to run simulations in Modelsim simulator

   A) sim.do File :

      a) The 'sim.do' file has commands to compile and simulate memory
         interface design and run the simulation for specified period of time.

      b) It has the syntax to Map the required libraries (unisims_ver,
         unisim and secureip). The libraries should be mapped using
         the following command
         vmap unisims_ver <unisims_ver lib path>
         vmap unisim <unisim lib path>
         vmap secureip  <secureip lib path>

         Also, $XILINX environment variable must be set in order to compile glbl.v file

      c) Displays the waveforms that are listed with "add wave" command.

   B) Steps to run the Modelsim simulation:

      a) The user should invoke the Modelsim simulator GUI.

      b) Change the present working directory path to the sim folder.
         In Transcript window, at Modelsim prompt, type the following command to
         change directory path.
            cd <sim directory path>

      c) Run the simulation using sim.do file.
         At Modelsim prompt, type the following command:
            do sim.do

      d) To exit simulation, type the following command at Modelsim prompt:
            quit -f

      e) Verify the transcript file for the memory transactions.

2. Simulations are not supported for design frequencies of less than 400MHz due to
   issues with unisim libraries. These issues will be fixed in next release.

3. SIM_BYPASS_INIT_CAL parameter value of SKIP, skips memory initialization sequence
   and calibration sequence. This could lead to simulation errors since design is not
   calibrated at all. Preferred values for parameter SIM_BYPASS_INIT_CAL to run
   simulations are FAST and OFF.

