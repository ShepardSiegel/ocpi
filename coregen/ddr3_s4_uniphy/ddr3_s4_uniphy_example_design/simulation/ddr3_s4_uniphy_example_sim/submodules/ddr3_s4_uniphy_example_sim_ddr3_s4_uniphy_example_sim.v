// ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim.v

// This file was auto-generated from alt_mem_if_ddr3_tg_eds_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using SOPC Builder version 11.0sp1 208 at 2011.09.28.12:47:26

`timescale 1 ps / 1 ps
module ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim #(
		parameter ENABLE_VCDPLUS = 0
	) (
		input  wire  pll_ref_clk,       //     pll_ref_clk.clk
		input  wire  global_reset_n,    //    global_reset.reset_n
		input  wire  soft_reset_n,      //      soft_reset.reset_n
		input  wire  oct_rdn,           //             oct.rdn
		input  wire  oct_rup,           //                .rup
		output wire  local_powerdn_ack, // local_powerdown.local_powerdn_ack
		input  wire  local_powerdn_req  //                .local_powerdn_req
	);

	wire         e0_afi_clk_clk;                   // e0:afi_clk -> t0:clk
	wire         e0_afi_reset_reset;               // e0:afi_reset_n -> t0:reset_n
	wire         e0_drv_status_test_complete;      // e0:drv_status_test_complete -> t0:test_complete
	wire         e0_drv_status_fail;               // e0:drv_status_fail -> t0:fail
	wire         e0_drv_status_pass;               // e0:drv_status_pass -> t0:pass
	wire         e0_emif_status_local_cal_fail;    // e0:local_cal_fail -> t0:local_cal_fail
	wire         e0_emif_status_local_cal_success; // e0:local_cal_success -> t0:local_cal_success
	wire         e0_emif_status_local_init_done;   // e0:local_init_done -> t0:local_init_done
	wire   [0:0] e0_memory_mem_odt;                // e0:mem_odt -> m0:mem_odt
	wire   [0:0] e0_memory_mem_cs_n;               // e0:mem_cs_n -> m0:mem_cs_n
	wire  [12:0] e0_memory_mem_a;                  // e0:mem_a -> m0:mem_a
	wire   [0:0] e0_memory_mem_ck_n;               // e0:mem_ck_n -> m0:mem_ck_n
	wire   [0:0] e0_memory_mem_ras_n;              // e0:mem_ras_n -> m0:mem_ras_n
	wire   [0:0] e0_memory_mem_cke;                // e0:mem_cke -> m0:mem_cke
	wire   [1:0] e0_memory_mem_dqs;                // [] -> [e0:mem_dqs, m0:mem_dqs]
	wire   [0:0] e0_memory_mem_we_n;               // e0:mem_we_n -> m0:mem_we_n
	wire   [2:0] e0_memory_mem_ba;                 // e0:mem_ba -> m0:mem_ba
	wire  [15:0] e0_memory_mem_dq;                 // [] -> [e0:mem_dq, m0:mem_dq]
	wire   [0:0] e0_memory_mem_ck;                 // e0:mem_ck -> m0:mem_ck
	wire         e0_memory_mem_reset_n;            // e0:mem_reset_n -> m0:mem_reset_n
	wire   [1:0] e0_memory_mem_dm;                 // e0:mem_dm -> m0:mem_dm
	wire   [0:0] e0_memory_mem_cas_n;              // e0:mem_cas_n -> m0:mem_cas_n
	wire   [1:0] e0_memory_mem_dqs_n;              // [] -> [e0:mem_dqs_n, m0:mem_dqs_n]

	generate
		// If any of the display statements (or deliberately broken
		// instantiations) within this generate block triggers then this module
		// has been instantiated this module with a set of parameters different
		// from those it was generated for.  This will usually result in a
		// non-functioning system.
		if (ENABLE_VCDPLUS != 0)
		begin
			initial begin
				$display("Generated module instantiated with wrong parameters");
				$stop;
			end
			instantiated_with_wrong_parameters_error_see_comment_above
					enable_vcdplus_check ( .error(1'b1) );
		end
	endgenerate

	ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim_e0 e0 (
		.pll_ref_clk              (pll_ref_clk),                      //     pll_ref_clk.clk
		.global_reset_n           (global_reset_n),                   //    global_reset.reset_n
		.soft_reset_n             (soft_reset_n),                     //      soft_reset.reset_n
		.afi_reset_n              (e0_afi_reset_reset),               //       afi_reset.reset_n
		.afi_clk                  (e0_afi_clk_clk),                   //         afi_clk.clk
		.afi_half_clk             (),                                 //    afi_half_clk.clk
		.mem_a                    (e0_memory_mem_a),                  //          memory.mem_a
		.mem_ba                   (e0_memory_mem_ba),                 //                .mem_ba
		.mem_ck                   (e0_memory_mem_ck),                 //                .mem_ck
		.mem_ck_n                 (e0_memory_mem_ck_n),               //                .mem_ck_n
		.mem_cke                  (e0_memory_mem_cke),                //                .mem_cke
		.mem_cs_n                 (e0_memory_mem_cs_n),               //                .mem_cs_n
		.mem_dm                   (e0_memory_mem_dm),                 //                .mem_dm
		.mem_ras_n                (e0_memory_mem_ras_n),              //                .mem_ras_n
		.mem_cas_n                (e0_memory_mem_cas_n),              //                .mem_cas_n
		.mem_we_n                 (e0_memory_mem_we_n),               //                .mem_we_n
		.mem_reset_n              (e0_memory_mem_reset_n),            //                .mem_reset_n
		.mem_dq                   (e0_memory_mem_dq),                 //                .mem_dq
		.mem_dqs                  (e0_memory_mem_dqs),                //                .mem_dqs
		.mem_dqs_n                (e0_memory_mem_dqs_n),              //                .mem_dqs_n
		.mem_odt                  (e0_memory_mem_odt),                //                .mem_odt
		.local_init_done          (e0_emif_status_local_init_done),   //     emif_status.local_init_done
		.local_cal_success        (e0_emif_status_local_cal_success), //                .local_cal_success
		.local_cal_fail           (e0_emif_status_local_cal_fail),    //                .local_cal_fail
		.oct_rdn                  (oct_rdn),                          //             oct.rdn
		.oct_rup                  (oct_rup),                          //                .rup
		.drv_status_pass          (e0_drv_status_pass),               //      drv_status.pass
		.drv_status_fail          (e0_drv_status_fail),               //                .fail
		.drv_status_test_complete (e0_drv_status_test_complete),      //                .test_complete
		.local_powerdn_ack        (local_powerdn_ack),                // local_powerdown.local_powerdn_ack
		.local_powerdn_req        (local_powerdn_req)                 //                .local_powerdn_req
	);

	status_checker #(
		.ENABLE_VCDPLUS (0)
	) t0 (
		.clk               (e0_afi_clk_clk),                   //   avl_clock.clk
		.reset_n           (e0_afi_reset_reset),               //   avl_reset.reset_n
		.test_complete     (e0_drv_status_test_complete),      //  drv_status.test_complete
		.fail              (e0_drv_status_fail),               //            .fail
		.pass              (e0_drv_status_pass),               //            .pass
		.local_init_done   (e0_emif_status_local_init_done),   // emif_status.local_init_done
		.local_cal_success (e0_emif_status_local_cal_success), //            .local_cal_success
		.local_cal_fail    (e0_emif_status_local_cal_fail)     //            .local_cal_fail
	);

	alt_mem_if_ddr3_mem_model_top_ddr3_mem_if_dm_pins_en_mem_if_dqsn_en #(
		.MEM_IF_ADDR_WIDTH            (13),
		.MEM_IF_ROW_ADDR_WIDTH        (13),
		.MEM_IF_COL_ADDR_WIDTH        (10),
		.MEM_IF_CS_PER_RANK           (1),
		.MEM_IF_CONTROL_WIDTH         (1),
		.MEM_IF_DQS_WIDTH             (2),
		.MEM_IF_CS_WIDTH              (1),
		.MEM_IF_BANKADDR_WIDTH        (3),
		.MEM_IF_DQ_WIDTH              (16),
		.MEM_IF_CK_WIDTH              (1),
		.MEM_IF_CLK_EN_WIDTH          (1),
		.DEVICE_WIDTH                 (1),
		.MEM_TRCD                     (8),
		.MEM_TRTP                     (4),
		.MEM_DQS_TO_CLK_CAPTURE_DELAY (100),
		.MEM_CLK_TO_DQS_CAPTURE_DELAY (100000),
		.MEM_IF_ODT_WIDTH             (1),
		.MEM_MIRROR_ADDRESSING_DEC    (0),
		.MEM_REGDIMM_ENABLED          (0),
		.DEVICE_DEPTH                 (1),
		.MEM_GUARANTEED_WRITE_INIT    (0),
		.MEM_INIT_EN                  (0),
		.MEM_INIT_FILE                (""),
		.DAT_DATA_WIDTH               (32)
	) m0 (
		.mem_a       (e0_memory_mem_a),       // memory.mem_a
		.mem_ba      (e0_memory_mem_ba),      //       .mem_ba
		.mem_ck      (e0_memory_mem_ck),      //       .mem_ck
		.mem_ck_n    (e0_memory_mem_ck_n),    //       .mem_ck_n
		.mem_cke     (e0_memory_mem_cke),     //       .mem_cke
		.mem_cs_n    (e0_memory_mem_cs_n),    //       .mem_cs_n
		.mem_dm      (e0_memory_mem_dm),      //       .mem_dm
		.mem_ras_n   (e0_memory_mem_ras_n),   //       .mem_ras_n
		.mem_cas_n   (e0_memory_mem_cas_n),   //       .mem_cas_n
		.mem_we_n    (e0_memory_mem_we_n),    //       .mem_we_n
		.mem_reset_n (e0_memory_mem_reset_n), //       .mem_reset_n
		.mem_dq      (e0_memory_mem_dq),      //       .mem_dq
		.mem_dqs     (e0_memory_mem_dqs),     //       .mem_dqs
		.mem_dqs_n   (e0_memory_mem_dqs_n),   //       .mem_dqs_n
		.mem_odt     (e0_memory_mem_odt)      //       .mem_odt
	);

endmodule
