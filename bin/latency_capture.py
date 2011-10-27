#!/usr/local/bin/python

import os
import re
import subprocess
import sys

Lengths = [4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]

def main(argv):
  if len(argv) != 2:
    print """\
usage: %s <argfoop>
where <argfoop> is a valid foop.""" % (prog_name)
    sys.exit(1)
  else:
    print 'argv 1 is ' + argv[1]

    for l in Lengths:

      cmd = ["sudo", "-E", "./testRpl", "-r1im", "-r3om", "-I", str(l), "-i", "1", "-z", "0000:04:00.0"]
      sys.stderr.write(str(cmd) + '\n')
      x = 1000 
      while x:
        x = x-1

        # This approach will not return the byteStream until the subprocess completes
        byteStream = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
       
        # positive lookbehind assertion 
        m = re.search('(?<=Time delta = )\w+', byteStream)
        if x:
          print m.group(0) + ',' ,
        else:
          print m.group(0) 
  


prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
