//*****************************************************************************
// (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
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
//  \   \         Application: STAN_MEMC
//  /   /         Filename: pipeline_inserter.v
// /___/   /\     Date Last Modified: $Date: 
// \   \  /  \    Date Created: 
//  \___\/\___\
//
//Device: Spartan6
//Design Name: DDR/DDR2/DDR3/LPDDR 
//Purpose: Insert pipelines
//Reference:
//Revision History:
//*****************************************************************************

`timescale 1ps/1ps
module pipeline_inserter(data_i, data_o, clk_i, en_i);
   parameter DATA_WIDTH = 32;
   parameter PIPE_STAGES = 1;   
   
   input [DATA_WIDTH-1:0] data_i; 
   output [DATA_WIDTH-1:0] data_o; 
   input                   clk_i; 
   input                   en_i;
   
   genvar                  i;
   integer                  j;

   reg [DATA_WIDTH - 1:0]  pipe_array [PIPE_STAGES+1:0];
   

 

   //**********************************************************
   //*
   //* No Pipeline
   //* 
   //***********************************************************/ 
   generate
   if(PIPE_STAGES == 0) begin: no_pipe
      assign               data_o = data_i;
   end
   endgenerate


   //**********************************************************
   //*
   //* Add Pipeline
   //* 
   //***********************************************************/ 
   generate
   if(PIPE_STAGES > 0) begin: add_pipe 
   
  initial begin
   for(j = 0; j < PIPE_STAGES; j = j + 1) 
            pipe_array[j] <= 'b0;

  end
      assign               data_o = pipe_array[PIPE_STAGES-1];
      
      always @ (posedge clk_i) begin
         if(en_i) begin
            pipe_array[0] <= data_i;     
         end
      end
   
   for(i = 1; i < PIPE_STAGES; i = i + 1) begin : pipe
      always @ (posedge clk_i) begin
         if(en_i) begin
            pipe_array[i] <= pipe_array[i-1];
         end
      end   
   end 
   end
   
   endgenerate
   
endmodule // pipeline_inserter
