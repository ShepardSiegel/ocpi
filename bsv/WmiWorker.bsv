// WmiWorker.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import GetPut::*;
import DReg::*;
import FIFO::*;	
import FIFOF::*;	

interface WmiWorkerIfc;
  interface Wmi_m#(14,12,32,0,0,32) wmi_m;
endinterface 

(* synthesize *)
module mkWmiWorker (WmiWorkerIfc);

  WmiMasterIfc#(14,12,32,0,0,32) wmi <- mkWmiMaster;
  Reg#(Bool)           doWrMsg      <- mkReg(False);
  Reg#(Bool)           doRdMsg      <- mkReg(False);
  Reg#(Bool)           nxtMsg       <- mkReg(False);
  Reg#(Bool)           doDwell      <- mkReg(False);
  Reg#(Bool)           initialized  <- mkReg(False);
  Reg#(Bit#(14))       addr         <- mkRegU;
  Reg#(Bit#(14))       bytesRemain  <- mkRegU;
  Reg#(Bit#(32))       msgCount     <- mkReg(0);
  Reg#(Bit#(32))       dataCount    <- mkReg(0);

 (* descending_urgency = "doInit, dwell, wrMessage, rdMessage, newMessage" *)

  rule doInit (!initialized);
    nxtMsg      <= True;
    initialized <= True;
  endrule

  rule newMessage (nxtMsg && initialized);
    nxtMsg      <= False;
    addr        <= 0;
    bytesRemain <= 16;
    msgCount    <= msgCount + 1;
    $display("[%0d]: %m: newMessage msg:%0d ", $time, msgCount);

    doWrMsg <= True;
    /*
    case (msgCount)
      0: doWrMsg <= True;
      1: doWrMsg <= True;
      2: doWrMsg <= True;
      3: doWrMsg <= True;
      4: doRdMsg <= True;
      5: doRdMsg <= True;
      6: doRdMsg <= True;
      7: doRdMsg <= True;
    endcase
    */
  endrule


 (* mutually_exclusive = "wrMessage, rdMessage, dwell" *)

  rule wrMessage (doWrMsg && initialized);
    Bool last = (bytesRemain==4);
    wmi.req(True, addr, 1, last);
    //wmi.dh(last?msgCount:dataCount, '1, True);
    wmi.dh(dataCount, '1, True);
    addr        <= addr + 4;
    bytesRemain <= bytesRemain - 4;
    dataCount   <= dataCount + 1;
    if (last) begin
      doWrMsg <= False;
      doDwell <= True;
    end
  endrule

  rule rdMessage (doRdMsg && initialized);
    Bool last = (bytesRemain==4);
    wmi.req(False, addr, 1, last);
    addr        <= addr + 4;
    bytesRemain <= bytesRemain - 4;
    dataCount   <= dataCount + 1;
    if (last) begin
      doRdMsg <= False;
      doDwell <= True;
    end
  endrule

  rule dwell (doDwell && initialized);  // Dwell at message end if there is Req or Dh backpressure
    if (!wmi.anyBusy) begin
      doDwell <= False;
      nxtMsg  <= True;
    end
  endrule

  rule respChomp;
    let resp <- wmi.resp;
    $display("[%0d]: %m: respChomp msg:%0d rdata:%0x", $time, msgCount, resp.data);
  endrule

  interface Wmi_m wmi_m = wmi.mas;
endmodule

