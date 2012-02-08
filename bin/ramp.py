#! /usr/local/bin/python
# ramp.py: generate binary test data
# Ned Batchelder
# http://www.nedbatchelder.com

import getopt, sys

def main(args):

    def usage():
        for l in [
            "ramp: generate binary data",
            "ramp [opts] outfile",
            " -n n      length of ramp",
            " -r r      number of times to repeat ramp",
            " -d        ramp descending",
            " -s s      skip by this between samples",
            " -x x      repeat each sample this many times",
            " -q data   use numeric data instead of ramp",
            " -t data   use text data instead of ramp",
            ]: print l
        sys.exit()
        
    try:
        opts, args = getopt.getopt(args, "dn:r:s:x:q:t:")
    except getopt.GetoptError:
        # print help information and exit:
        usage()

    # Collect the options

    num = 256
    repeat = 1
    skip = 1
    xtimes = 1
    descend = 0
    bytes = []
    
    for o, a in opts:
        if o == '-n':
            num = eval(a)
        elif o == '-r':
            repeat = eval(a)
        elif o == '-s':
            skip = eval(a)
        elif o == '-x':
            xtimes = eval(a)
        elif o == '-d':
            descend = 1
        elif o == '-q':
            bytes += map(eval, a.split())
        elif o == '-t':
            bytes += map(ord, a)
        else:
            usage()
    
    if num > 256:
        usage()

    if len(args) == 1:
        fout = open(args[0], 'wb')
    else:
        fout = sys.stdout

    if not bytes:
        bytes = range(0, num*skip, skip)
        
    if descend:
        bytes.reverse()

    for i in range(repeat):
        for ch in bytes:
            for x in range(xtimes):
                fout.write(chr(ch))

if __name__ == '__main__':
    main(sys.argv[1:])
