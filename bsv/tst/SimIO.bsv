// SimIO.bsv - Routines to read requests from and write responses to named pipes
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import Connectable  ::*;
import ClientServer ::*;
import FIFO         ::*;
import GetPut       ::*;

interface SimIOIfc;
  interface Client#(Bit#(8),Bit#(8)) host;
endinterface

(* synthesize *)
module mkSimIO (SimIOIfc);

  UInt#(16) skipAmt = 255;

  Reg#(Maybe#(File))      r_hdl          <- mkReg(tagged Invalid);  // file read handle
  Reg#(Maybe#(File))      w_hdl          <- mkReg(tagged Invalid);  // file write handle
  Reg#(Bit#(32))          h2cpByteCount  <- mkReg(0);               // Host to Control Plane Byte Count
  Reg#(Bit#(32))          cp2hByteCount  <- mkReg(0);               // Control Plane to Host Byte Count
  FIFO#(Bit#(8))          reqF           <- mkFIFO;                 // input queue from host
  FIFO#(Bit#(8))          respF          <- mkFIFO;                 // output queue ito host
  Reg#(UInt#(16))         skipCnt        <- mkReg(skipAmt);

  rule skipUpdate;
    skipCnt <= (skipCnt==0) ? skipAmt : skipCnt-1;
  endrule


  rule do_r_open (r_hdl matches tagged Invalid);
    let hdl <- $fopen("/tmp/OpenCPI0_Req", "r");
    r_hdl <= tagged Valid hdl;
  endrule

  rule do_w_open (w_hdl matches tagged Invalid);
    let hdl <- $fopen("/tmp/OpenCPI0_Resp", "w");
    w_hdl <= tagged Valid hdl;
  endrule

  rule do_r_char (r_hdl matches tagged Valid .hdl &&& skipCnt==0);
    int i <- $fgetc(hdl);
    if (i == -1) begin
        $display("[%0d]: do_r_char fgetc returned -1 after %0d Bytes", $time, h2cpByteCount);
        $fclose(hdl);
        r_hdl <= tagged Invalid;
      end
      else begin
        Bit#(8) c = truncate(pack(i));
        h2cpByteCount <= h2cpByteCount + 1;
        $display("[%0d]: get_cp read 0x%x  readCount:%0d ", $time, c, h2cpByteCount);
        reqF.enq(c);
      end
  endrule

  rule do_w_char (w_hdl matches tagged Valid .hdl);
    let c = respF.first; respF.deq;
    $fwrite(hdl, "%c", c);  // %c should allow $fputc-like functionality
    $fflush(hdl);
    cp2hByteCount <= cp2hByteCount + 1;
    $display("[%0d]: get_cp write 0x%x  writeCount:%0d ", $time, c, cp2hByteCount);
  endrule

  interface Client host;
    interface request  = toGet(reqF);
    interface response = toPut(respF);
  endinterface

endmodule: mkSimIO

