#!/usr/local/bin/python

import os
import re
import struct
import subprocess
import sys

def main(argv):
  for num in range(1024):
    print '%08X' % (num)

prog_name = os.path.basename(sys.argv[0])
if __name__ == '__main__':
    main(sys.argv)
