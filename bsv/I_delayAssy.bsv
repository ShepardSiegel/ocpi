// THIS FILE WAS GENERATED ON Fri May  7 16:41:37 2010 EDT
// YOU PROBABLY SHOULD NOT EDIT IT
// This file contains the BSV declarations for the worker with
//  spec name "delayAssy" and implementation name "delayAssy".
// It is needed for instantiating the worker in BSV.
// Interface signal names are defined with suffix rule: "_"

package I_delayAssy; // Package name is the implementation name of the worker

import OCWip::*; // Include the OpenCPI BSV WIP package

import Vector::*;
// Define parameterized types for each worker port
//  with parameters derived from WIP attributes

// For worker interfaces named "wci0" to "wci2" WIP Attributes are:
// SizeOfConfigSpace: 1048576 (0x100000)
typedef Wci_Es#(20) I_wci0;
typedef Wci_Es#(20) I_wci1;
typedef Wci_Es#(20) I_wci2;
// For worker interface named "wmemi0" WIP Attributes are:
// DataWidth: 128
// MemoryWords: 4294967296 (0x100000000)
// ByteWidth: 8
// MaxBurstLength: 4095
typedef Wmemi_Em#(36,12,128,16) I_wmemi0;
// For worker interface named "adc" WIP Attributes are:
// DataValueWidth: 8
// MaxMessageValues: 16380
// ZeroLengthMessages: true
// NumberOfOpcodes: 256
// DataWidth: 32
typedef Wsi_Es#(12,32,4,8,0) I_adc;
// For worker interface named "dac" WIP Attributes are:
// DataValueWidth: 8
// MaxMessageValues: 16380
// ZeroLengthMessages: true
// NumberOfOpcodes: 256
// DataWidth: 32
typedef Wsi_Em#(12,32,4,8,0) I_dac;
// For worker interface named "FC" WIP Attributes are:
// DataValueWidth: 8
// MaxMessageValues: 16380
// ZeroLengthMessages: true
// NumberOfOpcodes: 256
// DataWidth: 32
typedef Wmi_Em#(14,12,32,0,4,32) I_FC;
// For worker interface named "FP" WIP Attributes are:
// DataValueWidth: 8
// MaxMessageValues: 16380
// ZeroLengthMessages: true
// NumberOfOpcodes: 256
// DataWidth: 32
typedef Wmi_Em#(14,12,32,0,4,32) I_FP;

// Define the wrapper module around the real verilog module "delayAssy"
interface VdelayAssyIfc;
  // First define the various clocks so they can be used in BSV across the OCP interfaces
  interface I_wci0 i_wci0;
  interface I_wci1 i_wci1;
  interface I_wci2 i_wci2;
  interface I_wmemi0 i_wmemi0;
  interface I_adc i_adc;
  interface I_dac i_dac;
  interface I_FC i_FC;
  interface I_FP i_FP;
endinterface: VdelayAssyIfc

// Use importBVI to bind the signal names in the verilog to BSV methods
import "BVI" delayAssy =
module vMkdelayAssy #(Clock i_wciClk, Vector#(3,Reset) i_wciRst) (VdelayAssyIfc);

  default_clock no_clock;
  default_reset no_reset;

  // Input clocks on specific worker interfaces
  input_clock  i_wciClk(wci_Clk) = i_wciClk;
  // Interface "wmemi0" uses clock on interface "wci"
  // Interface "adc" uses clock on interface "wci"
  // Interface "dac" uses clock on interface "wci"
  // Interface "FC" uses clock on interface "wci"
  // Interface "FP" uses clock on interface "wci"

  // Reset inputs for worker interfaces that have one
  input_reset  i_wci0Rst(wci0_MReset_n) = i_wciRst[0];
  input_reset  i_wci1Rst(wci1_MReset_n) = i_wciRst[1];
  input_reset  i_wci2Rst(wci2_MReset_n) = i_wciRst[2];

interface I_wci0 i_wci0;
  method mAddr (wci0_MAddr) enable((*inhigh*)en0) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method mAddrSpace (wci0_MAddrSpace) enable((*inhigh*)en1) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method mByteEn (wci0_MByteEn) enable((*inhigh*)en2) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method mCmd (wci0_MCmd) enable((*inhigh*)en3) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method mData (wci0_MData) enable((*inhigh*)en4) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method mFlag (wci0_MFlag) enable((*inhigh*)en5) clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method wci0_SData sData clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method wci0_SFlag sFlag clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method wci0_SResp sResp clocked_by(i_wciClk) reset_by(i_wci0Rst);
  method wci0_SThreadBusy sThreadBusy clocked_by(i_wciClk) reset_by(i_wci0Rst);
endinterface: i_wci0

interface I_wci1 i_wci1;
  method mAddr (wci1_MAddr) enable((*inhigh*)en6) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method mAddrSpace (wci1_MAddrSpace) enable((*inhigh*)en7) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method mByteEn (wci1_MByteEn) enable((*inhigh*)en8) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method mCmd (wci1_MCmd) enable((*inhigh*)en9) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method mData (wci1_MData) enable((*inhigh*)en10) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method mFlag (wci1_MFlag) enable((*inhigh*)en11) clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method wci1_SData sData clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method wci1_SFlag sFlag clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method wci1_SResp sResp clocked_by(i_wciClk) reset_by(i_wci1Rst);
  method wci1_SThreadBusy sThreadBusy clocked_by(i_wciClk) reset_by(i_wci1Rst);
endinterface: i_wci1

interface I_wci2 i_wci2;
  method mAddr (wci2_MAddr) enable((*inhigh*)en12) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method mAddrSpace (wci2_MAddrSpace) enable((*inhigh*)en13) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method mByteEn (wci2_MByteEn) enable((*inhigh*)en14) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method mCmd (wci2_MCmd) enable((*inhigh*)en15) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method mData (wci2_MData) enable((*inhigh*)en16) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method mFlag (wci2_MFlag) enable((*inhigh*)en17) clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method wci2_SData sData clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method wci2_SFlag sFlag clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method wci2_SResp sResp clocked_by(i_wciClk) reset_by(i_wci2Rst);
  method wci2_SThreadBusy sThreadBusy clocked_by(i_wciClk) reset_by(i_wci2Rst);
endinterface: i_wci2


interface I_wmemi0 i_wmemi0;
  method wmemi0_MAddr mAddr clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MBurstLength mBurstLength clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MCmd mCmd clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MData mData clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MDataByteEn mDataByteEn clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MDataLast mDataLast clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MDataValid mDataValid clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MReqLast mReqLast clocked_by(i_wciClk) reset_by(no_reset);
  method wmemi0_MReset_n mReset_n clocked_by(i_wciClk) reset_by(no_reset);
  method sCmdAccept () enable(wmemi0_SCmdAccept) clocked_by(i_wciClk) reset_by(no_reset);
  method sData (wmemi0_SData) enable((*inhigh*)en18) clocked_by(i_wciClk) reset_by(no_reset);
  method sDataAccept () enable(wmemi0_SDataAccept) clocked_by(i_wciClk) reset_by(no_reset);
  method sResp (wmemi0_SResp) enable((*inhigh*)en19) clocked_by(i_wciClk) reset_by(no_reset);
  method sRespLast () enable(wmemi0_SRespLast) clocked_by(i_wciClk) reset_by(no_reset);
endinterface: i_wmemi0

interface I_adc i_adc;
  method mBurstLength (adc_MBurstLength) enable((*inhigh*)en20) clocked_by(i_wciClk) reset_by(no_reset);
  method mByteEn (adc_MByteEn) enable((*inhigh*)en21) clocked_by(i_wciClk) reset_by(no_reset);
  method mCmd (adc_MCmd) enable((*inhigh*)en22) clocked_by(i_wciClk) reset_by(no_reset);
  method mData (adc_MData) enable((*inhigh*)en23) clocked_by(i_wciClk) reset_by(no_reset);
  method mDataInfo     (adc_MDataInfo)      enable((*inhigh*)en332) clocked_by(i_wciClk) reset_by(no_reset);
  method mBurstPrecise () enable(adc_MBurstPrecise) clocked_by(i_wciClk) reset_by(no_reset);
  method mReqInfo (adc_MReqInfo) enable((*inhigh*)en24) clocked_by(i_wciClk) reset_by(no_reset);
  method mReqLast () enable(adc_MReqLast) clocked_by(i_wciClk) reset_by(no_reset);
  method mReset_n () enable(adc_MReset_n) clocked_by(i_wciClk) reset_by(no_reset);
  method adc_SReset_n sReset_n clocked_by(i_wciClk) reset_by(no_reset);
  method adc_SThreadBusy sThreadBusy clocked_by(i_wciClk) reset_by(no_reset);
endinterface: i_adc

interface I_dac i_dac;
  method dac_MBurstLength mBurstLength clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MByteEn mByteEn clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MCmd mCmd clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MData mData clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MDataInfo     mDataInfo  clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MBurstPrecise mBurstPrecise clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MReqInfo mReqInfo clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MReqLast mReqLast clocked_by(i_wciClk) reset_by(no_reset);
  method dac_MReset_n mReset_n clocked_by(i_wciClk) reset_by(no_reset);
  method sReset_n () enable(dac_SReset_n) clocked_by(i_wciClk) reset_by(no_reset);
  method sThreadBusy () enable(dac_SThreadBusy) clocked_by(i_wciClk) reset_by(no_reset);
endinterface: i_dac

interface I_FC i_FC;
  method FC_MAddr mAddr clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MAddrSpace mAddrSpace clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MBurstLength mBurstLength clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MCmd mCmd clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MData mData clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MDataInfo    mDataInfo   clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MDataByteEn mDataByteEn clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MDataLast mDataLast clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MDataValid mDataValid clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MFlag mFlag clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MReqInfo mReqInfo clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MReqLast mReqLast clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MReset_n mReset_n clocked_by(i_wciClk) reset_by(no_reset);
  method sData (FC_SData) enable((*inhigh*)en25) clocked_by(i_wciClk) reset_by(no_reset);
  method sDataThreadBusy () enable(FC_SDataThreadBusy) clocked_by(i_wciClk) reset_by(no_reset);
  method sFlag (FC_SFlag) enable((*inhigh*)en26) clocked_by(i_wciClk) reset_by(no_reset);
  method sResp (FC_SResp) enable((*inhigh*)en27) clocked_by(i_wciClk) reset_by(no_reset);
  method sRespLast () enable(FC_SRespLast) clocked_by(i_wciClk) reset_by(no_reset);
  method sReset_n () enable(FC_SReset_n) clocked_by(i_wciClk) reset_by(no_reset);
  method sThreadBusy () enable(FC_SThreadBusy) clocked_by(i_wciClk) reset_by(no_reset);
endinterface: i_FC

interface I_FP i_FP;
  method FP_MAddr mAddr clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MAddrSpace mAddrSpace clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MBurstLength mBurstLength clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MCmd mCmd clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MData mData clocked_by(i_wciClk) reset_by(no_reset);
  method FC_MDataInfo    mDataInfo   clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MDataByteEn mDataByteEn clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MDataLast mDataLast clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MDataValid mDataValid clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MFlag mFlag clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MReqInfo mReqInfo clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MReqLast mReqLast clocked_by(i_wciClk) reset_by(no_reset);
  method FP_MReset_n mReset_n clocked_by(i_wciClk) reset_by(no_reset);
  method sData (FP_SData) enable((*inhigh*)en28) clocked_by(i_wciClk) reset_by(no_reset);
  method sDataThreadBusy () enable(FP_SDataThreadBusy) clocked_by(i_wciClk) reset_by(no_reset);
  method sFlag (FP_SFlag) enable((*inhigh*)en29) clocked_by(i_wciClk) reset_by(no_reset);
  method sResp (FP_SResp) enable((*inhigh*)en30) clocked_by(i_wciClk) reset_by(no_reset);
  method sRespLast () enable(FP_SRespLast) clocked_by(i_wciClk) reset_by(no_reset);
  method sReset_n () enable(FP_SReset_n) clocked_by(i_wciClk) reset_by(no_reset);
  method sThreadBusy () enable(FP_SThreadBusy) clocked_by(i_wciClk) reset_by(no_reset);
endinterface: i_FP

schedule (
i_wci0_mAddr, i_wci0_mAddrSpace, i_wci0_mByteEn, i_wci0_mCmd, i_wci0_mData, i_wci0_mFlag, i_wci0_sData, i_wci0_sFlag, i_wci0_sResp, i_wci0_sThreadBusy, i_wci1_mAddr, i_wci1_mAddrSpace, i_wci1_mByteEn, i_wci1_mCmd, i_wci1_mData, i_wci1_mFlag, i_wci1_sData, i_wci1_sFlag, i_wci1_sResp, i_wci1_sThreadBusy, i_wci2_mAddr, i_wci2_mAddrSpace, i_wci2_mByteEn, i_wci2_mCmd, i_wci2_mData, i_wci2_mFlag, i_wci2_sData, i_wci2_sFlag, i_wci2_sResp, i_wci2_sThreadBusy, i_wmemi0_mAddr, i_wmemi0_mBurstLength, i_wmemi0_mCmd, i_wmemi0_mData, i_wmemi0_mDataByteEn, i_wmemi0_mDataLast, i_wmemi0_mDataValid, i_wmemi0_mReqLast, i_wmemi0_mReset_n, i_wmemi0_sCmdAccept, i_wmemi0_sData, i_wmemi0_sDataAccept, i_wmemi0_sResp, i_wmemi0_sRespLast, i_adc_mBurstLength, i_adc_mByteEn, i_adc_mCmd, i_adc_mData, i_adc_mBurstPrecise, i_adc_mReqInfo, i_adc_mReqLast, i_adc_sReset_n, i_adc_sThreadBusy, i_dac_mBurstLength, i_dac_mByteEn, i_dac_mCmd, i_dac_mData, i_dac_mBurstPrecise, i_dac_mReqInfo, i_dac_mReqLast, i_dac_mReset_n, i_dac_sThreadBusy, i_FC_mAddr, i_FC_mAddrSpace, i_FC_mBurstLength, i_FC_mCmd, i_FC_mData, i_FC_mDataByteEn, i_FC_mDataLast, i_FC_mDataValid, i_FC_mFlag, i_FC_mReqInfo, i_FC_mReqLast, i_FC_mReset_n, i_FC_sData, i_FC_sDataThreadBusy, i_FC_sFlag, i_FC_sResp, i_FC_sRespLast, i_FC_sThreadBusy, i_FP_mAddr, i_FP_mAddrSpace, i_FP_mBurstLength, i_FP_mCmd, i_FP_mData, i_FP_mDataByteEn, i_FP_mDataLast, i_FP_mDataValid, i_FP_mFlag, i_FP_mReqInfo, i_FP_mReqLast, i_FP_mReset_n, i_FP_sData, i_FP_sDataThreadBusy, i_FP_sFlag, i_FP_sResp, i_FP_sRespLast, i_FP_sThreadBusy,
    i_FC_mDataInfo, i_FP_mDataInfo, i_dac_mDataInfo, i_adc_mDataInfo, i_FC_sReset_n, i_FP_sReset_n, i_dac_sReset_n, i_adc_mReset_n) //FIXME
   CF  (
i_wci0_mAddr, i_wci0_mAddrSpace, i_wci0_mByteEn, i_wci0_mCmd, i_wci0_mData, i_wci0_mFlag, i_wci0_sData, i_wci0_sFlag, i_wci0_sResp, i_wci0_sThreadBusy, i_wci1_mAddr, i_wci1_mAddrSpace, i_wci1_mByteEn, i_wci1_mCmd, i_wci1_mData, i_wci1_mFlag, i_wci1_sData, i_wci1_sFlag, i_wci1_sResp, i_wci1_sThreadBusy, i_wci2_mAddr, i_wci2_mAddrSpace, i_wci2_mByteEn, i_wci2_mCmd, i_wci2_mData, i_wci2_mFlag, i_wci2_sData, i_wci2_sFlag, i_wci2_sResp, i_wci2_sThreadBusy, i_wmemi0_mAddr, i_wmemi0_mBurstLength, i_wmemi0_mCmd, i_wmemi0_mData, i_wmemi0_mDataByteEn, i_wmemi0_mDataLast, i_wmemi0_mDataValid, i_wmemi0_mReqLast, i_wmemi0_mReset_n, i_wmemi0_sCmdAccept, i_wmemi0_sData, i_wmemi0_sDataAccept, i_wmemi0_sResp, i_wmemi0_sRespLast, i_adc_mBurstLength, i_adc_mByteEn, i_adc_mCmd, i_adc_mData, i_adc_mBurstPrecise, i_adc_mReqInfo, i_adc_mReqLast, i_adc_mReset_n, i_adc_sReset_n, i_adc_sThreadBusy, i_dac_mBurstLength, i_dac_mByteEn, i_dac_mCmd, i_dac_mData, i_dac_mBurstPrecise, i_dac_mReqInfo, i_dac_mReqLast, i_dac_mReset_n, i_dac_sReset_n, i_dac_sThreadBusy, i_FC_mAddr, i_FC_mAddrSpace, i_FC_mBurstLength, i_FC_mCmd, i_FC_mData, i_FC_mDataByteEn, i_FC_mDataLast, i_FC_mDataValid, i_FC_mFlag, i_FC_mReqInfo, i_FC_mReqLast, i_FC_mReset_n, i_FC_sData, i_FC_sDataThreadBusy, i_FC_sFlag, i_FC_sResp, i_FC_sRespLast, i_FC_sReset_n, i_FC_sThreadBusy, i_FP_mAddr, i_FP_mAddrSpace, i_FP_mBurstLength, i_FP_mCmd, i_FP_mData, i_FP_mDataByteEn, i_FP_mDataLast, i_FP_mDataValid, i_FP_mFlag, i_FP_mReqInfo, i_FP_mReqLast, i_FP_mReset_n, i_FP_sData, i_FP_sDataThreadBusy, i_FP_sFlag, i_FP_sResp, i_FP_sRespLast, i_FP_sReset_n, i_FP_sThreadBusy,
    i_FC_mDataInfo, i_FP_mDataInfo, i_dac_mDataInfo, i_adc_mDataInfo, i_FC_sReset_n, i_FP_sReset_n, i_dac_sReset_n, i_adc_mReset_n); // FIXME 

endmodule: vMkdelayAssy
// Make a synthesizable Verilog module from our wrapper
(* synthesize *)
(* doc= "Info about this module" *)
module mkdelayAssy#(Clock i_wciClk, Vector#(3,Reset) i_wciRst) (VdelayAssyIfc);
  let _ifc <- vMkdelayAssy(i_wciClk, i_wciRst);
  return _ifc;
endmodule: mkdelayAssy

endpackage: I_delayAssy
