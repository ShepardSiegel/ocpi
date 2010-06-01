// WmiServer.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import RegFile::*;
import Vector::*;
import FIFO::*;	
import FIFOF::*;	

interface WmiServerIfc;
  interface Wmi_s#(14,12,32,0,0,8) wmi_s;
endinterface 

(* synthesize *)
module mkWmiServer (WmiServerIfc);

  WmiSlaveIfc#(14,12,32,0,0,8) wmi          <- mkWmiSlave;
  RegFile#(Bit#(12),Bit#(32))  rf           <- mkRegFileFull;  // 4K by 4B (16KB)
  Reg#(Bool)                   wrActive     <- mkReg(False);
  Reg#(Bool)                   rdActive     <- mkReg(False);
  Reg#(Bool)                   reqValid     <- mkReg(False);
  Reg#(Bit#(14))               addr         <- mkRegU;
  Reg#(Bit#(14))               bytesRemain  <- mkRegU;
  Reg#(Bit#(32))               reqCount     <- mkReg(0);
  Reg#(Bit#(32))               msgCount     <- mkReg(0);

  rule blocking (False);
    wmi.blockSThreadBusy;
  endrule

 (* descending_urgency = "doWrite, doRead, getRequest" *)
 (* mutually_exclusive = "doWrite, doRead" *)

  rule getRequest (!wrActive || !rdActive);
    let req <- wmi.req;
    wrActive    <= req.cmd==WR;
    rdActive    <= req.cmd==RD;
    addr        <= req.addr;
    Bit#(14) br = extend(req.burstLength * 4);
    bytesRemain <= br;
    reqCount    <= reqCount + 1;
    reqValid    <= True;
    if (req.reqInfo==1'b1) msgCount <= msgCount + 1;
    $display("[%0d]: %m: getRequest msg:%0x req:%0x startAddr:%0x bytesRemain:%0x",
      $time, msgCount, reqCount, req.addr, br);
  endrule

  rule doWrite (wrActive && reqValid);
    Bool last = (bytesRemain==4);
    let dh <- wmi.dh;
    rf.upd(truncate(addr>>2),dh.data);
    addr        <= addr + 4;
    bytesRemain <= bytesRemain - 4;
    $display("[%0d]: %m: **** doWrite msg:%0x req:%0x addr:%0x wdata:%0x ", $time, msgCount, reqCount, addr, dh.data);
    if (last) begin
      wrActive <= False;
      reqValid <= False;
    end
  endrule

  rule doRead (rdActive && reqValid);
    Bool last = (bytesRemain==4);
    let rdata = rf.sub(truncate(addr>>2));
    wmi.respd(rdata);
    addr        <= addr + 4;
    bytesRemain <= bytesRemain - 4;
    $display("[%0d]: %m: **** doRead msg:%0x req:%0x addr:%0x rdata:%0x ", $time, msgCount, reqCount, addr, rdata);
    if (last) begin
      rdActive <= False;
      reqValid <= False;
    end
  endrule

  interface Wmi_s wmi_s = wmi.slv;
endmodule

