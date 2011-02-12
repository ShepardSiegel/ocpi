%  (c) Copyright 2010 Xilinx, Inc. All rights reserved.
%
%  This file contains confidential and proprietary information
%  of Xilinx, Inc. and is protected under U.S. and
%  international copyright and other intellectual property
%  laws.
%
%  DISCLAIMER
%  This disclaimer is not a license and does not grant any
%  rights to the materials distributed herewith. Except as
%  otherwise provided in a valid license issued to you by
%  Xilinx, and to the maximum extent permitted by applicable
%  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
%  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
%  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
%  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
%  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
%  (2) Xilinx shall not be liable (whether in contract or tort,
%  including negligence, or under any other theory of
%  liability) for any loss or damage of any kind or nature
%  related to, arising under or in connection with these
%  materials, including for any direct, or any indirect,
%  special, incidental, or consequential loss or damage
%  (including loss of data, profits, goodwill, or any type of
%  loss or damage suffered as a result of any action brought
%  by a third party) even if such damage or loss was
%  reasonably foreseeable or Xilinx had been advised of the
%  possibility of the same.
%
%  CRITICAL APPLICATIONS
%  Xilinx products are not designed or intended to be fail-
%  safe, or for use in any application requiring fail-safe
%  performance, such as life-support or safety devices or
%  systems, Class III medical devices, nuclear facilities,
%  applications related to the deployment of airbags, or any
%  other applications that could lead to death, personal
%  injury, or severe property or environmental damage
%  (individually and collectively, "Critical
%  Applications"). Customer assumes the sole risk and
%  liability of any use of Xilinx products in Critical
%  Applications, subject only to applicable laws and
%  regulations governing limitations on product liability.
%
%  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
%  PART OF THIS FILE AT ALL TIMES. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Compile the duc_ddc_compiler_v1_0 MEX function for the current Matlab environment
%  make_mex()
%  make_mex(export_dir,platform_dir)
%
%In
%  export_dir      Path to directory containing header file (default: ../export)
%  platform_dir    Path to directory containing library files (default: ../<platform>)
%
%Notes
%  <platform> is automatically determined from the Matlab computer varaible and will be nt, nt64, lin or lin64.
%
function []=make_mex(export_dir,platform_dir)

	platform=get_platform();
	fprintf('INFO:make_mex:Building for platform %s\n',platform);

	%Handle parameters
	if (nargin<1 || isempty(export_dir     )) export_dir     ='../export'; end
	if (nargin<2 || isempty(platform_dir   )) platform_dir   =['../' platform]; end

	%Check that directories and files required exist
	if (~isdir(export_dir)) error('ERROR:make_mex:Could not find export directory %s',export_dir); end
	if (~isdir(platform_dir))
		%Look for an optimised platform directory
		if (isdir([platform_dir 'opt']))
			platform_dir=[platform_dir 'opt'];
		else
			error('ERROR:make_mex:Could not find platform directory %s',platform_dir);
		end
	end
	if (~isfile([export_dir '/duc_ddc_compiler_v1_0_bitacc_cmodel.h'])) error('ERROR:make_mex:Could not find file duc_ddc_compiler_v1_0_bitacc_cmodel.h in the export directory'); end
	if (~isfile('duc_ddc_compiler_v1_0_bitacc_mex.cc')) error('ERROR:make_mex:Could not find file duc_ddc_compiler_v1_0_bitacc_mex.cc in the current directory'); end

	mex_cmd={};
	switch lower(platform)
		case 'nt'
			mex_cmd={'-DWIN32' '-DNT'   '-DNDEBUG' '-D_USRDLL' '-O' ['-I' export_dir] ['-L' platform_dir] 'duc_ddc_compiler_v1_0_bitacc_mex.cc' [platform_dir '/libIp_duc_ddc_compiler_v1_0_bitacc_cmodel.lib']};
		case 'nt64'
			mex_cmd={'-DWIN64' '-DNT'   '-DNDEBUG' '-D_USRDLL' '-O' ['-I' export_dir] ['-L' platform_dir] 'duc_ddc_compiler_v1_0_bitacc_mex.cc' [platform_dir '/libIp_duc_ddc_compiler_v1_0_bitacc_cmodel.lib']};
		case 'lin'
			mex_cmd={'-DLIN'   '-DUNIX' '-DNDEBUG' '-D_USRDLL' '-O' ['-I' export_dir] ['-L' platform_dir] 'duc_ddc_compiler_v1_0_bitacc_mex.cc' '-lIp_duc_ddc_compiler_v1_0_bitacc_cmodel'};
		case 'lin64'
			mex_cmd={'-DLIN64' '-DUNIX' '-DNDEBUG' '-D_USRDLL' '-O' ['-I' export_dir] ['-L' platform_dir] 'duc_ddc_compiler_v1_0_bitacc_mex.cc' '-lIp_duc_ddc_compiler_v1_0_bitacc_cmodel'};
	end
	if (isempty(mex_cmd)) error('ERROR:make_mex:Unsupported platform %s',platform); end

	err=mex(mex_cmd{:});
	if (err) error('ERROR:make_mex:Build was unsuccessful'); end

	if (ispc())
		path_var='PATH';
		lib_file='dynamic link libraries';
	else
		path_var='LD_LIBRARY_PATH';
		lib_file='shared objects';
	end

	fprintf('INFO:make_mex:Build was successful\n');
	fprintf('INFO:make_mex:With the current Matlab path the following MEX function will be used:\n');
	fprintf('INFO:make_mex:  %s\n',which('duc_ddc_compiler_v1_0_bitacc_mex'));
	fprintf('INFO:make_mex:\n');
	fprintf('INFO:make_mex:To use the MEX function, Matlab must be able to find the libraries in the platform directory\n');
	fprintf('INFO:make_mex:This can be achieved in two ways:\n');
	fprintf('INFO:make_mex:  1) Add the %s directory to the %s environment variable before staring Matlab\n',platform_dir,path_var);
	fprintf('INFO:make_mex:  2) Copy the %s from %s to a directory that is already in the library search\n',lib_file,platform_dir);

end

%Determine Xilinx platform Matlab is running on
function [platform]=get_platform()
	switch upper(computer)
		case 'PCWIN'
			platform='nt';
		case 'PCWIN64'
			platform='nt64';
		case 'GLNX86'
			platform='lin';
		case 'GLNXA64'
			platform='lin64';
		otherwise
			error('ERROR:make_mex:Unexpected platform; must be one of nt, nt64, lin or lin64')
	end
end

%Check is a file exists or not
function [x]=isfile(f)
	x=(exist(f,'file')==2);
end

%------------------------------------------------------------------------------------------------------------------------
%
%  (c) Copyright 2009 Xilinx, Inc. All rights reserved.
%
%  This file contains confidential and proprietary information
%  of Xilinx, Inc. and is protected under U.S. and
%  international copyright and other intellectual property
%  laws.
%
%  DISCLAIMER
%  This disclaimer is not a license and does not grant any
%  rights to the materials distributed herewith. Except as
%  otherwise provided in a valid license issued to you by
%  Xilinx, and to the maximum extent permitted by applicable
%  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
%  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
%  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
%  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
%  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
%  (2) Xilinx shall not be liable (whether in contract or tort,
%  including negligence, or under any other theory of
%  liability) for any loss or damage of any kind or nature
%  related to, arising under or in connection with these
%  materials, including for any direct, or any indirect,
%  special, incidental, or consequential loss or damage
%  (including loss of data, profits, goodwill, or any type of
%  loss or damage suffered as a result of any action brought
%  by a third party) even if such damage or loss was
%  reasonably foreseeable or Xilinx had been advised of the
%  possibility of the same.
%
%  CRITICAL APPLICATIONS
%  Xilinx products are not designed or intended to be fail-
%  safe, or for use in any application requiring fail-safe
%  performance, such as life-support or safety devices or
%  systems, Class III medical devices, nuclear facilities,
%  applications related to the deployment of airbags, or any
%  other applications that could lead to death, personal
%  injury, or severe property or environmental damage
%  (individually and collectively, "Critical
%  Applications"). Customer assumes the sole risk and
%  liability of any use of Xilinx products in Critical
%  Applications, subject only to applicable laws and
%  regulations governing limitations on product liability.
%
%  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
%  PART OF THIS FILE AT ALL TIMES.
