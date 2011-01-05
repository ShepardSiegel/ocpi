// OCWipDefs.bsv - OpenCPI WIP 
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCWipDefs;

import Connectable::*;

// Specify the depth of Slave-Request buffer...
typedef 3 SRBsize; // 3 is the minimum required to support the latency of pipelined SThreadBusy

// OCP-IP Enums...
typedef enum {IDLE, WR, RD, RDEX, RDL, WRNP, WRC, BCST} OCP_CMD deriving (Bits, Eq);
typedef enum {NULL, DVA,     FAIL,   ERR}   OCP_RESP deriving (Bits, Eq);
typedef enum {OKAY, EXOKAY, SLVERR, DECERR} AXI_RESP deriving (Bits, Eq);
typedef enum {None, Precise, Imprecise} OCP_BURST deriving (Bits, Eq);

// Message Metadata (RDMA) Structures...
typedef struct {
  Bit#(32) length;  // Message Length in Bytes
  Bit#(32) opcode;  // Opcode in bits[7:0]
  Bit#(32) nowMS;   // Integer portion of Time
  Bit#(32) nowLS;   // Fractional portion of Time
} MesgMeta deriving (Bits, Eq);

typedef struct {
  Bit#(8)  tag;     // context-specifc tag
  Bit#(8)  opcode;  // 8b OpCode
  Bit#(16) length;  // (truncated) Message Length in Bytes
} MesgMetaDW deriving (Bits, Eq);

typedef struct {
  Bit#(8)  opcode;  // 8b OpCode
  Bit#(24) length;  // Message Length in Bytes
} MesgMetaFlag deriving (Bits, Eq);

// RPL Worker Opcodes...

typedef enum {Sample, Sync, Timestamp, Rsvd} SampOpcode deriving (Bits, Eq);
typedef struct {
  SampOpcode opcode;
  Bool       last;
  Bit#(4)    be;
  Bit#(32)   data;
} SampMesg deriving (Bits, Eq);

// Worker Data Interface Port Status Structure...
// Bits[7:4]==0 "Ready and Healthy" else something not good-to-go (or has previously failed)
// Bits[3:0] provide informative data about port state
// Sticky bits are cleared by local reset only
typedef struct {         //bit  -Description--
  Bool localReset;       // 7:  This port is reset
  Bool partnerReset;     // 6:  The connected partner port is reset
  Bool notOperatonal;    // 5:  This port is not Operational
  Bool observedError;    // 4:  An error has been observed since port became operational (sticky)
  Bool inProgress;       // 3:  A message is in progress at this port
  Bool sThreadBusy;      // 2:  Present value of SThreadBusy
  Bool sDataThreadBusy;  // 1:  Present value of SDataThreadBusy (datahandshakeonly)
  Bool observedTraffic;  // 0:  Traffic has moved across this port since it became operational (sticky)
} WipDataPortStatus deriving (Bits, Eq);

// Worker Data Interface Port Extended Status Structure...
// State is reset by local reset only...
typedef struct {          // -Description--
  Bit#(32) pMesgCount;    // rolling count of precise   messages completed  (counts on reqLast)
  Bit#(32) iMesgCount;    // rolling count of imprecise messages completed  (counts on reqLast)
  Bit#(32) tBusyCount;    // rolling count of ThreadBusy while linkReady    (indication of how much "backpressure")
} WipDataPortExtendedStatus deriving (Bits, Eq);

// ConnectableMSO is used across multiple profiles and protocols...
typeclass ConnectableMSO#(type a, type b, type c); // Master-Slave-Observer Connectable...
  module mkConnectionMSO#(a m, b s, c o) (Empty);
endtypeclass


//TODO: Move this convienience function somewhere more appropriate...
import GetPut::*;
import FIFOF::*;	
function Get#(a) fifofToGet (FIFOF#(a) f);
 return (interface Get method get();
   actionvalue
    f.deq(); return f.first();
   endactionvalue
  endmethod: get
 endinterface);
endfunction: fifofToGet

interface BoolEdgeIfc;
  method Bool changing;
  method Bool rising;
  method Bool falling;
endinterface

module mkBoolEdge#(Bool src) (BoolEdgeIfc);
  Reg#(Bool) srcD <- mkRegU;
  rule doAlways; srcD <= src; endrule
  method Bool changing =  src !=  srcD;
  method Bool rising   =  src && !srcD;
  method Bool falling  = !src &&  srcD;
endmodule

endpackage: OCWipDefs
