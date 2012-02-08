#!/usr/local/bin/python
# bytesweep_nft.py
# Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

import os
import subprocess
import sys

#WidthList = [32, 64, 128, 256]
#DebugList = [0, 1]
#module = 'SMAdapter'

def bytesweep(length):
  for l in range(length):
    cmd = "ramp.py -n " + str(l) + " nft_in.dat";
    os.system(cmd);
    cmd = "sudo -E ./nft -m1000 0000:04:00.0 < nft_in.dat > nft_out.dat"
    os.system(cmd);

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]
    bytesweep(int(argv[1]))
    sys.exit(0)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
