#!/bin/sh
echo file is $1
ed $1 <<XXX
1
/pci0_pcie_ep\$trn_clk/p
//p
.=
//
.=
p
d
/pci0_pcie_ep\$trn_tsrc_rdy_n/
.=

.=
.r v5clockECO.v
.=
w
XXX
