-- THIS FILE WAS GENERATED ON Thu Oct  4 16:01:55 2012 EDT
-- BASED ON THE FILE: bias_vhdl.xml
-- YOU PROBABLY SHOULD NOT EDIT IT
-- This file contains the VHDL declarations for the worker with
--  spec name "bias" and implementation name "bias_vhdl".
-- It is needed for instantiating the worker.
-- Interface signal names are defined with pattern rule: "%s_"
Library IEEE;
  use IEEE.std_logic_1164.all;
Library ocpi; use ocpi.all; use ocpi.types.all;

package bias_vhdl_defs is

component bias_vhdl is
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
end component bias_vhdl;

constant properties : ocpi.wci.properties_t;
constant worker : ocpi.wci.worker_t;

  -- These 2 records correspond to the input and output sides of the OCP bundle
  -- for the "bias_vhdl" worker's "WCI" profile interface named "ctl"

  -- Record for the WCI input (OCP master) signals for port "ctl" of worker "bias_vhdl"
  type ctl_in_t is record
    Clk                 : std_logic;
    MAddr               : std_logic_vector(4 downto 0);
    MAddrSpace          : std_logic_vector(0 downto 0);
    MCmd                : ocpi.ocp.MCmd_t;
    MData               : std_logic_vector(31 downto 0);
    MFlag               : std_logic_vector(1 downto 0);
    MReset_n            : std_logic;
  end record ctl_in_t;

  -- Record for the WCI output (OCP slave) signals for port "ctl" of worker "bias_vhdl"
  type ctl_out_t is record
    SData               : std_logic_vector(31 downto 0);
    SFlag               : std_logic_vector(1 downto 0);
    SResp               : ocpi.ocp.SResp_t;
    SThreadBusy         : std_logic_vector(0 downto 0);
  end record ctl_out_t;
  -- These two records are for the inner/worker interfaces for port "ctl"
  type worker_ctl_in_t is record
    clk           : std_logic;
    reset         : bool_t;
    control_op    : wci.control_op_t; -- control op in progress, or no_op_e
    state         : wci.state_t;      -- wci state: see state_t
    is_operating  : bool_t;           -- shorthand for state==operating_e
    abort_control_op : bool_t;
    is_big_endian : bool_t;           -- for endian-switchable workers
  end record worker_ctl_in_t;
  type worker_ctl_out_t is record
    done          : bool_t;           -- is the pending prop access/config op done?
    attention     : bool_t;           -- worker wants attention
  end record worker_ctl_out_t;

  -- These 2 records correspond to the input and output sides of the OCP bundle
  -- for the "bias_vhdl" worker's "WSI" profile interface named "in"

  -- Record for the WSI input (OCP master) signals for port "in" of worker "bias_vhdl"
  type in_in_t is record
    MBurstLength        : std_logic_vector(11 downto 0);
    MByteEn             : std_logic_vector(3 downto 0);
    MCmd                : ocpi.ocp.MCmd_t;
    MData               : std_logic_vector(31 downto 0);
    MBurstPrecise       : std_logic;
    MReqInfo            : std_logic_vector(7 downto 0);
    MReqLast            : std_logic;
    MReset_n            : std_logic;
  end record in_in_t;

  -- Record for the WSI output (OCP slave) signals for port "in" of worker "bias_vhdl"
  type in_out_t is record
    SReset_n            : std_logic;
    SThreadBusy         : std_logic_vector(0 downto 0);
  end record in_out_t;
  -- These two records are for the inner/worker interfaces for port "in"
  type worker_in_in_t is record
    reset           : bool_t; -- this port is being reset from the outside
    ready           : bool_t; -- this port is ready for data to be taken
    data            : std_logic_vector(31 downto 0);
    byte_enable     : std_logic_vector(3 downto 0);
    som, eom, valid : bool_t;
  end record worker_in_in_t;
  type worker_in_out_t is record
    take            : bool_t; -- take data now from this port
  end record worker_in_out_t;

  -- These 2 records correspond to the input and output sides of the OCP bundle
  -- for the "bias_vhdl" worker's "WSI" profile interface named "out"

  -- Record for the WSI input (OCP slave) signals for port "out" of worker "bias_vhdl"
  type out_in_t is record
    SReset_n            : std_logic;
    SThreadBusy         : std_logic_vector(0 downto 0);
  end record out_in_t;

  -- Record for the WSI output (OCP master) signals for port "out" of worker "bias_vhdl"
  type out_out_t is record
    MBurstLength        : std_logic_vector(11 downto 0);
    MByteEn             : std_logic_vector(3 downto 0);
    MCmd                : ocpi.ocp.MCmd_t;
    MData               : std_logic_vector(31 downto 0);
    MBurstPrecise       : std_logic;
    MReqInfo            : std_logic_vector(7 downto 0);
    MReqLast            : std_logic;
    MReset_n            : std_logic;
  end record out_out_t;
  -- These two records are for the inner/worker interfaces for port "out"
  type worker_out_in_t is record
    reset           : bool_t; -- this port is being reset from the outside
    ready           : bool_t; -- this port is ready for data to be given
  end record worker_out_in_t;
  type worker_out_out_t is record
    give            : bool_t; -- give data now to this port
    data            : std_logic_vector(31 downto 0);
    byte_enable     : std_logic_vector(3 downto 0);
    som, eom, valid : bool_t;
  end record worker_out_out_t;
end package bias_vhdl_defs;
