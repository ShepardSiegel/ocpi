package MeshNoC;

// This is an implementation of a 2D mesh NoC.

import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;

import MsgFormat :: *;
import MsgXfer   :: *;
import LRU       :: *;

/* The mesh is a collection of switches, each connected to (up to) 4
 * neighbors and 1 processing node. Each switch has a unique (X,Y)
 * coordinate within the mesh. The switch implements X-Y routing,
 * in which messages first route in the X direction and then the
 * Y direction. This is a simple deadlock-free mechanism for
 * wormhole routing.
 *
 *                ----      North
 *           Node     \    ^     |
 *                <--  V   |     V
 *                   \+---------------+
 *                    |               |
 *                --->|               |--->
 *           West     |     switch    |     East
 *                <---|               |<---
 *                    |               |
 *                    +---------------+
 *                         ^     |
 *                         |     V
 *                          South
 */

interface MeshSwitch#(numeric type bpb, numeric type asz);
   interface MsgPort#(bpb,asz) north;
   interface MsgPort#(bpb,asz) east;
   interface MsgPort#(bpb,asz) west;
   interface MsgPort#(bpb,asz) south;
   interface MsgPort#(bpb,asz) node;
endinterface: MeshSwitch

/* The switch module is a higher-order module that takes module
 * parameters for creating the source and sink FIFOs. These are
 * parameterized because different target parts have differing
 * support for efficient FIFO structures.
 *
 * Finally, the module takes a function to interpret NodeIDs as
 * (X,Y) coordinates and the NodeID of its attached node.
 */
module mkMeshSwitch#( module#(FifoMsgSink#(bpb,asz))   mk_fsink
                    , module#(FifoMsgSource#(bpb,asz)) mk_fsource
                    , function Tuple2#(xloc,yloc) node_to_xy(NodeID node)
                    , NodeID this_node
                    )
                    ( MeshSwitch#(bpb,asz) )
   provisos( Add#(_,8,TMul#(8,bpb)), Add#(asz,p,64)
           , Eq#(xloc), Ord#(xloc), Bits#(xloc,xsz)
           , Eq#(yloc), Ord#(yloc), Bits#(yloc,ysz)
           );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);
   check_msg_type_params("mkMeshSwitch", bytes_per_beat, addr_size);

   let {this_x,this_y} = node_to_xy(this_node);

   // message ports
   FifoMsgSink#(bpb,asz)   north_in  <- mk_fsink();
   FifoMsgSource#(bpb,asz) north_out <- mk_fsource();
   FifoMsgSink#(bpb,asz)   east_in   <- mk_fsink();
   FifoMsgSource#(bpb,asz) east_out  <- mk_fsource();
   FifoMsgSink#(bpb,asz)   west_in   <- mk_fsink();
   FifoMsgSource#(bpb,asz) west_out  <- mk_fsource();
   FifoMsgSink#(bpb,asz)   south_in  <- mk_fsink();
   FifoMsgSource#(bpb,asz) south_out <- mk_fsource();
   FifoMsgSink#(bpb,asz)   node_in   <- mk_fsink();
   FifoMsgSource#(bpb,asz) node_out  <- mk_fsource();

   /* The implementation of the switch follows a regular pattern.
    * Every input port has an associated MsgRoute module to
    * announce the first and last beat of each message passing
    * through the port. Every output port has an LRU module to
    * arbitrate access to the output port.
    *
    * The implementation elements always follow the NEWS + node
    * pattern, which highlights the regularity of the structure and
    * makes it easier to get the patterns right.
    */

   // track messages coming in from each port
   MsgRoute#(bpb,asz) north_mr <- mkMsgRoute();
   MsgRoute#(bpb,asz) east_mr  <- mkMsgRoute();
   MsgRoute#(bpb,asz) west_mr  <- mkMsgRoute();
   MsgRoute#(bpb,asz) south_mr <- mkMsgRoute();
   MsgRoute#(bpb,asz) node_mr  <- mkMsgRoute();

   // arbitrate access to send out each port
   LRU#(4) north_lru <- mkLRU();
   LRU#(2) east_lru  <- mkLRU(); // only node and west can send east
   LRU#(2) west_lru  <- mkLRU(); // only node and east can send west
   LRU#(4) south_lru <- mkLRU();
   LRU#(4) node_lru  <- mkLRU();

   // Send beats to the message parsers for each port.

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_north if (!north_in.empty());
      north_mr.beat(north_in.first());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_east if (!east_in.empty());
      east_mr.beat(east_in.first());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_west if (!west_in.empty());
      west_mr.beat(west_in.first());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_south if (!south_in.empty());
      south_mr.beat(south_in.first());
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_node if (!node_in.empty());
      node_mr.beat(node_in.first());
   endrule

   // destinations (don't use *_mr.dst() because we want any implicit conditions on these)
   let {north_x,north_y} = node_to_xy(unpack(truncate(north_in.first())));
   let {east_x,east_y}   = node_to_xy(unpack(truncate(east_in.first())));
   let {west_x,west_y}   = node_to_xy(unpack(truncate(west_in.first())));
   let {south_x,south_y} = node_to_xy(unpack(truncate(south_in.first())));
   let {node_x,node_y}   = node_to_xy(unpack(truncate(node_in.first())));

   /* For each allowed combination of input port and output port
    * there is a start_<in>_to_<out> signal and a
    * continue_<in>_to_<out> register. The start signal is asserted
    * when the input has a valid beat, that beat is the first beat
    * in a message, and the destination of the message requires it
    * to be routed out the output port. The continue register is
    * set to True after the first beat in the message and stays
    * set until the last beat of the message has been moved to
    * the output port.
    */

   // from N (we know that north_x == this_x && north_y >= this_y)
   Bool start_N_to_S    = north_mr.first_beat()
                       && !north_in.empty()
                       && (north_y != this_y)
                        ;
   Reg#(Bool) continue_N_to_S <- mkReg(False);
   Bool start_N_to_node = north_mr.first_beat()
                       && !north_in.empty()
                       && (north_y == this_y)
                        ;
   Reg#(Bool) continue_N_to_node <- mkReg(False);

   // from E (we know that east_x <= this_x)
   Bool start_E_to_N    = east_mr.first_beat()
                       && !east_in.empty()
                       && (east_x == this_x)
                       && (east_y < this_y)
                        ;
   Reg#(Bool) continue_E_to_N <- mkReg(False);
   Bool start_E_to_W    = east_mr.first_beat()
                       && !east_in.empty()
                       && (east_x != this_x)
                        ;
   Reg#(Bool) continue_E_to_W <- mkReg(False);
   Bool start_E_to_S    = east_mr.first_beat()
                       && !east_in.empty()
                       && (east_x == this_x)
                       && (east_y > this_y)
                        ;
   Reg#(Bool) continue_E_to_S <- mkReg(False);
   Bool start_E_to_node = east_mr.first_beat()
                       && !east_in.empty()
                       && (east_x == this_x)
                       && (east_y == this_y)
                        ;

   Reg#(Bool) continue_E_to_node <- mkReg(False);

   // from W (we know that west_x >= this_x)
   Bool start_W_to_N    = west_mr.first_beat()
                       && !west_in.empty()
                       && (west_x == this_x)
                       && (west_y < this_y)
                        ;
   Reg#(Bool) continue_W_to_N <- mkReg(False);
   Bool start_W_to_E    = west_mr.first_beat()
                       && !west_in.empty()
                       && (west_x != this_x)
                        ;
   Reg#(Bool) continue_W_to_E <- mkReg(False);
   Bool start_W_to_S    = west_mr.first_beat()
                       && !west_in.empty()
                       && (west_x == this_x)
                       && (west_y > this_y)
                        ;
   Reg#(Bool) continue_W_to_S <- mkReg(False);
   Bool start_W_to_node = west_mr.first_beat()
                       && !west_in.empty()
                       && (west_x == this_x)
                       && (west_y == this_y)
                        ;
   Reg#(Bool) continue_W_to_node <- mkReg(False);

   // from S (we know that south_x == this_x && south_y <= this_y)
   Bool start_S_to_N    = south_mr.first_beat()
                       && !south_in.empty()
                       && (south_y != this_y)
                        ;
   Reg#(Bool) continue_S_to_N <- mkReg(False);
   Bool start_S_to_node = south_mr.first_beat()
                       && !south_in.empty()
                       && (south_y == this_y)
                        ;
   Reg#(Bool) continue_S_to_node <- mkReg(False);

   // from node (we know that !(node_x == this_x && node_y == this_y))
   Bool start_node_to_N = node_mr.first_beat()
                       && !node_in.empty()
                       && (node_x == this_x)
                       && (node_y < this_y)
                        ;
   Reg#(Bool) continue_node_to_N <- mkReg(False);
   Bool start_node_to_E = node_mr.first_beat()
                       && !node_in.empty()
                       && (node_x > this_x)
                        ;
   Reg#(Bool) continue_node_to_E <- mkReg(False);
   Bool start_node_to_W = node_mr.first_beat()
                       && !node_in.empty()
                       && (node_x < this_x)
                        ;
   Reg#(Bool) continue_node_to_W <- mkReg(False);
   Bool start_node_to_S = node_mr.first_beat()
                       && !node_in.empty()
                       && (node_x == this_x)
                       && (node_y > this_y)
                        ;
   Reg#(Bool) continue_node_to_S <- mkReg(False);

   /* If any start_*_to_<out> is True it indicates that there is
    * a new message ready to use the <out> output port. If any
    * continue_*_to_<out> is True it indicates that the <out> output
    * port is busy transmitting an existing message.
    *
    * There is an arbitration rule for each output port. When the
    * port is needed and not busy, all inputs that have messages
    * ready for the port request access.
    */

   Bool outport_N_is_needed = start_E_to_N    || start_W_to_N    || start_S_to_N    || start_node_to_N;
   Bool outport_N_is_busy   = continue_E_to_N || continue_W_to_N || continue_S_to_N || continue_node_to_N;
   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_N if (outport_N_is_needed && !outport_N_is_busy);
      if (start_E_to_N)    north_lru.channel[0].request();
      if (start_W_to_N)    north_lru.channel[1].request();
      if (start_S_to_N)    north_lru.channel[2].request();
      if (start_node_to_N) north_lru.channel[3].request();
      north_lru.enable();
   endrule: arbitrate_N

   Bool outport_E_is_needed = start_W_to_E    || start_node_to_E;
   Bool outport_E_is_busy   = continue_W_to_E || continue_node_to_E;
   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_E if (outport_E_is_needed && !outport_E_is_busy);
      if (start_W_to_E)    east_lru.channel[0].request();
      if (start_node_to_E) east_lru.channel[1].request();
      east_lru.enable();
   endrule: arbitrate_E

   Bool outport_W_is_needed = start_E_to_W    || start_node_to_W;
   Bool outport_W_is_busy   = continue_E_to_W || continue_node_to_W;
   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_W if (outport_W_is_needed && !outport_W_is_busy);
      if (start_E_to_W)    west_lru.channel[0].request();
      if (start_node_to_W) west_lru.channel[1].request();
      west_lru.enable();
   endrule: arbitrate_W

   Bool outport_S_is_needed = start_N_to_S    || start_E_to_S    || start_W_to_S    || start_node_to_S;
   Bool outport_S_is_busy   = continue_N_to_S || continue_E_to_S || continue_W_to_S || continue_node_to_S;
   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_S if (outport_S_is_needed && !outport_S_is_busy);
      if (start_N_to_S)    south_lru.channel[0].request();
      if (start_E_to_S)    south_lru.channel[1].request();
      if (start_W_to_S)    south_lru.channel[2].request();
      if (start_node_to_S) south_lru.channel[3].request();
      south_lru.enable();
   endrule: arbitrate_S

   Bool outport_node_is_needed = start_N_to_node    || start_E_to_node    || start_W_to_node    || start_S_to_node;
   Bool outport_node_is_busy   = continue_N_to_node || continue_E_to_node || continue_W_to_node || continue_S_to_node;
   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_node if (outport_node_is_needed && !outport_node_is_busy);
      if (start_N_to_node) node_lru.channel[0].request();
      if (start_E_to_node) node_lru.channel[1].request();
      if (start_W_to_node) node_lru.channel[2].request();
      if (start_S_to_node) node_lru.channel[3].request();
      node_lru.enable();
   endrule: arbitrate_node

   /* This function moves a single beat from an input port to an
    * output port. It will be called once for each allowed input-
    * output port connection. The arbitration and one-hot nature
    * of the continue_*_to_<out> signals ensures that no calls
    * of the function which conflict will be active in the same
    * clock cycle.
    */

   function Action move_beat( FifoMsgSink#(bpb,asz) inport
                            , FifoMsgSource#(bpb,asz) outport
                            , Reg#(Bool) continue_xfer
                            , MsgRoute#(bpb,asz) mr
                            );
      action
         MsgBeat#(bpb,asz) beat = inport.first();
         inport.deq();
         outport.enq(beat);
         mr.advance();
         if (mr.last_beat())
            continue_xfer <= False;
         else if (mr.first_beat())
            continue_xfer <= True;
      endaction
   endfunction: move_beat

   /* There is one rule for each output port, to transfer
    * a single beat from any of the allowed input ports to
    * that output port.
    *
    * If the port is not busy but is needed by a new message,
    * then exactly one of the inputs will have been granted
    * access.
    *
    * If the port is busy, then the input node retains the
    * grant until the message completes.
    *
    * The arbitration scheme we employ unsures that the
    * matching of input ports to output ports will always
    * be bipartite, and therefore the xfer_to_<out> rules
    * below are conflict free.
    */

   (* fire_when_enabled *)
   (* conflict_free = "xfer_to_N,xfer_to_E,xfer_to_W,xfer_to_S,xfer_to_node" *)
   rule xfer_to_N if (outport_N_is_needed || outport_N_is_busy);
      if      (  (!outport_N_is_busy && north_lru.channel[0].grant())
              || (continue_E_to_N && !east_in.empty())
              )
         move_beat(east_in,  north_out, continue_E_to_N,    east_mr);
      else if (  (!outport_N_is_busy && north_lru.channel[1].grant())
              || (continue_W_to_N && !west_in.empty())
              )
         move_beat(west_in,  north_out, continue_W_to_N,    west_mr);
      else if (  (!outport_N_is_busy && north_lru.channel[2].grant())
              || (continue_S_to_N && !south_in.empty())
              )
         move_beat(south_in, north_out, continue_S_to_N,    south_mr);
      else if (  (!outport_N_is_busy && north_lru.channel[3].grant())
              || (continue_node_to_N && !node_in.empty())
              )
         move_beat(node_in,  north_out, continue_node_to_N, node_mr);
   endrule: xfer_to_N

   (* fire_when_enabled *)
   rule xfer_to_E if (outport_E_is_needed || outport_E_is_busy);
      if      (  (!outport_E_is_busy && east_lru.channel[0].grant())
              || (continue_W_to_E && !west_in.empty())
              )
         move_beat(west_in,  east_out, continue_W_to_E,     west_mr);
      else if (  (!outport_E_is_busy && east_lru.channel[1].grant())
              || (continue_node_to_E && !node_in.empty())
              )
         move_beat(node_in,  east_out, continue_node_to_E,  node_mr);
   endrule: xfer_to_E

   (* fire_when_enabled *)
   rule xfer_to_W if (outport_W_is_needed || outport_W_is_busy);
      if      (  (!outport_W_is_busy && west_lru.channel[0].grant())
              || (continue_E_to_W && !east_in.empty())
              )
         move_beat(east_in,  west_out, continue_E_to_W,     east_mr);
      else if (  (!outport_W_is_busy && west_lru.channel[1].grant())
              || (continue_node_to_W && !node_in.empty())
              )
         move_beat(node_in,  west_out, continue_node_to_W,  node_mr);
   endrule: xfer_to_W

   (* fire_when_enabled *)
   rule xfer_to_S if (outport_S_is_needed || outport_S_is_busy);
      if      (  (!outport_S_is_busy && south_lru.channel[0].grant())
              || (continue_N_to_S && !north_in.empty())
              )
         move_beat(north_in, south_out, continue_N_to_S,    north_mr);
      else if (  (!outport_S_is_busy && south_lru.channel[1].grant())
              || (continue_E_to_S && !east_in.empty())
              )
         move_beat(east_in,  south_out, continue_E_to_S,    east_mr);
      else if (  (!outport_S_is_busy && south_lru.channel[2].grant())
              || (continue_W_to_S && !west_in.empty())
              )
         move_beat(west_in,  south_out, continue_W_to_S,    west_mr);
      else if (  (!outport_S_is_busy && south_lru.channel[3].grant())
              || (continue_node_to_S && !node_in.empty())
              )
         move_beat(node_in,  south_out, continue_node_to_S, node_mr);
   endrule: xfer_to_S

   (* fire_when_enabled *)
   rule xfer_to_node if (outport_node_is_needed || outport_node_is_busy);
      if      (  (!outport_node_is_busy && node_lru.channel[0].grant())
              || (continue_N_to_node && !north_in.empty())
              )
         move_beat(north_in, node_out,  continue_N_to_node, north_mr);
      else if (  (!outport_node_is_busy && node_lru.channel[1].grant())
              || (continue_E_to_node && !east_in.empty())
              )
         move_beat(east_in,  node_out,  continue_E_to_node, east_mr);
      else if (  (!outport_node_is_busy && node_lru.channel[2].grant())
              || (continue_W_to_node && !west_in.empty())
              )
         move_beat(west_in,  node_out,  continue_W_to_node, west_mr);
      else if (  (!outport_node_is_busy && node_lru.channel[3].grant())
              || (continue_S_to_node && !south_in.empty())
              )
         move_beat(south_in, node_out,  continue_S_to_node, south_mr);
   endrule: xfer_to_node

   // assemble the interface

   interface MsgPort north;
      interface in  = north_in.sink;
      interface out = north_out.source;
   endinterface

   interface MsgPort east;
      interface in  = east_in.sink;
      interface out = east_out.source;
   endinterface

   interface MsgPort west;
      interface in  = west_in.sink;
      interface out = west_out.source;
   endinterface

   interface MsgPort south;
      interface in  = south_in.sink;
      interface out = south_out.source;
   endinterface

   interface MsgPort node;
      interface in  = node_in.sink;
      interface out = node_out.source;
   endinterface

endmodule: mkMeshSwitch

/* This is a utility to automatically create the mesh switch fabric
 * with the correct connections and tie-offs.
 */
module mkMeshNetwork#( function module#(MeshSwitch#(bpb,asz)) mk_switch(xloc x,yloc y)
                     , Vector#(cols,Vector#(rows,MsgPort#(bpb,asz)))  node_matrix
                     )
                     (Empty)
   provisos(Literal#(xloc),Literal#(yloc));

   Vector#(cols,Vector#(rows,MeshSwitch#(bpb,asz))) fabric = replicate(replicate(?));

   // instantiate switches
   for (Integer x = 0; x < valueOf(cols); x = x + 1) begin
      for (Integer y = 0; y < valueOf(rows); y = y + 1) begin
         let _sw <- mk_switch(fromInteger(x),fromInteger(y));
         fabric[x][y] = _sw;
      end
   end

   // connect switches to nodes
   for (Integer x = 0; x < valueOf(cols); x = x + 1) begin
      for (Integer y = 0; y < valueOf(rows); y = y + 1) begin
         mkConnection(fabric[x][y].node.in,  node_matrix[x][y].out);
         mkConnection(fabric[x][y].node.out, node_matrix[x][y].in);
      end
   end

   // connect switches to each other
   for (Integer x = 0; x < valueOf(cols); x = x + 1) begin
      for (Integer y = 0; y < valueOf(rows); y = y + 1) begin
         // north
         if (y == 0)
            mkTieOff(fabric[x][y].north);
         else
            mkConnection(fabric[x][y].north,fabric[x][y-1].south);
         // east
         if (x == valueOf(cols) - 1)
            mkTieOff(fabric[x][y].east);
         else
            mkConnection(fabric[x][y].east,fabric[x+1][y].west);
         // west
         if (x == 0)
            mkTieOff(fabric[x][y].west);
         // south
         if (y == valueOf(rows) - 1)
            mkTieOff(fabric[x][y].south);
      end
   end

endmodule: mkMeshNetwork

endpackage: MeshNoC
