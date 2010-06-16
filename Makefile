##
## Makefile
##
BTEST   ?= TB2
ITEST   ?= TB2
ITEST10 ?= TB10
RTEST5  ?= FTopV5
RTESTS6 ?= FTopS6
RTEST5a ?= FTopV5_adc
RTEST5m ?= FTopV5_mem
RTEST5g ?= FTopV5_gbe
RTEST6  ?= FTopV6
OBJ     ?= obj
RTL     ?= rtl
BSV     ?= bsv

VLG_HDL   = libsrc/hdl/ocpi
BUILD_HDL = scripts/buildhdl

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
	echo Bit#\(32\) compileTime = `date +%s`\; // Bluesim `date` > bsv/CompileTime.bsv
	bsc -u -sim -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(BTEST).bsv

	# create bluesim executable
	bsc -sim -keep-fires -keep-inlined-boundaries \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-o $(OBJ)/mk$(BTEST).bexe -e mk$(BTEST) $(OBJ)/*.ba

	# run bluesim executable
	$(OBJ)/mk$(BTEST).bexe -V


######################################################################
isim: $(OBJ)

	# compile to verilog backend for ISim
	echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(ITEST).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST) -o runsim
	./runsim 

######################################################################
isim10: $(OBJ)

	# compile to verilog backend for ISim
	#echo Bit#\(32\) compileTime = `date +%s`\; // ISim `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab \
		-keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(ITEST10).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST10) -o runsim
	./runsim 

	# create verilog executable
	#cd $(OBJ) && bsc -vsim modelsim -keep-fires -keep-inlined-boundaries -o mk$(ITEST).vexe -e mk$(ITEST) *.v

	# run verilog
	#cd $(OBJ) && mk$(ITEST).vexe > mk$(ITEST).runlog

	#@# test to be sure the word "PASSED" is in the log file
	#@ if !(grep -c PASSED $(OBJ)/mk$(ITEST).runlog) then exit 2; fi

######################################################################
verilog_s6: $(OBJ)
	
	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTESTS6).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTESTS6).v

######################################################################
verilog_v5: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTEST5).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTEST5).v

######################################################################
verilog_v5a: $(OBJ)
	
	# compile to verilog backend for RTL
	#echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTEST5a).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTEST5a).v

######################################################################
verilog_v5m: $(OBJ)
	
	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTEST5m).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTEST5m).v

######################################################################
verilog_v5g: $(OBJ)
	
	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTEST5g).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTEST5g).v

######################################################################
verilog_v6: $(OBJ)

	# compile to verilog backend for RTL
	echo Bit#\(32\) compileTime = `date +%s`\; // Verilog `date` > bsv/CompileTime.bsv
	bsc -u -verilog -elab -keep-fires -keep-inlined-boundaries -no-warn-action-shadowing \
		-aggressive-conditions -no-show-method-conf \
		-vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
		-p $(BSV):lib:+ \
		$(BSV)/$(RTEST6).bsv
	cp $(RTL)/mkFTop.v $(VLG_HDL)/mk$(RTEST6).v

$(OBJ):
	@mkdir -p $(OBJ)

######################################################################
clean:
	du -s
	rm -fR $(OBJ) dump* *.sched bsv/*~ rtl/*~
	rm -fR novas.rc nWaveLog schedule* vfastLog veriwell*
	rm -fR isim.* fuse.log out out.* isim runsim runsim.*
	rm -fR sim/isim
	rm -fR sim/isim.wdb 
	rm -fR sim/my_sim.exe
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

sx95t:
	mkdir -p build
	rm -rf build/tmp-sx95t
	cp -r $(BUILD_HDL) build/tmp-sx95t
	cp ucf/sx95t.ucf build/tmp-sx95t
	cp ucf/sx95t.xcf build/tmp-sx95t
	cd build/tmp-sx95t; ./build_fpgaTop sx95t
	mv build/tmp-sx95t build/sx95t-`date +%Y%m%d_%H%M`
	echo sx95t Build complete

lx330:
	mkdir -p build
	rm -rf build/tmp-lx330
	cp -r $(BUILD_HDL) build/tmp-lx330
	cp ucf/lx330.ucf build/tmp-lx330
	cp ucf/lx330.xcf build/tmp-lx330
	cd build/tmp-lx330; ./build_fpgaTop lx330
	mv build/tmp-lx330 build/lx330-`date +%Y%m%d_%H%M`
	echo lx330 Build complete

tx240:
	mkdir -p build
	rm -rf build/tmp-tx240
	cp -r $(BUILD_HDL) build/tmp-tx240
	cp ucf/tx240.ucf build/tmp-tx240
	cp ucf/tx240.xcf build/tmp-tx240
	cd build/tmp-tx240; ./build_fpgaTop tx240
	mv build/tmp-tx240 build/tx240-`date +%Y%m%d_%H%M`
	echo tx240 Build complete

fx130:
	mkdir -p build
	rm -rf build/tmp-fx130
	cp -r $(BUILD_HDL) build/tmp-fx130
	cp ucf/fx130.ucf build/tmp-fx130
	cp ucf/fx130.xcf build/tmp-fx130
	cd build/tmp-fx130; ./build_fpgaTop fx130
	mv build/tmp-fx130 build/fx130-`date +%Y%m%d_%H%M`
	echo fx130 Build complete

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
	make sx95t
	make lx330
	make fx130
	make verilog_v6
	make ml605
	make sp605


