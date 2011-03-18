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
// File       : pipe_sync.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Filename     :  pipe_sync.v
//  Description  :  PIPE Sync Module for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Sync Module --------------------------------------------------
module pipe_sync #
(

    parameter PCIE_AUTO_TXSYNC     = 1,                     // PCIe Auto TX sync
    parameter PCIE_AUTO_RXSYNC     = 1,                     // PCIe Auto RX sync
    parameter BYPASS_TXPHASE_ALIGN = 0,                     // Bypass TX phase align 
    parameter BYPASS_RXPHASE_ALIGN = 0,                     // Bypass RX phase align 
    parameter BYPASS_TXDELAY_ALIGN = 0,                     // Bypass TX delay align
    parameter BYPASS_RXDELAY_ALIGN = 0                      // Bypass RX delay align

)

(

    //---------- Input -------------------------------------
    input               SYNC_CLK,
    input               SYNC_RST_N,
    input               SYNC_SLAVE,
    input				SYNC_MMCM_LOCK,
    input               SYNC_RXELECIDLE,
    input               SYNC_RXCDRLOCK,
    
    input				SYNC_TXSYNC_START,
    input               SYNC_TXPHINITDONE,   
    input               SYNC_TXDLYSRESETDONE,
    input               SYNC_TXPHALIGNDONE,
        
    input				SYNC_RXSYNC_START,
    input               SYNC_RXDLYSRESETDONE,
    input               SYNC_RXPHALIGNDONE,
    
    //---------- Output ------------------------------------
    output              SYNC_TXPHALIGN,     
    output              SYNC_TXPHALIGNEN,  
    output              SYNC_TXPHINIT,      
    output              SYNC_TXDLYEN,      
    output              SYNC_TXDLYSRESET,
    output              SYNC_TXSYNC_DONE,
    output      [ 2:0]  SYNC_FSM_TX,
    
    output              SYNC_RXDLYSRESET,
    output              SYNC_RXSYNC_DONE,
    output		[ 2:0]  SYNC_FSM_RX

);

    //---------- Input FF or Buffer ------------------------
    reg					mmcm_lock_reg1;
    reg                 rxelecidle_reg1;
    reg                 rxcdrlock_reg1;
    
    reg					txsync_start_reg1;
    reg                 txphinitdone_reg1;
    reg                 txdlysresetdone_reg1;
    reg                 txphaligndone_reg1;
    
    reg					rxsync_start_reg1;
    reg                 rxdlysresetdone_reg1;
    reg                 rxphaligndone_reg1;
    
    reg					mmcm_lock_reg2;
    reg                 rxelecidle_reg2;
    reg                 rxcdrlock_reg2;
    
    reg					txsync_start_reg2;
    reg                 txphinitdone_reg2;
    reg                 txdlysresetdone_reg2;
    reg                 txphaligndone_reg2;
    
    reg					rxsync_start_reg2;
    reg                 rxdlysresetdone_reg2;
    reg                 rxphaligndone_reg2;
    
    //---------- Output FF or Buffer -----------------------          
    reg                 txdlyen     = 1'd0;
    reg                 txsync_done = 1'd0;
    reg         [ 2:0]  fsm_tx      = 3'd0;     
    
    reg                 rxsync_done = 1'd0;         
    reg			[ 2:0]	fsm_rx      = 3'd0;   
   
    //---------- FSM ---------------------------------------                                         
    localparam          FSM_TXSYNC_IDLE  = 3'd0; 
    localparam          FSM_MMCM_LOCK    = 3'd1;                                     
    localparam          FSM_TXSYNC_START = 3'd2;
    localparam          FSM_TXPHINITDONE = 3'd3;            // Manual TX sync only
    localparam          FSM_TXSYNC_DONE1 = 3'd4;   
    localparam          FSM_TXSYNC_DONE2 = 3'd5;             
        
    localparam          FSM_RXSYNC_IDLE  = 3'd0; 
    localparam          FSM_RXCDRLOCK    = 3'd1;                                     
    localparam          FSM_RXSYNC_START = 3'd2;
    localparam          FSM_RXSYNC_DONE1 = 3'd3;                                     
    localparam          FSM_RXSYNC_DONE2 = 3'd4;
        
    
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge SYNC_CLK)
begin

    if (!SYNC_RST_N)
        begin    
        //---------- 1st Stage FF --------------------------  
        mmcm_lock_reg1       <= 1'd0;
        rxelecidle_reg1      <= 1'd0;
		rxcdrlock_reg1 	     <= 1'd0;
		
		txsync_start_reg1	 <= 1'd0;
		txphinitdone_reg1    <= 1'd0;
        txdlysresetdone_reg1 <= 1'd0;
        txphaligndone_reg1   <= 1'd0;
        
        rxsync_start_reg1	 <= 1'd0; 
        rxdlysresetdone_reg1 <= 1'd0;
        rxphaligndone_reg1   <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        mmcm_lock_reg2       <= 1'd0;
        rxelecidle_reg2      <= 1'd0;
		rxcdrlock_reg2 	     <= 1'd0;
		
		txsync_start_reg2	 <= 1'd0;
		txphinitdone_reg2    <= 1'd0;
        txdlysresetdone_reg2 <= 1'd0;
        txphaligndone_reg2   <= 1'd0;
        
        rxsync_start_reg1	 <= 1'd0; 
        rxdlysresetdone_reg2 <= 1'd0;
        rxphaligndone_reg2   <= 1'd0;
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        mmcm_lock_reg1       <= SYNC_MMCM_LOCK;
        rxelecidle_reg1      <= SYNC_RXELECIDLE;
		rxcdrlock_reg1	     <= SYNC_RXCDRLOCK;
		
		txsync_start_reg1    <= SYNC_TXSYNC_START;
		txphinitdone_reg1    <= SYNC_TXPHINITDONE;
        txdlysresetdone_reg1 <= SYNC_TXDLYSRESETDONE;
        txphaligndone_reg1   <= SYNC_TXPHALIGNDONE;
        
        rxsync_start_reg1	 <= SYNC_RXSYNC_START; 
        rxdlysresetdone_reg1 <= SYNC_RXDLYSRESETDONE;
        rxphaligndone_reg1   <= SYNC_RXPHALIGNDONE;
        //---------- 2nd Stage FF --------------------------
        mmcm_lock_reg2       <= mmcm_lock_reg1;
        rxelecidle_reg2      <= rxelecidle_reg1;
        rxcdrlock_reg2       <= rxcdrlock_reg1;
        
        txsync_start_reg2    <= txsync_start_reg1;       
        txphinitdone_reg2    <= txphinitdone_reg1; 
        txdlysresetdone_reg2 <= txdlysresetdone_reg1;   
        txphaligndone_reg2   <= txphaligndone_reg1;
        
        rxsync_start_reg2    <= rxsync_start_reg1;
        rxdlysresetdone_reg2 <= rxdlysresetdone_reg1; 
        rxphaligndone_reg2   <= rxphaligndone_reg1;
        end
        
end       



//---------- PIPE TX Sync FSM --------------------------------------------------
always @ (posedge SYNC_CLK)
begin

    if (!SYNC_RST_N)
        begin
        fsm_tx      <= FSM_TXSYNC_IDLE;   
        txdlyen     <= 1'd0; 
        txsync_done <= 1'd0;
        end                    
    else
        begin
        
        case (fsm_tx)
        
        //---------- Idle State ----------------------------
        FSM_TXSYNC_IDLE :
        
            begin
            if (txsync_start_reg2)
                begin
                fsm_tx      <= FSM_MMCM_LOCK;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            else
                begin
                fsm_tx      <= FSM_TXSYNC_IDLE;
                txdlyen     <= txdlyen; 
                txsync_done <= txsync_done;
                end
            end
            
        //---------- Check for MMCM Lock -------------------
        FSM_MMCM_LOCK :
        
            begin
            if (mmcm_lock_reg2)
                begin
                fsm_tx      <= FSM_TXSYNC_START;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            else
                begin
                fsm_tx      <= FSM_MMCM_LOCK;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            end   
            
        //---------- Start TX Sync -------------------------
        FSM_TXSYNC_START :
        
            begin
            if (txdlysresetdone_reg2)
                begin
                fsm_tx      <= FSM_TXPHINITDONE;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            else
                begin
                fsm_tx      <= FSM_TXSYNC_START;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            end
            
        //---------- Wait for TXPHINITDONE -----------------
        FSM_TXPHINITDONE :
        
            begin
            if ((!txphinitdone_reg2 && txphinitdone_reg1) || PCIE_AUTO_TXSYNC)
                begin
                fsm_tx      <= FSM_TXSYNC_DONE1;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            else
                begin
                fsm_tx      <= FSM_TXPHINITDONE;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            end
            
        //---------- Wait for TXPHALIGNDONE (Phase Align) --
        FSM_TXSYNC_DONE1 :
        
            begin
            if ((!txphaligndone_reg2 && txphaligndone_reg1) || BYPASS_TXPHASE_ALIGN)
                begin
                fsm_tx      <= FSM_TXSYNC_DONE2;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            else
                begin
                fsm_tx      <= FSM_TXSYNC_DONE1;
                txdlyen     <= 1'd0; 
                txsync_done <= 1'd0;
                end
            end  
            
        //---------- Wait for TXPHALIGNDONE (Delay Align) --
        FSM_TXSYNC_DONE2 :
        
            begin
            if ((!txphaligndone_reg2 && txphaligndone_reg1) || SYNC_SLAVE || BYPASS_TXDELAY_ALIGN) 
                begin
                fsm_tx      <= FSM_TXSYNC_IDLE;
                txdlyen     <= !SYNC_SLAVE; 
                txsync_done <= 1'd1;
                end
            else
                begin
                fsm_tx      <= FSM_TXSYNC_DONE2;
                txdlyen     <= !SYNC_SLAVE; 
                txsync_done <= 1'd0;
                end
            end         
                          
        //---------- Default State -------------------------
        default :
            begin 
            fsm_tx      <= FSM_TXSYNC_IDLE;
            txdlyen     <= 1'd0; 
            txsync_done <= 1'd0;
            end
            
    	endcase
        
        end
        
end     
          
          
          
 //---------- PIPE RX Sync FSM --------------------------------------------------
always @ (posedge SYNC_CLK)
begin

    if (!SYNC_RST_N)
        begin
        fsm_rx      <= FSM_RXSYNC_IDLE; 
        rxsync_done <= 1'd0;   
        end                    
    else
        begin
        
        case (fsm_rx)
        
        //---------- Idle State ----------------------------
        FSM_RXSYNC_IDLE :
        
            begin
            if (rxsync_start_reg2)
                begin
                fsm_rx      <= FSM_RXCDRLOCK;
                rxsync_done <= 1'd0;
                end
            else
                begin
                fsm_rx <= FSM_RXSYNC_IDLE;
                
                //---------- Reset RXSYNC_DONE if RXELECIDLE = 1 
                if (rxelecidle_reg2)
                    rxsync_done <= 1'd0;
                else
                    rxsync_done <= rxsync_done;
                
                end
            end
            
        //---------- Wait for RXELECIDLE and RXCDRLOCK -----
        FSM_RXCDRLOCK :
        
            begin
            if (!rxelecidle_reg2 && rxcdrlock_reg2)
                begin
                fsm_rx      <= FSM_RXSYNC_START;
                rxsync_done <= 1'd0;
                end
            else
                begin
                fsm_rx      <= FSM_RXCDRLOCK;
                rxsync_done <= 1'd0;
                end
            end   
            
        //---------- Start RX Sync -------------------------
        FSM_RXSYNC_START :
        
            begin
            //---------- Hold RXDLYSRESET until RXDLYSRESETDONE
            if (rxdlysresetdone_reg2)
                begin
                fsm_rx      <= FSM_RXSYNC_DONE1;
                rxsync_done <= 1'd0;
                end
            else
                begin
                fsm_rx      <= FSM_RXSYNC_START;
                rxsync_done <= 1'd0;
                end
            end     
                  
        //---------- Wait for RXPHALIGNDONE (Phase Align) --
        FSM_RXSYNC_DONE1 :
        
            begin
            if ((rxphaligndone_reg1 && !rxphaligndone_reg2) || BYPASS_RXPHASE_ALIGN)
                begin
                fsm_rx      <= FSM_RXSYNC_DONE2;
                rxsync_done <= 1'd0;
                end
            else
                begin
                fsm_rx      <= FSM_RXSYNC_DONE1;
                rxsync_done <= 1'd0;
                end
            end  
            
        //---------- Wait for RXPHALIGNDONE (Delay Align) --
        FSM_RXSYNC_DONE2 :
        
            begin
            if ((rxphaligndone_reg1 && !rxphaligndone_reg2) || SYNC_SLAVE || BYPASS_RXDELAY_ALIGN) 
                begin
                fsm_rx      <= FSM_RXSYNC_IDLE;
                rxsync_done <= 1'd1;
                end
            else
                begin
                fsm_rx      <= FSM_RXSYNC_DONE2;
                rxsync_done <= 1'd0;
                end
            end     
                          
        //---------- Default State -------------------------
        default : 
            begin
            fsm_rx      <= FSM_RXSYNC_IDLE;
            rxsync_done <= 1'd0;
            end    
                    
    	endcase
        
        end
        
end            
          
   

//---------- PIPE Sync Output --------------------------------------------------            
assign SYNC_TXPHALIGNEN = PCIE_AUTO_TXSYNC ? 1'd0 : 1'd1;                          
assign SYNC_TXDLYSRESET = (fsm_tx == FSM_TXSYNC_START); 
assign SYNC_TXPHINIT    = PCIE_AUTO_TXSYNC ? 1'd0 : (fsm_tx == FSM_TXPHINITDONE); 
assign SYNC_TXPHALIGN   = PCIE_AUTO_TXSYNC ? 1'd0 : (fsm_tx == FSM_TXSYNC_DONE1);
assign SYNC_TXDLYEN     = PCIE_AUTO_TXSYNC ? 1'd0 : txdlyen;
assign SYNC_TXSYNC_DONE = txsync_done;
assign SYNC_FSM_TX      = fsm_tx;

assign SYNC_RXDLYSRESET = (fsm_rx == FSM_RXSYNC_START);
assign SYNC_RXSYNC_DONE = rxsync_done;
assign SYNC_FSM_RX		= fsm_rx;  



endmodule
