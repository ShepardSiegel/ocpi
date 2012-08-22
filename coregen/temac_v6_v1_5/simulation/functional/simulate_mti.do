vlib work
vmap work work
vlog -work work $env(XILINX)/verilog/src/glbl.v
vlog -work work ../../example_design/client/address_swap_module_8.v
vlog -work work ../../example_design/client/fifo/tx_client_fifo_8.v
vlog -work work ../../example_design/client/fifo/rx_client_fifo_8.v
vlog -work work ../../example_design/client/fifo/eth_fifo_8.v
vlog -work work ../../example_design/physical/gmii_if.v
vlog -work work ../../example_design/v6_emac_v1_5.v
vlog -work work ../../example_design/v6_emac_v1_5_block.v
vlog -work work ../../example_design/v6_emac_v1_5_locallink.v
vlog -work work ../../example_design/v6_emac_v1_5_example_design.v
vlog -work work ../configuration_tb.v
vlog -work work ../phy_tb.v
vlog -work work ../demo_tb.v
vsim -voptargs="+acc" -L secureip -L unisims_ver -t ps work.testbench work.glbl
do wave_mti.do
run -all
