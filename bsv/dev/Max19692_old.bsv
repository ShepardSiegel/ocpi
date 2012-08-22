// Max19692_old.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED
// Deprectated version that composed DCM and ODDR from BSV Cells
// Use of newer OSERDES-based module suggested

import XilinxCells::*;
import XilinxExtra::*;
import Vector::*;
import Clocks::*;
import DefaultValue::*;
import Connectable::*;

// The interface declaration of the device-package-pins for the Maxim MAX19692
interface P_Max19692Ifc;
  (*always_ready*) method  Bit#(12)  dap;
  (*always_ready*) method  Bit#(12)  dan;
  (*always_ready*) method  Bit#(12)  dbp;
  (*always_ready*) method  Bit#(12)  dbn;
  (*always_ready*) method  Bit#(12)  dcp;
  (*always_ready*) method  Bit#(12)  dcn;
  (*always_ready*) method  Bit#(12)  ddp;
  (*always_ready*) method  Bit#(12)  ddn;
  (*always_ready*) method  Bit#(1)   dacClkDiv;
  (*always_ready*) method  Bit#(1)   dacDelay;
  (*always_ready*) method  Bit#(1)   dacRf;
  (*always_ready*) method  Bit#(1)   dacRz;
  (*always_ready*) method  Bit#(1)   dacCal;
  (*always_ready*) method  Bit#(1)   syncOutp;
  (*always_ready*) method  Bit#(1)   syncOutn;
  (*always_ready*) method  Bit#(1)   syncMutep;
  (*always_ready*) method  Bit#(1)   syncMuten;
endinterface 

// The interface declaration of the DAC methods + the chip-level interface...
interface Max19692Ifc;
  method Action        doInitSeq;   // do chip init
  method Bool          isInited;    // chip is init-ed
  interface P_Max19692Ifc dac;       // the ADC chip pins
endinterface: Max19692Ifc

(* default_clock_osc="dac_clk"*) //could rename reset here
module mkMax19692#(Clock dac_clk) (Max19692Ifc);

  ClockGenIfc     dcm_bufg    <- mkDCM_BUFG();
  Clock           wordClock   = dcm_bufg.gen_clk;
  Reg#(Bit#(9))   dacCount    <- mkRegU(clocked_by wordClock);
  Reg#(Bit#(20))  calCount    <- mkReg(0, clocked_by wordClock);
  Reg#(Bool)      calBit      <- mkReg(False, clocked_by wordClock);
  Reg#(Bool)      dataOK      <- mkReg(False, clocked_by wordClock);

  ODDRParams#(Bit#(12)) odrP = defaultValue; odrP.ddr_clk_edge="SAME_EDGE";

  Vector#(4, ODDR#(Bit#(12)))       oddr <- replicateM(mkODDR(odrP, clocked_by wordClock));
  Vector#(4, DiffOutIfc#(Bit#(12))) obuf <- replicateM(mkOBUFDS(clocked_by wordClock));

  Reg#(Bool)           syncOut       <- mkRegU(clocked_by wordClock);
  Reg#(Bool)           syncMute      <- mkReg(False, clocked_by wordClock);
  DiffOutIfc#(Bit#(1)) syncOut_obuf  <- mkOBUFDS(clocked_by wordClock);
  DiffOutIfc#(Bit#(1)) syncMute_obuf <- mkOBUFDS(clocked_by wordClock);

  rule dac_count;
    dacCount <= dacCount + 1;
    syncOut <= (dacCount=='0);
  endrule

  rule cal_count; 
    if (calCount < 20'hFFFFF) calCount <= calCount + 1;
    if (calCount > 20'h80000) calBit <= True;
    if (calCount > 20'hF0000) dataOK <= True;
  endrule

  Vector#(8, Bit#(12)) rCount = ?;
  for (Integer i=0; i<8; i=i+1) rCount[i] = dataOK ? {dacCount,fromInteger(i)} : 0;

  (* fire_when_enabled *)
  rule oddr_input;
    for (Integer i=0; i<4; i=i+1) begin
       oddr[i].d1(rCount[i]);
       oddr[i].d2(rCount[i+4]);
    end
  endrule

  rule oddr_ce;
     for (Integer i=0; i<4; i=i+1) oddr[i].ce(True);
  endrule

  rule oddr_s;
    for (Integer i=0; i<4; i=i+1) oddr[i].s(False);
  endrule

  // Use this one line:
  // let oddr2obuf <- mkConnection(oddr.q, obuf._write);
  // Or this rule:
  (* fire_when_enabled *)
  rule connect_oddr2obuf;
    for (Integer i=0;i<4;i=i+1) obuf[i] <= oddr[i].q;
  endrule

  (* fire_when_enabled *) rule synOut; syncOut_obuf <= pack(syncOut); endrule
  (* fire_when_enabled *) rule synMut; syncMute_obuf <= pack(syncMute); endrule

  method Bool   isInited        = False;
  interface P_Max19692Ifc dac;
    method  Bit#(12) dap = obuf[0].read_pos; 
    method  Bit#(12) dan = obuf[0].read_neg;
    method  Bit#(12) dbp = obuf[1].read_pos;
    method  Bit#(12) dbn = obuf[1].read_neg;
    method  Bit#(12) dcp = obuf[2].read_pos;
    method  Bit#(12) dcn = obuf[2].read_neg;
    method  Bit#(12) ddp = obuf[3].read_pos;
    method  Bit#(12) ddn = obuf[3].read_neg;
    method  Bit#(1)  dacClkDiv = 1'b1;
    method  Bit#(1)  dacDelay  = 1'b0;
    method  Bit#(1)  dacRf     = 1'b0;
    method  Bit#(1)  dacRz     = 1'b0;
    method  Bit#(1)  dacCal    = pack(calBit);
    method  Bit#(1)  syncOutp  = syncOut_obuf.read_pos;
    method  Bit#(1)  syncOutn  = syncOut_obuf.read_neg;
    method  Bit#(1)  syncMutep = syncMute_obuf.read_pos;
    method  Bit#(1)  syncMuten = syncMute_obuf.read_neg;
  endinterface
endmodule
