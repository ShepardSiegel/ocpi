//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
//  /   /         Filename: prbs_gen.v
// /___/   /\     Date Last Modified: $Date: 2010/11/09 17:40:54 $
// \   \  /  \    Date Created: 05/12/10
//  \___\/\___\
//
//Device: 7 Series
//Design Name: DDR3 SDRAM
//Purpose:       This PRBS module uses many to one feedback mechanism for 2^n 
//               sequence generation because the levels of logic are the same
//               compared to one to many feedback mechanism for 2^n sequence
//               generation. The advantage with many to one is that all 8 bits
//               can be accessed for staggered output generation. The feedback
//               TAP is chosen from the table that is listed in xapp052. 
//
//Reference:
//Revision History:
// 
//*****************************************************************************

/******************************************************************************
**$Id: prbs_gen.v,v 1.1 2010/11/09 17:40:54 mishra Exp $
**$Date: 2010/11/09 17:40:54 $
**$Author: mishra $
**$Revision: 1.1 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_1/data/dlib/7series/ddr3_sdram/verilog/rtl/phy/prbs_gen.v,v $
******************************************************************************/


`timescale 1ps/1ps

module prbs_gen #
  (
    parameter PRBS_WIDTH  = 4
   )
  (
   input           clk,
   input           clk_en,
   input           rst,
   output  [PRBS_WIDTH-1:0]  prbs_o
//   output reg [3:0] prbs_shift_value
  );


localparam  PRBS_OFFSET = 0;  
  
reg [PRBS_WIDTH - 1:0] Next_LFSR_Reg;
reg [PRBS_WIDTH - 1:0] LFSR_Reg;
reg [3:0]              prbs_shift_value;
reg Bits_all, Feedback;
integer i;



always @ (posedge clk)
begin
   if (rst )
        LFSR_Reg <=  {{PRBS_WIDTH-1{1'b0}},1'b1};
   else if (clk_en) begin
        if ( PRBS_OFFSET == 0)
         // $display("prbs_value = 0x%h",LFSR_Reg);
        LFSR_Reg <= Next_LFSR_Reg;
        prbs_shift_value <= {prbs_shift_value[2:0],LFSR_Reg[PRBS_WIDTH-1]};
        end
end

always @ (LFSR_Reg)
begin :LFSR_Next
   Bits_all = ~| LFSR_Reg[PRBS_WIDTH-2:0];
   Feedback = LFSR_Reg[PRBS_WIDTH-1]^Bits_all; 
   for (i = PRBS_WIDTH - 1; i >= 1 ; i = i-1)
      Next_LFSR_Reg[i] = LFSR_Reg[i-1];
        
   // Many to one feedback taps for 2^n sequence
   // 4 logic levels required for PRBS_WIDTH = 64
   case (PRBS_WIDTH)
   32'd4:      
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[2];
   32'd8:      
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[3]^LFSR_Reg[4]^LFSR_Reg[5];
   32'd10:      
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[6];
   32'd14:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[0]^LFSR_Reg[2]^LFSR_Reg[4];
   32'd24:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[16]^LFSR_Reg[21]^LFSR_Reg[22];
   32'd32:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[0]^LFSR_Reg[1]^LFSR_Reg[21];
   32'd42:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[18]^LFSR_Reg[19]^LFSR_Reg[40];
   32'd56:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[33]^LFSR_Reg[34]^LFSR_Reg[54];
   32'd64:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[59]^LFSR_Reg[60]^LFSR_Reg[62];
   32'd72:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[18]^LFSR_Reg[24]^LFSR_Reg[65];
   default:
      Next_LFSR_Reg[0] = Feedback^LFSR_Reg[59]^LFSR_Reg[60]^LFSR_Reg[62];
   endcase
end

assign prbs_o = LFSR_Reg;



endmodule
   
         
