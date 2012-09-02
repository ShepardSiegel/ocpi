// FTop_n210.bsv - Top Level for N210 OpenCPI Platform
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

// Application Imports...
import ClockN210         ::*;
import LedN210           ::*;
import Config            ::*;
import GMAC              ::*;
import GbeQABS           ::*;
import GbeWrk            ::*;
import IQADCWorker       ::*;
import MDIO              ::*;
import EDCP              ::*;
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
  interface  Clock         sys0Clk;    // So that clk and rst are seen at this i/f bounds...
  interface  Clock         sys1Clk;
  interface  Reset         sys0Rst;
  interface  Reset         sys1Rst;
endinterface: FTop_n210Ifc

(* synthesize, no_default_clock, no_default_reset, clock_prefix="", reset_prefix="" *)
module mkFTop_n210#(Clock sys0_clkp, Clock sys0_clkn,  // 100 MHz Board XO Reference
                    Clock gmii_sysclk,                 // 125 MHz from GbE PHY  - stable clock, once enabled after reset
                    Clock gmii_rx_clk,                 // 125 MHz GMII RX Clock - agile recovered rx clock, when 1Gb link up
                    Clock adc_clkout,                  // CMOS SDR Output Clock from ADC
                    Reset fpga_rstn)                   // FPGA User Reset Pushbutton S2
                    (FTop_n210Ifc);

  // Clocks and Resets...
  Clock            clkIn      <- mkClockIBUFDS(sys0_clkp, sys0_clkn); // 100 MHz Clock and Reset (from ext clock gen device)
  ClockN210Ifc     clkN210    <- mkClockN210(clkIn, fpga_rstn);
  Clock            sys0_clk   = clkN210.clk0;   // 100 MHz system clock 0 
  Reset            sys0_rst   = clkN210.rst0;   // 100 MHz system reset 0 
  Clock            sys1_clk   = clkN210.clkdv;  //  50 MHz system clock 1 
  Reset            sys1_rst   = clkN210.rstdv;  //  50 MHz system reset 1 
  Clock            gmiixo_clk <- mkClockBUFG (clocked_by gmii_sysclk);   // 125 MHz clock from GbE PHY
  Reset            gmiixo_rst <- mkAsyncReset(2, sys0_rst, gmiixo_clk);  // 125 MHz reset from GbE PHY

  // Module Instantiations...
  LedN210Ifc       ledLogic   <- mkLedN210(clocked_by sys1_clk, reset_by sys1_rst);
  GbeQABSIfc       gbe0       <- mkGbeQABS(
                                   True,          // hasDebugLogic
                                   gmii_rx_clk,   // passed down as rxClk (agile from rx)
                                   gmiixo_clk,    // passed down as txClk and (stable after reset) BUFG driven
                                   gmiixo_rst,    // passed down reset, resynced thrrough system reset
                                   clocked_by sys1_clk, reset_by sys1_rst);
  EDCPAdapterIfc   edcp       <- mkEDCPAdapter(clocked_by sys1_clk, reset_by sys1_rst);
  OCCPIfc#(Nwcit)  cp         <- mkOCCP(
                                   ?,             // pciDevice (not used)
                                   sys1_clk,      // time_clk timebase
                                   sys1_rst,      // time_rst reset
                                   clocked_by sys1_clk, reset_by sys1_rst);

  mkConnection(gbe0.client, edcp.server);  // GBE  <-> EDCP
  mkConnection(edcp.client, cp.server);    // EDCP <-> CP

  Vector#(Nwcit, WciEM) vWci = cp.wci_Vm;

  // Make sure when calling out a specific interface, eg xxx4BIfc, you use the non-polymorphic mkXxx4B instance
  // 2012-08-19 odd WSI behavior seen when non-synth, poly module was instanced instead. Should dig deeper.
  //WSIPatternWorker4BIfc  pat0    <- mkWSIPatternWorker4B(True,        clocked_by sys1_clk, reset_by(vWci[5].mReset_n));
  //SMAdapter4BIfc         sma0    <- mkSMAdapter4B(32'h00000002, True, clocked_by sys1_clk, reset_by(vWci[6].mReset_n));

//WciSlaveNullIfc#(32)  tieOff0  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff1  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff2  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff3  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff4  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff5  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff6  <- mkWciSlaveNull;
  PWrk_n210Ifc          pwrk     <- mkPWrk_n210(sys1_rst, clocked_by sys1_clk, reset_by(vWci[7].mReset_n));
//WciSlaveNullIfc#(32)  tieoff8  <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieoff9  <- mkWciSlaveNull;
  GbeWrkIfc             gbewrk   <- mkGbeWrk(True, clocked_by sys1_clk, reset_by(vWci[9].mReset_n));
  IQADCWorkerIfc        iqadc    <- mkIQADCWorker(True, sys1_clk, sys1_rst, sys1_clk, sys1_rst, adc_clkout, clocked_by sys1_clk, reset_by(vWci[10].mReset_n));  // Worker 11 
  //WSICaptureWorker4BIfc cap0     <- mkWSICaptureWorker4B(True,                                              clocked_by sys1_clk, reset_by(vWci[11].mReset_n));  // Worker 12
//WciSlaveNullIfc#(32)  tieOff12 <- mkWciSlaveNull;
//WciSlaveNullIfc#(32)  tieOff13 <- mkWciSlaveNull;
  //OCEDP4BIfc edp0  <- mkOCEDP4B (?,True,True, True, clocked_by sys1_clk, reset_by vWci[13].mReset_n); // Ethernet Data Plane 0
//WciSlaveNullIfc#(32)  tieOff14 <- mkWciSlaveNull;

  //mkConnection(gbe0.dpClient, edp0.server); // Path from dgdp to GbE

  //mkConnection(pat0.wsiM0, sma0.wsiS0, clocked_by sys1_clk, reset_by sys1_rst);     // Connect the PatternWorker to the SMAAdapter
  //mkConnection(sma0.wmiM0, edp0.wmiS0);     // Connect the SMAAdapter to the DGDP WMI slave port

//mkConnection(vWci[0],  tieOff0.slv); 
//mkConnection(vWci[1],  tieOff1.slv); 
//mkConnection(vWci[2],  tieOff2.slv); 
//mkConnection(vWci[3],  tieOff3.slv); 
//mkConnection(vWci[4],  tieOff4.slv); 
  //mkConnection(vWci[5],  pat0.wciS0); 
  //mkConnection(vWci[6],  sma0.wciS0); 
  mkConnection(vWci[7],  pwrk.wciS0);    // N210 Platform Worker
//mkConnection(vWci[8],  tieoff8.slv);   // 

//mkConnection(vWci[9],  tieoff9.slv);   // 
  mkConnection(vWci[9],  gbewrk.wciS0);  // GbE Worker

  //mkConnection(vWci[10], iqadc.wciS0);   // IQ-ADC
  //mkConnection(vWci[11], cap0.wciS0);    // Capture Worker
//mkConnection(vWci[12], tieOff12.slv); 
//mkConnection(vWci[13], tieOff13.slv); 
  //mkConnection(vWci[13], edp0.wciS0);    // EDP0
//mkConnection(vWci[14], tieOff14.slv); 

  mkConnection(pwrk.macAddr, gbe0.macAddr);  // Connect the EEPROM-sourced MAC Addr to the GBE
  //mkConnection(iqadc.wsiM0, cap0.wsiS0);     // Connect the WSI output from the IQ-ADC to the Capture Worker

  //rule send_gbe_stats;
  //  gbewrk.dgdpEgressCnt(gbe0.dgdpEgressCnt);
  //endrule

  // Connect gbewrk values into gbe0...
  (* fire_when_enabled *) 
  rule send_gbe_l2Dst;
    gbe0.l2Dst(gbewrk.l2Dst);
    gbe0.l2Typ(gbewrk.l2Typ);
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
  interface Clock         sys1Clk    = sys1_clk;
  interface Reset         sys0Rst    = sys0_rst;
  interface Reset         sys1Rst    = sys1_rst;
endmodule: mkFTop_n210

