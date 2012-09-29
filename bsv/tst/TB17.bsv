// TB17.bsv - A testbench for a OpenCPI that uses a DCP byte stream 
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip        ::*;
import BiasWorker   ::*;
import SimIO        ::*;

import ClientServer ::*;
import Connectable  ::*;
import FIFO         ::*;
import GetPut       ::*;
import Real         ::*;

(* synthesize *)
module mkTB17();

  Reg#(Bit#(16))          simCycle       <- mkReg(0);      // simulation cycle counter
  SimIOIfc                simIO          <- mkSimIO;       // simulator file IO


  // It is each WCI master's job to generate for each WCI M-S pairing a mReset_n signal that can reset each worker
  // We send that reset in on the "reset_by" line to reset all state associated with worker module...
  //BiasWorker4BIfc             biasWorker     <- mkBiasWorker4B(True, reset_by wci.mas.mReset_n); 

  // Connect the DUT's three interfaces...
  //mkConnection(wci.mas, biasWorker.wciS0);              // Connect the WCI Master to the DUT
  //mkConnection(toWsiEM(wsiM.mas), biasWorker.wsiS0);    // Connect the Source wsiM to the biasWorker wsi-S input
  //Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 
  //mkConnection(biasWorker.wsiM0,  wsi_Es);              // Connect the biasWorker wsi-M output to the Sinc wsiS

  mkConnection(simIO.host.request, simIO.host.response);

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==10000);
    $display("[%0d]: %m: mkTB16 termination by terminate rule (timeout)", $time);
    $finish;
  endrule

endmodule: mkTB17

