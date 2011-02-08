wave add -r /
vcd dumpfile dump.vcd
vcd dumpvars -m /main -l 0
vcd dumpon
run all
vcd flush
