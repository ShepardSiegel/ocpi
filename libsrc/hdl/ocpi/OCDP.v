// OCDP.v - OpenCPI Data Plane with parmeterization
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

module OCDP # ( 
  parameter integer                      WMI_S0_DATAPATH_WIDTH  = 32,
  parameter integer                      HAS_PUSH_LOGIC         = 1,
  parameter integer                      HAS_PULL_LOGIC         = 1,
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

  input  [ 2:0]                          wmiS0_MCmd,
  input                                  wmiS0_MReqLast,
  input                                  wmiS0_MReqInfo,
  input                                  wmiS0_MAddrSpace,
  input  [13:0]                          wmiS0_MAddr,
  input  [11:0]                          wmiS0_MBurstLength,
  input                                  wmiS0_MDataValid,
  input                                  wmiS0_MDataLast,
  input  [WMI_S0_DATAPATH_WIDTH-1  :0]   wmiS0_MData,
  input  [WMI_S0_DATAPATH_WIDTH/4-1:0]   wmiS0_MDataByteEn,
  output [1:0]                           wmiS0_SResp,
  output [WMI_S0_DATAPATH_WIDTH-1  :0]   wmiS0_SData,
  output                                 wmiS0_SThreadBusy,
  output                                 wmiS0_SDataThreadBusy,
  output                                 wmiS0_SRespLast,
  output [31:0]                          wmiS0_SFlag,
  input  [31:0]                          wmiS0_MFlag,
  input                                  wmiS0_MReset_n,
  output                                 wmiS0_SReset_n,

  input  [152 : 0]                       server_request_put,
  input                                  EN_server_request_put,
  output                                 RDY_server_request_put,

  output [152 : 0]                       server_response_get,
  input                                  EN_server_response_get,
  output                                 RDY_server_response_get


);

// Compile time check for expected parameters...
initial begin
  if ( (WMI_S0_DATAPATH_WIDTH != 32) && (WMI_S0_DATAPATH_WIDTH != 64) && (WMI_S0_DATAPATH_WIDTH != 128) && (WMI_S0_DATAPATH_WIDTH != 256) ) begin
    $display("Unsupported WMI_S0_DATAPATH width"); $finish; end
end

// Instance the correct variant...

generate
  //genvar byteWidth;
  //byteWidth = WMI_S0_DATAPATH_WIDTH/8;

  case (WMI_S0_DATAPATH_WIDTH/8)
    4:
      mkOCDP4B #(
      .hasPush       (HAS_PUSH_LOGIC  ),
      .hasPull       (HAS_PULL_LOGIC  ),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      OCDP4B_i (
      .wciS0_Clk               (wciS0_Clk),
      .wciS0_MReset_n          (wciS0_MReset_n),
      .wciS0_MAddr             (wciS0_MAddr),
      .wciS0_MAddrSpace        (wciS0_MAddrSpace),
      .wciS0_MByteEn           (wciS0_MByteEn),
      .wciS0_MCmd              (wciS0_MCmd),
      .wciS0_MData             (wciS0_MData),
      .wciS0_MFlag             (wciS0_MFlag),
      .wciS0_SResp             (wciS0_SResp),
      .wciS0_SData             (wciS0_SData),
      .wciS0_SThreadBusy       (wciS0_SThreadBusy),
      .wciS0_SFlag             (wciS0_SFlag),
      .wmiS0_SData             (wmiS0_SData),
      .wmiS0_SFlag             (wmiS0_SFlag),
      .wmiS0_SResp             (wmiS0_SResp),
      .wmiS0_SThreadBusy       (wmiS0_SThreadBusy),
      .wmiS0_SDataThreadBusy   (wmiS0_SDataThreadBusy),
      .wmiS0_SRespLast         (wmiS0_SRespLast),
      .wmiS0_SReset_n          (wmiS0_SReset_n),
      .wmiS0_MCmd              (wmiS0_MCmd),
      .wmiS0_MReqLast          (wmiS0_MReqLast),
      .wmiS0_MReqInfo          (wmiS0_MReqInfo),
      .wmiS0_MAddrSpace        (wmiS0_MAddrSpace),
      .wmiS0_MAddr             (wmiS0_MAddr),
      .wmiS0_MBurstLength      (wmiS0_MBurstLength),
      .wmiS0_MDataValid        (wmiS0_MDataValid),
      .wmiS0_MDataLast         (wmiS0_MDataLast),
      .wmiS0_MData             (wmiS0_MData),
      .wmiS0_MDataByteEn       (wmiS0_MDataByteEn),
      .wmiS0_MFlag             (wmiS0_MFlag),
      .wmiS0_MReset_n          (wmiS0_MReset_n),
      .server_request_put      (server_request_put,
      .EN_server_request_put   (EN_server_request_put),
      .RDY_server_request_put  (RDY_server_request_put),
      .server_response_get     (server_response_get),
      .EN_server_response_get  (EN_server_response_get),
      .RDY_server_response_get (RDY_server_response_get)
      );
      
    8:
      mkOCDP8B #(
      .hasPush       (HAS_PUSH_LOGIC  ),
      .hasPull       (HAS_PULL_LOGIC  ),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      OCDP8B_i (
      .wciS0_Clk               (wciS0_Clk),
      .wciS0_MReset_n          (wciS0_MReset_n),
      .wciS0_MAddr             (wciS0_MAddr),
      .wciS0_MAddrSpace        (wciS0_MAddrSpace),
      .wciS0_MByteEn           (wciS0_MByteEn),
      .wciS0_MCmd              (wciS0_MCmd),
      .wciS0_MData             (wciS0_MData),
      .wciS0_MFlag             (wciS0_MFlag),
      .wciS0_SResp             (wciS0_SResp),
      .wciS0_SData             (wciS0_SData),
      .wciS0_SThreadBusy       (wciS0_SThreadBusy),
      .wciS0_SFlag             (wciS0_SFlag),
      .wmiS0_SData             (wmiS0_SData),
      .wmiS0_SFlag             (wmiS0_SFlag),
      .wmiS0_SResp             (wmiS0_SResp),
      .wmiS0_SThreadBusy       (wmiS0_SThreadBusy),
      .wmiS0_SDataThreadBusy   (wmiS0_SDataThreadBusy),
      .wmiS0_SRespLast         (wmiS0_SRespLast),
      .wmiS0_SReset_n          (wmiS0_SReset_n),
      .wmiS0_MCmd              (wmiS0_MCmd),
      .wmiS0_MReqLast          (wmiS0_MReqLast),
      .wmiS0_MReqInfo          (wmiS0_MReqInfo),
      .wmiS0_MAddrSpace        (wmiS0_MAddrSpace),
      .wmiS0_MAddr             (wmiS0_MAddr),
      .wmiS0_MBurstLength      (wmiS0_MBurstLength),
      .wmiS0_MDataValid        (wmiS0_MDataValid),
      .wmiS0_MDataLast         (wmiS0_MDataLast),
      .wmiS0_MData             (wmiS0_MData),
      .wmiS0_MDataByteEn       (wmiS0_MDataByteEn),
      .wmiS0_MFlag             (wmiS0_MFlag),
      .wmiS0_MReset_n          (wmiS0_MReset_n),
      .server_request_put      (server_request_put,
      .EN_server_request_put   (EN_server_request_put),
      .RDY_server_request_put  (RDY_server_request_put),
      .server_response_get     (server_response_get),
      .EN_server_response_get  (EN_server_response_get),
      .RDY_server_response_get (RDY_server_response_get)
      );
      
    16:
      mkOCDP16B #(
      .hasPush       (HAS_PUSH_LOGIC  ),
      .hasPull       (HAS_PULL_LOGIC  ),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      OCDP16B_i (
      .wciS0_Clk               (wciS0_Clk),
      .wciS0_MReset_n          (wciS0_MReset_n),
      .wciS0_MAddr             (wciS0_MAddr),
      .wciS0_MAddrSpace        (wciS0_MAddrSpace),
      .wciS0_MByteEn           (wciS0_MByteEn),
      .wciS0_MCmd              (wciS0_MCmd),
      .wciS0_MData             (wciS0_MData),
      .wciS0_MFlag             (wciS0_MFlag),
      .wciS0_SResp             (wciS0_SResp),
      .wciS0_SData             (wciS0_SData),
      .wciS0_SThreadBusy       (wciS0_SThreadBusy),
      .wciS0_SFlag             (wciS0_SFlag),
      .wmiS0_SData             (wmiS0_SData),
      .wmiS0_SFlag             (wmiS0_SFlag),
      .wmiS0_SResp             (wmiS0_SResp),
      .wmiS0_SThreadBusy       (wmiS0_SThreadBusy),
      .wmiS0_SDataThreadBusy   (wmiS0_SDataThreadBusy),
      .wmiS0_SRespLast         (wmiS0_SRespLast),
      .wmiS0_SReset_n          (wmiS0_SReset_n),
      .wmiS0_MCmd              (wmiS0_MCmd),
      .wmiS0_MReqLast          (wmiS0_MReqLast),
      .wmiS0_MReqInfo          (wmiS0_MReqInfo),
      .wmiS0_MAddrSpace        (wmiS0_MAddrSpace),
      .wmiS0_MAddr             (wmiS0_MAddr),
      .wmiS0_MBurstLength      (wmiS0_MBurstLength),
      .wmiS0_MDataValid        (wmiS0_MDataValid),
      .wmiS0_MDataLast         (wmiS0_MDataLast),
      .wmiS0_MData             (wmiS0_MData),
      .wmiS0_MDataByteEn       (wmiS0_MDataByteEn),
      .wmiS0_MFlag             (wmiS0_MFlag),
      .wmiS0_MReset_n          (wmiS0_MReset_n),
      .server_request_put      (server_request_put,
      .EN_server_request_put   (EN_server_request_put),
      .RDY_server_request_put  (RDY_server_request_put),
      .server_response_get     (server_response_get),
      .EN_server_response_get  (EN_server_response_get),
      .RDY_server_response_get (RDY_server_response_get)

      );
      
    32:
      mkOCDP32B #(
      .hasPush       (HAS_PUSH_LOGIC  ),
      .hasPull       (HAS_PULL_LOGIC  ),
      .hasDebugLogic (HAS_DEBUG_LOGIC))
      OCDP32B_i (
      .wciS0_Clk               (wciS0_Clk),
      .wciS0_MReset_n          (wciS0_MReset_n),
      .wciS0_MAddr             (wciS0_MAddr),
      .wciS0_MAddrSpace        (wciS0_MAddrSpace),
      .wciS0_MByteEn           (wciS0_MByteEn),
      .wciS0_MCmd              (wciS0_MCmd),
      .wciS0_MData             (wciS0_MData),
      .wciS0_MFlag             (wciS0_MFlag),
      .wciS0_SResp             (wciS0_SResp),
      .wciS0_SData             (wciS0_SData),
      .wciS0_SThreadBusy       (wciS0_SThreadBusy),
      .wciS0_SFlag             (wciS0_SFlag),
      .wmiS0_SData             (wmiS0_SData),
      .wmiS0_SFlag             (wmiS0_SFlag),
      .wmiS0_SResp             (wmiS0_SResp),
      .wmiS0_SThreadBusy       (wmiS0_SThreadBusy),
      .wmiS0_SDataThreadBusy   (wmiS0_SDataThreadBusy),
      .wmiS0_SRespLast         (wmiS0_SRespLast),
      .wmiS0_SReset_n          (wmiS0_SReset_n),
      .wmiS0_MCmd              (wmiS0_MCmd),
      .wmiS0_MReqLast          (wmiS0_MReqLast),
      .wmiS0_MReqInfo          (wmiS0_MReqInfo),
      .wmiS0_MAddrSpace        (wmiS0_MAddrSpace),
      .wmiS0_MAddr             (wmiS0_MAddr),
      .wmiS0_MBurstLength      (wmiS0_MBurstLength),
      .wmiS0_MDataValid        (wmiS0_MDataValid),
      .wmiS0_MDataLast         (wmiS0_MDataLast),
      .wmiS0_MData             (wmiS0_MData),
      .wmiS0_MDataByteEn       (wmiS0_MDataByteEn),
      .wmiS0_MFlag             (wmiS0_MFlag),
      .wmiS0_MReset_n          (wmiS0_MReset_n),
      .server_request_put      (server_request_put,
      .EN_server_request_put   (EN_server_request_put),
      .RDY_server_request_put  (RDY_server_request_put),
      .server_response_get     (server_response_get),
      .EN_server_response_get  (EN_server_response_get),
      .RDY_server_response_get (RDY_server_response_get)
      );
      
    //default: begin $display("Illegal case arm"); $finish; end
  endcase
endgenerate

      
endmodule
