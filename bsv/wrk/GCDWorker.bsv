// GCDWorker.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;

import GetPut::*;
import FIFO::*;	
import FIFOF::*;	
import SpecialFIFOs::*;

interface GCDWorkerIfc;
  interface Wci_s#(20) wci_s;
endinterface 

(* synthesize *)
module mkGCDWorker#(Bit#(4) ordinalId) (GCDWorkerIfc);
  WciSlaveIfc#(20)     wci        <- mkWciSlave;
  Reg#(Bit#(32))          r0         <- mkReg(0);
  Reg#(Bit#(32))          r4         <- mkReg(0);
  Reg#(Bit#(8))           b18        <- mkReg(8'h18);
  Reg#(Bit#(8))           b19        <- mkReg(8'h19);
  Reg#(Bit#(8))           b1A        <- mkReg(8'h1A);
  Reg#(Bit#(8))           b1B        <- mkReg(8'h1B);
  Reg#(Bool)              sFlagState <- mkReg(False);
  Reg#(Maybe#(Bit#(32)))  gcdRslt    <- mkReg(tagged Invalid);
  Reg#(Bool)              newOp      <- mkReg(False);
  Reg#(Bit#(32))          x          <- mkRegU;
  Reg#(Bit#(32))          y          <- mkRegU;
  Reg#(Bit#(32))          cnt        <- mkReg(0);

  rule updateSflag (sFlagState);
    action wci.drvSFlag; endaction
  endrule

  rule startGCD (newOp && wci.isOperating);
    x <= r0; y <= r4;
    newOp   <= False;
    gcdRslt <= tagged Invalid;
  endrule

  rule flip (!isValid(gcdRslt) && x>y && y!=0);  x <= y; y <= x;     endrule
  rule sub  (!isValid(gcdRslt) && x<=y && y!=0); y <= y - x;         endrule
  rule done (!isValid(gcdRslt) && y==0); gcdRslt<=(tagged Valid x);  endrule

  rule count;
    case (wci.ctlState)
      Initialized: cnt <= 0;        // Reset when Inititalized
      Operating:   cnt <= cnt + 1;  // Increment when Operating
    endcase
  endrule


(* descending_urgency = "wci_ctl_op_complete, wci_ctl_op_start, wci_cfwr, wci_cfrd" *)
(* mutually_exclusive = "wci_cfwr, wci_cfrd, wci_ctrl_EiI, wci_ctrl_IsO, wci_ctrl_OrE" *)

rule wci_cfwr (wci.configWrite); // WCI Configuration Property Writes...
 let wciReq <- wci.reqGet.get;
   case (wciReq.addr[7:0]) matches
     'h00 : begin r0  <= unpack(wciReq.data); newOp<=True; end
     'h04 : begin r4  <= unpack(wciReq.data); newOp<=True; end
     'h18 : begin
         if (wciReq.byteEn[0]==1) b18 <=wciReq.data[ 7: 0];
         if (wciReq.byteEn[1]==1) b19 <=wciReq.data[15: 8];
         if (wciReq.byteEn[2]==1) b1A <=wciReq.data[23:16];
         if (wciReq.byteEn[3]==1) b1B <=wciReq.data[31:24];
      end
     'h20 : sFlagState <= unpack(wciReq.data[0]);
   endcase
   $display("[%0d]: %m: WCI CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, wciReq.data);
   wci.respPut.put(wciOKResponse); // write response
endrule

rule wci_cfrd (wci.configRead); // WCI Configuration Property Reads...
 Bool allowResponse = True;
 let wciReq <- wci.reqGet.get; Bit#(32) rdat = '0;
   case (wciReq.addr[7:0]) matches
     'h00 : rdat = pack(r0);
     'h04 : rdat = pack(r4);
     'h08 : rdat = pack(fromMaybe(32'hBADBADBA,gcdRslt));
     'h0C : rdat = extend(pack(isValid(gcdRslt)));
     'h10 : rdat = extend(ordinalId);
     'h14 : rdat = cnt;
     'h18 : begin
         Bit#(32) myBytes = 0;
         if (wciReq.byteEn[0]==1) myBytes = myBytes | extend(b18)<<0;
         if (wciReq.byteEn[1]==1) myBytes = myBytes | extend(b19)<<8;
         if (wciReq.byteEn[2]==1) myBytes = myBytes | extend(b1A)<<16;
         if (wciReq.byteEn[3]==1) myBytes = myBytes | extend(b1B)<<24;
         rdat = myBytes;
      end
     'h1C : allowResponse = False;
     'h20 : rdat = extend(pack(sFlagState));
   endcase
   $display("[%0d]: %m: WCI CONFIG READ Addr:%0x BE:%0x Data:%0x",
     $time, wciReq.addr, wciReq.byteEn, rdat);
   if (allowResponse) wci.respPut.put(WciResp{resp:DVA data:rdat}); // read response
endrule

rule wci_ctrl_EiI (wci.ctlState==Exists && wci.ctlOp==Initialize);
  wci.ctlAck;
endrule

rule wci_ctrl_IsO (wci.ctlState==Initialized && wci.ctlOp==Start);
  gcdRslt    <= tagged Invalid;
  newOp      <= False;
  wci.ctlAck;
endrule

rule wci_ctrl_OrE (wci.isOperating && wci.ctlOp==Release);
  wci.ctlAck;
endrule

  interface Wci_s wci_s = wci.slv;
endmodule

