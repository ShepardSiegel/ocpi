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
  print cmdout
  return(0)

def wread(device, workerNum, offset):
  print device
  cmd = ["sudo", "-E", "./ocpihdl", "wread", "-P", device, str(workerNum), str(offset), "1"]
  print 'cmd is ', cmd
  cmdout = subprocess.popen(cmd, stderr=subprocess.STDOUT)
  print cmdout
  return(0)

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]
    probe(dev0)
    wread(dev0, 11, 0x0C)
    sys.exit(0)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
