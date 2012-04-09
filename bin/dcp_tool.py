#!/usr/bin/env python2.7
# dcp_tool.py - DCP packet tool
# Copyright (c) 2012 Atomic Rules LLC - ALL Rights Reserved

import os
import sys
import time

from scapy.all import *

class DCP(Packet):
  name = "DWORD Control Packet"
  fields_desc = [ ShortField("payload_length", 10),
                  ShortField("head_reserved", 0),
                  XByteField("mesage_type", 0),    # needs nibble field enumerations
                  ByteField("dcp_tag", 0) ]

def main(argv):
  
  #parser = argparse.ArgumentParser(description='DCP Tool Parser.')
  #parser.add_argument('--dcpAction'

  print """Hello from %s""" % (prog_name)
  p = Ether()
  p.src  = '00:26:E1:01:01:00'   # Linux Host Source MAC Address
  p.dst  = '00:0A:35:42:01:00'   # Xilinx FPGA Dest MAC Address
  p.type = 0xF040                # EtherType TCP
  #p.payload = "\x00\x0A\x00\x00\x0F\x05\x80\x00\x00\x01"                    # 10B NOP
  #p.payload = "\x00\x0E\x00\x00\x1F\x06\x00\x00\x00\x24\x00\x00\x00\x02"    # 14B Write 0x24 with 0x00000002
  p.payload = "\x00\x0A\x00\x00\x2F\x07\x00\x00\x00\x24"                     # 10B Read 0x24
  print "Sending packet..."
  rp = srp1(p, iface="eth1")
  print "Got back"
  #print rp
  rp.show()


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
