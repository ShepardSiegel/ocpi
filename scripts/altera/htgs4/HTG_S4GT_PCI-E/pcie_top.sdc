# The refclk assignment may need to be renamed to match design top level port name.
# May be desireable to move refclk assignment to a top level SDC file.
create_clock -period "100 MHz" -name {refclk} {refclk}
# testin bits are either static or treated asynchronously, cut the paths.
set_false_path -to [get_pins -hierarchical {*hssi_pcie_hip|testin[*]} ]
# SERDES Digital Reset inputs are asynchronous
set_false_path -to {*|pcie_top_serdes:serdes|*|tx_digitalreset_reg0c[0]}
set_false_path -to {*|pcie_top_serdes:serdes|*|rx_digitalreset_reg0c[0]}
#
# The following multicycle path constraints are only valid if the logic use to sample the tl_cfg_ctl and tl_cfg_sts signals 
# are as designed in the Altera provided files altpcierd_tl_cfg_sample.v and altpcierd_tl_cfg_sample.vhd   
# 
# These constraints are only valid when the altpcierd_tl_cfg_sample module or entity is used with the PCI Express
# Hard IP block in Stratix IV, Arria II, Cyclone IV and HardCopy IV devices. 
# These constraints are not neccesary for PCI Express Hard IP in Stratix V devices. 
#
global tl_cfg_ctl_wr_setup
global tl_cfg_sts_wr_setup
#
# If there are consistent hold time violations for the tl_cfg_ctl_wr signal in your chosen device and design, 
# the multicycle setup constraint for tl_cfg_ctl_wr can be changed from 1 to 0 in the following variable:  
set tl_cfg_ctl_wr_setup 1
#
# If there are consistent hold time violations for the tl_cfg_sts_wr signal in your chosen device and design, 
# the multicycle setup constraint for tl_cfg_sts_wr can be changed from 1 to 0 in the following variable:  
set tl_cfg_sts_wr_setup 1
#
set_multicycle_path -start -setup -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_ctl_wr}] $tl_cfg_ctl_wr_setup
set_multicycle_path -end -setup -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_ctl[*]}] [expr $tl_cfg_ctl_wr_setup + 2]
set_multicycle_path -end -hold -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_ctl[*]}] 3
#
set_multicycle_path -start -setup -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_sts_wr}] $tl_cfg_sts_wr_setup
set_multicycle_path -end -setup -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_sts[*]}] [expr $tl_cfg_sts_wr_setup + 2]
set_multicycle_path -end -hold -from [get_keepers {*|pcie_top_core:wrapper|altpcie_hip_pipen1b:altpcie_hip_pipen1b_inst|tl_cfg_sts[*]}] 3
