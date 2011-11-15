#!/bin/bash

#-----------------------------------------------------------------------------
# Command to run the planAhead in batch mode
#-----------------------------------------------------------------------------

rm -rf results
mkdir results
cd results

planAhead -mode batch -source ../planAhead_rdn.tcl

#end
