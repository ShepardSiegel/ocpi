
set device xc7k325t-fbg900-2
set projName pcie_7x_v1_3
set design pcie_7x_v1_3
set projDir  [file dirname [info script]]

set projDir [file dirname [info script]]
create_project $projName $projDir/results/$projName -part $device -force
set_property design_mode RTL [current_fileset -srcset]

set top_module xilinx_pcie_2_1_ep_7x
set_property top xilinx_pcie_2_1_ep_7x [get_property srcset [current_run]]
add_files -norecurse {../../source/pcie_7x_v1_3_gt_top.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_bram_top_7x.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_brams_7x.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_bram_7x.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_7x.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_pipe_pipeline.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_pipe_lane.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_pipe_misc.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_tx_thrtl_ctl.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_rx.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_rx_null_gen.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_rx_pipeline.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_tx_pipeline.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_tx.v}
add_files -norecurse {../../source/pcie_7x_v1_3_axi_basic_top.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pcie_top.v}
add_files -norecurse {../../source/pcie_7x_v1_3.v}
add_files -norecurse {../../source/pcie_7x_v1_3_gt_wrapper.v}
add_files -norecurse {../../source/pcie_7x_v1_3_qpll_wrapper.v}
add_files -norecurse {../../source/pcie_7x_v1_3_qpll_drp.v}
add_files -norecurse {../../source/pcie_7x_v1_3_qpll_reset.v}
add_files -norecurse {../../source/pcie_7x_v1_3_rxeq_scan.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_eq.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_clock.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_drp.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_rate.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_reset.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_user.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_sync.v}
add_files -norecurse {../../source/pcie_7x_v1_3_pipe_wrapper.v}
add_files -norecurse {../../example_design/xilinx_pcie_2_1_ep_7x.v}
add_files -norecurse {../../example_design/pcie_app_7x.v}
add_files -norecurse {../../example_design/PIO.v}
add_files -norecurse {../../example_design/PIO_EP.v}
add_files -norecurse {../../example_design/PIO_EP_MEM_ACCESS.v}
add_files -norecurse {../../example_design/EP_MEM.v}
add_files -norecurse {../../example_design/PIO_TO_CTRL.v}
add_files -norecurse {../../example_design/PIO_RX_ENGINE.v}
add_files -norecurse {../../example_design/PIO_TX_ENGINE.v}
read_xdc ../../example_design/xilinx_pcie_2_1_ep_7x_08_lane_gen2_xc7k325t-fbg900-2-PCIE_X0Y0.xdc
synth_design -flatten_hierarchy none
opt_design
place_design
route_design
set_param sta.dlyMediator true
write_sdf -rename_top_module xilinx_pcie_2_1_ep_7x -file routed.sdf
write_verilog -nolib -mode sim -sdf_anno true -rename_top_module xilinx_pcie_2_1_ep_7x -file routed.v
report_timing -nworst 30 -path_type full -file routed.twr
report_drc
