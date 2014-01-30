//
// Generated by Bluespec Compiler, version 2013.01.beta5 (build 30325, 2013-01-23)
//
// On Thu Jan 30 14:51:24 EST 2014
//
//
// Ports:
// Name                         I/O  size props
// wsiS0_SThreadBusy              O     1
// wsiS0_SReset_n                 O     1
// wsiM0_MCmd                     O     3
// wsiM0_MReqLast                 O     1
// wsiM0_MBurstPrecise            O     1
// wsiM0_MBurstLength             O    12
// wsiM0_MData                    O   256 reg
// wsiM0_MByteEn                  O    32 reg
// wsiM0_MReqInfo                 O     8
// wsiM0_MReset_n                 O     1
// CLK                            I     1 clock
// RST_N                          I     1 reset
// wsiS0_MCmd                     I     3
// wsiS0_MBurstLength             I    12
// wsiS0_MData                    I    32
// wsiS0_MByteEn                  I     4
// wsiS0_MReqInfo                 I     8
// wsiS0_MReqLast                 I     1
// wsiS0_MBurstPrecise            I     1
// wsiS0_MReset_n                 I     1 reg
// wsiM0_SThreadBusy              I     1 reg
// wsiM0_SReset_n                 I     1 reg
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
  `define BSV_ASSIGNMENT_DELAY
`endif

`ifdef BSV_POSITIVE_RESET
  `define BSV_RESET_VALUE 1'b1
  `define BSV_RESET_EDGE posedge
`else
  `define BSV_RESET_VALUE 1'b0
  `define BSV_RESET_EDGE negedge
`endif

module mkWsiAdapter4B32B(CLK,
			 RST_N,

			 wsiS0_MCmd,

			 wsiS0_MReqLast,

			 wsiS0_MBurstPrecise,

			 wsiS0_MBurstLength,

			 wsiS0_MData,

			 wsiS0_MByteEn,

			 wsiS0_MReqInfo,

			 wsiS0_SThreadBusy,

			 wsiS0_SReset_n,

			 wsiS0_MReset_n,

			 wsiM0_MCmd,

			 wsiM0_MReqLast,

			 wsiM0_MBurstPrecise,

			 wsiM0_MBurstLength,

			 wsiM0_MData,

			 wsiM0_MByteEn,

			 wsiM0_MReqInfo,

			 wsiM0_SThreadBusy,

			 wsiM0_MReset_n,

			 wsiM0_SReset_n);
  input  CLK;
  input  RST_N;

  // action method wsiS0_mCmd
  input  [2 : 0] wsiS0_MCmd;

  // action method wsiS0_mReqLast
  input  wsiS0_MReqLast;

  // action method wsiS0_mBurstPrecise
  input  wsiS0_MBurstPrecise;

  // action method wsiS0_mBurstLength
  input  [11 : 0] wsiS0_MBurstLength;

  // action method wsiS0_mData
  input  [31 : 0] wsiS0_MData;

  // action method wsiS0_mByteEn
  input  [3 : 0] wsiS0_MByteEn;

  // action method wsiS0_mReqInfo
  input  [7 : 0] wsiS0_MReqInfo;

  // action method wsiS0_mDataInfo

  // value method wsiS0_sThreadBusy
  output wsiS0_SThreadBusy;

  // value method wsiS0_sReset_n
  output wsiS0_SReset_n;

  // action method wsiS0_mReset_n
  input  wsiS0_MReset_n;

  // value method wsiM0_mCmd
  output [2 : 0] wsiM0_MCmd;

  // value method wsiM0_mReqLast
  output wsiM0_MReqLast;

  // value method wsiM0_mBurstPrecise
  output wsiM0_MBurstPrecise;

  // value method wsiM0_mBurstLength
  output [11 : 0] wsiM0_MBurstLength;

  // value method wsiM0_mData
  output [255 : 0] wsiM0_MData;

  // value method wsiM0_mByteEn
  output [31 : 0] wsiM0_MByteEn;

  // value method wsiM0_mReqInfo
  output [7 : 0] wsiM0_MReqInfo;

  // value method wsiM0_mDataInfo

  // action method wsiM0_sThreadBusy
  input  wsiM0_SThreadBusy;

  // value method wsiM0_mReset_n
  output wsiM0_MReset_n;

  // action method wsiM0_sReset_n
  input  wsiM0_SReset_n;

  // signals for module outputs
  wire [255 : 0] wsiM0_MData;
  wire [31 : 0] wsiM0_MByteEn;
  wire [11 : 0] wsiM0_MBurstLength;
  wire [7 : 0] wsiM0_MReqInfo;
  wire [2 : 0] wsiM0_MCmd;
  wire wsiM0_MBurstPrecise,
       wsiM0_MReqLast,
       wsiM0_MReset_n,
       wsiS0_SReset_n,
       wsiS0_SThreadBusy;

  // inlined wires
  wire [312 : 0] wsiM_reqFifo_x_wire_wget;
  wire [95 : 0] wsiM_extStatusW_wget, wsiS_extStatusW_wget;
  wire [60 : 0] wsiS_wsiReq_wget;
  wire [31 : 0] wsi_Es_mData_w_wget;
  wire [11 : 0] wsi_Es_mBurstLength_w_wget;
  wire [7 : 0] wsi_Es_mReqInfo_w_wget;
  wire [3 : 0] wsi_Es_mByteEn_w_wget;
  wire [2 : 0] wsi_Es_mCmd_w_wget;
  wire wsiM_operateD_1_wget,
       wsiM_operateD_1_whas,
       wsiM_peerIsReady_1_wget,
       wsiM_peerIsReady_1_whas,
       wsiM_reqFifo_dequeueing_whas,
       wsiM_reqFifo_enqueueing_whas,
       wsiM_reqFifo_x_wire_whas,
       wsiM_sThreadBusy_pw_whas,
       wsiS_operateD_1_wget,
       wsiS_operateD_1_whas,
       wsiS_peerIsReady_1_wget,
       wsiS_peerIsReady_1_whas,
       wsiS_reqFifo_doResetClr_whas,
       wsiS_reqFifo_doResetDeq_whas,
       wsiS_reqFifo_doResetEnq_whas,
       wsiS_reqFifo_r_clr_whas,
       wsiS_reqFifo_r_deq_whas,
       wsiS_reqFifo_r_enq_whas,
       wsiS_sThreadBusy_dw_wget,
       wsiS_sThreadBusy_dw_whas,
       wsiS_wsiReq_whas,
       wsi_Es_mBurstLength_w_whas,
       wsi_Es_mBurstPrecise_w_whas,
       wsi_Es_mByteEn_w_whas,
       wsi_Es_mCmd_w_whas,
       wsi_Es_mDataInfo_w_whas,
       wsi_Es_mData_w_whas,
       wsi_Es_mReqInfo_w_whas,
       wsi_Es_mReqLast_w_whas;

  // register isFull
  reg isFull;
  wire isFull_D_IN, isFull_EN;

  // register isLast
  reg isLast;
  wire isLast_D_IN, isLast_EN;

  // register pos
  reg [2 : 0] pos;
  wire [2 : 0] pos_D_IN;
  wire pos_EN;

  // register stage_0
  reg [60 : 0] stage_0;
  wire [60 : 0] stage_0_D_IN;
  wire stage_0_EN;

  // register stage_1
  reg [60 : 0] stage_1;
  wire [60 : 0] stage_1_D_IN;
  wire stage_1_EN;

  // register stage_2
  reg [60 : 0] stage_2;
  wire [60 : 0] stage_2_D_IN;
  wire stage_2_EN;

  // register stage_3
  reg [60 : 0] stage_3;
  wire [60 : 0] stage_3_D_IN;
  wire stage_3_EN;

  // register stage_4
  reg [60 : 0] stage_4;
  wire [60 : 0] stage_4_D_IN;
  wire stage_4_EN;

  // register stage_5
  reg [60 : 0] stage_5;
  wire [60 : 0] stage_5_D_IN;
  wire stage_5_EN;

  // register stage_6
  reg [60 : 0] stage_6;
  wire [60 : 0] stage_6_D_IN;
  wire stage_6_EN;

  // register stage_7
  reg [60 : 0] stage_7;
  wire [60 : 0] stage_7_D_IN;
  wire stage_7_EN;

  // register wsiM_burstKind
  reg [1 : 0] wsiM_burstKind;
  wire [1 : 0] wsiM_burstKind_D_IN;
  wire wsiM_burstKind_EN;

  // register wsiM_errorSticky
  reg wsiM_errorSticky;
  wire wsiM_errorSticky_D_IN, wsiM_errorSticky_EN;

  // register wsiM_iMesgCount
  reg [31 : 0] wsiM_iMesgCount;
  wire [31 : 0] wsiM_iMesgCount_D_IN;
  wire wsiM_iMesgCount_EN;

  // register wsiM_isReset_isInReset
  reg wsiM_isReset_isInReset;
  wire wsiM_isReset_isInReset_D_IN, wsiM_isReset_isInReset_EN;

  // register wsiM_operateD
  reg wsiM_operateD;
  wire wsiM_operateD_D_IN, wsiM_operateD_EN;

  // register wsiM_pMesgCount
  reg [31 : 0] wsiM_pMesgCount;
  wire [31 : 0] wsiM_pMesgCount_D_IN;
  wire wsiM_pMesgCount_EN;

  // register wsiM_peerIsReady
  reg wsiM_peerIsReady;
  wire wsiM_peerIsReady_D_IN, wsiM_peerIsReady_EN;

  // register wsiM_reqFifo_cntr_r
  reg [1 : 0] wsiM_reqFifo_cntr_r;
  wire [1 : 0] wsiM_reqFifo_cntr_r_D_IN;
  wire wsiM_reqFifo_cntr_r_EN;

  // register wsiM_reqFifo_q_0
  reg [312 : 0] wsiM_reqFifo_q_0;
  reg [312 : 0] wsiM_reqFifo_q_0_D_IN;
  wire wsiM_reqFifo_q_0_EN;

  // register wsiM_reqFifo_q_1
  reg [312 : 0] wsiM_reqFifo_q_1;
  reg [312 : 0] wsiM_reqFifo_q_1_D_IN;
  wire wsiM_reqFifo_q_1_EN;

  // register wsiM_sThreadBusy_d
  reg wsiM_sThreadBusy_d;
  wire wsiM_sThreadBusy_d_D_IN, wsiM_sThreadBusy_d_EN;

  // register wsiM_statusR
  reg [7 : 0] wsiM_statusR;
  wire [7 : 0] wsiM_statusR_D_IN;
  wire wsiM_statusR_EN;

  // register wsiM_tBusyCount
  reg [31 : 0] wsiM_tBusyCount;
  wire [31 : 0] wsiM_tBusyCount_D_IN;
  wire wsiM_tBusyCount_EN;

  // register wsiM_trafficSticky
  reg wsiM_trafficSticky;
  wire wsiM_trafficSticky_D_IN, wsiM_trafficSticky_EN;

  // register wsiS_burstKind
  reg [1 : 0] wsiS_burstKind;
  wire [1 : 0] wsiS_burstKind_D_IN;
  wire wsiS_burstKind_EN;

  // register wsiS_errorSticky
  reg wsiS_errorSticky;
  wire wsiS_errorSticky_D_IN, wsiS_errorSticky_EN;

  // register wsiS_iMesgCount
  reg [31 : 0] wsiS_iMesgCount;
  wire [31 : 0] wsiS_iMesgCount_D_IN;
  wire wsiS_iMesgCount_EN;

  // register wsiS_isReset_isInReset
  reg wsiS_isReset_isInReset;
  wire wsiS_isReset_isInReset_D_IN, wsiS_isReset_isInReset_EN;

  // register wsiS_mesgWordLength
  reg [11 : 0] wsiS_mesgWordLength;
  wire [11 : 0] wsiS_mesgWordLength_D_IN;
  wire wsiS_mesgWordLength_EN;

  // register wsiS_operateD
  reg wsiS_operateD;
  wire wsiS_operateD_D_IN, wsiS_operateD_EN;

  // register wsiS_pMesgCount
  reg [31 : 0] wsiS_pMesgCount;
  wire [31 : 0] wsiS_pMesgCount_D_IN;
  wire wsiS_pMesgCount_EN;

  // register wsiS_peerIsReady
  reg wsiS_peerIsReady;
  wire wsiS_peerIsReady_D_IN, wsiS_peerIsReady_EN;

  // register wsiS_reqFifo_countReg
  reg [1 : 0] wsiS_reqFifo_countReg;
  wire [1 : 0] wsiS_reqFifo_countReg_D_IN;
  wire wsiS_reqFifo_countReg_EN;

  // register wsiS_reqFifo_levelsValid
  reg wsiS_reqFifo_levelsValid;
  wire wsiS_reqFifo_levelsValid_D_IN, wsiS_reqFifo_levelsValid_EN;

  // register wsiS_statusR
  reg [7 : 0] wsiS_statusR;
  wire [7 : 0] wsiS_statusR_D_IN;
  wire wsiS_statusR_EN;

  // register wsiS_tBusyCount
  reg [31 : 0] wsiS_tBusyCount;
  wire [31 : 0] wsiS_tBusyCount_D_IN;
  wire wsiS_tBusyCount_EN;

  // register wsiS_trafficSticky
  reg wsiS_trafficSticky;
  wire wsiS_trafficSticky_D_IN, wsiS_trafficSticky_EN;

  // register wsiS_wordCount
  reg [11 : 0] wsiS_wordCount;
  wire [11 : 0] wsiS_wordCount_D_IN;
  wire wsiS_wordCount_EN;

  // ports of submodule wsiS_reqFifo
  wire [60 : 0] wsiS_reqFifo_D_IN, wsiS_reqFifo_D_OUT;
  wire wsiS_reqFifo_CLR,
       wsiS_reqFifo_DEQ,
       wsiS_reqFifo_EMPTY_N,
       wsiS_reqFifo_ENQ,
       wsiS_reqFifo_FULL_N;

  // rule scheduling signals
  wire WILL_FIRE_RL_wsiM_reqFifo_both,
       WILL_FIRE_RL_wsiM_reqFifo_decCtr,
       WILL_FIRE_RL_wsiM_reqFifo_deq,
       WILL_FIRE_RL_wsiM_reqFifo_incCtr,
       WILL_FIRE_RL_wsiS_reqFifo_enq,
       WILL_FIRE_RL_wsiS_reqFifo_reset;

  // inputs to muxes for submodule ports
  wire [312 : 0] MUX_wsiM_reqFifo_q_0_write_1__VAL_1,
		 MUX_wsiM_reqFifo_q_0_write_1__VAL_2,
		 MUX_wsiM_reqFifo_q_1_write_1__VAL_1;
  wire [2 : 0] MUX_pos_write_1__VAL_1;
  wire [1 : 0] MUX_wsiM_reqFifo_cntr_r_write_1__VAL_1,
	       MUX_wsiM_reqFifo_cntr_r_write_1__VAL_2;
  wire MUX_isFull_write_1__VAL_1,
       MUX_wsiM_reqFifo_q_0_write_1__SEL_1,
       MUX_wsiM_reqFifo_q_0_write_1__SEL_2,
       MUX_wsiM_reqFifo_q_1_write_1__SEL_1,
       MUX_wsiM_reqFifo_q_1_write_1__SEL_2,
       MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3;

  // remaining internal signals
  reg [31 : 0] x_byteEn__h6989;
  wire [255 : 0] x_data__h6988;
  wire [31 : 0] be__h8502,
		be__h8521,
		be__h8562,
		be__h8618,
		be__h8689,
		be__h8775,
		be__h8876,
		be__h8992;
  wire [27 : 0] x__h8880;
  wire [23 : 0] x__h8779;
  wire [19 : 0] x__h8693;
  wire [15 : 0] x__h8622;
  wire [11 : 0] x__h8566, x_burstLength__h6987;
  wire [7 : 0] x__h8525;
  wire _dfoo1, _dfoo3;

  // value method wsiS0_sThreadBusy
  assign wsiS0_SThreadBusy =
	     !wsiS_sThreadBusy_dw_whas || wsiS_sThreadBusy_dw_wget ;

  // value method wsiS0_sReset_n
  assign wsiS0_SReset_n = !wsiS_isReset_isInReset && wsiS_operateD ;

  // value method wsiM0_mCmd
  assign wsiM0_MCmd = wsiM_sThreadBusy_d ? 3'd0 : wsiM_reqFifo_q_0[312:310] ;

  // value method wsiM0_mReqLast
  assign wsiM0_MReqLast = !wsiM_sThreadBusy_d && wsiM_reqFifo_q_0[309] ;

  // value method wsiM0_mBurstPrecise
  assign wsiM0_MBurstPrecise = !wsiM_sThreadBusy_d && wsiM_reqFifo_q_0[308] ;

  // value method wsiM0_mBurstLength
  assign wsiM0_MBurstLength =
	     wsiM_sThreadBusy_d ? 12'd0 : wsiM_reqFifo_q_0[307:296] ;

  // value method wsiM0_mData
  assign wsiM0_MData = wsiM_reqFifo_q_0[295:40] ;

  // value method wsiM0_mByteEn
  assign wsiM0_MByteEn = wsiM_reqFifo_q_0[39:8] ;

  // value method wsiM0_mReqInfo
  assign wsiM0_MReqInfo = wsiM_sThreadBusy_d ? 8'd0 : wsiM_reqFifo_q_0[7:0] ;

  // value method wsiM0_mReset_n
  assign wsiM0_MReset_n = !wsiM_isReset_isInReset && wsiM_operateD ;

  // submodule wsiS_reqFifo
  SizedFIFO #(.p1width(32'd61),
	      .p2depth(32'd3),
	      .p3cntr_width(32'd1),
	      .guarded(32'd1)) wsiS_reqFifo(.RST(RST_N),
					    .CLK(CLK),
					    .D_IN(wsiS_reqFifo_D_IN),
					    .ENQ(wsiS_reqFifo_ENQ),
					    .DEQ(wsiS_reqFifo_DEQ),
					    .CLR(wsiS_reqFifo_CLR),
					    .D_OUT(wsiS_reqFifo_D_OUT),
					    .FULL_N(wsiS_reqFifo_FULL_N),
					    .EMPTY_N(wsiS_reqFifo_EMPTY_N));

  // rule RL_wsiM_reqFifo_deq
  assign WILL_FIRE_RL_wsiM_reqFifo_deq =
	     wsiM_reqFifo_cntr_r != 2'd0 && !wsiM_sThreadBusy_d ;

  // rule RL_wsiM_reqFifo_incCtr
  assign WILL_FIRE_RL_wsiM_reqFifo_incCtr =
	     wsiM_reqFifo_enqueueing_whas && wsiM_reqFifo_enqueueing_whas &&
	     !WILL_FIRE_RL_wsiM_reqFifo_deq ;

  // rule RL_wsiM_reqFifo_decCtr
  assign WILL_FIRE_RL_wsiM_reqFifo_decCtr =
	     WILL_FIRE_RL_wsiM_reqFifo_deq && !wsiM_reqFifo_enqueueing_whas ;

  // rule RL_wsiM_reqFifo_both
  assign WILL_FIRE_RL_wsiM_reqFifo_both =
	     wsiM_reqFifo_enqueueing_whas && WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_enqueueing_whas ;

  // rule RL_wsiS_reqFifo_enq
  assign WILL_FIRE_RL_wsiS_reqFifo_enq =
	     wsiS_reqFifo_FULL_N && wsiS_operateD && wsiS_peerIsReady &&
	     wsiS_wsiReq_wget[60:58] == 3'd1 ;

  // rule RL_wsiS_reqFifo_reset
  assign WILL_FIRE_RL_wsiS_reqFifo_reset =
	     WILL_FIRE_RL_wsiS_reqFifo_enq ||
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ;

  // inputs to muxes for submodule ports
  assign MUX_wsiM_reqFifo_q_0_write_1__SEL_1 =
	     WILL_FIRE_RL_wsiM_reqFifo_both && _dfoo3 ;
  assign MUX_wsiM_reqFifo_q_0_write_1__SEL_2 =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_cntr_r == 2'd0 ;
  assign MUX_wsiM_reqFifo_q_1_write_1__SEL_1 =
	     WILL_FIRE_RL_wsiM_reqFifo_both && _dfoo1 ;
  assign MUX_wsiM_reqFifo_q_1_write_1__SEL_2 =
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr && wsiM_reqFifo_cntr_r == 2'd1 ;
  assign MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 =
	     wsiS_reqFifo_EMPTY_N && !isFull ;
  assign MUX_isFull_write_1__VAL_1 = pos == 3'd7 || wsiS_reqFifo_D_OUT[57] ;
  assign MUX_pos_write_1__VAL_1 = pos + 3'd1 ;
  assign MUX_wsiM_reqFifo_cntr_r_write_1__VAL_1 = wsiM_reqFifo_cntr_r - 2'd1 ;
  assign MUX_wsiM_reqFifo_cntr_r_write_1__VAL_2 = wsiM_reqFifo_cntr_r + 2'd1 ;
  assign MUX_wsiM_reqFifo_q_0_write_1__VAL_1 =
	     (wsiM_reqFifo_cntr_r == 2'd1) ?
	       MUX_wsiM_reqFifo_q_0_write_1__VAL_2 :
	       wsiM_reqFifo_q_1 ;
  assign MUX_wsiM_reqFifo_q_0_write_1__VAL_2 =
	     { 3'd1,
	       isLast,
	       stage_0[56],
	       x_burstLength__h6987,
	       x_data__h6988,
	       x_byteEn__h6989,
	       stage_0[7:0] } ;
  assign MUX_wsiM_reqFifo_q_1_write_1__VAL_1 =
	     (wsiM_reqFifo_cntr_r == 2'd2) ?
	       MUX_wsiM_reqFifo_q_0_write_1__VAL_2 :
	       313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00 ;

  // inlined wires
  assign wsiS_wsiReq_wget =
	     { wsiS0_MCmd,
	       wsiS0_MReqLast,
	       wsiS0_MBurstPrecise,
	       wsiS0_MBurstLength,
	       wsiS0_MData,
	       wsiS0_MByteEn,
	       wsiS0_MReqInfo } ;
  assign wsiS_wsiReq_whas = 1'd1 ;
  assign wsiS_operateD_1_wget = 1'd1 ;
  assign wsiS_operateD_1_whas = 1'd1 ;
  assign wsiS_peerIsReady_1_wget = 1'd1 ;
  assign wsiS_peerIsReady_1_whas = wsiS0_MReset_n ;
  assign wsiS_sThreadBusy_dw_wget = wsiS_reqFifo_countReg > 2'd1 ;
  assign wsiS_sThreadBusy_dw_whas =
	     wsiS_reqFifo_levelsValid && wsiS_operateD && wsiS_peerIsReady ;
  assign wsiM_reqFifo_x_wire_wget = MUX_wsiM_reqFifo_q_0_write_1__VAL_2 ;
  assign wsiM_reqFifo_x_wire_whas = wsiM_reqFifo_enqueueing_whas ;
  assign wsiM_operateD_1_wget = 1'd1 ;
  assign wsiM_operateD_1_whas = 1'd1 ;
  assign wsiM_peerIsReady_1_wget = 1'd1 ;
  assign wsiM_peerIsReady_1_whas = wsiM0_SReset_n ;
  assign wsi_Es_mCmd_w_wget = wsiS0_MCmd ;
  assign wsi_Es_mCmd_w_whas = 1'd1 ;
  assign wsi_Es_mBurstLength_w_wget = wsiS0_MBurstLength ;
  assign wsi_Es_mBurstLength_w_whas = 1'd1 ;
  assign wsi_Es_mData_w_wget = wsiS0_MData ;
  assign wsi_Es_mData_w_whas = 1'd1 ;
  assign wsi_Es_mByteEn_w_wget = wsiS0_MByteEn ;
  assign wsi_Es_mByteEn_w_whas = 1'd1 ;
  assign wsi_Es_mReqInfo_w_wget = wsiS0_MReqInfo ;
  assign wsi_Es_mReqInfo_w_whas = 1'd1 ;
  assign wsiS_reqFifo_r_enq_whas = WILL_FIRE_RL_wsiS_reqFifo_enq ;
  assign wsiS_reqFifo_r_deq_whas =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ;
  assign wsiS_reqFifo_r_clr_whas = 1'b0 ;
  assign wsiS_reqFifo_doResetEnq_whas = WILL_FIRE_RL_wsiS_reqFifo_enq ;
  assign wsiS_reqFifo_doResetDeq_whas =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ;
  assign wsiS_reqFifo_doResetClr_whas = 1'b0 ;
  assign wsiM_reqFifo_enqueueing_whas =
	     wsiM_reqFifo_cntr_r != 2'd2 && isFull ;
  assign wsiM_reqFifo_dequeueing_whas = WILL_FIRE_RL_wsiM_reqFifo_deq ;
  assign wsiM_sThreadBusy_pw_whas = wsiM0_SThreadBusy ;
  assign wsi_Es_mReqLast_w_whas = wsiS0_MReqLast ;
  assign wsi_Es_mBurstPrecise_w_whas = wsiS0_MBurstPrecise ;
  assign wsi_Es_mDataInfo_w_whas = 1'd1 ;
  assign wsiS_extStatusW_wget =
	     { wsiS_pMesgCount, wsiS_iMesgCount, wsiS_tBusyCount } ;
  assign wsiM_extStatusW_wget =
	     { wsiM_pMesgCount, wsiM_iMesgCount, wsiM_tBusyCount } ;

  // register isFull
  assign isFull_D_IN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 &&
	     MUX_isFull_write_1__VAL_1 ;
  assign isFull_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ||
	     wsiM_reqFifo_enqueueing_whas ;

  // register isLast
  assign isLast_D_IN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 &&
	     wsiS_reqFifo_D_OUT[57] ;
  assign isLast_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ||
	     wsiM_reqFifo_enqueueing_whas ;

  // register pos
  assign pos_D_IN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ?
	       MUX_pos_write_1__VAL_1 :
	       3'd0 ;
  assign pos_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ||
	     wsiM_reqFifo_enqueueing_whas ;

  // register stage_0
  assign stage_0_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_0_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd0 ;

  // register stage_1
  assign stage_1_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_1_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd1 ;

  // register stage_2
  assign stage_2_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_2_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd2 ;

  // register stage_3
  assign stage_3_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_3_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd3 ;

  // register stage_4
  assign stage_4_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_4_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd4 ;

  // register stage_5
  assign stage_5_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_5_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd5 ;

  // register stage_6
  assign stage_6_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_6_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd6 ;

  // register stage_7
  assign stage_7_D_IN = wsiS_reqFifo_D_OUT ;
  assign stage_7_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 && pos == 3'd7 ;

  // register wsiM_burstKind
  assign wsiM_burstKind_D_IN =
	     (wsiM_burstKind == 2'd0) ?
	       (wsiM_reqFifo_q_0[308] ? 2'd1 : 2'd2) :
	       2'd0 ;
  assign wsiM_burstKind_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     (wsiM_burstKind == 2'd0 ||
	      (wsiM_burstKind == 2'd1 || wsiM_burstKind == 2'd2) &&
	      wsiM_reqFifo_q_0[309]) ;

  // register wsiM_errorSticky
  assign wsiM_errorSticky_D_IN = 1'b0 ;
  assign wsiM_errorSticky_EN = 1'b0 ;

  // register wsiM_iMesgCount
  assign wsiM_iMesgCount_D_IN = wsiM_iMesgCount + 32'd1 ;
  assign wsiM_iMesgCount_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     wsiM_burstKind == 2'd2 &&
	     wsiM_reqFifo_q_0[309] ;

  // register wsiM_isReset_isInReset
  assign wsiM_isReset_isInReset_D_IN = 1'd0 ;
  assign wsiM_isReset_isInReset_EN = wsiM_isReset_isInReset ;

  // register wsiM_operateD
  assign wsiM_operateD_D_IN = 1'b1 ;
  assign wsiM_operateD_EN = 1'd1 ;

  // register wsiM_pMesgCount
  assign wsiM_pMesgCount_D_IN = wsiM_pMesgCount + 32'd1 ;
  assign wsiM_pMesgCount_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 &&
	     wsiM_burstKind == 2'd1 &&
	     wsiM_reqFifo_q_0[309] ;

  // register wsiM_peerIsReady
  assign wsiM_peerIsReady_D_IN = wsiM0_SReset_n ;
  assign wsiM_peerIsReady_EN = 1'd1 ;

  // register wsiM_reqFifo_cntr_r
  assign wsiM_reqFifo_cntr_r_D_IN =
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ?
	       MUX_wsiM_reqFifo_cntr_r_write_1__VAL_1 :
	       MUX_wsiM_reqFifo_cntr_r_write_1__VAL_2 ;
  assign wsiM_reqFifo_cntr_r_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ||
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr ;

  // register wsiM_reqFifo_q_0
  always@(MUX_wsiM_reqFifo_q_0_write_1__SEL_1 or
	  MUX_wsiM_reqFifo_q_0_write_1__VAL_1 or
	  MUX_wsiM_reqFifo_q_0_write_1__SEL_2 or
	  MUX_wsiM_reqFifo_q_0_write_1__VAL_2 or
	  WILL_FIRE_RL_wsiM_reqFifo_decCtr or wsiM_reqFifo_q_1)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_wsiM_reqFifo_q_0_write_1__SEL_1:
	  wsiM_reqFifo_q_0_D_IN = MUX_wsiM_reqFifo_q_0_write_1__VAL_1;
      MUX_wsiM_reqFifo_q_0_write_1__SEL_2:
	  wsiM_reqFifo_q_0_D_IN = MUX_wsiM_reqFifo_q_0_write_1__VAL_2;
      WILL_FIRE_RL_wsiM_reqFifo_decCtr:
	  wsiM_reqFifo_q_0_D_IN = wsiM_reqFifo_q_1;
      default: wsiM_reqFifo_q_0_D_IN =
		   313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign wsiM_reqFifo_q_0_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_both && _dfoo3 ||
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr &&
	     wsiM_reqFifo_cntr_r == 2'd0 ||
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ;

  // register wsiM_reqFifo_q_1
  always@(MUX_wsiM_reqFifo_q_1_write_1__SEL_1 or
	  MUX_wsiM_reqFifo_q_1_write_1__VAL_1 or
	  MUX_wsiM_reqFifo_q_1_write_1__SEL_2 or
	  MUX_wsiM_reqFifo_q_0_write_1__VAL_2 or
	  WILL_FIRE_RL_wsiM_reqFifo_decCtr)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_wsiM_reqFifo_q_1_write_1__SEL_1:
	  wsiM_reqFifo_q_1_D_IN = MUX_wsiM_reqFifo_q_1_write_1__VAL_1;
      MUX_wsiM_reqFifo_q_1_write_1__SEL_2:
	  wsiM_reqFifo_q_1_D_IN = MUX_wsiM_reqFifo_q_0_write_1__VAL_2;
      WILL_FIRE_RL_wsiM_reqFifo_decCtr:
	  wsiM_reqFifo_q_1_D_IN =
	      313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
      default: wsiM_reqFifo_q_1_D_IN =
		   313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign wsiM_reqFifo_q_1_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_both && _dfoo1 ||
	     WILL_FIRE_RL_wsiM_reqFifo_incCtr &&
	     wsiM_reqFifo_cntr_r == 2'd1 ||
	     WILL_FIRE_RL_wsiM_reqFifo_decCtr ;

  // register wsiM_sThreadBusy_d
  assign wsiM_sThreadBusy_d_D_IN = wsiM0_SThreadBusy ;
  assign wsiM_sThreadBusy_d_EN = 1'd1 ;

  // register wsiM_statusR
  assign wsiM_statusR_D_IN =
	     { wsiM_isReset_isInReset,
	       !wsiM_peerIsReady,
	       !wsiM_operateD,
	       wsiM_errorSticky,
	       wsiM_burstKind != 2'd0,
	       wsiM_sThreadBusy_d,
	       1'd0,
	       wsiM_trafficSticky } ;
  assign wsiM_statusR_EN = 1'd1 ;

  // register wsiM_tBusyCount
  assign wsiM_tBusyCount_D_IN = wsiM_tBusyCount + 32'd1 ;
  assign wsiM_tBusyCount_EN =
	     wsiM_operateD && wsiM_peerIsReady && wsiM_sThreadBusy_d ;

  // register wsiM_trafficSticky
  assign wsiM_trafficSticky_D_IN = 1'd1 ;
  assign wsiM_trafficSticky_EN =
	     WILL_FIRE_RL_wsiM_reqFifo_deq &&
	     wsiM_reqFifo_q_0[312:310] == 3'd1 ;

  // register wsiS_burstKind
  assign wsiS_burstKind_D_IN =
	     (wsiS_burstKind == 2'd0) ?
	       (wsiS_wsiReq_wget[56] ? 2'd1 : 2'd2) :
	       2'd0 ;
  assign wsiS_burstKind_EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq &&
	     (wsiS_burstKind == 2'd0 ||
	      (wsiS_burstKind == 2'd1 || wsiS_burstKind == 2'd2) &&
	      wsiS_wsiReq_wget[57]) ;

  // register wsiS_errorSticky
  assign wsiS_errorSticky_D_IN = 1'b0 ;
  assign wsiS_errorSticky_EN = 1'b0 ;

  // register wsiS_iMesgCount
  assign wsiS_iMesgCount_D_IN = wsiS_iMesgCount + 32'd1 ;
  assign wsiS_iMesgCount_EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_burstKind == 2'd2 &&
	     wsiS_wsiReq_wget[57] ;

  // register wsiS_isReset_isInReset
  assign wsiS_isReset_isInReset_D_IN = 1'd0 ;
  assign wsiS_isReset_isInReset_EN = wsiS_isReset_isInReset ;

  // register wsiS_mesgWordLength
  assign wsiS_mesgWordLength_D_IN = wsiS_wordCount ;
  assign wsiS_mesgWordLength_EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_wsiReq_wget[57] ;

  // register wsiS_operateD
  assign wsiS_operateD_D_IN = 1'b1 ;
  assign wsiS_operateD_EN = 1'd1 ;

  // register wsiS_pMesgCount
  assign wsiS_pMesgCount_D_IN = wsiS_pMesgCount + 32'd1 ;
  assign wsiS_pMesgCount_EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq && wsiS_burstKind == 2'd1 &&
	     wsiS_wsiReq_wget[57] ;

  // register wsiS_peerIsReady
  assign wsiS_peerIsReady_D_IN = wsiS0_MReset_n ;
  assign wsiS_peerIsReady_EN = 1'd1 ;

  // register wsiS_reqFifo_countReg
  assign wsiS_reqFifo_countReg_D_IN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq ?
	       wsiS_reqFifo_countReg + 2'd1 :
	       wsiS_reqFifo_countReg - 2'd1 ;
  assign wsiS_reqFifo_countReg_EN =
	     WILL_FIRE_RL_wsiS_reqFifo_enq !=
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ;

  // register wsiS_reqFifo_levelsValid
  assign wsiS_reqFifo_levelsValid_D_IN = WILL_FIRE_RL_wsiS_reqFifo_reset ;
  assign wsiS_reqFifo_levelsValid_EN =
	     MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ||
	     WILL_FIRE_RL_wsiS_reqFifo_enq ||
	     WILL_FIRE_RL_wsiS_reqFifo_reset ;

  // register wsiS_statusR
  assign wsiS_statusR_D_IN =
	     { wsiS_isReset_isInReset,
	       !wsiS_peerIsReady,
	       !wsiS_operateD,
	       wsiS_errorSticky,
	       wsiS_burstKind != 2'd0,
	       !wsiS_sThreadBusy_dw_whas || wsiS_sThreadBusy_dw_wget,
	       1'd0,
	       wsiS_trafficSticky } ;
  assign wsiS_statusR_EN = 1'd1 ;

  // register wsiS_tBusyCount
  assign wsiS_tBusyCount_D_IN = wsiS_tBusyCount + 32'd1 ;
  assign wsiS_tBusyCount_EN =
	     wsiS_operateD && wsiS_peerIsReady &&
	     (!wsiS_sThreadBusy_dw_whas || wsiS_sThreadBusy_dw_wget) ;

  // register wsiS_trafficSticky
  assign wsiS_trafficSticky_D_IN = 1'd1 ;
  assign wsiS_trafficSticky_EN = WILL_FIRE_RL_wsiS_reqFifo_enq ;

  // register wsiS_wordCount
  assign wsiS_wordCount_D_IN =
	     wsiS_wsiReq_wget[57] ? 12'd1 : wsiS_wordCount + 12'd1 ;
  assign wsiS_wordCount_EN = WILL_FIRE_RL_wsiS_reqFifo_enq ;

  // submodule wsiS_reqFifo
  assign wsiS_reqFifo_D_IN = wsiS_wsiReq_wget ;
  assign wsiS_reqFifo_ENQ = WILL_FIRE_RL_wsiS_reqFifo_enq ;
  assign wsiS_reqFifo_DEQ = MUX_wsiS_reqFifo_levelsValid_write_1__SEL_3 ;
  assign wsiS_reqFifo_CLR = 1'b0 ;

  // remaining internal signals
  assign _dfoo1 =
	     wsiM_reqFifo_cntr_r != 2'd2 ||
	     MUX_wsiM_reqFifo_cntr_r_write_1__VAL_1 == 2'd1 ;
  assign _dfoo3 =
	     wsiM_reqFifo_cntr_r != 2'd1 ||
	     MUX_wsiM_reqFifo_cntr_r_write_1__VAL_1 == 2'd0 ;
  assign be__h8502 = { 28'd0, stage_0[11:8] } ;
  assign be__h8521 = { 24'd0, x__h8525 } ;
  assign be__h8562 = { 20'd0, x__h8566 } ;
  assign be__h8618 = { 16'd0, x__h8622 } ;
  assign be__h8689 = { 12'd0, x__h8693 } ;
  assign be__h8775 = { 8'd0, x__h8779 } ;
  assign be__h8876 = { 4'd0, x__h8880 } ;
  assign be__h8992 = { stage_7[11:8], x__h8880 } ;
  assign x__h8525 = { stage_1[11:8], stage_0[11:8] } ;
  assign x__h8566 = { stage_2[11:8], x__h8525 } ;
  assign x__h8622 = { stage_3[11:8], x__h8566 } ;
  assign x__h8693 = { stage_4[11:8], x__h8622 } ;
  assign x__h8779 = { stage_5[11:8], x__h8693 } ;
  assign x__h8880 = { stage_6[11:8], x__h8779 } ;
  assign x_burstLength__h6987 = stage_0[55:44] >> 3 ;
  assign x_data__h6988 =
	     { stage_7[43:12],
	       stage_6[43:12],
	       stage_5[43:12],
	       stage_4[43:12],
	       stage_3[43:12],
	       stage_2[43:12],
	       stage_1[43:12],
	       stage_0[43:12] } ;
  always@(pos or
	  stage_7 or
	  stage_6 or
	  stage_5 or
	  stage_4 or
	  stage_3 or
	  stage_2 or
	  stage_1 or
	  stage_0 or
	  be__h8502 or
	  be__h8521 or
	  be__h8562 or
	  be__h8618 or be__h8689 or be__h8775 or be__h8876 or be__h8992)
  begin
    case (pos)
      3'd0: x_byteEn__h6989 = be__h8502;
      3'd1: x_byteEn__h6989 = be__h8521;
      3'd2: x_byteEn__h6989 = be__h8562;
      3'd3: x_byteEn__h6989 = be__h8618;
      3'd4: x_byteEn__h6989 = be__h8689;
      3'd5: x_byteEn__h6989 = be__h8775;
      3'd6: x_byteEn__h6989 = be__h8876;
      3'd7: x_byteEn__h6989 = be__h8992;
    endcase
  end

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (RST_N == `BSV_RESET_VALUE)
      begin
        isFull <= `BSV_ASSIGNMENT_DELAY 1'd0;
	isLast <= `BSV_ASSIGNMENT_DELAY 1'd0;
	pos <= `BSV_ASSIGNMENT_DELAY 3'd0;
	wsiM_burstKind <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiM_errorSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_iMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_operateD <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_pMesgCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_peerIsReady <= `BSV_ASSIGNMENT_DELAY 1'd0;
	wsiM_reqFifo_cntr_r <= `BSV_ASSIGNMENT_DELAY 2'd0;
	wsiM_reqFifo_q_0 <= `BSV_ASSIGNMENT_DELAY
	    313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
	wsiM_reqFifo_q_1 <= `BSV_ASSIGNMENT_DELAY
	    313'h00000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA00;
	wsiM_sThreadBusy_d <= `BSV_ASSIGNMENT_DELAY 1'd1;
	wsiM_tBusyCount <= `BSV_ASSIGNMENT_DELAY 32'd0;
	wsiM_trafficSticky <= `BSV_ASSIGNMENT_DELAY 1'd0;
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
        if (isFull_EN) isFull <= `BSV_ASSIGNMENT_DELAY isFull_D_IN;
	if (isLast_EN) isLast <= `BSV_ASSIGNMENT_DELAY isLast_D_IN;
	if (pos_EN) pos <= `BSV_ASSIGNMENT_DELAY pos_D_IN;
	if (wsiM_burstKind_EN)
	  wsiM_burstKind <= `BSV_ASSIGNMENT_DELAY wsiM_burstKind_D_IN;
	if (wsiM_errorSticky_EN)
	  wsiM_errorSticky <= `BSV_ASSIGNMENT_DELAY wsiM_errorSticky_D_IN;
	if (wsiM_iMesgCount_EN)
	  wsiM_iMesgCount <= `BSV_ASSIGNMENT_DELAY wsiM_iMesgCount_D_IN;
	if (wsiM_operateD_EN)
	  wsiM_operateD <= `BSV_ASSIGNMENT_DELAY wsiM_operateD_D_IN;
	if (wsiM_pMesgCount_EN)
	  wsiM_pMesgCount <= `BSV_ASSIGNMENT_DELAY wsiM_pMesgCount_D_IN;
	if (wsiM_peerIsReady_EN)
	  wsiM_peerIsReady <= `BSV_ASSIGNMENT_DELAY wsiM_peerIsReady_D_IN;
	if (wsiM_reqFifo_cntr_r_EN)
	  wsiM_reqFifo_cntr_r <= `BSV_ASSIGNMENT_DELAY
	      wsiM_reqFifo_cntr_r_D_IN;
	if (wsiM_reqFifo_q_0_EN)
	  wsiM_reqFifo_q_0 <= `BSV_ASSIGNMENT_DELAY wsiM_reqFifo_q_0_D_IN;
	if (wsiM_reqFifo_q_1_EN)
	  wsiM_reqFifo_q_1 <= `BSV_ASSIGNMENT_DELAY wsiM_reqFifo_q_1_D_IN;
	if (wsiM_sThreadBusy_d_EN)
	  wsiM_sThreadBusy_d <= `BSV_ASSIGNMENT_DELAY wsiM_sThreadBusy_d_D_IN;
	if (wsiM_tBusyCount_EN)
	  wsiM_tBusyCount <= `BSV_ASSIGNMENT_DELAY wsiM_tBusyCount_D_IN;
	if (wsiM_trafficSticky_EN)
	  wsiM_trafficSticky <= `BSV_ASSIGNMENT_DELAY wsiM_trafficSticky_D_IN;
	if (wsiS_burstKind_EN)
	  wsiS_burstKind <= `BSV_ASSIGNMENT_DELAY wsiS_burstKind_D_IN;
	if (wsiS_errorSticky_EN)
	  wsiS_errorSticky <= `BSV_ASSIGNMENT_DELAY wsiS_errorSticky_D_IN;
	if (wsiS_iMesgCount_EN)
	  wsiS_iMesgCount <= `BSV_ASSIGNMENT_DELAY wsiS_iMesgCount_D_IN;
	if (wsiS_operateD_EN)
	  wsiS_operateD <= `BSV_ASSIGNMENT_DELAY wsiS_operateD_D_IN;
	if (wsiS_pMesgCount_EN)
	  wsiS_pMesgCount <= `BSV_ASSIGNMENT_DELAY wsiS_pMesgCount_D_IN;
	if (wsiS_peerIsReady_EN)
	  wsiS_peerIsReady <= `BSV_ASSIGNMENT_DELAY wsiS_peerIsReady_D_IN;
	if (wsiS_reqFifo_countReg_EN)
	  wsiS_reqFifo_countReg <= `BSV_ASSIGNMENT_DELAY
	      wsiS_reqFifo_countReg_D_IN;
	if (wsiS_reqFifo_levelsValid_EN)
	  wsiS_reqFifo_levelsValid <= `BSV_ASSIGNMENT_DELAY
	      wsiS_reqFifo_levelsValid_D_IN;
	if (wsiS_tBusyCount_EN)
	  wsiS_tBusyCount <= `BSV_ASSIGNMENT_DELAY wsiS_tBusyCount_D_IN;
	if (wsiS_trafficSticky_EN)
	  wsiS_trafficSticky <= `BSV_ASSIGNMENT_DELAY wsiS_trafficSticky_D_IN;
	if (wsiS_wordCount_EN)
	  wsiS_wordCount <= `BSV_ASSIGNMENT_DELAY wsiS_wordCount_D_IN;
      end
    if (stage_0_EN) stage_0 <= `BSV_ASSIGNMENT_DELAY stage_0_D_IN;
    if (stage_1_EN) stage_1 <= `BSV_ASSIGNMENT_DELAY stage_1_D_IN;
    if (stage_2_EN) stage_2 <= `BSV_ASSIGNMENT_DELAY stage_2_D_IN;
    if (stage_3_EN) stage_3 <= `BSV_ASSIGNMENT_DELAY stage_3_D_IN;
    if (stage_4_EN) stage_4 <= `BSV_ASSIGNMENT_DELAY stage_4_D_IN;
    if (stage_5_EN) stage_5 <= `BSV_ASSIGNMENT_DELAY stage_5_D_IN;
    if (stage_6_EN) stage_6 <= `BSV_ASSIGNMENT_DELAY stage_6_D_IN;
    if (stage_7_EN) stage_7 <= `BSV_ASSIGNMENT_DELAY stage_7_D_IN;
    if (wsiM_statusR_EN)
      wsiM_statusR <= `BSV_ASSIGNMENT_DELAY wsiM_statusR_D_IN;
    if (wsiS_mesgWordLength_EN)
      wsiS_mesgWordLength <= `BSV_ASSIGNMENT_DELAY wsiS_mesgWordLength_D_IN;
    if (wsiS_statusR_EN)
      wsiS_statusR <= `BSV_ASSIGNMENT_DELAY wsiS_statusR_D_IN;
  end

  always@(posedge CLK or `BSV_RESET_EDGE RST_N)
  if (RST_N == `BSV_RESET_VALUE)
    begin
      wsiM_isReset_isInReset <= `BSV_ASSIGNMENT_DELAY 1'd1;
      wsiS_isReset_isInReset <= `BSV_ASSIGNMENT_DELAY 1'd1;
    end
  else
    begin
      if (wsiM_isReset_isInReset_EN)
	wsiM_isReset_isInReset <= `BSV_ASSIGNMENT_DELAY
	    wsiM_isReset_isInReset_D_IN;
      if (wsiS_isReset_isInReset_EN)
	wsiS_isReset_isInReset <= `BSV_ASSIGNMENT_DELAY
	    wsiS_isReset_isInReset_D_IN;
    end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    isFull = 1'h0;
    isLast = 1'h0;
    pos = 3'h2;
    stage_0 = 61'h0AAAAAAAAAAAAAAA;
    stage_1 = 61'h0AAAAAAAAAAAAAAA;
    stage_2 = 61'h0AAAAAAAAAAAAAAA;
    stage_3 = 61'h0AAAAAAAAAAAAAAA;
    stage_4 = 61'h0AAAAAAAAAAAAAAA;
    stage_5 = 61'h0AAAAAAAAAAAAAAA;
    stage_6 = 61'h0AAAAAAAAAAAAAAA;
    stage_7 = 61'h0AAAAAAAAAAAAAAA;
    wsiM_burstKind = 2'h2;
    wsiM_errorSticky = 1'h0;
    wsiM_iMesgCount = 32'hAAAAAAAA;
    wsiM_isReset_isInReset = 1'h0;
    wsiM_operateD = 1'h0;
    wsiM_pMesgCount = 32'hAAAAAAAA;
    wsiM_peerIsReady = 1'h0;
    wsiM_reqFifo_cntr_r = 2'h2;
    wsiM_reqFifo_q_0 =
	313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    wsiM_reqFifo_q_1 =
	313'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    wsiM_sThreadBusy_d = 1'h0;
    wsiM_statusR = 8'hAA;
    wsiM_tBusyCount = 32'hAAAAAAAA;
    wsiM_trafficSticky = 1'h0;
    wsiS_burstKind = 2'h2;
    wsiS_errorSticky = 1'h0;
    wsiS_iMesgCount = 32'hAAAAAAAA;
    wsiS_isReset_isInReset = 1'h0;
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
endmodule  // mkWsiAdapter4B32B

