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
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : axi_basic_rx_null_gen.v
// Version    : 1.1
//----------------------------------------------------------------------------//
//  File: axi_basic_rx_null_gen.v                                             //
//                                                                            //
//  Description:                                                              //
//  TRN to AXI RX null generator. Detects discontinued packets from PCIe      //
//  block and drives null packet to user design instead.                      //
//                                                                            //
//  Notes:                                                                    //
//  Optional notes section.                                                   //
//                                                                            //
//  Hierarchical:                                                             //
//    axi_basic_top                                                           //
//      axi_basic_rx                                                          //
//        axi_basic_rx_null_gen                                               //
//                                                                            //
//----------------------------------------------------------------------------//

`timescale 1ps/1ps

module axi_basic_rx_null_gen # (
  parameter C_DATA_WIDTH = 32,            // RX/TX interface data width
  parameter TCQ = 1,                      // Clock to Q time

  // Do not override parameters below this line
  parameter REM_WIDTH  = (C_DATA_WIDTH == 128) ? 2 : 1, // trem/rrem width
  parameter STRB_WIDTH = C_DATA_WIDTH / 8               // TSTRB width
  ) (

  // TRN RX
  //-----------
  input      [C_DATA_WIDTH-1:0] trn_rd,              // RX data from block
  input                         trn_rsof,            // RX start of packet
  input                         trn_reof,            // RX end of packet
  input                         trn_rsrc_rdy,        // RX source ready
  input                         trn_rdst_rdy,        // RX destination ready
  input                         trn_rsrc_dsc,        // RX source discontinue
  input         [REM_WIDTH-1:0] trn_rrem,            // RX remainder
  input                         m_axis_rx_tready,    // RX ready for data

  // Null Inputs
  //-----------
  output                        null_rx_tvalid,      // NULL generated tvalid
  output                        null_rx_tlast,       // NULL generated tlast
  output       [STRB_WIDTH-1:0] null_rx_tstrb,       // NULL generated tstrb
  output                        null_rdst_rdy,       // NULL generated rdst_rdy
  output                  [4:0] null_is_eof,         // NULL generated is_eof
  input                         null_mux_sel,

  // System
  //-----------
  input                         user_clk,            // user clock from block
  input                         user_rst             // user reset from block
);


localparam INTERFACE_WIDTH_DWORDS = (C_DATA_WIDTH == 128) ? 11'd4 :
                                           (C_DATA_WIDTH == 64) ? 11'd2 : 11'd1;

//----------------------------------------------------------------------------//
// NULL packet gnereator state machine                                        //
// This state machine shadows the TRN RX interface, tracking each packet as   //
// it's passed to the AXI user. When a disountine is detected, the rx data    //
// pipeline switches to a NULL packet and clocks that out instead. It does so //
// by asserting null_mux_sel, which the rx pipeline uses to mux in NULL vals. //
//----------------------------------------------------------------------------//

// State machine variables and states
localparam            IDLE      = 0;
localparam            IN_PACKET = 1;
localparam            PAD       = 2;
reg             [1:0] cur_state;
reg             [1:0] next_state;

// Calculate packet fields, which are needed to determine total packet length.
reg            [11:0] reg_pkt_len_counter;
reg            [11:0] pkt_len_counter;
wire           [11:0] new_pkt_len;
wire            [9:0] payload_len;
wire            [1:0] packet_fmt;
wire                  packet_td;
reg             [3:0] packet_overhead;

// Misc.
wire [STRB_WIDTH-1:0] eof_tstrb;


//----------------------------------------------------------------------------//
// Calculate the length of the packet being presented on the RX interface. To //
// do so, we need the relevent packet fields that impact total packet length. //
// These are:                                                                 //
//   - Header length: obtained from bit 1 of FMT field in 1st DWORD of header //
//   - Payload length: obtained from LENGTH field in 1st DWORD of header      //
//   - TLP digist: obtained from TD field in 1st DWORD of header              //
//   - Current data: the number of bytes that have already been presented     //
//                   on the data interface                                    //
//                                                                            //
// packet length = header + payload + tlp digest - # of DWORDS already        //
//                 transmitted                                                //
//                                                                            //
// packet_overhead is where we calculate everything except payload.           //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : len_calc_128
    assign packet_fmt  = trn_rrem[1] ? trn_rd[126:125] : trn_rd[62:61];
    assign packet_td   = trn_rrem[1] ? trn_rd[111] : trn_rd[47];
    assign payload_len = packet_fmt[1] ?
                        (trn_rrem[1] ? trn_rd[105:96] : trn_rd[41:32]) : 10'h0;

    always @(*) begin
      // In 128-bit mode, the amount of data currently on the interface
      // depends on whether we're straddling or not. If so, 2 DWORDs have been
      // seen. If not, 4 DWORDs.
      case({packet_fmt[0], packet_td, trn_rrem[1]})
        //                        Header +  TD  - Data currently on interface
        3'b0_0_0: packet_overhead = 4'd3 + 4'd0 - 4'd2;
        3'b0_0_1: packet_overhead = 4'd3 + 4'd0 - 4'd4;
        3'b0_1_0: packet_overhead = 4'd3 + 4'd1 - 4'd2;
        3'b0_1_1: packet_overhead = 4'd3 + 4'd1 - 4'd4;
        3'b1_0_0: packet_overhead = 4'd4 + 4'd0 - 4'd2;
        3'b1_0_1: packet_overhead = 4'd4 + 4'd0 - 4'd4;
        3'b1_1_0: packet_overhead = 4'd4 + 4'd1 - 4'd2;
        3'b1_1_1: packet_overhead = 4'd4 + 4'd1 - 4'd4;
      endcase
    end
  end
  else if(C_DATA_WIDTH == 64) begin : len_calc_64
    assign packet_fmt  = trn_rd[62:61];
    assign packet_td   = trn_rd[47];
    assign payload_len = packet_fmt[1] ? trn_rd[41:32] : 10'h0;

    always @(*) begin
      // 64-bit mode: no straddling, so always 2 DWORDs
      case({packet_fmt[0], packet_td})
        //                      Header +  TD  - Data currently on interface
        2'b0_0: packet_overhead = 4'd3 + 4'd0 - 4'd2;
        2'b0_1: packet_overhead = 4'd3 + 4'd1 - 4'd2;
        2'b1_0: packet_overhead = 4'd4 + 4'd0 - 4'd2;
        2'b1_1: packet_overhead = 4'd4 + 4'd1 - 4'd2;
      endcase
    end
  end
  else begin : len_calc_32
    assign packet_fmt  = trn_rd[30:29];
    assign packet_td   = trn_rd[15];
    assign payload_len = packet_fmt[1] ? trn_rd[9:0] : 10'h0;

    always @(*) begin
      // 32-bit mode: no straddling, so always 1 DWORD
      case({packet_fmt[0], packet_td})
        //                      Header +  TD  - Data currently on interface
        2'b0_0: packet_overhead = 4'd3 + 4'd0 - 4'd1;
        2'b0_1: packet_overhead = 4'd3 + 4'd1 - 4'd1;
        2'b1_0: packet_overhead = 4'd4 + 4'd0 - 4'd1;
        2'b1_1: packet_overhead = 4'd4 + 4'd1 - 4'd1;
      endcase
    end
  end
endgenerate

// Now calculate actual packet length, adding the packet overhead and the
// payload length. This is signed math, so sign-extend packet_overhead.
// NOTE: a payload length of zero means 1024 DW in the PCIe spec, but this
//       behavior isn't supported in our block.
assign new_pkt_len =
         {{9{packet_overhead[3]}}, packet_overhead[2:0]} + {1'b0, payload_len};


//----------------------------------------------------------------------------//
// Null generator Mealy state machine. Determine outputs based on:            //
//   1) current st                                                            //
//   2) current inp                                                           //
//----------------------------------------------------------------------------//
always @(*) begin
  case (cur_state)

    // IDLE state: the interface is IDLE and we're waiting for a packet to
    // start. If a packet starts, move to state IN_PACKET and begin tracking
    // it as long as it's NOT:
    //   1) a single cycle packet (indicated by simultaneous sof and eof)
    //   2) a sof discontinued packet (we'll squash the sof in this case)
    IDLE: begin
      if(trn_rsof && !trn_reof && !trn_rsrc_dsc && trn_rsrc_rdy && trn_rdst_rdy)
      begin
        next_state = IN_PACKET;
      end
      else begin
        next_state = IDLE;
      end

      pkt_len_counter = new_pkt_len;
    end

    // IN_PACKET: a packet is in progress and we're tracking it. We are
    // in lock-step with the TRN interface decrementing our packet length
    // tracking reg, and waiting for the packet to finish.
    //
    // * If packet finished and a new one starts, this is a straddle situation.
    //   Next state is IN_PACKET (128-bit only).
    // * If the current packet is done, next state is IDLE.
    // * If a discontinue is detected, next state is PAD.
    // * Otherwise, next state is IN_PACKET.
    IN_PACKET: begin
      // Straddle packet
      if((C_DATA_WIDTH == 128) && trn_rsof && trn_rdst_rdy) begin
        if(trn_rsrc_dsc) begin
          next_state = IDLE;
        end
        else begin
          next_state = IN_PACKET;
        end

        pkt_len_counter = new_pkt_len;
      end

      // Current packet finished
      else if(trn_rdst_rdy && (reg_pkt_len_counter <= INTERFACE_WIDTH_DWORDS))
      begin
        pkt_len_counter = new_pkt_len;
        next_state      = IDLE;
      end

      // Packet discontinued
      else if(trn_rsrc_dsc && !trn_reof) begin
        pkt_len_counter = reg_pkt_len_counter;
        next_state      = PAD;
      end

      // Packet in progress
      else begin
        if(trn_rdst_rdy) begin
          // Not throttled
          pkt_len_counter = reg_pkt_len_counter - INTERFACE_WIDTH_DWORDS;
        end
        else begin
          // Throttled
          pkt_len_counter = reg_pkt_len_counter;
        end

        next_state = IN_PACKET;
      end
    end

    // PAD: the current packet has been discontinued, and now a null packet is
    // being clocked out to the user design. We have switched over and are now
    // in lockstep with with the AXI interface. We should only provide data to
    // the user when null_mux_sel is asserted, indicating the pipeline stage has
    // switched over to the null generated data.
    //
    // * If the packet is done, next state is IDLE.
    // * Otherwise, next state is PAD.
    PAD: begin
      // Current packet finished
      if(null_mux_sel && (reg_pkt_len_counter <= INTERFACE_WIDTH_DWORDS))
      begin
        pkt_len_counter = new_pkt_len;
        next_state      = IDLE;
      end

      // Packet in progress
      else begin
        // Not throttled
        if(null_mux_sel && m_axis_rx_tready) begin
          pkt_len_counter = reg_pkt_len_counter - INTERFACE_WIDTH_DWORDS;
        end

        // Throttled
        else begin
          pkt_len_counter = reg_pkt_len_counter;
        end

        next_state = PAD;
      end
    end

    default: begin
      pkt_len_counter = reg_pkt_len_counter;
      next_state      = IDLE;
    end
  endcase
end


// Synchronous NULL packet generator state machine logic
always @(posedge user_clk) begin
  if(user_rst) begin
    cur_state           <= #TCQ IDLE;
    reg_pkt_len_counter <= #TCQ 11'h0;
  end
  else begin
    cur_state           <= #TCQ next_state;
    reg_pkt_len_counter <= #TCQ pkt_len_counter;
  end
end


// Generate TSTRB/is_eof for an end-of-packet situation.
generate
  if(C_DATA_WIDTH == 128) begin : strb_calc_128
    reg [4:0] reg_is_eof;
    always @(*) begin
      // Assign null_is_eof depending on how many DWORDs are left in the
      // packet.
      case(reg_pkt_len_counter)
        10'd1:   reg_is_eof = 5'b10011;
        10'd2:   reg_is_eof = 5'b10111;
        10'd3:   reg_is_eof = 5'b11011;
        10'd4:   reg_is_eof = 5'b11111;
        default: reg_is_eof = 5'b00011;
      endcase
    end
    assign null_is_eof = reg_is_eof;

    // TSTRB not used in 128-bit interface
    assign eof_tstrb = {STRB_WIDTH{1'b0}};
  end
  else if(C_DATA_WIDTH == 64) begin : strb_calc_64
    // is_eof not used in 64-bit interface
    assign null_is_eof = 5'b00011;

    // Assign TSTRB to 0xFF or 0x0F depending on how many DWORDs are left in
    // the current packet.
    assign eof_tstrb = { ((reg_pkt_len_counter == 2) ? 4'hF:4'h0), 4'hF };
  end
  else begin : strb_calc_32
    // is_eof not used in 32-bit interface
    assign null_is_eof = 5'b00011;

    // The entire DWORD is always valid in 32-bit mode, so TSTRB is always 0xF
    assign eof_tstrb = 4'hF;
  end
endgenerate


// Finally, use everything we've generated to calculate our NULL outputs
assign null_rx_tvalid = 1'b1;
assign null_rx_tlast  = (reg_pkt_len_counter <= INTERFACE_WIDTH_DWORDS);
assign null_rx_tstrb  = null_rx_tlast ? eof_tstrb : {STRB_WIDTH{1'b1}};
assign null_rdst_rdy  = null_rx_tlast;

endmodule
