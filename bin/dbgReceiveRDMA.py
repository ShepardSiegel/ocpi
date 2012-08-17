#!/usr/local/bin/python
# dbgReceiveRDMA.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl, wop

import os
import subprocess
import sys

#dev0 = 'ether:eth1/A0:36:FA:25:3B:81'
dev0 = 'ether:eth1/A0:36:FA:25:3E:A5'

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]
    if probe(dev0):
      print 'Device not Found'. dev0
      sys.exit(1)

    patWrkNum = 5   # pattern gen
    smaWrkNum = 6   # SMA
    gbeWrkNum = 9   # GBE
    dp0WrkNum = 13  # dgdp dp0

    #wreset(dev0, iqWrkNum)
    #wunreset(dev0, iqWrkNum)
    #wwctl(dev0, iqWrkNum, 0x8000000F)

    #wreset(dev0, capWrkNum)
    #wunreset(dev0, capWrkNum)
    #wwctl(dev0, capWrkNum, 0x8000000F)

    for addr in range(0, 0x30, 4):
      rval = wread(dev0, patWrkNum, addr)
      print 'pat addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x48, 4):
      rval = wread(dev0, smaWrkNum, addr)
      print 'sma addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x18, 4):
      rval = wread(dev0, gbeWrkNum, addr)
      print 'gbe addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0xB0, 4):
      rval = wread(dev0, dp0WrkNum, addr)
      print 'dp0 addr:', hex(addr), ' data:', hex(rval)


    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
