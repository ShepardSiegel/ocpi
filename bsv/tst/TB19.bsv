// TB19.bsv - A testbench for a OpenCPI that uses a DCP byte stream  - TB18 adapted to use OCApp
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import Config       ::*;
import OCApp        ::*;
import OCWip        ::*;
import OCCP         ::*;
import SimDCP       ::*;
import SimIO        ::*;

import ClientServer ::*;
import Connectable  ::*;
import FIFO         ::*;
import GetPut       ::*;
import Vector       ::*;
import Real         ::*;

(* synthesize *)
module mkTB19(Empty);

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

  mkConnection(simIO.host,simDCP.host);   // Connect simIO to simDCP 
  mkConnection(simDCP.client,cp.server);  // Connect simDCP to Control Plane 

  Vector#(Nwcit, WciEM) vWci = cp.wci_Vm;                                    // Vector of WciEM Interfaces
  Vector#(iNwci_ctop, Reset) resetVec = newVector;                           // Vector of WCI Resets
  for (Integer i=0; i<iNwci_app; i=i+1) resetVec[i] = vWci[i].mReset_n;      // Reset Vector for the Application
  OCApp4BIfc  app  <- mkOCApp4B(resetVec,True);                              // Instance the Application
  for (Integer i=0; i<iNwci_app; i=i+1) mkConnection(vWci[i], app.wci_s[i]); // Connect WCI between INF/APP

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

endmodule: mkTB19
