#!/usr/local/bin/python

import os
import re
import struct
import subprocess
import sys

def main(argv):
  fileObject = open('srcData.bin','wb');
  for num in range(2048):
    data = struct.pack('i', num);
    fileObject.write(data)
  fileObject.close()

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
