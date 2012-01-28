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
// File       : pcie_7x_v1_3_qpll_drp.v
// Version    : 1.3
//------------------------------------------------------------------------------
//  Filename     :  qpll_drp.v
//  Description  :  QPLL DRP Module for 7 Series Transceiver
//  Version      :  11.2
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- QPLL DRP Module ---------------------------------------------------
module pcie_7x_v1_3_qpll_drp #
(

    parameter PCIE_PLL_SEL     = "CPLL",                    // PCIe PLL select for Gen1/Gen2 only
    parameter PCIE_REFCLK_FREQ = 0,                         // PCIe reference clock frequency
    parameter INDEX_MAX        = 3'd4                       // Index max count

)

(

    //---------- Input -------------------------------------
    input               DRP_CLK,
    input               DRP_RST_N,
    input               DRP_OVRD,
    input               DRP_GEN3,
    input               DRP_START,
    input       [15:0]  DRP_DO,
    input               DRP_RDY,

    //---------- Output ------------------------------------
    output      [ 7:0]  DRP_ADDR,
    output              DRP_EN,
    output      [15:0]  DRP_DI,
    output              DRP_WE,
    output              DRP_DONE,
    output      [ 5:0]  DRP_CRSCODE,
    output      [ 6:0]  DRP_FSM

);

    //---------- Input Registers ---------------------------
    reg                 ovrd_reg1;
    reg                 gen3_reg1;
    reg                 start_reg1;
    reg         [15:0]  do_reg1;
    reg                 rdy_reg1;

    reg                 ovrd_reg2;
    reg                 gen3_reg2;
    reg                 start_reg2;
    reg         [15:0]  do_reg2;
    reg                 rdy_reg2;

    //---------- Internal Signals --------------------------
    reg         [ 2:0]  index   =  3'd0;
    reg                 mode    =  1'd0;
    reg         [ 5:0]  crscode =  6'd0;

    //---------- Output Registers --------------------------
    reg         [ 7:0]  addr    =  8'd0;
    reg         [15:0]  di      = 16'd0;
    reg                 done    =  1'd0;
    reg         [ 6:0]  fsm     =  7'd1;

    //---------- DRP Address -------------------------------
    localparam          ADDR_QPLL_FBDIV               = 8'h36;
    localparam          ADDR_CRSCODE                  = 8'h88;
    localparam          ADDR_QPLL_COARSE_FREQ_OVRD    = 8'h35;
    localparam          ADDR_QPLL_COARSE_FREQ_OVRD_EN = 8'h36;
    localparam          ADDR_QPLL_LOCK_CFG            = 8'h34;

    //---------- DRP Mask ----------------------------------
    localparam          MASK_QPLL_FBDIV               = 16'b1111110000000000;  // Unmask bit [ 9: 0]
    localparam          MASK_QPLL_COARSE_FREQ_OVRD    = 16'b0000001111111111;  // Unmask bit [15:10]
    localparam          MASK_QPLL_COARSE_FREQ_OVRD_EN = 16'b1111011111111111;  // Unmask bit [   11]
    localparam          MASK_QPLL_LOCK_CFG            = 16'b1110011111111111;  // Unmask bit [12:11]

    //---------- DRP Data for Normal QPLLLOCK Mode ---------
    localparam          NORM_QPLL_COARSE_FREQ_OVRD    = 16'b0000000000000000;  // Coarse freq value
    localparam          NORM_QPLL_COARSE_FREQ_OVRD_EN = 16'b0000000000000000;  // Normal QPLL lock
    localparam          NORM_QPLL_LOCK_CFG            = 16'b0000000000000000;  // Normal QPLL lock config

    //---------- DRP Data for Optimize QPLLLOCK Mode -------
    localparam          OVRD_QPLL_COARSE_FREQ_OVRD    = 16'b0000000000000000;  // Coarse freq value
    localparam          OVRD_QPLL_COARSE_FREQ_OVRD_EN = 16'b0000100000000000;  // Override QPLL lock
    localparam          OVRD_QPLL_LOCK_CFG            = 16'b0000000000000000;  // Override QPLL lock config

    //---------- Select QPLL Feedback Divider --------------
    //  N = 100 for 100 MHz ref clk and 10Gb/s line rate
    //  N =  80 for 125 MHz ref clk and 10Gb/s line rate
    //  N =  40 for 250 MHz ref clk and 10Gb/s line rate
    //------------------------------------------------------
    //  N =  80 for 100 MHz ref clk and  8Gb/s line rate
    //  N =  64 for 125 MHz ref clk and  8Gb/s line rate
    //  N =  32 for 250 MHz ref clk and  8Gb/s line rate
    //------------------------------------------------------
    localparam          QPLL_FBDIV = (PCIE_REFCLK_FREQ == 2) && (PCIE_PLL_SEL == "QPLL") ? 16'b0000000010000000 :
                                     (PCIE_REFCLK_FREQ == 1) && (PCIE_PLL_SEL == "QPLL") ? 16'b0000000100100000 :
                                     (PCIE_REFCLK_FREQ == 0) && (PCIE_PLL_SEL == "QPLL") ? 16'b0000000101110000 :
                                     (PCIE_REFCLK_FREQ == 2) && (PCIE_PLL_SEL == "CPLL") ? 16'b0000000001100000 :
                                     (PCIE_REFCLK_FREQ == 1) && (PCIE_PLL_SEL == "CPLL") ? 16'b0000000011100000 : 16'b0000000100100000;

    localparam          GEN12_QPLL_FBDIV = (PCIE_REFCLK_FREQ == 2) ? 16'b0000000010000000 :
                                           (PCIE_REFCLK_FREQ == 1) ? 16'b0000000100100000 : 16'b0000000101110000;

    localparam          GEN3_QPLL_FBDIV  = (PCIE_REFCLK_FREQ == 2) ? 16'b0000000001100000 :
                                           (PCIE_REFCLK_FREQ == 1) ? 16'b0000000011100000 : 16'b0000000100100000;

    //---------- DRP Data ----------------------------------
    wire        [15:0]  data_qpll_fbdiv;
    wire        [15:0]  data_qpll_coarse_freq_ovrd;
    wire        [15:0]  data_qpll_coarse_freq_ovrd_en;
    wire        [15:0]  data_qpll_lock_cfg;

    //---------- FSM ---------------------------------------
    localparam          FSM_IDLE  = 7'b0000001;
    localparam          FSM_LOAD  = 7'b0000010;
    localparam          FSM_READ  = 7'b0000100;
    localparam          FSM_RRDY  = 7'b0001000;
    localparam          FSM_WRITE = 7'b0010000;
    localparam          FSM_WRDY  = 7'b0100000;
    localparam          FSM_DONE  = 7'b1000000;



//---------- Input FF ----------------------------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        ovrd_reg1  <=  1'd0;
        gen3_reg1  <=  1'd0;
        start_reg1 <=  1'd0;
        do_reg1    <= 16'd0;
        rdy_reg1   <=  1'd0;
        //---------- 2nd Stage FF --------------------------
        ovrd_reg2  <=  1'd0;
        gen3_reg2  <=  1'd0;
        start_reg2 <=  1'd0;
        do_reg2    <= 16'd0;
        rdy_reg2   <=  1'd0;
        end

    else
        begin
        //---------- 1st Stage FF --------------------------
        ovrd_reg1  <= DRP_OVRD;
        gen3_reg1  <= DRP_GEN3;
        start_reg1 <= DRP_START;
        do_reg1    <= DRP_DO;
        rdy_reg1   <= DRP_RDY;
        //---------- 2nd Stage FF --------------------------
        ovrd_reg2  <= ovrd_reg1;
        gen3_reg2  <= gen3_reg1;
        start_reg2 <= start_reg1;
        do_reg2    <= do_reg1;
        rdy_reg2   <= rdy_reg1;
        end

end



//---------- Select DRP Data ---------------------------------------------------
assign data_qpll_fbdiv               = (gen3_reg2) ? GEN3_QPLL_FBDIV : GEN12_QPLL_FBDIV;
assign data_qpll_coarse_freq_ovrd    =  NORM_QPLL_COARSE_FREQ_OVRD;
assign data_qpll_coarse_freq_ovrd_en = (ovrd_reg2) ? OVRD_QPLL_COARSE_FREQ_OVRD_EN : NORM_QPLL_COARSE_FREQ_OVRD_EN;
assign data_qpll_lock_cfg            = (ovrd_reg2) ? OVRD_QPLL_LOCK_CFG            : NORM_QPLL_LOCK_CFG;



//---------- Update DRP Address and Data ---------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        addr    <=  8'd0;
        di      <= 16'd0;
        crscode <=  6'd0;
        end
    else
        begin

        case (index)

        //--------------------------------------------------
        3'd0 :
            begin
            addr    <= ADDR_QPLL_FBDIV;
            di      <= (do_reg2 & MASK_QPLL_FBDIV) | (mode ? data_qpll_fbdiv : QPLL_FBDIV);
            crscode <= crscode;
            end

        //--------------------------------------------------
        3'd1 :
            begin
            addr <= ADDR_CRSCODE;
            di   <= do_reg2;

            //---------- Latch CRS Code --------------------
            if (ovrd_reg2)
                crscode <= do_reg2[6:1];
            else
                crscode <= crscode;
            end

        //--------------------------------------------------
        3'd2 :
            begin
            addr    <= ADDR_QPLL_COARSE_FREQ_OVRD;
            di      <= (do_reg2 & MASK_QPLL_COARSE_FREQ_OVRD) | {(crscode - 6'd1), data_qpll_coarse_freq_ovrd[9:0]};
            crscode <= crscode;
            end

        //--------------------------------------------------
        3'd3 :
            begin
            addr    <= ADDR_QPLL_COARSE_FREQ_OVRD_EN;
            di      <= (do_reg2 & MASK_QPLL_COARSE_FREQ_OVRD_EN) | data_qpll_coarse_freq_ovrd_en;
            crscode <= crscode;
            end

        //--------------------------------------------------
        3'd4 :
            begin
            addr    <= ADDR_QPLL_LOCK_CFG;
            di      <= (do_reg2 & MASK_QPLL_LOCK_CFG) | data_qpll_lock_cfg;
            crscode <= crscode;
            end

        //--------------------------------------------------
        default :
            begin
            addr    <=  8'd0;
            di      <= 16'd0;
            crscode <=  6'd0;
            end

        endcase

        end

end



//---------- QPLL DRP FSM ------------------------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        fsm   <= FSM_IDLE;
        index <= 3'd0;
        mode  <= 1'd0;
        done  <= 1'd0;
        end
    else
        begin

        case (fsm)

        //---------- Idle State ----------------------------
        FSM_IDLE :

            begin
            if (start_reg2)
                begin
                fsm   <= FSM_LOAD;
                index <= 3'd0;
                mode  <= 1'd0;
                done  <= 1'd0;
                end
            else if ((gen3_reg2 != gen3_reg1) && (PCIE_PLL_SEL == "QPLL"))
                begin
                fsm   <= FSM_LOAD;
                index <= 3'd0;
                mode  <= 1'd1;
                done  <= 1'd0;
                end
            else
                begin
                fsm   <= FSM_IDLE;
                index <= 3'd0;
                mode  <= 1'd0;
                done  <= 1'd1;
                end
            end

        //---------- Load DRP Address  ---------------------
        FSM_LOAD :

            begin
            fsm   <= FSM_READ;
            index <= index;
            mode  <= mode;
            done  <= 1'd0;
            end

        //---------- Read DRP ------------------------------
        FSM_READ :

            begin
            fsm   <= FSM_RRDY;
            index <= index;
            mode  <= mode;
            done  <= 1'd0;
            end

        //---------- Read DRP Ready ------------------------
        FSM_RRDY :

            begin
            fsm   <= (rdy_reg2 ? FSM_WRITE : FSM_RRDY);
            index <= index;
            mode  <= mode;
            done  <= 1'd0;
            end

        //---------- Write DRP -----------------------------
        FSM_WRITE :

            begin
            fsm   <= FSM_WRDY;
            index <= index;
            mode  <= mode;
            done  <= 1'd0;
            end

        //---------- Write DRP Ready -----------------------
        FSM_WRDY :

            begin
            fsm   <= (rdy_reg2 ? FSM_DONE : FSM_WRDY);
            index <= index;
            mode  <= mode;
            done  <= 1'd0;
            end

        //---------- DRP Done ------------------------------
        FSM_DONE :

            begin
            if ((index == INDEX_MAX) || (mode && (index == 3'd0)))
                begin
                fsm   <= FSM_IDLE;
                index <= 3'd0;
                mode  <= mode;
                done  <= 1'd0;
                end
            else
                begin
                fsm   <= FSM_LOAD;
                index <= index + 3'd1;
                mode  <= mode;
                done  <= 1'd0;
                end
            end

        //---------- Default State -------------------------
        default :

            begin
            fsm   <= FSM_IDLE;
            index <= 3'd0;
            mode  <= 1'd0;
            done  <= 1'd0;
            end

        endcase

        end

end



//---------- QPLL DRP Output ---------------------------------------------------
assign DRP_ADDR    = addr;
assign DRP_EN      = (fsm == FSM_READ) || (fsm == FSM_WRITE);
assign DRP_DI      = di;
assign DRP_WE      = (fsm == FSM_WRITE) || (fsm == FSM_WRDY);
assign DRP_DONE    = done;
assign DRP_CRSCODE = crscode;
assign DRP_FSM     = fsm;



endmodule
