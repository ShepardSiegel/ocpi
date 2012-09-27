// TB16.bsv - A testbench for a OpenCPI that uses a DCP byte stream 
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip       ::*;
import BiasWorker  ::*;

import Connectable ::*;
import FIFO        ::*;
import GetPut      ::*;
import Real        ::*;


(* synthesize *)
module mkTB16();

  Reg#(Bit#(16))          simCycle       <- mkReg(0);               // simulation cycle counter
  Reg#(Maybe#(File))      r_hdl          <- mkReg(tagged Invalid);  // file read handle
  Reg#(Maybe#(File))      w_hdl          <- mkReg(tagged Invalid);  // file write handle
  Reg#(Bit#(32))          h2cpByteCount  <- mkReg(0);               // Host to Control Plane Byte Count
  Reg#(Bit#(32))          cp2hByteCount  <- mkReg(0);               // Control Plane to Host Byte Count
  FIFO#(Bit#(8))          inF            <- mkFIFO;                 // input queue from host
  FIFO#(Bit#(8))          outF           <- mkFIFO;                 // output queue ito host
  Reg#(Bool)              inEOF          <- mkReg(False);           // input EOF reached



  // It is each WCI master's job to generate for each WCI M-S pairing a mReset_n signal that can reset each worker
  // We send that reset in on the "reset_by" line to reset all state associated with worker module...
  //BiasWorker4BIfc             biasWorker     <- mkBiasWorker4B(True, reset_by wci.mas.mReset_n); 

  // Connect the DUT's three interfaces...
  //mkConnection(wci.mas, biasWorker.wciS0);              // Connect the WCI Master to the DUT
  //mkConnection(toWsiEM(wsiM.mas), biasWorker.wsiS0);    // Connect the Source wsiM to the biasWorker wsi-S input
  //Wsi_Es#(12,32,4,8,0) wsi_Es <- mkWsiStoES(wsiS.slv);  // Convert the conventional to explicit 
  //mkConnection(biasWorker.wsiM0,  wsi_Es);              // Connect the biasWorker wsi-M output to the Sinc wsiS


  rule do_r_open (r_hdl matches tagged Invalid);
    let hdl <- $fopen("host2cp.dat", "r");
    r_hdl <= tagged Valid hdl;
  endrule

//rule do_w_open (w_hdl matches tagged Invalid);
//  let hdl <- $fopen("cp2host.dat", "w");
//  w_hdl <= tagged Valid hdl;
//endrule

  rule do_r_char (r_hdl matches tagged Valid .hdl &&& !inEOF);
    int i <- $fgetc(hdl);
    if (i == -1) begin
        $display("[%0d]: do_r_char fgetc returned -1 after %0d Bytes", $time, h2cpByteCount);
        $fclose(hdl);
        inEOF <= True;
        //$finish(0);
      end
      else begin
        Bit#(8) c = truncate(pack(i));
        h2cpByteCount <= h2cpByteCount + 1;
        $display("[%0d]: get_cp read %x on byte %x ", $time, c, h2cpByteCount);
        //inF.enq(c);
      end
  endrule

  /*
  rule do_w_char (w_hdl matches tagged Valid .hdl);
    let c = outF.first; outF.deq;
    $fwrite(hdl, c);
    cp2hByteCount <= cp2hByteCount + 1;
    $display("[%0d]: get_cp write %x on byte %x ", $time, c, cp2hByteCount);
  endrule

  rule copy;
    outF.enq(inF.first); inF.deq;
  endrule
*/

  // Simulation Control...
  rule increment_simCycle;
    simCycle <= simCycle + 1;
  endrule

  rule terminate (simCycle==1000);
    $display("[%0d]: %m: mkTB16 termination", $time);
    $finish;
  endrule

endmodule: mkTB16

