// DDRSlaveDrive.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package DDRSlaveDrive;

import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;
import Vector::*;

(* always_ready, always_enabled *)
interface VDDRSlaveDriveIfc;
  // Pad-Facing...
  method Bit#(12)    dap();
  method Bit#(12)    dan();
  method Bit#(12)    dbp();
  method Bit#(12)    dbn();
  method Bit#(12)    dcp();
  method Bit#(12)    dcn();
  method Bit#(12)    ddp();
  method Bit#(12)    ddn();
  method Bit#(1)     dcmLocked();
  // Inward-Facing...
  interface Clock  sdrClk;
  method Action sdr0    (Bit#(12) arg);
  method Action sdr1    (Bit#(12) arg);
  method Action sdr2    (Bit#(12) arg);
  method Action sdr3    (Bit#(12) arg);
  method Action sdr4    (Bit#(12) arg);
  method Action sdr5    (Bit#(12) arg);
  method Action sdr6    (Bit#(12) arg);
  method Action sdr7    (Bit#(12) arg);
  method Action sdr8    (Bit#(12) arg);
  method Action sdr9    (Bit#(12) arg);
  method Action sdrA    (Bit#(12) arg);
  method Action sdrB    (Bit#(12) arg);
  method Action sdrC    (Bit#(12) arg);
  method Action sdrD    (Bit#(12) arg);
  method Action sdrE    (Bit#(12) arg);
  method Action sdrF    (Bit#(12) arg);
  //method Action dcmRst  (Bit#(1)  arg);
endinterface

import "BVI" ddrOutput2=
module vMkDDRSlaveDrive#(Clock ddrCk) (VDDRSlaveDriveIfc);

  default_clock  clk();
  default_reset  rst(dcmResetN) <- exposeCurrentReset;

  input_clock    ddrCk   (ddrClk)     = ddrCk;
  output_clock   sdrClk  (sdrClk);

  method dap dap();
  method dan dan();
  method dbp dbp();
  method dbn dbn();
  method dcp dcp();
  method dcn dcn();
  method ddp ddp();
  method ddn ddn();
  method dcmLocked dcmLocked();

  method sdr0 (sdrData0)    enable((*inhigh*)en0)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr1 (sdrData1)    enable((*inhigh*)en1)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr2 (sdrData2)    enable((*inhigh*)en2)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr3 (sdrData3)    enable((*inhigh*)en3)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr4 (sdrData4)    enable((*inhigh*)en4)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr5 (sdrData5)    enable((*inhigh*)en5)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr6 (sdrData6)    enable((*inhigh*)en6)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr7 (sdrData7)    enable((*inhigh*)en7)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr8 (sdrData8)    enable((*inhigh*)en8)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdr9 (sdrData9)    enable((*inhigh*)en9)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrA (sdrDataA)    enable((*inhigh*)enA)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrB (sdrDataB)    enable((*inhigh*)enB)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrC (sdrDataC)    enable((*inhigh*)enC)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrD (sdrDataD)    enable((*inhigh*)enD)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrE (sdrDataE)    enable((*inhigh*)enE)  clocked_by(sdrClk)  reset_by(no_reset);
  method sdrF (sdrDataF)    enable((*inhigh*)enF)  clocked_by(sdrClk)  reset_by(no_reset);
  //method dcmRst (dcmReset)  enable((*inhigh*)en10) clocked_by(sdrClk)  reset_by(no_reset);

  //schedule (sdr0,sdr1,sdr2,sdr3,sdr4,sdr5,sdr6,sdr7,sdr8,sdr9,sdrA,sdrB,sdrC,sdrD,sdrE,sdrF,dap,dan,dbp,dbn,dcp,dcn,ddp,ddn,dcmLocked,dcmRst)
  //CF       (sdr0,sdr1,sdr2,sdr3,sdr4,sdr5,sdr6,sdr7,sdr8,sdr9,sdrA,sdrB,sdrC,sdrD,sdrE,sdrF,dap,dan,dbp,dbn,dcp,dcn,ddp,ddn,dcmLocked,dcmRst);
  schedule (sdr0,sdr1,sdr2,sdr3,sdr4,sdr5,sdr6,sdr7,sdr8,sdr9,sdrA,sdrB,sdrC,sdrD,sdrE,sdrF,dap,dan,dbp,dbn,dcp,dcn,ddp,ddn,dcmLocked)
  CF       (sdr0,sdr1,sdr2,sdr3,sdr4,sdr5,sdr6,sdr7,sdr8,sdr9,sdrA,sdrB,sdrC,sdrD,sdrE,sdrF,dap,dan,dbp,dbn,dcp,dcn,ddp,ddn,dcmLocked);
endmodule

// TODO: 2s comp to be made offset-binary
Bit#(16) cos1[16] = {
  16'h7eb8, // i:   0 phi:0.0000 cosphi:1.0000 
  16'h7513, // i:   1 phi:0.3927 cosphi:0.9239 
  16'h599b, // i:   2 phi:0.7854 cosphi:0.7071 
  16'h307e, // i:   3 phi:1.1781 cosphi:0.3827 
  16'h0000, // i:   4 phi:1.5708 cosphi:-0.0000 
  16'hcf83, // i:   5 phi:1.9635 cosphi:-0.3827 
  16'ha666, // i:   6 phi:2.3562 cosphi:-0.7071 
  16'h8aee, // i:   7 phi:2.7489 cosphi:-0.9239 
  16'h8149, // i:   8 phi:3.1416 cosphi:-1.0000 
  16'h8aee, // i:   9 phi:3.5343 cosphi:-0.9239 
  16'ha666, // i:  10 phi:3.9270 cosphi:-0.7071 
  16'hcf83, // i:  11 phi:4.3197 cosphi:-0.3827 
  16'h0000, // i:  12 phi:4.7124 cosphi:0.0000 
  16'h307e, // i:  13 phi:5.1051 cosphi:0.3827 
  16'h599b, // i:  14 phi:5.4978 cosphi:0.7071 
  16'h7513  // i:  15 phi:5.8905 cosphi:0.9239 
 };

typedef Vector#(16, Bit#(12)) DacSWord; // DAC Superword
DacSWord ob16p =
  reverse(unpack({12'hf3e,12'hd8b,12'hb00,12'h800,12'h500,12'h275,12'h0c2,12'h029,12'h0c2,12'h275,12'h500,12'h800,12'hb00,12'hd8b,12'hf3e,12'hfd7}));

//DacSWord ob16p1 = reverse(cos1);

DacSWord obZero =
  (unpack({12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800,12'h800}));

interface DDRSlaveDriveIfc;
  // Pad-Facing...
  (* always_ready *) method Bit#(12) dap;
  (* always_ready *) method Bit#(12) dan;
  (* always_ready *) method Bit#(12) dbp;
  (* always_ready *) method Bit#(12) dbn;
  (* always_ready *) method Bit#(12) dcp;
  (* always_ready *) method Bit#(12) dcn;
  (* always_ready *) method Bit#(12) ddp;
  (* always_ready *) method Bit#(12) ddn;
  // Inward-Facing...
  method Clock  sdrClk;
  method Bool   dcmLocked;
  method Action sdrData  (DacSWord arg);
  //method Action dcmRst;
endinterface

module mkDDRSlaveDrive#(Clock ddrCk) (DDRSlaveDriveIfc);
  VDDRSlaveDriveIfc    ddrV       <- vMkDDRSlaveDrive(ddrCk);
  ReadOnly#(Bool)      dcmLock    <- mkNullCrossingWire(ddrV.sdrClk, unpack(ddrV.dcmLocked)); // place async dcmLock in sdrClk domain
  ReadOnly#(Bool)      isReset    <- isResetAsserted;

  method dap = ddrV.dap;
  method dan = ddrV.dan;
  method dbp = ddrV.dbp;
  method dbn = ddrV.dbn;
  method dcp = ddrV.dcp;
  method dcn = ddrV.dcn;
  method ddp = ddrV.ddp;
  method ddn = ddrV.ddn;

  method Clock  sdrClk    = ddrV.sdrClk;
  method        dcmLocked = dcmLock;
  method Action sdrData  (DacSWord arg);
    ddrV.sdr0(arg[0]);
    ddrV.sdr1(arg[1]);
    ddrV.sdr2(arg[2]);
    ddrV.sdr3(arg[3]);
    ddrV.sdr4(arg[4]);
    ddrV.sdr5(arg[5]);
    ddrV.sdr6(arg[6]);
    ddrV.sdr7(arg[7]);
    ddrV.sdr8(arg[8]);
    ddrV.sdr9(arg[9]);
    ddrV.sdrA(arg[10]);
    ddrV.sdrB(arg[11]);
    ddrV.sdrC(arg[12]);
    ddrV.sdrD(arg[13]);
    ddrV.sdrE(arg[14]);
    ddrV.sdrF(arg[15]);
  endmethod
  //method Action dcmRst = ddrV.dcmRst(1'b1);
endmodule

endpackage
