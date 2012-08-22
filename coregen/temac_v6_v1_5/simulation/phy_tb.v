//----------------------------------------------------------------------
// Title      : GMII Testbench
// Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
// File       : phy_tb.v
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
// Description: This testbench will exercise the PHY ports of the EMAC
//              to demonstrate the functionality.
//----------------------------------------------------------------------
//
// This testbench performs the following operations on the EMAC
// and its design example:
//
//  - Four frames are pushed into the receiver from the PHY
//    interface (GMII/MII):
//    The first is of minimum length (Length/Type = Length = 46 bytes).
//    The second frame sets Length/Type to Type = 0x8000.
//    The third frame has an error inserted.
//    The fourth frame only sends 4 bytes of data: the remainder of the
//    data field is padded up to the minimum frame length i.e. 46 bytes.
//
//  - These frames are then parsed from the MAC into the MAC's design
//    example.  The design example provides a MAC client loopback
//    function so that frames which are received without error will be
//    looped back to the MAC transmitter and transmitted back to the
//    testbench.  The testbench verifies that this data matches that
//    previously injected into the receiver.

`timescale 1ps / 1ps


// This module abstracts the frame data for simpler manipulation
module frame_typ;

   // data field
   reg [7:0]  data  [0:61];
   reg        valid [0:61];
   reg        error [0:61];

   // Indicate to the testbench that the frame contains an error
   reg        bad_frame;

`define FRAME_TYP [8*62+62+62+1:1]

   reg `FRAME_TYP bits;

   function `FRAME_TYP tobits;
      input dummy;
      begin
   bits = {data[ 0],  data[ 1],  data[ 2],  data[ 3],  data[ 4],
          data[ 5],  data[ 6],  data[ 7],  data[ 8],  data[ 9],
          data[10],  data[11],  data[12],  data[13],  data[14],
          data[15],  data[16],  data[17],  data[18],  data[19],
          data[20],  data[21],  data[22],  data[23],  data[24],
          data[25],  data[26],  data[27],  data[28],  data[29],
          data[30],  data[31],  data[32],  data[33],  data[34],
          data[35],  data[36],  data[37],  data[38],  data[39],
          data[40],  data[41],  data[42],  data[43],  data[44],
          data[45],  data[46],  data[47],  data[48],  data[49],
          data[50],  data[51],  data[52],  data[53],  data[54],
          data[55],  data[56],  data[57],  data[58],  data[59],
          data[60],  data[61],

          valid[ 0], valid[ 1], valid[ 2], valid[ 3], valid[ 4],
          valid[ 5], valid[ 6], valid[ 7], valid[ 8], valid[ 9],
          valid[10], valid[11], valid[12], valid[13], valid[14],
          valid[15], valid[16], valid[17], valid[18], valid[19],
          valid[20], valid[21], valid[22], valid[23], valid[24],
          valid[25], valid[26], valid[27], valid[28], valid[29],
          valid[30], valid[31], valid[32], valid[33], valid[34],
          valid[35], valid[36], valid[37], valid[38], valid[39],
          valid[40], valid[41], valid[42], valid[43], valid[44],
          valid[45], valid[46], valid[47], valid[48], valid[49],
          valid[50], valid[51], valid[52], valid[53], valid[54],
          valid[55], valid[56], valid[57], valid[58], valid[59],
          valid[60], valid[61],

          error[ 0], error[ 1], error[ 2], error[ 3], error[ 4],
          error[ 5], error[ 6], error[ 7], error[ 8], error[ 9],
          error[10], error[11], error[12], error[13], error[14],
          error[15], error[16], error[17], error[18], error[19],
          error[20], error[21], error[22], error[23], error[24],
          error[25], error[26], error[27], error[28], error[29],
          error[30], error[31], error[32], error[33], error[34],
          error[35], error[36], error[37], error[38], error[39],
          error[40], error[41], error[42], error[43], error[44],
          error[45], error[46], error[47], error[48], error[49],
          error[50], error[51], error[52], error[53], error[54],
          error[55], error[56], error[57], error[58], error[59],
          error[60], error[61],

          bad_frame};
   tobits = bits;
      end
   endfunction // tobits

   task frombits;
      input `FRAME_TYP frame;
      begin
   bits = frame;
          {data[ 0],  data[ 1],  data[ 2],  data[ 3],  data[ 4],
          data[ 5],  data[ 6],  data[ 7],  data[ 8],  data[ 9],
          data[10],  data[11],  data[12],  data[13],  data[14],
          data[15],  data[16],  data[17],  data[18],  data[19],
          data[20],  data[21],  data[22],  data[23],  data[24],
          data[25],  data[26],  data[27],  data[28],  data[29],
          data[30],  data[31],  data[32],  data[33],  data[34],
          data[35],  data[36],  data[37],  data[38],  data[39],
          data[40],  data[41],  data[42],  data[43],  data[44],
          data[45],  data[46],  data[47],  data[48],  data[49],
          data[50],  data[51],  data[52],  data[53],  data[54],
          data[55],  data[56],  data[57],  data[58],  data[59],
          data[60],  data[61],

          valid[ 0], valid[ 1], valid[ 2], valid[ 3], valid[ 4],
          valid[ 5], valid[ 6], valid[ 7], valid[ 8], valid[ 9],
          valid[10], valid[11], valid[12], valid[13], valid[14],
          valid[15], valid[16], valid[17], valid[18], valid[19],
          valid[20], valid[21], valid[22], valid[23], valid[24],
          valid[25], valid[26], valid[27], valid[28], valid[29],
          valid[30], valid[31], valid[32], valid[33], valid[34],
          valid[35], valid[36], valid[37], valid[38], valid[39],
          valid[40], valid[41], valid[42], valid[43], valid[44],
          valid[45], valid[46], valid[47], valid[48], valid[49],
          valid[50], valid[51], valid[52], valid[53], valid[54],
          valid[55], valid[56], valid[57], valid[58], valid[59],
          valid[60], valid[61],

          error[ 0], error[ 1], error[ 2], error[ 3], error[ 4],
          error[ 5], error[ 6], error[ 7], error[ 8], error[ 9],
          error[10], error[11], error[12], error[13], error[14],
          error[15], error[16], error[17], error[18], error[19],
          error[20], error[21], error[22], error[23], error[24],
          error[25], error[26], error[27], error[28], error[29],
          error[30], error[31], error[32], error[33], error[34],
          error[35], error[36], error[37], error[38], error[39],
          error[40], error[41], error[42], error[43], error[44],
          error[45], error[46], error[47], error[48], error[49],
          error[50], error[51], error[52], error[53], error[54],
          error[55], error[56], error[57], error[58], error[59],
          error[60], error[61],

          bad_frame} = bits;
      end
   endtask // frombits

endmodule // frame_typ


// This module is the GMII stimulus / monitor
module phy_tb
  (
    //----------------------------------------------------------------
    // GMII interface
    //----------------------------------------------------------------
    gmii_txd,
    gmii_tx_en,
    gmii_tx_er,
    gmii_tx_clk,
    gmii_rxd,
    gmii_rx_dv,
    gmii_rx_er,
    gmii_rx_clk,
    gmii_col,
    gmii_crs,
    mii_tx_clk,

    //----------------------------------------------------------------
    // Testbench semaphores
    //----------------------------------------------------------------
    configuration_busy,
    monitor_finished_1g,
    monitor_finished_100m,
    monitor_finished_10m,

    monitor_error
  );


  // Port declarations
  input  [7:0]     gmii_txd;
  input            gmii_tx_en;
  input            gmii_tx_er;
  input            gmii_tx_clk;
  output reg [7:0] gmii_rxd;
  output reg       gmii_rx_dv;
  output reg       gmii_rx_er;
  output           gmii_rx_clk;
  output           gmii_col;
  output           gmii_crs;
  output           mii_tx_clk;
  input            configuration_busy;
  output reg       monitor_finished_1g;
  output reg       monitor_finished_100m;
  output reg       monitor_finished_10m;
  output           monitor_error;


  //--------------------------------------------------------------------
  // Types to support frame data
  //--------------------------------------------------------------------

   frame_typ frame0();
   frame_typ frame1();
   frame_typ frame2();
   frame_typ frame3();

   frame_typ rx_stimulus_working_frame();
   frame_typ tx_monitor_working_frame();


  //--------------------------------------------------------------------
  // Stimulus - Frame data
  //--------------------------------------------------------------------
  // The following constant holds the stimulus for the testbench. It is
  // an ordered array of frames, with frame 0 the first to be injected
  // into the core transmit interface by the testbench.
  //--------------------------------------------------------------------
  initial
  begin
    //-----------
    // Frame 0
    //-----------
    frame0.data[0]  = 8'hDA;  frame0.valid[0]  = 1'b1;  frame0.error[0]  = 1'b0; // Destination Address (DA)
    frame0.data[1]  = 8'h02;  frame0.valid[1]  = 1'b1;  frame0.error[1]  = 1'b0;
    frame0.data[2]  = 8'h03;  frame0.valid[2]  = 1'b1;  frame0.error[2]  = 1'b0;
    frame0.data[3]  = 8'h04;  frame0.valid[3]  = 1'b1;  frame0.error[3]  = 1'b0;
    frame0.data[4]  = 8'h05;  frame0.valid[4]  = 1'b1;  frame0.error[4]  = 1'b0;
    frame0.data[5]  = 8'h06;  frame0.valid[5]  = 1'b1;  frame0.error[5]  = 1'b0;
    frame0.data[6]  = 8'h5A;  frame0.valid[6]  = 1'b1;  frame0.error[6]  = 1'b0; // Source Address (5A)
    frame0.data[7]  = 8'h02;  frame0.valid[7]  = 1'b1;  frame0.error[7]  = 1'b0;
    frame0.data[8]  = 8'h03;  frame0.valid[8]  = 1'b1;  frame0.error[8]  = 1'b0;
    frame0.data[9]  = 8'h04;  frame0.valid[9]  = 1'b1;  frame0.error[9]  = 1'b0;
    frame0.data[10] = 8'h05;  frame0.valid[10] = 1'b1;  frame0.error[10] = 1'b0;
    frame0.data[11] = 8'h06;  frame0.valid[11] = 1'b1;  frame0.error[11] = 1'b0;
    frame0.data[12] = 8'h00;  frame0.valid[12] = 1'b1;  frame0.error[12] = 1'b0;
    frame0.data[13] = 8'h2E;  frame0.valid[13] = 1'b1;  frame0.error[13] = 1'b0; // Length/Type = Length = 46
    frame0.data[14] = 8'h01;  frame0.valid[14] = 1'b1;  frame0.error[14] = 1'b0;
    frame0.data[15] = 8'h02;  frame0.valid[15] = 1'b1;  frame0.error[15] = 1'b0;
    frame0.data[16] = 8'h03;  frame0.valid[16] = 1'b1;  frame0.error[16] = 1'b0;
    frame0.data[17] = 8'h04;  frame0.valid[17] = 1'b1;  frame0.error[17] = 1'b0;
    frame0.data[18] = 8'h05;  frame0.valid[18] = 1'b1;  frame0.error[18] = 1'b0;
    frame0.data[19] = 8'h06;  frame0.valid[19] = 1'b1;  frame0.error[19] = 1'b0;
    frame0.data[20] = 8'h07;  frame0.valid[20] = 1'b1;  frame0.error[20] = 1'b0;
    frame0.data[21] = 8'h08;  frame0.valid[21] = 1'b1;  frame0.error[21] = 1'b0;
    frame0.data[22] = 8'h09;  frame0.valid[22] = 1'b1;  frame0.error[22] = 1'b0;
    frame0.data[23] = 8'h0A;  frame0.valid[23] = 1'b1;  frame0.error[23] = 1'b0;
    frame0.data[24] = 8'h0B;  frame0.valid[24] = 1'b1;  frame0.error[24] = 1'b0;
    frame0.data[25] = 8'h0C;  frame0.valid[25] = 1'b1;  frame0.error[25] = 1'b0;
    frame0.data[26] = 8'h0D;  frame0.valid[26] = 1'b1;  frame0.error[26] = 1'b0;
    frame0.data[27] = 8'h0E;  frame0.valid[27] = 1'b1;  frame0.error[27] = 1'b0;
    frame0.data[28] = 8'h0F;  frame0.valid[28] = 1'b1;  frame0.error[28] = 1'b0;
    frame0.data[29] = 8'h10;  frame0.valid[29] = 1'b1;  frame0.error[29] = 1'b0;
    frame0.data[30] = 8'h11;  frame0.valid[30] = 1'b1;  frame0.error[30] = 1'b0;
    frame0.data[31] = 8'h12;  frame0.valid[31] = 1'b1;  frame0.error[31] = 1'b0;
    frame0.data[32] = 8'h13;  frame0.valid[32] = 1'b1;  frame0.error[32] = 1'b0;
    frame0.data[33] = 8'h14;  frame0.valid[33] = 1'b1;  frame0.error[33] = 1'b0;
    frame0.data[34] = 8'h15;  frame0.valid[34] = 1'b1;  frame0.error[34] = 1'b0;
    frame0.data[35] = 8'h16;  frame0.valid[35] = 1'b1;  frame0.error[35] = 1'b0;
    frame0.data[36] = 8'h17;  frame0.valid[36] = 1'b1;  frame0.error[36] = 1'b0;
    frame0.data[37] = 8'h18;  frame0.valid[37] = 1'b1;  frame0.error[37] = 1'b0;
    frame0.data[38] = 8'h19;  frame0.valid[38] = 1'b1;  frame0.error[38] = 1'b0;
    frame0.data[39] = 8'h1A;  frame0.valid[39] = 1'b1;  frame0.error[39] = 1'b0;
    frame0.data[40] = 8'h1B;  frame0.valid[40] = 1'b1;  frame0.error[40] = 1'b0;
    frame0.data[41] = 8'h1C;  frame0.valid[41] = 1'b1;  frame0.error[41] = 1'b0;
    frame0.data[42] = 8'h1D;  frame0.valid[42] = 1'b1;  frame0.error[42] = 1'b0;
    frame0.data[43] = 8'h1E;  frame0.valid[43] = 1'b1;  frame0.error[43] = 1'b0;
    frame0.data[44] = 8'h1F;  frame0.valid[44] = 1'b1;  frame0.error[44] = 1'b0;
    frame0.data[45] = 8'h20;  frame0.valid[45] = 1'b1;  frame0.error[45] = 1'b0;
    frame0.data[46] = 8'h21;  frame0.valid[46] = 1'b1;  frame0.error[46] = 1'b0;
    frame0.data[47] = 8'h22;  frame0.valid[47] = 1'b1;  frame0.error[47] = 1'b0;
    frame0.data[48] = 8'h23;  frame0.valid[48] = 1'b1;  frame0.error[48] = 1'b0;
    frame0.data[49] = 8'h24;  frame0.valid[49] = 1'b1;  frame0.error[49] = 1'b0;
    frame0.data[50] = 8'h25;  frame0.valid[50] = 1'b1;  frame0.error[50] = 1'b0;
    frame0.data[51] = 8'h26;  frame0.valid[51] = 1'b1;  frame0.error[51] = 1'b0;
    frame0.data[52] = 8'h27;  frame0.valid[52] = 1'b1;  frame0.error[52] = 1'b0;
    frame0.data[53] = 8'h28;  frame0.valid[53] = 1'b1;  frame0.error[53] = 1'b0;
    frame0.data[54] = 8'h29;  frame0.valid[54] = 1'b1;  frame0.error[54] = 1'b0;
    frame0.data[55] = 8'h2A;  frame0.valid[55] = 1'b1;  frame0.error[55] = 1'b0;
    frame0.data[56] = 8'h2B;  frame0.valid[56] = 1'b1;  frame0.error[56] = 1'b0;
    frame0.data[57] = 8'h2C;  frame0.valid[57] = 1'b1;  frame0.error[57] = 1'b0;
    frame0.data[58] = 8'h2D;  frame0.valid[58] = 1'b1;  frame0.error[58] = 1'b0;
    frame0.data[59] = 8'h2E;  frame0.valid[59] = 1'b1;  frame0.error[59] = 1'b0; // 46th Byte of Data
    // unused
    frame0.data[60] = 8'h00;  frame0.valid[60] = 1'b0;  frame0.error[60] = 1'b0;
    frame0.data[61] = 8'h00;  frame0.valid[61] = 1'b0;  frame0.error[61] = 1'b0;

    // No error in this frame
    frame0.bad_frame  = 1'b0;


    //-----------
    // Frame 1
    //-----------
    frame1.data[0]  = 8'hDA;  frame1.valid[0]  = 1'b1;  frame1.error[0]  = 1'b0; // Destination Address (DA)
    frame1.data[1]  = 8'h02;  frame1.valid[1]  = 1'b1;  frame1.error[1]  = 1'b0;
    frame1.data[2]  = 8'h03;  frame1.valid[2]  = 1'b1;  frame1.error[2]  = 1'b0;
    frame1.data[3]  = 8'h04;  frame1.valid[3]  = 1'b1;  frame1.error[3]  = 1'b0;
    frame1.data[4]  = 8'h05;  frame1.valid[4]  = 1'b1;  frame1.error[4]  = 1'b0;
    frame1.data[5]  = 8'h06;  frame1.valid[5]  = 1'b1;  frame1.error[5]  = 1'b0;
    frame1.data[6]  = 8'h5A;  frame1.valid[6]  = 1'b1;  frame1.error[6]  = 1'b0; // Source Address (5A)
    frame1.data[7]  = 8'h02;  frame1.valid[7]  = 1'b1;  frame1.error[7]  = 1'b0;
    frame1.data[8]  = 8'h03;  frame1.valid[8]  = 1'b1;  frame1.error[8]  = 1'b0;
    frame1.data[9]  = 8'h04;  frame1.valid[9]  = 1'b1;  frame1.error[9]  = 1'b0;
    frame1.data[10] = 8'h05;  frame1.valid[10] = 1'b1;  frame1.error[10] = 1'b0;
    frame1.data[11] = 8'h06;  frame1.valid[11] = 1'b1;  frame1.error[11] = 1'b0;
    frame1.data[12] = 8'h80;  frame1.valid[12] = 1'b1;  frame1.error[12] = 1'b0; // Length/Type = Type = 8000
    frame1.data[13] = 8'h00;  frame1.valid[13] = 1'b1;  frame1.error[13] = 1'b0;
    frame1.data[14] = 8'h01;  frame1.valid[14] = 1'b1;  frame1.error[14] = 1'b0;
    frame1.data[15] = 8'h02;  frame1.valid[15] = 1'b1;  frame1.error[15] = 1'b0;
    frame1.data[16] = 8'h03;  frame1.valid[16] = 1'b1;  frame1.error[16] = 1'b0;
    frame1.data[17] = 8'h04;  frame1.valid[17] = 1'b1;  frame1.error[17] = 1'b0;
    frame1.data[18] = 8'h05;  frame1.valid[18] = 1'b1;  frame1.error[18] = 1'b0;
    frame1.data[19] = 8'h06;  frame1.valid[19] = 1'b1;  frame1.error[19] = 1'b0;
    frame1.data[20] = 8'h07;  frame1.valid[20] = 1'b1;  frame1.error[20] = 1'b0;
    frame1.data[21] = 8'h08;  frame1.valid[21] = 1'b1;  frame1.error[21] = 1'b0;
    frame1.data[22] = 8'h09;  frame1.valid[22] = 1'b1;  frame1.error[22] = 1'b0;
    frame1.data[23] = 8'h0A;  frame1.valid[23] = 1'b1;  frame1.error[23] = 1'b0;
    frame1.data[24] = 8'h0B;  frame1.valid[24] = 1'b1;  frame1.error[24] = 1'b0;
    frame1.data[25] = 8'h0C;  frame1.valid[25] = 1'b1;  frame1.error[25] = 1'b0;
    frame1.data[26] = 8'h0D;  frame1.valid[26] = 1'b1;  frame1.error[26] = 1'b0;
    frame1.data[27] = 8'h0E;  frame1.valid[27] = 1'b1;  frame1.error[27] = 1'b0;
    frame1.data[28] = 8'h0F;  frame1.valid[28] = 1'b1;  frame1.error[28] = 1'b0;
    frame1.data[29] = 8'h10;  frame1.valid[29] = 1'b1;  frame1.error[29] = 1'b0;
    frame1.data[30] = 8'h11;  frame1.valid[30] = 1'b1;  frame1.error[30] = 1'b0;
    frame1.data[31] = 8'h12;  frame1.valid[31] = 1'b1;  frame1.error[31] = 1'b0;
    frame1.data[32] = 8'h13;  frame1.valid[32] = 1'b1;  frame1.error[32] = 1'b0;
    frame1.data[33] = 8'h14;  frame1.valid[33] = 1'b1;  frame1.error[33] = 1'b0;
    frame1.data[34] = 8'h15;  frame1.valid[34] = 1'b1;  frame1.error[34] = 1'b0;
    frame1.data[35] = 8'h16;  frame1.valid[35] = 1'b1;  frame1.error[35] = 1'b0;
    frame1.data[36] = 8'h17;  frame1.valid[36] = 1'b1;  frame1.error[36] = 1'b0;
    frame1.data[37] = 8'h18;  frame1.valid[37] = 1'b1;  frame1.error[37] = 1'b0;
    frame1.data[38] = 8'h19;  frame1.valid[38] = 1'b1;  frame1.error[38] = 1'b0;
    frame1.data[39] = 8'h1A;  frame1.valid[39] = 1'b1;  frame1.error[39] = 1'b0;
    frame1.data[40] = 8'h1B;  frame1.valid[40] = 1'b1;  frame1.error[40] = 1'b0;
    frame1.data[41] = 8'h1C;  frame1.valid[41] = 1'b1;  frame1.error[41] = 1'b0;
    frame1.data[42] = 8'h1D;  frame1.valid[42] = 1'b1;  frame1.error[42] = 1'b0;
    frame1.data[43] = 8'h1E;  frame1.valid[43] = 1'b1;  frame1.error[43] = 1'b0;
    frame1.data[44] = 8'h1F;  frame1.valid[44] = 1'b1;  frame1.error[44] = 1'b0;
    frame1.data[45] = 8'h20;  frame1.valid[45] = 1'b1;  frame1.error[45] = 1'b0;
    frame1.data[46] = 8'h21;  frame1.valid[46] = 1'b1;  frame1.error[46] = 1'b0;
    frame1.data[47] = 8'h22;  frame1.valid[47] = 1'b1;  frame1.error[47] = 1'b0;
    frame1.data[48] = 8'h23;  frame1.valid[48] = 1'b1;  frame1.error[48] = 1'b0;
    frame1.data[49] = 8'h24;  frame1.valid[49] = 1'b1;  frame1.error[49] = 1'b0;
    frame1.data[50] = 8'h25;  frame1.valid[50] = 1'b1;  frame1.error[50] = 1'b0;
    frame1.data[51] = 8'h26;  frame1.valid[51] = 1'b1;  frame1.error[51] = 1'b0;
    frame1.data[52] = 8'h27;  frame1.valid[52] = 1'b1;  frame1.error[52] = 1'b0;
    frame1.data[53] = 8'h28;  frame1.valid[53] = 1'b1;  frame1.error[53] = 1'b0;
    frame1.data[54] = 8'h29;  frame1.valid[54] = 1'b1;  frame1.error[54] = 1'b0;
    frame1.data[55] = 8'h2A;  frame1.valid[55] = 1'b1;  frame1.error[55] = 1'b0;
    frame1.data[56] = 8'h2B;  frame1.valid[56] = 1'b1;  frame1.error[56] = 1'b0;
    frame1.data[57] = 8'h2C;  frame1.valid[57] = 1'b1;  frame1.error[57] = 1'b0;
    frame1.data[58] = 8'h2D;  frame1.valid[58] = 1'b1;  frame1.error[58] = 1'b0;
    frame1.data[59] = 8'h2E;  frame1.valid[59] = 1'b1;  frame1.error[59] = 1'b0;
    frame1.data[60] = 8'h2F;  frame1.valid[60] = 1'b1;  frame1.error[60] = 1'b0; // 47th Data byte
    // unused
    frame1.data[61] = 8'h00;  frame1.valid[61] = 1'b0;  frame1.error[61] = 1'b0;

    // No error in this frame
    frame1.bad_frame  = 1'b0;


    //-----------
    // Frame 2
    //-----------
    frame2.data[0]  = 8'hDA;  frame2.valid[0]  = 1'b1;  frame2.error[0]  = 1'b0; // Destination Address (DA)
    frame2.data[1]  = 8'h02;  frame2.valid[1]  = 1'b1;  frame2.error[1]  = 1'b0;
    frame2.data[2]  = 8'h03;  frame2.valid[2]  = 1'b1;  frame2.error[2]  = 1'b0;
    frame2.data[3]  = 8'h04;  frame2.valid[3]  = 1'b1;  frame2.error[3]  = 1'b0;
    frame2.data[4]  = 8'h05;  frame2.valid[4]  = 1'b1;  frame2.error[4]  = 1'b0;
    frame2.data[5]  = 8'h06;  frame2.valid[5]  = 1'b1;  frame2.error[5]  = 1'b0;
    frame2.data[6]  = 8'h5A;  frame2.valid[6]  = 1'b1;  frame2.error[6]  = 1'b0; // Source Address (5A)
    frame2.data[7]  = 8'h02;  frame2.valid[7]  = 1'b1;  frame2.error[7]  = 1'b0;
    frame2.data[8]  = 8'h03;  frame2.valid[8]  = 1'b1;  frame2.error[8]  = 1'b0;
    frame2.data[9]  = 8'h04;  frame2.valid[9]  = 1'b1;  frame2.error[9]  = 1'b0;
    frame2.data[10] = 8'h05;  frame2.valid[10] = 1'b1;  frame2.error[10] = 1'b0;
    frame2.data[11] = 8'h06;  frame2.valid[11] = 1'b1;  frame2.error[11] = 1'b0;
    frame2.data[12] = 8'h00;  frame2.valid[12] = 1'b1;  frame2.error[12] = 1'b0;
    frame2.data[13] = 8'h2E;  frame2.valid[13] = 1'b1;  frame2.error[13] = 1'b0; // Length/Type = Length = 46
    frame2.data[14] = 8'h01;  frame2.valid[14] = 1'b1;  frame2.error[14] = 1'b0;
    frame2.data[15] = 8'h02;  frame2.valid[15] = 1'b1;  frame2.error[15] = 1'b0;
    frame2.data[16] = 8'h03;  frame2.valid[16] = 1'b1;  frame2.error[16] = 1'b0;
    frame2.data[17] = 8'h00;  frame2.valid[17] = 1'b1;  frame2.error[17] = 1'b0; // Underrun this frame
    frame2.data[18] = 8'h00;  frame2.valid[18] = 1'b1;  frame2.error[18] = 1'b0;
    frame2.data[19] = 8'h00;  frame2.valid[19] = 1'b1;  frame2.error[19] = 1'b0;
    frame2.data[20] = 8'h00;  frame2.valid[20] = 1'b1;  frame2.error[20] = 1'b0;
    frame2.data[21] = 8'h00;  frame2.valid[21] = 1'b1;  frame2.error[21] = 1'b0;
    frame2.data[22] = 8'h00;  frame2.valid[22] = 1'b1;  frame2.error[22] = 1'b0;
    frame2.data[23] = 8'h00;  frame2.valid[23] = 1'b1;  frame2.error[23] = 1'b1; // Error asserted
    frame2.data[24] = 8'h00;  frame2.valid[24] = 1'b1;  frame2.error[24] = 1'b0;
    frame2.data[25] = 8'h00;  frame2.valid[25] = 1'b1;  frame2.error[25] = 1'b0;
    frame2.data[26] = 8'h00;  frame2.valid[26] = 1'b1;  frame2.error[26] = 1'b0;
    frame2.data[27] = 8'h00;  frame2.valid[27] = 1'b1;  frame2.error[27] = 1'b0;
    frame2.data[28] = 8'h00;  frame2.valid[28] = 1'b1;  frame2.error[28] = 1'b0;
    frame2.data[29] = 8'h00;  frame2.valid[29] = 1'b1;  frame2.error[29] = 1'b0;
    frame2.data[30] = 8'h00;  frame2.valid[30] = 1'b1;  frame2.error[30] = 1'b0;
    frame2.data[31] = 8'h00;  frame2.valid[31] = 1'b1;  frame2.error[31] = 1'b0;
    frame2.data[32] = 8'h00;  frame2.valid[32] = 1'b1;  frame2.error[32] = 1'b0;
    frame2.data[33] = 8'h00;  frame2.valid[33] = 1'b1;  frame2.error[33] = 1'b0;
    frame2.data[34] = 8'h00;  frame2.valid[34] = 1'b1;  frame2.error[34] = 1'b0;
    frame2.data[35] = 8'h00;  frame2.valid[35] = 1'b1;  frame2.error[35] = 1'b0;
    frame2.data[36] = 8'h00;  frame2.valid[36] = 1'b1;  frame2.error[36] = 1'b0;
    frame2.data[37] = 8'h00;  frame2.valid[37] = 1'b1;  frame2.error[37] = 1'b0;
    frame2.data[38] = 8'h00;  frame2.valid[38] = 1'b1;  frame2.error[38] = 1'b0;
    frame2.data[39] = 8'h00;  frame2.valid[39] = 1'b1;  frame2.error[39] = 1'b0;
    frame2.data[40] = 8'h00;  frame2.valid[40] = 1'b1;  frame2.error[40] = 1'b0;
    frame2.data[41] = 8'h00;  frame2.valid[41] = 1'b1;  frame2.error[41] = 1'b0;
    frame2.data[42] = 8'h00;  frame2.valid[42] = 1'b1;  frame2.error[42] = 1'b0;
    frame2.data[43] = 8'h00;  frame2.valid[43] = 1'b1;  frame2.error[43] = 1'b0;
    frame2.data[44] = 8'h00;  frame2.valid[44] = 1'b1;  frame2.error[44] = 1'b0;
    frame2.data[45] = 8'h00;  frame2.valid[45] = 1'b1;  frame2.error[45] = 1'b0;
    frame2.data[46] = 8'h00;  frame2.valid[46] = 1'b1;  frame2.error[46] = 1'b0;
    frame2.data[47] = 8'h00;  frame2.valid[47] = 1'b1;  frame2.error[47] = 1'b0;
    frame2.data[48] = 8'h00;  frame2.valid[48] = 1'b1;  frame2.error[48] = 1'b0;
    frame2.data[49] = 8'h00;  frame2.valid[49] = 1'b1;  frame2.error[49] = 1'b0;
    frame2.data[50] = 8'h00;  frame2.valid[50] = 1'b1;  frame2.error[50] = 1'b0;
    frame2.data[51] = 8'h00;  frame2.valid[51] = 1'b1;  frame2.error[51] = 1'b0;
    frame2.data[52] = 8'h00;  frame2.valid[52] = 1'b1;  frame2.error[52] = 1'b0;
    frame2.data[53] = 8'h00;  frame2.valid[53] = 1'b1;  frame2.error[53] = 1'b0;
    frame2.data[54] = 8'h00;  frame2.valid[54] = 1'b1;  frame2.error[54] = 1'b0;
    frame2.data[55] = 8'h00;  frame2.valid[55] = 1'b1;  frame2.error[55] = 1'b0;
    frame2.data[56] = 8'h00;  frame2.valid[56] = 1'b1;  frame2.error[56] = 1'b0;
    frame2.data[57] = 8'h00;  frame2.valid[57] = 1'b1;  frame2.error[57] = 1'b0;
    frame2.data[58] = 8'h00;  frame2.valid[58] = 1'b1;  frame2.error[58] = 1'b0;
    frame2.data[59] = 8'h00;  frame2.valid[59] = 1'b1;  frame2.error[59] = 1'b0;
    // unused
    frame2.data[60] = 8'h00;  frame2.valid[60] = 1'b0;  frame2.error[60] = 1'b0;
    frame2.data[61] = 8'h00;  frame2.valid[61] = 1'b0;  frame2.error[61] = 1'b0;

    // Error this frame
    frame2.bad_frame  = 1'b1;


    //-----------
    // Frame 3
    //-----------
    frame3.data[0]  = 8'hDA;  frame3.valid[0]  = 1'b1;  frame3.error[0]  = 1'b0; // Destination Address (DA)
    frame3.data[1]  = 8'h02;  frame3.valid[1]  = 1'b1;  frame3.error[1]  = 1'b0;
    frame3.data[2]  = 8'h03;  frame3.valid[2]  = 1'b1;  frame3.error[2]  = 1'b0;
    frame3.data[3]  = 8'h04;  frame3.valid[3]  = 1'b1;  frame3.error[3]  = 1'b0;
    frame3.data[4]  = 8'h05;  frame3.valid[4]  = 1'b1;  frame3.error[4]  = 1'b0;
    frame3.data[5]  = 8'h06;  frame3.valid[5]  = 1'b1;  frame3.error[5]  = 1'b0;
    frame3.data[6]  = 8'h5A;  frame3.valid[6]  = 1'b1;  frame3.error[6]  = 1'b0; // Source Address (5A)
    frame3.data[7]  = 8'h02;  frame3.valid[7]  = 1'b1;  frame3.error[7]  = 1'b0;
    frame3.data[8]  = 8'h03;  frame3.valid[8]  = 1'b1;  frame3.error[8]  = 1'b0;
    frame3.data[9]  = 8'h04;  frame3.valid[9]  = 1'b1;  frame3.error[9]  = 1'b0;
    frame3.data[10] = 8'h05;  frame3.valid[10] = 1'b1;  frame3.error[10] = 1'b0;
    frame3.data[11] = 8'h06;  frame3.valid[11] = 1'b1;  frame3.error[11] = 1'b0;
    frame3.data[12] = 8'h00;  frame3.valid[12] = 1'b1;  frame3.error[12] = 1'b0;
    frame3.data[13] = 8'h03;  frame3.valid[13] = 1'b1;  frame3.error[13] = 1'b0; // Length/Type = Length = 03
    frame3.data[14] = 8'h01;  frame3.valid[14] = 1'b1;  frame3.error[14] = 1'b0; // Therefore padding is required
    frame3.data[15] = 8'h02;  frame3.valid[15] = 1'b1;  frame3.error[15] = 1'b0;
    frame3.data[16] = 8'h03;  frame3.valid[16] = 1'b1;  frame3.error[16] = 1'b0;
    frame3.data[17] = 8'h00;  frame3.valid[17] = 1'b1;  frame3.error[17] = 1'b0; // Padding starts here
    frame3.data[18] = 8'h00;  frame3.valid[18] = 1'b1;  frame3.error[18] = 1'b0;
    frame3.data[19] = 8'h00;  frame3.valid[19] = 1'b1;  frame3.error[19] = 1'b0;
    frame3.data[20] = 8'h00;  frame3.valid[20] = 1'b1;  frame3.error[20] = 1'b0;
    frame3.data[21] = 8'h00;  frame3.valid[21] = 1'b1;  frame3.error[21] = 1'b0;
    frame3.data[22] = 8'h00;  frame3.valid[22] = 1'b1;  frame3.error[22] = 1'b0;
    frame3.data[23] = 8'h00;  frame3.valid[23] = 1'b1;  frame3.error[23] = 1'b0;
    frame3.data[24] = 8'h00;  frame3.valid[24] = 1'b1;  frame3.error[24] = 1'b0;
    frame3.data[25] = 8'h00;  frame3.valid[25] = 1'b1;  frame3.error[25] = 1'b0;
    frame3.data[26] = 8'h00;  frame3.valid[26] = 1'b1;  frame3.error[26] = 1'b0;
    frame3.data[27] = 8'h00;  frame3.valid[27] = 1'b1;  frame3.error[27] = 1'b0;
    frame3.data[28] = 8'h00;  frame3.valid[28] = 1'b1;  frame3.error[28] = 1'b0;
    frame3.data[29] = 8'h00;  frame3.valid[29] = 1'b1;  frame3.error[29] = 1'b0;
    frame3.data[30] = 8'h00;  frame3.valid[30] = 1'b1;  frame3.error[30] = 1'b0;
    frame3.data[31] = 8'h00;  frame3.valid[31] = 1'b1;  frame3.error[31] = 1'b0;
    frame3.data[32] = 8'h00;  frame3.valid[32] = 1'b1;  frame3.error[32] = 1'b0;
    frame3.data[33] = 8'h00;  frame3.valid[33] = 1'b1;  frame3.error[33] = 1'b0;
    frame3.data[34] = 8'h00;  frame3.valid[34] = 1'b1;  frame3.error[34] = 1'b0;
    frame3.data[35] = 8'h00;  frame3.valid[35] = 1'b1;  frame3.error[35] = 1'b0;
    frame3.data[36] = 8'h00;  frame3.valid[36] = 1'b1;  frame3.error[36] = 1'b0;
    frame3.data[37] = 8'h00;  frame3.valid[37] = 1'b1;  frame3.error[37] = 1'b0;
    frame3.data[38] = 8'h00;  frame3.valid[38] = 1'b1;  frame3.error[38] = 1'b0;
    frame3.data[39] = 8'h00;  frame3.valid[39] = 1'b1;  frame3.error[39] = 1'b0;
    frame3.data[40] = 8'h00;  frame3.valid[40] = 1'b1;  frame3.error[40] = 1'b0;
    frame3.data[41] = 8'h00;  frame3.valid[41] = 1'b1;  frame3.error[41] = 1'b0;
    frame3.data[42] = 8'h00;  frame3.valid[42] = 1'b1;  frame3.error[42] = 1'b0;
    frame3.data[43] = 8'h00;  frame3.valid[43] = 1'b1;  frame3.error[43] = 1'b0;
    frame3.data[44] = 8'h00;  frame3.valid[44] = 1'b1;  frame3.error[44] = 1'b0;
    frame3.data[45] = 8'h00;  frame3.valid[45] = 1'b1;  frame3.error[45] = 1'b0;
    frame3.data[46] = 8'h00;  frame3.valid[46] = 1'b1;  frame3.error[46] = 1'b0;
    frame3.data[47] = 8'h00;  frame3.valid[47] = 1'b1;  frame3.error[47] = 1'b0;
    frame3.data[48] = 8'h00;  frame3.valid[48] = 1'b1;  frame3.error[48] = 1'b0;
    frame3.data[49] = 8'h00;  frame3.valid[49] = 1'b1;  frame3.error[49] = 1'b0;
    frame3.data[50] = 8'h00;  frame3.valid[50] = 1'b1;  frame3.error[50] = 1'b0;
    frame3.data[51] = 8'h00;  frame3.valid[51] = 1'b1;  frame3.error[51] = 1'b0;
    frame3.data[52] = 8'h00;  frame3.valid[52] = 1'b1;  frame3.error[52] = 1'b0;
    frame3.data[53] = 8'h00;  frame3.valid[53] = 1'b1;  frame3.error[53] = 1'b0;
    frame3.data[54] = 8'h00;  frame3.valid[54] = 1'b1;  frame3.error[54] = 1'b0;
    frame3.data[55] = 8'h00;  frame3.valid[55] = 1'b1;  frame3.error[55] = 1'b0;
    frame3.data[56] = 8'h00;  frame3.valid[56] = 1'b1;  frame3.error[56] = 1'b0;
    frame3.data[57] = 8'h00;  frame3.valid[57] = 1'b1;  frame3.error[57] = 1'b0;
    frame3.data[58] = 8'h00;  frame3.valid[58] = 1'b1;  frame3.error[58] = 1'b0;
    frame3.data[59] = 8'h00;  frame3.valid[59] = 1'b1;  frame3.error[59] = 1'b0;
    // unused
    frame3.data[60] = 8'h00;  frame3.valid[60] = 1'b0;  frame3.error[60] = 1'b0;
    frame3.data[61] = 8'h00;  frame3.valid[61] = 1'b0;  frame3.error[61] = 1'b0;

    // No error in this frame
    frame3.bad_frame  = 1'b0;

  end


  //--------------------------------------------------------------------
  // CRC engine
  //--------------------------------------------------------------------
  task calc_crc;
    input  [7:0]  data;
    inout  [31:0] fcs;

    reg [31:0] crc;
    reg        crc_feedback;
    integer    I;
  begin

    crc = ~ fcs;

    for (I = 0; I < 8; I = I + 1)
    begin
      crc_feedback = crc[0] ^ data[I];

      crc[0]       = crc[1];
      crc[1]       = crc[2];
      crc[2]       = crc[3];
      crc[3]       = crc[4];
      crc[4]       = crc[5];
      crc[5]       = crc[6]  ^ crc_feedback;
      crc[6]       = crc[7];
      crc[7]       = crc[8];
      crc[8]       = crc[9]  ^ crc_feedback;
      crc[9]       = crc[10] ^ crc_feedback;
      crc[10]      = crc[11];
      crc[11]      = crc[12];
      crc[12]      = crc[13];
      crc[13]      = crc[14];
      crc[14]      = crc[15];
      crc[15]      = crc[16] ^ crc_feedback;
      crc[16]      = crc[17];
      crc[17]      = crc[18];
      crc[18]      = crc[19];
      crc[19]      = crc[20] ^ crc_feedback;
      crc[20]      = crc[21] ^ crc_feedback;
      crc[21]      = crc[22] ^ crc_feedback;
      crc[22]      = crc[23];
      crc[23]      = crc[24] ^ crc_feedback;
      crc[24]      = crc[25] ^ crc_feedback;
      crc[25]      = crc[26];
      crc[26]      = crc[27] ^ crc_feedback;
      crc[27]      = crc[28] ^ crc_feedback;
      crc[28]      = crc[29];
      crc[29]      = crc[30] ^ crc_feedback;
      crc[30]      = crc[31] ^ crc_feedback;
      crc[31]      =           crc_feedback;
    end

    // return the CRC result
    fcs = ~ crc;

    end
  endtask // calc_crc


  // Delay to provide setup and hold timing at the GMII/MII.
  parameter dly = 2000;  // 2 ns;

  // Testbench signals
  reg mii_tx_clk_int;
  reg mii_tx_clk100;
  reg mii_tx_clk10;

  reg gmii_rx_clk_int;
  reg gmii_rx_clk1000;
  reg gmii_rx_clk100;
  reg gmii_rx_clk10;

  // Testbench control signals
  reg [1:0] current_speed;

  reg clkmux_en_100;
  reg clkmux_en_10;

  reg monitor_error_1g;
  reg monitor_error_100m;
  reg monitor_error_10m;

  // Currently not used in this testbench.
  assign gmii_col = 1'b0;
  assign gmii_crs = 1'b0;

  assign monitor_error = (monitor_error_1g   === 1'b1 ||
                          monitor_error_100m === 1'b1 ||
                          monitor_error_10m  === 1'b1);
  assign mii_tx_clk = mii_tx_clk_int;


  //--------------------------------------------------------------------
  // gmii_rx_clk clock driver
  //--------------------------------------------------------------------

  // Drives gmii_rx_clk at 125 MHz for 1000Mb/s operation
  initial
  begin
    gmii_rx_clk_int <= 1'b0;
    #20000;
    forever
    begin
      #4000;
      gmii_rx_clk_int <= 1'b1;
      #4000;
      gmii_rx_clk_int <= 1'b0;
    end
  end

  assign gmii_rx_clk = gmii_rx_clk_int;


  //--------------------------------------------------------------------
  // Simulus process
  //----------------
  // Send four frames through the MAC and Design Example
  //      -- frame 0 = minimum length frame
  //      -- frame 1 = type frame
  //      -- frame 2 = errored frame
  //      -- frame 3 = padded frame
  //--------------------------------------------------------------------


  //---------------------------------------------------
  //  A task to inject the current frame at 1G/s
  //---------------------------------------------------
  task rx_stimulus_send_frame_1g;
    input   `FRAME_TYP frame;
    input   integer frame_number;
    integer column_index;
    reg [31:0] fcs;
    integer I;
    begin
      // import the frame into scratch space
      rx_stimulus_working_frame.frombits(frame);

   column_index = 0;
      @(posedge gmii_rx_clk_int);

      $display("EMAC: Sending Frame %d at 1Gb/s", frame_number);

      // Adding the preamble field
      for (I = 0; I < 7; I = I + 1)
      begin
        #dly;
        gmii_rxd   <= 8'h55;
        gmii_rx_dv <= 1'b1;
        @(posedge gmii_rx_clk_int);
      end

      // Adding the Start of Frame Delimiter (SFD)
      #dly;
      gmii_rxd   <= 8'hD5;
      gmii_rx_dv <= 1'b1;
      fcs = 32'h0; // reset the FCS field
      @(posedge gmii_rx_clk_int);

      // Sending the MAC frame
      while (rx_stimulus_working_frame.valid[column_index] !== 1'b0)
      begin
        // send one column of data
        calc_crc(rx_stimulus_working_frame.data[column_index], fcs);
        #dly;
        gmii_rxd    <= rx_stimulus_working_frame.data[column_index];
        gmii_rx_dv  <= rx_stimulus_working_frame.valid[column_index];
        gmii_rx_er  <= rx_stimulus_working_frame.error[column_index];
        column_index = column_index + 1;
        @(posedge gmii_rx_clk_int);
   end

      // Send the FCS.
      #dly;
      gmii_rxd    <= fcs[7:0];
      gmii_rx_dv  <= 1'b1;
      gmii_rx_er  <= 1'b0;
      @(posedge gmii_rx_clk_int);
      #dly;
      gmii_rxd    <= fcs[15:8];
      @(posedge gmii_rx_clk_int);
      #dly;
      gmii_rxd    <= fcs[23:16];
      @(posedge gmii_rx_clk_int);
      #dly;
      gmii_rxd    <= fcs[31:24];
      @(posedge gmii_rx_clk_int);

      // Clear the data lines.
      #dly;
      gmii_rxd       <= 8'h0;
      gmii_rx_dv     <= 1'b0;

      // Adding the minimum Interframe gap for a receiver (8 idles)
      for (I = 0; I < 7; I = I + 1)
        @(posedge gmii_rx_clk_int);

    end
  endtask // rx_stimulus_send_frame_1g;
  //---------------------------------------------------
  // Inject the frames into the GMII receiver
  //---------------------------------------------------
  initial
  begin : p_rx_stimulus

    // Initialise stimulus
    gmii_rxd       = 8'h0;
    gmii_rx_dv     = 1'b0;
    gmii_rx_er     = 1'b0;

    // Initialize clock mux enables
    clkmux_en_100  = 1'b0;
    clkmux_en_10   = 1'b0;

    // Wait for the configuration to initialise the MAC
    wait (configuration_busy == 1);
    wait (configuration_busy == 0);

    //----------------------------------
    // Send frames at 1Gb/s speed
    //----------------------------------

    current_speed <= 2'b10;  // 1G/s

    clkmux_en_100 <= 1'b0;
    clkmux_en_10  <= 1'b0;

    rx_stimulus_send_frame_1g(frame0.tobits(0), 0);
    rx_stimulus_send_frame_1g(frame1.tobits(1), 1);
    rx_stimulus_send_frame_1g(frame2.tobits(2), 2);
    rx_stimulus_send_frame_1g(frame3.tobits(3), 3);

    // Our work here is done

  end // p_rx_stimulus


  //--------------------------------------------------------------------
  // Monitor process
  //----------------
  // This process checks the data coming out of the
  // transmitter to make sure that it matches that inserted into the
  // receiver.
  //      -- frame 0 = minimum length frame
  //      -- frame 1 = type frame
  //      -- frame 2 = errored frame
  //      -- frame 3 = padded frame
  //
  // Repeated for all 3 speeds.
  //--------------------------------------------------------------------


  //---------------------------------------------------
  // A task to compare the current frame being
  // transmitted with the injected frame at 1G/s
  //---------------------------------------------------
  task tx_monitor_check_frame_1g;
    input `FRAME_TYP frame;
    input  integer frame_number;
    integer column_index;
    reg [31:0] fcs;
    integer I;
  begin
    $timeformat(-9, 0, "ns", 7);

    // import the frame into scratch space
    tx_monitor_working_frame.frombits(frame);

    column_index = 0;
    @(posedge gmii_tx_clk)

    // If the current frame had an error inserted then it would have
    // been dropped by the FIFO in the design example.  Therefore
    // exit this task and move immediately on to the next frame.
    if (tx_monitor_working_frame.bad_frame !== 1'b1)
    begin

      // wait until the first real column of data to come out of RX client
      while (gmii_tx_en !== 1'b1)
        @(posedge gmii_tx_clk);

      // Parse over the preamble field
      while (gmii_txd === 8'h55)
        @(posedge gmii_tx_clk);

      $display("EMAC: Comparing Frame %d at 1Gb/s", frame_number);

      // Parse over the Start of Frame Delimiter (SFD)
      @(posedge gmii_tx_clk);

      fcs = 32'h0; // reset the FCS field

      // frame has started, loop over columns of frame
      while (tx_monitor_working_frame.valid[column_index] !== 1'b0)
      begin

        // The transmitted Destination Address was the Source Address
        // of the injected frame
        if (column_index < 6)
        begin
          calc_crc(tx_monitor_working_frame.data[column_index+6], fcs);
          if (gmii_tx_en !== tx_monitor_working_frame.valid[column_index+6])
          begin
            $display("** ERROR: gmii_tx_en incorrect during Destination Address at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end

          if (gmii_txd !== tx_monitor_working_frame.data[(column_index+6)])
          begin
            $display("** ERROR: gmii_txd incorrect during Destination Address at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end
        end

        // The transmitted Source Address was the Destination Address
        // of the injected frame
        else if (column_index < 12)
        begin
          calc_crc(tx_monitor_working_frame.data[column_index-6], fcs);
          if (gmii_tx_en !== tx_monitor_working_frame.valid[column_index-6])
          begin
            $display("** ERROR: gmii_tx_en incorrect during Source Address at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end

          if (gmii_txd !== tx_monitor_working_frame.data[(column_index-6)])
          begin
            $display("** ERROR: gmii_txd incorrect during Source Address at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end
        end

        // for remainder of frame
        else
        begin
          calc_crc(tx_monitor_working_frame.data[column_index], fcs);
          if (gmii_tx_en !== tx_monitor_working_frame.valid[column_index])
          begin
            $display("** ERROR: gmii_tx_en incorrect at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end

          if (gmii_txd !== tx_monitor_working_frame.data[column_index])
          begin
            $display("** ERROR: gmii_txd incorrect at %t", $realtime);
            monitor_error_1g <= 1'b1;
          end
        end

        // wait for next column of data
        column_index = column_index + 1;
        @(posedge gmii_tx_clk);
      end

      // Check the FCS
      // Having checked all data columns, txd must contain FCS.
      if (gmii_txd !== fcs[7:0])
      begin
        $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime);
        monitor_error_1g <= 1'b1;
      end
      @(posedge gmii_tx_clk);

      if (gmii_txd !== fcs[15:8])
      begin
        $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime);
        monitor_error_1g <= 1'b1;
      end
      @(posedge gmii_tx_clk);

      if (gmii_txd !== fcs[23:16])
      begin
        $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime);
        monitor_error_1g <= 1'b1;
      end
      @(posedge gmii_tx_clk);

      if (gmii_txd !== fcs[31:24])
      begin
        $display("** ERROR: gmii_txd incorrect during FCS field at %t", $realtime);
        monitor_error_1g <= 1'b1;
      end
      @(posedge gmii_tx_clk);

    end
   end
  endtask // tx_monitor_check_frame_1g
  //---------------------------------------------------
  // Monitor the frames from the GMII transmitter
  //---------------------------------------------------
  initial
  begin : p_tx_monitor
    monitor_finished_1g   <= 0;
    monitor_finished_100m <= 0;
    monitor_finished_10m  <= 0;

    // first, get synced up with the TX clock
    @(posedge gmii_tx_clk)
    @(posedge gmii_tx_clk)

    //----------------------------------
    // Compare the frames at 1Gb/s speed
    //----------------------------------

    // parse all the frames in the stimulus vector
    tx_monitor_check_frame_1g(frame0.tobits(0), 0);
    tx_monitor_check_frame_1g(frame1.tobits(0), 1);
    tx_monitor_check_frame_1g(frame2.tobits(0), 2);
    tx_monitor_check_frame_1g(frame3.tobits(0), 3);

    monitor_finished_1g  <= 1;

  end // p_tx_monitor


endmodule
