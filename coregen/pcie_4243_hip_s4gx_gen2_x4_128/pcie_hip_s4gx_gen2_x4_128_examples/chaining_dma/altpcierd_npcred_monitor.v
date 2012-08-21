// /**
//  *   
//  */
// synthesis translate_off
 
`timescale 1ns / 1ps
// synthesis translate_on
// synthesis verilog_input_version verilog_2001
// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

//-----------------------------------------------------------------------------
// Title         : altpcierd_npcred_monitor
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcierd_npcred_monitor.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
//
//  Description:  This module monitors NonPosted header credits.  
//                It implements the algorithm for sampling tx_cred from 
//                the core, and accounts for in-flight TLPs.
//-----------------------------------------------------------------------------
// Copyright © 2009 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation 
// and therefore all warranties, representations or guarantees of any kind 
// (whether express, implied or statutory) including, without limitation, warranties of 
// merchantability, non-infringement, or fitness for a particular purpose, are 
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------


module altpcierd_npcred_monitor  # (
    parameter  CRED_LAT = 10   // # clks for np_sent to be reflected on np_cred_hip
) ( 
   input             clk_in, 
   input             rstn,   
   input [2:0]       np_cred,        // from HIP. 
   input             np_sent,        // this is NP TLP being issued from source logic that is doing credit check gating
   input             np_tx_sent,     // indicates NP TLP has been transmitted onto AV-ST (xx clks later, will be reflected on np_cred)
 
   output reg        have_cred       // indicates to source logic that there is atleast 1 NP credit.
   );
   
   localparam  LATCH_CRED      = 2'h0;
   localparam  GRANT_CRED      = 2'h1;
   localparam  WAIT_LAST_NP_TX = 2'h2;
   localparam  WAIT_CRED_UPD   = 2'h3;
   
   reg[2:0]  cred_sm;
   reg[2:0]  local_creds_avail;
   reg[7:0]  creds_granted; 
   reg[7:0]  latency_counter;
   reg[7:0]  creds_sent_on_tx;      // count # of NPs that made it out onto AV-ST interface
   wire      update_creds;
   
   assign update_creds = (cred_sm==LATCH_CRED) & (np_cred > 0);
   
   always @ (negedge rstn or posedge clk_in) begin
      if (rstn==1'b0) begin  
          cred_sm <= LATCH_CRED;
          local_creds_avail <= 3'h0;
          creds_sent_on_tx <= 8'h0;
          creds_granted <= 8'h0;
      end
      else begin    
          //-------------------------------------
          // track NP TLPs being sent on AV-ST TX
          
          if (update_creds) begin
              creds_sent_on_tx <= 8'h0;
          end
          else if (np_tx_sent) begin
              creds_sent_on_tx <= creds_sent_on_tx + 8'h1;
          end
          
          
          //----------------------------
          // monitor available TX creds
          case (cred_sm)
              LATCH_CRED: begin
                  latency_counter     <= 8'h0;
                  local_creds_avail   <= np_cred;  
                  creds_granted       <= np_cred;
                  if (np_cred > 0) begin
                      cred_sm   <= GRANT_CRED;
                      have_cred <= 1'b1; 
                  end 
                  else begin
                      cred_sm   <= cred_sm;
                      have_cred <= 1'b0; 
                    //  have_cred <= 1'b1; 
                  end
              end
              GRANT_CRED: begin
                  //  Grant credits until
                  //  all all creds used
                  local_creds_avail <= np_sent ? local_creds_avail-3'h1 : local_creds_avail; 
                  have_cred <= (local_creds_avail==3'h1) & np_sent ? 1'b0 : 1'b1;
                  if ((local_creds_avail==3'h1) & np_sent) begin
                      cred_sm   <= WAIT_LAST_NP_TX; 
                  end
                  else begin
                      cred_sm <= cred_sm;
                  end
              end
              WAIT_LAST_NP_TX: begin
                  // wait for all NP's to be 
                  // transmitted on AV-ST  
                  if (creds_sent_on_tx == creds_granted) begin
                      cred_sm <= WAIT_CRED_UPD;
                  end
                  else begin
                      cred_sm <= cred_sm;
                  end
              end
              WAIT_CRED_UPD: begin
                  latency_counter <= latency_counter + 8'h1;
                  if (latency_counter==CRED_LAT) begin
                      cred_sm <= LATCH_CRED;
                  end
                  else begin
                      cred_sm <= cred_sm;
                  end
              end
          endcase 
      end
   end
    
 
endmodule
