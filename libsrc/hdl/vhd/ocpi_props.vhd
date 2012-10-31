library ieee; use IEEE.std_logic_1164.all; use ieee.numeric_std.all;
--library std;
--use std.all;
library ocpi; use ocpi.types.all; use ocpi.wci.all;
package props is
--
-- Property storage entities to attach to a wci.decoder
--
-- Declarations for various property implementationss
--
-- registered bool property value, with write pulse 
--
component bool_property 
  generic(worker : worker_t; property : property_t; default : bool_t := bfalse); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(0 downto 0); 
        value : out bool_t; 
        written : out bool_t); 
end component; 
--
-- registered bool property array value, with write pulse
--
component bool_array_property 
  generic(worker : worker_t; property : property_t; default : bool_t := bfalse); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out bool_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_bool_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in bool_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_bool_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in bool_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered char property value, with write pulse 
--
component char_property 
  generic(worker : worker_t; property : property_t; default : char_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(char_t'range); 
        value : out char_t; 
        written : out bool_t); 
end component; 
--
-- registered char property array value, with write pulse
--
component char_array_property 
  generic(worker : worker_t; property : property_t; default : char_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out char_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_char_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in char_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_char_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in char_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered double property value, with write pulse 
--
component double_property 
  generic(worker : worker_t; property : property_t; default : double_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out double_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end component; 
--
-- registered double property array value, with write pulse
--
component double_array_property 
  generic(worker : worker_t; property : property_t; default : double_t := (others => '0'));
  port (clk : in std_logic;
        reset : in bool_t;
        write_enable : in bool_t;
        data : in std_logic_vector(31 downto 0);
        value : out double_array_t(0 to property.nitems-1);
        written : out bool_t;
        index : in unsigned(worker.decode_width-1 downto 0);
        any_written : out bool_t;
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property 
--
component read_double_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in double_t; 
        data_out : out std_logic_vector(31 downto 0); 
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property array 
--
component read_double_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in double_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        hi32 : in bool_t);
end component;
--
-- registered float property value, with write pulse 
--
component float_property 
  generic(worker : worker_t; property : property_t; default : float_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(float_t'range); 
        value : out float_t; 
        written : out bool_t); 
end component; 
--
-- registered float property array value, with write pulse
--
component float_array_property 
  generic(worker : worker_t; property : property_t; default : float_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out float_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_float_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in float_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_float_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in float_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered short property value, with write pulse 
--
component short_property 
  generic(worker : worker_t; property : property_t; default : short_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(short_t'range); 
        value : out short_t; 
        written : out bool_t); 
end component; 
--
-- registered short property array value, with write pulse
--
component short_array_property 
  generic(worker : worker_t; property : property_t; default : short_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out short_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_short_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in short_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_short_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in short_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered long property value, with write pulse 
--
component long_property 
  generic(worker : worker_t; property : property_t; default : long_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(long_t'range); 
        value : out long_t; 
        written : out bool_t); 
end component; 
--
-- registered long property array value, with write pulse
--
component long_array_property 
  generic(worker : worker_t; property : property_t; default : long_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out long_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_long_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in long_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_long_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in long_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered uchar property value, with write pulse 
--
component uchar_property 
  generic(worker : worker_t; property : property_t; default : uchar_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(uchar_t'range); 
        value : out uchar_t; 
        written : out bool_t); 
end component; 
--
-- registered uchar property array value, with write pulse
--
component uchar_array_property 
  generic(worker : worker_t; property : property_t; default : uchar_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out uchar_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_uchar_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in uchar_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_uchar_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in uchar_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered ulong property value, with write pulse 
--
component ulong_property 
  generic(worker : worker_t; property : property_t; default : ulong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(ulong_t'range); 
        value : out ulong_t; 
        written : out bool_t); 
end component; 
--
-- registered ulong property array value, with write pulse
--
component ulong_array_property 
  generic(worker : worker_t; property : property_t; default : ulong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out ulong_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_ulong_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ulong_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_ulong_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ulong_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered ushort property value, with write pulse 
--
component ushort_property 
  generic(worker : worker_t; property : property_t; default : ushort_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(ushort_t'range); 
        value : out ushort_t; 
        written : out bool_t); 
end component; 
--
-- registered ushort property array value, with write pulse
--
component ushort_array_property 
  generic(worker : worker_t; property : property_t; default : ushort_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out ushort_array_t(0 to property.nitems-1); 
        written : out bool_t; 
        index : in unsigned(worker.decode_width-1 downto 0); 
        any_written : out bool_t; 
        nbytes_1 : in byte_offset_t);
end component; 
--
-- readback scalar <=32 property 
--
component read_ushort_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ushort_t; 
        data_out : out std_logic_vector(31 downto 0)); 
end component; 
--
-- readback scalar <=32 property array 
--
component read_ushort_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ushort_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        nbytes_1 : in byte_offset_t);
end component;
--
-- registered longlong property value, with write pulse 
--
component longlong_property 
  generic(worker : worker_t; property : property_t; default : longlong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out longlong_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end component; 
--
-- registered longlong property array value, with write pulse
--
component longlong_array_property 
  generic(worker : worker_t; property : property_t; default : longlong_t := (others => '0'));
  port (clk : in std_logic;
        reset : in bool_t;
        write_enable : in bool_t;
        data : in std_logic_vector(31 downto 0);
        value : out longlong_array_t(0 to property.nitems-1);
        written : out bool_t;
        index : in unsigned(worker.decode_width-1 downto 0);
        any_written : out bool_t;
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property 
--
component read_longlong_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in longlong_t; 
        data_out : out std_logic_vector(31 downto 0); 
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property array 
--
component read_longlong_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in longlong_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        hi32 : in bool_t);
end component;
--
-- registered ulonglong property value, with write pulse 
--
component ulonglong_property 
  generic(worker : worker_t; property : property_t; default : ulonglong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out ulonglong_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end component; 
--
-- registered ulonglong property array value, with write pulse
--
component ulonglong_array_property 
  generic(worker : worker_t; property : property_t; default : ulonglong_t := (others => '0'));
  port (clk : in std_logic;
        reset : in bool_t;
        write_enable : in bool_t;
        data : in std_logic_vector(31 downto 0);
        value : out ulonglong_array_t(0 to property.nitems-1);
        written : out bool_t;
        index : in unsigned(worker.decode_width-1 downto 0);
        any_written : out bool_t;
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property 
--
component read_ulonglong_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ulonglong_t; 
        data_out : out std_logic_vector(31 downto 0); 
        hi32 : in bool_t);
end component; 
--
-- readback scalar >32 property array 
--
component read_ulonglong_array_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in ulonglong_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0); 
        index : in unsigned(worker.decode_width-1 downto 0); 
        hi32 : in bool_t);
end component;
--
-- registered string property value, with write pulse 
--
component string_property 
  generic(worker : worker_t; property : property_t; default : string_t := ("00000000","00000000"));
  port (clk : in std_logic;
        reset : in bool_t;
        write_enable : in bool_t;
        data : in std_logic_vector(31 downto 0);
        value : out string_t(0 to property.string_length);
        written : out bool_t;
        offset : in unsigned(worker.decode_width-1 downto 0));
end component; 
--
-- registered string property array value, with write pulse
--
component string_array_property 
  generic(worker : worker_t; property : property_t; default : string_array_t := (("00000000","00000000"),("00000000","00000000"))); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out string_array_t(0 to property.nitems-1,
                                            0 to (property.string_length+4)/4*4-1);
        written : out bool_t;
        index : in unsigned(worker.decode_width-1 downto 0);
        any_written : out bool_t; 
        offset : in unsigned(worker.decode_width-1 downto 0));
end component; 
--
-- readback scalar <=32 property 
--
component read_string_property 
  generic (worker : worker_t; property : property_t); 
  port (value : in string_t; 
        data_out : out std_logic_vector(31 downto 0); 
        offset : in unsigned(worker.decode_width-1 downto 0)); 
end component; 
--
-- readback string property array 
--
component read_string_array_property 
  generic (worker : worker_t; property : property_t);
  port    (value    : in  string_array_t(0 to property.nitems-1,
                                         0 to (property.string_length+4)/4*4-1);
           data_out : out std_logic_vector(31 downto 0);
           offset   : in  unsigned(worker.decode_width-1 downto 0));
end component;
end package props;
