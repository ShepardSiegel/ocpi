// A4LS.bsv
// Copyright (c) 2010 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4L::*;

import Bus::*;	
import FIFO::*;	

(* synthesize, default_clock_osc="ACLK", default_reset="ARESETN" *)
module mkA4LS#(parameter Bool hasDebugLogic) (A4L_Es);

  BusReceiver#(A4LAddrCmd)   a4wrAddr     <- mkBusReceiver;
  BusReceiver#(A4LWrData)    a4wrData     <- mkBusReceiver;
  BusSender#(A4LWrResp)      a4wrResp     <- mkBusSender(aWrRespDflt);
  BusReceiver#(A4LAddrCmd)   a4rdAddr     <- mkBusReceiver;
  BusSender#(A4LRdResp)      a4rdResp     <- mkBusSender(aRdRespDflt);
  Reg#(Bit#(32))             r0           <- mkReg(0);
  Reg#(Bit#(32))             r4           <- mkReg(0);
  Reg#(Bit#(8))              b18          <- mkReg(8'h18);
  Reg#(Bit#(8))              b19          <- mkReg(8'h19);
  Reg#(Bit#(8))              b1A          <- mkReg(8'h1A);
  Reg#(Bit#(8))              b1B          <- mkReg(8'h1B);

rule a4l_cfwr; // AXI4-Lite Configuration Property Writes...
  let wa = a4wrAddr.out.first; a4wrAddr.out.deq;
  let wd = a4wrData.out.first; a4wrData.out.deq;
  case (wa.addr[7:0]) matches
    'h00 : r0  <= unpack(wd.data);
    'h04 : r4  <= unpack(wd.data);
    'h18 : begin
        if (wd.strb[0]==1) b18 <=wd.data[ 7: 0];
        if (wd.strb[1]==1) b19 <=wd.data[15: 8];
        if (wd.strb[2]==1) b1A <=wd.data[23:16];
        if (wd.strb[3]==1) b1B <=wd.data[31:24];
      end
  endcase
  a4wrResp.in.enq(A4LWrResp{resp:OKAY});
  $display("[%0d]: %m: AXI4-LITE CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wa.addr, wd.strb, wd.data);
endrule

rule a4l_cfrd;  // AXI4-=Lite Configuration Property Reads...
  let ra = a4rdAddr.out.first; a4rdAddr.out.deq;
  Bit#(32) rdat = 0;
  case (ra.addr[7:0]) matches
    'h00 : rdat = pack(r0);
    'h04 : rdat = pack(r4);
    'h10 : rdat = 32'hF00DFACE;
    'h18 : rdat = {b1B,b1A,b19,b18};
  endcase
  a4rdResp.in.enq(A4LRdResp{data:rdat,resp:OKAY});
  $display("[%0d]: %m: AXI4-LITE CONFIG READ Addr:%0x",$time, ra.addr);
  $display("[%0d]: %m: AXI4-LITE CONFIG READ RESPOSNE Data:%0x",$time, rdat);
endrule

  A4L_Es a4ls <- mkA4StoEs(A4LSIfc {wrAddr:a4wrAddr.in,
                                    wrData:a4wrData.in,
                                    wrResp:a4wrResp.out,
                                    rdAddr:a4rdAddr.in,
                                    rdResp:a4rdResp.out} );
  return(a4ls);  // return the expanded interface
endmodule
