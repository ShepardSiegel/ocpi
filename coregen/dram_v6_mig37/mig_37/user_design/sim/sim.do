###############################################################################
## (c) Copyright 2008 � 2009 Xilinx, Inc. All rights reserved.
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
## \   \   \/     Version            : 3.7
##  \   \         Application        : MIG
##  /   /         Filename           : sim.do
## /___/   /\     Date Last Modified : $Date: 2010/10/05 16:43:05 $
## \   \  /  \    Date Created       : Mon Jun 23 2008
##  \___\/\___\
##
## Device           : Virtex-6
## Purpose          :
##                   Sample sim .do file to compile and simulate memory interface
##                   design and run the simulation for specified period of time.
##                   Display the waveforms that are listed with "add wave" command.
## Assumptions      :
##                   Simulation takes place in \sim folder of MIG output directory.
## Reference        :
## Revision History :
###############################################################################

vlib work

#Map the required libraries here#
#vmap unisims_ver <unisims_ver lib path>
#vmap unisim <unisim lib path>
#vmap secureip <secureip lib path>

#Compile all modules#
vlog  ../rtl/ip_top/ddr2_ddr3_chipscope.*
vlog  ../rtl/ip_top/*
vlog  ../rtl/controller/*
vlog  ../rtl/phy/*
vlog  ../rtl/ui/*
vlog  ../rtl/ecc/*


#Compile files in sim folder (excluding model parameter file)#
#$XILINX variable must be set
vlog  $env(XILINX)/verilog/src/glbl.v
vlog  ../sim/wiredly.*
vlog  ../sim/sim_tb_top.*
vlog  ../sim/afifo.v
vlog  ../sim/cmd_gen.v
vlog  ../sim/cmd_prbs_gen.v
vlog  ../sim/data_prbs_gen.v
vlog  ../sim/init_mem_pattern_ctr.v
vlog  ../sim/mcb_flow_control.v
vlog  ../sim/mcb_traffic_gen.v
vlog  ../sim/rd_data_gen.v
vlog  ../sim/read_data_path.v
vlog  ../sim/read_posted_fifo.v
vlog  ../sim/sp6_data_gen.v
vlog  ../sim/tg_status.v
vlog  ../sim/v6_data_gen.v
vlog  ../sim/wr_data_gen.v
vlog  ../sim/write_data_path.v

#Pass the parameters for memory model parameter file#
vlog  +incdir+. +define+x1Gb +define+sg187E +define+x16 ddr3_model.v

#Load the design. Use required libraries.#
vsim -t fs -novopt +notimingchecks -L unisims_ver work.sim_tb_top glbl

onerror {resume}
#Log all the objects in design. These will appear in .wlf file#
log -r /*
#View sim_tb_top signals in waveform#
add wave sim:/sim_tb_top/*
#Change radix to Hexadecimal#
radix hex
#Supress Numeric Std package and Arith package warnings.#
#For VHDL designs we get some warnings due to unknown values on some signals at startup#
# ** Warning: NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0#
#We may also get some Arithmetic packeage warnings because of unknown values on#
#some of the signals that are used in an Arithmetic operation.#
#In order to suppress these warnings, we use following two commands#
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

#Choose simulation run time by inserting a breakpoint and then run for specified #
#period. For more details, refer to user guide (UG406).#
when {/sim_tb_top/phy_init_done = 1} {
if {[when -label a_100] == ""} {
when -label a_100 { $now = 50 us } {
nowhen a_100
report simulator control
report simulator state
if {[examine /sim_tb_top/error] == 0} {
echo "TEST PASSED"
stop
}
if {[examine /sim_tb_top/error] != 0} {
echo "TEST FAILED: DATA ERROR"
stop
}
}
}
}

#In case calibration fails to complete, choose the run time and then stop#
when {$now = @1000 us and /sim_tb_top/phy_init_done != 1} {
echo "TEST FAILED: CALIBRATION DID NOT COMPLETE"
stop
}

run -all
stop
