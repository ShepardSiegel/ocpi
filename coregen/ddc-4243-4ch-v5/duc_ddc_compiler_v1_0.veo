/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used             *
*     solely for design, simulation, implementation and creation of            *
*     design files limited to Xilinx devices or technologies. Use              *
*     with non-Xilinx devices or technologies is expressly prohibited          *
*     and immediately terminates your license.                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"            *
*     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                  *
*     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION          *
*     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION              *
*     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS                *
*     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                  *
*     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE         *
*     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY                 *
*     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                  *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          *
*     FOR A PARTICULAR PURPOSE.                                                *
*                                                                              *
*     Xilinx products are not intended for use in life support                 *
*     appliances, devices, or systems. Use in such applications are            *
*     expressly prohibited.                                                    *
*                                                                              *
*     (c) Copyright 1995-2009 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/
// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
duc_ddc_compiler_v1_0 YourInstanceName (
	.clk(clk),
	.data_resetn(data_resetn),
	.sdata_valid(sdata_valid),
	.sdata_ready(sdata_ready),
	.sdata_r(sdata_r), // Bus [15 : 0] 
	.mdata_valid(mdata_valid),
	.mdata_ready(mdata_ready),
	.mdata_last(mdata_last),
	.mdata_clean(mdata_clean),
	.mdata_i(mdata_i), // Bus [15 : 0] 
	.mdata_q(mdata_q), // Bus [15 : 0] 
	.sreg_presetn(sreg_presetn),
	.sreg_paddr(sreg_paddr), // Bus [11 : 0] 
	.sreg_psel(sreg_psel),
	.sreg_penable(sreg_penable),
	.sreg_pwrite(sreg_pwrite),
	.sreg_pwdata(sreg_pwdata), // Bus [31 : 0] 
	.sreg_pready(sreg_pready),
	.sreg_prdata(sreg_prdata), // Bus [31 : 0] 
	.sreg_pslverr(sreg_pslverr),
	.int_missinput(int_missinput),
	.int_errpacket(int_errpacket),
	.int_lostoutput(int_lostoutput),
	.int_ducddc(int_ducddc));

// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file duc_ddc_compiler_v1_0.v when simulating
// the core, duc_ddc_compiler_v1_0. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

