-- THIS FILE WAS ORIGINALLY GENERATED ON Thu Oct  4 16:01:56 2012 EDT
-- BASED ON THE FILE: bias_vhdl.xml
-- YOU *ARE* EXPECTED TO EDIT IT
-- This file initially contains the architecture skeleton for worker: bias_vhdl

-- ssiegel 2012-10-06 modfications

library IEEE; use IEEE.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.types.all; -- remove this to avoid all ocpi name collisions
architecture rtl of bias_vhdl_worker is
begin

  variable moveData : std_logic;  -- combi decode of non-reset when source and sink are ready to move data

  reg : process(ctl_in.clk) is
  begin

  if rising_edge(ctl_in.clk) then

    if ctl_in.reset then
      in_out.SReset_n     = '0';
      in_out.SThreadBusy  = '1';
      moveData := 0;
    else
      in_out.SReset_n     = '1';
      in_out.SThreadBusy  = '0';
      moveData := in_out.ready && out_out.ready;
    end if;

  -- Non-reset condtionalized synchronous assignments...
    in_out.take         <= moveData;
    out_out.give        <= moveData;
    out_out.data        <= in_in.data;
    out_out.byte_enable <= in_in.byte_enable;
    out_out.som         <= in_in.som;
    out_out.eom         <= in_in.eom;
    out_out.valid       <= in_in.valid;
    
  end if

  end if;
  end process reg;

  
end rtl;
