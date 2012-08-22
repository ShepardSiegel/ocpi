// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import ClockN210         ::*;
import LedN210           ::*;
import Config            ::*;
import GMAC              ::*;
import GbeLite           ::*;
import GbeWrk            ::*;
import IQADCWorker       ::*;
import MDIO              ::*;
import OCCP              ::*;
import OCEDP             ::*;
import OCWip             ::*;
import PWrk_n210         ::*;
import SMAdapter         ::*;
import WSICaptureWorker  ::*;
import WSIPatternWorker  ::*;

//import CPDefs            ::*;
//import CTop              ::*;
//import FlashWorker       ::*;
//import GbeWorker         ::*;
//import SPICore32         ::*;
//import SPICore5          ::*;
//import TimeService       ::*;
//import WSICaptureWorker  ::*;
//import WsiAdapter        ::*;
//import XilinxExtra       ::*;
//import ProtocolMonitor   ::*;

// BSV Imports...
import Clocks            ::*;
import ClientServer      ::*;
import Connectable       ::*;
import DefaultValue      ::*;
import FIFO              ::*;
import GetPut            ::*;
import TieOff            ::*;
import Vector            ::*;
import XilinxCells       ::*;

/* USRP2 N210 Front-Panel LED Encoding
| A(4)tx   | B(1)mimo |
| C(3)rx   | D(0)firm |
| E(2)ref  | F(x)done |
*/


(* always_ready, always_enabled *)
interface FTop_n210Ifc;
  method     Bit#(5)       led;
  method     Bit#(32)      debug;
  interface  Clock         rxclkBnd;   // GMII RX Clock (provided here for BSV interface rules)
  interface  Reset         gmii_rstn;  // GMII Reset driven out to PHY
  interface  GMII_RS       gmii;       // The GMII link RX/TX
  interface  MDIO_Pads     mdio;       // The Ethernet MDIO pads
  interface  TI62P4X_Pads  adc;
  interface  I2C_Pins      i2c;
  interface  SPIFLASH_Pads flash;
  interface  Clock         sys0Clk;
  interface  Reset         sys0Rst;
endinterface: FTop_n210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_n210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Clock gmii_sysclk,                 // 125 MHz from GbE PHY - stable clock, once enabled after reset
                    Clock gmii_rx_clk,                 // 125 MHz GMII RX Clock - agile recovered rx clock, when 1Gb link up
                    Clock adc_clkout,                  // CMOS SDR Output Clock from ADC
                    Reset fpga_rstn)                   // FPGA User Reset Pushbutton S2
                    (FTop_n210Ifc);

  Clock            clkIn      <- mkClockIBUFDS(sys0_clkp, sys0_clkn);     // sys0: 100 MHz Clock and Reset (from clock gen)
  ClockN210Ifc     clkN210    <- mkClockN210(clkIn, fpga_rstn);
  Clock            sys0_clk   = clkN210.clk0;
  Reset            sys0_rst   = clkN210.rst0;
  Clock            gmiixo_clk <- mkClockBUFG(clocked_by gmii_sysclk);
  Reset            gmiixo_rst <- mkAsyncReset(2, sys0_rst, gmiixo_clk);

  LedN210Ifc       ledLogic   <- mkLedN210(clocked_by sys0_clk, reset_by sys0_rst);

  GbeLiteIfc       gbe0       <- mkGbeLite(False, gmii_rx_clk, gmiixo_clk, gmiixo_rst, sys0_clk, sys0_rst, clocked_by gmii_sysclk, reset_by gmiixo_rst);
  OCCPIfc#(Nwcit)  cp         <- mkOCCP(?, sys0_clk, sys0_rst, clocked_by sys0_clk, reset_by sys0_rst);

  mkConnection(gbe0.cpClient, cp.server);

  Vector#(Nwcit, WciEM) vWci = cp.wci_Vm;

  // Make sure when calling out a specific interface, eg xxx4BIfc, you use the non-polymorphic mkXxx4B instance
  // 2012-08-19 odd WSI behavior seen when non-synth, poly module was instanced instead. Should dig deeper.
  WSIPatternWorker4BIfc  pat0    <- mkWSIPatternWorker4B(True,        clocked_by sys0_clk, reset_by(vWci[5].mReset_n));
  SMAdapter4BIfc         sma0    <- mkSMAdapter4B(32'h00000002, True, clocked_by sys0_clk, reset_by(vWci[6].mReset_n));

//WciSlaveNullIfc#(32)  tieOff0  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff1  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff2  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff3  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff4  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff5  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff6  <- mkWciSlaveNull;
  PWrk_n210Ifc          pwrk     <- mkPWrk_n210(sys0_rst, clocked_by sys0_clk, reset_by(vWci[7].mReset_n));
  WciSlaveNullIfc#(32)  tieoff8  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieoff9  <- mkWciSlaveNull;
  GbeWrkIfc             gbewrk   <- mkGbeWrk(True, clocked_by sys0_clk, reset_by(vWci[9].mReset_n));
  IQADCWorkerIfc        iqadc    <- mkIQADCWorker(True, sys0_clk, sys0_rst, sys0_clk, sys0_rst, adc_clkout, clocked_by sys0_clk, reset_by(vWci[10].mReset_n));  // Worker 11 
  WSICaptureWorker4BIfc cap0     <- mkWSICaptureWorker4B(True,                                              clocked_by sys0_clk, reset_by(vWci[11].mReset_n));  // Worker 12
//WciSlaveNullIfc#(32)  tieOff12 <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff13 <- mkWciSlaveNull;
  OCEDP4BIfc edp0  <- mkOCEDP4B (?,True,True, True, clocked_by sys0_clk, reset_by vWci[13].mReset_n); // Ethernet Data Plane 0
//WciSlaveNullIfc#(32)  tieOff14 <- mkWciSlaveNull;

  mkConnection(gbe0.dpClient, edp0.server); // Path from dgdp to GbE
  mkConnection(pat0.wsiM0, sma0.wsiS0, clocked_by sys0_clk, reset_by sys0_rst);     // Connect the PatternWorker to the SMAAdapter
  mkConnection(sma0.wmiM0, edp0.wmiS0);     // Connect the SMAAdapter to the DGDP WMI slave port

//mkConnection(vWci[0],  tieOff0.slv); 
//mkConnection(vWci[1],  tieOff1.slv); 
//mkConnection(vWci[2],  tieOff2.slv); 
//mkConnection(vWci[3],  tieOff3.slv); 
//mkConnection(vWci[4],  tieOff4.slv); 
  mkConnection(vWci[5],  pat0.wciS0); 
  mkConnection(vWci[6],  sma0.wciS0); 
  mkConnection(vWci[7],  pwrk.wciS0);    // N210 Platform Worker
  mkConnection(vWci[8],  tieoff8.slv);   // 

//mkConnection(vWci[9],  tieoff9.slv);   // 
  mkConnection(vWci[9],  gbewrk.wciS0);  // GbE Worker

  mkConnection(vWci[10], iqadc.wciS0);   // IQ-ADC
  mkConnection(vWci[11], cap0.wciS0);    // Capture Worker
//mkConnection(vWci[12], tieOff12.slv); 
//mkConnection(vWci[13], tieOff13.slv); 
  mkConnection(vWci[13], edp0.wciS0);    // EDP0
//mkConnection(vWci[14], tieOff14.slv); 

  mkConnection(pwrk.macAddr, gbe0.macAddr);  // Connect the EEPROM-sourced MAC Addr to the GBE
  mkConnection(iqadc.wsiM0, cap0.wsiS0);     // Connect the WSI output from the IQ-ADC to the Capture Worker

  rule send_gbe_stats;
    gbewrk.dgdpEgressCnt(gbe0.dgdpEgressCnt);
  endrule

  method    Bit#(5)       led    = ledLogic.led;
  method    Bit#(32)      debug  = {16'h5555, 16'h0000};
  interface Clock         rxclkBnd   = gbe0.rxclkBnd;
  interface Reset         gmii_rstn  = gbe0.gmii_rstn;
  interface GMII          gmii       = gbe0.gmii;
  interface MDIO_Pads     mdio       = gbe0.mdio;
  interface TI62P4X_Pads  adc        = iqadc.adc;
  interface I2C_Pins      i2c        = pwrk.i2cpad;
  interface SPIFLASH_Pads flash      = pwrk.spipad;
  interface Clock         sys0Clk    = sys0_clk;
  interface Reset         sys0Rst    = sys0_rst;
endmodule: mkFTop_n210

