// PCIE_X6.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE_X6;

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

// V6 AXI (X6)...
// Note this imports the coregen top-level directly without the use of a Verilog wrapper;
// thus this code may change if the ports and function change in future versions.
import "BVI" v6_pcie_v2_3 =
module vMkPCIExpressXilinxAXI#(PCIEParams params)(PCIE_X6#(lanes))
   provisos(Add#(1, z, lanes));

   Reset reset <- invertCurrentReset;

   default_clock clk(sys_clk);
   default_reset rst(sys_reset) = reset;  // sys_reset is active high

   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";

   interface PCIE_EXP pcie;
      method pci_exp_txp                txp                                                                      reset_by(no_reset);
      method pci_exp_txn                txn                                                                      reset_by(no_reset);
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en0)                                   reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en1)                                   reset_by(no_reset);
   endinterface

   interface PCIE_AXI250 axi;
      output_clock                      clk(user_clk_out);
      output_clock                      clk2(user_clk2_out);
      output_reset                      usr_rst_p(user_reset_out)                                                clocked_by(axi_clk);
      method user_lnk_up                lnk_up                                                                   clocked_by(no_clock) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_TX axi_tx;
      method tx_buf_av                  tbuf_av                                                                  clocked_by(axi_clk)  reset_by(no_reset);
      method tx_err_drop                terr_drop                                                                clocked_by(axi_clk)  reset_by(no_reset);
      method tx_cfg_req                 tcfg_req                                                                 clocked_by(axi_clk)  reset_by(no_reset);
      method s_axis_tx_tready           tready                                                                   clocked_by(axi_clk)  reset_by(no_reset);
      method                            tdata(s_axis_tx_tdata)                            enable((*inhigh*)en02) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tstrb(s_axis_tx_tstrb)                            enable((*inhigh*)en03) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tuser(s_axis_tx_tuser)                            enable((*inhigh*)en04) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tlast(s_axis_tx_tlast)                            enable((*inhigh*)en05) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tvalid(s_axis_tx_tvalid)                          enable((*inhigh*)en06) clocked_by(axi_clk)  reset_by(no_reset);
      method                            cfg_gnt(tx_cfg_gnt)                               enable((*inhigh*)en07) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_RX axi_rx;
      method m_axis_rx_tdata            tdata                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tstrb            tstrb                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tlast            tlast                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tvalid           tvalid                                                                   clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tuser            tuser                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method                            tready(m_axis_rx_tready)                          enable((*inhigh*)en08) clocked_by(axi_clk)  reset_by(no_reset);
      method                            np_ok(rx_np_ok)                                   enable((*inhigh*)en09) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_FC axi_fc;
      method fc_cpld                    cpld                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method fc_cplh                    cplh                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method fc_npd                     npd                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_nph                     nph                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_pd                      pd                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method fc_ph                      ph                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method                            sel(fc_sel)                                       enable((*inhigh*)en10) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_CFG cfg;
      method cfg_do                     dout                                                                     clocked_by(axi_clk) reset_by(no_reset);
      method cfg_rd_wr_done             rd_wr_done                                                               clocked_by(axi_clk) reset_by(no_reset);
      method                            di(cfg_di)                                        enable((*inhigh*)en11) clocked_by(axi_clk) reset_by(no_reset);
      method                            byte_en(cfg_byte_en)                              enable((*inhigh*)en12) clocked_by(axi_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                                enable((*inhigh*)en13) clocked_by(axi_clk) reset_by(no_reset);
      method                            wr_en(cfg_wr_en)                                  enable((*inhigh*)en14) clocked_by(axi_clk) reset_by(no_reset);
      method                            rd_en(cfg_rd_en)                                  enable((*inhigh*)en15) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_ERR cfg_error;
      method                            cor(cfg_err_cor)                                  enable((*inhigh*)en16) clocked_by(axi_clk) reset_by(no_reset);
      method                            ur(cfg_err_ur)                                    enable((*inhigh*)en17) clocked_by(axi_clk) reset_by(no_reset);
      method                            ecrc(cfg_err_ecrc)                                enable((*inhigh*)en18) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_timeout(cfg_err_cpl_timeout)                  enable((*inhigh*)en19) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_abort(cfg_err_cpl_abort)                      enable((*inhigh*)en20) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_unexpect(cfg_err_cpl_unexpect)                enable((*inhigh*)en21) clocked_by(axi_clk) reset_by(no_reset);
      method                            posted(cfg_err_posted)                            enable((*inhigh*)en22) clocked_by(axi_clk) reset_by(no_reset);
      method                            locked(cfg_err_locked)                            enable((*inhigh*)en23) clocked_by(axi_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)            enable((*inhigh*)en24) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy            cpl_rdy                                                                  clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_INT cfg_interrupt;
      method                            req(cfg_interrupt)                                enable((*inhigh*)en25) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_rdy          rdy                                                                      clocked_by(axi_clk) reset_by(no_reset);
      method                            iassert(cfg_interrupt_assert)                     enable((*inhigh*)en26) clocked_by(axi_clk) reset_by(no_reset);
      method                            din(cfg_interrupt_di)                             enable((*inhigh*)en27) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                     clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                               clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                   clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_CFG2 cfg2;
      method                            turnoff_ok(cfg_turnoff_ok)                        enable((*inhigh*)en28) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_to_turnoff             to_turnoff                                                               clocked_by(axi_clk) reset_by(no_reset);
      method                            trn_pending(cfg_trn_pending)                      enable((*inhigh*)en29) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_wake(cfg_pm_wake)                              enable((*inhigh*)en30) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                               clocked_by(axi_clk) reset_by(no_reset);
      method cfg_device_number          device_number                                                            clocked_by(axi_clk) reset_by(no_reset);
      method cfg_function_number        function_number                                                          clocked_by(axi_clk) reset_by(no_reset);
      method cfg_status                 status                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method cfg_command                command                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pcie_link_state        pcie_link_state                                                          clocked_by(axi_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                      enable((*inhigh*)en31) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                             clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                         clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                         clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_PL_V6 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_gen2_capable       link_gen2_capable                                                        clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_upcfg_capable      link_upcfg_capable                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_link_rate           sel_link_rate                                                            clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_link_width          sel_link_width                                                           clocked_by(axi_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en32) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en33) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en34) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en35) clocked_by(axi_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en36) clocked_by(axi_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(axi_clk)  reset_by(no_reset);
   endinterface


   schedule (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tstrb, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tstrb, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 

     cfg_dout, cfg_rd_wr_done, cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, 
     cfg_error_cor, cfg_error_ur, cfg_error_ecrc, cfg_error_cpl_timeout, cfg_error_cpl_abort, cfg_error_cpl_unexpect, cfg_error_posted, cfg_error_locked, cfg_error_tlp_cpl_header, cfg_error_cpl_rdy, 
     cfg_interrupt_req, cfg_interrupt_rdy, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, 
     cfg2_turnoff_ok, cfg2_to_turnoff, cfg2_trn_pending, cfg2_pm_wake, cfg2_bus_number, cfg2_device_number, cfg2_function_number, cfg2_status,
     cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_dsn,
     cfg2_pmcsr_pme_en, cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 

     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     )
     CF
     (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tstrb, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tstrb, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 

     cfg_dout, cfg_rd_wr_done, cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, 
     cfg_error_cor, cfg_error_ur, cfg_error_ecrc, cfg_error_cpl_timeout, cfg_error_cpl_abort, cfg_error_cpl_unexpect, cfg_error_posted, cfg_error_locked, cfg_error_tlp_cpl_header, cfg_error_cpl_rdy, 
     cfg_interrupt_req, cfg_interrupt_rdy, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, 
     cfg2_turnoff_ok, cfg2_to_turnoff, cfg2_trn_pending, cfg2_pm_wake, cfg2_bus_number, cfg2_device_number, cfg2_function_number, cfg2_status,
     cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_dsn,
     cfg2_pmcsr_pme_en, cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 

     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     );

endmodule: vMkPCIExpressXilinxAXI

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx AXI Virtex 6 (X6)
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointX6#(PCIEParams params)(PCIExpressV6#(lanes))       //TODO: Provide X6 (not TRN V6) as alternate implementation
   provisos(Add#(1, z, lanes));

// This implementation has the interesting challenge of backward-migrating the AXI interface from the 2.3 V6/X6 PCIe core
// to the older TRN interface it will someday replace. This is so we can test the AXI endpoint without having to change the
// uNoC and everything attached to it. It is mostly the DWORD ordering and control logic generation.

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE_X6#(lanes)       pcie_ep          <- vMkPCIExpressXilinxAXI(params);   // Instance the vMk layer
   Clock                 axiclk           = pcie_ep.axi.clk;    // 250 MHz
   Clock                 axiclk2          = pcie_ep.axi.clk2;   // 125 MHz (was drp)
   Reset                 usr_rst_n        <- mkResetInverter(pcie_ep.axi.usr_rst_p); // Invert the active-high user reset from the AXI core
   Reset                 axiRst250        <- mkAsyncReset(2, usr_rst_n, axiclk);
   Reset                 axiRst125        <- mkAsyncReset(2, usr_rst_n, axiclk2);
   PulseWire             pwAxiTx          <- mkPulseWire(clocked_by axiclk, reset_by noReset);
   PulseWire             pwAxiRx          <- mkPulseWire(clocked_by axiclk, reset_by noReset);
   Reg#(Bool)            rcvPktActive     <- mkDReg(False, clocked_by axiclk, reset_by axiRst250);

   Reg#(UInt#(4))        dbpciCA          <- mkReg(1);                                             // 250 MHz source
   Reg#(UInt#(4))        dbpciCB          <- mkReg(2, clocked_by axiclk,  reset_by axiRst250);     // 250 MHz from core
   Reg#(UInt#(4))        dbpciCC          <- mkReg(3, clocked_by axiclk2, reset_by axiRst125);      // 125 MHz from core

   rule cnt_ca; dbpciCA <= dbpciCA + 1; endrule
   rule cnt_cb; dbpciCB <= dbpciCB + 1; endrule
   rule cnt_cc; dbpciCC <= dbpciCC + 1; endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule connect_axi_tx;
     pcie_ep.axi_tx.tvalid(pwAxiTx);   // assert tvalid when we xmit - causes push into EP
   endrule

   rule connect_axi_rx;
     pcie_ep.axi_rx.tready(pwAxiRx);   // assert tready when we receive - causes pop from EP 
   endrule

   rule rx_active (pcie_ep.axi_rx.tvalid && pwAxiRx); // Used to recreate SoF on RX path
     rcvPktActive <= !pcie_ep.axi_rx.tlast;
   endrule

   // Tieoffs...
   rule tx_grant; pcie_ep.axi_tx.cfg_gnt(True); endrule  // always let EP have priority
   rule rx_np_ok; pcie_ep.axi_rx.np_ok(True);   endrule  // always allow non-posted requests
   rule fc_sel;   pcie_ep.axi_fc.sel(RECEIVE_BUFFER_AVAILABLE_SPACE);     endrule  // always look at rcv credit avail
   mkTieOff(pcie_ep.pl);
   mkTieOff(pcie_ep.cfg);
   mkTieOff(pcie_ep.cfg2);
   mkTieOff(pcie_ep.cfg_interrupt);
   mkTieOff(pcie_ep.cfg_error);


   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie       = pcie_ep.pcie;

   interface PCIE_TRN_COMMON_V6 trn;
      interface Clock clk      = axiclk;    // 250 MHz
      interface Clock clk2     = axiclk2;   // 125 MHz
      interface Reset reset_n  = usr_rst_n;
      method    Bool  link_up  = pcie_ep.axi.lnk_up;
   endinterface

   interface PCIE_TRN_XMIT_V6 trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.axi_tx.tready); 
         //pcie_ep.trn_tx.tsof_n(pack(!data.sof));          // no sof for AXI
         pcie_ep.axi_tx.tlast(data.eof);                    // eof goes to tlast
         //pcie_ep.trn_tx.tsrc_dsc_n(pack(!discontinue));   // no xmt discontinue
         pcie_ep.axi_tx.tstrb(reverseBits(data.be));        // active-high be's are strobes, TODO check reverseBits
         pcie_ep.axi_tx.tdata(reverseDWORDS(data.data));    // reverse DWORDS
         pwAxiTx.send;
      endmethod
      method dropped                           = pcie_ep.axi_tx.terr_drop;
      method buffers_available                 = pcie_ep.axi_tx.tbuf_av;
      //method cut_through_mode(i)               = pcie_ep.axi_tx.tstr_n(pack(!i));
      //method configuration_completion_ready    = (pcie_ep.trn_tx.tcfg_req_n == 0);
      //method configuration_completion_grant(i) = pcie_ep.trn_tx.tcfg_gnt_n(pack(!i));
      //method error_forward(i)                  = pcie_ep.trn_tx.terrfwd_n(pack(!i));
   endinterface

   interface PCIE_TRN_RECV_V6 trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.axi_rx.tvalid);
         TLPData#(8) retval = defaultValue;
         retval.sof  = pcie_ep.axi_rx.tvalid && !rcvPktActive; // Make SoF on first tvalid
         retval.eof  = pcie_ep.axi_rx.tlast;
         retval.hit  = pcie_ep.axi_rx.tuser[8:2]; // implementation specific choice where 7 bar bits are in tuser
         retval.be   = reverseBits(pcie_ep.axi_rx.tstrb); //TODO check reverseBits
         retval.data = reverseDWORDS(pcie_ep.axi_rx.tdata);
         pwAxiRx.send;
         return retval;
      endmethod
      //method error_forward         = (pcie_ep.trn_rx.rerrfwd_n == 0);
      //method source_discontinue    = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      //method non_posted_ready(i)   = pcie_ep.trn_rx.rnp_ok_n(pack(!i));
   endinterface


   /*
   interface pl            = pcie_ep.pl;
   interface cfg           = pcie_ep.cfg;
   interface cfg_interrupt = pcie_ep.cfg_interrupt;
   interface cfg_err       = pcie_ep.cfg_err;
   */

endmodule: mkPCIExpressEndpointX6

endpackage: PCIE_X6
