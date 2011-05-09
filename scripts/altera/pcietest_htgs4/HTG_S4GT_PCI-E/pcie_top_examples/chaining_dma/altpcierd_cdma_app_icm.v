// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It arbitrates PCI Express packets for
//  * the modules altpcierd_dma_dt (read or write) and altpcierd_rc_slave. It
//  * instantiates the Endpoint memory used for the DMA read and write transfer.
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
// File          : altpcierd_cdma_app_icm.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This is the complete example application for the PCI Express Reference
// Design. This has all of the application logic for the example.
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
//
// TLP Packet constant
`define TLP_FMT_4DW_W        2'b11    // TLP FMT field  -> 64 bits Write
`define TLP_FMT_3DW_W        2'b10    // TLP FMT field  -> 32 bits Write
`define TLP_FMT_4DW_R        2'b01    // TLP FMT field  -> 64 bits Read
`define TLP_FMT_3DW_R        2'b00    // TLP FMT field  -> 32 bits Read

`define TLP_FMT_CPL          2'b00    // TLP FMT field  -> Completion w/o data
`define TLP_FMT_CPLD         2'b10    // TLP FMT field  -> Completion with data

`define TLP_TYPE_WRITE       5'b00000 // TLP Type field -> write
`define TLP_TYPE_READ        5'b00000 // TLP Type field -> read
`define TLP_TYPE_READ_LOCKED 5'b00001 // TLP Type field -> read_lock
`define TLP_TYPE_CPLD        5'b01010 // TLP Type field -> Completion with data
`define TLP_TYPE_IO          5'b00010 // TLP Type field -> IO

`define TLP_TC_DEFAULT       3'b000   // Default TC of the TLP
`define TLP_TD_DEFAULT       1'b0     // Default TD of the TLP
`define TLP_EP_DEFAULT       1'b0     // Default EP of the TLP
`define TLP_ATTR_DEFAULT     2'b0     // Default EP of the TLP

`define RESERVED_1BIT        1'b0     // reserved bit on 1 bit
`define RESERVED_2BIT        2'b00    // reserved bit on 1 bit
`define RESERVED_3BIT        3'b000   // reserved bit on 1 bit
`define RESERVED_4BIT        4'b0000  // reserved bit on 1 bit

`define EP_ADDR_READ_OFFSET  16
`define TRANSACTION_ID       3'b000

`define ZERO_QWORD           64'h0000_0000_0000_0000
`define ZERO_DWORD           32'h0000_0000
`define ZERO_WORD            16'h0000
`define ZERO_BYTE            8'h00

`define ONE_QWORD            64'h0000_0000_0000_0001
`define ONE_DWORD            32'h0000_0001
`define ONE_WORD             16'h0001
`define ONE_BYTE             8'h01

`define MINUS_ONE_QWORD      64'hFFFF_FFFF_FFFF_FFFF
`define MINUS_ONE_DWORD      32'hFFFF_FFFF
`define MINUS_ONE_WORD       16'hFFFF
`define MINUS_ONE_BYTE       8'hFF

`define DIRECTION_WRITE      1
`define DIRECTION_READ       0


module altpcierd_cdma_app_icm #(
   parameter MAX_NUMTAG             = 32,
   parameter AVALON_WADDR           = 12,
   parameter CHECK_BUS_MASTER_ENA   = 0,
   parameter AVALON_WDATA           = 64,
   parameter MAX_PAYLOAD_SIZE_BYTE  = 256,
   parameter BOARD_DEMO             = 0,
   parameter TL_SELECTION           = 0,
   parameter TXCRED_WIDTH           = 36,
   parameter CLK_250_APP            = 0,  // When 1 indicate application clock rate is 250MHz instead of 125 MHz
   parameter RC_64BITS_ADDR         = 0,  // When 1 use 64 bit tx_desc address and not 32
   parameter USE_CREDIT_CTRL        = 0,
   parameter USE_MSI                = 1,  // When 1, tx_arbitration uses tx_cred
   parameter USE_DMAWRITE           = 1,
   parameter USE_DMAREAD            = 1,
   parameter AVALON_ST_128          = 0,
   parameter INTENDED_DEVICE_FAMILY = "Cyclone IV GX",
   parameter CDMA_AST_RXWS_LATENCY  = 2
   )(
   input clk_in  ,
   input rstn    ,

   input[12:0] cfg_busdev,
   input[31:0] cfg_devcsr,
   input[31:0] cfg_prmcsr,
   input[23:0] cfg_tcvcmap,
   input[31:0] cfg_linkcsr,
   input[15:0] cfg_msicsr,
   input[19:0] ko_cpl_spc_vc0,

   output reg  cpl_pending,
   output[6:0] cpl_err,
   output [127:0] err_desc,

   // MSI signals section
   input       app_msi_ack,
   output      app_msi_req,
   output[2:0] app_msi_tc ,
   output[4:0] app_msi_num,

   // Legacy Interupt signals
   output      app_int_sts,
   input       app_int_ack,

   // Receive section channel 0
   output       rx_ack0  ,
   output       rx_mask0 ,
   output       rx_ws0   ,
   input        rx_req0  ,
   input[135:0] rx_desc0 ,
   input[127:0] rx_data0 ,
   input[15:0]  rx_be0,
   input        rx_dv0   ,
   input        rx_dfr0  ,
   input [15:0] rx_ecrc_bad_cnt,

   //transmit section channel 0
   output                   tx_req0 ,
   input                    tx_ack0 ,
   output [127:0]           tx_desc0,
   output                   tx_dv0  ,
   output                   tx_dfr0 ,
   input                    tx_ws0 ,
   output[127:0]            tx_data0,
   output                   tx_err0 ,
   input                    tx_mask0,
   input                    cpld_rx_buffer_ready,
   input [TXCRED_WIDTH-1:0] tx_cred0,
   input [15:0]             rx_buffer_cpl_max_dw,  // specifify the maximum amount of data available in RX Buffer for a given MRd
   input                    tx_stream_ready0

   );

// Local functions

// VHDL translation_on
//      function integer get_numwords;
//         input integer width;
//         begin
//            get_numwords = (1<<width);
//         end
//     endfunction
// localparam NUMWORDS_AVALON_WADDR = get_numwords(AVALON_WADDR);
localparam NUMWORDS_AVALON_WADDR = 1<<AVALON_WADDR;

// VHDL translation_off



// RTL Implementation static parameter
localparam AVALON_BYTE_WIDTH = AVALON_WDATA/8;  // for epmem byte enables

localparam FIFO_WIDTHU        = 6;  // Width of FIFO counters
localparam FIFO_DEPTH         = 64; // Depth of descriptor FIFOs (DMA read and DMA Write)
localparam RC_SLAVE_USETAG    = 0;  // when set (1) the RC Slave uses the TAG 2
localparam DMA_READ_PRIORITY  = 1;
localparam DMA_WRITE_PRIORITY = 1;
localparam CNT_50MS           =(CLK_250_APP==0)?24'h5F5E10:24'hBEBC20;

// Legacy interrupt signals
reg  app_int_req;         // legacy interrupt request
reg  app_int_ack_reg;     // boundary reg on legacy interrupt ack input
wire interrupt_ack_int;   // internal interrupt acknowledge (to interrupt requestor)
wire msi_enable;          // 1'b1 means MSI is enabled.  1'b0 means Legacy interrupt is enabled.
reg  int_deassert;        // State of Legacy interrupt:  1'b1 means issuing Interrupt DEASSERT message, 1'b0 means issuing Interrupt ASSERT message.


// AVALON SIGNALS
wire [AVALON_WDATA-1:0] writedata_dmard  ;
wire [AVALON_WADDR-1:0] address_dmard    ;
wire                    write_dmard      ;
wire                    waitrequest_dmard;
wire [AVALON_BYTE_WIDTH-1:0] write_byteena_dmard;  // From DMA Read

wire [AVALON_WDATA-1:0] open_read_data   ;
wire [AVALON_WDATA-1:0] readdata_dmawr   ;
wire [AVALON_WADDR-1:0] address_dmawr    ;
wire                    read_dmawr       ;
wire                    waitrequest_dmawr;
wire [AVALON_BYTE_WIDTH-1:0] write_byteena_dmawr;  // From DMA Write

wire                    ctl_wr_req;
wire [31:0]             ctl_wr_data;
wire [2:0]              ctl_addr;

// Max Payload, Max Read
reg [15:0] cfg_maxpload_dw ;
reg [15:0] cfg_maxrdreq_dw;  // max length of PCIe read in DWORDS
reg [2:0]  cfg_maxrdreq_rxbuffer;  // max length of PCIe read in DWORDS based on rx_buffer size
reg [2:0]  koh_cfg_maxrdreq;
reg [2:0]  kod_cfg_maxrdreq;
reg [2:0]  cfg_maxrdreq;
reg [2:0]  cfg_maxpload;
reg [4:0]  cfg_link_negociated;
reg [12:0] cfg_busdev_reg;
reg [15:0] cfg_msicsr_reg;

reg [TXCRED_WIDTH-1:0] tx_cred0_reg;
reg tx_mask_reg;
reg tx_stream_ready0_reg;

wire [31:0]  dma_prg_wrdata;
wire [3:0]   dma_prg_addr;
wire         dma_rd_prg_wrena;
wire         dma_wr_prg_wrena;

//tracking completion pending
wire         cpl_pending_dmawr;
wire         cpl_pending_dmard;

reg           mem_rd_data_valid;
reg           read_epmem_del;
reg           read_epmem_del2;
reg           read_epmem_del3;

wire [63:0]   read_dma_status;
wire [63:0]   write_dma_status;

wire          sel_ep_reg;
wire [7:0]    reg_wr_addr;
wire [7:0]    reg_rd_addr;
wire [31:0]   reg_wr_data;
wire [31:0]   reg_rd_data;
wire [31:0]   dma_wr_prg_rddata;
wire [31:0]   dma_rd_prg_rddata;


// Constant carrying width type for VHDL translation
wire cst_one;
wire cst_zero;
wire [63:0] cst_std_logic_vector_type_one;
wire [63:0] cst_std_logic_vector_type_zero;

reg rx_req_reg;
reg rx_req_p1 ;
wire rx_req_p0;
// PCI control signals
reg   pci_bus_master_enable;
reg   pci_mem_addr_space_decoder_enable;

   always @ (posedge clk_in) begin
      rx_req_reg <= rx_req0;
      rx_req_p1   <= rx_req_p0;
      pci_bus_master_enable             <= (CHECK_BUS_MASTER_ENA==1)?cfg_prmcsr[2]:1'b1;
      pci_mem_addr_space_decoder_enable <= (CHECK_BUS_MASTER_ENA==1)?cfg_prmcsr[1]:1'b1;
   end
   assign rx_req_p0 = rx_req0 & ~rx_req_reg;


//------------------------------------------------------------
// Static side-band signals
//------------------------------------------------------------
   assign cst_one         = 1'b1;
   assign cst_zero        = 1'b0;
   assign cst_std_logic_vector_type_one  = 64'hFFFF_FFFF_FFFF_FFFF;
   assign cst_std_logic_vector_type_zero = 0;

   always @ (posedge clk_in) begin
      cfg_maxpload_dw[4 :0 ]    <= 0;
      case (cfg_maxpload)
         3'b000 :cfg_maxpload_dw[10:5 ] <= 6'b000001;// 32    ->  128B
         3'b001 :cfg_maxpload_dw[10:5 ] <= 6'b000010;// 64    ->  256B
         3'b010 :cfg_maxpload_dw[10:5 ] <= 6'b000100;// 128   ->  512B
         3'b011 :cfg_maxpload_dw[10:5 ] <= 6'b001000;// 256   -> 1024B
         3'b100 :cfg_maxpload_dw[10:5 ] <= 6'b010000;// 512   -> 2048B
         default:cfg_maxpload_dw[10:5 ] <= 6'b100000;// 1024  -> 4096B
      endcase
      cfg_maxpload_dw[15:11] <= 0;
   end

   always @ (posedge clk_in) begin
      cfg_maxrdreq_dw[4 :0 ] <= 0;
      case (cfg_maxrdreq)
          3'b000 :cfg_maxrdreq_dw[10:5] <= 6'b000001;// 32    ->  128 Bytes
          3'b001 :cfg_maxrdreq_dw[10:5] <= 6'b000010;// 64    ->  256 Bytes
          3'b010 :cfg_maxrdreq_dw[10:5] <= 6'b000100;// 128   ->  512 Bytes
          3'b011 :cfg_maxrdreq_dw[10:5] <= 6'b001000;// 256   -> 1024 Bytes
          3'b100 :cfg_maxrdreq_dw[10:5] <= 6'b010000;// 512   -> 2048 Bytes
          default:cfg_maxrdreq_dw[10:5] <= 6'b100000;// 1024  -> 4096 Bytes
       endcase
       cfg_maxrdreq_dw[15:11] <= 0;
   end

   // Based on ko_cpl_spc_vc0, adjust the size of max read request
   // 1 MRd consume 1 credit header 4 DWORDs
   // Max Read Request should be smaller than
   // cfg_maxrdreq_rxbuffer assume that
   //  - each cpld header consumes 1 credit (4 DWORDS)
   reg [4:0] koh_cfg_compare;
   always @ (posedge clk_in) begin
      // Each header can be broken into RCB 64 byte + 1 if address is not 64 byte aligned
      // 4096 byte payload
      if (ko_cpl_spc_vc0[7:0] > 8'h40) koh_cfg_compare[4] <=1'b1;
      else                             koh_cfg_compare[4] <=1'b0;
      // 2048 byte payload
      if (ko_cpl_spc_vc0[7:0] > 8'h20) koh_cfg_compare[3] <=1'b1;
      else                             koh_cfg_compare[3] <=1'b0;
      // 1024 byte payload
      if (ko_cpl_spc_vc0[7:0] > 8'h10) koh_cfg_compare[2] <=1'b1;
      else                             koh_cfg_compare[2] <=1'b0;
      // 512 byte payload
      if (ko_cpl_spc_vc0[7:0] > 8'h8)  koh_cfg_compare[1] <=1'b1;
      else                             koh_cfg_compare[1] <=1'b0;
      // 256 byte payload
      if (ko_cpl_spc_vc0[7:0] > 8'h4)  koh_cfg_compare[0] <=1'b1;
      else                             koh_cfg_compare[0] <=1'b0;
   end

   reg [4:0] kod_cfg_compare;
   always @ (posedge clk_in) begin
      // Each credit provide 16 bytes
      // 4096 byte payload -> 12'h400 credit
      if (ko_cpl_spc_vc0[19:8] > 12'h400) kod_cfg_compare[4] <=1'b1;
      else                                kod_cfg_compare[4] <=1'b0;
      // 2048 byte payload -> 12'h200 credit
      if (ko_cpl_spc_vc0[19:8] > 12'h200) kod_cfg_compare[3] <=1'b1;
      else                                kod_cfg_compare[3] <=1'b0;
      // 1024 byte payload -> 12'h100 credit
      if (ko_cpl_spc_vc0[19:8] > 12'h100) kod_cfg_compare[2] <=1'b1;
      else                                kod_cfg_compare[2] <=1'b0;
      // 512 byte payload  -> 12'h80  credit
      if (ko_cpl_spc_vc0[19:8] > 12'h80)  kod_cfg_compare[1] <=1'b1;
      else                                kod_cfg_compare[1] <=1'b0;
      // 256 byte payload  -> 12'h40  credit
      if (ko_cpl_spc_vc0[19:8] > 12'h40)  kod_cfg_compare[0] <=1'b1;
      else                                kod_cfg_compare[0] <=1'b0;
   end

   always @ (posedge clk_in) begin
      // Set the max rd req size based on buffer allocation
      if (koh_cfg_compare[4])          koh_cfg_maxrdreq <= 3'h5;
      else if (koh_cfg_compare[3])     koh_cfg_maxrdreq <= 3'h4;
      else if (koh_cfg_compare[2])     koh_cfg_maxrdreq <= 3'h3;
      else if (koh_cfg_compare[1])     koh_cfg_maxrdreq <= 3'h2;
      else if (koh_cfg_compare[0])     koh_cfg_maxrdreq <= 3'h1;
      else                             koh_cfg_maxrdreq <= 3'h0;

      // Set the max rd req size based on data buffer allocation
      if (kod_cfg_compare[4])          kod_cfg_maxrdreq <= 3'h5;
      else if (kod_cfg_compare[3])     kod_cfg_maxrdreq <= 3'h4;
      else if (kod_cfg_compare[2])     kod_cfg_maxrdreq <= 3'h3;
      else if (kod_cfg_compare[1])     kod_cfg_maxrdreq <= 3'h2;
      else if (kod_cfg_compare[0])     kod_cfg_maxrdreq <= 3'h1;
      else                             kod_cfg_maxrdreq <= 3'h0;

      cfg_maxrdreq_rxbuffer <= (koh_cfg_maxrdreq > kod_cfg_maxrdreq) ?
                                 kod_cfg_maxrdreq : koh_cfg_maxrdreq;
      cfg_maxrdreq         <= (cfg_maxrdreq_rxbuffer>cfg_devcsr[14:12])?
                                 cfg_devcsr[14:12]:cfg_maxrdreq_rxbuffer;
   end

   //pipelined
   always @ (posedge clk_in) begin
      cfg_link_negociated[4:0]<= cfg_linkcsr[24:20] ;
      cfg_maxpload[2:0]       <= cfg_devcsr[7:5]   ;
      tx_mask_reg             <= tx_mask0;
      tx_stream_ready0_reg    <= tx_stream_ready0;
      tx_cred0_reg            <= tx_cred0;
      cfg_busdev_reg          <= cfg_busdev;
      cfg_msicsr_reg          <= cfg_msicsr;
   end

   // unused
   assign rx_mask0  = 1'b0;

//------------------------------------------------------------
//    DMA Write SECTION
//       - suffix _dmard
//------------------------------------------------------------
   // rx
   wire          rx_ack_dmawr;
   wire          rx_ws_dmawr;

   // tx
   wire          tx_req_dmawr;
   wire [127:0]  tx_desc_dmawr;
   wire          tx_err_dmawr;
   wire          tx_dv_dmawr;
   wire          tx_dfr_dmawr;
   wire [127:0]   tx_data_dmawr;

   reg           tx_sel_descriptor_dmawr  ;
   wire          tx_busy_descriptor_dmawr ;
   wire          tx_ready_descriptor_dmawr;
   reg           tx_ready_descriptor_dmawr_r;

   reg           tx_sel_requester_dmawr  ;
   wire          tx_busy_requester_dmawr ;
   wire          tx_ready_requester_dmawr;
   reg           tx_ready_requester_dmawr_r;

   reg           tx_sel_dmawr;
   wire          tx_ready_dmawr;
   wire          tx_sel_dmard;
   wire          tx_ready_dmard;
   wire          tx_stop_dma_write;

   wire          requester_mrdmwr_cycle_dmawr;
   wire          descriptor_mrd_cycle_dmawr;
   wire          init_dmawr     ;
   wire [10:0]   sm_dmawr   ;

   wire        app_msi_req_dmawr;
   wire [2:0]  app_msi_tc_dmawr;
   wire [4:0]  app_msi_num_dmawr;
   wire        msi_ready_dmawr  ;
   wire        msi_busy_dmawr   ;
   reg         msi_sel_dmawr    ;

   wire  tx_rdy_descriptor_dmawr;
   wire  tx_rdy_requester_dmawr ;
   wire  tx_rdy_descriptor_dmard;
   wire  tx_rdy_requester_dmard ;

   altpcierd_dma_dt  #(
      .DIRECTION      (`DIRECTION_WRITE),
      .FIFO_WIDTHU    (FIFO_WIDTHU     ),
      .FIFO_DEPTH     (FIFO_DEPTH      ),
      .USE_CREDIT_CTRL(USE_CREDIT_CTRL ),
      .USE_MSI        (USE_MSI         ),
      .RC_SLAVE_USETAG(RC_SLAVE_USETAG ),
      .USE_DMAWRITE   (USE_DMAWRITE),
      .USE_DMAREAD    (USE_DMAREAD ),
      .TXCRED_WIDTH   (TXCRED_WIDTH    ),
      .BOARD_DEMO     (BOARD_DEMO    ),
      .MAX_PAYLOAD    (MAX_PAYLOAD_SIZE_BYTE  ),
      .RC_64BITS_ADDR (RC_64BITS_ADDR  ),
      .MAX_NUMTAG     (MAX_NUMTAG      ),
      .AVALON_WADDR   (AVALON_WADDR    ),
      .TL_SELECTION   (TL_SELECTION    ),
      .AVALON_ST_128  (AVALON_ST_128   ),
      .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
      .AVALON_WDATA   (AVALON_WDATA    ),
      .CDMA_AST_RXWS_LATENCY (CDMA_AST_RXWS_LATENCY)
      )
      dma_write
      (
      .clk_in         (clk_in       ),
      .rstn           (rstn         ),

      .ctl_wr_req    (ctl_wr_req),
      .ctl_wr_data   (ctl_wr_data),
      .ctl_addr      (ctl_addr),

      .rx_req        (rx_req0 ),
      .rx_req_p0     (rx_req_p0),
      .rx_req_p1     (rx_req_p1),
      .rx_ack        (rx_ack_dmawr  ),
      .rx_desc       (rx_desc0 ),
      .rx_data       (rx_data0),
      .rx_ws         (rx_ws_dmawr  ),
      .rx_dv         (rx_dv0   ),
      .rx_dfr        (rx_dfr0  ),

      .tx_sel_descriptor        (tx_sel_descriptor_dmawr  ),
      .tx_busy_descriptor       (tx_busy_descriptor_dmawr ),
      .tx_ready_descriptor      (tx_ready_descriptor_dmawr),

      .tx_sel_requester        (tx_sel_requester_dmawr  ),
      .tx_busy_requester       (tx_busy_requester_dmawr ),
      .tx_ready_requester      (tx_ready_requester_dmawr),

      .tx_ready_other_dma      (tx_ready_dmard),

      .tx_req        (tx_req_dmawr  ),
      .tx_ack        (tx_ack0  ),
      .tx_desc       (tx_desc_dmawr ),
      .tx_ws         (tx_ws0   ),
      .tx_err        (tx_err_dmawr  ),
      .tx_dv         (tx_dv_dmawr   ),
      .tx_dfr        (tx_dfr_dmawr  ),
      .tx_data       (tx_data_dmawr ),
      .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),

      .app_msi_ack   (interrupt_ack_int),
      .app_msi_req   (app_msi_req_dmawr),
      .app_msi_tc    (app_msi_tc_dmawr ),
      .app_msi_num   (app_msi_num_dmawr),
      .msi_ready     (msi_ready_dmawr),
      .msi_busy      ( msi_busy_dmawr),
      .msi_sel       (  msi_sel_dmawr),

      .tx_cred          (tx_cred0_reg      ),
      .tx_have_creds    (1'b0),
      .cfg_maxpload_dw  (cfg_maxpload_dw),
      .cfg_maxrdreq_dw  (cfg_maxrdreq_dw),
      .cfg_maxpload     (cfg_maxpload  ),
      .cfg_maxrdreq     (cfg_maxrdreq  ),
      .cfg_busdev       (cfg_busdev_reg    ),
      .cfg_link_negociated    (cfg_link_negociated    ),

      .requester_mrdmwr_cycle   (requester_mrdmwr_cycle_dmawr),
      .descriptor_mrd_cycle     (descriptor_mrd_cycle_dmawr),
      .init          (init_dmawr         ),

      .dma_sm  (sm_dmawr),

      .dma_prg_wrdata   (dma_prg_wrdata),
      .dma_prg_addr     (dma_prg_addr),
      .dma_prg_wrena    (dma_wr_prg_wrena),
      .dma_prg_rddata   (dma_wr_prg_rddata),

      .dma_status (write_dma_status),
      .cpl_pending (cpl_pending_dmawr),

      // Avalon Read Master port
      .read_address  (address_dmawr    ),
      .read_wait     (waitrequest_dmawr),
      .read          (read_dmawr       ),
      .read_data     (readdata_dmawr   ),
      .write_byteena  (write_byteena_dmawr )
      );

//------------------------------------------------------------
// AVALON DP MEMORY SECTION
//------------------------------------------------------------


   wire [AVALON_WDATA-1:0] writedata_epmem ;
   wire [AVALON_WADDR-1:0] addresswr_epmem ;
   wire                    write_epmem     ;
   wire [AVALON_WDATA-1:0] readdata_epmem  ;
   wire [AVALON_WADDR-1:0] addressrd_epmem ;
   wire                    read_epmem      ;
   wire                    sel_epmem       ;
   wire [AVALON_BYTE_WIDTH-1:0] write_byteena_epmem;  // From RCSlave

   reg [AVALON_WDATA-1:0] writedata_epmem_del ;
   reg [AVALON_WADDR-1:0] addresswr_epmem_del ;
   reg                    write_epmem_del     ;
   reg [AVALON_WDATA-1:0] mem_rd_data_del  ;
   reg [AVALON_WADDR-1:0] addressrd_epmem_del ;
   reg                    mem_rd_data_valid_del;
   reg                    sel_epmem_del;
   reg [AVALON_BYTE_WIDTH-1:0] write_byteena_epmem_del;


   wire [AVALON_WDATA-1:0] data_a    ;
   wire [AVALON_WADDR-1:0] address_b ;
   wire                    wren_a    ;
   wire[AVALON_WDATA-1:0]  q_b       ;
   wire [AVALON_WADDR-1:0] address_a ;
   wire                    rden_b    ;

   reg [AVALON_WDATA-1:0] data_a_reg   ;
   reg [AVALON_WADDR-1:0] address_b_reg;
   reg                    wren_a_reg   ;
   reg [AVALON_WADDR-1:0] address_a_reg;
   reg                    rden_b_reg   ;
   reg [AVALON_BYTE_WIDTH-1:0] byteena_a_reg;
   reg [AVALON_BYTE_WIDTH-1:0] byteena_b_reg;
   wire [AVALON_BYTE_WIDTH-1:0] byteena_a;
   wire [AVALON_BYTE_WIDTH-1:0] byteena_b;

   assign byteena_a  = byteena_a_reg;
   assign byteena_b  = byteena_b_reg;


   assign data_a     = data_a_reg    ;
   assign address_a  = address_a_reg ;
   assign wren_a     = wren_a_reg    ;
   assign address_b  = address_b_reg ;
   assign rden_b     = rden_b_reg    ;

   // Registered EPMEM
   always @ (posedge clk_in or negedge rstn) begin
      if (rstn==1'b0) begin
         writedata_epmem_del     <= {AVALON_WDATA{1'b0}};
         addresswr_epmem_del     <= 0;
         write_epmem_del         <= 0;
         addressrd_epmem_del     <= 0;
         read_epmem_del          <= 0;
         mem_rd_data_del         <= {AVALON_WDATA{1'b0}};
         mem_rd_data_valid_del   <= 0;
         sel_epmem_del           <= 0;
         write_byteena_epmem_del <= 0;
         data_a_reg              <= {AVALON_WDATA{1'b0}};
         address_a_reg           <= 0;
         wren_a_reg              <= 0;
         address_b_reg           <= 0;
         rden_b_reg              <= 0;
         byteena_a_reg           <= {AVALON_BYTE_WIDTH{1'b0}};
         byteena_b_reg           <= {AVALON_BYTE_WIDTH{1'b0}};  // Port B only used for reading
         read_epmem_del          <= 0;
         read_epmem_del2         <= 0;
         read_epmem_del3         <= 0;
         mem_rd_data_valid       <= 0;
      end
      else begin
          writedata_epmem_del   <= writedata_epmem;
          addresswr_epmem_del   <= addresswr_epmem;
          write_epmem_del       <= write_epmem;
          addressrd_epmem_del   <= addressrd_epmem;
          read_epmem_del        <= read_epmem;
          mem_rd_data_del       <= q_b;
          mem_rd_data_valid_del <= mem_rd_data_valid;
          sel_epmem_del         <= sel_epmem;

          write_byteena_epmem_del <= write_byteena_epmem;
          if (sel_epmem_del==1'b1) begin
             data_a_reg          <= writedata_epmem_del ;
             address_a_reg       <= addresswr_epmem_del ;
             wren_a_reg          <= write_epmem_del     ;
             address_b_reg       <= addressrd_epmem_del ;
             rden_b_reg          <= read_epmem_del      ;
             byteena_a_reg       <= write_byteena_epmem_del;
             byteena_b_reg       <= {AVALON_BYTE_WIDTH{1'b0}};  // Port B only used for reading
             read_epmem_del      <= read_epmem;
             read_epmem_del2     <= read_epmem_del;
             read_epmem_del3     <= read_epmem_del2;
             mem_rd_data_valid   <= read_epmem_del3;
          end
          else begin
             data_a_reg    <= writedata_dmard;
             address_a_reg <= address_dmard  ;
             wren_a_reg    <= write_dmard & ~waitrequest_dmard;
             address_b_reg <= address_dmawr  ;
             rden_b_reg    <= read_dmawr & ~waitrequest_dmawr;
             byteena_a_reg     <= write_byteena_dmard;
             byteena_b_reg     <= {AVALON_BYTE_WIDTH{1'b0}};  // Port B only used for reading
             read_epmem_del    <= 1'b0;
             read_epmem_del2   <= 1'b0;
             read_epmem_del3   <= 1'b0;
             mem_rd_data_valid <= 1'b0;
          end
      end
   end

   assign readdata_epmem = q_b;
   assign readdata_dmawr = q_b;

   altsyncram # (
            .address_reg_b                      ("CLOCK0"          ),
            .indata_reg_b                       ("CLOCK0"          ),
            .wrcontrol_wraddress_reg_b          ("CLOCK0"          ),
            .intended_device_family             (INTENDED_DEVICE_FAMILY),
            .lpm_type                           ("altsyncram"      ),
            .numwords_a                         (NUMWORDS_AVALON_WADDR),
            .numwords_b                         (NUMWORDS_AVALON_WADDR),
            .operation_mode                     ("BIDIR_DUAL_PORT" ),
            .outdata_aclr_a                     ("NONE"            ),
            .outdata_aclr_b                     ("NONE"            ),
            .outdata_reg_a                      ("CLOCK0"          ),
            .outdata_reg_b                      ("CLOCK0"          ),
            .power_up_uninitialized             ("FALSE"           ),
            .read_during_write_mode_mixed_ports ("DONT_CARE"        ),
            .widthad_a                          (AVALON_WADDR      ),
            .widthad_b                          (AVALON_WADDR      ),
            .width_a                            (AVALON_WDATA      ),
            .width_b                            (AVALON_WDATA      ),
            .width_byteena_a                    (AVALON_BYTE_WIDTH ),
            .width_byteena_b                    (AVALON_BYTE_WIDTH ),
            .byteena_reg_b                      ("CLOCK0")
            ) ep_dpram (
            .clock0          (clk_in),
            .wren_a          (wren_a   ),
            .address_a       (address_a),
            .rden_b          (rden_b   ),
            .data_a          (data_a   ),
            .address_b       (address_b),
            .q_b             (q_b      ),
            .aclr0           (cst_zero),
            .aclr1           (cst_zero),
            .addressstall_a  (cst_zero),
            .addressstall_b  (cst_zero),
            .byteena_a       (byteena_a),
            .byteena_b       (byteena_b),
            .clock1          (cst_one),
            .clocken0        (cst_one),
            .clocken1        (cst_one),
            .data_b          (),
            .q_a             (),
            .wren_b          (cst_zero)
            );


//------------------------------------------------------------
//    DMA READ SECTION
//       - suffix _dmard
//------------------------------------------------------------
// RX
   wire          rx_ack_dmard  ;
   wire          rx_ws_dmard   ;

   // TX
   wire          tx_req_dmard  ;
   wire [127:0]  tx_desc_dmard ;
   wire          tx_err_dmard  ;
   wire          tx_dv_dmard   ;
   wire          tx_dfr_dmard  ;
   wire [127:0]  tx_data_dmard ;

   reg           tx_sel_descriptor_dmard  ;
   wire          tx_busy_descriptor_dmard ;
   wire          tx_ready_descriptor_dmard;
   reg           tx_ready_descriptor_dmard_r;

   reg           tx_sel_requester_dmard  ;
   wire          tx_busy_requester_dmard ;
   wire          tx_ready_requester_dmard;
   reg           tx_ready_requester_dmard_r;

   //MSI
   wire       app_msi_req_dmard;
   wire [2:0] app_msi_tc_dmard ;
   wire [4:0] app_msi_num_dmard;
   wire       msi_ready_dmard  ;
   wire       msi_busy_dmard   ;
   reg        msi_sel_dmard    ;

   // control signal
   wire requester_mrdmwr_cycle_dmard;
   wire descriptor_mrd_cycle_dmard;
   wire init_dmard         ;
   wire [10:0]  sm_dmard   ;
   reg  tx_req_dmard_reg;
   reg  tx_req_dmawr_reg;

   always @ (posedge clk_in or negedge rstn) begin
       if (~rstn) begin
           tx_req_dmard_reg <= 1'b0;
           tx_req_dmawr_reg <= 1'b0;
       end
       else begin
           tx_req_dmard_reg <= tx_req_dmard;
           tx_req_dmawr_reg <= tx_req_dmawr;
       end
   end

   altpcierd_dma_dt  #(
      .DIRECTION       (`DIRECTION_READ  ),
      .RC_64BITS_ADDR  ( RC_64BITS_ADDR  ),
      .MAX_NUMTAG      ( MAX_NUMTAG      ),
      .FIFO_WIDTHU     ( FIFO_WIDTHU     ),
      .FIFO_DEPTH      ( FIFO_DEPTH      ),
      .USE_CREDIT_CTRL ( USE_CREDIT_CTRL ),
      .BOARD_DEMO      ( BOARD_DEMO      ),
      .USE_MSI         ( USE_MSI         ),
      .USE_DMAWRITE    ( USE_DMAWRITE    ),
      .USE_DMAREAD     ( USE_DMAREAD     ),
      .RC_SLAVE_USETAG ( RC_SLAVE_USETAG ),
      .TXCRED_WIDTH    ( TXCRED_WIDTH    ),
      .AVALON_WADDR    ( AVALON_WADDR    ),
      .AVALON_ST_128   ( AVALON_ST_128   ),
      .AVALON_WDATA    ( AVALON_WDATA    ),
      .CDMA_AST_RXWS_LATENCY (CDMA_AST_RXWS_LATENCY)
   )
      dma_read
   (
   .clk_in        (clk_in        ),
   .rstn          (rstn          ),

   .ctl_wr_req    (ctl_wr_req),
   .ctl_wr_data   (ctl_wr_data),
   .ctl_addr      (ctl_addr),

   .rx_req        (rx_req0  ),
   .rx_req_p0     (rx_req_p0),
   .rx_req_p1     (rx_req_p1),
   .rx_ack        (rx_ack_dmard  ),
   .rx_desc       (rx_desc0 ),
   .rx_data       (rx_data0),
   .rx_be         (rx_be0),
   .rx_ws         (rx_ws_dmard   ),
   .rx_dv         (rx_dv0   ),
   .rx_dfr        (rx_dfr0  ),

   .tx_sel_descriptor        (tx_sel_descriptor_dmard  ),
   .tx_busy_descriptor       (tx_busy_descriptor_dmard ),
   .tx_ready_descriptor      (tx_ready_descriptor_dmard),

   .tx_sel_requester        (tx_sel_requester_dmard  ),
   .tx_busy_requester       (tx_busy_requester_dmard ),
   .tx_ready_requester      (tx_ready_requester_dmard),

   .tx_ready_other_dma      (tx_ready_dmawr),

   .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),
   .tx_cred       (tx_cred0_reg      ),
   .tx_have_creds (1'b0),
   .tx_req        (tx_req_dmard  ),
   .tx_ack        (tx_ack0  ),
   .tx_desc       (tx_desc_dmard ),
   .tx_ws         (tx_ws0   ),
   .tx_err        (tx_err_dmard  ),
   .tx_dv         (tx_dv_dmard   ),
   .tx_dfr        (tx_dfr_dmard  ),
   .tx_data       (tx_data_dmard ),

   .cfg_maxpload_dw  (cfg_maxpload_dw),
   .cfg_maxpload     (cfg_maxpload),
   .cfg_maxrdreq_dw  (cfg_maxrdreq_dw),
   .cfg_maxrdreq     (cfg_maxrdreq),
   .cfg_busdev       (cfg_busdev_reg),
   .cfg_link_negociated (cfg_link_negociated),

   .requester_mrdmwr_cycle   (requester_mrdmwr_cycle_dmard),
   .descriptor_mrd_cycle     (descriptor_mrd_cycle_dmard),
   .init                     (init_dmard    ),

   .app_msi_ack   (interrupt_ack_int   ),
   .app_msi_req   (app_msi_req_dmard),
   .app_msi_tc    (app_msi_tc_dmard ),
   .app_msi_num   (app_msi_num_dmard),
   .msi_ready     (msi_ready_dmard  ),
   .msi_busy      (msi_busy_dmard   ),
   .msi_sel       (msi_sel_dmard    ),

   .dma_sm         (sm_dmard),

   .dma_prg_wrdata   (dma_prg_wrdata),
   .dma_prg_addr     (dma_prg_addr),
   .dma_prg_wrena    (dma_rd_prg_wrena),
   .dma_prg_rddata (dma_rd_prg_rddata),

   .dma_status       (read_dma_status),
   .cpl_pending      (cpl_pending_dmard),

   // Avalon Write Master port
   .read_data      (open_read_data   ),
   .write_address  (address_dmard    ),
   .write_wait     (waitrequest_dmard),
   .write          (write_dmard      ),
   .write_data     (writedata_dmard  ),
   .write_byteena  (write_byteena_dmard)
   );

//------------------------------------------------------------
//RC Slave Section
//       - suffix _pcnt
//------------------------------------------------------------
   wire          rx_req_pcnt ;
   wire          rx_ack_pcnt ;
   wire [135:0]  rx_desc_pcnt;
   wire [63:0]   rx_data_pcnt;
   wire          rx_ws_pcnt  ;
   wire          rx_dv_pcnt  ;
   wire          rx_dfr_pcnt ;

   // TX
   wire          tx_req_pcnt  ;
   wire          tx_ack_pcnt  ;
   wire [127:0]  tx_desc_pcnt ;
   wire          tx_ws_pcnt   ;
   wire          tx_err_pcnt  ;
   wire          tx_dv_pcnt   ;
   wire          tx_dfr_pcnt  ;
   wire [127:0]  tx_data_pcnt ;
   reg           tx_sel_pcnt  ;
   wire          tx_busy_pcnt ;
   wire          tx_ready_pcnt;

   wire         tx_dv_dmard_mux  ;
   wire         tx_dfr_dmard_mux ;
   wire         tx_req_dmard_mux ;
   wire         tx_err_dmard_mux ;
   wire [127:0] tx_desc_dmard_mux;
   wire [127:0] tx_data_dmard_mux;


   wire         tx_sel_slave;

   assign          tx_err_pcnt = 1'b0;

   assign tx_sel_slave = tx_sel_pcnt;

   assign tx_dv_dmard_mux  =(tx_sel_slave==1'b0)?tx_dv_dmard:tx_dv_pcnt;
   assign tx_dfr_dmard_mux =(tx_sel_slave==1'b0)?tx_dfr_dmard:tx_dfr_pcnt;
   assign tx_req_dmard_mux =(tx_sel_slave==1'b0)?tx_req_dmard:tx_req_pcnt;
   assign tx_err_dmard_mux =(tx_sel_slave==1'b0)?tx_err_dmard:tx_err_pcnt;
   assign tx_data_dmard_mux=(tx_sel_slave==1'b0)?tx_data_dmard:tx_data_pcnt;
   assign tx_desc_dmard_mux=(tx_sel_slave==1'b0)?tx_desc_dmard:tx_desc_pcnt;


   altpcierd_rc_slave#(
      .AVALON_ST_128    (AVALON_ST_128),
      .AVALON_WDATA     (AVALON_WDATA),
      .AVALON_BYTE_WIDTH  (AVALON_BYTE_WIDTH),
      .AVALON_WADDR   (AVALON_WADDR)
      ) altpcierd_rc_slave(
           .clk_in     (clk_in),
           .rstn       (rstn),
           .cfg_busdev (cfg_busdev_reg),

           .rx_req     (rx_req0),
           .rx_desc    (rx_desc0),
           .rx_data    (rx_data0[AVALON_WDATA-1:0]),
           .rx_be      (rx_be0[AVALON_BYTE_WIDTH-1:0]),
           .rx_dv      (rx_dv0),
           .rx_dfr     (rx_dfr0),
           .rx_ack     (rx_ack_pcnt),
           .rx_ws      (rx_ws_pcnt),

           .tx_ws      (tx_ws0),
           .tx_ack     (tx_ack0),
           .tx_desc    (tx_desc_pcnt),
           .tx_data    (tx_data_pcnt[AVALON_WDATA-1:0]),
           .tx_dfr     (tx_dfr_pcnt),
           .tx_dv      (tx_dv_pcnt),
           .tx_req     (tx_req_pcnt),
           .tx_busy    (tx_busy_pcnt ),
           .tx_ready   (tx_ready_pcnt),
           .tx_sel     (tx_sel_pcnt  ),

           .mem_rd_data_valid (mem_rd_data_valid_del),
           .mem_rd_addr       (addressrd_epmem),
           .mem_rd_data       (mem_rd_data_del),
           .mem_rd_ena        (read_epmem),
           .mem_wr_ena        (write_epmem),
           .mem_wr_addr       (addresswr_epmem),
           .mem_wr_data       (writedata_epmem),
           .mem_wr_be         (write_byteena_epmem),
           .sel_epmem         (sel_epmem),

           .dma_rd_prg_rddata (dma_rd_prg_rddata),
           .dma_wr_prg_rddata (dma_wr_prg_rddata),
           .dma_prg_wrdata    (dma_prg_wrdata),
           .dma_prg_addr      (dma_prg_addr),
           .dma_rd_prg_wrena  (dma_rd_prg_wrena),
           .dma_wr_prg_wrena  (dma_wr_prg_wrena),

           .rx_ecrc_bad_cnt   (rx_ecrc_bad_cnt),
           .read_dma_status   (read_dma_status),
           .write_dma_status  (write_dma_status)
        );


//------------------------------------------------------------
// RX signal controls
//------------------------------------------------------------

   assign rx_ack0  = rx_ack_dmawr|rx_ack_dmard|rx_ack_pcnt;
   assign rx_ws0   = rx_ws_dmawr |rx_ws_dmard |rx_ws_pcnt;

//------------------------------------------------------------
// TX signal controls and data stream mux
//------------------------------------------------------------
   assign tx_dv0   = (tx_sel_dmawr==1'b1)?tx_dv_dmawr  :tx_dv_dmard_mux  ;
   assign tx_dfr0  = (tx_sel_dmawr==1'b1)?tx_dfr_dmawr :tx_dfr_dmard_mux ;
   assign tx_data0 = (tx_sel_dmawr==1'b1)?tx_data_dmawr:tx_data_dmard_mux;
   assign tx_req0  = (tx_sel_dmawr==1'b1)?tx_req_dmawr :tx_req_dmard_mux ;
   assign tx_err0  = (tx_sel_dmawr==1'b1)?tx_err_dmawr :tx_err_dmard_mux ;
   assign tx_desc0[127]     = `RESERVED_1BIT;
   // TLP_FMT
   assign tx_desc0[126:125] = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[126:125]:
                                               tx_desc_dmard_mux[126:125];
   // TLP_TYPE
   assign tx_desc0[124:120] = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[124:120]:
                                               tx_desc_dmard_mux[124:120];
   assign tx_desc0[119]     = `RESERVED_1BIT   ;
   assign tx_desc0[118:116] = `TLP_TC_DEFAULT  ;
   assign tx_desc0[115:112] = `RESERVED_4BIT   ;
   assign tx_desc0[111]     = `TLP_TD_DEFAULT  ;
   assign tx_desc0[110]     = `TLP_EP_DEFAULT  ;
   assign tx_desc0[109:108] = `TLP_ATTR_DEFAULT;
   assign tx_desc0[107:106] = `RESERVED_2BIT   ;

   // length
   assign tx_desc0[105:96]   = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[105:96]:
                                                 tx_desc_dmard_mux[105:96];
   // requester id
   assign tx_desc0[95:83]   = cfg_busdev_reg;
   assign tx_desc0[82:80 ]   = `TRANSACTION_ID;

   // tag
   assign tx_desc0[79:72]   = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[79:72]:
                                                 tx_desc_dmard_mux[79:72];
   // byte enable
   assign tx_desc0[71:64]   = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[71:64]:
                                                 tx_desc_dmard_mux[71:64];
   // address
   assign tx_desc0[63:0]    = (tx_sel_dmawr==1'b1)?tx_desc_dmawr[63:0]:
                                                 tx_desc_dmard_mux[63:0];

//------------------------------------------------------------
// Arbitration of TX- RX Stream
//------------------------------------------------------------

   wire dma_tx_idle;
   wire dma_tx_idle_p0_tx_sel;
   wire write_priority_over_read;
   wire tx_sel_descriptor_dmawr_p0;
   wire tx_sel_descriptor_dmard_p0;
   wire tx_sel_requester_dmawr_p0;
   wire tx_sel_requester_dmard_p0;
   wire tx_sel_pcnt_p0;
   reg tx_sel_reg_descriptor_dmawr;
   reg tx_sel_reg_descriptor_dmard;
   reg tx_sel_reg_requester_dmawr;
   reg tx_sel_reg_requester_dmard;
   reg tx_sel_reg_pcnt;

   reg rx_ecrc_failure;

   assign write_priority_over_read = (DMA_WRITE_PRIORITY>DMA_READ_PRIORITY)?
                                                                      1'b1:1'b0;

   assign tx_ready_dmawr = ((write_priority_over_read==1'b1)&&
                            ((tx_rdy_descriptor_dmawr==1'b1)||
                             (tx_rdy_requester_dmawr==1'b1)  ))?1'b1:1'b0;

   assign tx_sel_dmard   = ((tx_sel_descriptor_dmard==1'b1)||
                            (tx_sel_requester_dmard==1'b1))?1'b1:1'b0;

   assign tx_stop_dma_write = ((tx_mask_reg==1'b1)||
                                (tx_stream_ready0_reg==1'b0))?1'b1:1'b0;

   assign tx_ready_dmard    = ((tx_stop_dma_write==1'b1)||
                               ((write_priority_over_read==1'b0)    &&
                                ((tx_rdy_descriptor_dmard==1'b1)||
                               (tx_rdy_requester_dmard==1'b1)  ) ))?1'b1:1'b0;

   assign tx_rdy_descriptor_dmawr= (TL_SELECTION==0)?tx_ready_descriptor_dmawr_r:tx_ready_descriptor_dmawr ;
   assign tx_rdy_requester_dmawr = (TL_SELECTION==0)?tx_ready_requester_dmawr_r :tx_ready_requester_dmawr  ;
   assign tx_rdy_descriptor_dmard= (TL_SELECTION==0)?tx_ready_descriptor_dmard_r:tx_ready_descriptor_dmard ;
   assign tx_rdy_requester_dmard = (TL_SELECTION==0)?tx_ready_requester_dmard_r :tx_ready_requester_dmard  ;

   always @ (posedge clk_in) begin
      tx_sel_reg_descriptor_dmawr <= tx_sel_descriptor_dmawr;
      tx_sel_reg_descriptor_dmard <= tx_sel_descriptor_dmard;
      tx_sel_reg_requester_dmawr  <= tx_sel_requester_dmawr;
      tx_sel_reg_requester_dmard  <= tx_sel_requester_dmard;
      tx_sel_reg_pcnt             <= tx_sel_pcnt;
      tx_ready_descriptor_dmawr_r <= tx_ready_descriptor_dmawr ;
      tx_ready_requester_dmawr_r  <= tx_ready_requester_dmawr  ;
      tx_ready_descriptor_dmard_r <= tx_ready_descriptor_dmard ;
      tx_ready_requester_dmard_r  <= tx_ready_requester_dmard  ;
   end

   assign tx_sel_descriptor_dmawr_p0 = tx_sel_descriptor_dmawr &
                                           ~tx_sel_reg_descriptor_dmawr;
   assign tx_sel_descriptor_dmard_p0 = tx_sel_descriptor_dmard &
                                           ~tx_sel_reg_descriptor_dmard;
   assign tx_sel_requester_dmawr_p0  = tx_sel_requester_dmawr &
                                           ~tx_sel_reg_requester_dmawr;
   assign tx_sel_requester_dmard_p0  = tx_sel_requester_dmard &
                                           ~tx_sel_reg_requester_dmard;
   assign tx_sel_pcnt_p0             = tx_sel_pcnt & ~tx_sel_reg_pcnt;

   assign dma_tx_idle_p0_tx_sel = ((tx_sel_pcnt_p0==1'b0)             &&
                                   (tx_sel_descriptor_dmawr_p0==1'b0) &&
                                   (tx_sel_requester_dmawr_p0==1'b0)  &&
                                   (tx_sel_descriptor_dmard_p0==1'b0) &&
                                  (tx_sel_requester_dmard_p0==1'b0)) ? 1'b1:1'b0;

   assign dma_tx_idle = ((tx_busy_pcnt==1'b0)             &&
                         (tx_busy_descriptor_dmawr==1'b0) &&
                         (tx_busy_requester_dmawr==1'b0)  &&
                         (tx_busy_descriptor_dmard==1'b0) &&
                         (tx_busy_requester_dmard==1'b0)            ) ? 1'b1:1'b0;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
         rx_ecrc_failure <= 1'b0;
      else if (rx_ecrc_bad_cnt>0)
         rx_ecrc_failure <= 1'b1;
   end

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         tx_sel_descriptor_dmawr <= 1'b0;
         tx_sel_requester_dmawr  <= 1'b0;
         tx_sel_dmawr            <= 1'b0;
         tx_sel_descriptor_dmard <= 1'b0;
         tx_sel_requester_dmard  <= 1'b0;
         tx_sel_pcnt             <= 1'b0;
      end
      else begin
         if (pci_bus_master_enable==1'b0) begin
            tx_sel_descriptor_dmawr <= 1'b0;
            tx_sel_requester_dmawr  <= 1'b0;
            tx_sel_dmawr            <= 1'b0;
            tx_sel_descriptor_dmard <= 1'b0;
            tx_sel_requester_dmard  <= 1'b0;
            tx_sel_pcnt             <= 1'b1;
         end
         else if ((dma_tx_idle==1'b1)&&
                  (dma_tx_idle_p0_tx_sel==1'b1) ) begin
            if (DMA_WRITE_PRIORITY>DMA_READ_PRIORITY) begin
               if ((tx_mask_reg==1'b1)||
                     (tx_stream_ready0_reg==1'b0)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_descriptor_dmawr==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b1;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b1;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_descriptor_dmard==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b1;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if (tx_rdy_requester_dmawr==1'b1) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b1;
                     tx_sel_dmawr            <= 1'b1;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_requester_dmard==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b1;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if (tx_ready_pcnt==1'b1) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b1;
               end
               else begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
            end
            else begin
               if ((tx_mask_reg==1'b1)||
                     (tx_stream_ready0_reg==1'b0)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_descriptor_dmard==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b1;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_descriptor_dmawr==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b1;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b1;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if ((tx_rdy_requester_dmard==1'b1)&&(cpld_rx_buffer_ready==1'b1)) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b1;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if (tx_rdy_requester_dmawr==1'b1) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b1;
                     tx_sel_dmawr            <= 1'b1;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
               else if (tx_ready_pcnt==1'b1) begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b1;
               end
               else begin
                     tx_sel_descriptor_dmawr <= 1'b0;
                     tx_sel_requester_dmawr  <= 1'b0;
                     tx_sel_dmawr            <= 1'b0;
                     tx_sel_descriptor_dmard <= 1'b0;
                     tx_sel_requester_dmard  <= 1'b0;
                     tx_sel_pcnt             <= 1'b0;
               end
            end
         end
      end
   end


//------------------------------------------------------------
// Arbitration of MSI Stream
//------------------------------------------------------------

// MSI Generation
reg app_msi_req_reg;
reg [4:0] app_msi_num_reg;
reg [2:0] app_msi_tc_reg;

   // MSI Generation
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0)
        app_msi_req_reg <= 1'b0;
      else if (msi_enable==1'b1) begin
          if (app_msi_ack == 1'b1)
            app_msi_req_reg <= 1'b0;
          else if (msi_sel_dmawr==1'b1)
            app_msi_req_reg <= app_msi_req_dmawr;
          else
            app_msi_req_reg <= app_msi_req_dmard;
      end
   end

   always @ (posedge clk_in) begin
      if (msi_sel_dmawr==1'b1)
         app_msi_num_reg <= app_msi_num_dmawr;
      else
         app_msi_num_reg <= app_msi_num_dmard;
   end

   always @ (posedge clk_in) begin
      if (msi_sel_dmawr==1'b1)
         app_msi_tc_reg <= app_msi_tc_dmawr;
      else
         app_msi_tc_reg <= app_msi_tc_dmard;
   end

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
        msi_sel_dmawr <= 1'b0;
        msi_sel_dmard <= 1'b0;
      end
      else if ({msi_busy_dmard,msi_busy_dmawr}==2'b00)
         if (msi_ready_dmawr == 1'b1) begin
           msi_sel_dmawr <= 1'b1;
           msi_sel_dmard <= 1'b0;
         end
      else if (msi_ready_dmard == 1'b1) begin
         msi_sel_dmawr <= 1'b0;
         msi_sel_dmard <= 1'b1;
      end
      else begin
         msi_sel_dmawr <= 1'b1;
         msi_sel_dmard <= 1'b0;
      end
   end

   //--------------------------------------------------------------
   // Interrupt/MSI IO signalling
   // Route arbitrated interrupt request to MSI if msi is enabled,
   // or to Legacy app_int_sts otherwise.
   //--------------------------------------------------------------

   assign msi_enable = cfg_msicsr_reg[0];

   // MSI REQUEST
   assign app_msi_req = (USE_MSI==0)?0:app_msi_req_reg;
   assign app_msi_num = (USE_MSI==0)?0:app_msi_num_reg;
   assign app_msi_tc  = (USE_MSI==0)?0:app_msi_tc_reg;

   // LEGACY INT REQUEST
   assign app_int_sts = (USE_MSI==0)?0:app_int_req;

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
          app_int_req      <= 1'b0;
          app_int_ack_reg  <= 1'b0;
          int_deassert     <= 1'b0;
      end
      else begin
          app_int_ack_reg <= app_int_ack;                                     // input boundary reg
          int_deassert    <= app_int_ack_reg ? ~int_deassert : int_deassert;  // track whether core is sending interrupt ASSERTION message or DEASSERTION message.

          if (app_int_ack_reg)                                                // deassert request when Interrupt ASSERTION is ack-ed
              app_int_req  <= 1'b0;
          else if ((~msi_enable & ~int_deassert) &
                    (((msi_sel_dmawr == 1'b1) &  (app_msi_req_dmawr == 1'b1)) |
                    ((msi_sel_dmawr == 1'b0) &  (app_msi_req_dmard == 1'b1)) ) ) begin  // assert if there is a request, and not waiting for the DEASSERTION ack for this request
                  app_int_req  <= 1'b1;
          end
          else
              app_int_req  <= app_int_req;
      end
   end


   // MSI & LEGACY ACKNOWLEDGE - sent to the internal interrupt requestor

   assign interrupt_ack_int = (app_msi_ack &  msi_enable) |                     // Ack from MSI
                              (app_int_ack_reg & ~int_deassert & ~msi_enable);   // INT ASSERT Message Ack from Legacy



//------------------------------------------------------------
// Registering module for static side band signals
//------------------------------------------------------------
   // cpl section
   reg [23:0] cpl_cnt_50ms;
   wire tx_mrd; // Set to 1 when MRd on TX
   wire [6:0] tx_desc_fmt_type;
   reg cpl_err0_r;

   assign tx_desc_fmt_type = tx_desc0[126:120];
   assign tx_mrd           = ((tx_ack0==1'b1)&&(tx_desc_fmt_type[4:0]==5'b00000)&&(tx_desc_fmt_type[6]==1'b0))?1'b1:1'b0;

   always @ (negedge rstn or posedge clk_in) begin : p_cpl_50ms
      if (rstn==1'b0) begin
         cpl_cnt_50ms <= 24'h0;
         cpl_pending  <= 1'b0;
         cpl_err0_r   <=1'b0;
      end
      else begin
         cpl_pending  <= cpl_pending_dmawr|cpl_pending_dmard;
         cpl_err0_r   <= (cpl_cnt_50ms==CNT_50MS)?1'b1:1'b0;
         if ((cpl_pending==1'b0)||(tx_mrd==1'b1))
         begin
            cpl_cnt_50ms <= 24'h0;
         end
         else if (cpl_cnt_50ms<CNT_50MS) begin
            cpl_cnt_50ms <= cpl_cnt_50ms+24'h1;
         end
      end
   end

   assign cpl_err[0]   = 1'b0; //cpl_err0_r;
   assign cpl_err[6:1] = 6'h0;
   assign err_desc     = 128'h0;

endmodule
