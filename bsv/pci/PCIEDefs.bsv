// PCIEDefs.bsv
// Copyright (c) 2009-2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIEDefs;

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////

import Clocks            ::*;
import Vector            ::*;
import Connectable       ::*;
import GetPut            ::*;
import Reserved          ::*;
import TieOff            ::*;
import DefaultValue      ::*;
import DReg              ::*;
import Gearbox           ::*;
import FIFO              ::*;
import FIFOF             ::*;
import FIFOLevel         ::*;

////////////////////////////////////////////////////////////////////////////////
/// Types
////////////////////////////////////////////////////////////////////////////////
typedef Bit#(30)         DWAddress;
typedef Bit#(62)         DWAddress64;
typedef Bit#(7)          Offset;
typedef Bit#(8)          BusNumber;
typedef Bit#(5)          DevNumber;
typedef Bit#(3)          FuncNumber;

typedef Bit#(10)         TLPLength;
typedef Bit#(4)          TLPFirstDWBE;
typedef Bit#(4)          TLPLastDWBE;
typedef Bit#(8)          TLPTag;
typedef Bit#(7)          TLPLowerAddr;
typedef Bit#(12)         TLPByteCount;
typedef Bit#(10)         TLPRegNum;

typedef struct {
   Bool                  sof;
   Bool                  eof;
   Bit#(7)               hit;
   Bit#(bytes)           be;
   Bit#(TMul#(bytes, 8)) data;
   } TLPData#(type bytes) deriving (Bits, Eq);

instance DefaultValue#(TLPData#(n));
   defaultValue =
   TLPData {
      sof:  False,
      eof:  False,
      hit:  0,
      be:   0,
      data: 0
      };
endinstance

// Altera Variant with empty and 8b Bar
typedef struct {
   Bool                  empty; // on eop/eof, asserts that only the lower 64b of data have data
   Bool                  sof;
   Bool                  eof;
   Bit#(8)               hit;
   Bit#(bytes)           be;
   Bit#(TMul#(bytes, 8)) data;
   } TLPDataA#(type bytes) deriving (Bits, Eq);

instance DefaultValue#(TLPDataA#(n));
   defaultValue =
   TLPDataA {
      empty:False,
      sof:  False,
      eof:  False,
      hit:  0,
      be:   0,
      data: 0
      };
endinstance


typedef enum {
   STRICT_ORDERING   = 0,
   RELAXED_ORDERING  = 1
   } TLPAttrRelaxedOrdering deriving (Bits, Eq);

typedef enum {
   SNOOPING_REQD     = 0,
   NO_SNOOPING_REQD  = 1
   } TLPAttrNoSnoop deriving (Bits, Eq);

typedef enum {
   NOT_POISONED      = 0,
   POISONED          = 1
   } TLPPoison deriving (Bits, Eq);

typedef enum {
   NO_DIGEST_PRESENT = 0,
   DIGEST_PRESENT    = 1
   } TLPDigest deriving (Bits, Eq);

typedef enum {
   TRAFFIC_CLASS_0 = 0,
   TRAFFIC_CLASS_1 = 1,
   TRAFFIC_CLASS_2 = 2,
   TRAFFIC_CLASS_3 = 3,
   TRAFFIC_CLASS_4 = 4,
   TRAFFIC_CLASS_5 = 5,
   TRAFFIC_CLASS_6 = 6,
   TRAFFIC_CLASS_7 = 7
   } TLPTrafficClass deriving (Bits, Eq);

typedef enum {
   MEMORY_READ_WRITE   = 0,
   MEMORY_READ_LOCKED  = 1,
   IO_REQUEST          = 2,
   UNKNOWN_TYPE_3      = 3,
   CONFIG_0_READ_WRITE = 4,
   CONFIG_1_READ_WRITE = 5,
   UNKNOWN_TYPE_6      = 6,
   UNKNOWN_TYPE_7      = 7,
   UNKNOWN_TYPE_8      = 8,
   UNKNOWN_TYPE_9      = 9,
   COMPLETION          = 10,
   COMPLETION_LOCKED   = 11,
   UNKNOWN_TYPE_12     = 12,
   UNKNOWN_TYPE_13     = 13,
   UNKNOWN_TYPE_14     = 14,
   UNKNOWN_TYPE_15     = 15,
   MSG_ROUTED_TO_ROOT  = 16,
   MSG_ROUTED_BY_ADDR  = 17,
   MSG_ROUTED_BY_ID    = 18,
   MSG_ROOT_BROADCAST  = 19,
   MSG_LOCAL           = 20,
   MSG_GATHER          = 21,
   UNKNOWN_TYPE_22     = 22,
   UNKNOWN_TYPE_23     = 23,
   UNKNOWN_TYPE_24     = 24,
   UNKNOWN_TYPE_25     = 25,
   UNKNOWN_TYPE_26     = 26,
   UNKNOWN_TYPE_27     = 27,
   UNKNOWN_TYPE_28     = 28,
   UNKNOWN_TYPE_29     = 29,
   UNKNOWN_TYPE_30     = 30,
   UNKNOWN_TYPE_31     = 31
   } TLPPacketType deriving (Bits, Eq);

typedef enum {
   MEM_READ_3DW_NO_DATA = 0,
   MEM_READ_4DW_NO_DATA = 1,
   MEM_WRITE_3DW_DATA   = 2,
   MEM_WRITE_4DW_DATA   = 3
   } TLPPacketFormat deriving (Bits, Eq);

typedef enum {
   SUCCESSFUL_COMPLETION   = 0,
   UNSUPPORTED_REQUEST     = 1,
   CONFIG_REQ_RETRY_STATUS = 2,
   UNKNOWN_STATUS_3        = 3,
   COMPLETER_ABORT         = 4,
   UNKNOWN_STATUS_5        = 5,
   UNKNOWN_STATUS_6        = 6,
   UNKNOWN_STATUS_7        = 7
   } TLPCompletionStatus deriving (Bits, Eq);

typedef enum {
   BYTE_COUNT_ORIGINAL     = 0,
   BYTE_COUNT_MODIFIED     = 1
   } TLPByteCountModified deriving (Bits, Eq);

typedef enum {
   ASSERT_INTA           = 0,
   ASSERT_INTB           = 1,
   ASSERT_INTC           = 2,
   ASSERT_INTD           = 3,
   DEASSERT_INTA         = 4,
   DEASSERT_INTB         = 5,
   DEASSERT_INTC         = 6,
   DEASSERT_INTD         = 7
   } MSIInterruptCode deriving (Bits, Eq);

typedef enum {
   UNKNOWN_CODE_0        = 0,
   UNKNOWN_CODE_1        = 1,
   UNKNOWN_CODE_2        = 2,
   UNKNOWN_CODE_3        = 3,
   PM_ACTIVE_STATE_NAK   = 4,
   UNKNOWN_CODE_5        = 5,
   UNKNOWN_CODE_6        = 6,
   UNKNOWN_CODE_7        = 7,
   PM_PME                = 8,
   PM_TURN_OFF           = 9,
   UNKNOWN_CODE_10       = 10,
   PME_TO_ACK            = 11,
   UNKNOWN_CODE_12       = 12,
   UNKNOWN_CODE_13       = 13,
   UNKNOWN_CODE_14       = 14,
   UNKNOWN_CODE_15       = 15
   } MSIPowerMgtCode deriving (Bits, Eq);

typedef enum {
   ERR_COR               = 0,
   ERR_NONFATAL          = 1,
   UNKNOWN_ERR_2         = 2,
   ERR_FATAL             = 3
   } MSIErrorCode deriving (Bits, Eq);

typedef enum {
   ATTN_INDICATOR_OFF    = 0,
   ATTN_INDICATOR_ON     = 1,
   UNKNOWN_CODE_2        = 2,
   ATTN_INDICATOR_BLINK  = 3,
   POWER_INDICATOR_OFF   = 4,
   POWER_INDICATOR_ON    = 5,
   UNKNOWN_CODE_6        = 6,
   POWER_INDICATOR_BLINK = 7,
   ATTN_BUTTON_PRESSED   = 8,
   UNKNOWN_CODE_9        = 9,
   UNKNOWN_CODE_10       = 10,
   UNKNOWN_CODE_11       = 11,
   UNKNOWN_CODE_12       = 12,
   UNKNOWN_CODE_13       = 13,
   UNKNOWN_CODE_14       = 14,
   UNKNOWN_CODE_15       = 15
   } MSIHotPlugCode deriving (Bits, Eq);

typedef union tagged {
   void                 Unlock;
   MSIPowerMgtCode      PowerManagement;
   MSIInterruptCode     Interrupt;
   MSIErrorCode         Error;
   MSIHotPlugCode       HotPlug;
   void                 SlotPower;
   void                 VendorType0; // the doc says this is two bits, but code=1 conflicts with vendor type 1.
   void                 VendorType1;
   } TLPMessageCode deriving (Eq);

instance Bits#(TLPMessageCode, 8);
   function Bit#(8) pack(TLPMessageCode x);
      let result = ?;
      case(x) matches
         tagged Unlock          .*   : result = 8'b0000_0000;
         tagged PowerManagement .code: result = { 4'b0001, pack(code) };
         tagged Interrupt       .code: result = { 5'b0010_0, pack(code) };
         tagged Error           .code: result = { 6'b0011_00, pack(code) };
         tagged HotPlug         .code: result = { 4'b0100, pack(code) };
         tagged SlotPower       .*   : result = 8'b0101_0000;
         tagged VendorType0     .code: result = 8'b0111_1110;
         tagged VendorType1     .code: result = 8'b0111_1111;
      endcase
      return result;
   endfunction
   function TLPMessageCode unpack(Bit#(8) x);
      let result = ?;
      case(x[7:4])
         4'b0000: result = tagged Unlock;
         4'b0001: result = tagged PowerManagement(unpack(x[3:0]));
         4'b0010: result = tagged Interrupt(unpack(x[2:0]));
         4'b0011: result = tagged Error(unpack(x[1:0]));
         4'b0100: result = tagged HotPlug(unpack(x[3:0]));
         4'b0101: result = tagged SlotPower;
         4'b0111: result = (x[0] == 1) ? tagged VendorType1 : tagged VendorType0;
      endcase
      return result;
   endfunction
endinstance

typedef struct {
   BusNumber  bus;
   DevNumber  dev;
   FuncNumber func;
   } PciId deriving (Eq, Bits);

instance DefaultValue#(PciId);
   defaultValue =
   PciId {
      bus:  0,
      dev:  0,
      func: 0
      };
endinstance

typedef enum {
   RECEIVE_BUFFER_AVAILABLE_SPACE = 0,
   RECEIVE_CREDITS_GRANTED        = 1,
   RECEIVE_CREDITS_CONSUMED       = 2,
   UNKNOWN_3                      = 3,
   TRANSMIT_USER_CREDITS_AVAIALBE = 4,
   TRANSMIT_CREDIT_LIMIT          = 5,
   TRANSMIT_CREDITS_CONSUMED      = 6,
   UNKNOWN_7                      = 7
   } FlowControlInfoSelect deriving (Bits, Eq);


// Implementatiopn-Specific Encodings...

typedef enum {
   DETECT_QUIET           = 0,
   DETECT_ACTIVE          = 1,
   POLLING_ACTIVE         = 2,
   POLLING_COMPLIANCE     = 3,
   POLLING_CONFIGURATION  = 4,
   POLLING_SPEED          = 5,
   CONFIG_LINKWIDTHSTART  = 6,
   CONFIG_LINKACCEPT      = 7,
   CONFIG_LANNUMACCEPT    = 8,
   CONFIG_LANNUMWAIT      = 9,
   CONFIG_COMPLETE        = 10,
   CONFIG_IDLE            = 11,
   RECOVERY_RCVLOCK       = 12,
   RECOVERY_RCVCONFIG     = 13,
   RECOVERY_IDLE          = 14,
   L0                     = 15,
   DISABLE                = 16,
   LOOPBACK_ENTRY         = 17,
   LOOPBACK_ACTIVE        = 18,
   LOOPBACK_EXIT          = 19,
   HOT_RESET              = 20,
   UNKNOWN_21             = 21,
   L1_ENTRY               = 22,
   L1_IDLE                = 23,
   L2_IDLE                = 24,
   L2_TRANSMIT_WAKE       = 25
   } LinkTrainingState deriving (Bits, Eq); // e.g. LTSSM state on dl_ltssm[4:0]


////////////////////////////////////////////////////////////////////////////////
/// Packet Types
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   ReservedZero#(1)        r1;
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;
   TLPLength               length;
   PciId                   reqid;
   TLPTag                  tag;
   TLPLastDWBE             lastbe;
   TLPFirstDWBE            firstbe;
   DWAddress               addr;
   ReservedZero#(2)        r7;
   Bit#(32)                data;
   } TLPMemoryIO3DWHeader deriving (Bits, Eq);

instance DefaultValue#(TLPMemoryIO3DWHeader);
   defaultValue =
   TLPMemoryIO3DWHeader {
      r1:      unpack(0),
      format:  MEM_WRITE_3DW_DATA,
      pkttype: MEMORY_READ_WRITE,
      r2:      unpack(0),
      tclass:  TRAFFIC_CLASS_0,
      r3:      unpack(0),
      digest:  NO_DIGEST_PRESENT,
      poison:  NOT_POISONED,
      relaxed: STRICT_ORDERING,
      nosnoop: NO_SNOOPING_REQD,
      r4:      unpack(0),
      length:  0,
      reqid:   defaultValue,
      tag:     0,
      lastbe:  0,
      firstbe: 0,
      addr:    0,
      r7:      unpack(0),
      data:    0
      };
endinstance

typedef struct {
   ReservedZero#(1)        r1;
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;
   TLPLength               length;
   PciId                   reqid;
   TLPTag                  tag;
   TLPLastDWBE             lastbe;
   TLPFirstDWBE            firstbe;
   DWAddress64             addr;
   ReservedZero#(2)        r7;
   } TLPMemory4DWHeader deriving (Bits, Eq);

instance DefaultValue#(TLPMemory4DWHeader);
   defaultValue =
   TLPMemory4DWHeader {
      r1:      unpack(0),
      format:  MEM_WRITE_4DW_DATA,
      pkttype: MEMORY_READ_WRITE,
      r2:      unpack(0),
      tclass:  TRAFFIC_CLASS_0,
      r3:      unpack(0),
      digest:  NO_DIGEST_PRESENT,
      poison:  NOT_POISONED,
      relaxed: STRICT_ORDERING,
      nosnoop: NO_SNOOPING_REQD,
      r4:      unpack(0),
      length:  0,
      reqid:   defaultValue,
      tag:     0,
      lastbe:  0,
      firstbe: 0,
      addr:    0,
      r7:      unpack(0)
      };
endinstance


typedef struct {
   ReservedZero#(1)        r1;
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;
   TLPLength               length;
   PciId                   cmplid;
   TLPCompletionStatus     cstatus;
   TLPByteCountModified    bcm;
   TLPByteCount            bytecount;
   PciId                   reqid;
   TLPTag                  tag;
   ReservedZero#(1)        r5;
   TLPLowerAddr            loweraddr;
   Bit#(32)                data;
   } TLPCompletionHeader deriving (Bits, Eq);

instance DefaultValue#(TLPCompletionHeader);
   defaultValue =
   TLPCompletionHeader {
      r1:        unpack(0),
      format:    MEM_WRITE_3DW_DATA,
      pkttype:   COMPLETION,
      r2:        unpack(0),
      tclass:    TRAFFIC_CLASS_0,
      r3:        unpack(0),
      digest:    NO_DIGEST_PRESENT,
      poison:    NOT_POISONED,
      relaxed:   STRICT_ORDERING,
      nosnoop:   NO_SNOOPING_REQD,
      r4:        unpack(0),
      length:    0,
      cmplid:    defaultValue,
      cstatus:   SUCCESSFUL_COMPLETION,
      bcm:       BYTE_COUNT_ORIGINAL,
      bytecount: 0,
      reqid:     defaultValue,
      tag:       0,
      r5:        unpack(0),
      loweraddr: 0,
      data:      0
      };
endinstance

typedef struct {
   ReservedZero#(1)        r1;
   TLPPacketFormat         format;
   TLPPacketType           pkttype;
   ReservedZero#(1)        r2;
   TLPTrafficClass         tclass;
   ReservedZero#(4)        r3;
   TLPDigest               digest;
   TLPPoison               poison;
   TLPAttrRelaxedOrdering  relaxed;
   TLPAttrNoSnoop          nosnoop;
   ReservedZero#(2)        r4;
   TLPLength               length;
   PciId                   reqid;
   TLPTag                  tag;
   TLPMessageCode          msgcode;
   DWAddress64             address;
   } TLPMSIHeader deriving (Bits, Eq);

instance DefaultValue#(TLPMSIHeader);
   defaultValue =
   TLPMSIHeader {
      r1:      unpack(0),
      format:  MEM_READ_4DW_NO_DATA,
      pkttype: MSG_ROUTED_TO_ROOT,
      r2:      unpack(0),
      tclass:  TRAFFIC_CLASS_0,
      r3:      unpack(0),
      digest:  NO_DIGEST_PRESENT,
      poison:  NOT_POISONED,
      relaxed: STRICT_ORDERING,
      nosnoop: SNOOPING_REQD,
      r4:      unpack(0),
      length:  0,
      reqid:   defaultValue,
      tag:     0,
      msgcode: tagged Unlock,
      address: 0
      };
endinstance

////////////////////////////////////////////////////////////////////////////////
/// Functions
////////////////////////////////////////////////////////////////////////////////
function PciId getReqID(BusNumber b, DevNumber d, FuncNumber f);
   return PciId { bus: b, dev: d, func: f };
endfunction

function TLPLowerAddr getLowerAddr(DWAddress addr, TLPFirstDWBE first);
   case(first)
      4'b1110: return { addr[4:0], 2'b01 };
      4'b1100: return { addr[4:0], 2'b10 };
      4'b1000: return { addr[4:0], 2'b11 };
      default: return { addr[4:0], 2'b00 };
   endcase
endfunction

// For read-request completions
function Bit#(12) computeByteCount(Bit#(10) length,
                                   Bit#(4) firstBE, Bit#(4) lastBE);
   function Bit#(2) missingBytes(Bit#(4) be);
      case (be)
         4'b1111: return 2'b00;
         4'b1110: return 2'b01;
         4'b1100: return 2'b10;
         default: return 2'b11;
      endcase
   endfunction

   return ( {length, 2'b00}
            - zeroExtend(missingBytes(firstBE))
            - ( length == 1 ? 0 : zeroExtend(missingBytes(lastBE)) ) );
endfunction

// Reverse-Position of DWORDs
function Bit#(nd) reverseDWORDS(Bit#(nd) a) provisos (Mul#(32,ndw,nd));
  Vector#(ndw, Bit#(32)) vWords = reverse(unpack(a)); return pack(vWords);
endfunction

// Reverse-Position of BYTESs
function Bit#(nd) reverseBYTES(Bit#(nd) a) provisos (Mul#(8,nby,nd));
  Vector#(nby, Bit#(8)) vBytes = reverse(unpack(a)); return pack(vBytes);
endfunction

// Decode PCIe 0=1024 over-zealous encoding (ref table 2-4 in pcie 2.0 spec)
function UInt#(11) decodeDWlength(Bit#(10) pcieDWlen);
  return(pcieDWlen==0?1024:unpack(extend(pcieDWlen)));
endfunction


////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
(* always_ready, always_enabled *)
interface PCIE_EXP#(numeric type lanes);
   method    Action      rxp(Bit#(lanes) i);
   method    Action      rxn(Bit#(lanes) i);
   method    Bit#(lanes) txp;
   method    Bit#(lanes) txn;
endinterface: PCIE_EXP

// Altera may not handle bit-vectors of differential signals...
(* always_ready, always_enabled *)
interface PCIE_EXP_ALT#(numeric type lanes);
   method    Action      rx(Bit#(lanes) i);
   method    Bit#(lanes) tx;
   //method    Action      prsnt(Bool i);
   //method    Bool        waken;
endinterface: PCIE_EXP_ALT

(* always_ready, always_enabled *)
interface PCIE_EXP_ALT4;
   method    Action  rx0(Bit#(1) i);
   method    Action  rx1(Bit#(1) i);
   method    Action  rx2(Bit#(1) i);
   method    Action  rx3(Bit#(1) i);
   method    Bit#(1) tx0;
   method    Bit#(1) tx1;
   method    Bit#(1) tx2;
   method    Bit#(1) tx3;
endinterface: PCIE_EXP_ALT4

(* always_ready, always_enabled *)
interface PCIE_CFG;
   method    Bit#(32)    dataout;
   method    Bit#(1)     rd_wr_done_n;
   method    Action      di(Bit#(32) i);
   method    Action      dwaddr(Bit#(10) i);
   method    Action      wr_en_n(Bit#(1) i);
   method    Action      rd_en_n(Bit#(1) i);
   method    Bit#(1)     to_turnoff_n;
   method    Action      byte_en_n(Bit#(4) i);
   method    Bit#(8)     bus_number;
   method    Bit#(5)     device_number;
   method    Bit#(3)     function_number;
   method    Bit#(16)    status;
   method    Bit#(16)    command;
   method    Bit#(16)    dstatus;
   method    Bit#(16)    dcommand;
   method    Bit#(16)    lstatus;
   method    Bit#(16)    lcommand;
   method    Action      pm_wake_n(Bit#(1) i);
   method    Bit#(3)     pcie_link_state_n;
   method    Action      trn_pending_n(Bit#(1) i);
   method    Action      dsn(Bit#(64) i);
endinterface: PCIE_CFG

(* always_ready, always_enabled *)
interface PCIE_INT;
   method    Action      interrupt_n(Bit#(1) i);
   method    Bit#(1)     interrupt_rdy_n;
   method    Bit#(3)     interrupt_mmenable;
   method    Bit#(1)     interrupt_msienable;
   method    Action      interrupt_di(Bit#(8) i);
   method    Bit#(8)     interrupt_do;
   method    Action      interrupt_assert_n(Bit#(1) i);
endinterface: PCIE_INT

(* always_ready, always_enabled *)
interface PCIE_ERR;
   method    Action      ecrc_n(Bit#(1) i);
   method    Action      ur_n(Bit#(1) i);
   method    Action      cpl_timeout_n(Bit#(1) i);
   method    Action      cpl_unexpect_n(Bit#(1) i);
   method    Action      cpl_abort_n(Bit#(1) i);
   method    Action      posted_n(Bit#(1) i);
   method    Action      cor_n(Bit#(1) i);
   method    Action      tlp_cpl_header(Bit#(48) i);
   method    Bit#(1)     cpl_rdy_n;
   method    Action      locked_n(Bit#(1) i);
endinterface: PCIE_ERR

(* always_ready, always_enabled *)
interface PCIE_TRN_RX;
   method    Bit#(1)     rsof_n;
   method    Bit#(1)     reof_n;
   method    Bit#(64)    rd;
   method    Bit#(8)     rrem_n;
   method    Bit#(1)     rerrfwd_n;
   method    Bit#(1)     rsrc_rdy_n;
   method    Action      rdst_rdy_n(Bit#(1) i);
   method    Bit#(1)     rsrc_dsc_n;
   method    Action      rnp_ok_n(Bit#(1) i);
   method    Action      rcpl_streaming_n(Bit#(1) i);
   method    Bit#(7)     rbar_hit_n;
   method    Bit#(8)     rfc_ph_av;
   method    Bit#(12)    rfc_pd_av;
   method    Bit#(8)     rfc_nph_av;
   method    Bit#(12)    rfc_npd_av;
endinterface: PCIE_TRN_RX

(* always_ready, always_enabled *)
interface PCIE_TRN;
   interface Clock       clk;
   interface Clock       clk2;
   interface Reset       reset_n;
   method    Bit#(1)     lnk_up_n;
endinterface: PCIE_TRN

(* always_ready, always_enabled *)
interface PCIE_TRN_TX;
   method    Action      tsof_n(Bit#(1) i);
   method    Action      teof_n(Bit#(1) i);
   method    Action      td(Bit#(64) i);
   method    Action      trem_n(Bit#(8) i);
   method    Action      tsrc_rdy_n(Bit#(1) i);
   method    Bit#(1)     tdst_rdy_n;
   method    Action      tsrc_dsc_n(Bit#(1) i);
   method    Bit#(1)     tdst_dsc_n;
   method    Bit#(4)     tbuf_av;
   method    Action      terrfwd_n(Bit#(1) i);
endinterface: PCIE_TRN_TX


(* always_ready, always_enabled *)
interface PCIE_TRN_V6;
   interface Clock            clk;
   interface Clock            clk2;
   interface Reset            reset_n;
   method    Bit#(1)          lnk_up_n;
   method    Bit#(8)          fc_ph;
   method    Bit#(12)         fc_pd;
   method    Bit#(8)          fc_nph;
   method    Bit#(12)         fc_npd;
   method    Bit#(8)          fc_cplh;
   method    Bit#(12)         fc_cpld;
   method    Action           fc_sel(FlowControlInfoSelect i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AST_S4;
   interface Clock            clk250;
   interface Clock            clk125;
   interface Reset            reset_n;
   method    Bit#(1)          lnk_up_n;
   method    Bit#(8)          fc_ph;
   method    Bit#(12)         fc_pd;
   method    Bit#(8)          fc_nph;
   method    Bit#(12)         fc_npd;
   method    Bit#(8)          fc_cplh;
   method    Bit#(12)         fc_cpld;
   method    Action           fc_sel(FlowControlInfoSelect i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_TRN_TX_V6;
   method    Action           tsof_n(Bit#(1) i);
   method    Action           teof_n(Bit#(1) i);
   method    Action           td(Bit#(64) i);
   method    Action           trem_n(Bit#(1) i);
   method    Action           tsrc_rdy_n(Bit#(1) i);
   method    Bit#(1)          tdst_rdy_n;
   method    Action           tsrc_dsc_n(Bit#(1) i);
   method    Bit#(6)          tbuf_av;
   method    Bit#(1)          terr_drop_n;
   method    Action           tstr_n(Bit#(1) i);
   method    Bit#(1)          tcfg_req_n;
   method    Action           tcfg_gnt_n(Bit#(1) i);
   method    Action           terrfwd_n(Bit#(1) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_TRN_RX_V6;
   method    Bit#(1)     rsof_n;
   method    Bit#(1)     reof_n;
   method    Bit#(64)    rd;
   method    Bit#(1)     rrem_n;
   method    Bit#(1)     rerrfwd_n;
   method    Bit#(1)     rsrc_rdy_n;
   method    Action      rdst_rdy_n(Bit#(1) i);
   method    Bit#(1)     rsrc_dsc_n;
   method    Action      rnp_ok_n(Bit#(1) i);
   method    Bit#(7)     rbar_hit_n;
endinterface

// AXI Interface definitions...

(* always_ready, always_enabled *)
interface PCIE_AXI250;
   interface Clock       clk;    // 250 MHz
   interface Clock       clk2;   // 125 MHz
   interface Reset       usr_rst_p;
   method    Bool        lnk_up;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI125;
   interface Clock       clk;    // 125 MHz
   interface Reset       usr_rst_p;
   method    Bool        lnk_up;
endinterface

(* always_ready, always_enabled *)
interface PCIE_PIPE;
  method  Action  pClk       (Bool i);
  method  Action  rxUserClk  (Bit#(4) i);
  method  Action  rxOutClkIn (Bool i);
  method  Action  dxClk      (Bool i);
  method  Action  userClk1   (Bool i);
  method  Action  userClk2   (Bool i);
  method  Action  oobClk     (Bool i);
  method  Action  mmcmLock   (Bool i);
  method  Bit#(4) txOutClk;
  method  Bit#(4) rxOutClkOut;
  method  Bool    pclkSel;
  method  Bool    gen3;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_TX;
   method    Bit#(6)     tbuf_av;
   method    Bool        terr_drop;
   method    Bool        tcfg_req;
   method    Bool        tready;
   method    Action      tdata   (Bit#(64) i);
   method    Action      tstrb   (Bit#(8) i);
   method    Action      tuser   (Bit#(4) i);
   method    Action      tlast   (Bool i);
   method    Action      tvalid  (Bool i);
   method    Action      cfg_gnt (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_RX;
   method    Bit#(64)    tdata;
   method    Bit#(8)     tstrb;
   method    Bool        tlast;
   method    Bool        tvalid;
   method    Bit#(22)    tuser;
   method    Action      tready (Bool i);
   method    Action      np_ok  (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_TX;
   method    Bit#(6)     tbuf_av;
   method    Bool        terr_drop;
   method    Bool        tcfg_req;
   method    Bool        tready;
   method    Action      tdata   (Bit#(128) i);
   method    Action      tkeep   (Bit#(16) i);
   method    Action      tuser   (Bit#(4) i);
   method    Action      tlast   (Bool i);
   method    Action      tvalid  (Bool i);
   method    Action      cfg_gnt (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_RX;
   method    Bit#(128)   tdata;
   method    Bit#(16)    tkeep;
   method    Bool        tlast;
   method    Bool        tvalid;
   method    Bit#(22)    tuser;
   method    Action      tready (Bool i);
   method    Action      np_ok  (Bool i);
   method    Action      np_req (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_FC;
   method    Bit#(12)    cpld;
   method    Bit#(8)     cplh;
   method    Bit#(12)    npd;
   method    Bit#(8)     nph;
   method    Bit#(12)    pd;
   method    Bit#(8)     ph;
   method    Action      sel(FlowControlInfoSelect i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_CFG;  // Configuration (CFG) Interface...
   method    Bit#(32)    dout;
   method    Bool        rd_wr_done;
   method    Action      di      (Bit#(32) i);
   method    Action      byte_en (Bit#(4)  i);
   method    Action      dwaddr  (Bit#(10) i);
   method    Action      wr_en   (Bool i);
   method    Action      rd_en   (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_CFG;  // Configuration (CFG) Interface...
   method    Bit#(32)    dout;
   method    Bool        rd_wr_done;
   method    Action      di          (Bit#(32) i);
   method    Action      byte_en     (Bit#(4)  i);
   method    Action      dwaddr      (Bit#(10) i);
   method    Action      wr_en       (Bool     i);
   method    Action      rd_en       (Bool     i);
   method    Action      wr_readonly (Bool     i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_ERR;  // Error Interface...
   method    Action      cor            (Bool i);
   method    Action      ur             (Bool i);
   method    Action      ecrc           (Bool i);
   method    Action      cpl_timeout    (Bool i);
   method    Action      cpl_abort      (Bool i);
   method    Action      cpl_unexpect   (Bool i);
   method    Action      posted         (Bool i);
   method    Action      locked         (Bool i);
   method    Action      tlp_cpl_header (Bit#(48) i);
   method    Bool        cpl_rdy;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_ERR;  // Error Interface...
   method    Action      ecrc           (Bool i);
   method    Action      ur             (Bool i);
   method    Action      cpl_timeout    (Bool i);
   method    Action      cpl_unexpect   (Bool i);
   method    Action      cpl_abort      (Bool i);
   method    Action      posted         (Bool i);
   method    Action      cor            (Bool i);
   method    Action      egress_blocked (Bool i);
   method    Action      internal_cor   (Bool i);
   method    Action      internal_uncor (Bool i);
   method    Action      malformed      (Bool i);
   method    Action      mc_blocked     (Bool i);
   method    Action      poisoned       (Bool i);
   method    Action      no_recovery    (Bool i);
   method    Action      tlp_cpl_header (Bit#(48)  i);
   method    Bool        cpl_rdy;
   method    Action      locked         (Bool i);
   method    Action      aer_headerlog  (Bit#(128) i);
   method    Bool        aer_headerlog_set;
   method    Action      acs            (Bool i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_INT;  // Interrupt Interface...
   method    Action      req            (Bool i);
   method    Bit#(1)     rdy;
   method    Action      iassert        (Bool i);
   method    Action      din            (Bit#(8) i);
   method    Bit#(8)     dout;
   method    Bit#(3)     mmenable;
   method    Bool        msienable;
   method    Bool        msixenable;
   method    Bool        msixfm;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_INT;  // Interrupt Interface...
   method    Action      req            (Bool i);
   method    Bit#(1)     rdy;
   method    Action      iassert        (Bool i);
   method    Action      din            (Bit#(8) i);
   method    Bit#(8)     dout;
   method    Bit#(3)     mmenable;
   method    Bool        msienable;
   method    Bool        msixenable;
   method    Bool        msixfm;
   method    Action      stat           (Bool i);
   method    Action      msgnum         (Bit#(5) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI_CFG2;  // Other CFG Signals...
   method    Action      turnoff_ok    (Bool i);
   method    Bool        to_turnoff;
   method    Action      trn_pending   (Bool i);
   method    Action      pm_wake       (Bool i);
   method    Bit#(8)     bus_number;
   method    Bit#(5)     device_number;
   method    Bit#(3)     function_number;
   method    Bit#(16)    status;
   method    Bit#(16)    command;
   method    Bit#(16)    dstatus;
   method    Bit#(16)    dcommand;
   method    Bit#(16)    lstatus;
   method    Bit#(16)    lcommand;
   method    Bit#(16)    dcommand2;
   method    Bit#(3)     pcie_link_state;
   method    Action      dsn           (Bit#(64) i);
   method    Bool        pmcsr_pme_en;
   method    Bool        pmcsr_pme_status;
   method    Bit#(2)     pmcsr_powerstate;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_CFG2;  // Other CFG Signals...
   method    Bit#(16)    status;
   method    Bit#(16)    command;
   method    Bit#(16)    dstatus;
   method    Bit#(16)    dcommand;
   method    Bit#(16)    lstatus;
   method    Bit#(16)    lcommand;
   method    Bit#(16)    dcommand2;
   method    Bit#(3)     pcie_link_state;
   method    Bool        pmcsr_pme_en;
   method    Bit#(2)     pmcsr_powerstate;
   method    Bool        pmcsr_pme_status;
   method    Bool        received_func_lvl_rst;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AXI7_CFG3;  // Other CFG Signals...
   method    Bool        to_turnoff;
   method    Action      turnoff_ok        (Bool i);
   method    Bit#(8)     bus_number;
   method    Bit#(5)     device_number;
   method    Bit#(3)     function_number;
   method    Action      pm_wake           (Bool i);
   method    Action      trn_pending       (Bool i);
   method    Action      pm_halt_aspm_l0s  (Bool i);
   method    Action      pm_halt_aspm_l1   (Bool i);
   method    Action      pm_force_state_en (Bool i);
   method    Action      pm_force_state    (Bit#(2) i);
   method    Action      dsn               (Bit#(64) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_PL_V6;
   method    Bit#(2)     initial_link_width;
   method    Bit#(2)     lane_reversal_mode;
   method    Bit#(1)     link_gen2_capable;
   method    Bit#(1)     link_partner_gen2_supported;
   method    Bit#(1)     link_upcfg_capable;
   method    Bit#(1)     sel_link_rate;
   method    Bit#(2)     sel_link_width;
   method    Bit#(6)     ltssm_state;
   method    Action      directed_link_auton(Bit#(1) i);
   method    Action      directed_link_change(Bit#(2) i);
   method    Action      directed_link_speed(Bit#(1) i);
   method    Action      directed_link_width(Bit#(2) i);
   method    Action      upstream_prefer_deemph(Bit#(1) i);
   method    Bit#(1)     received_hot_rst;
endinterface

(* always_ready, always_enabled *)
interface PCIE_CFG_V6;
   method    Bit#(32)    dout;
   method    Bit#(1)     rd_wr_done_n;
   method    Action      di(Bit#(32) i);
   method    Action      dwaddr(Bit#(10) i);
   method    Action      byte_en_n(Bit#(4) i);
   method    Action      wr_en_n(Bit#(1) i);
   method    Action      rd_en_n(Bit#(1) i);
   method    Bit#(8)     bus_number;
   method    Bit#(5)     device_number;
   method    Bit#(3)     function_number;
   method    Bit#(16)    status;
   method    Bit#(16)    command;
   method    Bit#(16)    dstatus;
   method    Bit#(16)    dcommand;
   method    Bit#(16)    dcommand2;
   method    Bit#(16)    lstatus;
   method    Bit#(16)    lcommand;
   method    Bit#(1)     to_turnoff_n;
   method    Action      turnoff_ok_n(Bit#(1) i);
   method    Action      pm_wake_n(Bit#(1) i);
   method    Bit#(3)     pcie_link_state_n;
   method    Action      trn_pending_n(Bit#(1) i);
   method    Action      dsn(Bit#(64) i);
   method    Bit#(1)     pmcsr_pme_en;
   method    Bit#(1)     pmcsr_pme_status;
   method    Bit#(2)     pmcsr_powerstate;
endinterface

(* always_ready, always_enabled *)
interface PCIE_INT_V6;
   method    Action      req_n(Bit#(1) i);
   method    Bit#(1)     rdy_n;
   method    Action      assert_n(Bit#(1) i);
   method    Action      di(Bit#(8) i);
   method    Bit#(8)     dout;
   method    Bit#(3)     mmenable;
   method    Bit#(1)     msienable;
   method    Bit#(1)     msixenable;
   method    Bit#(1)     msixfm;
endinterface

(* always_ready, always_enabled *)
interface PCIE_ERR_V6;
   method    Action      ecrc_n(Bit#(1) i);
   method    Action      ur_n(Bit#(1) i);
   method    Action      cpl_timeout_n(Bit#(1) i);
   method    Action      cpl_unexpect_n(Bit#(1) i);
   method    Action      cpl_abort_n(Bit#(1) i);
   method    Action      posted_n(Bit#(1) i);
   method    Action      cor_n(Bit#(1) i);
   method    Action      tlp_cpl_header(Bit#(48) i);
   method    Bit#(1)     cpl_rdy_n;
   method    Action      locked_n(Bit#(1) i);
endinterface

(* always_ready, always_enabled *)
interface PCIE_DRP;
   method    Action      clk     (Bool x);
   method    Action      en      (Bool x);
   method    Action      we      (Bool x);
   method    Action      addr    (Bit#(9)  x);
   method    Action      din     (Bit#(16) x);
   method    Bool        rdy; 
   method    Bit#(16)    dout; 
endinterface

// Altera-Specific PCIe Interfaces...

(* always_ready, always_enabled *)
interface PCIE_AVALONST;
   interface Clock       clk;
   interface Reset       usr_rst;
   method    Bool        alive;       // core is alive
   method    Bool        lnk_up;      // Link-Up L0 status
   method    Bit#(32)    debug;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AVALONST_RX;
   method    Action      mask (Bool i);
   method    Action      rdy  (Bool i);
   method    Bool        valid;
   method    Bit#(8)     bar;
   method    Bit#(16)    be;
   method    Bit#(128)   data;
   method    Bool        sop;
   method    Bool        eop;
   method    Bool        empty;
   method    Bool        err;
endinterface

(* always_ready, always_enabled *)
interface PCIE_AVALONST_TX;
   method    Action      data   (Bit#(128) i);
   method    Action      sop    (Bool i);
   method    Action      eop    (Bool i);
   method    Action      empty  (Bool i);
   method    Action      valid  (Bool i);
   method    Action      err    (Bool i);
   method    Bool        tready;
   method    Bit#(36)    credit;
   method    Bool        fEmpty;
endinterface

(* always_ready, always_enabled *)
interface PCIE_ALT_CFG;
   method    Bit#(4)     addr;
   method    Bit#(32)    data;
   method    Bool        dataWrite;
   method    Bit#(53)    status;
   method    Bool        statusWrite;
endinterface

// These Interface declarations aggregate the sub-interfaces used by each of the importBVI variants...
// These are the interfaces provided by the vMkXXX modules...

interface PCIE#(numeric type lanes);     // V5 TRN
   interface Clock            clkout;
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_CFG         cfg;
   interface PCIE_INT         cfg_irq;
   interface PCIE_ERR         cfg_err;
   interface PCIE_TRN_TX      trn_tx;
   interface PCIE_TRN_RX      trn_rx;
   interface PCIE_TRN         trn;
endinterface: PCIE

interface PCIE_V6#(numeric type lanes);  //  V6 TRN
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_TRN_TX_V6   trn_tx;
   interface PCIE_TRN_RX_V6   trn_rx;
   interface PCIE_TRN_V6      trn;
   interface PCIE_PL_V6       pl;
   interface PCIE_CFG_V6      cfg;
   interface PCIE_INT_V6      cfg_interrupt;
   interface PCIE_ERR_V6      cfg_err;
endinterface: PCIE_V6

interface PCIE_X6#(numeric type lanes);  // V6 AXI (X6)
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_AXI250      axi;
   interface PCIE_AXI_TX      axi_tx;
   interface PCIE_AXI_RX      axi_rx;
   interface PCIE_AXI_FC      axi_fc;
   interface PCIE_PL_V6       pl;
   interface PCIE_AXI_CFG     cfg;
   interface PCIE_AXI_CFG2    cfg2;
   interface PCIE_AXI_ERR     cfg_error;
   interface PCIE_AXI_INT     cfg_interrupt;
endinterface: PCIE_X6

interface PCIE_X7#(numeric type lanes);  // V7 AXI (X7)
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_PIPE        pipe;
   interface PCIE_AXI125      axi;
   interface PCIE_AXI7_TX     axi_tx;
   interface PCIE_AXI7_RX     axi_rx;
   interface PCIE_AXI_FC      axi_fc;
   interface PCIE_AXI7_CFG    cfg;
   interface PCIE_AXI7_ERR    cfg_error;
   interface PCIE_AXI7_CFG2   cfg2;
   interface PCIE_AXI7_CFG3   cfg3;
   interface PCIE_AXI7_INT    cfg_interrupt;
//   interface PCIE_DRP         drp;
   interface PCIE_PL_V6       pl;
endinterface: PCIE_X7

interface PCIE_vS4GX#(numeric type lanes);  // Altera Stratix4-GX low-level interface
   interface PCIE_EXP_ALT#(lanes) pcie;
   //interface PCIE_EXP_ALT pcie;
   interface PCIE_AVALONST        ava;
   interface PCIE_AVALONST_RX     ava_rx;
   interface PCIE_AVALONST_TX     ava_tx;
   interface PCIE_ALT_CFG         cfg;
   //interface PCIE_ALT_INT     cfg_interrupt;
endinterface: PCIE_vS4GX

interface PCIE_S4GX#(numeric type lanes);  // Altera Stratix4-GX mid-level interface
   interface PCIE_EXP_ALT#(lanes) pcie;
   //interface PCIE_EXP_ALT pcie;
   interface PCIE_AVALONST        ava;
   //interface PCIE_AVALONST_RX     ava_rx;
   //interface PCIE_AVALONST_TX     ava_tx;
   interface PCIE_TRN_XMIT16 trn_tx;
   interface PCIE_TRN_RECV16 trn_rx;
   method PciId                 device;
   //interface PCIE_ALT_CFG     cfg;
   //interface PCIE_ALT_INT     cfg_interrupt;
endinterface: PCIE_S4GX




typedef struct {
   Bool        fast_train_sim_only;
   } PCIEParams deriving (Bits, Eq);

instance DefaultValue#(PCIEParams);
   defaultValue =
   PCIEParams {
      fast_train_sim_only: False
      };
endinstance




//
// Factored out individual impl
// vMK Was Here
//



////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
interface PCIE_TRN_COMMON;
   interface Clock       clk;
   interface Clock       clk2;
   interface Reset       reset_n;
   method    Bool        link_up;
endinterface: PCIE_TRN_COMMON

interface PCIE_TRN_COMMON_V6;
   interface Clock       clk;
   interface Clock       clk2;
   interface Reset       reset_n;
   method    Bool        link_up;
endinterface

interface PCIE_AXI_COMMON;
   interface Clock       clk;
   interface Clock       clk2;
   interface Reset       reset_n;
   method    Bool        link_up;
endinterface

interface PCIE_TRN_XMIT;
   method    Action      xmit(Bool discontinue, TLPData#(8) data);
   method    Bool        discontinued;
   method    Bit#(4)     buffers_available;
endinterface: PCIE_TRN_XMIT

interface PCIE_TRN_XMIT16;
   method    Action      xmit(Bool discontinue, TLPData#(16) data);
endinterface: PCIE_TRN_XMIT16

interface PCIE_TRN_XMIT_V6;
   method    Action      xmit(Bool discontinue, TLPData#(8) data);
   method    Bool        dropped;
   method    Bit#(6)     buffers_available;
   method    Action      cut_through_mode(Bool i);
   method    Bool        configuration_completion_ready;
   method    Action      configuration_completion_grant(Bool i);
   method    Action      error_forward(Bool i);
endinterface

interface PCIE_TRN_RECV;
   method    ActionValue#(TLPData#(8)) recv();
   method    Bool        error_forward;
   method    Bool        source_discontinue;
   method    Action      non_posted_ready(Bool i);
   method    Action      completion_streaming(Bool i);
   method    Bit#(8)     posted_header_credits;
   method    Bit#(12)    posted_data_credits;
   method    Bit#(8)     non_posted_header_credits;
   method    Bit#(12)    non_posted_data_credits;
endinterface: PCIE_TRN_RECV

interface PCIE_TRN_RECV16;
   method    ActionValue#(TLPData#(16)) recv();
endinterface: PCIE_TRN_RECV16

interface PCIE_TRN_RECV_V6;
   method    ActionValue#(TLPData#(8)) recv();
   method    Bool        error_forward;
   method    Bool        source_discontinue;
   method    Action      non_posted_ready(Bool i);
endinterface

interface PCIExpress#(numeric type lanes);
   interface Clock            clkout;
   interface PCIE_EXP#(lanes) pcie;
   interface PCIE_TRN_COMMON  trn;
   interface PCIE_TRN_XMIT    trn_tx;
   interface PCIE_TRN_RECV    trn_rx;
   interface PCIE_CFG         cfg;
   interface PCIE_INT         cfg_irq;
   interface PCIE_ERR         cfg_err;
endinterface: PCIExpress

interface PCIExpressV6#(numeric type lanes);
   interface PCIE_EXP#(lanes)   pcie;
   interface PCIE_TRN_COMMON_V6 trn;
   interface PCIE_TRN_XMIT_V6   trn_tx;
   interface PCIE_TRN_RECV_V6   trn_rx;
   interface PCIE_CFG_V6        cfg;
   interface PCIE_INT_V6        cfg_interrupt;
   interface PCIE_ERR_V6        cfg_err;
   interface PCIE_PL_V6         pl;
endinterface: PCIExpressV6

interface PCIExpressX7#(numeric type lanes);
   interface PCIE_EXP#(lanes)   pcie;
   interface PCIE_TRN_COMMON_V6 trn;
   interface PCIE_TRN_XMIT16    trn_tx;
   interface PCIE_TRN_RECV16    trn_rx;
   interface PCIE_CFG_V6        cfg;
   interface PCIE_INT_V6        cfg_interrupt;
   interface PCIE_ERR_V6        cfg_err;
   interface PCIE_PL_V6         pl;
endinterface: PCIExpressX7

/* TODO: Modify to provide AXI, not TRN
interface PCIExpressX6#(numeric type lanes);
   interface PCIE_EXP#(lanes)   pcie;
   interface PCIE_AXI_COMMON    axi;
   interface PCIE_AXI_XMIT      axi_tx;
   interface PCIE_AXI_RECV      axi_rx;
   interface PCIE_AXI_FC        axi_fc;
   interface PCIE_AXI_CFG       cfg;
   interface PCIE_AXI_ERR       cerr;
   interface PCIE_AXI_INT       cint;
   interface PCIE_AXI_CFG2      cfg2;
   interface PCIE_PL_V6         pl;
endinterface: PCIExpressX6
*/

//
// Factored out individual impl
// mkX Was Here
//

// Not from PCIe spec but used for head communication...
typedef struct {
 Bit#(8)         hit;
 TLPLength       tlpLen; // encoded
 TLPPacketFormat pfmt;
 UInt#(11)       length; // actual packet length in DWORDS
} TLPHeadInfo deriving (Bits, Eq);


////////////////////////////////////////////////////////////////////////////////
/// Connection Instances
////////////////////////////////////////////////////////////////////////////////

// Basic TLPData#(8) connections to PCIE endpoint

instance Connectable#(Get#(TLPData#(8)), PCIE_TRN_XMIT);
   module mkConnection#(Get#(TLPData#(8)) g, PCIE_TRN_XMIT p)(Empty);
      rule connect;
         let data <- g.get;
         p.xmit(False, data);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT, Get#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_XMIT p, Get#(TLPData#(8)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(8)), PCIE_TRN_RECV);
   module mkConnection#(Put#(TLPData#(8)) p, PCIE_TRN_RECV r)(Empty);
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ready(True);
         r.completion_streaming(False);
      endrule
      rule connect;
         let data <- r.recv;
         p.put(data);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV, Put#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_RECV r, Put#(TLPData#(8)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance


instance Connectable#(Get#(TLPData#(8)), PCIE_TRN_XMIT_V6);
   module mkConnection#(Get#(TLPData#(8)) g, PCIE_TRN_XMIT_V6 p)(Empty);
      rule every;
         p.cut_through_mode(False);
         p.configuration_completion_grant(True);  // Core gets to choose
         p.error_forward(False);
      endrule
      rule connect;
         let data <- g.get;
         p.xmit(False, data);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT_V6, Get#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_XMIT_V6 p, Get#(TLPData#(8)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(8)), PCIE_TRN_RECV_V6);
   module mkConnection#(Put#(TLPData#(8)) p, PCIE_TRN_RECV_V6 r)(Empty);
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ready(True);
      endrule
      rule connect;
         let data <- r.recv;
         p.put(data);
      endrule
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV_V6, Put#(TLPData#(8)));
   module mkConnection#(PCIE_TRN_RECV_V6 r, Put#(TLPData#(8)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance


instance Connectable#(PCIE_TRN_RECV16, Put#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_RECV16 r, Put#(TLPData#(16)) p)(Empty);
      rule connect;
         let data <- r.recv;
         p.put(data);
      endrule
   endmodule
endinstance

instance Connectable#(Get#(TLPData#(16)), PCIE_TRN_XMIT16);
   module mkConnection#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT16 p)(Empty);
      rule connect;
         let data <- g.get;
         p.xmit(False, data);
      endrule
   endmodule
endinstance



// Conversions between TLPData#(8) and TLPData#(16)

instance Connectable#(Put#(TLPData#(16)), Get#(TLPData#(8)));
   module mkConnection#(Put#(TLPData#(16)) p, Get#(TLPData#(8)) g)(Empty);
      Reg#(Maybe#(TLPData#(8))) rg <- mkReg(Invalid);
      rule upconv_connect1 (rg matches tagged Invalid);
         let w1 <- g.get;
         if (!w1.eof)
            rg <= Valid(w1);
         else begin
            let wOut = TLPData {
                          sof  : w1.sof,
                          eof  : w1.eof,  // True
                          hit  : w1.hit,
                          be   : {w1.be, 0},
                          data : {w1.data, ?}
                       };
            p.put(wOut);
         end
      endrule
      rule upconv_connect2 (rg matches tagged Valid .w1);
         let w2 <- g.get;
         let wOut = TLPData {
                       sof  : w1.sof,
                       eof  : w2.eof,
                       hit  : w1.hit,
                       be   : {w1.be, w2.be},
                       data : {w1.data, w2.data}
                    };
         p.put(wOut);
         rg <= Invalid;
      endrule
   endmodule
endinstance

instance Connectable#(Get#(TLPData#(8)), Put#(TLPData#(16)));
   module mkConnection#(Get#(TLPData#(8)) g, Put#(TLPData#(16)) p)(Empty);
      mkConnection(p, g);
   endmodule
endinstance

instance Connectable#(Get#(TLPData#(16)), Put#(TLPData#(8)));
   module mkConnection#(Get#(TLPData#(16)) g, Put#(TLPData#(8)) p)(Empty);
      // We need this state because the Get interface does not allow us to
      // look at the data without also popping it from the queue.
      // If we need to save these bits, then consider using a different ifc.
      Reg#(Maybe#(TLPData#(8))) rg <- mkReg(Invalid);
      rule downconv_connect1 (rg matches tagged Invalid);
         let wIn <- g.get;
         // the 16-byte packet will fit in 8-bytes
         if (wIn.be[7:0] == 0) begin  // XXX "&& wIn.eof" ?
            TLPData#(8) w1 =
               TLPData {
                  sof  : wIn.sof,
                  eof  : wIn.eof, // True
                  hit  : wIn.hit,
                  be   : wIn.be[15:8],
                  data : wIn.data[127:64]
               };
            p.put(w1);
         end
         // we need to send two 8-byte packets
         else begin
            TLPData#(8) w1 =
               TLPData {
                  sof  : wIn.sof,
                  eof  : False,
                  hit  : wIn.hit,
                  be   : wIn.be[15:8],
                  data : wIn.data[127:64]
               };
            TLPData#(8) w2 =
               TLPData {
                  sof  : False,
                  eof  : wIn.eof,
                  hit  : wIn.hit,
                  be   : wIn.be[7:0],
                  data : wIn.data[63:0]
               };
            rg <= Valid(w2);
            p.put(w1);
         end
      endrule
      rule downconv_connect2 (rg matches tagged Valid .w2);
         rg <= Invalid;
         p.put(w2);
      endrule
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(8)), Get#(TLPData#(16)));
   module mkConnection#(Put#(TLPData#(8)) p, Get#(TLPData#(16)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

// Connections between TLPData#(16) and a PCIE endpoint.
// These are all using the same clock, so the TLPData#(16) accesses
// will not be back-to-back.

instance Connectable#(Get#(TLPData#(16)), PCIE_TRN_XMIT);
   module mkConnection#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT t)(Empty);
      FIFO#(TLPData#(8)) outFifo <- mkFIFO();

      rule connect;
         let data = outFifo.first; outFifo.deq;
         if (data.be != 0)
            t.xmit(False, data);
      endrule

      Put#(TLPData#(8)) p = fifoToPut(outFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT, Get#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_XMIT p, Get#(TLPData#(16)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(16)), PCIE_TRN_RECV);
   module mkConnection#(Put#(TLPData#(16)) p, PCIE_TRN_RECV r)(Empty);
      FIFO#(TLPData#(8)) inFifo <- mkFIFO();

      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ready(True);
         r.completion_streaming(False);
      endrule

      rule connect;
         let data <- r.recv;
         inFifo.enq(data);
      endrule

      Get#(TLPData#(8)) g = fifoToGet(inFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV, Put#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_RECV r, Put#(TLPData#(16)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance


instance Connectable#(Get#(TLPData#(16)), PCIE_TRN_XMIT_V6);
   module mkConnection#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT_V6 t)(Empty);
      FIFO#(TLPData#(8)) outFifo <- mkFIFO();

      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         t.cut_through_mode(False);
         t.configuration_completion_grant(True);  // True means core gets to choose
         t.error_forward(False);
      endrule

      rule connect;
         let data = outFifo.first; outFifo.deq;
         if (data.be != 0)
            t.xmit(False, data);
      endrule

      Put#(TLPData#(8)) p = fifoToPut(outFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_XMIT_V6, Get#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_XMIT_V6 p, Get#(TLPData#(16)) g)(Empty);
      mkConnection(g, p);
   endmodule
endinstance

instance Connectable#(Put#(TLPData#(16)), PCIE_TRN_RECV_V6);
   module mkConnection#(Put#(TLPData#(16)) p, PCIE_TRN_RECV_V6 r)(Empty);
      FIFO#(TLPData#(8)) inFifo <- mkFIFO();

      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         r.non_posted_ready(True);
      endrule

      rule connect;
         let data <- r.recv;
         inFifo.enq(data);
      endrule

      Get#(TLPData#(8)) g = fifoToGet(inFifo);
      mkConnection(g,p);
   endmodule
endinstance

instance Connectable#(PCIE_TRN_RECV_V6, Put#(TLPData#(16)));
   module mkConnection#(PCIE_TRN_RECV_V6 r, Put#(TLPData#(16)) p)(Empty);
      mkConnection(p, r);
   endmodule
endinstance



// Connections between TLPData#(16) and a PCIE endpoint, using a gearbox
// to match data rates between the endpoint and design clocks.

typeclass ConnectableWithClocks#(type a, type b);
   module mkConnectionWithClocks#(a x1, b x2, Clock fastClock, Reset fastReset, Clock slowClock, Reset slowReset)(Empty);
endtypeclass

instance ConnectableWithClocks#(Put#(TLPData#(16)), PCIE_TRN_RECV);
   module mkConnectionWithClocks#(Put#(TLPData#(16)) p, PCIE_TRN_RECV g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                        inFifo              <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(1, 2, TLPData#(8))               fifoRxData          <- mk1toNGearbox(fastClock, fastReset, slowClock, slowReset);

      Reg#(Bool)                                rOddBeat            <- mkRegA(False, clocked_by fastClock, reset_by fastReset);
      Reg#(Bool)                                rSendInvalid        <- mkDRegA(False, clocked_by fastClock, reset_by fastReset);
      Reg#(Bool)                                rHiEOF              <- mkRegU(clocked_by fastClock, reset_by fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         g.non_posted_ready(True);
         g.completion_streaming(False);
      endrule

      rule accept_data;
         let data <- g.recv;
         inFifo.enq(data);
      endrule

      rule process_incoming_packets(!rSendInvalid);
         let data = inFifo.first; inFifo.deq;
         rOddBeat     <= !rOddBeat;
         rSendInvalid <= !rOddBeat && data.eof;
         rHiEOF       <= data.eof;
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0] = data;
         fifoRxData.enq(v);
      endrule

      rule send_invalid_packets(rSendInvalid);
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0].eof = !rHiEOF;
         v[0].be  = 0;
         fifoRxData.enq(v);
         rOddBeat <= !rOddBeat;
      endrule

      rule send_data;
         function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
            return TLPData {
                            sof:   in[0].sof,
                            eof:   in[1].eof,
                            hit:   in[0].hit,
                            be:    { in[0].be,   in[1].be },
                            data:  { in[0].data, in[1].data }
                            };
         endfunction

         fifoRxData.deq;
         p.put(combine(fifoRxData.first));
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(PCIE_TRN_RECV, Put#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_RECV g, Put#(TLPData#(16)) p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);
      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance


instance ConnectableWithClocks#(PCIE_TRN_XMIT, Get#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_XMIT p, Get#(TLPData#(16)) g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                     outFifo             <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(2, 1, TLPData#(8))            fifoTxData          <- mkNto1Gearbox(slowClock, slowReset, fastClock, fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      rule get_data;
         function Vector#(2, TLPData#(8)) split(TLPData#(16) in);
            Vector#(2, TLPData#(8)) v = defaultValue;
            v[0].sof  = in.sof;
            v[0].eof  = (in.be[7:0] == 0) ? in.eof : False;
            v[0].hit  = in.hit;
            v[0].be   = in.be[15:8];
            v[0].data = in.data[127:64];
            v[1].sof  = False;
            v[1].eof  = in.eof;
            v[1].hit  = in.hit;
            v[1].be   = in.be[7:0];
            v[1].data = in.data[63:0];
            return v;
         endfunction

         let data <- g.get;
         fifoTxData.enq(split(data));
      endrule

      rule process_outgoing_packets;
         let data = fifoTxData.first; fifoTxData.deq;
         // filter out TLPs with 00 byte enable
         if (head(data).be != 0)
            outFifo.enq(head(data));
      endrule

      rule send_data;
         let data = outFifo.first; outFifo.deq;
         p.xmit(False, data);
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(Get#(TLPData#(16)), PCIE_TRN_XMIT);
   module mkConnectionWithClocks#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance

instance ConnectableWithClocks#(PCIE_TRN_XMIT_V6, Get#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_XMIT_V6 p, Get#(TLPData#(16)) g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                     outFifo             <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(2, 1, TLPData#(8))            fifoTxData          <- mkNto1Gearbox(slowClock, slowReset, fastClock, fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         p.cut_through_mode(False);
         p.configuration_completion_grant(True);  // Means the core gets to choose
         p.error_forward(False);
      endrule

      rule get_data;
         function Vector#(2, TLPData#(8)) split(TLPData#(16) in);
            Vector#(2, TLPData#(8)) v = defaultValue;
            v[0].sof  = in.sof;
            v[0].eof  = (in.be[7:0] == 0) ? in.eof : False;
            v[0].hit  = in.hit;
            v[0].be   = in.be[15:8];
            v[0].data = in.data[127:64];
            v[1].sof  = False;
            v[1].eof  = in.eof;
            v[1].hit  = in.hit;
            v[1].be   = in.be[7:0];
            v[1].data = in.data[63:0];
            return v;
         endfunction

         let data <- g.get;
         fifoTxData.enq(split(data));
      endrule

      rule process_outgoing_packets;
         let data = fifoTxData.first; fifoTxData.deq;
         // filter out TLPs with 00 byte enable
         if (head(data).be != 0)
            outFifo.enq(head(data));
      endrule

      rule send_data;
         let data = outFifo.first; outFifo.deq;
         p.xmit(False, data);
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(Get#(TLPData#(16)), PCIE_TRN_XMIT_V6);
   module mkConnectionWithClocks#(Get#(TLPData#(16)) g, PCIE_TRN_XMIT_V6 p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance

instance ConnectableWithClocks#(Put#(TLPData#(16)), PCIE_TRN_RECV_V6);
   module mkConnectionWithClocks#(Put#(TLPData#(16)) p, PCIE_TRN_RECV_V6 g,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);

      ////////////////////////////////////////////////////////////////////////////////
      /// Design Elements
      ////////////////////////////////////////////////////////////////////////////////
      FIFO#(TLPData#(8))                        inFifo              <- mkFIFO(clocked_by fastClock, reset_by fastReset);
      Gearbox#(1, 2, TLPData#(8))               fifoRxData          <- mk1toNGearbox(fastClock, fastReset, slowClock, slowReset);

      Reg#(Bool)                                rOddBeat            <- mkRegA(False, clocked_by fastClock, reset_by fastReset);
      Reg#(Bool)                                rSendInvalid        <- mkDRegA(False, clocked_by fastClock, reset_by fastReset);
      Reg#(Bool)                                rHiEOF              <- mkRegU(clocked_by fastClock, reset_by fastReset);

      ////////////////////////////////////////////////////////////////////////////////
      /// Rules
      ////////////////////////////////////////////////////////////////////////////////
      (* no_implicit_conditions, fire_when_enabled *)
      rule every;
         g.non_posted_ready(True);
      endrule

      rule accept_data;
         let data <- g.recv;
         inFifo.enq(data);
      endrule

      rule process_incoming_packets(!rSendInvalid);
         let data = inFifo.first; inFifo.deq;
         rOddBeat     <= !rOddBeat;
         rSendInvalid <= !rOddBeat && data.eof;
         rHiEOF       <= data.eof;
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0] = data;
         fifoRxData.enq(v);
      endrule

      rule send_invalid_packets(rSendInvalid);
         Vector#(1, TLPData#(8)) v = defaultValue;
         v[0].eof = !rHiEOF;
         v[0].be  = 0;
         fifoRxData.enq(v);
         rOddBeat <= !rOddBeat;
      endrule

      rule send_data;
         function TLPData#(16) combine(Vector#(2, TLPData#(8)) in);
            return TLPData {
                            sof:   in[0].sof,
                            eof:   in[1].eof,
                            hit:   in[0].hit,
                            be:    { in[0].be,   in[1].be },
                            data:  { in[0].data, in[1].data }
                            };
         endfunction

         fifoRxData.deq;
         p.put(combine(fifoRxData.first));
      endrule

   endmodule
endinstance

instance ConnectableWithClocks#(PCIE_TRN_RECV_V6, Put#(TLPData#(16)));
   module mkConnectionWithClocks#(PCIE_TRN_RECV_V6 g, Put#(TLPData#(16)) p,
                                  Clock fastClock, Reset fastReset,
                                  Clock slowClock, Reset slowReset)(Empty);
      mkConnectionWithClocks(p, g, fastClock, fastReset, slowClock, slowReset);
   endmodule
endinstance

// interface tie-offs

instance TieOff#(PCIE_CFG);
   module mkTieOff#(PCIE_CFG ifc)(Empty);
      rule tie_off_inputs;
         ifc.di('0);
         ifc.wr_en_n('1);
         ifc.rd_en_n('1);
         ifc.dwaddr('0);
         ifc.byte_en_n('1);
         ifc.pm_wake_n('1);
         ifc.trn_pending_n('1);
         ifc.dsn({ 32'h0000_0001, { { 8'h1}, 24'h000A35}});
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI_CFG);
   module mkTieOff#(PCIE_AXI_CFG ifc)(Empty);
      rule tie_off_inputs;
         ifc.di('0);
         ifc.byte_en('0);
         ifc.dwaddr('0);
         ifc.wr_en(False);
         ifc.rd_en(False);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI_CFG2);
   module mkTieOff#(PCIE_AXI_CFG2 ifc)(Empty);
      rule tie_off_inputs;
         ifc.turnoff_ok(False);
         ifc.trn_pending(False);
         ifc.pm_wake(False);
         ifc.dsn({ 32'h0000_0001, { { 8'h1}, 24'h000A35}});
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_ERR);
   module mkTieOff#(PCIE_ERR ifc)(Empty);
      rule tie_off_inputs;
         ifc.ecrc_n('1);
         ifc.ur_n('1);
         ifc.cpl_timeout_n('1);
         ifc.cpl_unexpect_n('1);
         ifc.cpl_abort_n('1);
         ifc.posted_n('1);
         ifc.cor_n('1);
         ifc.tlp_cpl_header('0);
         ifc.locked_n('1);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI_ERR);
   module mkTieOff#(PCIE_AXI_ERR ifc)(Empty);
      rule tie_off_inputs;
         ifc.cor(False);
         ifc.ur(False);
         ifc.ecrc(False);
         ifc.cpl_timeout(False);
         ifc.cpl_abort(False);
         ifc.cpl_unexpect(False);
         ifc.posted(False);
         ifc.locked(False);
         ifc.tlp_cpl_header('0); // TODO: Make meaningful default
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_INT);
   module mkTieOff#(PCIE_INT ifc)(Empty);
      rule tie_off_inputs;
         ifc.interrupt_n('1);
         ifc.interrupt_di('0);
         ifc.interrupt_assert_n('1);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_CFG_V6);
   module mkTieOff#(PCIE_CFG_V6 ifc)(Empty);
      rule tie_off_inputs;
         ifc.di('0);
         ifc.dwaddr('0);
         ifc.byte_en_n('1);
         ifc.wr_en_n('1);
         ifc.rd_en_n('1);
         ifc.turnoff_ok_n('1);
         ifc.pm_wake_n('1);
         ifc.trn_pending_n('1);
         ifc.dsn({ 32'h0000_0001, { { 8'h1}, 24'h000A35}});
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_INT_V6);
   module mkTieOff#(PCIE_INT_V6 ifc)(Empty);
      rule tie_off_inputs;
         ifc.req_n('1);
         ifc.assert_n('1);
         ifc.di('0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI_INT);
   module mkTieOff#(PCIE_AXI_INT ifc)(Empty);
      rule tie_off_inputs;
         ifc.req(False);
         ifc.iassert(False);
         ifc.din('0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_ERR_V6);
   module mkTieOff#(PCIE_ERR_V6 ifc)(Empty);
      rule tie_off_inputs;
         ifc.ecrc_n('1);
         ifc.ur_n('1);
         ifc.cpl_timeout_n('1);
         ifc.cpl_unexpect_n('1);
         ifc.cpl_abort_n('1);
         ifc.posted_n('1);
         ifc.cor_n('1);
         ifc.tlp_cpl_header('0);
         ifc.locked_n('1);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_PL_V6);
   module mkTieOff#(PCIE_PL_V6 ifc)(Empty);
      rule tie_off_inputs;
         ifc.directed_link_auton('0);
         ifc.directed_link_change('0);
         ifc.directed_link_speed('0);
         ifc.directed_link_width('0);
         ifc.upstream_prefer_deemph(1'b1);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI7_CFG);
   module mkTieOff#(PCIE_AXI7_CFG ifc)(Empty);
      rule tie_off_inputs;
         ifc.di          ('0);
         ifc.byte_en     ('0);
         ifc.dwaddr      ('0);
         ifc.wr_en       (False);
         ifc.rd_en       (False);
         ifc.wr_readonly (False);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI7_INT);
   module mkTieOff#(PCIE_AXI7_INT ifc)(Empty);
      rule tie_off_inputs;
         ifc.req     (False);
         ifc.iassert (False);
         ifc.din     ('0);
         ifc.stat    (False);
         ifc.msgnum  ('0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_DRP);
   module mkTieOff#(PCIE_DRP ifc)(Empty);
      rule tie_off_inputs;
         ifc.clk     (False);
         ifc.en      (False);
         ifc.we      (False);
         ifc.addr    ('0);
         ifc.din     ('0);
      endrule
   endmodule
endinstance

instance TieOff#(PCIE_AXI7_ERR);
   module mkTieOff#(PCIE_AXI7_ERR ifc)(Empty);
      rule tie_off_inputs;
         ifc.ecrc           (False);
         ifc.ur             (False);
         ifc.cpl_timeout    (False);
         ifc.cpl_unexpect   (False);
         ifc.cpl_abort      (False);
         ifc.posted         (False);
         ifc.cor            (False);
         ifc.egress_blocked (False);
         ifc.internal_cor   (False);
         ifc.internal_uncor (False);
         ifc.malformed      (False);
         ifc.mc_blocked     (False);
         ifc.poisoned       (False);
         ifc.no_recovery    (False);
         ifc.tlp_cpl_header ('0);
         ifc.locked         (False);
         ifc.aer_headerlog  ('0);
         ifc.acs            (False);
      endrule
   endmodule
endinstance

endpackage: PCIEDefs
