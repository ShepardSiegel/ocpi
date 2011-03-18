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
// File       : PIO.v
// Version    : 1.1
//
// Description:  Programmed I/O module. Design implements 8 KBytes of programmable
//--              memory space. Host processor can access this memory space using
//--              Memory Read 32 and Memory Write 32 TLPs. Design accepts
//--              1 Double Word (DW) payload length on Memory Write 32 TLP and
//--              responds to 1 DW length Memory Read 32 TLPs with a Completion
//--              with Data TLP (1DW payload).
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module PIO #(
  parameter C_DATA_WIDTH = 64,            // RX/TX interface data width

  // Do not override parameters below this line
  parameter STRB_WIDTH = C_DATA_WIDTH / 8               // TSTRB width
)(
  input                         user_clk,
  input                         user_reset,
  input                         user_lnk_up,

  // AXIS
  input                         s_axis_tx_tready,
  output  [C_DATA_WIDTH-1:0]    s_axis_tx_tdata,
  output  [STRB_WIDTH-1:0]      s_axis_tx_tstrb,
  output                        s_axis_tx_tlast,
  output                        s_axis_tx_tvalid,
  output                        tx_src_dsc,


  input  [C_DATA_WIDTH-1:0]     m_axis_rx_tdata,
  input  [STRB_WIDTH-1:0]       m_axis_rx_tstrb,
  input                         m_axis_rx_tlast,
  input                         m_axis_rx_tvalid,
  output                        m_axis_rx_tready,
  input    [21:0]               m_axis_rx_tuser,


  input                         cfg_to_turnoff,
  output                        cfg_turnoff_ok,

  input [15:0]                  cfg_completer_id,
  input                         cfg_bus_mstr_enable

  ); // synthesis syn_hier = "hard"


    // Local wires

    wire          req_compl;
    wire          compl_done;
    wire          pio_reset_n = user_lnk_up && !user_reset;


    //
    // PIO instance
    //

  PIO_EP  #(
    .C_DATA_WIDTH( C_DATA_WIDTH ),
    .STRB_WIDTH( STRB_WIDTH )
  ) PIO_EP (

    .clk( user_clk ),                             // I
    .rst_n( pio_reset_n ),                        // I

    .s_axis_tx_tready( s_axis_tx_tready ),        // I
    .s_axis_tx_tdata( s_axis_tx_tdata ),          // O
    .s_axis_tx_tstrb( s_axis_tx_tstrb ),          // O
    .s_axis_tx_tlast( s_axis_tx_tlast ),          // O
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),        // O
    .tx_src_dsc( tx_src_dsc ),                    // O

    .m_axis_rx_tdata( m_axis_rx_tdata ),          // I
    .m_axis_rx_tstrb( m_axis_rx_tstrb ),          // I
    .m_axis_rx_tlast( m_axis_rx_tlast ),          // I
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),        // I
    .m_axis_rx_tready( m_axis_rx_tready ),        // O
    .m_axis_rx_tuser ( m_axis_rx_tuser ),         // I

    .req_compl_o(req_compl),                      // O
    .compl_done_o(compl_done),                    // O

    .cfg_completer_id ( cfg_completer_id ),       // I [15:0]
    .cfg_bus_mstr_enable ( cfg_bus_mstr_enable )  // I
);


    //
    // Turn-Off controller
    //

  PIO_TO_CTRL PIO_TO  (
    .clk( user_clk ),                       // I
    .rst_n( pio_reset_n ),                  // I

    .req_compl_i( req_compl ),              // I
    .compl_done_i( compl_done ),            // I

    .cfg_to_turnoff( cfg_to_turnoff ),      // I
    .cfg_turnoff_ok( cfg_turnoff_ok )       // O
  );


endmodule // PIO

