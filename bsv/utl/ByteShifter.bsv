// ByteShifter.bsv - A Byte orieneted FIFO
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// This is a FIFO-like utility that allows a variable number of aligned Bytes
// to be enqueued at once and a variable number to be dequeued.

// Derived from code by Jeff Newbern at Bluespec Inc.

package ByteShifter;

import Vector :: *;

interface ByteShifter#( numeric type width_in,   // width of input  in Bytes
                        numeric type width_out,  // width of output in Bytes
                        numeric type buf_sz);    // capacity of buffer in Bytes

  // A count of the space available in the buffer
  (* always_ready *)
  method UInt#(TLog#(TAdd#(buf_sz,1))) space_available();

  // Add up to width_in bytes to the buffer
  method Action enq(UInt#(TLog#(TAdd#(width_in,1))) count,
                    Vector#(width_in,Bit#(8))       data);

  // A count of the number of bytes available in the buffer
  (* always_ready *)
  method UInt#(TLog#(TAdd#(buf_sz,1))) bytes_available();

  // The first width_out bytes available from the buffer
  method Vector#(width_out,Bit#(8)) bytes_out();

  // Retire up to width_out bytes from the buffer
  method Action deq(UInt#(TLog#(TAdd#(width_out,1))) count);

endinterface: ByteShifter

module mkByteShifter(ByteShifter#(width_in,width_out,buf_sz))
  provisos( Log#(TAdd#(width_in,1),count_in)
          , Log#(TAdd#(width_out,1),count_out)
          , Log#(TAdd#(buf_sz,1),count_buf)
          , Add#(_v0,width_in,buf_sz)  // buf_sz >= width_in
          , Add#(_v1,width_out,buf_sz) // buf_sz >= width_out
          // Things the compiler should be able to figure out, but doesn't
          , Add#(_v2,TMul#(width_in,8),TMul#(buf_sz,8))
          , Add#(_v3,count_in,count_buf)  // count_buf >= count_in
          , Add#(_v4,count_out,count_buf) // count_buf >= count_out
          );

  Reg#(Vector#(buf_sz,Bit#(8)))       vec         <-  mkReg(replicate('0));
  Reg#(UInt#(count_buf))              num_full    <-  mkReg(0);
  Reg#(UInt#(count_buf))              num_empty   <-  mkReg(fromInteger(valueOf(buf_sz)));
  RWire#(UInt#(count_in))             delta_enq   <-  mkRWire();
  RWire#(UInt#(count_out))            delta_deq   <-  mkRWire();
  RWire#(Vector#(width_in,Bit#(8)))   new_data    <-  mkRWire();

  function Bit#(8) mk_mask(UInt#(count_in) n, Integer pos);
    return (fromInteger(pos) < n) ? '1 : '0;
  endfunction

  (* fire_when_enabled, no_implicit_conditions *)
  rule update;
     UInt#(count_out) consumed = fromMaybe(0,delta_deq.wget());
     UInt#(count_in)  supplied = fromMaybe(0,delta_enq.wget());
     num_full  <= num_full  + zeroExtend(supplied) - zeroExtend(consumed);
     num_empty <= num_empty + zeroExtend(consumed) - zeroExtend(supplied);
     UInt#(TAdd#(count_out,3)) shift_amt = 8 * zeroExtend(consumed);
     Vector#(buf_sz,Bit#(8)) shifted = unpack(pack(vec) >> shift_amt);
     Vector#(buf_sz,Bit#(8)) added   = unpack('0);
     if (new_data.wget() matches tagged Valid .vin) begin
        UInt#(TAdd#(count_buf,3)) bit_pos = 8 * zeroExtend(num_full - zeroExtend(consumed));
        Vector#(width_in,Bit#(8)) mask = genWith(mk_mask(supplied));
        added = unpack(zeroExtend(pack(vin) & pack(mask)) << bit_pos);
     end
     vec <= unpack(pack(added) | pack(shifted));
  endrule

  // count of space available for new bytes
  method UInt#(count_buf) space_available = num_empty;

  // enq bytes -- caller must ensure that count <= space_available
  method Action enq(UInt#(count_in) count, Vector#(width_in,Bit#(8)) data) if (num_empty != 0);
    delta_enq.wset(count);
    new_data.wset(data);
  endmethod

  // count of bytes available in the queue
  method UInt#(count_buf) bytes_available = num_full;

  // the next batch of bytes in the queue
  // some bytes may be invalid, depending on bytes_available
  method Vector#(width_out,Bit#(8)) bytes_out() if (num_full != 0);
    return take(vec);
  endmethod

  // deq bytes -- caller must ensure that count <= bytes_available
  method Action deq(UInt#(count_out) count) if (num_full != 0);
    delta_deq.wset(count);
  endmethod

endmodule

endpackage: ByteShifter
