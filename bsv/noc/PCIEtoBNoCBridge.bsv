package PCIEtoBNoCBridge;

// This is a package which acts as a bridge between a TLP-based PCIe
// interface on one side and message-based NoC interface on the other.

import GetPut       :: *;
import Vector       :: *;
import FIFO         :: *;
import FIFOF        :: *;
import Counter      :: *;
import DefaultValue :: *;
import XilinxPCIE   :: *;

import MsgFormat     :: *;
import MsgXfer       :: *;
import ByteBuffer    :: *;
import ByteCompactor :: *;

interface PCIEtoBNoC#(numeric type bpb, numeric type asz);
   interface GetPut#(TLPData#(16)) tlps;
   interface MsgPort#(bpb,asz)     noc;
   method Bool rx_activity();
   method Bool tx_activity();
endinterface

interface MSIX_Entry;
   interface Reg#(Bit#(32)) addr_lo;
   interface Reg#(Bit#(32)) addr_hi;
   interface Reg#(Bit#(32)) msg_data;
   interface Reg#(Bool)     masked;
endinterface

module mkMSIXEntry(MSIX_Entry);
   Reg#(Bit#(32)) _addr_lo  <- mkReg(0);
   Reg#(Bit#(32)) _addr_hi  <- mkReg(0);
   Reg#(Bit#(32)) _msg_data <- mkReg(0);
   Reg#(Bool)     _masked   <- mkReg(True);

   interface addr_lo  = _addr_lo;
   interface addr_hi  = _addr_hi;
   interface msg_data = _msg_data;
   interface masked   = _masked;
endmodule

module mkPCIEtoBNoC#( Bit#(64)  board_content_id
                    , PciId     my_id
                    , UInt#(13) max_read_req_bytes
                    , UInt#(13) max_payload_bytes
                    , Bit#(7)   rcb_mask
                    , Bool      msix_enabled
                    , Bool      msix_mask_all_intr
                    )
                    (PCIEtoBNoC#(bpb,asz))
   provisos( Add#(asz, _v0, 64)                 // asz <= 64
           , Add#(1, _v1, TDiv#(bpb,4))         // bpb > 0
           , Add#(_v2, TLog#(TAdd#(1,bpb)), 7)  // bpb <= 64
           // compiler should figure these out, but doesn't
           , Add#(_v3, TLog#(bpb), 7)           // bpb <= 128
           , Add#(1, _v4, TLog#(TAdd#(1,bpb)))
           , Log#(TAdd#(1,bpb), TLog#(TAdd#(bpb,1)))
           , Add#(TAdd#(bpb,20), _v5, TMul#(TDiv#(TMul#(TAdd#(bpb,20),9),36),4))
           );

   Integer bytes_per_beat = valueOf(bpb);
   Integer addr_size      = valueOf(asz);

   check_msg_type_params("mkPCIEtoBNoC", bytes_per_beat, addr_size);

   // TLP boundary FIFOs

   FIFO#(TLPData#(16)) tlp_in_fifo  <- mkFIFO();
   FIFO#(TLPData#(16)) tlp_out_fifo <- mkFIFO();

   // Interrupt information FIFOs

   FIFOF#(Tuple2#(Bit#(64),Bit#(32))) intr_info <- mkFIFOF();

   // There are 3 different outbound TLP sources.
   // We need to make sure that we grant exclusive access
   // to a source until its entire TLP frame is complete.
   UInt#(2) unclaimed          = 0;
   UInt#(2) owned_by_completer = 1;
   UInt#(2) owned_by_noc       = 2;
   UInt#(2) owned_by_intr      = 3;

   Reg#(UInt#(2)) tlp_out_owner <- mkReg(unclaimed);
   PulseWire      req_by_completer <- mkPulseWire();
   PulseWire      req_by_noc       <- mkPulseWire();
   PulseWire      req_by_intr      <- mkPulseWire();
   PulseWire      release_claim    <- mkPulseWireOR();

   (* fire_when_enabled, no_implicit_conditions *)
   rule arbitrate_tlp_out if ((tlp_out_owner == unclaimed) || release_claim);
      if (req_by_completer)
         tlp_out_owner <= owned_by_completer;
      else if (req_by_intr)
         tlp_out_owner <= owned_by_intr;
      else if (req_by_noc)
         tlp_out_owner <= owned_by_noc;
      else
         tlp_out_owner <= unclaimed;
   endrule

   // define the BAR 0 address map and status registers

   // BAR 0 contains the board identification, network
   // configuration information and interrupt tables.

   Integer major_rev = 1;
   Integer minor_rev = 0;

   Reg#(Bool)            is_board_number_assigned <- mkReg(False);
   Reg#(UInt#(4))        board_number             <- mkReg(15);
   Reg#(Bool)            recv_enabled             <- mkReg(False);
   Reg#(Bool)            xmit_enabled             <- mkReg(False);
   Reg#(NodeID)          host_nodeid              <- mkReg(unpack(0));
   Reg#(Bit#(20))        host_buffer_page         <- mkReg(0);
   Reg#(UInt#(12))       host_buffer_head         <- mkReg(0);
   Reg#(UInt#(12))       host_buffer_tail         <- mkReg(0);
   Vector#(4,MSIX_Entry) msix_entry               <- replicateM(mkMSIXEntry);

   UInt#(12) buffer_space_available = (host_buffer_tail > host_buffer_head)
                                    ? (host_buffer_tail - host_buffer_head - 1)
                                    : (4095 - host_buffer_head + host_buffer_tail)
                                    ;

   function Bit#(32) rd_bar0(UInt#(30) addr);
      case (addr % 8192)
         // board identification
         0: return 32'h65756c42; // Blue
         1: return 32'h63657073; // spec
         2: return fromInteger(minor_rev);
         3: return fromInteger(major_rev);
         4: return pack(buildVersion);
         5: return pack(epochTime);
         6: return {27'd0,pack(is_board_number_assigned),pack(board_number)};
         7: return {23'd0,pack(addr_size == 64),fromInteger(bytes_per_beat)};
         8: return board_content_id[31:0];
         9: return board_content_id[63:32];
         // network configuration
         64: return {'0,pack(xmit_enabled),pack(recv_enabled)};
         65: return zeroExtend(pack(host_nodeid));
         // a table of destination buffer addresses
         512: return {host_buffer_page,12'd0};
         513: return {20'd0,pack(host_buffer_head)};
         514: return {20'd0,pack(host_buffer_tail)};
         // 4-entry MSIx table
         4096: return msix_entry[0].addr_lo;            // entry 0 lower address
         4097: return msix_entry[0].addr_hi;            // entry 0 upper address
         4098: return msix_entry[0].msg_data;           // entry 0 msg data
         4099: return {'0, pack(msix_entry[0].masked)}; // entry 0 vector control
         4100: return msix_entry[1].addr_lo;            // entry 1 lower address
         4101: return msix_entry[1].addr_hi;            // entry 1 upper address
         4102: return msix_entry[1].msg_data;           // entry 1 msg data
         4103: return {'0, pack(msix_entry[1].masked)}; // entry 1 vector control
         4104: return msix_entry[2].addr_lo;            // entry 2 lower address
         4105: return msix_entry[2].addr_hi;            // entry 2 upper address
         4106: return msix_entry[2].msg_data;           // entry 2 msg data
         4107: return {'0, pack(msix_entry[2].masked)}; // entry 2 vector control
         4108: return msix_entry[3].addr_lo;            // entry 3 lower address
         4109: return msix_entry[3].addr_hi;            // entry 3 upper address
         4110: return msix_entry[3].msg_data;           // entry 3 msg data
         4111: return {'0, pack(msix_entry[3].masked)}; // entry 3 vector control
         // 4-bit MSIx pending bit field
         5120: return {'0, pack(intr_info.notEmpty())}; // PBA structure (low)
         5121: return '0;                               // PBA structure (high)
         // unused addresses
         default: return 32'hbad0add0;
      endcase
   endfunction

   function t update_dword(t dword_orig, Bit#(4) be, Bit#(32) dword_in) provisos(Bits#(t,32));
      Vector#(4,Bit#(8)) result = unpack(pack(dword_orig));
      Vector#(4,Bit#(8)) vin    = unpack(dword_in);
      for (Integer i = 0; i < 4; i = i + 1)
         if (be[i] != 0) result[i] = vin[i];
      return unpack(pack(result));
   endfunction

   function Action wr_bar0(UInt#(30) addr, Bit#(4) be, Bit#(32) dword);
      action
         case (addr % 8192)
            // board identification
            6:  begin
                   if (be[0] == 1) board_number             <= unpack(dword[3:0]);
                   if (be[1] == 1) is_board_number_assigned <= unpack(dword[8]);
                end
            // network configuration
            64: if (be[0] == 1) begin
                   recv_enabled <= unpack(dword[0]);
                   xmit_enabled <= unpack(dword[1]);
                end
            65: if (be[0] == 1) host_nodeid <= unpack(dword[7:0]);
            // a table of destination buffer addresses
            512: host_buffer_page <= update_dword({host_buffer_page,12'd0}, be, dword)[31:12];
            513: host_buffer_head <= truncate(update_dword(zeroExtend(host_buffer_head), be, dword));
            514: host_buffer_tail <= truncate(update_dword(zeroExtend(host_buffer_tail), be, dword));
            // MSIx table entries
            4096: msix_entry[0].addr_lo  <= update_dword(msix_entry[0].addr_lo, be, (dword & 32'hfffffffc));
            4097: msix_entry[0].addr_hi  <= update_dword(msix_entry[0].addr_hi, be, dword);
            4098: msix_entry[0].msg_data <= update_dword(msix_entry[0].msg_data, be, dword);
            4099: if (be[0] == 1) msix_entry[0].masked <= unpack(dword[0]);
            4100: msix_entry[1].addr_lo  <= update_dword(msix_entry[1].addr_lo, be, (dword & 32'hfffffffc));
            4101: msix_entry[1].addr_hi  <= update_dword(msix_entry[1].addr_hi, be, dword);
            4102: msix_entry[1].msg_data <= update_dword(msix_entry[1].msg_data, be, dword);
            4103: if (be[0] == 1) msix_entry[1].masked <= unpack(dword[0]);
            4104: msix_entry[2].addr_lo  <= update_dword(msix_entry[2].addr_lo, be, (dword & 32'hfffffffc));
            4105: msix_entry[2].addr_hi  <= update_dword(msix_entry[2].addr_hi, be, dword);
            4106: msix_entry[2].msg_data <= update_dword(msix_entry[2].msg_data, be, dword);
            4107: if (be[0] == 1) msix_entry[2].masked <= unpack(dword[0]);
            4108: msix_entry[3].addr_lo  <= update_dword(msix_entry[3].addr_lo, be, (dword & 32'hfffffffc));
            4109: msix_entry[3].addr_hi  <= update_dword(msix_entry[3].addr_hi, be, dword);
            4110: msix_entry[3].msg_data <= update_dword(msix_entry[3].msg_data, be, dword);
            4111: if (be[0] == 1) msix_entry[3].masked <= unpack(dword[0]);
         endcase
      endaction
   endfunction

   // Define the BAR1 TLP-to-NoC conversion

   // BAR 1 converts written data directly into NoC messages.

   ByteCompactor#(16,bpb,TAdd#(bpb,20)) wr_data <- mkByteCompactor();

   function Maybe#(t) mkMaybe(Bool valid, t x);
      return valid ? tagged Valid x : tagged Invalid;
   endfunction

   function Action wr_bar1(Vector#(4,Tuple2#(Bit#(4),Bit#(32))) dwords);
      action
         Vector#(16,Bool)    mask  = unpack(pack(map(tpl_1,dwords)));
         Vector#(16,Bit#(8)) bytes = unpack(pack(map(tpl_2,dwords)));
         Vector#(16,Maybe#(Bit#(8))) vec = zipWith(mkMaybe,mask,bytes);
         wr_data.enq(vec);
      endaction
   endfunction

   // TLP processing

   Reg#(Bool) read_in_progress     <- mkReg(False);
   Reg#(Bool) write_in_progress    <- mkReg(False);
   Reg#(Bool) other_op_in_progress <- mkReg(False);
   Reg#(Bool) need_rd_bytes        <- mkReg(False);
   Reg#(Bool) header_sent          <- mkReg(False);

   Reg#(TLPTrafficClass)        saved_tc      <- mkRegU();
   Reg#(TLPAttrRelaxedOrdering) saved_attr_ro <- mkRegU();
   Reg#(TLPAttrNoSnoop)         saved_attr_ns <- mkRegU();
   Reg#(TLPTag)                 saved_tag     <- mkRegU();
   Reg#(PciId)                  saved_reqid   <- mkRegU();
   Reg#(Bit#(7))                saved_bar     <- mkRegU();
   Reg#(UInt#(30))              saved_addr    <- mkRegU();
   Reg#(UInt#(10))              saved_length  <- mkRegU();
   Reg#(TLPFirstDWBE)           saved_firstbe <- mkRegU();
   Reg#(TLPLastDWBE)            saved_lastbe  <- mkRegU();

   ByteBuffer#(16) completion_tlp <- mkByteBuffer();
   Reg#(UInt#(13)) bytes_to_send  <- mkRegU();
   Reg#(UInt#(32)) curr_rd_addr   <- mkRegU();

   Bool is_bar0       = (saved_bar == 7'h01);
   Bool is_bar1       = (saved_bar == 7'h02);
   Bool is_unused_bar = !is_bar0 && !is_bar1;

   // the number of bytes sent in a completion is determined by the
   // the starting address, the number of bytes requested and the
   // PCIe read completion boundary

   function UInt#(8) bytes_to_next_completion_boundary(DWAddress addr);
      UInt#(8)  rcb_offset  = unpack({1'b0,truncate({pack(addr),2'b00}) & rcb_mask});
      UInt#(8)  bytes_to_next_rcb = unpack(~pack(rcb_offset - 1) & {1'b0,rcb_mask});
      return (rcb_offset == 0) ? unpack(zeroExtend(rcb_mask) + 1) : bytes_to_next_rcb;
   endfunction

   function UInt#(6) dws_in_completion(TLPLength dws_remaining, DWAddress starting_addr);
      UInt#(12) num_bytes = 4 * zeroExtend(unpack(dws_remaining));
      UInt#(8)  bytes_to_next_rcb = bytes_to_next_completion_boundary(starting_addr);
      UInt#(6)  dws_in_next_completion = truncate(min(num_bytes,zeroExtend(bytes_to_next_rcb)) / 4);
      return dws_in_next_completion;
   endfunction

   Reg#(UInt#(6)) dws_left_in_tlp <- mkReg(0);

   // handle incoming TLPs

   FIFO#(UInt#(30)) bar0_rd_addr <- mkFIFO();

   // less urgent than pad_completion_TLP (happens at read completion boundaries)
   rule do_bar0_read if (completion_tlp.valid_mask() != replicate(True));
      UInt#(30) addr = bar0_rd_addr.first();
      bar0_rd_addr.deq();
      Vector#(4,Bit#(8)) result = unpack(byteSwap(rd_bar0(addr)));
      Bit#(16) mask = pack(completion_tlp.valid_mask());
      // note firstbe is already handled in dispatch_incoming_TLP
      if (mask[15:12] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[12+i] == 0) completion_tlp.bytes[12+i] <= result[i];
      end
      else if (mask[11:8] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[8+i] == 0) completion_tlp.bytes[8+i] <= result[i];
      end
      else if (mask[7:4] != '1) begin
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[4+i] == 0) completion_tlp.bytes[4+i] <= result[i];
      end
      else
         for (Integer i = 0; i < 4; i = i + 1)
            if (mask[i] == 0) completion_tlp.bytes[i] <= result[i];
   endrule: do_bar0_read

   // read byte_count bytes starting at byte address addr
   function ActionValue#(UInt#(13)) do_read(Bit#(7) hit, UInt#(13) byte_count, UInt#(32) addr);
      actionvalue
         UInt#(13) bytes_covered = byte_count;
         if (hit == 7'h01) begin
            UInt#(3) bytes_in_dword = 4 - truncate(addr % 4);
            UInt#(3) bytes_to_read = (byte_count < zeroExtend(bytes_in_dword)) ? truncate(byte_count) : bytes_in_dword;
            bar0_rd_addr.enq(truncate(addr/4));
            bytes_covered = zeroExtend(bytes_to_read);
         end
         return bytes_covered;
      endactionvalue
   endfunction: do_read

   // supply data (with dword granularity and byte enables) to be
   // written.
   function Action write_data(Vector#(4,Tuple2#(Bit#(4),Bit#(32))) value);
      action
         if (is_bar0) begin
            wr_bar0(saved_addr,  tpl_1(value[0]),tpl_2(value[0]));
            wr_bar0(saved_addr+1,tpl_1(value[1]),tpl_2(value[1]));
            wr_bar0(saved_addr+2,tpl_1(value[2]),tpl_2(value[2]));
            wr_bar0(saved_addr+3,tpl_1(value[3]),tpl_2(value[3]));
         end
         else if (is_bar1) begin
            wr_bar1(value);
         end
      endaction
   endfunction

   (* fire_when_enabled *)
   (* mutually_exclusive = "do_bar0_read,dispatch_incoming_TLP" *) // why: do_bar0_read requires read_in_progress
   rule dispatch_incoming_TLP if (!read_in_progress && !write_in_progress && !other_op_in_progress);
      TLPData#(16) tlp = tlp_in_fifo.first();
      if (tlp.sof) begin
         // this will be a TLP header
         TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
         if (hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
            // handle a read request
            tlp_in_fifo.deq();
            if (tlp.hit == 7'h01) begin
               DWAddress addr = hdr_3dw.addr;
               TLPLength len  = hdr_3dw.length;
               Bit#(12) _byte_count = computeByteCount(len,hdr_3dw.firstbe,hdr_3dw.lastbe);
               TLPLowerAddr _lower_addr = getLowerAddr(addr,hdr_3dw.firstbe);
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
               bytes_to_send    <= unpack({pack(_byte_count == '0),_byte_count});
               curr_rd_addr     <= unpack({addr[29:5],_lower_addr});
               dws_left_in_tlp  <= dws_in_completion(len,addr);
               // write first 3 DWs of header into completion TLP buffer
               TLPCompletionHeader rc_hdr = defaultValue();
               rc_hdr.tclass    = hdr_3dw.tclass;
               rc_hdr.relaxed   = hdr_3dw.relaxed;
               rc_hdr.nosnoop   = hdr_3dw.nosnoop;
               rc_hdr.length    = pack(zeroExtend(dws_in_completion(len,addr)));
               rc_hdr.cmplid    = my_id;
               rc_hdr.tag       = hdr_3dw.tag;
               rc_hdr.bytecount = _byte_count;
               rc_hdr.reqid     = hdr_3dw.reqid;
               rc_hdr.tag       = hdr_3dw.tag;
               rc_hdr.loweraddr = _lower_addr;
               Vector#(16,Bit#(8)) rc_hdr_dws = unpack(pack(rc_hdr));
               completion_tlp.clear();
               for (Integer i = 4; i < 16; i = i + 1)
                  completion_tlp.bytes[i] <= rc_hdr_dws[i];
               // add padding for unused bytes in first word
               for (Integer i = 0; i < 4; i = i + 1)
                  if (hdr_3dw.firstbe[i] == 0) completion_tlp.bytes[3-i] <= ?;
            end
            else begin
               // we only expect reads from BAR 0
               other_op_in_progress <= True;
            end
         end
         else if (hdr_3dw.format == MEM_WRITE_3DW_DATA) begin
            // handle a write request
            if (tlp.hit == 7'h01 || (tlp.hit == 7'h02 && recv_enabled)) begin
               // don't deq tlp -- it will be used and deq'ed in the supply_write_data rule
               write_in_progress <= True;
               saved_bar         <= tlp.hit;
               saved_addr        <= unpack(hdr_3dw.addr);
               saved_length      <= unpack(hdr_3dw.length);
               saved_firstbe     <= hdr_3dw.firstbe;
               saved_lastbe      <= (hdr_3dw.length == 1) ? '1 : hdr_3dw.lastbe;
            end
            else begin
               // write to an unexpected BAR
               other_op_in_progress <= True;
            end
         end
         else begin
            // this is an unexpected TLP type
            other_op_in_progress <= True;
         end
      end
   endrule: dispatch_incoming_TLP

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,initiate_read" *) // why: need_rd_bytes is set in dispatch_incoming_TLP
   rule initiate_read if (need_rd_bytes);
      UInt#(13) bytes_covered_by_request <- do_read(saved_bar, bytes_to_send, curr_rd_addr);
      if (bytes_covered_by_request == bytes_to_send)
         need_rd_bytes <= False;
      else begin
         bytes_to_send <= bytes_to_send - bytes_covered_by_request;
         curr_rd_addr  <= curr_rd_addr + zeroExtend(bytes_covered_by_request);
      end
   endrule: initiate_read

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,supply_write_data" *) // why: write_in_progress
   (* mutually_exclusive="initiate_read,supply_write_data" *)         // why: only one of read/write in progress
   rule supply_write_data if (write_in_progress);
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      Vector#(4,Tuple2#(Bit#(4),Bit#(32))) vec = replicate(tuple2(4'h0,?));
      if (tlp.sof) begin
         TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
         vec[0] = tuple2(saved_firstbe, byteSwap(hdr_3dw.data));
      end
      else begin
         vec[0] = tuple2((saved_length == 1) ? saved_lastbe : 4'hf, byteSwap(tlp.data[127:96]));
         vec[1] = tuple2((saved_length == 2) ? saved_lastbe : ((saved_length < 2) ? 4'h0 : 4'hf), byteSwap(tlp.data[95:64]));
         vec[2] = tuple2((saved_length == 3) ? saved_lastbe : ((saved_length < 3) ? 4'h0 : 4'hf), byteSwap(tlp.data[63:32]));
         vec[3] = tuple2((saved_length == 4) ? saved_lastbe : ((saved_length < 4) ? 4'h0 : 4'hf), byteSwap(tlp.data[31:0]));
      end
      write_data(vec);
      if (tlp.eof)
         write_in_progress <= False;
      else begin
         saved_addr   <= saved_addr + (tlp.sof ? 1 : 4);
         saved_length <= saved_length - (tlp.sof ? 1 : 4);
      end
   endrule: supply_write_data

   (* mutually_exclusive="dispatch_incoming_TLP,ignore_unknown_tlps" *) // why: other_op_in_progress
   (* mutually_exclusive="initiate_read,ignore_unknown_tlps" *)         // why: only one of read/other op in progress
   (* mutually_exclusive="supply_write_data,ignore_unknown_tlps" *)     // why: only one of write/other op in progress
   rule ignore_unknown_tlps if (other_op_in_progress);
      TLPData#(16) tlp = tlp_in_fifo.first();
      tlp_in_fifo.deq();
      if (tlp.eof)
         other_op_in_progress <= False;
   endrule

   // construct completion TLPs

   function UInt#(6) dws_in_buffer(Bit#(16) mask);
      if (mask[3:0] != '0)
         return 4;
      else if (mask[7:4] != '0)
         return 3;
      else if (mask[11:8] != '0)
         return 2;
      else if (mask[15:12] != 0)
         return 1;
      else return 0;
   endfunction

   UInt#(6) dws_in_completion_tlp_buffer = dws_in_buffer(pack(completion_tlp.valid_mask()));
   Bool need_to_pad = (dws_in_completion_tlp_buffer != 4) && (dws_left_in_tlp == dws_in_completion_tlp_buffer);

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,pad_completion_TLP" *) // why: read_in_progress
   (* descending_urgency="pad_completion_TLP,do_bar0_read" *) // why: pause read data at read completion boundary
   rule pad_completion_TLP if (read_in_progress && need_to_pad);
      for (Integer i = 0; i < 16; i = i + 1) begin
         if (!completion_tlp.valid_mask()[i])
            completion_tlp.bytes[i] <= ?;
      end
   endrule: pad_completion_TLP

   (* fire_when_enabled, no_implicit_conditions *)
   rule req_completion_TLP_output if ((completion_tlp.valid_mask() == replicate(True)) && (tlp_out_owner != owned_by_completer));
      req_by_completer.send();
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive="dispatch_incoming_TLP,send_completion_TLP" *) // why: read_in_progress is cleared by send_completion_TLP
   (* mutually_exclusive="do_bar0_read,send_completion_TLP" *) // why: completion_tlp not-full vs. full
   (* mutually_exclusive="pad_completion_TLP,send_completion_TLP" *) // why: completion_tlp not-full vs. full
   (* mutually_exclusive="supply_write_data,send_completion_TLP" *) // why: read_in_progess, not write
   rule send_completion_TLP if ((completion_tlp.valid_mask() == replicate(True)) && (tlp_out_owner == owned_by_completer));
      TLPData#(16) tlp;
      UInt#(8) bytes_in_next_completion = 4 * zeroExtend(dws_left_in_tlp);
      if (!header_sent) begin
         tlp.sof = True;
         tlp.eof = (bytes_in_next_completion == 4);
         tlp.be  = { 12'hfff, saved_firstbe };
      end
      else begin
         Bit#(4) be0 = '1;
         Bit#(4) be1 = (dws_left_in_tlp > 1) ? '1 : '0;
         Bit#(4) be2 = (dws_left_in_tlp > 2) ? '1 : '0;
         Bit#(4) be3 = (dws_left_in_tlp > 3) ? '1 : '0;
         tlp.sof = False;
         tlp.eof = (bytes_in_next_completion <= 16);
         tlp.be  = {be0,be1,be2,be3};
      end
      tlp.hit = saved_bar;
      tlp.data = pack(readVReg(completion_tlp.bytes));
      tlp_out_fifo.enq(tlp);
      completion_tlp.clear();
      if (tlp.eof)
         release_claim.send();
      UInt#(3) dws_sent = header_sent ? truncate(min(4,dws_left_in_tlp)) : 1;
      if (saved_length <= zeroExtend(dws_sent)) begin
         read_in_progress <= False;
         header_sent      <= False;
      end
      else begin
         saved_firstbe <= '1;
         UInt#(30) new_saved_addr   = saved_addr   + zeroExtend(dws_sent);
         UInt#(10) new_saved_length = saved_length - zeroExtend(dws_sent);
         saved_addr    <= new_saved_addr;
         saved_length  <= new_saved_length;
         UInt#(8) bytes_to_next_rcb = bytes_to_next_completion_boundary(pack(saved_addr));
         if (bytes_to_next_rcb > 4 * zeroExtend(dws_sent)) begin
            header_sent <= True;
            dws_left_in_tlp <= dws_left_in_tlp - zeroExtend(dws_sent);
         end
         else begin
            // set up for a new read completion header
            header_sent <= False;
            UInt#(6) dws_in_next_completion = dws_in_completion(pack(new_saved_length),pack(new_saved_addr));
            dws_left_in_tlp <= dws_in_next_completion;
            TLPCompletionHeader rc_hdr = defaultValue();
            rc_hdr.tclass    = saved_tc;
            rc_hdr.relaxed   = saved_attr_ro;
            rc_hdr.nosnoop   = saved_attr_ns;
            rc_hdr.length    = pack(zeroExtend(dws_in_next_completion));
            rc_hdr.cmplid    = my_id;
            rc_hdr.bytecount = computeByteCount(pack(saved_length),saved_firstbe,saved_lastbe);
            rc_hdr.reqid     = saved_reqid;
            rc_hdr.tag       = saved_tag;
            rc_hdr.loweraddr = getLowerAddr(pack(saved_addr),saved_firstbe);
            Vector#(16,Bit#(8)) rc_hdr_dws = unpack(pack(rc_hdr));
            for (Integer i = 4; i < 16; i = i + 1)
               completion_tlp.bytes[i] <= rc_hdr_dws[i];
         end
      end
   endrule: send_completion_TLP

   // handle incoming NoC messages

   PulseWire                            incoming_beat <- mkUnsafePulseWire();
   MsgParse#(bpb,asz)                   msg_parse     <- mkMsgParse();
   ByteCompactor#(bpb,16,TAdd#(bpb,20)) rd_data       <- mkByteCompactor();
   Wire#(MsgBeat#(bpb,asz))             current_beat  <- mkWire();

   rule advance_to_next_beat if (incoming_beat && xmit_enabled);
      Vector#(bpb,Maybe#(Bit#(8))) vec = zipWith(mkMaybe,replicate(True),unpack(current_beat));
      rd_data.enq(vec);
      msg_parse.advance();
   endrule

   ByteBuffer#(16)    outbound_tlp      <- mkByteBuffer();
   Reg#(Bit#(16))     outbound_bes      <- mkReg('0);
   Reg#(Bool)         first_segment     <- mkReg(True);
   Reg#(Bool)         header_sent_out   <- mkReg(False);
   Reg#(Bool)         first_tlp         <- mkReg(True);
   FIFOF#(MsgType)    msg_type_out      <- mkFIFOF();
   FIFOF#(SegmentTag) segment_tag_out   <- mkFIFOF();
   Counter#(8)        bytes_in_msg      <- mkCounter(0);
   Reg#(UInt#(8))     bytes_left_in_tlp <- mkReg(0);

   (* fire_when_enabled *)
   rule capture_msg_type if (xmit_enabled);
      MsgType mt = msg_parse.msg_type();
      msg_type_out.enq(mt);
   endrule

   (* fire_when_enabled *)
   rule capture_segment_tag if (xmit_enabled);
      SegmentTag stag = msg_parse.segment_tag();
      segment_tag_out.enq(stag);
   endrule

   (* fire_when_enabled *)
   rule start_rd_msg if ((msg_type_out.first() == Request) && first_segment && (bytes_in_msg.value() < 128));
      msg_type_out.deq();
      Integer rd_size = 4 + 2*(addr_size/8);
      UInt#(8) padded_rd_size = fromInteger((rd_size + bytes_per_beat - 1) / bytes_per_beat);
      bytes_in_msg.inc(pack(padded_rd_size));
   endrule

   (* fire_when_enabled *)
   rule start_wr_msg if ((msg_type_out.first() != Request) && first_segment && (bytes_in_msg.value() < 128));
      MsgType mt = msg_type_out.first();
      msg_type_out.deq();
      SegmentTag stag = segment_tag_out.first();
      segment_tag_out.deq();
      UInt#(8) seg_size = (mt == Datagram)
                        ? (4 + zeroExtend(stag.length_in_bytes))
                        : (fromInteger(4 + (addr_size/8)) + zeroExtend(stag.length_in_bytes))
                        ;
      UInt#(8) padded_seg_size = (seg_size % fromInteger(bytes_per_beat) == 0)
                               ? seg_size
                               : (((seg_size / fromInteger(bytes_per_beat)) + 1) * fromInteger(bytes_per_beat))
                               ;
      bytes_in_msg.inc(pack(padded_seg_size));
      if (!stag.end_of_message)
         first_segment <= False;
   endrule

   (* fire_when_enabled *)
   rule handle_next_segment if (!first_segment && (bytes_in_msg.value() < 128));
      SegmentTag stag = segment_tag_out.first();
      segment_tag_out.deq();
      UInt#(8) seg_size = 1 + zeroExtend(stag.length_in_bytes);
      UInt#(8) padded_seg_size = (seg_size % fromInteger(bytes_per_beat) == 0)
                               ? seg_size
                               : (((seg_size / fromInteger(bytes_per_beat)) + 1) * fromInteger(bytes_per_beat))
                               ;
      bytes_in_msg.inc(pack(padded_seg_size));
      if (stag.end_of_message)
         first_segment <= True;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   (* mutually_exclusive = "supply_write_data,write_outbound_tlp_header" *) // why: user should not change DMA buffer while transmission is enabled
   rule write_outbound_tlp_header if (  !header_sent_out
                                     && (bytes_in_msg.value() != 0)
                                     && (outbound_bes == '0)
                                     && (buffer_space_available >= 128)
                                     );
      UInt#(2) first_dw_start = (bytes_per_beat >= 4) ? 0 : truncate(host_buffer_head % 4);
      UInt#(13) padded_size = min(max_payload_bytes,zeroExtend(unpack(bytes_in_msg.value())) + zeroExtend(first_dw_start));
      UInt#(3) bytes_in_last_dw = ((bytes_per_beat >= 4) || (padded_size % 4 == 0)) ? 4 : truncate(padded_size % 4);
      TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
      hdr_3dw.format = MEM_WRITE_3DW_DATA;
      hdr_3dw.tag = 0;
      hdr_3dw.reqid = my_id;
      hdr_3dw.length = pack(padded_size / 4)[9:0] + ((bytes_in_last_dw == 4) ? 0 : 1);
      hdr_3dw.firstbe = '1 << first_dw_start;
      hdr_3dw.lastbe = ~('1 << bytes_in_last_dw);
      // for now, assume all packets go to a low-memory buffer on the host
      hdr_3dw.addr = {host_buffer_page,pack(host_buffer_head)[11:2]};
      for (Integer i = 4; i < 16; i = i + 1)
         outbound_tlp.bytes[i] <= pack(hdr_3dw)[8*i+7:8*i];
      outbound_bes <= 16'hfff0;
      header_sent_out <= True;
      UInt#(8) bytes_sent = truncate(padded_size - zeroExtend(first_dw_start));
      bytes_left_in_tlp <= bytes_sent;
      host_buffer_head <= host_buffer_head + zeroExtend(bytes_sent);
   endrule

   (* fire_when_enabled *)
   rule write_outbound_tlp_data if (header_sent_out && (outbound_tlp.valid_mask() != replicate(True)));
      Bit#(16) mask = pack(map(isValid,rd_data.first()));
      if (outbound_bes[15:4] == '1) begin
         // we need to supply 1 DW of data
         if (mask[3:0] == '1) begin
            for (Integer i = 0; i < 4; i = i + 1)
               outbound_tlp.bytes[3-i] <= validValue(rd_data.first()[i]);
            outbound_bes <= '1;
            rd_data.deq(4);
            bytes_left_in_tlp <= bytes_left_in_tlp - 4;
            bytes_in_msg.dec(4);
            if (bytes_left_in_tlp == 4)
               header_sent_out <= False;
         end
      end
      else if (outbound_bes == '0) begin
         // we need to supply up to 4DWs of data, but possibly less
         UInt#(8) bytes_to_take = min(bytes_left_in_tlp,16);
         Bit#(16) required_mask = ~('1 << bytes_to_take);
         if ((mask & required_mask) == required_mask) begin
            for (Integer i = 0; i < 16; i = i + 1) begin
               Integer dw  = 3 - (i / 4);
               Integer idx = 3 - (i % 4);
               if (required_mask[i] != 0)
                  outbound_tlp.bytes[4*dw+idx] <= validValue(rd_data.first()[i]);
               else
                  outbound_tlp.bytes[4*dw+idx] <= '0; // padding
            end
            outbound_bes <= ~('1 >> bytes_to_take);
            rd_data.deq(truncate(bytes_to_take));
            bytes_left_in_tlp <= bytes_left_in_tlp - bytes_to_take;
            bytes_in_msg.dec(pack(bytes_to_take));
            if (bytes_left_in_tlp == bytes_to_take)
               header_sent_out <= False;
         end
      end
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule req_outbound_TLP_output if ((outbound_tlp.valid_mask() == replicate(True)) && (tlp_out_owner != owned_by_noc));
      req_by_noc.send();
   endrule

   (* fire_when_enabled *)
   (* mutually_exclusive = "write_outbound_tlp_header, send_outbound_TLP" *) // why: outbound_bes
   rule send_outbound_TLP if ((outbound_tlp.valid_mask() == replicate(True)) && (tlp_out_owner == owned_by_noc));
      TLPData#(16) tlp;
      tlp.sof = first_tlp;
      tlp.eof = !header_sent_out;
      tlp.hit = 7'h02;
      tlp.be  = outbound_bes;
      tlp.data = pack(readVReg(outbound_tlp.bytes));
      tlp_out_fifo.enq(tlp);
      outbound_tlp.clear();
      outbound_bes <= '0;
      first_tlp <= !header_sent_out;
      if (tlp.eof)
         release_claim.send();
   endrule: send_outbound_TLP

   // generate MSIx interrupts

   Reg#(Bool)      buffer_space_is_low <- mkReg(False);
   Reg#(Bool)      is_end_of_msg       <- mkReg(False);
   ByteBuffer#(16) intr_tlp            <- mkByteBuffer();
   Reg#(Bool)      intr_header_done    <- mkReg(False);
   Reg#(Bool)      intr_in_one_tlp     <- mkRegU();
   Reg#(Bool)      second_tlp          <- mkRegU();
   PulseWire       need_intr           <- mkPulseWireOR();

   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_on_low_buffer;
      Bool low = buffer_space_available < 512;
      if (low && !buffer_space_is_low)
         need_intr.send();
      buffer_space_is_low <= low;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule trigger_intr_on_eom;
      Bool eom = xmit_enabled && msg_parse.last_beat();
      if (eom && !is_end_of_msg)
         need_intr.send();
      is_end_of_msg <= eom;
   endrule

   (* fire_when_enabled *)
   rule initiate_intr if (need_intr && msix_enabled);
      if (!intr_info.notEmpty())
         intr_info.enq(tuple2({msix_entry[0].addr_hi,msix_entry[0].addr_lo},msix_entry[0].msg_data));
   endrule

   (* fire_when_enabled *)
   rule write_intr_tlp_header if (!intr_header_done && !msix_mask_all_intr && !msix_entry[0].masked);
      let {addr,data} = intr_info.first();
      if (addr[63:32] == '0) begin
         TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
         hdr_3dw.format = MEM_WRITE_3DW_DATA;
         hdr_3dw.tag = 0;
         hdr_3dw.reqid = my_id;
         hdr_3dw.length = 1;
         hdr_3dw.firstbe = '1;
         hdr_3dw.lastbe = '1;
         hdr_3dw.addr = addr[31:2];
         for (Integer i = 4; i < 16; i = i + 1)
            intr_tlp.bytes[i] <= pack(hdr_3dw)[8*i+7:8*i];
         intr_in_one_tlp <= True;
      end
      else begin
         TLPMemory4DWHeader hdr_4dw = defaultValue();
         hdr_4dw.format = MEM_WRITE_4DW_DATA;
         hdr_4dw.tag = 0;
         hdr_4dw.reqid = my_id;
         hdr_4dw.length = 1;
         hdr_4dw.firstbe = '1;
         hdr_4dw.lastbe = '1;
         hdr_4dw.addr = addr[63:2];
         for (Integer i = 0; i < 16; i = i + 1)
            intr_tlp.bytes[i] <= pack(hdr_4dw)[8*i+7:8*i];
         intr_in_one_tlp <= False;
      end
      intr_header_done <= True;
   endrule

   (* fire_when_enabled *)
   rule write_intr_tlp_data if (intr_header_done && (intr_tlp.valid_mask() != replicate(True)));
      let {addr,data} = intr_info.first();
      intr_info.deq();
      Bit#(32) value = byteSwap(data);
      if (intr_in_one_tlp) begin
         for (Integer i = 0; i < 4; i = i + 1)
            intr_tlp.bytes[i] <= value[8*i+7:8*i];
      end
      else begin
         for (Integer i = 0; i < 4; i = i + 1)
            intr_tlp.bytes[12+i] <= value[8*i+7:8*i];
         for (Integer i = 0; i < 12; i = i + 1)
            intr_tlp.bytes[i] <= ?;
      end
      intr_header_done <= False;
      second_tlp       <= False;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule req_intr_TLP_output if ((intr_tlp.valid_mask() == replicate(True)) && (tlp_out_owner != owned_by_intr));
      req_by_intr.send();
   endrule

   (* fire_when_enabled *)
   rule send_intr_TLP if ((intr_tlp.valid_mask() == replicate(True)) && (tlp_out_owner == owned_by_intr));
      TLPData#(16) tlp;
      Bool end_of_frame = second_tlp || intr_in_one_tlp;
      tlp.sof = !second_tlp;
      tlp.eof = end_of_frame;
      tlp.hit = 7'h01;
      tlp.be  = second_tlp ? 16'h000f : 16'hffff;
      tlp.data = pack(readVReg(intr_tlp.bytes));
      if (msix_enabled)
         tlp_out_fifo.enq(tlp);
      intr_tlp.clear();
      second_tlp <= !end_of_frame;
      if (end_of_frame)
         release_claim.send();
   endrule: send_intr_TLP

   // interface

   interface GetPut tlps = tuple2(toGet(tlp_out_fifo),toPut(tlp_in_fifo));

   interface MsgPort noc;

      interface MsgSource out;
         method Action dst_rdy(Bool b);
            if (b && (wr_data.bytes_available() >= fromInteger(bytes_per_beat)))
               wr_data.deq(fromInteger(bytes_per_beat));
         endmethod
         method src_rdy = (wr_data.bytes_available() >= fromInteger(bytes_per_beat));
         method beat = pack(take(map(validValue,wr_data.first())));
      endinterface

      interface MsgSink in;
         method dst_rdy = xmit_enabled && rd_data.can_enq() && msg_type_out.notFull() && segment_tag_out.notFull();
         method Action src_rdy(Bool b);
            if (b)
               incoming_beat.send();
         endmethod
         method Action beat(MsgBeat#(bpb,asz) v);
            current_beat <= v;
            if (incoming_beat)
               msg_parse.beat(v);
         endmethod
      endinterface

   endinterface

   method Bool rx_activity = read_in_progress;
   method Bool tx_activity = write_in_progress;

endmodule: mkPCIEtoBNoC

endpackage: PCIEtoBNoCBridge
