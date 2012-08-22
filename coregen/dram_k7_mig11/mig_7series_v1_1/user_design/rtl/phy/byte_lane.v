/***********************************************************
-- (c) Copyright 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.

//
//
//  Owner:        Gary Martin
//  Revision:     $Id: byte_lane.v,v 1.8.4.1 2011/01/08 11:34:37 karthip Exp $
//                $Author: karthip $
//                $DateTime: 2010/05/11 18:05:17 $
//                $Change: 490882 $
//  Description:
//    This verilog file is a parameterizable single 10 or 12 bit byte lane.
//
//  History:
//  Date        Engineer    Description
//  04/01/2010  G. Martin   Initial Checkin.
//
////////////////////////////////////////////////////////////
***********************************************************/

`timescale 1ps/1ps

module byte_lane #(
// these are used to scale the index into phaser,calib,scan,mc vectors
// to access fields used in this instance
      parameter ABCD                            = "A", // A,B,C, or D
      parameter PO_DATA_CTL                     = "FALSE",
      parameter BITLANES                        = 12'b1111_1111_1111,
      parameter BITLANES_OUTONLY                = 12'b0000_0000_0000,
      parameter DIFFERENTIAL_DQS                = "TRUE",
      parameter GENERATE_DDR_CK                 = "B",
//OUT_FIFO
      parameter OF_ALMOST_EMPTY_VALUE           = 1,
      parameter OF_ALMOST_FULL_VALUE            = 1,
      parameter OF_ARRAY_MODE                   = "UNDECLARED",
      parameter OF_OUTPUT_DISABLE               = "TRUE",
      parameter OF_SYNCHRONOUS_MODE             = "TRUE",
//IN_FIFO
      parameter IF_ALMOST_EMPTY_VALUE           = 1,
      parameter IF_ALMOST_FULL_VALUE            = 1,
      parameter IF_ARRAY_MODE                   = "UNDECLARED",
      parameter IF_SYNCHRONOUS_MODE             = "TRUE",
//PHASER_IN
      parameter PI_BURST_MODE                   = "TRUE",
      parameter PI_CLKOUT_DIV                   = 2,
      parameter PI_FREQ_REF_DIV                 = "NONE",
      parameter PI_FINE_DELAY                   = 1,
      parameter PI_OUTPUT_CLK_SRC               = "DELAYED_REF" , //"DELAYED_REF",
      parameter PI_SYNC_IN_DIV_RST              = "FALSE",
//PHASER_OUT
      parameter PO_CLKOUT_DIV                   = (PO_DATA_CTL == "FALSE") ? 4 :  2,
      parameter PO_FINE_DELAY                   = 0,
      parameter PO_COARSE_DELAY                 = 0,
      parameter PO_OCLK_DELAY                   = 0,
      parameter PO_OCLKDELAY_INV                = "TRUE",
//      parameter PO_OCLKDELAY_INV                = "FALSE",
      parameter PO_OUTPUT_CLK_SRC               = "DELAYED_REF",
      parameter PO_SYNC_IN_DIV_RST              = "FALSE",

      parameter IDELAYE2_IDELAY_TYPE            = "VARIABLE",
      parameter IDELAYE2_IDELAY_VALUE           = 00,
      parameter  IODELAY_GRP                    = "IODELAY_MIG",

// local constants, do not pass in
      parameter BUS_WIDTH                       =  12,
      parameter MSB_BURST_PEND_PO               =  3,
      parameter MSB_BURST_PEND_PI               =  7,
      parameter MSB_RANK_SEL_I                  =  MSB_BURST_PEND_PI+ 8,
      parameter MSB_RANK_SEL_O                  =  MSB_RANK_SEL_I   + 8,
      parameter MSB_DIV_RST                     =  MSB_RANK_SEL_O   + 1,
      parameter MSB_PHASE_SELECT                =  MSB_DIV_RST      + 1,
      parameter MSB_BURST_PI                    =  MSB_PHASE_SELECT + 4,
      parameter PHASER_CTL_BUS_WIDTH            =  MSB_BURST_PI     + 1
    )(
      input                        rst,
      input                        phy_clk,
      input                        freq_refclk,
      input                        mem_refclk,
      input                        sync_pulse,
      inout  [BUS_WIDTH-1:0]       IO,
      output [BUS_WIDTH-1:0]       mem_dq_out, 
      output [BUS_WIDTH-1:0]       mem_dq_ts,
      input  [9:0]                 mem_dq_in,
      output                       mem_dqs_out,
      output                       mem_dqs_ts,
      input                        mem_dqs_in,
      inout                        DQS_P,
      inout                        DQS_N,
      output [1:0]                 ddr_ck_out,
      output                       rclk,
      output                       if_a_empty,
      output                       if_empty,
      output                       if_a_full,
      output                       if_full,
      output                       of_a_empty,
      output                       of_empty,
      output                       of_a_full,
      output                       of_full,
      output [79:0]                phy_din,
      input  [79:0]                phy_dout,
      input                        phy_cmd_wr_en,
      input                        phy_data_wr_en,
      input                        if_empty_or,
      input [PHASER_CTL_BUS_WIDTH-1:0] phaser_ctl_bus,
//    inout [`SCAN_TEST_BUS_WIDTH-1:0]  scan_test_bus,  // currently unused
      input                        idelay_inc,
      input                        idelay_ce,
      input                        idelay_ld,

      output                       po_coarse_overflow,
      output                       po_fine_overflow,
      output [8:0]                 po_counter_read_val,
      input                        po_fine_enable,
      input                        po_coarse_enable,
      input  [1:0]                 po_en_calib,
      input                        po_fine_inc,
      input                        po_coarse_inc,
      input                        po_counter_load_en,
      input                        po_counter_read_en,
      input                        po_sel_fine_oclk_delay,
      input  [8:0]                 po_counter_load_val,

      input  [1:0]                 pi_en_calib,
      input                        pi_rst_dqs_find,
      input                        pi_fine_enable,
      input                        pi_fine_inc,
      input                        pi_counter_load_en,
      input                        pi_counter_read_en,
      input  [5:0]                 pi_counter_load_val,

      output wire                  pi_iserdes_rst,
      output                       pi_phase_locked,
      output                       pi_fine_overflow,
      output [5:0]                 pi_counter_read_val,
      output wire                  pi_dqs_found,
      output                       dqs_out_of_range
);

localparam  PHASER_INDEX =
                      (ABCD=="B" ? 1 : (ABCD == "C") ? 2 : (ABCD == "D" ? 3 : 0));
localparam   L_OF_ARRAY_MODE =
              (OF_ARRAY_MODE != "UNDECLARED") ? OF_ARRAY_MODE : 
                      (PO_DATA_CTL == "FALSE" ) ?  "ARRAY_MODE_4_X_4" : "ARRAY_MODE_8_X_4";
localparam   L_IF_ARRAY_MODE = (IF_ARRAY_MODE != "UNDECLARED") ? IF_ARRAY_MODE :  "ARRAY_MODE_4_X_8" ;

wire [1:0]                         oserdes_dqs;
wire [1:0]                         oserdes_dqs_ts;
wire [1:0]                         oserdes_dq_ts;

wire [3:0]                         of_q9;
wire [3:0]                         of_q8;
wire [3:0]                         of_q7;
wire [7:0]                         of_q6;
wire [7:0]                         of_q5;
wire [3:0]                         of_q4;
wire [3:0]                         of_q3;
wire [3:0]                         of_q2;
wire [3:0]                         of_q1;
wire [3:0]                         of_q0;
wire [7:0]                         of_d9;
wire [7:0]                         of_d8;
wire [7:0]                         of_d7;
wire [7:0]                         of_d6;
wire [7:0]                         of_d5;
wire [7:0]                         of_d4;
wire [7:0]                         of_d3;
wire [7:0]                         of_d2;
wire [7:0]                         of_d1;
wire [7:0]                         of_d0;

wire [7:0]                         if_q9;
wire [7:0]                         if_q8;
wire [7:0]                         if_q7;
wire [7:0]                         if_q6;
wire [7:0]                         if_q5;
wire [7:0]                         if_q4;
wire [7:0]                         if_q3;
wire [7:0]                         if_q2;
wire [7:0]                         if_q1;
wire [7:0]                         if_q0;
wire [3:0]                         if_d9;
wire [3:0]                         if_d8;
wire [3:0]                         if_d7;
wire [3:0]                         if_d6;
wire [3:0]                         if_d5;
wire [3:0]                         if_d4;
wire [3:0]                         if_d3;
wire [3:0]                         if_d2;
wire [3:0]                         if_d1;
wire [3:0]                         if_d0;

wire [3:0]                         dummy_i5;
wire [3:0]                         dummy_i6;

wire [48-1:0]                      of_dqbus;
wire [10*4-1:0]                    iserdes_dout;

wire ififo_wr_enable;
wire phy_rd_en_;


wire                               dqs_to_phaser;
wire                               phy_wr_en = ( PO_DATA_CTL == "FALSE" ) ? phy_cmd_wr_en  : phy_data_wr_en;
wire                               if_empty_;
wire                               if_a_empty_;
wire                               if_full_;
wire                               if_a_full_;
wire                               of_full_;
wire                               of_a_full_;

wire                               if_empty_mux;
reg                                if_empty_r;
reg                                if_empty_r1;
wire [79:0]                        rd_data;
reg [79:0]                         rd_data_r;
reg  [79:0]                        rd_data_r1;
reg                                use_pipe;

wire  reset_dqs_find = rst | pi_rst_dqs_find;

// IN_FIFO EMPTY->RDEN TIMING FIX:
// Always read from IN_FIFO - it doesn't hurt to read from an empty FIFO
// since the IN_FIFO read pointers are not incr'ed when the FIFO is empty
assign #(25) phy_rd_en_ = 1'b1;

generate
if ( PO_DATA_CTL == "FALSE" ) begin : if_empty_null
    assign if_empty = 0;
    assign if_a_empty = 0;
    assign if_full = 0;
    assign if_a_full = 0;
end
else begin : if_empty_gen
    assign if_empty   = if_empty_mux;  // Use output of timing fix logic
    assign if_a_empty = if_a_empty_;
    assign if_full    = if_full_;
    assign if_a_full  = if_a_full_;
end
endgenerate

generate
if ( PO_DATA_CTL == "FALSE" ) begin : dq_gen_48
   assign of_dqbus[48-1:0] = {of_q6[7:4], of_q5[7:4], of_q9, of_q8, of_q7, of_q6[3:0], of_q5[3:0], of_q4, of_q3, of_q2, of_q1, of_q0};
   assign phy_din =  80'h0;
end
else begin : dq_gen_40
   assign of_dqbus[40-1:0] = {of_q9, of_q8, of_q7, of_q6[3:0], of_q5[3:0], of_q4, of_q3, of_q2, of_q1, of_q0};

   // IN_FIFO EMPTY->RDEN TIMING FIX:
   assign rd_data =  {if_q9, if_q8, if_q7, if_q6, if_q5, if_q4, if_q3, if_q2, if_q1, if_q0};

   // Keep track of whether this particular IN_FIFO is either ahead, behind,
   // or in sync with the other IN_FIFOs in terms of empty status. If it's
   // "ahead" (i.e. !empty occurs one clock cycle sooner), then the use_delay
   // signal will be set, and a delayed version of the IN_FIFO output data
   // will be used. 
   always @(posedge phy_clk) begin
      rd_data_r   <= #(025) rd_data;
      rd_data_r1  <= #(025) rd_data_r;     
      if_empty_r  <= #(025) if_empty_;
      if_empty_r1 <= #(025) if_empty_r;     
      if (if_empty_r) 
         // Reset use_pipe as soon as this FIFO goes empty - assumes that
         // the following case will not happen:
         //  - FIFO[0] is "ahead" and has its use_pipe = 1
         //  - FIFO[1] is "behind" and has its use_pipe = 0
         //  - Both FIFOs go empty at the same time for one cycle, then 
         //    go not empty afterwards 
         // In this case, in order for FIFO[0] to know that it is still 
         // "ahead" even after it has gone empty, it will need to know
         // that FIFO[1] went empty the same time FIFO[0] did - which
         // requires that the logic below use FIFO[1]'s empty flag - 
         // extending this to X IN_FIFOs, each FIFO's logic must check the
         // empty flag for the other X-1 IN_FIFOs. This can be an issue with 
         // meeting place/route timing for a wide I/F
         use_pipe <= #(025) 1'b0;
      else if (!if_empty_r && if_empty_or)
         // If this FIFO isn't empty, but others are, then this FIFO must
         // be "ahead" of others
         use_pipe <= #(025) 1'b1;
   end

  assign if_empty_mux = (use_pipe) ? if_empty_r1 : if_empty_r;
  assign phy_din      = (use_pipe) ? rd_data_r1  : rd_data_r;
  
end
endgenerate

wire  iserdes_rst;
assign pi_iserdes_rst = iserdes_rst;
  
assign { if_d9, if_d8, if_d7, if_d6, if_d5, if_d4, if_d3, if_d2, if_d1, if_d0} = iserdes_dout;

assign {of_d9, of_d8, of_d7, of_d6, of_d5, of_d4, of_d3, of_d2, of_d1, of_d0} = phy_dout;

wire [1:0] rank_sel_i  = ((phaser_ctl_bus[MSB_RANK_SEL_I :MSB_RANK_SEL_I -7] >> (PHASER_INDEX << 1)) & 2'b11);

wire [1:0]  rank_sel_o = ((phaser_ctl_bus[MSB_RANK_SEL_O :MSB_RANK_SEL_O -7] >> (PHASER_INDEX << 1)) & 2'b11);

PHASER_IN_PHY #(
  .BURST_MODE                       ( PI_BURST_MODE),
  .CLKOUT_DIV                       ( PI_CLKOUT_DIV),
  .FINE_DELAY                       ( PI_FINE_DELAY),
  .FREQ_REF_DIV                     ( PI_FREQ_REF_DIV),
  .OUTPUT_CLK_SRC                   ( PI_OUTPUT_CLK_SRC),
  .SYNC_IN_DIV_RST                  ( PI_SYNC_IN_DIV_RST)
) phaser_in (
  .DQSFOUND                         (pi_dqs_found),
  .DQSOUTOFRANGE                    (dqs_out_of_range),
  .FINEOVERFLOW                     (pi_fine_overflow),
  .PHASELOCKED                      (pi_phase_locked),
  .ISERDESRST                       (iserdes_rst),
  .ICLKDIV                          (iserdes_clkdiv),
  .ICLK                             (iserdes_clk),
  .COUNTERREADVAL                   (pi_counter_read_val),
  .RCLK                             (rclk),
  .WRENABLE                         (ififo_wr_enable),
  .BURSTPENDINGPHY                  (phaser_ctl_bus[MSB_BURST_PEND_PI - 3 + PHASER_INDEX]),
  .ENCALIBPHY                       (pi_en_calib),
  .FINEENABLE                       (pi_fine_enable),
  .FREQREFCLK                       (freq_refclk),
  .MEMREFCLK                        (mem_refclk),
  .RANKSELPHY                       (rank_sel_i),
  .PHASEREFCLK                      (dqs_to_phaser),
  .RSTDQSFIND                       (pi_rst_dqs_find),
  .RST                              (rst),
  .FINEINC                          (pi_fine_inc),
  .COUNTERLOADEN                    (pi_counter_load_en),
  .COUNTERREADEN                    (pi_counter_read_en),
  .COUNTERLOADVAL                   (pi_counter_load_val),
  .SYNCIN                           (sync_pulse),
  .SYSCLK                           (phy_clk)
);

wire  #0 phase_ref = freq_refclk;

wire oserdes_clk;


PHASER_OUT_PHY #(
  .CLKOUT_DIV                        ( PO_CLKOUT_DIV),
  .DATA_CTL_N                        ( PO_DATA_CTL ),
  .FINE_DELAY                        ( PO_FINE_DELAY),
  .COARSE_DELAY                      ( PO_COARSE_DELAY),
  .OCLK_DELAY                        ( PO_OCLK_DELAY),
  .OCLKDELAY_INV                     ( PO_OCLKDELAY_INV),
  .OUTPUT_CLK_SRC                    ( PO_OUTPUT_CLK_SRC),
  .SYNC_IN_DIV_RST                   ( PO_SYNC_IN_DIV_RST)
) phaser_out (
  .COARSEOVERFLOW                    (po_coarse_overflow),
  .CTSBUS                            (oserdes_dqs_ts),
  .DQSBUS                            (oserdes_dqs),
  .DTSBUS                            (oserdes_dq_ts),
  .FINEOVERFLOW                      (po_fine_overflow),
  .OCLKDIV                           (oserdes_clkdiv),
  .OCLK                              (oserdes_clk),
  .OCLKDELAYED                       (oserdes_clk_delayed),
  .COUNTERREADVAL                    (po_counter_read_val),
  .BURSTPENDINGPHY                   (phaser_ctl_bus[MSB_BURST_PEND_PO -3 + PHASER_INDEX]),
  .ENCALIBPHY                        (po_en_calib),
  .RDENABLE                          (po_rd_enable),
  .FREQREFCLK                        (freq_refclk),
  .MEMREFCLK                         (mem_refclk),
  .PHASEREFCLK                       (/*phase_ref*/),
  .RST                               (rst),
  .OSERDESRST                        (oserdes_rst),
  .COARSEENABLE                      (po_coarse_enable),
  .FINEENABLE                        (po_fine_enable),
  .COARSEINC                         (po_coarse_inc),
  .FINEINC                           (po_fine_inc),
  .SELFINEOCLKDELAY                  (po_sel_fine_oclk_delay),
  .COUNTERLOADEN                     (po_counter_load_en),
  .COUNTERREADEN                     (po_counter_read_en),
  .COUNTERLOADVAL                    (po_counter_load_val),
  .SYNCIN                            (sync_pulse),
  .SYSCLK                            (phy_clk)
);


IN_FIFO #(
  .ALMOST_EMPTY_VALUE                ( IF_ALMOST_EMPTY_VALUE ),
  .ALMOST_FULL_VALUE                 ( IF_ALMOST_FULL_VALUE ),
  .ARRAY_MODE                        ( L_IF_ARRAY_MODE),
  .SYNCHRONOUS_MODE                  ( IF_SYNCHRONOUS_MODE)
) in_fifo  (
  .ALMOSTEMPTY                       (if_a_empty_),
  .ALMOSTFULL                        (if_a_full_),
  .EMPTY                             (if_empty_),
  .FULL                              (if_full_),
  .Q0                                (if_q0),
  .Q1                                (if_q1),
  .Q2                                (if_q2),
  .Q3                                (if_q3),
  .Q4                                (if_q4),
  .Q5                                (if_q5),
  .Q6                                (if_q6),
  .Q7                                (if_q7),
  .Q8                                (if_q8),
  .Q9                                (if_q9),
//===
  .D0                                (if_d0),
  .D1                                (if_d1),
  .D2                                (if_d2),
  .D3                                (if_d3),
  .D4                                (if_d4),
  .D5                                ({dummy_i5,if_d5}),
  .D6                                ({dummy_i6,if_d6}),
  .D7                                (if_d7),
  .D8                                (if_d8),
  .D9                                (if_d9),
  .RDCLK                             (phy_clk),
  .RDEN                              (phy_rd_en_),
  .RESET                             (rst),
  .WRCLK                             (iserdes_clkdiv),
  .WREN                              (ififo_wr_enable)
);



OUT_FIFO #(
  .ALMOST_EMPTY_VALUE             (OF_ALMOST_EMPTY_VALUE),
  .ALMOST_FULL_VALUE              (OF_ALMOST_FULL_VALUE),
  .ARRAY_MODE                     (L_OF_ARRAY_MODE),
  .OUTPUT_DISABLE                 (OF_OUTPUT_DISABLE),
  .SYNCHRONOUS_MODE               (OF_SYNCHRONOUS_MODE)
) out_fifo (
  .ALMOSTEMPTY                    (of_a_empty),
  .ALMOSTFULL                     (of_a_full),
  .EMPTY                          (of_empty),
  .FULL                           (of_full),
  .Q0                             (of_q0),
  .Q1                             (of_q1),
  .Q2                             (of_q2),
  .Q3                             (of_q3),
  .Q4                             (of_q4),
  .Q5                             (of_q5),
  .Q6                             (of_q6),
  .Q7                             (of_q7),
  .Q8                             (of_q8),
  .Q9                             (of_q9),
  .D0                             (of_d0),
  .D1                             (of_d1),
  .D2                             (of_d2),
  .D3                             (of_d3),
  .D4                             (of_d4),
  .D5                             (of_d5),
  .D6                             (of_d6),
  .D7                             (of_d7),
  .D8                             (of_d8),
  .D9                             (of_d9),
  .RDCLK                          (oserdes_clkdiv),
  .RDEN                           (po_rd_enable),
  .RESET                          (rst),
  .WRCLK                          (phy_clk),
  .WREN                           (phy_wr_en)
);



byte_group_io   #
   (
   .BITLANES                (BITLANES),
   .BITLANES_OUTONLY        (BITLANES_OUTONLY),
   .OSERDES_DATA_RATE       (PO_DATA_CTL == "FALSE" ? "SDR" : "DDR"),
   .DIFFERENTIAL_DQS        (DIFFERENTIAL_DQS),
   .IDELAYE2_IDELAY_TYPE    (IDELAYE2_IDELAY_TYPE),
   .IDELAYE2_IDELAY_VALUE   (IDELAYE2_IDELAY_VALUE),
   .IODELAY_GRP             (IODELAY_GRP)
   )
   byte_group_io
   (
   .IO                       ( IO[BUS_WIDTH-1:0] /* iobuf terminated signals to memory */),
   .DQS_P                    ( DQS_P ),
   .DQS_N                    ( DQS_N ),
   .mem_dq_out               (mem_dq_out),
   .mem_dq_ts                (mem_dq_ts),
   .mem_dq_in                (mem_dq_in),
   .mem_dqs_in               (mem_dqs_in),
   .mem_dqs_out              (mem_dqs_out),
   .mem_dqs_ts               (mem_dqs_ts),
   .rst                      (rst),
   .oserdes_rst              (oserdes_rst),
   .iserdes_rst              (iserdes_rst ),
   .iserdes_dout             (iserdes_dout),
   .dqs_to_phaser            (dqs_to_phaser),
   .phy_clk                  (phy_clk),
   .iserdes_clk              (iserdes_clk),
   .iserdes_clkb             (!iserdes_clk),
   .iserdes_clkdiv           (iserdes_clkdiv),
   .idelay_inc               (idelay_inc),
   .idelay_ce                (idelay_ce),
   .idelay_ld                (idelay_ld),
   .oserdes_clk              (oserdes_clk),
   .oserdes_clk_delayed      (oserdes_clk_delayed),
   .oserdes_clkdiv           (oserdes_clkdiv),
   .oserdes_dqs              ({oserdes_dqs[1], oserdes_dqs[0]}),
   .oserdes_dqsts            ({oserdes_dqs_ts[1], oserdes_dqs_ts[0]}),
   .oserdes_dq               (of_dqbus),
   .oserdes_dqts             ({oserdes_dq_ts[1], oserdes_dq_ts[0]})
    );

generate
if  ( PO_DATA_CTL== "FALSE" && GENERATE_DDR_CK == ABCD) begin : ddr_ck_gen
ODDR ddr_ck (
   .C    (oserdes_clk),
   .R    (oserdes_rst),
   .S    (),
   .D1   (1'b0),
   .D2   (1'b1),
   .CE   (1'b1),
   .Q    (ddr_ck_out_q)
);
    OBUFDS ddr_ck_obuf  (.I(ddr_ck_out_q), .O(ddr_ck_out[0]), .OB(ddr_ck_out[1]));
end
else  begin : ddr_ck_null
    assign ddr_ck_out = 2'b0;
end
endgenerate

endmodule // byte_lane

