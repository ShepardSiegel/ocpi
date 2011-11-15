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
// File       : pcie_7x_v1_2_pipe_reset.v
// Version    : 1.2
//------------------------------------------------------------------------------
//  Filename     :  pipe_reset.v
//  Description  :  PIPE Reset Module for 7 Series Transceiver
//  Version      :  11.2
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Reset Module -------------------------------------------------
module pcie_7x_v1_2_pipe_reset #
(

    //---------- Global ------------------------------------
    parameter PCIE_PLL_SEL      = "CPLL",                   // PCIe PLL select for Gen1/Gen2 only
    parameter PCIE_POWER_SAVING = "TRUE",                   // PCIe power saving
    parameter PCIE_TXBUF_EN     = "FALSE",                  // PCIe TX buffer enable
    parameter PCIE_LANE         = 1,                        // PCIe number of lanes
    //---------- Local -------------------------------------
    parameter CFG_WAIT_MAX      = 6'd63,                    // Configuration wait max
    parameter BYPASS_RXCDRLOCK  = 1                         // Bypass RXCDRLOCK

)

(

    //---------- Input -------------------------------------
    input                           RST_CLK,
    input                           RST_RXUSRCLK,
    input                           RST_DCLK,
    input                           RST_RST_N,
    input       [PCIE_LANE-1:0]     RST_CPLLLOCK,
    input                           RST_QPLL_IDLE,
    input       [PCIE_LANE-1:0]     RST_RATE_IDLE,
    input       [PCIE_LANE-1:0]     RST_RXCDRLOCK,
    input                           RST_MMCM_LOCK,
    input       [PCIE_LANE-1:0]     RST_RESETDONE,
    input       [PCIE_LANE-1:0]     RST_PHYSTATUS,
    input       [PCIE_LANE-1:0]     RST_TXSYNC_DONE,

    //---------- Output ------------------------------------
    output                          RST_CPLLRESET,
    output                          RST_CPLLPD,
    output                          RST_RXUSRCLK_RESET,
    output                          RST_DCLK_RESET,
    output                          RST_GTRESET,
    output                          RST_USERRDY,
    output                          RST_TXSYNC_START,
    output                          RST_IDLE,
    output      [10:0]              RST_FSM

);

    //---------- Input Register ----------------------------
    reg         [PCIE_LANE-1:0]     cplllock_reg1;
    reg                             qpll_idle_reg1;
    reg         [PCIE_LANE-1:0]     rate_idle_reg1;
    reg         [PCIE_LANE-1:0]     rxcdrlock_reg1;
    reg                             mmcm_lock_reg1;
    reg         [PCIE_LANE-1:0]     resetdone_reg1;
    reg         [PCIE_LANE-1:0]     phystatus_reg1;
    reg         [PCIE_LANE-1:0]     txsync_done_reg1;

    reg         [PCIE_LANE-1:0]     cplllock_reg2;
    reg                             qpll_idle_reg2;
    reg         [PCIE_LANE-1:0]     rate_idle_reg2;
    reg         [PCIE_LANE-1:0]     rxcdrlock_reg2;
    reg                             mmcm_lock_reg2;
    reg         [PCIE_LANE-1:0]     resetdone_reg2;
    reg         [PCIE_LANE-1:0]     phystatus_reg2;
    reg         [PCIE_LANE-1:0]     txsync_done_reg2;

    //---------- Internal Signal ---------------------------
    reg         [ 5:0]              cfg_wait_cnt      =  6'd0;

    //---------- Output Register ---------------------------
    reg                             cpllreset         =  1'd0;
    reg                             cpllpd            =  1'd0;
    reg                             rxusrclk_rst_reg1 =  1'd0;
    reg                             rxusrclk_rst_reg2 =  1'd0;
    reg                             dclk_rst_reg1     =  1'd0;
    reg                             dclk_rst_reg2     =  1'd0;
    reg                             gtreset           =  1'd0;
    reg                             userrdy           =  1'd0;
    reg         [10:0]              fsm               = 11'd2;

    //---------- FSM ---------------------------------------
    localparam                      FSM_IDLE          = 11'b00000000001;
    localparam                      FSM_CFG_WAIT      = 11'b00000000010;
    localparam                      FSM_CPLLRESET     = 11'b00000000100;
    localparam                      FSM_CPLLLOCK      = 11'b00000001000;
    localparam                      FSM_DRP           = 11'b00000010000;
    localparam                      FSM_GTRESET       = 11'b00000100000;
    localparam                      FSM_MMCM_LOCK     = 11'b00001000000;
    localparam                      FSM_RESETDONE     = 11'b00010000000;
    localparam                      FSM_CPLL_PD       = 11'b00100000000;
    localparam                      FSM_TXSYNC_START  = 11'b01000000000;
    localparam                      FSM_TXSYNC_DONE   = 11'b10000000000;



//---------- Input FF ----------------------------------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        cplllock_reg1    <= {PCIE_LANE{1'd0}};
        qpll_idle_reg1   <= 1'd0;
        rate_idle_reg1   <= {PCIE_LANE{1'd0}};
        rxcdrlock_reg1   <= {PCIE_LANE{1'd0}};
        mmcm_lock_reg1   <= 1'd0;
        resetdone_reg1   <= {PCIE_LANE{1'd0}};
        phystatus_reg1   <= {PCIE_LANE{1'd0}};
        txsync_done_reg1 <= {PCIE_LANE{1'd0}};
        //---------- 2nd Stage FF --------------------------
        cplllock_reg2    <= {PCIE_LANE{1'd0}};
        qpll_idle_reg2   <= 1'd0;
        rate_idle_reg2   <= {PCIE_LANE{1'd0}};
        rxcdrlock_reg2   <= {PCIE_LANE{1'd0}};
        mmcm_lock_reg2   <= 1'd0;
        resetdone_reg2   <= {PCIE_LANE{1'd0}};
        phystatus_reg2   <= {PCIE_LANE{1'd0}};
        txsync_done_reg2 <= {PCIE_LANE{1'd0}};
        end
    else
        begin
        //---------- 1st Stage FF --------------------------
        cplllock_reg1    <= RST_CPLLLOCK;
        qpll_idle_reg1   <= RST_QPLL_IDLE;
        rate_idle_reg1   <= RST_RATE_IDLE;
        rxcdrlock_reg1   <= RST_RXCDRLOCK;
        mmcm_lock_reg1   <= RST_MMCM_LOCK;
        resetdone_reg1   <= RST_RESETDONE;
        phystatus_reg1   <= RST_PHYSTATUS;
        txsync_done_reg1 <= RST_TXSYNC_DONE;
        //---------- 2nd Stage FF --------------------------
        cplllock_reg2    <= cplllock_reg1;
        qpll_idle_reg2   <= qpll_idle_reg1;
        rate_idle_reg2   <= rate_idle_reg1;
        rxcdrlock_reg2   <= rxcdrlock_reg1;
        mmcm_lock_reg2   <= mmcm_lock_reg1;
        resetdone_reg2   <= resetdone_reg1;
        phystatus_reg2   <= phystatus_reg1;
        txsync_done_reg2 <= txsync_done_reg1;
        end

end



//---------- Configuration Reset Wait Counter ----------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
        cfg_wait_cnt <= 6'd0;
    else

        //---------- Increment Configuration Reset Wait Counter
        if ((fsm == FSM_CFG_WAIT) && (cfg_wait_cnt < CFG_WAIT_MAX))
            cfg_wait_cnt <= cfg_wait_cnt + 6'd1;

        //---------- Hold Configuration Reset Wait Counter -
        else if ((fsm == FSM_CFG_WAIT) && (cfg_wait_cnt == CFG_WAIT_MAX))
            cfg_wait_cnt <= cfg_wait_cnt;

        //---------- Reset Configuration Reset Wait Counter
        else
            cfg_wait_cnt <= 6'd0;

end



//---------- PIPE Reset FSM ----------------------------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
        begin
        fsm       <= FSM_CFG_WAIT;
        cpllreset <= 1'd0;
        cpllpd    <= 1'd0;
        gtreset   <= 1'd0;
        userrdy   <= 1'd0;
        end
    else
        begin

        case (fsm)

        //---------- Idle State ----------------------------
        FSM_IDLE :

            begin
            if (!RST_RST_N)
                begin
                fsm       <= FSM_CFG_WAIT;
                cpllreset <= 1'd0;
                cpllpd    <= 1'd0;
                gtreset   <= 1'd0;
                userrdy   <= 1'd0;
                end
            else
                begin
                fsm       <= FSM_IDLE;
                cpllreset <= cpllreset;
                cpllpd    <= cpllpd;
                gtreset   <= gtreset;
                userrdy   <= userrdy;
                end
            end

        //----------  Wait for Configuration Reset Delay ---
        FSM_CFG_WAIT :

            begin
            fsm       <= ((cfg_wait_cnt == CFG_WAIT_MAX) ? FSM_CPLLRESET : FSM_CFG_WAIT);
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Hold CPLL and GTX Channel in Reset ----
        FSM_CPLLRESET :

            begin
            fsm       <= ((&(~cplllock_reg2) && (&(~resetdone_reg2))) ? FSM_CPLLLOCK : FSM_CPLLRESET);
            cpllreset <= 1'd1;
            cpllpd    <= cpllpd;
            gtreset   <= 1'd1;
            userrdy   <= userrdy;
            end

        //---------- Wait for CPLL Lock --------------------
        FSM_CPLLLOCK :

            begin
            fsm       <= (&cplllock_reg2 ? FSM_DRP : FSM_CPLLLOCK);
            cpllreset <= 1'd0;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Wait for DRP Done to Setup Gen1 -------
        FSM_DRP :

            begin
            fsm       <= (&rate_idle_reg2 ? FSM_GTRESET : FSM_DRP);
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Release GTX Channel Reset -------------
        FSM_GTRESET :

            begin
            fsm       <= FSM_MMCM_LOCK;
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= 1'b0;
            userrdy   <= userrdy;
            end

        //---------- Wait for MMCM and RX CDR Lock ---------
        FSM_MMCM_LOCK :

            begin
            if (mmcm_lock_reg2 && (&rxcdrlock_reg2 || (BYPASS_RXCDRLOCK == 1)) && (qpll_idle_reg2 || (PCIE_PLL_SEL == "CPLL")))
                begin
                fsm       <= FSM_RESETDONE;
                cpllreset <= cpllreset;
                cpllpd    <= cpllpd;
                gtreset   <= gtreset;
                userrdy   <= 1'd1;
                end
            else
                begin
                fsm       <= FSM_MMCM_LOCK;
                cpllreset <= cpllreset;
                cpllpd    <= cpllpd;
                gtreset   <= gtreset;
                userrdy   <= 1'd0;
                end
            end

        //---------- Wait for [TX/RX]RESETDONE and PHYSTATUS
        FSM_RESETDONE :

            begin
            fsm       <= (&resetdone_reg2 && (&(~phystatus_reg2)) ? FSM_CPLL_PD : FSM_RESETDONE);
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Power-Down CPLL if QPLL is Used for Gen1/Gen2
        FSM_CPLL_PD :

            begin
            fsm       <= ((PCIE_TXBUF_EN == "TRUE") ? FSM_IDLE : FSM_TXSYNC_START);
            cpllreset <= cpllreset;
            cpllpd    <= (PCIE_PLL_SEL == "QPLL");
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Start TX Sync -------------------------
        FSM_TXSYNC_START :

            begin
            fsm       <= (&(~txsync_done_reg2) ? FSM_TXSYNC_DONE : FSM_TXSYNC_START);
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Wait for TX Sync Done -----------------
        FSM_TXSYNC_DONE :

            begin
            fsm       <= (&txsync_done_reg2 ? FSM_IDLE : FSM_TXSYNC_DONE);
            cpllreset <= cpllreset;
            cpllpd    <= cpllpd;
            gtreset   <= gtreset;
            userrdy   <= userrdy;
            end

        //---------- Default State -------------------------
        default :

            begin
            fsm       <= FSM_CFG_WAIT;
            cpllreset <= 1'd0;
            cpllpd    <= 1'd0;
            gtreset   <= 1'd0;
            userrdy   <= 1'd0;
            end

        endcase

        end

end



//---------- RXUSRCLK Reset Synchronizer ---------------------------------------
always @ (posedge RST_RXUSRCLK)
begin

    if (cpllreset)
        begin
        rxusrclk_rst_reg1 <= 1'd1;
        rxusrclk_rst_reg2 <= 1'd1;
        end
    else
        begin
        rxusrclk_rst_reg1 <= 1'd0;
        rxusrclk_rst_reg2 <= rxusrclk_rst_reg1;
        end

end



//---------- DCLK Reset Synchronizer -------------------------------------------
always @ (posedge RST_DCLK)
begin

    if (cpllreset)
        begin
        dclk_rst_reg1 <= 1'd1;
        dclk_rst_reg2 <= 1'd1;
        end
    else
        begin
        dclk_rst_reg1 <= 1'd0;
        dclk_rst_reg2 <= dclk_rst_reg1;
        end

end



//---------- PIPE Reset Output -------------------------------------------------
assign RST_CPLLRESET      = cpllreset;
assign RST_CPLLPD         = ((PCIE_POWER_SAVING == "FALSE") ? 1'd0 : cpllpd);
assign RST_RXUSRCLK_RESET = rxusrclk_rst_reg2;
assign RST_DCLK_RESET     = dclk_rst_reg2;
assign RST_GTRESET        = gtreset;
assign RST_USERRDY        = userrdy;
assign RST_TXSYNC_START   = (fsm == FSM_TXSYNC_START);
assign RST_IDLE           = (fsm == FSM_IDLE);
assign RST_FSM            = fsm;



endmodule
