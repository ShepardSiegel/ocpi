//*****************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2007, 2008 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 3.4
//  \   \        Application        : MIG
//  /   /        Filename           : sim_tb_top.v
// /___/   /\    Date Last Modified : $Date: 2009/11/03 04:43:17 $
// \   \  /  \   Date Created       : Mon May 14 2007
//  \___\/\___\
//
// Device      : Virtex-5
// Design Name : DDR2
// Purpose     : This is the simulation testbench which is used to verify the
//               design. The basic clocks and resets to the interface are
//               generated here. This also connects the memory interface to the
//               memory model.
// Reference:
// Revision History:
//*****************************************************************************

`timescale 1ns / 1ps

module sim_tb_top;

  // memory controller parameters
   parameter BANK_WIDTH            = 2;      // # of memory bank addr bits
   parameter CKE_WIDTH             = 1;      // # of memory clock enable outputs
   parameter CLK_WIDTH             = 2;      // # of clock outputs
   parameter CLK_TYPE              = "SINGLE_ENDED";       // # of clock type
   parameter COL_WIDTH             = 10;     // # of memory column bits
   parameter CS_NUM                = 1;      // # of separate memory chip selects
   parameter CS_WIDTH              = 2;      // # of total memory chip selects
   parameter CS_BITS               = 0;      // set to log2(CS_NUM) (rounded up)
   parameter DM_WIDTH              = 4;      // # of data mask bits
   parameter DQ_WIDTH              = 32;      // # of data width
   parameter DQ_PER_DQS            = 8;      // # of DQ data bits per strobe
   parameter DQS_WIDTH             = 4;      // # of DQS strobes
   parameter DQ_BITS               = 5;      // set to log2(DQS_WIDTH*DQ_PER_DQS)
   parameter DQS_BITS              = 2;      // set to log2(DQS_WIDTH)
   parameter HIGH_PERFORMANCE_MODE = "TRUE"; // Sets the performance mode for IODELAY elements
   parameter ODT_WIDTH             = 2;      // # of memory on-die term enables
   parameter ROW_WIDTH             = 13;     // # of memory row & # of addr bits
   parameter APPDATA_WIDTH         = 64;     // # of usr read/write data bus bits
   parameter ADDITIVE_LAT          = 0;      // additive write latency
   parameter BURST_LEN             = 8;      // burst length (in double words)
   parameter BURST_TYPE            = 0;      // burst type (=0 seq; =1 interlved)
   parameter CAS_LAT               = 5;      // CAS latency
   parameter ECC_ENABLE            = 0;      // enable ECC (=1 enable)
   parameter MULTI_BANK_EN         = 1;      // enable bank management
   parameter TWO_T_TIME_EN         = 0;      // 2t timing for unbuffered dimms
   parameter ODT_TYPE              = 3;      // ODT (=0(none),=1(75),=2(150),=3(50))
   parameter REDUCE_DRV            = 0;      // reduced strength mem I/O (=1 yes)
   parameter REG_ENABLE            = 0;      // registered addr/ctrl (=1 yes)
   parameter TREFI_NS              = 7800;   // auto refresh interval (ns)
   parameter TRAS                  = 40000;  // active->precharge delay
   parameter TRCD                  = 15000;  // active->read/write delay
   parameter TRFC                  = 105000;  // ref->ref, ref->active delay
   parameter TRP                   = 15000;  // precharge->command delay
   parameter TRTP                  = 7500;   // read->precharge delay
   parameter TWR                   = 15000;  // used to determine wr->prech
   parameter TWTR                  = 7500;   // write->read delay
   parameter SIM_ONLY              = 1;      // = 0 to allow power up delay
   parameter DEBUG_EN              = 1;      // Enable debug signals/controls
   parameter RST_ACT_LOW           = 1;      // =1 for active low reset, =0 for active high
   parameter DLL_FREQ_MODE         = "HIGH"; // DCM Frequency range
   parameter CLK_PERIOD            = 3333;   // Core/Mem clk period (in ps)

   localparam DEVICE_WIDTH    = 16;      // Memory device data width
   localparam real CLK_PERIOD_NS   = CLK_PERIOD / 1000.0;
   localparam real TCYC_200           = 5.0;
   localparam real TPROP_DQS          = 0.01;  // Delay for DQS signal during Write Operation
   localparam real TPROP_DQS_RD       = 0.01;  // Delay for DQS signal during Read Operation
   localparam real TPROP_PCB_CTRL     = 0.01;  // Delay for Address and Ctrl signals
   localparam real TPROP_PCB_DATA     = 0.01;  // Delay for data signal during Write operation
   localparam real TPROP_PCB_DATA_RD  = 0.01;  // Delay for data signal during Read operation

   
   reg                           sys_clk;
   wire                          sys_clk_n;
   wire                          sys_clk_p;
   reg                           sys_clk200;
   wire                          clk200_n;
   wire                          clk200_p;
   reg                           sys_rst_n;
   wire                          sys_rst_out;


   wire [DQ_WIDTH-1:0]          ddr2_dq_sdram;
   wire [DQS_WIDTH-1:0]         ddr2_dqs_sdram;
   wire [DQS_WIDTH-1:0]         ddr2_dqs_n_sdram;
   wire [DM_WIDTH-1:0]          ddr2_dm_sdram;
   reg [DM_WIDTH-1:0]           ddr2_dm_sdram_tmp;
   reg [CLK_WIDTH-1:0]          ddr2_clk_sdram;
   reg [CLK_WIDTH-1:0]          ddr2_clk_n_sdram;
   reg [ROW_WIDTH-1:0]          ddr2_address_sdram;
   reg [BANK_WIDTH-1:0]         ddr2_ba_sdram;
   reg                          ddr2_ras_n_sdram;
   reg                          ddr2_cas_n_sdram;
   reg                          ddr2_we_n_sdram;
   reg [CS_WIDTH-1:0]           ddr2_cs_n_sdram;
   reg [CKE_WIDTH-1:0]          ddr2_cke_sdram;
   reg [ODT_WIDTH-1:0]          ddr2_odt_sdram;


   wire [DQ_WIDTH-1:0]          ddr2_dq_fpga;
   wire [DQS_WIDTH-1:0]         ddr2_dqs_fpga;
   wire [DQS_WIDTH-1:0]         ddr2_dqs_n_fpga;
   wire [DM_WIDTH-1:0]          ddr2_dm_fpga;
   wire [CLK_WIDTH-1:0]         ddr2_clk_fpga;
   wire [CLK_WIDTH-1:0]         ddr2_clk_n_fpga;
   wire [ROW_WIDTH-1:0]         ddr2_address_fpga;
   wire [BANK_WIDTH-1:0]        ddr2_ba_fpga;
   wire                         ddr2_ras_n_fpga;
   wire                         ddr2_cas_n_fpga;
   wire                         ddr2_we_n_fpga;
   wire [CS_WIDTH-1:0]          ddr2_cs_n_fpga;
   wire [CKE_WIDTH-1:0]         ddr2_cke_fpga;
   wire [ODT_WIDTH-1:0]         ddr2_odt_fpga;

   wire                          error;
   wire                          phy_init_done;
   

   // Only RDIMM memory parts support the reset signal,
   // hence the ddr2_reset_n signal can be ignored for other memory parts
   wire                          ddr2_reset_n;
   reg [ROW_WIDTH-1:0]           ddr2_address_reg;
   reg [BANK_WIDTH-1:0]          ddr2_ba_reg;
   reg [CKE_WIDTH-1:0]           ddr2_cke_reg;
   reg                           ddr2_ras_n_reg;
   reg                           ddr2_cas_n_reg;
   reg                           ddr2_we_n_reg;
   reg [CS_WIDTH-1:0]            ddr2_cs_n_reg;
   reg [ODT_WIDTH-1:0]           ddr2_odt_reg;
   
   wire                          clk0_tb;
   wire                          rst0_tb;
   wire                          app_af_afull;
   wire                          app_wdf_afull;
   wire                          rd_data_valid;
   wire [APPDATA_WIDTH-1:0]      rd_data_fifo_out;
   wire                          app_af_wren;
   wire [2:0]                    app_af_cmd;
   wire [30:0]                   app_af_addr;
   wire                          app_wdf_wren;
   wire [APPDATA_WIDTH-1:0]      app_wdf_data;
   wire [(APPDATA_WIDTH/8)-1:0]  app_wdf_mask_data;
   wire                          error_cmp;

   //***************************************************************************
   // Clock generation and reset
   //***************************************************************************

   initial
     sys_clk = 1'b0;
   always
     sys_clk = #(CLK_PERIOD_NS/2) ~sys_clk;

   assign                sys_clk_p = sys_clk;
   assign                sys_clk_n = ~sys_clk;

   initial
     sys_clk200 = 1'b0;
   always
     sys_clk200 = #(TCYC_200/2) ~sys_clk200;

   assign                clk200_p = sys_clk200;
   assign                clk200_n = ~sys_clk200;

   initial begin
      sys_rst_n = 1'b0;
      #200;
      sys_rst_n = 1'b1;
   end
   assign sys_rst_out = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

   


// =============================================================================
//                             BOARD Parameters
// =============================================================================
// These parameter values can be changed to model varying board delays
// between the Virtex-5 device and the memory model


  always @( * ) begin
    ddr2_clk_sdram        <=  #(TPROP_PCB_CTRL) ddr2_clk_fpga;
    ddr2_clk_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_clk_n_fpga;
    ddr2_address_sdram    <=  #(TPROP_PCB_CTRL) ddr2_address_fpga;
    ddr2_ba_sdram         <=  #(TPROP_PCB_CTRL) ddr2_ba_fpga;
    ddr2_ras_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_ras_n_fpga;
    ddr2_cas_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_cas_n_fpga;
    ddr2_we_n_sdram       <=  #(TPROP_PCB_CTRL) ddr2_we_n_fpga;
    ddr2_cs_n_sdram       <=  #(TPROP_PCB_CTRL) ddr2_cs_n_fpga;
    ddr2_cke_sdram        <=  #(TPROP_PCB_CTRL) ddr2_cke_fpga;
    ddr2_odt_sdram        <=  #(TPROP_PCB_CTRL) ddr2_odt_fpga;
    ddr2_dm_sdram_tmp     <=  #(TPROP_PCB_DATA) ddr2_dm_fpga;//DM signal generation
  end

  assign ddr2_dm_sdram = ddr2_dm_sdram_tmp;


// Controlling the bi-directional BUS
  genvar dqwd;
  generate
    for (dqwd = 0;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
       (
        .Delay_g     (TPROP_PCB_DATA),
        .Delay_rd    (TPROP_PCB_DATA_RD)
       )
      u_delay_dq
       (
        .A           (ddr2_dq_fpga[dqwd]),
        .B           (ddr2_dq_sdram[dqwd]),
        .reset       (sys_rst_n)
       );
    end
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
       (
        .Delay_g     (TPROP_DQS),
        .Delay_rd    (TPROP_DQS_RD)
       )
      u_delay_dqs
       (
        .A           (ddr2_dqs_fpga[dqswd]),
        .B           (ddr2_dqs_sdram[dqswd]),
        .reset       (sys_rst_n)
       );

      WireDelay #
       (
        .Delay_g     (TPROP_DQS),
        .Delay_rd    (TPROP_DQS_RD)
       )
      u_delay_dqs_n
       (
        .A           (ddr2_dqs_n_fpga[dqswd]),
        .B           (ddr2_dqs_n_sdram[dqswd]),
        .reset       (sys_rst_n)
       );
    end
  endgenerate



   //***************************************************************************
   // FPGA memory controller
   //***************************************************************************

   mig_v3_4 #
     (
      .BANK_WIDTH            (BANK_WIDTH),
      .CKE_WIDTH             (CKE_WIDTH),
      .CLK_WIDTH             (CLK_WIDTH),
      .COL_WIDTH             (COL_WIDTH),
      .CS_NUM                (CS_NUM),
      .CS_WIDTH              (CS_WIDTH),
      .CS_BITS               (CS_BITS),
      .DM_WIDTH                     (DM_WIDTH),
      .DQ_WIDTH              (DQ_WIDTH),
      .DQ_PER_DQS            (DQ_PER_DQS),
      .DQ_BITS               (DQ_BITS),
      .DQS_WIDTH             (DQS_WIDTH),
      .DQS_BITS              (DQS_BITS),
      .HIGH_PERFORMANCE_MODE (HIGH_PERFORMANCE_MODE),
      .ODT_WIDTH             (ODT_WIDTH),
      .ROW_WIDTH             (ROW_WIDTH),
      .APPDATA_WIDTH         (APPDATA_WIDTH),
      .ADDITIVE_LAT          (ADDITIVE_LAT),
      .BURST_LEN             (BURST_LEN),
      .BURST_TYPE            (BURST_TYPE),
      .CAS_LAT               (CAS_LAT),
      .ECC_ENABLE            (ECC_ENABLE),
      .MULTI_BANK_EN         (MULTI_BANK_EN),
      .ODT_TYPE              (ODT_TYPE),
      .REDUCE_DRV            (REDUCE_DRV),
      .REG_ENABLE            (REG_ENABLE),
      .TREFI_NS              (TREFI_NS),
      .TRAS                  (TRAS),
      .TRCD                  (TRCD),
      .TRFC                  (TRFC),
      .TRP                   (TRP),
      .TRTP                  (TRTP),
      .TWR                   (TWR),
      .TWTR                  (TWTR),
      .SIM_ONLY              (SIM_ONLY),
      .RST_ACT_LOW           (RST_ACT_LOW),
      .CLK_TYPE                     (CLK_TYPE),
      .DLL_FREQ_MODE                (DLL_FREQ_MODE),
      .CLK_PERIOD            (CLK_PERIOD)
      )
   u_mem_controller
     (
      .sys_clk           (sys_clk_p),
      .idly_clk_200      (clk200_p),
      .sys_rst_n         (sys_rst_out),
      .ddr2_ras_n        (ddr2_ras_n_fpga),
      .ddr2_cas_n        (ddr2_cas_n_fpga),
      .ddr2_we_n         (ddr2_we_n_fpga),
      .ddr2_cs_n         (ddr2_cs_n_fpga),
      .ddr2_cke          (ddr2_cke_fpga),
      .ddr2_odt          (ddr2_odt_fpga),
      .ddr2_dm           (ddr2_dm_fpga),
      .ddr2_dq           (ddr2_dq_fpga),
      .ddr2_dqs          (ddr2_dqs_fpga),
      .ddr2_dqs_n        (ddr2_dqs_n_fpga),
      .ddr2_ck           (ddr2_clk_fpga),
      .ddr2_ck_n         (ddr2_clk_n_fpga),
      .ddr2_ba           (ddr2_ba_fpga),
      .ddr2_a            (ddr2_address_fpga),
      
      .clk0_tb           (clk0_tb),
      .rst0_tb           (rst0_tb),
      .app_af_afull      (app_af_afull),
      .app_wdf_afull     (app_wdf_afull),
      .rd_data_valid     (rd_data_valid),
      .rd_data_fifo_out  (rd_data_fifo_out),
      .app_af_wren       (app_af_wren),
      .app_af_cmd        (app_af_cmd),
      .app_af_addr       (app_af_addr),
      .app_wdf_wren      (app_wdf_wren),
      .app_wdf_data      (app_wdf_data),
.app_wdf_mask_data (app_wdf_mask_data),
      
      .phy_init_done     (phy_init_done)
      );

   // Extra one clock pipelining for RDIMM address and
   // control signals is implemented here (Implemented external to memory model)
   always @( posedge ddr2_clk_sdram[0] ) begin
      if ( ddr2_reset_n == 1'b0 ) begin
         ddr2_ras_n_reg    <= 1'b1;
         ddr2_cas_n_reg    <= 1'b1;
         ddr2_we_n_reg     <= 1'b1;
         ddr2_cs_n_reg     <= {CS_WIDTH{1'b1}};
         ddr2_odt_reg      <= 1'b0;
      end
      else begin
         ddr2_address_reg  <= #(CLK_PERIOD_NS/2) ddr2_address_sdram;
         ddr2_ba_reg       <= #(CLK_PERIOD_NS/2) ddr2_ba_sdram;
         ddr2_ras_n_reg    <= #(CLK_PERIOD_NS/2) ddr2_ras_n_sdram;
         ddr2_cas_n_reg    <= #(CLK_PERIOD_NS/2) ddr2_cas_n_sdram;
         ddr2_we_n_reg     <= #(CLK_PERIOD_NS/2) ddr2_we_n_sdram;
         ddr2_cs_n_reg     <= #(CLK_PERIOD_NS/2) ddr2_cs_n_sdram;
         ddr2_odt_reg      <= #(CLK_PERIOD_NS/2) ddr2_odt_sdram;
      end
   end

   // to avoid tIS violations on CKE when reset is deasserted
   always @( posedge ddr2_clk_n_sdram[0] )
      if ( ddr2_reset_n == 1'b0 )
         ddr2_cke_reg      <= 1'b0;
      else
         ddr2_cke_reg      <= #(CLK_PERIOD_NS) ddr2_cke_sdram;

   //***************************************************************************
   // Memory model instances
   //***************************************************************************
   
   genvar i, j;
   generate
      if (DEVICE_WIDTH == 16) begin
         // if memory part is x16
         if ( REG_ENABLE ) begin
           // if the memory part is Registered DIMM
           for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
             for(i = 0; i < DQS_WIDTH/2; i = i+1) begin : gen
                ddr2_model u_mem0
                  (
                   .ck        (ddr2_clk_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                   .ck_n      (ddr2_clk_n_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                   .cke       (ddr2_cke_reg[j]),
                   .cs_n      (ddr2_cs_n_reg[CS_WIDTH*i/DQS_WIDTH]),
                   .ras_n     (ddr2_ras_n_reg),
                   .cas_n     (ddr2_cas_n_reg),
                   .we_n      (ddr2_we_n_reg),
                   .dm_rdqs   (ddr2_dm_sdram[(2*(i+1))-1 : i*2]),
                   .ba        (ddr2_ba_reg),
                   .addr      (ddr2_address_reg),
                   .dq        (ddr2_dq_sdram[(16*(i+1))-1 : i*16]),
                   .dqs       (ddr2_dqs_sdram[(2*(i+1))-1 : i*2]),
                   .dqs_n     (ddr2_dqs_n_sdram[(2*(i+1))-1 : i*2]),
                   .rdqs_n    (),
                   .odt       (ddr2_odt_reg[ODT_WIDTH*i/DQS_WIDTH])
                   );
             end
           end
         end
         else begin
             // if the memory part is component or unbuffered DIMM
            if ( DQ_WIDTH%16 ) begin
              // for the memory part x16, if the data width is not multiple
              // of 16, memory models are instantiated for all data with x16
              // memory model and except for MSB data. For the MSB data
              // of 8 bits, all memory data, strobe and mask data signals are
              // replicated to make it as x16 part. For example if the design
              // is generated for data width of 72, memory model x16 parts
              // instantiated for 4 times with data ranging from 0 to 63.
              // For MSB data ranging from 64 to 71, one x16 memory model
              // by replicating the 8-bit data twice and similarly
              // the case with data mask and strobe.
              for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
                for(i = 0; i < DQ_WIDTH/16 ; i = i+1) begin : gen
                   ddr2_model u_mem0
                     (
                      .ck        (ddr2_clk_sdram[i]),
                     .ck_n      (ddr2_clk_n_sdram[i]),
                      .cke       (ddr2_cke_sdram[j]),
                      .cs_n      (ddr2_cs_n_sdram[(j*(CS_WIDTH/CS_NUM))+i]),
                      .ras_n     (ddr2_ras_n_sdram),
                      .cas_n     (ddr2_cas_n_sdram),
                      .we_n      (ddr2_we_n_sdram),
                      .dm_rdqs   (ddr2_dm_sdram[(2*(i+1))-1 : i*2]),
                      .ba        (ddr2_ba_sdram),
                      .addr      (ddr2_address_sdram),
                      .dq        (ddr2_dq_sdram[(16*(i+1))-1 : i*16]),
                      .dqs       (ddr2_dqs_sdram[(2*(i+1))-1 : i*2]),
                      .dqs_n     (ddr2_dqs_n_sdram[(2*(i+1))-1 : i*2]),
                      .rdqs_n    (),
                      .odt       (ddr2_odt_sdram[i])
                      );
                end
                   ddr2_model u_mem1
                     (
                      .ck        (ddr2_clk_sdram[CLK_WIDTH-1]),
                      .ck_n      (ddr2_clk_n_sdram[CLK_WIDTH-1]),
                      .cke       (ddr2_cke_sdram[j]),
                      .cs_n      (ddr2_cs_n_sdram[CS_WIDTH-1]),
                      .ras_n     (ddr2_ras_n_sdram),
                      .cas_n     (ddr2_cas_n_sdram),
                      .we_n      (ddr2_we_n_sdram),
                      .dm_rdqs   ({ddr2_dm_sdram[DM_WIDTH - 1],
                                   ddr2_dm_sdram[DM_WIDTH - 1]}),
                      .ba        (ddr2_ba_sdram),
                      .addr      (ddr2_address_sdram),
                      .dq        ({ddr2_dq_sdram[DQ_WIDTH - 1 : DQ_WIDTH - 8],
                                   ddr2_dq_sdram[DQ_WIDTH - 1 : DQ_WIDTH - 8]}),
                      .dqs       ({ddr2_dqs_sdram[DQS_WIDTH - 1],
                                   ddr2_dqs_sdram[DQS_WIDTH - 1]}),
                      .dqs_n     ({ddr2_dqs_n_sdram[DQS_WIDTH - 1],
                                   ddr2_dqs_n_sdram[DQS_WIDTH - 1]}),
                      .rdqs_n    (),
                      .odt       (ddr2_odt_sdram[ODT_WIDTH-1])
                      );
              end
            end
            else begin
              // if the data width is multiple of 16
              for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
                for(i = 0; i < CS_WIDTH/CS_NUM; i = i+1) begin : gen
                   ddr2_model u_mem0
                     (
                      .ck        (ddr2_clk_sdram[i]),
                     .ck_n      (ddr2_clk_n_sdram[i]),
                      .cke       (ddr2_cke_sdram[j]),
                      .cs_n      (ddr2_cs_n_sdram[(j*(CS_WIDTH/CS_NUM))+i]),
                      .ras_n     (ddr2_ras_n_sdram),
                      .cas_n     (ddr2_cas_n_sdram),
                      .we_n      (ddr2_we_n_sdram),
                      .dm_rdqs   (ddr2_dm_sdram[(2*(i+1))-1 : i*2]),
                      .ba        (ddr2_ba_sdram),
                      .addr      (ddr2_address_sdram),
                      .dq        (ddr2_dq_sdram[(16*(i+1))-1 : i*16]),
                      .dqs       (ddr2_dqs_sdram[(2*(i+1))-1 : i*2]),
                      .dqs_n     (ddr2_dqs_n_sdram[(2*(i+1))-1 : i*2]),
                      .rdqs_n    (),
                      .odt       (ddr2_odt_sdram[i])
                      );
                end
              end
            end
         end

      end else
        if (DEVICE_WIDTH == 8) begin
           // if the memory part is x8
           if ( REG_ENABLE ) begin
             // if the memory part is Registered DIMM
             for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
               for(i = 0; i < DQ_WIDTH/DQ_PER_DQS; i = i+1) begin : gen
                  ddr2_model u_mem0
                    (
                     .ck        (ddr2_clk_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                     .ck_n      (ddr2_clk_n_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                     .cke       (ddr2_cke_reg[j]),
                     .cs_n      (ddr2_cs_n_reg[CS_WIDTH*i/DQS_WIDTH]),
                     .ras_n     (ddr2_ras_n_reg),
                     .cas_n     (ddr2_cas_n_reg),
                     .we_n      (ddr2_we_n_reg),
                     .dm_rdqs   (ddr2_dm_sdram[i]),
                     .ba        (ddr2_ba_reg),
                     .addr      (ddr2_address_reg),
                     .dq        (ddr2_dq_sdram[(8*(i+1))-1 : i*8]),
                     .dqs       (ddr2_dqs_sdram[i]),
                     .dqs_n     (ddr2_dqs_n_sdram[i]),
                     .rdqs_n    (),
                     .odt       (ddr2_odt_reg[ODT_WIDTH*i/DQS_WIDTH])
                     );
               end
             end
           end
           else begin
             // if the memory part is component or unbuffered DIMM
             for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
               for(i = 0; i < CS_WIDTH/CS_NUM; i = i+1) begin : gen
                  ddr2_model u_mem0
                    (
                     .ck        (ddr2_clk_sdram[i]),
                    .ck_n      (ddr2_clk_n_sdram[i]),
                     .cke       (ddr2_cke_sdram[j]),
                     .cs_n      (ddr2_cs_n_sdram[(j*(CS_WIDTH/CS_NUM))+i]),
                     .ras_n     (ddr2_ras_n_sdram),
                     .cas_n     (ddr2_cas_n_sdram),
                     .we_n      (ddr2_we_n_sdram),
                     .dm_rdqs   (ddr2_dm_sdram[i]),
                     .ba        (ddr2_ba_sdram),
                     .addr      (ddr2_address_sdram),
                     .dq        (ddr2_dq_sdram[(8*(i+1))-1 : i*8]),
                     .dqs       (ddr2_dqs_sdram[i]),
                     .dqs_n     (ddr2_dqs_n_sdram[i]),
                     .rdqs_n    (),
                     .odt       (ddr2_odt_sdram[i])
                     );
               end
             end
           end

        end else
          if (DEVICE_WIDTH == 4) begin
             // if the memory part is x4
             if ( REG_ENABLE ) begin
               // if the memory part is Registered DIMM
               for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
                  for(i = 0; i < DQS_WIDTH; i = i+1) begin : gen
                     ddr2_model u_mem0
                       (
                        .ck        (ddr2_clk_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                        .ck_n      (ddr2_clk_n_sdram[CLK_WIDTH*i/DQS_WIDTH]),
                        .cke       (ddr2_cke_reg[j]),
                        .cs_n      (ddr2_cs_n_reg[CS_WIDTH*i/DQS_WIDTH]),
                        .ras_n     (ddr2_ras_n_reg),
                        .cas_n     (ddr2_cas_n_reg),
                        .we_n      (ddr2_we_n_reg),
                        .dm_rdqs   (ddr2_dm_sdram[i]),
                        .ba        (ddr2_ba_reg),
                        .addr      (ddr2_address_reg),
                        .dq        (ddr2_dq_sdram[(4*(i+1))-1 : i*4]),
                        .dqs       (ddr2_dqs_sdram[i]),
                        .dqs_n     (ddr2_dqs_n_sdram[i]),
                        .rdqs_n    (),
                        .odt       (ddr2_odt_reg[ODT_WIDTH*i/DQS_WIDTH])
                        );
                  end
               end
             end
             else begin
               // if the memory part is component or unbuffered DIMM
               for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
                 for(i = 0; i < CS_WIDTH/CS_NUM; i = i+1) begin : gen
                    ddr2_model u_mem0
                      (
                       .ck        (ddr2_clk_sdram[i]),
                      .ck_n      (ddr2_clk_n_sdram[i]),
                       .cke       (ddr2_cke_sdram[j]),
                       .cs_n      (ddr2_cs_n_sdram[(j*(CS_WIDTH/CS_NUM))+i]),
                       .ras_n     (ddr2_ras_n_sdram),
                       .cas_n     (ddr2_cas_n_sdram),
                       .we_n      (ddr2_we_n_sdram),
                       .dm_rdqs   (ddr2_dm_sdram[i]),
                       .ba        (ddr2_ba_sdram),
                       .addr      (ddr2_address_sdram),
                       .dq        (ddr2_dq_sdram[(4*(i+1))-1 : i*4]),
                       .dqs       (ddr2_dqs_sdram[i]),
                       .dqs_n     (ddr2_dqs_n_sdram[i]),
                       .rdqs_n    (),
                       .odt       (ddr2_odt_sdram[i])
                       );
                 end
               end
             end
          end
   endgenerate
   
   // synthesizable test bench provided for wotb designs
   ddr2_tb_top #
     (
      .BANK_WIDTH        (BANK_WIDTH),
      .COL_WIDTH         (COL_WIDTH),
      .DM_WIDTH          (DM_WIDTH),
      .DQ_WIDTH          (DQ_WIDTH),
      .ROW_WIDTH         (ROW_WIDTH),
      .ECC_ENABLE        (ECC_ENABLE),
      .APPDATA_WIDTH     (APPDATA_WIDTH),
      .BURST_LEN         (BURST_LEN)
      )
   u_tb_top
     (
      .clk0              (clk0_tb),
      .rst0              (rst0_tb),
      .app_af_afull      (app_af_afull),
      .app_wdf_afull     (app_wdf_afull),
      .rd_data_valid     (rd_data_valid),
      .rd_data_fifo_out  (rd_data_fifo_out),
      .phy_init_done     (phy_init_done),
      .app_af_wren       (app_af_wren),
      .app_af_cmd        (app_af_cmd),
      .app_af_addr       (app_af_addr),
      .app_wdf_wren      (app_wdf_wren),
      .app_wdf_data      (app_wdf_data),
      .app_wdf_mask_data (app_wdf_mask_data),
      .error             (error),
      .error_cmp         (error_cmp)
      );


endmodule
