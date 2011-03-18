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
// File       : pipe_user.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  PIPE User Module for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE User Module --------------------------------------------------
module pipe_user #
(

    parameter RXCDRLOCK_MAX = 4'd3,                         // RXCDRLOCK max count
    parameter RXVALID_MAX   = 4'd3                          // RXVALID max count
    
)

(

    //---------- Input -------------------------------------
    input               USER_CLK,
    input               USER_RST_N,
    input               USER_RESETOVRD_START,
    input               USER_TXRESETDONE,
    input               USER_RXRESETDONE,
    input               USER_TXELECIDLE,
    input               USER_TXCOMPLIANCE,
    input               USER_RXCDRLOCK_IN,
    input               USER_RXVALID_IN,
    input       [ 2:0]  USER_RXSTATUS_IN,
    input               USER_PHYSTATUS_IN,
    input               USER_RATE_DONE,
    input       [ 3:0]  USER_RST_FSM,
    input       [ 4:0]  USER_RATE_FSM,
    
    //---------- Output ------------------------------------
    output              USER_RESETOVRD,
    output              USER_TXPMARESET,                            
    output              USER_RXPMARESET,                           
    output              USER_RXCDRRESET,               
    output              USER_RXCDRFREQRESET,           
    output              USER_RXDFELPMRESET,            
    output              USER_EYESCANRESET,             
    output              USER_TXPCSRESET,                              
    output              USER_RXPCSRESET,                            
    output              USER_RXBUFRESET,   
    output              USER_RESETOVRD_DONE,            
    output              USER_RESETDONE,
    output              USER_ACTIVE_LANE,
    output              USER_RXCDRLOCK_OUT,
    output              USER_RXVALID_OUT,
    output              USER_PHYSTATUS_OUT,
    output              USER_PHYSTATUS_RST 

);
    
    //---------- Input FF or Buffer ------------------------   
    reg                 resetovrd_start_reg1;
    reg                 txresetdone_reg1;
    reg                 rxresetdone_reg1; 
    reg                 txelecidle_reg1;
    reg                 txcompliance_reg1;
	reg	                rxcdrlock_reg1;
    reg                 rxvalid_reg1;
    reg         [ 2:0]  rxstatus_reg1;
    reg                 rate_done_reg1;

    reg                 resetovrd_start_reg2;
    reg                 txresetdone_reg2;
    reg                 rxresetdone_reg2; 
    reg                 txelecidle_reg2;
    reg                 txcompliance_reg2;
	reg	                rxcdrlock_reg2;
    reg                 rxvalid_reg2;
    reg         [ 2:0]  rxstatus_reg2;
    reg                 rate_done_reg2;
    
    //---------- Internal Signal ---------------------------
    reg         [ 7:0]  reset_cnt     = 8'hFF;
    reg         [ 7:0]  reset         = 8'd0;
    reg         [ 3:0]  rxcdrlock_cnt = 4'd0;
    reg         [ 3:0]  rxvalid_cnt   = 4'd0;
    
    //---------- Output FF or Buffer -----------------------
    reg         [ 1:0]  fsm = 2'd0;
    
    //---------- FSM ---------------------------------------                                         
    localparam          FSM_IDLE           = 2'd0; 
    localparam          FSM_RESETOVRD      = 2'd1;
    localparam          FSM_RESET_INIT     = 2'd2;
    localparam          FSM_RESET          = 2'd3;                                                                       
    
    //---------- PIPE Rate FSM -----------------------------                           
    localparam          RST_FSM_IDLE  = 4'd0;              
    localparam          RATE_FSM_IDLE = 5'd0;                        
    localparam          RATE_FSM_DONE = 5'd21;              // Must match value from pipe_rate.v



//---------- Input FF ----------------------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        begin    
        //---------- 1st Stage FF --------------------------   
        resetovrd_start_reg1 <= 1'd0;
        txresetdone_reg1     <= 1'd0;
        rxresetdone_reg1     <= 1'd0; 
        txelecidle_reg1      <= 1'd0;
        txcompliance_reg1    <= 1'd0;
		rxcdrlock_reg1 	     <= 1'd0;
        rxvalid_reg1         <= 1'd0;
        rxstatus_reg1        <= 3'd0;
        rate_done_reg1       <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        resetovrd_start_reg2 <= 1'd0;
        txresetdone_reg2     <= 1'd0;
        rxresetdone_reg2     <= 1'd0; 
        txelecidle_reg2      <= 1'd0;
        txcompliance_reg2    <= 1'd0;
		rxcdrlock_reg2 	     <= 1'd0;
        rxvalid_reg2         <= 1'd0;
        rxstatus_reg2        <= 3'd0;
        rate_done_reg2       <= 1'd0;
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        resetovrd_start_reg1 <= USER_RESETOVRD_START;
        txresetdone_reg1     <= USER_TXRESETDONE;
        rxresetdone_reg1     <= USER_RXRESETDONE;
        txelecidle_reg1      <= USER_TXELECIDLE;
        txcompliance_reg1    <= USER_TXCOMPLIANCE;
		rxcdrlock_reg1 	     <= USER_RXCDRLOCK_IN;
        rxvalid_reg1         <= USER_RXVALID_IN;
        rxstatus_reg1        <= USER_RXSTATUS_IN;
        rate_done_reg1       <= USER_RATE_DONE;
        //---------- 2nd Stage FF --------------------------
        resetovrd_start_reg2 <= resetovrd_start_reg1;
        txresetdone_reg2     <= txresetdone_reg1;      
        rxresetdone_reg2     <= rxresetdone_reg1;      
        txelecidle_reg2      <= txelecidle_reg1;       
        txcompliance_reg2    <= txcompliance_reg1;     
        rxcdrlock_reg2 	     <= rxcdrlock_reg1; 	   
        rxvalid_reg2         <= rxvalid_reg1;            
        rxstatus_reg2        <= rxstatus_reg1;         
        rate_done_reg2       <= rate_done_reg1;        
        end
        
end 



//---------- Reset Counter -----------------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        reset_cnt <= 8'hFF;
    else
    
        //---------- Decrement Counter ---------------------
        if (((fsm == FSM_RESETOVRD) || (fsm == FSM_RESET)) && (reset_cnt != 8'd0))
            reset_cnt <= reset_cnt - 8'd1;
            
        //---------- Reset Counter -------------------------
        else 
        
            case (reset)
            
                8'b00000000 : reset_cnt <= 8'd127;           // PMARESET time
                8'b11111111 : reset_cnt <= 8'd127;           // Additional RXCDRRESET time
                8'b11111110 : reset_cnt <= 8'd127;           // Additional RXCDRFREQRESET time
                8'b11111100 : reset_cnt <= 8'd127;           // Additional RXDFELPMRESET time
                8'b11111000 : reset_cnt <= 8'd127;           // Additional EYESCANRESET time
                8'b11110000 : reset_cnt <= 8'd127;           // Additional PCSRESET time
                8'b11100000 : reset_cnt <= 8'd127;           // Additional RXBUFRESET time
                8'b11000000 : reset_cnt <= 8'd127;           // Wait time for RESETOVRD deassertion
                8'b10000000 : reset_cnt <= 8'd127;
                default     : reset_cnt <= 8'd127;
                
            endcase
end 



//---------- Reset Shift Register ----------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        begin
        reset <= 8'd0;
        end                    
    else
    
        //---------- Initialize Reset Register -------------
        if (fsm == FSM_RESET_INIT)
            reset <= 8'hFF;
        else
            
            //---------- Shift Reset Register --------------
            if ((fsm == FSM_RESET) && (reset_cnt == 8'd0))
                reset <= {reset[6:0], 1'd0};
                
            //---------- Hold Reset Register ---------------    
            else
                reset <= reset;
        
 end
     
        

//---------- User Reset FSM ----------------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        begin
        fsm <= FSM_IDLE;   
        end                    
    else
        begin
        
        case (fsm)
        
        //---------- Idle State ----------------------------
        FSM_IDLE :
        
            begin
            if (resetovrd_start_reg2)
                begin
                fsm <= FSM_RESETOVRD;
                end
            else
                begin
                fsm <= FSM_IDLE;
                end
            end
            
        //---------- Assert RESETOVRD ----------------------
        FSM_RESETOVRD :
        
            begin
            if (reset_cnt == 8'd0)
                begin
                fsm <= FSM_RESET_INIT;
                end
            else
                begin
                fsm <= FSM_RESETOVRD;
                end
            end
            
        //---------- Initialize Reset ----------------------
        FSM_RESET_INIT :
        
            begin
            fsm <= FSM_RESET;
            end
            
        //---------- Shift Reset ---------------------------
        FSM_RESET :
        
            begin
            if (&(~reset))
                begin
                fsm <= FSM_IDLE;
                end
            else
                begin
                fsm <= FSM_RESET;
                end
            end
                  
        //---------- Default State -------------------------
        default :
            begin 
            fsm <= FSM_IDLE;
            end
            
    	endcase
        
        end
        
end 




//---------- RXCDRLOCK Filter --------------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        rxcdrlock_cnt <= 4'd0;
    else
    
        //---------- Increment RXCDRLOCK Counter -----------
        if (rxcdrlock_reg2 && (rxcdrlock_cnt != RXCDRLOCK_MAX))
            rxcdrlock_cnt <= rxcdrlock_cnt + 4'd1;
            
        //---------- Hold RXCDRLOCK Counter ----------------
        else if (rxcdrlock_reg2 && (rxcdrlock_cnt == RXCDRLOCK_MAX))
            rxcdrlock_cnt <= rxcdrlock_cnt;
            
        //---------- Reset RXCDRLOCK Counter ---------------
        else
            rxcdrlock_cnt <= 4'd0;
        
end 



//---------- RXVALID Filter ----------------------------------------------------
always @ (posedge USER_CLK)
begin

    if (!USER_RST_N)
        rxvalid_cnt <= 4'd0;
    else
    
        //---------- Increment RXVALID Counter -------------
        if (rxvalid_reg2 && (rxvalid_cnt != RXVALID_MAX) && (!rxstatus_reg2[2]))
            rxvalid_cnt <= rxvalid_cnt + 4'd1;
            
        //---------- Hold RXVALID Counter ------------------
        else if (rxvalid_reg2 && (rxvalid_cnt == RXVALID_MAX))
            rxvalid_cnt <= rxvalid_cnt;
            
        //---------- Reset RXVALID Counter -----------------
        else
            rxvalid_cnt <= 4'd0;
        
end 



//---------- PIPE User Output --------------------------------------------------   
assign USER_RESETOVRD      = (fsm != FSM_IDLE);
assign USER_TXPMARESET     = 1'd0; 
assign USER_RXPMARESET     = reset[0];  
assign USER_RXCDRRESET     = reset[1];
assign USER_RXCDRFREQRESET = reset[2];
assign USER_RXDFELPMRESET  = reset[3];
assign USER_EYESCANRESET   = reset[4];
assign USER_TXPCSRESET     = 1'd0;  
assign USER_RXPCSRESET     = reset[5];  
assign USER_RXBUFRESET     = reset[6];  
assign USER_RESETOVRD_DONE = (fsm == FSM_IDLE);
assign USER_RESETDONE      = (txresetdone_reg2  && rxresetdone_reg2);
assign USER_ACTIVE_LANE    = !(txelecidle_reg2  && txcompliance_reg2);
assign USER_RXCDRLOCK_OUT  = (USER_RXCDRLOCK_IN && (rxcdrlock_cnt == RXCDRLOCK_MAX));
assign USER_RXVALID_OUT    = ((USER_RXVALID_IN  && (rxvalid_cnt   == RXVALID_MAX)) &&     // Gated RXVALID
                             ((USER_RST_FSM  == RST_FSM_IDLE) &&                          // Force RXVALID   = 0 during reset
                              (USER_RATE_FSM == RATE_FSM_IDLE)));                         // Force RXVALID   = 0 during rate change
assign USER_PHYSTATUS_OUT  = ((USER_RST_FSM  != RST_FSM_IDLE)                         ||  // Force PHYSTATUS = 1 during reset
                             ((USER_RATE_FSM == RATE_FSM_IDLE) && USER_PHYSTATUS_IN ) ||  // Raw PHYSTATUS
                             ((USER_RATE_FSM == RATE_FSM_DONE) && USER_RATE_DONE));       // Gated PHYSTATUS for rate change
assign USER_PHYSTATUS_RST  = (USER_RST_FSM != RST_FSM_IDLE);                              // Filtered PHYSTATUS for reset

endmodule
