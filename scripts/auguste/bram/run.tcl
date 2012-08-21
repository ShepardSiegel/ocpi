#
# mkBRAM100
#

#
# STEP#0: define some helpful variables, dirs, etc.
#

set topName mkBRAM100
set targetPart xc7k70tfbg484-2

# set_param project.keepTmpDir 1

set XDC_pre timing.xdc
set XDC_post pblock_create.xdc

# do more than read source
set DO_RUN 0

#
# STEP#1: setup design sources and constraints
#

read_verilog mkBRAM100.v BRAM1.v SizedFIFO.v

set_property top $topName [ get_filesets sources_1 ]

#
# STEP#2: run basic compilation - synthesis, place & route
#
puts "Reading user XDC via read_xdc"
read_xdc ${XDC_pre}

puts "Staring synth_design"
synth_design -part $targetPart -top $topName
report_utilization

opt_design
place_design
route_design

report_timing
report_utilization

