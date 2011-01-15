// BramServer.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED


// !!!NOT YET FUNCTIONAL!!!

package BramServer;

import OCWip::*;

import BRAM::*;
import ClientServer::*; 
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import GetPut::*;
import Vector::*;

interface BramServerIfc;
  interface WmemiES16B   wmemiS;  // The Wmemi slave interface provided to the application
endinterface

(* synthesize *)
module mkBramServer (BramServerIfc);

  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 1024; // Use 10b of address on each 4B BRAM 2^10
    cfg.latency    = 1;
  Vector#(4, BRAM2Port# (HexABits, DWord)) bram <- replicateM(mkBRAM2Server(cfg));
  function   BRAMServer#(HexABits, DWord)  getPortA (Integer i) = bram[i].portA;
  function   BRAMServer#(HexABits, DWord)  getPortB (Integer i) = bram[i].portB;
  Vector#(4, BRAMServer#(HexABits, DWord)) bramsA = genWith(getPortA);
  Vector#(4, BRAMServer#(HexABits, DWord)) bramsB = genWith(getPortB);


  // Put Req
  rule doWriteReq (wrActive);
    Bool lastWordofReq = (bytesRemainReq==extend(wmiByteWidth)); // Is this the last Word of this request?
    let dh <- wmi.dh;                             // Take the Datahandshake bundle from the WMI interface
    Bit#(128) writeWordB16 = zExtend(dh.data);    // Extend dh.data in the 4B and 8B cases; pass 16B unchanged
    Vector#(4,Bit#(32)) vWord = unpack(writeWordB16);  // Stuff 1, 2, or 4 DWORDs into the vWord Vector
    wrtCount <= wrtCount + 1;
    addr     <= addr + extend(wmiByteWidth);
    bytesRemainReq <= bytesRemainReq - extend(wmiByteWidth);
    HexABits bramAddr = truncate(lclMesgAddr>>4) + truncate(addr>>4);
    case (wmiByteWidth)
      4:  action
            let req4  = BRAMRequest { write:True, address:bramAddr, datain:vWord[0], responseOnWrite:False };
            mem[addr[3:2]].request.put(req4); 
          endaction
      8:  action 
            let req8a = BRAMRequest { write:True, address:bramAddr, datain:vWord[0], responseOnWrite:False };
            let req8b = BRAMRequest { write:True, address:bramAddr, datain:vWord[1], responseOnWrite:False };
            mem[{addr[3],1'b0}].request.put(req8a);
            mem[{addr[3],1'b1}].request.put(req8b);
          endaction
      16: action
          for (Integer i=0; i<4; i=i+1) begin
            let req16 = BRAMRequest { write:True, address:bramAddr, datain:vWord[i], responseOnWrite:False };
            mem[i].request.put(req16); 
          end
        endaction
    endcase
  endrule 

  // Get Resp
  rule doReadResp (bytesRemainResp>0);
    Vector#(4,Bit#(32)) vWord = ?;
    case (wmiByteWidth)
      4:  vWord[0] <- mem[p4B].response.get;
      8:  action
          vWord[0] <- mem[{p4B[1],1'b0}].response.get;
          vWord[1] <- mem[{p4B[1],1'b1}].response.get;
          endaction
      16: for (Integer i=0; i<4; i=i+1) vWord[i] <- mem[i].response.get;
    endcase
    Bit#(32)  readWordB4  = pack(vWord[0]);
    Bit#(64)  readWordB8  = pack(take(vWord));
    Bit#(128) readWordB16 = pack(vWord);
    p4B <= p4B + truncate((wmiByteWidth>>2));
    bytesRemainResp <= bytesRemainResp - extend(wmiByteWidth);
    case (wmiByteWidth)
      4:  wmi.respd(zExtend(readWordB4)); 
      8:  wmi.respd(zExtend(readWordB8));
      16: wmi.respd(zExtend(readWordB16));
    endcase
  endrule


  //Wci_Es#(32) wci_Es   <- mkWciStoES(wci.slv);
  WmemiES16B  wmemi_Es <- mkWmemiStoES(wmemi.slv);

  //interface             wci_s   = wci_Es; 
  interface WmemiES16B  wmemiS  = wmemi_Es;

endmodule: mkBramServer

endpackage: BramServer
