// Verilog wrapper around VHDL Bias Worker
// ssiegel 2012-10-06

module mkBiasWorker4B(
  input           wciS0_Clk,
  input           wciS0_MReset_n,
  input  [2 : 0]  wciS0_MCmd,
  input           wciS0_MAddrSpace,
  input  [3 : 0]  wciS0_MByteEn,
  input  [31 : 0] wciS0_MAddr,
  input  [31 : 0] wciS0_MData,
  output [1 : 0]  wciS0_SResp,
  output [31 : 0] wciS0_SData,
  output          wciS0_SThreadBusy,
  output [1 : 0]  wciS0_SFlag,
  input  [1 : 0]  wciS0_MFlag,
  input  [2 : 0]  wsiS0_MCmd,
  input           wsiS0_MReqLast,
  input           wsiS0_MBurstPrecise,
  input  [11 : 0] wsiS0_MBurstLength,
  input  [31 : 0] wsiS0_MData,
  input  [3 : 0]  wsiS0_MByteEn,
  input  [7 : 0]  wsiS0_MReqInfo,
  output          wsiS0_SThreadBusy,
  output          wsiS0_SReset_n,
  input           wsiS0_MReset_n,
  output [2 : 0]  wsiM0_MCmd,
  output          wsiM0_MReqLast,
  output          wsiM0_MBurstPrecise,
  output [11 : 0] wsiM0_MBurstLength,
  output [31 : 0] wsiM0_MData,
  output [3 : 0]  wsiM0_MByteEn,
  output [7 : 0]  wsiM0_MReqInfo,
  input           wsiM0_SThreadBusy,
  output          wsiM0_MReset_n,
  input           wsiM0_SReset_n );

// Instance the VHDL Bias Worker "bias_vhdl"...
  bias_vhdl bias_vi(
    .ctl_Clk               (wciS0_Clk),           // in  std_logic;
    .ctl_MAddr             (wciS0_MAddr),         // in  std_logic_vector(4 downto 0);
    .ctl_MAddrSpace        (wciS0_MAddrSpace),    // in  std_logic_vector(0 downto 0);
    .ctl_MCmd              (wciS0_MCmd),          // in  std_logic_vector(2 downto 0);
    .ctl_MData             (wciS0_MData),         // in  std_logic_vector(31 downto 0);
    .ctl_MFlag             (wciS0_MFlag),         // in  std_logic_vector(1 downto 0);
    .ctl_MReset_n          (wciS0_MReset_n),      // in  std_logic;
    .ctl_SData             (wciS0_SData),         // out std_logic_vector(31 downto 0);
    .ctl_SFlag             (wciS0_SFlag),         // out std_logic_vector(1 downto 0);
    .ctl_SResp             (wciS0_SResp),         // out std_logic_vector(1 downto 0);
    .ctl_SThreadBusy       (wciS0_SThreadBusy),   // out std_logic_vector(0 downto 0);

    .in_MBurstLength       (wsiS0_MBurstLength),  // in  std_logic_vector(11 downto 0);
    .in_MByteEn            (wsiS0_MByteEn),       // in  std_logic_vector(3 downto 0);
    .in_MCmd               (wsiS0_MCmd),          // in  std_logic_vector(2 downto 0);
    .in_MData              (wsiS0_MData),         // in  std_logic_vector(31 downto 0);
    .in_MBurstPrecise      (wsiS0_MBurstPrecise), // in  std_logic;
    .in_MReqInfo           (wsiS0_MReqInfo),      // in  std_logic_vector(7 downto 0);
    .in_MReqLast           (wsiS0_MReqLast),      // in  std_logic;
    .in_MReset_n           (wsiS0_MReset_n),      // in  std_logic;
    .in_SReset_n           (wsiS0_SReset_n),      // out std_logic;
    .in_SThreadBusy        (wsiS0_SThreadBusy),   // out std_logic_vector(0 downto 0);

    .out_SReset_n          (wsiM0_SReset_n),      // in  std_logic;
    .out_SThreadBusy       (wsiM0_SThreadBusy),   // in  std_logic_vector(0 downto 0);
    .out_MBurstLength      (wsiM0_MBurstLength),  // out std_logic_vector(11 downto 0);
    .out_MByteEn           (wsiM0_MByteEn),       // out std_logic_vector(3 downto 0);
    .out_MCmd              (wsiM0_MCmd),          // out std_logic_vector(2 downto 0);
    .out_MData             (wsiM0_MData),         // out std_logic_vector(31 downto 0);
    .out_MBurstPrecise     (wsiM0_MBurstPrecise), // out std_logic;
    .out_MReqInfo          (wsiM0_MReqInfo),      // out std_logic_vector(7 downto 0);
    .out_MReqLast          (wsiM0_MReqLast),      // out std_logic;
    .out_MReset_n          (wsiM0_MReset_n)       // out std_logic 
  );

endmodule 
