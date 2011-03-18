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
// File       : axi_basic_rx_pipeline.v
// Version    : 1.1
//----------------------------------------------------------------------------//
//  File: axi_basic_rx_pipeline.v                                             //
//                                                                            //
//  Description:                                                              //
//  TRN to AXI RX pipeline. Converts received data from TRN protocol to AXI.  //
//                                                                            //
//  Notes:                                                                    //
//  Optional notes section.                                                   //
//                                                                            //
//  Hierarchical:                                                             //
//    axi_basic_top                                                           //
//      axi_basic_rx                                                          //
//        axi_basic_rx_pipeline                                               //
//                                                                            //
//----------------------------------------------------------------------------//

`timescale 1ps/1ps

module axi_basic_rx_pipeline #(
  parameter C_DATA_WIDTH = 32,            // RX/TX interface data width
  parameter C_FAMILY = "X7",              // Targeted FPGA family
  parameter TCQ = 1,                      // Clock to Q time

  // Do not override parameters below this line
  parameter REM_WIDTH  = (C_DATA_WIDTH == 128) ? 2 : 1, // trem/rrem width
  parameter RBAR_WIDTH = (C_FAMILY == "X7") ? 8 : 7,    // trn_rbar_hit width
  parameter STRB_WIDTH = C_DATA_WIDTH / 8               // TSTRB width
  ) (

  // AXI RX
  //-----------
  output reg [C_DATA_WIDTH-1:0] m_axis_rx_tdata,     // RX data to user
  output reg                    m_axis_rx_tvalid,    // RX data is valid
  input                         m_axis_rx_tready,    // RX ready for data
  output       [STRB_WIDTH-1:0] m_axis_rx_tstrb,     // RX strobe byte enables
  output                        m_axis_rx_tlast,     // RX data is last
  output reg             [21:0] m_axis_rx_tuser,     // RX user signals

  // TRN RX
  //-----------
  input      [C_DATA_WIDTH-1:0] trn_rd,              // RX data from block
  input                         trn_rsof,            // RX start of packet
  input                         trn_reof,            // RX end of packet
  input                         trn_rsrc_rdy,        // RX source ready
  output reg                    trn_rdst_rdy,        // RX destination ready
  input                         trn_rsrc_dsc,        // RX source discontinue
  input         [REM_WIDTH-1:0] trn_rrem,            // RX remainder
  input                         trn_rerrfwd,         // RX error forward
  input        [RBAR_WIDTH-1:0] trn_rbar_hit,        // RX BAR hit
  input                         trn_recrc_err,       // RX ECRC error

  // Null Inputs
  //-----------
  input                         null_rx_tvalid,      // NULL generated tvalid
  input                         null_rx_tlast,       // NULL generated tlast
  input        [STRB_WIDTH-1:0] null_rx_tstrb,       // NULL generated tstrb
  input                         null_rdst_rdy,       // NULL generated rdst_rdy
  input                   [4:0] null_is_eof,         // NULL generated is_eof
  output reg                    null_mux_sel,

  // System
  //-----------
  output                  [2:0] np_counter,          // Non-posted counter
  input                         user_clk,            // user clock from block
  input                         user_rst             // user reset from block
);

// Wires and regs for creating AXI signals
wire              [4:0] is_sof;
wire              [4:0] is_sof_prev;

wire              [4:0] is_eof;
wire              [4:0] is_eof_prev;

reg    [STRB_WIDTH-1:0] reg_tstrb;
wire   [STRB_WIDTH-1:0] tstrb;
wire   [STRB_WIDTH-1:0] tstrb_prev;

reg                     reg_tlast;

// Wires and regs for previous value buffer
wire [C_DATA_WIDTH-1:0] trn_rd_DW_swapped;
reg  [C_DATA_WIDTH-1:0] trn_rd_prev;

wire                    data_hold;
reg                     data_prev;

reg                     trn_reof_prev;
reg     [REM_WIDTH-1:0] trn_rrem_prev;
reg                     trn_rsrc_rdy_prev;
reg                     trn_rsrc_dsc_prev;
reg                     trn_rsof_prev;
reg               [7:0] trn_rbar_hit_prev;
reg                     trn_rerrfwd_prev;
reg                     trn_recrc_err_prev;
reg                     trn_rsrc_dsc_d;
reg                     trn_in_packet;
reg                     trn_in_packet_prev;

wire                    dsc_detect;
wire                    dsc_detect_prev;
reg                     dsc_pending;
reg                     dsc_dropped;
reg                     stall_trn;

// Create constant-width rbar_hit wire regardless of target architecture
wire              [7:0] trn_rbar_hit_full;
generate
  if(RBAR_WIDTH == 7) begin : rbar_width_7
    assign trn_rbar_hit_full = {1'b0, trn_rbar_hit};
  end
  else begin : rbar_width_8
    assign trn_rbar_hit_full = trn_rbar_hit;
  end
endgenerate


//----------------------------------------------------------------------------//
// Previous value buffer                                                      //
// ---------------------                                                      //
// We are inserting a pipeline stage in between TRN and AXI, which causes     //
// some issues with handshaking signals m_axis_rx_tready/trn_rdst_rdy. The    //
// added cycle of latency in the path causes the user design to fall behind   //
// the TRN interface whenever it throttles.                                   //
//                                                                            //
// To avoid loss of data, we must keep the previous value of all trn_r*       //
// signals in case the user throttles.                                        //
//----------------------------------------------------------------------------//
always @(posedge user_clk) begin
  if(user_rst) begin
    trn_rd_prev        <= #TCQ {C_DATA_WIDTH{1'b0}};
    trn_rsof_prev      <= #TCQ 1'b0;
    trn_reof_prev      <= #TCQ 1'b0;
    trn_rrem_prev      <= #TCQ {REM_WIDTH{1'b0}};
    trn_rsrc_rdy_prev  <= #TCQ 1'b0;
    trn_rbar_hit_prev  <= #TCQ 8'h00;
    trn_rerrfwd_prev   <= #TCQ 1'b0;
    trn_recrc_err_prev <= #TCQ 1'b0;
    trn_in_packet_prev <= #TCQ 1'b0;

    trn_rsrc_dsc_prev <= #TCQ 1'b0;
 end
  else begin
    // prev buffer works by checking trn_rdst_rdy. When trn_rdst_rdy is
    // asserted, a new value is present on the interface.
    if(trn_rdst_rdy) begin
      trn_rd_prev        <= #TCQ trn_rd_DW_swapped;
      trn_rsof_prev      <= #TCQ trn_rsof;
      trn_reof_prev      <= #TCQ trn_reof;
      trn_rrem_prev      <= #TCQ trn_rrem;
      trn_rsrc_rdy_prev  <= #TCQ trn_rsrc_rdy;
      trn_rbar_hit_prev  <= #TCQ trn_rbar_hit_full;
      trn_rerrfwd_prev   <= #TCQ trn_rerrfwd;
      trn_recrc_err_prev <= #TCQ trn_recrc_err;
      trn_in_packet_prev <= #TCQ trn_in_packet;
    end

    // Create discontinue previous value buffer. We use the same approach as the
    // other TRN signals above, except we need to handle a special situation
    // where trn_rsrc_dsc is cleared before it gets clocked into the RX
    // pipeline. See dsc_dropped for more details.
    if(trn_rdst_rdy) begin
      trn_rsrc_dsc_prev <= #TCQ trn_rsrc_dsc;
    end
    else if(dsc_dropped) begin
      trn_rsrc_dsc_prev <= #TCQ 1'b1;
    end
  end
end


//----------------------------------------------------------------------------//
// Create TDATA                                                               //
//----------------------------------------------------------------------------//

// Convert TRN data format to AXI data format. AXI is DWORD swapped from TRN
// 128-bit:                 64-bit:                  32-bit:
// TRN DW0 maps to AXI DW3  TRN DW0 maps to AXI DW1  TNR DW0 maps to AXI DW0
// TRN DW1 maps to AXI DW2  TRN DW1 maps to AXI DW0
// TRN DW2 maps to AXI DW1
// TRN DW3 maps to AXI DW0
generate
  if(C_DATA_WIDTH == 128) begin : rd_DW_swap_128
    assign trn_rd_DW_swapped = {trn_rd[31:0],
                                trn_rd[63:32],
                                trn_rd[95:64],
                                trn_rd[127:96]};
  end
  else if(C_DATA_WIDTH == 64) begin : rd_DW_swap_64
    assign trn_rd_DW_swapped = {trn_rd[31:0], trn_rd[63:32]};
  end
  else begin : rd_DW_swap_32
    assign trn_rd_DW_swapped = trn_rd;
  end
endgenerate


// Create special buffer which locks in the propper value of TDATA depending
// on whether the user is throttling or not. This buffer has three states:
//
//       HOLD state: TDATA maintains its current value
//                   - the user has throttled the PCIe block
//   PREVIOUS state: the buffer provides the previous value on trn_rd
//                   - the user has finished throttling, and is a little behind
//                     the PCIe block
//    CURRENT state: the buffer passes the current value on trn_rd
//                   - the user is caught up and ready to receive the latest
//                     data from the PCIe block
always @(posedge user_clk) begin
  if(user_rst) begin
    m_axis_rx_tdata <= #TCQ {C_DATA_WIDTH{1'b0}};
  end
  else begin
    if(!data_hold) begin
      // PREVIOUS state
      if(data_prev) begin
        m_axis_rx_tdata <= #TCQ trn_rd_prev;
      end

      // CURRENT state
      else begin
        m_axis_rx_tdata <= #TCQ trn_rd_DW_swapped;
      end
    end
    // else HOLD state
  end
end

// Logic to instruct pipeline to hold its value
assign data_hold = (!m_axis_rx_tready && m_axis_rx_tvalid && !null_mux_sel);

// Logic to instruct pipeline to use previous bus values. Always use previous
// value after holding a value.
always @(posedge user_clk) begin
  if(user_rst) begin
    data_prev <= #TCQ 1'b0;
  end
  else begin
    data_prev <= #TCQ data_hold;
  end
end


//----------------------------------------------------------------------------//
// Create TVALID, TLAST, TSTRB, TUSER                                         //
// -----------------------------------                                        //
// Use the same strategy for these signals as for TDATA, except here we need  //
// an extra provision for null packets.                                       //
//----------------------------------------------------------------------------//
always @(posedge user_clk) begin
  if(user_rst) begin
    m_axis_rx_tvalid <= #TCQ 1'b0;
    reg_tlast        <= #TCQ 1'b0;
    reg_tstrb        <= #TCQ {STRB_WIDTH{1'b1}};
    m_axis_rx_tuser  <= #TCQ 22'h0;
  end
  else begin
    // If in a null packet, use null generated value
    if(null_mux_sel) begin
      m_axis_rx_tvalid <= #TCQ null_rx_tvalid;
      reg_tlast        <= #TCQ null_rx_tlast;
      reg_tstrb        <= #TCQ null_rx_tstrb;
      m_axis_rx_tuser  <= #TCQ {null_is_eof, 17'h0000};
    end

    else if(!data_hold) begin
      // PREVIOUS state
      if(data_prev) begin
        m_axis_rx_tvalid <= #TCQ trn_rsrc_rdy_prev ||
                                      (trn_rsrc_dsc_prev && trn_in_packet_prev);
        reg_tlast        <= #TCQ trn_reof_prev;
        reg_tstrb        <= #TCQ tstrb_prev;
        m_axis_rx_tuser  <= #TCQ {is_eof_prev,          // TUSER bits [21:17]
                                  2'b00,                // TUSER bits [16:15]
                                  is_sof_prev,          // TUSER bits [14:10]
                                  trn_rbar_hit_prev,    // TUSER bits [9:2]
                                  trn_rerrfwd_prev,     // TUSER bit  [1]
                                  trn_recrc_err_prev};  // TUSER bit  [0]
      end

      // CURRENT state
      else begin
        m_axis_rx_tvalid <= #TCQ trn_rsrc_rdy ||
                                                (trn_rsrc_dsc && trn_in_packet);
        reg_tlast        <= #TCQ trn_reof;
        reg_tstrb        <= #TCQ tstrb;
        m_axis_rx_tuser  <= #TCQ {is_eof,               // TUSER bits [21:17]
                                  2'b00,                // TUSER bits [16:15]
                                  is_sof,               // TUSER bits [14:10]
                                  trn_rbar_hit_full,    // TUSER bits [9:2]
                                  trn_rerrfwd,          // TUSER bit  [1]
                                  trn_recrc_err};       // TUSER bit  [0]
      end
    end
    // else HOLD state
  end
end

// Hook up TLAST and TSTRB depending on interface width
generate
  // For 128-bit interface, don't pass TLAST and TSTRB to user (is_eof and
  // is_data passed to user instead). reg_tlast is still used internally.
  if(C_DATA_WIDTH == 128) begin : tlast_tstrb_hookup_128
    assign m_axis_rx_tlast = 1'b0;
    assign m_axis_rx_tstrb = {STRB_WIDTH{1'b1}};
  end

  // For 64/32-bit interface, pass TLAST to user.
  else begin : tlast_tstrb_hookup_64_32
    assign m_axis_rx_tlast = reg_tlast;
    assign m_axis_rx_tstrb = reg_tstrb;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create TSTRB                                                               //
// ------------                                                               //
// Convert RREM to STRB. Here, we are converting the encoding method for the  //
// location of the EOF from TRN flavor (rrem) to AXI (TSTRB).                 //
//                                                                            //
// NOTE: for each configuration, we need two values of TSTRB, the current and //
//       previous values. The need for these two values is described below.   //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : rrem_to_tstrb_128
    // TLAST and TSTRB not used in 128-bit interface. is_sof and is_eof used
    // instead.
    assign tstrb      = 16'h0000;
    assign tstrb_prev = 16'h0000;
  end
  else if(C_DATA_WIDTH == 64) begin : rrem_to_tstrb_64
    // 64-bit interface: contains 2 DWORDs per cycle, for a total of 8 bytes
    //  - TSTRB has only two possible values here, 0xFF or 0x0F
    assign tstrb      = trn_rrem      ? 8'hFF : 8'h0F;
    assign tstrb_prev = trn_rrem_prev ? 8'hFF : 8'h0F;
  end
  else begin : rrem_to_tstrb_32
    // 32-bit interface: contains 1 DWORD per cycle, for a total of 4 bytes
    //  - TSTRB is always 0xF in this case, due to the nature of the PCIe block
    assign tstrb      = 4'hF;
    assign tstrb_prev = 4'hF;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create is_sof                                                              //
// -------------                                                              //
// is_sof is a signal to the user indicating the location of SOF in TDATA   . //
// Due to inherent 64-bit alignment of packets from the block, the only       //
// possible values are: 5'b11000 (sof @ byte 8)                               //
//                      5'b10000 (sof @ byte 0)                               //
//                      5'b00000 (sof not present)                            //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : is_sof_128
    assign is_sof      = {(trn_rsof && !trn_rsrc_dsc), // bit 4:   enable
                          (trn_rsof && !trn_rrem[1]),  // bit 3:   sof @ byte 8?
                          3'b000};                     // bit 2-0: hardwired 0

    assign is_sof_prev = {(trn_rsof_prev && !trn_rsrc_dsc_prev), // bit 4
                          (trn_rsof_prev && !trn_rrem_prev[1]),  // bit 3
                          3'b000};                               // bit 2-00
  end
  else begin : is_sof_64_32
    assign is_sof      = 5'b00000;
    assign is_sof_prev = 5'b00000;
  end
endgenerate


//----------------------------------------------------------------------------//
// Create is_eof                                                              //
// -------------                                                              //
// is_eof is a signal to the user indicating the location of EOF in TDATA   . //
// Due to DWORD granularity of packets from the block, the only               //
// possible values are: 5'b11111 (eof @ byte 15)                              //
//                      5'b11011 (eof @ byte 11)                              //
//                      5'b10111 (eof @ byte 7)                               //
//                      5'b10011 (eof @ byte 3)`                              //
//                      5'b00011 (eof not present)                            //
//----------------------------------------------------------------------------//
generate
  if(C_DATA_WIDTH == 128) begin : is_eof_128
    assign is_eof      = {trn_reof,      // bit 4:   enable
                          trn_rrem,      // bit 3-2: encoded eof loc from block
                          2'b11};        // bit 1-0: hardwired 1

    assign is_eof_prev = {trn_reof_prev, // bit 4:   enable
                          trn_rrem_prev, // bit 3-2: encoded eof loc from block
                          2'b11};        // bit 1-0: hardwired 1
  end
  else begin : is_eof_64_32
    assign is_eof      = 5'b00011;
    assign is_eof_prev = 5'b00011;
  end
endgenerate



//----------------------------------------------------------------------------//
// Create trn_rdst_rdy                                                        //
//----------------------------------------------------------------------------//
always @(posedge user_clk) begin
  if(user_rst) begin
    trn_rdst_rdy <= #TCQ 1'b0;
  end
  else begin
    //  - If in a null packet, use null generated value
    if(null_mux_sel) begin
      trn_rdst_rdy <= #TCQ null_rdst_rdy;
    end

    else if(stall_trn) begin
      trn_rdst_rdy <= #TCQ 1'b0;
    end

    //  - If in a packet, pass user back-pressure directly to block
    else if(m_axis_rx_tvalid) begin
      trn_rdst_rdy <= #TCQ m_axis_rx_tready;
    end

    //  - If idle, default to no back-pressure. We need to default to the
    //    "ready to accept data" state to make sure we catch the first
    //    clock of data of a new packet.
    else begin
      trn_rdst_rdy <= #TCQ 1'b1;
    end
  end
end


//----------------------------------------------------------------------------//
// Create null_mux_sel                                                        //
// null_mux_sel is the signal used to detect a discontinue situation and      //
// mux in the null packet generated in rx_null_gen. This signal then feeds    //
// back into the null packet generator, to instruct the null gen state        //
// that null packet data is being consumed.                                   //
//----------------------------------------------------------------------------//
always @(posedge user_clk) begin
  if(user_rst) begin
    null_mux_sel <= #TCQ 1'b0;
  end
  else begin

    // Wait to mux in NULL data until pipeline is caught up
    if(!null_mux_sel && data_hold) begin
      null_mux_sel <= #TCQ 1'b0;
    end

    // NULL packet done
    else if(null_mux_sel && null_rx_tlast) begin
      null_mux_sel <= #TCQ 1'b0;
    end

    // Discontinue detected on current data, switch to NULL packet
    else if(dsc_detect) begin
      null_mux_sel <= #TCQ 1'b1;
    end

    // Discontinue detected on previous data, switch to NULL packet
    else if(dsc_detect_prev)
    begin
      null_mux_sel <= #TCQ 1'b1;
    end
  end
end

// Create signal trn_in_packet, which is needed to validate trn_rsrc_dsc. We
// should ignore trn_rsrc_dsc when it's asserted out-of-packet.
always @(posedge user_clk) begin
  if(user_rst) begin
    trn_in_packet <= #TCQ 1'b0;
  end
  else begin
    if(!trn_in_packet && trn_rsof && !trn_reof && trn_rsrc_rdy && trn_rdst_rdy)
    begin
      trn_in_packet <= 1'b1;
    end
    else if(trn_in_packet && trn_reof && !trn_rsof && trn_rsrc_rdy &&
                                                             trn_rdst_rdy) begin
      trn_in_packet <= 1'b0;
    end
  end
end

// Create discontinue detect signals. We need to start muxing in data when the
// following conditions are met:
// 1) trn_rsrc_dsc is asserted
// 2) trn_rsof is deasserted (we'll squash discontinued SOFs outright instead of
//    clocking out a null packet)
// 3) trn_reof is deasserted (If an EOF is discontinued, there's nothing we need
//    to do)
//
// Make two signals: one for "current" mode and one for "previous" mode.
assign dsc_detect      = !data_prev && trn_rsrc_dsc && trn_in_packet
                                                                   && !trn_reof;
assign dsc_detect_prev = data_prev && trn_rsrc_dsc_prev && trn_in_packet_prev
                                                              && !trn_reof_prev;

// Look for a dropped dsc. The core asserts trn_rsrc_dsc when the link goes
// down, and deasserts it when the link goes up. This is irrespective of
// trn_rdst_rdy. As such, dsc could assert and deassert before it ever gets
// sucked into the pipeline, and we could loose the data beat that's pending
// on the interface when this circumstance occurs.
always @(posedge user_clk) begin
  if(user_rst) begin
    trn_rsrc_dsc_d <= #TCQ 1'b0;
    dsc_pending    <= #TCQ 1'b0;
    dsc_dropped    <= #TCQ 1'b0;
 end
  else begin
    // A discontinue has been stalled. Start looking for a possible dropped dsc
    if(trn_rsrc_dsc && !trn_rsrc_dsc_d && trn_in_packet && !trn_rdst_rdy) begin
      dsc_pending <= #TCQ 1'b1;
    end

    // Discontinue drop detected
    else if(dsc_pending && !trn_rsrc_dsc && !trn_rdst_rdy) begin
      dsc_pending <= #TCQ 1'b0;
      dsc_dropped <= #TCQ 1'b1;
    end

    // Discontinue consumed, so no drop detected
    else if(trn_rdst_rdy) begin
      dsc_pending <= #TCQ 1'b0;
      dsc_dropped <= #TCQ 1'b0;
    end

    trn_rsrc_dsc_d <= #TCQ trn_rsrc_dsc;
  end
end

// In the event of a dropped discontinue, we need to stall the TRN interface for
// one cycle to make up for the dropped data beat.
always @(posedge user_clk) begin
  if(user_rst) begin
    stall_trn <= #TCQ 1'b0;
 end
  else begin
    // If a discontinue was dropped, stall TRN on the next data beat
    if(dsc_dropped) begin
      stall_trn <= #TCQ 1'b1;
    end

    // When we see TVALID asserted, we've stalled the TRN for one data beat
    else if(m_axis_rx_tvalid) begin
      stall_trn <= #TCQ 1'b0;
    end
  end
end


//----------------------------------------------------------------------------//
// Create np_counter (V6 128-bit only). This counter tells the V6 128-bit     //
// interface core how many NP packets have left the RX pipeline. The V6       //
// 128-bit interface uses this count to perform rnp_ok modulation.            //
//----------------------------------------------------------------------------//
generate
  if(C_FAMILY == "V6" && C_DATA_WIDTH == 128) begin : np_cntr_to_128_enabled
    reg [2:0] reg_np_counter;

    // Look for NP packets beginning on lower (i.e. unaligned) start
    wire mrd_lower      = (!(|m_axis_rx_tdata[92:88]) && !m_axis_rx_tdata[94]);
    wire mrd_lk_lower   = (m_axis_rx_tdata[92:88] == 5'b00001);
    wire io_rdwr_lower  = (m_axis_rx_tdata[92:88] == 5'b00010);
    wire cfg_rdwr_lower = (m_axis_rx_tdata[92:89] == 4'b0010);
    wire atomic_lower   = ((&m_axis_rx_tdata[91:90]) && m_axis_rx_tdata[94]);

    wire np_pkt_lower = (mrd_lower      ||
                         mrd_lk_lower   ||
                         io_rdwr_lower  ||
                         cfg_rdwr_lower ||
                         atomic_lower) && m_axis_rx_tuser[13];

    // Look for NP packets beginning on upper (i.e. aligned) start
    wire mrd_upper      = (!(|m_axis_rx_tdata[28:24]) && !m_axis_rx_tdata[30]);
    wire mrd_lk_upper   = (m_axis_rx_tdata[28:24] == 5'b00001);
    wire io_rdwr_upper  = (m_axis_rx_tdata[28:24] == 5'b00010);
    wire cfg_rdwr_upper = (m_axis_rx_tdata[28:25] == 4'b0010);
    wire atomic_upper   = ((&m_axis_rx_tdata[27:26]) && m_axis_rx_tdata[30]);

    wire np_pkt_upper = (mrd_upper      ||
                         mrd_lk_upper   ||
                         io_rdwr_upper  ||
                         cfg_rdwr_upper ||
                         atomic_upper) && !m_axis_rx_tuser[13];

    wire pkt_accepted =
                    m_axis_rx_tuser[14] && m_axis_rx_tready && m_axis_rx_tvalid;

    // Increment counter whenever an NP packet leaves the RX pipeline
    always @(posedge user_clk)  begin
      if (user_rst) begin
        reg_np_counter <= #TCQ 0;
      end
      else begin
        if((np_pkt_lower || np_pkt_upper) && pkt_accepted)
        begin
          reg_np_counter <= #TCQ reg_np_counter + 3'h1;
        end
      end
    end

    assign np_counter = reg_np_counter;
  end
  else begin : np_cntr_to_128_disabled
    assign np_counter = 3'h0;
  end
endgenerate

endmodule
