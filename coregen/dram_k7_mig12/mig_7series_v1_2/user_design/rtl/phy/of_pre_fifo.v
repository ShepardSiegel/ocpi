//*****************************************************************************
// (c) Copyright 2008 - 2011 Xilinx, Inc. All rights reserved.
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
// /___/  \  /    Vendor                : Xilinx
// \   \   \/     Version               : %version
//  \   \         Application           : MIG
//  /   /         Filename              : of_pre_fifo.v
// /___/   /\     Date Last Modified    : $date$
// \   \  /  \    Date Created          : Feb 08 2011
//  \___\/\___\
//
//Device            : 7 Series
//Design Name       : DDR3 SDRAM
//Purpose           : Extends the depth of a PHASER OUT_FIFO up to 4 entries
//Reference         :
//Revision History  :
//*****************************************************************************

/******************************************************************************
**$Id: of_pre_fifo.v,v 1.4.14.2 2011/05/27 14:31:03 venkatp Exp $
**$Date: 2011/05/27 14:31:03 $
**$Author: venkatp $
**$Revision: 1.4.14.2 $
**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_7series_v1_2/data/dlib/7series/ddr3_sdram/verilog/rtl/phy/of_pre_fifo.v,v $
******************************************************************************/

`timescale 1 ps / 1 ps

module of_pre_fifo #
  (
   parameter TCQ   = 100,             // clk->out delay (sim only)
   parameter DEPTH = 4,               // # of entries
   parameter WIDTH = 32               // data bus width
   )
  (
   input              clk,            // clock
   input              rst,            // synchronous reset
   input              full_in,        // FULL flag from OUT_FIFO
   input              wr_en_in,       // write enable from controller
   input [WIDTH-1:0]  d_in,           // write data from controller
   output             wr_en_out,      // write enable to OUT_FIFO
   output [WIDTH-1:0] d_out           // write data to OUT_FIFO
   );
  
  // # of bits used to represent read/write pointers
  localparam PTR_BITS 
             = (DEPTH == 2) ? 1 : 
               ((DEPTH == 3) || (DEPTH == 4)) ? 2 : 
               (((DEPTH == 5) || (DEPTH == 6) || 
                 (DEPTH == 7) || (DEPTH == 8)) ? 3 : 'bx);

  integer i;
  
  reg [WIDTH-1:0]    mem[0:DEPTH-1];
  reg                my_empty;
  reg                my_full;
  reg [PTR_BITS-1:0] rd_ptr;
  // synthesis attribute MAX_FANOUT of rd_ptr is 10; 
  reg [PTR_BITS-1:0] wr_ptr;
  // synthesis attribute MAX_FANOUT of wr_ptr is 10; 
  wire [PTR_BITS-1:0] nxt_rd_ptr;
  wire [PTR_BITS-1:0] nxt_wr_ptr;
  wire [WIDTH-1:0] mem_out;
  wire wr_en;

        // synthesis translate_off
  task updt_ptrs;
    input rd;
    input wr;
    reg [2:0] next_rd_ptr;
    reg [2:0] next_wr_ptr;
    begin
//      next_rd_ptr = next_ptr(rd_ptr, DEPTH-1);
//      next_wr_ptr = next_ptr(wr_ptr, DEPTH-1);
      casez ({rd, wr, my_empty, my_full})
        4'b0100: begin
//          wr_ptr <= #TCQ next_wr_ptr;
//          my_full <= #TCQ (next_wr_ptr == rd_ptr);
        end
        4'b0110: begin
//          wr_ptr <= #TCQ next_wr_ptr;
//          my_empty <= #TCQ 1'b0;
        end     
        4'b1000: begin
//          rd_ptr <= #TCQ next_rd_ptr;
//          my_empty <= #TCQ (next_rd_ptr == wr_ptr);
        end
        4'b1001: begin
//          rd_ptr <= #TCQ next_rd_ptr;
//          my_full <= #TCQ 1'b0;
        end
        4'b1100: begin
//          rd_ptr <= #TCQ next_rd_ptr;
//          wr_ptr <= #TCQ next_wr_ptr;
        end
        4'b1101: begin
//          rd_ptr <= #TCQ next_rd_ptr;
//          wr_ptr <= #TCQ next_wr_ptr;
        end
        default: begin
          $display("ERR %m @%t Illegal pointer sequence!", $time);
        end
      endcase
    end
  endtask

        // synthesis translate_on
  assign d_out = my_empty ? d_in : mem_out;
  assign wr_en_out = /*!full_in && */(!my_empty || wr_en_in);
  
        // synthesis translate_off
  always @(posedge clk) 
    if (rst) begin
//      for (i = 0; i < DEPTH; i = i + 1) 
//        mem[i] <= 'bx;
//      my_empty <= 1'b1;
//      my_full <= 1'b0;
//      rd_ptr <= 'b0;
//      wr_ptr <= 'b0;
    end else begin
      casez ({my_empty, my_full, full_in, wr_en_in})
        4'b0z00: begin
//          updt_ptrs(1'b1, 1'b0);
        end
        4'b0z01: begin
//          updt_ptrs(1'b1, 1'b1);
//          mem[wr_ptr] <= #TCQ d_in;
        end
        4'bz011: begin
//          updt_ptrs(1'b0, 1'b1);
//          mem[wr_ptr] <= #TCQ d_in;
        end
        4'b0010, 4'b0110, 4'b1000, 4'b1001, 4'b1010: ; // do nothing
        // bad news
        4'b0111: begin
          $display("ERR %m @%t Both FIFOs full and a write came in!", 
                   $time);
        end
        default: begin
          $display("ERR %m @%t Illegal access sequence!", $time);
        end
      endcase
    end
        // synthesis translate_on       

assign wr_en = wr_en_in & ((!my_empty & !full_in)|(!my_full & full_in));

always @ (posedge clk)
begin
  if (wr_en)
    mem[wr_ptr] <= #TCQ d_in;
end

assign mem_out = mem [rd_ptr];

assign nxt_rd_ptr = (rd_ptr + 1'b1)%DEPTH;

always @ (posedge clk)
begin
  if (rst)
  begin
    rd_ptr <= 'b0;
  end
  else if ((!my_empty) & (!full_in))
  begin 
    rd_ptr <= nxt_rd_ptr;
  end
end

always @ (posedge clk)
begin
  if (rst)
  begin
    my_empty <= 1'b1;
  end
  else if (my_empty & !my_full & full_in & wr_en_in)
  begin
    my_empty <= 1'b0;
  end
  else if (!my_empty & !my_full & !full_in & !wr_en_in)
  begin
    my_empty <= (nxt_rd_ptr == wr_ptr);
  end
end

assign nxt_wr_ptr = (wr_ptr + 1'b1)%DEPTH;

always @ (posedge clk)
begin
  if (rst)
  begin
    wr_ptr <= 'b0;
  end
  else if ( (wr_en_in) & ( (!my_empty & !full_in) | (!my_full & full_in) ) )
  begin 
    wr_ptr <= nxt_wr_ptr;
  end
end

always @ (posedge clk)
begin
  if (rst)
  begin
    my_full <= 1'b0;
  end
  else if (!my_empty & my_full & !full_in & !wr_en_in)
  begin
    my_full <= 1'b0;
  end
  else if (!my_empty & !my_full & full_in & wr_en_in)
  begin
    my_full <= (nxt_wr_ptr == rd_ptr);
  end
end

endmodule
