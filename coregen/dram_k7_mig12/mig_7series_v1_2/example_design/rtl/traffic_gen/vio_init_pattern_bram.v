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
// /___/   /\     Date Last Modified: $Date: 2011/05/27 14:31:13 $
// \   \  /  \    Date Created: Fri Sep 01 2006
//  \___\/\___\
//
//Device: STAN
//Design Name: cmd_gen
//Purpose:
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ps/1ps
`ifndef TCQ
 `define TCQ 100
`endif
module vio_init_pattern_bram #
  ( 
    parameter TCQ        = 100,
    parameter START_ADDR = 32'h00000000,
    parameter MEM_BURST_LEN = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16,

    parameter NUM_DQ_PINS = 8,
    parameter SEL_VICTIM_LINE = NUM_DQ_PINS // possible value : 0 to NUM_DQ_PINS
    
  )
  (
   input                        clk_i,
   input                        rst_i,   
   input                        cmd_start,
   input  [31:0]                 cmd_addr,     //
   input                        mode_load_i,  // signal to initialze internal bram
                                              // with input data1 through data9.
   input  [3:0]                 data_mode_i,  // selection of data pattern.                                            
   input  [31:0]     data0,    // data1 through data8 are
   input  [31:0]     data1,    // used as simple traffic data
   input  [31:0]     data2,    // pattern that repeats continuously
   input  [31:0]     data3,
   input  [31:0]     data4,
   input  [31:0]     data5,
   input  [31:0]     data6,
   input  [31:0]     data7,
   input  [31:0]     data8,    // used a fixed input data
  
   output reg                   bram_rd_valid_o,
   input                        bram_rd_rdy_i,
   output  [31:0] dout_o
  );
   



function integer logb2;
  input [31:0] number;
  integer i;
  begin
    i = number;
      for(logb2=1; i>0; logb2=logb2+1)
        i = i >> 1;
  end
endfunction


reg  [ADDR_WIDTH - 1:0]    wr_addr;
reg  [ADDR_WIDTH - 1:0]    rd_addr;
reg                        init_write;
reg                        mode_load_r1;
reg                        mode_load_r2;
reg [31:0]                 data_in0;
reg [31:0]                 data_in1;
reg [31:0]                 data_in2;
reg [31:0]                 data_in3;
reg [31:0]                 data_in4;
reg [31:0]                 data_in5;
reg [31:0]                 data_in6;
reg [31:0]                 data_in7;
reg [31:0]                 data_in8;
reg [31:0]                 data_in9;
reg [31:0]                 data_in10;
reg [31:0]                 data_in11;
reg [31:0]                 data_in12;
reg [31:0]                 data_in13;
reg [31:0]                 data_in14;
reg [31:0]                 data_in15;




reg [31:0]                 hdata;
reg    [31:0]  mem[0:DEPTH - 1]; 
reg    [31:0]  data_in; 
reg                         wr_en;
reg    cmd_addr_r9;
integer i,j,k;

always @ (posedge clk_i)
begin
   mode_load_r1 <= mode_load_i;
   mode_load_r2 <= mode_load_r1;
end   


always @ (posedge clk_i)
begin
if (rst_i)
    init_write <= 'b0;
else if (wr_addr == {4'b0111})    
    init_write <= 'b1;
else if (mode_load_r1 && ~mode_load_r2 && data_mode_i != 4'b0010)
    init_write <= 'b1;
end

// generate a mutil_cycle control siganl to improve timing.
always @ (posedge clk_i)
if (rst_i)
    wr_en   <= 1'b1;
else if (init_write && data_mode_i != 4'b0010)
    wr_en   <= 1'b1;


always @ (posedge clk_i)
begin
if (rst_i)
    wr_addr <= 'b0;
else if (  data_mode_i == 4'b0011)  
         wr_addr <= 4'b1001;
else if ( ~init_write && data_mode_i == 4'b0100)  
         wr_addr <= 4'b0000;

else if (init_write && wr_en && data_mode_i != 4'b0010)
   if (wr_addr != 7)
      wr_addr <= wr_addr + 1'b1;

//else if (bram_rd_rdy_i)
//         wr_addr <= rd_addr + 1;

/*else if (rd_addr >= 7)  
       if (rd_addr == 7)
         wr_addr <= 0;
       else
         wr_addr <= wr_addr + 1;
       
else if (rd_addr < 7 || rd_addr == 15)  
    if (rd_addr == 15)
      wr_addr <= 8;   
    else
      wr_addr <= wr_addr + 1;   
    
*/


end

// HAMMER_PATTERN_MINUS: generate walking HAMMER  data pattern except 1 bit for the whole burst. The incoming addr_i[5:2] determine 
// the position of the pin driving oppsite polarity
//  addr_i[6:2] = 5'h0f ; 32 bit data port
//                 => the rsing data pattern will be    32'b11111111_11111111_01111111_11111111
//                 => the falling data pattern will be  32'b00000000_00000000_00000000_00000000

// Only generate NUM_DQ_PINS width of hdata and will do concatenation in above level.
always @ (posedge clk_i) begin
//for (j=0; j <= 1; j= j+1) //  
  for (i= 0; i <= 31; i= i+1) //begin: hammer_data
      if ( i >= NUM_DQ_PINS )
        if (SEL_VICTIM_LINE == NUM_DQ_PINS)
             hdata[i] <= 1'b0;
        else if (
             ((i == SEL_VICTIM_LINE-1) || (i-NUM_DQ_PINS) == SEL_VICTIM_LINE ||
              (i-(NUM_DQ_PINS*2)) == SEL_VICTIM_LINE || 
              (i-(NUM_DQ_PINS*3)) == SEL_VICTIM_LINE)) 
             
              hdata[i] <= 1'b1;
         else
              hdata[i] <= 1'b0;
         
      else 
        
              hdata[i] <= 1'b1;


end






    
/*
parameter mif_file = "stimulus.mif";  
initial
begin
    $readmemb(mif_file,mem, 0, DATA_WIDTH);
end
*/


initial begin
// content formats
//        {burst length, instruction, address}
mem[0]  = {26'h0000000,6'h00};
mem[1]  = {26'h0000000,6'h04};
mem[2]  = {26'h0000000,6'h08};
mem[3]  = {26'h0000000,6'h0c};
mem[4]  = {26'h0000000,6'h10};
mem[5]  = {26'h0000000,6'h14};
mem[6]  = {26'h0000000,6'h18};
mem[7]  = {26'h0000000,6'h1c};
mem[8]  = {26'h0000000,6'h20};
mem[9]  = {26'h0000000,6'h24};
mem[10] = #TCQ 32'hffffffff;
mem[11] = #TCQ 32'h00000000;
mem[12] = {26'h0000000,6'h30};
mem[13] = {26'h0000000,6'h34};
mem[14] = {26'h0000000,6'h38};
mem[15] = {26'h0000000,6'h3c};
end




always @ (posedge clk_i)
       mem[wr_addr] <= data_in;


always @ (data_mode_i, data0,data1,data2,data3,data4,data5,data6,data7,data8,hdata)
//always @ (posedge clk_i)

begin

      data_in0[31:0]  = #TCQ data0;
      data_in1[31:0]  = #TCQ data1;
      data_in2[31:0]  = #TCQ data2;
      data_in3[31:0]  = #TCQ data3;
      data_in4[31:0]  = #TCQ data4;
      data_in5[31:0]  = #TCQ data5;
      data_in6[31:0]  = #TCQ data6;
      data_in7[31:0]  = #TCQ data7;
      data_in8[31:0]  = #TCQ data8;  
      data_in9[31:0]  = #TCQ hdata;
      data_in10[31:0] =  #TCQ 32'hffffffff;
      data_in11[31:0] =  #TCQ 32'h00000000;
      data_in12[31:0] =  #TCQ 'b0;
      data_in13[31:0] =  #TCQ 'b0;
      data_in14[31:0] =  #TCQ 'b0;
      data_in15[31:0] =  #TCQ 'b0;
     
    
    
end   


always @ (posedge clk_i)
begin
  if (cmd_start)
    cmd_addr_r9 <= cmd_addr[9];
end

always @ (posedge clk_i)
begin
if (rst_i)
      data_in <= #TCQ data0;
else
  // address is one cycle earlier.
  case(wr_addr)
      0: if (init_write)
              data_in <= #TCQ data_in1;
         else
              data_in <= #TCQ data_in0;
         
      1: data_in <= #TCQ data_in2;
      2: data_in <= #TCQ data_in3;
      3: data_in <= #TCQ data_in4;
      4: data_in <= #TCQ data_in5;
      5: data_in <= #TCQ data_in6;
      6: data_in <= #TCQ data_in7;
      7: data_in <= #TCQ data_in7;
      8: data_in <= #TCQ data_in8;          
      9: data_in <= #TCQ data_in9;
     10: data_in <= #TCQ data_in10;
     11: data_in <= #TCQ data_in11;
     12: data_in <= #TCQ data_in12;
     13: data_in <= #TCQ data_in13;
     14: data_in <= #TCQ data_in14;
     15: data_in <= #TCQ data_in15;
      
      default: data_in <= data8;
  endcase
end

  

always @ (posedge clk_i)
 if (rst_i)
    bram_rd_valid_o <= 1'b0;
 else if (wr_addr[3:0] == {ADDR_WIDTH - 1{1'b1}} || data_mode_i == 2  || data_mode_i == 3)
    bram_rd_valid_o <= 1'b1;

// rd_address generation depending on data pattern mode.   


always @ (posedge clk_i)
begin
if (rst_i)
  if (data_mode_i == 9) begin
      rd_addr[3:1] <= #TCQ 3'b101;
      rd_addr[0] <= #TCQ cmd_addr[9];
     end
  else if (data_mode_i == 3)      // address as data pattern
   rd_addr <= #TCQ 9;
  else
   rd_addr <= #TCQ 0;

else if (cmd_start) 
        begin
        if (data_mode_i == 1 || data_mode_i == 3)
           rd_addr[3:0] <= #TCQ 9;  
        else if (data_mode_i == 9) begin
           rd_addr[3:1] <= #TCQ 3'b101;
           rd_addr[0] <= #TCQ cmd_addr[9];
           end    
        else
           rd_addr[3:0] <= #TCQ 0;  
        
        end
   
else  if (bram_rd_rdy_i)
/*  if (data_mode_i == 2)      // address as data pattern
      rd_addr <= #TCQ 0;
  else if (data_mode_i == 4) // simple_data_pattern
     if (rd_addr == 7)
        rd_addr <= #TCQ 0;
     else
        rd_addr <= #TCQ rd_addr+ 1'b1;
  else if (data_mode_i == 1) // fixed input pattern
      rd_addr <= #TCQ 8;
  else if (data_mode_i == 3) // hammer pattern
      rd_addr <= #TCQ 9;
  else if (data_mode_i == 9)  // slow 2 MHz pattern
      begin
      rd_addr[3:1] <= #TCQ 3'b101;
      rd_addr[0] <= #TCQ cmd_addr_r9;
      end
   */   
      
  case (data_mode_i)    
      4'h2:  rd_addr <= #TCQ 0;
      4'h4: if (rd_addr == 7)
                rd_addr <= #TCQ 0;
            else
                rd_addr <= #TCQ rd_addr+ 1'b1;
      4'h1:  rd_addr <= #TCQ 8;
      4'h3:  rd_addr <= #TCQ 9;
      4'h9: begin
              rd_addr[3:1] <= #TCQ 3'b101;
              rd_addr[0] <= #TCQ cmd_addr_r9;
            end
      default: rd_addr <= #TCQ 0;
      
  endcase  
end


// need to  infer distributed RAM to meet output timing
// in upper level
assign  dout_o  =  mem[rd_addr];   //



endmodule
