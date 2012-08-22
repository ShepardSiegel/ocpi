//*****************************************************************************
// (c) Copyright 2008-2010 Xilinx, Inc. All rights reserved.
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
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: %version
//  \   \         Application: MEMC
//  /   /         Filename: mcb_traffic_gen.v
// /___/   /\     Date Last Modified: $Date:
// \   \  /  \    Date Created:
//  \___\/\___\
//
//Device: Virtex7
//Design Name: s7ven_data_gen
//Purpose: This is top level module of memory traffic generator which can
//         generate different CMD_PATTERN and DATA_PATTERN to Virtex 7
//         hard memory controller core.
//         Supported Data pattern:  0 : Reserved.
//                                  1 : FIXED_DATA_MODE.
//                                  2 : ADDR_DATA_MODE
//                                  3 : HAMMER_DATA_MODE
//                                  4 : NEIGHBOR_DATA_MODE
//                                  5 : WALKING1_DATA_MODE
//                                  6 : WALKING0_DATA_MODE
//                                  7 : TRUE_PRBS_MODE
//
//                                 
//Reference:
//Revision History:     1.1    

//*****************************************************************************

`timescale 1ps/1ps
`ifndef TCQ
 `define TCQ 100
`endif

module s7ven_data_gen #
 
(  parameter DMODE = "WRITE",
   parameter nCK_PER_CLK = 2,   // 2: Memc core speed 1/2 of memory clock speed.
                                //    User data bus width = 4 x DQs data width.
                                // 4: memc core speed 1/4 of memory clock speed.
                                //    User data bus width = 8 x DQs data width.
   parameter MEM_TYPE      = "DDR3",
                                
   parameter TCQ        = 100,
   parameter BL_WIDTH   = 6,    // USER_Interface Command Burst Length
   parameter FAMILY     = "SPARTAN6",

   parameter EYE_TEST   = "FALSE",
   parameter ADDR_WIDTH = 32,
   parameter MEM_BURST_LEN = 8,
   parameter START_ADDR = 32'h00000000,
   parameter DWIDTH = 32,
   parameter DATA_PATTERN = "DGEN_ALL", //"DGEN__HAMMER", "DGEN_WALING1","DGEN_WALING0","DGEN_ADDR","DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"  
   parameter NUM_DQ_PINS   = 72,
   parameter COLUMN_WIDTH = 10,
   parameter SEL_VICTIM_LINE = 3  // VICTIM LINE is one of the DQ pins is selected to be different than hammer pattern
//   parameter [287:0] ALL_1 = {288{1'b1}},
//   parameter [287:0] ALL_0 = {288{1'b0}}
  
   
 )
 (
   input   clk_i,                 //
   input   rst_i, 
   input [31:0] prbs_fseed_i,
   input        mode_load_i,
   input        mem_init_done_i,
   input        wr_data_mask_gen_i,
   input [3:0]  data_mode_i,   // "00" = bram; 
   input        data_rdy_i,
   input   cmd_startA,  
   input   cmd_startB,         
   input   cmd_startC,         
   input   cmd_startD,         
   input   cmd_startE, 
   
   input [31:0] simple_data0 ,
   input [31:0] simple_data1 ,
   input [31:0] simple_data2 ,
   input [31:0] simple_data3 ,
   input [31:0] simple_data4 ,
   input [31:0] simple_data5 ,
   input [31:0] simple_data6 ,
   input [31:0] simple_data7 ,
   
   input [ADDR_WIDTH-1:0]  m_addr_i,          // generated address used to determine data pattern.
   input [31:0]     fixed_data_i,    
   
   input [ADDR_WIDTH-1:0]  addr_i,          // generated address used to determine data pattern.
   input [BL_WIDTH:0]    user_burst_cnt,   // generated burst length for control the burst data
   
   input   fifo_rdy_i,           // connect from mcb_wr_full when used as wr_data_gen
                                 // connect from mcb_rd_empty when used as rd_data_gen
                                 // When both data_rdy and data_valid is asserted, the ouput data is valid.
  // input [(DWIDTH/8)-1:0] wr_mask_count;
   output [(NUM_DQ_PINS*nCK_PER_CLK*2/8)-1:0] data_mask_o,                              
   output  [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] data_o ,  // generated data pattern   
   output                      bram_rd_valid_o
);  
// 

localparam PRBS_WIDTH = 8;//BL_WIDTH;
localparam TAPS_VALUE = (BL_WIDTH == 8)  ? 8'b10001110 :
           //  (BL_WIDTH == 10) ? 10'b1000000100:
                                   8'b10001110 ;


wire [31:0]       prbs_data; 
reg [35:0] acounts;

wire [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] fdata;
wire [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] bdata;
wire [31:0] bram_data;

wire [NUM_DQ_PINS*nCK_PER_CLK*2-1:0]        adata_tmp; 
wire [NUM_DQ_PINS*nCK_PER_CLK*2-1:0]        adata; 

wire [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] hammer_data;

reg [NUM_DQ_PINS*nCK_PER_CLK*2-1:0]  w1data; 
reg [NUM_DQ_PINS*2-1:0]        hdata; 

reg [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] w0data; 
reg [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] data;

reg burst_count_reached2;

reg               data_valid;
reg [2:0] walk_cnt;
reg [ADDR_WIDTH-1:0] user_address;
reg [ADDR_WIDTH-1:0]  m_addr_r;         // generated address used to determine data pattern.
reg sel_w1gen_logic;
//reg [7:0] BLANK;
reg [4*NUM_DQ_PINS -1 :0] sel_victimline_r;
reg data_clk_en,data_clk_en2;
wire [NUM_DQ_PINS*2*nCK_PER_CLK-1:0] full_prbs_data2;
wire [NUM_DQ_PINS*2*nCK_PER_CLK-1:0] psuedo_prbs_data;

reg [2*nCK_PER_CLK-1:0] prbs_mux_data;
reg [NUM_DQ_PINS*4-1:0] h_prbsdata;                        
wire [PRBS_WIDTH-1:0] prbs_seed;
reg [5:0] prbs_mux_counter;
reg [2*nCK_PER_CLK*16-1:0] prbs_comb_data;
reg prbs_seeded;
reg prbs_comb_data_load;
reg mode_has_loaded;
wire [127:0] prbs_shift_value;
reg next_calib_data;
reg [2*nCK_PER_CLK*NUM_DQ_PINS-1:0  ] calib_data;
wire [2*nCK_PER_CLK*NUM_DQ_PINS/8 -1:0] w1data_group;
wire [31:0] mcb_prbs_data;
wire [NUM_DQ_PINS-1:0] prbsdata_rising_0;
wire [NUM_DQ_PINS-1:0] prbsdata_falling_0;
wire [NUM_DQ_PINS-1:0] prbsdata_rising_1;
wire [NUM_DQ_PINS-1:0] prbsdata_falling_1;
wire [NUM_DQ_PINS-1:0] prbsdata_rising_2;
wire [NUM_DQ_PINS-1:0] prbsdata_falling_2;
wire [NUM_DQ_PINS-1:0] prbsdata_rising_3;
wire [NUM_DQ_PINS-1:0] prbsdata_falling_3 ;

wire [BL_WIDTH-1:0] prbs_o0,prbs_o1,prbs_o2,prbs_o3,prbs_o4,prbs_o5,prbs_o6,prbs_o7;
wire [BL_WIDTH-1:0] prbs_o8,prbs_o9,prbs_o10,prbs_o11,prbs_o12,prbs_o13,prbs_o14,prbs_o15;
wire [3:0] prbs_shift_value0,prbs_shift_value1,prbs_shift_value2,prbs_shift_value3,prbs_shift_value4;
wire [3:0] prbs_shift_value5,prbs_shift_value6,prbs_shift_value7,prbs_shift_value8,prbs_shift_value9;
wire [3:0] prbs_shift_value10,prbs_shift_value11,prbs_shift_value12,prbs_shift_value13,prbs_shift_value14;
wire [3:0] prbs_shift_value15;
wire [3:0] prbs_shift_value16,prbs_shift_value17,prbs_shift_value18,prbs_shift_value19,prbs_shift_value20;
wire [3:0] prbs_shift_value21,prbs_shift_value22,prbs_shift_value23,prbs_shift_value24,prbs_shift_value25;
wire [3:0] prbs_shift_value26,prbs_shift_value27,prbs_shift_value28,prbs_shift_value29,prbs_shift_value30;
wire [3:0] prbs_shift_value31;


//wire [nCK_PER_CLK * 32 -1 :0] prbs_shift_value;

wire [nCK_PER_CLK * 256 -1:0] ReSeedcounter;


reg mode_load_r1,mode_load_r2;
reg [3:0] htstpoint ;
reg data_clk_en2_r;
reg force_load;
reg [NUM_DQ_PINS-1:0] wdatamask_ripplecnt;
//wire [4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS] ALL_1 = 
reg mode_load_r;
reg user_burst_cnt_larger_1_r;


integer i,j,k;

localparam NUM_WIDTH = 2*nCK_PER_CLK*NUM_DQ_PINS;
localparam USER_BUS_DWIDTH = (nCK_PER_CLK == 2) ?  NUM_DQ_PINS*4 : NUM_DQ_PINS*8;


//*********************************************************************************************
localparam BRAM_DATAL_MODE       =    4'b0000;
localparam FIXED_DATA_MODE       =    4'b0001;
localparam ADDR_DATA_MODE        =    4'b0010;                                     
localparam HAMMER_DATA_MODE      =    4'b0011;
localparam NEIGHBOR_DATA_MODE    =    4'b0100;
localparam WALKING1_DATA_MODE    =    4'b0101;
localparam WALKING0_DATA_MODE    =    4'b0110;
localparam PRBS_DATA_MODE        =    4'b0111;

assign data_o = data;
generate
if (nCK_PER_CLK == 4) 
begin: full_prbs_data64
//always @ (prbsdata_falling_3,prbsdata_rising_3,prbsdata_falling_2,prbsdata_rising_2,prbsdata_falling_1,prbsdata_rising_1,prbsdata_falling_0,prbsdata_rising_0)
  assign  full_prbs_data2 = {prbsdata_falling_3,prbsdata_rising_3,prbsdata_falling_2,prbsdata_rising_2,prbsdata_falling_1,prbsdata_rising_1,prbsdata_falling_0,prbsdata_rising_0};
end
else   
begin:  full_prbs_data32
   assign full_prbs_data2 = {prbsdata_falling_1,prbsdata_rising_1,prbsdata_falling_0,prbsdata_rising_0};
end
endgenerate
generate

genvar p;

for (p = 0; p < NUM_DQ_PINS*nCK_PER_CLK*2/32; p = p+1) 
begin
   assign     psuedo_prbs_data[p*32+31:p*32] = mcb_prbs_data;

end
endgenerate



reg [NUM_DQ_PINS*nCK_PER_CLK*2-1:0] w1data_o;
reg [3:0] data_mode_rr_a;
reg [3:0] data_mode_rr_c;

// write data mask generation.
// Only support data pattern = address data mode.
// When wdatamask_ripple_cnt is asserted, the corresponding wr_data word will be jammed with 8'hff.

assign data_mask_o = (wr_data_mask_gen_i == 1'b1 && mem_init_done_i) ? wdatamask_ripplecnt :{ NUM_DQ_PINS*nCK_PER_CLK*2/8{1'b0}};

always @ (posedge clk_i)
begin
if (rst_i || ~wr_data_mask_gen_i || ~mem_init_done_i)
   wdatamask_ripplecnt <= 'b0;
else if (cmd_startA)
   //wdatamask_ripplecnt <= {15'd0,1'b1};
      wdatamask_ripplecnt <= {{NUM_DQ_PINS-1{1'b0}},1'b1};

else if (user_burst_cnt_larger_1_r && data_rdy_i)
   wdatamask_ripplecnt <= {wdatamask_ripplecnt[NUM_DQ_PINS-2:0],wdatamask_ripplecnt[NUM_DQ_PINS-1]};


end


generate
genvar n;
for (n = 0; n < NUM_DQ_PINS*nCK_PER_CLK*2/8; n = n+1) 
begin

   if (MEM_TYPE == "QDR2PLUS")  
       assign  adata = adata_tmp;// QDR not supporting masking  
   else
       assign  adata[n*8+7:n*8] = adata_tmp[n*8+7:n*8]| {8{wdatamask_ripplecnt[NUM_DQ_PINS-1]}};

end
endgenerate


always @ (posedge clk_i)
begin
  data_mode_rr_a <= #TCQ data_mode_i;
  data_mode_rr_c <= #TCQ data_mode_i;
 
end  



assign bdata = {USER_BUS_DWIDTH/32{bram_data[31:0]}};

// selected data pattern go through "data" mux to user data bus.
// 72 pin 1: failed
always @ (bdata,calib_data,hammer_data,adata,data_mode_rr_a,w1data,full_prbs_data2,psuedo_prbs_data)
begin
   case(data_mode_rr_a)  //
         // Simple Data Pattern for bring up
         //  0:          Reserved
         //  1:          32 bits fixed_data from user defined inputs. 
         //              The data from this static pattern is concatenated together multiple times 
         //              to make up the required number of bits as needed.
         //  2:          32 bits address as data 
         //              The data from this pattern is concatenated together multiple times 
         //              to make up the required number of bits as needed.
         //  4:          simple 8data pattern and repeats every 8 words. The pattern is embedded in RAM.         
         //  5,6:        Walkign 1,0 data.
         //  a           Calibration data pattern
   
         // 0,1,2,3,4,9:  use bram to implemnt.
         4'b0000,4'b0001,4'b0100,4'b1001: data = bdata;
         4'b0010: data = adata;    //  address as data     
         
         4'b0011: data = hammer_data;
         
         
         4'b0101, 4'b110: data = w1data;  // walking 1 or walking 0 data 
         // when vio_instr_mode_value set to 4'hf,the init_mem_pattern_ctr module
         // will automatically set the data_mode_o to 0x8
         4'b1010: data =calib_data;
         
         
         // Characterization Mode
         //  2:    Address as data
         //  3:    hammer data with option to select VICTIM line which output is always high.
         //  7:    Hammer PRBS. Only valid in V6,V7 family
         //  9:    Slow 2 MHz hammer pattern.
         4'b0111: data = full_prbs_data2;//{prbs_data,prbs_data,prbs_data,prbs_data};   //  "011" = prbs         
         4'b1000: data = psuedo_prbs_data;//{prbs_data,prbs_data,prbs_data,prbs_data};   //  "011" = prbs         
         
         default : begin
                //       for (i=0; i <= 4*NUM_DQ_PINS - 1; i= i+1)  begin: neighbor_data
               //      data = begin 
               //           for (
                   data = adata;
                   end
   endcase
end

// phy calibration data pattern
//  
generate
if (nCK_PER_CLK == 2) 
begin: calib_data32
always @ (posedge clk_i)
if (rst_i) begin
    next_calib_data <= 1'b0;
    calib_data <=  #TCQ {{(NUM_DQ_PINS/8){8'h55}},{(NUM_DQ_PINS/8){8'haa}},{(NUM_DQ_PINS/8){8'h00}},{(NUM_DQ_PINS/8){8'hff}}};
    end   
else if (cmd_startA)
     begin
     calib_data <=  #TCQ {{(NUM_DQ_PINS/8){8'h55}},{(NUM_DQ_PINS/8){8'haa}},{(NUM_DQ_PINS/8){8'h00}},{(NUM_DQ_PINS/8){8'hff}}};
     next_calib_data <=#TCQ  1'b1;
//     calib_data <= 'b0;
     end
   else if (fifo_rdy_i)  
     begin
     next_calib_data <= #TCQ  ~next_calib_data;
     if (next_calib_data )
     
     calib_data <= #TCQ  {{(NUM_DQ_PINS/8){8'h66}},{(NUM_DQ_PINS/8){8'h99}},{(NUM_DQ_PINS/8){8'haa}},{(NUM_DQ_PINS/8){8'h55}}};
     else
     calib_data <= #TCQ  {{(NUM_DQ_PINS/8){8'h55}},{(NUM_DQ_PINS/8){8'haa}},{(NUM_DQ_PINS/8){8'h00}},{(NUM_DQ_PINS/8){8'hff}}};
     end
end
else
begin: calib_data64  // when nCK_PER_LK =4 has not verified
always @ (posedge clk_i)

if (rst_i) begin
    next_calib_data <= 1'b0;
    calib_data <=  #TCQ {{(NUM_DQ_PINS/8){16'h5555}},{(NUM_DQ_PINS/8){16'haaaa}},{(NUM_DQ_PINS/8){16'h0000}},{(NUM_DQ_PINS/8){16'hffff}}};
    end   
else if (cmd_startA)
   begin
     calib_data <=  #TCQ {{(NUM_DQ_PINS/8){16'h5555}},{(NUM_DQ_PINS/8){16'haaaa}},{(NUM_DQ_PINS/8){16'h0000}},{(NUM_DQ_PINS/8){16'hffff}}};
     next_calib_data <=#TCQ  1'b1;
//     calib_data <= 'b0;
     end
   else if (fifo_rdy_i)  
     begin
     next_calib_data <= #TCQ  ~next_calib_data;
     if (next_calib_data )
     
     calib_data <= #TCQ  {{(NUM_DQ_PINS/8){16'h6666}},{(NUM_DQ_PINS/8){16'h9999}},{(NUM_DQ_PINS/8){16'haaaa}},{(NUM_DQ_PINS/8){16'h5555}}};
     else
     calib_data <= #TCQ  {{(NUM_DQ_PINS/8){16'h5555}},{(NUM_DQ_PINS/8){16'haaaa}},{(NUM_DQ_PINS/8){16'h0000}},{(NUM_DQ_PINS/8){16'hffff}}};
     end


end
endgenerate
/*

always @ (posedge clk_i)
begin    calib_data <= 'b0;

end
*/
//**************************************************************************
// Pattern bram generates fixed input, hammer, simple 8 repeat data pattern.
//**************************************************************************

function integer logb2;
  input [31:0] number;
  integer i;
  begin
    i = number;
      for(logb2=1; i>0; logb2=logb2+1)
        i = i >> 1;
  end
endfunction



vio_init_pattern_bram # 
( .MEM_BURST_LEN      (MEM_BURST_LEN),
  .START_ADDR         (START_ADDR),
  .NUM_DQ_PINS        (NUM_DQ_PINS),
  .SEL_VICTIM_LINE    (SEL_VICTIM_LINE)

)
vio_init_pattern_bram
(
 .clk_i              (clk_i ),
 .rst_i              (rst_i ),   
 // BL8 : least 3 address bits are always zero.
 // BL4 " least 2 address bits are always zero.
 // for walking 1's or 0's, the least 8 address bits are always zero.
 .cmd_addr           (addr_i),
 .cmd_start          (cmd_startB),
 .mode_load_i        (mode_load_i),
 .data_mode_i        (data_mode_rr_a),
 //.w1data              (w1data),
 .data0              (simple_data0 ),  
 .data1              (simple_data1 ),  
 .data2              (simple_data2 ),  
 .data3              (simple_data3 ),
 .data4              (simple_data4 ),
 .data5              (simple_data5 ),
 .data6              (simple_data6 ),
 .data7              (simple_data7 ),
 .data8              (fixed_data_i ),  

 .bram_rd_valid_o    (bram_rd_valid_o),
 .bram_rd_rdy_i      (user_burst_cnt_larger_1_r & (data_rdy_i | cmd_startB)),
 .dout_o             (bram_data)

 );



//**************************************************************
// Functions to be used byg Walking 1 and Walking 0 circuits.
//**************************************************************


function [2*nCK_PER_CLK*NUM_DQ_PINS-1:0] Data_Gen (input integer i );
 integer j;
  begin
    j = i/2;
    Data_Gen = {2*nCK_PER_CLK*NUM_DQ_PINS{1'b0}};
        if(i %2 == 1) begin
           if (nCK_PER_CLK == 2) begin
            Data_Gen[(0*NUM_DQ_PINS+j*8)+:8] = 8'b00010000;
            Data_Gen[(2*NUM_DQ_PINS+j*8)+:8] = 8'b01000000;
            Data_Gen[(1*NUM_DQ_PINS+j*8)+:8] = 8'b00100000;
            Data_Gen[(3*NUM_DQ_PINS+j*8)+:8] = 8'b10000000;
            end
           else begin
           
            Data_Gen[(0*NUM_DQ_PINS+j*8)+:8] = 8'b00010000;
            Data_Gen[(1*NUM_DQ_PINS+j*8)+:8] = 8'b00100000;
            Data_Gen[(2*NUM_DQ_PINS+j*8)+:8] = 8'b01000000; 
            Data_Gen[(3*NUM_DQ_PINS+j*8)+:8] = 8'b10000000;
            Data_Gen[(4*NUM_DQ_PINS+j*8)+:8] = 8'b00000001;
            Data_Gen[(5*NUM_DQ_PINS+j*8)+:8] = 8'b00000010;
            Data_Gen[(6*NUM_DQ_PINS+j*8)+:8] = 8'b00000100; 
            Data_Gen[(7*NUM_DQ_PINS+j*8)+:8] = 8'b00001000;
            
           end
        end else begin
           if (nCK_PER_CLK == 2) begin
            Data_Gen[(0*NUM_DQ_PINS+j*8)+:8] = 8'b00000001;
            Data_Gen[(1*NUM_DQ_PINS+j*8)+:8] = 8'b00000010;
            Data_Gen[(2*NUM_DQ_PINS+j*8)+:8] = 8'b00000100;
            Data_Gen[(3*NUM_DQ_PINS+j*8)+:8] = 8'b00001000;
           end
           else begin
            Data_Gen[(0*NUM_DQ_PINS+j*8)+:8] = 8'b00000001;
            Data_Gen[(1*NUM_DQ_PINS+j*8)+:8] = 8'b00000010;
            Data_Gen[(2*NUM_DQ_PINS+j*8)+:8] = 8'b00000100;
            Data_Gen[(3*NUM_DQ_PINS+j*8)+:8] = 8'b00001000;
            Data_Gen[(4*NUM_DQ_PINS+j*8)+:8] = 8'b00010000;
            Data_Gen[(5*NUM_DQ_PINS+j*8)+:8] = 8'b00100000;
            Data_Gen[(6*NUM_DQ_PINS+j*8)+:8] = 8'b01000000; 
            Data_Gen[(7*NUM_DQ_PINS+j*8)+:8] = 8'b10000000;
            
           end
           
           
           
           
           
        end
       
    
  end
endfunction



function [2*nCK_PER_CLK*NUM_DQ_PINS-1:0] Data_GenW0 (input integer i);
 integer j;
  begin
    j = i/2;
    Data_GenW0 = {2*nCK_PER_CLK*NUM_DQ_PINS{1'b1}};
    
        if(i %2  == 1) begin
             if (nCK_PER_CLK == 2) begin

             Data_GenW0[(0*NUM_DQ_PINS+j*8)+:8] = 8'b11101111;
             Data_GenW0[(1*NUM_DQ_PINS+j*8)+:8] = 8'b11011111;
             Data_GenW0[(2*NUM_DQ_PINS+j*8)+:8] = 8'b10111111;
             Data_GenW0[(3*NUM_DQ_PINS+j*8)+:8] = 8'b01111111;
             end
             else begin
             Data_GenW0[(0*NUM_DQ_PINS+j*8)+:8] = 8'b11101111;
             Data_GenW0[(1*NUM_DQ_PINS+j*8)+:8] = 8'b11011111;
             Data_GenW0[(2*NUM_DQ_PINS+j*8)+:8] = 8'b10111111;
             Data_GenW0[(3*NUM_DQ_PINS+j*8)+:8] = 8'b01111111;
             
             Data_GenW0[(4*NUM_DQ_PINS+j*8)+:8] = 8'b11111110;
             Data_GenW0[(5*NUM_DQ_PINS+j*8)+:8] = 8'b11111101;
             Data_GenW0[(6*NUM_DQ_PINS+j*8)+:8] = 8'b11111011; 
             Data_GenW0[(7*NUM_DQ_PINS+j*8)+:8] = 8'b11110111;
             
             end
        end else begin
            if (nCK_PER_CLK == 2) begin
        
            Data_GenW0[(0*NUM_DQ_PINS+j*8)+:8] = 8'b11111110;
            Data_GenW0[(1*NUM_DQ_PINS+j*8)+:8] = 8'b11111101;
            Data_GenW0[(2*NUM_DQ_PINS+j*8)+:8] = 8'b11111011;
            Data_GenW0[(3*NUM_DQ_PINS+j*8)+:8] = 8'b11110111;
            end
            else begin
            
            Data_GenW0[(0*NUM_DQ_PINS+j*8)+:8] = 8'b11111110;
            Data_GenW0[(1*NUM_DQ_PINS+j*8)+:8] = 8'b11111101;
            Data_GenW0[(2*NUM_DQ_PINS+j*8)+:8] = 8'b11111011;
            Data_GenW0[(3*NUM_DQ_PINS+j*8)+:8] = 8'b11110111;
            Data_GenW0[(4*NUM_DQ_PINS+j*8)+:8] = 8'b11101111;
            Data_GenW0[(5*NUM_DQ_PINS+j*8)+:8] = 8'b11011111;
            Data_GenW0[(6*NUM_DQ_PINS+j*8)+:8] = 8'b10111111; 
            Data_GenW0[(7*NUM_DQ_PINS+j*8)+:8] = 8'b01111111;
            
            
            
            
            
            
            end
        end
        
    
  end
endfunction

always @ (posedge clk_i) begin
 if (data_mode_rr_c[2:0] == 3'b101  || data_mode_rr_c[2:0] == 3'b100 || data_mode_rr_c[2:0] == 3'b110)   // WALKING ONES
     sel_w1gen_logic <= #TCQ 1'b1;
 else
     sel_w1gen_logic <= #TCQ 1'b0;
end



generate
genvar m;
 for (m=0; m < (2*nCK_PER_CLK*NUM_DQ_PINS/8) - 1; m= m+1)  
 begin: w1_gp
       assign  w1data_group[m] = ( (w1data[(m*8+7):m*8]) != 8'h00);
 end 
endgenerate   



  generate
    if ((NUM_DQ_PINS == 8 ) &&(DATA_PATTERN == "DGEN_WALKING1" || DATA_PATTERN == "DGEN_WALKING0" || DATA_PATTERN == "DGEN_ALL"))  
    begin : WALKING_ONE_8_PATTERN
     always @ (posedge clk_i) begin
       
        if( (fifo_rdy_i ) || cmd_startC )
          if (cmd_startC ) begin
             if (sel_w1gen_logic) begin
                  if (data_mode_i == 4'b0101)
                       w1data <= #TCQ Data_Gen(32'b0);
                  else
                       w1data <= #TCQ Data_GenW0(32'b0);

             end
          end
     
        else if ( MEM_BURST_LEN == 8 && fifo_rdy_i )  begin
            if ( nCK_PER_CLK == 2)
                begin
                w1data[4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS] <= #TCQ {w1data[4*NUM_DQ_PINS - 5:3*NUM_DQ_PINS  ],w1data[4*NUM_DQ_PINS - 1:4*NUM_DQ_PINS - 4]};
                w1data[3*NUM_DQ_PINS - 1:2*NUM_DQ_PINS] <= #TCQ {w1data[3*NUM_DQ_PINS - 5:2*NUM_DQ_PINS  ],w1data[3*NUM_DQ_PINS - 1:3*NUM_DQ_PINS - 4]};
                w1data[2*NUM_DQ_PINS - 1:1*NUM_DQ_PINS] <= #TCQ {w1data[2*NUM_DQ_PINS - 5:1*NUM_DQ_PINS  ],w1data[2*NUM_DQ_PINS - 1:2*NUM_DQ_PINS - 4]};
                w1data[1*NUM_DQ_PINS - 1:0*NUM_DQ_PINS] <= #TCQ {w1data[1*NUM_DQ_PINS - 5:0*NUM_DQ_PINS  ],w1data[1*NUM_DQ_PINS - 1:1*NUM_DQ_PINS - 4]};
                end
            else begin
                w1data[8*NUM_DQ_PINS - 1:7*NUM_DQ_PINS] <= #TCQ w1data[8*NUM_DQ_PINS - 1:7*NUM_DQ_PINS ];
                w1data[7*NUM_DQ_PINS - 1:6*NUM_DQ_PINS] <= #TCQ w1data[7*NUM_DQ_PINS - 1:6*NUM_DQ_PINS ];
                w1data[6*NUM_DQ_PINS - 1:5*NUM_DQ_PINS] <= #TCQ w1data[6*NUM_DQ_PINS - 1:5*NUM_DQ_PINS ];
                w1data[5*NUM_DQ_PINS - 1:4*NUM_DQ_PINS] <= #TCQ w1data[5*NUM_DQ_PINS - 1:4*NUM_DQ_PINS ];
                w1data[4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS] <= #TCQ w1data[4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS ] ;            
                w1data[3*NUM_DQ_PINS - 1:2*NUM_DQ_PINS] <= #TCQ w1data[3*NUM_DQ_PINS - 1:2*NUM_DQ_PINS ];
                 w1data[2*NUM_DQ_PINS - 1:1*NUM_DQ_PINS] <= #TCQ w1data[2*NUM_DQ_PINS - 1:1*NUM_DQ_PINS ] ;
                w1data[1*NUM_DQ_PINS - 1:0*NUM_DQ_PINS] <= #TCQ w1data[1*NUM_DQ_PINS - 1:0*NUM_DQ_PINS ];
             
                end
         end
      end
      
    end
   
  //endgenerate
  
  //generate
  else if ((NUM_DQ_PINS != 8 ) &&(DATA_PATTERN == "DGEN_WALKING1" || DATA_PATTERN == "DGEN_WALKING0" || DATA_PATTERN == "DGEN_ALL"))  
    begin : WALKING_ONE_64_PATTERN
      always @ (posedge clk_i) begin
   
       if( (fifo_rdy_i ) || cmd_startC )
          if (cmd_startC ) begin
             if (sel_w1gen_logic) begin
                  if (data_mode_i == 4'b0101)
                       w1data <= #TCQ Data_Gen(32'b0);
                  else
                       w1data <= #TCQ Data_GenW0(32'b0);

             end
          end
     
       else if ( MEM_BURST_LEN == 8 && fifo_rdy_i )  begin
         if ( nCK_PER_CLK == 2)
              begin
              w1data[4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS] <= #TCQ {w1data[4*NUM_DQ_PINS - 5:3*NUM_DQ_PINS  ],w1data[4*NUM_DQ_PINS - 1:4*NUM_DQ_PINS - 4]};
              w1data[3*NUM_DQ_PINS - 1:2*NUM_DQ_PINS] <= #TCQ {w1data[3*NUM_DQ_PINS - 5:2*NUM_DQ_PINS  ],w1data[3*NUM_DQ_PINS - 1:3*NUM_DQ_PINS - 4]};
              w1data[2*NUM_DQ_PINS - 1:1*NUM_DQ_PINS] <= #TCQ {w1data[2*NUM_DQ_PINS - 5:1*NUM_DQ_PINS  ],w1data[2*NUM_DQ_PINS - 1:2*NUM_DQ_PINS - 4]};
              w1data[1*NUM_DQ_PINS - 1:0*NUM_DQ_PINS] <= #TCQ {w1data[1*NUM_DQ_PINS - 5:0*NUM_DQ_PINS  ],w1data[1*NUM_DQ_PINS - 1:1*NUM_DQ_PINS - 4]};
              end
          else begin
              w1data[8*NUM_DQ_PINS - 1:7*NUM_DQ_PINS] <= #TCQ {w1data[8*NUM_DQ_PINS - 9:7*NUM_DQ_PINS  ],w1data[8*NUM_DQ_PINS - 1:8*NUM_DQ_PINS - 8]};
              w1data[7*NUM_DQ_PINS - 1:6*NUM_DQ_PINS] <= #TCQ {w1data[7*NUM_DQ_PINS - 9:6*NUM_DQ_PINS  ],w1data[7*NUM_DQ_PINS - 1:7*NUM_DQ_PINS - 8]};
              w1data[6*NUM_DQ_PINS - 1:5*NUM_DQ_PINS] <= #TCQ {w1data[6*NUM_DQ_PINS - 9:5*NUM_DQ_PINS  ],w1data[6*NUM_DQ_PINS - 1:6*NUM_DQ_PINS - 8]};
              w1data[5*NUM_DQ_PINS - 1:4*NUM_DQ_PINS] <= #TCQ {w1data[5*NUM_DQ_PINS - 9:4*NUM_DQ_PINS  ],w1data[5*NUM_DQ_PINS - 1:5*NUM_DQ_PINS - 8]};
        
              w1data[4*NUM_DQ_PINS - 1:3*NUM_DQ_PINS] <= #TCQ {w1data[4*NUM_DQ_PINS - 9:3*NUM_DQ_PINS  ],w1data[4*NUM_DQ_PINS - 1:4*NUM_DQ_PINS - 8]};
              w1data[3*NUM_DQ_PINS - 1:2*NUM_DQ_PINS] <= #TCQ {w1data[3*NUM_DQ_PINS - 9:2*NUM_DQ_PINS  ],w1data[3*NUM_DQ_PINS - 1:3*NUM_DQ_PINS - 8]};
              w1data[2*NUM_DQ_PINS - 1:1*NUM_DQ_PINS] <= #TCQ {w1data[2*NUM_DQ_PINS - 9:1*NUM_DQ_PINS  ],w1data[2*NUM_DQ_PINS - 1:2*NUM_DQ_PINS - 8]};
              w1data[1*NUM_DQ_PINS - 1:0*NUM_DQ_PINS] <= #TCQ {w1data[1*NUM_DQ_PINS - 9:0*NUM_DQ_PINS  ],w1data[1*NUM_DQ_PINS - 1:1*NUM_DQ_PINS - 8]};
              end
           end
      end
      
    end
   else
   begin: NO_WALKING_PATTERN
      always @ (posedge clk_i) 
         w1data <= 'b0;  
   end
  endgenerate  

// HAMMER_PATTERN_MINUS: generate walking HAMMER  data pattern except 1 bit for the whole burst. The incoming addr_i[5:2] determine 
// the position of the pin driving oppsite polarity
//  addr_i[6:2] = 5'h0f ; 32 bit data port
//                 => the rsing data pattern will be    32'b11111111_11111111_01111111_11111111
//                 => the falling data pattern will be  32'b00000000_00000000_00000000_00000000

// Only generate NUM_DQ_PINS width of hdata and will do concatenation in above level.
always @ (posedge clk_i) 
begin
  for (i= 0; i <= 2*NUM_DQ_PINS - 1; i= i+1) //begin: hammer_data

      if ( i >= NUM_DQ_PINS )
        if (SEL_VICTIM_LINE == NUM_DQ_PINS)
             hdata[i] <= 1'b0;
        else if (
             ((i == SEL_VICTIM_LINE-1) || 
              (i-NUM_DQ_PINS) == SEL_VICTIM_LINE ))//||
             
              hdata[i] <= 1'b1;
         else
              hdata[i] <= 1'b0;
         
      else 
        
              hdata[i] <= 1'b1;


end
generate
if (nCK_PER_CLK == 2)  
begin : HAMMER_2
    assign hammer_data = {2{hdata[2*NUM_DQ_PINS - 1:0]}};
end
else
begin : HAMMER_4
    assign hammer_data = {4{hdata[2*NUM_DQ_PINS - 1:0]}};
end
endgenerate


// ADDRESS_PATTERN: use the address as the 1st data pattern for the whole burst. For example
// Dataport 32 bit width with starting addr_i  = 32'h12345678,  burst length 8
//                 => the 1st data pattern :     32'h12345680
//                 => the 2nd data pattern :     32'h12345688
//                 => the 3rd data pattern :     32'h12345690
//                 => the 4th data pattern :     32'h12345698
generate

reg COut_a;
if (DATA_PATTERN == "DGEN_ADDR"  || DATA_PATTERN == "DGEN_ALL")  
begin : ADDRESS_PATTERN
  always @ (posedge clk_i)
  begin
    if (cmd_startD) 
      ///         35:0
         acounts  <= #TCQ {4'b0000,addr_i} ;  
    else if (user_burst_cnt_larger_1_r && data_rdy_i  ) begin
         if (nCK_PER_CLK == 2)
            if (FAMILY == "VIRTEX6")
                if (MEM_TYPE == "QDR2PLUS")
                   {COut_a,acounts} <= #TCQ acounts + 1;
                else
                 {COut_a,acounts} <= #TCQ acounts + 4;
                
            else  begin  // "SPARTAN6" 
               if (DWIDTH == 32)
                   {COut_a,acounts} <= #TCQ acounts + 4;
               else if (DWIDTH == 64)
                   {COut_a,acounts} <= #TCQ acounts + 8;
               else if (DWIDTH == 64)
                   {COut_a,acounts} <= #TCQ acounts + 16;
               end
         else
             {COut_a,acounts} <= #TCQ acounts + 8;
         end
    else
         acounts <= #TCQ acounts;

    end

    assign    adata_tmp = {USER_BUS_DWIDTH/32{acounts[31:0]}};

  end                   
else
begin: NO_ADDRESS_PATTERN
    assign    adata_tmp = 'b0;
end
endgenerate

 
// PRBS_PATTERN: use the address as the PRBS seed data pattern for the whole burst. For example
// Dataport 32 bit width with starting addr_i = 30'h12345678, user burst length 4
//                

always @ (posedge clk_i)
begin
  if (user_burst_cnt > 6'd1  || cmd_startE)
     user_burst_cnt_larger_1_r <= 1'b1;
  else
     user_burst_cnt_larger_1_r <= 1'b0;
end

generate
// When doing eye_test, traffic gen only does write and want to 
// keep the prbs random and address is fixed at a location.
if (EYE_TEST == "TRUE")  
begin : d_clk_en1
always @(data_clk_en)
  data_clk_en = 1'b1;//fifo_rdy_i && data_rdy_i && user_burst_cnt > 6'd1;
end 
//endgenerate

//generate
//if (EYE_TEST == "FALSE" || EYE_TEST == "READ_EYE")  
else
begin : d_clk_en2
//assign data_clk_en = fifo_rdy_i & data_rdy_i & (user_burst_cnt_larger_1_r > 6'd0);
//assign data_clk_en2 = fifo_rdy_i & data_rdy_i & (user_burst_cnt_larger_1_r > 6'd0);

always @ (fifo_rdy_i, data_rdy_i , user_burst_cnt_larger_1_r)
begin

if (fifo_rdy_i && data_rdy_i && user_burst_cnt_larger_1_r )
  data_clk_en  <= 1'b1;
else
  data_clk_en  <= 1'b0;
end

always @ (fifo_rdy_i, data_rdy_i , user_burst_cnt_larger_1_r)
begin

if (fifo_rdy_i && data_rdy_i && user_burst_cnt_larger_1_r )
  data_clk_en2  <= 1'b1;
else
  data_clk_en2  <= 1'b0;
end

end 
endgenerate

generate
if (DATA_PATTERN == "DGEN_PRBS"  || DATA_PATTERN == "DGEN_ALL")  
begin : PSUEDO_PRBS_PATTERN
       
//   PRBS DATA GENERATION
// xor all the tap positions before feedback to 1st stage.
   always @ (posedge clk_i)
      m_addr_r <= m_addr_i;


   data_prbs_gen #
  (
    .PRBS_WIDTH (32),  
    .SEED_WIDTH (32),
    .EYE_TEST   (EYE_TEST)
   )
   data_prbs_gen
  (
   .clk_i            (clk_i),
   .rst_i            (rst_i),
   .clk_en           (data_clk_en),
   
   .prbs_seed_init   (cmd_startE),
   .prbs_seed_i      (m_addr_i[31:0]),
   .prbs_o           (mcb_prbs_data)

  );   
end  
else
begin:NO_PSUEDO_PRBS_PATTERN
   assign mcb_prbs_data = 'b0;
end
endgenerate 


wire [31:0] ReSeedcounter_o;

assign prbs_seed = START_ADDR[BL_WIDTH+1:2];//addr_i[13:2];

always @ (posedge clk_i)
begin
if (rst_i)
    prbs_seeded <= 1'b0;
else if (cmd_startE)
   if  ( data_mode_i == 4'b0111)
    prbs_seeded <= 1'b1;
   else
    prbs_seeded <= 1'b0;
   
end    




//localparam TAPS_VALUE = 12'b100000101001;//10'b1001000000;  256
//localparam TAPS_VALUE = 10'b1000000100;//10'b1001000000;  64

//localparam TAPS_VALUE = 9'b100001000;//9'b1001000000;  64
//localparam TAPS_VALUE = 8'b10001110;//10'b1001000000;  repeated in 16 cmd writes
  assign prbs_shift_value0  = prbs_shift_value[3:0];
  assign prbs_shift_value1  = prbs_shift_value[7:4];
  assign prbs_shift_value2  = prbs_shift_value[11:8];
  assign prbs_shift_value3  = prbs_shift_value[15:12];
  
  assign prbs_shift_value4  = prbs_shift_value[19:16];
  assign prbs_shift_value5  = prbs_shift_value[23:20];
  assign prbs_shift_value6  = prbs_shift_value[27:24];
  assign prbs_shift_value7  = prbs_shift_value[31:28];
  
  assign prbs_shift_value8  = prbs_shift_value[35:32];
  assign prbs_shift_value9  = prbs_shift_value[39:36];
  assign prbs_shift_value10 = prbs_shift_value[43:40];
  assign prbs_shift_value11 = prbs_shift_value[47:44];
  
  assign prbs_shift_value12 = prbs_shift_value[51:48];
  assign prbs_shift_value13 = prbs_shift_value[55:52];
  assign prbs_shift_value14 = prbs_shift_value[59:56];
  assign prbs_shift_value15 = prbs_shift_value[63:60];
  
  generate 
  if (nCK_PER_CLK == 4 )  
  begin 
    assign prbs_shift_value16 = prbs_shift_value[67:64];
    assign prbs_shift_value17 = prbs_shift_value[71:68];
    assign prbs_shift_value18 = prbs_shift_value[75:72];
    assign prbs_shift_value19 = prbs_shift_value[79:76];
    
    assign prbs_shift_value20 = prbs_shift_value[83:80];
    assign prbs_shift_value21 = prbs_shift_value[87:84];
    assign prbs_shift_value22 = prbs_shift_value[91:88];
    assign prbs_shift_value23 = prbs_shift_value[95:92];
    
    assign prbs_shift_value24 = prbs_shift_value[99:96];
    assign prbs_shift_value25 = prbs_shift_value[103:100];
    assign prbs_shift_value26 = prbs_shift_value[107:104];
    assign prbs_shift_value27 = prbs_shift_value[111:108];
    
    assign prbs_shift_value28 = prbs_shift_value[115:112];
    assign prbs_shift_value29 = prbs_shift_value[119:116];
    assign prbs_shift_value30 = prbs_shift_value[123:120];
    assign prbs_shift_value31 = prbs_shift_value[127:124];
  
  end
  else
  begin
    assign prbs_shift_value16 = 'b0;
    assign prbs_shift_value17 = 'b0; 
    assign prbs_shift_value18 = 'b0; 
    assign prbs_shift_value19 = 'b0; 
  
    assign prbs_shift_value20 = 'b0; 
    assign prbs_shift_value21 = 'b0; 
    assign prbs_shift_value22 = 'b0; 
    assign prbs_shift_value23 = 'b0; 
  
    assign prbs_shift_value24 = 'b0; 
    assign prbs_shift_value25 = 'b0; 
    assign prbs_shift_value26 = 'b0; 
    assign prbs_shift_value27 = 'b0; 
  
    assign prbs_shift_value28 = 'b0; 
    assign prbs_shift_value29 = 'b0; 
    assign prbs_shift_value30 = 'b0; 
    assign prbs_shift_value31 = 'b0; 
    
  end
   endgenerate
  
genvar l;
generate
for (l = 0; l < nCK_PER_CLK*8; l = l + 1) 
begin: prbs_modules
 tg_prbs_gen #
   (
    .PRBS_WIDTH    (PRBS_WIDTH),  
    .START_ADDR    (START_ADDR),
    .PRBS_OFFSET   (l*4),
    .TAPS          (TAPS_VALUE)

   )
   u_data_prbs_gen
  (
   .clk_i            (clk_i),
   .rst              (rst_i),
   .clk_en           (data_clk_en),
//   .prbs_seed_init   (prbs_seed_init),
   .prbs_seed_i      (prbs_seed[PRBS_WIDTH-1:0]),//(m_addr_i[31:0]),
   .initialize_done  (),
   .prbs_shift_value (prbs_shift_value[(l+1)*4-1:(l)*4]),

   // ADDED, richc 020810: declare ports to avoid warnings
   .prbs_o          (),
   .ReSeedcounter_o (ReSeedcounter[(l+1)*32-1:(l)*32])
  );   
 


end endgenerate

  
// need a mux circuit to mux out prbs_ox to full_prbs bus.
always @ (posedge clk_i)
begin
if (rst_i)
  prbs_mux_counter <= 'b0;
else if (data_clk_en )
  prbs_mux_counter <= prbs_mux_counter + 1'b1;
end

always @ (posedge clk_i)
begin
if (rst_i)
    mode_has_loaded <= 1'b0;
else if  ( mode_load_r2  )
    mode_has_loaded <= 1'b1;

end


// assert force_load whenever prbs generator has cycle through.
always @ (posedge clk_i)
begin
   data_clk_en2_r <= data_clk_en2;
   if (ReSeedcounter[31:0] == 0 && data_clk_en2_r && ~data_clk_en2)  
         force_load <= 1'b1;
   else 
         force_load <= 1'b0;
end   

always @ (posedge clk_i)
begin
if (rst_i)
         prbs_comb_data_load <= 1'b0;

else if (prbs_mux_counter == 63 //&& DMODE == "WRITE"  ||
      )  
         prbs_comb_data_load <= 1'b1;
else if (data_clk_en2)
         prbs_comb_data_load <= 1'b0;
end   


// 16 PRBS generators are running in parallel. Each one is four cycles earlier to its next one.
// 
always @ (posedge clk_i) 
begin
if ((mode_load_i & ~mode_has_loaded )|| (prbs_comb_data_load && data_clk_en2 && ReSeedcounter[5:0] == 0) || force_load)

    prbs_comb_data <= {
                       prbs_shift_value31,prbs_shift_value30,prbs_shift_value29,prbs_shift_value28,
                       prbs_shift_value27,prbs_shift_value26,prbs_shift_value25,prbs_shift_value24,
                       prbs_shift_value23 ,prbs_shift_value22,prbs_shift_value21,prbs_shift_value20,
                       prbs_shift_value19 ,prbs_shift_value18,prbs_shift_value17,prbs_shift_value16,
    
                       prbs_shift_value15,prbs_shift_value14,prbs_shift_value13,prbs_shift_value12,
                       prbs_shift_value11,prbs_shift_value10,prbs_shift_value9,prbs_shift_value8,
                       prbs_shift_value7 ,prbs_shift_value6,prbs_shift_value5,prbs_shift_value4,
                       prbs_shift_value3 ,prbs_shift_value2,prbs_shift_value1,prbs_shift_value0
                  };
                  
 end 



always @ (posedge clk_i) 
begin

   mode_load_r1 <= mode_load_i;
   mode_load_r2 <= mode_load_r1;
end   


always @ (posedge clk_i) 
begin
    if ((mode_load_r1 && ~mode_has_loaded) || (ReSeedcounter[31:0] == 0 && ~data_clk_en2 && nCK_PER_CLK == 4) ||
        (ReSeedcounter[31:0] == 0 && nCK_PER_CLK == 2 && data_clk_en2))  
        // needed to preload the previous value in READ mode.
       if (nCK_PER_CLK == 4)
        
            prbs_mux_data <=  #TCQ {prbs_shift_value1,prbs_shift_value0};
       else

            prbs_mux_data[3:0] <=  #TCQ {prbs_shift_value0};

    else if (data_clk_en2 ) 
      begin
        case (prbs_mux_counter[3:0])
                                            //           8
        0 :  if (ReSeedcounter[31:0] == 0)
                    if (nCK_PER_CLK == 4)
                        prbs_mux_data <=  #TCQ {prbs_shift_value1,prbs_shift_value0};
                    else
                        prbs_mux_data[3:0] <=  #TCQ {prbs_shift_value0};

             else
                    prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*1 - 1:nCK_PER_CLK*2*0];               
        1 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*2 - 1:nCK_PER_CLK*2*1 ];
        2 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*3 - 1:nCK_PER_CLK*2*2 ];//[23:16];
        3 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*4 - 1:nCK_PER_CLK*2*3 ];//[31:24];
        4 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*5 - 1:nCK_PER_CLK*2*4 ];//[39:32];
        5 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*6 - 1:nCK_PER_CLK*2*5 ];//[47:40];
        6 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*7 - 1:nCK_PER_CLK*2*6 ];//[55:48];
        7 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*8 - 1:nCK_PER_CLK*2*7 ];//[63:56];
        8 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*9 - 1:nCK_PER_CLK*2*8 ];//[71:64];
        9 :  prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2*10 - 1:nCK_PER_CLK*2*9 ];//[79:72];
        10: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*11 - 1:nCK_PER_CLK*2*10];//[87:80];
        11: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*12 - 1:nCK_PER_CLK*2*11];//[95:88];
        12: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*13 - 1:nCK_PER_CLK*2*12];//[103:96];
        13: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*14 - 1:nCK_PER_CLK*2*13];//[111:104];
        14: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*15 - 1:nCK_PER_CLK*2*14];//[119:112];
        15: prbs_mux_data <= #TCQ  prbs_comb_data[nCK_PER_CLK*2*16 - 1:nCK_PER_CLK*2*15];//[127:120];
         default: prbs_mux_data <= #TCQ prbs_comb_data[nCK_PER_CLK*2 - 1:nCK_PER_CLK*2*0 ];//[7:0];
        endcase
    end
        
        
end    

                  
assign prbsdata_rising_0  = {NUM_DQ_PINS{prbs_mux_data[3]}};
assign prbsdata_falling_0 = {NUM_DQ_PINS{prbs_mux_data[2]}};
assign prbsdata_rising_1  = {NUM_DQ_PINS{prbs_mux_data[1]}};
assign prbsdata_falling_1 = {NUM_DQ_PINS{prbs_mux_data[0]}};

assign prbsdata_rising_2  = {NUM_DQ_PINS{prbs_mux_data[7]}};
assign prbsdata_falling_2 = {NUM_DQ_PINS{prbs_mux_data[6]}};
assign prbsdata_rising_3  = {NUM_DQ_PINS{prbs_mux_data[5]}};
assign prbsdata_falling_3 = {NUM_DQ_PINS{prbs_mux_data[4]}};

endmodule 

