// PBNBridge.bsv - PCIe / BNoC Bridge
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import PCIE::*;
import MsgFormat::*;

package PBNBridge;

/* 

The PCIe BNoC Bridge provides an implementation which converts between PCIe TL
messages on the PCIe EP side; and more-abstract BNoC messages on the BNoC side.
The PCIe 3.0 TL spec serves as the specification for the PCIe side.
The AR/Bluespec BNoC Message Format serves as the spec for the BNoC side.
The initial implementation provides the following six bridge functions, three in
each direction. The operation is functionally symmertrical, save for the differnces
in the protocols on each side of the bridge...

   +++ From PCIe Fabric to BNoC +++

1. PCIe posted write to BNoC write. This operation invoves the slicing of a PCIe
   posted-write into N BNoC segments. It also involves translating the PCIe BAR and
   address into a local destination node and address.

2. PCIe non-posted read request to BNoC read request. This involves translating the 
   PCIe BAR and address into a local destination node and address. The information
   from the read request is stored on the PCIe Completion Buffer (PCB) for when BNoC
   responds.

3. PCIe returning completion data to BNoC requester as write in response. This operation
   is cordinated with the BNoC Completion Buffer (BCB) so as potentially out-of-order segments
   arrive, they are corectly converted in-flight to BNoC write in response actions.

   +++ From BNoC to PCIe Fabric +++

4. BNoC posted write to PCIe fabric write. This involves translating the BNoC Address to 
   a PCIe device and address.

5. BNoC non-posted read request to PCIe read request. This involves translating the 
   PCIe BAR and address into a local destination node and address. Slicing into mutiple
   reads may be required to meet PCIe spec. The information from the read request is stored
   on the BNoC Completion Buffer (BCB) for when the PCIe completion returns.

6. BNoC returning completion data to a PCIe requester as write in response. This operation
   is coordinated with the PCIe Completion Buffer (PCB) so the read data is retunred to the 
   correct device.

The PCIe Completion Buffer (PCB) holds unique indetifiers for PCIe requests toward BNoC,
along with the the supplemental data needed to complete the PCIe read request when BNoC responds.

The BNoC Completion Buffer (BCB) holds unique indetentifiers for BNoC requests toward PCIe,
along with the supplimental data needed to generate the Write-InResponse when PCIe responds.


*/

endpackage: PBNBridge
