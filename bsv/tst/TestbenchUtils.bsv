package TestbenchUtils;

import StmtFSM::*;
export StmtFSM::*;  // send it right back out

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
export StallCntr(..), mkStallCntr;

// this counter is always running..  It is initialized to
// the paramter value and reset to that value when "reset" is called.
// counter decrements if "reset" is not called
// when counter hits 0, then message is printed and called $finish
// this prevents tests from stalling forever
// ie.
//
//   StallCntr cntr <- mkStallCntr;
//   rule didThis;
//       cntr.reset();  // we are still alive!
//   endrule

interface StallCntr;
   method Action reset();
   method Action stop();
   method Bool   stalled();
endinterface

module mkStallCntr#(UInt#(16) limit)( StallCntr );

   Reg#(UInt#(16)) idleCntr <- mkReg(0);
   Reg#(Bool)      run      <- mkReg(True);

   rule bumpCounter;
      idleCntr <= idleCntr + 1; 
   endrule
   
   rule weAreStalled ((idleCntr == limit) || (idleCntr == unpack(-1)));
      $display("STOP: simulation went idle in %m");
      $finish;
   endrule

   method Action reset();
      run <= True;
      idleCntr <= 0;
   endmethod
   
   method Action stop();
      run <= False;
   endmethod

   method Bool stalled();
      return idleCntr == limit;
   endmethod
   
endmodule


//////////////////////////////////////////////////////////////////////
// various types of timeout
typedef enum { TimeoutInfo, TimeoutWarning, TimeoutError } TTimeout deriving(Bits, Eq);

export TTimeout(..);
export timedAction, Counter,  mkCounter;

/////////////////////////////
// create a simple counter, to be used in stmtfsm for timedAction and timedActionAction
// create counter size, when start(val) is called counter counts down to 0
interface Counter#(type td);
   method Action start(td cnt);
   method Bool   done();
endinterface

module mkCounter( Counter#(UInt#(n)) ) provisos( Add#(_xx,2,n) );
   
   Reg#(Maybe#(UInt#(n))) cntr <- mkRegU;

   rule countDown ( cntr matches tagged Valid .val );
      if (val == 0)
         cntr <= Invalid;
      else
         cntr <= Valid( val - 1 );
   endrule

   method Action start(UInt#(n) cnt);
      cntr <= Valid(cnt);
   endmethod

   method Bool   done();
      return isValid( cntr ) == False;
   endmethod
   
endmodule

////////////////////////////////////////
export mkLoopingCounter;
module mkLoopingCounter#(UInt#(n) cmax)( Reg#(UInt#(n)) );
   Reg#(UInt#(n)) cnt <- mkReg(0);

   rule inc;
      if (cnt != cmax)
         cnt <= cnt + 1;
      else
         cnt <= 0;
   endrule

   method _write(UInt#(n) x) = cnt._write(x);
   method _read() = cnt._read();

endmodule


////////////////////////////////////////
// create an action

function Stmt timedAction( Counter#(UInt#(n)) cnt, 
                           UInt#(n) val, 
                           TTimeout ctype,
                           String message,
                           Action normalOp);
   return seq
             cnt.start( val );
      
             action
                (* split *)
                if (cnt.done() == False) begin
                   normalOp;
                end
                else // cnt is done, we timed out!
                   case ( ctype )
                      TimeoutInfo:    $display("info:    %s timeout at ", message, $time);
                      TimeoutWarning: $display("Warning: %s timeout at ", message, $time);
                      TimeoutError:  begin
                                        $display("ERROR: %s timeout at ", message, $time);
                                        $display("ERROR: Stopping simulation...");
                                        $finish;
                                     end
                   endcase
             endaction
          endseq;
endfunction

export timedActionAction;
function Stmt timedActionAction( Counter#(UInt#(n)) cnt, 
                                 UInt#(n) val, 
                                 Action normalOp,
                                 Action timeoutAction);
   return seq
             cnt.start( val );
      
             action
                (* split *)
                if (cnt.done() == False)
                   normalOp;
                else
                   timeoutAction;
             endaction

          endseq;
endfunction

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// for use with filereader.v
export FileReader, mkFileReader;

interface FileReader#(type tx);
   method tx      first();
   method Action  deq();
   method Bool    done();
endinterface

import "BVI" filereader =
  module mkFileReader#(String file)( FileReader#(td) ) provisos(Bits#(td,sizeD));
     default_clock clk(clk);
     default_reset rst_n(rst_n);

     parameter FILE = file;
     parameter  WIDTH = valueof(sizeD);

     method odata first() ready( odata_rdy );
     method       deq()   ready( odata_rdy ) enable ( odata_en );
     method done  done();

     schedule deq  C deq;
     schedule first CF (first,deq);
     schedule (deq,first,done) CF done;
  endmodule

endpackage

