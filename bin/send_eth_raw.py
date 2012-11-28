#!/usr/bin/env python2.7
# send_eth_raw.py
# Copyright (c) 2012 Atomic Rules LLC - ALL Rights Reserved

import optparse
import os
import re
import subprocess
import sys
import time

from scapy.all import *

def main(argv):
  print """Hello from %s""" % (prog_name)

  for line in range(108):
    p = Ether()
    p.src  = '00:26:E1:01:01:00'   # Linux Host Source MAC Address
    p.dst  = '00:0A:35:42:01:00'   # Xilinx FPGA Dest MAC Address
    p.type = 0xF042                # EtherType 
    P = bytearray(680)
    for i in range(680):
      P[i] = i & 0xff
    p.payload = str(P)
    r = srp(p, iface="eth1")


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
