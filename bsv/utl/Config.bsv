// Config.bsv
// Copyright (c) 2009-2010 Atomic Rules LLC - ALL RIGHTS RESERVED

package Config;

  // Global

`ifdef USE_NDW1
  `define DEFINE_NDW 1
`elsif USE_NDW2
  `define DEFINE_NDW 2
`elsif USE_NDW4
  `define DEFINE_NDW 4
`elsif USE_NDW8
  `define DEFINE_NDW 8
`endif


  typedef `DEFINE_NDW NDW_global;
  Integer iNDW_global = valueOf(NDW_global);
  
  //TODO: Remove
  // Number of Bytes in the dataplane
  //typedef 16 NB_dataplane;
  //Integer iNB_dataplane = valueOf(NB_dataplane);

  // WCI...

  // Set number of WCI interfaces in the applcation
  typedef 8 Nwci_app;
  Integer iNwci_app = valueOf(Nwci_app);

  // Set number of WCI interfaces in FTop
  typedef 5 Nwci_ftop;
  Integer iNwci_ftop = valueOf(Nwci_ftop);

  // Set number of WCI interfaces brokered by ctop
  typedef 13 Nwci_ctop;
  Integer iNwci_ctop = valueOf(Nwci_ctop);

  // Set number of WCI interfaces TOTAL...
  typedef 15 Nwcit;
  Integer iNwcit = valueOf(Nwcit);

  // WMI...

  // Set number of WMI interfaces between infrastructure and application...
  typedef 2 Nwmi;
  Integer iNwi = valueOf(Nwmi);

  // WMemi...

  // Set number of WMemi interfaces between infrastructure and application...
  typedef 1 Nwmemi;
  Integer iNwmemi = valueOf(Nwmemi);

endpackage: Config
 
