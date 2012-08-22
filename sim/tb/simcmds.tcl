wave add -r /
vcd dumpfile dump.vcd
vcd dumpvars -m /tb200 -l 0
vcd dumpon
run 1 us
vcd dumpflush
quit
