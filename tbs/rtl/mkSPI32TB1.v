//
// Generated by Bluespec Compiler, version 2012.01.A (build 26572, 2012-01-17)
//
// On Wed Apr 11 19:07:17 EDT 2012
//
//
// Ports:
// Name                         I/O  size props
// CLK                            I     1 clock
// RST_N                          I     1 reset
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

module mkSPI32TB1(CLK,
		  RST_N);
  input  CLK;
  input  RST_N;

  // inlined wires
  wire spi_csbR_1$wget,
       spi_csbR_1$whas,
       spi_doResp_1$wget,
       spi_doResp_1$whas,
       spi_reqF_dClear_pw$whas,
       spi_reqF_deq_happened$whas,
       spi_reqF_deq_pw$whas,
       spi_reqF_enq_pw$whas,
       spi_reqF_sClear_pw$whas,
       spi_respF_dClear_pw$whas,
       spi_respF_deq_happened$whas,
       spi_respF_deq_pw$whas,
       spi_respF_enq_pw$whas,
       spi_respF_sClear_pw$whas,
       spi_sdiWs$wget;

  // register simCycle
  reg [15 : 0] simCycle;
  wire [15 : 0] simCycle$D_IN;
  wire simCycle$EN;

  // register spi_capV
  reg [31 : 0] spi_capV;
  wire [31 : 0] spi_capV$D_IN;
  wire spi_capV$EN;

  // register spi_csbR
  reg spi_csbR;
  wire spi_csbR$D_IN, spi_csbR$EN;

  // register spi_dPos
  reg [4 : 0] spi_dPos;
  wire [4 : 0] spi_dPos$D_IN;
  wire spi_dPos$EN;

  // register spi_doResp
  reg spi_doResp;
  wire spi_doResp$D_IN, spi_doResp$EN;

  // register spi_rPos
  reg [4 : 0] spi_rPos;
  wire [4 : 0] spi_rPos$D_IN;
  wire spi_rPos$EN;

  // register spi_rcv_d
  reg spi_rcv_d;
  wire spi_rcv_d$D_IN, spi_rcv_d$EN;

  // register spi_reqF_head_wrapped
  reg spi_reqF_head_wrapped;
  wire spi_reqF_head_wrapped$D_IN, spi_reqF_head_wrapped$EN;

  // register spi_reqF_tail_wrapped
  reg spi_reqF_tail_wrapped;
  wire spi_reqF_tail_wrapped$D_IN, spi_reqF_tail_wrapped$EN;

  // register spi_reqS
  reg [36 : 0] spi_reqS;
  wire [36 : 0] spi_reqS$D_IN;
  wire spi_reqS$EN;

  // register spi_respF_head_wrapped
  reg spi_respF_head_wrapped;
  wire spi_respF_head_wrapped$D_IN, spi_respF_head_wrapped$EN;

  // register spi_respF_tail_wrapped
  reg spi_respF_tail_wrapped;
  wire spi_respF_tail_wrapped$D_IN, spi_respF_tail_wrapped$EN;

  // register spi_respS
  reg [31 : 0] spi_respS;
  wire [31 : 0] spi_respS$D_IN;
  wire spi_respS$EN;

  // register spi_sdiP
  reg spi_sdiP;
  wire spi_sdiP$D_IN, spi_sdiP$EN;

  // register spi_sdoR
  reg spi_sdoR;
  wire spi_sdoR$D_IN, spi_sdoR$EN;

  // register spi_xmt_d
  reg spi_xmt_d;
  wire spi_xmt_d$D_IN, spi_xmt_d$EN;

  // ports of submodule spi_cd
  wire spi_cd$CLK_OUT, spi_cd$PREEDGE;

  // ports of submodule spi_cinv
  wire spi_cinv$CLK_OUT;

  // ports of submodule spi_reqF_dCombinedReset
  wire spi_reqF_dCombinedReset$RST_OUT;

  // ports of submodule spi_reqF_dCrossedsReset
  wire spi_reqF_dCrossedsReset$OUT_RST_N;

  // ports of submodule spi_reqF_dInReset
  wire spi_reqF_dInReset$VAL;

  // ports of submodule spi_reqF_sCombinedReset
  wire spi_reqF_sCombinedReset$RST_OUT;

  // ports of submodule spi_reqF_sCrosseddReset
  wire spi_reqF_sCrosseddReset$OUT_RST_N;

  // ports of submodule spi_reqF_sInReset
  wire spi_reqF_sInReset$VAL;

  // ports of submodule spi_respF_dCombinedReset
  wire spi_respF_dCombinedReset$RST_OUT;

  // ports of submodule spi_respF_dCrossedsReset
  wire spi_respF_dCrossedsReset$OUT_RST_N;

  // ports of submodule spi_respF_dInReset
  wire spi_respF_dInReset$VAL;

  // ports of submodule spi_respF_sCombinedReset
  wire spi_respF_sCombinedReset$RST_OUT;

  // ports of submodule spi_respF_sCrosseddReset
  wire spi_respF_sCrosseddReset$OUT_RST_N;

  // ports of submodule spi_respF_sInReset
  wire spi_respF_sInReset$VAL;

  // ports of submodule spi_slowReset
  wire spi_slowReset$OUT_RST_N;

  // rule scheduling signals
  wire WILL_FIRE_RL_spi_rd_resp,
       WILL_FIRE_RL_spi_recv_d,
       WILL_FIRE_RL_spi_reqF_deq_update_head,
       WILL_FIRE_RL_spi_reqF_enq_update_tail,
       WILL_FIRE_RL_spi_respF_enq_update_tail,
       WILL_FIRE_RL_spi_send_d,
       WILL_FIRE_RL_spi_start_cs;

  // inputs to muxes for submodule ports
  wire [4 : 0] MUX_spi_dPos$write_1__VAL_1,
	       MUX_spi_rPos$write_1__VAL_1,
	       MUX_spi_rPos$write_1__VAL_2;
  wire MUX_spi_doResp_1$wset_1__SEL_1, MUX_spi_rcv_d$write_1__SEL_1;

  // remaining internal signals
  reg [63 : 0] v__h19976;
  reg CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2;
  wire [31 : 0] spi_reqS_BITS_31_TO_0__q1;
  wire [4 : 0] _31_MINUS_spi_dPos_2___d133;
  wire x__h9210;

  // submodule spi_cd
  ClockDiv #(.width(32'd3),
	     .lower(32'd0),
	     .upper(32'd7),
	     .offset(32'd0)) spi_cd(.CLK_IN(CLK),
				    .RST_N(RST_N),
				    .PREEDGE(spi_cd$PREEDGE),
				    .CLK_OUT(spi_cd$CLK_OUT));

  // submodule spi_cinv
  ClockInverter spi_cinv(.CLK_IN(spi_cd$CLK_OUT),
			 .PREEDGE(),
			 .CLK_OUT(spi_cinv$CLK_OUT));

  // submodule spi_reqF_dCombinedReset
  ResetEither spi_reqF_dCombinedReset(.A_RST(spi_slowReset$OUT_RST_N),
				      .B_RST(spi_reqF_dCrossedsReset$OUT_RST_N),
				      .RST_OUT(spi_reqF_dCombinedReset$RST_OUT));

  // submodule spi_reqF_dCrossedsReset
  SyncReset0 spi_reqF_dCrossedsReset(.IN_RST_N(RST_N),
				     .OUT_RST_N(spi_reqF_dCrossedsReset$OUT_RST_N));

  // submodule spi_reqF_dInReset
  ResetToBool spi_reqF_dInReset(.RST(spi_reqF_dCombinedReset$RST_OUT),
				.VAL(spi_reqF_dInReset$VAL));

  // submodule spi_reqF_sCombinedReset
  ResetEither spi_reqF_sCombinedReset(.A_RST(RST_N),
				      .B_RST(spi_reqF_sCrosseddReset$OUT_RST_N),
				      .RST_OUT(spi_reqF_sCombinedReset$RST_OUT));

  // submodule spi_reqF_sCrosseddReset
  SyncReset0 spi_reqF_sCrosseddReset(.IN_RST_N(spi_slowReset$OUT_RST_N),
				     .OUT_RST_N(spi_reqF_sCrosseddReset$OUT_RST_N));

  // submodule spi_reqF_sInReset
  ResetToBool spi_reqF_sInReset(.RST(spi_reqF_sCombinedReset$RST_OUT),
				.VAL(spi_reqF_sInReset$VAL));

  // submodule spi_respF_dCombinedReset
  ResetEither spi_respF_dCombinedReset(.A_RST(RST_N),
				       .B_RST(spi_respF_dCrossedsReset$OUT_RST_N),
				       .RST_OUT(spi_respF_dCombinedReset$RST_OUT));

  // submodule spi_respF_dCrossedsReset
  SyncReset0 spi_respF_dCrossedsReset(.IN_RST_N(spi_slowReset$OUT_RST_N),
				      .OUT_RST_N(spi_respF_dCrossedsReset$OUT_RST_N));

  // submodule spi_respF_dInReset
  ResetToBool spi_respF_dInReset(.RST(spi_respF_dCombinedReset$RST_OUT),
				 .VAL(spi_respF_dInReset$VAL));

  // submodule spi_respF_sCombinedReset
  ResetEither spi_respF_sCombinedReset(.A_RST(spi_slowReset$OUT_RST_N),
				       .B_RST(spi_respF_sCrosseddReset$OUT_RST_N),
				       .RST_OUT(spi_respF_sCombinedReset$RST_OUT));

  // submodule spi_respF_sCrosseddReset
  SyncReset0 spi_respF_sCrosseddReset(.IN_RST_N(RST_N),
				      .OUT_RST_N(spi_respF_sCrosseddReset$OUT_RST_N));

  // submodule spi_respF_sInReset
  ResetToBool spi_respF_sInReset(.RST(spi_respF_sCombinedReset$RST_OUT),
				 .VAL(spi_respF_sInReset$VAL));

  // submodule spi_slowReset
  SyncResetA #(.RSTDELAY(32'd1)) spi_slowReset(.CLK(spi_cd$CLK_OUT),
					       .IN_RST_N(RST_N),
					       .OUT_RST_N(spi_slowReset$OUT_RST_N));

  // rule RL_spi_start_cs
  assign WILL_FIRE_RL_spi_start_cs =
	     spi_reqF_head_wrapped != spi_reqF_tail_wrapped &&
	     !spi_reqF_dInReset$VAL &&
	     !spi_xmt_d &&
	     !spi_rcv_d &&
	     !spi_doResp ;

  // rule RL_spi_send_d
  assign WILL_FIRE_RL_spi_send_d =
	     spi_reqF_head_wrapped != spi_reqF_tail_wrapped &&
	     !spi_reqF_dInReset$VAL &&
	     spi_xmt_d &&
	     !spi_rcv_d &&
	     !spi_doResp ;

  // rule RL_spi_recv_d
  assign WILL_FIRE_RL_spi_recv_d = !spi_xmt_d && spi_rcv_d && !spi_doResp ;

  // rule RL_spi_rd_resp
  assign WILL_FIRE_RL_spi_rd_resp =
	     spi_respF_head_wrapped == spi_respF_tail_wrapped &&
	     !spi_respF_sInReset$VAL &&
	     !spi_xmt_d &&
	     !spi_rcv_d &&
	     spi_doResp ;

  // rule RL_spi_reqF_enq_update_tail
  assign WILL_FIRE_RL_spi_reqF_enq_update_tail =
	     !spi_reqF_sInReset$VAL && spi_reqF_enq_pw$whas ;

  // rule RL_spi_reqF_deq_update_head
  assign WILL_FIRE_RL_spi_reqF_deq_update_head =
	     !spi_reqF_dInReset$VAL && MUX_spi_rcv_d$write_1__SEL_1 ;

  // rule RL_spi_respF_enq_update_tail
  assign WILL_FIRE_RL_spi_respF_enq_update_tail =
	     !spi_respF_sInReset$VAL && WILL_FIRE_RL_spi_rd_resp ;

  // inputs to muxes for submodule ports
  assign MUX_spi_doResp_1$wset_1__SEL_1 =
	     WILL_FIRE_RL_spi_recv_d && spi_rPos == 5'd0 ;
  assign MUX_spi_rcv_d$write_1__SEL_1 =
	     WILL_FIRE_RL_spi_send_d && spi_dPos == 5'd0 ;
  assign MUX_spi_dPos$write_1__VAL_1 =
	     (spi_dPos == 5'd0) ? spi_dPos : spi_dPos - 5'd1 ;
  assign MUX_spi_rPos$write_1__VAL_1 = spi_reqS[36] ? 5'd31 : 5'd0 ;
  assign MUX_spi_rPos$write_1__VAL_2 =
	     (spi_rPos == 5'd0) ? spi_rPos : spi_rPos - 5'd1 ;

  // inlined wires
  assign spi_csbR_1$wget = WILL_FIRE_RL_spi_recv_d && spi_rPos == 5'd31 ;
  assign spi_csbR_1$whas =
	     WILL_FIRE_RL_spi_recv_d || WILL_FIRE_RL_spi_send_d ;
  assign spi_doResp_1$wget = MUX_spi_doResp_1$wset_1__SEL_1 ;
  assign spi_doResp_1$whas =
	     WILL_FIRE_RL_spi_recv_d && spi_rPos == 5'd0 ||
	     WILL_FIRE_RL_spi_rd_resp ;
  assign spi_reqF_enq_pw$whas =
	     spi_reqF_head_wrapped == spi_reqF_tail_wrapped &&
	     !spi_reqF_sInReset$VAL &&
	     spi_cd$PREEDGE &&
	     simCycle == 16'd32 ;
  assign spi_reqF_deq_pw$whas = MUX_spi_rcv_d$write_1__SEL_1 ;
  assign spi_reqF_sClear_pw$whas = 1'b0 ;
  assign spi_reqF_dClear_pw$whas = 1'b0 ;
  assign spi_reqF_deq_happened$whas = 1'b0 ;
  assign spi_respF_enq_pw$whas = WILL_FIRE_RL_spi_rd_resp ;
  assign spi_respF_deq_pw$whas = 1'b0 ;
  assign spi_respF_sClear_pw$whas = 1'b0 ;
  assign spi_respF_dClear_pw$whas = 1'b0 ;
  assign spi_respF_deq_happened$whas = 1'b0 ;
  assign spi_sdiWs$wget = spi_sdiP ;

  // register simCycle
  assign simCycle$D_IN = simCycle + 16'd1 ;
  assign simCycle$EN = 1'd1 ;

  // register spi_capV
  assign spi_capV$D_IN = { spi_capV[30:0], spi_sdiP } ;
  assign spi_capV$EN = WILL_FIRE_RL_spi_recv_d ;

  // register spi_csbR
  assign spi_csbR$D_IN = !spi_csbR_1$whas || spi_csbR_1$wget ;
  assign spi_csbR$EN = 1'd1 ;

  // register spi_dPos
  assign spi_dPos$D_IN =
	     WILL_FIRE_RL_spi_send_d ? MUX_spi_dPos$write_1__VAL_1 : 5'd31 ;
  assign spi_dPos$EN = WILL_FIRE_RL_spi_send_d || WILL_FIRE_RL_spi_start_cs ;

  // register spi_doResp
  assign spi_doResp$D_IN =
	     spi_doResp_1$whas && MUX_spi_doResp_1$wset_1__SEL_1 ;
  assign spi_doResp$EN = 1'd1 ;

  // register spi_rPos
  assign spi_rPos$D_IN =
	     WILL_FIRE_RL_spi_start_cs ?
	       MUX_spi_rPos$write_1__VAL_1 :
	       MUX_spi_rPos$write_1__VAL_2 ;
  assign spi_rPos$EN = WILL_FIRE_RL_spi_start_cs || WILL_FIRE_RL_spi_recv_d ;

  // register spi_rcv_d
  assign spi_rcv_d$D_IN = MUX_spi_rcv_d$write_1__SEL_1 && spi_reqS[36] ;
  assign spi_rcv_d$EN =
	     WILL_FIRE_RL_spi_send_d && spi_dPos == 5'd0 ||
	     WILL_FIRE_RL_spi_recv_d && spi_rPos == 5'd0 ;

  // register spi_reqF_head_wrapped
  assign spi_reqF_head_wrapped$D_IN =
	     WILL_FIRE_RL_spi_reqF_deq_update_head && !spi_reqF_head_wrapped ;
  assign spi_reqF_head_wrapped$EN =
	     WILL_FIRE_RL_spi_reqF_deq_update_head || spi_reqF_dInReset$VAL ;

  // register spi_reqF_tail_wrapped
  assign spi_reqF_tail_wrapped$D_IN =
	     WILL_FIRE_RL_spi_reqF_enq_update_tail && !spi_reqF_tail_wrapped ;
  assign spi_reqF_tail_wrapped$EN =
	     WILL_FIRE_RL_spi_reqF_enq_update_tail || spi_reqF_sInReset$VAL ;

  // register spi_reqS
  assign spi_reqS$D_IN = 37'h0187654321 ;
  assign spi_reqS$EN = spi_reqF_enq_pw$whas ;

  // register spi_respF_head_wrapped
  assign spi_respF_head_wrapped$D_IN = 1'd0 ;
  assign spi_respF_head_wrapped$EN = spi_respF_dInReset$VAL ;

  // register spi_respF_tail_wrapped
  assign spi_respF_tail_wrapped$D_IN =
	     WILL_FIRE_RL_spi_respF_enq_update_tail &&
	     !spi_respF_tail_wrapped ;
  assign spi_respF_tail_wrapped$EN =
	     WILL_FIRE_RL_spi_respF_enq_update_tail ||
	     spi_respF_sInReset$VAL ;

  // register spi_respS
  assign spi_respS$D_IN = spi_capV ;
  assign spi_respS$EN = WILL_FIRE_RL_spi_rd_resp ;

  // register spi_sdiP
  assign spi_sdiP$D_IN = 1'b0 ;
  assign spi_sdiP$EN = 1'b0 ;

  // register spi_sdoR
  assign spi_sdoR$D_IN =
	     spi_reqS[36] ?
	       _31_MINUS_spi_dPos_2___d133 != 5'd0 &&
	       (_31_MINUS_spi_dPos_2___d133 == 5'd1 ||
		_31_MINUS_spi_dPos_2___d133 == 5'd2 ||
		_31_MINUS_spi_dPos_2___d133 == 5'd3 ||
		CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2) :
	       x__h9210 ;
  assign spi_sdoR$EN = WILL_FIRE_RL_spi_send_d ;

  // register spi_xmt_d
  assign spi_xmt_d$D_IN = !MUX_spi_rcv_d$write_1__SEL_1 ;
  assign spi_xmt_d$EN =
	     WILL_FIRE_RL_spi_send_d && spi_dPos == 5'd0 ||
	     WILL_FIRE_RL_spi_start_cs ;

  // remaining internal signals
  assign _31_MINUS_spi_dPos_2___d133 = 5'd31 - spi_dPos ;
  assign spi_reqS_BITS_31_TO_0__q1 = spi_reqS[31:0] ;
  assign x__h9210 = spi_reqS_BITS_31_TO_0__q1[_31_MINUS_spi_dPos_2___d133] ;
  always@(_31_MINUS_spi_dPos_2___d133 or spi_reqS)
  begin
    case (_31_MINUS_spi_dPos_2___d133)
      5'd4:
	  CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2 =
	      spi_reqS[32];
      5'd5:
	  CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2 =
	      spi_reqS[33];
      5'd6:
	  CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2 =
	      spi_reqS[34];
      default: CASE_31_MINUS_spi_dPos_2_33_31_MINUS_spi_dPos__ETC__q2 =
		   _31_MINUS_spi_dPos_2___d133 == 5'd7 && spi_reqS[35];
    endcase
  end

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (!RST_N)
      begin
        simCycle <= `BSV_ASSIGNMENT_DELAY 16'd0;
	spi_reqF_tail_wrapped <= `BSV_ASSIGNMENT_DELAY 1'd0;
	spi_respF_head_wrapped <= `BSV_ASSIGNMENT_DELAY 1'd0;
      end
    else
      begin
        if (simCycle$EN) simCycle <= `BSV_ASSIGNMENT_DELAY simCycle$D_IN;
	if (spi_reqF_tail_wrapped$EN)
	  spi_reqF_tail_wrapped <= `BSV_ASSIGNMENT_DELAY
	      spi_reqF_tail_wrapped$D_IN;
	if (spi_respF_head_wrapped$EN)
	  spi_respF_head_wrapped <= `BSV_ASSIGNMENT_DELAY
	      spi_respF_head_wrapped$D_IN;
      end
    if (spi_reqS$EN) spi_reqS <= `BSV_ASSIGNMENT_DELAY spi_reqS$D_IN;
  end

  always@(posedge spi_cd$CLK_OUT)
  begin
    if (!spi_slowReset$OUT_RST_N)
      begin
        spi_capV <= `BSV_ASSIGNMENT_DELAY 32'd0;
	spi_csbR <= `BSV_ASSIGNMENT_DELAY 1'd1;
	spi_dPos <= `BSV_ASSIGNMENT_DELAY 5'd0;
	spi_doResp <= `BSV_ASSIGNMENT_DELAY 1'd0;
	spi_rPos <= `BSV_ASSIGNMENT_DELAY 5'd0;
	spi_rcv_d <= `BSV_ASSIGNMENT_DELAY 1'd0;
	spi_reqF_head_wrapped <= `BSV_ASSIGNMENT_DELAY 1'd0;
	spi_respF_tail_wrapped <= `BSV_ASSIGNMENT_DELAY 1'd0;
	spi_sdoR <= `BSV_ASSIGNMENT_DELAY 1'b0;
	spi_xmt_d <= `BSV_ASSIGNMENT_DELAY 1'd0;
      end
    else
      begin
        if (spi_capV$EN) spi_capV <= `BSV_ASSIGNMENT_DELAY spi_capV$D_IN;
	if (spi_csbR$EN) spi_csbR <= `BSV_ASSIGNMENT_DELAY spi_csbR$D_IN;
	if (spi_dPos$EN) spi_dPos <= `BSV_ASSIGNMENT_DELAY spi_dPos$D_IN;
	if (spi_doResp$EN)
	  spi_doResp <= `BSV_ASSIGNMENT_DELAY spi_doResp$D_IN;
	if (spi_rPos$EN) spi_rPos <= `BSV_ASSIGNMENT_DELAY spi_rPos$D_IN;
	if (spi_rcv_d$EN) spi_rcv_d <= `BSV_ASSIGNMENT_DELAY spi_rcv_d$D_IN;
	if (spi_reqF_head_wrapped$EN)
	  spi_reqF_head_wrapped <= `BSV_ASSIGNMENT_DELAY
	      spi_reqF_head_wrapped$D_IN;
	if (spi_respF_tail_wrapped$EN)
	  spi_respF_tail_wrapped <= `BSV_ASSIGNMENT_DELAY
	      spi_respF_tail_wrapped$D_IN;
	if (spi_sdoR$EN) spi_sdoR <= `BSV_ASSIGNMENT_DELAY spi_sdoR$D_IN;
	if (spi_xmt_d$EN) spi_xmt_d <= `BSV_ASSIGNMENT_DELAY spi_xmt_d$D_IN;
      end
    if (spi_respS$EN) spi_respS <= `BSV_ASSIGNMENT_DELAY spi_respS$D_IN;
  end

  always@(posedge spi_cinv$CLK_OUT)
  begin
    if (spi_sdiP$EN) spi_sdiP <= `BSV_ASSIGNMENT_DELAY spi_sdiP$D_IN;
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    simCycle = 16'hAAAA;
    spi_capV = 32'hAAAAAAAA;
    spi_csbR = 1'h0;
    spi_dPos = 5'h0A;
    spi_doResp = 1'h0;
    spi_rPos = 5'h0A;
    spi_rcv_d = 1'h0;
    spi_reqF_head_wrapped = 1'h0;
    spi_reqF_tail_wrapped = 1'h0;
    spi_reqS = 37'h0AAAAAAAAA;
    spi_respF_head_wrapped = 1'h0;
    spi_respF_tail_wrapped = 1'h0;
    spi_respS = 32'hAAAAAAAA;
    spi_sdiP = 1'h0;
    spi_sdoR = 1'h0;
    spi_xmt_d = 1'h0;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on

  // handling of system tasks

  // synopsys translate_off
  always@(negedge CLK)
  begin
    #0;
    if (RST_N)
      if (simCycle == 16'd1000)
	begin
	  v__h19976 = $time;
	  #0;
	end
    if (RST_N)
      if (simCycle == 16'd1000)
	$display("[%0d]: %m: mkSPI32TB1 termination", v__h19976);
    if (RST_N) if (simCycle == 16'd1000) $finish(32'd1);
  end
  // synopsys translate_on
endmodule  // mkSPI32TB1
