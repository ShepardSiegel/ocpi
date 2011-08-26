// OCCP.bsv
// Copyright (c) 2009,2010,2011 Atomic Rules LLC - ALL RIGHTS RESERVED

package OCCP;

import OCWip::*;
import TimeService::*;
import TLPMF::*;
import TLPSerializer::*;
import Config::*;
import CompileTime::*;
import DNA::*;
import PCIE::*;

import DefaultValue::*;
import DReg::*;	
import FIFO::*;
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
  interface Server#(PTW16,PTW16) server;
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
module mkOCCP#(PciId pciDevice, Clock sys0_clk, Reset sys0_rst) (OCCPIfc#(Nwcit));

  TLPSerializerIfc  tlp  <- mkTLPSerializer(pciDevice);       // TLP-facing DW serializer
  Reg#(CPReq)       cpReq        <- mkReg(tagged Idle);       // reqeust pending
  Reg#(Bool)        dispatched   <- mkReg(False);             // Set when current cpReq is dispatched
  Reg#(Bit#(4))     wrkAct       <- mkReg(0);                 // Number of Active Worker
  Reg#(DWord)       scratch20    <- mkReg(0);                 // Scratch register at 0x20
  Reg#(DWord)       scratch24    <- mkReg(0);                 // Scratch register at 0x24
  Reg#(DWord)       cpControl    <- mkReg(0);                 // 32b for cpControl
  Reg#(Bit#(32))    td           <- mkRegU;                   // Temp DW used for 8B writes
  //Reg#(DWord)       msiAddrMs    <- mkRegU;                   // PCIe MSI Address MS [63:32]
  //Reg#(DWord)       msiAddrLs    <- mkRegU;                   // PCIe MSI Address LS [31:2],2'b0
  //Reg#(Bit#(16))    msiMesgD     <- mkRegU;                   // PCIe MSI Message Data
  Reg#(UInt#(4))    rogueTLP     <- mkReg(0);                 // Running count of unhandled TLPs
  Reg#(Bit#(3))     switch_d     <- mkRegU;                   // Debounce switch 
  TimeServerIfc     timeServ     <- mkTimeServer(defaultValue, sys0_clk, sys0_rst); // Instance the Time Server
  Reg#(GPS64_t)     deltaTime    <- mkReg(0.0);

  Wire#(Bit#(64))   deviceDNA    <-mkDWire(64'h0badc0de_0badc0de);
  Wire#(Vector#(2,  Bit#(32))) devDNAV <- mkWire; // devDNA as a Vector of 2  32b DWORDs

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
    return  mkWciMaster; // all get WCI masters
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
      
       // TimeServer Set Actions...
      'h34 : timeServ.setControl(wd);
      'h38 : td <= wd;
      'h3C : timeServ.setTime(fxptFromIntFrac(unpack(td),unpack(wd)));
      'h40 : td <= wd;
      'h44 : deltaTime <= timeServ.gpsTimeCC - fxptFromIntFrac(unpack(td),unpack(wd));

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

  function Maybe#(DWord) getAdminReg(Bit#(8) bAddr);
    Bit#(6) dwAddr = truncate(bAddr>>2);
    case (bAddr)
      'h00 : return Valid(32'h_4F_70_65_6E);          // Open
      'h04 : return Valid(32'h_43_50_49_00);          // CPI
      'h08 : return Valid(cpRevision);                // IP Revsion Code
      'h0C : return Valid(cpBirthday);                // Compile Epoch
      'h10 : return Valid(extend(wrkPresent));        // Bitmask of Present Workers (1=present)
      'h14 : return Valid(extend(pack(pciDevice)));   // Assigned PCI device ID
      'h18 : return Valid(extend(wrkAttn));           // Worker Attention
      'h1C : return Valid(cpStatus);                  // CP status
      'h20 : return Valid(scratch20);                 // Scratch register
      'h24 : return Valid(scratch24);                 // Scratch register
      'h28 : return Valid(cpControl);                 // Cp control
      'h2C : return Valid(0);

       // TimeServer Get Actions...
      'h30 : return Valid(timeServ.getStatus);                    // rplTimeStatus
      'h34 : return Valid(timeServ.getControl);                   // rplTimeControl
      'h38 : return Valid(pack(fxptGetInt (timeServ.gpsTimeCC))); // Time Integer Seconds
      'h3C : return Valid(pack(fxptGetFrac(timeServ.gpsTimeCC))); // Time Fractional Seconds
      'h40 : return Valid(pack(fxptGetInt(deltaTime)));           // Measured deltaTime Integer Seconds
      'h44 : return Valid(pack(fxptGetFrac(deltaTime)));          // Measured deltaTime Fractional Seconds
      'h48 : return Valid(pack(timeServ.tRefPerPps));             // rplTimeRefPerPPS (frequency counter)

      'h50 : return Valid(pack(devDNAV[0]));          // LSBs of devDNA
      'h54 : return Valid(pack(devDNAV[1]));          // MSBs of devDNA

      'h7C : return Valid(32'd2);
      'h80 : return Valid(pack(dpMemRegion0));  
      'h84 : return Valid(pack(dpMemRegion1));  

      'hC0,'hC4,'hC8,'hCC,'hD0,'hD4,'hD8,'hDC,'hE0,'hE4,'hE8,'hEC,'hF0,'hF4,'hF8,'hFC : begin 
         Bit#(4) dwIdx = truncate(dwAddr);
         return Valid(pack(reverse(uuidV)[dwIdx]));
       end

      default: return Invalid;
    endcase
  endfunction

  function Action completeAdminRd(Bit#(24) bAddr, Bit#(8) tag);
  action
    DWord rtnData = fromMaybe(32'hDEAD_C0DE, getAdminReg(truncate(bAddr)));
    CpReadResp crr = CpReadResp { tag:tag, data:rtnData };
    tlp.client.response.put(crr);
    cpReq  <= tagged Idle;
  endaction
  endfunction

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
      tagged AdminRd  {tag:.tag, bAddr:.ba}:  completeAdminRd(ba, tag);
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
    tlp.client.response.put(crr);
    wrkAct <= 0;
    cpReq  <= tagged Idle;
    //$display("[%0d]: %m: Worker:%0x read data received:%0x" , $time, wrkAct, rtnData);
  endrule

  rule reqRcv (cpReq matches tagged Idle);
    CpReq cpri <- tlp.client.request.get;
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

  interface Server server = tlp.server;
  method GPS64_t cpNow = timeServ.gpsTime;
  interface GPSIfc gps = timeServ.gps;
  //interface Vector wci_Em = map(get_wci_Em, wci);
  interface Vector wci_Vm = wci_Emv;
  method led       = scratch24[1:0];
  method Action  switch    (Bit#(3) x);     switch_d <= x;           endmethod
  method Action  uuid      (Bit#(512) arg); uuidV   <= unpack(arg);  endmethod

endmodule: mkOCCP
endpackage: OCCP
