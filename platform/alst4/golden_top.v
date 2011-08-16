//--------------------------------------------------------------------------//
// Title:       golden_top.v                                                //
// Rev:         Rev 4                                                       //
// Author:      Altera                                                      //
//--------------------------------------------------------------------------//
// Description: All Stratix IV GX FPGA Dev Kit I/O signals and settings     //
//              such as termination, drive strength, etc...                 //
//              Some toggle_rate=0 where needed for fitter rules. (TR=0)    // 
//--------------------------------------------------------------------------//
// Revision History:                                                        //
// Rev 1:       First cut from tcl-script output. 3/26/2009                 //
// Rev 2:       Minor textual edits and clean-up.  Board trace models left  //
//              as separate tcl scripts from golden_top settings file.      //
//              Transceiver GXB pins including reference clocks are         //
//              commented out.  Add GXB instatiation under to use these.    //
//              12/23/2009                                                  //
// Rev 3:       Reformat and added comments.  Removed logic.  Added safe    // 
//              settings.  Changed XCVR input termination to OCT 100ohms    //
//              from Differential.  09/06/2010                              //
// Rev 4:       Corrected pinout for ddr3bot_ck_p and ddr3bot_ck_n per SPR  //
//              320427.                                                     // 
//----------------------------------------------------------------------------
//------ 1 ------- 2 ------- 3 ------- 4 ------- 5 ------- 6 ------- 7 ------7
//------ 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------- 0 ------8
//----------------------------------------------------------------------------
//Copyright © 2010 Altera Corporation. All rights reserved.  Altera products  
//are protected under numerous U.S. and foreign patents, maskwork rights,     
//copyrights and other intellectual property laws.                            
//                                                                            
//This reference design file, and your use thereof, is subject to and         
//governed by the terms and conditions of the applicable Altera Reference     
//Design License Agreement.  By using this reference design file, you         
//indicate your acceptance of such terms and conditions between you and       
//Altera Corporation.  In the event that you do not agree with such terms and 
//conditions, you may not use the reference design file. Please promptly      
//destroy any copies you have made.                                           
//                                                                            
//This reference design file being provided on an "as-is" basis and as an     
//accommodation and therefore all warranties, representations or guarantees   
//of any kind (whether express, implied or statutory) including, without      
//limitation, warranties of merchantability, non-infringement, or fitness for 
//a particular purpose, are specifically disclaimed.  By making this          
//reference design file available, Altera expressly does not recommend,       
//suggest or require that this reference design file be used in combination   
//with any other product not provided by Altera.                              
//                                                                            

module golden_top (

//GPLL-CLK-----------------------------//8 pins
   input          clkin_50,            //2.5V    //50 MHz, also to EPM2210F256
   input          clkintop_100_p,      //LVDS    //100 MHz prog osc
   input          clkinbot_100_p,      //LVDS    //100 MHz prog osc
   input  [1:1]   clk_125_p,           //LVDS    //125 MHz GPLL-req's OCT
   output         clkout_sma,          //2.5V    //PLL clock output or GPIO
//XCVR-REFCLK--------------------------//12 pins //req's ALTGXB instatiation
   //input  [0:0]   clk_125_p,         //LVDS    //125 MHz REFCLK-req's OCT
   //input          clk_148_p,         //LVDS    //148.5 MHz REFCLK-req's OCT
   //input          clk_155_p,         //LVPECL  //155.52 MHz REFCLK-no OCT
   //input          clk_156_p,         //LVDS    //156.25 MHz REFCLK-req's OCT
   //input          clkinlt_100_p,     //LVDS    //100 MHz prog osc-req's OCT
   //input          clkinrt_100_p,     //LVDS    //100 MHz prog osc-req's OCT

//Power-Monitor------------------------//8 pins  //--------------------------
   //Bussed to FPGA and EPM2210
   //EPM2210 is default master
   //output         sense_adc_f0,      //2.5V    //LTC2418 Fref (0-ohm-to-GND)
   //output         sense_cs0n,        //2.5V    //LTC2418 Device 0 sel (TR=0)
   //output         sense_cs1n,        //2.5V    //LTC2418 Device 1 sel (TR=0)
   //output         sense_sck,         //2.5V    //LTC2418 Clk (TR=0)
   //input          sense_sdi,         //2.5V    //LTC2418 Data out (TR=0)
   //output         sense_sdo,         //2.5V    //LTC2418 Data in (TR=0)
   //output         sense_smb_clk,     //2.5V    //LTC4151 & MAX1619 Clk(TR=0)
   //inout          sense_smb_data,    //2.5V    //LTC4151 & MAX1619 Dat(TR=0)

//DDR3BOT-x64--------------------------//117pins //--------------------------
   output  [14:0] ddr3bot_a,           //SSTL15  //Address
   output  [2:0]  ddr3bot_ba,          //SSTL15  //Bank Address
   output         ddr3bot_casn,        //SSTL15  //Column Address Strobe
   output         ddr3bot_ck_n,        //SSTL15  //Diff Clock - Neg
   output         ddr3bot_ck_p,        //SSTL15  //Diff Clock - Pos
   output         ddr3bot_cke,         //SSTL15  //Clock Enable
   output         ddr3bot_csn,         //SSTL15  //Chip Select
   output  [7:0]  ddr3bot_dm,          //SSTL15  //Data Write Mask
   inout   [63:0] ddr3bot_dq,          //SSTL15  //Data Bus
   inout   [7:0]  ddr3bot_dqs_n,       //SSTL15  //Diff Data Strobe - Neg
   inout   [7:0]  ddr3bot_dqs_p,       //SSTL15  //Diff Data Strobe - Pos
   output         ddr3bot_odt,         //SSTL15  //On-Die Termination Enable
   output         ddr3bot_rasn,        //SSTL15  //Row Address Strobe
   output         ddr3bot_rstn,        //SSTL15  //Reset
   output         ddr3bot_wen,         //SSTL15  //Write Enable

//DDR3TOP-x16--------------------------//49 pins //--------------------------
   output  [14:0] ddr3top_a,           //SSTL15  //Address
   output  [2:0]  ddr3top_ba,          //SSTL15  //Bank Address
   output         ddr3top_casn,        //SSTL15  //Column Address Strobe
   output         ddr3top_ck_n,        //SSTL15  //Diff Clock - Neg
   output         ddr3top_ck_p,        //SSTL15  //Diff Clock - Pos
   output         ddr3top_cke,         //SSTL15  //Clock Enable
   output         ddr3top_csn,         //SSTL15  //Chip Select
   output  [1:0]  ddr3top_dm,          //SSTL15  //Data Write Mask
   inout   [15:0] ddr3top_dq,          //SSTL15  //Data Bus
   inout   [1:0]  ddr3top_dqs_n,       //SSTL15  //Diff Data Strobe - Neg
   inout   [1:0]  ddr3top_dqs_p,       //SSTL15  //Diff Data Strobe - Pos
   output         ddr3top_odt,         //SSTL15  //On-Die Termination Enable
   output         ddr3top_rasn,        //SSTL15  //Row Address Strobe
   output         ddr3top_rstn,        //SSTL15  //Reset
   output         ddr3top_wen,         //SSTL15  //Write Enable

//QDR2TOP0-x18read/x18write------------//66 pins //--------------------------
   output  [19:0] qdr2top0_a,          //HSTL15  //Address
   output  [1:0]  qdr2top0_bwsn,       //HSTL15  //Byte Write Select
   input          qdr2top0_cq_n,       //HSTL15  //Read Data Clock - Neg
   input          qdr2top0_cq_p,       //HSTL15  //Read Data Clock - Pos
   output  [17:0] qdr2top0_d,          //HSTL15  //Write Data
   output         qdr2top0_doffn,      //HSTL15  //PLL disable (TR=0)
   output         qdr2top0_k_n,        //HSTL15  //Write Data Clock - Neg
   output         qdr2top0_k_p,        //HSTL15  //Write Data Clock - Pos
   output         qdr2top0_odt,        //HSTL15  //On-Die Termination Enable
   input   [17:0] qdr2top0_q,          //HSTL15  //Read Data
   input          qdr2top0_qvld,       //HSTL15  //Read Data Valid
   output         qdr2top0_rpsn,       //HSTL15  //Read Port Select
   output         qdr2top0_wpsn,       //HSTL15  //Write Port Select

//QDR2TOP1-x18read/x18write------------//66 pins //--------------------------
   output  [19:0] qdr2top1_a,          //HSTL15  //Address
   output  [1:0]  qdr2top1_bwsn,       //HSTL15  //Byte Write Select
   input          qdr2top1_cq_n,       //HSTL15  //Read Data Clock - Neg
   input          qdr2top1_cq_p,       //HSTL15  //Read Data Clock - Pos
   output  [17:0] qdr2top1_d,          //HSTL15  //Write Data
   output         qdr2top1_doffn,      //HSTL15  //PLL disable (TR=0)
   output         qdr2top1_k_n,        //HSTL15  //Write Data Clock - Neg
   output         qdr2top1_k_p,        //HSTL15  //Write Data Clock - Pos
   output         qdr2top1_odt,        //HSTL15  //On-Die Termination Enable
   input   [17:0] qdr2top1_q,          //HSTL15  //Read Data
   input          qdr2top1_qvld,       //HSTL15  //Read Data Valid
   output         qdr2top1_rpsn,       //HSTL15  //Read Port Select
   output         qdr2top1_wpsn,       //HSTL15  //Write Port Select

//Ethernet-10/100/1000-----------------//8 pins  //--------------------------
   input          enet_intn,           //2.5V    //MDIO Interrupt (TR=0)
   output         enet_mdc,            //2.5V    //MDIO Clock (TR=0)
   inout          enet_mdio,           //2.5V    //MDIO Data (TR=0)
   output         enet_resetn,         //2.5V    //Device Reset (TR=0)
   input          enet_rx_p,           //LVDS    //SGMII Receive-req's OCT
   output         enet_tx_p,           //LVDS    //SGMII Transmit

//HDMI-Video-Output--------------------//39 pins //--------------------------
   output         hdmi_clk,            //1.8V    //Video Data Clock
   output  [23:0] hdmi_d,              //1.8V    //Video Data
   output         hdmi_de,             //1.8V    //End
   output         hdmi_hsync,          //1.8V    //Horizontal Sync
   output   [3:0] hdmi_i2s,            //1.8V    //I2S Digital Audio
   input          hdmi_intn,           //1.5V    //Interrupt (TR=0) 
                                                 //(ran out of 1.8V)
   output         hdmi_lrclk,          //1.8V    //Digital Audio Clock
   output         hdmi_mclk,           //1.8V    //Digital Audio Clock
   output         hdmi_scl,            //1.8V    //SM Bus Clock (TR=0)
   output         hdmi_sclk,           //1.8V    //I2S Digital Audio Clock
   inout          hdmi_sda,            //1.8V    //SM Bus Data (TR=0)
   output         hdmi_spdif,          //1.8V    //SPDIF Digital Audio
   output         hdmi_vsync,          //1.8V    //Vertical Sync

//SDI-Video-Port-----------------------//7 pins  //--------------------------
   //input          sdi_rx_p,          //PCML14  //SDI Video Input-req's OCT
   //output         sdi_tx_p,          //PCML14  //SDI Video Output
   output         sdi_clk148_dn,       //2.5V    //VCO Frequency Down
   output         sdi_clk148_up,       //2.5V    //VCO Frequency Up
   output         sdi_tx_sd_hdn,       //2.5V    //HD Mode Enable

//FSM-Shared-Bus---(Flash/SRAM/Max)----//78 pins //--------------------------
   output  [25:0] fsm_a,               //2.5V    //Address
   inout   [31:0] fsm_d,               //2.5V    //Data
   output         flash_advn,          //2.5V    //Flash Address Valid
   output         flash_cen,           //2.5V    //Flash Chip Enable
   output         flash_clk,           //2.5V    //Flash Clock
   output         flash_oen,           //2.5V    //Flash Output Enable
   input          flash_rdybsyn,       //2.5V    //Flash Ready/Busy
   output         flash_resetn,        //2.5V    //Flash Reset
   output         flash_wen,           //2.5V    //Flash Write Enable
   output         sram_adscn,          //2.5V    //SRAM Address Strobe Cntrl
   output         sram_adspn,          //2.5V    //SRAM Address Strobe Proc
   output         sram_advn,           //2.5V    //SRAM Address Valid
   output         sram_bwen,           //2.5V    //SRAM Byte Write Enable
   output   [3:0] sram_bwn,            //2.5V    //SRAM Byte Write Per Byte
   output         sram_cen,            //2.5V    //SRAM Chip Enable
   output         sram_clk,            //2.5V    //SRAM Clock
   inout    [3:0] sram_dqp,            //2.5V    //SRAM Parity Bits
   output         sram_gwn,            //2.5V    //SRAM Global Write Enable
   output         sram_oen,            //2.5V    //SRAM Output Enable
   output         sram_zz,             //2.5V    //SRAM Sleep
   output   [3:0] max2_ben,            //2.5V    //Max II Byte Enable Per Byte
   output         max2_clk,            //2.5V    //Max II Clk
   output         max2_csn,            //2.5V    //Max II Chip Select
   output         max2_oen,            //2.5V    //Max II Output Enable
   output         max2_wen,            //2.5V    //Max II Write Enable

//Character-LCD------------------------//11 pins //--------------------------
   output         lcd_csn,             //2.5V    //LCD Chip Select
   output         lcd_d_cn,            //2.5V    //LCD Data / Command Select
   inout    [7:0] lcd_data,            //2.5V    //LCD Data
   output         lcd_wen,             //2.5V    //LCD Write Enable

//User-IO------------------------------//27 pins //--------------------------
   input    [7:0] user_dipsw,          //2.5V    //User DIP Switches (TR=0)
   output  [15:0] user_led,            //2.5V    //User LEDs
   input    [2:0] user_pb,             //2.5V    //User Pushbuttons (TR=0)
   input          cpu_resetn,          //2.5V    //CPU Reset Pushbutton (TR=0)

//PCI-Express--------------------------//25 pins //--------------------------
   //input  [7:0] pcie_rx_p,           //PCML14  //PCIe Receive Data-req's OCT
   //output [7:0] pcie_tx_p,           //PCML14  //PCIe Transmit Data
   //input        pcie_refclk_p,       //HCSL    //PCIe Clock- Terminate on MB
   output         pcie_led_g2,         //2.5V    //User LED - Labeled Gen2
   output         pcie_led_x1,         //2.5V    //User LED - Labeled x1
   output         pcie_led_x4,         //2.5V    //User LED - Labeled x4
   output         pcie_led_x8,         //2.5V    //User LED - Labeled x8
   input          pcie_perstn,         //2.5V    //PCIe Reset 
   input          pcie_smbclk,         //2.5V    //SMBus Clock (TR=0)
   inout          pcie_smbdat,         //2.5V    //SMBus Data (TR=0)
   output         pcie_waken,          //2.5V    //PCIe Wake-Up (TR=0) 
                                                 //must install 0-ohm resistor

//Transceiver-SMA-Output---------------//2 pins  //--------------------------
   //input          sma_tx_p,          //PCML14  //SMA Output Pair

//HSMC-Port-A--------------------------//107pins //--------------------------
   //input  [7:0] hsma_rx_p,           //PCML14  //HSMA Receive Data-req's OCT
   //output [7:0] hsma_tx_p,           //PCML14  //HSMA Transmit Data
 //Enable below for CMOS HSMC        
   //inout  [79:0]  hsma_d,            //2.5V    //HSMA CMOS Data Bus
 //Enable below for LVDS HSMC        
   input          hsma_clk_in0,        //2.5V    //Primary single-ended CLKIN
   input          hsma_clk_in_p1,      //LVDS    //Secondary diff. CLKIN
   input          hsma_clk_in_p2,      //LVDS    //Primary Source-Sync CLKIN
   output         hsma_clk_out0,       //2.5V    //Primary single-ended CLKOUT
   output         hsma_clk_out_p1,     //LVDS    //Secondary diff. CLKOUT
   output         hsma_clk_out_p2,     //LVDS    //Primary Source-Sync CLKOUT
   inout    [3:0] hsma_d,              //2.5V    //Dedicated CMOS IO
   input          hsma_prsntn,         //2.5V    //HSMC Presence Detect Input
   input   [16:0] hsma_rx_d_p,         //LVDS    //LVDS Sounce-Sync Input
   output  [16:0] hsma_tx_d_p,         //LVDS    //LVDS Sounce-Sync Output
   output         hsma_rx_led,         //2.5V    //User LED - Labeled RX
   output         hsma_scl,            //2.5V    //SMBus Clock
   inout          hsma_sda,            //2.5V    //SMBus Data
   output         hsma_tx_led,         //2.5V    //User LED - Labeled TX

//HSMC-Port-B--------------------------//107pins //--------------------------
   //input  [7:0] hsmb_rx_p,           //PCML14  //HSMB Receive Data-req's OCT
   //output [7:0] hsmb_tx_p,           //PCML14  //HSMB Transmit Data
 //Enable below for CMOS HSMC        
   //inout  [79:0]  hsmb_d,            //2.5V    //HSMB CMOS Data Bus
 //Enable below for LVDS HSMC        
   input          hsmb_clk_in0,        //2.5V    //Primary single-ended CLKIN
   input          hsmb_clk_in_p1,      //LVDS    //Secondary diff. CLKIN
   input          hsmb_clk_in_p2,      //LVDS    //Primary Source-Sync CLKIN
   output         hsmb_clk_out0,       //2.5V    //Primary single-ended CLKOUT
   output         hsmb_clk_out_p1,     //LVDS    //Secondary diff. CLKOUT
   output         hsmb_clk_out_p2,     //LVDS    //Primary Source-Sync CLKOUT
   inout    [3:0] hsmb_d,              //2.5V    //Dedicated CMOS IO
   input          hsmb_prsntn,         //2.5V    //HSMC Presence Detect Input
   input   [16:0] hsmb_rx_d_p,         //LVDS    //LVDS Sounce-Sync Input
   output  [16:0] hsmb_tx_d_p,         //LVDS    //LVDS Sounce-Sync Output
   output         hsmb_rx_led,         //2.5V    //User LED - Labeled RX
   output         hsmb_scl,            //2.5V    //SMBus Clock
   inout          hsmb_sda,            //2.5V    //SMBus Data
   output         hsmb_tx_led          //2.5V    //User LED - Labeled TX
);


endmodule
