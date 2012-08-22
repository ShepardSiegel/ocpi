// WmiServBC.bsv
// Copyright (c) 2009-2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import OCWip::*;
import OCBufQ::*;
import TimeService::*;

import GetPut::*;
import RegFile::*;
import Vector::*;
import BUtils::*;	 
import DReg::*;	
import BRAM::*;	
import FIFO::*;	
import FIFOF::*;	
import Connectable::*;
import ClientServer::*;
import Alias::*;

interface WmiServBCIfc#(numeric type ndw);
  interface Wmi_s#(14,12,TMul#(ndw,32),0,TMul#(ndw,4),32)  wmi_s;
  interface BufQCIfc                            bufq;
  method Vector#(4,Bit#(32))                    stat;
  method Action                                 dpCtrl  (DPControl dc);
  method Action                                 operate;
  method Action                                 now     (Bit#(64) arg);
endinterface 

module mkWmiServBC#(Vector#(4,BRAMServer#(DPBufHWAddr,Bit#(32))) mem) (WmiServBCIfc#(ndw))
  provisos (DWordWidth#(ndw), NumAlias#(TMul#(ndw,32),nd), Add#(a_,32,nd));

  Bit#(9)  wmiByteWidth  = fromInteger(valueOf(nd))>>3;         // Width of WMI in Bytes

  WmiSlaveIfc#(14,12,nd,0,TMul#(ndw,4),32) wmi   <- mkWmiSlave;
  Reg#(Maybe#(MesgMeta))        mesgMeta         <- mkReg(tagged Invalid);
  Reg#(Bool)                    wrActive         <- mkReg(False);
  Reg#(Bool)                    rdActive         <- mkReg(False);
  Reg#(Bool)                    doneWithMesg     <- mkReg(False);
  Reg#(Bool)                    wrFinalize       <- mkReg(False);
  Reg#(Bit#(14))                addr             <- mkRegU;
  Reg#(Bit#(14))                bytesRemainReq   <- mkRegU;
  Reg#(Bit#(14))                bytesRemainResp  <- mkReg(0);
  Reg#(Bit#(32))                mesgCount        <- mkReg(0);
  Reg#(Bool)                    mesgBusy         <- mkReg(False);
  Reg#(Bool)                    metaBusy         <- mkReg(False);
  Reg#(Bool)                    mesgStart        <- mkDReg(False);
  Reg#(Bool)                    mesgDone         <- mkDReg(False);
  Reg#(Bool)                    mesgBufReady     <- mkDReg(False);
  Reg#(Bit#(2))                 bufDwell         <- mkReg(0);
  Reg#(Bit#(2))                 p4B              <- mkReg(0);
  Reg#(DPBufBAddr)              lclMetaAddr      <- mkRegU;
  Reg#(DPBufBAddr)              lclMesgAddr      <- mkRegU;
  Reg#(MesgMetaDW)              thisMesg         <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(MesgMetaDW)              lastMesg         <- mkReg(unpack(32'hFEFE_FFFE));
  Reg#(Bit#(16))                reqCount         <- mkReg(0);
  Reg#(Bit#(16))                wrtCount         <- mkReg(0);
  Wire#(DPControl)              dpControl        <- mkWire;
  Wire#(Bit#(64))               nowW             <- mkWire;
  //FIFO#(Bit#(0))                mesgTokenF       <- mkFIFO1;

  Bool isProducer = dpControl.dir==FProducer;

  rule throttleWmi;
    if ( (!isProducer&&!isValid(mesgMeta)) || (isProducer&&!mesgBufReady) ) begin
      wmi.forceSThreadBusy;
      //$display("[%0d]: %m: WmiServBC MESG REQ BUF BLOCKED AT mesgCount:%0x", $time, mesgCount);
    end
  endrule

 (* descending_urgency = "doWriteFinalize, doWriteReq, doReadResp, doReadReq, getRequest, respMetadata, reqMetadata" *)

  // As a Fabric Consumer, request needed message metadata when available...
  rule reqMetadata (!isProducer && !isValid(mesgMeta) && mesgBufReady && !metaBusy && bufDwell==0);
    metaBusy <= True;
    let req = BRAMRequest {write:False, address:truncate(lclMetaAddr>>4), datain:0, responseOnWrite:False };
    for (Integer i=0; i<4; i=i+1) mem[i].request.put(req); 
    //$display("[%0d]: %m: reqMetaData lclMetaAddr :%0h", $time, lclMetaAddr );
  endrule

  // As a Fabric Consumer, capture the message metadata...
  rule respMetadata (!isProducer && !isValid(mesgMeta) && mesgBufReady && metaBusy);
    metaBusy <= False;
    Bit#(32) length   <- mem[0].response.get;  // Message Length in Bytes
    Bit#(32) opcode   <- mem[1].response.get;
    Bit#(32) nowMS    <- mem[2].response.get;
    Bit#(32) nowLS    <- mem[3].response.get;
    let m = MesgMeta { length   : length, 
                       opcode   : opcode, 
                       nowMS    : nowMS,
                       nowLS    : nowLS };
    mesgMeta <= tagged Valid m; // Valid mesgMeta indicates message available on SThreadBusy
    wmi.drvSFlag({opcode[7:0],length[23:0]});  // Put the opcode and Byte length out on WMI SFlag
    //$display("[%0d]: %m: respMetaData length:%0h opcode:%0h", $time, length, opcode);
  endrule


  // This rule fires to digest each new WMI request...
  rule getRequest ((!wrActive || !rdActive) && !wrFinalize && (mesgBufReady || mesgBusy) && bufDwell==0 );
    let req <- wmi.req;
    //if(req.cmd==WR) mesgTokenF.enq(?); // prevent getRequest from firing until doWriteFinalize has completed
    reqCount <= reqCount + 1;
    wrActive    <= req.cmd==WR;
    rdActive    <= req.cmd==RD;
    addr        <= req.addr;
    Bit#(14) transferBytes = extend(req.burstLength) * extend(wmiByteWidth);
    bytesRemainReq  <= transferBytes;
    if (req.cmd==RD) begin
      bytesRemainResp <= transferBytes;
      p4B <= req.addr[3:2];                  // Starting Read phase for the 4B word in the 16B superword
    end
    mesgBusy    <= True;                     // Frames one or more requests to the message buffer
    if (!mesgBusy) mesgStart  <= True;       // Exactly one local.start event to buffer manager logic
    doneWithMesg <=  unpack(req.reqInfo[0]); // Sample DWM for this request
    //$display("[%0d]: %m: getRequest mesgCount:%0x startAddr:%0x",$time,mesgCount,req.addr);
  endrule

  // Fires one or more times to commit each DW/QW/HW in the Write Request 4B/8B/16B at a time...
  rule doWriteReq (wrActive);
    Bool lastWordofReq = (bytesRemainReq==extend(wmiByteWidth)); // Is this the last Word of this request?
    let dh <- wmi.dh;                             // Take the Datahandshake bundle from the WMI interface
    Bit#(128) writeWordB16 = zExtend(dh.data);    // Extend dh.data in the 4B and 8B cases; pass 16B unchanged
    Vector#(4,Bit#(32)) vWord = unpack(writeWordB16);  // Stuff 1, 2, or 4 DWORDs into the vWord Vector
    wrtCount <= wrtCount + 1;
    addr     <= addr + extend(wmiByteWidth);
    bytesRemainReq <= bytesRemainReq - extend(wmiByteWidth);
    DPBufHWAddr bramAddr = truncate(lclMesgAddr>>4) + truncate(addr>>4);
    case (wmiByteWidth)
      4:  action
            let req4  = BRAMRequest { write:True, address:bramAddr, datain:vWord[0], responseOnWrite:False };
            mem[addr[3:2]].request.put(req4); 
          endaction
      8:  action 
            let req8a = BRAMRequest { write:True, address:bramAddr, datain:vWord[0], responseOnWrite:False };
            let req8b = BRAMRequest { write:True, address:bramAddr, datain:vWord[1], responseOnWrite:False };
            mem[{addr[3],1'b0}].request.put(req8a);
            mem[{addr[3],1'b1}].request.put(req8b);
          endaction
      16: action
          for (Integer i=0; i<4; i=i+1) begin
            let req16 = BRAMRequest { write:True, address:bramAddr, datain:vWord[i], responseOnWrite:False };
            mem[i].request.put(req16); 
          end
        endaction
    endcase
    if (lastWordofReq) begin           // If last Word of Write Request...
      wrActive <= False;               //   Invalidate Request
      if (doneWithMesg) begin          //   And if also a DWM Write Request...
        doneWithMesg  <= False;        //     Invalidate DWM
        wrFinalize    <= True;         //     doWriteFinalize for Message Metadata
      end
    end
    //$display("[%0d]: %m: doWriteReq mesgCount:%0x addr:%0x bramAddr:%0x wdata:%x ", $time, mesgCount, addr, bramAddr, dh.data);
  endrule 


  // Fires exactly once after a Write Done-With-Message (DWM) request...
  rule doWriteFinalize (wrFinalize);
    //mesgTokenF.deq();
    let mf <- wmi.popMFlag;
    Bit#(8)  reqInfo    = truncate(mf>>24);
    Bit#(24) mesgLength = truncate(mf);
    thisMesg <= MesgMetaDW { tag:truncate(mesgCount), opcode:reqInfo, length:truncate(mesgLength) };
    lastMesg <= thisMesg;
    let mesgMeta  = MesgMeta {length:extend(mesgLength), opcode:{24'h800000,reqInfo}, nowMS:nowW[63:32], nowLS:nowW[31:0]}; 
    let req = BRAMRequest {write:True, address:truncate(lclMetaAddr>>4), datain:0, responseOnWrite:False };
    // Simultaneously write all four DWORDs of the Message Metadata...
    req.datain = mesgMeta.length;   mem[0].request.put(req);  // Message Length in Bytes
    req.datain = mesgMeta.opcode;   mem[1].request.put(req); 
    req.datain = mesgMeta.nowMS;    mem[2].request.put(req); 
    req.datain = mesgMeta.nowLS;    mem[3].request.put(req); 
    wmi.allowReq;                    // Allow the next request
    wrFinalize   <= False;           // Clear wrFinalize
    mesgDone     <= True;            // Exactly one local.done event to buffer manager logic
    bufDwell     <= 3;               // Wait 3 cycles for the finalize->done->bml->addr update
    mesgCount    <= mesgCount+1;     // Bump diagnostic message count
    $display("[%0d]: %m: doWriteFinalize lclMetaAddr :%0x length:%0x opcode:%0x nowMS:%0x nowLS:%0x ",
      $time, lclMetaAddr , mesgMeta.length, mesgMeta.opcode, mesgMeta.nowMS, mesgMeta.nowLS);
  endrule 

  // Fires one or more times to REQUEST DW/QW/HQ Reads 4B/8B/16B at a time...
  rule doReadReq (rdActive);
    Bool lastWordofReq = (bytesRemainReq==extend(wmiByteWidth));
    addr           <= addr + extend(wmiByteWidth);
    bytesRemainReq <= bytesRemainReq - extend(wmiByteWidth);
    DPBufHWAddr bramAddr = truncate(lclMesgAddr>>4) + truncate(addr>>4);
    // There are at least two approaches we can take for reads:
    // We could simply read the entire 16B superword, capure the entire 16B response, then select whatever 4B/8B/16B we need
    // Or, we could issue specific 4B/8B/16B requests and then selectively capture the responses to the parts we requested
    // The later probably saves power since we only read from memories where we will use the results
    /*
    for (Integer i=0; i<4; i=i+1) begin
      let req16 = BRAMRequest { write:False, address:bramAddr, datain:'0, responseOnWrite:False };
      mem[i].request.put(req16);  // read all the memories
    end
    */
    case (wmiByteWidth)
      4:  action
            let req4  = BRAMRequest { write:False, address:bramAddr, datain:'0, responseOnWrite:False };
            mem[addr[3:2]].request.put(req4); 
          endaction
      8:  action 
            let req8a = BRAMRequest { write:False, address:bramAddr, datain:'0, responseOnWrite:False };
            let req8b = BRAMRequest { write:False, address:bramAddr, datain:'0, responseOnWrite:False };
            mem[{addr[3],1'b0}].request.put(req8a);
            mem[{addr[3],1'b1}].request.put(req8b);
          endaction
      16: action
          for (Integer i=0; i<4; i=i+1) begin
            let req16 = BRAMRequest { write:False, address:bramAddr, datain:'0, responseOnWrite:False };
            mem[i].request.put(req16); 
          end
        endaction
    endcase
    if (lastWordofReq) begin          // If last Word of Read Request... 
      rdActive <= False;              //   Invalidate Request
      if (doneWithMesg) begin         //   And if also a DWM Read Request...
        wmi.allowReq;                 //     Allow the next request
        doneWithMesg  <= False;       //     Invalidate DWM
        mesgDone      <= True;        //     Exactly one local.done event to buffer manager logic
        bufDwell      <= 3;           //     Wait 3 cycles before clearing mesgBusy
        mesgCount     <= mesgCount+1; //     Increment rolling message counter
        mesgMeta      <= tagged Invalid;  // Indicates Message Unavailable to Fabric Consumer
        //$display("[%0d]: %m: doReadReq4B doneWithMesg", $time);
      end
    end
    //$display("[%0d]: %m: doReadReq mesgCount:%0x addr:%0x bramAddr:%0x", $time, mesgCount, addr, bramAddr);
  endrule

 // rd: Used to hold off the next consumer meta read until the buffer pointer is updated
 // wt: Used to hold off the next producer request until finalize->done->make buffer new address
 // Can remove this if we switch the buffer logic to count on "start" instead of "done"?
 rule doDwell (bufDwell > 0);
   bufDwell <= bufDwell - 1;
   if(bufDwell==1) mesgBusy <= False;  // This cascade of requests is over
 endrule

  // Fires to collect the read RESPONSES 4B/8B/16B at a time that follow each doReadReq by the read latency
  // We must select either a 4B, 8B, or 16B aligned WMI word to return...
  rule doReadResp (bytesRemainResp>0);
    Vector#(4,Bit#(32)) vWord = ?;
    case (wmiByteWidth)
      4:  vWord[0] <- mem[p4B].response.get;
      8:  action
          vWord[0] <- mem[{p4B[1],1'b0}].response.get;
          vWord[1] <- mem[{p4B[1],1'b1}].response.get;
          endaction
      16: for (Integer i=0; i<4; i=i+1) vWord[i] <- mem[i].response.get;
    endcase
    Bit#(32)  readWordB4  = pack(vWord[0]);
    Bit#(64)  readWordB8  = pack(take(vWord));
    Bit#(128) readWordB16 = pack(vWord);
    p4B <= p4B + truncate((wmiByteWidth>>2));
    bytesRemainResp <= bytesRemainResp - extend(wmiByteWidth);
    case (wmiByteWidth)
      4:  wmi.respd(zExtend(readWordB4)); 
      8:  wmi.respd(zExtend(readWordB8));
      16: wmi.respd(zExtend(readWordB16));
    endcase
    //$display("[%0d]: %m: doReadResp p4B:%0x bytesRemainResp:%0x readWord:%0x ", $time, p4B, bytesRemainResp, readWord);
  endrule

  interface Wmi_s wmi_s = wmi.slv;

  interface BufQCIfc bufq;
    method Bool   start   = mesgStart;
    method Bool   done    = mesgDone;
    method Bool   fabric  = False;
    method Action rdy     = mesgBufReady._write(True);
    method Action frdy    = noAction;
    method Action credit  = noAction;
    method Action bufMeta (Bit#(16) bMeta); lclMetaAddr<=truncate(bMeta); endmethod
    method Action bufMesg (Bit#(16) bMesg); lclMesgAddr<=truncate(bMesg); endmethod
    method Action fabMeta (Bit#(32) fMeta) = noAction;
    method Action fabMesg (Bit#(32) fMesg) = noAction;
    method Action fabFlow (Bit#(32) fFlow) = noAction;
  endinterface
  
  method Vector#(4,Bit#(32)) stat = unpack({pack(thisMesg),pack(lastMesg),reqCount,wrtCount,32'h0});
  method Action dpCtrl (DPControl dc) = dpControl._write(dc);
  method Action operate = wmi.operate();
  method Action now (Bit#(64) arg) = nowW._write(arg);

endmodule

