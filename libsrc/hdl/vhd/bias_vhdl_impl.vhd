-- THIS FILE WAS GENERATED ON Mon Oct 15 08:27:13 2012 EDT
-- BASED ON THE FILE: bias_vhdl.xml
-- YOU PROBABLY SHOULD NOT EDIT IT
-- This file contains the implementation declarations for worker bias_vhdl
-- Interface definition signal names defined with pattern rule: "%s_"

--                   OCP-based Control Interface, based on the WCI profile,
--                      used for clk/reset, control and configuration
--                                           /\
--                                          /--\
--               +--------------------OCP----||----OCP---------------------------+
--               |                          \--/                                 |
--               |                           \/                                  |
--               |                   Entity: <worker>                            |
--               |                                                               |
--               O   +------------------------------------------------------+    O
--               C   |            Entity: <worker>_worker                   |    C
--               P   |                                                      |    P
--               |   | This "inner layer" is the code you write, based      |    |
-- Data Input    |\  | on definitions the in <worker>_worker_defs package,  |    |\  Data Output
-- Port based  ==| \ | and the <worker>_worker entity, both in this file,   |   =| \ Port based
-- on the WSI  ==| / | both in the "work" library.                          |   =| / on the WSI
-- OCP Profile   |/  | Package and entity declaration is this               |    |/  OCP Profile
--               O   | <worker>_impl.vhd file. Architeture is in your       |    |
--               O   |  <worker>.vhd file                                   |    O
--               C   |                                                      |    C
--               P   +------------------------------------------------------+    P
--               |                                                               |
--               |     This outer layer is the "worker shell" code which         |
--               |     is automatically generated.  The "worker shell" is        |
--               |     defined as the <worker> entity using definitions in       |
--               |     the <worker>_defs package.  The worker shell is also      |
--               |     defined as a VHDL component in the <worker>_defs package, |
--               |     as declared in the <worker>_defs.vhd file.                |
--               |     The worker shell "architecture" is also in this file,      |
--               |     as well as some subsidiary modules.                       |
--               +---------------------------------------------------------------+

-- This package defines types needed for the inner worker entity's generics or ports
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library ocpi;
 use ocpi.all; use ocpi.types.all;
package bias_vhdl_worker_defs is

  -- The following two records are for the inner/worker interfaces for port "ctl"
  type worker_ctl_in_t is record
    clk              : std_logic;        -- clock for this worker
    reset            : Bool_t;           -- reset for this worker, at least 16 clocks long
    control_op       : wci.control_op_t; -- control op in progress, or no_op_e
    state            : wci.state_t;      -- wci state: see state_t
    is_operating     : Bool_t;           -- shorthand for state = operating_e
    abort_control_op : Bool_t;           -- demand that slow control op finish now
    is_big_endian    : Bool_t;           -- for endian-switchable workers
  end record worker_ctl_in_t;
  type worker_ctl_out_t is record
    done             : Bool_t;           -- is the pending prop access/config op done?
    attention        : Bool_t;           -- worker wants attention
  end record worker_ctl_out_t;

  -- The following two records are for the inner/worker interfaces for port "in"
  type worker_in_in_t is record
    reset            : Bool_t;           -- this port is being reset from the outside
    ready            : Bool_t;           -- this port is ready for data to be taken
                                         -- one or more of: som, eom, valid are true
    data             : std_logic_vector(31 downto 0);
    byte_enable      : std_logic_vector(3 downto 0);
    som, eom, valid  : Bool_t;           -- valid means data and byte_enable are present
  end record worker_in_in_t;
  type worker_in_out_t is record
    take             : Bool_t;           -- take data now from this port
                                         -- can be asserted when ready is true
  end record worker_in_out_t;

  -- The following two records are for the inner/worker interfaces for port "out"
  type worker_out_in_t is record
    reset            : Bool_t;           -- this port is being reset from the outside
    ready            : Bool_t;           -- this port is ready for data to be given
  end record worker_out_in_t;
  type worker_out_out_t is record
    give             : Bool_t;           -- give data now to this port
                                         -- can be asserted when ready is true
    data             : std_logic_vector(31 downto 0);
    byte_enable      : std_logic_vector(3 downto 0);
    som, eom, valid : Bool_t;            -- one or more must be true when 'give' is asserted
  end record worker_out_out_t;
end package bias_vhdl_worker_defs;

-- This is the entity to be implemented, depending on the above record types.
library ocpi; use ocpi.types.all;
library work; use work.bias_vhdl_worker_defs.all;
entity bias_vhdl_worker is
  port(
    -- Signals for control and configuration.  See record types above.
    ctl_in            : in  worker_ctl_in_t;
    ctl_out           : out worker_ctl_out_t;
    -- Registered inputs for this worker's writable properties
    biasValue_value   : in  ULong_t;
    biasValue_written : in  Bool_t;
    -- Signals for WSI input port named "in".  See record types above.
    in_in             : in  worker_in_in_t;
    in_out            : out worker_in_out_t;
    -- Signals for WSI output port named "out".  See record types above.
    out_in            : in  worker_out_in_t;
    out_out           : out worker_out_out_t);
end entity bias_vhdl_worker;
-- The rest of the file below here is the implementation of the wrapper
-- which surrounds the entity to be implemented, above.



-- Worker-specific definitions that are needed outside entities below
package body bias_vhdl_defs is
  constant worker : ocpi.wci.worker_t := (5, "00000100");
  constant properties : ocpi.wci.properties_t := (
   0 => (32,      0,      3,      0,      1, true,  true,  false, false)
  );
end bias_vhdl_defs;
-- This is the entity declaration that the worker developer will implement
-- The achitecture for this entity will be in the implementation file
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library ocpi;
 use ocpi.all; use ocpi.types.all;
library work;
 use work.all;
 use work.bias_vhdl_defs.all;
entity bias_vhdl is
  port (

    -- The WCI interface named "ctl", with "bias_vhdl" acting as OCP slave:
    -- WIP attributes for this WCI interface are:
    --   Clock: this interface has its own clock, named "ctl_Clk"
    --   SizeOfConfigSpace: 4 (0x4)
    --   WritableConfigProperties: true
    --   ReadableConfigProperties: true
    --   Sub32BitConfigProperties: false
    --   ControlOperations (in addition to the required "start"): 
    --   ResetWhileSuspended: true
    ctl_Clk               : in std_logic;
    ctl_MAddr             : in std_logic_vector(4 downto 0);
    ctl_MAddrSpace        : in std_logic_vector(0 downto 0);
    ctl_MCmd              : in std_logic_vector(2 downto 0);
    ctl_MData             : in std_logic_vector(31 downto 0);
    ctl_MFlag             : in std_logic_vector(1 downto 0);
    ctl_MReset_n          : in std_logic;
    ctl_SData             : out std_logic_vector(31 downto 0);
    ctl_SFlag             : out std_logic_vector(1 downto 0);
    ctl_SResp             : out std_logic_vector(1 downto 0);
    ctl_SThreadBusy       : out std_logic_vector(0 downto 0);

    -- The WSI consumer interface named "in", with "bias_vhdl" acting as OCP slave:
    -- WIP attributes for this WSI interface are:
    --   Clock: uses the clock from interface named "ctl"
    --   Protocol: "stream32"
    --   DataValueWidth: 8
    --   DataValueGranularity: 1
    --   DiverseDataSizes: false
    --   MaxMessageValues: 16380
    --   NumberOfOpcodes: 256
    --   Producer: false
    --   VariableMessageLength: true
    --   ZeroLengthMessages: true
    --   Continuous: false
    --   DataWidth: 32
    --   ByteWidth: 8
    --   ImpreciseBurst: true
    --   Preciseburst: true
    --   Abortable: false
    --   EarlyRequest: false
    -- No Clk signal here. The "in" interface uses "ctl_Clk" as clock
    in_MBurstLength       : in std_logic_vector(11 downto 0);
    in_MByteEn            : in std_logic_vector(3 downto 0);
    in_MCmd               : in std_logic_vector(2 downto 0);
    in_MData              : in std_logic_vector(31 downto 0);
    in_MBurstPrecise      : in std_logic;
    in_MReqInfo           : in std_logic_vector(7 downto 0);
    in_MReqLast           : in std_logic;
    in_MReset_n           : in std_logic;
    in_SReset_n           : out std_logic;
    in_SThreadBusy        : out std_logic_vector(0 downto 0);

    -- The WSI producer interface named "out", with "bias_vhdl" acting as OCP master:
    -- WIP attributes for this WSI interface are:
    --   Clock: uses the clock from interface named "ctl"
    --   Protocol: "stream32"
    --   DataValueWidth: 8
    --   DataValueGranularity: 1
    --   DiverseDataSizes: false
    --   MaxMessageValues: 16380
    --   NumberOfOpcodes: 256
    --   Producer: true
    --   VariableMessageLength: true
    --   ZeroLengthMessages: true
    --   Continuous: false
    --   DataWidth: 32
    --   ByteWidth: 8
    --   ImpreciseBurst: true
    --   Preciseburst: true
    --   Abortable: false
    --   EarlyRequest: false
    -- No Clk signal here. The "out" interface uses "ctl_Clk" as clock
    out_SReset_n          : in std_logic;
    out_SThreadBusy       : in std_logic_vector(0 downto 0);
    out_MBurstLength      : out std_logic_vector(11 downto 0);
    out_MByteEn           : out std_logic_vector(3 downto 0);
    out_MCmd              : out std_logic_vector(2 downto 0);
    out_MData             : out std_logic_vector(31 downto 0);
    out_MBurstPrecise     : out std_logic;
    out_MReqInfo          : out std_logic_vector(7 downto 0);
    out_MReqLast          : out std_logic;
    out_MReset_n          : out std_logic 
  );
  -- Aliases for WCI interface "ctl"
  alias ctl_Terminate : std_logic is ctl_MFlag(0);
  alias ctl_Endian    : std_logic is ctl_MFlag(1);
  alias ctl_Config    : std_logic is ctl_MAddrSpace(0);
  alias ctl_Attention : std_logic is ctl_SFlag(0);
  -- Constants for bias_vhdl's property addresses
  subtype Property_t is std_logic_vector(4 downto 0);
  constant biasValue              : Property_t := b"00000"; -- 0x00
  -- Aliases for interface "in"
  subtype in_OpCode_t is std_logic_vector(7 downto 0);
  alias in_Opcode: in_OpCode_t is in_MReqInfo(7 downto 0);
  -- Opcode/operation value declarations for protocol "stream32" on interface "in"
  constant in_data_Op                : in_Opcode_t := b"00000000"; -- 0x00
  -- Aliases for interface "out"
  subtype out_OpCode_t is std_logic_vector(7 downto 0);
  alias out_Opcode: out_OpCode_t is out_MReqInfo(7 downto 0);
  -- Opcode/operation value declarations for protocol "stream32" on interface "out"
  constant out_data_Op               : out_Opcode_t := b"00000000"; -- 0x00
  signal wci_reset : boolean;
  -- these signals provide the values of writable properties
  signal biasValue_value : ULong_t;
  signal biasValue_written : Bool_t;
  signal wci_attention, wci_is_operating: Bool_t;
  signal wci_is_big_endian, wci_abort_control_op, wci_done : Bool_t;
  signal wci_control_op : wci.control_op_t;
  signal wci_state : wci.state_t;
  signal in_take : Bool_t;
  signal in_ready : Bool_t;
  signal in_reset : Bool_t; -- this port is being reset from the outside
  signal in_data  : std_logic_vector(31 downto 0);
  signal in_byte_enable: std_logic_vector(3 downto 0);
  signal in_som : Bool_t;    -- valid eom
  signal in_eom : Bool_t;    -- valid som
  signal in_valid : Bool_t;   -- valid data
  signal out_give : Bool_t;
  signal out_ready : Bool_t;
  signal out_reset : Bool_t; -- this port is being reset from the outside
  signal out_data  : std_logic_vector(31 downto 0);
  signal out_byte_enable: std_logic_vector(3 downto 0);
  signal out_som : Bool_t;    -- valid eom
  signal out_eom : Bool_t;    -- valid som
  signal out_valid : Bool_t;   -- valid data
end entity bias_vhdl;

-- Here we define and implement the WCI interface module for this worker,
-- which can be used by the worker implementer to avoid all the OCP/WCI issues
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library ocpi;
  use ocpi.all; use ocpi.types.all;
library work;
 use work.all;
entity bias_vhdl_wci is
  port(
    inputs            : in  wci.in_t;  -- signal bundle from wci interface
    done              : in  boolean := true;  -- worker uses this to delay completion
    attention         : in  boolean := false; -- worker indicates an attention condition
    outputs           : out wci.out_t; -- signal bundle to wci interface
    reset             : out boolean;          -- wci reset for worker
    control_op        : out wci.control_op_t; -- control op in progress, or no_op_e
    state             : out wci.state_t;      -- wci state: see state_t
    is_operating      : out boolean;          -- shorthand for state==operating_e
    is_big_endian     : out boolean;          -- for endian-switchable workers
    abort_control_op  : out boolean;          -- forcible abort a control-op when
                                              -- worker uses 'done' to delay it
    -- Outputs for this worker's writable properties
    biasValue_value   : out ULong_t;
    biasValue_written : out Bool_t
  );
end entity;
architecture rtl of bias_vhdl_wci is
  signal my_clk   : std_logic; -- internal usage of output
  signal my_reset : boolean; -- internal usage of output
  -- signals for property reads and writes
  signal offsets       : wci.offset_a_t(0 to 0);  -- offsets within each property
  signal indices       : wci.offset_a_t(0 to 0);  -- array index for array properties
  signal hi32          : boolean;                 -- high word of 64 bit value
  signal nbytes_1      : types.byte_offset_t;       -- # bytes minus one being read/written
  -- signals between the decoder and the writable property registers
  signal write_enables : wci.boolean_array_t(0 to 0);
  signal data          : wci.data_a_t (0 to 0);   -- data being written, right justified
  -- signals between the decoder and the readback mux
  signal read_enables  : wci.boolean_array_t(0 to 0);
  signal readback_data : wci.data_a_t(bias_vhdl_defs.properties'range);
  -- internal signals between property registers and the readback mux
  -- for those that are writable, readable, and not volatile
  signal my_biasValue_value   : ULong_t;
begin
  outputs.SFlag(0) <= '1' when attention else '0';
  outputs.SFlag(1) <= '1'; -- worker is present
  outputs.SThreadBusy(0) <= '0' when done else '1';
  my_clk <= inputs.Clk;
  my_reset <= inputs.MReset_n = '0';
  reset <= my_reset;
  x : component wci.decoder
      generic map(worker                 => bias_vhdl_defs.worker,
                  properties             => bias_vhdl_defs.properties)
      port map(   ocp_in                 => inputs,
                  done                   => done,
                  resp                   => outputs.SResp,
                  write_enables          => write_enables,
                  read_enables           => read_enables,
                  offsets                => offsets,
                  indices                => indices,
                  hi32                   => hi32,
                  nbytes_1               => nbytes_1,
                  data_outputs           => data,
                  control_op             => control_op,
                  state                  => state,
                  is_operating           => is_operating,
                  abort_control_op       => abort_control_op,
                  is_big_endian          => is_big_endian);
readback : component wci.readback
  generic map(bias_vhdl_defs.properties)
  port map(   read_enables => read_enables,
              data_inputs  => readback_data,
              data_output  => outputs.SData);
  biasValue : component ocpi.props.ULong_property
    generic map(worker       => bias_vhdl_defs.worker,
                property     => bias_vhdl_defs.properties(0))
    port map(   clk          => my_clk,
                reset        => my_reset,
                write_enable => write_enables(0),
                data         => data(0)(31 downto 0),
                value        => my_biasValue_value,
                written      => biasValue_written);
  biasValue_value <= my_biasValue_value;
  biasValue_readback : component ocpi.props.read_ULong_property
    generic map(worker       => bias_vhdl_defs.worker,
                property     => bias_vhdl_defs.properties(0))
    port map(   value        => my_biasValue_value,
                data_out     => readback_data(0));
end architecture rtl;
library IEEE; use IEEE.std_logic_1164.ALL; use IEEE.numeric_std.ALL;
library ocpi; use ocpi.types.all;
library work; use work.bias_vhdl_defs.all;
entity bias_vhdl_in_wsi is
  port (-- Exterior OCP signals
        ocp_in         : in  in_in_t;
        ocp_out        : out in_out_t;
        -- Signals connected from the worker's WCI to this interface;
        wci_clk        : in  std_logic;
        wci_reset      : in  Bool_t;
        -- Interior signals used by worker logic
        reset          : out Bool_t; -- this port is being reset from outside
        ready          : out Bool_t; -- data can be taken
        take           : in Bool_t;
        data       : out std_logic_vector(31 downto 0);
        byte_enable    : out std_logic_vector(3 downto 0);
        som, eom, valid : out Bool_t);
end entity;
architecture rtl of bias_vhdl_in_wsi is
  signal fifo_full_n, fifo_empty_n : std_logic;
  signal my_take, my_reset_n, my_enq : std_logic;
component FIFO2
  generic (width   : natural := 1; \guarded\ : natural := 1);
  port(    CLK     : in  std_logic;
           RST_N   : in  std_logic;
           D_IN    : in  std_logic_vector(width - 1 downto 0);
           ENQ     : in  std_logic;
           DEQ     : in  std_logic;
           CLR     : in  std_logic;
           FULL_N  : out std_logic;
           EMPTY_N : out std_logic;
           D_OUT   : out std_logic_vector(width - 1 downto 0));
end component FIFO2;
begin
  my_take <= '1' when take else '0';
  my_enq <= '1' when ocp_in.MCmd = ocpi.ocp.MCmd_WRITE else '0';
  my_reset_n <= '0' when wci_reset or (ocp_in.MReset_n = '0') else '1';
  ready <= true when fifo_empty_n = '1' else false;
  fifo : FIFO2
    generic map(width => 32)
    port map(   clk     => wci_clk,
                rst_n   => my_reset_n,
                d_in    => ocp_in.MData,
                enq     => my_enq,
                full_n  => fifo_full_n,
                d_out   => data,
                deq     => my_take,
                empty_n => fifo_empty_n,
                clr     => '0');
end architecture rtl;
library IEEE; use IEEE.std_logic_1164.ALL; use IEEE.numeric_std.ALL;
library ocpi; use ocpi.types.all;
library work; use work.bias_vhdl_defs.all;
entity bias_vhdl_out_wsi is
  port (-- Exterior OCP signals
        ocp_in         : in  out_in_t;
        ocp_out        : out out_out_t;
        -- Signals connected from the worker's WCI to this interface;
        wci_clk        : in  std_logic;
        wci_reset      : in  Bool_t;
        -- Interior signals used by worker logic
        reset          : out Bool_t; -- this port is being reset from outside
        ready          : out Bool_t; -- data can be given
        give           : in  Bool_t;
        data       : in  std_logic_vector(31 downto 0);
        byte_enable    : in  std_logic_vector(3 downto 0);
        som, eom, valid : in  Bool_t);
end entity;
architecture rtl of bias_vhdl_out_wsi is
  signal my_reset : Bool_t;
begin
  my_reset <= wci_reset or (ocp_in.SReset_n = '0');
  reset <= my_reset;
  reg: process(wci_clk) is begin
    if rising_edge(wci_clk) then
      if my_reset then
        ready <= false;
      else
        ready <= ocp_in.SThreadBusy(0) = '0';
      end if;
    end if;
  end process;
  ocp_out.MCmd <= ocpi.ocp.MCmd_WRITE when give else ocpi.ocp.MCmd_IDLE;
  ocp_out.MData <= data;
  ocp_out.MReqLast <= '1' when eom else '0';
  ocp_out.MBurstLength <=
    std_logic_vector(to_unsigned(1,ocp_out.MBurstLength'length)) when eom
    else std_logic_vector(to_unsigned(2, ocp_out.MBurstLength'length));
  ocp_out.MByteEn <= byte_enable;
end architecture rtl;
library IEEE; use IEEE.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.types.all; -- remove this to avoid all ocpi name collisions
architecture rtl of bias_vhdl is
  signal unused : std_logic_vector(3 downto 0);
begin
  -- This instantiates the WCI/Control module/entity generated in the *_impl.vhd file
  -- With no user logic at all, this implements writable properties.
  wci : entity bias_vhdl_wci
    port map(-- These first signals are just for use by the wci module, not the worker
             inputs.Clk        => ctl_Clk,
             inputs.MAddr(4 downto 0) => ctl_MAddr,
             inputs.MAddr(31 downto 5) => (others => '0'),
             inputs.MAddrSpace => ctl_MAddrSpace,
             inputs.MByteEn    => unused,
             inputs.MCmd       => ctl_MCmd,
             inputs.MData      => ctl_MData,
             inputs.MFlag      => ctl_MFlag,
             inputs.MReset_n   => ctl_MReset_n,
             outputs.SData => ctl_SData, outputs.SResp => ctl_SResp,
             outputs.SFlag => ctl_SFlag, outputs.SThreadBusy => ctl_SThreadBusy,
             -- These are outputs used by the worker logic
             reset         => wci_reset, -- OCP guarantees 16 clocks of reset
             control_op    => wci_control_op,
             state         => wci_state,
             is_operating  => wci_is_operating,
             is_big_endian => wci_is_big_endian,
             done          => wci_done,
             attention     => wci_attention,
             abort_control_op => wci_abort_control_op,     -- use this to know when we are running
            -- These are outputs to the worker for writable property values.
            biasValue_value     => biasValue_value,
            biasValue_written     => biasValue_written
           );
  --
  -- The WSI interface helper component instance for port "in"
  in_port : entity bias_vhdl_in_wsi
    port map(-- These signals connect this component to the external OCP interface
             ocp_in.MBurstLength => in_MBurstLength,
             ocp_in.MBurstPrecise => in_MBurstPrecise,
             ocp_in.MByteEn      => in_MByteEn,
             ocp_in.MCmd         => in_MCmd,
             ocp_in.MData        => in_MData,
             ocp_in.MReqInfo     => in_MReqInfo,
             ocp_in.MReqLast     => in_MReqLast,
             ocp_in.MReset_n     => in_MReset_n,
             ocp_out.SReset_n    => in_SReset_n,
             ocp_out.SThreadBusy => in_SThreadBusy,
             -- These signals are just connected to the WCI
             wci_clk     => ctl_Clk,
             wci_reset   => wci_reset,
             -- This signal is the only input from worker code
             take => in_take,
             -- Output signals from this component into the worker
             reset       => in_reset, -- this port is being reset from the outside
             ready       => in_ready,
             data        => in_data,
             byte_enable => in_byte_enable,
             som         => in_som,    -- valid eom
             eom         => in_eom,    -- valid som
             valid        => in_valid); -- valid data
  --
  -- The WSI interface helper component instance for port "out"
  out_port : entity bias_vhdl_out_wsi
    port map(-- These signals connect this component to the external OCP interface
             ocp_in.SReset_n    => out_SReset_n,
             ocp_in.SThreadBusy => out_SThreadBusy,
             ocp_out.MBurstLength => out_MBurstLength,
             ocp_out.MBurstPrecise => out_MBurstPrecise,
             ocp_out.MByteEn      => out_MByteEn,
             ocp_out.MCmd         => out_MCmd,
             ocp_out.MData        => out_MData,
             ocp_out.MReqInfo     => out_MReqInfo,
             ocp_out.MReqLast     => out_MReqLast,
             ocp_out.MReset_n     => out_MReset_n,
             -- These signals are just connected to the WCI
             wci_clk     => ctl_Clk,
             wci_reset   => wci_reset,
             -- This signal is the control input from worker code
             give => out_give,
             -- Output signals from this component into the worker
             reset       => out_reset, -- this port is being reset from the outside
             ready       => out_ready,
             data        => out_data,
             byte_enable => out_byte_enable,
             som         => out_som,    -- valid eom
             eom         => out_eom,    -- valid som
             valid        => out_valid); -- valid data
bias_vhdl : entity bias_vhdl_worker
  port map(
    ctl_in.clk => ctl_Clk, ctl_in.reset => wci_reset,
    ctl_in.control_op => wci_control_op,
    ctl_in.state => wci_state,
    ctl_in.is_operating => wci_is_operating,
    ctl_in.abort_control_op => wci_abort_control_op,
    ctl_in.is_big_endian => wci_is_big_endian,
    ctl_out.done => wci_done, ctl_out.attention => wci_attention,
    in_in.reset => in_reset,
    in_in.ready => in_ready,
    in_in.data => in_data,
    in_in.byte_enable => in_byte_enable,
    in_in.som => in_som,
    in_in.eom => in_eom,
    in_in.valid => in_valid,
    in_out.take => in_take,
    out_in.reset => out_reset,
    out_in.ready => out_ready,
    out_out.give => out_give, out_out.data => out_data,
    out_out.byte_enable => out_byte_enable,
    out_out.som => out_som,
    out_out.eom => out_eom,
    out_out.valid => out_valid,
    biasValue_value => biasValue_value,
    biasValue_written => biasValue_written);
end rtl;
