// DelayWorker.v - DelayWorker with parmeterization
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

module BiasWorker # ( 
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
  input                                  wsiS0_MReset_n,

  output [  2:0]                         wmemiM0_MCmd,
  output                                 wmemiM0_MReqLast,
  output [ 35:0]                         wmemiM0_MAddr,
  output [ 11:0]                         wmemiM0_MBurstLength,
  output                                 wmemiM0_MDataValid,
  output                                 wmemiM0_MDataLast,
  output [127:0]                         wmemiM0_MData,
  output [ 15:0]                         wmemiM0_MDataByteEn,
  input  [  1:0]                         wmemiM0_SResp,
  input                                  wmemiM0_SRespLast,
  input  [127:0]                         wmemiM0_SData,
  input                                  wmemiM0_SCmdAccept,
  input                                  wmemiM0_SDataAccept,
  output                                 wmemiM0_MReset_n
);

// Compile time check for expected parameters...
initial begin
  if ( (WSI_M0_DATAPATH_WIDTH != 32) && (WSI_M0_DATAPATH_WIDTH != 64) && (WSI_M0_DATAPATH_WIDTH != 128) && (WSI_M0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WSI_M0_DATAPATH width"); $finish; end
  if ( (WSI_S0_DATAPATH_WIDTH != 32) && (WSI_S0_DATAPATH_WIDTH != 64) && (WSI_S0_DATAPATH_WIDTH != 128) && (WSI_S0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WSI_S0_DATAPATH width"); $finish; end
  if ( WSI_M0_DATAPATH_WIDTH != WSI_S0_DATAPATH_WIDTH ) begin
    $display("Width Mismatch, WSI_M0 WSI_S0_ DATAPATH widths must match"); $finish; end
end

// Instance the correct variant...

generate
  //genvar byteWidth;
  //byteWidth = WMI_M0_DATAPATH_WIDTH/8;

  case (WMI_M0_DATAPATH_WIDTH/8)
    4:
      mkDelayWorker4B #(
      .dlyCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      DelayWorker4B_i (
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
      .wsiM0_MReset_n        (wsiM0_MReset_n),
      .wmemiM0_MCmd          (wmemiM0_MCmd),
      .wmemiM0_MReqLast      (wmemiM0_MReqLast),
      .wmemiM0_MAddr         (wmemiM0_MAddr),
      .wmemiM0_MBurstLength  (wmemiM0_MBurstLength),
      .wmemiM0_MDataValid    (wmemiM0_MDataValid),
      .wmemiM0_MDataLast     (wmemiM0_MDataLast),
      .wmemiM0_MData         (wmemiM0_MData),
      .wmemiM0_MDataByteEn   (wmemiM0_MDataByteEn),
      .wmemiM0_SResp         (wmemiM0_SResp),
      .wmemiM0_SRespLast     (wmemiM0_SRespLast),
      .wmemiM0_SData         (wmemiM0_SData),
      .wmemiM0_SCmdAccept    (wmemiM0_SCmdAccept),
      .wmemiM0_SDataAccept   (wmemiM0_SDataAccept),
      .wmemiM0_MReset_n      (wmemiM0_MReset_n)
      );
      
    8:
      mkDelayWorker8B #(
      .dlyCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      DelayWorker8B_i (
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
      .wsiM0_MReset_n        (wsiM0_MReset_n),
      .wmemiM0_MCmd          (wmemiM0_MCmd),
      .wmemiM0_MReqLast      (wmemiM0_MReqLast),
      .wmemiM0_MAddr         (wmemiM0_MAddr),
      .wmemiM0_MBurstLength  (wmemiM0_MBurstLength),
      .wmemiM0_MDataValid    (wmemiM0_MDataValid),
      .wmemiM0_MDataLast     (wmemiM0_MDataLast),
      .wmemiM0_MData         (wmemiM0_MData),
      .wmemiM0_MDataByteEn   (wmemiM0_MDataByteEn),
      .wmemiM0_SResp         (wmemiM0_SResp),
      .wmemiM0_SRespLast     (wmemiM0_SRespLast),
      .wmemiM0_SData         (wmemiM0_SData),
      .wmemiM0_SCmdAccept    (wmemiM0_SCmdAccept),
      .wmemiM0_SDataAccept   (wmemiM0_SDataAccept),
      .wmemiM0_MReset_n      (wmemiM0_MReset_n)
      );
      
    16:
      mkDelayWorker16B #(
      .dlyCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      DelayWorker16B_i (
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
      .wsiM0_MReset_n        (wsiM0_MReset_n),
      .wmemiM0_MCmd          (wmemiM0_MCmd),
      .wmemiM0_MReqLast      (wmemiM0_MReqLast),
      .wmemiM0_MAddr         (wmemiM0_MAddr),
      .wmemiM0_MBurstLength  (wmemiM0_MBurstLength),
      .wmemiM0_MDataValid    (wmemiM0_MDataValid),
      .wmemiM0_MDataLast     (wmemiM0_MDataLast),
      .wmemiM0_MData         (wmemiM0_MData),
      .wmemiM0_MDataByteEn   (wmemiM0_MDataByteEn),
      .wmemiM0_SResp         (wmemiM0_SResp),
      .wmemiM0_SRespLast     (wmemiM0_SRespLast),
      .wmemiM0_SData         (wmemiM0_SData),
      .wmemiM0_SCmdAccept    (wmemiM0_SCmdAccept),
      .wmemiM0_SDataAccept   (wmemiM0_SDataAccept),
      .wmemiM0_MReset_n      (wmemiM0_MReset_n)
      );
      
    32:
      mkDelayWorker32B #(
      .dlyCtrlInit   (WORKER_CTRL_INIT),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      DelayWorker32B_i (
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
      .wsiM0_MReset_n        (wsiM0_MReset_n),
      .wmemiM0_MCmd          (wmemiM0_MCmd),
      .wmemiM0_MReqLast      (wmemiM0_MReqLast),
      .wmemiM0_MAddr         (wmemiM0_MAddr),
      .wmemiM0_MBurstLength  (wmemiM0_MBurstLength),
      .wmemiM0_MDataValid    (wmemiM0_MDataValid),
      .wmemiM0_MDataLast     (wmemiM0_MDataLast),
      .wmemiM0_MData         (wmemiM0_MData),
      .wmemiM0_MDataByteEn   (wmemiM0_MDataByteEn),
      .wmemiM0_SResp         (wmemiM0_SResp),
      .wmemiM0_SRespLast     (wmemiM0_SRespLast),
      .wmemiM0_SData         (wmemiM0_SData),
      .wmemiM0_SCmdAccept    (wmemiM0_SCmdAccept),
      .wmemiM0_SDataAccept   (wmemiM0_SDataAccept),
      .wmemiM0_MReset_n      (wmemiM0_MReset_n)
      );
      
    //default: begin $display("Illegal case arm"); $finish; end
  endcase
endgenerate

      
endmodule
