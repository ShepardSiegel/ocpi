#!/bin/bash
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

QUARTUS_ROOTDIR='d:/altera/10.1/quartus'
PHY_TYPE_STRATIXVGX=0

cat sim_filelist | grep "\.v" | sed -e "/_icm.v/ s/^/-v /g" -e "/example_.*_top/ s/^/-v /g" -e "/altpcie_/ s/^/-v /g" > sim_filelist.f
if [ `cat sim_filelist | grep -c "\.sv"` != 0 ]
then
   cat sim_filelist | grep "\.sv" | sed "s/^/+sv -v /g"                                                  >> sim_filelist.f
fi

echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/220model.v"                                                        >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v"                                                       >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/sgate.v"                                                           >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiigx_hssi_atoms.v"                                          >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/libraries/megafunctions/alt2gxb.v"                                             >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_hssi_atoms.v"                                            >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixiv_pcie_hip_atoms.v"                                        >> sim_filelist.f
if [ $PHY_TYPE_STRATIXVGX == 0 ]
then
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_hssi_atoms.v"                                           >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaii_pcie_hip_atoms.v"                                       >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_hssi_atoms.v"                                         >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/arriaiigz_pcie_hip_atoms.v"                                     >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_hssi_atoms.v"                                         >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cycloneiv_pcie_hip_atoms.v"                                     >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_hssi_atoms.v"                                        >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/hardcopyiv_pcie_hip_atoms.v"                                    >> sim_filelist.f
fi

echo "+sv -v $QUARTUS_ROOTDIR/eda/sim_lib/altera_lnsim.sv"                                               >> sim_filelist.f
echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/altera_primitives.v"                                               >> sim_filelist.f

if [ $PHY_TYPE_STRATIXVGX == 1 ]
then
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_hssi_atoms.v"                                          >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/stratixv_pcie_hip_atoms.v"                                      >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cadence/stratixv_hssi_atoms_ncrypt.v"                           >> sim_filelist.f
   echo "-v $QUARTUS_ROOTDIR/eda/sim_lib/cadence/stratixv_pcie_hip_atoms_ncrypt.v"                       >> sim_filelist.f
fi

ncverilog -ALLOWREDEFINITION +DEFINE+VCS -f sim_filelist.f +incdir+../../common/testbench/+../../common/incremental_compile_module -l transcript
