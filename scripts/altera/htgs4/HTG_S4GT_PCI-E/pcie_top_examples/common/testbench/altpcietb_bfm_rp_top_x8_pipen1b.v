`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express BFM with Root Port 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_rp_top_x8_pipen1b.vhd
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This entity is the entire PCI Ecpress Root Port BFM
//-----------------------------------------------------------------------------
// Copyright (c) 2005 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation 
// and therefore all warranties, representations or guarantees of any kind 
// (whether express, implied or statutory) including, without limitation, warranties of 
// merchantability, non-infringement, or fitness for a particular purpose, are 
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------
module altpcietb_bfm_rp_top_x8_pipen1b (clk250_in, clk500_in, local_rstn, pcie_rstn, swdn_out, rx_in0, tx_out0, rx_in1, tx_out1, rx_in2, tx_out2, rx_in3, tx_out3, rx_in4, tx_out4, rx_in5, tx_out5, rx_in6, tx_out6, rx_in7, tx_out7, pipe_mode, test_in, test_out, txdata0_ext, txdatak0_ext, txdetectrx0_ext, txelecidle0_ext, txcompl0_ext, rxpolarity0_ext, powerdown0_ext, rxdata0_ext, rxdatak0_ext, rxvalid0_ext, phystatus0_ext, rxelecidle0_ext, rxstatus0_ext, txdata1_ext, txdatak1_ext, txdetectrx1_ext, txelecidle1_ext, txcompl1_ext, rxpolarity1_ext, powerdown1_ext, rxdata1_ext, rxdatak1_ext, rxvalid1_ext, phystatus1_ext, rxelecidle1_ext, rxstatus1_ext, txdata2_ext, txdatak2_ext, txdetectrx2_ext, txelecidle2_ext, txcompl2_ext, rxpolarity2_ext, powerdown2_ext, rxdata2_ext, rxdatak2_ext, rxvalid2_ext, phystatus2_ext, rxelecidle2_ext, rxstatus2_ext, txdata3_ext, txdatak3_ext, txdetectrx3_ext, txelecidle3_ext, txcompl3_ext, rxpolarity3_ext, powerdown3_ext, rxdata3_ext, rxdatak3_ext, rxvalid3_ext, phystatus3_ext, rxelecidle3_ext, rxstatus3_ext, txdata4_ext, txdatak4_ext, txdetectrx4_ext, txelecidle4_ext, txcompl4_ext, rxpolarity4_ext, powerdown4_ext, rxdata4_ext, rxdatak4_ext, rxvalid4_ext, phystatus4_ext, rxelecidle4_ext, rxstatus4_ext, txdata5_ext, txdatak5_ext, txdetectrx5_ext, txelecidle5_ext, txcompl5_ext, rxpolarity5_ext, powerdown5_ext, rxdata5_ext, rxdatak5_ext, rxvalid5_ext, phystatus5_ext, rxelecidle5_ext, rxstatus5_ext, txdata6_ext, txdatak6_ext, txdetectrx6_ext, txelecidle6_ext, txcompl6_ext, rxpolarity6_ext, powerdown6_ext, rxdata6_ext, rxdatak6_ext, rxvalid6_ext, phystatus6_ext, rxelecidle6_ext, rxstatus6_ext, txdata7_ext, txdatak7_ext, txdetectrx7_ext, txelecidle7_ext, txcompl7_ext, rxpolarity7_ext, powerdown7_ext, rxdata7_ext, rxdatak7_ext, rxvalid7_ext, phystatus7_ext, rxelecidle7_ext, rxstatus7_ext,rate_ext);

   `include "altpcietb_bfm_constants.v"
   `include "altpcietb_bfm_log.v"
   `include "altpcietb_bfm_shmem.v"

   input clk250_in;
   input clk500_in; 
   input local_rstn; 
   input pcie_rstn; 
   output [5:0] swdn_out;
   input rx_in0; 
   output tx_out0; 
   wire tx_out0;
   input rx_in1; 
   output tx_out1; 
   wire tx_out1;
   input rx_in2; 
   output tx_out2; 
   wire tx_out2;
   input rx_in3; 
   output tx_out3; 
   wire tx_out3;
   input rx_in4; 
   output tx_out4; 
   wire tx_out4;
   input rx_in5; 
   output tx_out5; 
   wire tx_out5;
   input rx_in6; 
   output tx_out6; 
   wire tx_out6;
   input rx_in7; 
   output tx_out7; 
   wire tx_out7;
   input pipe_mode; 
   input[31:0] test_in; 
   output[511:0] test_out; 
   wire[511:0] test_out;
   output[7:0] txdata0_ext; 
   wire[7:0] txdata0_ext;
   output txdatak0_ext; 
   wire txdatak0_ext;
   output txdetectrx0_ext;
   wire txdetectrx0_ext;
output rate_ext;
   output txelecidle0_ext; 
   wire txelecidle0_ext;
   output txcompl0_ext; 
   wire txcompl0_ext;
   output rxpolarity0_ext; 
   wire rxpolarity0_ext;
   output[1:0] powerdown0_ext; 
   wire[1:0] powerdown0_ext;
   input[7:0] rxdata0_ext; 
   input rxdatak0_ext; 
   input rxvalid0_ext; 
   input phystatus0_ext; 
   input rxelecidle0_ext; 
   input[2:0] rxstatus0_ext; 
   output[7:0] txdata1_ext; 
   wire[7:0] txdata1_ext;
   output txdatak1_ext; 
   wire txdatak1_ext;
   output txdetectrx1_ext; 
   wire txdetectrx1_ext;
   output txelecidle1_ext; 
   wire txelecidle1_ext;
   output txcompl1_ext; 
   wire txcompl1_ext;
   output rxpolarity1_ext; 
   wire rxpolarity1_ext;
   output[1:0] powerdown1_ext; 
   wire[1:0] powerdown1_ext;
   input[7:0] rxdata1_ext; 
   input rxdatak1_ext; 
   input rxvalid1_ext; 
   input phystatus1_ext; 
   input rxelecidle1_ext; 
   input[2:0] rxstatus1_ext; 
   output[7:0] txdata2_ext; 
   wire[7:0] txdata2_ext;
   output txdatak2_ext; 
   wire txdatak2_ext;
   output txdetectrx2_ext; 
   wire txdetectrx2_ext;
   output txelecidle2_ext; 
   wire txelecidle2_ext;
   output txcompl2_ext; 
   wire txcompl2_ext;
   output rxpolarity2_ext; 
   wire rxpolarity2_ext;
   output[1:0] powerdown2_ext; 
   wire[1:0] powerdown2_ext;
   input[7:0] rxdata2_ext; 
   input rxdatak2_ext; 
   input rxvalid2_ext; 
   input phystatus2_ext; 
   input rxelecidle2_ext; 
   input[2:0] rxstatus2_ext; 
   output[7:0] txdata3_ext; 
   wire[7:0] txdata3_ext;
   output txdatak3_ext; 
   wire txdatak3_ext;
   output txdetectrx3_ext; 
   wire txdetectrx3_ext;
   output txelecidle3_ext; 
   wire txelecidle3_ext;
   output txcompl3_ext; 
   wire txcompl3_ext;
   output rxpolarity3_ext; 
   wire rxpolarity3_ext;
   output[1:0] powerdown3_ext; 
   wire[1:0] powerdown3_ext;
   input[7:0] rxdata3_ext; 
   input rxdatak3_ext; 
   input rxvalid3_ext; 
   input phystatus3_ext; 
   input rxelecidle3_ext; 
   input[2:0] rxstatus3_ext; 
   output[7:0] txdata4_ext; 
   wire[7:0] txdata4_ext;
   output txdatak4_ext; 
   wire txdatak4_ext;
   output txdetectrx4_ext; 
   wire txdetectrx4_ext;
   output txelecidle4_ext; 
   wire txelecidle4_ext;
   output txcompl4_ext; 
   wire txcompl4_ext;
   output rxpolarity4_ext; 
   wire rxpolarity4_ext;
   output[1:0] powerdown4_ext; 
   wire[1:0] powerdown4_ext;
   input[7:0] rxdata4_ext; 
   input rxdatak4_ext; 
   input rxvalid4_ext; 
   input phystatus4_ext; 
   input rxelecidle4_ext; 
   input[2:0] rxstatus4_ext; 
   output[7:0] txdata5_ext; 
   wire[7:0] txdata5_ext;
   output txdatak5_ext; 
   wire txdatak5_ext;
   output txdetectrx5_ext; 
   wire txdetectrx5_ext;
   output txelecidle5_ext; 
   wire txelecidle5_ext;
   output txcompl5_ext; 
   wire txcompl5_ext;
   output rxpolarity5_ext; 
   wire rxpolarity5_ext;
   output[1:0] powerdown5_ext; 
   wire[1:0] powerdown5_ext;
   input[7:0] rxdata5_ext; 
   input rxdatak5_ext; 
   input rxvalid5_ext; 
   input phystatus5_ext; 
   input rxelecidle5_ext; 
   input[2:0] rxstatus5_ext; 
   output[7:0] txdata6_ext; 
   wire[7:0] txdata6_ext;
   output txdatak6_ext; 
   wire txdatak6_ext;
   output txdetectrx6_ext; 
   wire txdetectrx6_ext;
   output txelecidle6_ext; 
   wire txelecidle6_ext;
   output txcompl6_ext; 
   wire txcompl6_ext;
   output rxpolarity6_ext; 
   wire rxpolarity6_ext;
   output[1:0] powerdown6_ext; 
   wire[1:0] powerdown6_ext;
   input[7:0] rxdata6_ext; 
   input rxdatak6_ext; 
   input rxvalid6_ext; 
   input phystatus6_ext; 
   input rxelecidle6_ext; 
   input[2:0] rxstatus6_ext; 
   output[7:0] txdata7_ext; 
   wire[7:0] txdata7_ext;
   output txdatak7_ext; 
   wire txdatak7_ext;
   output txdetectrx7_ext; 
   wire txdetectrx7_ext;
   output txelecidle7_ext; 
   wire txelecidle7_ext;
   output txcompl7_ext; 
   wire txcompl7_ext;
   output rxpolarity7_ext; 
   wire rxpolarity7_ext;
   output[1:0] powerdown7_ext; 
   wire[1:0] powerdown7_ext;
   input[7:0] rxdata7_ext; 
   input rxdatak7_ext; 
   input rxvalid7_ext; 
   input phystatus7_ext; 
   input rxelecidle7_ext; 
   input[2:0] rxstatus7_ext; 

   wire[127:0] GND_BUS; 
   wire l2_exit; 
   wire hotrst_exit; 
   wire dlup_exit; 
   wire cpl_pending; 
   wire[2:0] cpl_err; 
   wire pme_to_cr; 
   wire pme_to_sr; 
   wire pm_auxpwr; 
   wire[6:0] slotcap_in; 
   wire[12:0] slotnum_in; 
   wire serr_out; 
   wire app_int_sts; 
   wire app_msi_req; 
   wire app_msi_ack; 
   wire[2:0] app_msi_tc; 
   wire[12:0] cfg_busdev; 
   wire[31:0] cfg_prmcsr; 
   wire[31:0] cfg_pmcsr; 
   wire[15:0] cfg_msicsr; 
   wire[31:0] cfg_devcsr; 
   wire[31:0] cfg_linkcsr; 
   wire[31:0] cfg_slotcsr; 
   wire[31:0] cfg_rootcsr; 
   wire[31:0] cfg_seccsr; 
   wire[7:0] cfg_secbus; 
   wire[7:0] cfg_subbus; 
   wire[19:0] cfg_io_bas; 
   wire[19:0] cfg_io_lim; 
   wire[11:0] cfg_np_bas; 
   wire[11:0] cfg_np_lim; 
   wire[43:0] cfg_pr_bas; 
   wire[43:0] cfg_pr_lim; 
   wire[23:0] cfg_tcvcmap; 
   wire[21:0] tx_cred0; 
   wire[21:0] tx_cred1; 
   wire[21:0] tx_cred2; 
   wire[21:0] tx_cred3; 
   wire rx_req0; 
   wire rx_ack0; 
   wire rx_abort0; 
   wire rx_retry0; 
   wire rx_mask0; 
   wire[135:0] rx_desc0; 
   wire rx_ws0; 
   wire[63:0] rx_data0; 
   wire[7:0] rx_be0; 
   wire rx_dv0; 
   wire rx_dfr0; 
   wire tx_req0; 
   wire[127:0] tx_desc0; 
   wire tx_ack0; 
   wire tx_dfr0; 
   wire[63:0] tx_data0; 
   wire tx_dv0; 
   wire tx_err0; 
   wire tx_ws0; 
   wire rx_req1; 
   wire rx_ack1; 
   wire rx_abort1; 
   wire rx_retry1; 
   wire rx_mask1; 
   wire[135:0] rx_desc1; 
   wire rx_ws1; 
   wire[63:0] rx_data1; 
   wire[7:0] rx_be1; 
   wire rx_dv1; 
   wire rx_dfr1; 
   wire tx_req1; 
   wire[127:0] tx_desc1; 
   wire tx_ack1; 
   wire tx_dfr1; 
   wire[63:0] tx_data1; 
   wire tx_dv1; 
   wire tx_err1; 
   wire tx_ws1; 
   wire rx_req2; 
   wire rx_ack2; 
   wire rx_abort2; 
   wire rx_retry2; 
   wire rx_mask2; 
   wire[135:0] rx_desc2; 
   wire rx_ws2; 
   wire[63:0] rx_data2; 
   wire[7:0] rx_be2; 
   wire rx_dv2; 
   wire rx_dfr2; 
   wire tx_req2; 
   wire[127:0] tx_desc2; 
   wire tx_ack2; 
   wire tx_dfr2; 
   wire[63:0] tx_data2; 
   wire tx_dv2; 
   wire tx_err2; 
   wire tx_ws2; 
   wire rx_req3; 
   wire rx_ack3; 
   wire rx_abort3; 
   wire rx_retry3; 
   wire rx_mask3; 
   wire[135:0] rx_desc3; 
   wire rx_ws3; 
   wire[63:0] rx_data3; 
   wire[7:0] rx_be3; 
   wire rx_dv3; 
   wire rx_dfr3; 
   wire tx_req3; 
   wire[127:0] tx_desc3; 
   wire tx_ack3; 
   wire tx_dfr3; 
   wire[63:0] tx_data3; 
   wire tx_dv3; 
   wire tx_err3; 
   wire tx_ws3; 
   reg[24:0] rsnt_cnt; 
   reg rstn; 
   wire npor; 
   wire crst; 
   wire srst;
   wire coreclk_out;
wire 	clk_in = (pipe_mode == 0) ? coreclk_out :  ( rate_ext == 1) ? clk500_in : clk250_in;


   assign GND_BUS = {128{1'b0}} ;

   always @(posedge clk250_in or negedge pcie_rstn)
   begin
      if (pcie_rstn == 1'b0)
      begin
         rsnt_cnt <= {25{1'b0}} ; 
         rstn <= 1'b0 ; 
      end
      else
      begin
         if (rsnt_cnt != 25'b1110111001101011001010000)
         begin
            rsnt_cnt <= rsnt_cnt + 1 ; 
         end 
         if (local_rstn == 1'b0 | l2_exit == 1'b0 | hotrst_exit == 1'b0 | dlup_exit == 1'b0)
         begin
            rstn <= 1'b0 ; 
         end
         else if ((test_in[0]) == 1'b1 & rsnt_cnt == 25'b0000000000000000000100000)
         begin
            rstn <= 1'b1 ; 
         end
         else if (rsnt_cnt == 25'b1110111001101011001010000)
         begin
            rstn <= 1'b1 ; 
         end 
      end 
   end 
   assign npor = pcie_rstn & local_rstn ;
   assign srst = ~(hotrst_exit & l2_exit & dlup_exit & rstn) ;
   assign crst = ~(hotrst_exit & l2_exit & rstn) ;
   assign cpl_pending = 1'b0 ;
   assign cpl_err = 3'b000 ;
   assign pm_auxpwr = 1'b0 ;
   assign slotcap_in = 7'b0000000 ;
   assign slotnum_in = 13'b0000000000000 ;
   assign app_int_sts = 1'b0 ;
   assign app_msi_req = 1'b0 ;
   assign app_msi_tc = 3'b000 ;
   altpcietb_bfm_rpvar_64b_x8_pipen1b rp (
      .pclk_in(clk_in),
      .ep_clk250_in(clk250_in),
      .coreclk_out(coreclk_out), 
      .npor(npor), 
      .crst(crst), 
      .srst(srst), 
      .rx_in0(rx_in0), 
      .tx_out0(tx_out0), 
      .rx_in1(rx_in1), 
      .tx_out1(tx_out1), 
      .rx_in2(rx_in2), 
      .tx_out2(tx_out2), 
      .rx_in3(rx_in3), 
      .tx_out3(tx_out3), 
      .rx_in4(rx_in4), 
      .tx_out4(tx_out4), 
      .rx_in5(rx_in5), 
      .tx_out5(tx_out5), 
      .rx_in6(rx_in6), 
      .tx_out6(tx_out6), 
      .rx_in7(rx_in7), 
      .tx_out7(tx_out7), 
      .pipe_mode(pipe_mode),
      .rate_ext(rate_ext),
      .txdata0_ext(txdata0_ext), 
      .txdatak0_ext(txdatak0_ext), 
      .txdetectrx0_ext(txdetectrx0_ext), 
      .txelecidle0_ext(txelecidle0_ext), 
      .txcompl0_ext(txcompl0_ext), 
      .rxpolarity0_ext(rxpolarity0_ext), 
      .powerdown0_ext(powerdown0_ext), 
      .rxdata0_ext(rxdata0_ext), 
      .rxdatak0_ext(rxdatak0_ext), 
      .rxvalid0_ext(rxvalid0_ext), 
      .phystatus0_ext(phystatus0_ext), 
      .rxelecidle0_ext(rxelecidle0_ext), 
      .rxstatus0_ext(rxstatus0_ext), 
      .txdata1_ext(txdata1_ext), 
      .txdatak1_ext(txdatak1_ext), 
      .txdetectrx1_ext(txdetectrx1_ext), 
      .txelecidle1_ext(txelecidle1_ext), 
      .txcompl1_ext(txcompl1_ext), 
      .rxpolarity1_ext(rxpolarity1_ext), 
      .powerdown1_ext(powerdown1_ext), 
      .rxdata1_ext(rxdata1_ext), 
      .rxdatak1_ext(rxdatak1_ext), 
      .rxvalid1_ext(rxvalid1_ext), 
      .phystatus1_ext(phystatus1_ext), 
      .rxelecidle1_ext(rxelecidle1_ext), 
      .rxstatus1_ext(rxstatus1_ext), 
      .txdata2_ext(txdata2_ext), 
      .txdatak2_ext(txdatak2_ext), 
      .txdetectrx2_ext(txdetectrx2_ext), 
      .txelecidle2_ext(txelecidle2_ext), 
      .txcompl2_ext(txcompl2_ext), 
      .rxpolarity2_ext(rxpolarity2_ext), 
      .powerdown2_ext(powerdown2_ext), 
      .rxdata2_ext(rxdata2_ext), 
      .rxdatak2_ext(rxdatak2_ext), 
      .rxvalid2_ext(rxvalid2_ext), 
      .phystatus2_ext(phystatus2_ext), 
      .rxelecidle2_ext(rxelecidle2_ext), 
      .rxstatus2_ext(rxstatus2_ext), 
      .txdata3_ext(txdata3_ext), 
      .txdatak3_ext(txdatak3_ext), 
      .txdetectrx3_ext(txdetectrx3_ext), 
      .txelecidle3_ext(txelecidle3_ext), 
      .txcompl3_ext(txcompl3_ext), 
      .rxpolarity3_ext(rxpolarity3_ext), 
      .powerdown3_ext(powerdown3_ext), 
      .rxdata3_ext(rxdata3_ext), 
      .rxdatak3_ext(rxdatak3_ext), 
      .rxvalid3_ext(rxvalid3_ext), 
      .phystatus3_ext(phystatus3_ext), 
      .rxelecidle3_ext(rxelecidle3_ext), 
      .rxstatus3_ext(rxstatus3_ext), 
      .txdata4_ext(txdata4_ext), 
      .txdatak4_ext(txdatak4_ext), 
      .txdetectrx4_ext(txdetectrx4_ext), 
      .txelecidle4_ext(txelecidle4_ext), 
      .txcompl4_ext(txcompl4_ext), 
      .rxpolarity4_ext(rxpolarity4_ext), 
      .powerdown4_ext(powerdown4_ext), 
      .rxdata4_ext(rxdata4_ext), 
      .rxdatak4_ext(rxdatak4_ext), 
      .rxvalid4_ext(rxvalid4_ext), 
      .phystatus4_ext(phystatus4_ext), 
      .rxelecidle4_ext(rxelecidle4_ext), 
      .rxstatus4_ext(rxstatus4_ext), 
      .txdata5_ext(txdata5_ext), 
      .txdatak5_ext(txdatak5_ext), 
      .txdetectrx5_ext(txdetectrx5_ext), 
      .txelecidle5_ext(txelecidle5_ext), 
      .txcompl5_ext(txcompl5_ext), 
      .rxpolarity5_ext(rxpolarity5_ext), 
      .powerdown5_ext(powerdown5_ext), 
      .rxdata5_ext(rxdata5_ext), 
      .rxdatak5_ext(rxdatak5_ext), 
      .rxvalid5_ext(rxvalid5_ext), 
      .phystatus5_ext(phystatus5_ext), 
      .rxelecidle5_ext(rxelecidle5_ext), 
      .rxstatus5_ext(rxstatus5_ext), 
      .txdata6_ext(txdata6_ext), 
      .txdatak6_ext(txdatak6_ext), 
      .txdetectrx6_ext(txdetectrx6_ext), 
      .txelecidle6_ext(txelecidle6_ext), 
      .txcompl6_ext(txcompl6_ext), 
      .rxpolarity6_ext(rxpolarity6_ext), 
      .powerdown6_ext(powerdown6_ext), 
      .rxdata6_ext(rxdata6_ext), 
      .rxdatak6_ext(rxdatak6_ext), 
      .rxvalid6_ext(rxvalid6_ext), 
      .phystatus6_ext(phystatus6_ext), 
      .rxelecidle6_ext(rxelecidle6_ext), 
      .rxstatus6_ext(rxstatus6_ext), 
      .txdata7_ext(txdata7_ext), 
      .txdatak7_ext(txdatak7_ext), 
      .txdetectrx7_ext(txdetectrx7_ext), 
      .txelecidle7_ext(txelecidle7_ext), 
      .txcompl7_ext(txcompl7_ext), 
      .rxpolarity7_ext(rxpolarity7_ext), 
      .powerdown7_ext(powerdown7_ext), 
      .rxdata7_ext(rxdata7_ext), 
      .rxdatak7_ext(rxdatak7_ext), 
      .rxvalid7_ext(rxvalid7_ext), 
      .phystatus7_ext(phystatus7_ext), 
      .rxelecidle7_ext(rxelecidle7_ext), 
      .rxstatus7_ext(rxstatus7_ext), 
      .test_in(test_in), 
      .test_out(test_out), 
      .l2_exit(l2_exit), 
      .hotrst_exit(hotrst_exit), 
      .dlup_exit(dlup_exit), 
      .cpl_pending(cpl_pending), 
      .cpl_err(cpl_err), 
      .pme_to_cr(pme_to_cr), 
      .pme_to_sr(pme_to_cr), 
      .pm_auxpwr(pm_auxpwr), 
      .slotcap_in(slotcap_in), 
      .slotnum_in(slotnum_in), 
      .serr_out(serr_out), 
      .swdn_out(swdn_out),
      .app_int_sts(app_int_sts), 
      .app_msi_req(app_msi_req), 
      .app_msi_ack(app_msi_ack), 
      .app_msi_tc(app_msi_tc), 
      .cfg_busdev(cfg_busdev), 
      .cfg_prmcsr(cfg_prmcsr), 
      .cfg_pmcsr(cfg_pmcsr), 
      .cfg_msicsr(cfg_msicsr), 
      .cfg_devcsr(cfg_devcsr), 
      .cfg_linkcsr(cfg_linkcsr), 
      .cfg_slotcsr(cfg_slotcsr), 
      .cfg_rootcsr(cfg_rootcsr), 
      .cfg_seccsr(cfg_seccsr), 
      .cfg_secbus(cfg_secbus), 
      .cfg_subbus(cfg_subbus), 
      .cfg_io_bas(cfg_io_bas), 
      .cfg_io_lim(cfg_io_lim), 
      .cfg_np_bas(cfg_np_bas), 
      .cfg_np_lim(cfg_np_lim), 
      .cfg_pr_bas(cfg_pr_bas), 
      .cfg_pr_lim(cfg_pr_lim), 
      .cfg_tcvcmap(cfg_tcvcmap), 
      .tx_cred0(tx_cred0), 
      .tx_cred1(tx_cred1), 
      .tx_cred2(tx_cred2), 
      .tx_cred3(tx_cred3), 
      .rx_req0(rx_req0), 
      .rx_ack0(rx_ack0), 
      .rx_abort0(rx_abort0), 
      .rx_retry0(rx_retry0), 
      .rx_mask0(rx_mask0), 
      .rx_desc0(rx_desc0), 
      .rx_ws0(rx_ws0), 
      .rx_data0(rx_data0), 
      .rx_be0(rx_be0), 
      .rx_dv0(rx_dv0), 
      .rx_dfr0(rx_dfr0), 
      .tx_req0(tx_req0), 
      .tx_desc0(tx_desc0), 
      .tx_ack0(tx_ack0), 
      .tx_dfr0(tx_dfr0), 
      .tx_data0(tx_data0), 
      .tx_dv0(tx_dv0), 
      .tx_err0(tx_err0), 
      .tx_ws0(tx_ws0), 
      .rx_req1(rx_req1), 
      .rx_ack1(rx_ack1), 
      .rx_abort1(rx_abort1), 
      .rx_retry1(rx_retry1), 
      .rx_mask1(rx_mask1), 
      .rx_desc1(rx_desc1), 
      .rx_ws1(rx_ws1), 
      .rx_data1(rx_data1), 
      .rx_be1(rx_be1), 
      .rx_dv1(rx_dv1), 
      .rx_dfr1(rx_dfr1), 
      .tx_req1(tx_req1), 
      .tx_desc1(tx_desc1), 
      .tx_ack1(tx_ack1), 
      .tx_dfr1(tx_dfr1), 
      .tx_data1(tx_data1), 
      .tx_dv1(tx_dv1), 
      .tx_err1(tx_err1), 
      .tx_ws1(tx_ws1), 
      .rx_req2(rx_req2), 
      .rx_ack2(rx_ack2), 
      .rx_abort2(rx_abort2), 
      .rx_retry2(rx_retry2), 
      .rx_mask2(rx_mask2), 
      .rx_desc2(rx_desc2), 
      .rx_ws2(rx_ws2), 
      .rx_data2(rx_data2), 
      .rx_be2(rx_be2), 
      .rx_dv2(rx_dv2), 
      .rx_dfr2(rx_dfr2), 
      .tx_req2(tx_req2), 
      .tx_desc2(tx_desc2), 
      .tx_ack2(tx_ack2), 
      .tx_dfr2(tx_dfr2), 
      .tx_data2(tx_data2), 
      .tx_dv2(tx_dv2), 
      .tx_err2(tx_err2), 
      .tx_ws2(tx_ws2), 
      .rx_req3(rx_req3), 
      .rx_ack3(rx_ack3), 
      .rx_abort3(rx_abort3), 
      .rx_retry3(rx_retry3), 
      .rx_mask3(rx_mask3), 
      .rx_desc3(rx_desc3), 
      .rx_ws3(rx_ws3), 
      .rx_data3(rx_data3), 
      .rx_be3(rx_be3), 
      .rx_dv3(rx_dv3), 
      .rx_dfr3(rx_dfr3), 
      .tx_req3(tx_req3), 
      .tx_desc3(tx_desc3), 
      .tx_ack3(tx_ack3), 
      .tx_dfr3(tx_dfr3), 
      .tx_data3(tx_data3), 
      .tx_dv3(tx_dv3), 
      .tx_err3(tx_err3), 
      .tx_ws3(tx_ws3)
   ); 

   altpcietb_bfm_vc_intf #(0) vc0(
      .clk_in(clk_in), 
      .rstn(rstn), 
      .rx_req(rx_req0), 
      .rx_ack(rx_ack0), 
      .rx_abort(rx_abort0), 
      .rx_retry(rx_retry0), 
      .rx_mask(rx_mask0), 
      .rx_desc(rx_desc0), 
      .rx_ws(rx_ws0), 
      .rx_data(rx_data0), 
      .rx_be(rx_be0), 
      .rx_dv(rx_dv0), 
      .rx_dfr(rx_dfr0), 
      .tx_cred(tx_cred0), 
      .tx_req(tx_req0), 
      .tx_desc(tx_desc0), 
      .tx_ack(tx_ack0), 
      .tx_dfr(tx_dfr0), 
      .tx_data(tx_data0), 
      .tx_dv(tx_dv0), 
      .tx_err(tx_err0), 
      .tx_ws(tx_ws0), 
      .cfg_io_bas(cfg_io_bas), 
      .cfg_np_bas(cfg_np_bas), 
      .cfg_pr_bas(cfg_pr_bas)
   ); 

   altpcietb_bfm_vc_intf #(1) vc1(
      .clk_in(clk_in), 
      .rstn(rstn), 
      .rx_req(rx_req1), 
      .rx_ack(rx_ack1), 
      .rx_abort(rx_abort1), 
      .rx_retry(rx_retry1), 
      .rx_mask(rx_mask1), 
      .rx_desc(rx_desc1), 
      .rx_ws(rx_ws1), 
      .rx_data(rx_data1), 
      .rx_be(rx_be1), 
      .rx_dv(rx_dv1), 
      .rx_dfr(rx_dfr1), 
      .tx_cred(tx_cred1), 
      .tx_req(tx_req1), 
      .tx_desc(tx_desc1), 
      .tx_ack(tx_ack1), 
      .tx_dfr(tx_dfr1), 
      .tx_data(tx_data1), 
      .tx_dv(tx_dv1), 
      .tx_err(tx_err1), 
      .tx_ws(tx_ws1), 
      .cfg_io_bas(cfg_io_bas), 
      .cfg_np_bas(cfg_np_bas), 
      .cfg_pr_bas(cfg_pr_bas)
   ); 

   altpcietb_bfm_vc_intf #(2) vc2(
      .clk_in(clk_in), 
      .rstn(rstn), 
      .rx_req(rx_req2), 
      .rx_ack(rx_ack2), 
      .rx_abort(rx_abort2), 
      .rx_retry(rx_retry2), 
      .rx_mask(rx_mask2), 
      .rx_desc(rx_desc2), 
      .rx_ws(rx_ws2), 
      .rx_data(rx_data2), 
      .rx_be(rx_be2), 
      .rx_dv(rx_dv2), 
      .rx_dfr(rx_dfr2), 
      .tx_cred(tx_cred2), 
      .tx_req(tx_req2), 
      .tx_desc(tx_desc2), 
      .tx_ack(tx_ack2), 
      .tx_dfr(tx_dfr2), 
      .tx_data(tx_data2), 
      .tx_dv(tx_dv2), 
      .tx_err(tx_err2), 
      .tx_ws(tx_ws2), 
      .cfg_io_bas(cfg_io_bas), 
      .cfg_np_bas(cfg_np_bas), 
      .cfg_pr_bas(cfg_pr_bas)
   ); 

   altpcietb_bfm_vc_intf #(3) vc3(
      .clk_in(clk_in), 
      .rstn(rstn), 
      .rx_req(rx_req3), 
      .rx_ack(rx_ack3), 
      .rx_abort(rx_abort3), 
      .rx_retry(rx_retry3), 
      .rx_mask(rx_mask3), 
      .rx_desc(rx_desc3), 
      .rx_ws(rx_ws3), 
      .rx_data(rx_data3), 
      .rx_be(rx_be3), 
      .rx_dv(rx_dv3), 
      .rx_dfr(rx_dfr3), 
      .tx_cred(tx_cred3), 
      .tx_req(tx_req3), 
      .tx_desc(tx_desc3), 
      .tx_ack(tx_ack3), 
      .tx_dfr(tx_dfr3), 
      .tx_data(tx_data3), 
      .tx_dv(tx_dv3), 
      .tx_err(tx_err3), 
      .tx_ws(tx_ws3), 
      .cfg_io_bas(cfg_io_bas), 
      .cfg_np_bas(cfg_np_bas), 
      .cfg_pr_bas(cfg_pr_bas)
   ); 
endmodule
