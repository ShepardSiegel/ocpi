import Connectable :: *;
import TieOff      :: *;
import Vector      :: *;
import StmtFSM     :: *;
import Clocks      :: *;

import MsgFormat    :: *;
import MsgXfer      :: *;
import RandomMsg    :: *;
import OnChipBuffer :: *;

// Set this to control the width of the NoC (values can be 1,2,4,8,16,...)

typedef `BEAT_SIZE_IN_BYTES BytesPerBeat;

// Set this to control the width of the memory

typedef `MEM_WIDTH_IN_BYTES MemWidth;

// This is a fixed value for this test

typedef 32 AddrSize;

// synthesizable message sink

(* synthesize *)
module mkSink#( NodeID this_node )
              ( MsgSink#(BytesPerBeat,AddrSize) );
   let _m <- mkSink_(this_node);
   return _m;
endmodule: mkSink

// Memory test module

(* synthesize *)
module mkTester#( NodeID this_node, NodeID mem_node )
                ( MsgSource#(BytesPerBeat,AddrSize) );

   FifoMsgSource#(BytesPerBeat,AddrSize) out_f <- mkFifoMsgSource();
   Reg#(UInt#(10)) beat_count <- mkReg(0);

   function Stmt wr(UInt#(AddrSize) addr, Bit#(n) x)
      provisos( Add#(8,_v1,n) // n >= 8
              , Div#(n,8,data_bytes)
              , Div#(AddrSize,8,addr_bytes)
              , Add#(4,addr_bytes,start_of_payload)
              , Add#(start_of_payload,data_bytes,msg_bytes)
              , Div#(msg_bytes,BytesPerBeat,msg_beats)
              , Mul#(msg_beats,BytesPerBeat,padded_msg_bytes)
              , Mul#(BytesPerBeat,8,beat_size)
              , Mul#(padded_msg_bytes,8,TMul#(msg_beats,beat_size))
              , Div#(TMul#(msg_beats,beat_size), beat_size, msg_beats)
              );

      Vector#(padded_msg_bytes,Bit#(8)) msg = replicate(unpack('0));

      SegmentTag stag = SegmentTag { end_of_message: True, length_in_bytes: fromInteger(valueOf(data_bytes)) };

      // header
      msg[0] = pack(mem_node);
      msg[1] = pack(this_node);
      msg[2] = {6'd0,pack(Write)};
      msg[3] = pack(stag);

      // address
      for (Integer i = 0; i < valueOf(addr_bytes); i = i + 1)
         msg[i+4] = truncate(pack(addr) >> (8*i));

      // payload
      for (Integer i = 0; i < valueOf(data_bytes); i = i + 1)
         msg[i+valueOf(start_of_payload)] = truncate(x >> (8*i));

      Vector#(msg_beats,MsgBeat#(BytesPerBeat,AddrSize)) beats = toChunks(msg);

      return seq
                 action
                    $display("Write %0d bytes starting at %0d = %x", valueOf(data_bytes), addr, x);
                    beat_count <= 0;
                 endaction
                 while (beat_count < fromInteger(valueOf(msg_beats))) action
                    out_f.enq(beats[beat_count]);
                    beat_count <= beat_count + 1;
                 endaction
             endseq;
   endfunction

   function Stmt rd(UInt#(AddrSize) addr, UInt#(14) count)
      provisos( Div#(AddrSize,8,addr_bytes)
              , Add#(4,addr_bytes,_tmp)
              , Add#(_tmp,addr_bytes,msg_bytes)
              , Div#(msg_bytes,BytesPerBeat,msg_beats)
              , Mul#(BytesPerBeat,8,beat_size)
              , Div#(TMul#(msg_beats,beat_size), beat_size, msg_beats)
              );

      Vector#(msg_bytes,Bit#(8)) msg = replicate(unpack('0));

      // header
      msg[0] = pack(mem_node);
      msg[1] = pack(this_node);
      msg[2] = {pack(count)[5:0],pack(Request)};
      msg[3] = pack(count)[13:6];

      // address at dst
      for (Integer i = 0; i < valueOf(addr_bytes); i = i + 1)
         msg[i+4] = truncate(pack(addr) >> (8*i));

      // address at src
      for (Integer i = 0; i < valueOf(addr_bytes); i = i + 1)
         msg[i+4+valueOf(addr_bytes)] = 0;

      Vector#(msg_beats,MsgBeat#(BytesPerBeat,AddrSize)) beats = toChunks(msg);

      return seq
                 action
                    beat_count <= 0;
                    $display("Read %0d bytes starting at %0d", count, addr);
                 endaction
                 while (beat_count < fromInteger(valueOf(msg_beats))) action
                    out_f.enq(beats[beat_count]);
                    beat_count <= beat_count + 1;
                 endaction
             endseq;
   endfunction

   function Stmt wr_seg(UInt#(AddrSize) addr, Bit#(1016) x0, Bit#(1016) x1, Bit#(n) x2)
      provisos( Add#(8,_v1,n) // n >= 8
              , Div#(n,8,data_bytes)
              , Div#(AddrSize,8,addr_bytes)
              , Add#(4,addr_bytes,start_of_payload)
              , Add#(start_of_payload,127,seg0_bytes)
              , Div#(seg0_bytes,BytesPerBeat,seg0_beats)
              , Mul#(seg0_beats,BytesPerBeat,padded_seg0_bytes)
              , Mul#(BytesPerBeat,8,beat_size)
              , Mul#(padded_seg0_bytes,8,TMul#(seg0_beats,beat_size))
              , Div#(TMul#(seg0_beats,beat_size), beat_size, seg0_beats)
              , Div#(128,BytesPerBeat,seg1_beats)
              , Mul#(seg1_beats,BytesPerBeat,padded_seg1_bytes)
              , Div#(TAdd#(data_bytes,1),BytesPerBeat,seg2_beats)
              , Mul#(seg2_beats,BytesPerBeat,padded_seg2_bytes)
              , Div#(TMul#(padded_seg2_bytes,8),beat_size,seg2_beats)
              );


      // Segment 0

      Vector#(padded_seg0_bytes,Bit#(8)) seg0 = replicate(unpack('0));

      SegmentTag stag0 = SegmentTag { end_of_message: False, length_in_bytes: 127 };

      // header
      seg0[0] = pack(mem_node);
      seg0[1] = pack(this_node);
      seg0[2] = {6'd0,pack(Write)};
      seg0[3] = pack(stag0);

      // address
      for (Integer i = 0; i < valueOf(addr_bytes); i = i + 1)
         seg0[i+4] = truncate(pack(addr) >> (8*i));

      // payload
      for (Integer i = 0; i < 127; i = i + 1)
         seg0[i+valueOf(start_of_payload)] = truncate(x0 >> (8*i));

      Vector#(seg0_beats,MsgBeat#(BytesPerBeat,AddrSize)) beats0 = toChunks(seg0);

      // Segment 1

      Vector#(padded_seg1_bytes,Bit#(8)) seg1 = replicate(unpack('0));

      SegmentTag stag1 = SegmentTag { end_of_message: False, length_in_bytes: 127 };
      seg1[0] = pack(stag1);

      for (Integer i = 0; i < 127; i = i + 1)
         seg1[i+1] = truncate(x1 >> (8*i));

      Vector#(seg1_beats,MsgBeat#(BytesPerBeat,AddrSize)) beats1 = toChunks(seg1);

      // Segment 1

      Vector#(padded_seg2_bytes,Bit#(8)) seg2 = replicate(unpack('0));

      SegmentTag stag2 = SegmentTag { end_of_message: True, length_in_bytes: fromInteger(valueOf(data_bytes)) };
      seg2[0] = pack(stag2);

      for (Integer i = 0; i < valueOf(data_bytes); i = i + 1)
         seg2[i+1] = truncate(x2 >> (8*i));

      Vector#(seg2_beats,MsgBeat#(BytesPerBeat,AddrSize)) beats2 = toChunks(seg2);

      // Combine

      let beats = append(beats0,append(beats1,beats2));

      return seq
                 action
                    $display("Write %0d bytes starting at %0d = %x %x %x", (2*127) + valueOf(data_bytes), addr, x0, x1, x2);
                    beat_count <= 0;
                 endaction
                 while (beat_count < fromInteger(valueOf(seg0_beats) + valueOf(seg1_beats) + valueOf(seg2_beats))) action
                    out_f.enq(beats[beat_count]);
                    beat_count <= beat_count + 1;
                 endaction
             endseq;
   endfunction


   Vector#(256,Bit#(8)) pattern = genWith(fromInteger);
   Vector#(127,Bit#(8)) pattern0 = take(pattern);
   Vector#(129,Bit#(8)) remainder = drop(pattern);
   Vector#(127,Bit#(8)) pattern1 = take(remainder);
   Vector#(2,Bit#(8))   pattern2 = drop(remainder);

   Stmt test_seq = seq
                       delay(10);
                       wr(120,32'h03020100);
                       rd(120,1);
                       rd(122,2);
                       wr(124,8'h04);
                       wr(125,40'h0908070605);
                       rd(121,4);
                       rd(120,10);
                       delay(10);
                       wr_seg(128,pack(pattern0),pack(pattern1),pack(pattern2));
                       rd(128,256);
                       delay(1000);
                   endseq;
   mkAutoFSM(test_seq);

   return out_f.source();

endmodule

// Top-level test module

(* synthesize *)
module mkMemTest();

   // tester node
   MsgSource#(BytesPerBeat,AddrSize) test_src <- mkTester(unpack(0),unpack(1));
   MsgSink#(BytesPerBeat,AddrSize)   test_snk <- mkSink(unpack(0));

   // memory node
   Clock noc_clk  <- exposeCurrentClock();
   Reset noc_rstn <- exposeCurrentReset();
   OnChipBuffer#(UInt#(10),Vector#(MemWidth,Bit#(8)),BytesPerBeat,AddrSize) ocb <- mkOnChipBuffer(noc_clk, noc_rstn, noc_clk, noc_rstn);

   // connect the tester to the memory
   mkConnection(as_port(test_src,test_snk),ocb.noc);

endmodule: mkMemTest
