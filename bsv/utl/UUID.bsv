// UUID.bsv - template for FPGA GUID insertion up to 512b, 64B, 16DW, 1CL
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

interface UUIDIfc;
  (* always_ready *) method Bit#(512) uuid;
endinterface

(* synthesize, no_default_clock, no_default_reset *)
module mkUUID (UUIDIfc);
  Bit#(512) id = 512'hF0000000_E0000000_D0000000_C0000000_B0000000_A0000000_90000000_80000000_70000000_60000000_50000000_40000000_30000000_20000000_10000000_00000000;
  method Bit#(512) uuid = id;
endmodule
