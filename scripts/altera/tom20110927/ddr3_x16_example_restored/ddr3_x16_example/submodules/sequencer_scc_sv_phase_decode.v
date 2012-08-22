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
module sequencer_scc_sv_phase_decode
    # (parameter
    
    AVL_DATA_WIDTH          =   32,
    DLL_DELAY_CHAIN_LENGTH  =   6
        
    )
    (
    
    avl_writedata,

	dqsi_phase,	
    dqs_phase_reset,
    dqs_phase,	
    dq_phase_reset,
    dq_phase,	
    dqse_phase_reset,
    dqse_phase
    
);

	input [AVL_DATA_WIDTH - 1:0] avl_writedata;
	
	output [2:0] dqsi_phase;	
	output [6:0] dqs_phase_reset;
	output [6:0] dqs_phase;	
	output [6:0] dq_phase_reset;
	output [6:0] dq_phase;	
	output [5:0] dqse_phase_reset;
	output [5:0] dqse_phase;
	
	//USER phase decoding.

	reg [2:0] dqsi_phase;
	
	reg [6:0] dqs_phase_reset;
	reg [6:0] dqs_phase;
	
	reg [6:0] dq_phase_reset;
	reg [6:0] dq_phase;
	
	reg [5:0] dqse_phase_reset;
	reg [5:0] dqse_phase;

	//USER decode phases
	
	always @ (*) begin
		dqsi_phase = 0;
		
		dqs_phase_reset = 0;
		//dqs_phase = 0;
		
		dq_phase_reset = 0;
		//dq_phase = 0;
		
		dqse_phase_reset = 0;
		dqse_phase = 0;
		
		//USER DQSin = 90, DQS = 180, DQ = 90, DQSE = 90
			
		dqsi_phase = 3'b010;
		dqse_phase = 6'b001000;

		//USER DQS = 315, DQ = 225, DQSE = 225
		dqs_phase  = 7'b1110110;
		dq_phase   = 7'b0110100;
		dqse_phase = 6'b000110;

		case (avl_writedata[4:0])
		5'b00000: //USER DQS = 180, DQ = 90, DQSE = 90
			begin
				dqs_phase  = 7'b0010100;
				dq_phase   = 7'b1000100;
				dqse_phase = 6'b000010;
			end
		5'b00001: //USER DQS = 225, DQ = 135, DQSE = 135
			begin
				dqs_phase  = 7'b0110100;
				dq_phase   = 7'b1100100;
				dqse_phase = 6'b000011;
			end
		5'b00010: //USER DQS = 270, DQ = 180, DQSE = 180
			begin
				dqs_phase  = 7'b1010100;
				dq_phase   = 7'b0010100;
				dqse_phase = 6'b000100;
			end
		5'b00011: //USER DQS = 315, DQ = 225, DQSE = 225
			begin
				dqs_phase  = 7'b1110110;
				dq_phase   = 7'b0110100;
				dqse_phase = 6'b000101;
			end
		5'b00100: //USER DQS = 360, DQ = 270, DQSE = 270
			begin
				dqs_phase  = 7'b0000110;
				dq_phase   = 7'b1010100;
				dqse_phase = 6'b000110;
			end
		5'b00101: //USER DQS = 405, DQ = 315, DQSE = 315
			begin
				dqs_phase  = 7'b0100110;
				dq_phase   = 7'b1110110;
				dqse_phase = 6'b000111;
			end
		5'b00110: //USER DQS = 450, DQ = 360, DQSE = 360
			begin
				dqs_phase  = 7'b1000110;
				dq_phase   = 7'b0000110;
				dqse_phase = 6'b000000;
			end
		5'b00111: //USER DQS = 495, DQ = 405, DQSE = 405
			begin
				dqs_phase  = 7'b1100110;
				dq_phase   = 7'b0100110;
				dqse_phase = 6'b000000;
			end
		5'b01000: //USER DQS = 540, DQ = 450
			begin
				dqs_phase  = 7'b0010110;
				dq_phase   = 7'b1000110;
			end
		5'b01001: //USER DQS = 585, DQ = 495
			begin
				dqs_phase  = 7'b0110110;
				dq_phase   = 7'b1100110;
			end
		5'b01010: //USER DQS = 630, DQ = 540
			begin
				dqs_phase  = 7'b1010110;
				dq_phase   = 7'b0010110;
			end
		5'b01011: //USER DQS = 675, DQ = 585
			begin
				dqs_phase  = 7'b1111000;
				dq_phase   = 7'b0110110;
			end
		5'b01100: //USER DQS = 720, DQ = 630
			begin
				dqs_phase  = 7'b0001000;
				dq_phase   = 7'b1010110;
			end
		5'b01101: //USER DQS = 765, DQ = 675
			begin
				dqs_phase  = 7'b0101000;
				dq_phase   = 7'b1111000;
			end
		5'b01110: //USER DQS = 810, DQ = 720
			begin
				dqs_phase  = 7'b1001000;
				dq_phase   = 7'b0001000;
			end


		5'b01111: //USER DQS = 855, DQ = 765
			begin
				dqs_phase  = 7'b1101000;
				dq_phase   = 7'b0101000;
			end
		5'b10000: //USER DQS = 900, DQ = 810
			begin
				dqs_phase  = 7'b0011000;
				dq_phase   = 7'b1001000;
			end
		5'b10001: //USER DQS = 945, DQ = 855
			begin
				dqs_phase  = 7'b0111000;
				dq_phase   = 7'b1101000;
			end
		5'b10010: //USER DQS = 990, DQ = 900
			begin
				dqs_phase  = 7'b1011000;
				dq_phase   = 7'b0011000;
			end
		5'b10011: //USER DQS = 1035, DQ = 945
			begin
				dqs_phase  = 7'b1111010;
				dq_phase   = 7'b0111000;
			end
		5'b10100: //USER DQS = 1080, DQ = 990
			begin
				dqs_phase  = 7'b0001010;
				dq_phase   = 7'b1011000;
			end
		5'b10101: //USER DQS = 1125, DQ = 1035
			begin
				dqs_phase  = 7'b0101010;
				dq_phase   = 7'b1111010;
			end
		5'b10110: //USER DQS = 1170, DQ = 1080
			begin
				dqs_phase  = 7'b1001010;
				dq_phase   = 7'b0001010;
			end
		5'b10111: //USER DQS = 1215, DQ = 1125
			begin
				dqs_phase  = 7'b1101010;
				dq_phase   = 7'b0101010;
			end
		5'b11000: //USER DQS = 1260, DQ = 1170
			begin
				dqs_phase  = 7'b0011010;
				dq_phase   = 7'b1001010;
			end
		5'b11001: //USER DQS = 1305, DQ = 1215
			begin
				dqs_phase  = 7'b0111010;
				dq_phase   = 7'b1101010;
			end
		5'b11010: //USER DQS = 1350, DQ = 1260
			begin
				dqs_phase  = 7'b1011010;
				dq_phase   = 7'b0011010;
			end
		5'b11011: //USER DQS = 1395, DQ = 1305
			begin
				dqs_phase  = 7'b1111010;
				dq_phase   = 7'b0111010;
			end
		default : begin end
		endcase
	end

endmodule
