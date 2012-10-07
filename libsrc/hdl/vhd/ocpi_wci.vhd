-- This package defines constants relating to the WCI interface
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.types.all; use ocpi.ocp;
package wci is

TYPE control_op_t IS (INITIALIZE_e,
                      START_e,     
                      STOP_e,
                      RELEASE_e,
                      BEFORE_QUERY_e,
                      AFTER_CONFIG_e,
                      TEST_e,
                      NO_OP_e);

subtype control_op_mask_t is std_logic_vector(control_op_t'pos(no_op_e) downto 0);
type worker_t is record
  decode_width : natural;
  allowed_ops : control_op_mask_t;
end record worker_t;
type property_t is record
  data_width,                         -- data width of datum in bits, but 32 for strings
  offset,                             -- offset in property space in bytes
  bytes_1,                            -- total bytes in this property minus 1
  string_length,                      -- bytes (excluding null) for string values
  nitems                              -- nitems array
    : natural;                -- with of a single item
  writable, readable, volatile, parameter : boolean;
end record property_t;

  -- Address Space Selection
  CONSTANT CONFIG  : std_logic := '1';
  CONSTANT CONTROL : std_logic := '0';

  -- Worker State
  -- These are not normative to the WCI interface, but are useful for bookkeepping
  -- Note we track the state where we have accepted a control operation but
  -- have not yet responded to it.
  TYPE State_t IS (EXISTS_e,            -- 0
                   INITIALIZED_e,       -- 1
                   OPERATING_e,         -- 2
                   SUSPENDED_e,         -- 3
                   UNUSABLE_e);         -- 4


  type control_op_masks_t is array (natural range <>) of control_op_mask_t;

  -- constant masks for what control op is allowed in each state
  constant next_ops : control_op_masks_t :=
    ("00000010",       -- EXISTS_e
     "10010100",       -- INITIALIZED_e
     "01111000",       -- OPERATING_e
     "01110100",       -- SUSPENDED_e
     "00000000"        -- UNUSABLE_e: nothing to do but reset
     );
  
  --SUBTYPE  State_t IS std_logic_vector(2 DOWNTO 0);
  --CONSTANT EXISTS      : State_t := "000";
  --CONSTANT INITIALIZED : State_t := "001";
  --CONSTANT OPERATING   : State_t := "010";
  --CONSTANT SUSPENDED   : State_t := "011";
  --CONSTANT UNUSABLE    : State_t := "100";

  ---- Worker Control Operations
  --SUBTYPE  ControlOp_t IS std_logic_vector(2 DOWNTO 0);
  --CONSTANT INITIALIZE   : ControlOp_t := "000";
  --CONSTANT START        : ControlOp_t := "001";
  --CONSTANT STOP         : ControlOp_t := "010";
  --CONSTANT RELEASE      : ControlOp_t := "011";
  --CONSTANT TEST         : ControlOp_t := "100";
  --CONSTANT BEFORE_QUERY : ControlOp_t := "101";
  --CONSTANT AFTER_CONFIG : ControlOp_t := "110";
  --CONSTANT RESERVED     : ControlOp_t := "111";

  type in_t is record
    Clk                 : std_logic;
    MAddr               : std_logic_vector(31 downto 0);
    MAddrSpace          : std_logic_vector(0 downto 0);
    MByteEn             : std_logic_vector(3 downto 0);
    MCmd                : ocp.MCmd_t;
    MData               : std_logic_vector(31 downto 0);
    MFlag               : std_logic_vector(1 downto 0);
    MReset_n            : std_logic;
  end record in_t;

  type out_t is record
    SData               : std_logic_vector(31 downto 0);
    SFlag               : std_logic_vector(1 downto 0);
    SResp               : ocp.SResp_t;
    SThreadBusy         : std_logic_vector(0 downto 0);
  end record out_t;

  -- This is the type of access to the property, or none
  type Access_t IS (None_e, Error_e, Read_e, Write_e, Control_e);

  -- Return the currently decoded access
  function decode_access(input : in_t) return Access_t;

  -- Return the byte offset from the byte enables
  --subtype byte_offset_t is unsigned(1 downto 0);
--  function be2offset(input: in_t) return byte_offset_t;

  -- pull the value from the data bus, shifted and sized
  function get_value(input : in_t; boffset : unsigned; width : natural) return std_logic_vector;
  
  function to_control_op(bits : std_logic_vector(2 downto 0)) return control_op_t;

  function resize(bits : std_logic_vector; n : natural) return std_logic_vector;


  subtype hword_t is std_logic_vector(15 downto 0);
  subtype byte_t is std_logic_vector(7 downto 0);
  type properties_t is array (natural range <>) of property_t;
  type data_a_t is array (natural range <>) of word_t;
  type offset_a_t is array (natural range <>) of unsigned(31 downto 0);
  type boolean_array_t is array (natural range <>) of boolean;
  function data_out_top (property : property_t) return natural;

  -- the wci convenience IP that makes it simple to implement a WCI interface
  component decoder
    generic(worker : worker_t; properties : properties_t);
    port(
      ocp_in                 : in in_t;       
      done                   : in boolean := true;
      resp                   : out ocp.SResp_t;
      write_enables          : out boolean_array_t(properties'range);
      read_enables           : out boolean_array_t(properties'range);
      offsets                : out offset_a_t(properties'range);
      indices                : out offset_a_t(properties'range);
      hi32                   : out boolean;
      nbytes_1               : out byte_offset_t;
      data_outputs           : out data_a_t(properties'range);
      control_op             : out control_op_t;
      state                  : out state_t;
      is_operating           : out boolean;  -- just a convenience for state = operating_e
      abort_control_op       : out boolean;
      is_big_endian          : out boolean   -- for runtime dynamic endian
    );
  end Component;
         
  component readback
    generic(properties : properties_t);
    port(
      read_enables : in boolean_array_t(properties'range);
      data_inputs  : in data_a_t(properties'range);
      data_output  : out std_logic_vector(31 downto 0)
      );
  end component readback;
end package wci;

