// timeServer.v - GPS Disciplined Time Server
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED


// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This is the top-level port signature of the Verilog timeServer Module
// The signals are grouped functionally as indicated by their prefix
// + The aclk and aresetn inputs are the clock and reset for all AXI port groups

module ubbDemodulator # 

  (
  parameter                              S_AXIS_CONFIG_TDATA_WIDTH = 32,
  parameter                              S_AXIS_RCVR_TDATA_WIDTH   = 16,
  parameter                              S_AXIS_RCVR_TUSER_WIDTH   = 2,
  parameter                              S_AXIS_NCO_TDATA_WIDTH    = 32,
  parameter                              S_AXIS_NCO_TUSER_WIDTH    = 2,
  parameter                              M_AXIS_TIME_TDATA_WIDTH   = 64,
  parameter                              M_AXIS_TIME_TUSER_WIDTH   = 2)

  ( 
  input                                  aclk,                 // Core clock
  input                                  aresetn,              // Synchronous Reset, Active-Low

  input  [S_AXIS_CONFIG_TDATA_WIDTH-1:0] s_axis_config_tdata,  // Configuration Input Channel...
  input                                  s_axis_config_tvalid,
  output                                 s_axis_config_tready,
  input                                  s_axis_config_tlast,

  input  [S_AXIS_RCVR_TDATA_WIDTH-1:0]   s_axis_rcvr_tdata,    // Receiver Input Channel...
  input  [S_AXIS_RCVR_TUSER_WIDTH-1:0]   s_axis_rcvr_tuser, 
  input                                  s_axis_rcvr_tvalid,
  output                                 s_axis_rcvr_tready,
  input                                  s_axis_rcvr_tlast,

  input  [S_AXIS_NCO_TDATA_WIDTH-1:0]    s_axis_nco_tdata,     // NCO Input Channel...
  input  [S_AXIS_NCO_TUSER_WIDTH-1:0]    s_axis_nco_tuser, 
  input                                  s_axis_nco_tvalid,
  output                                 s_axis_nco_tready,
  input                                  s_axis_nco_tlast,

  output [M_AXIS_DEMOD_TDATA_WIDTH-1:0]  m_axis_time_tdata,    // Time Output channel...
  output [M_AXIS_DEMOD_TUSER_WIDTH-1:0]  m_axis_time_tuser, 
  output                                 m_axis_time_tvalid,
  input                                  m_axis_time_tready,
  output                                 m_axis_time_tlast
);

endmodule
