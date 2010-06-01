setMode -bscan
setCable -p auto
addDevice -p 1 -file fpgaTop.bit
program -p 1
saveCDF -file openCpi.cdf
quit
