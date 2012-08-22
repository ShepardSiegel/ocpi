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

///** This Verilog HDL file is used for synthesis in chaining DMA design example
//*
//* This file provides the top level for synthesis
//*/
module pcie_4243_hip_s4gx_gen2_x8_128_example_chaining_top (
                                                             // inputs:
                                                              free_100MHz,
                                                              local_rstn_ext,
                                                              pcie_rstn,
                                                              refclk,
                                                              req_compliance_push_button_n,
                                                              rx_in0,
                                                              rx_in1,
                                                              rx_in2,
                                                              rx_in3,
                                                              rx_in4,
                                                              rx_in5,
                                                              rx_in6,
                                                              rx_in7,
                                                              usr_sw,

                                                             // outputs:
                                                              L0_led,
                                                              alive_led,
                                                              comp_led,
                                                              gen2_led,
                                                              lane_active_led,
                                                              tx_out0,
                                                              tx_out1,
                                                              tx_out2,
                                                              tx_out3,
                                                              tx_out4,
                                                              tx_out5,
                                                              tx_out6,
                                                              tx_out7
                                                           )
;

  output           L0_led;
  output           alive_led;
  output           comp_led;
  output           gen2_led;
  output  [  3: 0] lane_active_led;
  output           tx_out0;
  output           tx_out1;
  output           tx_out2;
  output           tx_out3;
  output           tx_out4;
  output           tx_out5;
  output           tx_out6;
  output           tx_out7;
  input            free_100MHz;
  input            local_rstn_ext;
  input            pcie_rstn;
  input            refclk;
  input            req_compliance_push_button_n;
  input            rx_in0;
  input            rx_in1;
  input            rx_in2;
  input            rx_in3;
  input            rx_in4;
  input            rx_in5;
  input            rx_in6;
  input            rx_in7;
  input   [  7: 0] usr_sw;

  reg              L0_led;
  reg     [ 25: 0] alive_cnt;
  reg              alive_led;
  wire             any_rstn;
  reg              any_rstn_r /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;
  reg              any_rstn_rr /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=R102"  */;
  wire             clk_out_buf;
  reg              comp_led;
  reg              gen2_led;
  wire             gen2_speed;
  reg     [  3: 0] lane_active_led;
  wire             local_rstn;
  wire    [  3: 0] open_lane_width_code;
  wire    [  3: 0] open_phy_sel_code;
  wire    [  3: 0] open_ref_clk_sel_code;
  wire             phystatus_ext;
  wire    [  1: 0] powerdown_ext;
  wire             req_compliance_soft_ctrl;
  wire    [  7: 0] rxdata0_ext;
  wire    [  7: 0] rxdata1_ext;
  wire    [  7: 0] rxdata2_ext;
  wire    [  7: 0] rxdata3_ext;
  wire    [  7: 0] rxdata4_ext;
  wire    [  7: 0] rxdata5_ext;
  wire    [  7: 0] rxdata6_ext;
  wire    [  7: 0] rxdata7_ext;
  wire             rxdatak0_ext;
  wire             rxdatak1_ext;
  wire             rxdatak2_ext;
  wire             rxdatak3_ext;
  wire             rxdatak4_ext;
  wire             rxdatak5_ext;
  wire             rxdatak6_ext;
  wire             rxdatak7_ext;
  wire             rxelecidle0_ext;
  wire             rxelecidle1_ext;
  wire             rxelecidle2_ext;
  wire             rxelecidle3_ext;
  wire             rxelecidle4_ext;
  wire             rxelecidle5_ext;
  wire             rxelecidle6_ext;
  wire             rxelecidle7_ext;
  wire             rxpolarity0_ext;
  wire             rxpolarity1_ext;
  wire             rxpolarity2_ext;
  wire             rxpolarity3_ext;
  wire             rxpolarity4_ext;
  wire             rxpolarity5_ext;
  wire             rxpolarity6_ext;
  wire             rxpolarity7_ext;
  wire    [  2: 0] rxstatus0_ext;
  wire    [  2: 0] rxstatus1_ext;
  wire    [  2: 0] rxstatus2_ext;
  wire    [  2: 0] rxstatus3_ext;
  wire    [  2: 0] rxstatus4_ext;
  wire    [  2: 0] rxstatus5_ext;
  wire    [  2: 0] rxstatus6_ext;
  wire    [  2: 0] rxstatus7_ext;
  wire             rxvalid0_ext;
  wire             rxvalid1_ext;
  wire             rxvalid2_ext;
  wire             rxvalid3_ext;
  wire             rxvalid4_ext;
  wire             rxvalid5_ext;
  wire             rxvalid6_ext;
  wire             rxvalid7_ext;
  wire             safe_mode;
  wire             set_compliance_mode;
  wire    [ 39: 0] test_in;
  wire             test_in_32_hip;
  wire             test_in_5_hip;
  wire    [  8: 0] test_out_icm;
  wire             tx_out0;
  wire             tx_out1;
  wire             tx_out2;
  wire             tx_out3;
  wire             tx_out4;
  wire             tx_out5;
  wire             tx_out6;
  wire             tx_out7;
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
  assign safe_mode = 1;
  assign local_rstn = safe_mode | local_rstn_ext;
  assign any_rstn = pcie_rstn & local_rstn;
  assign test_in[39 : 33] = 0;
  assign set_compliance_mode = usr_sw[0];
  assign req_compliance_soft_ctrl = 0;
  assign test_in[32] = test_in_32_hip;
  assign test_in[31 : 9] = 0;
  assign test_in[8 : 6] = safe_mode ? 4'b010 : usr_sw[3 : 1];
  assign test_in[5] = test_in_5_hip;
  assign test_in[4 : 0] = 5'b01000;
  //reset Synchronizer
  always @(posedge clk_out_buf or negedge any_rstn)
    begin
      if (any_rstn == 0)
        begin
          any_rstn_r <= 0;
          any_rstn_rr <= 0;
        end
      else 
        begin
          any_rstn_r <= 1;
          any_rstn_rr <= any_rstn_r;
        end
    end


  //LED logic
  always @(posedge clk_out_buf or negedge any_rstn_rr)
    begin
      if (any_rstn_rr == 0)
        begin
          alive_cnt <= 0;
          alive_led <= 0;
          comp_led <= 0;
          L0_led <= 0;
          lane_active_led <= 0;
        end
      else 
        begin
          alive_cnt <= alive_cnt +1;
          alive_led <= alive_cnt[25];
          comp_led <= ~(test_out_icm[4 : 0] == 5'b00011);
          L0_led <= ~(test_out_icm[4 : 0] == 5'b01111);
          lane_active_led[3 : 0] <= ~(test_out_icm[8 : 5]);
        end
    end


  //Gen2 LED logic
  always @(posedge clk_out_buf or negedge any_rstn_rr)
    begin
      if (any_rstn_rr == 0)
          gen2_led <= 0;
      else 
        gen2_led <= ~gen2_speed;
    end


  altpcierd_compliance_test pcie_compliance_test_enable
    (
      .local_rstn (local_rstn_ext),
      .pcie_rstn (pcie_rstn),
      .refclk (refclk),
      .req_compliance_push_button_n (req_compliance_push_button_n),
      .req_compliance_soft_ctrl (req_compliance_soft_ctrl),
      .set_compliance_mode (set_compliance_mode),
      .test_in_32_hip (test_in_32_hip),
      .test_in_5_hip (test_in_5_hip)
    );


  pcie_4243_hip_s4gx_gen2_x8_128_example_chaining_pipen1b core
    (
      .core_clk_out (clk_out_buf),
      .free_100MHz (free_100MHz),
      .gen2_speed (gen2_speed),
      .lane_width_code (open_lane_width_code),
      .local_rstn (local_rstn),
      .pcie_rstn (pcie_rstn),
      .phy_sel_code (open_phy_sel_code),
      .phystatus_ext (phystatus_ext),
      .pipe_mode (1'b0),
      .pld_clk (clk_out_buf),
      .powerdown_ext (powerdown_ext),
      .ref_clk_sel_code (open_ref_clk_sel_code),
      .refclk (refclk),
      .rx_in0 (rx_in0),
      .rx_in1 (rx_in1),
      .rx_in2 (rx_in2),
      .rx_in3 (rx_in3),
      .rx_in4 (rx_in4),
      .rx_in5 (rx_in5),
      .rx_in6 (rx_in6),
      .rx_in7 (rx_in7),
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
      .test_in (test_in),
      .test_out_icm (test_out_icm),
      .tx_out0 (tx_out0),
      .tx_out1 (tx_out1),
      .tx_out2 (tx_out2),
      .tx_out3 (tx_out3),
      .tx_out4 (tx_out4),
      .tx_out5 (tx_out5),
      .tx_out6 (tx_out6),
      .tx_out7 (tx_out7),
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



endmodule

