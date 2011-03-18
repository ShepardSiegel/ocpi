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
// File       : pipe_reset.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  PIPE Reset Module for Virtex-7 GTX PCIe
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Reset Module -------------------------------------------------
module pipe_reset #
(

    parameter PCIE_TXBUF_EN        = "FALSE",               // PCIe TX buffer enable
    parameter PCIE_LANE            = 1,                     // PCIe number of lanes
    parameter WAIT_MAX             = 4'd15,                 // Wait max
    parameter BYPASS_RXCDRLOCK     = 1                      // Bypass RXCDRLOCK

)

(

    //---------- Input -------------------------------------
    input                           RST_CLK,
    input                           RST_RST_N,
    input       [PCIE_LANE-1:0]     RST_CPLLLOCK,
    input       [(PCIE_LANE*5)-1:0] RST_RATE_FSM,
    input       [PCIE_LANE-1:0]     RST_RXCDRLOCK,
    input                           RST_MMCM_LOCK,
    input       [PCIE_LANE-1:0]     RST_RESETDONE,
    input       [PCIE_LANE-1:0]     RST_PHYSTATUS,
    input       [PCIE_LANE-1:0]     RST_TXSYNC_DONE,
    
    //---------- Output ------------------------------------
    output                          RST_CPLLRESET,
    output                          RST_GTXRESET,
    output                          RST_USERRDY,
    output                          RST_TXSYNC_START,
    output      [ 3:0]              RST_FSM

);

    //---------- Input FF or Buffer ------------------------
    reg         [PCIE_LANE-1:0]     cplllock_reg1;
    reg         [PCIE_LANE-1:0]     rxcdrlock_reg1;
    reg                             mmcm_lock_reg1;
    reg         [PCIE_LANE-1:0]     resetdone_reg1;
    reg         [PCIE_LANE-1:0]     phystatus_reg1;
    reg         [PCIE_LANE-1:0]     txsync_done_reg1;  
    
    reg         [PCIE_LANE-1:0]     cplllock_reg2;
    reg         [PCIE_LANE-1:0]     rxcdrlock_reg2;
    reg                             mmcm_lock_reg2;
    reg         [PCIE_LANE-1:0]     resetdone_reg2;
    reg         [PCIE_LANE-1:0]     phystatus_reg2;
    reg         [PCIE_LANE-1:0]     txsync_done_reg2;
    
    //---------- Internal Signal ---------------------------
    reg         [ 3:0]              wait_cnt = 4'd0;
    
    //---------- Output FF or Buffer -----------------------
    reg                             cpllreset = 1'd0;
    reg                             gtxreset  = 1'd0;
    reg                             userrdy   = 1'd0;
    reg         [ 3:0]              fsm       = 4'd1;                 
   
    //---------- FSM ---------------------------------------                                         
    localparam                      FSM_IDLE         = 4'd0; 
    localparam                      FSM_WAIT         = 4'd1;
    localparam                      FSM_CPLLRESET    = 4'd2;     
    localparam                      FSM_CPLLLOCK     = 4'd3;
    localparam                      FSM_DRP          = 4'd4;                            
    localparam                      FSM_GTXRESET     = 4'd5;                      
    localparam                      FSM_MMCM_LOCK    = 4'd6;  
    localparam                      FSM_RESETDONE    = 4'd7;    
    localparam                      FSM_TXSYNC_START = 4'd8;
    localparam                      FSM_TXSYNC_DONE  = 4'd9;                                

 
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
        begin    
        //---------- 1st Stage FF --------------------------    
        cplllock_reg1    <= {PCIE_LANE{1'd0}}; 
        rxcdrlock_reg1   <= {PCIE_LANE{1'd0}}; 
        mmcm_lock_reg1   <= 1'd0; 
        resetdone_reg1   <= {PCIE_LANE{1'd0}}; 
        phystatus_reg1   <= {PCIE_LANE{1'd1}}; 
        txsync_done_reg1 <= {PCIE_LANE{1'd0}}; 
        //---------- 2nd Stage FF --------------------------
        cplllock_reg2    <= {PCIE_LANE{1'd0}}; 
        rxcdrlock_reg2   <= {PCIE_LANE{1'd0}}; 
        mmcm_lock_reg2   <= 1'd0;
        resetdone_reg2   <= {PCIE_LANE{1'd0}}; 
        phystatus_reg2   <= {PCIE_LANE{1'd1}}; 
        txsync_done_reg2 <= {PCIE_LANE{1'd0}}; 
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------    
        cplllock_reg1    <= RST_CPLLLOCK;
        rxcdrlock_reg1   <= RST_RXCDRLOCK;
        mmcm_lock_reg1   <= RST_MMCM_LOCK;
        resetdone_reg1   <= RST_RESETDONE;
        phystatus_reg1   <= RST_PHYSTATUS;
        txsync_done_reg1 <= RST_TXSYNC_DONE;
        //---------- 2nd Stage FF --------------------------
        cplllock_reg2    <= cplllock_reg1;
        rxcdrlock_reg2   <= rxcdrlock_reg1;
        mmcm_lock_reg2   <= mmcm_lock_reg1;
        resetdone_reg2   <= resetdone_reg1;
        phystatus_reg2   <= phystatus_reg1;
        txsync_done_reg2 <= txsync_done_reg1;   
        end
        
end    



//---------- Wait Counter ---------------------------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
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



//---------- PIPE Reset FSM ----------------------------------------------------
always @ (posedge RST_CLK)
begin

    if (!RST_RST_N)
        begin
        fsm       <= FSM_WAIT;
        cpllreset <= 1'd0;
        gtxreset  <= 1'd0;
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
                fsm       <= FSM_WAIT;
                cpllreset <= 1'd0;
                gtxreset  <= 1'd0;
                userrdy   <= 1'd0;
                end
            else
                begin
                fsm       <= FSM_IDLE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end  
            
        //----------  Wait at least 100ns ------------------
          FSM_WAIT :
          
            begin
            if (wait_cnt == WAIT_MAX) 
                begin
                fsm       <= FSM_CPLLRESET;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_WAIT;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end 
            
        //---------- Assert CPLLRESET and GTX[TX/RX]RESET --
        FSM_CPLLRESET :
        
            begin
            if (&(~cplllock_reg2))
                begin
                fsm       <= FSM_CPLLLOCK;
                cpllreset <= 1'd1;
                gtxreset  <= 1'd1;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_CPLLRESET;
                cpllreset <= 1'd1;
                gtxreset  <= 1'd1;
                userrdy   <= userrdy;
                end
            end  

        //---------- Wait for CPLLLOCK ---------------------
        FSM_CPLLLOCK :
        
            begin
            if (&cplllock_reg2)
                begin
                fsm       <= FSM_DRP;
                cpllreset <= 1'd0;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_CPLLLOCK;
                cpllreset <= 1'd0;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end

        //---------- Wait for DRP Done ---------------------
        FSM_DRP :
        
            begin
            if (&(~RST_RATE_FSM))
                begin
                fsm       <= FSM_GTXRESET;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_DRP;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end

        //---------- Deassert GTXRESET ---------------------
        FSM_GTXRESET :
        
            begin
            if (&(~resetdone_reg2))
                begin
                fsm       <= FSM_MMCM_LOCK;
                cpllreset <= cpllreset;
                gtxreset  <= 1'b0;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_GTXRESET;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end 
            end

        //---------- Wait for MMCM Lock and RXCDRLOCK ------
        FSM_MMCM_LOCK :
        
            begin
            if (mmcm_lock_reg2 && ((&rxcdrlock_reg2) || (BYPASS_RXCDRLOCK)))
                begin
                fsm       <= FSM_RESETDONE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= 1'b1;
                end
            else
                begin
                fsm       <= FSM_MMCM_LOCK;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end

        //---------- Wait for RESETDONE and PHYSTATUS ------
        FSM_RESETDONE :
        
            begin
            if ((&resetdone_reg2) && (&(~phystatus_reg2)))
                begin
                //---------- Bypass TX sync alignment when TX buffer is used
                if (PCIE_TXBUF_EN == "TRUE")
                    begin
                    fsm       <= FSM_IDLE;
                    cpllreset <= cpllreset;
                    gtxreset  <= gtxreset;
                    userrdy   <= userrdy;
                    end
                else
                    begin
                    fsm       <= FSM_TXSYNC_START;
                    cpllreset <= cpllreset;
                    gtxreset  <= gtxreset;
                    userrdy   <= userrdy;
                    end
                end
            else
                begin
                fsm       <= FSM_RESETDONE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end
            
        //---------- Start TX Sync -------------------------
        FSM_TXSYNC_START:
        
            begin
            if (&(~txsync_done_reg2))
                begin
                fsm       <= FSM_TXSYNC_DONE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_TXSYNC_START;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end
            
        //---------- Wait for TX Sync Done -----------------
        FSM_TXSYNC_DONE:
        
            begin
            if (&txsync_done_reg2) 
                begin
                fsm       <= FSM_IDLE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            else
                begin
                fsm       <= FSM_TXSYNC_DONE;
                cpllreset <= cpllreset;
                gtxreset  <= gtxreset;
                userrdy   <= userrdy;
                end
            end     
            
        //---------- Default State -------------------------
        default :
        
            begin
            fsm       <= FSM_IDLE;
            cpllreset <= cpllreset;
            gtxreset  <= gtxreset;
            userrdy   <= userrdy;
            end

        endcase
        
        end
        
end



//---------- PIPE Reset Output -------------------------------------------------
assign RST_CPLLRESET    = cpllreset; 
assign RST_GTXRESET     = gtxreset;  
assign RST_USERRDY      = userrdy;
assign RST_TXSYNC_START = (fsm == FSM_TXSYNC_START);
assign RST_FSM          = fsm;                   



endmodule
