# The package naming convention is <core_name>_xmdf
package provide v6_pcie_v1_5_xmdf 1.0

# This includes some utilities that support common XMDF operations
package require utilities_xmdf

# Define a namespace for this package. The name of the name space
# is <core_name>_xmdf
namespace eval ::v6_pcie_v1_5_xmdf {
# Use this to define any statics
}

# Function called by client to rebuild the params and port arrays
# Optional when the use context does not require the param or ports
# arrays to be available.
proc ::v6_pcie_v1_5_xmdf::xmdfInit { instance } {
# Variable containg name of library into which module is compiled
# Recommendation: <module_name>
# Required
utilities_xmdf::xmdfSetData $instance Module Attributes Name v6_pcie_v1_5}
# ::v6_pcie_v1_5_xmdf::xmdfInit

# Function called by client to fill in all the xmdf* data variables
# based on the current settings of the parameters
proc ::v6_pcie_v1_5_xmdf::xmdfApplyParams { instance } {

set fcount 0
# Array containing libraries that are assumed to exist
# Examples include unisim and xilinxcorelib
# Optional
# In this example, we assume that the unisim library will
# be magically
# available to the simulation and synthesis tool
utilities_xmdf::xmdfSetData $instance FileSet $fcount type logical_library
utilities_xmdf::xmdfSetData $instance FileSet $fcount logical_library unisim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/gtx_tx_sync_rate_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/gtx_wrapper_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/gtx_rx_valid_filter_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_upconfig_fix_3451_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_2_0_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_bram_top_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_bram_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_brams_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_clocking_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_gtx_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_pipe_lane_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_pipe_misc_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_pipe_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/pcie_reset_delay_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/source/v6_pcie_v1_5.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
utilities_xmdf::xmdfSetData $instance FileSet $fcount toplevel true
incr fcount


utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5/example_design/xilinx_pcie_2_0_ep_v6_04_lane_gen2_xc6vlx240t-ff1156-1-PCIE_X0Y0.ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module xilinx_pcie_2_0_ep_v6.v
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5.veo
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog_template
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5.xco
utilities_xmdf::xmdfSetData $instance FileSet $fcount type coregen_ip
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_5_xmdf.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount


utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module v6_pcie_v1_5
incr fcount

}

# ::v6_pcie_v1_5_xmdf::xmdfApplyParams

