// AXIS_LOOPBACK - For testing the OPED component
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED
//
// The purpose of this module is to loopback the AXI4-Stream that is produced
// by the OPED to the stream that is consumed by the OPED. In this way, this
// module can stand-in for the OPED during development; and be repaled with
// Input/Output arbiters when ready. This module allows testing of the DMA
// capabilities of OPED block with mininal extra logic.

// + The 32b of TUSER are assigned as follows
// TUSER[31:16] Transfer Length in Bytes  (provided by OPED AXIS Master, ignored by OPED AXIS Slave)
// TUSER[15:08] Spare, Ignored (zero)
// TUSER[ 7:0 ] Message Opcode (provided by AXIS master, accepted by AXIS slave)

module AXIS_LOOPBACK (
  input  wire        ACLK,
  input  wire        ARESETN,
  input  wire [32:0] S_AXIS_DAT_TDATA,
  input  wire        S_AXIS_DAT_TVALID,
  input  wire [3:0]  S_AXIS_DAT_TSTRB,
  input  wire [32:0] S_AXIS_DAT_TUSER,
  input  wire        S_AXIS_DAT_TLAST,
  output wire        S_AXIS_DAT_TREADY,
  output wire [32:0] M_AXIS_DAT_TDATA,
  output wire        M_AXIS_DAT_TVALID,
  output wire [3:0]  M_AXIS_DAT_TSTRB,
  output wire [32:0] M_AXIS_DAT_TUSER,
  output wire        M_AXIS_DAT_TLAST,
  input  wire        M_AXIS_DAT_TREADY
);

// Just loop the signals through...
  assign M_AXIS_DAT_TDATA  = S_AXIS_DAT_TDATA;
  assign M_AXIS_DAT_TVALID = S_AXIS_DAT_TVALID;
  assign M_AXIS_DAT_TSTRB  = S_AXIS_DAT_TSTRB;
  assign M_AXIS_DAT_TUSER  = S_AXIS_DAT_TUSER;
  assign M_AXIS_DAT_TLAST  = S_AXIS_DAT_TLAST;
  assign S_AXIS_DAT_TREADY = M_AXIS_DAT_TREADY;

endmodule
