#!/usr/local/bin/python

import os
import re
import subprocess
import sys

WidthList = [32, 64, 128, 256]
DebugList = [0, 1]
module = 'SMAdapter'

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
        print 'Iteration: ' + ' Width:' + str(w) + ' Debug:' + str(d)
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

        #cmd = ["sudo", "-E", "./testRpl", "-r1im", "-r3om", "-I", str(l), "-i", "1", "-z", "0000:04:00.0"]
        #sys.stderr.write(str(cmd) + '\n')
        #x = 1000 
        #while x:
          #x = x-1
  #
          ## This approach will not return the byteStream until the subprocess completes
          #byteStream = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
         #
          ## positive lookbehind assertion 
          #m = re.search('(?<=Time delta = )\w+', byteStream)
          #if x:
            #print m.group(0) + ',' ,
          #else:
            #print m.group(0) 
  

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
