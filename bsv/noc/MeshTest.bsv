import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;

import MsgFormat :: *;
import MsgXfer   :: *;
import MeshNoC   :: *;
import RandomMsg :: *;

// Set this to control the width of the NoC (values can be 1,2,4,8,16,...)

typedef `BEAT_SIZE_IN_BYTES BytesPerBeat;

// Set this to control the address size used on the NoC

typedef `ADDR_SIZE_IN_BITS AddrSize;

// Set these to control mesh address format

typedef UInt#(2) XLoc;
typedef UInt#(1) YLoc;

Integer min_xloc = 0;
Integer max_xloc = 2;
Integer min_yloc = 0;
Integer max_yloc = 1;

// Pack (x,y) into low bits of NodeID

function Tuple2#(XLoc,YLoc) node_to_xy(NodeID node)
   provisos(Bits#(NodeID,nsz), Bits#(Tuple2#(XLoc,YLoc),lsz), Add#(lsz,padding,nsz));
   return unpack(truncate(pack(node)));
endfunction

function NodeID xy_to_node(XLoc x, YLoc y)
   provisos(Bits#(NodeID,nsz), Bits#(Tuple2#(XLoc,YLoc),lsz), Add#(lsz,padding,nsz));
   return unpack(extend(pack(tuple2(x,y))));
endfunction

// choose destinations among allowed addresses
function NodeID mk_dest(Bit#(8) rv)
   provisos(Bits#(NodeID,nsz), Bits#(Tuple2#(XLoc,YLoc),lsz), Add#(lsz,padding,8), Ord#(XLoc), Ord#(YLoc));
   Tuple2#(XLoc,YLoc) loc1 = unpack(rv[2:0]);
   Tuple2#(XLoc,YLoc) loc2 = unpack(rv[7:5]);
   Tuple2#(XLoc,YLoc) loc3 = unpack(rv[4:2]);
   let {x1,y1} = loc1;
   let {x2,y2} = loc2;
   let {x3,y3} = loc3;
   XLoc x;
   YLoc y;
   if (x1 >= fromInteger(min_xloc) && x1 <= fromInteger(max_xloc))
      x = x1;
   else if (x2 >= fromInteger(min_xloc) && x2 <= fromInteger(max_xloc))
      x = x2;
   else if (x3 >= fromInteger(min_xloc) && x3 <= fromInteger(max_xloc))
      x = x3;
   else
      x = fromInteger(min_xloc);
   if (y1 >= fromInteger(min_yloc) && y1 <= fromInteger(max_yloc))
      y = y1;
   else if (y2 >= fromInteger(min_yloc) && y2 <= fromInteger(max_yloc))
      y = y2;
   else if (y3 >= fromInteger(min_yloc) && y3 <= fromInteger(max_yloc))
      y = y3;
   else
      y = fromInteger(min_yloc);
   return xy_to_node(x,y);
endfunction

// Set this to control how long the test runs

UInt#(32) run_cycles = 1000000;

// synthesizable random message source

(* synthesize *)
module mkSource#( Bit#(32)  seed
                , NodeID    this_node
                , UInt#(7)  last_segment_prob
                , UInt#(14) max_read_length
                , UInt#(10) max_delay
                )
                ( MsgSource#(BytesPerBeat,AddrSize) );
   let _m <- mkSource_(seed, this_node, mk_dest, last_segment_prob, max_read_length, max_delay, run_cycles);
   return _m;
endmodule: mkSource

// synthesizable message sink

(* synthesize *)
module mkSink#( NodeID this_node )
              ( MsgSink#(BytesPerBeat,AddrSize) );
   let _m <- mkSink_(this_node);
   return _m;
endmodule: mkSink

// synthesizable switch

(* synthesize *)
module mkSwitch#(XLoc x, YLoc y)(MeshSwitch#(BytesPerBeat,AddrSize));
   let _m <- mkMeshSwitch(mkFifoMsgSink, mkFifoMsgSource, node_to_xy, xy_to_node(x,y));
   return _m;
endmodule

// Top-level test module

(* synthesize *)
module mkMeshTest();

   // node (0,0)
   MsgSource#(BytesPerBeat,AddrSize) src_0_0 <- mkSource(32'hc001cafe, xy_to_node(0,0), 60, 200, 100);
   MsgSink#(BytesPerBeat,AddrSize)   snk_0_0 <- mkSink(xy_to_node(0,0));

   // node (0,1)
   MsgSource#(BytesPerBeat,AddrSize) src_0_1 <- mkSource(32'h12345678, xy_to_node(0,1), 85, 100, 175);
   MsgSink#(BytesPerBeat,AddrSize)   snk_0_1 <- mkSink(xy_to_node(0,1));

   // node (1,0)
   MsgSource#(BytesPerBeat,AddrSize) src_1_0 <- mkSource(32'h0abc0def, xy_to_node(1,0), 55, 40, 300);
   MsgSink#(BytesPerBeat,AddrSize)   snk_1_0 <- mkSink(xy_to_node(1,0));

   // node (1,1)
   MsgSource#(BytesPerBeat,AddrSize) src_1_1 <- mkSource(32'h00f1fee1, xy_to_node(1,1), 70, 120, 130);
   MsgSink#(BytesPerBeat,AddrSize)   snk_1_1 <- mkSink(xy_to_node(1,1));

   // node (2,0)
   MsgSource#(BytesPerBeat,AddrSize) src_2_0 <- mkSource(32'h1be7b5ce, xy_to_node(2,0), 50, 90, 250);
   MsgSink#(BytesPerBeat,AddrSize)   snk_2_0 <- mkSink(xy_to_node(2,0));

   // node (2,1)
   MsgSource#(BytesPerBeat,AddrSize) src_2_1 <- mkSource(32'haabbccdd, xy_to_node(2,1), 80, 400, 300);
   MsgSink#(BytesPerBeat,AddrSize)   snk_2_1 <- mkSink(xy_to_node(2,1));

   Vector#(3,Vector#(2,MsgPort#(BytesPerBeat,AddrSize))) mesh_nodes = replicate(replicate(?));

   mesh_nodes[0][0] = as_port(src_0_0,snk_0_0);
   mesh_nodes[0][1] = as_port(src_0_1,snk_0_1);
   mesh_nodes[1][0] = as_port(src_1_0,snk_1_0);
   mesh_nodes[1][1] = as_port(src_1_1,snk_1_1);
   mesh_nodes[2][0] = as_port(src_2_0,snk_2_0);
   mesh_nodes[2][1] = as_port(src_2_1,snk_2_1);

   mkMeshNetwork(mkSwitch,mesh_nodes);

   Reg#(UInt#(32)) cycles_remaining <- mkReg(run_cycles + 10000);

   rule count_down if (cycles_remaining != 0);
      cycles_remaining <= cycles_remaining - 1;
   endrule

   rule done if (cycles_remaining == 0);
      $finish(0);
   endrule

endmodule: mkMeshTest
