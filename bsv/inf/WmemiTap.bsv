// WmemiTap.bsv - A Wmemi Connector with an AXI4-MM-Lite tap
// Copyright (c) 2014 Atomic Rules LLC - ALL RIGHTS RESERVED

package WmemiTap;

import ARAXI4L     ::*;
import OCWip       ::*;

import Connectable ::*;
import DReg        ::*;
import FIFO        ::*;	
import GetPut      ::*;
import Vector      ::*;

interface WmemiTapIfc;
  interface WmemiES16B  wmemiS0;  // upstream WMemi Memory Slave Port
  interface WmemiEM16B  wmemiM0;  // downstream WMemi Memory Master Port
  interface A4LMIfc     axiM0;    // downstream AXI4-Lite Master Port
endinterface 

(* synthesize *)
module mkWmemiTap (WmemiTapIfc);

  WmemiSlaveIfc# (36,12,128,16)  wmemiS     <- mkWmemiSlave;  // 2^36 = 64GB
  WmemiMasterIfc#(36,12,128,16)  wmemiM     <- mkWmemiMaster; // 2^36 = 64GB
  A4LMasterIfc                   a4l        <- mkA4LMaster;   // The AXI4-Lite Master Interface
  Reg#(Bool)                     axiActive  <- mkReg(False);  // Used to block WMemi While Axi in flight

  rule operating_actions;
    wmemiS.operate();
    wmemiM.operate();
  endrule

  function Bool isMemoryAddr(Bit#(36) a);
    return !unpack(a[31]); //TODO; Make this function more interesting
  endfunction

  rule advance_request (!axiActive); 
    let req <- wmemiS.req;
    if (isMemoryAddr(req.addr)) begin
      wmemiM.req((req.cmd==WR), req.addr, req.burstLength);   // TODO: Go back and make WmemiMaster take WmemiReq
      if (req.cmd==WR) begin
        let dh <- wmemiS.dh;
        wmemiM.dh(dh.data, dh.dataByteEn, dh.dataLast); 
      end
    end else begin
      axiActive <= True;
      if (req.cmd==WR) begin
        let dh <- wmemiS.dh;
        a4l.f.wrAddr.enq(A4LAddrCmd{addr:truncate(req.addr), prot:aProtDflt});
        a4l.f.wrData.enq(A4LWrData {strb:truncate(dh.dataByteEn), data:truncate(dh.data)});
        $display("[%0d]: %m: AXI4-LITE WRITE REQUEST Addr:%0x BE:%0x Data:%0x", $time, req.addr, dh.dataByteEn, dh.data);
      end else begin
        a4l.f.rdAddr.enq(A4LAddrCmd{addr:truncate(req.addr), prot:aProtDflt});
        $display("[%0d]: %m: AXI4-LITE READ REQUEST Addr:%0x",$time, req.addr);
      end
    end
  endrule

  rule wmemi_response (!axiActive);
    let rsp <- wmemiM.resp;
    wmemiS.respd(rsp.data, rsp.respLast);
  endrule

  rule axi_write_response (axiActive);
    let aw = a4l.f.wrResp.first; //TODO: look at AXI write response code (assume OKAY for now)
    a4l.f.wrResp.deq;
    // write response : Do Nothing, just swallow the write rsp
    axiActive <= False; 
    $display("[%0d]: %m: AXI4-LITE WRITE RESPOSNE",$time);
  endrule

  rule axi_read_response (axiActive);
    let ar = a4l.f.rdResp.first; //TODO: look at AXI read response code (assume OKAY for now)
    a4l.f.rdResp.deq;
    wmemiS.respd(extend(ar.data), True); // Send the data back upstream
    axiActive <= False; 
    $display("[%0d]: %m: AXI4-LITE READ RESPOSNE Data:%0x",$time, ar.data);
  endrule


  WmemiES16B wmemi_Es  <- mkWmemiStoES(wmemiS.slv);
  WmemiEM16B wmemi_Em  <- mkWmemiMtoEm(wmemiM.mas);
  interface WmemiES16B  wmemiS0  = wmemi_Es;
  interface WmemiEM16B  wmemiM0 = wmemi_Em;
  interface A4LMIfc axiM0 = a4l.a4lm;
endmodule

endpackage
