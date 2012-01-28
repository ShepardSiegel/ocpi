// PCIE_X7.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE_X7;

import PCIEDefs          ::*;

import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import FIFOLevel         ::*;

// K7 AXI (X7)...
// Note this imports the coregen top-level SOLUTION WRAPPER directly without the use of another Verilog wrapper;
// thus this code may change if the ports and function change in future versions.
import "BVI" pcie_7x_v1_3 =
module vMkPCIExpressXilinx7AXI#(PCIEParams params) (PCIE_X7#(lanes))
   provisos(Add#(1, z, lanes));

   Reset reset <- invertCurrentReset;     // Invert the module-level active-low Reset to make the signal "reset" active-high
   default_clock clk(sys_clk);            // System clock; typ 100 MHz (alt 125 or 250 MHz)
   default_reset rst(sys_reset) = reset;  // System Reset; sys_reset is active high

   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";

   interface PCIE_EXP pcie;
      method pci_exp_txp                txp                                                                      reset_by(no_reset);
      method pci_exp_txn                txn                                                                      reset_by(no_reset);
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en00)                                  reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en01)                                  reset_by(no_reset);
   endinterface

   interface PCIE_PIPE pipe;
     method                             pClk      (PIPE_PCLK_IN)            enable((*inhigh*)en100)  clocked_by(no_clock) reset_by(no_reset);
     method                             rxUserClk (PIPE_RXUSRCLK_IN)        enable((*inhigh*)en101)  clocked_by(no_clock) reset_by(no_reset);
     method                             rxOutClkIn(PIPE_RXOUTCLK_IN)        enable((*inhigh*)en102)  clocked_by(no_clock) reset_by(no_reset);
     method                             dxClk     (PIPE_DCLK_IN)            enable((*inhigh*)en103)  clocked_by(no_clock) reset_by(no_reset);
     method                             userClk1  (PIPE_USERCLK1_IN)        enable((*inhigh*)en104)  clocked_by(no_clock) reset_by(no_reset);
     method                             userClk2  (PIPE_USERCLK2_IN)        enable((*inhigh*)en105)  clocked_by(no_clock) reset_by(no_reset);
     method                             oobClk    (PIPE_OOBCLK_IN)          enable((*inhigh*)en099)  clocked_by(no_clock) reset_by(no_reset);
     method                             mmcmLock  (PIPE_MMCM_LOCK_IN)       enable((*inhigh*)en106)  clocked_by(no_clock) reset_by(no_reset);
     method  PIPE_TXOUTCLK_OUT          txOutClk                                                     clocked_by(no_clock) reset_by(no_reset);
     method  PIPE_RXOUTCLK_OUT          rxOutClkOut                                                  clocked_by(no_clock) reset_by(no_reset);
     method  PIPE_PCLK_SEL_OUT          pclkSel                                                      clocked_by(no_clock) reset_by(no_reset);
     method  PIPE_GEN3_OUT              gen3                                                         clocked_by(no_clock) reset_by(no_reset);
   endinterface

   interface PCIE_AXI125 axi;
      output_clock                      clk        (user_clk_out);
      output_reset                      usr_rst_p  (user_reset_out)                                               clocked_by(axi_clk);
      method user_lnk_up                lnk_up                                                                    clocked_by(no_clock) reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_TX axi_tx;
      method tx_buf_av                  tbuf_av                                                                   clocked_by(axi_clk)  reset_by(no_reset);
      method tx_err_drop                terr_drop                                                                 clocked_by(axi_clk)  reset_by(no_reset);
      method tx_cfg_req                 tcfg_req                                                                  clocked_by(axi_clk)  reset_by(no_reset);
      method s_axis_tx_tready           tready                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method                            tdata   (s_axis_tx_tdata)                         enable((*inhigh*)en107) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tkeep   (s_axis_tx_tkeep)                         enable((*inhigh*)en108) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tuser   (s_axis_tx_tuser)                         enable((*inhigh*)en109) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tlast   (s_axis_tx_tlast)                         enable((*inhigh*)en110) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tvalid  (s_axis_tx_tvalid)                        enable((*inhigh*)en111) clocked_by(axi_clk)  reset_by(no_reset);
      method                            cfg_gnt (tx_cfg_gnt)                              enable((*inhigh*)en112) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_RX axi_rx;
      method m_axis_rx_tdata            tdata                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tkeep            tkeep                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tlast            tlast                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tvalid           tvalid                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tuser            tuser                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method                            tready (m_axis_rx_tready)                         enable((*inhigh*)en113) clocked_by(axi_clk)  reset_by(no_reset);
      method                            np_ok  (rx_np_ok)                                 enable((*inhigh*)en114) clocked_by(axi_clk)  reset_by(no_reset);
      method                            np_req (rx_np_req)                                enable((*inhigh*)en115) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_FC axi_fc;
      method fc_cpld                    cpld                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_cplh                    cplh                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_npd                     npd                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method fc_nph                     nph                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method fc_pd                      pd                                                                        clocked_by(axi_clk)  reset_by(no_reset);
      method fc_ph                      ph                                                                        clocked_by(axi_clk)  reset_by(no_reset);
      method                            sel(fc_sel)                                       enable((*inhigh*)en116) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_CFG cfg;
      method cfg_mgmt_do                dout                                                                      clocked_by(axi_clk) reset_by(no_reset);
      method cfg_mgmt_rd_wr_done        rd_wr_done                                                                clocked_by(axi_clk) reset_by(no_reset);
      method                            di          (cfg_mgmt_di)                         enable((*inhigh*)en117) clocked_by(axi_clk) reset_by(no_reset);
      method                            byte_en     (cfg_mgmt_byte_en)                    enable((*inhigh*)en118) clocked_by(axi_clk) reset_by(no_reset);
      method                            dwaddr      (cfg_mgmt_dwaddr)                     enable((*inhigh*)en119) clocked_by(axi_clk) reset_by(no_reset);
      method                            wr_en       (cfg_mgmt_wr_en)                      enable((*inhigh*)en120) clocked_by(axi_clk) reset_by(no_reset);
      method                            rd_en       (cfg_mgmt_rd_en)                      enable((*inhigh*)en121) clocked_by(axi_clk) reset_by(no_reset);
      method                            wr_readonly (cfg_mgmt_wr_readonly)                enable((*inhigh*)en122) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_ERR cfg_error;
      method                            ecrc           (cfg_err_ecrc)                     enable((*inhigh*)en300) clocked_by(axi_clk) reset_by(no_reset);
      method                            ur             (cfg_err_ur)                       enable((*inhigh*)en301) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_timeout    (cfg_err_cpl_timeout)              enable((*inhigh*)en302) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_unexpect   (cfg_err_cpl_unexpect)             enable((*inhigh*)en303) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_abort      (cfg_err_cpl_abort)                enable((*inhigh*)en304) clocked_by(axi_clk) reset_by(no_reset);
      method                            posted         (cfg_err_posted)                   enable((*inhigh*)en305) clocked_by(axi_clk) reset_by(no_reset);
      method                            cor            (cfg_err_cor)                      enable((*inhigh*)en306) clocked_by(axi_clk) reset_by(no_reset);
      method                            egress_blocked (cfg_err_atomic_egress_blocked)    enable((*inhigh*)en307) clocked_by(axi_clk) reset_by(no_reset);
      method                            internal_cor   (cfg_err_internal_cor)             enable((*inhigh*)en308) clocked_by(axi_clk) reset_by(no_reset);
      method                            internal_uncor (cfg_err_internal_uncor)           enable((*inhigh*)en309) clocked_by(axi_clk) reset_by(no_reset);
      method                            malformed      (cfg_err_malformed)                enable((*inhigh*)en310) clocked_by(axi_clk) reset_by(no_reset);
      method                            mc_blocked     (cfg_err_mc_blocked)               enable((*inhigh*)en311) clocked_by(axi_clk) reset_by(no_reset);
      method                            poisoned       (cfg_err_poisoned)                 enable((*inhigh*)en312) clocked_by(axi_clk) reset_by(no_reset);
      method                            no_recovery    (cfg_err_norecovery)               enable((*inhigh*)en313) clocked_by(axi_clk) reset_by(no_reset);
      method                            tlp_cpl_header (cfg_err_tlp_cpl_header)           enable((*inhigh*)en314) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy            cpl_rdy                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method                            locked         (cfg_err_locked)                   enable((*inhigh*)e3115) clocked_by(axi_clk) reset_by(no_reset);
      method                            aer_headerlog  (cfg_err_aer_headerlog)            enable((*inhigh*)e3116) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_err_aer_headerlog_set  aer_headerlog_set                                                         clocked_by(axi_clk) reset_by(no_reset);
      method                            acs            (cfg_err_acs)                      enable((*inhigh*)en318) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_CFG2 cfg2;
      method cfg_status                 status                                                                    clocked_by(axi_clk) reset_by(no_reset);
      method cfg_command                command                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pcie_link_state        pcie_link_state                                                           clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                              clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                          clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                          clocked_by(axi_clk) reset_by(no_reset);
      method cfg_received_func_lvl_rst  received_func_lvl_rst                                                     clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_CFG3 cfg3;
      method cfg_to_turnoff             to_turnoff                                                                clocked_by(axi_clk) reset_by(no_reset);
      method                            turnoff_ok        (cfg_turnoff_ok)                enable((*inhigh*)en319) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_device_number          device_number                                                             clocked_by(axi_clk) reset_by(no_reset);
      method cfg_function_number        function_number                                                           clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_wake           (cfg_pm_wake)                   enable((*inhigh*)en320) clocked_by(axi_clk) reset_by(no_reset);
      method                            trn_pending       (cfg_trn_pending)               enable((*inhigh*)en321) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_halt_aspm_l0s  (cfg_pm_halt_aspm_l0s)          enable((*inhigh*)en322) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_halt_aspm_l1   (cfg_pm_halt_aspm_l1)           enable((*inhigh*)en323) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_force_state_en (cfg_pm_force_state_en)         enable((*inhigh*)en324) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_force_state    (cfg_pm_force_state)            enable((*inhigh*)en325) clocked_by(axi_clk) reset_by(no_reset);
      method                            dsn               (cfg_dsn)                       enable((*inhigh*)en326) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI7_INT cfg_interrupt;
      method                            req               (cfg_interrupt)                 enable((*inhigh*)en327) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_rdy          rdy                                                                       clocked_by(axi_clk) reset_by(no_reset);
      method                            iassert           (cfg_interrupt_assert)          enable((*inhigh*)en328) clocked_by(axi_clk) reset_by(no_reset);
      method                            din               (cfg_interrupt_di)              enable((*inhigh*)en329) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                      clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                    clocked_by(axi_clk) reset_by(no_reset);
      method                            stat              (cfg_interrupt_stat)            enable((*inhigh*)en330) clocked_by(axi_clk) reset_by(no_reset);
      method                            msgnum            (cfg_pciecap_interrupt_msgnum)  enable((*inhigh*)en331) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   /*
   interface PCIE_DRP drp;
      method                            clk               (drp_clk)                       enable((*inhigh*)en332) clocked_by(axi_clk) reset_by(no_reset);
      method                            en                (drp_en)                        enable((*inhigh*)en333) clocked_by(axi_clk) reset_by(no_reset);
      method                            we                (drp_we)                        enable((*inhigh*)en334) clocked_by(axi_clk) reset_by(no_reset);
      method                            addr              (drp_addr)                      enable((*inhigh*)en335) clocked_by(axi_clk) reset_by(no_reset);
      method                            din               (drp_di)                        enable((*inhigh*)en336) clocked_by(axi_clk) reset_by(no_reset);
      method drp_rdy                    rdy;
      method drp_do                     dout;
   endinterface
   */

   interface PCIE_PL_V6 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_gen2_cap           link_gen2_capable                                                        clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_upcfg_cap          link_upcfg_capable                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_lnk_rate            sel_link_rate                                                            clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_lnk_width           sel_link_width                                                           clocked_by(axi_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en48) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en49) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en50) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en51) clocked_by(axi_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en52) clocked_by(axi_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(axi_clk)  reset_by(no_reset);
   endinterface


   schedule (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tkeep, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tkeep, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 
     cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, cfg_wr_readonly, 
     cfg_error_ecrc, cfg_error_ur, cfg_error_cpl_timeout, cfg_error_cpl_unexpect, cfg_error_cpl_abort, cfg_error_posted, cfg_error_cor, cfg_error_egress_blocked, 
     cfg_error_internal_cor, cfg_error_internal_uncor, cfg_error_malformed, cfg_error_mc_blocked, cfg_error_poisoned, cfg_error_no_recovery, 
     cfg_error_tlp_cpl_header, cfg_error_locked, cfg_error_aer_headerlog, cfg_error_acs, 
     cfg_interrupt_req, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_stat, cfg_interrupt_msgnum,
     cfg2_status, cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_pmcsr_pme_en,
     cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 
     cfg3_turnoff_ok, cfg3_to_turnoff, cfg3_trn_pending, cfg3_pm_wake, cfg3_bus_number, cfg3_device_number, cfg3_function_number, cfg3_dsn, 
     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     )
     CF
     (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tkeep, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tkeep, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 
     cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, cfg_wr_readonly, 
     cfg_error_ecrc, cfg_error_ur, cfg_error_cpl_timeout, cfg_error_cpl_unexpect, cfg_error_cpl_abort, cfg_error_posted, cfg_error_cor, cfg_error_egress_blocked, 
     cfg_error_internal_cor, cfg_error_internal_uncor, cfg_error_malformed, cfg_error_mc_blocked, cfg_error_poisoned, cfg_error_no_recovery, 
     cfg_error_tlp_cpl_header, cfg_error_locked, cfg_error_aer_headerlog, cfg_error_acs, 
     cfg_interrupt_req, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_stat, cfg_interrupt_msgnum,
     cfg2_status, cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_pmcsr_pme_en,
     cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 
     cfg3_turnoff_ok, cfg3_to_turnoff, cfg3_trn_pending, cfg3_pm_wake, cfg3_bus_number, cfg3_device_number, cfg3_function_number, cfg3_dsn, 
     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     );

endmodule: vMkPCIExpressXilinx7AXI

////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx AXI Series 7 (X7) (Kintex/Virtex 7)
///
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointX7_125#(PCIEParams params)(PCIExpressX7#(lanes)) 
   provisos(Add#(1, z, lanes));

// This implementation has the interesting challenge of backward-migrating the AXI interface from this K7 v1_3 core
// to the older TRN interface it will someday replace. This is so we can test the AXI endpoint without having to change the
// uNoC and everything attached to it. It is mostly the DWORD ordering and control logic generation.

  PCIE_X7#(lanes)       pcie_ep          <- vMkPCIExpressXilinx7AXI(params);   // Instance the vMk layer
  Clock                 axiclk           = pcie_ep.axi.clk;    // 125 MHz
  Reset                 usr_rst_n        <- mkResetInverter(pcie_ep.axi.usr_rst_p); // Invert the active-high user reset from the AXI core
  Reset                 axiRst125        <- mkAsyncReset(2, usr_rst_n, axiclk);
  FIFOF#(TLPData#(16))  txF              <- mkFIFOF(clocked_by axiclk, reset_by axiRst125);
  FIFOF#(TLPData#(16))  rxF              <- mkFIFOF(clocked_by axiclk, reset_by axiRst125);

  Wire#(Bit#(128))      axiTxData        <- mkDWire(0,     clocked_by axiclk, reset_by axiRst125);
  Wire#(Bit#(16))       axiTxKeep        <- mkDWire(0,     clocked_by axiclk, reset_by axiRst125);
  Wire#(Bit#(4) )       axiTxUser        <- mkDWire(0,     clocked_by axiclk, reset_by axiRst125);
  Wire#(Bool)           axiTxLast        <- mkDWire(False, clocked_by axiclk, reset_by axiRst125);
  Wire#(Bool)           axiTxValid       <- mkDWire(False, clocked_by axiclk, reset_by axiRst125);

  // There are three key functions this module provides:
  // 1. Get the PciID from the configuration port and provide that info upward
  // 2. Manage the traffic downstream RX from the AXI PCIe device to provide a TRN source  ->AXI->TRN->
  // 3. Manage the traffic upstream TX to the AXI PCIe device to provide a TRN sink        <-AXI<-TRN<-


  //
  // Downstream RX path from AXI to TRN; enq rxF with TRN format data converted from AXI...
  //

  rule connect_axi_rx;
    pcie_ep.axi_rx.tready(rxF.notFull);  // When room in rxF, assert rx_tready
  endrule

  function Bool isSOF(Bit#(22) tuser) = unpack(tuser[14]);
  function Bool isEOF(Bit#(22) tuser) = unpack(tuser[21]);
  function Bit#(7)  getBAR(Bit#(22) tuser) = tuser[8:2];
  function Bit#(16) genBE(Bit#(22) tuser);  // assumes no straddling
    Bit#(16) rval = '1;
    if (isEOF(tuser)) begin
      case (tuser[20:19])
        0: rval = 16'h000F; // End has DWORD 0
        1: rval = 16'h00FF; // End has DWORD 0,1
        2: rval = 16'h0FFF; // End has DWORD 0,1,2
        3: rval = 16'hFFFF; // End has DWORD 0.1,2,3
      endcase
    end 
    return(rval);
  endfunction

  // TODO: Extend RX to handle straddled packet scenario
  // This is a naive implementation that expects alligned, not straddled packets
  rule accept_axi_rx (pcie_ep.axi_rx.tvalid); // core has rc data for us to accept
    rxF.enq( TLPData {
      sof  :  isSOF(pcie_ep.axi_rx.tuser),
      eof  :  isEOF(pcie_ep.axi_rx.tuser),
      hit  : getBAR(pcie_ep.axi_rx.tuser),
      be   : reverseBits(genBE(pcie_ep.axi_rx.tuser)), 
      data : reverseDWORDS(pcie_ep.axi_rx.tdata) });
  endrule

  rule rx_np_ok;  pcie_ep.axi_rx.np_ok (True); endrule  // always allow non-posted requests
  rule rx_np_req; pcie_ep.axi_rx.np_req(True); endrule  // NP reqs can come at line rate


  //
  // Upstream TX path from TRN to AXI; deq txF with TRN format data and convert to AXI
  //

  rule connect_axi_tx;
    pcie_ep.axi_tx.tdata(axiTxData);
    pcie_ep.axi_tx.tkeep(axiTxKeep);
    pcie_ep.axi_tx.tuser(axiTxUser);
    pcie_ep.axi_tx.tlast(axiTxLast);
    pcie_ep.axi_tx.tvalid(axiTxValid);
  endrule

  rule advance_axi_tx (pcie_ep.axi_tx.tready);
    let tlp = txF.first; txF.deq;
    axiTxValid <= True;
    axiTxData <= reverseDWORDS(tlp.data);
    axiTxKeep <= (tlp.eof) ? reverseBits(tlp.be) : '1;
    axiTxUser <= 4'b0000; // src_dsc, tx_stream, err_fwd, ecrc_gen  TODO: Consider streaming cut-through
    axiTxLast <= tlp.eof;
  endrule

  rule tx_grant; pcie_ep.axi_tx.cfg_gnt(True); endrule  // always let EP have priority

   // Tieoffs...
   rule fc_sel;   pcie_ep.axi_fc.sel(RECEIVE_BUFFER_AVAILABLE_SPACE);     endrule  // always look at rcv credit avail
   mkTieOff(pcie_ep.pl);
   mkTieOff(pcie_ep.cfg);
   mkTieOff(pcie_ep.cfg_interrupt);
   mkTieOff(pcie_ep.cfg_error);
   //mkTieOff(pcie_ep.cfg2);  // all value methods, nothing to tie off
   //mkTieOff(pcie_ep.drp);


  // Interfaces...

  interface pcie       = pcie_ep.pcie;

  interface PCIE_TRN_COMMON_V6 trn;
    interface Clock clk      = axiclk;    // 125 MHz from core
    interface Reset reset_n  = usr_rst_n;
    method    Bool  link_up  = pcie_ep.axi.lnk_up;
  endinterface

  // As the rxF FIFO has TRN format data, we pop the TLPData and return it...
  interface PCIE_TRN_RECV16 trn_rx; // RX data moving downstream
     method ActionValue#(TLPData#(16)) recv() if (rxF.notEmpty);
       let rxo = rxF.first;
       rxF.deq;
       return rxo;
     endmethod
  endinterface

  // As the txF FIFO has TRN format data, we enqueue when we can...
  interface PCIE_TRN_XMIT16 trn_tx;  // TX data moving upstream 
    method Action xmit(discontinue, data) if (txF.notFull);
      txF.enq(data);
    endmethod
  endinterface

  interface cfg3          = pcie_ep.cfg3;  // Just expose the cfg3 interface to provide bus/dev/func
  /*
  interface pl            = pcie_ep.pl;
  interface cfg           = pcie_ep.cfg;
  interface cfg_interrupt = pcie_ep.cfg_interrupt;
  interface cfg_err       = pcie_ep.cfg_err;
  */
endmodule: mkPCIExpressEndpointX7_125

endpackage: PCIE_X7
