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
  p.src  = '00:26:E1:01:01:00'
  p.dst  = '00:0A:35:42:01:00'
  p.type = 0xF040
  #p.payload = "\x00\x0A\x00\x00\x0F\x05\x80\x00\x00\x01"
  p.payload = "\x00\x0E\x00\x00\x1F\x06\x00\x00\x00\x24\x00\x00\x00\x01"
  p.show()
  print "Sending packet..."
  sendp(p, iface="eth1")


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
