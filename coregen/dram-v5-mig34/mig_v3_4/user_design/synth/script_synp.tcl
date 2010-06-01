project -new 
#add_file options
add_file -verilog "../rtl/ddr2_chipscope.v"
add_file -verilog "../rtl/ddr2_ctrl.v"
add_file -verilog "../rtl/ddr2_idelay_ctrl.v"
add_file -verilog "../rtl/ddr2_infrastructure.v"
add_file -verilog "../rtl/ddr2_mem_if_top.v"
add_file -verilog "../rtl/ddr2_phy_calib.v"
add_file -verilog "../rtl/ddr2_phy_ctl_io.v"
add_file -verilog "../rtl/ddr2_phy_dm_iob.v"
add_file -verilog "../rtl/ddr2_phy_dq_iob.v"
add_file -verilog "../rtl/ddr2_phy_dqs_iob.v"
add_file -verilog "../rtl/ddr2_phy_init.v"
add_file -verilog "../rtl/ddr2_phy_io.v"
add_file -verilog "../rtl/ddr2_phy_top.v"
add_file -verilog "../rtl/ddr2_phy_write.v"
add_file -verilog "../rtl/ddr2_top.v"
add_file -verilog "../rtl/ddr2_usr_addr_fifo.v"
add_file -verilog "../rtl/ddr2_usr_rd.v"
add_file -verilog "../rtl/ddr2_usr_top.v"
add_file -verilog "../rtl/ddr2_usr_wr.v"
add_file -verilog "../rtl/mig_v3_4.v"

add_file -constraint "../synth/mem_interface_top_synp.sdc"

#implementation: "rev_1"
impl -add rev_1

#device options
set_option -technology virtex5
set_option -part xc5vsx95t
set_option -package ff1136
set_option -speed_grade -2

#compilation/mapping options
set_option -default_enum_encoding default
set_option -resource_sharing 0
set_option -use_fsm_explorer 0
set_option -top_module "mig_v3_4"

#map options
set_option -frequency 300.03
set_option -fanout_limit 20000
set_option -disable_io_insertion 0
set_option -pipe 1
set_option -update_models_cp 0
set_option -verification_mode 0
set_option -modular 0
set_option -retiming 0
set_option -fixgatedclocks 0

#sequential_optimizations options
set_option -symbolic_fsm_compiler 1

#simulation options
set_option -write_verilog 0
set_option -write_vhdl 0

#automatic place and route (vendor) options
set_option -write_apr_constraint 0

#set result format/file last
project -result_file "../synth/rev_1/mig_v3_4.edf"

#implementation attributes
set_option -vlog_std v2001
set_option -auto_constrain_io 0

#par_1 attributes
impl -active "../synth/rev_1"
project -run hdl_info_gen 
project -run
project -save

