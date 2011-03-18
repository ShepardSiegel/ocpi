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
// File       : pipe_drp.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Description  :  PIPE DRP Module for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE DRP Module ---------------------------------------------------
module pipe_drp #
(

    parameter PCIE_SI_REV       = "1.0",                    // PCIe silicon revision
    parameter PCIE_TXBUF_EN     = "FALSE",                  // PCIe TX buffer enable
    parameter PCIE_AUTO_TXSYNC  = 0,                        // PCIe auto TX sync
    parameter PCIE_AUTO_RXSYNC  = 0,                        // PCIe auto RX sync
    parameter INDEX_MAX         = 4'd11                     // Index max count

        
)

(
    
    //---------- Input -------------------------------------
    input               DRP_CLK,
    input               DRP_RST_N,
    input               DRP_GTXRESET,
    input       [ 1:0]  DRP_RATE,
    input               DRP_START,
    input       [15:0]  DRP_DO,
    input               DRP_RDY,
    
    //---------- Output ------------------------------------
    output      [ 8:0]  DRP_ADDR,
    output              DRP_EN,  
    output      [15:0]  DRP_DI,   
    output              DRP_WE,
    output              DRP_DONE,
    output      [ 2:0]  DRP_FSM
    
);

    //---------- Input FF or Buffer ------------------------
    reg                 gtxreset_reg1;
    reg         [ 1:0]  rate_reg1;
    reg                 start_reg1;
    reg         [15:0]  do_reg1;
    reg                 rdy_reg1;
    
    reg                 gtxreset_reg2;
    reg         [ 1:0]  rate_reg2;
    reg                 start_reg2;
    reg         [15:0]  do_reg2;
    reg                 rdy_reg2;
    
    //---------- Internal Signals --------------------------
    reg         [ 3:0]  index    =  4'd0;
    reg                 mode     =  1'd0;
    reg         [ 8:0]  addr_reg =  9'd0;
    reg         [15:0]  di_reg   = 16'd0;
    
    //---------- Output FF or Buffer -----------------------
    reg         [ 2:0]  fsm = 3'd0;      
                        
    //---------- DRP Address -------------------------------
    localparam          ADDR_PCS_RSVD_ATTR     = 9'h06F;
    localparam          ADDR_CPLL_TXOUT_DIV    = 9'h088;
    localparam          ADDR_CPLL_RXOUT_DIV    = 9'h088;
    localparam          ADDR_TX_DATA_WIDTH     = 9'h06B;            
    localparam          ADDR_TX_INT_DATAWIDTH  = 9'h06B;         
    localparam          ADDR_RX_DATA_WIDTH     = 9'h011;            
    localparam          ADDR_RX_INT_DATAWIDTH  = 9'h011;              
    localparam          ADDR_TXBUF_EN          = 9'h01C;           
    localparam          ADDR_RXBUF_EN          = 9'h09D;
    localparam          ADDR_TX_XCLK_SEL       = 9'h059;
    localparam          ADDR_RX_XCLK_SEL       = 9'h059;                 
    localparam          ADDR_CLK_CORRECT_USE   = 9'h044; 
    localparam          ADDR_TX_DRIVE_MODE     = 9'h019;
    
    //---------- DRP Mask ---------------------------------- 
    localparam          MASK_PCS_RSVD_ATTR     = 16'b1111111111111001;  // Unmask bit [2:1]
    localparam          MASK_CPLL_TXOUT_DIV    = 16'b1111111110001111;  // Unmask bit [6:4]
    localparam          MASK_CPLL_RXOUT_DIV    = 16'b1111111111111000;  // Unmask bit [2:0]
    localparam          MASK_TX_DATA_WIDTH     = 16'b1111111111111000;  // Unmask bit [2:0]   
    localparam          MASK_TX_INT_DATAWIDTH  = 16'b1111111111101111;  // Unmask bit [4]
    localparam          MASK_RX_DATA_WIDTH     = 16'b1100011111111111;  // Unmask bit [13:11]   
    localparam          MASK_RX_INT_DATAWIDTH  = 16'b1011111111111111;  // Unmask bit [14]  
    localparam          MASK_TXBUF_EN          = 16'b1011111111111111;  // Unmask bit [14]  
    localparam          MASK_RXBUF_EN          = 16'b1111111111111101;  // Unmask bit [1] 
    localparam          MASK_TX_XCLK_SEL       = 16'b1111111101111111;  // Unmask bit [7]    
    localparam          MASK_RX_XCLK_SEL       = 16'b1111111110111111;  // Unmask bit [6]       
    localparam          MASK_CLK_CORRECT_USE   = 16'b1011111111111111;  // Unmask bit [14]
    localparam          MASK_TX_DRIVE_MODE     = 16'b1111111111100000;  // Unmask bit [4:0]
     
    //---------- DRP Data for PCIe Gen 1 and 2 -------------
    localparam          GEN12_PCS_RSVD_ATTR_A  = 16'b0000000000000000;  // Auto TX sync mode
    localparam          GEN12_PCS_RSVD_ATTR_M  = 16'b0000000000000010;  // Manual TX sync mode
    localparam          GEN12_CPLL_TXOUT_DIV   = 16'b0000000000010000;  // Divide by 2
    localparam          GEN12_CPLL_RXOUT_DIV   = 16'b0000000000000001;  // Divide by 2
    localparam          GEN12_TX_DATA_WIDTH    = 16'b0000000000000011;  // 2-byte external data width   
    localparam          GEN12_TX_INT_DATAWIDTH = 16'b0000000000000000;  // 2-byte internal data width
    localparam          GEN12_RX_DATA_WIDTH    = 16'b0001100000000000;  // 2-byte external data width
    localparam          GEN12_RX_INT_DATAWIDTH = 16'b0000000000000000;  // 2-byte internal data width
    localparam          GEN12_TXBUF_EN         = 16'b0100000000000000;  // Use TX buffer if PCIE_TXBUF_EN == "TRUE"
    localparam          GEN12_RXBUF_EN         = 16'b0000000000000010;  // Use RX buffer  
    localparam          GEN12_TX_XCLK_SEL      = 16'b0000000000000000;  // Use TXOUT if PCIE_TXBUF_EN == "TRUE"
    localparam          GEN12_RX_XCLK_SEL      = 16'b0000000000000000;  // Use RXREC  
    localparam          GEN12_CLK_CORRECT_USE  = 16'b0100000000000000;  // Use clock correction
    localparam          GEN12_TX_DRIVE_MODE    = 16'b0000000000000001;  // Use PIPE Gen 1 and 2 mode 
    
    //---------- DRP Data for PCIe Gen 3 --------------------                  
    localparam          GEN3_CPLL_TXOUT_DIV    = 16'b0000000000000000;  // Divide by 1
    localparam          GEN3_CPLL_RXOUT_DIV    = 16'b0000000000000000;  // Divide by 1
    localparam          GEN3_TX_DATA_WIDTH     = 16'b0000000000000100;  // 4-byte external data width                     
    localparam          GEN3_TX_INT_DATAWIDTH  = 16'b0000000000010000;  // 4-byte internal data width               
    localparam          GEN3_RX_DATA_WIDTH     = 16'b0010000000000000;  // 4-byte external data width                  
    localparam          GEN3_RX_INT_DATAWIDTH  = 16'b0100000000000000;  // 4-byte internal data width               
    localparam          GEN3_TXBUF_EN          = 16'b0000000000000000;  // Bypass TX buffer 
    localparam          GEN3_RXBUF_EN          = 16'b0000000000000000;  // Bypass RX buffer  
    localparam          GEN3_TX_XCLK_SEL       = 16'b0000000010000000;  // Use TXUSR  
    localparam          GEN3_RX_XCLK_SEL       = 16'b0000000001000000;  // Use RXUSR                         
    localparam          GEN3_CLK_CORRECT_USE   = 16'b0000000000000000;  // Bypass clock correction  
    localparam          GEN3_TX_DRIVE_MODE     = 16'b0000000000000010;  // Use PIPE Gen 3 mode                
      
    //---------- DRP Data ----------------------------------   
    wire        [15:0]  data_pcs_rsvd_attr;      
    wire        [15:0]  data_cpll_txout_div;
    wire        [15:0]  data_cpll_rxout_div;
    wire        [15:0]  data_tx_data_width;               
    wire        [15:0]  data_tx_int_datawidth;            
    wire        [15:0]  data_rx_data_width;               
    wire        [15:0]  data_rx_int_datawidth;                
    wire        [15:0]  data_txbuf_en;        
    wire        [15:0]  data_rxbuf_en;        
    wire        [15:0]  data_tx_xclk_sel;
    wire        [15:0]  data_rx_xclk_sel;            
    wire        [15:0]  data_clk_correction_use; 
    wire        [15:0]  data_tx_drive_mode;
           
    //---------- FSM ---------------------------------------  
    localparam          FSM_IDLE  = 3'd0;  
    localparam          FSM_LOAD  = 3'd1;                           
    localparam          FSM_READ  = 3'd2;
    localparam          FSM_RRDY  = 3'd3;
    localparam          FSM_WRITE = 3'd4;
    localparam          FSM_WRDY  = 3'd5;    
    localparam          FSM_DONE  = 3'd6; 
    
    
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        gtxreset_reg1 <= 1'd0;
        rate_reg1     <= 2'd0;
        do_reg1       <= 16'd0;
        rdy_reg1      <= 1'd0;
        start_reg1    <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        gtxreset_reg2 <= 1'd0;
        rate_reg2     <= 2'd0;
        do_reg2       <= 16'd0;
        rdy_reg2      <= 1'd0;
        start_reg2    <= 1'd0;
        end
        
    else
        begin
        //---------- 1st Stage FF --------------------------
        gtxreset_reg1 <= DRP_GTXRESET;
        rate_reg1     <= DRP_RATE;
        do_reg1       <= DRP_DO;
        rdy_reg1      <= DRP_RDY;
        start_reg1    <= DRP_START;
        //---------- 2nd Stage FF --------------------------
        gtxreset_reg2 <= gtxreset_reg1;
        rate_reg2     <= rate_reg1;
        do_reg2       <= do_reg1;
        rdy_reg2      <= rdy_reg1;
        start_reg2    <= start_reg1;
        end
    
end  



//---------- Select DRP Data ---------------------------------------------------
assign data_pcs_rsvd_attr      = PCIE_AUTO_TXSYNC    ? GEN12_PCS_RSVD_ATTR_A : GEN12_PCS_RSVD_ATTR_M;
assign data_cpll_txout_div     = (rate_reg2 == 2'd2) ? GEN3_CPLL_TXOUT_DIV   : GEN12_CPLL_TXOUT_DIV;
assign data_cpll_rxout_div     = (rate_reg2 == 2'd2) ? GEN3_CPLL_RXOUT_DIV   : GEN12_CPLL_RXOUT_DIV;
assign data_tx_data_width      = (rate_reg2 == 2'd2) ? GEN3_TX_DATA_WIDTH    : GEN12_TX_DATA_WIDTH;
assign data_tx_int_datawidth   = (rate_reg2 == 2'd2) ? GEN3_TX_INT_DATAWIDTH : GEN12_TX_INT_DATAWIDTH;
assign data_rx_data_width      = (rate_reg2 == 2'd2) ? GEN3_RX_DATA_WIDTH    : GEN12_RX_DATA_WIDTH;
assign data_rx_int_datawidth   = (rate_reg2 == 2'd2) ? GEN3_RX_INT_DATAWIDTH : GEN12_RX_INT_DATAWIDTH;
assign data_txbuf_en           = ((rate_reg2 == 2'd2) || (PCIE_TXBUF_EN == "FALSE")) ? GEN3_TXBUF_EN    : GEN12_TXBUF_EN;
assign data_rxbuf_en           = (rate_reg2 == 2'd2) ? GEN3_RXBUF_EN         : GEN12_RXBUF_EN;
assign data_tx_xclk_sel        = ((rate_reg2 == 2'd2) || (PCIE_TXBUF_EN == "FALSE")) ? GEN3_TX_XCLK_SEL : GEN12_TX_XCLK_SEL;
assign data_rx_xclk_sel        = (rate_reg2 == 2'd2) ? GEN3_RX_XCLK_SEL      : GEN12_RX_XCLK_SEL;
assign data_clk_correction_use = (rate_reg2 == 2'd2) ? GEN3_CLK_CORRECT_USE  : GEN12_CLK_CORRECT_USE;
assign data_tx_drive_mode      = (rate_reg2 == 2'd2) ? GEN3_TX_DRIVE_MODE    : GEN12_TX_DRIVE_MODE;



//---------- Update DRP Address and Data ---------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        addr_reg <= 9'd0;
        di_reg   <= 16'd0;
        end
    else
        begin
        
        case (index)
        
        
        //--------------------------------------------------      
        4'd0:     
            begin
            addr_reg <= mode ? ADDR_PCS_RSVD_ATTR : ADDR_CPLL_TXOUT_DIV; 
            di_reg   <= mode ? ((do_reg2 & MASK_PCS_RSVD_ATTR)  | GEN12_PCS_RSVD_ATTR_A)
                             : ((do_reg2 & MASK_CPLL_TXOUT_DIV) | data_cpll_txout_div);
            end 
            
        //--------------------------------------------------      
        4'd1:    
            begin
            addr_reg <= mode ? ADDR_PCS_RSVD_ATTR : ADDR_CPLL_RXOUT_DIV;
            di_reg   <= mode ? ((do_reg2 & MASK_PCS_RSVD_ATTR)  | GEN12_PCS_RSVD_ATTR_M) 
                             : ((do_reg2 & MASK_CPLL_RXOUT_DIV) | data_cpll_rxout_div);
            end 
        
        //--------------------------------------------------      
        4'd0:
            begin
            addr_reg <= ADDR_CPLL_TXOUT_DIV;
            di_reg   <= (do_reg2 & MASK_CPLL_TXOUT_DIV) | data_cpll_txout_div;
            end 
            
        //--------------------------------------------------      
        4'd1:
            begin
            addr_reg <= ADDR_CPLL_RXOUT_DIV;
            di_reg   <= (do_reg2 & MASK_CPLL_RXOUT_DIV) | data_cpll_rxout_div;
            end 
            
        //--------------------------------------------------
        4'd2 :
            begin        
            addr_reg <= ADDR_TX_DATA_WIDTH;
            di_reg   <= (do_reg2 & MASK_TX_DATA_WIDTH) | data_tx_data_width;
            end
           
        //--------------------------------------------------    
        4'd3 :
            begin        
            addr_reg <= ADDR_TX_INT_DATAWIDTH;
            di_reg   <= (do_reg2 & MASK_TX_INT_DATAWIDTH) | data_tx_int_datawidth;
            end    
        
        //--------------------------------------------------     
        4'd4 :
            begin
            addr_reg <= ADDR_RX_DATA_WIDTH;
            di_reg   <= (do_reg2 & MASK_RX_DATA_WIDTH) | data_rx_data_width;
            end   
        
        //--------------------------------------------------     
        4'd5 :
            begin        
            addr_reg <= ADDR_RX_INT_DATAWIDTH;
            di_reg   <= (do_reg2 & MASK_RX_INT_DATAWIDTH) | data_rx_int_datawidth;
            end  
  
        //--------------------------------------------------         
        4'd6 :
            begin        
            addr_reg <= ADDR_TXBUF_EN;
            di_reg   <= (do_reg2 & MASK_TXBUF_EN) | data_txbuf_en;
            end   
        
        //--------------------------------------------------         
        4'd7 :
            begin        
            addr_reg <= ADDR_RXBUF_EN;
            di_reg   <= (do_reg2 & MASK_RXBUF_EN) | data_rxbuf_en;
            end   
        
        //--------------------------------------------------         
        4'd8 :
            begin        
            addr_reg <= ADDR_TX_XCLK_SEL;
            di_reg   <= (do_reg2 & MASK_TX_XCLK_SEL) | data_tx_xclk_sel;
            end   
        
        //--------------------------------------------------         
        4'd9 :
            begin        
            addr_reg <= ADDR_RX_XCLK_SEL;
            di_reg   <= (do_reg2 & MASK_RX_XCLK_SEL) | data_rx_xclk_sel;
            end   
        
        //--------------------------------------------------      
        4'd10 :
            begin
            addr_reg <= ADDR_CLK_CORRECT_USE;
            di_reg   <= (do_reg2 & MASK_CLK_CORRECT_USE) | data_clk_correction_use;
            end 

        //--------------------------------------------------      
        4'd11 :
            begin
            addr_reg <= ADDR_TX_DRIVE_MODE;
            di_reg   <= (do_reg2 & MASK_TX_DRIVE_MODE) | data_tx_drive_mode;
            end 
            
        //--------------------------------------------------
        default : 
            begin
            addr_reg <= 9'd0;
            di_reg   <= 16'd0;
            end
            
        endcase
        
        end
        
end  



//---------- PIPE DRP FSM ------------------------------------------------------
always @ (posedge DRP_CLK)
begin

    if (!DRP_RST_N)
        begin
        fsm   <= FSM_IDLE;
        index <= 4'd0;
        mode  <= 1'd0;
        end
    else
        begin
        
        case (fsm)

        //---------- Idle State ----------------------------
        FSM_IDLE :  
          
            begin
            //---------- Reset or Rate Change --------------
            if (start_reg2)
                begin
                fsm   <= FSM_LOAD;
                index <= 4'd0;
                mode  <= 1'd0; 
                end
            //---------- GTXRESET --------------------------    
            else if ((gtxreset_reg2 && !gtxreset_reg1) && !PCIE_AUTO_TXSYNC && (PCIE_SI_REV == "1.0"))
                begin
                fsm   <= FSM_LOAD;
                index <= 4'd0;
                mode  <= 1'd1;
                end
            //---------- Idle ------------------------------
            else       
                begin
                fsm   <= FSM_IDLE;
                index <= 4'd0;
                mode  <= 1'd0;
                end 
            end    
            
        //---------- Load DRP Address  ---------------------
        FSM_LOAD :
        
            begin
            fsm   <= FSM_READ;
            index <= index;
            mode  <= mode;
            end  
            
        //---------- Read DRP ------------------------------
        FSM_READ :
        
            begin
            fsm   <= FSM_RRDY;
            index <= index;
            mode  <= mode;
            end
            
        //---------- Read DRP Ready ------------------------
        FSM_RRDY :    
        
            begin
            if (rdy_reg2)
                begin
                fsm   <= FSM_WRITE;
                index <= index;
                mode  <= mode;
                end
            else       
                begin
                fsm   <= FSM_RRDY;
                index <= index;
                mode  <= mode;
                end 
            end  
            
        //---------- Write DRP -----------------------------
        FSM_WRITE :    
        
            begin
            fsm   <= FSM_WRDY;
            index <= index;
            mode  <= mode;
            end       
            
        //---------- Write DRP Ready -----------------------
        FSM_WRDY :    
        
            begin
            if (rdy_reg2)
                begin
                fsm   <= FSM_DONE;
                index <= index;
                mode  <= mode;
                end
            else       
                begin
                fsm   <= FSM_WRDY;
                index <= index;
                mode  <= mode;
                end 
            end        
             
        //---------- DRP Done ------------------------------
        FSM_DONE :
        
            begin
            if ((index == INDEX_MAX) || (mode && (index == 4'd1)))
                begin
                fsm   <= FSM_IDLE;
                index <= 4'd0;
                mode  <= 1'd0;
                end
            else       
                begin
                fsm   <= FSM_LOAD;
                index <= index + 4'd1;
                mode  <= mode;
                end
            end     
              
        //---------- Default State -------------------------
        default :
        
            begin      
            fsm   <= FSM_IDLE;
            index <= 4'd0;
            mode  <= 1'd0;
            end
            
        endcase
        
        end
        
end 



//---------- PIPE DRP Output ---------------------------------------------------
assign DRP_ADDR = addr_reg;
assign DRP_EN   = (fsm == FSM_READ) || (fsm == FSM_WRITE);
assign DRP_DI   = di_reg;
assign DRP_WE   = (fsm == FSM_WRITE) || (fsm == FSM_WRDY);
assign DRP_DONE = (fsm == FSM_IDLE);
assign DRP_FSM  = fsm;



endmodule
