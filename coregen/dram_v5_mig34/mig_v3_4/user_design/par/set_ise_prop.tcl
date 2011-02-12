project new test.ise

project set "Device Family" "virtex5"

project set "Device" "xc5vsx95t"

project set "Package" "ff1136"

project set "Speed Grade" "-2"

project set "Synthesis Tool" "XST (VHDL/Verilog)"

project set "Simulator" "ISim (VHDL/Verilog)"

xfile add "../rtl/ddr2_chipscope.v"
xfile add "../rtl/ddr2_ctrl.v"
xfile add "../rtl/ddr2_idelay_ctrl.v"
xfile add "../rtl/ddr2_infrastructure.v"
xfile add "../rtl/ddr2_mem_if_top.v"
xfile add "../rtl/ddr2_phy_calib.v"
xfile add "../rtl/ddr2_phy_ctl_io.v"
xfile add "../rtl/ddr2_phy_dm_iob.v"
xfile add "../rtl/ddr2_phy_dq_iob.v"
xfile add "../rtl/ddr2_phy_dqs_iob.v"
xfile add "../rtl/ddr2_phy_init.v"
xfile add "../rtl/ddr2_phy_io.v"
xfile add "../rtl/ddr2_phy_top.v"
xfile add "../rtl/ddr2_phy_write.v"
xfile add "../rtl/ddr2_top.v"
xfile add "../rtl/ddr2_usr_addr_fifo.v"
xfile add "../rtl/ddr2_usr_rd.v"
xfile add "../rtl/ddr2_usr_top.v"
xfile add "../rtl/ddr2_usr_wr.v"
xfile add "../rtl/mig_v3_4.v"

xfile add "mig_v3_4.ucf"

project set "Optimization Goal" "Speed" -process "Synthesize - XST"
project set "Optimization Effort" "Normal" -process "Synthesize - XST"
project set "Power Reduction" "False" -process "Synthesize - XST"
project set "Use Synthesis Constraints File" "True" -process "Synthesize - XST"
project set "Library Search Order" "../synth/mig_v3_4.lso" -process "Synthesize - XST"
project set "Keep Hierarchy" "No" -process "Synthesize - XST"
project set "Global Optimization Goal" "AllClockNets" -process "Synthesize - XST"
project set "Generate RTL Schematic" "Yes" -process "Synthesize - XST"
project set "Read Cores" "True" -process "Synthesize - XST"
project set "Cores Search Directories" "" -process "Synthesize - XST"
project set "Write Timing Constraints" "False" -process "Synthesize - XST"
project set "Cross Clock Analysis" "False" -process "Synthesize - XST"
project set "Hierarchy Separator" "/" -process "Synthesize - XST"
project set "Bus Delimiter" "<>" -process "Synthesize - XST"
project set "LUT-FF Pairs Utilization Ratio" "100" -process "Synthesize - XST"
project set "BRAM Utilization Ratio" "100" -process "Synthesize - XST"
project set "DSP Utilization Ratio" "100" -process "Synthesize - XST"
project set "Case" "Maintain" -process "Synthesize - XST"
project set "HDL INI File" "" -process "Synthesize - XST"
project set "Verilog 2001" "True" -process "Synthesize - XST"
project set "Verilog Include Directories" "" -process "Synthesize - XST"
project set "Verilog Macros" "" -process "Synthesize - XST"
project set "Other XST Command Line Options" "" -process "Synthesize - XST"
project set "FSM Encoding Algorithm" "Auto" -process "Synthesize - XST"
project set "Safe Implementation" "No" -process "Synthesize - XST"
project set "Case Implementation Style" "None" -process "Synthesize - XST"
project set "FSM Style" "LUT" -process "Synthesize - XST"
project set "RAM Extraction" "True" -process "Synthesize - XST"
project set "RAM Style" "Auto" -process "Synthesize - XST"
project set "ROM Extraction" "True" -process "Synthesize - XST"
project set "ROM Style" "Auto" -process "Synthesize - XST"
project set "Automatic BRAM Packing" "False" -process "Synthesize - XST"
project set "Mux Extraction" "Yes" -process "Synthesize - XST"
project set "Mux Style" "Auto" -process "Synthesize - XST"
project set "Decoder Extraction" "True" -process "Synthesize - XST"
project set "Priority Encoder Extraction" "Yes" -process "Synthesize - XST"
project set "Shift Register Extraction" "True" -process "Synthesize - XST"
project set "Logical Shifter Extraction" "True" -process "Synthesize - XST"
project set "XOR Collapsing" "True" -process "Synthesize - XST"
project set "Resource Sharing" "True" -process "Synthesize - XST"
project set "Use DSP Block" "Auto" -process "Synthesize - XST"
project set "Asynchronous To Synchronous" "False" -process "Synthesize - XST"
project set "Add I/O Buffers" "True" -process "Synthesize - XST"
project set "Max Fanout" "100000" -process "Synthesize - XST"
project set "Number of Clock Buffers" "32" -process "Synthesize - XST"
project set "Register Duplication" "True" -process "Synthesize - XST"
project set "Equivalent Register Removal" "True" -process "Synthesize - XST"
project set "Register Balancing" "No" -process "Synthesize - XST"
project set "Pack I/O Registers into IOBs" "Auto" -process "Synthesize - XST"
project set "Slice Packing" "True" -process "Synthesize - XST"
project set "Use Clock Enable" "Auto" -process "Synthesize - XST"
project set "Use Synchronous Set" "Auto" -process "Synthesize - XST"
project set "Use Synchronous Reset" "Auto" -process "Synthesize - XST"
project set "Optimize Instantiated Primitives" "False" -process "Synthesize - XST"

project set "Use LOC Constraints" "True" -process Translate
project set "Netlist Translation Type" "Timestamp" -process Translate
project set "Create I/O Pads from Ports" "False" -process Translate
project set "Allow Unexpanded Blocks" "False" -process Translate
project set "Allow Unmatched LOC Constraints" "False" -process Translate

project set "Placer Effort Level" "High" -process Map
project set "Placer Extra Effort" "None" -process Map
project set "Starting Placer Cost Table (1-100)" "1" -process Map
project set "Combinatorial Logic Optimization" "False" -process Map
project set "Trim Unconnected Signals" "True" -process Map
project set "Allow Logic Optimization Across Hierarchy" "False" -process Map
project set "Optimization Strategy (Cover Mode)" "Area" -process Map
project set "Generate Detailed MAP Report" "False" -process Map
project set "Pack I/O Registers/Latches into IOBs" "Off" -process Map
project set "Map Slice Logic into Unused Block RAMs" "False" -process Map
project set "Other Map Command Line Options" "" -process Map

project set "Place And Route Mode" "Route Only" -process "Place & Route"
project set "Place & Route Effort Level (Overall)" "High" -process "Place & Route"
project set "Extra Effort (Highest PAR level only)" "None" -process "Place & Route"
project set "Ignore User Timing Constraints" "False" -process "Place & Route"
project set "Use Bonded I/Os" "False" -process "Place & Route"
project set "Generate Asynchronous Delay Report" "False" -process "Place & Route"
project set "Generate Clock Region Report" "False" -process "Place & Route"
project set "Generate Post-Place & Route Simulation Model" "False" -process "Place & Route"
project set "Power Reduction" "False" -process "Place & Route"

project set "Report Type" "Error Report" -process "Generate Post-Map Static Timing"
project set "Number of Paths in Error/Verbose Report" "3" -process "Generate Post-Map Static Timing"
project set "Perform Advanced Analysis" "False" -process "Generate Post-Map Static Timing"
project set "Change Device Speed To" "-2" -process "Generate Post-Map Static Timing"
project set "Report Unconstrained Paths" "" -process "Generate Post-Map Static Timing"
project set "Report Fastest Path(s) in Each Constraint" "False" -process "Generate Post-Map Static Timing"

project set "Enable Debugging of Serial Mode BitStream" "False" -process "Generate Programming File"
project set "Create Binary Configuration File" "False" -process "Generate Programming File"
project set "Enable Cyclic Redundancy Checking (CRC)" "True" -process "Generate Programming File"
project set "Configuration Rate" "2" -process "Generate Programming File"
project set "Configuration Clk (Configuration Pins)" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin M0" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin M1" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin M2" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin Program" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin Done" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin Init" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin CS" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin DIn" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin Busy" "Pull Up" -process "Generate Programming File"
project set "Configuration Pin RdWr" "Pull Up" -process "Generate Programming File"
project set "JTAG Pin TCK" "Pull Up" -process "Generate Programming File"
project set "JTAG Pin TDI" "Pull Up" -process "Generate Programming File"
project set "JTAG Pin TDO" "Pull Up" -process "Generate Programming File"
project set "JTAG Pin TMS" "Pull Up" -process "Generate Programming File"
project set "Unused IOB Pins" "Pull Down" -process "Generate Programming File"
project set "UserID Code (8 Digit Hexadecimal)" "0xFFFFFFFF" -process "Generate Programming File"
project set "DCI Update Mode" "As Required" -process "Generate Programming File"
project set "FPGA Start-Up Clock" "CCLK" -process "Generate Programming File"
project set "Done (Output Events)" "Default (4)" -process "Generate Programming File"
project set "Enable Outputs (Output Events)" "Default (5)" -process "Generate Programming File"
project set "Release Write Enable (Output Events)" "Default (6)" -process "Generate Programming File"
project set "Wait for DLL Lock (Output Events)" "Default (NoWait)" -process "Generate Programming File"
project set "Enable Internal Done Pipe" "False" -process "Generate Programming File"
project set "Drive Done Pin High" "False" -process "Generate Programming File"
project set "Security" "Enable Readback and Reconfiguration" -process "Generate Programming File"
project set "Encrypt Bitstream" "False" -process "Generate Programming File"

project close


