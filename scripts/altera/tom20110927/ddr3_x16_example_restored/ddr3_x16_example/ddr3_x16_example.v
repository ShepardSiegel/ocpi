// ddr3_x16_example.v

// This file was auto-generated from alt_mem_if_ddr3_tg_ed_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using SOPC Builder version 11.0sp1 208 at 2011.09.27.09:38:39

`timescale 1 ps / 1 ps
module ddr3_x16_example (
		input  wire        pll_ref_clk,              //     pll_ref_clk.clk
		input  wire        global_reset_n,           //    global_reset.reset_n
		input  wire        soft_reset_n,             //      soft_reset.reset_n
		output wire [12:0] mem_a,                    //          memory.mem_a
		output wire [2:0]  mem_ba,                   //                .mem_ba
		output wire        mem_ck,                   //                .mem_ck
		output wire        mem_ck_n,                 //                .mem_ck_n
		output wire        mem_cke,                  //                .mem_cke
		output wire        mem_cs_n,                 //                .mem_cs_n
		output wire [1:0]  mem_dm,                   //                .mem_dm
		output wire        mem_ras_n,                //                .mem_ras_n
		output wire        mem_cas_n,                //                .mem_cas_n
		output wire        mem_we_n,                 //                .mem_we_n
		output wire        mem_reset_n,              //                .mem_reset_n
		inout  wire [15:0] mem_dq,                   //                .mem_dq
		inout  wire [1:0]  mem_dqs,                  //                .mem_dqs
		inout  wire [1:0]  mem_dqs_n,                //                .mem_dqs_n
		output wire        mem_odt,                  //                .mem_odt
		//output wire        local_init_done,          //     emif_status.local_init_done
		//output wire        local_cal_success,        //                .local_cal_success
		//output wire        local_cal_fail,           //                .local_cal_fail
		input  wire        oct_rdn,                  //             oct.rdn
		input  wire        oct_rup,                  //                .rup
		//output wire        drv_status_pass,          //      drv_status.pass
		//output wire        drv_status_fail,          //                .fail
		//output wire        drv_status_test_complete, //                .test_complete
		output wire [5:0]  user_led,
		output wire        local_powerdn_ack,        // local_powerdown.local_powerdn_ack
		input  wire        local_powerdn_req         //                .local_powerdn_req
	);

	wire         if0_afi_clk_clk;                                           // if0:afi_clk -> [d0:clk, d0_avl_translator:clk, if0_avl_translator:clk, rst_controller:clk]
	wire         if0_afi_reset_reset;                                       // if0:afi_reset_n -> [d0:reset_n, rst_controller:reset_in0]
	wire   [2:0] d0_avl_burstcount;                                         // d0:avl_size -> d0_avl_translator:av_burstcount
	wire         d0_avl_waitrequest;                                        // d0_avl_translator:av_waitrequest -> d0:avl_ready
	wire  [63:0] d0_avl_writedata;                                          // d0:avl_wdata -> d0_avl_translator:av_writedata
	wire  [26:0] d0_avl_address;                                            // d0:avl_addr -> d0_avl_translator:av_address
	wire         d0_avl_write;                                              // d0:avl_write_req -> d0_avl_translator:av_write
	wire         d0_avl_beginbursttransfer;                                 // d0:avl_burstbegin -> d0_avl_translator:av_beginbursttransfer
	wire         d0_avl_read;                                               // d0:avl_read_req -> d0_avl_translator:av_read
	wire  [63:0] d0_avl_readdata;                                           // d0_avl_translator:av_readdata -> d0:avl_rdata
	wire   [7:0] d0_avl_byteenable;                                         // d0:avl_be -> d0_avl_translator:av_byteenable
	wire         d0_avl_readdatavalid;                                      // d0_avl_translator:av_readdatavalid -> d0:avl_rdata_valid
	wire         d0_avl_translator_avalon_universal_master_0_waitrequest;   // if0_avl_translator:uav_waitrequest -> d0_avl_translator:uav_waitrequest
	wire   [5:0] d0_avl_translator_avalon_universal_master_0_burstcount;    // d0_avl_translator:uav_burstcount -> if0_avl_translator:uav_burstcount
	wire  [63:0] d0_avl_translator_avalon_universal_master_0_writedata;     // d0_avl_translator:uav_writedata -> if0_avl_translator:uav_writedata
	wire  [26:0] d0_avl_translator_avalon_universal_master_0_address;       // d0_avl_translator:uav_address -> if0_avl_translator:uav_address
	wire         d0_avl_translator_avalon_universal_master_0_lock;          // d0_avl_translator:uav_lock -> if0_avl_translator:uav_lock
	wire         d0_avl_translator_avalon_universal_master_0_write;         // d0_avl_translator:uav_write -> if0_avl_translator:uav_write
	wire         d0_avl_translator_avalon_universal_master_0_read;          // d0_avl_translator:uav_read -> if0_avl_translator:uav_read
	wire  [63:0] d0_avl_translator_avalon_universal_master_0_readdata;      // if0_avl_translator:uav_readdata -> d0_avl_translator:uav_readdata
	wire         d0_avl_translator_avalon_universal_master_0_debugaccess;   // d0_avl_translator:uav_debugaccess -> if0_avl_translator:uav_debugaccess
	wire   [7:0] d0_avl_translator_avalon_universal_master_0_byteenable;    // d0_avl_translator:uav_byteenable -> if0_avl_translator:uav_byteenable
	wire         d0_avl_translator_avalon_universal_master_0_readdatavalid; // if0_avl_translator:uav_readdatavalid -> d0_avl_translator:uav_readdatavalid
	wire         if0_avl_translator_avalon_anti_slave_0_waitrequest;        // if0:avl_ready -> if0_avl_translator:av_waitrequest
	wire   [2:0] if0_avl_translator_avalon_anti_slave_0_burstcount;         // if0_avl_translator:av_burstcount -> if0:avl_size
	wire  [63:0] if0_avl_translator_avalon_anti_slave_0_writedata;          // if0_avl_translator:av_writedata -> if0:avl_wdata
	wire  [23:0] if0_avl_translator_avalon_anti_slave_0_address;            // if0_avl_translator:av_address -> if0:avl_addr
	wire         if0_avl_translator_avalon_anti_slave_0_write;              // if0_avl_translator:av_write -> if0:avl_write_req
	wire         if0_avl_translator_avalon_anti_slave_0_beginbursttransfer; // if0_avl_translator:av_beginbursttransfer -> if0:avl_burstbegin
	wire         if0_avl_translator_avalon_anti_slave_0_read;               // if0_avl_translator:av_read -> if0:avl_read_req
	wire  [63:0] if0_avl_translator_avalon_anti_slave_0_readdata;           // if0:avl_rdata -> if0_avl_translator:av_readdata
	wire         if0_avl_translator_avalon_anti_slave_0_readdatavalid;      // if0:avl_rdata_valid -> if0_avl_translator:av_readdatavalid
	wire   [7:0] if0_avl_translator_avalon_anti_slave_0_byteenable;         // if0_avl_translator:av_byteenable -> if0:avl_be
	wire         rst_controller_reset_out_reset;                            // rst_controller:reset_out -> [d0_avl_translator:reset, if0_avl_translator:reset]

	wire local_init_done;
	wire local_cal_success;
	wire local_cal_fail;
	wire drv_status_pass;
	wire drv_status_fail;
	wire drv_status_test_complete;
	assign user_led = {~drv_status_test_complete,
							 ~drv_status_fail,
							 ~drv_status_pass,
							 ~local_cal_fail,
							 ~local_cal_success,
							 ~local_init_done};
	
	ddr3_x16_example_if0 if0 (
		.pll_ref_clk       (pll_ref_clk),                                               //     pll_ref_clk.clk
		.global_reset_n    (global_reset_n),                                            //    global_reset.reset_n
		.soft_reset_n      (soft_reset_n),                                              //      soft_reset.reset_n
		.afi_clk           (if0_afi_clk_clk),                                           //         afi_clk.clk
		.afi_half_clk      (),                                                          //    afi_half_clk.clk
		.afi_reset_n       (if0_afi_reset_reset),                                       //       afi_reset.reset_n
		.mem_a             (mem_a),                                                     //          memory.mem_a
		.mem_ba            (mem_ba),                                                    //                .mem_ba
		.mem_ck            (mem_ck),                                                    //                .mem_ck
		.mem_ck_n          (mem_ck_n),                                                  //                .mem_ck_n
		.mem_cke           (mem_cke),                                                   //                .mem_cke
		.mem_cs_n          (mem_cs_n),                                                  //                .mem_cs_n
		.mem_dm            (mem_dm),                                                    //                .mem_dm
		.mem_ras_n         (mem_ras_n),                                                 //                .mem_ras_n
		.mem_cas_n         (mem_cas_n),                                                 //                .mem_cas_n
		.mem_we_n          (mem_we_n),                                                  //                .mem_we_n
		.mem_reset_n       (mem_reset_n),                                               //                .mem_reset_n
		.mem_dq            (mem_dq),                                                    //                .mem_dq
		.mem_dqs           (mem_dqs),                                                   //                .mem_dqs
		.mem_dqs_n         (mem_dqs_n),                                                 //                .mem_dqs_n
		.mem_odt           (mem_odt),                                                   //                .mem_odt
		.avl_ready         (if0_avl_translator_avalon_anti_slave_0_waitrequest),        //             avl.waitrequest_n
		.avl_burstbegin    (if0_avl_translator_avalon_anti_slave_0_beginbursttransfer), //                .beginbursttransfer
		.avl_addr          (if0_avl_translator_avalon_anti_slave_0_address),            //                .address
		.avl_rdata_valid   (if0_avl_translator_avalon_anti_slave_0_readdatavalid),      //                .readdatavalid
		.avl_rdata         (if0_avl_translator_avalon_anti_slave_0_readdata),           //                .readdata
		.avl_wdata         (if0_avl_translator_avalon_anti_slave_0_writedata),          //                .writedata
		.avl_be            (if0_avl_translator_avalon_anti_slave_0_byteenable),         //                .byteenable
		.avl_read_req      (if0_avl_translator_avalon_anti_slave_0_read),               //                .read
		.avl_write_req     (if0_avl_translator_avalon_anti_slave_0_write),              //                .write
		.avl_size          (if0_avl_translator_avalon_anti_slave_0_burstcount),         //                .burstcount
		.local_init_done   (local_init_done),                                           //          status.local_init_done
		.local_cal_success (local_cal_success),                                         //                .local_cal_success
		.local_cal_fail    (local_cal_fail),                                            //                .local_cal_fail
		.oct_rdn           (oct_rdn),                                                   //             oct.rdn
		.oct_rup           (oct_rup),                                                   //                .rup
		.local_powerdn_ack (local_powerdn_ack),                                         // local_powerdown.local_powerdn_ack
		.local_powerdn_req (local_powerdn_req)                                          //                .local_powerdn_req
	);

	ddr3_x16_example_d0 #(
		.DEVICE_FAMILY                          ("Stratix IV"),
		.TG_AVL_DATA_WIDTH                      (64),
		.TG_AVL_ADDR_WIDTH                      (27),
		.TG_AVL_WORD_ADDR_WIDTH                 (24),
		.TG_AVL_SIZE_WIDTH                      (3),
		.TG_AVL_BE_WIDTH                        (8),
		.TG_GEN_BYTE_ADDR                       (1),
		.TG_NUM_DRIVER_LOOP                     (1),
		.TG_RANDOM_BYTE_ENABLE                  (1),
		.TG_ENABLE_READ_COMPARE                 (1),
		.TG_POWER_OF_TWO_BURSTS_ONLY            (0),
		.TG_BURST_ON_BURST_BOUNDARY             (0),
		.TG_TIMEOUT_COUNTER_WIDTH               (30),
		.TG_MAX_READ_LATENCY                    (20),
		.TG_SINGLE_RW_SEQ_ADDR_COUNT            (32),
		.TG_SINGLE_RW_RAND_ADDR_COUNT           (32),
		.TG_SINGLE_RW_RAND_SEQ_ADDR_COUNT       (32),
		.TG_BLOCK_RW_SEQ_ADDR_COUNT             (8),
		.TG_BLOCK_RW_RAND_ADDR_COUNT            (8),
		.TG_BLOCK_RW_RAND_SEQ_ADDR_COUNT        (8),
		.TG_BLOCK_RW_BLOCK_SIZE                 (8),
		.TG_TEMPLATE_STAGE_COUNT                (4),
		.TG_SEQ_ADDR_GEN_MIN_BURSTCOUNT         (1),
		.TG_SEQ_ADDR_GEN_MAX_BURSTCOUNT         (4),
		.TG_RAND_ADDR_GEN_MIN_BURSTCOUNT        (1),
		.TG_RAND_ADDR_GEN_MAX_BURSTCOUNT        (4),
		.TG_RAND_SEQ_ADDR_GEN_MIN_BURSTCOUNT    (1),
		.TG_RAND_SEQ_ADDR_GEN_MAX_BURSTCOUNT    (4),
		.TG_RAND_SEQ_ADDR_GEN_RAND_ADDR_PERCENT (50)
	) d0 (
		.clk             (if0_afi_clk_clk),           // avl_clock.clk
		.reset_n         (if0_afi_reset_reset),       // avl_reset.reset_n
		.pass            (drv_status_pass),           //    status.pass
		.fail            (drv_status_fail),           //          .fail
		.test_complete   (drv_status_test_complete),  //          .test_complete
		.avl_ready       (~d0_avl_waitrequest),       //       avl.waitrequest_n
		.avl_addr        (d0_avl_address),            //          .address
		.avl_size        (d0_avl_burstcount),         //          .burstcount
		.avl_wdata       (d0_avl_writedata),          //          .writedata
		.avl_rdata       (d0_avl_readdata),           //          .readdata
		.avl_write_req   (d0_avl_write),              //          .write
		.avl_read_req    (d0_avl_read),               //          .read
		.avl_rdata_valid (d0_avl_readdatavalid),      //          .readdatavalid
		.avl_be          (d0_avl_byteenable),         //          .byteenable
		.avl_burstbegin  (d0_avl_beginbursttransfer)  //          .beginbursttransfer
	);

	altera_merlin_master_translator #(
		.AV_ADDRESS_W                (27),
		.AV_DATA_W                   (64),
		.AV_BURSTCOUNT_W             (3),
		.AV_BYTEENABLE_W             (8),
		.UAV_ADDRESS_W               (27),
		.UAV_BURSTCOUNT_W            (6),
		.USE_READ                    (1),
		.USE_WRITE                   (1),
		.USE_BEGINBURSTTRANSFER      (1),
		.USE_BEGINTRANSFER           (0),
		.USE_CHIPSELECT              (0),
		.USE_BURSTCOUNT              (1),
		.USE_READDATAVALID           (1),
		.USE_WAITREQUEST             (1),
		.AV_SYMBOLS_PER_WORD         (8),
		.AV_ADDRESS_SYMBOLS          (1),
		.AV_BURSTCOUNT_SYMBOLS       (0),
		.AV_CONSTANT_BURST_BEHAVIOR  (1),
		.UAV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_LINEWRAPBURSTS           (0),
		.AV_REGISTERINCOMINGSIGNALS  (0)
	) d0_avl_translator (
		.clk                   (if0_afi_clk_clk),                                           //                       clk.clk
		.reset                 (rst_controller_reset_out_reset),                            //                     reset.reset
		.uav_address           (d0_avl_translator_avalon_universal_master_0_address),       // avalon_universal_master_0.address
		.uav_burstcount        (d0_avl_translator_avalon_universal_master_0_burstcount),    //                          .burstcount
		.uav_read              (d0_avl_translator_avalon_universal_master_0_read),          //                          .read
		.uav_write             (d0_avl_translator_avalon_universal_master_0_write),         //                          .write
		.uav_waitrequest       (d0_avl_translator_avalon_universal_master_0_waitrequest),   //                          .waitrequest
		.uav_readdatavalid     (d0_avl_translator_avalon_universal_master_0_readdatavalid), //                          .readdatavalid
		.uav_byteenable        (d0_avl_translator_avalon_universal_master_0_byteenable),    //                          .byteenable
		.uav_readdata          (d0_avl_translator_avalon_universal_master_0_readdata),      //                          .readdata
		.uav_writedata         (d0_avl_translator_avalon_universal_master_0_writedata),     //                          .writedata
		.uav_lock              (d0_avl_translator_avalon_universal_master_0_lock),          //                          .lock
		.uav_debugaccess       (d0_avl_translator_avalon_universal_master_0_debugaccess),   //                          .debugaccess
		.av_address            (d0_avl_address),                                            //      avalon_anti_master_0.address
		.av_waitrequest        (d0_avl_waitrequest),                                        //                          .waitrequest
		.av_burstcount         (d0_avl_burstcount),                                         //                          .burstcount
		.av_byteenable         (d0_avl_byteenable),                                         //                          .byteenable
		.av_beginbursttransfer (d0_avl_beginbursttransfer),                                 //                          .beginbursttransfer
		.av_read               (d0_avl_read),                                               //                          .read
		.av_readdata           (d0_avl_readdata),                                           //                          .readdata
		.av_readdatavalid      (d0_avl_readdatavalid),                                      //                          .readdatavalid
		.av_write              (d0_avl_write),                                              //                          .write
		.av_writedata          (d0_avl_writedata),                                          //                          .writedata
		.av_begintransfer      (1'b0),                                                      //               (terminated)
		.av_chipselect         (1'b0),                                                      //               (terminated)
		.av_lock               (1'b0),                                                      //               (terminated)
		.av_debugaccess        (1'b0),                                                      //               (terminated)
		.uav_clken             (),                                                          //               (terminated)
		.av_clken              (1'b1)                                                       //               (terminated)
	);

	altera_merlin_slave_translator #(
		.AV_ADDRESS_W                   (24),
		.AV_DATA_W                      (64),
		.UAV_DATA_W                     (64),
		.AV_BURSTCOUNT_W                (3),
		.AV_BYTEENABLE_W                (8),
		.UAV_BYTEENABLE_W               (8),
		.UAV_ADDRESS_W                  (27),
		.UAV_BURSTCOUNT_W               (6),
		.AV_READLATENCY                 (0),
		.USE_READDATAVALID              (1),
		.USE_WAITREQUEST                (1),
		.USE_UAV_CLKEN                  (0),
		.AV_SYMBOLS_PER_WORD            (8),
		.AV_ADDRESS_SYMBOLS             (0),
		.AV_BURSTCOUNT_SYMBOLS          (0),
		.AV_CONSTANT_BURST_BEHAVIOR     (0),
		.UAV_CONSTANT_BURST_BEHAVIOR    (0),
		.AV_REQUIRE_UNALIGNED_ADDRESSES (0),
		.CHIPSELECT_THROUGH_READLATENCY (0),
		.AV_READ_WAIT_CYCLES            (1),
		.AV_WRITE_WAIT_CYCLES           (0),
		.AV_SETUP_WAIT_CYCLES           (0),
		.AV_DATA_HOLD_CYCLES            (0)
	) if0_avl_translator (
		.clk                   (if0_afi_clk_clk),                                           //                      clk.clk
		.reset                 (rst_controller_reset_out_reset),                            //                    reset.reset
		.uav_address           (d0_avl_translator_avalon_universal_master_0_address),       // avalon_universal_slave_0.address
		.uav_burstcount        (d0_avl_translator_avalon_universal_master_0_burstcount),    //                         .burstcount
		.uav_read              (d0_avl_translator_avalon_universal_master_0_read),          //                         .read
		.uav_write             (d0_avl_translator_avalon_universal_master_0_write),         //                         .write
		.uav_waitrequest       (d0_avl_translator_avalon_universal_master_0_waitrequest),   //                         .waitrequest
		.uav_readdatavalid     (d0_avl_translator_avalon_universal_master_0_readdatavalid), //                         .readdatavalid
		.uav_byteenable        (d0_avl_translator_avalon_universal_master_0_byteenable),    //                         .byteenable
		.uav_readdata          (d0_avl_translator_avalon_universal_master_0_readdata),      //                         .readdata
		.uav_writedata         (d0_avl_translator_avalon_universal_master_0_writedata),     //                         .writedata
		.uav_lock              (d0_avl_translator_avalon_universal_master_0_lock),          //                         .lock
		.uav_debugaccess       (d0_avl_translator_avalon_universal_master_0_debugaccess),   //                         .debugaccess
		.av_address            (if0_avl_translator_avalon_anti_slave_0_address),            //      avalon_anti_slave_0.address
		.av_write              (if0_avl_translator_avalon_anti_slave_0_write),              //                         .write
		.av_read               (if0_avl_translator_avalon_anti_slave_0_read),               //                         .read
		.av_readdata           (if0_avl_translator_avalon_anti_slave_0_readdata),           //                         .readdata
		.av_writedata          (if0_avl_translator_avalon_anti_slave_0_writedata),          //                         .writedata
		.av_beginbursttransfer (if0_avl_translator_avalon_anti_slave_0_beginbursttransfer), //                         .beginbursttransfer
		.av_burstcount         (if0_avl_translator_avalon_anti_slave_0_burstcount),         //                         .burstcount
		.av_byteenable         (if0_avl_translator_avalon_anti_slave_0_byteenable),         //                         .byteenable
		.av_readdatavalid      (if0_avl_translator_avalon_anti_slave_0_readdatavalid),      //                         .readdatavalid
		.av_waitrequest        (~if0_avl_translator_avalon_anti_slave_0_waitrequest),       //                         .waitrequest
		.av_begintransfer      (),                                                          //              (terminated)
		.av_writebyteenable    (),                                                          //              (terminated)
		.av_lock               (),                                                          //              (terminated)
		.av_chipselect         (),                                                          //              (terminated)
		.av_clken              (),                                                          //              (terminated)
		.uav_clken             (1'b0),                                                      //              (terminated)
		.av_debugaccess        (),                                                          //              (terminated)
		.av_outputenable       ()                                                           //              (terminated)
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS        (1),
		.OUTPUT_RESET_SYNC_EDGES ("deassert"),
		.SYNC_DEPTH              (2)
	) rst_controller (
		.reset_in0  (~if0_afi_reset_reset),           // reset_in0.reset
		.clk        (if0_afi_clk_clk),                //       clk.clk
		.reset_out  (rst_controller_reset_out_reset), // reset_out.reset
		.reset_in1  (1'b0),                           // (terminated)
		.reset_in2  (1'b0),                           // (terminated)
		.reset_in3  (1'b0),                           // (terminated)
		.reset_in4  (1'b0),                           // (terminated)
		.reset_in5  (1'b0),                           // (terminated)
		.reset_in6  (1'b0),                           // (terminated)
		.reset_in7  (1'b0),                           // (terminated)
		.reset_in8  (1'b0),                           // (terminated)
		.reset_in9  (1'b0),                           // (terminated)
		.reset_in10 (1'b0),                           // (terminated)
		.reset_in11 (1'b0),                           // (terminated)
		.reset_in12 (1'b0),                           // (terminated)
		.reset_in13 (1'b0),                           // (terminated)
		.reset_in14 (1'b0),                           // (terminated)
		.reset_in15 (1'b0)                            // (terminated)
	);

endmodule
