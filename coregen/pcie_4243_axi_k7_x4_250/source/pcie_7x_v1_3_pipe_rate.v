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
// File       : pcie_7x_v1_3_pipe_rate.v
// Version    : 1.3
//------------------------------------------------------------------------------
//  Filename     :  pipe_rate.v
//  Description  :  PIPE Rate Module for 7 Series Transceiver
//  Version      :  11.4
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Rate Module --------------------------------------------------
module pcie_7x_v1_3_pipe_rate #
(

    parameter PCIE_USE_MODE     = "1.1",                    // PCIe use mode
    parameter PCIE_PLL_SEL      = "CPLL",                   // PCIe PLL select for Gen1/Gen2 only
    parameter PCIE_POWER_SAVING = "TRUE",                   // PCIe power saving
    parameter PCIE_ASYNC_EN     = "FALSE",                  // PCIe async enable
    parameter PCIE_TXBUF_EN     = "FALSE",                  // PCIe TX buffer enable for Gen1/Gen2 only
    parameter PCIE_RXBUF_EN     = "TRUE",                   // PCIe RX buffer enable for Gen3      only
    parameter TXDATA_WAIT_MAX   = 4'd15                     // TXDATA wait max

)

(

    //---------- Input -------------------------------------
    input               RATE_CLK,
    input               RATE_RST_N,
    input               RATE_RST_IDLE,
    input       [ 1:0]  RATE_RATE_IN,
    input               RATE_CPLLLOCK,
    input               RATE_QPLLLOCK,
    input               RATE_MMCM_LOCK,
    input               RATE_DRP_DONE,
    input               RATE_TXRESETDONE,
    input               RATE_RXRESETDONE,
    input               RATE_TXRATEDONE,
    input               RATE_RXRATEDONE,
    input               RATE_PHYSTATUS,
    input               RATE_RESETOVRD_DONE,
    input               RATE_TXSYNC_DONE,
    input               RATE_RXSYNC_DONE,

    //---------- Output ------------------------------------
    output              RATE_CPLLPD,
    output              RATE_QPLLPD,
    output              RATE_CPLLRESET,
    output              RATE_QPLLRESET,
    output              RATE_TXPMARESET,
    output              RATE_RXPMARESET,
    output              RATE_DRP_START,
    output      [ 1:0]  RATE_SYSCLKSEL,
    output              RATE_PCLK_SEL,
    output              RATE_GEN3,
    output      [ 2:0]  RATE_RATE_OUT,
    output              RATE_RESETOVRD_START,
    output              RATE_TXSYNC_START,
    output              RATE_DONE,
    output              RATE_RXSYNC_START,
    output              RATE_RXSYNC,
    output              RATE_IDLE,
    output      [23:0]  RATE_FSM

);

    //---------- Input FF or Buffer ------------------------
    reg                 rst_idle_reg1;
    reg         [ 1:0]  rate_in_reg1;
    reg                 cplllock_reg1;
    reg                 qplllock_reg1;
    reg                 mmcm_lock_reg1;
    reg                 drp_done_reg1;
    reg                 txresetdone_reg1;
    reg                 rxresetdone_reg1;
    reg                 txratedone_reg1;
    reg                 rxratedone_reg1;
    reg                 phystatus_reg1;
    reg                 resetovrd_done_reg1;
    reg                 txsync_done_reg1;
    reg                 rxsync_done_reg1;

    reg                 rst_idle_reg2;
    reg         [ 1:0]  rate_in_reg2;
    reg                 cplllock_reg2;
    reg                 qplllock_reg2;
    reg                 mmcm_lock_reg2;
    reg                 drp_done_reg2;
    reg                 txresetdone_reg2;
    reg                 rxresetdone_reg2;
    reg                 txratedone_reg2;
    reg                 rxratedone_reg2;
    reg                 phystatus_reg2;
    reg                 resetovrd_done_reg2;
    reg                 txsync_done_reg2;
    reg                 rxsync_done_reg2;

    //---------- Internal Signals --------------------------
    wire                pll_lock;
    wire        [ 2:0]  rate;
    reg         [ 3:0]  txdata_wait_cnt = 4'd0;
    reg                 txratedone      = 1'd0;
    reg                 rxratedone      = 1'd0;
    reg                 phystatus       = 1'd0;
    reg                 ratedone        = 1'd0;
    reg                 gen3_exit       = 1'd0;

    //---------- Output FF or Buffer -----------------------
    reg                 cpllpd     =  1'd0;
    reg                 qpllpd     =  1'd0;
    reg                 cpllreset  =  1'd0;
    reg                 qpllreset  =  1'd0;
    reg                 txpmareset =  1'd0;
    reg                 rxpmareset =  1'd0;
    reg         [ 1:0]  sysclksel  = (PCIE_PLL_SEL == "QPLL") ? 2'd1 : 2'd0;
    reg                 gen3       =  1'd0;
    reg                 pclk_sel   =  1'd0;
    reg         [ 2:0]  rate_out   =  3'd0;
    reg         [23:0]  fsm        = 24'd0;

    //---------- FSM ---------------------------------------
    localparam          FSM_IDLE             = 24'b000000000000000000000001;
    localparam          FSM_PLL_PU           = 24'b000000000000000000000010; // Gen 3 only
    localparam          FSM_PLL_PURESET      = 24'b000000000000000000000100; // Gen 3 only
    localparam          FSM_PLL_LOCK         = 24'b000000000000000000001000; // Gen 3 or reset only
    localparam          FSM_PMARESET_HOLD    = 24'b000000000000000000010000; // Gen 3 or reset only
    localparam          FSM_PLL_SEL          = 24'b000000000000000000100000; // Gen 3 or reset only
    localparam          FSM_MMCM_LOCK        = 24'b000000000000000001000000; // Gen 3 or reset only
    localparam          FSM_DRP_START        = 24'b000000000000000010000000; // Gen 3 or reset only
    localparam          FSM_DRP_DONE         = 24'b000000000000000100000000; // Gen 3 or reset only
    localparam          FSM_PMARESET_RELEASE = 24'b000000000000001000000000; // Gen 3 only
    localparam          FSM_PMARESET_DONE    = 24'b000000000000010000000000; // Gen 3 only
    localparam          FSM_TXDATA_WAIT      = 24'b000000000000100000000000;
    localparam          FSM_PCLK_SEL         = 24'b000000000001000000000000;
    localparam          FSM_RATE_SEL         = 24'b000000000010000000000000;
    localparam          FSM_RATE_DONE        = 24'b000000000100000000000000;
    localparam          FSM_RESETOVRD_START  = 24'b000000001000000000000000; // PCIe use mode 1.0 only
    localparam          FSM_RESETOVRD_DONE   = 24'b000000010000000000000000; // PCIe use mode 1.0 only
    localparam          FSM_PLL_PDRESET      = 24'b000000100000000000000000;
    localparam          FSM_PLL_PD           = 24'b000001000000000000000000;
    localparam          FSM_TXSYNC_START     = 24'b000010000000000000000000;
    localparam          FSM_TXSYNC_DONE      = 24'b000100000000000000000000;
    localparam          FSM_DONE             = 24'b001000000000000000000000; // Must sync value to pipe_user.v
    localparam          FSM_RXSYNC_START     = 24'b010000000000000000000000; // Gen 3 only
    localparam          FSM_RXSYNC_DONE      = 24'b100000000000000000000000; // Gen 3 only



//---------- Input FF ----------------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        rst_idle_reg1       <= 1'd0;
        rate_in_reg1        <= 2'd0;
        cplllock_reg1       <= 1'd0;
        qplllock_reg1       <= 1'd0;
        mmcm_lock_reg1      <= 1'd0;
        drp_done_reg1       <= 1'd0;
        txresetdone_reg1    <= 1'd0;
        rxresetdone_reg1    <= 1'd0;
        txratedone_reg1     <= 1'd0;
        rxratedone_reg1     <= 1'd0;
        phystatus_reg1      <= 1'd0;
        resetovrd_done_reg1 <= 1'd0;
        txsync_done_reg1    <= 1'd0;
        rxsync_done_reg1    <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        rst_idle_reg2       <= 1'd0;
        rate_in_reg2        <= 2'd0;
        cplllock_reg2       <= 1'd0;
        qplllock_reg2       <= 1'd0;
        mmcm_lock_reg2      <= 1'd0;
        drp_done_reg2       <= 1'd0;
        txresetdone_reg2    <= 1'd0;
        rxresetdone_reg2    <= 1'd0;
        txratedone_reg2     <= 1'd0;
        rxratedone_reg2     <= 1'd0;
        phystatus_reg2      <= 1'd0;
        resetovrd_done_reg2 <= 1'd0;
        txsync_done_reg2    <= 1'd0;
        rxsync_done_reg2    <= 1'd0;
        end
    else
        begin
        //---------- 1st Stage FF --------------------------
        rst_idle_reg1       <= RATE_RST_IDLE;
        rate_in_reg1        <= RATE_RATE_IN;
        cplllock_reg1       <= RATE_CPLLLOCK;
        qplllock_reg1       <= RATE_QPLLLOCK;
        mmcm_lock_reg1      <= RATE_MMCM_LOCK;
        drp_done_reg1       <= RATE_DRP_DONE;
        txresetdone_reg1    <= RATE_TXRESETDONE;
        rxresetdone_reg1    <= RATE_RXRESETDONE;
        txratedone_reg1     <= RATE_TXRATEDONE;
        rxratedone_reg1     <= RATE_RXRATEDONE;
        phystatus_reg1      <= RATE_PHYSTATUS;
        resetovrd_done_reg1 <= RATE_RESETOVRD_DONE;
        txsync_done_reg1    <= RATE_TXSYNC_DONE;
        rxsync_done_reg1    <= RATE_RXSYNC_DONE;
        //---------- 2nd Stage FF --------------------------
        rst_idle_reg2       <= rst_idle_reg1;
        rate_in_reg2        <= rate_in_reg1;
        cplllock_reg2       <= cplllock_reg1;
        qplllock_reg2       <= qplllock_reg1;
        mmcm_lock_reg2      <= mmcm_lock_reg1;
        drp_done_reg2       <= drp_done_reg1;
        txresetdone_reg2    <= txresetdone_reg1;
        rxresetdone_reg2    <= rxresetdone_reg1;
        txratedone_reg2     <= txratedone_reg1;
        rxratedone_reg2     <= rxratedone_reg1;
        phystatus_reg2      <= phystatus_reg1;
        resetovrd_done_reg2 <= resetovrd_done_reg1;
        txsync_done_reg2    <= txsync_done_reg1;
        rxsync_done_reg2    <= rxsync_done_reg1;
        end

end



//---------- Select CPLL or QPLL Lock ------------------------------------------
//  Gen1 : Wait for QPLL lock if QPLL is used for Gen1/Gen2, else wait for CPLL lock
//  Gen2 : Wait for QPLL lock if QPLL is used for Gen1/Gen2, else wait for CPLL lock
//  Gen3 : Wait for QPLL lock
//------------------------------------------------------------------------------
assign pll_lock = (rate_in_reg2 == 2'd2) || (PCIE_PLL_SEL == "QPLL") ? qplllock_reg2 : cplllock_reg2;



//---------- Select Rate -------------------------------------------------------
//  Gen1 : Div 4 using [TX/RX]OUT_DIV = 4 if QPLL is used for Gen1/Gen2, else div 2 using [TX/RX]OUT_DIV = 2
//  Gen2 : Div 2 using [TX/RX]RATE = 3'd2 if QPLL is used for Gen1/Gen2, else div 1 using [TX/RX]RATE = 3'd1
//  Gen3 : Div 1 using [TX/RX]OUT_DIV = 1
//------------------------------------------------------------------------------
assign rate = (rate_in_reg2 == 2'd1) && (PCIE_PLL_SEL == "QPLL") ? 3'd2 :
              (rate_in_reg2 == 2'd1) && (PCIE_PLL_SEL == "CPLL") ? 3'd1 : 3'd0;



//---------- TXDATA Wait Counter -----------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        txdata_wait_cnt <= 4'd0;
    else

        //---------- Increment Wait Counter ----------------
        if ((fsm == FSM_TXDATA_WAIT) && (txdata_wait_cnt < TXDATA_WAIT_MAX))
            txdata_wait_cnt <= txdata_wait_cnt + 4'd1;

        //---------- Hold Wait Counter ---------------------
        else if ((fsm == FSM_TXDATA_WAIT) && (txdata_wait_cnt == TXDATA_WAIT_MAX))
            txdata_wait_cnt <= txdata_wait_cnt;

        //---------- Reset Wait Counter --------------------
        else
            txdata_wait_cnt <= 4'd0;

end



//---------- Latch TXRATEDONE, RXRATEDONE, and PHYSTATUS -----------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin
        txratedone <= 1'd0;
        rxratedone <= 1'd0;
        phystatus  <= 1'd0;
        ratedone   <= 1'd0;
        end
    else
        begin

        if (fsm == FSM_RATE_DONE)

            begin

            //---------- Latch TXRATEDONE ------------------
            if (txratedone_reg2)
                txratedone <= 1'd1;
            else
                txratedone <= txratedone;

            //---------- Latch RXRATEDONE ------------------
            if (rxratedone_reg2)
                rxratedone <= 1'd1;
            else
                rxratedone <= rxratedone;

            //---------- Latch PHYSTATUS -------------------
            if (phystatus_reg2)
                phystatus <= 1'd1;
            else
                phystatus <= phystatus;

            //---------- Latch Rate Done -------------------
            if (rxratedone && txratedone && phystatus)
                ratedone <= 1'd1;
            else
                ratedone <= ratedone;

            end

        else

            begin
            txratedone <= 1'd0;
            rxratedone <= 1'd0;
            phystatus  <= 1'd0;
            ratedone   <= 1'd0;
            end

        end

end



//---------- PIPE Rate FSM -----------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin
        fsm        <= FSM_PLL_LOCK;
        gen3_exit  <= 1'd0;
        cpllpd     <= 1'd0;
        qpllpd     <= 1'd0;
        cpllreset  <= 1'd0;
        qpllreset  <= 1'd0;
        txpmareset <= 1'd0;
        rxpmareset <= 1'd0;
        sysclksel  <= (PCIE_PLL_SEL == "QPLL") ? 2'd1 : 2'd0;
        pclk_sel   <= 1'd0;
        gen3       <= 1'd0;
        rate_out   <= 3'd0;
        end
    else
        begin

        case (fsm)

        //---------- Idle State ----------------------------
        FSM_IDLE :

            begin
            //---------- Detect Rate Change ----------------
            if (rate_in_reg2 != rate_in_reg1)
                begin
                fsm        <= ((rate_in_reg2 == 2'd2) || (rate_in_reg1 == 2'd2)) ? FSM_PLL_PU : FSM_TXDATA_WAIT;
                gen3_exit  <= (rate_in_reg2 == 2'd2);
                cpllpd     <= cpllpd;
                qpllpd     <= qpllpd;
                cpllreset  <= cpllreset;
                qpllreset  <= qpllreset;
                txpmareset <= txpmareset;
                rxpmareset <= rxpmareset;
                sysclksel  <= sysclksel;
                pclk_sel   <= pclk_sel;
                gen3       <= gen3;
                rate_out   <= rate_out;
                end
            else
                begin
                fsm        <= FSM_IDLE;
                gen3_exit  <= gen3_exit;
                cpllpd     <= cpllpd;
                qpllpd     <= qpllpd;
                cpllreset  <= cpllreset;
                qpllreset  <= qpllreset;
                txpmareset <= txpmareset;
                rxpmareset <= rxpmareset;
                sysclksel  <= sysclksel;
                pclk_sel   <= pclk_sel;
                gen3       <= gen3;
                rate_out   <= rate_out;
                end
            end

        //---------- Power-up PLL --------------------------
        FSM_PLL_PU :

            begin
            fsm        <= FSM_PLL_PURESET;
            gen3_exit  <= gen3_exit;
            cpllpd     <= (PCIE_PLL_SEL == "QPLL");
            qpllpd     <= 1'd0;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Release PLL Resets --------------------
        FSM_PLL_PURESET :

            begin
            fsm        <= FSM_PLL_LOCK;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= (PCIE_PLL_SEL == "QPLL");
            qpllreset  <= 1'd0;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for PLL Lock ---------------------
        FSM_PLL_LOCK :

            begin
            fsm        <= (pll_lock ? FSM_PMARESET_HOLD : FSM_PLL_LOCK);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Hold both PMA in Reset ----------------
        //  Gen1 : Release PMA Reset
        //  Gen2 : Release PMA Reset
        //  Gen3 : Hold PMA Reset
        //--------------------------------------------------
        FSM_PMARESET_HOLD :

            begin
            fsm        <= FSM_PLL_SEL;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= ((rate_in_reg2 == 2'd2) || gen3_exit);
            rxpmareset <= ((rate_in_reg2 == 2'd2) || gen3_exit);
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Select PLL ----------------------------
        //  Gen1 : QPLL if PCIE_PLL_SEL = QPLL, else CPLL
        //  Gen2 : QPLL if PCIE_PLL_SEL = QPLL, else CPLL
        //  Gen3 : QPLL
        //--------------------------------------------------
        FSM_PLL_SEL :

            begin
            fsm        <= FSM_MMCM_LOCK;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= ((rate_in_reg2 == 2'd2) || (PCIE_PLL_SEL == "QPLL")) ? 2'd1 : 2'd0;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Check for MMCM Lock -------------------
        FSM_MMCM_LOCK :

            begin
            fsm        <= (mmcm_lock_reg2 ? FSM_DRP_START : FSM_MMCM_LOCK);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Start DRP -----------------------------
        FSM_DRP_START:

            begin
            fsm        <= (!drp_done_reg2 ? FSM_DRP_DONE : FSM_DRP_START);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= ((rate_in_reg2 == 2'd1) || (rate_in_reg2 == 2'd2));
            gen3       <= (rate_in_reg2 == 2'd2);
            rate_out   <= (((rate_in_reg2 == 2'd2) || gen3_exit) ? rate : rate_out);
            end

        //---------- Wait for DRP Done ---------------------
        FSM_DRP_DONE :

            begin
            fsm        <= (drp_done_reg2 ? (rst_idle_reg2 ? FSM_PMARESET_RELEASE : FSM_IDLE): FSM_DRP_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Release PMA Resets --------------------
        FSM_PMARESET_RELEASE :

            begin
            fsm        <= FSM_PMARESET_DONE;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= 1'd0;
            rxpmareset <= 1'd0;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for both TX/RX PMA Reset Dones and PHYSTATUS Deassertion
        FSM_PMARESET_DONE :

            begin
            fsm        <= (((rxresetdone_reg2 && txresetdone_reg2 && !phystatus_reg2)) ? FSM_TXDATA_WAIT : FSM_PMARESET_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for TXDATA to TX[P/N] Latency ----
        FSM_TXDATA_WAIT :

            begin
            fsm        <= (txdata_wait_cnt == TXDATA_WAIT_MAX) ? FSM_PCLK_SEL : FSM_TXDATA_WAIT;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Select PCLK Frequency -----------------
        //  Gen1 : PCLK = 125 MHz
        //  Gen2 : PCLK = 250 MHz
        //  Gen3 : PCLK = 250 MHz
        //--------------------------------------------------
        FSM_PCLK_SEL :

            begin
            fsm        <= FSM_RATE_SEL;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= ((rate_in_reg2 == 2'd1) || (rate_in_reg2 == 2'd2));
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Select Rate ---------------------------
        FSM_RATE_SEL :

            begin
            fsm        <= FSM_RATE_DONE;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate;                             // Update [TX/RX]RATE
            end

        //---------- Wait for Rate Change Done -------------
        FSM_RATE_DONE :

            begin
            if (ratedone || (rate_in_reg2 == 2'd2) || (gen3_exit))
                if ((PCIE_USE_MODE == "1.0") && (rate_in_reg2 != 2'd2) && (!gen3_exit))
                    fsm <= FSM_RESETOVRD_START;
                else
                    fsm <= FSM_PLL_PDRESET;
            else
                fsm <= FSM_RATE_DONE;

            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Reset Override Start ------------------
        FSM_RESETOVRD_START:

            begin
            fsm        <= (!resetovrd_done_reg2 ? FSM_RESETOVRD_DONE : FSM_RESETOVRD_START);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Reset Override Done -------------------
        FSM_RESETOVRD_DONE :

            begin
            fsm        <= (resetovrd_done_reg2 ? FSM_PLL_PDRESET : FSM_RESETOVRD_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Hold PLL Not Used in Reset ------------
        FSM_PLL_PDRESET :

            begin
            fsm        <= FSM_PLL_PD;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= (PCIE_PLL_SEL == "QPLL") ? 1'd1 : (rate_in_reg2 == 2'd2);
            qpllreset  <= (PCIE_PLL_SEL == "QPLL") ? 1'd0 : (rate_in_reg2 != 2'd2);
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Power-Down PLL Not Used ---------------
        FSM_PLL_PD :

            begin
            fsm        <= (((rate_in_reg2 == 2'd2) || (PCIE_TXBUF_EN == "FALSE")) ? FSM_TXSYNC_START : FSM_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= (PCIE_PLL_SEL == "QPLL") ? 1'd1 : (rate_in_reg2 == 2'd2);
            qpllpd     <= (PCIE_PLL_SEL == "QPLL") ? 1'd0 : (rate_in_reg2 != 2'd2);
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Start TX Sync -------------------------
        FSM_TXSYNC_START:

            begin
            fsm        <= (!txsync_done_reg2 ? FSM_TXSYNC_DONE : FSM_TXSYNC_START);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for TX Sync Done -----------------
        FSM_TXSYNC_DONE:

            begin
            fsm        <= (txsync_done_reg2 ? FSM_DONE : FSM_TXSYNC_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Rate Change Done ----------------------
        FSM_DONE :

            begin
            fsm        <= (((rate_in_reg2 == 2'd2) && (PCIE_RXBUF_EN == "FALSE") && (PCIE_ASYNC_EN == "TRUE")) ? FSM_RXSYNC_START : FSM_IDLE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Start RX Sync -------------------------
        FSM_RXSYNC_START:

            begin
            fsm        <= (!rxsync_done_reg2 ? FSM_RXSYNC_DONE : FSM_RXSYNC_START);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for RX Sync Done -----------------
        FSM_RXSYNC_DONE:

            begin
            fsm        <= (rxsync_done_reg2 ? FSM_IDLE : FSM_RXSYNC_DONE);
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Default State -------------------------
        default :

            begin
            fsm        <= FSM_IDLE;
            gen3_exit  <= 1'd0;
            cpllpd     <= 1'd0;
            qpllpd     <= 1'd0;
            cpllreset  <= 1'd0;
            qpllreset  <= 1'd0;
            txpmareset <= 1'd0;
            rxpmareset <= 1'd0;
            sysclksel  <= (PCIE_PLL_SEL == "QPLL") ? 2'd1 : 2'd0;
            pclk_sel   <= 1'd0;
            gen3       <= 1'd0;
            rate_out   <= 3'd0;
            end

        endcase

        end

end



//---------- PIPE Rate Output --------------------------------------------------
assign RATE_CPLLPD          = ((PCIE_POWER_SAVING == "FALSE") ? 1'd0 : cpllpd);
assign RATE_QPLLPD          = ((PCIE_POWER_SAVING == "FALSE") ? 1'd0 : qpllpd);
assign RATE_CPLLRESET       = ((PCIE_POWER_SAVING == "FALSE") ? 1'd0 : cpllreset);
assign RATE_QPLLRESET       = ((PCIE_POWER_SAVING == "FALSE") ? 1'd0 : qpllreset);
assign RATE_TXPMARESET      = txpmareset;
assign RATE_RXPMARESET      = rxpmareset;
assign RATE_SYSCLKSEL       = sysclksel;
assign RATE_DRP_START       = (fsm == FSM_DRP_START);
assign RATE_PCLK_SEL        = pclk_sel;
assign RATE_GEN3            = gen3;
assign RATE_RATE_OUT        = rate_out;
assign RATE_RESETOVRD_START = (fsm == FSM_RESETOVRD_START);
assign RATE_TXSYNC_START    = (fsm == FSM_TXSYNC_START);
assign RATE_DONE            = (fsm == FSM_DONE);
assign RATE_RXSYNC_START    = (fsm == FSM_RXSYNC_START);
assign RATE_RXSYNC          = ((fsm == FSM_RXSYNC_START) || (fsm == FSM_RXSYNC_DONE));
assign RATE_IDLE            = (fsm == FSM_IDLE);
assign RATE_FSM             = fsm;



endmodule
