// SimIO.bsv - Routines to read requests from and write responses to named pipes
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import Accum        ::*;

import Connectable  ::*;
import ClientServer ::*;
import FIFO         ::*;
import GetPut       ::*;

interface SimIOIfc;
  interface Client#(Bit#(8),Bit#(8)) host;
endinterface

(* synthesize *)
module mkSimIO (SimIOIfc);

  UInt#(16) skipAmt = 32;

  Reg#(Maybe#(File))         s_hdl          <- mkReg(tagged Invalid);  // file read IOCTL handle
  Reg#(Maybe#(File))         r_hdl          <- mkReg(tagged Invalid);  // file read DCP   handle
  Reg#(Maybe#(File))         w_hdl          <- mkReg(tagged Invalid);  // file write handle
  Reg#(Bit#(32))             h2ioByteCount  <- mkReg(0);               // Host to IOCTL Byte Count
  Reg#(Bit#(32))             h2cpByteCount  <- mkReg(0);               // Host to Control Plane Byte Count
  Reg#(Bit#(32))             cp2hByteCount  <- mkReg(0);               // Control Plane to Host Byte Count
  FIFO#(Bit#(8))             reqF           <- mkFIFO;                 // input queue from host
  FIFO#(Bit#(8))             respF          <- mkFIFO;                 // output queue ito host
  Accumulator2Ifc#(Int#(16)) spinCredit     <- mkAccumulator2;         // Spin credits
  Accumulator2Ifc#(Int#(16)) dcpCredit      <- mkAccumulator2;         // DCP read credits
  Reg#(Bool)                 doTerminate    <- mkReg(False);  
  Reg#(Bool)                 isOpcode       <- mkReg(True);  
  Reg#(Bit#(8))              ioOpcode       <- mkRegU;

  rule passTime (spinCredit>0);
    spinCredit.acc2(-1);
    //$display("[%0d]: passing time - spinCredit:%0d dcpCredit:%0d", $time, spinCredit, dcpCredit);
  endrule

  rule do_w_open (w_hdl matches tagged Invalid);                         // Open response channel first
    let hdl <- $fopen("/tmp/OpenCPI0_Resp", "w");
    w_hdl <= tagged Valid hdl;
    $display("[%0d]: do_w_open called", $time);
  endrule

  rule do_s_open (s_hdl matches tagged Invalid &&& isValid(w_hdl));      // Then IOCTL reads
    let hdl <- $fopen("/tmp/OpenCPI0_IOCtl", "r");
    s_hdl <= tagged Valid hdl;
    spinCredit.load(2);  // Must init to two so we can accept the first 2B instruction
    dcpCredit.load(0);
    $display("[%0d]: do_s_open called", $time);
  endrule

  rule do_r_open (r_hdl matches tagged Invalid &&& isValid(s_hdl));     // Then DCP requests 
    let hdl <- $fopen("/tmp/OpenCPI0_Req", "r");
    r_hdl <= tagged Valid hdl;
    $display("[%0d]: do_r_open called", $time);
  endrule

  rule do_s_char (s_hdl matches tagged Valid .hdl &&& (spinCredit==0));
    int i <- $fgetc(hdl);
    if (i == -1) begin
        $display("[%0d]: do_s_char IOCTL fgetc returned -1 after %0d Bytes", $time, h2ioByteCount);
        $fclose(hdl);
        s_hdl <= tagged Invalid;
    end else begin
        Bit#(8) c = truncate(pack(i));
        h2ioByteCount <= h2ioByteCount + 1;
        //$display("[%0d]: get_ioctl read 0x%x  Host->Simulator ioctl_readCount:%0d ", $time, c, h2ioByteCount);
        isOpcode <= !isOpcode;
        if (isOpcode) begin
          ioOpcode <= c;
        end else begin
          case (ioOpcode)
            0   : spinCredit.acc1(unpack(extend(c)));
            1   : dcpCredit.acc1 (unpack(extend(c)));
            253 : action $dumpoff; $display("[%0d]: dumpoff called", $time); endaction
            254 : action $dumpon;  $display("[%0d]: dumpon called", $time);  endaction
            255 : doTerminate <= True;
          endcase
        end
    end
  endrule

  rule do_r_char (r_hdl matches tagged Valid .hdl &&& (dcpCredit>0));
    int i <- $fgetc(hdl);
    if (i == -1) begin
        $display("[%0d]: do_r_char DCP fgetc returned -1 after %0d Bytes", $time, h2cpByteCount);
        $fclose(hdl);
        r_hdl <= tagged Invalid;
      end
      else begin
        Bit#(8) c = truncate(pack(i));
        h2cpByteCount <= h2cpByteCount + 1;
        //$display("[%0d]: get_cp read 0x%x  Host->Simulator DCP request_readCount:%0d ", $time, c, h2cpByteCount);
        reqF.enq(c);
        dcpCredit.acc2(-1);
      end
  endrule

  rule do_w_char (w_hdl matches tagged Valid .hdl);
    let c = respF.first; respF.deq;
    $fwrite(hdl, "%c", c);  // %c should allow $fputc-like functionality
    $fflush(hdl);
    cp2hByteCount <= cp2hByteCount + 1;
    //$display("[%0d]: get_cp write 0x%x  Simulator->Host response_writeCount:%0d ", $time, c, cp2hByteCount);
  endrule

  rule do_terminate (doTerminate);
    $display("[%0d]: doTerminate called by IOCTL channel", $time);
    $display("[%0d]: IOCTL Bytes Read    :%0d", $time, h2ioByteCount);
    $display("[%0d]: DCP   Bytes Read    :%0d", $time, h2cpByteCount);
    $display("[%0d]: DCP   Bytes Written :%0d", $time, cp2hByteCount);
    $finish;
  endrule

  interface Client host;
    interface request  = toGet(reqF);
    interface response = toPut(respF);
  endinterface

endmodule: mkSimIO

