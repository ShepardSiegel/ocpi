#-----------------------------------------------------------------------------
# Copyright ??? 2010 Altera Corporation. All rights reserved.  Altera products are
# protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
# other intellectual property laws.
#
# This reference design file, and your use thereof, is subject to and governed by
# the terms and conditions of the applicable Altera Reference Design License Agreement.
# By using this reference design file, you indicate your acceptance of such terms and
# conditions between you and Altera Corporation.  In the event that you do not agree with
# such terms and conditions, you may not use the reference design file. Please promptly
# destroy any copies you have made.
#
# This reference design file being provided on an "as-is" basis and as an accommodation
# and therefore all warranties, representations or guarantees of any kind
# (whether express, implied or statutory) including, without limitation, warranties of
# merchantability, non-infringement, or fitness for a particular purpose, are
# specifically disclaimed.  By making this reference design file available, Altera
# expressly does not recommend, suggest or require that this reference design file be
# used in combination with any other product not provided by Altera.
#-----------------------------------------------------------------------------
global env ;

set QUARTUS_ROOTDIR "/opt/altera/10.1/quartus"
set PHY_TYPE_STRATIXVGX 0
set MSIM_AE ""
set NOIMMEDCA ""

if [regexp {ModelSim ALTERA} [vsim -version]] {
   # Using Altera OEM Version need to add one more library mapping
   set altgxb_path $env(MODEL_TECH)\/../altera/verilog/altgxb ;
   set alt2gxb_path $env(MODEL_TECH)\/../altera/verilog/stratixiigx_hssi ;
   vmap altgxb_ver $altgxb_path ;
   vmap stratixiigx_hssi_ver $alt2gxb_path ;
   set MSIM_AE "-L altera_lnsim_ver -L altera_ver"
} else {
   # Using non-OEM Version, compile all of the libraries
   set NOIMMEDCA "-noimmedca"
   vlib lpm_ver
   vmap lpm_ver lpm_ver
   vlog -work lpm_ver $QUARTUS_ROOTDIR/eda/sim_lib/220model.v

   vlib altera_mf_ver
   vmap altera_mf_ver altera_mf_ver
   vlog -work altera_mf_ver $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v

   vlib sgate_ver
   vmap sgate_ver sgate_ver
   vlog -work sgate_ver $QUARTUS_ROOTDIR/eda/sim_lib/sgate.v

   vlib stratixiigx_hssi_ver
   vmap stratixiigx_hssi_ver stratixiigx_hssi_ver
   vlog -work stratixiigx_hssi_ver $QUARTUS_ROOTDIR/eda/sim_lib/stratixiigx_hssi_atoms.v
   vlog -work stratixiigx_hssi_ver $QUARTUS_ROOTDIR/libraries/megafunctions/alt2gxb.v

   if [ file exists $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v ] {

      vlib stratixiv_hssi_ver
      vmap stratixiv_hssi_ver stratixiv_hssi_ver
      vmap stratixiv_hssi stratixiv_hssi_ver
      vlog -work stratixiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v

      vlib stratixiv_pcie_hip_ver
      vmap stratixiv_pcie_hip_ver stratixiv_pcie_hip_ver
      vmap stratixiv_pcie_hip stratixiv_pcie_hip_ver
      vlog -work stratixiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v

      if { $PHY_TYPE_STRATIXVGX == 0 } {
         vlib arriaii_hssi_ver
         vmap arriaii_hssi_ver arriaii_hssi_ver
         vmap arriaii_hssi arriaii_hssi_ver
         vlog -work arriaii_hssi $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_hssi_atoms.v

         vlib arriaii_pcie_hip_ver
         vmap arriaii_pcie_hip_ver arriaii_pcie_hip_ver
         vmap arriaii_pcie_hip arriaii_pcie_hip_ver
         vlog -work arriaii_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_pcie_hip_atoms.v

         vlib arriaiigz_hssi_ver
         vmap arriaiigz_hssi_ver arriaiigz_hssi_ver
         vmap arriaiigz_hssi arriaiigz_hssi_ver
         vlog -work arriaiigz_hssi $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_hssi_atoms.v

         vlib arriaiigz_pcie_hip_ver
         vmap arriaiigz_pcie_hip_ver arriaiigz_pcie_hip_ver
         vmap arriaiigz_pcie_hip arriaiigz_pcie_hip_ver
         vlog -work arriaiigz_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_pcie_hip_atoms.v

         vlib cycloneiv_hssi_ver
         vmap cycloneiv_hssi_ver cycloneiv_hssi_ver
         vmap cycloneiv_hssi cycloneiv_hssi_ver
         vlog -work cycloneiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_hssi_atoms.v

         vlib cycloneiv_pcie_hip_ver
         vmap cycloneiv_pcie_hip_ver cycloneiv_pcie_hip_ver
         vmap cycloneiv_pcie_hip cycloneiv_pcie_hip_ver
         vlog -work cycloneiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_pcie_hip_atoms.v

         vlib hardcopyiv_hssi_ver
         vmap hardcopyiv_hssi_ver hardcopyiv_hssi_ver
         vmap hardcopyiv_hssi hardcopyiv_hssi_ver
         vlog -work hardcopyiv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_hssi_atoms.v

         vlib hardcopyiv_pcie_hip_ver
         vmap hardcopyiv_pcie_hip_ver hardcopyiv_pcie_hip_ver
         vmap hardcopyiv_pcie_hip hardcopyiv_pcie_hip_ver
         vlog -work hardcopyiv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_pcie_hip_atoms.v
      } else {
         vlib stratixv_hssi_ver
         vmap stratixv_hssi_ver stratixv_hssi_ver
         vmap stratixv_hssi stratixv_hssi_ver
         vlog     -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/altera_primitives.v
         vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_hssi_atoms.v
         vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_hssi_atoms_ncrypt.v
         vlog -sv -work stratixv_hssi $QUARTUS_ROOTDIR/eda/sim_lib/altera_lnsim.sv

         vlib stratixv_pcie_hip_ver
         vmap stratixv_pcie_hip_ver stratixv_pcie_hip_ver
         vmap stratixv_pcie_hip stratixv_pcie_hip_ver
         vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_pcie_hip_atoms.v
         vlog -sv -work stratixv_pcie_hip $QUARTUS_ROOTDIR/eda/sim_lib/mentor/stratixv_pcie_hip_atoms_ncrypt.v

      }
   }
}

# Create the work library
vlib work

# Now compile the Verilog files one by one
alias _comp {
set simlist [open sim_filelist r]
while {[gets $simlist vfile] >= 0} {
    vlog +incdir+../../common/testbench/+../../common/incremental_compile_module+.. -work work $vfile
}
close $simlist
}

_comp
# Now run the simulation
alias _vsim  {
   if { $PHY_TYPE_STRATIXVGX == 0 } {
      eval vsim $NOIMMEDCA -novopt -t ps -L altera_mf_ver -L lpm_ver -L sgate_ver -L stratixiigx_hssi_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaiigz_hssi_ver -L arriaiigz_pcie_hip_ver -L cycloneiv_hssi_ver -L cycloneiv_pcie_hip_ver -L hardcopyiv_hssi_ver -L hardcopyiv_pcie_hip_ver pcie_hip_s4gx_gen2_x4_128_chaining_testbench
   } else {
      eval vsim $NOIMMEDCA -novopt -t ps $MSIM_AE -L altera_mf_ver -L lpm_ver -L sgate_ver -L stratixiigx_hssi_ver -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver pcie_hip_s4gx_gen2_x4_128_chaining_testbench
   }
}

_vsim
set NumericStdNoWarnings 1
set StdArithNoWarnings 1
onbreak { resume }

# Log all nets
# log -r /*

run -all
