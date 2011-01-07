// UUID.bsv - template for FPGA GUID insertion up to 512b, 64B, 1CL
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

interface UUIDIfc;
  (* always_ready *) method Bit#(512) id;
endinterface

(* synthesize, no_default_clock, no_default_reset *)
module mkUUID (UUIDIfc);
  Bit#(512) uuid = 512'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
  method Bit#(512) id = uuid;
endmodule
