# Legal Notice: (C)2011 Altera Corporation. All rights reserved.  Your
# use of Altera Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any
# output files any of the foregoing (including device programming or
# simulation files), and any associated documentation or information are
# expressly subject to the terms and conditions of the Altera Program
# License Subscription Agreement or other applicable license agreement,
# including, without limitation, that your use is for the sole purpose
# of programming logic devices manufactured by Altera and sold by Altera
# or its authorized distributors.  Please refer to the applicable
# agreement for further details.

#**************************************************************
# Timequest JTAG clock definition
#   Uncommenting the following lines will define the JTAG
#   clock in TimeQuest Timing Analyzer
#**************************************************************

#create_clock -period 10MHz {altera_reserved_tck}
#set_clock_groups -asynchronous -group {altera_reserved_tck}

#**************************************************************
# Set TCL Path Variables 
#**************************************************************

set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst:*
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_break 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci_break:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci_break
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_ocimem 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_ocimem:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_ocimem
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci_debug:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_nios2_oci_debug
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_wrapper 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_wrapper:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_wrapper
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_tck 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_tck:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_tck
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sysclk 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_sysclk:the_altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_debug_module_sysclk
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path 	 [format "%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_break_path 	 [format "%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_break]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_ocimem_path 	 [format "%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_ocimem]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug_path 	 [format "%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_tck_path 	 [format "%s|%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_wrapper $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_tck]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sysclk_path 	 [format "%s|%s|%s" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_path $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_wrapper $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sysclk]
set 	altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr 	 [format "%s|*sr" $altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_tck_path]

#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_break_path|break_readreg*] -to [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr*]
set_false_path -from [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug_path|*resetlatch]     -to [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr[33]]
set_false_path -from [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug_path|monitor_ready]  -to [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr[0]]
set_false_path -from [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug_path|monitor_error]  -to [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr[34]]
set_false_path -from [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_ocimem_path|*MonDReg*] -to [get_keepers *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr*]
set_false_path -from *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sr*    -to *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sysclk_path|*jdo*
set_false_path -from sld_hub:*|irf_reg* -to *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_jtag_sysclk_path|ir*
set_false_path -from sld_hub:*|sld_shadow_jsm:shadow_jsm|state[1] -to *$altera_mem_if_ddr3_phy_0001_qsys_sequencer_cpu_inst_oci_debug_path|monitor_go
