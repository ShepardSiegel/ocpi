#!/bin/sh

# Clean up the results directory
rm -rf results
mkdir results

#Synthesize the Wrapper Files
echo 'Synthesizing example design with XST';
xst -ifn xilinx_pcie_2_1_ep_7x.xst -ofn xilinx_pcie_2_1_ep_7x.log
cp xilinx_pcie_2_1_ep_7x.ngc ./results/

cp xilinx_pcie_2_1_ep_7x.log xst.srp

if [ -f xilinx_pcie_2_1_ep_7x.ngc ]; then netgen -sim -ofmt verilog -ne -w -tm xilinx_pcie_2_1_ep_7x xilinx_pcie_2_1_ep_7x.ngc
fi
cp xilinx_pcie_2_1_ep_7x.ngc ./results/


rm -rf *.mgo xlnx_auto_0_xdb xlnx_auto_0.ise netlist.lst smart



cd results

echo 'Running ngdbuild'
ngdbuild -verbose -uc ../../example_design/xilinx_pcie_2_1_ep_7x_04_lane_gen2_xc7k325t-ffg900-1-PCIE_X0Y0.ucf xilinx_pcie_2_1_ep_7x.ngc -sd .


echo 'Running map'
map -w \
  -global_opt speed \
  -register_duplication on \
  -retiming on \
  -ol high \
  -o mapped.ncd \
  xilinx_pcie_2_1_ep_7x.ngd \
  mapped.pcf

echo 'Running par'
par \
  -ol high \
  -w mapped.ncd \
  routed.ncd \
  mapped.pcf

echo 'Running trce'
trce -u -e 100 \
  routed.ncd \
  mapped.pcf

echo 'Running design through netgen'
netgen -sim -ofmt verilog -ne -w -tm xilinx_pcie_2_1_ep_7x -sdf_path . routed.ncd

# Bitstream generation not supported in 13.1
#echo 'Running design through bitgen'
#bitgen -w routed.ncd

