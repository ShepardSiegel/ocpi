package MsgFormat;

/* This is a message format suitable for data exchange in an FPGA or
 * board-level network.  The goal is to be simple, efficient and support
 * a range of address and data beat sizes.
 *
 * This format attempts to abstract away from the peculiarities and
 * restrictions of any particular bus or network protocol and to avoid
 * dictating a particular choice of network topology or switch type.
 */

/* The network consists of a collection of up to 256 nodes, each
 * given a unique 8-bit identifier.  The structure of the identifier
 * is unspecified to allow flexibility in the choice of network
 * structure.
 */

typedef Bit#(8) NodeID;

/* Each node in the network is given its own flat address space.
 * The choice of 32-bit or 64-bit addressing should be made on a
 * network-wide basis.
 *
 * All of the addresses are byte-level addresses.
 *
 * Transfers on the network occur with byte granularity.
 * There are no restrictions on transfer start and end addresses.
 */

typedef UInt#(32) Addr32;
typedef UInt#(64) Addr64;

/*
 * There are 3 principal operations:
 *
 * 1. Send a datagram
 *
 * This involves sending bytes from a source node to a
 * destination node.  This is a data transfer independent of
 * the destination node's address space, intended for
 * interrupts, event signaling, control operations, etc.
 *
 * 2. Transfer data
 *
 * This involves sending bytes from a source node to a
 * destination node to be written consecutively starting at a
 * particular address in the destination node's address space.
 *
 * 3. Request data
 *
 * This involves sending a request to a destination node that it
 * transfer data back to the requester.  It is equivalent to a
 * traditional read request, except that it includes information on
 * the target buffer where the read data will be stored, so that a
 * normal data transfer request (see above) can be used instead of
 * a special read completion.
 */

typedef enum {
   Datagram = 0,
   Write    = 1,
   Request  = 2,
   WriteIR  = 3   // write in response to a request
} MsgType deriving (Eq,Bits);

function Bool is_write_msg(MsgType mt);
   return (mt == Write) || (mt == WriteIR);
endfunction: is_write_msg

/* Every message begins with a 4 byte header, followed by 0,1 or 2
 * addresses (which can each be 4 or 8 bytes depending on the chosen
 * address size), followed by 0 or more payload segments.
 * Little-endian byte ordering is used.
 *
 * Each payload segment consists of an 8-bit segment tag:
 *
 *   +-+-------+
 *   |E|  LEN  |   E   = End of Message flag
 *   +-+-------+   LEN = Bytes in segment (0 .. 127)
 *
 * Followed by 0 to 127 payload data bytes.
 *
 * Payload segments which do not completely fill a beat are
 * padded until the end of their final beat. The last payload
 * segment in a message is uniquely identified by setting the
 * end-of-message flag in its tag.
 *
 * The header format always includes the destination NodeID in the
 * the first byte, the source NodeID in the second byte and the
 * MsgType as the low 2 bits of the third byte. The remainder of
 * the header comes in two variations depending on the MsgType.
 *
 * For a Request message, the header format is:
 *
 *     Byte 3 |  Byte 2 | Byte 1 | Byte 0
 *   +--------+------+--+--------+--------+
 *   |  DATA_LENGTH  |MT|  SRC   |   DST  |
 *   +---------------+--+--------+--------+
 *    31           18    15     8 7      0
 *
 * For a Datagram, Write and WriteIR messages, the header format is:
 *
 *     Byte 3 |  Byte 2 | Byte 1 | Byte 0
 *   +--------+------+--+--------+--------+
 *   |   IST  | META |MT|  SRC   |   DST  |
 *   +--------+------+--+--------+--------+
 *    31    24 23  18    15     8 7      0
 *
 * where the IST field contains the initial segment tag
 * and the META field contains 6 bits of user-supplied metadata.
 *
 *
 * For a Datagram message with a single payload segment, the full
 * message looks like:
 *
 *      Byte 3 |  Byte 2 | Byte 1 | Byte 0
 *   +-+-------+------+--+--------+--------+
 *   |1|   N   | META |00|  SRC   |   DST  |
 *   +-+-------+------+--+--------+--------+
 *   |  DATA 3 | DATA 2  | DATA 1 | DATA 0 |
 *   +---------+---------+--------+--------+
 *   |                  ...                |
 *   +----------------------------+--------+
 *   |          PADDING*          |DATA N-1|
 *   +----------------------------+--------+
 *
 *
 * A Write with 2 payload segments using 32-bit addresses might
 * look like:
 *
 *      Byte 3 |  Byte 2 | Byte 1 | Byte 0
 *   +-+-------+------+--+--------+---------+
 *   |0|   N   | META |01|  SRC   |   DST   |   <-- initial segment
 *   +-+-------+------+--+--------+---------+       tag is in header
 *   |              DST ADDRESS             |
 *   +---------+---------+--------+---------+
 *   |  DATA 3 | DATA 2  | DATA 1 | DATA 0  |   <-- initial segment
 *   +---------+---------+--------+---------+       payload bytes
 *   |                  ...                 |       begin here
 *   +-------------------+--------+---------+
 *   |      PADDING*     |DATA N-1|DATA N-2 |
 *   +-------------------+--------+-+-------+
 *   | DATA N+2| DATA N+1| DATA N |1|   M   |   <-- second segment tag
 *   +---------+---------+--------+-+-------+       follows previous
 *   |                  ...                 |       segment, with payload
 *   +---------+---------+--------+---------+       bytes immediately
 *   | PADDING*|DT N+M-1 |DT N+M-2|DT N+M-3 |       after the tag
 *   +---------+---------+--------+---------+
 *
 *
 * A Request using 64-bit addresses might look like:
 *
 *     Byte 3 |  Byte 2 | Byte 1 | Byte 0
 *   +--------+------+--+--------+--------+
 *   |  DATA_LENGTH  |10|  SRC   |   DST  |
 *   +---------------+--+--------+--------+
 *   |          DST ADDRESS (LSBs)        |
 *   +------------------------------------+
 *   |          DST ADDRESS (MSBs)        |
 *   +------------------------------------+
 *   |          SRC ADDRESS (LSBs)        |
 *   +------------------------------------+
 *   |          SRC ADDRESS (MSBs)        |
 *   +------------------------------------+
 *   |              PADDING*              |
 *   +------------------------------------+
 *
 *
 *  * = padding bytes as needed to fill beat
 *
 * In the above diagams, DST ADDRESS refers to an address in
 * the address space of the DST node and SRC ADDRESS refers to
 * an address in the address space of the SRC node.
 *
 * Therefore, a Request message provides a DST ADDRESS that
 * specifies the location of the data to read within the DST
 * node's address space and a SRC ADDRESS that specifies the
 * location to copy that data to within the SRC node's address
 * space.  The DST node would respond with a WriteIR message
 * using the Request's SRC ADDRESS as the Write's DST ADDRESS,
 * since the role of SRC and DST is reversed in the response.
 */

typedef struct {
   Bool     end_of_message;
   UInt#(7) length_in_bytes;
} SegmentTag deriving (Bits);

/* Messages are assumed to be transmitted between network nodes as
 * a series of beats.  Beats can be 2^n bytes wide for n=0,1,2,...
 * and are assumed to be transmitted back-to-back on the inter-node
 * channel.  The channel is allowed to stall, but it should not
 * intermix beats from different messages.
 *
 * For channels with multi-byte beats the bytes of the message fill
 * the beat from least-significant to most-significant byte.
 *
 * Messages always begin on the least-significant byte of a beat
 * and if the message does not completely fill the last beat, the
 * upper bytes of the last beat will be padded with zeros.
 *
 * This ensures that the very first byte in any message contains
 * the destination NodeID so that the routing of the message can
 * be fully determined by the first beat even for a channel only
 * one byte wide.
 *
 * The MsgBeat type is parameterized by the number of bytes per
 * beat, but also be the address size used with messages. Inclusion
 * of the address size in the MsgBeat type allows the compiler to
 * check that both participants in a message exchange are using
 * the same format.
 */

typedef Bit#(TMul#(8,bytes_per_beat)) MsgBeat#(numeric type bytes_per_beat, numeric type addr_size);

// Compute the length of a message header in bytes
function UInt#(5) header_bytes( MsgType mt
                              , Integer addr_size
                              );

   UInt#(4) bytes_per_addr = fromInteger(addr_size/8);

   case (mt)
      Datagram: return 4;
      Write   : return (4 + extend(bytes_per_addr));
      Request : return (4 + 2 * extend(bytes_per_addr));
      WriteIR : return (4 + extend(bytes_per_addr));
   endcase

endfunction: header_bytes

// Compute the number of beats required to hold a given number of bytes
function UInt#(n) num_beats(Integer bytes_per_beat, UInt#(n) num_bytes);

   UInt#(n) whole_beats = num_bytes / fromInteger(bytes_per_beat);

   if ((num_bytes % fromInteger(bytes_per_beat)) != 0)
      return (whole_beats + 1);
   else
      return whole_beats;

endfunction: num_beats

// This is a little utility to check that the bytes_per_beat and address_size
// values are legal.

module check_msg_type_params#(String prefix, Integer bytes_per_beat, Integer address_size)();
   if (address_size != 32 && address_size != 64)
      errorM(prefix + ": Invalid address size (" + integerToString(address_size) + ") should be 32 or 64");
   if (bytes_per_beat < 1)
      errorM(prefix + ": Invalid beat size (" + integerToString(bytes_per_beat) + ") should be > 1");
   Bool is_power_of_two = False;
   Integer n = bytes_per_beat;
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
      errorM(prefix + ": Invalid beat size (" + integerToString(bytes_per_beat) + ") should be a power of 2");
endmodule

endpackage: MsgFormat
