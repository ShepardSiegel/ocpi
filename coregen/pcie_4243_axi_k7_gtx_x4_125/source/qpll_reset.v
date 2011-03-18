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
// File       : qpll_reset.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  QPLL Reset Module for Virtex-7 GTX PCIe
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- QPLL Reset Module --------------------------------------------------
module qpll_reset #
(

    parameter PCIE_LANE = 1                                 // PCIe number of lanes

)

(

    //---------- Input -------------------------------------
    input                           QRST_CLK,
    input                           QRST_RST_N,
    input                           QRST_MMCM_LOCK,
    input       [(PCIE_LANE-1)>>2:0]QRST_DRP_DONE,
    input       [(PCIE_LANE-1)>>2:0]QRST_QPLLLOCK,
    input       [ 1:0]              QRST_RATE,
    input       [PCIE_LANE-1:0]     QRST_QPLLRESET_IN,
    input       [PCIE_LANE-1:0]     QRST_QPLLPD_IN,
    
    //---------- Output ------------------------------------
    output                          QRST_OVRD,
    output                          QRST_DRP_START,
    output                          QRST_QPLLRESET_OUT,
    output                          QRST_QPLLPD_OUT,
    output      [ 3:0]              QRST_FSM

);

    //---------- Input FF ----------------------------------
    reg                             mmcm_lock_reg1;
    reg         [(PCIE_LANE-1)>>2:0]drp_done_reg1;
    reg         [(PCIE_LANE-1)>>2:0]qplllock_reg1;
    reg         [ 1:0]              rate_reg1;
    reg         [PCIE_LANE-1:0]     qpllreset_in_reg1;
    reg         [PCIE_LANE-1:0]     qpllpd_in_reg1;

    reg                             mmcm_lock_reg2;
    reg         [(PCIE_LANE-1)>>2:0]drp_done_reg2;
    reg         [(PCIE_LANE-1)>>2:0]qplllock_reg2;
    reg         [ 1:0]              rate_reg2;
    reg         [PCIE_LANE-1:0]     qpllreset_in_reg2;
    reg         [PCIE_LANE-1:0]     qpllpd_in_reg2;
    
    //---------- Output FF ---------------------------------
    reg                             ovrd      = 1'd0;
    reg                             qpllreset = 1'd0;
    reg                             qpllpd    = 1'd0;
    reg         [ 3:0]              fsm       = 4'd0;                 
   
    //---------- FSM ---------------------------------------                                         
    localparam                      FSM_IDLE       = 4'd0; 
    localparam                      FSM_MMCM_LOCK  = 4'd1;   
    localparam                      FSM_DRP_START1 = 4'd2;
    localparam                      FSM_DRP_DONE1  = 4'd3;
    localparam                      FSM_QPLLRESET  = 4'd4;  
    localparam                      FSM_QPLLLOCK   = 4'd5;
    localparam                      FSM_DRP_START2 = 4'd6;                            
    localparam                      FSM_DRP_DONE2  = 4'd7;
    localparam                      FSM_PD_STAGE1  = 4'd8;
    localparam                      FSM_PD_STAGE2  = 4'd9;                                                         
                                               
 
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge QRST_CLK)
begin

    if (!QRST_RST_N)
        begin    
        //---------- 1st Stage FF --------------------------
        mmcm_lock_reg1    <= 1'd0;
        drp_done_reg1     <= {(((PCIE_LANE-1)>>2)+1){1'd1}};     
        qplllock_reg1     <= {(((PCIE_LANE-1)>>2)+1){1'd0}}; 
        rate_reg1         <= 2'd0; 
        qpllreset_in_reg1 <= {PCIE_LANE{1'd1}}; 
        qpllpd_in_reg1    <= {PCIE_LANE{1'd1}}; 
        //---------- 2nd Stage FF --------------------------
        mmcm_lock_reg2    <= 1'd0;
        drp_done_reg2     <= {(((PCIE_LANE-1)>>2)+1){1'd1}}; 
        qplllock_reg2     <= {(((PCIE_LANE-1)>>2)+1){1'd0}}; 
        rate_reg2         <= 2'd0;
        qpllreset_in_reg2 <= {PCIE_LANE{1'd1}}; 
        qpllpd_in_reg2    <= {PCIE_LANE{1'd1}};  
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        mmcm_lock_reg1    <= QRST_MMCM_LOCK;    
        drp_done_reg1     <= QRST_DRP_DONE; 
        qplllock_reg1     <= QRST_QPLLLOCK;
        rate_reg1         <= QRST_RATE; 
        qpllreset_in_reg1 <= QRST_QPLLRESET_IN;
        qpllpd_in_reg1    <= QRST_QPLLPD_IN;
        //---------- 2nd Stage FF --------------------------
        mmcm_lock_reg2    <= mmcm_lock_reg1;
        drp_done_reg2     <= drp_done_reg1; 
        qplllock_reg2     <= qplllock_reg1;
        rate_reg2         <= rate_reg1;
        qpllreset_in_reg2 <= qpllreset_in_reg1;
        qpllpd_in_reg2    <= qpllpd_in_reg1;
        end
        
end    



//---------- QPLL Reset FSM ----------------------------------------------------
always @ (posedge QRST_CLK)
begin

    if (!QRST_RST_N)
        begin
        fsm       <= FSM_MMCM_LOCK;
        ovrd      <= 1'd0;
        qpllreset <= 1'd1;
        qpllpd    <= 1'd0;
        end
    else
        begin
        
        case (fsm)
            
        //---------- Idle State ----------------------------
        FSM_IDLE :
        
            begin
            if (!QRST_RST_N)
                begin
                fsm       <= FSM_MMCM_LOCK;
                ovrd      <= 1'd0;
                qpllreset <= 1'd1;
                qpllpd    <= 1'd0;
                end
            else
                begin
                fsm       <= FSM_IDLE;
                ovrd      <= ovrd;
                qpllreset <= &qpllreset_in_reg2;
                qpllpd    <= &qpllpd_in_reg2;
                end
            end  
            
        //---------- Wait for MMCM Lock --------------------
        FSM_MMCM_LOCK :
        
            begin
            if (mmcm_lock_reg2)
                begin
                fsm       <= FSM_DRP_START1;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_MMCM_LOCK;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            end      
            
        //---------- Start DRP for Normal QPLLLOCK Mode ----
        FSM_DRP_START1:
        
            begin
            if (&(~drp_done_reg2))
                begin
                fsm       <= FSM_DRP_DONE1;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_DRP_START1;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            end

        //---------- Wait for DRP Done ---------------------
        FSM_DRP_DONE1 :
        
            begin
            if (&drp_done_reg2)
                begin
                fsm       <= FSM_QPLLRESET;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_DRP_DONE1;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            end 

        //---------- Assert QPLLRESET ----------------------
        FSM_QPLLRESET :
        
            begin
            if (&(~qplllock_reg2))
                begin
                fsm       <= FSM_QPLLLOCK;
                ovrd      <= 1'd1;
                qpllreset <= 1'd1;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_QPLLRESET;
                ovrd      <= 1'd1;
                qpllreset <= 1'd1;
                qpllpd    <= qpllpd;
                end
            end
            
        //---------- Wait for QPLLLOCK ---------------------
        FSM_QPLLLOCK :
        
            begin
            if (&qplllock_reg2)
                begin
                fsm       <= FSM_DRP_START2;
                ovrd      <= ovrd;
                qpllreset <= 1'd0;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_QPLLLOCK;
                ovrd      <= ovrd;
                qpllreset <= 1'd0;
                qpllpd    <= qpllpd;
                end
            end
            
        //---------- Start DRP for Optimized QPLLLOCK Mode -
        FSM_DRP_START2:
        
            begin
            if (&(~drp_done_reg2))
                begin
                fsm       <= FSM_DRP_DONE2;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_DRP_START2;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            end

        //---------- Wait for DRP Done -------------------
        FSM_DRP_DONE2 :
        
            begin
            if (&drp_done_reg2)
                begin
                fsm       <= FSM_PD_STAGE1;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            else
                begin
                fsm       <= FSM_DRP_DONE2;
                ovrd      <= ovrd;
                qpllreset <= qpllreset;
                qpllpd    <= qpllpd;
                end
            end 
            
        //---------- Assert QPLLRESET ----------------------
        FSM_PD_STAGE1 :
        
            begin
            fsm       <= FSM_PD_STAGE2;
            ovrd      <= ovrd;
            qpllreset <= (rate_reg2 != 2'd2); 
            qpllpd    <= qpllpd;
            
            end
            
        //---------- Assert QPLLPD -------------------------
        FSM_PD_STAGE2 :
        
            begin
            fsm       <= FSM_IDLE;
            ovrd      <= ovrd;
            qpllreset <= qpllreset;
            qpllpd    <= (rate_reg2 != 2'd2);
            end 
                
        //---------- Default State -------------------------
        default :
        
            begin
            fsm       <= FSM_IDLE;
            ovrd      <= ovrd;
            qpllreset <= qpllreset;
            qpllpd    <= qpllpd;
            end

        endcase
        
        end
        
end



//---------- QPLL Lock Output --------------------------------------------------
assign QRST_OVRD          = ovrd;
assign QRST_DRP_START     = (fsm == FSM_DRP_START1) || (fsm == FSM_DRP_START2); 
assign QRST_QPLLRESET_OUT = qpllreset;
assign QRST_QPLLPD_OUT    = qpllpd;  
assign QRST_FSM           = fsm;                   



endmodule
