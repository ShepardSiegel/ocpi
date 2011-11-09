#!/usr/local/bin/python
# benchmark_sweep.py
# Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import os
import subprocess
import sys

WidthList = [32, 64, 128, 256]
DebugList = [0, 1]
module = 'SMAdapter'

def build_xst_commands(module, w, d):
  """
  Build a Xilinx XST command file to control synthesis
  """
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
  """
  This function parses a Xilinx XST synthesis report file for the metrics
  in the metric list and returns a dictionary populated with metrics as keys
  """
  metrics = ['Slice Registers:',
             'Slice LUTs:',
             'Number of IOs:',
             'Block RAM/FIFO:',
             'Maximum Frequency:']
  dm = {}
  for l in srp.splitlines():
    for m in metrics:
      if m in l:
        tail = l.partition(m)[2]         # take the tail after the match
        tlist = tail.split()             # make a list of the strings
        if m == 'Maximum Frequency:':    # special case for 123.45MHz, take as integer
          tlist = tlist[0].split('.')
        v = int(tlist[0]) 
        dm[m] = v                        # add the key and value for this metric
  return(dm)                             # return the metric dictionary for this parse

def cleanup_files():
  nuke = ['xst_tmp.xst',
          module + '.ngc',
          module + '.lso',
          module + '_xst.xrpt',
          '_xmsgs',
          'xst']
  for x in nuke:
    cmd = ["rm", "-rf",  x]              # remove the files or directories on nuke list
    sout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
  return(0)

def bench_sweep():
  """
  Sweep synthesis over the benchmark dimensions and parse results
  """
  for w in WidthList:
    for d in DebugList:
      build_xst_commands(module, w, d);
      suffixString =  'Width' + str(w) + '_Debug' + str(d)
      reportFile = module + '_'  + suffixString  + '.srp'
      cmd = ["xst", "-ifn", "xst_tmp.xst", "-ofn", reportFile]
      xstout = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
      dm = parse_srp(xstout)
      for m in dm.keys():
        print '  ' + m + ' ' + str(dm[m])
  return(0)

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]
    bench_sweep()
    cleanup_files()
    sys.exit(0)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
