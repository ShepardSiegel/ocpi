//-----------------------------------------------------------------------------
// Title      : 8-bit Client-to-LocalLink Transmitter FIFO
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : tx_client_fifo_8.v
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
//-----------------------------------------------------------------------------
// Description: This is a transmit-side LocalLink FIFO implementation for
//              the example design of the Virtex-6 Embedded Tri-Mode Ethernet
//              MAC Wrapper core.
//
//              The transmit FIFO is created from a Block RAM of size 4096
//              words of 8-bits per word.
//
//              Valid frame data received from LocalLink interface is written
//              into the Block RAM on the write clock. The FIFO will store
//              frames upto 4kbytes in length. If larger frames are written
//              to the FIFO the LocalLink interface will accept the rest of the
//              frame, but that frame will be dropped by the FIFO and
//              the overflow signal will be asserted.
//
//              The FIFO is designed to work with a minimum frame length of 14
//              bytes.
//
//              When there is at least one complete frame in the FIFO,
//              the MAC transmitter client interface will be driven to
//              request frame transmission by placing the first byte of
//              the frame onto tx_data[15:0] and by asserting
//              tx_data_valid. The MAC will later respond by asserting
//              tx_ack. At this point the remaining frame data is read
//              out of the FIFO in a continuous burst. Data is read out
//              of the FIFO on the rd_clk.
//
//              The FIFO has been designed to operate with different clocks
//              on the write and read sides. The write clock (LocalLink clock)
//              can be an equal or faster frequency than the read clock
//              (client clock). The minimum write clock frequency is the read
//              clock frequency divided by 2.5.
//
//              The FIFO memory size can be increased by expanding the rd_addr
//              and wr_addr signal widths, to address further BRAMs.
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module tx_client_fifo_8 (
   // MAC Interface
   rd_clk,
   rd_sreset,
   rd_enable,
   tx_data,
   tx_data_valid,
   tx_ack,
   tx_collision,
   tx_retransmit,
   overflow,

   // LocalLink Interface
   wr_clk,
   wr_sreset,
   wr_data,
   wr_sof_n,
   wr_eof_n,
   wr_src_rdy_n,
   wr_dst_rdy_n,
   wr_fifo_status
);

  //---------------------------------------------------------------------------
  // Define interface signals
  //---------------------------------------------------------------------------

  // MAC Interface
  input        rd_clk;
  input        rd_sreset;
  input        rd_enable;
  output [7:0] tx_data;
  output       tx_data_valid;
  input        tx_ack;
  input        tx_collision;
  input        tx_retransmit;
  output       overflow;

  // LocalLink Interface
  input        wr_clk;
  input        wr_sreset;
  input  [7:0] wr_data;
  input        wr_sof_n;
  input        wr_eof_n;
  input        wr_src_rdy_n;
  output       wr_dst_rdy_n;
  output [3:0] wr_fifo_status;

  // If FULL_DUPLEX_ONLY is 1 then all the half duplex logic in the FIFO is removed.
  // The default for the fifo is to include the half duplex functionality
  parameter    FULL_DUPLEX_ONLY = 0;

  reg [7:0]    tx_data;
  reg          tx_data_valid;
  reg [3:0]    wr_fifo_status;

  //---------------------------------------------------------------------------
  // Define internal signals
  //---------------------------------------------------------------------------

  wire        GND;
  wire        VCC;
  wire [31:0] GND_BUS;

  // Encode rd_state_machine states
  parameter  IDLE_s = 4'b0000;      parameter  QUEUE1_s = 4'b0001;
  parameter  QUEUE2_s = 4'b0010;    parameter  QUEUE3_s = 4'b0011;
  parameter  QUEUE_ACK_s = 4'b0100; parameter  WAIT_ACK_s = 4'b0101;
  parameter  FRAME_s = 4'b0110;     parameter  DROP_s = 4'b0111;
  parameter  RETRANSMIT_s = 4'b1000;

  reg  [3:0]  rd_state;
  reg  [3:0]  rd_nxt_state;

  // Encode wr_state_machine states
  parameter WAIT_s = 2'b00;  parameter DATA_s = 2'b01;
  parameter EOF_s = 2'b10;   parameter OVFLOW_s = 2'b11;

  reg  [1:0]  wr_state;
  reg  [1:0]  wr_nxt_state;

  reg  [7:0]  wr_data_bram;
  reg  [7:0]  wr_data_pipe[0:1];
  reg         wr_sof_pipe[0:1];
  reg         wr_eof_pipe[0:1];
  reg         wr_accept_pipe[0:1];
  reg         wr_accept_bram;
  reg  [0:0]  wr_eof_bram;
  reg  [11:0] wr_addr;
  wire        wr_addr_inc;
  wire        wr_start_addr_load;
  wire        wr_addr_reload;
  reg  [11:0] wr_start_addr;
  reg         wr_fifo_full;
  wire        wr_en;
  reg         wr_ovflow_dst_rdy;
  wire        wr_dst_rdy_int_n;

  reg         frame_in_fifo;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         frame_in_fifo_sync;

  wire        rd_eof_bram;
  reg         rd_eof;
  reg         rd_eof_reg;
  reg  [11:0] rd_addr;
  wire        rd_addr_inc;
  wire        rd_addr_reload;
  wire [7:0]  rd_data_bram;
  reg  [7:0]  rd_data_pipe;
  wire        rd_en;
  wire        rd_en_bram;
  wire [31:0] dob_bram;
  wire [3:0]  dopb_bram;

  reg         rd_tran_frame_tog;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         wr_tran_frame_tog;

  reg         wr_tran_frame_sync;
  reg         wr_tran_frame_delay;
  reg         rd_retran_frame_tog;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         wr_retran_frame_tog;

  reg         wr_retran_frame_sync;
  reg         wr_retran_frame_delay;
  wire        wr_store_frame;
  wire        wr_eof_state;
  reg         wr_eof_state_reg;
  reg         wr_transmit_frame;
  reg         wr_retransmit_frame;
  reg  [8:0]  wr_frames;
  reg         wr_frame_in_fifo;

  reg   [3:0] rd_16_count;
  wire        rd_txfer_en;
  reg  [11:0] rd_addr_txfer;
  reg         rd_txfer_tog;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         wr_txfer_tog;

  reg         wr_txfer_tog_sync;
  reg         wr_txfer_tog_delay;
  wire        wr_txfer_en;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg  [11:0] wr_rd_addr;

  reg  [11:0] wr_addr_diff;

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

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         wr_col_window_pipe[0:1];

  wire        wr_fifo_overflow;
  reg  [9:0]  rd_slot_timer;
  reg         wr_col_window_expire;
  wire        rd_idle_state;

  reg         rd_enable_delay;
  reg         rd_enable_delay2;

  assign GND = 1'b0;
  assign VCC = 1'b1;
  assign GND_BUS = 32'b0;

  always @(posedge rd_clk)
  begin
    if (rd_sreset == 1'b1) begin
       rd_enable_delay <= 1'b0;
       rd_enable_delay2 <= 1'b0;
   end
   else begin
       rd_enable_delay <= rd_enable;
       rd_enable_delay2 <= rd_enable_delay;
   end
  end

  //---------------------------------------------------------------------------
  // Write state machine and control
  //---------------------------------------------------------------------------
  // Write state machine
  // states are WAIT, DATA, EOF, OVFLOW
  // clock through next state of sm
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
         wr_state <= WAIT_s;
     else
         wr_state <= wr_nxt_state;
  end

  // decode next state, combinitorial
  // should never be able to overflow whilst not in the data state.
  always @(wr_state or wr_sof_pipe[1] or wr_eof_pipe[0] or wr_eof_pipe[1] or wr_eof_bram[0] or wr_fifo_overflow)
  begin
  case (wr_state)
     WAIT_s : begin
        if (wr_sof_pipe[1] == 1'b1)
           wr_nxt_state <= DATA_s;
        else
           wr_nxt_state <= WAIT_s;
        end
     DATA_s : begin
        // wait for the end of frame to be detected
        if (wr_fifo_overflow == 1'b1 && wr_eof_pipe[0] == 1'b0 && wr_eof_pipe[1] == 1'b0)
           wr_nxt_state <= OVFLOW_s;
        else if (wr_eof_pipe[1] == 1'b1)
           wr_nxt_state <= EOF_s;
        else
           wr_nxt_state <= DATA_s;
        end
     EOF_s : begin
        // if the start of frame is already in the pipe, a back to back frame
        // transmission has occured.  move straight back to frame state
        if (wr_sof_pipe[1] == 1'b1)


           wr_nxt_state <= DATA_s;
        else if (wr_eof_bram[0] == 1'b1)
           wr_nxt_state <= WAIT_s;
        else
           wr_nxt_state <= EOF_s;
        end
     OVFLOW_s : begin
        // wait until the end of frame is reached before clearing the overflow
        if (wr_eof_bram[0] == 1'b1)
           wr_nxt_state <= WAIT_s;
        else
           wr_nxt_state <= OVFLOW_s;
        end
     default : begin
        wr_nxt_state <= WAIT_s;
        end
  endcase
  end

  // decode output signals.
  assign wr_en = (wr_state == OVFLOW_s) ? 1'b0 : wr_accept_bram;

  assign wr_addr_inc = wr_en;

  assign wr_addr_reload = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;
  assign wr_start_addr_load = (wr_state == EOF_s && wr_nxt_state == WAIT_s) ? 1'b1 :
                              (wr_state == EOF_s && wr_nxt_state == DATA_s) ? 1'b1 : 1'b0;

  // pause the LocalLink flow when the fifo is full.
  assign wr_dst_rdy_int_n = (wr_state == OVFLOW_s) ? wr_ovflow_dst_rdy : wr_fifo_full;
  assign wr_dst_rdy_n = wr_dst_rdy_int_n;

  // when in overflow and have captured ovflow eof send dst rdy high again.
  assign overflow = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;

  // when in overflow and have captured ovflow eof send dst rdy high again.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_ovflow_dst_rdy <= 1'b0;
     else
        begin
        if (wr_fifo_overflow == 1'b1 && wr_state == DATA_s)
            wr_ovflow_dst_rdy <= 1'b0;
        else if (wr_eof_n == 1'b0 && wr_src_rdy_n == 1'b0)
            wr_ovflow_dst_rdy <= 1'b1;
        end
  end

  // eof signals for use in overflow logic
  assign wr_eof_state = (wr_state == EOF_s) ? 1'b1 : 1'b0;

  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_eof_state_reg <= 1'b0;
     else
        wr_eof_state_reg <= wr_eof_state;
  end

  //---------------------------------------------------------------------------
  // Read state machine and control
  //---------------------------------------------------------------------------
  // clock through the read state machine
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_state <= IDLE_s;
     else if (rd_enable == 1'b1)
        rd_state <= rd_nxt_state;
  end

  // Full duplex only state machine
  generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_sm
  // decode the next state
  always @(rd_state or frame_in_fifo or rd_eof or tx_ack)
  begin
      case (rd_state)
           IDLE_s : begin
              // if there is a frame in the fifo start to queue the new frame
              // to the output
              if (frame_in_fifo == 1'b1)
                 rd_nxt_state <= QUEUE1_s;
              else
                 rd_nxt_state <= IDLE_s;
              end
           QUEUE1_s : begin
                 rd_nxt_state <= QUEUE2_s;
              end
           QUEUE2_s : begin
                 rd_nxt_state <= QUEUE3_s;
              end
           QUEUE3_s : begin
                 rd_nxt_state <= QUEUE_ACK_s;
              end
           QUEUE_ACK_s : begin
                 rd_nxt_state <= WAIT_ACK_s;
              end
           WAIT_ACK_s : begin
              // the output pipe line is fully loaded, so wait for ack from mac
              // before moving on
              if (tx_ack == 1'b1)
                 rd_nxt_state <= FRAME_s;
              else
                 rd_nxt_state <= WAIT_ACK_s;
              end
           FRAME_s : begin
              // when the end of frame has been reached wait another frame in
              // the fifo
              if (rd_eof == 1'b1)
                 rd_nxt_state <= IDLE_s;
              else
                 rd_nxt_state <= FRAME_s;
              end
           default : begin
                 rd_nxt_state <= IDLE_s;
              end
      endcase
  end
  end // gen_fd_sm
  endgenerate

  // Full and Half Duplex State Machine
  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_sm
  // decode the next state
  // should never receive a rd_drop_frame pulse outside of the Frame state
  always @(rd_state or frame_in_fifo or rd_eof_reg or tx_ack or rd_drop_frame or rd_retransmit)
  begin
  case (rd_state)
           IDLE_s : begin
              // if a retransmit request is detected go to retransmit state
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              // if there is a frame in the fifo then queue the new frame to
              // the output
              else if (frame_in_fifo == 1'b1)
                 rd_nxt_state <= QUEUE1_s;
              else
                 rd_nxt_state <= IDLE_s;
              end
           QUEUE1_s : begin
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              else
                rd_nxt_state <= QUEUE2_s;
              end
           QUEUE2_s : begin
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              else
                 rd_nxt_state <= QUEUE3_s;
              end
           QUEUE3_s : begin
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              else
                 rd_nxt_state <= QUEUE_ACK_s;
              end
           QUEUE_ACK_s : begin
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              else
                 rd_nxt_state <= WAIT_ACK_s;
              end
           WAIT_ACK_s : begin
              // the output pipeline is now fully loaded so wait for ack from
              // mac before moving on.
              if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              else if (tx_ack == 1'b1)
                 rd_nxt_state <= FRAME_s;
              else
                 rd_nxt_state <= WAIT_ACK_s;
              end
           FRAME_s : begin
              // if a collision only request, then must drop the rest of the
              // current frame, move to drop state
              if (rd_drop_frame == 1'b1)
                 rd_nxt_state <= DROP_s;
              else if (rd_retransmit == 1'b1)
                 rd_nxt_state <= RETRANSMIT_s;
              // continue transmitting frame until the end of the frame is
              // detected, then wait for a new frame to be sent.
              else if (rd_eof_reg == 1'b1)
                 rd_nxt_state <= IDLE_s;
              else
                 rd_nxt_state <= FRAME_s;
              end
           DROP_s : begin
              // wait until rest of frame has been cleared.
              if (rd_eof_reg == 1'b1)
                 rd_nxt_state <= IDLE_s;
              else
                 rd_nxt_state <= DROP_s;
              end
           RETRANSMIT_s : begin
              // reload the data pipe from the start of the frame
                 rd_nxt_state <= QUEUE1_s;
              end
           default : begin
                 rd_nxt_state <= IDLE_s;
              end
        endcase
  end
  end // gen_hd_sm
  endgenerate

  // Decode output signals
  // decode output data
  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        begin
        if (rd_nxt_state == FRAME_s)
           tx_data <= rd_data_pipe;
        else
        begin
           case (rd_state)
              QUEUE_ACK_s :
                 tx_data <= rd_data_pipe;
              WAIT_ACK_s :
                 tx_data <= tx_data;
              FRAME_s :
                 tx_data <= rd_data_pipe;
              default :
                 tx_data <= 8'b0;
           endcase
           end
        end
  end

  // decode output data valid
  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        begin
        if (rd_nxt_state == FRAME_s)
           tx_data_valid <= ~(tx_collision && ~(tx_retransmit));
        else
        begin
           case (rd_state)
              QUEUE_ACK_s :
                 tx_data_valid <= 1'b1;
              WAIT_ACK_s :
                 tx_data_valid <= 1'b1;
              FRAME_s :
                 tx_data_valid <= ~(rd_nxt_state == DROP_s);
              default :
                 tx_data_valid <= 1'b0;
           endcase
           end
        end
  end

  // decode full duplex only control signals
  generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_decode

  assign rd_en = (rd_state == IDLE_s) ? 1'b0 :
                 (rd_nxt_state == FRAME_s) ? 1'b1 :
                 (rd_state == WAIT_ACK_s) ? 1'b0 : 1'b1;

  assign rd_addr_inc = rd_en;

  assign rd_addr_reload = (rd_state == FRAME_s && rd_nxt_state == IDLE_s) ? 1'b1 : 1'b0;

  // Transmit frame pulse is only 1 clock enabled pulse long.
  // Transmit frame pulse must never be more frequent than 64 clocks to allow toggle to cross clock domain
  assign rd_transmit_frame = (rd_state == WAIT_ACK_s && rd_nxt_state == FRAME_s) ? 1'b1 : 1'b0;

  // unused for full duplex only
  assign rd_start_addr_reload = 1'b0;
  assign rd_start_addr_load   = 1'b0;
  assign rd_retransmit_frame  = 1'b0;

  end // gen_fd_decode
  endgenerate

  // decode half duplex control signals
  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_decode

  assign rd_en = (rd_state == IDLE_s) ? 1'b0 :
                 (rd_nxt_state == DROP_s && rd_eof == 1'b1) ? 1'b0 :
                 (rd_nxt_state == FRAME_s) ? 1'b1 :
                 (rd_state == RETRANSMIT_s) ? 1'b0 :
                 (rd_state == WAIT_ACK_s) ? 1'b0 : 1'b1;

  assign rd_addr_inc = rd_en;

  assign rd_addr_reload = (rd_state == FRAME_s && rd_nxt_state == IDLE_s) ? 1'b1 :
                          (rd_state == DROP_s && rd_nxt_state == IDLE_s) ? 1'b1 : 1'b0;

  assign rd_start_addr_reload = (rd_state == RETRANSMIT_s) ? 1'b1 : 1'b0;

  assign rd_start_addr_load = (rd_state == WAIT_ACK_s && rd_nxt_state == FRAME_s) ? 1'b1 :
                              (rd_col_window_expire == 1'b1) ? 1'b1 : 1'b0;

  // Transmit frame pulse must never be more frequent than 64 clocks to allow toggle to cross clock domain
  assign rd_transmit_frame = (rd_state == WAIT_ACK_s && rd_nxt_state == FRAME_s) ? 1'b1 : 1'b0;

  // Retransmit frame pulse must never be more frequent than 16 clocks to allow toggle to cross clock domain
  assign rd_retransmit_frame = (rd_state == RETRANSMIT_s) ? 1'b1 : 1'b0;

  end // gen_hd_decode
  endgenerate

  //---------------------------------------------------------------------------
  // Frame Count
  // We need to maintain a count of frames in the fifo, so that we know when a
  // frame is available for transmission.  The counter must be held on the
  // write clock domain as this is the faster clock.
  //---------------------------------------------------------------------------

  // A frame has been written to the fifo
  assign wr_store_frame = (wr_state == EOF_s && wr_nxt_state != EOF_s) ? 1'b1 : 1'b0;

  // generate a toggle to indicate when a frame has been transmitted from the fifo
  always @(posedge rd_clk)
  begin  // process
     if (rd_sreset == 1'b1)
         rd_tran_frame_tog <= 1'b0;
     else if (rd_enable == 1'b1)
        if (rd_transmit_frame == 1'b1)  // assumes EOF_s is valid for one clock
              rd_tran_frame_tog <= !rd_tran_frame_tog;
  end

  // move the read transmit frame signal onto the write clock domain
  always @(posedge wr_clk)
  begin
      if (wr_sreset == 1'b1)
      begin
            wr_tran_frame_tog  <= 1'b0;
            wr_tran_frame_sync <= 1'b0;
            wr_tran_frame_delay <= 1'b0;
            wr_transmit_frame   <= 1'b0;
      end
      else
      begin
           wr_tran_frame_tog  <= rd_tran_frame_tog;
           wr_tran_frame_sync <= wr_tran_frame_tog;
           wr_tran_frame_delay <= wr_tran_frame_sync;
           // edge detector
           if ((wr_tran_frame_delay ^ wr_tran_frame_sync) == 1'b1)
             wr_transmit_frame    <= 1'b1;
           else
             wr_transmit_frame    <= 1'b0;
      end
  end

  generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_count

  // count the number of frames in the fifo.  the counter is incremented when a
  // frame is stored and decremented when a frame is transmitted.  Need to keep
  // the counter on the write clock as this is the fastest clock.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_frames <= 9'b0;
     else
        if ((wr_store_frame & !wr_transmit_frame) == 1'b1)
           wr_frames <= wr_frames + 9'b1;
        else if ((!wr_store_frame & wr_transmit_frame) == 1'b1)
           wr_frames <= wr_frames - 9'b1;
  end

  end // gen_fd_count
  endgenerate

  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_count

  // generate a toggle to indicate when a frame has been transmitted from the fifo
  always @(posedge rd_clk)
  begin  // process
     if (rd_sreset == 1'b1)
        rd_retran_frame_tog <= 1'b0;
     else if (rd_enable == 1'b1)
        if (rd_retransmit_frame == 1'b1) // assumes EOF_s is valid for one clock
           rd_retran_frame_tog <= !rd_retran_frame_tog;
  end

  // move the read transmit frame signal onto the write clock domain
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        begin
           wr_retran_frame_tog  <= 1'b0;
           wr_retran_frame_sync <= 1'b0;
           wr_retran_frame_delay <= 1'b0;
           wr_retransmit_frame  <= 1'b0;
        end
     else
        begin
           wr_retran_frame_tog  <= rd_retran_frame_tog;
           wr_retran_frame_sync <= wr_retran_frame_tog;
           wr_retran_frame_delay <= wr_retran_frame_sync;
           // edge detector
           if ((wr_retran_frame_delay ^ wr_retran_frame_sync) == 1'b1)
              wr_retransmit_frame    <= 1'b1;
           else
              wr_retransmit_frame    <= 1'b0;
        end
  end

  // count the number of frames in the fifo.  the counter is incremented when a
  // frame is stored or retransmitted and decremented when a frame is transmitted.  Need to keep
  // the counter on the write clock as this is the fastest clock.
  // Assumes transmit and retransmit cannot happen at same time
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_frames <= 9'b0;
     else
        if ((wr_store_frame & wr_retransmit_frame) == 1'b1)
           wr_frames <= wr_frames + 9'd2;
        else if (((wr_store_frame | wr_retransmit_frame) & !wr_transmit_frame) == 1'b1)
           wr_frames <= wr_frames + 9'b1;
        else if (wr_transmit_frame == 1'b1 & !wr_store_frame)
           wr_frames <= wr_frames - 9'b1;
  end

  end // gen_hd_count
  endgenerate

  // generate a frame in fifo signal for use in control logic
  always @(posedge wr_clk)
  begin
      if (wr_sreset == 1'b1)
         wr_frame_in_fifo <= 1'b0;
      else
         if (wr_frames != 9'b0)
            wr_frame_in_fifo <= 1'b1;
         else
            wr_frame_in_fifo <= 1'b0;
  end

  // register back onto read domain for use in the read logic
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        begin
           frame_in_fifo_sync <= 1'b0;
           frame_in_fifo <= 1'b0;
        end
     else if (rd_enable == 1'b1)
        begin
           frame_in_fifo_sync <= wr_frame_in_fifo;
           frame_in_fifo <= frame_in_fifo_sync;
        end
  end

  //---------------------------------------------------------------------------
  // Address counters
  //---------------------------------------------------------------------------
  // Address counters
  // write address is incremented when write enable signal has been asserted
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_addr <= 12'b0;
     else if (wr_addr_reload == 1'b1)
        wr_addr <= wr_start_addr;
     else if (wr_addr_inc == 1'b1)
        wr_addr <= wr_addr + 12'b1;
  end

  // store the start address incase the address must be reset
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_start_addr <= 12'b0;
     else if (wr_start_addr_load == 1'b1)
        wr_start_addr <= wr_addr + 12'b1;
  end

  generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_addr
  // read address is incremented when read enable signal has been asserted
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr <= 12'b0;
     else if (rd_enable == 1'b1)
        if (rd_addr_reload == 1'b1)
           rd_addr <= rd_dec_addr;
        else if (rd_addr_inc == 1'b1)
           rd_addr <= rd_addr + 12'b1;
  end

  // do not need to keep a start address, but the address is needed to
  // calculate fifo occupancy.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_start_addr <= 12'b0;
     else if (rd_enable == 1'b1)
        rd_start_addr <= rd_addr;
  end

  end // gen_fd_addr
  endgenerate

  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_addr
  // read address is incremented when read enable signal has been asserted
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr <= 12'b0;
     else if (rd_enable == 1'b1)
        if (rd_addr_reload == 1'b1)
           rd_addr <= rd_dec_addr;
        else if (rd_start_addr_reload == 1'b1)
           rd_addr <= rd_start_addr;
        else if (rd_addr_inc == 1'b1)
           rd_addr <= rd_addr + 12'b1;
  end

  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_start_addr <= 12'b0;
     else if (rd_enable == 1'b1)
        if (rd_start_addr_load == 1'b1)
           rd_start_addr <= rd_addr - 12'd4;
  end

  // Collision window expires after MAC has been transmitting for required slot
  // time.  This is 512 clock cycles at 1G.  Also if the end of frame has fully
  // been transmitted by the mac then a collision cannot occur. This collision
  // expire signal goes high at 768 cycles from the start of the frame.
  // Inefficient for short frames, however should be enough to prevent fifo
  // locking up.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_col_window_expire <= 1'b0;
     else if (rd_enable == 1'b1)
        if (rd_transmit_frame == 1'b1)
           rd_col_window_expire <= 1'b0;
        else if (rd_slot_timer[9:8] == 2'b11)
           rd_col_window_expire <= 1'b1;
  end

  assign rd_idle_state = (rd_state == IDLE_s) ? 1'b1 : 1'b0;

  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        begin
           rd_col_window_pipe[0] <= rd_col_window_expire & rd_idle_state;
           if (rd_txfer_en == 1'b1)
              rd_col_window_pipe[1] <= rd_col_window_pipe[0];
        end
  end

  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1) // will not count until after first
                            // frame is sent.
        rd_slot_timer <= 10'b0;
     else if (rd_enable == 1'b1)
        if (rd_transmit_frame == 1'b1)  // reset counter
           rd_slot_timer <= 10'b0;
        // do not allow counter to role over.
        // only count when frame is being transmitted.
        else if (rd_slot_timer != 10'b1111111111)
           rd_slot_timer <= rd_slot_timer + 10'b1;
  end

  end // gen_hd_addr
  endgenerate

  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
           rd_dec_addr <= 12'b0;
     else if (rd_enable == 1'b1)
        if (rd_addr_inc == 1'b1)
           rd_dec_addr <= rd_addr - 12'b1;
  end

  //---------------------------------------------------------------------------
  // Data pipelines
  //---------------------------------------------------------------------------
  // register input signals to fifo
  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     wr_data_pipe[0] <= wr_data;
     if (wr_accept_pipe[0] == 1'b1)
        wr_data_pipe[1] <= wr_data_pipe[0];
     if (wr_accept_pipe[1] == 1'b1)
        wr_data_bram    <= wr_data_pipe[1];
  end

  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     wr_sof_pipe[0] <= !wr_sof_n;
     if (wr_accept_pipe[0] == 1'b1)
        wr_sof_pipe[1] <= wr_sof_pipe[0];
  end

  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        begin
           wr_accept_pipe[0] <= 1'b0;
           wr_accept_pipe[1] <= 1'b0;
           wr_accept_bram    <= 1'b0;
        end
     else
        begin
           wr_accept_pipe[0] <= !wr_src_rdy_n & !wr_dst_rdy_int_n;
           wr_accept_pipe[1] <= wr_accept_pipe[0];
           wr_accept_bram    <= wr_accept_pipe[1];
        end
  end

  always @(posedge wr_clk)
  begin
     wr_eof_pipe[0] <= !wr_eof_n;
     if (wr_accept_pipe[0] == 1'b1)
        wr_eof_pipe[1] <= wr_eof_pipe[0];
     if (wr_accept_pipe[1] == 1'b1)
        wr_eof_bram[0] <= wr_eof_pipe[1];
  end

  // register data output
  // no reset to allow srl16 target
  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        if (rd_en == 1'b1)
           rd_data_pipe <= rd_data_bram;
  end

  // register data output
  // no reset to allow srl16 target
  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        if (rd_en == 1'b1)
           begin
              rd_eof <= rd_eof_bram;
              rd_eof_reg <= rd_eof | rd_eof_bram;
           end
  end

  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_input
  // register the collision and retransmit signals
  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        rd_drop_frame <= tx_collision & !tx_retransmit;
  end

  always @(posedge rd_clk)
  begin
     if (rd_enable == 1'b1)
        rd_retransmit <= tx_collision & tx_retransmit;
  end

  end // gen_hd_input
  endgenerate

  //---------------------------------------------------------------------------
  // FIFO full functionality
  //---------------------------------------------------------------------------
  // when full duplex full functionality is difference between read and write addresses.
  // when in half duplex is difference between read start and write addresses.
  // Cannot use gray code this time as the read address and read start addresses jump by more than 1

  // generate an enable pulse for the read side every 16 read clocks.  This provides for the worst case
  // situation where wr clk is 20Mhz and rd clk is 125 Mhz.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_16_count <= 4'b0;
     else if (rd_enable == 1'b1)
        rd_16_count <= rd_16_count + 4'b1;
  end

  assign rd_txfer_en = (rd_16_count == 4'b1111) ? 1'b1 : 1'b0;

  // register the start address on the enable pulse
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr_txfer <= 12'b0;
     else if (rd_enable == 1'b1)
        begin
        if (rd_txfer_en == 1'b1)
           rd_addr_txfer <= rd_start_addr;
        end
  end

  // generate a toggle to indicate that the address has been loaded.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_txfer_tog <= 1'b0;
     else if (rd_enable == 1'b1)
        begin
        if (rd_txfer_en == 1'b1)
           rd_txfer_tog <= !rd_txfer_tog;
        end
  end

  // pass the toggle to the write side
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        begin
           wr_txfer_tog <= 1'b0;
           wr_txfer_tog_sync <= 1'b0;
           wr_txfer_tog_delay <= 1'b0;
        end
     else
        begin
           wr_txfer_tog <= rd_txfer_tog;
           wr_txfer_tog_sync <= wr_txfer_tog;
           wr_txfer_tog_delay <= wr_txfer_tog_sync;
        end
  end

  // generate an enable pulse from the toggle, the address should have
  // been steady on the wr clock input for at least one clock
  assign wr_txfer_en = wr_txfer_tog_delay ^ wr_txfer_tog_sync;

  // capture the address on the write clock when the enable pulse is high.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_rd_addr <= 12'b0;
     else if (wr_txfer_en == 1'b1)
        wr_rd_addr <= rd_addr_txfer;
  end

  // Obtain the difference between write and read pointers
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_addr_diff <= 12'b0;
     else
        wr_addr_diff <= wr_rd_addr - wr_addr;
  end

  // Detect when the FIFO is full
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_fifo_full <= 1'b0;
     else
        // The FIFO is considered to be full if the write address
        // pointer is within 1 to 3 of the read address pointer.
        if (wr_addr_diff[11:4] == 8'b0 && wr_addr_diff[3:2] != 2'b0)
           wr_fifo_full <= 1'b1;
        else
           wr_fifo_full <= 1'b0;
  end

  // memory overflow occurs when the fifo is full and there are no frames
  // available in the fifo for transmission.  If the collision window has
  // expired and there are no frames in the fifo and the fifo is full, then the
  // fifo is in an overflow state.  we must accept the rest of the incoming
  // frame in overflow condition.

  generate if (FULL_DUPLEX_ONLY == 1) begin : gen_fd_ovflow
     // in full duplex mode, the fifo memory can only overflow if the fifo goes
     // full but there is no frame available to be retranmsitted
     // do not allow to go high when the frame count is being updated, ie wr_store_frame is asserted.
     assign wr_fifo_overflow = (wr_fifo_full == 1'b1 && wr_frame_in_fifo == 1'b0
                             && wr_eof_state == 1'b0 && wr_eof_state_reg == 1'b0) ? 1'b1 : 1'b0;
  end // gen_fd_ovflow
  endgenerate

  generate if (FULL_DUPLEX_ONLY != 1) begin : gen_hd_ovflow
    // register wr col window to give address counter sufficient time to update.
    // do not allow to go high when the frame count is being updated, ie wr_store_frame is asserted.
    assign wr_fifo_overflow = (wr_fifo_full == 1'b1 && wr_frame_in_fifo == 1'b0
                            && wr_eof_state == 1'b0 && wr_eof_state_reg == 1'b0
                            && wr_col_window_expire == 1'b1) ? 1'b1 : 1'b0;

    // register rd_col_window signal
    // this signal is long, and will remain high until overflow functionality
    // has finished, so save just to register the once.
    always @(posedge wr_clk)
    begin  // process
       if (wr_sreset == 1'b1)
          begin
             wr_col_window_pipe[0] <= 1'b0;
             wr_col_window_pipe[1] <= 1'b0;
             wr_col_window_expire  <= 1'b0;
          end
       else
          begin
             if (wr_txfer_en == 1'b1)
                wr_col_window_pipe[0] <= rd_col_window_pipe[1];
             wr_col_window_pipe[1] <= wr_col_window_pipe[0];
             wr_col_window_expire <= wr_col_window_pipe[1];
          end
    end

  end // gen_hd_ovflow
  endgenerate

  //--------------------------------------------------------------------
  // Create FIFO Status Signals in the Write Domain
  //--------------------------------------------------------------------
  // The FIFO status signal is four bits which represents the occupancy
  // of the FIFO in 16'ths.  To generate this signal we therefore only
  // need to compare the 4 most significant bits of the write address
  // pointer with the 4 most significant bits of the read address
  // pointer.

  // The 4 most significant bits of the write pointer minus the 4 msb of
  // the read pointer gives us our FIFO status.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_fifo_status <= 4'b0;
     else
        if (wr_addr_diff == 12'b0)
           wr_fifo_status <= 4'b0;
        else
           begin
              wr_fifo_status[3] <= !wr_addr_diff[11];
              wr_fifo_status[2] <= !wr_addr_diff[10];
              wr_fifo_status[1] <= !wr_addr_diff[9];
              wr_fifo_status[0] <= !wr_addr_diff[8];
           end
  end

  //---------------------------------------------------------------------------
  // Memory
  //---------------------------------------------------------------------------
  assign rd_en_bram = rd_en & rd_enable_delay2;

  RAMB36E1 #(
    .DOB_REG             (1),
    .READ_WIDTH_A        (9),
    .READ_WIDTH_B        (9),
    .RSTREG_PRIORITY_B   ("RSTREG"),
    .SIM_COLLISION_CHECK ("ALL"),
    .SRVAL_B             (36'h0),
    .WRITE_MODE_A        ("WRITE_FIRST"),
    .WRITE_MODE_B        ("WRITE_FIRST"),
    .WRITE_WIDTH_A       (9),
    .WRITE_WIDTH_B       (9)
  )
  ramgen (
    .ENARDEN       (VCC),
    .CLKARDCLK     (wr_clk),
    .RSTRAMARSTRAM (wr_sreset),
    .RSTREGARSTREG (GND),
    .CASCADEINA    (GND),
    .REGCEAREGCE   (GND),
    .ENBWREN       (rd_en_bram),
    .CLKBWRCLK     (rd_clk),
    .RSTRAMB       (rd_sreset),
    .RSTREGB       (rd_sreset),
    .CASCADEINB    (GND),
    .REGCEB        (rd_en_bram),
    .INJECTDBITERR (GND),
    .INJECTSBITERR (GND),
    .ADDRARDADDR   ({GND, wr_addr, GND_BUS[2:0]}),
    .ADDRBWRADDR   ({GND, rd_addr, GND_BUS[2:0]}),
    .DIADI         ({GND_BUS[23:0], wr_data_bram}),
    .DIBDI         (GND_BUS),
    .DIPADIP       ({GND_BUS[2:0], wr_eof_bram[0]}),
    .DIPBDIP       (GND_BUS[3:0]),
    .WEA           ({GND_BUS[2:0], wr_en}),
    .WEBWE         (GND_BUS[7:0]),
    .CASCADEOUTA   (),
    .CASCADEOUTB   (),
    .DOADO         (),
    .DOBDO         (dob_bram),
    .DOPADOP       (),
    .DOPBDOP       (dopb_bram),
    .ECCPARITY     (),
    .RDADDRECC     (),
    .SBITERR       (),
    .DBITERR       ()
  );

  assign rd_data_bram = dob_bram[7:0];
  assign rd_eof_bram  = dopb_bram[0];

endmodule
