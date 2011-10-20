// SMAdapter.v - Stream/Message Adapter with parmeterization
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

module SMAdapter # ( 
  parameter integer                      WMI_M0_DATAPATH_WIDTH  = 32,
  parameter integer                      WSI_S0_DATAPATH_WIDTH  = 32,
  parameter integer                      WSI_M0_DATAPATH_WIDTH  = 32,
  parameter integer                      WORKER_CTRL_INIT       = 1,
  parameter integer                      HAS_DEBUG_LOGIC        = 1 )
(
  input                                  wciS0_Clk,
  input		                               wciS0_MReset_n,

  input  [ 2:0]                          wciS0_MCmd,
  input                                  wciS0_MAddrSpace,
  input  [ 3:0]                          wciS0_MByteEn,
  input  [31:0]                  		     wciS0_MAddr,
  input  [31:0]                          wciS0_MData,
  output [ 1:0]                          wciS0_SResp,
  output [31:0]                          wciS0_SData,
  output                                 wciS0_SThreadBusy,
  output [ 1:0]                          wciS0_SFlag,
  input  [ 1:0]                          wciS0_MFlag,

  output [ 2:0]                          wmiM0_MCmd,
  output                                 wmiM0_MReqLast,
  output                                 wmiM0_MReqInfo,
  output                                 wmiM0_MAddrSpace,
  output [13:0]                          wmiM0_MAddr,
  output [11:0]                          wmiM0_MBurstLength,
  output                                 wmiM0_MDataValid,
  output                                 wmiM0_MDataLast,
  output [WMI_M0_DATAPATH_WIDTH-1  :0]   wmiM0_MData,
  output [WMI_M0_DATAPATH_WIDTH/4-1:0]   wmiM0_MDataByteEn,
  input  [1:0]                           wmiM0_SResp,
  input  [WMI_M0_DATAPATH_WIDTH-1  :0]   wmiM0_SData,
  input                                  wmiM0_SThreadBusy,
  input                                  wmiM0_SDataThreadBusy,
  input                                  wmiM0_SRespLast,
  input  [31:0]                          wmiM0_SFlag,
  output [31:0]                          wmiM0_MFlag,
  output                                 wmiM0_MReset_n,
  input                                  wmiM0_SReset_n,
  
  output [ 2:0]                          wsiM0_MCmd,
  output                                 wsiM0_MReqLast,
  output                                 wsiM0_MBurstPrecise,
  output [11:0]                          wsiM0_MBurstLength,
  output [WSI_M0_DATAPATH_WIDTH-1  :0]   wsiM0_MData,
  output [WSI_M0_DATAPATH_WIDTH/4-1:0]   wsiM0_MByteEn,
  output [ 7:0]                          wsiM0_MReqInfo,
  input                                  wsiM0_SThreadBusy,
  output                                 wsiM0_MReset_n,
  input                                  wsiM0_SReset_n,

  input  [ 2:0]                          wsiS0_MCmd,
  input                                  wsiS0_MReqLast,
  input                                  wsiS0_MBurstPrecise,
  input  [11:0]                          wsiS0_MBurstLength,
  input  [WSI_S0_DATAPATH_WIDTH-1  :0]   wsiS0_MData,
  input  [WSI_S0_DATAPATH_WIDTH/4-1:0]   wsiS0_MByteEn,
  input  [ 7:0]                          wsiS0_MReqInfo,
  output                                 wsiS0_SThreadBusy,
  output                                 wsiS0_SReset_n,
  input                                  wsiS0_MReset_n
);

// Compile time check for expected parameters...
initial begin
  if ( (WMI_M0_DATAPATH_WIDTH != 32) && (WMI_M0_DATAPATH_WIDTH != 64) && (WMI_M0_DATAPATH_WIDTH != 128) && (WMI_M0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WMI_M0_DATAPATH width"); $finish; end
  if ( (WSI_M0_DATAPATH_WIDTH != 32) && (WSI_M0_DATAPATH_WIDTH != 64) && (WSI_M0_DATAPATH_WIDTH != 128) && (WSI_M0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WSI_M0_DATAPATH width"); $finish; end
  if ( (WSI_S0_DATAPATH_WIDTH != 32) && (WSI_S0_DATAPATH_WIDTH != 64) && (WSI_S0_DATAPATH_WIDTH != 128) && (WSI_S0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WSI_S0_DATAPATH width"); $finish; end
  if ( (WMI_M0_DATAPATH_WIDTH != WSI_M0_DATAPATH_WIDTH ) || (WSI_M0_DATAPATH_WIDTH != WSI_S0_DATAPATH_WIDTH) ) begin
    $display("Width Mismatch, WMI_M0_ WSI_M0 WSI_S0_ DATAPATH widths must match"); $finish; end
end

// Instance the correct variant...

generate
  //genvar byteWidth;
  //byteWidth = WMI_M0_DATAPATH_WIDTH/8;

  case (WMI_M0_DATAPATH_WIDTH/8)
    4:
      mkSMAdapter4B #(
      .smaCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      SMAdapter4B_i (
      .wciS0_Clk             (wciS0_Clk),
      .wciS0_MReset_n        (wciS0_MReset_n),
      .wciS0_MAddr           (wciS0_MAddr),
      .wciS0_MAddrSpace      (wciS0_MAddrSpace),
      .wciS0_MByteEn         (wciS0_MByteEn),
      .wciS0_MCmd            (wciS0_MCmd),
      .wciS0_MData           (wciS0_MData),
      .wciS0_MFlag           (wciS0_MFlag),
      .wciS0_SResp           (wciS0_SResp),
      .wciS0_SData           (wciS0_SData),
      .wciS0_SThreadBusy     (wciS0_SThreadBusy),
      .wciS0_SFlag           (wciS0_SFlag),
      .wmiM0_SData           (wmiM0_SData),
      .wmiM0_SFlag           (wmiM0_SFlag),
      .wmiM0_SResp           (wmiM0_SResp),
      .wmiM0_SThreadBusy     (wmiM0_SThreadBusy),
      .wmiM0_SDataThreadBusy (wmiM0_SDataThreadBusy),
      .wmiM0_SRespLast       (wmiM0_SRespLast),
      .wmiM0_SReset_n        (wmiM0_SReset_n),
      .wmiM0_MCmd            (wmiM0_MCmd),
      .wmiM0_MReqLast        (wmiM0_MReqLast),
      .wmiM0_MReqInfo        (wmiM0_MReqInfo),
      .wmiM0_MAddrSpace      (wmiM0_MAddrSpace),
      .wmiM0_MAddr           (wmiM0_MAddr),
      .wmiM0_MBurstLength    (wmiM0_MBurstLength),
      .wmiM0_MDataValid      (wmiM0_MDataValid),
      .wmiM0_MDataLast       (wmiM0_MDataLast),
      .wmiM0_MData           (wmiM0_MData),
      .wmiM0_MDataByteEn     (wmiM0_MDataByteEn),
      .wmiM0_MFlag           (wmiM0_MFlag),
      .wmiM0_MReset_n        (wmiM0_MReset_n),
      .wsiS0_MBurstLength    (wsiS0_MBurstLength),
      .wsiS0_MByteEn         (wsiS0_MByteEn),
      .wsiS0_MCmd            (wsiS0_MCmd),
      .wsiS0_MData           (wsiS0_MData),
      .wsiS0_MReqInfo        (wsiS0_MReqInfo),
      .wsiS0_MReqLast        (wsiS0_MReqLast),
      .wsiS0_MBurstPrecise   (wsiS0_MBurstPrecise),
      .wsiS0_MReset_n        (wsiS0_MReset_n),
      .wsiS0_SThreadBusy     (wsiS0_SThreadBusy),
      .wsiS0_SReset_n        (wsiS0_SReset_n),
      .wsiM0_SThreadBusy     (wsiM0_SThreadBusy),
      .wsiM0_SReset_n        (wsiM0_SReset_n),
      .wsiM0_MCmd            (wsiM0_MCmd),
      .wsiM0_MReqLast        (wsiM0_MReqLast),
      .wsiM0_MBurstPrecise   (wsiM0_MBurstPrecise),
      .wsiM0_MBurstLength    (wsiM0_MBurstLength),
      .wsiM0_MData           (wsiM0_MData),
      .wsiM0_MByteEn         (wsiM0_MByteEn),
      .wsiM0_MReqInfo        (wsiM0_MReqInfo),
      .wsiM0_MReset_n        (wsiM0_MReset_n)
      );
      
    8:
      mkSMAdapter8B #(
      .smaCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      SMAdapter8B_i (
      .wciS0_Clk             (wciS0_Clk),
      .wciS0_MReset_n        (wciS0_MReset_n),
      .wciS0_MAddr           (wciS0_MAddr),
      .wciS0_MAddrSpace      (wciS0_MAddrSpace),
      .wciS0_MByteEn         (wciS0_MByteEn),
      .wciS0_MCmd            (wciS0_MCmd),
      .wciS0_MData           (wciS0_MData),
      .wciS0_MFlag           (wciS0_MFlag),
      .wciS0_SResp           (wciS0_SResp),
      .wciS0_SData           (wciS0_SData),
      .wciS0_SThreadBusy     (wciS0_SThreadBusy),
      .wciS0_SFlag           (wciS0_SFlag),
      .wmiM0_SData           (wmiM0_SData),
      .wmiM0_SFlag           (wmiM0_SFlag),
      .wmiM0_SResp           (wmiM0_SResp),
      .wmiM0_SThreadBusy     (wmiM0_SThreadBusy),
      .wmiM0_SDataThreadBusy (wmiM0_SDataThreadBusy),
      .wmiM0_SRespLast       (wmiM0_SRespLast),
      .wmiM0_SReset_n        (wmiM0_SReset_n),
      .wmiM0_MCmd            (wmiM0_MCmd),
      .wmiM0_MReqLast        (wmiM0_MReqLast),
      .wmiM0_MReqInfo        (wmiM0_MReqInfo),
      .wmiM0_MAddrSpace      (wmiM0_MAddrSpace),
      .wmiM0_MAddr           (wmiM0_MAddr),
      .wmiM0_MBurstLength    (wmiM0_MBurstLength),
      .wmiM0_MDataValid      (wmiM0_MDataValid),
      .wmiM0_MDataLast       (wmiM0_MDataLast),
      .wmiM0_MData           (wmiM0_MData),
      .wmiM0_MDataByteEn     (wmiM0_MDataByteEn),
      .wmiM0_MFlag           (wmiM0_MFlag),
      .wmiM0_MReset_n        (wmiM0_MReset_n),
      .wsiS0_MBurstLength    (wsiS0_MBurstLength),
      .wsiS0_MByteEn         (wsiS0_MByteEn),
      .wsiS0_MCmd            (wsiS0_MCmd),
      .wsiS0_MData           (wsiS0_MData),
      .wsiS0_MReqInfo        (wsiS0_MReqInfo),
      .wsiS0_MReqLast        (wsiS0_MReqLast),
      .wsiS0_MBurstPrecise   (wsiS0_MBurstPrecise),
      .wsiS0_MReset_n        (wsiS0_MReset_n),
      .wsiS0_SThreadBusy     (wsiS0_SThreadBusy),
      .wsiS0_SReset_n        (wsiS0_SReset_n),
      .wsiM0_SThreadBusy     (wsiM0_SThreadBusy),
      .wsiM0_SReset_n        (wsiM0_SReset_n),
      .wsiM0_MCmd            (wsiM0_MCmd),
      .wsiM0_MReqLast        (wsiM0_MReqLast),
      .wsiM0_MBurstPrecise   (wsiM0_MBurstPrecise),
      .wsiM0_MBurstLength    (wsiM0_MBurstLength),
      .wsiM0_MData           (wsiM0_MData),
      .wsiM0_MByteEn         (wsiM0_MByteEn),
      .wsiM0_MReqInfo        (wsiM0_MReqInfo),
      .wsiM0_MReset_n        (wsiM0_MReset_n)
      );
      
    16:
      mkSMAdapter16B #(
      .smaCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      SMAdapter16B_i (
      .wciS0_Clk             (wciS0_Clk),
      .wciS0_MReset_n        (wciS0_MReset_n),
      .wciS0_MAddr           (wciS0_MAddr),
      .wciS0_MAddrSpace      (wciS0_MAddrSpace),
      .wciS0_MByteEn         (wciS0_MByteEn),
      .wciS0_MCmd            (wciS0_MCmd),
      .wciS0_MData           (wciS0_MData),
      .wciS0_MFlag           (wciS0_MFlag),
      .wciS0_SResp           (wciS0_SResp),
      .wciS0_SData           (wciS0_SData),
      .wciS0_SThreadBusy     (wciS0_SThreadBusy),
      .wciS0_SFlag           (wciS0_SFlag),
      .wmiM0_SData           (wmiM0_SData),
      .wmiM0_SFlag           (wmiM0_SFlag),
      .wmiM0_SResp           (wmiM0_SResp),
      .wmiM0_SThreadBusy     (wmiM0_SThreadBusy),
      .wmiM0_SDataThreadBusy (wmiM0_SDataThreadBusy),
      .wmiM0_SRespLast       (wmiM0_SRespLast),
      .wmiM0_SReset_n        (wmiM0_SReset_n),
      .wmiM0_MCmd            (wmiM0_MCmd),
      .wmiM0_MReqLast        (wmiM0_MReqLast),
      .wmiM0_MReqInfo        (wmiM0_MReqInfo),
      .wmiM0_MAddrSpace      (wmiM0_MAddrSpace),
      .wmiM0_MAddr           (wmiM0_MAddr),
      .wmiM0_MBurstLength    (wmiM0_MBurstLength),
      .wmiM0_MDataValid      (wmiM0_MDataValid),
      .wmiM0_MDataLast       (wmiM0_MDataLast),
      .wmiM0_MData           (wmiM0_MData),
      .wmiM0_MDataByteEn     (wmiM0_MDataByteEn),
      .wmiM0_MFlag           (wmiM0_MFlag),
      .wmiM0_MReset_n        (wmiM0_MReset_n),
      .wsiS0_MBurstLength    (wsiS0_MBurstLength),
      .wsiS0_MByteEn         (wsiS0_MByteEn),
      .wsiS0_MCmd            (wsiS0_MCmd),
      .wsiS0_MData           (wsiS0_MData),
      .wsiS0_MReqInfo        (wsiS0_MReqInfo),
      .wsiS0_MReqLast        (wsiS0_MReqLast),
      .wsiS0_MBurstPrecise   (wsiS0_MBurstPrecise),
      .wsiS0_MReset_n        (wsiS0_MReset_n),
      .wsiS0_SThreadBusy     (wsiS0_SThreadBusy),
      .wsiS0_SReset_n        (wsiS0_SReset_n),
      .wsiM0_SThreadBusy     (wsiM0_SThreadBusy),
      .wsiM0_SReset_n        (wsiM0_SReset_n),
      .wsiM0_MCmd            (wsiM0_MCmd),
      .wsiM0_MReqLast        (wsiM0_MReqLast),
      .wsiM0_MBurstPrecise   (wsiM0_MBurstPrecise),
      .wsiM0_MBurstLength    (wsiM0_MBurstLength),
      .wsiM0_MData           (wsiM0_MData),
      .wsiM0_MByteEn         (wsiM0_MByteEn),
      .wsiM0_MReqInfo        (wsiM0_MReqInfo),
      .wsiM0_MReset_n        (wsiM0_MReset_n)
      );
      
    32:
      mkSMAdapter32B #(
      .smaCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      SMAdapter32B_i (
      .wciS0_Clk             (wciS0_Clk),
      .wciS0_MReset_n        (wciS0_MReset_n),
      .wciS0_MAddr           (wciS0_MAddr),
      .wciS0_MAddrSpace      (wciS0_MAddrSpace),
      .wciS0_MByteEn         (wciS0_MByteEn),
      .wciS0_MCmd            (wciS0_MCmd),
      .wciS0_MData           (wciS0_MData),
      .wciS0_MFlag           (wciS0_MFlag),
      .wciS0_SResp           (wciS0_SResp),
      .wciS0_SData           (wciS0_SData),
      .wciS0_SThreadBusy     (wciS0_SThreadBusy),
      .wciS0_SFlag           (wciS0_SFlag),
      .wmiM0_SData           (wmiM0_SData),
      .wmiM0_SFlag           (wmiM0_SFlag),
      .wmiM0_SResp           (wmiM0_SResp),
      .wmiM0_SThreadBusy     (wmiM0_SThreadBusy),
      .wmiM0_SDataThreadBusy (wmiM0_SDataThreadBusy),
      .wmiM0_SRespLast       (wmiM0_SRespLast),
      .wmiM0_SReset_n        (wmiM0_SReset_n),
      .wmiM0_MCmd            (wmiM0_MCmd),
      .wmiM0_MReqLast        (wmiM0_MReqLast),
      .wmiM0_MReqInfo        (wmiM0_MReqInfo),
      .wmiM0_MAddrSpace      (wmiM0_MAddrSpace),
      .wmiM0_MAddr           (wmiM0_MAddr),
      .wmiM0_MBurstLength    (wmiM0_MBurstLength),
      .wmiM0_MDataValid      (wmiM0_MDataValid),
      .wmiM0_MDataLast       (wmiM0_MDataLast),
      .wmiM0_MData           (wmiM0_MData),
      .wmiM0_MDataByteEn     (wmiM0_MDataByteEn),
      .wmiM0_MFlag           (wmiM0_MFlag),
      .wmiM0_MReset_n        (wmiM0_MReset_n),
      .wsiS0_MBurstLength    (wsiS0_MBurstLength),
      .wsiS0_MByteEn         (wsiS0_MByteEn),
      .wsiS0_MCmd            (wsiS0_MCmd),
      .wsiS0_MData           (wsiS0_MData),
      .wsiS0_MReqInfo        (wsiS0_MReqInfo),
      .wsiS0_MReqLast        (wsiS0_MReqLast),
      .wsiS0_MBurstPrecise   (wsiS0_MBurstPrecise),
      .wsiS0_MReset_n        (wsiS0_MReset_n),
      .wsiS0_SThreadBusy     (wsiS0_SThreadBusy),
      .wsiS0_SReset_n        (wsiS0_SReset_n),
      .wsiM0_SThreadBusy     (wsiM0_SThreadBusy),
      .wsiM0_SReset_n        (wsiM0_SReset_n),
      .wsiM0_MCmd            (wsiM0_MCmd),
      .wsiM0_MReqLast        (wsiM0_MReqLast),
      .wsiM0_MBurstPrecise   (wsiM0_MBurstPrecise),
      .wsiM0_MBurstLength    (wsiM0_MBurstLength),
      .wsiM0_MData           (wsiM0_MData),
      .wsiM0_MByteEn         (wsiM0_MByteEn),
      .wsiM0_MReqInfo        (wsiM0_MReqInfo),
      .wsiM0_MReset_n        (wsiM0_MReset_n)
      );
      
    //default: begin $display("Illegal case arm"); $finish; end
  endcase
endgenerate

      
endmodule
