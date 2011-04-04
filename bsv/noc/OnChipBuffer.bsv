package OnChipBuffer;

/* This is a package which contains a dual-port memory that
 * will be inferred as BRAM/MRAM on an FPGA. One of the ports
 * is connected to the NoC and the other is available to the
 * user's processing element. The NoC and the processing
 * element can be in different clock domains.
 *
 * The width of memory must be a 2^n bytes for n=0,1,2,3,..
 * It does not need to match the beat size of the NoC.
 *
 * Write messages which arrive from the NoC are processed
 * by writing to memory buffer. Request messages which arrive
 * from the NoC are processed by reading from the memory buffer
 * and generating a Completion message to return the data across
 * the NoC.
 *
 * Datagram and Completion messages which arrive from the NoC are
 * ignored.
 */

import Vector       :: *;
import BRAM         :: *;
import DefaultValue :: *;
import FIFO         :: *;
import FIFOF        :: *;

import MsgFormat   :: *;
import MsgXfer     :: *;
import ByteShifter :: *;
import BypassReg   :: *;

export OnChipBuffer(..), mkOnChipBuffer;

// The interface of the on-chip buffer
interface OnChipBuffer#( type addr, type data
                       , numeric type bpb, numeric type asz
                       );
   // NoC-facing message port
   interface MsgPort#(bpb,asz)                               noc;
   // Memory port available to the user
   interface BRAMServerBE#(addr,data,TDiv#(SizeOf#(data),8)) user;
endinterface: OnChipBuffer

// This is a structure used internally to communicate
// Request message parameters
typedef struct {
   NodeID     dst;
   NodeID     src;
   UInt#(asz) addr;
} RespInfo#(numeric type asz) deriving (Bits);

// Utility module for checking the validity of the memory width
module check_mem_type_params#(String prefix, Integer mem_width_in_bits)();
   if (mem_width_in_bits % 8 != 0)
      errorM(prefix + ": Invalid memory width (" + integerToString(mem_width_in_bits) + " bits) should be a power of 2 bytes");
   Bool is_power_of_two = False;
   Integer n = mem_width_in_bits / 8;
   while (n != 0) begin
      if (n % 2 == 1) begin
         if (is_power_of_two) begin
            is_power_of_two = False;
            n = 0;
         end
         else
            is_power_of_two = True;
      end
      n = n / 2;
   end
   if (!is_power_of_two)
      errorM(prefix + ": Invalid memory width (" + integerToString(mem_width_in_bits) + " bits) should be a power of 2 bytes");
endmodule

// Implementation of an on-chip-buffer
//
// Practically, this is the end-of-the-road for polymorphism
// due to the rats nest of provisos required by this module.
// It is highly recommend that this module be instantiated
// with concrete type parameters, unless you're a real
// suffer-puppy.
(* no_default_clock, no_default_reset *)
module mkOnChipBuffer#( Clock noc_clk,  Reset noc_rstn
                      , Clock user_clk, Reset user_rstn
                      )
                      ( OnChipBuffer#(addr,data,bpb,asz) )
   // The data size should be 2^n bytes for n = 0,1,2,...
   // The addr type will be smaller than asz and the NoC addresses
   // can be divided into 4 parts:
   //      [ unused, row_addr, slice_idx, byte_idx ]
   // When there is a single slice, the slice_idx size will be 0
   // and the byte_idx size will be 1 or 2 bits.
   // When there are multiple slices, the slice_idx size will be >0
   // and the byte_idx size will be 2 bits.
   provisos ( Bits#(addr,addr_sz)
            , Bits#(data,data_sz)
            , Add#(1,_v0,addr_sz) // addr_sz >= 1
            , Add#(1,_v1,data_sz) // data_sz >= 1
            , Add#(asz,_v2,64)    // asz <= 64
            , Add#(7,_v3,asz)     // asz >= 7
            , Arith#(addr)
            , Div#(data_sz,8,num_data_bytes)
            , Min#(num_data_bytes,4,bytes_per_slice)
            , Div#(num_data_bytes,bytes_per_slice,num_slices)
            , Log#(num_slices,slice_idx_sz)
            , Log#(bytes_per_slice,byte_idx_sz)
            , Add#(byte_idx_sz,slice_idx_sz,total_idx_sz)
            , Add#(total_idx_sz,_v4,6) // total_idx_sz <= 6
            , Add#(total_idx_sz,addr_sz,byte_addr_sz)
            , Add#(byte_addr_sz,unused_addr_sz,asz)
            , Mul#(bytes_per_slice,8,slice_sz)
            , Div#(slice_sz,bytes_per_slice,8)
            , Mul#(num_slices,slice_sz,data_sz)
            , Log#(TAdd#(num_data_bytes,1),bc_sz)
            , Add#(_v5,bc_sz,7) // bc_sz <= 7
            , Max#(num_data_bytes,bpb,max0)
            , Add#(num_data_bytes,bpb,sum0)
            , Add#(sum0,max0,byte_buf_sz)
            , Add#(_v6,TLog#(TAdd#(byte_buf_sz,1)),7)
             // things the compiler should know already but doesn't
            , Add#(TAdd#(total_idx_sz,1),_v7,asz) // asz > total_idx_sz
            , Add#(total_idx_sz,_v8,asz)          // asz >= total_idx_sz
            , Add#(8,_v9,slice_sz)                // slice_sz >= 8
            , Add#(byte_idx_sz,_v10,5)            // byte_idx_sz <= 5
            , Add#(1, _v11, TLog#(TAdd#(1,bpb)))
            , Add#(_v12, TLog#(TAdd#(1,bpb)), TLog#(TAdd#(TMul#(bpb,4),1)))
            , Add#(total_idx_sz,_v13,13) // total_idx_sz <= 13
            , Add#(_v14, TMul#(bpb,8), TMul#(TMul#(bpb,4),8))
            , Add#(_v15,bc_sz,14) // bc_sz <= 14
            , Add#(_v16,bc_sz,TLog#(TAdd#(byte_buf_sz,1)))
            , Add#(_v17,TLog#(TAdd#(bpb,1)),TLog#(TAdd#(byte_buf_sz,1)))
            , Add#(_v18,total_idx_sz,bc_sz)
            , Add#(_v19,TLog#(TAdd#(bpb,1)),14)
            , Add#(_v20,TLog#(TAdd#(bpb,1)),7)
            , Add#(14,_v21,asz) // asz >= 14
            , Add#(_v22,TLog#(TAdd#(bpb,1)),asz)
            , Add#(8,_v23,asz)     // asz >= 8
            , Add#(_v24,TMul#(num_data_bytes,8),TMul#(byte_buf_sz,8))
            , Add#(_v25,TMul#(bpb,8),TMul#(byte_buf_sz,8))
            , Add#(_v26,bpb,byte_buf_sz) // byte_buf_sz >= bpb
            , Add#(_v27,num_data_bytes,byte_buf_sz) // byte_buf_sz >= num_data_bytes
            );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkOnChipBuffer", bytes_per_beat, addr_size);
   check_mem_type_params("mkOnChipBuffer", valueOf(data_sz));

   // Xilinx will not infer memory with >4 byte enables, so we split
   // up wide memories into multiple slices each no more than 4 bytes wide.
   Vector#(num_slices,BRAM2PortBE#(addr,Bit#(slice_sz),bytes_per_slice)) mems <-
        replicateM(mkSyncBRAM2ServerBE( defaultValue()
                                      , noc_clk, noc_rstn
                                      , user_clk, user_rstn)
                  );

   // Incoming beats are fed into a MsgParse to break them into abstract elements
   MsgParse#(bpb,asz) msg_parse <- mkMsgParse(clocked_by noc_clk, reset_by noc_rstn);

   // Capture data as it comes in from the message parser
   WReg#(UInt#(asz))           curr_addr      <- mkBypassReg(0,                clocked_by noc_clk, reset_by noc_rstn);
   WReg#(MsgType)              message_type   <- mkBypassReg(Datagram,         clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(14))            bytes_to_read  <- mkBypassReg(0,                clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(7))             bytes_to_write <- mkBypassReg(0,                clocked_by noc_clk, reset_by noc_rstn);
   WReg#(NodeID)               return_from    <- mkBypassReg(unpack('0),       clocked_by noc_clk, reset_by noc_rstn);
   WReg#(NodeID)               return_to      <- mkBypassReg(unpack('0),       clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(asz))           return_addr    <- mkBypassReg(0,                clocked_by noc_clk, reset_by noc_rstn);

   // Track availablity of read parameters
   PulseWire   start_of_new_msg     <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);
   PulseWire   got_addr_at_dst      <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);
   PulseWire   got_addr_at_src      <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);
   WReg#(Bool) addr_at_dst_is_stale <- mkBypassReg(True, clocked_by noc_clk, reset_by noc_rstn);
   WReg#(Bool) addr_at_src_is_stale <- mkBypassReg(True, clocked_by noc_clk, reset_by noc_rstn);

   (* fire_when_enabled *)
   rule capture_msg_dst;
      start_of_new_msg.send();
      return_from.bypass(msg_parse.dst());
   endrule

   (* fire_when_enabled *)
   rule capture_msg_src;
      return_to.bypass(msg_parse.src());
   endrule

   (* fire_when_enabled *)
   rule capture_msg_type;
      message_type.bypass(msg_parse.msg_type());
   endrule

   (* fire_when_enabled *)
   rule capture_addr;
      curr_addr.bypass(msg_parse.addr_at_dst());
      got_addr_at_dst.send();
   endrule

   (* fire_when_enabled *)
   rule capture_return_addr;
      return_addr.bypass(msg_parse.addr_at_src());
      got_addr_at_src.send();
   endrule

   (* fire_when_enabled *)
   rule capture_read_length;
      bytes_to_read.bypass(msg_parse.read_length());
   endrule

   (* fire_when_enabled *)
   rule capture_write_length;
      SegmentTag stag = msg_parse.segment_tag();
      bytes_to_write.bypass(stag.length_in_bytes);
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule track_addrs;
      if (got_addr_at_dst)
         addr_at_dst_is_stale.bypass(False);
      else if (start_of_new_msg)
         addr_at_dst_is_stale.bypass(True);
      if (got_addr_at_src)
         addr_at_src_is_stale.bypass(False);
      else if (start_of_new_msg)
         addr_at_src_is_stale.bypass(True);
   endrule

   // Requests go into a queue for access to the memory while
   // write data goes into a ByteShifter to accomodate the dynamic
   // nature of the byte widths flowing in and out.
   FIFOF#(Tuple3#(Bool,UInt#(asz),UInt#(14)))   req_fifo       <- mkSizedFIFOF(4, clocked_by noc_clk, reset_by noc_rstn);
   ByteShifter#(bpb,num_data_bytes,byte_buf_sz) write_bytes    <- mkByteShifter(clocked_by noc_clk, reset_by noc_rstn);
   ByteShifter#(num_data_bytes,bpb,byte_buf_sz) read_bytes     <- mkByteShifter(clocked_by noc_clk, reset_by noc_rstn);
   FIFOF#(RespInfo#(asz))                       resp_info_fifo <- mkFIFOF(clocked_by noc_clk, reset_by noc_rstn);

   // These are the conditions under which we must put backpressure on the NoC
   // because the capture_write_data or do_write or do_read rules can't handle
   // another input right now
   Bool stall = (write_bytes.space_available() < fromInteger(bytes_per_beat))
             || !req_fifo.notFull()
             || !resp_info_fifo.notFull()
              ;

   (* fire_when_enabled *)
   rule capture_write_data if (  !stall
                              && (msg_parse.valid_mask() != replicate(False))
                              );
      UInt#(TLog#(TAdd#(bpb,1))) bytes_added = 0;
      Vector#(bpb,Bit#(8)) vec = replicate(0);
      for (Integer n = 0; n < valueOf(bpb); n = n + 1) begin
         if (msg_parse.valid_mask()[n]) begin
            vec[bytes_added] = msg_parse.segment_bytes()[n];
            bytes_added = bytes_added + 1;
         end
      end // for
      write_bytes.enq(bytes_added,vec);
   endrule

   (* fire_when_enabled *)
   rule do_write if (  !stall
                    && (message_type == Write)
                    && (bytes_to_write > 0)
                    && !addr_at_dst_is_stale
                    );
      req_fifo.enq(tuple3(True,curr_addr,zeroExtend(bytes_to_write)));
      bytes_to_write <= 0;
      curr_addr <= curr_addr + zeroExtend(bytes_to_write);
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive = "do_write,do_read" *)
   rule do_read if (  !stall
                   && (message_type == Request)
                   && (bytes_to_read > 0)
                   && !addr_at_dst_is_stale
                   && !addr_at_src_is_stale
                   );
      req_fifo.enq(tuple3(False,curr_addr,bytes_to_read));
      resp_info_fifo.enq(tagged RespInfo { dst:  return_to
                                         , src:  return_from
                                         , addr: return_addr
                                         });
      bytes_to_read <= 0;
   endrule

   // There is some machinery for counting through memory rows
   // in a request taking the row boundaries and request alignment
   // into account.
   WReg#(addr)                row_addr      <- mkBypassReg(0, clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(total_idx_sz)) offset        <- mkBypassReg(0, clocked_by noc_clk, reset_by noc_rstn);
   WReg#(Bool)                is_wr         <- mkBypassReg(False, clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(14))           remaining     <- mkBypassReg(0, clocked_by noc_clk, reset_by noc_rstn);
   WReg#(UInt#(7))            segment_count <- mkBypassReg(0, clocked_by noc_clk, reset_by noc_rstn);
   Reg#(Bool)                 busy          <- mkReg(False, clocked_by noc_clk, reset_by noc_rstn);
   PulseWire                  started       <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);
   PulseWire                  finished      <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);

   // The read data is passed to a MsgBuild module to generate the return message
   MsgBuild#(bpb,asz)         msg_build     <- mkMsgBuild(clocked_by noc_clk, reset_by noc_rstn);
   Reg#(Bool)                 send_hdr      <- mkReg(False, clocked_by noc_clk, reset_by noc_rstn);
   FIFO#(Tuple2#(UInt#(bc_sz),UInt#(total_idx_sz))) take_fifo <- mkFIFO(clocked_by noc_clk, reset_by noc_rstn);
   RWire#(SegmentTag)         init_segment  <- mkRWire(clocked_by noc_clk, reset_by noc_rstn);
   RWire#(SegmentTag)         next_segment  <- mkRWire(clocked_by noc_clk, reset_by noc_rstn);
   FIFOF#(SegmentTag)         stag_fifo     <- mkFIFOF(clocked_by noc_clk, reset_by noc_rstn);
   Reg#(UInt#(7))             bytes_needed  <- mkReg(0, clocked_by noc_clk, reset_by noc_rstn);

   UInt#(7) max_segment_size = fromInteger(128 - valueOf(num_data_bytes));

   (* fire_when_enabled, no_implicit_conditions *)
   rule track_busy;
      if (finished)
         busy <= False;
      else if (started)
         busy <= True;
   endrule

   (* fire_when_enabled *)
   rule start_next_request if (!busy && !send_hdr && stag_fifo.notFull());
      let {we,addr,count} = req_fifo.first();
      req_fifo.deq();
      is_wr.bypass(we);
      row_addr.bypass(unpack(pack(addr)[valueOf(byte_addr_sz)-1:valueOf(total_idx_sz)]));
      offset.bypass(truncate(addr));
      remaining.bypass(count);
      send_hdr  <= !we;
      if (count != 0)
         started.send();
      if (!we) begin
         if (count > zeroExtend(max_segment_size)) begin
            segment_count.bypass(max_segment_size);
            init_segment.wset(tagged SegmentTag { end_of_message: False, length_in_bytes: max_segment_size });
         end
         else begin
            segment_count.bypass(truncate(count));
            init_segment.wset(tagged SegmentTag { end_of_message: True, length_in_bytes: truncate(count) });
         end
      end
   endrule

   (* fire_when_enabled *)
   rule gen_bram_write_req if (is_wr && (remaining != 0));
      // take as much available data as we can use, but no more
      UInt#(bc_sz) bytes_to_take = fromInteger(valueOf(num_data_bytes)) - zeroExtend(offset);
      if (remaining < zeroExtend(bytes_to_take))
         bytes_to_take = truncate(remaining);
      if (write_bytes.bytes_available() >= zeroExtend(bytes_to_take)) begin
         write_bytes.deq(bytes_to_take);

         // generate the requests for each slice
         Integer n = 0;
         Integer taken = 0;
         for (Integer i = 0; i < valueOf(num_slices); i = i + 1) begin
            BRAMRequestBE#(addr,Bit#(slice_sz),bytes_per_slice) sliced_req = ?;
            sliced_req.writeen         = '0;
            sliced_req.responseOnWrite = False;
            sliced_req.address         = row_addr;
            sliced_req.datain          = '0;
            for (Integer j = 0; j < valueOf(bytes_per_slice); j = j + 1) begin
               if ((fromInteger(n) >= offset) && (fromInteger(taken) < bytes_to_take)) begin
                  sliced_req.writeen = sliced_req.writeen | (1 << j);
                  sliced_req.datain  = sliced_req.datain  | (zeroExtend(write_bytes.bytes_out()[taken]) << (8*j));
                  taken = taken + 1;
               end
               n = n + 1;
            end
            if (sliced_req.writeen != '0) begin
               mems[i].portA.request.put(sliced_req);
               $display("%0t: writing slice %0d row %0d  data = %x mask = %x", $time(), i, sliced_req.address, sliced_req.datain, sliced_req.writeen);
            end
         end

         // update the request status
         UInt#(total_idx_sz) _new_offset = truncate(zeroExtend(offset) + bytes_to_take);
         offset    <= _new_offset;
         let _new_remaining = remaining - zeroExtend(bytes_to_take);
         remaining <= _new_remaining;
         if (_new_remaining == 0)
            finished.send();
         if (_new_offset == 0)
            row_addr <= row_addr + 1;
      end
   endrule

   (* fire_when_enabled *)
   rule gen_bram_read_req if (  !is_wr
                             && (remaining != 0)
                             && (read_bytes.space_available() >= fromInteger(2*valueOf(num_data_bytes)))
                             && stag_fifo.notFull()
                             );
      // generate a read request for each slice
      for (Integer i = 0; i < valueOf(num_slices); i = i + 1) begin
         BRAMRequestBE#(addr,Bit#(slice_sz),bytes_per_slice) sliced_req = ?;
         sliced_req.writeen         = '0;
         sliced_req.responseOnWrite = False;
         sliced_req.address         = row_addr;
         sliced_req.datain          = ?;
         mems[i].portA.request.put(sliced_req);
         $display("%0t: reading slice %0d row %0d", $time(), i, sliced_req.address);
      end

      // update the request status
      UInt#(bc_sz) bytes_to_take = fromInteger(valueOf(num_data_bytes)) - zeroExtend(offset);
      if (segment_count < zeroExtend(bytes_to_take))
         bytes_to_take = truncate(segment_count);
      take_fifo.enq(tuple2(bytes_to_take,offset));
      UInt#(total_idx_sz) _new_offset = truncate(zeroExtend(offset) + bytes_to_take);
      offset    <= _new_offset;
      let _new_remaining = remaining - zeroExtend(bytes_to_take);
      remaining <= _new_remaining;
      if (_new_remaining == 0)
         finished.send();
      if (  segment_count == zeroExtend(bytes_to_take)
         && remaining     != zeroExtend(bytes_to_take)
         )
      begin
         if (_new_remaining > zeroExtend(max_segment_size)) begin
            segment_count <= max_segment_size;
            next_segment.wset(tagged SegmentTag { end_of_message: False, length_in_bytes: max_segment_size });
         end
         else begin
            segment_count <= truncate(_new_remaining);
            next_segment.wset(tagged SegmentTag { end_of_message: True, length_in_bytes: truncate(_new_remaining) });
         end
      end
      else
         segment_count <= segment_count - zeroExtend(bytes_to_take);
      if (_new_offset == 0)
         row_addr <= row_addr + 1;
   endrule

   // We will never have multiple segments within a single cycle, since
   // the data width should be less than the maximum segment size.
   // But the compiler doesn't know this, so we have to split the
   // stag_fifo enq() into a separate rule so that start_next_request
   // and gen_bram_read_req can be conflict-free.
   (* fire_when_enabled *)
   rule next_segment_tag;
      if (init_segment.wget() matches tagged Valid .stag)
         stag_fifo.enq(stag);
      else if (next_segment.wget() matches tagged Valid .stag)
         stag_fifo.enq(stag);
   endrule

   // take responses from the memories (on portA) and create outbound messages

   rule send_header if (send_hdr);
      let resp_info = resp_info_fifo.first();
      resp_info_fifo.deq();
      msg_build.dst(resp_info.dst);
      msg_build.src(resp_info.src);
      msg_build.msg_type(Completion);
      msg_build.metadata('0);
      msg_build.addr_at_dst(resp_info.addr);
      send_hdr <= False;
   endrule

   (* fire_when_enabled *)
   rule handle_bram_read_resp if (read_bytes.space_available() >= fromInteger(valueOf(num_data_bytes)));
      // figure out how much of the row will be used
      let {bytes_to_take,off} = take_fifo.first();
      take_fifo.deq();

      // gather data from the response slices
      Vector#(num_data_bytes,Bit#(8)) vec = replicate(0);
      Integer n = 0;
      Integer taken = 0;
      for (Integer i = 0; i < valueOf(num_slices); i = i + 1) begin
         let read_data <- mems[i].portA.response.get();
         $display("%0t: read data for slice %0d = %x", $time(), i, read_data);
         for (Integer j = 0; j < valueOf(bytes_per_slice); j = j + 1) begin
            if ((fromInteger(n) >= off) && (fromInteger(taken) < bytes_to_take)) begin
               vec[taken] = truncate(read_data >> (8*j));
               taken = taken + 1;
            end
            n = n + 1;
         end
      end

      // pass the data on to the NoC-handling logic
      read_bytes.enq(bytes_to_take,vec);
   endrule

   rule send_segment_tag if (bytes_needed == 0);
      SegmentTag stag = stag_fifo.first();
      stag_fifo.deq();
      msg_build.segment_tag(stag);
      bytes_needed <= stag.length_in_bytes;
   endrule

   rule send_segment_bytes if (  bytes_needed != 0
                              && read_bytes.bytes_available() != 0
                              && (  zeroExtend(read_bytes.bytes_available()) >= bytes_needed
                                 || read_bytes.bytes_available() >= fromInteger(bytes_per_beat)
                                 )
                              );
      Vector#(bpb,Bool)    mask = replicate(False);
      Vector#(bpb,Bit#(8)) vec  = replicate(0);
      for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
         if (fromInteger(i) < bytes_needed) begin
            mask[i] = True;
            vec[i]  = read_bytes.bytes_out()[i];
         end
      end
      msg_build.segment_bytes.put(tuple2(mask,vec));
      if (bytes_needed <= fromInteger(bytes_per_beat)) begin
         bytes_needed <= 0;
         read_bytes.deq(truncate(bytes_needed));
      end
      else begin
         bytes_needed <= bytes_needed - fromInteger(bytes_per_beat);
         read_bytes.deq(fromInteger(bytes_per_beat));
      end
   endrule

   PulseWire beat_sent <- mkPulseWire(clocked_by noc_clk, reset_by noc_rstn);

   rule advance_to_next_beat if (beat_sent && !stall);
      msg_parse.advance();
   endrule

   // The NoC-facing message port

   interface MsgPort noc;
      interface MsgSink in;
         method dst_rdy = !stall;
         method Action src_rdy(Bool b);
            if (b && !stall)
               beat_sent.send();
         endmethod
         method Action beat(MsgBeat#(bpb,asz) v);
            if (beat_sent)
               msg_parse.beat(v);
         endmethod
      endinterface

      interface MsgSource out = msg_build.source;
   endinterface

   // The user-facing memory port

   interface BRAMServerBE user;

      interface Put request;
         method Action put(BRAMRequestBE#(addr,data,num_data_bytes) req);
            Vector#(num_slices,Bit#(bytes_per_slice)) wens = toChunks(req.writeen);
            Vector#(num_slices,Bit#(slice_sz))        vals = unpack(pack(req.datain));
            Bool is_write = req.writeen != '0;
            for (Integer i = 0; i < valueOf(num_slices); i = i + 1) begin
               BRAMRequestBE#(addr,Bit#(slice_sz),bytes_per_slice) sliced_req = ?;
               sliced_req.writeen         = wens[i];
               sliced_req.responseOnWrite = req.responseOnWrite;
               sliced_req.address         = req.address;
               sliced_req.datain          = vals[i];
               if (!is_write || ((wens[i] != 0) || req.responseOnWrite))
                  mems[i].portB.request.put(sliced_req);
            end // for
         endmethod
      endinterface

      interface Get response;
         method ActionValue#(data) get();
            Vector#(num_slices,Bit#(slice_sz)) vals = ?;
            for (Integer i = 0; i < valueOf(num_slices); i = i + 1) begin
               Bit#(slice_sz) x <- mems[i].portB.response.get();
               vals[i] = x;
            end
            return unpack(pack(vals));
         endmethod
      endinterface
   endinterface

endmodule

endpackage: OnChipBuffer