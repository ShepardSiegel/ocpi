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


// altera message_off 10230
module sequencer_scc_sv_wrapper
    # (parameter
    
    DATAWIDTH               =   24,
    IO_SDATA_BITS           =   11,
    DQS_SDATA_BITS          =   46,
    AVL_DATA_WIDTH          =   32,
    DLL_DELAY_CHAIN_LENGTH  =   6
        
    )
    (
	
	reset_n_scc_clk,	
	scc_clk,
	scc_dataout,
	scc_io_cfg,
	scc_dqs_cfg
);

	input scc_clk;
	input reset_n_scc_clk;
	input [DATAWIDTH-1:0] scc_dataout;
	output    [IO_SDATA_BITS - 1:0] scc_io_cfg;
	output    [DQS_SDATA_BITS - 1:0] scc_dqs_cfg;
	
	typedef enum integer {
		SCC_ADDR_DQS_IN_DELAY	= 'b0001,
		SCC_ADDR_DQS_EN_PHASE	= 'b0010,
		SCC_ADDR_DQS_EN_DELAY	= 'b0011,
		SCC_ADDR_DQDQS_OUT_PHASE= 'b0100,
		SCC_ADDR_OCT_OUT1_DELAY	= 'b0101,
		SCC_ADDR_OCT_OUT2_DELAY	= 'b0110,
		SCC_ADDR_IO_OUT1_DELAY	= 'b0111,
		SCC_ADDR_IO_OUT2_DELAY	= 'b1000,
		SCC_ADDR_IO_IN_DELAY	= 'b1001
	} sdata_addr_t;
	
	wire    [DATAWIDTH-1:0] scc_dataout;
	reg     [IO_SDATA_BITS - 1:0] scc_io_cfg;
	reg     [DQS_SDATA_BITS - 1:0] scc_dqs_cfg;
	
	wire    [2:0] dqsi_phase;
	wire    [5:0] dqse_phase_reset;
	wire    [5:0] dqse_phase;
	wire    [6:0] dqs_phase_reset;
	wire    [6:0] dqs_phase;
	wire    [6:0] dq_phase_reset;
	wire    [6:0] dq_phase;
	
	typedef bit [13:0] t_setting_mask;
	
        integer unsigned setting_offsets[1:9] = '{ 'd0, 'd12, 'd17, 'd25, 'd30, 'd36, 'd0, 'd6, 'd12 };
        t_setting_mask setting_masks [1:9] = '{ 'b0111111111111, 'b011111, 'b011111111, 'b011111, 'b0111111, 'b0111111, 'b0111111, 'b0111111, 'b0111111111111 };
	
	//USER decode phases
	
	sequencer_scc_sv_phase_decode  # (
        .AVL_DATA_WIDTH         (AVL_DATA_WIDTH         ),
        .DLL_DELAY_CHAIN_LENGTH (DLL_DELAY_CHAIN_LENGTH )
    ) sequencer_scc_phase_decode_dqe_inst (
        .avl_writedata          ((scc_dataout >> setting_offsets[SCC_ADDR_DQS_EN_PHASE]) & setting_masks[SCC_ADDR_DQS_EN_PHASE]),
        .dqsi_phase	            (dqsi_phase	            ),
        .dqse_phase_reset       (dqse_phase_reset       ),
        .dqse_phase             (dqse_phase             )
    );
	
	sequencer_scc_sv_phase_decode  # (
        .AVL_DATA_WIDTH         (AVL_DATA_WIDTH         ),
        .DLL_DELAY_CHAIN_LENGTH (DLL_DELAY_CHAIN_LENGTH )
    ) sequencer_scc_phase_decode_dqdqs_inst (
        .avl_writedata          ((scc_dataout >> setting_offsets[SCC_ADDR_DQDQS_OUT_PHASE]) & setting_masks[SCC_ADDR_DQDQS_OUT_PHASE]),
        .dqs_phase_reset        (dqs_phase_reset        ),
        .dqs_phase              (dqs_phase              ),
        .dq_phase_reset         (dq_phase_reset         ),
        .dq_phase               (dq_phase               )
    );
	
	always_ff @ (posedge scc_clk or negedge reset_n_scc_clk) begin
		if (~reset_n_scc_clk) begin
			scc_io_cfg <= '0;
			scc_dqs_cfg <= '0;
			
			scc_dqs_cfg[6:4] <= dqsi_phase;

			scc_dqs_cfg[29:28] <= dqs_phase_reset[6:5]; //dqsoutputphasesetting +
			scc_dqs_cfg[31] <= dqs_phase_reset[4]; //dqsoutputphaseinvert +
			scc_dqs_cfg[69] <= dqs_phase_reset[0]; //enaoctphasetransferreg + 
			scc_dqs_cfg[89] <= dqs_phase_reset[0]; //enadqsphasetransferreg + 

			scc_dqs_cfg[68:66] <= dqs_phase_reset[3:1];   //enaoctcycledelaysetting +
			scc_dqs_cfg[93:91] <= dqs_phase_reset[3:1];   //enaoctcycledelaysetting +


			scc_dqs_cfg[33:32] <= dq_phase_reset[6:5]; //dqoutputphasesetting +
			scc_dqs_cfg[36] <= dq_phase_reset[4]; // dqoutputphaseinvert +
			scc_dqs_cfg[90] <= dq_phase_reset[0]; // enaoutputphasetransferreg +
			scc_dqs_cfg[96:94] <= dq_phase_reset[3:1]; // enaoutputcycledelaysetting +

			scc_dqs_cfg[51:50] <= dq_phase_reset[6:5]; //dqoutputphasesetting +
			scc_dqs_cfg[54] <= 1'b0; //never invert the 2x clock

			scc_dqs_cfg[47:46] <= dqs_phase_reset[6:5]; //dqoutputphasesetting +
			scc_dqs_cfg[49] <= 1'b0; //never invert the 2x clock
	
			scc_dqs_cfg[10:7] <= dqse_phase_reset[5:2];
			scc_dqs_cfg[43] <= dqse_phase_reset[1];
			scc_dqs_cfg[38] <= dqse_phase_reset[0];
		end
		else begin
			scc_dqs_cfg[27:24] <= '0;
			scc_dqs_cfg[30] <= '0;  // powerdown option	
			scc_dqs_cfg[35:34] <= '0;  // powerdown and not mapped
			scc_dqs_cfg[48] <= '0; //powerdown
			scc_dqs_cfg[53:52] <= '0; //powerdown


			scc_dqs_cfg[40:37] <= '0;
			scc_dqs_cfg[65:46] <= '0;
			scc_dqs_cfg[93:91] <= '0;
			scc_dqs_cfg[100:97] <= '0;
			
	
			scc_dqs_cfg[88:87] <= dqsi_phase; // dqsinputphasesetting done
			
			scc_dqs_cfg[11:0] <= (scc_dataout >> setting_offsets[SCC_ADDR_DQS_IN_DELAY]) & ({'0, setting_masks[SCC_ADDR_DQS_IN_DELAY]}); //done
			scc_dqs_cfg[85:78] <= (scc_dataout >> setting_offsets[SCC_ADDR_DQS_EN_DELAY]) & ({'0, setting_masks[SCC_ADDR_DQS_EN_DELAY]}); //dqsenable
			scc_dqs_cfg[77:70] <= (scc_dataout >> setting_offsets[SCC_ADDR_DQS_EN_DELAY]) & ({'0, setting_masks[SCC_ADDR_DQS_EN_DELAY]}); //dqsdisable (same as enable for now)
			scc_dqs_cfg[17:12] <= (scc_dataout >> setting_offsets[SCC_ADDR_OCT_OUT1_DELAY]) & ({'0, setting_masks[SCC_ADDR_OCT_OUT1_DELAY]}); //done
			scc_dqs_cfg[23:18] <= (scc_dataout >> setting_offsets[SCC_ADDR_OCT_OUT2_DELAY]) & ({'0, setting_masks[SCC_ADDR_OCT_OUT2_DELAY]}); //done
		

			scc_dqs_cfg[42:41] <= dqse_phase[1:0]; //dqsenablectrlphasesetting done

			scc_dqs_cfg[45] <= dqse_phase[2]; //dqsenablectrlphaseinvert done
			scc_dqs_cfg[86] <= dqse_phase[3]; //enadqsenablephasetransferreg done

			scc_dqs_cfg[29:28] <= dqs_phase[6:5]; //dqsoutputphasesetting +
			scc_dqs_cfg[31] <= dqs_phase[4]; //dqsoutputphaseinvert +
			scc_dqs_cfg[69] <= dqs_phase[0]; //enaoctphasetransferreg + 
			scc_dqs_cfg[89] <= dqs_phase[0]; //enadqsphasetransferreg + 

			scc_dqs_cfg[68:66] <= dqs_phase[3:1];   //enaoctcycledelaysetting +
			scc_dqs_cfg[93:91] <= dqs_phase[3:1];   //enaoctcycledelaysetting +


			scc_dqs_cfg[33:32] <= dq_phase[6:5]; //dqoutputphasesetting +
			scc_dqs_cfg[36] <= dq_phase[4]; // dqoutputphaseinvert +
			scc_dqs_cfg[90] <= dq_phase[0]; // enaoutputphasetransferreg +
			scc_dqs_cfg[96:94] <= dq_phase[3:1]; // enaoutputcycledelaysetting +

			scc_dqs_cfg[51:50] <= dq_phase[6:5]; // + 1; //dqoutputphasesetting +
			scc_dqs_cfg[54] <= 1'b0; 

			scc_dqs_cfg[47:46] <= dqs_phase[6:5]; // + 1; //dqoutputphasesetting +
			scc_dqs_cfg[49] <= 1'b0;

			scc_dqs_cfg[86] <= 1'b1;   //enable phase transfer reg on postamble			

			scc_io_cfg[17:12] <= (scc_dataout >> setting_offsets[SCC_ADDR_IO_OUT1_DELAY]) & ({'0, setting_masks[SCC_ADDR_IO_OUT1_DELAY]}); //done
			scc_io_cfg[23:18] <= (scc_dataout >> setting_offsets[SCC_ADDR_IO_OUT2_DELAY]) & ({'0, setting_masks[SCC_ADDR_IO_OUT2_DELAY]}); //done
			scc_io_cfg[11:0] <= (scc_dataout >> setting_offsets[SCC_ADDR_IO_IN_DELAY]) & ({'0, setting_masks[SCC_ADDR_IO_IN_DELAY]}); //done
			scc_io_cfg[39:24] <= '0; //done
		end
	end
	
endmodule
