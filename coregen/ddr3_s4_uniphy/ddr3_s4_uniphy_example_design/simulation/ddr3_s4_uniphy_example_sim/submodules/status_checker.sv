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


module status_checker (clk, reset_n, test_complete, fail, pass, local_init_done, local_cal_success, local_cal_fail);

parameter AVL_DATA_WIDTH = 2;
parameter ENABLE_VCDPLUS = 0;

input clk;
input reset_n;

input test_complete;
input fail;
input pass;

input local_init_done;
input local_cal_success;
input local_cal_fail;


reg				afi_cal_success_reported;

//synthesis translate_off

initial begin
	if (ENABLE_VCDPLUS ==1)
		$vcdpluson;
	afi_cal_success_reported <= 0;
end


always @(posedge test_complete)
begin
	@(posedge clk);
	if (pass)
	begin
		$display("          --- SIMULATION PASSED --- ");
		$finish;
	end
	else
	begin
		$display("          --- SIMULATION FAILED --- ");
		$finish;
	end
end

always @(posedge clk) begin
	if (local_cal_fail)
		begin
			$display("          --- CALIBRATION FAILED --- ");
			$display("          --- SIMULATION FAILED --- ");
			$finish;
		end
	if (local_cal_success)
		if (!afi_cal_success_reported) begin
			afi_cal_success_reported <= 1'b1;
			$display("          --- CALIBRATION PASSED --- ");
		end
	end
		

//synthesis translate_on

endmodule