// MDIO.bsv - Managment Data Input/Output - see IEEE RFC802.3
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package MDIO;

import BUtils       ::*;
import Counter      ::*;
import FIFO         ::*;
import FIFOF        ::*;
import TriState     ::*;
import Vector       ::*;

export MDIO_Pads(..);
export MDIO_User(..);
export MDIORequest(..);
export MDIOResponse(..);
export MDIO(..);
export mkMDIO;

typedef enum {
  Address   = 0,  // Clause 45
  Write     = 1,  // Clause 22
  ReadAddr  = 2,  // Clause 45
  Read      = 3   // Clause 22
} MDIOOpCode deriving (Bits, Eq);

typedef struct {
  Bool         isWrite;
  Bit#(5)      phyAddr;
  Bit#(5)      regAddr;
  Bit#(16)     data;
} MDIORequest deriving (Bits, Eq);	

typedef struct {
  Bool        isGood;
  Bit#(16)    data;
} MDIOResponse deriving (Bits, Eq);	

typedef enum {
  Idle,
  Running
} State deriving (Bits, Eq);


(* always_enabled, always_ready *)
interface MDIO_Pads;
  (* prefix = "mdd" *)
  interface Inout#(Bit#(1)) mdd;
  (* prefix = "mdc" *)
  interface Inout#(Bit#(1)) mdc;
endinterface

interface MDIO_User;
  method  Action                     request(MDIORequest req);
  method  ActionValue#(MDIOResponse) response();
endinterface

interface MDIO;
   (* prefix = "" *)
   interface MDIO_Pads  mdio;
   (* prefix = "" *)
   interface MDIO_User  user;
endinterface

module mkMDIO#(Integer prescale)(MDIO);
//module mkMDIO (MDIO);

 // Integer prescale = 6; // 125/7 = 17.8MHz,  ~56nS/pwTick
   
  FIFOF#(MDIORequest)             fRequest            <- mkFIFOF;
  FIFO#(MDIOResponse)             fResponse           <- mkFIFO;
   
  Reg#(Bit#(1))                   rMDC                <- mkReg(0);  // Keep at zero except when clocking MDD to avoid confusing preamble logic
  Reg#(Bit#(1))                   rMDD                <- mkReg(1);
  Reg#(Bool)                      rOutEn              <- mkReg(True);
  TriState#(Bit#(1))              tMDC                <- mkTriState(True, rMDC);
  TriState#(Bit#(1))              tMDD                <- mkTriState(rOutEn, rMDD);

  Counter#(4)                     rPrescaler          <- mkCounter(fromInteger(prescale));
  PulseWire                       pwTick              <- mkPulseWire;
  Counter#(8)                     rPlayIndex          <- mkCounter(0);
   
  Reg#(State)                     rState              <- mkReg(Idle);
  Reg#(Bool)                      rWrite              <- mkRegU;
  Reg#(Bit#(5))                   rPhyAddr            <- mkRegU;
  Reg#(Bit#(5))                   rRegAddr            <- mkRegU;
  Reg#(Bit#(16))                  rWriteData          <- mkRegU;
  Vector#(16, Reg#(Bit#(1)))      vrReadData          <- replicateM(mkRegU);
   
  Bit#(5)                         padr                = rPhyAddr;
  Bit#(3)                         pa4                 = duplicate(padr[4]);
  Bit#(3)                         pa3                 = duplicate(padr[3]);
  Bit#(3)                         pa2                 = duplicate(padr[2]);
  Bit#(3)                         pa1                 = duplicate(padr[1]);
  Bit#(3)                         pa0                 = duplicate(padr[0]);
   
  Bit#(5)                         radr                = rRegAddr;
  Bit#(3)                         ra4                 = duplicate(radr[4]);
  Bit#(3)                         ra3                 = duplicate(radr[3]);
  Bit#(3)                         ra2                 = duplicate(radr[2]);
  Bit#(3)                         ra1                 = duplicate(radr[1]);
  Bit#(3)                         ra0                 = duplicate(radr[0]);
   
  Bit#(16)                        dat                  = rWriteData;
  Bit#(3)                         d15                  = duplicate(dat[15]);
  Bit#(3)                         d14                  = duplicate(dat[14]);
  Bit#(3)                         d13                  = duplicate(dat[13]);
  Bit#(3)                         d12                  = duplicate(dat[12]);
  Bit#(3)                         d11                  = duplicate(dat[11]);
  Bit#(3)                         d10                  = duplicate(dat[10]);
  Bit#(3)                         d9                   = duplicate(dat[9]);
  Bit#(3)                         d8                   = duplicate(dat[8]);
  Bit#(3)                         d7                   = duplicate(dat[7]);
  Bit#(3)                         d6                   = duplicate(dat[6]);
  Bit#(3)                         d5                   = duplicate(dat[5]);
  Bit#(3)                         d4                   = duplicate(dat[4]);
  Bit#(3)                         d3                   = duplicate(dat[3]);
  Bit#(3)                         d2                   = duplicate(dat[2]);
  Bit#(3)                         d1                   = duplicate(dat[1]);
  Bit#(3)                         d0                   = duplicate(dat[0]);
   
  Integer                         seqLength            = 195;  // 65 (32+32+1) * 3
  // First line of each is 32b preamble, the 32b command, then 1b idle...
  //                 st[1]   st[0]   op[1]   op[0]   phy[4]  phy[3]  phy[2]  phy[1]  phy[0]  reg[4]  reg[3]  reg[2]  reg[1]  reg[0]  ta[1]   ta[0]   dat[15] dat[14] dat[13] dat[12] dat[11] dat[10] dat[9]  dat[8]  dat[7]  dat[6]  dat[5]  dat[4]  dat[3]  dat[2]  dat[1]  dat[0]  idle
  let wXXClock  = { 3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010,3'b010, 
                    3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010 };
  let wWrData   = { 3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,
                    3'b000, 3'b111, 3'b000, 3'b111, pa4,    pa3,    pa2,    pa1,    pa0,    ra4,    ra3,    ra2,    ra1,    ra0,    3'b111, 3'b000, d15,    d14,    d13,    d12,    d11,    d10,    d9,     d8,     d7,     d6,     d5,     d4,     d3,     d2,     d1,     d0    , 3'b111 };
  let wRdData   = { 3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,
                    3'b000, 3'b111, 3'b111, 3'b000, pa4,    pa3,    pa2,    pa1,    pa0,    ra4,    ra3,    ra2,    ra1,    ra0,    3'b111, 3'b000, d15,    d14,    d13,    d12,    d11,    d10,    d9,     d8,     d7,     d6,     d5,     d4,     d3,     d2,     d1,     d0    , 3'b111 };
  let wWrOutEn  = { 3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,
                    3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000 };
  let wRdOutEn  = { 3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,3'b111,
                    3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000 };
  let wRdSample = { 3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,3'b000,
                    3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b000 };

  (* fire_when_enabled, no_implicit_conditions *)
  rule update_prescaler(rPrescaler.value > 0);
    rPrescaler.down;
  endrule

  (* fire_when_enabled, no_implicit_conditions *)
  rule reset_prescaler(rPrescaler.value == 0);
    rPrescaler.setF(fromInteger(prescale));
    pwTick.send;
  endrule
   
  rule start(rState == Idle);
    let request = fRequest.first; fRequest.deq;
    rPhyAddr   <= request.phyAddr;
    rRegAddr   <= request.regAddr;
    rWriteData <= request.data;
    rWrite     <= request.isWrite;
    rState     <= Running;
    rPlayIndex.setF(fromInteger(seqLength-1));
  endrule
   
  rule run_frame(rState==Running && pwTick);
    rPlayIndex.down;
    rMDC       <= wXXClock[rPlayIndex.value];
    rMDD       <= ((rWrite) ? wWrData  : wRdData)  [rPlayIndex.value];
    rOutEn     <= ((rWrite) ? wWrOutEn : wRdOutEn) [rPlayIndex.value] == 1;
    if (rPlayIndex.value > 0) begin
      if (!rWrite && wRdSample[rPlayIndex.value]==1) writeVReg(vrReadData, shiftInAt0(readVReg(vrReadData), tMDD));
    end else begin
      rState   <= Idle;
      if(!rWrite) fResponse.enq(MDIOResponse {isGood:True, data:pack(readVReg(vrReadData))});
    end
  endrule

  interface MDIO_Pads mdio;
    interface mdd    = tMDD.io;
    interface mdc    = tMDC.io;
  endinterface
   
  interface MDIO_User user;
    method  Action request(MDIORequest req);
	    fRequest.enq(req);
    endmethod

    method ActionValue#(MDIOResponse) response();
	    fResponse.deq;
	    return fResponse.first;
    endmethod
  endinterface
endmodule

endpackage: MDIO
