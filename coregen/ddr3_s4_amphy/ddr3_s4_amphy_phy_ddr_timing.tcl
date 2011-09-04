package require ::quartus::ddr_timing_model

# The clock period of your memory interface. Don't modify this
set ::t(period) 3.333

# The worst case skew between any pair of traces which are nominally matched
set ::t(board_skew) 0.020
set ::t(min_additional_dqs_variation) 0.000
set ::t(max_additional_dqs_variation) 0.000

###########################################################
# Memory timing parameters. See Section 6 of the JEDEC spec.
# ----------------------------------
# tDS/tDH: write timing
set ::t(DS) 0.195
set ::t(DH) 0.165
if {[string match -nocase "HARDCOPY IV*" [get_family_string]]} {
	# HardCopy IV uses default preset values because characterized slew rate data is not yet available
	set ::t(DS) 0.180
	set ::t(DH) 0.165
}

# Data output timing for non-DQS capture
set ::t(AC) 0.400

# Address and command input timing
set ::t(IS) 0.232
set ::t(IH) 0.248
if {[string match -nocase "HARDCOPY IV*" [get_family_string]]} {
	# HardCopy IV uses default preset values because characterized slew rate data is not yet available
	set ::t(IS) 0.340
	set ::t(IH) 0.240
}

# DQS to CK input timing
set ::t(DSS) 0.09
set ::t(DSH) 0.09
set ::t(DQSS) 0.387

# DQ to DQS timing on read
set ::t(DQSQ) 0.125
set ::t(QH) 1.486

# DQS to CK timing on reads
set ::t(DQSCK) 0.255
set ::t(HP) 1.500

# The maximum allowed length of the mimic path.
set ::t(mimic_shift) 1.600

# The clock period of the PLL reference clock
set ::t(inclk_period) 10.000

#####################
# FPGA specifications
#####################

# Duty cycle distortion from the device data sheet
set ::t(DCD_total) 0.000
# PLL phase shift error
set ::t(PLL_PSERR) 0.000

# DQS phase shift error
set ::t(DQS_PSERR_max) [expr [get_integer_node_delay -integer 2 -parameters {IO MAX HIGH} -src DQS_PSERR -in_fitter -period $::t(period)]/1000.0]
set ::t(DQS_PSERR_min) [expr [get_integer_node_delay -integer 2 -parameters {IO MIN HIGH} -src DQS_PSERR -in_fitter -period $::t(period)]/-1000.0]
if {($::t(period) < 2.173) && ([string match -nocase "HARDCOPY*" [get_family_string]] == 1)} {
	# The DLL configuration that ALTMEMPHY generates for Hardcopy may not be able to hit the frequencies required and will result in extra phase shift error
	set ::t(DQS_PSERR_max) [expr $::t(DQS_PSERR_max) + (2.173 - $::t(period))/4.0]
}
# DQS period jitter
set ::t(DQS_PERIOD_JITTER) [expr [get_integer_node_delay -integer 2 -parameters {IO MAX HIGH} -src DQS_JITTER -in_fitter]/1000.0]
# DQS phase jitter
set ::t(DQS_PHASE_JITTER) [expr [get_integer_node_delay -integer 2 -parameters {IO MAX HIGH} -src DQS_PHASE_JITTER -in_fitter]/1000.0]

###############
# SSN Info
###############

set package_type [get_package_type]
set ::SSN(pushout_o) [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSABSOLUTE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(pullin_o)  [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSABSOLUTE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(pushout_i) [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSABSOLUTE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(pullin_i)  [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSABSOLUTE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(rel_pushout_o) [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSRELATIVE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(rel_pullin_o)  [expr [get_micro_node_delay -micro SSO -parameters [list IO DQDQSRELATIVE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]
set ::SSN(rel_pushout_i) [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSRELATIVE NONLEVELED MAX] -package_type $package_type -in_fitter]/1000.0]
set ::SSN(rel_pullin_i)  [expr [get_micro_node_delay -micro SSI -parameters [list IO DQDQSRELATIVE NONLEVELED MIN] -package_type $package_type -in_fitter]/-1000.0]

###############
# Board Effects
###############

# Board skews
set ::board(minCK_DQS_skew) -0.010
set ::board(maxCK_DQS_skew) 0.010
set ::board(tpd_inter_DIMM) 0.050
set ::board(intra_DQS_group_skew) 0.020
set ::board(inter_DQS_group_skew) 0.020
set ::board(addresscmd_CK_skew) 0.000
set ::t(additional_addresscmd_tpd) $::board(addresscmd_CK_skew)

# ISI effects
set ::ISI(addresscmd_setup) 0.000
set ::ISI(addresscmd_hold) 0.000
set ::ISI(DQ) 0.000
set ::ISI(DQS) 0.000

set ddr3_s4_amphy_phy_use_flexible_timing 1

