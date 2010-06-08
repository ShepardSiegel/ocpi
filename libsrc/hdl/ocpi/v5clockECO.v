 // Take the clock out of the BPEP signal bundle to kill the BUFG
 // Verify that the clock emmitted by the BPEP does not have an added BUFG
 // Use with V5 BPEP only; With V6 use native MMCM
 (* buffer_type="none", max_fanout="100000" *)
  wire pci0_pcie_ep$trn_clk;

