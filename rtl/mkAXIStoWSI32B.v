//
// Generated by Bluespec Compiler, version 2010.10.beta1 (build 22431, 2010-10-28)
//
// On Fri Feb  4 14:13:06 EST 2011
//
//
// Ports:
// Name                         I/O  size props
// axi_TREADY                     O     1
// wsi_MCmd                       O     3
// wsi_MReqLast                   O     1
// wsi_MBurstPrecise              O     1
// wsi_MBurstLength               O    12
// wsi_MData                      O   256 reg
// wsi_MByteEn                    O    32 reg
// wsi_MReqInfo                   O     8
// wsi_MReset_n                   O     1
// CLK                            I     1 clock
// RST_N                          I     1 reset
// axi_TDATA                      I   256 reg
// axi_TSTRB                      I    32 reg
// axi_TVALID                     I     1
// axi_TLAST                      I     1 reg
// wsi_SThreadBusy                I     1 reg
// wsi_SReset_n                   I     1 reg
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

module mkAXIStoWSI32B(CLK,
		      RST_N,

		      axi_TVALID,

		      axi_TREADY,

		      axi_TDATA,

		      axi_TSTRB,

		      axi_TLAST,

		      wsi_MCmd,

		      wsi_MReqLast,

		      wsi_MBurstPrecise,

		      wsi_MBurstLength,

		      wsi_MData,

		      wsi_MByteEn,

		      wsi_MReqInfo,

		      wsi_SThreadBusy,

		      wsi_MReset_n,

		      wsi_SReset_n);
  input  CLK;
  input  RST_N;

  // action method axi_mTVALID
  input  axi_TVALID;

  // value method axi_sTREADY
  output axi_TREADY;

  // action method axi_mTDATA
  input  [255 : 0] axi_TDATA;

  // action method axi_mTSTRB
  input  [31 : 0] axi_TSTRB;

  // action method axi_mTKEEP

  // action method axi_mTLAST
  input  axi_TLAST;

  // value method wsi_mCmd
  output [2 : 0] wsi_MCmd;

  // value method wsi_mReqLast
  output wsi_MReqLast;

  // value method wsi_mBurstPrecise
  output wsi_MBurstPrecise;

  // value method wsi_mBurstLength
  output [11 : 0] wsi_MBurstLength;

  // value method wsi_mData
  output [255 : 0] wsi_MData;

  // value method wsi_mByteEn
  output [31 : 0] wsi_MByteEn;

  // value method wsi_mReqInfo
  output [7 : 0] wsi_MReqInfo;

  // value method wsi_mDataInfo

  // action method wsi_sThreadBusy
  input  wsi_SThreadBusy;

  // value method wsi_mReset_n
  output wsi_MReset_n;

  // action method wsi_sReset_n
  input  wsi_SReset_n;

  // signals for module outputs
  wire [255 : 0] wsi_MData;
  wire [31 : 0] wsi_MByteEn;
  wire [11 : 0] wsi_MBurstLength;
  wire [7 : 0] wsi_MReqInfo;
  wire [2 : 0] wsi_MCmd;
  wire axi_TREADY, wsi_MBurstPrecise, wsi_MReqLast, wsi_MReset_n;

  // inlined wires
  wire [312 : 0] wsiM_reqFifo_x_wire$wget;
  wire [288 : 0] a4ss_data_wire$wget;
  wire [255 : 0] axi_Es_mTData_w$wget;
  wire [95 : 0] wsiM_extStatusW$wget;
  wire [31 : 0] axi_Es_mTStrb_w$wget;
  wire a4ss_enq_enq$whas,
       a4ss_enq_valid$whas,
       axi_Es_mTData_w$whas,
       axi_Es_mTKeep_w$whas,
       axi_Es_mTLast_w$wget,
       axi_Es_mTLast_w$whas,
       axi_Es_mTStrb_w$whas,
       axi_Es_mTVal_w$wget,
       axi_Es_mTVal_w$whas,
       wsiM_operateD_1$wget,
       wsiM_operateD_1$whas,
       wsiM_peerIsReady_1$wget,
       wsiM_peerIsReady_1$whas,
       wsiM_reqFifo_dequeueing$whas,
       wsiM_reqFifo_enqueueing$whas,
       wsiM_reqFifo_x_wire$whas,
       wsiM_sThreadBusy_pw$whas;

  // register wsiM_burstKind
  reg [1 : 0] wsiM_burstKind;
  wire [1 : 0] wsiM_burstKind$D_IN;
  wire wsiM_burstKind$EN;

  // register wsiM_errorSticky
  reg wsiM_errorSticky;
  wire wsiM_errorSticky$D_IN, wsiM_errorSticky$EN;

  // register wsiM_iMesgCount
  reg [31 : 0] wsiM_iMesgCount;
  wire [31 : 0] wsiM_iMesgCount$D_IN;
  wire wsiM_iMesgCount$EN;

  // register wsiM_operateD
  reg wsiM_operateD;
  wire wsiM_operateD$D_IN, wsiM_operateD$EN;

  // register wsiM_pMesgCount
  reg [31 : 0] wsiM_pMesgCount;
  wire [31 : 0] wsiM_pMesgCount$D_IN;
  wire wsiM_pMesgCount$EN;

  // register wsiM_peerIsReady
  reg wsiM_peerIsReady;
  wire wsiM_peerIsReady$D_IN, wsiM_peerIsReady$EN;

  // register wsiM_reqFifo_c_r
  reg [1 : 0] wsiM_reqFifo_c_r;
  wire [1 : 0] wsiM_reqFifo_c_r$D_IN;
  wire wsiM_reqFifo_c_r$EN;

  // register wsiM_reqFifo_q_0
  reg [312 : 0] wsiM_reqFifo_q_0;
  reg [312 : 0] wsiM_reqFifo_q_0$D_IN;
  wire wsiM_reqFifo_q_0$EN;

  // register wsiM_reqFifo_q_1
  reg [312 : 0] wsiM_reqFifo_q_1;
  reg [312 : 0] wsiM_reqFifo_q_1$D_IN;
  wire wsiM_reqFifo_q_1$EN;

  // register wsiM_sThreadBusy_d
  reg wsiM_sThreadBusy_d;
  wire wsiM_sThreadBusy_d$D_IN, wsiM_sThreadBusy_d$EN;

  // register wsiM_statusR
  reg [7 : 0] wsiM_statusR;
  wire [7 : 0] wsiM_statusR$D_IN;
  wire wsiM_statusR$EN;

  // register wsiM_tBusyCount
  reg [31 : 0] wsiM_tBusyCount;
  wire [31 : 0] wsiM_tBusyCount$D_IN;
  wire wsiM_tBusyCount$EN;

  // register wsiM_trafficSticky
  reg wsiM_trafficSticky;
  wire wsiM_trafficSticky$D_IN, wsiM_trafficSticky$EN;

  // ports of submodule a4ss_fifof
  wire [288 : 0] a4ss_fifof$D_IN, a4ss_fifof$D_OUT;
  wire a4ss_fifof$CLR,
       a4ss_fifof$DEQ,
       a4ss_fifof$EMPTY_N,
       a4ss_fifof$ENQ,
       a4ss_fifof$FULL_N;

  // ports of submodule wsiM_isReset
  wire wsiM_isReset$VAL;

  // rule scheduling signals
  wire WILL_FIRE_RL_wsiM_reqFifo_both,
       WILL_FIRE_RL_wsiM_reqFifo_decCtr,
       WILL_FIRE_RL_wsiM_reqFifo_deq,
       WILL_FIRE_RL_wsiM_reqFifo_incCtr;

  // inputs to muxes for submodule ports
  wire [312 : 0] MUX_wsiM_reqFifo_q_0$write_1__VAL_1,
		 MUX_wsiM_reqFifo_q_0$write_1__VAL_2,
		 MUX_wsiM_reqFifo_q_1$write_1__VAL_1;
  wire [1 : 0] MUX_wsiM_reqFifo_c_r$write_1__VAL_1,
	       MUX_wsiM_reqFifo_c_r$write_1__VAL_2;
  wire MUX_wsiM_reqFifo_q_0$write_1__SEL_2,
       MUX_wsiM_reqFifo_q_1$write_1__SEL_2;

  // remaining internal signals
  wire [11 : 0] x_burstLength__h3209;

  // value method axi_sTREADY
  assign axi_TREADY = a4ss_fifof$FULL_N ;

  // value method wsi_mCmd
  assign wsi_MCmd = wsiM_sThreadBusy_d ? 3'd0 : wsiM_reqFifo_q_0[312:310] ;

  // value method wsi_mReqLast
  assign wsi_MReqLast = !wsiM_sThreadBusy_d && wsiM_reqFifo_q_0[309] ;

  // value method wsi_mBurstPrecise
  assign wsi_MBurstPrecise = !wsiM_sThreadBusy_d && wsiM_reqFifo_q_0[308] ;

  // value method wsi_mBurstLength
  assign wsi_MBurstLength =
	     wsiM_sThreadBusy_d ? 12'd0 : wsiM_reqFifo_q_0[307:296] ;

  // value method wsi_mData
  assign wsi_MData = wsiM_reqFifo_q_0[295:40] ;

  // value method wsi_mByteEn
  assign wsi_MByteEn = wsiM_reqFifo_q_0[39:8] ;

  // value method wsi_mReqInfo
  assign wsi_MReqInfo = wsiM_sThreadBusy_d ? 8'd0 : wsiM_reqFifo_q_0[7:0] ;

  // value method wsi_mReset_n
  assign wsi_MReset_n = !wsiM_isReset$VAL && wsiM_operateD ;

  // submodule a4ss_fifof
  FIFO2 #(.width(32'd289), .guarded(32'd1)) a4ss_fifof(.RST_N(RST_N),
						       .CLK(CLK),
						       .D_IN(a4ss_fifof$D_IN),
						       .ENQ(a4ss_fifof$ENQ),
						       .DEQ(a4ss_fifof$DEQ),
						       .CLR(a4ss_fifof$CLR),
						       .D_OUT(a4ss_fifof$D_OUT),
						       .FULL_N(a4ss_fifof$FULL_N),
						       .EMPTY_N(a4ss_fifof$EMPTY_N));

  // submodule wsiM_isReset
  ResetToBool wsiM_isReset(.RST(RST_N), .VAL(wsiM_isReset$VAL));

  // rule RL_wsiM_reqFifo_deq
  assign WILL_FIRE_RL_wsiM_reqFifo_deq =
	     wsiM_reqFifo_c_r != 2'd0 && !wsiM_sThreadBusy_d ;

  // rule RL_wsiM_reqFifo_incCtr
  assign WILL_FIRE_RL_wsiM_reqFifo_incCtr =
	     ((wsiM_reqFifo_c_r == 2'd0) ?
		wsiM_reqFifo_enqueueing$whas :
		wsiM_reqFifo_c_r != 2'd1 || wsiM_reqFifo_enqueueing$whas) &&
	     wsiM_reqFifo_enqueueing$whas &&
	     !WILL_FIRE_RL_wsiM_reqFifo_deq ;

  // rule RL_wsiM_reqFifo_decCtr
  assign WILL_FIRE_RL_wsiM_reqFifo_decCtr =
	     WILL_FIRE_RL_wsiM_reqFifo_deq && !wsiM_reqFifo_enqueueing$whas ;

  // rule RL_wsiM_reqFifo_both
  assign WILL_FIRE_RL_wsiM_reqFifo_both =
	     ((wsiM_reqFifo_c_r == 2'd1) ?
		wsiM_reqFifo_enqueueing$whas :
		wsiM_reqFifo_c_r != 2'd2 || wsiM_reqFifo_enqueueing$whas) &&
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_enqueueing$whas ;

  // inputs to muxes for submodule ports
  assign MUX_wsiM_reqFifo_q_0$write_1__SEL_2 =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_c_r == 2'd0 ;
  assign MUX_wsiM_reqFifo_q_1$write_1__SEL_2 =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_c_r == 2'd1 ;
  assign MUX_wsiM_reqFifo_c_r$write_1__VAL_1 = wsiM_reqFifo_c_r + 2'd1 ;
  assign MUX_wsiM_reqFifo_c_r$write_1__VAL_2 = wsiM_reqFifo_c_r - 2'd1 ;
  assign MUX_wsiM_reqFifo_q_0$write_1__VAL_1 =
	     (wsiM_reqFifo_c_r == 2'd1) ?
	       MUX_wsiM_reqFifo_q_0$write_1__VAL_2 :
	       wsiM_reqFifo_q_1 ;
  assign MUX_wsiM_reqFifo_q_0$write_1__VAL_2 =
	     { 3'd1,
	       a4ss_fifof$D_OUT[0],
	       1'd0,
	       x_burstLength__h3209,
	       a4ss_fifof$D_OUT[288:1],
	       8'd0 } ;
  assign MUX_wsiM_reqFifo_q_1$write_1__VAL_1 =
	     (wsiM_reqFifo_c_r == 2'd2) ?
	       MUX_wsiM_reqFifo_q_0$write_1__VAL_2 :
	       313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00 ;

  // inlined wires
  assign wsiM_reqFifo_x_wire$wget = MUX_wsiM_reqFifo_q_0$write_1__VAL_2 ;
  assign wsiM_reqFifo_x_wire$whas = wsiM_reqFifo_enqueueing$whas ;
  assign wsiM_operateD_1$wget = 1'd1 ;
  assign wsiM_operateD_1$whas = 1'd1 ;
  assign wsiM_peerIsReady_1$wget = 1'd1 ;
  assign wsiM_peerIsReady_1$whas = wsi_SReset_n ;
  assign axi_Es_mTVal_w$wget = 1'd1 ;
  assign axi_Es_mTVal_w$whas = axi_TVALID ;
  assign axi_Es_mTLast_w$wget = 1'd1 ;
  assign axi_Es_mTLast_w$whas = axi_TLAST ;
  assign axi_Es_mTData_w$wget = axi_TDATA ;
  assign axi_Es_mTData_w$whas = 1'd1 ;
  assign axi_Es_mTStrb_w$wget = axi_TSTRB ;
  assign axi_Es_mTStrb_w$whas = 1'd1 ;
  assign a4ss_enq_valid$whas = axi_TVALID ;
  assign a4ss_enq_enq$whas = 1'b0 ;
  assign wsiM_reqFifo_enqueueing$whas =
	     wsiM_reqFifo_c_r != 2'd2 && a4ss_fifof$EMPTY_N ;
  assign wsiM_reqFifo_dequeueing$whas = WILL_FIRE_RL_wsiM_reqFifo_deq ;
  assign wsiM_sThreadBusy_pw$whas = wsi_SThreadBusy ;
  assign axi_Es_mTKeep_w$whas = 1'd1 ;
  assign a4ss_data_wire$wget = { axi_TDATA, axi_TSTRB, axi_TLAST } ;
  assign wsiM_extStatusW$wget =
	     { wsiM_pMesgCount, wsiM_iMesgCount, wsiM_tBusyCount } ;

  // register wsiM_burstKind
  assign wsiM_burstKind$D_IN =
	     (wsiM_burstKind == 2'd0) ?
	       (wsiM_reqFifo_q_0[308] ? 2'd1 : 2'd2) :
	       2'd0 ;
  assign wsiM_burstKind$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     (wsiM_burstKind == 2'd0 ||
	      (wsiM_burstKind == 2'd1 || wsiM_burstKind == 2'd2) &&
	      wsiM_reqFifo_q_0[309]) ;

  // register wsiM_errorSticky
  assign wsiM_errorSticky$D_IN = 1'b0 ;
  assign wsiM_errorSticky$EN = 1'b0 ;

  // register wsiM_iMesgCount
  assign wsiM_iMesgCount$D_IN = wsiM_iMesgCount + 32'd1 ;
  assign wsiM_iMesgCount$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     wsiM_burstKind == 2'd2 &&
	     wsiM_reqFifo_q_0[309] ;

  // register wsiM_operateD
  assign wsiM_operateD$D_IN = 1'b1 ;
  assign wsiM_operateD$EN = 1'd1 ;

  // register wsiM_pMesgCount
  assign wsiM_pMesgCount$D_IN = wsiM_pMesgCount + 32'd1 ;
  assign wsiM_pMesgCount$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     wsiM_burstKind == 2'd1 &&
	     wsiM_reqFifo_q_0[309] ;

  // register wsiM_peerIsReady
  assign wsiM_peerIsReady$D_IN = wsi_SReset_n ;
  assign wsiM_peerIsReady$EN = 1'd1 ;

  // register wsiM_reqFifo_c_r
  assign wsiM_reqFifo_c_r$D_IN =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr ?
	       MUX_wsiM_reqFifo_c_r$write_1__VAL_1 :
	       MUX_wsiM_reqFifo_c_r$write_1__VAL_2 ;
  assign wsiM_reqFifo_c_r$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr ||
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ;

  // register wsiM_reqFifo_q_0
  always@(WILL_FIRE_RL_wsiM_reqFifo_both or
	  MUX_wsiM_reqFifo_q_0$write_1__VAL_1 or
	  MUX_wsiM_reqFifo_q_0$write_1__SEL_2 or
	  MUX_wsiM_reqFifo_q_0$write_1__VAL_2 or
	  WILL_FIRE_RL_wsiM_reqFifo_decCtr or wsiM_reqFifo_q_1)
  begin
    case (1'b1) // synopsys parallel_case
      WILL_FIRE_RL_wsiM_reqFifo_both:
	  wsiM_reqFifo_q_0$D_IN = MUX_wsiM_reqFifo_q_0$write_1__VAL_1;
      MUX_wsiM_reqFifo_q_0$write_1__SEL_2:
	  wsiM_reqFifo_q_0$D_IN = MUX_wsiM_reqFifo_q_0$write_1__VAL_2;
      WILL_FIRE_RL_wsiM_reqFifo_decCtr:
	  wsiM_reqFifo_q_0$D_IN = wsiM_reqFifo_q_1;
      default: wsiM_reqFifo_q_0$D_IN =
		   313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign wsiM_reqFifo_q_0$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_both ||
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_c_r == 2'd0 ||
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ;

  // register wsiM_reqFifo_q_1
  always@(WILL_FIRE_RL_wsiM_reqFifo_both or
	  MUX_wsiM_reqFifo_q_1$write_1__VAL_1 or
	  MUX_wsiM_reqFifo_q_1$write_1__SEL_2 or
	  MUX_wsiM_reqFifo_q_0$write_1__VAL_2 or
	  WILL_FIRE_RL_wsiM_reqFifo_decCtr)
  begin
    case (1'b1) // synopsys parallel_case
      WILL_FIRE_RL_wsiM_reqFifo_both:
	  wsiM_reqFifo_q_1$D_IN = MUX_wsiM_reqFifo_q_1$write_1__VAL_1;
      MUX_wsiM_reqFifo_q_1$write_1__SEL_2:
	  wsiM_reqFifo_q_1$D_IN = MUX_wsiM_reqFifo_q_0$write_1__VAL_2;
      WILL_FIRE_RL_wsiM_reqFifo_decCtr:
	  wsiM_reqFifo_q_1$D_IN =
	      313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
      default: wsiM_reqFifo_q_1$D_IN =
		   313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign wsiM_reqFifo_q_1$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_both ||
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_c_r == 2'd1 ||
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ;

  // register wsiM_sThreadBusy_d
  assign wsiM_sThreadBusy_d$D_IN = wsi_SThreadBusy ;
  assign wsiM_sThreadBusy_d$EN = 1'd1 ;

  // register wsiM_statusR
  assign wsiM_statusR$D_IN =
	     { wsiM_isReset$VAL,
	       !wsiM_peerIsReady,
	       !wsiM_operateD,
	       wsiM_errorSticky,
	       wsiM_burstKind != 2'd0,
	       wsiM_sThreadBusy_d,
	       1'd0,
	       wsiM_trafficSticky } ;
  assign wsiM_statusR$EN = 1'd1 ;

  // register wsiM_tBusyCount
  assign wsiM_tBusyCount$D_IN = wsiM_tBusyCount + 32'd1 ;
  assign wsiM_tBusyCount$EN =
	     wsiM_operateD && wsiM_peerIsReady && wsiM_sThreadBusy_d ;

  // register wsiM_trafficSticky
  assign wsiM_trafficSticky$D_IN = 1'd1 ;
  assign wsiM_trafficSticky$EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 ;

  // submodule a4ss_fifof
  assign a4ss_fifof$D_IN = a4ss_data_wire$wget ;
  assign a4ss_fifof$ENQ = a4ss_fifof$FULL_N && axi_TVALID ;
  assign a4ss_fifof$DEQ = wsiM_reqFifo_enqueueing$whas ;
  assign a4ss_fifof$CLR = 1'b0 ;

  // remaining internal signals
  assign x_burstLength__h3209 = a4ss_fifof$D_OUT[0] ? 12'd1 : 12'd4095 ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (!RST_N)
      begin
        wsiM_burstKind <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiM_errorSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_iMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_operateD <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_pMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_peerIsReady <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_reqFifo_c_r <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiM_reqFifo_q_0 <= `BSV_ASSIGNMENT_DELAY
	    313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
	wsiM_reqFifo_q_1 <= `BSV_ASSIGNMENT_DELAY
	    313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
	wsiM_sThreadBusy_d <= `BSV_ASSIGNMENT_DELAY 1'd1;
	wsiM_tBusyCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_trafficSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
      end
    else
      begin
        if (wsiM_burstKind$EN)
	  wsiM_burstKind <= `BSV_ASSIGNMENT_DELAY wsiM_burstKind$D_IN;
	if (wsiM_errorSticky$EN)
	  wsiM_errorSticky <= `BSV_ASSIGNMENT_DELAY wsiM_errorSticky$D_IN;
	if (wsiM_iMesgCount$EN)
	  wsiM_iMesgCount <= `BSV_ASSIGNMENT_DELAY wsiM_iMesgCount$D_IN;
	if (wsiM_operateD$EN)
	  wsiM_operateD <= `BSV_ASSIGNMENT_DELAY wsiM_operateD$D_IN;
	if (wsiM_pMesgCount$EN)
	  wsiM_pMesgCount <= `BSV_ASSIGNMENT_DELAY wsiM_pMesgCount$D_IN;
	if (wsiM_peerIsReady$EN)
	  wsiM_peerIsReady <= `BSV_ASSIGNMENT_DELAY wsiM_peerIsReady$D_IN;
	if (wsiM_reqFifo_c_r$EN)
	  wsiM_reqFifo_c_r <= `BSV_ASSIGNMENT_DELAY wsiM_reqFifo_c_r$D_IN;
	if (wsiM_reqFifo_q_0$EN)
	  wsiM_reqFifo_q_0 <= `BSV_ASSIGNMENT_DELAY wsiM_reqFifo_q_0$D_IN;
	if (wsiM_reqFifo_q_1$EN)
	  wsiM_reqFifo_q_1 <= `BSV_ASSIGNMENT_DELAY wsiM_reqFifo_q_1$D_IN;
	if (wsiM_sThreadBusy_d$EN)
	  wsiM_sThreadBusy_d <= `BSV_ASSIGNMENT_DELAY wsiM_sThreadBusy_d$D_IN;
	if (wsiM_tBusyCount$EN)
	  wsiM_tBusyCount <= `BSV_ASSIGNMENT_DELAY wsiM_tBusyCount$D_IN;
	if (wsiM_trafficSticky$EN)
	  wsiM_trafficSticky <= `BSV_ASSIGNMENT_DELAY wsiM_trafficSticky$D_IN;
      end
    if (wsiM_statusR$EN)
      wsiM_statusR <= `BSV_ASSIGNMENT_DELAY wsiM_statusR$D_IN;
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    wsiM_burstKind = 2'h2;
    wsiM_errorSticky = 1'h0;
    wsiM_iMesgCount = 32'hAAAAAAAA;
    wsiM_operateD = 1'h0;
    wsiM_pMesgCount = 32'hAAAAAAAA;
    wsiM_peerIsReady = 1'h0;
    wsiM_reqFifo_c_r = 2'h2;
    wsiM_reqFifo_q_0 =
	313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    wsiM_reqFifo_q_1 =
	313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    wsiM_sThreadBusy_d = 1'h0;
    wsiM_statusR = 8'hAA;
    wsiM_tBusyCount = 32'hAAAAAAAA;
    wsiM_trafficSticky = 1'h0;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on
endmodule  // mkAXIStoWSI32B

