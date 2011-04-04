package MsgXfer;

/* Common interfaces to facilitate exchange of messages between
 * nodes and switches in a NoC.
 */

import FIFO        :: *;
import FIFOF       :: *;
import GetPut      :: *;
import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;

import MsgFormat :: *;

export MsgSource(..), MsgSink(..);
export FifoMsgSource(..), mkFifoMsgSource;
export FifoMsgSink(..), mkFifoMsgSink;
export get_source_ifc, get_sink_ifc;
export MsgPort(..), as_port;
export hasNodeID;
export MsgParse(..), MsgParseTC(..);
export MsgBuild(..), MsgBuildTC(..);

/* MsgSource and MsgSink together form two endpoints of a message
 * channel. The message is considered transfered when both the source
 * and the sink assert their ready signals during the same cycle.
 */

// Message source, parameterized by the beat size and address size.
interface MsgSource#(numeric type bytes_per_beat, numeric type addr_size);
   (* always_ready *)
   method Bool src_rdy();
   (* always_ready, always_enabled *)
   method Action dst_rdy(Bool b);
   (* always_ready *)
   method MsgBeat#(bytes_per_beat,addr_size) beat();
endinterface

// Message sink, parameterized by the beat size and address size
interface MsgSink#(numeric type bytes_per_beat, numeric type addr_size);
   (* always_ready *)
   method Bool dst_rdy();
   (* always_ready, always_enabled *)
   method Action src_rdy(Bool b);
   (* always_ready, always_enabled *)
   method Action beat(MsgBeat#(bytes_per_beat,addr_size) v);
endinterface

// MsgSource and MsgSink are connectable if the beat sizes match.

instance Connectable#(MsgSource#(bpb,asz),MsgSink#(bpb,asz));
   module mkConnection#(MsgSource#(bpb,asz) source, MsgSink#(bpb,asz) sink)();
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_src_rdy;
         sink.src_rdy(source.src_rdy());
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_dst_rdy;
         source.dst_rdy(sink.dst_rdy());
      endrule
      (* fire_when_enabled, no_implicit_conditions *)
      rule connect_data;
         sink.beat(source.beat());
      endrule
   endmodule
endinstance

instance Connectable#(MsgSink#(bpb,asz),MsgSource#(bpb,asz));
   module mkConnection#(MsgSink#(bpb,asz) sink, MsgSource#(bpb,asz) source)();
      let _m <- mkConnection(source,sink);
      return _m;
   endmodule
endinstance

// It is often required to tie-off unused message sources or sinks
// For MsgSource, this will accept messages and discard them.
// For MsgSink, this will never send a message.

instance TieOff#(MsgSource#(bpb,asz));
   module mkTieOff#(MsgSource#(bpb,asz) ifc)();
      // always be ready but don't look at the data
      (* fire_when_enabled, no_implicit_conditions *)
      rule always_accept_beat;
         ifc.dst_rdy(True);
      endrule
   endmodule
endinstance

instance TieOff#(MsgSink#(bpb,asz));
   module mkTieOff#(MsgSink#(bpb,asz) ifc)();
      // never be ready
      (* fire_when_enabled, no_implicit_conditions *)
      rule never_be_ready;
         ifc.src_rdy(False);
      endrule
      // the beat data doesn't matter
      (* fire_when_enabled, no_implicit_conditions *)
      rule send_whatever;
         ifc.beat(?);
      endrule
   endmodule
endinstance

// FIFO versions of the source and sink expose a FIFO-like half and
// MsgSource/MsgSink half

interface FifoMsgSource#(numeric type bpb, numeric type asz);
   method Bool   full();
   method Action enq(MsgBeat#(bpb,asz) v);
   interface MsgSource#(bpb,asz) source;
endinterface: FifoMsgSource

interface FifoMsgSink#(numeric type bpb, numeric type asz);
   method Bool              empty();
   method MsgBeat#(bpb,asz) first();
   method Action            deq();
   interface MsgSink#(bpb,asz) sink;
endinterface: FifoMsgSink

// Create a FIFO and expose its destination half as a MsgSource
module mkFifoMsgSource(FifoMsgSource#(bpb,asz));

   // The FIFO for storing message beats
   FIFOF#(MsgBeat#(bpb,asz)) f <- mkUGFIFOF();

   // The MsgSource beat is valid if the FIFO is not empty
   Bool src_ok = f.notEmpty();

   Wire#(Bool) dst_ok <- mkBypassWire();

   // The beat transfers when both src and dst assert ready
   (* fire_when_enabled, no_implicit_conditions *)
   rule update if (src_ok && dst_ok);
      f.deq();
   endrule

   // Expose the FIFO's full condition
   method Bool full();
      return !f.notFull();
   endmethod

   // Allow beats to be added to the FIFO
   method Action enq(MsgBeat#(bpb,asz) v) if (f.notFull());
      f.enq(v);
   endmethod

   // The MsgSource view of the FIFO destination side
   interface MsgSource source;
      method src_rdy = src_ok;        // FIFO is not empty
      method dst_rdy = dst_ok._write; // destination is ready
      method beat    = f.first();     // next FIFO value
   endinterface

endmodule: mkFifoMsgSource

// Create a FIFO and expose its source half as a MsgSink
module mkFifoMsgSink(FifoMsgSink#(bpb,asz));

   // The FIFO for storing message beats
   FIFOF#(MsgBeat#(bpb,asz)) f <- mkUGFIFOF();

   Wire#(Bool) src_ok <- mkBypassWire();

   // The sink is ready when the FIFO has space
   Bool dst_ok = f.notFull();

   Wire#(MsgBeat#(bpb,asz)) val <- mkBypassWire();

   // The beat transfers when both src and dst assert ready
   (* fire_when_enabled, no_implicit_conditions *)
   rule update if (src_ok && dst_ok);
      f.enq(val);
   endrule

   // Expose the FIFO's empty condition
   method Bool empty();
      return !f.notEmpty();
   endmethod

   // Expose the FIFO's next data value (unguarded)
   method MsgBeat#(bpb,asz) first();
      return f.first();
   endmethod

   // Allow data to be removed from the FIFO (unguarded)
   method Action deq();
      f.deq();
   endmethod

   // The MsgSink view of the FIFO source side
   interface MsgSink sink;
      method dst_rdy = dst_ok;        // FIFO is not full
      method src_rdy = src_ok._write; // source data is valid
      method beat    = val._write;    // data from source
   endinterface

endmodule: mkFifoMsgSink

// Functions used to extract source and sink interfaces

function MsgSource#(bpb,asz) get_source_ifc(FifoMsgSource#(bpb,asz) fsource);
   return fsource.source;
endfunction

function MsgSink#(bpb,asz) get_sink_ifc(FifoMsgSink#(bpb,asz) fsink);
   return fsink.sink;
endfunction

/* Standard definition of a bidirectional port for
 * building switches and connecting nodes to the NoC.
 */

interface MsgPort#(numeric type bpb, numeric type asz);
   interface MsgSink#(bpb,asz)   in;
   interface MsgSource#(bpb,asz) out;
endinterface: MsgPort

instance Connectable#(MsgPort#(bpb,asz), MsgPort#(bpb,asz));
   module mkConnection#(MsgPort#(bpb,asz) p1, MsgPort#(bpb,asz) p2)();
      mkConnection(p1.in,  p2.out);
      mkConnection(p1.out, p2.in);
   endmodule
endinstance

instance TieOff#(MsgPort#(bpb,asz));
   module mkTieOff#(MsgPort#(bpb,asz) p)();
      mkTieOff(p.in);
      mkTieOff(p.out);
   endmodule
endinstance

function MsgPort#(bpb,asz) as_port( MsgSource#(bpb,asz) src
                                  , MsgSink#(bpb,asz)   snk
                                  );
   return (interface MsgPort;
              interface MsgSink   in  = snk;
              interface MsgSource out = src;
           endinterface);
endfunction: as_port

// This function is useful for creating routing predicates

function Bool hasNodeID(NodeID target, NodeID n);
   return (n == target);
endfunction: hasNodeID

/* This is a useful utility module for parsing messages.
 * It can take in a stream of beats and provide the
 * individual elements of the message through a battery
 * of value methods.
 *
 * This is an intricate piece of code, so it is good to
 * do this once in a library and allow it to be reused by
 * all message-handling modules.
 */

interface MsgParse#(numeric type bpb, numeric type asz);
   // provide the next beat
   (* always_ready *)
   method Action beat(MsgBeat#(bpb,asz) v);
   // commit the state updates for this beat
   (* always_ready *)
   method Action advance();
   // read the individual elements from the beat
   method NodeID               dst();
   method NodeID               src();
   method MsgType              msg_type();
   method UInt#(14)            read_length();
   method Bit#(6)              metadata();
   method UInt#(asz)           addr_at_dst();
   method UInt#(asz)           addr_at_src();
   method SegmentTag           segment_tag();
   method Vector#(bpb,Bit#(8)) segment_bytes;
   (* always_ready *)
   method Vector#(bpb,Bool)    valid_mask;
   // beat framing signals
   (* always_ready *)
   method Bool first_beat();
   (* always_ready *)
   method Bool last_beat();
endinterface: MsgParse

// the message parser state
typedef struct {
   UInt#(5)           state;
   MsgType            message_type;
   Vector#(7,Bit#(8)) last_seven_bytes;
   Bool               is_last_segment;
   UInt#(7)           bytes_remaining; // in current segment
   UInt#(TLog#(bpb))  first_payload_byte;
} MsgParseState#(numeric type bpb) deriving (Bits);

// initial parse state at the beginning of each message
MsgParseState#(bpb) init_parse_st = MsgParseState { state:              0
                                                  , message_type:       Datagram
                                                  , last_seven_bytes:   replicate('0)
                                                  , is_last_segment:    False
                                                  , bytes_remaining:    0
                                                  , first_payload_byte: 0
                                                  };

// Statically determine if a byte in a beat could fall within a
// particular byte range in a message. This helps take some load off
// the compiler and sythesis tools to generate minimal logic for the
// message parsing module.
function Bool in_range(Integer bytes_per_beat, Integer pos, Integer lo, Integer hi);
   Bool ret = False;
   for (Integer i = lo; i <= hi; i = i + 1) begin
      ret = ret || (i % bytes_per_beat == pos);
   end
   return ret;
endfunction

// utility functions for reading pulsewires and rwires

function Bool readPW(PulseWire pw);
   return pw;
endfunction

function Bool rwHasData(RWire#(a) rw);
   return isValid(rw.wget());
endfunction

function a readRW(RWire#(a) rw);
   return validValue(rw.wget());
endfunction

/* This is an implementation of the message parsing interface
 * that is parameterized across all beat sizes and address sizes.
 * This implementation is not the most elegant (which would be
 * a single fold of a byte-parsing function over the bytes
 * in a beat), because it represents a compromise between
 * elegance and evaluator scalability limitations.
 */
module mkMsgParse_POLY(MsgParse#(bpb,asz))
   provisos( Add#(asz, padding, 64)    // asz <= 64
           , Add#(_v1, TLog#(bpb), 7)  // byte pos in beat requires 7 or fewer bits
           , Add#(_v2, TLog#(TAdd#(1,bpb)), 7)
           , Add#(1, _v3, TLog#(TAdd#(1,bpb)))
           );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkMsgParse", bytes_per_beat, addr_size);

   // the incoming beat
   Wire#(Vector#(bpb,Bit#(8)))  the_beat         <- mkWire();

   // wires to report what was learned from the beat
   Wire#(NodeID)                dst_w            <- mkWire();
   Wire#(NodeID)                src_w            <- mkWire();
   Wire#(MsgType)               msg_type_w       <- mkWire();
   Wire#(UInt#(14))             read_length_w    <- mkWire();
   Wire#(Bit#(6))               metadata_w       <- mkWire();
   Wire#(UInt#(asz))            addr_at_dst_w    <- mkWire();
   Wire#(UInt#(asz))            addr_at_src_w    <- mkWire();
   RWire#(SegmentTag)           segment_tag_rw1  <- mkRWire();
   RWire#(SegmentTag)           segment_tag_rw2  <- mkRWire();
   Vector#(bpb,RWire#(Bit#(8))) segment_bytes_ws <- replicateM(mkRWire);
   Vector#(bpb,PulseWire)       valid_mask_pws   <- replicateM(mkPulseWire);

   PulseWire                    first_beat_pw    <- mkPulseWire();
   PulseWire                    last_beat_pw     <- mkPulseWire();

   /* This is the low-level parsing function. Based on the current parse state
    * we know if we are expecting a header byte, an address byte, a segment tag
    * byte or a segment payload byte. That is the top-level decision. Based
    * on the current position in the beat and the beat size, we can statically
    * constrain which parsing actions are required at each byte position.
    */
   function ActionValue#(MsgParseState#(bpb)) parse_one_byte( MsgParseState#(bpb) st
                                                            , Bit#(8)             curr_byte
                                                            , Integer             pos
                                                            )
      provisos( Add#(asz,padding,64) ); // asz <= 64
      actionvalue

         Bool is_last_byte = (pos == (bytes_per_beat - 1));


         Bit#(64) addr_bytes_32 = { 32'd0
                                  , curr_byte
                                  , st.last_seven_bytes[6]
                                  , st.last_seven_bytes[5]
                                  , st.last_seven_bytes[4]
                                  };
         Bit#(64) addr_bytes_64 = { curr_byte, pack(st.last_seven_bytes) };
         Bit#(64) full_addr = (addr_size == 32) ? addr_bytes_32 : addr_bytes_64;
         UInt#(asz) curr_addr = unpack(truncate(full_addr));

         // state field encoding:
         //   0-3   header bytes
         //   4-11  dst addr bytes
         //   12-19 src addr bytes
         //   20    segment tag
         //   21    segment payload
         //   22    padding

         case (st.state)
            0       : begin // hdr byte 0
                         if (in_range(bytes_per_beat,pos,0,0)) begin
                            dst_w <= unpack(curr_byte);
                            first_beat_pw.send();
                            st.state = 1;
                         end
                      end
            1       : begin // hdr byte 1
                         if (in_range(bytes_per_beat,pos,1,1)) begin
                            src_w <= unpack(curr_byte);
                            st.state = 2;
                         end
                      end
            2       : begin // hdr byte 2
                         if (in_range(bytes_per_beat,pos,2,2)) begin
                            MsgType mt = unpack(curr_byte[1:0]);
                            st.message_type = mt;
                            msg_type_w <= mt;
                            if (mt != Request)
                               metadata_w <= curr_byte[7:2];
                            st.state = 3;
                         end
                      end
            3       : begin // hdr byte 3
                         if (in_range(bytes_per_beat,pos,3,3)) begin
                            if (st.message_type == Request) begin
                               read_length_w <= unpack({curr_byte,st.last_seven_bytes[6][7:2]});
                               st.is_last_segment = True;
                               st.bytes_remaining = 0;
                               st.state = 4; // parse destination address next
                            end
                            else begin
                               SegmentTag istag = unpack(curr_byte);
                               segment_tag_rw1.wset(istag);
                               st.is_last_segment = istag.end_of_message;
                               st.bytes_remaining = istag.length_in_bytes;
                               if (st.message_type != Datagram) begin
                                  st.state = 4; // parse destination address next
                                  st.first_payload_byte = fromInteger((4 + addr_size/8) % bytes_per_beat);
                               end
                               else begin
                                  // a datagram has no address, so the next state
                                  // is either payload, a tag, padding, or the next
                                  // message header
                                  if (istag.end_of_message && istag.length_in_bytes == 0) begin
                                     // there is no payload
                                     if (is_last_byte) begin
                                        last_beat_pw.send();
                                        st.state = 0;  // this filled the beat, so the message is complete
                                     end
                                     else
                                        st.state = 22; // pad until end of beat
                                  end
                                  else if (istag.length_in_bytes == 0) begin
                                     // the initial segment is of length 0
                                     if (is_last_byte)
                                        st.state = 20; // look for a new segment tag next
                                     else
                                        st.state = 22; // pad until end of beat
                                  end
                                  else begin
                                     st.state = 21; // read initial payload next
                                     st.first_payload_byte = fromInteger(4 % bytes_per_beat);
                                  end
                               end
                            end
                         end
                      end
            4,5,6   : begin // destination address bytes 0, 1, 2
                         if (in_range(bytes_per_beat,pos,4,6))
                            st.state = st.state + 1;
                      end
            7       : begin // destination address byte 3
                         if ((addr_size == 32) && in_range(bytes_per_beat,pos,7,7)) begin
                            addr_at_dst_w <= curr_addr;
                            if (st.message_type == Request)
                               st.state = 12; // parse source address next
                            else if (st.is_last_segment && st.bytes_remaining == 0) begin
                               // there is no payload
                               if (is_last_byte) begin
                                  last_beat_pw.send();
                                  st.state = 0;  // this filled the beat, so the message is complete
                               end
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (st.bytes_remaining == 0) begin
                               // the initial segment is of length 0
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else begin
                               st.state = 21; // read initial payload next
                            end
                         end
                         else if ((addr_size == 64) && in_range(bytes_per_beat,pos,7,7))
                            st.state = st.state + 1;
                      end
            8,9,10  : begin // destination address bytes 4, 5, 6
                         if ((addr_size == 64) && (in_range(bytes_per_beat,pos,8,10)))
                            st.state = st.state + 1;
                      end
            11      : begin // destination address byte 7
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,11,11)) begin
                            addr_at_dst_w <= curr_addr;
                            if (st.message_type == Request)
                               st.state = 12; // parse source address next
                            else if (st.is_last_segment && st.bytes_remaining == 0) begin
                               // there is no payload
                               if (is_last_byte) begin
                                  last_beat_pw.send();
                                  st.state = 0;  // this filled the beat, so the message is complete
                               end
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (st.bytes_remaining == 0) begin
                               // the initial segment is of length 0
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else begin
                               st.state = 21; // read initial payload next
                            end
                         end
                      end
            12,13,14: begin // source address bytes 0, 1, 2
                         if (  ((addr_size == 32) && in_range(bytes_per_beat,pos,8,10))
                            || ((addr_size == 64) && in_range(bytes_per_beat,pos,12,14))
                            )
                            st.state = st.state + 1;
                      end
            15      : begin // source address byte 3
                         if ((addr_size == 32) && in_range(bytes_per_beat,pos,11,11)) begin
                            addr_at_src_w <= curr_addr;
                            // there is no payload, since this is a Request message
                            if (is_last_byte) begin
                               last_beat_pw.send();
                               st.state = 0;  // this filled the beat, so the message is complete
                            end
                            else
                               st.state = 22; // pad until end of beat
                         end
                         else if ((addr_size == 64) && in_range(bytes_per_beat,pos,15,15))
                            st.state = st.state + 1;
                      end
            16,17,18: begin // source address bytes 4, 5, 6
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,16,18))
                            st.state = st.state + 1;
                      end
            19      : begin // source address byte 7
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,19,19)) begin
                            addr_at_src_w <= curr_addr;
                            // there is no payload, since this is a Request message
                            if (is_last_byte) begin
                               last_beat_pw.send();
                               st.state = 0;  // this filled the beat, so the message is complete
                            end
                            else
                               st.state = 22; // pad until end of beat
                         end
                      end
            20      : begin // segment tag
                         if (pos == 0) begin
                            SegmentTag stag = unpack(curr_byte);
                            segment_tag_rw2.wset(stag);
                            st.is_last_segment = stag.end_of_message;
                            st.bytes_remaining = stag.length_in_bytes;
                            if (stag.end_of_message && stag.length_in_bytes == 0) begin
                               // there is no payload
                               if (is_last_byte) begin
                                  last_beat_pw.send();
                                  st.state = 0;  // this filled the beat, so the message is complete
                               end
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (stag.length_in_bytes == 0) begin
                               // the segment is of length 0, but there are other segments to follow
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else begin
                               st.state = 21; // read segment payload next
                               st.first_payload_byte = fromInteger(1 % bytes_per_beat);
                            end
                         end
                      end
            21      : begin // segment payload data
                         UInt#(TLog#(bpb)) bytes_consumed = fromInteger(pos) - st.first_payload_byte;
                         Bool is_final_byte_in_segment = (zeroExtend(bytes_consumed) == (st.bytes_remaining - 1));
                         segment_bytes_ws[pos].wset(curr_byte);
                         valid_mask_pws[pos].send();
                         if (st.is_last_segment && is_final_byte_in_segment) begin
                            // this is the last payload byte of the message
                            if (is_last_byte) begin
                               last_beat_pw.send();
                               st.state = 0;  // this filled the beat, so the message is complete
                            end
                            else
                               st.state = 22; // pad until end of beat
                         end
                         else if (is_final_byte_in_segment) begin
                            // this is the last payload byte of this segment, but there are other
                            // segments to follow
                            if (is_last_byte)
                               st.state = 20; // look for a new segment tag next
                            else
                               st.state = 22; // pad until end of beat
                         end
                      end
            22      : begin // padding
                         if (is_last_byte) begin
                            if (st.is_last_segment) begin
                               last_beat_pw.send();
                               st.state = 0; // the message is complete
                            end
                            else
                               st.state = 20; // parse the next segment tag
                         end
                      end
         endcase

         st.last_seven_bytes = shiftInAtN(st.last_seven_bytes,curr_byte);

         return st;

      endactionvalue
   endfunction: parse_one_byte

   /* To perform the parsing, we have one rule for each byte in the beat.
    * The rule calls parse_one_byte on the byte along with its position in
    * the beat. The input state for position 0 comes from a register and
    * each rule's output state is written into a wire that feeds the input
    * state of the rule at the next position. The final rule's output state
    * is written back to the register whenever the advance() method is called.
    *
    * The rules are written so that they are all conflict free which each
    * other.
    */

   Reg#(MsgParseState#(bpb))                parse_state        <- mkReg(init_parse_st);
   Vector#(bpb,RWire#(MsgParseState#(bpb))) intermediate_state <- replicateM(mkRWire);

   Rules parse_rules = emptyRules;

   for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
      Rules r = rules
                   rule parse_byte;
                      MsgParseState#(bpb) st_in = (i == 0) ? parse_state : validValue(intermediate_state[i-1].wget());
                      let tmp_st <- parse_one_byte(st_in, the_beat[i], i);
                      intermediate_state[i].wset(tmp_st);
                   endrule
                endrules;
      parse_rules = rJoin(parse_rules,r);
   end

   addRules(parse_rules);

   // provide the next beat
   method Action beat(MsgBeat#(bpb,asz) v);
      the_beat <= unpack(pack(v));
   endmethod

   // Commit the state updates from the current beat.
   // This is written without an implicit condition so that
   // it can be combined in rules without aggressive conditions.
   method Action advance();
      if (intermediate_state[bytes_per_beat-1].wget() matches tagged Valid .st) begin
         MsgParseState#(bpb) updated_st = st;
         let bytes_removed = countOnes(pack(map(readPW,valid_mask_pws)));
         updated_st.bytes_remaining = updated_st.bytes_remaining - zeroExtend(bytes_removed);
         if (updated_st.state == 21)
            updated_st.first_payload_byte = 0;
         parse_state <= updated_st;
      end
   endmethod

   // read the individual elements from the beat
   method NodeID     dst         = dst_w;
   method NodeID     src         = src_w;
   method MsgType    msg_type    = msg_type_w;
   method UInt#(14)  read_length = read_length_w;
   method Bit#(6)    metadata    = metadata_w;
   method UInt#(asz) addr_at_dst = addr_at_dst_w;
   method UInt#(asz) addr_at_src = addr_at_src_w;
   method SegmentTag segment_tag() if (isValid(segment_tag_rw1.wget()) || isValid(segment_tag_rw2.wget()));
      if (segment_tag_rw1.wget() matches tagged Valid .stag)
         return stag;
      else
         return validValue(segment_tag_rw2.wget());
   endmethod
   method Vector#(bpb,Bit#(8)) segment_bytes = map(readRW,segment_bytes_ws);
   method Vector#(bpb,Bool)    valid_mask    = map(readPW,valid_mask_pws);

   // message framing signals
   method Bool first_beat = first_beat_pw;
   method Bool last_beat  = last_beat_pw;

endmodule: mkMsgParse_POLY

// Specialized versions for synthesis boundaries

(* synthesize *)
module mkMsgParse_4_32(MsgParse#(4,32));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgParse_8_32(MsgParse#(8,32));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgParse_16_32(MsgParse#(16,32));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgParse_4_64(MsgParse#(4,64));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgParse_8_64(MsgParse#(8,64));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgParse_16_64(MsgParse#(16,64));
   let _m <- mkMsgParse_POLY();
   return _m;
endmodule

// Abstract type class version that restores polymorphism

typeclass MsgParseTC#(numeric type bpb, numeric type asz);
   module mkMsgParse(MsgParse#(bpb,asz));
endtypeclass

instance MsgParseTC#(4,32);
   mkMsgParse = mkMsgParse_4_32;
endinstance

instance MsgParseTC#(8,32);
   mkMsgParse = mkMsgParse_8_32;
endinstance

instance MsgParseTC#(16,32);
   mkMsgParse = mkMsgParse_16_32;
endinstance

instance MsgParseTC#(4,64);
   mkMsgParse = mkMsgParse_4_64;
endinstance

instance MsgParseTC#(8,64);
   mkMsgParse = mkMsgParse_8_64;
endinstance

instance MsgParseTC#(16,64);
   mkMsgParse = mkMsgParse_16_64;
endinstance

// fall-through instance with no synthesis boundary
instance MsgParseTC#(bpb,asz)
   provisos( Add#(asz, padding, 64)    // asz <= 64
           , Add#(_v1, TLog#(bpb), 7)  // byte pos in beat requires 7 or fewer bits
           , Add#(_v2, TLog#(TAdd#(1,bpb)), 7)
           , Add#(1, _v3, TLog#(TAdd#(1,bpb)))
           );
   mkMsgParse = mkMsgParse_POLY;
endinstance


/* This is a useful utility module for generating messages.
 * It can produce a stream of beats given the individual
 * elements of the message through a battery of action
 * methods.
 *
 * This is an intricate piece of code, so it is good to
 * do this once in a library and allow it to be reused by
 * all message-generating modules.
 */

interface MsgBuild#(numeric type bpb, numeric type asz);
   // provide message information
   method Action dst(NodeID to);
   method Action src(NodeID from);
   method Action msg_type(MsgType mt);
   method Action read_length(UInt#(14) len);
   method Action metadata(Bit#(6) x);
   method Action addr_at_dst(UInt#(asz) addr);
   method Action addr_at_src(UInt#(asz) addr);
   method Action segment_tag(SegmentTag stag);
   // Note: the bits set in the mask must be contiguous and begin at bit 0.
   interface Put#(Tuple2#(Vector#(bpb,Bool),Vector#(bpb,Bit#(8)))) segment_bytes;

   // the MsgSource gives a stream of beats
   interface MsgSource#(bpb,asz) source;

   // message framing signals for convenience
   method Bool start_of_message();
   method Bool end_of_message();
endinterface: MsgBuild

// the message builder state
typedef struct {
   UInt#(5)                 state;
   MsgType                  message_type;
   Bool                     is_last_segment;
   UInt#(7)                 bytes_remaining; // in current segment
   Vector#(n,Bit#(8))       available_bytes;
   UInt#(TLog#(TAdd#(n,1))) byte_count;
   UInt#(TLog#(bpb))        first_payload_byte;
} MsgBuildState#(numeric type bpb,numeric type n) deriving (Bits);

// initial builder state at the beginning of each message
function MsgBuildState#(bpb,n) init_build_st();
   return MsgBuildState { state:              0
                        , message_type:       Datagram
                        , is_last_segment:    False
                        , bytes_remaining:    0
                        , available_bytes:    replicate('0)
                        , byte_count:         0
                        , first_payload_byte: 0
                        };
endfunction

/* This is an implementation of the message building interface
 * that is parameterized across all beat sizes and address sizes.
 * It is built along the same principles as the mkMsgParse
 * module above, but performs the dual operation of message
 * building instead of message parsing.
 */
module mkMsgBuild_POLY(MsgBuild#(bpb,asz))
   provisos( Add#(asz,padding,64) // asz <= 64
           , Add#(_v0, 8, asz)    // asz >= 8
           , Mul#(bpb,4,buf_sz)   // buf_sz = 4 * bpb
           , Add#(1, _v1, TLog#(TAdd#(1, bpb)))
           , Add#(_v2, TLog#(TAdd#(1,bpb)), TLog#(TAdd#(buf_sz,1)))
           , Add#(_v3, TMul#(bpb,8), TMul#(buf_sz,8))
           , Add#(_v4, TLog#(bpb), 7)
           , Add#(_v5, TLog#(TAdd#(1,bpb)), 7)
           , Add#(_v6, TLog#(TAdd#(1,bpb)), TAdd#(3,TLog#(TAdd#(buf_sz,1))))
           , Add#(_v7, TLog#(bpb), TLog#(TAdd#(buf_sz,1)))
           );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkMsgBuild", bytes_per_beat, addr_size);

   // store message information until it can be transmitted

   Reg#(Maybe#(NodeID))     cur_dst         <- mkReg(tagged Invalid);
   Reg#(Maybe#(NodeID))     cur_src         <- mkReg(tagged Invalid);
   Reg#(Maybe#(MsgType))    cur_msg_type    <- mkReg(tagged Invalid);
   Reg#(Maybe#(UInt#(14)))  cur_read_length <- mkReg(tagged Invalid);
   Reg#(Maybe#(Bit#(6)))    cur_metadata    <- mkReg(tagged Invalid);
   Reg#(Maybe#(UInt#(asz))) cur_addr_at_dst <- mkReg(tagged Invalid);
   Reg#(Maybe#(UInt#(asz))) cur_addr_at_src <- mkReg(tagged Invalid);
   Reg#(Maybe#(SegmentTag)) cur_segment_tag <- mkReg(tagged Invalid);

   FIFOF#(Tuple2#(Vector#(bpb,Bool),Vector#(bpb,Bit#(8)))) segment_bytes_fifo <- mkGLSizedFIFOF(True,True,2);

   PulseWire done_with_dst         <- mkPulseWire();
   PulseWire done_with_src         <- mkPulseWire();
   PulseWire done_with_msg_type    <- mkPulseWire();
   PulseWire done_with_read_length <- mkPulseWire();
   PulseWire done_with_metadata    <- mkPulseWire();
   PulseWire done_with_addr_at_dst <- mkPulseWire();
   PulseWire done_with_addr_at_src <- mkPulseWire();
   PulseWire done_with_segment_tag <- mkPulseWireOR();

   /* This is the low-level builder function. Based on the current build state
    * we know if we need to generate a header byte, an address byte, a segment
    * tag byte or a segment payload byte. That is the top-level decision. Based
    * on the current position in the beat and the beat size, we can statically
    * constrain which building actions are required at each byte position.
    */
   function ActionValue#(Tuple3#(MsgBuildState#(bpb,buf_sz),Maybe#(Bit#(8)),Bool))
            gen_one_byte( MsgBuildState#(bpb,buf_sz) st
                        , Integer                    pos
                        )
      provisos( Add#(asz,padding,64) );  // asz <= 64
      actionvalue

         Bool is_last_byte = (pos == (bytes_per_beat - 1));

         Maybe#(Bit#(8)) this_byte  = tagged Invalid;
         Bool            is_payload = False;

         // state field encoding (same as parse_one_byte):
         //   0-3   header bytes
         //   4-11  dst addr bytes
         //   12-19 src addr bytes
         //   20    segment tag
         //   21    segment payload
         //   22    padding

         case (st.state)
            0       : begin // hdr byte 0
                         if (in_range(bytes_per_beat,pos,0,0)) begin
                            if (cur_dst matches tagged Valid .dst) begin
                               this_byte = tagged Valid pack(dst);
                               st.state = 1;
                               done_with_dst.send();
                            end
                         end
                      end
            1       : begin // hdr byte 1
                         if (in_range(bytes_per_beat,pos,1,1)) begin
                            if (cur_src matches tagged Valid .src) begin
                               this_byte = tagged Valid pack(src);
                               st.state = 2;
                               done_with_src.send();
                            end
                         end
                      end
            2       : begin // hdr byte 2
                         if (in_range(bytes_per_beat,pos,2,2)) begin
                            if (cur_msg_type matches tagged Valid .mt) begin
                               if (mt == Request) begin
                                  if (cur_read_length matches tagged Valid .len) begin
                                     this_byte = tagged Valid ({pack(len)[5:0],pack(mt)});
                                     st.state = 3;
                                  end
                               end
                               else begin
                                  if (cur_metadata matches tagged Valid .md) begin
                                     this_byte = tagged Valid ({md,pack(mt)});
                                     st.state = 3;
                                  end
                               end
                               st.message_type = mt;
                               done_with_msg_type.send();
                               done_with_metadata.send();
                            end
                         end
                      end
            3       : begin // hdr byte 3
                         if (in_range(bytes_per_beat,pos,3,3)) begin
                            if (st.message_type == Request) begin
                               if (cur_read_length matches tagged Valid .len) begin
                                  this_byte = tagged Valid pack(len)[13:6];
                                  st.state = 4; // parse destination address next
                                  done_with_read_length.send();
                               end
                            end
                            else begin
                               if (cur_segment_tag matches tagged Valid .istag) begin
                                  this_byte = tagged Valid pack(istag);
                                  st.is_last_segment = istag.end_of_message;
                                  st.bytes_remaining = istag.length_in_bytes;
                                  if (st.message_type != Datagram) begin
                                     st.state = 4; // parse destination address next
                                     if (istag.length_in_bytes != 0)
                                        st.first_payload_byte = fromInteger((4 + addr_size/8) % bytes_per_beat);
                                  end
                                  else begin
                                     // a datagram has no address, so the next state
                                     // is either payload, a tag, padding, or the next
                                     // message header
                                     if (istag.end_of_message && istag.length_in_bytes == 0) begin
                                        // there is no payload
                                        if (is_last_byte)
                                           st.state = 0;  // this filled the beat, so the message is complete
                                        else
                                           st.state = 22; // pad until end of beat
                                     end
                                     else if (istag.length_in_bytes == 0) begin
                                        // the initial segment is of length 0
                                        if (is_last_byte)
                                           st.state = 20; // look for a new segment tag next
                                        else
                                           st.state = 22; // pad until end of beat
                                     end
                                     else begin
                                        st.state = 21; // read initial payload next
                                        st.first_payload_byte = fromInteger(4 % bytes_per_beat);
                                     end
                                  end
                                  done_with_segment_tag.send();
                               end
                            end
                         end
                      end
            4,5,6   : begin // destination address bytes 0, 1, 2
                         if (in_range(bytes_per_beat,pos,4,6)) begin
                            if (cur_addr_at_dst matches tagged Valid .addr) begin
                               this_byte = tagged Valid truncate(pack(addr) >> (8*(st.state-4)));
                               st.state = st.state + 1;
                            end
                         end
                      end
            7       : begin // destination address byte 3
                         if ((addr_size == 32) && in_range(bytes_per_beat,pos,7,7)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_dst);
                            this_byte = tagged Valid truncate(pack(addr) >> 24);
                            if (st.message_type == Request)
                               st.state = 12; // parse source address next
                            else if (st.is_last_segment && st.bytes_remaining == 0) begin
                               // there is no payload
                               if (is_last_byte)
                                  st.state = 0;  // this filled the beat, so the message is complete
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (st.bytes_remaining == 0) begin
                               // the initial segment is of length 0
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else begin
                               st.state = 21; // read initial payload next
                            end
                            done_with_addr_at_dst.send();
                         end
                         else if ((addr_size == 64) && in_range(bytes_per_beat,pos,7,7)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_dst);
                            this_byte = tagged Valid truncate(pack(addr) >> 24);
                            st.state = st.state + 1;
                         end
                      end
            8,9,10  : begin // destination address bytes 4, 5, 6
                         if ((addr_size == 64) && (in_range(bytes_per_beat,pos,8,10))) begin
                            UInt#(asz) addr = validValue(cur_addr_at_dst);
                            this_byte = tagged Valid truncate(pack(addr) >> (8*(st.state-4)));
                            st.state = st.state + 1;
                         end
                      end
            11      : begin // destination address byte 7
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,11,11)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_dst);
                            this_byte = tagged Valid truncate(pack(addr) >> 56);
                            if (st.message_type == Request)
                               st.state = 12; // parse source address next
                            else if (st.is_last_segment && st.bytes_remaining == 0) begin
                               // there is no payload
                               if (is_last_byte)
                                  st.state = 0;  // this filled the beat, so the message is complete
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (st.bytes_remaining == 0) begin
                               // the initial segment is of length 0
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else begin
                               st.state = 21; // read initial payload next
                            end
                            done_with_addr_at_dst.send();
                         end
                      end
            12,13,14: begin // source address bytes 0, 1, 2
                         if (  ((addr_size == 32) && in_range(bytes_per_beat,pos,8,10))
                            || ((addr_size == 64) && in_range(bytes_per_beat,pos,12,14))
                            )
                         begin
                            if (cur_addr_at_src matches tagged Valid .addr) begin
                               this_byte = tagged Valid truncate(pack(addr) >> (8*(st.state-12)));
                               st.state = st.state + 1;
                            end
                         end
                      end
            15      : begin // source address byte 3
                         if ((addr_size == 32) && in_range(bytes_per_beat,pos,11,11)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_src);
                            this_byte = tagged Valid truncate(pack(addr) >> 24);
                            // there is no payload, since this is a Request message
                            if (is_last_byte)
                               st.state = 0;  // this filled the beat, so the message is complete
                            else
                               st.state = 22; // pad until end of beat
                               done_with_addr_at_src.send();
                         end
                         else if ((addr_size == 64) && in_range(bytes_per_beat,pos,15,15)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_src);
                            this_byte = tagged Valid truncate(pack(addr) >> 24);
                            st.state = st.state + 1;
                         end
                      end
            16,17,18: begin // source address bytes 4, 5, 6
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,16,18)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_src);
                            this_byte = tagged Valid truncate(pack(addr) >> (8*(st.state-12)));
                            st.state = st.state + 1;
                         end
                      end
            19      : begin // source address byte 7
                         if ((addr_size == 64) && in_range(bytes_per_beat,pos,19,19)) begin
                            UInt#(asz) addr = validValue(cur_addr_at_src);
                            this_byte = tagged Valid truncate(pack(addr) >> 56);
                            // there is no payload, since this is a Request message
                            if (is_last_byte)
                               st.state = 0;  // this filled the beat, so the message is complete
                            else
                               st.state = 22; // pad until end of beat
                               done_with_addr_at_src.send();
                         end
                      end
            20      : begin // segment tag
                         if (pos == 0) begin
                            if (cur_segment_tag matches tagged Valid .stag) begin
                               this_byte = tagged Valid pack(stag);
                               st.is_last_segment = stag.end_of_message;
                               st.bytes_remaining = stag.length_in_bytes;
                               if (stag.end_of_message && stag.length_in_bytes == 0) begin
                                  // there is no payload
                                  if (is_last_byte)
                                     st.state = 0;  // this filled the beat, so the message is complete
                                  else
                                     st.state = 22; // pad until end of beat
                               end
                               else if (stag.length_in_bytes == 0) begin
                                  // the segment is of length 0, but there are other segments to follow
                                  if (is_last_byte)
                                     st.state = 20; // look for a new segment tag next
                                  else
                                     st.state = 22; // pad until end of beat
                               end
                               else begin
                                  st.state = 21; // read segment payload next
                                  st.first_payload_byte = fromInteger(1 % bytes_per_beat);
                               end
                               done_with_segment_tag.send();
                            end
                         end
                      end
            21      : begin // segment payload data
                         UInt#(TLog#(bpb)) bytes_consumed = fromInteger(pos) - st.first_payload_byte;
                         Bool is_final_byte_in_segment = (zeroExtend(bytes_consumed) == (st.bytes_remaining - 1));
                         if (zeroExtend(bytes_consumed) < st.byte_count) begin
                            this_byte = tagged Valid st.available_bytes[bytes_consumed];
                            is_payload = True;
                            if (st.is_last_segment && is_final_byte_in_segment) begin
                               // this is the last payload byte of the message
                               if (is_last_byte)
                                  st.state = 0;  // this filled the beat, so the message is complete
                               else
                                  st.state = 22; // pad until end of beat
                            end
                            else if (is_final_byte_in_segment) begin
                               // this is the last payload byte of this segment, but there are other
                               // segments to follow
                               if (is_last_byte)
                                  st.state = 20; // look for a new segment tag next
                               else
                                  st.state = 22; // pad until end of beat
                            end
                         end
                      end
            22      : begin // padding
                         this_byte = tagged Valid '0;
                         if (is_last_byte) begin
                            if ((st.message_type == Request) || st.is_last_segment)
                               st.state = 0; // the message is complete
                            else
                               st.state = 20; // parse the next segment tag
                         end
                      end
         endcase

         return tuple3(st,this_byte,is_payload);
      endactionvalue

   endfunction: gen_one_byte

   /* To perform the building, we have one rule for each byte in the beat.
    * The rule calls gen_one_byte with its position in the beat. Each rule
    * also produces Maybe a byte, and a full beat is available only when
    * all rules produces a Valid byte. The input state for position 0 comes
    * from a register and each rule's output state is written into a wire
    * that feeds the input state of the rule at the next position. The
    * final rule's output state is written back to the register whenever
    * a full beat has been produced and there is space in the output buffer.
    *
    * The rules are written so that they are all conflict free which each
    * other.
    */

   Reg#(MsgBuildState#(bpb,buf_sz))                build_state        <- mkReg(init_build_st());
   Vector#(bpb,RWire#(MsgBuildState#(bpb,buf_sz))) intermediate_state <- replicateM(mkRWire);
   Vector#(bpb,RWire#(Bit#(8)))                    the_bytes          <- replicateM(mkRWire);
   Vector#(bpb,PulseWire)                          has_segment_data   <- replicateM(mkPulseWire);

   Rules build_rules = emptyRules;

   for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
      Rules r = rules
                   rule gen_byte;
                      MsgBuildState#(bpb,buf_sz) st_in = (i == 0) ? build_state : validValue(intermediate_state[i-1].wget());
                      let {tmp_st,mbyte,is_payload} <- gen_one_byte(st_in,i);
                      intermediate_state[i].wset(tmp_st);
                      if (mbyte matches tagged Valid .v)
                         the_bytes[i].wset(v);
                      if (is_payload)
                         has_segment_data[i].send();
                   endrule
                endrules;
      build_rules = rJoin(build_rules,r);
   end

   addRules(build_rules);

   // beat output gets buffered through a FIFO

   Bool has_full_beat = all(rwHasData,the_bytes);
   FIFOF#(Tuple3#(Bool,Bool,MsgBeat#(bpb,asz))) beat_fifo <- mkUGFIFOF();

   Bool will_take_bytes = build_state.byte_count <= fromInteger(valueOf(buf_sz)-valueOf(bpb));
   Bool will_give_beat  =  isValid(intermediate_state[bytes_per_beat-1].wget())
                        && has_full_beat
                        && beat_fifo.notFull()
                        ;

   (* fire_when_enabled, no_implicit_conditions *)
   rule update_state if (will_take_bytes || will_give_beat);
      MsgBuildState#(bpb,buf_sz) updated_st = will_give_beat
                                            ? validValue(intermediate_state[bytes_per_beat-1].wget())
                                            : build_state;
      let bytes_added = 0;
      Vector#(bpb,Bit#(8)) bytes = replicate(0);
      if (will_take_bytes && segment_bytes_fifo.notEmpty()) begin
         let {add_valid_vec,bvec} = segment_bytes_fifo.first();
         segment_bytes_fifo.deq();
         Bit#(bpb) add_valid = pack(add_valid_vec);
         bytes_added = countOnes(add_valid);
         bytes = bvec;
      end

      let bytes_removed = 0;
      if (will_give_beat)
         bytes_removed = countOnes(pack(map(readPW,has_segment_data)));

      UInt#(TAdd#(3,TLog#(TAdd#(buf_sz,1)))) shift_by = 8 * zeroExtend(bytes_removed);
      UInt#(TAdd#(3,TLog#(TAdd#(buf_sz,1)))) bit_pos  = 8 * (zeroExtend(updated_st.byte_count) - zeroExtend(bytes_removed));
//    XXX - experiment to determine path issues regardless of available_bytes updating
//    updated_st.available_bytes = unpack((pack(updated_st.available_bytes) >> shift_by) | (zeroExtend(pack(bytes)) << bit_pos));
      updated_st.available_bytes = unpack(pack(updated_st.available_bytes) | zeroExtend(pack(bytes)));

      let orig_byte_count = updated_st.byte_count;
      updated_st.byte_count      = updated_st.byte_count - zeroExtend(bytes_removed) + zeroExtend(bytes_added);
      updated_st.bytes_remaining = updated_st.bytes_remaining - zeroExtend(bytes_removed);
      if (updated_st.state == 21 && will_give_beat)
         updated_st.first_payload_byte = 0;
      build_state <= updated_st;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule gen_beat if (will_give_beat);
      if (done_with_dst)         cur_dst         <= tagged Invalid;
      if (done_with_src)         cur_src         <= tagged Invalid;
      if (done_with_msg_type)    cur_msg_type    <= tagged Invalid;
      if (done_with_read_length) cur_read_length <= tagged Invalid;
      if (done_with_metadata)    cur_metadata    <= tagged Invalid;
      if (done_with_addr_at_dst) cur_addr_at_dst <= tagged Invalid;
      if (done_with_addr_at_src) cur_addr_at_src <= tagged Invalid;
      if (done_with_segment_tag) cur_segment_tag <= tagged Invalid;
      MsgBeat#(bpb,asz) the_beat = unpack(pack(map(readRW,the_bytes)));
      Bool is_first_beat = (build_state.state == 0);
      Bool is_last_beat  = (validValue(intermediate_state[bytes_per_beat-1].wget()).state == 0);
      beat_fifo.enq(tuple3(is_first_beat,is_last_beat,the_beat));
   endrule

   // provide message information

   method Action dst(NodeID to) if (!isValid(cur_dst));
      cur_dst <= tagged Valid to;
   endmethod

   method Action src(NodeID from) if (!isValid(cur_src));
      cur_src <= tagged Valid from;
   endmethod

   method Action msg_type(MsgType mt) if (!isValid(cur_msg_type));
      cur_msg_type <= tagged Valid mt;
   endmethod

   method Action read_length(UInt#(14) len) if (!isValid(cur_read_length));
      cur_read_length <= tagged Valid len;
   endmethod

   method Action metadata(Bit#(6) x) if (!isValid(cur_metadata));
      cur_metadata <= tagged Valid x;
   endmethod

   method Action addr_at_dst(UInt#(asz) addr) if (!isValid(cur_addr_at_dst));
      cur_addr_at_dst <= tagged Valid addr;
   endmethod

   method Action addr_at_src(UInt#(asz) addr) if (!isValid(cur_addr_at_src));
      cur_addr_at_src <= tagged Valid addr;
   endmethod

   method Action segment_tag(SegmentTag stag) if (!isValid(cur_segment_tag));
      cur_segment_tag <= tagged Valid stag;
   endmethod

   interface Put segment_bytes;
      method Action put(x) if (segment_bytes_fifo.notFull());
         segment_bytes_fifo.enq(x);
      endmethod
   endinterface

   // the MsgSource gives a stream of beats
   interface MsgSource source;
      method src_rdy = beat_fifo.notEmpty;
      method Action dst_rdy(Bool b);
         if (b && beat_fifo.notEmpty())
            beat_fifo.deq();
      endmethod
      method MsgBeat#(bpb,asz) beat();
         return tpl_3(beat_fifo.first());
      endmethod
   endinterface

   // Also provide message framing pulse for convenience

   method Bool start_of_message();
      return beat_fifo.notEmpty() && tpl_1(beat_fifo.first());
   endmethod

   method Bool end_of_message();
      return beat_fifo.notEmpty() && tpl_2(beat_fifo.first());
   endmethod

endmodule: mkMsgBuild_POLY

// Specialized versions for synthesis boundaries

(* synthesize *)
module mkMsgBuild_4_32(MsgBuild#(4,32));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgBuild_8_32(MsgBuild#(8,32));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgBuild_16_32(MsgBuild#(16,32));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgBuild_4_64(MsgBuild#(4,64));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgBuild_8_64(MsgBuild#(8,64));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

(* synthesize *)
module mkMsgBuild_16_64(MsgBuild#(16,64));
   let _m <- mkMsgBuild_POLY();
   return _m;
endmodule

// Abstract type class version that restores polymorphism

typeclass MsgBuildTC#(numeric type bpb, numeric type asz);
   module mkMsgBuild(MsgBuild#(bpb,asz));
endtypeclass

instance MsgBuildTC#(4,32);
   mkMsgBuild = mkMsgBuild_4_32;
endinstance

instance MsgBuildTC#(8,32);
   mkMsgBuild = mkMsgBuild_8_32;
endinstance

instance MsgBuildTC#(16,32);
   mkMsgBuild = mkMsgBuild_16_32;
endinstance

instance MsgBuildTC#(4,64);
   mkMsgBuild = mkMsgBuild_4_64;
endinstance

instance MsgBuildTC#(8,64);
   mkMsgBuild = mkMsgBuild_8_64;
endinstance

instance MsgBuildTC#(16,64);
   mkMsgBuild = mkMsgBuild_16_64;
endinstance

// fall-through instance with no synthesis boundary
instance MsgBuildTC#(bpb,asz)
   provisos( Add#(asz,padding,64) // asz <= 64
           , Add#(_v0, 8, asz)    // asz >= 8
           , Mul#(bpb,4,buf_sz)   // buf_sz = 4 * bpb
           , Add#(1, _v1, TLog#(TAdd#(1, bpb)))
           , Add#(_v2, TLog#(TAdd#(1,bpb)), TLog#(TAdd#(buf_sz,1)))
           , Add#(_v3, TMul#(bpb,8), TMul#(buf_sz,8))
           , Add#(_v4, TLog#(bpb), 7)
           , Add#(_v5, TLog#(TAdd#(1,bpb)), 7)
           , Add#(_v6, TLog#(TAdd#(1,bpb)), TAdd#(3,TLog#(TAdd#(buf_sz, 1))))
           , Add#(_v7, TLog#(bpb), TLog#(TAdd#(buf_sz,1)))
           );
   mkMsgBuild = mkMsgBuild_POLY;
endinstance

endpackage: MsgXfer
