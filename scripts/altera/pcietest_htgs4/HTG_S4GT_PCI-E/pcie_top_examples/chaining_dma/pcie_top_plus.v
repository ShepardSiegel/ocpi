//Legal Notice: (C)2011 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

///** PCIe wrapper + 
//*/
module pcie_top_plus (
                       // inputs:
                        app_int_sts,
                        app_msi_num,
                        app_msi_req,
                        app_msi_tc,
                        cpl_err,
                        cpl_pending,
                        fixedclk_serdes,
                        lmi_addr,
                        lmi_din,
                        lmi_rden,
                        lmi_wren,
                        local_rstn,
                        pcie_rstn,
                        pclk_in,
                        pex_msi_num,
                        phystatus_ext,
                        pipe_mode,
                        pld_clk,
                        pm_auxpwr,
                        pm_data,
                        pm_event,
                        pme_to_cr,
                        reconfig_clk,
                        reconfig_clk_locked,
                        refclk,
                        rx_in0,
                        rx_in1,
                        rx_in2,
                        rx_in3,
                        rx_in4,
                        rx_in5,
                        rx_in6,
                        rx_in7,
                        rx_st_mask0,
                        rx_st_ready0,
                        rxdata0_ext,
                        rxdata1_ext,
                        rxdata2_ext,
                        rxdata3_ext,
                        rxdata4_ext,
                        rxdata5_ext,
                        rxdata6_ext,
                        rxdata7_ext,
                        rxdatak0_ext,
                        rxdatak1_ext,
                        rxdatak2_ext,
                        rxdatak3_ext,
                        rxdatak4_ext,
                        rxdatak5_ext,
                        rxdatak6_ext,
                        rxdatak7_ext,
                        rxelecidle0_ext,
                        rxelecidle1_ext,
                        rxelecidle2_ext,
                        rxelecidle3_ext,
                        rxelecidle4_ext,
                        rxelecidle5_ext,
                        rxelecidle6_ext,
                        rxelecidle7_ext,
                        rxstatus0_ext,
                        rxstatus1_ext,
                        rxstatus2_ext,
                        rxstatus3_ext,
                        rxstatus4_ext,
                        rxstatus5_ext,
                        rxstatus6_ext,
                        rxstatus7_ext,
                        rxvalid0_ext,
                        rxvalid1_ext,
                        rxvalid2_ext,
                        rxvalid3_ext,
                        rxvalid4_ext,
                        rxvalid5_ext,
                        rxvalid6_ext,
                        rxvalid7_ext,
                        test_in,
                        tx_st_data0,
                        tx_st_empty0,
                        tx_st_eop0,
                        tx_st_err0,
                        tx_st_sop0,
                        tx_st_valid0,

                       // outputs:
                        app_int_ack,
                        app_msi_ack,
                        clk250_out,
                        clk500_out,
                        core_clk_out,
                        lane_act,
                        lmi_ack,
                        lmi_dout,
                        ltssm,
                        pme_to_sr,
                        powerdown_ext,
                        rate_ext,
                        rc_pll_locked,
                        rx_st_bardec0,
                        rx_st_be0,
                        rx_st_data0,
                        rx_st_empty0,
                        rx_st_eop0,
                        rx_st_err0,
                        rx_st_sop0,
                        rx_st_valid0,
                        rxpolarity0_ext,
                        rxpolarity1_ext,
                        rxpolarity2_ext,
                        rxpolarity3_ext,
                        rxpolarity4_ext,
                        rxpolarity5_ext,
                        rxpolarity6_ext,
                        rxpolarity7_ext,
                        srstn,
                        test_out,
                        tl_cfg_add,
                        tl_cfg_ctl,
                        tl_cfg_ctl_wr,
                        tl_cfg_sts,
                        tl_cfg_sts_wr,
                        tx_cred0,
                        tx_fifo_empty0,
                        tx_out0,
                        tx_out1,
                        tx_out2,
                        tx_out3,
                        tx_out4,
                        tx_out5,
                        tx_out6,
                        tx_out7,
                        tx_st_ready0,
                        txcompl0_ext,
                        txcompl1_ext,
                        txcompl2_ext,
                        txcompl3_ext,
                        txcompl4_ext,
                        txcompl5_ext,
                        txcompl6_ext,
                        txcompl7_ext,
                        txdata0_ext,
                        txdata1_ext,
                        txdata2_ext,
                        txdata3_ext,
                        txdata4_ext,
                        txdata5_ext,
                        txdata6_ext,
                        txdata7_ext,
                        txdatak0_ext,
                        txdatak1_ext,
                        txdatak2_ext,
                        txdatak3_ext,
                        txdatak4_ext,
                        txdatak5_ext,
                        txdatak6_ext,
                        txdatak7_ext,
                        txdetectrx_ext,
                        txelecidle0_ext,
                        txelecidle1_ext,
                        txelecidle2_ext,
                        txelecidle3_ext,
                        txelecidle4_ext,
                        txelecidle5_ext,
                        txelecidle6_ext,
                        txelecidle7_ext
                     )
;

  output           app_int_ack;
  output           app_msi_ack;
  output           clk250_out;
  output           clk500_out;
  output           core_clk_out;
  output  [  3: 0] lane_act;
  output           lmi_ack;
  output  [ 31: 0] lmi_dout;
  output  [  4: 0] ltssm;
  output           pme_to_sr;
  output  [  1: 0] powerdown_ext;
  output           rate_ext;
  output           rc_pll_locked;
  output  [  7: 0] rx_st_bardec0;
  output  [ 15: 0] rx_st_be0;
  output  [127: 0] rx_st_data0;
  output           rx_st_empty0;
  output           rx_st_eop0;
  output           rx_st_err0;
  output           rx_st_sop0;
  output           rx_st_valid0;
  output           rxpolarity0_ext;
  output           rxpolarity1_ext;
  output           rxpolarity2_ext;
  output           rxpolarity3_ext;
  output           rxpolarity4_ext;
  output           rxpolarity5_ext;
  output           rxpolarity6_ext;
  output           rxpolarity7_ext;
  output           srstn;
  output  [  8: 0] test_out;
  output  [  3: 0] tl_cfg_add;
  output  [ 31: 0] tl_cfg_ctl;
  output           tl_cfg_ctl_wr;
  output  [ 52: 0] tl_cfg_sts;
  output           tl_cfg_sts_wr;
  output  [ 35: 0] tx_cred0;
  output           tx_fifo_empty0;
  output           tx_out0;
  output           tx_out1;
  output           tx_out2;
  output           tx_out3;
  output           tx_out4;
  output           tx_out5;
  output           tx_out6;
  output           tx_out7;
  output           tx_st_ready0;
  output           txcompl0_ext;
  output           txcompl1_ext;
  output           txcompl2_ext;
  output           txcompl3_ext;
  output           txcompl4_ext;
  output           txcompl5_ext;
  output           txcompl6_ext;
  output           txcompl7_ext;
  output  [  7: 0] txdata0_ext;
  output  [  7: 0] txdata1_ext;
  output  [  7: 0] txdata2_ext;
  output  [  7: 0] txdata3_ext;
  output  [  7: 0] txdata4_ext;
  output  [  7: 0] txdata5_ext;
  output  [  7: 0] txdata6_ext;
  output  [  7: 0] txdata7_ext;
  output           txdatak0_ext;
  output           txdatak1_ext;
  output           txdatak2_ext;
  output           txdatak3_ext;
  output           txdatak4_ext;
  output           txdatak5_ext;
  output           txdatak6_ext;
  output           txdatak7_ext;
  output           txdetectrx_ext;
  output           txelecidle0_ext;
  output           txelecidle1_ext;
  output           txelecidle2_ext;
  output           txelecidle3_ext;
  output           txelecidle4_ext;
  output           txelecidle5_ext;
  output           txelecidle6_ext;
  output           txelecidle7_ext;
  input            app_int_sts;
  input   [  4: 0] app_msi_num;
  input            app_msi_req;
  input   [  2: 0] app_msi_tc;
  input   [  6: 0] cpl_err;
  input            cpl_pending;
  input            fixedclk_serdes;
  input   [ 11: 0] lmi_addr;
  input   [ 31: 0] lmi_din;
  input            lmi_rden;
  input            lmi_wren;
  input            local_rstn;
  input            pcie_rstn;
  input            pclk_in;
  input   [  4: 0] pex_msi_num;
  input            phystatus_ext;
  input            pipe_mode;
  input            pld_clk;
  input            pm_auxpwr;
  input   [  9: 0] pm_data;
  input            pm_event;
  input            pme_to_cr;
  input            reconfig_clk;
  input            reconfig_clk_locked;
  input            refclk;
  input            rx_in0;
  input            rx_in1;
  input            rx_in2;
  input            rx_in3;
  input            rx_in4;
  input            rx_in5;
  input            rx_in6;
  input            rx_in7;
  input            rx_st_mask0;
  input            rx_st_ready0;
  input   [  7: 0] rxdata0_ext;
  input   [  7: 0] rxdata1_ext;
  input   [  7: 0] rxdata2_ext;
  input   [  7: 0] rxdata3_ext;
  input   [  7: 0] rxdata4_ext;
  input   [  7: 0] rxdata5_ext;
  input   [  7: 0] rxdata6_ext;
  input   [  7: 0] rxdata7_ext;
  input            rxdatak0_ext;
  input            rxdatak1_ext;
  input            rxdatak2_ext;
  input            rxdatak3_ext;
  input            rxdatak4_ext;
  input            rxdatak5_ext;
  input            rxdatak6_ext;
  input            rxdatak7_ext;
  input            rxelecidle0_ext;
  input            rxelecidle1_ext;
  input            rxelecidle2_ext;
  input            rxelecidle3_ext;
  input            rxelecidle4_ext;
  input            rxelecidle5_ext;
  input            rxelecidle6_ext;
  input            rxelecidle7_ext;
  input   [  2: 0] rxstatus0_ext;
  input   [  2: 0] rxstatus1_ext;
  input   [  2: 0] rxstatus2_ext;
  input   [  2: 0] rxstatus3_ext;
  input   [  2: 0] rxstatus4_ext;
  input   [  2: 0] rxstatus5_ext;
  input   [  2: 0] rxstatus6_ext;
  input   [  2: 0] rxstatus7_ext;
  input            rxvalid0_ext;
  input            rxvalid1_ext;
  input            rxvalid2_ext;
  input            rxvalid3_ext;
  input            rxvalid4_ext;
  input            rxvalid5_ext;
  input            rxvalid6_ext;
  input            rxvalid7_ext;
  input   [ 39: 0] test_in;
  input   [127: 0] tx_st_data0;
  input            tx_st_empty0;
  input            tx_st_eop0;
  input            tx_st_err0;
  input            tx_st_sop0;
  input            tx_st_valid0;

  wire             app_int_ack;
  wire             app_msi_ack;
  wire             busy_altgxb_reconfig;
  wire             busy_altgxb_reconfig_altr;
  wire             clk250_out;
  wire             clk500_out;
  wire             core_clk_out;
  wire             crst;
  wire             data_valid;
  wire             dlup_exit;
  wire    [  4: 0] gnd_hpg_ctrler;
  wire             gxb_powerdown;
  wire             hotrst_exit;
  wire             hotrst_exit_altr;
  wire             l2_exit;
  wire    [  3: 0] lane_act;
  wire             lmi_ack;
  wire    [ 31: 0] lmi_dout;
  wire    [  4: 0] ltssm;
  wire             npor;
  wire             npor_serdes_pll_locked;
  wire             offset_cancellation_reset;
  wire             open_rx_fifo_empty0;
  wire             open_rx_fifo_full0;
  wire             open_tx_fifo_full0;
  wire    [  3: 0] open_tx_fifo_rdptr0;
  wire    [  3: 0] open_tx_fifo_wrptr0;
  wire             otb0;
  wire             otb1;
  wire             pll_powerdown;
  wire             pme_to_sr;
  wire    [  1: 0] powerdown_ext;
  wire             rate_ext;
  wire             rc_pll_locked;
  wire    [ 33: 0] reconfig_fromgxb;
  wire    [  3: 0] reconfig_togxb;
  wire    [  3: 0] rx_eqctrl_out;
  wire    [  2: 0] rx_eqdcgain_out;
  wire    [  7: 0] rx_st_bardec0;
  wire    [ 15: 0] rx_st_be0;
  wire    [127: 0] rx_st_data0;
  wire             rx_st_empty0;
  wire             rx_st_eop0;
  wire             rx_st_err0;
  wire             rx_st_sop0;
  wire             rx_st_valid0;
  wire             rxpolarity0_ext;
  wire             rxpolarity1_ext;
  wire             rxpolarity2_ext;
  wire             rxpolarity3_ext;
  wire             rxpolarity4_ext;
  wire             rxpolarity5_ext;
  wire             rxpolarity6_ext;
  wire             rxpolarity7_ext;
  wire             srst;
  wire             srstn;
  wire    [  8: 0] test_out;
  wire    [  3: 0] tl_cfg_add;
  wire    [ 31: 0] tl_cfg_ctl;
  wire             tl_cfg_ctl_wr;
  wire    [ 52: 0] tl_cfg_sts;
  wire             tl_cfg_sts_wr;
  wire    [ 35: 0] tx_cred0;
  wire             tx_fifo_empty0;
  wire             tx_out0;
  wire             tx_out1;
  wire             tx_out2;
  wire             tx_out3;
  wire             tx_out4;
  wire             tx_out5;
  wire             tx_out6;
  wire             tx_out7;
  wire    [  4: 0] tx_preemp_0t_out;
  wire    [  4: 0] tx_preemp_1t_out;
  wire    [  4: 0] tx_preemp_2t_out;
  wire             tx_st_ready0;
  wire    [  2: 0] tx_vodctrl_out;
  wire             txcompl0_ext;
  wire             txcompl1_ext;
  wire             txcompl2_ext;
  wire             txcompl3_ext;
  wire             txcompl4_ext;
  wire             txcompl5_ext;
  wire             txcompl6_ext;
  wire             txcompl7_ext;
  wire    [  7: 0] txdata0_ext;
  wire    [  7: 0] txdata1_ext;
  wire    [  7: 0] txdata2_ext;
  wire    [  7: 0] txdata3_ext;
  wire    [  7: 0] txdata4_ext;
  wire    [  7: 0] txdata5_ext;
  wire    [  7: 0] txdata6_ext;
  wire    [  7: 0] txdata7_ext;
  wire             txdatak0_ext;
  wire             txdatak1_ext;
  wire             txdatak2_ext;
  wire             txdatak3_ext;
  wire             txdatak4_ext;
  wire             txdatak5_ext;
  wire             txdatak6_ext;
  wire             txdatak7_ext;
  wire             txdetectrx_ext;
  wire             txelecidle0_ext;
  wire             txelecidle1_ext;
  wire             txelecidle2_ext;
  wire             txelecidle3_ext;
  wire             txelecidle4_ext;
  wire             txelecidle5_ext;
  wire             txelecidle6_ext;
  wire             txelecidle7_ext;
  assign otb0 = 1'b0;
  assign otb1 = 1'b1;
  assign offset_cancellation_reset = ~reconfig_clk_locked;
  assign gnd_hpg_ctrler = 0;
  assign busy_altgxb_reconfig_altr = (pipe_mode==otb1)?otb0:busy_altgxb_reconfig;
  assign gxb_powerdown = ~npor;
  assign hotrst_exit_altr = hotrst_exit;
  assign pll_powerdown = ~npor;
  assign npor_serdes_pll_locked = pcie_rstn & local_rstn & rc_pll_locked;
  assign npor = pcie_rstn & local_rstn;
  pcie_top epmap
    (
      .app_int_ack (app_int_ack),
      .app_int_sts (app_int_sts),
      .app_msi_ack (app_msi_ack),
      .app_msi_num (app_msi_num),
      .app_msi_req (app_msi_req),
      .app_msi_tc (app_msi_tc),
      .busy_altgxb_reconfig (busy_altgxb_reconfig_altr),
      .cal_blk_clk (reconfig_clk),
      .clk250_out (clk250_out),
      .clk500_out (clk500_out),
      .core_clk_out (core_clk_out),
      .cpl_err (cpl_err),
      .cpl_pending (cpl_pending),
      .crst (crst),
      .dlup_exit (dlup_exit),
      .fixedclk_serdes (fixedclk_serdes),
      .gxb_powerdown (gxb_powerdown),
      .hotrst_exit (hotrst_exit),
      .hpg_ctrler (gnd_hpg_ctrler),
      .l2_exit (l2_exit),
      .lane_act (lane_act),
      .lmi_ack (lmi_ack),
      .lmi_addr (lmi_addr),
      .lmi_din (lmi_din),
      .lmi_dout (lmi_dout),
      .lmi_rden (lmi_rden),
      .lmi_wren (lmi_wren),
      .ltssm (ltssm),
      .npor (npor),
      .pclk_in (pclk_in),
      .pex_msi_num (pex_msi_num),
      .phystatus_ext (phystatus_ext),
      .pipe_mode (pipe_mode),
      .pld_clk (pld_clk),
      .pll_powerdown (pll_powerdown),
      .pm_auxpwr (pm_auxpwr),
      .pm_data (pm_data),
      .pm_event (pm_event),
      .pme_to_cr (pme_to_cr),
      .pme_to_sr (pme_to_sr),
      .powerdown_ext (powerdown_ext),
      .rate_ext (rate_ext),
      .rc_pll_locked (rc_pll_locked),
      .reconfig_clk (reconfig_clk),
      .reconfig_fromgxb (reconfig_fromgxb),
      .reconfig_togxb (reconfig_togxb),
      .refclk (refclk),
      .rx_fifo_empty0 (open_rx_fifo_empty0),
      .rx_fifo_full0 (open_rx_fifo_full0),
      .rx_in0 (rx_in0),
      .rx_in1 (rx_in1),
      .rx_in2 (rx_in2),
      .rx_in3 (rx_in3),
      .rx_in4 (rx_in4),
      .rx_in5 (rx_in5),
      .rx_in6 (rx_in6),
      .rx_in7 (rx_in7),
      .rx_st_bardec0 (rx_st_bardec0),
      .rx_st_be0 (rx_st_be0),
      .rx_st_data0 (rx_st_data0),
      .rx_st_empty0 (rx_st_empty0),
      .rx_st_eop0 (rx_st_eop0),
      .rx_st_err0 (rx_st_err0),
      .rx_st_mask0 (rx_st_mask0),
      .rx_st_ready0 (rx_st_ready0),
      .rx_st_sop0 (rx_st_sop0),
      .rx_st_valid0 (rx_st_valid0),
      .rxdata0_ext (rxdata0_ext),
      .rxdata1_ext (rxdata1_ext),
      .rxdata2_ext (rxdata2_ext),
      .rxdata3_ext (rxdata3_ext),
      .rxdata4_ext (rxdata4_ext),
      .rxdata5_ext (rxdata5_ext),
      .rxdata6_ext (rxdata6_ext),
      .rxdata7_ext (rxdata7_ext),
      .rxdatak0_ext (rxdatak0_ext),
      .rxdatak1_ext (rxdatak1_ext),
      .rxdatak2_ext (rxdatak2_ext),
      .rxdatak3_ext (rxdatak3_ext),
      .rxdatak4_ext (rxdatak4_ext),
      .rxdatak5_ext (rxdatak5_ext),
      .rxdatak6_ext (rxdatak6_ext),
      .rxdatak7_ext (rxdatak7_ext),
      .rxelecidle0_ext (rxelecidle0_ext),
      .rxelecidle1_ext (rxelecidle1_ext),
      .rxelecidle2_ext (rxelecidle2_ext),
      .rxelecidle3_ext (rxelecidle3_ext),
      .rxelecidle4_ext (rxelecidle4_ext),
      .rxelecidle5_ext (rxelecidle5_ext),
      .rxelecidle6_ext (rxelecidle6_ext),
      .rxelecidle7_ext (rxelecidle7_ext),
      .rxpolarity0_ext (rxpolarity0_ext),
      .rxpolarity1_ext (rxpolarity1_ext),
      .rxpolarity2_ext (rxpolarity2_ext),
      .rxpolarity3_ext (rxpolarity3_ext),
      .rxpolarity4_ext (rxpolarity4_ext),
      .rxpolarity5_ext (rxpolarity5_ext),
      .rxpolarity6_ext (rxpolarity6_ext),
      .rxpolarity7_ext (rxpolarity7_ext),
      .rxstatus0_ext (rxstatus0_ext),
      .rxstatus1_ext (rxstatus1_ext),
      .rxstatus2_ext (rxstatus2_ext),
      .rxstatus3_ext (rxstatus3_ext),
      .rxstatus4_ext (rxstatus4_ext),
      .rxstatus5_ext (rxstatus5_ext),
      .rxstatus6_ext (rxstatus6_ext),
      .rxstatus7_ext (rxstatus7_ext),
      .rxvalid0_ext (rxvalid0_ext),
      .rxvalid1_ext (rxvalid1_ext),
      .rxvalid2_ext (rxvalid2_ext),
      .rxvalid3_ext (rxvalid3_ext),
      .rxvalid4_ext (rxvalid4_ext),
      .rxvalid5_ext (rxvalid5_ext),
      .rxvalid6_ext (rxvalid6_ext),
      .rxvalid7_ext (rxvalid7_ext),
      .srst (srst),
      .test_in (test_in),
      .test_out (test_out),
      .tl_cfg_add (tl_cfg_add),
      .tl_cfg_ctl (tl_cfg_ctl),
      .tl_cfg_ctl_wr (tl_cfg_ctl_wr),
      .tl_cfg_sts (tl_cfg_sts),
      .tl_cfg_sts_wr (tl_cfg_sts_wr),
      .tx_cred0 (tx_cred0),
      .tx_fifo_empty0 (tx_fifo_empty0),
      .tx_fifo_full0 (open_tx_fifo_full0),
      .tx_fifo_rdptr0 (open_tx_fifo_rdptr0),
      .tx_fifo_wrptr0 (open_tx_fifo_wrptr0),
      .tx_out0 (tx_out0),
      .tx_out1 (tx_out1),
      .tx_out2 (tx_out2),
      .tx_out3 (tx_out3),
      .tx_out4 (tx_out4),
      .tx_out5 (tx_out5),
      .tx_out6 (tx_out6),
      .tx_out7 (tx_out7),
      .tx_st_data0 (tx_st_data0),
      .tx_st_empty0 (tx_st_empty0),
      .tx_st_eop0 (tx_st_eop0),
      .tx_st_err0 (tx_st_err0),
      .tx_st_ready0 (tx_st_ready0),
      .tx_st_sop0 (tx_st_sop0),
      .tx_st_valid0 (tx_st_valid0),
      .txcompl0_ext (txcompl0_ext),
      .txcompl1_ext (txcompl1_ext),
      .txcompl2_ext (txcompl2_ext),
      .txcompl3_ext (txcompl3_ext),
      .txcompl4_ext (txcompl4_ext),
      .txcompl5_ext (txcompl5_ext),
      .txcompl6_ext (txcompl6_ext),
      .txcompl7_ext (txcompl7_ext),
      .txdata0_ext (txdata0_ext),
      .txdata1_ext (txdata1_ext),
      .txdata2_ext (txdata2_ext),
      .txdata3_ext (txdata3_ext),
      .txdata4_ext (txdata4_ext),
      .txdata5_ext (txdata5_ext),
      .txdata6_ext (txdata6_ext),
      .txdata7_ext (txdata7_ext),
      .txdatak0_ext (txdatak0_ext),
      .txdatak1_ext (txdatak1_ext),
      .txdatak2_ext (txdatak2_ext),
      .txdatak3_ext (txdatak3_ext),
      .txdatak4_ext (txdatak4_ext),
      .txdatak5_ext (txdatak5_ext),
      .txdatak6_ext (txdatak6_ext),
      .txdatak7_ext (txdatak7_ext),
      .txdetectrx_ext (txdetectrx_ext),
      .txelecidle0_ext (txelecidle0_ext),
      .txelecidle1_ext (txelecidle1_ext),
      .txelecidle2_ext (txelecidle2_ext),
      .txelecidle3_ext (txelecidle3_ext),
      .txelecidle4_ext (txelecidle4_ext),
      .txelecidle5_ext (txelecidle5_ext),
      .txelecidle6_ext (txelecidle6_ext),
      .txelecidle7_ext (txelecidle7_ext)
    );


  altpcie_reconfig_4sgx reconfig
    (
      .busy (busy_altgxb_reconfig),
      .data_valid (data_valid),
      .logical_channel_address (3'b000),
      .offset_cancellation_reset (offset_cancellation_reset),
      .read (1'b0),
      .reconfig_clk (reconfig_clk),
      .reconfig_fromgxb (reconfig_fromgxb),
      .reconfig_togxb (reconfig_togxb),
      .rx_eqctrl (4'b0000),
      .rx_eqctrl_out (rx_eqctrl_out),
      .rx_eqdcgain (3'b000),
      .rx_eqdcgain_out (rx_eqdcgain_out),
      .tx_preemp_0t (5'b00000),
      .tx_preemp_0t_out (tx_preemp_0t_out),
      .tx_preemp_1t (5'b00000),
      .tx_preemp_1t_out (tx_preemp_1t_out),
      .tx_preemp_2t (5'b00000),
      .tx_preemp_2t_out (tx_preemp_2t_out),
      .tx_vodctrl (3'b000),
      .tx_vodctrl_out (tx_vodctrl_out),
      .write_all (1'b0)
    );


  pcie_top_rs_hip rs_hip
    (
      .app_rstn (srstn),
      .crst (crst),
      .dlup_exit (dlup_exit),
      .hotrst_exit (hotrst_exit_altr),
      .l2_exit (l2_exit),
      .ltssm (ltssm),
      .npor (npor_serdes_pll_locked),
      .pld_clk (pld_clk),
      .srst (srst),
      .test_sim (test_in[0])
    );



endmodule

