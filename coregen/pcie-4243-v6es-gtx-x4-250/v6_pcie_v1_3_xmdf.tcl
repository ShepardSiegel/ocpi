# The package naming convention is <core_name>_xmdf
package provide v6_pcie_v1_3_xmdf 1.0

# This includes some utilities that support common XMDF operations
package require utilities_xmdf

# Define a namespace for this package. The name of the name space
# is <core_name>_xmdf
namespace eval ::v6_pcie_v1_3_xmdf {
# Use this to define any statics
}

# Function called by client to rebuild the params and port arrays
# Optional when the use context does not require the param or ports
# arrays to be available.
proc ::v6_pcie_v1_3_xmdf::xmdfInit { instance } {
# Variable containg name of library into which module is compiled
# Recommendation: <module_name>
# Required
utilities_xmdf::xmdfSetData $instance Module Attributes Name v6_pcie_v1_3}
# ::v6_pcie_v1_3_xmdf::xmdfInit

# Function called by client to fill in all the xmdf* data variables
# based on the current settings of the parameters
proc ::v6_pcie_v1_3_xmdf::xmdfApplyParams { instance } {

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

# PIO Verilog Example design files
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_64.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_64_RX_ENGINE.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_64_TX_ENGINE.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_EP.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/EP_MEM.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_EP_MEM_ACCESS.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/PIO_TO_CTRL.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/pcie_app_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/xilinx_pcie_2_0_ep_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

# V-6 Verilog simulation files
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pcie_2_0_rport_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/xilinx_pcie_2_0_rport_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_usrapp_pl.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_expect_tasks.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_usrapp_cfg.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_usrapp_com.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_usrapp_rx.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/dsport/pci_exp_usrapp_tx.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/board.f
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/board.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/board_common.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/simulate_mti.do
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/simulate_ncsim.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/simulate_vcs.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/xilinx_lib_vcs.f
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/example_design/xilinx_pcie_2_0_ep_v6_04_lane_gen2_xc6vlx240t-ff1156-1_ML605.ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ucf
utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module xilinx_pcie_2_0_ep_v6.v
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/sys_clk_gen.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/functional/sys_clk_gen_ds.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/tests/sample_tests1.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/simulation/tests/tests.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilogsim
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/gtx_tx_sync_rate_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/gtx_wrapper_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/gtx_rx_valid_filter_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_upconfig_fix_3451_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_2_0_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_bram_top_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_bram_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_brams_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_clocking_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_gtx_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_pipe_lane_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_pipe_misc_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_pipe_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/pcie_reset_delay_v6.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/source/v6_pcie_v1_3.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
utilities_xmdf::xmdfSetData $instance FileSet $fcount toplevel true
incr fcount


# Implementation scripts and project files
utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/implement/implement.bat
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/implement/implement.sh
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/implement/xilinx_pcie_2_0_ep_v6.prj
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/implement/xilinx_pcie_2_0_ep_v6.cmd
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3/implement/xilinx_pcie_2_0_ep_v6.xcf
utilities_xmdf::xmdfSetData $instance FileSet $fcount type Ignore
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3.veo
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog_template
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3.xco
utilities_xmdf::xmdfSetData $instance FileSet $fcount type coregen_ip
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path v6_pcie_v1_3_xmdf.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

}

# ::v6_pcie_v1_3_xmdf::xmdfApplyParams

