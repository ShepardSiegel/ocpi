package RandomMsg;

import Vector :: *;
import LFSR   :: *;
import GetPut :: *;

import BypassReg :: *;
import MsgFormat :: *;
import MsgXfer   :: *;

// this is a module that sends random messages onto the NoC
module mkSource_#( Bit#(32)  seed
                 , NodeID    this_node
                 , function NodeID gen_destination(Bit#(8) x)
                 , UInt#(7)  last_segment_prob
                 , UInt#(14) max_read_length
                 , UInt#(10) max_delay
                 , UInt#(32) stop_after
                 )
                 ( MsgSource#(bpb,asz) )
   provisos ( Add#(asz,padding,64) // asz <= 64
            , Add#(_v0, 8, asz)    // asz >= 8
            , Add#(1, _v1, TLog#(TAdd#(1, bpb)))
            , Add#(_v2, TLog#(TAdd#(1,bpb)), TLog#(TAdd#(TMul#(bpb,4),1)))
            , Add#(_v3, TMul#(bpb,8), TMul#(TMul#(bpb,4),8)) // compiler couldn't figure this out
            );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkSource", bytes_per_beat, addr_size);

   MsgBuild#(bpb,asz)  msg_build   <- mkMsgBuild();

   LFSR#(Bit#(32))     lfsr        <- mkLFSR_32();
   Reg#(Bool)          seeded      <- mkReg(False);
   PulseWire           used_lfsr   <- mkPulseWireOR();
   Reg#(UInt#(10))     delay       <- mkReg(5);
   PulseWire           reset_delay <- mkPulseWire();

   Reg#(Bool)          start_msg   <- mkReg(False);
   WReg#(NodeID)       dst         <- mkBypassReg(0);
   Reg#(Bool)          last        <- mkReg(True);
   Reg#(UInt#(7))      bytes_left  <- mkReg(0);

   Reg#(NodeID)        beat_dst    <- mkRegU();

   Reg#(UInt#(32)) cycle <- mkReg(0);
   Bool gen_msgs = (cycle != stop_after);

   (* fire_when_enabled, no_implicit_conditions *)
   rule cycle_count if (gen_msgs);
      cycle <= cycle + 1;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule seed_lfsr if (!seeded);
      lfsr.seed(seed);
      seeded <= True;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule advance_lfsr if (seeded && used_lfsr);
      lfsr.next();
   endrule

   function UInt#(n) scale(UInt#(n) lo, UInt#(n) hi, Bit#(m) rv) provisos(Add#(n,_unused,m));
      UInt#(n) range = hi - lo;
      Bit#(n) mask = 0;
      Bool found_one = False;
      for (Integer i = valueOf(n) - 1; i >= 0; i = i - 1) begin
         found_one = found_one || (pack(range)[i] == 1);
         if (found_one)
            mask = mask | (1 << i);
      end
      UInt#(n) candidate = unpack(truncate(pack(rv)) & mask);
      UInt#(n) delta = min(range,candidate);
      return lo + delta;
   endfunction

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_delay if (seeded);
      if (delay != 0) begin
         if (delay == 1)
            start_msg <= gen_msgs;
         delay <= delay - 1;
      end
      else if (reset_delay)
         delay <= scale(1,max_delay,lfsr.value());
   endrule

   rule next_dst if (start_msg);
      Bit#(8) r = lfsr.value()[31:24];
      used_lfsr.send();
      NodeID  _dst_node = gen_destination(r);
      if (_dst_node != this_node) begin
         msg_build.dst(_dst_node);
         dst.bypass(_dst_node);
         start_msg <= False;
         $display("%0t: Sending message from %0d to %0d", $time(), this_node, _dst_node);
      end
   endrule

   rule next_src;
      msg_build.src(this_node);
   endrule

   rule next_msg_type if (seeded);
      MsgType _mt = unpack(lfsr.value()[23:22]);
      used_lfsr.send();
      msg_build.msg_type(_mt);
   endrule

   rule next_read_len if (seeded);
      UInt#(14) _read_len = scale(0, max_read_length, lfsr.value()[15:2]);
      used_lfsr.send();
      msg_build.read_length(_read_len);
   endrule

   rule next_metadata if (seeded);
      Bit#(6) _meta = lfsr.value()[15:10];
      used_lfsr.send();
      msg_build.metadata(_meta);
   endrule

   rule next_addr_at_dst if (seeded);
      UInt#(asz) _addr = truncate(unpack({lfsr.value(),lfsr.value()}));
      used_lfsr.send();
      msg_build.addr_at_dst(_addr);
   endrule

   rule next_addr_at_src if (seeded);
      UInt#(asz) _addr = truncate(unpack({lfsr.value(),lfsr.value()}));
      used_lfsr.send();
      msg_build.addr_at_src(_addr);
   endrule

   rule next_segment_tag if (seeded && (bytes_left == 0));
      Bit#(32) r = lfsr.value();
      used_lfsr.send();
      Bool     _last = unpack(r[14:8]) <= last_segment_prob;
      UInt#(7) _len  = min(unpack(r[6:0]),unpack(r[21:15]));
      msg_build.segment_tag(tagged SegmentTag { end_of_message: _last, length_in_bytes: _len });
      last <= _last;
      bytes_left <= _len;
      // $display("%0t: Segment originating at %0d: last = %b  len = %0d", $time, this_node, _last, _len);
   endrule

   rule next_segment_bytes if (bytes_left != 0);
      Vector#(4,Bit#(8)) rand_bytes = unpack(lfsr.value());
      used_lfsr.send();
      Vector#(bpb,Bool)    mask = replicate(False);
      Vector#(bpb,Bit#(8)) vec = replicate(0);
      for (Integer i = 0; i < valueOf(bpb); i = i + 1) begin
         vec[i]  = rotateBitsBy(rand_bytes[i % 4],fromInteger(i % 8));
         mask[i] = fromInteger(i) < bytes_left;
      end
      msg_build.segment_bytes.put(tuple2(mask,vec));
      if (bytes_left <= fromInteger(valueOf(bpb)))
         bytes_left <= 0;
      else
         bytes_left <= bytes_left - fromInteger(valueOf(bpb));
   endrule

   method src_rdy = msg_build.source.src_rdy;

   method Action dst_rdy(Bool b);
      msg_build.source.dst_rdy(b);
      if (b && msg_build.source.src_rdy()) begin
         MsgBeat#(bpb,asz) beat = msg_build.source.beat();
         NodeID _dst = beat_dst;
         if (msg_build.start_of_message()) begin
            _dst = dst;
            beat_dst <= dst;
         end
         if (msg_build.end_of_message())
            reset_delay.send();
         $display("%0t: (%0d -> %0d) beat = %x", $time(), this_node, _dst, beat);
      end
   endmethod

   method beat = msg_build.source.beat;

endmodule: mkSource_

// this is a module that accepts beats from the NoC

module mkSink_#(NodeID this_node)(MsgSink#(bpb,asz))
   provisos( Add#(asz,padding,64) );  // asz <= 64

   PulseWire          src_ok   <- mkPulseWire();
   PulseWire          got_beat <- mkPulseWire();
   MsgParse#(bpb,asz) mp       <- mkMsgParse();

   (* fire_when_enabled *)
   rule describe_msg_boundaries;
      if (mp.first_beat())
         $display("%0t: Sink %0d is receiving a new message", $time(), this_node);
      if (mp.last_beat())
         $display("%0t: Sink %0d has received a complete message", $time(), this_node);
   endrule

   (* fire_when_enabled *)
   rule describe_msg_src;
      $display("%0t: Sink %0d message comes from %0d", $time(), this_node, mp.src());
   endrule

   (* fire_when_enabled *)
   rule describe_segment;
      SegmentTag stag = mp.segment_tag();
      if (stag.end_of_message)
         $display("%0t: Sink %0d is receiving the final segment of %0d bytes", $time(), this_node, stag.length_in_bytes);
      else
         $display("%0t: Sink %0d is receiving a non-final segment of %0d bytes", $time(), this_node, stag.length_in_bytes);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule advance_mp if (got_beat);
      mp.advance();
   endrule

   method dst_rdy = True;

   method Action src_rdy(Bool b);
      if (b)
         src_ok.send();
   endmethod

   method Action beat(MsgBeat#(bpb,asz) v);
      if (src_ok) begin
         $display("%0t: Sink %0d got beat %x", $time(), this_node, v);
         mp.beat(v);
         got_beat.send();
      end
   endmethod: beat

endmodule: mkSink_

endpackage: RandomMsg
