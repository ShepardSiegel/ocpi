//-----------------------------------------------------------------------------
// Title      : 8-bit Client-to-LocalLink Receiver FIFO
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : rx_client_fifo_8.v
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
// Description: This is the receive-side LocalLink FIFO for the example design
//              of the Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper core.
//
//              The FIFO is created from a Block RAM of size 4096
//              words by 8 bits per word.
//
//              Frame data received from the MAC receiver is written into the
//              FIFO on the wr_clk. An End Of Frame marker is written to the
//              BRAM parity bit on the last byte of data stored for a frame.
//              This acts as frame deliniation.
//
//              The rx_good_frame and rx_bad_frame signals are used to
//              qualify the frame. A frame for which rx_bad_frame was
//              asserted will cause the FIFO write address pointer to be
//              reset to the base address of that frame. In this way
//              the bad frame will be overwritten with the next received
//              frame and is therefore dropped from the FIFO.
//
//              Frames will also be dropped from the FIFO if an overflow occurs.
//              If there is not enough memory capacity in the FIFO to store the
//              whole of an incoming frame, the write address pointer will be
//              reset and the overflow signal asserted.
//
//              When there is at least one complete frame in the FIFO,
//              the 8-bit LocalLink read interface will be enabled allowing
//              data to be read from the fifo.
//
//              The FIFO has been designed to operate with different clocks
//              on the write and read sides.  The read clock (LocalLink clock)
//              should always operate at an equal or faster frequency
//              than the write clock (client clock).
//
//              The FIFO is designed to work with a minimum frame length of 8 bytes.
//
//              The FIFO memory size can be increased by expanding the rd_addr
//              and wr_addr signal widths, to address further BRAMs.
//
//              Requirements :
//              * Minimum frame size of 8 bytes
//              * Spacing between good/bad frame flags is at least 32 clock cycles
//              * Wr clock is 125MHz downto 1.25MHz
//              * Rd clock is downto 20MHz
//
//-------------------------------------------------------------------------------

`timescale 1ps / 1ps

module rx_client_fifo_8 (
   // LocalLink Interface
   rd_clk,
   rd_sreset,
   rd_data_out,
   rd_sof_n,
   rd_eof_n,
   rd_src_rdy_n,
   rd_dst_rdy_n,
   rx_fifo_status,

   // Client Interface
   wr_sreset,
   wr_clk,
   wr_enable,
   rx_data,
   rx_data_valid,
   rx_good_frame,
   rx_bad_frame,
   overflow
);


  //---------------------------------------------------------------------------
  // Define interface signals
  //--------------------------------------------------------------------------

  // LocalLink Interface
  input        rd_clk;
  input        rd_sreset;
  output [7:0] rd_data_out;
  output       rd_sof_n;
  output       rd_eof_n;
  output       rd_src_rdy_n;
  input        rd_dst_rdy_n;
  output [3:0] rx_fifo_status;

  // Client Interface
  input        wr_sreset;
  input        wr_clk;
  input        wr_enable;
  input [7:0]  rx_data;
  input        rx_data_valid;
  input        rx_good_frame;
  input        rx_bad_frame;
  output       overflow;

  reg [7:0]    rd_data_out;

  //---------------------------------------------------------------------------
  // Define internal signals
  //---------------------------------------------------------------------------

  wire        GND;
  wire        VCC;
  wire [31:0] GND_BUS;

  // Encode rd_state_machine states
  parameter WAIT_s = 3'b000;      parameter QUEUE1_s = 3'b001;
  parameter QUEUE2_s = 3'b010;    parameter QUEUE3_s = 3'b011;
  parameter QUEUE_SOF_s = 3'b100; parameter SOF_s = 3'b101;
  parameter DATA_s = 3'b110;      parameter EOF_s = 3'b111;

  reg [2:0]   rd_state;
  reg [2:0]   rd_nxt_state;

  // Encode wr_state_machine states
  parameter IDLE_s = 3'b000; parameter FRAME_s = 3'b001;
  parameter END_s= 3'b010;   parameter GF_s = 3'b011;
  parameter BF_s = 3'b100;   parameter OVFLOW_s = 3'b101;

  reg  [2:0]  wr_state;
  reg  [2:0]  wr_nxt_state;

  wire        wr_en;
  reg  [11:0] wr_addr;
  wire        wr_addr_inc;
  wire        wr_start_addr_load;
  wire        wr_addr_reload;
  reg  [11:0] wr_start_addr;
  reg  [7:0]  wr_data_bram;
  reg  [7:0]  wr_data_pipe[0:1];
  reg  [0:0]  wr_eof_bram;
  reg         wr_dv_pipe[0:1];
  reg         wr_gf_pipe[0:1];
  reg         wr_bf_pipe[0:1];
  reg         frame_in_fifo;

  reg  [11:0] rd_addr;
  wire        rd_addr_inc;
  wire        rd_addr_reload;
  wire [7:0]  rd_data_bram;
  reg  [7:0]  rd_data_pipe;
  reg         rd_en;
  wire        rd_pull_frame;
  wire        rd_eof;
  wire [31:0] dob_bram;
  wire [3:0]  dopb_bram;

  reg         wr_store_frame_tog;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg         rd_store_frame_tog;

  reg         rd_store_frame_delay;
  reg         rd_store_frame_sync;
  reg         rd_store_frame;
  reg  [8:0]  rd_frames;
  reg         wr_fifo_full;

  reg  [11:0] rd_addr_gray;

  // ASYNC_REG attribute added to simulate actual behavior under
  // asynchronous operating conditions.
  (* ASYNC_REG = "TRUE" *)
  reg  [11:0] wr_rd_addr_gray_sync;

  reg  [11:0] wr_rd_addr_gray;
  wire [11:0] wr_rd_addr;
  reg  [11:0] wr_addr_diff;

  reg  [3:0]  wr_fifo_status;

  reg         rd_sof_n_int     = 1'b1;
  reg         rd_eof_n_int     = 1'b1;
  reg         rd_src_rdy_n_int = 1'b1;

  reg  [2:0]  rd_valid_pipe;

  //---------------------------------------------------------------------------
  // Functions for gray code conversion
  //---------------------------------------------------------------------------
  function [11:0] bin_to_gray;
  input    [11:0] bin;
  integer         i;
  begin
     for (i=0;i<12;i=i+1)
        begin
          if (i == 11)
             bin_to_gray[i] = bin[i];
          else
             bin_to_gray[i] = bin[i+1] ^ bin[i];
        end
  end
  endfunction

  function [11:0] gray_to_bin;
  input   [11:0] gray;
  integer        i;
  begin
     for (i=11;i>=0;i=i-1)
        begin
          if (i == 11)
            gray_to_bin[i] = gray[i];
          else
            gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
        end
  end
  endfunction // gray_to_bin

  assign GND     = 1'b0;
  assign VCC     = 1'b1;
  assign GND_BUS = 32'b0;

  //---------------------------------------------------------------------------
  // Read state machines and control
  //---------------------------------------------------------------------------
  // LocalLink state machine
  // states are WAIT, QUEUE1, QUEUE2, QUEUE3, SOF, DATA, EOF
  // clock state to next state
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_state <= WAIT_s;
     else
        rd_state <= rd_nxt_state;
  end

  assign rd_eof_n = rd_eof_n_int;

  // decode next state, combinatorial
  always @(rd_state or frame_in_fifo or rd_eof or rd_dst_rdy_n or rd_eof_n_int or rd_valid_pipe[1])
  begin
     case (rd_state)
        WAIT_s : begin
           // wait till there is a full frame in the fifo
           // then start to load the pipeline
           if (frame_in_fifo == 1'b1 && rd_eof_n_int == 1'b1)
              rd_nxt_state <= QUEUE1_s;
           else
              rd_nxt_state <= WAIT_s;
           end
        QUEUE1_s : begin
           // load the output pipeline
           // this takes three clocks
           rd_nxt_state <= QUEUE2_s;
           end
        QUEUE2_s : begin
           rd_nxt_state <= QUEUE3_s;
           end
        QUEUE3_s : begin
           rd_nxt_state <= QUEUE_SOF_s;
           end
        QUEUE_SOF_s : begin
           // used mark sof at end of queue
              rd_nxt_state <= DATA_s;  // move straight to frame.
           end
        SOF_s : begin
           // used to mark sof when following straight from eof
           if (rd_dst_rdy_n == 1'b0)
              rd_nxt_state <= DATA_s;
           else
              rd_nxt_state <= SOF_s;
           end
        DATA_s : begin
           // When the eof marker is detected from the BRAM output
           // move to EOF state
           if (rd_dst_rdy_n == 1'b0 && rd_eof == 1'b1)
              rd_nxt_state <= EOF_s;
           else
              rd_nxt_state <= DATA_s;
           end
        EOF_s : begin
           // hold in this state until dst rdy is low
           // and eof bit is accepted on interface
           // If there is a frame in the fifo, then the next frame
           // will already be queued into the pipe line so move straight
           // to sof state.
           if (rd_dst_rdy_n == 1'b0)
              if (rd_valid_pipe[1] == 1'b1)
                 rd_nxt_state <= SOF_s;
              else
                 rd_nxt_state <= WAIT_s;
              else
              rd_nxt_state <= EOF_s;
           end
        default : begin
           rd_nxt_state <= WAIT_s;
           end
        endcase
  end

  // detect if frame in fifo was high 3 reads ago
  // this is used to ensure we only treat data in the pipeline as valid if
  // frame in fifo goes high at or before the eof of the current frame
  // It may be that there is valid data (i.e a partial packet has been written)
  // but until the end of that packet we do not know if it is a good packet
  always @(posedge rd_clk)
  begin
    if (rd_dst_rdy_n == 1'b0)
      rd_valid_pipe <= {rd_valid_pipe[1], rd_valid_pipe[0], frame_in_fifo};
  end

  // decode the output signals depending on current state.
  // decode sof signal.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_sof_n_int <= 1'b1;
     else
        case (rd_state)
           QUEUE_SOF_s :
              // no need to wait for dst rdy to be low, as there is valid data
              rd_sof_n_int <= 1'b0;
           SOF_s :
              // needed to wait till rd_dst_rdy is low to ensure eof signal has
              // been accepted onto the interface before asserting sof.
              if (rd_dst_rdy_n == 1'b0)
                 rd_sof_n_int <= 1'b0;
           default :
              // needed to wait till rd_dst_rdy is low to ensure sof signal has
              // been accepted onto the interface.
              if (rd_dst_rdy_n == 1'b0)
                 rd_sof_n_int <= 1'b1;
        endcase
  end

  //assign to rd_sof_n output
  assign rd_sof_n = rd_sof_n_int;

  // decode eof signal
  // check init value of this reg is 1.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_eof_n_int <= 1'b1;
     else if (rd_dst_rdy_n == 1'b0)
        // needed to wait till rd_dst_rdy is low to ensure penultimate byte of frame has
        // been accepted onto the interface before asserting eof and that
        // eof is accepted before moving on
        case (rd_state)
           EOF_s :
               rd_eof_n_int <= 1'b0;
           default :
              rd_eof_n_int <= 1'b1;
        endcase
           // queue sof is not needed if init value is 1
  end

  // register data outputs
  // no reset to allow for SRL target
  always @(posedge rd_clk)
  begin
     if (rd_en == 1'b1)
     begin
        rd_data_out  <= rd_data_pipe;
        rd_data_pipe <= rd_data_bram;
     end
  end

  // decode the output scr_rdy signal
  // want to remove the dependancy of src_rdy from dst rdy
  // check init value of this reg is 1'b1
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_src_rdy_n_int <= 1'b1;
     else
        case (rd_state)
           QUEUE_SOF_s :
              rd_src_rdy_n_int <= 1'b0;
           SOF_s :
              rd_src_rdy_n_int <= 1'b0;
           DATA_s :
              rd_src_rdy_n_int <= 1'b0;
           EOF_s :
              rd_src_rdy_n_int <= 1'b0;
           default :
              if (rd_dst_rdy_n == 1'b0)
                 rd_src_rdy_n_int <= 1'b1;
         endcase
  end


  // assign to rd_src_rd_n output
  assign rd_src_rdy_n = rd_src_rdy_n_int;

  // decode internal control signals
  // rd_en is used to enable the BRAM read and load the output pipe
  always @(rd_state or rd_dst_rdy_n)
  begin
     case (rd_state)
         WAIT_s :
              rd_en <= 1'b0;
         QUEUE1_s :
              rd_en <= 1'b1;
         QUEUE2_s :
              rd_en <= 1'b1;
         QUEUE3_s :
              rd_en <= 1'b1;
         QUEUE_SOF_s :
              rd_en <= 1'b1;
         default :
              rd_en <= !rd_dst_rdy_n;
         endcase
  end

  // rd_addr_inc is used to enable the BRAM read address to increment
  assign rd_addr_inc = rd_en;

  // When the current frame is output, if there is no frame in the fifo, then
  // the fifo must wait until a new frame is written in.  This requires the read
  // address to be moved back to where the new frame will be written.  The pipe
  // is then reloaded using the QUEUE states
  assign rd_addr_reload = (rd_state == EOF_s && rd_nxt_state == WAIT_s) ? 1'b1 : 1'b0;

  // Data is available if there is at leat one frame stored in the FIFO.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        frame_in_fifo <= 1'b0;
     else
        if (rd_frames != 9'b0)
           frame_in_fifo <= 1'b1;
        else
           frame_in_fifo <= 1'b0;
  end

  // when a frame has been stored need to convert to rd clock domain for frame
  // count store.
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        begin
           rd_store_frame_tog  <= 1'b0;
           rd_store_frame_sync <= 1'b0;
           rd_store_frame_delay <= 1'b0;
           rd_store_frame      <= 1'b0;
        end
     else
        begin
           rd_store_frame_tog  <= wr_store_frame_tog;
           rd_store_frame_sync <= rd_store_frame_tog;
           rd_store_frame_delay <= rd_store_frame_sync;
           // edge detector
           if ((rd_store_frame_delay ^ rd_store_frame_sync) == 1'b1)
              rd_store_frame    <= 1'b1;
           else
              rd_store_frame    <= 1'b0;
        end
  end

  assign rd_pull_frame = (rd_state == SOF_s && rd_nxt_state != SOF_s) ? 1'b1 :
                         (rd_state == QUEUE_SOF_s && rd_nxt_state != QUEUE_SOF_s) ? 1'b1 : 1'b0;

  // Up/Down counter to monitor the number of frames stored within the
  // the FIFO. Note:
  //    * decrements at the beginning of a frame read cycle
  //    * increments at the end of a frame write cycle
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_frames <= 9'b0;
     else
        // A frame is written to the fifo in this cycle, and no frame is being
        // read out on the same cycle
        if (rd_store_frame == 1'b1 && rd_pull_frame == 1'b0)
           rd_frames <= rd_frames + 9'b1;
        // A frame is being read out on this cycle and no frame is being
        // written on the same cycle
        else if (rd_store_frame == 1'b0 && rd_pull_frame == 1'b1)
           rd_frames <= rd_frames - 9'b1;
  end

  //---------------------------------------------------------------------------
  // Write state machines and control
  //---------------------------------------------------------------------------
  // write state machine
  // states are IDLE, FRAME, EOF, GF, BF, OVFLOW
  // clock state to next state
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_state <= IDLE_s;
     else if (wr_enable == 1'b1)
        wr_state <= wr_nxt_state;
  end

  // decode next state, combinatorial
  always @(wr_state or wr_dv_pipe[1] or wr_gf_pipe[1] or wr_bf_pipe[1] or wr_eof_bram[0] or wr_fifo_full)
  begin
     case (wr_state)
        IDLE_s : begin
           // there is data in the incoming pipeline when dv_pipe(1) goes high
           if (wr_dv_pipe[1] == 1'b1)
              wr_nxt_state <= FRAME_s;
           else
              wr_nxt_state <= IDLE_s;
           end
        FRAME_s : begin
              // if fifo is full then go to overflow state.
              // if the good or bad flag is detected the end
              // of the frame has been reached!
              // this transistion occurs when the gb flag
              // is on the clock edge immediately following
              // the end of the frame.
              // if the eof_bram signal is detected then data valid has
              // fallen low and the end of frame has been detected.
              if (wr_fifo_full == 1'b1)
                 wr_nxt_state <= OVFLOW_s;
              else if (wr_gf_pipe[1] == 1'b1)
                 wr_nxt_state <= GF_s;
              else if (wr_bf_pipe[1] == 1'b1)
                 wr_nxt_state <= BF_s;
              else if (wr_eof_bram[0] == 1'b1)
                 wr_nxt_state <= END_s;
              else
                 wr_nxt_state <= FRAME_s;
              end
           END_s : begin
              // if frame is full then go to overflow state
              // else wait until the good or bad flag has been received.
              if (wr_gf_pipe[1] == 1'b1)
                 wr_nxt_state <= GF_s;
              else if (wr_bf_pipe[1] == 1'b1)
                 wr_nxt_state <= BF_s;
              else
                 wr_nxt_state <= END_s;
              end
           GF_s : begin
              // wait for next frame
              wr_nxt_state <= IDLE_s;
              end
           BF_s : begin
              // wait for next frame
              wr_nxt_state <= IDLE_s;
              end
           OVFLOW_s : begin
              // wait until the good or bad flag received.
              if (wr_gf_pipe[1] == 1'b1 || wr_bf_pipe[1] == 1'b1)
                 wr_nxt_state <= IDLE_s;
              else
                 wr_nxt_state <= OVFLOW_s;
              end
           default : begin
              wr_nxt_state <= IDLE_s;
              end
        endcase
  end

  // decode control signals
  // wr_en is used to enable the BRAM write and loading of the input pipeline
  assign wr_en = (wr_state == FRAME_s) ? 1'b1 : 1'b0;

  // increment the write address when we are receiving a frame
  assign wr_addr_inc = (wr_state == FRAME_s) ? 1'b1 : 1'b0;

  // if the fifo overflows or a frame is to be dropped, we need to move the
  // write address back to the start of the frame.  This allows the data to be
  // overwritten.
  assign wr_addr_reload = (wr_state == BF_s || wr_state == OVFLOW_s) ? 1'b1 : 1'b0;

  // the start address is saved when in the WAIT state
  assign wr_start_addr_load = (wr_state == IDLE_s) ? 1'b1 : 1'b0;

  // we need to know when a frame is stored, in order to increment the count of
  // frames stored in the fifo.
  always @(posedge wr_clk)
  begin  // process
     if (wr_sreset == 1'b1)
        wr_store_frame_tog <= 1'b0;
     else if (wr_enable == 1'b1)
        if (wr_state == GF_s)
           wr_store_frame_tog <= ! wr_store_frame_tog;
  end

  //---------------------------------------------------------------------------
  // Address counters
  //---------------------------------------------------------------------------
  // write address is incremented when write enable signal has been asserted
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_addr <= 12'b0;
     else if (wr_enable == 1'b1)
        if (wr_addr_reload == 1'b1)
           wr_addr <= wr_start_addr;
        else if (wr_addr_inc == 1'b1)
           wr_addr <= wr_addr + 12'b1;
  end

  // store the start address
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_start_addr <= 12'b0;
     else if (wr_enable == 1'b1)
        if (wr_start_addr_load == 1'b1)
           wr_start_addr <= wr_addr;
  end

  // read address is incremented when read enable signal has been asserted
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr <= 12'b0;
     else
        if (rd_addr_reload == 1'b1)
           rd_addr <= rd_addr - 12'd2;
        else if (rd_addr_inc == 1'b1)
           rd_addr <= rd_addr + 12'b1;
  end

  //---------------------------------------------------------------------------
  // Data pipelines
  //---------------------------------------------------------------------------
  // register data inputs to bram
  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_enable == 1'b1)
        begin
           wr_data_pipe[0] <= rx_data;
           wr_data_pipe[1] <= wr_data_pipe[0];
           wr_data_bram    <= wr_data_pipe[1];
        end
  end

  // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_enable == 1'b1)
        begin
           wr_dv_pipe[0] <= rx_data_valid;
           wr_dv_pipe[1] <= wr_dv_pipe[0];
           wr_eof_bram[0] <= wr_dv_pipe[1] & !wr_dv_pipe[0];
        end
  end

   // no reset to allow srl16 target
  always @(posedge wr_clk)
  begin
     if (wr_enable == 1'b1)
        begin
           wr_gf_pipe[0] <= rx_good_frame;
           wr_gf_pipe[1] <= wr_gf_pipe[0];
           wr_bf_pipe[0] <= rx_bad_frame;
           wr_bf_pipe[1] <= wr_bf_pipe[0];
        end
  end

  //---------------------------------------------------------------------------
  // Overflow functionality
  //---------------------------------------------------------------------------
  // Take the Read Address Pointer and convert it into a grey code
  always @(posedge rd_clk)
  begin
     if (rd_sreset == 1'b1)
        rd_addr_gray <= 12'b0;
     else
        rd_addr_gray <= bin_to_gray(rd_addr);
  end

  // Resync the Read Address Pointer grey code onto the write clock
  // NOTE: rd_addr_gray signal crosses clock domains
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        begin
           wr_rd_addr_gray_sync <= 12'b0;
           wr_rd_addr_gray <= 12'b0;
        end
     else if (wr_enable == 1'b1)
        begin
           wr_rd_addr_gray_sync <= rd_addr_gray;
           wr_rd_addr_gray <= wr_rd_addr_gray_sync;
        end
  end

  // Convert the resync'd Read Address Pointer grey code back to binary
  assign wr_rd_addr = gray_to_bin(wr_rd_addr_gray);

  // Obtain the difference between write and read pointers
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_addr_diff <= 12'b0;
     else if (wr_enable == 1'b1)
        wr_addr_diff <= wr_rd_addr - wr_addr;
  end

  // Detect when the FIFO is full
  // The FIFO is considered to be full if the write address
  // pointer is within 0 to 3 of the read address pointer.
  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
        wr_fifo_full <= 1'b0;
     else if (wr_enable == 1'b1)
        if (wr_addr_diff[11:4] == 8'b0 && wr_addr_diff[3:2] != 2'b0)
           wr_fifo_full <= 1'b1;
        else
           wr_fifo_full <= 1'b0;
  end

  assign overflow = (wr_state == OVFLOW_s) ? 1'b1 : 1'b0;

  //--------------------------------------------------------------------
  // FIFO status signals
  //--------------------------------------------------------------------
  // The FIFO status signal is four bits which represents the occupancy
  // of the FIFO in 16'ths.  To generate this signal we therefore only
  // need to compare the 4 most significant bits of the write address
  // pointer with the 4 most significant bits of the read address
  // pointer.

  // already have fifo status on write side through wr_addr_diff.
  // calculate fifo status here and output on the wr clock domain.

  always @(posedge wr_clk)
  begin
     if (wr_sreset == 1'b1)
         wr_fifo_status <= 4'b0;
     else if (wr_enable == 1'b1)
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

  assign rx_fifo_status = wr_fifo_status;

  //---------------------------------------------------------------------------
  // Memory
  //---------------------------------------------------------------------------
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
    .ENBWREN       (rd_en),
    .CLKBWRCLK     (rd_clk),
    .RSTRAMB       (rd_sreset),
    .RSTREGB       (rd_sreset),
    .CASCADEINB    (GND),
    .REGCEB        (rd_en),
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
  assign rd_eof       = dopb_bram[0];

endmodule
