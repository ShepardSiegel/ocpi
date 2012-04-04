// CPMux.bsv - Control Plane Mux - Allow Two Control Plane clients (e.g. PCIe and Ethernet) to access the Control Plane Server
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import CPDefs::*;

import ClientServer::*; 
import FIFO::*;
import GetPut::*;

interface CPMuxIfc;
  interface Server#(CpReq,CpReadResp) serverA;
  interface Server#(CpReq,CpReadResp) serverB;
  interface Client#(CpReq,CpReadResp) client;
endinterface

module mkCPMux (CPMuxIfc);

  FIFO#(CpReq)          reqAF    <- mkFIFO;
  FIFO#(CpReq)          reqBF    <- mkFIFO;
  FIFO#(CpReq)          cpReqF   <- mkFIFO;
  FIFO#(CpReadResp)     respAF   <- mkFIFO;
  FIFO#(CpReadResp)     respBF   <- mkFIFO;
  FIFO#(CpReadResp)     cpRespF  <- mkFIFO;
  FIFO#(Bool)           aActF    <- mkFIFO;

  //TODO: At 2012-04-04 there were no active write responses on this interface.
  // This complicates this issue of returning the reponse to the correct requester in the case of multi-thread access
  // The aActF hols where the read request came from so that it can be returned to the proper requester
  // This logic may need revisiting if/when write responses are used

  rule request_portA;
    let req = reqAF.first; reqAF.deq; cpReqF.enq(req); 
    if (req matches tagged ReadRequest .r) aActF.enq(True);
  endrule

  rule request_portB;
    let req = reqBF.first; reqBF.deq; cpReqF.enq(req);
    if (req matches tagged ReadRequest .r) aActF.enq(False);
  endrule

  rule response_cp;  // Only Reads have Responses
    let resp = cpRespF.first; cpRespF.deq; 
    if (aActF.first) respAF.enq(resp); 
    else             respBF.enq(resp);
    aActF.deq;
  endrule


  interface Server serverA;                 // Facing the Fabric (e.g. PCIe, Ethernet, NoC)
    interface request  = toPut(reqAF);
    interface response = toGet(respAF);
  endinterface
  interface Server serverB;                 // Facing the Fabric (e.g. PCIe, Ethernet, NoC)
    interface request  = toPut(reqBF);
    interface response = toGet(respBF);
  endinterface
  interface Client client;                  // Facing the Control Plane
    interface request  = toGet(cpReqF);
    interface response = toPut(cpRespF);
  endinterface
endmodule


