#!/usr/local/bin/python
# dbgIQADCWorker.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl

import os
import subprocess
import sys

dev0 = 'ether:eth1/A0:36:FA:25:3B:81'

# this function enables serial read, does a read, then disables it again...
def spi_read(device, iqWrkNum, addr):
  wwrite(device, iqWrkNum, 0x400, 0x1)   # enable serial readout
  rval = wread(device, iqWrkNum, addr)
  wwrite(device, iqWrkNum, 0x400, 0x0)   # disable serial readout
  return(rval)

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
    iqWrkNum = 10
    wreset(dev0, iqWrkNum)
    wunreset(dev0, iqWrkNum)
    wwctl(dev0, iqWrkNum, 0x8000000F)

    for addr in range(0, 0x64, 4):
      rval = wread(dev0, iqWrkNum, addr)
      print 'CFG addr:', hex(addr), ' data:', hex(rval)

    #wwrite(dev0, iqWrkNum, 0x400, 0x2)  # soft reset ADC device
    #while (wread(dev0, iqWrkNum, 0x400) & 0x2):   # test if bit 1 is set - goes to zero when reset finishes
    #  print 'waiting for reset bit to self clear'

    #wwrite(dev0, iqWrkNum, 0x458, 0x4)   # ramp pattern
    wwrite(dev0, iqWrkNum, 0x28, 0x00001408)   # override cmos (0x14) <= 0x8
    wwrite(dev0, iqWrkNum, 0x28, 0x00001604)   # ramp pattern  (0x16) <= 0x4

    #for addr in [0x400, 0x458]:
    #  rval = spi_read(dev0, iqWrkNum, addr)
    #  print 'SPI addr:', hex(addr), ' data:', hex(rval)

    #for addr in range(0x478, 0x4AC, 4):
    #  rval = spi_read(dev0, iqWrkNum, addr)
    #  print 'COEF addr:', hex(addr), ' data:', hex(rval)




    sys.exit(0)


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
