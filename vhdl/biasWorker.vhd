-- biasWorker.vhd
-- Copyright (c) 2009 Atomic Rules LLC - ALL RIGHTS RESERVED
--
-- 2009-07-11 ssiegel creation
-- 2009-07-12 ssiegel run thorough XST
-- 2009-07-13 ssiegel adapt to use ocpiTypes
-- 2009-07-15 ssiegel controlOp decode
-- 2010-03-01 ssiegel Added Peer-Peer WSI Resets

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library work;
  use work.ocpiTypes.all;

entity biasWorker is  

  port (
    clk                : in   std_logic;
    rst_n              : in   std_logic;

    -- WCI Port
    -- WCI Req...
    wci_MCmd           : in   std_logic_vector( 2 downto 0);
    wci_MAddrSpace     : in   std_logic_vector( 0 downto 0);
    wci_MByteEn        : in   std_logic_vector( 3 downto 0);
    wci_MAddr          : in   std_logic_vector(19 downto 0);
    wci_MData          : in   std_logic_vector(31 downto 0);
    -- WCI Resp...
    wci_SResp          : out  std_logic_vector( 1 downto 0);
    wci_SData          : out  std_logic_vector(31 downto 0);
    -- WCI Util...
    wci_MFlag          : in   std_logic_vector( 1 downto 0);
    wci_SFlag          : out  std_logic_vector( 1 downto 0);
    wci_SThreadBusy    : out  std_logic;

    -- WSI Slave Port (WSI0)
    wsi0_MReset_n      : in   std_logic;  -- Reset in from WSI partner
    wsi0_SReset_n      : out  std_logic;  -- Reset out to  WSI partner
    -- WSI Req...
    wsi0_MCmd          : in   std_logic_vector( 2 downto 0);
    wsi0_MReqLast      : in   std_logic;
    wsi0_MBurstPrecise : in   std_logic;
    wsi0_MBurstLength  : in   std_logic_vector(11 downto 0);
    wsi0_MData         : in   std_logic_vector(31 downto 0);
    wsi0_MByteEn       : in   std_logic_vector( 3 downto 0);
    wsi0_MReqInfo      : in   std_logic_vector( 7 downto 0);
    -- WSI Util...
    wsi0_SThreadBusy   : out  std_logic;

    -- WSI Master Port (WSI1)
    wsi1_MReset_n      : out  std_logic;  -- Reset out to  WSI partner
    wsi1_SReset_n      : in   std_logic;  -- Reset in from WSI partner
    -- WSI Req...
    wsi1_MCmd          : out  std_logic_vector( 2 downto 0);
    wsi1_MReqLast      : out  std_logic;
    wsi1_MBurstPrecise : out  std_logic;
    wsi1_MBurstLength  : out  std_logic_vector(11 downto 0);
    wsi1_MData         : out  std_logic_vector(31 downto 0);
    wsi1_MByteEn       : out  std_logic_vector( 3 downto 0);
    wsi1_MReqInfo      : out  std_logic_vector( 7 downto 0);
    -- WSI Util...
    wsi1_SThreadBusy   : in   std_logic);

end biasWorker;


architecture rtl of biasWorker is

  signal biasValue     : std_logic_vector(31 downto 0);
  signal wci_ctlSt     : wciCtlStT;
  signal wci_cfg_write : std_logic;
  signal wci_cfg_read  : std_logic;
  signal wci_ctl_op    : std_logic;

begin

  --When this worker is WCI reset, propagate reset out to WSI partners...
  wsi0_SReset_n <= rst_n;
  wsi1_MReset_n <= rst_n;

  wci_cfg_write <= to_std_logic(wci_MCmd=ocpCmd_WR and wci_MAddrSpace(0)='1');
  wci_cfg_read  <= to_std_logic(wci_MCmd=ocpCmd_RD and wci_MAddrSpace(0)='1');
  wci_ctl_op    <= to_std_logic(wci_MCmd=ocpCmd_RD and wci_MAddrSpace(0)='0');

  -- Pass the SThreadBusy upstream without pipelining...
  wsi0_SThreadBusy <= wsi1_SThreadBusy or to_std_logic(wci_ctlSt/=wciCtlSt_Operating);
  
reg : process(clk) is
begin
  if rising_edge(clk) then
      
    if (wci_ctlSt  = wciCtlSt_Operating ) then  -- Implement the biasWorker function...
      wsi1_MData <= std_logic_vector(unsigned(wsi0_MData) + unsigned(biasValue));
      wsi1_MCmd  <= wsi0_MCmd;
    else                                        -- Or block the WSI pipeline cleanly...
      wsi1_MData <= (others=>'0');
      wsi1_MCmd  <= ocpCmd_IDLE;
    end if;

    -- Pass through signals of the WSI interface that we maintain, but do not use...
    wsi1_MReqLast       <= wsi0_MReqLast;
    wsi1_MBurstPrecise  <= wsi0_MBurstPrecise;
    wsi1_MBurstLength   <= wsi0_MBurstLength;
    wsi1_MByteEn        <= wsi0_MByteEn;
    wsi1_MReqInfo       <= wsi0_MReqInfo;

    -- Implement minimal WCI attach logic...
    wci_SThreadBusy     <= '0'; 
    wci_SResp           <= ocpResp_NULL;

    wci_reset_clause : if (rst_n='0') then

      wci_ctlSt       <= wciCtlSt_Exists;
      wci_SResp       <= ocpResp_NULL;
      wci_SFlag       <= "00";
      wci_SThreadBusy <= '1';
      biasValue       <= X"0000_0000";

    else

      -- WCI Configuration Property Writes...
      if wci_cfg_write='1' then
        biasValue <= wci_MData;
        wci_SResp <= ocpResp_DVA;
      end if;

      -- WCI Configuration Property Reads...
      if wci_cfg_read='1' then
        wci_SData <= biasValue;
        wci_SResp <= ocpResp_DVA;
      end if;

      -- WCI Control Operations...
      if wci_ctl_op='1' then 
        case wci_MAddr(4 downto 2) is
          when wciCtlOp_Initialize  => wci_ctlSt  <= wciCtlSt_Initialized;
          when wciCtlOp_Start       => wci_ctlSt  <= wciCtlSt_Operating;
          when wciCtlOp_Stop        => wci_ctlSt  <= wciCtlSt_Suspended;
          when wciCtlOp_Release     => wci_ctlSt  <= wciCtlSt_Exists;
          when others => null;
        end case;
        wci_SData <= wciResp_OK;
        wci_SResp <= ocpResp_DVA;
      end if;  

    end if wci_reset_clause;

  end if;
end process reg;
end rtl;

