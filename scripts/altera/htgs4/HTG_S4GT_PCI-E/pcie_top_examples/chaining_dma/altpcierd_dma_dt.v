// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the chaining DMA design example. It arbitrates PCI Express packets issued
//  * by the submodules the modules altpcierd_dma_prg_reg, altpcierd_read_dma_requester,
//  * altpcierd_write_dma_requester and altpcierd_dma_descriptor.
//  */
// synthesis translate_off
`timescale 1ns / 1ps
`include "altpcierd_dma_dt_cst_sim.v"
// synthesis translate_on

// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings
// altera message_level Level1
// altera message_off 10034 10035 10036 10037 10230 10240 10030
//-----------------------------------------------------------------------------
// Title         : DMA Module using descriptor table for PCIe backend
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_dma_dt.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Abbreviation :
//
//   EP      : End Point
//   RC      : Root complex
//   DT      : Descriptor Table
//   MWr     : Memory write
//   MRd     : Memory read
//   CPLD    : Completion with data
//   MSI     : PCIe Message Signaled Interrupt
//   BDT     : Base address of the descriptor header table in RC memory
//   BDT_LSB : Base address of the descriptor header table in RC memory
//   BDT_MSB : Base address of the descriptor header table in RC memory
//   BRC     : [BDT_MSB:BDT_LSB]
//   DW0     : First DWORD of the descriptor table header
//   DW1     : Second DWORD of the descriptor table header
//   DW2     : Third DWORD of the descriptor table header
//   RCLAST  : RC MWr RCLAST in EP memeory to reflects the number
//             of DMA transfers ready to start
//   EPLAST  : EP MWr EPLAST in shared memeory to reflects the number
//             of completed DMA transfers
//
//-----------------------------------------------------------------------------
//  Suffix   :
//
//   tx      : PCIe Transmit signals
//   rx      : PCIe Receive signals
//   dt      : descriptor table
//
//-----------------------------------------------------------------------------
//  Overview  chaining DMA operation:
//
//   The chaining DMA consist of a DMA Write and a DMA Read sub-module
//   Each DMA use a separate descriptor table mapped in the share memeory
//   The descriptor table contains a header with 3 DWORDs (DW0, DW1, DW2)
//
//       |31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16|15 .................0
//   ----|---------------------------------------------------------------------
//       | R|        |         |              |  | E|M| D |
//   DW0 | E| MSI    |         |              |  | P|S| I |
//       | S|TRAFFIC |         |              |  | L|I| R |
//       | E|CLASS   | RESERVED|  MSI         |1 | A| | E |      SIZE:Number
//       | R|        |         |  NUMBER      |  | S| | C |   of DMA descriptor
//       | V|        |         |              |  | T| | T |
//       | E|        |         |              |  |  | | I |
//       | D|        |         |              |  |  | | O |
//       |  |        |         |              |  |  | | N |
//   ----|---------------------------------------------------------------------
//   DW1 |                     BDT_MSB
//   ----|---------------------------------------------------------------------
//   DW2 |                   DT_LSB
//   ----|---------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
// Module Description :
//
// This is the section of descriptor table (dt) based DMA
// This assume that the root complex (rc) writes the descriptor table
//
// altpcierd_dma_dt consists of 3 modules :
//
//  - altpcierd_dma_prg_reg    : Application (RC) program the DMA
//                             RC issues 4 MWr : DW0, DW1, DW2, RCLAST
//
//  - altpcierd_dma_descriptor : EP DMA retrieve descriptor table into FIFO
//
//  - altpcierd_write_dma_requester/altpcierd_read_dma_requester : The EP DMA
//          retrieve descriptor info from FIFO and run DMA
//
// altpcierd_dma_prg_reg : is re-used for the read DMA and the write DMA.
//                       the static parameter DIRECTION differentiates the
//                       two modes: RC issues 4 Mwr32 at BAR 2 or 3 at
//                       EP ADDR :
//                       |----------------------------------------------
//                       | DMA Write (direction = "write")
//                       |----------------------------------------------
//                       | 0h     | DW0
//                       |--------|-------------------------------------
//                       | 04h    | DW1
//                       |--------|-------------------------------------
//                       | 08h    | DW2
//                       |--------|-------------------------------------
//                       | 0ch    | RCLast
//                       |        | RC MWr RCLast : Available DMA number
//                       |----------------------------------------------
//                       | DMA Read  (direction = "read")
//                       |----------------------------------------------
//                       |10h     | DW0
//                       |--------|-------------------------------------
//                       |14h     | DW1
//                       |--------|-------------------------------------
//                       |18h     | DW2
//                       |--------|-------------------------------------
//                       |1ch     | RCLast
//                       |        | RC MWr RCLast : Available DMA number
//
//
// altpcierd_dma_descriptor: is re-used for the read DMA and the write DMA.
//                       the static parameter DIRECTION differentiates the
//                       two modes for tag management such as when EP issues
//                       MRd
//                       TAG 8'h00            : Descriptor read
//                       TAG 8'h01            : Descriptor write
//                       TAG 8'h02 -> MAX TAG : Requester read
//
// altpcierd_write_dma_requester : DMA Write transfer on a given descriptor
//
// altpcierd_read_dma_requester : DMA Read transfer on a given descriptor
//
//-----------------------------------------------------------------------------
//
// altpcierd_dma_dt Parameters
//
//  DIRECTION       :  "Write" or "Read"
//  MAX_NUMTAG      :  Number of TAG available
//  FIFO_WIDTH      :  Descriptor FIFO width
//  FIFO_DEPTH      :  Descriptor FIFO depth
//  TXCRED_WIDTH    :  tx_dredit bus width
//  RC_SLAVE_USETAG :  Number of TAG used by RC Slave module
//  MAX_PAYLOAD     :  MAX Write payload
//  AVALON_WADDR    :  Avalon buffer address width
//  AVALON_WDATA    :  Avalon buffer data width
//  BOARD_DEMO      :  Specify which board is being used
//  USE_MSI         :  When set add MSI state machine
//  USE_CREDIT_CTRL :  When set check credit prior to MRd/MWr
//  RC_64BITS_ADDR  :  When set use 64 bits RC address
//  DISPLAY_SM      :  When set set bring State machine register to RC Slave
//
//-----------------------------------------------------------------------------
// Copyright (c) 2009 Altera Corporation. All rights reserved.  Altera products are
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


module altpcierd_dma_dt #(
   parameter DIRECTION       =`DIRECTION_WRITE,
   parameter MAX_NUMTAG      =32,
   parameter FIFO_WIDTHU     =8,
   parameter FIFO_DEPTH      =256,
   parameter TXCRED_WIDTH    =36,
   parameter RC_SLAVE_USETAG =0,
   parameter USE_DMAWRITE          = 1,
   parameter USE_DMAREAD           = 1,
   parameter MAX_PAYLOAD     =256,
   parameter AVALON_WADDR    =12,
   parameter AVALON_WDATA    =64,
   parameter AVALON_ST_128   = 0,
   parameter BOARD_DEMO      =0,
   parameter INTENDED_DEVICE_FAMILY = "Cyclone IV GX",
   parameter USE_MSI         =1,
   parameter USE_CREDIT_CTRL =1,
   parameter RC_64BITS_ADDR  =0,
   parameter TL_SELECTION    =0,
   parameter DISPLAY_SM      =1 ,
   parameter DT_EP_ADDR_SPEC = 0,    // Descriptor Table's EP Address is specified as:  3=QW Address,  2=DW Address, 1= W Address, 0= Byte Addr.
   parameter AVALON_BYTE_WIDTH = AVALON_WDATA/8,   // for epmem byte enables
   parameter CDMA_AST_RXWS_LATENCY = 2
   )(
   input clk_in,
   input rstn ,

   input              ctl_wr_req,
   input[31:0]        ctl_wr_data,
   input[2:0]         ctl_addr,

   // PCIe backend Receive section
   input              rx_req   ,
   input              rx_req_p0,
   input              rx_req_p1,
   output             rx_ack   ,
   output             rx_ws    ,
   input[135:0]       rx_desc  ,
   input[127:0]       rx_data  ,
   input[15:0]        rx_be,
   input              rx_dv    ,
   input              rx_dfr   ,
   input [15:0]       rx_buffer_cpl_max_dw,

   // PCIe backend Transmit section
   output             tx_req   ,
   input              tx_ack   ,
   output [127:0]     tx_desc  ,
   input              tx_ws    ,
   output             tx_err   ,
   output             tx_dv    ,
   output             tx_dfr   ,
   output [127:0]     tx_data  ,

   // Used for arbitration with the other DMA

   input  tx_sel_descriptor,
   output tx_busy_descriptor,
   output tx_ready_descriptor,

   input  tx_sel_requester,
   output tx_busy_requester,
   output tx_ready_requester,

   output  cpl_pending,

   input  tx_ready_other_dma,

   input [TXCRED_WIDTH-1:0]  tx_cred,
   input  tx_have_creds,

   // MSI   signals
   input       app_msi_ack,
   output      app_msi_req,
   output[2:0] app_msi_tc ,
   output[4:0] app_msi_num,
   input       msi_sel   ,
   output      msi_ready ,
   output      msi_busy  ,

   // control signals
   input [2:0]  cfg_maxpload ,
   input [2:0]  cfg_maxrdreq ,
   input [15:0] cfg_maxpload_dw,
   input [15:0] cfg_maxrdreq_dw,  // max lenght of PCIe read in DWORDS
   input [12:0] cfg_busdev   ,
   input [4:0]  cfg_link_negociated   ,

   // Avalon EP memory signals
   output [AVALON_WDATA-1:0] write_data    ,
   output [AVALON_WADDR-1:0] write_address ,
   output                    write         ,
   output                    write_wait    ,
   output [AVALON_BYTE_WIDTH-1:0] write_byteena,

   input  [AVALON_WDATA-1:0] read_data    ,
   output [AVALON_WADDR-1:0] read_address ,
   output                    read         ,
   output                    read_wait    ,

   input [31:0]  dma_prg_wrdata,
   input [3:0]   dma_prg_addr,
   input         dma_prg_wrena,
   output [31:0] dma_prg_rddata,

   // RC Slave control signals
   output [10:0]     dma_sm,
   output descriptor_mrd_cycle   ,
   output requester_mrdmwr_cycle ,
   output [63:0]     dma_status,

   output init

   );

   localparam MAX_NUMTAG_LIMIT=MAX_NUMTAG;
   localparam FIFO_WIDTH =(AVALON_ST_128==1)?128:64;

//////////////////////////////////////////////////////////////////////////////
// DMA Program Register specific signals  (module altpcierd_dma_prg_reg)
//
// specify the # of the last descripor upadted by RC host/application
wire [15:0]     dt_rc_last    ;
wire            dt_rc_last_sync;
wire            dt_3dw_rcadd;

//// specify the size of the descripor table in RC memeory (how many descriptors)
wire [15:0]     dt_size       ;
//// Base address of the descriptor table
wire [63:0]     dt_base_rc    ;
wire            dt_eplast_ena ;
wire            dt_msi        ;
wire            ep_last_sent_to_rc;
wire            dt_fifo_empty;

// Descriptor control signals
wire tx_req_descriptor;
wire [127:0] tx_desc_descriptor;

// Requester control signals
wire tx_req_requester;
wire [127:0] tx_desc_requester;

// Rx signals from the 3 modules
wire rx_ack_dma_prg   ;
wire rx_ack_descriptor;
wire rx_ack_requester ;
wire rx_ws_requester  ;



assign rx_ack        = rx_ack_descriptor | rx_ack_requester;

wire                   dt_fifo_rdreq;
wire [FIFO_WIDTH-1:0]  dt_fifo_q;
wire[12:0]             dt_fifo_q_4K_bound;

// rx ctrl outputs
assign tx_err   = 0;
assign rx_ws    = rx_ws_requester;

// Debug output

wire [6:0]  dma_sm_req ;  // read   wire [3:0]  dma_sm_tx_rd;
                          //        wire [2:0]  dma_sm_rx_rd; // read
                          // read   wire [3:0]
wire [3:0]  dma_sm_desc;

//cpl_pending
wire cpl_pending_descriptor;
wire cpl_pending_requestor;

assign cpl_pending = cpl_pending_descriptor | cpl_pending_requestor;

//////////////////////////////////////////////////////////////////////////////
//
// TX Arbitration between descriptor and requester modules
// tx_busy  : when 1; the module is driving tx_req, tx_desc, tx_data
// tx_ready : when 1; the module is ready to drive tx_req, tx_desc, tx_data
// tx_sel   : when 1; enable the module state to drive tx_req, tx_desc, tx_data
assign tx_req =(tx_sel_descriptor==1'b1)?tx_req_descriptor:tx_req_requester;
assign tx_desc=(tx_sel_descriptor==1'b1)?tx_desc_descriptor:tx_desc_requester;

// RC program EP DT issuing mwr (32 bits)
   altpcierd_dma_prg_reg  #(
   .RC_64BITS_ADDR(RC_64BITS_ADDR),
   .AVALON_ST_128(AVALON_ST_128)
   ) dma_prg (
   .dma_prg_wrena   (dma_prg_wrena        ),
   .dma_prg_wrdata  (dma_prg_wrdata),
   .dma_prg_addr    (dma_prg_addr       ),
   .dma_prg_rddata  (dma_prg_rddata ),

   .dt_rc_last      (dt_rc_last    ),
   .dt_rc_last_sync (dt_rc_last_sync),
   .dt_size         (dt_size       ),
   .dt_base_rc      (dt_base_rc    ),
   .dt_eplast_ena   (dt_eplast_ena ),
   .dt_msi          (dt_msi        ),
   .dt_3dw_rcadd    (dt_3dw_rcadd  ),
   .app_msi_tc      (app_msi_tc   ),
   .app_msi_num     (app_msi_num  ),

   .init            (init),

   .clk_in        (clk_in        ),
   .rstn          (rstn          )
   );

// EP retrieve descriptor from RC
// if direction write
// tag : 0--> MAX_NUMTAG=1, MAX_NUMTAG-1=1, [TAG used for DMA]
// if direction read
// tag : 0--> MAX_NUMTAG=0, MAX_NUMTAG-1=1, [TAG used for DMA]
   altpcierd_dma_descriptor #(
   .RC_64BITS_ADDR(RC_64BITS_ADDR),
   .MAX_NUMTAG (MAX_NUMTAG_LIMIT),
   .DIRECTION   (DIRECTION)  ,
   .USE_CREDIT_CTRL (USE_CREDIT_CTRL),
   .TXCRED_WIDTH  (TXCRED_WIDTH),
   .FIFO_DEPTH  (FIFO_DEPTH ),
   .FIFO_WIDTHU (FIFO_WIDTHU),
   .AVALON_ST_128(AVALON_ST_128),
   .FIFO_WIDTH  (FIFO_WIDTH ),
   .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
   .CDMA_AST_RXWS_LATENCY(CDMA_AST_RXWS_LATENCY)
   )
   descriptor
   (
   .init            (((DIRECTION==`DIRECTION_WRITE)&&(USE_DMAWRITE==0))?1'b1:((DIRECTION==`DIRECTION_READ)&&(USE_DMAREAD==0))?1'b1:init),
   .dt_rc_last      (dt_rc_last     ),
   .dt_rc_last_sync (dt_rc_last_sync),
   .dt_base_rc      (dt_base_rc     ),
   .dt_size         (dt_size        ),

   .dt_fifo_rdreq (dt_fifo_rdreq    ),
   .dt_fifo_empty (dt_fifo_empty    ),
   .dt_fifo_q     (dt_fifo_q        ),
   .dt_3dw_rcadd  (dt_3dw_rcadd     ),
   .dt_fifo_q_4K_bound (dt_fifo_q_4K_bound),

   // PCIe config info
   .cfg_maxrdreq_dw  (cfg_maxrdreq_dw),

   // PCIe backend Transmit section
   .tx_ready    (tx_ready_descriptor),
   .tx_sel      (tx_sel_descriptor  ),
   .tx_busy     (tx_busy_descriptor ),
   .tx_cred     (tx_cred            ),
   .tx_have_creds (tx_have_creds),
   .tx_req      (tx_req_descriptor  ),
   .tx_ack      (tx_ack             ),
   .tx_desc     (tx_desc_descriptor ),
   .tx_ws       (tx_ws              ),
   .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),

   // PCIe backend Receive section
   .rx_req              (rx_req                ),
   .rx_ack              (rx_ack_descriptor     ),
   .rx_desc             (rx_desc               ),
   .rx_data             (rx_data               ),
   .rx_dv               (rx_dv                 ),
   .rx_dfr              (rx_dfr                ),
   .dma_sm              (dma_sm_desc           ),
   .cpl_pending         (cpl_pending_descriptor),
   .descriptor_mrd_cycle(descriptor_mrd_cycle  ),
   .clk_in              (clk_in                ),
   .rstn                (rstn                  )
   );

// Instanciation of DMA Requestor (Read or Write)
generate
   begin
   if ((DIRECTION == `DIRECTION_WRITE) && (AVALON_ST_128==0)) begin
         // altpcierd_write_dma_requester
         // Transfer data from EP memory to RC memory
         altpcierd_write_dma_requester #(
            .RC_64BITS_ADDR (RC_64BITS_ADDR),
            .FIFO_WIDTH     (FIFO_WIDTH),
            .USE_CREDIT_CTRL(USE_CREDIT_CTRL),
            .TXCRED_WIDTH   (TXCRED_WIDTH),
            .USE_MSI        (USE_MSI),
            .BOARD_DEMO     (BOARD_DEMO),
            .MAX_NUMTAG     (MAX_NUMTAG_LIMIT),
            .TL_SELECTION   (TL_SELECTION),
            .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
            .MAX_PAYLOAD    (MAX_PAYLOAD),
            .AVALON_WADDR   (AVALON_WADDR),
            .AVALON_WDATA   (AVALON_WDATA),
            .DT_EP_ADDR_SPEC (DT_EP_ADDR_SPEC)
            )
            write_requester
            (
            .dt_fifo_rdreq (dt_fifo_rdreq),
            .dt_fifo_empty (dt_fifo_empty),
            .dt_fifo_q     (dt_fifo_q    ),

            // PCIe config info
            .cfg_maxpload_dw  (cfg_maxpload_dw),
            .cfg_maxpload     (cfg_maxpload),
            .cfg_link_negociated  (cfg_link_negociated     ),

            // DMA Prg signals register
            .dt_base_rc    (dt_base_rc   ),
            .dt_3dw_rcadd  (dt_3dw_rcadd ),
            .dt_eplast_ena (dt_eplast_ena),
            .dt_msi        (dt_msi       ),
            .dt_size       (dt_size      ),
            .dt_fifo_q_4K_bound (dt_fifo_q_4K_bound),

            // PCIe backend Transmit section
            .tx_ready      (tx_ready_requester),
            .tx_sel        (tx_sel_requester  ),
            .tx_busy       (tx_busy_requester ),
            .tx_ready_dmard(tx_ready_other_dma),
            .tx_cred       (tx_cred           ),
            .tx_req        (tx_req_requester  ),
            .tx_ack        (tx_ack            ),
            .tx_desc       (tx_desc_requester ),
            .tx_data       (tx_data[63:0]     ),
            .tx_dfr        (tx_dfr            ),
            .tx_dv         (tx_dv             ),
            .tx_ws         (tx_ws             ),


            //MSI
            .app_msi_ack   (app_msi_ack  ),
            .app_msi_req   (app_msi_req  ),
            .msi_sel       (msi_sel      ),
            .msi_ready     (msi_ready    ),
            .msi_busy      (msi_busy     ),

            // Avalon back end
            .address       (read_address ),
            .waitrequest   (read_wait    ),
            .read          (read         ),
            .readdata      (read_data    ),

            .dma_sm        (dma_sm_req[3:0]),
            .descriptor_mrd_cycle   (descriptor_mrd_cycle),
            .requester_mrdmwr_cycle (requester_mrdmwr_cycle),

            .dma_status    (dma_status),

            .init          ((USE_DMAWRITE==0)?1'b1:init         ),
            .clk_in        (clk_in       ),
            .rstn          ((USE_DMAWRITE==0)?1'b0:rstn         )
            );
         assign  tx_data[127:64]       = 0;
         assign  write                 = 1'b0;
         assign  write_wait            = 1'b0;
         assign  rx_ack_requester      = 1'b0;
         assign  rx_ws_requester       = 1'b0;
         assign  dma_sm_req[6:4]       = 0;
         assign  write_byteena         = 8'h0;
         assign  cpl_pending_requestor = 1'b0;

      end
      else if ((DIRECTION == `DIRECTION_WRITE) && (AVALON_ST_128==1)) begin
         // altpcierd_write_dma_requester
         // Transfer data from EP memory to RC memory
         altpcierd_write_dma_requester_128 #(
            .RC_64BITS_ADDR (RC_64BITS_ADDR),
            .FIFO_WIDTH     (FIFO_WIDTH),
            .USE_CREDIT_CTRL(USE_CREDIT_CTRL),
            .TXCRED_WIDTH   (TXCRED_WIDTH),
            .USE_MSI        (USE_MSI),
            .BOARD_DEMO     (BOARD_DEMO),
            .MAX_NUMTAG     (MAX_NUMTAG_LIMIT),
            .TL_SELECTION   (TL_SELECTION),
            .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
            .MAX_PAYLOAD    (MAX_PAYLOAD),
            .AVALON_WADDR   (AVALON_WADDR),
            .AVALON_WDATA   (AVALON_WDATA),
            .DT_EP_ADDR_SPEC (DT_EP_ADDR_SPEC)
            )
            write_requester_128
            (
            .dt_fifo_rdreq (dt_fifo_rdreq),
            .dt_fifo_empty (dt_fifo_empty),
            .dt_fifo_q     (dt_fifo_q    ),

            // PCIe config info
            .cfg_maxpload_dw  (cfg_maxpload_dw),
            .cfg_maxpload     (cfg_maxpload),
            .cfg_link_negociated  (cfg_link_negociated     ),

            // DMA Prg signals register
            .dt_base_rc    (dt_base_rc   ),
            .dt_3dw_rcadd  (dt_3dw_rcadd ),
            .dt_eplast_ena (dt_eplast_ena),
            .dt_msi        (dt_msi       ),
            .dt_size       (dt_size      ),
            .dt_fifo_q_4K_bound (dt_fifo_q_4K_bound),

            // PCIe backend Transmit section
            .tx_ready      (tx_ready_requester),
            .tx_sel        (tx_sel_requester  ),
            .tx_busy       (tx_busy_requester ),
            .tx_ready_dmard(tx_ready_other_dma),
            .tx_cred       (tx_cred           ),
            .tx_req        (tx_req_requester  ),
            .tx_ack        (tx_ack            ),
            .tx_desc       (tx_desc_requester ),
            .tx_data       (tx_data[127:0]    ),
            .tx_dfr        (tx_dfr            ),
            .tx_dv         (tx_dv             ),
            .tx_ws         (tx_ws             ),


            //MSI
            .app_msi_ack   (app_msi_ack  ),
            .app_msi_req   (app_msi_req  ),
            .msi_sel       (msi_sel      ),
            .msi_ready     (msi_ready    ),
            .msi_busy      (msi_busy     ),

            // Avalon back end
            .address       (read_address ),
            .waitrequest   (read_wait    ),
            .read          (read         ),
            .readdata      (read_data    ),

            .dma_sm        (dma_sm_req[3:0]),
            .descriptor_mrd_cycle   (descriptor_mrd_cycle),
            .requester_mrdmwr_cycle (requester_mrdmwr_cycle),

            .dma_status    (dma_status),


            .init          ((USE_DMAWRITE==0)?1'b1:init),
            .clk_in        (clk_in       ),
            .rstn          ((USE_DMAWRITE==0)?1'b0:rstn)
            );
         assign  write                 = 1'b0;
         assign  write_wait            = 1'b0;
         assign  rx_ack_requester      = 1'b0;
         assign  rx_ws_requester       = 1'b0;
         assign  dma_sm_req[6:4]       = 0;
         assign  write_byteena         = 16'h0;
         assign  cpl_pending_requestor = 1'b0;
      end
    else if (AVALON_ST_128==1) begin
         // altpcierd_read_dma_requester
         // Transfer data RC memory to EP memeory
         altpcierd_read_dma_requester_128 #(
            .RC_64BITS_ADDR  (RC_64BITS_ADDR) ,
            .FIFO_WIDTH      (FIFO_WIDTH)     ,
            .MAX_NUMTAG      (MAX_NUMTAG_LIMIT)     ,
            .USE_CREDIT_CTRL (USE_CREDIT_CTRL),
            .TXCRED_WIDTH    (TXCRED_WIDTH)   ,
            .BOARD_DEMO      (BOARD_DEMO)     ,
            .USE_MSI         (USE_MSI)        ,
            .AVALON_WADDR    (AVALON_WADDR)   ,
            .AVALON_WDATA    (AVALON_WDATA)   ,
            .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
            .RC_SLAVE_USETAG (RC_SLAVE_USETAG),
            .DT_EP_ADDR_SPEC (DT_EP_ADDR_SPEC),
            .CDMA_AST_RXWS_LATENCY (CDMA_AST_RXWS_LATENCY)
            )
            read_requester_128
            (
            .dt_fifo_rdreq (dt_fifo_rdreq),
            .dt_fifo_empty (dt_fifo_empty),
            .dt_fifo_q     (dt_fifo_q    ),

            // PCIe config info
           .cfg_maxrdreq_dw     (cfg_maxrdreq_dw),
            .cfg_maxrdreq        (cfg_maxrdreq),
            .cfg_link_negociated (cfg_link_negociated),

            // DMA Prg signals register
            .dt_base_rc    (dt_base_rc   ),
            .dt_3dw_rcadd  (dt_3dw_rcadd ),
            .dt_eplast_ena (dt_eplast_ena),
            .dt_msi        (dt_msi       ),
            .dt_size       (dt_size      ),

            // PCIe backend Transmit section
            .tx_ready      (tx_ready_requester),
            .tx_sel        (tx_sel_requester  ),
            .tx_busy       (tx_busy_requester ),
            .tx_cred       (tx_cred           ),
            .tx_have_creds (tx_have_creds),
            .tx_req        (tx_req_requester  ),
            .tx_ack        (tx_ack            ),
            .tx_desc       (tx_desc_requester ),
            .tx_data       (tx_data           ),
            .tx_dfr        (tx_dfr            ),
            .tx_dv         (tx_dv             ),
            .tx_ws         (tx_ws             ),
            .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),

            .rx_req        (rx_req           ),
            .rx_ack        (rx_ack_requester ),
            .rx_desc       (rx_desc          ),
            .rx_data       (rx_data          ),
            .rx_be         (rx_be            ),
            .rx_dv         (rx_dv            ),
            .rx_dfr        (rx_dfr           ),
            .rx_ws         (rx_ws_requester  ),

            //MSI
            .app_msi_ack   (app_msi_ack  ),
            .app_msi_req   (app_msi_req  ),
            .msi_sel       (msi_sel      ),
            .msi_ready     (msi_ready    ),
            .msi_busy      (msi_busy     ),

            // Avalon back end
            .address       (write_address ),
            .waitrequest   (write_wait    ),
            .write         (write         ),
            .writedata     (write_data    ),
            .write_byteena (write_byteena),

            .dma_sm_tx(dma_sm_req[3:0]),
            .dma_sm_rx(dma_sm_req[6:4]),

            .descriptor_mrd_cycle   (descriptor_mrd_cycle),
            .requester_mrdmwr_cycle (requester_mrdmwr_cycle),

            .dma_status    (dma_status),
            .cpl_pending   (cpl_pending_requestor),

            .init          ((USE_DMAREAD==0)?1'b1:init   ),
            .clk_in        (clk_in ),
            .rstn          ((USE_DMAREAD==0)?1'b0:rstn   )
            );
         assign  read      = 1'b0;
         assign  read_wait = 1'b0;
      end
    else begin
         // altpcierd_read_dma_requester
         // Transfer data RC memory to EP memeory
         altpcierd_read_dma_requester #(
            .RC_64BITS_ADDR  (RC_64BITS_ADDR) ,
            .FIFO_WIDTH      (FIFO_WIDTH)     ,
            .MAX_NUMTAG      (MAX_NUMTAG_LIMIT)     ,
            .USE_CREDIT_CTRL (USE_CREDIT_CTRL),
            .TXCRED_WIDTH    (TXCRED_WIDTH)   ,
            .BOARD_DEMO      (BOARD_DEMO)     ,
            .USE_MSI         (USE_MSI)        ,
            .AVALON_WADDR    (AVALON_WADDR)   ,
            .AVALON_WDATA    (AVALON_WDATA)   ,
            .INTENDED_DEVICE_FAMILY (INTENDED_DEVICE_FAMILY),
            .RC_SLAVE_USETAG (RC_SLAVE_USETAG),
            .DT_EP_ADDR_SPEC (DT_EP_ADDR_SPEC),
            .CDMA_AST_RXWS_LATENCY(CDMA_AST_RXWS_LATENCY)
            )
            read_requester
            (
            .dt_fifo_rdreq (dt_fifo_rdreq),
            .dt_fifo_empty (dt_fifo_empty),
            .dt_fifo_q     (dt_fifo_q    ),

            // PCIe config info
            .cfg_maxrdreq_dw     (cfg_maxrdreq_dw),
            .cfg_maxrdreq        (cfg_maxrdreq),
            .cfg_link_negociated (cfg_link_negociated),

            // DMA Prg signals register
            .dt_base_rc    (dt_base_rc   ),
            .dt_3dw_rcadd  (dt_3dw_rcadd ),
            .dt_eplast_ena (dt_eplast_ena),
            .dt_msi        (dt_msi       ),
            .dt_size       (dt_size      ),

            // PCIe backend Transmit section
            .tx_ready      (tx_ready_requester),
            .tx_sel        (tx_sel_requester  ),
            .tx_busy       (tx_busy_requester ),
            .tx_cred       (tx_cred           ),
            .tx_have_creds (tx_have_creds),
            .tx_req        (tx_req_requester  ),
            .tx_ack        (tx_ack            ),
            .tx_desc       (tx_desc_requester ),
            .tx_data       (tx_data           ),
            .tx_dfr        (tx_dfr            ),
            .tx_dv         (tx_dv             ),
            .tx_ws         (tx_ws             ),
            .rx_buffer_cpl_max_dw(rx_buffer_cpl_max_dw),

            .rx_req        (rx_req           ),
            .rx_ack        (rx_ack_requester ),
            .rx_desc       (rx_desc          ),
            .rx_data       (rx_data[63:0]    ),
            .rx_be         (rx_be[7:0]       ),
            .rx_dv         (rx_dv            ),
            .rx_dfr        (rx_dfr           ),
            .rx_ws         (rx_ws_requester  ),

            //MSI
            .app_msi_ack   (app_msi_ack  ),
            .app_msi_req   (app_msi_req  ),
            .msi_sel       (msi_sel      ),
            .msi_ready     (msi_ready    ),
            .msi_busy      (msi_busy     ),

            // Avalon back end
            .address       (write_address ),
            .waitrequest   (write_wait    ),
            .write         (write         ),
            .writedata     (write_data    ),
            .write_byteena (write_byteena),

            .dma_sm_tx(dma_sm_req[3:0]),
            .dma_sm_rx(dma_sm_req[6:4]),

            .descriptor_mrd_cycle   (descriptor_mrd_cycle),
            .requester_mrdmwr_cycle (requester_mrdmwr_cycle),

            .dma_status    (dma_status),
            .cpl_pending   (cpl_pending_requestor),

            .init          ((USE_DMAREAD==0)?1'b1:init   ),
            .clk_in        (clk_in ),
            .rstn          ((USE_DMAREAD==0)?1'b0:rstn   )
            );
         assign  tx_data[127:64]  = 0;
         assign  read      = 1'b0;
         assign  read_wait = 1'b0;
      end
   end
endgenerate


assign dma_sm[6:0] =(DISPLAY_SM==0)?0:dma_sm_req;
assign dma_sm[10:7] =(DISPLAY_SM==0)?0:dma_sm_desc;


endmodule




