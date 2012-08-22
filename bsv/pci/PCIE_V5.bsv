// PCIE_V5.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE_V5;

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

// V5 TRN...
import "BVI" xilinx_v5_pcie_wrapper =
module vMkVirtex5PCIExpressWithDCM#(PCIEParams params)(PCIE#(lanes))
   provisos(Add#(1, z, lanes));

   default_clock clk(sys_clk);
   default_reset rstn(sys_reset_n);

   port fast_train_simulation_only = params.fast_train_sim_only;

   output_clock  clkout(refclkout);

   interface PCIE_EXP pcie;
      method                  rxp(pci_exp_rxp) enable((*inhigh*)en0) reset_by(no_reset);
      method                  rxn(pci_exp_rxn) enable((*inhigh*)en1) reset_by(no_reset);
      method pci_exp_txp      txp                                    reset_by(no_reset);
      method pci_exp_txn      txn                                    reset_by(no_reset);
   endinterface: pcie

   interface PCIE_CFG cfg;
      method cfg_do                     dataout                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_rd_wr_done_n           rd_wr_done_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_di)                                   enable((*inhigh*)en2)  clocked_by(trn_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                           enable((*inhigh*)en3)  clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_en_n(cfg_wr_en_n)                         enable((*inhigh*)en4)  clocked_by(trn_clk) reset_by(no_reset);
      method                            rd_en_n(cfg_rd_en_n)                         enable((*inhigh*)en5)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_to_turnoff_n           to_turnoff_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            byte_en_n(cfg_byte_en_n)                     enable((*inhigh*)en9)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                          clocked_by(no_clock) reset_by(no_reset);
      method cfg_device_number          device_number                                                       clocked_by(no_clock) reset_by(no_reset);
      method cfg_function_number        function_number                                                     clocked_by(no_clock) reset_by(no_reset);
      method cfg_status                 status                                                              clocked_by(trn_clk) reset_by(no_reset);
      method cfg_command                command                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                            clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                            clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_wake_n(cfg_pm_wake_n)                     enable((*inhigh*)en10) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pcie_link_state_n      pcie_link_state_n                                                   clocked_by(trn_clk) reset_by(no_reset);
      method                            trn_pending_n(cfg_trn_pending_n)             enable((*inhigh*)en11) clocked_by(trn_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                 enable((*inhigh*)en12) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg

   interface PCIE_INT cfg_irq;
      method                            interrupt_n(cfg_interrupt_n)                 enable((*inhigh*)en6)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_rdy_n        interrupt_rdy_n                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     interrupt_mmenable                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    interrupt_msienable                                                 clocked_by(trn_clk) reset_by(no_reset);
      method                            interrupt_di(cfg_interrupt_di)               enable((*inhigh*)en7)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_do           interrupt_do                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            interrupt_assert_n(cfg_interrupt_assert_n)   enable((*inhigh*)en8)  clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg_irq

   interface PCIE_ERR cfg_err;
      method                            ecrc_n(cfg_err_ecrc_n)                       enable((*inhigh*)en13) clocked_by(trn_clk) reset_by(no_reset);
      method                            ur_n(cfg_err_ur_n)                           enable((*inhigh*)en14) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_timeout_n(cfg_err_cpl_timeout_n)         enable((*inhigh*)en15) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_unexpect_n(cfg_err_cpl_unexpect_n)       enable((*inhigh*)en16) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_abort_n(cfg_err_cpl_abort_n)             enable((*inhigh*)en17) clocked_by(trn_clk) reset_by(no_reset);
      method                            posted_n(cfg_err_posted_n)                   enable((*inhigh*)en18) clocked_by(trn_clk) reset_by(no_reset);
      method                            cor_n(cfg_err_cor_n)                         enable((*inhigh*)en19) clocked_by(trn_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)       enable((*inhigh*)en20) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy_n          cpl_rdy_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method                            locked_n(cfg_err_locked_n)                   enable((*inhigh*)en21) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg_err

   interface PCIE_TRN trn;
      output_clock                      clk(trn_clk);
      output_clock                      clk2(trn2_clk);
      output_reset                      reset_n(trn_reset_n)                                                clocked_by(trn_clk);
      method trn_lnk_up_n               lnk_up_n                                                            clocked_by(no_clock) reset_by(no_reset); /* semi-static */
   endinterface: trn

   interface PCIE_TRN_TX trn_tx;
      method                            tsof_n(trn_tsof_n)                           enable((*inhigh*)en22) clocked_by(trn_clk) reset_by(no_reset);
      method                            teof_n(trn_teof_n)                           enable((*inhigh*)en23) clocked_by(trn_clk) reset_by(no_reset);
      method                            td(trn_td)                                   enable((*inhigh*)en24) clocked_by(trn_clk) reset_by(no_reset);
      method                            trem_n(trn_trem_n)                           enable((*inhigh*)en25) clocked_by(trn_clk) reset_by(no_reset);
      method                            tsrc_rdy_n(trn_tsrc_rdy_n)                   enable((*inhigh*)en26) clocked_by(trn_clk) reset_by(no_reset);
      method trn_tdst_rdy_n             tdst_rdy_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            tsrc_dsc_n(trn_tsrc_dsc_n)                   enable((*inhigh*)en27) clocked_by(trn_clk) reset_by(no_reset);
      method trn_tdst_dsc_n             tdst_dsc_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_tbuf_av                tbuf_av                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            terrfwd_n(trn_terrfwd_n)                     enable((*inhigh*)en31) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: trn_tx

   interface PCIE_TRN_RX trn_rx;
      method trn_rsof_n                 rsof_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_reof_n                 reof_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_rd                     rd                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method trn_rrem_n                 rrem_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_rerrfwd_n              rerrfwd_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rsrc_rdy_n             rsrc_rdy_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            rdst_rdy_n(trn_rdst_rdy_n)                   enable((*inhigh*)en28) clocked_by(trn_clk) reset_by(no_reset);
      method trn_rsrc_dsc_n             rsrc_dsc_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            rnp_ok_n(trn_rnp_ok_n)                       enable((*inhigh*)en29) clocked_by(trn_clk) reset_by(no_reset);
      method                            rcpl_streaming_n(trn_rcpl_streaming_n)       enable((*inhigh*)en30) clocked_by(trn_clk) reset_by(no_reset);
      method trn_rbar_hit_n             rbar_hit_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_ph_av              rfc_ph_av                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_pd_av              rfc_pd_av                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_nph_av             rfc_nph_av                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_npd_av             rfc_npd_av                                                          clocked_by(trn_clk) reset_by(no_reset);
   endinterface: trn_rx

   schedule (pcie_rxp, pcie_rxn, pcie_txp, pcie_txn, cfg_dataout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_wr_en_n, cfg_rd_en_n, cfg_irq_interrupt_n, cfg_irq_interrupt_rdy_n, cfg_irq_interrupt_mmenable, cfg_irq_interrupt_msienable,
             cfg_irq_interrupt_di, cfg_irq_interrupt_do, cfg_irq_interrupt_assert_n, cfg_to_turnoff_n, cfg_byte_en_n, cfg_bus_number, cfg_device_number, cfg_function_number,
             cfg_status, cfg_command, cfg_dstatus, cfg_dcommand, cfg_lstatus, cfg_lcommand, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn,
             cfg_err_ecrc_n, cfg_err_ur_n, cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n, cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n,
             trn_lnk_up_n, trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n, trn_tx_tsrc_dsc_n, trn_tx_tdst_dsc_n, trn_tx_tbuf_av, trn_tx_terrfwd_n,
             trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n, trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rcpl_streaming_n, trn_rx_rbar_hit_n, trn_rx_rfc_ph_av, trn_rx_rfc_pd_av, trn_rx_rfc_nph_av, trn_rx_rfc_npd_av) CF
            (pcie_rxp, pcie_rxn, pcie_txp, pcie_txn, cfg_dataout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_wr_en_n, cfg_rd_en_n, cfg_irq_interrupt_n, cfg_irq_interrupt_rdy_n, cfg_irq_interrupt_mmenable, cfg_irq_interrupt_msienable,
             cfg_irq_interrupt_di, cfg_irq_interrupt_do, cfg_irq_interrupt_assert_n, cfg_to_turnoff_n, cfg_byte_en_n, cfg_bus_number, cfg_device_number, cfg_function_number,
             cfg_status, cfg_command, cfg_dstatus, cfg_dcommand, cfg_lstatus, cfg_lcommand, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn,
             cfg_err_ecrc_n, cfg_err_ur_n, cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n, cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n,
             trn_lnk_up_n, trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n, trn_tx_tsrc_dsc_n, trn_tx_tdst_dsc_n, trn_tx_tbuf_av, trn_tx_terrfwd_n,
             trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n, trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rcpl_streaming_n, trn_rx_rbar_hit_n, trn_rx_rfc_ph_av, trn_rx_rfc_pd_av, trn_rx_rfc_nph_av, trn_rx_rfc_npd_av);

endmodule: vMkVirtex5PCIExpressWithDCM

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx V5 TRN
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpoint#(PCIEParams params)(PCIExpress#(lanes))
   provisos(Add#(1, z, lanes));

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE#(lanes)                              pcie_ep             <- vMkVirtex5PCIExpressWithDCM(params);

   Clock                                     trnclk               = pcie_ep.trn.clk;
   Clock                                     trn2clk              = pcie_ep.trn.clk2;
   Reset                                     trnrst_n             = pcie_ep.trn.reset_n;

   PulseWire                                 pwTrnTx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxSof           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxEof           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxDsc           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bit#(8))                            wTrnTxRem           <- mkDWire(8'h00, clocked_by trnclk, reset_by noReset);
   Wire#(Bit#(64))                           wTrnTxDat           <- mkDWire(64'h00, clocked_by trnclk, reset_by noReset);

   PulseWire                                 pwTrnRx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxNpOk          <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxCplS          <- mkDWire(True, clocked_by trnclk, reset_by noReset);

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule connect_trn_tx;
      pcie_ep.trn_tx.tsof_n(pack(wTrnTxSof));
      pcie_ep.trn_tx.teof_n(pack(wTrnTxEof));
      pcie_ep.trn_tx.tsrc_dsc_n(pack(wTrnTxDsc));
      pcie_ep.trn_tx.trem_n(~wTrnTxRem);
      pcie_ep.trn_tx.td(wTrnTxDat);
      pcie_ep.trn_tx.tsrc_rdy_n(pack(!pwTrnTx));
      pcie_ep.trn_tx.terrfwd_n('1);
   endrule

   rule connect_trn_rx;
      pcie_ep.trn_rx.rdst_rdy_n(pack(!pwTrnRx));
      pcie_ep.trn_rx.rnp_ok_n(pack(wTrnRxNpOk));
      pcie_ep.trn_rx.rcpl_streaming_n(pack(wTrnRxCplS));
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface clkout  = pcie_ep.clkout;
   interface pcie    = pcie_ep.pcie;

   interface PCIE_TRN_COMMON trn;
      interface clk           = pcie_ep.trn.clk;
      interface clk2          = pcie_ep.trn.clk2;
      interface reset_n       = pcie_ep.trn.reset_n;
      method Bool link_up     = (pcie_ep.trn.lnk_up_n == 0);
   endinterface: trn

   interface PCIE_TRN_XMIT trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.trn_tx.tdst_rdy_n == 0);
         wTrnTxSof <= !data.sof;
         wTrnTxEof <= !data.eof;
         wTrnTxDsc <= !discontinue;
         wTrnTxRem <= data.be;
         wTrnTxDat <= data.data;
         pwTrnTx.send;
      endmethod
      method discontinued      = (pcie_ep.trn_tx.tdst_dsc_n == 0);
      method buffers_available = pcie_ep.trn_tx.tbuf_av;
   endinterface: trn_tx

   interface PCIE_TRN_RECV trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.trn_rx.rsrc_rdy_n == 0);
         TLPData#(8) retval = defaultValue;
         retval.sof  = (pcie_ep.trn_rx.rsof_n == 0);
         retval.eof  = (pcie_ep.trn_rx.reof_n == 0);
         retval.hit  = ~pcie_ep.trn_rx.rbar_hit_n;
         retval.be   = ~pcie_ep.trn_rx.rrem_n;
         retval.data = pcie_ep.trn_rx.rd;
         pwTrnRx.send;
         return retval;
      endmethod
      method error_forward      = (pcie_ep.trn_rx.rerrfwd_n == 0);
      method source_discontinue = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      method Action non_posted_ready(i);
         wTrnRxNpOk <= !i;
      endmethod
      method Action completion_streaming(i);
         wTrnRxCplS <= !i;
      endmethod
      method posted_header_credits     = pcie_ep.trn_rx.rfc_ph_av;
      method posted_data_credits       = pcie_ep.trn_rx.rfc_pd_av;
      method non_posted_header_credits = pcie_ep.trn_rx.rfc_nph_av;
      method non_posted_data_credits   = pcie_ep.trn_rx.rfc_npd_av;
   endinterface: trn_rx

   interface cfg        = pcie_ep.cfg;
   interface cfg_irq    = pcie_ep.cfg_irq;
   interface cfg_err    = pcie_ep.cfg_err;
endmodule: mkPCIExpressEndpoint

endpackage: PCIE_V5
