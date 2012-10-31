--
-- implementation of registered bool property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity bool_property is 
  generic(worker : worker_t; property : property_t; default : bool_t := bfalse); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(0 downto 0); 
        value : out bool_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of bool_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= to_bool(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered bool property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity bool_array_property is 
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
end entity; 
architecture rtl of bool_array_property is 
  signal base : natural;begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= to_bool(data(0));
        if nbytes_1 > 0 and property.nitems > 1 then
          value(base+1) <= to_bool(data(8));
          if nbytes_1 > 1 and property.nitems > 2 then
            value(base+2) <= to_bool(data(16));
            if nbytes_1 > 2 and property.nitems > 3 then
              value(base+3) <= to_bool(data(24));
            end if;
          end if;
        end if;
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        any_written <= bfalse;
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_bool_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in bool_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_bool_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned(from_bool(value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--v
-- readback 1 bit property array
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_bool_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in bool_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_bool_array_property is 
  signal byte_offset : byte_offset_t; 
begin
  byte_offset <= resize(property.offset + index, byte_offset_t'length);
  data_out <= from_bool_array(value,index,nbytes_1,byte_offset);
end rtl;
--
-- implementation of registered char property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity char_property is 
  generic(worker : worker_t; property : property_t; default : char_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(char_t'range); 
        value : out char_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of char_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= char_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered char property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity char_array_property is 
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
end entity; 
architecture rtl of char_array_property is
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= char_t(data(7 downto 0));
        if nbytes_1 > 0 and property.nitems > 1 then
          value(base+1) <= char_t(data(15 downto 8));
          if nbytes_1 > 1 and property.nitems > 2 then
            value(base+2) <= char_t(data(23 downto 16));
            if nbytes_1 > 2 and property.nitems > 3 then
              value(base+3) <= char_t(data(31 downto 24));
            end if;
          end if;
        end if;
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_char_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in char_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_char_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 8 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_char_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in char_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_char_array_property is
  signal i : natural;
  signal word : word_t;
begin
  i <= to_integer(index);
  word <=
    x"000000" & std_logic_vector(value(i)) when nbytes_1 = 0 else
    x"0000" & std_logic_vector(value(i+1)) & std_logic_vector(value(i)) when nbytes_1 = 1 else
    x"00" & std_logic_vector(value(i+2)) &
    std_logic_vector(value(i+1)) & std_logic_vector(value(i)) when nbytes_1 = 2 else
    std_logic_vector(value(i+3)) & std_logic_vector(value(i+2)) &
    std_logic_vector(value(i+1)) & std_logic_vector(value(i));
  data_out <= word_t(shift_left(unsigned(word),
                                ((property.offset+to_integer(index)) rem 4) *8));
end rtl;
--
-- implementation of registered double property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity double_property is 
  generic(worker : worker_t; property : property_t; default : double_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out double_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end entity; 
architecture rtl of double_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(63 downto 32) <= (data);
          written <= btrue;
        else
          value(31 downto 0) <= (data);
        end if; 
      else
        written <= bfalse;
      end if;
    end if; 
  end process; end rtl; 
--
-- implementation of registered double property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity double_array_property is 
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
end entity; 
architecture rtl of double_array_property is
  signal base : natural;begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(base)(63 downto 32) <= (data);
          -- for little endian machines that do a store64
          if base = 0 then written <= btrue; end if;
        else
          value(base)(31 downto 0) <= (data);
        end if;
        any_written <= btrue;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar >32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_double_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in double_t;
        hi32 : in bool_t;
        data_out : out std_logic_vector(31 downto 0)
       );
end entity;
architecture rtl of read_double_property is begin
  data_out <= std_logic_vector(value(63 downto 32)) when its(hi32)
              else std_logic_vector(value(31 downto 0));
end rtl; 
--
-- readback scalar 64 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_double_array_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in double_array_t(0 to property.nitems-1);
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        hi32 : in bool_t);
end entity;
architecture rtl of read_double_array_property is
  signal i : natural;
begin
  i <= to_integer(index);
  data_out <= std_logic_vector(value(i)(63 downto 32)) when its(hi32) else
              std_logic_vector(value(i)(31 downto 0));
end rtl;
--
-- implementation of registered float property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity float_property is 
  generic(worker : worker_t; property : property_t; default : float_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(float_t'range); 
        value : out float_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of float_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= float_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered float property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity float_array_property is 
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
end entity; 
architecture rtl of float_array_property is
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= float_t(data);
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_float_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in float_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_float_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 16 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_float_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in float_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_float_array_property is
begin
  data_out <= std_logic_vector(value(to_integer(index)));
end rtl;
--
-- implementation of registered short property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity short_property is 
  generic(worker : worker_t; property : property_t; default : short_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(short_t'range); 
        value : out short_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of short_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= short_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered short property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity short_array_property is 
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
end entity; 
architecture rtl of short_array_property is 
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= short_t(data(15 downto 0));
        if nbytes_1 > 1 and property.nitems > 1 then
          value(base+1) <= short_t(data(31 downto 16));
        end if;
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_short_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in short_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_short_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 16 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_short_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in short_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_short_array_property is
  signal i : natural;
begin
  i <= to_integer(index);
  data_out <=
    std_logic_vector(value(i)) & x"0000" when (to_integer(index) + property.offset/2) rem 2 = 1 else
    x"0000" & std_logic_vector(value(i)) when nbytes_1 = 1 else
    std_logic_vector(value(i+1)) & std_logic_vector(value(i));
end rtl;
--
-- implementation of registered long property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity long_property is 
  generic(worker : worker_t; property : property_t; default : long_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(long_t'range); 
        value : out long_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of long_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= long_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered long property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity long_array_property is 
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
end entity; 
architecture rtl of long_array_property is
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= long_t(data);
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_long_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in long_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_long_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 16 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_long_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in long_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_long_array_property is
begin
  data_out <= std_logic_vector(value(to_integer(index)));
end rtl;
--
-- implementation of registered uchar property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity uchar_property is 
  generic(worker : worker_t; property : property_t; default : uchar_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(uchar_t'range); 
        value : out uchar_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of uchar_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= uchar_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered uchar property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity uchar_array_property is 
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
end entity; 
architecture rtl of uchar_array_property is
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= uchar_t(data(7 downto 0));
        if nbytes_1 > 0 and property.nitems > 1 then
          value(base+1) <= uchar_t(data(15 downto 8));
          if nbytes_1 > 1 and property.nitems > 2 then
            value(base+2) <= uchar_t(data(23 downto 16));
            if nbytes_1 > 2 and property.nitems > 3 then
              value(base+3) <= uchar_t(data(31 downto 24));
            end if;
          end if;
        end if;
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_uchar_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in uchar_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_uchar_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 8 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_uchar_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in uchar_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_uchar_array_property is
  signal i : natural;
  signal word : word_t;
begin
  i <= to_integer(index);
  word <=
    x"000000" & std_logic_vector(value(i)) when nbytes_1 = 0 else
    x"0000" & std_logic_vector(value(i+1)) & std_logic_vector(value(i)) when nbytes_1 = 1 else
    x"00" & std_logic_vector(value(i+2)) &
    std_logic_vector(value(i+1)) & std_logic_vector(value(i)) when nbytes_1 = 2 else
    std_logic_vector(value(i+3)) & std_logic_vector(value(i+2)) &
    std_logic_vector(value(i+1)) & std_logic_vector(value(i));
  data_out <= word_t(shift_left(unsigned(word),
                                ((property.offset+to_integer(index)) rem 4) *8));
end rtl;
--
-- implementation of registered ulong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ulong_property is 
  generic(worker : worker_t; property : property_t; default : ulong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(ulong_t'range); 
        value : out ulong_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of ulong_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= ulong_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered ulong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ulong_array_property is 
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
end entity; 
architecture rtl of ulong_array_property is
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= ulong_t(data);
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ulong_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in ulong_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_ulong_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 16 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ulong_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in ulong_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_ulong_array_property is
begin
  data_out <= std_logic_vector(value(to_integer(index)));
end rtl;
--
-- implementation of registered ushort property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ushort_property is 
  generic(worker : worker_t; property : property_t; default : ushort_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(ushort_t'range); 
        value : out ushort_t; 
        written : out bool_t 
       );
end entity; 
architecture rtl of ushort_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        value <= ushort_t(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered ushort property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ushort_array_property is 
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
end entity; 
architecture rtl of ushort_array_property is 
  signal base : natural;
begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        value(base) <= ushort_t(data(15 downto 0));
        if nbytes_1 > 1 and property.nitems > 1 then
          value(base+1) <= ushort_t(data(31 downto 16));
        end if;
        any_written <= btrue;
        if base = 0 then written <= btrue; end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar <=32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ushort_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in ushort_t;
        data_out : out std_logic_vector(31 downto 0));
end entity; 
architecture rtl of read_ushort_property is begin
  data_out <= std_logic_vector(resize(shift_left(unsigned((value)),
                                                 (property.offset rem 4)*8),
                                      32));
end rtl; 
--
-- readback scalar 16 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ushort_array_property is 
  generic (worker : worker_t; property : property_t); 
  port (value : in ushort_array_t(0 to property.nitems-1); 
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        nbytes_1 : in byte_offset_t);
end entity;
architecture rtl of read_ushort_array_property is
  signal i : natural;
begin
  i <= to_integer(index);
  data_out <=
    std_logic_vector(value(i)) & x"0000" when (to_integer(index) + property.offset/2) rem 2 = 1 else
    x"0000" & std_logic_vector(value(i)) when nbytes_1 = 1 else
    std_logic_vector(value(i+1)) & std_logic_vector(value(i));
end rtl;
--
-- implementation of registered longlong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity longlong_property is 
  generic(worker : worker_t; property : property_t; default : longlong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out longlong_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end entity; 
architecture rtl of longlong_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(63 downto 32) <= signed(data);
          written <= btrue;
        else
          value(31 downto 0) <= signed(data);
        end if; 
      else
        written <= bfalse;
      end if;
    end if; 
  end process; end rtl; 
--
-- implementation of registered longlong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity longlong_array_property is 
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
end entity; 
architecture rtl of longlong_array_property is
  signal base : natural;begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(base)(63 downto 32) <= signed(data);
          -- for little endian machines that do a store64
          if base = 0 then written <= btrue; end if;
        else
          value(base)(31 downto 0) <= signed(data);
        end if;
        any_written <= btrue;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar >32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_longlong_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in longlong_t;
        hi32 : in bool_t;
        data_out : out std_logic_vector(31 downto 0)
       );
end entity;
architecture rtl of read_longlong_property is begin
  data_out <= std_logic_vector(value(63 downto 32)) when its(hi32)
              else std_logic_vector(value(31 downto 0));
end rtl; 
--
-- readback scalar 64 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_longlong_array_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in longlong_array_t(0 to property.nitems-1);
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        hi32 : in bool_t);
end entity;
architecture rtl of read_longlong_array_property is
  signal i : natural;
begin
  i <= to_integer(index);
  data_out <= std_logic_vector(value(i)(63 downto 32)) when its(hi32) else
              std_logic_vector(value(i)(31 downto 0));
end rtl;
--
-- implementation of registered ulonglong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ulonglong_property is 
  generic(worker : worker_t; property : property_t; default : ulonglong_t := (others => '0')); 
  port (clk : in std_logic; 
        reset : in bool_t; 
        write_enable : in bool_t; 
        data : in std_logic_vector(31 downto 0); 
        value : out ulonglong_t; 
        written : out bool_t; 
        hi32 : in bool_t); 
end entity; 
architecture rtl of ulonglong_property is begin
  reg: process(Clk) is
  begin 
    if rising_edge(clk) then
      if its(reset) then
        value <= default;
        written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(63 downto 32) <= unsigned(data);
          written <= btrue;
        else
          value(31 downto 0) <= unsigned(data);
        end if; 
      else
        written <= bfalse;
      end if;
    end if; 
  end process; end rtl; 
--
-- implementation of registered ulonglong property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity ulonglong_array_property is 
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
end entity; 
architecture rtl of ulonglong_array_property is
  signal base : natural;begin
  base <= to_integer(index);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => default);
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        if its(hi32) then
          value(base)(63 downto 32) <= unsigned(data);
          -- for little endian machines that do a store64
          if base = 0 then written <= btrue; end if;
        else
          value(base)(31 downto 0) <= unsigned(data);
        end if;
        any_written <= btrue;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- readback scalar >32 property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ulonglong_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in ulonglong_t;
        hi32 : in bool_t;
        data_out : out std_logic_vector(31 downto 0)
       );
end entity;
architecture rtl of read_ulonglong_property is begin
  data_out <= std_logic_vector(value(63 downto 32)) when its(hi32)
              else std_logic_vector(value(31 downto 0));
end rtl; 
--
-- readback scalar 64 bit property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_ulonglong_array_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in ulonglong_array_t(0 to property.nitems-1);
        data_out : out std_logic_vector(31 downto 0);
        index : in unsigned(worker.decode_width-1 downto 0);
        hi32 : in bool_t);
end entity;
architecture rtl of read_ulonglong_array_property is
  signal i : natural;
begin
  i <= to_integer(index);
  data_out <= std_logic_vector(value(i)(63 downto 32)) when its(hi32) else
              std_logic_vector(value(i)(31 downto 0));
end rtl;
--
-- implementation of registered string property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity string_property is 
  generic(worker : worker_t; property : property_t; default : string_t := ("00000000","00000000")); 
  port (clk : in std_logic;
        reset : in bool_t;
        write_enable : in bool_t;
        data : in std_logic_vector(31 downto 0);
        value : out string_t(0 to property.string_length);
        written : out bool_t;
        offset : in unsigned(worker.decode_width-1 downto 0));
end entity; 
architecture rtl of string_property is 
  signal base : natural;begin
  base <= to_integer(offset);
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        value <= (others => to_signed(0,char_t'length));
        written <= bfalse;
      elsif its(write_enable) then
        value (base to base + 3) <= to_string(data);
        written <= btrue;
      else
        written <= bfalse;
      end if;
    end if; 
  end process; 
end rtl; 
--
-- implementation of registered string property value, with write pulse 
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity string_array_property is 
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
end entity; 
--
-- readback string property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_string_property is 
  generic (worker : worker_t; property : property_t);
  port (value : in string_t;
        data_out : out std_logic_vector(31 downto 0);
        offset : in unsigned(worker.decode_width-1 downto 0));
end entity;
architecture rtl of read_string_property is begin
  data_out <= from_string(value, offset);
end rtl; 
--
-- readback scalar string property
--
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.all; use ocpi.types.all; use ocpi.wci.all; use ocpi.ocp.all;
entity read_string_array_property is 
  generic (worker : worker_t; property : property_t);
  port    (value    : in  string_array_t(0 to property.nitems-1,
                                         0 to (property.string_length+4)/4*4-1);
           data_out : out std_logic_vector(31 downto 0);
           offset   : in  unsigned(worker.decode_width-1 downto 0));
end entity;
architecture rtl of string_array_property is
  constant nwords : natural := (property.string_length+4)/4;
  subtype string_words_t is data_a_t(0 to nwords * property.nitems-1);
  signal string_words : string_words_t;
begin
  gen: for i in 0 to property.nitems-1 generate -- properties'left to 0 generate
    gen1: for j in 0 to nwords-1 generate
      gen2: for k in 0 to 3 generate
       value(i,j*4+k) <= signed(string_words(i*nwords + j)(k*8+7 downto k*8));
      end generate gen2;
    end generate gen1;
 end generate gen;
  reg: process(Clk) is
  begin
    if rising_edge(clk) then
      if its(reset) then
        string_words(0) <= (others => '0');
        written <= bfalse;
        any_written <= bfalse;
      elsif its(write_enable) then
        string_words(to_integer(offset) / 4) <= data;
        written <= btrue;
 if to_integer(offset) = 0 then
   any_written <= btrue;
 end if;
      else
        written <= bfalse;
        any_written <= bfalse;
      end if;
    end if;
  end process;
end rtl;
architecture rtl of read_string_array_property is
  constant nwords : natural := (property.string_length+4)/4;
  subtype string_words_t is data_a_t(0 to nwords * property.nitems-1);
  signal string_words : string_words_t;
begin
  gen: for i in 0 to property.nitems-1 generate -- properties'left to 0 generate
    gen1: for j in 0 to nwords-1 generate
      gen2: for k in 0 to 3 generate
       string_words(i*nwords + j)(k*8+7 downto k*8) <= std_logic_vector(value(i,j*4+k));
      end generate gen2;
    end generate gen1;
 end generate gen;
 data_out <= string_words(to_integer(offset)/4);
end rtl;
