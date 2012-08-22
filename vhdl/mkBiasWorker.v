// mkBiasWorker.v
// Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED

// Verilog module to take the place of mkBiasWorker.v and instance the VHDL biasWorker

// The same module interface signature as Verilog...
module mkBiasWorker4B(
        CLK,
	RST_N,
	wci_s_req,
	wci_s_resp,
	wci_s_SThreadBusy,
	wci_s_SFlag,
	wci_s_MFlag,
	wsi_s_req,
	wsi_s_SThreadBusy,
	wsi_m_req,
	wsi_m_SThreadBusy,
  wsi_m_MReset_n,
  wsi_m_SReset_n,
  wsi_s_MReset_n,
  wsi_s_SReset_n);

  input  CLK;
  input  RST_N;
  input  [59 : 0] wci_s_req;
  output [33 : 0] wci_s_resp;
  output          wci_s_SThreadBusy;
  output [1 : 0]  wci_s_SFlag;
  input  [1 : 0]  wci_s_MFlag;
  input  [60 : 0] wsi_s_req;
  output          wsi_s_SThreadBusy;
  output [60 : 0] wsi_m_req;
  input           wsi_m_SThreadBusy;
  output          wsi_m_MReset_n;
  input           wsi_m_SReset_n;
  input           wsi_s_MReset_n;
  output          wsi_s_SReset_n;

// Instantiate the VHDL biasWorker and unwind the data structures...
  biasWorker bw_instance(
   .clk                (CLK),
   .rst_n              (RST_N),
   .wci_MCmd           (wci_s_req[59:57]),
   .wci_MAddrSpace     (wci_s_req[56]),
   .wci_MByteEn        (wci_s_req[55:52]),
   .wci_MAddr          (wci_s_req[51:32]),
   .wci_MData          (wci_s_req[31:0]),
   .wci_SResp          (wci_s_resp[33:32]),
   .wci_SData          (wci_s_resp[31:0]),
   .wci_MFlag          (wci_s_MFlag),
   .wci_SFlag          (wci_s_SFlag),
   .wci_SThreadBusy    (wci_s_SThreadBusy),
   .wsi0_MCmd          (wsi_s_req[60:58]),
   .wsi0_MReqLast      (wsi_s_req[57]),
   .wsi0_MBurstPrecise (wsi_s_req[56]),
   .wsi0_MBurstLength  (wsi_s_req[55:44]),
   .wsi0_MData         (wsi_s_req[43:12]),
   .wsi0_MByteEn       (wsi_s_req[11:8]),
   .wsi0_MReqInfo      (wsi_s_req[7:0]),
   .wsi0_SThreadBusy   (wsi_s_SThreadBusy),
   .wsi1_MCmd          (wsi_m_req[60:58]),
   .wsi1_MReqLast      (wsi_m_req[57]),
   .wsi1_MBurstPrecise (wsi_m_req[56]),
   .wsi1_MBurstLength  (wsi_m_req[55:44]),
   .wsi1_MData         (wsi_m_req[43:12]),
   .wsi1_MByteEn       (wsi_m_req[11:8]),
   .wsi1_MReqInfo      (wsi_m_req[7:0]),
   .wsi1_SThreadBusy   (wsi_m_SThreadBusy),
   .wsi_m_MReset_n     (wsi_m_MReset_n),
   .wsi_m_SReset_n     (wsi_m_SReset_n),
   .wsi_s_MReset_n     (wsi_s_MReset_n),
   .wsi_s_SReset_n     (wsi_s_SReset_n)
 );

endmodule

