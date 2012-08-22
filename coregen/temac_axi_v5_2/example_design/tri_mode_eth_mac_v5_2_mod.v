//------------------------------------------------------------------------------
// File       : tri_mode_eth_mac_v5_2_mod.v
// Author     : Xilinx Inc.
//------------------------------------------------------------------------------
// Description: This package holds the top level component declaration
//              for the Tri-Mode Ethernet MAC core.
// -----------------------------------------------------------------------------
// (c) Copyright 2002-2008 Xilinx, Inc. All rights reserved.
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


module tri_mode_eth_mac_v5_2
  (
      //---------------------------------------
      // asynchronous reset
      input           glbl_rstn,  
      input           rx_axi_rstn,
      input           tx_axi_rstn,


      //---------------------------------------
      // Receiver Interface
      input           rx_axi_clk,
      output          rx_reset_out, 
      output [7:0]    rx_axis_mac_tdata, 
      output          rx_axis_mac_tvalid,
      output          rx_axis_mac_tlast, 
      output          rx_axis_mac_tuser, 
      // Receiver Statistics
      output [27:0]   rx_statistics_vector,
      output          rx_statistics_valid,

      //---------------------------------------
      // Transmitter Interface
      input           tx_axi_clk,
      output          tx_reset_out, 
      input  [7:0]    tx_axis_mac_tdata, 
      input           tx_axis_mac_tvalid,
      input           tx_axis_mac_tlast, 
      input           tx_axis_mac_tuser,
      output          tx_axis_mac_tready,
      
      output          tx_retransmit,
      output          tx_collision,
      input  [7:0]    tx_ifg_delay,
      // Transmitter Statistics
      output [31:0]   tx_statistics_vector,
      output          tx_statistics_valid,
      
      //---------------------------------------
      // MAC Control Interface
      input           pause_req,
      input  [15:0]   pause_val,
     
      //---------------------------------------
      // Current Speed Indication
      output          speed_is_100,
      output          speed_is_10_100,

      //---------------------------------------
      // Physical Interface of the core

      output [7:0]    gmii_txd,
      output          gmii_tx_en,
      output          gmii_tx_er,
      input           gmii_col,
      input           gmii_crs,
      input  [7:0]    gmii_rxd,
      input           gmii_rx_dv,
      input           gmii_rx_er,

      // MDIO Interface
      output          mdc_out,
      input           mdio_in,
      output          mdio_out,
      output          mdio_tri,

      //---------------------------------------
      // IPIC Interface
      input           bus2ip_clk,
      input           bus2ip_reset,
      input  [31:0]   bus2ip_addr,
      input           bus2ip_cs,
      input           bus2ip_rdce,
      input           bus2ip_wrce,
      input  [31:0]   bus2ip_data,
      output [31:0]   ip2bus_data,
      output          ip2bus_wrack,
      output          ip2bus_rdack,
      output          ip2bus_error,
      output          mac_irq

  );



endmodule // tri_mode_eth_mac_v5_2
   
