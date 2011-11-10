#!/usr/local/bin/python
# ocdp_sweep.py
# Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED

import os
import subprocess
import sys

module = 'OCDP'
#SweepList   = [WidthList[], HasPushList[], HasPullList[], DebugList[]]
WidthList   = [32, 64, 128, 256]
HasPushList = [0, 1]
HasPullList = [0, 1]
DebugList   = [0, 1]

from copy import deepcopy

class Sweep:
  def __init__(self, list_of_option_lists):
    self._data      = deepcopy(list_of_option_lists)
    self._num_lists = len(list_of_option_lists)
    self._current   = [ 0 for l in list_of_option_lists ]
  def __iter__(self):
    while True:
      yield tuple([ self._data[n][self._current[n]] for n in range(self._num_lists) ])
      for n in range(self._num_lists):
        if self._current[n] == len(self._data[n])-1:
          self._current[n] = 0
        else:
          self._current[n] += 1
          break
      if sum(self._current) == 0:
        break

def example_sweep():
  for (s,n,a) in Sweep([['a','b','c'],[1,2,3],["cat","dog"]]):
    print (s,n,a)

def build_sweep_ocdp():
  """
  Create the key-value pairs desired to execute this sweep
  These are the values we would need to persist to represent this object in order to recreate
  """
  S = {}
  S['objectName']   = 'sweepObject'
  S['moduleName']   = 'OCDP'                                      # Name of the module to be swept
  S['sweepList']    = ['Width', 'HasPush', 'HasPull', 'Debug']    # List of dimensions to sweep
  S['Width']        = [32, 64, 128, 256]
  S['WidthParam']   = ['WMI_S0_DATAPATH_WIDTH']
  S['HasPush']      = [0, 1]
  S['HasPushParam'] = ['HAS_PUSH_LOGIC']
  S['HasPull']      = [0, 1]
  S['HasPullParam'] = ['HAS_PULL_LOGIC']
  S['Debug']        = [0, 1]
  S['DebugParam']   = ['HAS_DEBUG_LOGIC']
  return(S)

def build_suffixString(S, T):
  ss = ''
  i = 0
  for s in S['sweepList']:
    sp = s + 'Param'
    ss += s
    ss += str(S[s][T[i]])
    if i+1 < len(S['sweepList']):
      ss += '_'
    i += 1
  return(ss)

def process_sweep(S):
  """
  Calculate the artifacts of the sweep for convienience. Key-values added here can be recalculated.
  This is generic to all our sweep objects
  """
  if S['objectName'] != 'sweepObject': print 'Wrong dictionary'; return(1)
  dl = []
  perm = 1
  for dn in S['sweepList']:
    u = len(S[dn])
    perm *= u
    dl.append(u)
  S['dimlist']  = dl         # place the dimension list in the dictionary for easy unwiding
  S['perms']    = perm
  print 'Sweep has dimension of ' + str(len(S['dimlist'])) + ' with ' + str(S['perms']) + ' permutations'
  return(S)

def build_xst_commands(S, T):
  """
  Build a Xilinx XST command file to control synthesis
  """
  f = open('xst_tmp.xst', 'w')
  f.write('run\n')
  f.write('-ifn ' + S['moduleName'] + '.prj\n')
  f.write('-ofn ' + S['moduleName'] + '\n')
  f.write('-top ' + S['moduleName'] + '\n')
  f.write('-generics {')
  i = 0
  for s in S['sweepList']:
    sp = s + 'Param'
    f.write(S[sp][0] + '=' + str(S[s][T[i]])) # use the tuple T to index the param name and value fields
    if i+1 < len(S['sweepList']):
      f.write(', ')
    else:
      f.write('}\n')
    i += 1
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

def bench_sweep(S):
  """
  Sweep synthesis over the benchmark dimensions and parse results
  """
  for T in Sweep(map(range,S['dimlist'])):
    print T
    print 'Variation: ' + ', '.join(S['sweepList']) + ': ' + str(T)
    build_xst_commands(S, T);
    suffixString = build_suffixString(S, T)
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
    S = build_sweep_ocdp()
    S = process_sweep(S)
    bench_sweep(S)
    cleanup_files()
    sys.exit(0)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
