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


module altera_mem_if_ddr3_phy_0001_write_datapath(
	pll_afi_clk,
    reset_n,
	force_oct_off,
	phy_ddio_oct_ena,
	afi_dqs_en,
    afi_wdata,
    afi_wdata_valid,
    afi_dm,
    phy_ddio_dq,
	phy_ddio_dqs_en,
	phy_ddio_wrdata_en,
	phy_ddio_wrdata_mask	
);


parameter MEM_ADDRESS_WIDTH     = "";
parameter MEM_DM_WIDTH          = "";
parameter MEM_CONTROL_WIDTH     = "";
parameter MEM_DQ_WIDTH          = "";
parameter MEM_READ_DQS_WIDTH    = "";
parameter MEM_WRITE_DQS_WIDTH   = "";

parameter AFI_ADDRESS_WIDTH     = "";
parameter AFI_DATA_MASK_WIDTH   = "";
parameter AFI_CONTROL_WIDTH     = "";
parameter AFI_DATA_WIDTH        = "";
parameter AFI_DQS_WIDTH	        = "";
parameter NUM_WRITE_PATH_FLOP_STAGES = "";


input	pll_afi_clk;
input	reset_n;

input	[AFI_DQS_WIDTH-1:0] force_oct_off;
output	[AFI_DQS_WIDTH-1:0] phy_ddio_oct_ena;
input	[AFI_DQS_WIDTH-1:0]	afi_dqs_en;
input	[AFI_DATA_WIDTH-1:0]	afi_wdata;
input	[AFI_DQS_WIDTH-1:0]	afi_wdata_valid;
input	[AFI_DATA_MASK_WIDTH-1:0]   afi_dm;

output	[AFI_DATA_WIDTH-1:0]  phy_ddio_dq;
output	[AFI_DQS_WIDTH-1:0]   phy_ddio_dqs_en;
output	[AFI_DQS_WIDTH-1:0]   phy_ddio_wrdata_en;
output	[AFI_DATA_MASK_WIDTH-1:0]	phy_ddio_wrdata_mask;

wire	[AFI_DQS_WIDTH-1:0]   phy_ddio_dqs_en_pre_shift;
wire	[AFI_DATA_WIDTH-1:0]  phy_ddio_dq_pre_shift;
wire	[AFI_DQS_WIDTH-1:0]   phy_ddio_wrdata_en_pre_shift;
wire	[AFI_DATA_MASK_WIDTH-1:0]	phy_ddio_wrdata_mask_pre_shift;

generate
genvar stage;
if (NUM_WRITE_PATH_FLOP_STAGES == 0)
begin
	assign phy_ddio_dq_pre_shift = afi_wdata;
	assign phy_ddio_dqs_en_pre_shift = afi_dqs_en;
	assign phy_ddio_wrdata_en_pre_shift = afi_wdata_valid;
	assign phy_ddio_wrdata_mask_pre_shift = afi_dm;
end
else
begin
	reg	[AFI_DATA_WIDTH-1:0]  afi_wdata_r [NUM_WRITE_PATH_FLOP_STAGES-1:0];
	reg	[AFI_DQS_WIDTH-1:0]   afi_wdata_valid_r [NUM_WRITE_PATH_FLOP_STAGES-1:0] /* synthesis dont_merge */;
	reg	[AFI_DQS_WIDTH-1:0]   afi_dqs_en_r [NUM_WRITE_PATH_FLOP_STAGES-1:0];

	// phy_ddio_wrdata_mask is tied low during calibration
	// the purpose of the assignment is to avoid Quartus from connecting the signal to the sclr pin of the flop
	// sclr pin is very slow and causes timing failures
	(* altera_attribute = {"-name ALLOW_SYNCH_CTRL_USAGE OFF"}*) reg [AFI_DATA_MASK_WIDTH-1:0] afi_dm_r [NUM_WRITE_PATH_FLOP_STAGES-1:0];

	always @(posedge pll_afi_clk)
	begin
		afi_wdata_r[0] <= afi_wdata;
		afi_dqs_en_r[0] <= afi_dqs_en;
		afi_wdata_valid_r[0] <= afi_wdata_valid;
		afi_dm_r[0] <= afi_dm;
	end

	for (stage = 1; stage < NUM_WRITE_PATH_FLOP_STAGES; stage = stage + 1)
	begin : stage_gen
		always @(posedge pll_afi_clk)
		begin
			afi_wdata_r[stage] <= afi_wdata_r[stage-1];
			afi_dqs_en_r[stage] <= afi_dqs_en_r[stage-1];
			afi_wdata_valid_r[stage] <= afi_wdata_valid_r[stage-1];
			afi_dm_r[stage] <= afi_dm_r[stage-1];
		end
	end

	assign phy_ddio_dq_pre_shift = afi_wdata_r[NUM_WRITE_PATH_FLOP_STAGES-1];
	assign phy_ddio_dqs_en_pre_shift = afi_dqs_en_r[NUM_WRITE_PATH_FLOP_STAGES-1];
	assign phy_ddio_wrdata_en_pre_shift = afi_wdata_valid_r[NUM_WRITE_PATH_FLOP_STAGES-1];
	assign phy_ddio_wrdata_mask_pre_shift = afi_dm_r[NUM_WRITE_PATH_FLOP_STAGES-1];
	
end
endgenerate

wire [AFI_DQS_WIDTH-1:0] oct_ena;
reg [MEM_WRITE_DQS_WIDTH-1:0] dqs_en_reg;
always @(posedge pll_afi_clk)
	dqs_en_reg <= phy_ddio_dqs_en[AFI_DQS_WIDTH-1:MEM_WRITE_DQS_WIDTH];
assign oct_ena[AFI_DQS_WIDTH-1:MEM_WRITE_DQS_WIDTH] = ~phy_ddio_dqs_en[AFI_DQS_WIDTH-1:MEM_WRITE_DQS_WIDTH];
assign oct_ena[MEM_WRITE_DQS_WIDTH-1:0] = ~(phy_ddio_dqs_en[AFI_DQS_WIDTH-1:MEM_WRITE_DQS_WIDTH] | dqs_en_reg);
assign phy_ddio_oct_ena_pre_shift = oct_ena & ~force_oct_off;

 
	assign phy_ddio_dq = phy_ddio_dq_pre_shift;
	assign phy_ddio_wrdata_mask = phy_ddio_wrdata_mask_pre_shift;
	assign phy_ddio_wrdata_en = phy_ddio_wrdata_en_pre_shift;
	assign phy_ddio_dqs_en = phy_ddio_dqs_en_pre_shift;
	assign phy_ddio_oct_ena = phy_ddio_oct_ena_pre_shift;
  

endmodule
