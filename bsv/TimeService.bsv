// TimeService.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package TimeService;

import OCWip::*;

import ClientServer::*;
import Clocks::*;
import Connectable::*;
import DefaultValue::*;
import DReg::*;	
import FIFO::*;
import FixedPoint::*;
import GetPut::*;
import Vector::*;
import Real::*;
import StmtFSM::*;
import Synchronizer::*;

// Recreates the Fixedpoint value from int and fractional parts.
function FixedPoint#(isize, fsize) fxptFromIntFrac ( Int#(isize) intpart, UInt#(fsize) fracpart);
   return FixedPoint { i:pack(intpart), f:pack(fracpart) } ;
endfunction

typedef struct {
  Real curFreq;  // Current   Clock Frequency, in Hertz
  Real refFreq;  // Reference Clock Frequency, in Hertz
} TSMParams;

instance DefaultValue#(TSMParams);
  defaultValue =
    TSMParams {
      curFreq: 125e6,  // 125.0 MHz PCIe Current Clock
      refFreq: 200e6   // 200.0 MHz Sys0 Reference Clock
    };
endinstance

typedef FixedPoint#(32,32) GPS64_t;

(* always_ready, always_enabled *) // Interface provided to top-level...
interface GPSIfc;
  method Action   ppsSyncIn (Bool x);   // PPS Sync In
  method Bool     ppsSyncOut;           // PPS Sync Out
endinterface

interface TimeServerIfc;
  method Action    setTime     (GPS64_t sTime);
  method Bit#(32)  getStatus;
  method Action    setControl  (Bit#(32) arg);
  method Bit#(32)  getControl;
  method Bit#(32)  tRefPerPps;
  method GPS64_t   gpsTimeCC;
  method GPS64_t   gpsTime;
  interface GPSIfc gps;
endinterface

// The TimeService TimeServer is instanced once per chip to serve as the chip-local source of time.
// Time here may be set by software (coarse) or hardware gps (fine) and is exposed to one or more Time Clients
// The TimeServer is clocked off a stable (typ 200 MHz +/- 50PPM) sys0 clock so it can freewheel during holdover
// in the absesnve of the GPS PPS signal

typedef enum {TimeServ, PpsIn, LocalXo, Mute} PPSOutMode deriving (Bits, Eq);
typedef struct {
  Bool       disableServo;    // 4
  Bool       disableGPS;      // 3
  Bool       disablePPSIn;    // 2
  PPSOutMode drivePPSOut;     // 1:0
 } TimeControl deriving (Bits, Eq);

module mkTimeServer#(TSMParams tsmp, Clock sys0_clk, Reset sys0_rst) (TimeServerIfc);

  // Sofware Control Interface State...
  Reg#(TimeControl)        rplTimeControl  <- mkReg(unpack(0));
  Reg#(Bool)               ppsLostSticky   <- mkReg(False);
  Reg#(Bool)               gpsInSticky     <- mkReg(False);
  Reg#(Bool)               ppsInSticky     <- mkReg(False);
  Reg#(Bool)               ppsOKCC         <- mkSyncRegToCC(False,  sys0_clk, sys0_rst);
  Reg#(Bool)               ppsLostCC       <- mkSyncRegToCC(False,  sys0_clk, sys0_rst);
  Reg#(Bool)               timeSetSticky   <- mkReg(False);
  Reg#(Bit#(8))            rollingPPSIn    <- mkSyncRegToCC(0,      sys0_clk, sys0_rst);
  Bit#(32) rplTimeStatus = {pack(ppsLostSticky),pack(gpsInSticky),pack(ppsInSticky),pack(timeSetSticky),pack(ppsOKCC),pack(ppsLostCC),18'h0,rollingPPSIn};
  SyncFIFOIfc#(GPS64_t)    setRefF         <- mkSyncFIFOFromCC(2,   sys0_clk);
  Reg#(Bit#(28))           refPerPPS       <- mkSyncRegToCC(0,      sys0_clk, sys0_rst);
  Reg#(GPS64_t)            nowInCC         <- mkSyncRegToCC(0,      sys0_clk, sys0_rst);
  // Sys0 Clock Timebase...
  Reg#(FixedPoint#(2,48))  fracSeconds     <- mkReg(0.0,            clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(FixedPoint#(2,48))  lastSecond      <- mkReg(0.0,            clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(FixedPoint#(2,48))  fracInc         <- mkReg(fromRational(1,round(tsmp.refFreq)), clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(FixedPoint#(2,48))  delSecond       <- mkReg(1.0,            clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(FixedPoint#(2,0))   delSec          <- mkReg(0.0,            clocked_by sys0_clk, reset_by sys0_rst);
  Synchronizer#(Bool)      ppsExtSync      <- mkSynchronizer(False, clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(PPSOutMode)         ppsOutMode      <- mkSyncRegFromCC(TimeServ, sys0_clk);
  Reg#(Bool)               ppsDisablePPS   <- mkSyncRegFromCC(False,    sys0_clk);
  Reg#(Bool)               disableServo    <- mkSyncRegFromCC(False,    sys0_clk);
  Reg#(Bool)               ppsExtSyncD     <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)               ppsExtCapture   <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)               ppsDrive        <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)               ppsOK           <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)               ppsLost         <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bool)               xo2             <- mkReg(False,          clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(8))            ppsEdgeCount    <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(28))           refFromRise     <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(28))           refPerCount     <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(28))           refFreeCount    <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(28))           refFreeSamp     <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(28))           refFreeSpan     <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(Bit#(32))           refSecCount     <- mkReg(0,              clocked_by sys0_clk, reset_by sys0_rst);
  Reg#(GPS64_t)            now             <- mkReg(unpack(0),      clocked_by sys0_clk, reset_by sys0_rst);

  Bool ppsExtRising  = ( ppsExtSync && !ppsExtSyncD);
  Bool ppsExtFalling = (!ppsExtSync &&  ppsExtSyncD);

  rule pps_assign (!ppsDisablePPS); ppsExtSyncD<=ppsExtSync; endrule
  rule ppsEdgeCountInc (ppsExtRising); ppsEdgeCount <= ppsEdgeCount + 1; endrule
  rule ppsEdgeCountIncCC;  rollingPPSIn  <= ppsEdgeCount; endrule
  rule xfr_ppsOutmode;     ppsOutMode    <= rplTimeControl.drivePPSOut;  endrule
  rule xfr_ppsDisablePPS;  ppsDisablePPS <= rplTimeControl.disablePPSIn; endrule
  rule xfr_disableServo;   disableServo  <= rplTimeControl.disableServo; endrule
  rule xfr_ppsOK;          ppsOKCC       <= ppsOK; endrule
  rule xfr_ppsLost;        ppsLostCC     <= ppsLost; endrule
  rule ppsStickySet (ppsOKCC);   ppsInSticky   <= True; endrule
  rule ppsLostSet   (ppsLostCC); ppsLostSticky <= True; endrule
  rule make_xo2; xo2 <= !xo2; endrule  // 100 MHz

  Bool  refPerReset  = ppsOK ? ppsExtRising : (fxptGetInt(delSec) != fxptGetInt(fracSeconds));

  // The refFreeCount is an uncompensated 200 MHz rolling count that has no runtime reset
  // The refFromRise counter is reset by any rising edge on PPS, and is used to detect when the incident PPS is OK
  // The refPerCount  is an uncompensated 200 MHz count off of sys0 clk; reset by the refPerReset condition
  (* fire_when_enabled, no_implicit_conditions *) // Assert that this rule will always fire on every XO cycle
  rule every_xo_cycle;
     refPerCount  <= refPerReset  ? 0 : refPerCount + 1;
     refFromRise  <= ppsExtRising ? 0 : refFromRise + 1;
     refFreeCount <= refFreeCount + 1;

     Bool inWindow = ( (refFromRise>fromInteger(round(tsmp.refFreq*0.999))) &&   // -.1% (1000 PPM)
                       (refFromRise<fromInteger(round(tsmp.refFreq*1.001))) );   // +.1% (1000 PPM)
     Bool pastWindow = (refFromRise>fromInteger(round(tsmp.refFreq*1.001)));     // +.1% (1000 PPM)

     ppsOK   <= ((ppsExtRising && inWindow) || (ppsOK && !ppsLost));        // Set ppsOK if it lies within our window, Hold while not Lost
     ppsLost <= ( ppsOK && ((ppsExtRising && !inWindow) || (pastWindow)));  // Pulse ppsLost if it was OK, but now is not (will clear ppsOK)

     if (ppsExtRising && inWindow) begin            // On every PPS rising edge...
       refFreeSamp <= refFreeCount;                 // Sample the refFreeCount for the next second around
       refFreeSpan <= refFreeCount - refFreeSamp;   // Holds the number of sys0 clocks in 1 pps Span (PPS measure of refFreq)
       lastSecond  <= fracSeconds;                  // Capture "now" to last second for delSecond update
       delSecond   <= fracSeconds - lastSecond;     // The 2.48 measurement of 1 second, according to PPS
       // With each PPS, proportionally correct the fractonal increment by the measured error divided by the number of increments...
       // Positive beta == ref is SLOW wrt PPS ; Negative beta == ref is FAST wrt PPS
       FixedPoint#(2,48) beta = ((1.0-delSecond)>>28); // Kp: (gain) 2^28 ~= 200e6, thus our proportional response is slightly over-damped
       if (ppsOK && !disableServo) fracInc <= fracInc + beta; // Apply the proporional beta compensation to the fracSeconds accumulator
     end

     ppsDrive    <= (refPerCount<fromInteger(round(tsmp.refFreq*0.9)));  // 90% HI, 10% LO
     fracSeconds <= fracSeconds + fracInc;
     delSec      <= fromInt(fxptGetInt(fracSeconds));
  endrule
 
  rule update_refPerPPS (ppsExtRising);
    refPerPPS  <= refFreeSpan; // For rplTimeRefPerPPS visability back in CC domain
  endrule

  rule refSecCounter;
    if (setRefF.notEmpty) begin // Time Set has priority over integer second increment
      refSecCount   <= pack(fxptGetInt(setRefF.first));
      setRefF.deq;
    end else if (refPerReset) refSecCount  <= refSecCount  + 1;
  endrule

  rule updateNow;
     now     <= unpack({refSecCount,pack(fracSeconds)[47:16]});
     nowInCC <= unpack({refSecCount,pack(fracSeconds)[47:16]});
  endrule

  // Interfaces Provided...
  method Action setTime (GPS64_t sTime);
    setRefF.enq(sTime);
    timeSetSticky <= True;
  endmethod
  method Bit#(32) getStatus = rplTimeStatus;
  method Action   setControl (Bit#(32) arg);
    rplTimeControl <= unpack(truncate(arg));
    if (unpack(arg[31])) begin  // clearStickyBits
      ppsLostSticky <= False;
      gpsInSticky   <= False;
      ppsInSticky   <= False;
      timeSetSticky <= False;
    end
  endmethod
  method Bit#(32) getControl = extend(pack(rplTimeControl));
  method tRefPerPps = extend(refPerPPS);

  method GPS64_t  gpsTimeCC = nowInCC;
  method GPS64_t  gpsTime    = now;

  interface GPSIfc gps;
    method ppsSyncIn (Bool x)  = ppsExtSync._write(x); 
    method ppsSyncOut;
      case (ppsOutMode)
        TimeServ : return(ppsDrive);
        PpsIn    : return(ppsExtSync);
        LocalXo  : return(xo2);
        Mute     : return(False);
      endcase
    endmethod
   endinterface

endmodule: mkTimeServer

//---

// The TimeService TimeClient is instanced for each target WTI clock domain one or more times
// The time client transfers the time from the time server to the target clock domain and compensates for the latency
// The time clinet provides a OCP::WIP::WTI compliant WTI-M interface

interface TimeClientIfc;
  method Action gpsTime (GPS64_t arg); 
  interface Wti_m#(64) wti_m;
endinterface

module mkTimeClient#(Clock sys0_clk, Reset sys0_rst, Clock wti_clk, Reset wti_rst) (TimeClientIfc);

  Reg#(GPS64_t)      now   <- mkSyncReg(unpack(0), sys0_clk, sys0_rst, wti_clk);
  WtiMasterIfc#(64)  wti   <- mkWtiMaster(clocked_by wti_clk, reset_by wti_rst); 

  rule send_time;
    wti.reqPut.put (WtiReq {cmd:WR, data:pack(now)});
  endrule

  // Interfaces Provided...
  method Action gpsTime (GPS64_t arg) = now._write(arg);
  interface Wti_m wti_m = wti.mas;

endmodule: mkTimeClient

endpackage: TimeService
