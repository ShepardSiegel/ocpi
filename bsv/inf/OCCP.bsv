// OCCP.bsv
// Copyright (c) 2009,2010,2011,2012 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCCP;

import CPDefs        ::*;
import OCWip         ::*;
import TimeService   ::*;
import TLPMF         ::*;
import Config        ::*;
import CompileTime   ::*;
import DNA           ::*;
import PCIE          ::*;

import BRAM::*;
import DefaultValue::*;
import DReg::*;	
import FIFO::*;
import FIFOF::*;
import FixedPoint::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import StmtFSM::*;
import Vector::*;


typedef struct {
  Bit#(4)  bar;     // The PCIe BAR that this memory region belong to
  Bit#(14) offset;  // Offset into this PCIe BAR, in 4KB pages
  Bit#(14) size;    // Size of this memory region, in 4KB pages
} DPMemRegion deriving (Bits, Eq);

DPMemRegion dpMemRegion0 = DPMemRegion {bar:1, offset:0, size:8};  // Bar 1, Offset 0,    Size 32 KB
DPMemRegion dpMemRegion1 = DPMemRegion {bar:1, offset:8, size:8};  // Bar 1, Offset 32KB, Size 32 KB

//
// OpenCPI Control Plane Interface 
//
// nWci - number of Wci Worker Control Links  (1st worker is worker 0)
//
interface OCCPIfc#(numeric type nWci);
  interface Server#(CpReq,CpReadResp) server;
  interface Vector#(nWci,WciEM)  wci_Vm;
  method    GPS64_t   cpNow;
  interface GPSIfc    gps;
  (* always_ready *)                 method Bit#(2) led;
  (* always_ready, always_enabled *) method Action  switch (Bit#(3) x);
  (* always_ready, always_enabled *) method Action  uuid   (Bit#(512) arg);
endinterface

typedef union tagged {
  void Idle;
  struct {WCI_SPACE sp; DWord wData; Bit#(24) bAddr; Bit#(4) be;} AdminWt;
  struct {WCI_SPACE sp; Bit#(8) tag; Bit#(24) bAddr; Bit#(4) be;} AdminRd;
  struct {WCI_SPACE sp; DWord wData; Bit#(24) bAddr; Bit#(4) be;} WrkWt;
  struct {WCI_SPACE sp; Bit#(8) tag; Bit#(24) bAddr; Bit#(4) be;} WrkRd;
} CPReq deriving (Bits);


(* synthesize *)
module mkOCCP#(PciId pciDevice, Clock time_clk, Reset time_rst) (OCCPIfc#(Nwcit));

  FIFO#(CpReq)      cpReqF       <- mkFIFO;                  // Inbound  Requests
  FIFO#(CpReadResp) cpRespF      <- mkFIFO;                  // Outbound Responses

  Reg#(CPReq)       cpReq        <-  mkReg(tagged Idle);     // reqeust pending
  Reg#(Bool)        dispatched   <-  mkReg(False);           // Set when current cpReq is dispatched
  Reg#(Bit#(4))     wrkAct       <-  mkReg(0);               // Number of Active Worker
  Reg#(DWord)       scratch20    <-  mkReg(0);               // Scratch register at 0x20
  Reg#(DWord)       scratch24    <-  mkReg(0);               // Scratch register at 0x24
  Reg#(DWord)       cpControl    <-  mkReg(0);               // 32b for cpControl
  Reg#(Bit#(32))    td           <-  mkRegU;                 // Temp DW used for 8B writes
  Reg#(UInt#(32))   readCntReg   <-  mkReg(0);               // Read side-effect register
//Reg#(DWord)       msiAddrMs    <-  mkRegU;                 // PCIe MSI Address MS [63:32]
//Reg#(DWord)       msiAddrLs    <-  mkRegU;                 // PCIe MSI Address LS [31:2],2'b0
//Reg#(Bit#(16))    msiMesgD     <-  mkRegU;                 // PCIe MSI Message Data
  Reg#(UInt#(4))    rogueTLP     <-  mkReg(0);               // Running count of unhandled TLPs
  Reg#(Bit#(3))     switch_d     <-  mkRegU;                 // Debounce switch 
  Reg#(Bool)        warmResetP   <-  mkDReg(False);          // Warm Reset Pulse

`ifdef ALTERA_100MHZ_SYS0CLK
  TSMParams altera100 = TSMParams {curFreq:125e6, refFreq: 100e6};  // Altera alst4 has 100 MHz time clk
  TimeServerIfc     timeServ     <-  mkTimeServer(altera100,    time_clk, time_rst); // Instance the Time Server
`else
  TimeServerIfc     timeServ     <-  mkTimeServer(defaultValue, time_clk, time_rst); // Instance the Time Server
`endif

  Reg#(GPS64_t)     deltaTime    <-  mkReg(0.0);
  Wire#(Bit#(64))   deviceDNA    <-  mkDWire(64'h0badc0de_0badc0de);
  Wire#(Vector#(2,Bit#(32))) devDNAV <- mkWire;              // devDNA as a Vector of 2  32b DWORDs
  Reg#(Bit#(8))     seqTag       <-  mkRegU;                 // sequential, single-threaded, tag storage 
  FIFOF#(DWordM)    adminResp1F  <-  mkFIFOF1;               // Admin region read-response FIFO - region 1
  FIFOF#(DWordM)    adminResp2F  <-  mkFIFOF1;               // Admin region read-response FIFO - region 2
  FIFOF#(DWordM)    adminResp3F  <-  mkFIFOF1;               // Admin region read-response FIFO - region 3
  FIFOF#(DWordM)    adminResp4F  <-  mkFIFOF1;               // Admin region read-response FIFO - region 4
  FIFO#(DWordM)     adminRespF   <-  mkFIFO1;                // Admin region read-response FIFO - aggregate

  BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 1024;  // Number of DWORD entries in 4KB ROM
    cfg.latency    = 1;
    cfg.loadFormat = tagged Hex "ramprom.data";
  BRAM1Port#(Bit#(10), Bit#(32)) rom <- mkBRAM1Server(cfg);

`ifdef HAS_DEVICE_DNA
  DNAIfc dna <- mkDNA; // Instance the device DNA reader core if we have one
  rule assign_deviceDNA;
    deviceDNA <= extend(dna.deviceID);
  endrule
`endif
  rule assign_devDNAV;
    devDNAV <= unpack(deviceDNA); // place 64b in 2 DWORD structure
  endrule

  Wire#(Vector#(16, Bit#(32))) uuidV   <- mkWire; // uuid   as a Vector of 16 32b DWORDs

  function makeWciMaster (Integer i);
    //return (i<5||i>12) ? mkWciMaster : mkWciMasterNull;  // only instance the 7 (0:4,13:14) we need
    //return (i<6||i>9) ? mkWciMaster : mkWciMasterNull;  // only instance the 11 (0:5,10:14)  we need

    //FIXME: Specalized for n210 platform development!
    //return (i<7||i>11) ? mkWciMasterNull : mkWciMaster;  
    //if (i==5 || i==6 || i==7 || i==9 || i==10 || i==13) return mkWciMaster;   // uSed for CP + DP
    if ( i==7 || i==9 ) return mkWciMaster;   // sls used with 20120908_1121 for emux debug testing
    else return mkWciMasterNull;

    //return  mkWciMaster; // all get WCI masters
  endfunction
  Vector#(Nwcit,WciMasterIfc#(20,32)) wci <- genWithM(makeWciMaster);  

  Bit#(Nwcit)  wrkAttn;
  for (Integer i=0; i<iNwcit; i=i+1) wrkAttn[i]    = pack(wci[i].attn);

  Bit#(Nwcit)  wrkPresent;
  for (Integer i=0; i<iNwcit; i=i+1) wrkPresent[i] = pack(wci[i].present);

  DWord cpRevision  = 32'h0000_0001;
  DWord cpBirthday  = compileTime;
  DWord cpStatus    = extend(pack(rogueTLP));


  function Action setAdminReg(Bit#(8) bAddr, DWord wd);
  action
    case (bAddr)
      'h20 : scratch20    <= wd;
      'h24 : scratch24    <= wd;
      'h28 : cpControl    <= wd;
      'h2C : warmResetP   <= (wd == 32'hC0DE_FFFF);
      
       // TimeServer Set Actions...
      'h34 : timeServ.setControl(wd);
      'h38 : td <= wd;
      'h3C : timeServ.setTime(fxptFromIntFrac(unpack(td),unpack(wd)));
      'h40 : td <= wd;
      'h44 : deltaTime <= timeServ.gpsTimeCC - fxptFromIntFrac(unpack(td),unpack(wd));

      'h4C : readCntReg   <= unpack(wd);

    endcase
    cpReq  <= tagged Idle;
    //$display("[%0d]: %m: setAdminReg WRITE-RETIRED Addr:%0x Data:%0x", $time, bAddr, wd);
  endaction
  endfunction


  function Action reqWorker(WCI_SPACE sp, Bool write, Bit#(24) bAddr, DWord wd, Bit#(4) be);
  action
    Bit#(4)         wn = bAddr[19:16] - 1;
    if (sp==Config) wn = bAddr[23:20] - 1;
    wci[wn].req(sp, write, truncate(bAddr), wd, be);
    wrkAct <= wn;
    if (write) $display("[%0d]: %m: reqWorker WRITE-POSTED   Worker:%0d sp:%x Addr:%0x Data:%0x BE:%0x", $time, wn, pack(sp), bAddr, wd, be);
    else       $display("[%0d]: %m: reqWorker READ-REQUESTED Worker:%0d sp:%x Addr:%0x BE:%0x", $time, wn, pack(sp), bAddr, be);
  endaction
  endfunction

  // To avoid congestion of a largish N:1 32b multiplexer, we have split the Admin read into three
  // groups each less than about 16:1 . This elastic registered result is then collected in a 3:1 merge 

  function Action getAdminReg1(Bit#(8) bAddr); 
  action
    DWordM rv = Invalid;
    case (bAddr)
      'h00 : rv = Valid(32'h_4F_70_65_6E);                      // Open
      'h04 : rv = Valid(32'h_43_50_49_00);                      // CPI
      'h08 : rv = Valid(cpRevision);                            // IP Revsion Code
      'h0C : rv = Valid(cpBirthday);                            // Compile Epoch
      'h10 : rv = Valid(extend(wrkPresent));                    // Bitmask of Present Workers (1=present)
      'h14 : rv = Valid(extend(pack(pciDevice)));               // Assigned PCI device ID
      'h18 : rv = Valid(extend(wrkAttn));                       // Worker Attention
      'h1C : rv = Valid(cpStatus);                              // CP status
      'h20 : rv = Valid(scratch20);                             // Scratch register
      'h24 : rv = Valid(scratch24);                             // Scratch register
      'h28 : rv = Valid(cpControl);                             // Cp control
      'h2C : rv = Valid(0);
      default: rv = Invalid;
    endcase
    adminResp1F.enq(rv);
  endaction
  endfunction

  function Action getAdminReg2(Bit#(8) bAddr);
  action
    DWordM rv = Invalid;
    case (bAddr)
      'h30 : rv = Valid(timeServ.getStatus);                    // rplTimeStatus
      'h34 : rv = Valid(timeServ.getControl);                   // rplTimeControl
      'h38 : rv = Valid(pack(fxptGetInt (timeServ.gpsTimeCC))); // Time Integer Seconds
      'h3C : rv = Valid(pack(fxptGetFrac(timeServ.gpsTimeCC))); // Time Fractional Seconds
      'h40 : rv = Valid(pack(fxptGetInt(deltaTime)));           // Measured deltaTime Integer Seconds
      'h44 : rv = Valid(pack(fxptGetFrac(deltaTime)));          // Measured deltaTime Fractional Seconds
      'h48 : rv = Valid(pack(timeServ.tRefPerPps));             // rplTimeRefPerPPS (frequency counter)
      'h4C : begin rv = Valid(pack(readCntReg)); readCntReg<=readCntReg+1; end // Read side effect register
      'h50 : rv = Valid(pack(devDNAV[0]));                      // LSBs of devDNA
      'h54 : rv = Valid(pack(devDNAV[1]));                      // MSBs of devDNA
      'h7C : rv = Valid(32'd2);                                 // DP Mem Region Descriptors...
      'h80 : rv = Valid(pack(dpMemRegion0));  
      'h84 : rv = Valid(pack(dpMemRegion1));  
      default: rv = Invalid;
    endcase
    adminResp2F.enq(rv);
  endaction
  endfunction

  function Action getAdminReg3(Bit#(8) bAddr);
  action
    Bit#(6) dwAddr = truncate(bAddr>>2);
    DWordM rv = Invalid;
    case (bAddr)
      'hC0,'hC4,'hC8,'hCC,'hD0,'hD4,'hD8,'hDC,'hE0,'hE4,'hE8,'hEC,'hF0,'hF4,'hF8,'hFC : begin 
         Bit#(4) dwIdx = truncate(dwAddr);
         rv =  Valid(pack(reverse(uuidV)[dwIdx]));
       end
      default: rv = Invalid;
    endcase
    adminResp3F.enq(rv);
  endaction
  endfunction

  rule response_rom_read;
    DWordM rv = Invalid;
    let r <- rom.portA.response.get;
    rv = Valid(r);
    adminResp4F.enq(rv);
  endrule

  function Action requestAdminRd(Bit#(24) bAddr, Bit#(8) tag);
  action
    seqTag <= tag;  // Set tag aside for response - Implicit single-issue of reads
    if (bAddr < 24'h00_0100) begin
      Bit#(8) a = truncate(bAddr);
      if      (a <  8'h30)                getAdminReg1(a);
      else if (a >= 8'h30 && a < 8'hC0)   getAdminReg2(a);
      else                                getAdminReg3(a);
    end else if (bAddr >= 24'h00_01000) begin
       rom.portA.request.put(BRAMRequest {write:False, responseOnWrite:False, address:bAddr[11:2], datain:0});
    end
  endaction
  endfunction

  rule readAdminResponseCollect;
    if      (adminResp1F.notEmpty) begin adminRespF.enq(adminResp1F.first); adminResp1F.deq; end
    else if (adminResp2F.notEmpty) begin adminRespF.enq(adminResp2F.first); adminResp2F.deq; end
    else if (adminResp3F.notEmpty) begin adminRespF.enq(adminResp3F.first); adminResp3F.deq; end
    else if (adminResp4F.notEmpty) begin adminRespF.enq(adminResp4F.first); adminResp4F.deq; end
  endrule

  rule responseAdminRd;
    DWordM arr = adminRespF.first; adminRespF.deq;  // Pop the admin response collection FIFO
    CpReadResp crr = CpReadResp { tag:seqTag, data:fromMaybe(32'hDEAD_C0DE, arr) };  // use tag from seqTag
    cpRespF.enq(crr);
    cpReq  <= tagged Idle;
  endrule

  function WCI_SPACE decodeCP(Bit#(22) dwAddr); // 16MB CP Decode Policy
    if      (dwAddr[21:14]=='0) return(Admin);
    else if (dwAddr[21:18]=='0) return(Control);
    else                        return(Config);
  endfunction

  (* descending_urgency = "reqRcv, cpDispatch, completeWorkerWrite, completeWorkerRead" *)

  rule cpDispatch (!dispatched);
    (* split *)
    case (cpReq) matches
      tagged AdminWt {wData:.wd, bAddr:.ba}:  setAdminReg(truncate(ba),  wd); 
      tagged AdminRd  {tag:.tag, bAddr:.ba}:  requestAdminRd(ba, tag);
      tagged WrkWt   {sp:.s, wData:.wd, bAddr:.ba, be:.be}:  reqWorker(s, True,  ba, wd, be);
      tagged WrkRd   {sp:.s, tag:.tag,  bAddr:.ba, be:.be}:  reqWorker(s, False, ba, ?,  be);
    endcase
    dispatched <= True;
  endrule

  rule completeWorkerWrite (cpReq matches tagged WrkWt .x );
    let r <- wci[wrkAct].resp;
    wrkAct <= 0;
    cpReq  <= tagged Idle;
    //$display("[%0d]: %m: Worker:%0x write acknowledged" , $time, wrkAct);
  endrule

  rule completeWorkerRead (cpReq matches tagged WrkRd .x );
    let r <- wci[wrkAct].resp;
    DWord rtnData = r.data;
    CpReadResp crr = CpReadResp { tag:x.tag, data:rtnData };
    cpRespF.enq(crr);
    wrkAct <= 0;
    cpReq  <= tagged Idle;
    //$display("[%0d]: %m: Worker:%0x read data received:%0x" , $time, wrkAct, rtnData);
  endrule

  rule reqRcv (cpReq matches tagged Idle);
    CpReq cpri = cpReqF.first; cpReqF.deq;
    if (cpri matches tagged WriteRequest .x ) begin
      case (decodeCP(x.dwAddr))
        Admin:   cpReq <= tagged AdminWt {sp:Admin,   wData:x.data, bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn}; 
        Control: cpReq <= tagged WrkWt   {sp:Control, wData:x.data, bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn}; 
        Config:  cpReq <= tagged WrkWt   {sp:Config,  wData:x.data, bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn};
      endcase
    end
    if (cpri matches tagged ReadRequest .x ) begin
      case (decodeCP(x.dwAddr))
        Admin:   cpReq <= tagged AdminRd {sp:Admin,   tag:x.tag,    bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn};
        Control: cpReq <= tagged WrkRd   {sp:Control, tag:x.tag,    bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn}; 
        Config:  cpReq <= tagged WrkRd   {sp:Config,  tag:x.tag,    bAddr:truncate({x.dwAddr,2'b0}), be:x.byteEn};
      endcase
    end
    dispatched <= False;
  endrule

  function Wci_m#(32) get_wci_Em (WciMasterIfc#(20,32) i) = i.mas;

  function makeWciExpander (Integer i);
    return  mkWciMtoEm(wci[i].mas); 
  endfunction
  Vector#(Nwcit,WciEM) wci_Emv <- genWithM(makeWciExpander);  

  interface Server server; 
    interface request  = toPut(cpReqF);
    interface response = toGet(cpRespF);
  endinterface
  method GPS64_t cpNow = timeServ.gpsTime;
  interface GPSIfc gps = timeServ.gps;
  //interface Vector wci_Em = map(get_wci_Em, wci);
  interface Vector wci_Vm = wci_Emv;
  method led       = scratch24[1:0];
  method Action  switch    (Bit#(3) x);     switch_d <= x;           endmethod
  method Action  uuid      (Bit#(512) arg); uuidV   <= unpack(arg);  endmethod

endmodule: mkOCCP
endpackage: OCCP
