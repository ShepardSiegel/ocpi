// ddr3_s4_uniphy_example_if0.v

// This file was auto-generated from alt_mem_if_ddr3_emif_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using SOPC Builder version 11.0sp1 208 at 2011.09.28.12:48:48

`timescale 1 ps / 1 ps
module ddr3_s4_uniphy_example_if0 (
		input  wire        pll_ref_clk,       //     pll_ref_clk.clk
		input  wire        global_reset_n,    //    global_reset.reset_n
		input  wire        soft_reset_n,      //      soft_reset.reset_n
		output wire        afi_clk,           //         afi_clk.clk
		output wire        afi_half_clk,      //    afi_half_clk.clk
		output wire        afi_reset_n,       //       afi_reset.reset_n
		output wire [12:0] mem_a,             //          memory.mem_a
		output wire [2:0]  mem_ba,            //                .mem_ba
		output wire        mem_ck,            //                .mem_ck
		output wire        mem_ck_n,          //                .mem_ck_n
		output wire        mem_cke,           //                .mem_cke
		output wire        mem_cs_n,          //                .mem_cs_n
		output wire [1:0]  mem_dm,            //                .mem_dm
		output wire        mem_ras_n,         //                .mem_ras_n
		output wire        mem_cas_n,         //                .mem_cas_n
		output wire        mem_we_n,          //                .mem_we_n
		output wire        mem_reset_n,       //                .mem_reset_n
		inout  wire [15:0] mem_dq,            //                .mem_dq
		inout  wire [1:0]  mem_dqs,           //                .mem_dqs
		inout  wire [1:0]  mem_dqs_n,         //                .mem_dqs_n
		output wire        mem_odt,           //                .mem_odt
		output wire        avl_ready,         //             avl.waitrequest_n
		input  wire        avl_burstbegin,    //                .beginbursttransfer
		input  wire [23:0] avl_addr,          //                .address
		output wire        avl_rdata_valid,   //                .readdatavalid
		output wire [63:0] avl_rdata,         //                .readdata
		input  wire [63:0] avl_wdata,         //                .writedata
		input  wire [7:0]  avl_be,            //                .byteenable
		input  wire        avl_read_req,      //                .read
		input  wire        avl_write_req,     //                .write
		input  wire [2:0]  avl_size,          //                .burstcount
		output wire        local_init_done,   //          status.local_init_done
		output wire        local_cal_success, //                .local_cal_success
		output wire        local_cal_fail,    //                .local_cal_fail
		input  wire        oct_rdn,           //             oct.rdn
		input  wire        oct_rup,           //                .rup
		output wire        local_powerdn_ack, // local_powerdown.local_powerdn_ack
		input  wire        local_powerdn_req  //                .local_powerdn_req
	);

	wire  [25:0] c0_afi_afi_addr;          // c0:afi_addr -> p0:afi_addr
	wire   [1:0] c0_afi_afi_odt;           // c0:afi_odt -> p0:afi_odt
	wire         c0_afi_afi_cal_req;       // c0:afi_cal_req -> p0:afi_cal_req
	wire   [5:0] p0_afi_afi_wlat;          // p0:afi_wlat -> c0:afi_wlat
	wire   [1:0] p0_afi_afi_rdata_valid;   // p0:afi_rdata_valid -> c0:afi_rdata_valid
	wire   [1:0] c0_afi_afi_rdata_en_full; // c0:afi_rdata_en_full -> p0:afi_rdata_en_full
	wire   [1:0] c0_afi_afi_we_n;          // c0:afi_we_n -> p0:afi_we_n
	wire   [5:0] c0_afi_afi_ba;            // c0:afi_ba -> p0:afi_ba
	wire   [1:0] c0_afi_afi_cke;           // c0:afi_cke -> p0:afi_cke
	wire   [1:0] c0_afi_afi_cs_n;          // c0:afi_cs_n -> p0:afi_cs_n
	wire  [63:0] c0_afi_afi_wdata;         // c0:afi_wdata -> p0:afi_wdata
	wire   [1:0] c0_afi_afi_rdata_en;      // c0:afi_rdata_en -> p0:afi_rdata_en
	wire   [1:0] c0_afi_afi_rst_n;         // c0:afi_rst_n -> p0:afi_rst_n
	wire   [1:0] c0_afi_afi_cas_n;         // c0:afi_cas_n -> p0:afi_cas_n
	wire         p0_afi_afi_cal_success;   // p0:afi_cal_success -> c0:afi_cal_success
	wire   [1:0] c0_afi_afi_ras_n;         // c0:afi_ras_n -> p0:afi_ras_n
	wire   [5:0] p0_afi_afi_rlat;          // p0:afi_rlat -> c0:afi_rlat
	wire  [63:0] p0_afi_afi_rdata;         // p0:afi_rdata -> c0:afi_rdata
	wire         p0_afi_afi_cal_fail;      // p0:afi_cal_fail -> c0:afi_cal_fail
	wire   [3:0] c0_afi_afi_wdata_valid;   // c0:afi_wdata_valid -> p0:afi_wdata_valid
	wire   [3:0] c0_afi_afi_dqs_burst;     // c0:afi_dqs_burst -> p0:afi_dqs_burst
	wire   [7:0] c0_afi_afi_dm;            // c0:afi_dm -> p0:afi_dm

	ddr3_s4_uniphy_example_if0_c0 c0 (
		.afi_reset_n       (afi_reset_n),              //       afi_reset.reset_n
		.afi_clk           (afi_clk),                  //         afi_clk.clk
		.afi_half_clk      (afi_half_clk),             //    afi_half_clk.clk
		.local_init_done   (local_init_done),          //          status.local_init_done
		.local_cal_success (local_cal_success),        //                .local_cal_success
		.local_cal_fail    (local_cal_fail),           //                .local_cal_fail
		.afi_addr          (c0_afi_afi_addr),          //             afi.afi_addr
		.afi_ba            (c0_afi_afi_ba),            //                .afi_ba
		.afi_cke           (c0_afi_afi_cke),           //                .afi_cke
		.afi_cs_n          (c0_afi_afi_cs_n),          //                .afi_cs_n
		.afi_ras_n         (c0_afi_afi_ras_n),         //                .afi_ras_n
		.afi_we_n          (c0_afi_afi_we_n),          //                .afi_we_n
		.afi_cas_n         (c0_afi_afi_cas_n),         //                .afi_cas_n
		.afi_rst_n         (c0_afi_afi_rst_n),         //                .afi_rst_n
		.afi_odt           (c0_afi_afi_odt),           //                .afi_odt
		.afi_dqs_burst     (c0_afi_afi_dqs_burst),     //                .afi_dqs_burst
		.afi_wdata_valid   (c0_afi_afi_wdata_valid),   //                .afi_wdata_valid
		.afi_wdata         (c0_afi_afi_wdata),         //                .afi_wdata
		.afi_dm            (c0_afi_afi_dm),            //                .afi_dm
		.afi_rdata         (p0_afi_afi_rdata),         //                .afi_rdata
		.afi_rdata_en      (c0_afi_afi_rdata_en),      //                .afi_rdata_en
		.afi_rdata_en_full (c0_afi_afi_rdata_en_full), //                .afi_rdata_en_full
		.afi_rdata_valid   (p0_afi_afi_rdata_valid),   //                .afi_rdata_valid
		.afi_cal_success   (p0_afi_afi_cal_success),   //                .afi_cal_success
		.afi_cal_fail      (p0_afi_afi_cal_fail),      //                .afi_cal_fail
		.afi_cal_req       (c0_afi_afi_cal_req),       //                .afi_cal_req
		.afi_wlat          (p0_afi_afi_wlat),          //                .afi_wlat
		.afi_rlat          (p0_afi_afi_rlat),          //                .afi_rlat
		.local_powerdn_ack (local_powerdn_ack),        // local_powerdown.local_powerdn_ack
		.local_powerdn_req (local_powerdn_req),        //                .local_powerdn_req
		.avl_ready         (avl_ready),                //             avl.waitrequest_n
		.avl_burstbegin    (avl_burstbegin),           //                .beginbursttransfer
		.avl_addr          (avl_addr),                 //                .address
		.avl_rdata_valid   (avl_rdata_valid),          //                .readdatavalid
		.avl_rdata         (avl_rdata),                //                .readdata
		.avl_wdata         (avl_wdata),                //                .writedata
		.avl_be            (avl_be),                   //                .byteenable
		.avl_read_req      (avl_read_req),             //                .read
		.avl_write_req     (avl_write_req),            //                .write
		.avl_size          (avl_size)                  //                .burstcount
	);

	ddr3_s4_uniphy_example_if0_p0 p0 (
		.global_reset_n             (global_reset_n),           // global_reset.reset_n
		.soft_reset_n               (soft_reset_n),             //   soft_reset.reset_n
		.afi_reset_n                (afi_reset_n),              //    afi_reset.reset_n
		.afi_clk                    (afi_clk),                  //      afi_clk.clk
		.afi_half_clk               (afi_half_clk),             // afi_half_clk.clk
		.pll_ref_clk                (pll_ref_clk),              //  pll_ref_clk.clk
		.afi_addr                   (c0_afi_afi_addr),          //          afi.afi_addr
		.afi_ba                     (c0_afi_afi_ba),            //             .afi_ba
		.afi_cke                    (c0_afi_afi_cke),           //             .afi_cke
		.afi_cs_n                   (c0_afi_afi_cs_n),          //             .afi_cs_n
		.afi_ras_n                  (c0_afi_afi_ras_n),         //             .afi_ras_n
		.afi_we_n                   (c0_afi_afi_we_n),          //             .afi_we_n
		.afi_cas_n                  (c0_afi_afi_cas_n),         //             .afi_cas_n
		.afi_rst_n                  (c0_afi_afi_rst_n),         //             .afi_rst_n
		.afi_odt                    (c0_afi_afi_odt),           //             .afi_odt
		.afi_dqs_burst              (c0_afi_afi_dqs_burst),     //             .afi_dqs_burst
		.afi_wdata_valid            (c0_afi_afi_wdata_valid),   //             .afi_wdata_valid
		.afi_wdata                  (c0_afi_afi_wdata),         //             .afi_wdata
		.afi_dm                     (c0_afi_afi_dm),            //             .afi_dm
		.afi_rdata                  (p0_afi_afi_rdata),         //             .afi_rdata
		.afi_rdata_en               (c0_afi_afi_rdata_en),      //             .afi_rdata_en
		.afi_rdata_en_full          (c0_afi_afi_rdata_en_full), //             .afi_rdata_en_full
		.afi_rdata_valid            (p0_afi_afi_rdata_valid),   //             .afi_rdata_valid
		.afi_cal_success            (p0_afi_afi_cal_success),   //             .afi_cal_success
		.afi_cal_fail               (p0_afi_afi_cal_fail),      //             .afi_cal_fail
		.afi_cal_req                (c0_afi_afi_cal_req),       //             .afi_cal_req
		.afi_wlat                   (p0_afi_afi_wlat),          //             .afi_wlat
		.afi_rlat                   (p0_afi_afi_rlat),          //             .afi_rlat
		.oct_rdn                    (oct_rdn),                  //          oct.rdn
		.oct_rup                    (oct_rup),                  //             .rup
		.mem_a                      (mem_a),                    //       memory.mem_a
		.mem_ba                     (mem_ba),                   //             .mem_ba
		.mem_ck                     (mem_ck),                   //             .mem_ck
		.mem_ck_n                   (mem_ck_n),                 //             .mem_ck_n
		.mem_cke                    (mem_cke),                  //             .mem_cke
		.mem_cs_n                   (mem_cs_n),                 //             .mem_cs_n
		.mem_dm                     (mem_dm),                   //             .mem_dm
		.mem_ras_n                  (mem_ras_n),                //             .mem_ras_n
		.mem_cas_n                  (mem_cas_n),                //             .mem_cas_n
		.mem_we_n                   (mem_we_n),                 //             .mem_we_n
		.mem_reset_n                (mem_reset_n),              //             .mem_reset_n
		.mem_dq                     (mem_dq),                   //             .mem_dq
		.mem_dqs                    (mem_dqs),                  //             .mem_dqs
		.mem_dqs_n                  (mem_dqs_n),                //             .mem_dqs_n
		.mem_odt                    (mem_odt),                  //             .mem_odt
		.dll_delayctrl              (),                         //  (terminated)
		.seriesterminationcontrol   (),                         //  (terminated)
		.parallelterminationcontrol ()                          //  (terminated)
	);

endmodule
