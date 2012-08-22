#!/bin/sh
lsusb | grep Xilinx
$XILINX/bin/lin64/impact -batch <<FOO 2> /dev/null | grep chain
setMode -bs
setCable -port $1
Identify
closeCable
Exit
FOO
rm _impactbatch.log
