// WSIAXIS.bsv - Unidirectional Adapters between WSI and AXI4-Stream
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import ARAXI4S::*;
import OCWip::*;

import FIFO::*;	
import GetPut::*;

interface WSItoAXIS32BIfc;
  interface WsiES32B  wsi;  // WSI-Slave 
  interface A4SEM32B  axi;  // AXI4-Stream Master
endinterface 

interface AXIStoWSI32BIfc;
  interface A4SES32B  axi;  // AXI4-Stream Slave 
  interface WsiEM32B  wsi;  // WSI-Master
endinterface 
