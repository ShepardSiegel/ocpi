// DAC32823.bsv - Interface to the TI DAC3283 DAC
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED
// Implement specific TI DAC3283 DAC Operations

package DAC3283;

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

(*always_ready*)  // The DAC-facing FPGA pads...
interface DAC3283_PADS;
  method Bit#(1)  txena;
  method Bit#(1)  dclkp;
  method Bit#(1)  dclkn;
  method Bit#(1)  framep;
  method Bit#(1)  framen;
  method Bit#(8)  dap;
  method Bit#(8)  dan;
endinterface 

interface DAC3283Ifc;

  /*
  method Bit#(32)      underflowCnt;
  method Bit#(32)      dacSampleDeq;
  method Action        emitEn;
  method Action        toneEn;
  interface SyncFIFOSrcIfc#(DacSWord) smpF;
  method Action        dacCtrl (Bit#(4) arg);
  method Action        doInitSeq;   // do chip init
  method Bool          isInited;    // chip is init-ed
  method Bool          dcmLocked;   // SDR DCM is Locked
  */

  interface DAC3283_PADS pads; 
endinterface: DAC3283Ifc

module mkDAC3283#(Clock divClk,     // The OSERDES input clock = sample clock (typ 122.88 MHz)
                  Clock dataClk)    // The OSERDES output clock (typ 245.75 MHz, 491.52 MT/S)
                 (DAC3283Ifc);

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
  PulseWire               toneEn_pw     <-  mkPulseWire;
  SyncBitIfc#(Bit#(1))    toneEn_d      <-  mkSyncBitFromCC(sdrClk);
  Reg#(Bool)              tone          <-  mkReg(False,   clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(32))          undCount      <-  mkReg(0,clocked_by sdrClk, reset_by sdrRst);
  Reg#(Bit#(32))          undCountCC    <-  mkSyncRegToCC(0, sdrClk, sdrRst);

  rule emit_to_sdr;      emitEn_d.send(pack(emitEn_pw));             endrule  // CC  domain connect
  rule sdr_emit_adv;     emit<=unpack(emitEn_d.read); emitD <= emit; endrule  // SDR domain connect
  rule update_emitcnt;   emitCntCC._write(emitCnt);                  endrule
  rule update_undcount;  undCountCC._write(undCount);                endrule

  rule tone_to_sdr;      toneEn_d.send(pack(toneEn_pw)); endrule  // CC  domain connect
  rule sdr_tone_adv;     tone<=unpack(toneEn_d.read);    endrule  // SDR domain connect

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

  (* fire_when_enabled *)
  rule emit_word (emit);
    if (sampF.notEmpty) begin       // Samples available...
      ddrSDrv.sdrData(sampF.first);   // Push to DAC
      sampF.deq;                      // DEQ
      emitCnt  <= emitCnt + 1;        // Bump emission count
    end else begin                  // No Samples available...
      ddrSDrv.sdrData(obZero);        // Drive out zero when we underflow
      undCount <= undCount + 1;       // Bump the undeflow counter
    end
  endrule

  (* fire_when_enabled *)
  rule ramp_word (!emit);
    ddrSDrv.sdrData(tone?ob16p:obZero); // push superword of 16 DAC samples
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
  method Action toneEn = toneEn_pw.send;
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

    method  Bit#(1)  dacCal    = pack(calBit);
    method  Bit#(1)  syncOutp  = syncOut_obuf.read_pos;
    method  Bit#(1)  syncOutn  = syncOut_obuf.read_neg;
    method  Bit#(1)  syncMutep = syncMute_obuf.read_pos;
    method  Bit#(1)  syncMuten = syncMute_obuf.read_neg;
    interface  Clock dacSdrClk = sdrClk;
    interface  Reset dacSdrRst = sdrRst;
  endinterface
endmodule

endpackage
