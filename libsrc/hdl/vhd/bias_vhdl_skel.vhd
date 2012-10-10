-- THIS FILE WAS ORIGINALLY GENERATED ON Thu Oct  4 16:01:56 2012 EDT
-- BASED ON THE FILE: bias_vhdl.xml
-- YOU *ARE* EXPECTED TO EDIT IT
-- This file initially contains the architecture skeleton for worker: bias_vhdl

-- ssiegel 2012-10-06 modfications

library IEEE; use IEEE.std_logic_1164.all; use ieee.numeric_std.all;
library ocpi; use ocpi.types.all; -- remove this to avoid all ocpi name collisions

architecture rtl of bias_vhdl_worker is
begin

  reg : process(ctl_in.clk) is
  begin

  if rising_edge(ctl_in.clk) then
  -- Non-reset condtionalized synchronous assignments...
    in_out.take         <= in_in.ready and out_in.ready;
    out_out.give        <= in_in.ready and out_in.ready;
    out_out.data        <= in_in.data;
    out_out.byte_enable <= in_in.byte_enable;
    out_out.som         <= in_in.som;
    out_out.eom         <= in_in.eom;
    out_out.valid       <= in_in.valid;
  end if;

  end process reg;

end rtl;
