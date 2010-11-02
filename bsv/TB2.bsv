import CTop::*;
import OCTG::*;
import TLPMF::*;

import PCIE::*;
import GetPut::*;
import TestbenchUtils::*;
import ClientServer::*;
import Connectable::*;

(* synthesize *)
module mkTB2();

  Reg#(Bit#(16))  cycle      <- mkReg(0);
  PciId           pciDevice  = unpack('0);
  Clock           sys0_clk   <- exposeCurrentClock;
  Reset           sys0_rst   <- exposeCurrentReset;
  CTop4BIfc       ctop       <- mkCTop4B(pciDevice, sys0_clk, sys0_rst);
  OCTGIfc         tg         <- mkOCTG_genchk;
  TLPCMIfc        cm0        <- mkTLPCM(tagged Bus 255);    // client merge, fork away Req to Bus 255

  rule terminate (cycle==5000);
  //rule terminate (cycle==100);
    $display("[%0d] %m termination", $time);
    $finish;
  endrule

  rule cycleCount;
    cycle <= cycle + 1;
  endrule

  mkConnection(tg.client, cm0.s0);               // cm0 tg attach
  mkConnection(cm0.c, ctop.server);              // cm0 sm0 link
  mkConnection(cm0.s1.request, cm0.s1.response); // loopback so DP1 can reach DP0

endmodule: mkTB2

