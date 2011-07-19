// PCIE.bsv
// Copyright (c) 2009  Bluespec, Inc.   ALL RIGHTS RESERVED.
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package PCIE;

// Notes :
// + The Xilinx cores have an additional, manually written wrapper layer for legacy reasons when MMCMs were needed
// + The Altera cores are import-BVI'd directly

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import DwordShifter      ::*;


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
interface PCIE_AXI;
   interface Clock       clk;
   interface Clock       drp;
   interface Reset       usr_rst_p;
   method    Bool        lnk_up;
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
   method    Action      byte_en (Bit#(4) i);
   method    Action      dwaddr  (Bit#(10) i);
   method    Action      wr_en   (Bool i);
   method    Action      rd_en   (Bool i);
endinterface

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
   interface PCIE_AXI         axi;
   interface PCIE_AXI_TX      axi_tx;
   interface PCIE_AXI_RX      axi_rx;
   interface PCIE_AXI_FC      axi_fc;
   interface PCIE_PL_V6       pl;
   interface PCIE_AXI_CFG     cfg;
   interface PCIE_AXI_CFG2    cfg2;
   interface PCIE_AXI_ERR     cfg_error;
   interface PCIE_AXI_INT     cfg_interrupt;
endinterface: PCIE_X6

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


////////////////////////////////////////////////////////////////////////////////
/// Definitions
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   Bool        fast_train_sim_only;
   } PCIEParams deriving (Bits, Eq);

instance DefaultValue#(PCIEParams);
   defaultValue =
   PCIEParams {
      fast_train_sim_only: False
      };
endinstance

// V5 TRN...
import "BVI" xilinx_v5_pcie_wrapper =
module vMkVirtex5PCIExpressWithDCM#(PCIEParams params)(PCIE#(lanes))
   provisos(Add#(1, z, lanes));

   default_clock clk(sys_clk);
   default_reset rstn(sys_reset_n);

   port fast_train_simulation_only = params.fast_train_sim_only;

   output_clock  clkout(refclkout);

   interface PCIE_EXP pcie;
      method                  rxp(pci_exp_rxp) enable((*inhigh*)en0) reset_by(no_reset);
      method                  rxn(pci_exp_rxn) enable((*inhigh*)en1) reset_by(no_reset);
      method pci_exp_txp      txp                                    reset_by(no_reset);
      method pci_exp_txn      txn                                    reset_by(no_reset);
   endinterface: pcie

   interface PCIE_CFG cfg;
      method cfg_do                     dataout                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_rd_wr_done_n           rd_wr_done_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_di)                                   enable((*inhigh*)en2)  clocked_by(trn_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                           enable((*inhigh*)en3)  clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_en_n(cfg_wr_en_n)                         enable((*inhigh*)en4)  clocked_by(trn_clk) reset_by(no_reset);
      method                            rd_en_n(cfg_rd_en_n)                         enable((*inhigh*)en5)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_to_turnoff_n           to_turnoff_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            byte_en_n(cfg_byte_en_n)                     enable((*inhigh*)en9)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                          clocked_by(no_clock) reset_by(no_reset);
      method cfg_device_number          device_number                                                       clocked_by(no_clock) reset_by(no_reset);
      method cfg_function_number        function_number                                                     clocked_by(no_clock) reset_by(no_reset);
      method cfg_status                 status                                                              clocked_by(trn_clk) reset_by(no_reset);
      method cfg_command                command                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                            clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                            clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_wake_n(cfg_pm_wake_n)                     enable((*inhigh*)en10) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pcie_link_state_n      pcie_link_state_n                                                   clocked_by(trn_clk) reset_by(no_reset);
      method                            trn_pending_n(cfg_trn_pending_n)             enable((*inhigh*)en11) clocked_by(trn_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                 enable((*inhigh*)en12) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg

   interface PCIE_INT cfg_irq;
      method                            interrupt_n(cfg_interrupt_n)                 enable((*inhigh*)en6)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_rdy_n        interrupt_rdy_n                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     interrupt_mmenable                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    interrupt_msienable                                                 clocked_by(trn_clk) reset_by(no_reset);
      method                            interrupt_di(cfg_interrupt_di)               enable((*inhigh*)en7)  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_do           interrupt_do                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            interrupt_assert_n(cfg_interrupt_assert_n)   enable((*inhigh*)en8)  clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg_irq

   interface PCIE_ERR cfg_err;
      method                            ecrc_n(cfg_err_ecrc_n)                       enable((*inhigh*)en13) clocked_by(trn_clk) reset_by(no_reset);
      method                            ur_n(cfg_err_ur_n)                           enable((*inhigh*)en14) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_timeout_n(cfg_err_cpl_timeout_n)         enable((*inhigh*)en15) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_unexpect_n(cfg_err_cpl_unexpect_n)       enable((*inhigh*)en16) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_abort_n(cfg_err_cpl_abort_n)             enable((*inhigh*)en17) clocked_by(trn_clk) reset_by(no_reset);
      method                            posted_n(cfg_err_posted_n)                   enable((*inhigh*)en18) clocked_by(trn_clk) reset_by(no_reset);
      method                            cor_n(cfg_err_cor_n)                         enable((*inhigh*)en19) clocked_by(trn_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)       enable((*inhigh*)en20) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy_n          cpl_rdy_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method                            locked_n(cfg_err_locked_n)                   enable((*inhigh*)en21) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: cfg_err

   interface PCIE_TRN trn;
      output_clock                      clk(trn_clk);
      output_clock                      clk2(trn2_clk);
      output_reset                      reset_n(trn_reset_n)                                                clocked_by(trn_clk);
      method trn_lnk_up_n               lnk_up_n                                                            clocked_by(no_clock) reset_by(no_reset); /* semi-static */
   endinterface: trn

   interface PCIE_TRN_TX trn_tx;
      method                            tsof_n(trn_tsof_n)                           enable((*inhigh*)en22) clocked_by(trn_clk) reset_by(no_reset);
      method                            teof_n(trn_teof_n)                           enable((*inhigh*)en23) clocked_by(trn_clk) reset_by(no_reset);
      method                            td(trn_td)                                   enable((*inhigh*)en24) clocked_by(trn_clk) reset_by(no_reset);
      method                            trem_n(trn_trem_n)                           enable((*inhigh*)en25) clocked_by(trn_clk) reset_by(no_reset);
      method                            tsrc_rdy_n(trn_tsrc_rdy_n)                   enable((*inhigh*)en26) clocked_by(trn_clk) reset_by(no_reset);
      method trn_tdst_rdy_n             tdst_rdy_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            tsrc_dsc_n(trn_tsrc_dsc_n)                   enable((*inhigh*)en27) clocked_by(trn_clk) reset_by(no_reset);
      method trn_tdst_dsc_n             tdst_dsc_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_tbuf_av                tbuf_av                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            terrfwd_n(trn_terrfwd_n)                     enable((*inhigh*)en31) clocked_by(trn_clk) reset_by(no_reset);
   endinterface: trn_tx

   interface PCIE_TRN_RX trn_rx;
      method trn_rsof_n                 rsof_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_reof_n                 reof_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_rd                     rd                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method trn_rrem_n                 rrem_n                                                              clocked_by(trn_clk) reset_by(no_reset);
      method trn_rerrfwd_n              rerrfwd_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rsrc_rdy_n             rsrc_rdy_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            rdst_rdy_n(trn_rdst_rdy_n)                   enable((*inhigh*)en28) clocked_by(trn_clk) reset_by(no_reset);
      method trn_rsrc_dsc_n             rsrc_dsc_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method                            rnp_ok_n(trn_rnp_ok_n)                       enable((*inhigh*)en29) clocked_by(trn_clk) reset_by(no_reset);
      method                            rcpl_streaming_n(trn_rcpl_streaming_n)       enable((*inhigh*)en30) clocked_by(trn_clk) reset_by(no_reset);
      method trn_rbar_hit_n             rbar_hit_n                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_ph_av              rfc_ph_av                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_pd_av              rfc_pd_av                                                           clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_nph_av             rfc_nph_av                                                          clocked_by(trn_clk) reset_by(no_reset);
      method trn_rfc_npd_av             rfc_npd_av                                                          clocked_by(trn_clk) reset_by(no_reset);
   endinterface: trn_rx

   schedule (pcie_rxp, pcie_rxn, pcie_txp, pcie_txn, cfg_dataout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_wr_en_n, cfg_rd_en_n, cfg_irq_interrupt_n, cfg_irq_interrupt_rdy_n, cfg_irq_interrupt_mmenable, cfg_irq_interrupt_msienable,
             cfg_irq_interrupt_di, cfg_irq_interrupt_do, cfg_irq_interrupt_assert_n, cfg_to_turnoff_n, cfg_byte_en_n, cfg_bus_number, cfg_device_number, cfg_function_number,
             cfg_status, cfg_command, cfg_dstatus, cfg_dcommand, cfg_lstatus, cfg_lcommand, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn,
             cfg_err_ecrc_n, cfg_err_ur_n, cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n, cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n,
             trn_lnk_up_n, trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n, trn_tx_tsrc_dsc_n, trn_tx_tdst_dsc_n, trn_tx_tbuf_av, trn_tx_terrfwd_n,
             trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n, trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rcpl_streaming_n, trn_rx_rbar_hit_n, trn_rx_rfc_ph_av, trn_rx_rfc_pd_av, trn_rx_rfc_nph_av, trn_rx_rfc_npd_av) CF
            (pcie_rxp, pcie_rxn, pcie_txp, pcie_txn, cfg_dataout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_wr_en_n, cfg_rd_en_n, cfg_irq_interrupt_n, cfg_irq_interrupt_rdy_n, cfg_irq_interrupt_mmenable, cfg_irq_interrupt_msienable,
             cfg_irq_interrupt_di, cfg_irq_interrupt_do, cfg_irq_interrupt_assert_n, cfg_to_turnoff_n, cfg_byte_en_n, cfg_bus_number, cfg_device_number, cfg_function_number,
             cfg_status, cfg_command, cfg_dstatus, cfg_dcommand, cfg_lstatus, cfg_lcommand, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn,
             cfg_err_ecrc_n, cfg_err_ur_n, cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n, cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n,
             trn_lnk_up_n, trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n, trn_tx_tsrc_dsc_n, trn_tx_tdst_dsc_n, trn_tx_tbuf_av, trn_tx_terrfwd_n,
             trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n, trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rcpl_streaming_n, trn_rx_rbar_hit_n, trn_rx_rfc_ph_av, trn_rx_rfc_pd_av, trn_rx_rfc_nph_av, trn_rx_rfc_npd_av);

endmodule: vMkVirtex5PCIExpressWithDCM

// V6 TRN...
import "BVI" xilinx_v6_pcie_wrapper =
module vMkVirtex6PCIExpressWithDCM#(PCIEParams params)(PCIE_V6#(lanes))
   provisos(Add#(1, z, lanes));

   default_clock clk(sys_clk);
   default_reset rstn(sys_reset_n);

   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";

   interface PCIE_EXP pcie;
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en0)                              reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en1)                              reset_by(no_reset);
      method pci_exp_txp                txp                                                                 reset_by(no_reset);
      method pci_exp_txn                txn                                                                 reset_by(no_reset);
   endinterface

   interface PCIE_TRN_V6 trn;
      output_clock                      clk(trn_clk);
      output_clock                      clk2(trn2_clk);
      output_reset                      reset_n(trn_reset_n)                                                clocked_by(trn_clk);
      method trn_lnk_up_n               lnk_up_n                                                            clocked_by(no_clock) reset_by(no_reset); /* semi-static */
      method trn_fc_ph                  fc_ph                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_pd                  fc_pd                                                               clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_nph                 fc_nph                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_npd                 fc_npd                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_cplh                fc_cplh                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method trn_fc_cpld                fc_cpld                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method                            fc_sel(trn_fc_sel)                           enable((*inhigh*)en01) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_TRN_TX_V6 trn_tx;
      method                            tsof_n(trn_tsof_n)                           enable((*inhigh*)en02) clocked_by(trn_clk)  reset_by(no_reset);
      method                            teof_n(trn_teof_n)                           enable((*inhigh*)en03) clocked_by(trn_clk)  reset_by(no_reset);
      method                            td(trn_td)                                   enable((*inhigh*)en04) clocked_by(trn_clk)  reset_by(no_reset);
      method                            trem_n(trn_trem_n)                           enable((*inhigh*)en05) clocked_by(trn_clk)  reset_by(no_reset);
      method                            tsrc_rdy_n(trn_tsrc_rdy_n)                   enable((*inhigh*)en06) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tdst_rdy_n             tdst_rdy_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            tsrc_dsc_n(trn_tsrc_dsc_n)                   enable((*inhigh*)en07) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tbuf_av                tbuf_av                                                             clocked_by(trn_clk)  reset_by(no_reset);
      method trn_terr_drop_n            terr_drop_n                                                         clocked_by(trn_clk)  reset_by(no_reset);
      method                            tstr_n(trn_tstr_n)                           enable((*inhigh*)en08) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_tcfg_req_n             tcfg_req_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            tcfg_gnt_n(trn_tcfg_gnt_n)                   enable((*inhigh*)en09) clocked_by(trn_clk)  reset_by(no_reset);
      method                            terrfwd_n(trn_terrfwd_n)                     enable((*inhigh*)en10) clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_TRN_RX_V6 trn_rx;
      method trn_rsof_n                 rsof_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_reof_n                 reof_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rd                     rd                                                                  clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rrem_n                 rrem_n                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rerrfwd_n              rerrfwd_n                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rsrc_rdy_n             rsrc_rdy_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            rdst_rdy_n(trn_rdst_rdy_n)                   enable((*inhigh*)en11) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rsrc_dsc_n             rsrc_dsc_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
      method                            rnp_ok_n(trn_rnp_ok_n)                       enable((*inhigh*)en12) clocked_by(trn_clk)  reset_by(no_reset);
      method trn_rbar_hit_n             rbar_hit_n                                                          clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_PL_V6 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_gen2_capable       link_gen2_capable                                                        clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(trn_clk)  reset_by(no_reset);
      method pl_link_upcfg_capable      link_upcfg_capable                                                       clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_link_rate           sel_link_rate                                                            clocked_by(trn_clk)  reset_by(no_reset);
      method pl_sel_link_width          sel_link_width                                                           clocked_by(trn_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en13) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en14) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en15) clocked_by(trn_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en16) clocked_by(trn_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en17) clocked_by(trn_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(trn_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_CFG_V6 cfg;
      method cfg_do                     dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_rd_wr_done_n           rd_wr_done_n                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_di)                                        enable((*inhigh*)en18) clocked_by(trn_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                                enable((*inhigh*)en19) clocked_by(trn_clk) reset_by(no_reset);
      method                            byte_en_n(cfg_byte_en_n)                          enable((*inhigh*)en20) clocked_by(trn_clk) reset_by(no_reset);
      method                            wr_en_n(cfg_wr_en_n)                              enable((*inhigh*)en21) clocked_by(trn_clk) reset_by(no_reset);
      method                            rd_en_n(cfg_rd_en_n)                              enable((*inhigh*)en22) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                               clocked_by(trn_clk) reset_by(no_reset);
      method cfg_device_number          device_number                                                            clocked_by(trn_clk) reset_by(no_reset);
      method cfg_function_number        function_number                                                          clocked_by(trn_clk) reset_by(no_reset);
      method cfg_status                 status                                                                   clocked_by(trn_clk) reset_by(no_reset);
      method cfg_command                command                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                  clocked_by(trn_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_to_turnoff_n           to_turnoff_n                                                             clocked_by(trn_clk) reset_by(no_reset);
      method                            turnoff_ok_n(cfg_turnoff_ok_n)                    enable((*inhigh*)en23) clocked_by(trn_clk) reset_by(no_reset);
      method                            pm_wake_n(cfg_pm_wake_n)                          enable((*inhigh*)en24) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pcie_link_state_n      pcie_link_state_n                                                        clocked_by(trn_clk) reset_by(no_reset);
      method                            trn_pending_n(cfg_trn_pending_n)                  enable((*inhigh*)en25) clocked_by(trn_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                      enable((*inhigh*)en26) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                             clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                         clocked_by(trn_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                         clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   interface PCIE_INT_V6 cfg_interrupt;
      method                            req_n(cfg_interrupt_n)                            enable((*inhigh*)en27) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_rdy_n        rdy_n                                                                    clocked_by(trn_clk) reset_by(no_reset);
      method                            assert_n(cfg_interrupt_assert_n)                  enable((*inhigh*)en28) clocked_by(trn_clk) reset_by(no_reset);
      method                            di(cfg_interrupt_di)                              enable((*inhigh*)en29) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                     clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                 clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                               clocked_by(trn_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                   clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   interface PCIE_ERR_V6 cfg_err;
      method                            ecrc_n(cfg_err_ecrc_n)                       enable((*inhigh*)en30) clocked_by(trn_clk) reset_by(no_reset);
      method                            ur_n(cfg_err_ur_n)                           enable((*inhigh*)en31) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_timeout_n(cfg_err_cpl_timeout_n)         enable((*inhigh*)en32) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_unexpect_n(cfg_err_cpl_unexpect_n)       enable((*inhigh*)en33) clocked_by(trn_clk) reset_by(no_reset);
      method                            cpl_abort_n(cfg_err_cpl_abort_n)             enable((*inhigh*)en34) clocked_by(trn_clk) reset_by(no_reset);
      method                            posted_n(cfg_err_posted_n)                   enable((*inhigh*)en35) clocked_by(trn_clk) reset_by(no_reset);
      method                            cor_n(cfg_err_cor_n)                         enable((*inhigh*)en36) clocked_by(trn_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)       enable((*inhigh*)en37) clocked_by(trn_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy_n          cpl_rdy_n                                                           clocked_by(trn_clk) reset_by(no_reset);
      method                            locked_n(cfg_err_locked_n)                   enable((*inhigh*)en38) clocked_by(trn_clk) reset_by(no_reset);
   endinterface

   schedule (
             pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
             trn_lnk_up_n, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel,
             trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n,
             trn_tx_tsrc_dsc_n, trn_tx_tbuf_av, trn_tx_terr_drop_n, trn_tx_tstr_n, trn_tx_tcfg_req_n, trn_tx_tcfg_gnt_n,
             trn_tx_terrfwd_n, trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n,
             trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rbar_hit_n,
             pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
             pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
             pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph,
             pl_received_hot_rst, cfg_dout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_byte_en_n, cfg_wr_en_n,
             cfg_rd_en_n, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command,
             cfg_dstatus, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_to_turnoff_n,
             cfg_turnoff_ok_n, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn, cfg_pmcsr_pme_en,
             cfg_pmcsr_pme_status, cfg_pmcsr_powerstate, cfg_interrupt_req_n, cfg_interrupt_rdy_n,
             cfg_interrupt_assert_n, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable,
             cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_err_ecrc_n, cfg_err_ur_n,
             cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n,
             cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n
             )
            CF
            (
             pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
             trn_lnk_up_n, trn_fc_ph, trn_fc_pd, trn_fc_nph, trn_fc_npd, trn_fc_cplh, trn_fc_cpld, trn_fc_sel,
             trn_tx_tsof_n, trn_tx_teof_n, trn_tx_td, trn_tx_trem_n, trn_tx_tsrc_rdy_n, trn_tx_tdst_rdy_n,
             trn_tx_tsrc_dsc_n, trn_tx_tbuf_av, trn_tx_terr_drop_n, trn_tx_tstr_n, trn_tx_tcfg_req_n, trn_tx_tcfg_gnt_n,
             trn_tx_terrfwd_n, trn_rx_rsof_n, trn_rx_reof_n, trn_rx_rd, trn_rx_rrem_n, trn_rx_rerrfwd_n,
             trn_rx_rsrc_rdy_n, trn_rx_rdst_rdy_n, trn_rx_rsrc_dsc_n, trn_rx_rnp_ok_n, trn_rx_rbar_hit_n,
             pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
             pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
             pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph,
             pl_received_hot_rst, cfg_dout, cfg_rd_wr_done_n, cfg_di, cfg_dwaddr, cfg_byte_en_n, cfg_wr_en_n,
             cfg_rd_en_n, cfg_bus_number, cfg_device_number, cfg_function_number, cfg_status, cfg_command,
             cfg_dstatus, cfg_dcommand, cfg_dcommand2, cfg_lstatus, cfg_lcommand, cfg_to_turnoff_n,
             cfg_turnoff_ok_n, cfg_pm_wake_n, cfg_pcie_link_state_n, cfg_trn_pending_n, cfg_dsn, cfg_pmcsr_pme_en,
             cfg_pmcsr_pme_status, cfg_pmcsr_powerstate, cfg_interrupt_req_n, cfg_interrupt_rdy_n,
             cfg_interrupt_assert_n, cfg_interrupt_di, cfg_interrupt_dout, cfg_interrupt_mmenable,
             cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_err_ecrc_n, cfg_err_ur_n,
             cfg_err_cpl_timeout_n, cfg_err_cpl_unexpect_n, cfg_err_cpl_abort_n, cfg_err_posted_n,
             cfg_err_cor_n, cfg_err_tlp_cpl_header, cfg_err_cpl_rdy_n, cfg_err_locked_n
             );

endmodule: vMkVirtex6PCIExpressWithDCM

// V6 AXI (X6)...
// Note this imports the coregen top-level directly without the use of a Verilog wrapper;
// thus this code may change if the ports and function change in future versions.
import "BVI" v6_pcie_v2_3 =
module vMkPCIExpressXilinxAXI#(PCIEParams params)(PCIE_X6#(lanes))
   provisos(Add#(1, z, lanes));

   Reset reset <- invertCurrentReset;

   default_clock clk(sys_clk);
   default_reset rst(sys_reset) = reset;  // sys_reset is active high

   parameter PL_FAST_TRAIN = (params.fast_train_sim_only) ? "TRUE" : "FALSE";

   interface PCIE_EXP pcie;
      method pci_exp_txp                txp                                                                      reset_by(no_reset);
      method pci_exp_txn                txn                                                                      reset_by(no_reset);
      method                            rxp(pci_exp_rxp) enable((*inhigh*)en0)                                   reset_by(no_reset);
      method                            rxn(pci_exp_rxn) enable((*inhigh*)en1)                                   reset_by(no_reset);
   endinterface

   interface PCIE_AXI axi;
      output_clock                      clk(user_clk_out);
      output_clock                      drp(drp_clk);
      output_reset                      usr_rst_p(user_reset_out)                                                clocked_by(axi_clk);
      method user_lnk_up                lnk_up                                                                   clocked_by(no_clock) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_TX axi_tx;
      method tx_buf_av                  tbuf_av                                                                  clocked_by(axi_clk)  reset_by(no_reset);
      method tx_err_drop                terr_drop                                                                clocked_by(axi_clk)  reset_by(no_reset);
      method tx_cfg_req                 tcfg_req                                                                 clocked_by(axi_clk)  reset_by(no_reset);
      method s_axis_tx_tready           tready                                                                   clocked_by(axi_clk)  reset_by(no_reset);
      method                            tdata(s_axis_tx_tdata)                            enable((*inhigh*)en02) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tstrb(s_axis_tx_tstrb)                            enable((*inhigh*)en03) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tuser(s_axis_tx_tuser)                            enable((*inhigh*)en04) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tlast(s_axis_tx_tlast)                            enable((*inhigh*)en05) clocked_by(axi_clk)  reset_by(no_reset);
      method                            tvalid(s_axis_tx_tvalid)                          enable((*inhigh*)en06) clocked_by(axi_clk)  reset_by(no_reset);
      method                            cfg_gnt(tx_cfg_gnt)                               enable((*inhigh*)en07) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_RX axi_rx;
      method m_axis_rx_tdata            tdata                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tstrb            tstrb                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tlast            tlast                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tvalid           tvalid                                                                   clocked_by(axi_clk)  reset_by(no_reset);
      method m_axis_rx_tuser            tuser                                                                    clocked_by(axi_clk)  reset_by(no_reset);
      method                            tready(m_axis_rx_tready)                          enable((*inhigh*)en08) clocked_by(axi_clk)  reset_by(no_reset);
      method                            np_ok(rx_np_ok)                                   enable((*inhigh*)en09) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_FC axi_fc;
      method fc_cpld                    cpld                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method fc_cplh                    cplh                                                                     clocked_by(axi_clk)  reset_by(no_reset);
      method fc_npd                     npd                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_nph                     nph                                                                      clocked_by(axi_clk)  reset_by(no_reset);
      method fc_pd                      pd                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method fc_ph                      ph                                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method                            sel(fc_sel)                                       enable((*inhigh*)en10) clocked_by(axi_clk)  reset_by(no_reset);
   endinterface

   interface PCIE_AXI_CFG cfg;
      method cfg_do                     dout                                                                     clocked_by(axi_clk) reset_by(no_reset);
      method cfg_rd_wr_done             rd_wr_done                                                               clocked_by(axi_clk) reset_by(no_reset);
      method                            di(cfg_di)                                        enable((*inhigh*)en11) clocked_by(axi_clk) reset_by(no_reset);
      method                            byte_en(cfg_byte_en)                              enable((*inhigh*)en12) clocked_by(axi_clk) reset_by(no_reset);
      method                            dwaddr(cfg_dwaddr)                                enable((*inhigh*)en13) clocked_by(axi_clk) reset_by(no_reset);
      method                            wr_en(cfg_wr_en)                                  enable((*inhigh*)en14) clocked_by(axi_clk) reset_by(no_reset);
      method                            rd_en(cfg_rd_en)                                  enable((*inhigh*)en15) clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_ERR cfg_error;
      method                            cor(cfg_err_cor)                                  enable((*inhigh*)en16) clocked_by(axi_clk) reset_by(no_reset);
      method                            ur(cfg_err_ur)                                    enable((*inhigh*)en17) clocked_by(axi_clk) reset_by(no_reset);
      method                            ecrc(cfg_err_ecrc)                                enable((*inhigh*)en18) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_timeout(cfg_err_cpl_timeout)                  enable((*inhigh*)en19) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_abort(cfg_err_cpl_abort)                      enable((*inhigh*)en20) clocked_by(axi_clk) reset_by(no_reset);
      method                            cpl_unexpect(cfg_err_cpl_unexpect)                enable((*inhigh*)en21) clocked_by(axi_clk) reset_by(no_reset);
      method                            posted(cfg_err_posted)                            enable((*inhigh*)en22) clocked_by(axi_clk) reset_by(no_reset);
      method                            locked(cfg_err_locked)                            enable((*inhigh*)en23) clocked_by(axi_clk) reset_by(no_reset);
      method                            tlp_cpl_header(cfg_err_tlp_cpl_header)            enable((*inhigh*)en24) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_err_cpl_rdy            cpl_rdy                                                                  clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_INT cfg_interrupt;
      method                            req(cfg_interrupt)                                enable((*inhigh*)en25) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_rdy          rdy                                                                      clocked_by(axi_clk) reset_by(no_reset);
      method                            iassert(cfg_interrupt_assert)                     enable((*inhigh*)en26) clocked_by(axi_clk) reset_by(no_reset);
      method                            din(cfg_interrupt_di)                             enable((*inhigh*)en27) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_do           dout                                                                     clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_mmenable     mmenable                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msienable    msienable                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixenable   msixenable                                                               clocked_by(axi_clk) reset_by(no_reset);
      method cfg_interrupt_msixfm       msixfm                                                                   clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AXI_CFG2 cfg2;
      method                            turnoff_ok(cfg_turnoff_ok)                        enable((*inhigh*)en28) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_to_turnoff             to_turnoff                                                               clocked_by(axi_clk) reset_by(no_reset);
      method                            trn_pending(cfg_trn_pending)                      enable((*inhigh*)en29) clocked_by(axi_clk) reset_by(no_reset);
      method                            pm_wake(cfg_pm_wake)                              enable((*inhigh*)en30) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_bus_number             bus_number                                                               clocked_by(axi_clk) reset_by(no_reset);
      method cfg_device_number          device_number                                                            clocked_by(axi_clk) reset_by(no_reset);
      method cfg_function_number        function_number                                                          clocked_by(axi_clk) reset_by(no_reset);
      method cfg_status                 status                                                                   clocked_by(axi_clk) reset_by(no_reset);
      method cfg_command                command                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dstatus                dstatus                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand               dcommand                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lstatus                lstatus                                                                  clocked_by(axi_clk) reset_by(no_reset);
      method cfg_lcommand               lcommand                                                                 clocked_by(axi_clk) reset_by(no_reset);
      method cfg_dcommand2              dcommand2                                                                clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pcie_link_state        pcie_link_state                                                          clocked_by(axi_clk) reset_by(no_reset);
      method                            dsn(cfg_dsn)                                      enable((*inhigh*)en31) clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_en           pmcsr_pme_en                                                             clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_pme_status       pmcsr_pme_status                                                         clocked_by(axi_clk) reset_by(no_reset);
      method cfg_pmcsr_powerstate       pmcsr_powerstate                                                         clocked_by(axi_clk) reset_by(no_reset);
   endinterface

   interface PCIE_PL_V6 pl;
      method pl_initial_link_width      initial_link_width                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_lane_reversal_mode      lane_reversal_mode                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_gen2_capable       link_gen2_capable                                                        clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_partner_gen2_supported link_partner_gen2_supported                                          clocked_by(axi_clk)  reset_by(no_reset);
      method pl_link_upcfg_capable      link_upcfg_capable                                                       clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_link_rate           sel_link_rate                                                            clocked_by(axi_clk)  reset_by(no_reset);
      method pl_sel_link_width          sel_link_width                                                           clocked_by(axi_clk)  reset_by(no_reset);
      method pl_ltssm_state             ltssm_state                                                              clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_auton(pl_directed_link_auton)       enable((*inhigh*)en32) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_change(pl_directed_link_change)     enable((*inhigh*)en33) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_speed(pl_directed_link_speed)       enable((*inhigh*)en34) clocked_by(axi_clk)  reset_by(no_reset);
      method                            directed_link_width(pl_directed_link_width)       enable((*inhigh*)en35) clocked_by(axi_clk)  reset_by(no_reset);
      method                            upstream_prefer_deemph(pl_upstream_prefer_deemph) enable((*inhigh*)en36) clocked_by(axi_clk)  reset_by(no_reset);
      method pl_received_hot_rst        received_hot_rst                                                         clocked_by(axi_clk)  reset_by(no_reset);
   endinterface


   schedule (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tstrb, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tstrb, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 

     cfg_dout, cfg_rd_wr_done, cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, 
     cfg_error_cor, cfg_error_ur, cfg_error_ecrc, cfg_error_cpl_timeout, cfg_error_cpl_abort, cfg_error_cpl_unexpect, cfg_error_posted, cfg_error_locked, cfg_error_tlp_cpl_header, cfg_error_cpl_rdy, 
     cfg_interrupt_req, cfg_interrupt_rdy, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, 
     cfg2_turnoff_ok, cfg2_to_turnoff, cfg2_trn_pending, cfg2_pm_wake, cfg2_bus_number, cfg2_device_number, cfg2_function_number, cfg2_status,
     cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_dsn,
     cfg2_pmcsr_pme_en, cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 

     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     )
     CF
     (
     pcie_rxp, pcie_rxn, pcie_txp, pcie_txn,
     axi_lnk_up, axi_fc_cpld, axi_fc_cplh, axi_fc_npd, axi_fc_nph, axi_fc_pd, axi_fc_ph, axi_fc_sel, 
     axi_tx_tbuf_av, axi_tx_terr_drop, axi_tx_tcfg_req, axi_tx_tready, axi_tx_tdata, axi_tx_tstrb, axi_tx_tuser, axi_tx_tlast, axi_tx_tvalid, axi_tx_cfg_gnt, 
     axi_rx_tdata, axi_rx_tstrb, axi_rx_tlast, axi_rx_tvalid, axi_rx_tuser, axi_rx_tready, axi_rx_np_ok, 

     cfg_dout, cfg_rd_wr_done, cfg_di, cfg_byte_en, cfg_dwaddr, cfg_wr_en, cfg_rd_en, 
     cfg_error_cor, cfg_error_ur, cfg_error_ecrc, cfg_error_cpl_timeout, cfg_error_cpl_abort, cfg_error_cpl_unexpect, cfg_error_posted, cfg_error_locked, cfg_error_tlp_cpl_header, cfg_error_cpl_rdy, 
     cfg_interrupt_req, cfg_interrupt_rdy, cfg_interrupt_iassert, cfg_interrupt_din, cfg_interrupt_dout, cfg_interrupt_mmenable, cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, 
     cfg2_turnoff_ok, cfg2_to_turnoff, cfg2_trn_pending, cfg2_pm_wake, cfg2_bus_number, cfg2_device_number, cfg2_function_number, cfg2_status,
     cfg2_command, cfg2_dstatus, cfg2_dcommand, cfg2_lstatus, cfg2_lcommand, cfg2_dcommand2, cfg2_pcie_link_state, cfg2_dsn,
     cfg2_pmcsr_pme_en, cfg2_pmcsr_pme_status, cfg2_pmcsr_powerstate, 

     pl_initial_link_width, pl_lane_reversal_mode, pl_link_gen2_capable, pl_link_partner_gen2_supported,
     pl_link_upcfg_capable, pl_sel_link_rate, pl_sel_link_width, pl_ltssm_state, pl_directed_link_auton,
     pl_directed_link_change, pl_directed_link_speed, pl_directed_link_width, pl_upstream_prefer_deemph, pl_received_hot_rst
     );

endmodule: vMkPCIExpressXilinxAXI


// Altera Avalon-SX...
import "BVI" pcie_hip_s4gx_gen2_x4_128_wrapper =
module vMkStratix4PCIExpress#(Clock sclk, Reset srstn, Clock pclk, Reset prstn) (PCIE_vS4GX#(lanes))
   provisos(Add#(lanes, 0, 4));

   input_clock sclk    (sys0_clk)                   = sclk;
   input_reset srstn   (sys0_rstn) clocked_by(sclk) = srstn;
   default_clock       (pcie_clk)  = pclk;
   default_reset prstn (pcie_rstn) = prstn;

   interface PCIE_EXP_ALT pcie;
      method                            rx(pcie_rx_in)     enable((*inhigh*)en00)  reset_by(no_reset);
      method pcie_tx_out                tx                                         reset_by(no_reset);
      //method                            prsnt(pcie_prsnt)  enable((*inhigh*)en01)  reset_by(no_reset);
      //method pcie_waken                 waken                                      reset_by(no_reset);
   endinterface

   interface PCIE_AVALONST ava;
      output_clock                      clk(ava_core_clk_out);
      output_reset                      usr_rst(ava_srstn)                  clocked_by(ava_clk);
      method ava_alive                  alive                               clocked_by(no_clock) reset_by(no_reset); 
      method ava_lnk_up                 lnk_up                              clocked_by(no_clock) reset_by(no_reset); 
      method ava_debug                  debug                               clocked_by(no_clock) reset_by(no_reset); 
   endinterface

   interface PCIE_AVALONST_RX ava_rx;
      method                            mask(rx_st_mask0)    enable((*inhigh*)en04) clocked_by(ava_clk) reset_by(no_reset);
      method                            rdy (rx_st_ready0)   enable((*inhigh*)en05) clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_valid0  valid                                                 clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_bardec0 bar                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_be0     be                                                    clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_data0   data                                                  clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_sop0    sop                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_eop0    eop                                                   clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_empty0  empty                                                 clocked_by(ava_clk) reset_by(no_reset);
      method    rx_st_err0    err                                                   clocked_by(ava_clk) reset_by(no_reset);
   endinterface

   interface PCIE_AVALONST_TX ava_tx;
      method                            data (tx_st_data0)  enable((*inhigh*)en06) clocked_by(ava_clk) reset_by(no_reset);
      method                            sop  (tx_st_sop0)   enable((*inhigh*)en07) clocked_by(ava_clk) reset_by(no_reset);
      method                            eop  (tx_st_eop0)   enable((*inhigh*)en08) clocked_by(ava_clk) reset_by(no_reset);
      method                            empty(tx_st_empty0) enable((*inhigh*)en09) clocked_by(ava_clk) reset_by(no_reset);
      method                            valid(tx_st_valid0) enable((*inhigh*)en10) clocked_by(ava_clk) reset_by(no_reset);
      method                            err  (tx_st_err0)   enable((*inhigh*)en11) clocked_by(ava_clk) reset_by(no_reset);
      method    tx_st_ready0   tready                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tx_cred0       credit                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tx_fifo_empty0 fEmpty                                              clocked_by(ava_clk) reset_by(no_reset);
   endinterface

   interface PCIE_ALT_CFG cfg;
      method    tl_cfg_add     addr                                                clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_ctl     data                                                clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_ctl_wr  dataWrite                                           clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_sts     status                                              clocked_by(ava_clk) reset_by(no_reset);
      method    tl_cfg_sts_wr  statusWrite                                         clocked_by(ava_clk) reset_by(no_reset);
   endinterface

     schedule (pcie_rx, pcie_tx, ava_alive, ava_lnk_up, ava_debug, ava_rx_mask, ava_rx_rdy, ava_rx_valid, ava_rx_bar, ava_rx_be, ava_rx_data, ava_rx_sop, ava_rx_eop, ava_rx_empty, ava_rx_err, ava_tx_data, ava_tx_sop, ava_tx_eop, ava_tx_empty, ava_tx_valid, ava_tx_err, ava_tx_tready, ava_tx_credit, ava_tx_fEmpty, cfg_addr, cfg_data, cfg_dataWrite, cfg_status, cfg_statusWrite) CF
     (pcie_rx, pcie_tx, ava_alive, ava_lnk_up, ava_debug, ava_rx_mask, ava_rx_rdy, ava_rx_valid, ava_rx_bar, ava_rx_be, ava_rx_data, ava_rx_sop, ava_rx_eop, ava_rx_empty, ava_rx_err, ava_tx_data, ava_tx_sop, ava_tx_eop, ava_tx_empty, ava_tx_valid, ava_tx_err, ava_tx_tready, ava_tx_credit, ava_tx_fEmpty, cfg_addr, cfg_data, cfg_dataWrite, cfg_status, cfg_statusWrite);

endmodule: vMkStratix4PCIExpress 


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


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx V5 TRN
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpoint#(PCIEParams params)(PCIExpress#(lanes))
   provisos(Add#(1, z, lanes));

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE#(lanes)                              pcie_ep             <- vMkVirtex5PCIExpressWithDCM(params);

   Clock                                     trnclk               = pcie_ep.trn.clk;
   Clock                                     trn2clk              = pcie_ep.trn.clk2;
   Reset                                     trnrst_n             = pcie_ep.trn.reset_n;

   PulseWire                                 pwTrnTx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxSof           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxEof           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnTxDsc           <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bit#(8))                            wTrnTxRem           <- mkDWire(8'h00, clocked_by trnclk, reset_by noReset);
   Wire#(Bit#(64))                           wTrnTxDat           <- mkDWire(64'h00, clocked_by trnclk, reset_by noReset);

   PulseWire                                 pwTrnRx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxNpOk          <- mkDWire(True, clocked_by trnclk, reset_by noReset);
   Wire#(Bool)                               wTrnRxCplS          <- mkDWire(True, clocked_by trnclk, reset_by noReset);

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule connect_trn_tx;
      pcie_ep.trn_tx.tsof_n(pack(wTrnTxSof));
      pcie_ep.trn_tx.teof_n(pack(wTrnTxEof));
      pcie_ep.trn_tx.tsrc_dsc_n(pack(wTrnTxDsc));
      pcie_ep.trn_tx.trem_n(~wTrnTxRem);
      pcie_ep.trn_tx.td(wTrnTxDat);
      pcie_ep.trn_tx.tsrc_rdy_n(pack(!pwTrnTx));
      pcie_ep.trn_tx.terrfwd_n('1);
   endrule

   rule connect_trn_rx;
      pcie_ep.trn_rx.rdst_rdy_n(pack(!pwTrnRx));
      pcie_ep.trn_rx.rnp_ok_n(pack(wTrnRxNpOk));
      pcie_ep.trn_rx.rcpl_streaming_n(pack(wTrnRxCplS));
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface clkout  = pcie_ep.clkout;
   interface pcie    = pcie_ep.pcie;

   interface PCIE_TRN_COMMON trn;
      interface clk           = pcie_ep.trn.clk;
      interface clk2          = pcie_ep.trn.clk2;
      interface reset_n       = pcie_ep.trn.reset_n;
      method Bool link_up     = (pcie_ep.trn.lnk_up_n == 0);
   endinterface: trn

   interface PCIE_TRN_XMIT trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.trn_tx.tdst_rdy_n == 0);
         wTrnTxSof <= !data.sof;
         wTrnTxEof <= !data.eof;
         wTrnTxDsc <= !discontinue;
         wTrnTxRem <= data.be;
         wTrnTxDat <= data.data;
         pwTrnTx.send;
      endmethod
      method discontinued      = (pcie_ep.trn_tx.tdst_dsc_n == 0);
      method buffers_available = pcie_ep.trn_tx.tbuf_av;
   endinterface: trn_tx

   interface PCIE_TRN_RECV trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.trn_rx.rsrc_rdy_n == 0);
         TLPData#(8) retval = defaultValue;
         retval.sof  = (pcie_ep.trn_rx.rsof_n == 0);
         retval.eof  = (pcie_ep.trn_rx.reof_n == 0);
         retval.hit  = ~pcie_ep.trn_rx.rbar_hit_n;
         retval.be   = ~pcie_ep.trn_rx.rrem_n;
         retval.data = pcie_ep.trn_rx.rd;
         pwTrnRx.send;
         return retval;
      endmethod
      method error_forward      = (pcie_ep.trn_rx.rerrfwd_n == 0);
      method source_discontinue = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      method Action non_posted_ready(i);
         wTrnRxNpOk <= !i;
      endmethod
      method Action completion_streaming(i);
         wTrnRxCplS <= !i;
      endmethod
      method posted_header_credits     = pcie_ep.trn_rx.rfc_ph_av;
      method posted_data_credits       = pcie_ep.trn_rx.rfc_pd_av;
      method non_posted_header_credits = pcie_ep.trn_rx.rfc_nph_av;
      method non_posted_data_credits   = pcie_ep.trn_rx.rfc_npd_av;
   endinterface: trn_rx

   interface cfg        = pcie_ep.cfg;
   interface cfg_irq    = pcie_ep.cfg_irq;
   interface cfg_err    = pcie_ep.cfg_err;
endmodule: mkPCIExpressEndpoint

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx V6 TRN
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointV6#(PCIEParams params)(PCIExpressV6#(lanes))
   provisos(Add#(1, z, lanes));

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE_V6#(lanes)                           pcie_ep             <- vMkVirtex6PCIExpressWithDCM(params);

   Clock                                     trnclk               = pcie_ep.trn.clk;    // 250 MHz
   Clock                                     trn2clk              = pcie_ep.trn.clk2;   // 125 MHz trn_clk/2
   Reset                                     trnrst_n             = pcie_ep.trn.reset_n;

   PulseWire                                 pwTrnTx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);
   PulseWire                                 pwTrnRx             <- mkPulseWire(clocked_by trnclk, reset_by noReset);

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule connect_trn_tx;
      pcie_ep.trn_tx.tsrc_rdy_n(pack(!pwTrnTx));
   endrule

   rule connect_trn_rx;
      pcie_ep.trn_rx.rdst_rdy_n(pack(!pwTrnRx));
   endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie       = pcie_ep.pcie;

   interface PCIE_TRN_COMMON_V6 trn;
      interface clk           = pcie_ep.trn.clk;
      interface clk2          = pcie_ep.trn.clk2;
      interface reset_n       = pcie_ep.trn.reset_n;
      method Bool link_up     = (pcie_ep.trn.lnk_up_n == 0);
   endinterface

   interface PCIE_TRN_XMIT_V6 trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.trn_tx.tdst_rdy_n == 0);
         pcie_ep.trn_tx.tsof_n(pack(!data.sof));
         pcie_ep.trn_tx.teof_n(pack(!data.eof));
         pcie_ep.trn_tx.tsrc_dsc_n(pack(!discontinue));
         pcie_ep.trn_tx.trem_n(pack(data.be != '1));
         pcie_ep.trn_tx.td(data.data);
         pwTrnTx.send;
      endmethod
      method dropped                           = (pcie_ep.trn_tx.terr_drop_n == 0);
      method buffers_available                 = pcie_ep.trn_tx.tbuf_av;
      method cut_through_mode(i)               = pcie_ep.trn_tx.tstr_n(pack(!i));
      method configuration_completion_ready    = (pcie_ep.trn_tx.tcfg_req_n == 0);
      method configuration_completion_grant(i) = pcie_ep.trn_tx.tcfg_gnt_n(pack(!i));
      method error_forward(i)                  = pcie_ep.trn_tx.terrfwd_n(pack(!i));
   endinterface

   interface PCIE_TRN_RECV_V6 trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.trn_rx.rsrc_rdy_n == 0);
         TLPData#(8) retval = defaultValue;
         retval.sof  = (pcie_ep.trn_rx.rsof_n == 0);
         retval.eof  = (pcie_ep.trn_rx.reof_n == 0);
         retval.hit  = ~pcie_ep.trn_rx.rbar_hit_n;
         retval.be   = ~(pack(replicate((pcie_ep.trn_rx.rrem_n))));
         retval.data = pcie_ep.trn_rx.rd;
         pwTrnRx.send;
         return retval;
      endmethod
      method error_forward         = (pcie_ep.trn_rx.rerrfwd_n == 0);
      method source_discontinue    = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      method non_posted_ready(i)   = pcie_ep.trn_rx.rnp_ok_n(pack(!i));
   endinterface

   interface pl            = pcie_ep.pl;
   interface cfg           = pcie_ep.cfg;
   interface cfg_interrupt = pcie_ep.cfg_interrupt;
   interface cfg_err       = pcie_ep.cfg_err;
endmodule: mkPCIExpressEndpointV6

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Xilinx AXI Virtex 6 (X6)
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointX6#(PCIEParams params)(PCIExpressV6#(lanes))       //TODO: Provide X6 (not TRN V6) as alternate implementation
   provisos(Add#(1, z, lanes));

// This implementation has the interesting challenge of backward-migrating the AXI interface from the 2.3 V6/X6 PCIe core
// to the older TRN interface it will someday replace. This is so we can test the AXI endpoint without having to change the
// uNoC and everything attached to it. It is mostly the DWORD ordering and control logic generation.

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   PCIE_X6#(lanes)       pcie_ep          <- vMkPCIExpressXilinxAXI(params);   // Instance the vMk layer
   Clock                 axiclk           = pcie_ep.axi.clk;    // 250 MHz
   Clock                 axiclk2          = pcie_ep.axi.drp;    // 125 MHz
   Reset                 usr_rst_n        <- mkResetInverter(pcie_ep.axi.usr_rst_p); // Invert the active-high user reset from the AXI core
   Reset                 axiRst250        <- mkAsyncReset(2, usr_rst_n, axiclk);
   Reset                 axiRst125        <- mkAsyncReset(2, usr_rst_n, axiclk2);
   PulseWire             pwAxiTx          <- mkPulseWire(clocked_by axiclk, reset_by noReset);
   PulseWire             pwAxiRx          <- mkPulseWire(clocked_by axiclk, reset_by noReset);
   Reg#(Bool)            rcvPktActive     <- mkDReg(False, clocked_by axiclk, reset_by axiRst250);

   Reg#(UInt#(4))        dbpciCA          <- mkReg(1);                                             // 250 MHz source
   Reg#(UInt#(4))        dbpciCB          <- mkReg(2, clocked_by axiclk,  reset_by axiRst250);     // 250 MHz from core
   Reg#(UInt#(4))        dbpciCC          <- mkReg(3, clocked_by axiclk2, reset_by axiRst125);      // 125 MHz from core

   rule cnt_ca; dbpciCA <= dbpciCA + 1; endrule
   rule cnt_cb; dbpciCB <= dbpciCB + 1; endrule
   rule cnt_cc; dbpciCC <= dbpciCC + 1; endrule

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   rule connect_axi_tx;
     pcie_ep.axi_tx.tvalid(pwAxiTx);   // assert tvalid when we xmit - causes push into EP
   endrule

   rule connect_axi_rx;
     pcie_ep.axi_rx.tready(pwAxiRx);   // assert tready when we receive - causes pop from EP 
   endrule

   rule rx_active (pcie_ep.axi_rx.tvalid && pwAxiRx); // Used to recreate SoF on RX path
     rcvPktActive <= !pcie_ep.axi_rx.tlast;
   endrule

   // Tieoffs...
   rule tx_grant; pcie_ep.axi_tx.cfg_gnt(True); endrule  // always let EP have priority
   rule rx_np_ok; pcie_ep.axi_rx.np_ok(True);   endrule  // always allow non-posted requests
   rule fc_sel;   pcie_ep.axi_fc.sel(RECEIVE_BUFFER_AVAILABLE_SPACE);     endrule  // always look at rcv credit avail
   mkTieOff(pcie_ep.pl);
   mkTieOff(pcie_ep.cfg);
   mkTieOff(pcie_ep.cfg2);
   mkTieOff(pcie_ep.cfg_interrupt);
   mkTieOff(pcie_ep.cfg_error);


   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface pcie       = pcie_ep.pcie;

   interface PCIE_TRN_COMMON_V6 trn;
      interface Clock clk      = axiclk;    // 250 MHz
      interface Clock clk2     = axiclk2;   // 125 MHz
      interface Reset reset_n  = usr_rst_n;
      method    Bool  link_up  = pcie_ep.axi.lnk_up;
   endinterface

   interface PCIE_TRN_XMIT_V6 trn_tx;
      method Action xmit(discontinue, data) if (pcie_ep.axi_tx.tready); 
         //pcie_ep.trn_tx.tsof_n(pack(!data.sof));          // no sof for AXI
         pcie_ep.axi_tx.tlast(data.eof);                    // eof goes to tlast
         //pcie_ep.trn_tx.tsrc_dsc_n(pack(!discontinue));   // no xmt discontinue
         pcie_ep.axi_tx.tstrb(reverseBits(data.be));        // active-high be's are strobes, TODO check reverseBits
         pcie_ep.axi_tx.tdata(reverseDWORDS(data.data));    // reverse DWORDS
         pwAxiTx.send;
      endmethod
      method dropped                           = pcie_ep.axi_tx.terr_drop;
      method buffers_available                 = pcie_ep.axi_tx.tbuf_av;
      //method cut_through_mode(i)               = pcie_ep.axi_tx.tstr_n(pack(!i));
      //method configuration_completion_ready    = (pcie_ep.trn_tx.tcfg_req_n == 0);
      //method configuration_completion_grant(i) = pcie_ep.trn_tx.tcfg_gnt_n(pack(!i));
      //method error_forward(i)                  = pcie_ep.trn_tx.terrfwd_n(pack(!i));
   endinterface

   interface PCIE_TRN_RECV_V6 trn_rx;
      method ActionValue#(TLPData#(8)) recv() if (pcie_ep.axi_rx.tvalid);
         TLPData#(8) retval = defaultValue;
         retval.sof  = pcie_ep.axi_rx.tvalid && !rcvPktActive; // Make SoF on first tvalid
         retval.eof  = pcie_ep.axi_rx.tlast;
         retval.hit  = pcie_ep.axi_rx.tuser[8:2]; // implementation specific choice where 7 bar bits are in tuser
         retval.be   = reverseBits(pcie_ep.axi_rx.tstrb); //TODO check reverseBits
         retval.data = reverseDWORDS(pcie_ep.axi_rx.tdata);
         pwAxiRx.send;
         return retval;
      endmethod
      //method error_forward         = (pcie_ep.trn_rx.rerrfwd_n == 0);
      //method source_discontinue    = (pcie_ep.trn_rx.rsrc_dsc_n == 0);
      //method non_posted_ready(i)   = pcie_ep.trn_rx.rnp_ok_n(pack(!i));
   endinterface


   /*
   interface pl            = pcie_ep.pl;
   interface cfg           = pcie_ep.cfg;
   interface cfg_interrupt = pcie_ep.cfg_interrupt;
   interface cfg_err       = pcie_ep.cfg_err;
   */

endmodule: mkPCIExpressEndpointX6


// Not from PCIe spec but used for head communication...
typedef struct {
 Bit#(8)         hit;
 TLPLength       length;
 TLPPacketFormat pfmt;
} TLPHeadInfo deriving (Bits, Eq);


////////////////////////////////////////////////////////////////////////////////
///
/// Implementation - Altera S4 GX - Avalon-ST Interface
///
////////////////////////////////////////////////////////////////////////////////
module mkPCIExpressEndpointS4GX#(Clock sclk, Reset srstn, Clock pclk, Reset prstn)(PCIE_S4GX#(lanes))
  provisos(Add#(lanes, 0, 4));

  PCIE_vS4GX#(4)    pcie_ep     <- vMkStratix4PCIExpress(sclk, srstn, pclk, prstn);
  Clock             ava125Clk   = pcie_ep.ava.clk; 
  Reset             ava125Rst   = pcie_ep.ava.usr_rst;

  Wire#(Bool)       avaTxSop    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxEop    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxEmpty  <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxValid  <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);
  Wire#(Bool)       avaTxErr    <- mkDWire(False, clocked_by ava125Clk, reset_by ava125Rst);

  // Avalon-ST RX qword-allignment bubble removal
  FIFOLevelIfc#(TLPDataA#(16), 3) rxInF       <- mkFIFOLevel( clocked_by ava125Clk, reset_by ava125Rst);  // Pusposefully depth-3 for Avalon variable latency flow control
  FIFOF#(TLPHeadInfo)             rxHeadF     <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  DwordShifter#(4,4,8)            rxDws       <- mkDwordShifter ( clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(UInt#(3))                rxEofF      <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  FIFOF#(TLPData#(16))            rxOutF      <- mkFIFOF    ( clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(UInt#(3))                  rxPushAccu  <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                      rxInFlight  <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);

  // Avalon-ST TX qword-allignment bubble insertion
  FIFOF#(TLPData#(16))         txInF          <- mkFIFOF(     clocked_by ava125Clk, reset_by ava125Rst); 
  FIFOF#(TLPData#(16))         txStageF       <- mkFIFOF1(    clocked_by ava125Clk, reset_by ava125Rst); 
  Reg#(Bit#(2))                txSerPos       <- mkReg(0,     clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                   txHeadPushed   <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);
  Reg#(Bool)                   txSeqGuard     <- mkReg(False, clocked_by ava125Clk, reset_by ava125Rst);

  Reg#(PciId)                  deviceReg      <- mkReg(?,     clocked_by ava125Clk, reset_by ava125Rst);

  // Configuration capture logic...
  rule capture_deviceid (pcie_ep.cfg.addr == 4'hF); // capture cfg_busdev
    deviceReg <= PciId { bus:pcie_ep.cfg.data[12:5], dev:pcie_ep.cfg.data[4:0], func:0 } ;
  endrule

  // Downstream Avalon-ST to TRN

  rule connect_ava_rx_mask;
    pcie_ep.ava_rx.mask(False); // No non-posted back pressure. 26 more NP requests may come after this is asserted (128b Avalon-ST)
  endrule

  rule connect_ava_rx_rdy;
    //pcie_ep.ava_rx.rdy(rxInF.isLessThan(2)); // 1 element in rxInF means at least 2 more may follow after Avalon-Ready is de-asserted
    pcie_ep.ava_rx.rdy(True); // FIXME
  endrule

  rule rx_instage (pcie_ep.ava_rx.valid);  // instage brings guarded FIFO semantics to Avalon-ST (removes variable read latency)
    Bit#(8) bar = 0;
    if(pcie_ep.ava_rx.sop) begin  // Avalon bardec only valid on SOP
      TLPPacketType pktType = unpack(pcie_ep.ava_rx.data[28:24]);
      bar = (pktType==MEMORY_READ_WRITE) ? pcie_ep.ava_rx.bar : 0; // zero out Bar for non-memory requests
    end
    rxInF.enq(TLPDataA {  
      empty: pcie_ep.ava_rx.empty,
      sof:   pcie_ep.ava_rx.sop,
      eof:   pcie_ep.ava_rx.eop,
      hit:   bar,
      be:    pcie_ep.ava_rx.be,
      data:  pcie_ep.ava_rx.data });

  endrule

  // When RX packets are available in rxInF, we consume then and then enstage enq into HeadF, Dws, and Eof...

  // These rx_enstage operations are about removing the Avalon Spexcificiity and making PCIe generic...
  rule rx_enstage (rxDws.space_available >= 4);  // enstage is only ready when 4 or more locations are open in rxDws (the max we may need)
    let prx = rxInF.first; rxInF.deq();

    // bit 2 of the request address at Header Byte 11 - bubble when alligned (and a MEM_WRITE); If we are a read request, we are not a bubble...
    Bool rxBubble = prx.sof && !unpack(prx.data[66]) && unpack(prx.data[30]); 

    TLPPacketFormat tpf = unpack(prx.data[30:29]);
    TLPLength       len = unpack(prx.data[9:0]);
    if (prx.sof) begin
      rxHeadF.enq(TLPHeadInfo {hit:prx.hit, length:len, pfmt:tpf});
    end

    // Now supply the rxDws with the goods...
    Vector#(4, Bit#(32)) vdw = unpack(prx.data);
    if (prx.sof && !rxBubble && tpf==MEM_WRITE_3DW_DATA) begin
      vdw[3] = reverseBYTES(vdw[3]);   // Only muck with the data (non-header) in the first word
    end 
    if (!prx.sof) begin
      vdw[3] = reverseBYTES(vdw[3]);   // Only muck with the data in the payload
      vdw[2] = reverseBYTES(vdw[2]);
      vdw[1] = reverseBYTES(vdw[1]);
      vdw[0] = reverseBYTES(vdw[0]);
    end 
    vdw = unpack(reverseDWORDS(pack(vdw)));    // Make Big endian for TRN
    UInt#(3)                                                   enqCount = 0;
    if      ( prx.sof && tpf==MEM_READ_3DW_NO_DATA)            enqCount = 3;
    else if ( prx.sof && tpf==MEM_READ_4DW_NO_DATA)            enqCount = 4;
    else if ( prx.sof && tpf==MEM_WRITE_3DW_DATA && !rxBubble) enqCount = 4;
    else if ( prx.sof && tpf==MEM_WRITE_3DW_DATA &&  rxBubble) enqCount = 3;
    else if (!prx.sof && !prx.eof)                             enqCount = 4;
    else if (             prx.eof &&  prx.empty)               enqCount = 2;
    else if (             prx.eof && !prx.empty)               enqCount = 4;
    else                                                       enqCount = 0;
    rxDws.enq(enqCount, vdw);
    UInt#(3) rxNxtAccu = rxPushAccu + enqCount; // keep track of how many DW pused so we can calculate remainder
    rxPushAccu <= rxNxtAccu;

    if (prx.eof) begin
      rxEofF.enq(rxNxtAccu); // signal that the message is over and what we pushed to make it complete
    end

    // Note we have not used tge BE supplied from the Avalon RX core

  endrule

  // These rx_destage operations are about making PCIe generic specific to the TRN uNoC format...
  rule rx_destage;
    let rxh = rxHeadF.first;

    Bool sof = !rxInFlight;
    Bool eof = rxEofF.notEmpty;

    Vector#(4, Bit#(32)) vdw = rxDws.dwords_out;
    // Calculate deq amount

    rxOutF.enq(TLPData { 
      sof:  sof,
      eof:  eof,
      hit:  truncate(rxh.hit),
      be:   reverseBits('1),
      data: pack(vdw) });

      if (eof) begin
        rxHeadF.deq;
        rxEofF.deq;
      end
      rxInFlight <= !eof;

  endrule


  // Upstream TRN to Avalon-ST...

  rule tx_enstage (pcie_ep.ava_tx.tready && !txStageF.notEmpty && !txSeqGuard);
    let tx = txInF.first;
    TLPCompletionHeader txAsCompl = unpack(tx.data);
    //Bool txBubble = tx.sof && !unpack(tx.data[66]); // bit 2 of the lower address at Header Byte 11 - bubble when alligned
    Bool txBubble = tx.sof && txAsCompl.loweraddr[2]==0;

    if (!txBubble) txInF.deq;
    else txSeqGuard <= True;

    Bit#(16)  be   = ?;
    Bit#(128) data = ?;

    be   = reverseBits(tx.be);
    data = reverseDWORDS(tx.data);

    Vector#(4, Bit#(32)) vdw = unpack(data);

    if (!txBubble) begin
      vdw[3] = reverseBYTES(vdw[3]);   // Only muck with the data (non-header)
    end else begin
      txStageF.enq(tx);
    end

    avaTxValid  <=  True;
    avaTxSop    <=  tx.sof;
    avaTxEop    <= (tx.eof && !txBubble);
    avaTxEmpty  <=  False;

    //pcie_ep.ava_tx.empty(False); //FIXME: Assert when TLP ends in lower 64b of 128b
    //pcie_ep.ava_tx.tstrb(be);

    pcie_ep.ava_tx.data(pack(vdw));

    if (tx.eof && !txBubble) begin
      txSerPos <= 0;
      txHeadPushed <= False;
    end
  endrule

  //TODO: Bubble insertion on TX

  rule tx_destage (pcie_ep.ava_tx.tready && txStageF.notEmpty && txSeqGuard);
    let tx = txInF.first; txInF.deq;
    let ts = txStageF.first; txStageF.deq;
    Bit#(16)  be   = ?;
    Bit#(128) data = ?;
    //be   = {reverseBits(tx.be)[15:4],       reverseBits(ts.be)[3:0]};
    //data = {reverseDWORDS(tx.data)[127:32], reverseDWORDS(ts.data)[31:0]};
    be   = {tx.be[15:4],     ts.be[3:0]};
    //data = {tx.data[127:32], ts.data[31:0]};

    // This is always data, so reverse Bytes...
    Vector#(4, Bit#(32)) vdw = unpack({tx.data[127:32], ts.data[31:0]});
      vdw[0] = reverseBYTES(vdw[0]);
      vdw[1] = reverseBYTES(vdw[1]);
      vdw[2] = reverseBYTES(vdw[2]);
      vdw[3] = reverseBYTES(vdw[3]);
      data = pack(vdw);

    avaTxValid  <=  True;
    avaTxSop    <=  False;
    avaTxEop    <=  True;
    avaTxEmpty  <=  True;

    //pcie_ep.ava_tx.empty(True); //FIXME: Assert when TLP ends in lower 64b of 128b
    //pcie_ep.ava_tx.tstrb(be);
    pcie_ep.ava_tx.data(data);

    if (tx.eof) begin
      txSerPos <= 0;
      txHeadPushed <= False;
    end

    txSeqGuard <= False;
  endrule

  (* no_implicit_conditions, fire_when_enabled *)
  rule connect_ava_tx;
    pcie_ep.ava_tx.sop(avaTxSop);
    pcie_ep.ava_tx.eop(avaTxEop);
    pcie_ep.ava_tx.empty(avaTxEmpty);
    pcie_ep.ava_tx.valid(avaTxValid);
    pcie_ep.ava_tx.err(avaTxErr);
  endrule


  interface pcie = pcie_ep.pcie;

  interface PCIE_AVALONST ava;
    interface Clock    clk     = pcie_ep.ava.clk;
    interface Reset    usr_rst = pcie_ep.ava.usr_rst;
    method    Bool     alive   = pcie_ep.ava.alive;
    method    Bool     lnk_up  = pcie_ep.ava.lnk_up;
    method    Bit#(32) debug   = pcie_ep.ava.debug;
  endinterface

  interface PCIE_TRN_RECV16 trn_rx;  // downstream...
     method ActionValue#(TLPData#(16)) recv() if (rxOutF.notEmpty);
        let rxo = rxOutF.first;
        rxOutF.deq;
        TLPData#(16) retval = defaultValue;
        retval.sof  = rxo.sof;
        retval.eof  = rxo.eof;
        retval.hit  = rxo.hit;
        retval.be   = rxo.be;
        retval.data = rxo.data;
        return retval;
     endmethod
  endinterface

  interface PCIE_TRN_XMIT16 trn_tx; // upstream
    method Action xmit(discontinue, data) if (txInF.notFull);
      txInF.enq(data);
    endmethod
  endinterface

  method PciId device = deviceReg;

endmodule: mkPCIExpressEndpointS4GX



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


endpackage: PCIE
