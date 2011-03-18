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
// File       : pipe_clock.v
// Version    : 1.1
//------------------------------------------------------------------------------
//  Filename     :  pipe_clock.v
//  Description  :  PIPE Clock Module for 7 Series Transceiver
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Clock Module -------------------------------------------------
module pipe_clock #
(

    parameter PCIE_TXBUF_EN      = "FALSE",                 // PCIe TX buffer enable
    parameter PCIE_LANE          = 1,                       // PCIe number of lanes
    parameter PCIE_LINK_SPEED    = 3,                       // PCIe link speed 
    parameter PCIE_REFCLK_FREQ   = 0,                       // PCIe reference clock frequency
    parameter PCIE_USERCLK1_FREQ = 1,                       // PCIe user clock 1 frequency
    parameter PCIE_USERCLK2_FREQ = 1                        // PCIe user clock 2 frequency
    
)

(

    //---------- Input -------------------------------------
    input                       CLK_CLK,
    input                       CLK_TXOUTCLK,
    input       [PCIE_LANE-1:0] CLK_RXOUTCLK,
    input                       CLK_RST_N,
    input       [PCIE_LANE-1:0] CLK_PCLK_SEL,
    input                       CLK_GEN3,
    
    //---------- Output ------------------------------------
    output                      CLK_FAB_REFCLK,
    output                      CLK_PCLK,
    output      [PCIE_LANE-1:0] CLK_RXUSRCLK,
    output                      CLK_DCLK,
    output                      CLK_USERCLK1,
    output                      CLK_USERCLK2,
    output                      CLK_MMCM_LOCK
    
);
    
    //---------- Select Clock Divider ----------------------
    localparam          DIVCLK_DIVIDE    = (PCIE_REFCLK_FREQ == 2) ? 2 :
                                           (PCIE_REFCLK_FREQ == 1) ? 1 : 1;
                                               
    localparam          CLKFBOUT_MULT_F  = (PCIE_REFCLK_FREQ == 2) ? 8 :
                                           (PCIE_REFCLK_FREQ == 1) ? 8 : 10;
                                               
    localparam          CLKOUT0_DIVIDE_F = 8;
    
    localparam          CLKOUT1_DIVIDE   = 4;
    
    localparam          CLKIN1_PERIOD    = (PCIE_REFCLK_FREQ == 2) ? 4 :
                                           (PCIE_REFCLK_FREQ == 1) ? 8 : 10;
    
    localparam          CLKOUT2_DIVIDE   = (PCIE_USERCLK1_FREQ == 4) ?  2 : 
                                           (PCIE_USERCLK1_FREQ == 3) ?  4 :
                                           (PCIE_USERCLK1_FREQ == 2) ?  8 :
                                           (PCIE_USERCLK1_FREQ == 0) ? 32 : 16;
                                               
    localparam          CLKOUT3_DIVIDE   = (PCIE_USERCLK2_FREQ == 4) ?  2 : 
                                           (PCIE_USERCLK2_FREQ == 3) ?  4 :
                                           (PCIE_USERCLK2_FREQ == 2) ?  8 :
                                           (PCIE_USERCLK2_FREQ == 0) ? 32 : 16;
       
    //---------- Internal Signals -------------------------- 
    wire                        refclk;
    wire                        mmcm_fb_in;
    wire                        mmcm_fb_out;
    wire                        clk_125mhz;
    wire                        clk_250mhz;
    wire                        userclk1;
    wire                        userclk2;
    reg         [PCIE_LANE-1:0] pclk_sel_reg1 = {PCIE_LANE{1'b0}};
    reg         [PCIE_LANE-1:0] pclk_sel_reg2 = {PCIE_LANE{1'b0}};
    reg                         pclk_sel      = 1'd0;
    reg                         gen3_reg1     = 1'd0;
    reg                         gen3_reg2     = 1'd0;

    //---------- Output FF or Buffer -----------------------
    wire                pclk_1;
    wire                pclk;
    wire                mmcm_lock;
    
    //---------- Generate Per-Lane Signals -----------------
  //genvar              i;                                  // Index for per-lane signals



//---------- Input FF ----------------------------------------------------------
always @ (posedge pclk)
begin

    if (!CLK_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        pclk_sel_reg1 <= {PCIE_LANE{1'b0}};
        gen3_reg1     <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        pclk_sel_reg2 <= {PCIE_LANE{1'b0}};
        gen3_reg2     <= 1'd0;
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        pclk_sel_reg1 <= CLK_PCLK_SEL;
        gen3_reg1     <= CLK_GEN3;
        //---------- 2nd Stage FF --------------------------
        pclk_sel_reg2 <= pclk_sel_reg1;
        gen3_reg2     <= gen3_reg1;
        end
        
end



//---------- Reference Clock -----------------------------------------------
BUFG refclk_i
(

    //---------- Input -------------------------------------
    .I                          (((PCIE_TXBUF_EN == "TRUE") && (PCIE_LINK_SPEED != 3)) ? CLK_CLK : CLK_TXOUTCLK),
    
    //---------- Output ------------------------------------
    .O                          (refclk)
   
);



//---------- Fabric Reference Clock --------------------------------------------
BUFG fab_refclk_i
(

    //---------- Input -------------------------------------
    .I                          (CLK_CLK),
    
    //---------- Output ------------------------------------
    .O                          (CLK_FAB_REFCLK)
   
);



//---------- MMCM --------------------------------------------------------------
// Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
// Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
//------------------------------------------------------------------------------
// CLK_OUT1   125.000      0.000    50.000      234.137     98.575
// CLK_OUT2   250.000      0.000    50.000      226.449     98.575
//
//------------------------------------------------------------------------------
// Input Clock   Input Freq (MHz)   Input Jitter (UI)
//------------------------------------------------------------------------------
// primary         100.000            0.100
//------------------------------------------------------------------------------
MMCME2_ADV #
(

    .BANDWIDTH                  ("OPTIMIZED"),
    .CLKOUT4_CASCADE 			("FALSE"),
    .COMPENSATION               ("ZHOLD"),
    .STARTUP_WAIT               ("FALSE"),
    .DIVCLK_DIVIDE              (DIVCLK_DIVIDE),
    .CLKFBOUT_MULT_F            (CLKFBOUT_MULT_F),  
    .CLKFBOUT_PHASE             (0.000),
    .CLKFBOUT_USE_FINE_PS       ("FALSE"),
    .CLKOUT0_DIVIDE_F           (CLKOUT0_DIVIDE_F),                    
    .CLKOUT0_PHASE              (0.000),
    .CLKOUT0_DUTY_CYCLE         (0.500),
    .CLKOUT0_USE_FINE_PS        ("FALSE"),
    .CLKOUT1_DIVIDE             (CLKOUT1_DIVIDE),                    
    .CLKOUT1_PHASE              (0.000),
    .CLKOUT1_DUTY_CYCLE         (0.500),
    .CLKOUT1_USE_FINE_PS        ("FALSE"),
    .CLKOUT2_DIVIDE             (CLKOUT2_DIVIDE),                  
    .CLKOUT2_PHASE              (0.000),
    .CLKOUT2_DUTY_CYCLE         (0.500),
    .CLKOUT2_USE_FINE_PS        ("FALSE"),
    .CLKOUT3_DIVIDE             (CLKOUT3_DIVIDE),                  
    .CLKOUT3_PHASE              (0.000),
    .CLKOUT3_DUTY_CYCLE         (0.500),
    .CLKOUT3_USE_FINE_PS        ("FALSE"),
    .CLKIN1_PERIOD              (CLKIN1_PERIOD),                   
    .REF_JITTER1                (0.100)
    
)
mmcm_i
(

     //---------- Input ------------------------------------
    .CLKIN1                     (refclk),
    .CLKIN2                     (1'd0),
    .CLKINSEL                   (1'd1),
    .CLKFBIN                    (mmcm_fb_in),
    .RST                        (!CLK_RST_N),
    .PWRDWN                     (1'd0), 
    
    //---------- Output ------------------------------------
    .CLKFBOUT                   (mmcm_fb_out),
    .CLKFBOUTB                  (),
    .CLKOUT0                    (clk_125mhz),
    .CLKOUT0B                   (),
    .CLKOUT1                    (clk_250mhz),
    .CLKOUT1B                   (),
    .CLKOUT2                    (userclk1),
    .CLKOUT2B                   (),
    .CLKOUT3                    (userclk2),
    .CLKOUT3B                   (),
    .CLKOUT4                    (),
    .CLKOUT5                    (),
    .CLKOUT6                    (),
    .LOCKED                     (mmcm_lock),
    
    //---------- Dynamic Reconfiguration -------------------
    .DCLK                       (1'd0),
    .DADDR                      (7'd0),
    .DEN                        (1'd0),
    .DWE                        (1'd0),
    .DI                         (16'd0),
    .DO                         (),
    .DRDY                       (),
    
    //---------- Dynamic Phase Shift -----------------------
    .PSCLK                      (1'd0),
    .PSEN                       (1'd0),
    .PSINCDEC                   (1'd0),
    .PSDONE                     (),
    
    //---------- Control and Status ------------------------
    .CLKINSTOPPED               (),
    .CLKFBSTOPPED               ()

);



//---------- MMCM Feedback Clock -----------------------------------------------
BUFG mmcm_fb_i
(

    //---------- Input -------------------------------------
    .I                          (mmcm_fb_out),
    
    //---------- Output ------------------------------------
    .O                          (mmcm_fb_in)
    
);
    
  
      
//---------- PIPE Clock --------------------------------------------------------
BUFGMUX pclk_1_i
(
    
    //---------- Input -------------------------------------
    .I0                         (clk_125mhz),
    .I1                         (clk_250mhz),
    .S                          (pclk_sel),
        
    //---------- Output ------------------------------------ 
    .O                          (pclk_1)
       
);



//---------- MMCM Feedback Clock -----------------------------------------------
BUFG pclk_i
(

    //---------- Input -------------------------------------
    .I                          (pclk_1),
    
    //---------- Output ------------------------------------
    .O                          (pclk)
    
);



//---------- Generate PIPE Lane ------------------------------------------------
/*
generate for (i=0; i<PCIE_LANE; i=i+1) begin : rxusrclk_lane

//---------- RX User Clock -----------------------------------------------------
BUFGMUX rxusrclk_i
(
    
    //---------- Input -------------------------------------
    .I0                         (pclk_1),
    .I1                         (CLK_RXOUTCLK[i]),
    .S                          (CLK_GEN3),                    
        
    //---------- Output ------------------------------------ 
    .O                          (CLK_RXUSRCLK[i])
       
);

end endgenerate
*/



//---------- RX User Clock -----------------------------------------------------
BUFGMUX rxusrclk_i
(
    
    //---------- Input -------------------------------------
    .I0                         (pclk_1),
    .I1                         (CLK_RXOUTCLK[0]),
    .S                          (gen3_reg2),                    
        
    //---------- Output ------------------------------------ 
    .O                          (CLK_RXUSRCLK[0])
       
);



//---------- DRP Clock ---------------------------------------------------------
BUFG dclk_i
(

    //---------- Input -------------------------------------
    .I                          (clk_125mhz),
    
    //---------- Output ------------------------------------
    .O                          (CLK_DCLK)
   
);



//---------- User Clock 1 ------------------------------------------------------
BUFG usrclk1_i
(

    //---------- Input -------------------------------------
    .I                          (userclk1),
    
    //---------- Output ------------------------------------
    .O                          (CLK_USERCLK1)
   
);



//---------- User Clock 2 ------------------------------------------------------
BUFG usrclk2_i
(

    //---------- Input -------------------------------------
    .I                          (userclk2),
    
    //---------- Output ------------------------------------
    .O                          (CLK_USERCLK2)
   
);



//---------- PCLK Select -------------------------------------------------------
always @ (posedge pclk)
begin

    if (!CLK_RST_N)
        pclk_sel <= 1'd0;
    else
        begin 

        //---------- Set PCLK = 1 --------------------------
        if (&pclk_sel_reg2)
            pclk_sel <= 1'd1;
            
        //---------- Set PCLK = 0 --------------------------    
        else if (&(~pclk_sel_reg2))
            pclk_sel <= 1'd0;
        
        //---------- Hold PCLK -----------------------------
        else
            pclk_sel <= pclk_sel;
            
        end

end        



//---------- PIPE Clock Output -------------------------------------------------
assign CLK_PCLK      = pclk;
assign CLK_MMCM_LOCK = mmcm_lock;



endmodule
