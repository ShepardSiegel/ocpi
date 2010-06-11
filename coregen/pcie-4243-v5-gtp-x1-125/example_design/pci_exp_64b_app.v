
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
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
// Project    : V5-Block Plus for PCI Express
// File       : pci_exp_64b_app.v
//
// Description:  PCI Express Endpoint Core 64 bit interface sample application
//              design.
//
//------------------------------------------------------------------------------

module  pci_exp_64b_app (

                        trn_clk,
                        trn_reset_n,
                        trn_lnk_up_n,

                        trn_td,
                        trn_trem,
                        trn_tsof_n,
                        trn_teof_n,
                        trn_tsrc_rdy_n,
                        trn_tdst_rdy_n,
                        trn_tsrc_dsc_n,
                        trn_tdst_dsc_n,
                        trn_terrfwd_n,
                        trn_tbuf_av,

                        trn_rd,
                        trn_rrem,
                        trn_rsof_n,
                        trn_reof_n,
                        trn_rsrc_rdy_n,
                        trn_rsrc_dsc_n,
                        trn_rdst_rdy_n,
                        trn_rerrfwd_n,
                        trn_rnp_ok_n,
                        trn_rbar_hit_n,
                        trn_rfc_nph_av,
                        trn_rfc_npd_av,
                        trn_rfc_ph_av,
                        trn_rfc_pd_av,

                        trn_rcpl_streaming_n, 

                        cfg_do,
                        cfg_rd_wr_done_n,
                        cfg_di,
                        cfg_byte_en_n,
                        cfg_dwaddr,
                        cfg_wr_en_n,
                        cfg_rd_en_n,
                        cfg_err_cor_n,
                        cfg_err_ur_n,
                        cfg_err_cpl_rdy_n,
                        cfg_err_ecrc_n,
                        cfg_err_cpl_timeout_n,
                        cfg_err_cpl_abort_n,
                        cfg_err_cpl_unexpect_n,
                        cfg_err_posted_n,
                        cfg_err_tlp_cpl_header,
                        cfg_interrupt_n,
                        cfg_interrupt_rdy_n,
                        cfg_interrupt_assert_n,
                        cfg_interrupt_di,
                        cfg_interrupt_do,
                        cfg_interrupt_mmenable,
                        cfg_interrupt_msienable,
                        cfg_turnoff_ok_n,
                        cfg_to_turnoff_n,
                        cfg_pm_wake_n,
                        cfg_status,
                        cfg_command,
                        cfg_dstatus,
                        cfg_dcommand,
                        cfg_lstatus,
                        cfg_lcommand,

                        cfg_bus_number,
                        cfg_device_number,
                        cfg_function_number,
                        cfg_pcie_link_state_n,
                        cfg_dsn,
                        cfg_trn_pending_n


                        );


 // Common

input                                             trn_clk;
input                                             trn_reset_n;
input                                             trn_lnk_up_n;

  // Tx


output [63:0]          trn_td;
output [7:0]           trn_trem;
output                                            trn_tsof_n;
output                                            trn_teof_n;
output                                            trn_tsrc_rdy_n;
input                                             trn_tdst_rdy_n;
output                                            trn_tsrc_dsc_n;
input                                             trn_tdst_dsc_n;
output                                            trn_terrfwd_n;
input  [(4 - 1):0]        trn_tbuf_av;

  // Rx

input  [63:0]          trn_rd;
input  [7:0]           trn_rrem;
input                                             trn_rsof_n;
input                                             trn_reof_n;
input                                             trn_rsrc_rdy_n;
input                                             trn_rsrc_dsc_n;
output                                            trn_rdst_rdy_n;
input                                             trn_rerrfwd_n;
output                                            trn_rnp_ok_n;

input  [6:0]       trn_rbar_hit_n;
input  [7:0]        trn_rfc_nph_av;
input  [11:0]       trn_rfc_npd_av;
input  [7:0]        trn_rfc_ph_av;
input  [11:0]       trn_rfc_pd_av;



output                                            trn_rcpl_streaming_n;


  // Host (CFG) Interface


input  [31:0]          cfg_do;
output [31:0]          cfg_di;
output [3:0]        cfg_byte_en_n;
output [9:0]          cfg_dwaddr;

input                                             cfg_rd_wr_done_n;
output                                            cfg_wr_en_n;
output                                            cfg_rd_en_n;
output                                            cfg_err_cor_n;
output                                            cfg_err_ur_n;
input                                             cfg_err_cpl_rdy_n;
output                                            cfg_err_ecrc_n;
output                                            cfg_err_cpl_timeout_n;
output                                            cfg_err_cpl_abort_n;
output                                            cfg_err_cpl_unexpect_n;
output                                            cfg_err_posted_n;
output                                            cfg_interrupt_n;
input                                             cfg_interrupt_rdy_n;
output                                            cfg_interrupt_assert_n;
output [7:0]                                      cfg_interrupt_di;
input  [7:0]                                      cfg_interrupt_do;
input  [2:0]                                      cfg_interrupt_mmenable;
input                                             cfg_interrupt_msienable;
output                                            cfg_turnoff_ok_n;
input                                             cfg_to_turnoff_n;
output                                            cfg_pm_wake_n;

output [47:0]        cfg_err_tlp_cpl_header;
input  [15:0]           cfg_status;
input  [15:0]           cfg_command;
input  [15:0]           cfg_dstatus;
input  [15:0]           cfg_dcommand;
input  [15:0]           cfg_lstatus;
input  [15:0]           cfg_lcommand;
input  [7:0]        cfg_bus_number;
input  [4:0]        cfg_device_number;
input  [2:0]        cfg_function_number;
input  [2:0]         cfg_pcie_link_state_n;
output                                            cfg_trn_pending_n;
output [(64 - 1):0]           cfg_dsn;


// Local wires and registers
//wire   [15:0]                                     cfg_completer_id;
//wire                                              cfg_bus_mstr_enable;
wire                                              cfg_ext_tag_en;
wire   [2:0]                                      cfg_max_rd_req_size;
wire   [2:0]                                      cfg_max_payload_size;

//
// Core input tie-offs
//

assign trn_rnp_ok_n = 1'b0;
assign trn_rcpl_streaming_n = 1'b1; 
assign trn_terrfwd_n = 1'b1;

assign cfg_err_cor_n = 1'b1;
assign cfg_err_ur_n = 1'b1;
assign cfg_err_ecrc_n = 1'b1;
assign cfg_err_cpl_timeout_n = 1'b1;
assign cfg_err_cpl_abort_n = 1'b1;
assign cfg_err_cpl_unexpect_n = 1'b1;
assign cfg_err_posted_n = 1'b0;
assign cfg_pm_wake_n = 1'b1;
assign cfg_trn_pending_n = 1'b1;
assign cfg_interrupt_n = 1'b1;
assign cfg_interrupt_assert_n = 1'b0;
assign cfg_interrupt_di = 8'b0;
assign cfg_dwaddr = 0;
assign cfg_rd_en_n = 1;

assign cfg_err_tlp_cpl_header = 0;
assign cfg_di = 0;
assign cfg_byte_en_n = 4'hf;
assign cfg_wr_en_n = 1;
assign cfg_dsn = {32'h00000001,  {{8'h1},24'h000A35}};


//
// Programmable I/O Module
//

wire [15:0] cfg_completer_id = {cfg_bus_number,
                                cfg_device_number,
                                cfg_function_number};

wire cfg_bus_mstr_enable = cfg_command[2];

assign cfg_ext_tag_en = cfg_dcommand[8];
assign cfg_max_rd_req_size = cfg_dcommand[14:12];
assign cfg_max_payload_size = cfg_dcommand[7:5];

  PIO PIO (
        .trn_clk ( trn_clk ),                       // I
        .trn_reset_n ( trn_reset_n ),               // I
        .trn_lnk_up_n ( trn_lnk_up_n ),             // I

        .trn_td ( trn_td ),                         // O [63:0]
        .trn_trem_n ( trn_trem ),                   // O [7:0]
        .trn_tsof_n ( trn_tsof_n ),                 // O
        .trn_teof_n ( trn_teof_n ),                 // O
        .trn_tsrc_rdy_n ( trn_tsrc_rdy_n ),         // O
        .trn_tsrc_dsc_n ( trn_tsrc_dsc_n ),         // O
        .trn_tdst_rdy_n ( trn_tdst_rdy_n ),         // I
        .trn_tdst_dsc_n ( trn_tdst_dsc_n ),         // I

        .trn_rd ( trn_rd ),                         // I [63:0]
        .trn_rrem_n ( trn_rrem ),                   // I [7:0]
        .trn_rsof_n ( trn_rsof_n ),                 // I
        .trn_reof_n ( trn_reof_n ),                 // I
        .trn_rsrc_rdy_n ( trn_rsrc_rdy_n ),         // I
        .trn_rsrc_dsc_n ( trn_rsrc_dsc_n ),         // I

        .trn_rbar_hit_n ( trn_rbar_hit_n ),         // I [6:0]
        .trn_rdst_rdy_n ( trn_rdst_rdy_n ),         // O

        .cfg_to_turnoff_n ( cfg_to_turnoff_n ),     // I
        .cfg_turnoff_ok_n ( cfg_turnoff_ok_n ),     // O

        .cfg_completer_id ( cfg_completer_id ),     // I [15:0]
        .cfg_bus_mstr_enable (cfg_bus_mstr_enable ) // I

        );


endmodule // pci_exp_64b_app
