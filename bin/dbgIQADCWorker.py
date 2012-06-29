#!/usr/local/bin/python
# dbgIQADCWorker.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

from ocpihdl import probe, wadmin, radmin, wwrite, wread, wreset, wunreset, wwctl, wop

import os
import subprocess
import sys

#dev0 = 'ether:eth1/A0:36:FA:25:3B:81'
dev0 = 'ether:eth1/A0:36:FA:25:3E:A5'

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

    iqWrkNum  = 10  # the IQADCWorker
    capWrkNum = 11  # the WSI Capture Worker

    wreset(dev0, iqWrkNum)
    wunreset(dev0, iqWrkNum)
    wwctl(dev0, iqWrkNum, 0x8000000F)

    wreset(dev0, capWrkNum)
    wunreset(dev0, capWrkNum)
    wwctl(dev0, capWrkNum, 0x8000000F)

    for addr in range(0, 0x64, 4):
      rval = wread(dev0, iqWrkNum, addr)
      print 'IQADC CFG addr:', hex(addr), ' data:', hex(rval)

    #wwrite(dev0, iqWrkNum, 0x400, 0x2)  # soft reset ADC device
    #while (wread(dev0, iqWrkNum, 0x400) & 0x2):   # test if bit 1 is set - goes to zero when reset finishes
    #  print 'waiting for reset bit to self clear'

    print 'Enabling ADC Ramp Output...'
    wwrite(dev0, iqWrkNum, 0x28, 0x00000002)   # soft reset ADC (0x00) <= 0x02
    wwrite(dev0, iqWrkNum, 0x28, 0x00001480)   # (0x14) <= 0x80  override bit d7
    wwrite(dev0, iqWrkNum, 0x28, 0x00001604)   # ramp pattern  (0x16) <= 0x4

    #wwrite(dev0, iqWrkNum, 0x28, 0x00001B80)   # Offset Correction

    wwrite(dev0, iqWrkNum, 0x28, 0x000018AA)
    wwrite(dev0, iqWrkNum, 0x28, 0x000019AA)

    for addr in range(0, 0x64, 4):
      rval = wread(dev0, iqWrkNum, addr)
      print 'IQADC CFG addr:', hex(addr), ' data:', hex(rval)

    for i in range(0, 10):
      addr = 0x1C # sample spy
      rval = wread(dev0, iqWrkNum, addr)
      print 'CFG addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x20, 4):
      rval = wread(dev0, capWrkNum, addr)
      print 'WSICAP CFG addr:', hex(addr), ' data:', hex(rval)

    print 'start capture'
    wop(dev0, capWrkNum, 'initialize')
    wop(dev0, capWrkNum, 'start')

    wwrite(dev0, capWrkNum, 0x00, 0x00000003)  # b1=wrapInhibit b0=captureEnabled

    print 'start iqadc'
    wop(dev0, iqWrkNum, 'initialize')
    wop(dev0, iqWrkNum, 'start')

    wwrite(dev0, capWrkNum, 0x00, 0x00000000)  # b1=wrapInhibit b0=captureEnabled


    for addr in range(0, 0x64, 4):
      rval = wread(dev0, iqWrkNum, addr)
      print 'IQADC CFG addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x20, 4):
      rval = wread(dev0, capWrkNum, addr)
      print 'WSICAP CFG addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x1000, 4):
      rval = wread(dev0, capWrkNum, 0x80000000 + addr)
      print 'WSICAP DATA_REGION addr:', hex(addr), ' data:', hex(rval)

    for addr in range(0, 0x32, 4):
      rval = wread(dev0, capWrkNum, 0x40000000 + addr)
      print 'WSICAP META_REGION addr:', hex(addr), ' data:', hex(rval)






    #wwrite(dev0, iqWrkNum, 0x28, 0x00001000)   # (0x10) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001100)   # (0x11) <= 0x00
    ####wwrite(dev0, iqWrkNum, 0x28, 0x00001480)   # (0x14) <= 0x80  override bit d7
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001600)   # (0x16) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001700)   # (0x17) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001800)   # (0x18) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001900)   # (0x19) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001A00)   # (0x1A) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001A00)   # (0x1B) <= 0x00
    #wwrite(dev0, iqWrkNum, 0x28, 0x00001D00)   # (0x1D) <= 0x00

    #wwrite(dev0, iqWrkNum, 0x28, 0x00000001)   # ramp pattern  (0x16) <= 0x4
    #wwrite(dev0, iqWrkNum, 0x28, 0x80001400)   #

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
