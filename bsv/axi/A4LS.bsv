// A4LS.bsv - A Basic AXI4-Lite Slave
// Copyright (c) 2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4L::*;  
import FIFO::*;	

(* synthesize, default_clock_osc="ACLK", default_reset="ARESETN" *)
module mkA4LS#(parameter Bool hasDebugLogic) (A4L_Es);
  A4LSlaveIfc     a4l           <- mkA4LSlave;     // The AXI4-Lite Slave Interface
  Reg#(Bit#(32))  r0            <- mkReg(0);       // Some regsiters for testing...
  Reg#(Bit#(32))  r4            <- mkReg(0);
  Reg#(Bit#(8))   b18           <- mkReg(8'h18);
  Reg#(Bit#(8))   b19           <- mkReg(8'h19);
  Reg#(Bit#(8))   b1A           <- mkReg(8'h1A);
  Reg#(Bit#(8))   b1B           <- mkReg(8'h1B);
  Reg#(Bit#(32))  lastReadAddr  <- mkReg(0);
  Reg#(Bit#(32))  lastWriteAddr <- mkReg(0);

rule a4l_cfwr; // AXI4-Lite Configuration Property Writes...
  let wa = a4l.f.wrAddr.first; a4l.f.wrAddr.deq;  // Get the write address
  let wd = a4l.f.wrData.first; a4l.f.wrData.deq;  // Get the write data
  lastWriteAddr <= wa.addr;                       // Capture this write address
  case (wa.addr[7:0]) matches                     // Take some action with it...
    'h00 : r0  <= unpack(wd.data);
    'h04 : r4  <= unpack(wd.data);
    'h18 : begin
        if (wd.strb[0]==1) b18 <=wd.data[ 7: 0];
        if (wd.strb[1]==1) b19 <=wd.data[15: 8];
        if (wd.strb[2]==1) b1A <=wd.data[23:16];
        if (wd.strb[3]==1) b1B <=wd.data[31:24];
      end
  endcase
  a4l.f.wrResp.enq(A4LWrResp{resp:OKAY});         // Acknowledge the write
  $display("[%0d]: %m: AXI4-LITE CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wa.addr, wd.strb, wd.data);
endrule

rule a4l_cfrd;  // AXI4-Lite Configuration Property Reads...
  let ra = a4l.f.rdAddr.first; a4l.f.rdAddr.deq;    // Get the read address
  lastReadAddr <= ra.addr;                          // Capture this read address
  Bit#(32) rdat = ?;                                
  case (ra.addr[7:0]) matches                     
    'h00 : rdat = pack(r0);           // return r0
    'h04 : rdat = pack(r4);           // return r4
    'h10 : rdat = 32'hF00DFACE;       // return a constant
    'h18 : rdat = {b1B,b1A,b19,b18};  // return little-endian
    'h20 : rdat = lastWriteAddr;      // return the address last written
    'h24 : rdat = lastReadAddr;       // return the address last read
  endcase
  a4l.f.rdResp.enq(A4LRdResp{data:rdat,resp:OKAY}); // Return the read data
  $display("[%0d]: %m: AXI4-LITE CONFIG READ Addr:%0x",$time, ra.addr);
  $display("[%0d]: %m: AXI4-LITE CONFIG READ RESPOSNE Data:%0x",$time, rdat);
endrule

  A4L_Es a4ls <- mkA4StoEs(a4l.a4ls); // return the expanded interface...
  return(a4ls); 
endmodule
