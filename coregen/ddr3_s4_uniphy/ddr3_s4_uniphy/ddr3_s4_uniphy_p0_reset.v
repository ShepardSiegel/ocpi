// (C) 2001-2011 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


(* altera_attribute = "-name GLOBAL_SIGNAL OFF" *)
module ddr3_s4_uniphy_p0_reset(
	seq_reset_mem_stable, 
	pll_afi_clk,
	pll_addr_cmd_clk,
	pll_dqs_ena_clk,
	seq_clk,
	scc_clk,
	pll_avl_clk,
	reset_n_scc_clk,
	reset_n_avl_clk,
	read_capture_clk,
	pll_locked,
	global_reset_n,
	soft_reset_n,
	csr_soft_reset_req,
	reset_request_n,
	ctl_reset_n,
	reset_n_afi_clk,
	reset_n_addr_cmd_clk,
	reset_n_resync_clk,
	reset_n_seq_clk,
	reset_n_read_capture_clk
);


parameter MEM_READ_DQS_WIDTH = ""; 

parameter NUM_AFI_RESET = 1;


input	seq_reset_mem_stable;

input	pll_afi_clk;
input	pll_addr_cmd_clk;
input	pll_dqs_ena_clk;
input	seq_clk;
input	scc_clk;
input	pll_avl_clk;
output	reset_n_scc_clk;
output	reset_n_avl_clk;
input	[MEM_READ_DQS_WIDTH-1:0] read_capture_clk;
input	pll_locked;
input	global_reset_n;
input	soft_reset_n;
input   csr_soft_reset_req;
output	reset_request_n;
output	ctl_reset_n;
output	[NUM_AFI_RESET-1:0] reset_n_afi_clk;
output	reset_n_addr_cmd_clk;
output	reset_n_resync_clk;
output	reset_n_seq_clk;
output	[MEM_READ_DQS_WIDTH-1:0] reset_n_read_capture_clk;

// Apply the synthesis keep attribute on the synchronized reset wires
// so that these names can be constrained using QSF settings to keep
// the resets on local routing.
wire	phy_reset_n /* synthesis keep = 1 */;
wire	phy_reset_mem_stable_n /* synthesis keep = 1*/;

wire	[MEM_READ_DQS_WIDTH-1:0] reset_n_read_capture;


	assign reset_request_n = pll_locked;
	assign phy_reset_mem_stable_n = phy_reset_n & seq_reset_mem_stable;
	assign reset_n_read_capture_clk = reset_n_read_capture;

	assign phy_reset_n = pll_locked & global_reset_n & soft_reset_n & (!csr_soft_reset_req);

	ddr3_s4_uniphy_p0_reset_sync	ureset_afi_clk(
		.reset_n		(phy_reset_n),
		.clk			(pll_afi_clk),
		.reset_n_sync	(reset_n_afi_clk)
	);
	defparam ureset_afi_clk.RESET_SYNC_STAGES = 5; 
	defparam ureset_afi_clk.NUM_RESET_OUTPUT = NUM_AFI_RESET;

	ddr3_s4_uniphy_p0_reset_sync	ureset_ctl_reset_clk(
		.reset_n		(phy_reset_n),
		.clk			(pll_afi_clk),
		.reset_n_sync	(ctl_reset_n)
	);
	defparam ureset_ctl_reset_clk.RESET_SYNC_STAGES = 5;

    ddr3_s4_uniphy_p0_reset_sync	ureset_addr_cmd_clk(
        .reset_n        (phy_reset_n),
        .clk            (pll_addr_cmd_clk),
        .reset_n_sync   (reset_n_addr_cmd_clk)
    );


	ddr3_s4_uniphy_p0_reset_sync	ureset_resync_clk(
		.reset_n		(phy_reset_n),
		.clk			(pll_dqs_ena_clk),
		.reset_n_sync	(reset_n_resync_clk)
	);

	ddr3_s4_uniphy_p0_reset_sync	ureset_seq_clk(
		.reset_n		(phy_reset_n),
		.clk			(seq_clk),
		.reset_n_sync	(reset_n_seq_clk)
	);

	ddr3_s4_uniphy_p0_reset_sync	ureset_scc_clk(
		.reset_n		(phy_reset_n),
		.clk			(scc_clk),
		.reset_n_sync	(reset_n_scc_clk)
	);

	ddr3_s4_uniphy_p0_reset_sync	ureset_avl_clk(
		.reset_n		(phy_reset_n),
		.clk			(pll_avl_clk),
		.reset_n_sync	(reset_n_avl_clk)
	);

generate
genvar i;
	for (i=0; i<MEM_READ_DQS_WIDTH; i=i+1)
	begin: read_capture_reset
    	ddr3_s4_uniphy_p0_reset_sync	ureset_read_capture_clk(
    	    .reset_n        (phy_reset_mem_stable_n),
    	    .clk            (read_capture_clk[i]),
    	    .reset_n_sync   (reset_n_read_capture[i])
    	);
	end
endgenerate

endmodule
