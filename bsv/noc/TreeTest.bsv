import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;

import MsgFormat :: *;
import MsgXfer   :: *;
import TreeNoC   :: *;
import RandomMsg :: *;

// Set this to control the width of the NoC (values can be 1,2,4,8,16,...)

typedef `BEAT_SIZE_IN_BYTES BytesPerBeat;

// Set this to control the address size used on the NoC

typedef `ADDR_SIZE_IN_BITS AddrSize;

// choose destinations among allowed addresses
function NodeID mk_dest(Bit#(8) rv) provisos(Bits#(NodeID,nsz));
   UInt#(3) n1 = unpack(rv[2:0]);
   UInt#(3) n2 = unpack(rv[7:5]);
   UInt#(3) n3 = unpack(rv[4:2]);
   UInt#(3) n = (n1 != 7) ? n1 : ((n2 != 7) ? n2 : ((n3 != 7) ? n3 : unpack({0,rv[5:4]})));
   NodeID dst = ?;
   case (n)
      0:       dst =  0;
      1:       dst =  1;
      2:       dst =  2;
      3:       dst =  3;
      4:       dst =  5;
      5:       dst =  9;
      6:       dst = 13;
      default: dst =  9; // this should never occur
   endcase
   return dst;
endfunction

// Set this to control how long the test runs

UInt#(32) run_cycles = 1000000;

// synthesizable random message source

(* synthesize *)
module mkSource#( Bit#(32)  seed
                , NodeID    this_node
                , UInt#(7)  last_segment_prob
                , UInt#(14) max_payload_length
                , UInt#(10) max_delay
                )
                ( MsgSource#(BytesPerBeat,AddrSize) );
   let _m <- mkSource_(seed, this_node, mk_dest, last_segment_prob, max_payload_length, max_delay, run_cycles);
   return _m;
endmodule: mkSource

// synthesizable message sink

(* synthesize *)
module mkSink#( NodeID this_node )
              ( MsgSink#(BytesPerBeat,AddrSize) );
   let _m <- mkSink_(this_node);
   return _m;
endmodule: mkSink

// synthesizable switches

(* synthesize *)
module mkSwitch0#(parameter NodeID coordinate)(TreeSwitch#(4,BytesPerBeat,AddrSize));
   let _m <- mkTreeSwitch(mkFifoMsgSink, mkFifoMsgSource, 0, coordinate);
   return _m;
endmodule

(* synthesize *)
module mkSwitch1#(parameter NodeID coordinate)(TreeSwitch#(4,BytesPerBeat,AddrSize));
   let _m <- mkTreeSwitch(mkFifoMsgSink, mkFifoMsgSource, 1, coordinate);
   return _m;
endmodule

// Top-level test module

(* synthesize *)
module mkTreeTest();

   // node 0
   MsgSource#(BytesPerBeat,AddrSize) src_0 <- mkSource(32'hc001cafe, 0, 60, 200, 100);
   MsgSink#(BytesPerBeat,AddrSize)   snk_0 <- mkSink(0);

   // node 1
   MsgSource#(BytesPerBeat,AddrSize) src_1 <- mkSource(32'h12345678, 1, 85, 100, 175);
   MsgSink#(BytesPerBeat,AddrSize)   snk_1 <- mkSink(1);

   // node 2
   MsgSource#(BytesPerBeat,AddrSize) src_2 <- mkSource(32'h0abc0def, 2, 55, 40, 300);
   MsgSink#(BytesPerBeat,AddrSize)   snk_2 <- mkSink(2);

   // node 3
   MsgSource#(BytesPerBeat,AddrSize) src_3 <- mkSource(32'h00f1fee1, 3, 40, 120, 130);
   MsgSink#(BytesPerBeat,AddrSize)   snk_3 <- mkSink(3);

   // node 5
   MsgSource#(BytesPerBeat,AddrSize) src_5 <- mkSource(32'h1be7b5ce, 5, 50, 90, 250);
   MsgSink#(BytesPerBeat,AddrSize)   snk_5 <- mkSink(5);

   // node 9
   MsgSource#(BytesPerBeat,AddrSize) src_9 <- mkSource(32'haabbccdd, 9, 80, 400, 300);
   MsgSink#(BytesPerBeat,AddrSize)   snk_9 <- mkSink(9);

   // node 13
   MsgSource#(BytesPerBeat,AddrSize) src_13 <- mkSource(32'h00112233, 13, 63, 100, 100);
   MsgSink#(BytesPerBeat,AddrSize)   snk_13 <- mkSink(13);

   // make and connect switches manually for now
   TreeSwitch#(4,BytesPerBeat,AddrSize) root <- mkSwitch0(0);
   TreeSwitch#(4,BytesPerBeat,AddrSize) sw_1 <- mkSwitch1(1);

   mkTieOff(root.up);
   mkConnection(root.down[0], as_port(src_0, snk_0));
   mkConnection(root.down[1], sw_1.up);
   mkConnection(root.down[2], as_port(src_2, snk_2));
   mkConnection(root.down[3], as_port(src_3, snk_3));

   mkConnection(sw_1.down[0], as_port(src_1, snk_1));
   mkConnection(sw_1.down[1], as_port(src_5, snk_5));
   mkConnection(sw_1.down[2], as_port(src_9, snk_9));
   mkConnection(sw_1.down[3], as_port(src_13, snk_13));

   Reg#(UInt#(32)) cycles_remaining <- mkReg(run_cycles + 10000);

   rule count_down if (cycles_remaining != 0);
      cycles_remaining <= cycles_remaining - 1;
   endrule

   rule done if (cycles_remaining == 0);
      $finish(0);
   endrule

endmodule: mkTreeTest
