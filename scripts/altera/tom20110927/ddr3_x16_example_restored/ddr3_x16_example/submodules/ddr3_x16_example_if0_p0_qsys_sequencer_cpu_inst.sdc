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

set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst:*
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_break 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci_break:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci_break
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_ocimem 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_ocimem:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_ocimem
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci_debug:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_nios2_oci_debug
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_wrapper 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_wrapper:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_wrapper
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_tck 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_tck:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_tck
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sysclk 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_sysclk:the_ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_debug_module_sysclk
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path 	 [format "%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_break_path 	 [format "%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_break]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_ocimem_path 	 [format "%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_ocimem]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug_path 	 [format "%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_tck_path 	 [format "%s|%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_wrapper $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_tck]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sysclk_path 	 [format "%s|%s|%s" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_path $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_wrapper $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sysclk]
set 	ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr 	 [format "%s|*sr" $ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_tck_path]

#**************************************************************
# Set False Paths
#**************************************************************

set_false_path -from [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_break_path|break_readreg*] -to [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr*]
set_false_path -from [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug_path|*resetlatch]     -to [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr[33]]
set_false_path -from [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug_path|monitor_ready]  -to [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr[0]]
set_false_path -from [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug_path|monitor_error]  -to [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr[34]]
set_false_path -from [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_ocimem_path|*MonDReg*] -to [get_keepers *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr*]
set_false_path -from *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sr*    -to *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sysclk_path|*jdo*
set_false_path -from sld_hub:*|irf_reg* -to *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_jtag_sysclk_path|ir*
set_false_path -from sld_hub:*|sld_shadow_jsm:shadow_jsm|state[1] -to *$ddr3_x16_example_if0_p0_qsys_sequencer_cpu_inst_oci_debug_path|monitor_go
