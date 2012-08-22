//-----------------------------------------------------------------------------
//
// (c) Copyright 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
//
// This disclaimer is not a license and does not grant any rights to the
// materials distributed herewith. Except as otherwise provided in a valid
// license issued to you by Xilinx, and to the maximum extent permitted by
// applicable law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND WITH ALL
// FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS, EXPRESS,
// IMPLIED, OR STATUTORY, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
// MERCHANTABILITY, NON-INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE;
// and (2) Xilinx shall not be liable (whether in contract or tort, including
// negligence, or under any other theory of liability) for any loss or damage
// of any kind or nature related to, arising under or in connection with these
// materials, including for any direct, or any indirect, special, incidental,
// or consequential loss or damage (including loss of data, profits, goodwill,
// or any type of loss or damage suffered as a result of any action brought by
// a third party) even if such damage or loss was reasonably foreseeable or
// Xilinx had been advised of the possibility of the same.
//
// CRITICAL APPLICATIONS
//
// Xilinx products are not designed or intended to be fail-safe, or for use in
// any application requiring fail-safe performance, such as life-support or
// safety devices or systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any other
// applications that could lead to death, personal injury, or severe property
// or environmental damage (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and liability of any use of
// Xilinx products in Critical Applications, subject only to applicable laws
// and regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE
// AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Spartan-6 Integrated Block for PCI Express
// File       : s6_pcie_v1_2.veo
//-----------------------------------------------------------------------------
// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
s6_pcie_v1_2 YourInstanceName (
  .pci_exp_txp            (pci_exp_txp            ),
  .pci_exp_txn            (pci_exp_txn            ),
  .pci_exp_rxp            (pci_exp_rxp            ),
  .pci_exp_rxn            (pci_exp_rxn            ),
  .trn_lnk_up_n           (trn_lnk_up_n           ),
  .trn_td                 (trn_td                 ), // Bus [31 : 0]
  .trn_tsof_n             (trn_tsof_n             ),
  .trn_teof_n             (trn_teof_n             ),
  .trn_tsrc_rdy_n         (trn_tsrc_rdy_n         ),
  .trn_tdst_rdy_n         (trn_tdst_rdy_n         ),
  .trn_terr_drop_n        (trn_terr_drop_n        ),
  .trn_tsrc_dsc_n         (trn_tsrc_dsc_n         ),
  .trn_terrfwd_n          (trn_terrfwd_n          ),
  .trn_tbuf_av            (trn_tbuf_av            ), // Bus [31 : 0]
  .trn_tstr_n             (trn_tstr_n             ),
  .trn_tcfg_req_n         (trn_tcfg_req_n         ),
  .trn_tcfg_gnt_n         (trn_tcfg_gnt_n         ),
  .trn_rd                 (trn_rd                 ), // Bus [31 : 0]
  .trn_rsof_n             (trn_rsof_n             ),
  .trn_reof_n             (trn_reof_n             ),
  .trn_rsrc_rdy_n         (trn_rsrc_rdy_n         ),
  .trn_rsrc_dsc_n         (trn_rsrc_dsc_n         ),
  .trn_rdst_rdy_n         (trn_rdst_rdy_n         ),
  .trn_rerrfwd_n          (trn_rerrfwd_n          ),
  .trn_rnp_ok_n           (trn_rnp_ok_n           ),
  .trn_rbar_hit_n         (trn_rbar_hit_n         ), // Bus [31 : 0]
  .trn_fc_sel             (trn_fc_sel             ), // Bus [31 : 0]
  .trn_fc_nph             (trn_fc_nph             ), // Bus [31 : 0]
  .trn_fc_npd             (trn_fc_npd             ), // Bus [31 : 0]
  .trn_fc_ph              (trn_fc_ph              ), // Bus [31 : 0]
  .trn_fc_pd              (trn_fc_pd              ), // Bus [31 : 0]
  .trn_fc_cplh            (trn_fc_cplh            ), // Bus [31 : 0]
  .trn_fc_cpld            (trn_fc_cpld            ), // Bus [31 : 0]
  .cfg_do                 (cfg_do                 ), // Bus [31 : 0]
  .cfg_rd_wr_done_n       (cfg_rd_wr_done_n       ),
  .cfg_dwaddr             (cfg_dwaddr             ), // Bus [31 : 0]
  .cfg_rd_en_n            (cfg_rd_en_n            ),
  .cfg_err_ur_n           (cfg_err_ur_n           ),
  .cfg_err_cor_n          (cfg_err_cor_n          ),
  .cfg_err_ecrc_n         (cfg_err_ecrc_n         ),
  .cfg_err_cpl_timeout_n  (cfg_err_cpl_timeout_n  ),
  .cfg_err_cpl_abort_n    (cfg_err_cpl_abort_n    ),
  .cfg_err_posted_n       (cfg_err_posted_n       ),
  .cfg_err_locked_n       (cfg_err_locked_n       ),
  .cfg_err_tlp_cpl_header (cfg_err_tlp_cpl_header ), // Bus [31 : 0]
  .cfg_err_cpl_rdy_n      (cfg_err_cpl_rdy_n      ),
  .cfg_interrupt_n        (cfg_interrupt_n        ),
  .cfg_interrupt_rdy_n    (cfg_interrupt_rdy_n    ),
  .cfg_interrupt_assert_n (cfg_interrupt_assert_n ),
  .cfg_interrupt_do       (cfg_interrupt_do       ), // Bus [31 : 0]
  .cfg_interrupt_di       (cfg_interrupt_di       ), // Bus [31 : 0]
  .cfg_interrupt_mmenable (cfg_interrupt_mmenable ), // Bus [31 : 0]
  .cfg_interrupt_msienable(cfg_interrupt_msienable),
  .cfg_turnoff_ok_n       (cfg_turnoff_ok_n       ),
  .cfg_to_turnoff_n       (cfg_to_turnoff_n       ),
  .cfg_pm_wake_n          (cfg_pm_wake_n          ),
  .cfg_pcie_link_state_n  (cfg_pcie_link_state_n  ), // Bus [31 : 0]
  .cfg_trn_pending_n      (cfg_trn_pending_n      ),
  .cfg_dsn                (cfg_dsn                ), // Bus [31 : 0]
  .cfg_bus_number         (cfg_bus_number         ), // Bus [31 : 0]
  .cfg_device_number      (cfg_device_number      ), // Bus [31 : 0]
  .cfg_function_number    (cfg_function_number    ), // Bus [31 : 0]
  .cfg_status             (cfg_status             ), // Bus [31 : 0]
  .cfg_command            (cfg_command            ), // Bus [31 : 0]
  .cfg_dstatus            (cfg_dstatus            ), // Bus [31 : 0]
  .cfg_dcommand           (cfg_dcommand           ), // Bus [31 : 0]
  .cfg_lstatus            (cfg_lstatus            ), // Bus [31 : 0]
  .cfg_lcommand           (cfg_lcommand           ), // Bus [31 : 0]
  .sys_clk                (sys_clk                ),
  .sys_reset_n            (sys_reset_n            ),
  .trn_clk                (trn_clk                ),
  .trn_reset_n            (trn_reset_n            ),
  .received_hot_reset     (received_hot_reset     ));

// INST_TAG_END ------ End INSTANTIATION Template ---------

