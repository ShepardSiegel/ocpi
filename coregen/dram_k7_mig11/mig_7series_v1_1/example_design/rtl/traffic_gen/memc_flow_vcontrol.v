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
//  /   /         Filename: mcb_flow_control.v
// /___/   /\     Date Last Modified: $Date: 2010/12/13 23:13:50 $
// \   \  /  \    Date Created: 
//  \___\/\___\
//
//Device: Virtex 6
//Design Name: DDR2/DDR3
//Purpose: This module is the main flow control between cmd_gen.v, 
//         write_data_path and read_data_path modules.
//Reference:
//Revision History: 7/29/10  Support V6 Back-to-back commands over user interface.
//                          
//*****************************************************************************

`timescale 1ps/1ps

module memc_flow_control #
  (
    parameter TCQ           = 100,
    parameter nCK_PER_CLK   = 4,
    parameter NUM_DQ_PINS = 32,
    parameter BL_WIDTH = 6,
    parameter MEM_BURST_LEN = 4,
    parameter FAMILY = "SPARTAN6",
    parameter MEM_TYPE = "DDR3"
    
  )
  ( 
   input     clk_i, 
   input [9:0]    rst_i,
   input [3:0]            data_mode_i,
   input [5:0]    cmds_gap_delay_value,
   // interface to cmd_gen, pipeline inserter
   output  reg     cmd_rdy_o, 
   input        cmd_valid_i, 
   input [2:0]  cmd_i, 
   input [31:0] addr_i, 
   input [BL_WIDTH - 1:0]  bl_i,

   
   // interface to mcb_cmd port
   input                  mcb_cmd_full,
   input                  mcb_wr_full_i,
   output reg [2:0]           cmd_o, 
   output  [31:0]          addr_o, 
   output reg [BL_WIDTH-1:0]           bl_o,
   output                 cmd_en_o,   // interface to write data path module
   // *** interface to qdr ****
   output reg               qdr_rd_cmd_o,
   // *************************
   input                  mcb_wr_en_i,
   input                  last_word_wr_i,
   input                  wdp_rdy_i, 
   output  reg            wdp_valid_o, 
   output  reg            wdp_validB_o, 
   output  reg            wdp_validC_o,   
   
   output  [31:0]         wr_addr_o, 
   output  [BL_WIDTH-1:0] wr_bl_o,
   // interface to read data path module
   input                   rdp_rdy_i, 
   output  reg             rdp_valid_o, 
   output  [31:0]          rd_addr_o, 
   output [BL_WIDTH-1:0]   rd_bl_o
   );
   
   //FSM State Defination
localparam READY      = 5'b00001,
           READ       = 5'b00010,
           WRITE      = 5'b00100,
           CMD_WAIT   = 5'b01000,
           REFRESH_ST = 5'b10000; 

localparam RD     =         3'b001;
localparam RDP    =         3'b011;
localparam WR     =         3'b000;
localparam WRP    =         3'b010;
localparam REFRESH =        3'b100;
localparam NOP     =        3'b101;  // this defination is local to this traffic gen and is not defined


reg cmd_fifo_rdy;
wire cmd_rd;
wire cmd_wr;         // need equation
wire cmd_others;
reg  push_cmd;
//reg  xfer_cmd;
reg  rd_vld  ;  
reg  wr_vld;
reg  cmd_rdy;
reg [31:0]  addr_r;
reg [2:0]   bank_cnt;
reg [2:0]   cmd_reg; 
reg [31:0]  addr_reg; 
reg [BL_WIDTH - 1:0]   bl_reg;
reg [BL_WIDTH :0]   cmd_counts;
reg       rdp_valid;
(*EQUIVALENT_REGISTER_REMOVAL="NO"*) reg   wdp_valid,wdp_validB,wdp_validC;

reg [4:0] current_state;
reg [4:0] next_state;
reg [3:0] tstpointA;
reg push_cmd_r;
reg wait_done;
reg cmd_en_r1 ;
reg wr_in_progress,wr_in_progress_r;
reg wrcmd_in_progress;
//reg [10:0] INC_COUNTS;
reg push_cmd_valid;
reg wr_path_full_r;
reg rdcmd_in_progress;
//localparam MEM_BURST_INT = (MEM_BURST_LEN == "8")? 8 : 4;
localparam MEM_BURST_INT = MEM_BURST_LEN ;
reg[5:0] commands_delay_counters;
reg       goahead;
reg       cmd_rdy_latch;
reg cmd_en_r2;  // Spartan 6 use only

reg [3:0] addr_INC;

reg     [8*50:0]        flow_command;

always @ (posedge clk_i) begin

if (data_mode_i == 4'b1000 || FAMILY == "SPARTAN6" )
     addr_INC <= #TCQ  0;
else                                                        // *** need to uncomment this for Fuji
     addr_INC <= #TCQ  MEM_BURST_LEN[3:0];                  // *** need to uncomment this for Fuji
end

 initial begin
    addr_r   = 'b0;
  end

/*
    always @ (posedge clk_i) begin
    
if ( (NUM_DQ_PINS >= 128 && NUM_DQ_PINS <= 144))       //256
     INC_COUNTS <= #TCQ  64 * (MEM_BURST_INT/4);
    
else if ( (NUM_DQ_PINS >= 64 && NUM_DQ_PINS < 128))       //256
     INC_COUNTS <= #TCQ  32 * (MEM_BURST_INT/4);
else if ((NUM_DQ_PINS >= 32) && (NUM_DQ_PINS < 64))   //128
     INC_COUNTS <= #TCQ  16 * (MEM_BURST_INT/4)   ;
else if ((NUM_DQ_PINS == 16) || (NUM_DQ_PINS == 24))  //64
     INC_COUNTS <= #TCQ  8 * (MEM_BURST_INT/4);
else if ((NUM_DQ_PINS == 8) )
     INC_COUNTS <= #TCQ  4 * (MEM_BURST_INT/4);
end
*/


//  mcb_command bus outputs

always @(posedge clk_i) begin    
if (rst_i[0]  ) begin
    commands_delay_counters <=  5'b00000;
    goahead <= 1'b1;
    end
else if (cmds_gap_delay_value == 5'd0)
    goahead <= 1'b1;

else if ((wr_in_progress || wrcmd_in_progress || rdcmd_in_progress || cmd_rdy_o) ) begin
    commands_delay_counters <=  5'b00000;
    goahead <= 1'b0;
    end
else
  if (commands_delay_counters == cmds_gap_delay_value) begin 
    commands_delay_counters <= commands_delay_counters ;
    goahead <= 1'b1;
    end
  else  
    commands_delay_counters <= commands_delay_counters + 1'b1;

  

end
assign cmd_en_o = (FAMILY == "VIRTEX6") ? cmd_en_r1 : (~cmd_en_r1 & cmd_en_r2) ;


always @ (posedge clk_i) begin
       cmd_rdy_o <= #TCQ cmd_rdy;
    
end

//generate
//if (FAMILY == "VIRTEX6") begin
always @ (posedge clk_i)
begin
if (rst_i[8])
    cmd_en_r1 <= #TCQ  1'b0;
else if (cmd_counts == 1 && (!mcb_cmd_full &&  cmd_en_r1 || mcb_wr_full_i))
    cmd_en_r1 <= #TCQ  1'b0;

else if ( rdcmd_in_progress || wrcmd_in_progress  && MEM_TYPE != "QDR" ||
           mcb_wr_en_i && MEM_TYPE == "QDR")

    cmd_en_r1 <= #TCQ  1'b1;
 else if (!mcb_cmd_full )
    cmd_en_r1 <= #TCQ  1'b0;
 
 end
//end endgenerate

generate
if (FAMILY == "SPARTAN6") begin
always @ (posedge clk_i)
begin
if (rst_i[8])
    cmd_en_r2 <= #TCQ  1'b0;
else
    cmd_en_r2 <= cmd_en_r1;
 end
end endgenerate

// QDR rd command generation
always @ (posedge clk_i)
begin
if (rst_i[8])
    qdr_rd_cmd_o <= #TCQ  1'b0;
else if (cmd_counts == 0 && !mcb_cmd_full && rdcmd_in_progress && cmd_en_r1)
    qdr_rd_cmd_o <= #TCQ  1'b0;

else if ( rdcmd_in_progress )

    qdr_rd_cmd_o <= #TCQ  1'b1;
 else if (!mcb_cmd_full)
    qdr_rd_cmd_o <= #TCQ  1'b0;
 
 end


always @ (posedge clk_i)
begin
if (rst_i[9])
    cmd_fifo_rdy <= #TCQ  1'b1;
else if (cmd_en_r1 || mcb_cmd_full)//(xfer_cmd)
    cmd_fifo_rdy <= #TCQ  1'b0;
else if (!mcb_cmd_full)    
    cmd_fifo_rdy <= #TCQ  1'b1;
end

always @ (posedge clk_i)
begin
if (rst_i[9]) begin
    cmd_o  <= #TCQ  'b0;
    bl_o   <= #TCQ  'b0;
end
//else if (xfer_cmd && current_state == READ ) begin  // this one has bug
else if (push_cmd_r && current_state == READ ) begin
        cmd_o <=    #TCQ cmd_i;
        bl_o   <= #TCQ bl_i - 1'b1;
end
else if ( push_cmd_r && current_state == WRITE) begin

    if (FAMILY == "SPARTAN6")
        cmd_o <= #TCQ  cmd_reg;
    else
        cmd_o  <= #TCQ  {2'b00,cmd_reg[0]};
    bl_o   <= #TCQ  bl_reg;
end

end


always @ (posedge clk_i)
 if (push_cmd)
        addr_reg <= #TCQ addr_i;
        


always @ (posedge clk_i)
begin
if (push_cmd && cmd_rd) begin
    addr_r <= #TCQ  addr_i;
end
 
else if (push_cmd_r  && current_state != READ) begin
    addr_r <= #TCQ  addr_reg;
end
//else if (xfer_cmd ) begin
else if ((wrcmd_in_progress && ~mcb_cmd_full)|| (rdcmd_in_progress && cmd_en_r1 && ~mcb_cmd_full)) begin

       
    if (cmd_en_r1) begin

       // for V6, BL 8, BL 4
         addr_r[31:0] <= addr_o + addr_INC;
       
    end
end


end

//assign addr_o[24:0] = addr_r[24:0];
//assign addr_o[27:25] = bank_cnt;
//assign addr_o[31:28] = addr_r[31:28];
//assign addr_o[8:0] = addr_r[8:0];
//assign addr_o[31:9] = 'b0;
assign addr_o = addr_r;



// go directly to wr_datapath and rd_datapath modules 
       assign  wr_addr_o = addr_i;
       assign  rd_addr_o = addr_i;
assign rd_bl_o   = bl_i ;
assign wr_bl_o   = bl_i ;


always @ (posedge clk_i)
begin

 wdp_valid_o <= wdp_valid;
 wdp_validB_o <= wdp_validB;
 wdp_validC_o <= wdp_validC;



end


always @ (posedge clk_i)
begin

 rdp_valid_o <= rdp_valid;
end

// internal control siganls

always @ (posedge clk_i)
begin
if (rst_i[8])
   wait_done <= #TCQ  1'b1;
else if (push_cmd_r)
   wait_done <=  #TCQ 1'b1;
else if (cmd_rdy_o && cmd_valid_i && FAMILY == "SPARTAN6")
   wait_done <=  #TCQ 1'b0;


end

//  


always @ (posedge clk_i)
     begin
     push_cmd_r  <= #TCQ push_cmd;
     end
always @ (posedge clk_i)
 if (push_cmd)
   begin
        cmd_reg <=    #TCQ cmd_i;
        bl_reg   <= #TCQ bl_i - 1'b1;
        
   end
 
 
always @ (posedge clk_i)
begin
  if (push_cmd)
      if (bl_i == 0)
           if (MEM_BURST_LEN == 8)
              if (nCK_PER_CLK == 4)
                  cmd_counts <= #TCQ {1'b1, {BL_WIDTH-1{1'b0}}};
              else
                 if (FAMILY == "SPARTAN6")
                     cmd_counts <= bl_i ;
                 else
                  cmd_counts <= #TCQ {1'b1, {BL_WIDTH-2{1'b0}}};
              
           else// not tested yet in MEM_BURST_LEN == 4
            cmd_counts <= {(BL_WIDTH -1){1'b1}} ;//- 2;//63;
         
      else
         if (MEM_BURST_LEN == 8)
              if (nCK_PER_CLK == 4)         
                   cmd_counts <= bl_i ;
              else
                 if (FAMILY == "SPARTAN6")
                   cmd_counts <= bl_i ;
                 
                 else
                   cmd_counts <= {1'b0,bl_i[BL_WIDTH-2:1]}; 
              
         else // not tested yet in MEM_BURST_LEN == 4
           cmd_counts <= bl_i ;//- 1 ;// {1'b0,bl_i[5:1]} -2;
         
  else if ((wrcmd_in_progress  || rdcmd_in_progress ) && cmd_en_r1 && ~mcb_cmd_full)
      if (MEM_BURST_LEN == 8 && cmd_counts > 0)
       // cmd_counts <= cmd_counts - 2;
        if (FAMILY == "VIRTEX6")
        cmd_counts <= cmd_counts - 1'b1;
        
      else
           if (wrcmd_in_progress)
        cmd_counts <= cmd_counts - 1'b1;
           else
                 cmd_counts <= 0;
          
end  
 
   
//--Command Decodes--
assign  cmd_wr     = ((cmd_i == WR  | cmd_i == WRP) & cmd_valid_i )  ? 1'b1 : 1'b0;
assign  cmd_rd     = ((cmd_i == RD | cmd_i == RDP) & cmd_valid_i) ? 1'b1 : 1'b0;
assign  cmd_others = ((cmd_i[2] == 1'b1)& cmd_valid_i && (FAMILY == "SPARTAN6")) ? 1'b1 : 1'b0;

    
reg cmd_wr_pending_r1;  

always @ (posedge clk_i)
begin
if (rst_i[0])
    cmd_wr_pending_r1 <= #TCQ 1'b0;

//else if (current_state == WRITE && last_word_wr_i && !cmd_fifo_rdy)
//else if ( last_word_wr_i && !cmd_fifo_rdy)
else if ( last_word_wr_i )


    cmd_wr_pending_r1 <= #TCQ 1'b1;
else if (push_cmd)//xfer_cmd)
    cmd_wr_pending_r1 <= #TCQ 1'b0;
end    


// corner case if fixed read command with fixed bl 64

always @ (posedge clk_i)
begin
if (rst_i[0])
   wr_in_progress <= #TCQ  1'b0;
else if (last_word_wr_i )   
   wr_in_progress <= #TCQ  1'b0;   
else if (push_cmd && cmd_wr)   
   wr_in_progress <= #TCQ  1'b1;


end

 always @ (posedge clk_i)
 begin
if (rst_i[0])
   wrcmd_in_progress <= #TCQ  1'b0;
//else if (last_word_wr_i )   
else if (cmd_wr && push_cmd )   

   wrcmd_in_progress <= #TCQ  1'b1;   
else if (cmd_counts == 0  || cmd_counts == 1)   
   wrcmd_in_progress <= #TCQ  1'b0;


end


 always @ (posedge clk_i)
 begin
if (rst_i[0])
   rdcmd_in_progress <= #TCQ  1'b0;
else if (cmd_rd && push_cmd)   
   rdcmd_in_progress <= #TCQ  1'b1;

else if (cmd_counts <= 1)   
   rdcmd_in_progress <= #TCQ  1'b0;   


end


 always @ (posedge clk_i)
 begin
    if (rst_i[0])
        current_state <= #TCQ  4'b0001;
    else
        current_state <= #TCQ next_state;
 end

// mcb_flow_control statemachine
always @ (*)
begin
               push_cmd  = 1'b0;
//               xfer_cmd = 1'b0;
               
               wdp_valid = 1'b0;
               wdp_validB = 1'b0;
               wdp_validC = 1'b0;
               
               rdp_valid = 1'b0;
               cmd_rdy = 1'b0;
               next_state = current_state;
case(current_state)
   READY:  
        begin
         if(rdp_rdy_i && cmd_rd && ~mcb_cmd_full)   //rdp_rdy_i comes from read_data path

            begin
              next_state = READ;
              push_cmd = 1'b1;
//              xfer_cmd = 1'b0;
              rdp_valid = 1'b1;
              cmd_rdy = 1'b1;
            end
         else if (wdp_rdy_i && cmd_wr && ~mcb_cmd_full)
             begin
              next_state = WRITE;
               push_cmd = 1'b1;
               wdp_valid     = 1'b1;
               wdp_validB = 1'b1;
               wdp_validC = 1'b1;
               cmd_rdy = 1'b1;
             end 
         else if ( cmd_others && cmd_fifo_rdy)
             begin
              next_state = REFRESH_ST;
               push_cmd = 1'b1;
//               xfer_cmd = 1'b0;
              cmd_rdy = 1'b0;
               
             end 
             
         else
              begin
              next_state = READY;
              push_cmd = 1'b0;
              cmd_rdy = 1'b0;
              end
         
         end
         
   REFRESH_ST : begin
   
         if (rdp_rdy_i && cmd_rd && cmd_fifo_rdy  )
            begin
               next_state = READ;
               push_cmd = 1'b1;
               rdp_valid = 1'b1;
               wdp_valid = 1'b0;
  //             xfer_cmd = 1'b1;
              // tstpointA    = 4'b0101;
               
            end   
          else if (cmd_fifo_rdy && cmd_wr && wdp_rdy_i )
             begin
               next_state = WRITE;
               push_cmd = 1'b1;
   //            xfer_cmd = 1'b1;
               
               wdp_valid     = 1'b1;
               wdp_validB    = 1'b1;
               wdp_validC    = 1'b1;
               
             //   tstpointA    = 4'b0110;
              
             end
            
          else if (cmd_fifo_rdy && cmd_others)
             begin
               push_cmd = 1'b1;
  //             xfer_cmd = 1'b1;
             end
          else if (!cmd_fifo_rdy)

             begin
               next_state = CMD_WAIT;
               tstpointA    = 4'b1001;
               
             end  
          else
               next_state = READ; 
 
              cmd_rdy = 1'b0;
          
         
   
          end
   READ:  begin
   
         if (rdcmd_in_progress )

            begin
               next_state = READ;
               push_cmd = 1'b0;
               rdp_valid = 1'b0;
               wdp_valid = 1'b0;
               tstpointA    = 4'b0101;
               
            end   
         else if (!rdp_rdy_i )
            begin
               next_state = READ; 
               push_cmd  = 1'b0;
              
               tstpointA    = 4'b0111;
              
               wdp_valid = 1'b0;
               wdp_validB = 1'b0;
               wdp_validC    = 1'b0;
               rdp_valid = 1'b0;
            end                       
          else if (~cmd_fifo_rdy && ~rdcmd_in_progress && goahead)

             begin
//               next_state = READY;//CMD_WAIT;
               next_state = CMD_WAIT;

               tstpointA    = 4'b1001;
               
             end  
          else if (goahead)
               next_state = READY; 
 
 
               
              cmd_rdy = 1'b0;
          
        
        end
   WRITE: begin  // for write, always wait until the last_word_wr 
          if ( wr_in_progress || wrcmd_in_progress || push_cmd_r )

               begin
                  next_state = WRITE;

               tstpointA    = 4'b0001;
                  wdp_valid     = 1'b0;
                  wdp_validB = 1'b0;
               wdp_validC    = 1'b0;
                  push_cmd = 1'b0;
               
               end               
          else if (!cmd_fifo_rdy && last_word_wr_i && goahead)

               begin
//               next_state = READY;// CMD_WAIT;
               
               next_state = CMD_WAIT;
               push_cmd = 1'b0;
               tstpointA    = 4'b0011;
               
               end
          
          else if (goahead) begin
               next_state = READY;
               tstpointA    = 4'b0100;
               end

             cmd_rdy = 1'b0;
         
              
         end
   
   
   

   
   CMD_WAIT: if (!cmd_fifo_rdy || wr_in_progress)
               begin
               next_state = CMD_WAIT;
               cmd_rdy = 1'b0;
               tstpointA    = 4'b1010;
               
               end
             else if (cmd_fifo_rdy && rdp_rdy_i && cmd_rd)
               begin
               next_state = READY;
               push_cmd = 1'b0;
               cmd_rdy = 1'b0;
               rdp_valid     = 1'b0;
               
               tstpointA    = 4'b1011;
               end
             else if (cmd_fifo_rdy  && cmd_wr && goahead && (wait_done || cmd_wr_pending_r1))

               begin
               next_state = READY;
               push_cmd = 1'b0;
               cmd_rdy = 1'b0;
               wdp_valid     = 1'b0;
               wdp_validB = 1'b0;
               wdp_validC    = 1'b0;
               
               tstpointA    = 4'b1100;
               
               end
             else
               begin
               next_state = CMD_WAIT;
               tstpointA    = 4'b1110;
               cmd_rdy = 1'b0;
                  
                  
               end
     
               
   default:
          begin
           push_cmd = 1'b0;
           
           wdp_valid = 1'b0;
           wdp_validB = 1'b0;
           wdp_validC    = 1'b0;
           next_state = READY;              
                    
                         

         end
   
 endcase
 end
   
   
   
   
  //synthesis translate_off
   
   
always @(current_state) begin
        casex (current_state)
                5'b00001 :       begin flow_command = "READY";            end
                5'b00010 :       begin flow_command = "READ" ;             end
                5'b00100 :       begin flow_command = "WRITE";                 end
                5'b01000 :       begin flow_command = "CMD_WAIT"  ;           end
                5'b10000 :       begin flow_command = "REFRESH_ST";            end
        endcase                                                                           
                                                                                          
end                                                                                       
 
  //synthesis translate_on

   
endmodule 
