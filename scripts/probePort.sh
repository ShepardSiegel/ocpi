#!/bin/sh
/opt/Xilinx/11.1/ISE/bin/lin64/impact -batch <<FOO 2> /dev/null | grep chain
setMode -bs
setCable -port $1
Identify
closeCable
Exit
FOO
