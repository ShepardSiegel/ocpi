-- Various re-usable functions relating to property data type support.
--library ocpi;
--use ocpi.wci.all;
library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
package body types is
-- THESE ARE DEFINITIONS WHEN Bool_t is std_logic
function its(b : bool_t) return boolean is begin return b = '1'; end;
function To_bool(b : std_logic) return Bool_t is begin return b; end to_bool;
function To_bool(b : std_logic_vector) return Bool_t is begin return b(0); end to_bool;
function To_bool(b : boolean) return Bool_t is begin if b then return '1'; else return '0'; end if; end;
function from_bool(b : bool_t) return std_logic_vector is begin
if b = '1' then return std_logic_vector'(b"1"); else return std_logic_vector'(b"0"); end if;
end from_bool;                                                            
function "and"  ( l : bool_t; r : bool_t ) return boolean is begin return its(l) and its(r); end;
function "nand" ( l : bool_t; r : bool_t ) return boolean is begin return its(l) nand its(r); end;
function "or"   ( l : bool_t; r : bool_t ) return boolean is begin return its(l) or its(r); end;
function "nor"  ( l : bool_t; r : bool_t ) return boolean is begin return its(l) nor its(r); end;
function "xor"  ( l : bool_t; r : bool_t ) return boolean is begin return its(l) xor its(r); end;
function "xnor" ( l : bool_t; r : bool_t ) return boolean is begin return its(l) xnor its(r); end;

--function "and"  ( l : bool_t; r : boolean ) return boolean is begin return its(l) and r; end;
function "nand" ( l : bool_t; r : boolean ) return boolean is begin return its(l) nand r; end;
function "or"   ( l : bool_t; r : boolean ) return boolean is begin return its(l) or r; end;
function "nor"  ( l : bool_t; r : boolean ) return boolean is begin return its(l) nor r; end;
function "xor"  ( l : bool_t; r : boolean ) return boolean is begin return its(l) xor r; end;
function "xnor" ( l : bool_t; r : boolean ) return boolean is begin return its(l) xnor r; end;

function "and"  ( l : boolean; r : bool_t ) return boolean is begin return l and its(r); end;
function "nand" ( l : boolean; r : bool_t ) return boolean is begin return l nand its(r); end;
function "or"   ( l : boolean; r : bool_t ) return boolean is begin return l or its(r); end;
function "nor"  ( l : boolean; r : bool_t ) return boolean is begin return l nor its(r); end;
function "xor"  ( l : boolean; r : bool_t ) return boolean is begin return l xor its(r); end;
function "xnor" ( l : boolean; r : bool_t ) return boolean is begin return l xnor its(r); end;

function "or"   ( l : bool_t; r : boolean ) return bool_t is begin return to_bool(to_boolean(l) or r); end;

function "not"  ( l : bool_t             ) return boolean is begin return not its(l); end;

-- THESE ARE DEFINITIONS WHEN Bool_t is BOOLEAN
--function its(b : bool_t) return boolean is begin return b; end;
--function To_bool(b : std_logic) return Bool_t is begin return b = '1'; end to_bool;
--function To_bool(b : std_logic_vector) return Bool_t is begin return b(0) = '1'; end to_bool;
--function To_bool(b : boolean) return Bool_t is begin return b; end;
--function from_bool(b : bool_t) return std_logic_vector is begin
--  if b then return std_logic_vector'(b"1"); else return std_logic_vector'(b"0"); end if;
--end from_bool;                                                            
--function from_bool(b : bool_t) return std_logic is begin
--if b then return '1'; else return '0'; end if;
--end from_bool;                                                            

-- THESE ARE Bool_t related definitions independent of whether bool_t is boolean or std_logic
function btrue return bool_t is begin return to_bool(true); end;
function bfalse return bool_t is begin return to_bool(false); end;
function To_boolean(b : bool_t) return boolean is begin return its(b); end to_boolean;
function from_bool_array(ba : bool_array_t; index, nbytes_1, byte_offset : unsigned) return word_t is
  variable result: word_t := (others => '0');
  variable i : natural := to_integer(index);
  variable o : natural := to_integer(byte_offset) * 8;
begin
  result(o + 0) := from_bool(ba(i))(0);
  if nbytes_1 > 0 then
    result(o + 8) := from_bool(ba(i+1))(0);
    if nbytes_1 > 1 then
      result(o + 16) := from_bool(ba(i+2))(0);
      if nbytes_1 = 3 then
        result(o + 24) := from_bool(ba(i+3))(0);
      end if; 
    end if;
  end if;
  return result;
end from_bool_array;
function To_character (c : Char_t) return character is
begin
  return character'val(to_integer(c));
end to_character;
function To_char (c: Character) return char_t is
begin
  return to_signed(character'pos(c),char_t'length);
end to_char;
function To_char (c: integer) return char_t is
begin
 return to_signed(c,char_t'length);
end to_char;
function from_char (c: char_t) return std_logic_vector is begin
  return std_logic_vector(c);
end from_char;                                                            

function To_short (c: integer) return short_t is
begin
 return to_signed(c,short_t'length);
end to_short;
function To_long (c: integer) return long_t is
begin
 return to_signed(c,long_t'length);
end to_long;

function To_uchar (c: natural) return uchar_t is
begin
 return to_unsigned(c,uchar_t'length);
end to_uchar;
function To_ushort (c: natural) return ushort_t is
begin
 return to_unsigned(c,ushort_t'length);
end to_ushort;
function To_ulong (c: natural) return ulong_t is
begin
 return to_unsigned(c,ulong_t'length);
end to_ulong;

--function To_char (c: std_logic_vector) return char_t is
--begin
--return char_t(c(7 downto 0));
--end to_char;

function to_string(inword : word_t) return wordstring_t is
begin
  return
   (signed(inword( 7 downto  0)),
    signed(inword(15 downto  8)),
	  signed(inword(23 downto 16)),
	  signed(inword(31 downto 24)));
end to_string;

function from_string(s : string_t; offset : unsigned) return word_t is
  variable off : natural;
begin 
  off := to_integer(offset);
  return
    std_logic_vector(s(off))   &
    std_logic_vector(s(off+1)) &
    std_logic_vector(s(off+2)) &
    std_logic_vector(s(off+3));
end from_string;

end types;
