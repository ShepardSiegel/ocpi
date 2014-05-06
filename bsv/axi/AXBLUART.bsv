// AXBLUART - An AXI wrapper around a BSV UART
// Copyright (c) 2014 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4L ::*;  
import BLUART  ::*;

import FIFO    ::*;	
import GetPut  ::*;
import Vector  ::*;

interface AXBLUARTIfc;
  interface A4L_Es    s_axi;  // Slave AXI Ifc
  interface UART_pads upads;  // UART pads
endinterface

(* synthesize, default_clock_osc="s_axi_aclk", default_reset="s_axi_aresetn" *)
module mkAXBLUART (AXBLUARTIfc);
  A4LSlaveIfc     a4l          <- mkA4LSlave;     // The AXI4-Lite Slave Interface
  Reg#(Bit#(32))  r0           <- mkReg(0);       // Some regsiters for testing...
  Reg#(Bit#(32))  r4           <- mkReg(0);
  Reg#(Bit#(32))  r8           <- mkReg(0);
  Reg#(Bit#(32))  rC           <- mkReg(0);
  BLUARTIfc       bluart       <- mkBLUART;       // BLUART
  Reg#(Bool)      uartInited   <- mkReg(False);
  Reg#(UInt#(6))  uartTxtP     <- mkReg(0);

  function Vector#(40,Bit#(8)) uartLine(String s);
     Integer n = primStringToInteger(s);
     Integer l = stringLength(s) - 1;
     Vector#(40,Bit#(8)) text;
     for (Integer i = 0; i < 40; i = i + 1) begin
        Bit#(8) ch = fromInteger(n % 256);
        n = n / 256;
        if (ch == 0) text[i] = 8'h20; // blank space
        else text[l-i] = ch;
     end
     return text;
  endfunction

rule init_uart_text (!uartInited);
  Vector#(40,Bit#(8)) initText = uartLine("AXBLUART.bsv - Atomic Rules LLC (c) 2014");
  case (uartTxtP)
    0,42   : bluart.txChar.put(8'h0d); // CR
    1,43   : bluart.txChar.put(8'h0a); // LF
    default: bluart.txChar.put(initText[uartTxtP-2]);
  endcase
  uartTxtP <= uartTxtP + 1;
  if (uartTxtP==43) uartInited <= True;
endrule

rule a4l_cfwr; // AXI4-Lite Configuration Property Writes...
  let wa = a4l.f.wrAddr.first; a4l.f.wrAddr.deq;  // Get the write address
  let wd = a4l.f.wrData.first; a4l.f.wrData.deq;  // Get the write data
  case (wa.addr[7:0]) matches                     // Take some action with it...
    'h00 : r0  <= unpack(wd.data);
    'h04 : r4  <= unpack(wd.data);
    'h08 : r8  <= unpack(wd.data);
    'h0C : rC  <= unpack(wd.data);
    'h20 : bluart.setClkDiv.put(truncate(unpack(wd.data)));
    'h2C : bluart.txChar.put   (truncate(unpack(wd.data)));
  endcase
  a4l.f.wrResp.enq(A4LWrResp{resp:OKAY});         // Acknowledge the write
  $display("[%0d]: %m: AXI4-LITE CONFIG WRITE Addr:%0x BE:%0x Data:%0x", $time, wa.addr, wd.strb, wd.data);
endrule

rule a4l_cfrd;  // AXI4-Lite Configuration Property Reads...
  let ra = a4l.f.rdAddr.first; a4l.f.rdAddr.deq;    // Get the read address
  Bit#(32) rdat = ?;                                
  case (ra.addr[7:0]) matches                     
    'h00 : rdat = pack(r0);           // return r0
    'h04 : rdat = pack(r4);           // return r4
    'h08 : rdat = pack(r8);           // return r8
    'h0C : rdat = pack(rC);           // return rC
    'h10 : rdat = 32'hDEADBEEF;       // return a constant
    'h14 : rdat = 32'hBABECAFE;       // return a constant
    'h18 : rdat = 32'hF00DFACE;       // return a constant
    'h1C : rdat = 32'hFEEDC0DE;       // return a constant
    'h24 : rdat = extend(pack(bluart.txLevel));  // return the count of chars in the txFIFO
    'h28 : rdat = extend(pack(bluart.rxLevel));  // return the count of chars in the rxFIFO
    'h30 : action  // Check to see if there is anything in the rxFIFO...
             if (bluart.rxLevel > 0) begin // if so, get that data and return
               let d <- bluart.rxChar.get();
               rdat = extend(unpack(d));
             end else begin                // if not, return 0
               rdat = 0;
             end
           endaction
  endcase
  a4l.f.rdResp.enq(A4LRdResp{data:rdat,resp:OKAY}); // Return the read data
  $display("[%0d]: %m: AXI4-LITE CONFIG READ Addr:%0x",$time, ra.addr);
  $display("[%0d]: %m: AXI4-LITE CONFIG READ RESPOSNE Data:%0x",$time, rdat);
endrule

  A4L_Es a4ls <- mkA4StoEs(a4l.a4ls); // return the expanded interface...
  //return(a4ls); 
  interface A4L_Es s_axi = a4ls;      // prepend "s_axi"
  interface UART_pads upads = bluart.pads;
endmodule
