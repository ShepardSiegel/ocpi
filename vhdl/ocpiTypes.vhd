-- ocpiTypes.vhd
-- Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED
--
-- 2009-07-13 ssiegel creation from names in OCWip.bsv

library IEEE;
  use IEEE.std_logic_1164.all;

package ocpiTypes is

  subtype  wciCtlOpT is std_logic_vector(2 downto 0);
    constant wciCtlOp_Initialize  : wciCtlOpT  := "000";
    constant wciCtlOp_Start       : wciCtlOpT  := "001";
    constant wciCtlOp_Stop        : wciCtlOpT  := "010";
    constant wciCtlOp_Release     : wciCtlOpT  := "011";
    constant wciCtlOp_Test        : wciCtlOpT  := "100";
    constant wciCtlOp_BeforeQuery : wciCtlOpT  := "101";
    constant wciCtlOp_AfterConfig : wciCtlOpT  := "110";
    constant wciCtlOp_Rsvd7       : wciCtlOpT  := "111";

  subtype  wciCtlStT is std_logic_vector(2 downto 0);
    constant wciCtlSt_Exists      : wciCtlStT  := "000";
    constant wciCtlSt_Initialized : wciCtlStT  := "001";
    constant wciCtlSt_Operating   : wciCtlStT  := "010";
    constant wciCtlSt_Suspended   : wciCtlStT  := "011";
    constant wciCtlSt_Unusable    : wciCtlStT  := "100";
    constant wciCtlSt_Rsvd5       : wciCtlStT  := "101";
    constant wciCtlSt_Rsvd6       : wciCtlStT  := "110";
    constant wciCtlSt_Rsvd7       : wciCtlStT  := "111";

  subtype  wciRespT is std_logic_vector(31 downto 0);
    constant wciResp_OK           : wciRespT   := X"C0DE_4201";
    constant wciResp_Error        : wciRespT   := X"C0DE_4202";
    constant wciResp_Timeout      : wciRespT   := X"C0DE_4203";
    constant wciResp_Reset        : wciRespT   := X"C0DE_4204";

  subtype  ocpCmdT is std_logic_vector(2 downto 0);
    constant ocpCmd_IDLE          : ocpCmdT    := "000";
    constant ocpCmd_WR            : ocpCmdT    := "001";
    constant ocpCmd_RD            : ocpCmdT    := "010";

  subtype  ocpRespT is std_logic_vector(1 downto 0);
    constant ocpResp_NULL         : ocpRespT   := "00";
    constant ocpResp_DVA          : ocpRespT   := "01";
    constant ocpResp_FAIL         : ocpRespT   := "10";
    constant ocpResp_ERR          : ocpRespT   := "11";

  function to_std_logic(bool:boolean) return std_logic;

end package ocpiTypes;

package body ocpiTypes is

  function to_std_logic (bool:boolean) return std_logic is begin
   if (bool) then return '1'; else return '0'; end if;
  end function to_std_logic;

end package body ocpiTypes;
