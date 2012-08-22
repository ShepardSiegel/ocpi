// ddr3_s4_uniphy_example_sim.v

// 

`timescale 1 ps / 1 ps
module ddr3_s4_uniphy_example_sim (
		input  wire  pll_ref_clk,       //     pll_ref_clk.clk
		input  wire  global_reset_n,    //    global_reset.reset_n
		input  wire  soft_reset_n,      //      soft_reset.reset_n
		input  wire  oct_rdn,           //             oct.rdn
		input  wire  oct_rup,           //                .rup
		output wire  local_powerdn_ack, // local_powerdown.local_powerdn_ack
		input  wire  local_powerdn_req  //                .local_powerdn_req
	);

	ddr3_s4_uniphy_example_sim_ddr3_s4_uniphy_example_sim #(
		.ENABLE_VCDPLUS (0)
	) ddr3_s4_uniphy_example_sim_inst (
		.pll_ref_clk       (pll_ref_clk),       //     pll_ref_clk.clk
		.global_reset_n    (global_reset_n),    //    global_reset.reset_n
		.soft_reset_n      (soft_reset_n),      //      soft_reset.reset_n
		.oct_rdn           (oct_rdn),           //             oct.rdn
		.oct_rup           (oct_rup),           //                .rup
		.local_powerdn_ack (local_powerdn_ack), // local_powerdown.local_powerdn_ack
		.local_powerdn_req (local_powerdn_req)  //                .local_powerdn_req
	);

endmodule
