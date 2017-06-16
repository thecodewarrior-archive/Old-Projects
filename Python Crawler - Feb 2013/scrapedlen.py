#!/usr/bin/env python3.2

from subprocess import Popen , PIPE #Popen , PIPE
import sys
import argparse

def FileHeight(path):
    a = int(Popen(['grep' , '-c' , '\n' , path] , stdout=PIPE).communicate()[0]) + 1
    print(a)
#	lns = int(pop.communicate())
#	print(round(lns, -3))
	
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='count the lines in a document')
    parser.add_argument('-f', '--file' , dest='filePathLocal' , action='store' ,
     help='file to load and count lines of')
    opts = parser.parse_args()
    FileHeight(opts.filePathLocal)
