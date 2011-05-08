// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It manage the interface between the
//  * chaining DMA and the Avalon Streaming ports
//  */
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030

//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_example_app_chaining.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Copyright (c) 2008 Altera Corporation. All rights reserved.  Altera products are
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
// Parameters
//
// AVALON_WDATA    : Width of the data port of the on chip Avalon memory
// AVALON_WADDR    : Width of the address port of the on chip Avalon memory
// MAX_NUMTAG      : Indicates the maximum number of PCIe tags
// BOARD_DEMO      : Indicates to the software application which board is being
//                   used
//                    0 - Altera Stratix II GX  x1
//                    1 - Altera Stratix II GX  x4
//                    2 - Altera Stratix II GX  x8
//                    3 - Cyclone II            x1
//                    4 - Arria GX              x1
//                    5 - Arria GX              x4
//                    6 - Custom PHY            x1
//                    7 - Custom PHY            x4
// USE_RCSLAVE     : When USE_RCSLAVE is set an additional module (~1000 LE)
//                   is added to the design to provide instrumentation to the
//                   PCI Express Chained DMA design such as Performance
//                   counter, debug register and EP memory Write a Read by
//                   bypassing the DMA engine.
// TXCRED_WIDTH    : Width of the PCIe tx_cred back bus
// TL_SELECTION    : Interface type
//                    0 : Descriptor data interface (in use with ICM)
//                    6 : Avalon-ST interface
// MAX_PAYLOAD_SIZE_BYTE : Indicates the Maxpayload parameter specified in the
//                         PCIe MegaWizzard
//
module altpcierd_example_app_chaining #(
   parameter AVALON_WADDR          = 12,
   parameter AVALON_WDATA          = 128,
   parameter MAX_NUMTAG            = 64,
   parameter MAX_PAYLOAD_SIZE_BYTE = 512,
   parameter BOARD_DEMO            = 1,
   parameter TL_SELECTION          = 0,
   parameter CLK_250_APP           = 0,// When 1 indicate application clock rate is 250MHz instead of 125 MHz
   parameter ECRC_FORWARD_CHECK    = 0,
   parameter ECRC_FORWARD_GENER    = 0,
   parameter CHECK_RX_BUFFER_CPL   = 0,
   parameter CHECK_BUS_MASTER_ENA  = 0,
   parameter AVALON_ST_128         = (TL_SELECTION == 7) ? 1 : 0 ,
   parameter INTENDED_DEVICE_FAMILY = "Cyclone IV GX",
   parameter RC_64BITS_ADDR        = 0,  // When 1 RC Capable of 64 bit address --> 4DW header rx_desc/tx_desc address instead of 3DW
   parameter USE_CREDIT_CTRL       = 0,
   parameter USE_MSI               = 1,  // When 1, tx_arbitration uses tx_cred
   parameter USE_DMAWRITE          = 1,
   parameter USE_DMAREAD           = 1,
   parameter USE_RCSLAVE           = 0, // Deprecated
   parameter TXCRED_WIDTH          = 22
   )(

   // Avalon streaming interface Transmit Data
   // Desc/Data Interface + Avalon ST Interface
   input        tx_stream_ready0,  //reg
   output[74:0] tx_stream_data0_0,
   output[74:0] tx_stream_data0_1,
   output       tx_stream_valid0,
   input        tx_stream_fifo_empty0,

   // Avalon streaming interface Receive Data
   // Desc/Data Interface + Avalon ST Interface
   input[81:0]  rx_stream_data0_0, //reg
   input[81:0]  rx_stream_data0_1, //reg
   input        rx_stream_valid0,  //reg
   output       rx_stream_ready0,
   output       rx_stream_mask0,

   // MSI Interrupt
   // Desc/Data Interface only
   input        msi_stream_ready0,
   output[7:0]  msi_stream_data0,
   output       msi_stream_valid0,

   // MSI Interrupt
   // Avalon ST Interface only
   output[4:0]   aer_msi_num,
   output[4:0]   pex_msi_num,
   output        app_msi_req,
   input         app_msi_ack, //reg
   output[2:0]   app_msi_tc,
   output[4:0]   app_msi_num,

   // Legacy Interrupt
   output        app_int_sts,
   input         app_int_ack,

   // Side band static signals
   // Desc/Data Interface only
   input         tx_stream_mask0,

   // Side band static signals
   // Desc/Data Interface + Avalon ST Interface
   input [TXCRED_WIDTH-1:0] tx_stream_cred0,

   // Configuration info signals
   // Desc/Data Interface + Avalon ST Interface
   input[12:0] cfg_busdev,  // Bus device number captured by the core
   input[31:0] cfg_devcsr,  // Configuration dev control status register of
                            // PCIe capability structure (address 0x88)
   input[31:0] cfg_prmcsr,  // Control and status of the PCI configuration space (address 0x4)
   input[23:0] cfg_tcvcmap,
   input[31:0] cfg_linkcsr,
   input[15:0] cfg_msicsr,
   output      cpl_pending,
   output[6:0] cpl_err,
   output[127:0] err_desc,

   input[19:0] ko_cpl_spc_vc0,

   // Unused signals
   output[9:0] pm_data,
   input test_sim,

   input clk_in  ,
   input rstn

   );


   // Receive section channel 0
   wire        open_rx_retry0;
   wire        open_rx_mask0 ;
   wire[7:0]   open_rx_be0   ;

   wire        rx_ack0  ;
   wire        rx_ws0   ;
   wire        rx_req0  ;
   wire[135:0] rx_desc0 ;
   wire[127:0] rx_data0 ;
   wire[15:0]  rx_be0   ;
   wire        rx_dv0   ;
   wire        rx_dfr0  ;
   wire [15:0] rx_ecrc_bad_cnt;

   //transmit section channel 0
   wire        tx_req0 ;
   wire        tx_mask0;
   wire        tx_ack0 ;
   wire[127:0] tx_desc0;
   wire        tx_ws0  ;
   wire        tx_err0 ;
   wire        tx_dv0  ;
   wire        tx_dfr0 ;
   wire[127:0] tx_data0;

   wire        app_msi_req_int;
   wire[2:0]   app_msi_tc_int ;
   wire[4:0]   app_msi_num_int;
   wire        app_msi_ack_int;
   reg         app_msi_ack_reg;

   reg tx_stream_ready0_reg;

   reg[81:0]  rx_stream_data0_0_reg;
   reg[81:0]  rx_stream_data0_1_reg;
   reg        rx_stream_valid0_reg ;

   reg[81:0]  rx_stream_data0_0_reg2;
   reg[81:0]  rx_stream_data0_1_reg2;
   reg        rx_stream_valid0_reg2 ;


   reg        app_msi_req_synced;
   reg[3:0]   tx_fifo_empty_timer;
   wire       tx_local_fifo_empty;
   reg        app_msi_req_synced_n;
   reg[3:0]   tx_fifo_empty_timer_n;
   reg[3:0]   msi_req_state;
   reg[3:0]   msi_req_state_n;


   always @(posedge clk_in) begin
      tx_stream_ready0_reg  <= tx_stream_ready0 ;
      rx_stream_data0_0_reg2 <= rx_stream_data0_0;
      rx_stream_data0_1_reg2 <= rx_stream_data0_1;
      rx_stream_valid0_reg2  <= rx_stream_valid0 ;
   end

   always @(posedge clk_in) begin
      rx_stream_data0_0_reg <= rx_stream_data0_0_reg2;
      rx_stream_data0_1_reg <= rx_stream_data0_1_reg2;
      rx_stream_valid0_reg  <= rx_stream_valid0_reg2 ;
   end

   //------------------------------------------------------------
   //    MSI Streaming Interface
   //       - generates streaming interface signals
   //------------------------------------------------------------
   wire        app_msi_ack_dd;

   reg srst;

   always @(posedge clk_in or negedge rstn) begin
      if (rstn==0)
         srst <= 1'b1;
      else
         srst <=1'b0;
   end

   //------------------------------------------------------------
   //    RX buffer cpld credit tracking
   //------------------------------------------------------------
   wire cpld_rx_buffer_ready;
   wire [15:0] rx_buffer_cpl_max_dw;

   altpcierd_cpld_rx_buffer #(
               .CHECK_RX_BUFFER_CPL(CHECK_RX_BUFFER_CPL),
               .MAX_NUMTAG(MAX_NUMTAG)
               )
            altpcierd_cpld_rx_buffer_i (
            .clk_in     (clk_in),
            .srst       (srst),

            .rx_req0    (rx_req0),
            .rx_ack0    (rx_ack0),
            .rx_desc0   (rx_desc0),

            .tx_req0    (tx_req0),
            .tx_ack0    (tx_ack0),
            .tx_desc0   (tx_desc0),

            .ko_cpl_spc_vc0      (ko_cpl_spc_vc0),
            .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),
            .cpld_rx_buffer_ready(cpld_rx_buffer_ready)
   );

   altpcierd_cdma_ast_msi altpcierd_cdma_ast_msi_i (
            .clk_in(clk_in),
            .rstn(rstn),  //TODO Use srst
            .app_msi_req(app_msi_req_int),
            .app_msi_ack(app_msi_ack_dd),
            .app_msi_tc(app_msi_tc_int),
            .app_msi_num(app_msi_num_int),
            .stream_ready(msi_stream_ready0),
            .stream_data(msi_stream_data0),
            .stream_valid(msi_stream_valid0));

   generate begin : HIPCAP_64
      if ((AVALON_ST_128==0) & (TL_SELECTION == 6)) begin

   //------------------------------------------------------------
   //    TX Streaming Interface
   //       - generates streaming interface signals
   //       - arbitrates between master and slave requests
   //------------------------------------------------------------

      wire [132:0] txdata;
      assign tx_stream_data0_0[74]   = txdata[132];//err
      assign tx_stream_data0_0[73]   = txdata[131];//sop
      assign tx_stream_data0_0[72]   = txdata[128];//eop
      assign tx_stream_data0_0[71:64] = 0;

      assign tx_stream_data0_1[74]    = txdata[132];
      assign tx_stream_data0_1[73]    = txdata[131];
      assign tx_stream_data0_1[72]    = txdata[128];
      assign tx_stream_data0_1[71:64] = 0;

      assign tx_stream_data0_0[63:0] = {txdata[95:64], txdata[127:96]};
      assign tx_stream_data0_1[63:0] = {txdata[95:64], txdata[127:96]};


      wire         otx_req0 ;
      wire [127:0] otx_desc0;
      wire         otx_err0 ;
      wire         otx_dv0  ;
      wire         otx_dfr0 ;
      wire [127:0] otx_data0;

      altpcierd_tx_req_reg  #(
         .TX_PIPE_REQ(0)
            ) altpcierd_tx_req128_reg  (
               .clk_in   (clk_in   ),
               .rstn     (rstn     ),
               .itx_req0 (tx_req0  ),
               .itx_desc0(tx_desc0 ),
               .itx_err0 (tx_err0  ),
               .itx_dv0  (tx_dv0   ),
               .itx_dfr0 (tx_dfr0  ),
               .itx_data0(tx_data0 ),
               .otx_req0 (otx_req0 ),
               .otx_desc0(otx_desc0),
               .otx_err0 (otx_err0 ),
               .otx_dv0  (otx_dv0  ),
               .otx_dfr0 (otx_dfr0 ),
               .otx_data0(otx_data0)
         );

      altpcierd_cdma_ast_tx_64
       #(    .TX_PIPE_REQ(0),
             .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
             .ECRC_FORWARD_GENER(ECRC_FORWARD_GENER)
             )
            altpcierd_cdma_ast_tx_i_64 (
               .clk_in(clk_in),
               .srst(srst),
               // Avalon-ST
               .txdata(txdata),
               .tx_stream_ready0(tx_stream_ready0_reg),
               .tx_stream_valid0(tx_stream_valid0),
               // Application iterface
               .tx_req0    (otx_req0),
               .tx_ack0    (tx_ack0),
               .tx_desc0   (otx_desc0),
               .tx_data0   (otx_data0),
               .tx_dfr0    (otx_dfr0),
               .tx_dv0     (otx_dv0),
               .tx_err0    (otx_err0),
               .tx_ws0     (tx_ws0),
               .tx_fifo_empty (tx_local_fifo_empty));

   //------------------------------------------------------------
   //    RX Streaming Interface
   //       - generates streaming interface signals
   //       - routes data to master/slave
   //------------------------------------------------------------
      wire [139:0] rxdata;
      wire [15:0]  rxdata_be;   // rx byte enables
      assign rxdata_be = {rx_stream_data0_0_reg[77:74], rx_stream_data0_0_reg[81:78],
                          rx_stream_data0_1_reg[77:74], rx_stream_data0_1_reg[81:78]};

      assign rxdata = {
         rx_stream_data0_0_reg[73],    //rx_sop0 [139]
         rx_stream_data0_0_reg[72],    //rx_eop0 [138]
         rx_stream_data0_1_reg[73],    //rx_eop1 [137]
         rx_stream_data0_1_reg[72],    //rx_eop1 [136]
         rx_stream_data0_0_reg[71:64], //bar     [135:128]          |  Aligned | Un-aligned 3 DW | UN-aligned 4 DW
         rx_stream_data0_0_reg[31:0],   // rx_desc[127:96]  aka H0  |   D0     |  -  -> D1       |     -> D3
         rx_stream_data0_0_reg[63:32],  // rx_desc[95:64 ]  aka H1  |   D1     |  -  -> D2       |  D0 -> D4
         rx_stream_data0_1_reg[31:0],   // rx_desc[63:32 ]  aka H2  |   D2     |  -  -> D3       |  D1 -> D5
         rx_stream_data0_1_reg[63:32]}; // rx_desc[31:0  ]  aka H4  |   D3     |  D0 -> D4       |  D2 -> D6
      altpcierd_cdma_ast_rx_64
       #( .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
          .ECRC_FORWARD_CHECK(ECRC_FORWARD_CHECK))
         altpcierd_cdma_ast_rx_i_64 (
               .clk_in(clk_in),
               .srst(srst),

               .rx_stream_ready0(rx_stream_ready0),
               .rx_stream_valid0(rx_stream_valid0_reg),
               .rxdata     (rxdata),
               .rxdata_be  (rxdata_be),

               .rx_req0    (rx_req0),
               .rx_ack0    (rx_ack0),
               .rx_data0   (rx_data0),
               .rx_be0     (rx_be0),
               .rx_desc0   (rx_desc0),
               .rx_dfr0    (rx_dfr0),
               .rx_dv0     (rx_dv0),
               .rx_ws0     (rx_ws0),
               .ecrc_bad_cnt(rx_ecrc_bad_cnt));
     end
   end
   endgenerate

   generate  begin : ICM
      if (TL_SELECTION == 0) begin

   //------------------------------------------------------------
   //    TX Streaming Interface
   //       - generates streaming interface signals
   //       - arbitrates between master and slave requests
   //------------------------------------------------------------
   // rx_req is generated one clk cycle ahead of
   // other control signals.
   // re-align here.
      altpcierd_cdma_ast_tx #(.TL_SELECTION(TL_SELECTION))
            altpcierd_cdma_ast_tx_i (
               .clk_in(clk_in),  //TODO Use srst
               .rstn(rstn),
               .tx_stream_data0(tx_stream_data0_0),
               .tx_stream_ready0(tx_stream_ready0),
               .tx_stream_valid0(tx_stream_valid0),

               .tx_req0    (tx_req0),
               .tx_ack0    (tx_ack0),
               .tx_desc0   (tx_desc0),
               .tx_data0   (tx_data0[63:0]),
               .tx_dfr0    (tx_dfr0),
               .tx_dv0     (tx_dv0),
               .tx_err0    (tx_err0),
               .tx_ws0     (tx_ws0));

   //------------------------------------------------------------
   //    RX Streaming Interface
   //       - generates streaming interface signals
   //       - routes data to master/slave
   //------------------------------------------------------------
      altpcierd_cdma_ast_rx  #(.TL_SELECTION(TL_SELECTION))
         altpcierd_cdma_ast_rx_i (
               .clk_in(clk_in),
               .rstn(rstn),  //TODO Use srst

               .rx_stream_ready0(rx_stream_ready0),
               .rx_stream_valid0(rx_stream_valid0),
               .rx_stream_data0(rx_stream_data0_0),

               .rx_req0    (rx_req0),
               .rx_ack0    (rx_ack0),
               .rx_data0   (rx_data0[63:0]),
               .rx_desc0   (rx_desc0),
               .rx_dfr0    (rx_dfr0),
               .rx_dv0     (rx_dv0),
               .rx_ws0     (rx_ws0),
               .rx_be0     (rx_be0),
               .ecrc_bad_cnt(rx_ecrc_bad_cnt));

      assign rx_data0[127:64] = 0;

      end
   end
   endgenerate

  generate begin : HIPCAB_128
      if (AVALON_ST_128==1) begin
   //------------------------------------------------------------
   //    TX Streaming Interface
   //       - generates streaming interface signals
   //       - arbitrates between master and slave requests
   //------------------------------------------------------------
   // rx_req is generated one clk cycle ahead of
   // other control signals.
   // re-align here.
      wire [132:0] txdata;

      wire         otx_req0 ;
      wire [127:0] otx_desc0;
      wire         otx_err0 ;
      wire         otx_dv0  ;
      wire         otx_dfr0 ;
      wire [127:0] otx_data0;

      assign tx_stream_data0_0[74]   = txdata[132];//err
      assign tx_stream_data0_0[73]   = txdata[131];//sop
      assign tx_stream_data0_0[72]   = txdata[130];//eop
      assign tx_stream_data0_0[71:64] = 0;

      assign tx_stream_data0_1[74]    = txdata[132];//err
      assign tx_stream_data0_1[73]    = txdata[129];//sop
      assign tx_stream_data0_1[72]    = txdata[128];//eop
      assign tx_stream_data0_1[71:64] = 0;

      assign tx_stream_data0_0[63:0] = {txdata[95:64], txdata[127:96]};
      assign tx_stream_data0_1[63:0] = {txdata[31:0] , txdata[63:32]};

      altpcierd_tx_req_reg  #(
         .TX_PIPE_REQ(CLK_250_APP)
            ) altpcierd_tx_req128_reg  (
               .clk_in   (clk_in   ),
               .rstn     (rstn     ),
               .itx_req0 (tx_req0  ),
               .itx_desc0(tx_desc0 ),
               .itx_err0 (tx_err0  ),
               .itx_dv0  (tx_dv0   ),
               .itx_dfr0 (tx_dfr0  ),
               .itx_data0(tx_data0 ),
               .otx_req0 (otx_req0 ),
               .otx_desc0(otx_desc0),
               .otx_err0 (otx_err0 ),
               .otx_dv0  (otx_dv0  ),
               .otx_dfr0 (otx_dfr0 ),
               .otx_data0(otx_data0)
         );

      altpcierd_cdma_ast_tx_128
       #(   .TX_PIPE_REQ(CLK_250_APP),
             .ECRC_FORWARD_GENER(ECRC_FORWARD_GENER))
            altpcierd_cdma_ast_tx_i_128 (
               .clk_in(clk_in),
               .rstn(rstn),
               // Avalon-ST
               .txdata(txdata),
               .tx_stream_ready0(tx_stream_ready0_reg),
               .tx_stream_valid0(tx_stream_valid0),
               // Application iterface
               .tx_req0    (otx_req0),
               .tx_ack0    (tx_ack0),
               .tx_desc0   (otx_desc0),
               .tx_data0   (otx_data0),
               .tx_dfr0    (otx_dfr0),
               .tx_dv0     (otx_dv0),
               .tx_err0    (otx_err0),
               .tx_ws0     (tx_ws0),
               .tx_fifo_empty (tx_local_fifo_empty));

   //------------------------------------------------------------
   //    RX Streaming Interface
   //       - generates streaming interface signals
   //       - routes data to master/slave
   //------------------------------------------------------------
      wire [139:0] rxdata;
      wire [15:0]  rxdata_be;   // rx byte enables
      assign rxdata_be = {rx_stream_data0_0_reg[77:74], rx_stream_data0_0_reg[81:78],
                          rx_stream_data0_1_reg[77:74], rx_stream_data0_1_reg[81:78]};  // swapped to keep consistent with DW swapping on data field
      assign rxdata = {
         rx_stream_data0_0_reg[73],    //rx_sop0 [139]
         rx_stream_data0_0_reg[72],    //rx_eop0 [138]
         rx_stream_data0_1_reg[73],    //rx_eop1 [137]
         rx_stream_data0_1_reg[72],    //rx_eop1 [136]
         rx_stream_data0_0_reg[71:64], //bar     [135:128]          |  Aligned | Un-aligned 3 DW | UN-aligned 4 DW
         rx_stream_data0_0_reg[31:0],   // rx_desc[127:96]  aka H0  |   D0     |  -  -> D1       |     -> D3
         rx_stream_data0_0_reg[63:32],  // rx_desc[95:64 ]  aka H1  |   D1     |  -  -> D2       |  D0 -> D4
         rx_stream_data0_1_reg[31:0],   // rx_desc[63:32 ]  aka H2  |   D2     |  -  -> D3       |  D1 -> D5
         rx_stream_data0_1_reg[63:32]}; // rx_desc[31:0  ]  aka H4  |   D3     |  D0 -> D4       |  D2 -> D6
      altpcierd_cdma_ast_rx_128
       #(.ECRC_FORWARD_CHECK(ECRC_FORWARD_CHECK))
         altpcierd_cdma_ast_rx_i_128 (
               .clk_in(clk_in),
               .rstn(rstn),

               .rx_stream_ready0(rx_stream_ready0),
               .rx_stream_valid0(rx_stream_valid0_reg),
               .rxdata(rxdata),
               .rxdata_be(rxdata_be),

               .rx_req0    (rx_req0),
               .rx_ack0    (rx_ack0),
               .rx_data0   (rx_data0),
               .rx_be0     (rx_be0),
               .rx_desc0   (rx_desc0),
               .rx_dfr0    (rx_dfr0),
               .rx_dv0     (rx_dv0),
               .rx_ws0     (rx_ws0),
               .ecrc_bad_cnt(rx_ecrc_bad_cnt));
      end
   end
   endgenerate
   //------------------------------------------------------------
   //    Chaining DMA application interface
   //------------------------------------------------------------
   // This parameter is specific to the implementation of the
   // Avalon streaming interface in the Chaining DMA design example.
   // It specifies the cdma_ast_rx's response time to an rx_ws assertion.
   // i.e. rx_data responds "CDMA_AST_RXWS_LATENCY" clock cycles after rx_ws asserts.

   localparam CDMA_AST_RXWS_LATENCY = (TL_SELECTION==0) ?  4 :  2;


   assign aer_msi_num = 0;
   assign pm_data     = 0;
   assign pex_msi_num = 0;

   assign app_msi_ack_int  = (USE_MSI==0)?0:(TL_SELECTION==0)?app_msi_ack_dd:app_msi_ack_reg;
   assign app_msi_req      = (USE_MSI==0)?0:(TL_SELECTION==0)?0:app_msi_req_synced;
   assign app_msi_tc       = (USE_MSI==0)?0:(TL_SELECTION==0)?0:app_msi_tc_int;
   assign app_msi_num      = (USE_MSI==0)?0:(TL_SELECTION==0)?0:app_msi_num_int;

   assign tx_mask0         = (TL_SELECTION==0)?tx_stream_mask0:1'b0;


   // states for msi_req_state
   parameter MSI_MON_IDLE         = 4'h0;
   parameter MSI_WAIT_LOCAL_EMPTY = 4'h1;
   parameter MSI_WAIT_LATENCY     = 4'h2;
   parameter MSI_WAIT_CORE_EMPTY  = 4'h3;
   parameter MSI_WAIT_CORE_ACK    = 4'h4;

   // this state machine synchronizes the app_msi_req
   // generation to the tx streaming datapath so that
   // it is issued only after the previously issued tx
   // data has been transferred to the core
   always @(posedge clk_in) begin
      if (srst==1'b1) begin
         app_msi_req_synced  <= 1'b0;
         tx_fifo_empty_timer <= 4'h0;
         msi_req_state       <= MSI_MON_IDLE;
         app_msi_ack_reg     <= 1'b0;
      end
      else begin
         app_msi_req_synced  <= app_msi_req_synced_n;
         tx_fifo_empty_timer <= tx_fifo_empty_timer_n;
         msi_req_state       <= (USE_MSI==0)?MSI_MON_IDLE:msi_req_state_n;
         app_msi_ack_reg     <= app_msi_ack;
      end
   end

   always @(*) begin
          // defaults
         app_msi_req_synced_n  = app_msi_req_synced;
         tx_fifo_empty_timer_n = tx_fifo_empty_timer;
         msi_req_state_n       = msi_req_state;

          case (msi_req_state)
              MSI_MON_IDLE: begin
                  app_msi_req_synced_n = 1'b0;
                  if (USE_MSI==0)
                      msi_req_state_n = MSI_MON_IDLE;
                  else if (app_msi_req_int==1'b1)
                      msi_req_state_n = MSI_WAIT_LOCAL_EMPTY;
                  else
                      msi_req_state_n = msi_req_state;
              end
              MSI_WAIT_LOCAL_EMPTY: begin
                  tx_fifo_empty_timer_n = 4'h0;
                  if (tx_local_fifo_empty==1'b1)
                      msi_req_state_n = MSI_WAIT_LATENCY;
                  else
                      msi_req_state_n = msi_req_state;
              end
              MSI_WAIT_LATENCY: begin
                  tx_fifo_empty_timer_n = tx_fifo_empty_timer + 1;
                  if (tx_fifo_empty_timer[3]==1'b1)
                      msi_req_state_n = MSI_WAIT_CORE_EMPTY;
                  else
                      msi_req_state_n = msi_req_state;
              end
              MSI_WAIT_CORE_EMPTY: begin
                  if (tx_stream_fifo_empty0==1'b1) begin
                      app_msi_req_synced_n = 1'b1;
                      msi_req_state_n      = MSI_WAIT_CORE_ACK;
                  end
                  else begin
                      app_msi_req_synced_n = app_msi_req_synced;
                      msi_req_state_n      = msi_req_state;
                  end
              end
              MSI_WAIT_CORE_ACK: begin
                  if (app_msi_ack_reg==1'b1) begin
                      msi_req_state_n      = MSI_MON_IDLE;
                      app_msi_req_synced_n = 1'b0;
                  end
                  else begin
                      msi_req_state_n      = msi_req_state;
                      app_msi_req_synced_n = app_msi_req_synced;
                  end
              end
              default: begin
                  app_msi_req_synced_n  = app_msi_req_synced;
                  msi_req_state_n       = msi_req_state;
                  tx_fifo_empty_timer_n = tx_fifo_empty_timer;
              end
          endcase
     end

      altpcierd_cdma_app_icm #(
            .AVALON_WADDR           (AVALON_WADDR),
            .AVALON_WDATA           (AVALON_WDATA),
            .MAX_NUMTAG             (MAX_NUMTAG),
            .MAX_PAYLOAD_SIZE_BYTE  (MAX_PAYLOAD_SIZE_BYTE),
            .BOARD_DEMO             (BOARD_DEMO),
            .USE_CREDIT_CTRL        (USE_CREDIT_CTRL),
            .USE_DMAWRITE           (USE_DMAWRITE),
            .USE_DMAREAD            (USE_DMAREAD ),
            .USE_MSI                (USE_MSI),
            .CHECK_BUS_MASTER_ENA   (CHECK_BUS_MASTER_ENA),
            .RC_64BITS_ADDR         (RC_64BITS_ADDR),
            .CLK_250_APP            (CLK_250_APP),
            .TL_SELECTION           (TL_SELECTION),
            .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
            .AVALON_ST_128          (AVALON_ST_128),
            .TXCRED_WIDTH           (TXCRED_WIDTH),
            .CDMA_AST_RXWS_LATENCY  (CDMA_AST_RXWS_LATENCY)
         ) chaining_dma_arb (
            .app_msi_ack (app_msi_ack_int),
            .app_msi_req (app_msi_req_int),
            .app_msi_num (app_msi_num_int),
            .app_msi_tc  (app_msi_tc_int),

            .app_int_sts (app_int_sts),
            .app_int_ack (app_int_ack),

            .cfg_busdev  (cfg_busdev),
            .cfg_prmcsr  (cfg_prmcsr),
            .cfg_devcsr  (cfg_devcsr),
            .cfg_linkcsr (cfg_linkcsr),
            .cfg_tcvcmap (cfg_tcvcmap),
            .cfg_msicsr  (cfg_msicsr),

            .cpl_err                (cpl_err),
            .err_desc               (err_desc),
            .cpl_pending            (cpl_pending),
            .ko_cpl_spc_vc0         (ko_cpl_spc_vc0),
            .tx_mask0               (tx_mask0),
            .cpld_rx_buffer_ready   (cpld_rx_buffer_ready),
            .tx_cred0               (tx_stream_cred0),
            .tx_stream_ready0       (tx_stream_ready0),

            .clk_in (clk_in),
            .rstn (rstn),  //TODO Use srst

            .rx_req0    (rx_req0),
            .rx_ack0    (rx_ack0),
            .rx_data0   (rx_data0),
            .rx_be0     (rx_be0),
            .rx_desc0   (rx_desc0),
            .rx_dfr0    (rx_dfr0),
            .rx_dv0     (rx_dv0),
            .rx_ws0     (rx_ws0),
            .rx_mask0   (rx_stream_mask0),
            .rx_ecrc_bad_cnt(rx_ecrc_bad_cnt),

            .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),
            .tx_req0    (tx_req0),
            .tx_ack0    (tx_ack0),
            .tx_desc0   (tx_desc0),
            .tx_data0   (tx_data0),
            .tx_dfr0    (tx_dfr0),
            .tx_dv0     (tx_dv0),
            .tx_err0    (tx_err0),
            .tx_ws0     (tx_ws0));



endmodule


module altpcierd_tx_req_reg  #(
   parameter TX_PIPE_REQ=0
      )(
   input             clk_in,
   input             rstn,

   //transmit section channel 0
   input             itx_req0 ,
   input [127:0]     itx_desc0,
   input             itx_err0 ,
   input             itx_dv0  ,
   input             itx_dfr0 ,
   input[127:0]      itx_data0,


   output            otx_req0 ,
   output [127:0]    otx_desc0,
   output            otx_err0 ,
   output            otx_dv0  ,
   output            otx_dfr0 ,
   output [127:0]    otx_data0
   );

   generate begin
      if (TX_PIPE_REQ==0) begin : g_comb
         assign otx_req0  = itx_req0 ;
         assign otx_desc0 = itx_desc0;
         assign otx_err0  = itx_err0 ;
         assign otx_dv0   = itx_dv0  ;
         assign otx_dfr0  = itx_dfr0 ;
         assign otx_data0 = itx_data0;
      end
   end
   endgenerate

   generate begin
      if (TX_PIPE_REQ>0) begin : g_pipe
         reg            rtx_req0 ;
         reg [127:0]    rtx_desc0;
         reg            rtx_err0 ;
         reg            rtx_dv0  ;
         reg            rtx_dfr0 ;
         reg [127:0]    rtx_data0;

         assign otx_req0  = rtx_req0 ;
         assign otx_desc0 = rtx_desc0;
         assign otx_err0  = rtx_err0 ;
         assign otx_dv0   = rtx_dv0  ;
         assign otx_dfr0  = rtx_dfr0 ;
         assign otx_data0 = rtx_data0;

         always @ (negedge rstn or posedge clk_in) begin
            if (rstn==1'b0) begin
               rtx_req0  <= 0;
               rtx_desc0 <= 0;
               rtx_err0  <= 0;
               rtx_dv0   <= 0;
               rtx_dfr0  <= 0;
               rtx_data0 <= 0;
            end
            else begin
               rtx_req0  <= itx_req0 ;
               rtx_desc0 <= itx_desc0;
               rtx_err0  <= itx_err0 ;
               rtx_dv0   <= itx_dv0  ;
               rtx_dfr0  <= itx_dfr0 ;
               rtx_data0 <= itx_data0;
            end
         end
      end
   end
   endgenerate

endmodule
