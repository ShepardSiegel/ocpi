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


`timescale 1 ps / 1 ps

module alt_mem_if_common_ddr_mem_model_ddr3_mem_if_dm_pins_en_mem_if_dqsn_en  
    # (parameter	 
        MEM_CLK_EN_WIDTH = 1,
        MEM_IF_BA_WIDTH = 2,
        MEM_IF_ADDR_WIDTH = 12, 
        MEM_IF_ROW_WIDTH = 12, 
        MEM_IF_COL_WIDTH = 10, 
        MEM_IF_CS_WIDTH = 1,
        MEM_IF_CS_PER_RANK = 1,
        MEM_DQS_WIDTH = 2,
        MEM_DQ_WIDTH = 16, 
        MEM_TRTP = 6,
        MEM_TRCD = 11,
        MEM_DQS_TO_CLK_CAPTURE_DELAY = 0,
        MEM_CLK_TO_DQS_CAPTURE_DELAY = 0,
        MEM_MIRROR_ADDRESSING = 0,
        MEM_DEPTH_IDX = -1,
        MEM_WIDTH_IDX = -1,
        MEM_REGDIMM_ENABLED = 0,
        MEM_INIT_EN = 0,
        MEM_INIT_FILE = "",
        MEM_GUARANTEED_WRITE_INIT = 0,
        DAT_DATA_WIDTH = 32
	 )                    
     (
	mem_a,
	mem_ba,
	mem_ck,
	mem_ck_n,
	mem_cke,
	mem_cs_n,
	mem_ras_n,
	mem_cas_n,
	mem_we_n,
	mem_reset_n,
	mem_dm,
	mem_dq,
	mem_dqs,
	mem_dqs_n,
	mem_odt
);

input	[MEM_IF_ADDR_WIDTH - 1:0]	mem_a;
input	[MEM_IF_BA_WIDTH - 1:0]	mem_ba;
input	mem_ck;
input	mem_ck_n;
input	[MEM_CLK_EN_WIDTH - 1:0] mem_cke;
input	[MEM_IF_CS_WIDTH - 1:0] mem_cs_n;
input	mem_ras_n;
input	mem_cas_n;
input	mem_we_n;
input	mem_reset_n;
input	[MEM_DQS_WIDTH - 1:0] mem_dm;
inout   [MEM_DQ_WIDTH - 1:0]	mem_dq;
inout   [MEM_DQS_WIDTH - 1:0]	mem_dqs;
inout   [MEM_DQS_WIDTH - 1:0]	mem_dqs_n;
input 	mem_odt;

//synthesis translate_off

reg		[MEM_IF_ADDR_WIDTH-1:0]	a;
reg		[MEM_IF_BA_WIDTH-1:0]	ba;
reg		cke;
reg		[MEM_IF_CS_WIDTH-1:0]	cs_n;
reg		ras_n;
reg		cas_n;
reg		we_n;
reg		odt;

generate
	if (MEM_REGDIMM_ENABLED) begin
		
		always @(posedge mem_ck) begin
			a <= #10 mem_a;
			ba <= #10 mem_ba;
			cke <= #10 mem_cke;
			cs_n <= #10 mem_cs_n;
			ras_n <= #10 mem_ras_n;
			cas_n <= #10 mem_cas_n;
			we_n <= #10 mem_we_n;
			odt <= #10 mem_odt;
		end
	end
	else begin
	
		always @(*) begin
			a <= mem_a;
			ba <= mem_ba;
			cke <= mem_cke;
			cs_n <= mem_cs_n;
			ras_n <= mem_ras_n;
			cas_n <= mem_cas_n;
			we_n <= mem_we_n;
			odt <= mem_odt;
		end
	end
endgenerate

`ifdef ENABLE_UNIPHY_SIM_SVA

// This is used just for regtests to verify that the test hasn't hung
parameter MAX_CYCLES_BETWEEN_ACTIVITY = 2000000;

generate
if (MAX_CYCLES_BETWEEN_ACTIVITY > 0)
begin
	// trigger a fake we_n edge at startup so that we can detect failure at startup
	reg startup_active = 0;

	initial 
	begin
		@(posedge mem_ck);
		startup_active <= 1;
		@(posedge mem_ck);
		startup_active <= 0;
	end
	
	mem_hang: assert property(memory_active)
		else $fatal(0, "No activity in %0d cycles", MAX_CYCLES_BETWEEN_ACTIVITY);
	
	// check that we always have activity within MAX_CYCLES_BETWEEN_ACTIVITY of previous activity (or startup)
	// Note, we check on both mem_ck and mem_ck_n since we may not have alignment with mem_ck
	property memory_active;
		@(posedge mem_ck or posedge mem_ck_n)
			((|mem_dqs) | startup_active) |-> ##[1:MAX_CYCLES_BETWEEN_ACTIVITY] $rose(|mem_dqs);
	endproperty
end
endgenerate

`endif // ENABLE_UNIPHY_SIM_SVA


generate
	if (MEM_REGDIMM_ENABLED) begin
		rdimm_chip
			# (
				.MEM_IF_BA_WIDTH(MEM_IF_BA_WIDTH),
				.MEM_IF_ADDR_WIDTH(MEM_IF_ADDR_WIDTH),
				.MEM_IF_CS_WIDTH(MEM_IF_CS_WIDTH),
					.MEM_DEPTH_IDX(MEM_DEPTH_IDX),
					.MEM_WIDTH_IDX(MEM_WIDTH_IDX)
			) rdimm_chip_i
			(	.a(a),
				.ba(ba),
				.ck(mem_ck),
				.cs_n(cs_n),
				.ras_n(ras_n),
				.cas_n(cas_n),
				.we_n(we_n)
			);
	end
endgenerate

generate
genvar rank;
    for (rank = 0; rank < MEM_IF_CS_WIDTH/MEM_IF_CS_PER_RANK; rank = rank + 1)
    begin : rank_gen
        mem_rank_model # (
                            .MEM_IF_BA_WIDTH (MEM_IF_BA_WIDTH),
                            .MEM_IF_ADDR_WIDTH (MEM_IF_ADDR_WIDTH),
                            .MEM_IF_ROW_ADDR_WIDTH (MEM_IF_ROW_WIDTH),
                            .MEM_IF_COL_ADDR_WIDTH (MEM_IF_COL_WIDTH),
                            .MEM_DQS_WIDTH (MEM_DQS_WIDTH),
                            .MEM_DQ_WIDTH (MEM_DQ_WIDTH),
                            .MEM_CS_WIDTH (MEM_IF_CS_PER_RANK),
                            .MEM_TRTP (MEM_TRTP),
                            .MEM_TRCD (MEM_TRCD),
			    .MEM_DQS_TO_CLK_CAPTURE_DELAY(MEM_DQS_TO_CLK_CAPTURE_DELAY),
			    .MEM_CLK_TO_DQS_CAPTURE_DELAY(MEM_CLK_TO_DQS_CAPTURE_DELAY),
			    // If the DIMM supports mirror addressing, all odd
			    // ranks must be configured that way
			    .MEM_MIRROR_ADDRESSING (MEM_MIRROR_ADDRESSING && (rank % 2)),
			    .MEM_DEPTH_IDX (MEM_DEPTH_IDX),
			    .MEM_WIDTH_IDX (MEM_WIDTH_IDX),
			    .MEM_RANK_IDX (rank),
                            .MEM_INIT_EN (MEM_INIT_EN),
                            .MEM_INIT_FILE (MEM_INIT_FILE),
			    .MEM_GUARANTEED_WRITE_INIT (MEM_GUARANTEED_WRITE_INIT),
                            .DAT_DATA_WIDTH (DAT_DATA_WIDTH)
                        ) rank_inst (
                        .mem_a       (a),
                        .mem_ba      (ba),
                        .mem_ck      (mem_ck),
                        .mem_ck_n    (mem_ck_n),   
                        .mem_cke     (cke),
                        .mem_cs_n    (cs_n[(rank+1)*MEM_IF_CS_PER_RANK-1:rank*MEM_IF_CS_PER_RANK]),
                        .mem_ras_n   (ras_n),
                        .mem_cas_n   (cas_n),
                        .mem_we_n    (we_n),
                        .mem_reset_n (mem_reset_n),
                        .mem_dm      (mem_dm),
                        .mem_dq      (mem_dq),
                        .mem_dqs     (mem_dqs),
                        .mem_dqs_n   (mem_dqs_n),
                        .mem_odt     (odt)
                    );
    end
endgenerate

endmodule

module rdimm_chip
    # (parameter 	
		MEM_IF_BA_WIDTH = 2,
		MEM_IF_ADDR_WIDTH = 12,
		MEM_IF_CS_WIDTH = 1,
       		MEM_DEPTH_IDX = -1,
		MEM_WIDTH_IDX = -1
	)
	(	a, 
		ba, 
		ck, 
		cs_n, 
		ras_n, 
		cas_n, 
		we_n
	);
	input [MEM_IF_ADDR_WIDTH - 1:0]	a;
	input [MEM_IF_BA_WIDTH - 1:0]	ba;
	input ck;
	input [MEM_IF_CS_WIDTH - 1:0] cs_n;
	input ras_n;
	input cas_n;
	input we_n;

	task automatic cmd_program_rdimm;
		bit [3:0] rdimm_addr = {ba[2], a[2], a[1], a[0]};
		bit [3:0] rdimm_d = {ba[1], ba[0], a[4], a[3]};
		$display("[%0t] [DW=%0d%0d]:  RDIMM RC%0d => %0H", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, rdimm_addr, rdimm_d);
	endtask

	always @ (posedge ck) begin
		// $display("%b %b %b %b", cs_n, ras_n, cas_n, we_n);
		if(cs_n == {MEM_IF_CS_WIDTH{1'b0}} && ras_n && cas_n && we_n) cmd_program_rdimm;
	end

endmodule

`timescale 1 ps / 1 ps

module mem_rank_model 
    # (parameter	 MEM_IF_BA_WIDTH = 2,
                     MEM_IF_ADDR_WIDTH = 12, 
                     MEM_IF_ROW_ADDR_WIDTH = 12, 
                     MEM_IF_COL_ADDR_WIDTH = 10, 
                     MEM_DQS_WIDTH = 2,
                     MEM_DQ_WIDTH = 16,
                     MEM_CS_WIDTH = 1,
                     MEM_TRTP = 6,
                     MEM_TRCD = 11,
		     MEM_DQS_TO_CLK_CAPTURE_DELAY = 0,
		     MEM_CLK_TO_DQS_CAPTURE_DELAY = 0,
		     MEM_MIRROR_ADDRESSING = 0,
       		     MEM_DEPTH_IDX = -1,
       		     MEM_WIDTH_IDX = -1,
       		     MEM_RANK_IDX = -1,
                     MEM_INIT_EN = 0,
                     MEM_INIT_FILE = "",
       		     MEM_GUARANTEED_WRITE_INIT = 0,
                     DAT_DATA_WIDTH = 32
       
	 )                    
     (
	mem_a,
	mem_ba,
	mem_ck,
	mem_ck_n,
	mem_cke,
	mem_cs_n,
	mem_ras_n,
	mem_cas_n,
	mem_we_n,
	mem_reset_n,
	mem_dm,
	mem_dq,
	mem_dqs,
	mem_dqs_n,
	mem_odt
);

localparam NUM_BANKS = 2**MEM_IF_BA_WIDTH;
localparam MEM_DQS_GROUP_SIZE = MEM_DQ_WIDTH / MEM_DQS_WIDTH;
//__ACDS_COMMENT_CHAR__ Enable verbose mode to have the model dump mode info
localparam VERBOSE_MODE = 1;        
localparam DISABLE_NOP_DISPLAY = 1;
localparam CHECK_VIOLATIONS = 1;
localparam REFRESH_INTERVAL_PS = 36000000;
localparam MAX_LATENCY = 22;
localparam MAX_BURST = 8;

input	[MEM_IF_ADDR_WIDTH - 1:0]	mem_a;
input	[MEM_IF_BA_WIDTH - 1:0]	mem_ba;
input	mem_ck;
input	mem_ck_n;
input	mem_cke;
input	[MEM_CS_WIDTH - 1:0] mem_cs_n;
input	[MEM_DQS_WIDTH - 1:0] mem_dm;
input	mem_ras_n;
input	mem_cas_n;
input	mem_we_n;
input	mem_reset_n;
inout   [MEM_DQ_WIDTH - 1:0]	mem_dq;
inout   [MEM_DQS_WIDTH - 1:0]	mem_dqs;
inout   [MEM_DQS_WIDTH - 1:0]	mem_dqs_n;
input 	mem_odt;

wire [MEM_IF_ADDR_WIDTH - 1:0] mem_a_wire;
wire [MEM_IF_BA_WIDTH - 1:0] mem_ba_wire;

wire [MEM_DQS_WIDTH - 1:0] mem_dqs_shifted;
wire [MEM_DQS_WIDTH - 1:0] mem_dqs_n_shifted;

typedef enum logic[3:0] {
	OPCODE_PRECHARGE = 4'b0010,
	OPCODE_ACTIVATE = 4'b0011,
	OPCODE_WRITE = 4'b0100,
	OPCODE_READ = 4'b0101,
	OPCODE_MRS = 4'b0000,
	OPCODE_REFRESH = 4'b0001,
	OPCODE_DES = 4'b1xxx,
	OPCODE_ZQC = 4'b0110,
	OPCODE_NOP = 4'b0111
} OPCODE_TYPE;

//__ACDS_COMMENT_CHAR__ Burst Type 
typedef enum {
	DDR_BURST_TYPE_BL8,
	DDR_BURST_TYPE_OTF,
	DDR_BURST_TYPE_BL4
} DDR_BURST_TYPE;

//__ACDS_COMMENT_CHAR__ Additive CAS Latency Type
typedef enum {
	DDR_AL_TYPE_ZERO,
	DDR_AL_TYPE_CL_MINUS_1,
	DDR_AL_TYPE_CL_MINUS_2
} DDR_AL_TYPE;

//__ACDS_COMMENT_CHAR__ Internal variables for memory parameters based on configuration
DDR_BURST_TYPE burst_type;
int cas_latency;
int cas_additive_latency;
int cas_write_latency;
DDR_AL_TYPE al_type;

// DDR3 timing parameters expressed in clock cycles
// IVAN: for now these are hard-coded, but they should
// be passed in as parameters
int tRTP_cycles = MEM_TRTP;
int tRCD_cycles = MEM_TRCD;

//__ACDS_COMMENT_CHAR__ Clock cycle counter
int clock_cycle;

//__ACDS_COMMENT_CHAR__ Clock status register
reg clock_stable;

//__ACDS_COMMENT_CHAR__ Bank counters
typedef struct {
	bit [MEM_IF_ROW_ADDR_WIDTH - 1:0] opened_row;
	time last_ref_time;
	int last_ref_cycle;
	int last_activate_cycle;
	int last_precharge_cycle;
	int last_write_cmd_cycle;
	int last_write_access_cycle;
	int last_read_cmd_cycle;
	int last_read_access_cycle;
} bank_struct;

//__ACDS_COMMENT_CHAR__ This is the actual storage variable
bit [MEM_DQ_WIDTH - 1:0] mem_data[*];

bank_struct banks [NUM_BANKS - 1:0];

//__ACDS_COMMENT_CHAR__ Command Type
typedef enum {
	DDR_CMD_TYPE_PRECHARGE,
	DDR_CMD_TYPE_ACTIVATE,
	DDR_CMD_TYPE_WRITE,
	DDR_CMD_TYPE_READ,
	DDR_CMD_TYPE_MRS,
	DDR_CMD_TYPE_REFRESH,
	DDR_CMD_TYPE_NOP,
	DDR_CMD_TYPE_DES,
	DDR_CMD_TYPE_ZQC,
	DDR_CMD_TYPE_ERROR
} DDR_CMD_TYPE;

typedef struct {
	DDR_CMD_TYPE cmd_type;
	int word_count;
	int burst_length;
	bit [MEM_IF_ADDR_WIDTH - 1:0] address;
	bit [MEM_IF_BA_WIDTH - 1:0] bank;
	bit [3:0] opcode;
} command_struct;


// Some simulators like NCsim don't yet support queues or arrays of structs
// As a result, unpack the command_struct.
// This is very dirty... so we should go back to an actual structure ASAP

// WRITE QUEUE
DDR_CMD_TYPE write_command_queue[$];
int write_word_count_queue[$];
int write_burst_length_queue[$];
bit [MEM_IF_ADDR_WIDTH - 1:0] write_address_queue[$];
bit [MEM_IF_BA_WIDTH - 1:0] write_bank_queue[$];

// READ QUEUE
DDR_CMD_TYPE read_command_queue[$];
int read_word_count_queue[$];
int read_burst_length_queue[$];
bit [MEM_IF_ADDR_WIDTH - 1:0] read_address_queue[$];
bit [MEM_IF_BA_WIDTH - 1:0] read_bank_queue[$];

// PRECHARGE QUEUE (necessary to handle auto-precharge
DDR_CMD_TYPE precharge_command_queue[$];
bit [MEM_IF_BA_WIDTH - 1:0] precharge_bank_queue[$];

// ACTIVATE QUEUE
DDR_CMD_TYPE activate_command_queue[$];
bit [MEM_IF_BA_WIDTH-1:0] activate_bank_queue[$];
bit [MEM_IF_ADDR_WIDTH-1:0] activate_row_queue[$];

command_struct active_command;
command_struct new_command;
command_struct precharge_command;
command_struct activate_command;

// Command pipelines to ensure read/write latency is met
// Latency is multiplied by 2 because it gets updated twice per clock
// cycle
bit [2 * MAX_LATENCY + 1:0] read_command_pipeline;
bit [2 * MAX_LATENCY + 1:0] write_command_pipeline;
bit [2 * MAX_LATENCY + 1:0] precharge_command_pipeline;
bit [2 * MAX_LATENCY + 1:0] activate_command_pipeline;

reg [MEM_DQ_WIDTH - 1:0]	mem_dq_int;
reg [MEM_DQ_WIDTH - 1:0]	mem_dq_captured;
reg [MEM_DQS_WIDTH - 1:0]	mem_dm_captured;
bit mem_dq_en;
bit mem_dqs_en;
bit mem_dqs_preamble;
wire [MEM_DQ_WIDTH - 1:0] full_mask;

time mem_dqs_time;
time mem_ck_time;


//__ACDS_COMMENT_CHAR__ Initialize the memory
localparam RATE_RATIO = (DAT_DATA_WIDTH > MEM_DQ_WIDTH) ? DAT_DATA_WIDTH / MEM_DQ_WIDTH : 2;
task init_mem;
    integer file, r;
    reg [MEM_DQ_WIDTH * RATE_RATIO - 1:0] avl_data;
    bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] avl_addr;
    bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] mem_addr_first;
    bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] mem_addr_second;
    bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] mem_addr_third;
    bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] mem_addr_forth;

    file = $fopen(MEM_INIT_FILE, "r");
    if (!file) begin
        $display("Can't find %s",MEM_INIT_FILE);
    end
    else begin

        while (!$feof(file)) begin
            r = $fscanf(file, "@%h %h \n", avl_addr, avl_data);
            if (VERBOSE_MODE)
                $display("Reading %s. avl_addr = %h, avl_data = %h", MEM_INIT_FILE, avl_addr, avl_data);

            mem_addr_first = avl_addr * 2 + 0;
            mem_addr_second = avl_addr * 2 + 1;
            mem_addr_third = avl_addr * 2 + 2;
            mem_addr_forth = avl_addr * 2 + 3;

            if (RATE_RATIO == 2) begin
                mem_data[mem_addr_first] = avl_data[MEM_DQ_WIDTH - 1:0];
                mem_data[mem_addr_second] = avl_data[MEM_DQ_WIDTH * 2 - 1:MEM_DQ_WIDTH];
                if (VERBOSE_MODE) begin
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_first, mem_data[mem_addr_first]);
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_second, mem_data[mem_addr_second]);
                end
            end
            else begin
                mem_data[mem_addr_first] = avl_data[MEM_DQ_WIDTH - 1:0];
                mem_data[mem_addr_second] = avl_data[MEM_DQ_WIDTH * 2 - 1:MEM_DQ_WIDTH];
                mem_data[mem_addr_third] = avl_data[MEM_DQ_WIDTH * 3 - 1:MEM_DQ_WIDTH * 2];
                mem_data[mem_addr_forth] = avl_data[MEM_DQ_WIDTH * 4 - 1:MEM_DQ_WIDTH * 3];
                if (VERBOSE_MODE) begin
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_first, mem_data[mem_addr_first]);
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_second, mem_data[mem_addr_second]);
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_third, mem_data[mem_addr_third]);
                    $display("Initializing the memory. addr = %h, mem_data = %h", mem_addr_forth, mem_data[mem_addr_forth]);
                end
            end
        end // while not EOF
    end
    $fclose(file);

endtask

task init_guaranteed_write;
	
	// to support bypassing guaranteed-write step in calibration, we pre-initialize
	// memory with the correct contents:
	// DDR2:
	// 0x55 at BRC 0/0/8 and 2/0/0, up to 8 bytes long each
	// 0xAA at BRC 2/0/8 and 0/0/0, up to 8 bytes long each
	// DDR3:
	// 0x55 at BRC 0/0/8 and 3/0/0, up to 8 bytes long each
	// 0xAA at BRC 3/0/8 and 0/0/0, up to 8 bytes long each
	int burst_length = 8;
	int other_bank = 3;
	
	int i;
	command_struct cmd;

	$display("Pre-initializing memory for guaranteed write");

	cmd.word_count = 0;
	cmd.burst_length = burst_length; // not used
	cmd.address = 0;
	cmd.bank = 0;
	cmd.opcode = OPCODE_WRITE;

	cmd.address = burst_length;
	cmd.bank = 0;
	for (i = 0; i < burst_length; i++)
	begin
		cmd.word_count = i;
		// write 32 bits and let task truncate as needed
		write_memory(cmd, 32'h5555, '0);
	end

	cmd.address = 0;
	cmd.bank = other_bank;
	for (i = 0; i < burst_length; i++)
	begin
		cmd.word_count = i;
		// write 32 bits and let task truncate as needed
		write_memory(cmd, 32'h5555, '0);
	end

	cmd.address = burst_length;
	cmd.bank = other_bank;
	for (i = 0; i < burst_length; i++)
	begin
		cmd.word_count = i;
		// write 32 bits and let task truncate as needed
		write_memory(cmd, 32'hAAAA, '0);
	end

	cmd.address = 0;
	cmd.bank = 0;
	for (i = 0; i < burst_length; i++)
	begin
		cmd.word_count = i;
		// write 32 bits and let task truncate as needed
		write_memory(cmd, 32'hAAAA, '0);
	end

endtask

//==========================================================================//
//                        Tasks and Functions                               //
//==========================================================================//
function automatic int min;
	// Return the minimum of two numbers
	input int a;
	input int b;
	int result = (a < b) ? a : b;
	return result;
endfunction

task automatic initialize_db;
	// Delete the existing command queue by iterating through the queue
	while (write_command_queue.size() > 0)
		write_command_queue.delete(0);
	while (write_word_count_queue.size() > 0)
		write_word_count_queue.delete(0);
	while (write_burst_length_queue.size() > 0)
		write_burst_length_queue.delete(0);
	while (write_address_queue.size() > 0)
		write_address_queue.delete(0);
	while (write_bank_queue.size() > 0)
		write_bank_queue.delete(0);

	while (read_command_queue.size() > 0)
		read_command_queue.delete(0);
	while (read_word_count_queue.size() > 0)
		read_word_count_queue.delete(0);
	while (read_burst_length_queue.size() > 0)
		read_burst_length_queue.delete(0);
	while (read_address_queue.size() > 0)
		read_address_queue.delete(0);
	while (read_bank_queue.size() > 0)
		read_bank_queue.delete(0);

	while (precharge_command_queue.size() > 0)
		precharge_command_queue.delete(0);
	while (precharge_bank_queue.size() > 0)
		precharge_bank_queue.delete(0);

    while (activate_command_queue.size() > 0)
        activate_command_queue.delete(0);
    while (activate_bank_queue.size() > 0)
        activate_bank_queue.delete(0);
    while (activate_row_queue.size() > 0)
        activate_row_queue.delete(0);

	// Delete the memory
	mem_data.delete();
endtask

task automatic set_cas_latency (input bit [2:0] code);
    case(code)
            3'b001 : cas_latency = 5;
            3'b010 : cas_latency = 6;
            3'b011 : cas_latency = 7;
            3'b100 : cas_latency = 8;
            3'b101 : cas_latency = 9;
            3'b110 : cas_latency = 10;
            3'b111 : cas_latency = 11;
        default: begin
        end
    endcase
    if (VERBOSE_MODE) begin
        $display("   CAS LATENCY set to : %0d", cas_latency);
    end
    
endtask

    task automatic set_additive_latency (input bit [1:0] code);
        case(code)
            3'b00 : begin
                if (VERBOSE_MODE)
                    $display("   Setting Additive CAS LATENCY to 0");
                al_type = DDR_AL_TYPE_ZERO;
            end
            3'b01 : begin
                if (VERBOSE_MODE)
                    $display("   Setting Additive CAS LATENCY to CL - 1");
                al_type = DDR_AL_TYPE_CL_MINUS_1;
            end
            3'b10 : begin 
                if (VERBOSE_MODE)
                    $display("   Setting Additive CAS LATENCY to CL - 2");
                al_type = DDR_AL_TYPE_CL_MINUS_2;
            end
            3'b11 : begin
                $display("Error: Use of reserved Addirive CAS latency code : %b", code);
                $stop(1);
            end
        endcase
    endtask
    
    function automatic int get_additive_latency;
        int additive_latency = 0;
    
        case(al_type)
            DDR_AL_TYPE_ZERO : begin
            end
            DDR_AL_TYPE_CL_MINUS_1 : begin
                additive_latency = cas_latency - 1;
            end
            DDR_AL_TYPE_CL_MINUS_2 : begin
                additive_latency = cas_latency - 2;
            end
            default : begin
                $display("Error: Unknown additive latency type: %0d", al_type);
            end
        endcase
        return additive_latency;
    endfunction

function automatic int get_read_latency;
	// This function computes the latency of read
	int read_latency = cas_latency + get_additive_latency();
	return read_latency;
endfunction

function automatic int get_write_latency;
	// This function computes the latency of write
	int write_latency = cas_write_latency + get_additive_latency();
	return write_latency;
endfunction

function automatic int get_precharge_latency;
	// This function computes the latency of auto-precharge 

	// IVAN: Notice that this is the basic computation
	// If this value breaks the tRAS requirement, it should be adjusted
	// to satisfy it. This is currently NOT supported
	int precharge_latency = tRTP_cycles + get_additive_latency();
	return precharge_latency;
endfunction

    task automatic set_cas_write_latency (input bit [2:0] code);
        case(code)
            3'b000 : cas_write_latency = 5;
            3'b001 : cas_write_latency = 6;
            3'b010 : cas_write_latency = 7;
            3'b011 : cas_write_latency = 8;
            default : begin
                $display("Error: Use of reserved CAS WRITE latency code : %b", code);
                $stop(1);
            end
        endcase
    
        if (VERBOSE_MODE)
            $display("   CAS WRITE LATENCY set to : %0d", cas_write_latency);
    endtask

task automatic reset_dll (input bit code);
	if(code == 1'b1) begin
		if (VERBOSE_MODE)
			$display("   Resetting DLL");
	end
endtask

    task automatic set_burst_type (input bit [1:0] burst_mode);
        case (burst_mode)
            2'b00 : begin
                    if (VERBOSE_MODE)
                        $display("   Setting burst length Fixed BL8");
                    burst_type = DDR_BURST_TYPE_BL8;
                    end
            2'b01 : begin
                    if (VERBOSE_MODE)
                        $display("   Setting burst length on-the-fly");
                    burst_type = DDR_BURST_TYPE_OTF;
                    end
            2'b10 : begin
                    if (VERBOSE_MODE)
                        $display("   Setting burst length Fixed BL4");
                    burst_type = DDR_BURST_TYPE_BL4;
                    end
            default : begin
                $display("Invalid burst type mode %0d specified!", burst_mode);
                $finish(1);
                end
        endcase
    endtask

task automatic cmd_nop;
	if (VERBOSE_MODE && !DISABLE_NOP_DISPLAY)
		$display("[%0t] [DWR=%0d%0d%0d]:  NOP Command", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
endtask

task automatic cmd_des;
	if (VERBOSE_MODE && !DISABLE_NOP_DISPLAY)
		$display("[%0t] [DWR=%0d%0d%0d]:  DES Command", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
endtask

task automatic cmd_zqc;
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  ZQC Command", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
endtask

task automatic cmd_unknown;
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  WARNING: Unknown Command (OPCODE %b). Command ignored.", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.opcode);
endtask

task automatic cmd_set_activate;
	int activate_latency = min(get_read_latency(), get_write_latency()) + 1;

	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  ACTIVATE (queue) - BANK [ %0h ] - ROW [ %0h ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.bank, new_command.address);
	activate_command_queue.push_back(DDR_CMD_TYPE_ACTIVATE);
	activate_bank_queue.push_back(new_command.bank);
	activate_row_queue.push_back(new_command.address);

	activate_command_pipeline[ 2 * activate_latency ] = 1;
    banks[new_command.bank].last_activate_cycle = clock_cycle;
endtask

task automatic cmd_activate(bit [MEM_IF_BA_WIDTH-1:0] bank, bit [MEM_IF_ADDR_WIDTH-1:0] address);
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  ACTIVATE (execute) - BANK [ %0h ] - ROW [ %0h ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, bank, address);

	// IVAN The activate time should be annotated to the back

	banks[bank].opened_row = address;
endtask

task automatic cmd_precharge(bit [2:0] bank, bit all_banks);
	if (VERBOSE_MODE)
		if(all_banks)
			$display("[%0t] [DWR=%0d%0d%0d]:  PRECHARGE - ALL BANKS", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
		else
			$display("[%0t] [DWR=%0d%0d%0d]:  PRECHARGE - BANK [ %0d ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, bank);

	banks[mem_ba_wire].last_precharge_cycle = clock_cycle;
endtask

task automatic cmd_mrs;
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  MRS Command - MRS [ %0d ] -> %0h", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.bank, new_command.address);

	case(new_command.bank)
		3'b000 : begin
			if (VERBOSE_MODE)
				$display("   MRS - 0");

			// Set the burst length
                set_burst_type(new_command.address[1:0]);
			set_cas_latency(new_command.address[6:4]);

			reset_dll(new_command.address[8]);
		end

		3'b001 : begin
			if (VERBOSE_MODE)
				$display("   MRS - 1");
                set_additive_latency(new_command.address[4:3]);
		end

		3'b010 : begin
                if (VERBOSE_MODE)
                    $display("   MRS - 2");
    
                set_cas_write_latency(new_command.address[5:3]);
		end

		3'b011 : begin
			if (VERBOSE_MODE)
				$display("   MRS - 3: not supported");
		end

		default : begin
			$display("Error: MRS Invalid Bank Address: %0d", new_command.bank);

			$stop(1);
		end
	endcase
endtask

task automatic cmd_refresh;
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  REFRESH Command", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);

	//IVAN: for now we don't do anything here, since there's no checking
	//performed on refresh time

endtask

task automatic cmd_read;
	int read_latency = get_read_latency();
	int precharge_latency = get_precharge_latency();

	if (VERBOSE_MODE)
		if(mem_a_wire[10])
			$display("[%0t] [DWR=%0d%0d%0d]:  READ with AP (BL%0d) - BANK [ %0d ] - COL [ %0h ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.burst_length, new_command.bank, new_command.address);
		else
			$display("[%0t] [DWR=%0d%0d%0d]:  READ (BL%0d) - BANK [ %0d ] - COL [ %0h ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.burst_length, new_command.bank, new_command.address);
	
	new_command.word_count = 0;
	
	read_command_queue.push_back(new_command.cmd_type);
	read_word_count_queue.push_back(new_command.word_count);
	read_burst_length_queue.push_back(new_command.burst_length);
	read_address_queue.push_back(new_command.address);
	read_bank_queue.push_back(new_command.bank);

	// Latency is multiplied by 2 because it gets updated twice per clock
	// cycle.
	read_command_pipeline[ 2 * read_latency ] = 1;
	
	banks[mem_ba_wire].last_read_cmd_cycle = clock_cycle;

	// Reads also count as a refresh
	refresh_bank(mem_ba_wire);
		
	// Take care of auto-precharge if needed
	if(mem_a_wire[10]) begin
		precharge_command_queue.push_back(DDR_CMD_TYPE_PRECHARGE);
		precharge_bank_queue.push_back(new_command.bank);

		// Latency is multiplied by 2 because it gets updated twice per clock
		// cycle.
		precharge_command_pipeline[ 2 * precharge_latency ] = 1;
	end
endtask

task automatic cmd_write;
	int write_latency = get_write_latency();

	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  WRITE (BL%0d) - BANK [ %0d ] - COL [ %0h ]", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, new_command.burst_length, new_command.bank, new_command.address);
	
	new_command.word_count = 0;
	
	write_command_queue.push_back(new_command.cmd_type);
	write_word_count_queue.push_back(new_command.word_count);
	write_burst_length_queue.push_back(new_command.burst_length);
	write_address_queue.push_back(new_command.address);
	write_bank_queue.push_back(new_command.bank);

	// Latency is multiplied by 2 because it gets updated twice per clock
	// cycle.
	write_command_pipeline[2 * write_latency] = 1'b1;
	
	banks[mem_ba_wire].last_write_cmd_cycle = clock_cycle;
endtask

task automatic refresh_command;
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  Refresh Command to bank %0h", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, mem_ba_wire);
	refresh_bank(mem_ba_wire);
endtask

task automatic refresh_bank(input int bank_num);
	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  Refreshing bank %0h", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, bank_num);
	banks[bank_num].last_ref_time = $time;
	banks[bank_num].last_ref_cycle = clock_cycle;
endtask

task automatic init_banks;
	int i;
	for (i = 0; i < NUM_BANKS; i++) begin
		if (VERBOSE_MODE)
			$display("[%0t] [DWR=%0d%0d%0d]:  Initializing bank %0d", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, i);
		banks[i].opened_row = '0;
		banks[i].last_ref_time = 0;
		banks[i].last_ref_cycle = 0;
		banks[i].last_activate_cycle = 0;
		banks[i].last_precharge_cycle = 0;
		banks[i].last_read_cmd_cycle = 0;
		banks[i].last_read_access_cycle = 0;
		banks[i].last_write_cmd_cycle = 0;
		banks[i].last_write_access_cycle = 0;
	end
		
endtask

task automatic check_violations;
	int i;

	/* **** *
	 * tRCD *
	 * **** */

	// Check only if the current command is a READ
	if(new_command.cmd_type == DDR_CMD_TYPE_READ) begin
		if(banks[new_command.bank].last_activate_cycle > banks[new_command.bank].last_read_cmd_cycle - tRCD_cycles) begin
			$display("[%0t] [DWR=%0d%0d%0d]:  ERROR: tRCD violation (READ) on bank %0d @ cycle %0d", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, i, clock_cycle);
			$display("    tRCD = %0d", tRCD_cycles);
			$display("    Last ACTIVATE @ %0d", banks[new_command.bank].last_activate_cycle);
			$display("    Last READ CMD @ %0d", banks[new_command.bank].last_read_cmd_cycle);
		end
	end
	// Check only if the current command is a WRITE
	if(new_command.cmd_type == DDR_CMD_TYPE_WRITE) begin
		if(banks[new_command.bank].last_activate_cycle > banks[new_command.bank].last_write_cmd_cycle - tRCD_cycles) begin
			$display("[%0t] [DWR=%0d%0d%0d]:  ERROR: tRCD violation (WRITE) on bank %0d @ cycle %0d", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, i, clock_cycle);
			$display("    tRCD = %0d", tRCD_cycles);
			$display("    Last ACTIVATE @ %0d", banks[new_command.bank].last_activate_cycle);
			$display("    Last WRITE CMD @ %0d", banks[new_command.bank].last_write_cmd_cycle);
		end
	end
endtask

task write_memory(
	input command_struct write_command,
	input [MEM_DQ_WIDTH - 1:0] write_data,
	input [MEM_DQ_WIDTH - 1:0] data_mask);

	bit [MEM_IF_BA_WIDTH - 1:0] bank_address;
	bit [MEM_IF_ROW_ADDR_WIDTH - 1:0] row_address;
	bit [MEM_IF_COL_ADDR_WIDTH - 1:0] col_address;
	bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] address;
	bit [MEM_DQ_WIDTH - 1:0] masked_data;

	integer i;

	bank_address = write_command.bank;

	row_address = banks[bank_address].opened_row;
	col_address = write_command.address;
	address = {bank_address, row_address, col_address} + write_command.word_count;

	// If a bit in the data_mask is equal to 1, the memory content is not
	// modified, otherwise it's replaced by the new data
	for(i = 0; i < MEM_DQ_WIDTH; i = i + 1) begin
		if (data_mask[i] !== 0 && data_mask[i] !== 1)
			masked_data[i] = 'x;
		else if (data_mask[i])
			masked_data[i] = mem_data[address][i];
		else
			masked_data[i] = write_data[i];
	end

	if (VERBOSE_MODE)
		$display("[%0t] [DWR=%0d%0d%0d]:  Writing data %h (%h/%h) @ %0h (BRC=%0h/%0h/%0h ) burst %0d", 
			$time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, masked_data, write_data, ~data_mask, address, bank_address, row_address, col_address, write_command.word_count);

	mem_data[address] = masked_data;
	banks[bank_address].last_write_access_cycle = clock_cycle;

endtask

task read_memory(
	input command_struct write_command,
	output [MEM_DQ_WIDTH - 1:0] read_data);

	bit [MEM_IF_BA_WIDTH - 1:0] bank_address;
	bit [MEM_IF_ROW_ADDR_WIDTH - 1:0] row_address;
	bit [MEM_IF_COL_ADDR_WIDTH - 1:0] col_address;
	bit [MEM_IF_BA_WIDTH + MEM_IF_ROW_ADDR_WIDTH + MEM_IF_COL_ADDR_WIDTH - 1 : 0] address;

	bank_address = write_command.bank;
	// Check that this bank as an open row

	row_address = banks[bank_address].opened_row;
	col_address = write_command.address;
	address = {bank_address, row_address, col_address} + write_command.word_count;

	if (mem_data.exists(address)) begin
		read_data = mem_data[address];
		if (VERBOSE_MODE)
			$display("[%0t] [DWR=%0d%0d%0d]:  Reading data %h @ %0h (BRC=%0h/%0h/%0h ) burst %0d", 
				$time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, read_data, address, bank_address, row_address, col_address, write_command.word_count);
	end
	else begin
		$display("[%0t] [DWR=%0d%0d%0d]:  WARNING: Attempting to read from invalid address @ %0h (BRC=%0h/%0h/%0h) burst %0d", 
			$time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, address, bank_address, row_address, col_address, write_command.word_count);
		read_data = 'X;
	end

	banks[bank_address].last_read_access_cycle = clock_cycle;
endtask

//==========================================================================//
//                           Model Start                                    //
//==========================================================================//

if(MEM_MIRROR_ADDRESSING) begin
	// Swap address bits 3,4 - 5,6 - 7,8
	assign mem_a_wire = {mem_a[MEM_IF_ADDR_WIDTH - 1:9], mem_a[7], mem_a[8], mem_a[5], mem_a[6], mem_a[3], mem_a[4], mem_a[2:0]};

	// Swap Bank Address bits 0,1
	if(MEM_IF_BA_WIDTH > 2) begin
		assign mem_ba_wire = {mem_ba[MEM_IF_BA_WIDTH - 1:2], mem_ba[0], mem_ba[1]};
	end
	else begin
		assign mem_ba_wire = {mem_ba[0], mem_ba[1]};
	end
end
else begin
	assign mem_a_wire = mem_a;
	assign mem_ba_wire = mem_ba;
end

// Internal version of mem_ck based on differential clock
logic mem_ck_diff;
always @(posedge mem_ck) #8 mem_ck_diff <= mem_ck;
always @(posedge mem_ck_n) #8 mem_ck_diff <= ~mem_ck_n;

initial begin
	int i;
	
	$display("Altera Generic DDR3 Memory Model");
	if (VERBOSE_MODE) begin
		$display("[%0t] [DWR=%0d%0d%0d]:  Max refresh interval of %0d ps", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX, REFRESH_INTERVAL_PS);
	end
	
	// Clear the clock cycle counter
	clock_cycle = 0;
	clock_stable = 1'b0;
	
	// On startup set the configuration mode
	initialize_db;
	set_burst_type(2'b0);

	// Reset all banks
	init_banks();
	
	// Delete the memory
	mem_data.delete();

	// Initialie memory
	if (MEM_INIT_EN)
		init_mem();

	if (MEM_GUARANTEED_WRITE_INIT)
	begin
		init_guaranteed_write();
	end

	// Make the active command a NOP
	active_command.cmd_type <= DDR_CMD_TYPE_NOP;
	
	// Clear the command pipelines
	for (i = 0; i < 2 * MAX_LATENCY; i++) begin
		read_command_pipeline[i] = 0;
		write_command_pipeline[i] = 0;
	end
end

// Update the clock cycle counter
always @ (posedge mem_ck) begin
	clock_cycle <= clock_cycle + 1;
	if (clock_cycle == 4) clock_stable <= 1'b1;
end

wire [MEM_IF_COL_ADDR_WIDTH-1:0] col_addr;
generate
	// Need to skip a[10] (Auto-Precharge)
	if(MEM_IF_COL_ADDR_WIDTH <= 10) begin : col_addr_gen1
		assign col_addr = mem_a_wire[9:0];
	end
	// Need to skip a[12] (Burst Chop)
	else if(MEM_IF_COL_ADDR_WIDTH == 11) begin : col_addr_gen2
		assign col_addr = {mem_a_wire[11],mem_a_wire[9:0]};
	end
	else begin : col_addr_gen3
		assign col_addr = {mem_a_wire[MEM_IF_COL_ADDR_WIDTH+1:13],mem_a_wire[11],mem_a_wire[9:0]};
	end
endgenerate

always @ (posedge mem_ck_diff or negedge mem_ck_diff) begin
	
	mem_ck_time = $time;
	
	// Shift the command pipelines
	read_command_pipeline = read_command_pipeline >> 1;
	write_command_pipeline = write_command_pipeline >> 1;
    activate_command_pipeline = activate_command_pipeline >> 1;
    
        if(mem_ck_diff && clock_stable) begin
            // Process the new commands on the pins
            new_command.bank = mem_ba_wire;
            new_command.word_count = 0;
            new_command.opcode = {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n};
    
            // Set the burst length based on MRS configuration and/or A12
            case (burst_type)
                DDR_BURST_TYPE_BL8 : new_command.burst_length = 8;
                DDR_BURST_TYPE_BL4 : new_command.burst_length = 4;
                    DDR_BURST_TYPE_OTF : new_command.burst_length = (mem_a_wire[12]) ? 8 : 4;
            endcase
                
            casex (new_command.opcode)
                OPCODE_PRECHARGE : new_command.cmd_type = DDR_CMD_TYPE_PRECHARGE;
                OPCODE_ACTIVATE : new_command.cmd_type = DDR_CMD_TYPE_ACTIVATE;
                OPCODE_WRITE : new_command.cmd_type = DDR_CMD_TYPE_WRITE;
                OPCODE_READ : new_command.cmd_type = DDR_CMD_TYPE_READ;
                OPCODE_MRS : new_command.cmd_type = DDR_CMD_TYPE_MRS;
                OPCODE_REFRESH : new_command.cmd_type = DDR_CMD_TYPE_REFRESH;
                OPCODE_NOP : new_command.cmd_type = DDR_CMD_TYPE_NOP;
                OPCODE_DES : new_command.cmd_type = DDR_CMD_TYPE_DES;
                OPCODE_ZQC : new_command.cmd_type = DDR_CMD_TYPE_ZQC;
                default : new_command.cmd_type = DDR_CMD_TYPE_ERROR;
            endcase
    
            new_command.address = mem_a_wire;
            // Memory address needs to be corrected for READ/WRITE operations
            if(new_command.cmd_type == DDR_CMD_TYPE_READ || new_command.cmd_type == DDR_CMD_TYPE_WRITE) begin
		new_command.address = {'0,col_addr};
            end
            
            case (new_command.cmd_type)
                DDR_CMD_TYPE_NOP : cmd_nop();
                DDR_CMD_TYPE_DES : cmd_des();
                DDR_CMD_TYPE_ZQC : cmd_zqc();
                DDR_CMD_TYPE_ERROR : cmd_unknown();
                DDR_CMD_TYPE_ACTIVATE : cmd_set_activate();
                DDR_CMD_TYPE_PRECHARGE : cmd_precharge(new_command.bank, mem_a_wire[10]);
                DDR_CMD_TYPE_WRITE : cmd_write();
                DDR_CMD_TYPE_READ : cmd_read();
                DDR_CMD_TYPE_MRS : cmd_mrs();
                DDR_CMD_TYPE_REFRESH : cmd_refresh();
            endcase
    
            // Now that the current command has been identified check that
            // no violation is occuring in this clock cycle
            if(CHECK_VIOLATIONS)
                check_violations();
        end
        
        if (read_command_pipeline[0]) begin
            if (read_command_queue.size() == 0) begin
                $display("[%0t] [DWR=%0d%0d%0d]:  Internal Error: READ command queue empty but READ commands expected!", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
                $stop(1);
            end
        end
    
        if (write_command_pipeline[0]) begin
            if (write_command_queue.size() == 0) begin
                $display("[%0t] [DWR=%0d%0d%0d]:  Internal Error: WRITE command queue empty but WRITE commands expected!", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
                $stop(1);
            end
        end
    
        // Determine if any active command is finished
        if (active_command.cmd_type != DDR_CMD_TYPE_NOP) begin
            if (active_command.word_count == active_command.burst_length) begin
                // Command complete
                active_command.cmd_type = DDR_CMD_TYPE_NOP;
            end
        end
        
    
        // Is there an active read/write on this cycle?
        if (active_command.cmd_type == DDR_CMD_TYPE_NOP) begin
            if (read_command_pipeline[0]) begin
                active_command.cmd_type = read_command_queue.pop_front();
                active_command.word_count = read_word_count_queue.pop_front();
                active_command.burst_length = read_burst_length_queue.pop_front();
                active_command.address = read_address_queue.pop_front();
                active_command.bank = read_bank_queue.pop_front();
    
                if (active_command.cmd_type != DDR_CMD_TYPE_READ) begin
                    $display("[%0t] [DWR=%0d%0d%0d]:  Internal Error: Expected READ command not in queue!", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
                    $stop(1);
                end
                
            end
            else if (write_command_pipeline[0]) begin
                active_command.cmd_type = write_command_queue.pop_front();
                active_command.word_count = write_word_count_queue.pop_front();
                active_command.burst_length = write_burst_length_queue.pop_front();
                active_command.address = write_address_queue.pop_front();
                active_command.bank = write_bank_queue.pop_front();
    
                if (active_command.cmd_type != DDR_CMD_TYPE_WRITE) begin
                    $display("[%0t] [DWR=%0d%0d%0d]:  Internal Error: Expected WRITE command not in queue!", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
                    $stop(1);
                end
                
            end
        end
        else begin
            // Make sure no other command is trying to be active
            if (read_command_pipeline[0] || write_command_pipeline[0]) begin
                $display("[%0t] [DWR=%0d%0d%0d]:  Internal Error: Active command but read/write pipeline also active!", $time, MEM_DEPTH_IDX, MEM_WIDTH_IDX, MEM_RANK_IDX);
                $stop(1);
            end
        end
    
        // Execute auto-precharge
        if (precharge_command_pipeline[0]) begin
            precharge_command.cmd_type = precharge_command_queue.pop_front();
            precharge_command.bank = precharge_bank_queue.pop_front();
    
            cmd_precharge(precharge_command.bank, 1'b0);
        end
        
        if (activate_command_pipeline[0]) begin
            activate_command.cmd_type = activate_command_queue.pop_front();
            activate_command.bank = activate_bank_queue.pop_front();
            activate_command.address = activate_row_queue.pop_front();
            
            cmd_activate(activate_command.bank, activate_command.address);
        end
    
        // Process any active command
        mem_dq_en = 1'b0;
        mem_dqs_en = 1'b0;
        mem_dqs_preamble = 1'b0;
        if (active_command.cmd_type == DDR_CMD_TYPE_WRITE) begin
			// Since this memory model doesn't accurately model the memory device capture
			// logic, write operation where DQS arrives after MEM_CK will result in the
			// first bit to be lost. Note that in real memory devices MEM_CK and DQS can
			// be off by up-to a quarter of a cycle both ways.
			// In order to guarantee that we don't try to store data before
			// it gets captured, I'm delaying the write_memory operation.
	    // FIXME: the window should be configurable from a file for maximum flexibility
	    integer mem_ck_dqs_diff;
            #(MEM_DQS_TO_CLK_CAPTURE_DELAY);
	    if (mem_ck_time > mem_dqs_time) begin
		mem_ck_dqs_diff = -(mem_ck_time - mem_dqs_time);
	    end 
	    else begin
		mem_ck_dqs_diff = mem_dqs_time - mem_ck_time;
	    end
	    if (mem_ck_dqs_diff >= -(MEM_CLK_TO_DQS_CAPTURE_DELAY)) begin
	        write_memory(active_command, mem_dq_captured, full_mask);
	    end 
	    else begin
		$display("[%0t] %s Write: mem_ck=%0t mem_dqs=%0t delta=%0d min=%0d", 
			 $time, mem_ck_dqs_diff >= -(MEM_CLK_TO_DQS_CAPTURE_DELAY) ? "GOOD" : "BAD",
			 mem_ck_time, mem_dqs_time, mem_ck_dqs_diff, -(MEM_CLK_TO_DQS_CAPTURE_DELAY));
	        write_memory(active_command, 'x, 'x);
	    end
            active_command.word_count = active_command.word_count+1;
        end
        else if (active_command.cmd_type == DDR_CMD_TYPE_READ) begin
            read_memory(active_command, mem_dq_int);
            mem_dq_en = 1'b1;
            mem_dqs_en = 1'b1;
            active_command.word_count = active_command.word_count+1;
        end
    
        // Generate Preamble when necessary
        if (!mem_dqs_en & (read_command_pipeline[2] | read_command_pipeline[1])) begin
            mem_dqs_en = 1'b1;
            mem_dqs_preamble = 1'b1;
        end
end

generate
genvar dm_count;
	for (dm_count = 0; dm_count < MEM_DQS_WIDTH; dm_count = dm_count + 1)
	begin: dm_mapping
		assign full_mask [(dm_count + 1) * MEM_DQS_GROUP_SIZE - 1 : dm_count * MEM_DQS_GROUP_SIZE] = {MEM_DQS_GROUP_SIZE{mem_dm_captured[dm_count]}};
	end
endgenerate

// IVAN: for now only use DQS[0] to capture data
// Data is captured on both edges of DQS
assign #1 mem_dqs_shifted = mem_dqs;
assign #1 mem_dqs_n_shifted = mem_dqs_n;
// for ddr3, we need to ignore the first dqs_n posedge since it's part of the preamble
// we remember what we transitions from so that we can check below whether this is
// the first edge and hence invalid
wire mem_dqs_n_shifted_2;
reg mem_dqs_n_shifted_2_prev = 'z;
assign #2 mem_dqs_n_shifted_2 = mem_dqs_n;
always @(posedge mem_dqs_shifted[0] or posedge mem_dqs_n_shifted[0]) begin
	mem_dqs_time <= $time;
	mem_dq_captured <= mem_dq;
	mem_dm_captured <= mem_dm;
	// for ddr3, we need to ignore the first dqs_n posedge since it's part of the preamble
	// so, we just overwrite captured data with 'z in that case
	// this is really only needed to properly handle certain calibration tests
	if (mem_dqs_n_shifted_2 === 'z || mem_dqs_n_shifted_2_prev === 'z)
	begin
		mem_dq_captured <= 'z;
		mem_dm_captured <= 'z;
	end
	mem_dqs_n_shifted_2_prev <= mem_dqs_n_shifted_2;
end

// DQ and DQS output
assign mem_dq = (mem_dq_en) ? mem_dq_int : 'z;
assign mem_dqs = 
	(mem_dqs_en) 
		?  (mem_dqs_preamble) 
			     ? '0 : {MEM_DQS_WIDTH{mem_ck_diff}} 
		              : 'z;
        
assign mem_dqs_n = 
	(mem_dqs_en) 
		?  (mem_dqs_preamble) 
			? '1 : {MEM_DQS_WIDTH{~mem_ck_diff}} 
		: 'z;

//synthesis translate_on

endmodule
