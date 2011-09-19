

`timescale 1ps/1ps

module ddr3_s4_uniphy_example_sim_tb();

reg clk;
reg reset_n;

ddr3_s4_uniphy_example_sim dut (

		.oct_rdn(),
		.oct_rup(),

        .pll_ref_clk(clk),
        .global_reset_n(reset_n),
        .soft_reset_n(1'b1)
);


always #(10000/2) clk <= ~clk;

initial
begin
        clk <= 1'b0;
        reset_n <= 0;
        #(50000) reset_n <= 1;
end



endmodule

