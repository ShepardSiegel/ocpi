./rem_files.bat

coregen -b makeproj.bat
coregen -p . -b icon4_cg.xco
coregen -p . -b vio_async_in96_cg.xco
coregen -p . -b vio_async_in192_cg.xco
coregen -p . -b vio_sync_out32_cg.xco
coregen -p . -b vio_async_in100_cg.xco
rm *.ncf
xtclsh set_ise_prop.tcl
