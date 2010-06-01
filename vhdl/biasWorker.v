// biasWorker.v - hand coded verilog of biasWorker
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

// 2009-07-11 ssiegel creation
// 2010-01-19 ssiegel VHDL manually converted to Verilog 
// 2010-03-01 ssiegel Added Peer-Peer WSI Resets

  module biasWorker (
   input         clk,
   input         rst_n,

   // Worker Control Interface (WCI) Slave Signals...
   input      [2:0]  wci_MCmd,
   input      [0:0]  wci_MAddrSpace,
   input      [3:0]  wci_MByteEn,
   input      [19:0] wci_MAddr,
   input      [31:0] wci_MData,
   output reg [1:0]  wci_SResp,
   output reg [31:0] wci_SData,
   input      [1:0]  wci_MFlag,
   output reg [1:0]  wci_SFlag,
   output reg        wci_SThreadBusy,

   // Worker Streaming Interface (WSI0) Slave Signals...
   input [2:0]       wsi0_MCmd,
   input             wsi0_MReqLast,
   input             wsi0_MBurstPrecise,
   input [11:0]      wsi0_MBurstLength,
   input [31:0]      wsi0_MData,
   input [3:0]       wsi0_MByteEn,
   input [7:0]       wsi0_MReqInfo,
   output            wsi0_SThreadBusy,

   // Worker Streaming Interface (WSI1) Master Signals...
   output reg [2:0]  wsi1_MCmd,
   output reg        wsi1_MReqLast,
   output reg        wsi1_MBurstPrecise,
   output reg [11:0] wsi1_MBurstLength,
   output reg [31:0] wsi1_MData,
   output reg [3:0]  wsi1_MByteEn,
   output reg [7:0]  wsi1_MReqInfo,
   input             wsi1_SThreadBusy,

   // Peer to Peer OCP Resets...
   output            wsi_m_MReset_n,
   input             wsi_m_SReset_n,
   input             wsi_s_MReset_n,
   output            wsi_s_SReset_n
 );

  reg [31:0] biasValue;
  reg [2:0]  wci_ctlSt;
  wire wci_cfg_write, wci_cfg_read, wci_ctl_op;

  assign wci_cfg_write = (wci_MCmd==3'h1 && wci_MAddrSpace[0]==1'b1);
  assign wci_cfg_read  = (wci_MCmd==3'h2 && wci_MAddrSpace[0]==1'b1);
  assign wci_ctl_op    = (wci_MCmd==3'h2 && wci_MAddrSpace[0]==1'b0);

  // When this worker is WCI reset, propagate reset out to WSI partners...
  assign wsi_m_MReset_n = rst_n;
  assign wsi_s_SReset_n = rst_n;

  //Pass the SThreadBusy upstream without pipelining...
  assign wsi0_SThreadBusy = (wsi1_SThreadBusy || (wci_ctlSt!=2'h2));
  
  always@(posedge clk)
  begin
                                           // Registered Operations that don't care about reset...
    if (wci_ctlSt == 2'h2) begin           // Implement the biasWorker function when operating...
      wsi1_MData = wsi0_MData + biasValue; // add the bias
      wsi1_MCmd  = wsi0_MCmd;
    end else begin                         // Or block the WSI pipeline cleanly...
      wsi1_MData = 0;
      wsi1_MCmd  = 3'h0;                   // Idle
    end
    
	 // Pass through signals of the WSI interface that we maintain, but do not use...
    wsi1_MReqLast       = wsi0_MReqLast;
    wsi1_MBurstPrecise  = wsi0_MBurstPrecise;
    wsi1_MBurstLength   = wsi0_MBurstLength;
    wsi1_MByteEn        = wsi0_MByteEn;
    wsi1_MReqInfo       = wsi0_MReqInfo;

    // Implement minimal WCI attach logic...
    wci_SThreadBusy     = 1'b0;                 
    wci_SResp           = 2'b0;

    if (rst_n==1'b0) begin                 // Reset Conditions...
      wci_ctlSt       = 3'h0;
      wci_SResp       = 2'h0;
      wci_SFlag       = 2'h0;
      wci_SThreadBusy = 2'b1;             
      biasValue       = 32'h0000_0000;
    end else begin                         // When not Reset...
      // WCI Configuration Property Writes...
      if (wci_cfg_write==1'b1) begin
        biasValue = wci_MData;             // Write the biasValue Configuration Property
        wci_SResp = 2'h1;
      end
      // WCI Configuration Property Reads...
      if (wci_cfg_read==1'b1) begin
        wci_SData = biasValue;             // Read the biasValue Configuration Property
        wci_SResp = 2'h1;
      end
      //WCI Control Operations...
      if (wci_ctl_op==1'b1) begin 
        case (wci_MAddr[4:2]) 
          2'h0 : wci_ctlSt = 3'h1;  // when wciCtlOp_Initialize  => wci_ctlSt  <= wciCtlSt_Initialized;
          2'h1 : wci_ctlSt = 3'h2;  // when wciCtlOp_Start       => wci_ctlSt  <= wciCtlSt_Operating;
          2'h2 : wci_ctlSt = 3'h3;  // when wciCtlOp_Stop        => wci_ctlSt  <= wciCtlSt_Suspended;
          2'h3 : wci_ctlSt = 3'h0;  // when wciCtlOp_Release     => wci_ctlSt  <= wciCtlSt_Exists;
        endcase
        wci_SData = 32'hC0DE_4201;
        wci_SResp = 2'h1;
      end  

    end  // end of not reset clause
  end  // end of always block
endmodule

// Type definitions from VHDL...
//subtype  wciCtlOpT is std_logic_vector(2 downto 0);
  //constant wciCtlOp_Initialize  : wciCtlOpT  := "000";
  //constant wciCtlOp_Start       : wciCtlOpT  := "001";
  //constant wciCtlOp_Stop        : wciCtlOpT  := "010";
  //constant wciCtlOp_Release     : wciCtlOpT  := "011";
  //constant wciCtlOp_Test        : wciCtlOpT  := "100";
  //constant wciCtlOp_BeforeQuery : wciCtlOpT  := "101";
  //constant wciCtlOp_AfterConfig : wciCtlOpT  := "110";
  //constant wciCtlOp_Rsvd7       : wciCtlOpT  := "111";
//subtype  wciCtlStT is std_logic_vector(2 downto 0);
  //constant wciCtlSt_Exists      : wciCtlStT  := "000";
  //constant wciCtlSt_Initialized : wciCtlStT  := "001";
  //constant wciCtlSt_Operating   : wciCtlStT  := "010";
  //constant wciCtlSt_Suspended   : wciCtlStT  := "011";
  //constant wciCtlSt_Unusable    : wciCtlStT  := "100";
  //constant wciCtlSt_Rsvd5       : wciCtlStT  := "101";
  //constant wciCtlSt_Rsvd6       : wciCtlStT  := "110";
  //constant wciCtlSt_Rsvd7       : wciCtlStT  := "111";
//subtype  wciRespT is std_logic_vector(31 downto 0);
  //constant wciResp_OK           : wciRespT   := X"C0DE_4201";
  //constant wciResp_Error        : wciRespT   := X"C0DE_4202";
  //constant wciResp_Timeout      : wciRespT   := X"C0DE_4203";
  //constant wciResp_Reset        : wciRespT   := X"C0DE_4204";
//subtype  ocpCmdT is std_logic_vector(2 downto 0);
  //constant ocpCmd_IDLE          : ocpCmdT    := "000";
  //constant ocpCmd_WR            : ocpCmdT    := "001";
  //constant ocpCmd_RD            : ocpCmdT    := "010";
//subtype  ocpRespT is std_logic_vector(1 downto 0);
  //constant ocpResp_NULL         : ocpRespT   := "00";
  //constant ocpResp_DVA          : ocpRespT   := "01";
  //constant ocpResp_FAIL         : ocpRespT   := "10";
  //constant ocpResp_ERR          : ocpRespT   := "11";
