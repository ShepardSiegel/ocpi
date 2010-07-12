// Max19692.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED
// Implement specific Maxim MAX19692 DAC Operations

import DDRSlaveDrive::*;

import BRAMFIFO::*;
import Connectable::*;
import Clocks::*;
import DefaultValue::*;
import StmtFSM::*;
import Vector::*;
import XilinxExtra::*;

// Src-Side methods...
interface SyncFIFOSrcIfc #(type a_type) ;
  method Action enq ( a_type sendData ) ;
  method Bool notFull () ;
endinterface

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
  interface Clock dacSdrClk;
  interface Reset dacSdrRst;
endinterface 

// The interface declaration of the DAC methods + the chip-level interface...
interface Max19692Ifc;
  method Bit#(32)      underflowCnt;
  method Bit#(32)      dacSampleDeq;
  method Action        emitEn;
  interface SyncFIFOSrcIfc#(DacSWord) smpF;
  //method Bool          dacUnderflow;    // Add me to allow FIFO precharge

  method Action        dacCtrl (Bit#(4) arg);
  method Action        doInitSeq;   // do chip init
  method Bool          isInited;    // chip is init-ed
  method Bool          dcmLocked;   // SDR DCM is Locked
  method Bool          isTrue;
  method Bool          isFalse;
  interface P_Max19692Ifc dac;      // the DAC chip pins
endinterface: Max19692Ifc

module mkMax19692#(Clock dac_clk) (Max19692Ifc);

  DDRSlaveDriveIfc        ddrSDrv       <-  mkDDRSlaveDrive(dac_clk);
  Clock                   sdrClk        =   ddrSDrv.sdrClk;
  Reset                   sdrRst        <-  mkAsyncResetFromCR(1,sdrClk);
  Reg#(Bit#(8))           dacCount      <-  mkRegU(        clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              calBit        <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              muteDAC       <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              syncOut       <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bool)              syncMute      <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst);
  DiffOutIfc#(Bit#(1))    syncOut_obuf  <-  mkOBUFDS(      clocked_by sdrClk, reset_by sdrRst);
  DiffOutIfc#(Bit#(1))    syncMute_obuf <-  mkOBUFDS(      clocked_by sdrClk, reset_by sdrRst);
  SyncBitIfc#(Bit#(1))    dcmLck_cc     <-  mkSyncBitToCC(sdrClk,sdrRst);
  SyncFIFOIfc#(DacSWord)  sampF         <-  mkSyncBRAMFIFOFromCC(512, sdrClk, sdrRst);
  Reg#(Bit#(4))           dacCtrl_w     <-  mkReg(4'h8);
  ReadOnly#(Bit#(4))      dacCtrl_s     <-  mkNullCrossingWire(sdrClk, dacCtrl_w);
  PulseWire               emitEn_pw     <-  mkPulseWire;                                        // EmitEn Method Enabled
  SyncBitIfc#(Bit#(1))    emitEn_d      <-  mkSyncBitFromCC(sdrClk);                            // EmitEn in sdrClk domain
  Reg#(Bool)              emit          <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst); // emit  flop   
  Reg#(Bool)              emitD         <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst); // emitD flop
  Reg#(Bit#(32))          emitCnt       <-  mkReg(0,       clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(32))          emitCntCC     <-  mkSyncRegToCC(0, sdrClk, sdrRst);
  Reg#(Bit#(32))          undCount      <-  mkReg(0,clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(32))          undCountCC    <-  mkSyncRegToCC(0, sdrClk, sdrRst);

  rule emit_to_sdr;      emitEn_d.send(pack(emitEn_pw));             endrule  // CC  domain connect
  rule sdr_emit_adv;     emit<=unpack(emitEn_d.read); emitD <= emit; endrule  // SDR domain connect
  rule update_emitcnt;   emitCntCC._write(emitCnt);                  endrule
  rule update_undcount;  undCountCC._write(undCount);                endrule

  rule und_count (emit && !sampF.notEmpty);
    ddrSDrv.sdrData(obZero);   // Drive out zero when we underflow
    undCount <= undCount + 1;  // Bump the undeflow counter
  endrule

  // Max19692 Initialization/Calibration sequence... (see Pp14 MAX19692 datasheet)
  Stmt iseq = seq
    muteDAC <= True;          // Mute the data to the DAC OSERDES (DAC inputs not switching)
    calBit  <= False;         // De-Assert the Calibration Bit
    await(ddrSDrv.dcmLocked); // DCM should be locked, Voltages Stable
    calBit  <= True;          // Assert the Calibration Bit
    delay(65536/16);          // Wait for 65,536 DAC clock cycles
    muteDAC <= False;         // Un-Mute (Enable) the data to the DAC OSERDES
  endseq;
  FSM iseqFsm <- mkFSM(iseq, clocked_by sdrClk, reset_by sdrRst);

  // Init handshaking the from the CC to SDR and back to CC domain...
  SyncFIFOIfc#(Bit#(1))  startIseqF  <- mkSyncFIFOFromCC(2, sdrClk);

  rule start_cal_seq (False);  // Disable Cal Seq
    startIseqF.deq();
    iseqFsm.start;
  endrule

  SyncBitIfc#(Bit#(1)) iSeqDone <- mkSyncBitToCC(sdrClk,sdrRst);
  rule donebit_to_cc; iSeqDone.send(pack(iseqFsm.done)); endrule

  rule dcmLck_to_cc;  dcmLck_cc.send(pack(ddrSDrv.dcmLocked)); endrule

  (* fire_when_enabled *)
  rule dac_count;
    dacCount <= dacCount + 1;
    syncOut <= (dacCount=='0);
  endrule


  rule emit_word (emit);
    ddrSDrv.sdrData(sampF.first);
    sampF.deq;
    emitCnt <= emitCnt + 1;
  endrule

  rule ramp_word (!emit);
   // DacSWord dSW = ?;
   // for (Integer i=0; i<16; i=i+1) dSW[i] = muteDAC ? 0 : {dacCount,fromInteger(i)};
    ddrSDrv.sdrData(obZero); // push superword of 16 DAC samples
  endrule

  (* fire_when_enabled *) rule synOut; syncOut_obuf  <= pack(syncOut);  endrule
  (* fire_when_enabled *) rule synMut; syncMute_obuf <= pack(syncMute); endrule

  // Interfaces Provided...
  interface SyncFIFOSrcIfc smpF; 
    method Action  enq (DacSWord sendData) = sampF.enq(sendData);
    method Bool notFull = sampF.notFull;
  endinterface
  method Bit#(32) underflowCnt = undCountCC;
  method Bit#(32) dacSampleDeq = emitCntCC;
  method Action emitEn = emitEn_pw.send;
  method Action dacCtrl (Bit#(4) arg)  = dacCtrl_w._write(arg);
  method Action doInitSeq       = startIseqF.enq(1'b0);
  method Bool   isInited        = unpack(iSeqDone.read);
  method Bool   dcmLocked       = unpack(dcmLck_cc.read);
  method Bool   isTrue  = True;
  method Bool   isFalse = False;
  interface P_Max19692Ifc dac;
    method  Bit#(12) dap = ddrSDrv.dap;
    method  Bit#(12) dan = ddrSDrv.dan; 
    method  Bit#(12) dbp = ddrSDrv.dbp; 
    method  Bit#(12) dbn = ddrSDrv.dbn; 
    method  Bit#(12) dcp = ddrSDrv.dcp; 
    method  Bit#(12) dcn = ddrSDrv.dcn; 
    method  Bit#(12) ddp = ddrSDrv.ddp; 
    method  Bit#(12) ddn = ddrSDrv.ddn; 

    method  Bit#(1)  dacClkDiv = dacCtrl_s[3]; // 1=DDR(fdac/8) 0=QDR(fdac16)
    method  Bit#(1)  dacDelay  = dacCtrl_s[2]; // 0=No Delay 1=2 cycle slip
    method  Bit#(1)  dacRz     = dacCtrl_s[1]; // RzRf 00=NRZ, 10=RZ, 01=RF, 11=Rsvd
    method  Bit#(1)  dacRf     = dacCtrl_s[0]; // See Table 1 and Figure 5 in datasheet

      /*
    method  Bit#(1)  dacClkDiv = 1'b1; // 1=DDR(fdac/8) 0=QDR(fdac16)
    method  Bit#(1)  dacDelay  = 1'b0; // 0=No Delay 1=2 cycle slip
    method  Bit#(1)  dacRz     = 1'b0; // RzRf 00=NRZ, 10=RZ, 01=RF, 11=Rsvd
    method  Bit#(1)  dacRf     = 1'b0; // See Table 1 and Figure 5 in datasheet
      */

    method  Bit#(1)  dacCal    = pack(calBit);
    method  Bit#(1)  syncOutp  = syncOut_obuf.read_pos;
    method  Bit#(1)  syncOutn  = syncOut_obuf.read_neg;
    method  Bit#(1)  syncMutep = syncMute_obuf.read_pos;
    method  Bit#(1)  syncMuten = syncMute_obuf.read_neg;
    interface  Clock dacSdrClk = sdrClk;
    interface  Reset dacSdrRst = sdrRst;
  endinterface
endmodule
