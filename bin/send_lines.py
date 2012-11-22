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

def emitPackets():
  for line in range(2):
    p = Ether()
    p.src  = '00:26:E1:01:01:00'   # Linux Host Source MAC Address
    p.dst  = '00:0A:35:42:01:00'   # Xilinx FPGA Dest MAC Address
    p.type = 0xF042                # EtherType 
    P = bytearray(1000)
    for i in range(1000):
      P[i] = i & 0xff
    p.payload = str(P)
    sendp(p, iface="eth1")

def emitPacket(dataStr): 
    p = Ether()
    p.src  = '00:26:E1:01:01:00'   # Linux Host Source MAC Address
    p.dst  = '00:0A:35:42:01:00'   # Xilinx FPGA Dest MAC Address
    p.type = 0xF042                # EtherType 
    p.payload = dataStr            # The dataString payload of Bytes
    sendp(p, iface="eth1")

def main(argv):
  print """Hello from %s""" % (prog_name)

  f = open('t100', 'r')
  for row in range(1):   # 1080
    for col in range(1): # 1920
      dataStr = '\x00\x00'
      for oct in range(5): # 1920/8=240  FIXME
        g = int(f.read(2),16)
        b = int(f.read(2),16)
        r = int(f.read(2),16)
        t = int('00',16)
        dataStr = dataStr+chr(g)+chr(b)+chr(r)+chr(t)
      emitPacket(dataStr)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
