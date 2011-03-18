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
// File       : pipe_rate.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Filename     :  pipe_rate.v
//  Description  :  PIPE Rate Module for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Rate Module --------------------------------------------------
module pipe_rate #
(

    parameter PCIE_SI_REV          = "1.0",                 // PCIe silicon revision
    parameter PCIE_TXBUF_EN        = "FALSE",               // PCIe TX buffer enable
    parameter WAIT_MAX             = 4'd15                  // Wait max


)

(

    //---------- Input -------------------------------------
    input               RATE_CLK,
    input               RATE_RST_N,
    input       [ 3:0]  RATE_RST_FSM,
    input               RATE_ACTIVE_LANE,
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
    output      [ 4:0]  RATE_FSM

);

    //---------- Input FF or Buffer ------------------------
    reg                 active_lane_reg1;
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
    
    reg                 active_lane_reg2;
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
    wire                gtxpll_lock;
    wire        [ 2:0]  rate;
    reg         [ 3:0]  wait_cnt   = 4'd0;
    reg                 txratedone = 1'd0;
    reg                 rxratedone = 1'd0;
    reg                 phystatus  = 1'd0;
    reg                 ratedone   = 1'd0;
    reg                 gen3_exit  = 1'd0;
    
    //---------- Output FF or Buffer -----------------------
    reg                 cpllpd     = 1'd0;
    reg                 qpllpd     = 1'd1;
    reg                 cpllreset  = 1'd0;
    reg                 qpllreset  = 1'd1;
    reg                 txpmareset = 1'd0;
    reg                 rxpmareset = 1'd0;
    reg         [ 1:0]  sysclksel  = 2'd0; 
    reg                 gen3       = 1'd0;
    reg                 pclk_sel   = 1'd0; 
    reg         [ 2:0]  rate_out   = 3'd0; 
    reg         [ 4:0]  fsm        = 5'd0;                 
   
    //---------- FSM ---------------------------------------                                         
    localparam          FSM_IDLE            = 5'd0; 
    localparam          FSM_GTXPLL_PU       = 5'd1;         // Gen 3 only
    localparam          FSM_GTXPLL_PURESET  = 5'd2;         // Gen 3 only
    localparam          FSM_GTXPLL_LOCK     = 5'd3;         // Gen 3 or reset only
    localparam          FSM_GTXRESET_ON     = 5'd4;         // Gen 3 or reset only
    localparam          FSM_SYSCLKSEL       = 5'd5;         // Gen 3 or reset only   
    localparam          FSM_MMCM_LOCK       = 5'd6;         // Gen 3 or reset only             
    localparam          FSM_DRP_START       = 5'd7;         // Gen 3 or reset only                                 
    localparam          FSM_DRP_DONE        = 5'd8;         // Gen 3 or reset only
    localparam          FSM_GTXRESET_OFF    = 5'd9;         // Gen 3 only
    localparam          FSM_RESETDONE       = 5'd10;        // Gen 3 only
    localparam          FSM_WAIT            = 5'd11;           
    localparam          FSM_PCLK_SEL        = 5'd12;   
    localparam          FSM_RATE            = 5'd13;
    localparam          FSM_RATEDONE        = 5'd14;
    localparam          FSM_RESETOVRD_START = 5'd15;        // Gen 1 and 2 only
    localparam          FSM_RESETOVRD_DONE  = 5'd16;        // Gen 1 and 2 only
    localparam          FSM_GTXPLL_PDRESET  = 5'd17;
    localparam          FSM_GTXPLL_PD       = 5'd18;                                
    localparam          FSM_TXSYNC_START    = 5'd19;
    localparam          FSM_TXSYNC_DONE     = 5'd20;                   
    localparam          FSM_DONE            = 5'd21;        // Must sync value to pipe_user.v
    localparam          FSM_RXSYNC_START    = 5'd22;        // Gen 3 only
    localparam          FSM_RXSYNC_DONE     = 5'd23;        // Gen 3 only                                    
    
    
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin    
        //---------- 1st Stage FF --------------------------    
        active_lane_reg1    <= 1'd1;
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
        active_lane_reg2    <= 1'd1;
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
        active_lane_reg1    <= RATE_ACTIVE_LANE;
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
        active_lane_reg2    <= active_lane_reg1;
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



//---------- Select QPLLLOCK or CPLLLOCK ---------------------------------
assign gtxpll_lock = (rate_in_reg2 == 2'd2) ? qplllock_reg2 : cplllock_reg2;



//---------- Select Rate -------------------------------------------------------
//  rate = 3'd0 : Divide by  1 (Gen 3 : CPLL_[TX/RX]OUT_DIV = 1) 
//              : Divide by  2 (Gen 1 : CPLL_[TX/RX]OUT_DIV = 2) 
//  rate = 3'd1 : Divide by  1 (Gen 2)
//  rate = 3'd2 : Divide by  2 
//  rate = 3'd3 : Divide by  4 
//  rate = 3'd4 : Divide by  8  
//  rate = 3'd5 : Divide by 16 
//  rate = 3'd6 : Divide by  1
//  rate = 3'd7 : Divide by  1 
//------------------------------------------------------------------------------  
assign rate = (rate_in_reg2 == 2'd1) ? 3'd1 : 3'd0;



//---------- Wait Counter ---------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        wait_cnt <= 4'd0;
    else
    
        //---------- Increment Wait Counter ----------------
        if ((fsm == FSM_WAIT) && (wait_cnt < WAIT_MAX))
            wait_cnt <= wait_cnt + 4'd1;
            
        //---------- Hold Wait Counter ---------------------
        else if ((fsm == FSM_WAIT) && (wait_cnt == WAIT_MAX))
            wait_cnt <= wait_cnt;
            
        //---------- Reset Wait Counter --------------------
        else
            wait_cnt <= 4'd0;
        
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

        if (fsm == FSM_RATEDONE)
        
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
        fsm        <= FSM_GTXPLL_LOCK;
        gen3_exit  <= 1'd0;
        cpllpd     <= 1'd0;
        qpllpd     <= 1'd1;
        cpllreset  <= 1'd0;
        qpllreset  <= 1'd1;
        txpmareset <= 1'd0;
        rxpmareset <= 1'd0;
        sysclksel  <= 2'd0;                               
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
            //---------- Detect rate change ----------------
            if (rate_in_reg2 != rate_in_reg1)
                begin
                //---------- Enter or exit Gen 3 speed -----
                if ((rate_in_reg2 == 2'd2) || (rate_in_reg1 == 2'd2)) 
                    begin
                    fsm        <= FSM_GTXPLL_PU;
                    gen3_exit  <= (rate_in_reg2 == 2'd2);  // Exit Gen 3 speed
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
                //-------- Rate change between Gen 1 and 2 speeds 
                else
                    begin
                    fsm        <= FSM_WAIT;
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
            
        //---------- Power Up GTX PLL ----------------------
        FSM_GTXPLL_PU :
        
            begin
            fsm        <= FSM_GTXPLL_PURESET;
            gen3_exit  <= gen3_exit;
            cpllpd     <= 1'd0;
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
            
        //---------- Release GTX PLL Reset -----------------
        FSM_GTXPLL_PURESET :
        
            begin
            fsm        <= FSM_GTXPLL_LOCK;
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= 1'd0;
            qpllreset  <= 1'd0;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end 

        //---------- Wait for GTX PLL LOCK -----------------
        FSM_GTXPLL_LOCK :
        
            begin
            if (gtxpll_lock || (!active_lane_reg2))
                begin
                fsm        <= FSM_GTXRESET_ON;  
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
            else
                begin
                fsm        <= FSM_GTXPLL_LOCK;
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

        //---------- Assert [TX/RX]PMARESET  ---------------
        FSM_GTXRESET_ON :
        
            begin
            fsm        <= FSM_SYSCLKSEL;
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
        //  sysclksel = 0 : CPLL for Gen 1 and 2
        //  sysclksel = 1 : QPLL for Gen 3
        //--------------------------------------------------
        FSM_SYSCLKSEL :
        
            begin
            fsm        <= FSM_MMCM_LOCK;    
            gen3_exit  <= gen3_exit;
            cpllpd     <= cpllpd;
            qpllpd     <= qpllpd;
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= (rate_in_reg2 == 2'd2);                          
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end

        //---------- Wait for MMCM LOCK --------------------
        FSM_MMCM_LOCK :
        
            begin
            if (mmcm_lock_reg2)
                begin
                fsm        <= FSM_DRP_START;  
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
            else
                begin
                fsm        <= FSM_MMCM_LOCK;
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

        //---------- Start DRP -----------------------------
        FSM_DRP_START:
        
            begin
            //---------- Hold DRP Start until DRP Done Deasserts
            if (!drp_done_reg2 || (!active_lane_reg2))
                begin
                fsm        <= FSM_DRP_DONE;
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
                
                //---------- Enter or exit Gen 3 speed -----
                if ((rate_in_reg2 == 2'd2) || gen3_exit)
                    rate_out <= rate;                       // Update GTX rate
                else
                    rate_out <= rate_out;
                end
                
            else
                begin
                fsm        <= FSM_DRP_START;
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

        //---------- Wait for DRP Done ---------------------
        FSM_DRP_DONE :
        
            begin
            if (drp_done_reg2)
                begin
                //---------- DRP for Reset  ----------------
                if (RATE_RST_FSM != 4'd0)
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
                else
                    begin
                    fsm        <= FSM_GTXRESET_OFF;
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
            else
                begin
                fsm        <= FSM_DRP_DONE;
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

        //---------- Deassert [TX/RX]PMARESET --------------
        FSM_GTXRESET_OFF :
        
            begin
            fsm        <= FSM_RESETDONE;
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

        //---------- Wait for [TX/RX]RESETDONE and PHYSTATUS
        FSM_RESETDONE :
        
            begin
            if (((rxresetdone_reg2 && txresetdone_reg2) && (!phystatus_reg2)) || (!active_lane_reg2))
                begin
                fsm        <= FSM_WAIT; 
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
            else
                begin
                fsm        <= FSM_RESETDONE;
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

        //---------- Wait for TXDATA to GTXTX Latency ------
        FSM_WAIT :
        
            begin
            if (wait_cnt == WAIT_MAX) 
                begin
                fsm        <= FSM_PCLK_SEL;
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
            else
                begin
                fsm        <= FSM_WAIT;
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

        //---------- Select PCLK ---------------------------
        //  pclk_sel = 0 : 125 MHz for Gen 1
        //  pclk_sel = 1 : 250 MHz for Gen 2 and 3
        //--------------------------------------------------
        FSM_PCLK_SEL :
        
            begin
            fsm        <= FSM_RATE;    
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

        //---------- Change Rate ---------------------------
        FSM_RATE :
        
            begin
            fsm        <= FSM_RATEDONE;
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
            rate_out   <= rate;                             // Update GTX rate  
            end    
            
        //---------- Wait for Rate Done --------------------
        FSM_RATEDONE :
        
            begin
            if (ratedone || (rate_in_reg2 == 2'd2) || gen3_exit || (!active_lane_reg2)) 
                begin
                fsm        <= FSM_RESETOVRD_START;
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
            else
                begin
                fsm        <= FSM_RATEDONE;
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
            
        //---------- Reset Override Start ------------------
        FSM_RESETOVRD_START:
        
            begin
            if (!resetovrd_done_reg2 || (rate_in_reg2 == 2'd2) || gen3_exit || (PCIE_SI_REV != "1.0"))
                begin
                fsm        <= FSM_RESETOVRD_DONE;
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
            else
                begin
                fsm        <= FSM_RESETOVRD_START;
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
            
        //---------- Reset Override Done -------------------
        FSM_RESETOVRD_DONE :
        
            begin
            if (resetovrd_done_reg2 || (rate_in_reg2 == 2'd2) || gen3_exit || (PCIE_SI_REV != "1.0")) 
                begin
                fsm        <= FSM_GTXPLL_PDRESET;
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
            else
                begin
                fsm        <= FSM_RESETOVRD_DONE;
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
                
        //---------- Assert GTX PLL Reset -------------------
        FSM_GTXPLL_PDRESET :
        
            begin
            fsm       <= FSM_GTXPLL_PD;
            gen3_exit <= gen3_exit;
            cpllpd    <= cpllpd;
            qpllpd    <= qpllpd;
            
            //---------- Enter Gen 3 Speed ----------------- 
            if (rate_in_reg2 == 2'd2)  
                begin
                cpllreset <= 1'd1;
                qpllreset <= 1'd0;
                end
            else   
                begin 
                cpllreset <= 1'd0;
                qpllreset <= 1'd1;    
                end
                
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end    
            
        //---------- Power Down GTX PLL --------------------
        FSM_GTXPLL_PD :
        
            begin
            
            //---------- Bypass TX sync when TX buffer is enabled
            if ((PCIE_TXBUF_EN == "TRUE") && (rate_in_reg2 != 2'd2))
                fsm <= FSM_DONE;
            else
                fsm <= FSM_TXSYNC_START;
            
            gen3_exit <= gen3_exit;
            
            //---------- Enter Gen 3 Speed ----------------- 
            if (rate_in_reg2 == 2'd2)
                begin
                cpllpd <= 1'd1;
                qpllpd <= 1'd0;
                end
            else
                begin
                cpllpd <= 1'd0;
                qpllpd <= 1'd1;  
                end
                
            cpllreset  <= cpllreset;
            qpllreset  <= qpllreset;
            txpmareset <= txpmareset;
            rxpmareset <= rxpmareset;
            sysclksel  <= sysclksel;
            pclk_sel   <= pclk_sel;
            gen3       <= gen3;
            rate_out   <= rate_out;
            end         
            
        //---------- TX Sync Start -------------------------
        FSM_TXSYNC_START:
        
            begin
            if (!txsync_done_reg2)
                begin
                fsm        <= FSM_TXSYNC_DONE;
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
            else
                begin
                fsm        <= FSM_TXSYNC_START;
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
            
        //---------- Wait for TX Phase Sync Done -----------
        FSM_TXSYNC_DONE:
        
            begin
            if (txsync_done_reg2) 
                begin
                fsm        <= FSM_DONE;
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
            else
                begin
                fsm        <= FSM_TXSYNC_DONE;
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

        //---------- Done State ----------------------------
        FSM_DONE :  
          
            begin
            if (rate_in_reg2 == 2'd2)
                begin
                fsm        <= FSM_RXSYNC_START;
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
               
        //---------- Start RX Sync -------------------------
        FSM_RXSYNC_START:
        
            begin
            if (!rxsync_done_reg2)
                begin
                fsm        <= FSM_RXSYNC_DONE;
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
            else
                begin
                fsm        <= FSM_RXSYNC_START;
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
            
        //---------- Wait for RX Phase Sync Done -----------
        FSM_RXSYNC_DONE:
        
            begin
            if (rxsync_done_reg2) 
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
            else
                begin
                fsm        <= FSM_RXSYNC_DONE;
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
                
        //---------- Default State -------------------------
        default :
        
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

        endcase
        
        end
        
end 



//---------- PIPE Rate Output --------------------------------------------------
assign RATE_CPLLPD          = cpllpd;
assign RATE_QPLLPD          = qpllpd;
assign RATE_CPLLRESET       = cpllreset;
assign RATE_QPLLRESET       = qpllreset;
assign RATE_TXPMARESET      = txpmareset;
assign RATE_RXPMARESET      = rxpmareset;
assign RATE_SYSCLKSEL       = sysclksel;
assign RATE_DRP_START       = (fsm == FSM_DRP_START); 
assign RATE_PCLK_SEL        = pclk_sel;
assign RATE_GEN3            = gen3;
assign RATE_RATE_OUT        = rate_out;
assign RATE_RESETOVRD_START = (PCIE_SI_REV == "1.0") && (fsm == FSM_RESETOVRD_START);
assign RATE_TXSYNC_START    = (fsm == FSM_TXSYNC_START);
assign RATE_DONE            = (fsm == FSM_DONE);
assign RATE_RXSYNC_START    = (fsm == FSM_RXSYNC_START);
assign RATE_FSM             = fsm;   



endmodule
