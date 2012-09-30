// TB18.bsv - A testbench for a OpenCPI that uses a DCP byte stream 
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import Config       ::*;
import OCWip        ::*;
import BiasWorker   ::*;
import OCCP         ::*;
import SimDCP       ::*;
import SimIO        ::*;
import WSIPatternWorker ::*;
import WSICaptureWorker ::*;

import ClientServer ::*;
import Connectable  ::*;
import FIFO         ::*;
import GetPut       ::*;
import Vector       ::*;
import Real         ::*;

(* synthesize *)
module mkTB18();

  Clock  sys1_clk <- exposeCurrentClock;
  Reset  sys1_rst <- exposeCurrentReset;

  Reg#(Bit#(16))          simCycle       <- mkReg(0);      // simulation cycle counter
  SimIOIfc                simIO          <- mkSimIO;       // simulator file IO
  SimDCPIfc               simDCP         <- mkSimDCP;      // decode DCP to control plane
  OCCPIfc#(Nwcit)         cp             <- mkOCCP(
                                            ?,             // pciDevice (not used)
                                            sys1_clk,      // time_clk timebase
                                            sys1_rst,      // time_rst reset
                                            clocked_by sys1_clk, reset_by sys1_rst);

  Vector#(Nwcit, WciEM) vWci = cp.wci_Vm;

  WSIPatternWorker4BIfc  pat0  <- mkWSIPatternWorker(True, clocked_by sys1_clk, reset_by(vWci[2].mReset_n));
  BiasWorker4BIfc        bias  <- mkBiasWorker4B(    True, clocked_by sys1_clk, reset_by(vWci[3].mReset_n));
  WSICaptureWorker4BIfc  cap0  <- mkWSICaptureWorker(True, clocked_by sys1_clk, reset_by(vWci[4].mReset_n));

  mkConnection(simIO.host,simDCP.host);   // Connect simIO to simDCP 
  mkConnection(simDCP.client,cp.server);  // Connect simDCP to Control Plane 

  mkConnection(pat0.wsiM0, bias.wsiS0);   // PAT0->Bias
  mkConnection(bias.wsiM0, cap0.wsiS0);   // Bias->CAP0

  mkConnection(vWci[2],  pat0.wciS0);     // PAT0
  mkConnection(vWci[3],  bias.wciS0);     // Bias Worker
  mkConnection(vWci[4],  cap0.wciS0);     // CAP0


  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==64000);
    $display("[%0d]: %m: mkTB18 termination by terminate rule (timeout)", $time);
    $finish;
  endrule

endmodule: mkTB18
