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

///** This Verilog HDL file generates the Incremental Compilation Wrapper that is used for simulation and synthesis
//*/
module pcie_hip_s4gx_gen2_x4_128_icm (
                                       // inputs:
                                        app_int_sts_icm,
                                        cal_blk_clk,
                                        clk125_in,
                                        cpl_err_icm,
                                        cpl_pending_icm,
                                        crst,
                                        gxb_powerdown,
                                        msi_stream_data0,
                                        msi_stream_valid0,
                                        npor,
                                        pex_msi_num_icm,
                                        phystatus_ext,
                                        pipe_mode,
                                        pll_powerdown,
                                        pme_to_cr,
                                        reconfig_clk,
                                        reconfig_togxb,
                                        refclk,
                                        rstn,
                                        rx_in0,
                                        rx_in1,
                                        rx_in2,
                                        rx_in3,
                                        rx_stream_mask0,
                                        rx_stream_ready0,
                                        rxdata0_ext,
                                        rxdata1_ext,
                                        rxdata2_ext,
                                        rxdata3_ext,
                                        rxdatak0_ext,
                                        rxdatak1_ext,
                                        rxdatak2_ext,
                                        rxdatak3_ext,
                                        rxelecidle0_ext,
                                        rxelecidle1_ext,
                                        rxelecidle2_ext,
                                        rxelecidle3_ext,
                                        rxstatus0_ext,
                                        rxstatus1_ext,
                                        rxstatus2_ext,
                                        rxstatus3_ext,
                                        rxvalid0_ext,
                                        rxvalid1_ext,
                                        rxvalid2_ext,
                                        rxvalid3_ext,
                                        srst,
                                        test_in,
                                        tx_stream_data0,
                                        tx_stream_valid0,

                                       // outputs:
                                        app_int_sts_ack_icm,
                                        cfg_busdev_icm,
                                        cfg_devcsr_icm,
                                        cfg_linkcsr_icm,
                                        cfg_msicsr_icm,
                                        cfg_prmcsr_icm,
                                        clk125_out,
                                        dlup_exit,
                                        hotrst_exit,
                                        l2_exit,
                                        lane_width_code,
                                        msi_stream_ready0,
                                        phy_sel_code,
                                        pme_to_sr,
                                        powerdown_ext,
                                        reconfig_fromgxb,
                                        ref_clk_sel_code,
                                        rx_stream_data0,
                                        rx_stream_valid0,
                                        rxpolarity0_ext,
                                        rxpolarity1_ext,
                                        rxpolarity2_ext,
                                        rxpolarity3_ext,
                                        test_out_icm,
                                        tx_out0,
                                        tx_out1,
                                        tx_out2,
                                        tx_out3,
                                        tx_stream_cred0,
                                        tx_stream_mask0,
                                        tx_stream_ready0,
                                        txcompl0_ext,
                                        txcompl1_ext,
                                        txcompl2_ext,
                                        txcompl3_ext,
                                        txdata0_ext,
                                        txdata1_ext,
                                        txdata2_ext,
                                        txdata3_ext,
                                        txdatak0_ext,
                                        txdatak1_ext,
                                        txdatak2_ext,
                                        txdatak3_ext,
                                        txdetectrx_ext,
                                        txelecidle0_ext,
                                        txelecidle1_ext,
                                        txelecidle2_ext,
                                        txelecidle3_ext
                                     )
;

  output           app_int_sts_ack_icm;
  output  [ 12: 0] cfg_busdev_icm;
  output  [ 31: 0] cfg_devcsr_icm;
  output  [ 31: 0] cfg_linkcsr_icm;
  output  [ 15: 0] cfg_msicsr_icm;
  output  [ 31: 0] cfg_prmcsr_icm;
  output           clk125_out;
  output           dlup_exit;
  output           hotrst_exit;
  output           l2_exit;
  output  [  3: 0] lane_width_code;
  output           msi_stream_ready0;
  output  [  3: 0] phy_sel_code;
  output           pme_to_sr;
  output  [  1: 0] powerdown_ext;
  output  [ 16: 0] reconfig_fromgxb;
  output  [  3: 0] ref_clk_sel_code;
  output  [ 81: 0] rx_stream_data0;
  output           rx_stream_valid0;
  output           rxpolarity0_ext;
  output           rxpolarity1_ext;
  output           rxpolarity2_ext;
  output           rxpolarity3_ext;
  output  [  8: 0] test_out_icm;
  output           tx_out0;
  output           tx_out1;
  output           tx_out2;
  output           tx_out3;
  output  [ 21: 0] tx_stream_cred0;
  output           tx_stream_mask0;
  output           tx_stream_ready0;
  output           txcompl0_ext;
  output           txcompl1_ext;
  output           txcompl2_ext;
  output           txcompl3_ext;
  output  [ 15: 0] txdata0_ext;
  output  [ 15: 0] txdata1_ext;
  output  [ 15: 0] txdata2_ext;
  output  [ 15: 0] txdata3_ext;
  output  [  1: 0] txdatak0_ext;
  output  [  1: 0] txdatak1_ext;
  output  [  1: 0] txdatak2_ext;
  output  [  1: 0] txdatak3_ext;
  output           txdetectrx_ext;
  output           txelecidle0_ext;
  output           txelecidle1_ext;
  output           txelecidle2_ext;
  output           txelecidle3_ext;
  input            app_int_sts_icm;
  input            cal_blk_clk;
  input            clk125_in;
  input   [  6: 0] cpl_err_icm;
  input            cpl_pending_icm;
  input            crst;
  input            gxb_powerdown;
  input   [  7: 0] msi_stream_data0;
  input            msi_stream_valid0;
  input            npor;
  input   [  4: 0] pex_msi_num_icm;
  input            phystatus_ext;
  input            pipe_mode;
  input            pll_powerdown;
  input            pme_to_cr;
  input            reconfig_clk;
  input   [  3: 0] reconfig_togxb;
  input            refclk;
  input            rstn;
  input            rx_in0;
  input            rx_in1;
  input            rx_in2;
  input            rx_in3;
  input            rx_stream_mask0;
  input            rx_stream_ready0;
  input   [ 15: 0] rxdata0_ext;
  input   [ 15: 0] rxdata1_ext;
  input   [ 15: 0] rxdata2_ext;
  input   [ 15: 0] rxdata3_ext;
  input   [  1: 0] rxdatak0_ext;
  input   [  1: 0] rxdatak1_ext;
  input   [  1: 0] rxdatak2_ext;
  input   [  1: 0] rxdatak3_ext;
  input            rxelecidle0_ext;
  input            rxelecidle1_ext;
  input            rxelecidle2_ext;
  input            rxelecidle3_ext;
  input   [  2: 0] rxstatus0_ext;
  input   [  2: 0] rxstatus1_ext;
  input   [  2: 0] rxstatus2_ext;
  input   [  2: 0] rxstatus3_ext;
  input            rxvalid0_ext;
  input            rxvalid1_ext;
  input            rxvalid2_ext;
  input            rxvalid3_ext;
  input            srst;
  input   [ 31: 0] test_in;
  input   [ 74: 0] tx_stream_data0;
  input            tx_stream_valid0;

  wire             app_int_ack;
  wire             app_int_sts;
  wire             app_int_sts_ack_icm;
  wire             app_msi_ack;
  wire    [  4: 0] app_msi_num;
  wire             app_msi_req;
  wire    [  2: 0] app_msi_tc;
  wire    [ 12: 0] cfg_busdev;
  wire    [ 12: 0] cfg_busdev_icm;
  wire    [ 31: 0] cfg_devcsr;
  wire    [ 31: 0] cfg_devcsr_icm;
  wire    [ 31: 0] cfg_linkcsr;
  wire    [ 31: 0] cfg_linkcsr_icm;
  wire    [ 15: 0] cfg_msicsr;
  wire    [ 15: 0] cfg_msicsr_icm;
  wire    [ 31: 0] cfg_prmcsr;
  wire    [ 31: 0] cfg_prmcsr_icm;
  wire    [ 23: 0] cfg_tcvcmap;
  wire             clk125_out;
  wire    [  6: 0] cpl_err;
  wire    [  2: 0] cpl_err_icm_int;
  wire    [  2: 0] cpl_err_int;
  wire             cpl_pending;
  wire             dlup_exit;
  wire             hotrst_exit;
  wire             l2_exit;
  wire    [  3: 0] lane_width_code;
  wire             msi_stream_ready0;
  wire    [ 31: 0] open_cfg_pmcsr;
  wire    [ 23: 0] open_cfg_tcvcmap_icm;
  wire    [ 19: 0] open_ko_cpl_spc_vc0;
  wire    [  4: 0] pex_msi_num;
  wire    [  3: 0] phy_sel_code;
  wire             pme_to_sr;
  wire    [  1: 0] powerdown_ext;
  wire    [ 16: 0] reconfig_fromgxb;
  wire    [  3: 0] ref_clk_sel_code;
  wire             rx_abort0;
  wire             rx_ack0;
  wire    [  7: 0] rx_be0;
  wire    [ 63: 0] rx_data0;
  wire    [135: 0] rx_desc0;
  wire             rx_dfr0;
  wire             rx_dv0;
  wire             rx_mask0;
  wire             rx_req0;
  wire             rx_retry0;
  wire    [ 81: 0] rx_stream_data0;
  wire             rx_stream_valid0;
  wire             rx_ws0;
  wire             rxpolarity0_ext;
  wire             rxpolarity1_ext;
  wire             rxpolarity2_ext;
  wire             rxpolarity3_ext;
  wire    [ 31: 0] test_in_int;
  wire    [  8: 0] test_out_icm;
  wire    [  8: 0] test_out_int;
  wire    [  8: 0] test_out_wire;
  wire             tx_ack0;
  wire    [ 21: 0] tx_cred0_int;
  wire    [ 63: 0] tx_data0;
  wire    [127: 0] tx_desc0;
  wire             tx_dfr0;
  wire             tx_dv0;
  wire             tx_err0;
  wire    [ 11: 0] tx_npcredd0;
  wire             tx_npcredd_inf0;
  wire    [  7: 0] tx_npcredh0;
  wire             tx_npcredh_inf0;
  wire             tx_out0;
  wire             tx_out1;
  wire             tx_out2;
  wire             tx_out3;
  wire             tx_req0;
  wire    [ 21: 0] tx_stream_cred0;
  wire             tx_stream_mask0;
  wire             tx_stream_ready0;
  wire             tx_ws0;
  wire             txcompl0_ext;
  wire             txcompl1_ext;
  wire             txcompl2_ext;
  wire             txcompl3_ext;
  wire    [ 15: 0] txdata0_ext;
  wire    [ 15: 0] txdata1_ext;
  wire    [ 15: 0] txdata2_ext;
  wire    [ 15: 0] txdata3_ext;
  wire    [  1: 0] txdatak0_ext;
  wire    [  1: 0] txdatak1_ext;
  wire    [  1: 0] txdatak2_ext;
  wire    [  1: 0] txdatak3_ext;
  wire             txdetectrx_ext;
  wire             txelecidle0_ext;
  wire             txelecidle1_ext;
  wire             txelecidle2_ext;
  wire             txelecidle3_ext;
  assign ref_clk_sel_code = 0;
  assign lane_width_code = 2;
  assign phy_sel_code = 6;
  assign test_out_wire = test_out_int;
  assign test_in_int = {23'h000000,test_in[8 : 5],1'b0,test_in[3],2'b00,test_in[0]};
  assign cpl_err = {cpl_err_int,4'h0};
  assign cpl_err_icm_int = cpl_err_icm[2 : 0];
  assign tx_npcredh0 = tx_cred0_int[10];
  assign tx_npcredd0 = tx_cred0_int[11];
  assign tx_npcredh_inf0 = 1'b0;
  assign tx_npcredd_inf0 = 1'b0;
  pcie_hip_s4gx_gen2_x4_128 epmap
    (
      .app_int_ack (app_int_ack),
      .app_int_sts (app_int_sts),
      .app_msi_ack (app_msi_ack),
      .app_msi_num (app_msi_num),
      .app_msi_req (app_msi_req),
      .app_msi_tc (app_msi_tc),
      .cal_blk_clk (cal_blk_clk),
      .cfg_busdev (cfg_busdev),
      .cfg_devcsr (cfg_devcsr),
      .cfg_linkcsr (cfg_linkcsr),
      .cfg_msicsr (cfg_msicsr),
      .cfg_pmcsr (open_cfg_pmcsr),
      .cfg_prmcsr (cfg_prmcsr),
      .cfg_tcvcmap (cfg_tcvcmap),
      .clk125_in (clk125_in),
      .clk125_out (clk125_out),
      .cpl_err (cpl_err),
      .cpl_pending (cpl_pending),
      .crst (crst),
      .dlup_exit (dlup_exit),
      .gxb_powerdown (gxb_powerdown),
      .hotrst_exit (hotrst_exit),
      .ko_cpl_spc_vc0 (open_ko_cpl_spc_vc0),
      .l2_exit (l2_exit),
      .npor (npor),
      .pex_msi_num (pex_msi_num),
      .phystatus_ext (phystatus_ext),
      .pipe_mode (pipe_mode),
      .pll_powerdown (pll_powerdown),
      .pme_to_cr (pme_to_cr),
      .pme_to_sr (pme_to_sr),
      .powerdown_ext (powerdown_ext),
      .reconfig_clk (reconfig_clk),
      .reconfig_fromgxb (reconfig_fromgxb),
      .reconfig_togxb (reconfig_togxb),
      .refclk (refclk),
      .rx_abort0 (rx_abort0),
      .rx_ack0 (rx_ack0),
      .rx_be0 (rx_be0),
      .rx_data0 (rx_data0),
      .rx_desc0 (rx_desc0),
      .rx_dfr0 (rx_dfr0),
      .rx_dv0 (rx_dv0),
      .rx_in0 (rx_in0),
      .rx_in1 (rx_in1),
      .rx_in2 (rx_in2),
      .rx_in3 (rx_in3),
      .rx_mask0 (rx_mask0),
      .rx_req0 (rx_req0),
      .rx_retry0 (rx_retry0),
      .rx_ws0 (rx_ws0),
      .rxdata0_ext (rxdata0_ext),
      .rxdata1_ext (rxdata1_ext),
      .rxdata2_ext (rxdata2_ext),
      .rxdata3_ext (rxdata3_ext),
      .rxdatak0_ext (rxdatak0_ext),
      .rxdatak1_ext (rxdatak1_ext),
      .rxdatak2_ext (rxdatak2_ext),
      .rxdatak3_ext (rxdatak3_ext),
      .rxelecidle0_ext (rxelecidle0_ext),
      .rxelecidle1_ext (rxelecidle1_ext),
      .rxelecidle2_ext (rxelecidle2_ext),
      .rxelecidle3_ext (rxelecidle3_ext),
      .rxpolarity0_ext (rxpolarity0_ext),
      .rxpolarity1_ext (rxpolarity1_ext),
      .rxpolarity2_ext (rxpolarity2_ext),
      .rxpolarity3_ext (rxpolarity3_ext),
      .rxstatus0_ext (rxstatus0_ext),
      .rxstatus1_ext (rxstatus1_ext),
      .rxstatus2_ext (rxstatus2_ext),
      .rxstatus3_ext (rxstatus3_ext),
      .rxvalid0_ext (rxvalid0_ext),
      .rxvalid1_ext (rxvalid1_ext),
      .rxvalid2_ext (rxvalid2_ext),
      .rxvalid3_ext (rxvalid3_ext),
      .srst (srst),
      .test_in (test_in_int),
      .test_out (test_out_int),
      .tx_ack0 (tx_ack0),
      .tx_cred0 (tx_cred0_int),
      .tx_data0 (tx_data0),
      .tx_desc0 (tx_desc0),
      .tx_dfr0 (tx_dfr0),
      .tx_dv0 (tx_dv0),
      .tx_err0 (tx_err0),
      .tx_out0 (tx_out0),
      .tx_out1 (tx_out1),
      .tx_out2 (tx_out2),
      .tx_out3 (tx_out3),
      .tx_req0 (tx_req0),
      .tx_ws0 (tx_ws0),
      .txcompl0_ext (txcompl0_ext),
      .txcompl1_ext (txcompl1_ext),
      .txcompl2_ext (txcompl2_ext),
      .txcompl3_ext (txcompl3_ext),
      .txdata0_ext (txdata0_ext),
      .txdata1_ext (txdata1_ext),
      .txdata2_ext (txdata2_ext),
      .txdata3_ext (txdata3_ext),
      .txdatak0_ext (txdatak0_ext),
      .txdatak1_ext (txdatak1_ext),
      .txdatak2_ext (txdatak2_ext),
      .txdatak3_ext (txdatak3_ext),
      .txdetectrx_ext (txdetectrx_ext),
      .txelecidle0_ext (txelecidle0_ext),
      .txelecidle1_ext (txelecidle1_ext),
      .txelecidle2_ext (txelecidle2_ext),
      .txelecidle3_ext (txelecidle3_ext)
    );


  altpcierd_icm_top icm
    (
      .app_int_sts (app_int_sts),
      .app_int_sts_ack (app_int_ack),
      .app_int_sts_ack_icm (app_int_sts_ack_icm),
      .app_int_sts_icm (app_int_sts_icm),
      .app_msi_ack (app_msi_ack),
      .app_msi_num (app_msi_num),
      .app_msi_req (app_msi_req),
      .app_msi_tc (app_msi_tc),
      .cfg_busdev (cfg_busdev),
      .cfg_busdev_icm (cfg_busdev_icm),
      .cfg_devcsr (cfg_devcsr),
      .cfg_devcsr_icm (cfg_devcsr_icm),
      .cfg_linkcsr (cfg_linkcsr),
      .cfg_linkcsr_icm (cfg_linkcsr_icm),
      .cfg_msicsr (cfg_msicsr),
      .cfg_msicsr_icm (cfg_msicsr_icm),
      .cfg_prmcsr (cfg_prmcsr),
      .cfg_prmcsr_icm (cfg_prmcsr_icm),
      .cfg_tcvcmap (cfg_tcvcmap),
      .cfg_tcvcmap_icm (open_cfg_tcvcmap_icm),
      .clk (clk125_in),
      .cpl_err (cpl_err_int),
      .cpl_err_icm (cpl_err_icm_int),
      .cpl_pending (cpl_pending),
      .cpl_pending_icm (cpl_pending_icm),
      .msi_stream_data0 (msi_stream_data0),
      .msi_stream_ready0 (msi_stream_ready0),
      .msi_stream_valid0 (msi_stream_valid0),
      .pex_msi_num (pex_msi_num),
      .pex_msi_num_icm (pex_msi_num_icm),
      .rstn (rstn),
      .rx_abort0 (rx_abort0),
      .rx_ack0 (rx_ack0),
      .rx_be0 (rx_be0),
      .rx_data0 (rx_data0),
      .rx_desc0 (rx_desc0),
      .rx_dfr0 (rx_dfr0),
      .rx_dv0 (rx_dv0),
      .rx_mask0 (rx_mask0),
      .rx_req0 (rx_req0),
      .rx_retry0 (rx_retry0),
      .rx_stream_data0 (rx_stream_data0),
      .rx_stream_mask0 (rx_stream_mask0),
      .rx_stream_ready0 (rx_stream_ready0),
      .rx_stream_valid0 (rx_stream_valid0),
      .rx_ws0 (rx_ws0),
      .test_out (test_out_wire),
      .test_out_icm (test_out_icm),
      .tx_ack0 (tx_ack0),
      .tx_cred0 (tx_cred0_int),
      .tx_data0 (tx_data0),
      .tx_desc0 (tx_desc0),
      .tx_dfr0 (tx_dfr0),
      .tx_dv0 (tx_dv0),
      .tx_err0 (tx_err0),
      .tx_npcredd0 (tx_npcredd0),
      .tx_npcredd_inf0 (tx_npcredd_inf0),
      .tx_npcredh0 (tx_npcredh0),
      .tx_npcredh_inf0 (tx_npcredh_inf0),
      .tx_req0 (tx_req0),
      .tx_stream_cred0 (tx_stream_cred0),
      .tx_stream_data0 (tx_stream_data0),
      .tx_stream_mask0 (tx_stream_mask0),
      .tx_stream_ready0 (tx_stream_ready0),
      .tx_stream_valid0 (tx_stream_valid0),
      .tx_ws0 (tx_ws0)
    );

  defparam icm.TXCRED_WIDTH = 22;


endmodule

