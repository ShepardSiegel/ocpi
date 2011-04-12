//*****************************************************************************
// (c) Copyright 2008-2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MIG
//  /   /         Filename: tb_cmd_gen.v
// /___/   /\     Date Last Modified: $Date: 2010/12/13 23:13:50 $
// \   \  /  \    Date Created: Fri Sep 01 2006
//  \___\/\___\
//
//Device: STAN
//Design Name: PRBS_Generator
//Purpose:       This PRBS is using one to many feedback mechanism because it always
//               has a single level XOR(XNOR) for feedback. The TAP is chosen from the table
//               that listed in xapp052. The  TAPS position can be defined in parameter
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ps/1ps

module tg_prbs_gen #
  (
    parameter PRBS_WIDTH = 64,          //                                                                 // "SEQUENTIAL_BURST"
    parameter START_ADDR  = 32'h00000000,
    parameter DMODE = "READ",
    parameter PRBS_OFFSET = 0, 
    parameter [PRBS_WIDTH-1:0] TAPS= 32'h80200003 //32'b10000000_00100000_00000000_00000011// [31,21,1,0]
   // 16 taps: [15,14,12,3] : 16'b11010000_00001000 
   // 64 taps: [63,62,60,59]: {{8'b11011000}, {56'b0}}
    
   )
  (
   input           clk_i,
   input           clk_en,
   input           rst,
//   input           prbs_seed_init,  // when high the prbs_x_seed will be loaded
   input [PRBS_WIDTH-1:0]    prbs_seed_i,
   output                    initialize_done,
   output  [PRBS_WIDTH-1:0]  prbs_o,     // generated address
   output reg [3:0] prbs_shift_value,
   output [31:0] ReSeedcounter_o
  );
  
  
wire  prbs_seed_ld;
reg [PRBS_WIDTH - 1:0] Next_LFSR_Reg;
reg [PRBS_WIDTH - 1:0] LFSR_Reg;
reg [PRBS_WIDTH-1:0] counterA;
reg Bits0_9_zero, Feedback;
integer i;
reg [PRBS_WIDTH - 1:0] ReSeedcounter;
reg [10:0] freerun_counters;
reg init_setup;
wire prbs_clk_en1;
wire prbs_clk_en2;
always @ (posedge clk_i)
begin
   if (rst)
     freerun_counters <= 'b0;
   else if (freerun_counters <= 128 || init_setup)
     freerun_counters <= freerun_counters + 1'b1;
end


always @ (posedge clk_i)
begin
   if (rst)
     counterA <= 'b0;
//   else if (clk_en || init_setup || )
   else if (prbs_clk_en1)

     counterA <= counterA + 1'b1;
end




assign initialize_done = ~init_setup;
always @ (posedge clk_i)
begin
   if (rst)
     init_setup <= 'b0;
   else if ( freerun_counters <= PRBS_OFFSET + 255 )
     init_setup <= 1'b1;
   else
     init_setup <= 1'b0;
    
end

/*always @ (posedge clk_i)
begin
   if (rst)
      prbs_shift_value <= 'b0;
   else if (freerun_counters == PRBS_OFFSET + 4 )
      prbs_shift_value <= LFSR_Reg[3:0];
end      
*/

assign ReSeedcounter_o = {{(32-PRBS_WIDTH){1'b0}},ReSeedcounter};
always @ (posedge clk_i)
begin
   if (rst)
     ReSeedcounter <= 'b0;
   else if (prbs_clk_en1)
     if (ReSeedcounter == {PRBS_WIDTH {1'b1}})
         ReSeedcounter <= 'b0;
     else
         ReSeedcounter <= ReSeedcounter + 1'b1;
end


assign prbs_clk_en1 = clk_en || init_setup ;
assign prbs_clk_en2 = clk_en || init_setup ;

always @ (posedge clk_i)
begin
   if (rst  )
        // add a fixed non zero value to prevent to load a zero value to the LFSR.
        LFSR_Reg <=  prbs_seed_i +8'h55;
   else if (prbs_clk_en2) begin
     //   if ( PRBS_OFFSET == 0)
     //      $display("prbs_value = 0x%h",LFSR_Reg);
        LFSR_Reg <= Next_LFSR_Reg;
        prbs_shift_value <= {prbs_shift_value[2:0],LFSR_Reg[PRBS_WIDTH-1]};
        end
end

   

always @ (LFSR_Reg)
begin :LFSR_Feedback
   Bits0_9_zero = ~| LFSR_Reg[PRBS_WIDTH-2:0];
   Feedback = LFSR_Reg[PRBS_WIDTH-1]^Bits0_9_zero; 
//   Feedback = LFSR_Reg[PRBS_WIDTH-1] ; 

//   for (i = 1; i <= PRBS_WIDTH - 1; i = i+1)
   for (i = PRBS_WIDTH - 1; i >= 1 ; i = i-1)

      if (TAPS[i - 1] == 1)
         Next_LFSR_Reg[i]= LFSR_Reg[i-1] ^ Feedback  ;
      else
         Next_LFSR_Reg[i] = LFSR_Reg[i-1];
         
   Next_LFSR_Reg[0] = Feedback  ;//LFSR_Reg[PRBS_WIDTH-1];// always use the last stage for feedback
end
assign prbs_o = LFSR_Reg;



endmodule
   
         
