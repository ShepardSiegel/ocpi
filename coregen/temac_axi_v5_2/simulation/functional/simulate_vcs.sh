#!/bin/sh

rm -rf simv* csrc DVEfiles AN.DB

echo "Compiling Core Simulation Models"
vlogan +v2k -v2005 \
      ../../../tri_mode_eth_mac_v5_2.v \
      ../../example_design/fifo/tx_client_fifo.v \
      ../../example_design/fifo/rx_client_fifo.v \
      ../../example_design/fifo/ten_100_1g_eth_fifo.v \
      ../../example_design/common/reset_sync.v \
      ../../example_design/common/sync_block.v \
      ../../example_design/pat_gen/address_swap.v \
      ../../example_design/pat_gen/axi_mux.v \
      ../../example_design/pat_gen/axi_pat_gen.v \
      ../../example_design/pat_gen/axi_pat_check.v \
      ../../example_design/pat_gen/axi_pipe.v \
      ../../example_design/pat_gen/basic_pat_gen.v \
      ../../example_design/physical/gmii_if.v \
     ../../example_design/axi_lite/axi_lite_sm.v \
     ../../example_design/axi_ipif/counter_f.v \
     ../../example_design/axi_ipif/pselect_f.v \
     ../../example_design/axi_ipif/address_decoder.v \
     ../../example_design/axi_ipif/slave_attachment.v \
     ../../example_design/axi_ipif/axi_lite_ipif.v \
     ../../example_design/axi_ipif/axi4_lite_ipif_wrapper.v \
      ../../example_design/clk_wiz.v \
      ../../example_design/tri_mode_eth_mac_v5_2_block.v \
      ../../example_design/tri_mode_eth_mac_v5_2_fifo_block.v \
      ../../example_design/tri_mode_eth_mac_v5_2_example_design.v \
      ../demo_tb.v

echo "Elaborating design"
vcs +vcs+lic+wait \
      -y unisims_ver \
      -y unimacro_ver \
      -y simprims_ver \
    -debug -PP \
    testbench glbl

echo "Starting simulation"
./simv -ucli -i ucli_commands.key

dve -vpd vcdplus.vpd -session vcs_session.tcl


