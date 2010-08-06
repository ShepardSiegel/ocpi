# The package naming convention is <core_name>_xmdf
package provide duc_ddc_compiler_v1_0_xmdf 1.0

# This includes some utilities that support common XMDF operations
package require utilities_xmdf

# Define a namespace for this package. The name of the name space
# is <core_name>_xmdf
namespace eval ::duc_ddc_compiler_v1_0_xmdf {
# Use this to define any statics
}

# Function called by client to rebuild the params and port arrays
# Optional when the use context does not require the param or ports
# arrays to be available.
proc ::duc_ddc_compiler_v1_0_xmdf::xmdfInit { instance } {
# Variable containg name of library into which module is compiled
# Recommendation: <module_name>
# Required
utilities_xmdf::xmdfSetData $instance Module Attributes Name duc_ddc_compiler_v1_0
}
# ::duc_ddc_compiler_v1_0_xmdf::xmdfInit

# Function called by client to fill in all the xmdf* data variables
# based on the current settings of the parameters
proc ::duc_ddc_compiler_v1_0_xmdf::xmdfApplyParams { instance } {

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

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2.cfg
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s1.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s2.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s3.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s4.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s5.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path ddc_chbw1_C4_pb10_if1_frf61_os2_s6.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3.cfg
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3_s1.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3_s2.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3_s3.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3_s4.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_chbw5_C1_pb5_if0_frf122_os3_s5.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0.asy
utilities_xmdf::xmdfSetData $instance FileSet $fcount type asy
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0.ngc
utilities_xmdf::xmdfSetData $instance FileSet $fcount type ngc
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0.v
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0.veo
utilities_xmdf::xmdfSetData $instance FileSet $fcount type verilog_template
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0.xco
utilities_xmdf::xmdfSetData $instance FileSet $fcount type coregen_ip
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s1_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s1_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s2_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s2_f0COEFF_auto_HALFBAND_CENTRE0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s2_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s3_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s3_f0COEFF_auto_HALFBAND_CENTRE0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s3_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s4_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s4_f0COEFF_auto_HALFBAND_CENTRE0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s4_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s5_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s5_f0COEFF_auto_HALFBAND_CENTRE0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s5_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_0.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_1.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_2.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_3.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_4.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_5.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0COEFF_auto0_6.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_s6_f0filt_decode_rom.mif
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount relative_path duc_ddc_compiler_v1_0_xmdf.tcl
utilities_xmdf::xmdfSetData $instance FileSet $fcount type AnyView
incr fcount

utilities_xmdf::xmdfSetData $instance FileSet $fcount associated_module duc_ddc_compiler_v1_0
incr fcount

}

# ::gen_comp_name_xmdf::xmdfApplyParams
