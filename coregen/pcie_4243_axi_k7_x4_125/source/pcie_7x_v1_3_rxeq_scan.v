//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
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
// File       : pcie_7x_v1_3_rxeq_scan.v
// Version    : 1.3
//------------------------------------------------------------------------------
//  Filename     :  rxeq_scan.v
//  Description  :  PIPE Equalization Eye Scan Test Module for 7 Series Transceiver
//  Version      :  10.5
//------------------------------------------------------------------------------


`timescale 1ns / 1ps



//---------- RXEQ Eye Scan Module ----------------------------------------------
module pcie_7x_v1_3_rxeq_scan
(

    //---------- Input -------------------------------------
    input               RXEQSCAN_CLK,
    input               RXEQSCAN_RST_N,

    input       [ 2:0]  RXEQSCAN_PRESET,
    input               RXEQSCAN_PRESET_VALID,
    input       [ 3:0]  RXEQSCAN_TXPRESET,
    input       [17:0]  RXEQSCAN_TXCOEFF,
    input               RXEQSCAN_NEW_TXCOEFF_REQ,
    input       [ 5:0]  RXEQSCAN_FS,
    input       [ 5:0]  RXEQSCAN_LF,


    //---------- Output ------------------------------------
    output              RXEQSCAN_PRESET_DONE,
    output      [17:0]  RXEQSCAN_NEW_TXCOEFF,
    output              RXEQSCAN_NEW_TXCOEFF_DONE,
    output              RXEQSCAN_LFFS_SEL,
    output              RXEQSCAN_ADAPT_DONE

);

    //---------- Input Register ----------------------------
    reg         [ 2:0]  preset_reg1;
    reg                 preset_valid_reg1;
    reg         [ 3:0]  txpreset_reg1;
    reg         [17:0]  txcoeff_reg1;
    reg                 new_txcoeff_req_reg1;
    reg         [ 5:0]  fs_reg1;
    reg         [ 5:0]  lf_reg1;

    reg         [ 2:0]  preset_reg2;
    reg                 preset_valid_reg2;
    reg         [ 3:0]  txpreset_reg2;
    reg         [17:0]  txcoeff_reg2;
    reg                 new_txcoeff_req_reg2;
    reg         [ 5:0]  fs_reg2;
    reg         [ 5:0]  lf_reg2;

    //---------- Internal Signals --------------------------
    reg         [ 1:0]  lffs_sel_cnt   = 2'd0;
    reg         [ 2:0]  adapt_done_cnt = 3'd0;

    //---------- Output Register ---------------------------
    reg                 preset_done      =  1'd0;
    reg         [17:0]  new_txcoeff      = 18'd0;
    reg                 new_txcoeff_done =  1'd0;
    reg                 lffs_sel         =  1'd0;
    reg                 adapt_done       =  1'd0;
    reg         [ 2:0]  fsm              =  3'd0;

    //---------- FSM ---------------------------------------
    localparam          FSM_IDLE            = 3'b001;
    localparam          FSM_PRESET          = 3'b010;
    localparam          FSM_NEW_TXCOEFF_REQ = 3'b100;



//---------- Input FF ----------------------------------------------------------
always @ (posedge RXEQSCAN_CLK)
begin

    if (!RXEQSCAN_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        preset_reg1          <=  3'd0;
        preset_valid_reg1    <=  1'd0;
        txpreset_reg1        <=  4'd0;
        txcoeff_reg1         <= 18'd0;
        new_txcoeff_req_reg1 <=  1'd0;
        fs_reg1              <=  6'd0;
        lf_reg1              <=  6'd0;
        //---------- 2nd Stage FF --------------------------
        preset_reg2          <=  3'd0;
        preset_valid_reg2    <=  1'd0;
        txpreset_reg2        <=  4'd0;
        txcoeff_reg2         <= 18'd0;
        new_txcoeff_req_reg2 <=  1'd0;
        fs_reg2              <=  6'd0;
        lf_reg2              <=  6'd0;
        end
    else
        begin
        //---------- 1st Stage FF --------------------------
        preset_reg1          <= RXEQSCAN_PRESET;
        preset_valid_reg1    <= RXEQSCAN_PRESET_VALID;
        txpreset_reg1        <= RXEQSCAN_TXPRESET;
        txcoeff_reg1         <= RXEQSCAN_TXCOEFF;
        new_txcoeff_req_reg1 <= RXEQSCAN_NEW_TXCOEFF_REQ;
        fs_reg1              <= RXEQSCAN_FS;
        lf_reg1              <= RXEQSCAN_LF;
        //---------- 2nd Stage FF --------------------------
        preset_reg2          <= preset_reg1;
        preset_valid_reg2    <= preset_valid_reg1;
        txpreset_reg2        <= txpreset_reg1;
        txcoeff_reg2         <= txcoeff_reg1;
        new_txcoeff_req_reg2 <= new_txcoeff_req_reg1;
        fs_reg2              <= fs_reg1;
        lf_reg2              <= lf_reg1;
        end

end



//---------- Eye Scan ----------------------------------------------------------
always @ (posedge RXEQSCAN_CLK)
begin

    if (!RXEQSCAN_RST_N)
        begin
        fsm              <=  FSM_IDLE;
        preset_done      <=  1'd0;
        new_txcoeff      <= 18'd0;
        new_txcoeff_done <=  1'd0;
        lffs_sel         <=  1'd0;
        lffs_sel_cnt     <=  2'd0;
        adapt_done       <=  1'd0;
        adapt_done_cnt   <=  3'd0;
        end
    else

        begin

        case (fsm)

        //---------- Idle State ----------------------------
        FSM_IDLE :

            begin

            //---------- Process RXEQ Preset ---------------
            if (preset_valid_reg2)
                begin
                fsm              <=  FSM_PRESET;
                preset_done      <=  1'd1;
                new_txcoeff      <=  new_txcoeff;
                new_txcoeff_done <=  1'd0;
                lffs_sel         <=  1'd0;
                lffs_sel_cnt     <=  lffs_sel_cnt;
                adapt_done       <=  1'd0;
                adapt_done_cnt   <=  adapt_done_cnt;
                end
            //---------- Request New TX Coefficient --------
            else if (new_txcoeff_req_reg2)
                begin
                fsm              <=  FSM_NEW_TXCOEFF_REQ;
                preset_done      <=  1'd0;
                new_txcoeff      <=  txcoeff_reg2;
                new_txcoeff_done <=  1'd1;
                lffs_sel         <= (lffs_sel_cnt   == 2'd1);
                lffs_sel_cnt     <= (lffs_sel_cnt   +  2'd1);
                adapt_done       <= (adapt_done_cnt == 3'd1);
                adapt_done_cnt   <= (adapt_done_cnt +  3'd1);
                end
            //---------- Default ---------------------------
            else
                begin
                fsm              <=  FSM_IDLE;
                preset_done      <=  1'd0;
                new_txcoeff      <=  new_txcoeff;
                new_txcoeff_done <=  1'd0;
                lffs_sel         <=  1'd0;
                lffs_sel_cnt     <=  lffs_sel_cnt;
                adapt_done       <=  1'd0;
                adapt_done_cnt   <=  adapt_done_cnt;
                end

            end

        //---------- Process RXEQ Preset -------------------
        FSM_PRESET :

            begin
            fsm              <= (!preset_valid_reg2) ? FSM_IDLE : FSM_PRESET;
            preset_done      <=  1'd1;
            new_txcoeff      <=  new_txcoeff;
            new_txcoeff_done <=  1'd0;
            lffs_sel         <=  1'd0;
            lffs_sel_cnt     <=  lffs_sel_cnt;
            adapt_done       <=  1'd0;
            adapt_done_cnt   <=  adapt_done_cnt;
            end

        //---------- Request New TX Coefficient ------------
        FSM_NEW_TXCOEFF_REQ :

            begin
            fsm              <= (!new_txcoeff_req_reg2) ? FSM_IDLE : FSM_NEW_TXCOEFF_REQ;
            preset_done      <=  1'd0;
            new_txcoeff      <=  new_txcoeff;
            new_txcoeff_done <=  1'd1;
            lffs_sel         <=  lffs_sel;
            lffs_sel_cnt     <=  lffs_sel_cnt;
            adapt_done       <=  adapt_done;
            adapt_done_cnt   <=  adapt_done_cnt;
            end

        //---------- Default State -------------------------
        default :

            begin
            fsm              <=  FSM_IDLE;
            preset_done      <=  1'd0;
            new_txcoeff      <= 18'd0;
            new_txcoeff_done <=  1'd0;
            lffs_sel         <=  1'd0;
            lffs_sel_cnt     <=  2'd0;
            adapt_done       <=  1'd0;
            adapt_done_cnt   <=  3'd0;
            end

        endcase

        end

end



//---------- RXEQ Eye Scan Output ----------------------------------------------
assign RXEQSCAN_PRESET_DONE      = preset_done;
assign RXEQSCAN_NEW_TXCOEFF      = new_txcoeff;
assign RXEQSCAN_NEW_TXCOEFF_DONE = new_txcoeff_done;
assign RXEQSCAN_LFFS_SEL         = lffs_sel;
assign RXEQSCAN_ADAPT_DONE       = adapt_done;



endmodule
