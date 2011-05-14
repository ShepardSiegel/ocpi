// AXIS_LOOPBACK - For testing the OPED component
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// The purpose of this module is to loopback the AXI4-Stream that is produced
// by the OPED to the stream that is consumed by the OPED. In this way, this
// module can stand-in for the OPED during development; and be repaled with
// Input/Output arbiters when ready. This module allows testing of the DMA
// capabilities of OPED block with mininal extra logic.
//
// + The 128b of TUSER are assigned as follows:
// TUSER[15:0]   Transfer Length in Bytes  (provided by OPED AXIS Master; ignored by OPED AXIS Slave since TLAST implicit length) 
// TUSER[23:16]  Source Port (SPT) (provided by OPED AXIS Master from DP0 opcode; ignored by OPED AXIS Slave)
// TUSER[31:24]  Destination Port (DPT) (driven to 8'h01 by OPED AXIS Master;  used by OPED AXIS Slave to make DP1 opcode)
// TUSER[127:32] User metadata bits, un-used by OPED. driven to 0 by OPED AXIS master; un-used by OPED AXIS slave
//
// Note that OPED is "port-encoding-agnostic" with respect to the values on SPT and DPT:
//  a. In the case of packets moving downstream from host to NF10, OPED places DP0 opcode metadata on SPT
//  b. In the case of packets moving upstream from NF10 to host, OPED captures DPT and places it in DP1 opcode
//  The value 8'h01 is placed as a constant in the DPT output of the OPED AXIS Master

// Note that OPED does nothing with the TUSER[127:32] user metadata bits.
// a. It drives them to 0 on the AXIS Master
// b. it ignores them on the the AXIS Slave


module AXIS_LOOPBACK (
  input  wire         ACLK,
  input  wire         ARESETN,
  input  wire [32:0]  S_AXIS_DAT_TDATA,
  input  wire         S_AXIS_DAT_TVALID,
  input  wire [3:0]   S_AXIS_DAT_TSTRB,
  input  wire [127:0] S_AXIS_DAT_TUSER,
  input  wire         S_AXIS_DAT_TLAST,
  output wire         S_AXIS_DAT_TREADY,
  output wire [32:0]  M_AXIS_DAT_TDATA,
  output wire         M_AXIS_DAT_TVALID,
  output wire [3:0]   M_AXIS_DAT_TSTRB,
  output wire [127:0] M_AXIS_DAT_TUSER,
  output wire         M_AXIS_DAT_TLAST,
  input  wire         M_AXIS_DAT_TREADY
);

// Just loop the signals through...
  assign M_AXIS_DAT_TDATA  = S_AXIS_DAT_TDATA;
  assign M_AXIS_DAT_TVALID = S_AXIS_DAT_TVALID;
  assign M_AXIS_DAT_TSTRB  = S_AXIS_DAT_TSTRB;
  assign M_AXIS_DAT_TUSER  = S_AXIS_DAT_TUSER;
  assign M_AXIS_DAT_TLAST  = S_AXIS_DAT_TLAST;
  assign S_AXIS_DAT_TREADY = M_AXIS_DAT_TREADY;

endmodule
