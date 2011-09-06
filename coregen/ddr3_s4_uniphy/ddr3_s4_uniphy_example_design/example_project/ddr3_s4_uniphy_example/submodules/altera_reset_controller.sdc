# (C) 2001-2011 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera MegaCore Function License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


# +---------------------------------------------------
# | Cut the async clear paths
# +---------------------------------------------------
set_false_path -to [get_pins -compatibility_mode -nocase *|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain*|aclr]
set_false_path -to [get_pins -compatibility_mode -nocase *|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain*|clrn]
