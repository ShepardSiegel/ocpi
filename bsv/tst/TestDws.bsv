// TestDws - test the DwordShifter

import Vector       :: *;
import StmtFSM      :: *;
import DwordShifter :: *;

module mkTestDws (Empty);

 DwordShifter#(4,4,8) dutDws    <- mkDwordShifter;
 Reg#(Bool)           starting  <- mkReg(True);
 Reg#(UInt#(32))      tbcnt     <- mkReg(0);

 Vector#(4, Bit#(32)) v = ?;
 v[0] = 32'h76543210;
 v[1] = 32'hFEDCBA98;
 v[2] = 32'hcafef00d;
 v[3] = 32'hdeadbeef;

 Stmt testSeq =
 (seq
   dutDws.enq(4, v);
   dutDws.enq(2, v);
   dutDws.enq(2, v);
   dutDws.enq(1, v);
   dutDws.enq(1, v);
   dutDws.enq(1, v);
   dutDws.enq(1, v);
 endseq);
 FSM tseq <- mkFSM(testSeq);

 rule start_sm (starting);
   starting <= False;
   tseq.start;
 endrule

 rule every;
   tbcnt <= tbcnt + 1;
 endrule

 rule endit (tbcnt == 50);
   $finish;
 endrule

 rule consume (dutDws.dwords_available >= 4);
   $display("[%0d]: %m: dwords_available:%d dwords_out:%032x", 
     $time, dutDws.dwords_available, dutDws.dwords_out);
   dutDws.deq(4);
 endrule
   

endmodule
