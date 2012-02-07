#!/bin/sh

rm -rf simv* csrc DVEfiles AN.DB

echo "Compiling Core Simulation Models"
vlogan +v2k \
      ../../example_design/client/address_swap_module_8.v \
      ../../example_design/client/fifo/tx_client_fifo_8.v \
      ../../example_design/client/fifo/rx_client_fifo_8.v \
      ../../example_design/client/fifo/eth_fifo_8.v \
      ../../example_design/physical/gmii_if.v \
      ../../example_design/v6_emac_v1_5.v \
      ../../example_design/v6_emac_v1_5_block.v \
      ../../example_design/v6_emac_v1_5_locallink.v \
      ../../example_design/v6_emac_v1_5_example_design.v \
      ../configuration_tb.v \
      ../phy_tb.v \
      ../demo_tb.v \
      $XILINX/verilog/src/glbl.v

vcs   +vcs+lic+wait \
      -debug -PP    \
      testbench glbl

./simv -ucli -i ucli_commands.key
dve -vpd vcdplus.vpd -session vcs_session.tcl
