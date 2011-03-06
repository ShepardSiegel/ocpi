// TagCAM.bsv - Tag Content Addressable Memory
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

// This is a brute-force implemenation intended for a relatively small (e.g. 4) slot reservation of rid values.

package TagCAM;

import FIFO    ::*;
import GetPut  ::*;
import Vector  ::*;

typedef struct {
  Bit#(8)  tag;
  Bit#(16) rid;
} TagVal deriving (Bits,Eq);

interface TagCAMIfc;
  method Action                 commit    (TagVal  tv);     // Commit the tag/rid to an open slot 
  method ActionValue#(Bool)     testMatch (Bit#(8) ttag);   // Test if the ttag matches a valid entry         
  method ActionValue#(Bit#(16)) lookup    (Bit#(8) ltag);   // Return the rid for a matching ltag argument
endinterface

module mkTagCAM (TagCAMIfc);
  Vector#(4,Reg#(Maybe#(TagVal))) cam  <- replicateM(mkReg(tagged Invalid));

  Bool noVacancy = isValid(cam[0]) && isValid(cam[1]) && isValid(cam[2]) && isValid(cam[3]);

  function Bool tagMatch(Vector#(4,Reg#(Maybe#(TagVal))) c, Bit#(8) t);
    Bool rval = False;
    for (Integer i=0; i<4; i=i+1) rval = rval || (isValid(c[i]) && fromMaybe(unpack(0),cam[i]).tag==t);
    return(rval);
  endfunction

  function UInt#(2) findMatch(Vector#(4,Reg#(Maybe#(TagVal))) c, Bit#(8) t);
    UInt#(2) mval = 0;
    for (Integer i=0; i<4; i=i+1) if (isValid(c[i]) && fromMaybe(unpack(0),cam[i]).tag==t) mval = fromInteger(i);
    return(mval);
  endfunction

  function UInt#(2) findOpen(Vector#(4,Reg#(Maybe#(TagVal))) c);
    UInt#(2) oval = 0;
    for (Integer i=0; i<4; i=i+1) if (!isValid(c[i])) oval = fromInteger(i);
    return(oval);
  endfunction

  method Action commit (TagVal tv) if(!noVacancy);
    action cam[findOpen(cam)] <= Valid (tv); endaction
  endmethod

  method ActionValue#(Bool) testMatch (Bit#(8) ttag);           
    return(tagMatch(cam, ttag));
  endmethod

  method ActionValue#(Bit#(16)) lookup (Bit#(8) ltag);
    UInt#(2) mval = findMatch(cam,ltag);
    cam[mval] <= tagged Invalid;
    return(fromMaybe(unpack(0),cam[mval]).rid);
  endmethod
endmodule

endpackage: TagCAM
