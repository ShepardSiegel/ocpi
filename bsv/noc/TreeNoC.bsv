package TreeNoC;

// This is an implementation of a k-ary tree NoC.

import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;

import MsgFormat :: *;
import MsgXfer   :: *;
import LRU       :: *;

/* The tree is a collection of switches, each connected to its
 * descendents. All switches except the root are connected to an
 * ancestor.
 *
 * The descendent ports on a switch are numbered sequentially
 * starting from 0. A level is defined for each switch based
 * on its distance for the root. The root is at level 0, its
 * immediate descendents are at level 1, their immediate
 * descendants are at level 2, and so on. For any path from
 * the root to a leaf, let the port number by which that path
 * exits level n be called p_n. Then the polynomial:
 *   p_0 + p_1 * k + p_2 * k^2 + ...
 * uniquely assigns a number to each leaf. This number is
 * used as the coordinate for routing. When k is a power of 2,
 * hardware manipulations of this polynomial are efficient.
 *
 * Messages are routed by testing the destination NodeID against
 * the switch coordinate to determine if the destination is in
 * one of the switch's subtrees or if it must be routed up through
 * the switch's ancestor.
 *
 * Example 4-ary switch port:
 *
 *                           UP
 *                          ^  |
 *                          |  V
 *                    +---------------+
 *                    |               |
 *                --->|               |--->
 *              3     |     switch    |     0
 *                <---|               |<---
 *                    |               |
 *                    +---------------+
 *                        ^ |   ^ |
 *                        | V   | V
 *                         2     1
 */

interface TreeSwitch#(numeric type k, numeric type bpb, numeric type asz);
   interface Vector#(k,MsgPort#(bpb,asz)) down;
   interface MsgPort#(bpb,asz)            up;
endinterface: TreeSwitch

module mkTreeSwitch#( module#(FifoMsgSink#(bpb,asz))   mk_fsink
                    , module#(FifoMsgSource#(bpb,asz)) mk_fsource
                    , Integer level
                    , NodeID coordinate
                    )
                    ( TreeSwitch#(k,bpb,asz) )
   provisos( Add#(_,8,TMul#(8,bpb)), Add#(k,1,k_plus_1), Add#(asz,p,64) );

   Integer addr_size = valueOf(asz);
   if (addr_size != 32 && addr_size != 64) begin
      errorM("mkTreeSwitch: addr_size must be either 32 or 64.");
   end

   // Routing is entirely encapsulated in this function.

   Integer up_idx = valueOf(k);

   function Bool route_to(Integer port, NodeID dst);
      // If the destination % k^level matches this coordinate,
      // then the destination is in a subtree of this switch.
      // To determine which subtree it is in, compute
      // (destination / k^level) % k.
      UInt#(8) prefix = unpack(pack(dst)) % fromInteger(valueOf(k) ** level);
      Bool is_below = (pack(prefix) == pack(coordinate));
      UInt#(8) subtree = (unpack(pack(dst)) / fromInteger(valueOf(k) ** level)) % fromInteger(valueOf(k));
      if (port == up_idx)
         return !is_below;
      else
         return is_below && (subtree == fromInteger(port));
   endfunction: route_to

   // message ports
   Vector#(k,FifoMsgSink#(bpb,asz))   from_below <- replicateM(mk_fsink);
   Vector#(k,FifoMsgSource#(bpb,asz)) to_below   <- replicateM(mk_fsource);
   FifoMsgSink#(bpb,asz)              from_above <- mk_fsink();
   FifoMsgSource#(bpb,asz)            to_above   <- mk_fsource();

   /* The implementation of the switch follows a regular pattern.
    * Every input port has an associated MsgParse module to
    * announce the first and last beat of each message passing
    * through the port. Every output port has an LRU module to
    * arbitrate access to the output port.
    */

   // track messages coming in from each port
   Vector#(k,MsgParse#(bpb,asz)) below_mp <- replicateM(mkMsgParse);
   MsgParse#(bpb,asz)            above_mp <- mkMsgParse();

   // arbitrate access to send out each port
   Vector#(k,LRU#(k)) below_lru <- replicateM(mkLRU);
   LRU#(k)            above_lru <- mkLRU();

   // Send beats to the message parsers for each port

   for (Integer s = 0; s < valueOf(k); s = s + 1) begin
      (* fire_when_enabled, no_implicit_conditions *)
      rule parse_below if (!from_below[s].empty());
         below_mp[s].beat(from_below[s].first());
      endrule
   end

   (* fire_when_enabled, no_implicit_conditions *)
   rule parse_above if (!from_above.empty());
      above_mp.beat(from_above.first());
   endrule

   /* We maintain matrices to track for each (input port,
    * output port) pair whether the input port is ready to
    * start sending a message to the output port and whether the
    * input port is already sending a message to the output port.
    *
    * The start_xfer matrix entries are True when the input has a
    * valid beat, that beat is the first beat in a message,
    * and the destination of the message requires it
    * to be routed out the output port.
    *
    * The continue_xfer matrix entries are set to True after the first
    * beat in the message and stay set until the last beat of the
    * message has been moved to the output port.
    *
    * In these matrices, the indices 0 through k-1 represent the
    * descendent ports, and the index k represents the ancestor
    * port.
    */
   Vector#(k_plus_1,Vector#(k_plus_1,Bool))       start_xfer    =  replicate(replicate(False));
   Vector#(k_plus_1,Vector#(k_plus_1,Reg#(Bool))) continue_xfer <- replicateM(replicateM(mkReg(False)));

   for (Integer s = 0; s < valueOf(k); s = s + 1) begin
      for (Integer d = 0; d < valueOf(k); d = d + 1) begin
         if (d == s) begin
            start_xfer[s][d] = False;
         end
         else begin
            start_xfer[s][d] = below_mp[s].first_beat()
                            && !from_below[s].empty()
                            && route_to(d,from_below[s].first()[7:0])
                             ;
         end
      end //for
      start_xfer[s][up_idx] = below_mp[s].first_beat()
                           && !from_below[s].empty()
                           && route_to(up_idx,from_below[s].first()[7:0])
                            ;
   end // for
   for (Integer d = 0; d < valueOf(k); d = d + 1) begin
      start_xfer[up_idx][d] = above_mp.first_beat()
                           && !from_above.empty()
                           && route_to(d,from_above.first()[7:0])
                            ;
   end // for

   /* If any start_xfer[*][d] is True it indicates that there is
    * a new message ready to use the d output port. If any
    * continue_xfer[*][d] is True it indicates that the d output
    * port is busy transmitting an existing message.
    *
    * There is an arbitration rule for each output port. When the
    * port is needed and not busy, all inputs that have messages
    * ready for the port request access.
    */
   Vector#(k_plus_1,Bool) outport_is_needed = fold(zipWith(\|| ),start_xfer);
   Vector#(k_plus_1,Bool) outport_is_busy   = fold(zipWith(\|| ),map(readVReg,continue_xfer));

   for (Integer d = 0; d < valueOf(k); d = d + 1) begin

      (* fire_when_enabled, no_implicit_conditions *)
      rule arbitrate_below if (outport_is_needed[d] && !outport_is_busy[d]);
         Integer ch = 0;
         for (Integer s = 0; s <= valueOf(k); s = s + 1) begin
            if (s != d) begin
               if (start_xfer[s][d]) below_lru[d].channel[ch].request();
               ch = ch + 1;
            end
         end
         below_lru[d].enable();
      endrule: arbitrate_below

   end // for

   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_above if (outport_is_needed[up_idx] && !outport_is_busy[up_idx]);
      for (Integer s = 0; s < valueOf(k); s = s + 1) begin
         if (start_xfer[s][up_idx]) above_lru.channel[s].request();
      end
      above_lru.enable();
   endrule: arbitrate_above

   /* This function moves a single beat from an input port to an
    * output port. It will be called once for each allowed input-
    * output port connection. The arbitration and one-hot nature
    * of the continue_xfer[s][d] signals ensures that no calls
    * of the function which conflict will be active in the same
    * clock cycle.
    */

   function Action move_beat(Integer s, Integer d);
      action
         FifoMsgSink#(bpb,asz)   inport    = (s == valueOf(k)) ? from_above : from_below[s];
         FifoMsgSource#(bpb,asz) outport   = (d == valueOf(k)) ? to_above   : to_below[d];
         Reg#(Bool)              cont_xfer = asIfc(continue_xfer[s][d]);
         MsgParse#(bpb,asz)      mp        = (s == valueOf(k)) ? above_mp   : below_mp[s];

         MsgBeat#(bpb,asz) beat = inport.first();
         inport.deq();
         outport.enq(beat);
         mp.advance();
         if (mp.last_beat())
            cont_xfer <= False;
         else if (mp.first_beat())
            cont_xfer <= True;
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
    * be bipartite, and therefore the xfer_* rules
    * below are conflict free.
    */

   Rules xfer_rules = emptyRules;

   for (Integer d = 0; d < valueOf(k); d = d + 1) begin

      Rules another_xfer_rule = rules
         (* fire_when_enabled *)
         rule xfer_to_below if (outport_is_needed[d] || outport_is_busy[d]);
            Integer ch = 0;
            // this is only needed to satisy bsc that only one move_beat call
            // will occur with a given destination per clock cycle
            Bool moved = False;
            for (Integer s = 0; s < valueOf(k); s = s + 1) begin
               if (s != d) begin
                  if (  (!outport_is_busy[d] && below_lru[d].channel[ch].grant())
                     || (continue_xfer[s][d] && !from_below[s].empty())
                     )
                  begin
                     if (!moved) begin
                        move_beat(s,d);
                        moved = True;
                     end
                  end
                  ch = ch + 1;
               end
            end
            if (  (!outport_is_busy[d] && below_lru[d].channel[valueOf(k)-1].grant())
               || (continue_xfer[up_idx][d] && !from_above.empty())
               )
               if (!moved) move_beat(up_idx,d);
         endrule: xfer_to_below
      endrules;

      xfer_rules = rJoinConflictFree(xfer_rules, another_xfer_rule);

   end // for

   Rules yet_another_xfer_rule = rules
      (* fire_when_enabled *)
      rule xfer_to_above if (outport_is_needed[up_idx] || outport_is_busy[up_idx]);
         // this is only needed to satisy bsc that only one move_beat call
         // will occur with a given destination per clock cycle
         Bool moved = False;
         for (Integer s = 0; s < valueOf(k); s = s + 1) begin
            if (  (!outport_is_busy[up_idx] && above_lru.channel[s].grant())
               || (continue_xfer[s][up_idx] && !from_below[s].empty())
               )
            begin
               if (!moved) begin
                  move_beat(s,up_idx);
                  moved = True;
               end
            end
         end
      endrule: xfer_to_above
   endrules;

   xfer_rules = rJoinConflictFree(xfer_rules, yet_another_xfer_rule);

   addRules(xfer_rules);

   // assemble the interface

   interface down  = zipWith(as_port, map(get_source_ifc,to_below), map(get_sink_ifc,from_below));
   interface up    = as_port(to_above.source, from_above.sink);

endmodule: mkTreeSwitch

endpackage: TreeNoC
