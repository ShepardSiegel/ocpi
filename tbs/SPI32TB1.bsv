// SPI32TB1 - A Testbench for the SPICore32
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import SPICore32   ::*;

import Connectable ::*;
import FIFO        ::*;
import GetPut      ::*;

(* synthesize *)
module mkSPI32TB1(Empty);

  Reg#(Bit#(16))        simCycle       <- mkReg(0);       // simulation cycle counter
  Spi32Ifc              spi            <- mkSpi32;

  rule do_req (simCycle==36);
    //spi.req.put(Spi32Req{isRead:False, addr:4'h1, data:32'h8765_4321});
    spi.req.put(Spi32Req{isRead:True, addr:4'h1, data:'0});
  endrule

  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkSPI32TB1 termination", $time);
    $finish;
  endrule

endmodule: mkSPI32TB1
