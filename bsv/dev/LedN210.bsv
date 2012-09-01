// LedN210.bsv - LED Logic for the N210 Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...

// BSV Imports...
import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import Gray              ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;

/* USRP2 N210 Front-Panel LED Encoding
| A(4)tx   | B(1)mimo |
| C(3)rx   | D(0)firm |
| E(2)ref  | F(-)cpld |
*/

interface LedN210Ifc;
  method  Action  ledDrive (Bit#(5) i);
(* always_ready, always_enabled *)
  method  Bit#(5) led;
endinterface

(* synthesize *)
module mkLedN210 (LedN210Ifc);

  Reg#(Bit#(5))    ledReg     <- mkReg(0);
  Reg#(Bit#(32))   freeCnt    <- mkReg(0);
  Reg#(Bool)       doInit     <- mkReg(True);

  rule inc_freeCnt;
    freeCnt <= freeCnt + 1;
    if (freeCnt>32'h0800_0000) doInit <= False;
  endrule

  function Bit#(5) initBlink (Bit#(32) cnt);
    Bool gateBit = unpack(cnt[21]);
    case (cnt[25:23])
      0, 1, 2, 6, 7 : return~(gateBit ? 5'h1C : 5'h00);
      3 : return~(5'h04);
      4 : return~(5'h0C);
      5 : return~(5'h1C);
    endcase
  endfunction

  function Bit#(5) ledStatus (Bit#(32) cnt, Bit#(5) ctl);
    Bool gateBit = unpack(cnt[23]);
    return~((gateBit ? 5'h01 : 5'h00) | ctl);
  endfunction

  method  Action  ledDrive (Bit#(5) i) = ledReg._write(i);
  method  Bit#(5) led = doInit ? initBlink(freeCnt) : ledStatus(freeCnt, ledReg);
endmodule: mkLedN210

