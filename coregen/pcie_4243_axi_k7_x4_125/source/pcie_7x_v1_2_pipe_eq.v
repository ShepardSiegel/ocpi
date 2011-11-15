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
// Project    : Series-7 Integrated Block for PCI Express
// File       : pcie_7x_v1_2_pipe_eq.v
// Version    : 1.2
//------------------------------------------------------------------------------
//  Filename     :  pipe_eq.v
//  Description  :  PIPE Equalization Module for 7 Series Transceiver
//  Version      :  11.1
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Equalization Module ------------------------------------------
module pcie_7x_v1_2_pipe_eq
(

    //---------- Input -------------------------------------
    input               EQ_CLK,
    input               EQ_RST_N,
    input               EQ_GEN3,

    input       [ 1:0]  EQ_TXEQ_CONTROL,
    input       [ 3:0]  EQ_TXEQ_PRESET,
    input       [ 3:0]  EQ_TXEQ_PRESET_DEFAULT,
    input       [ 5:0]  EQ_TXEQ_DEEMPH_IN,

    input       [ 1:0]  EQ_RXEQ_CONTROL,
    input       [ 2:0]  EQ_RXEQ_PRESET,
    input       [ 5:0]  EQ_RXEQ_LFFS,
    input       [ 3:0]  EQ_RXEQ_TXPRESET,


    //---------- Output ------------------------------------
    output              EQ_TXEQ_DEEMPH,
    output      [ 4:0]  EQ_TXEQ_PRECURSOR,
    output      [ 6:0]  EQ_TXEQ_MAINCURSOR,
    output      [ 4:0]  EQ_TXEQ_POSTCURSOR,
    output      [17:0]  EQ_TXEQ_DEEMPH_OUT,
    output              EQ_TXEQ_DONE,
    output      [ 4:0]  EQ_TXEQ_FSM,

    output      [17:0]  EQ_RXEQ_NEW_TXCOEFF,
    output              EQ_RXEQ_LFFS_SEL,
    output              EQ_RXEQ_ADAPT_DONE,
    output              EQ_RXEQ_DONE,
    output      [ 5:0]  EQ_RXEQ_FSM

);

    //---------- Input Registers ---------------------------
    reg                 gen3_reg1;
    reg                 gen3_reg2;

    reg         [ 1:0]  txeq_control_reg1;
    reg         [ 3:0]  txeq_preset_reg1;
    reg         [ 5:0]  txeq_deemph_reg1;

    reg         [ 1:0]  txeq_control_reg2;
    reg			      [ 3:0]  txeq_preset_reg2;
    reg         [ 5:0]  txeq_deemph_reg2;

    reg         [ 1:0]  rxeq_control_reg1;
    reg			      [ 2:0]  rxeq_preset_reg1;
    reg         [ 5:0]  rxeq_lffs_reg1;
    reg         [ 3:0]  rxeq_txpreset_reg1;

    reg         [ 1:0]  rxeq_control_reg2;
    reg			      [ 2:0]  rxeq_preset_reg2;
    reg         [ 5:0]  rxeq_lffs_reg2;
    reg         [ 3:0]  rxeq_txpreset_reg2;

    //---------- Internal Signals --------------------------
    reg         [17:0]  txeq_preset          = 18'd0;
    reg                 txeq_preset_done     =  1'd0;
    reg         [ 1:0]  txeq_txcoeff_cnt     =  2'd0;

    reg         [ 2:0]  rxeq_preset          =  3'd0;
    reg                 rxeq_preset_valid    =  1'd0;
    reg         [ 3:0]  rxeq_txpreset        =  4'd0;
    reg         [17:0]  rxeq_txcoeff         = 18'd0;
    reg         [ 2:0]  rxeq_cnt             =  3'd0;
    reg         [ 5:0]  rxeq_fs              =  6'd0;
    reg         [ 5:0]  rxeq_lf              =  6'd0;
    reg                 rxeq_new_txcoeff_req =  1'd0;

    //---------- Output Registers --------------------------
    reg         [17:0]  txeq_txcoeff        = 18'd0;
    reg                 txeq_done           =  1'd0;
    reg         [ 4:0]  fsm_tx              =  5'd0;

    reg         [17:0]  rxeq_new_txcoeff    = 18'd0;
    reg                 rxeq_lffs_sel       =  1'd0;
    reg                 rxeq_adapt_done_reg =  1'd0;
    reg                 rxeq_adapt_done     =  1'd0;
    reg                 rxeq_done           =  1'd0;
    reg         [ 5:0]  fsm_rx              =  6'd0;

    //---------- RXEQ Eye Scan Module Output ---------------
    wire                rxeqscan_lffs_sel;
    wire                rxeqscan_preset_done;
    wire        [17:0]  rxeqscan_new_txcoeff;
    wire                rxeqscan_new_txcoeff_done;
    wire                rxeqscan_adapt_done;

    //---------- FSM ---------------------------------------
    localparam          FSM_TXEQ_IDLE            = 5'b00001;
    localparam          FSM_TXEQ_PRESET          = 5'b00010;
    localparam          FSM_TXEQ_TXCOEFF         = 5'b00100;
    localparam          FSM_TXEQ_QUERY           = 5'b01000;
    localparam          FSM_TXEQ_DONE            = 5'b10000;

    localparam          FSM_RXEQ_IDLE            = 6'b000001;
    localparam          FSM_RXEQ_PRESET          = 6'b000010;
    localparam          FSM_RXEQ_TXCOEFF         = 6'b000100;
    localparam          FSM_RXEQ_LF              = 6'b001000;
    localparam          FSM_RXEQ_NEW_TXCOEFF_REQ = 6'b010000;
    localparam          FSM_RXEQ_DONE            = 6'b100000;

    //---------- TXEQ Presets Look-up Table ----------------
    localparam          TXPRECURSOR_00  = 6'd0;
    localparam          TXMAINCURSOR_00 = 6'd0;
    localparam          TXPOSTCURSOR_00 = 6'd0;

    localparam          TXPRECURSOR_01  = 6'd1;
    localparam          TXMAINCURSOR_01 = 6'd1;
    localparam          TXPOSTCURSOR_01 = 6'd1;

    localparam          TXPRECURSOR_02  = 6'd2;
    localparam          TXMAINCURSOR_02 = 6'd2;
    localparam          TXPOSTCURSOR_02 = 6'd2;

    localparam          TXPRECURSOR_03  = 6'd3;
    localparam          TXMAINCURSOR_03 = 6'd3;
    localparam          TXPOSTCURSOR_03 = 6'd3;

    localparam          TXPRECURSOR_04  = 6'd4;
    localparam          TXMAINCURSOR_04 = 6'd4;
    localparam          TXPOSTCURSOR_04 = 6'd4;

    localparam          TXPRECURSOR_05  = 6'd5;
    localparam          TXMAINCURSOR_05 = 6'd5;
    localparam          TXPOSTCURSOR_05 = 6'd5;

    localparam          TXPRECURSOR_06  = 6'd6;
    localparam          TXMAINCURSOR_06 = 6'd6;
    localparam          TXPOSTCURSOR_06 = 6'd6;

    localparam          TXPRECURSOR_07  = 6'd7;
    localparam          TXMAINCURSOR_07 = 6'd7;
    localparam          TXPOSTCURSOR_07 = 6'd7;

    localparam          TXPRECURSOR_08  = 6'd8;
    localparam          TXMAINCURSOR_08 = 6'd8;
    localparam          TXPOSTCURSOR_08 = 6'd8;

    localparam          TXPRECURSOR_09  = 6'd9;
    localparam          TXMAINCURSOR_09 = 6'd9;
    localparam          TXPOSTCURSOR_09 = 6'd9;



//---------- Input FF ----------------------------------------------------------
always @ (posedge EQ_CLK)
begin

    if (!EQ_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        gen3_reg1          <= 1'd0;

        txeq_control_reg1  <= 2'd0;
        txeq_preset_reg1   <= 4'd0;
        txeq_deemph_reg1   <= 6'd1;

        rxeq_control_reg1  <= 2'd0;
        rxeq_preset_reg1   <= 3'd0;
        rxeq_lffs_reg1     <= 6'd0;
        rxeq_txpreset_reg1 <= 4'd0;
        //---------- 2nd Stage FF --------------------------
        gen3_reg2          <= 1'd0;

        txeq_control_reg2  <= 2'd0;
        txeq_preset_reg2   <= 4'd0;
        txeq_deemph_reg2   <= 6'd1;

        rxeq_control_reg2  <= 2'd0;
        rxeq_preset_reg2   <= 3'd0;
        rxeq_lffs_reg2     <= 6'd0;
        rxeq_txpreset_reg2 <= 4'd0;
        end
    else
        begin
        //---------- 1st Stage FF --------------------------
        gen3_reg1          <= EQ_GEN3;

        txeq_control_reg1  <= EQ_TXEQ_CONTROL;
        txeq_preset_reg1   <= EQ_TXEQ_PRESET;
        txeq_deemph_reg1   <= EQ_TXEQ_DEEMPH_IN;

        rxeq_control_reg1  <= EQ_RXEQ_CONTROL;
        rxeq_preset_reg1   <= EQ_RXEQ_PRESET;
        rxeq_lffs_reg1     <= EQ_RXEQ_LFFS;
        rxeq_txpreset_reg1 <= EQ_RXEQ_TXPRESET;
        //---------- 2nd Stage FF --------------------------
        gen3_reg2          <= gen3_reg1;

        txeq_control_reg2  <= txeq_control_reg1;
        txeq_preset_reg2   <= txeq_preset_reg1;
        txeq_deemph_reg2   <= txeq_deemph_reg1;

        rxeq_control_reg2  <= rxeq_control_reg1;
        rxeq_preset_reg2   <= rxeq_preset_reg1;
        rxeq_lffs_reg2     <= rxeq_lffs_reg1;
        rxeq_txpreset_reg2 <= rxeq_txpreset_reg1;
        end

end



//---------- TXEQ Preset -------------------------------------------------------
always @ (posedge EQ_CLK)
begin

    if (!EQ_RST_N)
        begin

        //---------- Select TXEQ Preset ----------------
        case (EQ_TXEQ_PRESET_DEFAULT)
        4'd0    : txeq_preset <= {TXPOSTCURSOR_00, TXMAINCURSOR_00, TXPRECURSOR_00};
        4'd1    : txeq_preset <= {TXPOSTCURSOR_01, TXMAINCURSOR_01, TXPRECURSOR_01};
        4'd2    : txeq_preset <= {TXPOSTCURSOR_02, TXMAINCURSOR_02, TXPRECURSOR_02};
        4'd3    : txeq_preset <= {TXPOSTCURSOR_03, TXMAINCURSOR_03, TXPRECURSOR_03};
        4'd4    : txeq_preset <= {TXPOSTCURSOR_04, TXMAINCURSOR_04, TXPRECURSOR_04};
        4'd5    : txeq_preset <= {TXPOSTCURSOR_05, TXMAINCURSOR_05, TXPRECURSOR_05};
        4'd6    : txeq_preset <= {TXPOSTCURSOR_06, TXMAINCURSOR_06, TXPRECURSOR_06};
        4'd7    : txeq_preset <= {TXPOSTCURSOR_07, TXMAINCURSOR_07, TXPRECURSOR_07};
        4'd8    : txeq_preset <= {TXPOSTCURSOR_08, TXMAINCURSOR_08, TXPRECURSOR_08};
        4'd9    : txeq_preset <= {TXPOSTCURSOR_09, TXMAINCURSOR_09, TXPRECURSOR_09};
        default : txeq_preset <= 18'd0;
        endcase

        txeq_preset_done <=  1'd0;
        end
    else
        begin
        if (fsm_tx == FSM_TXEQ_PRESET)
            begin

            //---------- Select TXEQ Preset ----------------
            case (txeq_preset_reg2)
            4'd0    : txeq_preset <= {TXPOSTCURSOR_00, TXMAINCURSOR_00, TXPRECURSOR_00};
            4'd1    : txeq_preset <= {TXPOSTCURSOR_01, TXMAINCURSOR_01, TXPRECURSOR_01};
            4'd2    : txeq_preset <= {TXPOSTCURSOR_02, TXMAINCURSOR_02, TXPRECURSOR_02};
            4'd3    : txeq_preset <= {TXPOSTCURSOR_03, TXMAINCURSOR_03, TXPRECURSOR_03};
            4'd4    : txeq_preset <= {TXPOSTCURSOR_04, TXMAINCURSOR_04, TXPRECURSOR_04};
            4'd5    : txeq_preset <= {TXPOSTCURSOR_05, TXMAINCURSOR_05, TXPRECURSOR_05};
            4'd6    : txeq_preset <= {TXPOSTCURSOR_06, TXMAINCURSOR_06, TXPRECURSOR_06};
            4'd7    : txeq_preset <= {TXPOSTCURSOR_07, TXMAINCURSOR_07, TXPRECURSOR_07};
            4'd8    : txeq_preset <= {TXPOSTCURSOR_08, TXMAINCURSOR_08, TXPRECURSOR_08};
            4'd9    : txeq_preset <= {TXPOSTCURSOR_09, TXMAINCURSOR_09, TXPRECURSOR_09};
            default : txeq_preset <= 18'd0;
        	   endcase

            txeq_preset_done <= 1'd1;
            end
        else
            begin
            txeq_preset      <= txeq_preset;
            txeq_preset_done <= 1'd0;
            end
        end

end



//---------- TXEQ FSM ----------------------------------------------------------
always @ (posedge EQ_CLK)
begin

    if (!EQ_RST_N)
        begin
        fsm_tx           <=  FSM_TXEQ_IDLE;
        txeq_txcoeff     <= 18'd0;
        txeq_txcoeff_cnt <=  2'd0;
        txeq_done        <=  1'd0;
        end
    else
        begin

        case (fsm_tx)

        //---------- Idle State ----------------------------
        FSM_TXEQ_IDLE :

            begin

            case (txeq_control_reg2)

            //---------- Idle ------------------------------
            2'd0    :
                begin
                fsm_tx           <= FSM_TXEQ_IDLE;
                txeq_txcoeff     <= txeq_txcoeff;
                txeq_txcoeff_cnt <= 2'd0;
                txeq_done        <= 1'd0;
                end

            //---------- Process TXEQ Preset ---------------
            2'd1    :
                begin
                fsm_tx           <= FSM_TXEQ_PRESET;
                txeq_txcoeff     <= txeq_txcoeff;
                txeq_txcoeff_cnt <= 2'd0;
                txeq_done        <= 1'd0;
                end

            //---------- Coefficient -----------------------
            2'd2    :
                begin
                fsm_tx           <= FSM_TXEQ_TXCOEFF;
                txeq_txcoeff     <= {txeq_deemph_reg2, txeq_txcoeff[17:6]};
                txeq_txcoeff_cnt <= 2'd1;
                txeq_done        <= 1'd0;
                end

            //---------- Query -----------------------------
            2'd3    :
                begin
                fsm_tx           <= FSM_TXEQ_QUERY;
                txeq_txcoeff     <= txeq_txcoeff;
                txeq_txcoeff_cnt <= 2'd0;
                txeq_done        <= 1'd0;
                end

            //---------- Default ---------------------------
            default :
                begin
                fsm_tx           <= FSM_TXEQ_IDLE;
                txeq_txcoeff     <= txeq_txcoeff;
                txeq_txcoeff_cnt <= 2'd0;
                txeq_done        <= 1'd0;
                end

            endcase

            end

        //---------- Process TXEQ Preset -------------------
        FSM_TXEQ_PRESET :

            begin
            fsm_tx           <= (txeq_preset_done ? FSM_TXEQ_DONE : FSM_TXEQ_PRESET);
            txeq_txcoeff     <= txeq_preset;
            txeq_txcoeff_cnt <= 2'd0;
            txeq_done        <= 1'd0;
            end

        //---------- Latch Link Partner TX Coefficient -----
        FSM_TXEQ_TXCOEFF :

            begin
            fsm_tx           <= ((txeq_txcoeff_cnt == 2'd2) ? FSM_TXEQ_DONE : FSM_TXEQ_TXCOEFF);
            txeq_txcoeff     <= {txeq_deemph_reg2, txeq_txcoeff[17:6]};
            txeq_txcoeff_cnt <= txeq_txcoeff_cnt + 2'd1;
            txeq_done        <= 1'd0;
            end

        //---------- Query TXEQ Coefficient ----------------
        FSM_TXEQ_QUERY:

            begin
            fsm_tx           <= FSM_TXEQ_DONE;
            txeq_txcoeff     <= txeq_txcoeff;
            txeq_txcoeff_cnt <= 2'd0;
            txeq_done        <= 1'd0;
            end

        //---------- Done ----------------------------------
        FSM_TXEQ_DONE :

            begin
            fsm_tx           <= ((txeq_control_reg2 == 2'd0) ? FSM_TXEQ_IDLE : FSM_TXEQ_DONE);
            txeq_txcoeff     <= txeq_txcoeff;
            txeq_txcoeff_cnt <= 2'd0;
            txeq_done        <= 1'd1;
            end

        //---------- Default State -------------------------
        default :
            begin
            fsm_tx           <=  FSM_TXEQ_IDLE;
            txeq_txcoeff     <= 18'd0;
            txeq_txcoeff_cnt <=  2'd0;
            txeq_done        <=  1'd0;
            end

        endcase

        end

end



//---------- RXEQ FSM ----------------------------------------------------------
always @ (posedge EQ_CLK)
begin

    if (!EQ_RST_N)
        begin
        fsm_rx               <= FSM_RXEQ_IDLE;
        rxeq_preset          <=  3'd0;
        rxeq_preset_valid    <=  1'd0;
        rxeq_txpreset        <=  4'd0;
        rxeq_txcoeff         <= 18'd0;
        rxeq_cnt             <=  3'd0;
        rxeq_fs              <=  6'd0;
        rxeq_lf              <=  6'd0;
        rxeq_new_txcoeff_req <=  1'd0;
        rxeq_new_txcoeff     <= 18'd0;
        rxeq_lffs_sel        <=  1'd0;
        rxeq_adapt_done_reg  <=  1'd0;
        rxeq_adapt_done      <=  1'd0;
        rxeq_done            <=  1'd0;
        end
    else
        begin

        case (fsm_rx)

        //---------- Idle State ----------------------------
        FSM_RXEQ_IDLE :

            begin

            case (rxeq_control_reg2)

            //---------- Process RXEQ Preset ---------------
            2'd1 :
                begin
                fsm_rx               <= FSM_RXEQ_PRESET;
                rxeq_preset          <= rxeq_preset_reg2;
                rxeq_preset_valid    <= 1'd0;
                rxeq_txpreset        <= rxeq_txpreset;
                rxeq_txcoeff         <= rxeq_txcoeff;
                rxeq_cnt             <= 3'd0;
                rxeq_fs              <= rxeq_fs;
                rxeq_lf              <= rxeq_lf;
                rxeq_new_txcoeff_req <= 1'd0;
                rxeq_new_txcoeff     <= rxeq_new_txcoeff;
                rxeq_lffs_sel        <= 1'd0;
                rxeq_adapt_done_reg  <= 1'd0;
                rxeq_adapt_done      <= 1'd0;
                rxeq_done            <= 1'd0;
                end

            //---------- Request New TX Coefficient --------
            2'd2 :
                begin
                fsm_rx               <= FSM_RXEQ_TXCOEFF;
                rxeq_preset          <= rxeq_preset;
                rxeq_preset_valid    <= 1'd0;
                rxeq_txpreset        <= rxeq_txpreset_reg2;
                rxeq_txcoeff         <= {txeq_deemph_reg2, rxeq_txcoeff[17:6]};
                rxeq_cnt             <= 3'd1;
                rxeq_fs              <= rxeq_lffs_reg2;
                rxeq_lf              <= rxeq_lf;
                rxeq_new_txcoeff_req <= 1'd0;
                rxeq_new_txcoeff     <= rxeq_new_txcoeff;
                rxeq_lffs_sel        <= 1'd0;
                rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
                rxeq_adapt_done      <= 1'd0;
                rxeq_done            <= 1'd0;
                end

            //---------- Default ---------------------------
            default :
                begin
                fsm_rx               <= FSM_RXEQ_IDLE;
                rxeq_preset          <= rxeq_preset;
                rxeq_preset_valid    <= 1'd0;
                rxeq_txpreset        <= rxeq_txpreset;
                rxeq_txcoeff         <= rxeq_txcoeff;
                rxeq_cnt             <= 3'd0;
                rxeq_fs              <= rxeq_fs;
                rxeq_lf              <= rxeq_lf;
                rxeq_new_txcoeff_req <= 1'd0;
                rxeq_new_txcoeff     <= rxeq_new_txcoeff;
                rxeq_lffs_sel        <= 1'd0;
                rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
                rxeq_adapt_done      <= 1'd0;
                rxeq_done            <= 1'd0;
                end

            endcase

            end

        //---------- Process RXEQ Preset -------------------
        FSM_RXEQ_PRESET :

            begin
            fsm_rx               <= (rxeqscan_preset_done ? FSM_RXEQ_DONE : FSM_RXEQ_PRESET);
            rxeq_preset          <= rxeq_preset_reg2;
            rxeq_preset_valid    <= 1'd1;
            rxeq_txpreset        <= rxeq_txpreset;
            rxeq_txcoeff         <= rxeq_txcoeff;
            rxeq_cnt             <= 3'd0;
            rxeq_fs              <= rxeq_fs;
            rxeq_lf              <= rxeq_lf;
            rxeq_new_txcoeff_req <= 1'd0;
            rxeq_new_txcoeff     <= rxeq_new_txcoeff;
            rxeq_lffs_sel        <= 1'd0;
            rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
            rxeq_adapt_done      <= 1'd0;
            rxeq_done            <= 1'd0;
            end

        //---------- Shift-in Partner TX Coefficient and Preset
        FSM_RXEQ_TXCOEFF :

            begin
            fsm_rx               <= ((rxeq_cnt == 3'd2) ? FSM_RXEQ_LF : FSM_RXEQ_TXCOEFF);
            rxeq_preset          <= rxeq_preset;
            rxeq_preset_valid    <= 1'd0;
            rxeq_txpreset        <= rxeq_txpreset_reg2;
            rxeq_txcoeff         <= {txeq_deemph_reg2, rxeq_txcoeff[17:6]};
            rxeq_cnt             <= rxeq_cnt + 2'd1;
            rxeq_fs              <= rxeq_fs;
            rxeq_lf              <= rxeq_lf;
            rxeq_new_txcoeff_req <= 1'd0;
            rxeq_new_txcoeff     <= rxeq_new_txcoeff;
            rxeq_lffs_sel        <= 1'd1;
            rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
            rxeq_adapt_done      <= 1'd0;
            rxeq_done            <= 1'd0;
            end

        //---------- Read Low Frequency (LF) Value ---------
        FSM_RXEQ_LF :
            begin
            fsm_rx               <= ((rxeq_cnt == 3'd7) ? FSM_RXEQ_NEW_TXCOEFF_REQ : FSM_RXEQ_LF);
            rxeq_preset          <= rxeq_preset;
            rxeq_preset_valid    <= 1'd0;
            rxeq_txpreset        <= rxeq_txpreset;
            rxeq_txcoeff         <= rxeq_txcoeff;
            rxeq_cnt             <= rxeq_cnt + 2'd1;
            rxeq_fs              <= rxeq_fs;
            rxeq_lf              <= ((rxeq_cnt == 3'd7) ? rxeq_lffs_reg2 : rxeq_lf);
            rxeq_new_txcoeff_req <= 1'd0;
            rxeq_new_txcoeff     <= rxeq_new_txcoeff;
            rxeq_lffs_sel        <= 1'd1;
            rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
            rxeq_adapt_done      <= 1'd0;
            rxeq_done            <= 1'd0;
            end

        //---------- Request New TX Coefficient ------------
        FSM_RXEQ_NEW_TXCOEFF_REQ :

            begin
            rxeq_preset          <= rxeq_preset;
            rxeq_preset_valid    <= 1'd0;
            rxeq_txpreset        <= rxeq_txpreset;
            rxeq_txcoeff         <= rxeq_txcoeff;
            rxeq_cnt             <= 3'd0;
            rxeq_fs              <= rxeq_fs;
            rxeq_lf              <= rxeq_lf;

            if (rxeqscan_new_txcoeff_done)
                begin
                fsm_rx               <= FSM_RXEQ_DONE;
                rxeq_new_txcoeff_req <= 1'd0;
                rxeq_new_txcoeff     <= rxeqscan_lffs_sel ? {14'd0, rxeqscan_new_txcoeff[3:0]} : rxeqscan_new_txcoeff;
                rxeq_lffs_sel        <= rxeqscan_lffs_sel;
                rxeq_adapt_done_reg  <= rxeqscan_adapt_done || rxeq_adapt_done_reg;
                rxeq_adapt_done      <= rxeqscan_adapt_done || rxeq_adapt_done_reg;
                rxeq_done            <= 1'd1;
                end
            else
                begin
                fsm_rx               <= FSM_RXEQ_NEW_TXCOEFF_REQ;
                rxeq_new_txcoeff_req <= 1'd1;
                rxeq_new_txcoeff     <= rxeq_new_txcoeff;
                rxeq_lffs_sel        <= 1'd0;
                rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
                rxeq_adapt_done      <= 1'd0;
                rxeq_done            <= 1'd0;
                end

            end

        //---------- RXEQ Done -----------------------------
        FSM_RXEQ_DONE :

            begin
            fsm_rx               <= ((rxeq_control_reg2 == 2'd0) ? FSM_RXEQ_IDLE : FSM_RXEQ_DONE);
            rxeq_preset          <= rxeq_preset;
            rxeq_preset_valid    <= 1'd0;
            rxeq_txpreset        <= rxeq_txpreset;
            rxeq_txcoeff         <= rxeq_txcoeff;
            rxeq_cnt             <= 3'd0;
            rxeq_fs              <= rxeq_fs;
            rxeq_lf              <= rxeq_lf;
            rxeq_new_txcoeff_req <= 1'd0;
            rxeq_new_txcoeff     <= rxeq_new_txcoeff;
            rxeq_lffs_sel        <= rxeq_lffs_sel;
            rxeq_adapt_done_reg  <= rxeq_adapt_done_reg;
            rxeq_adapt_done      <= rxeq_adapt_done;
            rxeq_done            <= 1'd1;
            end

        //---------- Default State -------------------------
        default :
            begin
            fsm_rx               <= FSM_RXEQ_IDLE;
            rxeq_preset          <=  3'd0;
            rxeq_preset_valid    <=  1'd0;
            rxeq_txpreset        <=  4'd0;
            rxeq_txcoeff         <= 18'd0;
            rxeq_cnt             <=  3'd0;
            rxeq_fs              <=  6'd0;
            rxeq_lf              <=  6'd0;
            rxeq_new_txcoeff_req <=  1'd0;
            rxeq_new_txcoeff     <= 18'd0;
            rxeq_lffs_sel        <=  1'd0;
            rxeq_adapt_done_reg  <=  1'd0;
            rxeq_adapt_done      <=  1'd0;
            rxeq_done            <=  1'd0;
            end

    	   endcase

        end

end



//---------- RXEQ Eye Scan Module ----------------------------------------------
pcie_7x_v1_2_rxeq_scan rxeq_scan_i
(

    //---------- Input -------------------------------------
    .RXEQSCAN_CLK                       (EQ_CLK),
    .RXEQSCAN_RST_N                     (EQ_RST_N),
    .RXEQSCAN_FS                        (rxeq_fs),
    .RXEQSCAN_LF                        (rxeq_lf),
    .RXEQSCAN_PRESET                    (rxeq_preset),
    .RXEQSCAN_PRESET_VALID              (rxeq_preset_valid),
    .RXEQSCAN_TXPRESET                  (rxeq_txpreset),
    .RXEQSCAN_TXCOEFF                   (rxeq_txcoeff),
    .RXEQSCAN_NEW_TXCOEFF_REQ           (rxeq_new_txcoeff_req),

    //---------- Output ------------------------------------
    .RXEQSCAN_PRESET_DONE               (rxeqscan_preset_done),
    .RXEQSCAN_NEW_TXCOEFF               (rxeqscan_new_txcoeff),
    .RXEQSCAN_NEW_TXCOEFF_DONE          (rxeqscan_new_txcoeff_done),
    .RXEQSCAN_LFFS_SEL                  (rxeqscan_lffs_sel),
    .RXEQSCAN_ADAPT_DONE                (rxeqscan_adapt_done)

);



//---------- PIPE EQ Output ----------------------------------------------------
assign EQ_TXEQ_DEEMPH      = txeq_txcoeff[0];
assign EQ_TXEQ_PRECURSOR   = gen3_reg2 ?        txeq_txcoeff[ 4: 0]  : 5'h00;
assign EQ_TXEQ_MAINCURSOR  = gen3_reg2 ? {1'd0, txeq_txcoeff[11: 6]} : 7'h00;
assign EQ_TXEQ_POSTCURSOR  = gen3_reg2 ?        txeq_txcoeff[16:12]  : 5'h00;
assign EQ_TXEQ_DEEMPH_OUT  = txeq_txcoeff;
assign EQ_TXEQ_DONE        = txeq_done;
assign EQ_TXEQ_FSM         = fsm_tx;

assign EQ_RXEQ_NEW_TXCOEFF = rxeq_new_txcoeff;
assign EQ_RXEQ_LFFS_SEL    = rxeq_lffs_sel;
assign EQ_RXEQ_ADAPT_DONE  = rxeq_adapt_done;
assign EQ_RXEQ_DONE        = rxeq_done;
assign EQ_RXEQ_FSM         = fsm_rx;


endmodule
