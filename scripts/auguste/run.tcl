#
# ocpi
#

#
# STEP#0: define some helpful variables, dirs, etc.
#
set targetPart xc6vlx240t-ff1156-1
set topName fpgaTop

# set_param project.keepTmpDir 1

# For synthesis
set XDC_pre xxx
# For implementation
set XDC_post yyy

#
# STEP#1: setup design sources and constraints
#
read_verilog ./../../libsrc/hdl/ocpi/ClockInvToBool.v
read_verilog ./../../libsrc/hdl/ocpi/arSRLFIFO.v
read_verilog ./../../libsrc/hdl/ocpi/arSRLFIFOD.v
read_verilog ./../../libsrc/hdl/ocpi/Ethernet_v6.v

read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_upconfig_fix_3451_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_reset_delay_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_brams_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_clocking_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_gtx_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_pipe_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_pipe_lane_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_pipe_misc_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_2_0_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_bram_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/pcie_bram_top_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/gtx_rx_valid_filter_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/gtx_drp_chanalign_fix_3752_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/gtx_tx_sync_rate_v6.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/v6_pcie_v1_7.v
read_verilog ./../../coregen/pcie_4243_trn_v6_gtx_x4_250/source/gtx_wrapper_v6.v
read_verilog ./../../libsrc/hdl/ocpi/xilinx_v6_pcie_wrapper.v

read_verilog ./../../rtl/mkSMAdapter4B.v
read_verilog ./../../rtl/mkSMAdapter16B.v
read_verilog ./../../libsrc/hdl/ocpi/duc_ddc_compiler_v1_0.v
read_verilog ./../../rtl/mkDDCWorker.v
read_verilog ./../../rtl/mkDelayWorker4B.v
read_verilog ./../../rtl/mkDelayWorker16B.v
read_verilog ./../../libsrc/hdl/ocpi/xfft_v7_1.v
read_verilog ./../../rtl/mkPSD.v
read_verilog ./../../rtl/mkBiasWorker4B.v
read_verilog ./../../rtl/mkGbeWorker.v
read_verilog ./../../rtl/mkICAPWorker.v
read_verilog ./../../rtl/mkFlashWorker.v
read_verilog ./../../rtl/mkDramServer_v6.v

read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/arb_mux.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/arb_row_col.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/arb_select.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_cntrl.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_common.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_compare.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_mach.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_queue.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/bank_state.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/col_mach.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/mc.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/rank_cntrl.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/rank_common.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/rank_mach.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/controller/round_robin_arb.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ecc/ecc_buf.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ecc/ecc_dec_fix.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ecc/ecc_gen.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ecc/ecc_merge_enc.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ip_top/clk_ibuf.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ip_top/ddr2_ddr3_chipscope.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ip_top/infrastructure.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ip_top/memc_ui_top.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ip_top/mem_intfc.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/circ_buffer.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_ck_iob.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_clock_io.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_control_io.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_data_io.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_dly_ctrl.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_dm_iob.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_dq_iob.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_dqs_iob.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_init.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_pd_top.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_pd.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_rdclk_gen.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_rdctrl_sync.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_rddata_sync.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_rdlvl.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_read.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_top.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_write.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/phy_wrlvl.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/phy/rd_bitslip.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ui/ui_cmd.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ui/ui_rd_data.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ui/ui_top.v
read_verilog ./../../coregen/dram_v6_mig37/mig_37/user_design/rtl/ui/ui_wr_data.v
read_verilog ./../../coregen/dram_v6_mig37/iodelay_ctrl_eco20100428.v
read_verilog ./v6_mig37_patch20110411.v

read_verilog ./../../rtl/mkTLPSM.v
read_verilog ./../../rtl/mkTLPCM.v
read_verilog ./../../rtl/mkPktFork.v
read_verilog ./../../rtl/mkPktMerge.v
read_verilog ./../../rtl/mkUUID.v
read_verilog ./../../rtl/mkOCCP.v
read_verilog ./../../rtl/mkOCDP4B.v
read_verilog ./../../rtl/mkOCDP16B.v
read_verilog ./../../rtl/mkOCInf4B.v
read_verilog ./../../rtl/mkOCInf16B.v
read_verilog ./../../rtl/mkOCApp16B.v
read_verilog ./../../rtl/mkCTop4B.v
read_verilog ./../../rtl/mkCTop16B.v

set bsv_files {./../../libsrc/hdl/bsv/BRAM1.v
	       ./../../libsrc/hdl/bsv/BRAM1BE.v
	       ./../../libsrc/hdl/bsv/BypassCrossingWire.v
	       ./../../libsrc/hdl/bsv/BypassWire.v
	       ./../../libsrc/hdl/bsv/ClockDiv.v
	       ./../../libsrc/hdl/bsv/ClockInverter.v
	       ./../../libsrc/hdl/bsv/FIFO1.v
	       ./../../libsrc/hdl/bsv/FIFO10.v
	       ./../../libsrc/hdl/bsv/FIFO2.v
	       ./../../libsrc/hdl/bsv/FIFO20.v
	       ./../../libsrc/hdl/bsv/MakeResetA.v
	       ./../../libsrc/hdl/bsv/ResetEither.v
	       ./../../libsrc/hdl/bsv/ResetInverter.v
	       ./../../libsrc/hdl/bsv/ResetToBool.v
	       ./../../libsrc/hdl/bsv/RevertReg.v
	       ./../../libsrc/hdl/bsv/SizedFIFO.v
	       ./../../libsrc/hdl/bsv/SyncBit.v
	       ./../../libsrc/hdl/bsv/SyncFIFO.v
	       ./../../libsrc/hdl/bsv/SyncHandshake.v
	       ./../../libsrc/hdl/bsv/SyncPulse.v
	       ./../../libsrc/hdl/bsv/SyncRegister.v
	       ./../../libsrc/hdl/bsv/SyncReset0.v
	       ./../../libsrc/hdl/bsv/SyncResetA.v
	       ./../../libsrc/hdl/bsv/TriState.v
         ./BRAM2.v}

foreach x $bsv_files {read_verilog $x}

read_verilog ./../../rtl/mkWciMonitor.v

read_verilog ./../../rtl/mkFTop_ml605.v

read_verilog ./../../libsrc/hdl/ocpi/fpgaTop_ml605.v

set_property top $topName [ get_filesets sources_1 ]  

#read_xdc ${XDC_pre}

#
# STEP#2: run basic compilation - synthesis, place & route
#
synth_design -part $targetPart
puts "Report Utilization"
report_utilization
#read_xdc ${XDC_post}
#opt_design
#place_design
#route_design
#puts "Report Utilization"
#report_utilization

