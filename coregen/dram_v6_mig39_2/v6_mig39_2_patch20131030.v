// v6_mig39_2_patch20131030.v

//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 3.92
//  \   \         Application        : MIG
//  /   /         Filename           : mig_39_2.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:00 $
// \   \  /  \    Date Created       : Mon Jun 23 2008
//  \___\/\___\
//
// Device           : Virtex-6
// Design Name      : DDR3 SDRAM
// Purpose          :
//                   Top-level  module. This module serves both as an example,
//                   and allows the user to synthesize a self-contained design,
//                   which they can use to test their hardware. In addition to
//                   the memory controller.
//                   instantiates:
//                     1. Clock generation/distribution, reset logic
//                     2. IDELAY control block
//                     3. Synthesizable testbench - used to model user's backend
//                        logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module v6_mig39_2 #
  (
   parameter REFCLK_FREQ             = 200,
                                       // # = 200 for all design frequencies of
                                       //         -1 speed grade devices
                                       //   = 200 when design frequency < 480 MHz
                                       //         for -2 and -3 speed grade devices.
                                       //   = 300 when design frequency >= 480 MHz
                                       //         for -2 and -3 speed grade devices.
   parameter IODELAY_GRP             = "IODELAY_MIG",
                                       // It is associated to a set of IODELAYs with
                                       // an IDELAYCTRL that have same IODELAY CONTROLLER
                                       // clock frequency.
   parameter MMCM_ADV_BANDWIDTH      = "OPTIMIZED", // MMCM programming algorithm
   parameter CLKFBOUT_MULT_F         = 6,   // write PLL VCO multiplier.
   parameter DIVCLK_DIVIDE           = 2,   // write PLL VCO divisor.  //TODO Was 1 in mig37
   parameter CLKOUT_DIVIDE           = 3,   // VCO output divisor for fast (memory) clocks.
   parameter nCK_PER_CLK             = 2,
                                       // # of memory CKs per fabric clock.
                                       // # = 2, 1.
   parameter tCK                     = 2500,
                                       // memory tCK paramter.
                                       // # = Clock Period.
   parameter DEBUG_PORT              = "ON",
                                       // # = "ON" Enable debug signals/controls.
                                       //   = "OFF" Disable debug signals/controls.
   parameter SIM_BYPASS_INIT_CAL     = "OFF",
                                       // # = "OFF" -  Complete memory init &
                                       //              calibration sequence
                                       // # = "SKIP" - Skip memory init &
                                       //              calibration sequence
                                       // # = "FAST" - Skip memory init & use
                                       //              abbreviated calib sequence
   parameter nCS_PER_RANK            = 1,
                                       // # of unique CS outputs per Rank for
                                       // phy.
   parameter DQS_CNT_WIDTH           = 3,  // # = ceil(log2(DQS_WIDTH)).
   parameter RANK_WIDTH              = 1,  // # = ceil(log2(RANKS)).
   parameter BANK_WIDTH              = 3,  // # of memory Bank Address bits.
   parameter CK_WIDTH                = 1,  // # of CK/CK# outputs to memory.
   parameter CKE_WIDTH               = 1,  // # of CKE outputs to memory.
   parameter COL_WIDTH               = 10, // # of memory Column Address bits.
   parameter CS_WIDTH                = 1,  // # of unique CS outputs to memory.
   parameter DM_WIDTH                = 8,  // # of Data Mask bits.
   parameter DQ_WIDTH                = 64, // # of Data (DQ) bits.
   parameter DQS_WIDTH               = 8,  // # of DQS/DQS# bits.
   parameter ROW_WIDTH               = 13, // # of memory Row Address bits.
   parameter BURST_MODE              = "8",
                                       // Burst Length (Mode Register 0).
                                       // # = "8", "4", "OTF".
   parameter BM_CNT_WIDTH            = 2,        // # = ceil(log2(nBANK_MACHS)).
   parameter ADDR_CMD_MODE           = "1T" ,    // # = "2T", "1T".
   parameter ORDERING                = "STRICT", // # = "NORM", "STRICT".
   parameter WRLVL                   = "ON",
                                       // # = "ON" - DDR3 SDRAM
                                       //   = "OFF" - DDR2 SDRAM.
   parameter PHASE_DETECT            = "ON",
                                       // # = "ON", "OFF".
   parameter RTT_NOM                 = "60",
                                       // RTT_NOM (ODT) (Mode Register 1).
                                       // # = "DISABLED" - RTT_NOM disabled,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
                                       //   = "40"  - RZQ/6.
   parameter RTT_WR                  = "OFF",
                                       // RTT_WR (ODT) (Mode Register 2).
                                       // # = "OFF" - Dynamic ODT off,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
   parameter OUTPUT_DRV              = "HIGH",
                                       // Output Driver Impedance Control (Mode Register 1).
                                       // # = "HIGH" - RZQ/7,
                                       //   = "LOW" - RZQ/6.
   parameter REG_CTRL                = "OFF",
                                       // # = "ON" - RDIMMs,
                                       //   = "OFF" - Components, SODIMMs, UDIMMs.
   parameter nDQS_COL0               = 6, // Number of DQS groups in I/O column #1.  TODO Was 3
   parameter nDQS_COL1               = 2, // Number of DQS groups in I/O column #2.  TODO Was 5
   parameter nDQS_COL2               = 0, // Number of DQS groups in I/O column #3.
   parameter nDQS_COL3               = 0, // Number of DQS groups in I/O column #4.
   parameter DQS_LOC_COL0            = 48'h050403020100, // DQS groups in column #1.
   parameter DQS_LOC_COL1            = 16'h0706,         // DQS groups in column #2.
   parameter DQS_LOC_COL2            = 0,                // DQS groups in column #3.
   parameter DQS_LOC_COL3            = 0,                // DQS groups in column #4.
   parameter tPRDI                   = 1_000_000,        // memory tPRDI paramter.
   parameter tREFI                   = 7800000,          // memory tREFI paramter.
   parameter tZQI                    = 128_000_000,      // memory tZQI paramter.
   parameter ADDR_WIDTH              = 27, // # = RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
   parameter ECC                     = "OFF",
   parameter ECC_TEST                = "OFF",
   parameter TCQ                     = 100,
   parameter DATA_WIDTH              = 64,
   // If parameters overrinding is used for simulation, PAYLOAD_WIDTH parameter
   // should to be overidden along with the vsim command
   parameter PAYLOAD_WIDTH           = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
   parameter RST_ACT_LOW             = 0,
                                       // =1 for active low reset,
                                       // =0 for active high.
   parameter INPUT_CLK_TYPE          = "SINGLE_ENDED",
                                       // input clock type DIFFERENTIAL or SINGLE_ENDED
   parameter STARVE_LIMIT            = 2
                                       // # = 2,3,4.
   )
  (

  input                                 clk_sys,
  input                                 clk_ref,
  input                                 sys_rst,

   inout  [DQ_WIDTH-1:0]                ddr3_dq,
   output [ROW_WIDTH-1:0]               ddr3_addr,
   output [BANK_WIDTH-1:0]              ddr3_ba,
   output                               ddr3_ras_n,
   output                               ddr3_cas_n,
   output                               ddr3_we_n,
   output                               ddr3_reset_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
   output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
   output [CKE_WIDTH-1:0]               ddr3_cke,
   output [DM_WIDTH-1:0]                 ddr3_dm,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_p,
   inout  [DQS_WIDTH-1:0]               ddr3_dqs_n,
   output [CK_WIDTH-1:0]                ddr3_ck_p,
   output [CK_WIDTH-1:0]                ddr3_ck_n,
   inout                                sda,
   output                               scl,

   input                                app_wdf_wren,
   input [(4*PAYLOAD_WIDTH)-1:0]        app_wdf_data,
   input [(4*PAYLOAD_WIDTH)/8-1:0]      app_wdf_mask,
   input                                app_wdf_end,
   input [ADDR_WIDTH-1:0]               app_addr,
   input [2:0]                          app_cmd,
   input                                app_en,
   output                               app_rdy,
   output                               app_wdf_rdy,
   output [(4*PAYLOAD_WIDTH)-1:0]       app_rd_data,
   output                               app_rd_data_end,
   output                               app_rd_data_valid,
   output                               phy_init_done,
   output                               ui_clk_sync_rst_n,
   output                               ui_clk,

   // 18 dbg inputs...
   input                              dbg_pd_off,
   input                              dbg_pd_maintain_off,
   input                              dbg_pd_maintain_0_only,
   input                              dbg_ocb_mon_off,
   input                              dbg_inc_cpt,
   input                              dbg_dec_cpt,
   input                              dbg_inc_rd_dqs,
   input                              dbg_dec_rd_dqs,
   input [DQS_CNT_WIDTH-1:0]          dbg_inc_dec_sel,
   input                              dbg_wr_dqs_tap_set,
   input                              dbg_wr_dq_tap_set,
   input                              dbg_wr_tap_set_en,
   input                              dbg_inc_rd_fps,
   input                              dbg_pd_msb_sel,
   input                              dbg_sel_idel_cpt,
   input                              dbg_sel_idel_rsync,
   input                              dbg_pd_byte_sel,
   input                              dbg_dec_rd_fps,

   // Debug outputs...
   output [DQS_WIDTH-1:0]             dbg_wl_dqs_inverted,
   output [2*DQS_WIDTH-1:0]           dbg_wr_calib_clk_delay,
   output [5*DQS_WIDTH-1:0]           dbg_wl_odelay_dqs_tap_cnt,
   output [5*DQS_WIDTH-1:0]           dbg_wl_odelay_dq_tap_cnt,
   output [1:0]                       dbg_rdlvl_done,
   output [1:0]                       dbg_rdlvl_err,
   output [5*DQS_WIDTH-1:0]           dbg_cpt_tap_cnt,
   output [5*DQS_WIDTH-1:0]           dbg_cpt_first_edge_cnt,
   output [5*DQS_WIDTH-1:0]           dbg_cpt_second_edge_cnt,
   output [3*DQS_WIDTH-1:0]           dbg_rd_bitslip_cnt,
   output [2*DQS_WIDTH-1:0]           dbg_rd_clkdly_cnt,
   output [4:0]                       dbg_rd_active_dly,
   output [5*DQS_WIDTH-1:0]           dbg_dqs_p_tap_cnt,
   output [5*DQS_WIDTH-1:0]           dbg_dqs_n_tap_cnt,
   output [5*DQS_WIDTH-1:0]           dbg_dq_tap_cnt,
   output [4*DQ_WIDTH-1:0]            dbg_rddata
   );


  localparam SYSCLK_PERIOD          = tCK * nCK_PER_CLK;

  // The following parameters used to drive Data and Address modes
  // in debug ports
  localparam SIMULATION          = "FALSE";
  localparam DATA_MODE           = 2;
  localparam ADDR_MODE           = 3;
  localparam APP_DATA_WIDTH      = PAYLOAD_WIDTH * 4;
  localparam APP_MASK_WIDTH      = APP_DATA_WIDTH / 8;

  wire                                sys_clk;
  wire                                mmcm_clk;
  wire                                iodelay_ctrl_rdy;
  (* KEEP = "TRUE" *) wire            sda_i;
  (* KEEP = "TRUE" *) wire            scl_i;
  wire                                rst;
  wire                                clk;
  wire                                clk_mem;
  wire                                clk_rd_base;
  wire                                pd_PSDONE;
  wire                                pd_PSEN;
  wire                                pd_PSINCDEC;
  wire  [(BM_CNT_WIDTH)-1:0]          bank_mach_next;
  wire                                ddr3_parity;
  wire                                app_hi_pri;
  wire [3:0]                          app_ecc_multiple_err_i;
  wire [47:0]                         traffic_wr_data_counts;
  wire [47:0]                         traffic_rd_data_counts;


  assign app_hi_pri = 1'b0;
  assign ui_clk = clk;
  assign ui_clk_sync_rst_n = !rst;  // Make active-low output reset

  MUXCY scl_inst ( .O  (scl), .CI (scl_i), .DI (1'b0), .S  (1'b1));
  MUXCY sda_inst ( .O  (sda), .CI (sda_i), .DI (1'b0), .S  (1'b1));

  assign clk_ref = 1'b0;
  assign sys_clk = 1'b0;


  iodelay_ctrl #
    (
     .TCQ            (TCQ),
     .IODELAY_GRP    (IODELAY_GRP),
     .INPUT_CLK_TYPE (INPUT_CLK_TYPE),
     .RST_ACT_LOW    (RST_ACT_LOW)
     )
    u_iodelay_ctrl
      (
       .clk_ref_p        (1'b0),
       .clk_ref_n        (1'b0),
       .clk_ref          (clk_ref),
       .sys_rst          (sys_rst),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy)
       );

       /*
  clk_ibuf #
    (
     .INPUT_CLK_TYPE (INPUT_CLK_TYPE)
     )
    u_clk_ibuf
      (
       .sys_clk_p         (sys_clk_p),
       .sys_clk_n         (sys_clk_n),
       .sys_clk           (sys_clk),
       .mmcm_clk          (mmcm_clk)
       );
       */

  infrastructure #
    (
     .TCQ                (TCQ),
     .CLK_PERIOD         (SYSCLK_PERIOD),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .MMCM_ADV_BANDWIDTH (MMCM_ADV_BANDWIDTH),
     .CLKFBOUT_MULT_F    (CLKFBOUT_MULT_F),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKOUT_DIVIDE      (CLKOUT_DIVIDE),
     .RST_ACT_LOW        (RST_ACT_LOW)
     )
    u_infrastructure
      (
       .clk_mem          (clk_mem),
       .clk              (clk),
       .clk_rd_base      (clk_rd_base),
       .rstdiv0          (rst),
       .mmcm_clk         (mmcm_clk),
       .sys_rst          (sys_rst),
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
       .PSDONE           (pd_PSDONE),
       .PSEN             (pd_PSEN),
       .PSINCDEC         (pd_PSINCDEC)
       );


  memc_ui_top #
  (
   .ADDR_CMD_MODE        (ADDR_CMD_MODE),
   .BANK_WIDTH           (BANK_WIDTH),
   .CK_WIDTH             (CK_WIDTH),
   .CKE_WIDTH            (CKE_WIDTH),
   .nCK_PER_CLK          (nCK_PER_CLK),
   .COL_WIDTH            (COL_WIDTH),
   .CS_WIDTH             (CS_WIDTH),
   .DM_WIDTH             (DM_WIDTH),
   .nCS_PER_RANK         (nCS_PER_RANK),
   .DEBUG_PORT           (DEBUG_PORT),
   .IODELAY_GRP          (IODELAY_GRP),
   .DQ_WIDTH             (DQ_WIDTH),
   .DQS_WIDTH            (DQS_WIDTH),
   .DQS_CNT_WIDTH        (DQS_CNT_WIDTH),
   .ORDERING             (ORDERING),
   .OUTPUT_DRV           (OUTPUT_DRV),
   .PHASE_DETECT         (PHASE_DETECT),
   .RANK_WIDTH           (RANK_WIDTH),
   .REFCLK_FREQ          (REFCLK_FREQ),
   .REG_CTRL             (REG_CTRL),
   .ROW_WIDTH            (ROW_WIDTH),
   .RTT_NOM              (RTT_NOM),
   .RTT_WR               (RTT_WR),
   .SIM_BYPASS_INIT_CAL  (SIM_BYPASS_INIT_CAL),
   .WRLVL                (WRLVL),
   .nDQS_COL0            (nDQS_COL0),
   .nDQS_COL1            (nDQS_COL1),
   .nDQS_COL2            (nDQS_COL2),
   .nDQS_COL3            (nDQS_COL3),
   .DQS_LOC_COL0         (DQS_LOC_COL0),
   .DQS_LOC_COL1         (DQS_LOC_COL1),
   .DQS_LOC_COL2         (DQS_LOC_COL2),
   .DQS_LOC_COL3         (DQS_LOC_COL3),
   .tPRDI                (tPRDI),
   .tREFI                (tREFI),
   .tZQI                 (tZQI),
   .BURST_MODE           (BURST_MODE),
   .BM_CNT_WIDTH         (BM_CNT_WIDTH),
   .tCK                  (tCK),
   .ADDR_WIDTH           (ADDR_WIDTH),
   .TCQ                  (TCQ),
   .ECC                  (ECC),
   .ECC_TEST             (ECC_TEST),
   .PAYLOAD_WIDTH        (PAYLOAD_WIDTH),
   .APP_DATA_WIDTH       (APP_DATA_WIDTH),
   .APP_MASK_WIDTH       (APP_MASK_WIDTH)
   )
  u_memc_ui_top
  (
   .clk                              (clk),
   .clk_mem                          (clk_mem),
   .clk_rd_base                      (clk_rd_base),
   .rst                              (rst),
   .ddr_addr                         (ddr3_addr),
   .ddr_ba                           (ddr3_ba),
   .ddr_cas_n                        (ddr3_cas_n),
   .ddr_ck_n                         (ddr3_ck_n),
   .ddr_ck                           (ddr3_ck_p),
   .ddr_cke                          (ddr3_cke),
   .ddr_cs_n                         (ddr3_cs_n),
   .ddr_dm                           (ddr3_dm),
   .ddr_odt                          (ddr3_odt),
   .ddr_ras_n                        (ddr3_ras_n),
   .ddr_reset_n                      (ddr3_reset_n),
   .ddr_parity                       (ddr3_parity),
   .ddr_we_n                         (ddr3_we_n),
   .ddr_dq                           (ddr3_dq),
   .ddr_dqs_n                        (ddr3_dqs_n),
   .ddr_dqs                          (ddr3_dqs_p),
   .pd_PSEN                          (pd_PSEN),
   .pd_PSINCDEC                      (pd_PSINCDEC),
   .pd_PSDONE                        (pd_PSDONE),
   .phy_init_done                    (phy_init_done),
   .bank_mach_next                   (bank_mach_next),
   .app_ecc_multiple_err             (app_ecc_multiple_err_i),
   .app_rd_data                      (app_rd_data),
   .app_rd_data_end                  (app_rd_data_end),
   .app_rd_data_valid                (app_rd_data_valid),
   .app_rdy                          (app_rdy),
   .app_wdf_rdy                      (app_wdf_rdy),
   .app_addr                         (app_addr),
   .app_cmd                          (app_cmd),
   .app_en                           (app_en),
   .app_hi_pri                       (app_hi_pri),
   .app_sz                           (1'b1),
   .app_wdf_data                     (app_wdf_data),
   .app_wdf_end                      (app_wdf_end),
   .app_wdf_mask                     (app_wdf_mask),
   .app_wdf_wren                     (app_wdf_wren),
   .app_correct_en                   (1'b1),
   .dbg_wr_dqs_tap_set               (dbg_wr_dqs_tap_set),
   .dbg_wr_dq_tap_set                (dbg_wr_dq_tap_set),
   .dbg_wr_tap_set_en                (dbg_wr_tap_set_en),
   .dbg_wrlvl_start                  (dbg_wrlvl_start),
   .dbg_wrlvl_done                   (dbg_wrlvl_done),
   .dbg_wrlvl_err                    (dbg_wrlvl_err),
   .dbg_wl_dqs_inverted              (dbg_wl_dqs_inverted),
   .dbg_wr_calib_clk_delay           (dbg_wr_calib_clk_delay),
   .dbg_wl_odelay_dqs_tap_cnt        (dbg_wl_odelay_dqs_tap_cnt),
   .dbg_wl_odelay_dq_tap_cnt         (dbg_wl_odelay_dq_tap_cnt),
   .dbg_rdlvl_start                  (dbg_rdlvl_start),
   .dbg_rdlvl_done                   (dbg_rdlvl_done),
   .dbg_rdlvl_err                    (dbg_rdlvl_err),
   .dbg_cpt_tap_cnt                  (dbg_cpt_tap_cnt),
   .dbg_cpt_first_edge_cnt           (dbg_cpt_first_edge_cnt),
   .dbg_cpt_second_edge_cnt          (dbg_cpt_second_edge_cnt),
   .dbg_rd_bitslip_cnt               (dbg_rd_bitslip_cnt),
   .dbg_rd_clkdly_cnt                (dbg_rd_clkdly_cnt),
   .dbg_rd_active_dly                (dbg_rd_active_dly),
   .dbg_pd_off                       (dbg_pd_off),
   .dbg_pd_maintain_off              (dbg_pd_maintain_off),
   .dbg_pd_maintain_0_only           (dbg_pd_maintain_0_only),
   .dbg_inc_cpt                      (dbg_inc_cpt),
   .dbg_dec_cpt                      (dbg_dec_cpt),
   .dbg_inc_rd_dqs                   (dbg_inc_rd_dqs),
   .dbg_dec_rd_dqs                   (dbg_dec_rd_dqs),
   .dbg_inc_dec_sel                  (dbg_inc_dec_sel),
   .dbg_inc_rd_fps                   (dbg_inc_rd_fps),
   .dbg_dec_rd_fps                   (dbg_dec_rd_fps),
   .dbg_dqs_tap_cnt                  (dbg_dqs_tap_cnt),
   .dbg_dq_tap_cnt                   (dbg_dq_tap_cnt),
   .dbg_rddata                       (dbg_rddata)
   );



endmodule
