////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009  Bluespec, Inc.   ALL RIGHTS RESERVED.
////////////////////////////////////////////////////////////////////////////////
//  Filename      : AlignedFIFO.bsv
//  Author        : Todd Snyder
//  Description   : Fifos to preserve bandwidth by stepping down clock frequency
//                  and widening the datapath.
//  Requirements  : Clocks must be phase aligned
////////////////////////////////////////////////////////////////////////////////
package AlignedFIFO;

// Notes :
// - Only 2x clocks are currently supported

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Clocks            ::*;
import FIFOF             ::*;
import Vector            ::*;
import Connectable       ::*;

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
interface Aligned2xS2FFIFO#(type a_type);
   method    Action      enq(a_type in1, a_type in2);
   method    Action      deq();
   method    a_type      first();
   method    Bool        notFull();
   method    Bool        notEmpty();
endinterface

interface Aligned2xF2SFIFO#(type a_type);
   method    Action      enq(a_type in);
   method    Action      deq();
   method    a_type      first();
   method    a_type      second();
   method    Bool        notFull();
   method    Bool        notEmpty();
endinterface

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Implementation of Slow to Fast FIFO
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkSyncFIFO_Aligned2x_srcSlow_dstFast#(Bool ugenq,
					     Bool ugdeq,
					     Clock slowSrcClock
					     )(Aligned2xS2FFIFO#(a_type))
   provisos(Bits#(a_type, sa));
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Clocks & Reset
   ////////////////////////////////////////////////////////////////////////////////
   Clock                                     fastDstClock        <- exposeCurrentClock;
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   Vector#(4, Reg#(Maybe#(a_type)))          vrFIFO              <- replicateM(mkRegA(Invalid, clocked_by fastDstClock));

   Reg#(Bool)                                fEnqueued           <- mkRegA(False, clocked_by fastDstClock);
   
   RWire#(Vector#(2, a_type))                rwEnqueue           <- mkRWire(clocked_by slowSrcClock, reset_by noReset);
   PulseWire                                 pwDequeue           <- mkPulseWire(clocked_by fastDstClock);
   
   Reg#(Bool)                                rFullN              <- mkRegA(True, clocked_by fastDstClock);
   Reg#(Bool)                                rEmptyN             <- mkRegA(False, clocked_by fastDstClock);

   // allow the rFullN signal to be read in the slow domain
   ReadOnly#(Bool)                           slowFullN           <- mkNullCrossingWire(slowSrcClock, rFullN, clocked_by fastDstClock);
   // allow the rwEnqueue signal to be read in the fast domain
   ReadOnly#(Maybe#(Vector#(2, a_type)))     fastEnqueue         <- mkNullCrossing(fastDstClock, rwEnqueue.wget, clocked_by slowSrcClock);

   Bool enq_ok     = ugenq || slowFullN;
   Bool deq_ok     = ugdeq || rEmptyN;
   
   Bool enqueueing = isValid(fastEnqueue);
   Bool dequeueing = pwDequeue;
   Bool even_cycle = !fEnqueued;
   Bool odd_cycle  = fEnqueued;

   
   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_only(enqueueing && !dequeueing && even_cycle);
      Vector#(2, a_type) data = fromMaybe(?, fastEnqueue);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      if (!isValid(vrFIFO[0])) begin 
	 fifodata[0] = Valid(data[0]);
	 fifodata[1] = Valid(data[1]);
      end
      else if (!isValid(vrFIFO[1])) begin
	 fifodata[1] = Valid(data[0]);
	 fifodata[2] = Valid(data[1]);
      end 
      else begin
	 fifodata[2] = Valid(data[0]);
	 fifodata[3] = Valid(data[1]);
      end
      writeVReg(vrFIFO, fifodata);
      fEnqueued <= True;
      rEmptyN   <= True;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule dequeueing_only(dequeueing && !enqueueing);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      fifodata = shiftInAtN(fifodata, Invalid);
      writeVReg(vrFIFO, fifodata);
      rEmptyN   <= isValid(vrFIFO[1]);
      rFullN    <= !isValid(vrFIFO[2]);
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_odd_cycle(!dequeueing && odd_cycle);
      fEnqueued <= False;
      rFullN    <= !isValid(vrFIFO[2]);
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_and_dequeueing(enqueueing && dequeueing && even_cycle);
      Vector#(2, a_type) data = fromMaybe(?, fastEnqueue);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      fifodata    = shiftInAtN(fifodata, Invalid);
      if (isValid(vrFIFO[1])) begin
	 fifodata[1] = Valid(data[0]);
	 fifodata[2] = Valid(data[1]);
      end	 
      else begin
	 fifodata[0] = Valid(data[0]);
	 fifodata[1] = Valid(data[1]);
      end
      writeVReg(vrFIFO, fifodata);
      fEnqueued <= True;
      rEmptyN   <= True;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_and_dequeueing_odd_cycle(enqueueing && dequeueing && odd_cycle);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      fifodata = shiftInAtN(fifodata, Invalid);
      writeVReg(vrFIFO, fifodata);
      rEmptyN   <= isValid(vrFIFO[1]);
      fEnqueued <= False;
      rFullN    <= !isValid(vrFIFO[3]);
   endrule
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   method Action enq(a_type in1, a_type in2) if (enq_ok);
      Vector#(2, a_type) enqdata = ?;
      enqdata[0] = in1;
      enqdata[1] = in2;
      rwEnqueue.wset(enqdata);
   endmethod
   
   method Action deq() if (deq_ok);
      pwDequeue.send;
   endmethod
   
   method a_type first if (deq_ok);
      return fromMaybe(?, vrFIFO[0]);
   endmethod

   method Bool notFull;
      return slowFullN;
   endmethod
   
   method Bool notEmpty;
      return rEmptyN;
   endmethod
   
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Implementation of Fast to Slow FIFO
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkSyncFIFO_Aligned2x_srcFast_dstSlow#(Bool ugenq,
					     Bool ugdeq,
					     Clock slowSrcClock
					     )(Aligned2xF2SFIFO#(a_type))
   provisos(Bits#(a_type, sa));
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Clocks & Reset
   ////////////////////////////////////////////////////////////////////////////////
   Clock                                     fastDstClock        <- exposeCurrentClock;

   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   Vector#(4, Reg#(Maybe#(a_type)))          vrFIFO              <- replicateM(mkRegA(Invalid, clocked_by fastDstClock));
   
   Reg#(Bool)                                fDequeued           <- mkRegA(False, clocked_by fastDstClock);
   
   RWire#(a_type)                            rwEnqueue           <- mkRWire(clocked_by fastDstClock);
   PulseWire                                 pwDequeue           <- mkPulseWire(clocked_by slowSrcClock, reset_by noReset);

   Reg#(Bool)                                rFullN              <- mkRegA(True,  clocked_by fastDstClock);
   Reg#(Bool)                                rEmptyN             <- mkRegA(False, clocked_by fastDstClock);
   
   // allow the rEmptyN signal to be read in the slow domain
   ReadOnly#(Bool)                           slowEmptyN          <- mkNullCrossingWire(slowSrcClock, rEmptyN, clocked_by fastDstClock);
   // allow the rwEnqueue signal to be read in the fast domain
   ReadOnly#(Bool)                           fastDequeue         <- mkNullCrossing(fastDstClock, pwDequeue, clocked_by slowSrcClock);
   // allow the slow domain to get the data
   ReadOnly#(a_type)                         slowFirst           <- mkNullCrossingWire(slowSrcClock, validValue(vrFIFO[0]), clocked_by fastDstClock);
   ReadOnly#(a_type)                         slowSecond          <- mkNullCrossingWire(slowSrcClock, validValue(vrFIFO[1]), clocked_by fastDstClock);

   Bool enq_ok     = ugenq || rFullN;
   Bool deq_ok     = ugdeq || slowEmptyN;
   
   Bool enqueueing = isValid(rwEnqueue.wget);
   Bool dequeueing = fastDequeue;
   Bool even_cycle = !fDequeued;
   Bool odd_cycle  = fDequeued;
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_only(enqueueing && !dequeueing);
      let data = fromMaybe(?, rwEnqueue.wget);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      if (!isValid(vrFIFO[0])) 
	 fifodata[0] = Valid(data);
      else if (!isValid(vrFIFO[1]))
	 fifodata[1] = Valid(data);
      else if (!isValid(vrFIFO[2]))
	 fifodata[2] = Valid(data);
      else
	 fifodata[3] = Valid(data);
      writeVReg(vrFIFO, fifodata);
      rEmptyN   <= isValid(vrFIFO[0]);
      rFullN    <= !isValid(vrFIFO[2]);      
   endrule      
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule dequeueing_only(dequeueing && !enqueueing && even_cycle);
      fDequeued <= True;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule dequeueing_odd_cycle(!enqueueing && odd_cycle);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      fifodata = shiftInAtN(fifodata, Invalid);
      fifodata = shiftInAtN(fifodata, Invalid);
      writeVReg(vrFIFO, fifodata);
      fDequeued <= False;
      rEmptyN   <= isValid(vrFIFO[2]);
      rFullN    <= True; 
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_and_dequeueing(enqueueing && dequeueing && even_cycle);
      let data = fromMaybe(?, rwEnqueue.wget);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      if (!isValid(vrFIFO[2]))
	 fifodata[2] = Valid(data);
      else
	 fifodata[3] = Valid(data);
      writeVReg(vrFIFO, fifodata);
      fDequeued <= True;
      rFullN    <= True;
   endrule
   
   (* fire_when_enabled, no_implicit_conditions *)
   rule enqueueing_and_dequeueing_odd_cycle(enqueueing && dequeueing && odd_cycle);
      let data = fromMaybe(?, rwEnqueue.wget);
      Vector#(4, Maybe#(a_type)) fifodata = readVReg(vrFIFO);
      fifodata = shiftInAtN(fifodata, Invalid);
      fifodata = shiftInAtN(fifodata, Invalid);
      if (!isValid(vrFIFO[2]))
	 fifodata[0] = Valid(data);
      else
	 fifodata[1] = Valid(data);
      writeVReg(vrFIFO, fifodata);
      fDequeued <= False;
      rEmptyN   <= True;
      rFullN    <= True;
   endrule
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   method Action enq(a_type in) if (enq_ok);
      rwEnqueue.wset(in);
   endmethod
   
   method Action deq() if (deq_ok);
      pwDequeue.send;
   endmethod
   
   method a_type first()  if (deq_ok);
      return slowFirst;
   endmethod
   
   method a_type second()  if (deq_ok);
      return slowSecond;
   endmethod
   
   method Bool notFull();
      return rFullN;
   endmethod
   
   method Bool notEmpty();
      return slowEmptyN;
   endmethod
   
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Synthesis boundaries to test clock domain properties
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/*
(* synthesize *)
module mkTest1(Empty);
   Clock slow <- mkAbsoluteClock(10,20);
   Aligned2xS2FFIFO#(Bool) f <- mkSyncFIFO_Aligned2x_srcSlow_dstFast(False, False, slow);
   Reg#(Bool) rgIn <- mkRegU(clocked_by slow);
   Reg#(Bool) rgOut <- mkRegU;
   rule r1;
      f.enq(rgIn, True);
   endrule
   rule r2;
      rgOut <= f.first;
      f.deq;
   endrule
endmodule
*/

/*
(* synthesize *)
module mkTest2(Empty);
   Clock slow <- mkAbsoluteClock(10,20);
   Aligned2xF2SFIFO#(Bool) f <- mkSyncFIFO_Aligned2x_srcFast_dstSlow(False, False, slow);
   Reg#(Bool) rgIn <- mkRegU;
   Reg#(Bool) rgOut <- mkRegU(clocked_by slow);
   rule r1;
      f.enq(rgIn);
   endrule
   rule r2;
      rgOut <= f.first;
      f.deq;
   endrule
endmodule
*/

endpackage: AlignedFIFO
