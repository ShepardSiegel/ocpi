//Legal Notice: (C)2009 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altpcierd_compliance_test (
    input local_rstn,                  // Local board reset
    input pcie_rstn,                   // PCIe reset
    input refclk,                      // 100 Mhz clock
    input req_compliance_push_button_n,// Push button to cycle through compliance mode, gen1, gen2 - Active low
    input req_compliance_soft_ctrl  ,  // Register to cycle trough compliance mode (monitor rising edge on this register - Active on 0 to 1 transition
    input set_compliance_mode,         // Set compliance mode (test_in[32])

    output test_in_5_hip,
    output test_in_32_hip);

wire rstn;                   // async rstn synchronized on refclk
wire exit_ltssm_compliance;  // when 1 : force exit LTSSM COMPLIANCE state
                             // When 0 : if board plugged on compliance based board, LTSSM returns to COMPLIANCE state
wire new_edge_for_compliance;
reg [2:0] ltssm_cnt_cycles;
reg [15:0] dbc_cnt;

assign test_in_5_hip = (set_compliance_mode==1'b0) ? 1'b1 : exit_ltssm_compliance;
assign test_in_32_hip= set_compliance_mode;

//
// LTSSM Compliance forcing in/out
//
assign exit_ltssm_compliance = ltssm_cnt_cycles[2];
always @(posedge refclk or negedge rstn) begin
   if (rstn == 1'b0) begin
      ltssm_cnt_cycles     <= 3'b000;
   end
   else begin
      if (new_edge_for_compliance==1'b1) begin
         ltssm_cnt_cycles <= 3'b111;
      end
      else if (ltssm_cnt_cycles != 3'b000) begin
         ltssm_cnt_cycles <= ltssm_cnt_cycles - 3'b001;
      end
   end
end

reg  req_compliance_cycle,req_compliance_cycle_r, req_compliance_soft_ctrl_r;
always @(posedge refclk or negedge rstn) begin
   if (rstn == 1'b0) begin
      req_compliance_cycle       <= 1'b1;
      req_compliance_cycle_r     <= 1'b1;
      req_compliance_soft_ctrl_r <= 1'b1;
   end
   else begin
      req_compliance_cycle       <= (dbc_cnt == 16'h0000) ? 1'b0: 1'b1;
      req_compliance_cycle_r     <= req_compliance_cycle;
      req_compliance_soft_ctrl_r <= req_compliance_soft_ctrl;
   end
end
assign new_edge_for_compliance = (((req_compliance_cycle_r == 1'b1)&(req_compliance_cycle == 1'b0))||
                                 ((req_compliance_soft_ctrl_r == 1'b0)&(req_compliance_soft_ctrl == 1'b1))) ?1'b1:1'b0;


//De bouncer  for push button
always @(posedge refclk or negedge rstn) begin
    if (rstn == 1'b0) begin
       dbc_cnt <= 16'hFFFF;
    end
    else begin
       if (req_compliance_push_button_n == 0) begin
          dbc_cnt <= 16'hFFFF;
       end
       else if (dbc_cnt != 16'h0000) begin
          dbc_cnt <= dbc_cnt -16'h1;
       end
    end
end


// Sync async reset
wire npor ;
reg  [2:0] rstn_sync;

assign npor = pcie_rstn & local_rstn;
always @(posedge refclk or negedge npor) begin
   if (npor == 1'b0) begin
      rstn_sync[2:0] <= 3'b000;
   end
   else begin
      rstn_sync[0] <= 1'b1;
      rstn_sync[1] <= rstn_sync[0];
      rstn_sync[2] <= rstn_sync[1];
   end
end
assign rstn  = rstn_sync[2];

endmodule

