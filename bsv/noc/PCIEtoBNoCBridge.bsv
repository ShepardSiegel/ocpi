package PCIEtoBNoCBridge;

import GetPut       :: *;
import Vector       :: *;
import FIFO         :: *;
import DefaultValue :: *;
import XilinxPCIE   :: *;

import MsgFormat   :: *;
import MsgXfer     :: *;
import ByteShifter :: *;

interface PCIEtoBNoC#(numeric type bpb, numeric type asz);
   interface GetPut#(TLPData#(16)) tlps;
   interface MsgPort#(bpb,asz)     noc;
   method Bool intr();
   method Bool rx_activity();
   method Bool tx_activity();
endinterface

function Vector#(sz,Bit#(8)) write_v4(Vector#(sz,Bit#(8)) vec, UInt#(isz) idx, Bit#(32) x)
   provisos(Log#(sz,isz));
   Vector#(4,Bit#(8)) xv = unpack(x);
   vec[idx]   = xv[0];
   vec[idx+1] = xv[1];
   vec[idx+2] = xv[2];
   vec[idx+3] = xv[3];
   return vec;
endfunction

module mkPCIEtoBNoC#( Bit#(64)  board_content_id
                    , PciId     my_id
                    , UInt#(13) max_read_req_bytes
                    , UInt#(13) max_payload_bytes
                    , UInt#(8)  read_completion_boundary
                    )
                    (PCIEtoBNoC#(bpb,asz))
   provisos( Add#(asz, _v0, 64) // asz <= 64
           , Add#(_v1, 30, asz) // asz >= 30
           , Add#(_v2, 1, bpb)  // bpb >= 1
           , Add#(_v3, TLog#(TAdd#(TAdd#(bpb,24),1)), 12)
           // compiler should figure these out but doesn't
           , Add#(_v4, TLog#(TAdd#(TMax#(bpb,16),1)), 12)
           , Add#(_v5, TMax#(bpb,16), TAdd#(bpb,24))
           , Add#(_v6, TMul#(bpb,8), TMul#(TMul#(bpb,4),8))
           , Add#(_v7, TLog#(TAdd#(1,bpb)), TLog#(TAdd#(TMul#(bpb,4),1)))
           , Add#(1, _v8, TLog#(TAdd#(1,bpb)))
           , Add#(_v9, 5, TLog#(TAdd#(TAdd#(bpb,24),1)))
           , Add#(_v10, TLog#(TAdd#(TMax#(bpb,16),1)), TLog#(TAdd#(TAdd#(bpb,24),1)))
           , Add#(_v11, TMul#(TMax#(bpb,16),8), TMul#(TAdd#(bpb,24),8))
           , Add#(_v12, 2, TLog#(TAdd#(TMax#(bpb,16),1)))
           , Add#(_v13, 2, asz)
           , Add#(_v14, 8, asz)
           , Add#(_v15, TLog#(TAdd#(bpb,1)), TLog#(TAdd#(TMax#(bpb,16),1)))
           , Add#(_v16, TLog#(TAdd#(bpb,1)), 10)
           , Add#(_v17, 2, TLog#(TAdd#(bpb,1)))
           , Add#(_v18, TLog#(TAdd#(bpb,1)), TLog#(TAdd#(TAdd#(bpb,24),1)))
           , Add#(_v19, TMul#(bpb,8), TMul#(TMax#(bpb,16),8))
           , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
           , Add#(1, _v20, TLog#(TAdd#(bpb,1)))
           , Add#(_v21, 128, TMul#(TAdd#(bpb,24),8))
           , Add#(_v22, TLog#(TAdd#(TAdd#(bpb,24),1)), 8)
           );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkPCIEtoBNoC", bytes_per_beat, addr_size);

   // TLP boundary FIFOs

   FIFO#(TLPData#(16)) tlp_in_fifo  <- mkFIFO();
   FIFO#(TLPData#(16)) tlp_out_fifo <- mkFIFO();

   // NoC boundary message parser and builder

   MsgParse#(bpb,asz) msg_parse <- mkMsgParse();
   MsgBuild#(bpb,asz) msg_build <- mkMsgBuild();

   // define the BAR 0 address map and status registers

   Integer major_rev = 1;
   Integer minor_rev = 0;

   Reg#(UInt#(4)) board_number <- mkReg(15);
   Reg#(Bool)     recv_enabled <- mkReg(False);
   Reg#(Bool)     xmit_enabled <- mkReg(False);
   Reg#(NodeID)   host_nodeid  <- mkReg(unpack(0));

   function Bit#(32) rd_bar0(UInt#(30) addr);
      case (addr % 1024)
         // board identification
         0: return 32'h65756c42; // Blue
         1: return 32'h63657073; // spec
         2: return fromInteger(minor_rev);
         3: return fromInteger(major_rev);
         4: return pack(buildVersion);
         5: return pack(epochTime);
         6: return zeroExtend(pack(board_number));
         7: return {23'd0,pack(addr_size == 64),fromInteger(bytes_per_beat)};
         8: return board_content_id[31:0];
         9: return board_content_id[63:32];
         // network configuration
         25: return {'0,pack(xmit_enabled),pack(recv_enabled)};
         26: return zeroExtend(pack(host_nodeid));
         // unused addresses
         default: return 32'hbad0add0;
      endcase
   endfunction

   function Action wr_bar0(UInt#(30) addr, Bit#(32) v, Bit#(4) be);
      action
         case (addr % 1024)
            // board identification
            6: if (be[0] == 1) board_number <= unpack(v[3:0]);
            // network configuration
            25: if (be[0] == 1) begin
                   recv_enabled <= unpack(v[0]);
                   xmit_enabled <= unpack(v[1]);
                end
            26: if (be[0] == 1) host_nodeid <= unpack(v[7:0]);
         endcase
      endaction
   endfunction

   // define BAR 1 TLP-to-NoC conversions


   // TLP processing

   Reg#(Bool) read_in_progress     <- mkReg(False);
   Reg#(Bool) write_in_progress    <- mkReg(False);
   Reg#(Bool) other_op_in_progress <- mkReg(False);
   Reg#(Bool) forward_req_msg      <- mkReg(False);
   Reg#(Bool) need_rd_bytes        <- mkReg(False);
   Reg#(Bool) header_sent          <- mkReg(False);

   Reg#(TLPTrafficClass)        saved_tc         <- mkRegU();
   Reg#(TLPAttrRelaxedOrdering) saved_attr_ro    <- mkRegU();
   Reg#(TLPAttrNoSnoop)         saved_attr_ns    <- mkRegU();
   Reg#(TLPTag)                 saved_tag        <- mkRegU();
   Reg#(PciId)                  saved_reqid      <- mkRegU();
   Reg#(Bit#(7))                saved_bar        <- mkRegU();
   Reg#(UInt#(30))              saved_addr       <- mkRegU();
   Reg#(UInt#(10))              saved_length     <- mkRegU();
   Reg#(TLPFirstDWBE)           saved_firstbe    <- mkRegU();
   Reg#(TLPLastDWBE)            saved_lastbe     <- mkRegU();

   ByteShifter#(TMax#(bpb,16),16,TAdd#(bpb,24)) rd_bytes         <- mkByteShifter();
   Reg#(UInt#(10))                              dws_to_send      <- mkRegU();
   Reg#(UInt#(2))                               carry_over       <- mkReg(0);
   Reg#(UInt#(30))                              curr_rd_addr     <- mkRegU();
   Reg#(Bool)                                   pad_rd_bytes     <- mkReg(False);
   PulseWire                                    incoming_beat    <- mkPulseWire();

   ByteShifter#(16,bpb,TAdd#(bpb,24))           wr_bytes         <- mkByteShifter();
   Reg#(UInt#(7))                               segment_length   <- mkReg(0);
   FIFO#(SegmentTag)                            new_segment_data <- mkFIFO();

   Bool is_bar0       = (saved_bar == 7'h01);
   Bool is_bar1       = (saved_bar == 7'h02);
   Bool is_unused_bar = !is_bar0 && !is_bar1;

   // handle incoming TLPs

   (* fire_when_enabled *)
   rule dispatch_incoming_TLP if (!read_in_progress && !write_in_progress && !other_op_in_progress);
      TLPData#(16) tlp = tlp_in_fifo.first();
      if (tlp.sof) begin
         // this will be a TLP header
         TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
         if (hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
            // handle a read request
            tlp_in_fifo.deq();
            DWAddress addr = hdr_3dw.addr;
            TLPLength len  = hdr_3dw.length;
            read_in_progress <= True;
            header_sent      <= False;
            saved_tc         <= hdr_3dw.tclass;
            saved_attr_ro    <= hdr_3dw.relaxed;
            saved_attr_ns    <= hdr_3dw.nosnoop;
            saved_tag        <= hdr_3dw.tag;
            saved_reqid      <= hdr_3dw.reqid;
            saved_bar        <= tlp.hit;
            saved_addr       <= unpack(addr);
            saved_length     <= unpack(len);
            saved_firstbe    <= hdr_3dw.firstbe;
            saved_lastbe     <= (len == 1) ? '1 : hdr_3dw.lastbe;
            need_rd_bytes    <= True;
            dws_to_send      <= unpack(len);
            curr_rd_addr     <= unpack(addr);
            forward_req_msg  <= (tlp.hit == 7'h02);
         end
         else if (hdr_3dw.format == MEM_WRITE_3DW_DATA) begin
            // handle a write request
            write_in_progress <= True;
            saved_bar         <= tlp.hit;
            saved_addr        <= unpack(hdr_3dw.addr);
            saved_length      <= unpack(hdr_3dw.length);
            saved_firstbe     <= hdr_3dw.firstbe;
            saved_lastbe      <= (hdr_3dw.length == 1) ? '1 : hdr_3dw.lastbe;
         end
         else begin
            // this is an unexpected TLP type
            other_op_in_progress <= True;
         end
      end
   endrule

   UInt#(12) bytes_to_send = 4 * zeroExtend(dws_to_send);
   Bool rd_bytes_has_enough_space = ((bytes_to_send < 16) && (rd_bytes.space_available() >= truncate(bytes_to_send)))
                                 || (rd_bytes.space_available() >= 16)
                                  ;

   // BAR 0 -- configuration and status registers

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,do_bar0_read" *)
   rule do_bar0_read if (need_rd_bytes && is_bar0 && rd_bytes_has_enough_space);
      Vector#(TMax#(bpb,16),Bit#(8)) vec = replicate('0);
      vec = write_v4(vec,0,rd_bar0(curr_rd_addr));
      if (dws_to_send > 1)
         vec = write_v4(vec,4,rd_bar0(curr_rd_addr + 1));
      if (dws_to_send > 2)
         vec = write_v4(vec,8,rd_bar0(curr_rd_addr + 2));
      if (dws_to_send > 3)
         vec = write_v4(vec,12,rd_bar0(curr_rd_addr + 3));
      if (dws_to_send <= 4) begin
         rd_bytes.enq(truncate(bytes_to_send),vec);
         need_rd_bytes <= False;
      end
      else begin
         rd_bytes.enq(16,vec);
         dws_to_send  <= dws_to_send - 4;
         curr_rd_addr <= curr_rd_addr + 4;
      end
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,do_bar0_write" *)
   (* mutually_exclusive="do_bar0_read,do_bar0_write" *)
   rule do_bar0_write if (write_in_progress && is_bar0);
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      if (tlp.sof) begin
         TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
         Bit#(32) value = byteSwap(hdr_3dw.data);
         wr_bar0(saved_addr, value, saved_firstbe);
      end
      else begin
         Bit#(4) be0 = (saved_length == 1) ? saved_lastbe : '1;
         Bit#(4) be1 = (saved_length == 2) ? saved_lastbe : '1;
         Bit#(4) be2 = (saved_length == 3) ? saved_lastbe : '1;
         Bit#(4) be3 = (saved_length == 4) ? saved_lastbe : '1;
         wr_bar0(saved_addr,byteSwap(tlp.data[127:96]),be0);
         if (saved_length > 1)
            wr_bar0(saved_addr+1,byteSwap(tlp.data[95:64]),be1);
         if (saved_length > 2)
            wr_bar0(saved_addr+2,byteSwap(tlp.data[63:32]),be2);
         if (saved_length > 3)
            wr_bar0(saved_addr+3,byteSwap(tlp.data[31:0]),be3);
      end
      if (tlp.eof)
         write_in_progress <= False;
      else begin
         saved_addr   <= saved_addr + (tlp.sof ? 1 : 4);
         saved_length <= saved_length - (tlp.sof ? 1 : 4);
      end
   endrule

   // BAR 1 -- maps 1 MB of each node's address space

   UInt#(30) one_MB = 1024 * 256; // in DWs

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,do_bar1_read" *)
   (* mutually_exclusive="do_bar0_read,do_bar1_read" *)
   rule do_bar1_read if (forward_req_msg && (rd_bytes.space_available() >= 3));
      NodeID     dst          = unpack(pack(truncate(saved_addr / one_MB)));
      UInt#(2)   unused_first = truncate(countZerosLSB(saved_firstbe));
      UInt#(2)   unused_last  = truncate(countZerosMSB(saved_lastbe));
      UInt#(asz) addr         = (4 * zeroExtend(saved_addr % one_MB)) + zeroExtend(unused_first);
      UInt#(14)  len          = (4 * zeroExtend(saved_length)) - zeroExtend(unused_first) - zeroExtend(unused_last);
      msg_build.dst(dst);
      msg_build.src(host_nodeid);
      msg_build.msg_type(Request);
      msg_build.read_length(len);
      msg_build.addr_at_dst(addr);
      msg_build.addr_at_src(0);
      forward_req_msg <= False;
      carry_over      <= truncate(unused_first);
      if (unused_first != 0)
         rd_bytes.enq(zeroExtend(unused_first),replicate(0));
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,handle_bar1_response" *)
   (* mutually_exclusive="do_bar0_read,handle_bar1_response" *)
   (* mutually_exclusive="do_bar1_read,handle_bar1_response" *)
   rule handle_bar1_response if (  need_rd_bytes
                                && is_bar1
                                && (rd_bytes.space_available() >= fromInteger(bytes_per_beat))
                                && incoming_beat
                                && !pad_rd_bytes
                                /* && src, dst, msg_type are all correct */
                                );
      Vector#(TMax#(bpb,16),Bit#(8)) vec = unpack(zeroExtend(pack(msg_parse.segment_bytes())));
      UInt#(TLog#(TAdd#(bpb,1))) num_bytes = countOnes(pack(msg_parse.valid_mask()));
      if (num_bytes != 0) begin
         UInt#(TLog#(TAdd#(bpb,1))) shift_bytes = zeroExtend(countZerosLSB(pack(msg_parse.valid_mask)));
         UInt#(TAdd#(TLog#(TAdd#(bpb,1)),3)) shift_bits = 8 * zeroExtend(shift_bytes);
         rd_bytes.enq(zeroExtend(num_bytes), unpack(pack(vec) >> shift_bits));
         UInt#(10) dws_sent       = (zeroExtend(num_bytes) + zeroExtend(carry_over)) / 4;
         UInt#(2)  new_carry_over = truncate((num_bytes + zeroExtend(carry_over)) % 4);
         carry_over <= new_carry_over;
         if (zeroExtend(dws_sent) < dws_to_send) begin
            dws_to_send  <= dws_to_send - dws_sent;
            curr_rd_addr <= curr_rd_addr + zeroExtend(dws_sent);
            if (msg_parse.last_beat() && new_carry_over != 0)
               pad_rd_bytes <= True;
         end
         else begin
            need_rd_bytes <= False;
         end
      end
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="do_bar0_read,do_rd_byte_padding" *)
   (* mutually_exclusive="do_bar1_read,do_rd_byte_padding" *)
   (* mutually_exclusive="handle_bar1_response,do_rd_byte_padding" *)
   rule do_rd_byte_padding if (pad_rd_bytes && (rd_bytes.space_available() >= 3));
      rd_bytes.enq(4-zeroExtend(carry_over),replicate(0));
      pad_rd_bytes <= False;
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,do_bar1_write_initial" *)
   (* mutually_exclusive="do_bar1_read,do_bar1_write_initial" *)
   (* mutually_exclusive="do_bar0_write,do_bar1_write_initial" *)
   rule do_bar1_write_initial if (  write_in_progress
                                 && is_bar1
                                 && (wr_bytes.space_available() >= 16)
                                 && tlp_in_fifo.first().sof
                                 );
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      NodeID     dst          = unpack(pack(truncate(saved_addr / one_MB)));
      UInt#(2)   unused_first = truncate(countZerosLSB(saved_firstbe));
      UInt#(2)   unused_last  = truncate(countZerosMSB(saved_lastbe));
      UInt#(asz) addr         = (4 * zeroExtend(saved_addr % one_MB)) + zeroExtend(unused_first);
      UInt#(14)  len          = (4 * zeroExtend(saved_length)) - zeroExtend(unused_first) - zeroExtend(unused_last);
      msg_build.dst(dst);
      msg_build.src(host_nodeid);
      msg_build.msg_type(Write);
      msg_build.metadata('0);
      msg_build.addr_at_dst(addr);
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      Vector#(16,Bit#(8)) vec = replicate('0);
      UInt#(5) num_bytes = 0;
      for (Integer i = 0; i < 4; i = i + 1) begin
         Vector#(4,Bit#(8)) x = unpack(byteSwap(hdr_3dw.data));
         if (hdr_3dw.firstbe[i] == 1) begin
            vec[num_bytes] = x[i];
            num_bytes = num_bytes + 1;
         end
      end // for
      if (len < 128) begin
         let stag = SegmentTag { end_of_message: True, length_in_bytes: truncate(len) };
         new_segment_data.enq(stag);
         segment_length <= truncate(len) - zeroExtend(num_bytes);
      end
      else begin
         let stag = SegmentTag { end_of_message: False, length_in_bytes: 127 };
         new_segment_data.enq(stag);
         segment_length <= 127 - zeroExtend(num_bytes);
      end
      wr_bytes.enq(num_bytes,vec);
      saved_firstbe <= '1;
      saved_addr    <= saved_addr + 1;
      saved_length  <= saved_length - 1;
      if (tlp.eof)
         write_in_progress <= False;
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,do_bar1_write_more" *)
   (* mutually_exclusive="do_bar1_read,do_bar1_write_more" *)
   (* mutually_exclusive="do_bar0_write,do_bar1_write_more" *)
   rule do_bar1_write_more if (  write_in_progress
                              && is_bar1
                              && (wr_bytes.space_available() >= 16)
                              && !tlp_in_fifo.first().sof
                              );
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      UInt#(2)            unused_last = truncate(countZerosMSB(saved_lastbe));
      UInt#(14)           len         = (4 * zeroExtend(saved_length)) - zeroExtend(unused_last);
      Vector#(16,Bit#(8)) vec         = replicate('0);
      for (Integer i = 0; i < 4; i = i + 1) begin
         if (saved_length > fromInteger(i)) begin
            Vector#(4,Bit#(8)) x = unpack(byteSwap(tlp.data[127-(32*i):96-(32*i)]));
            vec[4*i]   = x[0];
            vec[4*i+1] = x[1];
            vec[4*i+2] = x[2];
            vec[4*i+3] = x[3];
         end
      end // for
      if (!tlp.eof) begin
         saved_addr   <= saved_addr + 4;
         saved_length <= saved_length - 4;
      end
      UInt#(5) bytes_sent = (len > 16) ? 16 : truncate(len);
      if (zeroExtend(bytes_sent) > segment_length) begin
         UInt#(14) len_past_segment = len - zeroExtend(segment_length);
         UInt#(5)  extra_bytes = bytes_sent - truncate(segment_length);
         if (len_past_segment < 128) begin
            let stag = SegmentTag { end_of_message: True, length_in_bytes: truncate(len_past_segment) };
            new_segment_data.enq(stag);
            segment_length <= truncate(len_past_segment) - zeroExtend(extra_bytes);
         end
         else begin
            let stag = SegmentTag { end_of_message: False, length_in_bytes: 127 };
            new_segment_data.enq(stag);
            segment_length <= 127 - zeroExtend(extra_bytes);
         end
      end
      else begin
         segment_length <= segment_length - zeroExtend(bytes_sent);
      end
      wr_bytes.enq(bytes_sent,vec);
      if (tlp.eof)
         write_in_progress <= False;
   endrule

   (* fire_when_enabled *)
   rule start_new_segment;
      SegmentTag stag = new_segment_data.first();
      new_segment_data.deq();
      msg_build.segment_tag(stag);
   endrule

   (* fire_when_enabled *)
   rule xmit_wr_payload;
      UInt#(TLog#(TAdd#(bpb,1))) num_bytes = (wr_bytes.bytes_available() < fromInteger(bytes_per_beat))
                                           ? truncate(wr_bytes.bytes_available())
                                           : fromInteger(bytes_per_beat)
                                           ;
      Vector#(bpb,Bit#(8)) vec = replicate('0);
      Vector#(bpb,Bool)    mask = replicate(False);
      for (Integer i = 0; i < bytes_per_beat; i = i + 1) begin
         if (fromInteger(i) < num_bytes) begin
            vec[i] = wr_bytes.bytes_out()[i];
            mask[i] = True;
         end
      end // for
      wr_bytes.deq(num_bytes);
      msg_build.segment_bytes.put(tuple2(mask,vec));
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,ignore_other_read" *)
   (* mutually_exclusive="do_bar0_read,ignore_other_read" *)
   (* mutually_exclusive="do_bar1_read,ignore_other_read" *)
   (* mutually_exclusive="do_rd_byte_padding,ignore_other_read" *)
   rule ignore_other_read if (need_rd_bytes && is_unused_bar && rd_bytes_has_enough_space);
      Vector#(TMax#(16,bpb),Bit#(8)) vec = replicate('0);
      if (dws_to_send <= 4) begin
         rd_bytes.enq(truncate(bytes_to_send),vec);
         need_rd_bytes <= False;
      end
      else begin
         rd_bytes.enq(16,vec);
         dws_to_send  <= dws_to_send - 4;
         curr_rd_addr <= curr_rd_addr + 4;
      end
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,ignore_other_write" *)
   (* mutually_exclusive="ignore_other_read,ignore_other_write" *)
   (* mutually_exclusive="do_bar0_write,ignore_other_write" *)
   (* mutually_exclusive="do_bar1_write_initial,ignore_other_write" *)
   (* mutually_exclusive="do_bar1_write_more,ignore_other_write" *)
   rule ignore_other_write if (write_in_progress && is_unused_bar);
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      if (tlp.eof)
         write_in_progress <= False;
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,ignore_other_op" *)
   (* mutually_exclusive="ignore_other_read,ignore_other_op" *)
   (* mutually_exclusive="ignore_other_write,ignore_other_op" *)
   (* mutually_exclusive="do_bar0_write,ignore_other_op" *)
   (* mutually_exclusive="do_bar1_write_initial,ignore_other_op" *)
   (* mutually_exclusive="do_bar1_write_more,ignore_other_op" *)
   rule ignore_other_op if (other_op_in_progress);
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      if (tlp.eof)
         other_op_in_progress <= False;
   endrule

   // the number of bytes sent in a completion is determined by the
   // the starting address, the number of bytes requested and the
   // PCIe read completion boundary
   UInt#(12) saved_bytes = 4 * zeroExtend(saved_length);
   UInt#(8)  rcb_offset = 4 * ((read_completion_boundary == 64) ? truncate(saved_addr % 16) : truncate(saved_addr % 32));
   UInt#(8)  bytes_to_next_rcb = read_completion_boundary - rcb_offset;
   UInt#(8)  bytes_in_next_completion = (saved_bytes < zeroExtend(bytes_to_next_rcb)) ? truncate(saved_bytes) : bytes_to_next_rcb;
   UInt#(6)  dws_in_next_completion = truncate(bytes_in_next_completion / 4);

   (* fire_when_enabled *)
   (* mutually_exclusive="do_bar0_write,send_read_completion_header" *)
   (* mutually_exclusive="do_bar1_write_initial,send_read_completion_header" *)
   (* mutually_exclusive="do_bar1_write_more,send_read_completion_header" *)
   rule send_read_completion_header if (read_in_progress && !header_sent && (rd_bytes.bytes_available() >= 4));
      TLPCompletionHeader hdr = defaultValue();
      hdr.tclass    = saved_tc;
      hdr.relaxed   = saved_attr_ro;
      hdr.nosnoop   = saved_attr_ns;
      hdr.length    = pack(zeroExtend(dws_in_next_completion));
      hdr.cmplid    = my_id;
      hdr.tag       = saved_tag;
      hdr.bytecount = computeByteCount(pack(saved_length),saved_firstbe,saved_lastbe);
      hdr.reqid     = saved_reqid;
      hdr.tag       = saved_tag;
      hdr.loweraddr = getLowerAddr(pack(saved_addr),saved_firstbe);
      TLPData#(16) tlp;
      let vec = rd_bytes.bytes_out();
      rd_bytes.deq(4);
      Bit#(32) result = {vec[3],vec[2],vec[1],vec[0]};
      tlp.sof = True;
      tlp.eof = (bytes_in_next_completion == 4);
      tlp.hit = saved_bar;
      tlp.be  = { 12'hfff, saved_firstbe };
      hdr.data = byteSwap(result);
      tlp.data = pack(hdr);
      tlp_out_fifo.enq(tlp);
      if (saved_length == 1)
         read_in_progress <= False;
      else begin
         saved_firstbe <= '1;
         saved_addr    <= saved_addr + 1;
         saved_length  <= saved_length - 1;
         if (bytes_to_next_rcb != 4)
            header_sent <= True;
      end
   endrule

   Bool rd_bytes_has_enough_data = ((bytes_in_next_completion < 16) && (rd_bytes.bytes_available() >= truncate(bytes_in_next_completion)))
                                || (rd_bytes.bytes_available() >= 16)
                                 ;

   (* fire_when_enabled *)
   (* mutually_exclusive="do_bar0_write,continue_read_completion" *)
   (* mutually_exclusive="do_bar1_write_initial,continue_read_completion" *)
   (* mutually_exclusive="do_bar1_write_more,continue_read_completion" *)
   rule continue_read_completion if (read_in_progress && header_sent && rd_bytes_has_enough_data);
      TLPData#(16) tlp;
      Bit#(4) be0 = '1;
      Bit#(4) be1 = (dws_in_next_completion > 1) ? '1 : '0;
      Bit#(4) be2 = (dws_in_next_completion > 2) ? '1 : '0;
      Bit#(4) be3 = (dws_in_next_completion > 3) ? '1 : '0;
      let vec = rd_bytes.bytes_out();
      if (bytes_in_next_completion <= 16)
         rd_bytes.deq(truncate(bytes_in_next_completion));
      else
         rd_bytes.deq(16);
      Bit#(32) result0 = {vec[3],vec[2],vec[1],vec[0]};
      Bit#(32) result1 = (dws_in_next_completion > 1) ? {vec[7],vec[6],vec[5],vec[4]} : '0;
      Bit#(32) result2 = (dws_in_next_completion > 2) ? {vec[11],vec[10],vec[9],vec[8]} : '0;
      Bit#(32) result3 = (dws_in_next_completion > 3) ? {vec[15],vec[14],vec[13],vec[12]} : '0;
      tlp.sof = False;
      tlp.eof = (bytes_in_next_completion <= 16);
      tlp.hit = saved_bar;
      tlp.be  = {be0,be1,be2,be3};
      tlp.data = { byteSwap(result0), byteSwap(result1), byteSwap(result2), byteSwap(result3) };
      tlp_out_fifo.enq(tlp);
      if (saved_length <= 4) begin
         read_in_progress <= False;
         header_sent      <= False;
      end
      else begin
         saved_addr   <= saved_addr + 4;
         saved_length <= saved_length - 4;
         if (bytes_to_next_rcb <= 16)
            header_sent <= False;
      end
   endrule

   // interface

   interface GetPut tlps = tuple2(toGet(tlp_out_fifo),toPut(tlp_in_fifo));

   interface MsgPort noc;
      interface MsgSource out = msg_build.source;

      interface MsgSink in;
         method dst_rdy = (rd_bytes.space_available() >= fromInteger(bytes_per_beat));
         method Action src_rdy(Bool b);
            if (b && (rd_bytes.space_available() >= fromInteger(bytes_per_beat))) begin
               incoming_beat.send();
               msg_parse.advance();
            end
         endmethod
         method beat = msg_parse.beat();
      endinterface
   endinterface

   method Bool intr = False;
   method Bool rx_activity = read_in_progress;
   method Bool tx_activity = write_in_progress;

endmodule: mkPCIEtoBNoC

endpackage: PCIEtoBNoCBridge
