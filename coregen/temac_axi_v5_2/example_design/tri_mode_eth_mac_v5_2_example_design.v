//------------------------------------------------------------------------------
// File       : tri_mode_eth_mac_v5_2_example_design.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------
// (c) Copyright 2004-2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 
// -----------------------------------------------------------------------------
// Description:  This is the Verilog example design for the Tri-Mode
//               Ethernet MAC core. It is intended that this example design
//               can be quickly adapted and downloaded onto an FPGA to provide
//               a real hardware test environment.
//
//               This level:
//
//               * Instantiates the FIFO Block wrapper, containing the
//                 block level wrapper and an RX and TX FIFO with an
//                 AXI-S interface;
//
//               * Instantiates a simple AXI-S example design,
//                 providing an address swap and a simple
//                 loopback function;
//
//               * Instantiates transmitter clocking circuitry
//                   -the User side of the FIFOs are clocked at gtx_clk
//                    at all times
//
//               * Instantiates a state machine which drives the AXI Lite
//                 interface to bring the TEMAC up in the correct state
//
//               * Serializes the Statistics vectors to prevent logic being 
//                 optimized out
//
//               * Ties unused inputs off to reduce the number of IO
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Tri-Mode Ethernet MAC User Gude for further information.
//
//
//    ---------------------------------------------------------------------
//    | EXAMPLE DESIGN WRAPPER                                            |
//    |           --------------------------------------------------------|
//    |           |FIFO BLOCK WRAPPER                                     |
//    |           |                                                       |
//    |           |                                                       |
//    |           |              -----------------------------------------|
//    |           |              | BLOCK LEVEL WRAPPER                    |
//    | --------  |              |                                        |
//    | |      |  |              |      -------------------               |
//    | | AXI  |--|--------------|----->|                 |               |
//    | | LITE |  |              |      | AXI4-Lite IPIF  |               |
//    | |  SM  |  |              |      |                 |               |
//    | |      |<-|--------------|------|                 |               |
//    | |      |  |              |      -------------------               |
//    | --------  |              |         |    |                         |
//    |           |              |    ---------------------               |
//    |           |              |    | ETHERNET MAC CORE |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    |           |              |    |                   |               |
//    | --------  |  ----------  |    |                   |               |
//    | |      |  |  |        |  |    |                   |  ---------    |
//    | |      |->|->|        |--|--->| Tx            Tx  |--|       |--->|
//    | |  PAT |  |  |        |  |    | AXI-S         PHY |  |       |    |
//    | |  GEN |  |  |        |  |    | I/F           I/F |  |       |    |
//    | |(ADDR |  |  |  AXI-S |  |    |                   |  | PHY   |    |
//    | | SWAP)|  |  |  FIFO  |  |    |                   |  | I/F   |    |
//    | |      |  |  |        |  |    |                   |  |       |    |
//    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
//    | |      |  |  |        |  |    | AXI-S         PHY |  |       |    |
//    | |      |<-|<-|        |<-|----| I/F           I/F |<-|       |<---|
//    | |      |  |  |        |  |    |                   |  ---------    |
//    | --------  |  ----------  |    |                   |               |
//    |           |              |    ---------------------               |
//    |           |              |                                        |
//    |           |              -----------------------------------------|
//    |           --------------------------------------------------------|
//    ---------------------------------------------------------------------
//
//------------------------------------------------------------------------------

`timescale 1 ps/1 ps


//------------------------------------------------------------------------------
// The entity declaration for the example_design level wrapper.
//------------------------------------------------------------------------------

module tri_mode_eth_mac_v5_2_example_design 
   (
      // asynchronous reset
      input         glbl_rst,

      // 200MHz clock input from board
      input         clk_in_p,
      input         clk_in_n,
      
      output        phy_resetn,
      
      // GMII Interface
      //---------------
      
      output [7:0]  gmii_txd,
      output        gmii_tx_en,
      output        gmii_tx_er,
      output        gmii_tx_clk,
      input  [7:0]  gmii_rxd,
      input         gmii_rx_dv,
      input         gmii_rx_er,
      input         gmii_rx_clk,
      input         gmii_col,
      input         gmii_crs,

      // MDIO Interface
      //---------------
      inout         mdio,
      output        mdc,

      // Serialised statistics vectors
      //------------------------------
      output        tx_statistics_s,
      output        rx_statistics_s,
      
      // Serialised Pause interface controls
      //------------------------------------
      input         pause_req_s,
      
      // Main example design controls
      //-----------------------------
      input  [1:0]  mac_speed,
      input         update_speed,
      //input         serial_command, // tied to pause_req_s
      input         config_board,
      output        serial_response,
      input         gen_tx_data,
      input         chk_tx_data,
      input         reset_error,
      output        frame_error,
      output        frame_errorn,
      output        activity_flash,
      output        activity_flashn
      
    );

   //----------------------------------------------------------------------------
   // Parameters used in this top level wrapper.
   //----------------------------------------------------------------------------
   parameter MAC_BASE_ADDR = 32'h0;
  
   //----------------------------------------------------------------------------
   // internal signals used in this top level wrapper.
   //----------------------------------------------------------------------------
  
   // example design clocks
   (* KEEP = "TRUE" *)
   wire                 gtx_clk_bufg;
   (* KEEP = "TRUE" *)
   wire                 refclk_bufg;
   (* KEEP = "TRUE" *)
   wire                 s_axi_aclk;                 
   wire                 rx_mac_aclk;
   reg                  phy_resetn_int;
   // resets (and reset generation)
   wire                 s_axi_reset_int;
   reg                  s_axi_pre_resetn = 0;
   reg                  s_axi_resetn = 0;
   wire                 chk_reset_int;
   reg                  chk_pre_resetn = 0;
   reg                  chk_resetn = 0;
   wire                 gtx_clk_reset_int;
   reg                  gtx_pre_resetn = 0;
   reg                  gtx_resetn = 0;
   wire                 rx_reset;
   wire                 tx_reset;

   wire                 dcm_locked;
   wire                 glbl_rst_int;
   reg   [5:0]          phy_reset_count;
   wire                 glbl_rst_intn;
   

   // USER side RX AXI-S interface
   wire                 rx_fifo_clock;
   wire                 rx_fifo_resetn;  
   wire  [7:0]          rx_axis_fifo_tdata;
   wire                 rx_axis_fifo_tvalid;
   wire                 rx_axis_fifo_tlast;
   wire                 rx_axis_fifo_tready;

   // USER side TX AXI-S interface
   wire                 tx_fifo_clock;
   wire                 tx_fifo_resetn;
   wire  [7:0]          tx_axis_fifo_tdata;
   wire                 tx_axis_fifo_tvalid;
   wire                 tx_axis_fifo_tlast;
   wire                 tx_axis_fifo_tready;
   
   // RX Statistics serialisation signals
   (* KEEP = "TRUE" *)
   wire                 rx_statistics_valid;
   reg                  rx_statistics_valid_reg;
   (* KEEP = "TRUE" *)
   wire  [27:0]         rx_statistics_vector;
   reg   [27:0]         rx_stats;
   reg                  rx_stats_toggle = 0;
   wire                 rx_stats_toggle_sync;
   reg                  rx_stats_toggle_sync_reg = 0;
   reg   [29:0]         rx_stats_shift;

   // TX Statistics serialisation signals
   (* KEEP = "TRUE" *)
   wire                 tx_statistics_valid;
   reg                  tx_statistics_valid_reg;
   (* KEEP = "TRUE" *)
   wire  [31:0]         tx_statistics_vector;
   reg   [33:0]         tx_stats_shift;

   // Pause interface DESerialisation
   reg   [18:0]         pause_shift;
   reg                  pause_req;
   reg   [15:0]         pause_val;

   // AXI-Lite interface                
   (* KEEP = "TRUE" *)
   wire  [31:0]         s_axi_awaddr;
   (* KEEP = "TRUE" *)
   wire                 s_axi_awvalid;
   (* KEEP = "TRUE" *)
   wire                 s_axi_awready;
   (* KEEP = "TRUE" *)
   wire  [31:0]         s_axi_wdata;
   (* KEEP = "TRUE" *)
   wire                 s_axi_wvalid;
   (* KEEP = "TRUE" *)
   wire                 s_axi_wready;
   (* KEEP = "TRUE" *)
   wire  [1:0]          s_axi_bresp;
   (* KEEP = "TRUE" *)
   wire                 s_axi_bvalid;
   (* KEEP = "TRUE" *)
   wire                 s_axi_bready;
   (* KEEP = "TRUE" *)
   wire  [31:0]         s_axi_araddr;
   (* KEEP = "TRUE" *)
   wire                 s_axi_arvalid;
   (* KEEP = "TRUE" *)
   wire                 s_axi_arready;
   (* KEEP = "TRUE" *)
   wire  [31:0]         s_axi_rdata;   
   (* KEEP = "TRUE" *)
   wire  [1:0]          s_axi_rresp;
   (* KEEP = "TRUE" *)
   wire                 s_axi_rvalid;
   (* KEEP = "TRUE" *)
   wire                 s_axi_rready;
   
   // set board defaults - only updated when reprogrammed
   reg                  enable_address_swap = 1;
   reg                  enable_phy_loopback = 0;
   
   // signal tie offs             
   wire  [7:0]          tx_ifg_delay = 0;    // not used in this example

   assign frame_errorn = !frame_error;
   assign activity_flashn = !activity_flash;
  
   wire                 mdio_i;
   wire                 mdio_o;
   wire                 mdio_t;
      
   // want to infer an IOBUF on the mdio port
   assign mdio = mdio_t ? 1'bz : mdio_o;
  
   assign mdio_i = mdio;


  // when the config_board button is pushed capture and hold the 
  // state of the gne/chek tx_data inputs.  These values will persist until the 
  // board is reprogrammed or config_board is pushed again
  always @(posedge gtx_clk_bufg)
  begin
     if (config_board) begin
        enable_address_swap   <= gen_tx_data;
     end
  end

  always @(posedge s_axi_aclk)
  begin
     if (config_board) begin
        enable_phy_loopback   <= chk_tx_data;
     end
  end


  //----------------------------------------------------------------------------
  // Clock logic to generate required clocks from the 200MHz on board
  // if 125MHz is available directly this can be removed
  //----------------------------------------------------------------------------
  clk_wiz_v2_1 clock_generator
  (   
      // Clock in ports
      .CLK_IN1_P     (clk_in_p),
      .CLK_IN1_N     (clk_in_n),
      // Clock out ports
      .CLK_OUT1      (gtx_clk_bufg),
      .CLK_OUT2      (s_axi_aclk),
      .CLK_OUT3      (refclk_bufg),
      // Status and control signals
      .RESET         (glbl_rst),
      .LOCKED        (dcm_locked)
 );
 
  //---------------
  // global reset
   reset_sync glbl_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst),
      .reset_out        (glbl_rst_int)
   );

   assign glbl_rst_intn = !glbl_rst_int;


  //----------------------------------------------------------------------------
  // Generate the user side clocks for the axi fifos
  //----------------------------------------------------------------------------
  assign tx_fifo_clock = gtx_clk_bufg;
  assign rx_fifo_clock = gtx_clk_bufg;
  
  //----------------------------------------------------------------------------
  // Generate resets required for the fifo side signals etc
  //----------------------------------------------------------------------------
  // in each case the async reset is first captured and then synchronised
  
  //---------------
  // AXI-Lite reset
   reset_sync axi_lite_reset_gen (
      .clk              (s_axi_aclk),
      .enable           (phy_resetn_int),
      .reset_in         (glbl_rst),
      .reset_out        (s_axi_reset_int)
   );

   // Create fully synchronous reset in the s_axi clock domain.
   always @(posedge s_axi_aclk)
   begin
     if (s_axi_reset_int) begin
       s_axi_pre_resetn <= 0;
       s_axi_resetn     <= 0;
     end
     else begin
       s_axi_pre_resetn <= 1;
       s_axi_resetn     <= s_axi_pre_resetn;
     end
   end 

  //---------------
  // gtx_clk reset
   reset_sync gtx_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst || rx_reset || tx_reset),
      .reset_out        (gtx_clk_reset_int)
   );

   // Create fully synchronous reset in the gtx_clk domain.
   always @(posedge gtx_clk_bufg)
   begin
     if (gtx_clk_reset_int) begin
       gtx_pre_resetn  <= 0;
       gtx_resetn      <= 0;
     end
     else begin
       gtx_pre_resetn  <= 1;
       gtx_resetn      <= gtx_pre_resetn;
     end
   end 

  //---------------
  // data check reset
   reset_sync chk_reset_gen (
      .clk              (gtx_clk_bufg),
      .enable           (dcm_locked),
      .reset_in         (glbl_rst || reset_error),
      .reset_out        (chk_reset_int)
   );

   // Create fully synchronous reset in the gtx_clk domain.
   always @(posedge gtx_clk_bufg)
   begin
     if (chk_reset_int) begin
       chk_pre_resetn  <= 0;
       chk_resetn      <= 0;
     end
     else begin
       chk_pre_resetn  <= 1;
       chk_resetn      <= chk_pre_resetn;
     end
   end 

   
   //---------------
   // PHY reset
   // the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
   // this is derived using the 125MHz available and a 6 bit counter
   always @(posedge gtx_clk_bufg)
   begin
      if (!glbl_rst_intn) begin
         phy_resetn_int <= 0;
         phy_reset_count <= 0;
      end
      else begin
         if (!(&phy_reset_count)) begin
            phy_reset_count <= phy_reset_count + 1;
         end
         else begin
            phy_resetn_int <= 1;
         end
      end
   end
   
   assign phy_resetn = phy_resetn_int;

   // generate the user side resets for the axi fifos
   assign tx_fifo_resetn = gtx_resetn;
   assign rx_fifo_resetn = gtx_resetn;
  
  //----------------------------------------------------------------------------
  // Serialize the stats vectors
  // This is a single bit approach, retimed onto gtx_clk
  // this code is only present to prevent code being stripped..
  //----------------------------------------------------------------------------
  
  // RX STATS
  
  // first capture the stats on the appropriate clock
  always @(posedge rx_mac_aclk)
  begin
     rx_statistics_valid_reg <= rx_statistics_valid;
     if (!rx_statistics_valid_reg & rx_statistics_valid) begin
        rx_stats <= rx_statistics_vector;
        rx_stats_toggle <= !rx_stats_toggle;
     end
  end

  sync_block rx_stats_sync (
     .clk              (gtx_clk_bufg),
     .data_in          (rx_stats_toggle),
     .data_out         (rx_stats_toggle_sync)
  );
  
  always @(posedge gtx_clk_bufg)
  begin
     rx_stats_toggle_sync_reg <= rx_stats_toggle_sync;
  end

  // when an update is rxd load shifter (plus start/stop bit)
  // shifter always runs (no power concerns as this is an example design)
  always @(posedge gtx_clk_bufg)
  begin
     if (rx_stats_toggle_sync_reg != rx_stats_toggle_sync) begin
        rx_stats_shift <= {1'b1, rx_stats, 1'b1};
     end
     else begin
        rx_stats_shift <= {rx_stats_shift[28:0], 1'b0};
     end
  end

  assign rx_statistics_s = rx_stats_shift[29];

  // TX STATS
  
  // when an update is txd load shifter (plus start/stop bit)
  // shifter always runs (no power concerns as this is an example design)
  always @(posedge gtx_clk_bufg)
  begin
     tx_statistics_valid_reg <= tx_statistics_valid;
     if (!tx_statistics_valid_reg & tx_statistics_valid) begin
        tx_stats_shift <= {1'b1, tx_statistics_vector, 1'b1};
     end
     else begin
        tx_stats_shift <= {tx_stats_shift[32:0], 1'b0};
     end
  end

  assign tx_statistics_s = tx_stats_shift[33];

  //----------------------------------------------------------------------------
  // DESerialize the Pause interface
  // This is a single bit approachtimed on gtx_clk
  // this code is only present to prevent code being stripped..
  //----------------------------------------------------------------------------
  // the serialised pause info has a start bit followed by the quanta and a stop bit
  // capture the quanta when the start bit hits the msb and the stop bit is in the lsb
  always @(posedge gtx_clk_bufg)
  begin
     pause_shift <= {pause_shift[17:0], pause_req_s};
  end

  always @(posedge gtx_clk_bufg)
  begin
     if (pause_shift[18] === 1'b0 & pause_shift[17] === 1'b1 & pause_shift[0] === 1'b1) begin
        pause_req <= 1'b1;
        pause_val <= pause_shift[16:1];
     end
     else begin
        pause_req <= 1'b0;
        pause_val <= 0;
     end
  end

  //----------------------------------------------------------------------------
  // Instantiate the AXI-LITE Controller
  
   axi_lite_sm #(
      . MAC_BASE_ADDR               (MAC_BASE_ADDR)
   ) axi_lite_controller (
      .s_axi_aclk                   (s_axi_aclk),                  
      .s_axi_resetn                 (s_axi_resetn),
                                                                        
      .mac_speed                    (mac_speed),              
      .update_speed                 (update_speed),   // may need glitch protection on this..              
      .serial_command               (pause_req_s),
      .serial_response              (serial_response),
      .phy_loopback                 (enable_phy_loopback),
                                                     
      .s_axi_awaddr                 (s_axi_awaddr),       
      .s_axi_awvalid                (s_axi_awvalid),      
      .s_axi_awready                (s_axi_awready),      
                                                         
      .s_axi_wdata                  (s_axi_wdata),        
      .s_axi_wvalid                 (s_axi_wvalid),       
      .s_axi_wready                 (s_axi_wready),       
                                                         
      .s_axi_bresp                  (s_axi_bresp),        
      .s_axi_bvalid                 (s_axi_bvalid),       
      .s_axi_bready                 (s_axi_bready),       
                                                         
      .s_axi_araddr                 (s_axi_araddr),       
      .s_axi_arvalid                (s_axi_arvalid),      
      .s_axi_arready                (s_axi_arready),      
                                                         
      .s_axi_rdata                  (s_axi_rdata),                            
      .s_axi_rresp                  (s_axi_rresp),         
      .s_axi_rvalid                 (s_axi_rvalid),        
      .s_axi_rready                 (s_axi_rready)
   );

  //----------------------------------------------------------------------------
  // Instantiate the TRIMAC core fifo block wrapper
  //----------------------------------------------------------------------------
  tri_mode_eth_mac_v5_2_fifo_block #(
       .C_BASE_ADDRESS              (MAC_BASE_ADDR)
   ) trimac_fifo_block (
      .gtx_clk                      (gtx_clk_bufg),
      // asynchronous reset
      .glbl_rstn                    (glbl_rst_intn),
      .rx_axi_rstn                  (1'b1),
      .tx_axi_rstn                  (1'b1),

      // Reference clock for IDELAYCTRL's
      .refclk                       (refclk_bufg),

      // Receiver Statistics Interface
      //---------------------------------------
      .rx_mac_aclk                  (rx_mac_aclk),
      .rx_reset                     (rx_reset),
      .rx_statistics_vector         (rx_statistics_vector),
      .rx_statistics_valid          (rx_statistics_valid),

      // Receiver (AXI-S) Interface
      //----------------------------------------
      .rx_fifo_clock                (rx_fifo_clock),
      .rx_fifo_resetn               (rx_fifo_resetn),
      .rx_axis_fifo_tdata           (rx_axis_fifo_tdata),
      .rx_axis_fifo_tvalid          (rx_axis_fifo_tvalid),
      .rx_axis_fifo_tready          (rx_axis_fifo_tready),
      .rx_axis_fifo_tlast           (rx_axis_fifo_tlast),

      // Transmitter Statistics Interface
      //------------------------------------------
      .tx_reset                     (tx_reset),
      .tx_ifg_delay                 (tx_ifg_delay),
      .tx_statistics_vector         (tx_statistics_vector),
      .tx_statistics_valid          (tx_statistics_valid),

      // Transmitter (AXI-S) Interface
      //-------------------------------------------
      .tx_fifo_clock                (tx_fifo_clock),
      .tx_fifo_resetn               (tx_fifo_resetn),
      .tx_axis_fifo_tdata           (tx_axis_fifo_tdata),
      .tx_axis_fifo_tvalid          (tx_axis_fifo_tvalid),
      .tx_axis_fifo_tready          (tx_axis_fifo_tready),
      .tx_axis_fifo_tlast           (tx_axis_fifo_tlast),

      // MAC Control Interface
      //------------------------
      .pause_req                    (pause_req),
      .pause_val                    (pause_val),

      // GMII Interface
      //-----------------
      .gmii_txd                     (gmii_txd),
      .gmii_tx_en                   (gmii_tx_en),
      .gmii_tx_er                   (gmii_tx_er),
      .gmii_tx_clk                  (gmii_tx_clk),
      .gmii_rxd                     (gmii_rxd),
      .gmii_rx_dv                   (gmii_rx_dv),
      .gmii_rx_er                   (gmii_rx_er),
      .gmii_rx_clk                  (gmii_rx_clk),
      .gmii_col                     (gmii_col),
      .gmii_crs                     (gmii_crs),
      // MDIO Interface
      //-----------------
      .mdio_i                       (mdio_i),
      .mdio_o                       (mdio_o),
      .mdio_t                       (mdio_t),
      .mdc                          (mdc),

      // AXI-Lite Interface
      //---------------
      .s_axi_aclk                   (s_axi_aclk),
      .s_axi_resetn                 (s_axi_resetn),
      
      .s_axi_awaddr                 (s_axi_awaddr),
      .s_axi_awvalid                (s_axi_awvalid),
      .s_axi_awready                (s_axi_awready),
      
      .s_axi_wdata                  (s_axi_wdata),
      .s_axi_wvalid                 (s_axi_wvalid),
      .s_axi_wready                 (s_axi_wready),
      
      .s_axi_bresp                  (s_axi_bresp),
      .s_axi_bvalid                 (s_axi_bvalid),
      .s_axi_bready                 (s_axi_bready),
      
      .s_axi_araddr                 (s_axi_araddr),
      .s_axi_arvalid                (s_axi_arvalid),
      .s_axi_arready                (s_axi_arready),
      
      .s_axi_rdata                  (s_axi_rdata),
      .s_axi_rresp                  (s_axi_rresp),
      .s_axi_rvalid                 (s_axi_rvalid),
      .s_axi_rready                 (s_axi_rready)
      
   );


  //----------------------------------------------------------------------------
  //  Instantiate the address swapping module and simple pattern generator
  //----------------------------------------------------------------------------
   basic_pat_gen basic_pat_gen (
      .axi_tclk                     (tx_fifo_clock),
      .axi_tresetn                  (tx_fifo_resetn),
      .check_resetn                 (chk_resetn),
    
      .enable_pat_gen               (gen_tx_data),
      .enable_pat_chk               (chk_tx_data),    
      .enable_address_swap          (enable_address_swap),
      .speed                        (mac_speed),
    
      .rx_axis_tdata                (rx_axis_fifo_tdata),
      .rx_axis_tvalid               (rx_axis_fifo_tvalid),
      .rx_axis_tlast                (rx_axis_fifo_tlast),
      .rx_axis_tuser                (1'b0), // the FIFO drops all bad frames
      .rx_axis_tready               (rx_axis_fifo_tready),
    
      .tx_axis_tdata                (tx_axis_fifo_tdata),
      .tx_axis_tvalid               (tx_axis_fifo_tvalid),
      .tx_axis_tlast                (tx_axis_fifo_tlast),
      .tx_axis_tready               (tx_axis_fifo_tready),
    
      .frame_error                  (frame_error),
      .activity_flash               (activity_flash)
   );



endmodule
