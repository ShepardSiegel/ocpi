import CTop::*;
import OCTG_nft::*;
import TLPMF::*;

import PCIE::*;
import GetPut::*;
import TestbenchUtils::*;
import ClientServer::*;
import Connectable::*;

(* synthesize *)
module mkTB_nft();

  Reg#(Bit#(32))  cycle      <- mkReg(0);
  PciId           pciDevice  = unpack('0);
  Clock           sys0_clk   <- exposeCurrentClock;
  Reset           sys0_rst   <- exposeCurrentReset;
  CTop16BIfc       ctop       <- mkCTop16B(pciDevice, sys0_clk, sys0_rst);
  OCTGIfc         tg         <- mkOCTG_nft;
  TLPCMIfc        cm0        <- mkTLPCM(tagged Bus 255);    // client merge, fork away Req to Bus 255

  rule terminate (cycle==100000);
    $display("[%0d] %m termination NFT", $time);
    $finish;
  endrule

  rule cycleCount;
    cycle <= cycle + 1;
  endrule

  mkConnection(tg.client, cm0.s0);               // cm0 tg attach
  mkConnection(tg.client2, cm0.s1);
  mkConnection(cm0.c, ctop.server);              // cm0 sm0 link

endmodule: mkTB_nft

