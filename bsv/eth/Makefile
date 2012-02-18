##
## Makefile
##

BTEST     ?= GMACTB
ITEST     ?= GMACTB

OBJ       ?= obj
RTL       ?= rtl
BSV       ?= bsv
BSVTST    ?= .
BSVAPP    ?= bsv/app
BSVTOP    ?= bsv/top
BSVINF    ?= bsv/inf
BSVAXI    ?= bsv/axi
BSVDIRS   ?= ../app:../axi:../dev:../inf:../prm:../top:../tst:../utl:../wip:../wrk:../pci
#BSVDIRS   ?= ../app:../axi:../dev:../inf:../prm:../top:../tst:../utl:../wip:../wrk:../pci:../eth

OCPI_DIR  ?= (shell pwd)

default:
	make bsim

regress:
	make clean
	make TEST=TB1 bsim

err:
	if !(grep -c PASSED log) then exit 2; fi

######################################################################
bsim: $(OBJ)

	# compile to bluesim backend
	bsc -u -sim -elab \
  -keep-inlined-boundaries  \
  -no-warn-action-shadowing \
  -aggressive-conditions \
  -keep-fires \
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
isim: $(OBJ)

	# compile to verilog backend for ISim
	bsc -u -verilog -elab \
  -keep-inlined-boundaries \
  -no-warn-action-shadowing \
  -aggressive-conditions \
  -no-show-method-conf \
  -vdir $(RTL) -bdir $(OBJ) -simdir $(OBJ) \
  -p $(BSVDIRS):lib:+ \
  -D USE_DEBUGLOGIC \
  $(BSVTST)/$(ITEST).bsv
	
	bsc -vsim isim -vdir $(RTL) -bdir $(OBJ) -vsearch $(VLG_HDL):+ -e mk$(ITEST) -o runsim
	./runsim -testplusarg bscvcd

######################################################################
$(OBJ):
	@mkdir -p $(OBJ)
######################################################################

clean:
	./cleanall
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

