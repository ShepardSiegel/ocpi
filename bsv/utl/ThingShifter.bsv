// ThingShifter.bsv - A Type t orieneted FIFO
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This is a FIFO-like utility that allows a variable number of aligned things of Type t
// to be enqueued at once and a variable number to be dequeued at once.
// Derived from ByteShfter code by Jeff Newbern at Bluespec Inc.

package ThingShifter;

import Vector :: *;

interface ThingShifter#( numeric type width_in,   // width of input     - things of Type t
                         numeric type width_out,  // width of output    - things of Type t
                         numeric type buf_sz,     // capacity of buffer - things of Type t
                         type t);                 // the Type of thing this FIFO/shifter manipulates

  // A count of the space available in the buffer
  (* always_ready *)
  method UInt#(TLog#(TAdd#(buf_sz,1))) space_available();

  // Add up to width_in things to the buffer
  method Action enq(UInt#(TLog#(TAdd#(width_in,1))) count,
                    Vector#(width_in, t)            data);

  // A count of the number of things available in the buffer
  (* always_ready *)
  method UInt#(TLog#(TAdd#(buf_sz,1))) things_available();

  // The first width_out things available from the buffer
  method Vector#(width_out,t) things_out();

  // Retire up to width_out things from the buffer
  method Action deq(UInt#(TLog#(TAdd#(width_out,1))) count);

endinterface: ThingShifter

module mkThingShifter(ThingShifter#(width_in,width_out,buf_sz,t))
  provisos( Log#(TAdd#(width_in,1), count_in)
          , Log#(TAdd#(width_out,1),count_out)
          , Log#(TAdd#(buf_sz,1),   count_buf)
          , Add#(_v0,width_in,buf_sz)  // buf_sz >= width_in
          , Add#(_v1,width_out,buf_sz) // buf_sz >= width_out
          , Bits#(t, st)               // Type of thing t must derive Bits, has size st
          , Add#(TLog#(st),1,cntSize)  // Add 1 to the log of st for cntSize (round up)
          // Things the compiler should be able to figure out, but doesn't...
          , Add#(_v2,TMul#(width_in,st),TMul#(buf_sz,st))
          , Add#(_v3,count_in,count_buf)  // count_buf >= count_in
          , Add#(_v4,count_out,count_buf) // count_buf >= count_out
          );

  Reg#(Vector#(buf_sz,t))      vec         <-  mkReg(replicate(unpack('0)));
  Reg#(UInt#(count_buf))       num_full    <-  mkReg(0);
  Reg#(UInt#(count_buf))       num_empty   <-  mkReg(fromInteger(valueOf(buf_sz)));
  RWire#(UInt#(count_in))      delta_enq   <-  mkRWire();
  RWire#(UInt#(count_out))     delta_deq   <-  mkRWire();
  RWire#(Vector#(width_in,t))  new_data    <-  mkRWire();

  function Bit#(st) mk_mask(UInt#(count_in) n, Integer pos);
    return (fromInteger(pos) < n) ? '1 : '0;
  endfunction

  (* fire_when_enabled, no_implicit_conditions *)
  rule update;
     UInt#(count_out) consumed = fromMaybe(0,delta_deq.wget());
     UInt#(count_in)  supplied = fromMaybe(0,delta_enq.wget());
     num_full  <= num_full  + zeroExtend(supplied) - zeroExtend(consumed);
     num_empty <= num_empty + zeroExtend(consumed) - zeroExtend(supplied);
     UInt#(TAdd#(count_out,cntSize)) shift_amt = fromInteger(valueOf(st)) * zeroExtend(consumed);
     Vector#(buf_sz,t) shifted = unpack(pack(vec) >> shift_amt);
     Vector#(buf_sz,t) added   = unpack('0);
     if (new_data.wget() matches tagged Valid .vin) begin
        UInt#(TAdd#(count_buf,cntSize)) bit_pos = fromInteger(valueOf(st)) * zeroExtend(num_full - zeroExtend(consumed));
        Vector#(width_in,Bit#(st)) mask = genWith(mk_mask(supplied));
        added = unpack(zeroExtend(pack(vin) & pack(mask)) << bit_pos);
     end
     vec <= unpack(pack(added) | pack(shifted));
  endrule

  // count of space available for new things
  method UInt#(count_buf) space_available = num_empty;

  // enq things -- caller must ensure that count <= space_available
  method Action enq(UInt#(count_in) count, Vector#(width_in,t) data) if (num_empty != 0);
    delta_enq.wset(count);
    new_data.wset(data);
  endmethod

  // count of things available in the queue
  method UInt#(count_buf) things_available = num_full;

  // the next batch of things in the queue
  // some things may be invalid, depending on things_available
  method Vector#(width_out,t) things_out() if (num_full != 0);
    return take(vec);
  endmethod

  // deq things -- caller must ensure that count <= things_available
  method Action deq(UInt#(count_out) count) if (num_full != 0);
    delta_deq.wset(count);
  endmethod

endmodule

endpackage: ThingShifter
