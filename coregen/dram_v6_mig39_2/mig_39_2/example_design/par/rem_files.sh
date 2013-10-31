##!/bin/csh -f
##****************************************************************************
## (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##****************************************************************************
##   ____  ____
##  /   /\/   /
## /___/  \  /    Vendor                : Xilinx
## \   \   \/     Version               : 3.92
##  \   \         Application           : MIG
##  /   /         Filename              : rem_files.bat
## /___/   /\     Date Last Modified    : Mon Jul 20 2009
## \   \  /  \    Date Created          : Fri Feb 06 2009
##  \___\/\___\
##
## Device            : Virtex-6
## Design Name       : DDR3 SDRAM
## Purpose           : Batch file to remove files generated from ISE
## Reference         :
## Revision History  :
##****************************************************************************

rm -rf "../synth/__projnav"
rm -rf "../synth/xst"
rm -rf "../synth/_ngo"

rm -rf tmp
rm -rf _xmsgs

rm -rf xst
rm -rf xlnx_auto_0_xdb

rm -rf coregen.cgp
rm -rf coregen.cgc
rm -rf coregen.log

rm -rf ise_flow_results.txt
rm -rf xlnx_auto_0.ise
rm -rf example_top_vhdl.prj
rm -rf example_top.syr
rm -rf example_top.ngc
rm -rf example_top.ngr
rm -rf example_top_xst.xrpt
rm -rf example_top.bld
rm -rf example_top.ngd
rm -rf example_top_ngdbuild.xrpt
rm -rf example_top_map.map
rm -rf example_top_map.mrp
rm -rf example_top_map.ngm
rm -rf example_top.pcf
rm -rf example_top_map.ncd
rm -rf example_top_map.xrpt
rm -rf example_top_summary.xml
rm -rf example_top_usage.xml
rm -rf example_top.ncd
rm -rf example_top.par
rm -rf example_top.xpi
rm -rf smartpreview.twr
rm -rf example_top.ptwx
rm -rf example_top.pad
rm -rf example_top.unroutes
rm -rf example_top_pad.csv
rm -rf example_top_pad.txt
rm -rf example_top_par.xrpt
rm -rf example_top.twx
rm -rf example_top.bgn
rm -rf example_top.twr
rm -rf example_top.drc
rm -rf example_top_bitgen.xwbt
rm -rf example_top.bit

# Files and folders generated Coregen ChipScope Modules
rm -rf icon5.asy
rm -rf icon5.ngc
rm -rf icon5.xco
rm -rf icon5_xmdf.tcl
rm -rf icon5.gise
rm -rf icon5.ise
rm -rf icon5.xise
rm -rf icon5_flist.txt
rm -rf icon5_readme.txt
rm -rf icon5.cdc
rm -rf icon5_xdb

rm -rf ila384_8.asy
rm -rf ila384_8.ngc
rm -rf ila384_8.xco
rm -rf ila384_8_xmdf.tcl
rm -rf ila384_8.gise
rm -rf ila384_8.ise
rm -rf ila384_8.xise
rm -rf ila384_8_flist.txt
rm -rf ila384_8_readme.txt
rm -rf ila384_8.cdc
rm -rf ila384_8_xdb

rm -rf vio_async_in256.asy
rm -rf vio_async_in256.ngc
rm -rf vio_async_in256.xco
rm -rf vio_async_in256_xmdf.tcl
rm -rf vio_async_in256.gise
rm -rf vio_async_in256.ise
rm -rf vio_async_in256.xise
rm -rf vio_async_in256_flist.txt
rm -rf vio_async_in256_readme.txt
rm -rf vio_async_in256.cdc
rm -rf vio_async_in256_xdb

rm -rf vio_sync_out32.asy
rm -rf vio_sync_out32.ngc
rm -rf vio_sync_out32.xco
rm -rf vio_sync_out32_xmdf.tcl
rm -rf vio_sync_out32.gise
rm -rf vio_sync_out32.ise
rm -rf vio_sync_out32.xise
rm -rf vio_sync_out32_flist.txt
rm -rf vio_sync_out32_readme.txt
rm -rf vio_sync_out32.cdc
rm -rf vio_sync_out32_xdb

# Files and folders generated by create ise
rm -rf test_xdb
rm -rf _xmsgs
rm -rf test.gise
rm -rf test.xise
rm -rf test.xise

# Files and folders generated by ISE through GUI mode
rm -rf _ngo
rm -rf xst
rm -rf example_top.cmd_log
rm -rf example_top.lso
rm -rf example_top.prj
rm -rf example_top.stx
rm -rf example_top.ut
rm -rf example_top.xst
rm -rf example_top_guide.ncd
rm -rf example_top_prev_built.ngd
rm -rf example_top_summary.html
rm -rf par_usage_statistics.html
rm -rf usage_statistics_webtalk.html
rm -rf webtalk.log
rm -rf device_usage_statistics.html
rm -rf test.ntrc_log
