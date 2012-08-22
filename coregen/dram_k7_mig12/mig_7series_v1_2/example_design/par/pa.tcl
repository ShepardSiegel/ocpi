#
# This is a common pa.tcl used by all designs used for hardware validation
#

# Setup default values
set DEBUG_FILES 1

# Might not need in the future# 
create_project proj1 . -force;
set_property design_mode RTL [get_property srcset [current_run]] ;# Set project type to RTL (as apposed to Netlist)

# Define some helpful variables, dirs, etc.
# All defines related to the design should be located in the app directory

set design example_top
set device xc7k325t-1-fbg900
#set constraints_file example_top.ucf

# temporary options
set_param synth.elaboration.rodinMoreOptions "set_parameter inferMuxPart false;set flattenHierarchy 0"

# Setup design sources and constraints
set readfile [open ../synth/example_top.prj r]
while {[gets $readfile line] >=0} {
set file_list [split $line " "]
read_verilog [lindex $file_list 2]
}

# Read the xdc constraints for the top-level file
set_property top ${design} [get_property srcset [current_run]]
import_files -fileset [get_filesets constrs_1] -force -norecurse {./example_top.xdc} 
set_property target_constrs_file {./example_top.xdc} [current_fileset -constrset]
add_files -norecurse {./example_top.xdc}

# Run basic compilation - synthesis, place & route
synth_design -part ${device} -top example_top;
write_verilog ./${design}.v;


# specific for hardware testing
#read_ucf ${constraints_file};
opt_design -retarget;       # RhvVariant:comment
opt_design -propconst;      # RhvVariant:comment
opt_design -remap;          # RhvVariant:comment
opt_design -sweep;          # RhvVariant:comment

place_design;
route_design;

# Mandatory outputs
report_drc -file ${design}.drc;


# Optional 'debug' outputs
if {$DEBUG_FILES} {
    report_timing -file ${design}.sta;
    write_edf ./${design}.edf;
    write_verilog ./${design}.routed.v;
    write_xdc ./${design}.planahead.xdc;
}

close_project -delete;
