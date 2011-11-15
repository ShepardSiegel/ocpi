
rem #-------------------------------------------------------------------------
rem # Command to run the planAhead in batch mode
rem #-------------------------------------------------------------------------

rem Clean up the results directory

rmdir /S /Q results
mkdir results
cd results

planAhead -mode batch -source ..\planAhead_rdn.tcl

