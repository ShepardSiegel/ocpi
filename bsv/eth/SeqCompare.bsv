// SeqCompare.bsv - Sequential Comparator
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package SeqCompare;

import Vector ::*;

interface SeqCompareIfc;
  method Action addr (Bit#(48) a);
  method Action data (Bit#(8)  d);
  method ActionValue#(Bool) isMatch();
endinterface

(* synthesize *)
module mkSeqCompare (SeqCompareIfc);
  Wire#(Bit#(48))    addrW         <- mkWire;
  Reg#(UInt#(3))     bytesMatched  <- mkReg(0);
  Vector#(6,Bit#(8)) addrV = reverse(unpack(addrW));

  method Action addr (Bit#(48) a) = addrW._write(a);
  method Action data (Bit#(8)  d);
    bytesMatched <= (d == addrV[bytesMatched]) ? bytesMatched + 1 : 0 ;
  endmethod
  method ActionValue#(Bool) isMatch();
    bytesMatched <= 0;
    return (bytesMatched == 6);
  endmethod
endmodule: mkSeqCompare 

endpackage: SeqCompare
