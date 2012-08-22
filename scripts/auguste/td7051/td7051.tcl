# td7051.tcl - KC705 test chip 1
# Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

set designTop fpgaTop
set designName td7051
set targetPart xc7k325tffg900-1
set designDir ./rtl
set outputBaseName td7051
set outputDir ./output
file mkdir $outputDir

read_verilog [glob $designDir/*.v]
read_xdc $designDir/$designName.xdc

synth_design -top $designTop -part $targetPart
opt_design
place_design
route_design
report_timing

report_timing -file $outputDir/$outputBaseName.sta
write_verilog $outputDir/$outputBaseName.v
write_xdc $outputDir/$outputBaseName.xdc
write_dcp ${outputBaseName}_checkpoint $outputDir
write_ncd $outputDir/$outputBaseName.ncd
#write_pcf $outputDir/$outputBaseName.pcf
