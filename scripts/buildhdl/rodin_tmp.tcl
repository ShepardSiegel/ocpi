read_verilog "../../libsrc/hdl/bsv/BRAM2.v"
read_verilog "../../libsrc/hdl/bsv/FIFO10.v"
read_verilog "../../libsrc/hdl/bsv/FIFO2.v"
read_verilog "../../libsrc/hdl/bsv/SizedFIFO.v"
read_verilog "../../rtl/mkSMAdapter4B.v"
read_verilog "../../rtl/mkSMAdapter8B.v"
read_verilog "../../rtl/mkSMAdapter16B.v"
read_verilog "../../rtl/mkSMAdapter32B.v"
read_verilog "../../libsrc/hdl/ocpi/SMAdapter.v"
synth_design -top SMAdapter -part xc7k70tfbg484-2 -no_iob 
opt_design
place_design
phys_opt_design
route_design
