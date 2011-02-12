vlib work
vmap work work
vlog -work work ../../implement/results/routed.v
vlog -work work ../configuration_tb.v
vlog -work work ../phy_tb.v
vlog -work work ../demo_tb.v
vsim -voptargs="+acc" -L simprims_ver -L secureip +no_tchk_msg +transport_int_delays +transport_path_delays -t ps -sdfmax /dut=../../implement/results/routed.sdf work.testbench work.glbl
do wave_mti.do
run -all
