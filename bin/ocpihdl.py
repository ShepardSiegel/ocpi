#!/usr/local/bin/python
# ocpihdl.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import os
import subprocess
import sys

#dev0 = 'ether:eth1/A0:36:FA:25:3B:81'
dev0 = 'ether:eth1/A0:36:FA:25:3E:A5'

def probe(device):
  cmd = ["./ocpihdl", "probe", device]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  if "found" in cmdout:
    print 'Found device', device
    return(0);
  else:
    return(cmdout)

def radmin(device, offset):
  cmd = ["./ocpihdl", "radmin", "-P", device, str(offset)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  return(int(cmdout, 0))

def wop(device, workerNum, op):
  cmd = ["./ocpihdl", "wop", "-P", device, str(workerNum), op]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  rval = int(cmdout, 0)
  print 'worker', str(workerNum), 'command', op, 'returned', hex(rval)
  if (rval != 0xc0de4201):
    print 'wop got unexpected return', hex(rval)
  return(rval)

def wwpage(device, workerNum, pageVal):
  cmd = ["./ocpihdl", "wwpage", "-P", device, str(workerNum), str(pageVal)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  return(cmdout)

def wread(device, workerNum, offset):
  wwpage(device, workerNum, offset>>20)
  cmd = ["./ocpihdl", "wread", "-P", device, str(workerNum), str(offset), "1"]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  return(int(cmdout, 0))

def wadmin(device, offset, wdata):
  cmd = ["./ocpihdl", "wadmin", "-P", device, str(offset), str(wdata)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wwrite(device, workerNum, offset, wdata):
  cmd = ["./ocpihdl", "wwrite", "-P", device, str(workerNum), str(offset), str(wdata)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wwritePage(device, workerNum, offset, wdata):
  wwpage(device, workerNum, offset>>20)
  cmd = ["./ocpihdl", "wwrite", "-P", device, str(workerNum), str(offset), str(wdata)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wreset(device, workerNum):
  cmd = ["./ocpihdl", "wreset", "-P", device, str(workerNum)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wunreset(device, workerNum):
  cmd = ["./ocpihdl", "wunreset", "-P", device, str(workerNum)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wwctl(device, workerNum, wdata):
  cmd = ["./ocpihdl", "wwctl", "-P", device, str(workerNum), str(wdata)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def wwpage(device, workerNum, wpage):
  cmd = ["./ocpihdl", "wwpage", "-P", device, str(workerNum), str(wpage)]
  cmdout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  #return(int(cmdout, 0))

def rwsr(device, workerNum):
  wpone = (workerNum + 1) & 0xF
  addr = (wpone<<16) | 0xFFE0
  wsr = radmin(device, addr)
  addr = (wpone<<16) | 0xFFE4
  wcr = radmin(device, addr)
  print 'Worker: ' + str(workerNum) + ' WSR: ' + hex(wsr) + '  WCR: ' + hex(wcr)


# Functions that build off of primitives above...

def testAdminReg(device, offset):
  origValue = radmin(device, offset)
  for bit in range(32):
    tval = 1<<bit
    wadmin(device, offset, tval)
    gval = radmin(device, offset)
    if (tval != gval):
      print 'Mismatch: Expected: ' + hex(tval) + ' Got: ' + hex(gval)
  wadmin(device, offset, origValue)


def testScratchReg(device, workerNum, offset):
  origValue = wread(device, workerNum, offset)
  for bit in range(32):
    tval = 1<<bit
    wwrite(device, workerNum, offset, tval)
    gval = wread(device, workerNum, offset)
    if (tval != gval):
      print 'Mismatch worker: ' + str(workerNum) + ' Expected: ' + hex(tval) + ' Got: ' + hex(gval)
      break
  wwrite(device, workerNum, offset, origValue)


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
    wadmin(dev0, 0x20, 0xf00dc0de)
    wadmin(dev0, 0x24, 0xfeedface)
    rval = radmin(dev0, 0x20)
    print hex(rval)
    rval = radmin(dev0, 0x24)
    print hex(rval)
    sys.exit(0)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
