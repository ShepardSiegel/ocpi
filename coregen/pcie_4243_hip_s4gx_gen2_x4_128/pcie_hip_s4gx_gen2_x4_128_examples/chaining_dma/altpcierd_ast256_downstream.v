// /**
//  * This Verilog HDL file is used for simulation and synthesis in
//  * the single DWORD downstream 256-bit interface  design example.
//  */
// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

//-----------------------------------------------------------------------------
// Title         : PCI Express Reference Design Example Application
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_ast256_downstream.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Copyright (c) 2010 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents maskwork rights, copyrights and
// other intellectual property laws.
//
// This reference design file and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation
// and therefore all warranties representations or guarantees of any kind
// (whether express implied or statutory) including, without limitation, warranties of
// merchantability non-infringement, or fitness for a particular purpose, are
// specifically disclaimed.  By making this reference design file available Altera
// expressly does not recommend suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------
// Parameters
//
//
module altpcierd_ast256_downstream #(
   parameter AVALON_WADDR          = 12,
   parameter AVALON_WDATA          = 256,
   parameter MAX_NUMTAG            = 64,
   parameter MAX_PAYLOAD_SIZE_BYTE = 512,
   parameter BOARD_DEMO            = 1,
   parameter USE_RCSLAVE           = 0,
   parameter TL_SELECTION          = 0,
   parameter CLK_250_APP           = 0,// When 1 indicate application clock rate is 250MHz instead of 125 MHz
   parameter ECRC_FORWARD_CHECK    = 0,
   parameter ECRC_FORWARD_GENER    = 0,
   parameter CHECK_BUS_MASTER_ENA  = 0,
   parameter CHECK_RX_BUFFER_CPL   = 0,
   parameter AVALON_ST_128         = 0,
   parameter USE_CREDIT_CTRL       = 0,
   parameter RC_64BITS_ADDR        = 0 , // When 1 RC Capable of 64 bit address --> 4DW header rx_desc/tx_desc address instead of 3DW
   parameter USE_MSI               = 1   // When 1, tx_arbitration uses tx_cred
   )(

   input  [  7: 0] rx_st_bardec0  ,
   input  [ 31: 0] rx_st_be0      ,
   input  [255: 0] rx_st_data0    ,
   input  [  1: 0] rx_st_empty0   ,
   input           rx_st_eop0     ,
   input           rx_st_err0     ,
   input           rx_st_sop0     ,
   input           rx_st_valid0   ,
   output          rx_st_mask0    ,
   output          rx_st_ready0   ,

   input                tx_st_ready0 ,
   output  reg [255: 0] tx_st_data0  ,
   output  reg [  1: 0] tx_st_empty0 ,
   output  reg          tx_st_eop0   ,
   output  reg          tx_st_err0   ,
   output  reg [ 31: 0] tx_st_parity0,
   output  reg          tx_st_sop0   ,
   output  reg          tx_st_valid0 ,

   // Credit
   input  [ 11: 0] tx_cred_datafccp,
   input  [ 11: 0] tx_cred_datafcnp,
   input  [ 11: 0] tx_cred_datafcp,
   input  [  5: 0] tx_cred_fchipcons,
   input  [  5: 0] tx_cred_fcinfinite,
   input  [  7: 0] tx_cred_hdrfccp,
   input  [  7: 0] tx_cred_hdrfcnp,
   input  [  7: 0] tx_cred_hdrfcp,

   // MSI Interrupt
   // Avalon ST Interface only
   output[4:0]   aer_msi_num      ,
   output[4:0]   pex_msi_num      ,
   output        app_msi_req      ,
   input         app_msi_ack      ,
   output[2:0]   app_msi_tc       ,
   output[4:0]   app_msi_num      ,

   // Legacy Interrupt
   output        app_int_sts,
   input         app_int_ack,

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

   input clk_in,
   input rstn

   );

   // Local parameters
   localparam [255:0] ZERO          = 256'h0;
   localparam NUMWORDS_AVALON_WADDR = 1<<AVALON_WADDR;
   localparam AVALON_BYTE_WIDTH     = AVALON_WDATA/8;  // for epmem byte enables

   localparam ST_TX_IDLE      =0,
              ST_RD_DATA      =1,
              ST_TX_SOP_CPLD  =2,
              ST_TX_MOP_CPLD  =3;

   reg         [2:0]   cstate_tx;
   reg         [2:0]   nstate_tx;

   reg [AVALON_WDATA-1:0]   wrdata        ;
   reg [AVALON_BYTE_WIDTH-1:0]   byteena_a     ;
   reg [AVALON_BYTE_WIDTH-1:0]   byteena_b     ;
   reg [AVALON_WADDR-1:0]   rdaddress     ;
   reg                      wren        ;
   wire [AVALON_WDATA-1:0]  rddata           ;
   reg [AVALON_WADDR-1:0]  wraddress     ;
   reg [AVALON_WADDR-1:0]  wraddress_r     ;
   reg                      rden        ;
   reg                      tlp_read      ;
   reg                      tlp_write     ;
   reg  [9:0]               tlp_rx_len    ;
   reg                      tlp_3dw_header;
   reg                      tlp_sop;

   reg                      tlp_addr_qwaligned;
   wire                     bar_downstream;
   wire                     bar_upstream  ;


   wire [31:0] tx_st_data_dw0;
   wire [31:0] tx_st_data_dw1;
   wire [31:0] tx_st_data_dw2;
   wire [31:0] tx_st_data_dw3;
   wire [31:0] tx_st_data_dw4;
   wire [31:0] tx_st_data_dw5;
   wire [31:0] tx_st_data_dw6;
   wire [31:0] tx_st_data_dw7;

   wire [31:0] rx_st_data_dw0;
   wire [31:0] rx_st_data_dw1;
   wire [31:0] rx_st_data_dw2;
   wire [31:0] rx_st_data_dw3;
   wire [31:0] rx_st_data_dw4;
   wire [31:0] rx_st_data_dw5;
   wire [31:0] rx_st_data_dw6;
   wire [31:0] rx_st_data_dw7;

   wire [1:0]  rx_st_fmt;
   wire [4:0]  rx_st_type;
   wire [9:0]  rx_st_len;

   reg [31:0] rx_h0;
   reg [31:0] rx_h1;
   reg [31:0] rx_h2;
   reg [31:0] rx_h3;
   reg [159:0] payload_h;

   wire [31:0] tx_h0;
   wire [31:0] tx_h1;
   wire [31:0] tx_h2;
   reg  [23:0] reqid_tag;
   reg  [9:0]  addr_len_cnt;
   reg  [9:0]  tx_h0_len;
   reg  [9:0]  tx_len_cnt;
   reg  [6:0]  tx_h2_lower_add;
   reg  [127:0] rd_data;

   assign rx_st_mask0       = 1'b0              ;
   assign rx_st_ready0      = (cstate_tx==ST_TX_IDLE)?1'b1:1'b0;
   assign aer_msi_num       = ZERO[4:0]         ;
   assign pex_msi_num       = ZERO[4:0]         ;
   assign app_msi_req       = 1'b0              ;
   assign app_msi_tc        = ZERO[2:0]         ;
   assign app_msi_num       = ZERO[4:0]         ;
   assign app_int_sts       = 1'b0              ;
   assign cpl_pending       = 1'b0              ;
   assign cpl_err           = ZERO[6:0]         ;
   assign err_desc          = ZERO[127:0]       ;
   assign pm_data           = ZERO[9:0]         ;


   assign {rx_st_data_dw7, rx_st_data_dw6, rx_st_data_dw5, rx_st_data_dw4, rx_st_data_dw3, rx_st_data_dw2, rx_st_data_dw1, rx_st_data_dw0}=
                  rx_st_data0;

   assign bar_downstream = rx_st_bardec0[0]| rx_st_bardec0[1]|rx_st_bardec0[4]|rx_st_bardec0[5];
   assign bar_upstream   = rx_st_bardec0[2]| rx_st_bardec0[3];
   assign rx_st_fmt     = rx_st_data_dw0[30:29];
   assign rx_st_type    = rx_st_data_dw0[28:24];
   assign rx_st_len     = rx_st_data_dw0[9:0];

   always @(negedge rstn or posedge clk_in) begin : p_rx_h
      if (rstn == 1'b0) begin
         rx_h0             <= 32'h0;
         rx_h1             <= 32'h0;
         rx_h2             <= 32'h0;
         rx_h3             <= 32'h0;
         tlp_read          <=  1'b0;
         tlp_sop           <=  1'b0;
         tlp_write         <=  1'b0;
         tlp_3dw_header    <= 1'b0;
         tlp_addr_qwaligned<= 1'b0;
         reqid_tag         <= 24'h0;
         tx_h2_lower_add   <= 7'h0;
         tx_h0_len         <= 10'h0;
      end
      else begin
         tlp_sop <= ((rx_st_valid0==1'b1)&&(rx_st_sop0==1'b1)) ?1'b1:1'b0;
         if ((rx_st_valid0==1'b1)&&(rx_st_sop0==1'b1)) begin
            rx_h0     <= rx_st_data_dw0;
            rx_h1     <= rx_st_data_dw1;
            rx_h2     <= rx_st_data_dw2;
            reqid_tag <= rx_st_data_dw1[31:8];
            tx_h0_len <= rx_st_data_dw0[9:0];
            if (rx_st_fmt[0]==1'b1) begin
               rx_h3                <= rx_st_data_dw3;
               tlp_3dw_header       <= 1'b0;
               tlp_addr_qwaligned   <= (rx_st_data_dw3[2:0]==3'b000)?1'b1:1'b0;
               tx_h2_lower_add      <= rx_st_data_dw3[6:0];
            end
            else begin
               tlp_3dw_header       <= 1'b1;
               tlp_addr_qwaligned   <= (rx_st_data_dw2[2:0]==3'b000)?1'b1:1'b0;
               tx_h2_lower_add      <= rx_st_data_dw2[6:0];
            end
            tlp_read   <= ((rx_st_fmt[1]==1'b0)&&(rx_st_type==5'h0))?1'b1:1'b0;
            tlp_write  <= ((rx_st_fmt[1]==1'b1)&&(rx_st_type==5'h0))?1'b1:1'b0;
         end
         else if (rx_st_valid0==1'b0) begin
            tlp_read   <= 1'b0;
            tlp_write  <= 1'b0;
         end
      end
   end

   // Mem Write
   always @ * begin
      case (tlp_rx_len)
         10'h1  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_0_0_0_0_0_F;
         10'h2  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_0_0_0_0_F_F;
         10'h3  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_0_0_0_F_F_F;
         10'h4  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_0_0_F_F_F_F;
         10'h5  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_0_F_F_F_F_F;
         10'h6  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_0_F_F_F_F_F_F;
         10'h7  :byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'h0_F_F_F_F_F_F_F;
         default:byteena_a[AVALON_BYTE_WIDTH-1:0] <= 32'hF_F_F_F_F_F_F_F;
      endcase
      if (tlp_3dw_header==1'b0) begin
         wrdata = (tlp_addr_qwaligned==1'b1)?{rx_st_data0[127:0],payload_h[159:32]}:
                                                 {rx_st_data0[159:0],payload_h[159:64]};
         wraddress [AVALON_WADDR-1:0]<=  (tlp_sop==1'b1)?rx_h3[AVALON_WADDR-1:0]:wraddress_r;
      end
      else begin
         wrdata = (tlp_addr_qwaligned==1'b1)?{rx_st_data0[127:0],payload_h[159:32]}:
                                                 {rx_st_data0[96:0] ,payload_h[159:0]};
         wraddress [AVALON_WADDR-1:0]= (tlp_sop==1'b1)?rx_h2[AVALON_WADDR-1:0]:wraddress_r;
      end
      if (tlp_write==1'b1) begin
         wren    =  (tlp_rx_len>0)?1'b1:1'b0;
      end
      else begin
         wren      =  1'b0;
      end
   end

   always @(negedge rstn or posedge clk_in) begin : p_wr_mem
      if (rstn == 1'b0) begin
         payload_h <= 160'h0;
         tlp_rx_len <= 10'h0;
         wraddress_r [AVALON_WADDR-1:0]<= 0;
      end
      else begin
         payload_h <= {rx_st_data_dw7,rx_st_data_dw6,rx_st_data_dw5,rx_st_data_dw4,rx_st_data_dw3};

         if (rx_st_valid0==1'b1) begin
            wraddress_r <= (tlp_sop==1'b1)?wraddress+1:wraddress_r+1;
         end
         if ((rx_st_valid0==1'b1)&&(rx_st_sop0==1'b1)) begin
            tlp_rx_len <= rx_st_len;
         end
         else if (tlp_write==1'b1) begin
            tlp_rx_len <= (tlp_rx_len>10'h8)?tlp_rx_len-10'h8:10'h0;
         end
         else begin
            tlp_rx_len <= 10'h0;
         end
      end
   end


   // MEM read
   always @(negedge rstn or posedge clk_in) begin : p_rd_mem
      if (rstn == 1'b0) begin
         rdaddress                           <= ZERO[AVALON_WADDR-1:0];
         rden                                <= ZERO[0];
         byteena_b[AVALON_BYTE_WIDTH-1:0]    <= 32'hFFFF_FFFF; // TODO check byte enable
         addr_len_cnt                        <= 10'h0;
      end
      else begin
         rd_data <= rddata[255:128];
         rden <= (addr_len_cnt>10'h0)?1'b1:1'b0;
         if ((rx_st_valid0==1'b1)&&(rx_st_sop0==1'b1)&&(rx_st_fmt[1]==1'b0)&&(rx_st_type==5'h0)) begin
            addr_len_cnt <= rx_st_len;
            rden     <=1'b1;
         end
         else if (tx_st_ready0==1'b1) begin
            addr_len_cnt <= (addr_len_cnt>10'h8)?addr_len_cnt-10'h8:10'h0;
            rden     <= (addr_len_cnt>10'h8)?1'b1:1'b0;
         end

         if ((tlp_sop==1'b1) &&(tlp_read==1'b1)) begin
            rdaddress [AVALON_WADDR-1:0]<=  (tlp_3dw_header==1'b0)?rx_h3[AVALON_WADDR-1:0]:rx_h2;
         end
         else if (addr_len_cnt>10'h0) begin
         // 3DW header
            rdaddress [AVALON_WADDR-1:0]<=  rdaddress+1;
         end
      end
   end

   onchip_256xram onchip_ram ( .clock(clk_in),
                               .data(wrdata),
                               .rdaddress(rdaddress),
                               .wraddress(wraddress),
                               .wren(wren),
                               .rden(rden),
                               .q(rddata));

   always @*
      case (cstate_tx)
         ST_TX_IDLE    :
         // Reflects the beginning of a new descriptor
            begin
               nstate_tx = (rden==1'b1)?ST_RD_DATA:ST_TX_IDLE;
            end

         ST_RD_DATA   : //
            begin
               nstate_tx = ST_TX_SOP_CPLD;
            end
         ST_TX_SOP_CPLD        : // rx_ack upon rx_req and CPLD, and DMA Read tag
            begin
               if (tx_st_ready0==1'b1) begin
                  if (tx_len_cnt==10'h0)
                     nstate_tx = (rden==1'b1)?ST_RD_DATA:ST_TX_IDLE;
                  else if (tx_len_cnt>10'h8)
                     nstate_tx = ST_TX_MOP_CPLD;
                  else
                     nstate_tx = ST_TX_SOP_CPLD;
               end
               else begin
                  nstate_tx = ST_TX_SOP_CPLD;
               end
            end
         ST_TX_MOP_CPLD        : //
            begin
               if (tx_st_ready0==1'b0)
                  nstate_tx = ST_TX_MOP_CPLD;
               else if (tx_len_cnt==10'h0)
                  nstate_tx = (rden==1'b1)?ST_RD_DATA:ST_TX_IDLE;
               else
                  nstate_tx = ST_TX_MOP_CPLD;
            end
         default:
            nstate_tx = ST_TX_IDLE;

      endcase

   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin
         cstate_tx <= ST_TX_IDLE;
      end
      else begin
         cstate_tx  <= nstate_tx;
      end
   end

   always @(negedge rstn or posedge clk_in) begin : p_tx_h
      if (rstn == 1'b0) begin
         tx_st_data0   <= 256'h0;
         tx_st_empty0  <= 2'h0;
         tx_st_eop0    <= 1'b0;
         tx_st_err0    <= 1'b0;
         tx_st_parity0 <= 32'h0;
         tx_st_sop0    <= 1'b0;
         tx_st_valid0  <= 1'b0;
         tx_len_cnt    <= 10'h0;
      end
      else begin
         tx_st_parity0 <= 32'h0;
         tx_st_err0    <= 1'b0;
         if (cstate_tx==ST_TX_SOP_CPLD) begin
            tx_st_sop0  <= 1'b1;
            if (tx_h2_lower_add[2:0]==0) begin
               tx_st_data0 <= {rddata[127:0],32'h0,tx_h2,tx_h1,tx_h0};
               tx_st_eop0  <= (tx_h0_len<5)?1'b1:1'b0;
               tx_len_cnt  <= (tx_h0_len<5)?10'h0:tx_h0_len-5;
               case(tx_h0_len)
                  10'h1  :tx_st_empty0 <= 2'h1;
                  10'h2  :tx_st_empty0 <= 2'h1;
                  default:tx_st_empty0 <= 2'h0;
               endcase
            end
            else begin
               tx_st_data0 <= {rddata[159:0],tx_h2,tx_h1,tx_h0};
               tx_st_eop0  <= (tx_h0_len<6)?1'b1:1'b0;
               tx_len_cnt  <= (tx_h0_len<6)?10'h0:tx_h0_len-6;
               case(tx_h0_len)
                  10'h1  :tx_st_empty0 <= 2'h2;
                  10'h2  :tx_st_empty0 <= 2'h1;
                  10'h3  :tx_st_empty0 <= 2'h1;
                  default:tx_st_empty0<= 2'h0;
               endcase
            end
            tx_st_valid0 <= (tx_st_ready0==1'b1)?1'b1:1'b0;
         end
         else if (cstate_tx==ST_TX_MOP_CPLD) begin
            tx_st_sop0  <= 1'b0;
            tx_st_data0 <= (tx_h2_lower_add[2:0]==0)?{rddata[127:0],rd_data[127:0]}:{rddata[159:0], rd_data[95:0]};
            tx_st_eop0  <= (tx_len_cnt<8)?1'b1:1'b0;
            tx_len_cnt  <= (tx_len_cnt<8)?10'h0:tx_h0_len-8;
            case(tx_len_cnt)
               10'h1  :tx_st_empty0 <= 2'h3;
               10'h2  :tx_st_empty0 <= 2'h2;
               10'h3  :tx_st_empty0 <= 2'h2;
               10'h4  :tx_st_empty0 <= 2'h1;
               10'h5  :tx_st_empty0 <= 2'h1;
               default:tx_st_empty0 <= 2'h0;
            endcase
            tx_st_valid0 <= (tx_st_ready0==1'b1)?1'b1:1'b0;
         end
         else begin
            tx_st_valid0  <= 1'b0;
            tx_st_sop0    <= 1'b0;
            tx_st_eop0    <= 1'b0;
            tx_st_empty0  <= 2'b00;
         end
      end
   end

   // TX TLP Header
   assign tx_h0[9:0]   = tx_h0_len[9:0];
   assign tx_h0[15:10] = 6'h00;
   assign tx_h0[23:16] = 8'h00;
   assign tx_h0[28:24] = 5'b01010;    // FMT CPLD
   assign tx_h0[31:29] = 3'b010;      // CPLD with data

   assign tx_h1[11:0]  = {tx_h0_len,2'h0}; // Byte count  //TODO Update for broke down completion
   assign tx_h1[15:12] = 4'h0;
   assign tx_h1[31:16] = {cfg_busdev[12:0],3'h0};// Bus /Dev /Function=0

   assign tx_h2[6:0]   = tx_h2_lower_add[6:0];
   assign tx_h2[7]     = 1'b0;
   assign tx_h2[31:8]  = reqid_tag[23:0];

   // For debug
   assign tx_st_data_dw0 = tx_st_data0[31:0];
   assign tx_st_data_dw1 = tx_st_data0[63:32];
   assign tx_st_data_dw2 = tx_st_data0[95:64];
   assign tx_st_data_dw3 = tx_st_data0[127:96];
   assign tx_st_data_dw4 = tx_st_data0[159:128];
   assign tx_st_data_dw5 = tx_st_data0[191:160];
   assign tx_st_data_dw6 = tx_st_data0[223:192];
   assign tx_st_data_dw7 = tx_st_data0[255:224];

endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module onchip_256xram (
   clock,
   data,
   rdaddress,
   rden,
   wraddress,
   wren,
   q);

   input   clock;
   input [255:0]  data;
   input [11:0]  rdaddress;
   input   rden;
   input [11:0]  wraddress;
   input   wren;
   output   [255:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
   tri1    clock;
   tri1    rden;
   tri0    wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

   wire [255:0] sub_wire0;
   wire [255:0] q = sub_wire0[255:0];

   altsyncram  altsyncram_component (
            .wren_a (wren),
            .clock0 (clock),
            .address_a (wraddress),
            .address_b (rdaddress),
            .rden_b (rden),
            .data_a (data),
            .q_b (sub_wire0),
            .aclr0 (1'b0),
            .aclr1 (1'b0),
            .addressstall_a (1'b0),
            .addressstall_b (1'b0),
            .byteena_a (1'b1),
            .byteena_b (1'b1),
            .clock1 (1'b1),
            .clocken0 (1'b1),
            .clocken1 (1'b1),
            .clocken2 (1'b1),
            .clocken3 (1'b1),
            .data_b ({256{1'b1}}),
            .eccstatus (),
            .q_a (),
            .rden_a (1'b1),
            .wren_b (1'b0));
   defparam
      altsyncram_component.address_aclr_b = "NONE",
      altsyncram_component.address_reg_b = "CLOCK0",
      altsyncram_component.clock_enable_input_a = "BYPASS",
      altsyncram_component.clock_enable_input_b = "BYPASS",
      altsyncram_component.clock_enable_output_b = "BYPASS",
      altsyncram_component.intended_device_family = "Stratix IV",
      altsyncram_component.lpm_type = "altsyncram",
      altsyncram_component.numwords_a = 4096,
      altsyncram_component.numwords_b = 4096,
      altsyncram_component.operation_mode = "DUAL_PORT",
      altsyncram_component.outdata_aclr_b = "NONE",
      altsyncram_component.outdata_reg_b = "CLOCK0",
      altsyncram_component.power_up_uninitialized = "FALSE",
      altsyncram_component.rdcontrol_reg_b = "CLOCK0",
      altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
      altsyncram_component.widthad_a = 12,
      altsyncram_component.widthad_b = 12,
      altsyncram_component.width_a = 256,
      altsyncram_component.width_b = 256,
      altsyncram_component.width_byteena_a = 1;


endmodule
