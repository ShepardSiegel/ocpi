#!/usr/bin/env python2.7
# send_dcp.py - Send a DCP packet
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
  p = Ether()
  p.src  = '01:02:03:04:05:06'
  p.dst  = '91:92:93:94:95:96'
  p.type = 0xF040
  p.payload = 'Atomic'
  p.show()
  print "Sending packet..."
  sendp(p, iface="eth1")


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
