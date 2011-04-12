//*****************************************************************************
// (c) Copyright 2008 - 2010 Xilinx, Inc. All rights reserved.
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
// /___/  \  /    Vendor                : Xilinx
// \   \   \/     Version               : %version
//  \   \         Application           : MIG
//  /   /         Filename              : mc_phy_wrapper.v
// /___/   /\     Date Last Modified    : $date$
// \   \  /  \    Date Created          : Oct 10 2010
//  \___\/\___\
//
//Device            : 7 Series
//Design Name       : DDR3 SDRAM
//Purpose           : Wrapper file that encompasses the MC_PHY module
//                    instantiation and handles the vector remapping between
//                    the MC_PHY ports and the user's DDR3 ports. Vector
//                    remapping affects DDR3 control, address, and DQ/DQS/DM. 
//Reference         :
//Revision History  :
//*****************************************************************************

`timescale 1 ps / 1 ps

module mc_phy_wrapper #
  (
   parameter TCQ              = 100,    // Register delay (simulation only)
   parameter tCK              = 2500,   // ps
   parameter IODELAY_GRP      = "IODELAY_MIG",
   parameter nCK_PER_CLK      = 4,      // Memory:Logic clock ratio
   parameter nCS_PER_RANK     = 1,      // # of unique CS outputs per rank
   parameter BANK_WIDTH       = 3,      // # of bank address
   parameter CKE_WIDTH        = 1,      // # of clock enable outputs 
   parameter CS_WIDTH         = 1,      // # of chip select
   parameter DDR2_DQSN_ENABLE = "YES",  // Enable differential DQS for DDR2
   parameter DM_WIDTH         = 8,      // # of data mask
   parameter DQ_WIDTH         = 16,     // # of data bits
   parameter DQS_CNT_WIDTH    = 3,      // ceil(log2(DQS_WIDTH))
   parameter DQS_WIDTH        = 8,      // # of strobe pairs
   parameter DRAM_TYPE        = "DDR3", // DRAM type (DDR2, DDR3)
   parameter RANKS            = 4,      // # of ranks
   parameter REG_CTRL        = "OFF",   // "ON" for registered DIMM
   parameter ROW_WIDTH        = 16,     // # of row/column address
   parameter USE_DM_PORT      = 1,      // Support data mask output
   parameter USE_ODT_PORT     = 1,      // Support ODT output
   parameter IBUF_LPWR_MODE   = "OFF",  // input buffer low power option
   // Hard PHY parameters
   parameter PHYCTL_CMD_FIFO = "FALSE",
   parameter DATA_CTL_B0     = 4'hc,
   parameter DATA_CTL_B1     = 4'hf,
   parameter DATA_CTL_B2     = 4'hf,
   parameter DATA_CTL_B3     = 4'hf,
   parameter DATA_CTL_B4     = 4'hf,
   parameter BYTE_LANES_B0   = 4'b1111,
   parameter BYTE_LANES_B1   = 4'b0000,
   parameter BYTE_LANES_B2   = 4'b0000,
   parameter BYTE_LANES_B3   = 4'b0000,
   parameter BYTE_LANES_B4   = 4'b0000,
   parameter PHY_0_BITLANES  = 48'h0000_0000_0000,
   parameter PHY_1_BITLANES  = 48'h0000_0000_0000,
   parameter PHY_2_BITLANES  = 48'h0000_0000_0000,
   // Parameters calculated outside of this block
   parameter HIGHEST_BANK    = 3,        // Highest I/O bank index
   parameter HIGHEST_LANE    = 12,       // Highest byte lane index
   // ** Pin mapping parameters
   // Parameters for mapping between hard PHY and physical DDR3 signals
   // There are 2 classes of parameters:
   //   - DQS_BYTE_MAP, CK_BYTE_MAP, CKE_ODT_BYTE_MAP: These consist of 
   //      8-bit elements. Each element indicates the bank and byte lane 
   //      location of that particular signal. The bit lane in this case 
   //      doesn't need to be specified, either because there's only one 
   //      pin pair in each byte lane that the DQS or CK pair can be 
   //      located at, or in the case of CKE_ODT_BYTE_MAP, only the byte
   //      lane needs to be specified in order to determine which byte
   //      lane generates the RCLK (Note that CKE, and ODT must be located
   //      in the same bank, thus only one element in CKE_ODT_BYTE_MAP)
   //        [7:4] = bank # (0-4)
   //        [3:0] = byte lane # (0-3)
   //   - All other MAP parameters: These consist of 12-bit elements. Each
   //      element indicates the bank, byte lane, and bit lane location of
   //      that particular signal:
   //        [11:8] = bank # (0-4)
   //        [7:4]  = byte lane # (0-3)
   //        [3:0]  = bit lane # (0-11)
   // Note that not all elements in all parameters will be used - it 
   // depends on the actual widths of the DDR3 buses. The parameters are 
   // structured to support a maximum of: 
   //   - DQS groups: 18
   //   - data mask bits: 18
   // In addition, the default parameter size of some of the parameters will
   // support a certain number of bits, however, this can be expanded at 
   // compile time by expanding the width of the vector passed into this 
   // parameter
   //   - chip selects: 10
   //   - bank bits: 3
   //   - address bits: 16
   parameter CK_BYTE_MAP
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00,
   parameter ADDR_MAP    
     = 192'h000_000_000_000_000_000_000_000_000_000_000_000_000_000_000_000,
   parameter BANK_MAP   = 36'h000_000_000,
   parameter CAS_MAP    = 12'h000,
   parameter CKE_ODT_BYTE_MAP = 8'h00,
   parameter CS_MAP     = 120'h000_000_000_000_000_000_000_000_000_000,
   parameter PARITY_MAP = 12'h000,
   parameter RAS_MAP    = 12'h000,
   parameter WE_MAP     = 12'h000,
   parameter DQS_BYTE_MAP         
     = 144'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00,
   // DATAx_MAP parameter is used for byte lane X in the design
   parameter DATA0_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA1_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA2_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA3_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA4_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA5_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA6_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA7_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA8_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA9_MAP  = 96'h000_000_000_000_000_000_000_000,
   parameter DATA10_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA11_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA12_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA13_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA14_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA15_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA16_MAP = 96'h000_000_000_000_000_000_000_000,
   parameter DATA17_MAP = 96'h000_000_000_000_000_000_000_000,
   // MASK0_MAP used for bytes [8:0], MASK1_MAP for bytes [17:9]
   parameter MASK0_MAP  = 108'h000_000_000_000_000_000_000_000_000,
   parameter MASK1_MAP  = 108'h000_000_000_000_000_000_000_000_000
  )
  (
   input                               rst,
   input                               clk,
   input                               freq_refclk,
   input                               mem_refclk,
   input                               pll_lock,
   input                               sync_pulse,
   input                               idelayctrl_refclk,
   input                               phy_cmd_wr_en,
   input                               phy_data_wr_en,
   input [31:0]                        phy_ctl_wd,
   input                               phy_ctl_wr,
   input [3:0]                         aux_in_1,
   input [3:0]                         aux_in_2,
   output                              if_empty,
   output                              phy_ctl_full,
   output                              phy_cmd_full,
   output                              phy_data_full,
   output [1:0]                        ddr_clk,
   output                              phy_mc_go,          
   input                               phy_write_calib,
   input                               phy_read_calib,
   input                               calib_in_common,
//   input [DQS_CNT_WIDTH:0]           byte_sel_cnt,
   input [5:0]                         calib_sel,
   input [HIGHEST_BANK-1:0]            calib_zero_inputs,
   input                               po_fine_enable,
   input                               po_coarse_enable,
   input                               po_fine_inc,
   input                               po_coarse_inc,
   input                               po_counter_load_en,
   input                               po_sel_fine_oclk_delay,
   input [8:0]                         po_counter_load_val,
   input                               pi_rst_dqs_find,
   input                               pi_fine_enable,
   input                               pi_fine_inc,
   input                               pi_counter_load_en,
   input [5:0]                         pi_counter_load_val,
   output                              pi_phase_locked,
   output                              pi_phase_locked_all,
   output                              pi_dqs_found,
   output                              pi_dqs_found_all,
   output                              pi_dqs_out_of_range,
   // From/to calibration logic/soft PHY
   input                                         phy_init_data_sel,
   input [nCK_PER_CLK*ROW_WIDTH-1:0]             mux_address,
   input [nCK_PER_CLK*BANK_WIDTH-1:0]            mux_bank, 
   input [nCK_PER_CLK-1:0]                       mux_cas_n,
   input [CS_WIDTH*nCS_PER_RANK*nCK_PER_CLK-1:0] mux_cs_n,
   input [nCK_PER_CLK-1:0]                       mux_ras_n,
   input [nCK_PER_CLK-1:0]                       mux_we_n,   
   input [nCK_PER_CLK-1:0]                       parity_in,
   input [2*nCK_PER_CLK*DQ_WIDTH-1:0]            mux_wrdata,
   input [2*nCK_PER_CLK*(DQ_WIDTH/8)-1:0]        mux_wrdata_mask,   
   output [2*nCK_PER_CLK*DQ_WIDTH-1:0]           rd_data,
   // Memory I/F
   output [ROW_WIDTH-1:0]                        ddr_addr,
   output [BANK_WIDTH-1:0]                       ddr_ba,
   output                                        ddr_cas_n,
   output [CKE_WIDTH-1:0]                        ddr_cke,
   output [CS_WIDTH*nCS_PER_RANK-1:0]            ddr_cs_n,
   output [DM_WIDTH-1:0]                         ddr_dm,
   output [RANKS-1:0]                            ddr_odt,
   output                                        ddr_parity,
   output                                        ddr_ras_n,
   output                                        ddr_we_n,
   inout [DQ_WIDTH-1:0]                          ddr_dq,
   inout [DQS_WIDTH-1:0]                         ddr_dqs,
   inout [DQS_WIDTH-1:0]                         ddr_dqs_n
   );

  // Enable low power mode for input buffer
  localparam IBUF_LOW_PWR
             = (IBUF_LPWR_MODE == "OFF") ? "FALSE" :
             ((IBUF_LPWR_MODE == "ON")  ? "TRUE" : "ILLEGAL");

  // Ratio of data to strobe
  localparam DQ_PER_DQS = DQ_WIDTH / DQS_WIDTH;
  // number of data phases per internal clock
  localparam PHASE_PER_CLK = 2*nCK_PER_CLK;
  // used to determine routing to OUT_FIFO for control/address for 2:1
  // vs. 4:1 memory:internal clock ratio modes
  localparam PHASE_DIV = 4 / nCK_PER_CLK;

  // Create an aggregate parameters for data mapping to reduce # of generate
  // statements required in remapping code. Need to account for the case
  // when the DQ:DQS ratio is not 8:1 - in this case, each DATAx_MAP 
  // parameter will have fewer than 8 elements used 
  localparam FULL_DATA_MAP = {DATA17_MAP[12*DQ_PER_DQS-1:0], 
                              DATA16_MAP[12*DQ_PER_DQS-1:0], 
                              DATA15_MAP[12*DQ_PER_DQS-1:0], 
                              DATA14_MAP[12*DQ_PER_DQS-1:0], 
                              DATA13_MAP[12*DQ_PER_DQS-1:0], 
                              DATA12_MAP[12*DQ_PER_DQS-1:0], 
                              DATA11_MAP[12*DQ_PER_DQS-1:0], 
                              DATA10_MAP[12*DQ_PER_DQS-1:0], 
                              DATA9_MAP[12*DQ_PER_DQS-1:0],  
                              DATA8_MAP[12*DQ_PER_DQS-1:0],  
                              DATA7_MAP[12*DQ_PER_DQS-1:0],  
                              DATA6_MAP[12*DQ_PER_DQS-1:0],
                              DATA5_MAP[12*DQ_PER_DQS-1:0],  
                              DATA4_MAP[12*DQ_PER_DQS-1:0],  
                              DATA3_MAP[12*DQ_PER_DQS-1:0],  
                              DATA2_MAP[12*DQ_PER_DQS-1:0],  
                              DATA1_MAP[12*DQ_PER_DQS-1:0],  
                              DATA0_MAP[12*DQ_PER_DQS-1:0]};
  // Same deal, but for data mask mapping
  localparam FULL_MASK_MAP = {MASK1_MAP, MASK0_MAP};

  // Temporary parameters to determine which bank is outputting the CK/CK#
  // Eventually there will be support for multiple CK/CK# output
  localparam TMP_DDR_CLK_SELECT_BANK = (CK_BYTE_MAP[7:4]);
  // Temporary method to force MC_PHY to generate ODDR associated with
  // CK/CK# output only for a single byte lane in the design. All banks
  // that won't be generating the CK/CK# will have "UNUSED" as their
  // PHY_GENERATE_DDR_CK parameter
  localparam TMP_PHY_0_GENERATE_DDR_CK 
             = (TMP_DDR_CLK_SELECT_BANK != 0) ? "UNUSED" : 
                ((CK_BYTE_MAP[1:0] == 2'b00) ? "A" :
                 ((CK_BYTE_MAP[1:0] == 2'b01) ? "B" :
                  ((CK_BYTE_MAP[1:0] == 2'b10) ? "C" : "D")));
  localparam TMP_PHY_1_GENERATE_DDR_CK 
             = (TMP_DDR_CLK_SELECT_BANK != 1) ? "UNUSED" : 
                ((CK_BYTE_MAP[1:0] == 2'b00) ? "A" :
                 ((CK_BYTE_MAP[1:0] == 2'b01) ? "B" :
                  ((CK_BYTE_MAP[1:0] == 2'b10) ? "C" : "D")));
  localparam TMP_PHY_2_GENERATE_DDR_CK 
             = (TMP_DDR_CLK_SELECT_BANK != 2) ? "UNUSED" : 
                ((CK_BYTE_MAP[1:0] == 2'b00) ? "A" :
                 ((CK_BYTE_MAP[1:0] == 2'b01) ? "B" :
                  ((CK_BYTE_MAP[1:0] == 2'b10) ? "C" : "D")));

  // Function to generate MC_PHY parameter from data mask map parameter
  function [143:0] calc_phy_bitlanes_outonly;
    input [215:0] data_mask_in;
    integer       z;
    begin
      calc_phy_bitlanes_outonly = 'b0;
      for (z = 0; z < DM_WIDTH; z = z + 1)
        calc_phy_bitlanes_outonly[48*data_mask_in[(12*z+8)+:3] + 
                                  12*data_mask_in[(12*z+4)+:2] + 
                                  data_mask_in[12*z+:4]] = 1'b1;
    end 
  endfunction

  localparam PHY_BITLANES_OUTONLY   = calc_phy_bitlanes_outonly(FULL_MASK_MAP);
  localparam PHY_0_BITLANES_OUTONLY = PHY_BITLANES_OUTONLY[47:0];
  localparam PHY_1_BITLANES_OUTONLY = PHY_BITLANES_OUTONLY[95:48];
  localparam PHY_2_BITLANES_OUTONLY = PHY_BITLANES_OUTONLY[143:96];

  // Determine which bank and byte lane generates the RCLK used to clock
  // out the auxilliary (ODT, CKE) outputs
  localparam CKE_ODT_RCLK_SELECT_BANK 
             = (CKE_ODT_BYTE_MAP[7:4] == 4'h0) ? 0 :
                 ((CKE_ODT_BYTE_MAP[7:4] == 4'h1) ? 1 :
                  ((CKE_ODT_BYTE_MAP[7:4] == 4'h2) ? 2 :
                   ((CKE_ODT_BYTE_MAP[7:4] == 4'h3) ? 3 :
                    ((CKE_ODT_BYTE_MAP[7:4] == 4'h4) ? 4 : -1))));
  localparam CKE_ODT_RCLK_SELECT_LANE
             = (CKE_ODT_BYTE_MAP[3:0] == 4'h0) ? "A" :
                 ((CKE_ODT_BYTE_MAP[3:0] == 4'h1) ? "B" :
                  ((CKE_ODT_BYTE_MAP[3:0] == 4'h2) ? "C" :
                   ((CKE_ODT_BYTE_MAP[3:0] == 4'h3) ? "D" : "ILLEGAL")));
  
  // OCLKDELAYED tap setting calculation:
  // Parameters for calculating amount of phase shifting output clock to
  // achieve 90 degree offset between DQS and DQ on writes
  localparam PO_OCLKDELAY_INV = "TRUE";
  localparam PHY_0_A_PI_FREQ_REF_DIV = tCK > 2500 ?  "DIV2" : "NONE";
  localparam real FREQ_REF_MHZ 
             =  1.0/((tCK/(PHY_0_A_PI_FREQ_REF_DIV == "DIV2" ? 2 : 1) / 
                      1000.0) / 1000) ;
  localparam real MC_OCLK_DELAY2 = FREQ_REF_MHZ/10000.0 + 0.4548;
  localparam real MC_OCLK_DELAY3 
             = ((0.25 * (PHY_0_A_PI_FREQ_REF_DIV == "DIV2" ? 2 : 1)) - 
                MC_OCLK_DELAY2 - (PO_OCLKDELAY_INV == "TRUE"  ? 1 : 0) * 0.5) ;
  localparam real MC_OCLK_DELAY4 
             = (MC_OCLK_DELAY3 + (MC_OCLK_DELAY3 < 0 )+0) * 64;
  localparam real MC_OCLK_DELAY 
             = MC_OCLK_DELAY4 + ((tCK < 1900 ) || tCK > 3000) ;
  // Value expressed as fraction of a full tCK period  
  localparam real SHIFT = (1 + 0.3);
  // Value expressed as fraction of a full tCK period
  localparam real OCLK_INTRINSIC_DELAY  
             = (tCK < 1000) ? 0.708 :
                ((tCK < 1100) ? 0.748 :
                 ((tCK < 1300) ? 0.742 :
                  ((tCK < 1600) ? 0.709 :
                   ((tCK < 2500) ? 0.637 : 0.425))));
  
  // OCLK_DELAYED due to inversion
  localparam real OCLK_DELAY_INV_DELAY 
             = (PO_OCLKDELAY_INV == "TRUE") ? 0.5 : 0;  
  localparam real OCLK_DELAY_PERCENT 
             = (SHIFT - OCLK_INTRINSIC_DELAY - OCLK_DELAY_INV_DELAY) * 100;
  localparam integer PHY_0_A_PO_OCLK_DELAY = MC_OCLK_DELAY + 0.5;

  // IDELAY value
  localparam PHY_0_A_IDELAYE2_IDELAY_VALUE 
             = (tCK < 1000) ? 0 :
                ((tCK < 1330) ? 1 :
                 ((tCK < 2300) ? 3 :
                  ((tCK < 2500) ? 5 : 6)));
  
  /*localparam PHY_0_A_IDELAYE2_IDELAY_VALUE 
             = (tCK < 1000) ? 4 :
                ((tCK < 1330) ? 5 :
                 ((tCK < 2300) ? 7 :
                  ((tCK < 2500) ? 9 : 10)));*/
  
  // Aux_out parameters RD_CMD_OFFSET = CL+2? and WR_CMD_OFFSET = CWL+3?
  localparam PHY_0_RD_CMD_OFFSET_0 = 10;  //8
  localparam PHY_0_RD_CMD_OFFSET_1 = 10;  //8
  localparam PHY_0_RD_CMD_OFFSET_2 = 10;  //8
  localparam PHY_0_RD_CMD_OFFSET_3 = 10;  //8
  localparam PHY_0_WR_CMD_OFFSET_0 = 10;  //8
  localparam PHY_0_WR_CMD_OFFSET_1 = 10;  //8
  localparam PHY_0_WR_CMD_OFFSET_2 = 10;  //8
  localparam PHY_0_WR_CMD_OFFSET_3 = 10;  //8
    
  wire [((HIGHEST_LANE+3)/4)*4-1:0] aux_out;
  wire [HIGHEST_LANE-1:0]           mem_dqs_in;
  wire [HIGHEST_LANE-1:0]           mem_dqs_out;
  wire [HIGHEST_LANE-1:0]           mem_dqs_ts;
  wire [HIGHEST_LANE*10-1:0]        mem_dq_in;
  wire [HIGHEST_LANE*12-1:0]        mem_dq_out;
  wire [HIGHEST_LANE*12-1:0]        mem_dq_ts;
  wire [DQ_WIDTH-1:0]               in_dq;
  wire [DQS_WIDTH-1:0]              in_dqs;
  wire [ROW_WIDTH-1:0]              out_addr;  
  wire [BANK_WIDTH-1:0]             out_ba;
  wire                              out_cas_n;
  wire [CS_WIDTH*nCS_PER_RANK-1:0]  out_cs_n;
  wire [DM_WIDTH-1:0]               out_dm;
  wire [DQ_WIDTH-1:0]               out_dq;
  wire [DQS_WIDTH-1:0]              out_dqs;
  wire                              out_parity;
  wire                              out_ras_n;
  wire                              out_we_n;
  wire [HIGHEST_LANE*80-1:0]        phy_din;
  wire [HIGHEST_LANE*80-1:0]        phy_dout;
  wire [DM_WIDTH-1:0]               ts_dm;  
  wire [DQ_WIDTH-1:0]               ts_dq;  
  wire [DQS_WIDTH-1:0]              ts_dqs;

  //***************************************************************************
  // Auxiliary output steering
  //***************************************************************************

  // For a 4 rank I/F the aux_out[3:0] from the addr/ctl bank will be 
  // mapped to ddr_odt and the aux_out[7:4] from one of the data banks
  // will map to ddr_cke. For I/Fs less than 4 the aux_out[3:0] from the
  // addr/ctl bank would bank would map to both ddr_odt and ddr_cke.
  generate
    if (RANKS == 1) begin : gen_cke_odt
      assign ddr_cke = aux_out[0];
      if (USE_ODT_PORT == 1) begin: gen_use_odt
        assign ddr_odt = aux_out[1];
      end else begin
        assign ddr_odt = 1'b0;
      end
    end else begin: gen_2rank_cke_odt
      assign ddr_cke = {aux_out[2],aux_out[0]};
      if (USE_ODT_PORT == 1) begin: gen_use_odt
        assign ddr_odt = {aux_out[3],aux_out[1]};
      end else begin
        assign ddr_odt = 2'b00; 
      end
    end
  endgenerate

  //***************************************************************************
  // Read data bit steering
  //***************************************************************************

  // Transpose elements of rd_data_map to form final read data output:
  // phy_din elements are grouped according to "physical bit" - e.g.
  // for nCK_PER_CLK = 4, there are 8 data phases transfered per physical
  // bit per clock cycle: 
  //   = {dq0_fall3, dq0_rise3, dq0_fall2, dq0_rise2, 
  //      dq0_fall1, dq0_rise1, dq0_fall0, dq0_rise0}
  // whereas rd_data is are grouped according to "phase" - e.g.
  //   = {dq7_rise0, dq6_rise0, dq5_rise0, dq4_rise0,
  //      dq3_rise0, dq2_rise0, dq1_rise0, dq0_rise0}
  // therefore rd_data is formed by transposing phy_din - e.g.
  //   for nCK_PER_CLK = 4, and DQ_WIDTH = 16, and assuming MC_PHY 
  //   bit_lane[0] maps to DQ[0], and bit_lane[1] maps to DQ[1], then 
  //   the assignments for bits of rd_data corresponding to DQ[1:0]
  //   would be:      
  //    {rd_data[112], rd_data[96], rd_data[80], rd_data[64],
  //     rd_data[48], rd_data[32], rd_data[16], rd_data[0]} = phy_din[7:0]
  //    {rd_data[113], rd_data[97], rd_data[81], rd_data[65],
  //     rd_data[49], rd_data[33], rd_data[17], rd_data[1]} = phy_din[15:8]   
  generate
    genvar i, j;  
    for (i = 0; i < DQ_WIDTH; i = i + 1) begin: gen_loop_rd_data_1
      for (j = 0; j < PHASE_PER_CLK; j = j + 1) begin: gen_loop_rd_data_2
        assign rd_data[DQ_WIDTH*j + i] 
                 = phy_din[(320*FULL_DATA_MAP[(12*i+8)+:3]+
                            80*FULL_DATA_MAP[(12*i+4)+:2] +
                            8*FULL_DATA_MAP[12*i+:4]) + j];
      end
    end
  endgenerate
  
  //***************************************************************************
  // Control/address
  //***************************************************************************

  assign out_cas_n
    = mem_dq_out[48*CAS_MAP[10:8] + 12*CAS_MAP[5:4] + CAS_MAP[3:0]];
  
  generate
    // if signal placed on bit lanes [0-9]    
    if (CAS_MAP[3:0] < 4'hA) begin: gen_cas_lt10
      // Determine routing based on clock ratio mode. If running in 4:1
      // mode, then all four bits from logic are used. If 2:1 mode, only
      // 2-bits are provided by logic, and each bit is repeated 2x to form
      // 4-bit input to IN_FIFO, e.g.
      //   4:1 mode: phy_dout[] = {in[3], in[2], in[1], in[0]}
      //   2:1 mode: phy_dout[] = {in[1], in[1], in[0], in[0]}
      assign phy_dout[(320*CAS_MAP[10:8] + 80*CAS_MAP[5:4] + 
                       8*CAS_MAP[3:0])+:4] 
               = {mux_cas_n[3/PHASE_DIV], mux_cas_n[2/PHASE_DIV],
                  mux_cas_n[1/PHASE_DIV], mux_cas_n[0]};
    end else begin: gen_cas_ge10
      // If signal is placed in bit lane [10] or [11], route to upper
      // nibble of phy_dout lane [5] or [6] respectively (in this case
      // phy_dout lane [5, 6] are multiplexed to take input for two
      // different SDR signals - this is how bits[10,11] need to be
      // provided to the OUT_FIFO
      assign phy_dout[(320*CAS_MAP[10:8] + 80*CAS_MAP[5:4] + 
                       8*(CAS_MAP[3:0]-5) + 4)+:4] 
               = {mux_cas_n[3/PHASE_DIV], mux_cas_n[2/PHASE_DIV],
                  mux_cas_n[1/PHASE_DIV], mux_cas_n[0]};
    end
  endgenerate

  assign out_ras_n
    = mem_dq_out[48*RAS_MAP[10:8] + 12*RAS_MAP[5:4] + RAS_MAP[3:0]];
  
  generate
    if (RAS_MAP[3:0] < 4'hA) begin: gen_ras_lt10
      assign phy_dout[(320*RAS_MAP[10:8] + 80*RAS_MAP[5:4] + 
                       8*RAS_MAP[3:0])+:4]
               = {mux_ras_n[3/PHASE_DIV], mux_ras_n[2/PHASE_DIV],
                  mux_ras_n[1/PHASE_DIV], mux_ras_n[0]};
    end else begin: gen_ras_ge10
      assign phy_dout[(320*RAS_MAP[10:8] + 80*RAS_MAP[5:4] + 
                       8*(RAS_MAP[3:0]-5) + 4)+:4] 
               = {mux_ras_n[3/PHASE_DIV], mux_ras_n[2/PHASE_DIV],
                  mux_ras_n[1/PHASE_DIV], mux_ras_n[0]};
    end
  endgenerate

  assign out_we_n
    = mem_dq_out[48*WE_MAP[10:8] + 12*WE_MAP[5:4] + WE_MAP[3:0]];
  
  generate
    if (WE_MAP[3:0] < 4'hA) begin: gen_we_lt10
      assign phy_dout[(320*WE_MAP[10:8] + 80*WE_MAP[5:4] + 
                       8*WE_MAP[3:0])+:4] 
               = {mux_we_n[3/PHASE_DIV], mux_we_n[2/PHASE_DIV],
                  mux_we_n[1/PHASE_DIV], mux_we_n[0]};
    end else begin: gen_we_ge10
      assign phy_dout[(320*WE_MAP[10:8] + 80*WE_MAP[5:4] + 
                       8*(WE_MAP[3:0]-5) + 4)+:4] 
               = {mux_we_n[3/PHASE_DIV], mux_we_n[2/PHASE_DIV],
                  mux_we_n[1/PHASE_DIV], mux_we_n[0]};
    end
  endgenerate
  
  generate
    if ((DRAM_TYPE == "DDR3") && (REG_CTRL == "ON")) begin: gen_parity_out
      // Generate addr/ctrl parity output only for DDR3 registered DIMMs
      assign out_parity
        = mem_dq_out[48*PARITY_MAP[10:8] + 12*PARITY_MAP[5:4] + 
                     PARITY_MAP[3:0]];
      if (PARITY_MAP[3:0] < 4'hA) begin: gen_lt10
        assign phy_dout[(320*PARITY_MAP[10:8] + 80*PARITY_MAP[5:4] + 
                         8*PARITY_MAP[3:0])+:4] 
                 = {parity_in[3/PHASE_DIV], parity_in[2/PHASE_DIV],
                    parity_in[1/PHASE_DIV], parity_in[0]};                 
      end else begin: gen_ge10
        assign phy_dout[(320*PARITY_MAP[10:8] + 80*PARITY_MAP[5:4] + 
                         8*(PARITY_MAP[3:0]-5) + 4)+:4] 
               = {parity_in[3/PHASE_DIV], parity_in[2/PHASE_DIV],
                  parity_in[1/PHASE_DIV], parity_in[0]};
      end
    end
  endgenerate
  
  //*****************************************************************  
  
  generate
    genvar m, n;  

    //*****************************************************************
    // Control/address (multi-bit) buses
    //*****************************************************************

    // Row/Column address
    for (m = 0; m < ROW_WIDTH; m = m + 1) begin: gen_addr_out
      assign out_addr[m]
               = mem_dq_out[48*ADDR_MAP[(12*m+8)+:3] + 
                            12*ADDR_MAP[(12*m+4)+:2] + 
                            ADDR_MAP[12*m+:4]];
      
      if (ADDR_MAP[12*m+:4] < 4'hA) begin: gen_lt10
        // For multi-bit buses, we also have to deal with transposition 
        // when going from the logic-side control bus to phy_dout
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*ADDR_MAP[(12*m+8)+:3] + 
                          80*ADDR_MAP[(12*m+4)+:2] + 
                          8*ADDR_MAP[12*m+:4] + n]
                   = mux_address[ROW_WIDTH*(n/PHASE_DIV) + m];
        end
      end else begin: gen_ge10 
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*ADDR_MAP[(12*m+8)+:3] + 
                          80*ADDR_MAP[(12*m+4)+:2] + 
                          8*(ADDR_MAP[12*m+:4]-5) + 4 + n]
                   = mux_address[ROW_WIDTH*(n/PHASE_DIV) + m];
        end
      end
    end

    // Bank address
    for (m = 0; m < BANK_WIDTH; m = m + 1) begin: gen_ba_out
        assign out_ba[m]
                 = mem_dq_out[48*BANK_MAP[(12*m+8)+:3] + 
                              12*BANK_MAP[(12*m+4)+:2] + 
                              BANK_MAP[12*m+:4]];

      if (BANK_MAP[12*m+:4] < 4'hA) begin: gen_lt10
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*BANK_MAP[(12*m+8)+:3] + 
                          80*BANK_MAP[(12*m+4)+:2] + 
                          8*BANK_MAP[12*m+:4] + n]
                   = mux_bank[BANK_WIDTH*(n/PHASE_DIV) + m];
        end
      end else begin: gen_ge10 
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*BANK_MAP[(12*m+8)+:3] + 
                          80*BANK_MAP[(12*m+4)+:2] + 
                          8*(BANK_MAP[12*m+:4]-5) + 4 + n]
                   = mux_bank[BANK_WIDTH*(n/PHASE_DIV) + m];
        end
      end
    end
    
    // Chip select     
    for (m = 0; m < CS_WIDTH*nCS_PER_RANK; m = m + 1) begin: gen_cs_out
      assign out_cs_n[m]
               = mem_dq_out[48*CS_MAP[(12*m+8)+:3] + 
                            12*CS_MAP[(12*m+4)+:2] + 
                            CS_MAP[12*m+:4]];
      if (CS_MAP[12*m+:4] < 4'hA) begin: gen_lt10
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*CS_MAP[(12*m+8)+:3] + 
                          80*CS_MAP[(12*m+4)+:2] + 
                          8*CS_MAP[12*m+:4] + n]
                   = mux_cs_n[CS_WIDTH*nCS_PER_RANK*(n/PHASE_DIV) + m];
        end
      end else begin: gen_ge10 
        for (n = 0; n < 4; n = n + 1) begin: loop_xpose
          assign phy_dout[320*CS_MAP[(12*m+8)+:3] + 
                          80*CS_MAP[(12*m+4)+:2] + 
                          8*(CS_MAP[12*m+:4]-5) + 4 + n]
                   = mux_cs_n[CS_WIDTH*nCS_PER_RANK*(n/PHASE_DIV) + m];
        end
      end
    end
    
    //*****************************************************************
    // Data mask
    //*****************************************************************

    if (USE_DM_PORT == 1) begin: gen_dm_out
      for (m = 0; m < DM_WIDTH; m = m + 1) begin: gen_dm_out
        assign out_dm[m]
                 = mem_dq_out[48*FULL_MASK_MAP[(12*m+8)+:3] + 
                              12*FULL_MASK_MAP[(12*m+4)+:2] + 
                              FULL_MASK_MAP[12*m+:4]];
        assign ts_dm[m]
                 = mem_dq_ts[48*FULL_MASK_MAP[(12*m+8)+:3] + 
                             12*FULL_MASK_MAP[(12*m+4)+:2] + 
                             FULL_MASK_MAP[12*m+:4]];           
        for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_xpose
          assign phy_dout[320*FULL_MASK_MAP[(12*m+8)+:3] + 
                          80*FULL_MASK_MAP[(12*m+4)+:2] + 
                          8*FULL_MASK_MAP[12*m+:4] + n]
                   = mux_wrdata_mask[DM_WIDTH*n + m];     
        end
      end
    end

    //*****************************************************************
    // Input and output DQ
    //*****************************************************************
  
    for (m = 0; m < DQ_WIDTH; m = m + 1) begin: gen_dq_inout
      // to MC_PHY
      assign mem_dq_in[40*FULL_DATA_MAP[(12*m+8)+:3] + 
                       10*FULL_DATA_MAP[(12*m+4)+:2] + 
                       FULL_DATA_MAP[12*m+:4]] 
               = in_dq[m];
      // to I/O buffers
      assign out_dq[m]
               = mem_dq_out[48*FULL_DATA_MAP[(12*m+8)+:3] + 
                            12*FULL_DATA_MAP[(12*m+4)+:2] + 
                            FULL_DATA_MAP[12*m+:4]];
      assign ts_dq[m]
               = mem_dq_ts[48*FULL_DATA_MAP[(12*m+8)+:3] + 
                           12*FULL_DATA_MAP[(12*m+4)+:2] + 
                           FULL_DATA_MAP[12*m+:4]];   
      for (n = 0; n < PHASE_PER_CLK; n = n + 1) begin: loop_xpose
        assign phy_dout[320*FULL_DATA_MAP[(12*m+8)+:3] + 
                        80*FULL_DATA_MAP[(12*m+4)+:2] + 
                        8*FULL_DATA_MAP[12*m+:4] + n]
                 = mux_wrdata[DQ_WIDTH*n + m];     
      end
    end

    //*****************************************************************
    // Input and output DQS
    //*****************************************************************

    for (m = 0; m < DQS_WIDTH; m = m + 1) begin: gen_dqs_inout
      // to MC_PHY
      assign mem_dqs_in[4*DQS_BYTE_MAP[(8*m+4)+:3] + DQS_BYTE_MAP[(8*m)+:2]]
        = in_dqs[m];
      // to I/O buffers
      assign out_dqs[m]
        = mem_dqs_out[4*DQS_BYTE_MAP[(8*m+4)+:3] + DQS_BYTE_MAP[(8*m)+:2]];
      assign ts_dqs[m]
        = mem_dqs_ts[4*DQS_BYTE_MAP[(8*m+4)+:3] + DQS_BYTE_MAP[(8*m)+:2]];
    end
  endgenerate
  
  //***************************************************************************
  // Memory I/F output and I/O buffer instantiation
  //***************************************************************************

  // Note on instantiation - generally at the minimum, it's not required to 
  // instantiate the output buffers - they can be inferred by the synthesis
  // tool, and there aren't any attributes that need to be associated with
  // them. Consider as a future option to take out the OBUF instantiations
  
  OBUF u_cas_n_obuf
    (
     .I (out_cas_n),
     .O (ddr_cas_n)
     );

  OBUF u_ras_n_obuf
    (
     .I (out_ras_n),
     .O (ddr_ras_n)
     );  

  OBUF u_we_n_obuf
    (
     .I (out_we_n),
     .O (ddr_we_n)
     );  
  
  generate
    genvar p;

    for (p = 0; p < ROW_WIDTH; p = p + 1) begin: gen_addr_obuf
      OBUF u_addr_obuf
        (
         .I (out_addr[p]),
         .O (ddr_addr[p])
         );      
    end

    for (p = 0; p < BANK_WIDTH; p = p + 1) begin: gen_bank_obuf
      OBUF u_bank_obuf
        (
         .I (out_ba[p]),
         .O (ddr_ba[p])
         );      
    end

    for (p = 0; p < CS_WIDTH*nCS_PER_RANK; p = p + 1) begin: gen_cs_obuf
      OBUF u_cs_n_obuf
        (
         .I (out_cs_n[p]),
         .O (ddr_cs_n[p])
         );      
    end

    if ((DRAM_TYPE == "DDR3") && (REG_CTRL == "ON")) begin: gen_parity_obuf
      // Generate addr/ctrl parity output only for DDR3 registered DIMMs
      OBUF u_parity_obuf
        (
         .I (out_parity),
         .O (ddr_parity)
         );
    end else begin: gen_parity_tieoff
      assign ddr_parity = 1'b0;
    end
    
    if (USE_DM_PORT == 1) begin: gen_dm_obuf
      for (p = 0; p < DM_WIDTH; p = p + 1) begin: loop_dm
        OBUFT u_dm_obuf
          (
           .I (out_dm[p]),
           .T (ts_dm[p]),
           .O (ddr_dm[p])
           );      
      end      
    end else begin: gen_dm_tieoff
      assign ddr_dm = 'b0;
    end      

    for (p = 0; p < DQ_WIDTH; p = p + 1) begin: gen_dq_iobuf
      IOBUF #
        (
         .IBUF_LOW_PWR (IBUF_LOW_PWR)
         )
        u_iobuf_dq
          (
           .I  (out_dq[p]),       
           .T  (ts_dq[p]),
           .O  (in_dq[p]),
           .IO (ddr_dq[p])
           );
    end

    for (p = 0; p < DQS_WIDTH; p = p + 1) begin: gen_dqs_iobuf
      if ((DRAM_TYPE == "DDR2") && 
          (DDR2_DQSN_ENABLE != "YES")) begin: gen_ddr2_dqs_se
        IOBUF #
          (
           .IBUF_LOW_PWR (IBUF_LOW_PWR)
           )
          u_iobuf_dqs
            (
             .I   (out_dqs[p]),       
             .T   (ts_dqs[p]),
             .O   (in_dqs[p]),
             .IO  (ddr_dqs[p])
             );
        assign ddr_dqs_n[p] = 1'b0;
      end else begin: gen_dqs_diff
        IOBUFDS #
          (
           .IBUF_LOW_PWR (IBUF_LOW_PWR)
           )
          u_iobuf_dqs
            (
             .I   (out_dqs[p]),       
             .T   (ts_dqs[p]),
             .O   (in_dqs[p]),
             .IO  (ddr_dqs[p]),
             .IOB (ddr_dqs_n[p])
             );
      end
    end
    
  endgenerate

  //***************************************************************************
  // Hard PHY instantiation
  //***************************************************************************

  mc_phy #
    (
     .PHYCTL_CMD_FIFO               ("FALSE"),
     .PHY_SYNC_MODE                 ("TRUE"),
     .PHY_DISABLE_SEQ_MATCH         ("FALSE"),
     .PHY_0_A_PI_FREQ_REF_DIV       (PHY_0_A_PI_FREQ_REF_DIV),
     .DATA_CTL_B0                   (DATA_CTL_B0),
     .DATA_CTL_B1                   (DATA_CTL_B1),
     .DATA_CTL_B2                   (DATA_CTL_B2),
     .DATA_CTL_B3                   (DATA_CTL_B3),
     .DATA_CTL_B4                   (DATA_CTL_B4),
     .BYTE_LANES_B0                 (BYTE_LANES_B0),
     .BYTE_LANES_B1                 (BYTE_LANES_B1),
     .BYTE_LANES_B2                 (BYTE_LANES_B2),
     .BYTE_LANES_B3                 (BYTE_LANES_B3),
     .BYTE_LANES_B4                 (BYTE_LANES_B4),
     .PHY_0_BITLANES                (PHY_0_BITLANES),
     .PHY_1_BITLANES                (PHY_1_BITLANES),
     .PHY_2_BITLANES                (PHY_2_BITLANES),
     .PHY_0_BITLANES_OUTONLY        (PHY_0_BITLANES_OUTONLY),
     .PHY_1_BITLANES_OUTONLY        (PHY_1_BITLANES_OUTONLY),
     .PHY_2_BITLANES_OUTONLY        (PHY_2_BITLANES_OUTONLY),
     .RCLK_SELECT_BANK              (CKE_ODT_RCLK_SELECT_BANK),
     .RCLK_SELECT_LANE              (CKE_ODT_RCLK_SELECT_LANE),
     .DDR_CLK_SELECT_BANK           (TMP_DDR_CLK_SELECT_BANK),
     .PHY_0_GENERATE_DDR_CK         (TMP_PHY_0_GENERATE_DDR_CK),
     .PHY_1_GENERATE_DDR_CK         (TMP_PHY_1_GENERATE_DDR_CK),
     .PHY_2_GENERATE_DDR_CK         (TMP_PHY_2_GENERATE_DDR_CK),
     .PHY_EVENTS_DELAY              (63),
     .PHY_FOUR_WINDOW_CLOCKS        (18),
     .PHY_0_A_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_0_B_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_0_C_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_0_D_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_1_A_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_1_B_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_1_C_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_1_D_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_2_A_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_2_B_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_2_C_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_2_D_PO_OCLK_DELAY         (PHY_0_A_PO_OCLK_DELAY),
     .PHY_0_A_PO_OCLKDELAY_INV      (PO_OCLKDELAY_INV),
     .PHY_0_A_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_0_B_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_0_C_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_0_D_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_1_A_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_1_B_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_1_C_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_1_D_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_2_A_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_2_B_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_2_C_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_2_D_IDELAYE2_IDELAY_VALUE (PHY_0_A_IDELAYE2_IDELAY_VALUE),
     .PHY_0_RD_DURATION_0           (6),
     .PHY_0_RD_DURATION_1           (6),
     .PHY_0_RD_DURATION_2           (6),
     .PHY_0_RD_DURATION_3           (6),
     .PHY_0_WR_DURATION_0           (6),
     .PHY_0_WR_DURATION_1           (6),
     .PHY_0_WR_DURATION_2           (6),
     .PHY_0_WR_DURATION_3           (6),
     .PHY_0_RD_CMD_OFFSET_0         (PHY_0_RD_CMD_OFFSET_0),
     .PHY_0_RD_CMD_OFFSET_1         (PHY_0_RD_CMD_OFFSET_1),
     .PHY_0_RD_CMD_OFFSET_2         (PHY_0_RD_CMD_OFFSET_2),
     .PHY_0_RD_CMD_OFFSET_3         (PHY_0_RD_CMD_OFFSET_3),
     .PHY_0_WR_CMD_OFFSET_0         (PHY_0_WR_CMD_OFFSET_0),
     .PHY_0_WR_CMD_OFFSET_1         (PHY_0_WR_CMD_OFFSET_1),
     .PHY_0_WR_CMD_OFFSET_2         (PHY_0_WR_CMD_OFFSET_2),
     .PHY_0_WR_CMD_OFFSET_3         (PHY_0_WR_CMD_OFFSET_3),
     .PHY_0_CMD_OFFSET              (10),//for CKE
     .IODELAY_GRP                   (IODELAY_GRP)
     )
    u_mc_phy
      (
       .rst                    (rst),
       // Don't use MC_PHY to generate DDR_RESET_N output. Instead
       // generate this output outside of MC_PHY (and synchronous to CLK)
       .ddr_rst_in_n           (1'b1),
       .phy_clk                (clk),
       .freq_refclk            (freq_refclk),
       .mem_refclk             (mem_refclk),
       // Remove later - always same connection as phy_clk port
       .mem_refclk_div4        (clk),
       .pll_lock               (pll_lock),
       .sync_pulse             (sync_pulse),
       .phy_dout               (phy_dout),
       .phy_cmd_wr_en          (phy_cmd_wr_en),
       .phy_data_wr_en         (phy_data_wr_en),
       .phy_ctl_wd             (phy_ctl_wd),
       .phy_ctl_wr             (phy_ctl_wr),
       .aux_in_1               (aux_in_1),
       .aux_in_2               (aux_in_2),
       .cke_in                 (),
       .if_a_empty             (),
       .if_empty               (if_empty),
       .of_ctl_a_full          (phy_cmd_full),
       .of_data_a_full         (phy_data_full),
       .of_ctl_full            (),
       .of_data_full           (),
       .idelay_ld              (1'b0),
       .idelay_ce              (1'b0),
       .input_sink             (),
       .phy_din                (phy_din),
       .phy_ctl_a_full         (phy_ctl_full),
       .phy_ctl_full           (),
       .mem_dq_out             (mem_dq_out),
       .mem_dq_ts              (mem_dq_ts),
       .mem_dq_in              (mem_dq_in),
       .mem_dqs_out            (mem_dqs_out),
       .mem_dqs_ts             (mem_dqs_ts),
       .mem_dqs_in             (mem_dqs_in),
       .aux_out                (aux_out),
       .phy_ctl_ready          (),
       .rst_out                (),
       .ddr_clk                (ddr_clk),
       .rclk                   (),
       .mcGo                   (phy_mc_go),
       .phy_write_calib        (phy_write_calib),
       .phy_read_calib         (phy_read_calib),
       .calib_sel              (calib_sel),
       .calib_in_common        (calib_in_common),
       .calib_zero_inputs      (calib_zero_inputs),
       .po_fine_enable         (po_fine_enable),
       .po_coarse_enable       (po_coarse_enable),
       .po_fine_inc            (po_fine_inc),
       .po_coarse_inc          (po_coarse_inc),
       .po_counter_load_en     (po_counter_load_en),
       .po_sel_fine_oclk_delay (po_sel_fine_oclk_delay),
       .po_counter_load_val    (po_counter_load_val),
       .po_counter_read_en     (),
       .po_coarse_overflow     (),
       .po_fine_overflow       (),
       .po_counter_read_val    (),
       .pi_rst_dqs_find        (pi_rst_dqs_find),
       .pi_fine_enable         (pi_fine_enable),
       .pi_fine_inc            (pi_fine_inc),
       .pi_counter_load_en     (pi_counter_load_en),
       .pi_counter_read_en     (),
       .pi_counter_load_val    (pi_counter_load_val),
       .pi_fine_overflow       (),
       .pi_counter_read_val    (),
       .pi_phase_locked        (pi_phase_locked),
       .pi_phase_locked_all    (pi_phase_locked_all),
       .pi_dqs_found           (),
       .pi_dqs_found_any       (pi_dqs_found),
       .pi_dqs_found_all       (pi_dqs_found_all),
       // Currently not being used. May be used in future if periodic
       // reads become a requirement. This output could be used to signal 
       // a catastrophic failure in read capture and the need for 
       // re-calibration.
       .pi_dqs_out_of_range    (pi_dqs_out_of_range)
       );
      
endmodule
