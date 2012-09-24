#!/usr/local/bin/python
# dbgEDP.py - debug the Ethernet Dataplane
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

    patWrkNum = 5   # pattern gen
    smaWrkNum = 6   # SMA
    plaWrkNum = 7   # Platform
    gbeWrkNum = 9   # GBE
    adcWrkNum = 10  # IQADC
    dp0WrkNum = 13  # dgdp dp0
    dp1WrkNum = 14  # dgdp dp1

    workerList = [5,6,7,9,10,13,14]

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
    testScratchReg(dev0, 5, 0)
    testScratchReg(dev0, 6, 0)
    testScratchReg(dev0, 9, 0)
    testScratchReg(dev0, 13, 0xB8)
    testScratchReg(dev0, 14, 0xB8)

    print 'Done.'
    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
