#!/usr/local/bin/python
# dbgRcvCP.py - manipulate a few Rcv control Plane (CP) workers
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl, wop, testScratchReg

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

    workerList = [5,6,9,13]

    print 'Reset cycling each worker...'
    for w in workerList:
      wreset(dev0, w)
      wunreset(dev0, w)
      wwctl(dev0, w, 0x8000000F)

    print 'Initializing each worker...'
    for w in workerList:
      wwctl(dev0, w, 'initialize')

    print 'Testing scratch registers...'
    testScratchReg(dev0, 5, 0)
    testScratchReg(dev0, 6, 0)
    #testScratchReg(dev0, 9, 0)
    #testScratchReg(dev0, 13, 0)

    print 'Done.'
    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
