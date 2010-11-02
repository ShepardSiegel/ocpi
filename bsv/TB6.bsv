import CTop::*;
import OCTG::*;
import TLPMF::*;

import PCIE::*;
import GetPut::*;
import TestbenchUtils::*;
import ClientServer::*;
import Connectable::*;

(* synthesize *)
module mkTB6();

  Reg#(Bit#(16))    cycle      <- mkReg(0);
  OCTGIfc           tg         <- mkOCTG_dma2push;
  CTop4BIfc         ct0        <- mkCTop4B(PciId{bus:0, dev:0, func:0 });
  CTop4BIfc         ct1        <- mkCTop4B(PciId{bus:1, dev:0, func:0 });
  TLPClientNodeIfc  cn0        <- mkTLPClientNode(tagged Route RouteSub{addr:4'hF, bus:8'hFF});
  TLPServerNodeIfc  sn0        <- mkTLPServerNode(tagged Route RouteSub{addr:4'h0, bus:8'h0});
  TLPServerNodeIfc  sn1        <- mkTLPServerNode(tagged Route RouteSub{addr:4'h1, bus:8'h1});

  rule cycleCount; cycle <= cycle + 1; endrule

  rule terminate (cycle==10000);
    $display("[%0d] %m termination", $time);
    $finish;
  endrule

  mkConnection(tg.client, cn0.s);
  mkConnection(sn0.c, ct0.server);
  mkConnection(sn1.c, ct1.server);
  mkConnection(cn0.p, sn0.g);
  mkConnection(sn0.p, sn1.g);
  mkConnection(sn1.p, cn0.g);

endmodule: mkTB6

