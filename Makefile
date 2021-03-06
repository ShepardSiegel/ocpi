##
## Makefile
##
BTEST     ?= TB2
BTEST1    ?= TB1
BTEST7    ?= TB7
BTEST8    ?= TB8
BTEST14   ?= TB14
BTEST15   ?= TB15
BTEST16   ?= TB16
BTEST17   ?= TB17
BTEST18   ?= TB18
BTEST19   ?= TB19
BTEST_WMEMI ?= WmemiTB
ITEST     ?= TB2
ITEST1    ?= TB1
ITEST7    ?= TB7
ITEST8    ?= TB8
ITEST10   ?= TB10
ITEST11   ?= TB11
ITEST12   ?= TB12
ITEST13   ?= TB13
ITEST15   ?= TB15
ITEST16   ?= TB16
ITEST17   ?= TB17
ITEST18   ?= TB18
ITEST19   ?= TB19
OPED      ?= OPED
A4LS      ?= A4LS
NFT       ?= TB_nft

## 14 OpenCPI FPGA Board Platforms...
## See $OPCPI/doc/OpenCPI-BoardsDevices.pdf
P_ML555   ?= FTop_ml555
P_ALDER   ?= FTop_alder
P_SCHIST  ?= FTop_schist
P_XUPV5   ?= FTop_xupv5
P_BIOTITE ?= FTop_biotite
P_NF10    ?= FTop_nf10
P_ILLITE  ?= FTop_illite
P_ML605   ?= FTop_ml605
P_SP605   ?= FTop_sp605
P_ALCY4   ?= FTop_alcy4
P_ALST4   ?= FTop_alst4
P_HTGS4   ?= FTop_htgs4
P_KC705   ?= FTop_kc705
P_VC707   ?= FTop_vc707
P_N210    ?= FTop_n210

OBJ       ?= obj
RTL       ?= rtl
BSV       ?= bsv
BSVTST    ?= bsv/tst
BSVAPP    ?= bsv/app
BSVTOP    ?= bsv/top
BSVINF    ?= bsv/inf
BSVAXI    ?= bsv/axi
BSVDIRS   ?= ./bsv/app:./bsv/axi:./bsv/dev:./bsv/inf:./bsv/prm:./bsv/top:./bsv/tst:./bsv/utl:./bsv/wip:./bsv/wrk:./bsv/pci:./bsv/eth:./bsv/pwk:./bsv/dpp

OCAPP_S0    ?= OCApp_scenario0
OCAPP_S1    ?= OCApp_scenario1
OCAPP_S2    ?= OCApp_scenario2
OCAPP_S3a   ?= OCApp_scenario3a
OCAPP_S3b   ?= OCApp_scenario3b
OCAPP_S4    ?= OCApp_scenario4

VLG_HDL   = libsrc/hdl/ocpi
VHD_HDL   = libsrc/hdl/vhd
BSV_HDL   = libsrc/hdl/bsv

# Select if we use the local or opencpi-referenced build - only uncomment one of these..
# scripts/buildhdl was the "original" self-contained ocpi upstream dir. No longer the default.
# if using buildocpi, be sure the env var $OCPI_BASE_DIR is set to point to the opencpi root.
# To use buildocpi, pull down the opencpi.org disti (limk on next line) and place it in a peer directory
# https://github.com/opencpi/opencpi
#
BUILD_HDL = scripts/buildhdl
#BUILD_HDL = scripts/buildocpi

OCPI_DIR  ?= (shell pwd)

default:
	make bsim

regress:
	make clean
	make TEST=TB1 bsim

tar:
	make clean
	tar czvf ../ocpi-`date +%Y%m%d_%H%M`.tar.-gz .

drop:
	make clean
	cp -r . ../safe/ocpi-`date +%Y%m%d_%H%M`
	echo Removing build directory and sub-directories
	rm -fR build
	tar czvf ../ocpi-`date +%Y%m%d_%H%M`.tar.-gz .

err:
	if !(grep -c PASSED log) then exit 2; fi

######################################################################
bsim: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST).bexe -e mk$(BTEST) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST).bexe -V


######################################################################
bsim1: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST1).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST1).bexe -e mk$(BTEST1) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST1).bexe -V


######################################################################
bsim7: $(OBJ)

	# compile to bluesim backend
	echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST7).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST7).bexe -e mk$(BTEST7) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST7).bexe -V


######################################################################
bsim8: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST8).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST8).bexe -e mk$(BTEST8) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST8).bexe -V

######################################################################
bsim14: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST14).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST14).bexe -e mk$(BTEST14) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST14).bexe -V

######################################################################
bsim15: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST15).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST15).bexe -e mk$(BTEST15) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST15).bexe -V

######################################################################
bsim16: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST16).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST16).bexe -e mk$(BTEST16) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST16).bexe -V

######################################################################
bsim17: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(BTEST17).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST17).bexe -e mk$(BTEST17) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST17).bexe -V

######################################################################
bsim18: $(OBJ)

	# compile to bluesim backend
	#echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-keep-fires \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		$(BSVTST)/$(BTEST18).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries -keep-fires \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST18).bexe -e mk$(BTEST18) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST18).bexe -V

######################################################################
bsim19: $(OBJ)

	# compile to bluesim backend
	bsc -u -sim -elab -keep-inlined-boundaries -no-warn-action-shadowing \
	-aggressive-conditions \
	-keep-fires \
	-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
	-p $(BSVDIRS):lib:+ \
	-D DEFINE_NDW=1 \
	-D USE_NDW1 \
	$(BSVTST)/$(BTEST19).bsv

	# create bluesim executable
	bsc -sim -keep-inlined-boundaries -keep-fires \
	-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
	-o $(OBJ)/mk$(BTEST19).bexe -e mk$(BTEST19) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST19).bexe -V

######################################################################
bsim_wmemi: $(OBJ)

  # compile to bluesim backend
	bsc -u -sim -elab -keep-inlined-boundaries \
  -aggressive-conditions \
  -vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
  -p $(BSVDIRS):lib:+ \
   $(BSVTST)/$(BTEST_WMEMI).bsv

  # create bluesim executable
	bsc -sim -keep-inlined-boundaries \
  -vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
  -o $(OBJ)/mk$(BTEST_WMEMI).bexe -e mk$(BTEST_WMEMI) $(OBJ)/*.ba
	
  # run bluesim executable
	$(OBJ)/mk$(BTEST_WMEMI).bexe -V

######################################################################
vcs: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -info-dir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW4 \
		-D USE_DEBUGLOGIC \
		$(BSVTST)/$(NFT).bsv
	
	bsc -vsim vcs -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(NFT) -o runsim
	./runsim | tee tmp

######################################################################
isim: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		$(BSVTST)/$(ITEST).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim1: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST1).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST1) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim7: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST7).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST7) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim8: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST8).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST8) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim10: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST10).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST10) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim11: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST11).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST11) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim12: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST12).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST12) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
isim13: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST13).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST13) -o runsim
	./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim15: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST15).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST15) -o runsim
	./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim16: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST16).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST16) -o runsim
	./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim17: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST17).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST17) -o runsim
	./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim18: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		$(BSVTST)/$(ITEST18).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST18) -o runsim
	# uncomment next line to run
	#./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim19: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-D USE_NDW1 \
		$(BSVTST)/$(ITEST19).bsv

	bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST19) -o runsim
	# uncomment next line to run
	#./runsim -testplusarg bscvcd

######################################################################
vls18: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		$(BSVTST)/$(ITEST18).bsv

	# Holding place for Vivado build scripts
	#bsc -vsim isim -D BSV_TIMESCALE=1ns/1ps -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST18) -o runsim
	# uncomment next line to run
	#./runsim -testplusarg bscvcd

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
isim18vhd: $(OBJ)

  # Ensure BSV mkBiasWorker4B Verilog does not exist in path...
	rm -f rtl/mkBiasWorker4B.v

	vhpcomp -work ocpi \
	$(VHD_HDL)/ocpi_ocp.vhd \
	$(VHD_HDL)/ocpi_types.vhd \
	$(VHD_HDL)/ocpi_wci.vhd \
	$(VHD_HDL)/ocpi_worker.vhd \
	$(VHD_HDL)/ocpi_types_body.vhd \
	$(VHD_HDL)/ocpi_wci_body.vhd  \
	$(VHD_HDL)/ocpi_wci_impl.vhd  \
	$(VHD_HDL)/ocpi_props.vhd \
	$(VHD_HDL)/ocpi_props_impl.vhd

	vhpcomp -work work $(VHD_HDL)/bias_vhdl_defs.vhd $(VHD_HDL)/bias_vhdl_impl.vhd $(VHD_HDL)/bias_vhdl_skel.vhd 

	vlogcomp -work work $(VHD_HDL)/mkBiasWorker4B.v $(BSV_HDL)/FIFO2.v

	fuse -v 0 -o runsim.isim -prj /tmp/fuse.prj.qn7779 \
	-sourcelibdir rtl \
	-sourcelibdir libsrc/hdl/vhd \
	-sourcelibdir libsrc/hdl/ocpi \
	-sourcelibdir /opt/Bluespec/Bluespec-2012.09.beta1B/lib/Libraries \
	-sourcelibdir /opt/Bluespec/Bluespec-2012.09.beta1B/lib/Verilog \
	-sourcelibext .v \
	-d TOP=mkTB18 \
	-d BSV_TIMESCALE=1ns/1ps \
	-L unisims_ver \
	-L ocpi \
	-L work \
	-t worx_mkTB18.glbl \
	-t worx_mkTB18.main 


######################################################################
verilog_scenario0: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S0).bsv 
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario0.v

verilog_scenario1: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S1).bsv
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario1.v

verilog_scenario1_ndw4: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW4 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S1).bsv
	cp $(RTL)/mkOCApp16B.v $(RTL)/mkOCApp16B_scenario1.v

verilog_scenario2: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S2).bsv
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario2.v

verilog_scenario3a: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S3a).bsv
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario3a.v

verilog_scenario3b: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S3b).bsv
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario3b.v

verilog_scenario4: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -D USE_NDW1 -D USE_DEBUGLOGIC -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S4).bsv
	cp $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario4.v

######################################################################
verilog_sp605: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-verilog-filter basicinout $(BSVTOP)/$(P_SP605).bsv

######################################################################
verilog_oped: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf -keep-fires \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-verilog-filter basicinout $(BSVINF)/$(OPED).bsv

######################################################################
verilog_a4ls: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-verilog-filter basicinout $(BSVAXI)/$(A4LS).bsv

######################################################################
platform_ml555: $(OBJ)
	
	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-D USE_NDW1 \
		-D USE_SRLFIFO \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML555).bsv

######################################################################
platform_schist: $(OBJ)
	
	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-verilog-filter basicinout $(BSVTOP)/$(P_SCHIST).bsv


######################################################################
platform_nf10: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_SRLFIFO \
		-verilog-filter basicinout $(BSVTOP)/$(P_NF10).bsv


######################################################################
platform_xupv5: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-verilog-filter basicinout $(BSVTOP)/$(P_XUPV5).bsv


######################################################################
platform_ml605: $(OBJ)

	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-remove-dollar \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW4 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-D HAS_DEVICE_DNA \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML605).bsv

######################################################################
platform_kc705: $(OBJ)

	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-show-range-conflict \
		-remove-dollar \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		+RTS -K11M -RTS \
		-verilog-filter basicinout $(BSVTOP)/$(P_KC705).bsv

######################################################################
platform_vc707: $(OBJ)

	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-remove-dollar \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW4 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-verilog-filter basicinout $(BSVTOP)/$(P_VC707).bsv

######################################################################
platform_alst4: $(OBJ)

	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D ALTERA_100MHZ_SYS0CLK \
		-verilog-filter basicinout $(BSVTOP)/$(P_ALST4).bsv

######################################################################
platform_htgs4: $(OBJ)

	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-verilog-filter basicinout $(BSVTOP)/$(P_HTGS4).bsv

######################################################################
platform_ml605_ndw1_nodebug: $(OBJ)

	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_SRLFIFO \
		-D HAS_DEVICE_DNA \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML605).bsv

platform_ml605_ndw1_debug: $(OBJ)

	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-D HAS_DEVICE_DNA \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML605).bsv

platform_ml605_ndw4_nodebug: $(OBJ)

	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW4 \
		-D USE_SRLFIFO \
		-D HAS_DEVICE_DNA \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML605).bsv

platform_ml605_ndw4_debug: $(OBJ)

	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW4 \
		-D USE_DEBUGLOGIC \
		-D USE_SRLFIFO \
		-D HAS_DEVICE_DNA \
		-verilog-filter basicinout $(BSVTOP)/$(P_ML605).bsv

platform_n210: $(OBJ)

	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D USE_NDW1 \
		-D USE_DEBUGLOGIC \
		-D HAS_DEVICE_DNA \
		-D USE_SRLFIFO \
		-D SPARTAN \
		-verilog-filter basicinout $(BSVTOP)/$(P_N210).bsv


######################################################################
$(OBJ):
	@mkdir -p $(OBJ)

######################################################################

clean:
	sim/tb/cleanall
	rm -fR $(OBJ) dump* *.sched bsv/*~ rtl/*~
	rm -fR novas.rc nWaveLog schedule* vfastLog veriwell*
	rm -fR isim.* fuse.log out out.* isim runsim runsim.*
	rm -fR sim/isim/tb/isim
	rm -fR sim/isim
	rm -fR sim/isim.wdb 
	rm -fR sim/my_sim.exe
	rm -fR synth/*.ngc
	rm -fR synth/*.xrpt
	rm -fR synth/*.srp
	rm -fR synth/*.ngr
	rm -fR synth/*.lso
	rm -fR synth/xst
	rm -fR synth/_xmsgs
	rm -fR info obj
	rm -fR `find . -name \*~`
	rm -fR bin/*.log
	rm -fR scripts/_impactbatch.log
	rm -fR fuse.xmsgs fuseRelaunch.cmd
	mkdir obj

clean-isim:
	rm -fR isim.* isim fuse.log runsim runsim.*

clean-all:
	make clean
	echo Removing mkFoo Verilogs from rtl dir...
	rm -fR rtl/mk*
	echo Removing build directory and sub-directories
	rm -fR build

bsv_v6:
	cd scripts/buildhdl; xst -ifn bsvprims_v6.xst
	cp scripts/buildhdl/xst/bsv/bsv* lib/hdl/bsv/bsv_v6

ml555:
	mkdir -p build
	rm -rf build/tmp-ml555
	cp -r $(BUILD_HDL) build/tmp-ml555
	cp ucf/ml555.ucf build/tmp-ml555
	cp ucf/ml555.xcf build/tmp-ml555
	cd build/tmp-ml555; ./build_fpgaTop ml555
	mv build/tmp-ml555 build/ml555-`date +%Y%m%d_%H%M`
	echo ml555 Build complete

ml555nf:
	mkdir -p build
	rm -rf build/tmp-ml555nf
	cp -r $(BUILD_HDL) build/tmp-ml555nf
	cp ucf/ml555nf.ucf build/tmp-ml555nf
	cp ucf/ml555nf.xcf build/tmp-ml555nf
	cd build/tmp-ml555nf; ./build_fpgaTop ml555nf
	mv build/tmp-ml555nf build/ml555nf-`date +%Y%m%d_%H%M`
	echo ml555nf Build complete

xupv5:
	mkdir -p build
	rm -rf build/tmp-xupv5
	cp -r $(BUILD_HDL) build/tmp-xupv5
	cp ucf/xupv5.ucf build/tmp-xupv5
	cp ucf/xupv5.xcf build/tmp-xupv5
	cd build/tmp-xupv5; ./build_fpgaTop xupv5
	mv build/tmp-xupv5 build/xupv5-`date +%Y%m%d_%H%M`
	echo xupv5 Build complete

alder:
	mkdir -p build
	rm -rf build/tmp-alder
	cp -r $(BUILD_HDL) build/tmp-alder
	cp ucf/alder.ucf build/tmp-alder
	cp ucf/alder.xcf build/tmp-alder
	cd build/tmp-alder; ./build_fpgaTop alder
	mv build/tmp-alder build/alder-`date +%Y%m%d_%H%M`
	echo alder Build complete

schist:
	mkdir -p build
	rm -rf build/tmp-schist
	cp -r $(BUILD_HDL) build/tmp-schist
	cp ucf/schist.ucf build/tmp-schist
	cp ucf/schist.xcf build/tmp-schist
	cd build/tmp-schist; ./build_fpgaTop schist
	mv build/tmp-schist build/schist-`date +%Y%m%d_%H%M`
	echo schist Build complete

schistnf:
	mkdir -p build
	rm -rf build/tmp-schistnf
	cp -r $(BUILD_HDL) build/tmp-schistnf
	cp ucf/schistnf.ucf build/tmp-schistnf
	cp ucf/schistnf.xcf build/tmp-schistnf
	cd build/tmp-schistnf; ./build_fpgaTop schistnf
	mv build/tmp-schistnf build/schistnf-`date +%Y%m%d_%H%M`
	echo schistnf Build complete

illite:
	mkdir -p build
	rm -rf build/tmp-illite
	cp -r $(BUILD_HDL) build/tmp-illite
	cp ucf/illite.ucf build/tmp-illite
	cp ucf/illite.xcf build/tmp-illite
	cd build/tmp-illite; ./build_fpgaTop illite
	mv build/tmp-illite build/illite-`date +%Y%m%d_%H%M`
	echo illite Build complete

nf10:
	mkdir -p build
	rm -rf build/tmp-nf10
	cp -r $(BUILD_HDL) build/tmp-nf10
	cp ucf/nf10.ucf build/tmp-nf10
	cp ucf/nf10.xcf build/tmp-nf10
	cd build/tmp-nf10; ./build_fpgaTop nf10
	mv build/tmp-nf10 build/nf10-`date +%Y%m%d_%H%M`
	echo nf10 Build complete

biotite:
	mkdir -p build
	rm -rf build/tmp-biotite
	cp -r $(BUILD_HDL) build/tmp-biotite
	cp ucf/biotite.ucf build/tmp-biotite
	cp ucf/biotite.xcf build/tmp-biotite
	cd build/tmp-biotite; ./build_fpgaTop biotite
	mv build/tmp-biotite build/biotite-`date +%Y%m%d_%H%M`
	echo biotite Build complete

ml605:
	mkdir -p build
	rm -rf build/tmp-ml605
	cp -r $(BUILD_HDL) build/tmp-ml605
	cp ucf/ml605.ucf build/tmp-ml605
	cp ucf/ml605.xcf build/tmp-ml605
	cd build/tmp-ml605; ./build_fpgaTop ml605
	mv build/tmp-ml605 build/ml605-`date +%Y%m%d_%H%M`
	echo ml605 Build complete

ml605es:
	mkdir -p build
	rm -rf build/tmp-ml605es
	cp -r $(BUILD_HDL) build/tmp-ml605es
	cp ucf/ml605es.ucf build/tmp-ml605es
	cp ucf/ml605es.xcf build/tmp-ml605es
	cd build/tmp-ml605es; ./build_fpgaTop ml605es
	mv build/tmp-ml605es build/ml605es-`date +%Y%m%d_%H%M`
	echo ml605es Build complete

ml605x:
	mkdir -p build
	rm -rf build/tmp-ml605x
	cp -r $(BUILD_HDL) build/tmp-ml605x
	cp ucf/ml605x.ucf build/tmp-ml605x
	cp ucf/ml605x.xcf build/tmp-ml605x
	cd build/tmp-ml605x; ./build_fpgaTop ml605x
	mv build/tmp-ml605x build/ml605x-`date +%Y%m%d_%H%M`
	echo ml605x Build complete

sp605:
	mkdir -p build
	rm -rf build/tmp-sp605
	cp -r $(BUILD_HDL) build/tmp-sp605
	cp ucf/sp605.ucf build/tmp-sp605
	cp ucf/sp605.xcf build/tmp-sp605
	cd build/tmp-sp605; ./build_fpgaTop sp605
	mv build/tmp-sp605 build/sp605-`date +%Y%m%d_%H%M`
	echo sp605 Build complete

kc705:
	mkdir -p build
	rm -rf build/tmp-kc705
	cp -r $(BUILD_HDL) build/tmp-kc705
	cp ucf/kc705.ucf build/tmp-kc705
	cp ucf/kc705.xcf build/tmp-kc705
	cd build/tmp-kc705; ./build_fpgaTop kc705
	mv build/tmp-kc705 build/kc705-`date +%Y%m%d_%H%M`
	echo kc705 Build complete

vc707:
	mkdir -p build
	rm -rf build/tmp-vc707
	cp -r $(BUILD_HDL) build/tmp-vc707
	cp ucf/vc707.ucf build/tmp-vc707
	cp ucf/vc707.xcf build/tmp-vc707
	cd build/tmp-vc707; ./build_fpgaTop vc707
	mv build/tmp-vc707 build/vc707-`date +%Y%m%d_%H%M`
	echo vc707 Build complete

n210:
	mkdir -p build
	rm -rf build/tmp-n210
	cp -r $(BUILD_HDL) build/tmp-n210
	cp ucf/n210.ucf build/tmp-n210
	cp ucf/n210.xcf build/tmp-n210
	cd build/tmp-n210; ./build_fpgaTop n210
	mv build/tmp-n210 build/n210-`date +%Y%m%d_%H%M`
	echo n210 Build complete

n210tmp:
	mkdir -p build
	rm -rf build/tmp-n210
	cp -r $(BUILD_HDL) build/tmp-n210
	cp ucf/n210.ucf build/tmp-n210
	cp ucf/n210.xcf build/tmp-n210
	cd build/tmp-n210; ./build_fpgaTop n210
	mv build/tmp-n210 build/n210-`date +%Y%m%d_%H%M`
	echo n210 Build complete

build_all:
	make verilog_v5
	make ml555
	make xupv5
	make alder
	make schist
	make illite
	make biotite
	make verilog_v6
	make ml605
	make sp605
	make kc705
	make vc707

