//
// Generated by Bluespec Compiler, version 2010.10.beta1 (build 22431, 2010-10-28)
//
// On Fri Feb  4 14:13:05 EST 2011
//
//
// Ports:
// Name                         I/O  size props
// wsi_SThreadBusy                O     1
// wsi_SReset_n                   O     1
// axi_TVALID                     O     1
// axi_TDATA                      O   256 reg
// axi_TSTRB                      O    32 reg
// axi_TLAST                      O     1 reg
// CLK                            I     1 clock
// RST_N                          I     1 reset
// wsi_MCmd                       I     3
// wsi_MBurstLength               I    12
// wsi_MData                      I   256
// wsi_MByteEn                    I    32
// wsi_MReqInfo                   I     8
// wsi_MReqLast                   I     1
// wsi_MBurstPrecise              I     1
// wsi_MReset_n                   I     1 reg
// axi_TREADY                     I     1
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

module mkWSItoAXIS32B(CLK,
		      RST_N,

		      wsi_MCmd,

		      wsi_MReqLast,

		      wsi_MBurstPrecise,

		      wsi_MBurstLength,

		      wsi_MData,

		      wsi_MByteEn,

		      wsi_MReqInfo,

		      wsi_SThreadBusy,

		      wsi_SReset_n,

		      wsi_MReset_n,

		      axi_TVALID,

		      axi_TREADY,

		      axi_TDATA,

		      axi_TSTRB,

		      axi_TLAST);
  input  CLK;
  input  RST_N;

  // action method wsi_mCmd
  input  [2 : 0] wsi_MCmd;

  // action method wsi_mReqLast
  input  wsi_MReqLast;

  // action method wsi_mBurstPrecise
  input  wsi_MBurstPrecise;

  // action method wsi_mBurstLength
  input  [11 : 0] wsi_MBurstLength;

  // action method wsi_mData
  input  [255 : 0] wsi_MData;

  // action method wsi_mByteEn
  input  [31 : 0] wsi_MByteEn;

  // action method wsi_mReqInfo
  input  [7 : 0] wsi_MReqInfo;

  // action method wsi_mDataInfo

  // value method wsi_sThreadBusy
  output wsi_SThreadBusy;

  // value method wsi_sReset_n
  output wsi_SReset_n;

  // action method wsi_mReset_n
  input  wsi_MReset_n;

  // value method axi_mTVALID
  output axi_TVALID;

  // action method axi_sTREADY
  input  axi_TREADY;

  // value method axi_mTDATA
  output [255 : 0] axi_TDATA;

  // value method axi_mTSTRB
  output [31 : 0] axi_TSTRB;

  // value method axi_mTKEEP

  // value method axi_mTLAST
  output axi_TLAST;

  // signals for module outputs
  wire [255 : 0] axi_TDATA;
  wire [31 : 0] axi_TSTRB;
  wire axi_TLAST, axi_TVALID, wsi_SReset_n, wsi_SThreadBusy;

  // inlined wires
  wire [312 : 0] wsiS_wsiReq$wget;
  wire [288 : 0] a4ms_fifof_x_wire$wget;
  wire [255 : 0] wsi_Es_mData_w$wget;
  wire [95 : 0] wsiS_extStatusW$wget;
  wire [31 : 0] wsi_Es_mByteEn_w$wget;
  wire [11 : 0] wsi_Es_mBurstLength_w$wget;
  wire [7 : 0] wsi_Es_mReqInfo_w$wget;
  wire [2 : 0] wsi_Es_mCmd_w$wget;
  wire a4ms_deq_deq$whas,
       a4ms_deq_ready$whas,
       a4ms_fifof_dequeueing$whas,
       a4ms_fifof_enqueueing$whas,
       a4ms_fifof_x_wire$whas,
       axi_Em_mTRdy_w$wget,
       axi_Em_mTRdy_w$whas,
       wsiS_operateD_1$wget,
       wsiS_operateD_1$whas,
       wsiS_peerIsReady_1$wget,
       wsiS_peerIsReady_1$whas,
       wsiS_reqFifo_doResetClr$whas,
       wsiS_reqFifo_doResetDeq$whas,
       wsiS_reqFifo_doResetEnq$whas,
       wsiS_reqFifo_r_clr$whas,
       wsiS_reqFifo_r_deq$whas,
       wsiS_reqFifo_r_enq$whas,
       wsiS_sThreadBusy_dw$wget,
       wsiS_sThreadBusy_dw$whas,
       wsiS_wsiReq$whas,
       wsi_Es_mBurstLength_w$whas,
       wsi_Es_mBurstPrecise_w$whas,
       wsi_Es_mByteEn_w$whas,
       wsi_Es_mCmd_w$whas,
       wsi_Es_mDataInfo_w$whas,
       wsi_Es_mData_w$whas,
       wsi_Es_mReqInfo_w$whas,
       wsi_Es_mReqLast_w$whas;

  // register a4ms_fifof_c_r
  reg [1 : 0] a4ms_fifof_c_r;
  wire [1 : 0] a4ms_fifof_c_r$D_IN;
  wire a4ms_fifof_c_r$EN;

  // register a4ms_fifof_q_0
  reg [288 : 0] a4ms_fifof_q_0;
  reg [288 : 0] a4ms_fifof_q_0$D_IN;
  wire a4ms_fifof_q_0$EN;

  // register a4ms_fifof_q_1
  reg [288 : 0] a4ms_fifof_q_1;
  reg [288 : 0] a4ms_fifof_q_1$D_IN;
  wire a4ms_fifof_q_1$EN;

  // register wsiS_burstKind
  reg [1 : 0] wsiS_burstKind;
  wire [1 : 0] wsiS_burstKind$D_IN;
  wire wsiS_burstKind$EN;

  // register wsiS_errorSticky
  reg wsiS_errorSticky;
  wire wsiS_errorSticky$D_IN, wsiS_errorSticky$EN;

  // register wsiS_iMesgCount
  reg [31 : 0] wsiS_iMesgCount;
  wire [31 : 0] wsiS_iMesgCount$D_IN;
  wire wsiS_iMesgCount$EN;

  // register wsiS_mesgWordLength
  reg [11 : 0] wsiS_mesgWordLength;
  wire [11 : 0] wsiS_mesgWordLength$D_IN;
  wire wsiS_mesgWordLength$EN;

  // register wsiS_operateD
  reg wsiS_operateD;
  wire wsiS_operateD$D_IN, wsiS_operateD$EN;

  // register wsiS_pMesgCount
  reg [31 : 0] wsiS_pMesgCount;
  wire [31 : 0] wsiS_pMesgCount$D_IN;
  wire wsiS_pMesgCount$EN;

  // register wsiS_peerIsReady
  reg wsiS_peerIsReady;
  wire wsiS_peerIsReady$D_IN, wsiS_peerIsReady$EN;

  // register wsiS_reqFifo_countReg
  reg [1 : 0] wsiS_reqFifo_countReg;
  wire [1 : 0] wsiS_reqFifo_countReg$D_IN;
  wire wsiS_reqFifo_countReg$EN;

  // register wsiS_reqFifo_levelsValid
  reg wsiS_reqFifo_levelsValid;
  wire wsiS_reqFifo_levelsValid$D_IN, wsiS_reqFifo_levelsValid$EN;

  // register wsiS_statusR
  reg [7 : 0] wsiS_statusR;
  wire [7 : 0] wsiS_statusR$D_IN;
  wire wsiS_statusR$EN;

  // register wsiS_tBusyCount
  reg [31 : 0] wsiS_tBusyCount;
  wire [31 : 0] wsiS_tBusyCount$D_IN;
  wire wsiS_tBusyCount$EN;

  // register wsiS_trafficSticky
  reg wsiS_trafficSticky;
  wire wsiS_trafficSticky$D_IN, wsiS_trafficSticky$EN;

  // register wsiS_wordCount
  reg [11 : 0] wsiS_wordCount;
  wire [11 : 0] wsiS_wordCount$D_IN;
  wire wsiS_wordCount$EN;

  // ports of submodule wsiS_isReset
  wire wsiS_isReset$VAL;

  // ports of submodule wsiS_reqFifo
  wire [312 : 0] wsiS_reqFifo$D_IN, wsiS_reqFifo$D_OUT;
  wire wsiS_reqFifo$CLR,
       wsiS_reqFifo$DEQ,
       wsiS_reqFifo$EMPTY_N,
       wsiS_reqFifo$ENQ,
       wsiS_reqFifo$FULL_N;

  // rule scheduling signals
  wire WILL_FIRE_RL_a4ms_fifof_both,
       WILL_FIRE_RL_a4ms_fifof_decCtr,
       WILL_FIRE_RL_a4ms_fifof_incCtr,
       WILL_FIRE_RL_wsiS_reqFifo_enq,
       WILL_FIRE_RL_wsiS_reqFifo_reset;

  // inputs to muxes for submodule ports
  wire [288 : 0] MUX_a4ms_fifof_q_0$write_1__VAL_1,
		 MUX_a4ms_fifof_q_0$write_1__VAL_2,
		 MUX_a4ms_fifof_q_1$write_1__VAL_1;
  wire [1 : 0] MUX_a4ms_fifof_c_r$write_1__VAL_1,
	       MUX_a4ms_fifof_c_r$write_1__VAL_2;
  wire MUX_a4ms_fifof_q_0$write_1__SEL_2,
       MUX_a4ms_fifof_q_1$write_1__SEL_2,
       MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2,
       MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3;

  // remaining internal signals
  wire wsiS_reqFifo_notFull__1_AND_wsiS_burstKind_6_E_ETC___d53;

  // value method wsi_sThreadBusy
  assign wsi_SThreadBusy =
	     !wsiS_sThreadBusy_dw$whas || wsiS_sThreadBusy_dw$wget ;

  // value method wsi_sReset_n
  assign wsi_SReset_n = !wsiS_isReset$VAL && wsiS_operateD ;

  // value method axi_mTVALID
  assign axi_TVALID = a4ms_fifof_c_r != 2'd0 ;

  // value method axi_mTDATA
  assign axi_TDATA = a4ms_fifof_q_0[288:33] ;

  // value method axi_mTSTRB
  assign axi_TSTRB = a4ms_fifof_q_0[32:1] ;

  // value method axi_mTLAST
  assign axi_TLAST = a4ms_fifof_q_0[0] ;

  // submodule wsiS_isReset
  ResetToBool wsiS_isReset(.RST(RST_N), .VAL(wsiS_isReset$VAL));

  // submodule wsiS_reqFifo
  SizedFIFO #(.p1width(32'd313),
	      .p2depth(32'd3),
	      .p3cntr_width(32'd1),
	      .guarded(32'd1)) wsiS_reqFifo(.RST_N(RST_N),
					    .CLK(CLK),
					    .D_IN(wsiS_reqFifo$D_IN),
					    .ENQ(wsiS_reqFifo$ENQ),
					    .DEQ(wsiS_reqFifo$DEQ),
					    .CLR(wsiS_reqFifo$CLR),
					    .D_OUT(wsiS_reqFifo$D_OUT),
					    .FULL_N(wsiS_reqFifo$FULL_N),
					    .EMPTY_N(wsiS_reqFifo$EMPTY_N));

  // rule RL_wsiS_reqFifo_enq
  assign WILL_FIRE_RL_wsiS_reqFifo_enq =
	     wsiS_operateD && wsiS_peerIsReady &&
	     wsiS_wsiReq$wget[312:310] == 3'd1 ;

  // rule RL_wsiS_reqFifo_reset
  assign WILL_FIRE_RL_wsiS_reqFifo_reset =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ||
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;

  // rule RL_a4ms_fifof_incCtr
  assign WILL_FIRE_RL_a4ms_fifof_incCtr =
	     ((a4ms_fifof_c_r == 2'd0) ?
		MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 :
		a4ms_fifof_c_r != 2'd1 ||
		MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2) &&
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 &&
	     !a4ms_fifof_dequeueing$whas ;

  // rule RL_a4ms_fifof_decCtr
  assign WILL_FIRE_RL_a4ms_fifof_decCtr =
	     a4ms_fifof_dequeueing$whas &&
	     !MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;

  // rule RL_a4ms_fifof_both
  assign WILL_FIRE_RL_a4ms_fifof_both =
	     ((a4ms_fifof_c_r == 2'd1) ?
		MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 :
		a4ms_fifof_c_r != 2'd2 ||
		MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2) &&
	     a4ms_fifof_dequeueing$whas &&
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;

  // inputs to muxes for submodule ports
  assign MUX_a4ms_fifof_q_0$write_1__SEL_2 =
	     WILL_FIRE_RL_a4ms_fifof_incCtr && a4ms_fifof_c_r == 2'd0 ;
  assign MUX_a4ms_fifof_q_1$write_1__SEL_2 =
	     WILL_FIRE_RL_a4ms_fifof_incCtr && a4ms_fifof_c_r == 2'd1 ;
  assign MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 =
	     a4ms_fifof_c_r != 2'd2 && wsiS_reqFifo$EMPTY_N ;
  assign MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_reqFifo$FULL_N ;
  assign MUX_a4ms_fifof_c_r$write_1__VAL_1 = a4ms_fifof_c_r + 2'd1 ;
  assign MUX_a4ms_fifof_c_r$write_1__VAL_2 = a4ms_fifof_c_r - 2'd1 ;
  assign MUX_a4ms_fifof_q_0$write_1__VAL_1 =
	     (a4ms_fifof_c_r == 2'd1) ?
	       MUX_a4ms_fifof_q_0$write_1__VAL_2 :
	       a4ms_fifof_q_1 ;
  assign MUX_a4ms_fifof_q_0$write_1__VAL_2 =
	     { wsiS_reqFifo$D_OUT[295:8], wsiS_reqFifo$D_OUT[309] } ;
  assign MUX_a4ms_fifof_q_1$write_1__VAL_1 =
	     (a4ms_fifof_c_r == 2'd2) ?
	       MUX_a4ms_fifof_q_0$write_1__VAL_2 :
	       289'd0 ;

  // inlined wires
  assign wsiS_wsiReq$wget =
	     { wsi_MCmd,
	       wsi_MReqLast,
	       wsi_MBurstPrecise,
	       wsi_MBurstLength,
	       wsi_MData,
	       wsi_MByteEn,
	       wsi_MReqInfo } ;
  assign wsiS_wsiReq$whas = 1'd1 ;
  assign wsiS_operateD_1$wget = 1'd1 ;
  assign wsiS_operateD_1$whas = 1'd1 ;
  assign wsiS_peerIsReady_1$wget = 1'd1 ;
  assign wsiS_peerIsReady_1$whas = wsi_MReset_n ;
  assign wsiS_sThreadBusy_dw$wget = wsiS_reqFifo_countReg > 2'd1 ;
  assign wsiS_sThreadBusy_dw$whas =
	     wsiS_reqFifo_levelsValid && wsiS_operateD && wsiS_peerIsReady ;
  assign a4ms_fifof_x_wire$wget = MUX_a4ms_fifof_q_0$write_1__VAL_2 ;
  assign a4ms_fifof_x_wire$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;
  assign wsi_Es_mCmd_w$wget = wsi_MCmd ;
  assign wsi_Es_mCmd_w$whas = 1'd1 ;
  assign wsi_Es_mBurstLength_w$wget = wsi_MBurstLength ;
  assign wsi_Es_mBurstLength_w$whas = 1'd1 ;
  assign wsi_Es_mData_w$wget = wsi_MData ;
  assign wsi_Es_mData_w$whas = 1'd1 ;
  assign wsi_Es_mByteEn_w$wget = wsi_MByteEn ;
  assign wsi_Es_mByteEn_w$whas = 1'd1 ;
  assign wsi_Es_mReqInfo_w$wget = wsi_MReqInfo ;
  assign wsi_Es_mReqInfo_w$whas = 1'd1 ;
  assign axi_Em_mTRdy_w$wget = 1'd1 ;
  assign axi_Em_mTRdy_w$whas = axi_TREADY ;
  assign wsiS_reqFifo_r_enq$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ;
  assign wsiS_reqFifo_r_deq$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;
  assign wsiS_reqFifo_r_clr$whas = 1'b0 ;
  assign wsiS_reqFifo_doResetEnq$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ;
  assign wsiS_reqFifo_doResetDeq$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;
  assign wsiS_reqFifo_doResetClr$whas = 1'b0 ;
  assign a4ms_fifof_enqueueing$whas =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;
  assign a4ms_fifof_dequeueing$whas = a4ms_fifof_c_r != 2'd0 && axi_TREADY ;
  assign a4ms_deq_ready$whas = axi_TREADY ;
  assign a4ms_deq_deq$whas = 1'b0 ;
  assign wsi_Es_mReqLast_w$whas = wsi_MReqLast ;
  assign wsi_Es_mBurstPrecise_w$whas = wsi_MBurstPrecise ;
  assign wsi_Es_mDataInfo_w$whas = 1'd1 ;
  assign wsiS_extStatusW$wget =
	     { wsiS_pMesgCount, wsiS_iMesgCount, wsiS_tBusyCount } ;

  // register a4ms_fifof_c_r
  assign a4ms_fifof_c_r$D_IN =
	     WILL_FIRE_RL_a4ms_fifof_incCtr ?
	       MUX_a4ms_fifof_c_r$write_1__VAL_1 :
	       MUX_a4ms_fifof_c_r$write_1__VAL_2 ;
  assign a4ms_fifof_c_r$EN =
	     WILL_FIRE_RL_a4ms_fifof_incCtr ||
	     WILL_FIRE_RL_a4ms_fifof_decCtr ;

  // register a4ms_fifof_q_0
  always@(WILL_FIRE_RL_a4ms_fifof_both or
	  MUX_a4ms_fifof_q_0$write_1__VAL_1 or
	  MUX_a4ms_fifof_q_0$write_1__SEL_2 or
	  MUX_a4ms_fifof_q_0$write_1__VAL_2 or
	  WILL_FIRE_RL_a4ms_fifof_decCtr or a4ms_fifof_q_1)
  begin
    case (1'b1) // synopsys parallel_case
      WILL_FIRE_RL_a4ms_fifof_both:
	  a4ms_fifof_q_0$D_IN = MUX_a4ms_fifof_q_0$write_1__VAL_1;
      MUX_a4ms_fifof_q_0$write_1__SEL_2:
	  a4ms_fifof_q_0$D_IN = MUX_a4ms_fifof_q_0$write_1__VAL_2;
      WILL_FIRE_RL_a4ms_fifof_decCtr: a4ms_fifof_q_0$D_IN = a4ms_fifof_q_1;
      default: a4ms_fifof_q_0$D_IN =
		   289'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign a4ms_fifof_q_0$EN =
	     WILL_FIRE_RL_a4ms_fifof_both ||
	     WILL_FIRE_RL_a4ms_fifof_incCtr && a4ms_fifof_c_r == 2'd0 ||
	     WILL_FIRE_RL_a4ms_fifof_decCtr ;

  // register a4ms_fifof_q_1
  always@(WILL_FIRE_RL_a4ms_fifof_both or
	  MUX_a4ms_fifof_q_1$write_1__VAL_1 or
	  MUX_a4ms_fifof_q_1$write_1__SEL_2 or
	  MUX_a4ms_fifof_q_0$write_1__VAL_2 or WILL_FIRE_RL_a4ms_fifof_decCtr)
  begin
    case (1'b1) // synopsys parallel_case
      WILL_FIRE_RL_a4ms_fifof_both:
	  a4ms_fifof_q_1$D_IN = MUX_a4ms_fifof_q_1$write_1__VAL_1;
      MUX_a4ms_fifof_q_1$write_1__SEL_2:
	  a4ms_fifof_q_1$D_IN = MUX_a4ms_fifof_q_0$write_1__VAL_2;
      WILL_FIRE_RL_a4ms_fifof_decCtr: a4ms_fifof_q_1$D_IN = 289'd0;
      default: a4ms_fifof_q_1$D_IN =
		   289'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign a4ms_fifof_q_1$EN =
	     WILL_FIRE_RL_a4ms_fifof_both ||
	     WILL_FIRE_RL_a4ms_fifof_incCtr && a4ms_fifof_c_r == 2'd1 ||
	     WILL_FIRE_RL_a4ms_fifof_decCtr ;

  // register wsiS_burstKind
  assign wsiS_burstKind$D_IN =
	     (wsiS_burstKind == 2'd0) ?
	       (wsiS_wsiReq$wget[308] ? 2'd1 : 2'd2) :
	       2'd0 ;
  assign wsiS_burstKind$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq &&
	     wsiS_reqFifo_notFull__1_AND_wsiS_burstKind_6_E_ETC___d53 ;

  // register wsiS_errorSticky
  assign wsiS_errorSticky$D_IN = 1'd1 ;
  assign wsiS_errorSticky$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && !wsiS_reqFifo$FULL_N ;

  // register wsiS_iMesgCount
  assign wsiS_iMesgCount$D_IN = wsiS_iMesgCount + 32'd1 ;
  assign wsiS_iMesgCount$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_reqFifo$FULL_N &&
	     wsiS_burstKind == 2'd2 &&
	     wsiS_wsiReq$wget[309] ;

  // register wsiS_mesgWordLength
  assign wsiS_mesgWordLength$D_IN = wsiS_wordCount ;
  assign wsiS_mesgWordLength$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_reqFifo$FULL_N &&
	     wsiS_wsiReq$wget[309] ;

  // register wsiS_operateD
  assign wsiS_operateD$D_IN = 1'b1 ;
  assign wsiS_operateD$EN = 1'd1 ;

  // register wsiS_pMesgCount
  assign wsiS_pMesgCount$D_IN = wsiS_pMesgCount + 32'd1 ;
  assign wsiS_pMesgCount$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_reqFifo$FULL_N &&
	     wsiS_burstKind == 2'd1 &&
	     wsiS_wsiReq$wget[309] ;

  // register wsiS_peerIsReady
  assign wsiS_peerIsReady$D_IN = wsi_MReset_n ;
  assign wsiS_peerIsReady$EN = 1'd1 ;

  // register wsiS_reqFifo_countReg
  assign wsiS_reqFifo_countReg$D_IN =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ?
	       wsiS_reqFifo_countReg + 2'd1 :
	       wsiS_reqFifo_countReg - 2'd1 ;
  assign wsiS_reqFifo_countReg$EN =
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 !=
	     MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;

  // register wsiS_reqFifo_levelsValid
  assign wsiS_reqFifo_levelsValid$D_IN = WILL_FIRE_RL_wsiS_reqFifo_reset ;
  assign wsiS_reqFifo_levelsValid$EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_reqFifo$FULL_N ||
	     a4ms_fifof_c_r != 2'd2 && wsiS_reqFifo$EMPTY_N ||
	     WILL_FIRE_RL_wsiS_reqFifo_reset ;

  // register wsiS_statusR
  assign wsiS_statusR$D_IN =
	     { wsiS_isReset$VAL,
	       !wsiS_peerIsReady,
	       !wsiS_operateD,
	       wsiS_errorSticky,
	       wsiS_burstKind != 2'd0,
	       !wsiS_sThreadBusy_dw$whas || wsiS_sThreadBusy_dw$wget,
	       1'd0,
	       wsiS_trafficSticky } ;
  assign wsiS_statusR$EN = 1'd1 ;

  // register wsiS_tBusyCount
  assign wsiS_tBusyCount$D_IN = wsiS_tBusyCount + 32'd1 ;
  assign wsiS_tBusyCount$EN =
	     wsiS_operateD && wsiS_peerIsReady &&
	     (!wsiS_sThreadBusy_dw$whas || wsiS_sThreadBusy_dw$wget) ;

  // register wsiS_trafficSticky
  assign wsiS_trafficSticky$D_IN = 1'd1 ;
  assign wsiS_trafficSticky$EN = MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ;

  // register wsiS_wordCount
  assign wsiS_wordCount$D_IN =
	     wsiS_wsiReq$wget[309] ? 12'd1 : wsiS_wordCount + 12'd1 ;
  assign wsiS_wordCount$EN = MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ;

  // submodule wsiS_reqFifo
  assign wsiS_reqFifo$D_IN = wsiS_wsiReq$wget ;
  assign wsiS_reqFifo$ENQ = MUX_wsiS_reqFifo_levelsValid$write_1__SEL_3 ;
  assign wsiS_reqFifo$DEQ = MUX_wsiS_reqFifo_levelsValid$write_1__SEL_2 ;
  assign wsiS_reqFifo$CLR = 1'b0 ;

  // remaining internal signals
  assign wsiS_reqFifo_notFull__1_AND_wsiS_burstKind_6_E_ETC___d53 =
	     wsiS_reqFifo$FULL_N &&
	     (wsiS_burstKind == 2'd0 ||
	      (wsiS_burstKind == 2'd1 || wsiS_burstKind == 2'd2) &&
	      wsiS_wsiReq$wget[309]) ;

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (!RST_N)
      begin
        a4ms_fifof_c_r <= `BSV_ASSIGNMENT_DELAY 2'd0;
	a4ms_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY 289'd0;
	a4ms_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY 289'd0;
	wsiS_burstKind <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiS_errorSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiS_iMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiS_operateD <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiS_pMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiS_peerIsReady <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiS_reqFifo_countReg <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiS_reqFifo_levelsValid <= `BSV_ASSIGNMENT_DELAY 1'd1;
	wsiS_tBusyCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiS_trafficSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiS_wordCount <= `BSV_ASSIGNMENT_DELAY 12'd1;
      end
    else
      begin
        if (a4ms_fifof_c_r$EN)
	  a4ms_fifof_c_r <= `BSV_ASSIGNMENT_DELAY a4ms_fifof_c_r$D_IN;
	if (a4ms_fifof_q_0$EN)
	  a4ms_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY a4ms_fifof_q_0$D_IN;
	if (a4ms_fifof_q_1$EN)
	  a4ms_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY a4ms_fifof_q_1$D_IN;
	if (wsiS_burstKind$EN)
	  wsiS_burstKind <= `BSV_ASSIGNMENT_DELAY wsiS_burstKind$D_IN;
	if (wsiS_errorSticky$EN)
	  wsiS_errorSticky <= `BSV_ASSIGNMENT_DELAY wsiS_errorSticky$D_IN;
	if (wsiS_iMesgCount$EN)
	  wsiS_iMesgCount <= `BSV_ASSIGNMENT_DELAY wsiS_iMesgCount$D_IN;
	if (wsiS_operateD$EN)
	  wsiS_operateD <= `BSV_ASSIGNMENT_DELAY wsiS_operateD$D_IN;
	if (wsiS_pMesgCount$EN)
	  wsiS_pMesgCount <= `BSV_ASSIGNMENT_DELAY wsiS_pMesgCount$D_IN;
	if (wsiS_peerIsReady$EN)
	  wsiS_peerIsReady <= `BSV_ASSIGNMENT_DELAY wsiS_peerIsReady$D_IN;
	if (wsiS_reqFifo_countReg$EN)
	  wsiS_reqFifo_countReg <= `BSV_ASSIGNMENT_DELAY
	      wsiS_reqFifo_countReg$D_IN;
	if (wsiS_reqFifo_levelsValid$EN)
	  wsiS_reqFifo_levelsValid <= `BSV_ASSIGNMENT_DELAY
	      wsiS_reqFifo_levelsValid$D_IN;
	if (wsiS_tBusyCount$EN)
	  wsiS_tBusyCount <= `BSV_ASSIGNMENT_DELAY wsiS_tBusyCount$D_IN;
	if (wsiS_trafficSticky$EN)
	  wsiS_trafficSticky <= `BSV_ASSIGNMENT_DELAY wsiS_trafficSticky$D_IN;
	if (wsiS_wordCount$EN)
	  wsiS_wordCount <= `BSV_ASSIGNMENT_DELAY wsiS_wordCount$D_IN;
      end
    if (wsiS_mesgWordLength$EN)
      wsiS_mesgWordLength <= `BSV_ASSIGNMENT_DELAY wsiS_mesgWordLength$D_IN;
    if (wsiS_statusR$EN)
      wsiS_statusR <= `BSV_ASSIGNMENT_DELAY wsiS_statusR$D_IN;
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    a4ms_fifof_c_r = 2'h2;
    a4ms_fifof_q_0 =
	289'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    a4ms_fifof_q_1 =
	289'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    wsiS_burstKind = 2'h2;
    wsiS_errorSticky = 1'h0;
    wsiS_iMesgCount = 32'hAAAAAAAA;
    wsiS_mesgWordLength = 12'hAAA;
    wsiS_operateD = 1'h0;
    wsiS_pMesgCount = 32'hAAAAAAAA;
    wsiS_peerIsReady = 1'h0;
    wsiS_reqFifo_countReg = 2'h2;
    wsiS_reqFifo_levelsValid = 1'h0;
    wsiS_statusR = 8'hAA;
    wsiS_tBusyCount = 32'hAAAAAAAA;
    wsiS_trafficSticky = 1'h0;
    wsiS_wordCount = 12'hAAA;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on
endmodule  // mkWSItoAXIS32B

