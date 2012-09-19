#!/usr/local/bin/python
# dbgRcvCP.py - manipulate a few Rcv control Plane (CP) workers
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl, wop, testScratchReg, testAdminReg, rwsr

import os
import subprocess
import sys

dev0 = 'ether:eth1/A0:36:FA:25:3B:81'
#dev0 = 'ether:eth1/A0:36:FA:25:3E:A5'

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

    sma0WrkNum = 2   # SMA0
    biasWrkNum = 3   # Bias
    sma1WrkNum = 4   # SMA1
    plaWrkNum  = 7   # Platform
    gbeWrkNum  = 9   # GBE
    adcWrkNum  = 10  # IQADC
    dp0WrkNum  = 13  # dgdp dp0
    dp1WrkNum  = 14  # dgdp dp1

    workerList = [2,3,4,7,9,10,13,14]

    print 'Reset cycling each worker...'
    for w in workerList:
      print 'Worker: ' + str(w)
      print 'reset'
      wreset(dev0, w)
      print 'unreset'
      wunreset(dev0, w)
      print 'f-value timeout'
      wwctl(dev0, w, 0x8000000F)

    print 'Testing admin scratch regsiters...'
    testAdminReg(dev0, 0x20)
    testAdminReg(dev0, 0x24)

    print 'Probing Worker Control Status ahead of init...'
    for w in workerList:
      rwsr(dev0, w)

    print 'Initializing each worker...'
    for w in workerList:
      wop(dev0, w, 'initialize')

    print 'Probing Worker Control Status after init...'
    for w in workerList:
      rwsr(dev0, w)

    print 'Testing scratch registers...'
    print 'sma0'
    testScratchReg(dev0, sma0WrkNum, 0)
    print 'bias'
    testScratchReg(dev0, biasWrkNum, 0x4)
    print 'sma1'
    testScratchReg(dev0, sma1WrkNum, 0)
    print 'gbe'
    testScratchReg(dev0, gbeWrkNum,  0)
    print 'dp0'
    testScratchReg(dev0, dp0WrkNum,  0xB8)
    print 'dp1'
    testScratchReg(dev0, dp1WrkNum,  0xB8)

    print 'Done.'
    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
