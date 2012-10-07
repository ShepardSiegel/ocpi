#!/usr/local/bin/python
# dbgRcvCP.py - manipulate a few Rcv control Plane (CP) workers
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl, wwpage, wop, testScratchReg, testAdminReg, rwsr

import os
import subprocess
import sys

def argTest(arg):
  print arg
  print hex(arg)

#dev0 = 'ether:eth1/A0:36:FA:25:3B:81'
#dev0 = 'ether:eth1/A0:36:FA:25:3E:A5'
dev0 = 'sim:OpenCPI0'

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


    pat0WrkNum = 2   # Pattern
    biasWrkNum = 3   # Bias
    cap0WrkNum = 4   # Capture

    workerList = [2,3,4]

    print 'Reset cycling each worker...'
    for w in workerList:
      print 'Worker: ' + str(w)
      print 'reset'
      wreset(dev0, w)
      print 'unreset'
      wunreset(dev0, w)
      # Modification for extended timeout...
      #print 'f-value timeout'
      #wwctl(dev0, w, 0x8000000F)

    #print 'Testing admin scratch regsiters...'
    #testAdminReg(dev0, 0x20)
    #testAdminReg(dev0, 0x24)
    wadmin(dev0, 0x20, 0xFEEDC0DE)
    wadmin(dev0, 0x24, 0xBABECAFE)

    print 'Probing Worker Control Status ahead of init...'
    for w in workerList:
      rwsr(dev0, w)

    print 'Initializing each worker...'
    for w in workerList:
      wop(dev0, w, 'initialize')

    wwrite(dev0, pat0WrkNum, 0x04, 0x00000001);

    print 'Reading Config Prop status regs...'
    wread(dev0,  pat0WrkNum, 0x1C);
    wread(dev0,  cap0WrkNum, 0x0C);

    print 'Starting each worker...'
    for w in workerList:
      wop(dev0, w, 'start')

    print 'Write capture enable bit...'
    wwrite(dev0, cap0WrkNum, 0x00, 0x00000001);

    print 'Set Page Register to Metadata on Pattern Generator...'
    wwpage(dev0,  pat0WrkNum, 0x400);
    print 'Write Metadata...'
    wwrite(dev0,  pat0WrkNum, 0x0000, 0x00000080); # 32*4=128
    wwrite(dev0,  pat0WrkNum, 0x0004, 0x00000002); # opcode 2
    wwrite(dev0,  pat0WrkNum, 0x0008, 0x00000042);
    wwrite(dev0,  pat0WrkNum, 0x000C, 0x00000043);

    print 'Set Page Register to Data Region on Pattern Generator...'
    wwpage(dev0,  pat0WrkNum, 0x800);
    print 'Write Data Region...'
    #wwrite(dev0,  pat0WrkNum, 0x0000, 0x03020100);
    #wwrite(dev0,  pat0WrkNum, 0x0004, 0x07060504);
    #wwrite(dev0,  pat0WrkNum, 0x0008, 0x0B0A0908);
    #wwrite(dev0,  pat0WrkNum, 0x000C, 0x0F0E0D0C);
    #wwrite(dev0,  pat0WrkNum, 0x0010, 0x13121110);

    startWord = 0x03020100;
    for i in range(32):
      wwrite(dev0,  pat0WrkNum, i*4, i);

    print 'ReturnPage Register to 0 on Pattern Generator...'
    wwpage(dev0,  pat0WrkNum, 0x0);  # Page 0
    print 'Write Data Region...'
    wwrite(dev0,  pat0WrkNum, 0x0010, 0x00000003);  # send 3 messages
    wwrite(dev0,  pat0WrkNum, 0x0000, 0x00000001);  # Fire!

    print 'Command Sequence complete and fired!'


    #print 'Probing Worker Control Status after init...'
    #for w in workerList:
    #  rwsr(dev0, w)

    #print 'Testing scratch registers...'
    #print 'sma0'
    #testScratchReg(dev0, pat0WrkNum, 0)
    #print 'bias'
    #testScratchReg(dev0, biasWrkNum, 0x4)
    #print 'sma1'
    #testScratchReg(dev0, cap0WrkNum, 0)

    print 'Done.'
    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
