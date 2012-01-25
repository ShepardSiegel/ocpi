// PCIE_V6.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE_V6;

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

// V6 TRN...
import "BVI" xilinx_v6_pcie_wrapper =
module vMkVirtex6PCIExpressWithDCM#(PCIEParams params)(PCIE_V6#(lanes))
   provisos(Add#(1, z, lanes));

   default_clock clk(sys_clk);
   default_reset rstn(sys_reset_n);

   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";

   interface PCIE_EXP pcie;
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en0)                              reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en1)                              reset_by(no_reset);
      method pci_exp_txp                txp                                                                 reset_by(no_reset);
      method pci_exp_txn                txn                                                                 reset_by(no_reset);
   endinterface

   interface PCIE_TRN_V6 trn;
      output_clock                      clk(trn_clk);
      output_clock                      clk2(trn2_clk);
      output_reset                      reset_n(trn_reset_n)                                                clocked_by(trn_clk);
      method trn_lnk_up_n               lnk_up_n                                                            clocked_by(no_clock) reset_by(no_reset); /* semi-static */
      method trn_fc_ph                  fc_ph                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_pd                  fc_pd                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_nph                 fc_nph                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_npd                 fc_npd                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_cplh                fc_cplh                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_cpld                fc_cpld                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method                            fc_sel(trn_fc_sel)                           enable((*inhigh*)en01) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_TRN_TX_V6 trn_tx;
      method                            tsof_n(trn_tsof_n)                           enable((*inhigh*)en02) clocked_by(trn_clk)  reset_by(no_reset);
      method                            teof_n(trn_teof_n)                           enable((*inhigh*)en03) clocked_by(trn_clk)  reset_by(no_reset);
      method                            td(trn_td)                                   enable((*inhigh*)en04) clocked_by(trn_clk)  reset_by(no_reset);
      method                            trem_n(trn_trem_n)                           enable((*inhigh*)en05) clocked_by(trn_clk)  reset_by(no_reset);
      method                            tsrc_rdy_n(trn_tsrc_rdy_n)                   enable((*inhigh*)en06) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tdst_rdy_n             tdst_rdy_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            tsrc_dsc_n(trn_tsrc_dsc_n)                   enable((*inhigh*)en07) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tbuf_av                tbuf_av                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method trn_terr_drop_n            terr_drop_n                                                         clocked_by(trn_clk)  reset_by(no_reset);
      method                            tstr_n(trn_tstr_n)                           enable((*inhigh*)en08) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tcfg_req_n             tcfg_req_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            tcfg_gnt_n(trn_tcfg_gnt_n)                   enable((*inhigh*)en09) clocked_by(trn_clk)  reset_by(no_reset);
      method                            terrfwd_n(trn_terrfwd_n)                     enable((*inhigh*)en10) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_TRN_RX_V6 trn_rx;
      method trn_rsof_n                 rsof_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_reof_n                 reof_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rd                     rd                                                                  clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rrem_n                 rrem_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rerrfwd_n              rerrfwd_n                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rsrc_rdy_n             rsrc_rdy_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            rdst_rdy_n(trn_rdst_rdy_n)                   enable((*inhigh*)en11) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rsrc_dsc_n             rsrc_dsc_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            rnp_ok_n(trn_rnp_ok_n)                       enable((*inhigh*)en12) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rbar_hit_n             rbar_hit_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_PL_V6 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_gen2_capable       link_gen2_capable                                                        clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_upcfg_capable      link_upcfg_capable                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_link_rate           sel_link_rate                                                            clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_link_width          sel_link_width                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en13) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en14) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en15) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en16) clocked_by(trn_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en17) clocked_by(trn_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_CFG_V6 cfg;
      method cfg_do                     dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_rd_wr_done_n           rd_wr_done_n                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_di)                                        enable((*inhigh*)en18) clocked_by(trn_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                                enable((*inhigh*)en19) clocked_by(trn_clk) reset_by(no_reset);
      method                            byte_en_n(cfg_byte_en_n)                          enable((*inhigh*)en20) clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_en_n(cfg_wr_en_n)                              enable((*inhigh*)en21) clocked_by(trn_clk) reset_by(no_reset);
      method                            rd_en_n(cfg_rd_en_n)                              enable((*inhigh*)en22) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                               clocked_by(trn_clk) reset_by(no_reset);
      method cfg_device_number          device_number                                                            clocked_by(trn_clk) reset_by(no_reset);
      method cfg_function_number        function_number                                                          clocked_by(trn_clk) reset_by(no_reset);
      method cfg_status                 status                                                                   clocked_by(trn_clk) reset_by(no_reset);
      method cfg_command                command                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_to_turnoff_n           to_turnoff_n                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            turnoff_ok_n(cfg_turnoff_ok_n)                    enable((*inhigh*)en23) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_wake_n(cfg_pm_wake_n)                          enable((*inhigh*)en24) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pcie_link_state_n      pcie_link_state_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            trn_pending_n(cfg_trn_pending_n)                  enable((*inhigh*)en25) clocked_by(trn_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                      enable((*inhigh*)en26) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                         clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                         clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   interface PCIE_INT_V6 cfg_interrupt;
      method                            req_n(cfg_interrupt_n)                            enable((*inhigh*)en27) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_rdy_n        rdy_n                                                                    clocked_by(trn_clk) reset_by(no_reset);
      method                            assert_n(cfg_interrupt_assert_n)                  enable((*inhigh*)en28) clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_interrupt_di)                              enable((*inhigh*)en29) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                               clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                   clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   interface PCIE_ERR_V6 cfg_err;
      method                            ecrc_n(cfg_err_ecrc_n)                       enable((*inhigh*)en30) clocked_by(trn_clk) reset_by(no_reset);
      method                            ur_n(cfg_err_ur_n)                           enable((*inhigh*)en31) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_timeout_n(cfg_err_cpl_timeout_n)         enable((*inhigh*)en32) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_unexpect_n(cfg_err_cpl_unexpect_n)       enable((*inhigh*)en33) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_abort_n(cfg_err_cpl_abort_n)             enable((*inhigh*)en34) clocked_by(trn_clk) reset_by(no_reset);
      method                            posted_n(cfg_err_posted_n)                   enable((*inhigh*)en35) clocked_by(trn_clk) reset_by(no_reset);
      method                            cor_n(cfg_err_cor_n)                         enable((*inhigh*)en36) clocked_by(trn_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)       enable((*inhigh*)en37) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy_n          cpl_rdy_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method                            locked_n(cfg_err_locked_n)                   enable((*inhigh*)en38) clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   schedule (
             pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
             trn_lnk_up_n, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel,
             trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n,
             trn_tx_tsrc_dsc_n, trn_tx_tbuf_av, trn_tx_terr_drop_n, trn_tx_tstr_n, trn_tx_tcfg_req_n, trn_tx_tcfg_gnt_n,
             trn_tx_terrfwd_n, trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n,
             trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rbar_hit_n,
             pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
             pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
             pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph,
             pl_received_hot_rst, cfg_dout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_byte_en_n, cfg_wr_en_n,
             cfg_rd_en_n, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command,
             cfg_dstatus, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_to_turnoff_n,
             cfg_turnoff_ok_n, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn, cfg_pmcsr_pme_en,
             cfg_pmcsr_pme_status, cfg_pmcsr_powerstate, cfg_interrupt_req_n, cfg_interrupt_rdy_n,
             cfg_interrupt_assert_n, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable,
             cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_err_ecrc_n, cfg_err_ur_n,
             cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n,
             cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n
             )
            CF
            (
             pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
             trn_lnk_up_n, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel,
             trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n,
             trn_tx_tsrc_dsc_n, trn_tx_tbuf_av, trn_tx_terr_drop_n, trn_tx_tstr_n, trn_tx_tcfg_req_n, trn_tx_tcfg_gnt_n,
             trn_tx_terrfwd_n, trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n,
             trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rbar_hit_n,
             pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
             pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
             pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph,
             pl_received_hot_rst, cfg_dout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_byte_en_n, cfg_wr_en_n,
             cfg_rd_en_n, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command,
             cfg_dstatus, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_to_turnoff_n,
             cfg_turnoff_ok_n, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn, cfg_pmcsr_pme_en,
             cfg_pmcsr_pme_status, cfg_pmcsr_powerstate, cfg_interrupt_req_n, cfg_interrupt_rdy_n,
             cfg_interrupt_assert_n, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable,
             cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_err_ecrc_n, cfg_err_ur_n,
             cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n,
             cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n
             );

endmodule: vMkVirtex6PCIExpressWithDCM

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx V6 TRN
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointV6#(PCIEParams params)(PCIExpressV6#(lanes))
   provisos(Add#(1, z, lanes));

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE_V6#(lanes)                           pcie_ep             <- vMkVirtex6PCIExpressWithDCM(params);

   Clock                                     trnclk               = pcie_ep.trn.clk;    // 250 MHz
   Clock                                     trn2clk              = pcie_ep.trn.clk2;   // 125 MHz trn_clk/2
   Reset                                     trnrst_n             = pcie_ep.trn.reset_n;

   PulseWire                                 pwTrnTx             <- mkPulseWire(    clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxSof_n         <- mkDWire(True,   clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxEof_n         <- mkDWire(True,   clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxDsc_n         <- mkDWire(True,   clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxRem_n         <- mkDWire(True,   clocked_by trnclk, reset_by noReset);
   Wire#(Bit#(64))                           wTrnTxDat           <- mkDWire(64'h00, clocked_by trnclk, reset_by noReset);

   PulseWire                                 pwTrnRx             <- mkPulseWire(    clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxNpOk_n        <- mkDWire(True,   clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxCplS_n        <- mkDWire(True,   clocked_by trnclk, reset_by noReset);

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////

   rule connect_trn_tx;
      pcie_ep.trn_tx.tsof_n(pack(wTrnTxSof_n));
      pcie_ep.trn_tx.teof_n(pack(wTrnTxEof_n));
      pcie_ep.trn_tx.tsrc_dsc_n(pack(wTrnTxDsc_n));
      pcie_ep.trn_tx.trem_n(pack(wTrnTxRem_n));
      pcie_ep.trn_tx.td(wTrnTxDat);
      pcie_ep.trn_tx.tsrc_rdy_n(pack(!pwTrnTx));
      pcie_ep.trn_tx.terrfwd_n('1);
   endrule

   rule connect_trn_rx;
      pcie_ep.trn_rx.rdst_rdy_n(pack(!pwTrnRx));
      pcie_ep.trn_rx.rnp_ok_n(pack(wTrnRxNpOk_n));
      //pcie_ep.trn_rx.rcpl_streaming_n(pack(wTrnRxCplS_n));
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie       = pcie_ep.pcie;

   interface PCIE_TRN_COMMON_V6 trn;
      interface clk           = pcie_ep.trn.clk;
      interface clk2          = pcie_ep.trn.clk2;
      interface reset_n       = pcie_ep.trn.reset_n;
      method Bool link_up     = (pcie_ep.trn.lnk_up_n == 0);
   endinterface

   interface PCIE_TRN_XMIT_V6 trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.trn_tx.tdst_rdy_n == 0);
         wTrnTxSof_n <= !data.sof;
         wTrnTxEof_n <= !data.eof;
         wTrnTxDsc_n <= !discontinue;
         wTrnTxRem_n <= (data.be != '1);
         wTrnTxDat   <= data.data;
         pwTrnTx.send;
      endmethod
      //method discontinued      = (pcie_ep.trn_tx.tdst_dsc_n == 0);
      method dropped                           = (pcie_ep.trn_tx.terr_drop_n == 0);
      method buffers_available                 = pcie_ep.trn_tx.tbuf_av;
      method cut_through_mode(i)               = pcie_ep.trn_tx.tstr_n(pack(!i));
      method configuration_completion_ready    = (pcie_ep.trn_tx.tcfg_req_n == 0);
      method configuration_completion_grant(i) = pcie_ep.trn_tx.tcfg_gnt_n(pack(!i));
      method error_forward(i)                  = pcie_ep.trn_tx.terrfwd_n(pack(!i));
   endinterface

   interface PCIE_TRN_RECV_V6 trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.trn_rx.rsrc_rdy_n == 0);
         TLPData#(8) retval = defaultValue;
         retval.sof  = (pcie_ep.trn_rx.rsof_n == 0);
         retval.eof  = (pcie_ep.trn_rx.reof_n == 0);
         retval.hit  = ~pcie_ep.trn_rx.rbar_hit_n;
         retval.be   = ~(pack(replicate((pcie_ep.trn_rx.rrem_n))));
         retval.data = pcie_ep.trn_rx.rd;
         pwTrnRx.send;
         return retval;
      endmethod
      method error_forward         = (pcie_ep.trn_rx.rerrfwd_n == 0);
      method source_discontinue    = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      //method non_posted_ready(i)   = pcie_ep.trn_rx.rnp_ok_n(pack(!i));
      method Action non_posted_ready(i);
         wTrnRxNpOk_n <= !i;
      endmethod
   endinterface

   interface pl            = pcie_ep.pl;
   interface cfg           = pcie_ep.cfg;
   interface cfg_interrupt = pcie_ep.cfg_interrupt;
   interface cfg_err       = pcie_ep.cfg_err;
endmodule: mkPCIExpressEndpointV6

endpackage: PCIE_V6
