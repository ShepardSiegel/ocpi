//*****************************************************************************
// (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
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
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Application        : MIG                          
//  \   \         Filename           : traffic_gen_top.v
//  /   /         Date Last Modified : $Date: 2011/05/27 14:31:13 $
// /___/   /\     Date Created       : Fri Mar 26 2010
// \   \  /  \    
//  \___\/\___\
//
//Device           : Virtex-7
//Design Name      : DDR/DDR2/DDR3/LPDDR
//Purpose          : This Traffic Gen supports both nCK_PER_CLK x4 mode and nCK_PER_CLK x2 mode for
//                   7series MC UI Interface.  The user bus datawidth has a equation: 2*nCK_PER_CLK*DQ_WIDTH.
//                   
//Reference        :
//Revision History :  11/17 Adding CMD_GAP_DELAY to allow control of next command generation after current
//                          completion of burst command in user interface port. 
//*****************************************************************************

`timescale 1ps/1ps

module traffic_gen_top #(
   parameter TCQ           = 100,            // SIMULATION tCQ delay.
   
   parameter SIMULATION             = "FALSE",   
   parameter FAMILY                   = "VIRTEX7",         //  "VIRTEX6", "VIRTEX7"
   parameter MEM_TYPE                 = "DDR3",
   
   parameter TST_MEM_INSTR_MODE       =  "R_W_INSTR_MODE", // Spartan6 Available commands: 
                                                           // "FIXED_INSTR_R_MODE", "FIXED_INSTR_W_MODE"
                                                           // "R_W_INSTR_MODE", "RP_WP_INSTR_MODE 
                                                           // "R_RP_W_WP_INSTR_MODE", "R_RP_W_WP_REF_INSTR_MODE"
                                                    // *******************************
                                                    // Virtex 6 Available commands:
                                                    // "R_W_INSTR_MODE"
                                                    // "FIXED_INSTR_R_MODE" - Only Read commands will be generated.
                                                    // "FIXED_INSTR_W_MODE" -- Only Write commands will be generated.
                                                    // "FIXED_INSTR_R_EYE_MODE"  Only Read commands will be generated 
                                                    //                           with lower 10 bits address in sequential increment.
                                                    //                           This mode is for Read Eye measurement.
                                                    
   parameter BL_WIDTH                 = 10,             // Define User Interface Burst length width. 
                                                        // For a maximum 128 continuous back_to_back command, set this to 8.
   parameter nCK_PER_CLK              = 4,              // Memory Clock ratio to fabric clock.
   parameter NUM_DQ_PINS              = 8,              // Total number of memory dq pins in the design.
   parameter MEM_BURST_LEN            = 8,              // MEMROY Burst Length    
   parameter MEM_COL_WIDTH            = 10,             // Memory component column width.
   parameter PORT_MODE                = "BI_MODE",      
   parameter DATA_PATTERN             = "DGEN_ALL",     // Default is to generate all data pattern circuits.
   parameter CMD_PATTERN              = "CGEN_ALL",     // Default is to generate all commands pattern circuits.
   parameter DATA_WIDTH               = NUM_DQ_PINS*2*nCK_PER_CLK,             // User Interface Data Width      
   parameter ADDR_WIDTH               = 32,             // Command Address Bus width
   parameter MASK_SIZE                = DATA_WIDTH/8,   // 
   parameter DATA_MODE                = 4'b0010,        // Default Data mode is set to Address as Data pattern.

   // parameters define the address range
   parameter BEGIN_ADDRESS            = 32'h00000100,
   parameter END_ADDRESS              = 32'h000002ff,
   parameter PRBS_EADDR_MASK_POS      = 32'hfffffc00,
   // debug parameters
   parameter CMDS_GAP_DELAY           = 6'd0,   // CMDS_GAP_DELAY is used in memc_flow_vcontrol module to insert delay between 
                                                // each sucessive burst commands. The maximum delay is 32 clock cycles 
                                                // after the last  command.
   parameter SEL_VICTIM_LINE          = NUM_DQ_PINS,      // VICTIM LINE is one of the DQ pins is selected to be always asserted when
                                                          // DATA MODE is hammer pattern. No VICTIM_LINE will be selected if
                                                          // SEL_VICTIM_LINE = NUM_DQ_PINS.
   parameter EYE_TEST                 = "FALSE"
  )
  (
   input                           clk, 
   input                           rst, 
   input                           manual_clear_error,
   input                           memc_init_done, 

   input                           memc_cmd_full,
   output                          memc_cmd_en,
   output [2:0]                    memc_cmd_instr,
   output [5:0]                    memc_cmd_bl,
   output [31:0]                   memc_cmd_addr,

   output                          memc_wr_en,
   output                          memc_wr_end,
   
   output [DATA_WIDTH/8 - 1:0]     memc_wr_mask,
   output [DATA_WIDTH - 1:0]       memc_wr_data,
   input                           memc_wr_full,

   output                          memc_rd_en,
   input [DATA_WIDTH - 1:0]        memc_rd_data,
   input                           memc_rd_empty,

   // interface to qdr interface
   output                          qdr_wr_cmd_o,
   output                          qdr_rd_cmd_o,


   // Signal declarations that can be connected to vio module 
   input                           vio_modify_enable,
   input [3:0]                     vio_data_mode_value,
   input [2:0]                     vio_addr_mode_value,
   input [3:0]                     vio_instr_mode_value,
   input [1:0]                     vio_bl_mode_value,
   input [BL_WIDTH - 1:0]          vio_fixed_bl_value,
   input                           vio_data_mask_gen,  // data_mask generation is only supported 
                                                       // when data mode = address as data .
   input [31:0]                    fixed_addr_i,
   
   // User Specific data pattern interface that used when vio_data_mode vale = 1.4.9.
   input [31:0]                    fixed_data_i,
   input [31:0]                    simple_data0,
   input [31:0]                    simple_data1, 
   input [31:0]                    simple_data2, 
   input [31:0]                    simple_data3, 
   input [31:0]                    simple_data4, 
   input [31:0]                    simple_data5, 
   input [31:0]                    simple_data6, 
   input [31:0]                    simple_data7, 
   
   // BRAM interface.
                                          //   bram bus formats:
                                          //   Only SP6 has been tested.
   input [38:0]                    bram_cmd_i,   //  {{bl}, {cmd}, {address[28:2]}}
   input                           bram_valid_i,
   output                          bram_rdy_o,  //
   

   // status feedback
   output [DATA_WIDTH-1:0]         cmp_data,
   output                          cmp_data_valid,
   output                          cmp_error,
   output                          error,       // asserted whenever the read back data is not correct.
   output [64 + (2*DATA_WIDTH - 1):0]     error_status
  );

  
  

//p0 wire declarations
   wire            tg_run_traffic; 
   wire [31:0]     tg_start_addr;
   wire [31:0]     tg_end_addr;
   wire [31:0]     tg_cmd_seed; 
   wire [31:0]     tg_data_seed;
   wire            tg_load_seed;
   wire [2:0]      tg_addr_mode;
   wire [3:0]      tg_instr_mode;
   wire [1:0]      tg_bl_mode;
   wire [3:0]      tg_data_mode;
   wire            tg_mode_load;
   wire [BL_WIDTH-1:0]      tg_fixed_bl;
   wire [2:0]      tg_fixed_instr;
   wire            tg_addr_order;
   wire [5:0]      cmds_gap_delay_value;
   wire            tg_memc_wr_en;
   wire            mem_pattern_init_done;
//   reg memc_init_done;
//  assign tg_fixed_bl = 64;//{1'b1, {BL_WIDTH-1{1'b0}}} ;//* BURST_LENGTH;
// when in PRBS mode:
//  assign tg_fixed_bl = 64;//{1'b1, {BL_WIDTH-1{1'b0}}} ;//* BURST_LENGTH;
     
// cmds_gap_delay_value is used in memc_flow_vcontrol module to insert delay between 
// each sucessive burst commands. The maximum delay is 32 clock cycles after the last  command.
assign cmds_gap_delay_value = CMDS_GAP_DELAY;

localparam TG_FAMILY = ((FAMILY == "VIRTEX6") || (FAMILY == "VIRTEX7") || (FAMILY == "7SERIES") 
                         || (FAMILY == "KINTEX7") || (FAMILY == "ARTIX7") ) ? "VIRTEX6" : "SPARTAN6";



assign tg_memc_wr_en = (TG_FAMILY == "VIRTEX6") ?memc_cmd_en & ~memc_cmd_full : memc_wr_en ;

// The following 'generate' statement activates the traffic generator for
   // init_mem_pattern_ctr module instantiation for Port-0
   init_mem_pattern_ctr #
     (
      .TCQ                           (TCQ),
      .DWIDTH                        (DATA_WIDTH), 
      
      .TST_MEM_INSTR_MODE            (TST_MEM_INSTR_MODE),
   //   .nCK_PER_CLK                   (nCK_PER_CLK),
      .MEM_BURST_LEN                 (MEM_BURST_LEN),
      .NUM_DQ_PINS                   (NUM_DQ_PINS), 
      .MEM_TYPE                      (MEM_TYPE),
      
      .FAMILY                        (TG_FAMILY),
      .BL_WIDTH            (BL_WIDTH),
      .ADDR_WIDTH                    (ADDR_WIDTH),
      .BEGIN_ADDRESS                 (BEGIN_ADDRESS),
      .END_ADDRESS                   (END_ADDRESS),
      .CMD_SEED_VALUE                (32'h56456783),
      .DATA_SEED_VALUE               (32'h12345678),  
      .DATA_MODE                     (DATA_MODE), 
      .PORT_MODE                     (PORT_MODE) 
    )
   u_init_mem_pattern_ctr
     (
      .clk_i                         (clk),   
      .rst_i                         (rst),     
   
      .memc_cmd_en_i                  (memc_cmd_en),   
      .memc_wr_en_i                   (tg_memc_wr_en), 
   
      .vio_modify_enable             (vio_modify_enable),   
      .vio_instr_mode_value          (vio_instr_mode_value),
      .vio_data_mode_value           (vio_data_mode_value),  
      .vio_addr_mode_value           (vio_addr_mode_value),
      .vio_bl_mode_value             (vio_bl_mode_value),  // always set to PRBS_BL mode
      .vio_fixed_bl_value            (vio_fixed_bl_value),  // always set to 64 in order to run PRBS data pattern
      .vio_data_mask_gen             (vio_data_mask_gen),
      .memc_init_done_i               (memc_init_done),
      .cmp_error                     (error),
      .run_traffic_o                 (tg_run_traffic),  
      .start_addr_o                  (tg_start_addr),
      .end_addr_o                    (tg_end_addr), 
      .cmd_seed_o                    (tg_cmd_seed),  
      .data_seed_o                   (tg_data_seed), 
      .load_seed_o                   (tg_load_seed), 
      .addr_mode_o                   (tg_addr_mode), 
      .instr_mode_o                  (tg_instr_mode), 
      .bl_mode_o                     (tg_bl_mode), 
      .data_mode_o                   (tg_data_mode), 
      .mode_load_o                   (tg_mode_load), 
      .fixed_bl_o                    (tg_fixed_bl), 
      .fixed_instr_o                 (tg_fixed_instr),
      .mem_pattern_init_done_o         (mem_pattern_init_done)
     );
   
   // traffic generator instantiation for Port-0
   memc_traffic_gen #
     (
      .TCQ                           (TCQ),
      .MEM_BURST_LEN                 (MEM_BURST_LEN),  
      .MEM_COL_WIDTH                 (MEM_COL_WIDTH),  
      .NUM_DQ_PINS                   (NUM_DQ_PINS), 
      .nCK_PER_CLK                   (nCK_PER_CLK),
      
      .PORT_MODE                     (PORT_MODE),     
      .DWIDTH                        (DATA_WIDTH),
      .FAMILY                        (TG_FAMILY),    
      .MEM_TYPE                      (MEM_TYPE),
      .SIMULATION                    (SIMULATION),   
      .DATA_PATTERN                  (DATA_PATTERN),  
      .CMD_PATTERN                   (CMD_PATTERN ),  
      .ADDR_WIDTH                    (ADDR_WIDTH),  
      .BL_WIDTH                      (BL_WIDTH),
      .SEL_VICTIM_LINE               (SEL_VICTIM_LINE),
      .PRBS_SADDR_MASK_POS           (BEGIN_ADDRESS), 
      .PRBS_EADDR_MASK_POS           (PRBS_EADDR_MASK_POS),
      .PRBS_SADDR                    (BEGIN_ADDRESS), 
      .PRBS_EADDR                    (END_ADDRESS),
      .EYE_TEST                      (EYE_TEST)
     )  
   u_memc_traffic_gen 
     (  
      .clk_i                         (clk),     
      .rst_i                         (rst),     
      .run_traffic_i                 (tg_run_traffic),                  
      .manual_clear_error            (manual_clear_error),   
      .cmds_gap_delay_value         (cmds_gap_delay_value),
      
      // runtime parameter  
      .mem_pattern_init_done_i       (mem_pattern_init_done),
      
      .start_addr_i                  (tg_start_addr),                  
      .end_addr_i                    (tg_end_addr),                  
      .cmd_seed_i                    (tg_cmd_seed),                  
      .data_seed_i                   (tg_data_seed),                  
      .load_seed_i                   (tg_load_seed),                
      .addr_mode_i                   (tg_addr_mode),                
      .instr_mode_i                  (tg_instr_mode),                  
      .bl_mode_i                     (tg_bl_mode),                  
      .data_mode_i                   (tg_data_mode),                  
      .mode_load_i                   (tg_mode_load), 
      .wr_data_mask_gen_i             (vio_data_mask_gen),
      // fixed pattern inputs interface  
      .fixed_bl_i                    (tg_fixed_bl),                     
      .fixed_instr_i                 (tg_fixed_instr),                     
      .fixed_addr_i                  (fixed_addr_i),                 
      .fixed_data_i                  (fixed_data_i), 
      // BRAM interface. 
      .bram_cmd_i                    (bram_cmd_i),
   //   .bram_addr_i                   (bram_addr_i ),
   //   .bram_instr_i                  ( bram_instr_i),
      .bram_valid_i                  (bram_valid_i),
      .bram_rdy_o                    (bram_rdy_o),  
      
      //  MCB INTERFACE  
      .memc_cmd_en_o                  (memc_cmd_en),                 
      .memc_cmd_instr_o               (memc_cmd_instr),                    
      .memc_cmd_bl_o                  (memc_cmd_bl),                 
      .memc_cmd_addr_o                (memc_cmd_addr),                   
      .memc_cmd_full_i                (memc_cmd_full),                   
   
      .memc_wr_en_o                   (memc_wr_en),     
      .memc_wr_data_end_o             (memc_wr_end), 
      .memc_wr_mask_o                 (memc_wr_mask),                  
      .memc_wr_data_o                 (memc_wr_data),                 
      .memc_wr_full_i                 (memc_wr_full),                  
   
      .memc_rd_en_o                   (memc_rd_en),                
      .memc_rd_data_i                 (memc_rd_data),                  
      .memc_rd_empty_i                (memc_rd_empty),                   
      
      .qdr_wr_cmd_o                  (qdr_wr_cmd_o),
      .qdr_rd_cmd_o                  (qdr_rd_cmd_o),
      // status feedback  
      .counts_rst                    (rst),     
      .wr_data_counts                (), 
      .rd_data_counts                (), 
      .error                         (error),  // asserted whenever the read back data is not correct.  
      .error_status                  (error_status),  // TBD how signals mapped  
      .cmp_data                      (cmp_data),            
      .cmp_data_valid                (cmp_data_valid),                  
      .cmp_error                     (cmp_error),             
      .mem_rd_data                   (), 
      .simple_data0                  (simple_data0),
      .simple_data1                  (simple_data1),
      .simple_data2                  (simple_data2),
      .simple_data3                  (simple_data3),
      .simple_data4                  (simple_data4),
      .simple_data5                  (simple_data5),
      .simple_data6                  (simple_data6),
      .simple_data7                  (simple_data7),
      .dq_error_bytelane_cmp         (), 
      .cumlative_dq_lane_error       (),
      .cumlative_dq_r0_bit_error     (),
      .cumlative_dq_f0_bit_error     (),
      .cumlative_dq_r1_bit_error     (),
      .cumlative_dq_f1_bit_error     (),
      .dq_r0_bit_error_r             (),
      .dq_f0_bit_error_r             (),
      .dq_r1_bit_error_r             (),
      .dq_f1_bit_error_r             (),
      .dq_r0_read_bit                (),
      .dq_f0_read_bit                (),
      .dq_r1_read_bit                (),
      .dq_f1_read_bit                (),
      .dq_r0_expect_bit              (),
      .dq_f0_expect_bit              (),
      .dq_r1_expect_bit              (),
      .dq_f1_expect_bit              (),
      .error_addr                    ()
     );

endmodule
