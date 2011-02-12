#!/bin/sh

# Clean up the results directory
rm -rf results
mkdir -p results

echo 'Synthesizing example design with XST';
xst -ifn xst.scr
cp v6_emac_v1_3_example_design.ngc ./results/

echo 'Copying files from constraints directory to results directory'
cp ../example_design/v6_emac_v1_3_example_design.ucf results/

cd results

echo 'Running ngdbuild'
ngdbuild -uc v6_emac_v1_3_example_design.ucf v6_emac_v1_3_example_design.ngc v6_emac_v1_3_example_design.ngd

echo 'Running map'
map -ol high v6_emac_v1_3_example_design -o mapped.ncd

echo 'Running par'
par -ol high -w mapped.ncd routed.ncd mapped.pcf

echo 'Running trce'
trce -e 10 routed -o routed mapped.pcf

echo 'Running design through bitgen'
bitgen -w routed

echo 'Running netgen to create gate level Verilog model'
netgen -ofmt verilog -sim -dir . -pcf mapped.pcf -tm v6_emac_v1_3_example_design -w -sdf_anno false routed.ncd routed.v
