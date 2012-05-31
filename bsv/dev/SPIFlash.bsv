// SPIFlash.bsv - BSV code to provide SPI-Flash memory access functionality
// Copyright (c) 2010,2011,2012  Atomic Rules LCC ALL RIGHTS RESERVED

// Notes
// M25P32 has
//  + 4 MB (8b each)
//  + 64 sectors (512Kb, 64KB each)
//  + 16K pages (256B each)
// Suggested Map:
// Sectors 0-31 bottom: 0-23  (24 sectors) bitstream 0 ; sector 24-31 user 0 
// Sectors 32-63 top:   32-55 (24 sectors) bitstream 1 ; sector 56-63 user 1

package SPIFlash;

import Connectable       ::*;
import DReg              ::*;
import GetPut            ::*;
import FIFO              ::*;
import StmtFSM           ::*;

typedef struct {
  Bool      isRead; // request is read
  Bit#(20)  addr;   // 4-Byte (DWORD) memory address
  Bit#(32)  data;   // write data
 } SPIFlashReq deriving (Bits);

(* always_enabled, always_ready *)  // IO pads connected to the SPI flash device...
interface SPIFLASH_Pads;
  method  Action              miso (Bool i);  // Flash Q to FPGA in  (master-input,  slave-output)
  method  Bool                mosi;           // FPGA out to FLASH D (master-output, slave-input)
  method  Bool                clk;            // FLASH serial clock
  method  Bool                cs_n;           // FLASH Chip Select (active-low)
  method  Bool                wp_n;           // FLASH Write Protect 
endinterface: SPIFLASH_Pads

interface SPIFLASH_User;
  interface Put#(SPIFlashReq)  request;
  interface Get#(Bit#(32))     response;
  method Bool                  waitBit;
endinterface: SPIFLASH_User

interface SPIFlashIfc;
  interface SPIFLASH_Pads      flash;
  interface SPIFLASH_User      user;
endinterface: SPIFlashIfc

module mkSPIFlash (SPIFlashIfc);

  FIFO#(SPIFlashReq)   reqF      <- mkFIFO;
  FIFO#(Bit#(32))      respF     <- mkFIFO;
  Reg#(Bool)           misoReg   <- mkRegU; 
  Reg#(Bool)           mosiReg   <- mkDReg(False); 
  Reg#(Bool)           clkReg    <- mkDReg(False); 
  Reg#(Bool)           csReg     <- mkDReg(False); 
  Reg#(Bool)           wpReg     <- mkDReg(False); 
  Reg#(Bool)           waitReg   <- mkReg(False); 

  interface SPIFLASH_Pads flash;
    method  Action miso (Bool i) = misoReg._write(i);
    method  Bool   mosi = mosiReg;
    method  Bool   clk  = clkReg;
    method  Bool   cs_n = !csReg;
    method  Bool   wp_n = !wpReg;
  endinterface

  interface SPIFLASH_User user;
    interface Put  request      = toPut(reqF);
    interface Get  response     = toGet(respF);
    method    Bool waitBit      = waitReg;
  endinterface

endmodule: mkSPIFlash

endpackage: SPIFlash
