// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import ClockN210         ::*;
import ICAPWorker        ::*;
import LedN210           ::*;
import Config            ::*;
import OCCP              ::*;
import OCWip             ::*;
import MDIO              ::*;
import GMAC              ::*;
import GbeLite           ::*;
import SPIFlashWorker    ::*;
import IQADCWorker       ::*;

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
| E(2)ref  | F(-)cpld |
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
  interface  SPIFLASH_Pads flash;
  interface  Clock         sys0Clk;
  interface  Reset         sys0Rst;
  interface  Clock         sys125Clk;
  interface  Reset         sys125Rst;
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
  Clock            sys2_clk   = clkN210.clk2x;
  Reset            sys2_rst   = clkN210.rst2x;
  Clock            sysdv_clk  = clkN210.clkdv;
  Reset            sysdv_rst  = clkN210.rstdv;
  Clock            sys125_clk = clkN210.clk125;
  Reset            sys125_rst = clkN210.rst125;
  Clock            gmiixo_clk <- mkClockBUFG(clocked_by gmii_sysclk);
  Reset            gmiixo_rst <- mkAsyncReset(2, sys0_rst, gmiixo_clk);

  Clock            adc_clk    = sysdv_clk;
  Reset            adc_rst    = sysdv_rst;

  LedN210Ifc       ledLogic   <- mkLedN210(clocked_by sys0_clk, reset_by sys0_rst);
  GbeLiteIfc       gbe0       <- mkGbeLite(False, gmii_rx_clk, gmiixo_clk, gmiixo_rst, sys0_clk, sys0_rst, clocked_by sys125_clk, reset_by sys125_rst);
  OCCPIfc#(Nwcit)  cp         <- mkOCCP(?, sys2_clk, sys2_rst, clocked_by sys0_clk, reset_by sys0_rst);
  mkConnection(gbe0.cpClient, cp.server);

  Vector#(Nwcit, WciEM) vWci = cp.wci_Vm;

  WciSlaveNullIfc#(32) tieOff0  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff1  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff2  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff3  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff4  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff5  <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff6  <- mkWciSlaveNull;
  ICAPWorkerIfc        icap     <- mkICAPWorker("S3A", True, clocked_by sys0_clk, reset_by(vWci[7].mReset_n));  // Worker 8
  SPIFlashWorkerIfc    flashw   <- mkSPIFlashWorker(True,    clocked_by sys0_clk, reset_by(vWci[8].mReset_n));  // Worker 9
  WciSlaveNullIfc#(32) tieOff9  <- mkWciSlaveNull;  // GbE Worker 10
  IQADCWorkerIfc       iqadc    <- mkIQADCWorker(True, sys2_clk, sys2_rst, adc_clk, adc_rst, adc_clkout, clocked_by sys0_clk, reset_by(vWci[10].mReset_n));  // Worker 11 
  WciSlaveNullIfc#(32) tieOff11 <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff12 <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff13 <- mkWciSlaveNull;
  WciSlaveNullIfc#(32) tieOff14 <- mkWciSlaveNull;

  mkConnection(vWci[0],  tieOff0.slv); 
  mkConnection(vWci[1],  tieOff1.slv); 
  mkConnection(vWci[2],  tieOff2.slv); 
  mkConnection(vWci[3],  tieOff3.slv); 
  mkConnection(vWci[4],  tieOff4.slv); 
  mkConnection(vWci[5],  tieOff5.slv); 
  mkConnection(vWci[6],  tieOff6.slv); 
  mkConnection(vWci[7],  icap.wciS0);    // Worker 8: ICAP
  mkConnection(vWci[8],  flashw.wciS0);  // Worker 9: Flash
  mkConnection(vWci[9],  tieOff9.slv);   // GbE Worker 10
  mkConnection(vWci[10], iqadc.wciS0);   // Worker 11: IQ-ADC
  mkConnection(vWci[11], tieOff11.slv); 
  mkConnection(vWci[12], tieOff12.slv); 
  mkConnection(vWci[13], tieOff13.slv); 
  mkConnection(vWci[14], tieOff14.slv); 

  method    Bit#(5)       led    = ledLogic.led;
  method    Bit#(32)      debug  = {16'h5555, 16'h0000};
  interface Clock         rxclkBnd   = gbe0.rxclkBnd;
  interface Reset         gmii_rstn  = gbe0.gmii_rstn;
  interface GMII          gmii       = gbe0.gmii;
  interface MDIO_Pads     mdio       = gbe0.mdio;
  interface TI62P4X_Pads  adc        = iqadc.adc;
  interface SPIFLASH_Pads flash      = flashw.pads;
  interface Clock         sys0Clk    = sys0_clk;
  interface Reset         sys0Rst    = sys0_rst;
  interface Clock         sys125Clk  = sys125_clk;
  interface Reset         sys125Rst  = sys125_rst;
endmodule: mkFTop_n210

