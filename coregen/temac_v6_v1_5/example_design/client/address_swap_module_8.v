//-----------------------------------------------------------------------------
// Title      : Address Swapping Module
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : address_swap_module_8.v
// Version    : 1.5
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
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
//----------------------------------------------------------------------
// Description: - Takes in frame from the client-side EMAC reciever.
//              - Swaps the source address with destination address.
//              - Outputs the modified frame.
//              - rx_data_valid, rx_good_frame, rx_bad_frame are delayed
//                by an equal number of clock cycles to rx_data.
//              - The module consists of a six-stage shift register and
//                multiplexer to select data either from the shift
//                register output or directly from the data input.  The
//                destination address is loaded into the shift register
//                and held whilst the source address is selected
//                directly from the input.  Once the source address has
//                been output, data is taken from the shift register.
//----------------------------------------------------------------------

`timescale 1 ns/1 ps

//fsm type and signals
`define wait_sf    3'd0  // awaiting start of frame
`define bypass_sa1 3'd1  // bypassing first byte of source address
`define bypass_sa2 3'd2  // bypassing second byte of source address
`define bypass_sa3 3'd3  // bypassing third byte of source address
`define bypass_sa4 3'd4  // bypassing fourth byte of source address
`define bypass_sa5 3'd5  // bypassing fifth byte of source address
`define bypass_sa6 3'd6  // bypassing sixth byte of source address
`define pass_rof   3'd7  // transmitting remainder of data in frame


module address_swap_module_8 (
      rx_ll_clock,         // Input CLK from TRIMAC Reciever
      rx_ll_reset,         // Synchronous reset signal
      rx_ll_data_in,       // Input data
      rx_ll_sof_in_n,      // Input start of frame
      rx_ll_eof_in_n,      // Input end of frame
      rx_ll_src_rdy_in_n,  // Input source ready
      rx_ll_data_out,      // Modified output data
      rx_ll_sof_out_n,     // Output start of frame
      rx_ll_eof_out_n,     // Output end of frame
      rx_ll_src_rdy_out_n, // Output source ready
      rx_ll_dst_rdy_in_n   // Input destination ready
   );

// Port declarations
   input  rx_ll_clock;
   input  rx_ll_reset;
   input  [7:0] rx_ll_data_in;
   input  rx_ll_sof_in_n;
   input  rx_ll_eof_in_n;
   input  rx_ll_src_rdy_in_n;
   output [7:0] rx_ll_data_out;
   reg    [7:0] rx_ll_data_out;
   output rx_ll_sof_out_n;
   output rx_ll_eof_out_n;
   output rx_ll_src_rdy_out_n;
   input  rx_ll_dst_rdy_in_n;

   // Signal declarations
   reg        sel_delay_path;        // controls mux in Process data_out_mux
   reg        enable_data_sr;        // clock enable for data shift register
   wire [7:0] data_sr5;              // data after 6 cycle delay
   reg  [7:0] mux_out;               // data to output register

   wire       rx_enable;             // Internal enable signal

   // state machine state variable
   reg [2:0]  control_fsm_state;     // holds state of control fsm

   // 6 stage shift register type and signals
   reg [7:0]  data_sr_content[0:5];  // holds contents of data sr


   // 7 stage shift register type and signals
   reg        eof_sr_content[0:6];  // holds contents of end of frame sr
   reg        sof_sr_content[0:6];  // holds contents of start of frame sr
   reg        rdy_sr_content[0:6];   // holds contents of source ready sr

   integer    i;  // index for sr processes

   //--------------------------------------------------------------------------
   //Process data_sr_p
   //A six stage shift register to hold six bytes of incoming data.
   //Clock enable signal enable_data_sr allows destination address to be stored
   //in shift register when in bypass mode.
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (enable_data_sr == 1'b1 && rx_enable == 1'b1)
      begin
       for(i=5; i >0; i=i-1)
         data_sr_content[i] <= data_sr_content [i-1];
       data_sr_content[0] <= rx_ll_data_in;
      end
   end // data_sr_p
   assign data_sr5 = data_sr_content[5];

   //--------------------------------------------------------------------------
   //Process data_out_mux_p
   //Selects data_out from the data shift register or from data_in, allowing
   //destination address to be bypassed
   //--------------------------------------------------------------------------
   always @(rx_ll_data_in, data_sr5, sel_delay_path)
   begin
      if (sel_delay_path == 1'b1)
         mux_out = rx_ll_data_in;
      else
         mux_out = data_sr5;
   end // data_out_mux_p

   //--------------------------------------------------------------------------
   //Process data_out_reg_p
   //Registers data output from output mux
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (rx_enable == 1'b1)
         rx_ll_data_out <= mux_out;
   end // data_out_reg_p

   assign rx_enable = ~(rx_ll_dst_rdy_in_n);

   //--------------------------------------------------------------------------
   //Process data_sof_sr_p
   //Delays start of frame by 7 clock cycles
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (rx_enable == 1'b1)
      begin
         for(i=6; i>0; i=i-1)
         sof_sr_content[i] <= sof_sr_content[i-1];
         sof_sr_content[0] <= !rx_ll_sof_in_n;
      end
   end // data_sof_sr_p
   assign rx_ll_sof_out_n = !sof_sr_content[6];

   //--------------------------------------------------------------------------
   //Process data_eof_sr_p
   //Delays end of frame by 7 clock cycles
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (rx_enable == 1'b1)
      begin
       for(i=6; i>0; i=i-1)
         eof_sr_content[i] <= eof_sr_content[i-1];
         eof_sr_content[0] <= !rx_ll_eof_in_n;
      end
   end // data_bad_sr_p
   assign rx_ll_eof_out_n = !eof_sr_content[6];

   //--------------------------------------------------------------------------
   //Process data_rdy_sr_p
   //Delays source ready by 7 clock cycles
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (rx_enable == 1'b1)
      begin
         for(i=6; i>0; i=i-1)
         rdy_sr_content[i] <= rdy_sr_content[i-1];
         rdy_sr_content[0] <= !rx_ll_src_rdy_in_n;
      end
   end // data_bad_sr_p
   assign rx_ll_src_rdy_out_n = !rdy_sr_content[6];

   //--------------------------------------------------------------------------
   //Process control_fsm_sync_p
   //Synchronous update of next state of control_fsm
   //--------------------------------------------------------------------------
   always @(posedge rx_ll_clock)
   begin
      if (rx_ll_reset == 1)
         control_fsm_state <= `wait_sf;
      else
         if (rx_enable == 1'b1)
         begin
            case(control_fsm_state)
               `wait_sf :     if (sof_sr_content[4] == 1'b1)
                              control_fsm_state <= `bypass_sa1;  // Start of frame detected
                              else
                              control_fsm_state <= `wait_sf;     // Continue to wait for sof

                `bypass_sa1 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `bypass_sa2;  // Pass next byte of source address
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `bypass_sa2 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `bypass_sa3;  // Pass next byte of source address
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `bypass_sa3 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `bypass_sa4;  // Pass next byte of source address
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `bypass_sa4 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `bypass_sa5;  // Pass next byte of source address
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `bypass_sa5 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `bypass_sa6;  // Pass next byte of source address
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `bypass_sa6 : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `pass_rof;    // Output remaining data in frame
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame

                `pass_rof   : if (!(sof_sr_content[4] == 1'b0 && eof_sr_content[4] == 1'b1))
                              control_fsm_state <= `pass_rof;    // Output remaining data in frame
                              else
                              control_fsm_state <= `wait_sf;     // Frame ended, wait for next frame
                 default    : control_fsm_state <= `wait_sf;

            endcase
        end
   end // control_fsm_sync_p

   //--------------------------------------------------------------------------
   //Process control_fsm_comb_p
   //Determines control signals from control_fsm state
   //--------------------------------------------------------------------------
   always @(control_fsm_state)
   begin
   case (control_fsm_state)
         `wait_sf    : begin
                       sel_delay_path = 1'b0;  // output data from data shift register
                       enable_data_sr = 1'b1;  // enable data to be loaded into shift register
                       end
         `bypass_sa1 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `bypass_sa2 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `bypass_sa3 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `bypass_sa4 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `bypass_sa5 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `bypass_sa6 : begin
                       sel_delay_path = 1'b1;  // output data directly from input
                       enable_data_sr = 1'b0;  // hold current data in shift register
                       end
         `pass_rof   : begin
                       sel_delay_path = 1'b0;  // output data from data shift register
                       enable_data_sr = 1'b1;  // enable data to be loaded into shift register
                       end
          default    : begin
                       sel_delay_path = 1'b0;
                       enable_data_sr = 1'b1;
                       end
      endcase
   end // control_fsm_comb_p

endmodule
