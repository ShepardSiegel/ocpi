./rem_files.bat

coregen -b makeproj.bat
coregen -p . -b icon4_cg.xco
coregen -p . -b vio_async_in96_cg.xco
coregen -p . -b vio_async_in192_cg.xco
coregen -p . -b vio_sync_out32_cg.xco
coregen -p . -b vio_async_in100_cg.xco
rm *.ncf
echo Synthesis Tool: XST

mkdir "../synth/__projnav" > ise_flow_results.txt
mkdir "../synth/xst" >> ise_flow_results.txt
mkdir "../synth/xst/work" >> ise_flow_results.txt

xst -ifn xst_run.txt -ofn mem_interface_top.syr -intstyle ise >> ise_flow_results.txt
ngdbuild -intstyle ise -dd ../synth/_ngo -nt timestamp -uc mig_v3_4.ucf -p xc5vsx95tff1136-2 mig_v3_4.ngc mig_v3_4.ngd >> ise_flow_results.txt

map -intstyle ise -detail -w -logic_opt off -ol high -xe n -t 1 -cm area -o mig_v3_4_map.ncd mig_v3_4.ngd mig_v3_4.pcf >> ise_flow_results.txt
par -w -intstyle ise -ol high -xe n mig_v3_4_map.ncd mig_v3_4.ncd mig_v3_4.pcf >> ise_flow_results.txt
trce -e 3 -xml mig_v3_4 mig_v3_4.ncd -o mig_v3_4.twr mig_v3_4.pcf >> ise_flow_results.txt
bitgen -intstyle ise -f mem_interface_top.ut mig_v3_4.ncd >> ise_flow_results.txt

echo done!
