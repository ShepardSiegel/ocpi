
rem Clean up the results directory
rmdir /S /Q results
mkdir results

echo 'Synthesizing HDL example design with XST';
xst -ifn xilinx_pcie_2_0_ep_v6.cmd -ofn xilinx_pcie_2_0_ep_v6.log
rem xst -ifn xst.scr


copy xilinx_pcie_2_0_ep_v6.log xst.srp


if not exist xilinx_pcie_2_0_ep_v6.ngc netgen -sim -ofmt verilog -ne -w -tm xilinx_pcie_2_0_ep_v6 xilinx_pcie_2_0_ep_v6.ngc

copy xilinx_pcie_2_0_ep_v6.ngc .\results\

cd results

echo 'Running ngdbuild'
ngdbuild -verbose -uc ../../example_design/xilinx_pcie_2_0_ep_v6_04_lane_gen2_xc6vlx240t-ff1156-1_ML605.ucf xilinx_pcie_2_0_ep_v6.ngc -sd .

echo 'Running map'
map -u -timing -ol high -xe c -pr b -o mapped.ncd -t 1 xilinx_pcie_2_0_ep_v6.ngd mapped.pcf

echo 'Running par'
par -ol high -xe c -w mapped.ncd routed.ncd mapped.pcf

echo 'Running trce'
trce -u -v 100 routed.ncd mapped.pcf

echo 'Running design through netgen'
netgen -sim -ofmt verilog -ne -w -tm xilinx_pcie_2_0_ep_v6 -sdf_path . routed.ncd

echo 'Running design through bitgen'
bitgen -w routed.ncd
