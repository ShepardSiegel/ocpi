//
// Generated by Bluespec Compiler, version 2009.11.beta2 (build 18693, 2009-11-24)
//
// On Fri Sep 17 17:44:29 EDT 2010
//
//
// Ports:
// Name                         I/O  size props
// wrAddr_ready                   O     1
// wrData_ready                   O     1
// wrResp_data                    O     2 reg
// wrResp_valid                   O     1
// rdAddr_ready                   O     1
// rdResp_data                    O    34 reg
// rdResp_valid                   O     1
// CLK                            I     1 clock
// RST_N                          I     1 reset
// wrAddr_data_value              I    23 reg
// wrAddr_valid_value             I     1
// wrData_data_value              I    36 reg
// wrData_valid_value             I     1
// wrResp_ready_value             I     1
// rdAddr_data_value              I    23 reg
// rdAddr_valid_value             I     1
// rdResp_ready_value             I     1
//
// No combinational paths from inputs to outputs
//
//

`ifdef BSV_ASSIGNMENT_DELAY
`else
`define BSV_ASSIGNMENT_DELAY
`endif

module mkA4LS(CLK,
	      RST_N,

	      wrAddr_data_value,

	      wrAddr_valid_value,

	      wrAddr_ready,

	      wrData_data_value,

	      wrData_valid_value,

	      wrData_ready,

	      wrResp_data,

	      wrResp_valid,

	      wrResp_ready_value,

	      rdAddr_data_value,

	      rdAddr_valid_value,

	      rdAddr_ready,

	      rdResp_data,

	      rdResp_valid,

	      rdResp_ready_value);
  parameter [0 : 0] hasDebugLogic = 1'b0;
  input  CLK;
  input  RST_N;

  // action method wrAddr_data
  input  [22 : 0] wrAddr_data_value;

  // action method wrAddr_valid
  input  wrAddr_valid_value;

  // value method wrAddr_ready
  output wrAddr_ready;

  // action method wrData_data
  input  [35 : 0] wrData_data_value;

  // action method wrData_valid
  input  wrData_valid_value;

  // value method wrData_ready
  output wrData_ready;

  // value method wrResp_data
  output [1 : 0] wrResp_data;

  // value method wrResp_valid
  output wrResp_valid;

  // action method wrResp_ready
  input  wrResp_ready_value;

  // action method rdAddr_data
  input  [22 : 0] rdAddr_data_value;

  // action method rdAddr_valid
  input  rdAddr_valid_value;

  // value method rdAddr_ready
  output rdAddr_ready;

  // value method rdResp_data
  output [33 : 0] rdResp_data;

  // value method rdResp_valid
  output rdResp_valid;

  // action method rdResp_ready
  input  rdResp_ready_value;

  // signals for module outputs
  wire [33 : 0] rdResp_data;
  wire [1 : 0] wrResp_data;
  wire rdAddr_ready, rdResp_valid, wrAddr_ready, wrData_ready, wrResp_valid;

  // inlined wires
  wire [35 : 0] a4wrData_data_wire$wget;
  wire [33 : 0] a4rdResp_fifof_x_wire$wget;
  wire [22 : 0] a4rdAddr_data_wire$wget, a4wrAddr_data_wire$wget;
  wire [1 : 0] a4wrResp_fifof_x_wire$wget;
  wire a4rdAddr_enq_enq$whas,
       a4rdAddr_enq_valid$whas,
       a4rdResp_deq_deq$whas,
       a4rdResp_deq_ready$whas,
       a4rdResp_fifof_dequeueing$whas,
       a4rdResp_fifof_enqueueing$whas,
       a4rdResp_fifof_x_wire$whas,
       a4wrAddr_enq_enq$whas,
       a4wrAddr_enq_valid$whas,
       a4wrData_enq_enq$whas,
       a4wrData_enq_valid$whas,
       a4wrResp_deq_deq$whas,
       a4wrResp_deq_ready$whas,
       a4wrResp_fifof_dequeueing$whas,
       a4wrResp_fifof_enqueueing$whas,
       a4wrResp_fifof_x_wire$whas;

  // register a4rdResp_fifof_c_r
  reg [1 : 0] a4rdResp_fifof_c_r;
  wire [1 : 0] a4rdResp_fifof_c_r$D_IN;
  wire a4rdResp_fifof_c_r$EN;

  // register a4rdResp_fifof_q_0
  reg [33 : 0] a4rdResp_fifof_q_0;
  reg [33 : 0] a4rdResp_fifof_q_0$D_IN;
  wire a4rdResp_fifof_q_0$EN;

  // register a4rdResp_fifof_q_1
  reg [33 : 0] a4rdResp_fifof_q_1;
  reg [33 : 0] a4rdResp_fifof_q_1$D_IN;
  wire a4rdResp_fifof_q_1$EN;

  // register a4wrResp_fifof_c_r
  reg [1 : 0] a4wrResp_fifof_c_r;
  wire [1 : 0] a4wrResp_fifof_c_r$D_IN;
  wire a4wrResp_fifof_c_r$EN;

  // register a4wrResp_fifof_q_0
  reg [1 : 0] a4wrResp_fifof_q_0;
  reg [1 : 0] a4wrResp_fifof_q_0$D_IN;
  wire a4wrResp_fifof_q_0$EN;

  // register a4wrResp_fifof_q_1
  reg [1 : 0] a4wrResp_fifof_q_1;
  wire [1 : 0] a4wrResp_fifof_q_1$D_IN;
  wire a4wrResp_fifof_q_1$EN;

  // register b18
  reg [7 : 0] b18;
  wire [7 : 0] b18$D_IN;
  wire b18$EN;

  // register b19
  reg [7 : 0] b19;
  wire [7 : 0] b19$D_IN;
  wire b19$EN;

  // register b1A
  reg [7 : 0] b1A;
  wire [7 : 0] b1A$D_IN;
  wire b1A$EN;

  // register b1B
  reg [7 : 0] b1B;
  wire [7 : 0] b1B$D_IN;
  wire b1B$EN;

  // register r0
  reg [31 : 0] r0;
  wire [31 : 0] r0$D_IN;
  wire r0$EN;

  // register r4
  reg [31 : 0] r4;
  wire [31 : 0] r4$D_IN;
  wire r4$EN;

  // ports of submodule a4rdAddr_fifof
  wire [22 : 0] a4rdAddr_fifof$D_IN, a4rdAddr_fifof$D_OUT;
  wire a4rdAddr_fifof$CLR,
       a4rdAddr_fifof$DEQ,
       a4rdAddr_fifof$EMPTY_N,
       a4rdAddr_fifof$ENQ,
       a4rdAddr_fifof$FULL_N;

  // ports of submodule a4wrAddr_fifof
  wire [22 : 0] a4wrAddr_fifof$D_IN, a4wrAddr_fifof$D_OUT;
  wire a4wrAddr_fifof$CLR,
       a4wrAddr_fifof$DEQ,
       a4wrAddr_fifof$EMPTY_N,
       a4wrAddr_fifof$ENQ,
       a4wrAddr_fifof$FULL_N;

  // ports of submodule a4wrData_fifof
  wire [35 : 0] a4wrData_fifof$D_IN, a4wrData_fifof$D_OUT;
  wire a4wrData_fifof$CLR,
       a4wrData_fifof$DEQ,
       a4wrData_fifof$EMPTY_N,
       a4wrData_fifof$ENQ,
       a4wrData_fifof$FULL_N;

  // rule scheduling signals
  wire CAN_FIRE_RL_a4l_cfrd,
       CAN_FIRE_RL_a4l_cfwr,
       CAN_FIRE_RL_a4rdAddr_do_enq,
       CAN_FIRE_RL_a4rdResp_do_deq,
       CAN_FIRE_RL_a4rdResp_fifof_both,
       CAN_FIRE_RL_a4rdResp_fifof_decCtr,
       CAN_FIRE_RL_a4rdResp_fifof_incCtr,
       CAN_FIRE_RL_a4wrAddr_do_enq,
       CAN_FIRE_RL_a4wrData_do_enq,
       CAN_FIRE_RL_a4wrResp_do_deq,
       CAN_FIRE_RL_a4wrResp_fifof_both,
       CAN_FIRE_RL_a4wrResp_fifof_decCtr,
       CAN_FIRE_RL_a4wrResp_fifof_incCtr,
       CAN_FIRE_rdAddr_data,
       CAN_FIRE_rdAddr_valid,
       CAN_FIRE_rdResp_ready,
       CAN_FIRE_wrAddr_data,
       CAN_FIRE_wrAddr_valid,
       CAN_FIRE_wrData_data,
       CAN_FIRE_wrData_valid,
       CAN_FIRE_wrResp_ready,
       WILL_FIRE_RL_a4l_cfrd,
       WILL_FIRE_RL_a4l_cfwr,
       WILL_FIRE_RL_a4rdAddr_do_enq,
       WILL_FIRE_RL_a4rdResp_do_deq,
       WILL_FIRE_RL_a4rdResp_fifof_both,
       WILL_FIRE_RL_a4rdResp_fifof_decCtr,
       WILL_FIRE_RL_a4rdResp_fifof_incCtr,
       WILL_FIRE_RL_a4wrAddr_do_enq,
       WILL_FIRE_RL_a4wrData_do_enq,
       WILL_FIRE_RL_a4wrResp_do_deq,
       WILL_FIRE_RL_a4wrResp_fifof_both,
       WILL_FIRE_RL_a4wrResp_fifof_decCtr,
       WILL_FIRE_RL_a4wrResp_fifof_incCtr,
       WILL_FIRE_rdAddr_data,
       WILL_FIRE_rdAddr_valid,
       WILL_FIRE_rdResp_ready,
       WILL_FIRE_wrAddr_data,
       WILL_FIRE_wrAddr_valid,
       WILL_FIRE_wrData_data,
       WILL_FIRE_wrData_valid,
       WILL_FIRE_wrResp_ready;

  // inputs to muxes for submodule ports
  wire [33 : 0] MUX_a4rdResp_fifof_q_0$write_1__VAL_1,
		MUX_a4rdResp_fifof_q_0$write_1__VAL_2,
		MUX_a4rdResp_fifof_q_1$write_1__VAL_2;
  wire [1 : 0] MUX_a4rdResp_fifof_c_r$write_1__VAL_1,
	       MUX_a4rdResp_fifof_c_r$write_1__VAL_2,
	       MUX_a4wrResp_fifof_c_r$write_1__VAL_1,
	       MUX_a4wrResp_fifof_c_r$write_1__VAL_2,
	       MUX_a4wrResp_fifof_q_0$write_1__VAL_2;
  wire MUX_a4rdResp_fifof_q_0$write_1__SEL_1,
       MUX_a4rdResp_fifof_q_1$write_1__SEL_1,
       MUX_a4wrResp_fifof_q_0$write_1__SEL_1;

  // remaining internal signals
  reg [63 : 0] v__h3765, v__h3797, v__h4576;
  reg [31 : 0] _theResult____h3619;
  wire [31 : 0] rdat__h3735;

  // action method wrAddr_data
  assign CAN_FIRE_wrAddr_data = 1'd1 ;
  assign WILL_FIRE_wrAddr_data = 1'd1 ;

  // action method wrAddr_valid
  assign CAN_FIRE_wrAddr_valid = 1'd1 ;
  assign WILL_FIRE_wrAddr_valid = 1'd1 ;

  // value method wrAddr_ready
  assign wrAddr_ready = a4wrAddr_fifof$FULL_N ;

  // action method wrData_data
  assign CAN_FIRE_wrData_data = 1'd1 ;
  assign WILL_FIRE_wrData_data = 1'd1 ;

  // action method wrData_valid
  assign CAN_FIRE_wrData_valid = 1'd1 ;
  assign WILL_FIRE_wrData_valid = 1'd1 ;

  // value method wrData_ready
  assign wrData_ready = a4wrData_fifof$FULL_N ;

  // value method wrResp_data
  assign wrResp_data = a4wrResp_fifof_q_0 ;

  // value method wrResp_valid
  assign wrResp_valid = a4wrResp_fifof_c_r != 2'd0 ;

  // action method wrResp_ready
  assign CAN_FIRE_wrResp_ready = 1'd1 ;
  assign WILL_FIRE_wrResp_ready = 1'd1 ;

  // action method rdAddr_data
  assign CAN_FIRE_rdAddr_data = 1'd1 ;
  assign WILL_FIRE_rdAddr_data = 1'd1 ;

  // action method rdAddr_valid
  assign CAN_FIRE_rdAddr_valid = 1'd1 ;
  assign WILL_FIRE_rdAddr_valid = 1'd1 ;

  // value method rdAddr_ready
  assign rdAddr_ready = a4rdAddr_fifof$FULL_N ;

  // value method rdResp_data
  assign rdResp_data = a4rdResp_fifof_q_0 ;

  // value method rdResp_valid
  assign rdResp_valid = a4rdResp_fifof_c_r != 2'd0 ;

  // action method rdResp_ready
  assign CAN_FIRE_rdResp_ready = 1'd1 ;
  assign WILL_FIRE_rdResp_ready = 1'd1 ;

  // submodule a4rdAddr_fifof
  FIFO2 #(.width(32'd23), .guarded(32'd1)) a4rdAddr_fifof(.RST_N(RST_N),
							  .CLK(CLK),
							  .D_IN(a4rdAddr_fifof$D_IN),
							  .ENQ(a4rdAddr_fifof$ENQ),
							  .DEQ(a4rdAddr_fifof$DEQ),
							  .CLR(a4rdAddr_fifof$CLR),
							  .D_OUT(a4rdAddr_fifof$D_OUT),
							  .FULL_N(a4rdAddr_fifof$FULL_N),
							  .EMPTY_N(a4rdAddr_fifof$EMPTY_N));

  // submodule a4wrAddr_fifof
  FIFO2 #(.width(32'd23), .guarded(32'd1)) a4wrAddr_fifof(.RST_N(RST_N),
							  .CLK(CLK),
							  .D_IN(a4wrAddr_fifof$D_IN),
							  .ENQ(a4wrAddr_fifof$ENQ),
							  .DEQ(a4wrAddr_fifof$DEQ),
							  .CLR(a4wrAddr_fifof$CLR),
							  .D_OUT(a4wrAddr_fifof$D_OUT),
							  .FULL_N(a4wrAddr_fifof$FULL_N),
							  .EMPTY_N(a4wrAddr_fifof$EMPTY_N));

  // submodule a4wrData_fifof
  FIFO2 #(.width(32'd36), .guarded(32'd1)) a4wrData_fifof(.RST_N(RST_N),
							  .CLK(CLK),
							  .D_IN(a4wrData_fifof$D_IN),
							  .ENQ(a4wrData_fifof$ENQ),
							  .DEQ(a4wrData_fifof$DEQ),
							  .CLR(a4wrData_fifof$CLR),
							  .D_OUT(a4wrData_fifof$D_OUT),
							  .FULL_N(a4wrData_fifof$FULL_N),
							  .EMPTY_N(a4wrData_fifof$EMPTY_N));

  // rule RL_a4l_cfrd
  assign CAN_FIRE_RL_a4l_cfrd =
	     a4rdResp_fifof_c_r != 2'd2 && a4rdAddr_fifof$EMPTY_N ;
  assign WILL_FIRE_RL_a4l_cfrd = CAN_FIRE_RL_a4l_cfrd ;

  // rule RL_a4l_cfwr
  assign CAN_FIRE_RL_a4l_cfwr =
	     a4wrResp_fifof_c_r != 2'd2 && a4wrAddr_fifof$EMPTY_N &&
	     a4wrData_fifof$EMPTY_N ;
  assign WILL_FIRE_RL_a4l_cfwr = CAN_FIRE_RL_a4l_cfwr ;

  // rule RL_a4rdResp_do_deq
  assign CAN_FIRE_RL_a4rdResp_do_deq =
	     a4rdResp_fifof_c_r != 2'd0 && rdResp_ready_value ;
  assign WILL_FIRE_RL_a4rdResp_do_deq = CAN_FIRE_RL_a4rdResp_do_deq ;

  // rule RL_a4rdResp_fifof_both
  assign CAN_FIRE_RL_a4rdResp_fifof_both =
	     ((a4rdResp_fifof_c_r == 2'd1) ?
		CAN_FIRE_RL_a4l_cfrd :
		a4rdResp_fifof_c_r != 2'd2 || CAN_FIRE_RL_a4l_cfrd) &&
	     CAN_FIRE_RL_a4rdResp_do_deq &&
	     CAN_FIRE_RL_a4l_cfrd ;
  assign WILL_FIRE_RL_a4rdResp_fifof_both = CAN_FIRE_RL_a4rdResp_fifof_both ;

  // rule RL_a4rdResp_fifof_decCtr
  assign CAN_FIRE_RL_a4rdResp_fifof_decCtr =
	     CAN_FIRE_RL_a4rdResp_do_deq && !CAN_FIRE_RL_a4l_cfrd ;
  assign WILL_FIRE_RL_a4rdResp_fifof_decCtr =
	     CAN_FIRE_RL_a4rdResp_fifof_decCtr ;

  // rule RL_a4rdResp_fifof_incCtr
  assign CAN_FIRE_RL_a4rdResp_fifof_incCtr =
	     ((a4rdResp_fifof_c_r == 2'd0) ?
		CAN_FIRE_RL_a4l_cfrd :
		a4rdResp_fifof_c_r != 2'd1 || CAN_FIRE_RL_a4l_cfrd) &&
	     CAN_FIRE_RL_a4l_cfrd &&
	     !CAN_FIRE_RL_a4rdResp_do_deq ;
  assign WILL_FIRE_RL_a4rdResp_fifof_incCtr =
	     CAN_FIRE_RL_a4rdResp_fifof_incCtr ;

  // rule RL_a4rdAddr_do_enq
  assign CAN_FIRE_RL_a4rdAddr_do_enq =
	     a4rdAddr_fifof$FULL_N && rdAddr_valid_value ;
  assign WILL_FIRE_RL_a4rdAddr_do_enq = CAN_FIRE_RL_a4rdAddr_do_enq ;

  // rule RL_a4wrResp_do_deq
  assign CAN_FIRE_RL_a4wrResp_do_deq =
	     a4wrResp_fifof_c_r != 2'd0 && wrResp_ready_value ;
  assign WILL_FIRE_RL_a4wrResp_do_deq = CAN_FIRE_RL_a4wrResp_do_deq ;

  // rule RL_a4wrResp_fifof_both
  assign CAN_FIRE_RL_a4wrResp_fifof_both =
	     ((a4wrResp_fifof_c_r == 2'd1) ?
		CAN_FIRE_RL_a4l_cfwr :
		a4wrResp_fifof_c_r != 2'd2 || CAN_FIRE_RL_a4l_cfwr) &&
	     CAN_FIRE_RL_a4wrResp_do_deq &&
	     CAN_FIRE_RL_a4l_cfwr ;
  assign WILL_FIRE_RL_a4wrResp_fifof_both = CAN_FIRE_RL_a4wrResp_fifof_both ;

  // rule RL_a4wrResp_fifof_decCtr
  assign CAN_FIRE_RL_a4wrResp_fifof_decCtr =
	     CAN_FIRE_RL_a4wrResp_do_deq && !CAN_FIRE_RL_a4l_cfwr ;
  assign WILL_FIRE_RL_a4wrResp_fifof_decCtr =
	     CAN_FIRE_RL_a4wrResp_fifof_decCtr ;

  // rule RL_a4wrResp_fifof_incCtr
  assign CAN_FIRE_RL_a4wrResp_fifof_incCtr =
	     ((a4wrResp_fifof_c_r == 2'd0) ?
		CAN_FIRE_RL_a4l_cfwr :
		a4wrResp_fifof_c_r != 2'd1 || CAN_FIRE_RL_a4l_cfwr) &&
	     CAN_FIRE_RL_a4l_cfwr &&
	     !CAN_FIRE_RL_a4wrResp_do_deq ;
  assign WILL_FIRE_RL_a4wrResp_fifof_incCtr =
	     CAN_FIRE_RL_a4wrResp_fifof_incCtr ;

  // rule RL_a4wrAddr_do_enq
  assign CAN_FIRE_RL_a4wrAddr_do_enq =
	     a4wrAddr_fifof$FULL_N && wrAddr_valid_value ;
  assign WILL_FIRE_RL_a4wrAddr_do_enq = CAN_FIRE_RL_a4wrAddr_do_enq ;

  // rule RL_a4wrData_do_enq
  assign CAN_FIRE_RL_a4wrData_do_enq =
	     a4wrData_fifof$FULL_N && wrData_valid_value ;
  assign WILL_FIRE_RL_a4wrData_do_enq = CAN_FIRE_RL_a4wrData_do_enq ;

  // inputs to muxes for submodule ports
  assign MUX_a4rdResp_fifof_q_0$write_1__SEL_1 =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr &&
	     a4rdResp_fifof_c_r == 2'd0 ;
  assign MUX_a4rdResp_fifof_q_1$write_1__SEL_1 =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr &&
	     a4rdResp_fifof_c_r == 2'd1 ;
  assign MUX_a4wrResp_fifof_q_0$write_1__SEL_1 =
	     WILL_FIRE_RL_a4wrResp_fifof_incCtr &&
	     a4wrResp_fifof_c_r == 2'd0 ;
  assign MUX_a4rdResp_fifof_c_r$write_1__VAL_1 = a4rdResp_fifof_c_r + 2'd1 ;
  assign MUX_a4rdResp_fifof_c_r$write_1__VAL_2 = a4rdResp_fifof_c_r - 2'd1 ;
  assign MUX_a4rdResp_fifof_q_0$write_1__VAL_1 =
	     { 2'd0, _theResult____h3619 } ;
  assign MUX_a4rdResp_fifof_q_0$write_1__VAL_2 =
	     (a4rdResp_fifof_c_r == 2'd1) ?
	       MUX_a4rdResp_fifof_q_0$write_1__VAL_1 :
	       a4rdResp_fifof_q_1 ;
  assign MUX_a4rdResp_fifof_q_1$write_1__VAL_2 =
	     (a4rdResp_fifof_c_r == 2'd2) ?
	       MUX_a4rdResp_fifof_q_0$write_1__VAL_1 :
	       34'd0 ;
  assign MUX_a4wrResp_fifof_c_r$write_1__VAL_1 = a4wrResp_fifof_c_r + 2'd1 ;
  assign MUX_a4wrResp_fifof_c_r$write_1__VAL_2 = a4wrResp_fifof_c_r - 2'd1 ;
  assign MUX_a4wrResp_fifof_q_0$write_1__VAL_2 =
	     (a4wrResp_fifof_c_r == 2'd1) ? 2'd0 : a4wrResp_fifof_q_1 ;

  // inlined wires
  assign a4wrAddr_data_wire$wget = wrAddr_data_value ;
  assign a4wrAddr_enq_valid$whas = wrAddr_valid_value ;
  assign a4wrAddr_enq_enq$whas = 1'b0 ;
  assign a4wrData_enq_valid$whas = wrData_valid_value ;
  assign a4wrData_data_wire$wget = wrData_data_value ;
  assign a4wrData_enq_enq$whas = 1'b0 ;
  assign a4wrResp_fifof_enqueueing$whas = CAN_FIRE_RL_a4l_cfwr ;
  assign a4wrResp_fifof_x_wire$wget = 2'd0 ;
  assign a4wrResp_fifof_x_wire$whas = CAN_FIRE_RL_a4l_cfwr ;
  assign a4wrResp_fifof_dequeueing$whas = CAN_FIRE_RL_a4wrResp_do_deq ;
  assign a4wrResp_deq_ready$whas = wrResp_ready_value ;
  assign a4wrResp_deq_deq$whas = 1'b0 ;
  assign a4rdAddr_data_wire$wget = rdAddr_data_value ;
  assign a4rdAddr_enq_valid$whas = rdAddr_valid_value ;
  assign a4rdAddr_enq_enq$whas = 1'b0 ;
  assign a4rdResp_fifof_enqueueing$whas = CAN_FIRE_RL_a4l_cfrd ;
  assign a4rdResp_fifof_x_wire$wget = MUX_a4rdResp_fifof_q_0$write_1__VAL_1 ;
  assign a4rdResp_fifof_x_wire$whas = CAN_FIRE_RL_a4l_cfrd ;
  assign a4rdResp_deq_ready$whas = rdResp_ready_value ;
  assign a4rdResp_fifof_dequeueing$whas = CAN_FIRE_RL_a4rdResp_do_deq ;
  assign a4rdResp_deq_deq$whas = 1'b0 ;

  // register a4rdResp_fifof_c_r
  assign a4rdResp_fifof_c_r$D_IN =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr ?
	       MUX_a4rdResp_fifof_c_r$write_1__VAL_1 :
	       MUX_a4rdResp_fifof_c_r$write_1__VAL_2 ;
  assign a4rdResp_fifof_c_r$EN =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr ||
	     WILL_FIRE_RL_a4rdResp_fifof_decCtr ;

  // register a4rdResp_fifof_q_0
  always@(MUX_a4rdResp_fifof_q_0$write_1__SEL_1 or
	  MUX_a4rdResp_fifof_q_0$write_1__VAL_1 or
	  WILL_FIRE_RL_a4rdResp_fifof_both or
	  MUX_a4rdResp_fifof_q_0$write_1__VAL_2 or
	  WILL_FIRE_RL_a4rdResp_fifof_decCtr or a4rdResp_fifof_q_1)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_a4rdResp_fifof_q_0$write_1__SEL_1:
	  a4rdResp_fifof_q_0$D_IN = MUX_a4rdResp_fifof_q_0$write_1__VAL_1;
      WILL_FIRE_RL_a4rdResp_fifof_both:
	  a4rdResp_fifof_q_0$D_IN = MUX_a4rdResp_fifof_q_0$write_1__VAL_2;
      WILL_FIRE_RL_a4rdResp_fifof_decCtr:
	  a4rdResp_fifof_q_0$D_IN = a4rdResp_fifof_q_1;
      default: a4rdResp_fifof_q_0$D_IN =
		   34'h2AAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign a4rdResp_fifof_q_0$EN =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr &&
	     a4rdResp_fifof_c_r == 2'd0 ||
	     WILL_FIRE_RL_a4rdResp_fifof_both ||
	     WILL_FIRE_RL_a4rdResp_fifof_decCtr ;

  // register a4rdResp_fifof_q_1
  always@(MUX_a4rdResp_fifof_q_1$write_1__SEL_1 or
	  MUX_a4rdResp_fifof_q_0$write_1__VAL_1 or
	  WILL_FIRE_RL_a4rdResp_fifof_both or
	  MUX_a4rdResp_fifof_q_1$write_1__VAL_2 or
	  WILL_FIRE_RL_a4rdResp_fifof_decCtr)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_a4rdResp_fifof_q_1$write_1__SEL_1:
	  a4rdResp_fifof_q_1$D_IN = MUX_a4rdResp_fifof_q_0$write_1__VAL_1;
      WILL_FIRE_RL_a4rdResp_fifof_both:
	  a4rdResp_fifof_q_1$D_IN = MUX_a4rdResp_fifof_q_1$write_1__VAL_2;
      WILL_FIRE_RL_a4rdResp_fifof_decCtr: a4rdResp_fifof_q_1$D_IN = 34'd0;
      default: a4rdResp_fifof_q_1$D_IN =
		   34'h2AAAAAAAA /* unspecified value */ ;
    endcase
  end
  assign a4rdResp_fifof_q_1$EN =
	     WILL_FIRE_RL_a4rdResp_fifof_incCtr &&
	     a4rdResp_fifof_c_r == 2'd1 ||
	     WILL_FIRE_RL_a4rdResp_fifof_both ||
	     WILL_FIRE_RL_a4rdResp_fifof_decCtr ;

  // register a4wrResp_fifof_c_r
  assign a4wrResp_fifof_c_r$D_IN =
	     WILL_FIRE_RL_a4wrResp_fifof_incCtr ?
	       MUX_a4wrResp_fifof_c_r$write_1__VAL_1 :
	       MUX_a4wrResp_fifof_c_r$write_1__VAL_2 ;
  assign a4wrResp_fifof_c_r$EN =
	     WILL_FIRE_RL_a4wrResp_fifof_incCtr ||
	     WILL_FIRE_RL_a4wrResp_fifof_decCtr ;

  // register a4wrResp_fifof_q_0
  always@(MUX_a4wrResp_fifof_q_0$write_1__SEL_1 or
	  WILL_FIRE_RL_a4wrResp_fifof_both or
	  MUX_a4wrResp_fifof_q_0$write_1__VAL_2 or
	  WILL_FIRE_RL_a4wrResp_fifof_decCtr or a4wrResp_fifof_q_1)
  begin
    case (1'b1) // synopsys parallel_case
      MUX_a4wrResp_fifof_q_0$write_1__SEL_1: a4wrResp_fifof_q_0$D_IN = 2'd0;
      WILL_FIRE_RL_a4wrResp_fifof_both:
	  a4wrResp_fifof_q_0$D_IN = MUX_a4wrResp_fifof_q_0$write_1__VAL_2;
      WILL_FIRE_RL_a4wrResp_fifof_decCtr:
	  a4wrResp_fifof_q_0$D_IN = a4wrResp_fifof_q_1;
      default: a4wrResp_fifof_q_0$D_IN = 2'b10 /* unspecified value */ ;
    endcase
  end
  assign a4wrResp_fifof_q_0$EN =
	     WILL_FIRE_RL_a4wrResp_fifof_incCtr &&
	     a4wrResp_fifof_c_r == 2'd0 ||
	     WILL_FIRE_RL_a4wrResp_fifof_both ||
	     WILL_FIRE_RL_a4wrResp_fifof_decCtr ;

  // register a4wrResp_fifof_q_1
  assign a4wrResp_fifof_q_1$D_IN = 2'd0 ;
  assign a4wrResp_fifof_q_1$EN =
	     WILL_FIRE_RL_a4wrResp_fifof_incCtr &&
	     a4wrResp_fifof_c_r == 2'd1 ||
	     WILL_FIRE_RL_a4wrResp_fifof_both ||
	     WILL_FIRE_RL_a4wrResp_fifof_decCtr ;

  // register b18
  assign b18$D_IN = a4wrData_fifof$D_OUT[7:0] ;
  assign b18$EN =
	     WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h18 &&
	     a4wrData_fifof$D_OUT[32] ;

  // register b19
  assign b19$D_IN = a4wrData_fifof$D_OUT[15:8] ;
  assign b19$EN =
	     WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h18 &&
	     a4wrData_fifof$D_OUT[33] ;

  // register b1A
  assign b1A$D_IN = a4wrData_fifof$D_OUT[23:16] ;
  assign b1A$EN =
	     WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h18 &&
	     a4wrData_fifof$D_OUT[34] ;

  // register b1B
  assign b1B$D_IN = a4wrData_fifof$D_OUT[31:24] ;
  assign b1B$EN =
	     WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h18 &&
	     a4wrData_fifof$D_OUT[35] ;

  // register r0
  assign r0$D_IN = a4wrData_fifof$D_OUT[31:0] ;
  assign r0$EN = WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h0 ;

  // register r4
  assign r4$D_IN = a4wrData_fifof$D_OUT[31:0] ;
  assign r4$EN = WILL_FIRE_RL_a4l_cfwr && a4wrAddr_fifof$D_OUT[7:0] == 8'h04 ;

  // submodule a4rdAddr_fifof
  assign a4rdAddr_fifof$D_IN = rdAddr_data_value ;
  assign a4rdAddr_fifof$DEQ = CAN_FIRE_RL_a4l_cfrd ;
  assign a4rdAddr_fifof$ENQ = CAN_FIRE_RL_a4rdAddr_do_enq ;
  assign a4rdAddr_fifof$CLR = 1'b0 ;

  // submodule a4wrAddr_fifof
  assign a4wrAddr_fifof$D_IN = wrAddr_data_value ;
  assign a4wrAddr_fifof$DEQ = CAN_FIRE_RL_a4l_cfwr ;
  assign a4wrAddr_fifof$ENQ = CAN_FIRE_RL_a4wrAddr_do_enq ;
  assign a4wrAddr_fifof$CLR = 1'b0 ;

  // submodule a4wrData_fifof
  assign a4wrData_fifof$D_IN = wrData_data_value ;
  assign a4wrData_fifof$DEQ = CAN_FIRE_RL_a4l_cfwr ;
  assign a4wrData_fifof$ENQ = CAN_FIRE_RL_a4wrData_do_enq ;
  assign a4wrData_fifof$CLR = 1'b0 ;

  // remaining internal signals
  assign rdat__h3735 = { b1B, b1A, b19, b18 } ;
  always@(a4rdAddr_fifof$D_OUT or r0 or r4 or rdat__h3735)
  begin
    case (a4rdAddr_fifof$D_OUT[7:0])
      8'h0: _theResult____h3619 = r0;
      8'h04: _theResult____h3619 = r4;
      8'h18: _theResult____h3619 = rdat__h3735;
      default: _theResult____h3619 = 32'd0;
    endcase
  end

  // handling of inlined registers

  always@(posedge CLK)
  begin
    if (!RST_N)
      begin
        a4rdResp_fifof_c_r <= `BSV_ASSIGNMENT_DELAY 2'd0;
	a4rdResp_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY 34'd0;
	a4rdResp_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY 34'd0;
	a4wrResp_fifof_c_r <= `BSV_ASSIGNMENT_DELAY 2'd0;
	a4wrResp_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY 2'd0;
	a4wrResp_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY 2'd0;
	b18 <= `BSV_ASSIGNMENT_DELAY 8'h18;
	b19 <= `BSV_ASSIGNMENT_DELAY 8'h19;
	b1A <= `BSV_ASSIGNMENT_DELAY 8'h1A;
	b1B <= `BSV_ASSIGNMENT_DELAY 8'h1B;
	r0 <= `BSV_ASSIGNMENT_DELAY 32'd0;
	r4 <= `BSV_ASSIGNMENT_DELAY 32'd0;
      end
    else
      begin
        if (a4rdResp_fifof_c_r$EN)
	  a4rdResp_fifof_c_r <= `BSV_ASSIGNMENT_DELAY a4rdResp_fifof_c_r$D_IN;
	if (a4rdResp_fifof_q_0$EN)
	  a4rdResp_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY a4rdResp_fifof_q_0$D_IN;
	if (a4rdResp_fifof_q_1$EN)
	  a4rdResp_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY a4rdResp_fifof_q_1$D_IN;
	if (a4wrResp_fifof_c_r$EN)
	  a4wrResp_fifof_c_r <= `BSV_ASSIGNMENT_DELAY a4wrResp_fifof_c_r$D_IN;
	if (a4wrResp_fifof_q_0$EN)
	  a4wrResp_fifof_q_0 <= `BSV_ASSIGNMENT_DELAY a4wrResp_fifof_q_0$D_IN;
	if (a4wrResp_fifof_q_1$EN)
	  a4wrResp_fifof_q_1 <= `BSV_ASSIGNMENT_DELAY a4wrResp_fifof_q_1$D_IN;
	if (b18$EN) b18 <= `BSV_ASSIGNMENT_DELAY b18$D_IN;
	if (b19$EN) b19 <= `BSV_ASSIGNMENT_DELAY b19$D_IN;
	if (b1A$EN) b1A <= `BSV_ASSIGNMENT_DELAY b1A$D_IN;
	if (b1B$EN) b1B <= `BSV_ASSIGNMENT_DELAY b1B$D_IN;
	if (r0$EN) r0 <= `BSV_ASSIGNMENT_DELAY r0$D_IN;
	if (r4$EN) r4 <= `BSV_ASSIGNMENT_DELAY r4$D_IN;
      end
  end

  // synopsys translate_off
  `ifdef BSV_NO_INITIAL_BLOCKS
  `else // not BSV_NO_INITIAL_BLOCKS
  initial
  begin
    a4rdResp_fifof_c_r = 2'h2;
    a4rdResp_fifof_q_0 = 34'h2AAAAAAAA;
    a4rdResp_fifof_q_1 = 34'h2AAAAAAAA;
    a4wrResp_fifof_c_r = 2'h2;
    a4wrResp_fifof_q_0 = 2'h2;
    a4wrResp_fifof_q_1 = 2'h2;
    b18 = 8'hAA;
    b19 = 8'hAA;
    b1A = 8'hAA;
    b1B = 8'hAA;
    r0 = 32'hAAAAAAAA;
    r4 = 32'hAAAAAAAA;
  end
  `endif // BSV_NO_INITIAL_BLOCKS
  // synopsys translate_on

  // handling of system tasks

  // synopsys translate_off
  always@(negedge CLK)
  begin
    #0;
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfrd)
	begin
	  v__h3765 = $time;
	  #0;
	end
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfrd)
	$display("[%0d]: %m: AXI4-LITE CONFIG READ Addr:%0x",
		 v__h3765,
		 a4rdAddr_fifof$D_OUT[19:0]);
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfrd)
	begin
	  v__h3797 = $time;
	  #0;
	end
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfrd)
	$display("[%0d]: %m: AXI4-LITE CONFIG READ RESPOSNE Data:%0x",
		 v__h3797,
		 _theResult____h3619);
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfwr)
	begin
	  v__h4576 = $time;
	  #0;
	end
    if (RST_N)
      if (WILL_FIRE_RL_a4l_cfwr)
	$display("[%0d]: %m: AXI4-LITE CONFIG WRITE Addr:%0x BE:%0x Data:%0x",
		 v__h4576,
		 a4wrAddr_fifof$D_OUT[19:0],
		 a4wrData_fifof$D_OUT[35:32],
		 a4wrData_fifof$D_OUT[31:0]);
  end
  // synopsys translate_on
endmodule  // mkA4LS

