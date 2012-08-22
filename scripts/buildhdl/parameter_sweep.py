#!/usr/local/bin/python

import os
import re
import subprocess
import sys

WidthList = [32, 64, 128, 256]
DebugList = [0, 1]
module = 'SMAdapter'

def build_xst_commands(module, w, d):
  print 'Variation: ' + 'Width:' + str(w) + ' Debug:' + str(d)
  f = open('xst_tmp.xst', 'w')
  f.write('run\n')
  f.write('-ifn ' + module + '.prj\n')
  f.write('-ofn ' + module + '\n')
  f.write('-top ' + module + '\n')
  f.write('-generics {')
  f.write('WMI_M0_DATAPATH_WIDTH=' + str(w) + ', ')
  f.write('WSI_S0_DATAPATH_WIDTH=' + str(w) + ', ')
  f.write('WSI_M0_DATAPATH_WIDTH=' + str(w) + ', ')
  f.write('HAS_DEBUG_LOGIC=' + str(d) + '}\n')
  f.write('-p virtex6\n')
  f.write('-iobuf NO\n')
  f.close

def parse_srp(srp):
  metrics = ['Slice Registers:', 'Slice LUTs:', 'Number of IOs:', 'Block RAM/FIFO:', 'Maximum Frequency:']
  for l in srp.splitlines():
    for m in metrics:
      if m in l:
        tail = l.partition(m)[2]         # take the tail after the match
        tlist = tail.split()             # make a list of the strings
        if m == 'Maximum Frequency:':    # special case for 123.45MHz, take as integer
          tlist = tlist[0].split('.')
        v = int(tlist[0]) 
        print '  ' + m + ' ' + str(v)

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]

    for w in WidthList:
      for d in DebugList:
        build_xst_commands(module, w, d);
        suffixString =  'Width' + str(w) + '_Debug' + str(d)
        reportFile = module + '_'  +suffixString  + '.srp'
        cmd = ["xst", "-ifn", "xst_tmp.xst", "-ofn", reportFile]
        xstout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
        parse_srp(xstout)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
