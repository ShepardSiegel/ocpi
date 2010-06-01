// PciAdapt.bsv
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

import Clocks            ::*;
import GetPut            ::*;
import FIFO              ::*;
import FIFOF             ::*;
import Connectable       ::*;
import DReg              ::*;
import DefaultValue      ::*;
import SpecialFIFOs      ::*;
import PCIE              ::*;
import AlignedFIFO       ::*;

typedef struct {
  PciTlpWord#(8) first;
  PciTlpWord#(8) second;
 } PciTlpWord2_8 deriving(Bits, Eq);

function PciTlpWord#(16) convertTLP2_8toTLP16(PciTlpWord2_8 in);
  return combineTLP8s(in.first, in.second);
endfunction

function PciTlpWord2_8 convertTLP16toTLP2_8(PciTlpWord#(16) in);
  match { .hi, .lo } = splitTLP16(in);
  return PciTlpWord2_8 {first:hi, second:lo};
endfunction

interface PciAdaptIfc;
  interface Put#(PciTlpWord#(8))  putTLPWordN;
  interface Get#(PciTlpWord#(8))  getTLPWordN;
  interface Put#(PciTlpWord#(16)) putTLPWordW;
  interface Get#(PciTlpWord#(16)) getTLPWordW;
endinterface

   
(* synthesize *)
module mkPciAdapt (Clock inf_clk, Reset inf_rst_n, PciAdaptIfc ifc);
  Clock                             trn_clk      <- exposeCurrentClock;
  Reset                             trn_rst_n    <- exposeCurrentReset;
  FIFO#(PciTlpWord#(8))             fTrnInfN     <- mkFIFO(clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(PciTlpWord#(8))             fInfTrnN     <- mkFIFO(clocked_by trn_clk, reset_by trn_rst_n);
  FIFO#(PciTlpWord#(16))            fTrnInfW     <- mkFIFO(clocked_by inf_clk, reset_by inf_rst_n);
  FIFO#(PciTlpWord#(16))            fInfTrnW     <- mkFIFO(clocked_by inf_clk, reset_by inf_rst_n);
  Aligned2xF2SFIFO#(PciTlpWord#(8)) fifoRxData   <- mkSyncFIFO_Aligned2x_srcFast_dstSlow(False, False,
                                                      inf_clk, clocked_by trn_clk, reset_by trn_rst_n);
  Aligned2xS2FFIFO#(PciTlpWord#(8)) fifoTxData   <- mkSyncFIFO_Aligned2x_srcSlow_dstFast(False, False,
                                                     inf_clk, clocked_by trn_clk, reset_by trn_rst_n);
  Reg#(Bool)                        oddBeat      <- mkRegA(False,  clocked_by trn_clk, reset_by trn_rst_n);
  Reg#(Bool)                        sendInvalid  <- mkDRegA(False, clocked_by trn_clk, reset_by trn_rst_n);
  Reg#(Bool)                        hieof        <- mkRegU(clocked_by trn_clk, reset_by trn_rst_n);

  // TLP Dataflow from TRN->INF, Receive Rules...

  rule process_incoming_packets_trn2inf_clktrn (!sendInvalid);
    let data = fTrnInfN.first; fTrnInfN.deq;
    oddBeat     <= !oddBeat;
    sendInvalid <= !oddBeat && fTrnInfN.first.eof;
    hieof       <= data.eof;
    fifoRxData.enq(data);
  endrule

  rule send_invalid_packets_trn2inf_clktrn (sendInvalid);
    fifoRxData.enq(createInvalidTLP8(hieof));
    oddBeat     <= !oddBeat;
  endrule

  rule send_inf_data_trn2inf_clkinf;
    let hi = fifoRxData.first;
    let lo = fifoRxData.second;
    let data = PciTlpWord2_8 {first:hi, second:lo};
    fifoRxData.deq;
    fTrnInfW.enq(convertTLP2_8toTLP16(data));
  endrule
   
  // TLP Dataflow from INF->TRN, Transmit Rules...

  rule get_inf_data_inf2trn_clkinf;
    let data = fInfTrnW.first; fInfTrnW.deq;
    let converted = convertTLP16toTLP2_8(data);
    fifoTxData.enq(converted.first, converted.second);
  endrule
   
  rule process_outgoing_packets_inf2trn_clktrn;
    let data = fifoTxData.first; fifoTxData.deq;
    if (data.rema != 0) fInfTrnN.enq(data);
  endrule
      
  interface putTLPWordN = toPut(fTrnInfN);  // Narrow-Fast, (nf) Trn->Inf
  interface getTLPWordW = toGet(fTrnInfW);  // Wide-Slow  ,      Trn->Inf (ws)
  interface getTLPWordN = toGet(fInfTrnN);  // Narrow-Fast, (nf) Trn<-Inf
  interface putTLPWordW = toPut(fInfTrnW);  // Wide-Slow  ,      Trn<-Inf (ws)
   
endmodule

