// arSRLFIFOD.v
// Copyright (c) 2009, 2010, 2011 Atomic Rules LLC, ALL RIGHTS RESERVED
//
// 2009-05-10 ssiegel Creation in VHDL
// 2009-11-01 ssiegel Converted to Verilog from VHDL
// 2009-11-14 ssiegel Add D flop at back end for greater Fmax
// 2011-06-17 ssiegel Update logic to follow non-registered version
// 2011-07-28 hyzeng  Changed ENQ action so that XST for both V5 and V6 would infer SRL

module arSRLFIFOD (CLK,RST_N,ENQ,DEQ,FULL_N,EMPTY_N,D_IN,D_OUT,CLR);

  parameter  width   = 128;
  parameter  l2depth = 5;
  localparam depth   = 2**l2depth;

  input             CLK;
  input             RST_N;
  input             CLR;
  input             ENQ;
  input             DEQ;
  output            FULL_N;
  output            EMPTY_N;
  input[width-1:0]  D_IN;
  output[width-1:0] D_OUT;

  reg[l2depth-1:0]  pos;             // head position
  reg[depth-1:0]    dat[width-1:0];  // SRL FIFO
  reg[width-1:0]    dreg;            // Ouput register
  reg               sempty, sfull, dempty;
  wire              sdx;             // SRL-DEQ and D-ENQ 
  wire[l2depth-1:0] pos_minus_one = pos - 1;

  integer i;

  always@(posedge CLK) begin
    if(!RST_N || CLR) begin
      pos      <= 'b0;
      sempty   <= 1'b1;
      sfull    <= 1'b0;
      dempty   <= 1'b1;
    end else begin
      if (!ENQ &&  sdx) pos <= pos - 1;
      if ( ENQ && !sdx) pos <= pos + 1;
      if (ENQ) for(i=0;i<width;i=i+1) dat[i] <= {dat[i][depth-2:0],D_IN[i]};
      sempty <= ((pos==0         && !ENQ) || (pos==1         && (sdx&&!ENQ)));
      sfull  <= ((pos==(depth-1) && !sdx) || (pos==(depth-2) && (ENQ&&!sdx)));

      // This registered version of the SRLFIFO operates as if there is 1-deep FIFO
      // appended to the output of the SRL FIFO. An ENQ of of the 1-deep FIFO 
      // must happen with a DEQ of the SRL FIFO, this internal signal is "sdx"
      if (sdx) begin 
        //dreg   <= dat[pos-1];  // transfer the SRL to the D reg
        for(i=0;i<width;i=i+1) dreg[i] <= dat[i][pos_minus_one];
        dempty <= 1'b0;        // dempty becomes False when we load the 1-deep FIFO
      end
      if (DEQ && sempty) begin
        dempty <= 1'b1;        // dempty becomes True when we DEQ and nothing to sdx
      end
    end
  end

  assign sdx     =  ((dempty && !sempty) || (!dempty && DEQ && !sempty));
  assign FULL_N  = !sfull;
  assign EMPTY_N = !dempty;
  assign D_OUT   = dreg;

endmodule
