#!/usr/local/bin/python
# ocpihdl.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import os
import subprocess
import sys

dev0 = 'ether:eth1/A0:36:FA:25:3B:81'

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

def wread(device, workerNum, offset):
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
