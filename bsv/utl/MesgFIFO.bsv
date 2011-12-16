// MesgFIFO.bsv - Message FIFO for data and metadata
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

/*
  A Message FIFO is a module that operates upon messages.
  A message is composed of data and metadata:
  Each message may have 0 to N words of data associated with it.
  Each message has exactly one metadata word assoacted with it.
  The metadata always contains a UInt specifying the length of its data message in words.
  The metadata may contain additional per-message user information .
  Both data and metadata arrive and depart in their own parallel, strictly FIFO sequence.
  There is no enforced relation between data and metadata arrival and departure.
  Data may arrive before metadata, or visa versa.

  The utility of this module is that it faciliates the allignment of data and metadata
  to suit the meassage protocol needs of each side of the MesgFIFO. For example, messages
  might arrive at the MesgFIFO with data first and metadata following. This is common in cases
  where the upstream side has to calculate a variable message length. But the downstream
  side may require knowing the message length from the metadata prior to eading out the data.
  The MesgFIFO eases this task of protocol adapation.

  Auxiliary methods amplify the fundamental MesgFIFO semantics by providing information that
  can reduce or remove the need for external circuity to do the same:

    + The dataPutAvail method exposes how much data space is available so that an upstream read
    requestor could ask for no more data than can be accepted by (and Put to) the MesgFIFO.

    + The metaPutAvail method exposes how much meta space is available so that an upstream read
    requestor could ask for no more metadata than can be accepted by (and Put to) the MesgFIFO.

    + The dataGetAvail method exposes how much data is available so that a downstream
    device can take (and Get from) the MesgFIFO parts of message.

    + The metaGetAvail method exposes how many metadata words (one per message) are
    available to take (and Get from) the MesgFIFO. 

    + The mesgReady method indicates if one or more complete message of data and metadata is ready.
    When mesgReady is True, the downstream consumer is sure there is a non-zero number of complete messages.
*/


package MesgFIFO;

import FIFO      :: *;
import FIFOLevel :: *;
import GetPut    :: *;
import Vector    :: *;

interface MesgFIFOIfc#( numeric type data_width,
                        numeric type meta_width,
                        numeric type data_buf_sz,
                        numeric type meta_buf_sz); 

  // Input-Consumer-Put side sub-interfaces and methods...
  interface Put#(Bit#(data_width)) putData;
  interface Put#(Bit#(meta_width)) putMeta;

  (* always_ready *) // The number of data words available to put
  method UInt#(TLog#(TAdd#(data_buf_sz,1))) dataPutAvail();
  (* always_ready *) // The number of meta words available to put
  method UInt#(TLog#(TAdd#(meta_buf_sz,1))) metaPutAvail();

  // Output-Producer-Get side sub-interfaces and methods...
  interface GetS#(Bit#(data_width)) getsData;
  interface GetS#(Bit#(meta_width)) getsMeta;

  (* always_ready *) // The number of data words available to get
  method UInt#(TLog#(TAdd#(data_buf_sz,1))) dataGetAvail();
  (* always_ready *) // The number of meta words available to get
  method UInt#(TLog#(TAdd#(meta_buf_sz,1))) metaGetAvail();
  (* always_ready *)
  method Bool mesgReady();

endinterface: MesgFIFOIfc

function GetS#(a) toGetS(FIFOCountIfc#(a,b) f);
  return
    (interface GetS;
       method a      first = f.first;
       method Action deq   = f.deq();
     endinterface);
endfunction

// This is one basic implementation based on using mkFIFOCount...

module mkMesgFIFO(MesgFIFOIfc#(data_width,meta_width,data_buf_sz,meta_buf_sz))
  provisos( Log#(TAdd#(data_buf_sz,1),data_bufcount)
          , Log#(TAdd#(meta_buf_sz,1),meta_bufcount)
          );

  FIFOCountIfc#(Bit#(data_width),data_buf_sz)  dataF     <-  mkFIFOCount;
  FIFOCountIfc#(Bit#(meta_width),meta_buf_sz)  metaF     <-  mkFIFOCount;
  Reg#(Bit#(meta_bufcount))                    mesgCnt   <-  mkReg(0);

  interface Put  putData  = toPut(dataF);
  interface Put  putMeta  = toPut(metaF);
  interface GetS getsData = toGetS(dataF);
  interface GetS getsMeta = toGetS(metaF);

  method UInt#(data_bufcount) dataPutAvail = fromInteger(valueOf(data_buf_sz)) - dataF.count;
  method UInt#(meta_bufcount) metaPutAvail = fromInteger(valueOf(meta_buf_sz)) - metaF.count;
  method UInt#(data_bufcount) dataGetAvail = dataF.count;
  method UInt#(meta_bufcount) metaGetAvail = metaF.count;
  method Bool mesgReady = (mesgCnt>0);

endmodule

endpackage: MesgFIFO
