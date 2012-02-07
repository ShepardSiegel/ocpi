//------------------------------------------------------------------------------
// Title      : Transmitter FIFO with AxiStream interfaces
// Version    : 1.3
// Project    : Tri-Mode Ethernet MAC
//------------------------------------------------------------------------------
// File       : tx_client_fifo.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------
// (c) Copyright 2004-2008 Xilinx, Inc. All rights reserved.
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
// -----------------------------------------------------------------------------
// Description: This is a transmitter side FIFO for the design example
//              of the Tri-Mode Ethernet MAC core. AxiStream interfaces are used.
//
//              The FIFO is created from 2 Block RAMs of size 2048
//              words of 8-bits per word, giving a total frame memory capacity
//              of 4096 bytes.
//
//              Valid frame data received from the user interface is written
//              into the Block RAM on the tx_fifo_aclkk. The FIFO will store
//              frames up to 4kbytes in length. If larger frames are written
//              to the FIFO, the AxiStream interface will accept the rest of the
//              frame, but that frame will be dropped by the FIFO and the
//              overflow signal will be asserted.
//
//              The FIFO is designed to work with a minimum frame length of 14
//              bytes.
//
//              When there is at least one complete frame in the FIFO, the MAC
//              transmitter AxiStream interface will be driven to request frame
//              transmission by placing the first byte of the frame onto
//              tx_axis_mac_tdata and by asserting tx_axis_mac_tvalid. The MAC will later
//              respond by asserting tx_axis_mac_tready. At this point the remaining
//              frame data is read out of the FIFO subject to tx_axis_mac_tready.
//              Data is read out of the FIFO on the tx_mac_aclk.
//
//              If the generic FULL_DUPLEX_ONLY is set to false, the FIFO will
//              requeue and retransmit frames as requested by the MAC. Once a
//              frame has been transmitted by the FIFO it is stored until the
//              possible retransmit window for that frame has expired.
//
//              The FIFO has been designed to operate with different clocks
//              on the write and read sides. The write clock (user-side
//              AxiStream clock) can be an equal or faster frequency than the
//              read clock (MAC-side AxiStream clock). The minimum write clock
//              frequency is the read clock frequency divided by 2.
//
//              The FIFO memory size can be increased by expanding the rd_addr
//              and wr_addr signal widths, to address further BRAMs.
//
//------------------------------------------------------------------------------

`timescale 1ps / 1ps

//------------------------------------------------------------------------------
// The module declaration for the Transmitter FIFO
//------------------------------------------------------------------------------

module tx_client_fifo #
  (
    parameter FULL_DUPLEX_ONLY = 0
  )

  (
    // User-side (write-side) AxiStream interface
    input            tx_fifo_aclk,
    input            tx_fifo_resetn,
    input      [7:0] tx_axis_fifo_tdata,
    input            tx_axis_fifo_tvalid,
    input            tx_axis_fifo_tlast,
    output           tx_axis_fifo_tready,

    // MAC-side (read-side) AxiStream interface
    input            tx_mac_aclk,
    input            tx_mac_resetn,
    output     [7:0] tx_axis_mac_tdata,
    output reg       tx_axis_mac_tvalid,
    output reg       tx_axis_mac_tlast,
    input            tx_axis_mac_tready,
    output reg       tx_axis_mac_tuser,

    // FIFO status and overflow indication,
    // synchronous to write-side (tx_user_aclk) interface
    output           fifo_overflow,
    output     [3:0] fifo_status,

    // FIFO collision and retransmission requests from MAC
    input            tx_collision,
    input            tx_retransmit
  );


  //----------------------------------------------------------------------------
  // Define internal signals
  //----------------------------------------------------------------------------

  wire        GND;
  wire        VCC;
  wire [8:0]  GND_BUS;

  // Binary encoded read state machine states.
  parameter  IDLE_s             = 4'b0000;
  parameter  QUEUE1_s           = 4'b0001;
  parameter  QUEUE2_s           = 4'b0010;
  parameter  QUEUE3_s           = 4'b0011;
  parameter  START_DATA1_s      = 4'b0100;
  parameter  DATA_PRELOAD1_s    = 4'b0101;
  parameter  DATA_PRELOAD2_s    = 4'b0110;
  parameter  WAIT_HANDSHAKE_s   = 4'b0111;
  parameter  FRAME_s            = 4'b1000;
  parameter  HANDSHAKE_s        = 4'b1001;
  parameter  FINISH_s           = 4'b1010;
  parameter  DROP_ERR_s         = 4'b1011;
  parameter  DROP_s             = 4'b1100;
  parameter  RETRANSMIT_ERR_s   = 4'b1101;
  parameter  RETRANSMIT_s       = 4'b1111;

  reg  [3:0]  rd_state;
  reg  [3:0]  rd_nxt_state;

  // Binary encoded write state machine states.
  parameter WAIT_s   = 2'b00;
  parameter DATA_s   = 2'b01;
  parameter EOF_s    = 2'b10;
  parameter OVFLOW_s = 2'b11;

  reg  [1:0]  wr_state;
  reg  [1:0]  wr_nxt_state;

  wire [8:0]  wr_eof_data_bram;
  reg  [7:0]  wr_data_bram;
  reg  [7:0]  wr_data_pipe[0:1];
  reg         wr_sof_pipe[0:1];
  reg         wr_eof_pipe[0:1];
  reg         wr_accept_pipe[0:1];
  reg         wr_accept_bram;
  wire        wr_sof_int;
  reg  [0:0]  wr_eof_bram;
  reg         wr_eof_reg;
  reg  [11:0] wr_addr;
  wire        wr_addr_inc;
  wire        wr_start_addr_load;
  wire        wr_addr_reload;
  reg  [11:0] wr_start_addr;
  reg         wr_fifo_full;
  wire        wr_en;
  wire        wr_en_u;
  wire [0:0]  wr_en_u_bram;
  wire        wr_en_l;
  wire [0:0]  wr_en_l_bram;
  reg         wr_ovflow_dst_rdy;
  wire        tx_axis_fifo_tready_int_n;

  wire        frame_in_fifo;
  reg         rd_eof;
  reg         rd_eof_reg;
  reg         rd_eof_pipe;
  reg  [11:0] rd_addr;
  wire        rd_addr_inc;
  wire        rd_addr_reload;
  wire [8:0]  rd_bram_u_unused;
  wire [8:0]  rd_bram_l_unused;
  wire [8:0]  rd_eof_data_bram_u;
  wire [8:0]  rd_eof_data_bram_l;
  wire [7:0]  rd_data_bram_u;
  wire [7:0]  rd_data_bram_l;
  reg  [7:0]  rd_data_pipe_u;
  reg  [7:0]  rd_data_pipe_l;
  reg  [7:0]  rd_data_pipe;
  wire [0:0]  rd_eof_bram_u;
  wire [0:0]  rd_eof_bram_l;
  wire        rd_en;
  reg         rd_bram_u;
  reg         rd_bram_u_reg;

  (* INIT = "0" *)
  reg         rd_tran_frame_tog = 1'b0;
  wire        wr_tran_frame_sync;

  (* INIT = "0" *)
  reg         wr_tran_frame_delay = 1'b0;

  (* INIT = "0" *)
  reg         rd_retran_frame_tog = 1'b0;
  wire        wr_retran_frame_sync;

  (* INIT = "0" *)
  reg         wr_retran_frame_delay = 1'b0;
  wire        wr_store_frame;
  reg         wr_transmit_frame;
  reg         wr_retransmit_frame;
  reg  [8:0]  wr_frames;
  reg         wr_frame_in_fifo;

  reg   [3:0] rd_16_count;
  wire        rd_txfer_en;
  reg  [11:0] rd_addr_txfer;

  (* INIT = "0" *)
  reg         rd_txfer_tog = 1'b0;
  wire        wr_txfer_tog_sync;

  (* INIT = "0" *)
  reg         wr_txfer_tog_delay = 1'b0;
  wire        wr_txfer_en;

  (* ASYNC_REG = "TRUE" *)
  reg  [11:0] wr_rd_addr;

  reg  [11:0] wr_addr_diff;

  reg  [3:0]  wr_fifo_status;

  reg         rd_drop_frame;
  reg         rd_retransmit;

  reg  [11:0] rd_start_addr;
  wire        rd_start_addr_load;
  wire        rd_start_addr_reload;

  reg  [11:0] rd_dec_addr;

  wire        rd_transmit_frame;
  wire        rd_retransmit_frame;
  reg         rd_col_window_expire;
  reg         rd_col_window_pipe[0:1];

  (* ASYNC_REG = "TRUE" *)
  reg         wr_col_window_pipe[0:1];

  wire        wr_eof_state;
  reg         wr_eof_state_reg;
  wire        wr_fifo_overflow;
  reg  [9:0]  rd_slot_timer;
  reg         wr_col_window_expire;
  wire        rd_idle_state;

  wire [7:0]  tx_axis_mac_tdata_int_frame;
  wire [7:0]  tx_axis_mac_tdata_int_handshake;
  reg  [7:0]  tx_axis_mac_tdata_int;
  wire        tx_axis_mac_tvalid_int_finish;
  wire        tx_axis_mac_tvalid_int_droperr;
  wire        tx_axis_mac_tvalid_int_retransmiterr;
  wire        tx_axis_mac_tlast_int_frame_handshake;
  wire        tx_axis_mac_tlast_int_finish;
  wire        tx_axis_mac_tlast_int_droperr;
  wire        tx_axis_mac_tlast_int_retransmiterr;
  wire        tx_axis_mac_tuser_int_droperr;
  wire        tx_axis_mac_tuser_int_retransmit;

  wire        tx_fifo_reset;
  wire        tx_mac_reset;

  // invert reset sense as architecture is optimised for active high resets
  assign tx_fifo_reset = !tx_fifo_resetn;
  assign tx_mac_reset  = !tx_mac_resetn;

  //----------------------------------------------------------------------------
  // Begin FIFO architecture
  //----------------------------------------------------------------------------

  assign GND = 1'b0;
  assign VCC = 1'b1;
  assign GND_BUS = 9'b0;


  //----------------------------------------------------------------------------
  // Write state machine and control
  //----------------------------------------------------------------------------

  // Write state machine.
  // States are WAIT, DATA, EOF, OVFLOW.
  // Clock state to next state.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
         wr_state <= WAIT_s;
     end
     else begin
         wr_state <= wr_nxt_state;
     end
  end

  // Decode next state, combinatorial.
  always @(wr_state, wr_sof_pipe[1], wr_eof_pipe[0], wr_eof_pipe[1],
           wr_eof_bram[0], wr_fifo_overflow)
  begin
  case (wr_state)
     WAIT_s : begin
        if (wr_sof_pipe[1] == 1'b1 && wr_eof_pipe[1] == 1'b0) begin
           wr_nxt_state <= DATA_s;
        end
        else begin
           wr_nxt_state <= WAIT_s;
        end
     end

     DATA_s : begin
        // Wait for the end of frame to be detected.
        if (wr_fifo_overflow == 1'b1 && wr_eof_pipe[0] == 1'b0
            && wr_eof_pipe[1] == 1'b0) begin
           wr_nxt_state <= OVFLOW_s;
        end
        else if (wr_eof_pipe[1] == 1'b1) begin
           wr_nxt_state <= EOF_s;
        end
        else begin
           wr_nxt_state <= DATA_s;
        end
     end

     EOF_s : begin
        // If the start of frame is already in the pipe, a back-to-back frame
        // transmission has occured. Move straight back to frame state.
        if (wr_sof_pipe[1] == 1'b1 && wr_eof_pipe[1] == 1'b0) begin
           wr_nxt_state <= DATA_s;
        end
        else if (wr_eof_bram[0] == 1'b1) begin
           wr_nxt_state <= WAIT_s;
        end
        else begin
           wr_nxt_state <= EOF_s;
        end
     end

     OVFLOW_s : begin
        // Wait until the end of frame is reached before clearing the overflow.
        if (wr_eof_bram[0] == 1'b1) begin
           wr_nxt_state <= WAIT_s;
        end
        else begin
           wr_nxt_state <= OVFLOW_s;
        end
     end

     default : begin
        wr_nxt_state <= WAIT_s;
     end

  endcase
  end

  // Decode output signals.
  // wr_en is used to enable the BRAM write and the address to increment.
  assign wr_en = (wr_state == OVFLOW_s) ? 1'b0 : wr_accept_bram;

  // The upper and lower signals are used to distinguish between the upper and
  // lower BRAMs.
  assign wr_en_l = wr_en & !wr_addr[11];
  assign wr_en_u = wr_en &  wr_addr[11];
  assign wr_en_l_bram[0] = wr_en_l;
  assign wr_en_u_bram[0] = wr_en_u;

  assign wr_addr_inc = wr_en;

  assign wr_addr_reload = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;
  assign wr_start_addr_load = (wr_state == EOF_s && wr_nxt_state == WAIT_s)
                              ? 1'b1 :
                              (wr_state == EOF_s && wr_nxt_state == DATA_s)
                              ? 1'b1 : 1'b0;

  // Pause the AxiStream handshake when the FIFO is full.
  assign tx_axis_fifo_tready_int_n = (wr_state == OVFLOW_s) ?
                                wr_ovflow_dst_rdy : wr_fifo_full;

  assign tx_axis_fifo_tready = !tx_axis_fifo_tready_int_n;

  // Generate user overflow indicator.
  assign fifo_overflow = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;

  // When in overflow and have captured ovflow EOF, set tx_axis_fifo_tready again.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_ovflow_dst_rdy <= 1'b0;
     end
     else begin
        if (wr_fifo_overflow == 1'b1 && wr_state == DATA_s) begin
            wr_ovflow_dst_rdy <= 1'b0;
        end
        else if (tx_axis_fifo_tvalid == 1'b1 && tx_axis_fifo_tlast == 1'b1) begin
            wr_ovflow_dst_rdy <= 1'b1;
        end
     end
  end

  // EOF signals for use in overflow logic.
  assign wr_eof_state = (wr_state == EOF_s) ? 1'b1 : 1'b0;

  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_eof_state_reg <= 1'b0;
     end
     else begin
        wr_eof_state_reg <= wr_eof_state;
     end
  end


  //----------------------------------------------------------------------------
  // Read state machine and control
  //----------------------------------------------------------------------------

  // Read state machine.
  // States are IDLE, QUEUE1, QUEUE2, QUEUE3, QUEUE_ACK, WAIT_ACK, FRAME,
  // HANDSHAKE, FINISH, DROP_ERR, DROP, RETRANSMIT_ERR, RETRANSMIT.
  // Clock state to next state.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_state <= IDLE_s;
     end
     else begin
        rd_state <= rd_nxt_state;
     end
  end

  //----------------------------------------------------------------------------
  // Full duplex-only state machine.
generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_sm
  // Decode next state, combinatorial.
  always @(rd_state, frame_in_fifo, rd_eof, rd_eof_reg, tx_axis_mac_tready)
  begin
  case (rd_state)
           IDLE_s : begin
              // If there is a frame in the FIFO, start to queue the new frame
              // to the output.
              if (frame_in_fifo == 1'b1) begin
                 rd_nxt_state <= QUEUE1_s;
              end
              else begin
                 rd_nxt_state <= IDLE_s;
              end
           end

           // Load the output pipeline, which takes three clock cycles.
           QUEUE1_s : begin
              rd_nxt_state <= QUEUE2_s;
           end

           QUEUE2_s : begin
              rd_nxt_state <= QUEUE3_s;
           end

           QUEUE3_s : begin
              rd_nxt_state <= START_DATA1_s;
           end

           START_DATA1_s : begin
              // The pipeline is full and the frame output starts now.
              rd_nxt_state <= DATA_PRELOAD1_s;
           end

           DATA_PRELOAD1_s : begin
              // Await the tx_axis_mac_tready acknowledge before moving on.
              if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= FRAME_s;
              end
              else begin
                 rd_nxt_state <= DATA_PRELOAD1_s;
              end
           end

           FRAME_s : begin
              // Read the frame out of the FIFO. If the MAC deasserts
              // tx_axis_mac_tready, stall in the handshake state. If the EOF
              // flag is encountered, move to the finish state.
              if (tx_axis_mac_tready == 1'b0)
              begin
                 rd_nxt_state <= HANDSHAKE_s;
              end
              else if (rd_eof == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else begin
                 rd_nxt_state <= FRAME_s;
              end
           end

           HANDSHAKE_s : begin
              // Await tx_axis_mac_tready before continuing frame transmission.
              // If the EOF flag is encountered, move to the finish state.
              if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b0) begin
                 rd_nxt_state <= FRAME_s;
              end
              else begin
                 rd_nxt_state <= HANDSHAKE_s;
              end
           end

           FINISH_s : begin
              // Frame has finished. Assure that the MAC has accepted the final
              // byte by transitioning to idle only when tx_axis_mac_tready is high.
              if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= IDLE_s;
              end
              else begin
                 rd_nxt_state <= FINISH_s;
              end
           end

           default : begin
              rd_nxt_state <= IDLE_s;
           end
        endcase
  end

end
endgenerate

  //----------------------------------------------------------------------------
  // Full and half duplex state machine.
generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_sm
  // Decode the next state, combinatorial.
  always @(rd_state, frame_in_fifo, rd_eof_reg, tx_axis_mac_tready, rd_drop_frame,
           rd_retransmit)
  begin
  case (rd_state)
           IDLE_s : begin
              // If a retransmit request is detected then prepare to retransmit.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              // If there is a frame in the FIFO, then queue the new frame to
              // the output.
              else if (frame_in_fifo == 1'b1) begin
                 rd_nxt_state <= QUEUE1_s;
              end
              else begin
                 rd_nxt_state <= IDLE_s;
              end
           end

           // Load the output pipeline, which takes three clock cycles.
           QUEUE1_s : begin
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else begin
                rd_nxt_state <= QUEUE2_s;
              end
           end

           QUEUE2_s : begin
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else begin
                 rd_nxt_state <= QUEUE3_s;
              end
           end

           QUEUE3_s : begin
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else begin
                 rd_nxt_state <= START_DATA1_s;
              end
           end

           START_DATA1_s : begin
              // The pipeline is full and the frame output starts now.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else begin
                 rd_nxt_state <= DATA_PRELOAD1_s;
              end
           end

           DATA_PRELOAD1_s : begin
              // Await the tx_axis_mac_tready acknowledge before moving on.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= DATA_PRELOAD2_s;
              end
              else begin
                 rd_nxt_state <= DATA_PRELOAD1_s;
              end
           end

           DATA_PRELOAD2_s : begin
              // If a collision-only request, then must drop the rest of the
              // current frame. If collision and retransmit, then prepare
              // to retransmit the frame.
              if (rd_drop_frame == 1'b1) begin
                 rd_nxt_state <= DROP_ERR_s;
              end
              else if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              // Read the frame out of the FIFO. If the MAC deasserts
              // tx_axis_mac_tready, stall in the handshake state. If the EOF
              // flag is encountered, move to the finish state.
              else if (tx_axis_mac_tready == 1'b0) begin
                 rd_nxt_state <= WAIT_HANDSHAKE_s;
              end
              else if (rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else begin
                 rd_nxt_state <= DATA_PRELOAD2_s;
              end
           end

           WAIT_HANDSHAKE_s : begin
              // Await tx_axis_mac_tready before continuing frame transmission.
              // If the EOF flag is encountered, move to the finish state.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b0) begin
                 rd_nxt_state <= FRAME_s;
              end
              else begin
                 rd_nxt_state <= WAIT_HANDSHAKE_s;
              end
           end

           FRAME_s : begin
              // If a collision-only request, then must drop the rest of the
              // current frame. If collision and retransmit, then prepare
              // to retransmit the frame.
              if (rd_drop_frame == 1'b1) begin
                 rd_nxt_state <= DROP_ERR_s;
              end
              else if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              // Read the frame out of the FIFO. If the MAC deasserts
              // tx_axis_mac_tready, stall in the handshake state. If the EOF
              // flag is encountered, move to the finish state.
              else if (tx_axis_mac_tready == 1'b0) begin
                 rd_nxt_state <= HANDSHAKE_s;
              end
              else if (rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else begin
                 rd_nxt_state <= FRAME_s;
              end
           end

           HANDSHAKE_s : begin
              // Await tx_axis_mac_tready before continuing frame transmission.
              // If the EOF flag is encountered, move to the finish state.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              else if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= FINISH_s;
              end
              else if (tx_axis_mac_tready == 1'b1 && rd_eof_reg == 1'b0) begin
                 rd_nxt_state <= FRAME_s;
              end
              else begin
                 rd_nxt_state <= HANDSHAKE_s;
              end
           end

           FINISH_s : begin
              // Frame has finished. Assure that the MAC has accepted the final
              // byte by transitioning to idle only when tx_axis_mac_tready is high.
              if (rd_retransmit == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
              if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= IDLE_s;
              end
              else begin
                 rd_nxt_state <= FINISH_s;
              end
           end

           DROP_ERR_s : begin
              // FIFO is ready to drop the frame. Assure that the MAC has
              // accepted the final byte and err signal before dropping.
              if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= DROP_s;
              end
              else begin
                 rd_nxt_state <= DROP_ERR_s;
              end
           end

           DROP_s : begin
              // Wait until rest of frame has been cleared.
              if (rd_eof_reg == 1'b1) begin
                 rd_nxt_state <= IDLE_s;
              end
              else begin
                 rd_nxt_state <= DROP_s;
              end
           end

           RETRANSMIT_ERR_s : begin
              // FIFO is ready to retransmit the frame. Assure that the MAC has
              // accepted the final byte and err signal before retransmitting.
              if (tx_axis_mac_tready == 1'b1) begin
                 rd_nxt_state <= RETRANSMIT_s;
              end
              else begin
                 rd_nxt_state <= RETRANSMIT_ERR_s;
              end
           end

           RETRANSMIT_s : begin
              // Reload the data pipeline from the start of the frame.
              rd_nxt_state <= QUEUE1_s;
           end

           default : begin
              rd_nxt_state <= IDLE_s;
           end
        endcase
  end

end
endgenerate

  // Combinatorially select tdata candidates.
  assign tx_axis_mac_tdata_int_frame = (rd_nxt_state == HANDSHAKE_s || rd_nxt_state == WAIT_HANDSHAKE_s) ?
                                      tx_axis_mac_tdata_int : rd_data_pipe;
  assign tx_axis_mac_tdata_int_handshake = (rd_nxt_state == FINISH_s)    ?
                                      rd_data_pipe : tx_axis_mac_tdata_int;
  assign tx_axis_mac_tdata          = tx_axis_mac_tdata_int;

  // Decode output tdata based on current and next read state.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_nxt_state == FRAME_s || rd_nxt_state == DATA_PRELOAD2_s)
        tx_axis_mac_tdata_int <= rd_data_pipe;
     else if (rd_nxt_state == RETRANSMIT_ERR_s || rd_nxt_state == DROP_ERR_s)
        tx_axis_mac_tdata_int <= tx_axis_mac_tdata_int;
     else begin
        case (rd_state)
           START_DATA1_s :
              tx_axis_mac_tdata_int <= rd_data_pipe;
           FRAME_s, DATA_PRELOAD2_s :
              tx_axis_mac_tdata_int <= tx_axis_mac_tdata_int_frame;
           HANDSHAKE_s, WAIT_HANDSHAKE_s:
              tx_axis_mac_tdata_int <= tx_axis_mac_tdata_int_handshake;
           default :
              tx_axis_mac_tdata_int <= tx_axis_mac_tdata_int;
        endcase
     end
  end

  // Combinatorially select tvalid candidates.
  assign tx_axis_mac_tvalid_int_finish     = (rd_nxt_state == IDLE_s)       ?
                                             1'b0 : 1'b1;
  assign tx_axis_mac_tvalid_int_droperr  = (rd_nxt_state == DROP_s)       ?
                                             1'b0 : 1'b1;
  assign tx_axis_mac_tvalid_int_retransmiterr = (rd_nxt_state == RETRANSMIT_s) ?
                                             1'b0 : 1'b1;

  // Decode output tvalid based on current and next read state.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_nxt_state == FRAME_s || rd_nxt_state == DATA_PRELOAD2_s)
        tx_axis_mac_tvalid <= 1'b1;
     else if (rd_nxt_state == RETRANSMIT_ERR_s || rd_nxt_state == DROP_ERR_s)
        tx_axis_mac_tvalid <= 1'b1;
     else
     begin
        case (rd_state)
           START_DATA1_s :
              tx_axis_mac_tvalid <= 1'b1;
           DATA_PRELOAD1_s :
              tx_axis_mac_tvalid <= 1'b1;
           FRAME_s, DATA_PRELOAD2_s :
              tx_axis_mac_tvalid <= 1'b1;
           HANDSHAKE_s, WAIT_HANDSHAKE_s :
              tx_axis_mac_tvalid <= 1'b1;
           FINISH_s :
              tx_axis_mac_tvalid <= tx_axis_mac_tvalid_int_finish;
           DROP_ERR_s :
              tx_axis_mac_tvalid <= tx_axis_mac_tvalid_int_droperr;
           RETRANSMIT_ERR_s :
              tx_axis_mac_tvalid <= tx_axis_mac_tvalid_int_retransmiterr;
           default :
              tx_axis_mac_tvalid <= 1'b0;
        endcase
     end
  end

  // Combinatorially select tlast candidates.
  assign tx_axis_mac_tlast_int_frame_handshake = (rd_nxt_state == FINISH_s)     ?
                                            rd_eof_reg : 1'b0;
  assign tx_axis_mac_tlast_int_finish     = (rd_nxt_state == IDLE_s)       ?
                                            1'b0 : rd_eof_reg;
  assign tx_axis_mac_tlast_int_droperr  = (rd_nxt_state == DROP_s)       ?
                                            1'b0 : 1'b1;
  assign tx_axis_mac_tlast_int_retransmiterr = (rd_nxt_state == RETRANSMIT_s) ?
                                            1'b0 : 1'b1;

  // Decode output tlast based on current and next read state.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_nxt_state == FRAME_s || rd_nxt_state == DATA_PRELOAD2_s)
        tx_axis_mac_tlast <= rd_eof;
     else if (rd_nxt_state == RETRANSMIT_ERR_s || rd_nxt_state == DROP_ERR_s)
        tx_axis_mac_tlast <= 1'b1;
     else
     begin
        case (rd_state)
           DATA_PRELOAD1_s :
              tx_axis_mac_tlast <= rd_eof;
           FRAME_s, DATA_PRELOAD2_s :
              tx_axis_mac_tlast <= tx_axis_mac_tlast_int_frame_handshake;
           HANDSHAKE_s, WAIT_HANDSHAKE_s :
              tx_axis_mac_tlast <= tx_axis_mac_tlast_int_frame_handshake;
           FINISH_s :
              tx_axis_mac_tlast <= tx_axis_mac_tlast_int_finish;
           DROP_ERR_s :
              tx_axis_mac_tlast <= tx_axis_mac_tlast_int_droperr;
           RETRANSMIT_ERR_s :
              tx_axis_mac_tlast <= tx_axis_mac_tlast_int_retransmiterr;
           default :
              tx_axis_mac_tlast <= 1'b0;
        endcase
     end
  end

  // Combinatorially select tuser candidates.
  assign tx_axis_mac_tuser_int_droperr = (rd_nxt_state == DROP_s)       ?
                                       1'b0 : 1'b1;
  assign tx_axis_mac_tuser_int_retransmit = (rd_nxt_state == RETRANSMIT_s) ?
                                       1'b0 : 1'b1;

  // Decode output tuser based on current and next read state.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_nxt_state == RETRANSMIT_ERR_s || rd_nxt_state == DROP_ERR_s)
        tx_axis_mac_tuser <= 1'b1;
     else
     begin
        case (rd_state)
           DROP_ERR_s :
              tx_axis_mac_tuser <= tx_axis_mac_tuser_int_droperr;
           RETRANSMIT_ERR_s :
              tx_axis_mac_tuser <= tx_axis_mac_tuser_int_retransmit;
           default :
              tx_axis_mac_tuser <= 1'b0;
        endcase
     end
  end

  //----------------------------------------------------------------------------
  // Decode full duplex-only control signals.
generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_decode

  // rd_en is used to enable the BRAM read and load the output pipeline.
  assign rd_en = (rd_state == IDLE_s) ? 1'b0 :
                 (rd_nxt_state == FRAME_s) ? 1'b1 :
                 (rd_state == FRAME_s && rd_nxt_state == HANDSHAKE_s) ? 1'b0 :
                 (rd_nxt_state == HANDSHAKE_s) ? 1'b0 :
                 (rd_state == FINISH_s) ? 1'b0 :
                 (rd_state == DATA_PRELOAD1_s) ? 1'b0 : 1'b1;

  // When the BRAM is being read, enable the read address to be incremented.
  assign rd_addr_inc = rd_en;

  assign rd_addr_reload = (rd_state != FINISH_s && rd_nxt_state == FINISH_s)
                          ? 1'b1 : 1'b0;

  // Transmit frame pulse must never be more frequent than once per 64 clocks to
  // allow toggle to cross clock domain.
  assign rd_transmit_frame = (rd_state == DATA_PRELOAD1_s && rd_nxt_state == FRAME_s)
                             ? 1'b1 : 1'b0;

  // Unused for full duplex only.
  assign rd_start_addr_reload = 1'b0;
  assign rd_start_addr_load   = 1'b0;
  assign rd_retransmit_frame  = 1'b0;

end
endgenerate

  //----------------------------------------------------------------------------
  // Decode full and half duplex control signals.
generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_decode

  // rd_en is used to enable the BRAM read and load the output pipeline.
  assign rd_en = (rd_state == IDLE_s) ? 1'b0 :
                 (rd_nxt_state == DROP_ERR_s) ? 1'b0 :
                 (rd_nxt_state == DROP_s && rd_eof == 1'b1) ? 1'b0 :
                 (rd_nxt_state == FRAME_s || rd_nxt_state == DATA_PRELOAD2_s) ? 1'b1 :
                 (rd_state == DATA_PRELOAD2_s && rd_nxt_state == WAIT_HANDSHAKE_s) ? 1'b0 :
                 (rd_state == FRAME_s && rd_nxt_state == HANDSHAKE_s) ? 1'b0 :
                 (rd_nxt_state == HANDSHAKE_s || rd_nxt_state == WAIT_HANDSHAKE_s) ? 1'b0 :
                 (rd_state == FINISH_s) ? 1'b0 :
                 (rd_state == RETRANSMIT_ERR_s) ? 1'b0 :
                 (rd_state == RETRANSMIT_s) ? 1'b0 :
                 (rd_state == DATA_PRELOAD1_s) ? 1'b0 : 1'b1;

  // When the BRAM is being read, enable the read address to be incremented.
  assign rd_addr_inc = rd_en;

  assign rd_addr_reload = (rd_state != FINISH_s && rd_nxt_state == FINISH_s)
                          ? 1'b1 :
                          (rd_state == DROP_s && rd_nxt_state == IDLE_s)
                          ? 1'b1 : 1'b0;

  // Assertion indicates that the starting address must be reloaded to enable
  // the current frame to be retransmitted.
  assign rd_start_addr_reload = (rd_state == RETRANSMIT_s) ? 1'b1 : 1'b0;

  assign rd_start_addr_load = (rd_state== WAIT_HANDSHAKE_s && rd_nxt_state == FRAME_s)
                              ? 1'b1 :
                              (rd_col_window_expire == 1'b1) ? 1'b1 : 1'b0;

  // Transmit frame pulse must never be more frequent than once per 64 clocks to
  // allow toggle to cross clock domain.
  assign rd_transmit_frame = (rd_state == WAIT_HANDSHAKE_s && rd_nxt_state == FRAME_s)
                             ? 1'b1 : 1'b0;

  // Retransmit frame pulse must never be more frequent than once per 16 clocks
  // to allow toggle to cross clock domain.
  assign rd_retransmit_frame = (rd_state == RETRANSMIT_s) ? 1'b1 : 1'b0;

end
endgenerate


  //----------------------------------------------------------------------------
  // Frame count
  // We need to maintain a count of frames in the FIFO, so that we know when a
  // frame is available for transmission. The counter must be held on the write
  // clock domain as this is the faster clock if they differ.
  //----------------------------------------------------------------------------

  // A frame has been written to the FIFO.
  assign wr_store_frame = (wr_state == EOF_s && wr_nxt_state != EOF_s)
                          ? 1'b1 : 1'b0;

  // Generate a toggle to indicate when a frame has been transmitted by the FIFO.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_transmit_frame == 1'b1) begin
        rd_tran_frame_tog <= !rd_tran_frame_tog;
     end
  end

  // Synchronize the read transmit frame signal into the write clock domain.
  sync_block resync_rd_tran_frame_tog
  (
    .clk       (tx_fifo_aclk),
    .data_in   (rd_tran_frame_tog),
    .data_out  (wr_tran_frame_sync)
  );

  // Edge-detect of the resynchronized transmit frame signal.

  always @(posedge tx_fifo_aclk)
  begin
     wr_tran_frame_delay <= wr_tran_frame_sync;
  end

  always @(posedge tx_fifo_aclk)
  begin
      if (tx_fifo_reset == 1'b1) begin
         wr_transmit_frame   <= 1'b0;
      end
      else begin
         // Edge detector
         if ((wr_tran_frame_delay ^ wr_tran_frame_sync) == 1'b1) begin
           wr_transmit_frame <= 1'b1;
         end
         else begin
           wr_transmit_frame <= 1'b0;
         end
      end
  end

  //----------------------------------------------------------------------------
  // Full duplex-only frame count.
generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_count

  // Count the number of frames in the FIFO. The counter is incremented when a
  // frame is stored and decremented when a frame is transmitted. Need to keep
  // the counter on the write clock as this is the fastest clock if they differ.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_frames <= 9'b0;
     end
     else begin
        if ((wr_store_frame & !wr_transmit_frame) == 1'b1) begin
           wr_frames <= wr_frames + 9'b1;
        end
        else if ((!wr_store_frame & wr_transmit_frame) == 1'b1) begin
           wr_frames <= wr_frames - 9'b1;
        end
     end
  end

end
endgenerate

  //----------------------------------------------------------------------------
  // Full and half duplex frame count.
generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_count

  // Generate a toggle to indicate when a frame has been retransmitted by
  // the FIFO.
  always @(posedge tx_mac_aclk)
  begin  // process
     if (rd_retransmit_frame == 1'b1) begin
        rd_retran_frame_tog <= !rd_retran_frame_tog;
     end
  end

  // Synchronize the read retransmit frame signal into the write clock domain.
  sync_block resync_rd_tran_frame_tog
  (
    .clk       (tx_fifo_aclk),
    .data_in   (rd_retran_frame_tog),
    .data_out  (wr_retran_frame_sync)
  );

  // Edge detect of the resynchronized retransmit frame signal.

  always @(posedge tx_fifo_aclk)
  begin
     wr_retran_frame_delay <= wr_retran_frame_sync;
  end

  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_retransmit_frame    <= 1'b0;
     end
     else begin
        // Edge detector
        if ((wr_retran_frame_delay ^ wr_retran_frame_sync) == 1'b1) begin
           wr_retransmit_frame <= 1'b1;
        end
        else begin
           wr_retransmit_frame <= 1'b0;
        end
     end
  end

  // Count the number of frames in the FIFO. The counter is incremented when a
  // frame is stored or retransmitted and decremented when a frame is
  // transmitted. Need to keep the counter on the write clock as this is the
  // fastest clock if they differ. Logic assumes transmit and retransmit cannot
  // happen at same time.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_frames <= 9'd0;
     end
     else begin
        if ((wr_store_frame & wr_retransmit_frame) == 1'b1) begin
           wr_frames <= wr_frames + 9'd2;
        end
        else if (((wr_store_frame | wr_retransmit_frame)
                 & !wr_transmit_frame) == 1'b1) begin
           wr_frames <= wr_frames + 9'd1;
        end
        else if (wr_transmit_frame == 1'b1 & !wr_store_frame) begin
           wr_frames <= wr_frames - 9'd1;
        end
     end
  end

end
endgenerate

  // Generate a frame in FIFO signal for use in control logic.
  always @(posedge tx_fifo_aclk)
  begin
      if (tx_fifo_reset == 1'b1) begin
         wr_frame_in_fifo <= 1'b0;
      end
      else begin
         if (wr_frames != 9'b0) begin
            wr_frame_in_fifo <= 1'b1;
         end
         else begin
            wr_frame_in_fifo <= 1'b0;
         end
      end
  end

  // Synchronize it back onto read domain for use in the read logic.
  sync_block resync_wr_frame_in_fifo
  (
    .clk       (tx_mac_aclk),
    .data_in   (wr_frame_in_fifo),
    .data_out  (frame_in_fifo)
  );


  //----------------------------------------------------------------------------
  // Address counters
  //----------------------------------------------------------------------------

  // Write address is incremented when write enable signal has been asserted.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_addr <= 12'b0;
     end
     else if (wr_addr_reload == 1'b1) begin
        wr_addr <= wr_start_addr;
     end
     else if (wr_addr_inc == 1'b1) begin
        wr_addr <= wr_addr + 12'b1;
     end
  end

  // Store the start address in case the address must be reset.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_start_addr <= 12'b0;
     end
     else if (wr_start_addr_load == 1'b1) begin
        wr_start_addr <= wr_addr + 12'b1;
     end
  end

  //----------------------------------------------------------------------------
  // Half duplex-only read address counters.
generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_addr
  // Read address is incremented when read enable signal has been asserted.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_addr <= 12'b0;
     end
     else begin
        if (rd_addr_reload == 1'b1) begin
           rd_addr <= rd_dec_addr;
        end
        else if (rd_addr_inc == 1'b1) begin
           rd_addr <= rd_addr + 12'b1;
        end
     end
  end

  // Do not need to keep a start address, but the address is needed to
  // calculate FIFO occupancy.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_start_addr <= 12'b0;
     end
     else begin
        rd_start_addr <= rd_addr;
     end
  end

end
endgenerate

  //----------------------------------------------------------------------------
  // Full and half duplex read address counters.
generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_addr
  // Read address is incremented when read enable signal has been asserted.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_addr <= 12'b0;
     end
     else begin
        if (rd_addr_reload == 1'b1) begin
           rd_addr <= rd_dec_addr;
        end
        else if (rd_start_addr_reload == 1'b1) begin
           rd_addr <= rd_start_addr;
        end
        else if (rd_addr_inc == 1'b1) begin
           rd_addr <= rd_addr + 12'b1;
        end
     end
  end

  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_start_addr <= 12'd0;
     end
     else begin
        if (rd_start_addr_load == 1'b1) begin
           rd_start_addr <= rd_addr - 12'd6;
        end
     end
  end

  // Collision window expires after MAC has been transmitting for required slot
  // time. This is 512 clock cycles at 1Gbps. Also if the end of frame has fully
  // been transmitted by the MAC then a collision cannot occur. This collision
  // expiration signal goes high at 768 cycles from the start of the frame.
  // This is inefficient for short frames, however it should be enough to
  // prevent the FIFO from locking up.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_col_window_expire <= 1'b0;
     end
     else begin
        if (rd_transmit_frame == 1'b1) begin
           rd_col_window_expire <= 1'b0;
        end
        else if (rd_slot_timer[9:7] == 3'b110) begin
           rd_col_window_expire <= 1'b1;
        end
     end
  end

  assign rd_idle_state = (rd_state == IDLE_s) ? 1'b1 : 1'b0;

  always @(posedge tx_mac_aclk)
  begin
     rd_col_window_pipe[0] <= rd_col_window_expire & rd_idle_state;
     if (rd_txfer_en == 1'b1) begin
        rd_col_window_pipe[1] <= rd_col_window_pipe[0];
     end
  end

  always @(posedge tx_mac_aclk)
  begin
     // Will not count until after the first frame is sent.
     if (tx_mac_reset == 1'b1) begin
        rd_slot_timer <= 10'b1111111111;
     end
     else begin
        // Reset counter.
        if (rd_transmit_frame == 1'b1) begin
           rd_slot_timer <= 10'b0;
        end
        // Do not allow counter to roll over, and
        // only count when frame is being transmitted.
        else if (rd_slot_timer != 10'b1111111111) begin
           rd_slot_timer <= rd_slot_timer + 10'b1;
        end
     end
  end

end
endgenerate

  // Read address generation.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_dec_addr <= 12'b0;
     end
     else begin
        if (rd_addr_inc == 1'b1) begin
           rd_dec_addr <= rd_addr - 12'b1;
        end
     end
  end

  // Which BRAM is read from is dependant on the upper bit of the address
  // space. This needs to be registered to give the correct timing.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_bram_u <= 1'b0;
        rd_bram_u_reg <= 1'b0;
     end
     else begin
        if (rd_addr_inc == 1'b1) begin
           rd_bram_u <= rd_addr[11];
           rd_bram_u_reg <= rd_bram_u;
        end
     end
  end


  //----------------------------------------------------------------------------
  // Data pipelines
  //----------------------------------------------------------------------------

  // Register data inputs to BRAM.
  // No resets to allow for SRL16 target.
  always @(posedge tx_fifo_aclk)
  begin
     wr_data_pipe[0] <= tx_axis_fifo_tdata;
     if (wr_accept_pipe[0] == 1'b1) begin
        wr_data_pipe[1] <= wr_data_pipe[0];
     end
     if (wr_accept_pipe[1] == 1'b1) begin
        wr_data_bram    <= wr_data_pipe[1];
     end
  end

  // Start of frame set when tvalid is asserted and previous frame has ended.
  assign wr_sof_int = tx_axis_fifo_tvalid & wr_eof_reg;

  // Set end of frame flag when tlast and tvalid are asserted together.
  // Reset to logic 1 to enable first frame's start of frame flag.
  always @(posedge tx_fifo_aclk)
  begin
    if (tx_fifo_reset == 1'b1) begin
      wr_eof_reg <= 1'b1;
    end
    else begin
      if (tx_axis_fifo_tvalid == 1'b1 & tx_axis_fifo_tready_int_n == 1'b0) begin
        wr_eof_reg <= tx_axis_fifo_tlast;
      end
    end
  end

  // Pipeline the start of frame flag when the pipe is enabled.
  always @(posedge tx_fifo_aclk)
  begin
     wr_sof_pipe[0] <= wr_sof_int;
     if (wr_accept_pipe[0] == 1'b1) begin
        wr_sof_pipe[1] <= wr_sof_pipe[0];
     end
  end

  // Pipeline the pipeline enable signal, which is derived from simultaneous
  // assertion of tvalid and tready.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_accept_pipe[0] <= 1'b0;
        wr_accept_pipe[1] <= 1'b0;
        wr_accept_bram    <= 1'b0;
     end
     else begin
        wr_accept_pipe[0] <= tx_axis_fifo_tvalid & !tx_axis_fifo_tready_int_n;
        wr_accept_pipe[1] <= wr_accept_pipe[0];
        wr_accept_bram    <= wr_accept_pipe[1];
     end
  end

  // Pipeline the end of frame flag when the pipe is enabled.
  always @(posedge tx_fifo_aclk)
  begin
     wr_eof_pipe[0] <= tx_axis_fifo_tvalid & tx_axis_fifo_tlast;
     if (wr_accept_pipe[0] == 1'b1) begin
        wr_eof_pipe[1] <= wr_eof_pipe[0];
     end
     if (wr_accept_pipe[1] == 1'b1) begin
        wr_eof_bram[0] <= wr_eof_pipe[1];
     end
  end

  // Register data outputs from BRAM.
  // No resets to allow for SRL16 target.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_en == 1'b1) begin
        rd_data_pipe_u <= rd_data_bram_u;
        rd_data_pipe_l <= rd_data_bram_l;
        if (rd_bram_u_reg == 1'b1) begin
           rd_data_pipe <= rd_data_pipe_u;
        end
        else begin
           rd_data_pipe <= rd_data_pipe_l;
        end
     end
  end

  always @(posedge tx_mac_aclk)
  begin
     if (rd_en == 1'b1) begin
        if (rd_bram_u == 1'b1) begin
           rd_eof_pipe <= rd_eof_bram_u[0];
        end
        else begin
           rd_eof_pipe <= rd_eof_bram_l[0];
        end
        rd_eof <= rd_eof_pipe;
        rd_eof_reg <= rd_eof | rd_eof_pipe;
     end
  end

  //----------------------------------------------------------------------------
  // Half duplex-only drop and retransmission controls.
generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_input
  // Register the collision without retransmit signal, which is a pulse that
  // causes the FIFO to drop the frame.
  always @(posedge tx_mac_aclk)
  begin
     rd_drop_frame <= tx_collision & !tx_retransmit;
  end

  // Register the collision with retransmit signal, which is a pulse that
  // causes the FIFO to retransmit the frame.
  always @(posedge tx_mac_aclk)
  begin
     rd_retransmit <= tx_collision & tx_retransmit;
  end
end
endgenerate


  //----------------------------------------------------------------------------
  // FIFO full functionality
  //----------------------------------------------------------------------------

  // Full functionality is the difference between read and write addresses.
  // We cannot use gray code this time as the read address and read start
  // addresses jump by more than 1.
  // We generate an enable pulse for the read side every 16 read clocks. This
  // provides for the worst-case situation where the write clock is 20MHz and
  // read clock is 125MHz.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_16_count <= 4'b0;
     end
     else begin
        rd_16_count <= rd_16_count + 4'b1;
     end
  end

  assign rd_txfer_en = (rd_16_count == 4'b1111) ? 1'b1 : 1'b0;

  // Register the start address on the enable pulse.
  always @(posedge tx_mac_aclk)
  begin
     if (tx_mac_reset == 1'b1) begin
        rd_addr_txfer <= 12'b0;
     end
     else begin
        if (rd_txfer_en == 1'b1) begin
           rd_addr_txfer <= rd_start_addr;
        end
     end
  end

  // Generate a toggle to indicate that the address has been loaded.
  always @(posedge tx_mac_aclk)
  begin
     if (rd_txfer_en == 1'b1) begin
        rd_txfer_tog <= !rd_txfer_tog;
     end
  end

  // Synchronize the toggle to the write side.
  sync_block resync_rd_txfer_tog
  (
    .clk       (tx_fifo_aclk),
    .data_in   (rd_txfer_tog),
    .data_out  (wr_txfer_tog_sync)
  );

  // Delay the synchronized toggle by one cycle.
  always @(posedge tx_fifo_aclk)
  begin
     wr_txfer_tog_delay <= wr_txfer_tog_sync;
  end

  // Generate an enable pulse from the toggle. The address should have been
  // steady on the wr clock input for at least one clock.
  assign wr_txfer_en = wr_txfer_tog_delay ^ wr_txfer_tog_sync;

  // Capture the address on the write clock when the enable pulse is high.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_rd_addr <= 12'b0;
     end
     else if (wr_txfer_en == 1'b1) begin
        wr_rd_addr <= rd_addr_txfer;
     end
  end

  // Obtain the difference between write and read pointers.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_addr_diff <= 12'b0;
     end
     else begin
        wr_addr_diff <= wr_rd_addr - wr_addr;
     end
  end

  // Detect when the FIFO is full.
  // The FIFO is considered to be full if the write address pointer is
  // within 0 to 3 of the read address pointer.
  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_fifo_full <= 1'b0;
     end
     else begin
        if (wr_addr_diff[11:4] == 8'b0 && wr_addr_diff[3:2] != 2'b0) begin
           wr_fifo_full <= 1'b1;
        end
        else begin
           wr_fifo_full <= 1'b0;
        end
     end
  end

  // Memory overflow occurs when the FIFO is full and there are no frames
  // available in the FIFO for transmission. If the collision window has
  // expired and there are no frames in the FIFO and the FIFO is full, then the
  // FIFO is in an overflow state. We must accept the rest of the incoming
  // frame in overflow condition.

generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_ovflow
     // In full duplex mode, the FIFO memory can only overflow if the FIFO goes
     // full but there is no frame available to be retranmsitted. Therefore,
     // prevent signal from being asserted when store_frame signal is high, as
     // frame count is being updated.
     assign wr_fifo_overflow = (wr_fifo_full == 1'b1 && wr_frame_in_fifo == 1'b0
                                   && wr_eof_state == 1'b0
                                   && wr_eof_state_reg == 1'b0)
                                ? 1'b1 : 1'b0;
end
endgenerate

generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_ovflow
    // In half duplex mode, register write collision window to give address
    // counter sufficient time to update. This will prevent the signal from
    // being asserted when the store_frame signal is high, as the frame count
    // is being updated.
    assign wr_fifo_overflow = (wr_fifo_full == 1'b1 && wr_frame_in_fifo == 1'b0
                                  && wr_eof_state == 1'b0
                                  && wr_eof_state_reg == 1'b0
                                  && wr_col_window_expire == 1'b1)
                               ? 1'b1 : 1'b0;

    // Register rd_col_window signal.
    // This signal is long, and will remain high until overflow functionality
    // has finished, so save just to register once.
    always @(posedge tx_fifo_aclk)
    begin
       if (tx_fifo_reset == 1'b1) begin
          wr_col_window_pipe[0] <= 1'b0;
          wr_col_window_pipe[1] <= 1'b0;
          wr_col_window_expire  <= 1'b0;
       end
       else begin
          if (wr_txfer_en == 1'b1) begin
             wr_col_window_pipe[0] <= rd_col_window_pipe[1];
          end
          wr_col_window_pipe[1] <= wr_col_window_pipe[0];
          wr_col_window_expire <= wr_col_window_pipe[1];
       end
    end

end
endgenerate


  //----------------------------------------------------------------------------
  // FIFO status signals
  //----------------------------------------------------------------------------

  // The FIFO status is four bits which represents the occupancy of the FIFO
  // in sixteenths. To generate this signal we therefore only need to compare
  // the 4 most significant bits of the write address pointer with the 4 most
  // significant bits of the read address pointer.

  always @(posedge tx_fifo_aclk)
  begin
     if (tx_fifo_reset == 1'b1) begin
        wr_fifo_status <= 4'b0;
     end
     else begin
        if (wr_addr_diff == 12'b0) begin
           wr_fifo_status <= 4'b0;
        end
        else begin
           wr_fifo_status[3] <= !wr_addr_diff[11];
           wr_fifo_status[2] <= !wr_addr_diff[10];
           wr_fifo_status[1] <= !wr_addr_diff[9];
           wr_fifo_status[0] <= !wr_addr_diff[8];
        end
     end
  end

  assign fifo_status = wr_fifo_status;


  //----------------------------------------------------------------------------
  // Instantiate FIFO block memory
  //----------------------------------------------------------------------------

  assign wr_eof_data_bram[8]   = wr_eof_bram[0];
  assign wr_eof_data_bram[7:0] = wr_data_bram;

  // Block RAM for lower address space (rd_addr[11] = 1'b0)
  assign rd_eof_bram_l[0] = rd_eof_data_bram_l[8];
  assign rd_data_bram_l   = rd_eof_data_bram_l[7:0];
  BRAM_TDP_MACRO #
  (
     .DEVICE        ("VIRTEX6"),
     .WRITE_WIDTH_A (9),
     .WRITE_WIDTH_B (9),
     .READ_WIDTH_A  (9),
     .READ_WIDTH_B  (9)
  )
  ramgen_l (
     .DOA    (rd_bram_l_unused),
     .DOB    (rd_eof_data_bram_l),
     .ADDRA  (wr_addr[10:0]),
     .ADDRB  (rd_addr[10:0]),
     .CLKA   (tx_fifo_aclk),
     .CLKB   (tx_mac_aclk),
     .DIA    (wr_eof_data_bram),
     .DIB    (GND_BUS[8:0]),
     .ENA    (VCC),
     .ENB    (rd_en),
     .REGCEA (VCC),
     .REGCEB (VCC),
     .RSTA   (tx_fifo_reset),
     .RSTB   (tx_mac_reset),
     .WEA    (wr_en_l_bram),
     .WEB    (GND)
  );

  // Block RAM for upper address space (rd_addr[11] = 1'b1)
  assign rd_eof_bram_u[0] = rd_eof_data_bram_u[8];
  assign rd_data_bram_u   = rd_eof_data_bram_u[7:0];
  BRAM_TDP_MACRO #
  (
     .DEVICE        ("VIRTEX6"),
     .WRITE_WIDTH_A (9),
     .WRITE_WIDTH_B (9),
     .READ_WIDTH_A  (9),
     .READ_WIDTH_B  (9)
  )
  ramgen_u (
     .DOA    (rd_bram_u_unused),
     .DOB    (rd_eof_data_bram_u),
     .ADDRA  (wr_addr[10:0]),
     .ADDRB  (rd_addr[10:0]),
     .CLKA   (tx_fifo_aclk),
     .CLKB   (tx_mac_aclk),
     .DIA    (wr_eof_data_bram),
     .DIB    (GND_BUS[8:0]),
     .ENA    (VCC),
     .ENB    (rd_en),
     .REGCEA (VCC),
     .REGCEB (VCC),
     .RSTA   (tx_fifo_reset),
     .RSTB   (tx_mac_reset),
     .WEA    (wr_en_u_bram),
     .WEB    (GND)
  );


endmodule
