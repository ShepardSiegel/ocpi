##
## Makefile
##
BTEST     ?= TB2
BTEST7    ?= TB7
BTEST8    ?= TB8
ITEST     ?= TB2
ITEST7    ?= TB7
ITEST8    ?= TB8
ITEST10   ?= TB10
ITEST11   ?= TB11
ITEST12   ?= TB12
OPED      ?= OPED
A4LS      ?= A4LS
RTEST5    ?= FTop_ml555
RTEST5a   ?= FTop_shist
RTEST5n   ?= FTop_nf10
RTEST6    ?= FTop_ml605
RTESTS6   ?= FTop_sp605
OBJ       ?= obj
RTL       ?= rtl
BSV       ?= bsv
BSVTST    ?= bsv/tst
BSVAPP    ?= bsv/app
BSVTOP    ?= bsv/top
BSVINF    ?= bsv/inf
BSVAXI    ?= bsv/axi
BSVDIRS   ?= ./bsv/app:./bsv/axi:./bsv/dev:./bsv/inf:./bsv/prm:./bsv/top:./bsv/tst:./bsv/utl:./bsv/wip:./bsv/wrk

OCAPP_S0    ?= OCApp_scenario0
OCAPP_S1    ?= OCApp_scenario1
OCAPP_S2    ?= OCApp_scenario2
OCAPP_S3a   ?= OCApp_scenario3a
OCAPP_S3b   ?= OCApp_scenario3b
OCAPP_S4    ?= OCApp_scenario4

VLG_HDL   = libsrc/hdl/ocpi
BUILD_HDL = scripts/buildhdl

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
	echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/utl/CompileTime.bsv
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
isim: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		$(BSVTST)/$(ITEST).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST) -o runsim
	./runsim -testplusarg bsvvcd

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
	./runsim -testplusarg bsvvcd

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
	./runsim -testplusarg bsvvcd

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
	./runsim -testplusarg bsvvcd

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
	./runsim -testplusarg bsvvcd

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

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
verilog_scenario0: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S0).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario0.v

verilog_scenario1: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S1).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario1.v

verilog_scenario2: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S2).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario2.v

verilog_scenario3a: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S3a).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario3a.v

verilog_scenario3b: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S3b).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario3b.v

verilog_scenario4: $(OBJ)
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing -aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) -p $(BSVDIRS):lib:+ -verilog-filter basicinout $(BSVAPP)/$(OCAPP_S4).bsv
	mv $(RTL)/mkOCApp4B.v $(RTL)/mkOCApp4B_scenario4.v

######################################################################
verilog_sp605: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-verilog-filter basicinout $(BSVTOP)/$(RTESTS6).bsv

######################################################################
verilog_oped: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
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
		-verilog-filter basicinout $(BSVTOP)/$(RTEST5).bsv

######################################################################
platform_shist: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-verilog-filter basicinout $(BSVTOP)/$(RTEST5a).bsv


######################################################################
platform_nf10: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-verilog-filter basicinout $(BSVTOP)/$(RTEST5n).bsv


######################################################################
platform_ml605: $(OBJ)

	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/utl/CompileTime.bsv
	bsc -u -verilog -elab -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSVDIRS):lib:+ \
		-D DEFINE_NDW=1 \
		-verilog-filter basicinout $(BSVTOP)/$(RTEST6).bsv

$(OBJ):
	@mkdir -p $(OBJ)

######################################################################
clean:
	du -s
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
	mkdir obj
	du -s

clean-isim:
	rm -fR isim.* isim fuse.log runsim runsim.*

clean-all:
	make clean
	echo Removing mkFoo Verilogs from rtl dir...
	rm -fR rtl/mk*
	echo Removing build directory and sub-directories
	rm -fR build

ml555:
	mkdir -p build
	rm -rf build/tmp-ml555
	cp -r $(BUILD_HDL) build/tmp-ml555
	cp ucf/ml555.ucf build/tmp-ml555
	cp ucf/ml555.xcf build/tmp-ml555
	cd build/tmp-ml555; ./build_fpgaTop ml555
	mv build/tmp-ml555 build/ml555-`date +%Y%m%d_%H%M`
	echo ml555 Build complete

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

shist:
	mkdir -p build
	rm -rf build/tmp-shist
	cp -r $(BUILD_HDL) build/tmp-shist
	cp ucf/shist.ucf build/tmp-shist
	cp ucf/shist.xcf build/tmp-shist
	cd build/tmp-shist; ./build_fpgaTop shist
	mv build/tmp-shist build/shist-`date +%Y%m%d_%H%M`
	echo shist Build complete

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

sp605:
	mkdir -p build
	rm -rf build/tmp-sp605
	cp -r $(BUILD_HDL) build/tmp-sp605
	cp ucf/sp605.ucf build/tmp-sp605
	cp ucf/sp605.xcf build/tmp-sp605
	cd build/tmp-sp605; ./build_fpgaTop sp605
	mv build/tmp-sp605 build/sp605-`date +%Y%m%d_%H%M`
	echo sp605 Build complete


build_all:
	make verilog_v5
	make ml555
	make xupv5
	make alder
	make shist
	make illite
	make biotite
	make verilog_v6
	make ml605
	make sp605


